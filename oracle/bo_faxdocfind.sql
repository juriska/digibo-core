CREATE OR REPLACE package BOFaxDocFind as

type cursor_t is ref cursor;

function find(
	pFaxId in varchar2,
	pFromFax in varchar2,
	pFromCSid in varchar2,

	pDocId in varchar2,
	pCustId in varchar2,
	pFromAccount in varchar2,
	pAmountFrom in varchar2,
	pAmountTo in varchar2,
	pDocCcy in varchar2,
	pOfficerId in number,
	pDocClass in number,

	pClasses in varchar2,
	pStatuses in varchar2,

	pPartner in varchar2,
	pSubj in varchar2,

	pRecvTimeFrom in number,
	pRecvTimeTo in number
) return cursor_t;

end;
/

show err;

CREATE OR REPLACE package body BOFaxDocFind as

function find_by_filter(
	pFromFax in varchar2,
	pFromCSid in varchar2,
	pCustId in varchar2,
	pFromAccount in varchar2,
	pAmountFrom in varchar2,
	pAmountTo in varchar2,
	pDocCcy in varchar2,
	pOfficerId in number,
	pDocClass in number,
	pClasses in varchar2,
	pStatuses in varchar2,
	pPartner in varchar2,
	pSubj in varchar2,
	pRecvTimeFrom in number,
	pRecvTimeTo in number
) return cursor_t is
	rv cursor_t;
	t_classes num_table_type := bocommon.str2table(pClasses);
	t_statuses num_table_type := bocommon.str2table(pStatuses);
	is_assistant_only integer := 0;
begin
	if dbms_session.is_role_enabled('RBOFAXASSISTANT') and
		not dbms_session.is_role_enabled('RBOFAXMANAGER') then
		is_assistant_only := 1;
	end if;

	open rv for select  /* BOFaxDocFind.find_filter */
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
	where rownum <= bocommon.ResultSetSize and
		f.sid = d.sid
		and (pDocClass = 0 or d.class_id = pDocClass)
		and (pDocClass != 0 or d.class_id in (select * from table(cast(t_classes as num_table_type))))
		and (is_assistant_only = 0 or (d.class_id != 4 and d.class_id != 6))
		and (pFromFax is null or upper(f.from_Fax) like bocommon.prepare_like(pFromFax))
		and (pFromCSid is null or upper(f.from_CSID) like bocommon.prepare_like(pFromCSid))
		and (pRecvTimeFrom = 0 or f.receive_time between pRecvTimeFrom and pRecvTimeTo)
		and (pCustId is null or d.cust_id = pCustId)
		and (pFromAccount is null or upper(d.from_account) like bocommon.prepare_like(pFromAccount))
		and (pAmountTo is null or d.amount between nvl(pAmountFrom, 0) and pAmountTo)
		and (pDocCcy is null or d.amount_ccy = pDocCcy)
		and (pPartner is null or upper(d.partner) like bocommon.prepare_like(pPartner))
		and (pSubj is null or upper(d.subject) like bocommon.prepare_like(pSubj))
		and (pOfficerId = 0 or d.officer_id = pOfficerId)
		and (pStatuses is null or d.status_id in (select * from table(cast(t_statuses as num_table_type))));
	return rv;
end;

function find_by_id(
	pFaxId in varchar2,
	pDocId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select /* BOFaxDocFind.find_by_id */
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
	where f.sid = pFaxId and d.id = pDocId and f.sid = d.sid;
	return rv;
end;

function find_by_doc_id(
	pDocId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select /* BOFaxDocFind.find_by_doc_id */
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
	where d.id = pDocId and f.sid = d.sid;
	return rv;
end;

function find_by_fax_id(
	pFaxId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select  /* BOFaxDocFind.find_by_fax_id */
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
	where f.sid = pFaxId and f.sid = d.sid;
	return rv;
end;

function find(
	pFaxId in varchar2,
	pFromFax in varchar2,
	pFromCSid in varchar2,
	pDocId in varchar2,
	pCustId in varchar2,
	pFromAccount in varchar2,
	pAmountFrom in varchar2,
	pAmountTo in varchar2,
	pDocCcy in varchar2,
	pOfficerId in number,
	pDocClass in number,
	pClasses in varchar2,
	pStatuses in varchar2,
	pPartner in varchar2,
	pSubj in varchar2,
	pRecvTimeFrom in number,
	pRecvTimeTo in number
) return cursor_t is
begin
	if pFaxId is not null and pDocId is not null then
		return find_by_id(pFaxId, pDocId);
	elsif pFaxId is not null then
		return find_by_fax_id(pFaxId);
	elsif pDocId is not null then
		return find_by_doc_id(pDocId);
	end if;
	return find_by_filter(
		pFromFax,
		pFromCSid,
		pCustId,
		pFromAccount,
		pAmountFrom,
		pAmountTo,
		pDocCcy,
		pOfficerId,
		pDocClass,
		pClasses,
		pStatuses,
		pPartner,
		pSubj,
		pRecvTimeFrom,
		pRecvTimeTo
	);
end;

end;
/

show err;
