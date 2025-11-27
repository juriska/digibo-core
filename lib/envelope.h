#ifndef envelopeH
#define envelopeH

#include "escp_prn.h"

class QWidget;

class DigiEnvelope : public EscpPrinter {
#if 0
	// Moved onto the context parameters.
	enum { PageLen    =  4, LeftMargin =  2 };
#endif

public:
	DigiEnvelope(QWidget* _parent);
	~DigiEnvelope() {}

	void print(const QString& visible, const QString& hidden);
};

#endif
