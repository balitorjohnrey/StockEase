create or replace function public.prevent_multiple_business_profiles()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform pg_advisory_xact_lock(hashtextextended(new.owner_id::text, 0));

  if exists (
    select 1
    from public.businesses
    where owner_id = new.owner_id
      and id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
  ) then
    raise exception 'Each user can only have one business profile.'
      using errcode = '23505';
  end if;

  return new;
end;
$$;

drop trigger if exists businesses_prevent_multiple_profiles
  on public.businesses;
create trigger businesses_prevent_multiple_profiles
before insert or update of owner_id on public.businesses
for each row execute function public.prevent_multiple_business_profiles();

do $$
begin
  if not exists (
    select 1
    from public.businesses
    group by owner_id
    having count(*) > 1
  ) and not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.businesses'::regclass
      and conname = 'businesses_one_profile_per_owner'
  ) then
    alter table public.businesses
      add constraint businesses_one_profile_per_owner unique (owner_id);
  end if;
end;
$$;

create or replace function public.user_has_business_access(
  target_business_id uuid
)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.businesses b
    where b.id = target_business_id
      and b.owner_id = auth.uid()
  );
$$;

drop policy if exists "members_access" on public.business_members;
drop policy if exists "business_members_owner_read"
  on public.business_members;
create policy "business_members_owner_read" on public.business_members
for select using (public.user_has_business_access(business_id));

drop policy if exists "business_members_owner_self_insert"
  on public.business_members;
create policy "business_members_owner_self_insert" on public.business_members
for insert with check (
  user_id = auth.uid()
  and exists (
    select 1
    from public.businesses b
    where b.id = business_id
      and b.owner_id = auth.uid()
  )
);
