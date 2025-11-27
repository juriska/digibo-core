#include "appctx.h"

const int appctx_t::get_officer_id(QListBoxItem* i) const {
	officer_t* o = dynamic_cast<officer_t*>(i);
	return o ? o->id : 0;
}

const QString appctx_t::get_officer_name(const int id, int attr) const {
	officers_t::const_iterator i = officers.find(officer_t(id));
	if(i != officers.end() && (!attr || (attr & (*i).attr))) return (*i).name;
	return tr("Officer ID %1").arg(id);
}

void appctx_t::add_officers(QComboBox* cb, int attr) const {
	cb->clear();
	cb->insertItem("");
	for(officers_t::const_iterator i = officers.begin(); i != officers.end(); i++) {
		if(!attr || (attr & (*i).attr))
			cb->listBox()->insertItem(new officer_t(*i));
	}
	cb->listBox()->sort();
	cb->setEnabled(cb->count() > 1);
}
