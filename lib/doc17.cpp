#include "appctx.h"

void appctx_t::setMLoanDocTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(QString::null, "112,710,711,515,534,533,517,518,539,540,727,738,742,745,759,747,760,529,530,761"));
	// cb->listBox()->insertItem(new doc_text_type_t(tr("Mortgage loan order"), "112"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Consumer loan application"), "710"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Home loan application"), "711,712,745,759"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Credit rating"), "727,742"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Signing the consumer loan agreement"), "515"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Agreement on debt repayment"), "534"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Small consumer loan"), "533"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Small home loan"), "539"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Home energy efficiency loan"), "540"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Application for Entrepreneur loan"), "738"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Mortgage loan Guarantor application"), "747,760"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Auto loan"), "529"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Refinancing"), "530"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Loan amendment"), "761"));
}

void appctx_t::setMLoanStatuses(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_status_t(QString::null, "1,3,4,5,6,19,23,29,30,36,51,52,54,61,62"));
	cb->listBox()->insertItem(new doc_status_t(tr("Executed"), "1"));
	cb->listBox()->insertItem(new doc_status_t(tr("Rejected"), "3"));
	cb->listBox()->insertItem(new doc_status_t(tr("Delivered"), "4"));
	cb->listBox()->insertItem(new doc_status_t(tr("Signature Ok"), "5"));
	cb->listBox()->insertItem(new doc_status_t(tr("Draft"), "6,61"));
	cb->listBox()->insertItem(new doc_status_t(tr("Processing"), "19"));
	cb->listBox()->insertItem(new doc_status_t(tr("Maturity"), "23"));
	cb->listBox()->insertItem(new doc_status_t(tr("Globuss approved"), "52"));
	cb->listBox()->insertItem(new doc_status_t(tr("Validated"), "62"));
	cb->listBox()->insertItem(new doc_status_t(tr("Require Lursoft check"), "36"));
	cb->listBox()->insertItem(new doc_status_t(tr("Signature OK First Coborrower"), "54"));
}

void appctx_t::setCustodyStatuses(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_status_t(QString::null, "1,3,5,6,13,19,29,30,61,51"));
	cb->listBox()->insertItem(new doc_status_t(tr("Executed"), "1"));
	cb->listBox()->insertItem(new doc_status_t(tr("Rejected"), "3"));
	cb->listBox()->insertItem(new doc_status_t(tr("Confirm OK"), "5,13"));
	cb->listBox()->insertItem(new doc_status_t(tr("Draft"), "6,61"));
	cb->listBox()->insertItem(new doc_status_t(tr("Processing"), "19"));
}

void appctx_t::setCustodyDocTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(QString::null, "318,319,320,323,327,330"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Receipt of financial instruments"), "318"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Transfer of financial instruments"), "319"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Instruction on corporate action"), "320"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Application to AS Citadele banka ordinary shares within IPO"), "323"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Order for AS Citadele banka shares purchase/sale"), "327"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Full transfer (Brokerage)"), "330"));
}

void appctx_t::setLeaseStatuses(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_status_t(QString::null, "1,3,5,6,13,19,29,30,61,51"));
	cb->listBox()->insertItem(new doc_status_t(tr("Executed"), "1"));
	cb->listBox()->insertItem(new doc_status_t(tr("Rejected"), "3"));
	cb->listBox()->insertItem(new doc_status_t(tr("Confirm OK"), "5,13"));
	cb->listBox()->insertItem(new doc_status_t(tr("Draft"), "6,61"));
	cb->listBox()->insertItem(new doc_status_t(tr("Processing"), "19"));
}

void appctx_t::setLeaseDocTypes(QComboBox* cb) {
	cb->clear();
//	cb->listBox()->insertItem(new doc_text_type_t(QString::null, "728"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Leasing application form"), "728"));
}


void appctx_t::setFIAccOpenStatuses(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_status_t(QString::null, "1,3,4,5,6,13,19,23,29,30,61,51,81,82,83,84"));
	cb->listBox()->insertItem(new doc_status_t(tr("Executed"), "1"));
	cb->listBox()->insertItem(new doc_status_t(tr("Rejected"), "3"));
	cb->listBox()->insertItem(new doc_status_t(tr("Delivered"), "4"));
	cb->listBox()->insertItem(new doc_status_t(tr("Confirm OK"), "5,13"));
	cb->listBox()->insertItem(new doc_status_t(tr("Draft"), "6,61"));
	cb->listBox()->insertItem(new doc_status_t(tr("Processing"), "19"));
	cb->listBox()->insertItem(new doc_status_t(tr("Waiting for approval"), "81"));
	cb->listBox()->insertItem(new doc_status_t(tr("Processing approval"), "82"));
	cb->listBox()->insertItem(new doc_status_t(tr("Waiting for auth."), "83"));
	cb->listBox()->insertItem(new doc_status_t(tr("Maturity"), "23"));
}

void appctx_t::setFIAccOpenDocTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(QString::null, "321,322"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("FI account create private"), "321"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("FI account create legal"), "322"));
}


void appctx_t::setAccAdminDocTypes(QComboBox* cb) {
	cb->clear();
        cb->listBox()->insertItem(new doc_text_type_t(QString::null, "507,508,717,718,791,792"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Activate account"), "507"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Account close order"), "508"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Monocurrency settlement account open order"), "717"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Multicurrency settlement account open order"), "718"));
    	cb->listBox()->insertItem(new doc_text_type_t(tr("CORP - Open a monocurrency settlement account"), "791"));
    	cb->listBox()->insertItem(new doc_text_type_t(tr("CORP - Open a multicurrency settlement account"), "792"));
}

void appctx_t::setAccAdminStatuses(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_status_t(QString::null, "1,3,4,5,6,13,19,23,29,30,61,51"));
	cb->listBox()->insertItem(new doc_status_t(tr("Executed"), "1"));
	cb->listBox()->insertItem(new doc_status_t(tr("Rejected"), "3"));
	cb->listBox()->insertItem(new doc_status_t(tr("Signature Ok"), "5,13"));
	cb->listBox()->insertItem(new doc_status_t(tr("Draft"), "6,61"));
	cb->listBox()->insertItem(new doc_status_t(tr("Processing"), "19"));
	cb->listBox()->insertItem(new doc_status_t(tr("Maturity"), "23"));
}


void appctx_t::setLeaseAppStatuses(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_status_t(QString::null, "1,3,4,5,6,9,13,19,29,30,61,51"));
	cb->listBox()->insertItem(new doc_status_t(tr("Draft"), "6,61"));
	cb->listBox()->insertItem(new doc_status_t(tr("Executed"), "1"));
	cb->listBox()->insertItem(new doc_status_t(tr("Rejected"), "3"));
	cb->listBox()->insertItem(new doc_status_t(tr("Confirm OK"), "5,13"));
	cb->listBox()->insertItem(new doc_status_t(tr("Processing"), "19"));
}

void appctx_t::setLeaseAppDocTypes(QComboBox* cb) {
	cb->clear();
	//cb->listBox()->insertItem(new doc_status_t(QString::null, "1014"));
	cb->listBox()->insertItem(new doc_status_t(tr("Leasing application"), "1014"));
}


void appctx_t::setAmexOrderStatuses(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_status_t(QString::null, "1,3,4,5,6,9,13,15,19,23,26,29,30,37,38,39,61,51,85,86,87"));
	cb->listBox()->insertItem(new doc_status_t(tr("Draft"), "6,61"));
	cb->listBox()->insertItem(new doc_status_t(tr("Executed"), "1"));
	cb->listBox()->insertItem(new doc_status_t(tr("Rejected"), "3"));
	cb->listBox()->insertItem(new doc_status_t(tr("Confirm OK"), "5,13"));
	cb->listBox()->insertItem(new doc_status_t(tr("Processing"), "19,86,87"));
	cb->listBox()->insertItem(new doc_status_t(tr("Message Sent"), "15"));
	cb->listBox()->insertItem(new doc_status_t(tr("Maturity"), "23"));
	cb->listBox()->insertItem(new doc_status_t(tr("Message Failed"), "26"));
	cb->listBox()->insertItem(new doc_status_t(tr("Confirmed by operator"), "37"));
	cb->listBox()->insertItem(new doc_status_t(tr("Rejected by Veriff"), "38"));
	cb->listBox()->insertItem(new doc_status_t(tr("Delivered Genesys"), "39"));
	cb->listBox()->insertItem(new doc_status_t(tr("Rejected by Ondato"), "85"));
}


void appctx_t::setAmexOrderDocTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(QString::null, "1001,1002,1003,1004,1005,1006,1007,1009,1010,1011,1012,1013,1015,1016,1017,1018,1019,1020,1021,1025,786,787,788,789"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("American Express Membership rewards registration"), "1001"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Amex card private"), "1002"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Amex card legal"), "1003"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Amex WIN WIN"), "1004"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Amex POS terminal"), "1005"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Credit card order"), "1006"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Citadele payment card"), "1007"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("New customer online registration form"), "1009"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Credit rating web application"), "1010,1021"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Open new loan online"), "1011"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Credit card application"), "1012"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Debetcard application"), "1013"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Hipo Konsultacijas"), "1015"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("New customer primary online registration form"), "1016"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Finance Consultation"), "1017"));
	//cb->listBox()->insertItem(new doc_text_type_t(tr("Business loan application"), "1018"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Credit rating request (for business customers)"), "1018"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Micro loan application (for business customers)"), "1019"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Onboarding"), "1020"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("EE public consumer loan"), "1025"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("New payments plan application"), "786"));	
	cb->listBox()->insertItem(new doc_text_type_t(tr("Cancel payments plan"), "787"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Change payments plan"), "788"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Change fee account"), "789"));
}

void appctx_t::setAmexOrderFormTypes(QComboBox* cb) {
	cb->clear();
	//cb->listBox()->insertItem(new doc_text_type_t(QString::null, "CREDIT_SCORE,CREDIT_CARD,KPP,REFINANCING"));
	cb->listBox()->insertItem(new doc_text_type_t(QString::null, ""));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Credit rating application"), "CREDIT_SCORE"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Credit card application"), "CREDIT_CARD"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("New loan application"), "KPP"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Refinancing"), "REFINANCING"));
}

void appctx_t::setCapfStatuses(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_status_t(QString::null, "1,3,5,6,13,19,29,30,61,51"));
	cb->listBox()->insertItem(new doc_status_t(tr("Executed"), "1"));
	cb->listBox()->insertItem(new doc_status_t(tr("Rejected"), "3"));
	cb->listBox()->insertItem(new doc_status_t(tr("Confirm OK"), "5,13"));
	cb->listBox()->insertItem(new doc_status_t(tr("Processing"), "19"));
}


void appctx_t::setCapfDocTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(QString::null, "1008"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Life Pension"), "1008"));
}

void appctx_t::setProdKitStatuses(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_status_t(QString::null, "1,3,5,6,13,19,29,30,61,51"));
	cb->listBox()->insertItem(new doc_status_t(tr("Executed"), "1"));
	cb->listBox()->insertItem(new doc_status_t(tr("Rejected"), "3"));
	cb->listBox()->insertItem(new doc_status_t(tr("Signature Ok"), "5,13"));
	cb->listBox()->insertItem(new doc_status_t(tr("Draft"), "6,61"));
	cb->listBox()->insertItem(new doc_status_t(tr("Processing"), "19"));
}

void appctx_t::setProdKitDocTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(QString::null, "712,713,714,715,716"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Every One KIT"), "712"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Senior KIT"), "713"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Unior KIT"), "714"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Basic KIT"), "715"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Gold KIT"), "716"));
}

void appctx_t::setCredLimIncStatuses(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_status_t(QString::null, "1,3,4,5,6,13,19,23,29,30,61,51,52,62"));
	cb->listBox()->insertItem(new doc_status_t(tr("Executed"), "1"));
	cb->listBox()->insertItem(new doc_status_t(tr("Rejected"), "3"));
	cb->listBox()->insertItem(new doc_status_t(tr("Delivered"), "4"));
	cb->listBox()->insertItem(new doc_status_t(tr("Signature Ok"), "5,13"));
	cb->listBox()->insertItem(new doc_status_t(tr("Draft"), "6,61"));
	cb->listBox()->insertItem(new doc_status_t(tr("Processing"), "19"));
}

void appctx_t::setCredLimIncDocTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(QString::null, "719"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Application for credit limit increasing"), "719"));
}

void appctx_t::setLifeAndPensionStatuses(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_status_t(QString::null, "1,3,5,6,13,19,29,30,61,51"));
	cb->listBox()->insertItem(new doc_status_t(tr("Executed"), "1"));
	cb->listBox()->insertItem(new doc_status_t(tr("Rejected"), "3"));
	cb->listBox()->insertItem(new doc_status_t(tr("Signature Ok"), "5,13"));
	cb->listBox()->insertItem(new doc_status_t(tr("Draft"), "6,61"));
	cb->listBox()->insertItem(new doc_status_t(tr("Processing"), "19"));
}

void appctx_t::setLifeAndPensionDocTypes(QComboBox* cb, bool hasLifeAndPensionRole, bool hasPensAgreementRole) {
	cb->clear();
	QString classIds;
	
	if(hasLifeAndPensionRole &&  hasPensAgreementRole) classIds = "720,721,722,765";
	else if(hasLifeAndPensionRole) classIds = "720,721,765";
	else classIds = "722,765";

	cb->listBox()->insertItem(new doc_text_type_t(QString::null, classIds));
	if(hasLifeAndPensionRole) {
		cb->listBox()->insertItem(new doc_text_type_t(tr("Application on participation in 3rd-level pension"), "720"));
		cb->listBox()->insertItem(new doc_text_type_t(tr("Application on life insurance with savings contract"), "721"));
	}
	
	if(hasPensAgreementRole) 
                cb->listBox()->insertItem(new doc_text_type_t(tr("Individual Participation Agreement"), "722"));

	cb->listBox()->insertItem(new doc_text_type_t(tr("Pension 3 Level Fund change"), "765"));
}