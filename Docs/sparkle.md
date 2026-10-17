# Sparkle in-app updates

Octoshot uses [Sparkle 2](https://sparkle-project.org/) for signed, notarized update delivery.

## Feed URL

Released builds read:

`https://neardws.github.io/Octoshot/appcast.xml`

The appcast is published from `website/public/appcast.xml` when the GitHub Pages site deploys from `main`.

## Checking for updates

- Menu bar **Octoshot → Check for Updates…** (简体：**检查更新…**)
- **Settings → About → Check for Updates…**

Automatic checks run once per day (`SUScheduledCheckInterval` = 86400). Downloads are **not** installed without user confirmation (`SUAutomaticallyUpdate` = false).

Debug builds and non-`.app` runs do not start Sparkle (no error dialogs when `SUFeedURL` is absent from the running bundle).

## Signing keys (maintainers)

Sparkle uses an Ed25519 key pair:

1. On a Mac, run:

   ```bash
   bash Scripts/generate-sparkle-keys.sh
   ```

   This uses Sparkle’s `generate_keys`, stores the private key in your login Keychain, and exports:

   `~/octoshot-private/sparkle/eddsa_priv.key`

2. Copy the printed **public** key into `Octoshot/Info.plist` as `SUPublicEDKey` (only the public key belongs in git).

3. **Never commit** `eddsa_priv.key` or any Keychain export. The repo `.gitignore` lists common private-key paths.

If you regenerate keys, every future appcast must be signed with the matching private key. Without the private key that corresponds to `SUPublicEDKey`, you must generate a new pair and ship a release that updates the public key in the app.

Optional GitHub Actions secret: store the **file contents** of `eddsa_priv.key` as `SPARKLE_EDDSA_KEY` and write it to a temp path before calling `Scripts/generate-appcast.sh`.

## Publishing an appcast (no GitHub Release from this script)

After `Scripts/package.sh` produces a **notarized** DMG:

```bash
export VERSION=0.2.1
export DMG_PATH=dist/Octoshot-v0.2.1-macOS.dmg
# SPARKLE_KEY defaults to ~/octoshot-private/sparkle/eddsa_priv.key
bash Scripts/generate-appcast.sh
```

Commit `website/public/appcast.xml`, merge to `main`, and ensure the release DMG is uploaded to GitHub Releases at the URL used in the appcast enclosure (for example `https://github.com/neardws/Octoshot/releases/download/v0.2.1/Octoshot-v0.2.1-macOS.dmg`).

## Placeholder appcast

Until the first signed release, the feed is an empty RSS channel (no `<item>` entries). Sparkle treats that as “no updates available” and does not break clients.
