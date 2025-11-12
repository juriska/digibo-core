/************************** RBA database stored procedures ********************
 *    $Author: dteplih $
 *   $RCSfile: bo_faxdocedit.sql,v $
 *  $Revision: 1.1 $
 *        $Id: bo_faxdocedit.sql,v 1.1 2006/02/23 14:42:48 dteplih Exp $
 *
 ********* Copyright (c) 2001 Parex Bank, Latvia. All rights reserved *********/

CREATE OR REPLACE package BOFaxDocEdit as

type cursor_t is ref cursor;

procedure save_document(
	pDocId in varchar2,
	pOfficerId in number,
	pCustId in varchar2,
	pFromAccount in varchar2,
	pAmnt in fax_document.amount%type,
	pCcy in varchar2,
	pPartner in varchar2,
	pNote in varchar2,
	pSubj in varchar2,
	pDocStatus in number
);

end;
/
show err;

CREATE OR REPLACE package body BOFaxDocEdit as

procedure save_document(
	pDocId varchar2,
	pOfficerId number,
	pCustId in varchar2,
	pFromAccount varchar2,
	pAmnt in fax_document.amount%type,
	pCcy varchar2,
	pPartner in varchar2,
	pNote in varchar2,
	pSubj in varchar2,
	pDocStatus in number
) is
	vStatus fax_document.status_id%TYPE;
begin
	select status_id into vStatus from fax_document where id = pDocId;

	bocommon.log_event(
		pEventId => BOFaxView.DOC_MODIFIED,
		pPayId   => pDocId,
		pNew     => vStatus);

	insert into fax_doc_history(
		audit_log_id,
		class_id,
		officer_id,
		cust_id,
		from_account,
		amount,
		amount_ccy,
		partner,
		subject,
		note,
		-- new, written to history:
		doc_id,
		status_id,
		change_officer_id,
		change_date
	) select
		audit_log_id,
		class_id,
		officer_id,
		cust_id,
		from_account,
		amount,
		amount_ccy,
		partner,
		subject,
		note,
		--
		id,
		status_id,
		change_officer_id,
		change_date
	from fax_document
	where id = pDocId;

	update fax_document
	set
		officer_id = pOfficerId,
		cust_id = pCustId,
		from_account = pFromAccount,
		amount = pAmnt,
		amount_ccy = pCcy,
		partner = pPartner,
		subject = pSubj,
		note = pNote,
		status_id = pDocStatus,
		audit_log_id = UNQ_AUDIT_LOG_ID_SEQ.currVal,
		change_officer_id = bocommon.officerId,
		change_date = SysDate
	where id = pDocId;
end;

end;
/
show err;
