//! Restoring a backup archive, which is untrusted input: every entry lands
//! inside the staging directory, and the archive cannot make the restore
//! write more than the limits allow however its headers lie.

use std::fs::{self, File};
use std::io::{self, Read, Write};
use std::path::{Component, Path, PathBuf};

pub const MAX_ENTRIES: usize = 10_000;
pub const MAX_ENTRY_BYTES: u64 = 512 << 20;
pub const MAX_TOTAL_BYTES: u64 = 1 << 30;
/// Text and SQLite pages compress well, but nowhere near this.
pub const MAX_RATIO: u64 = 1_000;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ArchiveError {
    Invalid,
    TooLarge,
    Io,
}

/// The staging path for `name`, or None for a name that would leave
/// `staging`: absolute, drive-qualified, or climbing out with `..`.
pub fn staged_path(staging: &Path, name: &str) -> Option<PathBuf> {
    let normalized = name.replace('\\', "/");
    if normalized.starts_with('/') {
        return None;
    }
    let mut parts: Vec<&str> = Vec::new();
    for part in normalized.split('/') {
        match part {
            "" | "." => {}
            ".." => {
                parts.pop()?;
            }
            _ if part.contains(':') => return None,
            _ => parts.push(part),
        }
    }
    if parts.is_empty() {
        return None;
    }
    let path = parts
        .iter()
        .fold(staging.to_path_buf(), |path, part| path.join(part));
    let relative = path.strip_prefix(staging).ok()?;
    if relative
        .components()
        .all(|component| matches!(component, Component::Normal(_)))
    {
        Some(path)
    } else {
        None
    }
}

/// Writes the archive's files under `staging` and returns how many it wrote.
/// Entries whose names would leave `staging` are skipped, as are directories.
pub fn extract(archive: &Path, staging: &Path) -> Result<u32, ArchiveError> {
    let file = File::open(archive).map_err(|_| ArchiveError::Invalid)?;
    let mut zip = zip::ZipArchive::new(file).map_err(|_| ArchiveError::Invalid)?;
    if zip.len() > MAX_ENTRIES {
        return Err(ArchiveError::TooLarge);
    }
    fs::create_dir_all(staging).map_err(|_| ArchiveError::Io)?;
    let mut total: u64 = 0;
    let mut written = 0;
    for index in 0..zip.len() {
        let mut entry = zip.by_index(index).map_err(|_| ArchiveError::Invalid)?;
        if entry.is_dir() {
            continue;
        }
        let Some(path) = staged_path(staging, entry.name()) else {
            continue;
        };
        let compressed = entry.compressed_size().max(1);
        let declared = entry.size();
        if declared > MAX_ENTRY_BYTES
            || declared / compressed > MAX_RATIO
            || total + declared > MAX_TOTAL_BYTES
        {
            return Err(ArchiveError::TooLarge);
        }
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent).map_err(|_| ArchiveError::Io)?;
        }
        let budget = MAX_ENTRY_BYTES
            .min(MAX_TOTAL_BYTES - total)
            .min(compressed.saturating_mul(MAX_RATIO));
        let mut output = File::create(&path).map_err(|_| ArchiveError::Io)?;
        let copied = copy_limited(&mut entry, &mut output, budget)?;
        total += copied;
        written += 1;
    }
    Ok(written)
}

/// Copies at most `budget` bytes and fails if the reader has more: a header
/// can understate the size, the stream cannot.
fn copy_limited(
    reader: &mut impl Read,
    writer: &mut impl Write,
    budget: u64,
) -> Result<u64, ArchiveError> {
    let mut limited = reader.take(budget + 1);
    let copied = io::copy(&mut limited, writer).map_err(|error| match error.kind() {
        io::ErrorKind::InvalidData | io::ErrorKind::UnexpectedEof => ArchiveError::Invalid,
        _ => ArchiveError::Io,
    })?;
    if copied > budget {
        return Err(ArchiveError::TooLarge);
    }
    Ok(copied)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Cursor;
    use zip::write::SimpleFileOptions;

    fn temp_dir(name: &str) -> PathBuf {
        let dir =
            std::env::temp_dir().join(format!("rust_api_backup_{name}_{}", std::process::id()));
        let _ = fs::remove_dir_all(&dir);
        fs::create_dir_all(&dir).unwrap();
        dir
    }

    fn write_zip(path: &Path, entries: &[(&str, &[u8])]) {
        let mut zip = zip::ZipWriter::new(File::create(path).unwrap());
        let options =
            SimpleFileOptions::default().compression_method(zip::CompressionMethod::Deflated);
        for (name, data) in entries {
            zip.start_file(*name, options).unwrap();
            zip.write_all(data).unwrap();
        }
        zip.finish().unwrap();
    }

    #[test]
    fn staged_paths_stay_inside_the_staging_directory() {
        let staging = Path::new("/stage");
        assert_eq!(
            staged_path(staging, "profiles/1.yaml"),
            Some(staging.join("profiles").join("1.yaml"))
        );
        assert_eq!(
            staged_path(staging, "a/../b.txt"),
            Some(staging.join("b.txt"))
        );
        assert_eq!(
            staged_path(staging, "profiles\\2.yaml"),
            Some(staging.join("profiles").join("2.yaml"))
        );
        for name in [
            "../escape",
            "a/../../escape",
            "/etc/passwd",
            "\\windows\\system32",
            "C:/x",
            "C:\\x",
            "",
            ".",
            "..",
        ] {
            assert_eq!(staged_path(staging, name), None, "{name}");
        }
    }

    #[test]
    fn extracts_files_and_skips_escaping_names() {
        let dir = temp_dir("slip");
        let archive = dir.join("a.zip");
        write_zip(
            &archive,
            &[
                ("config.json", b"{}"),
                ("profiles/1.yaml", b"proxies: []"),
                ("../outside.txt", b"x"),
                ("/abs.txt", b"x"),
            ],
        );
        let staging = dir.join("staging");

        assert_eq!(extract(&archive, &staging), Ok(2));
        assert_eq!(fs::read(staging.join("config.json")).unwrap(), b"{}");
        assert!(staging.join("profiles").join("1.yaml").exists());
        assert!(!dir.join("outside.txt").exists());
        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn rejects_what_is_not_a_zip() {
        let dir = temp_dir("invalid");
        let archive = dir.join("a.zip");
        fs::write(&archive, b"not a zip").unwrap();

        assert_eq!(
            extract(&archive, &dir.join("staging")),
            Err(ArchiveError::Invalid)
        );
        assert_eq!(
            extract(&dir.join("missing.zip"), &dir.join("staging")),
            Err(ArchiveError::Invalid)
        );
        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn rejects_a_compression_bomb() {
        let dir = temp_dir("bomb");
        let archive = dir.join("a.zip");
        let zeros = vec![0u8; 8 << 20];
        write_zip(&archive, &[("config.json", &zeros)]);

        assert_eq!(
            extract(&archive, &dir.join("staging")),
            Err(ArchiveError::TooLarge)
        );
        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn copy_limited_trusts_the_stream_not_the_header() {
        let mut sink = Vec::new();
        assert_eq!(
            copy_limited(&mut Cursor::new(vec![1u8; 10]), &mut sink, 10),
            Ok(10)
        );
        assert_eq!(
            copy_limited(&mut Cursor::new(vec![1u8; 11]), &mut Vec::new(), 10),
            Err(ArchiveError::TooLarge)
        );
    }

    #[test]
    fn rejects_too_many_entries() {
        let dir = temp_dir("entries");
        let archive = dir.join("a.zip");
        let names: Vec<String> = (0..=MAX_ENTRIES).map(|i| format!("f{i}")).collect();
        let entries: Vec<(&str, &[u8])> =
            names.iter().map(|name| (name.as_str(), &b""[..])).collect();
        write_zip(&archive, &entries);

        assert_eq!(
            extract(&archive, &dir.join("staging")),
            Err(ArchiveError::TooLarge)
        );
        let _ = fs::remove_dir_all(&dir);
    }
}
