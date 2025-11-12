CREATE OR REPLACE package IB.BOCustomer as

type cursor_t is ref cursor;

USER_ACCESS_SPEC_RATE constant int := 35;
USER_ACCESS_INFO2BANK constant int := 140;
USER_ACCESS_CONNECT constant int := 100;


function customer_exists(pId in varchar2) return number;

function load_user_channels(pId in varchar2) return cursor_t;

procedure load_user(
	pId in out number,
	pName out varchar2,
	pIssuerCountry out varchar2,
	pPersonalId out varchar2,
	pPassportNo out varchar2,
	pStreet out varchar2,
	pCity out varchar2,
	pCountry out varchar2,
	pZip out varchar2,
	pPhone out varchar2,
	pMobile out varchar2,
	pFax out varchar2,
	pEmail out varchar2,
	pApart out varchar2,
	pHouse out varchar2,
 	pStdQ out number,
 	pSpecQ out varchar2,
 	pAnswer out varchar2,
	pRegDate out date,
	pChangeDate out date,
	pChangeOfficerId out varchar2,
	pChangeLogin out varchar2,
	pCustomerId out number,
	pMigrStatus out number,
	pHasAgreementInGlobus out number
);

procedure load_user_old(
	pId in out number,
	pName out varchar2,
	pIssuerCountry out varchar2,
	pPersonalId out varchar2,
	pPassportNo out varchar2,
	pStreet out varchar2,
	pCity out varchar2,
	pCountry out varchar2,
	pZip out varchar2,
	pPhone out varchar2,
	pMobile out varchar2,
	pFax out varchar2,
	pEmail out varchar2,
	pApart out varchar2,
	pHouse out varchar2,
 	pStdQ out number,
 	pSpecQ out varchar2,
 	pAnswer out varchar2,
	pRegDate out date,
	pChangeDate out date,
	pChangeOfficerId out varchar2,
	pChangeLogin out varchar2,
	pCustomerId out number,
	pMigrStatus out number
);

function load_user_info(pId in number) return cursor_t;

function load_user_history(pId in number) return cursor_t;

function load_customer_tree(
	pCustId in varchar2,
	pLocation in varchar2
) return cursor_t;

function load_licenses(
	pCustId in varchar2
) return cursor_t;

function check_license(
	pId in varchar2
) return number;

function check_login(
	pUserId in number,
	pLogin in varchar2,
	pLicense in varchar2,
	pChannelId in number
) return number;

function check_pswd_num(pPswdNum in varchar2) return number;


function check_sign_level(
	pCustId number,
	pWocId number,
	pCertId varchar2,
	pLevel varchar2
) return number;

function load_users(
	pCustId in varchar2,
	pChannel in number,
	pLicense in varchar2,
	pLocation in varchar2
) return cursor_t;

procedure load_channel(
	pWocId in varchar2,
	pCustId in varchar2,
	pCDevType out number,
	pCDevNum out varchar2,
	pSellerId out number,
	pDistribCenterId out number,
	pLevel out number,
	pTmpLevel out number,
	pChangeOfficer out varchar2,
	pSpecRate out number,
	pInfo2Bank out number,
	pDFAccessRight out number
    
);

procedure fill_full_history(
	pId in number,
	pChannel in number
);

function load_full_history return cursor_t;

procedure load_channel_info(
	pId in number, -- woc history ID
	pCustId in number,
	pLicense out varchar2,
	pLogin out varchar2,
	pUserName out varchar2,
	pPersonalId out varchar2,
	pCountry out varchar2,
	pCDevType out number,
	pCDevNum out varchar2,
	pIbRights out varchar2,
	pStatus out number,
	pSignLevel out number,
	pSignLevelTmp out number,
	pDocRights out cursor_t
);

function load_user_wocs(
	pUserId in number,
	pLicense in varchar2
) return cursor_t;

function load_rights(
	pWocId in number,
	pCustId in number,
	pLocation in varchar2
) return cursor_t;

function load_binded_customers(
	pWocId in number,
	pCustId in number,
	pLocation in varchar2
) return cursor_t;

procedure load_channel_history(
	pId in number, -- woc history ID
	pCustId in number,
	pLicense out varchar2,
	pLogin out varchar2,
	pUserName out varchar2,
	pPersonalId out varchar2,
	pCountry out varchar2,
	pCDevType out number,
	pCDevNum out varchar2,
	pIbRights out varchar2,
	pStatus out number,
	pSignLevel out number,
	pSignLevelTmp out number,
	pDocRights out cursor_t
);

end;
/
