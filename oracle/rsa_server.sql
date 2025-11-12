prompt This package is part of RSA server.

create or replace package rsasrv as

-- Written by Boris Botstein for DIGI::FIRMA project.

-- Ver. 1.00

-- Ver. 1.01
-- 1. Field tested_documents.customer_id added (store_doc).
-- 2. Snapshot rsa_s$acsd is not longer required.
-- 3. procedure get_acsd eliminated.
-- 4. FFO support added (get_ffo_conditions).

type cursor_t is ref cursor;

-- Validates officer id.
-- Returns 1 on success.
function oid_allowed(
	oid in integer
) return integer;

-- Inserts root certificate to database.
procedure lroot(
	md5 in varchar2,	-- certificate's md5 in base64 encoding.
	text in varchar2,	-- certificate's text.
	serial_no in varchar2,	-- serial no assigned by root's issuer.
	auth_id in varchar2,	-- authority's id.
	subject in varchar2	-- certificate's subject.
);

-- Inserts user's certificate to database.
procedure luser(
	oid in integer,		-- officer id.
	md5 in varchar2,	-- certificate's md5 in base64 encoding.
	text in varchar2,	-- certificate's text.
	serial_no in integer,	-- serial no assigned.
	parent in varchar2,	-- certificate's parent id.
	status_id in integer	-- server defined status (0 - active, 1 - inactive)
);

-- revokes next serial no from sequence.
function get_next_serial_no return integer;

-- retrieves certificate.
procedure get_certificate(
	md5 in varchar2,	 -- certificate's id.
	status_id out integer,	 -- certificate's status.
	dev_type_id out integer, -- certificate's device type.
	text out varchar2,	 -- certificate's text.
	issuer out varchar2,	 -- certificate's parent id.
	auth_id out varchar2	 -- authorities.id.
);

-- changes certificate's status to active (0).
procedure set_active(
	md5 in varchar2		-- certificate's id.
);

-- changes certificate's status to expired (3).
procedure set_expired(
	md5 in varchar2		-- certificate's id.
);

-- VRF.

function get_sign_rights(
	cust in integer,	-- customer id.
	cert in varchar2	-- certificates id stack.
) return cursor_t;

function get_sign_conditions(
	cust in integer,	-- customer id.
	acnt in varchar2,	-- mccy_accnum || sub_accnum.
	sub in varchar2,	-- sub_accnum.
	ccy_id in varchar2	-- debet ccy.
) return cursor_t;

function transaction_limit(
	cond_id in varchar2,
	digest in varchar2,
	acnt in varchar2,
	pCcy in varchar2
) return integer;

function get_ffo_conditions(
	cust in integer		-- customer id.
) return cursor_t;

procedure store_doc(
	doc_id in varchar2,	-- document id.
	rv in integer,		-- VRF result.
	cipher in varchar2,	-- decrypted digest, if any.
	src in varchar2,	-- signature source.
	cusd_id in integer	-- customer id.
);

-- VSG.

procedure get_doc(
	doc_id in varchar2,	-- document id.
	rv out integer,		-- VRF result.
	cipher out varchar2,	-- message digest.
	src out varchar2	-- message.
);

-- CRR.

procedure crr(
	oid in integer,		-- officer id.
	cert_id in varchar2	-- certificate id to revoke.
);

function store_certificate(
	serial_no in varchar2,
	pem in varchar2,
	ocsp in integer
) return integer;

end;
/

show err;

create or replace package body rsasrv as

function oid_allowed(
	oid in integer
) return integer is
	rv integer;
begin
--	select count(id) into rv from RSA_S$OFFICERS where oid = id;
--	return rv;
	return 1;
end;

procedure lroot(
	md5 in varchar2,	-- certificate's md5 in base64 encoding.
	text in varchar2,	-- certificate's text.
	serial_no in varchar2,	-- serial no assigned by root's issuer.
	auth_id in varchar2,	-- authority's id.
	subject in varchar2	-- certificate's subject.
) is
	sdate date;
begin
	select sysdate into sdate from sys.dual;
	insert into authorities (id, name) values (auth_id, subject);
	insert into certificates (
		id,
		pem_certificate,
		status,
		create_date,
		create_officer,
		change_date,
		change_officer,
		serial,
		issuer_id,
		ca_id
	)
	values (
		md5,
		text,
		0,
		sdate,
		-1,
		sdate,
		-1,
		serial_no,
		NULL,
		auth_id
	);
end;

procedure luser(
	oid in integer,		-- officer id.
	md5 in varchar2,	-- certificate's md5 in base64 encoding.
	text in varchar2,	-- certificate's text.
	serial_no in integer,	-- serial no assigned.
	parent in varchar2,	-- certificate's parent id.
	status_id in integer	-- server defined status (0 - active, 1 - inactive)
) is
	sdate date;
begin
	select sysdate into sdate from sys.dual;
	insert into certificates (
		id,
		pem_certificate,
		status,
		create_date,
		create_officer,
		change_date,
		change_officer,
		serial,
		issuer_id,
		ca_id
	)
	values (
		md5,
		text,
		status_id,
		sdate,
		oid,
		sdate,
		oid,
		serial_no,
		parent,
		NULL
	);

end;

function get_next_serial_no return integer is
	rv integer;
begin
	select UNQ_CERT_SERIAL_SEQ.NextVal into rv from sys.dual;
	return rv;
end;

procedure get_certificate(
	md5 in varchar2,	 -- certificate's id.
	status_id out integer,	 -- certificate's status.
	dev_type_id out integer, -- certificate's device type.
	text out varchar2,	 -- certificate's text.
	issuer out varchar2,	 -- certificate's parent id.
	auth_id out varchar2	 -- authorities.id.
) is
begin
	select status, pem_certificate, issuer_id, ca_id, dev_type
	into status_id, text, issuer, auth_id, dev_type_id
	from certificates
	where id = replace(md5, '_');
end;

procedure set_active(
	md5 in varchar2		-- certificate's id.
) is
	status_id integer;
begin
	select status into status_id from certificates where id = replace(md5, '_');
	if 1 = status_id then
		update certificates set status = 0 where id = replace(md5, '_');
	elsif 0 = status_id then
		return;
	else
		raise_application_error(-20000, md5 || ' - invalid status.');
	end if;
end;

procedure set_expired(
	md5 in varchar2		-- certificate's id.
) is
	status_id integer;
begin
	select status into status_id from certificates where id = replace(md5, '_');
	if 0 = status_id or 1 = status_id then
		update certificates set status = 3 where id = replace(md5, '_');
	elsif 3 = status_id then
		return;
	else
		raise_application_error(-20001, md5 || ' - invalid status.');
	end if;
end;

function get_id(
	src in varchar2,	-- certificate ids catenation.
	no in integer		-- index [1 .. 32].
) return varchar2 is
begin
	return replace(substr(src, ((no - 1) * 24) + 1, 24), '_');
end;

function get_sign_rights(
	cust in integer,	-- customer id.
	cert in varchar2	-- certificates id stack.
) return cursor_t is
	rv cursor_t;
	c01 varchar2(24) := get_id(cert,  1);
	c02 varchar2(24) := get_id(cert,  2);
	c03 varchar2(24) := get_id(cert,  3);
	c04 varchar2(24) := get_id(cert,  4);
	c05 varchar2(24) := get_id(cert,  5);
	c06 varchar2(24) := get_id(cert,  6);
	c07 varchar2(24) := get_id(cert,  7);
	c08 varchar2(24) := get_id(cert,  8);
	c09 varchar2(24) := get_id(cert,  9);
	c10 varchar2(24) := get_id(cert, 10);
	c11 varchar2(24) := get_id(cert, 11);
	c12 varchar2(24) := get_id(cert, 12);
	c13 varchar2(24) := get_id(cert, 13);
	c14 varchar2(24) := get_id(cert, 14);
	c15 varchar2(24) := get_id(cert, 15);
	c16 varchar2(24) := get_id(cert, 16);
	c17 varchar2(24) := get_id(cert, 17);
	c18 varchar2(24) := get_id(cert, 18);
	c19 varchar2(24) := get_id(cert, 19);
	c20 varchar2(24) := get_id(cert, 20);
	c21 varchar2(24) := get_id(cert, 21);
	c22 varchar2(24) := get_id(cert, 22);
	c23 varchar2(24) := get_id(cert, 23);
	c24 varchar2(24) := get_id(cert, 24);
	c25 varchar2(24) := get_id(cert, 25);
	c26 varchar2(24) := get_id(cert, 26);
	c27 varchar2(24) := get_id(cert, 27);
	c28 varchar2(24) := get_id(cert, 28);
	c29 varchar2(24) := get_id(cert, 29);
	c30 varchar2(24) := get_id(cert, 30);
	c31 varchar2(24) := get_id(cert, 31);
	c32 varchar2(24) := get_id(cert, 32);
begin
	open rv for
	select sign_level, cert_id from sign_rights
	where cust_id = cust and cert_id in (
		c01, c02, c03, c04, c05, c06, c07, c08, c09, c10,
		c11, c12, c13, c14, c15, c16, c17, c18, c19, c20,
		c21, c22, c23, c24, c25, c26, c27, c28, c29, c30,
		c31, c32
	);
	return rv;
end;

function get_sign_conditions(
	cust in integer,	-- customer id.
	acnt in varchar2,	-- mccy_accnum || sub_accnum.
	sub in varchar2,	-- sub_accnum.
	ccy_id in varchar2	-- debet ccy.
) return cursor_t is
	rv cursor_t;
begin
	open rv for
	select id, type, condition from signature_conditions
	where cust_id = cust and (
		(type =  1) or
		(type = 11) or
		(type = 12 and account = acnt) or
		(type = 13 and account = acnt and (sub_account = sub or sub is NULL)) or
		(type = 14 and account = acnt and (sub_account = sub or sub is NULL) and ccy = ccy_id)
	)
	order by type desc;
	return rv;
end;
/*
function recalculate(ccy in varchar2, amount in number, loc in varchar2) return number is
	rate number(15, 6) := 0.0;
	quote integer := 0;
	today date;
begin
	-- concept: look-and-feel for each company !
	if ccy = 'LVL' and loc = 'LV' then
		return amount;
	end if;
	if ccy = 'EUR' and loc = 'EE' then
		return amount;
	end if;
	if ccy = 'EUR' and loc = 'DE' then
		return amount;
	end if;
	if ccy = 'SEK' and loc = 'SE' then
		return amount;
	end if;
	--
	select d.today into today from ibglb.glb_business_dates@&&rsa_dblink d;
	select c.quot_amount, c.reval_local_mid
	into quote, rate
	from ibglb.glb_currency_reval@&&rsa_dblink c
	where c.rate_date = today and
		c.id = ccy and
		c.location = loc;
	if quote = 0 then
		quote := 1;
	end if;
	if loc = 'EE' then
		return (amount / rate) / quote;
	end if;
	return (amount * rate) / quote;
end;
*/
function recalculate(ccy in varchar2, amount in number, loc in varchar2) return number is
	rate number(15, 6) := 0.0;
	quote integer := 0;
	today date;
	LVLinLV number := 0;
begin
	select is_visible into LVLinLV from ibglb.glb_currencies@&&rsa_dblink where id = 'LVL';
	-- concept: look-and-feel for each company !
	if ccy = 'LVL' and loc = 'LV' and LVLinLV = 1 then
		return amount;
	end if;
	if ccy = 'EUR' and loc = 'LV' and LVLinLV = 0 then
		return amount;
	end if;
	if ccy = 'EUR' and loc = 'EE' then
		return amount;
	end if;
	if ccy = 'EUR' and loc = 'DE' then
		return amount;
	end if;
	if ccy = 'SEK' and loc = 'SE' then
		return amount;
	end if;
	--
	select d.today into today from ibglb.glb_business_dates@&&rsa_dblink d;
	select c.quot_amount, c.reval_local_mid
	into quote, rate
	from ibglb.glb_currency_reval@&&rsa_dblink c
	where c.rate_date = today and
		c.id = ccy and
		c.location = loc;
	if quote = 0 then
		quote := 1;
	end if;
	if LVLinLV = 0 then
		return (amount / rate) / quote;
	end if;
	if loc = 'EE' then
		return (amount / rate) / quote;
	end if;
	return (amount * rate) / quote;
end;

function transaction_limit(
	cond_id in varchar2,
	digest in varchar2,
	acnt in varchar2,
	pCcy in varchar2
) return integer is
	txn_limit signature_conditions.txn_limit%type := null;
	txn_limit_ccy char(3) := null;
	loc char(2) := null;
	src varchar2(4096);
	t_ccy char(3);
	t_amount varchar2(64);
	n integer := 0;
begin
	begin
		select txn_limit, txn_limit_ccy
		into txn_limit, txn_limit_ccy
		from signature_conditions
		where id = cond_id;
	exception when NO_DATA_FOUND then
		return 10;
	end;
	if nvl(txn_limit, 0.0) = 0.0 or txn_limit_ccy is null then
		return 0; -- Unlimited condition.
	end if;
	begin
		select location
		into loc
		from ibglb.acsd@&&rsa_dblink a
		where (a.iban = acnt or to_char(a.mccy_accnum) = acnt) and a.ccy = pCcy and a.is_visible = 1;
	exception
		when NO_DATA_FOUND then
--			raise_application_error(-20000, 'Parameters: ' || acnt || ' ' || pCcy || ' ' || digest);
			return 20;
		when TOO_MANY_ROWS then
--			raise_application_error(-20001, 'Parameters: ' || acnt || ' ' || pCcy || ' ' || digest);
			return 21;
	end;
	n := instr(digest, chr(31));
	if nvl(n, 0) = 0 then
		return 30;
	end if;
	src := substr(digest, n + 1); -- skipping debit account.
	n := instr(src, chr(31));
	if nvl(n, 0) = 0 then
		return 40;
	end if;
	t_amount := substr(src, 1, n - 1); -- transaction amount.
	src := substr(src, n + 1);
	n := instr(src, chr(31));
	if nvl(n, 0) = 0 then
		return 50;
	end if;
	t_ccy := substr(src, 1, n - 1); -- transaction CCY.
	begin
		if recalculate(t_ccy, t_amount, loc) <=
			recalculate(txn_limit_ccy, txn_limit, loc) then
			return 0;
		end if;
		return 60;
	exception when NO_DATA_FOUND then
		return 70;
	end;
end;

function get_ffo_conditions(
	cust in integer		-- customer id.
) return cursor_t is
	rv cursor_t;
begin
	open rv for
	select type, condition from signature_conditions
	where cust_id = cust and ((type = 1) or (type = 21))
	order by type desc;
	return rv;
end;

procedure store_doc(
	doc_id in varchar2,	-- document id.
	rv in integer,		-- VRF result.
	cipher in varchar2,	-- decrypted digest, if any.
	src in varchar2,	-- signature source.
	cusd_id in integer	-- customer id.
) is
begin
	insert into tested_documents (
		test_date,
		test_code,
		digest,
		id,
		signature,
		customer_id
	)
	values (
		sysdate,
		rv,
		cipher,
		doc_id,
		src,
		cusd_id
	);
end;

procedure get_doc(
	doc_id in varchar2,	-- document id.
	rv out integer,		-- VRF result.
	cipher out varchar2,	-- message digest.
	src out varchar2	-- message.
) is
begin
	select test_code, digest, signature
	into rv, cipher, src
	from tested_documents
	where doc_id = id;
end;

procedure crr(
	oid in integer,		-- officer id.
	cert_id in varchar2	-- certificate id to revoke.
) is
	d date := sysdate;
	r rowid;
begin
	select rowid into r from certificates where id = replace(cert_id, '_');
	update certificates	-- certificate.
	set
		status = 2,
		change_officer = oid,
		change_date = d
	where r = rowid;
	update certificates	-- childs, if any.
	set
		status = 2,
		change_officer = oid,
		change_date = d
	where issuer_id = cert_id;
end;

function store_certificate(
	serial_no in varchar2,
	pem in varchar2,
	ocsp in integer
) return integer is
	rv integer := 0;
	ex integer := 0;
begin
	select count(1) into ex from certificates where id = serial_no;
	if ex = 0 then
		return 1; -- serial_no not registered in Digi::Bo.
	end if;
	update certificates
	set
		pem_certificate = pem,
		status = decode(ocsp, 1, 0, 4),
		dev_type = 5
	where id = serial_no;
	return 0;
end;

end;
/

show err;

prompt End of RSA server package installation.
