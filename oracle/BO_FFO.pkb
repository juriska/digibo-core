CREATE OR REPLACE package body IB.BOFFO as

function find_by_id(
	docId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select /* BOFFO.find_by_id */
		p.id id,
		p.class_id class_id,
		p.status_id status_id,
		p.order_date order_date,
		p.document_number document_number,
		p.creator_channel_id creator_channel_id,
		w.login login,
		p.ff_subject ff_subject
        , w.id woc_id
        , p.from_customer glb_cust_id,
        (select c.sector from cusd c where c.id = p.from_customer)sector,
        (select c.segment from cusd c where c.id = p.from_customer)segment,
        (select count(*) from document_attachments where document_id = docId and type in (2,5,6,7,8,9,10,13,14,15,16)) isDocumentAttached,
        p.ffo_category_id category_id,
        p.ffo_subcategory_id subcategory_id,
        (select nvl(trim(decode(bocommon.LanguageId,
			0, c.name.name_lv,
			1, c.name.name_en,
			2, c.name.name_ru,
			3, c.name.extra_1,
			4, c.name.extra_2,
			5, c.name.extra_3,
			c.name.name_en
		)), c.name.name_en) from ffo_categories c where c.id = p.ffo_category_id) category_name,
  	  (select nvl(trim(decode(bocommon.LanguageId,
			0, c.name.name_lv,
			1, c.name.name_en,
			2, c.name.name_ru,
			3, c.name.extra_1,
			4, c.name.extra_2,
			5, c.name.extra_3,
			c.name.name_en
		)), c.name.name_en) from ffo_categories c where c.id = p.ffo_subcategory_id) subcategory_name,
        p.ffo_assignee assignee,
	(select max(nvl(is_type_visible, 0)) from document_attachments da where da.document_id = p.id) document_attached
	from documents p, ways_of_connection w
	where p.id = docId
          and p.class_id in (  rba_const.FREE_FORMAT, 524, 527, 731, 732, 734, 755, 764, 769, 770, 771, 781, 782, 783, 794, 798, 729,1200)
          and w.id = p.creator_woc_id;
	return rv;
end;

function find_by_filter(
	pCursorName in integer
) return cursor_t is
	cursor_name integer := pCursorName;
	rv cursor_t;
	row ffo_t;
	rows_processed integer;
	rowset ffo_set_t := ffo_set_t();
	id number(14);
	class_id number(4);
	status_id number(2);
	order_date date;
	document_number varchar2(16);
	creator_channel_id number(2);
	login varchar2(60);
	ff_subject varchar2(105);
  woc_id number(14);
	glb_cust_id number(10);
  sector number(5);
  segment varchar2(32);
  isDocumentAttached number(2);
  category_id number(9);
  subcategory_id number(9);
  category_name varchar2(50);
  subcategory_name varchar2(50);
  assignee number(9);
  document_attached number(1);
begin
	dbms_sql.define_column(cursor_name, 1, id);
	dbms_sql.define_column(cursor_name, 2, class_id);
	dbms_sql.define_column(cursor_name, 3, status_id);
	dbms_sql.define_column(cursor_name, 4, order_date);
	dbms_sql.define_column(cursor_name, 5, document_number, 16);
	dbms_sql.define_column(cursor_name, 6, creator_channel_id);
	dbms_sql.define_column(cursor_name, 7, login, 60);
	dbms_sql.define_column(cursor_name, 8, ff_subject, 105);
  dbms_sql.define_column(cursor_name, 9, woc_id);
  dbms_sql.define_column(cursor_name, 10, glb_cust_id);
  dbms_sql.define_column(cursor_name, 11, sector);
  dbms_sql.define_column(cursor_name, 12, segment, 32);
  dbms_sql.define_column(cursor_name, 13, isDocumentAttached);
	dbms_sql.define_column(cursor_name, 14, category_id);
	dbms_sql.define_column(cursor_name, 15, subcategory_id);
	dbms_sql.define_column(cursor_name, 16, category_name, 50);
	dbms_sql.define_column(cursor_name, 17, subcategory_name, 50);
	dbms_sql.define_column(cursor_name, 18, assignee);
	dbms_sql.define_column(cursor_name, 19, document_attached);

	rows_processed := dbms_sql.execute(cursor_name);

	while dbms_sql.fetch_rows(cursor_name) > 0 loop
		dbms_sql.column_value(cursor_name, 1, id);
		dbms_sql.column_value(cursor_name, 2, class_id);
		dbms_sql.column_value(cursor_name, 3, status_id);
		dbms_sql.column_value(cursor_name, 4, order_date);
		dbms_sql.column_value(cursor_name, 5, document_number);
		dbms_sql.column_value(cursor_name, 6, creator_channel_id);
		dbms_sql.column_value(cursor_name, 7, login);
		dbms_sql.column_value(cursor_name, 8, ff_subject);
    dbms_sql.column_value(cursor_name, 9, woc_id);
	  dbms_sql.column_value(cursor_name, 10, glb_cust_id);
    dbms_sql.column_value(cursor_name, 11, sector);
	  dbms_sql.column_value(cursor_name, 12, segment);
    dbms_sql.column_value(cursor_name, 13, isDocumentAttached);
		dbms_sql.column_value(cursor_name, 14, category_id);
		dbms_sql.column_value(cursor_name, 15, subcategory_id);
		dbms_sql.column_value(cursor_name, 16, category_name);
		dbms_sql.column_value(cursor_name, 17, subcategory_name);
		dbms_sql.column_value(cursor_name, 18, assignee);
		dbms_sql.column_value(cursor_name, 19, document_attached);

		row := ffo_t(
			id,
			class_id,
			status_id,
			order_date,
			document_number,
			creator_channel_id,
			login,
			ff_subject,
			woc_id,
		        glb_cust_id,
			sector,
            		segment,
	    		isDocumentAttached,
			category_id,
			subcategory_id,
			category_name,
			subcategory_name,
			assignee,
			document_attached
		);
		rowset.extend;
		rowset(rowset.count) := row;
	end loop;

	dbms_sql.close_cursor(cursor_name);

	open rv for select * from table(cast(rowset as ffo_set_t));
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
	pSubject in varchar2,
	pText in varchar2,

	-- system
	channels in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date,
	assignee in integer,
	category_id in integer,
	subcategory_id in integer
) return cursor_t is
	rq varchar2(32767);
	cursor_name integer;
	custName varchar2(1024) := bocommon.prepare_like(pCustName);
	userLogin varchar2(1024) := bocommon.prepare_like(pUserLogin);
	remoteId integer := BODocuments.get_remote_officer(officerId);
    has_rboorders BOOLEAN := bocommon.has_role('RBOORDERS') > 0;
    has_finance_edit BOOLEAN := bocommon.has_role('RBO_FINANCE_CONSULTATION_EDIT') > 0;
begin
	if custName is not null or remoteId > 0 then
		delete from tmp_request_data;
		insert into tmp_request_data (requested_id)
		select distinct c.id from ibglb.cusd c
		where (remoteId <= 0 or	c.remote_officers.contains(remoteId) = 1) and
			(custName is null or c.name.is_like(custName) = 1);
	end if;

	rq := rq || 'select /* BOFFO.find_by_filter */';
--	if custId is not null or custName is not null or remoteId > 0 then
--		rq := rq || ' /*+ INDEX (p IDX_DOC_CUST_ID_DATE) */';
--	elsif userLogin is not null then
--		rq := rq || ' /*+ INDEX (p IDX_DOC_WOC_ID_DATE) */';
--	end if;
	rq := rq || ' p.id id,';
	rq := rq || ' p.class_id class_id,';
	rq := rq || ' p.status_id status_id,';
	rq := rq || ' p.order_date order_date,';
	rq := rq || ' p.document_number document_number,';
	rq := rq || ' p.creator_channel_id creator_channel_id,';
	rq := rq || ' (select login from ways_of_connection where id = p.creator_woc_id) login,';
	rq := rq || ' p.ff_subject ff_subject';
    rq := rq || ' , p.creator_woc_id woc_id';
    rq := rq || ' , p.from_customer glb_cust_id';
    rq := rq || ' ,(select c.sector from cusd c where c.id = p.from_customer)sector';
    rq := rq || ' ,(select c.segment from cusd c where c.id = p.from_customer)segment';
    rq := rq || ' ,(select count(*) from document_attachments where document_id = p.id and type in (2,5,6,7,8,9,10,13,14,15,16)) isDocumentAttached';

    rq := rq || ' , p.ffo_category_id category_id';
    rq := rq || ' , p.ffo_subcategory_id subcategory_id';
    rq := rq || ' , (select nvl(trim(decode(:LanguageID,
			0, c.name.name_lv,
			1, c.name.name_en,
			2, c.name.name_ru,
			3, c.name.extra_1,
			4, c.name.extra_2,
			5, c.name.extra_3,
			c.name.name_en
		)), c.name.name_en) from ffo_categories c where c.id = p.ffo_category_id) category_name';
     rq := rq || ' ,(select nvl(trim(decode(:LanguageID,
			0, c.name.name_lv,
			1, c.name.name_en,
			2, c.name.name_ru,
			3, c.name.extra_1,
			4, c.name.extra_2,
			5, c.name.extra_3,
			c.name.name_en
		)), c.name.name_en) from ffo_categories c where c.id = p.ffo_subcategory_id) subcategory_name';
    rq := rq || ' , p.ffo_assignee assignee';
	rq := rq || ' ,(select max(nvl(is_type_visible, 0)) from document_attachments da where da.document_id = p.id) document_attached';

	rq := rq || ' from documents p';
	rq := rq || ' where rownum <= :ResultSetSize';
	rq := rq || ' and ' || bocommon.order_date_expression(custId, custName, userLogin, remoteId);
    rq := rq || ' and p.class_id in (' || docClass || ')';

    IF has_rboorders THEN
        rq := rq || ' AND p.class_id IN (6, 524, 527, 731, 732, 734, 755, 764, 769, 770, 771, 781, 782, 783, 794, 798, 729, 1200)';
    END IF;

	rq := rq || ' and p.creator_channel_id in (' || channels || ')';
	rq := rq || ' and p.status_id in (' || statuses || ')';

	if pText is not null then
		rq := rq || ' and upper(p.ff_text) like :Body';
	end if;
	if pSubject is not null then
		rq := rq || ' and upper(p.ff_subject) like :Subject';
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
	if custName is not null or remoteId > 0 then
		rq := rq || ' and p.from_customer in (select requested_id from tmp_request_data)';
	end if;

	if assignee > 0 then
		rq := rq || ' and p.FFO_ASSIGNEE = :Assignee';
	end if;
	if category_id > 0 then
		rq := rq || ' and p.FFO_CATEGORY_ID = :CategoryId';
	end if;
	if subcategory_id > 0 then
		rq := rq || ' and p.FFO_SUBCATEGORY_ID = :SubcategoryId';
	end if;


	cursor_name := dbms_sql.open_cursor;

	dbms_sql.parse(cursor_name, rq, dbms_sql.native);
	dbms_sql.bind_variable(cursor_name, ':ResultSetSize', bocommon.ResultSetSize);
	dbms_sql.bind_variable(cursor_name, ':DateFrom', createdFrom);
	dbms_sql.bind_variable(cursor_name, ':DateTill', createdTill);
	dbms_sql.bind_variable(cursor_name, ':LanguageID', bocommon.LanguageId);
	--dbms_sql.bind_variable(cursor_name, ':ClassId', rba_const.FREE_FORMAT);
	if pText is not null then
		dbms_sql.bind_variable(cursor_name, ':Body', bocommon.prepare_like(pText));
	end if;
	if pSubject is not null then
		dbms_sql.bind_variable(cursor_name, ':Subject', bocommon.prepare_like(pSubject));
	end if;
	if custId is not null then
		dbms_sql.bind_variable(cursor_name, ':CustomerId', custId);
	end if;
	if userLogin is not null then
		dbms_sql.bind_variable(cursor_name, ':UserLogin', userLogin);
	end if;

	if assignee > 0 then
		dbms_sql.bind_variable(cursor_name, ':Assignee', assignee);
	end if;
	if category_id > 0 then
		dbms_sql.bind_variable(cursor_name, ':CategoryId', category_id);
	end if;
	if subcategory_id > 0 then
		dbms_sql.bind_variable(cursor_name, ':SubcategoryId', subcategory_id);
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
	pSubject in varchar2,
	pText in varchar2,

	-- system
	docId in varchar2,
	channels in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date,
  assignee in integer,
  category_id in integer,
  subcategory_id in integer
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
		pSubject,
		pText,
		channels,
		statuses,
		createdFrom,
		createdTill,
    assignee,
    category_id,
    subcategory_id
	);
end;

function find_my return cursor_t is
	rv cursor_t;
	t_dept num_table_type;
	my_locations varchar2_loc_type := bocommon.isDefaultFor;
begin
	bodocuments.get_remote_officers(t_dept);
	open rv for select
		/* BOFFO.find_my */
		/*+ INDEX (p IDX_DOC_STATUS_CLASS) */
		p.id id,
		p.class_id class_id,
		p.status_id status_id,
		p.order_date order_date,
		p.document_number document_number,
		p.creator_channel_id creator_channel_id,
		(select login from ways_of_connection where id = p.creator_woc_id) login,
		p.ff_subject ff_subject
        , p.creator_woc_id woc_id
        , p.from_customer glb_cust_id
        , (select c.sector from cusd c where c.id = p.from_customer)sector
        , (select c.segment from cusd c where c.id = p.from_customer)segment
	, (select count(*) from document_attachments where document_id = p.id and type in (2,5,6,7,8,9,10,13,14,15,16)) isDocumentAttached
	, p.ffo_category_id category_id,
  p.ffo_subcategory_id subcategory_id,
        (select nvl(trim(decode(bocommon.LanguageId,
			0, c.name.name_lv,
			1, c.name.name_en,
			2, c.name.name_ru,
			3, c.name.extra_1,
			4, c.name.extra_2,
			5, c.name.extra_3,
			c.name.name_en
		)), c.name.name_en) from ffo_categories c where c.id = p.ffo_category_id) category_name,
    (select nvl(trim(decode(bocommon.LanguageId,
			0, c.name.name_lv,
			1, c.name.name_en,
			2, c.name.name_ru,
			3, c.name.extra_1,
			4, c.name.extra_2,
			5, c.name.extra_3,
			c.name.name_en
		)), c.name.name_en) from ffo_categories c where c.id = p.ffo_subcategory_id) subcategory_name,
        p.ffo_assignee assignee,
	(select max(nvl(is_type_visible, 0)) from document_attachments da where da.document_id = p.id) document_attached

	from documents p
	where rownum <= bocommon.ResultSetSize
        and p.class_id in (  rba_const.FREE_FORMAT, 524, 527, 731, 732, 734, 755, 764, 769, 770, 771, 781, 782, 783, 794, 798, 729, 1200)
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

procedure ffo(
	pId in varchar2,
	userName out varchar2,
	userId out varchar2,
	officerName out varchar2,
    goldManager out varchar2,
	custName out varchar2,
	custAccount out varchar2,
	globusNo out varchar2,
	pLocation out varchar2,
	-- ffo:
	fText out varchar2,
	--
	itc out varchar2,
	itb out varchar2,
	signTime out date,
	--signDevType out integer,
	--signDevId out varchar2,
	--signKey1 out varchar2,
	--signKey2 out varchar2,
	signRSA out varchar2,
    sector out number,
    segment out varchar2
) is
begin
	select
		/* BOFFO.ffo */
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
		d.from_location,
		d.ff_text,
		d.info_to_customer,
		d.info_to_bank,
		d.signature_date,
		--d.signature_cdevice_type_id,
		--d.signature_cdevice_serial,
		--d.signature_key_1,
		--d.signature_key_2,
		--substr(d.signature_rsa, instr(d.signature_rsa, ';') + 1),
        (select substr(s.signature_rsa, instr(s.signature_rsa, ';') + 1) from document_signature_rel r, document_signatures s where r.document_id = pId and S.ID = r.signature_id and rownum <= 1 ),
        (   select dog.officer_name
            from
                ibglb.cusd cg,
                ibglb.glb_dept_accnt_officer dog
            where
                cg.id = d.from_customer
                and cg.manager_code = dog.id
                and cg.segment = 200
        ),
       c.sector,
       c.segment
	into
		globusNo,
		userName,
		userId,
		officerName,
		custName,
		custAccount,
		pLocation,
		fText,
		itc,
		itb,
		signTime,
		--signDevType,
		--signDevId,
		--signKey1,
		--signKey2,
		signRSA,
        goldManager,
        sector,
        segment
	from documents d, v$users u, acsd a, cusd c, ways_of_connection w,
		(select d.id id, o.officer_name name
		from documents d, acsd a, cusd c, ibglb.glb_dept_accnt_officer o,
			ways_of_connection w
		where d.id = pId and
			c.id = d.from_customer and
			a.id(+) = d.from_account and
			w.id(+) = d.creator_woc_id and
			o.id = c.remote_officers.get_id(nvl(a.location, w.contract_location))
		) remote_officer
	where d.id = pId and d.id = remote_officer.id(+) and
		a.id(+) = d.from_account and
		c.id(+) = d.from_customer and
		u.id = d.creator_user_id and
		w.id(+) = d.creator_woc_id;

end;

function get_categories return cursor_t is
	rv cursor_t;
begin
	open rv for select
		c.id id,
    		nvl(c.parent_id, 0) parent_id,
		nvl(trim(decode(bocommon.LanguageId,
			0, c.name.name_lv,
			1, c.name.name_en,
			2, c.name.name_ru,
			3, c.name.extra_1,
			4, c.name.extra_2,
			5, c.name.extra_3,
			c.name.name_en
		)), c.name.name_en) name
	from ffo_categories c
	where c.is_visible = 1;

	return rv;
end;

function categorize(pDocId in number, pCategoryId in number, pSubCategoryId in number, pAssignee in number) return integer is
	vRes int;
begin
	vRes := 0;

	update documents
	set ffo_category_id = decode(pCategoryId, 0, null, pCategoryId), ffo_subcategory_id = decode(pSubCategoryId, 0, null, pSubCategoryId), ffo_assignee = pAssignee
	where id = pDocId;

	return vRes;
end;

function set_processing(pId in varchar2, reason in varchar2, pNewStatus in integer, pMessageId in integer) return integer is
	vRes int;
begin
	vRes := 0;

	update documents
		set change_officer_id = bocommon.officerId
		where id = pId
		returning change_officer_id into vRes;

	if vRes > 0 then
		bodocuments.set_manual_status(pId, reason, pNewStatus, pMessageId);
	else
		vRes := 0;
	end if;

	return vRes;
end;


end;


/
