/* 
* Credit card orders.
*/

create or replace package BOCards as

type cursor_t is ref cursor;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,
	userLogin in varchar2,
	officerId in integer,

	-- document
	docClass in varchar2,
	fromLocation in varchar2,

	-- system
	docId in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date,
	channels in varchar2
) return cursor_t;

function find_my(pOfficerId in integer, docClass in varchar2) return cursor_t;

procedure card(
	pId in varchar2,
	userName out varchar2,
	userId out varchar2,
	officerName out varchar2,
	custName out varchar2,
	custCountry out varchar2,
	custAccount out varchar2,
	-- card orders:
	grpId out varchar2,
	grpName out varchar2,
	prodName out varchar2,
	prodCCY out varchar2,
	pan out varchar2,
	pEmail out varchar2,
	pPhone out varchar2,
	pMobile out varchar2,
	--
	chargesAcsdId out varchar2,
	interestIban out varchar2,
	issueForAccount out varchar2,
	issueForCustomer out varchar2,
	cardStan out varchar2,
	cardStatusFrom out varchar2,
	cardStatusTo out varchar2,
	cortexStatus out integer,
	cortexDetails out varchar2,
	lostType out integer,
	lostDate out date,
	--
	ffText out varchar2,
	pLocation out varchar2,
	--
	itc out varchar2,
	itb out varchar2,
	signTime out date,
	signDevType out integer,
	signDevId out varchar2,
	signKey1 out varchar2,
	signKey2 out varchar2
);

procedure get_lost_addr(
	pId in varchar2,
	lostCountry out varchar2,
	lostCity out varchar2
);

procedure get_issue_addr(
	pId in varchar2,
	pReceivingType out integer,
	pOffice out varchar2,
	pCountry out varchar2,
	pAddress out varchar2
);

function get_extensions(pId in varchar2) return cursor_t;

function set_processing(pId in varchar2, pStatusIdFrom in integer) return integer;

end;
/

show err;

create or replace package body BOCards as

function find_by_id(
	docId in varchar2,
	docClass in varchar2
) return cursor_t is
	t_classes num_table_type := bocommon.str2table(docClass);
	rv cursor_t;
begin
	open rv for select
		/* BOCards.find_by_id */
		p.id pId,
		p.class_id class,
		p.status_id status,
		p.card_cortex_proc_success cortex_status,
		p.order_date created,
		p.document_number docNumber,
		w.login login,
		NVL(p.card_pan, (SELECT pan from card_cards WHERE internal_id = p.from_card)) subject,
		cd.country country
        --, p.credit_amount overdraft_amount
        , (select max(nvl(e.additional_info, '')) from document_extensions e where e.document_id = p.id and (e.dictionary_id = '3390' OR e.dictionary_id ='3390RO')) overdraft_amount
        , cd.segment segment
        , p.change_officer_id processedBy
	, p.from_location fromLocation
	from documents p, ways_of_connection w, cusd cd
	where p.id = docId
		and p.class_id in (select * from table(cast(t_classes as num_table_type)))
		and w.id = p.creator_woc_id
		and cd.id = p.from_customer
        and p.class_id in ( 10,11,12,13,17,18,19,500,501,519,510,511,513,522,523,526,531,532,535,536,756,528)
    ;    
	return rv;
end;

function execute_by_filter(
	pCursorName in integer
) return cursor_t is
	cursor_name integer := pCursorName;
	rv cursor_t;
	row card_message_t;
	rows_processed integer;
	rowset card_message_set_t := card_message_set_t();
	pId number(14);
	class number(4);
	status number(2);
	cortex_status number(1);
	created date;
	docNumber varchar2(16);
	login varchar2(60);
	subject varchar2(19);
	country varchar2(2);
    overdraft_amount number(15,3);
    segment varchar2(32);
    processedBy number(10);
    fromLocation varchar2(30);

begin
	dbms_sql.define_column(cursor_name,  1, pId);
	dbms_sql.define_column(cursor_name,  2, class);
	dbms_sql.define_column(cursor_name,  3, status);
	dbms_sql.define_column(cursor_name,  4, cortex_status);
	dbms_sql.define_column(cursor_name,  5, created);
	dbms_sql.define_column(cursor_name,  6, docNumber, 16);
	dbms_sql.define_column(cursor_name,  7, login, 60);
	dbms_sql.define_column(cursor_name,  8, subject, 19);
	dbms_sql.define_column(cursor_name,  9, country, 2);
    dbms_sql.define_column(cursor_name, 10, overdraft_amount);
    dbms_sql.define_column(cursor_name, 11, segment, 32);
    dbms_sql.define_column(cursor_name, 12, processedBy);
    dbms_sql.define_column(cursor_name, 13, fromLocation, 30);

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name,  1, pId);
		dbms_sql.column_value(cursor_name,  2, class);
		dbms_sql.column_value(cursor_name,  3, status);
		dbms_sql.column_value(cursor_name,  4, cortex_status);
		dbms_sql.column_value(cursor_name,  5, created);
		dbms_sql.column_value(cursor_name,  6, docNumber);
		dbms_sql.column_value(cursor_name,  7, login);
		dbms_sql.column_value(cursor_name,  8, subject);
		dbms_sql.column_value(cursor_name,  9, country);
        dbms_sql.column_value(cursor_name, 10, overdraft_amount);
        dbms_sql.column_value(cursor_name, 11, segment);
        dbms_sql.column_value(cursor_name, 12, processedBy);
        dbms_sql.column_value(cursor_name, 13, fromLocation);
		row := card_message_t(
			pId,
			class,
			status,
			cortex_status,
			created,
			docNumber,
			login,
			subject,
			country
            , overdraft_amount
            , segment
            , processedBy
	    , fromLocation
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as card_message_set_t));
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
	docClass in varchar2,
	fromLocation in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date,
	channels in varchar2
) return cursor_t is
	rq varchar2(32767);
	cursor_name integer;
	custName varchar2(1024) := bocommon.prepare_like(pCustName);
	userLogin varchar2(1024) := bocommon.prepare_like(pUserLogin);
	remoteId integer := BODocuments.get_remote_officer(officerId);
	channels_mod varchar2(100);
begin
	if custName is not null or remoteId > 0 then
		delete from tmp_request_data;
		insert into tmp_request_data (requested_id)
		select distinct c.id from ibglb.cusd c
		where (remoteId <= 0 or	c.remote_officers.contains(remoteId) = 1) and
			(custName is null or c.name.is_like(custName) = 1);
	end if;
	
    channels_mod := channels;
    if channels_mod like '%5%' then
       null;
       channels_mod := channels_mod || ',28';
    end if;

	rq := rq || 'select /* BOCards.find_by_filter */';
--	if custId is not null or custName is not null or remoteId > 0 then
--		rq := rq || ' /*+ INDEX (p IDX_DOC_CUST_ID_DATE) */';
--	elsif userLogin is not null then
--		rq := rq || ' /*+ INDEX (p IDX_DOC_WOC_ID_DATE) */';
--	end if;
	rq := rq || ' p.id pId,';
	rq := rq || ' p.class_id class,';
	rq := rq || ' p.status_id status,';
	rq := rq || ' p.card_cortex_proc_success cortex_status,';
	rq := rq || ' p.order_date created,';
	rq := rq || ' p.document_number docNumber,';
	rq := rq || ' (select login from ways_of_connection where id = p.creator_woc_id) login,';
	rq := rq || ' (NVL(p.card_pan, (SELECT pan from card_cards WHERE internal_id = p.from_card))) subject,';
	rq := rq || ' (select country from cusd where id = p.from_customer) country';
    rq := rq || ' , (select max(additional_info) from document_extensions where document_id = p.id and ( dictionary_id = ''3390'' or dictionary_id = ''3390RO'' )) overdraft_amount';
    rq := rq || ' , (select segment from cusd c where c.id = p.from_customer) segment';
    rq := rq || ' , p.change_officer_id processedBy ';
    rq := rq || ' , p.from_location fromLocation';

	rq := rq || ' from documents p';
	rq := rq || ' where rownum <= :ResultSetSize';
	rq := rq || ' and ' || bocommon.order_date_expression(custId, custName, userLogin, remoteId);
	rq := rq || ' and p.class_id in (' || docClass || ')';
	rq := rq || ' and p.status_id in (' || statuses || ')';
	rq := rq || ' and p.creator_channel_id in (' || channels_mod || ')'; -- implemented channels_mod instead of channels to add quick auth channel to internetbank 2016-09-21
    rq := rq || ' and p.class_id in ( 10,11,12,13,17,18,19,500,501,519,510,511,513,522,523,526,531,532,535,536,756,528)';
    
	if custId is not null then
		rq := rq || ' and p.from_customer = :CustomerId';
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
	if fromLocation is not null then
		rq := rq || ' and upper(p.from_location) like :FromLocation';
	end if;

	cursor_name := dbms_sql.open_cursor;

	dbms_sql.parse(cursor_name, rq, dbms_sql.native);
	dbms_sql.bind_variable(cursor_name, ':ResultSetSize', bocommon.ResultSetSize);
	dbms_sql.bind_variable(cursor_name, ':DateFrom', createdFrom);
	dbms_sql.bind_variable(cursor_name, ':DateTill', createdTill);
	if custId is not null then
		dbms_sql.bind_variable(cursor_name, ':CustomerId', custId);
	end if;
	if userLogin is not null then
		dbms_sql.bind_variable(cursor_name, ':UserLogin', userLogin);
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
	officerId in integer,

	-- document
	docClass in varchar2,
	fromLocation in varchar2,

	-- system
	docId in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date,
	channels in varchar2
) return cursor_t is
begin
	if docId is not null then
		return find_by_id(docId, docClass);
	end if;
	return find_by_filter(
		custId,
		custName,
		userLogin,
		officerId,
		docClass,
		fromLocation,
		statuses,
		createdFrom,
		createdTill,
		channels
	);
end;

function find_my(pOfficerId in integer, docClass in varchar2) return cursor_t is
	rv cursor_t;
	t_classes num_table_type := bocommon.str2table(docClass);
begin
	-- Card orders in statuses:
	--  5, Signature Ok;
	-- 11, Printed;
	-- 15, Message sent;
	-- 16, Partly executed.
	open rv for select
		/* BOCards.find_my */
		/*+ INDEX (p IDX_DOC_STATUS_CLASS) */
		p.id pId,
		p.class_id class,
		p.status_id status,
		p.card_cortex_proc_success cortex_status,
		p.order_date created,
		p.document_number docNumber,
		(select login from ways_of_connection where id = p.creator_woc_id) login,
		NVL(p.card_pan, (SELECT pan from card_cards WHERE internal_id = p.from_card)) subject,
		(select country from cusd where id = p.from_customer) country
        --, p.credit_amount overdraft_amount
        , (select max(nvl(e.additional_info, '')) from document_extensions e where e.document_id = p.id and (e.dictionary_id = '3390' OR e.dictionary_id ='3390RO')) overdraft_amount
        , (select segment from cusd c where c.id = p.from_customer) segment 
        , p.change_officer_id processedBy
        , p.from_location fromLocation
	from documents p
	where rownum <= bocommon.ResultSetSize
		and p.class_id in (select * from table(cast(t_classes as num_table_type)))
        and (
            (pOfficerId = 0 and p.status_id in (5, 11, 15, 16))
             or
             (p.change_officer_id = pOfficerId and p.status_id in (RBA_CONST.MANUAL_PROCESSING_STARTED, RBA_CONST.PRINTED))
              )
        and p.class_id in ( 10,11,12,13,17,18,19,500,501,519,510,511,513,522,523,526,531,532,535,536,756,528)
        ;
	return rv;
end;

procedure card(
	pId in varchar2,
	userName out varchar2,
	userId out varchar2,
	officerName out varchar2,
	custName out varchar2,
	custCountry out varchar2,
	custAccount out varchar2,
	-- card orders:
	grpId out varchar2,
	grpName out varchar2,
	prodName out varchar2,
	prodCCY out varchar2,
	pan out varchar2,
	pEmail out varchar2,
	pPhone out varchar2,
	pMobile out varchar2,
	--
	chargesAcsdId out varchar2,
	interestIban out varchar2,
	issueForAccount out varchar2,
	issueForCustomer out varchar2,
	cardStan out varchar2,
	cardStatusFrom out varchar2,
	cardStatusTo out varchar2,
	cortexStatus out integer,
	cortexDetails out varchar2,
	lostType out integer,
	lostDate out date,
	--
	ffText out varchar2,
	pLocation out varchar2,
	--
	itc out varchar2,
	itb out varchar2,
	signTime out date,
	signDevType out integer,
	signDevId out varchar2,
	signKey1 out varchar2,
	signKey2 out varchar2
) is
begin
	select /* BOCards.card */
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
			c.name.name_en
		)), c.name.name_en) || ' (' || c.id || ')',
		c.country,
		nvl(a.iban, a.mccy_accnum || ' ' || a.sub_accnum) || ' ' || a.ccy,
		d.card_crdgroup_id,
		nvl(trim(decode(bocommon.LanguageId,
			0, cg.name.name_lv,
			1, cg.name.name_en,
			2, cg.name.name_ru,
			3, cg.name.extra_1,
			4, cg.name.extra_2,
			5, cg.name.extra_3,
			cg.name.name_en
		)), cg.name.name_en),
		nvl(trim(decode(bocommon.LanguageId,
			0, cp.name.name_lv,
			1, cp.name.name_en,
			2, cp.name.name_ru,
			3, cp.name.extra_1,
			4, cp.name.extra_2,
			5, cp.name.extra_3,
			cp.name.name_en
		)), cp.name.name_en),
		d.debit_ccy,
		NVL(d.card_pan, (SELECT pan from card_cards WHERE internal_id = d.from_card)) card_pan,
		d.email,
		d.phone_home,
		d.phone_mobile,
		--
		nvl(charges_id.iban, charges_id.mccy_accnum || ' ' || charges_id.sub_accnum) || ' ' || charges_id.ccy,
		ben_iban,
		nvl(iaid.iban, iaid.mccy_accnum || ' ' || iaid.sub_accnum) || ' ' || iaid.ccy,
		nvl(trim(decode(bocommon.LanguageId,
			0, icid.name.name_lv,
			1, icid.name.name_en,
			2, icid.name.name_ru,
			3, icid.name.extra_1,
			4, icid.name.extra_2,
			5, icid.name.extra_3,
			icid.name.name_en
		)), icid.name.name_en) || decode(icid.id, null, '', ' (' || icid.id || ')'),
		d.card_stan,
		d.card_status_from,
		d.card_status_to,
		d.card_cortex_proc_success,
		d.card_cortex_proc_details,
		d.card_loss_type,
		d.card_loss_date,
		d.ff_text,
		d.from_location,
		d.info_to_customer,
		d.info_to_bank,
		d.signature_date,
		d.signature_cdevice_type_id,
		d.signature_cdevice_serial,
		d.signature_key_1,
		d.signature_key_2
	into
		userName,
		userId,
		officerName,
		custName,
		custCountry,
		custAccount,
		grpId,
		grpName,
		prodName,
		prodCCY,
		pan,
		pEmail,
		pPhone,
		pMobile,
		--
		chargesAcsdId,
		interestIban,
		issueForAccount,
		issueForCustomer,
		cardStan,
		cardStatusFrom,
		cardStatusTo,
		cortexStatus,
		cortexDetails,
		lostType,
		lostDate,
		ffText,
		pLocation,
		itc,
		itb,
		signTime,
		signDevType,
		signDevId,
		signKey1,
		signKey2
	from documents d, v$users u,
		ibglb.card_crdtypes cp, ibglb.glb_bank_products cg,
		acsd a, acsd charges_id, acsd iaid,
		cusd c, cusd icid, ways_of_connection w,
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
		d.card_type = cp.id(+) and
		d.card_crdgroup_id = cg.id(+) and
		d.charges_account_id = charges_id.id(+) and
		d.card_issue_for_acsd_id = iaid.id(+) and
		d.card_issue_for_cusd_id = icid.id(+);
end;

procedure get_lost_addr(
	pId in varchar2,
	lostCountry out varchar2,
	lostCity out varchar2
) is
begin
	select /* BOCards.get_lost_addr */
		nvl((select nvl(trim(decode(bocommon.LanguageId,
				0, c.name.name_lv,
				1, c.name.name_en,
				2, c.name.name_ru,
				3, c.name.extra_1,
				4, c.name.extra_2,
				5, c.name.extra_3,
				c.name.name_en)), c.name.name_en)
			from ibglb.glb_countries c
			where c.id(+) = addr_country), addr_country),
		addr_city
	into lostCountry, lostCity
	from document_addresses
	where document_id = pId;
end;

procedure get_issue_addr(
	pId in varchar2,
	pReceivingType out integer,
	pOffice out varchar2,
	pCountry out varchar2,
	pAddress out varchar2
) is
begin
	select /* BOCards.get_issue_addr */
		receiving_type,
		nvl((select nvl(trim(decode(bocommon.LanguageId,
				0, ccs.name.name_lv,
				1, ccs.name.name_en,
				2, ccs.name.name_ru,
				3, ccs.name.extra_1,
				4, ccs.name.extra_2,
				5, ccs.name.extra_3,
				ccs.name.name_en)), ccs.name.name_en)
			from ibglb.card_client_service_centres ccs
			where bank_office_name = ccs.id(+)),
		bank_office_name),
		nvl((select nvl(trim(decode(bocommon.LanguageId,
				0, c.name.name_lv,
				1, c.name.name_en,
				2, c.name.name_ru,
				3, c.name.extra_1,
				4, c.name.extra_2,
				5, c.name.extra_3,
				c.name.name_en)), c.name.name_en)
			from ibglb.glb_countries c
			where c.id(+) = addr_country), addr_country),
		addr_zip || ', ' || addr_city || ', ' || addr_street || ', ' ||
		addr_house || ', ' || addr_apart
	into pReceivingType, pOffice, pCountry, pAddress
	from document_addresses
	where document_id = pId;
end;

function get_extensions(pId in varchar2) return cursor_t is
	rv cursor_t;
begin
	open rv for select /* BOCards.get_extensions */
		(dictionary_id || '-' || block_number) block_id,
		decode(field_type,
			13, -- FIELD_BRANCH
			additional_info || ', '	||
				(select nvl(trim(decode(bocommon.LanguageId,
					0, ccs.name.name_lv,
					1, ccs.name.name_en,
					2, ccs.name.name_ru,
					3, ccs.name.extra_1,
					4, ccs.name.extra_2,
					5, ccs.name.extra_3,
					ccs.name.name_en)), ccs.name.name_en)
				from ibglb.card_client_service_centres ccs
				where additional_info = ccs.id(+)),
			19, -- GLB_CUST_ACTIVITY_TYPE
			additional_info || ', '	||
				(select nvl(trim(decode(bocommon.LanguageId,
					0, cat.name.name_lv,
					1, cat.name.name_en,
					2, cat.name.name_ru,
					3, cat.name.extra_1,
					4, cat.name.extra_2,
					5, cat.name.extra_3,
					cat.name.name_en)), cat.name.name_en)
				from ibglb.glb_cust_activity_types cat
				where additional_info = cat.id(+)),
		additional_info) info,
		block_number,
		(select max(block_number) from document_extensions de
			where de.document_id = pId and de.dictionary_id = d.dictionary_id) total_blocks
	from dictionary dict, document_extensions d
	where document_id = pId and dict.id = dictionary_id
	order by dictionary_id;
	return rv;
end;

function set_processing(pId in varchar2, pStatusIdFrom in integer) return integer is
    vRes int;
begin
    vRes := 0;

    update documents
    set change_officer_id = bocommon.officerId
    where id = pId
        --and status_id in (RBA_CONST.SIGNATURE_OK, RBA_CONST.CONFIRM_OK, RBA_CONST.MANUAL_PROCESSING_STARTED, RBA_CONST.PRINTED)
        and status_id = pStatusIdFrom
    returning change_officer_id into vRes;

    if vRes > 0 then
      -- if pStatusIdFrom in (RBA_CONST.SIGNATURE_OK, RBA_CONST.CONFIRM_OK, RBA_CONST.MANUAL_PROCESSING_STARTED )then
      --    bodocuments.set_manual_status(pId, null, RBA_CONST.MANUAL_PROCESSING_STARTED, 24403);
      -- end if; 
       if pStatusIdFrom in (RBA_CONST.PRINTED) then
          bodocuments.set_manual_status(pId, null, RBA_CONST.PRINTED, 24403);
       else
          bodocuments.set_manual_status(pId, null, RBA_CONST.MANUAL_PROCESSING_STARTED, 24403);
       end if;
    else
        vRes := 0;
    end if;

    return vRes;
end;

end;
/

show err;
