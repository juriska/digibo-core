#include <qstring.h>
#include <qregexp.h>

QString commaSeparated(const QString& src) {
	QString rv(src);
	rv.remove(", ,");
	rv.remove(QRegExp("^ *,"));
	rv.remove(QRegExp(" *, *$"));
	rv = rv.stripWhiteSpace();
	return rv == "," ? QString::null : rv;
}