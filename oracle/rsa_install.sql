accept rsa_instance_name char default RSAX prompt 'Enter target RSA SID:'
accept rsa_owner_name char default RSA_DIGI prompt 'Enter RSA owner name [RSA_DIGI]:'
accept rsa_owner_passwd char default rsa_digi prompt 'Enter RSA owner password:' hide
accept rsa_sys_passwd char default master prompt 'Enter RSA ''sys'' password:' hide
accept rsa_dblink char default IBDX prompt 'Enter dblink to IB name [IBDX]:'

prompt Connecting as sysdba user
connect sys/&&rsa_sys_passwd@&&rsa_instance_name as sysdba;

--@rsa_roles.sql

disconnect;

prompt Connecting as sysdba user
connect sys/&&rsa_sys_passwd@&&rsa_instance_name as sysdba;

spool rsabo.log

prompt
prompt Patch for RSA instance ...
prompt

grant select on sys.dba_role_privs to &&rsa_owner_name;
grant select on sys.dba_users to &&rsa_owner_name;
grant select on sys.dba_roles to &&rsa_owner_name;

grant connect to RBOSYSADMIN;
grant connect to RBOOFFICER;
grant connect to RBOCUSTOMER;
grant connect to CASERVER;

GRANT GRANT ANY ROLE TO RBOSYSADMIN WITH ADMIN OPTION;
GRANT ALTER USER TO RBOSYSADMIN WITH ADMIN OPTION;
GRANT CREATE USER TO RBOSYSADMIN WITH ADMIN OPTION;
GRANT ALTER USER TO RBOOFFICERPASSWORD;

grant RBOCustomer to RBOCustomerEdit;
grant RBOCustomer to RBOTeller;
grant RBOCustomerEdit to RBOInputer;
grant RBOCustomer to RBOAdmin;
grant RBOOfficer to RBOAdmin;
grant RBOOFFICER to RBOSYSADMIN;
grant RBOOFFICER to RBOOFFICERPASSWORD;

disconnect;

prompt Connecting as RSA owner user
connect &&rsa_owner_name/&&rsa_owner_passwd@&&rsa_instance_name;

--@alterNNN.sql

@rsa_server.sql
@rsa_bo_common.sql
@rsa_bo_sysadmin.sql
@rsa_bo_customer.sql
@rsa_bo_customeredit.sql

GRANT EXECUTE ON  RSASRV TO CASERVER;

grant execute on bocommon to RBOCustomer;
grant execute on bocommon to RBOOfficer;
grant execute on bocommon to RBOSYSADMIN;

grant execute on bosysadmin to RBOOfficer;

grant execute on bocustomer to RBOCustomer;
grant execute on bocustomeredit to RBOCustomerEdit;

prompt
prompt Fin for RSA.
prompt

spool off

disconnect;
