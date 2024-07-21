CREATE TABLE public.account
(
    id           uuid default gen_random_uuid() NOT NULL
        CONSTRAINT account_pk
            PRIMARY KEY,
    account_name varchar(20)                    NOT NULL,
    pw_hash      varchar(72)                    NOT NULL,
    name         varchar(80)                    NOT NULL
);

CREATE UNIQUE INDEX account_account_name_uindex
    ON public.account (account_name);
