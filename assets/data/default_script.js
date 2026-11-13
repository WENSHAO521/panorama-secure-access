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
// 图标：Phosphor Icons（MIT）实心款，按品牌色着色；Netflix 取自 Simple Icons（CC0）。
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

const ICONS = {
  proxy: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNTYgMjU2Ij48ZyBmaWxsPSIjOEI2Q0ZGIiBjb2xvcj0iIzhCNkNGRiI+PHBhdGggZmlsbD0iIzhCNkNGRiIgZD0iTTEwMS44NSAxOTEuMTRDOTcuMzQgMjAxIDgyLjI5IDIyNCA0MCAyMjRhOCA4IDAgMCAxLTgtOGMwLTQyLjI5IDIzLTU3LjM0IDMyLjg2LTYxLjg1YTggOCAwIDAgMSA2LjY0IDE0LjU2Yy02LjQzIDIuOTMtMjAuNjIgMTIuMzYtMjMuMTIgMzguOTFjMjYuNTUtMi41IDM2LTE2LjY5IDM4LjkxLTIzLjEyYTggOCAwIDEgMSAxNC41NiA2LjY0bTEyMi0xNDRhMTYgMTYgMCAwIDAtMTUtMTVjLTEyLjU4LS43NS00NC43My40LTcxLjQgMjcuMDdMODggMTA4LjdhOCA4IDAgMCAxLTExLjMzLTExLjMxbDI2LjU2LTI2LjU3YTQgNCAwIDAgMC0yLjgyLTYuODJINzQuMzVBMTUuOSAxNS45IDAgMCAwIDYzIDY4LjY4TDI4LjcgMTAzYTE2IDE2IDAgMCAwIDkuMDcgMjcuMTZsMzguNDcgNS4zN2w0NC4yMSA0NC4yMWw1LjM3IDM4LjQ5YTE1Ljk0IDE1Ljk0IDAgMCAwIDEwLjc4IDEyLjkyYTE2LjEgMTYuMSAwIDAgMCA1LjEuODNhMTUuOSAxNS45IDAgMCAwIDExLjMtNC42OGwzNC4zMi0zNC4zYTE2IDE2IDAgMCAwIDQuNjgtMTEuMzV2LTI2LjA2YTQgNCAwIDAgMC02LjgzLTIuODJsLTI2LjU3IDI2LjU2YTggOCAwIDAgMS0xMS43MS0uNDJhOC4yIDguMiAwIDAgMSAuNi0xMS4xbDQ5LjI3LTQ5LjI3YzI2LjY5LTI2LjY4IDI3Ljg0LTU4LjgzIDI3LjA5LTcxLjQyWiIvPjwvZz48L3N2Zz4=',
  auto: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNTYgMjU2Ij48ZyBmaWxsPSIjRjVCODNEIiBjb2xvcj0iI0Y1QjgzRCI+PHBhdGggZmlsbD0iI0Y1QjgzRCIgZD0ibTIxMy44NSAxMjUuNDZsLTExMiAxMjBhOCA4IDAgMCAxLTEzLjY5LTdsMTQuNjYtNzMuMzNsLTU3LjYzLTIxLjY0YTggOCAwIDAgMS0zLTEzbDExMi0xMjBhOCA4IDAgMCAxIDEzLjY5IDdsLTE0LjcgNzMuNDFsNTcuNjMgMjEuNjFhOCA4IDAgMCAxIDMgMTIuOTVaIi8+PC9nPjwvc3ZnPg==',
  chainEntry: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNTYgMjU2Ij48ZyBmaWxsPSIjM0I5RUZGIiBjb2xvcj0iIzNCOUVGRiI+PHBhdGggZmlsbD0iIzNCOUVGRiIgZD0iTTE3NiAyMTZhOCA4IDAgMCAxLTggOEgyNGE4IDggMCAwIDEgMC0xNmgxNDRhOCA4IDAgMCAxIDggOG03MC4zMS0xMjkuMjRsLTE4LjY0LTIzLjg5bC0uMTItLjE1YTM5LjgyIDM5LjgyIDAgMCAwLTUxLjI4LTkuMTJMMTI0LjcgODQuMzhMNzAuNzYgNjQuNTRhOCA4IDAgMCAwLTUuNTkgMEw1OCA2Ny4yN2wtLjMyLjEzYTE2IDE2IDAgMCAwLTQuNTMgMjYuNDdMNzUgMTE1LjA2bC0yMC4xNyAxMi4ybC0yOC4yNi05LjU0YTggOCAwIDAgMC02LjA4LjRsLTMgMS40N0ExNiAxNiAwIDAgMCAxMyAxNDUuOGwzNiAzNS4yN2wuMTIuMTJhMzkuNzggMzkuNzggMCAwIDAgMjcuMjggMTAuODdhNDAuMiA0MC4yIDAgMCAwIDIwLjI2LTUuNTJsMTQ3LjQxLTg4YTggOCAwIDAgMCAyLjIxLTExLjc4WiIvPjwvZz48L3N2Zz4=',
  chainExit: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNTYgMjU2Ij48ZyBmaWxsPSIjMTJCNUE2IiBjb2xvcj0iIzEyQjVBNiI+PHBhdGggZmlsbD0iIzEyQjVBNiIgZD0iTTI1NiAyMTZhOCA4IDAgMCAxLTggOEgxMDRhOCA4IDAgMCAxIDAtMTZoMTQ0YTggOCAwIDAgMSA4IDhtLTI0LTI0YTggOCAwIDAgMCA4LTh2LTM1LjY4YTQwLjEzIDQwLjEzIDAgMCAwLTI5LjI4LTM4LjU0bC02MC44NC0xN2wtMjIuNS01My42M2E4IDggMCAwIDAtNC44NS00LjVsLTUuNDctMS44MkExNiAxNiAwIDAgMCA5NiA0OHYyOS4zOWwtMjkuODctOC41MWwtMTAuNjEtMjkuMzdhOCA4IDAgMCAwLTUtNC44N2wtNS40Ny0xLjgyQTE2IDE2IDAgMCAwIDI0IDQ4djU1LjcyYTQwLjEyIDQwLjEyIDAgMCAwIDI5LjIxIDM4LjUybDE3Ni42MyA0OS40NmE4IDggMCAwIDAgMi4xNi4zIi8+PC9nPjwvc3ZnPg==',
  ai: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNTYgMjU2Ij48ZyBmaWxsPSIjMTBBMzdGIiBjb2xvcj0iIzEwQTM3RiI+PHBhdGggZmlsbD0iIzEwQTM3RiIgZD0iTTIyNC4zMiAxMTQuMjRhNTYgNTYgMCAwIDAtNjAuMDctNzYuNTdhNTYgNTYgMCAwIDAtOTYuMzIgMTMuNzdhNTYgNTYgMCAwIDAtMzYuMjUgOTAuMzJBNTYgNTYgMCAwIDAgNjkgMjE3YTU2LjQgNTYuNCAwIDAgMCAxNC41OSAyYTU2IDU2IDAgMCAwIDguMTctLjYxYTU2IDU2IDAgMCAwIDk2LjMxLTEzLjc4YTU2IDU2IDAgMCAwIDM2LjI1LTkwLjMyWm0tODAuMzIgMjNsLTE2IDkuMjRsLTE2LTkuMjR2LTE4LjQ4bDE2LTkuMjRsMTYgOS4yNFptMzguODUtODIuODFhNDAgNDAgMCAwIDEgMjguNTYgNDhhNTEgNTEgMCAwIDAtMi45MS0xLjgxTDE2NCA3NC44OGE4IDggMCAwIDAtOCAwbC00NCAyNS40MVY4MS44MWw0MC41LTIzLjM4YTM5Ljc2IDM5Ljc2IDAgMCAxIDMwLjM1LTRtLTE0MiAzMi41YTM5Ljc1IDM5Ljc1IDAgMCAxIDIzLjI3LTE4LjM2QTU2IDU2IDAgMCAwIDY0IDcydjUxLjM4YTggOCAwIDAgMCA0IDYuOTNsNDQgMjUuNEw5NiAxNjVsLTQwLjUtMjMuNDNhNDAgNDAgMCAwIDEtMTQuNjQtNTQuNjRaTTEzNiAyMjRhMzkuOCAzOS44IDAgMCAxLTI3LjUyLTEwLjk1YzEtLjUxIDItMS4wNSAzLTEuNjNMMTU2IDE4NS43M2E4IDggMCAwIDAgNC02LjkyVjEyOGwxNiA5LjI0VjE4NGE0MCA0MCAwIDAgMS00MCA0MCIvPjwvZz48L3N2Zz4=',
  youtube: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNTYgMjU2Ij48ZyBmaWxsPSIjRkYwMDMzIiBjb2xvcj0iI0ZGMDAzMyI+PHBhdGggZmlsbD0iI0ZGMDAzMyIgZD0iTTIzNC4zMyA2OS41MmEyNCAyNCAwIDAgMC0xNC40OS0xNi40QzE4NS41NiAzOS44OCAxMzEgNDAgMTI4IDQwcy01Ny41Ni0uMTItOTEuODQgMTMuMTJhMjQgMjQgMCAwIDAtMTQuNDkgMTYuNEMxOS4wOCA3OS41IDE2IDk3Ljc0IDE2IDEyOHMzLjA4IDQ4LjUgNS42NyA1OC40OGEyNCAyNCAwIDAgMCAxNC40OSAxNi40MUM2OSAyMTUuNTYgMTIwLjQgMjE2IDEyNy4zNCAyMTZoMS4zMmM2Ljk0IDAgNTguMzctLjQ0IDkxLjE4LTEzLjExYTI0IDI0IDAgMCAwIDE0LjQ5LTE2LjQxYzIuNTktMTAgNS42Ny0yOC4yMiA1LjY3LTU4LjQ4cy0zLjA4LTQ4LjUtNS42Ny01OC40OG0tNzMuNzQgNjVsLTQwIDI4QTggOCAwIDAgMSAxMDggMTU2di01NmE4IDggMCAwIDEgMTIuNTktNi41NWw0MCAyOGE4IDggMCAwIDEgMCAxMy4xWiIvPjwvZz48L3N2Zz4=',
  google: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNTYgMjU2Ij48ZyBmaWxsPSIjNDI4NUY0IiBjb2xvcj0iIzQyODVGNCI+PHBhdGggZmlsbD0iIzQyODVGNCIgZD0iTTEyOCAyNGExMDQgMTA0IDAgMSAwIDEwNCAxMDRBMTA0IDEwNCAwIDAgMCAxMjggMjRtMCAxODRhODAgODAgMCAxIDEgNTMuMzQtMTM5LjYzYTggOCAwIDAgMS0xMC42NyAxMS45MkE2NCA2NCAwIDEgMCAxOTEuNSAxMzZIMTI4YTggOCAwIDAgMSAwLTE2aDcyYTggOCAwIDAgMSA4IDhhODAuMDkgODAuMDkgMCAwIDEtODAgODAiLz48L2c+PC9zdmc+',
  github: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNTYgMjU2Ij48ZyBmaWxsPSIjOUE5QUEyIiBjb2xvcj0iIzlBOUFBMiI+PHBhdGggZmlsbD0iIzlBOUFBMiIgZD0iTTIxNiAxMDR2OGE1Ni4wNiA1Ni4wNiAwIDAgMS00OC40NCA1NS40N0EzOS44IDM5LjggMCAwIDEgMTc2IDE5MnY0MGE4IDggMCAwIDEtOCA4aC02NGE4IDggMCAwIDEtOC04di0xNkg3MmE0MCA0MCAwIDAgMS00MC00MGEyNCAyNCAwIDAgMC0yNC0yNGE4IDggMCAwIDEgMC0xNmE0MCA0MCAwIDAgMSA0MCA0MGEyNCAyNCAwIDAgMCAyNCAyNGgyNHYtOGEzOS44IDM5LjggMCAwIDEgOC40NC0yNC41M0E1Ni4wNiA1Ni4wNiAwIDAgMSA1NiAxMTJ2LThhNTguMTQgNTguMTQgMCAwIDEgNy42OS0yOC4zMkE1OS43OCA1OS43OCAwIDAgMSA2OS4wNyAyOEE4IDggMCAwIDEgNzYgMjRhNTkuNzUgNTkuNzUgMCAwIDEgNDggMjRoMjRhNTkuNzUgNTkuNzUgMCAwIDEgNDgtMjRhOCA4IDAgMCAxIDYuOTMgNGE1OS43NCA1OS43NCAwIDAgMSA1LjM3IDQ3LjY4QTU4IDU4IDAgMCAxIDIxNiAxMDQiLz48L2c+PC9zdmc+',
  telegram: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNTYgMjU2Ij48ZyBmaWxsPSIjMjZBNUU0IiBjb2xvcj0iIzI2QTVFNCI+PHBhdGggZmlsbD0iIzI2QTVFNCIgZD0iTTIyOC44OCAyNi4xOWE5IDkgMCAwIDAtOS4xNi0xLjU3TDE3LjA2IDEwMy45M2ExNC4yMiAxNC4yMiAwIDAgMCAyLjQzIDI3LjIxTDcyIDE0MS40NVYyMDBhMTUuOTIgMTUuOTIgMCAwIDAgMTAgMTQuODNhMTUuOTEgMTUuOTEgMCAwIDAgMTcuNTEtMy43M2wyNS4zMi0yNi4yNkwxNjUgMjIwYTE1Ljg4IDE1Ljg4IDAgMCAwIDEwLjUxIDRhMTYuMyAxNi4zIDAgMCAwIDUtLjc5YTE1Ljg1IDE1Ljg1IDAgMCAwIDEwLjY3LTExLjYzTDIzMS43NyAzNWE5IDkgMCAwIDAtMi44OS04LjgxTTE3NS41MyAyMDhsLTgyLjY4LTcyLjVsMTE5LTg1LjI5WiIvPjwvZz48L3N2Zz4=',
  netflix: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9Ii0xIC0xIDI2IDI2Ij48cGF0aCBmaWxsPSIjRTUwOTE0IiBkPSJtNS4zOTggMCA4LjM0OCAyMy42MDJjMi4zNDYuMDU5IDQuODU2LjM5OCA0Ljg1Ni4zOThMMTAuMTEzIDBINS4zOTh6bTguNDg5IDB2OS4xNzJsNC43MTUgMTMuMzNWMGgtNC43MTV6TTUuMzk4IDEuNVYyNGMxLjg3My0uMjI1IDIuODEtLjMxMiA0LjcxNS0uMzk4VjE0LjgzTDUuMzk4IDEuNXoiLz48L3N2Zz4=',
  disney: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNTYgMjU2Ij48ZyBmaWxsPSIjMkY2QkZGIiBjb2xvcj0iIzJGNkJGRiI+PHBhdGggZmlsbD0iIzJGNkJGRiIgZD0iTTIxNiAxMDRIMTAyLjA5TDIxMCA3NS41MWE4IDggMCAwIDAgNS42OC05Ljg0bC04LjE2LTMwYTE1LjkzIDE1LjkzIDAgMCAwLTE5LjQyLTExLjEzTDM1LjgxIDY0Ljc0YTE1Ljc1IDE1Ljc1IDAgMCAwLTkuNyA3LjRhMTUuNSAxNS41IDAgMCAwLTEuNTUgMTJMMzIgMTExLjU2VjIwMGExNiAxNiAwIDAgMCAxNiAxNmgxNjBhMTYgMTYgMCAwIDAgMTYtMTZ2LTg4YTggOCAwIDAgMC04LThtLTIzLjg0LTY0bDYgMjIuMDdMMTY0LjU3IDcxbC0yOC4xMy0xNi4yOFpNNzcuNTUgNzAuMjdsMjguMTIgMTYuMjRsLTU5LjYgMTUuNzNsLTYtMjIuMDhaIi8+PC9nPjwvc3ZnPg==',
  spotify: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNTYgMjU2Ij48ZyBmaWxsPSIjMUVENzYwIiBjb2xvcj0iIzFFRDc2MCI+PHBhdGggZmlsbD0iIzFFRDc2MCIgZD0iTTEyOCAyNGExMDQgMTA0IDAgMSAwIDEwNCAxMDRBMTA0LjExIDEwNC4xMSAwIDAgMCAxMjggMjRtMzEuMDcgMTQ1Ljc0YTggOCAwIDAgMS0xMC44MSAzLjMzYTQyLjc5IDQyLjc5IDAgMCAwLTQwLjUyIDBhOCA4IDAgMCAxLTcuNDgtMTQuMTRhNTkuMzMgNTkuMzMgMCAwIDEgNTUuNDggMGE4IDggMCAwIDEgMy4zMyAxMC44MW0xNi0yOGE4IDggMCAwIDEtMTAuODIgMy4zYTc3LjA3IDc3LjA3IDAgMCAwLTcyLjQ4IDBhOCA4IDAgMCAxLTcuNTItMTQuMTJhOTMgOTMgMCAwIDEgODcuNTIgMGE4IDggMCAwIDEgMy4yOSAxMC44NFptMTYtMjhhOCA4IDAgMCAxLTEwLjgzIDMuMjlhMTEwLjYyIDExMC42MiAwIDAgMC0xMDQuNDYgMGE4IDggMCAwIDEtNy41NC0xNC4xMmExMjYuNjcgMTI2LjY3IDAgMCAxIDExOS41NCAwYTggOCAwIDAgMSAzLjI4IDEwLjg1WiIvPjwvZz48L3N2Zz4=',
  tiktok: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNTYgMjU2Ij48ZyBmaWxsPSIjRkUyQzU1IiBjb2xvcj0iI0ZFMkM1NSI+PHBhdGggZmlsbD0iI0ZFMkM1NSIgZD0iTTIzMiA4MHY0MGE4IDggMCAwIDEtOCA4YTEwMy4yNSAxMDMuMjUgMCAwIDEtNDgtMTEuNzFWMTU2YTc2IDc2IDAgMCAxLTE1MiAwYzAtMzYuOSAyNi45MS02OS41MiA2Mi42LTc1Ljg4QTggOCAwIDAgMSA5NiA4OHY0Mi42OWE4IDggMCAwIDEtNC41NyA3LjIzQTIwIDIwIDAgMSAwIDEyMCAxNTZWMjRhOCA4IDAgMCAxIDgtOGg0MGE4IDggMCAwIDEgOCA4YTQ4LjA1IDQ4LjA1IDAgMCAwIDQ4IDQ4YTggOCAwIDAgMSA4IDgiLz48L2c+PC9zdmc+',
  microsoft: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNTYgMjU2Ij48ZyBmaWxsPSIjMDBBNEVGIiBjb2xvcj0iIzAwQTRFRiI+PHBhdGggZmlsbD0iIzAwQTRFRiIgZD0iTTEwNCAxNDR2NTEuNjRhOCA4IDAgMCAxLTggOGE4LjUgOC41IDAgMCAxLTEuNDMtLjEzbC02NC0xMS42NEE4IDggMCAwIDEgMjQgMTg0di00MGE4IDggMCAwIDEgOC04aDY0YTggOCAwIDAgMSA4IDhtLTIuODctODkuNzhhOCA4IDAgMCAwLTYuNTYtMS43M2wtNjQgMTEuNjRBOCA4IDAgMCAwIDI0IDcydjQwYTggOCAwIDAgMCA4IDhoNjRhOCA4IDAgMCAwIDgtOFY2MC4zNmE4IDggMCAwIDAtMi44Ny02LjE0TTIwOCAxMzZoLTgwYTggOCAwIDAgMC04IDh2NTcuNDVhOCA4IDAgMCAwIDYuNTcgNy44OGw4MCAxNC41NGE3LjYgNy42IDAgMCAwIDEuNDMuMTNhOCA4IDAgMCAwIDgtOHYtNzJhOCA4IDAgMCAwLTgtOG01LjEzLTEwMi4xNGE4IDggMCAwIDAtNi41Ni0xLjczbC04MCAxNC41NWE4IDggMCAwIDAtNi41NyA3Ljg3VjExMmE4IDggMCAwIDAgOCA4aDgwYTggOCAwIDAgMCA4LThWNDBhOCA4IDAgMCAwLTIuODctNi4xNCIvPjwvZz48L3N2Zz4=',
  apple: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNTYgMjU2Ij48ZyBmaWxsPSIjOUE5QUEyIiBjb2xvcj0iIzlBOUFBMiI+PHBhdGggZmlsbD0iIzlBOUFBMiIgZD0iTTEyOC4yMyAzMEE0MCA0MCAwIDAgMSAxNjcgMGgxYTggOCAwIDAgMSAwIDE2aC0xYTI0IDI0IDAgMCAwLTIzLjI0IDE4YTggOCAwIDEgMS0xNS41LTRabTk1LjA3IDEzOS41OWE4LjA3IDguMDcgMCAwIDAtMi44LTMuNEMyMDMuNTMgMTU0LjUzIDIwMCAxMzQuNjQgMjAwIDEyMGMwLTE3LjY3IDEzLjQ3LTMzLjA2IDIxLjUtNDAuNjdhOCA4IDAgMCAwIDAtMTEuNjJDMjA4LjgyIDU1Ljc0IDE4Ny44MiA0OCAxNjggNDhhNzIuMjMgNzIuMjMgMCAwIDAtNDAgMTIuMTNhNzEuNTYgNzEuNTYgMCAwIDAtOTAuNzEgOS4wOUE3NC42MyA3NC42MyAwIDAgMCAxNiAxMjMuNGExMjcgMTI3IDAgMCAwIDQwLjE0IDg5LjczQTM5LjggMzkuOCAwIDAgMCA4My41OSAyMjRoODcuNjhhMzkuODQgMzkuODQgMCAwIDAgMjkuMTItMTIuNTdhMTI1IDEyNSAwIDAgMCAxNy44Mi0yNC42YzcuMDItMTIuODMgNi4xMi0xNC44MyA1LjA5LTE3LjI0Ii8+PC9nPjwvc3ZnPg==',
  direct: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNTYgMjU2Ij48ZyBmaWxsPSIjRTU0ODREIiBjb2xvcj0iI0U1NDg0RCI+PHBhdGggZmlsbD0iI0U1NDg0RCIgZD0iTTIyNCAxMjB2OTZhOCA4IDAgMCAxLTggOGgtNTZhOCA4IDAgMCAxLTgtOHYtNTJhNCA0IDAgMCAwLTQtNGgtNDBhNCA0IDAgMCAwLTQgNHY1MmE4IDggMCAwIDEtOCA4SDQwYTggOCAwIDAgMS04LTh2LTk2YTE2IDE2IDAgMCAxIDQuNjktMTEuMzFsODAtODBhMTYgMTYgMCAwIDEgMjIuNjIgMGw4MCA4MEExNiAxNiAwIDAgMSAyMjQgMTIwIi8+PC9nPjwvc3ZnPg==',
  final: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNTYgMjU2Ij48ZyBmaWxsPSIjMjJCOENGIiBjb2xvcj0iIzIyQjhDRiI+PHBhdGggZmlsbD0iIzIyQjhDRiIgZD0iTTE2OCA3NmExMiAxMiAwIDEgMS0xMi0xMmExMiAxMiAwIDAgMSAxMiAxMm00OC43MiA2Ny42NGMtMTkuMzcgMzQuOS01NS40NCA1My43Ni0xMDcuMjQgNTYuMWwtMjIgNTEuNDFBOCA4IDAgMCAxIDgwLjEgMjU2aC0uNTFhOCA4IDAgMCAxLTcuMTktNS43OGwtMTQuOC01MS44M2wtNTEuOC0xNC44M2E4IDggMCAwIDEtMS0xNS4wNWw1MS40MS0yMmMyLjM1LTUxLjc4IDIxLjIxLTg3Ljg0IDU2LjA5LTEwNy4yMmMyNC43NS0xMy43NCA1Mi43NC0xNS44NCA3MS44OC0xNS4xOGMxOC42NC42NCAzNiA0LjI3IDM4Ljg2IDZhOCA4IDAgMCAxIDIuODMgMi44M2MxLjY5IDIuODUgNS4zMyAyMC4yMSA2IDM4Ljg1Yy42OCAxOS4xLTEuNDEgNDcuMS0xNS4xNSA3MS44NW0tNC4zLTEwMC4wN2MtMTQuMTUtMy02NC4xLTExLTEwMC4zIDE0Ljc1YTgxLjIgODEuMiAwIDAgMC0xNiAxNS4wN2EzNiAzNiAwIDAgMCAzOS4zNSAzOC40NGE4IDggMCAwIDEgOC43MyA4LjczYTM2IDM2IDAgMCAwIDM4LjQ3IDM5LjM0YTgwLjggODAuOCAwIDAgMCAxNS0xNmMyNS43NS0zNi4xNyAxNy43NS04Ni4xNiAxNC43NS0xMDAuMzMiLz48L2c+PC9zdmc+',
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
