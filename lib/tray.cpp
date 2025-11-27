#include <qsound.h>
#include <qpopupmenu.h>

#include "appctx.h"

static void play(const QString& f) {
	if(QSound::available() && !f.isEmpty()) {
		QSound::play(appPath() + "sounds/" + f);
	}
	else {
		MessageBeep(MB_ICONEXCLAMATION);
	}
}

void appctx_t::initializeTrayIcons() {
	static bool first = true;
	if(!first) return;

	QString title(tr("New order available."));

	ti_pamo.setToolTip(tr("New PAM order available."), title);
	QPopupMenu* m1 = new QPopupMenu();
	m1->insertItem(tr("Select new PAM orders"), this, SLOT(pamoTrayIconSelected()));
	ti_pamo.setPopup(m1);
	connect(&ti_pamo, SIGNAL(doubleClicked(const QPoint&)), SLOT(pamoTrayIconSelected()));

	ti_broker.setToolTip(tr("New security order available."), title);
	QPopupMenu* m2 = new QPopupMenu();
	m2->insertItem(tr("Select new security orders"), this, SLOT(brokerTrayIconSelected()));
	ti_broker.setPopup(m2);
	connect(&ti_broker, SIGNAL(doubleClicked(const QPoint&)), SLOT(brokerTrayIconSelected()));

	ti_margin.setToolTip(tr("New margin order available."), title);
	QPopupMenu* m3 = new QPopupMenu();
	m3->insertItem(tr("Select new margin orders"), this, SLOT(marginTrayIconSelected()));
	ti_margin.setPopup(m3);
	connect(&ti_margin, SIGNAL(doubleClicked(const QPoint&)), SLOT(marginTrayIconSelected()));

	ti_ffo.setToolTip(tr("New FFO order available."), title);
	QPopupMenu* m4 = new QPopupMenu();
	m4->insertItem(tr("Select new FFO orders"), this, SLOT(ffoTrayIconSelected()));
	ti_ffo.setPopup(m4);
	connect(&ti_ffo, SIGNAL(doubleClicked(const QPoint&)), SLOT(ffoTrayIconSelected()));

	first = false;
}

void appctx_t::addTrayIcon(int type_id) {
	initializeTrayIcons();
	QWidget* target = 0;
	switch(type_id) {
	case UID_PAM:
		target = get_widget("PAMO");
		if(target) {
			ti_pamo.setIcon(*(target->icon()));
			ti_pamo.show();
			play(PAMO);
		}
		break;
	case UID_SEC:
		target = get_widget("Broker");
		if(target) {
			ti_broker.setIcon(*(target->icon()));
			ti_broker.show();
			play(Broker);
		}
		break;
	case UID_MARGIN:
		target = get_widget("Margin");
		if(target) {
			ti_margin.setIcon(*(target->icon()));
			ti_margin.show();
			play(Margin);
		}
		break;
	case UID_FFO:
		target = get_widget("FFO");
		if(target) {
			ti_ffo.setIcon(*(target->icon()));
			ti_ffo.show();
			play(FFO);
		}
		break;
	}
}

void appctx_t::deleteTrayIcon(int type_id) {
	switch(type_id) {
	case UID_PAM:
		ti_pamo.hide();
		break;
	case UID_SEC:
		ti_broker.hide();
		break;
	case UID_MARGIN:
		ti_margin.hide();
		break;
	case UID_FFO:
		ti_ffo.hide();
		break;
	}
}

void appctx_t::pamoTrayIconSelected() {
	if(QApplication::activeModalWidget() || QApplication::activePopupWidget())
		return;
	QWidget* w = get_widget("PAMO");
	if(w) {
		show(w);
		emit selectNewPam();
	}
}

void appctx_t::brokerTrayIconSelected() {
	if(QApplication::activeModalWidget() || QApplication::activePopupWidget())
		return;
	QWidget* w = get_widget("Broker");
	if(w) {
		show(w);
		emit selectNewBroker();
	}
}

void appctx_t::marginTrayIconSelected() {
	if(QApplication::activeModalWidget() || QApplication::activePopupWidget())
		return;
	QWidget* w = get_widget("Margin");
	if(w) {
		show(w);
		emit selectNewMargin();
	}
}

void appctx_t::ffoTrayIconSelected() {
	if(QApplication::activeModalWidget() || QApplication::activePopupWidget())
		return;
	QWidget* w = get_widget("FFO");
	if(w) {
		show(w);
		emit selectNewFfo();
	}
}
