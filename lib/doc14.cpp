#include "appctx.h"

void appctx_t::setSecTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(QString::null, "301,304,305,306"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Stock purchase/sale"), "304"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Bond purchase/sale"), "305"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Option purchase/sale"), "306"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Stock free form order"), "301"));
}

void appctx_t::setInsuranceTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(QString::null, "780,784,785"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Insurance policy application"), "780"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Application for insurance termination"), "784"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Application for insurance prolongation"), "785"));
}
