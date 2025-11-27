#ifndef TRAYICON_H
#define TRAYICON_H

#ifndef QT_H
#include <qobject.h>
#include <qimage.h>
#endif

class QPopupMenu;

class TrayIcon : public QObject {
	Q_OBJECT

public:
	TrayIcon(int typeId, QObject *parent = 0, const char *name = 0);

	TrayIcon(
		int typeId,
		const QPixmap&,
		const QString&,
		const QString&,
		QPopupMenu *popup = 0,
		QObject *parent = 0,
		const char *name = 0
	);
	~TrayIcon();

	void setPopup(QPopupMenu*);
	QPopupMenu* popup() const;

	QPixmap icon() const;
	QString toolTip() const;
	QString toolTitle() const;
	int typeId() const { return type_id; }

public slots:
	void setIcon(const QPixmap &icon);
	void setToolTip(const QString &tip, const QString &tooltitle);
	void show();
	void hide();

signals:
	void clicked(const QPoint&);
	void doubleClicked(const QPoint&);

protected:
	bool event(QEvent*);
	virtual void mouseMoveEvent(QMouseEvent* e);
	virtual void mousePressEvent(QMouseEvent* e);
	virtual void mouseReleaseEvent(QMouseEvent* e);
	virtual void mouseDoubleClickEvent(QMouseEvent* e);

private:
	int type_id;
	QPopupMenu *pop;
	QPixmap pm;
	QString tip, title;

	class TrayIconPrivate;
	TrayIconPrivate *d;
	void sysInstall();
	void sysRemove();
	void sysUpdateIcon();
	void sysUpdateToolTip();
};

#endif //TRAYICON_H
