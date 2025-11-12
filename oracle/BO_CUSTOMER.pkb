CREATE OR REPLACE package body IB.BOCustomer as

function customer_exists(
	pId in varchar2
) return number is
	rv number;
begin
	select count(1) into rv
	from acsd
	where customer_id = pId;
	return rv;
end;

function load_user_channels(
	pId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select distinct
		w.id wocId,
		w.channel_id channelId,
		w.license_id licenseId,
		c.id custId,
		nvl(trim(decode(bocommon.LanguageId,
			0, c.name.name_lv,
			1, c.name.name_en,
			2, c.name.name_ru,
			3, c.name.extra_1,
			4, c.name.extra_2,
			5, c.name.extra_3,
			c.name.name_en
		)), c.name.name_en) custName,
		w.login login,
		w.status_id status,
		nvl(w.substatus_id, 0) substatus,
		w.cdevice_type_id cDevType,
        w.cdevice_type_id_2 cDevType_2,
		--w.cdevice_serial_number cDevNum,
        w.cdevice_serial_number || decode( w.cdevice_serial_number_2, null, '', ', ' ||  w.cdevice_serial_number_2) cDevNum,
		c.is_visible custVisible,
		w.contract_location location
	from ways_of_connection w, v$customer_globus_restrictions cgr, cusd c
	where w.user_id = pId and
		w.channel_id in (RBA_CONST.INET, RBA_CONST.DIGI_FIRMA, RBA_CONST.SMS, RBA_CONST.GATE) and
		cgr.woc_id(+) = w.id and
		c.id(+) = cgr.cusd_id;
	return rv;
end;

procedure load_user(
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
	pCustomerId out number,
	pMigrStatus out number,
	pHasAgreementInGlobus out number
) is begin

    
	select  count(1)
	into	pHasAgreementInGlobus
	from    ways_of_connection w,
        	glb_rb_contract gc
	where	w.user_id = pId and
        	gc.woc_id = w.id 
            --and gc.is_visible = 1
            ;

    if pHasAgreementInGlobus = 0 then
        select  count(1)
        into    pHasAgreementInGlobus
        from    ways_of_connection w,
                ways_of_connection_external we
        where    w.user_id = pId and
                we.woc_id = w.id and
                we.link_type = 3;
    end if;
    
	select
		u.name,
		u.issuer_country_id,
		u.personal_id,
		u.passport_no,
		u.street,
		u.city,
		u.country_id,
		u.zip_code,
		u.phone,
		u.mobile_phone,
		u.fax,
		u.email,
		u.apart,
		u.house,

		nvl(u.standard_question_id, 0),
		u.special_question,
		u.answer,

		u.reg_date,
		u.change_date,
		u.change_officer_id,
		w.login,
    u.customer_id,
    u.MIGRSTATUS
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
    pCustomerId,
    pMigrStatus
	from
		v$users u,
		ways_of_connection w
	where
		u.change_woc_id = w.id(+)
		and u.id = pId;

	exception when no_data_found then
		pId := null;


end;

procedure load_user_old(
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
  pCustomerId out number,
  pMigrStatus out number
) is begin
	select
		u.name,
		u.issuer_country_id,
		u.personal_id,
		u.passport_no,
		u.street,
		u.city,
		u.country_id,
		u.zip_code,
		u.phone,
		u.mobile_phone,
		u.fax,
		u.email,
		u.apart,
		u.house,

		nvl(u.standard_question_id, 0),
		u.special_question,
		u.answer,

		u.reg_date,
		u.change_date,
		u.change_officer_id,
		w.login,
    u.CUSTOMER_ID,
    u.MIGRSTATUS
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
    pCustomerId,
    pMigrStatus
	from
		users u,
		ways_of_connection w
	where
		u.change_woc_id = w.id(+)
		and u.id = pId;

	exception when no_data_found then
		pId := null;
end;


function load_user_info(
	pId in number
) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		u.change_date changeDate,
		u.change_officer_id changeOfficerId,
		w.login changeLogin,
		u.name userName,
		u.passport_no passportNo,
		u.issuer_country_id issuerCountry,
		u.personal_id personalId,
		u.phone phone,
		u.mobile_phone mobile,
		u.fax fax,
		u.email email,
		u.apart apartment,
		u.house house,
		u.street street,
		u.zip_code zip,
		u.country_id country,
        DECODE (u.MIGRSTATUS, 1, u.customer_id, NULL) customer_id   
	from
		v$users u,
		ways_of_connection w
	where
		u.id = pId
		and w.id(+) = u.change_woc_id;
	return rv;
end;

function load_user_history(
	pId in number
) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		u.change_date changeDate,
		u.change_officer_id changeOfficerId,
		w.login changeLogin,
		DECODE (u.MIGRSTATUS, 1, c.NAME.name_en, u.name) userName,
		DECODE (u.MIGRSTATUS, 1, c.LEGAL_ID, u.PASSPORT_NO) passportNo,
		DECODE (u.MIGRSTATUS, 1, c.COUNTRY, u.ISSUER_COUNTRY_ID) issuerCountry,
		DECODE (u.MIGRSTATUS, 1, c.LEGAL_ID, u.PERSONAL_ID) personalId,
		DECODE (u.MIGRSTATUS, 1, NULL, u.PHONE) phone,
		DECODE (u.MIGRSTATUS, 1, NULL, u.MOBILE_PHONE) mobile,
		DECODE (u.MIGRSTATUS, 1, NULL, u.FAX) fax,
		 DECODE (u.MIGRSTATUS, 1, NULL, u.EMAIL) email,
		DECODE (u.MIGRSTATUS, 1, NULL, u.APART) apartment,
		DECODE (u.MIGRSTATUS, 1, NULL, u.HOUSE) house,
		DECODE (u.MIGRSTATUS, 1, c.ADDR_STR.NAME_EN, u.STREET) street,
		DECODE (u.MIGRSTATUS, 1, c.ZIP_CODE, u.ZIP_CODE) zip,
		DECODE (u.MIGRSTATUS, 1, c.ADDRESS_COUNTRY, u.COUNTRY_ID) country,
        DECODE (u.MIGRSTATUS, 1, u.customer_id, NULL) customer_id   
	from
		user_history u,
		ways_of_connection w,
        ibglb.cusd c
	where
		u.user_id = pId
		and w.id(+) = u.change_woc_id
        and u.customer_id = c.id(+);
	return rv;
end;

function load_customer_tree(
	pCustId in varchar2,
	pLocation in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select iban iban, ccy ccy, id id
	from acsd
	where customer_id = pCustId and
		is_visible = 1 and
		close_date is null and
		iban is not null and
		location = pLocation;
	return rv;
end;

function load_licenses(
	pCustId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select distinct w.license_id licenseId, udr.location location
	from customer_globus_restrictions cgr,
		ways_of_connection w,
		user_document_rights udr
	where cgr.cusd_id = pCustId and
		w.id = cgr.woc_id and
		w.channel_id = RBA_CONST.DIGI_FIRMA and
		w.license_id is not null and
		udr.woc_id(+) = w.id and
		udr.customer_id(+) = pCustId;
	return rv;
end;

function load_users(
	pCustId in varchar2,
	pChannel in number,
	pLicense in varchar2,
	pLocation in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		/*+ INDEX (cgr PK_CGR_CUSD_ID) INDEX (w PK_WAYS_OF_CONNECTION) */
		/*+ INDEX (u PK_USER) INDEX (w IDX_WOC_USER) */
		u.id userId,
		u.name userName,
		u.personal_id personalId,
		u.country_id country,
		w.id wocId,
		w.login login,
		w.status_id status,
		decode(w.cdevice_type_id, 3, w.cdevice_serial_number, null) certId,
		cgr.sign_level signLevel,
		cgr.sign_level_tmp signLevelTmp,
		w.user_agent agent,
		( select
			(select count(1) from glb_rb_contract gc where gc.cust_id = cgr.cusd_id and gc.woc_id = w.id and gc.location = pLocation /*and gc.is_visible = 1*/)
			--+ (select count(1) from ways_of_connection_external we where we.woc_id = w.id and we.link_type = 3) -- tihis is commented since there were case when one of agreements was not impoted in GLOBUS. In the migration day would be good uncomment this
			from dual ) is_agreement_in_globus,
		w.language_id languageId
	from v$customer_globus_restrictions cgr,
		ways_of_connection w,
		v$users u
	where cgr.cusd_id = pCustId and
		w.id = cgr.woc_id and
		w.channel_id = pChannel and
		(pLicense is null or w.license_id = pLicense) and
		((w.channel_id = RBA_CONST.SMS and w.contract_location = pLocation and w.status_id <> 3) or
		(w.channel_id in (RBA_CONST.INET, RBA_CONST.DIGI_FIRMA) and
            (
            exists (
			select 1
			from user_document_rights udr
			where udr.woc_id = w.id	and
				udr.customer_id = pCustId and
				udr.location = pLocation)
            or
            exists (
            select 1 from glb_rb_contract gc2 where gc2.cust_id = cgr.cusd_id and gc2.woc_id = w.id and gc2.is_visible = 1 and gc2.location = pLocation
            )
            )
        )) and
		u.id(+) = w.user_id;
	return rv;
end;


function check_license(
	pId in varchar2
) return number is
	rv number;
begin
	select count(1) into rv from licenses l
	where l.id = pId and l.status != 'G';
	if 0 != rv then
		return 0;
	end if;
	return 2; -- not found ready for use id.
end;

function check_login(
	pUserId in number,
	pLogin in varchar2,
	pLicense in varchar2,
	pChannelId in number
) return number is
	rv number;
begin
	-- user available woc list:
	select count(1) into rv
	from ways_of_connection
	where
		user_id = pUserId
		and (channel_id = RBA_CONST.INET
			or (channel_id = RBA_CONST.DIGI_FIRMA and license_id = pLicense)
		)
		and login = pLogin;

	-- login check:
	if rv = 0 then
		select count(1) into rv
		from ways_of_connection
		where upper(login) = upper(pLogin) and user_id != pUserId;
		if rv = 0 and pChannelId = RBA_CONST.INET then
			select count(1) into rv
			from reserved_login
			where upper(login) = upper(pLogin) and
				sysdate < expiry_date;
		end if;
	else
		rv := 0; -- login is OK
	end if;
	return rv;
end;

function check_pswd_num(
	pPswdNum in varchar2
) return number is
	rv number;
begin
	select count(1) into rv
	from generated_passwords
	where
		nr = pPswdNum
		and status = RBA_CONST.PWD_GENERATED;
	return rv;
end;


function check_sign_level(
	pCustId number,
	pWocId number,
	pCertId varchar2,
	pLevel varchar2
) return number is
	rv number;
begin
	select count(id) into rv
	from ways_of_connection w, customer_globus_restrictions cgr
	where
		w.id = cgr.woc_id
		and cgr.cusd_id = pCustId
		and w.cdevice_serial_number = pCertId
		and w.id != pWocId
		and cgr.sign_level != pLevel;
	return rv;
end;

procedure load_channel(
	pWocId in varchar2,
	pCustId in varchar2,
	pCDevType out number,
	pCDevNum out varchar2,
	pSellerId out number,
	pDistribCenterId out number,
	pLevel out number,
	pTmpLevel out number,
	pChangeOfficer out varchar2,
	pSpecRate out number,
	pInfo2Bank out number,
	pDFAccessRight out number
    
) is begin
	select
		w.cdevice_type_id,
		w.cdevice_serial_number,
		w.seller_id,
		w.sell_place
        
	into
		pCDevType,
		pCDevNum,
		pSellerId,
		pDistribCenterId
        
	from
		ways_of_connection w
	where
		w.id = pWocId;

	begin
		select
			cgr.sign_level,
			cgr.sign_level_tmp,
			cgr.change_officer_id
		into
			pLevel,
			pTmpLevel,
			pChangeOfficer
		from customer_globus_restrictions cgr
		where cgr.woc_id = pWocId and cgr.cusd_id = pCustId;
	exception when no_data_found then
		pLevel := null;
	end;

	select count(1) into pSpecRate
	from user_access_rights u
	where u.woc_id = pWocId	and u.user_access_right = USER_ACCESS_SPEC_RATE;

	select count(1) into pInfo2Bank
	from user_access_rights u
	where u.woc_id = pWocId and u.user_access_right = USER_ACCESS_INFO2BANK;

	select count(1) into pDFAccessRight
	from user_access_rights u
	where u.woc_id = pWocId and u.user_access_right = USER_ACCESS_CONNECT;
end;

function load_user_wocs(
	pUserId in number,
	pLicense in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select * from (select
		distinct login,
		status_id statusId,
		channel_id channelId,
		id wocId
	from ways_of_connection w
	where w.user_id = pUserId and
		(w.channel_id = RBA_CONST.INET or
		(w.channel_id = RBA_CONST.DIGI_FIRMA and w.license_id = pLicense))
	) order by channelId desc;
	return rv;
end;

function load_rights(
	pWocId in number,
	pCustId in number,
	pLocation in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select iban, ccy, type, ascii(right) right, close_date
	from (
		select /*+ INDEX (a ACSD_I_CUSTOMER_ID_ID) */
			a.iban iban,
			a.ccy ccy,
			14 type,
			null right,
			a.close_date close_date
		from acsd a
		where a.customer_id = pCustId and
			a.is_visible = 1 and
			a.iban is not null and
			a.location = pLocation
		union
		select
			u.account iban,
			u.ccy ccy,
			u.type type,
			u.right right,
			null close_date
		from user_document_rights u
		where u.woc_id = pWocId and
			u.customer_id = pCustId and
			u.location = pLocation and (
			u.type not in (13, 14) or
			(u.type = 13 and exists (select 1 from acsd a where a.iban = u.account and a.is_visible = 1 and a.location = pLocation)) or
			(u.type = 14 and exists (select 1 from acsd a where a.iban = u.account and a.ccy = u.ccy and a.is_visible = 1 and a.location = pLocation))
		)
	)
	order by type, iban, right desc;
	return rv;
end;

function load_binded_customers(
	pWocId in number,
	pCustId in number,
	pLocation in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select distinct
		nvl(trim(decode(bocommon.LanguageId,
			0, c.name.name_lv,
			1, c.name.name_en,
			2, c.name.name_ru,
			3, c.name.extra_1,
			4, c.name.extra_2,
			5, c.name.extra_3,
			c.name.name_en
		)), c.name.name_en) custName
	from v$customer_globus_restrictions cgr,
		cusd c,
		acsd a
	where cgr.woc_id = pWocId and
		cgr.cusd_id != pCustId and
		c.id = cgr.cusd_id and
		c.is_visible = 1 and
		a.customer_id = c.id and
		a.location = pLocation;
	return rv;
end;

procedure fill_full_history(
	pId in number,
	pChannel in number
) is begin
	-- Actual data
	insert into tmp_customer_history (
		change_date,
		change_officer,
		change_woc_id,
		woc_id,
		hist_id,
		login,
		license,
		status_id,
		cust_id,
		user_name
	) select
		/*+ INDEX (cgr PK_CUSTOMER_GLOBUS_RESTRICTION ) INDEX (w PK_WAYS_OF_CONNECTION) */
		w.change_date,
		nvl(o.name, o.login),
		w.change_woc_id,
		w.id,
		null,
		w.login,
		w.license_id,
		w.status_id,
		cgr.cusd_id,
		u.name
	from
		customer_globus_restrictions cgr,
		ways_of_connection w,
		v$users u,
		officers o
	where
		w.channel_id = pChannel
		and cgr.woc_id(+) = w.id and cgr.cusd_id(+) = pId
		and w.id in ( -- Determines: was this WOC binded to this customer or did not
			select wocId from (
				select
				/*+ INDEX (ch IDX_CGRH_CUSD) INDEX (wh PK_WAY_OF_CONN_HIST) */
				distinct wh.woc_id wocId
				from ways_of_connection_history wh, cust_glb_restrictions_hist ch
				where wh.id = ch.woc_id and ch.cusd_id = pId
			union
			select
				distinct cg.woc_id wocId
				from customer_globus_restrictions cg
				where cg.cusd_id = pId
			)
		)
		and w.user_id = u.id
		and o.id(+) = w.change_officer_id;

	-- History data
	insert into tmp_customer_history (
		change_date,
		change_officer,
		change_woc_id,
		woc_id,
		hist_id,
		login,
		license,
		status_id,
		cust_id,
		user_name
	) select
		/*+ INDEX (cgr IDX_CGRH_WOC_CUSD ) INDEX (w PK_WAY_OF_CONN_HIST) */
		w.change_date,
		nvl(o.name, o.login),
		w.change_woc_id,
		w.woc_id,
		w.id,
		w.login,
		w.license_id,
		w.status_id,
		cgr.cusd_id,
		u.name
	from
		cust_glb_restrictions_hist cgr,
		ways_of_connection_history w,
		v$users u,
		officers o
	where
		w.channel_id = pChannel
		and cgr.woc_id(+) = w.id and (cgr.cusd_id(+) = pId)
		and w.woc_id in ( -- Determines: was this WOC binded to this customer or did not
			select
			/*+ INDEX (ch IDX_CGRH_CUSD) INDEX (wh PK_WAY_OF_CONN_HIST) */
			distinct wh.woc_id
			from ways_of_connection_history wh, cust_glb_restrictions_hist ch
		 	where wh.id = ch.woc_id and ch.cusd_id = pId
		)
		and w.user_id = u.id
		and o.id(+) = w.change_officer_id;
end;

function load_full_history return cursor_t is
	rv cursor_t;
	t_date ways_of_connection.change_date%type;
	t_hist ways_of_connection.id%type;
	t_woc ways_of_connection.id%type;
	t_id1 ways_of_connection.id%type;

	cursor full_hist is select
		change_date,
		change_officer,
		woc_id,
		hist_id,
		cust_id
	from
		tmp_customer_history
	order by woc_id, change_date;
begin
	t_date := SYSDATE - 10000;--null;
	t_woc := null;
	t_hist := null;
	t_id1 := 0;

	-- Removing history records after latest unbind
	-- which relates on other customers:
	for rec in full_hist loop
		if rec.cust_id is null then
			/*if rec.woc_id <> t_id1 then
				if rec.cust_id is null then
					-- delete all "fake" unbinds
					delete from tmp_customer_history
					where woc_id = rec.woc_id and hist_id = rec.hist_id;
				else
					t_id1 := rec.woc_id;
				end if;
			els*/if rec.woc_id = t_woc and rec.change_date > t_date then
				delete from tmp_customer_history
				where change_date = rec.change_date
					and woc_id = rec.woc_id
					and (hist_id is null or hist_id = rec.hist_id);
			else
				t_date := rec.change_date;
				t_woc := rec.woc_id;
				t_hist := rec.hist_id;
			end if;
		else
			t_date := SYSDATE-10000;
			t_woc := null;
			t_hist := null;
		end if;
	end loop;

	-- Resulting data fetch:
	open rv for select
		h.change_date changeDate,
		h.change_officer changeOfficer,
		h.woc_id wocId,
		h.hist_id id,
		h.login,
		h.license,
		h.status_id status,
		h.cust_id custId,
		h.user_name userName,
		decode(w.id, null, '', '(' || w.id || ') ' || w.login) changeWoc
	from tmp_customer_history h, ways_of_connection w
	where w.id(+) = h.change_woc_id
	order by h.woc_id, h.change_date;

	return rv;
end;

procedure load_channel_info(
	pId in number, -- woc ID
	pCustId in number,
	pLicense out varchar2,
	pLogin out varchar2,
	pUserName out varchar2,
	pPersonalId out varchar2,
	pCountry out varchar2,
	pCDevType out number,
	pCDevNum out varchar2,
	pIbRights out varchar2,
	pStatus out number,
	pSignLevel out number,
	pSignLevelTmp out number,
	pDocRights out cursor_t
) is
	ibr cursor_t;
	rightId user_access_rights.user_access_right%type;
begin
	-- Woc
	select
		w.license_id,
		w.login,
		u.name,
		u.personal_id,
		u.country_id,
		w.cdevice_type_id,
		w.cdevice_serial_number,
		w.status_id
	into
		pLicense,
		pLogin,
		pUserName,
		pPersonalId,
		pCountry,
		pCDevType,
		pCDevNum,
		pStatus
	from
		ways_of_connection w,
		v$users u
	where
		w.id = pId
		and w.user_id = u.id;

	-- Sign Level
	select
		sign_level, sign_level_tmp
	into
		pSignLevel, pSignLevelTmp
	from customer_globus_restrictions
	where cusd_id = pCustId and woc_id = pId;

	-- Document rights
	open pDocRights for select
		account acc,
		ccy,
		type,
		right,
		debit_limit,
		credit_limit,
		pan,
		--pin_auth_limit,
		--no_pin_auth_limit,
        card_auth_limit,
		failed_auth_limit,
		reversal_limit,
		serve_balance,
		include_balance,
		location
	from
		user_document_rights
	where
		woc_id = pId
		and customer_id = pCustId;

	-- Access rights
	open ibr for select user_access_right rightId
	from user_access_rights
	where woc_id = pId;

	fetch ibr into rightId;
	while ibr%found loop
		pIbRights := pIbRights || ', ' || rightId;
		fetch ibr into rightId;
	end loop;
end;

procedure load_channel_history(
	pId in number, -- woc history ID
	pCustId in number,
	pLicense out varchar2,
	pLogin out varchar2,
	pUserName out varchar2,
	pPersonalId out varchar2,
	pCountry out varchar2,
	pCDevType out number,
	pCDevNum out varchar2,
	pIbRights out varchar2,
	pStatus out number,
	pSignLevel out number,
	pSignLevelTmp out number,
	pDocRights out cursor_t
) is begin
	-- Woc
	select
		w.license_id,
		w.login,
		u.name,
		u.personal_id,
		u.country_id,
		w.cdevice_type_id,
		w.cdevice_serial_number,
		w.ib_rights,
		w.status_id
	into
		pLicense,
		pLogin,
		pUserName,
		pPersonalId,
		pCountry,
		pCDevType,
		pCDevNum,
		pIbRights,
		pStatus
	from
		ways_of_connection_history w,
		v$users u
	where
		w.id = pId
		and w.user_id = u.id;

	-- Sign Level
	select
		sign_level, sign_level_tmp
	into
		pSignLevel, pSignLevelTmp
	from cust_glb_restrictions_hist
	where cusd_id = pCustId and woc_id = pId;

	-- Document rights
	open pDocRights for select
		account acc,
		ccy,
		type,
		right,
		debit_limit,
		credit_limit,
		pan,
		--pin_auth_limit,
		--no_pin_auth_limit,
        card_auth_limit,
		failed_auth_limit,
		reversal_limit,
		serve_balance,
		include_balance,
		location
	from
		user_document_rights_hist
	where
		woc_id = pId
		and customer_id = pCustId;
end;

end;
/
