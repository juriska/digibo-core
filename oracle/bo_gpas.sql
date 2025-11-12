prompt *** Creating BackOffice Password Generation package ***

create or replace package BOPasGen as
/************************** RBA database stored procedures ********************
 *    $Author: bacerd $
 *   $RCSfile: bo_gpas.sql,v $
 *  $Revision: 1.3 $
 *        $Id: bo_gpas.sql,v 1.3 2004/04/13 08:26:58 bacerd Exp $
 *
 ********* Copyright (c) 2001 Parex Bank, Latvia. All rights reserved *********/

-- 3.1.10

auditLogId audit_log.id%type;
firstEnvelope generated_passwords .nr%type;
lastEnvelope generated_passwords .nr%type;


procedure add_generated_pas(pPas char, pNum out number);

function format_details return audit_log.details%type;

end;
/
show err;

create or replace package body BOPasGen as
procedure add_generated_pas(pPas char, pNum out number) is begin
    select count(nr) into pNum from generated_passwords where text = pPas;
    if 0 != pNum then
        pNum := null;
        return;
    end if;

    insert into generated_passwords(Nr, Text, Status)
    values (Unq_Generated_PWD_Id_Seq.NextVal, pPas, 1)
    return nr into pNum;
    lastEnvelope := pNum;

    if auditLogId is null then
        firstEnvelope := pNum;
        insert into audit_log (id, session_id, event_date, details, event_type_id)
        values (
            unq_audit_log_id_seq.NextVal, 
            unq_session_log_id_seq.CurrVal, 
            SysDate, format_details(), 60401)
        return id into auditLogId;
    else
        update audit_log 
        set event_date = SysDate, details = format_details() 
        where id = auditLogId;
    end if;
end;

function format_details return audit_log.details%type is begin
    return 'Envelope id: ' || firstEnvelope || ' - ' || lastEnvelope;
end;

begin
    auditLogId    := null;
    firstEnvelope := null;
    lastEnvelope  := null;
end;
/
show err;
/
