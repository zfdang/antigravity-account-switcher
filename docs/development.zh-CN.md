# 开发文档

简体中文 · [English](development.md)

## 构建与测试

安装 Xcode 后运行：

```sh
./build.sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

签名后的应用位于 `dist/`。签名构建需要与[固定证书](../scripts/signing/release-certificate.pem)对应的私钥。没有该私钥时，可运行 `UNSIGNED_BUILD=1 ./build.sh` 进行本机临时签名构建；改变签名身份可能导致钥匙串再次要求授权。应用尚未经过 Apple 公证。

## CI 与签名

CI 在 PR 和推送时运行测试并构建临时签名包。独立的签名构建工作流在推送到 `main` 或手动触发时构建 zip 并上传为构建产物；在 `main` 上，如果 `VERSION` 中的版本尚未发布，还会创建对应的 GitHub Release。发布新版本前请更新 `VERSION`；已发布版本不会被覆盖。签名工作流需要仓库 Secrets `MACOS_SIGNING_P12_BASE64` 和 `MACOS_SIGNING_P12_PASSWORD`，其受密码保护的签名身份必须与仓库固定的公钥证书匹配；不匹配时构建失败。切勿提交私钥、`.p12` 或密码。

如需轮换签名，请从钥匙串访问导出对应身份到仓库以外的受密码保护 `.p12`，更新公钥证书和两个 Secrets，并安全备份。例如可使用 `base64 -i /安全路径/签名.p12 | gh secret set MACOS_SIGNING_P12_BASE64` 设置文件，再通过 `gh secret set MACOS_SIGNING_P12_PASSWORD` 交互式输入密码。更换签名身份可能使钥匙串重新要求授权。

## 设计文档

[产品设计](product-design.md)和[技术方案](technical-design.md)记录产品目标与兼容性调研。
