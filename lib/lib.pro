include (../common.pro)

TARGET = ctx
TEMPLATE = lib 
CONFIG += qt staticlib release

HEADERS += appctx.h \
	trayicon.h

SOURCES += refresh.cpp \
	questions.cpp \
	currencies.cpp \
	officers.cpp \
	channels.cpp \
	countries.cpp \
	payment_template_groups.cpp \
	dp.cpp \
	envelope.cpp \
	escp_prn.cpp \
	doc01.cpp \
	doc02.cpp \
	doc03.cpp \
	doc04.cpp \
	doc05.cpp \
	doc06.cpp \
	doc07.cpp \
	doc08.cpp \
	doc09.cpp \
	doc10.cpp \
	doc11.cpp \
	doc12.cpp \
	doc13.cpp \
	doc14.cpp \
	doc15.cpp \
	doc16.cpp \
	doc17.cpp \
	doc18.cpp \
	docsms.cpp \
	docsmsview.cpp \
	docorderview.cpp \
	docvsaa1.cpp \
	cs.cpp \
	tray.cpp \
	trayicon.cpp \
	trayicon_win.cpp \
	cleanup.cpp \
	docext.cpp \
	devices.cpp \
	sellers.cpp \
	cru.cpp \
	rndpswd.cpp \
	tan_validator.cpp

TRANSLATIONS += liben.ts liblv.ts
