-- hot-chain break 1
begin transaction isolation level repeatable read;
select 1;
--3
commit;