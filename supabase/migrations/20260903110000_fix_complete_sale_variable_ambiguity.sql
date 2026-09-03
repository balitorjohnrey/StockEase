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

  if p_items is null or jsonb_typeof(p_items) <> 'array'
    or jsonb_array_length(p_items) = 0 then
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
    if cart_line.product_id is null
      or cart_line.quantity is null
      or cart_line.quantity <= 0 then
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
      raise exception 'Insufficient stock. Only % item(s) are available.',
        product_row.stock_quantity;
    end if;

    line_total := product_row.selling_price * cart_line.quantity;
    line_profit :=
      (product_row.selling_price - product_row.cost_price) * cart_line.quantity;
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
    line_profit :=
      (product_row.selling_price - product_row.cost_price) * cart_line.quantity;

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

  select name
  into business_name
  from public.businesses
  where id = p_business_id;

  select coalesce(
    jsonb_agg(
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
    ),
    '[]'::jsonb
  )
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
