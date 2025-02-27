/*
adds a dizziness amount to a mob
use this rather than directly changing var/dizziness
since this ensures that the dizzy_process proc is started
currently only humans get dizzy

value of dizziness ranges from 0 to 1000
below 100 is not dizzy
*/

/mob/var/dizziness = 0//Carbon
/mob/var/is_dizzy = 0

/mob/proc/make_dizzy(var/amount)
	if(!istype(src, /mob/living/carbon/human)) // for the moment, only humans get dizzy
		return

	dizziness = min(1000, dizziness + amount)	// store what will be new value
													// clamped to max 1000
	if(dizziness > 100 && !is_dizzy)
		spawn(0)
			dizzy_process()


/*
dizzy process - wiggles the client's pixel offset over time
spawned from make_dizzy(), will terminate automatically when dizziness gets <100
note dizziness decrements automatically in the mob's Life() proc.
*/
/mob/proc/dizzy_process()
	is_dizzy = 1
	while(dizziness > 100)
		if(client)
			var/amplitude = dizziness*(sin(dizziness * 0.044 * world.time) + 1) / 70
			client.pixel_x = amplitude * sin(0.008 * dizziness * world.time)
			client.pixel_y = amplitude * cos(0.008 * dizziness * world.time)

		sleep(1)
	//endwhile - reset the pixel offsets to zero
	is_dizzy = 0
	if(client)
		client.pixel_x = 0
		client.pixel_y = 0

// jitteriness - copy+paste of dizziness
/mob/var/is_jittery = 0
/mob/var/jitteriness = 0//Carbon
/mob/proc/make_jittery(var/amount)
	return

/mob/living/carbon/human/make_jittery(amount)	
	jitteriness = min(1000, jitteriness + amount)	// store what will be new value
													// clamped to max 1000
	if(jitteriness > 100 && !is_jittery && stat != DEAD && !(status_flags & FAKEDEATH))
		spawn(0)
			jittery_process()

/mob/proc/jittery_process()
	is_jittery = TRUE
	while(jitteriness > 100)
		var/amplitude = min(4, jitteriness / 100)
		pixel_x = old_x + rand(-amplitude, amplitude)
		pixel_y = old_y + rand(-amplitude/3, amplitude/3)
		if(stat == DEAD || (status_flags & FAKEDEATH))
			break
		sleep(1)
	//endwhile - reset the pixel offsets to zero
	is_jittery = FALSE
	pixel_x = old_x
	pixel_y = old_y


//handles up-down floaty effect in space and zero-gravity
/mob/var/is_floating = FALSE

/mob/proc/update_floating()
	if(anchored || buckled_to)
		set_floating(FALSE)
		return

	var/turf/turf = get_turf(src)
	if(!turf?.is_hole)
		var/area/A = turf.loc
		if(istype(A) && A.has_gravity())
			set_floating(FALSE)
			return
		else
			var/shoegrip = Check_Shoegrip()
			if(shoegrip)
				set_floating(FALSE)
				return
	else
		if(CanAvoidGravity())
			set_floating(TRUE)
			return
		else
			set_floating(FALSE)
			return

	set_floating(TRUE)

/mob/proc/set_floating(var/floating_state)
	if(buckled_to && is_floating)
		stop_floating()
		return

	if(floating_state && !is_floating)
		start_floating()
	else if(!floating_state && is_floating)
		stop_floating()

/mob/proc/start_floating()
	is_floating = TRUE

	var/amplitude = 2 //maximum displacement from original position
	var/period = 36 //time taken for the mob to go up >> down >> original position, in deciseconds. Should be multiple of 4

	var/top = old_y + amplitude
	var/bottom = old_y - amplitude
	var/half_period = period / 2
	var/quarter_period = period / 4

	animate(src, pixel_y = top, time = quarter_period, easing = SINE_EASING | EASE_OUT, loop = -1)		//up
	animate(pixel_y = bottom, time = half_period, easing = SINE_EASING, loop = -1)						//down
	animate(pixel_y = old_y, time = quarter_period, easing = SINE_EASING | EASE_IN, loop = -1)			//back

/mob/proc/stop_floating()
	animate(src, pixel_y = get_standard_pixel_y(), time = 5, easing = SINE_EASING | EASE_IN) //halt animation
	//reset the pixel offsets to defaults
	is_floating = FALSE

/atom/movable/proc/do_attack_animation(atom/A, atom/movable/weapon, var/image/attack_image, var/initial_pixel_x = 0, var/initial_pixel_y = 0)
	var/pixel_x_diff = 0
	var/pixel_y_diff = 0
	var/turn_dir = 1

	var/direction = get_dir(src, A)
	switch(direction)
		if(NORTH)
			pixel_y_diff = 8
		if(SOUTH)
			pixel_y_diff = -8
		if(EAST)
			pixel_x_diff = 8
		if(WEST)
			pixel_x_diff = -8
		if(NORTHEAST)
			pixel_x_diff = 8
			pixel_y_diff = 8
		if(NORTHWEST)
			pixel_x_diff = -8
			pixel_y_diff = 8
		if(SOUTHEAST)
			pixel_x_diff = 8
			pixel_y_diff = -8
		if(SOUTHWEST)
			pixel_x_diff = -8
			pixel_y_diff = -8
	if(direction & NORTH)
		pixel_y_diff = 8
		turn_dir = rand(50) ? -1 : 1
	else if(direction & SOUTH)
		pixel_y_diff = -8
		turn_dir = rand(50) ? -1 : 1

	if(direction & EAST)
		pixel_x_diff = 8
	else if(direction & WEST)
		pixel_x_diff = -8
		turn_dir = -1

	if(!initial_pixel_x)
		initial_pixel_x = initial(pixel_x)
	if(!initial_pixel_y)
		initial_pixel_y = initial(pixel_y)

	animate(src, pixel_x = pixel_x + pixel_x_diff, pixel_y = pixel_y + pixel_y_diff, time = 2)
	animate(pixel_x = initial_pixel_x, pixel_y = initial_pixel_y, time = 2)
	var/matrix/initial_transform = matrix(transform)
	var/matrix/rotated_transform = transform.Turn(15 * turn_dir)

	animate(src, pixel_x = pixel_x + pixel_x_diff, pixel_y = pixel_y + pixel_y_diff, transform = rotated_transform, time = 2, easing = BACK_EASING | EASE_IN)
	animate(pixel_x = initial_pixel_x, pixel_y = initial_pixel_y, transform = initial_transform, time = 2, easing = SINE_EASING)

// either attack_item OR attack_image should be used. if both are used, attack_image will be the one chosen
/mob/do_attack_animation(atom/A, var/atom/attack_item, var/image/attack_image)
	var/initial_pixel_x = get_standard_pixel_x()
	var/initial_pixel_y = get_standard_pixel_y()
	..(A, attack_item, attack_image, initial_pixel_x, initial_pixel_y)

	if(is_floating)
		addtimer(CALLBACK(src, PROC_REF(start_floating)), 4)

	if(attack_item == FIST_ATTACK_ANIMATION) // only play the physical movement
		return
	// What icon do we use for the attack?
	var/image/I
	if(attack_image)
		I = attack_image
	else if(attack_item)
		I = image(attack_item.icon, A, attack_item.icon_state, A.layer + 1)
	else
		if(hand && l_hand) // Attacked with item in left hand.
			I = image(l_hand.icon, A, l_hand.icon_state, A.layer + 1)
		else if (!hand && r_hand) // Attacked with item in right hand.
			I = image(r_hand.icon, A, r_hand.icon_state, A.layer + 1)
		else // Attacked with a fist?
			return

	// Who can see the attack?
	var/list/viewing = list()
	for (var/mob/M in viewers(A))
		if (M.client)
			viewing |= M.client
	flick_overlay(I, viewing, 5) // 5 ticks/half a second

	// Scale the icon.
	I.transform *= 0.75
	// Set the direction of the icon animation.
	var/direction = get_dir(src, A)
	if(direction & NORTH)
		I.pixel_y = -16
	else if(direction & SOUTH)
		I.pixel_y = 16

	if(direction & EAST)
		I.pixel_x = -16
	else if(direction & WEST)
		I.pixel_x = 16

	if(!direction) // Attacked self?!
		I.pixel_z = 16

	var/matrix/M = new
	M.Turn(pick(-20, 20))
	// And animate the attack!
	animate(I, alpha = 175, pixel_x = initial_pixel_x, pixel_y = initial_pixel_y, pixel_z = 0, time = 2, easing = CUBIC_EASING)
	sleep(2)
	animate(I, transform = M, time = 1) // apply the fancy matrix
	sleep(1)
	animate(I, transform = matrix(), time = 1) // back to a default matrix
	sleep(1)
	animate(I, alpha = 0, time = 1)

/mob/proc/spin(spintime, speed)
	spawn()
		var/D = dir
		while(spintime >= speed)
			sleep(speed)
			switch(D)
				if(NORTH)
					D = EAST
				if(SOUTH)
					D = WEST
				if(EAST)
					D = SOUTH
				if(WEST)
					D = NORTH
			set_dir(D)
			spintime -= speed
	return

// Mob Throwing Animation
/mob/proc/animate_throw()
	var/ipx = pixel_x
	var/ipy = pixel_y
	var/mpx = 0
	var/mpy = 0

	if(dir & NORTH)
		mpy += 3
	else if(dir & SOUTH)
		mpy -= 3
	if(dir & EAST)
		mpx += 3
	else if(dir & WEST)
		mpx -= 3

	var/new_x = mpx + ipx
	var/new_y = mpy + ipy

	animate(src, pixel_x = new_x, pixel_y = new_y, time = 0.6, easing = EASE_OUT)

	var/matrix/M = matrix(transform)
	animate(transform = turn(transform, (mpx - mpy) * 4), time = 0.6, easing = EASE_OUT)
	animate(pixel_x = ipx, pixel_y = ipy, time = 0.6, easing = EASE_IN)
	animate(transform = M, time = 0.6, easing = EASE_IN)

	if(is_floating)
		addtimer(CALLBACK(src, PROC_REF(start_floating)), 2.4)
