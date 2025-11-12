CREATE OR REPLACE package bosysadmin as

type cursor_t is ref cursor;

function get_replacers return cursor_t;


function get_officers(
	pLogin in varchar2,
	pName in varchar2
) return cursor_t;

function get_dept_list(pOfficer in integer) return cursor_t;

function officer_replaces(pId in integer) return cursor_t;

procedure load_officer(
	pId in out integer,
	pName out varchar2,
	pRepId out integer,
	pLogin out varchar2,
	pPersonalId out varchar2,
	pDeptId out varchar2,
	pPhone out varchar2,
	pMobile out varchar2,
	pEmail out varchar2,
	pRegDate out date,
	pParentDeptId out varchar2,
	pAvailPkgs out varchar2,
	pDefForCountry out varchar2,
	pHistory out cursor_t,
	pActual out cursor_t,
	pSkypeName out varchar2,
	pIsLdapUser out number
);

procedure update_officer(
	pId in integer,
	pName in varchar2,
	pRepId in integer,
	pLogin in varchar2,
	pPersonalId in varchar2,
	pDeptId in varchar2,
	pPhone in varchar2,
	pMobile in varchar2,
	pEmail in varchar2,
	pParentDeptId in varchar2,
	pDefForCountry in varchar2,
	pSkypeName in varchar2,
	pIsLdapUser in number
);

procedure replace_officer(
	pId in integer,
	pRepId in integer
);

procedure update_roles(
	pId in integer,
	pLogin in varchar2,
	pRoles in varchar2
);

function get_logged return cursor_t;

procedure get_photo(
    pId in integer,
    pPhoto out blob
);
procedure set_photo(
    pId in integer,
    pPhoto in blob
);    

PROCEDURE create_user_from_ldap(p_samaccountname IN VARCHAR2);

end;
/

show err;

CREATE OR REPLACE package body bosysadmin as

function officer_replaces(pId in integer) return cursor_t is
	rv cursor_t;
begin
	open rv for select o.login || ', ' || o.name name
	from officer_replacement r, officers o
	where r.replaced_by = pId and o.id = r.officer_id;
	return rv;
end;

-- Tagad bus originala
function get_replacers return cursor_t is
	rv cursor_t;
begin
	open rv for
	select o.id officerId, o.login login, o.name userName,
		r.replaced_by replacedBy, u.account_status account_status
	from (select id, upper(login) login, name from officers) o,
		sys.dba_users u, officer_replacement r
	where o.login = u.username and
		--0 != (select count(1) from sys.dba_role_privs where grantee = u.username and granted_role in ('RBOTELLER', 'RBOADMIN', 'RBOFAXMANAGER')) and
		o.id = r.officer_id(+);
	return rv;
end;

/*
function get_replacers return cursor_t is
    rv cursor_t;
begin
    open rv for
    select o.id officerId, o.login login, o.name userName,
        r.replaced_by replacedBy, u.account_status account_status
    from (select id, upper(login) login, name from officers) o,
        sys.dba_users u, officer_replacement r
    where o.login = u.username and
        1 < (
        select sum(nvl(aa, 0)) from (
             ( select nvl( count(p.grantee), 0) aa  from sys.dba_role_privs p where upper(p.grantee) = upper(o.login)  and p.granted_role in ('RBOTELLER', 'RBOADMIN', 'RBOFAXMANAGER') )
             union all
             ( select 1 aa from dual )
             )
             ) 
        and
        o.id = r.officer_id(+);
        
    select o.id officerId, o.login login, o.name userName,
        r.replaced_by replacedBy, u.account_status account_status
    from (select id, upper(login) login, name from officers) o,
        sys.dba_users u, officer_replacement r
    where o.login = u.username and
        u.username in (select grantee  from sys.dba_role_privs p where  p.granted_role in ('RBOTELLER', 'RBOADMIN', 'RBOFAXMANAGER'))
        and o.id = r.officer_id(+)  ;      
        
        --exception when others then
        --null;
    return rv;
end;
*/

/*
function get_replacers return cursor_t is
    rv cursor_t;
begin
    open rv for
    select o.id officerId, upper(o.login) login, o.name userName,
        r.replaced_by replacedBy, u.account_status account_status
    from 
        officers o
        , sys.dba_users u, officer_replacement r
        , sys.dba_role_privs p
    where o.login = u.username
          and p.grantee is not null
          and p.grantee = u.username
          and p.granted_role in ('RBOTELLER', 'RBOADMIN', 'RBOFAXMANAGER')
          and o.id = r.officer_id(+)
        ;
    return rv;
end;
*/
function get_officers(
	pLogin in varchar2,
	pName in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select * from (
		select o.id officerId,
			o.login login,
			o.name userName,
			o.reg_date regDate,
			o.phone phone,
			o.def_officer def_officer,
			u.username oraUser,
			u.account_status status,
			r.replaced_by replacedBy,
			dept_accnt_officer_id deptAcntId,
			nvl(gd.officer_name, '') || ' (' || nvl(gd.id, 0) || ')' dept,
            o.has_photo has_photo
		from (select id, upper(login) login, name, reg_date, phone, dept_accnt_officer_id, parent_department, def_officer, sign( DBMS_LOB.GETLENGTH(profile_image))has_photo from officers) o,
			sys.dba_users u,
			officer_replacement r,
			glb_dept_accnt_officer gd
		where o.login = u.username(+) and
			o.id = r.officer_id(+) and
			(pLogin is null or upper(o.login) like bocommon.prepare_like(pLogin)) and
			(pName is null or upper(o.name) like bocommon.prepare_like(pName)) and
			o.parent_department = gd.id(+)
	) attr, (
		select r.replaced_by repId, count(1) replaces
		from officer_replacement r
		group by r.replaced_by
	) cnt
	where attr.officerId = cnt.repId(+);
	return rv;
end;

function get_dept_list(pOfficer in integer) return cursor_t is
	rv cursor_t;
begin
	open rv for select gdo.officer_name || ' (' || gdo.id || ')' name
	from glb_dept_accnt_officer gdo
	where gdo.id not in
		(select io.dept_accnt_officer_id from officers io
		where (pOfficer is not null and io.id != pOfficer) and io.dept_accnt_officer_id is not null)
	order by gdo.officer_name;
	return rv;
end;

procedure load_officer(
	pId in out integer,
	pName out varchar2,
	pRepId out integer,
	pLogin out varchar2,
	pPersonalId out varchar2,
	pDeptId out varchar2,
	pPhone out varchar2,
	pMobile out varchar2,
	pEmail out varchar2,
	pRegDate out date,
	pParentDeptId out varchar2,
	pAvailPkgs out varchar2,
	pDefForCountry out varchar2,
	pHistory out cursor_t,
	pActual out cursor_t,
	pSkypeName out varchar2,
	pIsLdapUser out number
) is
	pCur cursor_t;
	attr varchar2(30);
	attrs varchar2(1024);
begin
	select
		o.id,
		o.name,
		r.replaced_by,
		upper(o.login),
		o.personal_id,
		o.dept_accnt_officer_id,
		o.phone,
		o.mobile_phone,
		o.email,
		o.reg_date,
		o.parent_department,
		o.def_officer,
		o.skype_name,
		o.is_ldap_user
	into
		pId,
		pName,
		pRepId,
		pLogin,
		pPersonalId,
		pDeptId,
		pPhone,
		pMobile,
		pEmail,
		pRegDate,
		pParentDeptId,
		pDefForCountry,
		pSkypeName,
		pIsLdapUser
	from
		officers o,
		officer_replacement r
	where
		o.id = r.officer_id(+) and
		o.id = pId;

	open pHistory for select
		h.change_date changeDate,
		nvl(o.name, o.login) changeOfficer,
		h.name name,
		h.personal_id personalId,
		h.dept_accnt_officer_id deptId,
		h.phone phone,
		h.mobile_phone mobile,
		h.email email,
		h.status_id accStatus,
		h.available_packages roles,
		h.parent_department parentDeptId,
		h.skype_name skypeName
	from 
		officer_history h,
		officers o
	where
		h.officer_id = pId and
		o.id(+) = h.change_officer_id;

	open pActual for select
		o.change_date changeDate,
		nvl(o1.name, o1.login) changeOfficer,
		o.name name,
		o.personal_id personalId,
		o.dept_accnt_officer_id deptId,
		o.phone phone,
		o.mobile_phone mobile,
		o.email email,
		u.account_status accStatus,
		o.parent_department parentDeptId,
		o.skype_name skypeName
	from 
		officers o,
		officers o1,
		sys.dba_users u
	where
		o.id = pId and
		o.login = u.username(+) and
		o1.id = o.change_officer_id;

	-- Available packages
	begin
		open pCur for select distinct(granted_role) 
		from sys.dba_role_privs 
		where 
			granted_role like 'RBO%' 
			and UPPER(grantee) = UPPER(pLogin);
		fetch pCur into attr;
		if pCur%FOUND then attrs := attr; end if;
		fetch pCur into attr;
		while pCur%FOUND and Length(attrs) + 2 + Length(attr) < 1024 Loop
			attrs := attrs||', '||attr;
			fetch pCur into attr;
		end loop;
		close pCur;
	exception when NO_DATA_FOUND then
		attrs := null;
	end;

	pAvailPkgs := attrs;

exception
	when NO_DATA_FOUND then
		pId := null;
end load_officer;

procedure update_officer(
	pId in integer,
	pName in varchar2,
	pRepId in integer,
	pLogin in varchar2,
	pPersonalId in varchar2,
	pDeptId in varchar2,
	pPhone in varchar2,
	pMobile in varchar2,
	pEmail in varchar2,
	pParentDeptId in varchar2,
	pDefForCountry in varchar2,
	pSkypeName in varchar2,
	pIsLdapUser in number
) is
	vId integer;
	pCur cursor_t;
	attrs varchar2(200);
	attr varchar2(30);
begin
	begin
		select id into vId from officers where id = pId;
	exception when NO_DATA_FOUND then
		vId := null;
	end;

	if pDefForCountry is not null then
		update officers set 
			def_officer = ''
		where def_officer = pDefForCountry;
	end if;
	
	if vId is null then
		insert into officers (
			id,
			name,
			phone,
			mobile_phone,
			email,
			personal_id,
			dept_accnt_officer_id,
			reg_date,
			login,
			change_officer_id,
			change_date,
			parent_department,
			def_officer,
			skype_name,
			is_ldap_user
		) values (
			unq_user_id_seq.NextVal,
			pName,
			pPhone,
			pMobile,
			pEmail,
			pPersonalId,
			pDeptId,
			SysDate,
			upper(pLogin),
			bocommon.officerId,
			SysDate,
			pParentDeptId,
			pDefForCountry,
			pSkypeName,
			pIsLdapUser
		);
	else
		-- Available packages
		begin
			open pCur for select distinct(granted_role) 
			from sys.dba_role_privs 
			where 
				granted_role like 'RBO%' 
				and UPPER(grantee) = UPPER(pLogin);
			fetch pCur into attr;
			if pCur%FOUND then attrs := attr; end if;
			fetch pCur into attr;
			while pCur%FOUND and Length(attrs) + 2 + Length(attr) < 200 Loop
				attrs := attrs||', '||attr;
				fetch pCur into attr;
			end loop;
			close pCur;
		exception when NO_DATA_FOUND then
			attrs := null;
		end;

		-- Oracle account status
		begin 
			select account_status into attr 
			from sys.dba_users 
			where username = upper(pLogin);
		exception when NO_DATA_FOUND then
			attr := 'NO ACCOUNT';
		end;

		-- Officer history    
		insert into officer_history (
			id,
			name,
			phone,
			mobile_phone,
			email,
			closure_date,
			personal_id,
			officer_id,
			status_id,
			AVAILABLE_PACKAGES,
			dept_accnt_officer_id, 
			login,
			change_date,
			change_officer_id,
			parent_department,
			skype_name
		) select 
			unq_officer_hist_id_seq.NextVal,
			name,
			phone,
			mobile_phone,
			email,
			closure_date,
			personal_id,
			id,
			attr, -- Status
			attrs, -- AVAILABLE_PACKAGES
			dept_accnt_officer_id,
			upper(login),
			change_date,
			change_officer_id,
			parent_department,
			skype_name
		from officers
		where id = pId;

		update officers set 
			name = pName, 
			phone = pPhone,
			mobile_phone = pMobile, 
			email = pEmail, 
			personal_id = pPersonalId, 
			dept_accnt_officer_id = pDeptId,
			Change_Date = SysDate, 
			Change_Officer_Id = bocommon.officerId,
			parent_department = pParentDeptId,
			def_officer = pDefForCountry,
			skype_name = pSkypeName,
			is_ldap_user = pIsLdapUser
		where id = pId;

		replace_officer(pId, pRepId);

		bocommon.log_event(pId, 60202, pLogin);
	end if;
	update digibo_parameters
	set value1 = to_char(sysdate, 'yyyymmddhh24miss')
	where name = 'UPDATE_PERMISSIONS';
end update_officer;


procedure replace_officer(
	pId in integer,
	pRepId in integer
) is
	vId integer;
	who varchar2(30);
	whom varchar2(30);
begin
	begin
		select replaced_by into vId from officer_replacement
		where officer_id = pId;
	exception when NO_DATA_FOUND then
		vId := 0;
	end;

	select upper(login) into whom from officers where id = pId;

	if vId != 0 and (pRepId is null or pRepId = 0) then
		-- Remove replacement
		select upper(login) into who from officers where id = vId;

		delete from officer_replacement
		where officer_id = pId;
			
		bocommon.log_event(pId, 60302, who || ' was replacing ' || whom);

	elsif vId != pRepId then
		-- Set replacement
		select upper(login) into who from officers where id = pRepId;

		delete from officer_replacement
		where officer_id = pId;

		insert into officer_replacement (
			officer_id,
			replaced_by,
			change_officer_id,
			change_date
		) values (
			pId,
			pRepId,
			bocommon.officerId,
			SysDate
		);
		bocommon.log_event(pId, 60301, who || ' now replacing ' || whom);
	end if;
end;

procedure update_roles(
	pId in integer,
	pLogin in varchar2,
	pRoles in varchar2
) is
	attr varchar2(1024);
begin
	select account_status into attr 
	from sys.dba_users 
	where username = upper(pLogin);
	-- SWB #2252
	update officers set 
		Change_Date = SysDate, 
		Change_Officer_Id = bocommon.officerId
	where id = pId;
	--
	insert into officer_history (
		id,
		name,
		phone,
		mobile_phone,
		email,
		closure_date,
		personal_id,
		officer_id,
		status_id,
		AVAILABLE_PACKAGES,
		dept_accnt_officer_id, 
		login,
		change_date,
		change_officer_id,
		parent_department
	) select 
		unq_officer_hist_id_seq.NextVal,
		name,
		phone,
		mobile_phone,
		email,
		closure_date,
		personal_id,
		id,
		attr,
		pRoles,
		dept_accnt_officer_id,
		login,
		change_date,
		change_officer_id,
		parent_department
	from officers
	where id = pId;
	bocommon.log_event(pId, 60202, pLogin);
	update digibo_parameters
	set value1 = to_char(sysdate, 'yyyymmddhh24miss')
	where name = 'UPDATE_PERMISSIONS';
end;

function get_logged return cursor_t is
	rv cursor_t;
begin
	open rv for select
		ol.ip_address || ':' || ol.ip_port address,
		ol.logged logged,
		o.id id,
		o.name name
	from officers_online ol, officers o
	where nvl( ol.type, 'BACKOFFICE') = 'BACKOFFICE'
          and o.id(+) = ol.officer_id;
	return rv;
end;

procedure get_photo(
    pId in integer,
    pPhoto out blob
) is
begin
  null;
  select profile_image into pPhoto from officers where id = pId; 
end;  
procedure set_photo(
    pId in integer,
    pPhoto in blob
) is
begin
  update officers
  set profile_image = pPhoto
  where id = pId
  ;
  commit;
  
end;  

PROCEDURE create_user_from_ldap(p_samaccountname IN VARCHAR2) IS
        retval       PLS_INTEGER;
        my_session   DBMS_LDAP.session;
        my_attrs     DBMS_LDAP.string_collection;
        my_message   DBMS_LDAP.message;
        my_entry     DBMS_LDAP.message;
        my_dn        VARCHAR2(4000);
        ldap_host    VARCHAR2(256) := 'dc1.parexgroup.net';
        ldap_port    VARCHAR2(256) := '389';
        ldap_user    VARCHAR2(256) := 'oracle-ad';
        ldap_passwd  VARCHAR2(256) := 'Vmun-pax8305';
        ldap_base    VARCHAR2(256) := 'dc=parexgroup,dc=net';
    BEGIN
        DBMS_LDAP.USE_EXCEPTION := TRUE;
    
        -- Start LDAP session
        my_session := DBMS_LDAP.init(ldap_host, ldap_port);
        retval := DBMS_LDAP.simple_bind_s(my_session, ldap_user, ldap_passwd);
    
        -- Only distinguishedName attribute
        my_attrs(1) := 'distinguishedName';
    
        -- Search for the specific account
        retval := DBMS_LDAP.search_s(
                my_session,
                ldap_base,
                DBMS_LDAP.SCOPE_SUBTREE,
                '(&(objectClass=user)(sAMAccountName=' || p_samaccountname || '))',
                my_attrs,
                0,
                my_message
            );
    
        -- Read DN
        my_entry := DBMS_LDAP.first_entry(my_session, my_message);
    
        IF my_entry IS NOT NULL THEN
            my_dn := DBMS_LDAP.get_dn(my_session, my_entry);
    
             EXECUTE IMMEDIATE
                    'CREATE USER "' || UPPER(p_samaccountname) || '"' ||
                    ' IDENTIFIED GLOBALLY AS ''' || my_dn || '''' ||
                    ' DEFAULT TABLESPACE IBANK' ||
                    ' TEMPORARY TABLESPACE TEMP' ||
                    ' PROFILE IBBOOFFICERPROFILE' ||
                    ' ACCOUNT UNLOCK';
    
        ELSE
            RAISE_APPLICATION_ERROR(-20001, 'User not found in LDAP: ' || p_samaccountname);
        END IF;
    
        retval := DBMS_LDAP.unbind_s(my_session);
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                IF my_session IS NOT NULL THEN
                    retval := DBMS_LDAP.unbind_s(my_session);
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
    
            RAISE_APPLICATION_ERROR(
                    -20002,
                    'Error in create_user_from_ldap: ' || SQLERRM
                );
    END;

end;
/


show err;
