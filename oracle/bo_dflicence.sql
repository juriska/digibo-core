CREATE OR REPLACE package bodflicence as

-- backoffice 4.x.x

type cursor_t is ref cursor;

procedure new_license(pId in varchar2);
function get_licences(pCount in integer) return cursor_t;
procedure print_licence(pId in varchar2);

end;
/
show err;

CREATE OR REPLACE package body bodflicence as

procedure new_license(pId in varchar2) is
begin
	insert into licenses(id, status, change_date, change_officer_id)
	values (pId, 'G', SysDate, 0);
end;

function get_licences(pCount in integer) return cursor_t is
	rv cursor_t;
begin
	open rv for select id
	from licenses l
	where l.status = 'G' and rownum <= pCount
	order by change_date;
	return rv;
end;

procedure print_licence(pId in varchar2) is
begin
	update licenses l set
		status ='P',
		change_date = SysDate,
		change_officer_id = bocommon.officerId
	where l.id = pId;
end;

end;
/
show err;
