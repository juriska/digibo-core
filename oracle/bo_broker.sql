/*
* Secure orders.
*/

create or replace package BOBroker as

type cursor_t is ref cursor;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,
	userLogin in varchar2,
	userPassword in varchar2,

	-- document
	docClass in varchar2,
	operationType in varchar2,
	docCount in integer,
	currencies in varchar2,
	expiryFrom in date,
	expiryTill in date,

	-- system
	docId in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t;

function find_my(docClass in varchar2) return cursor_t;

procedure broker(
	pId in varchar2,
	docNo out varchar2,
	userName out varchar2,
	userId out varchar2,
	officerName out varchar2,
	custName out varchar2,
	custAccount out varchar2,
	globusNo out varchar2,
	portfolioId out varchar2,
	operation out varchar2,
	isinCode out varchar2,
	fundName out varchar2,
	investVolume out varchar2,
	identCode out varchar2,
	stockSymbol out varchar2,
	optionSymbol out varchar2,
	emitentName out varchar2,
	exchangeName out varchar2,
	optionType out varchar2,
	optionPremium out varchar2,
	maturityDate out date,
	couponRate out varchar2,
	currency out varchar2,
	orderType out varchar2,
	price out varchar2,
	stopPrice out varchar2,
	trailAmount out varchar2,
	goodTill out varchar2,
	pText out varchar2,
	pLocation out varchar2,
	--
	itc out varchar2,
	itb out varchar2
);

end;
/

show err;

create or replace package body BOBroker as

function find_by_id(
	docId in varchar2,
	docClass in varchar2
) return cursor_t is
	rv cursor_t;
	t_classes num_table_type := bocommon.str2table(docClass);
begin
	open rv for select
		/* BOBroker.find_by_id */
		p.id pId,
		p.class_id class,
		p.status_id status,
		p.order_date created,
		p.document_number docNumber,
		p.creator_channel_id channel,
		w.login login,
		p.isin_code isinCode,
		p.operation_type operation
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
	row broker_t;
	rows_processed integer;
	rowset broker_set_t := broker_set_t();
	pId number(14);
	class number(3);
	status number(2);
	created date;
	docNumber varchar2(16);
	channel number(2);
	login varchar2(60);
	isinCode varchar2(12);
	operation varchar2(10);
begin
	dbms_sql.define_column(cursor_name, 1, pId);
	dbms_sql.define_column(cursor_name, 2, class);
	dbms_sql.define_column(cursor_name, 3, status);
	dbms_sql.define_column(cursor_name, 4, created);
	dbms_sql.define_column(cursor_name, 5, docNumber, 16);
	dbms_sql.define_column(cursor_name, 6, channel);
	dbms_sql.define_column(cursor_name, 7, login, 60);
	dbms_sql.define_column(cursor_name, 8, isinCode, 12);
	dbms_sql.define_column(cursor_name, 9, operation, 10);

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name, 1, pId);
		dbms_sql.column_value(cursor_name, 2, class);
		dbms_sql.column_value(cursor_name, 3, status);
		dbms_sql.column_value(cursor_name, 4, created);
		dbms_sql.column_value(cursor_name, 5, docNumber);
		dbms_sql.column_value(cursor_name, 6, channel);
		dbms_sql.column_value(cursor_name, 7, login);
		dbms_sql.column_value(cursor_name, 8, isinCode);
		dbms_sql.column_value(cursor_name, 9, operation);
		row := broker_t(
			pId,
			class,
			status,
			created,
			docNumber,
			channel,
			login,
			isinCode,
			operation
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as broker_set_t));
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
	userPassword in varchar2,
	docClass in varchar2,
	operationType in varchar2,
	docCount in integer,
	currencies in varchar2,
	expiryFrom in date,
	expiryTill in date,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t is
	rq varchar2(32767);
	cursor_name integer;
	custName varchar2(1024) := bocommon.prepare_like(pCustName);
	userLogin varchar2(1024) := bocommon.prepare_like(pUserLogin);
begin
	if custName is not null then
		delete from tmp_request_data;
		insert into tmp_request_data (requested_id)
		select distinct c.id from ibglb.cusd c
		where (custName is null or c.name.is_like(custName) = 1);
	end if;

	rq := rq || 'select /* BOBroker.find_by_filter */';
--	if custId is not null or custName is not null then
--		rq := rq || ' /*+ INDEX (p IDX_DOC_CUST_ID_DATE) */';
--	elsif userLogin is not null then
--		rq := rq || ' /*+ INDEX (p IDX_DOC_WOC_ID_DATE) */';
--	end if;
	rq := rq || ' p.id pId,';
	rq := rq || ' p.class_id class,';
	rq := rq || ' p.status_id status,';
	rq := rq || ' p.order_date created,';
	rq := rq || ' p.document_number docNumber,';
	rq := rq || ' p.creator_channel_id channel,';
	rq := rq || ' (select login from ways_of_connection where id = p.creator_woc_id) login,';
	rq := rq || ' p.isin_code isinCode,';
	rq := rq || ' p.operation_type operation';
	rq := rq || ' from documents p';
	rq := rq || ' where rownum <= :ResultSetSize ';
	rq := rq || ' and ' || bocommon.order_date_expression(custId, custName, userLogin, -1);
	rq := rq || ' and p.class_id in (' || docClass || ')';
	rq := rq || ' and p.status_id in (' || statuses || ')';
	if operationType is not null then
		rq := rq || ' and p.operation_type = :OperationType';
	end if;
	if docCount != 0 then
		rq := rq || ' and p.invest_volume = :DocCount';
	end if;
	if currencies is not null then
		rq := rq || ' and p.credit_ccy = :CCY';
	end if;
	if expiryFrom is not null and expiryTill is not null then
		rq := rq || ' and ((p.invest_expiry_type = ''DAY''';
		rq := rq || ' and p.order_date between :ExpiryFrom and :ExpiryTill)';
		rq := rq || ' or (p.invest_expiry_type = ''GTD''';
		rq := rq || ' and p.invest_expiry_date between :ExpiryFrom and :ExpiryTill))';
	end if;
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
	if custName is not null then
		rq := rq || ' and p.from_customer in (select requested_id from tmp_request_data)';
	end if;
	if userPassword is not null then
		rq := rq || ' and exists (select a.id from acsd a';
		rq := rq || ' where a.customer_id = p.from_customer and';
		rq := rq || ' upper(:UserPassword) = upper(a.ident_code))';
	end if;

	cursor_name := dbms_sql.open_cursor;

	dbms_sql.parse(cursor_name, rq, dbms_sql.native);
	dbms_sql.bind_variable(cursor_name, ':ResultSetSize', bocommon.ResultSetSize);
	dbms_sql.bind_variable(cursor_name, ':DateFrom', createdFrom);
	dbms_sql.bind_variable(cursor_name, ':DateTill', createdTill);
	if operationType is not null then
		dbms_sql.bind_variable(cursor_name, ':OperationType', operationType);
	end if;
	if docCount != 0 then
		dbms_sql.bind_variable(cursor_name, ':DocCount', docCount);
	end if;
	if currencies is not null then
		dbms_sql.bind_variable(cursor_name, ':CCY', currencies);
	end if;
	if expiryFrom is not null and expiryTill is not null then
		dbms_sql.bind_variable(cursor_name, ':ExpiryFrom', expiryFrom);
		dbms_sql.bind_variable(cursor_name, ':ExpiryTill', expiryTill);
	end if;
	if custId is not null then
		dbms_sql.bind_variable(cursor_name, ':CustomerId', custId);
	end if;
	if userLogin is not null then
		dbms_sql.bind_variable(cursor_name, ':UserLogin', userLogin);
	end if;
	if userPassword is not null then
		dbms_sql.bind_variable(cursor_name, ':UserPassword', userPassword);
	end if;

	return execute_by_filter(cursor_name);
end;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,
	userLogin in varchar2,
	userPassword in varchar2,

	-- document
	docClass in varchar2,
	operationType in varchar2,
	docCount in integer,
	currencies in varchar2,
	expiryFrom in date,
	expiryTill in date,

	-- system
	docId in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t is
begin
	if docId is not null then
		return find_by_id(docId, docClass);
	end if;
	return find_by_filter(
		custId,
		custName,
		userLogin,
		userPassword,
		docClass,
		operationType,
		docCount,
		currencies,
		expiryFrom,
		expiryTill,
		statuses,
		createdFrom,
		createdTill
	);
end;

function find_my(docClass in varchar2) return cursor_t is
	rv cursor_t;
	t_classes num_table_type := bocommon.str2table(docClass);
begin
	open rv for select
		/* BOBroker.find_my */
		/*+ INDEX (p IDX_DOC_STATUS_CLASS) */
		p.id pId,
		p.class_id class,
		p.status_id status,
		p.order_date created,
		p.document_number docNumber,
		p.creator_channel_id channel,
		(select login from ways_of_connection where id = p.creator_woc_id) login,
		p.isin_code isinCode,
		p.operation_type operation
	from documents p
	where rownum <= bocommon.ResultSetSize and
		p.status_id = 13 and
		p.class_id in (select * from table(cast(t_classes as num_table_type)));
	return rv;
end;

procedure broker(
	pId in varchar2,
	docNo out varchar2,
	userName out varchar2,
	userId out varchar2,
	officerName out varchar2,
	custName out varchar2,
	custAccount out varchar2,
	globusNo out varchar2,
	portfolioId out varchar2,
	operation out varchar2,
	isinCode out varchar2,
	fundName out varchar2,
	investVolume out varchar2,
	identCode out varchar2,
	stockSymbol out varchar2,
	optionSymbol out varchar2,
	emitentName out varchar2,
	exchangeName out varchar2,
	optionType out varchar2,
	optionPremium out varchar2,
	maturityDate out date,
	couponRate out varchar2,
	currency out varchar2,
	orderType out varchar2,
	price out varchar2,
	stopPrice out varchar2,
	trailAmount out varchar2,
	goodTill out varchar2,
	pText out varchar2,
	pLocation out varchar2,
	--
	itc out varchar2,
	itb out varchar2
) is
	order_class_id integer := 0;
begin
	select /* BOBroker.broker */
		d.document_number,
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
		a.portfolio_id,
		d.operation_type,
		d.isin_code,
		nvl(trim(decode(bocommon.LanguageId,
			0, invf.name.name_lv,
			1, invf.name.name_en,
			2, invf.name.name_ru,
			3, invf.name.extra_1,
			4, invf.name.extra_2,
			5, invf.name.extra_3,
			invf.name.name_en
		)), invf.name.name_en),
		d.invest_volume,
		d.info_to_customer,
		d.info_to_bank,
		a.ident_code,
		d.stock_symbol,
		d.option_symbol,
		d.emitent_name,
		nvl(trim(decode(bocommon.LanguageId,
			0, se.name.name_lv,
			1, se.name.name_en,
			2, se.name.name_ru,
			3, se.name.extra_1,
			4, se.name.extra_2,
			5, se.name.extra_3,
			se.name.name_en
		)), se.name.name_en),
		d.option_type,
		d.option_premium,
		d.paper_expiry_date,
		d.bond_rate,
		d.credit_ccy,
		d.invest_order_type,
		d.invest_price,
		d.invest_stop_price,
		d.invest_trail_amount,
		d.invest_expiry_type || ' ' || to_char(d.invest_expiry_date, 'yyyy-mm-dd'),
		d.ff_text,
		d.from_location
	into
		docNo,
		order_class_id,
		globusNo,
		userName,
		userId,
		officerName,
		custName,
		custAccount,
		portfolioId,
		operation,
		isinCode,
		fundName,
		investVolume,
		itc,
		itb,
		identCode,
		stockSymbol,
		optionSymbol,
		emitentName,
		exchangeName,
		optionType,
		optionPremium,
		maturityDate,
		couponRate,
		currency,
		orderType,
		price,
		stopPrice,
		trailAmount,
		goodTill,
		pText,
		pLocation
	from documents d, v$users u, acsd a, cusd c, ways_of_connection w,
		invest_funds invf, stock_exchanges se,
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
		d.isin_code = invf.id(+) and
		d.stock_exchange_id = se.id(+);
end;

end;
/

show err;
