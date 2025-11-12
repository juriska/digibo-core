CREATE OR REPLACE package IB.BOHelpDesk as

type cursor_t is ref cursor;

function find_user_channel(
	pLogin in varchar2,
	pAuthDev in varchar2,
	pUserName in varchar2,
	pPersonalId in varchar2
) return cursor_t;

function load_log(
	pUserId in varchar2,
	pWocId in varchar2
) return cursor_t;

function set_password(
	pChannelId in varchar2,
	pUserId in varchar2,
	pPassword in varchar2
) return integer;

function load_user_channel(
	pId in out number,
	pLogin out varchar2,
	pAuthDev out varchar2,
	pStatus out number,
	pSubStatus out number,
	pUserId out varchar2,
	pUserName out varchar2,
	pPersonalId out varchar2,
	pPhone out varchar2,
	pMobile out varchar2,
	pFax out varchar2,
	pEmail out varchar2,
	pStreet out varchar2,
	pCity out varchar2,
	pCountry out varchar2,
	pZip out varchar2,
	pRegDate out date,
    pPasswordChageAllowed out int
    , pHasCronto out int
    , pPassword out varchar2
) return cursor_t;

procedure load_auth_info(
	pId in out number,
	pStdQ out number,
	pSpecQ out varchar2,
	pAnswer out varchar2
);

procedure set_lock(
	pChannelId in varchar2,
	pUserId in varchar2,
	pStatus in number,
	pSubStatus in number
);

procedure reset_stolen(pChannelId in varchar2);

end;
/
