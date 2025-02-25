#!/usr/bin/lua

local ucursor = require "luci.model.uci".cursor()
local json = require "luci.jsonc"

local server_section = arg[1]
local proto = arg[2]
local local_port = arg[3] or "0"
local socks_port = arg[4] or "0"

local chain = arg[5] or "0"
local chain_local_port = string.split(chain, "/")[2] or "0"

local server = ucursor:get_all("shadowsocksr", server_section)
local outbound_settings = nil

function vmess_vless()
	outbound_settings = {
		vnext = {
			{
				address = server.server,
				port = tonumber(server.server_port),
				users = {
					{
						id = server.vmess_id,
						alterId = (server.v2ray_protocol == "vmess" or not server.v2ray_protocol) and tonumber(server.alter_id) or nil,
						security = (server.v2ray_protocol == "vmess" or not server.v2ray_protocol) and server.security or nil,
						encryption = (server.v2ray_protocol == "vless") and server.vless_encryption or nil,
						flow = ((server.tls == '1') or (server.reality == '1')) and server.tls_flow or nil
					}
				}
			}
		}
	}
end
function trojan_shadowsocks()
	outbound_settings = {
		servers = {
			{
				address = server.server,
				port = tonumber(server.server_port),
				password = server.password,
				method = ((server.v2ray_protocol == "shadowsocks") and server.encrypt_method_ss) or nil,
				uot = (server.v2ray_protocol == "shadowsocks") and (server.uot == '1') or nil,
				ivCheck = (server.v2ray_protocol == "shadowsocks") and (server.ivCheck == '1') or nil,
			}
		}
	}
end
function socks_http()
	outbound_settings = {
		version = server.socks_ver or nil,
		servers = {
			{
				address = server.server,
				port = tonumber(server.server_port),
				users = (server.auth_enable == "1") and {
					{
						user = server.username,
						pass = server.password
					}
				} or nil
			}
		}
	}
end
function wireguard()
	outbound_settings = {
		secretKey = server.private_key,
		address = server.local_addresses,
		peers = {
			{
				publicKey = server.peer_pubkey,
				preSharedKey = server.preshared_key,
				endpoint = server.server .. ":" .. server.server_port
			}
		},
		mtu = tonumber(server.mtu)
	}
end
local outbound = {}
function outbound:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end
function outbound:handleIndex(index)
	local switch = {
		vmess = function()
			vmess_vless()
		end,
		vless = function()
			vmess_vless()
		end,
		trojan = function()
			trojan_shadowsocks()
		end,
		shadowsocks = function()
			trojan_shadowsocks()
		end,
		socks = function()
			socks_http()
		end,
		http = function()
			socks_http()
		end,
		wireguard = function()
			wireguard()
		end
	}
	if switch[index] then
		switch[index]()
	end
end
local settings = outbound:new()
settings:handleIndex(server.v2ray_protocol)
local Xray = {
	log = {
		-- error = "/var/ssrplus.log",
		loglevel = "warning"
	},
	-- 传入连接
	inbound = (local_port ~= "0") and {
		-- listening
		port = tonumber(local_port),
		protocol = "dokodemo-door",
		settings = {network = proto, followRedirect = true},
		sniffing = {enabled = true, destOverride = {"http", "tls", "quic"}}
	} or nil,
	-- 开启 socks 代理
	inboundDetour = (proto:find("tcp") and socks_port ~= "0") and {
		{
			-- socks
			protocol = "socks",
			port = tonumber(socks_port),
			settings = {auth = "noauth", udp = true}
		}
	} or nil,
	-- 传出连接
	outbound = {
		protocol = server.v2ray_protocol,
		settings = outbound_settings,
		-- 底层传输配置
		streamSettings = {
			network = server.transport or "tcp",
			security = (server.tls == '1') and "tls" or (server.reality == '1') and "reality" or nil,
			tlsSettings = (server.tls == '1') and {
				-- tls
				alpn = server.tls_alpn,
				fingerprint = server.fingerprint,
				allowInsecure = (server.insecure == "1"),
				serverName = server.tls_host,
				certificates = server.certificate and {
					usage = "verify",
					certificateFile = server.certpath
				} or nil
			} or nil,
			realitySettings = (server.reality == '1') and {
				publicKey = server.reality_publickey,
				shortId = server.reality_shortid,
				spiderX = server.reality_spiderx,
				fingerprint = server.fingerprint,
				serverName = server.tls_host
			} or nil,
			tcpSettings = (server.transport == "tcp" and server.tcp_guise == "http") and {
				-- tcp
				header = {
					type = server.tcp_guise,
					request = {
						-- request
						path = {server.http_path} or {"/"},
						headers = {Host = {server.http_host} or {}}
					}
				}
			} or nil,
			kcpSettings = (server.transport == "kcp") and {
				-- kcp
				mtu = tonumber(server.mtu),
				tti = tonumber(server.tti),
				uplinkCapacity = tonumber(server.uplink_capacity),
				downlinkCapacity = tonumber(server.downlink_capacity),
				congestion = (server.congestion == "1") and true or false,
				readBufferSize = tonumber(server.read_buffer_size),
				writeBufferSize = tonumber(server.write_buffer_size),
				header = {type = server.kcp_guise},
				seed = server.seed or nil
			} or nil,
			wsSettings = (server.transport == "ws") and (server.ws_path or server.ws_host or server.tls_host) and {
				-- ws
				headers = (server.ws_host or server.tls_host) and {
					-- headers
					Host = server.ws_host or server.tls_host
				} or nil,
				path = server.ws_path,
				maxEarlyData = tonumber(server.ws_ed) or nil,
				earlyDataHeaderName = server.ws_ed_header or nil
			} or nil,
			httpSettings = (server.transport == "h2") and {
				-- h2
				path = server.h2_path or "",
				host = {server.h2_host} or nil,
				read_idle_timeout = tonumber(server.read_idle_timeout) or nil,
				health_check_timeout = tonumber(server.health_check_timeout) or nil
			} or nil,
			quicSettings = (server.transport == "quic") and {
				-- quic
				security = server.quic_security,
				key = server.quic_key,
				header = {type = server.quic_guise}
			} or nil,
			grpcSettings = (server.transport == "grpc") and {
				-- grpc
				serviceName = server.serviceName or "",
				multiMode = (server.grpc_mode == "multi") and true or false,
				idle_timeout = tonumber(server.idle_timeout) or nil,
				health_check_timeout = tonumber(server.health_check_timeout) or nil,
				permit_without_stream = (server.permit_without_stream == "1") and true or nil,
				initial_windows_size = tonumber(server.initial_windows_size) or nil
			} or nil,
			sockopt = (server.mptcp == "1") and {
				tcpcongestion = "bbr",
				tcpMptcp = true,
				tcpNoDelay = true
			} or nil
		},
		mux = (server.mux == "1") and {
			-- mux
			enabled = true,
			concurrency = tonumber(server.concurrency),
			xudpConcurrency = tonumber(server.xudpConcurrency),
			xudpProxyUDP443 = server.xudpProxyUDP443
		} or nil
	} or nil
}
local cipher = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:AES128-SHA:AES256-SHA:DES-CBC3-SHA"
local cipher13 = "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384"
local trojan = {
	log_level = 3,
	run_type = (proto == "nat" or proto == "tcp") and "nat" or "client",
	local_addr = "0.0.0.0",
	local_port = tonumber(local_port),
	remote_addr = server.server,
	remote_port = tonumber(server.server_port),
	udp_timeout = 60,
	-- 传入连接
	password = {server.password},
	-- 传出连接
	ssl = {
		verify = (server.insecure == "0") and true or false,
		verify_hostname = (server.tls == "1") and true or false,
		cert = (server.certificate) and server.certpath or nil,
		cipher = cipher,
		cipher_tls13 = cipher13,
		sni = server.tls_host,
		alpn = server.tls_alpn or {"h2", "http/1.1"},
		curve = "",
		reuse_session = true,
		session_ticket = (server.tls_sessionTicket == "1") and true or false
	},
	udp_timeout = 60,
	tcp = {
		-- tcp
		no_delay = true,
		keep_alive = true,
		reuse_port = true,
		fast_open = (server.fast_open == "1") and true or false,
		fast_open_qlen = 20
	}
}
local naiveproxy = {
	proxy = (server.username and server.password and server.server and server.server_port) and "https://" .. server.username .. ":" .. server.password .. "@" .. server.server .. ":" .. server.server_port,
	listen = (proto == "redir") and "redir" .. "://0.0.0.0:" .. tonumber(local_port) or "socks" .. "://0.0.0.0:" .. tonumber(local_port),
	["insecure-concurrency"] = tonumber(server.concurrency) or 1
}
local ss = {
	server = (server.kcp_enable == "1") and "127.0.0.1" or server.server,
	server_port = tonumber(server.server_port),
	local_address = "0.0.0.0",
	local_port = tonumber(local_port),
	mode = (proto == "tcp,udp") and "tcp_and_udp" or proto .. "_only",
	password = server.password,
	method = server.encrypt_method_ss,
	timeout = tonumber(server.timeout),
	fast_open = (server.fast_open == "1") and true or false,
	reuse_port = true
}
local hysteria = {
	server = (server.port_range and (server.server .. ":" .. server.port_range)) or (server.server_port and (server.server .. ":" .. server.server_port)),
	bandwidth = (server.uplink_capacity or server.downlink_capacity) and {
	up = tonumber(server.uplink_capacity) and tonumber(server.uplink_capacity) .. " mbps" or nil,
	down = tonumber(server.downlink_capacity) and tonumber(server.downlink_capacity) .. " mbps" or nil 
	},
	socks5 = (proto:find("tcp") and tonumber(socks_port) and tonumber(socks_port) ~= 0) and {
		listen = "0.0.0.0:" .. tonumber(socks_port),
		disable_udp = false
	} or nil,
	transport = (server.port_hopping == "1") and {
		type = server.transport_protocol,
		udp = { 
			hopInterval = tonumber(server.hopinterval) and tonumber(server.hopinterval) .. "s" or nil
		}
	} or nil,
--[[			
	tcpTProxy = (proto:find("tcp") and local_port ~= "0") and {
	listen = "0.0.0.0:" .. tonumber(local_port)
} or nil,
]]
	tcpRedirect = (proto:find("tcp") and local_port ~= "0") and {
					listen = "0.0.0.0:" .. tonumber(local_port)
	} or nil,
	udpTProxy = (proto:find("udp") and local_port ~= "0") and {
					listen = "0.0.0.0:" .. tonumber(local_port)
	} or nil,
	obfs = (server.flag_obfs == "1") and {
				type = server.obfs_type,
				salamander = { password = server.salamander }
	} or nil,
	quic = (server.flag_quicparam == "1" ) and {
		initStreamReceiveWindow = (server.initstreamreceivewindow and server.initstreamreceivewindow or nil),
		maxStreamReceiveWindow = (server.maxstreamseceivewindow and server.maxstreamseceivewindow or nil),
		initConnReceiveWindow = (server.initconnreceivewindow and server.initconnreceivewindow or nil),
		maxConnReceiveWindow = (server.maxconnreceivewindow and server.maxconnreceivewindow or nil),
		maxIdleTimeout = (tonumber(server.maxidletimeout) and tonumber(server.maxidletimeout) .. "s" or nil),
		keepAlivePeriod = (tonumber(server.keepaliveperiod) and tonumber(server.keepaliveperiod) .. "s" or nil),
		disable_mtu_discovery = (server.disablepathmtudiscovery == "1") and true or false
	} or nil,
	auth = server.hy2_auth,
	tls = (server.tls_host) and {
		sni = server.tls_host,
		alpn = server.tls_alpn or nil,
		--sni = server.tls_host or (server.tls_host and server.tls_alpn) or nil,
		insecure = (server.insecure == "1") and true or false,
		pinSHA256 = (server.insecure == "1") and server.pinsha256 or nil
	} or {
		sni = server.server,
		--sni = server.tls_host or (server.tls_host and server.tls_alpn) or nil,
		insecure = (server.insecure == "1") and true or false
	},
	fast_open = (server.fast_open == "1") and true or false,
	lazy = (server.lazy_mode == "1") and true or false
}
local shadowtls = {
	client = {
		server_addr = server.server_port and server.server .. ":" .. server.server_port or nil,
		listen = "127.0.0.1:" .. tonumber(local_port),
		tls_names = server.shadowtls_sni,
		password = server.password 
	},
	v3 = (server.shadowtls_protocol == "v3") and true or false,
	disable_nodelay = (server.disable_nodelay == "1") and true or false,
	fastopen = (server.fastopen == "1") and true or false,
	strict = (server.strict == "1") and true or false
}
local chain_sslocal = {
		locals = local_port ~= "0" and {
		{
			local_address = "0.0.0.0",
			local_port = (chain_local_port == "0" and tonumber(server.local_port) or tonumber(chain_local_port)),
			mode = (proto:find("tcp,udp") and "tcp_and_udp") or proto .. "_only",
			protocol = "redir",
			tcp_redir = "redirect",
			--tcp_redir = "tproxy",
			udp_redir = "tproxy"
		},
		socks_port ~= "0" and {
			protocol = "socks",
			local_address = "0.0.0.0",
			local_port = tonumber(socks_port)
		} or nil
	} or {{ 
			protocol = "socks",
			local_address = "0.0.0.0",
			ocal_port = tonumber(socks_port)
			}},
		servers = {
			{
				server = "127.0.0.1",
				server_port = (tonumber(local_port) == 0 and tonumber(chain_local_port) or tonumber(local_port)),
				method = server.sslocal_method,
				password = server.sslocal_password
			}
		}
}
local chain_vmess = {
	inbounds = (local_port ~= "0") and {
	{
		port =  (chain_local_port == "0" and tonumber(server.local_port) or tonumber(chain_local_port)),
		protocol = "dokodemo-door",
			settings = {
			network = proto, 
			followRedirect = true
		},
		streamSettings = {
			sockopt = {tproxy = "redirect"}
		},
		sniffing = {
			enable = true,
			destOverride = {"http","tls"}
		}
	},
		(proto:find("tcp") and socks_port ~= "0") and {
		protocol = "socks",
		port = tonumber(socks_port)
		} or nil
	} or { protocol = "socks",port = tonumber(socks_port) },
	outbound = {
		protocol = "vmess",
		settings = {
			vnext = {{
				address = "127.0.0.1",
				port =  (tonumber(local_port) == 0 and tonumber(chain_local_port) or tonumber(local_port)),
				users = {{
				id = (server.vmess_uuid),
				security = server.vmess_method,
				level = 0
				}}
			}}
		}
	}
}
local tuic = {
		relay = {
			server = server.server_port and server.server .. ":" .. server.server_port,
			ip = server.tuic_ip,
			uuid = server.tuic_uuid,
			password = server.tuic_passwd,
			certificates = server.certificate and { server.certpath } or nil,
			udp_relay_mode = server.udp_relay_mode,
			congestion_control = server.congestion_control,
			heartbeat = server.heartbeat and server.heartbeat .. "s" or nil,
			timeout = server.timeout and server.timeout .. "s" or nil,
			gc_interval = server.gc_interval and server.gc_interval .. "s" or nil,
			gc_lifetime = server.gc_lifetime and server.gc_lifetime .. "s" or nil,
			alpn = server.tls_alpn,
			disable_sni = (server.disable_sni == "1") and true or false,
			zero_rtt_handshake = (server.zero_rtt_handshake == "1") and true or false,
			send_window = tonumber(server.send_window),
			receive_window = tonumber(server.receive_window)
		},
		["local"] = {
			server = tonumber(socks_port) and (server.tuic_dual_stack == "1" and "[::1]:" or "127.0.0.1:")  .. (socks_port == "0" and local_port or tonumber(socks_port)),
			--username = server.tuic_socks_username,
			--password = server.tuic_socks_password,
			dual_stack = (server.tuic_dual_stack == "1") and true or false,
			max_packet_size = tonumber(server.tuic_max_package_size)
		}
}
local config = {}
function config:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end
function config:handleIndex(index)
	local switch = {
		ss = function()
			ss.protocol = socks_port
			if server.plugin and server.plugin ~= "none" then
				ss.plugin = server.plugin
				ss.plugin_opts = server.plugin_opts or nil
			end
			print(json.stringify(ss, 1))
		end,
		ssr = function()
			ss.protocol = server.protocol
			ss.protocol_param = server.protocol_param
			ss.method = server.encrypt_method
			ss.obfs = server.obfs
			ss.obfs_param = server.obfs_param
			print(json.stringify(ss, 1))
		end,
		v2ray = function()
			print(json.stringify(Xray, 1))
		end,
		trojan = function()
			print(json.stringify(trojan, 1))
		end,
		naiveproxy = function()
			print(json.stringify(naiveproxy, 1))
		end,
		hysteria = function()
			print(json.stringify(hysteria, 1))
		end,
		shadowtls = function()
			local chain_switch = {
				sslocal = function()
					if (chain:find("chain")) then
						print(json.stringify(chain_sslocal, 1))
					else
						print(json.stringify(shadowtls, 1))
					end
				end,
				vmess = function()
					if (chain:find("chain")) then
						print(json.stringify(chain_vmess, 1))
					else
						print(json.stringify(shadowtls, 1))
					end
				end
			}
			local ChainType = server.chain_type
				if chain_switch[ChainType] then
					chain_switch[ChainType]()
				end
			end,
		tuic = function()
			print(json.stringify(tuic, 1))
		end
	}
	if switch[index] then
		switch[index]()
	end
end
local f = config:new()
f:handleIndex(server.type)
