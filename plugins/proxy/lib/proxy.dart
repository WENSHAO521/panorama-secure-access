import 'dart:io';

import 'proxy_platform_interface.dart';
import 'src/linux_proxy.dart';
import 'src/macos_proxy.dart';
import 'src/proxy_command.dart';
import 'src/windows_proxy.dart';

export 'src/proxy_command.dart' show ProxyExecutableChecker, ProxyProcessRunner;

class Proxy {
  static const int _minPort = 1;
  static const int _maxPort = 65535;

  late final ProxyCommandRunner _commandRunner;
  late final LinuxProxy _linuxProxy;
  late final MacosProxy _macosProxy;

  Proxy({
    ProxyProcessRunner? processRunner,
    ProxyExecutableChecker? executableChecker,
  }) {
    final commandRunner = ProxyCommandRunner(processRunner ?? Process.run);
    _commandRunner = commandRunner;
    _linuxProxy = LinuxProxy(
      commandRunner: commandRunner,
      executableChecker: executableChecker,
    );
    _macosProxy = MacosProxy(commandRunner: commandRunner);
  }

  Future<bool> startProxy(
    int port, [
    List<String> bypassDomain = const [],
  ]) async {
    if (port < _minPort || port > _maxPort) {
      return false;
    }
    return switch (Platform.operatingSystem) {
      'macos' => await _macosProxy.start(port, bypassDomain),
      'linux' => await _linuxProxy.start(
        port,
        bypassDomain,
        desktop: Platform.environment['XDG_CURRENT_DESKTOP'],
        homeDir: Platform.environment['HOME'],
      ),
      'windows' => await ProxyPlatform.instance.startProxy(
        port,
        windowsBypassList(bypassDomain),
      ),
      String() => false,
    };
  }

  Future<int?> readLoopbackProxyPort() async {
    return switch (Platform.operatingSystem) {
      'macos' => await _macosProxy.readLoopbackProxyPort(),
      'linux' => await _linuxProxy.readLoopbackProxyPort(
        desktop: Platform.environment['XDG_CURRENT_DESKTOP'],
        homeDir: Platform.environment['HOME'],
      ),
      String() => null,
    };
  }

  Future<bool?> clearStaleProxy() async {
    if (!Platform.isWindows) {
      return null;
    }
    try {
      final result = await _commandRunner.process(
        Platform.resolvedExecutable,
        const ['--clear-stale-proxy'],
      );
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  Future<bool> stopProxy() async {
    return switch (Platform.operatingSystem) {
      'macos' => await _macosProxy.stop(),
      'linux' => await _linuxProxy.stop(
        desktop: Platform.environment['XDG_CURRENT_DESKTOP'],
        homeDir: Platform.environment['HOME'],
      ),
      'windows' => await ProxyPlatform.instance.stopProxy(),
      String() => false,
    };
  }
}
