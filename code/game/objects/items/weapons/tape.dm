/obj/item/tape_roll
	name = "tape roll"
	desc = "A roll of sticky tape. Possibly for taping ducks... or was that ducts?"
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "taperoll"
	w_class = ITEMSIZE_TINY
	drop_sound = 'sound/items/drop/cardboardbox.ogg'
	pickup_sound = 'sound/items/pickup/cardboardbox.ogg'
	surgerysound = /singleton/sound_category/rip_sound

/obj/item/tape_roll/attack(var/mob/living/carbon/human/H, var/mob/user, var/target_zone)
	if(istype(H))
		if(target_zone == BP_EYES)

			if(!H.organs_by_name[BP_HEAD])
				to_chat(user, SPAN_WARNING("\The [H] doesn't have a head."))
				return
			if(!H.has_eyes())
				to_chat(user, SPAN_WARNING("\The [H] doesn't have any eyes."))
				return
			if(H.glasses)
				to_chat(user, SPAN_WARNING("\The [H] is already wearing something on their eyes."))
				return
			if(H.head && (H.head.body_parts_covered & FACE))
				to_chat(user, SPAN_WARNING("Remove their [H.head] first."))
				return
			user.visible_message(SPAN_DANGER("\The [user] begins taping over \the [H]'s eyes!"))

			if(!do_after(user, 3 SECONDS, H, DO_UNIQUE))
				return

			// Repeat failure checks.
			if(!H || !src || !H.organs_by_name[BP_HEAD] || !H.has_eyes() || H.glasses || (H.head && (H.head.body_parts_covered & FACE)))
				return

			playsound(src, /singleton/sound_category/rip_sound, 25)
			user.visible_message(SPAN_DANGER("\The [user] has taped up \the [H]'s eyes!"))
			H.equip_to_slot_or_del(new /obj/item/clothing/glasses/sunglasses/blindfold/tape(H), slot_glasses)
			H.update_inv_glasses()

		else if(target_zone == BP_MOUTH || target_zone == BP_HEAD)
			if(!H.organs_by_name[BP_HEAD])
				to_chat(user, SPAN_WARNING("\The [H] doesn't have a head."))
				return
			if(!H.check_has_mouth())
				to_chat(user, SPAN_WARNING("\The [H] doesn't have a mouth."))
				return
			if(H.wear_mask)
				to_chat(user, SPAN_WARNING("\The [H] is already wearing a mask."))
				return
			if(H.head && (H.head.body_parts_covered & FACE))
				to_chat(user, SPAN_WARNING("Remove their [H.head] first."))
				return

			playsound(src, /singleton/sound_category/rip_sound, 25)
			user.visible_message(SPAN_DANGER("\The [user] begins taping up \the [H]'s mouth!"))

			if(!do_after(user, 3 SECONDS, H, DO_UNIQUE))
				return

			// Repeat failure checks.
			if(!H || !src || !H.organs_by_name[BP_HEAD] || !H.check_has_mouth() || H.wear_mask || (H.head && (H.head.body_parts_covered & FACE)))
				return

			playsound(src, /singleton/sound_category/rip_sound,25)
			user.visible_message(SPAN_DANGER("\The [user] has taped up \the [H]'s mouth!"))
			H.equip_to_slot_or_del(new /obj/item/clothing/mask/muzzle/tape(H), slot_wear_mask)
			H.update_inv_wear_mask()

		else if(target_zone == BP_R_HAND || target_zone == BP_L_HAND)
			playsound(src, /singleton/sound_category/rip_sound,25)
			var/obj/item/handcuffs/cable/tape/T = new(user)
			if(!T.place_handcuffs(H, user))
				user.unEquip(T)
				qdel(T)
				H.update_inv_handcuffed()
		else
			return ..()
		return 1

/obj/item/tape_roll/proc/stick(var/obj/item/W, mob/user)
	if(!istype(W, /obj/item/paper))
		return
	user.drop_from_inventory(W)
	//TODO: Possible animation? No clue
	var/obj/item/ducttape/tape = new(get_turf(src))
	tape.attach(W)
	user.put_in_hands(tape)

/obj/item/ducttape
	name = "tape"
	desc = "A piece of sticky tape."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "tape"
	w_class = ITEMSIZE_TINY
	layer = ABOVE_OBJ_LAYER
	anchored = 1 //it's sticky, no you cant move it
	drop_sound = null
	var/obj/item/stuck = null

/obj/item/ducttape/Initialize()
	. = ..()
	item_flags |= ITEM_FLAG_NO_BLUDGEON

/obj/item/ducttape/examine(mob/user)
	return stuck.examine(user)

/obj/item/ducttape/proc/attach(var/obj/item/W)
	stuck = W
	W.forceMove(src)
	icon_state = W.icon_state + "_taped"
	name = W.name + " (taped)"
	overlays = W.overlays

/obj/item/ducttape/attack_self(mob/user)
	if(!stuck)
		return

	to_chat(user, "You remove \the [initial(name)] from [stuck].")
	//TODO: Find out what the fuck is going on here
	user.drop_from_inventory(src)
	stuck.forceMove(get_turf(src))
	user.put_in_hands(stuck)
	stuck = null
	overlays = null
	qdel(src)

/obj/item/ducttape/afterattack(var/A, mob/user, flag, params)

	if(!in_range(user, A) || istype(A, /obj/machinery/door) || !stuck)
		return

	var/turf/target_turf = get_turf(A)
	var/turf/source_turf = get_turf(user)

	var/dir_offset = 0
	if(target_turf != source_turf)
		dir_offset = get_dir(source_turf, target_turf)
		if(!(dir_offset in GLOB.cardinal))
			to_chat(user, "You cannot reach that from here.")		// can only place stuck papers in GLOB.cardinal directions, to)
			return											// reduce papers around corners issue.

	user.drop_from_inventory(src,source_turf)
	playsound(src, /singleton/sound_category/rip_sound,25)

	if(params)
		var/list/mouse_control = mouse_safe_xy(params)
		if(mouse_control["icon-x"])
			pixel_x = mouse_control["icon-x"] - 16
			if(dir_offset & EAST)
				pixel_x += 32
			else if(dir_offset & WEST)
				pixel_x -= 32
		if(mouse_control["icon-y"])
			pixel_y = mouse_control["icon-y"] - 16
			if(dir_offset & NORTH)
				pixel_y += 32
			else if(dir_offset & SOUTH)
				pixel_y -= 32
