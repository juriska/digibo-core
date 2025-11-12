/************************** RBA database stored procedures ********************
 *    $Author: mstamers $
 *   $RCSfile: bo_smsagreementedit.sql,v $
 *  $Revision: 1.28 $
 *        $Id: bo_smsagreementedit.sql,v 1.28 2015/09/07 08:50:16 mstamers Exp $
 *
 ********* Copyright (c) 2001 Parex Bank, Latvia. All rights reserved *********/

CREATE OR REPLACE package BOSMSAgreementEdit as

DOC_RIGHTS_TYPE_CUSTOMER constant int := 1;
DOC_RIGHTS_TYPE_CCY constant int := 14;
DOC_RIGHTS_TYPE_CARD constant int := 82;

type cursor_t is ref cursor;

procedure save_channel(
	pId in out number, -- woc.id
	pCustId in number,
	pLocation in varchar2,
	pChannel in number,
	pUserId in number,
	pLogin in out varchar2,
	pOperator in number,
	pPswd in varchar2,
	pChargesAcc in number,
	pParentId in number,
	pLanguage in number,
	pSeller in number,
	pDistribCenter in number,
	pFfSMS in integer
    , pSmsTime in varchar2
);

procedure set_rights(
	pWocId in number,
	pCustId in number,
	pLocation in varchar2,
	pAcc in varchar2,
	pCcy in varchar2,
	pDebitLimit in user_document_rights.debit_limit%type,
	pCreditLimit in user_document_rights.debit_limit%type,
	pServeBal in user_document_rights.debit_limit%type,
	pIncludeBal in user_document_rights.include_balance%type
    , pType in integer
);

procedure set_card_rights(
	pWocId in number,
	pCustId in number,
	pLocation in varchar2,
	pPan in varchar2,
	pAcc in varchar2,
	pCcy in varchar2,
	--pPinAuthLimit in user_document_rights.pin_auth_limit%type,
	--pNoPinAuthLimit in user_document_rights.no_pin_auth_limit%type,
	pCardAuthLimit in user_document_rights.card_auth_limit%type,
	pFailedAuthLimit in user_document_rights.failed_auth_limit%type,
	pReversalLimit in user_document_rights.reversal_limit%type,
	pServeBal in user_document_rights.serve_balance%type,
	pIncludeBal in user_document_rights.include_balance%type
);

end;
/
show err;

CREATE OR REPLACE package body BOSMSAgreementEdit as

procedure save_channel(
	pId in out number, -- woc.id
	pCustId in number,
	pLocation in varchar2,
	pChannel in number,
	pUserId in number,
	pLogin in out varchar2,
	pOperator in number,
	pPswd in varchar2,
	pChargesAcc in number,
	pParentId in number,
	pLanguage in number,
	pSeller in number,
	pDistribCenter in number,
	pFfSMS in integer
    , pSmsTime in varchar2
) is
	vBinded number;
	vStatus number;
	vLogin ways_of_connection.login%TYPE;
	vSellDate date;
begin
	--if Length(pLogin) < 8 then
	--	pLogin := '2' || pLogin;
	--end if;

	if pId is null then
		if pSeller is null and pDistribCenter is null then
			vSellDate := null;
		else 
			vSellDate := SysDate;
		end if;

		-- woc creation
		insert into ways_of_connection (
			id,
			channel_id,
			user_id,
			license_id,
			contract_location,

			login,
			password,
			cdevice_type_id,
			change_pwd_frequency,
			session_timeout,
			mobile_operator,
			charges_account_id,
			parent_id,
			seller_id,
			sell_date,
			sell_place,

			status_id,
			invalid_attempts_count,
			expiry_date,
			change_date,
			change_officer_id,

			language_id,

			accept_freeformat_sms
            , sms_time
		) values (
			unq_woc_id_seq.NextVal,
			pChannel,
			pUserId,
			unq_woc_id_seq.CurrVal,
			pLocation,

			pLogin,
			pPswd,
			RBA_CONST.NO_CODING_DEVICE,
			NULL, --bocustomeredit.USER_CHANGE_PASSWORD_FREQUENCY,
			NULL, --bocustomeredit.USER_SESSION_TIMEOUT,
			pOperator,
			pChargesAcc,
			pParentId,
			pSeller,
			vSellDate,
			pDistribCenter,

			RBA_CONST.USER_INACTIVE,
			NULL, --RBA_CONST.INV_ATMPTS_COUNT,
			decode(pChannel,
				RBA_CONST.INET, SysDate - 1,
				RBA_CONST.DIGI_FIRMA, null),
			SysDate,
			bocommon.officerId,
			pLanguage,
	
			pFfSMS
            , pSmsTime
		)
		returning id into pId;

		if pId is null then
			return;
		end if;

		bocustomeredit.bind_to_customer(pId, pCustId);

		-- setting default rights: customer - restricted
		insert into user_document_rights (
			woc_id,
			customer_id,
			location,
			type,
			right,
			change_officer_id,
			change_date
		) values (
			pId,
			pCustId,
			pLocation,
			DOC_RIGHTS_TYPE_CUSTOMER,
			'R',
			bocommon.officerId,
			SysDate
		);

		bocommon.log_event(pUserId, 60102, 'Binded to customer', pId);
	else
	        -- woc and access right history
		bocustomeredit.save_channel_hist(pId);

		-- Deleting old rights for IBAN
		delete from user_document_rights
		where woc_id = pId and
			customer_id = pCustId and
			location = pLocation and
			type <> DOC_RIGHTS_TYPE_CUSTOMER; -- default: customer - restricted

		select
			sell_date,
			status_id,
			login
		into
			vSellDate,
			vStatus,
			vLogin
		from ways_of_connection
		where id = pId;
		
		if vSellDate is null and
			(pSeller is not null or pDistribCenter is not null) then
			vSellDate := SysDate;
		end if; 

		if vLogin != pLogin then
			vStatus := RBA_CONST.USER_INACTIVE;
		end if;

		-- current woc
		update ways_of_connection set
			login = pLogin,
			contract_location = pLocation,
			status_id = vStatus,
			mobile_operator = pOperator,
			charges_account_id = pChargesAcc,
			parent_id = pParentId,
			language_id = pLanguage,
			seller_id = pSeller,
			sell_date = vSellDate,
			sell_place = pDistribCenter,
			change_date = SysDate,
			change_officer_id = bocommon.officerId,
			accept_freeformat_sms = pFfSMS,
			change_woc_id = null
            , sms_time = pSmsTime
		where id = pId;

		select count(1) into vBinded from customer_globus_restrictions
		where woc_id = pId and cusd_id = pCustId;
		
		if vBinded = 0 then
			bocustomeredit.bind_to_customer(pId, pCustId);
		end if;

		bocommon.log_event(pUserId, 60102, '', pId);
	end if;

	-- Work order: 14,746
	RBA_SMS_CONFIG.UPDATE_ACCOUNT_FLAGS(pCustId);
end;

procedure set_rights(
	pWocId in number,
	pCustId in number,
	pLocation in varchar2,
	pAcc in varchar2,
	pCcy in varchar2,
	pDebitLimit in user_document_rights.debit_limit%type,
	pCreditLimit in user_document_rights.debit_limit%type,
	pServeBal in user_document_rights.debit_limit%type,
	pIncludeBal in user_document_rights.include_balance%type
    , pType in integer
) is begin
	insert into user_document_rights (
		woc_id,
		customer_id,
		location,
		account,
		ccy,
		type,
		right,
		debit_limit,
		credit_limit,
		serve_balance,
		include_balance,
		change_officer_id,
		change_date
	) values (
		pWocId,
		pCustId,
		pLocation,
		decode( pType, 11, null, pAcc),
		decode( pType, 11, null, pCcy),
		pType, --DOC_RIGHTS_TYPE_CCY,
		'V',
		pDebitLimit,
		pCreditLimit,
		pServeBal,
		pIncludeBal,
		bocommon.officerId,
		SysDate
	);
	-- Work order: 14,746
	RBA_SMS_CONFIG.UPDATE_ACCOUNT_FLAGS(pCustId);
end;

procedure set_card_rights(
	pWocId in number,
	pCustId in number,
	pLocation in varchar2,
	pPan in varchar2,
	pAcc in varchar2,
	pCcy in varchar2,
	--pPinAuthLimit in user_document_rights.pin_auth_limit%type,
	--pNoPinAuthLimit in user_document_rights.no_pin_auth_limit%type,
	pCardAuthLimit in user_document_rights.card_auth_limit%type,
	pFailedAuthLimit in user_document_rights.failed_auth_limit%type,
	pReversalLimit in user_document_rights.reversal_limit%type,
	pServeBal in user_document_rights.serve_balance%type,
	pIncludeBal in user_document_rights.include_balance%type
) is begin
	insert into user_document_rights (
		woc_id,
		customer_id,
		location,
		pan,
		account,
		ccy,
		type,
		right,
		--pin_auth_limit,
		--no_pin_auth_limit,
		card_auth_limit,
		failed_auth_limit,
		reversal_limit,
		serve_balance,
		include_balance,
		change_officer_id,
		change_date
	) values (
		pWocId,
		pCustId,
		pLocation,
		pPan,
		pAcc,
		pCcy,
		DOC_RIGHTS_TYPE_CARD,
		'V',
		--pPinAuthLimit,
		--pNoPinAuthLimit,
		pCardAuthLimit,
		pFailedAuthLimit,
		pReversalLimit,
		pServeBal,
		pIncludeBal,
		bocommon.officerId,
		SysDate
	);
	-- Work order: 14,746
	RBA_SMS_CONFIG.UPDATE_ACCOUNT_FLAGS(pCustId);
end;

end;
/
show err;
/
