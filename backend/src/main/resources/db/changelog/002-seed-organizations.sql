--liquibase formatted sql

--changeset franco:seed-organization
insert into public.organization (id, name, active) values ('10000000-0000-4000-8000-000000000001', 'Distribuidora Norte', true);
insert into public.organization (id, name, active) values ('10000000-0000-4000-8000-000000000002', 'Distribuidora Sur', true);