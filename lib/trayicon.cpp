#include "trayicon.h"
#include "qpopupmenu.h"

TrayIcon::TrayIcon(int typeId, QObject *parent, const char *name) :
	QObject(parent, name), pop(0), d(0), type_id(typeId) {
}

TrayIcon::TrayIcon(
	int typeId,
	const QPixmap &icon,
	const QString &tooltip,
	const QString &tooltitle,
	QPopupMenu *popup,
	QObject *parent,
	const char *name
) : QObject(parent, name),
	pop(popup), pm(icon), tip(tooltip), title(tooltitle), d(0), type_id(typeId) {
}

TrayIcon::~TrayIcon() {
	sysRemove();
}

void TrayIcon::setPopup(QPopupMenu* popup) {
	pop = popup;
}

QPopupMenu* TrayIcon::popup() const {
	return pop;
}

void TrayIcon::setIcon(const QPixmap &icon) {
	pm = icon;
	sysUpdateIcon();
}

QPixmap TrayIcon::icon() const {
	return pm;
}

void TrayIcon::setToolTip(const QString &tooltip, const QString &tooltitle) {
	tip = tooltip;
	title = tooltitle;
	sysUpdateToolTip();
}

QString TrayIcon::toolTip() const {
	return tip;
}

QString TrayIcon::toolTitle() const {
	return title;
}

void TrayIcon::show() {
	sysInstall();
}

void TrayIcon::hide() {
	sysRemove();
}

bool TrayIcon::event(QEvent *e) {
	switch(e->type()) {
	case QEvent::MouseMove:
		mouseMoveEvent((QMouseEvent*)e);
		break;
	case QEvent::MouseButtonPress:
		mousePressEvent((QMouseEvent*)e);
		break;
	case QEvent::MouseButtonRelease:
		mouseReleaseEvent((QMouseEvent*)e);
		break;
	case QEvent::MouseButtonDblClick:
		mouseDoubleClickEvent((QMouseEvent*)e);
		break;
	default:
		return QObject::event(e);
	}
	return TRUE;
}

void TrayIcon::mouseMoveEvent(QMouseEvent *e) {
	e->ignore();
}

void TrayIcon::mousePressEvent(QMouseEvent *e) {
	if(qWinVersion() == Qt::WV_2000 ||
		qWinVersion() == Qt::WV_XP ||
		qWinVersion() == Qt::WV_2003) e->ignore();
	else mouseReleaseEvent(e);
}

void TrayIcon::mouseReleaseEvent(QMouseEvent *e) {
	switch(e->button()) {
	case RightButton:
		if(pop) {
			// Necessary to make keyboard focus
			// and menu closing work on Windows.
			pop->setActiveWindow();
			pop->popup(e->globalPos());
			pop->setActiveWindow();
			e->accept();
		}
		break;
	case LeftButton:
		emit clicked(e->globalPos());
		break;
	default:
		break;
	}
	e->ignore();
}

void TrayIcon::mouseDoubleClickEvent(QMouseEvent *e) {
	if(e->button() == LeftButton)
		emit doubleClicked(e->globalPos());
	e->ignore();
}
