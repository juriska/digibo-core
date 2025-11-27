#include "appctx.h"

void crypto_device_t::select(QComboBox* cb, int id) {
	for(uint i = 0; i < cb->listBox()->count(); i++) {
		QListBoxItem* item = cb->listBox()->item(i);
		if(item) {
			crypto_device_t* device = dynamic_cast<crypto_device_t*>(item);
			if(device && (
				(device->id == id) ||
				(device->id == 0 && id == crypto_device_t::cNoDevice)
			)) {
				cb->setCurrentItem(i);
				return;
			}
		}
	}
	cb->setCurrentItem(0);
}
