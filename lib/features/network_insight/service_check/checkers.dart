// Service availability checkers.
//
// Detection algorithms are ported from Clash Verge Rev
// (https://github.com/clash-verge-rev/clash-verge-rev), crate
// `crates/clash-verge-media-unlock`, `dev` branch as fetched on
// 2026-09-22. Copyright (c) Clash Verge Rev contributors. Clash Verge Rev
// and Panorama Secure Access are both licensed under GPL-3.0.
//
// Deliberate differences from upstream are marked "Differs from upstream".
// The most important one is not here but in the HTTP client
// (see http.dart): upstream disables TLS certificate and host-name
// validation; Panorama keeps both on.

import 'dart:convert';

import 'http.dart';
import 'models.dart';
import 'region.dart';

typedef ServiceChecker = Future<ServiceCheckOutcome> Function(ServiceHttp http);

class ServiceDefinition {
  final String id;
  final String name;
  final ServiceCategory category;
  final Duration timeout;
  final ServiceChecker run;

  const ServiceDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.run,
    this.timeout = defaultServiceCheckTimeout,
  });
}

const defaultServiceCheckTimeout = Duration(seconds: 15);

/// Notes on a `limited` result that the UI shows localized; any other
/// message is technical detail (e.g. "HTTP 429") and shown as-is.
const serviceNoteOriginalsOnly = 'Originals only';
const serviceNoteComingSoon = 'Coming soon';

/// P0 services (brief §31) plus a plain Google connectivity probe.
final List<ServiceDefinition> serviceDefinitions = [
  const ServiceDefinition(
    id: 'chatgpt',
    name: 'ChatGPT',
    category: ServiceCategory.ai,
    run: checkChatGpt,
  ),
  const ServiceDefinition(
    id: 'claude',
    name: 'Claude',
    category: ServiceCategory.ai,
    run: checkClaude,
  ),
  const ServiceDefinition(
    id: 'gemini',
    name: 'Gemini',
    category: ServiceCategory.ai,
    run: checkGemini,
  ),
  const ServiceDefinition(
    id: 'netflix',
    name: 'Netflix',
    category: ServiceCategory.streaming,
    run: checkNetflix,
    timeout: Duration(seconds: 25),
  ),
  const ServiceDefinition(
    id: 'disney_plus',
    name: 'Disney+',
    category: ServiceCategory.streaming,
    run: checkDisneyPlus,
  ),
  const ServiceDefinition(
    id: 'prime_video',
    name: 'Prime Video',
    category: ServiceCategory.streaming,
    run: checkPrimeVideo,
  ),
  const ServiceDefinition(
    id: 'youtube_premium',
    name: 'YouTube Premium',
    category: ServiceCategory.streaming,
    run: checkYouTubePremium,
  ),
  const ServiceDefinition(
    id: 'spotify',
    name: 'Spotify',
    category: ServiceCategory.streaming,
    run: checkSpotify,
  ),
  const ServiceDefinition(
    id: 'tiktok',
    name: 'TikTok',
    category: ServiceCategory.social,
    run: checkTikTok,
  ),
  const ServiceDefinition(
    id: 'bilibili_mainland',
    name: 'Bilibili Mainland',
    category: ServiceCategory.regional,
    run: checkBilibiliMainland,
  ),
  const ServiceDefinition(
    id: 'bilibili_hk_mo_tw',
    name: 'Bilibili HK/MO/TW',
    category: ServiceCategory.regional,
    run: checkBilibiliHkMoTw,
  ),
  const ServiceDefinition(
    id: 'bahamut_anime',
    name: 'Bahamut Anime',
    category: ServiceCategory.regional,
    run: checkBahamutAnime,
  ),
  const ServiceDefinition(
    id: 'google',
    name: 'Google',
    category: ServiceCategory.connectivity,
    run: checkGoogle,
  ),
];

ServiceDefinition? serviceDefinitionById(String id) {
  for (final definition in serviceDefinitions) {
    if (definition.id == id) {
      return definition;
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// Shared helpers (upstream utils.rs)
// ---------------------------------------------------------------------------

Future<String?> _traceLocation(ServiceHttp http, String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    for (final line in const LineSplitter().convert(response.body)) {
      if (line.startsWith('loc=')) {
        return normalizeRegionCode(line.substring(4));
      }
    }
  } on ServiceHttpException {
    return null;
  }
  return null;
}

/// Value of the first `"key": "value"` pair in [body], without JSON-parsing
/// the (often HTML-embedded) document.
String? extractQuotedField(String body, String key) {
  final start = body.indexOf('"$key"');
  if (start == -1) {
    return null;
  }
  var rest = body.substring(start + key.length + 2);
  final colon = rest.indexOf(':');
  if (colon == -1) {
    return null;
  }
  rest = rest.substring(colon + 1).trimLeft();
  if (!rest.startsWith('"')) {
    return null;
  }
  rest = rest.substring(1);
  final end = rest.indexOf('"');
  return end == -1 ? null : rest.substring(0, end);
}

/// 403 / 451 mean the service refused this route; any other non-2xx means
/// we couldn't tell. Null means the response was successful.
ServiceCheckOutcome? _classifyRestrictedStatus(int statusCode) {
  if (statusCode == 403 || statusCode == 451) {
    return ServiceCheckOutcome(
      ServiceCheckStatus.blocked,
      message: 'HTTP $statusCode',
    );
  }
  if (statusCode < 200 || statusCode >= 300) {
    return ServiceCheckOutcome(
      ServiceCheckStatus.unknown,
      message: 'HTTP $statusCode',
    );
  }
  return null;
}

// ---------------------------------------------------------------------------
// AI
// ---------------------------------------------------------------------------

Future<ServiceCheckOutcome> checkChatGpt(ServiceHttp http) async {
  final region = await _traceLocation(
    http,
    'https://chat.openai.com/cdn-cgi/trace',
  );
  final response = await http.get(
    Uri.parse('https://api.openai.com/compliance/cookie_requirements'),
  );
  if (response.body.toLowerCase().contains('unsupported_country')) {
    return ServiceCheckOutcome(
      ServiceCheckStatus.unsupportedRegion,
      regionCode: region,
    );
  }
  return ServiceCheckOutcome(ServiceCheckStatus.available, regionCode: region);
}

const _claudeBlockedRegions = {
  'AF',
  'BY',
  'CN',
  'CU',
  'HK',
  'IR',
  'KP',
  'MO',
  'RU',
  'SY',
};

Future<ServiceCheckOutcome> checkClaude(ServiceHttp http) async {
  final region = await _traceLocation(http, 'https://claude.ai/cdn-cgi/trace');
  if (region == null) {
    return const ServiceCheckOutcome.networkError('No trace location');
  }
  return ServiceCheckOutcome(
    _claudeBlockedRegions.contains(region)
        ? ServiceCheckStatus.unsupportedRegion
        : ServiceCheckStatus.available,
    regionCode: region,
  );
}

const _geminiBlockedRegions = {
  'CHN',
  'RUS',
  'BLR',
  'CUB',
  'IRN',
  'PRK',
  'SYR',
  'HKG',
  'MAC',
};
const _geminiRegionMarker = ',2,1,200,"';
final _threeUpper = RegExp(r'^[A-Z]{3}');

Future<ServiceCheckOutcome> checkGemini(ServiceHttp http) async {
  final response = await http.get(Uri.parse('https://gemini.google.com'));
  final markerAt = response.body.indexOf(_geminiRegionMarker);
  if (markerAt == -1) {
    return const ServiceCheckOutcome.parseError('Region marker not found');
  }
  final rest = response.body.substring(markerAt + _geminiRegionMarker.length);
  final match = _threeUpper.firstMatch(rest);
  if (match == null) {
    return const ServiceCheckOutcome.parseError('Region marker not found');
  }
  final alpha3 = match.group(0)!;
  return ServiceCheckOutcome(
    _geminiBlockedRegions.contains(alpha3)
        ? ServiceCheckStatus.unsupportedRegion
        : ServiceCheckStatus.available,
    regionCode: normalizeRegionCode(alpha3),
  );
}

// ---------------------------------------------------------------------------
// Streaming
// ---------------------------------------------------------------------------

const _fastComUrl =
    'https://api.fast.com/netflix/speedtest/v2?https=true'
    '&token=YXNkZmFzZGxmbnNkYWZoYXNkZmhrYWxm&urlCount=5';

Future<ServiceCheckOutcome> checkNetflix(ServiceHttp http) async {
  final cdn = await _checkNetflixCdn(http);
  if (cdn != null) {
    return cdn;
  }

  final statuses = await Future.wait([
    http.get(Uri.parse('https://www.netflix.com/title/81280792')),
    http.get(Uri.parse('https://www.netflix.com/title/70143836')),
  ]).then((responses) => responses.map((r) => r.statusCode).toList());
  final (first, second) = (statuses[0], statuses[1]);

  if (first == 404 && second == 404) {
    return const ServiceCheckOutcome(
      ServiceCheckStatus.limited,
      message: serviceNoteOriginalsOnly,
    );
  }
  if (first == 403 || second == 403) {
    return const ServiceCheckOutcome(ServiceCheckStatus.blocked);
  }
  if (statuses.any((s) => s == 200 || s == 301)) {
    return ServiceCheckOutcome(
      ServiceCheckStatus.available,
      regionCode: await _netflixRegion(http),
    );
  }
  return ServiceCheckOutcome(
    ServiceCheckStatus.unknown,
    message: 'HTTP ${first}_$second',
  );
}

/// fast.com's API is served by Netflix's CDN: a 403 means this exit IP is
/// banned by Netflix, and a target list reveals the CDN's country.
Future<ServiceCheckOutcome?> _checkNetflixCdn(ServiceHttp http) async {
  final ServiceHttpResponse response;
  try {
    response = await http.get(Uri.parse(_fastComUrl));
  } on ServiceHttpException {
    return null;
  }
  if (response.statusCode == 403) {
    return const ServiceCheckOutcome(
      ServiceCheckStatus.ipRestricted,
      message: 'IP banned by Netflix',
    );
  }
  try {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final targets = data['targets'] as List<dynamic>;
    if (targets.isEmpty) {
      return null;
    }
    final location =
        (targets.first as Map<String, dynamic>)['location']
            as Map<String, dynamic>;
    return ServiceCheckOutcome(
      ServiceCheckStatus.available,
      regionCode: normalizeRegionCode(location['country'] as String?),
    );
  } catch (_) {
    return null;
  }
}

/// Differs from upstream: upstream reads the `location` header after its
/// client has already followed the redirect, so the header is gone and the
/// region falls back to "US". Here the redirect is not followed, which is
/// what the code evidently intends.
Future<String?> _netflixRegion(ServiceHttp http) async {
  try {
    final response = await http.get(
      Uri.parse('https://www.netflix.com/title/80018499'),
      followRedirects: false,
    );
    final location = response.header('location');
    if (location == null) {
      return 'US';
    }
    final segments = location.split('/');
    if (segments.length < 4) {
      return 'US';
    }
    final region = segments[3].split('-').first;
    return normalizeRegionCode(region.isEmpty ? 'US' : region) ?? 'US';
  } on ServiceHttpException {
    return null;
  }
}

const _disneyAuthHeader =
    'Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.'
    'Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84';

Future<ServiceCheckOutcome> checkDisneyPlus(ServiceHttp http) async {
  final device = await http.post(
    Uri.parse('https://disney.api.edge.bamgrid.com/devices'),
    headers: {
      'authorization': _disneyAuthHeader,
      'content-type': 'application/json',
    },
    body: jsonEncode({
      'deviceFamily': 'browser',
      'applicationRuntime': 'chrome',
      'deviceProfile': 'windows',
      'attributes': {},
    }),
  );
  if (device.statusCode == 403) {
    return const ServiceCheckOutcome(
      ServiceCheckStatus.ipRestricted,
      message: 'IP banned by Disney+',
    );
  }
  final String assertion;
  try {
    assertion =
        (jsonDecode(device.body) as Map<String, dynamic>)['assertion']
            as String;
  } catch (_) {
    return const ServiceCheckOutcome.parseError('No device assertion');
  }

  final token = await http.post(
    Uri.parse('https://disney.api.edge.bamgrid.com/token'),
    headers: {
      'authorization': _disneyAuthHeader,
      'content-type': 'application/x-www-form-urlencoded',
    },
    body: Uri(
      queryParameters: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:token-exchange',
        'latitude': '0',
        'longitude': '0',
        'platform': 'browser',
        'subject_token': assertion,
        'subject_token_type': 'urn:bamtech:params:oauth:token-type:device',
      },
    ).query,
  );
  if (token.statusCode == 403 ||
      token.body.contains('forbidden-location') ||
      token.body.contains('403 ERROR')) {
    return const ServiceCheckOutcome(
      ServiceCheckStatus.ipRestricted,
      message: 'IP banned by Disney+',
    );
  }
  final String refreshToken;
  try {
    refreshToken =
        (jsonDecode(token.body) as Map<String, dynamic>)['refresh_token']
            as String;
  } catch (_) {
    return ServiceCheckOutcome.parseError(
      'No refresh token (${token.statusCode})',
    );
  }

  final unavailable = await _disneyUnavailable(http);

  final graph = await http.post(
    Uri.parse('https://disney.api.edge.bamgrid.com/graph/v1/device/graphql'),
    headers: {
      'authorization': _disneyAuthHeader,
      'content-type': 'application/json',
    },
    body: jsonEncode({
      'query':
          'mutation refreshToken(\$input: RefreshTokenInput!) '
          '{ refreshToken(refreshToken: \$input) '
          '{ activeSession { sessionId } } }',
      'variables': {
        'input': {'refreshToken': refreshToken},
      },
    }),
  );
  if (!graph.isSuccess || graph.body.isEmpty) {
    return await _disneyFallbackRegion(http) ??
        ServiceCheckOutcome(
          ServiceCheckStatus.unknown,
          message: 'GraphQL HTTP ${graph.statusCode}',
        );
  }
  final Object? data;
  try {
    data = jsonDecode(graph.body);
  } catch (_) {
    return await _disneyFallbackRegion(http) ??
        const ServiceCheckOutcome.parseError('Invalid GraphQL response');
  }
  final region = normalizeRegionCode(_findJson<String>(data, 'countryCode'));
  if (region == null) {
    return await _disneyFallbackRegion(http) ??
        const ServiceCheckOutcome(ServiceCheckStatus.unsupportedRegion);
  }
  if (region == 'JP') {
    return const ServiceCheckOutcome(
      ServiceCheckStatus.available,
      regionCode: 'JP',
    );
  }
  if (unavailable) {
    return ServiceCheckOutcome(
      ServiceCheckStatus.unsupportedRegion,
      regionCode: region,
    );
  }
  return switch (_findJson<bool>(data, 'inSupportedLocation')) {
    true => ServiceCheckOutcome(
      ServiceCheckStatus.available,
      regionCode: region,
    ),
    false => ServiceCheckOutcome(
      ServiceCheckStatus.limited,
      regionCode: region,
      message: serviceNoteComingSoon,
    ),
    null => ServiceCheckOutcome(
      ServiceCheckStatus.unknown,
      regionCode: region,
      message: 'Unknown region status',
    ),
  };
}

Future<bool> _disneyUnavailable(ServiceHttp http) async {
  try {
    final response = await http.get(Uri.parse('https://disneyplus.com'));
    final url = response.uri.toString();
    return url.contains('preview') || url.contains('unavailable');
  } on ServiceHttpException {
    return true;
  }
}

Future<ServiceCheckOutcome?> _disneyFallbackRegion(ServiceHttp http) async {
  try {
    final response = await http.get(Uri.parse('https://www.disneyplus.com/'));
    final region = normalizeRegionCode(
      extractQuotedField(response.body, 'region'),
    );
    if (region == null) {
      return null;
    }
    return ServiceCheckOutcome(
      ServiceCheckStatus.available,
      regionCode: region,
      message: 'Region from main page',
    );
  } on ServiceHttpException {
    return null;
  }
}

T? _findJson<T>(Object? value, String key) {
  if (value is Map) {
    final direct = value[key];
    if (direct is T) {
      return direct;
    }
    for (final child in value.values) {
      final found = _findJson<T>(child, key);
      if (found != null) {
        return found;
      }
    }
  } else if (value is List) {
    for (final child in value) {
      final found = _findJson<T>(child, key);
      if (found != null) {
        return found;
      }
    }
  }
  return null;
}

Future<ServiceCheckOutcome> checkPrimeVideo(ServiceHttp http) async {
  final response = await http.get(Uri.parse('https://www.primevideo.com'));
  if (response.body.contains('isServiceRestricted')) {
    return const ServiceCheckOutcome(ServiceCheckStatus.unsupportedRegion);
  }
  const marker = '"currentTerritory":"';
  final at = response.body.indexOf(marker);
  if (at == -1) {
    return const ServiceCheckOutcome.parseError('Territory not found');
  }
  final rest = response.body.substring(at + marker.length);
  final end = rest.indexOf('"');
  final region = end == -1 ? null : normalizeRegionCode(rest.substring(0, end));
  if (region == null) {
    return const ServiceCheckOutcome.parseError('Territory not found');
  }
  return ServiceCheckOutcome(ServiceCheckStatus.available, regionCode: region);
}

const _youTubeUnavailablePhrases = [
  'youtube premium is not available in your country',
  'premium is not available in your country',
  'premium is not available in your region',
];
const _youTubeAvailableMarkers = [
  'youtube premium',
  'ad-free',
  '"browseid":"spunlimited"',
];

Future<ServiceCheckOutcome> checkYouTubePremium(ServiceHttp http) async {
  final response = await http.get(
    Uri.parse('https://www.youtube.com/premium?hl=en'),
  );
  final region = _youTubeRegion(response.body);
  final body = response.body.toLowerCase();
  if (_youTubeUnavailablePhrases.any(body.contains)) {
    return ServiceCheckOutcome(
      ServiceCheckStatus.unsupportedRegion,
      regionCode: region,
    );
  }
  if (response.isSuccess && _youTubeAvailableMarkers.any(body.contains)) {
    return ServiceCheckOutcome(
      ServiceCheckStatus.available,
      regionCode: region,
    );
  }
  return ServiceCheckOutcome(
    ServiceCheckStatus.unknown,
    regionCode: region,
    message: 'HTTP ${response.statusCode}',
  );
}

final _youTubeCountryCodeElement = RegExp(
  '''id=["']country-code["'][^>]*>\\s*([^<\\s]+)\\s*<''',
);

String? _youTubeRegion(String body) {
  for (final key in const ['GL', 'countryCode', 'country_code']) {
    final value = extractQuotedField(body, key);
    if (value != null) {
      return normalizeRegionCode(value);
    }
  }
  return normalizeRegionCode(
    _youTubeCountryCodeElement.firstMatch(body)?.group(1),
  );
}

Future<ServiceCheckOutcome> checkSpotify(ServiceHttp http) async {
  final response = await http.get(
    Uri.parse(
      'https://www.spotify.com/api/content/v1/country-selector'
      '?platform=web&format=json',
    ),
  );
  final region =
      _spotifyRegionFromUri(response.uri) ??
      normalizeRegionCode(extractQuotedField(response.body, 'countryCode'));
  final restricted = _classifyRestrictedStatus(response.statusCode);
  if (restricted != null) {
    return ServiceCheckOutcome(
      restricted.status,
      regionCode: region,
      message: restricted.message,
    );
  }
  if (response.body.toLowerCase().contains('not available in your country')) {
    return ServiceCheckOutcome(
      ServiceCheckStatus.unsupportedRegion,
      regionCode: region,
    );
  }
  return ServiceCheckOutcome(ServiceCheckStatus.available, regionCode: region);
}

String? _spotifyRegionFromUri(Uri uri) {
  final segments = uri.pathSegments;
  if (segments.isEmpty || segments.first.isEmpty || segments.first == 'api') {
    return null;
  }
  return normalizeRegionCode(segments.first.split('-').first);
}

// ---------------------------------------------------------------------------
// Social
// ---------------------------------------------------------------------------

const _tikTokBlockedPhrases = [
  'access denied',
  'not available in your region',
  'tiktok is not available',
];

Future<ServiceCheckOutcome> checkTikTok(ServiceHttp http) async {
  var outcome = await _checkTikTokUrl(
    http,
    'https://www.tiktok.com/cdn-cgi/trace',
  );
  if (outcome.regionCode == null ||
      outcome.status == ServiceCheckStatus.networkError ||
      outcome.status == ServiceCheckStatus.unknown) {
    final fallback = await _checkTikTokUrl(http, 'https://www.tiktok.com/');
    outcome = ServiceCheckOutcome(
      outcome.status == ServiceCheckStatus.blocked
          ? outcome.status
          : fallback.status,
      regionCode: outcome.regionCode ?? fallback.regionCode,
      message: outcome.status == ServiceCheckStatus.blocked
          ? outcome.message
          : fallback.message,
    );
  }
  return outcome;
}

Future<ServiceCheckOutcome> _checkTikTokUrl(
  ServiceHttp http,
  String url,
) async {
  final ServiceHttpResponse response;
  try {
    response = await http.get(Uri.parse(url));
  } on ServiceHttpException catch (e) {
    return ServiceCheckOutcome.networkError(e.message);
  }
  final region = _tikTokRegion(response.body);
  final restricted = _classifyRestrictedStatus(response.statusCode);
  if (restricted != null) {
    return ServiceCheckOutcome(
      restricted.status,
      regionCode: region,
      message: restricted.message,
    );
  }
  final body = response.body.toLowerCase();
  return ServiceCheckOutcome(
    _tikTokBlockedPhrases.any(body.contains)
        ? ServiceCheckStatus.blocked
        : ServiceCheckStatus.available,
    regionCode: region,
  );
}

/// Differs from upstream: also reads `loc=` from the Cloudflare trace
/// body. Upstream only looks for a JSON `"region"` field, which the trace
/// endpoint never contains, so it always needed the homepage fallback.
String? _tikTokRegion(String body) {
  final region = extractQuotedField(body, 'region');
  if (region != null) {
    return normalizeRegionCode(region.split('-').first);
  }
  for (final line in const LineSplitter().convert(body)) {
    if (line.startsWith('loc=')) {
      return normalizeRegionCode(line.substring(4));
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// Regional
// ---------------------------------------------------------------------------

const _bilibiliMainlandUrl =
    'https://api.bilibili.com/pgc/player/web/playurl?avid=82846771&qn=0'
    '&type=&otype=json&ep_id=307247&fourk=1&fnver=0&fnval=16&module=bangumi';
const _bilibiliHkMoTwUrl =
    'https://api.bilibili.com/pgc/player/web/playurl?avid=18281381'
    '&cid=29892777&qn=0&type=&otype=json&ep_id=183799&fourk=1&fnver=0'
    '&fnval=16&module=bangumi';

Future<ServiceCheckOutcome> checkBilibiliMainland(ServiceHttp http) =>
    _checkBilibili(http, _bilibiliMainlandUrl);

Future<ServiceCheckOutcome> checkBilibiliHkMoTw(ServiceHttp http) =>
    _checkBilibili(http, _bilibiliHkMoTwUrl);

Future<ServiceCheckOutcome> _checkBilibili(ServiceHttp http, String url) async {
  final response = await http.get(Uri.parse(url));
  final int code;
  try {
    code = (jsonDecode(response.body) as Map<String, dynamic>)['code'] as int;
  } catch (_) {
    return const ServiceCheckOutcome.parseError('Invalid API response');
  }
  return switch (code) {
    0 => const ServiceCheckOutcome(ServiceCheckStatus.available),
    -10403 => const ServiceCheckOutcome(ServiceCheckStatus.unsupportedRegion),
    _ => ServiceCheckOutcome(ServiceCheckStatus.unknown, message: 'code $code'),
  };
}

const _bahamutHeaders = {'user-agent': serviceCheckUserAgent};

Future<ServiceCheckOutcome> checkBahamutAnime(ServiceHttp http) async {
  final device = await http.get(
    Uri.parse('https://ani.gamer.com.tw/ajax/getdeviceid.php'),
    headers: _bahamutHeaders,
  );
  final String deviceId;
  try {
    deviceId =
        (jsonDecode(device.body) as Map<String, dynamic>)['deviceid'] as String;
  } catch (_) {
    return const ServiceCheckOutcome.parseError('No device id');
  }
  final token = await http.get(
    Uri.https('ani.gamer.com.tw', '/ajax/token.php', {
      'adID': '89422',
      'sn': '37783',
      'device': deviceId,
    }),
    headers: _bahamutHeaders,
  );
  if (!token.body.contains('animeSn')) {
    return const ServiceCheckOutcome(ServiceCheckStatus.unsupportedRegion);
  }
  String? region;
  try {
    final home = await http.get(
      Uri.parse('https://ani.gamer.com.tw/'),
      headers: _bahamutHeaders,
    );
    region = normalizeRegionCode(
      RegExp('data-geo="([^"]+)"').firstMatch(home.body)?.group(1),
    );
  } on ServiceHttpException {
    region = null;
  }
  return ServiceCheckOutcome(ServiceCheckStatus.available, regionCode: region);
}

// ---------------------------------------------------------------------------
// Connectivity (not in upstream)
// ---------------------------------------------------------------------------

Future<ServiceCheckOutcome> checkGoogle(ServiceHttp http) async {
  final response = await http.get(
    Uri.parse('https://www.google.com/generate_204'),
  );
  return response.statusCode == 204
      ? const ServiceCheckOutcome(ServiceCheckStatus.available)
      : ServiceCheckOutcome(
          ServiceCheckStatus.unknown,
          message: 'HTTP ${response.statusCode}',
        );
}
