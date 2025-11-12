CREATE OR REPLACE package IB.BOInsurance as

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
	channels in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date,
    fromLocation in varchar2

) return cursor_t;

function find_my return cursor_t;

end;
/

CREATE OR REPLACE package body IB.BOInsurance as

function find_by_id(
	docId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select /* BOInsurance.find_by_id */
		p.id id,
		p.class_id class_id,
		p.status_id status_id,
		p.order_date order_date,
		p.document_number document_number,
		p.creator_channel_id creator_channel_id,
		w.login login,
        w.id woc_id,
        p.from_customer glb_cust_id,
		p.from_location fromLocation,
	(select distinct(e.additional_info) from document_extensions e where p.id = e.document_id and dictionary_id in ('insurance.typeEnum')) typeEnum,
	(select distinct(e.additional_info) from document_extensions e where p.id = e.document_id and dictionary_id in ('insurance.step')) step
	from documents p, ways_of_connection w 
	where p.id = docId 
          and p.class_id in ( 780, 784, 785 )
          and w.id = p.creator_woc_id;
	return rv;
end;

function find_by_filter(
	pCursorName in integer
) return cursor_t is
	cursor_name integer := pCursorName;
	rv cursor_t;
	row insurance_t;
	rows_processed integer;
	rowset insurance_set_t := insurance_set_t();
	id number(14);
	class_id number(3);
	status_id number(2);
	order_date date;
	document_number varchar2(16);
	creator_channel_id number(2);
	login varchar2(60);
    woc_id number(14);
	glb_cust_id number(10);
	fromLocation varchar2(30);
	typeEnum varchar2(30);
	step varchar2(30);


begin
	dbms_sql.define_column(cursor_name, 1, id);
	dbms_sql.define_column(cursor_name, 2, class_id);
	dbms_sql.define_column(cursor_name, 3, status_id);
	dbms_sql.define_column(cursor_name, 4, order_date);
	dbms_sql.define_column(cursor_name, 5, document_number, 16);
	dbms_sql.define_column(cursor_name, 6, creator_channel_id);
	dbms_sql.define_column(cursor_name, 7, login, 60);
	dbms_sql.define_column(cursor_name, 8, woc_id);
        dbms_sql.define_column(cursor_name, 9, glb_cust_id);
        dbms_sql.define_column(cursor_name, 10, fromLocation, 30);
        dbms_sql.define_column(cursor_name, 11, typeEnum, 30);
        dbms_sql.define_column(cursor_name, 12, step, 30);

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name, 1, id);
		dbms_sql.column_value(cursor_name, 2, class_id);
		dbms_sql.column_value(cursor_name, 3, status_id);
		dbms_sql.column_value(cursor_name, 4, order_date);
		dbms_sql.column_value(cursor_name, 5, document_number);
		dbms_sql.column_value(cursor_name, 6, creator_channel_id);
		dbms_sql.column_value(cursor_name, 7, login);
        	dbms_sql.column_value(cursor_name, 8, woc_id);
	        dbms_sql.column_value(cursor_name, 9, glb_cust_id);
		dbms_sql.column_value(cursor_name, 10, fromLocation);
		dbms_sql.column_value(cursor_name, 11, typeEnum);
		dbms_sql.column_value(cursor_name, 12, step);

		row := insurance_t(
			id,
			class_id,
			status_id,
			order_date,
			document_number,
			creator_channel_id,
			login,
			woc_id,
		    	glb_cust_id,
			fromLocation,
			typeEnum,
			step
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as insurance_set_t));
	return rv;

exception when others then
	if dbms_sql.is_open(cursor_name) then
		dbms_sql.close_cursor(cursor_name);
	end if;
	raise;
end;

function find_by_filter(
	-- remitter
	custId in varchar2,
	pCustName in varchar2,
	pUserLogin in varchar2,
	officerId in integer,

	-- document
    docClass in varchar2,

	-- system
	channels in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date,
	fromLocation in varchar2	
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

	rq := rq || 'select /* BOInsurance.find_by_filter */';
	rq := rq || ' p.id id,';
	rq := rq || ' p.class_id class_id,';
	rq := rq || ' p.status_id status_id,';
	rq := rq || ' p.order_date order_date,';
	rq := rq || ' p.document_number document_number,';
	rq := rq || ' p.creator_channel_id creator_channel_id,';
	rq := rq || ' (select login from ways_of_connection where id = p.creator_woc_id) login,';
        rq := rq || ' p.creator_woc_id woc_id,';
        rq := rq || ' p.from_customer glb_cust_id,';
	rq := rq || ' p.from_location fromLocation,';
	rq := rq || ' (select distinct(e.additional_info) from document_extensions e where p.id = e.document_id and dictionary_id in (''insurance.typeEnum'')) typeEnum,';
	rq := rq || ' (select distinct(e.additional_info) from document_extensions e where p.id = e.document_id and dictionary_id in (''insurance.step'')) step';

	rq := rq || ' from documents p';
	rq := rq || ' where rownum <= :ResultSetSize';
	rq := rq || ' and ' || bocommon.order_date_expression(custId, custName, userLogin, remoteId);
    rq := rq || ' and p.class_id in (' || docClass || ')';
	rq := rq || ' and p.creator_channel_id in (' || channels || ')';
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

	return find_by_filter(cursor_name);
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
	channels in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date,
	fromLocation in varchar2
  
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
        docClass,
		channels,
		statuses,
		createdFrom,
		createdTill,
		fromLocation
	);
end;

function find_my return cursor_t is
	rv cursor_t;
	t_dept num_table_type;
	my_locations varchar2_loc_type := bocommon.isDefaultFor;
begin
	bodocuments.get_remote_officers(t_dept);
	open rv for select
		/* BOInsurance.find_my */
		/*+ INDEX (p IDX_DOC_STATUS_CLASS) */
		p.id id,
		p.class_id class_id,
		p.status_id status_id,
		p.order_date order_date,
		p.document_number document_number,
		p.creator_channel_id creator_channel_id,
		(select login from ways_of_connection where id = p.creator_woc_id) login,
        p.creator_woc_id woc_id,
        p.from_customer glb_cust_id,
		p.from_location fromLocation,
	(select distinct(e.additional_info) from document_extensions e where p.id = e.document_id and dictionary_id in ('insurance.typeEnum')) typeEnum,
	(select distinct(e.additional_info) from document_extensions e where p.id = e.document_id and dictionary_id in ('insurance.step')) step
                
	from documents p
	where rownum <= bocommon.ResultSetSize
        and p.class_id in (780, 784, 785)
        and p.status_id in (rba_const.SIGNATURE_OK, rba_const.PRINTED) and (
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
    
end;

/
