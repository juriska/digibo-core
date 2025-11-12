CREATE OR REPLACE package IB.BODocuments as

type cursor_t is ref cursor;

function history(pId in varchar2) return cursor_t;
function messageHistory(pId in varchar2) return cursor_t;

function set_lock(
	pId in varchar2,
	pStatus out integer,
	pOfficerName out varchar2,
	pOfficerPhone out varchar2
) return integer;

procedure set_manual_status(
	pId in varchar2,
	reason in varchar2,
	pNewStatus in integer,
	pMessageId in integer
);

procedure set_manual_status_1(
    pId in varchar2,
    reason in varchar2,
    pNewStatus in integer,
    pMessageId in integer
    , pBankRefference in varchar2
);
procedure signOwner(
	certId in varchar2,
	signDate in date,
	uName out varchar2,
	legalId out varchar2
);

function get_addr(pId in varchar2) return cursor_t;
function get_extensions(pId in varchar2) return cursor_t;

-- procedure get_officers(officers_id out num_table_type);
procedure get_remote_officers(dept_id out num_table_type);
function get_remote_officer(officer_id in integer) return integer;
function get_ib_signatures(pDocId in varchar2) return cursor_t;
function set_ManualProcessing(pId in varchar2) return integer;
function getChangeOfficerId(pId in varchar2) return integer;
function get_by_id(
    pId in number,
    pStatus out integer,
    pOfficerID out number,
    pITC out varchar2
) return integer;
end;
/
