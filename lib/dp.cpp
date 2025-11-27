#include "appctx.h"

QPoint appctx_t::dp(const QPaintDeviceMetrics& m, double x, double y) const {
	double xAdjust = (AdjustXmm % 31) / 10;
	double yAdjust = (AdjustYmm % 31) / 10;
	return QPoint(((x + xAdjust) * m.logicalDpiX()) / 2.54, 
		((y + yAdjust) * m.logicalDpiY()) / 2.54);
}
