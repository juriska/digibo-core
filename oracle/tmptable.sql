drop table tmp_customer_history;

create global temporary table tmp_customer_history (
	change_date DATE,
	change_officer VARCHAR2(70),
	woc_id NUMBER(10) NOT NULL,
	hist_id NUMBER(10),
	login VARCHAR2(60),
	license VARCHAR2(15),
	status_id NUMBER(2),
	cust_id NUMBER(10),
	user_name VARCHAR2(210)
) on commit delete rows;
/
