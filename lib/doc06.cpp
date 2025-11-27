#include "appctx.h"

void appctx_t::setDDTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(QString::null,
		"60,61,62,63,64,65,81,82,129,130,131,132"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Via NMC"), "60"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Rigas udens"), "61"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Lattelekom"), "62"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Tele2"), "63"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Baltkom Tikli"), "64"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Baltkom Decoder"), "65"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Update order"), "81"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Close order"), "82"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("ERRA"), "129,130,131,132"));
}
