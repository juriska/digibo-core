#include "appctx.h"

void appctx_t::setManualStatuses(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_status_t(
		QString::null, "1,2,3,4,5,6,9,11,12,13,14,15,16,19,23,26,29,30,34,52,53,61"));
	cb->listBox()->insertItem(new doc_status_t(tr("Executed"), "1"));
	cb->listBox()->insertItem(new doc_status_t(tr("Rejected"), "3"));
	cb->listBox()->insertItem(new doc_status_t(tr("Draft"), "6,29,30,61"));
	cb->listBox()->insertItem(new doc_status_t(tr("Signature Ok"), "5"));
	cb->listBox()->insertItem(new doc_status_t(tr("Invalid signature"), "2"));
	cb->listBox()->insertItem(new doc_status_t(tr("Pending"), "9,12"));
	cb->listBox()->insertItem(new doc_status_t(tr("Delivered"), "4"));
	cb->listBox()->insertItem(new doc_status_t(tr("Confirm Ok"), "13"));
	cb->listBox()->insertItem(new doc_status_t(tr("Message generated"), "14"));
	cb->listBox()->insertItem(new doc_status_t(tr("Message sent"), "15"));
	cb->listBox()->insertItem(new doc_status_t(tr("Partly executed"), "16, 34, 53"));
	cb->listBox()->insertItem(new doc_status_t(tr("Printed"), "11"));
	cb->listBox()->insertItem(new doc_status_t(tr("Processing"), "19"));
	cb->listBox()->insertItem(new doc_status_t(tr("Maturity"), "23"));
	cb->listBox()->insertItem(new doc_status_t(tr("Message failed"), "26"));
}

void appctx_t::setGlobusDocumentStatuses(QComboBox* cb, bool utility) {
	cb->clear();
	cb->listBox()->insertItem(new doc_status_t(
		QString::null, "1,2,3,4,5,6,9,12,13,14,16,19,22,23,25,26,27,28,34,51,52,29,30,61,37,85"));
	cb->listBox()->insertItem(new doc_status_t(tr("Executed"), "1,34"));
	cb->listBox()->insertItem(new doc_status_t(tr("Rejected"), "3"));
	cb->listBox()->insertItem(new doc_status_t(tr("Draft"), "6,29,30,61"));
	cb->listBox()->insertItem(new doc_status_t(tr("Signature Ok"), "5"));
	cb->listBox()->insertItem(new doc_status_t(tr("Confirm Ok"), "13"));
	cb->listBox()->insertItem(new doc_status_t(tr("Partly executed"), "16, 34"));
	cb->listBox()->insertItem(new doc_status_t(tr("Invalid signature"), "2"));
	cb->listBox()->insertItem(new doc_status_t(tr("Pending"), "9,12"));
	cb->listBox()->insertItem(new doc_status_t(tr("Message generated"), "14"));
	cb->listBox()->insertItem(new doc_status_t(tr("Processing"), "4"));
	cb->listBox()->insertItem(new doc_status_t(tr("Reversed"), "22"));
	cb->listBox()->insertItem(new doc_status_t(tr("Maturity"), "23"));
	if(utility) {
		cb->listBox()->insertItem(new doc_status_t(tr("Message pending"), "25"));
		cb->listBox()->insertItem(new doc_status_t(tr("Message failed"), "26"));
	}
	cb->listBox()->insertItem(new doc_status_t(tr("Message rejected"), "27"));
	cb->listBox()->insertItem(new doc_status_t(tr("Message reversed"), "28"));
	cb->listBox()->insertItem(new doc_status_t(tr("Awaiting processing"), "51"));
	cb->listBox()->insertItem(new doc_status_t(tr("Partly Succeed"), "34"));
}

void appctx_t::setApplicationStatuses(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_status_t(
		QString::null, "1,3,6,61,13,5,34"));
	cb->listBox()->insertItem(new doc_status_t(tr("Executed"), "1,34"));
	cb->listBox()->insertItem(new doc_status_t(tr("Rejected"), "3"));
	cb->listBox()->insertItem(new doc_status_t(tr("Draft"), "6,61"));
	cb->listBox()->insertItem(new doc_status_t(tr("Confirm Ok"), "13"));
	cb->listBox()->insertItem(new doc_status_t(tr("Signature Ok"), "5"));
}
