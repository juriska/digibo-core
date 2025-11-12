CREATE OR REPLACE package IB.BORequestToPay as

type cursor_t is ref cursor;

function find(
	-- remitter
	custId in varchar2,
	custName in varchar2,
	userLogin in varchar2,
	officerId in integer,

	-- payment
	benName in varchar2,
	fromContract in varchar2,
	fromLocation in varchar2,
	pmtDetails in varchar2,
	amountFrom in varchar2,
	amountTill in varchar2,
	currencies in varchar2,
	pmtClass in varchar2,
	effectFrom in date,
	effectTill in date,

	-- system
	paymentId in varchar2,
	cbPaymentId in varchar2,
	channels in varchar2,
	statuses in varchar2,
	createdFrom in date,
	createdTill in date
) return cursor_t;

end;
/
