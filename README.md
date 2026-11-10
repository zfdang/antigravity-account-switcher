# Antigravity Account Switcher

[简体中文](README.zh-CN.md) · English

A macOS menu bar app for managing multiple Antigravity accounts. Save your current login, add another account through Antigravity's own sign-in flow, switch between accounts, and remove saved accounts while keeping your local workspace and settings.

The interface follows the system language by default (Chinese for a Chinese system, English otherwise). Choose **Language** in the menu to override it or return to **Follow System**.

## Requirements

- macOS 13 or later and Antigravity installed at `/Applications/Antigravity.app`.
- An existing signed-in Antigravity account. Adding another account starts by saving the current login.
- Keychain access for saved credentials and the active Antigravity login. macOS may request authorization, especially the first time or after a signing identity changes.

Antigravity's credential format is an internal implementation detail and may change. The app changes login credentials, but account-specific cloud data and changes made by Antigravity itself may differ between accounts. Confirm the active account in Antigravity after switching.

## Getting started

1. Build the application as described below, then open `dist/Antigravity Account Switcher.app`. Its icon appears in the menu bar.
2. Choose **Save Current Account**, save your work, and close Antigravity. The wizard saves the current login to the macOS keychain.
3. Choose **Add Account** and follow the wizard. Sign in through Antigravity, close it after login, and choose **Finish Sign-in** in the wizard.
4. To switch accounts, select a saved account in the menu and follow the wizard. Close Antigravity and any `agy` command-line processes before continuing; Antigravity reopens after the switch.
5. Use **Remove Account** to delete a saved copy. This does not delete the Google account or sign out the current IDE session.

If an operation is interrupted, close Antigravity and use **Restore Previous Account** in the menu. The app stores account credentials in the local keychain and does not upload them. Do not share credentials or keychain exports.

## Build and test

Install Xcode, then run:

```sh
./build.sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

The signed app is written to `dist/`. Signed builds require the private key corresponding to [the pinned certificate](scripts/signing/release-certificate.pem). For a local ad-hoc build without that key, run `UNSIGNED_BUILD=1 ./build.sh`; changing signing identities may cause additional keychain prompts. The app is not notarized.

## CI and signing

CI runs tests and builds an ad-hoc bundle on pull requests and pushes. A separate workflow builds a signed zip on pushes to `main` and manual runs, and uploads it as an artifact; it does not publish a release. The signed workflow requires repository secrets `MACOS_SIGNING_P12_BASE64` and `MACOS_SIGNING_P12_PASSWORD`, containing the password-protected identity matching the pinned public certificate. It fails if the identity does not match. Never commit the private key, `.p12`, or password.

To rotate signing credentials, export the matching identity from Keychain Access to a password-protected `.p12` outside the repository, update the public certificate and both secrets, and keep a secure backup. For example, set the archive with `base64 -i /secure/path/signing.p12 | gh secret set MACOS_SIGNING_P12_BASE64` and enter the password interactively using `gh secret set MACOS_SIGNING_P12_PASSWORD`. Replacing the identity can trigger keychain authorization again.

## Project documents

The [product design](docs/product-design.md) and [technical design](docs/technical-design.md) describe the intended behavior, compatibility investigation, and recovery considerations. They are currently written in Chinese.
