# Building the APK via GitHub Actions (no local Flutter install needed)

This repo includes `.github/workflows/build-apk.yml`, which builds a
debug APK on GitHub's own servers (which have normal internet access,
unlike this chat's sandboxed environment) and hands it back to you as a
downloadable file.

## One-time setup

1. Create a new repository on GitHub (public or private, either works).
2. Push this project to it:
   ```bash
   cd finance_tracker
   git init
   git add .
   git commit -m "Initial commit: My Personal Finance Tracker"
   git branch -M main
   git remote add origin https://github.com/<your-username>/<your-repo>.git
   git push -u origin main
   ```
   Pushing to `main` automatically triggers the build (see the `on:`
   block in the workflow file).

## Getting the APK

1. On GitHub, open your repo → the **Actions** tab.
2. Click the most recent **Build APK** run (it takes a few minutes —
   downloading the Flutter SDK, Android SDK, and Gradle dependencies
   fresh on first run is the slow part).
3. Once it finishes (green checkmark), scroll to the **Artifacts**
   section at the bottom of that run's page.
4. Download **finance-tracker-debug-apk** — that's a `.zip` containing
   `app-debug.apk`. Unzip it and install on an Android device (you may
   need to enable "install unknown apps" for your file manager/browser).

## Re-running without a new commit

Go to **Actions → Build APK → Run workflow** (top right) to trigger a
fresh build anytime, even without pushing new code — useful if a
transient dependency download fails and you just want to retry.

## If the build fails

The most likely causes, in order:

- **A dependency version conflict** — `flutter pub get` will print
  exactly which package. Adjust the version in `pubspec.yaml` and push
  again.
- **A `build_runner` codegen error** — usually means one of the Isar
  `@collection` models has a syntax issue; the error output points at
  the exact file/line.
- **A test failure** — the workflow runs `flutter test` before building;
  if a test fails the APK step is skipped. Remove the `Run tests` step
  temporarily (or fix the failing test) if you want the APK regardless.
- **Flutter version mismatch** — this workflow pins Flutter 3.24.0.
  If a package requires a newer Flutter, bump the `flutter-version` in
  the workflow file.

## Want a release (signed) build instead?

The workflow above builds a **debug** APK, which is fine for installing
on your own device but isn't signed for distribution. For a signed
release build, you'd add your keystore as a GitHub Actions secret and
extend the workflow per the signing steps in `RELEASE.md` — ask if you
want that version written out too.
