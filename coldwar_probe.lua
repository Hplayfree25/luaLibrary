--[[
    coldwar_probe.lua — Madium-safe API / path tester
    ==================================================
    Purpose: test what coldwar_old needs, WITHOUT force-closing Roblox.

    Rules (strict):
      - NO getgc(true) unless you click the button (and even then: yielded, abortable)
      - NO hookfunction on game/string/global until you click a micro-test
      - NO auto combat hooks
      - Every dangerous step is opt-in via UI button
      - Base load only: type checks + safe require pcalls + print report

    How to use:
      1) Execute in Cold War (in-game, after spawn if possible)
      2) LeftAlt opens UI (or read F9 console)
      3) Click tests one-by-one. If a click freezes/closes → that API is the culprit.
--]]

local RESULTS = {} -- { name = string, ok = bool, detail = string, risk = "safe"|"medium"|"danger" }
local aborted = false
local scriptId = "CW_PROBE_UI"

local function log(name, ok, detail, risk)
    risk = risk or "safe"
    local row = { name = name, ok = ok, detail = tostring(detail or ""), risk = risk }
    table.insert(RESULTS, row)
    local tag = ok and "OK" or "FAIL"
    print(string.format("[CW_PROBE][%s][%s] %s — %s", tag, risk, name, row.detail))
    return row
end

local function exists(fn)
    return type(fn) == "function"
end

-- ── 0) identity (safe) ─────────────────────────────────────────────────────
local executorName = "unknown"
pcall(function()
    local id = identifyexecutor or getexecutorname
    if type(id) == "function" then
        executorName = tostring(id())
    end
end)
log("executor", true, executorName, "safe")

-- ── 1) SAFE type checks only (never CALL dangerous APIs yet) ───────────────
local API = {
    getgc              = rawget(_G, "getgc") or getgc,
    hookfunction       = rawget(_G, "hookfunction") or hookfunction,
    hookmetamethod     = rawget(_G, "hookmetamethod") or hookmetamethod,
    newcclosure        = rawget(_G, "newcclosure") or newcclosure,
    checkcaller        = rawget(_G, "checkcaller") or checkcaller,
    getnamecallmethod  = rawget(_G, "getnamecallmethod") or getnamecallmethod,
    islclosure         = rawget(_G, "islclosure") or islclosure,
    iscclosure         = rawget(_G, "iscclosure") or iscclosure,
    cloneref           = rawget(_G, "cloneref") or cloneref,
    gethui             = rawget(_G, "gethui") or gethui,
    getgenv            = rawget(_G, "getgenv") or getgenv,
    getrenv            = rawget(_G, "getrenv") or getrenv,
    getfenv            = rawget(_G, "getfenv") or getfenv,
    setfenv            = rawget(_G, "setfenv") or setfenv,
    getscriptclosure   = rawget(_G, "getscriptclosure") or getscriptclosure,
    getproto           = rawget(_G, "getproto") or getproto,
    getprotos          = rawget(_G, "getprotos") or getprotos,
    Drawing            = rawget(_G, "Drawing") or Drawing,
    writefile          = rawget(_G, "writefile") or writefile,
    readfile           = rawget(_G, "readfile") or readfile,
    isfile             = rawget(_G, "isfile") or isfile,
    request            = (syn and syn.request) or (http and http.request) or rawget(_G, "request") or request,
}

-- Madium: CALLING newcclosure hard-crashes (pcall does NOT catch it).
-- Never invoke native newcclosure. Always identity. Presence is logged only.
local newcclosureMode = "identity-forced"
local _nativeNewc = API.newcclosure
API.newcclosure = function(f) return f end -- never call _nativeNewc
if type(_nativeNewc) == "function" then
    newcclosureMode = "present-but-SKIPPED (crashy)"
else
    newcclosureMode = "missing→identity"
end

-- debug lib (sometimes under debug, sometimes globals)
local dbg = rawget(_G, "debug") or debug
API.debug_getinfo      = (dbg and dbg.getinfo) or rawget(_G, "getinfo") or getinfo
API.debug_getupvalue   = (dbg and dbg.getupvalue) or rawget(_G, "getupvalue") or getupvalue
API.debug_setupvalue   = (dbg and dbg.setupvalue) or rawget(_G, "setupvalue") or setupvalue
API.debug_getupvalues  = (dbg and dbg.getupvalues) or rawget(_G, "getupvalues") or getupvalues
API.debug_getconstants = (dbg and dbg.getconstants) or rawget(_G, "getconstants") or getconstants
API.debug_getconstant  = (dbg and dbg.getconstant) or rawget(_G, "getconstant") or getconstant
API.debug_setconstant  = (dbg and dbg.setconstant) or rawget(_G, "setconstant") or setconstant

local function typeCheck(name, v)
    local t = type(v)
    local ok = (t == "function") or (t == "table" and name == "Drawing")
    log("type:" .. name, ok, ok and t or ("missing (" .. t .. ")"), "safe")
    return ok
end

print("[CW_PROBE] === SAFE TYPE CHECKS (no calls) ===")
typeCheck("getgc", API.getgc)
typeCheck("hookfunction", API.hookfunction)
typeCheck("hookmetamethod", API.hookmetamethod)
-- Do NOT typeCheck native newcclosure as "callable" — we force identity.
log("fix:newcclosure", true, newcclosureMode, "safe")
log("type:newcclosure(wrapper)", true, "function identity", "safe")
typeCheck("islclosure", API.islclosure)
typeCheck("iscclosure", API.iscclosure)
typeCheck("debug.getinfo", API.debug_getinfo)
typeCheck("debug.getupvalue", API.debug_getupvalue)
typeCheck("debug.setupvalue", API.debug_setupvalue)
typeCheck("debug.getupvalues", API.debug_getupvalues)
typeCheck("debug.getconstants", API.debug_getconstants)
typeCheck("cloneref", API.cloneref)
typeCheck("gethui", API.gethui)
typeCheck("Drawing", API.Drawing)
typeCheck("request", API.request)

-- ── 2) SAFE Roblox services ────────────────────────────────────────────────
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

log("service:ReplicatedStorage", RS ~= nil, RS and RS:GetFullName() or "nil", "safe")
log("service:LocalPlayer", LocalPlayer ~= nil, LocalPlayer and LocalPlayer.Name or "nil", "safe")

-- ── 3) SAFE require path probes (pcall only) ───────────────────────────────
-- These are the exact paths coldwar_old uses.
local REQUIRE_PATHS = {
    {
        name = "RecoilController",
        run = function()
            return require(RS.Client.Tools.Weapon.controllers.RecoilController)
        end,
    },
    {
        name = "AimController",
        run = function()
            return require(RS.Client.Tools.Weapon.controllers.AimController)
        end,
    },
    {
        name = "FireController",
        run = function()
            return require(RS.Client.Tools.Weapon.Muzzle.firemodes.FireController)
        end,
    },
    {
        name = "Trajectory",
        run = function()
            return require(RS:WaitForChild("Shared"):WaitForChild("Ballistics"):WaitForChild("Trajectory"))
        end,
    },
    {
        name = "Wielder",
        run = function()
            return require(RS.Client.Character.Wielder)
        end,
    },
    {
        name = "ProjectileMaterials",
        run = function()
            return require(RS:WaitForChild("Shared"):WaitForChild("Ballistics"):WaitForChild("ProjectileMaterials"))
        end,
    },
}

local required = {} -- cache successful modules

local function testRequires()
    print("[CW_PROBE] === REQUIRE PATHS (pcall) ===")
    for _, item in ipairs(REQUIRE_PATHS) do
        local ok, res = pcall(item.run)
        if ok and res ~= nil then
            required[item.name] = res
            local kind = typeof(res)
            local extra = kind
            if kind == "table" then
                local keys = {}
                local n = 0
                for k in pairs(res) do
                    n = n + 1
                    if n <= 8 then table.insert(keys, tostring(k)) end
                end
                extra = "table keys~" .. n .. " sample=[" .. table.concat(keys, ",") .. "]"
            end
            log("require:" .. item.name, true, extra, "safe")
        else
            log("require:" .. item.name, false, res, "safe")
        end
        task.wait() -- breathe
    end
end
testRequires()

-- List Remotes / Client tree lightly (safe Instance walk, depth-limited)
local function listChildren(parent, prefix, max)
    max = max or 30
    local out = {}
    if not parent then return out end
    local n = 0
    for _, ch in ipairs(parent:GetChildren()) do
        n = n + 1
        if n > max then
            table.insert(out, "...(+more)")
            break
        end
        table.insert(out, prefix .. ch.Name .. " (" .. ch.ClassName .. ")")
    end
    return out
end

print("[CW_PROBE] === RS.Client children ===")
local client = RS:FindFirstChild("Client")
if client then
    for _, line in ipairs(listChildren(client, "  ", 40)) do print("[CW_PROBE]" .. line) end
    log("tree:RS.Client", true, #client:GetChildren() .. " children", "safe")
else
    log("tree:RS.Client", false, "missing", "safe")
end

print("[CW_PROBE] === RS.Remotes children ===")
local remotes = RS:FindFirstChild("Remotes")
if remotes then
    for _, line in ipairs(listChildren(remotes, "  ", 40)) do print("[CW_PROBE]" .. line) end
    log("tree:RS.Remotes", true, #remotes:GetChildren() .. " children", "safe")
else
    log("tree:RS.Remotes", false, "missing", "safe")
end

print("[CW_PROBE] === RS.Shared children ===")
local shared = RS:FindFirstChild("Shared")
if shared then
    for _, line in ipairs(listChildren(shared, "  ", 40)) do print("[CW_PROBE]" .. line) end
    log("tree:RS.Shared", true, #shared:GetChildren() .. " children", "safe")
else
    log("tree:RS.Shared", false, "missing", "safe")
end

-- ── 4) OPT-IN micro tests (never auto) ─────────────────────────────────────

local function test_debug_on_local_fn()
    -- Pure local function — should never crash a sane executor
    local function sample(a, b)
        local x = a + b
        return x, "ok"
    end
    local okInfo, info = pcall(function()
        if not exists(API.debug_getinfo) then error("no getinfo") end
        return API.debug_getinfo(sample)
    end)
    log("call:debug.getinfo(local)", okInfo, okInfo and (info and (info.name or info.what or "table") or "ok") or info, "medium")

    local okUp, up = pcall(function()
        if not exists(API.debug_getupvalue) and not exists(API.debug_getupvalues) then
            error("no getupvalue(s)")
        end
        if exists(API.debug_getupvalues) then
            return API.debug_getupvalues(sample)
        end
        return { API.debug_getupvalue(sample, 1) }
    end)
    log("call:debug.getupvalue(s)(local)", okUp, okUp and ("type=" .. type(up)) or up, "medium")

    local okConst, consts = pcall(function()
        if not exists(API.debug_getconstants) then error("no getconstants") end
        return API.debug_getconstants(sample)
    end)
    log("call:debug.getconstants(local)", okConst, okConst and ("n=" .. (type(consts)=="table" and #consts or "?")) or consts, "medium")
end

local function test_hookfunction_local()
    if not exists(API.hookfunction) then
        log("call:hookfunction(local)", false, "API missing", "danger")
        return
    end
    local function victim(n) return n + 1 end
    local ok, err = pcall(function()
        local old
        old = API.hookfunction(victim, function(n)
            return old(n) + 10
        end)
        local r = victim(1)
        if r ~= 12 then error("hook result unexpected: " .. tostring(r)) end
    end)
    log("call:hookfunction(local dummy)", ok, ok and "hooked dummy OK" or err, "danger")
end

local function test_newcclosure()
    -- ONLY tests identity wrapper. NEVER calls native newcclosure (force-close on Madium).
    local ok, err = pcall(function()
        local f = API.newcclosure(function(x) return x * 2 end)
        if f(3) ~= 6 then error("identity wrapper broken") end
    end)
    log("call:newcclosure(identity only)", ok,
        ok and ("OK · " .. newcclosureMode .. " · native NEVER called") or err,
        "safe")
end

local function test_require_recoil_fields()
    local mod = required.RecoilController
    if not mod then
        log("inspect:RecoilController", false, "module not loaded", "safe")
        return
    end
    local ok, detail = pcall(function()
        local fn = mod.getRecoilMult
        if type(fn) ~= "function" then error("getRecoilMult not a function: " .. type(fn)) end
        if exists(API.debug_getupvalues) then
            local ups = API.debug_getupvalues(fn)
            return "getRecoilMult ok, upvalues type=" .. type(ups)
        end
        return "getRecoilMult exists (no getupvalues to inspect)"
    end)
    log("inspect:RecoilController.getRecoilMult", ok, ok and detail or detail, "medium")
end

local function test_require_aim_fields()
    local mod = required.AimController
    if not mod then
        log("inspect:AimController", false, "module not loaded", "safe")
        return
    end
    local ok, detail = pcall(function()
        local parts = {}
        for _, k in ipairs({ "toggle", "isAimingAvailable", "update", "getAlpha" }) do
            table.insert(parts, k .. "=" .. type(mod[k]))
        end
        return table.concat(parts, ", ")
    end)
    log("inspect:AimController fields", ok, ok and detail or detail, "safe")
end

local function test_trajectory_new_read()
    local mod = required.Trajectory
    if not mod then
        log("inspect:Trajectory", false, "module not loaded", "safe")
        return
    end
    log("inspect:Trajectory.new", type(mod.new) == "function", "type=" .. type(mod.new), "safe")
end

-- Soft getgc(): NEVER getgc(true). Yield often. Cap time + count. Abortable.
local function test_getgc_soft()
    if not exists(API.getgc) then
        log("call:getgc()", false, "missing", "danger")
        return
    end
    print("[CW_PROBE] soft getgc() starting — if client dies HERE, getgc() itself is unsafe")
    local ok, err = pcall(function()
        local t0 = os.clock()
        local objects = API.getgc() -- NOT true
        if type(objects) ~= "table" then error("getgc returned " .. type(objects)) end
        local count, fnCount = 0, 0
        for _, v in pairs(objects) do
            count = count + 1
            if typeof(v) == "function" then fnCount = fnCount + 1 end
            if count % 200 == 0 then
                if aborted then error("aborted by user") end
                if os.clock() - t0 > 3 then error("timeout 3s after " .. count) end
                task.wait()
            end
            if count >= 5000 then break end -- hard cap
        end
        log("call:getgc()", true, string.format("scanned=%d funcs~%d time=%.2fs", count, fnCount, os.clock() - t0), "danger")
    end)
    if not ok then
        log("call:getgc()", false, err, "danger")
    end
end

-- getgc(true) — separate, scariest. Opt-in only, tiny budget.
local function test_getgc_true()
    if not exists(API.getgc) then
        log("call:getgc(true)", false, "missing", "danger")
        return
    end
    print("[CW_PROBE] WARNING: getgc(true) — known crashy on Madium. Starting with yield/cap...")
    local ok, err = pcall(function()
        local t0 = os.clock()
        local objects = API.getgc(true)
        if type(objects) ~= "table" then error("returned " .. type(objects)) end
        local count = 0
        for _ in pairs(objects) do
            count = count + 1
            if count % 100 == 0 then
                if aborted then error("aborted") end
                if os.clock() - t0 > 2 then error("timeout 2s at " .. count) end
                task.wait()
            end
            if count >= 2000 then break end
        end
        log("call:getgc(true)", true, "scanned=" .. count, "danger")
    end)
    if not ok then
        log("call:getgc(true)", false, err, "danger")
    end
end

-- Find coldwar_old targets WITHOUT full aggressive loop if possible
local function test_find_coldwar_funcs_soft()
    if not exists(API.getgc) then
        log("find:coldwar funcs", false, "no getgc", "danger")
        return
    end
    if not exists(API.debug_getinfo) then
        log("find:coldwar funcs", false, "no debug.getinfo", "danger")
        return
    end
    print("[CW_PROBE] soft search for spreadVector / fire / aimupdate (capped)")
    local found = {
        spreadVector = false,
        fire = false,
        aimupdate = false,
        awaitLength = false,
        GetAllMuzzlesConfig = false,
    }
    local ok, err = pcall(function()
        local objects = API.getgc() -- soft
        local n = 0
        local t0 = os.clock()
        for _, v in pairs(objects) do
            n = n + 1
            if n % 150 == 0 then
                if aborted then error("aborted") end
                if os.clock() - t0 > 4 then break end
                task.wait()
            end
            if typeof(v) ~= "function" then continue end
            if exists(API.islclosure) then
                local okL, isL = pcall(API.islclosure, v)
                if okL and not isL then continue end
            end
            local okI, info = pcall(API.debug_getinfo, v)
            if not okI or type(info) ~= "table" then continue end
            local name = info.name or ""
            local src = info.source or info.short_src or ""
            if name == "spreadVector" then found.spreadVector = true end
            if name == "update" and string.find(tostring(src), "AimController", 1, true) then
                found.aimupdate = true
            end
            if name == "awaitLength" then found.awaitLength = true end
            if name == "GetAllMuzzlesConfig" then found.GetAllMuzzlesConfig = true end
            -- fire is harder; only flag if constants API works
            if exists(API.debug_getconstants) and string.find(tostring(src), "Shooter", 1, true) then
                local okc, consts = pcall(API.debug_getconstants, v)
                if okc and type(consts) == "table" and table.find(consts, "config") then
                    found.fire = true
                end
            end
            if n >= 8000 then break end
        end
    end)
    if not ok then
        log("find:coldwar funcs", false, err, "danger")
        return
    end
    local parts = {}
    for k, v in pairs(found) do
        table.insert(parts, k .. "=" .. tostring(v))
    end
    log("find:coldwar funcs", true, table.concat(parts, ", "), "danger")
end

local function test_httpget_linoria()
    local ok, err = pcall(function()
        local src = game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua")
        if type(src) ~= "string" or #src < 100 then error("bad body len=" .. tostring(src and #src)) end
        return #src
    end)
    log("call:HttpGet(Linoria)", ok, ok and ("bytes=" .. tostring(err)) or err, "medium")
end

local function test_drawing()
    if type(API.Drawing) ~= "table" or type(API.Drawing.new) ~= "function" then
        log("call:Drawing.new", false, "Drawing API missing", "medium")
        return
    end
    local ok, err = pcall(function()
        local c = API.Drawing.new("Circle")
        c.Visible = false
        c.Radius = 10
        if c.Remove then c:Remove() elseif c.Destroy then c:Destroy() end
    end)
    log("call:Drawing.new(Circle)", ok, ok and "ok" or err, "medium")
end

-- ── 5) Report helpers ──────────────────────────────────────────────────────
local function summaryText()
    local okN, failN = 0, 0
    local lines = { "CW_PROBE report — " .. executorName, "" }
    for _, r in ipairs(RESULTS) do
        if r.ok then okN = okN + 1 else failN = failN + 1 end
        table.insert(lines, string.format("[%s][%s] %s | %s", r.ok and "OK" or "FAIL", r.risk, r.name, r.detail))
    end
    table.insert(lines, "")
    table.insert(lines, string.format("TOTAL ok=%d fail=%d", okN, failN))
    return table.concat(lines, "\n"), okN, failN
end

local function saveReport()
    local text = summaryText()
    if exists(API.writefile) then
        pcall(function()
            API.writefile("CW_PROBE_Report.txt", text)
        end)
        return true
    end
    return false
end

-- ── 6) Minimal UI (same lib as other hubs) — load last ─────────────────────
local getGenv = (exists(API.getgenv) and API.getgenv) or function() return _G end
if getGenv()[scriptId] then pcall(getGenv()[scriptId]) end

local UI
local uiOk, uiErr = pcall(function()
    UI = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/Hplayfree25/luaLibrary/refs/heads/master/Init.lua?t=" .. tick()
    ))()
end)

if not uiOk or not UI then
    print("[CW_PROBE] UI failed:", uiErr)
    print(summaryText())
    print("[CW_PROBE] Use F9 console. Buttons unavailable — call tests manually if needed.")
    return
end

local Window = UI.CreateWindow({
    Title = "CW Probe (safe)",
    ToggleText = "PROBE",
    Size = UDim2.new(0, 480, 0, 360),
    Keybind = Enum.KeyCode.LeftAlt,
    HideOnStartup = false,
})

getGenv()[scriptId] = function()
    aborted = true
    if Window then pcall(function() Window.destroy() end) end
    getGenv()[scriptId] = nil
end

local Tab = UI.CreateTab(Window, "TESTS", 1)
local TabLog = UI.CreateTab(Window, "REPORT", 2)

UI.CreateLabel(Tab, "Base load = type checks + require only (safe).")
UI.CreateLabel(Tab, "Click ONE test at a time. Close = that test is the killer.")
UI.CreateLabel(Tab, "Executor: " .. executorName)

local function notify(title, content)
    pcall(function()
        UI.Notify({ Title = title, Content = content, Duration = 5 })
    end)
end

UI.CreateButton(Tab, "1) debug.* on local function", function()
    test_debug_on_local_fn()
    notify("Done", "debug local tests finished — check F9")
end)

UI.CreateButton(Tab, "2) newcclosure (identity only — native skipped)", function()
    test_newcclosure()
    notify("Done", "Native newcclosure NOT called (crashy on Madium)")
end)

UI.CreateButton(Tab, "3) hookfunction (local dummy ONLY)", function()
    test_hookfunction_local()
    notify("Done", "If still alive, local hook works")
end)

UI.CreateButton(Tab, "4) Inspect RecoilController", function()
    test_require_recoil_fields()
    notify("Done", "RecoilController inspect done")
end)

UI.CreateButton(Tab, "5) Inspect AimController + Trajectory", function()
    test_require_aim_fields()
    test_trajectory_new_read()
    notify("Done", "Aim/Trajectory inspect done")
end)

UI.CreateButton(Tab, "6) Drawing API", function()
    test_drawing()
    notify("Done", "Drawing test done")
end)

UI.CreateButton(Tab, "7) HttpGet Linoria", function()
    test_httpget_linoria()
    notify("Done", "HttpGet test done")
end)

UI.CreateLabel(Tab, "--- DANGER ZONE (may crash Madium) ---")

UI.CreateButton(Tab, "8) getgc() SOFT (no true, capped)", function()
    task.spawn(function()
        notify("Running", "getgc() soft…")
        test_getgc_soft()
        notify("Done", "getgc soft finished or failed — see F9")
    end)
end)

UI.CreateButton(Tab, "9) Find CW funcs via soft getgc", function()
    task.spawn(function()
        notify("Running", "searching funcs…")
        test_find_coldwar_funcs_soft()
        notify("Done", "search finished — see F9")
    end)
end)

UI.CreateButton(Tab, "10) getgc(true) — LAST RESORT", function()
    task.spawn(function()
        notify("WARNING", "getgc(true) starting — high crash risk")
        test_getgc_true()
        notify("Done", "getgc(true) finished or failed")
    end)
end)

UI.CreateButton(Tab, "ABORT flag (stop long scans)", function()
    aborted = true
    notify("Abort", "aborted=true for running scans")
    task.delay(1, function() aborted = false end)
end)

UI.CreateButton(TabLog, "Print full report (F9)", function()
    print("========== CW_PROBE REPORT ==========")
    print(summaryText())
    print("=====================================")
    notify("Report", "Printed to F9 console")
end)

UI.CreateButton(TabLog, "Save report to CW_PROBE_Report.txt", function()
    local ok = saveReport()
    notify(ok and "Saved" or "No writefile", ok and "CW_PROBE_Report.txt" or "print F9 instead")
    if not ok then print(summaryText()) end
end)

UI.CreateButton(TabLog, "Re-run SAFE require paths", function()
    testRequires()
    notify("Done", "require paths re-tested")
end)

UI.CreateButton(TabLog, "Unload probe", function()
    if getGenv()[scriptId] then getGenv()[scriptId]() end
end)

UI.CreateLabel(TabLog, "Pass order if all survive: 1→2→3→4→5→6→7 then 8→9. Avoid 10 on Madium.")

notify("CW Probe", "Safe checks done. Open PROBE / LeftAlt. See F9.")
print("[CW_PROBE] Base load complete. Open UI and run opt-in tests one by one.")
print(summaryText())
