CREATE OR REPLACE PACKAGE IB.BOMessageWA as

Success  constant int := 0;
LockedBy constant int := 1; -- see OfficerName and OfficerPhone;
Locked   constant int := 2; -- non BO lock;
Error    constant int := 3;

type cursor_t is ref cursor;

function set_lock(
    pLockName in varchar2,
    pId in out varchar2,
    pOfficerName out varchar2,
    pOfficerPhone out varchar2
) return int;

function get_message_types return cursor_t;

procedure load_customer(
    pCustId in varchar2,
    pCustName out varchar2,
    pCustLegalId out varchar2
);

function load_accounts(
    pTypeId in varchar2,
    pCustId in varchar2
) return cursor_t;
function load_sent_msg_users(
    pMsgId in number
) return cursor_t;
function load_users(
    pTypeId in varchar2,
    pUserRights in varchar2,
    pCustId in varchar2,
    pAccountId in number
) return cursor_t;

procedure save_message(
    pMsgId in number,
    pNewMsgId out number,
    pMsgTypeId in varchar2,
    pCustomerId in varchar2,
    pAccountId in number,
    pBody in varchar2,
    pFileName in varchar2,
    pFileData in blob
);
procedure save_msg_woc(
    pMsgId in number,
    pWocId in number
);

function load_message(
    pMsgId in number,
    pStatusId out number,
    pAuthorId out number,
    pMsgTypeId out varchar2,
    pCustomerId out varchar2,
    pAccountId out number,
    pBody out varchar2,
    pFileName out varchar2,
    pFileData out blob
) return cursor_t;

function get_drafts return cursor_t;
function get_rejected return cursor_t;

function get_waiting_for_approve return cursor_t;
function find (
    pOfficerId in number,
    pDeptClassId in number,
    pCustomerId in varchar2,
    pStatuses in varchar2,
    --pStatusDraft in number,
    --pStatusWaitingFA in number,
    --pStatusSent in number,
    pDateFrom in date,
    pDateTo in date
) return cursor_t;
procedure send_to_approve(
    pMsgId in number
);
procedure approve(
    pMsgId in number
);
procedure reject(
    pMsgId in number
);
procedure attachment_viewed(
    --pFileId in number
    pMsgId in number
);

function get_history(
    pMsgId in number
) return cursor_t;
procedure load_file(
    pFileId in varchar2,
    pFileName out varchar2,
    pFileData out blob,
    pMsgId out number
);
end;
/


CREATE OR REPLACE PACKAGE BODY IB.BOMessageWA as

function set_lock(
    pLockName in varchar2,
    pId in out varchar2,
    pOfficerName out varchar2,
    pOfficerPhone out varchar2
) return int is
    vHandle varchar2(128);
    vRes int;
begin
    dbms_lock.allocate_unique(pLockName, vHandle);
    vRes := dbms_lock.request(lockhandle => vHandle, timeout => 0, release_on_commit => true);
    if vRes = 0 then
        begin
            if pId is not null then
                select id into pId
                from messageswa
                where id = pId for update nowait;
                return Success;
            else
                return Success;
            end if;
            exception when bocommon.RESOURCE_BUSY_NOWAIT then
            vRes := dbms_lock.release(lockhandle => vHandle);
            vRes := 1;
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

function get_message_types return cursor_t is
    rv cursor_t;
    vIsPersonalOfficer integer := 0;
    vIsPamDept integer := 0;
    vIsBrokerDept integer := 0;
    vIsMarginDept integer := 0;
    vIsMortgageDept integer := 0;
    vIsLeasingDept integer := 0;
    --vIsOtcSwapsDept boolean integer := 0;
begin
    if dbms_session.is_role_enabled('RBOTELLER') then
        vIsPersonalOfficer := 1;
    end if;
    if dbms_session.is_role_enabled('RBOPAM') then
        vIsPamDept := 1;
    end if;
    if dbms_session.is_role_enabled('RBOBROKER') then
        vIsBrokerDept := 1;
    end if;
    if dbms_session.is_role_enabled('RBODEALERT') then
        vIsMarginDept := 1;
    end if;
    if dbms_session.is_role_enabled('RBOMORTGLOANS') then
        vIsMortgageDept := 1;
    end if;
    if dbms_session.is_role_enabled('RBO_LEASE_APPLIC_EDIT') then
        vIsLeasingDept := 1;
    end if;
    
    open rv for select
        id msgTypeId,
         nvl(trim(decode(bocommon.LanguageId,
            0, t.name.name_lv,
            1, t.name.name_en,
            2, t.name.name_ru,
            3, t.name.extra_1,
            4, t.name.extra_2,
            5, t.name.extra_3,
            t.name.name_en
        )), t.name.name_en) msgTypeName,
        t.file_type file_type,
        t.user_rights user_rights
        from downloadable_report_type t
        where   ( department_class_id = rba_const.msg_personal_officer AND vIsPersonalOfficer = 1 ) OR
                    ( department_class_id = rba_const.msg_pam_department AND vIsPamDept = 1 ) OR
                    ( department_class_id = rba_const.msg_broker_department AND vIsBrokerDept = 1 ) OR
                    ( department_class_id = rba_const.msg_margin_department AND vIsMarginDept = 1 ) OR
                    ( department_class_id = rba_const.msg_mortgage_department AND vIsMortgageDept = 1 )OR
                    ( department_class_id = rba_const.MSG_CITADELE_LEASING_NUMBER AND vIsLeasingDept = 1 );
                    
    return rv;
end;

procedure load_customer(
    pCustId in varchar2,
    pCustName out varchar2,
    pCustLegalId out varchar2
) is
vCustFound integer := 0;
begin
  select count(id) into vCustFound from cusd c where c.id = pCustId;

  if vCustFound > 0 then
    select
        nvl(trim(decode(bocommon.LanguageId,
            0, c.name.name_lv,
            1, c.name.name_en,
            2, c.name.name_ru,
            3, c.name.extra_1,
            4, c.name.extra_2,
            5, c.name.extra_3,
            c.name.name_en
        )), c.name.name_en) custName,
        c.legal_id custLegalId
    into    pCustName,
            pCustLegalId
    from cusd c
    where c.id = pCustId;
  else
   select NULL, NULL into pCustName, pCustLegalId from dual;
  end if;

end;


function load_accounts(
    pTypeId in varchar2,
    pCustId in varchar2
) return cursor_t is
    rv cursor_t;
begin
    open rv for select
        a.id accId,
        a.iban accNum,
        a.ccy ccy,
        nvl(trim(decode(bocommon.LanguageId,
            0, categ.name.name_lv,
            1, categ.name.name_en,
            2, categ.name.name_ru,
            3, categ.name.extra_1,
            4, categ.name.extra_2,
            5, categ.name.extra_3,
            categ.name.name_en
        )), categ.name.name_en) categoryName
    from cusd c,
            acsd a,
            glb_categories categ,
   	    downloadable_report_type d
    where   c.id = pCustId and
                d.id = pTypeId and
                d.location = a.location and
                a.customer_id = c.id and
                --a.location = 'LV' and -- This must be fixed
                a.location = (select d.location from downloadable_report_type d where d.id = pTypeId) AND
                a.is_visible =1 and
                a.iban is not null and
                a.close_date is null and
                a.category=categ.id;
    return rv;
end;
function load_sent_msg_users(
    pMsgId in number
) return cursor_t is
rv cursor_t;
begin
    open rv for select
         mwa_woc.woc_id wocId,
         u.name userName,
         u.personal_id userPersonalId,
         u.passport_no userPassportNo,
         u.issuer_country_id passportIssuerCountry,
		 woc.login userLogin,
         m.status_id read_status
    from   messageswa mwa,
               messageswa_woc mwa_woc,
               ways_of_connection woc,
               v$users u,
               messages m
    where   mwa.id = pMsgId and
                mwa_woc.messagewa_id = mwa.id and
                woc.id = mwa_woc.woc_id and
                u.id = woc.user_id and
                m.id = mwa_woc.message_id;
    return rv;
end;
function load_users(
    pTypeId in varchar2,
    pUserRights in varchar2,
    pCustId in varchar2,
    pAccountId in number
) return cursor_t is
    rv cursor_t;
    vAccNum user_document_rights.account%TYPE;
    vAccCcy user_document_rights.ccy%TYPE;
begin
    if (  pUserRights = 'FULL_ON_CUSTOMER') then
        open rv for select distinct
             --udr.woc_id wocId,
             woc.id wocId,
             usr.name userName,
             usr.personal_id userPersonalId,
             usr.passport_no userPassportNo,
             usr.issuer_country_id passportIssuerCountry,
			 woc.login userLogin,
             1 read_status
        from    -- user_document_rights udr,
                v$woc_customers_full r,
                ways_of_connection woc,
                v$users usr,
                downloadable_report_type drt
        where
                --udr.CUSTOMER_ID = pCustId AND
                r.customer_id = pCustId AND
                --udr.woc_id = woc.id AND
                r.woc_id = woc.id AND
                usr.id = woc.user_id AND
                woc.channel_id = 5 AND
                woc.status_id = 1 AND
                --udr.location = 'LV' and
                drt.id = pTypeId and
                --drt.location = udr.location and
                drt.location = r.location
                --udr.TYPE = 1 AND
                --udr.RIGHT = 'F'
                ;
    end if;
    if (  pUserRights = 'ANY_RIGH') then
        open rv for select distinct
             --udr.woc_id wocId,
             woc.id wocId,
             usr.name userName,
             usr.personal_id userPersonalId,
             usr.passport_no userPassportNo,
             usr.issuer_country_id passportIssuerCountry,
			 woc.login userLogin,
             1 read_status
        from     --user_document_rights udr,
                v$woc_customers_rel r,
                ways_of_connection woc,
                v$users usr,
                downloadable_report_type drt
        where   --udr.CUSTOMER_ID = pCustId AND
                r.customer_id = pCustId AND
                --udr.woc_id = woc.id AND
                r.woc_id =  woc.id AND
                usr.id = woc.user_id AND
                woc.channel_id = 5 AND
                woc.status_id = 1 AND
                drt.id = pTypeId and
                --drt.location = udr.location and
                drt.location = r.location --and
                --udr.RIGHT in ('F', 'V')
                ;
    end if;
    if (  pUserRights = 'FULL_ON_ACCOUNT') then

        select iban, ccy into vAccNum, vAccCcy from acsd where id = pAccountId;

        open rv for select distinct
             --udr.woc_id wocId,
             woc.id wocId,
             usr.name userName,
             usr.personal_id userPersonalId,
             usr.passport_no userPassportNo,
             usr.issuer_country_id passportIssuerCountry,
			 woc.login userLogin,
             1 read_status
        from    
            -- user_document_rights udr,
            v$woc_accounts_full r,
            ways_of_connection woc,
            v$users usr,
            downloadable_report_type drt
where   --udr.CUSTOMER_ID = pCustId AND
                --udr.woc_id = woc.id AND
                r.woc_id = woc.id AND
                usr.id = woc.user_id AND
                woc.channel_id = 5 AND
                woc.status_id = 1 AND
                drt.id = pTypeId and
                r.account_id = pAccountId
                /*
                drt.location = udr.location and
            (
                   exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 14 and account = vAccNum and ccy=vAccCcy and right = 'F') OR
                (
                    exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 13 and account = vAccNum and right = 'F') AND
                    not exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 14 and account = vAccNum and ccy=vAccCcy)
                ) OR
                (
                    exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 11 and right = 'F') AND
                    not exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 14 and account = vAccNum and ccy=vAccCcy) AND
                    not exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 13 and account = vAccNum)
                ) OR
                 (
                    exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 1 and right = 'F') AND
                    not exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 14 and account = vAccNum and ccy=vAccCcy) AND
                    not exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 13 and account = vAccNum) AND
                    not exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 11)
                )
           ) */
           ;
    end if;
    if (  pUserRights = 'VIEW_ON_ACCOUNT') then

        select iban, ccy into vAccNum, vAccCcy from acsd where id = pAccountId;

        open rv for select distinct
             --udr.woc_id wocId,
             woc.id wocId,
             usr.name userName,
             usr.personal_id userPersonalId,
             usr.passport_no userPassportNo,
             usr.issuer_country_id passportIssuerCountry,
			 woc.login userLogin,
             1 read_status
        from     --user_document_rights udr,
            v$woc_accounts_viewable r,
            ways_of_connection woc,
            v$users usr,
            downloadable_report_type drt
where   --udr.CUSTOMER_ID = pCustId AND
                --udr.woc_id = woc.id AND
                r.woc_id = woc.id AND
                usr.id = woc.user_id AND
                woc.channel_id = 5 AND
                woc.status_id = 1 AND
                drt.id = pTypeId and
                r.account_id = pAccountId
                /*
                drt.location = udr.location and
            (
                   exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 14 and account = vAccNum and ccy=vAccCcy and right in ( 'F', 'V')) OR
                (
                    exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 13 and account = vAccNum and right  in ( 'F', 'V')) AND
                    not exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 14 and account = vAccNum and ccy=vAccCcy)
                ) OR
                (
                    exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 11 and right in ( 'F', 'V')) AND
                    not exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 14 and account = vAccNum and ccy=vAccCcy) AND
                    not exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 13 and account = vAccNum)
                ) OR
                 (
                    exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 1 and right  in ( 'F', 'V')) AND
                    not exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 14 and account = vAccNum and ccy=vAccCcy) AND
                    not exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 13 and account = vAccNum) AND
                    not exists (select 1 from user_document_rights where customer_id = udr.customer_id and woc_id = udr.woc_id and type = 11)
                )
           ) */
           ;
    end if;
    return rv;
end;

procedure save_message(
    pMsgId in number,
    pNewMsgId out number,
    pMsgTypeId in varchar2,
    pCustomerId in varchar2,
    pAccountId in number,
    pBody in varchar2,
    pFileName in varchar2,
    pFileData in blob
) is
vAccountId acsd.id%TYPE;
begin

    if pAccountId = 0 then -- empty accountId is passed as 0, but we must write null in DB
        vAccountId := null;
    else
        vAccountId := pAccountId;
    end if;

    if  pMsgId > 0 then -- existing message
        update messageswa set
            MESSAGE_TYPE_ID =   pMsgTypeId,
            CUSTOMER_ID = pCustomerId,
            ACCOUNT_ID = vAccountId,
            BODY = pBody,
            FILE_NAME = pFileName,
            FILE_DATA = pFileData,
            REJECTED = 0
        where id = pMsgId;

         bocommon.log_event(
                null,
                60506, -- Message with attachement updated
                null,
                null,
                pMsgId,
                null,
                null,
                null
            );

        delete from messageswa_woc where messagewa_id = pMsgId;
    else
        --select IB.UNQ_MESSAGEWA_ID_SEQ.NextVal into pNewMsgId from dual;
        select IB.UNQ_PAYMENT_ID_SEQ.NextVal into pNewMsgId from dual;

        insert into messageswa (
        ID,
        MESSAGE_TYPE_ID,
        STATUS_ID,
        CREATE_DATE,
        AUTHOR,
        APPROVER,
        CUSTOMER_ID,
        ACCOUNT_ID,
        BODY,
        FILE_NAME,
        FILE_DATA
        )
        values (
        pNewMsgId,
        pMsgTypeId,
        1,
        sysdate,
        bocommon.get_logged_officer,
        null,
        pCustomerId,
        vAccountId,
        pBody,
        pFileName,
        pFileData
        );

         bocommon.log_event(
                null,
                60505, -- Message with attachement created
                null,
                null,
                pNewMsgId,
                null,
                null,
                null
            );
    end if;


end;

procedure save_msg_woc(
    pMsgId in number,
    pWocId in number
)is
begin
    insert into messageswa_woc (
        messagewa_id,
        woc_id
        )
     values (
        pMsgId,
        pWocId
        );
end;


function load_message(
    pMsgId in number,
    pStatusId out number,
    pAuthorId out number,
    pMsgTypeId out varchar2,
    pCustomerId out varchar2,
    pAccountId out number,
    pBody out varchar2,
    pFileName out varchar2,
    pFileData out blob
) return cursor_t is
    rv cursor_t;
    vFileId downloadable_report.id%TYPE;
begin
    select status_id,
            author,
            message_type_id,
            customer_id,
            account_id,
            body,
            file_name,
            file_data,
            downloadable_report_id
    into   pStatusId,
            pAuthorId,
            pMsgTypeId,
            pCustomerId,
            pAccountId,
            pBody,
            pFileName,
            pFileData,
            vFileId
    from messageswa
    where id = pMsgId;

    open rv for select  woc_id wocId
    from    messageswa_woc
    where   MESSAGEWA_ID = pMsgId;

    if ( vFileId is not null ) then

            select report_file into pFileData from downloadable_report where id = vFileId;

    end if;
    return rv;
end;

function get_drafts return cursor_t is
    rv cursor_t;

begin

open rv for select
        m.ID msgId,
       nvl(trim(decode(bocommon.LanguageId,
                    0, t.name.name_lv,
                    1, t.name.name_en,
                    2, t.name.name_ru,
                    3, t.name.extra_1,
                    4, t.name.extra_2,
                    5, t.name.extra_3,
                    t.name.name_en
                )), t.name.name_en)
         msgTypeName,
        t.department_class_id deptClassId,
        status_id statusId,
        CREATE_DATE createDate,
        (select name from officers where id = author) author,
        (select name from officers where id = approver) approver,
        CUSTOMER_ID customerId,
        nvl(rejected, 0) rejected
    from messageswa m, downloadable_report_type t
    where   m.message_type_id = t.id and
                m.status_id = 1 and  -- draft
                m.author = bocommon.get_logged_officer
                ;

    return rv;
end;

function get_rejected return cursor_t is
    rv cursor_t;

begin

open rv for select
        m.ID msgId,
       nvl(trim(decode(bocommon.LanguageId,
                    0, t.name.name_lv,
                    1, t.name.name_en,
                    2, t.name.name_ru,
                    3, t.name.extra_1,
                    4, t.name.extra_2,
                    5, t.name.extra_3,
                    t.name.name_en
                )), t.name.name_en)
         msgTypeName,
        t.department_class_id deptClassId,
        status_id statusId,
        CREATE_DATE createDate,
        (select name from officers where id = author) author,
        (select name from officers where id = approver) approver,
        CUSTOMER_ID customerId,
        nvl(rejected, 0) rejected
    from messageswa m, downloadable_report_type t
    where   m.message_type_id = t.id and
                m.status_id = 1 and  -- draft
                m.author = bocommon.get_logged_officer and
                rejected = 1;
    return rv;
end;

function get_waiting_for_approve return cursor_t is
    rv cursor_t;
    vIsPersonalOfficer integer := 0;
    vIsPamDept integer := 0;
    vIsBrokerDept integer := 0;
    vIsMarginDept integer := 0;
    vIsMortgageDept integer := 0;
    vIsLeasingDept integer := 0;
begin

    if dbms_session.is_role_enabled('RBOTELLER') then
        vIsPersonalOfficer := 1;
    end if;
    if dbms_session.is_role_enabled('RBOPAM') then
        vIsPamDept := 1;
    end if;
    if dbms_session.is_role_enabled('RBOBROKER') then
        vIsBrokerDept := 1;
    end if;
    if dbms_session.is_role_enabled('RBODEALERT') then
        vIsMarginDept := 1;
    end if;
    if dbms_session.is_role_enabled('RBOMORTGLOANS') then
        vIsMortgageDept := 1;
    end if;
    if dbms_session.is_role_enabled('RBO_LEASE_APPLIC_EDIT') then
        vIsLeasingDept := 1;
    end if;

open rv for select
        m.ID msgId,
       nvl(trim(decode(bocommon.LanguageId,
                    0, t.name.name_lv,
                    1, t.name.name_en,
                    2, t.name.name_ru,
                    3, t.name.extra_1,
                    4, t.name.extra_2,
                    5, t.name.extra_3,
                    t.name.name_en
                )), t.name.name_en)
         msgTypeName,
        t.department_class_id deptClassId,
        status_id statusId,
        CREATE_DATE createDate,
        (select name from officers where id = author) author,
        (select name from officers where id = approver) approver,
        CUSTOMER_ID customerId,
        nvl(rejected, 0) rejected
    from messageswa m, downloadable_report_type t
    where   m.message_type_id = t.id and
                m.status_id = 2 and  -- waiting for approve
                (vIsPersonalOfficer = 1 or t.department_class_id != rba_const.msg_personal_officer) and
                (vIsPamDept = 1 or t.department_class_id != rba_const.msg_pam_department) and
                (vIsBrokerDept = 1 or t.department_class_id != rba_const.msg_broker_department) and
                (vIsMarginDept = 1 or t.department_class_id != rba_const.msg_margin_department) and
                (vIsMortgageDept = 1 or t.department_class_id != rba_const.msg_mortgage_department)and
                (vIsLeasingDept = 1 or t.department_class_id != rba_const.MSG_CITADELE_LEASING_NUMBER)
                ;
    return rv;
end;
function find (
    pOfficerId in number,
    pDeptClassId in number,
    pCustomerId in varchar2,
    pStatuses in varchar2,
    --pStatusDraft in number,
    --pStatusWaitingFA in number,
    --pStatusSent in number,
    pDateFrom in date,
    pDateTo in date
) return cursor_t is
    rv cursor_t;
    vIsPersonalOfficer integer := 0;
    vIsPamDept integer := 0;
    vIsBrokerDept integer := 0;
    vIsMarginDept integer := 0;
    vIsMortgageDept integer := 0;
    vIsLeasingDept integer := 0;
    t_statuses num_table_type := bocommon.str2table(pStatuses);
begin

    if dbms_session.is_role_enabled('RBOTELLER') then
        vIsPersonalOfficer := 1;
    end if;
    if dbms_session.is_role_enabled('RBOPAM') then
        vIsPamDept := 1;
    end if;
    if dbms_session.is_role_enabled('RBOBROKER') then
        vIsBrokerDept := 1;
    end if;
    if dbms_session.is_role_enabled('RBODEALERT') then
        vIsMarginDept := 1;
    end if;
    if dbms_session.is_role_enabled('RBOMORTGLOANS') then
        vIsMortgageDept := 1;
    end if;
    if dbms_session.is_role_enabled('RBO_LEASE_APPLIC_EDIT') then
        vIsLeasingDept := 1;
    end if;

 open rv for select
        m.ID msgId,
       nvl(trim(decode(bocommon.LanguageId,
                    0, t.name.name_lv,
                    1, t.name.name_en,
                    2, t.name.name_ru,
                    3, t.name.extra_1,
                    4, t.name.extra_2,
                    5, t.name.extra_3,
                    t.name.name_en
                )), t.name.name_en)
         msgTypeName,
        t.department_class_id deptClassId,
        status_id statusId,
        CREATE_DATE createDate,
        (select name from officers where id = author) author,
        (select name from officers where id = approver) approver,
        CUSTOMER_ID customerId,
        nvl(rejected, 0) rejected
    from messageswa m, downloadable_report_type t
    where   m.message_type_id = t.id and
                (pOfficerId is null or pOfficerId = 0 or m.author = pOfficerId or m.approver = pOfficerId) and
                (pDeptClassId is null or pDeptClassId = 0 or t.department_class_id = pDeptClassId) and
                (pCustomerId is null or pCustomerId = '' or customer_id = pCustomerId) and
                (create_date >= pDateFrom) and
                (create_date <= pDateTo) and
                (pStatuses is null or status_id in (select * from table(cast(t_statuses as num_table_type)))) and
                ( status_id != 1 or m.author = bocommon.get_logged_officer ) and -- shows only my drafts
                (vIsPersonalOfficer = 1 or t.department_class_id != rba_const.msg_personal_officer) and
                (vIsPamDept = 1 or t.department_class_id != rba_const.msg_pam_department) and
                (vIsBrokerDept = 1 or t.department_class_id != rba_const.msg_broker_department) and
                (vIsMarginDept = 1 or t.department_class_id != rba_const.msg_margin_department) and
                (vIsMortgageDept = 1 or t.department_class_id != rba_const.msg_mortgage_department)and
                (vIsLeasingDept = 1 or t.department_class_id != rba_const.MSG_CITADELE_LEASING_NUMBER)
                ;
    return rv;
end;
procedure send_to_approve(
    pMsgId in number
)is
begin
    update messageswa
    set status_id = 2
    where id = pMsgId;

     bocommon.log_event(
                null,
                60507, -- Message with attachement approved
                null,
                null,
                pMsgId,
                null,
                null,
                null
            );
end;
procedure approve(
    pMsgId in number
)is
    dReportId number(12);
    vWoc_Id ways_of_connection.id%TYPE;
    vNewMsgId messages.id%TYPE;
    cursor vCurWoc is select woc_id from messageswa_woc
        where messagewa_id = pMsgId;
begin

    select (CAST (To_CHAR(sysdate, 'YYYY') AS NUMBER))*100000000 + ibglb.unq_report_id_seq.NEXTVAL into dReportId from dual;

    insert into downloadable_report
        (id,
        cust_id,
        report_date,
        report_file,
        location,
        type,
        account_id,
        filename )
    (select
        dReportId,
        customer_id,
        trunc( sysdate, 'DD'),
        file_data,
        (select location from downloadable_report_type where id = message_type_id),
        message_type_id,
        account_id,
        file_name
    from messageswa
    where id = pMsgId);

    update messageswa
    set status_id = 3,
        file_data = null,
        downloadable_report_id = dReportId,
        approver = bocommon.get_logged_officer
    where id = pMsgId;

    -- foe each WOC creating new message and updating messagewa_woc with newly created message id
    open vCurWoc;
    fetch vCurWoc into vWoc_Id;
    while vCurWoc%FOUND Loop

        select  unq_message_id_seq.NextVal into vNewMsgId from dual;

        insert into messages (
            id,
            create_date,
            officer_id,
            body,
            status_id,
            class_id,
            woc_id,
            question_id,
            type,
            downloadable_report_id
        ) ( select
            vNewMsgId,
            SysDate,
            mwa.author,
            mwa.body,
            RBA_CONST.MSG_NEW,
            (select department_class_id from ibglb.downloadable_report_type where id = mwa.message_type_id),
            vWoc_Id,
            null,
            'A',
            dReportId
        from messageswa mwa
        where mwa.id = pMsgId
        );

        update messageswa_woc
        set message_id = vNewMsgId
        where messagewa_id = pMsgId and
            woc_id = vWoc_Id;

        -- log event for new nessage
        bocommon.log_event(
            null,
            60502, -- EVENT CREATED
            'Recipients WOC_ID = ' || vWoc_Id,
            vWoc_Id,
            null,
            vNewMsgId,
            null,
            null
        );

        fetch vCurWoc into vWoc_Id;
    end loop;


    -- log event for message with attachement status change
     bocommon.log_event(
                null,
                60508, -- Message with attachement approved
                null,
                null,
                pMsgId,
                null,
                null,
                null
            );
end;
procedure reject(
    pMsgId in number
)is
begin
    update messageswa
    set status_id = 1, rejected = 1
    where id = pMsgId;

     bocommon.log_event(
                null,
                60509, -- Rejected
                null,
                null,
                pMsgId,
                null,
                null,
                null
            );
end;
procedure attachment_viewed(
    pMsgId in number
)is
begin

     bocommon.log_event(
                null,
                60510, -- Attachment viewed
                null,
                null,
                pMsgId, -- (select id from messagewa where downloadable_report_file_id = pFileId), -- null, --pMsgId,
                null,
                null,
                null
            );
end;

function get_history(
    pMsgId in number
) return cursor_t is
    rv cursor_t;
begin
     open rv for select
                a.event_type_id event_id,
                a.event_date event_date,
                o.name officer_name,
                nvl(trim(decode(bocommon.LanguageId,
                    0, et.name.name_lv,
                    1, et.name.name_en,
                    2, et.name.name_ru,
                    3, et.name.extra_1,
                    4, et.name.extra_2,
                    5, et.name.extra_3,
                    et.name.name_en
                )), et.name.name_en) event_name,
                a.details details
    from audit_log a,
           session_log s,
           officers o,
           event_types et
    where   a.session_id = s.id and
            o.id = s.user_id and
            et.id = a.event_type_id and
            a.payment_id = pMsgId;
    return rv;
end;

procedure load_file(
    pFileId in varchar2,
    pFileName out varchar2,
    pFileData out blob,
    pMsgId out number
) is
    --pMsgId number(9);
    vDeptClassId ibglb.downloadable_report_type.department_class_id%TYPE;
begin

    select  r.report_file,
             r.filename,
             t.department_class_id
    into    pFileData,
             pFileName,
             vDeptClassId
    from ibglb.downloadable_report r,
            ibglb.downloadable_report_type t
    where   r.id = pFileId and
                r.type = t.id;

    if dbms_session.is_role_enabled('RBOMESSAGEATTACHMENTS') and
        (
           (vDeptClassId = 400 and dbms_session.is_role_enabled('RBOTELLER')) or
           (vDeptClassId = 401 and dbms_session.is_role_enabled('RBOPAM')) or
           (vDeptClassId = 402 and dbms_session.is_role_enabled('RBOBROKER')) or
           (vDeptClassId = 403 and dbms_session.is_role_enabled('RBODEALER')) or
           (vDeptClassId = 404 and dbms_session.is_role_enabled('RBOMORTGLOANS'))or
           (vDeptClassId = 407 and dbms_session.is_role_enabled('RBO_LEASE_APPLIC_EDIT')) or
	   (vDeptClassId = 408 and dbms_session.is_role_enabled('RBOTELLER'))
       ) then

            select id
            into pMsgId
            from messageswa
            where downloadable_report_id = pFileId;

            /*
             bocommon.log_event(
                        null,
                        60510, -- Attachment viewed
                        null,
                        null,
                        pMsgId,
                        null,
                        null,
                        null
                    );*/
    else
        pFileData := null;
        pFileName := null;
        pMsgId := null;
    end if;

end;

end;
/
