#include "appctx.h"

void appctx_t::add_daos(QComboBox* cb, const daos_t& data, int level) const {
	cb->clear();
	cb->insertItem("");
	for(daos_t::const_iterator i = data.begin(); i != data.end(); i++) {
		if(level >= 0) {
			if((*i).level == level) {
				cb->listBox()->insertItem(new dao_t(*i));
			}
		}
		else {
			cb->listBox()->insertItem(new dao_t(*i));
		}
	}
	cb->listBox()->sort();
	cb->setEnabled(cb->count() > 2);
}

void appctx_t::select_dao(QComboBox* cb, const QString& id) const {
	for(register int i = 1; i < cb->count(); i++) {
		dao_t* s = dynamic_cast<dao_t*>(cb->listBox()->item(i));
		if(s && id == s->id) {
			cb->setCurrentItem(i);
			return;
		}
	}
	cb->setCurrentItem(0);
}

const QString appctx_t::get_dao(QComboBox* cb) const {
	dao_t* s = dynamic_cast<dao_t*>(cb->listBox()->selectedItem());
	return s ? s->id : QString::null;
}
