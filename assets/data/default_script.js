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
  proxy: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJnIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjOEI1Q0Y2Ii8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjNEY0NkU1Ii8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiByeD0iMTgiIGZpbGw9InVybCgjZykiLz48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxNCAxNCkgc2NhbGUoMS41KSIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjZmZmIiBzdHJva2Utd2lkdGg9IjEuOSIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIj48cGF0aCBkPSJNMTIgMTV2NXMzLjAzLS41NSA0LTJjMS4wOC0xLjYyIDAtNSAwLTUiIC8+IDxwYXRoIGQ9Ik00LjUgMTYuNWMtMS41IDEuMjYtMiA1LTIgNXMzLjc0LS41IDUtMmMuNzEtLjg0LjctMi4xMy0uMDktMi45MWEyLjE4IDIuMTggMCAwIDAtMi45MS0uMDkiIC8+IDxwYXRoIGQ9Ik05IDEyYTIyIDIyIDAgMCAxIDItMy45NUExMi44OCAxMi44OCAwIDAgMSAyMiAyYzAgMi43Mi0uNzggNy41LTYgMTFhMjIuNCAyMi40IDAgMCAxLTQgMnoiIC8+IDxwYXRoIGQ9Ik05IDEySDRzLjU1LTMuMDMgMi00YzEuNjItMS4wOCA1IC4wNSA1IC4wNSIgLz48L2c+PC9zdmc+',
  auto: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJnIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjRkJCRjI0Ii8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjRUE1ODBDIi8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiByeD0iMTgiIGZpbGw9InVybCgjZykiLz48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxNCAxNCkgc2NhbGUoMS41KSIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjZmZmIiBzdHJva2Utd2lkdGg9IjEuOSIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIj48cGF0aCBkPSJNMTUuOTE0IDRhMS41IDEuNSAwIDAwLTIuNDc0LTEuNTYxbC05IDlBMS41IDEuNSAwIDAwNS41IDE0aDQuMDAyYS41LjUgMCAwMS40NzEuNjY2TDguMDg2IDIwYTEuNSAxLjUgMCAwMDIuNDc1IDEuNTZsOS05QTEuNSAxLjUgMCAwMDE4LjUgMTBoLTMuOTk3YS41LjUgMCAwMS0uNDcyLS42Njd6IiAvPjwvZz48L3N2Zz4=',
  chainEntry: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJnIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjMzhCREY4Ii8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMjU2M0VCIi8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiByeD0iMTgiIGZpbGw9InVybCgjZykiLz48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxNCAxNCkgc2NhbGUoMS41KSIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjZmZmIiBzdHJva2Utd2lkdGg9IjEuOSIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIj48cGF0aCBkPSJNMiAyMmgyMCIgLz4gPHBhdGggZD0iTTYuMzYgMTcuNCA0IDE3bC0yLTQgMS4xLS41NWEyIDIgMCAwIDEgMS44IDBsLjE3LjFhMiAyIDAgMCAwIDEuOCAwTDggMTIgNSA2bC45LS40NWEyIDIgMCAwIDEgMi4wOS4ybDQuMDIgM2EyIDIgMCAwIDAgMi4xLjJsNC4xOS0yLjA2YTIuNDEgMi40MSAwIDAgMSAxLjczLS4xN0wyMSA3YTEuNCAxLjQgMCAwIDEgLjg3IDEuOTlsLS4zOC43NmMtLjIzLjQ2LS42Ljg0LTEuMDcgMS4wOEw3LjU4IDE3LjJhMiAyIDAgMCAxLTEuMjIuMThaIiAvPjwvZz48L3N2Zz4=',
  chainExit: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJnIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjMkRENEJGIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMEY3NjZFIi8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiByeD0iMTgiIGZpbGw9InVybCgjZykiLz48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxNCAxNCkgc2NhbGUoMS41KSIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjZmZmIiBzdHJva2Utd2lkdGg9IjEuOSIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIj48cGF0aCBkPSJNMiAyMmgyMCIgLz4gPHBhdGggZD0iTTMuNzcgMTAuNzcgMiA5bDItNC41IDEuMS41NWMuNTUuMjguOS44NC45IDEuNDVzLjM1IDEuMTcuOSAxLjQ1TDggOC41bDMtNiAxLjA1LjUzYTIgMiAwIDAgMSAxLjA5IDEuNTJsLjcyIDUuNGEyIDIgMCAwIDAgMS4wOSAxLjUybDQuNCAyLjJjLjQyLjIyLjc4LjU1IDEuMDEuOTZsLjYgMS4wM2MuNDkuODgtLjA2IDEuOTgtMS4wNiAyLjFsLTEuMTguMTVjLS40Ny4wNi0uOTUtLjAyLTEuMzctLjI0TDQuMjkgMTEuMTVhMiAyIDAgMCAxLS41Mi0uMzhaIiAvPjwvZz48L3N2Zz4=',
  ai: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJnIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjQTg1NUY3Ii8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjRUM0ODk5Ii8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiByeD0iMTgiIGZpbGw9InVybCgjZykiLz48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxNCAxNCkgc2NhbGUoMS41KSIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjZmZmIiBzdHJva2Utd2lkdGg9IjEuOSIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIj48cGF0aCBkPSJNMTEuMDE3IDIuODE0YTEgMSAwIDAgMSAxLjk2NiAwbDEuMDUxIDUuNTU4YTIgMiAwIDAgMCAxLjU5NCAxLjU5NGw1LjU1OCAxLjA1MWExIDEgMCAwIDEgMCAxLjk2NmwtNS41NTggMS4wNTFhMiAyIDAgMCAwLTEuNTk0IDEuNTk0bC0xLjA1MSA1LjU1OGExIDEgMCAwIDEtMS45NjYgMGwtMS4wNTEtNS41NThhMiAyIDAgMCAwLTEuNTk0LTEuNTk0bC01LjU1OC0xLjA1MWExIDEgMCAwIDEgMC0xLjk2Nmw1LjU1OC0xLjA1MWEyIDIgMCAwIDAgMS41OTQtMS41OTR6IiAvPiA8cGF0aCBkPSJNMjAgMnY0IiAvPiA8cGF0aCBkPSJNMjIgNGgtNCIgLz4gPGNpcmNsZSBjeD0iNCIgY3k9IjIwIiByPSIyIiAvPjwvZz48L3N2Zz4=',
  youtube: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJnIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjRkYzQjMwIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjQzQwMDBGIi8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiByeD0iMTgiIGZpbGw9InVybCgjZykiLz48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxNSAxNSkgc2NhbGUoMS40MTY3KSIgZmlsbD0iI2ZmZiI+PHBhdGggZD0iTTIzLjQ5OCA2LjE4NmEzLjAxNiAzLjAxNiAwIDAgMC0yLjEyMi0yLjEzNkMxOS41MDUgMy41NDUgMTIgMy41NDUgMTIgMy41NDVzLTcuNTA1IDAtOS4zNzcuNTA1QTMuMDE3IDMuMDE3IDAgMCAwIC41MDIgNi4xODZDMCA4LjA3IDAgMTIgMCAxMnMwIDMuOTMuNTAyIDUuODE0YTMuMDE2IDMuMDE2IDAgMCAwIDIuMTIyIDIuMTM2YzEuODcxLjUwNSA5LjM3Ni41MDUgOS4zNzYuNTA1czcuNTA1IDAgOS4zNzctLjUwNWEzLjAxNSAzLjAxNSAwIDAgMCAyLjEyMi0yLjEzNkMyNCAxNS45MyAyNCAxMiAyNCAxMnMwLTMuOTMtLjUwMi01LjgxNHpNOS41NDUgMTUuNTY4VjguNDMyTDE1LjgxOCAxMmwtNi4yNzMgMy41Njh6Ii8+PC9nPjwvc3ZnPg==',
  google: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJnIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjNEY4RUY3Ii8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMUE1RkQwIi8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiByeD0iMTgiIGZpbGw9InVybCgjZykiLz48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxNSAxNSkgc2NhbGUoMS40MTY3KSIgZmlsbD0iI2ZmZiI+PHBhdGggZD0iTTEyLjQ4IDEwLjkydjMuMjhoNy44NGMtLjI0IDEuODQtLjg1MyAzLjE4Ny0xLjc4NyA0LjEzMy0xLjE0NyAxLjE0Ny0yLjkzMyAyLjQtNi4wNTMgMi40LTQuODI3IDAtOC42LTMuODkzLTguNi04LjcyczMuNzczLTguNzIgOC42LTguNzJjMi42IDAgNC41MDcgMS4wMjcgNS45MDcgMi4zNDdsMi4zMDctMi4zMDdDMTguNzQ3IDEuNDQgMTYuMTMzIDAgMTIuNDggMCA1Ljg2NyAwIC4zMDcgNS4zODcuMzA3IDEyczUuNTYgMTIgMTIuMTczIDEyYzMuNTczIDAgNi4yNjctMS4xNzMgOC4zNzMtMy4zNiAyLjE2LTIuMTYgMi44NC01LjIxMyAyLjg0LTcuNjY3IDAtLjc2LS4wNTMtMS40NjctLjE3My0yLjA1M0gxMi40OHoiLz48L2c+PC9zdmc+',
  github: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJnIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjM0I0MjUwIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMEQxMTE3Ii8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiByeD0iMTgiIGZpbGw9InVybCgjZykiLz48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxNSAxNSkgc2NhbGUoMS40MTY3KSIgZmlsbD0iI2ZmZiI+PHBhdGggZD0iTTEyIC4yOTdjLTYuNjMgMC0xMiA1LjM3My0xMiAxMiAwIDUuMzAzIDMuNDM4IDkuOCA4LjIwNSAxMS4zODUuNi4xMTMuODItLjI1OC44Mi0uNTc3IDAtLjI4NS0uMDEtMS4wNC0uMDE1LTIuMDQtMy4zMzguNzI0LTQuMDQyLTEuNjEtNC4wNDItMS42MUM0LjQyMiAxOC4wNyAzLjYzMyAxNy43IDMuNjMzIDE3LjdjLTEuMDg3LS43NDQuMDg0LS43MjkuMDg0LS43MjkgMS4yMDUuMDg0IDEuODM4IDEuMjM2IDEuODM4IDEuMjM2IDEuMDcgMS44MzUgMi44MDkgMS4zMDUgMy40OTUuOTk4LjEwOC0uNzc2LjQxNy0xLjMwNS43Ni0xLjYwNS0yLjY2NS0uMy01LjQ2Ni0xLjMzMi01LjQ2Ni01LjkzIDAtMS4zMS40NjUtMi4zOCAxLjIzNS0zLjIyLS4xMzUtLjMwMy0uNTQtMS41MjMuMTA1LTMuMTc2IDAgMCAxLjAwNS0uMzIyIDMuMyAxLjIzLjk2LS4yNjcgMS45OC0uMzk5IDMtLjQwNSAxLjAyLjAwNiAyLjA0LjEzOCAzIC40MDUgMi4yOC0xLjU1MiAzLjI4NS0xLjIzIDMuMjg1LTEuMjMuNjQ1IDEuNjUzLjI0IDIuODczLjEyIDMuMTc2Ljc2NS44NCAxLjIzIDEuOTEgMS4yMyAzLjIyIDAgNC42MS0yLjgwNSA1LjYyNS01LjQ3NSA1LjkyLjQyLjM2LjgxIDEuMDk2LjgxIDIuMjIgMCAxLjYwNi0uMDE1IDIuODk2LS4wMTUgMy4yODYgMCAuMzE1LjIxLjY5LjgyNS41N0MyMC41NjUgMjIuMDkyIDI0IDE3LjU5MiAyNCAxMi4yOTdjMC02LjYyNy01LjM3My0xMi0xMi0xMiIvPjwvZz48L3N2Zz4=',
  telegram: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJnIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjMzdCQkZFIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMUM5M0QxIi8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiByeD0iMTgiIGZpbGw9InVybCgjZykiLz48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxNSAxNSkgc2NhbGUoMS40MTY3KSIgZmlsbD0iI2ZmZiI+PHBhdGggZD0iTTExLjk0NCAwQTEyIDEyIDAgMCAwIDAgMTJhMTIgMTIgMCAwIDAgMTIgMTIgMTIgMTIgMCAwIDAgMTItMTJBMTIgMTIgMCAwIDAgMTIgMGExMiAxMiAwIDAgMC0uMDU2IDB6bTQuOTYyIDcuMjI0Yy4xLS4wMDIuMzIxLjAyMy40NjUuMTRhLjUwNi41MDYgMCAwIDEgLjE3MS4zMjVjLjAxNi4wOTMuMDM2LjMwNi4wMi40NzItLjE4IDEuODk4LS45NjIgNi41MDItMS4zNiA4LjYyNy0uMTY4LjktLjQ5OSAxLjIwMS0uODIgMS4yMy0uNjk2LjA2NS0xLjIyNS0uNDYtMS45LS45MDItMS4wNTYtLjY5My0xLjY1My0xLjEyNC0yLjY3OC0xLjgtMS4xODUtLjc4LS40MTctMS4yMS4yNTgtMS45MS4xNzctLjE4NCAzLjI0Ny0yLjk3NyAzLjMwNy0zLjIzLjAwNy0uMDMyLjAxNC0uMTUtLjA1Ni0uMjEycy0uMTc0LS4wNDEtLjI0OS0uMDI0Yy0uMTA2LjAyNC0xLjc5MyAxLjE0LTUuMDYxIDMuMzQ1LS40OC4zMy0uOTEzLjQ5LTEuMzAyLjQ4LS40MjgtLjAwOC0xLjI1Mi0uMjQxLTEuODY1LS40NC0uNzUyLS4yNDUtMS4zNDktLjM3NC0xLjI5Ny0uNzg5LjAyNy0uMjE2LjMyNS0uNDM3Ljg5My0uNjYzIDMuNDk4LTEuNTI0IDUuODMtMi41MjkgNi45OTgtMy4wMTQgMy4zMzItMS4zODYgNC4wMjUtMS42MjcgNC40NzYtMS42MzV6Ii8+PC9nPjwvc3ZnPg==',
  netflix: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJnIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjRjAyNDJFIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjOEUwNjBEIi8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiByeD0iMTgiIGZpbGw9InVybCgjZykiLz48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxNSAxNSkgc2NhbGUoMS40MTY3KSIgZmlsbD0iI2ZmZiI+PHBhdGggZD0ibTUuMzk4IDAgOC4zNDggMjMuNjAyYzIuMzQ2LjA1OSA0Ljg1Ni4zOTggNC44NTYuMzk4TDEwLjExMyAwSDUuMzk4em04LjQ4OSAwdjkuMTcybDQuNzE1IDEzLjMzVjBoLTQuNzE1ek01LjM5OCAxLjVWMjRjMS44NzMtLjIyNSAyLjgxLS4zMTIgNC43MTUtLjM5OFYxNC44M0w1LjM5OCAxLjV6Ii8+PC9nPjwvc3ZnPg==',
  disney: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJnIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjMjU2M0VCIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMEIxRjdBIi8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiByeD0iMTgiIGZpbGw9InVybCgjZykiLz48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxNCAxNCkgc2NhbGUoMS41KSIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjZmZmIiBzdHJva2Utd2lkdGg9IjEuOSIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIj48cGF0aCBkPSJtMTIuMjk2IDMuNDY0IDMuMDIgMy45NTYiIC8+IDxwYXRoIGQ9Ik0yMC4yIDYgMyAxMWwtLjktMi40Yy0uMy0xLjEuMy0yLjIgMS4zLTIuNWwxMy41LTRjMS4xLS4zIDIuMi4zIDIuNSAxLjN6IiAvPiA8cGF0aCBkPSJNMyAxMWgxOHY4YTIgMiAwIDAgMS0yIDJINWEyIDIgMCAwIDEtMi0yeiIgLz4gPHBhdGggZD0ibTYuMTggNS4yNzYgMy4xIDMuODk5IiAvPjwvZz48L3N2Zz4=',
  spotify: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJnIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjMkVFMDZEIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMTY5QzQ2Ii8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiByeD0iMTgiIGZpbGw9InVybCgjZykiLz48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxNSAxNSkgc2NhbGUoMS40MTY3KSIgZmlsbD0iI2ZmZiI+PHBhdGggZD0iTTEyIDBDNS40IDAgMCA1LjQgMCAxMnM1LjQgMTIgMTIgMTIgMTItNS40IDEyLTEyUzE4LjY2IDAgMTIgMHptNS41MjEgMTcuMzRjLS4yNC4zNTktLjY2LjQ4LTEuMDIxLjI0LTIuODItMS43NC02LjM2LTIuMTAxLTEwLjU2MS0xLjE0MS0uNDE4LjEyMi0uNzc5LS4xNzktLjg5OS0uNTM5LS4xMi0uNDIxLjE4LS43OC41NC0uOSA0LjU2LTEuMDIxIDguNTItLjYgMTEuNjQgMS4zMi40Mi4xOC40NzkuNjU5LjMwMSAxLjAyem0xLjQ0LTMuM2MtLjMwMS40Mi0uODQxLjYtMS4yNjIuMy0zLjIzOS0xLjk4LTguMTU5LTIuNTgtMTEuOTM5LTEuMzgtLjQ3OS4xMi0xLjAyLS4xMi0xLjE0LS42LS4xMi0uNDguMTItMS4wMjEuNi0xLjE0MUM5LjYgOS45IDE1IDEwLjU2MSAxOC43MiAxMi44NGMuMzYxLjE4MS41NC43OC4yNDEgMS4yem0uMTItMy4zNkMxNS4yNCA4LjQgOC44MiA4LjE2IDUuMTYgOS4zMDFjLS42LjE3OS0xLjItLjE4MS0xLjM4LS43MjEtLjE4LS42MDEuMTgtMS4yLjcyLTEuMzgxIDQuMjYtMS4yNiAxMS4yOC0xLjAyIDE1LjcyMSAxLjYyMS41MzkuMy43MTkgMS4wMi40MTkgMS41Ni0uMjk5LjQyMS0xLjAyLjU5OS0xLjU1OS4zeiIvPjwvZz48L3N2Zz4=',
  tiktok: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJnIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjMkEyQTJFIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMDAwMDAwIi8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiByeD0iMTgiIGZpbGw9InVybCgjZykiLz48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxNSAxNSkgc2NhbGUoMS40MTY3KSIgZmlsbD0iI2ZmZiI+PHBhdGggZD0iTTEyLjUyNS4wMmMxLjMxLS4wMiAyLjYxLS4wMSAzLjkxLS4wMi4wOCAxLjUzLjYzIDMuMDkgMS43NSA0LjE3IDEuMTIgMS4xMSAyLjcgMS42MiA0LjI0IDEuNzl2NC4wM2MtMS40NC0uMDUtMi44OS0uMzUtNC4yLS45Ny0uNTctLjI2LTEuMS0uNTktMS42Mi0uOTMtLjAxIDIuOTIuMDEgNS44NC0uMDIgOC43NS0uMDggMS40LS41NCAyLjc5LTEuMzUgMy45NC0xLjMxIDEuOTItMy41OCAzLjE3LTUuOTEgMy4yMS0xLjQzLjA4LTIuODYtLjMxLTQuMDgtMS4wMy0yLjAyLTEuMTktMy40NC0zLjM3LTMuNjUtNS43MS0uMDItLjUtLjAzLTEtLjAxLTEuNDkuMTgtMS45IDEuMTItMy43MiAyLjU4LTQuOTYgMS42Ni0xLjQ0IDMuOTgtMi4xMyA2LjE1LTEuNzIuMDIgMS40OC0uMDQgMi45Ni0uMDQgNC40NC0uOTktLjMyLTIuMTUtLjIzLTMuMDIuMzctLjYzLjQxLTEuMTEgMS4wNC0xLjM2IDEuNzUtLjIxLjUxLS4xNSAxLjA3LS4xNCAxLjYxLjI0IDEuNjQgMS44MiAzLjAyIDMuNSAyLjg3IDEuMTItLjAxIDIuMTktLjY2IDIuNzctMS42MS4xOS0uMzMuNC0uNjcuNDEtMS4wNi4xLTEuNzkuMDYtMy41Ny4wNy01LjM2LjAxLTQuMDMtLjAxLTguMDUuMDItMTIuMDd6Ii8+PC9nPjwvc3ZnPg==',
  microsoft: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJnIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjMkI5QUYzIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMDA2M0IxIi8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiByeD0iMTgiIGZpbGw9InVybCgjZykiLz48ZyBmaWxsPSIjZmZmIj48cmVjdCB4PSIxNyIgeT0iMTciIHdpZHRoPSIxNCIgaGVpZ2h0PSIxNCIgcng9IjEuNSIvPjxyZWN0IHg9IjMzIiB5PSIxNyIgd2lkdGg9IjE0IiBoZWlnaHQ9IjE0IiByeD0iMS41Ii8+PHJlY3QgeD0iMTciIHk9IjMzIiB3aWR0aD0iMTQiIGhlaWdodD0iMTQiIHJ4PSIxLjUiLz48cmVjdCB4PSIzMyIgeT0iMzMiIHdpZHRoPSIxNCIgaGVpZ2h0PSIxNCIgcng9IjEuNSIvPjwvZz48L3N2Zz4=',
  apple: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJnIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjNUE1QTYwIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMUMxQzFFIi8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiByeD0iMTgiIGZpbGw9InVybCgjZykiLz48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxNSAxNSkgc2NhbGUoMS40MTY3KSIgZmlsbD0iI2ZmZiI+PHBhdGggZD0iTTEyLjE1MiA2Ljg5NmMtLjk0OCAwLTIuNDE1LTEuMDc4LTMuOTYtMS4wNC0yLjA0LjAyNy0zLjkxIDEuMTgzLTQuOTYxIDMuMDE0LTIuMTE3IDMuNjc1LS41NDYgOS4xMDMgMS41MTkgMTIuMDkgMS4wMTMgMS40NTQgMi4yMDggMy4wOSAzLjc5MiAzLjAzOSAxLjUyLS4wNjUgMi4wOS0uOTg3IDMuOTM1LS45ODcgMS44MzEgMCAyLjM1Ljk4NyAzLjk2Ljk0OCAxLjYzNy0uMDI2IDIuNjc2LTEuNDggMy42NzYtMi45NDggMS4xNTYtMS42ODggMS42MzYtMy4zMjUgMS42NjItMy40MTUtLjAzOS0uMDEzLTMuMTgyLTEuMjIxLTMuMjItNC44NTctLjAyNi0zLjA0IDIuNDgtNC40OTQgMi41OTctNC41NTktMS40MjktMi4wOS0zLjYyMy0yLjMyNC00LjM5LTIuMzc2LTItLjE1Ni0zLjY3NSAxLjA5LTQuNjEgMS4wOXpNMTUuNTMgMy44M2MuODQzLTEuMDEyIDEuNC0yLjQyNyAxLjI0NS0zLjgzLTEuMjA3LjA1Mi0yLjY2Mi44MDUtMy41MzIgMS44MTgtLjc4Ljg5Ni0xLjQ1NCAyLjMzOC0xLjI3MyAzLjcxNCAxLjMzOC4xMDQgMi43MTUtLjY4OCAzLjU1OS0xLjcwMSIvPjwvZz48L3N2Zz4=',
  direct: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJnIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjRkI3MTg1Ii8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjQkUxMjNDIi8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiByeD0iMTgiIGZpbGw9InVybCgjZykiLz48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxNCAxNCkgc2NhbGUoMS41KSIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjZmZmIiBzdHJva2Utd2lkdGg9IjEuOSIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIj48cGF0aCBkPSJNMTUgMjF2LThhMSAxIDAgMCAwLTEtMWgtNGExIDEgMCAwIDAtMSAxdjgiIC8+IDxwYXRoIGQ9Ik0zIDEwYTIgMiAwIDAgMSAuNzA5LTEuNTI4bDctNmEyIDIgMCAwIDEgMi41ODIgMGw3IDZBMiAyIDAgMCAxIDIxIDEwdjlhMiAyIDAgMCAxLTIgMkg1YTIgMiAwIDAgMS0yLTJ6IiAvPjwvZz48L3N2Zz4=',
  final: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJnIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjMjJEM0VFIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMEU3NDkwIi8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiByeD0iMTgiIGZpbGw9InVybCgjZykiLz48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxNCAxNCkgc2NhbGUoMS41KSIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjZmZmIiBzdHJva2Utd2lkdGg9IjEuOSIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIj48cGF0aCBkPSJNNi41IDEyYy45NC0zLjQ2IDQuOTQtNiA4LjUtNiAzLjU2IDAgNi4wNiAyLjU0IDcgNi0uOTQgMy40Ny0zLjQ0IDYtNyA2cy03LjU2LTIuNTMtOC41LTZaIiAvPiA8cGF0aCBkPSJNMTggMTJ2LjUiIC8+IDxwYXRoIGQ9Ik0xNiAxNy45M2E5Ljc3IDkuNzcgMCAwIDEgMC0xMS44NiIgLz4gPHBhdGggZD0iTTcgMTAuNjdDNyA4IDUuNTggNS45NyAyLjczIDUuNWMtMSAxLjUtMSA1IC4yMyA2LjUtMS4yNCAxLjUtMS4yNCA1LS4yMyA2LjVDNS41OCAxOC4wMyA3IDE2IDcgMTMuMzMiIC8+IDxwYXRoIGQ9Ik0xMC40NiA3LjI2QzEwLjIgNS44OCA5LjE3IDQuMjQgOCAzaDUuOGEyIDIgMCAwIDEgMS45OCAxLjY3bC4yMyAxLjQiIC8+IDxwYXRoIGQ9Im0xNi4wMSAxNy45My0uMjMgMS40QTIgMiAwIDAgMSAxMy44IDIxSDkuNWE1Ljk2IDUuOTYgMCAwIDAgMS40OS0zLjk4IiAvPjwvZz48L3N2Zz4=',
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
