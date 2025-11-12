CREATE OR REPLACE package BOFaxFind as

type cursor_t is ref cursor;

-- Original faxes.

function find(
	pFaxId in varchar2,
	pFromFax in varchar2,
	pFromCSid in varchar2,
	pFaxStatus in number,
	pRecvTimeFrom in number,
	pRecvTimeTo in number
) return cursor_t;

function find_new return cursor_t;

end;
/

show err;

CREATE OR REPLACE package body BOFaxFind as

function find_new return cursor_t is
	rv cursor_t;
begin
	open rv for select /* BOFaxFind.find_new */
		f.sid faxId,
		f.from_fax fromFax,
		f.from_csid fromCSid,
		f.receive_time recvTime,
		f.receive_status recvStatus,
		f.status_id faxStatus
	from fax f
	where rownum <= bocommon.ResultSetSize
		and f.status_id = 1;
	return rv;
end;

function find_by_id(
	pFaxId in varchar2
) return cursor_t is
	rv cursor_t;
begin
	open rv for select /* BOFaxFind.find_by_id */
		f.sid faxId,
		f.from_fax fromFax,
		f.from_csid fromCSid,
		f.receive_time recvTime,
		f.receive_status recvStatus,
		f.status_id faxStatus
	from fax f
	where f.sid = pFaxId;
	return rv;
end;

function find_by_filter(
	pFromFax in varchar2,
	pFromCSid in varchar2,
	pFaxStatus in number,
	pRecvTimeFrom in number,
	pRecvTimeTo in number
) return cursor_t is
	rv cursor_t;
begin
	open rv for select /* BOFaxFind.find_by_filter */
		f.sid faxId,
		f.from_fax fromFax,
		f.from_csid fromCSid,
		f.receive_time recvTime,
		f.receive_status recvStatus,
		f.status_id faxStatus
	from fax f
	where rownum <= bocommon.ResultSetSize
		and (pFromFax is null or upper(from_fax) like bocommon.prepare_like(pFromFax))
		and (pFromCSid is null or upper(from_csid) like bocommon.prepare_like(pFromCSid))
		and (pFaxStatus = 0 or status_id = pFaxStatus)
		and (pRecvTimeFrom = 0 or receive_time between pRecvTimeFrom and pRecvTimeTo);
	return rv;
end;

function find(
	pFaxId in varchar2,
	pFromFax in varchar2,
	pFromCSid in varchar2,
	pFaxStatus in number,
	pRecvTimeFrom in number,
	pRecvTimeTo in number
) return cursor_t is
begin
	if pFaxId is not null then
		return find_by_id(pFaxId);
	end if;
	return find_by_filter(
		pFromFax,
		pFromCSid,
		pFaxStatus,
		pRecvTimeFrom,
		pRecvTimeTo
	);
end;

end;
/

show err;
