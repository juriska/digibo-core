/************************** RBA database stored procedures ********************
 *    $Author: ury $
 *   $RCSfile: bo_report.sql,v $
 *  $Revision: 1.8 $
 *        $Id: bo_report.sql,v 1.8 2011/10/10 14:43:15 ury Exp $
 *
 ********* Copyright (c) 2001 Parex Bank, Latvia. All rights reserved *********/

CREATE OR REPLACE package BOReport as

type cursor_t is ref cursor;

function unauthorizedConditions return cursor_t;

function unauthorizedUsers return cursor_t;

end;
/
show err;

CREATE OR REPLACE package body BOReport as

function unauthorizedConditions return cursor_t is
	rv cursor_t;
begin
	open rv for select * from (
		select distinct sct.cust_id custId,
			nvl(trim(decode(bocommon.LanguageId,
				0, c.name.name_lv,
				1, c.name.name_en,
				2, c.name.name_ru,
				3, c.name.extra_1,
				4, c.name.extra_2,
				5, c.name.extra_3,
				c.name.name_en
			)), c.name.name_en) custName,
			sct.change_officer changeOfficerId,
			o.phone changeOfficerPhone,
			sct.change_date changeDate
		from
			signature_conditions_tmp sct,
			cusd c,
			officers o
		where
			sct.cust_id = c.id
			and sct.change_officer = o.id
	)
	where rownum <= bocommon.ResultSetSize;
	return rv;
end;

function unauthorizedUsers return cursor_t is
	rv cursor_t;
begin
	open rv for select * from (
		select  cgr.woc_id,
			cgr.cusd_id custId,
			nvl(trim(decode(bocommon.LanguageId,
				0, c.name.name_lv,
				1, c.name.name_en,
				2, c.name.name_ru,
				3, c.name.extra_1,
				4, c.name.extra_2,
				5, c.name.extra_3,
				c.name.name_en
			)), c.name.name_en) custName,
			w.login login,
			u.name userName,
			u.personal_id personalId,
			w.change_officer_id changeOfficerId,
			o.phone changeOfficerPhone,			
			w.change_date changeDate
		from
			customer_globus_restrictions cgr,
			cusd c,
			ways_of_connection w,
			v$users u,
			officers o
		where (cgr.sign_level != nvl(cgr.sign_level_tmp, 0)
			or (cgr.sign_level is null and cgr.sign_level_tmp is not null))
			and cgr.cusd_id = c.id
			and cgr.woc_id = w.id
			and w.user_id = u.id
			and w.change_officer_id = o.id 
	)
	where rownum <= bocommon.ResultSetSize;
	return rv;
end;

end;
/
show err;
/
