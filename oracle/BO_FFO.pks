CREATE OR REPLACE package IB.BOFFO as

type cursor_t is ref cursor;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,
	userLogin in varchar2,
	officerId in integer,

	-- document
    	docClass in varchar2,
	pSubject in varchar2,
	pText in varchar2,

	-- system
	docId in varchar2,
	channels in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date,
  assignee in integer,
  category_id in integer,
  subcategory_id in integer
) return cursor_t;

function find_my return cursor_t;

procedure ffo(
	pId in varchar2,
	userName out varchar2,
	userId out varchar2,
	officerName out varchar2,
    	goldManager out varchar2,
	custName out varchar2,
	custAccount out varchar2,
	globusNo out varchar2,
	pLocation out varchar2,
	-- ffo:
	fText out varchar2,
	--
	itc out varchar2,
	itb out varchar2,
	signTime out date,
	--signDevType out integer,
	--signDevId out varchar2,
	--signKey1 out varchar2,
	--signKey2 out varchar2,
	signRSA out varchar2,
    	sector out number,
    	segment out varchar2
);

function get_categories return cursor_t;

function categorize(pDocId in number, pCategoryId in number, pSubCategoryId in number, pAssignee in number) return integer;

function set_processing(pId in varchar2, reason in varchar2, pNewStatus in integer, pMessageId in integer) return integer;

end;
/
