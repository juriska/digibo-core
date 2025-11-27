#include "appctx.h"

void appctx_t::cleanup() {
	logoff();
	ti_pamo.hide();
	ti_broker.hide();
	ti_margin.hide();
	ti_ffo.hide();
}