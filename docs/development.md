# Development

[简体中文](development.zh-CN.md) · English

## Build and test

Install Xcode, then run:

```sh
./build.sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

The signed app is written to `dist/`. Signed builds require the private key corresponding to [the pinned certificate](../scripts/signing/release-certificate.pem). For a local ad-hoc build without that key, run `UNSIGNED_BUILD=1 ./build.sh`; changing signing identities may cause additional keychain prompts. The app is not notarized.

## CI and signing

CI runs tests and builds an ad-hoc bundle on pull requests and pushes. A separate workflow builds a signed zip on pushes to `main` and manual runs, and uploads it as an artifact; it does not publish a release. The signed workflow requires repository secrets `MACOS_SIGNING_P12_BASE64` and `MACOS_SIGNING_P12_PASSWORD`, containing the password-protected identity matching the pinned public certificate. It fails if the identity does not match. Never commit the private key, `.p12`, or password.

To rotate signing credentials, export the matching identity from Keychain Access to a password-protected `.p12` outside the repository, update the public certificate and both secrets, and keep a secure backup. For example, set the archive with `base64 -i /secure/path/signing.p12 | gh secret set MACOS_SIGNING_P12_BASE64` and enter the password interactively using `gh secret set MACOS_SIGNING_P12_PASSWORD`. Replacing the identity can trigger keychain authorization again.

## Design documents

See the [product design](product-design.md) and [technical design](technical-design.md) for product goals and compatibility research (in Chinese).
