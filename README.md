# StockEase

StockEase is a Flutter inventory and point-of-sale app for sari-sari stores, mini-groceries, and small retail shops. It uses Supabase Auth, PostgreSQL tables, Row Level Security, and secure RPC functions for checkout and restocking.

## Setup

1. Install Flutter and enable the platforms you need:

```powershell
flutter doctor
flutter config --enable-web
```

2. Install dependencies:

```powershell
flutter pub get
```

3. Run the SQL in `supabase/schema.sql` in your Supabase SQL editor.

4. Run the app with your Supabase project URL and publishable key:

```powershell
flutter run --dart-define=SUPABASE_URL=https://dscjwdkwubcqxytulqml.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_n7RFrDOkSD-mBr2PCDhNaA_M2U_j0W8
```

Use the same `--dart-define` values for release builds:

```powershell
flutter build web --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
flutter build apk --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
```

Never place a database password or Supabase service-role secret in the Flutter app.

## Included Features

- Email/password login and sign-up with persistent Supabase sessions.
- Business setup tied to the authenticated user.
- Dashboard metrics, recent sales, low-stock counts, and sales charts.
- Inventory search, product creation/editing, deactivation, price updates, restocking, and stock-movement history.
- Cashier cart, checkout, secure `complete_sale` RPC, duplicate-submit prevention, receipt display, and sales history.
- Low-stock alerts, best-selling product reports, expenses, profit summaries, and business/account settings.

All currency values are formatted with the Philippine peso symbol, and business report day boundaries use Asia/Manila time.
