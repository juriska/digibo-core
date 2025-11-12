/*
* Payments.
*/

create or replace package BOPayment as

type cursor_t is ref cursor;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,
	userLogin in varchar2,
	officerId in integer,

	-- payment
	benName in varchar2,
	pmtDetails in varchar2,
	fromContract in varchar2,
	amountFrom in varchar2,
	amountTill in varchar2,
	currencies in varchar2,
	pmtClass in varchar2,
	effectFrom in date,
	effectTill in date,

	-- system
	paymentId in varchar2,
	channels in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t;

procedure payment(
	pId in varchar2,
	userName out varchar2,
	userId out varchar2,
	officerName out varchar2,
	custName out varchar2,
	custAccount out varchar2,
	benName out varchar2,
	benId out varchar2,
	benRes out varchar2,
	benCity out varchar2,
	benStreet out varchar2,
	benAcnt out varchar2,
	benType out varchar2,
	ordName out varchar2,
	ordId out varchar2,
	ordRes out varchar2,
	ordAcnt out varchar2,
	benBankName out varchar2,
	benBankBranch out varchar2,
	benBankSwiftCode out varchar2,
	benBankOtherCode out varchar2,
	benBankAddr out varchar2,
	imBankName out varchar2,
	imBankAcnt out varchar2,
	imBankSwiftCode out varchar2,
	imBankOtherCode out varchar2,
	imBankAddr out varchar2,
	paymentDetails out varchar2,
	itb out varchar2,
	itc out varchar2,
	epc out varchar2,
	itd out varchar2,
	exchangeRate out varchar2,
	comType out varchar2,
	typeId out integer,
	eCheque out varchar2,
	eExpiry out date,
	signTime out date,
	signDevType out integer,
	signDevId out varchar2,
	signKey1 out varchar2,
	signKey2 out varchar2,
	signRSA out varchar2,
	templateName out varchar2,
	pGlobusFt out varchar2,
	pBookingDate out date,
	pExecDate out date,
	taxPayerId out varchar2,
	isTaxDoc out integer,
	isUtPayment out integer,
	utTarifType out varchar2,
	utTarifPrice out varchar2,
	utTarifAmount out varchar2,
	utOverAmount out varchar2,
	utPenaltyType out varchar2,
	utPenaltyDays out integer,
	utPenaltyAmnt out varchar2,
	utBookingDate out date,
	utDateStart out date,
	utDateEnd out date,
	utVolumeStart out varchar2,
	utVolumeEnd out varchar2,
	utQuantity out varchar2,
	utCorpCustCode out varchar2,
	utCorpCustBranch out varchar2,
	utBillNumber out varchar2,
	utPhoneNumber out varchar2,
	abonentCode out varchar2,
	abonentName out varchar2,
	abonentSurname out varchar2,
	abonentAccount out varchar2,
	abonentLegalId out varchar2,
	pLocation out varchar2,
	pSavingAccChargeId out integer,
	pRejector out varchar2,
	pRejectDate out date,
	pChargesAccount out varchar2,
	pSalaryPaymentDate out date
);

end;
/

show err;

create or replace package body BOPayment as

function analyze(paymentId in varchar2) return documents.id%type is
	pid documents.id%type := null;
begin
	if paymentId is null then
		return null;
	end if;
	select payment_id into pid from stmt
	where appl_rec_id = upper(paymentId) and rownum = 1;
	return pid;
exception
	when NO_DATA_FOUND then
	begin
		pid := to_number(paymentId);
		return pid;
	exception
		when others then return null;
	end;
end;

function find_by_id(
	pId in documents.id%type,
	pmtClass in varchar2
) return cursor_t is
	rv cursor_t;
	t_classes num_table_type := bocommon.str2table(pmtClass);
begin
	open rv for select /* BOPayment.find_by_id */
		p.id id,
		p.class_id class_id,
		p.status_id status_id,
		p.order_date order_date,
		p.document_number document_number,
		p.creator_channel_id creator_channel_id,
		bocommon.FormatAmount(p.credit_amount, p.credit_ccy) credit_amount,
		bocommon.FormatAmount(p.debit_amount, p.debit_ccy) debit_amount,
		p.credit_ccy credit_ccy,
		p.debit_ccy debit_ccy,
		length(p.info_to_bank) ITB,
		(select login from ways_of_connection where id = p.creator_woc_id) login
	from documents p
	where p.id = pid and 
		p.class_id in (select * from table(cast(t_classes as num_table_type)));
	return rv;
end;

function find_by_reference(
	pReference in documents.bank_reference%type,
	pmtClass in varchar2
) return cursor_t is
	rv cursor_t;
	t_classes num_table_type := bocommon.str2table(pmtClass);
begin
	open rv for select /* BOPayment.find_by_reference */
		p.id id,
		p.class_id class_id,
		p.status_id status_id,
		p.order_date order_date,
		p.document_number document_number,
		p.creator_channel_id creator_channel_id,
		bocommon.FormatAmount(p.credit_amount, p.credit_ccy) credit_amount,
		bocommon.FormatAmount(p.debit_amount, p.debit_ccy) debit_amount,
		p.credit_ccy credit_ccy,
		p.debit_ccy debit_ccy,
		length(p.info_to_bank) ITB,
		(select login from ways_of_connection where id = p.creator_woc_id) login
	from documents p
	where p.bank_reference = pReference and 
		p.class_id in (select * from table(cast(t_classes as num_table_type)));
	return rv;
end;

function execute_by_filter(
	pCursorName in integer
) return cursor_t is
	cursor_name integer := pCursorName;
	rv cursor_t;
	row payment_t;
	rows_processed integer;
	rowset payments_set_t := payments_set_t();
	id number(14);
	class_id number(3);
	status_id number(2);
	order_date date;
	document_number varchar2(16);
	creator_channel_id number(2);
	credit_amount varchar2(32);
	debit_amount varchar2(32);
	credit_ccy varchar2(3);
	debit_ccy varchar2(3);
	itb integer;
	login varchar2(60);
begin
	dbms_sql.define_column(cursor_name,  1, id);
	dbms_sql.define_column(cursor_name,  2, class_id);
	dbms_sql.define_column(cursor_name,  3, status_id);
	dbms_sql.define_column(cursor_name,  4, order_date);
	dbms_sql.define_column(cursor_name,  5, document_number, 16);
	dbms_sql.define_column(cursor_name,  6, creator_channel_id);
	dbms_sql.define_column(cursor_name,  7, credit_amount, 32);
	dbms_sql.define_column(cursor_name,  8, debit_amount, 32);
	dbms_sql.define_column(cursor_name,  9, credit_ccy, 3);
	dbms_sql.define_column(cursor_name, 10, debit_ccy, 3);
	dbms_sql.define_column(cursor_name, 11, itb);
	dbms_sql.define_column(cursor_name, 12, login, 60);

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name,  1, id);
		dbms_sql.column_value(cursor_name,  2, class_id);
		dbms_sql.column_value(cursor_name,  3, status_id);
		dbms_sql.column_value(cursor_name,  4, order_date);
		dbms_sql.column_value(cursor_name,  5, document_number);
		dbms_sql.column_value(cursor_name,  6, creator_channel_id);
		dbms_sql.column_value(cursor_name,  7, credit_amount);
		dbms_sql.column_value(cursor_name,  8, debit_amount);
		dbms_sql.column_value(cursor_name,  9, credit_ccy);
		dbms_sql.column_value(cursor_name, 10, debit_ccy);
		dbms_sql.column_value(cursor_name, 11, itb);
		dbms_sql.column_value(cursor_name, 12, login);
		row := payment_t(
			id,
			class_id,
			status_id,
			order_date,
			document_number,
			creator_channel_id,
			credit_amount,
			debit_amount,
			credit_ccy,
			debit_ccy,
			itb,
			login
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as payments_set_t));
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
	benName in varchar2,
	pmtDetails in varchar2,
	fromContract in varchar2,
	amountFrom in varchar2,
	amountTill in varchar2,
	currencies in varchar2,
	pmtClass in varchar2,
	effectFrom in date,
	effectTill in date,
	channels in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t is
	custName varchar2(1024) := bocommon.prepare_like(pCustName);
	userLogin varchar2(1024) := bocommon.prepare_like(pUserLogin);
	remoteId integer := BODocuments.get_remote_officer(officerId);
	rq varchar2(32767);
	cursor_name integer;
begin
	if custName is not null or remoteId > 0 then
		delete from tmp_request_data;
		insert into tmp_request_data (requested_id)
		select distinct c.id from ibglb.cusd c
		where (remoteId <= 0 or	c.remote_officers.contains(remoteId) = 1) and
			(custName is null or c.name.is_like(custName) = 1);
	end if;

	rq := 'select /* BOPayment.find_by_filter */';
--	if custId is not null or custName is not null or remoteId > 0 then
--		rq := rq || ' /*+ INDEX (p IDX_DOC_CUST_ID_DATE) */';
--	elsif userLogin is not null then
--		rq := rq || ' /*+ INDEX (p IDX_DOC_WOC_ID_DATE) */';
--	else
--		rq := rq || ' /*+ INDEX (p IDX_DOC_ORDER_DATE) */';
--	end if;
	rq := rq || ' p.id id,';
	rq := rq || ' p.class_id class_id,';
	rq := rq || ' p.status_id status_id,';
	rq := rq || ' p.order_date order_date,';
	rq := rq || ' p.document_number document_number,';
	rq := rq || ' p.creator_channel_id creator_channel_id,';
	rq := rq || ' bocommon.FormatAmount(p.credit_amount, p.credit_ccy) credit_amount,';
	rq := rq || ' bocommon.FormatAmount(p.debit_amount, p.debit_ccy) debit_amount,';
	rq := rq || ' p.credit_ccy credit_ccy,';
	rq := rq || ' p.debit_ccy debit_ccy,';
	rq := rq || ' length(p.info_to_bank) ITB,';
	rq := rq || ' (select login from ways_of_connection where id = p.creator_woc_id) login';
	rq := rq || ' from documents p';
	rq := rq || ' where rownum <= :ResultSetSize';
	rq := rq || ' and p.order_date between :DateFrom and :DateTill';
	rq := rq || ' and p.class_id in (' || pmtClass || ')';
	rq := rq || ' and p.creator_channel_id in (' || channels || ')';
	rq := rq || ' and p.status_id in (' || statuses || ')';
	rq := rq || ' and (p.status_id != 20 or p.template_bank_visible = 1)';

	if custId is not null then
		rq := rq || ' and p.from_customer = :CustomerId';
	end if;
	if currencies is not null then
		rq := rq || ' and (p.credit_ccy = :CCY or p.debit_ccy = :CCY)';
	end if;
	if amountFrom is not null and amountTill is not null then
		rq := rq || ' and (p.credit_amount between :AmountFrom and :AmountTill or ' ||
			'p.debit_amount between :AmountFrom and :AmountTill)';
	end if;
	if benName is not null then
		rq := rq || ' and upper(p.ben_name) like :BenName';
	end if;
	if pmtDetails is not null then
		rq := rq || ' and upper(p.details) like :Details';
	end if;
	if fromContract is not null then
		rq := rq || ' and upper(p.from_contract) like :FromContract';
	end if;
	if effectFrom is not null and effectTill is not null then
		rq := rq || ' and p.execution_date between :EffectFrom and :EffectTill';
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
	if amountFrom is not null and amountTill is not null then
		dbms_sql.bind_variable(cursor_name, ':AmountFrom', amountFrom);
		dbms_sql.bind_variable(cursor_name, ':AmountTill', amountTill);
	end if;
	if benName is not null then
		dbms_sql.bind_variable(cursor_name, ':BenName', bocommon.prepare_like(benName));
	end if;
	if pmtDetails is not null then
		dbms_sql.bind_variable(cursor_name, ':Details', bocommon.prepare_like(pmtDetails));
	end if;
	if fromContract is not null then
		dbms_sql.bind_variable(cursor_name, ':FromContract', bocommon.prepare_like(fromContract));
	end if;
	if effectFrom is not null and effectTill is not null then
		dbms_sql.bind_variable(cursor_name, ':EffectFrom', effectFrom);
		dbms_sql.bind_variable(cursor_name, ':EffectTill', effectTill);
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

	-- payment
	benName in varchar2,
	pmtDetails in varchar2,
	fromContract in varchar2,
	amountFrom in varchar2,
	amountTill in varchar2,
	currencies in varchar2,
	pmtClass in varchar2,
	effectFrom in date,
	effectTill in date,

	-- system
	paymentId in varchar2,
	channels in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t is
	pid documents.id%type := analyze(paymentId);
begin
	if pid is not null then
		return find_by_id(pid, pmtClass);
	elsif paymentId is not null then
		return find_by_reference(paymentId, pmtClass);
	end if;
	return find_by_filter(
		custId,
		custName,
		userLogin,
		officerId,
		benName,
		pmtDetails,
		fromContract,
		amountFrom,
		amountTill,
		currencies,
		pmtClass,
		effectFrom,
		effectTill,
		channels,
		statuses,
		createdFrom,
		createdTill
	);
end;

procedure payment(
	pId in varchar2,
	userName out varchar2,
	userId out varchar2,
	officerName out varchar2,
	custName out varchar2,
	custAccount out varchar2,
	benName out varchar2,
	benId out varchar2,
	benRes out varchar2,
	benCity out varchar2,
	benStreet out varchar2,
	benAcnt out varchar2,
	benType out varchar2,
	ordName out varchar2,
	ordId out varchar2,
	ordRes out varchar2,
	ordAcnt out varchar2,
	benBankName out varchar2,
	benBankBranch out varchar2,
	benBankSwiftCode out varchar2,
	benBankOtherCode out varchar2,
	benBankAddr out varchar2,
	imBankName out varchar2,
	imBankAcnt out varchar2,
	imBankSwiftCode out varchar2,
	imBankOtherCode out varchar2,
	imBankAddr out varchar2,
	paymentDetails out varchar2,
	itb out varchar2, -- info to bank.
	itc out varchar2, -- info to customer.
	epc out varchar2, -- external payment code.
	itd out varchar2, -- info to dealer.
	exchangeRate out varchar2,
	comType out varchar2,
	typeId out integer,
	eCheque out varchar2,
	eExpiry out date,
	signTime out date,
	signDevType out integer,
	signDevId out varchar2,
	signKey1 out varchar2,
	signKey2 out varchar2,
	signRSA out varchar2,
	templateName out varchar2,
	pGlobusFt out varchar2,
	pBookingDate out date,
	pExecDate out date,
	taxPayerId out varchar2,
	isTaxDoc out integer,
	isUtPayment out integer,
	utTarifType out varchar2,
	utTarifPrice out varchar2,
	utTarifAmount out varchar2,
	utOverAmount out varchar2,
	utPenaltyType out varchar2,
	utPenaltyDays out integer,
	utPenaltyAmnt out varchar2,
	utBookingDate out date,
	utDateStart out date,
	utDateEnd out date,
	utVolumeStart out varchar2,
	utVolumeEnd out varchar2,
	utQuantity out varchar2,
	utCorpCustCode out varchar2,
	utCorpCustBranch out varchar2,
	utBillNumber out varchar2,
	utPhoneNumber out varchar2,
	abonentCode out varchar2,
	abonentName out varchar2,
	abonentSurname out varchar2,
	abonentAccount out varchar2,
	abonentLegalId out varchar2,
	pLocation out varchar2,
	pSavingAccChargeId out integer,
	pRejector out varchar2,
	pRejectDate out date,
	pChargesAccount out varchar2,
	pSalaryPaymentDate out date
) is
	statusId integer;
	globus_ft documents.bank_reference%type;
begin
	select /* BOPayment.payment */
		u.name || ' (' || wu.login || ')',
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
		nvl(ao.iban, ao.mccy_accnum || ' ' || ao.sub_accnum) || ' ' || ao.ccy,
		d.ben_name,
		d.ben_id,
		d.ben_residence,
		d.ben_city,
		d.ben_street,
		decode(ab.id,
			null, nvl(d.ben_iban, d.ben_account || ' ' || d.ben_sub_account),
			nvl(ab.iban, ab.mccy_accnum || ' ' || ab.sub_accnum) || ' ' || ab.ccy
		),
		d.ben_type,	
		d.ord_cust_name,
		d.ord_cust_id,
		d.ord_residence,
		d.ord_account,
		d.ben_bank_name,
		d.ben_bank_branch,
		d.ben_bank_swift_code,
		d.ben_bank_other_code,
		decode(d.ben_bank_street, null, '', d.ben_bank_street || ', ') ||
			decode(d.ben_bank_city, null, '',  d.ben_bank_city || ', ') ||
			d.ben_bank_country,
		d.im_bank_name,
		d.im_bank_ben_bank_account,
		d.im_bank_swift_code,
		d.im_bank_other_code,
		decode(d.im_bank_street, null, '', d.im_bank_street || ', ') ||
			decode(d.im_bank_city, null, '',  d.im_bank_city || ', ') ||
			d.im_bank_country,
		d.details,
		d.info_to_bank,
		d.info_to_customer,
		gppc.ppc_name,
		d.info_to_dealer,
		d.exchange_rate,
		d.type_id,
		decode(d.creator_channel_id,
			RBA_CONST.INET, 'IBTT' || d.id,
			RBA_CONST.CL_BANK, d.creator_user_id || '-' || d.cb_payment_id,
			RBA_CONST.DIGI_FIRMA, d.document_number
		) snip_id,
		d.expiry_date,
		d.signature_date,
		d.signature_cdevice_type_id,
		d.signature_cdevice_serial,
		d.signature_key_1,
		d.signature_key_2,
		substr(d.signature_rsa, instr(d.signature_rsa, ';') + 1),
		decode(d.interm_charges_payer_id,
			1, 'OUR',
			2, 'SHA',
			3, 'BEN',
			''
		),
		nvl(trim(decode(bocommon.LanguageId,
			0, d.template_name.name_lv,
			1, d.template_name.name_en,
			2, d.template_name.name_ru,
			3, d.template_name.extra_1,
			4, d.template_name.extra_2,
			5, d.template_name.extra_3,
			d.template_name.name_en
		)), d.template_name.name_en),
		d.status_id,
		d.tax_payer_id,
		d.is_tax_payment,
		d.execution_date,
		d.bank_reference,
		-- utility:
		d.is_ut_payment,
		d.abonent_code,
		d.abonent_name,
		d.abonent_surname,
		d.abonent_account,
		d.abonent_legal_id,
		d.ut_corp_cust_code,
		d.ut_corp_cust_branch,
		d.ut_bill_number,
		d.ut_phone_number,
		d.ut_tarif_type,
		d.ut_tarif_price,
		d.ut_tarif_amount,
		d.ut_over_amount,
		d.ut_penalty_type,
		d.ut_penalty_days,
		d.ut_penalty_amount,
		d.booking_date,
		d.ut_date_start,
		d.ut_date_end,
		d.ut_volume_start,
		d.ut_volume_end,
		d.ut_quantity,
		d.from_location,
		d.saving_account_charge_id,
		decode(ro.id, null, '', '(' || ro.id || ') ' || ro.officer_name),
		d.reject_date,
		nvl(ac.iban, ac.mccy_accnum),
		date_payment_next
	into
		userName,
		userId,
		officerName,
		custName,
		custAccount,
		benName,
		benId,
		benRes,
		benCity,
		benStreet,
		benAcnt,
		benType,
		ordName,
		ordId,
		ordRes,
		ordAcnt,
		benBankName,
		benBankBranch,
		benBankSwiftCode,
		benBankOtherCode,
		benBankAddr,
		imBankName,
		imBankAcnt,
		imBankSwiftCode,
		imBankOtherCode,
		imBankAddr,
		paymentDetails,
		itb,
		itc,
		epc,
		itd,
		exchangeRate,
		typeId,
		eCheque,
		eExpiry,
		signTime,
		signDevType,
		signDevId,
		signKey1,
		signKey2,
		signRSA,
		comType,
		templateName,
		statusId,
		taxPayerId,
		isTaxDoc,
		pExecDate,
		pGlobusFt,
		-- utility:
		isUtPayment,
		abonentCode,
		abonentName,
		abonentSurname,
		abonentAccount,
		abonentLegalId,
		utCorpCustCode,
		utCorpCustBranch,
		utBillNumber,
		utPhoneNumber,
		utTarifType,
		utTarifPrice,
		utTarifAmount,
		utOverAmount,
		utPenaltyType,
		utPenaltyDays,
		utPenaltyAmnt,
		utBookingDate,
		utDateStart,
		utDateEnd,
		utVolumeStart,
		utVolumeEnd,
		utQuantity,
		pLocation,
		pSavingAccChargeId,
		pRejector,
		pRejectDate,
		pChargesAccount,
		pSalaryPaymentDate
	from documents d, acsd ao, acsd ab, acsd ac, cusd c, v$users u,
		ways_of_connection w, ways_of_connection wu,
		ibglb.glb_dept_accnt_officer ro,
		(select d.id ppc_id,
			nvl(trim(decode(bocommon.LanguageId,
				0, ppc.name.name_lv,
				1, ppc.name.name_en,
				2, ppc.name.name_ru,
				3, ppc.name.extra_1,
				4, ppc.name.extra_2,
				5, ppc.name.extra_3,
				ppc.name.name_en
			)), ppc.name.name_en) ||
			decode(ppc.id, null, '', ' (' || ppc.id || ')') ppc_name
		from documents d, acsd a, ibglb.glb_payment_purpose_codes ppc
		where d.id = pId and
			a.id = d.from_account and
			ppc.id = d.external_payment_code and
			ppc.location = a.location
		) gppc,
		(select d.id id, o.officer_name name
		from documents d, acsd a, cusd c, ibglb.glb_dept_accnt_officer o
		where d.id = pId and
			a.id = d.from_account and
			c.id = d.from_customer and
			o.id = c.remote_officers.get_id(a.location)
		) remote_officer
	where d.id = pId and d.id = gppc.ppc_id(+) and
		d.id = remote_officer.id(+) and
		ao.id(+) = d.from_account and
		c.id(+) = d.from_customer and
		u.id(+) = d.creator_user_id and
		wu.id(+) = d.creator_woc_id and
		w.id(+) = d.template_user_woc_id and
		ro.id(+) = d.rejector_id and
		d.ben_account_id = ab.id(+) and
		d.charges_account_id = ac.id(+);

	if statusId in (1) then
		begin
			select appl_rec_id, booking_date
			into globus_ft, pBookingDate
			from stmt
			where payment_id = pId and rownum = 1;
			if globus_ft is not null then
				pGlobusFt := globus_ft;
			end if;
		exception when no_data_found then
			null;
		end;
	end if;
end;

end;
/

show err;
