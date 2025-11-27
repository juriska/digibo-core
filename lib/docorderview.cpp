#include "appctx.h"

void appctx_t::setOrderStatuses(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_status_t(
	QString::null, "1,3,5,6,13,19,61"));
	cb->listBox()->insertItem(new doc_status_t(tr("Finished"), "1,3"));
	cb->listBox()->insertItem(new doc_status_t(tr("Executed"), "1"));
	cb->listBox()->insertItem(new doc_status_t(tr("Rejected"), "3"));
	cb->listBox()->insertItem(new doc_status_t(tr("Signature Ok"), "5"));
	cb->listBox()->insertItem(new doc_status_t(tr("Draft"), "6,61"));
	cb->listBox()->insertItem(new doc_status_t(tr("In queue"), "13"));
	cb->listBox()->insertItem(new doc_status_t(tr("Processing"), "19"));
}

QString appctx_t::get_order_status(int value) {
	switch(value) {
	case  1: return tr("Executed");
	case  3: return tr("Rejected");
	case  5: return tr("Signature Ok");	
	case  6: case 61: return tr("Draft");
	case 13: return tr("In queue");
	case 19: return tr("Processing");
	}
	return value ? tr("Document status id %1").arg(value) : QString::null;
}

void appctx_t::setOrderDocTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(
	QString::null, "6,729,731,732,734,524,527,755,764,769,770,771,781,782,783,794,798,1200"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Free Form Order"), "6"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Finance Consultation"), "729"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Payment Cancellation"), "731"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Payment Investigation"), "732"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Payment confirmation or SWIFT copy"), "734"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("ATM Claim"), "524"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Card Claim"), "527"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Identification document image submission"), "755"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("IB payment automated cancellation order"), "764"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Open Account for Minor"), "769"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Application for preparation of reference"), "781,782,783"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Submit 'Know Your Client' documents"), "794"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Minor Onboarding Order (MobApp)"), "770"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Guaranteed compensation application"), "798"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Instant credit limit change"), "771,1200"));
}

QString appctx_t::get_FFO_doc_type(int value) {
	switch(value) {
	case   6: return tr("Free Form Order");
	case 729: return tr("Finance Consultation");
	case 731: return tr("Payment Cancellation");
	case 732: return tr("Payment Investigation");
	case 734: return tr("Payment confirmation or SWIFT copy");
	case 524: return tr("ATM Claim");
	case 527: return tr("Card Claim");
	case 755: return tr("Identification document image submission");
	case 764: return tr("IB payment automated cancellation order");
	case 769: return tr("Open Account for Minor");
	case 771: case 1200: return tr("Instant credit limit change");
	case 781: case 782: case 783: return tr("Application for preparation of reference");
	case 794: return tr("Submit 'Know Your Client' documents");
	case 798: return tr("Guaranteed compensation application");
	}
	return value ? tr("Type id %1").arg(value) : QString::null;
}

QString appctx_t::get_Insurance_doc_type(int value) {
	switch(value) {
	case 780: return tr("Insurance policy application");
	case 784: return tr("Application for insurance termination");
	case 785: return tr("Application for insurance prolongation");
	}
	return value ? tr("Type id %1").arg(value) : QString::null;
}