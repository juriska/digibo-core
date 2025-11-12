CREATE OR REPLACE package body IB.BOHelpDesk as

function execute_by_filter(
	pCursorName in integer
) return cursor_t is
	cursor_name integer := pCursorName;
	rv cursor_t;
	row helpdesk_t;
	rows_processed integer;
	rowset helpdesk_set_t := helpdesk_set_t();
	channelId number(10);
	login varchar2(60);
	authDev varchar2(50); -- bija 24
	userName varchar2(210);
	phone varchar2(120);
	mobilePhone varchar2(120);
	personalId varchar2(35);
	userAgent varchar2(255);
	regDate date;
	status number(2);
	channel number(2);
    sms_client varchar2(255); -- added 2014-09-01
begin
	dbms_sql.define_column(cursor_name,  1, channelId);
	dbms_sql.define_column(cursor_name,  2, login, 60);
	dbms_sql.define_column(cursor_name,  3, authDev, 50); -- bija 24
	dbms_sql.define_column(cursor_name,  4, userName, 210);
	dbms_sql.define_column(cursor_name,  5, phone, 120);
	dbms_sql.define_column(cursor_name,  6, mobilePhone, 120);
	dbms_sql.define_column(cursor_name,  7, personalId, 35);
	dbms_sql.define_column(cursor_name,  8, userAgent, 255);
	dbms_sql.define_column(cursor_name,  9, regDate);
	dbms_sql.define_column(cursor_name, 10, status);
	dbms_sql.define_column(cursor_name, 11, channel);
    dbms_sql.define_column(cursor_name, 12, sms_client, 255); -- added 2014-09-01

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name,  1, channelId);
		dbms_sql.column_value(cursor_name,  2, login);
		dbms_sql.column_value(cursor_name,  3, authDev);
		dbms_sql.column_value(cursor_name,  4, userName);
		dbms_sql.column_value(cursor_name,  5, phone);
		dbms_sql.column_value(cursor_name,  6, mobilePhone);
		dbms_sql.column_value(cursor_name,  7, personalId);
		dbms_sql.column_value(cursor_name,  8, userAgent);
		dbms_sql.column_value(cursor_name,  9, regDate);
		dbms_sql.column_value(cursor_name, 10, status);
		dbms_sql.column_value(cursor_name, 11, channel);
        dbms_sql.column_value(cursor_name, 12, sms_client); -- added 2014-09-01
		row := helpdesk_t(
			channelId,
			login,
			authDev,
			userName,
			phone,
			mobilePhone,
			personalId,
			userAgent,
			regDate,
			status,
			channel
            , sms_client
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as helpdesk_set_t));
	return rv;

exception when others then
	if dbms_sql.is_open(cursor_name) then
		dbms_sql.close_cursor(cursor_name);
	end if;
	raise;
end;

function find_user_channel(
	pLogin in varchar2,
	pAuthDev in varchar2,
	pUserName in varchar2,
	pPersonalId in varchar2
) return cursor_t is
	userLogin varchar2(1000) := bocommon.prepare_like(pLogin);
	userName varchar2(1000) := bocommon.prepare_like(pUserName);
	personalID varchar2(1000) := bocommon.prepare_like(pPersonalID);
	rq varchar2(32767);
	cursor_name integer;
begin
	rq := 'select /* BOHelpDesk.find_user_channel */ * from (select';
	if userLogin is not null or pAuthDev is not null then
		rq := rq || ' /*+ INDEX (u PK_USER) */';
	else
		rq := rq || ' /*+ INDEX (w IDX_WOC_USER) */';
	end if;
	rq := rq || ' w.id channelId,';
	rq := rq || ' w.login login,';
	--rq := rq || ' w.cdevice_serial_number authDev,';
    rq := rq || ' w.cdevice_serial_number  || decode(w.cdevice_serial_number_2, null, '''', ''; '' ||w.cdevice_serial_number_2 ) authDev,';
    --w.cdevice_serial_number || decode(w.cdevice_serial_number_2, null, '', '; ' ||w.cdevice_serial_number_2 ),
	rq := rq || ' u.name userName,';
    --rq := rq || ' (select distinct substr( c.id || '': '' || c.name.name_en, 0, 80) from user_document_rights udr, cusd c where udr.woc_id = w.id and c.id = udr.customer_id and w.channel_id = 6 and rownum <= 1) userName,'; -- just for test
	rq := rq || ' u.phone phone,';
	rq := rq || ' u.mobile_phone mobilePhone,';
	rq := rq || ' u.personal_id personalId,';
	rq := rq || ' w.user_agent userAgent,';
	rq := rq || ' u.reg_date regDate,';
	--rq := rq || ' w.status_id status,';
    rq := rq || ' decode( w.status_id, 1, decode( sign(w.blocked_till_date - sysdate), 1, 2, 1), w.status_id ) status,';
	rq := rq || ' w.channel_id channel';
    rq := rq || ', (select distinct substr( c.id || '': '' || c.name.name_en, 0, 80) from user_document_rights udr, cusd c where udr.woc_id = w.id and c.id = udr.customer_id and w.channel_id = 6 and rownum <= 1) sms_client'; -- added 2014-09-01
	rq := rq || ' from ways_of_connection w, v$users u';
	rq := rq || ' where';
	if userLogin is not null or pAuthDev is not null then
		-- RBA_CONST.INET, RBA_CONST.SMS
		rq := rq || ' w.channel_id in (5, 6, 27, 28, 29)';
		rq := rq || ' and w.substatus_id not in (2, 3, 4)';
		if userLogin is not null then
			--rq := rq || ' and upper(w.login) like :UserLogin';
            rq := rq || ' and ( upper(w.login) like :UserLogin or w.parent_id in (select w2.id from ways_of_connection w2 where upper(w2.login) = :UserLogin) )';
		end if;
		if pAuthDev is not null then
            rq := rq || ' and (w.cdevice_serial_number = :AuthDev or w.cdevice_serial_number_2 = :AuthDev)';
		end if;
		rq := rq || ' and u.id = w.user_id';
		if userName is not null then
			rq := rq || ' and upper(u.name) like :UserName';
		end if;
		if personalID is not null then
			rq := rq || ' and upper(u.personal_id) like :PersonalID';
		end if;
	else
		if userName is not null then
			rq := rq || ' upper(u.name) like :UserName';
			if personalID is not null then
				rq := rq || ' and';
			end if;
		end if;
		if personalID is not null then
			rq := rq || ' upper(u.personal_id) like :PersonalID';
		end if;
		rq := rq || ' and w.user_id = u.id';
		rq := rq || ' and w.channel_id in (5, 6, 27, 28, 29)';
		rq := rq || ' and w.substatus_id not in (2, 3, 4)';
	end if;
	rq := rq || ') where rownum <= :ResultSetSize';
	cursor_name := dbms_sql.open_cursor;
	dbms_sql.parse(cursor_name, rq, dbms_sql.native);
	dbms_sql.bind_variable(cursor_name, ':ResultSetSize', bocommon.ResultSetSize);
	if userLogin is not null then
		dbms_sql.bind_variable(cursor_name, ':UserLogin', userLogin);
	end if;
	if pAuthDev is not null then
		dbms_sql.bind_variable(cursor_name, ':AuthDev', pAuthDev);
	end if;
	if userName is not null then
		dbms_sql.bind_variable(cursor_name, ':UserName', userName);
	end if;
	if personalID is not null then
		dbms_sql.bind_variable(cursor_name, ':PersonalID', personalID);
	end if;
	return execute_by_filter(cursor_name);
end;

function load_log(
	pUserId in varchar2,
	pWocId in varchar2
) return cursor_t is
	cursor c1 (p_channel_id number) is select /* BOHelpDesk.load_log */ * from (select
		a.id id,
		a.event_type_id eventId,
		a.event_date eventDate,
		a.details details,
		a.session_id sessionId
	from audit_log a
	where a.user_child_id = pUserId and
		( p_channel_id = 5 and a.woc_child_id is null or a.woc_child_id = pWocId) and (
			(a.event_type_id between 10100 and 10699) or
			(a.event_type_id between 10800 and 10899) or
			(a.event_type_id between 14100 and 14199) or
			(a.event_type_id between 20100 and 20199) or
			(a.event_type_id between 20400 and 20499) or
			(a.event_type_id between 20700 and 20799) or
			(a.event_type_id between 40100 and 40199) or
			(a.event_type_id between 41100 and 41199) or
			(a.event_type_id between 42100 and 42199) or
			(a.event_type_id between 60100 and 60199)
		)
		order by a.event_date desc
	) where rownum <= bocommon.HelpDeskAuditLogSize;

	r1 c1%rowtype;
	r2 helpdesk_log_t := helpdesk_log_t(null, null, null, null, null, null, null, null, null);
	set2 helpdesk_log_set_t := helpdesk_log_set_t();

	rv cursor_t;
    v_channel_id number;
begin
    select min( channel_id) into v_channel_id from ways_of_connection where id = pWocId;   
	for r1 in c1 (v_channel_id) loop
		r2.id        := r1.id;
		r2.eventId   := r1.eventId;
		r2.eventDate := r1.eventDate;
		r2.details   := r1.details;
		r2.sessionId := r1.sessionId;
		set2.extend;
		set2(set2.count) := r2;
	end loop;
	if nvl(set2.count, 0) > 0 then
		for i in set2.first .. set2.last loop
			r2 := set2(i);

			select et.id || ' ' || nvl(trim(decode(bocommon.LanguageId,
				0, et.name.name_lv,
				1, et.name.name_en,
				2, et.name.name_ru,
				3, et.name.extra_1,
				4, et.name.extra_2,
				5, et.name.extra_3,
				et.name.name_en)), et.name.name_en) eventName
			into set2(i).eventName
			from event_types et
			where et.id = r2.eventId;

			select nvl(trim(decode(bocommon.LanguageId,
				0, et.name.name_lv,
				1, et.name.name_en,
				2, et.name.name_ru,
				3, et.name.extra_1,
				4, et.name.extra_2,
				5, et.name.extra_3,
				et.name.name_en)), et.name.name_en) eventGroup
			into set2(i).eventGroup
			from event_types et
			where r2.eventId - Mod(r2.eventId, 100) = et.id;

			select o.name officer, s.ip_address host
			into set2(i).officer, set2(i).host
			from session_log s, officers o
			where r2.sessionId = s.id(+) and s.user_id = o.id(+);

		end loop;
	end if;

	open rv for select * from table(cast(set2 as helpdesk_log_set_t));

	return rv;
end;

function set_password(
	pChannelId in varchar2,
	pUserId in varchar2,
	pPassword in varchar2
) return integer is begin
	savepoint old_pswd;

	update ways_of_connection
	set
		password = pPassword,
		invalid_attempts_count = RBA_CONST.INV_ATMPTS_COUNT,
		expiry_date = SysDate - 1,
        	password_change_skip_count = 0,
  	        password_salt = null,
		password_type = 'MD5'
	where
		id = pChannelId;

	bocommon.log_event(pUserId, 60103, '', pChannelId);
	return 0;
exception when others then
	rollback to old_pswd;
	return 1;
end;

function load_user_channel(
	pId in out number,
	pLogin out varchar2,
	pAuthDev out varchar2,
	pStatus out number,
	pSubStatus out number,
	pUserId out varchar2,
	pUserName out varchar2,
	pPersonalId out varchar2,
	pPhone out varchar2,
	pMobile out varchar2,
	pFax out varchar2,
	pEmail out varchar2,
	pStreet out varchar2,
	pCity out varchar2,
	pCountry out varchar2,
	pZip out varchar2,
	pRegDate out date,
    pPasswordChageAllowed out int
    , pHasCronto out int
    , pPassword out varchar2
) return cursor_t is
	rv cursor_t;
    v_blocked_till_date date;
begin
   	select
		w.login,
		w.cdevice_serial_number || decode(w.cdevice_serial_number_2, null, '', '; ' ||w.cdevice_serial_number_2 ),
		w.status_id,
		w.substatus_id,
		u.id,
		u.name,
		u.personal_id,
		u.street,
		u.city,
		u.country_id,
		u.zip_code,
		u.phone,
		u.mobile_phone,
		u.fax,
		u.email,
		u.reg_date,
        decode( w.cdevice_type_id,
                1,1,
                2,1,
                4,1,
                5,1,
                9,1,
                0)
         , decode( w.cdevice_type_id, 9, 1, decode( w.cdevice_type_id_2, 9, 1, 0)) 
         , decode( w.channel_id, 6, w.password, '')
         , blocked_till_date
	into
		pLogin,
		pAuthDev,
		pStatus,
		pSubStatus,
		pUserId,
		pUserName,
		pPersonalId,
		pStreet,
		pCity,
		pCountry,
		pZip,
		pPhone,
		pMobile,
		pFax,
		pEmail,
		pRegDate,
        pPasswordChageAllowed
        , pHasCronto
        , pPassword
        , v_blocked_till_date
	from v$users u, ways_of_connection w
	where w.id = pId and w.user_id = u.id;

    if pStatus = 1 and v_blocked_till_date > sysdate then
       pStatus := 2;
    end if;
    
	open rv for select
		c.cusd_id pGlbCustId
	from v$customer_globus_restrictions c
	where c.woc_id = pId;

	return rv;
exception
	when no_data_found then
		pId := null;
end;

procedure load_auth_info(
	pId in out number,
	pStdQ out number,
	pSpecQ out varchar2,
	pAnswer out varchar2
) is
	uid users.id%TYPE;
    is_agreement_in_globus number;
    cnt integer;
    pId_mod number;
    v_channel_id number;
begin

    select parent_id, channel_id into pId_mod, v_channel_id from ways_of_connection where id = pId;
    if pId_mod is null then
       pId_mod := pId;
    end if;
    
    select count(1)
    into is_agreement_in_globus
    from glb_rb_contract
    where woc_id = pId_mod and is_visible > 0;

    if ( is_agreement_in_globus > 0 ) then
        select
            u.id,
            0,
            w.special_question,
            w.answer
        into
            uid,
            pStdQ,
            pSpecQ,
            pAnswer
        from v$users u, ways_of_connection w
        where w.id = pId_mod and w.user_id = u.id;

    else
        select
            u.id,
            nvl(u.standard_question_id, 0),
            u.special_question,
            u.answer
        into
            uid,
            pStdQ,
            pSpecQ,
            pAnswer
        from v$users u, ways_of_connection w
        where w.id = pId_mod and w.user_id = u.id;
    end if;
/*
-- When IB agreement is registered in GLOBUS, there are no secret Q and A in users
        if pAnswer is null then
            select count(1)
            into cnt
            from ways_of_connection w_sms
                 , ways_of_connection w_ib
            where w_sms.id = pId_mod
                      and w_ib.id = w_sms.parent_id
                      and w_ib.channel_id = 5
                      and w_sms.channel_id = 6
                      ; 
            if cnt = 1 then
                select  w_ib.special_question,
                          w_ib.answer
                into pSpecQ,
                      pAnswer
                from ways_of_connection w_sms
                     , ways_of_connection w_ib
                where w_sms.id = pId_mod
                          and w_ib.id = w_sms.parent_id
                          and w_ib.channel_id = 5
                          and w_sms.channel_id = 6
                          ;             
            end if;       
        end if;
*/
	bocommon.log_event(uid, 60106, '', pId);
    if pId <> pId_mod then
       bocommon.log_event(uid, 60106, '', pId_mod);
    end if;
exception
	when no_data_found then
		pId := null;
end;

procedure set_lock(
	pChannelId in varchar2,
	pUserId in varchar2,
	pStatus in number,
	pSubStatus in number
) is
	new_invalid_attempts_count integer;
    v_channel_id number;
    v_parent_id number;
    cursor woc_cursor ( p_parent_id number) is 
           select id
           from ways_of_connection
           where parent_id = p_parent_id; 
begin
	select invalid_attempts_count, channel_id, parent_id
	into new_invalid_attempts_count, v_channel_id, v_parent_id
	from ways_of_connection
	where id = pChannelId;
	if RBA_CONST.USER_ACTIVE = pStatus then
		new_invalid_attempts_count := RBA_CONST.INV_ATMPTS_COUNT;
	end if;
    
    if v_channel_id in (28, 29) and  RBA_CONST.USER_INACTIVE = pStatus then -- for quick bal, etc - blocking all by parent - all channels set up via internetbank
       null;
       update ways_of_connection
        set
            invalid_attempts_count = new_invalid_attempts_count,
            status_id = pStatus,
            substatus_id = pSubStatus
        where
            parent_id = v_parent_id
            and channel_id in ( 28, 29)
            and status_id = RBA_CONST.USER_ACTIVE;
            
            for rec in woc_cursor(v_parent_id) loop 
                bocommon.log_event(pUserId, 60104, '', rec.id );
            end loop;
    else -- old way
        update ways_of_connection
        set
            invalid_attempts_count = new_invalid_attempts_count,
            status_id = pStatus,
            substatus_id = pSubStatus
            , blocked_till_date = null
        where
            id = pChannelId;
            
        if RBA_CONST.USER_INACTIVE = pStatus then
           bocommon.log_event(pUserId, 60104, '', pChannelId);
        else
           bocommon.log_event(pUserId, 60105, '', pChannelId);
        end if;
        
        if v_channel_id = 5 and  RBA_CONST.USER_INACTIVE = pStatus then -- When blocking IB, then blocking all mobile things too
           update ways_of_connection
            set
                invalid_attempts_count = new_invalid_attempts_count,
                status_id = pStatus,
                substatus_id = pSubStatus
            where
                parent_id = pChannelId
                and channel_id in ( 28, 29)
                and status_id = RBA_CONST.USER_ACTIVE;
            
            for rec in woc_cursor(pChannelId) loop 
                bocommon.log_event(pUserId, 60104, '', rec.id );
            end loop;
        end if;
    
    end if;


end;

procedure reset_stolen(pChannelId in varchar2) is
begin
	update ways_of_connection
	set
		substatus_id = 0
	where
		id = pChannelId;
end;

end;
/
