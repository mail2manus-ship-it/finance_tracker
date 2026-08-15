# Phase 6 — Testing, Optimization, Release Build

## Running the tests

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter test
```

Included:

- `test/core/utils/validators_test.dart` — amount/required-field/custom-
  category/notes validation rules.
- `test/core/utils/date_ranges_test.dart` — start/end of day/week/month/
  year math, including December→January and leap-year edge cases.
- `test/core/utils/transaction_filter_test.dart` — Search & Filter date
  preset resolution (today/yesterday/custom range) and `copyWith`
  semantics.
- `test/core/utils/insights_generator_test.dart` — Smart Financial
  Insights sentence generation: top-category percentage, month-over-
  month increase/decrease callouts, the 5-insight cap.
- `test/widget/splash_screen_test.dart`, `test/widget/amount_field_test.dart`
  — widget-level tests that don't require a live database.

**Not covered by these tests** (needs the real device/emulator, not
`flutter test`'s headless environment): Isar read/write round-trips,
PIN/biometric flows (`local_auth` requires real platform channels),
scheduled notifications, and the export file pickers. Run those
manually against a debug build. If you want repository-level tests
without a full emulator, Isar supports an in-memory test instance
(`Isar.open([...], directory: '', name: 'test_db')` in a `setUp`/
`tearDown` pair) — worth adding once the app is running locally and you
can confirm the generated `.g.dart` files build cleanly.

## Performance pass (Phase 6 changes)

- **Added missing Isar indexes**: `dateTime` and `isDeleted` on both
  `ExpenseModel` and `IncomeModel`. Every repository query
  (`getAll`, `getByDateRange`, `watchAll`, `watchByDateRange`) filters on
  `isDeleted` first and sorts by `dateTime` — those were previously
  unindexed while a less-used field (`date`) was. This matters once a
  user has hundreds/thousands of transactions; before this fix those
  queries degraded to full collection scans.
- **Lazy lists**: `TransactionsScreen` already used `ListView.builder`
  for the (potentially long, unbounded) full transaction list. Dashboard
  and Reports use plain `ListView`/`Column` since those lists are always
  short and bounded (top categories, last 10 transactions, 7-30 chart
  points) — `.builder` would be unnecessary overhead there.
- **Derived state, not re-queried state**: all Dashboard/Reports numbers
  are computed in Riverpod `Provider`s from the same two live Isar
  streams (`expenseListProvider`, `incomeListProvider`), so adding a
  transaction triggers one Isar write and Riverpod recomputes only the
  providers that actually depend on the changed data — no screen issues
  its own redundant queries.
- **`const` constructors** used throughout static widget trees (theme,
  tab list, chart legends) so Flutter can skip rebuilding subtrees that
  didn't change.

If profiling after real-world use turns up slow spots, the two most
likely candidates given this architecture are: (1) `_categoryBreakdown`
in `summary_providers.dart` doing an O(n) pass over all expenses on
every rebuild -- fine into the thousands of rows, but if a power user
accumulates tens of thousands of transactions, consider maintaining
running category totals incrementally instead of recomputing from
scratch; (2) the 30-day `savingsTrendProvider` loop, which is O(days ×
transactions) -- same mitigation if needed.

## Release build checklist

1. **Generate native platform projects** (this scaffold ships
   Dart/Flutter source only — run this once, locally):
   ```bash
   flutter create . --platforms=android,ios
   ```
2. **Android signing**: copy `release_config/key.properties.example` to
   `android/key.properties` (fill in real values, keep it out of git),
   and merge `release_config/build.gradle.snippet` into
   `android/app/build.gradle`. Copy `release_config/proguard-rules.pro`
   to `android/app/proguard-rules.pro`.
3. **App icons**: generate from a source image with
   `flutter_launcher_icons` (add as a dev dependency) or replace the
   files under `android/app/src/main/res/mipmap-*` and
   `ios/Runner/Assets.xcassets/AppIcon.appiconset` directly.
4. **Permissions**: confirm `android/app/src/main/AndroidManifest.xml`
   declares `USE_BIOMETRIC` (or `USE_FINGERPRINT` for older API levels),
   `POST_NOTIFICATIONS` (Android 13+), and `READ_MEDIA_IMAGES` /
   `READ_EXTERNAL_STORAGE` as needed by `image_picker`. iOS needs
   `NSFaceIDUsageDescription`, `NSPhotoLibraryUsageDescription`, and
   `NSCameraUsageDescription` entries in `ios/Runner/Info.plist`.
5. **Version bump**: update `version:` in `pubspec.yaml`
   (`major.minor.patch+buildNumber`).
6. **Build**:
   ```bash
   flutter build apk --release          # or: flutter build appbundle --release
   flutter build ipa --release          # macOS + Xcode required
   ```
7. **Smoke test the release build** on a real device before
   distributing — release mode disables asserts and changes some timing
   characteristics (animations, first-frame time) versus debug/profile.
