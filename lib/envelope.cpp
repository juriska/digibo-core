#include "envelope.h"
#include "appctx.h"

extern appctx_t* appctx;

DigiEnvelope::DigiEnvelope(QWidget* _parent) : EscpPrinter(_parent) {
}

void DigiEnvelope::print(const QString& visible, const QString& hidden) {
	beginJob();
	moveDown(appctx->DFvOffset1);
	moveRight(appctx->LeftMargin);
	write(hidden);
	moveDown(appctx->DFvOffset2);
	moveRight(appctx->LeftMargin);
	write(visible);
	formFeed();
}
