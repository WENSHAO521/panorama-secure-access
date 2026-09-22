import 'dart:convert';

import 'package:fl_clash/features/network_insight/service_check/checkers.dart';
import 'package:fl_clash/features/network_insight/service_check/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_service_http.dart';

const _openAiTrace = 'https://chat.openai.com/cdn-cgi/trace';
const _openAiCompliance =
    'https://api.openai.com/compliance/cookie_requirements';
const _claudeTrace = 'https://claude.ai/cdn-cgi/trace';
const _fastCom = 'https://api.fast.com/netflix/speedtest/v2';
const _netflixTitleA = 'https://www.netflix.com/title/81280792';
const _netflixTitleB = 'https://www.netflix.com/title/70143836';
const _netflixRegion = 'https://www.netflix.com/title/80018499';

String _trace(String loc) => 'fl=1\nip=203.0.113.9\nloc=$loc\nwarp=off\n';

Future<ServiceCheckOutcome> _run(
  ServiceChecker checker,
  Map<String, FakeHandler> routes,
) => checker(FakeServiceHttp(routes));

void main() {
  group('ChatGPT', () {
    test('available, with region from the Cloudflare trace', () async {
      final outcome = await _run(checkChatGpt, {
        _openAiTrace: reply(_trace('JP')),
        _openAiCompliance: reply('{"cookie_consent": false}'),
      });
      expect(outcome.status, ServiceCheckStatus.available);
      expect(outcome.regionCode, 'JP');
    });

    test('unsupported_country maps to unsupportedRegion', () async {
      final outcome = await _run(checkChatGpt, {
        _openAiTrace: reply(_trace('CN')),
        _openAiCompliance: reply(
          '{"error":{"code":"unsupported_country"}}',
          status: 403,
        ),
      });
      expect(outcome.status, ServiceCheckStatus.unsupportedRegion);
      expect(outcome.regionCode, 'CN');
    });

    test('a failed trace still reports availability, without region', () async {
      final outcome = await _run(checkChatGpt, {
        _openAiTrace: failWith(),
        _openAiCompliance: reply('{}'),
      });
      expect(outcome.status, ServiceCheckStatus.available);
      expect(outcome.regionCode, isNull);
    });
  });

  group('Claude', () {
    test('supported region', () async {
      final outcome = await _run(checkClaude, {
        _claudeTrace: reply(_trace('US')),
      });
      expect(outcome.status, ServiceCheckStatus.available);
      expect(outcome.regionCode, 'US');
    });

    test('unsupported region', () async {
      final outcome = await _run(checkClaude, {
        _claudeTrace: reply(_trace('HK')),
      });
      expect(outcome.status, ServiceCheckStatus.unsupportedRegion);
      expect(outcome.regionCode, 'HK');
    });

    test('no trace location is a network error, not a verdict', () async {
      final outcome = await _run(checkClaude, {_claudeTrace: failWith()});
      expect(outcome.status, ServiceCheckStatus.networkError);
    });
  });

  group('Gemini', () {
    const url = 'https://gemini.google.com';

    test('reads the alpha-3 region and normalises it to alpha-2', () async {
      final outcome = await _run(checkGemini, {
        url: reply('...[1,2,3],2,1,200,"JPN",null...'),
      });
      expect(outcome.status, ServiceCheckStatus.available);
      expect(outcome.regionCode, 'JP');
    });

    test('blocked region', () async {
      final outcome = await _run(checkGemini, {
        url: reply('xx,2,1,200,"CHN"yy'),
      });
      expect(outcome.status, ServiceCheckStatus.unsupportedRegion);
      expect(outcome.regionCode, 'CN');
    });

    test('page without the marker is a parse error', () async {
      final outcome = await _run(checkGemini, {url: reply('<html></html>')});
      expect(outcome.status, ServiceCheckStatus.parseError);
    });
  });

  group('Netflix', () {
    test('fast.com 403 means the exit IP is banned', () async {
      final outcome = await _run(checkNetflix, {
        _fastCom: reply('Forbidden', status: 403),
      });
      expect(outcome.status, ServiceCheckStatus.ipRestricted);
    });

    test('fast.com targets give the CDN country', () async {
      final outcome = await _run(checkNetflix, {
        _fastCom: reply(
          jsonEncode({
            'targets': [
              {
                'location': {'country': 'JP'},
              },
            ],
          }),
        ),
      });
      expect(outcome.status, ServiceCheckStatus.available);
      expect(outcome.regionCode, 'JP');
    });

    test('both non-original titles missing means originals only', () async {
      final outcome = await _run(checkNetflix, {
        _fastCom: failWith(),
        _netflixTitleA: reply('', status: 404),
        _netflixTitleB: reply('', status: 404),
      });
      expect(outcome.status, ServiceCheckStatus.limited);
      expect(outcome.message, 'Originals only');
    });

    test('403 on a title page means blocked', () async {
      final outcome = await _run(checkNetflix, {
        _fastCom: failWith(),
        _netflixTitleA: reply('', status: 403),
        _netflixTitleB: reply('', status: 200),
      });
      expect(outcome.status, ServiceCheckStatus.blocked);
    });

    test('region comes from the unfollowed redirect', () async {
      final http = FakeServiceHttp({
        _fastCom: failWith(),
        _netflixTitleA: reply('', status: 200),
        _netflixTitleB: reply('', status: 200),
        _netflixRegion: reply(
          '',
          status: 302,
          headers: {'location': 'https://www.netflix.com/hk-en/title/80018499'},
        ),
      });
      final outcome = await checkNetflix(http);
      expect(outcome.status, ServiceCheckStatus.available);
      expect(outcome.regionCode, 'HK');
      final regionRequest = http.requests.singleWhere(
        (r) => r.uri.toString() == _netflixRegion,
      );
      expect(regionRequest.followRedirects, isFalse);
    });

    test('no redirect means the US catalogue', () async {
      final outcome = await _run(checkNetflix, {
        _fastCom: failWith(),
        _netflixTitleA: reply('', status: 200),
        _netflixTitleB: reply('', status: 200),
        _netflixRegion: reply('', status: 200),
      });
      expect(outcome.regionCode, 'US');
    });
  });

  group('Disney+', () {
    const devices = 'https://disney.api.edge.bamgrid.com/devices';
    const token = 'https://disney.api.edge.bamgrid.com/token';
    const graph = 'https://disney.api.edge.bamgrid.com/graph/v1/device/graphql';
    const home = 'https://disneyplus.com';
    const homeWww = 'https://www.disneyplus.com/';

    Map<String, FakeHandler> flow({
      required Object graphBody,
      String homeUrl = 'https://www.disneyplus.com/en-jp',
    }) => {
      devices: reply('{"assertion":"a"}'),
      token: reply('{"refresh_token":"r"}'),
      home: reply('', url: homeUrl),
      graph: reply(jsonEncode(graphBody)),
    };

    test('IP banned at device registration', () async {
      final outcome = await _run(checkDisneyPlus, {
        devices: reply('', status: 403),
      });
      expect(outcome.status, ServiceCheckStatus.ipRestricted);
    });

    test('forbidden location at token exchange', () async {
      final outcome = await _run(checkDisneyPlus, {
        devices: reply('{"assertion":"a"}'),
        token: reply('{"error":"forbidden-location"}', status: 400),
      });
      expect(outcome.status, ServiceCheckStatus.ipRestricted);
    });

    test('supported location', () async {
      final outcome = await _run(
        checkDisneyPlus,
        flow(
          graphBody: {
            'extensions': {
              'sdk': {
                'session': {'inSupportedLocation': true, 'countryCode': 'SG'},
              },
            },
          },
        ),
      );
      expect(outcome.status, ServiceCheckStatus.available);
      expect(outcome.regionCode, 'SG');
    });

    test('not yet launched in the region', () async {
      final outcome = await _run(
        checkDisneyPlus,
        flow(
          graphBody: {
            'session': {'inSupportedLocation': false, 'countryCode': 'VN'},
          },
        ),
      );
      expect(outcome.status, ServiceCheckStatus.limited);
      expect(outcome.message, 'Coming soon');
    });

    test('home page redirecting to /unavailable means unsupported', () async {
      final outcome = await _run(
        checkDisneyPlus,
        flow(
          graphBody: {
            'session': {'inSupportedLocation': true, 'countryCode': 'CN'},
          },
          homeUrl: 'https://www.disneyplus.com/unavailable',
        ),
      );
      expect(outcome.status, ServiceCheckStatus.unsupportedRegion);
    });

    test('GraphQL failure falls back to the region on the main page', () async {
      final outcome = await _run(checkDisneyPlus, {
        devices: reply('{"assertion":"a"}'),
        token: reply('{"refresh_token":"r"}'),
        home: reply(''),
        graph: reply('', status: 500),
        homeWww: reply('{"region":"KR"}'),
      });
      expect(outcome.status, ServiceCheckStatus.available);
      expect(outcome.regionCode, 'KR');
    });
  });

  group('Prime Video', () {
    const url = 'https://www.primevideo.com';

    test('territory', () async {
      final outcome = await _run(checkPrimeVideo, {
        url: reply('..."currentTerritory":"DE",...'),
      });
      expect(outcome.status, ServiceCheckStatus.available);
      expect(outcome.regionCode, 'DE');
    });

    test('service restricted', () async {
      final outcome = await _run(checkPrimeVideo, {
        url: reply('{"isServiceRestricted":true}'),
      });
      expect(outcome.status, ServiceCheckStatus.unsupportedRegion);
    });

    test('unexpected page', () async {
      final outcome = await _run(checkPrimeVideo, {url: reply('<html/>')});
      expect(outcome.status, ServiceCheckStatus.parseError);
    });
  });

  group('YouTube Premium', () {
    const url = 'https://www.youtube.com/premium';

    test('available, region from GL', () async {
      final outcome = await _run(checkYouTubePremium, {
        url: reply('{"GL":"jp"} Enjoy ad-free videos'),
      });
      expect(outcome.status, ServiceCheckStatus.available);
      expect(outcome.regionCode, 'JP');
    });

    test('not available in the country', () async {
      final outcome = await _run(checkYouTubePremium, {
        url: reply('YouTube Premium is not available in your country.'),
      });
      expect(outcome.status, ServiceCheckStatus.unsupportedRegion);
    });

    test('region from the country-code element', () async {
      final outcome = await _run(checkYouTubePremium, {
        url: reply('<span id="country-code">TW</span> ad-free'),
      });
      expect(outcome.regionCode, 'TW');
    });

    test('neither marker present is unknown', () async {
      final outcome = await _run(checkYouTubePremium, {
        url: reply('<html>captcha</html>', status: 429),
      });
      expect(outcome.status, ServiceCheckStatus.unknown);
      expect(outcome.message, 'HTTP 429');
    });
  });

  group('Spotify', () {
    const url = 'https://www.spotify.com/api/content/v1/country-selector';

    test('region from the redirected path', () async {
      final outcome = await _run(checkSpotify, {
        url: reply('{}', url: 'https://www.spotify.com/jp-ja/select-country'),
      });
      expect(outcome.status, ServiceCheckStatus.available);
      expect(outcome.regionCode, 'JP');
    });

    test('451 means blocked', () async {
      final outcome = await _run(checkSpotify, {url: reply('', status: 451)});
      expect(outcome.status, ServiceCheckStatus.blocked);
    });
  });

  group('TikTok', () {
    const trace = 'https://www.tiktok.com/cdn-cgi/trace';
    const home = 'https://www.tiktok.com/';

    test('trace alone is enough when it reports a region', () async {
      final http = FakeServiceHttp({trace: reply(_trace('JP'))});
      final outcome = await checkTikTok(http);
      expect(outcome.status, ServiceCheckStatus.available);
      expect(outcome.regionCode, 'JP');
      expect(http.requests, hasLength(1));
    });

    test('a block on the trace is kept even if the homepage loads', () async {
      final outcome = await _run(checkTikTok, {
        trace: reply('', status: 403),
        home: reply('{"region":"US-CA"}'),
      });
      expect(outcome.status, ServiceCheckStatus.blocked);
      expect(outcome.regionCode, 'US');
    });
  });

  group('Bilibili', () {
    const api = 'https://api.bilibili.com/pgc/player/web/playurl';

    test('code 0 is available', () async {
      final outcome = await _run(checkBilibiliMainland, {
        api: reply('{"code":0}'),
      });
      expect(outcome.status, ServiceCheckStatus.available);
    });

    test('-10403 is region-locked', () async {
      final outcome = await _run(checkBilibiliHkMoTw, {
        api: reply('{"code":-10403}'),
      });
      expect(outcome.status, ServiceCheckStatus.unsupportedRegion);
    });

    test('other codes are unknown, not a verdict', () async {
      final outcome = await _run(checkBilibiliMainland, {
        api: reply('{"code":-404}'),
      });
      expect(outcome.status, ServiceCheckStatus.unknown);
    });

    test('non-JSON is a parse error', () async {
      final outcome = await _run(checkBilibiliMainland, {api: reply('<html>')});
      expect(outcome.status, ServiceCheckStatus.parseError);
    });
  });

  group('Bahamut Anime', () {
    const device = 'https://ani.gamer.com.tw/ajax/getdeviceid.php';
    const token = 'https://ani.gamer.com.tw/ajax/token.php';
    const home = 'https://ani.gamer.com.tw/';

    test('available with region', () async {
      final http = FakeServiceHttp({
        device: reply('{"deviceid":"abc"}'),
        token: reply('{"animeSn":37783}'),
        home: reply('<div data-geo="TW"></div>'),
      });
      final outcome = await checkBahamutAnime(http);
      expect(outcome.status, ServiceCheckStatus.available);
      expect(outcome.regionCode, 'TW');
      final tokenRequest = http.requests.singleWhere(
        (r) => r.uri.path == '/ajax/token.php',
      );
      expect(tokenRequest.uri.queryParameters['device'], 'abc');
    });

    test('no animeSn means outside the licensed region', () async {
      final outcome = await _run(checkBahamutAnime, {
        device: reply('{"deviceid":"abc"}'),
        token: reply('{"error":{"code":1000}}'),
      });
      expect(outcome.status, ServiceCheckStatus.unsupportedRegion);
    });
  });

  group('Google', () {
    const url = 'https://www.google.com/generate_204';

    test('204 means reachable', () async {
      final outcome = await _run(checkGoogle, {url: reply('', status: 204)});
      expect(outcome.status, ServiceCheckStatus.available);
    });

    test('a captive portal page is not treated as reachable', () async {
      final outcome = await _run(checkGoogle, {
        url: reply('<html>login</html>', status: 200),
      });
      expect(outcome.status, ServiceCheckStatus.unknown);
    });
  });

  group('extractQuotedField', () {
    test('finds the first key with a string value', () {
      expect(extractQuotedField('{"a": 1, "region" : "JP"}', 'region'), 'JP');
    });

    test('non-string values yield null', () {
      expect(extractQuotedField('{"region": 42}', 'region'), isNull);
    });
  });

  test('every P0 service is defined with a unique id', () {
    final ids = serviceDefinitions.map((d) => d.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(
      ids,
      containsAll([
        'chatgpt',
        'claude',
        'gemini',
        'netflix',
        'disney_plus',
        'prime_video',
        'youtube_premium',
        'spotify',
        'tiktok',
        'bilibili_mainland',
        'bilibili_hk_mo_tw',
        'bahamut_anime',
      ]),
    );
  });
}
