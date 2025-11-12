/************************** RBA database stored procedures ********************
 *    $Author: dteplih $
 *   $RCSfile: bo_faxedit4.sql,v $
 *  $Revision: 1.8 $
 *        $Id: bo_faxedit4.sql,v 1.8 2006/03/08 11:12:14 dteplih Exp $
 *
 ********* Copyright (c) 2001 Parex Bank, Latvia. All rights reserved *********/

CREATE OR REPLACE package BOFaxEdit as

EVENT_ORIG_CREATED constant int := 24502;
EVENT_ORIG_DIVIDED constant int := 24602;

DOC_ASSIGNED constant int := 17;

type cursor_t is ref cursor;

procedure add_document(
	pFaxId in varchar2,
	pDocClass in number,
	pOfficerId in number,
	pCustId in varchar2,
	pFromAccount in varchar2,
	pAmnt in fax_document.amount%type,
	pCcy in varchar2,
	pPartner in varchar2,
	pNote in varchar2,
	pSubj in varchar2,
	pDocStatus in number,
	pDTif in blob
);

end;
/
show err;

CREATE OR REPLACE package body BOFaxEdit as

procedure add_document(
	pFaxId in varchar2,
	pDocClass in number,
	pOfficerId in number,
	pCustId in varchar2,
	pFromAccount in varchar2,
	pAmnt in fax_document.amount%type,
	pCcy in varchar2,
	pPartner in varchar2,
	pNote in varchar2,
	pSubj in varchar2,
	pDocStatus in number,
	pDTif in blob
) is
	vDocId number;
	vFaxStatus fax.status_id%type;
begin
	select status_id into vFaxStatus from fax where sid = pFaxId;

	if vFaxStatus = BOFaxView.ORIG_NEW then 
		-- Dividing fax  
		update fax
		set
			status_id = BOFaxView.ORIG_DIVIDED,
			tif = null
		where
			sid = pFaxId;

		bocommon.log_event(
			pEventId => EVENT_ORIG_DIVIDED,
			pPayId   => pFaxId,
			pPrev    => BOFaxView.ORIG_NEW,
			pNew     => BOFaxView.ORIG_DIVIDED
	        );
	end if;

	-- Registering fax document
	select UNQ_PAYMENT_ID_SEQ.nextVal into vDocId from dual;

	bocommon.log_event( -- FIXME: Additional info (Class) | pPayId = DocId ?
                pEventId => BOFaxView.DOC_CREATED,
                pPayId   => vDocId,
                pNew     => DOC_ASSIGNED
	);

	insert into fax_document(
		id,
		sid,
		class_id,
		officer_id,
		cust_id,		
		from_account,
		amount,
		amount_ccy,
		partner,
		note,
		subject,
		status_id,
		tif,
		audit_log_id,
		change_officer_id,
		change_date
	) values (
		vDocId,
		pFaxId,
		pDocClass,
		pOfficerId,
		pCustId,
		pFromAccount,
		pAmnt,
		pCcy,
		pPartner,
		pNote,
		pSubj,
		DOC_ASSIGNED,
		pDTif,
		UNQ_AUDIT_LOG_ID_SEQ.currVal,
		bocommon.officerId,
		SysDate
	);
end;

end;
/
show err;
