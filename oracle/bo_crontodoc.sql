/*
* Cronto Documents
*/

create or replace package BOCRONTODOC as

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

function set_processing(pId in varchar2) return integer;

function find_my(pOfficerId in integer) return cursor_t;

end;
/

show err;

create or replace package body BOCRONTODOC as

function find_by_id(
	docId in varchar2,
	pType in varchar2
) return cursor_t is
	rv cursor_t;
	t_classes num_table_type := bocommon.str2table(pType);
begin
	open rv for select
		/* BOSTO.find_by_id */
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
		p.debit_ccy db_ccy,
		p.change_officer_id processedBy
	from documents p, ways_of_connection w
	where p.id = docId and
		--p.class_id in (select * from table(cast(t_classes as num_table_type))) and
        p.class_id in ( 514,516,723,724,725,735,736,739,740,744,746,1027,1028) and
		w.id = p.creator_woc_id;
	return rv;
end;

function execute_by_filter(
	pCursorName in integer
) return cursor_t is
	cursor_name integer := pCursorName;
	rv cursor_t;
	row cronto_t;
	rows_processed integer;
	rowset cronto_set_t := cronto_set_t();
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
	processedBy number(10);
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
	dbms_sql.define_column(cursor_name,  12, processedBy);

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
		dbms_sql.column_value(cursor_name,  12, processedBy);
		row := cronto_t(
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
			db_ccy,
			processedBy
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as cronto_set_t));
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

	rq := rq || 'select /* BOCRONTODOC.find_by_filter */';
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
	rq := rq || ' p.debit_ccy db_ccy,';
	rq := rq || ' p.change_officer_id processedBy';
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

function set_processing(pId in varchar2) return integer is
	vRes int;
begin
	vRes := 0;
	
	update documents
	set change_officer_id = bocommon.officerId
	where id = pId returning change_officer_id into vRes;

	if vRes > 0 then
		bodocuments.set_manual_status(pId, null, RBA_CONST.MANUAL_PROCESSING_STARTED, 24403);
	else
		vRes := 0;
	end if;

	return vRes;
end;

function find_my(pOfficerId in integer) return cursor_t is
	rv cursor_t;
begin
	-- Acts as "find_new" when pOfficerId is not supplied
	open rv for select
		/* BOSTO.find_by_id */
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
		p.debit_ccy db_ccy,
		p.change_officer_id processedBy
	from documents p, ways_of_connection w
	where rownum <= bocommon.ResultSetSize and
		p.class_id in (1028) and (
			(pOfficerId = 0 and p.change_officer_id is null and p.status_id = RBA_CONST.PARTLY_SUCCEED)
			or
			(p.change_officer_id = pOfficerId and p.status_id = RBA_CONST.MANUAL_PROCESSING_STARTED)
		) and
		w.id = p.creator_woc_id       
        ;
	return rv;
end;



end;
/

show err;
