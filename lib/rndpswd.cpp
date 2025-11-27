#include "appctx.h"

const QString newPassword() {
	static const char ValidChars[] = "23456789qwertyuiopasdfghjkzxcvbnmQWERTYUPASDFGHJKLZXCVBNM\0";
	static const int ValidCharsLen = ::strlen(ValidChars);
	QString res;
	while(res.find(QRegExp("[\\d][\\D]|[\\D][\\d]")) < 0) {
		for(res.setLength(0); res.length() < 8; ) {
			res.append(ValidChars[::rand() % ValidCharsLen]);
		}
	}
	return res;
}
