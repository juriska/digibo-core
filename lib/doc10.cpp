#include "appctx.h"

QPixmap appctx_t::get_doc_channel_pixmap(int value) {
	switch(value) {
	case  5: return QPixmap::fromMimeSource("web.png");
	case 21: return QPixmap::fromMimeSource("firma.png");
	case 27: return QPixmap::fromMimeSource("gateway.png");
	case 28: return QPixmap::fromMimeSource("msSmall.png");
	}
	return QPixmap();
}
