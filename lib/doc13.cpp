#include "appctx.h"

void appctx_t::setPAMTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(QString::null, "303,300,331,332,333"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Investment fund share buy/sell order"), "303"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("PAM free form order"), "300"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Partial transfer (Asset Management)"), "331"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Transfer without account closure (Asset Management)"), "332"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Transfer with account closure (Asset Management)"), "333"));
}
