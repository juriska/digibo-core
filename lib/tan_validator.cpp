#include <qvalidator.h>
#include "appctx.h"

QValidator::State appctx_t::validatePinTan(QString& input, int& pos) {
	QRegExpValidator vld(QRegExp("^([0-9]{8})$"), 0);
	if(QValidator::Acceptable != vld.validate(input, pos))
		return QValidator::Invalid;

	int cs = 0;
	const char* buf = input.ascii();
	for(uint i = 0; i < input.length() - 1; i++)
		cs += (buf[i] - '0') * ((i % 2) ? 1 : 3);
	cs++;
	cs %= 10;
	cs = cs ? (10 - cs) : cs;
	return (('0' + cs) == buf[input.length() - 1] ? QValidator::Acceptable : QValidator::Invalid);
}