create or replace package bocommon as

type cursor_t is ref cursor;

officerId number;

function prepare_like(str in varchar2) return varchar2;
function get_roles(
	pGrantee in varchar2,
	pRoles in varchar2
) return cursor_t;
function get_root_roles(
 	pGrantee in varchar2,
	pRoles in varchar2
) return cursor_t;

procedure log_event(
	pEventId number,
	pDetails varchar2 default null,
	pObjectId number default null
);

end;
/
show err;

create or replace package body bocommon as

function prepare_like(str in varchar2) return varchar2 is
	rv varchar2(4000);
begin
	rv := upper(replace(replace(str, '?', '_'), '*', '%'));
	return rv;
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

procedure log_event(
	pEventId number,
	pDetails varchar2,
	pObjectId number
) is
	vLogonId audit_log.id%type;
begin
	select unq_audit_seq.NextVal into vLogonId from dual;

	insert into audit_log (
		session_id, 
		id, 
		officer_id, 
		event_date, 
		event, 
		details,
		object_id
	) values (
		vLogonId,
		unq_audit_seq.NextVal,
		officerId,
		SysDate,
		pEventId,
		pDetails,
		pObjectId
	);
end;

begin
	select id into officerId 
	from officers@&&rsa_dblink
	where upper(login) = user;
end;
/
show err;
