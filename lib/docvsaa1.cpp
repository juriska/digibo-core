#include "appctx.h"

void appctx_t::setVSAAAdvAppStatuses(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_status_t(QString::null, "6,13,1,3,61"));
	cb->listBox()->insertItem(new doc_status_t(tr("Draft"), "6,61"));
	cb->listBox()->insertItem(new doc_status_t(tr("Confirm OK"), "13"));
	cb->listBox()->insertItem(new doc_status_t(tr("Executed"), "1"));
	cb->listBox()->insertItem(new doc_status_t(tr("Rejected"), "3"));
}

void appctx_t::setVSAAAdvAppTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(QString::null,
		"113,114"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Application"), "113"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Closure"), "114"));
}

