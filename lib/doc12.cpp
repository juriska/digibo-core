#include "appctx.h"

QString appctx_t::get_doc_priority(int value) {
	switch(value) {
	case 0: return tr("Standart");
	case 1: return tr("Urgent");
	case 2: return tr("Express");
	}
	return QString::null;
}
