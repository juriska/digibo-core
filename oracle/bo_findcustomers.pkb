CREATE OR REPLACE package body IB.BOFindCustomers as

procedure find_by_filter(
	pCustName in varchar2,
	pLegalId in varchar2,
	pLicence in varchar2,
	rowset in out customer_set_t
) is
	custName varchar2(1000) := bocommon.prepare_like(pCustName);
	legalID varchar2(1000) := bocommon.prepare_like(pLegalId);
	licenceID varchar2(1000) := bocommon.prepare_like(pLicence);

	rq varchar2(32767);
	cursor_name integer;
	rows_processed integer;

	useId integer := 0;

	row customer_t;

	id number(10);
	name_en varchar2(200);
	name_lv varchar2(200);
	name_ru varchar2(200);
	name_de varchar2(200);
	name_se varchar2(200);
	name_ee varchar2(200);
	legal_id varchar2(20);
	is_visible number(1);
	location varchar2(2);
begin
	if custName is not null or
		legalID is not null or
		licenceID is not null then
		delete from tmp_request_data;
		useId := 1;
	end if;

	if custName is not null or legalID is not null then
		insert into tmp_request_data (requested_id, filter1)
		select /* BOFindCustomers.find_by_filter.1 */ distinct c.id, '1'
		from ibglb.cusd c
		where (legalID is null or upper(c.legal_id) like legalID) and
			(custName is null or c.name.is_like(custName) = 1);
	end if;

	if licenceID is not null then
		insert into tmp_request_data (requested_id, filter1)
		select /* BOFindCustomers.find_by_filter.2 */ distinct cgr.cusd_id, '2'
		from ways_of_connection w, customer_globus_restrictions cgr
		where w.license_id like licenceID and
			w.channel_id = RBA_CONST.DIGI_FIRMA and
			cgr.woc_id = w.id;
	end if;

	rq := 'select /* BOFindCustomers.find_by_filter */ * from (select distinct';
	rq := rq || ' c.id id,';
	rq := rq || ' c.name.name_en name_en,';
	rq := rq || ' c.name.name_lv name_lv,';
	rq := rq || ' c.name.name_ru name_ru,';
	rq := rq || ' c.name.extra_1 name_de,';
	rq := rq || ' c.name.extra_2 name_se,';
	rq := rq || ' c.name.extra_3 name_ee,';
	rq := rq || ' c.legal_id legal_id,';
	rq := rq || ' c.is_visible is_visible,';
	rq := rq || ' a.location location';
	rq := rq || ' from cusd c, acsd a';
	rq := rq || ' where';
	if useId = 1 then
		useId := 0;
		rq := rq || ' c.id in (';
		if custName is not null or legalID is not null then
			rq := rq || ' select distinct requested_id';
			rq := rq || ' from tmp_request_data';
			rq := rq || ' where filter1 = ''1''';
			useId := 1;
		end if;
		if licenceID is not null then
			if useId = 1 then
				rq := rq || ' intersect';
			end if;
			rq := rq || ' select distinct requested_id';
			rq := rq || ' from tmp_request_data';
			rq := rq || ' where filter1 = ''2''';
			useId := 1;
		end if;
		rq := rq || ' )';
		rq := rq || ' and';
	end if;
	rq := rq || ' a.customer_id = c.id and a.location is not null';
	rq := rq || ' ) where rownum <= :ResultSetSize';

	cursor_name := dbms_sql.open_cursor;
	dbms_sql.parse(cursor_name, rq, dbms_sql.native);
	dbms_sql.bind_variable(cursor_name, ':ResultSetSize', bocommon.ResultSetSize);

	dbms_sql.define_column(cursor_name,  1, id);
	dbms_sql.define_column(cursor_name,  2, name_en, 200);
	dbms_sql.define_column(cursor_name,  3, name_lv, 200);
	dbms_sql.define_column(cursor_name,  4, name_ru, 200);
	dbms_sql.define_column(cursor_name,  5, name_de, 200);
	dbms_sql.define_column(cursor_name,  6, name_se, 200);
	dbms_sql.define_column(cursor_name,  7, name_ee, 200);
	dbms_sql.define_column(cursor_name,  8, legal_id, 20);
	dbms_sql.define_column(cursor_name,  9, is_visible);
	dbms_sql.define_column(cursor_name, 10, location, 2);

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name,  1, id);
		dbms_sql.column_value(cursor_name,  2, name_en);
		dbms_sql.column_value(cursor_name,  3, name_lv);
		dbms_sql.column_value(cursor_name,  4, name_ru);
		dbms_sql.column_value(cursor_name,  5, name_de);
		dbms_sql.column_value(cursor_name,  6, name_se);
		dbms_sql.column_value(cursor_name,  7, name_ee);
		dbms_sql.column_value(cursor_name,  8, legal_id);
		dbms_sql.column_value(cursor_name,  9, is_visible);
		dbms_sql.column_value(cursor_name, 10, location);

		row := customer_t(
			id,
			name_en,
			name_lv,
			name_ru,
			name_de,
			name_se,
			name_ee,
			legal_id,
			is_visible,
			location,
			0,
			0,
			0
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

exception when others then
	if dbms_sql.is_open(cursor_name) then
		dbms_sql.close_cursor(cursor_name);
	end if;
	raise;
end;

procedure find_by_id(
	pCustId in varchar2,
	rowset in out customer_set_t
) is

	cursor c is select /* BOFindCustomers.find_by_id */ * from (select distinct
		c.id id,
		c.name.name_en name_en,
		c.name.name_lv name_lv,
		c.name.name_ru name_ru,
		c.name.extra_1 name_de,
		c.name.extra_2 name_se,
		c.name.extra_3 name_ee,
		c.legal_id legal_id,
		c.is_visible is_visible,
		a.location location
	from cusd c, acsd a
	where c.id = pCustId and
		a.customer_id = c.id and
		a.location is not null
	) where rownum <= bocommon.ResultSetSize;

	r c%rowtype;
	row customer_t;
begin
	for r in c loop
		row := customer_t(
			r.id,
			r.name_en,
			r.name_lv,
			r.name_ru,
			r.name_de,
			r.name_se,
			r.name_ee,
			r.legal_id,
			r.is_visible,
			r.location,
			0,
			0,
			0
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;
end;

function find_customers(
	pCustId in varchar2,
	pCustName in varchar2,
	pLegalId in varchar2,
	pLicence in varchar2
) return cursor_t is
	row customer_t;
	rowset customer_set_t := customer_set_t();
	rv cursor_t;
begin
	if pCustId is not null then
		find_by_id(
			pCustId,
			rowset
		);
	else
		find_by_filter(
			pCustName,
			pLegalId,
			pLicence,
			rowset
		);
	end if;

	if nvl(rowset.count, 0) > 0 then
		for i in rowset.first .. rowset.last loop
			row := rowset(i);
			for r in (
				select /* BOFindCustomers.find_customers */ distinct w.channel_id channel_id
				from v$customer_globus_restrictions cgr,
					ways_of_connection w
				where cgr.cusd_id = row.id and
					w.id = cgr.woc_id and
					w.channel_id in (RBA_CONST.INET, RBA_CONST.SMS, RBA_CONST.DIGI_FIRMA) and
					((w.channel_id = RBA_CONST.SMS and
						w.contract_location = row.location) or
						(
                            exists (
                                select 1
                                from user_document_rights udr
                                where udr.woc_id = w.id	and
                                    udr.customer_id = row.id and
                                    udr.location = row.location
						    )
                            or
                            exists (
                                select 1
                                from v$woc_customers_view wc
                                where wc.customer_id = row.id and
                                    wc.location = row.location
                            )
                            or
                            exists (
                                select 1
                                from v$woc_accounts_viewable wa,
                                    ibglb.acsd a
                                where wa.account_id = a.id and
                                        a.customer_id = cgr.cusd_id and
                                        wa.woc_id = cgr.woc_id and
                                        cgr.cusd_id= row.id and
                                        a.location = row.location
                            )
                        )
					)
			) loop
				case r.channel_id
					when RBA_CONST.INET then rowset(i).inet := 1;
					when RBA_CONST.DIGI_FIRMA then rowset(i).df := 1;
					when RBA_CONST.SMS then rowset(i).sms := 1;
				end case;
			end loop;
		end loop;
	end if;

	open rv for select * from table(cast(rowset as customer_set_t));

	return rv;
end;

procedure load_customer_by_id(
  pId in out number,
	pName out varchar2,
	pIssuerCountry out varchar2,
	pPersonalId out varchar2,
	pPassportNo out varchar2,
	pStreet out varchar2,
	pCity out varchar2,
	pCountry out varchar2,
	pZip out varchar2,
	pPhone out varchar2,
	pMobile out varchar2,
	pFax out varchar2,
	pEmail out varchar2,
	pApart out varchar2,
	pHouse out varchar2,
 	pStdQ out number,
 	pSpecQ out varchar2,
 	pAnswer out varchar2,
	pRegDate out date,
	pChangeDate out date,
	pChangeOfficerId out varchar2,
	pChangeLogin out varchar2,
    pType out varchar2,
    pHasAgreementInGlobus out number
)
is
 vCCount number;
 vRes number;
begin

  select count(*) into vCCount FROM cusd where id = pId;

  if vCCount = 0 then bo_repl_link.replicate_customer(pId, vRes);
  end if;

	select    count(1)
	into       pHasAgreementInGlobus
	from     glb_rb_contract
	where   user_id = pId;

  select
		c.NAME.name_en,
		c.COUNTRY,
		c.LEGAL_ID,
		c.LEGAL_ID,
		c.ADDR_STR.NAME_EN,
		c.TOWN_COUNTRY.NAME_EN,
		c.ADDRESS_COUNTRY,
		c.zip_code,
		NULL phone,
		NULL mobile_phone,
		NULL fax,
		NULL email,
		NULL apart,
		NULL house,

		NULL,
		NULL,
		NULL,

		NULL reg_date,
		NULL change_date,
		NULL change_officer_id,
        NULL login,
        type
	into
		pName,
		pIssuerCountry,
		pPersonalId,
		pPassportNo,
		pStreet,
		pCity,
		pCountry,
		pZip,
		pPhone,
		pMobile,
		pFax,
		pEmail,
		pApart,
		pHouse,

		pStdQ,
		pSpecQ,
		pAnswer,

		pRegDate,
		pChangeDate,
		pChangeOfficerId,
		pChangeLogin,
        pType

	from
		cusd c
	where
    c.id = pId;

	exception when no_data_found then
		pId := null;

end;

end;
/
