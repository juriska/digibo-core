#include "appctx.h"

void appctx_t::add_currencies(QComboBox* cb, const QString& exclude) const {
	cb->clear();
	cb->insertItem("");
	for(set_of_str::const_iterator i = currencies.begin(); i != currencies.end(); i++) {
		if(0 == exclude.contains(*i)) {
			cb->listBox()->insertItem(new QListBoxText(*i));
		}
	}
	cb->setEnabled(cb->count() > 2);
}
