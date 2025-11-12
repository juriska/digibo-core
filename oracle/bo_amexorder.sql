/*
* Web orders.
*/

create or replace package BOamexorder as

type cursor_t is ref cursor;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,
	userLogin in varchar2,
	-- system
	docId in varchar2,
	statuses in varchar2,
	docClass in varchar2,
	fromLocation in varchar2,
	createdFrom in date,
	createdTill in date,
	pCustomerName in varchar2,
    pLegalId in varchar2,
    pFormType in varchar2
) return cursor_t;

function find_my(pOfficerId in integer) return cursor_t;

procedure amexorder(
	pId in varchar2,
	userName out varchar2,
	legalId out varchar2,
	officerName out varchar2,
	custName out varchar2,
	globusNo out varchar2,
	pLocation out varchar2,
	--
	fromAccount out varchar2,
	utPhoneNumber out varchar2,
	phoneMobile out varchar2,
	--
	authName out varchar2,
	authSurname out varchar2,
	authLegalId out varchar2,
	authPassportNo out varchar2,
	authPassportCountry out varchar2,
	authPassportInst out varchar2,
	authPhone out varchar2,
	authFax out varchar2,
	authEmail out varchar2,
	--
	itc out varchar2,
	itb out varchar2,
	channelId out integer,
	signTime out date,
	signDevType out integer,
	signDevId out varchar2,
	signKey1 out varchar2,
	signKey2 out varchar2,
	signRSA out varchar2
);

function set_processing(pId in varchar2) return integer;

end;
/

show err;

create or replace package body BOamexorder as

function find_by_id(
	docId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		/* BOMamexorder.find_by_id */
		p.id pId,
		p.status_id status,
		p.order_date created,
		p.document_number docNumber,
		w.login login,
		w.id wocId,
		p.change_officer_id processedBy,
		substr( p.info_to_customer, 0, 20) itc,
        --null itc,
		p.class_id class_id
        , trim( (select e.additional_info from document_extensions e where e.document_id = p.id and dictionary_id in ('amexNameF', 'amexNameJ', 'winName1', 'cnkName1', 'firstName', 'companyName', 'onbFirstName' ) and rownum <= 1 ) || ' ' || (select e.additional_info from document_extensions e where e.document_id = p.id and dictionary_id in ('winName2', 'cnkName2', 'lastName', 'onbLastName' ) and rownum <= 1 ) 
		   || ' ' || (select nvl(trim(decode(bocommon.LanguageId, 0, c.name.name_lv, 1, c.name.name_en, 2, c.name.name_ru, 3, c.name.extra_1, 4, c.name.extra_2,5, c.name.extra_3,c.name.name_en)), c.name.name_en) from cusd c
						where id = p.from_customer)		
		) customerName
        , (select e.additional_info from document_extensions e where e.document_id = p.id and dictionary_id in ('amexPersCode', 'amexRegNum', 'winPersCode', 'cnkPersCode', 'persCode', 'personalCode', 'companyRegNumber') and rownum <= 1 ) legalId
        , ( select e.dictionary_id from document_extensions e where e.document_id = p.id and e.dictionary_id in ('CREDIT_SCORE','CREDIT_CARD','KPP') and rownum <= 1 ) form_type
		, (select e.additional_info from document_extensions e where e.document_id = p.id and dictionary_id = 'onbPhone' and rownum <= 1 ) onbPhone
		, (select e.additional_info from document_extensions e where e.document_id = p.id and dictionary_id = 'onbLanguage' and rownum <= 1 ) onbLanguage
		, p.from_location fromLocation
	from documents p, ways_of_connection w
	where p.id = docId
        and p.class_id in ( 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1009, 1010, 1011, 1012, 1013, 1016, 1018, 1019, 1021, 1025, 786, 787, 788, 789, 1015, 1017, 1020)
		and w.id (+) = p.creator_woc_id;
	return rv;
end;

function execute_by_filter(
	pCursorName in integer
) return cursor_t is
	cursor_name integer := pCursorName;
	rv cursor_t;
	row amexorder_t;
	rows_processed integer;
	rowset amexorder_set_t := amexorder_set_t();
	pId number(14);
	status number(2);
	created date;
	docNumber varchar2(16);
	login varchar2(60);
	wocId number(10);
	processedBy number(10);
	itc varchar2(4000);
	class_id number(10);
    customerName varchar2(255);
    legalId varchar2(100);
    form_type varchar2(100);
	onbPhone varchar2(30);
	onbLanguage varchar2(30);
	fromLocation varchar2(30);
begin
	dbms_sql.define_column(cursor_name,  1, pId);
	dbms_sql.define_column(cursor_name,  2, status);
	dbms_sql.define_column(cursor_name,  3, created);
	dbms_sql.define_column(cursor_name,  4, docNumber, 16);
	dbms_sql.define_column(cursor_name,  5, login, 60);
	dbms_sql.define_column(cursor_name,  6, wocId);
	dbms_sql.define_column(cursor_name,  7, processedBy);
	dbms_sql.define_column(cursor_name,  8, itc, 4000);
	dbms_sql.define_column(cursor_name,  9, class_id);
    dbms_sql.define_column(cursor_name,  10, customerName, 255);
    dbms_sql.define_column(cursor_name,  11, legalId, 100);
    dbms_sql.define_column(cursor_name,  12, form_type, 100);
    dbms_sql.define_column(cursor_name,  13, onbPhone, 30);
    dbms_sql.define_column(cursor_name,  14, onbLanguage, 30);
    dbms_sql.define_column(cursor_name,  15, fromLocation, 30);

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name,  1, pId);
		dbms_sql.column_value(cursor_name,  2, status);
		dbms_sql.column_value(cursor_name,  3, created);
		dbms_sql.column_value(cursor_name,  4, docNumber);
		dbms_sql.column_value(cursor_name,  5, login);
		dbms_sql.column_value(cursor_name,  6, wocId);
		dbms_sql.column_value(cursor_name,  7, processedBy);
		dbms_sql.column_value(cursor_name,  8, itc);
		dbms_sql.column_value(cursor_name,  9, class_id);
        dbms_sql.column_value(cursor_name,  10, customerName);
        dbms_sql.column_value(cursor_name,  11, legalId);
        dbms_sql.column_value(cursor_name,  12, form_type);
		dbms_sql.column_value(cursor_name,  13, onbPhone);
		dbms_sql.column_value(cursor_name,  14, onbLanguage);
		dbms_sql.column_value(cursor_name,  15, fromLocation);
		
		row := amexorder_t(
			pId,
			status,
			created,
			docNumber,
			login,
			wocId,
			processedBy,
			itc,
			class_id,
			customerName,
			legalId,
			form_type,
			onbPhone,
			onbLanguage,
			fromLocation
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as amexorder_set_t));
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
	statuses in varchar2,
	docClass in varchar2,
	fromLocation in varchar2,
	createdFrom in date,
	createdTill in date
    , pCustomerName in varchar2
    , pLegalId in varchar2
    , pFormType in varchar2
) return cursor_t is
	rq varchar2(32767);
	cursor_name integer;
	custName varchar2(1024) := bocommon.prepare_like(pCustName);
	userLogin varchar2(1024) := bocommon.prepare_like(pUserLogin);
begin
	-- While do not filling "from_customer", commented customer and loging fields
	custName := null;
	userLogin := null;
	if custName is not null then
		delete from tmp_request_data;
		insert into tmp_request_data (requested_id)
		select distinct c.id from ibglb.cusd c
		where (custName is null or c.name.is_like(custName) = 1);
	end if;

	rq := rq || 'select /* BOamexorder.find_by_filter */';
--	if custId is not null or custName is not null then
--		rq := rq || ' /*+ INDEX (p IDX_DOC_CUST_ID_DATE) */';
--	elsif userLogin is not null then
--		rq := rq || ' /*+ INDEX (p IDX_DOC_WOC_ID_DATE) */';
--	end if;
	rq := rq || ' /*+ INDEX (w PK_WAYS_OF_CONNECTION) */';
	rq := rq || ' p.id pId,';
	rq := rq || ' p.status_id status,';
	rq := rq || ' p.order_date created,';
	rq := rq || ' p.document_number docNumber,';
	rq := rq || ' null login,';
	rq := rq || ' null wocId,';
	rq := rq || ' p.change_officer_id processedBy,';
	rq := rq || ' substr( p.info_to_customer, 0, 20) itc';
    --rq := rq || ' null itc';
	rq := rq || ' , p.class_id class_id';
    rq := rq || ' , trim( (select e.additional_info from document_extensions e where e.document_id = p.id and dictionary_id in (''amexNameF'', ''amexNameJ'', ''winName1'', ''cnkName1'', ''firstName'', ''companyName'', ''onbFirstName'' ) and rownum <= 1 ) || '' '' || (select e.additional_info from document_extensions e where e.document_id = p.id and dictionary_id in (''winName2'', ''cnkName2'', ''lastName'', ''onbLastName'' ) and rownum <= 1 ) || '' '' || (select nvl(trim(decode(:LanguageId, 0, c.name.name_lv, 1, c.name.name_en, 2, c.name.name_ru, 3, c.name.extra_1, 4, c.name.extra_2,5, c.name.extra_3,c.name.name_en)), c.name.name_en) from cusd c
	where id = p.from_customer) ) customerName ';

    rq := rq || ' , (select e.additional_info from document_extensions e where e.document_id = p.id and dictionary_id in (''amexPersCode'', ''amexRegNum'', ''winPersCode'', ''cnkPersCode'', ''persCode'', ''personalCode'', ''companyRegNumber'') and rownum <= 1 ) legalId';
    rq := rq || ' , ( select e.dictionary_id from document_extensions e where e.document_id = p.id and e.dictionary_id in (''CREDIT_SCORE'',''CREDIT_CARD'',''KPP'') and rownum <= 1 ) form_type';
	rq := rq || ' , ( select e.additional_info from document_extensions e where e.document_id = p.id and e.dictionary_id in (''onbPhone'') and rownum <= 1 ) onbPhone';
	rq := rq || ' , ( select e.additional_info from document_extensions e where e.document_id = p.id and e.dictionary_id in (''onbLanguage'') and rownum <= 1 ) onbLanguage';
	rq := rq || ' , p.from_location fromLocation';

	rq := rq || ' from documents p';
	rq := rq || ' where rownum <= :ResultSetSize';
	rq := rq || ' and ' || bocommon.order_date_expression(NULL, NULL, NULL, -1);
	rq := rq || ' and p.class_id in (' || docClass || ')';
	rq := rq || ' and p.status_id in (' || statuses || ')';
    rq := rq || ' and p.class_id in ( 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1009, 1010, 1011, 1012, 1013, 1016, 1018, 1019, 1021, 1025, 786, 787, 788, 789, 1015, 1017, 1020)';
									    
    if pCustomerName is not null then
       null;
       rq := rq || ' and trim( (select upper( e.additional_info) from document_extensions e where e.document_id = p.id and dictionary_id in (''amexNameF'', ''amexNameJ'', ''winName1'', ''cnkName1'', ''firstName'' ) and rownum <= 1 ) || '' '' || (select upper(e.additional_info) from document_extensions e where e.document_id = p.id and dictionary_id in (''winName2'', ''cnkName2'', ''lastName'' ) and rownum <= 1 ) ) like upper( :pCustomerName )';
    end if;
    if pLegalId is not null then
       null;
       rq := rq || ' and (select e.additional_info from document_extensions e where e.document_id = p.id and dictionary_id in (''amexPersCode'', ''amexRegNum'', ''winPersCode'', ''cnkPersCode'', ''persCode'', ''personalCode'') and rownum <= 1 ) like :pLegalId';
    end if;
    if pFormType is not null then
        rq := rq || ' and exists(select e.dictionary_id from document_extensions e where e.document_id = p.id and e.dictionary_id =  :pFormType )';
    end if;
	if fromLocation is not null then
		rq := rq || ' and upper(p.from_location) like :FromLocation';
	end if;
	
	cursor_name := dbms_sql.open_cursor;

	dbms_sql.parse(cursor_name, rq, dbms_sql.native);
	dbms_sql.bind_variable(cursor_name, ':ResultSetSize', bocommon.ResultSetSize);
	dbms_sql.bind_variable(cursor_name, ':DateFrom', createdFrom);
	dbms_sql.bind_variable(cursor_name, ':DateTill', createdTill);
	dbms_sql.bind_variable(cursor_name, ':LanguageId', bocommon.LanguageId);
		
	if custId is not null then
		dbms_sql.bind_variable(cursor_name, ':CustomerId', custId);
	end if;
	if userLogin is not null then
		dbms_sql.bind_variable(cursor_name, ':UserLogin', userLogin);
	end if;
    if pCustomerName is not null then
       dbms_sql.bind_variable(cursor_name, ':pCustomerName', pCustomerName);
    end if;
    if pLegalId is not null then
       dbms_sql.bind_variable(cursor_name, ':pLegalId', pLegalId);
    end if;
    if pFormType is not null then
       dbms_sql.bind_variable(cursor_name, ':pFormType', pFormType);
    end if;
	if fromLocation is not null then
		dbms_sql.bind_variable(cursor_name, ':FromLocation', bocommon.prepare_like(fromLocation));
	end if;

	return execute_by_filter(cursor_name);
end;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,
	userLogin in varchar2,
	-- system
	docId in varchar2,
	statuses in varchar2,
	docClass in varchar2,
	fromLocation in varchar2,
	createdFrom in date,
	createdTill in date,
	pCustomerName in varchar2,
    pLegalId in varchar2,
    pFormType in varchar2
) return cursor_t is
begin
	if docId is not null then
		return find_by_id(docId);
	end if;
	return find_by_filter(
		custId,
		custName,
		userLogin,
		statuses,
		docClass,
		fromLocation,
		createdFrom,
		createdTill,
        	pCustomerName,
		pLegalId,
		pFormType
	);
end;

function find_my(pOfficerId in integer) return cursor_t is
	rv cursor_t;
    v_feed_window_1010 integer;
begin
	-- Acts as "find_new" when pOfficerId is not supplied
    
    SELECT feed_window into v_feed_window_1010 FROM document_classes WHERE document_class_id = 1010;
    -- v_feed_window_1010 <> 1 -> usual workflow
    -- v_feed_window_1010 == 1 -> special workflow for class_id = 1010
    
	open rv for select
		/* BOamexorder.find_my */
		/*+ INDEX (p IDX_DOC_STATUS_CLASS) */
		/*+ INDEX (w PK_WAYS_OF_CONNECTION) */
		p.id pId,
		p.status_id status,
		p.order_date created,
		p.document_number docNumber,
		w.login login,
		w.id wocId,
		p.change_officer_id processedBy,
		--p.info_to_customer itc,
        	null itc,
		p.class_id class_id
        , trim( (select e.additional_info from document_extensions e where e.document_id = p.id and dictionary_id in ('amexNameF', 'amexNameJ', 'winName1', 'cnkName1', 'firstName', 'companyName', 'onbFirstName' ) and rownum <= 1 ) || ' ' || (select e.additional_info from document_extensions e where e.document_id = p.id and dictionary_id in ('winName2', 'cnkName2', 'lastName', 'onbLastName' ) and rownum <= 1 )
   		   || ' ' || (select nvl(trim(decode(bocommon.LanguageId, 0, c.name.name_lv, 1, c.name.name_en, 2, c.name.name_ru, 3, c.name.extra_1, 4, c.name.extra_2,5, c.name.extra_3,c.name.name_en)), c.name.name_en) from cusd c
		where id = p.from_customer) ) customerName
        , (select e.additional_info from document_extensions e where e.document_id = p.id and dictionary_id in ('amexPersCode', 'amexRegNum', 'winPersCode', 'cnkPersCode', 'persCode', 'personalCode', 'companyRegNumber' ) and rownum <= 1 ) legalId
        , ( select e.dictionary_id from document_extensions e where e.document_id = p.id and e.dictionary_id in ('CREDIT_SCORE','CREDIT_CARD','KPP') and rownum <= 1 ) form_type
		, (select e.additional_info from document_extensions e where e.document_id = p.id and dictionary_id = 'onbPhone' and rownum <= 1 ) onbPhone
		, (select e.additional_info from document_extensions e where e.document_id = p.id and dictionary_id = 'onbLanguage' and rownum <= 1 ) onbLanguage
		, p.from_location fromLocation
	from documents p, ways_of_connection w
	where rownum <= bocommon.ResultSetSize 
        and p.class_id in ( 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1009, 1010, 1011, 1012, 1013, 1016, 1018, 1019, 1021, 1025, 786, 787, 788, 789, 1015, 1017, 1020)
         and 
         ( -- Find NEW
			(pOfficerId = 0  and 
                    (

                        (p.class_id not in ( 1010, 1021, 1025) and p.status_id in ( RBA_CONST.CONFIRM_OK))
                        or
                        (p.class_id in ( 1020) and p.status_id in ( RBA_CONST.DRAFT, RBA_CONST.DRAFT_VALIDATED, RBA_CONST.REJECTED_BY_VERIFF ))
                        
                        or (p.class_id = 1010 and nvl(( SELECT feed_window FROM document_classes WHERE document_class_id = 1010 ), 0 ) <> 1 and p.status_id in ( RBA_CONST.CONFIRM_OK))
                        or (p.class_id = 1021 and nvl(( SELECT feed_window FROM document_classes WHERE document_class_id = 1021 ), 0 ) <> 1 and p.status_id in ( RBA_CONST.CONFIRM_OK))
                        or (p.class_id = 1025 and nvl(( SELECT feed_window FROM document_classes WHERE document_class_id = 1025 ), 0 ) <> 1 and p.status_id in ( RBA_CONST.CONFIRM_OK))
                        
                        or (p.class_id = 1010 and nvl(( SELECT feed_window FROM document_classes WHERE document_class_id = 1010 ), 0 ) = 1 and p.status_id in ( RBA_CONST.MESSAGE_SENT, RBA_CONST.MESSAGE_FAILED) )
                        or (p.class_id = 1021 and nvl(( SELECT feed_window FROM document_classes WHERE document_class_id = 1021 ), 0 ) = 1 and p.status_id in ( RBA_CONST.MESSAGE_SENT, RBA_CONST.MESSAGE_FAILED) )
                        or (p.class_id = 1025 and nvl(( SELECT feed_window FROM document_classes WHERE document_class_id = 1025 ), 0 ) = 1 and p.status_id in ( RBA_CONST.MESSAGE_SENT, RBA_CONST.MESSAGE_FAILED) )
                        
                    )
			)
			or
			(p.change_officer_id = pOfficerId and p.status_id = RBA_CONST.MANUAL_PROCESSING_STARTED)
		) and
		w.id (+) = p.creator_woc_id
        ;
	return rv;
end;

procedure amexorder(
	pId in varchar2,
	userName out varchar2,
	legalId out varchar2,
	officerName out varchar2,
	custName out varchar2,
	globusNo out varchar2,
	pLocation out varchar2,
	--
	fromAccount out varchar2,
	utPhoneNumber out varchar2,
	phoneMobile out varchar2,
	--
	authName out varchar2,
	authSurname out varchar2,
	authLegalId out varchar2,
	authPassportNo out varchar2,
	authPassportCountry out varchar2,
	authPassportInst out varchar2,
	authPhone out varchar2,
	authFax out varchar2,
	authEmail out varchar2,
	--
	itc out varchar2,
	itb out varchar2,
	channelId out integer,
	signTime out date,
	signDevType out integer,
	signDevId out varchar2,
	signKey1 out varchar2,
	signKey2 out varchar2,
	signRSA out varchar2
) is
begin
	select /* BOamexorder.amexorder */
		d.bank_reference,
		null, --u.name || ' (' || w.login || ')',
		null, --u.personal_id,
		null, --remote_officer.name,
		null, --nvl(trim(decode(bocommon.LanguageId,
		--	0, c.name.name_lv,
		--		1, c.name.name_en,
		--	2, c.name.name_ru,
		--	3, c.name.extra_1,
		--	4, c.name.extra_2,
		--	5, c.name.extra_3,
		--	c.name.name_en
		--)), c.name.name_en) || ' (' || c.id || ')',
		d.ff_text,
		null, --w.channel_id,
--
		null, --nvl(a.iban, a.mccy_accnum || ' ' || a.sub_accnum) || ' ' || a.ccy,
		d.ut_phone_number,
		d.phone_mobile,
--
		d.authorized_name,
		d.authorized_surname,
		d.authorized_legal_id,
		d.authorized_passport_number,
		d.authorized_passport_country,
		d.authorized_passport_inst,
		d.authorized_phone,
		d.authorized_fax,
		d.authorized_email,
--
		d.signature_date,
		d.signature_cdevice_type_id,
		d.signature_cdevice_serial,
		d.signature_key_1,
		d.signature_key_2,
		substr(d.signature_rsa, instr(d.signature_rsa, ';') + 1)
	into
		globusNo,
		userName,
		legalId,
		officerName,
		custName,
		itb,
		channelId,
--
		fromAccount,
		utPhoneNumber,
		phoneMobile,
--
		authName,
		authSurname,
		authLegalId,
		authPassportNo,
		authPassportCountry,
		authPassportInst,
		authPhone,
		authFax,
		authEmail,
--
		signTime,
		signDevType,
		signDevId,
		signKey1,
		signKey2,
		signRSA
	from documents d--, v$users u, acsd a, cusd c, ways_of_connection w,
		--(select d.id id, o.officer_name name
		--from documents d, acsd a, cusd c, ibglb.glb_dept_accnt_officer o
		--where d.id = pId and
		--	a.id = d.from_account and
		--	c.id = d.from_customer and
		--	o.id = c.remote_officers.get_id(a.location)
		--) remote_officer
	where d.id = pId;-- and d.id = remote_officer.id(+) and
		--a.id(+) = d.from_account and
		--c.id(+) = d.from_customer and
		--u.id = d.creator_user_id and
		--w.id(+) = d.creator_woc_id;
end;

function set_processing(pId in varchar2) return integer is
	vRes int;
    v_feed_window_1010 integer;
    v_class_id number(5);
begin 
	vRes := 0;

    select class_id into v_class_id from documents where id = pId;
    SELECT feed_window into v_feed_window_1010 FROM document_classes WHERE document_class_id = 1010;
    -- v_feed_window_1010 <> 1 -> usual workflow
    -- v_feed_window_1010 == 1 -> special workflow for class_id = 1010
	
	update documents
	set change_officer_id = bocommon.officerId
	where id = pId
		and (
				(status_id in (RBA_CONST.EXECUTED, RBA_CONST.REJECTED)) or
                          (v_class_id not in ( 1010, 1021, 1025) and status_id in (6, 61, RBA_CONST.SIGNATURE_OK, RBA_CONST.CONFIRM_OK, RBA_CONST.MANUAL_PROCESSING_STARTED))
                          or (v_class_id in ( 1010, 1021, 1025) and status_id in (RBA_CONST.DRAFT, RBA_CONST.DRAFT_VALIDATED  ))
			  or v_class_id = 1020 and status_id = RBA_CONST.REJECTED_BY_VERIFF

                          or (v_class_id = 1010 and nvl(( SELECT feed_window FROM document_classes WHERE document_class_id = 1010 ), 0 ) <> 1 and status_id in (6, 61, RBA_CONST.SIGNATURE_OK, RBA_CONST.CONFIRM_OK, RBA_CONST.MANUAL_PROCESSING_STARTED))
                          or (v_class_id = 1021 and nvl(( SELECT feed_window FROM document_classes WHERE document_class_id = 1021 ), 0 ) <> 1 and status_id in (6, 61, RBA_CONST.SIGNATURE_OK, RBA_CONST.CONFIRM_OK, RBA_CONST.MANUAL_PROCESSING_STARTED))
                          or (v_class_id = 1025 and nvl(( SELECT feed_window FROM document_classes WHERE document_class_id = 1025 ), 0 ) <> 1 and status_id in (6, 61, RBA_CONST.SIGNATURE_OK, RBA_CONST.CONFIRM_OK, RBA_CONST.MANUAL_PROCESSING_STARTED))
                          
                          or (v_class_id = 1010 and nvl(( SELECT feed_window FROM document_classes WHERE document_class_id = 1010 ), 0 ) = 1 and status_id in ( RBA_CONST.MESSAGE_SENT, RBA_CONST.MANUAL_PROCESSING_STARTED))
                          or (v_class_id = 1021 and nvl(( SELECT feed_window FROM document_classes WHERE document_class_id = 1021 ), 0 ) = 1 and status_id in ( RBA_CONST.MESSAGE_SENT, RBA_CONST.MANUAL_PROCESSING_STARTED))
                          or (v_class_id = 1025 and nvl(( SELECT feed_window FROM document_classes WHERE document_class_id = 1025 ), 0 ) = 1 and status_id in ( RBA_CONST.MESSAGE_SENT, RBA_CONST.MANUAL_PROCESSING_STARTED))
			  	
             )
	returning change_officer_id into vRes;

	if vRes > 0 then
		bodocuments.set_manual_status(pId, null, RBA_CONST.MANUAL_PROCESSING_STARTED, 24403);
	else
		vRes := 0;
	end if;

	return vRes;
end;

end;
/

show err;
