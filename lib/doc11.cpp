#include "appctx.h"

QString appctx_t::get_doc_channel(int value) {
	switch(value) {
	case  0: return tr("System");
	case  5: return tr("Web");
	case 10: return tr("Backoffice");
	case 20: return tr("Client-Bank");
	case 21: return tr("Firma");
	case 27: return tr("Gate");
	case 28: return tr("Quick-auth");
	case 29: return tr("Quick-bal");
	case 30: return tr("Fax");
	}
	return value ? tr("Document channel id %1").arg(value) : QString::null;
}
