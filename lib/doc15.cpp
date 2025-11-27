#include "appctx.h"

void appctx_t::setMarginTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(QString::null, "302,307,310"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Order for margin trading"), "307"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Cancel margin order"), "310"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Margin free form order"), "302"));
}
