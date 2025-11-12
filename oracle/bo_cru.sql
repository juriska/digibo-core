/*
* Confirmation of risks undertaken.
*/

create or replace package BOCRU as

type cursor_t is ref cursor;

function find(
	custId in varchar2,
	docId in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t;

procedure cru(
	pId in varchar2,
	pDocNo out varchar2,
	userName out varchar2,
	userId out varchar2,
	custName out varchar2,
	globusNo out varchar2,
	pLocation out varchar2,
	--
	itc out varchar2,
	itb out varchar2,
	signTime out date,
	signDevType out integer,
	signDevId out varchar2,
	signKey1 out varchar2,
	signKey2 out varchar2
);

end;
/

show err;

create or replace package body BOCRU as

function find_by_id(
	docId in varchar2,
	docClass in varchar2
) return cursor_t is
	rv cursor_t;
	t_classes num_table_type := bocommon.str2table(docClass);
begin
	open rv for select
		/* BOCRU.find_by_id */
		p.id document_id,
		p.from_customer customer_id,
		(select nvl(trim(decode(bocommon.LanguageId,
			0, c.name.name_lv,
			1, c.name.name_en,
			2, c.name.name_ru,
			3, c.name.extra_1,
			4, c.name.extra_2,
			5, c.name.extra_3,
			c.name.name_en)), c.name.name_en)
		from cusd c
		where id = p.from_customer) customer_name,
		(select name from v$users where id = p.creator_user_id) user_name,
		p.status_id status,
		p.order_date created
	from documents p
	where p.id = docId and
		p.class_id in (select * from table(cast(t_classes as num_table_type)));
	return rv;
end;

function execute_by_filter(
	pCursorName in integer
) return cursor_t is
	cursor_name integer := pCursorName;
	rv cursor_t;
	row cru_t;
	rows_processed integer;
	rowset cru_set_t := cru_set_t();
	document_id number(14);
	customer_id number(10);
	customer_name varchar2(200);
	user_name varchar2(210);
	status number(2);
	created date;
begin
	dbms_sql.define_column(cursor_name, 1, document_id);
	dbms_sql.define_column(cursor_name, 2, customer_id);
	dbms_sql.define_column(cursor_name, 3, customer_name, 200);
	dbms_sql.define_column(cursor_name, 4, user_name, 210);
	dbms_sql.define_column(cursor_name, 5, status);
	dbms_sql.define_column(cursor_name, 6, created);

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name, 1, document_id);
		dbms_sql.column_value(cursor_name, 2, customer_id);
		dbms_sql.column_value(cursor_name, 3, customer_name);
		dbms_sql.column_value(cursor_name, 4, user_name);
		dbms_sql.column_value(cursor_name, 5, status);
		dbms_sql.column_value(cursor_name, 6, created);
		row := cru_t(
			document_id,
			customer_id,
			customer_name,
			user_name,
			status,
			created
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as cru_set_t));
	return rv;

exception when others then
	if dbms_sql.is_open(cursor_name) then
		dbms_sql.close_cursor(cursor_name);
	end if;
	raise;
end;

function find_by_filter(
	docClass in varchar2,
	custId in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t is
	rq varchar2(32767);
	cursor_name integer;
begin
	rq := rq || 'select /* BOCRU.find_by_filter */';
--	if custId is not null then
--		rq := rq || ' /*+ INDEX (p IDX_DOC_CUST_ID_DATE) */';
--	end if;
	rq := rq || ' p.id document_id,';
	rq := rq || ' p.from_customer customer_id,';
	rq := rq || ' (select nvl(trim(decode(:LanguageID,';
	rq := rq || '     0, c.name.name_lv,';
	rq := rq || '     1, c.name.name_en,';
	rq := rq || '     2, c.name.name_ru,';
	rq := rq || '     3, c.name.extra_1,';
	rq := rq || '     4, c.name.extra_2,';
	rq := rq || '     5, c.name.extra_3,';
	rq := rq || '     c.name.name_en)), c.name.name_en)';
	rq := rq || ' from cusd c';
	rq := rq || ' where id = p.from_customer) customer_name,';
	rq := rq || ' (select name from v$users where id = p.creator_user_id) user_name,';
	rq := rq || ' p.status_id status,';
	rq := rq || ' p.order_date created';
	rq := rq || ' from documents p';
	rq := rq || ' where rownum <= :ResultSetSize';
	rq := rq || ' and ' || bocommon.order_date_expression(custId, NULL, NULL, -1);
	rq := rq || ' and p.class_id in (' || docClass || ')';
	rq := rq || ' and p.status_id in (' || statuses || ')';
	if custId is not null then
		rq := rq || ' and p.from_customer = :CustomerId';
	end if;
	cursor_name := dbms_sql.open_cursor;
	dbms_sql.parse(cursor_name, rq, dbms_sql.native);
	dbms_sql.bind_variable(cursor_name, ':ResultSetSize', bocommon.ResultSetSize);
	dbms_sql.bind_variable(cursor_name, ':DateFrom', createdFrom);
	dbms_sql.bind_variable(cursor_name, ':DateTill', createdTill);
	dbms_sql.bind_variable(cursor_name, ':LanguageID', bocommon.LanguageId);
	if custId is not null then
		dbms_sql.bind_variable(cursor_name, ':CustomerId', custId);
	end if;
	return execute_by_filter(cursor_name);
end;

function find(
	custId in varchar2,
	docId in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t is
begin
	if docId is not null then
		return find_by_id(docId, '311');
	end if;
	return find_by_filter(
		'311',
		custId,
		statuses,
		createdFrom,
		createdTill
	);
end;

procedure cru(
	pId in varchar2,
	pDocNo out varchar2,
	userName out varchar2,
	userId out varchar2,
	custName out varchar2,
	globusNo out varchar2,
	pLocation out varchar2,
	--
	itc out varchar2,
	itb out varchar2,
	signTime out date,
	signDevType out integer,
	signDevId out varchar2,
	signKey1 out varchar2,
	signKey2 out varchar2
) is
begin
	select
		/* BOCRU.order */
		d.bank_reference,
		d.document_number,
		u.name || ' (' || w.login || ')',
		u.personal_id,
		nvl(trim(decode(bocommon.LanguageId,
			0, c.name.name_lv,
			1, c.name.name_en,
			2, c.name.name_ru,
			3, c.name.extra_1,
			4, c.name.extra_2,
			5, c.name.extra_3,
			c.name.name_en
		)), c.name.name_en) || ' (' || c.id || ')',
		d.from_location,
		d.info_to_customer,
		d.info_to_bank,
		d.signature_date,
		d.signature_cdevice_type_id,
		d.signature_cdevice_serial,
		d.signature_key_1,
		d.signature_key_2
	into
		globusNo,
		pDocNo,
		userName,
		userId,
		custName,
		pLocation,
		itc,
		itb,
		signTime,
		signDevType,
		signDevId,
		signKey1,
		signKey2
	from documents d, v$users u, cusd c, ways_of_connection w
	where d.id = pId and
		c.id(+) = d.from_customer and
		u.id = d.creator_user_id and
		w.id(+) = d.creator_woc_id;
end;

end;
/

show err;
