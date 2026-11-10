# Antigravity Account Switcher

简体中文 · [English](README.md)

一个 macOS 菜单栏应用，帮助你管理多个 Antigravity 账号：保存当前登录，通过 Antigravity 原生流程添加账号，在账号之间切换，以及删除已保存的账号，同时保留本地工作区和设置。

界面默认跟随系统语言：系统首选语言为中文时显示中文，否则显示英文。可以在菜单栏的**语言**菜单中选择简体中文、English 或**跟随系统**。

## 使用条件

- macOS 13 或更高版本，并将 Antigravity 安装在 `/Applications/Antigravity.app`。
- 至少一个已经登录的 Antigravity 账号。添加新账号前，工具会先保存当前登录。
- 允许工具访问钥匙串中的账号凭据和 Antigravity 当前登录。首次访问或签名身份改变后，macOS 可能要求授权。

Antigravity 的凭据格式是内部实现，可能随版本变化。工具修改登录凭据；不同账号的云端数据和 Antigravity 自身引起的变化可能不同。切换后请在 Antigravity 中确认当前账号。

## 开始使用

1. 按下方说明构建，打开 `dist/Antigravity Account Switcher.app`，图标将出现在菜单栏。
2. 选择**保存当前账号**，保存工作并关闭 Antigravity。向导会把当前登录保存到 macOS 钥匙串。
3. 选择**添加账号**并按向导操作。在 Antigravity 中登录新账号，登录完成后关闭 Antigravity，再在向导中选择**完成登录**。
4. 要切换账号，在菜单中选择目标账号并按向导操作。继续前请关闭 Antigravity 及 `agy` 命令行进程；切换后 Antigravity 会重新打开。
5. 使用**删除账号**移除工具保存的副本。这不会删除 Google 账号，也不会退出当前 IDE 登录。

如果操作中断，请关闭 Antigravity 并在菜单中选择**恢复原账号**。账号凭据保存在本机钥匙串中，应用不会上传凭据；请勿分享凭据或钥匙串导出文件。

## 构建与测试

安装 Xcode 后运行：

```sh
./build.sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

签名后的应用位于 `dist/`。签名构建需要与[固定证书](scripts/signing/release-certificate.pem)对应的私钥。没有该私钥时，可运行 `UNSIGNED_BUILD=1 ./build.sh` 进行本机临时签名构建；改变签名身份可能导致钥匙串再次要求授权。应用尚未经过 Apple 公证。

## CI 与签名

CI 在 PR 和推送时运行测试并构建临时签名包。独立的签名构建工作流在推送到 `main` 或手动触发时构建 zip 并上传为构建产物，不会自动发布 Release。签名工作流需要仓库 Secrets `MACOS_SIGNING_P12_BASE64` 和 `MACOS_SIGNING_P12_PASSWORD`，其受密码保护的签名身份必须与仓库固定的公钥证书匹配；不匹配时构建失败。切勿提交私钥、`.p12` 或密码。

如需轮换签名，请从钥匙串访问导出对应身份到仓库以外的受密码保护 `.p12`，更新公钥证书和两个 Secrets，并安全备份。例如可使用 `base64 -i /安全路径/签名.p12 | gh secret set MACOS_SIGNING_P12_BASE64` 设置文件，再通过 `gh secret set MACOS_SIGNING_P12_PASSWORD` 交互式输入密码。更换签名身份可能使钥匙串重新要求授权。

## 项目文档

[产品设计](docs/product-design.md)和[技术方案](docs/technical-design.md)记录了产品目标、兼容性调研和恢复考虑。
