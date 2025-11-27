#include "appctx.h"

const QString appctx_t::get_payment_template_group_id(QListBoxItem* i) const {
	payment_template_group_t* c = dynamic_cast<payment_template_group_t*>(i);
	return c ? c->id : QString::null;
}

const QString appctx_t::get_payment_template_group_name(const QString& id) const {
	payment_template_groups_t::const_iterator i = payment_template_groups.find(payment_template_group_t(id));
	if(i != payment_template_groups.end()) return (*i).name;
	return QString::null;
}

void appctx_t::add_payment_template_groups(QComboBox* cb) const {
	cb->clear();
	cb->insertItem("");
	for(payment_template_groups_t::const_iterator i = payment_template_groups.begin(); i != payment_template_groups.end(); i++)
		cb->listBox()->insertItem(new payment_template_group_t(*i));
	cb->listBox()->sort();
	cb->setEnabled(cb->count() > 2);
}
