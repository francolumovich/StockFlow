--liquibase formatted sql

--changeset franco:create-organization
create table public.organization
(
                       id uuid primary key not null,
                       name varchar(120) not null CONSTRAINT min_length_name CHECK ( btrim(name) != '' AND char_length(btrim(name)) > 1),
                       active boolean default true not null
);
--rollback drop table public.organization;

