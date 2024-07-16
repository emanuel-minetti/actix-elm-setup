create table public.account
(
    id           uuid default gen_random_uuid() not null
        constraint account_pk
            primary key,
    account_name varchar(20)                    not null,
    pw_hash      varchar(72)                    not null,
    name         varchar(80)                    not null
);

create unique index account_account_name_uindex
    on public.account (account_name);

create table public.session
(
    id   uuid default gen_random_uuid() not null
        constraint session_pk
            primary key,
    name varchar(80)                    not null
);
