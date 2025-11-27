#ifndef appctx_h
#define appctx_h

#include <qlistbox.h>
#include <qlistview.h>
#include <qcombobox.h>
#include <qlineedit.h>
#include <qstatusbar.h>
#include <qprogressbar.h>
#include <qaction.h>
#include <qpaintdevicemetrics.h>
#include <qvalidator.h>

#include <stuff.h>
#include <report.h>

#include "trayicon.h"
#include "envelope.h"

static const QRegExp FMT_AMOUNT("^([0-9]{1,10})|"
	"((\\.|\\,)[0-9]{1,2})|([0-9]{1,10}(\\.|\\,)[0-9]{1,2})");

static const QRegExp FMT_RATE("^([0-9]{1,11})|"
	"((\\.|\\,)[0-9]{1,6})|([0-9]{1,11}(\\.|\\,)[0-9]{1,6})");

static const QRegExp DOC_ID_MASK("\\d{0,14}");

static const QRegExp CUST_ID_MASK("\\d{0,10}");

const QString RSA_CONNECTION("RSA");

#define UID_PAM                3
#define UID_SEC                5
#define UID_MARGIN             6
#define UID_FFO                7

// Replication answers
static const int RE_NO_DATA_CUSTOMER = 1;
static const int RE_BACKEND_UNAVAILABLE = 2;
static const int RE_REPLICATION_UNAVAILABLE = 3;
static const int RE_REPLICATION_FAILED = 4;
static const int RE_NO_DATA_ACCOUNTS = 5;
//

class dao_t : public QListBoxText {
public:
	QString id, name;
	int level;

	dao_t(const QString& i = QString::null,
		const QString& n = QString::null,
		int l = 0) :
		id(i), name(n), level(l) {
		setText(name);
	}

	bool operator==(const dao_t& rhs) const { return name == rhs.name; }
	bool operator<(const dao_t& rhs) const { return name < rhs.name; }
};

typedef set< dao_t > daos_t;

class question_t : public QListBoxText {
public:
	enum { lv = 0, en, ru, de, se, ee };

	int id;
	QString name[6];

	question_t(int i) : id(i) {}
	question_t(
		int i,
		int l,
		const QString& name_lv,
		const QString& name_en,
		const QString& name_ru,
		const QString& name_de,
		const QString& name_se,
		const QString& name_ee
	) {
		id = i;
		name[lv] = name_lv;
		name[en] = name_en;
		name[ru] = name_ru;
		name[de] = name_de;
		name[se] = name_se;
		name[ee] = name_ee;
		setText(name[l]);
	}

	void lang(int lid) { setText(name[lid]); }

	bool operator==(const question_t& rhs) const { return id == rhs.id; }
	bool operator<(const question_t& rhs) const { return id < rhs.id; }
};

typedef set< question_t > questions_t;

class officer_t : public QListBoxText {
public:
	enum { OFFICER = 1, FAXPAYMENT = 2, FAXFFO = 4, FAXMANAGER = 8, FAXASSISTANT = 16, PERSONALOFFICER = 32, ADMIN = 64, ATTACHED = 128};

	int id, attr;
	QString name;

	officer_t(int i) : id(i), attr(0) {}
	officer_t(int i, const QString& n) : id(i), attr(0), name(n) { setText(name); }

	bool operator==(const officer_t& rhs) const { return id == rhs.id; }
	bool operator<(const officer_t& rhs) const { return id < rhs.id; }
};

typedef set< officer_t > officers_t;

class channel_t : public QListBoxText {
public:
	enum {WEB = 5, SMS = 6, WAP = 7, BO = 10, CLIENT = 20, FIRMA = 21, GATE =  27, QUICK_AUTH = 28, QUICK_BAL = 29,  FAX = 30, VOICE = 40, EMAIL = 50};
	enum {Active = 1, Inactive = 2, Closed = 3};

	int id;
	QString name;

	channel_t(int i) : id(i) {}
	channel_t(const QString& n, int i) : name(n), id(i)  { setText(name); }

	bool operator==(const channel_t& rhs) const { return id == rhs.id; }
	bool operator<(const channel_t& rhs) const { return id < rhs.id; }
};

typedef set< channel_t > channels_t;

class crypto_device_t : public QListBoxText {
public:
	enum {cDigiPass = 1, cTanCard = 2, cRsaKey = 3, cNoDevice = 4, cEEIdCard = 5, cronto = 9};

	int id;
	QString name;

	crypto_device_t(const QString& n, int i) : name(n), id(i)  { setText(name); }

	bool operator==(const channel_t& rhs) const { return id == rhs.id; }
	bool operator<(const channel_t& rhs) const { return id < rhs.id; }

	static void select(QComboBox* cb, int id);
};

class channel_check_t : public QCheckListItem {
private:
	int mId;

public:
	channel_check_t(QListView* lv, const QString& text, const int id)
		: QCheckListItem(lv, text, QCheckListItem::CheckBoxController), mId(id) {}

	const int id() { return mId; }
};

class country_t : public QListBoxText {
public:
	QString id, name, entry_legal_id, accept_legal_id;

	country_t(const QString& i) : id(i) {}
	country_t(const QString& i, const QString& n) : id(i), name(n)  { setText(name); }

	bool operator==(const country_t& rhs) const { return id == rhs.id; }
	bool operator<(const country_t& rhs) const { return id < rhs.id; }
};

typedef set< country_t > countries_t;

class payment_template_group_t : public QListBoxText {
public:
	QString id, name;

	payment_template_group_t(const QString& i) : id(i) {}
	payment_template_group_t(const QString& i, const QString& n) : id(i), name(n)  { setText(name); }

	bool operator==(const payment_template_group_t& rhs) const { return id == rhs.id; }
	bool operator<(const payment_template_group_t& rhs) const { return id < rhs.id; }
};

typedef set< payment_template_group_t > payment_template_groups_t;

class doc_type_t : public QListBoxPixmap {
public:
	QString values;

	doc_type_t(const QPixmap& g, const QString& t, const QString& v) :
		QListBoxPixmap(g, t), values(v) {}
};

class doc_text_type_t : public QListBoxText {
public:
	QString values;

	doc_text_type_t(const QString& t, const QString& v) : QListBoxText(t), values(v) {}
};

class doc_status_t : public QListBoxText {
public:
	enum {
		Executed = 1,
		InvSignature = 2,
		Rejected = 3,
		Delivered = 4,
		SignOK = 5,
		Draft = 6,
		AnswPending = 9,
		Printed = 11,
		SignChkPending = 12,
		ConfirmOK = 13,
		MsgGenerated = 14,
		MsgSent = 15,
		PartlyExec = 16,
		Processing = 19,
		BankT = 20,
		UserT = 21,
		Reversed = 22,
		Maturity = 23,
		MsgPending = 25,
		MsgFailed = 26,
		MsgGeneratedRejected = 27,
		MsgGeneratedReversed = 28,
		SignatureAdditional = 29,
		SignatureRejected = 30,
		PartlySucceed = 34,
		RequireLursoftCheck = 36,
		OperatorConfirmOK = 37,
		RejectedByVeriff = 38,
	    DeliveredGenesys = 39,
		TemplateShared = 44,
        AwaitingProcessing = 51,
		GlobusApproved = 52,
		SignatureOKFirstCoborrower = 54,
		DraftValidated = 61,
		ValidatedGlbWaiting = 62,
		WaitingForApproval = 81,
		ProcessingApproval = 82,
		WaitingForAuth = 83,
		ProcessingAuth = 84,
		RejectedByOndato = 85,
        WaitingPersonalDataCheck = 86,
		PersonalDataManualCompare = 87
	};

	QString values;

	doc_status_t(const QString& t, const QString& v) : QListBoxText(t), values(v) {}
};

class doc_channel_t : public QListBoxText {
public:
	QString values;

	doc_channel_t(const QString& t, const QString& v) :
		QListBoxText(t), values(v) {}
};

class doc_location_t : public QListBoxText {
public:
	QString values;

	doc_location_t(const QString& t, const QString& v) :
		QListBoxText(t), values(v) {}
};

class dictionary_item_t {
public:
	enum {
		MainTitle = 1,
		FirstTitle = 2,
		SecondTitle = 3,
		CheckBox = 4,
		InputText = 5,
		ComboBox = 6,
		Radio = 7,
		CbxItem = 8,
		RadioItem = 9,

//		Address = 10,
		BlockBegin = 11,
		BlockEnd = 12,

		Branch = 13,
		Country = 14,
		Currency = 15,

		Date = 16,
		DateFirstDay = 17,
		DateLastDay = 18,

		ActivityType = 19 // ref. to ibglb.cust_activity_type.
	};

	QString text, parent_id, card_group_id;
	int field_type, class_id;

	dictionary_item_t() : field_type(0), card_group_id(QString::null) {}
};

typedef map< unsigned int, dictionary_item_t, less<unsigned int> > map_dictionary_t;

class dictionary_t : public map_dictionary_t {
public:
	bool get_item(unsigned int id, dictionary_item_t& item) const {
		map_dictionary_t::const_iterator i = find(id);
		if(i != end()) {
			item = (*i).second;
			return true;
		}
		return false;
	}
};

class QSplashScreen;

class appctx_t : public oractx_t {
	Q_OBJECT

public:
	appctx_t(int argc, char* argv[]) : oractx_t(argc, argv),
		pb(0), sb(0), seeded(false),
		aprint(0), apreview(0), afind(0), asave(0), aopen(0), arefresh(0), aclear(0),
		lockTimeout(120), lockTimeoutDelta(30), resultSetSize(2000),
		AdjustXmm(2), AdjustYmm(-2), portFrom(0), portTo(0),
		ti_pamo(UID_PAM), ti_broker(UID_SEC), ti_margin(UID_MARGIN), ti_ffo(UID_FFO),
		pageLength(4), LeftMargin(2), vOffset1(1.3), vOffset2(1.9), DFvOffset1(1.9), DFvOffset2(1.3) {
		setPrintoutPath((QSettings*)this);
		init_channels();
	}

	QProgressBar *pb;
	QStatusBar *sb;
	QAction *aprint, *apreview, *afind, *asave, *aopen, *arefresh, *aclear;
	bool seeded, usrToCstNewWay;

	QString ib_host, rsa_host, ib_schema, rsa_schema, rsadev_host, listener,
		session_id, BoDi, crontoURL, crontoManagerURL, phoneProfileURL, psd2ConsentURL, gatewayManagerURL, bannerManagerURL, smsPasswordLength, pushNotificationsURL, ffoCategoriesBodiURL;

	// Notification sounds:
	QString Broker, Margin, PAMO, FFO;

	int lockTimeout, lockTimeoutDelta, resultSetSize, AdjustXmm, AdjustYmm,
		rsaNewCert, rsaRemCert, portFrom, portTo, crontoPrintDelay, documentsRefreshTimer;

	int loggedOfficerId;

	// Envelope print parameters section:
	int pageLength;
	double LeftMargin, vOffset1, vOffset2, DFvOffset1, DFvOffset2;
	//

	void refresh(QSplashScreen*);

	bool is_role(const QString& request);

	QString sessionID() const { return session_id; }

	daos_t sellers, depts;
	void add_daos(QComboBox* cb, const daos_t& data, int level = -1) const;
	void select_dao(QComboBox* cb, const QString& id) const;
	const QString get_dao(QComboBox* cb) const;

	questions_t questions;
	question_t get_question(int id) const;
	const QString get_question_name(const int id) const;
	const int get_question_id(const QString& n) const;
	const int get_question_id(QListBoxItem* i) const;
	void add_questions(QComboBox* cb, int id, const QString& special) const;
	void add_questions(QComboBox* cb) const;

	set_of_str currencies;
	void add_currencies(QComboBox* cb, const QString& exclude = QString::null) const;

	officers_t officers;
	void add_officers(QComboBox* cb, int attr = 0) const;
	const int get_officer_id(QListBoxItem* i) const;
	const QString get_officer_name(const int id, int attr = 0) const;

	channels_t channels;
	void add_channels(QComboBox* cb) const;
	void add_channels_check(QListView* lv) const;
	const int get_channel_id(QListBoxItem* i) const;
	const QString get_channel_name(const int id) const;

	countries_t countries;
	void add_countries(QComboBox* cb) const;
	const QString get_country_id(QListBoxItem* i) const;
	const QString get_country_entry_legal_id(QListBoxItem* i) const;
	const QString get_country_accept_legal_id(QListBoxItem* i) const;
	const QString get_country_name(const QString& id) const;
	
	payment_template_groups_t payment_template_groups;
	void add_payment_template_groups(QComboBox* cb) const;
	const QString get_payment_template_group_id(QListBoxItem* i) const;
	const QString get_payment_template_group_name(const QString& id) const;

	dictionary_t dictionary; // Client questionaire and card orders

	static QString get_doc_status(int value);
	static QString get_doc_type(int value);
	static QPixmap get_doc_channel_pixmap(int value);
	static QString get_doc_channel(int value);
	static QString get_doc_priority(int value);
	static QString get_doc_device_type(int value);
	static QString get_sms_status(int status_id);
	static QString get_order_status(int value); // PAM, Broker, Marginal docs

	static void setPaymentTypes(QComboBox* cb);
	static void setRequestToPayDocTypes(QComboBox* cb);
	static void setManualTypes(QComboBox* cb);
	static void setDDTypes(QComboBox* cb);
	static void setSTOTypes(QComboBox* cb);
	static void setMSDTypes(QComboBox* cb);
	static void setSMSTypes(QComboBox* cb);
	void setSMSViewTypes(QComboBox* cb);
	static void setPAMTypes(QComboBox* cb);
	static void setSecTypes(QComboBox* cb);
	static void setInsuranceTypes(QComboBox* cb);
	static void setMarginTypes(QComboBox* cb);
	static void setCQTypes(QComboBox* cb);
	static void setVSAAAdvAppTypes(QComboBox* cb);
	static void setOrderDocTypes(QComboBox* cb);
	static QString get_FFO_doc_type( int value);
	static QString get_Insurance_doc_type( int value);

	static void setDocumentChannels(QComboBox* cb);
	static void setDocumentLocations(QComboBox* cb);
	static void setManualStatuses(QComboBox* cb);
        static void setGlobusDocumentStatuses(QComboBox* cb, bool utility = false);
        static void setApplicationStatuses(QComboBox* cb);
	static void setSMSStatuses(QComboBox* cb);
	static void setOrderStatuses(QComboBox* cb); // PAM, Broker, Marginal docs
	static void setMLoanStatuses(QComboBox* cb);
	static void setMLoanDocTypes(QComboBox* cb);
	static void setCustodyStatuses(QComboBox* cb);
	static void setCustodyDocTypes(QComboBox* cb);
	static void setLeaseStatuses(QComboBox* cb);
	static void setLeaseDocTypes(QComboBox* cb);
	static void setFIAccOpenStatuses(QComboBox* cb);
	static void setFIAccOpenDocTypes(QComboBox* cb);
	static void setAccAdminStatuses(QComboBox* cb);
	static void setAccAdminDocTypes(QComboBox* cb);
	static void setAmexOrderStatuses(QComboBox* cb);
	static void setAmexOrderDocTypes(QComboBox* cb);
	static void setAmexOrderFormTypes(QComboBox* cb);
	static void setLeaseAppStatuses(QComboBox* cb);
	static void setLeaseAppDocTypes(QComboBox* cb);
	static void setCapfStatuses(QComboBox* cb);
	static void setCapfDocTypes(QComboBox* cb);
	static void setProdKitStatuses(QComboBox* cb);
	static void setProdKitDocTypes(QComboBox* cb);
	static void setCredLimIncStatuses(QComboBox* cb);
	static void setCredLimIncDocTypes(QComboBox* cb);
	static void setLifeAndPensionStatuses(QComboBox* cb);
	static void setLifeAndPensionDocTypes(QComboBox* cb, bool hasLifeAndPensionRole, bool hasPensAgreementRole);

	static void setVSAAAdvAppStatuses(QComboBox* cb);
	static void setCRUStatuses(QComboBox* cb);
	static void setGerDepStatuses(QComboBox* cb);
	static QValidator::State validatePinTan(QString& input, int& pos);

	QPoint dp(const QPaintDeviceMetrics& m, double x, double y) const;

	oci_connection_t* rsacon() {
		return con(RSA_CONNECTION, rsa_host);
	}

signals:
	void selectNewPam();
	void selectNewBroker();
	void selectNewMargin();
	void selectNewFfo();

public:
	TrayIcon ti_pamo, ti_broker, ti_margin, ti_ffo;

	void addTrayIcon(int type_id);
	void deleteTrayIcon(int type_id);
	void initializeTrayIcons();

public slots:
	void refresh();
	void cleanup();

	void pamoTrayIconSelected();
	void brokerTrayIconSelected();
	void marginTrayIconSelected();
	void ffoTrayIconSelected();

protected:
	void get_roles(connection_t* conn, const QString& grantee, str_t& roles);

	void read_ini();
	void read_questions();
	void read_currencies();
	void read_officers();
	void read_countries();
	void read_payment_template_groups();
	void read_dictionary(); // Client questionaire and card orders
	void read_sellers();
	void read_depts();
	void init_channels();
};

class trigger_event_t : public QCustomEvent {
public:
	trigger_event_t() : QCustomEvent(1001) {}
};

class document_event_t : public QCustomEvent {
public:
	QString id;

	document_event_t() : QCustomEvent(1002) {}
};

class comm_event_t : public QCustomEvent {
public:
	QString user_id, message_id;
	QDateTime timestamp;

	comm_event_t() : QCustomEvent(1003) {}
};

class rates_event_t : public QCustomEvent {
public:
	rates_event_t() : QCustomEvent(1004) {}
};

class notify_event_t : public QCustomEvent {
public:
	notify_event_t() : QCustomEvent(1004), message_id(0) {}

	int message_id;
};

QString commaSeparated(const QString& src);
const QString newPassword();

// Document extensions.

class exttext_item_t {
public:
	QString text; 
	int block, block_cnt;

	exttext_item_t();
	exttext_item_t(const QString& text, int block, int block_cnt);
};

typedef map < QString, exttext_item_t, less<QString> > extension_map_t;

class extensions_t : public extension_map_t {
public:
	bool load(appctx_t* ctx, const QString& id, const QString& procedure);
};

#endif // appctx_h
