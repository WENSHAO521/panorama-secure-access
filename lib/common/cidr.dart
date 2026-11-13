import 'package:rust_api/netcfg.dart' as native;

/// The addresses of [include] that [exclude] leaves, as the fewest CIDR
/// blocks that cover them, IPv4 first. With [wholeWhenEmpty], a family
/// [include] names no block of counts as its whole address space. Entries that
/// do not parse are ignored.
Future<List<String>> subtractCidrs(
  List<String> include,
  List<String> exclude, {
  bool wholeWhenEmpty = false,
}) => native.subtractCidrs(
  include: include,
  exclude: exclude,
  wholeWhenEmpty: wholeWhenEmpty,
);

/// As strict as Go's netip.ParsePrefix, since the core fails a whole config or
/// update on one CIDR that parser refuses.
bool isCidr(String value) => native.isCidr(value: value);

/// The sniffer's address lists also take mihomo's geoip: and rule-set: items.
bool isIpMatcher(String value) => native.isIpMatcher(value: value);
