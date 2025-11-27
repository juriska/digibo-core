#include "appctx.h"

exttext_item_t::exttext_item_t() : text(), block(0), block_cnt(0) {
}

exttext_item_t::exttext_item_t(const QString& t, int b, int bc) :
	text(t), block(b), block_cnt(bc) {
}

bool extensions_t::load(appctx_t* ctx, const QString& id, const QString& procedure) {
	rset_t r(ctx->con(), "appctx::extensions");
	if(r.parse(QString("%1.%2").arg(ctx->ib_schema).arg(procedure)))
		return false;
	r["pId"]->asString() = id;
	if(r.exec(false)) return false;
	rset_t &rv = r.result()->asRSet();
	while(!rv.fetch(true)) {
		(*this)[rv["block_id"]->asString()] = exttext_item_t(
			rv["info"]->asString(),
			rv["block_number"]->asInt(),
			rv["total_blocks"]->asInt()
		);
	}
	return true;
}
