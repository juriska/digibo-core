BEGIN
	DBMS_SCHEDULER.CREATE_JOB(
		job_name	=> 'digibo$notify_rates_board',
		job_type	=> 'stored_procedure',
		job_action	=> '&&ib_owner_name..bonotify.notify_rates_board',
		repeat_interval	=> 'FREQ = SECONDLY; INTERVAL = 60',
		comments	=> 'Rates boards.');
	DBMS_SCHEDULER.ENABLE(name => 'digibo$notify_rates_board');
	DBMS_SCHEDULER.RUN_JOB('digibo$notify_rates_board', true);
END;
/
show err;

BEGIN
	DBMS_SCHEDULER.CREATE_JOB(
		job_name	=> 'digibo$notify_ffo',
		job_type	=> 'stored_procedure',
		job_action	=> '&&ib_owner_name..bonotify.notify_ffo',
		repeat_interval	=> 'FREQ = SECONDLY; INTERVAL = 60',
		comments	=> 'New FFO.');
	DBMS_SCHEDULER.ENABLE(name => 'digibo$notify_ffo');
	DBMS_SCHEDULER.RUN_JOB('digibo$notify_ffo', true);
END;
/
show err;

BEGIN
	DBMS_SCHEDULER.CREATE_JOB(
		job_name	=> 'digibo$notify_investment',
		job_type	=> 'stored_procedure',
		job_action	=> '&&ib_owner_name..bonotify.notify_investment',
		repeat_interval	=> 'FREQ = SECONDLY; INTERVAL = 10',
		comments	=> 'New PAM, secure and marginal orders.');
	DBMS_SCHEDULER.ENABLE(name => 'digibo$notify_investment');
	DBMS_SCHEDULER.RUN_JOB('digibo$notify_investment', true);
END;
/
show err;

BEGIN
	DBMS_SCHEDULER.CREATE_JOB(
		job_name	=> 'digibo$notify_mortgage_loans',
		job_type	=> 'stored_procedure',
		job_action	=> '&&ib_owner_name..bonotify.notify_mortgage_loans',
		repeat_interval	=> 'FREQ = SECONDLY; INTERVAL = 600',
		comments	=> 'Mortgage loans.');
	DBMS_SCHEDULER.ENABLE(name => 'digibo$notify_mortgage_loans');
	DBMS_SCHEDULER.RUN_JOB('digibo$notify_mortgage_loans', true);
END;
/
show err;

BEGIN
	DBMS_SCHEDULER.CREATE_JOB(
		job_name	=> 'digibo$update_bo_permissions',
		job_type	=> 'stored_procedure',
		job_action	=> '&&ib_owner_name..bonotify.update_bo_permissions',
		repeat_interval	=> 'FREQ = SECONDLY; INTERVAL = 60',
		comments	=> 'Updates DIGI::BO officers view.');
	DBMS_SCHEDULER.ENABLE(name => 'digibo$update_bo_permissions');
	DBMS_SCHEDULER.RUN_JOB('digibo$update_bo_permissions', true);
END;
/
show err;
