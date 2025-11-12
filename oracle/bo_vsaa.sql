/*
 * BackOffice VSAA package.
*/

create or replace package BOVSAA as

type cursor_t is ref cursor;

function find(
	userName in varchar2,
	legalId in varchar2,
	officerId in integer,
	docId in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t;

procedure vsaa(
	pId in varchar2,
	personalId out varchar2,
	signDate out date,
	lastUpdateDate out date,
	itc out varchar2,
	pState out varchar2,
	pStreet out varchar2,
	pEmail out varchar2,
	pPostalCode out varchar2,
	pPhone out varchar2,
	pReceivingType out integer,
	pOfficer out varchar2,
	pLocation out varchar2
);

end;
/

show err;

create or replace package body BOVSAA as

function find_by_id(
	docId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select /* BOVSAA.find_by_id */
		a.order_date created,
		a.status_id status,
		a.id pId,
		a.abonent_name name,
		a.vsaa_plan_id || ' ' || p.name.name_lv vsaaplan,
		da.vsaa_district_id || ' ' || d.name.name_lv vsaadistrict
	from documents a, vsaa_investment_plans p,
		vsaa_district_codes d, document_addresses da
	where a.id = docId and
		a.class_id = 14 and
		a.id = da.document_id(+) and
		a.vsaa_plan_id = p.id(+) and
		da.vsaa_district_id = d.id(+);
	return rv;
end;

function execute_by_filter(
	pCursorName in integer
) return cursor_t is
	cursor_name integer := pCursorName;
	rv cursor_t;
	row vsaa_t;
	rows_processed integer;
	rowset vsaa_set_t := vsaa_set_t();

	created date;
	status number(2);
	pId number(14);
	name varchar2(105);
	vsaaplan varchar2(210);
	vsaadistrict varchar2(210);
begin
	dbms_sql.define_column(cursor_name,  1, created);
	dbms_sql.define_column(cursor_name,  2, status);
	dbms_sql.define_column(cursor_name,  3, pId);
	dbms_sql.define_column(cursor_name,  4, name, 105);
	dbms_sql.define_column(cursor_name,  5, vsaaplan, 210);
	dbms_sql.define_column(cursor_name,  6, vsaadistrict, 210);

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name,  1, created);
		dbms_sql.column_value(cursor_name,  2, status);
		dbms_sql.column_value(cursor_name,  3, pId);
		dbms_sql.column_value(cursor_name,  4, name);
		dbms_sql.column_value(cursor_name,  5, vsaaplan);
		dbms_sql.column_value(cursor_name,  6, vsaadistrict);
		row := vsaa_t(
			created,
			status,
			pId,
			name,
			vsaaplan,
			vsaadistrict
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as vsaa_set_t));
	return rv;

exception when others then
	if dbms_sql.is_open(cursor_name) then
		dbms_sql.close_cursor(cursor_name);
	end if;
	raise;
end;

function find_by_filter(
	userName in varchar2,
	legalId in varchar2,
	officerId in integer,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t is
	rq varchar2(32767);
	cursor_name integer;
	remoteId integer := BODocuments.get_remote_officer(officerId);
begin
	if remoteId > 0 then
		delete from tmp_request_data;
		insert into tmp_request_data (requested_id)
		select distinct c.id from ibglb.cusd c
		where remoteId <= 0 or c.remote_officers.contains(remoteId) = 1;
	end if;

	rq := rq || 'select /* BOVSAA.find_by_filter */';
--	if remoteId > 0 then
--		rq := rq || ' /*+ INDEX (p IDX_DOC_CUST_ID_DATE) */';
--	end if;
	rq := rq || ' a.order_date created,';
	rq := rq || ' a.status_id status,';
	rq := rq || ' a.id pId,';
	rq := rq || ' a.abonent_name name,';
	rq := rq || ' a.vsaa_plan_id || '' '' || p.name.name_lv vsaaplan,';
	rq := rq || ' da.vsaa_district_id || '' '' || d.name.name_lv vsaadistrict';
	rq := rq || ' from documents a, vsaa_investment_plans p,';
	rq := rq || '     vsaa_district_codes d, document_addresses da';
	rq := rq || ' where rownum <= :ResultSetSize';
	rq := rq || ' and a.order_date between :DateFrom and :DateTill';
	rq := rq || ' and a.class_id = 14';
	rq := rq || ' and a.status_id in (' || statuses || ')';
	if legalId is not null then
		rq := rq || ' and upper(a.abonent_legal_id) like :LegalID';
	end if;
	if userName is not null then
		rq := rq || ' and upper(a.abonent_name) like :UserName';
	end if;
	if remoteId > 0 then
		rq := rq || ' and a.from_customer in (select requested_id from tmp_request_data)';
	end if;
	rq := rq || ' and a.id = da.document_id(+)';
	rq := rq || ' and a.vsaa_plan_id = p.id(+)';
	rq := rq || ' and da.vsaa_district_id = d.id(+)';

	cursor_name := dbms_sql.open_cursor;

	dbms_sql.parse(cursor_name, rq, dbms_sql.native);
	dbms_sql.bind_variable(cursor_name, ':ResultSetSize', bocommon.ResultSetSize);
	dbms_sql.bind_variable(cursor_name, ':DateFrom', createdFrom);
	dbms_sql.bind_variable(cursor_name, ':DateTill', createdTill);
	if legalId is not null then
		dbms_sql.bind_variable(cursor_name, ':LegalID', bocommon.prepare_like(legalId));
	end if;
	if userName is not null then
		dbms_sql.bind_variable(cursor_name, ':UserName', bocommon.prepare_like(userName));
	end if;

	return execute_by_filter(cursor_name);
end;

function find(
	userName in varchar2,
	legalId in varchar2,
	officerId in integer,
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
		userName,
		legalId,
		officerId,
		statuses,
		createdFrom,
		createdTill
	);
end;

procedure vsaa(
	pId in varchar2,
	personalId out varchar2,
	signDate out date,
	lastUpdateDate out date,
	itc out varchar2,
	pState out varchar2,
	pStreet out varchar2,
	pEmail out varchar2,
	pPostalCode out varchar2,
	pPhone out varchar2,
	pReceivingType out integer,
	pOfficer out varchar2,
	pLocation out varchar2
) is
begin
	select /* BOVSAA.vsaa */
		a.abonent_legal_id,
		a.signature_date,
		a.last_update_date,
		a.info_to_customer,
		da.addr_country,
		da.addr_street,
		a.email,
		da.addr_zip,
		a.phone_home,
		da.receiving_type,
		o.officer_name,
		a.from_location
	into
		personalId,
		signDate,
		lastUpdateDate,
		itc,
		pState,
		pStreet,
		pEmail,
		pPostalCode,
		pPhone,
		pReceivingType,
		pOfficer,
		pLocation
	from documents a, document_addresses da, ibglb.glb_dept_accnt_officer o, cusd c
	where a.id = pId and
		a.class_id = 14 and
		a.id = da.document_id(+) and
		c.id(+) = a.from_customer and
		o.id(+) = c.remote_officers.company_1;
end;

end;
/

show err;
