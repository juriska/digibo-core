#include <openssl/rand.h>
#include <openssl/evp.h>

#include <qsplashscreen.h>

#include "appctx.h"

static const QString role_prefix("ROLE_");

static Config ini;

void appctx_t::refresh() {
	refresh(0);
}

void appctx_t::refresh(QSplashScreen* splash) {
	ini.open(iniFile());

	ini.setGroup("ora");
	ib_host = ini.readEntry("ibhost");
	rsa_host = ini.readEntry("rsahost");
	ib_schema = ini.readEntry("ib");
	rsa_schema = ini.readEntry("rsa");

	if(splash) {
		if(!con(QString::null, ib_host)) ::exit(1);
		splash->message("Retrieving roles.");
		splash->show();
	}
	str_t roles;
	get_roles(con(), con()->get_user(), roles);
	for(str_t::const_iterator i = roles.begin(); i != roles.end(); ++i)
		setValue(role_prefix + (*i), 1);

	if(splash) splash->message("Reading application parameters.");
	read_ini();

	ini.setGroup("static");

	QString expr = ini.readEntry("questions");
	if(cond.doIt(expr.latin1())) {
		if(splash) splash->message("Loading questions.");
		read_questions();
	}

	expr = ini.readEntry("currencies");
	if(!expr.isEmpty() && cond.doIt(expr.latin1())) {
		if(splash) splash->message("Loading currencies.");
		read_currencies();
	}

	expr = ini.readEntry("officers");
	if(!expr.isEmpty() && cond.doIt(expr.latin1())) {
		if(splash) splash->message("Loading officers.");
		read_officers();
	}

	expr = ini.readEntry("countries");
	if(!expr.isEmpty() && cond.doIt(expr.latin1())) {
		if(splash) splash->message("Loading countries.");
		read_countries();
	}
	
	//expr = ini.readEntry("countries");
	//if(!expr.isEmpty() && cond.doIt(expr.latin1())) {
	//	if(splash) splash->message("Loading countries.");
		read_payment_template_groups();
//	}

	expr = ini.readEntry("dictionary");
	if(!expr.isEmpty() && cond.doIt(expr.latin1())) {
		if(splash) splash->message("Loading dictionary.");
		read_dictionary();
	}

	expr = ini.readEntry("sellers");
	if(!expr.isEmpty() && cond.doIt(expr.latin1())) {
		if(splash) splash->message("Loading sellers.");
		read_sellers();
	}

	expr = ini.readEntry("depts");
	if(!expr.isEmpty() && cond.doIt(expr.latin1())) {
		if(splash) splash->message("Loading departaments.");
		read_depts();
	}

	expr = ini.readEntry("usrToCstNewWay");
	if(!expr.isEmpty() && cond.doIt(expr.latin1())) {
		usrToCstNewWay = true;
	}
}

void appctx_t::get_roles(connection_t* conn, const QString& grantee, str_t& roles) {
	rset_t r(conn, "context::get_plain_roles");
	if(r.parse(QString("%1.bocommon.get_plain_roles").arg(ib_schema))) ::exit(1);
	r["pGrantee"]->asString() = grantee;
	r["pResult"]->asString() = QString::null;
	if(r.exec()) ::exit(1);
	QString t1(r["pResult"]->asString()), t2;
	for(register int i = 0; !(t2 = t1.section(';', i, i)).isEmpty(); ++i)
		roles.insert(t2);
	if(!seeded) {
		QString t;
		t += get_name();
		t += t1;
		RAND_seed(t.utf8().data(), t.utf8().length());
		seeded = true;
		unsigned char buff1[24], buff2[48];
		::memset(buff1, 0, sizeof(buff1));
		::memset(buff2, 0, sizeof(buff2));
		RAND_bytes(buff1, sizeof(buff1));
		EVP_EncodeBlock(buff2, buff1, sizeof(buff1));
		session_id = (char*)buff2;
		session_id.remove('+').remove('/').remove('=');
	}
}

bool appctx_t::is_role(const QString& request) {
	return bool(getValue(role_prefix + request));
}

void appctx_t::read_ini() {
	ini.setGroup("printer");
	AdjustXmm = ini.readNumEntry("AdjustXmm", AdjustXmm);
	AdjustYmm = ini.readNumEntry("AdjustYmm", AdjustYmm);

	ini.setGroup("envelope");
	pageLength = ini.readNumEntry("PageLength", pageLength);
	LeftMargin = ini.readEntry("LeftMargin", "2").toDouble();
	vOffset1 = ini.readEntry("vOffset1", "1.3").toDouble();
	vOffset2 = ini.readEntry("vOffset2", "1.9").toDouble();
	DFvOffset1 = ini.readEntry("dfvOffset1", "1.9").toDouble();
	DFvOffset2 = ini.readEntry("dfvOffset2", "1.3").toDouble();

	ini.setGroup("common");
	lockTimeout = ini.readNumEntry("LockTimeout", lockTimeout);
	if(lockTimeout < 120) lockTimeout = 120;
	if(lockTimeout > 3600) lockTimeout = 3600;
	lockTimeoutDelta = ini.readNumEntry("LockTimeoutDelta", lockTimeoutDelta);
	if(lockTimeoutDelta < 0) lockTimeoutDelta = 0;
	if(lockTimeoutDelta > 3600) lockTimeoutDelta = 3600;
	resultSetSize = ini.readNumEntry("ResultSetSize", resultSetSize);
	QString t(ini.readEntry("port"));
	portFrom = t.section(',', 0, 0).toInt();
	portTo = t.section(',', 1, 1).toInt();
	crontoPrintDelay = ini.readNumEntry("crontoPrintDelay", crontoPrintDelay);
	documentsRefreshTimer = ini.readNumEntry("documentsRefreshTimer", documentsRefreshTimer);


	ini.setGroup("helpdesk");
	int hdals = ini.readNumEntry("AuditLogSize", 100);

	ini.setGroup("rsa");
	rsadev_host = ini.readEntry("Address");
	rsaNewCert = ini.readNumEntry("NewCert", rsaNewCert);
	rsaRemCert = ini.readNumEntry("RemCert", rsaRemCert);

	rset_t r(con(), "context::set_params");
	if(r.parse(QString("%1.bocommon.set_params").arg(ib_schema))) ::exit(1);
	r["rss"]->asUInt() = resultSetSize;
	r["hdals"]->asUInt() = hdals;
	r["lang"]->asInt() = getLanguage();
	if(r.exec()) ::exit(1);

	ini.setGroup("notification");
	Broker = ini.readEntry("Broker");
	Margin = ini.readEntry("Margin");
	PAMO = ini.readEntry("PAMO");
	FFO = ini.readEntry("FFO");

	ini.setGroup("links");
	BoDi = ini.readEntry("BoDi");
	crontoURL = ini.readEntry("crontoURL");
	crontoManagerURL = ini.readEntry("crontoManagerURL");
	phoneProfileURL = ini.readEntry("phoneProfileURL");
	psd2ConsentURL = ini.readEntry("psd2ConsentURL");
	pushNotificationsURL = ini.readEntry("pushNotificationsURL");
	gatewayManagerURL = ini.readEntry("gatewayManagerURL");
	bannerManagerURL = ini.readEntry("bannerManagerURL");
	smsPasswordLength = ini.readEntry("smsPasswordLength");
	ffoCategoriesBodiURL = ini.readEntry("ffoCategoriesBodiURL");
}

void appctx_t::read_questions() {
	questions.clear();
	rset_t r(con(), "context::read_questions");
	if(r.parse(QString("%1.bocommon.get_questions").arg(ib_schema))) ::exit(1);
	if(r.exec()) ::exit(1);
	for(rset_t &cur = r.result()->asRSet(); !cur.fetch();) {
		question_t q(
			cur["id"]->asInt(),
			lang,
			cur["name_lv"]->asString(),
			cur["name_en"]->asString(),
			cur["name_ru"]->asString(),
			cur["name_de"]->asString(),
			cur["name_se"]->asString(),
			cur["name_ee"]->asString()
		);
		questions.insert(q);
	}
}

void appctx_t::read_currencies() {
	currencies.clear();
	rset_t r(con(), "context::read_currencies");
	if(r.parse(QString("%1.bocommon.get_currencies").arg(ib_schema))) ::exit(1);
	if(r.exec()) ::exit(1);
	for(rset_t &cur = r.result()->asRSet(); !cur.fetch();)
		currencies.insert(cur["id"]->asString());
}

void appctx_t::read_officers() {
	officers.clear();
	rset_t r(con(), "context::read_officers");
	if(r.parse(QString("%1.bocommon.get_officers").arg(ib_schema))) ::exit(1);
	if(r.exec()) ::exit(1);
	loggedOfficerId = r["pLoggedOfficerId"]->asInt();
	for(rset_t &cur = r.result()->asRSet(); !cur.fetch();) {
		officer_t o(cur["id"]->asInt(), cur["name"]->asString());
		if(cur["attached"]->asInt()) o.attr |= officer_t::ATTACHED;
		QString roles = cur["roles"]->asString();
		if(roles.find("RBOFAXPAYMENT") > -1) o.attr |= officer_t::FAXPAYMENT;
		if(roles.find("RBOFAXFFO") > -1) o.attr |= officer_t::FAXFFO;
		if(roles.find("RBOFAXMANAGER") > -1) o.attr |= officer_t::FAXMANAGER;
		if(roles.find("RBOFAXASSISTANT") > -1) o.attr |= officer_t::FAXASSISTANT;
		if(roles.find("RBOPERSONALOFFICER") > -1) o.attr |= officer_t::PERSONALOFFICER;
		if(roles.find("RBOADMIN") > -1) o.attr |= officer_t::ADMIN;
		officers.insert(o);
	}
}

void appctx_t::read_countries() {
	countries.clear();
	rset_t r(con(), "context::read_countries");
	if(r.parse(QString("%1.bocommon.get_countries").arg(ib_schema))) ::exit(1);
	if(r.exec()) ::exit(1);
	for(rset_t &cur = r.result()->asRSet(); !cur.fetch();) {
		QString cid(cur["id"]->asString());
		country_t o(cid, cur["name"]->asString());
		if("LV" == cid) {
			o.entry_legal_id = "[0-9]{0,6}\\-[0-9]{0,5}";
			o.accept_legal_id = "[0-9]{6}\\-[0-9]{5}";
		}
		else if("SE" == cid) {
			o.entry_legal_id = "[0-9]{0,6}\\-[0-9]{0,4}";
			o.accept_legal_id = "[0-9]{6}\\-[0-9]{4}";
		}
		else if("EE" == cid) {
			o.entry_legal_id = "[0-9]{0,11}";
			o.accept_legal_id = "[0-9]{11}";
		}
		countries.insert(o);
	}
}

void appctx_t::read_payment_template_groups() {
	payment_template_groups.clear();
	rset_t r(con(), "context::read_payment_template_groups");
	if(r.parse(QString("%1.bocommon.get_payment_template_groups").arg(ib_schema))) ::exit(1);
	if(r.exec()) ::exit(1);
	for(rset_t &cur = r.result()->asRSet(); !cur.fetch();) {
		QString cid(cur["id"]->asString());
		payment_template_group_t o(cid, cur["name"]->asString());
/*		if("LV" == cid) {
			o.entry_legal_id = "[0-9]{0,6}\\-[0-9]{0,5}";
			o.accept_legal_id = "[0-9]{6}\\-[0-9]{5}";
		}
		else if("SE" == cid) {
			o.entry_legal_id = "[0-9]{0,6}\\-[0-9]{0,4}";
			o.accept_legal_id = "[0-9]{6}\\-[0-9]{4}";
		}
		else if("EE" == cid) {
			o.entry_legal_id = "[0-9]{0,11}";
			o.accept_legal_id = "[0-9]{11}";
		}
*/
		payment_template_groups.insert(o);
	}
}

void appctx_t::read_dictionary() {
	dictionary.clear();
	rset_t r(con(), "context::dictionary");
	if(r.parse(QString("%1.bocommon.get_dictionary").arg(ib_schema))) ::exit(1);
	if(r.exec()) ::exit(1);
	rset_t &rv = r.result()->asRSet();
	while(!rv.fetch(true)) {
		dictionary_item_t item;
		item.class_id = rv["f_class_id"]->asInt();
		item.parent_id = rv["f_parent_id"]->asString();
		item.card_group_id = rv["f_card_group_id"]->asString();
		item.field_type = rv["f_field_type"]->asInt();
		QString t = rv["f_name"]->asString();
		t.replace(QChar(0x203B), "<br>");
		t.replace(QChar(0x2026), "...");
		t.replace(QChar(0x2057), "\"");
		t.replace(QChar(0x2039), "<");
		t.replace(QChar(0x203A), ">");
		item.text = t;
		dictionary[rv["f_id"]->asUInt()] = item;
	}
}

void appctx_t::read_sellers() {
	sellers.clear();
	rset_t r(con(), "context::sellers");
	if(r.parse(QString("%1.bocommon.get_sellers").arg(ib_schema))) ::exit(1);
	if(r.exec()) ::exit(1);
	rset_t &rv = r.result()->asRSet();
	while(!rv.fetch(true)) {
		sellers.insert(dao_t(rv["id"]->asString(), rv["name"]->asString()));
	}
}

void appctx_t::read_depts() {
	depts.clear();
	rset_t r(con(), "context::depts");
	if(r.parse(QString("%1.bocommon.get_depts").arg(ib_schema))) ::exit(1);
	if(r.exec()) ::exit(1);
	rset_t &rv = r.result()->asRSet();
	while(!rv.fetch(true)) {
		depts.insert(
			dao_t(rv["id"]->asString(),
				rv["name"]->asString(),
				rv["dept_level"]->asInt()
			)
		);
	}
}
