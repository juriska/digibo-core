#include "appctx.h"

void appctx_t::setDocumentChannels(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_channel_t(QString::null, "5,20,21,27,28"));
	cb->listBox()->insertItem(new doc_channel_t(tr("Web"), "5"));
	cb->listBox()->insertItem(new doc_channel_t(tr("Firma"), "20,21"));
	cb->listBox()->insertItem(new doc_channel_t(tr("Gate"), "27"));
    	cb->listBox()->insertItem(new doc_channel_t(tr("MobileApp"), "28"));
}

void appctx_t::setDocumentLocations(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_location_t(QString::null, ""));
	cb->listBox()->insertItem(new doc_location_t(tr("LV"), "LV"));
	cb->listBox()->insertItem(new doc_location_t(tr("LT"), "LT"));
	cb->listBox()->insertItem(new doc_location_t(tr("EE"), "EE"));
}
