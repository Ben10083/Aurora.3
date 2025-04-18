/* Windoor (window door) assembly -Nodrak
 * Step 1: Create a windoor out of rglass
 * Step 2: Add r-glass to the assembly to make a secure windoor (Optional)
 * Step 3: Rotate or Flip the assembly to face and open the way you want
 * Step 4: Wrench the assembly in place
 * Step 5: Add cables to the assembly
 * Step 6: Set access for the door.
 * Step 7: Screwdriver the door to complete
 */


/obj/structure/windoor_assembly
	name = "windoor assembly"
	icon = 'icons/obj/doors/windoor.dmi'
	icon_state = "l_windoor_assembly01"
	obj_flags = OBJ_FLAG_ROTATABLE
	anchored = 0
	density = 0
	dir = NORTH
	w_class = WEIGHT_CLASS_NORMAL
	atom_flags = ATOM_FLAG_CHECKS_BORDER

	var/obj/item/airlock_electronics/electronics = null

	//Vars to help with the icon's name
	var/facing = "l"	//Does the windoor open to the left or right?
	var/secure = ""		//Whether or not this creates a secure windoor
	var/state = "01"	//How far the door assembly has progressed in terms of sprites

/obj/structure/windoor_assembly/New(Loc, start_dir=NORTH, constructed=0)
	..()
	if(constructed)
		state = "01"
		anchored = 0
	switch(start_dir)
		if(NORTH, SOUTH, EAST, WEST)
			set_dir(start_dir)
		else //If the user is facing northeast. northwest, southeast, southwest or north, default to north
			set_dir(NORTH)

	update_nearby_tiles(need_rebuild=1)

/obj/structure/windoor_assembly/Destroy()
	density = 0
	update_nearby_tiles()
	return ..()

/obj/structure/windoor_assembly/update_icon()
	icon_state = "[facing]_[secure]windoor_assembly[state]"

/obj/structure/windoor_assembly/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(mover?.movement_type & PHASING)
		return TRUE
	if(istype(mover) && mover.pass_flags & PASSGLASS)
		return 1
	if(get_dir(loc, target) == dir) //Make sure looking at appropriate border
		if(air_group) return 0
		return !density
	else
		return 1

/obj/structure/windoor_assembly/CheckExit(atom/movable/mover as mob|obj, turf/target as turf)
	if(istype(mover) && mover.pass_flags & PASSGLASS)
		return 1
	if(get_dir(loc, target) == dir)
		return !density
	else
		return 1


/obj/structure/windoor_assembly/attackby(obj/item/attacking_item, mob/user)
	//I really should have spread this out across more states but thin little windoors are hard to sprite.
	switch(state)
		if("01")
			if(attacking_item.iswelder() && !anchored)
				var/obj/item/weldingtool/WT = attacking_item
				if (WT.use(0,user))
					user.visible_message("[user] dissassembles the windoor assembly.", "You start to dissassemble the windoor assembly.")
					playsound(src.loc, 'sound/items/welder_pry.ogg', 50, 1)

					if(attacking_item.use_tool(src, user, 40, volume = 50))
						if(!src || !WT.isOn()) return
						to_chat(user, SPAN_NOTICE("You dissasembled the windoor assembly!"))
						new /obj/item/stack/material/glass/reinforced(get_turf(src), 5)
						if(secure)
							new /obj/item/stack/rods(get_turf(src), 4)
						qdel(src)
				else
					to_chat(user, SPAN_NOTICE("You need more welding fuel to dissassemble the windoor assembly."))
					return

			//Wrenching an unsecure assembly anchors it in place. Step 4 complete
			if(attacking_item.iswrench() && !anchored)
				user.visible_message("[user] secures the windoor assembly to the floor.", "You start to secure the windoor assembly to the floor.")

				if(attacking_item.use_tool(src, user, 40, volume = 50))
					if(!src) return
					to_chat(user, SPAN_NOTICE("You've secured the windoor assembly!"))
					src.anchored = 1
					if(src.secure)
						src.name = "Secure Anchored Windoor Assembly"
					else
						src.name = "Anchored Windoor Assembly"

			//Unwrenching an unsecure assembly un-anchors it. Step 4 undone
			else if(attacking_item.iswrench() && anchored)
				user.visible_message("[user] unsecures the windoor assembly to the floor.", "You start to unsecure the windoor assembly to the floor.")

				if(attacking_item.use_tool(src, user, 40, volume = 50))
					if(!src) return
					to_chat(user, SPAN_NOTICE("You've unsecured the windoor assembly!"))
					src.anchored = 0
					if(src.secure)
						src.name = "Secure Windoor Assembly"
					else
						src.name = "Windoor Assembly"

			//Adding plasteel makes the assembly a secure windoor assembly. Step 2 (optional) complete.
			else if(istype(attacking_item, /obj/item/stack/rods) && !secure)
				var/obj/item/stack/rods/R = attacking_item
				if(R.get_amount() < 4)
					to_chat(user, SPAN_WARNING("You need more rods to do this."))
					return
				to_chat(user, SPAN_NOTICE("You start to reinforce the windoor with rods."))

				if(attacking_item.use_tool(src, user, 40, volume = 50) && !secure)
					if (R.use(4))
						to_chat(user, SPAN_NOTICE("You reinforce the windoor."))
						src.secure = "secure_"
						if(src.anchored)
							src.name = "Secure Anchored Windoor Assembly"
						else
							src.name = "Secure Windoor Assembly"

			//Adding cable to the assembly. Step 5 complete.
			else if(attacking_item.iscoil() && anchored)
				user.visible_message("[user] wires the windoor assembly.", "You start to wire the windoor assembly.")

				var/obj/item/stack/cable_coil/CC = attacking_item
				if(attacking_item.use_tool(src, user, 40, volume = 50))
					if (CC.use(1))
						to_chat(user, SPAN_NOTICE("You wire the windoor!"))
						src.state = "02"
						if(src.secure)
							src.name = "Secure Wired Windoor Assembly"
						else
							src.name = "Wired Windoor Assembly"
			else
				..()

		if("02")

			//Removing wire from the assembly. Step 5 undone.
			if(attacking_item.iswirecutter() && !src.electronics)
				playsound(src.loc, 'sound/items/Wirecutter.ogg', 100, 1)
				user.visible_message("[user] cuts the wires from the airlock assembly.", "You start to cut the wires from airlock assembly.")

				if(attacking_item.use_tool(src, user, 40, volume = 50))
					if(!src) return

					to_chat(user, SPAN_NOTICE("You cut the windoor wires.!"))
					new/obj/item/stack/cable_coil(get_turf(user), 1)
					src.state = "01"
					if(src.secure)
						src.name = "Secure Anchored Windoor Assembly"
					else
						src.name = "Anchored Windoor Assembly"

			//Adding airlock electronics for access. Step 6 complete.
			else if(istype(attacking_item, /obj/item/airlock_electronics) && attacking_item.icon_state != "door_electronics_smoked")
				var/obj/item/airlock_electronics/EL = attacking_item
				if(!EL.is_installed)
					playsound(src.loc, 'sound/items/Screwdriver.ogg', 100, 1)
					user.visible_message("[user] installs the electronics into the airlock assembly.", "You start to install electronics into the airlock assembly.")
					EL.is_installed = 1
					if(do_after(user, 40))
						EL.is_installed = 0
						if(!src) return
						user.drop_from_inventory(EL,src)
						to_chat(user, SPAN_NOTICE("You've installed the airlock electronics!"))
						src.name = "Near finished Windoor Assembly"
						src.electronics = EL
					else
						EL.is_installed = 0

			//Screwdriver to remove airlock electronics. Step 6 undone.
			else if(attacking_item.isscrewdriver() && src.electronics)
				user.visible_message("[user] removes the electronics from the airlock assembly.", "You start to uninstall electronics from the airlock assembly.")

				if(attacking_item.use_tool(src, user, 40, volume = 50))
					if(!src || !src.electronics) return
					to_chat(user, SPAN_NOTICE("You've removed the airlock electronics!"))
					if(src.secure)
						src.name = "Secure Wired Windoor Assembly"
					else
						src.name = "Wired Windoor Assembly"
					var/obj/item/airlock_electronics/ae = electronics
					electronics = null
					ae.forceMove(src.loc)

			//Crowbar to complete the assembly, Step 7 complete.
			else if(attacking_item.iscrowbar())
				if(!src.electronics)
					to_chat(usr, SPAN_WARNING("The assembly is missing electronics."))
					return
				usr << browse(null, "window=windoor_access")
				user.visible_message("[user] pries the windoor into the frame.", "You start prying the windoor into the frame.")

				if(attacking_item.use_tool(src, user, 40, volume = 50))

					if(!src) return

					density = 1 //Shouldn't matter but just incase
					to_chat(user, SPAN_NOTICE("You finish the windoor!"))

					if(secure)
						var/obj/machinery/door/window/brigdoor/windoor = new /obj/machinery/door/window/brigdoor(src.loc)
						if(src.facing == "l")
							windoor.icon_state = "leftsecureopen"
							windoor.base_state = "leftsecure"
						else
							windoor.icon_state = "rightsecureopen"
							windoor.base_state = "rightsecure"
						windoor.set_dir(src.dir)
						windoor.density = 0

						if(src.electronics.one_access)
							windoor.req_access = null
							windoor.req_one_access = src.electronics.conf_access
						else
							windoor.req_access = src.electronics.conf_access
						windoor.electronics = src.electronics
						src.electronics.forceMove(windoor)
					else
						var/obj/machinery/door/window/windoor = new /obj/machinery/door/window(src.loc)
						if(src.facing == "l")
							windoor.icon_state = "leftopen"
							windoor.base_state = "left"
						else
							windoor.icon_state = "rightopen"
							windoor.base_state = "right"
						windoor.set_dir(src.dir)
						windoor.density = 0

						if(src.electronics.one_access)
							windoor.req_access = null
							windoor.req_one_access = src.electronics.conf_access
						else
							windoor.req_access = src.electronics.conf_access
						windoor.electronics = src.electronics
						src.electronics.forceMove(windoor)


					qdel(src)


			else
				..()

	//Update to reflect changes(if applicable)
	update_icon()

/obj/structure/windoor_assembly/rotate(var/mob/user)
	if(use_check_and_message(user))
		return

	if(anchored)
		to_chat(user, SPAN_WARNING("\The [src] is bolted to the floor!"))
		return FALSE

	var/targetdir = turn(dir, 270)
	for(var/obj/obstacle in get_turf(src))
		if (obstacle == src)
			continue

		if((obstacle.atom_flags & ATOM_FLAG_CHECKS_BORDER) && obstacle.dir == targetdir)
			to_chat(usr, SPAN_WARNING("You can't turn the windoor assembly that way, there's already something there!"))
			return

	if(src.state != "01")
		update_nearby_tiles(need_rebuild=1) //Compel updates before

	set_dir(targetdir)

	if(src.state != "01")
		update_nearby_tiles(need_rebuild=1)

	update_icon()
	return

//Flips the windoor assembly, determines whather the door opens to the left or the right
/obj/structure/windoor_assembly/verb/flip()
	set name = "Flip Windoor Assembly"
	set category = "Object"
	set src in oview(1)

	if(src.facing == "l")
		to_chat(usr, "The windoor will now slide to the right.")
		src.facing = "r"
	else
		src.facing = "l"
		to_chat(usr, "The windoor will now slide to the left.")

	update_icon()
	return
