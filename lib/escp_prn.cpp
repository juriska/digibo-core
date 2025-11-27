#include <windows.h>
#include <QPrinter.h>

#include "appctx.h"
#include "escp_prn.h"

#include <exception>
using namespace std;

static wchar_t docName [] = L"Direct print\0";
static wchar_t datatype[] = L"RAW\0";

extern appctx_t* appctx;

EscpPrinter::EscpPrinter(QWidget* _parent) : parent(_parent), 
	prnName(""), prn(0), pageLen(appctx->pageLength) {
}

EscpPrinter::~EscpPrinter() {
	endJob();
}

bool EscpPrinter::setup() {
	QPrinter qPrn;
	qPrn.setPrinterName(prnName);
	if(!qPrn.setup(parent)) return false;
	prnName = qPrn.printerName();
	return true;
}

void EscpPrinter::setPrinterName(const QString& name) {
	prnName = name;
	endJob();
}

void EscpPrinter::setDocumentName(const QString& name) {
	docName = name;
	endJob();
}

void EscpPrinter::beginJob() {
	if(prn) return;
	wchar_t doc_name[128]; 
	::memset(doc_name, 0, sizeof(doc_name));
	::wcsncpy(doc_name, (wchar_t*)docName.ucs2(), docName.length());
	DOC_INFO_1 di1;
	di1.pDocName    = doc_name;
	di1.pOutputFile = 0;
	di1.pDatatype   = datatype;
	if(!::OpenPrinter((wchar_t*)prnName.ucs2(), &prn, 0)) {
		prn = 0;
		throw exception(exMsg("beginJob.OpenPrinter").ascii());
	}
	if(!StartDocPrinter(prn, 1, (LPBYTE)&di1)) {
		endJob(hilOpened);
		throw exception(exMsg("beginJob.StartDocPrinter").ascii());
	}
	if(!StartPagePrinter(prn)) {
		endJob(hilDoc);
		throw exception(exMsg("beginJob.StartPagePrinter").ascii());
	}
	initPageLength();
}

void EscpPrinter::write(char* str, int sz) {
	if(!prn) throw exception(exMsg("write(prn is NULL)").ascii());
	DWORD written = 0;
	unsigned char assign_charset[8] = { escEsc, '(', 't', 3, 0, 0, 31, 0 };
	::WritePrinter(prn, assign_charset, 8, &written);
	char select_charset[3] = { escEsc, 't', 0 };
	::WritePrinter(prn, select_charset, 3, &written);
	
	/* Making bold
	char set_bold[3] = { escEsc, 'E', 0 };
	::WritePrinter(prn, set_bold, 3, &written);
	*/
	if(!::WritePrinter(prn, str, sz, &written))
		throw exception(exMsg("write.WritePrinter").ascii());
}

void EscpPrinter::write(const QString& str) {
	char* data = (char*)(str.ascii());
	write(data, ::strlen(data));
}

void EscpPrinter::moveDown(double inInch) {
	char MoveDown[] = {escEsc, escMoveDown, 0};
	for(; 0 < inInch; inInch -= 1.0) {
		*(MoveDown + 2) = escMoveDownInch * double(1 < inInch ? 1 : inInch);
		write(MoveDown, sizeof(MoveDown));
	}
}

void EscpPrinter::moveRight(double inch) {
	char MoveRight[] = {
		escEsc,
		escMoveRight, 
		int(inch * escMoveRightInch) % 256,
		int(inch * escMoveRightInch) / 256,
	};
	write(MoveRight, sizeof(MoveRight));
}

void EscpPrinter::formFeed() {
	char FormFeed[] = {escFormFeed};
	write(FormFeed, sizeof(FormFeed));
}

void EscpPrinter::endJob(int hil) {
	if(!prn) return;
	switch(hil) {
	case hilFull: case hilPage:
		EndPagePrinter(prn);
	case hilDoc:
		EndDocPrinter(prn);
	case hilOpened:
		ClosePrinter(prn);
		prn = 0;
	}
}

const QString EscpPrinter::exMsg(const QString& where) const {
	return QString("EscpPrinter::%1\n\tPrinter name = \'%2\'\n\tWindows error = %3\n").
		arg(where).arg(prnName).arg(GetLastError());
}

void EscpPrinter::initPageLength() {
	char SetPageLength[] = {escEsc, escPageLen, 0, pageLen};
	write(SetPageLength, sizeof(SetPageLength));
}
