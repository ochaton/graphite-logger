local ffi = require 'ffi'

local _VERSION = 0.2

local function redef(t,def)
	if not pcall(ffi.typeof, t) then
		ffi.cdef(def)
	end
end
local function fdef(fn,def)
	if not pcall(function(fn) local t = ffi.C[fn] end, fn) then
		ffi.cdef(def)
	end
end

redef('size_t',    'typedef unsigned int    size_t;')
redef('ssize_t',   'typedef int             ssize_t;')
redef('in_addr_t', 'typedef uint32_t        in_addr_t;')
redef('socklen_t', 'typedef int             socklen_t;')
redef('struct sockaddr', [[
	struct sockaddr {
		unsigned short    sa_family;    // address family, AF_xxx
		char              sa_data[14];  // 14 bytes of protocol address
	};
]])
redef('struct in_addr', [[
	struct in_addr {
		in_addr_t s_addr;               // load with inet_pton()
	};
]])
redef('struct sockaddr_in', [[
	struct sockaddr_in {
		short            sin_family;   // e.g. AF_INET, AF_INET6    (2)
		unsigned short   sin_port;     // e.g. htons(3490)          (2)
		struct in_addr   sin_addr;     // see struct in_addr, below (4)
		char             sin_zero[8];  // zero this if you want to  (8)
	};
]])

fdef('socket',   [[ int socket(int domain, int type, int protocol); ]])
fdef('htons',    [[ uint16_t htons(uint16_t hostshort); ]])
fdef('inet_addr',[[ in_addr_t inet_addr(const char *cp); ]])
fdef('sendto',   [[ ssize_t sendto(int sockfd, const void *buf, size_t len, int flags, const struct sockaddr *dest_addr, socklen_t addrlen); ]])
fdef('strerror', [[ char *strerror(int errnum); ]])

local sockaddr_in = ffi.typeof("struct sockaddr_in")
local in_addr = ffi.typeof("struct in_addr")
local C = ffi.C

local function strerror() return ffi.string(C.strerror(ffi.errno())) end

local M = {}

setmetatable(M, {
	__call = function(self,...) return self:new(...) end,
})

local logger = setmetatable({ log = {} }, {
	__index = function(self, level)
		return rawget(self.log, level) or function(fmt, ...)
			fmt = "[%s] " .. fmt
			print(string.format(fmt, level, ...))
		end
	end,
	__call = function(self, log)
		self.log = log or {}
		return self
	end
})

function M:new(args)
	local dummy = { send = function() end }
	if type(args) ~= 'table' then
		print("[graphite]: Creating dummy graphite with no args")
		return dummy
	end
	if not args.ip then
		print("[graphite]: ip is required")
		return dummy
	end
	if args.enabled == false then
		print("[graphite]: enabled == false")
		return dummy
	end
	local self = setmetatable({
		ip      = tostring(args.ip);
		port    = tonumber(args.port or 2003);
		prefix  = tostring(args.prefix or "");
		log     = logger(args.log);
	}, { __index = M })

	self.sockfd = C.socket(2, 2, 0)
	if tonumber(self.sockfd) == -1 then
		self.log.error("Socket not openned: %s", strerror())
		return dummy
	end

	local chost = in_addr(C.inet_addr(ffi.cast("const char *", self.ip)))
	local cport = C.htons(ffi.cast("unsigned short", self.port))
	local cinzero = ffi.new("char[8]", {}) -- 8 '\0'
	self.sa = sockaddr_in(2, cport, chost, cinzero)
	self.dest_addr = ffi.cast("struct sockaddr *", self.sa)
	self.addr_len = ffi.cast("socklen_t", ffi.sizeof(self.sa))

	self.log.info("Using %s:%s for graphite", self.ip, self.port)
	return self
end

function M:send(key, value, ts)
	if not ts then ts = os.time() end
	local m = string.format("%s%s %s %s\n", self.prefix, key, value, ts)
	local r = C.sendto(self.sockfd, m, #m, 0, self.dest_addr, self.addr_len)
	if r == -1 then
		self.log.err("failed to send: %s", strerror())
	end
end

return M
