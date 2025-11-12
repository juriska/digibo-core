CREATE OR REPLACE package body IB.BOAuditLog as

function execute_by_filter(
	pCursorName in integer
) return cursor_t is
	cursor_name integer := pCursorName;
	rv cursor_t;
	rows_processed integer;
	row audit_log_t;
	rowset audit_log_set_t := audit_log_set_t();
	id number(14);
	time_stamp date;
	session_no number(14);
	machine varchar2(64);
	sl_woc_id number(10);
	al_woc_id number(10);
	details varchar2(2000);
	channel number(2);
	event_type_id number(10);
	doc_id number(14);
	user_id number(10);
	message_id number(9);
	sl_user_id number(10);
	orig_user varchar2(60);
	obj_user varchar2(60);
    storm_project char(4);
begin
	dbms_sql.define_column(cursor_name,  1, id);
	dbms_sql.define_column(cursor_name,  2, time_stamp);
	dbms_sql.define_column(cursor_name,  3, session_no);
	dbms_sql.define_column(cursor_name,  4, machine, 64);
	dbms_sql.define_column(cursor_name,  5, sl_woc_id);
	dbms_sql.define_column(cursor_name,  6, al_woc_id);
	dbms_sql.define_column(cursor_name,  7, details, 2000);
	dbms_sql.define_column(cursor_name,  8, channel);
	dbms_sql.define_column(cursor_name,  9, event_type_id);
	dbms_sql.define_column(cursor_name, 10, doc_id);
	dbms_sql.define_column(cursor_name, 11, user_id);
	dbms_sql.define_column(cursor_name, 12, message_id);
	dbms_sql.define_column(cursor_name, 13, sl_user_id);
	dbms_sql.define_column(cursor_name, 14, orig_user, 60);
	dbms_sql.define_column(cursor_name, 15, obj_user, 60);
    dbms_sql.define_column(cursor_name, 16, storm_project, 4);

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name,  1, id);
		dbms_sql.column_value(cursor_name,  2, time_stamp);
		dbms_sql.column_value(cursor_name,  3, session_no);
		dbms_sql.column_value(cursor_name,  4, machine);
		dbms_sql.column_value(cursor_name,  5, sl_woc_id);
		dbms_sql.column_value(cursor_name,  6, al_woc_id);
		dbms_sql.column_value(cursor_name,  7, details);
		dbms_sql.column_value(cursor_name,  8, channel);
		dbms_sql.column_value(cursor_name,  9, event_type_id);
		dbms_sql.column_value(cursor_name, 10, doc_id);
		dbms_sql.column_value(cursor_name, 11, user_id);
		dbms_sql.column_value(cursor_name, 12, message_id);
		dbms_sql.column_value(cursor_name, 13, sl_user_id);
		dbms_sql.column_value(cursor_name, 14, orig_user);
		dbms_sql.column_value(cursor_name, 15, obj_user);
        dbms_sql.column_value(cursor_name, 16, storm_project);

		row := audit_log_t(
			id,
			session_no,
			time_stamp,
			machine,
			orig_user,
			null,
			obj_user,
			null,
			null,
			details,
			channel,
			null,
			null,
			null,
			doc_id,
			null,
			null,
			user_id,
			message_id,
			sl_woc_id,
			al_woc_id,
			sl_user_id,
			event_type_id,
            storm_project
		);

		if orig_user is null and sl_user_id is not null then
			begin
				select login
				into row.orig_officer
				from officers
				where id(+) = sl_user_id;
			exception when NO_DATA_FOUND then
				null;
			end;
		end if;

		if obj_user is null and user_id is not null then
			begin
				select login
				into row.obj_officer
				from officers
				where id(+) = user_id;
			exception when NO_DATA_FOUND then
				null;
			end;
		end if;

		if doc_id is not null then
			begin
				select d.class_id, d.document_number || ' ' ||
					nvl(a.iban, a.mccy_accnum || ' ' || a.sub_accnum) ||
					' ' || a.ccy
				into row.class_id, row.doc_info
				from documents d, acsd a
				where d.id(+) = doc_id and a.id(+) = d.from_account;
			exception when NO_DATA_FOUND then
				null;
			end;
		end if;

		if doc_id is null then
			begin
				select class_id
				into row.fax_class_id
				from fax_doc_history
				where audit_log_id(+) = id;
			exception when NO_DATA_FOUND then
				null;
			end;
		end if;

		select et.id || ' ' || nvl(trim(decode(bocommon.LanguageId,
			0, et.name.name_lv,
			1, et.name.name_en,
			2, et.name.name_ru,
			3, et.name.extra_1,
			4, et.name.extra_2,
			5, et.name.extra_3,
			et.name.name_en)), et.name.name_en) eventName,
			et.cust_visible uv
		into row.eventName, row.uv
		from event_types et
		where et.id = event_type_id;

		select nvl(trim(decode(bocommon.LanguageId,
			0, et.name.name_lv,
			1, et.name.name_en,
			2, et.name.name_ru,
			3, et.name.extra_1,
			4, et.name.extra_2,
			5, et.name.extra_3,
			et.name.name_en)), et.name.name_en) eventGroup
		into row.eventGroup
		from event_types et
		where event_type_id - Mod(event_type_id, 100) = et.id;

		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as audit_log_set_t));

	return rv;

exception when others then
	if dbms_sql.is_open(cursor_name) then
		dbms_sql.close_cursor(cursor_name);
	end if;
	raise;
end;

function find(
	dfrom in date,
	dto in date,
	events in varchar2,
	pObject in varchar2,
	pOriginator in varchar2,
	pChannels in varchar2,
	pResultSetSize in number
) return cursor_t is
	rq varchar2(32767);
	m_object varchar2(1000) := bocommon.prepare_like(pObject);
	m_originator varchar2(1000) := bocommon.prepare_like(pOriginator);
	cursor_name integer;
begin
	if m_object is not null or m_originator is not null then
		delete from tmp_request_data;
	end if;

	if m_object is not null then -- for al.user_child_id.
		insert into tmp_request_data (requested_id, filter1)
		select user_id, 'OBJECT' from ways_of_connection
		where upper(login) like m_object;
		insert into tmp_request_data (requested_id, filter1)
		select id, 'OBJECT' from officers
		where login like m_object;
	end if;

	if m_originator is not null then -- for sl.user_id.
		insert into tmp_request_data (requested_id, filter1)
		select user_id, 'ORIGINATOR' from ways_of_connection
		where upper(login) like m_originator;
		insert into tmp_request_data (requested_id, filter1)
		select id, 'ORIGINATOR' from officers
		where login like m_originator;
	end if;

	rq := 'select /* BOAuditLog.find */';
	if m_object is not null then
		rq := rq || ' /*+ INDEX (al IDX_AL_USER_CHILD_ID) */';
	end if;
	if m_originator is not null then
		rq := rq || ' /*+ INDEX (sl PK_SESSION_LOG) */';
	end if;
	rq := rq || ' al.id id,';
	rq := rq || ' al.event_date time_stamp,';
	rq := rq || ' al.session_id session_no,';
	rq := rq || ' sl.ip_address machine,';
	rq := rq || ' sl.woc_id sl_woc_id,';
	rq := rq || ' al.woc_child_id al_woc_id,';
	rq := rq || ' al.details details,';
	rq := rq || ' sl.channel_id channel,';
	rq := rq || ' al.event_type_id event_type_id,';
	rq := rq || ' al.payment_id doc_id,';
	rq := rq || ' al.user_child_id user_id,';
	rq := rq || ' al.message_id message_id,';
	rq := rq || ' sl.user_id sl_user_id,';
	rq := rq || ' decode(sl.woc_id, null,';
	rq := rq || ' (select w.login from ways_of_connection w where w.user_id = sl.user_id and rownum < 2),';
	rq := rq || ' (select w.login from ways_of_connection w where w.id = sl.woc_id)';
	rq := rq || ' ) orig_user,';
	rq := rq || ' decode(al.woc_child_id, null,';
	rq := rq || ' (select w.login from ways_of_connection w where w.user_id = al.user_child_id and rownum < 2),';
	rq := rq || ' (select w.login from ways_of_connection w where w.id = al.woc_child_id)';
	rq := rq || ' ) obj_user,';
    rq := rq || ' SL.STORM_PROJECT storm_project';
	rq := rq || ' from audit_log al, session_log sl';
	rq := rq || ' where rownum <= :ResultSetSize';
	rq := rq || ' and al.event_date between :DateFrom and :DateTo';
	if events is not null then
		rq := rq || ' and al.event_type_id in (' || events || ')';
	end if;
	if m_object is not null then
		rq := rq || ' and al.user_child_id in (';
		rq := rq || ' select REQUESTED_ID';
		rq := rq || ' from tmp_request_data';
		rq := rq || ' where filter1 = ''OBJECT''';
		rq := rq || ' )';
	end if;
	rq := rq || ' and al.session_id = sl.id';
	if pChannels is not null then
		rq := rq || ' and nvl(sl.channel_id, 0) in (' || pChannels || ')';
	end if;
	if m_originator is not null then
		rq := rq || ' and sl.user_id in (';
		rq := rq || ' select REQUESTED_ID';
		rq := rq || ' from tmp_request_data';
		rq := rq || ' where filter1 = ''ORIGINATOR''';
		rq := rq || ' )';
	end if;

	cursor_name := dbms_sql.open_cursor;

	dbms_sql.parse(cursor_name, rq, dbms_sql.native);
	dbms_sql.bind_variable(cursor_name, ':ResultSetSize', pResultSetSize);
	dbms_sql.bind_variable(cursor_name, ':DateFrom', dfrom);
	dbms_sql.bind_variable(cursor_name, ':DateTo', dto);

	return execute_by_filter(cursor_name);
end;

function findSession(pSession in varchar2) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		/* BOAuditLog.findSession */
		/*+ INDEX (sl PK_SESSION_LOG) INDEX (ac PK_ACSD) */
		al.event_date time_stamp,
		al.session_id session_no,
		sl.ip_address machine,
		decode(sl.woc_id,
			null, (select woc.login from ways_of_connection woc where woc.user_id = sl.user_id and rownum < 2),
			(select woc.login from ways_of_connection woc where woc.id = sl.woc_id)
		) orig_user,
		ofco.login orig_officer,
		decode(al.woc_child_id,
			null, (select woc.login from ways_of_connection woc where woc.user_id = al.user_child_id and rownum < 2),
			(select woc.login from ways_of_connection woc where woc.id = al.woc_child_id)
		) obj_user,
		ofcc.login obj_officer,
		pay.document_number || ' ' ||
			nvl(ac.iban, ac.mccy_accnum || ' ' || ac.sub_accnum) || ' ' ||
			ac.ccy doc_info,
		al.details details,
		sl.channel_id channel,
		al.event_type_id || ' ' || nvl(trim(decode(bocommon.LanguageId,
			0, et1.name.name_lv,
			1, et1.name.name_en,
			2, et1.name.name_ru,
			3, et1.name.extra_1,
			4, et1.name.extra_2,
			5, et1.name.extra_3,
			et1.name.name_en
		)), et1.name.name_en) eventName,
		nvl(trim(decode(bocommon.LanguageId,
			0, et2.name.name_lv,
			1, et2.name.name_en,
			2, et2.name.name_ru,
			3, et2.name.extra_1,
			4, et2.name.extra_2,
			5, et2.name.extra_3,
			et2.name.name_en
		)), et2.name.name_en) eventGroup,
		et1.cust_visible uv,
		al.payment_id doc_id,
		decode(pay.id, null, pay.class_id) class_id,
		fdh.class_id fax_class_id,
		al.user_child_id user_id,
		al.message_id message_id,
        sl.storm_project storm_project
	from audit_log al, session_log sl, officers ofco, officers ofcc,
		documents pay, acsd ac, event_types et1, event_types et2,
		fax_doc_history fdh
	where sl.id = pSession and
		rownum <= bocommon.ResultSetSize and
		sl.id = al.session_id(+) and
		ofco.id(+) = sl.user_id and
		ofcc.id(+) = al.user_child_id and
		pay.id(+) = al.payment_id and
		ac.id(+) = pay.from_account and
		fdh.audit_log_id(+) = al.id and
		al.event_type_id = et1.id and
		al.event_type_id - Mod(al.event_type_id, 100) = et2.id;
	return rv;
end;

function get_tree return cursor_t is
	rv cursor_t;
begin
	open rv for select
		e.id id,
		nvl(trim(decode(bocommon.LanguageId,
			0, e.name.name_lv,
			1, e.name.name_en,
			2, e.name.name_ru,
			3, e.name.extra_1,
			4, e.name.extra_2,
			5, e.name.extra_3,
			e.name.name_en
		)), e.name.name_en) name,
		e.cust_visible uv
	from event_types e
	order by e.id;
	return rv;
end;

end;
/
