/*
* FI Account open orders.
*/

create or replace package BOFiaccopen as

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
	createdFrom in date,
	createdTill in date
) return cursor_t;

function find_my(pOfficerId in integer) return cursor_t;
/*
procedure custody(
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
*/
function set_processing(pId in varchar2, pStatusIdFrom in integer, pStatusIdTo in integer) return integer;

end;
/

show err;

create or replace package body BOFiaccopen as

function find_by_id(
	docId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		/* BOMCustody.find_by_id */
		p.id pId,
		p.status_id status,
		p.order_date created,
		p.document_number docNumber,
		w.login login,
		w.id wocId,
		p.change_officer_id processedBy,
		p.info_to_customer itc,
		p.class_id class_id
	from documents p, ways_of_connection w
	where p.id = docId
		and p.class_id in ( 321, 322)
		and w.id = p.creator_woc_id;
	return rv;
end;

function execute_by_filter(
	pCursorName in integer
) return cursor_t is
	cursor_name integer := pCursorName;
	rv cursor_t;
	row fiaccopen_t;
	rows_processed integer;
	rowset fiaccopen_set_t := fiaccopen_set_t();
	pId number(14);
	status number(2);
	created date;
	docNumber varchar2(16);
	login varchar2(60);
	wocId number(10);
	processedBy number(10);
	itc varchar2(4000);
	class_id number(10);
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
		row := fiaccopen_t(
			pId,
			status,
			created,
			docNumber,
			login,
			wocId,
			processedBy,
			itc,
			class_id
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as fiaccopen_set_t));
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

	rq := rq || 'select /* BOCustody.find_by_filter */';
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
	rq := rq || ' w.login login,';
	rq := rq || ' w.id wocId,';
	rq := rq || ' p.change_officer_id processedBy,';
	rq := rq || ' p.info_to_customer itc';
	rq := rq || ' , p.class_id class_id';
	rq := rq || ' from documents p, ways_of_connection w';
	rq := rq || ' where rownum <= :ResultSetSize';
	rq := rq || ' and ' || bocommon.order_date_expression(custId, custName, userLogin, -1);
	--rq := rq || ' and p.class_id in ( 318, 319, 320)';
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
	if custName is not null then
		rq := rq || ' and p.from_customer in (select requested_id from tmp_request_data)';
	end if;
	rq := rq || ' and w.id = p.creator_woc_id';

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
	-- system
	docId in varchar2,
	statuses in varchar2,
	docClass in varchar2,
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
		statuses,
		docClass,
		createdFrom,
		createdTill
	);
end;

function find_my(pOfficerId in integer) return cursor_t is
	rv cursor_t;
begin
	-- Acts as "find_new" when pOfficerId is not supplied
    
    if dbms_session.is_role_enabled('RBOCUSTODYEDIT') and not dbms_session.is_role_enabled('RBO_FI_BO_EDIT') then
        open rv for select
            /* BOCustody.find_my */
            /*+ INDEX (p IDX_DOC_STATUS_CLASS) */
            /*+ INDEX (w PK_WAYS_OF_CONNECTION) */
            p.id pId,
            p.status_id status,
            p.order_date created,
            p.document_number docNumber,
            w.login login,
            w.id wocId,
            p.change_officer_id processedBy,
            p.info_to_customer itc,
            p.class_id class_id
        from documents p, ways_of_connection w
        where rownum <= bocommon.ResultSetSize and
            p.class_id in ( 321, 322) and (
                --(pOfficerId = 0 and p.change_officer_id is null and p.status_id in ( RBA_CONST.SIGNATURE_OK, RBA_CONST.CONFIRM_OK)) -- 5, 13
                (pOfficerId = 0 and p.status_id in ( RBA_CONST.SIGNATURE_OK, RBA_CONST.CONFIRM_OK)) -- 5, 13
                or
                (p.change_officer_id = pOfficerId and p.status_id = RBA_CONST.MANUAL_PROCESSING_STARTED)
            ) and
            w.id = p.creator_woc_id;
    end if;
    
    if dbms_session.is_role_enabled('RBO_FI_BO_EDIT') and not dbms_session.is_role_enabled('RBOCUSTODYEDIT') then
        open rv for select
            /* BOCustody.find_my */
            /*+ INDEX (p IDX_DOC_STATUS_CLASS) */
            /*+ INDEX (w PK_WAYS_OF_CONNECTION) */
            p.id pId,
            p.status_id status,
            p.order_date created,
            p.document_number docNumber,
            w.login login,
            w.id wocId,
            p.change_officer_id processedBy,
            p.info_to_customer itc,
            p.class_id class_id
        from documents p, ways_of_connection w
        where rownum <= bocommon.ResultSetSize and
            p.class_id in ( 321, 322) and (
                --(pOfficerId = 0 and p.change_officer_id is null and p.status_id in ( RBA_CONST.WAITING_FOR_APPROVAL)) 
                (pOfficerId = 0 and p.status_id in ( RBA_CONST.WAITING_FOR_APPROVAL)) 
                or
                (p.change_officer_id = pOfficerId and p.status_id = RBA_CONST.PROCESSING_APPROVAL)
                or
                (pOfficerId = 0 and p.change_officer_id != bocommon.get_logged_officer and p.status_id = RBA_CONST.WAITING_FOR_AUTH)
            ) and
            w.id = p.creator_woc_id;
    end if;    

    if dbms_session.is_role_enabled('RBOCUSTODYEDIT') and dbms_session.is_role_enabled('RBO_FI_BO_EDIT') then
        open rv for select
            /* BOCustody.find_my */
            /*+ INDEX (p IDX_DOC_STATUS_CLASS) */
            /*+ INDEX (w PK_WAYS_OF_CONNECTION) */
            p.id pId,
            p.status_id status,
            p.order_date created,
            p.document_number docNumber,
            w.login login,
            w.id wocId,
            p.change_officer_id processedBy,
            p.info_to_customer itc,
            p.class_id class_id
        from documents p, ways_of_connection w
        where rownum <= bocommon.ResultSetSize and
            p.class_id in ( 321, 322) and (
                (pOfficerId = 0 and p.status_id in ( RBA_CONST.SIGNATURE_OK, RBA_CONST.CONFIRM_OK)) -- 5, 13
                or
                (p.change_officer_id = pOfficerId and p.status_id = RBA_CONST.MANUAL_PROCESSING_STARTED)
                or
                (pOfficerId = 0 and p.status_id in ( RBA_CONST.WAITING_FOR_APPROVAL))
                or
                (p.change_officer_id = pOfficerId and p.status_id = RBA_CONST.PROCESSING_APPROVAL)
                 or
                (p.change_officer_id != pOfficerId and p.change_officer_id != bocommon.get_logged_officer and p.status_id = RBA_CONST.WAITING_FOR_AUTH)
            ) and
            w.id = p.creator_woc_id;
    end if;
    
	return rv;
end;

function set_processing(pId in varchar2, pStatusIdFrom in integer, pStatusIdTo in integer) return integer is
	vRes int;
begin
	vRes := 0;
    
     update documents
        set change_officer_id = bocommon.officerId
        where id = pId
            and status_id = pStatusIdFrom
        returning change_officer_id into vRes;
        
        if vRes > 0 then
            bodocuments.set_manual_status(pId, null, pStatusIdTo, 24403);
        else
            vRes := 0;
        end if;
    
	/*
    if dbms_session.is_role_enabled('RBOCUSTODYEDIT') then
        update documents
        set change_officer_id = bocommon.officerId
        where id = pId
            and status_id in (RBA_CONST.SIGNATURE_OK, RBA_CONST.CONFIRM_OK, RBA_CONST.MANUAL_PROCESSING_STARTED)
        returning change_officer_id into vRes;
        
        if vRes > 0 then
            bodocuments.set_manual_status(pId, null, RBA_CONST.MANUAL_PROCESSING_STARTED, 24403);
        else
            vRes := 0;
        end if;
    end if;

    if dbms_session.is_role_enabled('RBO_FI_BO_EDIT') then
        update documents
        set change_officer_id = bocommon.officerId
        where id = pId
            and status_id in (RBA_CONST.WAITING_FOR_APPROVAL, RBA_CONST.PROCESSING_APPROVAL)
        returning change_officer_id into vRes;
        
        if vRes > 0 then
            bodocuments.set_manual_status(pId, null, RBA_CONST.PROCESSING_APPROVAL, 24403);
        else
            vRes := 0;
        end if;
    end if;
*/
	return vRes;
end;

end;
/

show err;
