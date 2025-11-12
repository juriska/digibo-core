create or replace package bocommon as

RESOURCE_BUSY_NOWAIT EXCEPTION;
type cursor_t is ref cursor;

officerId officers.id%type;

function is_replaced return integer;
function isDefaultFor return varchar2_loc_type;

procedure set_version(ver in varchar2);
procedure set_params(lang in integer, rss in integer, hdals in integer);
function prepare_like(str in varchar2) return varchar2;
function FormatCcyStr(ccy char) return char;
function FormatAmount(amount number, ccy char) return varchar2;
function str2table(p_str in varchar2) return num_table_type;
function create_str_table(p_str in varchar2) return varchar2_table_type;

function get_roles(
	pGrantee in varchar2,
	pRoles in varchar2
) return cursor_t;
function get_root_roles(
 	pGrantee in varchar2,
	pRoles in varchar2
) return cursor_t;
procedure get_plain_roles(
	pGrantee in varchar2,
	pResult in out varchar2
);


function get_questions return cursor_t;

function get_currencies return cursor_t;

function get_officers(pLoggedOfficerId out integer) return cursor_t;

function get_countries return cursor_t;

function get_payment_template_groups return cursor_t;

function get_dictionary return cursor_t;

function get_sellers return cursor_t;

function get_depts return cursor_t;

procedure log_event(
	pUserId audit_log.user_child_id%TYPE default null, 
	pEventId audit_log.event_type_id%TYPE default null, 
	pDetails audit_log.details%TYPE default null,
	pWocId audit_log.woc_child_id%TYPE default null,
	pPayId audit_log.payment_id%TYPE default null,
	pMsgId audit_log.message_id%TYPE default null,
	pPrev audit_log.prev_pmt_status%TYPE default null,
	pNew audit_log.cur_pmt_status%TYPE default null
);

procedure get_locker(
	lock_handle   in  varchar2,
	officer_name  out varchar2,
	officer_phone out varchar2
);

procedure new_listener(
	address in varchar2,
	port in integer,
	rand in varchar2 default 'N/A'
);
procedure drop_listener(
	address in varchar2,
	port in integer
);

function get_logged_officer return number;

ResultSetSize integer := 2000;
HelpDeskAuditLogSize integer := 100;
LanguageId integer := 0;

function check_pswd_SMS(
         pMobile in varchar2,
         pPassword in varchar2
) return number;

function has_role( pRole in varchar2)  return integer;

function order_date_expression(
    custId in varchar2,
    custName in varchar2,
    userLogin in varchar2,
    remoteId in integer) return varchar2;

end;
/

show err;

create or replace package body bocommon as

procedure set_version(ver in varchar2) is
begin
	dbms_application_info.set_module(ver, null);
end;

procedure set_params(lang in integer, rss in integer, hdals in integer) is
begin
	ResultSetSize := rss;
	HelpDeskAuditLogSize := hdals;
	LanguageId := lang;
end;

function prepare_like(str in varchar2) return varchar2 is
	rv varchar2(4000) := null;
begin
	if str is not null and regexp_instr(str, '^[%_\?\*]+$') = 0 then
		rv := upper(replace(replace(str, '?', '_'), '*', '%'));
	end if;
	return rv;
end;

function FormatCcyStr(ccy char) return char is
    d number(3);
    fs varchar2(20);
begin
    select decimals into d from glb_currencies where id = ccy;
    fs := '99999999999990';
    if d > 0 then fs := fs||SubStr('.999', 1, 1 + d); end if;
    return fs;
end;

function FormatAmount(amount number, ccy char) return varchar2 is
begin
	if amount is null or ccy is null then
		return '';
	end if;
	return trim(to_char(amount, FormatCcyStr(nvl(ccy, 'LVL'))));
end;

function str2table(p_str in varchar2) return num_table_type as
	l_str long default p_str || ',';
	l_n number;
	l_data num_table_type := num_table_type();
begin
	loop
		l_n := instr( l_str, ',' );
		exit when (nvl(l_n,0) = 0);
		l_data.extend;
		l_data( l_data.count ) := ltrim(rtrim(substr(l_str,1,l_n-1)));
		l_str := substr( l_str, l_n+1 );
	end loop;
	return l_data;
end;

function create_str_table(p_str in varchar2) return varchar2_table_type as
	src long default p_str || ',';
	data varchar2_table_type := varchar2_table_type();
	n integer;
begin
	loop
		n := instr(src, ',');
		exit when nvl(n, 0) = 0;
		data.extend;
		data(data.count) := ltrim(rtrim(substr(src, 1, n - 1)));
		src := substr(src, n + 1);
	end loop;
	return data;
end;

function get_root_roles(
 	pGrantee in varchar2,
	pRoles in varchar2
) return cursor_t is
 	rv cursor_t;
begin
	open rv for select distinct dr.role, drp.ao, nvl(drp.gc, 0)
	from sys.dba_roles dr, (
		select d.grantee, d.granted_role gr, d.admin_option ao, count(1) gc
		from sys.dba_role_privs d
		having d.grantee = pGrantee
		group by d.grantee, d.granted_role, d.admin_option
	) drp
	where dr.role like 'RBO%' and dr.role = drp.gr(+);
	return rv;
end;

function get_roles(
 	pGrantee in varchar2,
	pRoles in varchar2
) return cursor_t is
 	rv cursor_t;
begin
	open rv for select distinct granted_role, admin_option
	from sys.dba_role_privs
	where grantee = upper(pGrantee) and
		granted_role like pRoles;
	return rv;
end;

procedure get_plain_roles(
	pGrantee in varchar2,
	pResult in out varchar2
) is
	cursor rv is
		select distinct granted_role
		from sys.dba_role_privs
		where grantee = upper(pGrantee) and granted_role like 'RBO%';
begin
	for rec in rv loop
		if nvl(instr(pResult, rec.granted_role || ';'), 0) = 0 then
			pResult := pResult || rec.granted_role || ';';
			get_plain_roles(rec.granted_role, pResult);
		end if;
	end loop;
end;

function get_questions return cursor_t is
	rv cursor_t;
begin
	open rv for select
		sq.id id,
		sq.text.name_lv name_lv,
		sq.text.name_en name_en,
		sq.text.name_ru name_ru,
		sq.text.extra_1 name_de,
		sq.text.extra_2 name_se,
		sq.text.extra_3 name_ee
	from standard_questions sq;
	return rv;
end;

function get_currencies return cursor_t is
	rv cursor_t;
begin
	open rv for select c.id id 
	from glb_currencies c
	where is_visible != 0;
	return rv;
end;

function get_officers(pLoggedOfficerId out integer) return cursor_t is
	rv cursor_t;
begin
	pLoggedOfficerId := officerId;
	open rv for
		select id, roles, name, login, attached, roles from officers_and_roles;
	return rv;
end;

function get_countries return cursor_t is
	rv cursor_t;
begin
	open rv for select
		c.id id,
		nvl(trim(decode(bocommon.LanguageId,
			0, c.name.name_lv,
			1, c.name.name_en,
			2, c.name.name_ru,
			3, c.name.extra_1,
			4, c.name.extra_2,
			5, c.name.extra_3,
			c.name.name_en
		)), c.name.name_en) name
    from glb_countries c
	where is_visible != 0
	order by name;
	return rv;
end;

function get_payment_template_groups return cursor_t is
    rv cursor_t;
begin
    open rv for select
        c.id id,
        nvl(trim(decode(bocommon.LanguageId,
            0, c.name.name_lv,
            1, c.name.name_en,
            2, c.name.name_ru,
            3, c.name.extra_1,
            4, c.name.extra_2,
            5, c.name.extra_3,
            c.name.name_en
        )), c.name.name_en) name
    from ibglb.BANK_TEMPLATE_GROUP_CONFIG c
    --where is_visible != 0
    order by sequence_nr;
    return rv;
end;

function get_sellers return cursor_t is
	rv cursor_t;
begin
	open rv for select o.id id, o.officer_name name
	from glb_dept_accnt_officer o
	where is_visible = 1 and nvl(officer_level, 0) = 99;
	return rv;
end;

function get_depts return cursor_t is
	rv cursor_t;
begin
	open rv for select gdo.id id, gdo.officer_name name, gdo.officer_level dept_level
	from glb_dept_accnt_officer gdo
	where gdo.officer_level <> 99; /* 99 is persons */
	return rv;
end;

function get_dictionary return cursor_t is
	rv cursor_t;
begin
	open rv for select
		d.id f_id, 
		nvl(trim(decode(bocommon.LanguageId,
			0, d.name.name_lv,
			1, d.name.name_en,
			2, d.name.name_ru,
			3, d.name.extra_1,
			4, d.name.extra_2,
			5, d.name.extra_3,
			d.name.name_en
		)), d.name.name_en) f_name,
		d.field_type f_field_type,
		d.parent_id f_parent_id,
		d.class_id f_class_id,
		d.card_group_id f_card_group_id
	from dictionary d
	order by f_id;
	return rv;
end;

procedure log_event(
	pUserId audit_log.user_child_id%TYPE, 
	pEventId audit_log.event_type_id%TYPE, 
	pDetails audit_log.details%TYPE,
	pWocId audit_log.woc_child_id%TYPE,
	pPayId audit_log.payment_id%TYPE,
	pMsgId audit_log.message_id%TYPE,
	pPrev audit_log.prev_pmt_status%TYPE,
	pNew audit_log.cur_pmt_status%TYPE
) is begin
	insert into audit_log (
		id,
		event_date,
		session_id,
		user_child_id,
		woc_child_id,
		details,
		event_type_id,
		payment_id,
		message_id,
		prev_pmt_status,
		cur_pmt_status
	) values (
		unq_audit_log_id_seq.NextVal, 
		SysDate, 
		unq_session_log_id_seq.CurrVal,
		pUserId,
		pWocId,
		pDetails,
		pEventId,
		pPayId,
		pMsgId,
		pPrev,
		pNew
	);
end;

procedure get_locker(
	lock_handle   in  varchar2,
	officer_name  out varchar2,
	officer_phone out varchar2
) is begin
	select nvl(o.name, o.login), phone
	into officer_name, officer_phone
	from gv$session s, gv$lock l, officers o
	where l.id1 = substr(lock_handle, 1, 10) and
		l.sid = s.sid and
		s.username = upper(o.login);
	exception when NO_DATA_FOUND then
		return;
end;

function get_logged_officer return number is begin
	return officerId;
end;

function is_replaced return integer is
	rv integer := 0;
begin
	select count(1) into rv from officer_replacement
	where officer_id = bocommon.officerId and replaced_by is not null;
	return rv;
end;

procedure new_listener(
	address in varchar2,
	port in integer,
	rand in varchar2 default 'N/A'
) is
	r officers_online.roles%type;
        ip varchar2(20);
	
begin
	SELECT SYS_CONTEXT('USERENV','IP_ADDRESS') into ip FROM dual;

	delete from officers_online ol
	where ip = ol.ip_address and
		port = ol.ip_port and
		officerId = ol.officer_id
        and nvl(type, 'BACKOFFICE') = 'BACKOFFICE';
	get_plain_roles(user, r);
	insert into officers_online
		(ip_address, ip_port, officer_id, roles, terminal, username, session_id, type)
	values (ip, port, officerId, r, userenv('TERMINAL'), user, rand, 'BACKOFFICE');
    
    update officers
    set
           last_session_id = unq_session_log_id_seq.CurrVal,
           last_session_date = sysdate
    where id = OfficerId;                   
    
end;

procedure drop_listener(
	address in varchar2,
	port in integer
) is
begin
	delete from officers_online ol
	where address = ol.ip_address and
		port = ol.ip_port
        and nvl(type, 'BACKOFFICE') = 'BACKOFFICE';
end;

function check_pswd_SMS(
         pMobile in varchar2,
         pPassword in varchar2
) return number is
  cnt number;
begin
  select count(1) into cnt from ways_of_connection where login = pMobile and password = pPassword and channel_id = 6 and status_id in (1,2);
  return cnt;
end; 

function isDefaultFor return varchar2_loc_type is
	rv varchar2_loc_type := varchar2_loc_type();
	t varchar2(2);
	cursor c is select o.def_officer def_for
		from officers o, officer_replacement r
		where r.replaced_by = officerId and
			o.id = r.officer_id and
			o.def_officer is not null;
	r c%rowtype;
begin
	select def_officer into t from officers where id = officerId;
	if t is not null then
		rv.extend;
		rv(rv.count) := t;
	end if;
	for r in c loop
		rv.extend;
		rv(rv.count) := r.def_for;
	end loop;
	return rv;
end;

 function has_role (  pRole in varchar2) return integer is
  rv integer := 0;
begin
  if dbms_session.is_role_enabled(pRole) then
        rv := 1;
    end if;
  return rv;
end;


function order_date_expression(
    custId in varchar2,
    custName in varchar2,
    userLogin in varchar2,
    remoteId in integer) return varchar2
is
begin
    -- use functional index for order date if fields with better selectivity not found
    if custId is null and custName is null and userLogin is null and remoteId <= 0 then
        return 'trunc(nvl(p.order_date, p.order_date), ''DD'') between :DateFrom and :DateTill - 1';
    else
        return 'p.order_date between :DateFrom and :DateTill';
    end if;
end;


begin
	select id
	into officerId
	from officers 
	where upper(login) = user and rownum = 1;
end;



/

show err;
