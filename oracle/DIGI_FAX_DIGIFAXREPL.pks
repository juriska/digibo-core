CREATE OR REPLACE package DIGI_FAX.DigiFaxRepl as

UnixBirth constant date := to_date('01/01/1970', 'dd/mm/yyyy');

StatusReplicated constant int := 1;

vJobId user_jobs.job%type;
vSessionId number(14);

-- Replication procedure
procedure replicate_fax;

-- Start replication job
procedure submit_job;

-- Remove replication job.
-- Run it before ANY operation within Fax Database!
procedure remove_job;

-- Run replication job now.
procedure run_job;

-- Set new replication interval.
procedure change_interval(pNewInterval varchar2 := 'SysDate + (1 / 1440)');

-- Return current replication interval.
function get_interval return varchar2;

end;
/
