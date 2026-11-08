import 'dart:io';

import 'package:path/path.dart' as path;

import 'proxy_command.dart';

enum LinuxProxyBackend { gnome, mate, kde }

enum _ProxyType { http, https, socks }

const _fallbackBackends = [LinuxProxyBackend.gnome, LinuxProxyBackend.kde];

class LinuxProxy {
  final ProxyCommandRunner _commandRunner;
  final ProxyExecutableChecker _executableChecker;

  LinuxProxy({
    required ProxyCommandRunner commandRunner,
    ProxyExecutableChecker? executableChecker,
  }) : _commandRunner = commandRunner,
       _executableChecker = executableChecker ?? _hasExecutable;

  Future<bool> start(
    int port,
    List<String> bypassDomain, {
    required String? desktop,
    required String? homeDir,
  }) async {
    if (homeDir == null || homeDir.isEmpty) {
      return false;
    }
    final selection = await _resolveBackend(desktop);
    if (selection == null) {
      return false;
    }
    return _commandRunner.run(
      LinuxProxyCommands.buildStartForBackend(
        port: port,
        bypassDomain: bypassDomain,
        homeDir: homeDir,
        backend: selection.backend,
        kdeConfigWriter: selection.executable,
      ),
    );
  }

  Future<bool> stop({
    required String? desktop,
    required String? homeDir,
  }) async {
    if (homeDir == null || homeDir.isEmpty) {
      return false;
    }
    final selection = await _resolveBackend(desktop);
    if (selection == null) {
      return false;
    }
    return _commandRunner.run(
      LinuxProxyCommands.buildStopForBackend(
        homeDir: homeDir,
        backend: selection.backend,
        kdeConfigWriter: selection.executable,
      ),
    );
  }

  /// GNOME, MATE and KDE keep the setting across a killed run, like macOS.
  Future<int?> readLoopbackProxyPort({
    required String? desktop,
    required String? homeDir,
  }) async {
    if (homeDir == null || homeDir.isEmpty) {
      return null;
    }
    final selection = await _resolveBackend(desktop);
    if (selection == null) {
      return null;
    }
    return switch (selection.backend) {
      LinuxProxyBackend.gnome => _readGSettingsPort('org.gnome.system.proxy'),
      LinuxProxyBackend.mate => _readGSettingsPort('org.mate.system.proxy'),
      LinuxProxyBackend.kde => _readKdePort(
        homeDir,
        selection.executable.replaceFirst('kwrite', 'kread'),
      ),
    };
  }

  Future<int?> _readGSettingsPort(String schemaPrefix) async {
    final mode = await _output('gsettings', ['get', schemaPrefix, 'mode']);
    if (LinuxProxyCommands.unquote(mode) != 'manual') {
      return null;
    }
    final host = await _output('gsettings', [
      'get',
      '$schemaPrefix.http',
      'host',
    ]);
    final port = await _output('gsettings', [
      'get',
      '$schemaPrefix.http',
      'port',
    ]);
    return LinuxProxyCommands.loopbackPort(
      LinuxProxyCommands.unquote(host),
      port?.trim(),
    );
  }

  Future<int?> _readKdePort(String homeDir, String executable) async {
    List<String> key(String name) => [
      '--file',
      path.join(homeDir, '.config', 'kioslaverc'),
      '--group',
      'Proxy Settings',
      '--key',
      name,
    ];
    if ((await _output(executable, key('ProxyType')))?.trim() != '1') {
      return null;
    }
    final url = Uri.tryParse(
      (await _output(executable, key('httpProxy')))?.trim() ?? '',
    );
    if (url == null || !url.hasPort) {
      return null;
    }
    return LinuxProxyCommands.loopbackPort(url.host, '${url.port}');
  }

  Future<String?> _output(String executable, List<String> arguments) async {
    try {
      final result = await _commandRunner.process(executable, arguments);
      return result.exitCode == 0 ? result.stdout.toString() : null;
    } on ProcessException {
      return null;
    }
  }

  Future<_LinuxBackendSelection?> _resolveBackend(String? desktop) async {
    final preferredBackend = LinuxProxyCommands.preferredBackend(desktop);
    if (preferredBackend != null) {
      return _resolveSelection(preferredBackend);
    }
    for (final backend in _fallbackBackends) {
      final selection = await _resolveSelection(backend);
      if (selection != null) {
        return selection;
      }
    }
    return null;
  }

  Future<_LinuxBackendSelection?> _resolveSelection(
    LinuxProxyBackend backend,
  ) async {
    switch (backend) {
      case LinuxProxyBackend.gnome:
      case LinuxProxyBackend.mate:
        if (await _executableChecker('gsettings')) {
          return _LinuxBackendSelection(backend, 'gsettings');
        }
        return null;
      case LinuxProxyBackend.kde:
        for (final executable in const ['kwriteconfig6', 'kwriteconfig5']) {
          if (await _executableChecker(executable)) {
            return _LinuxBackendSelection(backend, executable);
          }
        }
    }
    return null;
  }

  static Future<bool> _hasExecutable(String executable) async {
    try {
      final result = await Process.run('which', [executable]);
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }
}

class LinuxProxyCommands {
  static String? unquote(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.length < 2) {
      return trimmed;
    }
    return trimmed.startsWith("'") && trimmed.endsWith("'")
        ? trimmed.substring(1, trimmed.length - 1)
        : trimmed;
  }

  static int? loopbackPort(String? host, String? port) {
    final value = int.tryParse(port ?? '');
    if (host == null ||
        value == null ||
        value < 1 ||
        value > 65535 ||
        !(host == 'localhost' || host == '::1' || host.startsWith('127.'))) {
      return null;
    }
    return value;
  }

  static LinuxProxyBackend? preferredBackend(String? desktop) {
    final desktops = _desktops(desktop);
    if (desktops.contains('KDE')) {
      return LinuxProxyBackend.kde;
    }
    if (desktops.contains('MATE')) {
      return LinuxProxyBackend.mate;
    }
    if (desktops.any(
      (desktop) =>
          const {'GNOME', 'CINNAMON', 'BUDGIE', 'UNITY'}.contains(desktop),
    )) {
      return LinuxProxyBackend.gnome;
    }
    return null;
  }

  static List<ProxyCommand> buildStart({
    required int port,
    required List<String> bypassDomain,
    required String? desktop,
    required String homeDir,
    Set<String>? availableExecutables,
  }) {
    final backend = _resolveBackend(
      desktop: desktop,
      availableExecutables: availableExecutables,
    );
    if (backend == null) {
      return [];
    }
    return buildStartForBackend(
      port: port,
      bypassDomain: bypassDomain,
      homeDir: homeDir,
      backend: backend,
      kdeConfigWriter: _resolveKdeConfigWriter(availableExecutables),
    );
  }

  static List<ProxyCommand> buildStop({
    required String? desktop,
    required String homeDir,
    Set<String>? availableExecutables,
  }) {
    final backend = _resolveBackend(
      desktop: desktop,
      availableExecutables: availableExecutables,
    );
    if (backend == null) {
      return [];
    }
    return buildStopForBackend(
      homeDir: homeDir,
      backend: backend,
      kdeConfigWriter: _resolveKdeConfigWriter(availableExecutables),
    );
  }

  static List<ProxyCommand> buildStartForBackend({
    required int port,
    required List<String> bypassDomain,
    required String homeDir,
    required LinuxProxyBackend backend,
    required String kdeConfigWriter,
  }) {
    return switch (backend) {
      LinuxProxyBackend.gnome => _buildGSettingsStart(
        port: port,
        bypassDomain: bypassDomain,
        schemaPrefix: 'org.gnome.system.proxy',
      ),
      LinuxProxyBackend.mate => _buildGSettingsStart(
        port: port,
        bypassDomain: bypassDomain,
        schemaPrefix: 'org.mate.system.proxy',
      ),
      LinuxProxyBackend.kde => _buildKdeStart(
        port: port,
        bypassDomain: bypassDomain,
        homeDir: homeDir,
        executable: kdeConfigWriter,
      ),
    };
  }

  static List<ProxyCommand> buildStopForBackend({
    required String homeDir,
    required LinuxProxyBackend backend,
    required String kdeConfigWriter,
  }) {
    return switch (backend) {
      LinuxProxyBackend.gnome => _buildGSettingsStop(
        schemaPrefix: 'org.gnome.system.proxy',
      ),
      LinuxProxyBackend.mate => _buildGSettingsStop(
        schemaPrefix: 'org.mate.system.proxy',
      ),
      LinuxProxyBackend.kde => _buildKdeStop(
        homeDir: homeDir,
        executable: kdeConfigWriter,
      ),
    };
  }

  static LinuxProxyBackend? _resolveBackend({
    required String? desktop,
    required Set<String>? availableExecutables,
  }) {
    final preferred = preferredBackend(desktop);
    if (preferred != null) {
      if (availableExecutables == null ||
          _isBackendAvailable(preferred, availableExecutables)) {
        return preferred;
      }
      return null;
    }
    if (availableExecutables == null) {
      return LinuxProxyBackend.gnome;
    }
    for (final backend in _fallbackBackends) {
      if (_isBackendAvailable(backend, availableExecutables)) {
        return backend;
      }
    }
    return null;
  }

  static bool _isBackendAvailable(
    LinuxProxyBackend backend,
    Set<String> availableExecutables,
  ) {
    return switch (backend) {
      LinuxProxyBackend.gnome ||
      LinuxProxyBackend.mate => availableExecutables.contains('gsettings'),
      LinuxProxyBackend.kde =>
        availableExecutables.contains('kwriteconfig6') ||
            availableExecutables.contains('kwriteconfig5'),
    };
  }

  static String _resolveKdeConfigWriter(Set<String>? availableExecutables) {
    if (availableExecutables?.contains('kwriteconfig6') ?? false) {
      return 'kwriteconfig6';
    }
    return 'kwriteconfig5';
  }

  static List<ProxyCommand> _buildGSettingsStart({
    required int port,
    required List<String> bypassDomain,
    required String schemaPrefix,
  }) {
    final commands = <ProxyCommand>[
      ProxyCommand('gsettings', [
        'set',
        schemaPrefix,
        'ignore-hosts',
        _formatGSettingsStringList(bypassDomain),
      ]),
    ];
    for (final type in _ProxyType.values) {
      commands.addAll([
        ProxyCommand('gsettings', [
          'set',
          '$schemaPrefix.${type.name}',
          'host',
          proxyHost,
        ]),
        ProxyCommand('gsettings', [
          'set',
          '$schemaPrefix.${type.name}',
          'port',
          '$port',
        ]),
      ]);
    }
    commands.add(
      ProxyCommand('gsettings', ['set', schemaPrefix, 'mode', 'manual']),
    );
    return commands;
  }

  static List<ProxyCommand> _buildGSettingsStop({
    required String schemaPrefix,
  }) {
    return [
      ProxyCommand('gsettings', ['set', schemaPrefix, 'mode', 'none']),
    ];
  }

  static List<ProxyCommand> _buildKdeStart({
    required int port,
    required List<String> bypassDomain,
    required String homeDir,
    required String executable,
  }) {
    final configFile = path.join(homeDir, '.config', 'kioslaverc');
    return [
      ProxyCommand(executable, [
        '--file',
        configFile,
        '--group',
        'Proxy Settings',
        '--key',
        'NoProxyFor',
        bypassDomain.join(','),
      ]),
      for (final type in _ProxyType.values)
        ProxyCommand(executable, [
          '--file',
          configFile,
          '--group',
          'Proxy Settings',
          '--key',
          '${type.name}Proxy',
          '${type == _ProxyType.socks ? 'socks' : 'http'}://$proxyHost:$port',
        ]),
      ProxyCommand(executable, [
        '--file',
        configFile,
        '--group',
        'Proxy Settings',
        '--key',
        'ProxyType',
        '1',
      ]),
      _kdeReparseConfiguration,
    ];
  }

  static List<ProxyCommand> _buildKdeStop({
    required String homeDir,
    required String executable,
  }) {
    return [
      ProxyCommand(executable, [
        '--file',
        path.join(homeDir, '.config', 'kioslaverc'),
        '--group',
        'Proxy Settings',
        '--key',
        'ProxyType',
        '0',
      ]),
      _kdeReparseConfiguration,
    ];
  }

  /// Running KIO programs keep the settings they read at startup until this
  /// signal, which is what the KDE proxy settings page sends after saving.
  static final _kdeReparseConfiguration = ProxyCommand('dbus-send', [
    '--session',
    '--type=signal',
    '/KIO/Scheduler',
    'org.kde.KIO.Scheduler.reparseSlaveConfiguration',
    'string:',
  ], optional: true);

  static String _formatGSettingsStringList(List<String> values) {
    final escaped = values.map((value) {
      return value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
    });
    return "[${escaped.map((value) => "'$value'").join(', ')}]";
  }

  static Set<String> _desktops(String? desktop) {
    if (desktop == null || desktop.isEmpty) {
      return {};
    }
    return desktop
        .split(':')
        .map((value) => value.trim().toUpperCase())
        .where((value) => value.isNotEmpty)
        .toSet();
  }
}

class _LinuxBackendSelection {
  final LinuxProxyBackend backend;
  final String executable;

  const _LinuxBackendSelection(this.backend, this.executable);
}
