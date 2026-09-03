# StockEase

StockEase is a Flutter inventory and point-of-sale app for sari-sari stores, mini-groceries, and small retail shops. It uses Supabase Auth, PostgreSQL tables, Row Level Security, and secure RPC functions for checkout and restocking.

## Live App

This repository is configured to deploy the Flutter web app with GitHub Pages:

```text
https://balitorjohnrey.github.io/StockEase/
```

Push to `main`, then check the repository's **Actions** tab for the `Deploy Flutter Web` workflow. The workflow builds Flutter web and publishes the result to the `gh-pages` branch.

If GitHub asks for a Pages source, set **Settings** > **Pages** > **Source** to **Deploy from a branch**, then choose `gh-pages` and `/ (root)`.

## Setup

Install Flutter and enable web:

```powershell
flutter doctor
flutter config --enable-web
```

Install dependencies:

```powershell
flutter pub get
npm install
```

Run the app locally:

```powershell
flutter run -d chrome --web-port 4572
```

The default Supabase project is already configured in `lib/src/config/supabase_config.dart`. To override it for another Supabase project, pass dart defines:

```powershell
flutter run -d chrome --web-port 4572 --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

## Supabase Auth

To stop confirmation emails and allow users to sign up, return to login, then log in with email and password:

1. Open your Supabase project dashboard.
2. Go to **Authentication** > **Sign In / Providers**.
3. Open the **Email** provider.
4. Turn off **Confirm email**.
5. Save the change.

For password recovery, OAuth, or any future email-link flows, set **Authentication** > **URL Configuration**:

```text
Site URL: https://balitorjohnrey.github.io/StockEase/
Redirect URL: https://balitorjohnrey.github.io/StockEase/**
```

## Database Changes

The database schema is in `supabase/migrations/20260903000000_initial_stockease_schema.sql`, with the same SQL kept in `supabase/schema.sql` for easy review.

If the Supabase GitHub integration is enabled for `main`, push migration changes to GitHub and Supabase will apply them to production. You can also push manually with the local CLI:

```powershell
npm run supabase -- login
npm run supabase -- link --project-ref dscjwdkwubcqxytulqml
npm run db:push:dry-run
npm run db:push
```

Create a new migration for every schema, RPC, or RLS change:

```powershell
npm run db:migration -- your_change_name
```

Run a live smoke test against Supabase:

```powershell
npm run smoke:e2e
```

This creates a disposable test user and clearly named test business in the hosted Supabase project, then verifies signup, login, business setup, inventory, restock, checkout, sales history, expenses, and product deactivation.

Never place a database password or Supabase service-role secret in the Flutter app.

## Included Features

- Email/password login and sign-up with persistent Supabase sessions.
- Business setup tied to the authenticated user.
- Dashboard metrics, recent sales, low-stock counts, and sales charts.
- Inventory search, product creation/editing, deactivation, price updates, restocking, and stock-movement history.
- Cashier cart, checkout, secure `complete_sale` RPC, duplicate-submit prevention, receipt display, and sales history.
- Low-stock alerts, best-selling product reports, expenses, profit summaries, and business/account settings.

All currency values are formatted with the Philippine peso symbol, and business report day boundaries use Asia/Manila time.
