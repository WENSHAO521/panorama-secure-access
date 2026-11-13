use std::path::Path;

use flutter_rust_bridge::frb;

use crate::backup;
pub use crate::backup::ArchiveError;

#[frb(mirror(ArchiveError))]
pub enum _ArchiveError {
    Invalid,
    TooLarge,
    Io,
}

/// Runs on a Rust worker thread, so a large archive never blocks the UI.
pub fn extract_backup_archive(
    archive_path: String,
    staging_dir: String,
) -> Result<u32, ArchiveError> {
    backup::extract(Path::new(&archive_path), Path::new(&staging_dir))
}
