function sdlext.executeAddModContent()
	sdlext.addModContent(
		GetText("ModContent_Button_ModConfig"),
		ConfigureMods,
		GetText("ModContent_ButtonTooltip_ModConfig")
	)

	sdlext.addModContent(
		GetText("ModContent_Button_SquadSelect"),
		SelectSquads,
		GetText("ModContent_ButtonTooltip_SquadSelect")
	)

	arrangePilotsButton = sdlext.addModContent(
		GetText("ModContent_Button_PilotArrange"),
		ArrangePilots,
		GetText("ModContent_ButtonTooltip_PilotArrange")
	)

	sdlext.addModContent(
		GetText("ModContent_Button_IslandLayout"),
		ArrangeIslands,
		GetText("ModContent_ButtonTooltip_IslandLayout")
	)

	sdlext.addModContent(
		GetText("ModContent_Button_ConfigureWeaponDeck"),
		ConfigureWeaponDeck,
		GetText("ModContent_ButtonTooltip_ConfigureWeaponDeck")
	)

	sdlext.addModContent(
		GetText("ModContent_Button_ModLoaderConfig"),
		ConfigureModLoader,
		GetText("ModContent_ButtonTooltip_ModLoaderConfig")
	)
end
