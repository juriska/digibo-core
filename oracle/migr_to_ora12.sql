accept ib_instance_name char default ibdasm.citadele.lv prompt 'Enter target IB SID:'
accept ib_sys_passwd char default test prompt 'Enter IB ''sys'' password:' hide

prompt Connecting as sysdba user
connect sys/&&ib_sys_passwd@&&ib_instance_name as sysdba;

spool ibbo.log

prompt
prompt Patch for IB instance ...
prompt

revoke RBOACCADMINEDIT from SYS;
revoke RBOACCADMINVIEW from SYS;
revoke RBOADMIN from SYS;
revoke RBOAMEXORDEREDIT from SYS;
revoke RBOAMEXORDERVIEW from SYS;
revoke RBOAUDITLOG from SYS;
revoke RBOBROKER from SYS;
revoke RBOCARDOFFICER from SYS;
revoke RBOCARDORDERS from SYS;
revoke RBOCONFRISKUNDERTAKEN from SYS;
revoke RBOCQEDIT from SYS;
revoke RBOCQVIEW from SYS;
revoke RBOCUSTODYEDIT from SYS;
revoke RBOCUSTODYVIEW from SYS;
revoke RBOCUSTOMER from SYS;
revoke RBOCUSTOMEREDIT from SYS;
revoke RBODDORDERS from SYS;
revoke RBODEALER from SYS;
revoke RBODEPOEDIT from SYS;
revoke RBODEPOSITORDERS from SYS;
revoke RBODEPOVIEW from SYS;
revoke RBOFAXASSISTANT from SYS;
revoke RBOFAXFFO from SYS;
revoke RBOFAXKRD from SYS;
revoke RBOFAXMANAGER from SYS;
revoke RBOFAXPAYMENT from SYS;
revoke RBOFAXREG from SYS;
revoke RBOFAXVIEW from SYS;
revoke RBOFFORDERS from SYS;
revoke RBOHELPDESK from SYS;
revoke RBOINPUTER from SYS;
revoke RBOLIFE from SYS;
revoke RBOMAINTENANCE from SYS;
revoke RBOMARGINORDERSEDIT from SYS;
revoke RBOMARGINORDERSVIEW from SYS;
revoke RBOMESSAGEATTACHMENTS from SYS;
revoke RBOMESSAGES from SYS;
revoke RBOMORTGLOANORDERSEDIT from SYS;
revoke RBOMORTGLOANORDERSVIEW from SYS;
revoke RBOMORTGLOANS from SYS;
revoke RBONOTE from SYS;
revoke RBONOTIFICATION from SYS;
revoke RBOOFFICER from SYS;
revoke RBOOFFICERDISTRIBUTOR from SYS;
revoke RBOOFFICEREDIT from SYS;
revoke RBOOFFICERPASSWORD from SYS;
revoke RBOOFFICERREPLACE from SYS;
revoke RBOORDERS from SYS;
revoke RBOOTSEAPPROVE from SYS;
revoke RBOOTSESIGN from SYS;
revoke RBOPAM from SYS;
revoke RBOPAMORDERSEDIT from SYS;
revoke RBOPAMORDERSVIEW from SYS;
revoke RBOPAYMENT from SYS;
revoke RBOPAYMENTVIEW from SYS;
revoke RBOPERSONALOFFICER from SYS;
revoke RBOPRODKITEDIT from SYS;
revoke RBOPRODKITVIEW from SYS;
revoke RBORATES from SYS;
revoke RBOSECORDERSEDIT from SYS;
revoke RBOSECORDERSVIEW from SYS;
revoke RBOSMSAGREEMENTEDIT from SYS;
revoke RBOSMSAGREEMENTVIEW from SYS;
revoke RBOSMSMSGVIEW from SYS;
revoke RBOSTANDINGORDERS from SYS;
revoke RBOSYSADMIN from SYS;
revoke RBOTELLER from SYS;
revoke RBOTEMPLATES from SYS;
revoke RBOTEMPLATESEDIT from SYS;
revoke RBOUSERMANUALMIGRATION from SYS;
revoke RBOVSAA from SYS;
revoke RBOVSAAADVICEAPPLICATIONS from SYS;
revoke RBOVSAAADVICES from SYS;
revoke RBOVSAAAPPLICATIONS from SYS;
revoke RBO_CAPF_EDIT from SYS;
revoke RBO_CAPF_VIEW from SYS;
revoke RBO_CREDIT_LIMIT_INCREASE_EDIT from SYS;
revoke RBO_CREDIT_LIMIT_INCREASE_VIEW from SYS;
revoke RBO_CRONTO_PRINT from SYS;
revoke RBO_FI_BO_EDIT from SYS;
revoke RBO_FI_BO_VIEW from SYS;
revoke RBO_GATEWAY_MANAGER from SYS;
revoke RBO_KLAC_IBSERVICE from SYS;
revoke RBO_KLAC_TELEMARKETING from SYS;
revoke RBO_LEASE_APPLIC_EDIT from SYS;
revoke RBO_LEASE_APPLIC_VIEW from SYS;
revoke RBO_LIFEANDPENSION_EDIT from SYS;
revoke RBO_LIFEANDPENSION_VIEW from SYS;
revoke RBO_MOBILESCAN_DOC_VIEW from SYS;
revoke RBO_OFFICER_PHOTO from SYS;
revoke RBO_PENSION_AGR_EDIT from SYS;
revoke RBO_PENSION_AGR_VIEW from SYS;


prompt
prompt Fin for IB.
prompt

disconnect;

spool off

--revoke RBOVSAA from SYS;
--revoke RBOVSAAADVICEAPPLICATIONS from SYS;
--revoke RBOVSAAADVICES from SYS;
--revoke RBOVSAAAPPLICATIONS from SYS;
--grant RBOVSAA to SYS;