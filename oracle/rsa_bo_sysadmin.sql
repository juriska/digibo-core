CREATE OR REPLACE package bosysadmin as

type cursor_t is ref cursor;

function get_officers(
	pLogin in varchar2,
	pName in varchar2
) return cursor_t;

end;
/
show err;

CREATE OR REPLACE package body bosysadmin as

function get_officers(
	pLogin in varchar2,
	pName in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		null officerId,
		u.username login,
		null userName,
		null regDate,
		null phone,
		u.username oraUser,
		u.account_status status,
		null replacedBy 
	from sys.dba_users u
	where (pLogin is null or
		upper(u.username) like bocommon.prepare_like(pLogin));
	return rv;
end;

end;
/
show err;
