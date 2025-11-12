/*
* Client questionnaire.
*/

create or replace package BOCQ as

type cursor_t is ref cursor;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,
	userLogin in varchar2,
	officerId in integer,

	-- document
	docClass in varchar2,

	-- system
	docId in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t;

function find_my(docClass in varchar2) return cursor_t;

procedure cq(
	pId in varchar2,
	--
	docNo out varchar2,
	userName out varchar2,
	userId out varchar2,
	officerName out varchar2,
	custName out varchar2,
	custAccount out varchar2,
	globusNo out varchar2,
	--
	itc out varchar2,
	itb out varchar2,
	-- additional properties.
	authName out varchar2,
	authSurname out varchar2,
	authLegalId out varchar2,
	authPassportNo out varchar2,
	authPassportCountry out varchar2,
	authPassportInst out varchar2,
	authPhone out varchar2,
	authFax out varchar2,
	authEmail out varchar2,
	contactPersonName out varchar2,
	contactPersonSurname out varchar2,
	contactPersonPhone out varchar2,
	contactPersonEmail out varchar2,
	econimicActivity out varchar2,
	recipients out varchar2,
	suppliers out varchar2,
	incomingPayments out varchar2,
	outgoingPayments out varchar2,
	financeClients out varchar2,
	pLocation out varchar2,
	--
	signTime out date,
	signDevType out integer,
	signDevId out varchar2,
	signKey1 out varchar2,
	signKey2 out varchar2
);

function get_extensions(pId in varchar2) return cursor_t;

end;
/

show err;

create or replace package body BOCQ as

function find_by_id(
	docId in varchar2,
	docClass in varchar2
) return cursor_t is
	rv cursor_t;
	t_classes num_table_type := bocommon.str2table(docClass);
begin
	open rv for select
		/* BOCQ.find_by_id */
		p.id pId,
		p.class_id class,
		p.status_id status,
		p.order_date created,
		p.document_number docNumber,
		p.creator_channel_id channel,
		w.login login
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
	row cq_t;
	rows_processed integer;
	rowset cq_set_t := cq_set_t();
	pId number(14);
	class number(3);
	status number(2);
	created date;
	docNumber varchar2(16);
	channel number(2);
	login varchar2(60);
begin
	dbms_sql.define_column(cursor_name,  1, pId);
	dbms_sql.define_column(cursor_name,  2, class);
	dbms_sql.define_column(cursor_name,  3, status);
	dbms_sql.define_column(cursor_name,  4, created);
	dbms_sql.define_column(cursor_name,  5, docNumber, 16);
	dbms_sql.define_column(cursor_name,  6, channel);
	dbms_sql.define_column(cursor_name,  7, login, 60);

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name,  1, pId);
		dbms_sql.column_value(cursor_name,  2, class);
		dbms_sql.column_value(cursor_name,  3, status);
		dbms_sql.column_value(cursor_name,  4, created);
		dbms_sql.column_value(cursor_name,  5, docNumber);
		dbms_sql.column_value(cursor_name,  6, channel);
		dbms_sql.column_value(cursor_name,  7, login);
		row := cq_t(
			pId,
			class,
			status,
			created,
			docNumber,
			channel,
			login
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as cq_set_t));
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

	rq := rq || 'select /* BOCQ.find_by_filter */';
--	if custId is not null or custName is not null or remoteId > 0 then
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
	rq := rq || ' (select login from ways_of_connection where id = p.creator_woc_id) login';
	rq := rq || ' from documents p';
	rq := rq || ' where rownum <= :ResultSetSize';
	rq := rq || ' and ' || bocommon.order_date_expression(custId, custName, userLogin, remoteId);
	rq := rq || ' and p.class_id in (' || docClass || ')';
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
	docClass in varchar2,

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
		officerId,
		docClass,
		statuses,
		createdFrom,
		createdTill
	);
end;

function find_my(docClass in varchar2) return cursor_t is
	rv cursor_t;
	t_classes num_table_type := bocommon.str2table(docClass);
	t_dept num_table_type;
	my_locations varchar2_loc_type := bocommon.isDefaultFor;
begin
	bodocuments.get_remote_officers(t_dept);
	open rv for select
		/* BOCQ.find_my */
		/*+ INDEX (p IDX_DOC_STATUS_CLASS) */
		p.id pId,
		p.class_id class,
		p.status_id status,
		p.order_date created,
		p.document_number docNumber,
		p.creator_channel_id channel,
		(select login from ways_of_connection where id = p.creator_woc_id) login
	from documents p
	where rownum <= bocommon.ResultSetSize
		and p.status_id = rba_const.SIGNATURE_OK
		and p.class_id in (select * from table(cast(t_classes as num_table_type)))
		and (
		(exists (select c.id from cusd c where c.id = p.from_customer and (
			c.remote_officers.get_id(p.from_location) in
				(select * from table(cast(t_dept as num_table_type)))
		))) or (p.from_location in (select * from table(cast(my_locations as varchar2_loc_type))) and
			(not exists (select c.id
			from cusd c, officers o
			where c.id = p.from_customer and
				o.DEPT_ACCNT_OFFICER_ID =
					c.remote_officers.get_id(p.from_location))))
		);
	return rv;
end;

procedure cq(
	pId in varchar2,
	--
	docNo out varchar2,
	userName out varchar2,
	userId out varchar2,
	officerName out varchar2,
	custName out varchar2,
	custAccount out varchar2,
	globusNo out varchar2,
	--
	itc out varchar2,
	itb out varchar2,
	-- additional properties.
	authName out varchar2,
	authSurname out varchar2,
	authLegalId out varchar2,
	authPassportNo out varchar2,
	authPassportCountry out varchar2,
	authPassportInst out varchar2,
	authPhone out varchar2,
	authFax out varchar2,
	authEmail out varchar2,
	contactPersonName out varchar2,
	contactPersonSurname out varchar2,
	contactPersonPhone out varchar2,
	contactPersonEmail out varchar2,
	econimicActivity out varchar2,
	recipients out varchar2,
	suppliers out varchar2,
	incomingPayments out varchar2,
	outgoingPayments out varchar2,
	financeClients out varchar2,
	pLocation out varchar2,
	--
	signTime out date,
	signDevType out integer,
	signDevId out varchar2,
	signKey1 out varchar2,
	signKey2 out varchar2
) is
begin
	select /* BOCQ.cq */
		d.document_number,
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
		d.authorized_name,
		d.authorized_surname,
		d.authorized_legal_id,
		d.authorized_passport_number,
		d.authorized_passport_country,
		d.authorized_passport_inst,
		d.authorized_phone,
		d.authorized_fax,
		d.authorized_email,
		d.abonent_name,
		d.abonent_surname,
		d.phone_home,
		d.email,
		d.ff_text,
		d.goods_recipient_countries,
		d.goods_suppliers_countries,
		d.incoming_payment_countries,
		d.outgoing_payment_countries,
		d.finance_clients_countries,
		d.from_location,
		d.signature_date,
		d.signature_cdevice_type_id,
		d.signature_cdevice_serial,
		d.signature_key_1,
		d.signature_key_2
	into
		docNo,
		globusNo,
		userName,
		userId,
		officerName,
		custName,
		custAccount,
		itc,
		itb,
		authName,
		authSurname,
		authLegalId,
		authPassportNo,
		authPassportCountry,
		authPassportInst,
		authPhone,
		authFax,
		authEmail,
		contactPersonName,
		contactPersonSurname,
		contactPersonPhone,
		contactPersonEmail,
		econimicActivity,
		recipients,
		suppliers,
		incomingPayments,
		outgoingPayments,
		financeClients,
		pLocation,
		signTime,
		signDevType,
		signDevId,
		signKey1,
		signKey2
	from documents d, v$users u, acsd a, cusd c, ways_of_connection w,
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
		w.id(+) = d.creator_woc_id;
end;

function get_extensions(pId in varchar2) return cursor_t is
	rv cursor_t;
begin
	open rv for select /* BOCQ.get_extensions */
		dictionary_id || '-' || block_number block_id,
		additional_info info,
		block_number,
		(select max(block_number)
			from document_extensions de
			where de.document_id = pId and
				de.dictionary_id = d.dictionary_id
		) total_blocks
	from dictionary dict, document_extensions d
	where dict.id = dictionary_id and document_id = pId;
	return rv;
end;

end;
/

show err;
