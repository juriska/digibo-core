create or replace package BOFindUsers as

type cursor_t is ref cursor;

function find_users(
	pUserId in varchar2,
	pGlobusUserId in varchar2,
	pUserName in varchar2,
	pPersonalId in varchar2,
	pOfficerId in number,
	pPhone in varchar2,
	pFax in varchar2,
	pEmail in varchar2,
	pChannelId in varchar2,
	pLogin in varchar2,
	pCDevNum in varchar2,
	pChannel in number,
	--
	pCustId in varchar2,
	pCustResidence in varchar2,
	pCustType in varchar2,
	--
	pDateFrom in date,
	pDateTill in date,
	pStatus in integer
) return cursor_t;

end;


/

show err;

create or replace
package body BOFindUsers as

function invariant(
	pChannelId in varchar2,
	pCustId in varchar2,
	pLogin in varchar2,
	pCDevNum in varchar2,
	pChannel in number,
	pStatus in integer,
	pCustResidence in varchar2,
	pCustType in varchar2,
	pOfficerId in number
) return integer is
	userLogin varchar2(1024) := bocommon.prepare_like(pLogin);
	deviceNo varchar2(1024) := bocommon.prepare_like(pCDevNum);
	remoteId integer := BODocuments.get_remote_officer(pOfficerId);
	rq varchar2(32767);
	add_and integer := 0;
	cursor_name integer;
	rows_processed integer;
begin
	if remoteId > 0 or
		pChannelId is not null or
		pCustId is not null or
		userLogin is not null or
		deviceNo is not null or
		pChannel > 0 or
		pStatus > 0 or
		pCustResidence is not null or
		pCustType is not null then
		delete from tmp_request_data;
	else
		return 0;
	end if;

	rq := 'insert into tmp_request_data (requested_id)';
	rq := rq || ' select /* BOFindUsers.invariant */ distinct user_id';
	rq := rq || ' from ways_of_connection w';
	rq := rq || ' where';
	if pChannelId is not null then
		rq := rq || ' w.id = :pChannelId';
		add_and := 1;
	end if;
	if pCustId is not null then
		if add_and = 1 then
			rq := rq || ' and';
		end if;
		rq := rq || ' w.id in (';
		rq := rq || ' select woc_id';
		rq := rq || ' from v$customer_globus_restrictions';
		rq := rq || ' where cusd_id = :pCustId';
		rq := rq || ' )';
		add_and := 1;
	end if;
	if userLogin is not null then
		if add_and = 1 then
			rq := rq || ' and';
		end if;
		rq := rq || ' upper(w.login) like :userLogin';
		add_and := 1;
	end if;
	if deviceNo is not null then
		if add_and = 1 then
			rq := rq || ' and';
		end if;
		rq := rq || ' ( upper(w.cdevice_serial_number) like :deviceNo or upper(w.cdevice_serial_number_2) like :deviceNo )';
		add_and := 1;
	end if;
	if pChannel > 0 then
		if add_and = 1 then
			rq := rq || ' and';
		end if;
		rq := rq || ' w.channel_id = :pChannel';
		add_and := 1;
	end if;
	if pStatus > 0 then
		if add_and = 1 then
			rq := rq || ' and';
		end if;
		rq := rq || ' w.status_id = :pStatus';
		add_and := 1;
	end if;
	if pCustResidence is not null or
		pCustType is not null or
		remoteId > 0 then
		if add_and = 1 then
			rq := rq || ' and';
		end if;
		rq := rq || ' w.id in (';
		rq := rq || ' select';
		rq := rq || ' /*+ INDEX (cgr PK_CUSTOMER_GLOBUS_RESTRICTION) */';
		rq := rq || ' /*+ INDEX (c PK_CUSD) */';
		rq := rq || ' cgr.woc_id';
		rq := rq || ' from v$customer_globus_restrictions cgr, cusd c';
		rq := rq || ' where c.id = cgr.cusd_id';
		if pCustResidence is not null then
			rq := rq || ' and upper(c.country) = upper(:pCustResidence)';
		end if;
		if pCustType is not null then
			rq := rq || ' and c.type = :pCustType';
		end if;
		if remoteId > 0 then
			rq := rq || ' and c.remote_officers.contains(:remoteId) = 1';
		end if;
		rq := rq || ' )';
	end if;

	cursor_name := dbms_sql.open_cursor;
	dbms_sql.parse(cursor_name, rq, dbms_sql.native);

	if pChannelId is not null then
		dbms_sql.bind_variable(cursor_name, ':pChannelId', pChannelId);
	end if;
	if pCustId is not null then
		dbms_sql.bind_variable(cursor_name, ':pCustId', pCustId);
	end if;
	if userLogin is not null then
		dbms_sql.bind_variable(cursor_name, ':userLogin', userLogin);
	end if;
	if deviceNo is not null then
		dbms_sql.bind_variable(cursor_name, ':deviceNo', deviceNo);
	end if;
	if pChannel > 0 then
		dbms_sql.bind_variable(cursor_name, ':pChannel', pChannel);
	end if;
	if pStatus > 0 then
		dbms_sql.bind_variable(cursor_name, ':pStatus', pStatus);
	end if;
	if pCustResidence is not null then
		dbms_sql.bind_variable(cursor_name, ':pCustResidence', pCustResidence);
	end if;
	if pCustType is not null then
		dbms_sql.bind_variable(cursor_name, ':pCustType', pCustType);
	end if;
	if remoteId > 0 then
		dbms_sql.bind_variable(cursor_name, ':remoteId', remoteId);
	end if;

	rows_processed := dbms_sql.execute(cursor_name);
	dbms_sql.close_cursor(cursor_name);

	return 1;

exception when others then
	if dbms_sql.is_open(cursor_name) then
		dbms_sql.close_cursor(cursor_name);
	end if;
	raise;
end;

function find_by_filter(
	pCursorName in integer
) return cursor_t is
	cursor_name integer := pCursorName;
	rv cursor_t;
	row user_t;
	rows_processed integer;
	rowset user_set_t := user_set_t();
	userId number(10);
	userName varchar2(210);
	personalId varchar2(35);
	passportNo varchar2(35);
	issuerCountry varchar2(2);
	country varchar2(2);
	phone varchar2(120);
	mobile varchar2(120);
	fax varchar2(120);
	email varchar2(129);
	regDate date;
begin
	dbms_sql.define_column(cursor_name,  1, userId);
	dbms_sql.define_column(cursor_name,  2, userName, 210);
	dbms_sql.define_column(cursor_name,  3, personalId, 35);
	dbms_sql.define_column(cursor_name,  4, passportNo, 35);
	dbms_sql.define_column(cursor_name,  5, issuerCountry, 2);
	dbms_sql.define_column(cursor_name,  6, country, 2);
	dbms_sql.define_column(cursor_name,  7, phone, 120);
	dbms_sql.define_column(cursor_name,  8, mobile, 120);
	dbms_sql.define_column(cursor_name,  9, fax, 120);
	dbms_sql.define_column(cursor_name, 10, email, 129);
	dbms_sql.define_column(cursor_name, 11, regDate);

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name,  1, userId);
		dbms_sql.column_value(cursor_name,  2, userName);
		dbms_sql.column_value(cursor_name,  3, personalId);
		dbms_sql.column_value(cursor_name,  4, passportNo);
		dbms_sql.column_value(cursor_name,  5, issuerCountry);
		dbms_sql.column_value(cursor_name,  6, country);
		dbms_sql.column_value(cursor_name,  7, phone);
		dbms_sql.column_value(cursor_name,  8, mobile);
		dbms_sql.column_value(cursor_name,  9, fax);
		dbms_sql.column_value(cursor_name, 10, email);
		dbms_sql.column_value(cursor_name, 11, regDate);
		row := user_t(
			userId,
			userName,
			personalId,
			passportNo,
			issuerCountry,
			country,
			phone,
			mobile,
			fax,
			email,
			regDate
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as user_set_t));
	return rv;

exception when others then
	if dbms_sql.is_open(cursor_name) then
		dbms_sql.close_cursor(cursor_name);
	end if;
	raise;
end;

function find_by_filter(
	pUserName in varchar2,
	pPersonalId in varchar2,
	pOfficerId in number,
	pPhone in varchar2,
	pFax in varchar2,
	pEmail in varchar2,
	pChannelId in varchar2,
	pLogin in varchar2,
	pCDevNum in varchar2,
	pChannel in number,
	pCustId in varchar2,
	pCustResidence in varchar2,
	pCustType in varchar2,
	pDateFrom in date,
	pDateTill in date,
	pStatus in integer
) return cursor_t is
	userName varchar2(1024) := bocommon.prepare_like(pUserName);
	personalID varchar2(1024) := bocommon.prepare_like(pPersonalId);
	phoneNo varchar2(1024) := bocommon.prepare_like(pPhone);
	faxNo varchar2(1024) := bocommon.prepare_like(pFax);
	e_mail varchar2(1024) := bocommon.prepare_like(pEmail);
	rq varchar2(32767);
	ids integer;
	cursor_name integer;
begin
	ids := invariant(
		pChannelId,
		pCustId,
		pLogin,
		pCDevNum,
		pChannel,
		pStatus,
		pCustResidence,
		pCustType,
		pOfficerId
	);

	rq := 'select /* BOFindUsers.find_by_filter */';
	rq := rq || ' u.id userId,';
	rq := rq || ' u.name userName,';
	rq := rq || ' u.personal_id personalId,';
	rq := rq || ' u.passport_no passportNo,';
	rq := rq || ' u.issuer_country_id issuerCountry,';
	rq := rq || ' u.country_id country,';
	rq := rq || ' u.phone phone,';
	rq := rq || ' u.mobile_phone mobile,';
	rq := rq || ' u.fax fax,';
	rq := rq || ' u.email email,';
	rq := rq || ' u.reg_date regDate';
	rq := rq || ' from v$users u';
	rq := rq || ' where rownum <= :ResultSetSize';
	if ids = 1 then
		rq := rq || ' and u.id in (';
		rq := rq || ' select requested_id from tmp_request_data';
		rq := rq || ' )';
	end if;
	if userName is not null then
		rq := rq || ' and upper(u.name) like :userName';
	end if;
	if personalID is not null then
		rq := rq || ' and upper(u.personal_id) like :personalID';
	end if;
	if personalID is not null then
		rq := rq || ' and upper(u.personal_id) like :personalID';
	end if;
	if phoneNo is not null then
		rq := rq || ' and (';
		rq := rq || ' upper(u.phone) like :phoneNo or';
		rq := rq || ' upper(u.mobile_phone) like :phoneNo';
		rq := rq || ' )';
	end if;
	if faxNo is not null then
		rq := rq || ' and upper(u.fax) like :faxNo';
	end if;
	if e_mail is not null then
		rq := rq || ' and upper(u.email) like :e_mail';
	end if;
	if pDateFrom is not null and pDateTill is not null then
		rq := rq || ' and (u.reg_date is null or u.reg_date between :pDateFrom and :pDateTill)';
	end if;

	cursor_name := dbms_sql.open_cursor;
	dbms_sql.parse(cursor_name, rq, dbms_sql.native);

	dbms_sql.bind_variable(cursor_name, ':ResultSetSize', bocommon.ResultSetSize);
	if userName is not null then
		dbms_sql.bind_variable(cursor_name, ':userName', userName);
	end if;
	if personalID is not null then
		dbms_sql.bind_variable(cursor_name, ':personalID', personalID);
	end if;
	if phoneNo is not null then
		dbms_sql.bind_variable(cursor_name, ':phoneNo', phoneNo);
	end if;
	if faxNo is not null then
		dbms_sql.bind_variable(cursor_name, ':faxNo', faxNo);
	end if;
	if e_mail is not null then
		dbms_sql.bind_variable(cursor_name, ':e_mail', e_mail);
	end if;
	if pDateFrom is not null and pDateTill is not null then
		dbms_sql.bind_variable(cursor_name, ':pDateFrom', pDateFrom);
		dbms_sql.bind_variable(cursor_name, ':pDateTill', pDateTill);
	end if;

	return find_by_filter(cursor_name);
end;

function find_by_id(
	pUserId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		u.id userId,
		u.name userName,
		u.personal_id personalId,
		u.passport_no passportNo,
		u.issuer_country_id issuerCountry,
		u.country_id country,
		u.phone phone,
		u.mobile_phone mobile,
		u.fax fax,
		u.email email,
		u.reg_date regDate
	from v$users u
	where u.id = pUserId;
	return rv;
end;

function find_by_globus_id(
	pGlobusUserId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		u.id userId,
		u.name userName,
		u.personal_id personalId,
		u.passport_no passportNo,
		u.issuer_country_id issuerCountry,
		u.country_id country,
		u.phone phone,
		u.mobile_phone mobile,
		u.fax fax,
		u.email email,
		u.reg_date regDate
	from v$users u
	where u.customer_id = pGlobusUserId;
	return rv;
end;

function find_users(
	pUserId in varchar2,
  	pGlobusUserId in varchar2,
	pUserName in varchar2,
	pPersonalId in varchar2,
	pOfficerId in number,
	pPhone in varchar2,
	pFax in varchar2,
	pEmail in varchar2,
	pChannelId in varchar2,
	pLogin in varchar2,
	pCDevNum in varchar2,
	pChannel in number,
	--
	pCustId in varchar2,
	pCustResidence in varchar2,
	pCustType in varchar2,
	--
	pDateFrom in date,
	pDateTill in date,
	pStatus in integer
) return cursor_t is
begin
    if pGlobusUserId is not null then
		return find_by_globus_id(pGlobusUserId);
	end if;
	if pUserId is not null then
		return find_by_id(pUserId);
	end if;
	return find_by_filter(
		pUserName,
		pPersonalId,
		pOfficerId,
		pPhone,
		pFax,
		pEmail,
		pChannelId,
		pLogin,
		pCDevNum,
		pChannel,
		pCustId,
		pCustResidence,
		pCustType,
		pDateFrom,
		pDateTill,
		pStatus
	);
end;

end;

/

show err;
