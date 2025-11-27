#include "appctx.h"

void appctx_t::setPaymentTypes(QComboBox* cb) {
	cb->clear();

	QPixmap t = QPixmap::fromMimeSource("type.png");
	QPixmap u = QPixmap::fromMimeSource("utility.png");

	static const QString non_utility(
		"1,2,3,4,5,7,15,16,22,23,24,25,26,115,116,117,118,122,123,124,125,126,127,128,133,134,135,137,138,139,329"
	);
	static const QString utility(
		"30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,800,801,802,803,804,805,806,807,808,809,810,811,812,813,814,815,816,817,818,819,820,821,822,823,824,825,826,827,828,829,830,831,832,833,834,835,836,838,839,840,841,842,843,844,845,846,847,848,849,850,851,852,853,854,855,856,857,858,859,860,861,862,863"
	);
	

	cb->listBox()->insertItem(new doc_type_t(t, QString::null,
		utility + "," + non_utility
	));

	cb->listBox()->insertItem(new doc_type_t(t, tr("All non utility types"),
		non_utility));
	QStringList entries = QStringList::split(",", non_utility, false);
	for(QStringList::const_iterator i = entries.begin(); i != entries.end(); ++i) {
		cb->listBox()->insertItem(
			new doc_type_t(t, get_doc_type((*i).toInt()), *i)
		);
	}

	cb->listBox()->insertItem(new doc_type_t(u, tr("All utility types"),
		utility));
	entries = QStringList::split(",", utility, false);
	for(QStringList::const_iterator i = entries.begin(); i != entries.end(); ++i) {
		cb->listBox()->insertItem(
			new doc_type_t(u, get_doc_type((*i).toInt()), *i)
		);
	}
}

void appctx_t::setRequestToPayDocTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(QString::null, "793, 139"));
	cb->listBox()->insertItem(new doc_text_type_t(tr("Request money"), "793"));
}

void appctx_t::setMSDTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(QString::null, "514,516,723,724,725,735,736,739,740,744,746,1027,1028"));
	cb->listBox()->insertItem(new doc_text_type_t(	tr("Enable mobile app quick functions"), "514"));
	cb->listBox()->insertItem(new doc_text_type_t(	tr("Disable mobile app quick functions"), "516"));
	cb->listBox()->insertItem(new doc_text_type_t(	tr("MobileSCAN license activation"), "723")	);
	cb->listBox()->insertItem(new doc_text_type_t(	tr("Add a new device"),	"724"));
	//cb->listBox()->insertItem(new doc_text_type_t(	tr("Remove device"), "725"));
	cb->listBox()->insertItem(new doc_text_type_t(	tr("Mobile services cancellation order"), "725"));
	cb->listBox()->insertItem(new doc_text_type_t(	tr("MobileSCAN license reservation"), "735")	);
	cb->listBox()->insertItem(new doc_text_type_t(	tr("MobileSCAN contract changes and device activation"), "736"));
	cb->listBox()->insertItem(new doc_text_type_t(	tr("Remotely activated MobileSCAN"), "739")	);
	cb->listBox()->insertItem(new doc_text_type_t(	tr("Enable quick auth"), "740"));
	cb->listBox()->insertItem(new doc_text_type_t(	tr("Disable QUICK Mobile services"), "744"));
        cb->listBox()->insertItem(new doc_text_type_t(	tr("PUSH Notifications"), "746"));
	cb->listBox()->insertItem(new doc_text_type_t(	tr("MobileSCAN recovery"), "1027"));
	cb->listBox()->insertItem(new doc_text_type_t(	tr("MobileSCAN recovery mismatch"), "1028"));
}