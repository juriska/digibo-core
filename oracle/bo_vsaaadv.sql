/*
* plugin vsaareq2.
*/

create or replace package BOVsaaAdv as

type cursor_t is ref cursor;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,

	-- system
	docId in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t;

procedure adv(
	pId in varchar2,
	officerName out varchar2,
	createSentDate out date,
	closeSentDate out date
);

end;
/

show err;

create or replace package body BOVsaaAdv as

function find_by_id(
	docId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		/* BOVsaaAdv.find_by_id */
		p.id id,
		p.legal_id personal_id,
		p.status_id status_id,
		p.create_date create_date,
		p.close_date close_date,
		nvl(trim(decode(bocommon.LanguageId,
			0, c.name.name_lv,
			1, c.name.name_en,
			2, c.name.name_ru,
			3, c.name.extra_1,
			4, c.name.extra_2,
			5, c.name.extra_3,
			c.name.name_en
		)), c.name.name_en) || ' (' || c.id || ')' customer
	from ibglb.pension_contracts p, ibglb.cusd c
	where p.id = docId and c.id = p.cusd_id;
	return rv;
end;

function find_by_filter(
	custId in varchar2,
	custName in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t is
	rv cursor_t;
	t_statuses num_table_type := bocommon.str2table(statuses);
begin
	open rv for select
		/* BOVsaaAdv.find_by_filter */
		p.id id,
		p.legal_id personal_id,
		p.status_id status_id,
		p.create_date create_date,
		p.close_date close_date,
		nvl(trim(decode(bocommon.LanguageId,
			0, c.name.name_lv,
			1, c.name.name_en,
			2, c.name.name_ru,
			3, c.name.extra_1,
			4, c.name.extra_2,
			5, c.name.extra_3,
			c.name.name_en
		)), c.name.name_en) || ' (' || c.id || ')' customer
	from ibglb.pension_contracts p, ibglb.cusd c
	where rownum <= bocommon.ResultSetSize and
		p.create_date between createdFrom and createdTill and
		p.status_id in (select * from table(cast(t_statuses as num_table_type))) and
		(custId is null or p.cusd_id = custId) and
		c.id = p.cusd_id and
		(custName is null or c.name.is_like(bocommon.prepare_like(custName)) = 1);
	return rv;
end;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,

	-- system
	docId in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t is
begin
	if docId is not null then
		return find_by_id(docId);
	end if;
	return find_by_filter(
		custId,
		custName,
		statuses,
		createdFrom,
		createdTill
	);
end;

procedure adv(
	pId in varchar2,
	officerName out varchar2,
	createSentDate out date,
	closeSentDate out date
) is
begin
	select /* BOVsaaAdv.adv */
		o.officer_name,
		p.create_sent_date,
		p.close_sent_date
	into
		officerName,
		createSentDate,
		closeSentDate
	from ibglb.pension_contracts p, ibglb.cusd c, ibglb.glb_dept_accnt_officer o
	where p.id = pId and
		c.id = p.cusd_id and
		o.id(+) = c.remote_officers.company_1;
end;

end;
/

show err;
