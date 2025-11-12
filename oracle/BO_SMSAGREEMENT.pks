CREATE OR REPLACE package IB.BOSMSAgreement as

type cursor_t is ref cursor;

DOC_RIGHTS_ALL_ACCOUNTS_LEVEL constant int := 11;
DOC_RIGHTS_CURRENCY_LEVEL constant int := 14;
DOC_RIGHTS_CARD constant int := 82;

function get_operators return cursor_t;

function get_accounts(
	pCustId in varchar2,
	pLocation in varchar2
) return cursor_t;

function get_logins(
	pUserId in number,
    pCustId in number,
	pLocation in varchar2
) return cursor_t;

function load_rights_1(
	pWocId in number,
	pCustId in number,
	pLocation in varchar2
) return cursor_t;

function load_rights_2(
	pWocId in number,
	pCustId in number,
	pLocation in varchar2
) return cursor_t;

function load_card_rights(
	pWocId in number,
	pCustId in number,
	pLocation in varchar2
) return cursor_t;

procedure load_channel(
	pWocId in varchar2,
	pLogin out varchar2,
	pOperator out number,
	pChargesAcc out number,
	pParentId out varchar2,
	pLanguage out number,
	pSellerId out number,
	pDistribCenterId out number,
	pFfSMS out integer
    , pPassword out varchar2
    , pHasDefault out integer
    , pSmsTime out varchar2
);

function check_login(
	pLogin in varchar2
) return number;

function get_login_count(
    pLogin in varchar2
) return number;

function login_for_customer_exists(
    pWocId in number,
    pCustId in number,
    pLocation in varchar2,
    pLogin in varchar2
) return number;

end;
/
