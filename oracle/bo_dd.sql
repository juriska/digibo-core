/*
* Direct debit orders.
*/

create or replace package BODD as

type cursor_t is ref cursor;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,
	userLogin in varchar2,
	officerId in integer,

	-- document
	pType in varchar2,

	-- system
	docId in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t;

procedure dd(
	pId in varchar2,
	userName out varchar2,
	userId out varchar2,
	officerName out varchar2,
	custName out varchar2,
	custAccount out varchar2,
	globusNo out varchar2,
-- Order part.
	agreement out varchar2,
	contractId out varchar2,
	firstDate out date,
	lastDate out date,
	benName out varchar2,
	utPhoneNo out varchar2,
	amountLimit out varchar2,
	abCode out varchar2,
	abName out varchar2,
	abSurname out varchar2,
	abAcnt out varchar2,
	abId out varchar2,
	giroNr out varchar2,
	legalAddr out varchar2,
	contactAddr out varchar2,
	pEMail out varchar2,
	pLocation out varchar2,
	pRejector out varchar2,
	pRejectDate out date,
--
	itc out varchar2,
	itb out varchar2--,
	--signTime out date,
	--signDevType out integer,
	--signDevId out varchar2,
	--signKey1 out varchar2,
	--signKey2 out varchar2
);

end;
/

show err;

create or replace package body BODD as

function find_by_id(
	docId in varchar2,
	pType in varchar2
) return cursor_t is
	rv cursor_t;
	t_classes num_table_type := bocommon.str2table(pType);
begin
	open rv for select
		/* BODD.find_by_id */
		p.id pId,
		p.status_id status,
		p.class_id class,
		p.order_date created,
		p.document_number docNumber,
		w.login login,
		length(p.info_to_bank) ITB,
		bocommon.FormatAmount(p.credit_amount, p.credit_ccy) cr_amount,
		bocommon.FormatAmount(p.debit_amount, p.debit_ccy) db_amount,
		p.credit_ccy cr_ccy,
		p.debit_ccy db_ccy
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
	row dd_t;
	rows_processed integer;
	rowset dd_set_t := dd_set_t();
	pId number(14);
	status number(2);
	class number(4);
	created date;
	docNumber varchar2(16);
	login varchar2(60);
	itb integer;
	cr_amount varchar2(32);
	db_amount varchar2(32);
	cr_ccy varchar2(3);
	db_ccy varchar2(3);
begin
	dbms_sql.define_column(cursor_name,  1, pId);
	dbms_sql.define_column(cursor_name,  2, status);
	dbms_sql.define_column(cursor_name,  3, class);
	dbms_sql.define_column(cursor_name,  4, created);
	dbms_sql.define_column(cursor_name,  5, docNumber, 16);
	dbms_sql.define_column(cursor_name,  6, login, 60);
	dbms_sql.define_column(cursor_name,  7, itb);
	dbms_sql.define_column(cursor_name,  8, cr_amount, 32);
	dbms_sql.define_column(cursor_name,  9, db_amount, 32);
	dbms_sql.define_column(cursor_name, 10, cr_ccy, 3);
	dbms_sql.define_column(cursor_name, 11, db_ccy, 3);

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name,  1, pId);
		dbms_sql.column_value(cursor_name,  2, status);
		dbms_sql.column_value(cursor_name,  3, class);
		dbms_sql.column_value(cursor_name,  4, created);
		dbms_sql.column_value(cursor_name,  5, docNumber);
		dbms_sql.column_value(cursor_name,  6, login);
		dbms_sql.column_value(cursor_name,  7, itb);
		dbms_sql.column_value(cursor_name,  8, cr_amount);
		dbms_sql.column_value(cursor_name,  9, db_amount);
		dbms_sql.column_value(cursor_name, 10, cr_ccy);
		dbms_sql.column_value(cursor_name, 11, db_ccy);
		row := dd_t(
			pId,
			status,
			class,
			created,
			docNumber,
			login,
			itb,
			cr_amount,
			db_amount,
			cr_ccy,
			db_ccy
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as dd_set_t));
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

	rq := rq || 'select /* BODD.find_by_filter */';
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
	rq := rq || ' length(p.info_to_bank) ITB,';
	rq := rq || ' bocommon.FormatAmount(p.credit_amount, p.credit_ccy) cr_amount,';
	rq := rq || ' bocommon.FormatAmount(p.debit_amount, p.debit_ccy) db_amount,';
	rq := rq || ' p.credit_ccy cr_ccy,';
	rq := rq || ' p.debit_ccy db_ccy';
	rq := rq || ' from documents p';
	rq := rq || ' where rownum <= :ResultSetSize';
	rq := rq || ' and ' || bocommon.order_date_expression(custId, custName, userLogin, remoteId);
	rq := rq || ' and p.class_id in (' || pType || ')';
	rq := rq || ' and p.status_id in (' || statuses || ')';
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
		statuses,
		createdFrom,
		createdTill
	);
end;

procedure dd(
	pId in varchar2,
	userName out varchar2,
	userId out varchar2,
	officerName out varchar2,
	custName out varchar2,
	custAccount out varchar2,
	globusNo out varchar2,
-- Order part.
	agreement out varchar2,
	contractId out varchar2,
	firstDate out date,
	lastDate out date,
	benName out varchar2,
	utPhoneNo out varchar2,
	amountLimit out varchar2,
	abCode out varchar2,
	abName out varchar2,
	abSurname out varchar2,
	abAcnt out varchar2,
	abId out varchar2,
	giroNr out varchar2,
	legalAddr out varchar2,
	contactAddr out varchar2,
	pEMail out varchar2,
	pLocation out varchar2,
	pRejector out varchar2,
	pRejectDate out date,
--
	itc out varchar2,
	itb out varchar2--,
	--signTime out date,
	--signDevType out integer,
	--signDevId out varchar2,
	--signKey1 out varchar2,
	--signKey2 out varchar2
) is
	addr cursor_t;
	t_type_id integer;
	t_receiving_type integer;
	t_bank_office_name varchar2(1000);
	t_addr varchar2(1000);
begin
    null;
--	select /* BODD.dd */
--		d.bank_reference,
--		u.name || ' (' || w.login || ')',
--		u.personal_id,
--		remote_officer.name,
--		nvl(trim(decode(bocommon.LanguageId,
--			0, c.name.name_lv,
--			1, c.name.name_en,
--			2, c.name.name_ru,
--			3, c.name.extra_1,
--			4, c.name.extra_2,
--			5, c.name.extra_3,
--			c.name.name_en
--		)), c.name.name_en) || ' (' || c.id || ')',
--		nvl(a.iban, a.mccy_accnum || ' ' || a.sub_accnum) || ' ' || a.ccy,
--		ag.text,
--		d.from_contract,
--		d.date_payment_first,
--		d.date_payment_last,
--		ucc.corp_cust_name,
--		d.ut_phone_number,
--		d.debit_amount_maximal,
--		d.abonent_code,
--		d.abonent_name,
--		d.abonent_surname,
--		d.abonent_account,
--		d.abonent_legal_id,
--		d.giro_no,
--		d.info_to_customer,
--		d.info_to_bank,
--		--d.signature_date,
--		--d.signature_cdevice_type_id,
--		--d.signature_cdevice_serial,
--		--d.signature_key_1,
--		--d.signature_key_2,
--		d.email,
--		d.from_location,
--		decode(ro.id, null, '', '(' || ro.id || ') ' || ro.officer_name),
--		d.reject_date
--	into
--		globusNo,
--		userName,
--		userId,
--		officerName,
--		custName,
--		custAccount,
--		agreement,
--		contractId,
--		firstDate,
--		lastDate,
--		benName,
--		utPhoneNo,
--		amountLimit,
--		abCode,
--		abName,
--		abSurname,
--		abAcnt,
--		abId,
--		giroNr,
--		itc,
--		itb,
--		--signTime,
--		--signDevType,
--		--signDevId,
--		--signKey1,
--		--signKey2,
--		pEMail,
--		pLocation,
--		pRejector,
--		pRejectDate
--	from documents d, v$users u, acsd a, cusd c, agreement_texts ag,
--		ibglb.ut_corp_customer ucc, ways_of_connection w,
--		ibglb.glb_dept_accnt_officer ro,
--		(select d.id id, o.officer_name name
--		from documents d, acsd a, cusd c, ibglb.glb_dept_accnt_officer o
--		where d.id = pId and
--			a.id = d.from_account and
--			c.id = d.from_customer and
--			o.id = c.remote_officers.get_id(a.location)
--		) remote_officer
--	where d.id = pId and d.id = remote_officer.id(+) and
--		a.id(+) = d.from_account and
--		c.id(+) = d.from_customer and
--		u.id = d.creator_user_id and
--		w.id(+) = d.creator_woc_id and
--		ro.id(+) = d.rejector_id and
--		ag.id(+) = d.agreement_text_id and
--		ucc.corp_cust_code(+) = d.ut_corp_cust_code;
--
--	open addr for select type_id, receiving_type, bank_office_name,
--		addr_zip || ', ' || addr_country || ', ' ||
--		addr_city || ', ' || addr_street || ', ' ||
--		addr_house || ', ' || addr_apart address
--	from document_addresses
--	where document_id = pId;
--	fetch addr into t_type_id, t_receiving_type, t_bank_office_name, t_addr;
--	while addr%found loop
--		if 1 = t_type_id then -- issuer.
--			if 1 = t_receiving_type then -- in office.
--				legalAddr := t_bank_office_name;
--			else
--				legalAddr := t_addr;
--			end if;
--		elsif 3 = t_type_id then -- contact.
--			if 1 = t_receiving_type then -- in office.
--				contactAddr := t_bank_office_name;
--			else
--				contactAddr := t_addr;
--			end if;
--		end if;
--		fetch addr into t_type_id, t_receiving_type, t_bank_office_name, t_addr;
--	end loop;
--	close addr;
end;

end;
/

show err;
