#ifndef ESCP_PRINTER_H
#define ESCP_PRINTER_H

#include <QString.h>

class QWidget;

class EscpPrinter {
    enum {
        // Printer handle init level
        hilFull,
        hilPage,
        hilDoc,
        hilOpened,

        escEsc           =  27,
        escPageLen       = 'C',
        escFormFeed      =  12,
        escMoveDown      = 'J', // Advance print position vertically
        escMoveRight     = '$',
        escMoveDownInch  = 180,
        escMoveRightInch =  60

#if 0
	// Moved onto the context parameter.
        defPageLength    =   4 // DIGI::Envelope
#endif
    };

public:
    EscpPrinter(QWidget* _parent);
    virtual ~EscpPrinter();

    bool ok() const {return !prnName.isNull();}
    bool setup();
    void setPrinterName(const QString& name);
    void setDocumentName(const QString& name);

    void beginJob();

    void write(char* str, int sz);
    void write(const QString& str);
    void moveDown (double inch);
    void moveRight(double inch);

    void formFeed();
    void endJob(int hil = hilFull);

private:
    const QString exMsg(const QString& where) const;
    void initPageLength();

private:
    QWidget* parent;
    QString  prnName;
    QString  docName;
    void*    prn;
    int      pageLen;
};

#endif
