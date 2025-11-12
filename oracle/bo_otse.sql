create or replace package BOOTSE as

type cursor_t is ref cursor;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,
	userLogin in varchar2,
	personalId in varchar2,

	-- system
	docId in varchar2
) return cursor_t;

function find_new return cursor_t;

function get_customer(
	pId in varchar2,
	pRv out number
) return cursor_t;

procedure bind(
	pWocId in varchar2,
	pCustId in varchar2,
	pUserId in varchar2,
	pDocId in varchar2
);

procedure set_woc_status(
	pWocId in varchar2,
	pStatus in integer,
	pSubStatus in integer
);

end;
/

show err;

create or replace package body BOOTSE as

DOC_RIGHTS_TYPE_CUSTOMER constant int := 1;

function find_by_id(
	docId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select /* BOOTSE.find_by_id */
		p.id id,
		p.class_id class_id,
		p.status_id status_id,
		p.order_date order_date,
		u.name name,
		u.personal_id personal_id,
		w.login login,
		w.id woc_id,
		u.id user_id
	from documents p, ways_of_connection w, v$users u
	where p.id = docId and
		p.class_id = 700 and
		w.id = p.creator_woc_id and
		u.id = w.user_id;
	return rv;
end;

function find_by_filter(
	pCursorName in integer
) return cursor_t is
	cursor_name integer := pCursorName;
	rv cursor_t;
	row otse_t;
	rows_processed integer;
	rowset otse_set_t := otse_set_t();
	id number(14);
	class_id number(3);
	status_id number(2);
	order_date date;
	name varchar2(210);
	personal_id varchar2(35);
	login varchar2(60);
	woc_id number(10);
	user_id number(10);
begin
	dbms_sql.define_column(cursor_name, 1, id);
	dbms_sql.define_column(cursor_name, 2, class_id);
	dbms_sql.define_column(cursor_name, 3, status_id);
	dbms_sql.define_column(cursor_name, 4, order_date);
	dbms_sql.define_column(cursor_name, 5, name, 210);
	dbms_sql.define_column(cursor_name, 6, personal_id, 35);
	dbms_sql.define_column(cursor_name, 7, login, 60);
	dbms_sql.define_column(cursor_name, 8, woc_id);
	dbms_sql.define_column(cursor_name, 9, user_id);

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name, 1, id);
		dbms_sql.column_value(cursor_name, 2, class_id);
		dbms_sql.column_value(cursor_name, 3, status_id);
		dbms_sql.column_value(cursor_name, 4, order_date);
		dbms_sql.column_value(cursor_name, 5, name);
		dbms_sql.column_value(cursor_name, 6, personal_id);
		dbms_sql.column_value(cursor_name, 7, login);
		dbms_sql.column_value(cursor_name, 8, woc_id);
		dbms_sql.column_value(cursor_name, 9, user_id);
		row := otse_t(
			id,
			class_id,
			status_id,
			order_date,
			name,
			personal_id,
			login,
			woc_id,
			user_id
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as otse_set_t));
	return rv;

exception when others then
	if dbms_sql.is_open(cursor_name) then
		dbms_sql.close_cursor(cursor_name);
	end if;
	raise;
end;

function find_by_filter(
	-- remitter
	custId in varchar2,
	pCustName in varchar2,
	pUserLogin in varchar2,
	personalId in varchar2
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

	rq := rq || 'select /* BOOTSE.find_by_filter */';
	rq := rq || ' p.id id,';
	rq := rq || ' p.class_id class_id,';
	rq := rq || ' p.status_id status_id,';
	rq := rq || ' p.order_date order_date,';
	rq := rq || ' u.name name,';
	rq := rq || ' u.personal_id personal_id,';
	rq := rq || ' w.login login,';
	rq := rq || ' w.id woc_id,';
	rq := rq || ' u.id user_id';
	rq := rq || ' from documents p, ways_of_connection w, v$users u';
	rq := rq || ' where rownum <= :ResultSetSize';
	rq := rq || ' and p.class_id = 700';
	rq := rq || ' and w.id = p.creator_woc_id';
	rq := rq || ' and u.id = w.user_id';

	if custId is not null then
		rq := rq || ' and p.from_customer = :CustomerId';
	end if;
	if userLogin is not null or personalId is not null then
		rq := rq || ' and p.creator_woc_id in (';
		if userLogin is not null then
			rq := rq || ' select /*+ INDEX (w1 IDX_WOC_LOGIN) */ w1.id id';
			rq := rq || ' from ways_of_connection w1';
			rq := rq || ' where upper(w1.login) like :UserLogin';
			if personalId is not null then
				rq := rq || ' intersect';
			end if;
		end if;
		if personalId is not null then
			rq := rq || ' select w2.id id';
			rq := rq || ' from ways_of_connection w2';
			rq := rq || ' where w2.user_id in (';
			rq := rq || '     select id from v$users where personal_id = :PersonalID';
			rq := rq || ' )';
		end if;
		rq := rq || ' )';
	end if;
	if custName is not null then
		rq := rq || ' and p.from_customer in (select requested_id from tmp_request_data)';
	end if;

	cursor_name := dbms_sql.open_cursor;

	dbms_sql.parse(cursor_name, rq, dbms_sql.native);
	dbms_sql.bind_variable(cursor_name, ':ResultSetSize', bocommon.ResultSetSize);
	if custId is not null then
		dbms_sql.bind_variable(cursor_name, ':CustomerId', custId);
	end if;
	if userLogin is not null then
		dbms_sql.bind_variable(cursor_name, ':UserLogin', userLogin);
	end if;
	if personalId is not null then
		dbms_sql.bind_variable(cursor_name, ':PersonalID', personalId);
	end if;

	return find_by_filter(cursor_name);
end;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,
	userLogin in varchar2,
	personalId in varchar2,

	-- system
	docId in varchar2
) return cursor_t is
begin
	if docId is not null then
		return find_by_id(docId);
	end if;
	return find_by_filter(
		custId,
		custName,
		userLogin,
		personalId
	);
end;

function find_new return cursor_t is
	rv cursor_t;
begin
	open rv for select
		/* BOOTSE.find_new */
		/*+ INDEX (p IDX_DOC_STATUS_CLASS) */
		p.id id,
		p.class_id class_id,
		p.status_id status_id,
		p.order_date order_date,
		u.name name,
		u.personal_id personal_id,
		w.login login,
		w.id woc_id,
		u.id user_id
	from documents p, ways_of_connection w, v$users u
	where rownum <= bocommon.ResultSetSize and
		p.class_id = 700 and
		p.status_id in (rba_const.SIGNATURE_OK, rba_const.MANUAL_PROCESSING_STARTED) and
		w.id = p.creator_woc_id and
		u.id = w.user_id;
	return rv;
end;

function get_customer(
	pId in varchar2,
	pRv out number
) return cursor_t is
	existence integer := 0;
	rv cursor_t;
begin
	select count(1) into existence from ibglb.cusd where id = pId;
	if existence = 0 then
		bo_repl_link.replicate_customer(pId, pRv);
		if 0 != pRv then
			return NULL;
		end if;
	else
		pRv := 0;
	end if;
	open rv for select /* BOOTSE.get_customer */
		c.id id,
		c.name.name_en name_en,
		c.name.name_lv name_lv,
		c.name.name_ru name_ru,
		c.name.extra_1 name_de,
		c.name.extra_2 name_se,
		c.name.extra_3 name_ee,
		c.legal_id legal_id,
		c.status status,
		c.posting_restrict posting_restrict,
		(select count(1)
			from acsd a
			where a.customer_id = c.id and
				a.location = 'EE' and
				a.is_visible != 0) accounts
	from cusd c
	where c.id = pId and c.is_visible = 1;
	return rv;
end;

procedure bind(
	pWocId in varchar2,
	pCustId in varchar2,
	pUserId in varchar2,
	pDocId in varchar2
) is
	vCount integer := 0;
begin
	select count(1) into vCount from customer_globus_restrictions
	where woc_id = pWocId and cusd_id = pCustId;
	if vCount = 0 then
		insert into customer_globus_restrictions (
			cusd_id,
			change_officer_id,
			change_date,
			woc_id
		) values (
			pCustId,
			bocommon.officerId,
			SysDate,
			pWocId
		);
	end if;
	select count(1) into vCount from user_document_rights
	where woc_id = pWocId and customer_id = pCustId and location = 'EE';
	if vCount = 0 then
		insert into user_document_rights (
			woc_id,
			customer_id,
			location,
			type,
			right,
			change_officer_id,
			change_date
		) values (
			pWocId,
			pCustId,
			'EE',
			DOC_RIGHTS_TYPE_CUSTOMER,
			'F',
			bocommon.officerId,
			SysDate
		);
	end if;

	update users u set customer_id = pCustId, migrstatus = 1 where u.id = pUserId;

	bocommon.log_event(pUserId, 60102, 'Binded to customer', pWocId);
	update documents set from_customer = pCustId where id = pDocId;
end;

procedure set_woc_status(
	pWocId in varchar2,
	pStatus in integer,
	pSubStatus in integer
) is
begin
	update ways_of_connection
	set
		status_id = pStatus,
		substatus_id = pSubStatus
	where id = pWocId;
end;

end;
/

show err;
