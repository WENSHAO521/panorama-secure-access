import 'package:rust_api/netcfg.dart' as native;

bool isHost(String value) => native.isHost(value: value);

/// mihomo starts no DNS server, and only logs why, for an address this refuses.
bool isListenAddress(String value) => native.isListenAddress(value: value);

bool isPortRange(String value) => native.isPortRange(value: value);
