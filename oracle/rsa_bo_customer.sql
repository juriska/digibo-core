/************************** RBA database stored procedures ********************
 *    $Author: boris $
 *   $RCSfile: rsa_bo_customer.sql,v $
 *  $Revision: 1.29 $
 *        $Id: rsa_bo_customer.sql,v 1.29 2009/09/14 13:33:19 boris Exp $
 *
 ********* Copyright (c) 2001 Parex Bank, Latvia. All rights reserved *********/

CREATE OR REPLACE package BOCustomer as

CERT_ACTIVE	constant number(1) := 0;
CERT_INACTIVE	constant number(1) := 1;
CERT_REVOKED	constant number(1) := 2;
CERT_EXPIRED	constant number(1) := 3;

type cursor_t is ref cursor;

function load_customer_conditions(
	pId in varchar2,
	pLocation in varchar2,
	pTmp in out number,
	pNoAuth out number
) return cursor_t;

function load_customer_conditions_hist(pCustId in varchar2) return cursor_t;
function load_customer_conditions_tmp(pCustId in varchar2) return cursor_t;
function load_customer_conditions_info(pCustId in varchar2) return cursor_t;

function load_conditions_hist(
	pId in varchar2,
	pLocation in varchar2
) return cursor_t;

function load_user_certificates(pUserId in varchar2) return cursor_t;

end;
/
CREATE OR REPLACE package body BOCustomer as

function load_customer_conditions(
	pId in varchar2, -- Customer ID
	pLocation in varchar2,
	pTmp in out number, -- on 0 current signature conditions is loaded, else - unauthorized 
	pNoAuth out number -- return value: if more than 0 
) return cursor_t is
	rv cursor_t;
begin
	pNoAuth := 0;

	if pTmp > 0 then
		select count(1) into pTmp
		from signature_conditions_tmp@&&rsa_dblink sc
		where sc.cust_id = pId and (
			sc.type = 0 or -- Empty unauthorized
			sc.type not in (13, 14) or
			(sc.type = 13 and exists (select 1 from ibglb.acsd@&&rsa_dblink a where a.iban = sc.account and a.is_visible = 1 and a.close_date is null and a.location = pLocation)) or
			(sc.type = 14 and exists (select 1 from ibglb.acsd@&&rsa_dblink a where a.iban = sc.account and a.ccy = sc.ccy and a.is_visible = 1 and a.close_date is null and a.location = pLocation))
		);
	end if;

	if pTmp = 0 then
		open rv for select
			sc.account iban,
			sc.ccy,
			sc.type,
			sc.condition,
			to_char(sc.txn_limit) txn_limit,
			sc.txn_limit_ccy
		from signature_conditions sc
		where sc.cust_id = pId and (
			sc.type not in (13, 14) or
			(sc.type = 13 and exists (select 1 from ibglb.acsd@&&rsa_dblink a where a.iban = sc.account and a.is_visible = 1 and a.close_date is null and a.location = pLocation)) or
			(sc.type = 14 and exists (select 1 from ibglb.acsd@&&rsa_dblink a where a.iban = sc.account and a.ccy = sc.ccy and a.is_visible = 1 and a.close_date is null and a.location = pLocation))
		)
		order by iban, ccy, type;
	else
		open rv for select
			sc.account iban,
			sc.ccy,
			sc.type,
			sc.condition,
			to_char(sc.txn_limit) txn_limit,
			sc.txn_limit_ccy
		from signature_conditions_tmp@&&rsa_dblink sc
		where sc.cust_id = pId and (
			sc.type = 0 or -- Empty unauthorized
			sc.type not in (13, 14) or
			(sc.type = 13 and exists (select 1 from ibglb.acsd@&&rsa_dblink a where a.iban = sc.account and a.is_visible = 1 and a.close_date is null and a.location = pLocation)) or
			(sc.type = 14 and exists (select 1 from ibglb.acsd@&&rsa_dblink a where a.iban = sc.account and a.ccy = sc.ccy and a.is_visible = 1 and a.close_date is null and a.location = pLocation))
		)
		order by iban, ccy, type;

		select count(1) into pNoAuth
		from signature_conditions_tmp@&&rsa_dblink sc
		where sc.cust_id = pId and change_officer = bocommon.officerId;
	end if;
	return rv;
end;

function load_customer_conditions_hist(
	pCustId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select distinct
		c.change_date changeDate,
		nvl(o.name, o.login) changeOfficer,
		c.audit_id id,
		c.auth is_auth
	from
		conditions_history c,
		audit_log a,
		officers@&&rsa_dblink o
	where
		c.audit_id = a.id
		and c.cust_id = pCustId
		and c.change_officer = o.id;
	return rv;
end;

function load_customer_conditions_info(
	pCustId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select * from 
		(select distinct
			c.change_date changeDate,
			nvl(o.name, o.login) changeOfficer,
			null id,
			'A'  is_auth
		from
			signature_conditions c,
			officers@&&rsa_dblink o
		where
			c.cust_id = pCustId
			and c.change_officer = o.id
		order by c.change_date desc
		)
	where rownum = 1;
	return rv;
end;

function load_customer_conditions_tmp(
	pCustId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select * from 
		(select distinct
			c.change_date changeDate,
			nvl(o.name, o.login) changeOfficer,
			null id,
			'N' is_auth
		from
			signature_conditions_tmp@&&rsa_dblink c,
			officers@&&rsa_dblink o
		where
			c.cust_id = pCustId
			and c.change_officer = o.id
		order by c.change_date desc
		)
	where rownum = 1;
	return rv;
end;

function load_conditions_hist(
	pId in varchar2,
	pLocation in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		account iban,
		ccy,
		type,
		condition
	from
		conditions_history
	where
		audit_id = pId
	order by iban, ccy, type;
	return rv;
end;

function load_user_certificates(
	pUserId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		distinct c.id md5,
		c.pem_certificate text,
		c.issuer_id issuerId,
		c.ca_id authId,
		c.serial serial,
		c.dev_type dev_type
	from
		certificates c,
		ways_of_connection@&&rsa_dblink w
	where
		w.cdevice_serial_number = c.id
		and w.channel_id = 21
		and w.user_id = pUserId
		and c.status in (CERT_ACTIVE, CERT_EXPIRED);
	return rv;
end;

end;
/
