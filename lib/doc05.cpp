#include "appctx.h"

void appctx_t::setSTOTypes(QComboBox* cb) {
	cb->clear();
	cb->listBox()->insertItem(new doc_text_type_t(QString::null,
		"83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,200,201"));
	cb->listBox()->insertItem(new doc_text_type_t(
		tr("Create fixed amount internal STO"), "83")
	);
	cb->listBox()->insertItem(new doc_text_type_t(
		tr("Create fixed amount EKS STO"), "84")
	);
	cb->listBox()->insertItem(new doc_text_type_t(
		tr("Create balance outward internal STO"), "85")
	);
	cb->listBox()->insertItem(new doc_text_type_t(
		tr("Create balance outward EKS STO"), "86")
	);
	cb->listBox()->insertItem(new doc_text_type_t(
		tr("Create balance inward STO"), "87")
	);
	cb->listBox()->insertItem(new doc_text_type_t(
		tr("Create revolving credit STO"), "88")
	);

	cb->listBox()->insertItem(new doc_text_type_t(
		tr("Update fixed amount STO"), "89")
	);
	cb->listBox()->insertItem(new doc_text_type_t(
		tr("Update balance outward STO"), "90")
	);
	cb->listBox()->insertItem(new doc_text_type_t(
		tr("Update balance inward STO"), "91")
	);
	cb->listBox()->insertItem(new doc_text_type_t(
		tr("Update revolving credit STO"), "92")
	);

	cb->listBox()->insertItem(new doc_text_type_t(
		tr("Close fixed amount STO"), "93")
	);
	cb->listBox()->insertItem(new doc_text_type_t(
		tr("Close balance outward STO"), "94")
	);
	cb->listBox()->insertItem(new doc_text_type_t(
		tr("Close balance inward STO"), "95")
	);
	cb->listBox()->insertItem(new doc_text_type_t(
		tr("Close revolving credit STO"), "96")
	);

	cb->listBox()->insertItem(new doc_text_type_t(
		get_doc_type(200), "200")
	);
	cb->listBox()->insertItem(new doc_text_type_t(
		get_doc_type(201), "201")
	);
	cb->listBox()->insertItem(new doc_text_type_t(
		get_doc_type(97), "97")
	);
	cb->listBox()->insertItem(new doc_text_type_t(
		get_doc_type(98), "98")
	);
}