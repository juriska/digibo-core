#include <dlglogin.h>

#include "appctx.h"

const int appctx_t::get_question_id(QListBoxItem* i) const {
	question_t* q = dynamic_cast<question_t*>(i);
	return q ? q->id : 0;
}

const int appctx_t::get_question_id(const QString& n) const {
	for(questions_t::const_iterator i = questions.begin(); i != questions.end(); i++)
		if(n.upper() == (*i).name[lang].upper())
			return (*i).id;
	return 0;
}

question_t appctx_t::get_question(int id) const {
	questions_t::const_iterator i = questions.find(question_t(id));
	if(i != questions.end()) return *i;
	return question_t(id);
}

const QString appctx_t::get_question_name(const int id) const {
	questions_t::const_iterator i = questions.find(question_t(id));
	if(i != questions.end()) return (*i).name[lang];
	return QString::null;
}

void appctx_t::add_questions(QComboBox* cb, int id, const QString& special) const {
	cb->clear();
	if(!special.isEmpty()) {
		cb->insertItem(special);
		return;
	}
	questions_t::const_iterator i = questions.find(question_t(id));
	for(register int j = 0; j <= LoginDialog::MAX_INDEX; j++) {
		question_t* q = new question_t(*i);
		q->lang(j);
		cb->listBox()->insertItem(q);
	}
	cb->setCurrentItem(lang);
	cb->setEnabled(cb->count() > 1);
}

void appctx_t::add_questions(QComboBox* cb) const {
	cb->clear();
	cb->insertItem("");
	for(questions_t::const_iterator i = questions.begin(); i != questions.end(); i++) {
		question_t* q = new question_t(*i);
		q->lang(lang);
		cb->listBox()->insertItem(q);
	}
	cb->setEnabled(cb->count() > 1);
}
