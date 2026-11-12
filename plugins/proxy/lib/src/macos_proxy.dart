import 'dart:io';

import 'package:flutter/foundation.dart';

import 'proxy_command.dart';

class MacosProxy {
  final ProxyCommandRunner _commandRunner;

  MacosProxy({required ProxyCommandRunner commandRunner})
    : _commandRunner = commandRunner;

  /// Taken at the first start of a run; by a later one the settings are ours.
  Map<String, MacosServiceProxy>? _snapshot;

  Future<bool> start(int port, List<String> bypassDomain) async {
    final services = await _networkServices();
    _snapshot ??= await _readServices(services, ownPort: port);
    return _commandRunner.run(
      services.expand(
        (service) => MacosProxyCommands.buildStart(service, port, bypassDomain),
      ),
    );
  }

  Future<bool> stop() async {
    final services = await _networkServices();
    final snapshot = _snapshot;
    final restored = await _commandRunner.run(
      services.expand(
        (service) => snapshot == null
            ? MacosProxyCommands.buildStop(service)
            : MacosProxyCommands.buildRestore(
                service,
                snapshot[service] ?? MacosServiceProxy.none,
              ),
      ),
    );
    if (restored) {
      _snapshot = null;
    }
    return restored;
  }

  Future<Map<String, MacosServiceProxy>> _readServices(
    List<String> services, {
    required int ownPort,
  }) async {
    Future<String> read(List<String> arguments) async {
      try {
        final result = await _commandRunner.process(
          '/usr/sbin/networksetup',
          arguments,
        );
        return result.exitCode == 0 ? result.stdout.toString() : '';
      } on ProcessException {
        return '';
      }
    }

    Future<MacosProxyEntry> entry(String getter, String service) async {
      final value = MacosProxyEntry.parse(await read([getter, service]));
      return value.port == ownPort &&
              MacosProxyCommands.isLoopbackHost(value.server)
          ? MacosProxyEntry.off
          : value;
    }

    return {
      for (final service in services)
        service: MacosServiceProxy(
          web: await entry('-getwebproxy', service),
          secureWeb: await entry('-getsecurewebproxy', service),
          socks: await entry('-getsocksfirewallproxy', service),
          bypass: MacosProxyCommands.parseBypassDomains(
            await read(['-getproxybypassdomains', service]),
          ),
        ),
    };
  }

  /// The loopback port the system proxy is enabled for, or null when none is.
  Future<int?> readLoopbackProxyPort() async {
    final ProcessResult result;
    try {
      result = await _commandRunner.process('/usr/sbin/scutil', ['--proxy']);
    } on ProcessException {
      return null;
    }
    if (result.exitCode != 0) {
      return null;
    }
    return MacosProxyCommands.parseLoopbackProxyPort(result.stdout.toString());
  }

  Future<List<String>> _networkServices() async {
    try {
      final result = await _commandRunner.process('/usr/sbin/networksetup', [
        '-listallnetworkservices',
      ]);
      if (result.exitCode != 0) {
        return [];
      }
      return MacosProxyCommands.parseNetworkServices(result.stdout.toString());
    } on ProcessException {
      return [];
    }
  }
}

@immutable
class MacosProxyEntry {
  final bool enabled;
  final String server;
  final int port;

  const MacosProxyEntry({
    required this.enabled,
    required this.server,
    required this.port,
  });

  static const off = MacosProxyEntry(enabled: false, server: '', port: 0);

  static MacosProxyEntry parse(String stdout) {
    final values = <String, String>{};
    for (final line in stdout.split('\n')) {
      final separator = line.indexOf(':');
      if (separator == -1) {
        continue;
      }
      values[line.substring(0, separator).trim()] = line
          .substring(separator + 1)
          .trim();
    }
    return MacosProxyEntry(
      enabled: values['Enabled'] == 'Yes',
      server: values['Server'] ?? '',
      port: int.tryParse(values['Port'] ?? '') ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MacosProxyEntry &&
      other.enabled == enabled &&
      other.server == server &&
      other.port == port;

  @override
  int get hashCode => Object.hash(enabled, server, port);
}

@immutable
class MacosServiceProxy {
  final MacosProxyEntry web;
  final MacosProxyEntry secureWeb;
  final MacosProxyEntry socks;
  final List<String> bypass;

  const MacosServiceProxy({
    required this.web,
    required this.secureWeb,
    required this.socks,
    required this.bypass,
  });

  static const none = MacosServiceProxy(
    web: MacosProxyEntry.off,
    secureWeb: MacosProxyEntry.off,
    socks: MacosProxyEntry.off,
    bypass: [],
  );
}

class MacosProxyCommands {
  /// Leaves the automatic proxy (PAC) alone: start never turns it on.
  static List<ProxyCommand> buildRestore(
    String service,
    MacosServiceProxy previous,
  ) {
    List<ProxyCommand> entry(String kind, MacosProxyEntry value) => [
      if (value.server.isNotEmpty && value.port > 0)
        ProxyCommand('/usr/sbin/networksetup', [
          '-set$kind',
          service,
          value.server,
          '${value.port}',
        ]),
      ProxyCommand('/usr/sbin/networksetup', [
        '-set${kind}state',
        service,
        value.enabled ? 'on' : 'off',
      ]),
    ];

    return [
      ...entry('webproxy', previous.web),
      ...entry('securewebproxy', previous.secureWeb),
      ...entry('socksfirewallproxy', previous.socks),
      buildProxyBypass(service, previous.bypass),
    ];
  }

  /// With no domains, networksetup prints a sentence instead.
  static List<String> parseBypassDomains(String stdout) {
    return stdout
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.contains(' '))
        .toList();
  }

  static List<ProxyCommand> buildStart(
    String service,
    int port,
    List<String> bypassDomain,
  ) {
    return [
      ProxyCommand('/usr/sbin/networksetup', [
        '-setwebproxy',
        service,
        proxyHost,
        '$port',
      ]),
      ProxyCommand('/usr/sbin/networksetup', [
        '-setsecurewebproxy',
        service,
        proxyHost,
        '$port',
      ]),
      ProxyCommand('/usr/sbin/networksetup', [
        '-setsocksfirewallproxy',
        service,
        proxyHost,
        '$port',
      ]),
      buildProxyBypass(service, bypassDomain),
      ProxyCommand('/usr/sbin/networksetup', [
        '-setwebproxystate',
        service,
        'on',
      ]),
      ProxyCommand('/usr/sbin/networksetup', [
        '-setsecurewebproxystate',
        service,
        'on',
      ]),
      ProxyCommand('/usr/sbin/networksetup', [
        '-setsocksfirewallproxystate',
        service,
        'on',
      ]),
    ];
  }

  static List<ProxyCommand> buildStop(String service) {
    return [
      ProxyCommand('/usr/sbin/networksetup', [
        '-setautoproxystate',
        service,
        'off',
      ]),
      ProxyCommand('/usr/sbin/networksetup', [
        '-setwebproxystate',
        service,
        'off',
      ]),
      ProxyCommand('/usr/sbin/networksetup', [
        '-setsecurewebproxystate',
        service,
        'off',
      ]),
      ProxyCommand('/usr/sbin/networksetup', [
        '-setsocksfirewallproxystate',
        service,
        'off',
      ]),
      buildProxyBypass(service, const []),
    ];
  }

  static ProxyCommand buildProxyBypass(
    String service,
    List<String> bypassDomain,
  ) {
    return ProxyCommand('/usr/sbin/networksetup', [
      '-setproxybypassdomains',
      service,
      if (bypassDomain.isEmpty) 'Empty' else ...bypassDomain,
    ]);
  }

  /// Reads what `scutil --proxy` reports; only a loopback host answers.
  static int? parseLoopbackProxyPort(String stdout) {
    final values = <String, String>{};
    for (final line in stdout.split('\n')) {
      final separator = line.indexOf(' : ');
      if (separator == -1) {
        continue;
      }
      final key = line.substring(0, separator).trim();
      values[key] = _withoutQuotes(line.substring(separator + 3).trim());
    }
    for (final kind in const ['HTTP', 'HTTPS', 'SOCKS']) {
      if (values['${kind}Enable'] != '1') {
        continue;
      }
      final host = values['${kind}Proxy'];
      final port = int.tryParse(values['${kind}Port'] ?? '');
      if (host == null ||
          port == null ||
          port < 1 ||
          port > 65535 ||
          !isLoopbackHost(host)) {
        continue;
      }
      return port;
    }
    return null;
  }

  static const _loopbackHosts = {'localhost', '::1', '0:0:0:0:0:0:0:1'};

  static bool isLoopbackHost(String host) {
    return _loopbackHosts.contains(host) || host.startsWith('127.');
  }

  static String _withoutQuotes(String value) {
    return value.replaceAll('"', '');
  }

  static List<String> parseNetworkServices(String stdout) {
    return stdout
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .where((line) => !line.startsWith('*'))
        .where((line) => !line.startsWith('An asterisk '))
        .toList();
  }
}
