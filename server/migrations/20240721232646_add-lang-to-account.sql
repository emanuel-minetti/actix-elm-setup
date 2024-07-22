CREATE TYPE lang AS ENUM ('en', 'de');

ALTER TABLE account ADD preferred_language lang DEFAULT 'de' NOT NULL ;
