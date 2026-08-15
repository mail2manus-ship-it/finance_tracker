# My Personal Finance Tracker — Complete (Phases 1–6)

**Tagline:** Track Every Rupee. Understand Every Expense.

All six phases from the original build plan are done:

1. Project setup, folder structure, theme, navigation, local database,
   state management.
2. Expense & Income modules — Add/Edit, Isar repositories, validation,
   search, filters, swipe-to-delete with Undo.
3. Dashboard wired to live data — daily/monthly totals, charts, Smart
   Financial Insights, recent transactions.
4. Reports (Daily/Weekly/Monthly/Yearly) + PDF/Excel/CSV export.
5. Settings — theme/currency, PIN lock + biometric unlock, daily
   reminders, local backup & restore.
6. **Testing, performance pass, and release build docs** (this update)
   — see `RELEASE.md` for the full checklist.

This app runs completely offline, requires no account, and every number
on screen is derived live from the local Isar database — nothing here
needs a manual refresh.

## Folder Structure

```
lib/
  core/
    constants/        # app-wide constants (categories, sources, payment methods)
    database/          # Isar setup + Riverpod provider
    routing/            # named route table
    theme/              # colors + Material 3 ThemeData
  data/
    models/            # Isar @collection classes (Expense, Income, Settings)
    repositories/       # concrete repo implementations (Phase 2)
  domain/
    entities/           # plain domain objects (Phase 2, if needed beyond models)
    repositories/       # abstract repository contracts
  presentation/
    providers/          # Riverpod state (theme, future: transactions, filters)
    screens/
      home/             # bottom-nav shell + dashboard placeholder
      splash/           # branded splash
      expense/           # Add/Edit Expense (Phase 2)
      income/             # Add/Edit Income (Phase 2)
    widgets/common/       # shared reusable widgets (Phase 2+)
  main.dart
```

This follows **Clean Architecture** (`data` → `domain` → `presentation`,
dependencies point inward), **MVVM** (Riverpod notifiers act as
ViewModels), and the **Repository Pattern** (UI depends on abstract
`ExpenseRepository`/`IncomeRepository`, not Isar directly).

## Database Schema (Isar)

**ExpenseModel**: id, date, dateTime, category, customCategory, amount,
paymentMethod, notes, imagePath, createdAt, updatedAt, isDeleted (soft
delete for Undo).

**IncomeModel**: id, date, dateTime, source, amount, notes, createdAt,
updatedAt, isDeleted.

**SettingsModel**: single row (id fixed at 0) — currencySymbol,
currencyCode, themeMode, reminderMinutesOfDay, reminderEnabled, pinEnabled,
biometricEnabled. The PIN itself is never stored here — it belongs in
`flutter_secure_storage` (wired in Phase 5).

## State Management

Riverpod (`flutter_riverpod`). `isarProvider` is overridden at app start
with the already-opened Isar instance, so no widget needs to handle a
"database still loading" state. `themeModeProvider` drives light/dark mode
app-wide.

## Getting Started

```bash
flutter pub get

# Generate Isar's *.g.dart adapters (required before first run,
# and again any time a model in lib/data/models changes):
flutter pub run build_runner build --delete-conflicting-outputs

flutter run
```

## What Phase 2 added

- `data/repositories/isar_expense_repository.dart` and
  `isar_income_repository.dart` — concrete implementations of the Phase 1
  repository contracts (soft-delete, restore, date-range/full-text query,
  live `.watch()` streams).
- `presentation/providers/repository_providers.dart`,
  `expense_providers.dart`, `income_providers.dart` — Riverpod wiring:
  live lists, a shared `TransactionFilter`, filtered views, and
  delete/undo notifiers.
- `presentation/screens/expense/add_edit_expense_screen.dart` and
  `presentation/screens/income/add_edit_income_screen.dart` — full
  Add/Edit forms (amount, date/time, category or source, payment method,
  notes, optional receipt photo for expenses), with validation via
  `core/utils/validators.dart`.
- `presentation/screens/home/transactions_screen.dart` — merged,
  searchable, filterable transaction feed with swipe-to-delete and an
  Undo snackbar.
- Shared widgets: `AmountField`, `CategoryPicker`, `DateTimePickerRow`,
  `TransactionTile`, `FilterSheet`.
- Home shell's FAB and bottom nav now open the real Add Expense / Add
  Income screens and the real Transactions tab instead of placeholders.

## What Phase 3 added

- `domain/entities/summary.dart` — plain `DailySummary`, `MonthlySummary`,
  `OverallStatistics`, `CategoryTotal` value objects (no Isar/Riverpod
  dependency, so they're trivially unit-testable).
- `presentation/providers/summary_providers.dart` — derives all of the
  above, plus weekly chart data and a 30-day savings-trend series, from
  the same live `expenseListProvider` / `incomeListProvider` streams
  Phase 2 already set up. A `monthlySummaryForProvider` family makes
  "summary for any given month" reusable by Reports in Phase 4.
- `core/utils/date_ranges.dart` — calendar-math helpers (start/end of
  day/week/month/year) shared by summaries and, later, Reports.
- `core/utils/insights_generator.dart` — turns computed summaries into
  the Smart Financial Insights sentences from the spec (top category %,
  month-over-month category change, highest expense, average daily
  spend, category reductions).
- `presentation/widgets/charts/` — `CategoryPieChart`, an
  `IncomeExpenseBarChart`, and a `SavingsTrendChart`, all built on
  `fl_chart` and styled with the app's income/expense/savings palette.
- `presentation/screens/dashboard/dashboard_screen.dart` — the real
  Dashboard tab, replacing Phase 1's static placeholder.

## What Phase 4 added

- `presentation/providers/report_providers.dart` — `ReportPeriodState`
  (daily/weekly/monthly/yearly + a reference date you can page forward/
  back through), plus derived providers for the period's transactions
  and chart-ready buckets (daily buckets for day/week/month views,
  monthly buckets for the yearly view).
- `presentation/screens/reports/reports_screen.dart` — period tabs, a
  totals row, the Income vs Expense bar chart and Category Comparison
  pie chart (both reusing Phase 3's chart widgets), and three export
  buttons.
- `core/export/` — format-agnostic `ExportRow`, plus `CsvExporter`,
  `ExcelExporter`, and `PdfExporter` implementations, tied together by
  `ReportExportService.exportAndShare()` which converts models →
  `ExportRow`s, writes the file, and opens the native share sheet via
  `share_plus`.

## What Phase 5 added

- `core/security/pin_service.dart` — salts + SHA-256-hashes the PIN and
  stores only the hash via `flutter_secure_storage` (Keychain on iOS,
  Keystore-backed encrypted prefs on Android). The raw PIN is never
  written to disk anywhere.
- `core/security/biometric_service.dart` — thin wrapper over `local_auth`
  for fingerprint/Face ID, with device-capability checks.
- `presentation/screens/settings/pin_screen.dart` — one reusable PIN
  entry screen for create/confirm/change/unlock flows.
- `presentation/screens/settings/app_lock_gate.dart` — wraps the whole
  app (via `MaterialApp.builder`) and shows the PIN/biometric screen on
  cold start and every time the app returns from the background, when
  PIN Lock is enabled.
- `core/notifications/notification_service.dart` — schedules a repeating
  daily local notification at a user-chosen time via
  `flutter_local_notifications` + `timezone`.
- `core/backup/backup_service.dart` — serializes every expense, income,
  and setting to a single indented `.json` file, shares it via the OS
  share sheet, and can restore from a previously-saved file (with a
  confirmation dialog before overwriting current data). PIN/biometric
  flags are deliberately excluded from backups so restoring on a new
  device never carries over a stale lock credential.
- `presentation/screens/settings/settings_screen.dart` — the real
  Settings tab: theme (synced with `SettingsModel` so it persists across
  restarts), currency (read-only for now — multi-currency is a spec'd
  future feature), PIN lock + biometric toggles, reminder toggle + time
  picker, Backup/Restore, and an About section.

## Roadmap (remaining phases)

All six phases are complete. See `RELEASE.md` for:
- how to run the test suite (`test/`)
- the performance changes made in Phase 6 (missing Isar indexes were
  the main find)
- the full release-build checklist (generating native `android`/`ios`
  projects, signing, ProGuard rules, permissions, versioning)

Each phase will be delivered with its own folder structure additions,
schema changes (if any), providers, repository code, and tests, per the
original spec's "Expected Output" section.
