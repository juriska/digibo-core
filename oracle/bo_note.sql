/************************** RBA database stored procedures ********************
 *    $Author: ury $
 *   $RCSfile: bo_note.sql,v $
 *  $Revision: 1.20 $
 *        $Id: bo_note.sql,v 1.20 2018/12/12 07:58:52 ury Exp $
 *
 ********* Copyright (c) 2001 Parex Bank, Latvia. All rights reserved *********/

CREATE OR REPLACE package BONote as

type cursor_t is ref cursor;

function products return cursor_t;

function find_notes(
	pSubj in varchar2,
	pText in varchar2,
	pCDevTypes in varchar2,
	pCorpTypes in varchar2,
	pResidTypes in varchar2,
	pCatInc in varchar2,
	pCatExc in varchar2,
	pDateFrom in date,
	pDateTill in date
) return cursor_t;

procedure load_note(
	pId in number,
	pFrom out date,
	pTill out date,
	pDevType out number,
	pCorpType out number,
	pResidType out number,

	pIsLv out number,
	pIsDe out number,
	pIsSe out number,
	pIsEe out number,
	pIsLt out number,
	

	pSubjEn out varchar2,
	pSubjLv out varchar2,
	pSubjRu out varchar2,
	pSubjDe out varchar2,
	pSubjSe out varchar2,
	pSubjEt out varchar2,
	pSubjLt out varchar2,

	pTextEn out varchar2,
	pTextLv out varchar2,
	pTextRu out varchar2,
	pTextDe out varchar2,
	pTextSe out varchar2,
	pTextEt out varchar2,
	pTextLt out varchar2,

	pChannels out cursor_t,
	pProducts out cursor_t
);

function load_note_history(pId in number) return cursor_t;

procedure set_note(
	pId in out number,
	pFrom in date,
	pTill in date,
	pDevType in number,
	pCorpType in number,
	pResidType in number,

	pIsLv in number,
	pIsDe in number,
	pIsSe in number,
	pIsEe in number,
	pIsLt in number,

	pSubjEn in varchar2,
	pSubjLv in varchar2,
	pSubjRu in varchar2,
	pSubjDe in varchar2,
	pSubjSe in varchar2,
	pSubjEt in varchar2,
	pSubjLt in varchar2,

	pTextEn in varchar2,
	pTextLv in varchar2,
	pTextRu in varchar2,
	pTextDe in varchar2,
	pTextSe in varchar2,
	pTextEt in varchar2,
	pTextLt in varchar2
);

procedure set_product(
	pId in number,
	pCatId in number,
	pVal in number
);

procedure set_channel(
	pId in number,
	pChannel in number
);

end;
/

show err;

CREATE OR REPLACE package body BONote as

function products return cursor_t is
	rv cursor_t;
begin
	open rv for select 
		c.id id, 
		nvl(trim(decode(bocommon.LanguageId,
			0, c.name.name_lv,
			1, c.name.name_en,
			2, c.name.name_ru,
			3, c.name.extra_1,
			4, c.name.extra_2,
			5, c.name.extra_3,
			6, c.name.extra_4,
			c.name.name_en
		)), c.name.name_en) name
	from glb_categories c
	where
		c.id < 10000
		or (c.id > 21000 and c.id < 22000); -- loans and deposites categories
	return rv;
end;

function find_notes(
	pSubj in varchar2,
	pText in varchar2,
	pCDevTypes in varchar2,
	pCorpTypes in varchar2,
	pResidTypes in varchar2,
	pCatInc in varchar2,
	pCatExc in varchar2,
	pDateFrom in date,
	pDateTill in date
) return cursor_t is 
	rv cursor_t;
	t_cdev_types num_table_type := bocommon.str2table(pCDevTypes);
	t_corp_types num_table_type := bocommon.str2table(pCorpTypes);
	t_resid_types num_table_type := bocommon.str2table(pResidTypes);
	t_cat_inc num_table_type := bocommon.str2table(pCatInc);
	t_cat_exc num_table_type := bocommon.str2table(pCatExc);
begin
	open rv for select
		n.id id,
		nvl(trim(decode(bocommon.LanguageId,
			0, n.subject.name_lv,
			1, n.subject.name_en,
			2, n.subject.name_ru,
			3, n.subject.extra_1,
			4, n.subject.extra_2,
			5, n.subject.extra_3,
			6, n.subject.extra_4,
			n.subject.name_en
		)), n.subject.name_en) subj,
		substr(nvl(trim(decode(bocommon.LanguageId,
			0, n.body.name_lv,
			1, n.body.name_en,
			2, n.body.name_ru,
			3, n.body.extra_1,
			4, n.body.extra_2,
			5, n.body.extra_3,
			6, n.body.extra_4,
			n.body.name_en)),
			n.body.name_en),
			1, 50) text,
		n.start_date startDate,
		n.end_date endDate
	from notices n
	where rownum <= bocommon.ResultSetSize and
		(pSubj is null
			or upper(n.subject.name_en) like bocommon.prepare_like(pSubj)
			or upper(n.subject.name_lv) like bocommon.prepare_like(pSubj)
			or upper(n.subject.name_ru) like bocommon.prepare_like(pSubj)
			or upper(n.subject.extra_1) like bocommon.prepare_like(pSubj)
			or upper(n.subject.extra_2) like bocommon.prepare_like(pSubj)
			or upper(n.subject.extra_3) like bocommon.prepare_like(pSubj)
			or upper(n.subject.extra_4) like bocommon.prepare_like(pSubj))
		and (pText is null
			or upper(n.body.name_en) like bocommon.prepare_like(pText)
			or upper(n.body.name_lv) like bocommon.prepare_like(pText)
			or upper(n.body.name_ru) like bocommon.prepare_like(pText)
			or upper(n.body.extra_1) like bocommon.prepare_like(pText)
			or upper(n.body.extra_2) like bocommon.prepare_like(pText)
			or upper(n.body.extra_3) like bocommon.prepare_like(pText)
			or upper(n.body.extra_4) like bocommon.prepare_like(pText))
		and (pCDevTypes is null or n.c_device_type_id in (select * from table(cast(t_cdev_types as num_table_type))))
		and (pCorpTypes is null or n.is_corporate in (select * from table(cast(t_corp_types as num_table_type))))
		and (pResidTypes is null or n.is_resident in (select * from table(cast(t_resid_types as num_table_type))))
		and ((pCatInc is null and pCatExc is null) 
			or n.id in (select notice_id from filter_categories
				where ((category_id in (select * from table(cast(t_cat_inc as num_table_type))))
						and link_type = 'I')
					or ((category_id in (select * from table(cast(t_cat_exc as num_table_type))))
						and link_type = 'E')))
		and (pDateFrom is null or ((n.start_date <= pDateTill and n.end_date >= pDateFrom)));
	return rv;
end;

procedure load_note(
	pId in number,
	pFrom out date,
	pTill out date,
	pDevType out number,
	pCorpType out number,
	pResidType out number,

	pIsLv out number,
	pIsDe out number,
	pIsSe out number,
	pIsEe out number,
	pIsLt out number,

	pSubjEn out varchar2,
	pSubjLv out varchar2,
	pSubjRu out varchar2,
	pSubjDe out varchar2,
	pSubjSe out varchar2,
	pSubjEt out varchar2,
	pSubjLt out varchar2,

	pTextEn out varchar2,
	pTextLv out varchar2,
	pTextRu out varchar2,
	pTextDe out varchar2,
	pTextSe out varchar2,
	pTextEt out varchar2,
	pTextLt out varchar2,

	pChannels out cursor_t,
	pProducts out cursor_t
) is begin
	select
		n.start_date,
		n.end_date,
		n.c_device_type_id,
		n.is_corporate,
		n.is_resident,

		nvl(n.is_location.company_1, 0), -- LV
		nvl(n.is_location.company_2, 0), -- DE
		nvl(n.is_location.company_3, 0), -- SE
		nvl(n.is_location.company_4, 0), -- EE
		nvl(n.is_location.company_5, 0), -- LT

		n.subject.name_en,
		n.subject.name_lv,
		n.subject.name_ru,
		n.subject.extra_1,
		n.subject.extra_2,
		n.subject.extra_3,
		n.subject.extra_4,

		n.body.name_en,
		n.body.name_lv,
		n.body.name_ru,
		n.body.extra_1,
		n.body.extra_2,
		n.body.extra_3,
		n.body.extra_4
	into
		pFrom,
		pTill,
		pDevType,
		pCorpType,
		pResidType,

		pIsLv,
		pIsDe,
		pIsSe,
		pIsEe,
		pIsLt,

		pSubjEn,
		pSubjLv,
		pSubjRu,
		pSubjDe,
		pSubjSe,
		pSubjEt,
		pSubjLt,

		pTextEn,
		pTextLv,
		pTextRu,
		pTextDe,
		pTextSe,
		pTextEt,
		pTextLt
	from 
		notices n
	where 
		n.id = pId;

	-- Note channels
	open pChannels for select channel_id
	from channels_for_notices
	where notice_id = pId;

	-- Note products
	open pProducts for select
		c.category_id catId, 
		decode(c.link_type, 'I', '1', 'E', '2') state
	from 
		filter_categories c
	where 
		c.notice_id = pId;
end;

function load_note_history(
	pId in number
) return cursor_t is
	rv cursor_t;
begin
	open rv for select
		n.change_date changeDate,
		n.change_officer_id changeOfficerId,
		n.channels_ids channels,
		n.start_date startDate,
		n.end_date endDate,
		n.c_device_type_id devType,
		n.is_corporate isCorp,
		n.is_resident isResid,

		nvl(n.is_location.company_1, 0) isLv, -- LV
		nvl(n.is_location.company_2, 0) isDe, -- DE
		nvl(n.is_location.company_3, 0) isSe, -- SE
		nvl(n.is_location.company_4, 0) isEe, -- EE
		nvl(n.is_location.company_5, 0) isLt, -- LT

		n.subject.name_en subjEn,
		n.subject.name_lv subjLv,
		n.subject.name_ru subjRu,
		n.subject.extra_1 subjDe,
		n.subject.extra_2 subjSe,
		n.subject.extra_3 subjEt,
		n.subject.extra_4 subjLt,

		n.body.name_en textEn,
		n.body.name_lv textLv,
		n.body.name_ru textRu,
		n.body.extra_1 textDe,
		n.body.extra_2 textSe,
		n.body.extra_3 textEt,
		n.body.extra_4 textLt
	from
		notices_hist n
	where
		n.notices_id = pId;
	return rv;
end;

procedure save2history(pId in varchar2) is
	cursor vCurA is 
		select channel_id 
		from channels_for_notices
		where notice_id = pId 
		order by channel_id;
	vChannels varchar2(50);
	vChnId int;
begin
	open vCurA;
	fetch vCurA into vChnId;
	if vCurA%FOUND then vChannels := vChnId; end if;
	fetch vCurA into vChnId;
	while vCurA%FOUND and Length(vChannels) + 4 < 50 Loop
		vChannels := vChannels||', '||vChnId;
		fetch vCurA into vChnId;
	end loop;

	insert into notices_hist (
		id,
		notices_id,
		start_date,
		end_date,
		subject,
		body,
		c_device_type_id,
		is_corporate,
		is_resident,
		is_location,
		channels_ids,
		change_officer_id,
		change_date
	) select 
		unq_notice_id_seq.NextVal,
		n.id,
		n.start_date,
		n.end_date,
		n.subject,
		n.body,
		n.c_device_type_id,
		n.is_corporate,
		n.is_resident,
		n.is_location,
		vChannels,
		n.change_officer_id,
		n.change_date
	from notices n
	where id = pId;

	insert into filter_categories_hist (
		history_id,
		category_id,
		link_type
	)
	select 
		unq_notice_id_seq.CurrVal,
		c.category_id,
		c.link_type
	from filter_categories c
	where c.notice_id = pId;
end;

procedure set_note(
	pId in out number,
	pFrom in date,
	pTill in date,
	pDevType in number,
	pCorpType in number,
	pResidType in number,

	pIsLv in number,
	pIsDe in number,
	pIsSe in number,
	pIsEe in number,
	pIsLt in number,

	pSubjEn in varchar2,
	pSubjLv in varchar2,
	pSubjRu in varchar2,
	pSubjDe in varchar2,
	pSubjSe in varchar2,
	pSubjEt in varchar2,
	pSubjLt in varchar2,

	pTextEn in varchar2,
	pTextLv in varchar2,
	pTextRu in varchar2,
	pTextDe in varchar2,
	pTextSe in varchar2,
	pTextEt in varchar2,
	pTextLt in varchar2
) is
begin
	if pId is null then
		insert into notices (
			id,
			start_date,
			end_date,
			c_device_type_id,
			is_corporate,
			is_resident,
			is_location,
			subject,
			body,
			change_officer_id,
			change_date
		) values (
			unq_notice_id_seq.NextVal,
			pFrom,
			pTill,
			pDevType,
			pCorpType,
			pResidType,
			multicompany_type(pIsLv, pIsDe, pIsSe, pIsEe, pIsLt, null, null, null, null, null),
			mlmsg_t(pSubjEn, pSubjLv, pSubjRu, pSubjDe, pSubjSe, pSubjEt, pSubjLt, null, null, null, null, null),
			mlmsg_t(pTextEn, pTextLv, pTextRu, pTextDe, pTextSe, pTextEt, pTextLt, null, null, null, null, null),
			bocommon.officerId,
			SysDate
		) returning id into pId;
	else
		update notices 
		set 
			start_date = pFrom,
			end_date = pTill,
			c_device_type_id = pDevType,
			is_corporate = pCorpType,
			is_resident = pResidType,
			is_location = multicompany_type(pIsLv, pIsDe, pIsSe, pIsEe, pIsLt, null, null, null, null, null),
			subject = mlmsg_t(pSubjEn, pSubjLv, pSubjRu, pSubjDe, pSubjSe, pSubjEt, pSubjLt, null, null, null, null, null),
			body = mlmsg_t(pTextEn, pTextLv, pTextRu, pTextDe, pTextSe, pTextEt, pTextLt, null, null, null, null, null),
			change_officer_id = bocommon.officerId,
			change_date = SysDate
		where id = pId;
	end if;

	save2history(pId);

	if pId is not null then
		delete from filter_categories c
		where 
			c.notice_id = pId;

		delete from channels_for_notices 
		where
			notice_id = pId;
	end if;
end;

procedure set_product(
	pId in number,
	pCatId in number,
	pVal in number
) is begin
	insert into filter_categories (
		notice_id,
		category_id,
		link_type
	) values (
		pId,
		pCatId,
		decode(pVal, 1, 'I', 2, 'E')
	);
end;

procedure set_channel(
	pId in number,
	pChannel in number
) is
	v int;
begin
	insert into channels_for_notices (notice_id, channel_id)
	values (pId, pChannel);
end;

end;
/

show err;
