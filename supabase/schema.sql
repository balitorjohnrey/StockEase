create extension if not exists pgcrypto;

create table if not exists public.businesses (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(trim(name)) > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.business_members (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'cashier' check (role in ('owner', 'cashier')),
  created_at timestamptz not null default now(),
  unique (business_id, user_id)
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null check (char_length(trim(name)) > 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, name)
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  category_id uuid references public.categories(id) on delete set null,
  name text not null check (char_length(trim(name)) > 0),
  sku text,
  barcode text,
  cost_price numeric(12, 2) not null default 0 check (cost_price >= 0),
  selling_price numeric(12, 2) not null default 0 check (selling_price >= 0),
  stock_quantity integer not null default 0 check (stock_quantity >= 0),
  low_stock_threshold integer not null default 0 check (low_stock_threshold >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, sku),
  unique (business_id, barcode)
);

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  phone text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.sales (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  cashier_id uuid not null references auth.users(id),
  receipt_number text not null unique,
  total_amount numeric(12, 2) not null check (total_amount >= 0),
  cash_received numeric(12, 2) not null check (cash_received >= 0),
  change_amount numeric(12, 2) not null check (change_amount >= 0),
  estimated_gross_profit numeric(12, 2) not null default 0,
  status text not null default 'completed' check (status in ('completed', 'voided')),
  created_at timestamptz not null default now()
);

create table if not exists public.sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name_snapshot text not null,
  sku_snapshot text,
  unit_price numeric(12, 2) not null check (unit_price >= 0),
  cost_price_snapshot numeric(12, 2) not null check (cost_price_snapshot >= 0),
  quantity integer not null check (quantity > 0),
  line_total numeric(12, 2) not null check (line_total >= 0),
  gross_profit numeric(12, 2) not null default 0
);

create table if not exists public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  movement_type text not null check (movement_type in ('sale', 'restock', 'adjustment')),
  quantity_delta integer not null,
  reason text,
  sale_id uuid references public.sales(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  category text not null check (char_length(trim(category)) > 0),
  description text,
  amount numeric(12, 2) not null check (amount >= 0),
  expense_date date not null default (timezone('Asia/Manila', now()))::date,
  created_at timestamptz not null default now()
);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists businesses_touch_updated_at on public.businesses;
create trigger businesses_touch_updated_at
before update on public.businesses
for each row execute function public.touch_updated_at();

drop trigger if exists categories_touch_updated_at on public.categories;
create trigger categories_touch_updated_at
before update on public.categories
for each row execute function public.touch_updated_at();

drop trigger if exists products_touch_updated_at on public.products;
create trigger products_touch_updated_at
before update on public.products
for each row execute function public.touch_updated_at();

create or replace function public.user_has_business_access(target_business_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.businesses b
    where b.id = target_business_id and b.owner_id = auth.uid()
  )
  or exists (
    select 1 from public.business_members bm
    where bm.business_id = target_business_id and bm.user_id = auth.uid()
  );
$$;

alter table public.businesses enable row level security;
alter table public.business_members enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.customers enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
alter table public.stock_movements enable row level security;
alter table public.expenses enable row level security;

drop policy if exists "businesses_select_own" on public.businesses;
create policy "businesses_select_own" on public.businesses
for select using (owner_id = auth.uid() or public.user_has_business_access(id));

drop policy if exists "businesses_insert_own" on public.businesses;
create policy "businesses_insert_own" on public.businesses
for insert with check (owner_id = auth.uid());

drop policy if exists "businesses_update_own" on public.businesses;
create policy "businesses_update_own" on public.businesses
for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());

drop policy if exists "members_access" on public.business_members;
create policy "members_access" on public.business_members
for all using (public.user_has_business_access(business_id))
with check (public.user_has_business_access(business_id));

drop policy if exists "categories_business_access" on public.categories;
create policy "categories_business_access" on public.categories
for all using (public.user_has_business_access(business_id))
with check (public.user_has_business_access(business_id));

drop policy if exists "products_business_access" on public.products;
create policy "products_business_access" on public.products
for all using (public.user_has_business_access(business_id))
with check (public.user_has_business_access(business_id));

drop policy if exists "customers_business_access" on public.customers;
create policy "customers_business_access" on public.customers
for all using (public.user_has_business_access(business_id))
with check (public.user_has_business_access(business_id));

drop policy if exists "sales_business_access" on public.sales;
create policy "sales_business_access" on public.sales
for select using (public.user_has_business_access(business_id));

drop policy if exists "sale_items_business_access" on public.sale_items;
create policy "sale_items_business_access" on public.sale_items
for select using (
  exists (
    select 1 from public.sales s
    where s.id = sale_id and public.user_has_business_access(s.business_id)
  )
);

drop policy if exists "stock_movements_business_access" on public.stock_movements;
create policy "stock_movements_business_access" on public.stock_movements
for select using (public.user_has_business_access(business_id));

drop policy if exists "expenses_business_access" on public.expenses;
create policy "expenses_business_access" on public.expenses
for all using (public.user_has_business_access(business_id))
with check (public.user_has_business_access(business_id));

create or replace function public.create_owner_membership()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.business_members (business_id, user_id, role)
  values (new.id, new.owner_id, 'owner')
  on conflict (business_id, user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists businesses_create_owner_membership on public.businesses;
create trigger businesses_create_owner_membership
after insert on public.businesses
for each row execute function public.create_owner_membership();

create or replace function public.complete_sale(
  p_business_id uuid,
  p_items jsonb,
  p_cash_received numeric
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  cart_line record;
  product_row public.products%rowtype;
  v_sale_id uuid;
  receipt text;
  trusted_total numeric(12, 2) := 0;
  trusted_profit numeric(12, 2) := 0;
  line_total numeric(12, 2);
  line_profit numeric(12, 2);
  receipt_items jsonb;
  business_name text;
begin
  if auth.uid() is null then
    raise exception 'You must be signed in to complete a sale.';
  end if;

  if not public.user_has_business_access(p_business_id) then
    raise exception 'Business access denied.';
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Cart is empty.';
  end if;

  if p_cash_received is null or p_cash_received < 0 then
    raise exception 'Cash received cannot be negative.';
  end if;

  for cart_line in
    select product_id, sum(quantity)::integer as quantity
    from jsonb_to_recordset(p_items) as x(product_id uuid, quantity integer)
    group by product_id
  loop
    if cart_line.product_id is null or cart_line.quantity is null or cart_line.quantity <= 0 then
      raise exception 'Invalid cart item quantity.';
    end if;

    select *
    into product_row
    from public.products
    where id = cart_line.product_id
      and business_id = p_business_id
      and is_active = true
    for update;

    if not found then
      raise exception 'A product in the cart is no longer available.';
    end if;

    if product_row.stock_quantity < cart_line.quantity then
      raise exception 'Insufficient stock. Only % item(s) are available.', product_row.stock_quantity;
    end if;

    line_total := product_row.selling_price * cart_line.quantity;
    line_profit := (product_row.selling_price - product_row.cost_price) * cart_line.quantity;
    trusted_total := trusted_total + line_total;
    trusted_profit := trusted_profit + line_profit;
  end loop;

  if p_cash_received < trusted_total then
    raise exception 'Cash received is less than the total purchase.';
  end if;

  receipt := 'SE-' ||
    to_char(timezone('Asia/Manila', now()), 'YYYYMMDD-HH24MISS') ||
    '-' ||
    upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));

  insert into public.sales (
    business_id,
    cashier_id,
    receipt_number,
    total_amount,
    cash_received,
    change_amount,
    estimated_gross_profit
  )
  values (
    p_business_id,
    auth.uid(),
    receipt,
    trusted_total,
    p_cash_received,
    p_cash_received - trusted_total,
    trusted_profit
  )
  returning id into v_sale_id;

  for cart_line in
    select product_id, sum(quantity)::integer as quantity
    from jsonb_to_recordset(p_items) as x(product_id uuid, quantity integer)
    group by product_id
  loop
    select *
    into product_row
    from public.products
    where id = cart_line.product_id
      and business_id = p_business_id
    for update;

    line_total := product_row.selling_price * cart_line.quantity;
    line_profit := (product_row.selling_price - product_row.cost_price) * cart_line.quantity;

    insert into public.sale_items (
      sale_id,
      product_id,
      product_name_snapshot,
      sku_snapshot,
      unit_price,
      cost_price_snapshot,
      quantity,
      line_total,
      gross_profit
    )
    values (
      v_sale_id,
      product_row.id,
      product_row.name,
      product_row.sku,
      product_row.selling_price,
      product_row.cost_price,
      cart_line.quantity,
      line_total,
      line_profit
    );

    update public.products
    set stock_quantity = stock_quantity - cart_line.quantity
    where id = product_row.id;

    insert into public.stock_movements (
      business_id,
      product_id,
      user_id,
      movement_type,
      quantity_delta,
      reason,
      sale_id
    )
    values (
      p_business_id,
      product_row.id,
      auth.uid(),
      'sale',
      -cart_line.quantity,
      'Sale ' || receipt,
      v_sale_id
    );
  end loop;

  select name into business_name from public.businesses where id = p_business_id;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'product_id', si.product_id,
      'product_name', si.product_name_snapshot,
      'sku', si.sku_snapshot,
      'unit_price', si.unit_price,
      'cost_price', si.cost_price_snapshot,
      'quantity', si.quantity,
      'subtotal', si.line_total
    )
    order by si.product_name_snapshot
  ), '[]'::jsonb)
  into receipt_items
  from public.sale_items si
  where si.sale_id = v_sale_id;

  return jsonb_build_object(
    'sale_id', v_sale_id,
    'business_name', business_name,
    'receipt_number', receipt,
    'date_time', now(),
    'items', receipt_items,
    'total_purchase', trusted_total,
    'cash_received', p_cash_received,
    'change', p_cash_received - trusted_total,
    'estimated_gross_profit', trusted_profit
  );
end;
$$;

create or replace function public.restock_product(
  p_business_id uuid,
  p_product_id uuid,
  p_quantity integer,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  product_row public.products%rowtype;
  new_quantity integer;
begin
  if auth.uid() is null then
    raise exception 'You must be signed in to restock products.';
  end if;

  if not public.user_has_business_access(p_business_id) then
    raise exception 'Business access denied.';
  end if;

  if p_quantity is null or p_quantity <= 0 then
    raise exception 'Restock quantity must be greater than zero.';
  end if;

  select *
  into product_row
  from public.products
  where id = p_product_id and business_id = p_business_id
  for update;

  if not found then
    raise exception 'Product not found.';
  end if;

  update public.products
  set stock_quantity = stock_quantity + p_quantity
  where id = p_product_id
  returning stock_quantity into new_quantity;

  insert into public.stock_movements (
    business_id,
    product_id,
    user_id,
    movement_type,
    quantity_delta,
    reason
  )
  values (
    p_business_id,
    p_product_id,
    auth.uid(),
    'restock',
    p_quantity,
    coalesce(nullif(trim(p_reason), ''), 'Manual restock')
  );

  return jsonb_build_object(
    'product_id', p_product_id,
    'product_name', product_row.name,
    'quantity_added', p_quantity,
    'new_stock', new_quantity
  );
end;
$$;
