local PLUGIN = PLUGIN

PLUGIN.name = "Personal Safe"
PLUGIN.author = "Mixed"
PLUGIN.desc = "Add a items to set the name and the password of a containers on the map to get a personal safe. (Can works on all containers of the map)."


ix.container.Register("models/Items/ammoCrate_Rockets.mdl", {
	name = "Personal Safe",
	description = "A personal safe.",
	width = 6,
	height = 4,
})