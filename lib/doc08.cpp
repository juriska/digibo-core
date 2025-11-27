#include "appctx.h"

QString appctx_t::get_doc_device_type(int value) {
	switch(value) {
	case 1: return tr("DigiPass");
	case 2: return tr("TanCard");
	case 3: return tr("RSA");
	case 7: return tr("X509");
	case 9: return tr("Cronto");
	}
	return QString::null;
}
