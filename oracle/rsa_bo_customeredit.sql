/************************** RBA database stored procedures ********************
 *    $Author: boris $
 *   $RCSfile: rsa_bo_customeredit.sql,v $
 *  $Revision: 1.34 $
 *        $Id: rsa_bo_customeredit.sql,v 1.34 2009/09/14 13:15:41 boris Exp $
 *
 ********* Copyright (c) 2001 Parex Bank, Latvia. All rights reserved *********/

CREATE OR REPLACE package BOCustomerEdit as

type cursor_t is ref cursor;

EVENT_CONDITIONS_CHANGED constant int := 401;
EVENT_CERT_CREATED constant int := 301;
EVENT_CERT_REMOVED constant int := 302;
EVENT_LEVEL_CHANGED constant int := 201;

-- Unauthorized:
procedure save_conditions_hist(pCustId varchar2);

procedure remove_customer_conditions(pCustId varchar2);

procedure save_customer_conditions(
        pCustId varchar2,
        pType number,
	pIban varchar2,
        pCcy varchar2,
        pCondition number,
	pTxnLimit varchar2,
	pTxnLimitCcy varchar2
);

procedure set_level(
	pCustId number,
	pWocId number,
	pLevel in out varchar2
);

procedure rem_level(
	pCustId number,
	pCertId varchar2
);

-- //

-- Authorized:
procedure authorize_customer_conditions(
        pCustId varchar2,
	pRemove in number
);

procedure decline_customer_conditions(
	pCustId varchar2
);

procedure authorize_level(
	pCustId number,
	pWocId number,
	pCertId varchar2,
	pCertDevId number,
	pLevel in out varchar2
);

-- //

procedure set_certificate(
	pCustId number,
	pWocId number,
	pCertId varchar2,
	pDevType number,
	pLevel out number
);

procedure rem_certificate(
	pCustId number,
	pWocId number,
	pCertId varchar2
);

procedure renew_certificate(
	pCertId varchar2,
	pNewCertId varchar2
);

end;
/

CREATE OR REPLACE package body BOCustomerEdit as

procedure save_conditions_hist( -- unauthorized only
	pCustId varchar2
) is begin
	bocommon.log_event(EVENT_CONDITIONS_CHANGED, pCustId);

	insert into conditions_history (
		id,
		cust_id,
		type,
		account,
		ccy,
		condition,
		change_date,
		change_officer,
		audit_id,
		auth,
		txn_limit,
		txn_limit_ccy
	) select
		1, -- we don't have any ID's
		cust_id,
		type,
		account,
		ccy,
		condition,
		change_date,
		change_officer,
		unq_audit_seq.CurrVal,
		'N',
		txn_limit,
		txn_limit_ccy
	from signature_conditions_tmp@&&rsa_dblink
	where cust_id = pCustId;
end;

procedure remove_customer_conditions( -- unautorhized only
	pCustId varchar2
) is begin
	delete from signature_conditions_tmp@&&rsa_dblink
	where cust_id = pCustId;
end;
    
procedure save_customer_conditions( -- single list view record
        pCustId varchar2,
        pType number,
	pIban varchar2,
        pCcy varchar2,
        pCondition number,
	pTxnLimit varchar2,
	pTxnLimitCcy varchar2
) is begin
	-- NON-Authorized changes
	insert into signature_conditions_tmp@&&rsa_dblink (
		cust_id,
		type,
		account,
		ccy,
		condition,
		change_date,
		change_officer,
		txn_limit,
		txn_limit_ccy
	) values (
		pCustId,
		pType,
		pIban,
		pCcy,
		pCondition,
		SysDate,
		bocommon.officerId,
		to_number(pTxnLimit),
		pTxnLimitCcy
	);
end;

procedure authorize_customer_conditions(
        pCustId varchar2,
	pRemove in number
) is begin
	bocommon.log_event(EVENT_CONDITIONS_CHANGED, pCustId);

	-- Formely authorizated conditions history
	insert into conditions_history (
		id,
		cust_id,
		type,
		account,
		ccy,
		condition,
		change_date,
		change_officer,
		audit_id,
		auth,
		txn_limit,
		txn_limit_ccy
	) select
		id,
		cust_id,
		type,
		account,
		ccy,
		condition,
		change_date,
		change_officer,
		unq_audit_seq.CurrVal,
		'A',
		txn_limit,
		txn_limit_ccy
	from signature_conditions
	where cust_id = pCustId;

	-- Formely authorized conditions deletion
	delete from signature_conditions
	where cust_id = pCustId;

	delete from rsa_t$signature_conditions@&&rsa_dblink
	where cust_id = pCustId;

	if pRemove = 0 then
		-- Authorization
		insert into signature_conditions (
			id,
			cust_id,
			type,
			account,
			ccy,
			condition,
			change_date,
			change_officer,
			txn_limit,
			txn_limit_ccy
		) select
			unq_cond_id_seq.nextVal,
			cust_id,
			type,
			account,
			ccy,
			condition,
			SysDate,
			bocommon.officerId, -- officer who authorized
			txn_limit,
			txn_limit_ccy
		from signature_conditions_tmp@&&rsa_dblink
		where cust_id = pCustId;

		-- Utility required copy
		insert into rsa_t$signature_conditions@&&rsa_dblink (
			cust_id,
			type,
			account,
			ccy,
			condition,
			change_date,
			change_officer,
			txn_limit,
			txn_limit_ccy
		) select
			cust_id,
			type,
			account,
			ccy,
			condition,
			change_date,
			change_officer,
			txn_limit,
			txn_limit_ccy
		from signature_conditions
		where cust_id = pCustId;
	end if;

	-- Unauthorizated conditions history
	bocommon.log_event(EVENT_CONDITIONS_CHANGED, pCustId);

	insert into conditions_history (
		id,
		cust_id,
		type,
		account,
		ccy,
		condition,
		change_date,
		change_officer,
		audit_id,
		auth,
		txn_limit,
		txn_limit_ccy
	) select
		1,
		cust_id,
		type,
		account,
		ccy,
		condition,
		change_date,
		change_officer,
		unq_audit_seq.CurrVal,
		'N',
		txn_limit,
		txn_limit_ccy
	from signature_conditions_tmp@&&rsa_dblink
	where cust_id = pCustId;

	-- Unauthorizated conditions deletion
	delete from signature_conditions_tmp@&&rsa_dblink
	where cust_id = pCustId;
end; -- authorize_customer_conditions

procedure decline_customer_conditions(
	pCustId varchar2
) is begin
	bocommon.log_event(EVENT_CONDITIONS_CHANGED, pCustId);

	-- Unauthorizated conditions history
	insert into conditions_history (
		id,
		cust_id,
		type,
		account,
		ccy,
		condition,
		change_date,
		change_officer,
		audit_id,
		auth,
		txn_limit,
		txn_limit_ccy
	) select
		1,
		cust_id,
		type,
		account,
		ccy,
		condition,
		change_date,
		change_officer,
		unq_audit_seq.CurrVal,
		'N',
		txn_limit,
		txn_limit_ccy
	from signature_conditions_tmp@&&rsa_dblink
	where cust_id = pCustId;

	-- Unauthorizated conditions deletion
	delete from signature_conditions_tmp@&&rsa_dblink
	where cust_id = pCustId;

	-- Additional history record (unauthorized and conditions empty)
	bocommon.log_event(EVENT_CONDITIONS_CHANGED, pCustId);

	insert into conditions_history (
		id,
		cust_id,
		type,
		account,
		ccy,
		condition,
		change_date,
		change_officer,
		audit_id,
		auth
	) values (
		1,
		pCustId,
		1,
		null,
		null,
		0, -- hm...
		SysDate,
		bocommon.officerId,
		unq_audit_seq.CurrVal,
		'N'
	);
end;

procedure set_certificate(
	pCustId number,
	pWocId number,
	pCertId varchar2,
	pDevType number,
	pLevel out number
) is
	vCount number;
begin
	update ways_of_connection@&&rsa_dblink w
	set
		w.cdevice_type_id = pDevType,
		w.cdevice_serial_number = pCertId,
		w.change_date = SysDate,
		w.change_officer_id = bocommon.officerId
	where w.id = pWocId;

	if 5 = pDevType then
		select count(id) into vCount
		from certificates
		where id = pCertId;
		if 0 = vCount then
			insert into certificates (id, dev_type, serial, pem_certificate, status, create_officer)
			values (pCertId, pDevType, 0, 'N/A', 0, bocommon.officerId);
		else
			update certificates
			set 
				status = 0,
				change_officer = bocommon.officerId,
				change_date = sysdate
			where id = pCertId;
		end if;
	end if;

	bocommon.log_event(EVENT_CERT_CREATED, pCertId, pWocId);

        -- current level for this cert	
	select
		sign_level into pLevel
	from
		sign_rights
	where
		cust_id = pCustId
		and cert_id = pCertId;
	exception when no_data_found then
		pLevel := 0;
end;

procedure rem_certificate(
	pCustId number,
	pWocId number,
	pCertId varchar2
) is
	vWocHistId number;
	cursor rv is select id
		from ways_of_connection@&&rsa_dblink w
		where w.cdevice_serial_number = pCertId and
			w.channel_id = 21;
begin
	-- Saving history for all WOCs using this cert
	-- and removing it from all the WOCs
	for rec in rv loop
		bocustomeredit.save_channel_hist@&&rsa_dblink(rec.id);
		bocommon.log_event(EVENT_CERT_REMOVED, pCertId, rec.id);

		update ways_of_connection@&&rsa_dblink
		set
			cdevice_serial_number = null,
			change_date = SysDate,
			change_officer_id = bocommon.officerId
		where
			id = rec.id and
			channel_id = 21; -- DF only.

		update customer_globus_restrictions@&&rsa_dblink
		set
			sign_level = null
		where
			woc_id = rec.id;
	end loop;

	-- sign_rights	
	insert into rights_history (
		audit_id,
		cert_id,
		cust_id,
		sign_level,
		change_date,
		change_officer
	) select
		unq_audit_seq.CurrVal,
		cert_id,
		cust_id,
		sign_level,
		change_date,
		change_officer
	from sign_rights
	where
		cert_id = pCertId;

	delete from sign_rights
	where 
		cert_id = pCertId;
end;

procedure renew_certificate(
	pCertId varchar2,
	pNewCertId varchar2
) is
	cursor rv is select id
		from ways_of_connection@&&rsa_dblink w
		where w.cdevice_serial_number = pCertId and
			w.channel_id = 21;
begin
	-- Saving history for all WOCs using this cert
	for rec in rv loop
		bocustomeredit.save_channel_hist@&&rsa_dblink(rec.id);
		bocommon.log_event(EVENT_CERT_CREATED, pCertId, rec.id);
	end loop;

	-- WOC
	update ways_of_connection@&&rsa_dblink
	set
		cdevice_serial_number = pNewCertId,
		change_date = SysDate,
		change_officer_id = bocommon.officerId
	where
		cdevice_serial_number = pCertId and
		channel_id = 21;

	-- sign_rights (matches last audit_log record)
	insert into rights_history (
		audit_id,
		cert_id,
		cust_id,
		sign_level,
		change_date,
		change_officer
	) select
		unq_audit_seq.CurrVal,
		cert_id,
		cust_id,
		sign_level,
		change_date,
		change_officer
	from sign_rights
	where
		cert_id = pCertId;

	update sign_rights
	set
		cert_id = pNewCertId,
		change_date = SysDate,
		change_officer = bocommon.officerId
	where
		cert_id = pCertId;
end;

procedure set_level(
	pCustId number,
	pWocId number,
	pLevel in out varchar2
) is begin
	-- bocustomeredit.save_channel_hist@&&rsa_dblink(pWocId); -- for single WOC

	-- Unauthorized sign level: 
	-- being updated only current WOC by setting temporary sign level
	if pLevel = 0 then
		pLevel := null;
	end if;
	update customer_globus_restrictions@&&rsa_dblink
	set
		change_officer_id = bocommon.officerId,
		change_date = SysDate,
		sign_level_tmp = pLevel
	where
		cusd_id = pCustId
		and woc_id = pWocId;
end;

procedure authorize_level(
	pCustId number,
	pWocId number,
	pCertId varchar2,
	pCertDevId number,
	pLevel in out varchar2
) is
	cursor rv is select distinct id
		from ways_of_connection@&&rsa_dblink w, customer_globus_restrictions@&&rsa_dblink cgr
		where w.id = cgr.woc_id and w.cdevice_serial_number = pCertId and
			w.channel_id = 21;
	vLevel number;
begin
	select count(cert_id) into vLevel
	from sign_rights                   
	where cert_id = pCertId and cust_id = pCustId;

	if vLevel > 0 then
		bocommon.log_event(EVENT_LEVEL_CHANGED, pCertId, '');

		insert into rights_history (
			audit_id,
			cert_id,
			cust_id,
			sign_level,
			change_date,
			change_officer
		) select
			unq_audit_seq.CurrVal,
			cert_id,
			cust_id,
			sign_level,
			change_date,
			change_officer
		from sign_rights
		where
			cert_id = pCertId
			and cust_id = pCustId; -- FIXME: only for one customer?

		update sign_rights set
			sign_level = pLevel,
			change_date = SysDate,
			change_officer = bocommon.officerId
		where 
			cert_id = pCertId
			and cust_id = pCustId;
	else
		insert into sign_rights (
			cert_id,
			cust_id,
			sign_level,
			change_date,
			change_officer
		) values (
			pCertId,
			pCustId,
			pLevel,
			SysDate,
			bocommon.officerId
		);
	end if;

	-- current sign level 
	-- being updated all WOCs using this cert on this customer

	if pLevel = 0 then
		pLevel := null;
	end if;
	for rec in rv loop
		bocustomeredit.save_channel_hist@&&rsa_dblink(rec.id);

		update customer_globus_restrictions@&&rsa_dblink
		set
			change_officer_id = bocommon.officerId,
			change_date = SysDate,
			sign_level_tmp = pLevel,
			sign_level = pLevel
		where
			cusd_id = pCustId
			and woc_id = rec.id;

		-- applying changes to whole WOC
		update ways_of_connection@&&rsa_dblink
		set
			change_officer_id = bocommon.officerId
		where
			id = rec.id;
	end loop;
end;

procedure rem_level(
	pCustId number,
	pCertId varchar2
) is begin
	bocommon.log_event(EVENT_LEVEL_CHANGED, pCertId, '');

	insert into rights_history (
		audit_id,
		cert_id,
		cust_id,
		sign_level,
		change_date,
		change_officer
	) select
		unq_audit_seq.CurrVal,
		cert_id,
		cust_id,
		sign_level,
		change_date,
		change_officer
	from sign_rights
	where
		cert_id = pCertId
		and cust_id = pCustId;

	delete from sign_rights
	where
		cert_id = pCertId
		and cust_id = pCustId;
end;

end;
/
show err;
