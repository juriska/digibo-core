CREATE OR REPLACE package body IB.BOGERDEP as

function find_new return cursor_t is
	rv cursor_t;
begin
	open rv for select
		/* BOGERDEP.find_new */
		/*+ INDEX (p IDX_DOC_STATUS_CLASS) */
		d.id "postident",
		d.status_id status_id,
		d.order_date order_date,
        d.from_customer cust_id,
        (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70680) || ' ' ||
        (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70690)  "name",
        (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70750)  "IdDocumentNo",
        (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70905)  "login",
        (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70965)  "amount"
	from documents d
	where rownum <= bocommon.ResultSetSize and
        d.status_id = 13 and
        d.class_id = 1000;
	return rv;
end;
function find_by_filter(
    pDocId in varchar2,
    pCustId in varchar2,
    pCustName in varchar2,
    pIdDocNo in varchar2,
    pLogin in varchar2,
    pStatus in varchar2,
    pOrderDateFrom in date,
    pOrderDateTo in date
) return cursor_t is
    rv cursor_t;
begin

    if pDocId is not null then
         open rv for select
            /* BOGERDEP.find_by_doc_id */
            /*+ INDEX (p PK_DOCUMENT) */
            d.id "postident",
            d.status_id status_id,
            d.order_date order_date,
            d.from_customer cust_id,
            (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70680) || ' ' ||
            (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70690)  "name",
            (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70750)  "IdDocumentNo",
            (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70905)  "login",
            (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70965)  "amount"
        from documents d
        where d.id = pDocId and
            d.class_id = 1000;
        return rv;
    elsif pCustId is not null then
         open rv for select
            /* BOGERDEP.find_by_cust_id */
            /*+ INDEX (p IDX_DOC_CUST_ID_DATE) */
            d.id "postident",
            d.status_id status_id,
            d.order_date order_date,
            d.from_customer cust_id,
            (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70680) || ' ' ||
            (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70690)  "name",
            (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70750)  "IdDocumentNo",
            (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70905)  "login",
            (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70965)  "amount"
        from documents d
        where d.from_customer = pCustId and
            d.class_id = 1000;
        return rv;
    else
        open rv for select
            /* BOGERDEP.find_new */
            /*+ INDEX (p IDX_DOC_STATUS_CLASS) */
            d.id "postident",
            d.status_id status_id,
            d.order_date order_date,
            d.from_customer cust_id,
            (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70680) || ' ' ||
            (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70690)  "name",
            (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70750)  "IdDocumentNo",
            (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70905)  "login",
            (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70965)  "amount"
        from documents d
        where rownum <= bocommon.ResultSetSize and
            d.class_id = 1000
            and (pLogin is null or pLogin = (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70905)) --  "login",
            and (pIdDocNo is null or pIdDocNo = (select additional_info from document_extensions e where e.document_id = d.id and dictionary_id = 70750))
            and (pStatus = 0 or status_id = pStatus)
            --and status_id in '( ' || pStatus || ')'
            and (pCustName is null or upper(d.from_customer) like bocommon.prepare_like(pCustName))
            and (pOrderDateFrom is null or d.order_date between pOrderDateFrom and pOrderDateTo)
            ;
        return rv;   
     end if;
end;
function select_customer(
    pCustId in varchar2,
    pRv out number
) return cursor_t is
    vCustReplicated int := 0;
     rv cursor_t;
--    vResult number := 0;
begin
    pRv := 0;
    --pErrorMessage := '';
    select count(1) into vCustReplicated from ibglb.cusd where id = pCustId;
    if vCustReplicated = 0 then
        bo_repl_link.replicate_customer(pCustId, pRv);
        if pRv = 5 then
            pRv := 0;
        end if;
         -- if 0 = pRv then
         --   select count(1) into vCustReplicated from ibglb.cusd where id = pCustId;
         --end if;
    end if;
    
    open rv for select /* BOGERDEP.select_customer */
        c.id id,
        c.name.name_en name_en,
        c.name.name_lv name_lv,
        c.name.name_ru name_ru,
        c.name.extra_1 name_de,
        c.name.extra_2 name_se,
        c.name.extra_3 name_ee,
        doc_number doc_number,
        c.status status,
        c.posting_restrict posting_restrict
    from cusd c
    where c.id = pCustId and c.is_visible = 1;
    return rv;
   
end;

procedure bind_to_customer(
    pDocId in varchar2,
    pCustId in varchar2
) is
    vCustReplicated int := 0;
    vResult number := 0;
    vPosting_Restrict varchar2(2) := '';
begin
    update documents set from_customer = pCustId, status_id = 16 where id = pDocId;
    
    bocommon.log_event(
                null, --pUserId
                20103, -- Attachment viewed
                null, --pDetails
                null, -- pWocId
                pDocId, --pPayId
                null,
                13, --pPrev audit_log.prev_pmt_status%TYPE,
                16 --pNew audit_log.cur_pmt_status%TYPE
            );
            --bocommon.log_event(user_id, pMessageId, itc, woc_id, pId, null, previous, pNewStatus);
end;
procedure account_exists(
    pDocId in varchar2,
    pAccExists out varchar2
) is
begin
    select count(1)
    into pAccExists
    from documents d,
            acsd a
    where d.id = pDocId and
            d.from_customer = a.customer_id and
            a.is_visible != 0;
end;
procedure create_user(
    pDocId in varchar2,
    pTanCardId in varchar2
) is
begin
    insert into users (
            id,
            special_question,
            answer,
            change_officer_id,
            change_date,
            reg_date,
            customer_id,
            migrstatus
        ) values (
            unq_user_id_seq.NextVal,
            (select additional_info from document_extensions e where e.document_id = pDocId and dictionary_id = 70910), --upper(pSpecQ),
            (select additional_info from document_extensions e where e.document_id = pDocId and dictionary_id = 70920), --upper(pAnswer),
            bocommon.officerId,
            SysDate,
            SysDate,
            (select from_customer from documents where id = pDocId), --pCustomerId,
            1 --pMigrStatus
        );
        
        insert into ways_of_connection (
            id,
            channel_id,
            license_id,
            user_id,

            contract_location,
            location,

            login,
            password,
            change_pwd_frequency,
            session_timeout,
            cdevice_type_id,
            cdevice_serial_number,


            status_id,
            invalid_attempts_count,
            expiry_date,
            change_date,
            change_officer_id,

            language_id
        ) values (
            unq_woc_id_seq.NextVal,
            RBA_CONST.INET,
            null, --pLicense,
            unq_user_id_seq.CurrVal, --pUserId,

            null, -- decode(pChannel,
                --RBA_CONST.DIGI_FIRMA, pLocation,
                --RBA_CONST.INET, null),
            null, --decode(pChannel,
                --RBA_CONST.DIGI_FIRMA, pLocation,
                --RBA_CONST.INET, null),

            (select additional_info from document_extensions e where e.document_id = pDocId and dictionary_id = 70905), --pLogin,
            (select additional_info from document_extensions e where e.document_id = pDocId and dictionary_id = 70930),
            RBA_CONST.CHANGE_PWD_FREQUENCY,
            USER_SESSION_TIMEOUT,
            2, --pCDevType,
            pTanCardId, --pCDeviceId,


            RBA_CONST.USER_ACTIVE,
            RBA_CONST.INV_ATMPTS_COUNT,
            SysDate - 1,
            SysDate,
            bocommon.officerId,
            3 -- language_id
        );
        
        insert into customer_globus_restrictions (
        cusd_id,
        change_officer_id,
        change_date,
        woc_id
    ) values (
        (select from_customer from documents where id = pDocId),
        bocommon.officerId,
        SysDate,
        unq_woc_id_seq.CurrVal
    );
    
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
            unq_woc_id_seq.CurrVal,
            (select from_customer from documents where id = pDocId),
            'LV', --pLocation,
            null, --pIban,
            null, --pCcy,
            1, --pType,
            'F', --chr(pRight),
            bocommon.officerId,
            SysDate
        );
    
    update documents set creator_user_id = unq_user_id_seq.CurrVal,
                                    creator_woc_id = unq_woc_id_seq.CurrVal, 
                                    creator_channel_id = RBA_CONST.INET, 
                                    status_id = 1 where id = pDocId;
    
    bocommon.log_event(
                null, --pUserId
                20103, -- Attachment viewed
                null, --pDetails
                null, -- pWocId
                pDocId, --pPayId
                null,
                16, --pPrev audit_log.prev_pmt_status%TYPE,
                1 --pNew audit_log.cur_pmt_status%TYPE
            );
           
end;
procedure reject(
    pDocId in varchar2,
    pReason in varchar2
) is
begin
    update documents set status_id = 3 where id = pDocId and status_id != 1;
    bocommon.log_event(
                null, --pUserId
                20103, -- Attachment viewed
                pReason, --null, --pDetails
                null, -- pWocId
                pDocId, --pPayId
                null,
                13, --pPrev audit_log.prev_pmt_status%TYPE,
                3 --pNew audit_log.cur_pmt_status%TYPE
            );
end;

end;
/
