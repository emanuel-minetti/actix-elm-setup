CREATE TABLE public.session
(
    id         UUID      DEFAULT gen_random_uuid()                              NOT NULL
        CONSTRAINT session_pk
            PRIMARY KEY,
    account_id UUID                                                             NOT NULL
        CONSTRAINT session_account_id_fk
            REFERENCES public.account,
    expires_at TIMESTAMP DEFAULT current_timestamp + (30 * INTERVAL '1 minute') NOT NULL
);

CREATE INDEX session_expires_at_index
    ON public.session (expires_at);