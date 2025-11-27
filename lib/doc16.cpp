#include "appctx.h"

void appctx_t::setCQTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(QString::null, "110,111,119,120,121,314,315,316,317,324,325,326,701,702,703,704,705,706,707,708,709,750,751,752,753,754,757,758,763,766,767,768,795"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Contact information documents"), "706, 750"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Natural person questionnaire"), "110,119,120,314,316,701,702,705,707,708,709,750,751,752,753,757,758"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Legal entity questionnaire"), "111,121,315,317,703,704,706"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Consent to receipt of notifications and offers"), "754,795"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Ownership and control structure information"), "763"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Legal questionnaire Baltic"), "766"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Legal Ownership info CHANGE"), "767"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Legal Ownership info ACCEPT"), "768"));
}
