
/datum/unit_test/vueui_monitors_watch_vars
	name = "VueUI: Var Monitors Have Populated Watch Lists"

/datum/unit_test/vueui_monitors_watch_vars/start_test()
	var/list/to_test = subtypesof(/datum/vueui_var_monitor)

	var/count_failed = 0
	for (var/path in to_test)
		var/datum/vueui_var_monitor/VM = new path()

		if (!VM.var_holders || !VM.var_holders.len)
			TEST_FAIL("VueUI var monitor has an empty var_holders list: [VM.type].")
			count_failed++

	if (count_failed)
		TEST_FAIL("\[[count_failed]\] VueUI var monitors without var holders discovered.")
	else
		TEST_PASS("All VueUI var monitors have var holders.")

	return TRUE


/datum/unit_test/vueui_monitors_have_valid_watchers
	name = "VueUI: Var Monitors Have Valid Keys"

/datum/unit_test/vueui_monitors_have_valid_watchers/start_test()
	var/list/to_test = subtypesof(/datum/vueui_var_monitor)

	var/count_failed = 0
	for (var/path in to_test)
		var/datum/vueui_var_monitor/VM = new path()
		var/datum/subject = null

		try
			subject = new VM.subject_type()
		catch ()
			TEST_FAIL("VueUI var monitor subject runtimed while being spawned. Monitor: [VM.type].")
			count_failed++
			continue

		if (!is_subject_valid(VM, subject))
			count_failed++

	if (count_failed)
		TEST_FAIL("\[[count_failed]\] VueUI var monitors have invalid var watches.")
	else
		TEST_PASS("All VueUI var monitors have valid var watchers.")

	return TRUE

/datum/unit_test/vueui_monitors_have_valid_watchers/proc/is_subject_valid(datum/vueui_var_monitor/VM, datum/subject)
	. = TRUE
	for (var/_iter in VM.var_holders)
		var/datum/vueui_var_holder/VH = _iter

		if (!VH.source_key || !VH.data_key)
			TEST_FAIL("VueUI var monitor has no source or data key: [VM.type].")
			. = FALSE
			continue

		if (!(VH.source_key in subject.vars))
			TEST_FAIL("VueUI var monitor is watching a var '[VH.source_key]' not found on the subject: [VM.type]. Subject: [subject.type].")
			. = FALSE
			continue
