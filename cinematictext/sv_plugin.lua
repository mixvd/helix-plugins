local PLUGIN = PLUGIN

util.AddNetworkString("openCinematicSplashMenu")
util.AddNetworkString("triggerCinematicSplashMenu")

net.Receive("triggerCinematicSplashMenu", function(_, client)
    if not client:IsAdmin() then return end

    net.Start("triggerCinematicSplashMenu")
        net.WriteString(net.ReadString()) -- text
        net.WriteString(net.ReadString()) --bigtext
        net.WriteUInt(net.ReadUInt(6), 6) --duration
        net.WriteBool(net.ReadBool()) -- blackBars
        net.WriteBool(net.ReadBool()) -- music
        net.WriteColor(net.ReadColor()) -- color
    net.Broadcast()
end)