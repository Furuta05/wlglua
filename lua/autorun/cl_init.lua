if not CLIENT then return end

surface.CreateFont("WL_Title", {font = "Trebuchet24", size = 26, weight = 800, extended = true})
surface.CreateFont("WL_Main", {font = "Trebuchet24", size = 18, weight = 500, extended = true})
surface.CreateFont("WL_PlayerName", {font = "Trebuchet24", size = 16, weight = 700, extended = true})
surface.CreateFont("WL_SteamID", {font = "Trebuchet24", size = 12, weight = 400, extended = true})
surface.CreateFont("WL_Small", {font = "Trebuchet24", size = 14, weight = 400, extended = true})

local function SmoothLerp(a, b, t)
    return Lerp(FrameTime() * t, a, b)
end

net.Receive("openWlMenu", function()
    local selectedJob = nil
    local selectedPlayerID = nil

    local frame = vgui.Create("DFrame")
    frame:SetSize(850, 550)
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.15)
    frame:ShowCloseButton(false)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(12, 0, 0, w, h, Color(15, 15, 15, 250))
        draw.SimpleText("ВЫДАТЬ ПРОФУ", "WL_Title", 25, 25, Color(255, 255, 255, 220))
        draw.RoundedBox(2, 25, 55, 40, 3, Color(70, 130, 210))
    end

    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(30, 30)
    closeBtn:SetPos(frame:GetWide() - 45, 20)
    closeBtn:SetText("×")
    closeBtn:SetFont("WL_Title")
    closeBtn:SetTextColor(Color(100, 100, 100))
    closeBtn.Paint = nil
    closeBtn.DoClick = function()
        frame:AlphaTo(0, 0.1, 0, function() frame:Close() end)
    end

    local leftScroll = vgui.Create("DScrollPanel", frame)
    leftScroll:SetPos(25, 80)
    leftScroll:SetSize(400, 445)

    local jobLayout = vgui.Create("DIconLayout", leftScroll)
    jobLayout:Dock(FILL)
    jobLayout:SetSpaceX(10)
    jobLayout:SetSpaceY(10)

    for jobId, jobData in pairs(RPExtraTeams) do
        local jobBtn = jobLayout:Add("DButton")
        jobBtn:SetSize(123, 150)
        jobBtn:SetText("")
        jobBtn.hoverState = 0

        jobBtn.Paint = function(self, w, h)
            local isSelected = (selectedJob == jobId)
            self.hoverState = SmoothLerp(self.hoverState, (self:IsHovered() or isSelected) and 1 or 0, 12)
            
            draw.RoundedBox(10, 0, 0, w, h, Color(25, 25, 25))
            if self.hoverState > 0.01 then
                draw.RoundedBox(10, 0, 0, w, h, Color(70, 130, 210, 30 * self.hoverState))
                surface.SetDrawColor(70, 130, 210, 120 * self.hoverState)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end

            draw.DrawText(jobData.name or "Unknown", "WL_Small", w / 2, h - 35, isSelected and color_white or Color(150, 150, 150), TEXT_ALIGN_CENTER)
        end
        jobBtn.DoClick = function()
            surface.PlaySound("ui/buttonclick.wav")
            selectedJob = jobId
        end

        local img = vgui.Create("ModelImage", jobBtn)
        img:SetSize(80, 80)
        img:SetPos(21, 15)
        local mdl = isstring(jobData.model) and jobData.model or (istable(jobData.model) and jobData.model[1] or "models/error.mdl")
        img:SetModel(mdl)
    end

    local rightPanel = vgui.Create("DPanel", frame)
    rightPanel:SetPos(450, 80)
    rightPanel:SetSize(375, 445)
    rightPanel.Paint = nil

    local searchBar = vgui.Create("DTextEntry", rightPanel)
    searchBar:Dock(TOP)
    searchBar:SetTall(40)
    searchBar:SetFont("WL_Main")
    searchBar:SetPlaceholderText("Поиск игрока...")
    searchBar:SetPlaceholderColor(Color(80, 80, 80))
    searchBar.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(25, 25, 25))
        self:DrawTextEntryText(color_white, Color(70, 130, 210), color_white)
    end

    local pScroll = vgui.Create("DScrollPanel", rightPanel)
    pScroll:Dock(FILL)
    pScroll:DockMargin(0, 10, 0, 10)
    
    local sbar = pScroll:GetVBar()
    sbar:SetWide(4)
    sbar.Paint = nil
    sbar.btnUp.Paint, sbar.btnDown.Paint = nil, nil
    sbar.btnGrip.Paint = function(s, w, h) draw.RoundedBox(2, 0, 0, w, h, Color(50, 50, 50)) end

    local function RefreshList(filter)
        pScroll:Clear()
        local filterLower = filter and filter:lower() or ""

        for _, ply in ipairs(player.GetAll()) do
            local nick = ply:Nick()
            local sid64 = ply:SteamID64() or "0"

            if filterLower ~= "" and not string.find(nick:lower(), filterLower) and not string.find(sid64, filterLower) then 
                continue 
            end

            local pCard = pScroll:Add("DButton")
            pCard:Dock(TOP)
            pCard:SetTall(50)
            pCard:DockMargin(0, 0, 5, 5)
            pCard:SetText("")
            pCard.hover = 0

            pCard.Paint = function(self, w, h)
                local isSelected = (selectedPlayerID == sid64)
                self.hover = SmoothLerp(self.hover, (self:IsHovered() or isSelected) and 1 or 0, 15)
                draw.RoundedBox(8, 0, 0, w, h, Color(25, 25, 25))
                if self.hover > 0.01 then
                    draw.RoundedBox(8, 0, 0, w, h, Color(70, 130, 210, 40 * self.hover))
                    surface.SetDrawColor(70, 130, 210, 100 * self.hover)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                end

                draw.SimpleText(nick, "WL_PlayerName", 60, 10, isSelected and color_white or Color(230, 230, 230))
                draw.SimpleText(sid64, "WL_SteamID", 60, h - 18, Color(100, 100, 100))
            end

            pCard.DoClick = function()
                surface.PlaySound("ui/buttonclick.wav")
                selectedPlayerID = sid64
            end

            local av = vgui.Create("AvatarImage", pCard)
            av:SetSize(36, 36)
            av:SetPos(12, 7)
            av:SetPlayer(ply, 64)
            av:SetMouseInputEnabled(true)
        end
    end

    RefreshList()
    searchBar.OnChange = function(self) RefreshList(self:GetValue()) end

    local applyBtn = vgui.Create("DButton", rightPanel)
    applyBtn:Dock(BOTTOM)
    applyBtn:SetTall(45)
    applyBtn:SetText("готово")
    applyBtn:SetFont("WL_Main")
    applyBtn:SetTextColor(color_white)
    applyBtn.hover = 0
    applyBtn.Paint = function(self, w, h)
        self.hover = SmoothLerp(self.hover, self:IsHovered() and 1 or 0, 10)
        draw.RoundedBox(8, 0, 0, w, h, Color(70, 130, 210, 200 + (self.hover * 55)))
        surface.SetDrawColor(255, 255, 255, 10 * self.hover)
        surface.DrawRect(0, 0, w, h / 2)
    end

    applyBtn.DoClick = function()
        if not selectedJob or not selectedPlayerID then
            surface.PlaySound("buttons/lightswitch2.wav")
            return
        end
        net.Start("wlSetJob")
            net.WriteString(selectedPlayerID)
            net.WriteInt(selectedJob, 16)
        net.SendToServer()
        frame:AlphaTo(0, 0.1, 0, function() frame:Close() end)
    end
end)