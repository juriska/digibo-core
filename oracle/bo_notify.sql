create or replace package bonotify as

type cursor_t is ref cursor;

procedure notify_rates_board;
procedure notify_ffo;
procedure notify_investment;
procedure notify_mortgage_loans;
procedure update_bo_permissions;

end;
/
show err;

create or replace package body bonotify as

procedure write_tcp(
	conn in out nocopy utl_tcp.connection,
	text in varchar2
) is
	t integer := length(text);
	i integer := 1;
	r integer := 0;
begin
	while t > 0 loop
		r := utl_tcp.write_text(conn, substr(text, i), t);
		t := t - r;
		i := i + r;
	end loop;
end;

procedure notify_workstations(
	rates in integer,
	pamo in integer,
	secure in integer,
	margin in integer
) is
	rv cursor_t;
	a officers_online.ip_address%type;
	p officers_online.ip_port%type;
	r officers_online.roles%type;
	c utl_tcp.connection;
	rsa_addr varchar2(64);
	rsa_port integer;
begin
	select value1, value2
	into rsa_addr, rsa_port
	from digibo_parameters
	where name = 'NOTIFY_SERVER';

	open rv for select distinct oo.ip_address, oo.ip_port, oo.roles
	from officers_online oo, sys.v_$session us
	where oo.terminal = us.terminal and oo.username = us.username and
		'DIGIBO' = substr(module, 1, 6)
        and nvl( oo.type, 'BACKOFFICE') = 'BACKOFFICE';
	fetch rv into a, p, r;
	while rv%found loop
		begin
			if rates = 1 and nvl(instr(r, 'RBORATES;'), 0) != 0 then
				c := utl_tcp.open_connection(remote_host => rsa_addr,
					remote_port => rsa_port,
					charset => 'US7ASCII');
				write_tcp(c, chr(9) || chr(1) || ';' || a || ';' || p || chr(4));
				utl_tcp.close_connection(c);
			end if;
			if pamo = 1 and nvl(instr(r, 'RBOPAMORDERSVIEW'), 0) != 0 then
				c := utl_tcp.open_connection(remote_host => rsa_addr,
					remote_port => rsa_port,
					charset => 'US7ASCII');
				write_tcp(c, chr(9) || chr(3) || ';' || a || ';' || p || chr(4));
				utl_tcp.close_connection(c);
			end if;
			if secure = 1 and nvl(instr(r, 'RBOSECORDERS'), 0) != 0 then
				c := utl_tcp.open_connection(remote_host => rsa_addr,
					remote_port => rsa_port,
					charset => 'US7ASCII');
				write_tcp(c, chr(9) || chr(5) || ';' || a || ';' || p || chr(4));
				utl_tcp.close_connection(c);
			end if;
			if margin = 1 and nvl(instr(r, 'RBOMARGINORDERS'), 0) != 0 then
				c := utl_tcp.open_connection(remote_host => rsa_addr,
					remote_port => rsa_port,
					charset => 'US7ASCII');
				write_tcp(c, chr(9) || chr(6) || ';' || a || ';' || p || chr(4));
				utl_tcp.close_connection(c);
			end if;
			fetch rv into a, p, r;
		exception
			when others then null;
		end;
	end loop;
	close rv;
end;

procedure notify_workstations(
	officer in integer
) is
	rv cursor_t;
	a officers_online.ip_address%type;
	p officers_online.ip_port%type;
	r officers_online.roles%type;
	c utl_tcp.connection;
	rsa_addr varchar2(64);
	rsa_port integer;
begin
	select value1, value2
	into rsa_addr, rsa_port
	from digibo_parameters
	where name = 'NOTIFY_SERVER';

	open rv for select distinct oo.ip_address, oo.ip_port, oo.roles
	from officers_online oo, sys.v_$session us
	where oo.officer_id = officer and
		oo.terminal = us.terminal and
		oo.username = us.username and
		'DIGIBO' = substr(module, 1, 6)
        and nvl( oo.type, 'BACKOFFICE') = 'BACKOFFICE';
	fetch rv into a, p, r;
	while rv%found loop
		begin
			c := utl_tcp.open_connection(remote_host => rsa_addr,
				remote_port => rsa_port,
				charset => 'US7ASCII');
			write_tcp(c, chr(9) || chr(7) || ';' || a || ';' || p || chr(4));
			utl_tcp.close_connection(c);
			fetch rv into a, p, r;
		exception
			when others then null;
		end;
	end loop;
	close rv;
end;

function get_last_rates_timestamp return date is
	t date;
begin
	select max(rate_timestamp) into t from glb_currency_rates;
	return t;
exception when no_data_found then
	return null;
end;

procedure notify_rates_board is
	rates integer := 0;
	dr date := null;
	d date;
begin
	begin
		select to_date(value1, 'yyyymmddhh24miss')
		into dr
		from digibo_parameters
		where name = 'NOTIFY_BOARD';
	exception 
		when others then null;
	end;
	d := get_last_rates_timestamp;
	if dr is null or d > dr then
		dr := d;
		notify_workstations(1, 0, 0, 0);
		update digibo_parameters
		set value1 = to_char(dr, 'yyyymmddhh24miss')
		where name = 'NOTIFY_BOARD';
		commit;
	end if;
end;

procedure notify_ffo is
	ffo integer := 0;
	df date := null;
	d date;
	t integer;
	u integer;
	o integer;
	r integer;
	l documents.from_location%type;
	rv cursor_t;
begin
	begin
		select to_date(value1, 'yyyymmddhh24miss')
		into df
		from digibo_parameters
		where name = 'NOTIFY_FFO';
	exception 
		when others then null;
	end;
	open rv for select id, order_date, from_customer, from_location from documents
		where status_id = 5 and
			class_id = 6 and
			order_date > df;
	fetch rv into t, d, u, l; -- from now u means customer_id.
	while rv%found loop
		ffo := 1;
		if d > df then
			df := d;
		end if;
		begin
			r := null;
			begin
				select bo.id into o from officers bo, cusd c
				where c.id = u and
					bo.DEPT_ACCNT_OFFICER_ID =
						c.remote_officers.get_id(l);
				select replaced_by into r from officer_replacement
				where officer_id = o;
			exception when NO_DATA_FOUND then
				null;
			end;
			if r is not null then
				o := r;
			end if;
			notify_workstations(o);
		exception when NO_DATA_FOUND then
			null;
		end;
		fetch rv into t, d, u, l;
	end loop;
	close rv;
	if ffo = 1 then
		update digibo_parameters
		set value1 = to_char(df, 'yyyymmddhh24miss')
		where name = 'NOTIFY_FFO';
	end if;
end;

procedure notify_investment is
	pamo integer := 0;
	secure integer := 0;
	margin integer := 0;
	dp date := null;
	dm date := null;
	ds date := null;
	d date;
	t integer;
	rv cursor_t;
begin
	begin
		select to_date(value1, 'yyyymmddhh24miss')
		into dp
		from digibo_parameters
		where name = 'NOTIFY_PAM';
	exception 
		when others then null;
	end;
	begin
		select to_date(value1, 'yyyymmddhh24miss')
		into ds
		from digibo_parameters
		where name = 'NOTIFY_SECURE';
	exception 
		when others then null;
	end;
	begin
		select to_date(value1, 'yyyymmddhh24miss')
		into dm
		from digibo_parameters
		where name = 'NOTIFY_MARGIN';
	exception 
		when others then null;
	end;
	open rv for select class_id, max(order_date) from documents
		where status_id = 13 and 
			class_id in (300, 303, 301, 304, 305, 306, 302, 307, 310)
		group by class_id;
	fetch rv into t, d;
	while rv%found loop
		if t in (300, 303) then
			if dp is null or d > dp then
				pamo := 1;
				dp := d;
			end if;
		elsif t in (301, 304, 305, 306) then
			if ds is null or d > ds then
				secure := 1;
				ds := d;
			end if;
		elsif t in (302, 307, 310) then
			if dm is null or d > dm then
				margin := 1;
				dm := d;
			end if;
		end if;
		fetch rv into t, d;
	end loop;
	close rv;
	notify_workstations(0, pamo, secure, margin);
	if pamo = 1 then
		update digibo_parameters
		set value1 = to_char(dp, 'yyyymmddhh24miss')
		where name = 'NOTIFY_PAM';
	end if;
	if secure = 1 then
		update digibo_parameters
		set value1 = to_char(ds, 'yyyymmddhh24miss')
		where name = 'NOTIFY_SECURE';
	end if;
	if margin = 1 then
		update digibo_parameters
		set value1 = to_char(dm, 'yyyymmddhh24miss')
		where name = 'NOTIFY_MARGIN';
	end if;
end;

procedure notify_mortgage_loans is
	order_id integer := 0;
	message_id integer := 0;
	max_order_id integer := 0;
	max_message_id integer := 0;
	count_id integer := 0;
	cust_id integer := 0;
	body varchar2(4000) := '';
	email officers.email%type;
	login officers.login%type;
	name ibglb.cusd.name.name_en%type;
	recipients varchar2_table_type := varchar2_table_type();
	rv cursor_t;

	procedure mail(recipient in varchar2, body in varchar2) is
		c UTL_SMTP.CONNECTION;
 
		procedure send_header(name IN VARCHAR2, header IN VARCHAR2) AS
		begin
			UTL_SMTP.WRITE_DATA(c, name || ': ' || header || UTL_TCP.CRLF);
		end;
 
	begin
		c := UTL_SMTP.OPEN_CONNECTION('mail.parex.lv');
		UTL_SMTP.HELO(c, 'parex.lv');
		UTL_SMTP.MAIL(c, '<digi@parex.lv>');
		UTL_SMTP.RCPT(c, '<' || recipient || '>');
		UTL_SMTP.OPEN_DATA(c);
		send_header('From', '"Sender" <digi@parex.lv>');
		send_header('To', '"Recipient" <' || recipient || '>');
		send_header('Content-Type', 'text/html; charset=UTF-8; format=flowed');
		send_header('Subject', 'Jauns hipotekara kredita pieteikumi/zinojumi.');
		UTL_SMTP.WRITE_DATA(c, UTL_TCP.CRLF || body);
		UTL_SMTP.CLOSE_DATA(c);
		UTL_SMTP.QUIT(c);
	exception
		when others then
			UTL_SMTP.QUIT(c);
	end;

	procedure mail(body in varchar2) is
	begin
		if recipients.count > 0 then
			for i in recipients.first .. recipients.last loop
				mail(recipients(i), body);
			end loop;
		end if;
		mail('digi@parex.lv', body);
	end;

	function permitted(pGrantee in varchar2) return boolean is
		cursor rv is
			select distinct granted_role
			from sys.dba_role_privs
			where grantee = upper(pGrantee) and granted_role like 'RBO%';
	begin
		if upper('RBOMortgLoanOrdersEdit') = upper(pGrantee) then
			return true;
		end if;
		for rec in rv loop
			if permitted(rec.granted_role) then
				return true;
			end if;
		end loop;
		return false;
	end;

begin
	open rv for select o.login login, o.email email
		from (select upper(login) login, email from officers) o, sys.dba_users u
		where o.login = u.username and
			o.email is not null and
			(instr(u.account_status, 'OPEN') = 1 or instr(u.account_status, 'GRACE') > 0) and
			(instr(o.email, 'parex.lv', -1) = length(o.email) - length('parex.lv') + 1);
	fetch rv into login, email;
	while rv%found loop
		if permitted(login) then
			recipients.extend;
			recipients(recipients.count) := email;
		end if;
		fetch rv into login, email;
	end loop;
	close rv;
	if recipients.count = 0 then
		return;
	end if;
	begin
		select nvl(value1, 0), nvl(value2, 0)
		into order_id, message_id
		from digibo_parameters
		where name = 'NOTIFY_MLOAN';
	exception 
		when others then null;
	end;
	open rv for select id, from_customer from documents where
		status_id in (RBA_CONST.MANUAL_PROCESSING_STARTED, RBA_CONST.SIGNATURE_OK) and
		class_id = RBA_CONST.MORTGAGE_LOAN and
		id > order_id;
	fetch rv into order_id, cust_id;
	body := 'Dokumenti:<br><table border=1 cellspacing=0>';
	while rv%found loop
		if order_id > max_order_id then
			max_order_id := order_id;
		end if;
		begin
			select c.name.name_en
			into name
			from ibglb.cusd c
			where c.id = cust_id;
		exception
			when others then null;
		end;

		if length( body || '<tr><td>' || order_id || '</td><td>' || cust_id || '</td><td>' || name || '</td></tr>' ) < 3700 then
			body := body || '<tr><td>' ||
				order_id || '</td><td>' ||
				cust_id || '</td><td>' ||
				name || '</td></tr>';
		end if;
		count_id := count_id + 1;
		fetch rv into order_id, cust_id;
	end loop;
	body := body || '</table><br><br>';
	close rv;
	if count_id = 1 then
		body := body ||
			'Lai apstradatu so pieteikumu,<br>' ||
			'ludzu atveriet DIGI::BackOffice un sadala<br>' ||
			'"Mortgage" nospiediet pogu "Jaunie pieteikumi".<br><br>';
	elsif count_id > 1 then
		body := body ||
			'Lai apstradatu sos pieteikumus,<br>' ||
			'ludzu atveriet DIGI::BackOffice un sadala<br>' ||
			'"Mortgage" nospiediet pogu "Jaunie pieteikumi".<br><br>';
	else
		body := '';
	end if;

	-- Messages:
	count_id := 0;
	open rv for
	select id, customer_id
	from messages
	where class_id = 404 and type = 'Q' and id > message_id;
	fetch rv into message_id, cust_id;
	while rv%found loop
		if count_id = 0 then
			body := body || 'Zinojumi:<br><table border=1 cellspacing=0>';
		end if;
		if message_id > max_message_id then
			max_message_id := message_id;
		end if;
		begin
			select c.name.name_en
			into name
			from ibglb.cusd c
			where c.id = cust_id;
		exception
			when others then null;
		end;
		if length(body || '<tr><td>' || 	message_id || '</td><td>' || cust_id || '</td><td>' || name || '</td></tr>') < 3700 then
			body := body || '<tr><td>' ||
				message_id || '</td><td>' ||
				cust_id || '</td><td>' ||
				name || '</td></tr>';
		end if;
		count_id := count_id + 1;
		fetch rv into message_id, cust_id;
	end loop;
	body := body || '</table><br><br>';
	close rv;
	if count_id = 1 then
		body := body ||
			'Lai apstradatu so zinojumu,<br>' ||
			'ludzu atveriet DIGI::BackOffice un sadala<br>' ||
			'"Zinojumi" nospiediet pogu "Mani jaunie zinojumi".<br><br>';
	elsif count_id > 1 then
		body := body ||
			'Lai apstradatu sos zinojumus,<br>' ||
			'ludzu atveriet DIGI::BackOffice un sadala<br>' ||
			'"Zinojumi" nospiediet pogu "Mani jaunie zinojumi".<br><br>';
	end if;
	--

	if max_order_id > 0 or max_message_id > 0 then
		mail(body);
		if max_order_id > 0 then
			update digibo_parameters
			set value1 = max_order_id
			where name = 'NOTIFY_MLOAN';
		end if;
		if max_message_id > 0 then
			update digibo_parameters
			set value2 = max_message_id
			where name = 'NOTIFY_MLOAN';
		end if;
	end if;
end;

procedure get_plain_roles(
	pGrantee in varchar2,
	pResult in out varchar2
) is
	cursor rv is
		select distinct granted_role
		from sys.dba_role_privs
		where grantee = upper(pGrantee) and granted_role like 'RBO%';
begin
	for rec in rv loop
		if nvl(instr(pResult, rec.granted_role || ';'), 0) = 0 then
			pResult := pResult || rec.granted_role || ';';
			get_plain_roles(rec.granted_role, pResult);
		end if;
	end loop;
end;

function get_officer_plain_roles(pGrantee in varchar2) return varchar2 is
	rv varchar2(4000) := '';
begin
	get_plain_roles(pGrantee, rv);
	return trim(rv);
end;

procedure refresh_officers_and_roles is
	officers num_table_type := num_table_type();

	cursor c1 is select distinct
		c.remote_officers.company_1 company_1,
		c.remote_officers.company_2 company_2,
		c.remote_officers.company_3 company_3,
		c.remote_officers.company_4 company_4,
		c.remote_officers.company_5 company_5,
		c.remote_officers.company_6 company_6,
		c.remote_officers.company_7 company_7,
		c.remote_officers.company_8 company_8,
		c.remote_officers.company_9 company_9,
		c.remote_officers.company_10 company_10
	from ibglb.cusd c
	where c.is_visible != 0 and (
		c.remote_officers.company_1 is not null or
		c.remote_officers.company_2 is not null or
		c.remote_officers.company_3 is not null or
		c.remote_officers.company_4 is not null or
		c.remote_officers.company_5 is not null or
		c.remote_officers.company_6 is not null or
		c.remote_officers.company_7 is not null or
		c.remote_officers.company_8 is not null or
		c.remote_officers.company_9 is not null or
		c.remote_officers.company_10 is not null
	);

	r1 c1%rowtype;

	cursor c2 is select /*+INDEX (o UNQ_OFCR_LOGIN) */
		o.id id,
		o.dept_accnt_officer_id dept_accnt_officer_id,
		nvl(o.name, o.login) name,
		o.login login
	from ib.officers o, sys.dba_users u
	where o.login is not null and u.username = o.login;

	r2 c2%rowtype;

	attached integer := 0;

	roles varchar2(4000) := '';
begin
	for r1 in c1 loop
		if r1.company_1 is not null then
			officers.extend;
			officers(officers.count) := r1.company_1;
		end if;
		if r1.company_2 is not null then
			officers.extend;
			officers(officers.count) := r1.company_2;
		end if;
		if r1.company_3 is not null then
			officers.extend;
			officers(officers.count) := r1.company_3;
		end if;
		if r1.company_4 is not null then
			officers.extend;
			officers(officers.count) := r1.company_4;
		end if;
		if r1.company_5 is not null then
			officers.extend;
			officers(officers.count) := r1.company_5;
		end if;
		if r1.company_6 is not null then
			officers.extend;
			officers(officers.count) := r1.company_6;
		end if;
		if r1.company_7 is not null then
			officers.extend;
			officers(officers.count) := r1.company_7;
		end if;
		if r1.company_8 is not null then
			officers.extend;
			officers(officers.count) := r1.company_8;
		end if;
		if r1.company_9 is not null then
			officers.extend;
			officers(officers.count) := r1.company_9;
		end if;
		if r1.company_10 is not null then
			officers.extend;
			officers(officers.count) := r1.company_10;
		end if;
	end loop;

	delete from officers_and_roles;

	for r2 in c2 loop
		roles := get_officer_plain_roles(r2.login);
		attached := 0;
		for i in officers.first .. officers.last loop
			if r2.dept_accnt_officer_id = officers(i) then
				attached := 1;
				exit;
			end if;
		end loop;
		insert into officers_and_roles fields (
			id, attached, name, login, roles
		)
		values (
			r2.id, attached, r2.name, r2.login, roles
		);
	end loop;
end;

procedure update_bo_permissions is
	updated date;  -- time of BO operation.
	executed date; -- last execution job started.
begin
	begin
		select to_date(value1, 'yyyymmddhh24miss'), to_date(value2, 'yyyymmddhh24miss')
		into updated, executed
		from digibo_parameters
		where name = 'UPDATE_PERMISSIONS';
	exception 
		when others then null;
	end;
	if updated is not null and (executed is null or updated > executed) then
		update digibo_parameters
		set value2 = to_char(sysdate, 'yyyymmddhh24miss')
		where name = 'UPDATE_PERMISSIONS';
		commit;
		refresh_officers_and_roles();
	end if;
end;

end;
/
show err;
