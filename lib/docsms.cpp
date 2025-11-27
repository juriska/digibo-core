#include "appctx.h"

void appctx_t::setSMSTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(QString::null,
		"107,108,109"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("SMS create"), "107"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("SMS update"), "108"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("SMS close"), "109"));
}
