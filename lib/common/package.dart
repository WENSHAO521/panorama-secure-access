import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import 'common.dart';

extension PackageInfoExtension on PackageInfo {
  String get ua => [
    '$appName/v$version',
    'clash-verge',
    'Platform/${Platform.operatingSystem}',
  ].join(' ');
}

/// Orders `major.minor.patch[-pre][+build]`; a pre-release such as `1.2.0-beta.3`
/// sorts before its release `1.2.0`.
int compareVersions(String version1, String version2) {
  final (core1, pre1, build1) = _splitVersion(version1);
  final (core2, pre2, build2) = _splitVersion(version2);
  for (var i = 0; i < 3; i++) {
    final part1 = i < core1.length ? int.parse(core1[i]) : 0;
    final part2 = i < core2.length ? int.parse(core2[i]) : 0;
    if (part1 != part2) {
      return part1.compareTo(part2);
    }
  }
  if (pre1 != pre2) {
    if (pre1 == null) return 1;
    if (pre2 == null) return -1;
    final result = _comparePreRelease(pre1, pre2);
    if (result != 0) return result;
  }
  return build1.compareTo(build2);
}

(List<String>, String?, int) _splitVersion(String version) {
  final [main, ...build] = version.split('+');
  final dash = main.indexOf('-');
  final core = dash < 0 ? main : main.substring(0, dash);
  return (
    core.split('.'),
    dash < 0 ? null : main.substring(dash + 1),
    build.isEmpty ? 0 : int.parse(build.first),
  );
}

int _comparePreRelease(String pre1, String pre2) {
  final ids1 = pre1.split('.');
  final ids2 = pre2.split('.');
  for (var i = 0; i < ids1.length && i < ids2.length; i++) {
    final num1 = int.tryParse(ids1[i]);
    final num2 = int.tryParse(ids2[i]);
    final result = num1 != null && num2 != null
        ? num1.compareTo(num2)
        : ids1[i].compareTo(ids2[i]);
    if (result != 0) return result;
  }
  return ids1.length.compareTo(ids2.length);
}

const releaseNotesBeginMarker = '<!-- flclash:changelog:begin -->';
const releaseNotesEndMarker = '<!-- flclash:changelog:end -->';

List<String> parseReleaseBody(String? body) {
  if (body == null) return [];
  final regex = RegExp(r'^[ \t]*-[ \t]+(.*)$', multiLine: true);
  return regex
      .allMatches(scopeReleaseNotes(body))
      .map((match) => match.group(1)?.trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

String scopeReleaseNotes(String body) {
  final begin = body.indexOf(releaseNotesBeginMarker);
  if (begin < 0) return body;
  final start = begin + releaseNotesBeginMarker.length;
  final end = body.indexOf(releaseNotesEndMarker, start);
  return end < 0 ? body.substring(start) : body.substring(start, end);
}
