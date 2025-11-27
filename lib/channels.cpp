#include "appctx.h"

void appctx_t::init_channels() {
	channels.insert(channel_t("Web", channel_t::WEB));
#ifdef BUILD_SMS
	channels.insert(channel_t("SMS", channel_t::SMS));
#endif
//	channels.insert(channel_t("WAP", channel_t::WAP));
//	channels.insert(channel_t("BO", channel_t::BO));
//	channels.insert(channel_t("Client", channel_t::CLIENT));
	channels.insert(channel_t("Firma", channel_t::FIRMA));
	channels.insert(channel_t("Gate", channel_t::GATE));
//	channels.insert(channel_t("Fax", channel_t::FAX));
//	channels.insert(channel_t("Voice", channel_t::VOICE));
//	channels.insert(channel_t("Email", channel_t::EMAIL));
}

void appctx_t::add_channels(QComboBox* cb) const {
	cb->clear();
	cb->insertItem("");
	for(channels_t::const_iterator i = channels.begin(); i != channels.end(); i++)
		cb->listBox()->insertItem(new channel_t(*i));
	cb->listBox()->sort();
	cb->setEnabled(cb->count() > 2);
}

void appctx_t::add_channels_check(QListView* lv) const {
	lv->clear();
	for(channels_t::const_iterator it = channels.begin(); it != channels.end(); it++)
		new channel_check_t(lv, (*it).name, (*it).id);
}

const int appctx_t::get_channel_id(QListBoxItem* i) const {
	channel_t* o = dynamic_cast<channel_t*>(i);
	return o ? o->id : 0;
}

const QString appctx_t::get_channel_name(const int id) const {
	channels_t::const_iterator i = channels.find(channel_t(id));
	if(i != channels.end()) return (*i).name;
	return QString::null;
}
