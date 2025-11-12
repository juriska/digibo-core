create or replace package borates as

type cursor_t is ref cursor;

function load_currency_rates(
	pFilter in varchar2,
	pDAO in number
) return cursor_t;

end;
/

show err;

create or replace package body borates as

function load_currency_rates(
	pFilter in varchar2,
	pDAO in number
) return cursor_t is
	filter varchar2_table_type := bocommon.create_str_table(pFilter);
	rv cursor_t;
	today date;
begin
	select gbd.today into today from glb_business_dates gbd;

	open rv for select
		c.id id,
		c.rate_date rate_date,
		c.rate_timestamp rate_timestamp,
		c.quot_amount rate_quot_amount,
		c.cash_local_buy,
		c.cash_local_sell
	from glb_currency_rates c, (
		select distinct
			sub.id,
			sub.rate_date,
			sub.location,
			max(nvl(sub.officer_id, 0)) dao_id
		from glb_currency_rates sub
		where sub.rate_date = trunc(sysdate) and
			sub.id in (select * from table(cast(filter as varchar2_table_type))) and
			sub.location = 'LV' and
			(nvl(sub.officer_id, 0) = nvl(pDAO, 0) or
				sub.officer_id is null)
		group by sub.id, sub.rate_date, sub.location
	) sub
	where c.rate_date = sub.rate_date and
		c.id = sub.id and
		c.location = sub.location and
		nvl(c.officer_id, 0) = sub.dao_id and
		c.rate_timestamp = (select max(t.rate_timestamp)
			from ibglb.glb_currency_rates t
			where t.id = c.id and
				t.location = c.location and
				nvl(t.officer_id, 0) = nvl(c.officer_id, 0) and
				t.rate_date = c.rate_date);

	return rv;
end;

end;
/

show err;
