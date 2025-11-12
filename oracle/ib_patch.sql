accept ib_instance_name char default ibdx prompt 'Enter target IB SID:'
accept ib_owner_name char default ib prompt 'Enter IB owner name [IB]:'
accept ib_owner_passwd char default ib prompt 'Enter IB owner password:' hide
--accept ib_sys_passwd char default test prompt 'Enter IB ''sys'' password:' hide

--accept digifax_instance_name char default ibdx prompt 'Enter target DIGI_FAX SID:'
--accept digifax_owner_name char default digi_fax prompt 'Enter DIGI_FAX owner name [IB]:'
--accept digifax_owner_passwd char default digi_fax prompt 'Enter DIGI_FAX owner password:' hide
--accept ib_sys_passwd char default test prompt 'Enter IB ''sys'' password:' hide


spool ibbo_patch.log

-- prompt Connecting as sysdba user
-- connect sys/&&ib_sys_passwd@&&ib_instance_name as sysdba;
-- disconnect;

prompt Connecting as IB owner user
connect &&ib_owner_name/&&ib_owner_passwd@&&ib_instance_name;

--prompt Connecting as DIGI_FAX owner user
--connect &&digifax_owner_name/&&digifax_owner_passwd@&&digifax_instance_name;

@bo_credliminc.sql
@bo_prodkit.sql


disconnect;

-- prompt Connecting as sysdba user
-- connect sys/&&ib_sys_passwd@&&ib_instance_name as sysdba;
-- disconnect;

spool off
