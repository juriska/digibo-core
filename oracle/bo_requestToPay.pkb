CREATE OR REPLACE package body IB.BORequestToPay as

    function analyze(paymentId in varchar2) return documents.id%type is
        pid documents.id%type := null;
    begin
        if paymentId is null then
            return null;
        end if;
        select payment_id into pid from stmt
        where appl_rec_id = upper(paymentId) and rownum = 1;
        return pid;
    exception
        when NO_DATA_FOUND then
            begin
                pid := to_number(paymentId);
                return pid;
            exception
                when others then return null;
            end;
    end;

    function find_by_id(
        pId in documents.id%type,
        pmtClass in varchar2
    ) return cursor_t is
        rv cursor_t;
        t_classes num_table_type := bocommon.str2table(pmtClass);
    begin
        open rv for select /* BOPayment.find_by_id */
                        p.id id,
                        p.class_id class_id,
                        p.status_id status_id,
                        p.order_date order_date,
                        p.document_number document_number,
                        p.creator_channel_id creator_channel_id,
                        bocommon.FormatAmount(p.credit_amount, p.credit_ccy) credit_amount,
                        bocommon.FormatAmount(p.debit_amount, p.debit_ccy) debit_amount,
                        p.credit_ccy credit_ccy,
                        p.debit_ccy debit_ccy,
                        length(p.info_to_bank) ITB,
                        (select login from ways_of_connection where id = p.creator_woc_id) login,
                        p.creator_woc_id woc_id,
                        (select c.sector from cusd c where c.id = p.from_customer)sector,
                        (select c.segment from cusd c where c.id = p.from_customer)segment,
                        p.from_location fromLocation,
                        p.CB_PAYMENT_ID cb_payment_id,
                        p.DETAILS details,
                        p.FROM_ACCOUNT from_account
                    from documents p
                    where p.id = pid and
                            p.class_id in (select * from table(cast(t_classes as num_table_type)));
        return rv;
    end;

    function find_by_cb_payment_id(
        pId in varchar2,
        pmtClass in varchar2
    ) return cursor_t is
        rv cursor_t;
        t_classes num_table_type := bocommon.str2table(pmtClass);
    begin
        open rv for select /* BOPayment.find_by_id */
                        p.id id,
                        p.class_id class_id,
                        p.status_id status_id,
                        p.order_date order_date,
                        p.document_number document_number,
                        p.creator_channel_id creator_channel_id,
                        bocommon.FormatAmount(p.credit_amount, p.credit_ccy) credit_amount,
                        bocommon.FormatAmount(p.debit_amount, p.debit_ccy) debit_amount,
                        p.credit_ccy credit_ccy,
                        p.debit_ccy debit_ccy,
                        length(p.info_to_bank) ITB,
                        (select login from ways_of_connection where id = p.creator_woc_id) login,
                        p.creator_woc_id woc_id,
                        (select c.sector from cusd c where c.id = p.from_customer)sector,
                        (select c.segment from cusd c where c.id = p.from_customer)segment,
                        p.from_location fromLocation,
                        p.CB_PAYMENT_ID cb_payment_id,
                        p.DETAILS details,
                        p.FROM_ACCOUNT from_account
                    from documents p
                    where p.cb_payment_id = pid; /*and
                            p.class_id in (select * from table(cast(t_classes as num_table_type)));*/
        return rv;
    end;

    function find_by_reference(
        pReference in documents.bank_reference%type,
        pmtClass in varchar2
    ) return cursor_t is
        rv cursor_t;
        t_classes num_table_type := bocommon.str2table(pmtClass);
    begin
        open rv for select /* BOPayment.find_by_reference */
                        p.id id,
                        p.class_id class_id,
                        p.status_id status_id,
                        p.order_date order_date,
                        p.document_number document_number,
                        p.creator_channel_id creator_channel_id,
                        bocommon.FormatAmount(p.credit_amount, p.credit_ccy) credit_amount,
                        bocommon.FormatAmount(p.debit_amount, p.debit_ccy) debit_amount,
                        p.credit_ccy credit_ccy,
                        p.debit_ccy debit_ccy,
                        length(p.info_to_bank) ITB,
                        (select login from ways_of_connection where id = p.creator_woc_id) login,
                        p.creator_woc_id woc_id,
                        (select c.sector from cusd c where c.id = p.from_customer)sector,
                        (select c.segment from cusd c where c.id = p.from_customer)segment,
                        p.from_location fromLocation,
                        p.CB_PAYMENT_ID cb_payment_id,
                        p.DETAILS details,
                        p.FROM_ACCOUNT from_account
                    from documents p
                    where p.bank_reference = pReference and
                            p.class_id in (select * from table(cast(t_classes as num_table_type)));
        return rv;
    end;

    function execute_by_filter(
        pCursorName in integer
    ) return cursor_t is
        cursor_name integer := pCursorName;
        rv cursor_t;
        row req_to_pay_t;
        rows_processed integer;
        rowset req_to_pay_set_t := req_to_pay_set_t();
        id number(14);
        class_id number(3);
        status_id number(2);
        order_date date;
        document_number varchar2(16);
        creator_channel_id number(2);
        credit_amount varchar2(32);
        debit_amount varchar2(32);
        credit_ccy varchar2(3);
        debit_ccy varchar2(3);
        itb integer;
        login varchar2(60);
        woc_id number(10);
        sector number(5);
        segment varchar2(32);
        fromLocation varchar2(30);
        cb_payment_id varchar2(64);
        details varchar(402);
		from_account varchar(32);

    begin
        dbms_sql.define_column(cursor_name,  1, id);
        dbms_sql.define_column(cursor_name,  2, class_id);
        dbms_sql.define_column(cursor_name,  3, status_id);
        dbms_sql.define_column(cursor_name,  4, order_date);
        dbms_sql.define_column(cursor_name,  5, document_number, 16);
        dbms_sql.define_column(cursor_name,  6, creator_channel_id);
        dbms_sql.define_column(cursor_name,  7, credit_amount, 32);
        dbms_sql.define_column(cursor_name,  8, debit_amount, 32);
        dbms_sql.define_column(cursor_name,  9, credit_ccy, 3);
        dbms_sql.define_column(cursor_name, 10, debit_ccy, 3);
        dbms_sql.define_column(cursor_name, 11, itb);
        dbms_sql.define_column(cursor_name, 12, login, 60);
        dbms_sql.define_column(cursor_name, 13, woc_id);
        dbms_sql.define_column(cursor_name, 14, sector);
        dbms_sql.define_column(cursor_name, 15, segment, 32);
        dbms_sql.define_column(cursor_name,  16, fromLocation, 30);
        dbms_sql.define_column(cursor_name,  17, cb_payment_id, 64);
        dbms_sql.define_column(cursor_name,  18, details, 402);
        dbms_sql.define_column(cursor_name,  19, from_account, 32);

        rows_processed := dbms_sql.execute(cursor_name);

        while dbms_sql.fetch_rows(cursor_name) > 0 loop
                dbms_sql.column_value(cursor_name,  1, id);
                dbms_sql.column_value(cursor_name,  2, class_id);
                dbms_sql.column_value(cursor_name,  3, status_id);
                dbms_sql.column_value(cursor_name,  4, order_date);
                dbms_sql.column_value(cursor_name,  5, document_number);
                dbms_sql.column_value(cursor_name,  6, creator_channel_id);
                dbms_sql.column_value(cursor_name,  7, credit_amount);
                dbms_sql.column_value(cursor_name,  8, debit_amount);
                dbms_sql.column_value(cursor_name,  9, credit_ccy);
                dbms_sql.column_value(cursor_name, 10, debit_ccy);
                dbms_sql.column_value(cursor_name, 11, itb);
                dbms_sql.column_value(cursor_name, 12, login);
                dbms_sql.column_value(cursor_name, 13, woc_id);
                dbms_sql.column_value(cursor_name, 14, sector);
                dbms_sql.column_value(cursor_name, 15, segment);
                dbms_sql.column_value(cursor_name,  16, fromLocation);
                dbms_sql.column_value(cursor_name,  17, cb_payment_id);
                dbms_sql.column_value(cursor_name,  18, details);
                dbms_sql.column_value(cursor_name,  19, from_account);
                row := req_to_pay_t(
                        id,
                        class_id,
                        status_id,
                        order_date,
                        document_number,
                        creator_channel_id,
                        credit_amount,
                        debit_amount,
                        credit_ccy,
                        debit_ccy,
                        itb,
                        login,
                        woc_id,
                        sector,
                        segment,
                        fromLocation,
                        cb_payment_id,
                        details,
                        from_account
                    );
                rowset.extend;
                rowset(rowset.count) := row;
            end loop;

        dbms_sql.close_cursor(cursor_name);

        open rv for select * from table(cast(rowset as req_to_pay_set_t));
        return rv;

    exception when others then
        if dbms_sql.is_open(cursor_name) then
            dbms_sql.close_cursor(cursor_name);
        end if;
        raise;
    end;

    function find_by_filter(
        custId in varchar2,
        pCustName in varchar2,
        pUserLogin in varchar2,
        officerId in integer,
        benName in varchar2,
        fromContract in varchar2,
        fromLocation in varchar2,
        pmtDetails in varchar2,
        amountFrom in varchar2,
        amountTill in varchar2,
        currencies in varchar2,
        pmtClass in varchar2,
        effectFrom in date,
        effectTill in date,
        channels in varchar2,
        statuses in varchar2,
        createdFrom in date,
        createdTill in date
    ) return cursor_t is
        custName varchar2(1024) := bocommon.prepare_like(pCustName);
        userLogin varchar2(1024) := bocommon.prepare_like(pUserLogin);
        remoteId integer := BODocuments.get_remote_officer(officerId);
        rq varchar2(32767);
        cursor_name integer;
        channels_mod varchar2(100);
    begin
        if custName is not null or remoteId > 0 then
            delete from tmp_request_data;
            insert into tmp_request_data (requested_id)
            select distinct c.id from ibglb.cusd c
            where (remoteId <= 0 or	c.remote_officers.contains(remoteId) = 1) and
                (custName is null or c.name.is_like(custName) = 1);
        end if;

        channels_mod := channels;
        if channels_mod like '%5%' then
            null;
            channels_mod := channels_mod || ',28';
        end if;

        rq := 'select /* BOPayment.find_by_filter */';
        rq := rq || ' p.id id,';
        rq := rq || ' p.class_id class_id,';
        rq := rq || ' p.status_id status_id,';
        rq := rq || ' p.order_date order_date,';
        rq := rq || ' p.document_number document_number,';
        rq := rq || ' p.creator_channel_id creator_channel_id,';
        rq := rq || ' bocommon.FormatAmount(p.credit_amount, p.credit_ccy) credit_amount,';
        rq := rq || ' bocommon.FormatAmount(p.debit_amount, p.debit_ccy) debit_amount,';
        rq := rq || ' p.credit_ccy credit_ccy,';
        rq := rq || ' p.debit_ccy debit_ccy,';
        rq := rq || ' length(p.info_to_bank) ITB,';
        rq := rq || ' (select login from ways_of_connection where id = p.creator_woc_id) login';
        rq := rq || ' , p.creator_woc_id woc_id';
        rq := rq || ' ,(select c.sector from cusd c where c.id = p.from_customer)sector';
        rq := rq || ' ,(select c.segment from cusd c where c.id = p.from_customer)segment';
        rq := rq || ' , p.from_location fromLocation';
        rq := rq || ' , p.CB_PAYMENT_ID cb_payment_id';
        rq := rq || ' , p.details details';
        rq := rq || ' , p.FROM_ACCOUNT from_account';

        rq := rq || ' from documents p';
        rq := rq || ' where rownum <= :ResultSetSize';
        rq := rq || ' and ' || bocommon.order_date_expression(custId, custName, userLogin, remoteId);
        rq := rq || ' and p.class_id in (' || pmtClass || ')';
        rq := rq || ' and p.creator_channel_id in (' || channels_mod || ')'; -- implemented channels_mod instead of channels to add quick auth channel to internetbank 2016-09-21
        rq := rq || ' and p.status_id in (' || statuses || ')';
        rq := rq || ' and (p.status_id != 20 or p.template_bank_visible = 1)';
        rq := rq || ' and (p.from_account is null or p.from_account not in (select id from ibglb.acsd where iban in (''LV30PARX0002243540001'', ''LT167290099013025118'', ''EE831200001226850185'')))';

        if custId is not null then
            rq := rq || ' and p.from_customer = :CustomerId';
        end if;
        if currencies is not null then
            rq := rq || ' and (p.credit_ccy = :CCY or p.debit_ccy = :CCY)';
        end if;
        if amountFrom is not null and amountTill is not null then
            rq := rq || ' and (p.credit_amount between :AmountFrom and :AmountTill or ' ||
                  'p.debit_amount between :AmountFrom and :AmountTill)';
        end if;
        if benName is not null then
            rq := rq || ' and upper(p.ben_name) like :BenName';
        end if;
        if fromContract is not null then
            rq := rq || ' and upper(p.from_contract) like :FromContract';
        end if;
        if fromLocation is not null then
            rq := rq || ' and upper(p.from_location) like :FromLocation';
        end if;
        if pmtDetails is not null then
            rq := rq || ' and upper(p.details) like :Details';
        end if;
        if effectFrom is not null and effectTill is not null then
            rq := rq || ' and p.execution_date between :EffectFrom and :EffectTill';
        end if;
        if userLogin is not null then
            rq := rq || ' and p.creator_woc_id in (';
            rq := rq || ' select /*+ INDEX (w1 IDX_WOC_LOGIN) */ w1.id id';
            rq := rq || ' from ways_of_connection w1';
            rq := rq || ' where upper(w1.login) like :UserLogin';
            rq := rq || ' )';
        end if;
        if custName is not null or remoteId > 0 then
            rq := rq || ' and p.from_customer in (select requested_id from tmp_request_data)';
        end if;

        cursor_name := dbms_sql.open_cursor;

        dbms_sql.parse(cursor_name, rq, dbms_sql.native);
        dbms_sql.bind_variable(cursor_name, ':ResultSetSize', bocommon.ResultSetSize);
        dbms_sql.bind_variable(cursor_name, ':DateFrom', createdFrom);
        dbms_sql.bind_variable(cursor_name, ':DateTill', createdTill);
        if custId is not null then
            dbms_sql.bind_variable(cursor_name, ':CustomerId', custId);
        end if;
        if currencies is not null then
            dbms_sql.bind_variable(cursor_name, ':CCY', currencies);
        end if;
        if amountFrom is not null and amountTill is not null then
            dbms_sql.bind_variable(cursor_name, ':AmountFrom', amountFrom);
            dbms_sql.bind_variable(cursor_name, ':AmountTill', amountTill);
        end if;
        if benName is not null then
            dbms_sql.bind_variable(cursor_name, ':BenName', bocommon.prepare_like(benName));
        end if;
        if fromContract is not null then
            dbms_sql.bind_variable(cursor_name, ':FromContract', bocommon.prepare_like(fromContract));
        end if;
        if fromLocation is not null then
            dbms_sql.bind_variable(cursor_name, ':FromLocation', bocommon.prepare_like(fromLocation));
        end if;
        if pmtDetails is not null then
            dbms_sql.bind_variable(cursor_name, ':Details', bocommon.prepare_like(pmtDetails));
        end if;
        if effectFrom is not null and effectTill is not null then
            dbms_sql.bind_variable(cursor_name, ':EffectFrom', effectFrom);
            dbms_sql.bind_variable(cursor_name, ':EffectTill', effectTill);
        end if;
        if userLogin is not null then
            dbms_sql.bind_variable(cursor_name, ':UserLogin', userLogin);
        end if;

        return execute_by_filter(cursor_name);
    end;

    function find(
        -- remitter
        custId in varchar2,
        custName in varchar2,
        userLogin in varchar2,
        officerId in integer,

        -- payment
        benName in varchar2,
        fromContract in varchar2,
        fromLocation in varchar2,
        pmtDetails in varchar2,
        amountFrom in varchar2,
        amountTill in varchar2,
        currencies in varchar2,
        pmtClass in varchar2,
        effectFrom in date,
        effectTill in date,

        -- system
        paymentId in varchar2,
        cbPaymentId in varchar2,
        channels in varchar2,
        statuses in varchar2,
        createdFrom in date,
        createdTill in date
    ) return cursor_t is
        pid documents.id%type := analyze(paymentId);
    begin

        if pid is not null then
            return find_by_id(pid, pmtClass);
        elsif paymentId is not null then
            return find_by_reference(paymentId, pmtClass);
        end if;

        if cbPaymentId is not null then
            return find_by_cb_payment_id(cbPaymentId, pmtClass);
        end if;

        return find_by_filter(
                custId,
                custName,
                userLogin,
                officerId,
                benName,
                fromContract,
                fromLocation,
                pmtDetails,
                amountFrom,
                amountTill,
                currencies,
                pmtClass,
                effectFrom,
                effectTill,
                channels,
                statuses,
                createdFrom,
                createdTill
            );
    end;

end;
/
