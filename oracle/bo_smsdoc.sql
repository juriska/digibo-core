/*
* SMS orders.
*/

prompt BOSMSDocument.update_document( ... ), currently is not multicompany.

create or replace package BOSMSDocument as

type cursor_t is ref cursor;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,
	userLogin in varchar2,
	officerId in integer,

	-- document
	pType in varchar2,
	pMobile in varchar2,

	-- system
	docId in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t;

procedure sms(
	pId in varchar2,
	userName out varchar2,
	userId out varchar2,
	officerName out varchar2,
	custName out varchar2,
	custAccount out varchar2,
-- Order part.
	agreement out varchar2,
	contractId out varchar2,
	pMobileOperator out varchar2,
	pContactLanguage out varchar2,
	pLocation out varchar2,
--
	itc out varchar2,
	--signTime out date,
	--signDevType out integer,
	--signDevId out varchar2,
	--signKey1 out varchar2,
	--signKey2 out varchar2
    sms_time out varchar2
);

function already_exists(phone in varchar2) return integer;

procedure update_document(
	pDocId in varchar2,
	reason in varchar2,
	pNewStatus in integer,
	pMessageId in integer
);

end;
/

show err;

create or replace package body BOSMSDocument as

function find_by_id(
	docId in varchar2,
	pType in varchar2
) return cursor_t is
	rv cursor_t;
	t_classes num_table_type := bocommon.str2table(pType);
begin
	open rv for select
		/* BOSMSDocument.find_by_id */
		p.id pId,
		p.status_id status,
		p.class_id class,
		p.order_date created,
		p.document_number docNumber,
		w.login login,
		p.phone_mobile mobile
	from documents p, ways_of_connection w
	where p.id = docId and
		p.class_id in (select * from table(cast(t_classes as num_table_type))) and
		w.id = p.creator_woc_id;
	return rv;
end;

function execute_by_filter(
	pCursorName in integer
) return cursor_t is
	cursor_name integer := pCursorName;
	rv cursor_t;
	row smsdoc_t;
	rows_processed integer;
	rowset smsdoc_set_t := smsdoc_set_t();
	pId number(14);
	status number(2);
	class number(3);
	created date;
	docNumber varchar2(16);
	login varchar2(60);
	mobile varchar2(35);
begin
	dbms_sql.define_column(cursor_name,  1, pId);
	dbms_sql.define_column(cursor_name,  2, status);
	dbms_sql.define_column(cursor_name,  3, class);
	dbms_sql.define_column(cursor_name,  4, created);
	dbms_sql.define_column(cursor_name,  5, docNumber, 16);
	dbms_sql.define_column(cursor_name,  6, login, 60);
	dbms_sql.define_column(cursor_name,  7, mobile, 35);

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name,  1, pId);
		dbms_sql.column_value(cursor_name,  2, status);
		dbms_sql.column_value(cursor_name,  3, class);
		dbms_sql.column_value(cursor_name,  4, created);
		dbms_sql.column_value(cursor_name,  5, docNumber);
		dbms_sql.column_value(cursor_name,  6, login);
		dbms_sql.column_value(cursor_name,  7, mobile);
		row := smsdoc_t(
			pId,
			status,
			class,
			created,
			docNumber,
			login,
			mobile
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as smsdoc_set_t));
	return rv;

exception when others then
	if dbms_sql.is_open(cursor_name) then
		dbms_sql.close_cursor(cursor_name);
	end if;
	raise;
end;

function find_by_filter(
	custId in varchar2,
	pCustName in varchar2,
	pUserLogin in varchar2,
	officerId in integer,
	pType in varchar2,
	pMobile in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t is
	rq varchar2(32767);
	cursor_name integer;
	custName varchar2(1024) := bocommon.prepare_like(pCustName);
	userLogin varchar2(1024) := bocommon.prepare_like(pUserLogin);
	remoteId integer := BODocuments.get_remote_officer(officerId);
begin
	if custName is not null or remoteId > 0 then
		delete from tmp_request_data;
		insert into tmp_request_data (requested_id)
		select distinct c.id from ibglb.cusd c
		where (remoteId <= 0 or	c.remote_officers.contains(remoteId) = 1) and
			(custName is null or c.name.is_like(custName) = 1);
	end if;

	rq := rq || 'select /* BOSMSDocument.find_by_filter */';
--	if custId is not null or custName is not null or remoteId > 0 then
--		rq := rq || ' /*+ INDEX (p IDX_DOC_CUST_ID_DATE) */';
--	elsif userLogin is not null then
--		rq := rq || ' /*+ INDEX (p IDX_DOC_WOC_ID_DATE) */';
--	end if;
	rq := rq || ' p.id pId,';
	rq := rq || ' p.status_id status,';
	rq := rq || ' p.class_id class,';
	rq := rq || ' p.order_date created,';
	rq := rq || ' p.document_number docNumber,';
	rq := rq || ' (select login from ways_of_connection where id = p.creator_woc_id) login,';
	rq := rq || ' p.phone_mobile mobile';
	rq := rq || ' from documents p';
	rq := rq || ' where rownum <= :ResultSetSize';
	rq := rq || ' and ' || bocommon.order_date_expression(custId, custName, userLogin, remoteId);
	rq := rq || ' and p.class_id in (' || pType || ')';
	rq := rq || ' and p.status_id in (' || statuses || ')';
	if custId is not null then
		rq := rq || ' and p.from_customer = :CustomerId';
	end if;
	if pMobile is not null then
		--rq := rq || ' and p.phone_mobile = :Mobile';
        rq := rq || ' and ( p.phone_mobile = :Mobile or p.phone_mobile = ''+371'' ||:Mobile )';
	end if;
	if userLogin is not null then
		rq := rq || ' and p.creator_woc_id in (';
		rq := rq || ' select /*+ INDEX (w1 IDX_WOC_LOGIN) */ w1.id id';
		rq := rq || ' from ways_of_connection w1';
		rq := rq || ' where upper(w1.login) like :UserLogin';
		rq := rq || ' )';
	end if;
	if custName is not null or remoteId > 0 then
		rq := rq || ' and p.from_customer in (select requested_id from tmp_request_data)';
	end if;

	cursor_name := dbms_sql.open_cursor;

	dbms_sql.parse(cursor_name, rq, dbms_sql.native);
	dbms_sql.bind_variable(cursor_name, ':ResultSetSize', bocommon.ResultSetSize);
	dbms_sql.bind_variable(cursor_name, ':DateFrom', createdFrom);
	dbms_sql.bind_variable(cursor_name, ':DateTill', createdTill);
	if custId is not null then
		dbms_sql.bind_variable(cursor_name, ':CustomerId', custId);
	end if;
	if pMobile is not null then
		dbms_sql.bind_variable(cursor_name, ':Mobile', pMobile);
	end if;
	if userLogin is not null then
		dbms_sql.bind_variable(cursor_name, ':UserLogin', userLogin);
	end if;

	return execute_by_filter(cursor_name);
end;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,
	userLogin in varchar2,
	officerId in integer,

	-- document
	pType in varchar2,
	pMobile in varchar2,

	-- system
	docId in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t is
begin
	if docId is not null then
		return find_by_id(docId, pType);
	end if;
	return find_by_filter(
		custId,
		custName,
		userLogin,
		officerId,
		pType,
		pMobile,
		statuses,
		createdFrom,
		createdTill
	);
end;

procedure sms(
	pId in varchar2,
	userName out varchar2,
	userId out varchar2,
	officerName out varchar2,
	custName out varchar2,
	custAccount out varchar2,
-- Order part.
	agreement out varchar2,
	contractId out varchar2,
	pMobileOperator out varchar2,
	pContactLanguage out varchar2,
	pLocation out varchar2,
--
	itc out varchar2,
	--signTime out date,
	--signDevType out integer,
	--signDevId out varchar2,
	--signKey1 out varchar2,
	--signKey2 out varchar2
    sms_time out varchar2
) is
cnt integer;
begin
    
    select count(1) into cnt from document_extensions where  document_id = pId and dictionary_id like 'smsTime%';
    if cnt = 1 then
       select substr( dictionary_id, 8) into sms_time from document_extensions where  document_id = pId and dictionary_id like 'smsTime%';
    else
       sms_time := ' ';
    end if;
    
	select /* BOSMSDocument.sms */
		u.name || ' (' || w.login || ')',
		u.personal_id,
		remote_officer.name,
		nvl(trim(decode(bocommon.LanguageId,
			0, c.name.name_lv,
			1, c.name.name_en,
			2, c.name.name_ru,
			3, c.name.extra_1,
			4, c.name.extra_2,
			5, c.name.extra_3,
			6, c.name.extra_4,
			c.name.name_en
		)), c.name.name_en) || ' (' || c.id || ')',
		nvl(a.iban, a.mccy_accnum || ' ' || a.sub_accnum) || ' ' || a.ccy,
		ag.text,
		d.from_contract,
		nvl(trim(decode(bocommon.LanguageId,
			0, mo.name.name_lv,
			1, mo.name.name_en,
			2, mo.name.name_ru,
			3, mo.name.extra_1,
			4, mo.name.extra_2,
			5, mo.name.extra_3,
		        6, mo.name.extra_4,
			mo.name.name_en
		)), mo.name.name_en),
		decode(d.contact_language,
			0, 'EN',
			1, 'LV',
			2, 'RU',
			3, 'DE',
			4, 'SE',
			5, 'EE',
			6, 'LT',
			'??'
		),
		d.from_location,
		d.info_to_customer--,
		--d.signature_date,
		--d.signature_cdevice_type_id,
		--d.signature_cdevice_serial,
		--d.signature_key_1,
		--d.signature_key_2
	into
		userName,
		userId,
		officerName,
		custName,
		custAccount,
		agreement,
		contractId,
		pMobileOperator,
		pContactLanguage,
		pLocation,
		itc--,
		--signTime,
		--signDevType,
		--signDevId,
		--signKey1,
		--signKey2
	from documents d, v$users u, acsd a, cusd c, agreement/*_texts*/ ag,
		ways_of_connection w, mobile_operators mo,
		(select d.id id, o.officer_name name
		from documents d, acsd a, cusd c, ibglb.glb_dept_accnt_officer o
		where d.id = pId and
			a.id = d.from_account and
			c.id = d.from_customer and
			o.id = c.remote_officers.get_id(a.location)
		) remote_officer
	where d.id = pId and d.id = remote_officer.id(+) and
		a.id(+) = d.from_account and
		c.id(+) = d.from_customer and
		u.id = d.creator_user_id and
		w.id(+) = d.creator_woc_id and
		ag.id(+) = d.agreement_text_id and
		mo.id(+) = d.mobile_operator;
end;

function already_exists(phone in varchar2) return integer is
	rv integer := 1;
begin
	select /* BOSMSDocument.already_exists */
		count(login) into rv from ways_of_connection
	where login = phone and
		channel_id = RBA_CONST.SMS and
		status_id != RBA_CONST.USER_CLOSED;
	return rv;
end;

procedure update_document(
	pDocId in varchar2,
	reason in varchar2,
	pNewStatus in integer,
	pMessageId in integer
) is
	newWoc integer := null;
	classId integer;
	custId integer;
	userId integer;
	login documents.phone_mobile%type;      -- phone number.
	operator integer;                       -- service provider.
	pswd documents.document_password%type;  -- password from document.
	chargesAcc integer;                     -- also from document.
	parentId integer;                       -- parent woc id from document.
	langId integer;
	contractId integer;
    
    cnt integer;
    v_sms_time_tmp varchar2(100);
    v_sms_time varchar2(1);
begin

     select count(1) into cnt from document_extensions where  document_id = pDocId and dictionary_id like 'smsTime%';
    if cnt = 1 then
       select substr( dictionary_id, 8) into v_sms_time_tmp from document_extensions where  document_id = pDocId and dictionary_id like 'smsTime%';
       if ( v_sms_time_tmp )= '0822' then
          v_sms_time := '1';
       elsif ( v_sms_time_tmp )= 'Any' then
          v_sms_time := '0';
       end if;
    else
       v_sms_time := ' ';
    end if;

	if RBA_CONST.EXECUTED = pNewStatus then
		select
			d.class_id,
			d.from_customer,
			d.creator_user_id,
			d.phone_mobile,
			d.mobile_operator,
			d.document_password,
			d.from_account,
			d.creator_woc_id,
			d.contact_language,
			d.from_contract
		into
			classId,
			custId,
			userId,
			login,
			operator,
			pswd,
			chargesAcc,
			parentId,
			langId,
			contractId
		from documents d
		where d.id = pDocId;
		if RBA_CONST.SMS_CREATE = classId then

			BOSMSAgreementEdit.save_channel(
				newWoc,
				custId,
				'LV',
				RBA_CONST.SMS,
				userId,
				login,
				operator,
				pswd,
				chargesAcc,
				parentId,
				langId,
				null,
				null,
				null,
                v_sms_time
			);

			update documents
			set bank_reference = newWoc
			where id = pDocId;
		elsif RBA_CONST.SMS_UPDATE = classId then

			BOSMSAgreementEdit.save_channel(
				contractId,
				custId,
				'LV',
				RBA_CONST.SMS,
				userId,
				login,
				operator,
				null,
				chargesAcc,
				parentId,
				langId,
				null,
				null,
				null,
                v_sms_time
			);

			if pswd is not null then
				update ways_of_connection
				set password = pswd
				where id = contractId;
			end if;
		end if;
	end if;
	BODocuments.set_manual_status(pDocId, reason, pNewStatus, pMessageId);
end;

end;
/

show err;
