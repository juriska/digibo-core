CREATE OR REPLACE package body DIGI_FAX.DigiFaxRepl as

procedure replicate_fax as begin
    for r in (select rowid,
                     DIGI_FAX.UNQ_FAX_ID_SEQ.NextVal/*sid + 100000000000000 * to_char(UnixBirth + receive_time / (24*60*60), 'yy')*/ sid,
                     sid original_sid
              from fax_mssql) loop
        begin
            execute immediate
                    'insert into fax (
                        sid, tif,
                        from_fax, from_csid,
                        receive_time, receive_status,
                        status_id
                    )
                    select
                        :1, to_lob(tif),
                        from_fax, from_csid,
                        receive_time, status,
                        :2
                    from fax_mssql
                    where rowid = :3'
            using r.sid, StatusReplicated, r.rowid;

            delete from fax_mssql where rowid = r.rowid;

            rba_log.insert_logs(
                    pi_session_log_id => vSessionId,
                    po_session_log_id => vSessionId,
                    pi_event_type_id  => 24502,
                    pi_payment_id     => r.sid,
                    pi_cur_pmt_sts    => StatusReplicated);
        exception
            when Others then
                rollback;
                rba_log.insert_logs(
                        pi_session_log_id => vSessionId,
                        po_session_log_id => vSessionId,
                        pi_event_type_id  => 24504,
                        pi_payment_id     => r.original_sid,
                        pi_details        => SQLERRM || ' (' || r.original_sid || '/' || r.sid || ')');
        end;
        commit;
    end loop;
end;

procedure submit_job is begin
    dbms_job.submit(vJobId, 'DigiFaxRepl.replicate_fax;', SysDate, 'SysDate + (1 / 288)');
    rba_log.insert_logs(
                pi_session_log_id => vSessionId,
                po_session_log_id => vSessionId,
                pi_event_type_id  => 24501,
                pi_details => 'Job id = ' || vJobId || '. User = ' || user);
    commit;
end;

procedure remove_job is begin
    dbms_job.remove(vJobId);
    rba_log.insert_logs(
                pi_session_log_id => vSessionId,
                po_session_log_id => vSessionId,
                pi_event_type_id  => 24505,
                pi_details => 'Job id = '|| vJobId || '. User = ' || user);
    vJobId     := null;
    commit;
end;

procedure run_job is begin
    dbms_job.run(vJobId);
end;

procedure change_interval(pNewInterval varchar2) is begin
    dbms_job.interval(vJobId, pNewInterval);
    rba_log.insert_logs(
                pi_session_log_id => vSessionId,
                po_session_log_id => vSessionId,
                pi_event_type_id  => 24503,
                pi_details => 'Job id = '|| vJobId || '. User = ' || user
                        || '. New interval = ' || pNewInterval);
    commit;
end;

function get_interval return varchar2 is
    vBuf user_jobs.interval%type;
begin
    select interval into vBuf from user_jobs where job = vJobId;
exception
    when NO_DATA_FOUND then return 'Job does not submited yet.';
end;

begin
    select job into vJobId
    from user_jobs
    where what = 'DigiFaxRepl.replicate_fax;' and rownum = 1;
exception
    when NO_DATA_FOUND then
        vJobId := null;
end;
/
