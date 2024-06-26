/datum/construction
	var/list/steps
	var/atom/holder
	var/result
	var/current_desc = null

/datum/construction/New(atom)
	..()
	holder = atom
	if(!holder) //don't want this without a holder
		qdel(src)
	set_desc(steps.len)

/datum/construction/Destroy(force)
	holder = null

	steps = null

	. = ..()

/datum/construction/proc/next_step()
	steps.len--
	if(!steps.len)
		spawn_result()
	else
		set_desc(steps.len)

/datum/construction/proc/action(atom/used_atom, mob/user)
	return

/datum/construction/proc/check_step(atom/used_atom, mob/user) //check last step only
	var/valid_step = is_right_key(used_atom)
	if(valid_step)
		if(custom_action(valid_step, used_atom, user))
			next_step()
			return TRUE
	return FALSE

/datum/construction/proc/is_right_key(atom/used_atom) // returns current step num if used_atom is of the right type.
	var/list/L = steps[steps.len]
	if(isobj(used_atom))
		var/return_value = check_tool_quality(used_atom, L["key"], steps.len)
		if(return_value)
			return return_value
	if(istype(used_atom, L["key"]))
		return steps.len
	return FALSE

/datum/construction/proc/custom_action(step, used_atom, user)
	return TRUE

/datum/construction/proc/check_all_steps(atom/used_atom, mob/user) //check all steps, remove matching one.
	for(var/i=1;i<=steps.len;i++)
		var/list/L = steps[i];
		if(istype(used_atom, L["key"]))
			if(custom_action(i, used_atom, user))
				steps[i]=null;//stupid byond list from list removal...
				listclearnulls(steps);
				if(!steps.len)
					spawn_result()
				return 1
	return 0


/datum/construction/proc/spawn_result()
	if(result)
		new result(get_turf(holder))
		QDEL_NULL(holder)

/datum/construction/proc/set_desc(index as num)
	var/list/step = steps[index]
	current_desc = step["desc"]

/datum/construction/proc/get_desc()
	return SPAN_NOTICE(current_desc)

/datum/construction/reversible
	var/index

/datum/construction/reversible/New(atom)
	..()
	index = steps.len

/datum/construction/reversible/proc/update_index(diff as num)
	index+=diff
	if(index==0)
		spawn_result()
	else
		set_desc(index)

/datum/construction/reversible/is_right_key(atom/used_atom) // returns index step
	var/list/L = steps[index]
	var/is_obj = FALSE
	if(isobj(used_atom))
		var/return_value = check_tool_quality(used_atom, L["key"], FORWARD)
		if(return_value)
			return return_value
		is_obj = TRUE
	if(istype(used_atom, L["key"]))
		return FORWARD //to the first step -> forward
	else if(L["backkey"])
		if(is_obj)
			var/return_value = check_tool_quality(used_atom, L["backkey"], BACKWARD)
			if(return_value)
				return return_value
		if(istype(used_atom, L["backkey"]))
			return BACKWARD //to the last step -> backwards
	return FALSE

/datum/construction/reversible/check_step(atom/used_atom, mob/user)
	var/diff = is_right_key(used_atom)
	if(diff)
		if(custom_action(index, diff, used_atom, user))
			update_index(diff)
			return TRUE
	return FALSE

/datum/construction/reversible/custom_action(index, diff, used_atom, user)
	return TRUE
