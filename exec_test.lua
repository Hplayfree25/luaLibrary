local res = {}

local function log_stat(name, stat)
    local msg = string.format("[%s] %s", stat, name)
    print(msg)
    table.insert(res, msg)
end

local function chk_env(path)
    local pts = string.split(path, ".")
    local cur = getfenv(0)
    if getgenv then
        local ok, env = pcall(getgenv)
        if ok and env then cur = env end
    end
    for _, p in ipairs(pts) do
        if type(cur) ~= "table" and type(cur) ~= "userdata" then return false end
        local ok, v = pcall(function() return cur[p] end)
        if not ok or v == nil then return false end
        cur = v
    end
    return true
end

local unc_env = {
    "cache.invalidate", "cache.iscached", "cache.replace",
    "checkcaller", "clonefunction", "getcallingscript", "getscriptclosure", "hookfunction", "iscclosure", "islclosure", "newcclosure",
    "rconsoleclear", "rconsolecreate", "rconsoledestroy", "rconsoleinput", "rconsoleprint", "rconsolesettitle",
    "crypt.base64encode", "crypt.base64decode", "crypt.encrypt", "crypt.decrypt", "crypt.generatebytes", "crypt.generatekey", "crypt.hash",
    "debug.getconstant", "debug.getconstants", "debug.getinfo", "debug.getproto", "debug.getprotos", "debug.getstack", "debug.getupvalue", "debug.getupvalues", "debug.setconstant", "debug.setstack", "debug.setupvalue",
    "readfile", "listfiles", "writefile", "makefolder", "appendfile", "isfile", "isfolder", "delfolder", "delfile", "loadfile", "dofile",
    "mouse1click", "mouse1press", "mouse1release", "mouse2click", "mouse2press", "mouse2release", "mousemoverel", "mousemoverel", "mousescroll",
    "fireclickdetector", "getcallbackvalue", "getconnections", "getcustomasset", "gethiddenproperty", "sethiddenproperty", "gethui", "getinstances", "getnilinstances", "isscriptable", "setscriptable", "setrbxclipboard",
    "getrawmetatable", "hookmetamethod", "getnamecallmethod", "isreadonly", "setrawmetatable", "setreadonly",
    "identifyexecutor", "lz4compress", "lz4decompress", "messagebox", "queue_on_teleport", "request", "setclipboard", "setfpscap",
    "getgc", "getgenv", "getloadedmodules", "getrenv", "getrunningscripts", "getscriptbytecode", "getscripthash", "getscripts", "getsenv", "getthreadidentity", "setthreadidentity",
    "Drawing", "Drawing.new", "Drawing.Fonts", "isrenderobj", "getrenderproperty", "setrenderproperty", "cleardrawcache",
    "WebSocket", "WebSocket.connect", "cloneref"
}

local sunc_tst = {
    {
        n = "hookfunction",
        r = function()
            if not hookfunction then return false, "MISSING" end
            local f1 = function() return 1 end
            local f2 = function() return 2 end
            hookfunction(f1, f2)
            if f1() ~= 2 then return false, "SPOOFED" end
            return true, "SUCCESS"
        end
    },
    {
        n = "hookmetamethod",
        r = function()
            if not hookmetamethod then return false, "MISSING" end
            local inst = Instance.new("Folder")
            local old
            old = hookmetamethod(game, "__namecall", function(self, ...)
                if self == inst and getnamecallmethod() == "GetFullName" then
                    return "hooked"
                end
                return old(self, ...)
            end)
            if inst:GetFullName() ~= "hooked" then return false, "SPOOFED" end
            return true, "SUCCESS"
        end
    },
    {
        n = "cloneref",
        r = function()
            if not cloneref then return false, "MISSING" end
            local p = game:GetService("Players")
            local ref = cloneref(p)
            if typeof(ref) ~= "Instance" then return false, "SPOOFED" end
            if ref == p then return false, "SPOOFED" end
            if ref.Name ~= p.Name then return false, "SPOOFED" end
            return true, "SUCCESS"
        end
    },
    {
        n = "clonefunction",
        r = function()
            if not clonefunction then return false, "MISSING" end
            local fn = function() return 42 end
            local cfn = clonefunction(fn)
            if cfn == fn then return false, "SPOOFED" end
            if cfn() ~= 42 then return false, "SPOOFED" end
            return true, "SUCCESS"
        end
    },
    {
        n = "newcclosure",
        r = function()
            if not newcclosure then return false, "MISSING" end
            local fn = function() return 7 end
            local cfn = newcclosure(fn)
            if iscclosure and not iscclosure(cfn) then return false, "SPOOFED" end
            if cfn() ~= 7 then return false, "SPOOFED" end
            return true, "SUCCESS"
        end
    },
    {
        n = "getrawmetatable",
        r = function()
            if not getrawmetatable then return false, "MISSING" end
            local inst = Instance.new("Folder")
            local meta = getrawmetatable(inst)
            if type(meta) ~= "table" then return false, "SPOOFED" end
            return true, "SUCCESS"
        end
    },
    {
        n = "setreadonly",
        r = function()
            if not setreadonly or not isreadonly then return false, "MISSING" end
            local t = {}
            setmetatable(t, {})
            setreadonly(t, true)
            if not isreadonly(t) then return false, "SPOOFED" end
            return true, "SUCCESS"
        end
    },
    {
        n = "getgenv",
        r = function()
            if not getgenv then return false, "MISSING" end
            local env = getgenv()
            if type(env) ~= "table" then return false, "SPOOFED" end
            env.TEST_VAR = 123
            if getgenv().TEST_VAR ~= 123 then return false, "SPOOFED" end
            return true, "SUCCESS"
        end
    },
    {
        n = "checkcaller",
        r = function()
            if not checkcaller then return false, "MISSING" end
            if type(checkcaller()) ~= "boolean" then return false, "SPOOFED" end
            return true, "SUCCESS"
        end
    },
    {
        n = "getnamecallmethod",
        r = function()
            if not getnamecallmethod then return false, "MISSING" end
            local inst = Instance.new("Folder")
            local pass = false
            local old
            if hookmetamethod then
                old = hookmetamethod(game, "__namecall", function(self, ...)
                    if self == inst and getnamecallmethod() == "Destroy" then
                        pass = true
                        return
                    end
                    return old(self, ...)
                end)
                pcall(function() inst:Destroy() end)
                if not pass then return false, "SPOOFED" end
                return true, "SUCCESS"
            else
                return false, "MISSING_DEP"
            end
        end
    }
}

local function run_tests()
    print("--- UNC & sUNC Stress Test ---")
    
    local u_pass = 0
    local u_tot = #unc_env
    for _, v in ipairs(unc_env) do
        if chk_env(v) then
            u_pass = u_pass + 1
        end
    end
    local u_sco = math.floor((u_pass / u_tot) * 100)
    
    local su_pass = 0
    local su_tot = #sunc_tst
    
    for _, t in ipairs(sunc_tst) do
        local ok, st, msg = pcall(t.r)
        if not ok then
            msg = "FAILED - " .. tostring(st)
            st = false
        end
        if st then
            su_pass = su_pass + 1
            log_stat(t.n, "SUCCESS")
        else
            log_stat(t.n, msg or "SPOOFED")
        end
    end
    
    local su_sco = math.floor((su_pass / su_tot) * 100)
    
    local out = string.format("\n--- RESULTS ---\nUNC: %d%% (%d/%d)\nsUNC: %d%% (%d/%d)\n---------------", u_sco, u_pass, u_tot, su_sco, su_pass, su_tot)
    print(out)
end

run_tests()
