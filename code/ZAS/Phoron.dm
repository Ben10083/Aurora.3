GLOBAL_DATUM_INIT(contamination_overlay, /image, image('icons/effects/contamination.dmi'))

/pl_control
	var/PHORON_DMG = 3
	var/PHORON_DMG_NAME = "Phoron Damage Amount"
	var/PHORON_DMG_DESC = "Self Descriptive"

	var/CLOTH_CONTAMINATION = TRUE
	var/CLOTH_CONTAMINATION_NAME = "Cloth Contamination"
	var/CLOTH_CONTAMINATION_DESC = "If this is on, phoron does damage by getting into cloth."

	var/PHORONGUARD_ONLY = FALSE
	var/PHORONGUARD_ONLY_NAME = "\"PhoronGuard Only\""
	var/PHORONGUARD_ONLY_DESC = "If this is on, only biosuits and spacesuits protect against contamination and ill effects."

	var/GENETIC_CORRUPTION = FALSE
	var/GENETIC_CORRUPTION_NAME = "Genetic Corruption Chance"
	var/GENETIC_CORRUPTION_DESC = "Chance of genetic corruption as well as toxic damage, X in 10,000."

	var/SKIN_BURNS = TRUE
	var/SKIN_BURNS_DESC = "Phoron has an effect similar to mustard gas on the un-suited."
	var/SKIN_BURNS_NAME = "Skin Burns"

	var/EYE_BURNS = TRUE
	var/EYE_BURNS_NAME = "Eye Burns"
	var/EYE_BURNS_DESC = "Phoron burns the eyes of anyone not wearing eye protection."

	var/CONTAMINATION_LOSS = 2
	var/CONTAMINATION_LOSS_NAME = "Contamination Loss"
	var/CONTAMINATION_LOSS_DESC = "How much fire damage is dealt from contaminated clothing, per life process."

	var/PHORON_HALLUCINATION = FALSE
	var/PHORON_HALLUCINATION_NAME = "Phoron Hallucination"
	var/PHORON_HALLUCINATION_DESC = "Does being in phoron cause you to hallucinate?"

	var/N2O_HALLUCINATION = TRUE
	var/N2O_HALLUCINATION_NAME = "N2O Hallucination"
	var/N2O_HALLUCINATION_DESC = "Does being in sleeping gas cause you to hallucinate?"


/obj/var/contaminated = 0

/obj/item/proc/can_contaminate()
	if(item_flags & ITEM_FLAG_PHORON_GUARD)
		return FALSE
	return TRUE

//Clothing can be contaminated.
/obj/item/storage/backpack/can_contaminate()
	return FALSE

/obj/item/proc/contaminate()
	//Do a contamination overlay? Temporary measure to keep contamination less deadly than it was.
	if(!contaminated)
		contaminated = 1
		AddOverlays(GLOB.contamination_overlay, ATOM_ICON_CACHE_PROTECTED)

/obj/item/proc/decontaminate()
	contaminated = 0
	CutOverlays(GLOB.contamination_overlay, ATOM_ICON_CACHE_PROTECTED)

/mob/proc/contaminate()

/mob/living/carbon/human/contaminate()
	//See if anything can be contaminated.

	if(!pl_suit_protected())
		suit_contamination()

	if(!pl_head_protected())
		if(prob(1)) suit_contamination() //Phoron can sometimes get through such an open suit.

/mob/proc/pl_effects()

/mob/living/carbon/human/pl_effects()
	//Handles all the bad things phoron can do.

	//Contamination
	if(GLOB.vsc.plc.CLOTH_CONTAMINATION) contaminate()

	//Anything else requires them to not be dead.
	if(stat >= DEAD)
		return

	if(species.flags & PHORON_IMMUNE)
		return

	//Burn skin if exposed.
	if(GLOB.vsc.plc.SKIN_BURNS)
		if(!pl_head_protected() || !pl_suit_protected())
			burn_skin(3)
			if(prob(20))
				to_chat(src, SPAN_DANGER("Your skin burns!"))
			updatehealth()

	//Burn eyes if exposed.
	if(GLOB.vsc.plc.EYE_BURNS)

		var/burn_eyes = 1

		//Check for protective glasses
		if(glasses && (glasses.body_parts_covered & EYES) && (glasses.item_flags & ITEM_FLAG_AIRTIGHT))
			burn_eyes = 0

		//Check for protective maskwear
		if(burn_eyes && wear_mask && (wear_mask.body_parts_covered & EYES) && (wear_mask.item_flags & ITEM_FLAG_AIRTIGHT))
			burn_eyes = 0

		//Check for protective helmets
		if(burn_eyes && head && (head.body_parts_covered & EYES) && (head.item_flags & ITEM_FLAG_AIRTIGHT))
			burn_eyes = 0

		//If we still need to, burn their eyes
		if(burn_eyes)
			burn_eyes()


	//Genetic Corruption
	if(GLOB.vsc.plc.GENETIC_CORRUPTION)
		if(rand(1,10000) < GLOB.vsc.plc.GENETIC_CORRUPTION)
			randmutb(src)
			to_chat(src, SPAN_DANGER("High levels of toxins cause you to spontaneously mutate!"))
			domutcheck(src,null)


/mob/living/carbon/human/proc/burn_eyes()
	//The proc that handles eye burning.
	if (!has_eyes() || species.eyes_are_impermeable)
		return

	var/obj/item/organ/internal/eyes/E = get_eyes(no_synthetic = TRUE)
	if(E)
		if(prob(20)) to_chat(src, SPAN_DANGER("Your eyes burn!"))
		E.damage += 2.5
		eye_blurry = min(eye_blurry+1.5,50)
		if (prob(max(0,E.damage - 15) + 1) &&!eye_blind)
			to_chat(src, SPAN_DANGER("You are blinded!"))
			eye_blind += 20

/mob/living/carbon/human/proc/pl_head_protected()
	//Checks if the head is adequately sealed.
	if(head)
		if(GLOB.vsc.plc.PHORONGUARD_ONLY)
			if(head.item_flags & ITEM_FLAG_PHORON_GUARD)
				return 1
		else if(head.body_parts_covered & EYES)
			return 1
	return 0

/mob/living/carbon/human/proc/pl_suit_protected()
	//Checks if the suit is adequately sealed.
	var/coverage = 0
	for(var/obj/item/protection in list(wear_suit, gloves, shoes))
		if(!protection)
			continue
		if(GLOB.vsc.plc.PHORONGUARD_ONLY && !(protection.item_flags & ITEM_FLAG_PHORON_GUARD))
			return 0
		coverage |= protection.body_parts_covered

	if(GLOB.vsc.plc.PHORONGUARD_ONLY)
		return 1

	return BIT_TEST_ALL(coverage, UPPER_TORSO|LOWER_TORSO|LEGS|FEET|ARMS|HANDS)

/mob/living/carbon/human/proc/suit_contamination()
	//Runs over the things that can be contaminated and does so.
	if(w_uniform) w_uniform.contaminate()
	if(shoes) shoes.contaminate()
	if(gloves) gloves.contaminate()
