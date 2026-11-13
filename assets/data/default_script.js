/**
 * Panorama Secure Access 默认分流脚本
 *
 * 只改写节点副本、策略组、规则和规则集；端口、DNS、TUN 等设置由应用自己管理。
 * 规则集全部来自 MetaCubeX/meta-rules-dat。
 *
 * 链式代理：设备 -> 链式前置 -> 链式出口 -> 网站。每个节点都会多一份
 * “【落地】”副本，经“链式前置”所选节点连出；在“链式出口”里选落地节点，
 * 再让默认代理或其他策略组选“链式出口”即可。
 */

const RULES_BASE = 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo';
const TEST_URL = 'http://cp.cloudflare.com/generate_204';
// 图标：Koolson/Qure 彩色图标集。
// 订阅里常见的“剩余流量 / 到期时间 / 官网”等信息节点，不参与选择、测速和链式代理。
const INFO_NODES = '剩余|到期|流量|官网|套餐|重置|expire|traffic|remaining|website';

const PROXY = '默认代理';
const AUTO = '自动选择';
const CHAIN_ENTRY = '链式前置';
const CHAIN_EXIT = '链式出口';
const CHAIN_PREFIX = '【落地】';
const CHAIN_PROVIDER_PREFIX = '__chain_exit__';
const DIRECT_GROUP = '国内直连';
const FINAL = '漏网之鱼';

const ICON_BASE = 'https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/';
const ICONS = {
  proxy: ICON_BASE + 'Rocket.png',
  auto: ICON_BASE + 'Auto.png',
  chainEntry: ICON_BASE + 'Airport.png',
  chainExit: ICON_BASE + 'Area.png',
  ai: ICON_BASE + 'ChatGPT.png',
  youtube: ICON_BASE + 'YouTube.png',
  google: ICON_BASE + 'Google_Search.png',
  github: ICON_BASE + 'GitHub.png',
  telegram: ICON_BASE + 'Telegram.png',
  netflix: ICON_BASE + 'Netflix.png',
  disney: ICON_BASE + 'Disney%2B.png',
  spotify: ICON_BASE + 'Spotify.png',
  tiktok: ICON_BASE + 'TikTok.png',
  microsoft: ICON_BASE + 'Microsoft.png',
  apple: ICON_BASE + 'Apple.png',
  direct: ICON_BASE + 'China.png',
  final: ICON_BASE + 'Final.png',
};

const SERVICES = [
  {name: 'AI', icon: 'ai', sites: ['category-ai-!cn']},
  {name: 'YouTube', icon: 'youtube', sites: ['youtube']},
  {name: 'Google', icon: 'google', sites: ['google'], ips: ['google']},
  {name: 'GitHub', icon: 'github', sites: ['github']},
  {name: 'Telegram', icon: 'telegram', sites: ['telegram'], ips: ['telegram']},
  {name: 'Netflix', icon: 'netflix', sites: ['netflix'], ips: ['netflix']},
  {name: 'Disney+', icon: 'disney', sites: ['disney']},
  {name: 'Spotify', icon: 'spotify', sites: ['spotify']},
  {name: 'TikTok', icon: 'tiktok', sites: ['tiktok']},
  {name: 'Microsoft', icon: 'microsoft', sites: ['onedrive', 'microsoft'], preferDirect: true},
  {name: 'Apple', icon: 'apple', sites: ['apple'], preferDirect: true},
];

function main(config) {
  config = config || {};
  const infoNode = new RegExp(INFO_NODES, 'i');
  const nodes = (config.proxies || []).filter(
    (node) => node && typeof node.name === 'string' && !node.name.startsWith(CHAIN_PREFIX),
  );
  const providers = config['proxy-providers'] || {};
  const providerNames = Object.keys(providers).filter(
    (name) => !name.startsWith(CHAIN_PROVIDER_PREFIX),
  );
  const hasNodes = nodes.length > 0 || providerNames.length > 0;

  if (hasNodes) {
    addChainCopies(config, nodes, providers, providerNames, infoNode);
  }

  const ruleProviders = {};
  const site = (name) => {
    const key = 'site_' + name;
    ruleProviders[key] = ruleSet('domain', RULES_BASE + '/geosite/' + name + '.mrs');
    return key;
  };
  const ip = (name) => {
    const key = 'ip_' + name;
    ruleProviders[key] = ruleSet('ipcidr', RULES_BASE + '/geoip/' + name + '.mrs');
    return key;
  };
  const viaProxy = hasNodes ? [PROXY, CHAIN_EXIT, 'DIRECT'] : [PROXY, 'DIRECT'];
  const viaDirect = hasNodes ? ['DIRECT', PROXY, CHAIN_EXIT] : ['DIRECT', PROXY];

  const groups = [
    selectGroup(PROXY, hasNodes ? [AUTO, CHAIN_EXIT, 'DIRECT'] : ['DIRECT'], 'proxy'),
  ];
  if (hasNodes) {
    groups.push(
      {
        'name': AUTO,
        'type': 'url-test',
        'include-all': true,
        'exclude-filter': plainNodesOnly(),
        'url': TEST_URL,
        'interval': 300,
        'tolerance': 50,
        'lazy': true,
        'icon': ICONS.auto,
      },
      selectGroup(CHAIN_ENTRY, [], 'chainEntry'),
      {
        'name': CHAIN_EXIT,
        'type': 'select',
        'include-all': true,
        'filter': '^' + CHAIN_PREFIX,
        'exclude-filter': '(?i)' + INFO_NODES,
        'icon': ICONS.chainExit,
      },
    );
  }

  const rules = [
    'RULE-SET,' + site('private') + ',DIRECT',
    'RULE-SET,' + ip('private') + ',DIRECT,no-resolve',
  ];
  const ipRules = [];
  for (const service of SERVICES) {
    groups.push(selectGroup(service.name, service.preferDirect ? viaDirect : viaProxy, service.icon));
    for (const name of service.sites) {
      rules.push('RULE-SET,' + site(name) + ',' + service.name);
    }
    for (const name of service.ips || []) {
      ipRules.push('RULE-SET,' + ip(name) + ',' + service.name + ',no-resolve');
    }
  }
  groups.push(
    selectGroup(DIRECT_GROUP, viaDirect, 'direct'),
    selectGroup(FINAL, viaProxy, 'final'),
  );
  rules.push(
    'RULE-SET,' + site('geolocation-!cn') + ',' + PROXY,
    'RULE-SET,' + site('cn') + ',' + DIRECT_GROUP,
    ...ipRules,
    'RULE-SET,' + ip('cn') + ',' + DIRECT_GROUP,
    'MATCH,' + FINAL,
  );

  config['proxy-groups'] = groups;
  config['rules'] = rules;
  config['rule-providers'] = ruleProviders;
  return config;
}

function addChainCopies(config, nodes, providers, providerNames, infoNode) {
  config.proxies = [
    ...nodes,
    ...nodes
      .filter((node) => !infoNode.test(node.name))
      .map((node) => ({...node, 'name': CHAIN_PREFIX + node.name, 'dialer-proxy': CHAIN_ENTRY})),
  ];
  for (const name of providerNames) {
    const provider = providers[name];
    const override = provider.override || {};
    providers[CHAIN_PROVIDER_PREFIX + name] = {
      ...provider,
      'override': {
        ...override,
        'additional-prefix': CHAIN_PREFIX + (override['additional-prefix'] || ''),
        'dialer-proxy': CHAIN_ENTRY,
      },
    };
  }
  config['proxy-providers'] = providers;
}

function plainNodesOnly() {
  return '(?i)' + INFO_NODES + '|^' + CHAIN_PREFIX;
}

function selectGroup(name, proxies, icon) {
  const group = {
    'name': name,
    'type': 'select',
    'include-all': true,
    'exclude-filter': plainNodesOnly(),
    'icon': ICONS[icon],
  };
  if (proxies.length > 0) {
    group.proxies = proxies;
  }
  return group;
}

function ruleSet(behavior, url) {
  return {
    'type': 'http',
    'behavior': behavior,
    'format': 'mrs',
    'interval': 86400,
    'url': url,
  };
}
