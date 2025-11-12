/*
* SMS messages monitoring.
*/

create or replace package bosmsview as

type cursor_t is ref cursor;

function get_types return cursor_t;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,
	userLogin in varchar2,
	officerId in integer,

	-- document
	pType in varchar2,
	pMobile in varchar2,
	pText in varchar2,

	-- system
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t;

procedure sms(
	pId in varchar2,
	typeName out varchar2,
	pPriority out varchar2,
	pChangeDate out date,
	pChargeDate out date,
	pText out varchar2,
	pSrcAddr out varchar2,
	pSrcProvider out varchar2,
	pDestAddr out varchar2,
	pDestProvider out varchar2,
	pWocId out varchar2,
	pUserId out varchar2,
	pUserName out varchar2,
	pLogin out varchar2,
	pStmtId out varchar2,
	pBatchId out varchar2,
	errorType out varchar2,
	errorText out varchar2
);

end;
/

show err;

create or replace package body bosmsview as

function get_types return cursor_t is
	rv cursor_t;
begin
	open rv for
	select m.id id, m.name name 
	from sms_owner.message_types m
	where id != 11 -- Incoming message
	order by id;
	return rv;
end;

function get_error_code(m_id in varchar2) return number is
	cursor rv is
		select e.code code
		from sms_owner.message_errors e
		where e.message_id = m_id and rownum <= 1
		order by e.id desc;
	error number(4) := 0;    
begin
	for rec in rv loop
		error := rec.code;
	end loop;
	return error;
exception when NO_DATA_FOUND then
	return null;
end;

function execute_by_filter(
	pCursorName in integer
) return cursor_t is
	cursor_name integer := pCursorName;
	rv cursor_t;
	rows_processed integer;
	row sms_message_t;
	rowset sms_message_set_t := sms_message_set_t();
	m_id number(10);
	parent_id number(10);
	status number(3);
	io varchar2(1);
	type_id number(3);
	create_date date;
	mobile_phone varchar2(21);
	customer varchar2(220);
begin
	dbms_sql.define_column(cursor_name,  1, m_id);
	dbms_sql.define_column(cursor_name,  2, parent_id);
	dbms_sql.define_column(cursor_name,  3, status);
	dbms_sql.define_column(cursor_name,  4, io, 1);
	dbms_sql.define_column(cursor_name,  5, type_id);
	dbms_sql.define_column(cursor_name,  6, create_date);
	dbms_sql.define_column(cursor_name,  7, mobile_phone, 21);
	dbms_sql.define_column(cursor_name,  8, customer, 220);

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name,  1, m_id);
		dbms_sql.column_value(cursor_name,  2, parent_id);
		dbms_sql.column_value(cursor_name,  3, status);
		dbms_sql.column_value(cursor_name,  4, io);
		dbms_sql.column_value(cursor_name,  5, type_id);
		dbms_sql.column_value(cursor_name,  6, create_date);
		dbms_sql.column_value(cursor_name,  7, mobile_phone);
		dbms_sql.column_value(cursor_name,  8, customer);

		row := sms_message_t(
			m_id,
			parent_id,
			status,
			io,
			type_id,
			create_date,
			mobile_phone,
			customer,
			get_error_code(m_id)
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as sms_message_set_t));
	return rv;

exception when others then
	if dbms_sql.is_open(cursor_name) then
		dbms_sql.close_cursor(cursor_name);
	end if;
	raise;
end;

function find(
	custId in varchar2,
	custName in varchar2,
	userLogin in varchar2,
	officerId in integer,
	pType in varchar2,
	pMobile in varchar2,
	pText in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t is
	rq varchar2(32767);
	cursor_name integer;
	remoteId integer := BODocuments.get_remote_officer(officerId);
	custMask varchar2(1000) := bocommon.prepare_like(custName);
	loginMask varchar2(1000) := bocommon.prepare_like(userLogin);
	textMask varchar2(1000) := bocommon.prepare_like(pText);
begin
	if custMask is not null or remoteId > 0 then
		delete from tmp_request_data;
		insert into tmp_request_data (requested_id)
		select distinct c.id from ibglb.cusd c
		where (remoteId <= 0 or	c.remote_officers.contains(remoteId) = 1) and
			(custMask is null or c.name.is_like(custMask) = 1);
	end if;

	rq := 'select /* BOSMSView.find */ * from (select';
	rq := rq || ' m.id id,';
	rq := rq || ' m.ref_id parent_id,';
	rq := rq || ' m.status status,';
	rq := rq || ' m.class_id io,';
	rq := rq || ' m.type_id type_id,';
	rq := rq || ' m.create_date create_date,';
	rq := rq || ' decode(m.class_id,';
	rq := rq || '     ''I'', m.source_address,';
	rq := rq || '     ''O'', m.dest_address,';
	rq := rq || '     null';
	rq := rq || ' ) mobile_phone,';
	rq := rq || ' (select nvl(trim(decode(:LanguageID,';
	rq := rq || '     0, c.name.name_lv,';
	rq := rq || '     1, c.name.name_en,';
	rq := rq || '     2, c.name.name_ru,';
	rq := rq || '     3, c.name.extra_1,';
	rq := rq || '     4, c.name.extra_2,';
	rq := rq || '     5, c.name.extra_3,';
	rq := rq || '     c.name.name_en)), c.name.name_en) || '' ('' || c.id || '')''';
	rq := rq || ' from ibglb.cusd c where c.id = m.cusd_id) customer';
	rq := rq || ' from (';
	rq := rq || '     select distinct nvl(m.ref_id, m.id) id';
	rq := rq || '     from sms_owner.messages m';
	rq := rq || '     where m.is_dlr = 0';
	rq := rq || '         and m.create_date between :DateFrom and :DateTill';
	rq := rq || '         and m.status in (' || statuses || ')';
	if pMobile is not null then
		rq := rq || ' and :pMobile = decode(m.class_id, ''I'', m.source_address, ''O'', m.dest_address, '''')';
	end if;
	if loginMask is not null then
		rq := rq || ' and :loginMask = decode(m.class_id, ''I'', m.source_address, ''O'', m.dest_address, '''')';
        --loginMask :=  '''' || loginMask || '''' || ',' || '''' || replace(loginMask, '+371', '' || '''' )|| ',' || '''' || '+371' || loginMask || '''';
        --rq := rq || ' and decode(m.class_id, ''I'', m.source_address, ''O'', m.dest_address, '''')in ( :loginMask )';
        --rq := rq || ' and (';
           --rq := rq || ' :loginMask = decode(m.class_id, ''I'', m.source_address, ''O'', m.dest_address, '''')';
           --loginMask :=  loginMask || ',' || replace(loginMask, '+371', '');
           --rq := rq || 'or :loginMask = decode(m.class_id, ''I'', m.source_address, ''O'', m.dest_address, '''')';
            --loginMask :=  '+371' || loginMask;
            --rq := rq || 'or :loginMask = decode(m.class_id, ''I'', m.source_address, ''O'', m.dest_address, '''')';
        --rq := rq || '  )';
	end if;
	if textMask is not null then
		rq := rq || ' and m.text like :textMask';
	end if;
	if custId is not null then
		rq := rq || ' and :custId = m.cusd_id';
	end if;
	if custMask is not null or remoteId > 0 then
		rq := rq || ' and m.cusd_id in (select requested_id from tmp_request_data)';
	end if;
	if pType = '''I'',''O''' or pType = '''O''' or pType = '''I''' then
		rq := rq || ' and m.class_id in (' || pType || ')';
	else
		rq := rq || ' and m.type_id in (' || pType || ')';
	end if;
	rq := rq || ' ) subset,';
	rq := rq || ' sms_owner.messages m';
	rq := rq || ' where (m.ref_id = subset.id or m.id = subset.id)';
	rq := rq || ' order by subset.id, m.id';
	rq := rq || ' )';
	rq := rq || ' where rownum <= :ResultSetSize';

	cursor_name := dbms_sql.open_cursor;
	dbms_sql.parse(cursor_name, rq, dbms_sql.native);

	dbms_sql.bind_variable(cursor_name, ':LanguageID', bocommon.LanguageId);
	dbms_sql.bind_variable(cursor_name, ':ResultSetSize', bocommon.ResultSetSize);
	dbms_sql.bind_variable(cursor_name, ':DateFrom', createdFrom);
	dbms_sql.bind_variable(cursor_name, ':DateTill', createdTill);
	if pMobile is not null then
		dbms_sql.bind_variable(cursor_name, ':pMobile', pMobile);
	end if;
	if loginMask is not null then
		dbms_sql.bind_variable(cursor_name, ':loginMask', loginMask);
	end if;
	if textMask is not null then
		dbms_sql.bind_variable(cursor_name, ':textMask', textMask);
	end if;
	if custId is not null then
		dbms_sql.bind_variable(cursor_name, ':custId', custId);
	end if;

	return execute_by_filter(cursor_name);
end;

procedure sms(
	pId in varchar2,
	typeName out varchar2,
	pPriority out varchar2,
	pChangeDate out date,
	pChargeDate out date,
	pText out varchar2,
	pSrcAddr out varchar2,
	pSrcProvider out varchar2,
	pDestAddr out varchar2,
	pDestProvider out varchar2,
	pWocId out varchar2,
	pUserId out varchar2,
	pUserName out varchar2,
	pLogin out varchar2,
	pStmtId out varchar2,
	pBatchId out varchar2,
	errorType out varchar2,
	errorText out varchar2
) is
begin
	select
		t.name,
		m.priority,
		m.change_date,
		m.charge_date,
		nvl(decode(m.class_id, 'I', m.text, null), decode(m.type_id, 403/*Freeformat SMS*/, m.text, null)),
		m.source_address,
		nvl(trim(decode(bocommon.LanguageId,
			0, mo1.name.name_lv,
			1, mo1.name.name_en,
			2, mo1.name.name_ru,
			3, mo1.name.extra_1,
			4, mo1.name.extra_2,
			5, mo1.name.extra_3,
			mo1.name.name_en
		)), mo1.name.name_en),
		m.dest_address,
		nvl(trim(decode(bocommon.LanguageId,
			0, mo2.name.name_lv,
			1, mo2.name.name_en,
			2, mo2.name.name_ru,
			3, mo2.name.extra_1,
			4, mo2.name.extra_2,
			5, mo2.name.extra_3,
			mo2.name.name_en
		)), mo2.name.name_en),
		w.id,
		u.id,
		u.name,
		w.login,
		m.stmt_id,
		m.com_batch_id
	into
		typeName,
		pPriority,
		pChangeDate,
		pChargeDate,
		pText,
		pSrcAddr,
		pSrcProvider,
		pDestAddr,
		pDestProvider,
		pWocId,
		pUserId,
		pUserName,
		pLogin,
		pStmtId,
		pBatchId
	from sms_owner.messages m, sms_owner.message_types t,
		ways_of_connection w, v$users u,
		mobile_operators mo1, mobile_operators mo2
	where m.id = pId and
		w.id(+) = m.woc_id and
		u.id(+) = w.user_id and
		t.id(+) = m.type_id and
		mo1.id(+) = m.source_provider and
		mo2.id(+) = m.dest_provider;


	begin
		select type, text
		into errorType,	errorText
		from sms_owner.message_errors
		where message_id = pId and rownum <= 1
		order by id desc;
	exception when others then
		null;
	end;
end;

end;
/

show err;
