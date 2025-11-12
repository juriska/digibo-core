BEGIN
	DBMS_SCHEDULER.STOP_JOB('digibo$notify_rates_board', true);
END;
/
show err;

BEGIN
	DBMS_SCHEDULER.DROP_JOB('digibo$notify_rates_board', true);
END;
/
show err;

--

BEGIN
	DBMS_SCHEDULER.STOP_JOB('digibo$notify_ffo', true);
END;
/
show err;

BEGIN
	DBMS_SCHEDULER.DROP_JOB('digibo$notify_ffo', true);
END;
/
show err;

--

BEGIN
	DBMS_SCHEDULER.STOP_JOB('digibo$notify_investment', true);
END;
/
show err;

BEGIN
	DBMS_SCHEDULER.DROP_JOB('digibo$notify_investment', true);
END;
/
show err;

--

BEGIN
	DBMS_SCHEDULER.STOP_JOB('digibo$notify_mortgage_loans', true);
END;
/
show err;

BEGIN
	DBMS_SCHEDULER.DROP_JOB('digibo$notify_mortgage_loans', true);
END;
/
show err;

--

BEGIN
	DBMS_SCHEDULER.STOP_JOB('digibo$update_bo_permissions', true);
END;
/
show err;

BEGIN
	DBMS_SCHEDULER.DROP_JOB('digibo$update_bo_permissions', true);
END;
/
show err;
