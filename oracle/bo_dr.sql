/*
* Deposit requests.
*/

create or replace package BODR as

type cursor_t is ref cursor;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,
	userLogin in varchar2,
	officerId in integer,

	-- document
	pClassId in integer,
	pTerm in varchar2,
	amountFrom in varchar2,
	amountTill in varchar2,
	currencies in varchar2,

	-- system
	docId in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t;

procedure dr(
	pId in varchar2,
	pClassId out integer,
	globusNo out varchar2,
	userName out varchar2,
	userId out varchar2,
	officerName out varchar2,
	custName out varchar2,
	custAccount out varchar2,
	rate out varchar2,
	product out varchar2,
	frequency out varchar2,
	benName out varchar2,
	benIban out varchar2,
	agreement out varchar2,
	pLocation out varchar2,
	pValueDate out date,
	pFromContract out varchar2,
	pLoyaltyBonus out varchar2,
	pStartAmount out varchar2,
	pStartCcy out varchar2,
	pCurrentAmount out varchar2,
	pCurrentCcy out varchar2,
	pReplenishmentAmount out varchar2,
	pReplenishmentCcy out varchar2,
	pStartDate out date,
	pTermDate out date,
	itc out varchar2,
	itb out varchar2,
	--signTime out date,
	--signDevType out integer,
	--signDevId out varchar2,
	--signKey1 out varchar2,
	--signKey2 out varchar2,
	pRejector out varchar2,
	pRejectDate out date,
	TypeId out integer
);

end;
/

show err;

create or replace package body BODR as

function find_by_id(
	docId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		/* BODR.find_by_id */
		p.id pId,
		p.class_id class_id,
		p.status_id status,
		p.order_date created,
		p.document_number docNumber,
		(select login from ways_of_connection where id = p.creator_woc_id) login,
		length(p.info_to_bank) ITB,
		bocommon.FormatAmount(p.debit_amount, p.debit_ccy) db_amount,
		nvl(p.debit_ccy, p.credit_ccy) ccy,
		p.deposit_term term,
		(select nvl(iban, mccy_accnum || ' ' || sub_accnum) || ' ' || ccy from acsd a where a.id = p.from_account) fromAccount
	from documents p
	where p.id = docId and p.class_id in (80, 502, 503, 504, 505, 506, 517, 518, 537, 538, 796, 797);
	return rv;
end;

function execute_by_filter(
	pCursorName in integer
) return cursor_t is
	cursor_name integer := pCursorName;
	rv cursor_t;
	row dr_t;
	rows_processed integer;
	rowset dr_set_t := dr_set_t();
	pId number(14);
	class_id number(3);
	status number(2);
	created date;
	docNumber varchar2(16);
	login varchar2(60);
	itb integer;
	db_amount varchar2(32);
	ccy varchar2(3);
	term varchar2(3);
	fromAccount varchar2(32);
begin
	dbms_sql.define_column(cursor_name,  1, pId);
	dbms_sql.define_column(cursor_name,  2, class_id);
	dbms_sql.define_column(cursor_name,  3, status);
	dbms_sql.define_column(cursor_name,  4, created);
	dbms_sql.define_column(cursor_name,  5, docNumber, 16);
	dbms_sql.define_column(cursor_name,  6, login, 60);
	dbms_sql.define_column(cursor_name,  7, itb);
	dbms_sql.define_column(cursor_name,  8, db_amount, 32);
	dbms_sql.define_column(cursor_name,  9, ccy, 3);
	dbms_sql.define_column(cursor_name, 10, term, 3);
	dbms_sql.define_column(cursor_name, 11, fromAccount, 32);

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name,  1, pId);
		dbms_sql.column_value(cursor_name,  2, class_id);
		dbms_sql.column_value(cursor_name,  3, status);
		dbms_sql.column_value(cursor_name,  4, created);
		dbms_sql.column_value(cursor_name,  5, docNumber);
		dbms_sql.column_value(cursor_name,  6, login);
		dbms_sql.column_value(cursor_name,  7, itb);
		dbms_sql.column_value(cursor_name,  8, db_amount);
		dbms_sql.column_value(cursor_name,  9, ccy);
		dbms_sql.column_value(cursor_name, 10, term);
		dbms_sql.column_value(cursor_name, 11, fromAccount);
		row := dr_t(
			pId,
			class_id,
			status,
			created,
			docNumber,
			login,
			itb,
			db_amount,
			ccy,
			term,
			fromAccount
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as dr_set_t));
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
	pClassId in integer,
	pTerm in varchar2,
	amountFrom in varchar2,
	amountTill in varchar2,
	currencies in varchar2,
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

	rq := rq || 'select /* BODR.find_by_filter */';
--	if custId is not null or custName is not null or remoteId > 0 then
--		rq := rq || ' /*+ INDEX (p IDX_DOC_CUST_ID_DATE) */';
--	elsif userLogin is not null then
--		rq := rq || ' /*+ INDEX (p IDX_DOC_WOC_ID_DATE) */';
--	end if;
	rq := rq || ' p.id pId,';
	rq := rq || ' p.class_id class_id,';
	rq := rq || ' p.status_id status,';
	rq := rq || ' p.order_date created,';
	rq := rq || ' p.document_number docNumber,';
	rq := rq || ' (select login from ways_of_connection where id = p.creator_woc_id) login,';
	rq := rq || ' length(p.info_to_bank) ITB,';
	rq := rq || ' bocommon.FormatAmount(p.debit_amount, p.debit_ccy) db_amount,';
	rq := rq || ' nvl(p.debit_ccy, p.credit_ccy) ccy,';
	rq := rq || ' p.deposit_term term,';
	rq := rq || ' (select nvl(iban, mccy_accnum || '' '' || sub_accnum) || '' '' || ccy from acsd a where a.id = p.from_account) fromAccount';
	rq := rq || ' from documents p';
	rq := rq || ' where rownum <= :ResultSetSize';
	rq := rq || ' and ' || bocommon.order_date_expression(custId, custName, userLogin, remoteId);
	rq := rq || ' and p.class_id = ' || pClassId;
	rq := rq || ' and p.status_id in (' || statuses || ')';
	if custId is not null then
		rq := rq || ' and p.from_customer = :CustomerId';
	end if;
	if currencies is not null then
		rq := rq || ' and (:CCY = p.debit_ccy or :CCY = p.credit_ccy)';
	end if;
	if pTerm is not null then
		rq := rq || ' and p.deposit_term like :Term';
	end if;
	if amountFrom is not null and amountTill is not null then
		rq := rq || ' and (p.debit_amount is null or p.debit_amount between :AMOUNT_FROM and :AMOUNT_TO)';
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
	if currencies is not null then
		dbms_sql.bind_variable(cursor_name, ':CCY', currencies);
	end if;
	if pTerm is not null then
		dbms_sql.bind_variable(cursor_name, ':Term', bocommon.prepare_like(pTerm));
	end if;
	if amountFrom is not null and amountTill is not null then
		dbms_sql.bind_variable(cursor_name, ':AMOUNT_FROM', amountFrom);
		dbms_sql.bind_variable(cursor_name, ':AMOUNT_TO', amountTill);
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
	pClassId in integer,
	pTerm in varchar2,
	amountFrom in varchar2,
	amountTill in varchar2,
	currencies in varchar2,

	-- system
	docId in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t is
begin
	if docId is not null then
		return find_by_id(docId);
	end if;
	return find_by_filter(
		custId,
		custName,
		userLogin,
		officerId,
		pClassId,
		pTerm,
		amountFrom,
		amountTill,
		currencies,
		statuses,
		createdFrom,
		createdTill
	);
end;

procedure dr(
	pId in varchar2,
	pClassId out integer,
	globusNo out varchar2,
	userName out varchar2,
	userId out varchar2,
	officerName out varchar2,
	custName out varchar2,
	custAccount out varchar2,
	rate out varchar2,
	product out varchar2,
	frequency out varchar2,
	benName out varchar2,
	benIban out varchar2,
	agreement out varchar2,
	pLocation out varchar2,
	pValueDate out date,
	pFromContract out varchar2,
	pLoyaltyBonus out varchar2,
	pStartAmount out varchar2,
	pStartCcy out varchar2,
	pCurrentAmount out varchar2,
	pCurrentCcy out varchar2,
	pReplenishmentAmount out varchar2,
	pReplenishmentCcy out varchar2,
	pStartDate out date,
	pTermDate out date,
	itc out varchar2,
	itb out varchar2,
	--signTime out date,
	--signDevType out integer,
	--signDevId out varchar2,
	--signKey1 out varchar2,
	--signKey2 out varchar2,
	pRejector out varchar2,
	pRejectDate out date,
	TypeId out integer
) is
	customRate documents.annual_interest_custom%type := null;
	lob clob;
begin
	select /* BODR.dr */
		d.class_id,
		d.bank_reference,
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
		nvl(a.iban, a.mccy_accnum || ' ' || a.sub_accnum) || ' ' || a.ccy,
		d.info_to_customer,
		d.info_to_bank,
		--d.signature_date,
		--d.signature_cdevice_type_id,
		--d.signature_cdevice_serial,
		--d.signature_key_1,
		--d.signature_key_2,
		d.annual_interest_rate,
		d.annual_interest_custom,
		nvl(trim(decode(bocommon.LanguageId,
			0, dp.description.name_lv,
			1, dp.description.name_en,
			2, dp.description.name_ru,
			3, dp.description.extra_1,
			4, dp.description.extra_2,
			5, dp.description.extra_3,
			dp.description.name_en
		)), dp.description.name_en),
		d.payment_frequency,
		d.ben_name,
		d.ben_iban || ' ' || d.credit_ccy,
		d.from_location,
		ag.text,
		decode(ro.id, null, '', '(' || ro.id || ') ' || ro.officer_name),
		d.reject_date,
		d.type_id,
		d.date_payment_first,
		d.from_contract,
		d.bonus_value,
		d.start_amount,
		d.start_currency,
		d.current_amount,
		d.current_currency,
		d.credit_amount,
		d.credit_ccy,
		d.ut_date_start,
		d.ut_date_end
	into
		pClassId,
		globusNo,
		userName,
		userId,
		officerName,
		custName,
		custAccount,
		itc,
		itb,
		--signTime,
		--signDevType,
		--signDevId,
		--signKey1,
		--signKey2,
		rate,
		customRate,
		product,
		frequency,
		benName,
		benIban,
		pLocation,
		lob,
		pRejector,
		pRejectDate,
		TypeId,
		pValueDate,
		pFromContract,
		pLoyaltyBonus,
		pStartAmount,
		pStartCcy,
		pCurrentAmount,
		pCurrentCcy,
		pReplenishmentAmount,
		pReplenishmentCcy,
		pStartDate,
		pTermDate
	--from documents d, v$users u, acsd a, cusd c, agreement_texts ag,
    from documents d, v$users u, acsd a, cusd c, agreement ag,
		ibglb.glb_deposit_products dp, ways_of_connection w,
		ibglb.glb_dept_accnt_officer ro,
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
		dp.id(+) = d.deposit_product_id and
		u.id = d.creator_user_id and
		w.id(+) = d.creator_woc_id and
		ro.id(+) = d.rejector_id and
		ag.id(+) = d.agreement_text_id;
	if customRate is not null then
		rate := customRate;
	end if;
	if lob is not null then
		agreement := dbms_lob.substr(lob, 10000);
		agreement := agreement || chr(10) || '...';
	end if;
end;

end;
/

show err;
