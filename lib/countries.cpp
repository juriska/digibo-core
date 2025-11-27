#include "appctx.h"

const QString appctx_t::get_country_id(QListBoxItem* i) const {
	country_t* c = dynamic_cast<country_t*>(i);
	return c ? c->id : QString::null;
}

const QString appctx_t::get_country_entry_legal_id(QListBoxItem* i) const {
	country_t* c = dynamic_cast<country_t*>(i);
	return c ? c->entry_legal_id : QString::null;
}

const QString appctx_t::get_country_accept_legal_id(QListBoxItem* i) const {
	country_t* c = dynamic_cast<country_t*>(i);
	return c ? c->accept_legal_id : QString::null;
}

const QString appctx_t::get_country_name(const QString& id) const {
	countries_t::const_iterator i = countries.find(country_t(id));
	if(i != countries.end()) return (*i).name;
	return QString::null;
}

void appctx_t::add_countries(QComboBox* cb) const {
	cb->clear();
	cb->insertItem("");
	for(countries_t::const_iterator i = countries.begin(); i != countries.end(); i++)
		cb->listBox()->insertItem(new country_t(*i));
	cb->listBox()->sort();
	cb->setEnabled(cb->count() > 2);
}
