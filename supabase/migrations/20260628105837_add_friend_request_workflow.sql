create index if not exists friend_requests_recipient_status_created_idx
on public.friend_requests (recipient_user_id, status, created_at desc);

create index if not exists friend_requests_requester_status_created_idx
on public.friend_requests (requester_user_id, status, created_at desc);

create index if not exists friendships_user_two_id_created_at_idx
on public.friendships (user_two_id, created_at desc);

insert into public.friendships (
  user_one_id,
  user_two_id,
  created_at
)
select
  least(request.requester_user_id, request.recipient_user_id),
  greatest(request.requester_user_id, request.recipient_user_id),
  coalesce(request.responded_at, request.updated_at, request.created_at)
from public.friend_requests request
where request.status = 'accepted'
on conflict (user_one_id, user_two_id) do nothing;

grant select, insert, update on public.friend_requests to service_role;
grant select, insert on public.friendships to service_role;
grant select on public.profiles to service_role;

revoke insert, update, delete on public.friend_requests from authenticated;

create or replace function public.send_friend_request(
  p_requester_user_id uuid,
  p_recipient_user_id uuid
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_locked_profile_count integer;
  v_request public.friend_requests%rowtype;
  v_recipient public.profiles%rowtype;
begin
  if p_requester_user_id is null or p_recipient_user_id is null then
    raise exception using
      errcode = 'P0001',
      message = 'Requester and recipient are required';
  end if;

  if p_requester_user_id = p_recipient_user_id then
    raise exception using
      errcode = 'P0001',
      message = 'You cannot send a friend request to yourself';
  end if;

  select count(*)
  into v_locked_profile_count
  from (
    select profile.id
    from public.profiles profile
    where profile.id in (p_requester_user_id, p_recipient_user_id)
    order by profile.id
    for update
  ) locked_profile;

  if v_locked_profile_count <> 2 then
    raise exception using
      errcode = 'P0001',
      message = 'Recipient profile was not found';
  end if;

  if exists (
    select 1
    from public.friendships friendship
    where friendship.user_one_id = least(
        p_requester_user_id,
        p_recipient_user_id
      )
      and friendship.user_two_id = greatest(
        p_requester_user_id,
        p_recipient_user_id
      )
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'You are already friends with this user';
  end if;

  select *
  into v_request
  from public.friend_requests request
  where request.requester_user_id = p_requester_user_id
    and request.recipient_user_id = p_recipient_user_id
    and request.status = 'pending';

  if found then
    select *
    into v_recipient
    from public.profiles
    where id = p_recipient_user_id;

    return jsonb_build_object(
      'request', to_jsonb(v_request),
      'recipient', jsonb_build_object(
        'id', v_recipient.id,
        'username', v_recipient.username,
        'display_name', v_recipient.display_name,
        'avatar_url', v_recipient.avatar_url
      ),
      'idempotent_replay', true
    );
  end if;

  if exists (
    select 1
    from public.friend_requests request
    where request.requester_user_id = p_recipient_user_id
      and request.recipient_user_id = p_requester_user_id
      and request.status = 'pending'
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'This user already sent you a pending friend request';
  end if;

  insert into public.friend_requests (
    requester_user_id,
    recipient_user_id,
    status
  )
  values (
    p_requester_user_id,
    p_recipient_user_id,
    'pending'
  )
  returning *
  into v_request;

  select *
  into v_recipient
  from public.profiles
  where id = p_recipient_user_id;

  return jsonb_build_object(
    'request', to_jsonb(v_request),
    'recipient', jsonb_build_object(
      'id', v_recipient.id,
      'username', v_recipient.username,
      'display_name', v_recipient.display_name,
      'avatar_url', v_recipient.avatar_url
    ),
    'idempotent_replay', false
  );
end;
$$;

create or replace function public.respond_to_friend_request(
  p_user_id uuid,
  p_request_id uuid,
  p_action text
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_action text := lower(trim(p_action));
  v_request public.friend_requests%rowtype;
  v_friendship public.friendships%rowtype;
  v_requester public.profiles%rowtype;
  v_idempotent_replay boolean := false;
begin
  if v_action not in ('accepted', 'rejected') then
    raise exception using
      errcode = 'P0001',
      message = 'Action must be accepted or rejected';
  end if;

  select *
  into v_request
  from public.friend_requests request
  where request.id = p_request_id
    and request.recipient_user_id = p_user_id
  for update;

  if not found then
    raise exception using
      errcode = 'P0001',
      message = 'Friend request was not found';
  end if;

  if v_request.status <> 'pending' then
    if v_request.status <> v_action then
      raise exception using
        errcode = 'P0001',
        message = format(
          'Friend request was already %s',
          v_request.status
        );
    end if;

    v_idempotent_replay = true;
  else
    update public.friend_requests
    set
      status = v_action,
      responded_at = timezone('utc', now())
    where id = v_request.id
    returning *
    into v_request;
  end if;

  if v_action = 'accepted' then
    insert into public.friendships (
      user_one_id,
      user_two_id
    )
    values (
      least(v_request.requester_user_id, v_request.recipient_user_id),
      greatest(v_request.requester_user_id, v_request.recipient_user_id)
    )
    on conflict (user_one_id, user_two_id) do nothing;

    select *
    into v_friendship
    from public.friendships friendship
    where friendship.user_one_id = least(
        v_request.requester_user_id,
        v_request.recipient_user_id
      )
      and friendship.user_two_id = greatest(
        v_request.requester_user_id,
        v_request.recipient_user_id
      );
  end if;

  select *
  into v_requester
  from public.profiles
  where id = v_request.requester_user_id;

  return jsonb_build_object(
    'request', to_jsonb(v_request),
    'friendship', case
      when v_action = 'accepted' then to_jsonb(v_friendship)
      else null
    end,
    'requester', jsonb_build_object(
      'id', v_requester.id,
      'username', v_requester.username,
      'display_name', v_requester.display_name,
      'avatar_url', v_requester.avatar_url
    ),
    'idempotent_replay', v_idempotent_replay
  );
end;
$$;

revoke all on function public.send_friend_request(
  uuid,
  uuid
) from public, anon, authenticated;

grant execute on function public.send_friend_request(
  uuid,
  uuid
) to service_role;

revoke all on function public.respond_to_friend_request(
  uuid,
  uuid,
  text
) from public, anon, authenticated;

grant execute on function public.respond_to_friend_request(
  uuid,
  uuid,
  text
) to service_role;
