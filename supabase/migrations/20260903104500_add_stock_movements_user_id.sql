alter table public.stock_movements
add column if not exists user_id uuid;

update public.stock_movements sm
set user_id = b.owner_id
from public.businesses b
where sm.business_id = b.id
  and sm.user_id is null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'stock_movements_user_id_fkey'
      and conrelid = 'public.stock_movements'::regclass
  ) then
    alter table public.stock_movements
    add constraint stock_movements_user_id_fkey
    foreign key (user_id) references auth.users(id);
  end if;
end $$;

alter table public.stock_movements
alter column user_id set not null;
