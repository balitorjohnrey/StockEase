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
npm install
```

3. Link and push the Supabase backend:

```powershell
npm run supabase -- login
npm run supabase -- link --project-ref dscjwdkwubcqxytulqml
npm run db:push:dry-run
npm run db:push
```

The initial backend migration is in `supabase/migrations/20260903000000_initial_stockease_schema.sql`. The same SQL is also kept in `supabase/schema.sql` for easy review. If you do not want to use the CLI, paste `supabase/schema.sql` into the Supabase SQL editor for the first setup.

4. Run the app with your Supabase project URL and publishable key:

```powershell
flutter run --dart-define=SUPABASE_URL=https://dscjwdkwubcqxytulqml.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_n7RFrDOkSD-mBr2PCDhNaA_M2U_j0W8
```

For web/Chrome specifically:

```powershell
flutter run -d chrome --web-port 4572 --dart-define=SUPABASE_URL=https://dscjwdkwubcqxytulqml.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_n7RFrDOkSD-mBr2PCDhNaA_M2U_j0W8
```

If VS Code is used, select **StockEase Web (Supabase)** or **StockEase Android (Supabase)** from Run and Debug.

If the app shows "StockEase needs Supabase settings", stop the current Flutter run with `Ctrl+C` and relaunch using one of the commands above.

## Email Confirmation Redirects

For local web testing, keep Flutter running on port `4572` and configure Supabase Auth to redirect there:

1. Open your Supabase project dashboard.
2. Go to **Authentication** > **URL Configuration**.
3. Set **Site URL** to `http://localhost:4572`.
4. Add **Redirect URL** `http://localhost:4572/**`.
5. Save, then create a new account or resend the confirmation email.

If a confirmation link still says "localhost refused to connect", it was probably generated before this setting changed. Send a fresh confirmation email and make sure Flutter is running when you click the link.

Use the same `--dart-define` values for release builds:

```powershell
flutter build web --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
flutter build apk --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
```

Never place a database password or Supabase service-role secret in the Flutter app.

## Database Changes

Create a new migration for every schema/RPC/RLS change:

```powershell
npm run db:migration -- your_change_name
```

Edit the new SQL file under `supabase/migrations/`, then push it:

```powershell
npm run db:push:dry-run
npm run db:push
```

## Included Features

- Email/password login and sign-up with persistent Supabase sessions.
- Business setup tied to the authenticated user.
- Dashboard metrics, recent sales, low-stock counts, and sales charts.
- Inventory search, product creation/editing, deactivation, price updates, restocking, and stock-movement history.
- Cashier cart, checkout, secure `complete_sale` RPC, duplicate-submit prevention, receipt display, and sales history.
- Low-stock alerts, best-selling product reports, expenses, profit summaries, and business/account settings.

All currency values are formatted with the Philippine peso symbol, and business report day boundaries use Asia/Manila time.
