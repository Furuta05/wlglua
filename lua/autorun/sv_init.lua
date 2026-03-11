if not SERVER then return end
local function initDatabase()
    if not sql.TableExists("whitelist_players") then
        sql.Query([[
            CREATE TABLE whitelist_players (
                steamid64 TEXT PRIMARY KEY,
                job_id INTEGER,
                last_seen INTEGER
            )
        ]])
    end
end
initDatabase()

util.AddNetworkString("openWlMenu")
util.AddNetworkString("wlSetJob")

local allowedGroups = {
    ["superadmin"] = true,
    ["admin"] = true,
    ["user"] = true
}

local function getPlayerJob(steamid64)
    local result = sql.Query("SELECT job_id FROM whitelist_players WHERE steamid64 = " .. sql.SQLStr(steamid64))
    if result and #result > 0 then
        return tonumber(result[1].job_id)
    end
    return nil
end

local function setPlayerJob(steamid64, ji)
    local curTime = os.time()
    sql.Query("REPLACE INTO whitelist_players (steamid64, job_id, last_seen) VALUES (" ..
        sql.SQLStr(steamid64) .. ", " .. ji .. ", " .. curTime .. ")")
end

hook.Add("PlayerInitialSpawn", "wlfix", function(ply)
    local sid64 = ply:SteamID64()
    local ji = getPlayerJob(sid64)

    if ji then
        timer.Simple(2, function()
            if IsValid(ply) then
                local jd = RPExtraTeams[ji]
                if jd then
                    ply:SetTeam(ji)
                    ply:setSelfDarkRPVar("job", jd.name)
                    sql.Query("UPDATE whitelist_players SET last_seen = " .. os.time() .. " WHERE steamid64 = " .. sql.SQLStr(sid64))
                end
            end
        end)
    end
end)

hook.Add("OnPlayerChangedTeam", "wlSave", function(ply, oldTeam, newTeam)
    if IsValid(ply) and newTeam > 0 then
        local sid64 = ply:SteamID64()
        local currentJob = getPlayerJob(sid64)
        if currentJob ~= newTeam and newTeam > 0 then
            setPlayerJob(sid64, newTeam)
        end
    end
end)

hook.Add("PlayerSay", "command", function(ply, text)
    if text == "/wl" or text == "/whitelist" then
        if allowedGroups[ply:GetUserGroup()] then
            net.Start("openWlMenu")
            net.Send(ply)
        else
            ply:ChatPrint("Подобная магия вам неподвластна")
        end
        return ""
    end
end)

net.Receive("wlSetJob", function(len, ply)
    if not allowedGroups[ply:GetUserGroup()] then return end
    local targetSID64 = net.ReadString()
    local ji = net.ReadInt(16)
    setPlayerJob(targetSID64, ji)
    local targetPly = player.GetBySteamID64(targetSID64)
    if IsValid(targetPly) then
        targetPly:changeTeam(ji, true)
    end
end)

timer.Create("wlCleanDataHUI", 86400, 0, function()
    local tridzatdney = os.time() - (30 * 24 * 60 * 60)
    sql.Query("DELETE FROM whitelist_players WHERE last_seen < " .. tridzatdney)
end)