#define FONT_SIZE "5pt"
#define FONT_COLOR "#09f"
#define FONT_STYLE "Arial Black"
#define SCROLL_SPEED 2

// Status display
// (formerly Countdown timer display)

// Use to show shuttle ETA/ETD times
// Alert status
// And arbitrary messages set by comms computer
/obj/machinery/status_display
	name = "status display"
	icon = 'icons/obj/status_display.dmi'
	icon_state = "frame"
	layer = ABOVE_WINDOW_LAYER
	anchored = 1
	density = 0
	idle_power_usage = 10
	obj_flags = OBJ_FLAG_MOVES_UNSUPPORTED
	var/hears_arrivals = FALSE
	var/mode = 1	// 0 = Blank
					// 1 = Shuttle timer
					// 2 = Arbitrary message(s)
					// 3 = alert picture
					// 4 = Supply shuttle timer

	var/picture_state	// icon_state of alert picture
	var/message1 = ""	// message line 1
	var/message2 = ""	// message line 2
	var/index1			// display index for scrolling messages or 0 if non-scrolling
	var/index2

	var/frequency = 1435		// radio frequency

	var/friendc = 0      // track if Friend Computer mode
	var/ignore_friendc = 0

	maptext_height = 26
	maptext_width = 32

	var/const/CHARS_PER_LINE = 5
	var/const/STATUS_DISPLAY_BLANK = 0
	var/const/STATUS_DISPLAY_TRANSFER_SHUTTLE_TIME = 1
	var/const/STATUS_DISPLAY_MESSAGE = 2
	var/const/STATUS_DISPLAY_ALERT = 3
	var/const/STATUS_DISPLAY_TIME = 4
	var/const/STATUS_DISPLAY_CUSTOM = 99

/obj/machinery/status_display/Destroy()
	SSmachinery.all_status_displays -= src
	SSradio.remove_object(src,frequency)
	return ..()

// register for radio system
/obj/machinery/status_display/Initialize()
	. = ..()
	SSmachinery.all_status_displays += src
	if (hears_arrivals)
		SSradio.add_object(src, frequency, RADIO_ARRIVALS)
	else
		SSradio.add_object(src, frequency)

// timed process
/obj/machinery/status_display/process()
	if(stat & NOPOWER)
		remove_display()
		return
	update()

/obj/machinery/status_display/emp_act(severity)
	. = ..()

	if(stat & (BROKEN|NOPOWER))
		return

	set_picture("ai_bsod")

// set what is displayed
/obj/machinery/status_display/proc/update()
	remove_display()
	if(friendc && !ignore_friendc)
		set_picture("ai_friend")
		return 1

	switch(mode)
		if(STATUS_DISPLAY_BLANK)	//blank
			return 1
		if(STATUS_DISPLAY_TRANSFER_SHUTTLE_TIME)				//emergency shuttle timer
			if(evacuation_controller)
				if(evacuation_controller.is_prepared())
					message1 = "-ETD-"
					if (evacuation_controller.waiting_to_leave())
						message2 = "Launch"
					else
						message2 = get_shuttle_timer()
						if(length(message2) > CHARS_PER_LINE)
							message2 = "Error"
					update_display(message1, message2)
					AddOverlays(emissive_appearance(icon, "outline", src, alpha = src.alpha))
				else if(evacuation_controller.has_eta())
					message1 = "-ETA-"
					message2 = get_shuttle_timer()
					if(length(message2) > CHARS_PER_LINE)
						message2 = "Error"
					update_display(message1, message2)
					AddOverlays(emissive_appearance(icon, "outline", src, alpha = src.alpha))
				return 1
		if(STATUS_DISPLAY_MESSAGE)	//custom messages
			var/line1
			var/line2

			if(!index1)
				line1 = message1
			else
				line1 = copytext(message1+"|"+message1, index1, index1+CHARS_PER_LINE)
				var/message1_len = length(message1)
				index1 += SCROLL_SPEED
				if(index1 > message1_len)
					index1 -= message1_len

			if(!index2)
				line2 = message2
			else
				line2 = copytext(message2+"|"+message2, index2, index2+CHARS_PER_LINE)
				var/message2_len = length(message2)
				index2 += SCROLL_SPEED
				if(index2 > message2_len)
					index2 -= message2_len
			update_display(line1, line2)
			AddOverlays(emissive_appearance(icon, "outline", src, alpha = src.alpha))
			return 1
		if(STATUS_DISPLAY_ALERT)
			set_picture(picture_state)
			AddOverlays(emissive_appearance(icon, "outline", src, alpha = src.alpha))
			return 1
		if(STATUS_DISPLAY_TIME)
			message1 = "TIME"
			message2 = worldtime2text()
			AddOverlays(emissive_appearance(icon, "outline", src, alpha = src.alpha))
			update_display(message1, message2)
			return 1
	return 0

/obj/machinery/status_display/get_examine_text(mob/user, distance, is_adjacent, infix, suffix)
	. = ..()
	if(mode != STATUS_DISPLAY_BLANK && mode != STATUS_DISPLAY_ALERT)
		. += "The display says:<br>\t[sanitize(message1)]<br>\t[sanitize(message2)]"

/obj/machinery/status_display/proc/set_message(m1, m2)
	if(m1)
		index1 = (length(m1) > CHARS_PER_LINE)
		message1 = m1
	else
		message1 = ""
		index1 = 0

	if(m2)
		index2 = (length(m2) > CHARS_PER_LINE)
		message2 = m2
	else
		message2 = ""
		index2 = 0

/obj/machinery/status_display/proc/set_picture(state)
	remove_display()
	picture_state = state
	AddOverlays(picture_state)

/obj/machinery/status_display/proc/update_display(line1, line2)
	var/new_text = {"<div style="font-size:[FONT_SIZE];color:[FONT_COLOR];font:'[FONT_STYLE]';text-align:center;" valign="top">[line1]<br>[line2]</div>"}
	if(maptext != new_text)
		maptext = new_text

/obj/machinery/status_display/proc/get_shuttle_timer()
	var/timeleft = evacuation_controller.get_eta()
	if(timeleft < 0)
		return ""
	return "[add_zero(num2text((timeleft / 60) % 60),2)]:[add_zero(num2text(timeleft % 60), 2)]"

/obj/machinery/status_display/proc/get_supply_shuttle_timer()
	var/datum/shuttle/autodock/ferry/supply/shuttle = SScargo.shuttle
	if (!shuttle)
		return "Error"

	if(shuttle.has_arrive_time())
		var/timeleft = round((shuttle.arrive_time - world.time) / 10,1)
		if(timeleft < 0)
			return "Late"
		return "[add_zero(num2text((timeleft / 60) % 60),2)]:[add_zero(num2text(timeleft % 60), 2)]"
	return ""

/obj/machinery/status_display/proc/get_arrivals_shuttle_timer()
	var/datum/shuttle/autodock/ferry/arrival/shuttle = SSarrivals.shuttle
	if (!shuttle)
		return "Error"

	if(shuttle.has_arrive_time())
		var/timeleft = round((shuttle.arrive_time - world.time) / 10,1)
		if(timeleft < 0)
			return ""
		return "[add_zero(num2text((timeleft / 60) % 60),2)]:[add_zero(num2text(timeleft % 60), 2)]"
	return ""

/obj/machinery/status_display/proc/get_arrivals_shuttle_timer2()
	if (!SSarrivals)
		return "Error"

	if(SSarrivals.launch_time)
		var/timeleft = round((SSarrivals.launch_time - world.time) / 10,1)
		if(timeleft < 0)
			return ""
		return "[add_zero(num2text((timeleft / 60) % 60),2)]:[add_zero(num2text(timeleft % 60), 2)]"
	else
		return "Launch"

/obj/machinery/status_display/proc/remove_display()
	ClearOverlays()
	if(maptext)
		maptext = ""

/obj/machinery/status_display/receive_signal(datum/signal/signal)
	switch(signal.data["command"])
		if("blank")
			mode = STATUS_DISPLAY_BLANK

		if("shuttle")
			mode = STATUS_DISPLAY_TRANSFER_SHUTTLE_TIME

		if("message")
			mode = STATUS_DISPLAY_MESSAGE
			set_message(signal.data["msg1"], signal.data["msg2"])

		if("alert")
			mode = STATUS_DISPLAY_ALERT
			set_picture(signal.data["picture_state"])

		if("time")
			mode = STATUS_DISPLAY_TIME
	update()

#undef FONT_SIZE
#undef FONT_COLOR
#undef FONT_STYLE
#undef SCROLL_SPEED
