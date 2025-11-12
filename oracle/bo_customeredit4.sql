/************************** RBA database stored procedures ********************
 *    $Author: mstamers $
 *   $RCSfile: bo_customeredit4.sql,v $
 *  $Revision: 1.79 $
 *        $Id: bo_customeredit4.sql,v 1.79 2013/07/12 07:24:58 mstamers Exp $
 *
 ********* Copyright (c) 2001 Parex Bank, Latvia. All rights reserved *********/

CREATE OR REPLACE package BOCustomerEdit as

USER_ACCESS_SPEC_RATE constant int := 35;
USER_ACCESS_CONNECT constant int := 100;
USER_ACCESS_INFO2BANK constant int := 140;
USER_SESSION_TIMEOUT constant int := 30;
DOC_RIGHTS_TYPE_CUSTOMER constant int := 1;

type cursor_t is ref cursor;

procedure save_user(
	pId in out number,
	pName varchar2,
	pIssuerCountry varchar2,
	pPersonalId varchar2,
	pPassportNo varchar2,
	pStdQ number,
	pSpecQ varchar2,
	pAnswer varchar2,
	pStreet varchar2,
	pCity varchar2,
	pCountry varchar2,
	pZip varchar2,
	pPhone varchar2,
	pMobile varchar2,
	pFax varchar2,
	pEmail varchar2,
	pApart varchar2,
	pHouse varchar2,
	pCustomerId varchar2,
	pMigrStatus varchar2
);

procedure save_user_small(
	pId in out number,
	pStdQ number,
	pSpecQ varchar2,
	pAnswer varchar2,
	pCustomerId varchar2,
	pMigrStatus varchar2
);

procedure save_channel( -- binding user to customer/license making a "channel".
	pId in out number, -- woc.id
	pCustId in number,
	pLocation in varchar2,
	pChannel in number,
	pLicense in varchar2,
	pUserId in number,
	pLogin in varchar2,
	pPswdNum in varchar2,
	pCDevType in number,
	pCDeviceId in varchar2,
	pSpecRate in number,
	pInfo2Bank in number,
	pSeller in number,
	pDistribCenter in number,
	pDFConnectRight in number
);

procedure bind_to_customer(
	pWocId number,
	pCustId number
);

procedure save_channel_hist(pId in number);

procedure activate_licence(pId number);

procedure activate_agreement(pId in number);

procedure set_web_access(
	pWocId in number,
	pRight in number,
	pOn in number
);

procedure drop_access(
	pWocId in number,
	pCustId in number,
	pLocation in varchar2
);

procedure set_access(
	pWocId in number,
	pCustId in number,
	pLocation in varchar2,
	pIban in varchar2,
	pCcy in varchar2,
	pType in int,
	pRight in int
);

function rem_user( -- unbinding user from customer/license
	pWocId in number,
	pChannelId in number,
	pCustId in number,
	pCertId in varchar2,
	pLocation in varchar2,
	pCount out integer
) return number;

PROCEDURE derive_access_rights(
        pi_woc_id              IN    glb_rb_contract.woc_id%TYPE,
        pi_customer_id         IN    glb_rb_contract.cust_id%TYPE
        );

end;
/

show err;

CREATE OR REPLACE package body BOCustomerEdit as

procedure save_user_small(
	pId in out number,
	pStdQ number,
	pSpecQ varchar2,
	pAnswer varchar2,
	pCustomerId varchar2,
	pMigrStatus varchar2
)
is
begin
    if pId is null then
         save_user(
            pId,
            null, --pName varchar2,
            null, --pIssuerCountry varchar2,
            null, --pPersonalId varchar2,
            null, --pPassportNo varchar2,
            pStdQ,
            pSpecQ,
            pAnswer,
            null, --pStreet varchar2,
            null, --pCity varchar2,
            null, --pCountry varchar2,
            null, --pZip varchar2,
            null, --pPhone varchar2,
            null, --pMobile varchar2,
            null, --pFax varchar2,
            null, --pEmail varchar2,
            null, --pApart varchar2,
            null, --pHouse varchar2,
            pCustomerId,
            pMigrStatus
        );
    else
        insert into user_history (
            id,
            name,
            street,
            city,
            phone,
            fax,
            mobile_phone,
            email,
            country_id,
            issuer_country_id,
            personal_id,
            passport_no,
            special_question,
            answer,
            zip_code,
            standard_question_id,
            user_id,
            change_date,
            change_officer_id,
            change_woc_id,
            customer_id,
            migrstatus
            ) select
            unq_user_hist_id_seq.NextVal,
            name,
            street,
            city,
            phone,
            fax,
            mobile_phone,
            email,
            country_id,
            issuer_country_id,
            personal_id,
            passport_no,
            special_question,
            answer,
            zip_code,
            standard_question_id,
            id,
            change_date,
            change_officer_id,
            change_woc_id,
            customer_id,
            MigrStatus
            from users u where u.id = pId;

            update users set 
                standard_question_id = pStdQ,
                special_question = upper(pSpecQ),
                answer = upper(pAnswer),
                change_woc_id = null,
                customer_id = pCustomerId,
                migrStatus = pMigrStatus,
                change_date = SysDate
            where id = pId;

            bocommon.log_event(pId, 60102, '');
        end if;
end;


procedure save_user(
	pId in out number,
	pName varchar2,
	pIssuerCountry varchar2,
	pPersonalId varchar2,
	pPassportNo varchar2,
	pStdQ number,
	pSpecQ varchar2,
	pAnswer varchar2,
	pStreet varchar2,
	pCity varchar2,
	pCountry varchar2,
	pZip varchar2,
	pPhone varchar2,
	pMobile varchar2,
	pFax varchar2,
	pEmail varchar2,
	pApart varchar2,
	pHouse varchar2,
	pCustomerId varchar2,
	pMigrStatus varchar2
) is
begin
	if pId is null then
		insert into users (
			id,
			name,
			issuer_country_id,
			personal_id,
			passport_no,
			standard_question_id,
			special_question,
			answer,
			street,
			city,
			country_id,
			zip_code,
			phone, 
			mobile_phone,
			fax,
			email,
			apart,
			house,
			change_officer_id,
			change_date,
			reg_date,
			customer_id,
			migrstatus
		) values (
			unq_user_id_seq.NextVal,
			pName,
			pIssuerCountry,
			upper(pPersonalId),
			upper(pPassportNo),
			pStdQ,
			upper(pSpecQ),
			upper(pAnswer),
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
			bocommon.officerId,
			SysDate,
			SysDate,
			pCustomerId,
			pMigrStatus
		)
		returning id into pId;

		bocommon.log_event(pId, 60101, '');

	else
		insert into user_history (
			id,
			name,
			street,
			city,
			phone,
			fax,
			mobile_phone,
			email,
			country_id,
			issuer_country_id,
			personal_id,
			passport_no,
			special_question,
			answer,
			zip_code,
			standard_question_id,
			user_id,
			change_date,
			change_officer_id,
			change_woc_id,
			customer_id,
			MigrStatus
		) select
			unq_user_hist_id_seq.NextVal,
			name,
			street,
			city,
			phone,
			fax,
			mobile_phone,
			email,
			country_id,
			issuer_country_id,
			personal_id,
			passport_no,
			special_question,
			answer,
			zip_code,
			standard_question_id,
			id,
			change_date,
			change_officer_id,
			change_woc_id,
			customer_id,
			MigrStatus
		from users u where u.id = pId;

		update users set 
			name = pName,
			issuer_country_id = pIssuerCountry,
			personal_id = upper(pPersonalId),
			passport_no = upper(pPassportNo),
			standard_question_id = pStdQ,
			special_question = upper(pSpecQ),
			answer = upper(pAnswer),
			street = pStreet,
			city = pCity,
			country_id = pCountry,
			zip_code = pZip,
			phone = pPhone, 
			mobile_phone = pMobile,
			fax = pFax,
			email = pEmail,
			apart = pApart,
			house = pHouse,
			change_officer_id = bocommon.officerId,
			change_date = SysDate,
			change_woc_id = null,
			customer_id = pCustomerId,
			migrStatus = pMigrStatus
		where id = pId;

		bocommon.log_event(pId, 60102, '');
	end if;
end;

procedure save_channel(
	pId in out number, -- woc.id
	pCustId in number,
	pLocation in varchar2,
	pChannel in number,
	pLicense in varchar2,
	pUserId in number,
	pLogin in varchar2,
	pPswdNum in varchar2,
	pCDevType in number,
	pCDeviceId in varchar2,
	pSpecRate in number,
	pInfo2Bank in number,
	pSeller in number,
	pDistribCenter in number,
	pDFConnectRight in number
) is
	vBinded number;
	vRights number;
	vStatus number;
	vSellDate date;
begin
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
			license_id,
			user_id,

			contract_location,
			location,

			login,
			generated_password_nr,
			change_pwd_frequency,
			session_timeout,
			cdevice_type_id,
			cdevice_serial_number,
			seller_id,
			sell_date,
			sell_place,

			status_id,
			invalid_attempts_count,
			expiry_date,
			change_date,
			change_officer_id,

			language_id
		) values (
			unq_woc_id_seq.NextVal,
			pChannel,
			pLicense,
			pUserId,

			decode(pChannel,
				RBA_CONST.DIGI_FIRMA, pLocation,
				RBA_CONST.INET, null),
			decode(pChannel,
				RBA_CONST.DIGI_FIRMA, pLocation,
				RBA_CONST.INET, null),

			pLogin,
			pPswdNum,
			RBA_CONST.CHANGE_PWD_FREQUENCY,
			USER_SESSION_TIMEOUT,
			pCDevType,
			pCDeviceId,
			pSeller,
			vSellDate,
			pDistribCenter,

			RBA_CONST.USER_ACTIVE,
			RBA_CONST.INV_ATMPTS_COUNT,
			decode(pChannel,
				RBA_CONST.INET, SysDate - 1,
				RBA_CONST.DIGI_FIRMA, null),
			SysDate,
			bocommon.officerId,
			0 -- language_id
		)
		returning id into pId;

		if pId is null then return; end if; -- exeception

		bind_to_customer(pId, pCustId);

		if pChannel = RBA_CONST.DIGI_FIRMA then
			set_web_access(pId, USER_ACCESS_CONNECT, pDFConnectRight);
		end if;
		set_web_access(pId, USER_ACCESS_SPEC_RATE, pSpecRate);
		set_web_access(pId, USER_ACCESS_INFO2BANK, pInfo2Bank);

		-- license
		if pLicense is not null then
			activate_licence(pLicense);
		end if;

		if pPswdNum is not null then
			update generated_passwords
			set status = RBA_CONST.PWD_ASSIGNED
			where nr = pPswdNum;
		end if;

		bocommon.log_event(pUserId, 60102, 'Binded to customer', pId);
	else
	        -- woc and access right history
		save_channel_hist(pId);

		select
			sell_date,
			status_id
		into
			vSellDate,
			vStatus
		from ways_of_connection
		where id = pId;
		
		if vSellDate is null and
			(pSeller is not null or pDistribCenter is not null) then
			vSellDate := SysDate;
		end if; 

		if vStatus = RBA_CONST.USER_CLOSED then
			vStatus := RBA_CONST.USER_ACTIVE;
		end if;

		-- current woc
		update ways_of_connection set
			login = pLogin,
			cdevice_type_id = pCDevType,
			cdevice_serial_number = pCDeviceId,
			status_id = vStatus,
			seller_id = pSeller,
			sell_date = vSellDate,
			sell_place = pDistribCenter,
			change_date = SysDate,
			change_officer_id = bocommon.officerId,
			change_woc_id = null,
			contract_location = decode(pChannel,
				RBA_CONST.DIGI_FIRMA, pLocation,
				RBA_CONST.INET, null),
			location = decode(pChannel,
				RBA_CONST.DIGI_FIRMA, pLocation,
				RBA_CONST.INET, location)
		where id = pId;

		-- customer bind
		select count(1) into vBinded from customer_globus_restrictions
		where woc_id = pId and cusd_id = pCustId;
		if vBinded = 0 then
			bind_to_customer(pId, pCustId);
		end if;

		-- default restricted rights
		select count(1) into vRights from user_document_rights
		where woc_id = pId and customer_id = pCustId and location = pLocation;
		if vRights = 0 then
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
		end if;

		if pChannel = RBA_CONST.DIGI_FIRMA then
			set_web_access(pId, USER_ACCESS_CONNECT, pDFConnectRight);
		end if;
		set_web_access(pId, USER_ACCESS_SPEC_RATE, pSpecRate);
		set_web_access(pId, USER_ACCESS_INFO2BANK, pInfo2Bank);

		bocommon.log_event(pUserId, 60102, '', pId);
	end if;
	--derive_access_rights(pId,pCustId);
end;

procedure bind_to_customer(
	pWocId number,
	pCustId number
) is begin
	insert into customer_globus_restrictions (
		cusd_id,
		change_officer_id,
		change_date,
		woc_id
	) values (
		pCustId,
		bocommon.officerId,
		SysDate,
		pWocId
	);
end;

procedure save_channel_hist(
	pId in number
) is
	-- Var's used for history
	attrs varchar2(200);
	cursor vCurA is select user_access_right from user_access_rights
		where woc_id = pId and user_access_right is not null
		order by user_access_right asc;
	ar int;
begin
	-- Collecting User access rights
	open vCurA;
	fetch vCurA into ar;
	if vCurA%FOUND then attrs := ar; end if;
	fetch vCurA into ar;
	while vCurA%FOUND and Length(attrs) + 4 < 200 Loop
		attrs := attrs||', '||ar;
		fetch vCurA into ar;
	end loop;

	insert into ways_of_connection_history(
		id,
		user_id,
		woc_id,
		channel_id,
		contract_location,
		login,
		status_id,
		expiry_date,
		invalid_attempts_count,
		parent_id,
		cdevice_type_id,
		cdevice_serial_number,
		change_pwd_frequency,
		change_officer_id,
		change_date,
		ib_rights,
		license_id,
		session_timeout,
		language_id,
		mobile_operator,
		charges_account_id,
		seller_id,
		sell_date,
		sell_place
	) select
		unq_woc_hist_id_seq.NextVal,
		user_id,
		id,
		channel_id,
		contract_location,
		login,
		status_id,
		expiry_date,
		invalid_attempts_count,
		parent_id,
		cdevice_type_id,
		cdevice_serial_number,
		change_pwd_frequency,
		change_officer_id,
		change_date,
		attrs,
		license_id,
		session_timeout,
		language_id,
		mobile_operator,
		charges_account_id,
		seller_id,
		sell_date,
		sell_place
	from ways_of_connection
	where id = pId;

	insert into cust_glb_restrictions_hist (
		woc_id,
		cusd_id,
		sign_level,
		sign_level_tmp
	) select 
		unq_woc_hist_id_seq.CurrVal,
		cusd_id,
		sign_level,
		sign_level_tmp
	from customer_globus_restrictions
	where woc_id = pId;

	insert into user_document_rights_hist (
		woc_id,
		customer_id,
		type,
		account,
		ccy,
		right,
		pan,
		--pin_auth_limit,
		--no_pin_auth_limit,
		card_auth_limit,
		failed_auth_limit,
		reversal_limit,
		debit_limit,
		credit_limit,
		serve_balance,
		include_balance,
		location
	) select
		unq_woc_hist_id_seq.CurrVal,
		customer_id,
		type,
		account,
		ccy,
		right,
		pan,
		--pin_auth_limit,
		--no_pin_auth_limit,
		card_auth_limit,
		failed_auth_limit,
		reversal_limit,
		debit_limit,
		credit_limit,
		serve_balance,
		include_balance,
		location
	from user_document_rights
	where woc_id = pId;
end;

procedure activate_licence(
	pId number
) is begin
	if pId is null then return; end if;
	update licenses set
		status = 'A',
		change_officer_id = bocommon.officerId,
		change_date = SysDate
	where id = pId;
end;

procedure activate_agreement(
	pId number
) is begin
	if pId is null then return; end if;
	update ways_of_connection set
		status_id = 1
	where id = pId;
end;

procedure set_web_access(
	pWocId in number,
	pRight in number,
	pOn in number
) is begin
	delete from user_access_rights
	where
		woc_id = pWocId
		and user_access_right = pRight;
	if pOn = 1 then
		insert into user_access_rights (
			woc_id,
			user_access_right,
			change_officer_id,
			change_date
		) 
		values (
			pWocId,
			pRight,
			bocommon.officerId,
			SysDate
		);
	end if;
end;

procedure drop_access(
	pWocId in number,
	pCustId in number,
	pLocation in varchar2
) is
begin
	delete from user_document_rights
	where woc_id = pWocId and
		customer_id = pCustId and
		location = pLocation;
end;

procedure set_access(
	pWocId in number,
	pCustId in number,
	pLocation in varchar2,
	pIban in varchar2,
	pCcy in varchar2,
	pType in int,
	pRight in int
) is begin
	if pRight != 0 then
		insert into user_document_rights (
			woc_id,
			customer_id,
			location,
			account,
			ccy,
			type,
			right,
			change_officer_id,
			change_date
		) values (
			pWocId,
			pCustId,
			pLocation,
			pIban,
			pCcy,
			pType,
			chr(pRight),
			bocommon.officerId,
			SysDate
		);
	end if;
	--derive_access_rights(pWocId,pCustId);
end;

function rem_user(
	pWocId in number,
	pChannelId in number,
	pCustId in number,
	pCertId in varchar2,
	pLocation in varchar2,
	pCount out integer
) return number is
	locCount integer;
	custCount integer;
	certWocCount integer;
begin
	save_channel_hist(pWocId);

	-- DWH journal
	insert into cust_glb_restrictions_journal (
		cusd_id,
		woc_id,
		delete_date
	) select 
		cusd_id,
		woc_id,
		SysDate
	from customer_globus_restrictions
	where cusd_id = pCustId	and woc_id = pWocId;
	--

	select count(1) into custCount
	from customer_globus_restrictions
	where woc_id = pWocId;

	delete from user_document_rights
	where customer_id = pCustId and
		location = pLocation and
		woc_id = pWocId;

	select count(1) into locCount
	from user_document_rights
	where woc_id = pWocId and customer_id = pCustId;

	select count(cdevice_serial_number) into certWocCount
	from ways_of_connection
	where cdevice_serial_number = pCertId and
		id != pWocId;

	update ways_of_connection
	set
		change_date = SysDate,
		change_officer_id = bocommon.officerId,
		change_woc_id = null
	where id = pWocId;

	if locCount = 0 then
		delete from customer_globus_restrictions
		where cusd_id = pCustId and
			woc_id = pWocId;

		if custCount = 1 then
			delete from user_access_rights
			where woc_id = pWocId;

			update ways_of_connection
			set
				status_id = RBA_CONST.USER_CLOSED,
				cdevice_type_id = RBA_CONST.NO_CODING_DEVICE,
				cdevice_serial_number = null
			where id = pWocId;
		end if;
	end if;

	-- Work order: 14,746
	if pChannelId = RBA_CONST.SMS then
		RBA_SMS_CONFIG.UPDATE_ACCOUNT_FLAGS(pCustId);
	end if;

	if pChannelId = RBA_CONST.DIGI_FIRMA then
		select count(1) into pCount
		from ways_of_connection w, user_document_rights u
		where w.channel_id = RBA_CONST.DIGI_FIRMA and
			w.cdevice_serial_number = pCertId and
			u.woc_id = w.id and
			u.customer_id = pCustId;
	else
		pCount := 0;
	end if;

	derive_access_rights(pWocId,pCustId);

	-- The following code is for or not for revoke.
	if locCount > 0 or custCount > 1 or certWocCount > 0 then
		return 0;
	else
		return 1;
	end if;
end;

PROCEDURE derive_access_rights(
 	pi_woc_id              IN    glb_rb_contract.woc_id%TYPE,
        pi_customer_id         IN    glb_rb_contract.cust_id%TYPE
) is begin
	rba_ib_contract.derive_access_rights(pi_woc_id,pi_customer_id);
end;

end;
/

show err;
