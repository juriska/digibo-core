CREATE OR REPLACE package IB.BOFindCustomers as

type cursor_t is ref cursor;

function find_customers(
	pCustId in varchar2,
	pCustName in varchar2,
	pLegalId in varchar2,
	pLicence in varchar2
) return cursor_t;

procedure load_customer_by_id(
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
    pType out varchar2,
    pHasAgreementInGlobus out number
);

end;
/
