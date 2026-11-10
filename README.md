# Antigravity Account Switcher

[简体中文](README.zh-CN.md) · English

Manage your work, personal, and other Antigravity accounts from your Mac's menu bar. Save an account once, then switch accounts without setting up your workspace again.

## What you can do

- **Add accounts:** Sign in through Antigravity and save each account for later.
- **Switch accounts:** Pick a saved account from the menu bar and follow the guided steps.
- **Remove accounts:** Remove a saved account from the app without deleting your Google account.
- **Recover a login:** Restore the previous account if adding or switching is interrupted.
- **Choose a language:** Use Chinese or English, or follow your Mac's system language.

The app changes the saved login while keeping your local workspace and settings. Cloud data and access can differ between accounts, and Antigravity may make its own changes when you sign in.

## Get the app

Download the latest `Antigravity-Account-Switcher-v<version>-arm64.zip` from the [Releases page](https://github.com/zfdang/antigravity-account-switcher/releases). Unzip it and move the app to Applications. The current release supports Apple silicon Macs. Developers can build the current version using the [development guide](docs/development.md).

You need macOS 13 or later, Antigravity installed in `/Applications`, and an Antigravity account that is already signed in. The app is not notarized; macOS may display a security warning when opening it.

## Get started

1. Open **Antigravity Account Switcher**. Its icon appears in the menu bar.
2. Select **Save Current Account**. Save your work and close Antigravity when prompted; the app saves your current login for later.
3. Select **Add Account** and follow the wizard. Sign in to the other account in Antigravity, close Antigravity after signing in, then select **Finish Sign-in** in the wizard.
4. To switch, select an account in the menu and follow the wizard. Save your work and close Antigravity and any `agy` command-line processes when prompted. Antigravity reopens after the switch; check the displayed account there.
5. To remove a saved account, select **Remove Account** and confirm. This removes the app's saved copy; it does not delete the Google account or sign out the current Antigravity session.

If an operation is interrupted, close Antigravity and select **Restore Previous Account** in the menu. If macOS asks for Keychain access, approve the request to let the app read or save the login; denying access stops the operation.

## Language and privacy

The interface follows your Mac's preferred language by default: Chinese if the first preferred language is Chinese, and English otherwise. Choose **Language** in the menu to switch manually or return to **Follow System**.

Account credentials are stored in the Mac's Keychain and are not uploaded by this app. Antigravity itself handles sign-in. Never share your credentials or Keychain exports.

## For developers

See the [development guide](docs/development.md) for building, testing, and signing. The [product design](docs/product-design.md) and [technical design](docs/technical-design.md) are also available in Chinese.
