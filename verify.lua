local _type = type
local _pcall = pcall
local _tostring = tostring
local _select = select
local _insert = table.insert
local _format = string.format
local _byte = string.byte
local _char = string.char
local _sub = string.sub
local _gsub = string.gsub
local _find = string.find
local _lower = string.lower
local _upper = string.upper
local _rep = string.rep
local _floor = math.floor
local _min = math.min
local _log = math.log
local _tick = (type(tick) == "function" and tick) or os.clock
local _time = os.time
local BOOT_T0 = _tick()
local FAIL_REASON = "ok"

local function isFn(v) return _type(v) == "function" end
local function isStr(v) return _type(v) == "string" end
local function isNum(v) return _type(v) == "number" end
local function isTable(v) return _type(v) == "table" end

local function hardStop(reason)
	FAIL_REASON = _tostring(reason or "verify_failed")
	local msg = "[NMZ-VERIFY] " .. FAIL_REASON
	if isFn(warn) then warn(msg) elseif isFn(print) then print(msg) end
	error(msg, 0)
end

local function safeCall(fn, ...)
	local ok, a, b, c, d, e = _pcall(fn, ...)
	if not ok then return false, a end
	return true, a, b, c, d, e
end

local function notify(title, text)
	if isFn(print) then
		print(_format("[NMZ-VERIFY] %s | %s", _tostring(title), _tostring(text)))
	end
end

local _bitAnd, _bitOr, _bitXor, _bitNot, _bitLShift, _bitRShift
do
	if bit32 then
		_bitAnd = function(a, b) return bit32.band(a, b) % 4294967296 end
		_bitOr = function(a, b) return bit32.bor(a, b) % 4294967296 end
		_bitXor = function(a, b) return bit32.bxor(a, b) % 4294967296 end
		_bitNot = function(a) return bit32.bnot(a) % 4294967296 end
		_bitLShift = function(a, n) return bit32.lshift(a, n) % 4294967296 end
		_bitRShift = function(a, n) return bit32.rshift(a, n) % 4294967296 end
	elseif bit then
		_bitAnd = function(a, b) return bit.band(a, b) % 4294967296 end
		_bitOr = function(a, b) return bit.bor(a, b) % 4294967296 end
		_bitXor = function(a, b) return bit.bxor(a, b) % 4294967296 end
		_bitNot = function(a) return bit.bnot(a) % 4294967296 end
		_bitLShift = function(a, n) return bit.lshift(a, n) % 4294967296 end
		_bitRShift = function(a, n) return bit.rshift(a, n) % 4294967296 end
	else
		_bitAnd = function(a, b)
			local r, m = 0, 1
			a, b = a % 4294967296, b % 4294967296
			for _ = 1, 32 do
				if a % 2 + b % 2 == 2 then r = r + m end
				a, b, m = _floor(a / 2), _floor(b / 2), m * 2
			end
			return r
		end
		_bitOr = function(a, b)
			local r, m = 0, 1
			a, b = a % 4294967296, b % 4294967296
			for _ = 1, 32 do
				if a % 2 + b % 2 > 0 then r = r + m end
				a, b, m = _floor(a / 2), _floor(b / 2), m * 2
			end
			return r
		end
		_bitXor = function(a, b)
			local r, m = 0, 1
			a, b = a % 4294967296, b % 4294967296
			for _ = 1, 32 do
				if a % 2 ~= b % 2 then r = r + m end
				a, b, m = _floor(a / 2), _floor(b / 2), m * 2
			end
			return r
		end
		_bitNot = function(a) return 4294967295 - (a % 4294967296) end
		_bitLShift = function(a, n) return (a * (2 ^ n)) % 4294967296 end
		_bitRShift = function(a, n) return _floor((a % 4294967296) / (2 ^ n)) end
	end
end

local function rrotate(x, n)
	n = n % 32
	return _bitOr(_bitRShift(x, n), _bitLShift(x, 32 - n)) % 4294967296
end

local function constantTimeEq(a, b)
	if not isStr(a) or not isStr(b) or #a ~= #b then return false end
	local diff = 0
	for i = 1, #a do
		diff = _bitOr(diff, _bitXor(_byte(a, i), _byte(b, i)))
	end
	return diff == 0
end

local function normalizeSource(src)
	if not isStr(src) or #src < 32 then return nil end
	src = _gsub(src, "\r\n", "\n")
	src = _gsub(src, "\r", "\n")
	if _sub(src, 1, 3) == "\239\187\191" then src = _sub(src, 4) end
	return src
end

local function mul32(a, b)
	a, b = a % 4294967296, b % 4294967296
	local a_l, a_h = a % 65536, _floor(a / 65536)
	local b_l, b_h = b % 65536, _floor(b / 65536)
	local lo = a_l * b_l
	local mid = (a_h * b_l + a_l * b_h) % 65536
	return (lo + mid * 65536) % 4294967296
end

local function fnv1a32(s)
	local h = 2166136261
	for i = 1, #s do
		h = _bitXor(h, _byte(s, i))
		h = mul32(h, 16777619)
	end
	return _format("%08x", h)
end

local function crc32(s)
	local poly, crc = 0xEDB88320, 0xFFFFFFFF
	for i = 1, #s do
		crc = _bitXor(crc, _byte(s, i))
		for _ = 1, 8 do
			if _bitAnd(crc, 1) ~= 0 then
				crc = _bitXor(_bitRShift(crc, 1), poly)
			else
				crc = _bitRShift(crc, 1)
			end
		end
	end
	return _format("%08x", _bitXor(crc, 0xFFFFFFFF))
end

local K = {
	0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
	0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
	0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
	0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
	0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
	0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
	0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
	0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2,
}

local function sha256(msg)
	if not isStr(msg) then return nil end
	if isTable(crypt) and isFn(crypt.hash) then
		local ok, dig = safeCall(crypt.hash, msg, "sha256")
		if ok and isStr(dig) then
			dig = _lower(_gsub(dig, "%s+", ""))
			if #dig == 64 then return dig end
		end
	end
	local len = #msg
	local bitLen = len * 8
	msg = msg .. "\128" .. _rep("\0", (55 - len) % 64) .. _char(
		_floor(bitLen / 2 ^ 56) % 256, _floor(bitLen / 2 ^ 48) % 256,
		_floor(bitLen / 2 ^ 40) % 256, _floor(bitLen / 2 ^ 32) % 256,
		_floor(bitLen / 2 ^ 24) % 256, _floor(bitLen / 2 ^ 16) % 256,
		_floor(bitLen / 2 ^ 8) % 256, bitLen % 256
	)
	local h0,h1,h2,h3 = 0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a
	local h4,h5,h6,h7 = 0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19
	local w = {}
	for i = 1, #msg, 64 do
		for j = 0, 15 do
			local p = i + j * 4
			w[j] = _bitLShift(_byte(msg, p), 24) + _bitLShift(_byte(msg, p + 1), 16)
				+ _bitLShift(_byte(msg, p + 2), 8) + _byte(msg, p + 3)
		end
		for j = 16, 63 do
			local v15, v2 = w[j - 15], w[j - 2]
			local s0 = _bitXor(_bitXor(rrotate(v15, 7), rrotate(v15, 18)), _bitRShift(v15, 3))
			local s1 = _bitXor(_bitXor(rrotate(v2, 17), rrotate(v2, 19)), _bitRShift(v2, 10))
			w[j] = (w[j - 16] + s0 + w[j - 7] + s1) % 4294967296
		end
		local a,b,c,d,e,f,g,h = h0,h1,h2,h3,h4,h5,h6,h7
		for j = 0, 63 do
			local S1 = _bitXor(_bitXor(rrotate(e, 6), rrotate(e, 11)), rrotate(e, 25))
			local ch = _bitXor(_bitAnd(e, f), _bitAnd(_bitNot(e), g))
			local t1 = (h + S1 + ch + K[j + 1] + w[j]) % 4294967296
			local S0 = _bitXor(_bitXor(rrotate(a, 2), rrotate(a, 13)), rrotate(a, 22))
			local maj = _bitXor(_bitXor(_bitAnd(a, b), _bitAnd(a, c)), _bitAnd(b, c))
			local t2 = (S0 + maj) % 4294967296
			h,g,f,e,d,c,b,a = g,f,e,(d + t1) % 4294967296,c,b,a,(t1 + t2) % 4294967296
		end
		h0 = (h0 + a) % 4294967296
		h1 = (h1 + b) % 4294967296
		h2 = (h2 + c) % 4294967296
		h3 = (h3 + d) % 4294967296
		h4 = (h4 + e) % 4294967296
		h5 = (h5 + f) % 4294967296
		h6 = (h6 + g) % 4294967296
		h7 = (h7 + h) % 4294967296
	end
	return _format("%08x%08x%08x%08x%08x%08x%08x%08x", h0, h1, h2, h3, h4, h5, h6, h7)
end

local function hasMarker(src, marker)
	return isStr(src) and isStr(marker) and _find(src, marker, 1, true) ~= nil
end

local function countLiteral(src, lit)
	local n, i = 0, 1
	while true do
		local a, b = _find(src, lit, i, true)
		if not a then break end
		n, i = n + 1, b + 1
		if n > 200000 then break end
	end
	return n
end

local function entropyScore(s)
	if not isStr(s) or #s == 0 then return 0 end
	local freq, n = {}, _min(#s, 8192)
	for i = 1, n do
		local b = _byte(s, i)
		freq[b] = (freq[b] or 0) + 1
	end
	local h = 0
	for _, c in pairs(freq) do
		local p = c / n
		h = h - p * (_log(p) / _log(2))
	end
	return h
end

local function structuralCheck(src)
	if not isStr(src) then return false, "not_string" end
	if #src < 1024 then return false, "too_small" end
	if #src > 5 * 1024 * 1024 then return false, "too_large" end
	if _find(src, "\0", 1, true) then return false, "nul_byte" end
	local openF, endC = countLiteral(src, "function"), countLiteral(src, "end")
	if openF < 3 or endC < 3 then return false, "structure_low" end
	if endC + 80 < openF then return false, "structure_imbalance" end
	local low = _lower(src)
	if hasMarker(low, "os.execute") or hasMarker(low, "io.popen") or hasMarker(low, "rm -rf") then
		return false, "dangerous_token"
	end
	local e = entropyScore(src)
	if e < 2.5 or e > 7.8 then return false, "entropy" end
	return true
end

local function getHttpGet()
	if isFn(game.HttpGet) then
		return function(url) return game:HttpGet(url, true) end
	end
	if isFn(game.HttpGetAsync) then
		return function(url) return game:HttpGetAsync(url) end
	end
	local req = (isFn(request) and request)
		or (isFn(http_request) and http_request)
		or (isTable(http) and isFn(http.request) and http.request)
		or (isTable(syn) and isFn(syn.request) and syn.request)
	if req then
		return function(url)
			local res = req({ Url = url, Method = "GET" })
			if isTable(res) and isStr(res.Body) and (res.StatusCode == nil or res.StatusCode == 200) then
				return res.Body
			end
			error("request_failed")
		end
	end
	return nil
end

local CATALOG = {
	{
		id = "newg",
		name = "Entrenched WW1",
		file = "NewG.lua",
		placeId = 3678761576,
		size = 81490,
		sha256 = "e443415fffe4038a3632573edd735930994d5b9b08e72af79f1cbbd32f25f475",
		fnv1a = "8c02016d",
		crc32 = "09fde240",
		markers = {
			"TARGET_PLACE_ID = 3678761576",
			"Developed by NMZ Team",
			"MNZ ENTRENCHED WW1",
			"local isExecutorSupported = true",
			"noRecoilEnabled",
			"silentAimEnabled",
		},
		antiMarkers = {
			"NMZ Cold War",
			"ColdWar_Config.json",
			"TARGET_PLACE_ID = 13687899540",
		},
	},
	{
		id = "coldwar",
		name = "Cold War",
		file = "coldwar.lua",
		placeId = 13687899540,
		size = 54384,
		sha256 = "415af91882d313cc583bcb604529093e0d9259001e398a41d137581edf082752",
		fnv1a = "cb11234a",
		crc32 = "c9b59a38",
		markers = {
			"TARGET_PLACE_ID = 13687899540",
			"NMZ Cold War",
			"ColdWar_Config.json",
			"local combat = {",
			"SilentEnabled",
			"NoBulletDrop",
		},
		antiMarkers = {
			"MNZ ENTRENCHED WW1",
			"Developed by NMZ Team (c) 2026",
			"TARGET_PLACE_ID = 3678761576",
		},
	},
}

local BASES = {
	"https://raw.githubusercontent.com/Hplayfree25/luaLibrary/refs/heads/master/",
	"https://raw.githubusercontent.com/Hplayfree25/luaLibrary/master/",
	"https://cdn.jsdelivr.net/gh/Hplayfree25/luaLibrary@master/",
}

local function buildUrls(file)
	local urls = {}
	local salt = _format("%d%d", _floor(_tick() * 1000) % 1000000, _time() % 100000)
	for _, base in ipairs(BASES) do
		_insert(urls, base .. file .. "?v=" .. salt)
		_insert(urls, base .. file)
	end
	return urls
end

local function fetchSource(file)
	local httpGet = getHttpGet()
	if not httpGet then return nil, "no_http" end
	local lastErr = "fetch_failed"
	for _, url in ipairs(buildUrls(file)) do
		local ok, body = safeCall(httpGet, url)
		if ok and isStr(body) then
			local norm = normalizeSource(body)
			if norm and #norm > 64 then
				local low = _lower(norm)
				if not hasMarker(low, "404: not found") and not hasMarker(low, "400: invalid") and not hasMarker(low, "<!doctype html") then
					return norm, url
				end
				lastErr = "not_found"
			else
				lastErr = "empty_body"
			end
		else
			lastErr = _tostring(body)
		end
	end
	return nil, lastErr
end

local function sleep(sec)
	if isTable(task) and isFn(task.wait) then
		task.wait(sec)
	elseif isFn(wait) then
		wait(sec)
	end
end

local function dualFetchConsensus(file)
	local a, aUrl = fetchSource(file)
	if not a then return nil, aUrl end
	sleep(0.05)
	local b, bUrl = fetchSource(file)
	if not b then return nil, bUrl end
	if constantTimeEq(a, b) then return a, aUrl end
	sleep(0.05)
	local c, cUrl = fetchSource(file)
	if not c then return nil, "consensus_fetch_fail" end
	if constantTimeEq(a, c) then return a, aUrl end
	if constantTimeEq(b, c) then return b, bUrl end
	return nil, "consensus_mismatch"
end

local function verifyIntegrity(entry, src)
	if not isTable(entry) or not isStr(src) then return false, "bad_args" end
	if #src ~= entry.size then
		return false, _format("size_mismatch:%d!=%d", #src, entry.size)
	end
	local okStruct, why = structuralCheck(src)
	if not okStruct then return false, "struct:" .. _tostring(why) end
	for _, m in ipairs(entry.markers) do
		if not hasMarker(src, m) then return false, "missing_marker:" .. m end
	end
	for _, m in ipairs(entry.antiMarkers or {}) do
		if hasMarker(src, m) then return false, "anti_marker:" .. m end
	end
	local gotFnv = fnv1a32(src)
	if not constantTimeEq(gotFnv, entry.fnv1a) then
		return false, "fnv_mismatch:" .. gotFnv
	end
	local gotCrc = crc32(src)
	if not constantTimeEq(gotCrc, entry.crc32) then
		return false, "crc_mismatch:" .. gotCrc
	end
	local gotSha = sha256(src)
	if not isStr(gotSha) then return false, "sha_unavailable" end
	if not constantTimeEq(_lower(gotSha), entry.sha256) then
		return false, "sha_mismatch:" .. gotSha
	end
	local head = _sub(src, 1, 128)
	local mid = _sub(src, _floor(#src / 2) - 63, _floor(#src / 2) + 64)
	local tail = _sub(src, #src - 127)
	local edge = sha256(head .. "|" .. mid .. "|" .. tail .. "|" .. _tostring(entry.size) .. "|" .. entry.fnv1a)
	if not isStr(edge) or #edge ~= 64 then return false, "edge_hash" end
	local seal = sha256(entry.sha256 .. ":" .. gotCrc .. ":" .. gotFnv .. ":" .. edge)
	if not isStr(seal) or #seal ~= 64 then return false, "seal_hash" end
	return true, {
		sha256 = gotSha,
		fnv1a = gotFnv,
		crc32 = gotCrc,
		edge = edge,
		seal = seal,
		bytes = #src,
	}
end

local function envHardeningCheck()
	if not isFn(loadstring) and not isFn(load) then
		return false, "no_loadstring"
	end
	if not getHttpGet() then
		return false, "no_http_transport"
	end
	local identity = 0
	if isFn(getthreadidentity) then
		local ok, v = safeCall(getthreadidentity)
		if ok and isNum(v) then identity = v end
	elseif isFn(getidentity) then
		local ok, v = safeCall(getidentity)
		if ok and isNum(v) then identity = v end
	end
	local exec = ""
	if isFn(identifyexecutor) then
		local ok, v = safeCall(identifyexecutor)
		if ok and isStr(v) then exec = _lower(v) end
	elseif isFn(getexecutorname) then
		local ok, v = safeCall(getexecutorname)
		if ok and isStr(v) then exec = _lower(v) end
	end
	for _, b in ipairs({ "xeno", "solara", "velocity" }) do
		if _find(exec, b, 1, true) then
			return false, "blocked_executor:" .. b
		end
	end
	return true, { identity = identity, executor = exec }
end

local function chooseById(id)
	id = _lower(_tostring(id or ""))
	id = _gsub(id, "%s+", "")
	if id == "ww1" or id == "entrenched" or id == "entrenchedww1" or id == "newg.lua" then
		id = "newg"
	elseif id == "cw" or id == "coldwar.lua" then
		id = "coldwar"
	end
	for _, e in ipairs(CATALOG) do
		if e.id == id or _lower(e.file) == id or _lower(_gsub(e.name, "%s+", "")) == id then
			return e
		end
	end
	return nil
end

local function currentPlaceId()
	local ok, pid = safeCall(function() return game.PlaceId end)
	if ok and isNum(pid) then return pid end
	return 0
end

local function entryByPlaceId(placeId)
	for _, e in ipairs(CATALOG) do
		if e.placeId == placeId then return e end
	end
	return nil
end

local function detectTarget()
	local placeId = currentPlaceId()
	local byPlace = entryByPlaceId(placeId)
	if byPlace then return byPlace end
	local gameName = ""
	local ok, n = safeCall(function() return _tostring(game.Name or "") end)
	if ok and isStr(n) then gameName = n end
	local ln = _lower(gameName)
	if (_find(ln, "cold", 1, true) and _find(ln, "war", 1, true)) or _find(ln, "coldwar", 1, true) then
		return CATALOG[2]
	end
	if _find(ln, "entrench", 1, true) or _find(ln, "ww1", 1, true) then
		return CATALOG[1]
	end
	return nil
end

local function getgenvSafe()
	if not isFn(getgenv) then return nil end
	local ok, g = safeCall(getgenv)
	if ok and isTable(g) then return g end
	return nil
end

local function resolveEntry(pref)
	if isStr(pref) and #pref > 0 then
		local e = chooseById(pref)
		if e then return e end
	end
	local genv = getgenvSafe()
	if genv and isStr(genv.NMZ_SCRIPT) then
		local e = chooseById(genv.NMZ_SCRIPT)
		if e then return e end
	end
	if isStr(NMZ_SCRIPT) then
		local e = chooseById(NMZ_SCRIPT)
		if e then return e end
	end
	local detected = detectTarget()
	if detected then return detected end
	return nil
end

local function compileAndRun(src, chunkName)
	local loader = loadstring or load
	if not isFn(loader) then return false, "no_loader" end
	local ok, fnOrErr = safeCall(loader, src, chunkName or "@nmz_verified")
	if not ok then return false, "compile_err:" .. _tostring(fnOrErr) end
	if not isFn(fnOrErr) then return false, "compile_not_fn:" .. _tostring(fnOrErr) end
	local ran, res = safeCall(fnOrErr)
	if not ran then return false, "runtime_err:" .. _tostring(res) end
	return true, res
end

local function lockBag(report)
	local genv = getgenvSafe()
	if not genv then return end
	genv.__NMZ_VERIFY = {
		ok = true,
		at = _time(),
		elapsed = _tick() - BOOT_T0,
		report = report,
	}
	genv.__NMZ_VERIFY_SEAL = report.seal
end

local function cryptoSelfTest()
	local e = sha256("")
	local a = sha256("abc")
	if e ~= "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" then
		return false, "sha_empty_fail"
	end
	if a ~= "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" then
		return false, "sha_abc_fail"
	end
	if fnv1a32("abc") ~= "1a47e90b" then
		return false, "fnv_abc_fail"
	end
	if crc32("123456789") ~= "cbf43926" then
		return false, "crc_vec_fail"
	end
	if not constantTimeEq("deadbeef", "deadbeef") then return false, "cteq_true_fail" end
	if constantTimeEq("deadbeef", "deadbeee") then return false, "cteq_false_fail" end
	return true
end

local function antiTamperSelfCheck()
	local okCrypto, why = cryptoSelfTest()
	if not okCrypto then return false, why end
	local info
	if isTable(debug) and isFn(debug.getinfo) then
		local ok, i = safeCall(debug.getinfo, antiTamperSelfCheck)
		if ok then info = i end
	elseif isFn(getinfo) then
		local ok, i = safeCall(getinfo, antiTamperSelfCheck)
		if ok then info = i end
	end
	if isTable(info) and info.what == "C" then
		return false, "verifier_hooked_c"
	end
	local probe = function() return 0xA5A5 end
	local ok, res = safeCall(probe)
	if not ok or res ~= 0xA5A5 then return false, "probe_corrupt" end
	return true
end

local function runPipeline(pref)
	local selfOk, selfWhy = antiTamperSelfCheck()
	if not selfOk then return hardStop(selfWhy) end
	local envOk, envInfo = envHardeningCheck()
	if not envOk then return hardStop(envInfo) end
	local placeId = currentPlaceId()
	local entry = resolveEntry(pref)
	if not entry then
		notify("SELECT", "set getgenv().NMZ_SCRIPT = 'newg' | 'coldwar' (or ww1/cw)")
		return hardStop("target_unresolved placeId=" .. _tostring(placeId))
	end
	if entry.placeId and placeId ~= 0 and placeId ~= entry.placeId then
		return hardStop(_format("place_mismatch: need %s got %s for %s", _tostring(entry.placeId), _tostring(placeId), entry.id))
	end
	notify("TARGET", _format("%s (%s) placeId=%s", entry.name, entry.file, _tostring(entry.placeId)))
	local src, from = dualFetchConsensus(entry.file)
	if not src then return hardStop("fetch:" .. _tostring(from)) end
	local ok, meta = verifyIntegrity(entry, src)
	if not ok then return hardStop("integrity:" .. _tostring(meta)) end
	local report = {
		id = entry.id,
		name = entry.name,
		file = entry.file,
		placeId = entry.placeId,
		livePlaceId = placeId,
		source = from,
		bytes = meta.bytes,
		sha256 = meta.sha256,
		fnv1a = meta.fnv1a,
		crc32 = meta.crc32,
		edge = meta.edge,
		seal = meta.seal,
		executor = envInfo.executor,
		identity = envInfo.identity,
	}
	lockBag(report)
	notify("PASS", _format("%s sha256=%s crc=%s", entry.file, meta.sha256, meta.crc32))
	local ran, res = compileAndRun(src, "@" .. entry.file)
	if not ran then return hardStop(res) end
	notify("LOADED", entry.name)
	return res, report
end

local preferred = nil
do
	local genv = getgenvSafe()
	if genv and isStr(genv.NMZ_SCRIPT) then
		preferred = genv.NMZ_SCRIPT
	elseif isStr(NMZ_SCRIPT) then
		preferred = NMZ_SCRIPT
	end
end

return runPipeline(preferred)
