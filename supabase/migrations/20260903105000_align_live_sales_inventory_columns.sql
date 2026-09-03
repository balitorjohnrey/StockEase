-- Keep the live production schema compatible with the current app/RPC code.
-- The existing hosted database had older sales, sale_items, stock_movements,
-- and expenses column names. These additions are idempotent for fresh projects.

alter table public.categories
add column if not exists is_active boolean not null default true,
add column if not exists updated_at timestamptz not null default now();

alter table public.sales
add column if not exists cashier_id uuid,
add column if not exists receipt_number text,
add column if not exists estimated_gross_profit numeric(12, 2) not null default 0,
add column if not exists customer_id uuid,
add column if not exists sale_number text,
add column if not exists created_by uuid,
add column if not exists voided_at timestamptz;

update public.sales
set receipt_number = coalesce(receipt_number, sale_number),
    sale_number = coalesce(sale_number, receipt_number),
    cashier_id = coalesce(cashier_id, created_by),
    created_by = coalesce(created_by, cashier_id),
    estimated_gross_profit = coalesce(estimated_gross_profit, 0);

alter table public.sales
alter column cashier_id set not null,
alter column receipt_number set not null,
alter column status set default 'completed';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'sales_cashier_id_fkey'
      and conrelid = 'public.sales'::regclass
  ) then
    alter table public.sales
    add constraint sales_cashier_id_fkey
    foreign key (cashier_id) references auth.users(id);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'sales_receipt_number_key'
      and conrelid = 'public.sales'::regclass
  ) then
    alter table public.sales
    add constraint sales_receipt_number_key unique (receipt_number);
  end if;
end $$;

create or replace function public.sync_sales_compat_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.receipt_number = coalesce(new.receipt_number, new.sale_number);
  new.sale_number = coalesce(new.sale_number, new.receipt_number);
  new.cashier_id = coalesce(new.cashier_id, new.created_by, auth.uid());
  new.created_by = coalesce(new.created_by, new.cashier_id, auth.uid());
  new.estimated_gross_profit = coalesce(new.estimated_gross_profit, 0);
  new.status = coalesce(nullif(new.status, ''), 'completed');
  return new;
end;
$$;

drop trigger if exists sales_sync_compat_columns on public.sales;
create trigger sales_sync_compat_columns
before insert or update on public.sales
for each row execute function public.sync_sales_compat_columns();

alter table public.sale_items
add column if not exists product_name_snapshot text,
add column if not exists sku_snapshot text,
add column if not exists cost_price_snapshot numeric(12, 2),
add column if not exists line_total numeric(12, 2),
add column if not exists gross_profit numeric(12, 2) not null default 0,
add column if not exists product_name text,
add column if not exists unit_cost numeric(12, 2) default 0,
add column if not exists subtotal numeric(12, 2);

update public.sale_items
set product_name_snapshot = coalesce(product_name_snapshot, product_name),
    product_name = coalesce(product_name, product_name_snapshot),
    cost_price_snapshot = coalesce(cost_price_snapshot, unit_cost, 0),
    unit_cost = coalesce(unit_cost, cost_price_snapshot, 0),
    line_total = coalesce(line_total, subtotal, unit_price * quantity),
    gross_profit = coalesce(
      gross_profit,
      (unit_price - coalesce(cost_price_snapshot, unit_cost, 0)) * quantity,
      0
    );

alter table public.sale_items
alter column product_name_snapshot set not null,
alter column cost_price_snapshot set not null,
alter column line_total set not null,
alter column gross_profit set not null;

create or replace function public.sync_sale_items_compat_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.product_name_snapshot = coalesce(
    new.product_name_snapshot,
    new.product_name
  );
  new.product_name = coalesce(new.product_name, new.product_name_snapshot);
  new.cost_price_snapshot = coalesce(new.cost_price_snapshot, new.unit_cost, 0);
  new.unit_cost = coalesce(new.unit_cost, new.cost_price_snapshot, 0);
  new.line_total = coalesce(
    new.line_total,
    new.subtotal,
    new.unit_price * new.quantity
  );
  new.gross_profit = coalesce(
    new.gross_profit,
    (new.unit_price - new.cost_price_snapshot) * new.quantity,
    0
  );
  return new;
end;
$$;

drop trigger if exists sale_items_sync_compat_columns on public.sale_items;
create trigger sale_items_sync_compat_columns
before insert or update on public.sale_items
for each row execute function public.sync_sale_items_compat_columns();

alter table public.stock_movements
add column if not exists quantity_delta integer,
add column if not exists reason text,
add column if not exists quantity_change integer,
add column if not exists previous_quantity integer,
add column if not exists new_quantity integer,
add column if not exists note text,
add column if not exists created_by uuid;

update public.stock_movements
set quantity_delta = coalesce(quantity_delta, quantity_change),
    quantity_change = coalesce(quantity_change, quantity_delta),
    reason = coalesce(reason, note),
    note = coalesce(note, reason),
    user_id = coalesce(user_id, created_by),
    created_by = coalesce(created_by, user_id);

alter table public.stock_movements
alter column quantity_delta set not null;

create or replace function public.sync_stock_movements_compat_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  current_stock integer;
begin
  new.quantity_delta = coalesce(new.quantity_delta, new.quantity_change);
  new.quantity_change = coalesce(new.quantity_change, new.quantity_delta);
  new.reason = coalesce(new.reason, new.note);
  new.note = coalesce(new.note, new.reason);
  new.user_id = coalesce(new.user_id, new.created_by, auth.uid());
  new.created_by = coalesce(new.created_by, new.user_id, auth.uid());

  select stock_quantity
  into current_stock
  from public.products
  where id = new.product_id;

  new.new_quantity = coalesce(new.new_quantity, current_stock, 0);
  new.previous_quantity = coalesce(
    new.previous_quantity,
    new.new_quantity - coalesce(new.quantity_delta, 0)
  );

  return new;
end;
$$;

drop trigger if exists stock_movements_sync_compat_columns
on public.stock_movements;
create trigger stock_movements_sync_compat_columns
before insert or update on public.stock_movements
for each row execute function public.sync_stock_movements_compat_columns();

alter table public.expenses
add column if not exists created_by uuid,
add column if not exists updated_at timestamptz not null default now();

update public.expenses
set created_by = b.owner_id
from public.businesses b
where expenses.business_id = b.id
  and expenses.created_by is null;

create or replace function public.sync_expenses_compat_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.created_by = coalesce(new.created_by, auth.uid());
  new.updated_at = coalesce(new.updated_at, now());
  return new;
end;
$$;

drop trigger if exists expenses_sync_compat_columns on public.expenses;
create trigger expenses_sync_compat_columns
before insert or update on public.expenses
for each row execute function public.sync_expenses_compat_columns();
