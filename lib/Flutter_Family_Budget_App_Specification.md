# SYSTEM SPECIFICATION & IMPLEMENTATION PROMPT
## Personal & Family Budget App — Flutter, Google Sheets, Responsive Multi-Platform

**Target:** Flutter AI Engineer / Anti-Gravity Agent  
**Source workbook:** `2026 Budget.xlsx`  
**Primary locale:** `id_ID` — Bahasa Indonesia, Rupiah (Rp), kalender Masehi  
**Platforms:** iPhone, Android phones, iPad, Android tablets; layout should also adapt to desktop/web if enabled  
**Primary goal:** Build a polished, reliable personal/family budgeting app that reads and writes the existing monthly worksheets while providing a clear financial dashboard, transaction logging, analytics, and responsive layouts.

---

## 1. Product goals

Build a production-minded Flutter application that lets the user:

1. Select a budget month from the available worksheet tabs.
2. View income, budget, actual spending, remaining budget, category summaries, bank balance and discrepancy.
3. Review and search budget items and daily expense records.
4. Add, edit, and delete daily expense transactions through a fast mobile-friendly form.
5. Associate each transaction with a budget item and update the relevant monthly data consistently.
6. See overspending, approaching limits, unusual values, sync status, and data-quality warnings.
7. Use the same application comfortably on small phones, large phones, iPads, and Android tablets without stretched or cramped UI.
8. Continue viewing cached data while offline, then sync safely when connectivity returns.

The app must use the spreadsheet as the existing source of truth unless a deliberate migration is approved. Do not silently redesign, overwrite, or “correct” the user's workbook structure.

## 2. Workbook facts and important implementation cautions

The supplied workbook contains these tabs:

- `November 2024`
- `0926`
- `1026`
- `1126`

Monthly code convention: `MMYY`, where `0926` = September 2026, `1026` = October 2026, and `1126` = November 2026. Detect valid month tabs dynamically; do not hardcode only these three months.

### 2.1 Observed layout in monthly tabs

The workbook has a familiar structure, but the exact rows and formulas are not identical in every month. The implementation must inspect sheet values and discover table boundaries rather than assume every tab is a perfect template.

Common layout observed in `1026` and `1126`:

| Area | Typical location | Meaning |
|---|---|---|
| Title | `B2` | Month/report title |
| Income | `B4:C...` | Income source and amount; examples include ABI and MAMA |
| Budget items | `D4:H...` | Budget item, planned amount, category, actual output, remaining amount |
| KPI summary | around `J5:M...` | Total income, total budget, spending, remaining amount and related values |
| Category summary | around `J10:M18` | Category budget, output and remainder |
| Bank / discrepancy values | around rows 20–27 | Bank balance and other workbook-specific reconciliation values |
| Daily expense log | begins around row 36 | Date, entry number, description and amount in columns `J:M` |

Observed budget item columns:
- `D`: budget item name
- `E`: budget amount
- `F`: category
- `G`: output / actual amount
- `H`: remaining amount

Observed transaction columns:
- `J`: date or date-group heading
- `K`: transaction number
- `L`: description
- `M`: amount

### 2.2 Month-specific differences

The September sheet `0926` is not laid out exactly like `1026` and `1126`. For example, its totals and transaction log start at different rows, and some budget entries/formulas use different row positions. The app must not assume that:
- budget items always end on row 34,
- transaction logs always begin at row 37,
- income only exists in rows 5–6,
- formulas are consistent across every month,
- all values are stored as plain numeric cells rather than formulas.

Use a configurable sheet parser with per-sheet detected ranges and validation. If a sheet cannot be parsed confidently, show a helpful data-structure warning and allow read-only viewing where possible; do not write to guessed coordinates.

### 2.3 Categories observed in the workbook

Use these category labels as the canonical values:
- `Wajib`
- `Keluarga`
- `Anak`
- `Transportasi`
- `Rumah`
- `Tabungan`
- `Lain-lain`

If the workbook contains a blank or unknown category, preserve the original value and display it as “Belum dikategorikan” or “Lain-lain” according to a documented mapping rule. Do not silently rewrite the source cell just because it is unknown.

### 2.4 Formula and calculation safety

The workbook uses formulas, including formulas that refer to transaction rows and category totals. Spreadsheet APIs may return either formula text or calculated values depending on the API options. Prefer reading calculated/unformatted values for display, and keep formula cells intact when writing.

- Never replace formula cells with calculated constants.
- Avoid writing a full sheet range when only a small number of cells need updating.
- Re-read the affected rows and summary values after a write to verify the result.
- The app's derived totals should be cross-checked against the sheet values and show a warning if they differ.
- Handle empty cells, numeric cells, formula results, decimal values and scientific notation safely.
- Rupiah display should normally have zero decimal places, but retain underlying precision when the source contains decimals.

## 3. Core screens

### 3.1 Home dashboard

Show the selected month prominently, plus a month selector that lists all valid monthly tabs in chronological order.

Primary KPI cards:
- Total pemasukan
- Total budget
- Total pengeluaran / realisasi
- Sisa anggaran

Secondary information:
- Saldo bank, when available
- Selisih / discrepancy, when available
- Sync status: Synced, Syncing, Offline cache, or Sync failed
- Last successful sync timestamp

Visuals:
- Donut chart for spending by category
- Category progress bars showing actual vs budget
- Daily spending chart
- Recent transactions
- Alerts for over-budget categories/items and possible data inconsistencies

All KPIs must state their calculation basis. Distinguish “sisa anggaran” from “saldo bank”; they are not necessarily the same amount.

### 3.2 Budget items

Provide a searchable, filterable list of budget items. Each item should show:
- Item name
- Budget
- Actual output
- Remaining amount
- Utilization percentage
- Category badge
- State: On track, Near limit, Over budget, or No budget set

Allow filtering by category and status, sorting by item name, budget, actual spending, remaining amount, and utilization.

Selecting an item opens a detail screen with associated transactions, budget progress, and an “Tambah Pengeluaran” action.

### 3.3 Daily expense log

Present transactions grouped by date, with newest dates first by default. Each row should show description, amount, budget item/category if known, and sync state if pending.

Provide:
- Search by description
- Date range filter
- Category and budget-item filters
- Sort by newest/oldest and amount
- Transaction detail
- Edit and delete actions, subject to confirmation and write permissions

### 3.4 Quick add transaction

Use a modal bottom sheet or full-screen form on phones. On tablets, prefer a centered dialog, side panel, or spacious form that uses the extra width.

Fields:
- Date (default to today in the device's local time zone)
- Description (required)
- Amount in IDR (required; must be greater than zero unless the app explicitly supports refunds)
- Budget item (select existing item)
- Category (derive from selected budget item; only allow a separate category if the data model explicitly supports it)
- Optional note, if a safe place to store it is defined

Behavior:
1. Validate the form before saving.
2. Show a clear confirmation with the amount and selected item.
3. Write only to the appropriate transaction cells / supported API endpoint.
4. Ensure the transaction number is unique within the date group if the workbook requires it.
5. Update the budget item's output using the workbook's established mapping or a backend-managed transaction-to-budget mapping.
6. Re-fetch affected data and verify totals.
7. Prevent accidental duplicate submissions by disabling the submit action while a save is in progress and using an idempotency key where supported.
8. If saving fails, keep the entered form data and offer retry. Do not show a success message until the write is confirmed.

**Critical:** The current workbook appears to calculate some budget item outputs from specific transaction row references and formulas. Do not assume a transaction can be associated with any budget item merely by inserting a row. First implement and validate a mapping strategy that preserves existing workbook formulas. If a safe mapping cannot be determined, make the transaction write read-only/disabled and explain the setup required rather than corrupting formulas.

### 3.5 Analytics and alerts

Include:
- Budget utilization by item and category
- Daily spending trend
- Month-to-month comparisons when comparable months exist
- Highest spending items
- Remaining budget ranking
- Over-budget alerts
- Near-limit alerts
- Missing category / unmapped transaction warnings
- Bank reconciliation discrepancy, only when the source provides enough information

Suggested visual thresholds (make configurable):
- Below 75% used: normal
- 75%–95%: approaching limit
- Above 95% and up to 100%: near limit
- Above 100%: over budget

These thresholds are UI alert conventions, not a replacement for the spreadsheet's own financial formulas.

## 4. Responsive UI requirements: iPhone, Android, iPad and Android tablets

**Responsive design is a core requirement, not a later enhancement.** Use Flutter's available layout constraints (for example `LayoutBuilder`, `MediaQuery`, and adaptive navigation) rather than checking only device names or operating systems.

### 4.1 Adaptive layout behavior

Use available content width as the main layout signal. Suggested starting breakpoints:
- **Compact:** under 600 logical pixels — phone layout
- **Medium:** 600–899 logical pixels — tablet / large phone layout
- **Expanded:** 900 logical pixels and above — wide tablet / desktop-style layout

Treat these as initial defaults; test and adjust based on actual content and accessibility.

**Compact phone layout**
- Single-column dashboard with KPI cards in a 2-column grid where they remain readable, or a vertical stack on very narrow widths.
- Bottom navigation or compact navigation rail, whichever best fits the number of destinations.
- Floating action button for quick transaction entry.
- Full-width forms with comfortable touch targets.
- No horizontal overflow at large text sizes.

**Medium tablet layout**
- Navigation rail or adaptive side navigation.
- Dashboard KPI cards in 2–3 columns.
- Dashboard sections may use a two-column layout.
- Budget item list can sit beside a detail pane in landscape when width permits.
- Forms use a centered dialog or medium-width panel rather than stretching edge-to-edge.

**Expanded tablet / wide layout**
- Persistent navigation rail or sidebar.
- Dashboard uses a balanced multi-column grid with a sensible maximum content width.
- Budget list and selected-item detail can appear side by side.
- Charts should grow only to a useful maximum width; avoid excessively wide donut charts.
- Use whitespace deliberately and keep important figures visually prominent.

### 4.2 Platform behavior

- Support iOS on iPhone and iPad, and Android on phones and tablets.
- Respect safe areas, display cutouts, status/navigation bars, keyboard insets, orientation changes, and system text scaling.
- Support portrait and landscape layouts.
- Use platform-appropriate back navigation and dialogs while keeping a consistent visual design.
- Do not assume that all tablets are landscape or all phones are portrait.
- Use touch targets around 44–48 logical pixels where practical.
- Ensure text remains legible with larger accessibility font settings.
- Avoid fixed widths/heights for main content. Prefer flexible constraints, `Wrap`, adaptive grids, and scrollable areas.
- Test split-screen and resized windows where supported.

### 4.3 Responsive acceptance criteria

The UI is not complete until it has been tested on:
- Small iPhone-sized viewport
- Large iPhone-sized viewport
- Android phone viewport
- iPad portrait and landscape
- Android tablet portrait and landscape
- Large text / accessibility scaling
- Keyboard visible on transaction forms
- Offline and loading states

Acceptance:
- No overflow exceptions or clipped financial values.
- No forced horizontal scrolling for primary dashboard content.
- Tables adapt to cards or compact lists on phones.
- Wide layouts make good use of space without stretching every component.
- All key actions remain reachable and tappable in every supported layout.

## 5. Visual design system

Create a premium, calm, finance-focused interface using Material 3:
- Clear typography hierarchy and consistent spacing.
- Neutral surfaces with restrained accent colors.
- Use semantic color meaning, but never rely on color alone to communicate status.
- Green/normal, amber/approaching limit, red/over budget; pair colors with labels and icons.
- Rounded cards with subtle elevation, consistent corner radii, and deliberate whitespace.
- Use currency formatting consistently: `Rp 1.234.567`.
- Avoid decorative effects that reduce readability or slow down frequent transaction entry.
- Include dark mode and light mode.
- Provide loading skeletons, empty states, error states, and clear retry actions.

## 6. Suggested architecture and technology

Use a maintainable feature-first clean architecture:

```text
lib/
  app/
    app.dart
    router/
    theme/
    responsive/
  core/
    errors/
    formatting/
    logging/
    network/
    sync/
    security/
  features/
    dashboard/
      data/
      domain/
      presentation/
    budget/
      data/
      domain/
      presentation/
    transactions/
      data/
      domain/
      presentation/
    analytics/
      data/
      domain/
      presentation/
    settings/
      data/
      domain/
      presentation/
```

Recommended stack:
- Flutter stable / Dart stable compatible with the project
- Material 3
- Riverpod for state management
- `go_router` or an equivalent structured router
- `intl` for Indonesian currency and date formatting
- `fl_chart` or a maintained chart package
- `freezed` / `json_serializable` if useful for immutable models and parsing
- A local persistence layer such as Isar, Hive, or SQLite/Drift, chosen based on current compatibility and maintenance
- Google Sheets API v4 via OAuth or a secure backend / Google Apps Script Web App

Do not embed a Google service-account private key or other long-lived secrets in the Flutter client. Prefer user OAuth with least privilege or a backend that protects credentials and validates requests. Do not make a public Apps Script endpoint capable of unrestricted writes to the spreadsheet.

## 7. Data models

Create domain models independent of cell coordinates. Suggested entities:

- `MonthIdentifier`: month, year, sheet code, display name
- `IncomeSource`: source name, amount, source row/cell metadata
- `BudgetItem`: stable identifier, name, planned amount, category, actual amount, remaining amount, utilization, source row metadata
- `DailyExpense`: stable ID, date, entry number, description, amount, linked budget item if known, sync status, source row metadata
- `CategorySummary`: category, budget, actual, remaining
- `MonthlyOverview`: month, income total, budget total, expense total, remaining total, optional bank balance, optional discrepancy, items, transactions, category summaries
- `SyncState`: status, last successful sync, pending changes, last error

Keep spreadsheet row/cell metadata in the data layer, not as the primary identity of a domain entity. Rows can move between months.

## 8. Calculation rules

Treat the following as intended calculation concepts, and verify each against the actual workbook formulas before relying on it:

- Item remaining = item budget − item actual output
- Category budget = sum of budgets in that category
- Category actual = sum of outputs in that category
- Category remaining = category budget − category actual
- Total income = sum of valid income source amounts
- Total budget = sum of valid budget item amounts
- Total spending = sum of actual spending, using one authoritative basis and avoiding duplicate counting
- Total remaining budget = total budget − total spending

Bank balance and discrepancy calculations vary in the existing workbook. Preserve their workbook-specific definitions until the user approves a normalized rule. If a value is missing, display “Tidak tersedia” rather than inventing it.

Do not add together formula-derived budget outputs and raw transactions if the budget outputs already include those same transactions. Define one authoritative total-spending calculation and document it.

## 9. Spreadsheet integration and write strategy

### Preferred integration options

**Option A — Secure backend / Apps Script REST API**
- Backend reads the workbook and returns normalized JSON.
- Backend validates writes, identifies the correct month and transaction location, and applies changes narrowly.
- Protect write endpoints with authentication and authorization.
- Return structured errors and updated totals.

**Option B — Google Sheets API from the client**
- Use a suitable OAuth flow and minimal scopes.
- Never ship private service-account keys inside the app.
- Restrict workbook access to the authenticated user as appropriate.

Choose one integration option and document its setup steps in the project README.

### Parser and repository responsibilities

- Discover valid monthly sheet tabs dynamically using a strict `MMYY` pattern and valid month range 01–12.
- Sort months chronologically.
- Read values and formulas deliberately; retain formula cells.
- Detect header rows and table boundaries based on labels and actual populated data.
- Handle each sheet's differing layout safely.
- Normalize cell values without changing original spreadsheet content.
- Return typed domain models plus parsing warnings.
- Log technical details without exposing tokens or secrets.

### Write safeguards

- Use narrow range updates; do not clear and rewrite an entire sheet.
- Confirm the month and transaction details before destructive operations.
- Prevent duplicate transaction creation on retries.
- After write, read back the transaction and affected totals.
- Record sync failures and allow retry.
- For edit/delete, require confirmation and preserve an audit trail if supported.
- If a row insertion would break formulas or existing references, do not perform it until a safe strategy has been implemented and tested.
- Provide a read-only mode if the integration is not yet safe for writes.

## 10. Offline-first and synchronization

- Cache the last successfully loaded month and relevant dashboard data.
- Clearly label cached values as potentially stale.
- Queue offline transaction edits only if conflict handling and safe replay are implemented.
- Assign local IDs and idempotency identifiers to pending writes.
- Define conflict behavior if the sheet is edited externally before a queued change syncs.
- Never silently overwrite newer spreadsheet changes.
- Display pending, syncing, synced, and failed states.
- Provide manual refresh and a “last synced” timestamp.

## 11. Security and privacy

- Do not log transaction descriptions, account balances, OAuth tokens, or credentials unnecessarily.
- Store tokens using platform-secure storage when needed.
- Require authentication for any server-side write operation.
- Validate all values on both client and server.
- Request only the permissions required to access the workbook.
- Do not expose the spreadsheet publicly as a shortcut for authentication.
- Include a clear sign-out / disconnect action.

## 12. Error handling and data quality

Handle at least:
- No network / timeout
- Authentication expired or access denied
- Worksheet missing or malformed
- Unsupported month tab name
- Empty sheet or empty month
- Formula result unavailable
- Invalid currency value
- Duplicate transaction submission
- Concurrent edit conflict
- Write succeeded but read-back verification failed
- Cached data older than the expected freshness threshold

Errors should be understandable to the user, with technical diagnostics available in debug logs. Never show a false success state.

## 13. Testing requirements

Create unit tests for:
- `MMYY` parsing and chronological sorting
- Indonesian Rupiah and date formatting
- Empty cells, formulas, decimals, and scientific notation parsing
- Category normalization
- Totals and discrepancy calculations
- Month-specific sheet layouts
- Duplicate transaction prevention
- Transaction-to-budget mapping
- Conflict and retry behavior

Create widget tests for:
- Dashboard loading, success, empty, offline and error states
- Responsive phone and tablet layouts
- Large text scaling
- Quick-add validation
- Category filters and search
- Over-budget indicators

Create integration tests for:
- Read workbook and select month
- Create a transaction in a test workbook
- Verify affected values and formulas remain intact
- Edit/delete transactions if supported
- Simulate network failure and retry

Use a **separate test spreadsheet** for write integration tests. Never run destructive tests against the user's live budget workbook.

## 14. Implementation roadmap

1. Inspect the Flutter project and existing conventions before creating or changing files.
2. Confirm workbook access method, authentication and write permissions.
3. Build a read-only sheet inspector/parser and validate it against `0926`, `1026`, and `1126`.
4. Add parser tests and compare parsed data against the workbook.
5. Implement domain models and financial calculations.
6. Build the responsive design system and navigation.
7. Implement dashboard, budget list, category summaries and transaction history.
8. Add transaction input only after the write/mapping strategy is proven safe on a test workbook.
9. Add caching, synchronization, offline states and error handling.
10. Add analytics, alerts, dark mode and accessibility.
11. Run unit, widget and integration tests.
12. Document setup, permissions, architecture, limitations and release steps.

At each phase, run the app, inspect logs, fix issues, and report what is complete. Do not claim a feature works if it has only been scaffolded.

## 15. Definition of done

The app is ready for initial release only when:
- It dynamically detects and lists monthly tabs.
- It accurately displays workbook data for the supplied months.
- Calculations are validated against workbook values and documented.
- Responsive layouts work on iPhone, Android phones, iPad and Android tablets in portrait and landscape.
- Primary screens work with large text and keyboard-visible states.
- Loading, empty, offline, error and sync states are implemented.
- Transaction writes are tested against a separate test workbook and preserve formulas.
- Credentials are not embedded in the client.
- Automated tests pass and setup instructions are documented.
- Any unsupported or ambiguous workbook behavior is clearly disclosed rather than guessed.

---

## 16. Final instruction to the Flutter / Anti-Gravity AI Agent

> Build this as a polished, maintainable Flutter budgeting application using Material 3 and Riverpod, with a clean feature-first architecture and responsive layouts for iPhone, Android phones, iPad, and Android tablets. Treat the supplied `2026 Budget.xlsx` workbook as the authoritative reference. Inspect the real worksheet structure before implementing parsing or writes; the monthly sheets are similar but not identical. Preserve formulas and existing data, validate calculations against the workbook, and implement transaction writing only after a safe mapping strategy has been tested on a separate workbook. Prioritize financial correctness, secure integration, accessibility, responsive behavior, clear synchronization status, and a refined user experience over decorative complexity.
