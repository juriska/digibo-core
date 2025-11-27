#include "appctx.h"

void appctx_t::setCRUStatuses(QComboBox* cb) {
	setGlobusDocumentStatuses(cb, false);
}
