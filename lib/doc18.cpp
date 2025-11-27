#include "appctx.h"

void appctx_t::setGerDepStatuses(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_status_t(QString::null, "1,3,13,16"));
	cb->listBox()->insertItem(new doc_status_t(tr("Executed"), "1"));
	cb->listBox()->insertItem(new doc_status_t(tr("Rejected"), "3"));
	cb->listBox()->insertItem(new doc_status_t(tr("Confirm OK"), "13"));
	cb->listBox()->insertItem(new doc_status_t(tr("Partly executed"), "16"));
}