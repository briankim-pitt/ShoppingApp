create schema if not exists private;

create extension if not exists pgcrypto with schema extensions;

create or replace function private.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create or replace function private.normalize_friendship_pair()
returns trigger
language plpgsql
as $$
declare
  smallest uuid;
  largest uuid;
begin
  if new.user_one_id = new.user_two_id then
    raise exception 'friendship users must be different';
  end if;

  smallest = least(new.user_one_id, new.user_two_id);
  largest = greatest(new.user_one_id, new.user_two_id);

  new.user_one_id = smallest;
  new.user_two_id = largest;
  return new;
end;
$$;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique,
  display_name text not null,
  avatar_url text,
  bio text,
  budget_points integer not null default 1000 check (budget_points >= 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (char_length(username) between 3 and 24),
  check (username ~ '^[a-z0-9_]+$'),
  check (char_length(display_name) between 1 and 50)
);

create table public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  requester_user_id uuid not null references public.profiles (id) on delete cascade,
  recipient_user_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'rejected')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  responded_at timestamptz,
  check (requester_user_id <> recipient_user_id)
);

create unique index friend_requests_pending_unique
on public.friend_requests (
  least(requester_user_id, recipient_user_id),
  greatest(requester_user_id, recipient_user_id)
)
where status = 'pending';

create table public.friendships (
  id uuid primary key default gen_random_uuid(),
  user_one_id uuid not null references public.profiles (id) on delete cascade,
  user_two_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  check (user_one_id <> user_two_id),
  unique (user_one_id, user_two_id)
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  canonical_url text not null unique,
  source_domain text not null,
  title text not null,
  description text,
  image_url text,
  currency_code text,
  price_amount numeric(12,2),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  last_imported_at timestamptz not null default timezone('utc', now())
);

create index products_source_domain_idx on public.products (source_domain);

create table public.product_imports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  source_url text not null,
  canonical_url text not null,
  source_domain text not null,
  product_id uuid references public.products (id) on delete set null,
  status text not null default 'succeeded' check (status in ('pending', 'succeeded', 'failed')),
  error_message text,
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create index product_imports_user_id_created_at_idx
on public.product_imports (user_id, created_at desc);

create table public.wishlists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  description text,
  visibility text not null default 'private' check (visibility in ('private', 'friends', 'public')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index wishlists_user_id_idx on public.wishlists (user_id);

create table public.wishlist_items (
  id uuid primary key default gen_random_uuid(),
  wishlist_id uuid not null references public.wishlists (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  note text,
  target_price_amount numeric(12,2),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (wishlist_id, product_id)
);

create index wishlist_items_wishlist_id_idx on public.wishlist_items (wishlist_id);

create table public.virtual_orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  wishlist_id uuid references public.wishlists (id) on delete set null,
  status text not null default 'created' check (status in ('created', 'processing', 'shipped', 'delivered', 'cancelled')),
  total_amount numeric(12,2) not null default 0,
  currency_code text,
  placed_at timestamptz,
  shipped_at timestamptz,
  delivered_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index virtual_orders_user_id_created_at_idx
on public.virtual_orders (user_id, created_at desc);

create table public.virtual_order_items (
  id uuid primary key default gen_random_uuid(),
  virtual_order_id uuid not null references public.virtual_orders (id) on delete cascade,
  product_id uuid references public.products (id) on delete set null,
  title_snapshot text not null,
  image_url_snapshot text,
  currency_code text,
  unit_price_amount numeric(12,2) not null default 0,
  quantity integer not null default 1 check (quantity > 0),
  created_at timestamptz not null default timezone('utc', now())
);

create index virtual_order_items_virtual_order_id_idx
on public.virtual_order_items (virtual_order_id);

create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function private.set_updated_at();

create trigger friend_requests_set_updated_at
before update on public.friend_requests
for each row
execute function private.set_updated_at();

create trigger products_set_updated_at
before update on public.products
for each row
execute function private.set_updated_at();

create trigger wishlists_set_updated_at
before update on public.wishlists
for each row
execute function private.set_updated_at();

create trigger wishlist_items_set_updated_at
before update on public.wishlist_items
for each row
execute function private.set_updated_at();

create trigger virtual_orders_set_updated_at
before update on public.virtual_orders
for each row
execute function private.set_updated_at();

create trigger friendships_normalize_pair
before insert or update on public.friendships
for each row
execute function private.normalize_friendship_pair();

alter table public.profiles enable row level security;
alter table public.friend_requests enable row level security;
alter table public.friendships enable row level security;
alter table public.products enable row level security;
alter table public.product_imports enable row level security;
alter table public.wishlists enable row level security;
alter table public.wishlist_items enable row level security;
alter table public.virtual_orders enable row level security;
alter table public.virtual_order_items enable row level security;

create policy "profiles are visible to signed in users"
on public.profiles
for select
to authenticated
using (true);

create policy "users can insert their own profile"
on public.profiles
for insert
to authenticated
with check ((select auth.uid()) = id);

create policy "users can update their own profile"
on public.profiles
for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

create policy "participants can view friend requests"
on public.friend_requests
for select
to authenticated
using (
  (select auth.uid()) = requester_user_id
  or (select auth.uid()) = recipient_user_id
);

create policy "users can create outgoing friend requests"
on public.friend_requests
for insert
to authenticated
with check (
  (select auth.uid()) = requester_user_id
  and requester_user_id <> recipient_user_id
  and status = 'pending'
);

create policy "recipients can update incoming friend requests"
on public.friend_requests
for update
to authenticated
using ((select auth.uid()) = recipient_user_id)
with check (
  (select auth.uid()) = recipient_user_id
  and status in ('accepted', 'rejected')
);

create policy "participants can delete friend requests"
on public.friend_requests
for delete
to authenticated
using (
  (select auth.uid()) = requester_user_id
  or (select auth.uid()) = recipient_user_id
);

create policy "participants can view friendships"
on public.friendships
for select
to authenticated
using (
  (select auth.uid()) = user_one_id
  or (select auth.uid()) = user_two_id
);

create policy "signed in users can browse imported products"
on public.products
for select
to authenticated
using (true);

create policy "users can view their own product imports"
on public.product_imports
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "users can view allowed wishlists"
on public.wishlists
for select
to authenticated
using (
  (select auth.uid()) = user_id
  or visibility = 'public'
  or (
    visibility = 'friends'
    and exists (
      select 1
      from public.friendships f
      where (
        f.user_one_id = least(user_id, (select auth.uid()))
        and f.user_two_id = greatest(user_id, (select auth.uid()))
      )
    )
  )
);

create policy "users can create their own wishlists"
on public.wishlists
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "users can update their own wishlists"
on public.wishlists
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "users can delete their own wishlists"
on public.wishlists
for delete
to authenticated
using ((select auth.uid()) = user_id);

create policy "users can view wishlist items from visible wishlists"
on public.wishlist_items
for select
to authenticated
using (
  exists (
    select 1
    from public.wishlists w
    where w.id = wishlist_id
      and (
        (select auth.uid()) = w.user_id
        or w.visibility = 'public'
        or (
          w.visibility = 'friends'
          and exists (
            select 1
            from public.friendships f
            where (
              f.user_one_id = least(w.user_id, (select auth.uid()))
              and f.user_two_id = greatest(w.user_id, (select auth.uid()))
            )
          )
        )
      )
  )
);

create policy "users can add items to their own wishlists"
on public.wishlist_items
for insert
to authenticated
with check (
  exists (
    select 1
    from public.wishlists w
    where w.id = wishlist_id
      and w.user_id = (select auth.uid())
  )
);

create policy "users can update items in their own wishlists"
on public.wishlist_items
for update
to authenticated
using (
  exists (
    select 1
    from public.wishlists w
    where w.id = wishlist_id
      and w.user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1
    from public.wishlists w
    where w.id = wishlist_id
      and w.user_id = (select auth.uid())
  )
);

create policy "users can delete items from their own wishlists"
on public.wishlist_items
for delete
to authenticated
using (
  exists (
    select 1
    from public.wishlists w
    where w.id = wishlist_id
      and w.user_id = (select auth.uid())
  )
);

create policy "users can view their own virtual orders"
on public.virtual_orders
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "users can create their own virtual orders"
on public.virtual_orders
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "users can update their own virtual orders"
on public.virtual_orders
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "users can delete their own virtual orders"
on public.virtual_orders
for delete
to authenticated
using ((select auth.uid()) = user_id);

create policy "users can view their own virtual order items"
on public.virtual_order_items
for select
to authenticated
using (
  exists (
    select 1
    from public.virtual_orders vo
    where vo.id = virtual_order_id
      and vo.user_id = (select auth.uid())
  )
);

create policy "users can create their own virtual order items"
on public.virtual_order_items
for insert
to authenticated
with check (
  exists (
    select 1
    from public.virtual_orders vo
    where vo.id = virtual_order_id
      and vo.user_id = (select auth.uid())
  )
);

create policy "users can update their own virtual order items"
on public.virtual_order_items
for update
to authenticated
using (
  exists (
    select 1
    from public.virtual_orders vo
    where vo.id = virtual_order_id
      and vo.user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1
    from public.virtual_orders vo
    where vo.id = virtual_order_id
      and vo.user_id = (select auth.uid())
  )
);

create policy "users can delete their own virtual order items"
on public.virtual_order_items
for delete
to authenticated
using (
  exists (
    select 1
    from public.virtual_orders vo
    where vo.id = virtual_order_id
      and vo.user_id = (select auth.uid())
  )
);

grant usage on schema public to authenticated;

grant select, insert, update on public.profiles to authenticated;
grant select, insert, update, delete on public.friend_requests to authenticated;
grant select on public.friendships to authenticated;
grant select on public.products to authenticated;
grant select on public.product_imports to authenticated;
grant select, insert, update, delete on public.wishlists to authenticated;
grant select, insert, update, delete on public.wishlist_items to authenticated;
grant select, insert, update, delete on public.virtual_orders to authenticated;
grant select, insert, update, delete on public.virtual_order_items to authenticated;

revoke all on schema private from public;

create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  base_username text;
  final_username text;
begin
  base_username = lower(
    regexp_replace(
      coalesce(
        nullif(new.raw_user_meta_data ->> 'preferred_username', ''),
        nullif(new.raw_user_meta_data ->> 'user_name', ''),
        nullif(new.raw_user_meta_data ->> 'username', ''),
        nullif(split_part(new.email, '@', 1), ''),
        'user'
      ),
      '[^a-zA-Z0-9_]+',
      '',
      'g'
    )
  );

  if char_length(base_username) < 3 then
    base_username = 'user';
  end if;

  base_username = left(base_username, 18);
  final_username = base_username || '_' || right(replace(new.id::text, '-', ''), 5);

  insert into public.profiles (id, username, display_name, avatar_url)
  values (
    new.id,
    final_username,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', ''),
      initcap(base_username)
    ),
    nullif(new.raw_user_meta_data ->> 'avatar_url', '')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

revoke all on function private.handle_new_user() from public;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function private.handle_new_user();
