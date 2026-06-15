## v1.0.7

- 修复：下载完成后自动触发安装（Android 使用系统包安装器，Windows/macOS/Linux 自动打开安装包）
- 优化：更新下载进度弹窗 UI（圆角卡片、系统更新图标、文件名显示、更粗的进度条）

## v1.0.6

- 安全：修复 SSL 证书验证绕过漏洞，现仅对 localhost 跳过证书检查
- DNS：启用 HTTP/3 (QUIC) 优先，加快 DNS 解析速度
- DNS：fallback DNS 由 DoT(853端口) 改为 DoH(HTTPS 443端口)，更稳定且难被封锁
- 性能：TCP keepAlive 间隔由 30s 降至 15s，不稳定网络下连接恢复更快

## v1.0.5

- 安全：新增 PIN 锁屏功能（启动时、从后台返回时验证，支持自动锁定超时）
- 安全：PIN 以 SHA-256 哈希存储，支持设置/修改 PIN（修改时需验证旧 PIN）
- 更新：应用内下载安装包，显示实时进度条，支持取消

## v1.0.4

- 修复 Android 无法覆盖安装旧版问题（applicationId 改为 com.psg.internal，独立于原版 FlClash）
- 修复 Android 签名一致性问题（提交固定 keystore，每次构建签名一致）

## v1.0.3

- 图标全面更新为 Bauhaus 黑底几何 P 设计，四端统一，圆角处理
- 免责声明改为 PSG 内部工具专属说明
- 关于页「检查更新」确认后自动下载对应平台安装包

## v1.0.1

- 修复 Android 自适应图标被裁切问题（元素缩放至安全区）
- 修复 macOS 应用名称构建失败（PRODUCT_NAME = PSG）
- 修复所有残余 FlClash 字符串引用

## v1.0.0

- PSG 初版发布，基于 FlClash 完整品牌重塑
- Bauhaus 德式极简设计风格（黑白红配色）
- 支持 Android / Windows / macOS / Linux 四平台
