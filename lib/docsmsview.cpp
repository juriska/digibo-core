#include "appctx.h"

void appctx_t::setSMSStatuses(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_status_t(
	QString::null, "0,5,10,20,30"));
	cb->listBox()->insertItem(new doc_status_t(tr("Created"), "0"));
	cb->listBox()->insertItem(new doc_status_t(tr("Sending"), "5"));
	cb->listBox()->insertItem(new doc_status_t(tr("Sent"), "10"));
	cb->listBox()->insertItem(new doc_status_t(tr("Not sent"), "20"));
	cb->listBox()->insertItem(new doc_status_t(tr("Charged"), "30"));
}

void appctx_t::setSMSViewTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(QString::null, "\'I\',\'O\'"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Incoming"), "\'I\'"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Outgoing"), "\'O\'"));

	rset_t r(con(), "appctx_t::setSMSViewTypes");
	if(r.parse(QString("%1.bosmsview.get_types").arg(ib_schema))) return;
	if(r.exec()) return;
	rset_t &rv = r.result()->asRSet();
	QString errId = "";
	while(!rv.fetch(true)) {
		if(20 <= rv["id"]->asInt() && 29 >= rv["id"]->asInt()) // Error messages (Macro item)
			errId += rv["id"]->asString() + ",";
		else
			cb->listBox()->insertItem(new doc_text_type_t(rv["name"]->asString(), rv["id"]->asString()));
	}
	if(!errId.isEmpty()) {
		errId.truncate(errId.length()-1);
		cb->listBox()->insertItem(new doc_text_type_t(tr("Error message"), errId));
	}
}

QString appctx_t::get_sms_status(int status_id) {
	switch(status_id) {
	case  0: return tr("Created");
	case  5: return tr("Sending");
	case 10: return tr("Sent");
	case 20: return tr("Not sent");
	case 30: return tr("Charged");
	}
	return QString::number(status_id);
}
