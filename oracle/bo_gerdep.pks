CREATE OR REPLACE package IB.BOGERDEP as

USER_SESSION_TIMEOUT constant int := 30;

type cursor_t is ref cursor;

function find_new return cursor_t;

function find_by_filter(
    pDocId in varchar2,
    pCustId in varchar2,
    pCustName in varchar2,
    pIdDocNo in varchar2,
    pLogin in varchar2,
    pStatus in varchar2,
    pOrderDateFrom in date,
    pOrderDateTo in date
) return cursor_t;
function select_customer(
    pCustId in varchar2,
    pRv out number
) return cursor_t;
procedure bind_to_customer(
    pDocId in varchar2,
    pCustId in varchar2
);
procedure account_exists(
    pDocId in varchar2,
    pAccExists out varchar2
);
procedure create_user(
    pDocId in varchar2,
    pTanCardId in varchar2
);
procedure reject(
    pDocId in varchar2,
    pReason in varchar2
);

end;
/
