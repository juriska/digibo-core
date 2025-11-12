/************************** RBA database stored procedures ********************
 *    $Author: boris $
 *   $RCSfile: bo_faxview4.sql,v $
 *  $Revision: 1.29 $
 *        $Id: bo_faxview4.sql,v 1.29 2009/03/12 15:00:40 boris Exp $
 *
 ********* Copyright (c) 2001 Parex Bank, Latvia. All rights reserved *********/

CREATE OR REPLACE package BOFaxView as

DOC_CREATED        constant int := 24701;
DOC_MODIFIED       constant int := 24703;

ORIG_NEW     constant int := 1;
ORIG_DIVIDED constant int := 2;

Success  constant int := 0;
LockedBy constant int := 1; -- see OfficerName and OfficerPhone;
Locked   constant int := 2; -- non BO lock;
Error    constant int := 3;

type cursor_t is ref cursor;

function find_my_documents(pClasses in varchar2) return cursor_t;

procedure load_fax(
	pId in out varchar2,
	pDocId in out varchar2,
	pFromFax  out varchar2,
	pFromCSid out varchar2,
	pRecvTime out number,
	pRecvStatus out number,
	pFaxStatus out number,
	pFTif out BLOB,
	documents out cursor_t
);

procedure init(
	pId in varchar2,
	pClassId out number,
	pStatusId out number
);

function set_lock(
	pId in out varchar2,
	pDoc in number,
	pOfficerName  out varchar2,
	pOfficerPhone out varchar2
) return int;

function load_history(pId in varchar2) return cursor_t;
function load_actual(pId in varchar2) return cursor_t;

function last_officer(
	pCustId in number,
	pFromAccount in varchar2,
	pClassId in number,
	pOfficers in varchar2
) return number;

function next_fax_id return number;

function next_document_id(
	pDocId in out number,
	pClasses in varchar2
) return number;

end;
/

show err;

CREATE OR REPLACE package body BOFaxView as

function find_my_documents(
	pClasses in varchar2
) return cursor_t is
	rv cursor_t;
	replaced cursor_t;
	t_replaced num_table_type := num_table_type();
	r integer;
	rfm integer;
	custd integer;
	t_classes num_table_type := bocommon.str2table(pClasses);
begin
	if pClasses = '3,4,5,6' then custd := 1; else custd := 0; end if;
	if dbms_session.is_role_enabled('RBOFAXMANAGER') then rfm := 1; else rfm := 0; end if;

	open replaced for select r.officer_id id from officer_replacement r
		where r.replaced_by = bocommon.officerId;
	fetch replaced into r;
	while replaced%found loop
		t_replaced.extend;
		t_replaced(t_replaced.count) := r;
		fetch replaced into r;
	end loop;
	close replaced;

	open rv for select /* BOFaxView.find_my_documents */
		f.sid id,
		f.receive_time recvTime,
		d.id docId,
		d.officer_id officerId,
		d.cust_id custId,
		d.from_account acc,
		d.amount amnt,
		d.amount_ccy ccy,
		d.class_id docClass,
		d.status_id status,
		d.note note,
		d.partner partner,
		d.subject subject
	from fax f, fax_document d
	where rownum <= bocommon.ResultSetSize
		and f.sid = d.sid
		and (
			-- For Customer Descriptive Document
			-- only officer with role RBOFAXMANAGER
			-- allowed to select assigned/reviewed documents
			(1 = custd and 1 = rfm and (
					(d.class_id = 3/*SDR*/ and d.status_id = 24/*RBA_CONST.REVIEWED*/)
					or (d.class_id in (4,5,6) and d.status_id = RBA_CONST.ASSIGNED)
				)
			)
			or
			(0 = custd and d.class_id in (select * from table(cast(t_classes as num_table_type)))
				and d.status_id = RBA_CONST.ASSIGNED)
		)
		and (
			(bocommon.is_replaced = 0 and d.officer_id = bocommon.officerId) or
			d.officer_id in (select * from table(cast(t_replaced as num_table_type)))
		);
	return rv;
end;

procedure load_fax(
	pId in out varchar2,
	pDocId in out varchar2,
	pFromFax  out varchar2,
	pFromCSid out varchar2,
	pRecvTime out number,
	pRecvStatus out number,
	pFaxStatus out number,
	pFTif out BLOB,
	documents out cursor_t
) is begin
	select
		/*+ INDEX (f PK_FAX ) */		
		from_fax,
		from_csid,
		receive_time,
		receive_status,
		status_id,
		tif
	into
		pFromFax,
		pFromCSid,
		pRecvTime,
		pRecvStatus,
		pFaxStatus,
		pFTif
	from
		fax
	where
		sid = pId;

	if ORIG_DIVIDED = pFaxStatus then
		pFTif := null;
		open documents for select
			/*+ INDEX (d FAX_PAGE_PK) */		
			d.class_id	pClass,
			d.id		pDocId,
			d.cust_id	pCustId,
			d.officer_id	pOfficerId,
			d.from_account	pFromAccount,
			d.amount	pAmnt,
			d.amount_ccy	pCcy,
			d.partner	pPartner,
			d.note		pNote,
			d.subject	pSubj,
			d.status_id	pDocStatus,
			d.tif		pFTif
		from
			fax_document d
		where
			d.sid = pId
			and (pDocId is null or d.id = pDocId);
	end if;
exception
	when NO_DATA_FOUND then
		pId := null;
end;

procedure init(
	pId in varchar2,
	pClassId out number,
	pStatusId out number
) is begin
	select class_id, status_id into pClassId, pStatusId
	from fax_document
	where id = pId;
end;

function set_lock(
	pId in out varchar2,
	pDoc in number,
	pOfficerName  out varchar2,
	pOfficerPhone out varchar2
) return int is
	vHandle varchar2(128);
	vRes int;
begin
	if(pDoc = 1) then
		dbms_lock.allocate_unique('faxDocId='||pId, vHandle);
	else
		dbms_lock.allocate_unique('faxId='||pId, vHandle);
	end if;
	vRes := dbms_lock.request(lockhandle=> vHandle, timeout=> 0, release_on_commit=> true);
	if vRes = 0 then begin
		if pDoc = 1 then
			select id into pId
			from fax_document
			where id = pId for update nowait;
			return Success;

		else
			select sid into pId
			from fax
			where sid = pId for update nowait;
			return Success;
		end if;
		
		exception when bocommon.RESOURCE_BUSY_NOWAIT then
			vRes := dbms_lock.release(lockhandle => vHandle);
			vRes := 1; -- dbms_lock.request timeout.
		end;
	end if;

	if vRes = 1 then
		bocommon.get_locker(vHandle, pOfficerName, pOfficerPhone);
		if pOfficerName is null then
			return Locked;
		else
			return LockedBy;
		end if;
	end if;
	return Error;
end;

function load_actual(pId in varchar2) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		/*+ INDEX (d FAX_PAGE_PK) */		
		d.change_date changeDate,
		d.change_officer_id changeOfficer,
		d.class_id docClass,
		d.cust_id custId,
		d.from_account acc,
		d.amount amnt,
		d.amount_ccy ccy,
		d.officer_id officerId,
		d.partner partner,
		d.subject subj,
		d.status_id status,
		d.note note
	from
		fax_document d
	where
		d.id = pId;
	return rv;
end;

function load_history(pId in varchar2) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		/*+ INDEX (h PK_FAX_DOC_HISTORY) */		
		h.change_date changeDate,
		h.change_officer_id changeOfficer,
		h.class_id docClass,
		h.cust_id custId,
		h.from_account acc,
		h.amount amnt,
		h.amount_ccy ccy,
		h.officer_id officerId,
		h.partner partner,
		h.subject subj,
		h.status_id status,
		h.note note
	from
		fax_doc_history h
	where
		h.doc_id = pId;
	return rv;
end;

function last_officer(
	pCustId in number,
	pFromAccount in varchar2,
	pClassId in number,
	pOfficers in varchar2
) return number is
	officerId number;
	t_officers num_table_type := bocommon.str2table(pOfficers);
begin
	select * into officerId from
		(select
			d.officer_id
		from
			fax f,
			fax_document d
		where
			d.sid = f.sid
			and (pClassId = 0 or d.class_id = pClassId)
			and (pCustId is null or d.cust_id = pCustId)
			and (pFromAccount is null or d.from_account = pFromAccount)
			and d.officer_id in (select * from table(cast(t_officers as num_table_type)))
		order by f.receive_time desc)
	where rownum = 1;
	return officerId;
exception
	when NO_DATA_FOUND then
		return null;
end;

function next_fax_id return number is
	vFaxId number;
begin
	select * into vFaxId from
		(select sid
		from fax
		where status_id = ORIG_NEW
		order by sid)
	where rownum = 1;
	return vFaxId;
exception
	when NO_DATA_FOUND then
		return null;
end;

function next_document_id(
	pDocId in out number,
	pClasses in varchar2
) return number is
	vFaxId number;
	replaced cursor_t;
	t_replaced num_table_type := num_table_type();
	r integer;
	rfm integer;
	rfa integer;
	custd integer;
	t_classes num_table_type := bocommon.str2table(pClasses);
begin
	if pClasses = '3,4,5,6' then custd := 1; else custd := 0; end if;
	if dbms_session.is_role_enabled('RBOFAXMANAGER') then rfm := 1; else rfm := 0; end if;
	if dbms_session.is_role_enabled('RBOFAXASSISTANT') then rfa := 1; else rfa := 0; end if;

	open replaced for select r.officer_id id from officer_replacement r
		where r.replaced_by = bocommon.officerId;
	fetch replaced into r;
	while replaced%found loop
		t_replaced.extend;
		t_replaced(t_replaced.count) := r;
		fetch replaced into r;
	end loop;
	close replaced;

	select * into vFaxId, pDocId from
		(select d.sid, d.id
		from
			fax f,
			fax_document d
		where
			f.sid = d.sid
			and (
				-- For Customer Descriptive Document
				-- only officer with role RBOFAXMANAGER
				-- allowed to select assigned/reviewed documents
				(1 = custd and 1 = rfm and (
						(d.class_id = 3/*SDR*/ and d.status_id = 24/*RBA_CONST.REVIEWED*/)
						or (d.class_id in (4,5,6) and d.status_id = RBA_CONST.ASSIGNED)
					)
				)
				or
				(0 = custd and d.class_id in (select * from table(cast(t_classes as num_table_type)))
					and d.status_id = RBA_CONST.ASSIGNED)
			)
			and (
				(bocommon.is_replaced = 0 and d.officer_id = bocommon.officerId) or
				d.officer_id in (select * from table(cast(t_replaced as num_table_type)))
			)
			and d.id > pDocId
		order by d.id
		)
	where rownum = 1;
	return vFaxId;
exception
	when NO_DATA_FOUND then
		return null;
end;

end;
/

show err;
