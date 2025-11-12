CREATE OR REPLACE package body IB.BOSMSAgreement as

function get_operators return cursor_t is
	rv cursor_t;
begin
	open rv for select m.id id, m.code code, m.phone_format frmt
	from mobile_operators m
	where is_visible = 1;
	return rv;
end;

function get_accounts(
	pCustId in varchar2,
	pLocation in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select id, iban, ccy
	from acsd
	where customer_id = pCustId and
		is_visible = 1 and
		close_date is null and
		location = pLocation and
		iban is not null and
		ccy <> 'LVL' and
		(post_restr IS NULL or post_restr = '');
	return rv;
end;

function get_logins(
	pUserId in number,
    pCustId in number,
	pLocation in varchar2
) return cursor_t is
	rv cursor_t;
begin

    open rv for select /*+INDEX(r IDX_WOC_USER) USE_NL(wa a) USE_NL(w wa)*/
        distinct
        w.login login,
        w.status_id statusId,
        w.id wocId
    from ways_of_connection w,
        --v$customer_globus_restrictions cgr,
        v$woc_accounts_viewable wa,
        acsd a
    where
        a.customer_id = pCustId and
        wa.account_id = a.id and
        a.location = pLocation and
        w.id = wa.woc_id and
        w.channel_id = RBA_CONST.INET and
        (w.status_id = RBA_CONST.USER_ACTIVE or w.status_id = RBA_CONST.USER_INACTIVE) and
        ( w.user_id = pUserId or
            w.user_id in (   select distinct u2.id
                                    from users u1,
                                            users u2
                                    where
                                            u1.id = pUserId and
                                            u1.migrstatus = 1 and
                                            u2.migrstatus = 1 and
                                            u1.customer_id = u2.customer_id
                              )
        )   ;

	return rv;
end;

function load_rights_1(
	pWocId in number,
	pCustId in number,
	pLocation in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for
    select
        '-' iban,
        '-' ccy,
        null isLimits,
        null debitLimit,
        null creditLimit,
        null serveBal,
        null includeBal
        , 11 docType
    from user_document_rights
    where woc_id = pWocId     
          and type = 11
    union
    select
        iban iban,
        ccy ccy,
        null isLimits,
        null debitLimit,
        null creditLimit,
        null serveBal,
        null includeBal
        , 14 docType
    from acsd
    where customer_id = pCustId and
        is_visible = 1 and
        close_date is null and
        location = pLocation and
        iban is not null   
    order by docType   
    ;
	return rv;
end;

function load_rights_2(
	pWocId in number,
	pCustId in number,
	pLocation in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		nvl( account, '-') iban,
		nvl( ccy, '-') ccy,
		nvl(debit_limit || credit_limit || serve_balance || include_balance, null) isLimits,
		debit_limit debitLimit,
		credit_limit creditLimit,
		serve_balance serveBal,
		include_balance includeBal
        , type docType
	from user_document_rights
	where woc_id = pWocId and
		customer_id = pCustId and
		location = pLocation and
		type in ( DOC_RIGHTS_CURRENCY_LEVEL, DOC_RIGHTS_ALL_ACCOUNTS_LEVEL)
        order by type;
	return rv;
end;

function load_card_rights(
	pWocId in number,
	pCustId in number,
	pLocation in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select pan, acc, ccy, isLimits,
		--pinAuthLimit, noPinAuthLimit,
        cardAuthLimit, 
        failedAuthLimit, reversalLimit,
		serveBal, includeBal
	from (select
			pan pan,
			iban acc,
			ccy,
			null isLimits,
			--null pinAuthLimit,
			--null noPinAuthLimit,
            null cardAuthLimit,
			null failedAuthLimit,
			null reversalLimit,
			null serveBal,
			null includeBal
		from acsd a, card_cards c, card_statcodes cs
		where a.customer_id = pCustId and
			a.is_visible = 1 and
			a.location = pLocation and
			c.account_id = a.id and
			c.is_visible = 1 and
			cs.id = c.statcode
            --and c.calc_show_before > sysdate
			--cs.card_visible = 1
		union
		select
			pan pan,
			account acc,
			ccy,
			nvl(/*pin_auth_limit || no_pin_auth_limit*/ card_auth_limit || failed_auth_limit || reversal_limit || serve_balance || include_balance, null) isLimits,
			--pin_auth_limit pinAuthLimit,
			--no_pin_auth_limit noPinAuthLimit,
            card_auth_limit cardAuthLimit,
			failed_auth_limit failedAuthLimit,
			reversal_limit reversalLimit,
			serve_balance serveBal,
			include_balance includeBal
		from user_document_rights
		where woc_id = pWocId and
			customer_id = pCustId and
			location = pLocation and
			type = DOC_RIGHTS_CARD
	)
	order by pan desc;
	return rv;
end;

procedure load_channel(
	pWocId in varchar2,
	pLogin out varchar2,
	pOperator out number,
	pChargesAcc out number,
	pParentId out varchar2,
	pLanguage out number,
	pSellerId out number,
	pDistribCenterId out number,
	pFfSMS out integer
    , pPassword out varchar2
    , pHasDefault out integer
    , pSmsTime out varchar2
) is begin
	select
		w.login,
		w.mobile_operator,
		w.charges_account_id,
		w.parent_id,
		w.language_id,
		w.seller_id,
		w.sell_place,
		w.accept_freeformat_sms
        , decode( w.channel_id, 6, w.password, '')
        , (select count(1) from user_document_rights r where r.woc_id = w.id and r.type = 11)
        --, 1
        , w.sms_time
	into
		pLogin,
		pOperator,
		pChargesAcc,
		pParentId,
		pLanguage,
		pSellerId,
		pDistribCenterId,
		pFfSMS
        , pPassword
        , pHasDefault
        , pSmsTime
	from
		ways_of_connection w
	where
		w.id = pWocId;
        
        if pHasDefault is null then
           pHasDefault := 0;
        end if;
        
end;

function check_login(
	pLogin in varchar2
) return number is
	rv number;
    vMultipleCustomers varchar2(20);
begin
    select attribute_value into vMultipleCustomers from IB.MGMT_VALUES where attribute_id = 'FeaturesConfig.smsMultipleCustomersPerNumberEnabled';
    if upper(vMultipleCustomers) <> 'FALSE' then
       return 0;
    end if;
	select count(1) into rv
	from ways_of_connection
	where upper(login) = upper(pLogin)
		and channel_id = RBA_CONST.SMS
		and status_id != RBA_CONST.USER_CLOSED;
	return rv;
end;

function get_login_count(
    pLogin in varchar2
) return number is
    rv number;
begin
    select count(1) into rv
    from ways_of_connection
    where upper(login) = upper(pLogin)
        and channel_id = RBA_CONST.SMS
        and status_id != RBA_CONST.USER_CLOSED;
    return rv;
end;

function login_for_customer_exists(
    pWocId in number,
    pCustId in number,
    pLocation in varchar2,
    pLogin in varchar2
) return number is
    rv number;
begin

    if pWocId is null then
    
        select count(1) into rv
        from ways_of_connection w
                , user_document_rights r
        where upper(w.login) = upper(pLogin)
            and w.channel_id = RBA_CONST.SMS
            and w.status_id != RBA_CONST.USER_CLOSED
            and r.woc_id = w.id
            and r.customer_id = pCustId
            and r.location = pLocation
            --and r.right in ('F', 'V', 'D')
            ;
        else
            select count(1) into rv
            from ways_of_connection w
                    , user_document_rights r
            where upper(w.login) = upper(pLogin)
                and w.channel_id = RBA_CONST.SMS
                and w.status_id != RBA_CONST.USER_CLOSED
                and r.woc_id = w.id
                and r.customer_id = pCustId
                and r.location = pLocation
                --and r.right in ('F', 'V', 'D')
                and w.id != pWocId
                ;
        end if;
        
    return rv;
end;

end;
/
