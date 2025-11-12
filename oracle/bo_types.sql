C:\projects\win32GIT\digibo\bin\oracle\bo_types.sqlcreate or replace type num_table_type as table of number;
/
create or replace type varchar2_table_type as table of varchar2(1024);
/
create or replace type varchar2_loc_type as table of varchar2(2);
/

drop type customer_set_t;
drop type customer_t;
drop type audit_log_set_t;
drop type audit_log_t;
drop type helpdesk_log_set_t;
drop type helpdesk_log_t;
drop type payments_set_t;
drop type payment_t;
drop type req_to_pay_set_t;
drop type req_to_pay_t;
drop type ffo_set_t;
drop type ffo_t;
drop type message_set_t;
drop type message_t;
drop type card_message_set_t;
drop type card_message_t;
drop type broker_set_t;
drop type insurance_set_t;
drop type broker_t;
drop type insurance_t;
drop type margin_set_t;
drop type margin_t;
drop type cq_set_t;
drop type cq_t;
drop type dd_set_t;
drop type dd_t;
drop type dr_set_t;
drop type cronto_set_t;
drop type cronto_t;
drop type dr_t;
drop type mloan_set_t;
drop type mloan_t;
drop type smsdoc_set_t;
drop type smsdoc_t;
drop type helpdesk_set_t;
drop type helpdesk_t;
drop type user_set_t;
drop type user_t;
drop type sms_message_set_t;
drop type sms_message_t;
drop type cru_set_t;
drop type cru_t;
drop type otse_set_t;
drop type otse_t;
drop type custody_set_t;
drop type custody_t;
drop type accadmin_set_t;
drop type accadmin_t;
drop type prodkit_set_t;
drop type prodkit_t;
drop type amexorder_set_t;
drop type amexorder_t;
drop type capf_set_t;
drop type capf_t;
drop type leaseweb_set_t;
drop type leaseweb_t;
drop type credliminc_set_t;
drop type credliminc_t;
drop type lifeandpension_set_t;
drop type lifeandpension_t;
drop type fiaccopen_set_t;
drop type fiaccopen_t;
drop type LeaseApplications_set_t;
drop type LeaseApplications_t;

create or replace type audit_log_t as object (
	id number(14),             -- audit_log.id
	session_no number(14),     -- session_log.id == audit_log.session_id
	time_stamp date,           -- audit_log.event_date
	machine varchar2(64),      -- session_log.ip_address
	orig_user varchar2(60),    -- ways_of_connection.login
	orig_officer varchar2(20), -- officers.login
	obj_user varchar2(60),     -- ways_of_connection.login
	obj_officer varchar2(20),  -- officers.login
	doc_info varchar2(64),     -- documents.document_number + acsd.iban + acsd.ccy
	details varchar2(2000),    -- audit_log.details
	channel number(2),         -- session_log.channel_id
	eventName varchar2(211),   -- audit_log.event_type_id + event_types.name
	eventGroup varchar2(211),  -- audit_log.event_type_id + event_types.name
	uv number(1),              -- event_types.cust_visible
	doc_id number(14),         -- audit_log.payment_id
	class_id number(5),        -- applications.class_id or documents.class_id
	fax_class_id number(2),    -- fax_doc_history.class_id
	user_id number(10),        -- audit_log.user_child_id
	message_id number(9),      -- audit_log.message_id
	sl_woc_id number(10),      -- session_log.woc_id
	al_woc_id number(10),      -- audit_log.woc_child_id
	sl_user_id number(10),     -- session_log.user_id
	event_type_id number(10),   -- audit_log.event_type_id
	storm_project char(4)      -- session_log.storm_project
);
/

show err;

create or replace type audit_log_set_t is table of audit_log_t;
/

show err;

create or replace type helpdesk_log_t as object (
	id number(14),             -- audit_log.id
	eventId number(10),        -- audit_log.event_type_id
	eventDate date,            -- audit_log.event_date
	eventName varchar2(211),   -- audit_log.event_type_id + event_types.name
	eventGroup varchar2(211),  -- audit_log.event_type_id + event_types.name
	details varchar2(2000),    -- audit_log.details
	officer varchar2(70),      -- officers.name
	host varchar2(64),         -- session_log.ip_address
	sessionId number(14)       -- session_log.id == audit_log.session_id
);
/

show err;

create or replace type helpdesk_log_set_t is table of helpdesk_log_t;
/

show err;

create or replace type customer_t as object (
	id number(10),
	name_en varchar2(200),
	name_lv varchar2(200),
	name_ru varchar2(200),
	name_de varchar2(200),
	name_se varchar2(200),
	name_ee varchar2(200),
	legal_id varchar2(20),
	is_visible number(1),
	location varchar2(2),
	inet integer,
	df integer,
	sms integer
);
/

show err;

create or replace type customer_set_t is table of customer_t;
/

show err;

create or replace type payment_t as object (
	id number(14),
	class_id number(3),
	status_id number(2),
	order_date date,
	document_number varchar2(16),
	creator_channel_id number(2),
	credit_amount varchar2(32),
	debit_amount varchar2(32),
	credit_ccy varchar2(3),
	debit_ccy varchar2(3),
	itb integer, -- length(documents.info_to_bank)
	login varchar2(60),
	woc_id number(10)
	, sector number(5)
	, segment varchar2(32)
	, fromLocation varchar2(30)
);
/

show err;

create or replace type payments_set_t is table of payment_t;
/

create or replace type req_to_pay_t as object (
	id number(14),
	class_id number(3),
	status_id number(2),
	order_date date,
	document_number varchar2(16),
	creator_channel_id number(2),
	credit_amount varchar2(32),
	debit_amount varchar2(32),
	credit_ccy varchar2(3),
	debit_ccy varchar2(3),
	itb integer, -- length(documents.info_to_bank)
	login varchar2(60),
	woc_id number(10)
	, sector number(5)
	, segment varchar2(32)
	, fromLocation varchar2(30)
	, cb_payment_id varchar2(64)
	, details varchar2(402)
	, from_account varchar2(32)
	
);
/

show err;

create or replace type req_to_pay_set_t is table of req_to_pay_t;
/

show err;

create or replace type ffo_t as object (
	id number(14),
	class_id number(4),
	status_id number(2),
	order_date date,
	document_number varchar2(16),
	creator_channel_id number(2),
	login varchar2(60),
	ff_subject varchar2(105)
	, woc_id number(14)
	, glb_cust_id number(10)
	, sector number(5)
	, segment varchar2(32)
	, isDocumentAttached number(2)
	, category_id number(9)
	, subcategory_id number(9)
	, category_name varchar2(50)
	, subcategory_name varchar2(50)
	, assignee number(9)
	, document_attached number(1)
);
/

show err;

create or replace type ffo_set_t is table of ffo_t;
/

show err;

create or replace type message_t as object (
	msgId number(9),
	wocId number(10),
	channel number(2),
	postDate date,
	login varchar2(60),
	message varchar2(100), -- substr(m.body, 1, 50) --changed from 50 to 100
	officerId number(10),
	status number(2),
	classId number(3)
	, sector number(5)
	, segment varchar2(32)
	, is_employee varchar2(32)
);
/

show err;

create or replace type message_set_t is table of message_t;
/

show err;

create or replace type card_message_t as object (
	pId number(14),
	class number(4),
	status number(2),
	cortex_status number(1), -- documents.card_cortex_proc_success
	created date,
	docNumber varchar2(16),
	login varchar2(60),
	subject varchar2(19), -- documents.card_pan
	country varchar2(2) -- customers.country
	, overdraft_amount number(15,3)
	, segment varchar2(32)
	, processedBy number(10) -- p.change_officer_id
	, fromLocation varchar2(30)
);
/

show err;

create or replace type card_message_set_t is table of card_message_t;
/

show err;

-- Also this object is used in BOPAMO.
create or replace type broker_t as object (
	pId number(14),
	class number(3),
	status number(2),
	created date,
	docNumber varchar2(16),
	channel number(2),
	login varchar2(60),
	isinCode varchar2(12),
	operation varchar2(10)
);
/

show err;

create or replace type broker_set_t is table of broker_t;
/

create or replace type insurance_t as object (
	id number(14),
	class_id number(3),
	status_id number(2),
	order_date date,
	document_number varchar2(16),
	creator_channel_id number(2),
	login varchar2(60),
	woc_id number(14),
	glb_cust_id number(10),
	fromLocation varchar2(30),
	typeEnum varchar2(30),
	step varchar2(30)
);
/

show err;

create or replace type insurance_set_t is table of insurance_t;
/

show err;

create or replace type margin_t as object (
	pId number(14),
	class number(3),
	status number(2),
	created date,
	docNumber varchar2(16),
	channel number(2),
	login varchar2(60),
	operation varchar2(10)
);
/

show err;

create or replace type margin_set_t is table of margin_t;
/

show err;

create or replace type cq_t as object (
	pId number(14),
	class number(3),
	status number(2),
	created date,
	docNumber varchar2(16),
	channel number(2),
	login varchar2(60)
);
/

show err;

create or replace type cq_set_t is table of cq_t;
/

show err;

-- Also this object is used in BOSTO.
create or replace type dd_t as object (
	pId number(14),
	status number(2),
	class number(4),
	created date,
	docNumber varchar2(16),
	login varchar2(60),
	itb integer, -- length(documents.info_to_bank)
	cr_amount varchar2(32),
	db_amount varchar2(32),
	cr_ccy varchar2(3),
	db_ccy varchar2(3)
);
/

create or replace type dd_set_t is table of dd_t;
/

-- Also this object is used in CRONTO.
create or replace type cronto_t as object (
	pId number(14),
	status number(2),
	class number(4),
	created date,
	docNumber varchar2(16),
	login varchar2(60),
	itb integer, -- length(documents.info_to_bank)
	cr_amount varchar2(32),
	db_amount varchar2(32),
	cr_ccy varchar2(3),
	db_ccy varchar2(3),
        processedBy number(10)
);
/

show err;

create or replace type cronto_set_t is table of cronto_t;
/

show err;

create or replace type dr_t as object (
	pId number(14),
	class_id number(3),
	status number(2),
	created date,
	docNumber varchar2(16),
	login varchar2(60),
	itb integer, -- length(documents.info_to_bank)
	db_amount varchar2(32),
	ccy varchar2(3),
	term varchar2(3), -- documents.deposit_term
	fromAccount varchar2(32)
);
/

show err;

create or replace type dr_set_t is table of dr_t;
/

show err;

create or replace type mloan_t as object (
	pId number(14),
	status number(2),
	created date,
	docNumber varchar2(16),
	login varchar2(60),
	wocId number(10),
	processedBy number(10), -- p.change_officer_id
	itc varchar2(4000) -- p.info_to_customer
	, class_id number(10)
	, fromLocation varchar2(30)
);
/

show err;

create or replace type mloan_set_t is table of mloan_t;
/

show err;

create or replace type smsdoc_t as object (
	pId number(14),
	status number(2),
	class number(3),
	created date,
	docNumber varchar2(16),
	login varchar2(60),
	mobile varchar2(35) -- p.phone_mobile
);
/

show err;

create or replace type smsdoc_set_t is table of smsdoc_t;
/

show err;

create or replace type helpdesk_t as object (
	channelId number(10), -- w.id
	login varchar2(60), -- w.login
	authDev varchar2(50), -- w.cdevice_serial_number -- bija 24
	userName varchar2(210), -- u.name
	phone varchar2(120), -- u.phone
	mobilePhone varchar2(120), -- u.mobile_phone
	personalId varchar2(35), -- u.personal_id
	userAgent varchar2(255), -- w.user_agent
	regDate date, -- u.reg_date
	status number(2), -- w.status_id
	channel number(2) -- w.channel_id
    , sms_client varchar2(255) -- SMS bank client; added 2014-09-01
);
/

show err;

create or replace type helpdesk_set_t is table of helpdesk_t;
/

show err;

create or replace type user_t as object (
	userId number(10), -- u.id
	userName varchar2(210), -- u.name
	personalId varchar2(35), -- u.personal_id
	passportNo varchar2(35), -- u.passport_no
	issuerCountry varchar2(2), -- u.issuer_country_id
	country varchar2(2), -- u.country_id
	phone varchar2(120), -- u.phone
	mobile varchar2(120), -- u.mobile_phone
	fax varchar2(120), -- u.fax
	email varchar2(129), -- u.email
	regDate date -- u.reg_date
);
/

show err;

create or replace type user_set_t is table of user_t;
/

show err;

create or replace type sms_message_t as object (
	id number(10), -- sms.messages.id
	parent_id number(10), -- sms.messages.ref_id
	status number(3), -- sms.messages.status
	io varchar2(1), -- sms.messages.class_id
	type_id number(3), -- sms.messages.type_id
	create_date date, -- sms.messages.create_date
	mobile_phone varchar2(21), -- sms.messages.source_address (dest_address)
	customer varchar2(220), -- customer name and id.
	error number(4) -- sms_owner.message_errors.code
);
/

show err;

create or replace type sms_message_set_t is table of sms_message_t;
/

show err;

create or replace type cru_t as object (
	document_id number(14),
	customer_id number(10),
	customer_name varchar2(200),
	user_name varchar2(210),
	status number(2),
	created date
);
/

show err;

create or replace type cru_set_t is table of cru_t;
/

show err;

create or replace type otse_t as object (
	id number(14),
	class_id number(3),
	status_id number(2),
	order_date date,
	name varchar2(210),
	personal_id varchar2(35),
	login varchar2(60),
	woc_id number(10),
	user_id number(10)
);
/

show err;

create or replace type otse_set_t is table of otse_t;
/

show err;

create or replace type custody_t as object (
	pId number(14),
	status number(2),
	created date,
	docNumber varchar2(16),
	login varchar2(60),
	wocId number(10),
	processedBy number(10), -- p.change_officer_id
	itc varchar2(4000) -- p.info_to_customer
	, class_id number(10)
);
/

show err;

create or replace type custody_set_t is table of custody_t;
/

show err;

create or replace type accadmin_t as object (
	pId number(14),
	status number(2),
	created date,
	docNumber varchar2(16),
	login varchar2(60),
	wocId number(10),
	processedBy number(10), -- p.change_officer_id
	itc varchar2(4000) -- p.info_to_customer
	, class_id number(10)
	, country varchar2(2)
);
/

show err;

create or replace type accadmin_set_t is table of accadmin_t;
/

show err;

create or replace type prodkit_t as object (
	pId number(14),
	status number(2),
	created date,
	docNumber varchar2(16),
	login varchar2(60),
	wocId number(10),
	processedBy number(10), -- p.change_officer_id
	itc varchar2(4000) -- p.info_to_customer
	, class_id number(10)
);
/

show err;

create or replace type prodkit_set_t is table of prodkit_t;
/

show err;

create or replace type amexorder_t as object (
	pId number(14),
	status number(2),
	created date,
	docNumber varchar2(16),
	login varchar2(60),
	wocId number(10),
	processedBy number(10), -- p.change_officer_id
	itc varchar2(4000) -- p.info_to_customer
	, class_id number(10)
    , customerName varchar2(255) -- added 2014-01-03
    , legalId varchar2(100) -- added 2014-01-03
    , form_type varchar2(100)
    , onbPhone varchar2(30)
    , onbLanguage varchar2(30) 
    , fromLocation varchar2(30) 
	
);
/

show err;

create or replace type amexorder_set_t is table of amexorder_t;
/

show err;

create or replace type capf_t as object (
	pId number(14),
	status number(2),
	created date,
	docNumber varchar2(16),
	login varchar2(60),
	wocId number(10),
	processedBy number(10), -- p.change_officer_id
	itc varchar2(4000) -- p.info_to_customer
	, class_id number(10)
    , customerName varchar2(255) -- added 2014-01-03
    , legalId varchar2(100) -- added 2014-01-03
);
/

show err;

create or replace type capf_set_t is table of capf_t;
/

show err;

create or replace type leaseweb_t as object (
	pId number(14),
	status number(2),
	created date,
	docNumber varchar2(16),
	login varchar2(60),
	wocId number(10),
	processedBy number(10), -- p.change_officer_id
	itc varchar2(4000) -- p.info_to_customer
	, class_id number(10)
    , customerName varchar2(255) -- added 2014-01-03
    , legalId varchar2(100) -- added 2014-01-03
);
/

show err;

create or replace type leaseweb_set_t is table of leaseweb_t;
/

show err;


create or replace type credliminc_t as object (
	pId number(14),
	status number(2),
	created date,
	docNumber varchar2(16),
	login varchar2(60),
	wocId number(10),
	processedBy number(10), -- p.change_officer_id
	itc varchar2(4000) -- p.info_to_customer
	, class_id number(10)
	, fromLocation varchar2(30) 
);
/
show err;
create or replace type credliminc_set_t is table of credliminc_t;
/
show err;


create or replace type lifeandpension_t as object (
	pId number(14),
	status number(2),
	created date,
	docNumber varchar2(16),
	login varchar2(60),
	wocId number(10),
	processedBy number(10), -- p.change_officer_id
	itc varchar2(4000) -- p.info_to_customer
	, class_id number(10)
	, bank_reference varchar2(115)
);
/
show err;
create or replace type lifeandpension_set_t is table of lifeandpension_t;
/
show err;

create or replace type fiaccopen_t as object (
	pId number(14),
	status number(2),
	created date,
	docNumber varchar2(16),
	login varchar2(60),
	wocId number(10),
	processedBy number(10), -- p.change_officer_id
	itc varchar2(4000) -- p.info_to_customer
	, class_id number(10)
);
/

show err;

create or replace type fiaccopen_set_t is table of fiaccopen_t;
/

show err;

create or replace type LeaseApplications_t as object (
	pId number(14),
	status number(2),
	created date,
	docNumber varchar2(16),
	login varchar2(60),
	wocId number(10),
	processedBy number(10), -- p.change_officer_id
	itc varchar2(4000) -- p.info_to_customer
	, class_id number(10)
);
/

show err;

create or replace type LeaseApplications_set_t is table of LeaseApplications_t;
/

show err;

