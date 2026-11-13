use std::net::{IpAddr, Ipv4Addr, Ipv6Addr};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
struct Range {
    start: u128,
    end: u128,
}

const FAMILIES: [u32; 2] = [32, 128];

fn is_decimal(value: &str) -> bool {
    match value.as_bytes() {
        [b'0'] => true,
        [b'1'..=b'9', rest @ ..] => rest.len() <= 2 && rest.iter().all(u8::is_ascii_digit),
        _ => false,
    }
}

/// As strict as Go's netip.ParsePrefix, since the core fails a whole config or
/// update on one CIDR that parser refuses.
pub fn is_cidr(value: &str) -> bool {
    let Some((address, prefix)) = value.rsplit_once('/') else {
        return false;
    };
    if !is_decimal(prefix) || address.contains('%') {
        return false;
    }
    let bits = if address.contains(':') {
        if address.parse::<Ipv6Addr>().is_err() {
            return false;
        }
        128
    } else {
        if address.parse::<Ipv4Addr>().is_err() {
            return false;
        }
        32
    };
    prefix.parse::<u32>().is_ok_and(|prefix| prefix <= bits)
}

fn parse(cidr: &str) -> Option<(u32, Range)> {
    let (address, prefix) = cidr.split_once('/')?;
    let address: IpAddr = address.trim().parse().ok()?;
    let prefix: u32 = prefix.trim().parse().ok()?;
    let (bits, value) = match address {
        IpAddr::V4(v4) => (32, u128::from(u32::from(v4))),
        IpAddr::V6(v6) => (128, u128::from(v6)),
    };
    if prefix > bits {
        return None;
    }
    let host = bits - prefix;
    let mask = if host == 128 {
        u128::MAX
    } else {
        (1u128 << host) - 1
    };
    let start = value & !mask;
    Some((
        bits,
        Range {
            start,
            end: start | mask,
        },
    ))
}

fn merge(mut ranges: Vec<Range>) -> Vec<Range> {
    ranges.sort_by_key(|range| range.start);
    let mut merged: Vec<Range> = Vec::with_capacity(ranges.len());
    for range in ranges {
        match merged.last_mut() {
            Some(last) if last.end == u128::MAX || range.start <= last.end + 1 => {
                last.end = last.end.max(range.end);
            }
            _ => merged.push(range),
        }
    }
    merged
}

fn subtract(included: &[Range], excluded: &[Range]) -> Vec<Range> {
    let mut result = Vec::new();
    let mut next = 0;
    for range in included {
        while next < excluded.len() && excluded[next].end < range.start {
            next += 1;
        }
        let mut cursor = Some(range.start);
        for cut in &excluded[next..] {
            let Some(at) = cursor else { break };
            if cut.start > range.end {
                break;
            }
            if cut.start > at {
                result.push(Range {
                    start: at,
                    end: cut.start - 1,
                });
            }
            cursor = cut.end.checked_add(1).filter(|next| *next <= range.end);
        }
        if let Some(at) = cursor {
            if at <= range.end {
                result.push(Range {
                    start: at,
                    end: range.end,
                });
            }
        }
    }
    result
}

fn to_cidrs(bits: u32, range: Range, out: &mut Vec<String>) {
    let mut start = range.start;
    loop {
        let aligned = if start == 0 {
            bits
        } else {
            start.trailing_zeros().min(bits)
        };
        let span = range.end - start;
        let fits = if span == u128::MAX {
            128
        } else {
            127 - (span + 1).leading_zeros()
        };
        let host = aligned.min(fits);
        out.push(format_block(bits, start, bits - host));
        let size = if host == 128 {
            None
        } else {
            Some(1u128 << host)
        };
        match size.and_then(|size| start.checked_add(size)) {
            Some(next) if next <= range.end => start = next,
            _ => return,
        }
    }
}

fn push_decimal(out: &mut String, value: u32) {
    if value >= 10 {
        push_decimal(out, value / 10);
    }
    out.push(char::from(b'0' + (value % 10) as u8));
}

// Route lists run to tens of thousands of blocks, where the std formatter's
// padding machinery for Ipv4Addr dominates the whole subtraction.
fn format_block(bits: u32, value: u128, prefix: u32) -> String {
    let mut out = String::with_capacity(if bits == 32 { 18 } else { 43 });
    if bits == 32 {
        for (index, octet) in (value as u32).to_be_bytes().into_iter().enumerate() {
            if index > 0 {
                out.push('.');
            }
            push_decimal(&mut out, u32::from(octet));
        }
    } else {
        use std::fmt::Write;
        let _ = write!(out, "{}", Ipv6Addr::from(value));
    }
    out.push('/');
    push_decimal(&mut out, prefix);
    out
}

/// The addresses of `include` that `exclude` leaves, as the fewest CIDR
/// blocks that cover them, IPv4 first. With `whole_when_empty`, a family
/// `include` names no block of counts as its whole address space. Entries that
/// do not parse are ignored.
pub fn subtract_cidrs(
    include: &[String],
    exclude: &[String],
    whole_when_empty: bool,
) -> Vec<String> {
    let grouped = |cidrs: &[String]| {
        let mut families: [Vec<Range>; 2] = [Vec::new(), Vec::new()];
        for (bits, range) in cidrs.iter().filter_map(|cidr| parse(cidr)) {
            families[usize::from(bits == 128)].push(range);
        }
        families
    };
    let [included_v4, included_v6] = grouped(include);
    let [excluded_v4, excluded_v6] = grouped(exclude);
    let mut out = Vec::new();
    for (bits, included, excluded) in [
        (FAMILIES[0], included_v4, excluded_v4),
        (FAMILIES[1], included_v6, excluded_v6),
    ] {
        let included = if included.is_empty() && whole_when_empty {
            let end = if bits == 128 {
                u128::MAX
            } else {
                (1u128 << bits) - 1
            };
            vec![Range { start: 0, end }]
        } else {
            included
        };
        for range in subtract(&merge(included), &merge(excluded)) {
            to_cidrs(bits, range, &mut out);
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn strings(values: &[&str]) -> Vec<String> {
        values.iter().map(|value| value.to_string()).collect()
    }

    #[test]
    fn cuts_a_block_out_of_a_range_as_the_fewest_covering_blocks() {
        assert_eq!(
            subtract_cidrs(&strings(&["0.0.0.0/0"]), &strings(&["10.0.0.0/8"]), false),
            strings(&[
                "0.0.0.0/5",
                "8.0.0.0/7",
                "11.0.0.0/8",
                "12.0.0.0/6",
                "16.0.0.0/4",
                "32.0.0.0/3",
                "64.0.0.0/2",
                "128.0.0.0/1",
            ]),
        );
    }

    #[test]
    fn a_family_without_an_included_block_counts_as_whole_on_request() {
        assert_eq!(
            subtract_cidrs(&strings(&["10.0.0.0/8"]), &[], true),
            strings(&["10.0.0.0/8", "::/0"]),
        );
        assert_eq!(
            subtract_cidrs(&strings(&["10.0.0.0/8"]), &[], false),
            strings(&["10.0.0.0/8"])
        );
    }

    #[test]
    fn whole_spaces_survive_the_edges_of_u128() {
        assert_eq!(
            subtract_cidrs(&strings(&["::/0", "0.0.0.0/0"]), &[], false),
            strings(&["0.0.0.0/0", "::/0"]),
        );
        assert!(subtract_cidrs(&strings(&["::/0"]), &strings(&["::/0"]), false).is_empty());
        assert_eq!(
            subtract_cidrs(&strings(&["::/0"]), &strings(&["::/1"]), false),
            strings(&["8000::/1"]),
        );
        assert_eq!(
            subtract_cidrs(&strings(&["::/0"]), &strings(&["8000::/1"]), false),
            strings(&["::/1"]),
        );
    }

    #[test]
    fn merges_overlaps_and_ignores_what_does_not_parse() {
        assert_eq!(
            subtract_cidrs(
                &strings(&["10.0.0.0/8", "bad", "10.1.0.0/16", "1.2.3.4/33"]),
                &[],
                false
            ),
            strings(&["10.0.0.0/8"]),
        );
        assert_eq!(
            subtract_cidrs(&strings(&[" 10.1.2.3 / 16 "]), &[], false),
            strings(&["10.1.0.0/16"])
        );
    }

    #[test]
    fn a_cidr_is_read_as_strictly_as_the_core_reads_a_prefix() {
        for value in [
            "192.168.1.5/24",
            "0.0.0.0/0",
            "fd00::/8",
            "::ffff:1.2.3.4/96",
        ] {
            assert!(is_cidr(value), "{value}");
        }
        for value in [
            "192.168.1.5",
            "192.168.1.0/33",
            "192.168.01.0/24",
            "192.168.1.0/024",
            " 10.0.0.0/8",
            "10.0.0.0/8 ",
            "10.0.0/8",
            "fe80::1%eth0/64",
            "fd00::/129",
            "10.0.0.0/+8",
        ] {
            assert!(!is_cidr(value), "{value}");
        }
    }
}
