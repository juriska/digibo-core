#include "appctx.h"

void appctx_t::setManualTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(tr(""), "10,11,12,13,17,18,19,500,501,519,510,511,513,522,523,526,528,531,532,535,536,756"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Maxi accounts"), "501"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Card open orders, existing account"), "17"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Card open orders, new account"), "18"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Additional card open orders"), "19"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Replace card orders"), "500"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Apliecinajums kreditkartes VISA sanemsanai"), "519"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Replace AmEx to X card"), "522"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Card replacement order"), "523"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Card renewal orders"), "10"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Card block orders"), "11"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Card close orders due to loss"), "12"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Card unblock orders"), "13"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Application on changing the way/place of the card delivery"), "510"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Activate card, received by post"), "511"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("VIP Application on changing the way/place of the card delivery"), "513"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Application for new card"), "526"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("X smart programme upgrade"), "528"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Card PIN change, Card - 000***000"), "531"));
        cb->listBox()->insertItem(new doc_text_type_t(tr("Replace payment card with x card"), "532,535,536"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("X Smart application"), "756"));
}
