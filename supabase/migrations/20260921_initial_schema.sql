create table public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    username text not null,
    created_at timestamptz not null default now()
);


create table public.player_progress (
    user_id uuid primary key references auth.users(id) on delete cascade,

    economy integer not null default 50,
    employment integer not null default 50,
    environment integer not null default 50,
    satisfaction integer not null default 50,

    turn integer not null default 1,
    action_points integer not null default 2,

    log_entries jsonb not null default '[]'::jsonb,

    updated_at timestamptz not null default now()
);


alter table public.profiles enable row level security;
alter table public.player_progress enable row level security;


create policy "Users can read their own profile"
on public.profiles
for select
to authenticated
using ((select auth.uid()) = id);


create policy "Users can update their own profile"
on public.profiles
for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);


create policy "Users can read their own progress"
on public.player_progress
for select
to authenticated
using ((select auth.uid()) = user_id);


create policy "Users can insert their own progress"
on public.player_progress
for insert
to authenticated
with check ((select auth.uid()) = user_id);


create policy "Users can update their own progress"
on public.player_progress
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);


create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin

    insert into public.profiles (id, username)
    values (
        new.id,
        coalesce(
            new.raw_user_meta_data->>'username',
            split_part(coalesce(new.email, 'player'), '@', 1)
        )
    );

    insert into public.player_progress (user_id)
    values (new.id);

    return new;

end;
$$;


drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute procedure public.handle_new_user();