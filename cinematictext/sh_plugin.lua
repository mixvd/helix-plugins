local PLUGIN = PLUGIN

PLUGIN.name = "Cinematic Splash Text"
PLUGIN.description = "Cinematic looking splash text for that extra flair."
PLUGIN.author = "76561198070441753 (TovarischPootis), ported to IX by mixed.dev"

ix.util.Include("sv_plugin.lua")

ix.config.Add("cinematicTextFont", "Arial", "The font used to display cinematic splash texts.", function()
	if (CLIENT) then
		hook.Run("LoadCinematicSplashTextFonts")
	end
end, {category = PLUGIN.name})

ix.config.Add("cinematicTextSize", 18, "The font size multiplier used by cinematic splash texts.", function()
	if (CLIENT) then
		hook.Run("LoadCinematicSplashTextFonts")
	end
end, {
    category = PLUGIN.name,
    data = {min = 10, max = 50},
    }
)

ix.config.Add("cinematicTextSizeBig", 30, "The big font size multiplier used by cinematic splash texts.", function()
	if (CLIENT) then
		hook.Run("LoadCinematicSplashTextFonts")
	end
end, {
    category = PLUGIN.name,
    data = {min = 10, max = 50},
    }
)

ix.config.Add("cinematicBarSize", 0.18, "How big the black bars are during cinematic.", nil, {
	category = PLUGIN.name,
    data = {min = 0.1, max = 0.2, decimals = 2}
})

ix.config.Add("cinematicTextMusic","music/stingers/industrial_suspense2.wav","The music played upon cinematic splash text appearance.",nil,
{category = PLUGIN.name})


ix.command.Add("CinematicMenu", {
	description = "Open a menu to setup the cinematic.",
	adminOnly = true,
	OnRun = function(self, client)
		net.Start("openCinematicSplashMenu")
        net.Send(client)
	end
})


if CLIENT then
    function PLUGIN:LoadCinematicSplashTextFonts()
        local font = ix.config.Get("cinematicTextFont", "Arial")
        local fontSizeBig = ix.config.Get("cinematicTextSizeBig", 30)
        local fontSizeNormal = ix.config.Get("cinematicTextSize", 18)
        surface.CreateFont("cinematicSplashFontBig", {
            font = font,
            size = ScreenScale(fontSizeBig),
            extended = true,
            weight = 1000
        })

        surface.CreateFont("cinematicSplashFont", {
            font = font,
            size = ScreenScale(fontSizeNormal),
            extended = true,
            weight = 800
        })

        surface.CreateFont("cinematicSplashFontSmall", {
            font = font,
            size = ScreenScale(10),
            extended = true,
            weight = 800
        })
    end

    function PLUGIN:LoadFonts()
        self:LoadCinematicSplashTextFonts() -- this will create the fonts upon initial load.
    end
end
