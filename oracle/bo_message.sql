/************************** RBA database stored procedures ********************
 *    $Author: ury $
 *   $RCSfile: bo_message.sql,v $
 *  $Revision: 1.72 $
 *        $Id: bo_message.sql,v 1.72 2019/01/04 07:51:57 ury Exp $
 *
 ********* Copyright (c) 2001 Parex Bank, Latvia. All rights reserved *********/

CREATE OR REPLACE package BOMessage as

EVENT_STATUS_CHANGED constant int := 60501;
EVENT_CREATED constant int := 60502;

Success  constant int := 0;
LockedBy constant int := 1; -- see OfficerName and OfficerPhone;
Locked   constant int := 2; -- non BO lock;
Error    constant int := 3;

type cursor_t is ref cursor;

function find_messages(
	pUserId in varchar2,
	pUserName in varchar2,
	pLogin in varchar2,
	pOfficerId in number,
	pMsgId in varchar2,
	pMessage in varchar2,
	pType in varchar2,
	pCustId in varchar2,
	pCustName in varchar2,
	pStatuses in varchar2,
	pClassId in number,
	pDateFrom in date,
	pDateTill in date,
	pChannelId in varchar2
) return cursor_t;

function find_current(
	pClasses in varchar2
) return cursor_t;

function load_user_data(
	pWocId in number,
	pMsgId in varchar2,
	pUserName out varchar2,
	pLogin out varchar2,
	pFromCust out varchar2,
  	pCustId out number
) return cursor_t;

function load_communication(
	pWocId in number
) return cursor_t;

function set_lock(
	pLockName in varchar2,
	pId in out varchar2,
	pOfficerName out varchar2,
	pOfficerPhone out varchar2
) return int;

procedure set_seen(pId in number);

procedure answer(
	pId in number,
	pWocId in number,
	pStatus in number,
	pClassId in number,
	pMessage in varchar2
);

procedure forward(
	pId in number,
	pClassId in number
);
function get_addressee_woc(
    pWocId in number,
    pAddresseeWocId out ways_of_connection.id%TYPE
) return number;

end;
/

show err;

CREATE OR REPLACE package body BOMessage as

function find_by_id(
	pMsgId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		/* BOMessage.find_by_id */
		/*+ INDEX (w PK_WAYS_OF_CONNECTION) */
		m.id msgId,
		w.id wocId,
		w.channel_id channel,
		m.create_date postDate,
		w.login login,
		substr(m.body, 1, 50) message,
		m.officer_id officerId,
		m.status_id status,
		m.class_id classId,
        (select c.sector from cusd c where c.id = m.customer_id)sector,
        (select c.segment from cusd c where c.id = m.customer_id)segment,
        (select decode( c.sector, 6100, 'Y', '') from cusd c where c.id = m.customer_id)is_employee
	from messages m, ways_of_connection w
	where m.id = pMsgId and	w.id(+) = m.woc_id;
	return rv;
end;

function execute_by_filter(
	pCursorName in integer
) return cursor_t is
	cursor_name integer := pCursorName;
	rv cursor_t;
	row message_t;
	rows_processed integer;
	rowset message_set_t := message_set_t();
	msgId number(9);
	wocId number(10);
	channel number(2);
	postDate date;
	login varchar2(60);
	message varchar2(100); --changed from 50 to 100
	officerId number(10);
	status number(2);
	classId number(3);
    sector number(5);
    segment varchar2(32);
    is_employee varchar2(32);
begin
	dbms_sql.define_column(cursor_name,  1, msgId);
	dbms_sql.define_column(cursor_name,  2, wocId);
	dbms_sql.define_column(cursor_name,  3, channel);
	dbms_sql.define_column(cursor_name,  4, postDate);
	dbms_sql.define_column(cursor_name,  5, login, 60);
	dbms_sql.define_column(cursor_name,  6, message, 100); --changed from 50 to 100
	dbms_sql.define_column(cursor_name,  7, officerId);
	dbms_sql.define_column(cursor_name,  8, status);
	dbms_sql.define_column(cursor_name,  9, classId);
    dbms_sql.define_column(cursor_name,  10, sector);
    dbms_sql.define_column(cursor_name,  11, segment, 32);
    dbms_sql.define_column(cursor_name,  12, is_employee, 32);

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name,  1, msgId);
		dbms_sql.column_value(cursor_name,  2, wocId);
		dbms_sql.column_value(cursor_name,  3, channel);
		dbms_sql.column_value(cursor_name,  4, postDate);
		dbms_sql.column_value(cursor_name,  5, login);
		dbms_sql.column_value(cursor_name,  6, message);
		dbms_sql.column_value(cursor_name,  7, officerId);
		dbms_sql.column_value(cursor_name,  8, status);
		dbms_sql.column_value(cursor_name,  9, classId);
        dbms_sql.column_value(cursor_name,  10, sector);
        dbms_sql.column_value(cursor_name,  11, segment);
        dbms_sql.column_value(cursor_name,  12, is_employee);
		row := message_t(
			msgId,
			wocId,
			channel,
			postDate,
			login,
			message,
			officerId,
			status,
			classId,
            sector,
            segment,
            is_employee
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as message_set_t));
	return rv;

exception when others then
	if dbms_sql.is_open(cursor_name) then
		dbms_sql.close_cursor(cursor_name);
	end if;
	raise;
end;

function find_by_filter(
	pUserId in varchar2,
	pUserName in varchar2,
	pLogin in varchar2,
	pOfficerId in number,
	pMessage in varchar2,
	pType in varchar2,
	pCustId in varchar2,
	pCustName in varchar2,
	pStatuses in varchar2,
	pClassId in number,
	pDateFrom in date,
	pDateTill in date,
    pChannelId in varchar2
) return cursor_t is
	rq varchar2(32767);
	cursor_name integer;
	custName varchar2(1024) := bocommon.prepare_like(pCustName);
	userLogin varchar2(1024) := bocommon.prepare_like(pLogin);
	userName varchar2(1024) := bocommon.prepare_like(pUserName);
	messageText varchar2(1024) := bocommon.prepare_like(pMessage);
	remoteId integer := BODocuments.get_remote_officer(pOfficerId);
	useWocId integer := 0;
  classIds varchar2(10);
  channelIds varchar2(15);
begin
	if pCustId is not null or
		userName is not null or
		pUserId is not null or
		custName is not null or remoteId > 0 or
		userLogin is not null then
		delete from tmp_request_data;
		useWocId := 1;
	end if;

	if pCustId is not null then
		insert into tmp_request_data (requested_id, filter1)
		select /* BOMessage.find_by_filter.1 */ cgr.woc_id, '1'
		from v$customer_globus_restrictions cgr
		where cgr.cusd_id = pCustId;
	end if;

	if userName is not null then
		insert into tmp_request_data (requested_id, filter1)
		select /* BOMessage.find_by_filter.2 */ w.id, '2'
		from v$users u, ways_of_connection w
		where upper(u.name) like userName and
			w.user_id = u.id and
			w.channel_id in (5, 21, 28, 29);
	end if;

	if pUserId is not null then
		insert into tmp_request_data (requested_id, filter1)
		select /* BOMessage.find_by_filter.3 */ w.id, '3'
		from ways_of_connection w
		where w.user_id = pUserId and
			w.channel_id in (5, 21);
	end if;

	if custName is not null or remoteId > 0 then
		if custName is not null and remoteId > 0 then
			insert into tmp_request_data (requested_id, filter1)
			select /* BOMessage.find_by_filter.4 */ cgr.woc_id, '4'
			from cusd c, v$customer_globus_restrictions cgr
			where c.remote_officers.contains(remoteId) = 1 and
				c.name.is_like(custName) = 1 and
				cgr.cusd_id = c.id;
		elsif custName is not null then
			insert into tmp_request_data (requested_id, filter1)
			select /* BOMessage.find_by_filter.4 */ cgr.woc_id, '4'
			from cusd c, v$customer_globus_restrictions cgr
			where c.name.is_like(custName) = 1 and
				cgr.cusd_id = c.id;
		elsif remoteId > 0 then
			insert into tmp_request_data (requested_id, filter1)
			select /* BOMessage.find_by_filter.4 */ cgr.woc_id, '4'
			from cusd c, v$customer_globus_restrictions cgr
			where c.remote_officers.contains(remoteId) = 1 and
				cgr.cusd_id = c.id;
		end if;
	end if;

	if userLogin is not null then
		insert into tmp_request_data (requested_id, filter1)
		select /* BOMessage.find_by_filter.5 */ w.id, '5'
		from ways_of_connection w
		where upper(w.login) like userLogin and
			w.channel_id in (5, 21, 28, 29);
	end if;

  if pClassId != 0 then
    classIds := TO_CHAR(pClassId);
    if pClassId = RBA_CONST.MSG_PERSONAL_OFFICER then
      classIds := classIds || ',' || RBA_CONST.MSG_CITADELE_BANK;
    end if;
  end if;

	rq := rq || 'select /* BOMessage.find_by_filter */';
--	if useWocId = 1 then
--		rq := rq || ' /*+ INDEX (m IDX_MESSAGES_WOC_ID) */';
--	else
--		rq := rq || ' /*+ INDEX (m IDX_MSG_CREATE_DATE) */';
--	end if;
--	rq := rq || ' /*+ INDEX (w PK_WAYS_OF_CONNECTION) */';
	rq := rq || ' m.id msgId,';
	rq := rq || ' w.id wocId,';
	--rq := rq || ' w.channel_id channel,';
    rq := rq || ' decode( m.storm_project, ''CIMO'', 28,  w.channel_id) channel,';
	rq := rq || ' m.create_date postDate,';
	rq := rq || ' w.login login,';
	rq := rq || ' substr(m.body, 1, 50) message,';
	rq := rq || ' m.officer_id officerId,';
	rq := rq || ' m.status_id status,';
	rq := rq || ' m.class_id classId,';
    rq := rq || '(select c.sector from cusd c where c.id = m.customer_id)sector,';
    rq := rq || '(select c.segment from cusd c where c.id = m.customer_id)segment,';
    rq := rq || '(select decode( c.sector, 6100, ''Y'', '''') from cusd c where c.id = m.customer_id)is_employee';
	rq := rq || ' from messages m, ways_of_connection w';
	rq := rq || ' where rownum <= :ResultSetSize';
	if useWocId = 1 then
		useWocId := 0;
		rq := rq || ' and m.woc_id in (';
		if pCustId is not null then
			rq := rq || ' select distinct requested_id';
			rq := rq || ' from tmp_request_data';
			rq := rq || ' where filter1 = ''1''';
			useWocId := 1;
		end if;
		if userName is not null then
			if useWocId = 1 then
				rq := rq || ' intersect';
			end if;
			rq := rq || ' select distinct requested_id';
			rq := rq || ' from tmp_request_data';
			rq := rq || ' where filter1 = ''2''';
			useWocId := 1;
		end if;
		if pUserId is not null then
			if useWocId = 1 then
				rq := rq || ' intersect';
			end if;
			rq := rq || ' select distinct requested_id';
			rq := rq || ' from tmp_request_data';
			rq := rq || ' where filter1 = ''3''';
			useWocId := 1;
		end if;
		if custName is not null or remoteId > 0 then
			if useWocId = 1 then
				rq := rq || ' intersect';
			end if;
			rq := rq || ' select distinct requested_id';
			rq := rq || ' from tmp_request_data';
			rq := rq || ' where filter1 = ''4''';
			useWocId := 1;
		end if;
		if userLogin is not null then
			if useWocId = 1 then
				rq := rq || ' intersect';
			end if;
			rq := rq || ' select distinct requested_id';
			rq := rq || ' from tmp_request_data';
			rq := rq || ' where filter1 = ''5''';
			useWocId := 1;
		end if;
		rq := rq || ' )';
	end if;
	rq := rq || ' and m.create_date between :DateFrom and :DateTill';
	if pClassId != 0 then
		rq := rq || ' and m.class_id in (' || classIds || ') ';
	end if;
	if pType is not null then
		rq := rq || ' and upper(m.type) = :MessageType';
	end if;
	if pStatuses is not null then
		rq := rq || ' and m.status_id in (' || pStatuses || ')';
	end if;
	if messageText is not null then
		rq := rq || ' and upper(m.body) like :MessageBody';
	end if;
	rq := rq || ' and w.id = m.woc_id';
	
	if pChannelId is not null then
		if pChannelId = '28' then
			rq := rq || ' and m.storm_project = ''CIMO''';
		elsif pChannelId = '5' then
			rq := rq || ' and w.channel_id = 5 and m.storm_project != ''CIMO''';
		else
			rq := rq || ' and w.channel_id in (' || pChannelId || ')';
		end if;	
	else 
		rq := rq || ' and w.channel_id in (5, 21, 28, 29)';
	end if;	

	cursor_name := dbms_sql.open_cursor;

	dbms_sql.parse(cursor_name, rq, dbms_sql.native);
	dbms_sql.bind_variable(cursor_name, ':ResultSetSize', bocommon.ResultSetSize);
	dbms_sql.bind_variable(cursor_name, ':DateFrom', pDateFrom);
	dbms_sql.bind_variable(cursor_name, ':DateTill', pDateTill);
	/*
  if pClassId != 0 then
		dbms_sql.bind_variable(cursor_name, ':ClassID', pClassId);
	end if;
  */
	if pType is not null then
		dbms_sql.bind_variable(cursor_name, ':MessageType', pType);
	end if;
	if messageText is not null then
		dbms_sql.bind_variable(cursor_name, ':MessageBody', messageText);
	end if;

	return execute_by_filter(cursor_name);
end;

function find_messages(
	pUserId in varchar2,
	pUserName in varchar2,
	pLogin in varchar2,
	pOfficerId in number,
	pMsgId in varchar2,
	pMessage in varchar2,
	pType in varchar2,
	pCustId in varchar2,
	pCustName in varchar2,
	pStatuses in varchar2,
	pClassId in number,
	pDateFrom in date,
	pDateTill in date,
	pChannelId in varchar2
) return cursor_t is
begin
	if pMsgId is not null then
		return find_by_id(pMsgId);
	end if;
	return find_by_filter(
		pUserId,
		pUserName,
		pLogin,
		pOfficerId,
		pMessage,
		pType,
		pCustId,
		pCustName,
		pStatuses,
		pClassId,
		pDateFrom,
		pDateTill,
		pChannelId
	);
end;

function find_current(
	pClasses in varchar2
) return cursor_t is
	rv cursor_t;
	t_dept num_table_type;
	t_classes num_table_type;
	my_locations varchar2_loc_type := bocommon.isDefaultFor;
begin
	bodocuments.get_remote_officers(t_dept);

	if pClasses is not null then
		t_classes := bocommon.str2table(pClasses);
	end if;

open rv for select
	/* BOMessage.find_current */
	m.id msgId,
	w.id wocId,
	decode( m.storm_project, 'CIMO', 23,  w.channel_id) channel,
	m.create_date postDate,
	w.login login,
	substr(m.body, 1, 50) message,
	m.officer_id officerId,
	m.status_id status,
	m.class_id classId,
    (select c.sector from cusd c where c.id = m.customer_id)sector,
    (select c.segment from cusd c where c.id = m.customer_id)segment,
    (select decode( c.sector, 6100, 'Y', '') from cusd c where c.id = m.customer_id)is_employee
from messages m, ways_of_connection w
where rownum <= bocommon.ResultSetSize and
	DECODE(DECODE(m.type, 'Q', m.status_id, NULL), 1, 1, 2, 1, 3, 1, NULL) = 1 and
	(pClasses is not null and m.class_id in
		(select * from table(cast(t_classes as num_table_type))) or
	((m.class_id = RBA_CONST.MSG_PERSONAL_OFFICER or m.class_id = RBA_CONST.MSG_CITADELE_BANK) and (
		exists (select distinct c.id from v$customer_globus_restrictions g, cusd c
			where ((m.customer_id is not null and g.cusd_id = m.customer_id) or
				g.woc_id = m.woc_id) and
				c.id = g.cusd_id and (c.remote_officers.get_id(m.location) in
					(select * from table(cast(t_dept as num_table_type))))) or
		(m.location in
			(select * from table(cast(my_locations as varchar2_loc_type))) and
		not exists (select distinct c.id
		from cusd c, officers o
		where c.id = m.customer_id and
			o.DEPT_ACCNT_OFFICER_ID =
				c.remote_officers.get_id(m.location)))
	))) and	w.id = m.woc_id;
	return rv;
end;

function load_user_data(
	pWocId in number,
	pMsgId in varchar2,
	pUserName out varchar2,
	pLogin out varchar2,
	pFromCust out varchar2,
  pCustId out number
) return cursor_t is
	rv cursor_t;
begin
	select /* BOMessage.load_user_data.1 */ u.name, w.login
	into pUserName, pLogin
	from ways_of_connection w, v$users u
	where w.user_id = u.id and w.id = pWocId;

	if pMsgId is not null then
		begin
			select
				/* BOMessage.load_user_data.2 */
				nvl(trim(decode(bocommon.LanguageId,
					0, c.name.name_lv,
					1, c.name.name_en,
					2, c.name.name_ru,
					3, c.name.extra_1,
					4, c.name.extra_2,
					5, c.name.extra_3,
					c.name.name_en
				)), c.name.name_en) || ' (' || c.id || ')', c.id
			into pFromCust, pCustId
			from messages m, cusd c
			where
				m.id = pMsgId and
				m.customer_id = c.id;
		exception when no_data_found then
			pFromCust := null;
		end;
	end if;

	open rv for select /* BOMessage.load_user_data.3 */
		nvl(trim(decode(bocommon.LanguageId,
			0, c.name.name_lv,
			1, c.name.name_en,
			2, c.name.name_ru,
			3, c.name.extra_1,
			4, c.name.extra_2,
			5, c.name.extra_3,
			c.name.name_en
		)), c.name.name_en) name,
		c.id id
	from
		v$customer_globus_restrictions cgr,
		cusd c
	where
		cgr.woc_id = pWocId and
		cgr.cusd_id = c.id and
		c.is_visible = 1;
	return rv;
end;

function set_lock(
	pLockName in varchar2,
	pId in out varchar2,
	pOfficerName out varchar2,
	pOfficerPhone out varchar2
) return int is
	vHandle varchar2(128);
	vRes int;
begin
	dbms_lock.allocate_unique(pLockName, vHandle);
	vRes := dbms_lock.request(lockhandle => vHandle, timeout => 0, release_on_commit => true);
	if vRes = 0 then
		begin
			if pId is not null then
				select id into pId
				from messages
				where id = pId for update nowait;
				return Success;
			else
				return Success;
			end if;
        	exception when bocommon.RESOURCE_BUSY_NOWAIT then
			vRes := dbms_lock.release(lockhandle => vHandle);
			vRes := 1;
		end;
	end if;
	if vRes = 1 then
		bocommon.get_locker(vHandle, pOfficerName, pOfficerPhone);
		if pOfficerName is null then
			return Locked;
		else
			return LockedBy;
		end if;
	end if;
	return Error;
end;

function load_communication(
	pWocId in number
) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		/* BOMessage.load_communication */
		/*+ INDEX (m IDX_MESSAGES_WOC_ID) */
		m.id id,
		nvl(m.question_id, m.id) qid,
		m.type type,
		m.status_id status,
		m.class_id classId,
		m.officer_id officerId,
		m.create_date postDate,
		m.body message,
		TO_CHAR( nvl( M.DOWNLOADABLE_REPORT_ID, 0 )) downloadableReportId
	from messages m
         , ways_of_connection w
	where 
         --m.woc_id = pWocId 
         M.WOC_ID = W.ID
         and ( w.id = pWocId or w.parent_id = pWocId )
         --and ( M.WOC_ID = W.ID or M.WOC_ID = W.parent_id)
         and exists (
                select /*+ INDEX (s IDX_MSG_STATUS) INDEX (PK_MESSAGES) */ 1
                from messages s
                where s.id = nvl(m.question_id, m.id) and
                    s.question_id is null and
                    s.status_id <= RBA_CONST.MSG_CLOSED_WITHOUT_ANSWER
                    )
	order by qid, m.id;
	return rv;
end;

procedure set_seen(pId in number) is begin
	update messages
	set status_id = RBA_CONST.MSG_SEEN
	where id = pId;
	bocommon.log_event(null, EVENT_STATUS_CHANGED, null, null, null, pId, null, RBA_CONST.MSG_SEEN);
end;

procedure answer(
	pId in number,
	pWocId in number,
	pStatus in number,
	pClassId in number,
	pMessage in varchar2
) is
        vSt int;
        vNewMsg messages.id%TYPE;
begin
	if RBA_CONST.MSG_NEW < pStatus then
		select status_id into vSt from messages where id = pId;
		update messages set status_id = pStatus where id = pId;
	end if;

	bocommon.log_event(
		null,
		EVENT_STATUS_CHANGED,
		'status changed. recipients WOC_ID = ' || pWocId,
		pWocId,
		null,
		pId,
		vSt,
		pStatus
	);

	if pStatus != RBA_CONST.MSG_CLOSED_WITHOUT_ANSWER then
		insert into messages (
			id,
			create_date,
			officer_id,
			body,
			status_id,
			class_id,
			woc_id,
			question_id,
			type
		) values (
			unq_message_id_seq.NextVal,
			SysDate,
			bocommon.officerId,
			pMessage,
			RBA_CONST.MSG_NEW,
			pClassId,
			pWocId,
			pId,
			'A'
		) returning id into vNewMsg;

		bocommon.log_event(
			null,
			EVENT_CREATED,
			'Recipients WOC_ID = ' || pWocId,
			pWocId,
			null,
			vNewMsg,
			null,
			null
		);
	end if;
end;

procedure forward(
	pId in number,
	pClassId in number
) is
begin
	update messages set
		class_id = pClassId,
		status_id = RBA_CONST.MSG_NEW
	where id = pId;
	bocommon.log_event(null, 60504, null, null, null, pId, null, null);
end;

function get_addressee_woc(
    pWocId in number,
    pAddresseeWocId out ways_of_connection.id%TYPE
) return number is
v_addressee_woc ways_of_connection.id%TYPE;
v_channel_id ways_of_connection.channel_id%TYPE;
v_parent_id ways_of_connection.parent_id%TYPE;
begin
  v_addressee_woc := pWocId;
  select channel_id, parent_id into v_channel_id, v_parent_id from ways_of_connection where id = pWocId;
  if v_channel_id in (28, 29)and v_parent_id is not null then
     v_addressee_woc := v_parent_id;
  end if;
  pAddresseeWocId := v_addressee_woc;
  return v_addressee_woc;
end;  


end;
/

show err;
