#define _WIN32_IE 0x0500

#include "trayicon.h"

#include <qwidget.h>
#include <qapplication.h>
#include <qimage.h>
#include <qpixmap.h>
#include <qbitmap.h>
#include <qcursor.h>
#include <qlibrary.h>

#include <qt_windows.h>

static uint MYWM_TASKBARCREATED = 0;
#define MYWM_NOTIFYICON	(WM_APP+101)

typedef BOOL (WINAPI *PtrShell_NotifyIcon)(DWORD,PNOTIFYICONDATA);
static PtrShell_NotifyIcon ptrShell_NotifyIcon = 0;

static void resolveLibs() {
	QLibrary lib("shell32");
	lib.setAutoUnload(FALSE);
	static bool triedResolve = FALSE;
	if(!ptrShell_NotifyIcon && !triedResolve) {
		triedResolve = TRUE;
		ptrShell_NotifyIcon = (PtrShell_NotifyIcon)lib.resolve("Shell_NotifyIconW");
	}
}

class TrayIcon::TrayIconPrivate : public QWidget {
public:
	TrayIconPrivate(TrayIcon *object) : QWidget(0), hIcon(0), hMask(0), iconObject(object) {
		if(!MYWM_TASKBARCREATED)
			MYWM_TASKBARCREATED = RegisterWindowMessage((TCHAR*)"TaskbarCreated");
	}

	~TrayIconPrivate() {
		if(hMask) DeleteObject(hMask);
		if(hIcon) DestroyIcon(hIcon);
	}

	bool trayMessage(DWORD msg) {
		bool res;
		resolveLibs();
		NOTIFYICONDATA tnd;
		memset(&tnd, 0, sizeof(NOTIFYICONDATA));
		tnd.cbSize = sizeof(NOTIFYICONDATA);
		tnd.hWnd = winId();
		tnd.uID = iconObject->typeId();

		if(msg != NIM_DELETE) {
			tnd.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP | NIF_INFO;
			tnd.uCallbackMessage = MYWM_NOTIFYICON;
			tnd.hIcon = hIcon;
			if(!iconObject->toolTip().isNull()) {
				QString tip = iconObject->toolTip().left( 63 ) + QChar();
				lstrcpyn(tnd.szTip, (TCHAR*)tip.unicode(), QMIN( tip.length()+1, 64 ) );
				wcscpy(tnd.szInfo, (TCHAR*)iconObject->toolTip().ucs2());
			}
			if(!iconObject->toolTitle().isNull()) {
				tnd.dwInfoFlags = NIIF_INFO;
				tnd.uTimeout = 30;
				wcscpy(tnd.szInfoTitle, (const wchar_t *)iconObject->toolTitle().ucs2());
			}
		}
		res = ptrShell_NotifyIcon(msg, &tnd);
		return res;
	}

	bool iconDrawItem(LPDRAWITEMSTRUCT lpdi) {
		if(!hIcon) return FALSE;
		DrawIconEx(lpdi->hDC, lpdi->rcItem.left, lpdi->rcItem.top, hIcon,
			0, 0, 0, NULL, DI_NORMAL);
		return TRUE;
	}

	bool winEvent(MSG *m) {
		switch(m->message) {
		case WM_DRAWITEM:
			return iconDrawItem((LPDRAWITEMSTRUCT)m->lParam);
		case MYWM_NOTIFYICON: {
			QMouseEvent *e = 0;
			QPoint gpos = QCursor::pos();
			switch(m->lParam) {
			case WM_MOUSEMOVE:
				e = new QMouseEvent(QEvent::MouseMove, mapFromGlobal(gpos), gpos, 0, 0);
				break;
			case WM_LBUTTONDOWN:
				e = new QMouseEvent(QEvent::MouseButtonPress, mapFromGlobal(gpos), gpos, LeftButton, LeftButton);
				break;
			case WM_LBUTTONUP:
				e = new QMouseEvent(QEvent::MouseButtonRelease, mapFromGlobal(gpos), gpos, LeftButton, LeftButton);
				break;
			case WM_LBUTTONDBLCLK:
				e = new QMouseEvent(QEvent::MouseButtonDblClick, mapFromGlobal(gpos), gpos, LeftButton, LeftButton);
				break;
			case WM_RBUTTONDOWN:
				e = new QMouseEvent(QEvent::MouseButtonPress, mapFromGlobal(gpos), gpos, RightButton, RightButton);
				break;
			case WM_RBUTTONUP:
				e = new QMouseEvent(QEvent::MouseButtonRelease, mapFromGlobal(gpos), gpos, RightButton, RightButton);
				break;
			case WM_RBUTTONDBLCLK:
				e = new QMouseEvent(QEvent::MouseButtonDblClick, mapFromGlobal(gpos), gpos, RightButton, RightButton);
				break;
			case WM_MBUTTONDOWN:
				e = new QMouseEvent(QEvent::MouseButtonPress, mapFromGlobal(gpos), gpos, MidButton, MidButton);
				break;
			case WM_MBUTTONUP:
				e = new QMouseEvent(QEvent::MouseButtonRelease, mapFromGlobal(gpos), gpos, MidButton, MidButton);
				break;
			case WM_MBUTTONDBLCLK:
				e = new QMouseEvent(QEvent::MouseButtonDblClick, mapFromGlobal(gpos), gpos, MidButton, MidButton);
				break;
			case WM_CONTEXTMENU:
				e = new QMouseEvent(QEvent::MouseButtonRelease, mapFromGlobal(gpos), gpos, RightButton, RightButton);
				break;
			default:
				break;
			}
			if(e) {
				bool res = QApplication::sendEvent(iconObject, e);
				delete e;
				return res;
			}
		}
		break;
		default:
			if(m->message == MYWM_TASKBARCREATED)
				trayMessage(NIM_ADD);
			break;
		}
		return QWidget::winEvent( m );
	}

public:
	HICON hIcon;
	HBITMAP hMask;
	TrayIcon *iconObject;
};

static HBITMAP createIconMask(const QPixmap &qp) {
	QImage bm = qp.convertToImage();
	int w = bm.width();
	int h = bm.height();
	int bpl = ((w + 15) / 16) * 2; // bpl, 16 bit alignment
	uchar *bits = new uchar[bpl * h];
	bm.invertPixels();
	for(int y = 0; y < h; y++)
		memcpy(bits + y * bpl, bm.scanLine(y), bpl);
	HBITMAP hbm = CreateBitmap(w, h, 1, 1, bits);
	delete[] bits;
	return hbm;
}

static HICON createIcon(const QPixmap &pm, HBITMAP &hbm) {
	QPixmap maskpm(pm.size(), pm.depth(), QPixmap::NormalOptim);
	QBitmap mask(pm.size(), FALSE, QPixmap::NormalOptim);
	if(pm.mask()) {
		maskpm.fill(Qt::black); // make masked area black
		bitBlt(&mask, 0, 0, pm.mask());
	}
	else {
		maskpm.fill(Qt::color1);
	}
	bitBlt(&maskpm, 0, 0, &pm);
	ICONINFO iconInfo;
	iconInfo.fIcon = TRUE;
	iconInfo.hbmMask = createIconMask(mask);
	hbm = iconInfo.hbmMask;
	iconInfo.hbmColor = maskpm.hbm();
	return CreateIconIndirect(&iconInfo);
}

void TrayIcon::sysInstall() {
	if(d) return;
	d = new TrayIconPrivate(this);
	d->hIcon = createIcon(pm, d->hMask);
	d->trayMessage(NIM_ADD);
}

void TrayIcon::sysRemove() {
	if(!d) return;
	d->trayMessage(NIM_DELETE);
	delete d;
	d = 0;
}

void TrayIcon::sysUpdateIcon() {
	if(!d) return;
	if(d->hMask) DeleteObject(d->hMask);
	if(d->hIcon) DestroyIcon(d->hIcon);
	d->hIcon = createIcon(pm, d->hMask);
	d->trayMessage(NIM_MODIFY);
}

void TrayIcon::sysUpdateToolTip() {
	if(!d) return;
	d->trayMessage(NIM_MODIFY);
}
