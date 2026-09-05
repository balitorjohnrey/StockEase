create sequence if not exists public.product_sku_sequence;
create sequence if not exists public.product_barcode_sequence;

create or replace function public.product_ean13_check_digit(p_body text)
returns text
language plpgsql
immutable
as $$
declare
  digit_sum integer := 0;
  i integer;
  digit integer;
begin
  if p_body !~ '^[0-9]{12}$' then
    raise exception 'EAN-13 body must contain exactly 12 digits.';
  end if;

  for i in 1..12 loop
    digit := substring(p_body from i for 1)::integer;

    if mod(i, 2) = 0 then
      digit_sum := digit_sum + (digit * 3);
    else
      digit_sum := digit_sum + digit;
    end if;
  end loop;

  return mod(10 - mod(digit_sum, 10), 10)::text;
end;
$$;

create or replace function public.generate_unique_product_sku(p_business_id uuid)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  generated_sku text;
begin
  loop
    generated_sku :=
      'STK-' || lpad(nextval('public.product_sku_sequence')::text, 8, '0');

    exit when not exists (
      select 1
      from public.products
      where business_id = p_business_id
        and sku = generated_sku
    );
  end loop;

  return generated_sku;
end;
$$;

create or replace function public.generate_unique_product_barcode(
  p_business_id uuid
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  barcode_body text;
  generated_barcode text;
begin
  loop
    barcode_body :=
      '2' || lpad(nextval('public.product_barcode_sequence')::text, 11, '0');
    generated_barcode :=
      barcode_body || public.product_ean13_check_digit(barcode_body);

    exit when not exists (
      select 1
      from public.products
      where business_id = p_business_id
        and barcode = generated_barcode
    );
  end loop;

  return generated_barcode;
end;
$$;

create or replace function public.fill_product_identifiers()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  new.sku := nullif(btrim(new.sku), '');
  new.barcode := nullif(btrim(new.barcode), '');

  if new.sku is null then
    new.sku := public.generate_unique_product_sku(new.business_id);
  end if;

  if new.barcode is null then
    new.barcode := public.generate_unique_product_barcode(new.business_id);
  end if;

  return new;
end;
$$;

drop trigger if exists products_fill_identifiers on public.products;
create trigger products_fill_identifiers
before insert or update on public.products
for each row
execute function public.fill_product_identifiers();

update public.products
set sku = public.generate_unique_product_sku(business_id)
where nullif(btrim(sku), '') is null;

update public.products
set barcode = public.generate_unique_product_barcode(business_id)
where nullif(btrim(barcode), '') is null;

alter table public.products
  alter column sku set not null,
  alter column barcode set not null;

alter table public.products
  drop constraint if exists products_sku_not_blank,
  add constraint products_sku_not_blank check (char_length(btrim(sku)) > 0),
  drop constraint if exists products_barcode_not_blank,
  add constraint products_barcode_not_blank
    check (char_length(btrim(barcode)) > 0);
