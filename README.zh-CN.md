# Antigravity Account Switcher

简体中文 · [English](README.md)

在 Mac 菜单栏管理你的工作、个人等多个 Antigravity 账号。保存账号后，即可在账号之间切换，继续使用本机的工作环境。

## 能做什么

- **添加账号**：通过 Antigravity 登录，并保存账号以便日后使用。
- **切换账号**：从菜单栏选择已保存的账号，按向导完成切换。
- **删除账号**：从工具中移除已保存的账号，不会删除 Google 账号。
- **恢复登录**：添加或切换中断时，恢复之前使用的账号。
- **选择语言**：使用中文、英文，或跟随 Mac 系统语言。

工具切换保存的登录信息，同时保留本地工作区和设置。不同账号的云端数据与访问权限可能不同，Antigravity 登录时也可能自行更改信息。

## 获取应用

从 [Releases 页面](https://github.com/zfdang/antigravity-account-switcher/releases)下载最新的 `Antigravity-Account-Switcher-v<version>-arm64.zip`，解压后将应用移到“应用程序”目录。当前发布版本支持 Apple Silicon Mac。开发者可以参考[开发文档](docs/development.zh-CN.md)构建当前版本。

你需要 macOS 13 或更高版本、安装在“应用程序”目录中的 Antigravity，以及至少一个已经登录的 Antigravity 账号。应用尚未经过 Apple 公证，打开时 macOS 可能显示安全提示。

## 开始使用

1. 打开 **Antigravity Account Switcher**，图标会出现在菜单栏。
2. 选择**保存当前账号**，按提示保存工作并关闭 Antigravity。工具会保存当前登录，供以后切换使用。
3. 选择**添加账号**，按向导在 Antigravity 中登录另一个账号。登录后关闭 Antigravity，再在向导中选择**完成登录**。
4. 需要切换时，在菜单中选择目标账号并按向导操作。提示时保存工作，关闭 Antigravity 和 `agy` 命令行进程。切换后 Antigravity 会重新打开，请在其中确认当前账号。
5. 要移除已保存的账号，选择**删除账号**并确认。这只会删除工具保存的副本，不会删除 Google 账号，也不会退出 Antigravity 当前登录。

如果操作中断，请关闭 Antigravity，再在菜单中选择**恢复原账号**。如果 macOS 请求钥匙串访问权限，需要允许工具读取或保存登录；拒绝授权会停止操作。

## 语言与隐私

界面默认跟随 Mac 的首选语言：首选语言为中文时显示中文，否则显示英文。可以在菜单栏的**语言**菜单中手动切换，或选择**跟随系统**。

账号凭据保存在本机钥匙串中，应用不会上传凭据。登录由 Antigravity 完成；请勿分享凭据或钥匙串导出文件。

## 开发者

构建、测试和签名说明请参阅[开发文档](docs/development.zh-CN.md)。也可以查看[产品设计](docs/product-design.md)和[技术方案](docs/technical-design.md)。
