/************************** RBA database stored procedures ********************
 *    $Author: ury $
 *   $RCSfile: bo_sms.sql,v $
 *  $Revision: 1.7 $
 *        $Id: bo_sms.sql,v 1.7 2011/10/21 08:42:47 ury Exp $
 *
 ********* Copyright (c) 2001 Parex Bank, Latvia. All rights reserved *********/

CREATE OR REPLACE package BOSMS as

type cursor_t is ref cursor;

function load_user_data(
	pWocId in number,
	pUserName out varchar2,
	pLogin out varchar2,
	pLang out integer,
	pActive out integer,
	pAccept out integer
) return cursor_t;

end;
/

show err;

CREATE OR REPLACE package body BOSMS as

function load_user_data(
	pWocId in number,
	pUserName out varchar2,
	pLogin out varchar2,
	pLang out integer,
	pActive out integer,
	pAccept out integer
) return cursor_t is
	rv cursor_t;
begin
	select
		u.name,
		w.login,
		w.language_id,
		decode(w.status_id, RBA_CONST.USER_ACTIVE, 1, 0),
		w.accept_freeformat_sms
	into
		pUserName,
		pLogin,
		pLang,
		pActive,
		pAccept
	from ways_of_connection w, v$users u
	where w.user_id = u.id and w.id = pWocId;

	open rv for select 
		nvl(trim(decode(bocommon.LanguageId,
			0, c.name.name_lv,
			1, c.name.name_en,
			2, c.name.name_ru,
			3, c.name.extra_1,
			4, c.name.extra_2,
			5, c.name.extra_3,
			c.name.name_en
		)), c.name.name_en) name,
		c.id id
	from 
		v$customer_globus_restrictions cgr,
		cusd c
	where 
		cgr.woc_id = pWocId and 
		cgr.cusd_id = c.id and
		c.is_visible = 1;
	return rv;
end;

end;
/

show err;
