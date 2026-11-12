import 'dart:io';

import 'package:flutter/foundation.dart';

import 'constant.dart';
import 'print.dart';

/// Clients whose TUN or system proxy overrides this app's when both run.
const _conflictingProcessNames = {
  'clash',
  'clash-meta',
  'clash-verge',
  'clash-verge-service',
  'clash for windows',
  'clash-win64',
  'clash-darwin',
  'clash-linux',
  'mihomo',
  'mihomo-party',
  'clash-party',
  'verge-mihomo',
  'verge-mihomo-alpha',
  'flclash',
  'flclashcore',
  'sing-box',
  'v2ray',
  'v2rayn',
  'xray',
  'nekoray',
  'nekobox',
  'hiddify',
  'hiddifycli',
  'shadowsocks',
  'sslocal',
};

@visibleForTesting
Set<String> parseProcessNames(String stdout, {required bool windows}) {
  final names = <String>{};
  for (final raw in stdout.split('\n')) {
    var line = raw.trim();
    if (line.isEmpty) {
      continue;
    }
    if (windows) {
      if (!line.startsWith('"')) {
        continue;
      }
      line = line.substring(1, line.indexOf('"', 1).clamp(1, line.length));
    } else {
      line = line.split('/').last;
    }
    line = line.toLowerCase();
    if (line.endsWith('.exe')) {
      line = line.substring(0, line.length - 4);
    }
    names.add(line);
  }
  return names;
}

@visibleForTesting
List<String> conflictingProcesses(Set<String> running) {
  return running
      .where(_conflictingProcessNames.contains)
      .where((name) => !name.startsWith(appExecutableName))
      .toList()
    ..sort();
}

Future<List<String>> findConflictingProcesses() async {
  try {
    final result = Platform.isWindows
        ? await Process.run('tasklist', ['/FO', 'CSV', '/NH'])
        : await Process.run('ps', ['-A', '-o', 'comm=']);
    if (result.exitCode != 0) {
      return const [];
    }
    return conflictingProcesses(
      parseProcessNames(result.stdout.toString(), windows: Platform.isWindows),
    );
  } catch (error) {
    commonPrint.log('process list unavailable: $error');
    return const [];
  }
}

Future<bool> isLoopbackPortFree(int port) async {
  try {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
    await socket.close();
    return true;
  } on SocketException {
    return false;
  }
}

Future<int?> nextFreePort(
  int port, {
  int span = 100,
  Future<bool> Function(int port) isFree = isLoopbackPortFree,
}) async {
  for (var candidate = port + 1; candidate <= port + span; candidate++) {
    if (candidate > 65535) {
      break;
    }
    if (await isFree(candidate)) {
      return candidate;
    }
  }
  return null;
}
