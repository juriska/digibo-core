/*
* plugin vsaareq1.
*/

create or replace package BOVsaaAdvApp as

type cursor_t is ref cursor;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,
	userLogin in varchar2,

	-- document
	docClass in varchar2,
	pLegalId in varchar2,

	-- system
	docId in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t;

procedure advapp(
	pId in varchar2,
	userName out varchar2,
	userId out varchar2,
	officerName out varchar2,
	docNo out varchar2,
	custName out varchar2
);

end;
/

show err;

create or replace package body BOVsaaAdvApp as

function find_by_id(
	docId in varchar2,
	docClass in varchar2
) return cursor_t is
	rv cursor_t;
	t_classes num_table_type := bocommon.str2table(docClass);
begin
	open rv for select
		/* BOVsaaAdvApp.find_by_id */
		p.id pId,
		p.class_id class,
		p.status_id status,
		p.order_date created,
		w.login login
	from documents p, ways_of_connection w
	where p.id = docId and
		p.class_id in (select * from table(cast(t_classes as num_table_type))) and
		w.id = p.creator_woc_id;
	return rv;
end;

function execute_by_filter(
	pCursorName in integer
) return cursor_t is
	cursor_name integer := pCursorName;
	rv cursor_t;
	row vsaaadvapp_t;
	rows_processed integer;
	rowset vsaaadvapp_set_t := vsaaadvapp_set_t();
	pId number(14);
	class number(3);
	status number(2);
	created date;
	login varchar2(60);
begin
	dbms_sql.define_column(cursor_name,  1, pId);
	dbms_sql.define_column(cursor_name,  2, class);
	dbms_sql.define_column(cursor_name,  3, status);
	dbms_sql.define_column(cursor_name,  4, created);
	dbms_sql.define_column(cursor_name,  5, login, 60);

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name,  1, pId);
		dbms_sql.column_value(cursor_name,  2, class);
		dbms_sql.column_value(cursor_name,  3, status);
		dbms_sql.column_value(cursor_name,  4, created);
		dbms_sql.column_value(cursor_name,  5, login);
		row := vsaaadvapp_t(
			pId,
			class,
			status,
			created,
			login
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as vsaaadvapp_set_t));
	return rv;

exception when others then
	if dbms_sql.is_open(cursor_name) then
		dbms_sql.close_cursor(cursor_name);
	end if;
	raise;
end;

function find_by_filter(
	custId in varchar2,
	pCustName in varchar2,
	pUserLogin in varchar2,
	docClass in varchar2,
	pLegalId in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t is
	rq varchar2(32767);
	cursor_name integer;
	custName varchar2(1024) := bocommon.prepare_like(pCustName);
	userLogin varchar2(1024) := bocommon.prepare_like(pUserLogin);
begin
	if custName is not null then
		delete from tmp_request_data;
		insert into tmp_request_data (requested_id)
		select distinct c.id from ibglb.cusd c
		where custName is null or c.name.is_like(custName) = 1;
	end if;

	rq := rq || 'select /* BOVsaaAdvApp.find_by_filter */';
--	if custId is not null or custName is not null then
--		rq := rq || ' /*+ INDEX (p IDX_DOC_CUST_ID_DATE) */';
--	elsif userLogin is not null then
--		rq := rq || ' /*+ INDEX (p IDX_DOC_WOC_ID_DATE) */';
--	end if;
	rq := rq || ' p.id pId,';
	rq := rq || ' p.class_id class,';
	rq := rq || ' p.status_id status,';
	rq := rq || ' p.order_date created,';
	rq := rq || ' (select login from ways_of_connection where id = p.creator_woc_id) login';
	rq := rq || ' from documents p';
	rq := rq || ' where rownum <= :ResultSetSize';
	rq := rq || ' and p.order_date between :DateFrom and :DateTill';
	rq := rq || ' and p.class_id in (' || docClass || ')';
	rq := rq || ' and p.status_id in (' || statuses || ')';
	if pLegalId is not null then
		rq := rq || ' and upper(p.abonent_legal_id) like :LegalID';
	end if;
	if custId is not null then
		rq := rq || ' and p.from_customer = :CustomerId';
	end if;
	if userLogin is not null then
		rq := rq || ' and p.creator_woc_id in (';
		rq := rq || ' select /*+ INDEX (w1 IDX_WOC_LOGIN) */ w1.id id';
		rq := rq || ' from ways_of_connection w1';
		rq := rq || ' where upper(w1.login) like :UserLogin';
		rq := rq || ' )';
	end if;
	if custName is not null then
		rq := rq || ' and p.from_customer in (select requested_id from tmp_request_data)';
	end if;

	cursor_name := dbms_sql.open_cursor;

	dbms_sql.parse(cursor_name, rq, dbms_sql.native);
	dbms_sql.bind_variable(cursor_name, ':ResultSetSize', bocommon.ResultSetSize);
	dbms_sql.bind_variable(cursor_name, ':DateFrom', createdFrom);
	dbms_sql.bind_variable(cursor_name, ':DateTill', createdTill);
	if pLegalId is not null then
		dbms_sql.bind_variable(cursor_name, ':LegalID', bocommon.prepare_like(pLegalId));
	end if;
	if custId is not null then
		dbms_sql.bind_variable(cursor_name, ':CustomerId', custId);
	end if;
	if userLogin is not null then
		dbms_sql.bind_variable(cursor_name, ':UserLogin', userLogin);
	end if;

	return execute_by_filter(cursor_name);
end;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,
	userLogin in varchar2,

	-- document
	docClass in varchar2,
	pLegalId in varchar2,

	-- system
	docId in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t is
begin
	if docId is not null then
		return find_by_id(docId, docClass);
	end if;
	return find_by_filter(
		custId,
		custName,
		userLogin,
		docClass,
		pLegalId,
		statuses,
		createdFrom,
		createdTill
	);
end;

procedure advapp(
	pId in varchar2,
	userName out varchar2,
	userId out varchar2,
	officerName out varchar2,
	docNo out varchar2,
	custName out varchar2
) is
begin
	select /* BOVsaaAdvApp.advapp */
		u.name || ' (' || w.login || ')',
		d.abonent_legal_id,
		o.officer_name,
		d.document_number,
		nvl(trim(decode(bocommon.LanguageId,
			0, c.name.name_lv,
			1, c.name.name_en,
			2, c.name.name_ru,
			3, c.name.extra_1,
			4, c.name.extra_2,
			5, c.name.extra_3,
			c.name.name_en
		)), c.name.name_en) || ' (' || c.id || ')'
	into
		userName,
		userId,
		officerName,
		docNo,
		custName
	from documents d, v$users u, cusd c, ways_of_connection w,
		ibglb.glb_dept_accnt_officer o
	where d.id = pId and
		c.id(+) = d.from_customer and
		u.id = d.creator_user_id and
		o.id(+) = c.remote_officers.company_1 and
		w.id(+) = d.creator_woc_id;
end;

end;
/

show err;
