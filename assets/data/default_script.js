/**
 * Bundled default script of Panorama Secure Access.
 * Based on https://raw.githubusercontent.com/hheshenghuan-cloud/ziji/refs/heads/main/flclash.js
 * with only the two chain group icons replaced.
 */
/**
 * FlClash / Mihomo 配置脚本
 * 用法：在 FlClash 的脚本配置中导入本文件，然后将其应用到订阅配置。
 * 脚本接收订阅解析后的配置对象，并返回修改后的配置对象。
 * 已加入链式代理：设备 -> 链式前置 -> 链式出口 -> 网站。
 * 在两个链式组分别选择节点，再让默认代理或应用策略组选择“链式出口”。
 */
function main(config) {
  config = config || {};

  Object.assign(config, {
    'mixed-port': 7890,
    'socks-port': 7891,
    'redir-port': 7892,
    'port': 7893,
    'tproxy-port': 7894,
    'allow-lan': true,
    'bind-address': '*',
    'ipv6': false,
    'unified-delay': true,
    'tcp-concurrent': true,
    'find-process-mode': 'always',
    'log-level': 'warning',
    'keep-alive-idle': 600,
    'keep-alive-interval': 15,
    'external-controller': '0.0.0.0:9090',
    'secret': 'diyhh',
    'profile': {
      'store-selected': true,
      'store-fake-ip': true
    },
    'sniffer': {
      'enable': true,
      'force-dns-mapping': false,
      'parse-pure-ip': true,
      'sniff': {
        'HTTP': {
          'ports': [80, '8080-8880'],
          'override-destination': false
        },
        'TLS': {
          'ports': [443, 8443],
          'override-destination': false
        },
        'QUIC': {
          'ports': [443, 8443],
          'override-destination': false
        }
      },
      'skip-domain': ['Mijia Cloud', '+.push.apple.com', 'mtalk.google.com']
    },
    'tun': {
      'enable': true,
      'stack': 'mixed',
      'dns-hijack': ['any:53', 'tcp://any:53']
    },
    'dns': {
      'enable': true,
      'cache-algorithm': 'arc',
      'listen': '0.0.0.0:1053',
      'ipv6': false,
      'respect-rules': true,
      'enhanced-mode': 'fake-ip',
      'fake-ip-range': '198.18.0.1/16',
      'fake-ip-filter-mode': 'blacklist',
      'direct-nameserver-follow-policy': true,
      'nameserver-policy': {
        'rule-set:googlefcm': ['https://8.8.8.8/dns-query']
      },
      'default-nameserver': ['https://223.5.5.5/dns-query'],
      'proxy-server-nameserver': ['https://dns.alidns.com/dns-query', 'https://doh.pub/dns-query'],
      'proxy-server-nameserver-policy': {'+.v51124-4.qpon': ['tcp://bc0e2d336f8bdb37d44e7f52d7841e3c46c5d23c.9fe06a.fyi:8080']},
      'direct-nameserver': ['https://dns.alidns.com/dns-query', 'https://doh.pub/dns-query'],
      'nameserver': ['https://8.8.8.8/dns-query', 'https://1.1.1.1/dns-query'],
      'fake-ip-filter': ['+.push.apple.com', 'mtalk.google.com', 'rule-set:fakeipfilter_domain']
    },
    'proxy-groups': [
      {'name': '默认代理', 'type': 'select', 'include-all': true, 'proxies': ['DIRECT'], 'icon': 'https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/Rocket.png'},
      {'name': 'YouTube', 'type': 'select', 'include-all': true, 'proxies': ['默认代理', 'DIRECT'], 'icon': 'https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/YouTube.png'},
      {'name': 'Google', 'type': 'select', 'include-all': true, 'proxies': ['默认代理', 'DIRECT'], 'icon': 'https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/Google_Search.png'},
      {'name': 'GoogleFCM', 'type': 'select', 'include-all': true, 'proxies': ['默认代理', 'DIRECT'], 'icon': 'https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/Rocket.png'},
      {'name': 'ChatGPT', 'type': 'select', 'include-all': true, 'proxies': ['默认代理', 'DIRECT'], 'icon': 'https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/ChatGPT.png'},
      {'name': 'GitHub', 'type': 'select', 'include-all': true, 'proxies': ['默认代理', 'DIRECT'], 'icon': 'https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/GitHub.png'},
      {'name': 'OneDrive', 'type': 'select', 'include-all': true, 'proxies': ['默认代理', 'DIRECT'], 'icon': 'https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/OneDrive.png'},
      {'name': 'Microsoft', 'type': 'select', 'include-all': true, 'proxies': ['默认代理', 'DIRECT'], 'icon': 'https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/Microsoft.png'},
      {'name': 'TikTok', 'type': 'select', 'include-all': true, 'proxies': ['默认代理', 'DIRECT'], 'icon': 'https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/TikTok.png'},
      {'name': 'APPLE', 'type': 'select', 'include-all': true, 'proxies': ['默认代理', 'DIRECT'], 'icon': 'https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/Apple.png'},
      {'name': 'Telegram', 'type': 'select', 'include-all': true, 'proxies': ['默认代理', 'DIRECT'], 'icon': 'https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/Telegram.png'},
      {'name': 'NETFLIX', 'type': 'select', 'include-all': true, 'proxies': ['默认代理', 'DIRECT'], 'icon': 'https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/Netflix.png'},
      {'name': 'Disney', 'type': 'select', 'include-all': true, 'proxies': ['默认代理', 'DIRECT'], 'icon': 'https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/Disney%2B.png'},
      {'name': '国内网络', 'type': 'select', 'include-all': true, 'proxies': ['DIRECT', '默认代理'], 'icon': 'https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/China.png'},
      {'name': '漏网之鱼', 'type': 'select', 'include-all': true, 'proxies': ['默认代理', 'DIRECT'], 'icon': 'https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/Final.png'}
    ],
    'rules': [
      'DOMAIN-SUFFIX,fxltsbl.com,REJECT',
      'RULE-SET,ziji,默认代理',
      'RULE-SET,private_ip,国内网络,no-resolve',
      'RULE-SET,private_domain,国内网络',
      'RULE-SET,cn_domain,国内网络',
      'RULE-SET,cn_ip,国内网络',
      'RULE-SET,zijign,国内网络',
      'RULE-SET,fakeipfilter_domain,国内网络',
      'RULE-SET,googlefcm,GoogleFCM',
      'AND,((DST-PORT,443),(NETWORK,UDP)),REJECT',
      'RULE-SET,ai,ChatGPT',
      'RULE-SET,github_domain,GitHub',
      'RULE-SET,youtube_domain,YouTube',
      'RULE-SET,google_domain,Google',
      'RULE-SET,onedrive_domain,OneDrive',
      'RULE-SET,microsoft_domain,Microsoft',
      'RULE-SET,apple_domain,APPLE',
      'RULE-SET,tiktok_domain,TikTok',
      'RULE-SET,telegram_domain,Telegram',
      'RULE-SET,netflix_domain,NETFLIX',
      'RULE-SET,disney_domain,Disney',
      'RULE-SET,apple_ip,APPLE',
      'RULE-SET,google_ip,Google',
      'RULE-SET,netflix_ip,NETFLIX',
      'RULE-SET,telegram_ip,Telegram',
      'RULE-SET,proxylite,默认代理',
      'RULE-SET,geolocation-!cn,默认代理',
      'MATCH,漏网之鱼'
    ],
    'rule-providers': {
      'ziji': {'type': 'http', 'interval': 86400, 'behavior': 'domain', 'format': 'yaml', 'url': 'https://raw.githubusercontent.com/hheshenghuan-cloud/ziji/main/ziji.yaml'},
      'zijign': {'type': 'http', 'interval': 86400, 'behavior': 'domain', 'format': 'yaml', 'url': 'https://raw.githubusercontent.com/hheshenghuan-cloud/ziji/main/zijign.yaml'},
      'googlefcm': {'type': 'http', 'interval': 86400, 'behavior': 'domain', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/googlefcm.mrs'},
      'fakeipfilter_domain': {'type': 'http', 'interval': 86400, 'behavior': 'domain', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/DustinWin/ruleset_geodata/mihomo-ruleset/fakeip-filter.mrs'},
      'private_domain': {'type': 'http', 'interval': 86400, 'behavior': 'domain', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/private.mrs'},
      'proxylite': {'type': 'http', 'interval': 86400, 'behavior': 'classical', 'format': 'text', 'url': 'https://raw.githubusercontent.com/qichiyuhub/rule/main/rules/proxy.list'},
      'ai': {'type': 'http', 'interval': 86400, 'behavior': 'domain', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/category-ai-!cn.mrs'},
      'youtube_domain': {'type': 'http', 'interval': 86400, 'behavior': 'domain', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/youtube.mrs'},
      'google_domain': {'type': 'http', 'interval': 86400, 'behavior': 'domain', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/google.mrs'},
      'github_domain': {'type': 'http', 'interval': 86400, 'behavior': 'domain', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/github.mrs'},
      'telegram_domain': {'type': 'http', 'interval': 86400, 'behavior': 'domain', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/telegram.mrs'},
      'netflix_domain': {'type': 'http', 'interval': 86400, 'behavior': 'domain', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/netflix.mrs'},
      'onedrive_domain': {'type': 'http', 'interval': 86400, 'behavior': 'domain', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/onedrive.mrs'},
      'microsoft_domain': {'type': 'http', 'interval': 86400, 'behavior': 'domain', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/microsoft.mrs'},
      'apple_domain': {'type': 'http', 'interval': 86400, 'behavior': 'domain', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/apple.mrs'},
      'speedtest_domain': {'type': 'http', 'interval': 86400, 'behavior': 'domain', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/ookla-speedtest.mrs'},
      'tiktok_domain': {'type': 'http', 'interval': 86400, 'behavior': 'domain', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/tiktok.mrs'},
      'geolocation-!cn': {'type': 'http', 'interval': 86400, 'behavior': 'domain', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/geolocation-!cn.mrs'},
      'cn_domain': {'type': 'http', 'interval': 86400, 'behavior': 'domain', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/cn.mrs'},
      'disney_domain': {'type': 'http', 'interval': 86400, 'behavior': 'domain', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/GitMetaio/rule/refs/heads/master/rule/Clash/Disney/Disney_OCD_Domain.mrs'},
      'private_ip': {'type': 'http', 'interval': 86400, 'behavior': 'ipcidr', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/private.mrs'},
      'cn_ip': {'type': 'http', 'interval': 86400, 'behavior': 'ipcidr', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/cn.mrs'},
      'google_ip': {'type': 'http', 'interval': 86400, 'behavior': 'ipcidr', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/google.mrs'},
      'telegram_ip': {'type': 'http', 'interval': 86400, 'behavior': 'ipcidr', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/telegram.mrs'},
      'netflix_ip': {'type': 'http', 'interval': 86400, 'behavior': 'ipcidr', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/netflix.mrs'},
      'apple_ip': {'type': 'http', 'interval': 86400, 'behavior': 'ipcidr', 'format': 'mrs', 'url': 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo-lite/geoip/apple.mrs'}
    }
  });
  return addChainProxy(config);
}

// 链式前置 / 链式出口 icons are drawn for Panorama Secure Access (original
// artwork, no third-party license) and embedded so they show offline.
const ENTRY_ICON = 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMDggMTA4Ij48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9ImEiIHgxPSIwIiB5MT0iMCIgeDI9IjEiIHkyPSIxIj48c3RvcCBvZmZzZXQ9IjAiIHN0b3AtY29sb3I9IiMyRkQzRjUiLz48c3RvcCBvZmZzZXQ9IjEiIHN0b3AtY29sb3I9IiMyMTY1RTgiLz48L2xpbmVhckdyYWRpZW50PjwvZGVmcz48cGF0aCBkPSJNNTYgMTJoMjZhMTQgMTQgMCAwIDEgMTQgMTR2NTZhMTQgMTQgMCAwIDEtMTQgMTRINTZhNyA3IDAgMCAxIDAtMTRoMjZWMjZINTZhNyA3IDAgMCAxIDAtMTR6IiBmaWxsPSJ1cmwoI2EpIi8+PHBhdGggZD0iTTQ1IDMwYTcgNyAwIDAgMSA5LjkgMGwxOSAxOWE3IDcgMCAwIDEgMCA5LjlsLTE5IDE5QTcgNyAwIDAgMSA0NSA2OGw3LjEtN0gxOGE3IDcgMCAwIDEgMC0xNGgzNC4xTDQ1IDQwYTcgNyAwIDAgMSAwLTEweiIgZmlsbD0idXJsKCNhKSIvPjwvc3ZnPg==';
const EXIT_ICON = 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMDggMTA4Ij48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9ImIiIHgxPSIwIiB5MT0iMCIgeDI9IjEiIHkyPSIxIj48c3RvcCBvZmZzZXQ9IjAiIHN0b3AtY29sb3I9IiNGRkM5M0MiLz48c3RvcCBvZmZzZXQ9IjEiIHN0b3AtY29sb3I9IiNGRjVBMkMiLz48L2xpbmVhckdyYWRpZW50PjwvZGVmcz48cGF0aCBkPSJNMjggODJjLTkgMi41LTE0IDYtMTQgOS41QzE0IDk4IDMyIDEwMiA1NCAxMDJzNDAtNCA0MC0xMC41YzAtMy41LTUtNy0xNC05LjVsLTMuNiA1LjdDODMgODkgODYgOTAuNCA4NiA5MS41YzAgMi40LTEyLjUgNS41LTMyIDUuNXMtMzItMy4xLTMyLTUuNWMwLTEuMSAzLTIuNSA5LjYtMy44eiIgZmlsbD0idXJsKCNiKSIgb3BhY2l0eT0iLjg1Ii8+PHBhdGggZD0iTTU0IDZjLTE5LjMgMC0zNSAxNS4yLTM1IDM0IDAgMjQuNSAzMC4yIDUwLjIgMzEuNSA1MS4zYTUuNCA1LjQgMCAwIDAgNyAwQzU4LjggOTAuMiA4OSA2NC41IDg5IDQwIDg5IDIxLjIgNzMuMyA2IDU0IDZ6bTAgNDdhMTMgMTMgMCAxIDEgMC0yNiAxMyAxMyAwIDAgMSAwIDI2eiIgZmlsbD0idXJsKCNiKSIvPjwvc3ZnPg==';

function addChainProxy(config) {
  const ENTRY = '链式前置';
  const EXIT = '链式出口';
  const PREFIX = '【落地】';
  const PROVIDER_PREFIX = '__chain_exit__';
  const nodes = (config.proxies || []).filter(node => !node.name.startsWith(PREFIX));
  config.proxies = [...nodes, ...nodes.map(node => ({
    ...node,
    'name': PREFIX + node.name,
    'dialer-proxy': ENTRY
  }))];

  // 同时支持 proxy-providers 形式的节点订阅。
  const providers = config['proxy-providers'] || {};
  for (const [name, provider] of Object.entries(providers).filter(([name]) => !name.startsWith(PROVIDER_PREFIX))) {
    providers[PROVIDER_PREFIX + name] = {
      ...provider,
      'override': {
        ...provider.override,
        'override-expr': [
          ...((provider.override || {})['override-expr'] || []),
          '.name = ' + JSON.stringify(PREFIX + name + ' / ') + ' + .name',
          '."dialer-proxy" = ' + JSON.stringify(ENTRY)
        ]
      }
    };
    if (provider.type === 'http') {
      providers[PROVIDER_PREFIX + name].path = './proxy_providers/chain-' + encodeURIComponent(name) + '.yaml';
    }
  }

  for (const group of config['proxy-groups']) {
    group['exclude-filter'] = '^' + PREFIX;
    group.proxies.push(EXIT);
  }
  config['proxy-groups'].push(
    {'name': ENTRY, 'type': 'select', 'include-all': true, 'exclude-filter': '^' + PREFIX, 'empty-fallback': 'REJECT', 'icon': ENTRY_ICON},
    {'name': EXIT, 'type': 'select', 'include-all': true, 'filter': '^' + PREFIX, 'empty-fallback': 'REJECT', 'icon': EXIT_ICON}
  );
  return config;
}
