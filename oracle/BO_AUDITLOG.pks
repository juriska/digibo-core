CREATE OR REPLACE package IB.BOAuditLog as

type cursor_t is ref cursor;

function find(
	dfrom in date,
	dto in date,
	events in varchar2,
	pObject in varchar2,
	pOriginator in varchar2,
	pChannels in varchar2,
	pResultSetSize in number
) return cursor_t;

function findSession(pSession in varchar2) return cursor_t;

function get_tree return cursor_t;

end;
/
