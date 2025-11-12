CREATE OR REPLACE package body IB.BODocuments as

function history(pId in varchar2) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		al.id,
		al.event_type_id,
		al.event_date timestamp,
		al.cur_pmt_status status,
		o.name officer,
		al.details details
	from audit_log al, session_log sl, officers o
	where
		payment_id = pId and cur_pmt_status != RBA_CONST.DRAFT and
		al.session_id = sl.id and
		o.id(+) = sl.user_id;
	return rv;
end;

function messageHistory(pId in varchar2) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		al.id,
		al.event_type_id,
		al.event_date timestamp,
		al.cur_pmt_status status,
		al.details details
	from audit_log al
	where message_id = pId;
	return rv;
end;

function set_lock(
	pId in varchar2,
	pStatus out integer,
	pOfficerName out varchar2,
	pOfficerPhone out varchar2
) return integer is
	vHandle varchar2(128);
	vRes int;
begin
	dbms_lock.allocate_unique('documents.id=' || pId, vHandle);
	vRes := dbms_lock.request(lockhandle => vHandle, timeout => 0, release_on_commit => true);
	if vRes = 0 then
	begin
		select status_id into pStatus from documents
		where id = pId for update nowait;
		return 0;
	exception when bocommon.RESOURCE_BUSY_NOWAIT then
		vRes := dbms_lock.release(lockhandle => vHandle);
		vRes := 1;
	end;
	end if;
	if vRes = 1 then
		bocommon.get_locker(vHandle, pOfficerName, pOfficerPhone);
	end if;
	return 1;
end;

procedure signOwner(
	certId in varchar2,
	signDate in date,
	uName out varchar2,
	legalId out varchar2
) is
	vDate date;
	vUserId users.id%type := null;
begin
	begin
		select change_date, user_id into vDate, vUserId
		from ways_of_connection
		where cdevice_serial_number = replace(certId, '_') and rownum = 1;
	exception when no_data_found then
		null;
	end;
	if vUserId is null or vDate > signDate then
		begin
			select user_id into vUserId
			from ways_of_connection_history
			where id = (select max(id) from ways_of_connection_history
				where cdevice_serial_number = replace(certId, '_') and
					change_date < signDate);
		exception when no_data_found then
			null;
		end;
	end if;
	begin
		select name, personal_id, change_date into uName, legalId, vDate
		from v$users where id = vUserId;
	exception when no_data_found then
		null;
	end;
	if uName is null or vDate > signDate then
		begin
			select name, personal_id into uName, legalId
			from user_history
			where id = (select max(id) from user_history
				where user_id = vUserId and change_date < signDate);
		exception when no_data_found then
			null;
		end;
	end if;
exception when no_data_found then
	null;
end;

procedure set_manual_status(
	pId in varchar2,
	reason in varchar2,
	pNewStatus in integer,
	pMessageId in integer
    --, pBankRefference in varchar2
) is
	user_id documents.creator_user_id%type := null;
	woc_id documents.creator_woc_id%type := null;
	previous documents.status_id%type := null;
	itc documents.info_to_customer%type := null;
begin
	select creator_user_id, creator_woc_id, status_id, info_to_customer
	into user_id, woc_id, previous, itc
	from documents where id = pId;
	update documents
	set
		status_id = pNewStatus,
		info_to_customer = reason,
		last_update_date = sysdate
	where id = pId;
	bocommon.log_event(user_id, pMessageId, itc, woc_id, pId, null, previous, pNewStatus);
end;

procedure set_manual_status_1(
    pId in varchar2,
    reason in varchar2,
    pNewStatus in integer,
    pMessageId in integer
    , pBankRefference in varchar2
) is
    user_id documents.creator_user_id%type := null;
    woc_id documents.creator_woc_id%type := null;
    previous documents.status_id%type := null;
    itc documents.info_to_customer%type := null;
begin
    select creator_user_id, creator_woc_id, status_id, info_to_customer
    into user_id, woc_id, previous, itc
    from documents where id = pId;
    update documents
    set
        status_id = pNewStatus,
        info_to_customer = reason,
        last_update_date = sysdate
        , bank_reference = pBankRefference
    where id = pId;
    bocommon.log_event(user_id, pMessageId, itc, woc_id, pId, null, previous, pNewStatus);
end;
function get_addr(pId in varchar2) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		type_id,
		receiving_type,
		bank_office_name,
		addr_zip || ', ' || addr_country || ', ' ||
		addr_city || ', ' || addr_street || ', ' ||
		addr_house || ', ' || addr_apart addr
	from document_addresses
	where document_id = pId;
	return rv;
end;

function get_extensions(pId in varchar2) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		dictionary_id,
		additional_info,
		block_number
	from document_extensions
	where document_id = pId
	order by dictionary_id;
	return rv;
end;

/*
procedure get_officers(officers_id out num_table_type) is
	replaced cursor_t;
	r integer;
begin
	officers_id := num_table_type();
	open replaced for select r.officer_id id from officer_replacement r
		where r.replaced_by = bocommon.officerId;
	fetch replaced into r;
	while replaced%found loop
		officers_id.extend;
		officers_id(officers_id.count) := r;
		fetch replaced into r;
	end loop;
	close replaced;
end;
*/

function get_remote_officer(officer_id in integer) return integer is
	dept_id officers.dept_accnt_officer_id%type := 0;
begin
	if nvl(officer_id, 0) = 0 then
		return 0;
	end if;
	select dept_accnt_officer_id into dept_id from officers where id = officer_id;
	if nvl(dept_id, 0) = 0 then
		return -1;
	end if;
	return dept_id;
exception when others then return -1;
end;

procedure get_remote_officers(dept_id out num_table_type) is
	my_dept_id officers.dept_accnt_officer_id%type;
	c cursor_t;
	r integer;
begin
	dept_id := num_table_type();
	select dept_accnt_officer_id into my_dept_id from officers where id = bocommon.officerId;
	open c for select gd.id from ibglb.glb_dept_accnt_officer gd
		start with gd.id = my_dept_id or
			gd.id in (
			select o.dept_accnt_officer_id from officer_replacement r, officers o
				where r.replaced_by = bocommon.officerId and
					r.officer_id = o.id
		)
		connect by prior gd.parent_accnt_officer = gd.id;
	fetch c into r;
	while c%found loop
		dept_id.extend;
		dept_id(dept_id.count) := r;
		fetch c into r;
	end loop;
	close c;
end;

function get_ib_signatures(pDocId in varchar2) return cursor_t is
    rv cursor_t;
begin
    open rv for select
        u.name name,
        r.document_signature_rel_type signature_action,
        s.signature_level signature_level,
        s.signature_date signature_date,
        s.signature_cdevice_type_id signature_cdevice_type_id,
        s.signature_cdevice_serial signature_cdevice_serial,
        S.DOCUMENT_BATCH_ID DOCUMENT_BATCH_ID
    from document_signature_rel r,
            document_signatures s,
            ways_of_connection w,
            v$users u
    where r.document_id = pDocId and
            s.id = r.signature_id and
            w.id = r.change_woc_id and
            u.id = w.user_id
    order by s.id;
/*
    open rv for select
        u.name name,
        s.signature_action signature_action,
        s.signature_level signature_level,
        s.signature_date signature_date
    from document_signatures s,
            ways_of_connection w,
            v$users u
    where s.document_id = pDocId and
            w.id = s.signer_woc_id and
            u.id = w.user_id
    order by s.id;
    */
    return rv;
end;

function set_ManualProcessing(pId in varchar2) return integer is
    vRes int;
begin
    vRes := 0;
    
    update documents
    set change_officer_id = bocommon.officerId
    where id = pId
        and status_id in (RBA_CONST.SIGNATURE_OK, RBA_CONST.CONFIRM_OK, RBA_CONST.MANUAL_PROCESSING_STARTED, RBA_CONST.PARTLY_SUCCEED)
    returning change_officer_id into vRes;

    if vRes > 0 then
        bodocuments.set_manual_status(pId, null, RBA_CONST.MANUAL_PROCESSING_STARTED, 24403);
        --bodocuments.set_manual_status(pId, null, RBA_CONST.MANUAL_PROCESSING_STARTED, 24403, null);
    else
        vRes := 0;
    end if;

    return vRes;
end;

function getChangeOfficerId(pId in varchar2) return integer is
    vRes int;
    vDocStatus int;
begin
    vRes := 0;
    
    select change_officer_id, status_id into vRes, vDocStatus from documents where id = pId;
    
    if vDocStatus in (RBA_CONST.SIGNATURE_OK, RBA_CONST.CONFIRM_OK) then
        vRes := 0;
    end if;

    return vRes;
end;
function get_by_id(
    pId in number,
    pStatus out integer,
    pOfficerID out number,
    pITC out varchar2
) return integer is
begin
  select status_id, change_officer_id, info_to_customer into pStatus, pOfficerID, pITC from documents where id = pId;
  return 1;
end;  

end;
/
