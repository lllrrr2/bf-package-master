'use strict';
'require view';
'require ui';
'require form';
'require fs';
'require rpc';
'require uci';
'require tools.widgets as widgets';

//	[Widget, Option, Title, Description, {Param: 'Value'}],
var startupConf = [
	[form.Flag, 'stdout', _('Log stdout')],
	[form.Flag, 'stderr', _('Log stderr')],
	[widgets.UserSelect, 'user', _('Run daemon as user')],
	[widgets.GroupSelect, 'group', _('Run daemon as group')],
	[form.Flag, 'respawn', _('Respawn when crashed')],
	[form.DynamicList, 'env', _('Environment variable'), _('OS environments pass to frp for config file template, see <a href="https://github.com/fatedier/frp#configuration-file-template">frp README</a>'), {placeholder: 'ENV_NAME=value'}],
	[form.DynamicList, 'conf_inc', _('Additional configs'), _('Config files include in temporary config file'), {placeholder: '/etc/frp/frpc.d/frpc_full.ini'}]
];

var commonConf = [
	[form.Flag, 'enabled', _('Enable'), {rmempty: false}],
	[form.Value, 'server_addr', _('Server address'), _('ServerAddr specifies the address of the server to connect to.<br />By default, this value is "127.0.0.1".'), {datatype: 'host'}],
	[form.Value, 'server_port', _('Server port'), _('ServerPort specifies the port to connect to the server on.<br />By default, this value is 7000.'), {datatype: 'port'}],
	[form.Value, 'http_proxy', _('HTTP proxy'), _('HttpProxy specifies a proxy address to connect to the server through. If this value is "", the server will be connected to directly.<br />By default, this value is read from the "http_proxy" environment variable.')],
	[form.Value, 'log_file', _('Log file'), _('LogFile specifies a file where logs will be written to. This value will only be used if LogWay is set appropriately.<br />By default, this value is "console".')],
	[form.ListValue, 'log_level', _('Log level'), _('LogLevel specifies the minimum log level. Valid values are "trace", "debug", "info", "warn", and "error".<br />By default, this value is "info".'), {values: ['trace', 'debug', 'info', 'warn', 'error']}],
	[form.Value, 'log_max_days', _('Log max days'), _('LogMaxDays specifies the maximum number of days to store log information before deletion. This is only used if LogWay == "file".<br />By default, this value is 0.'), {datatype: 'uinteger', placeholder: '0'}],
	[form.Flag, 'disable_log_color', _('Disable log color'), _('DisableLogColor disables log colors when LogWay == "console" when set to true.'), {datatype: 'bool', default: 'false'}],
	[form.Value, 'token', _('Token'), _('Token specifies the authorization token used to create keys to be sent to the server. The server must have a matching token for authorization to succeed. <br />By default, this value is "".')],
	[form.Value, 'admin_addr', _('Admin address'), _('AdminAddr specifies the address that the admin server binds to.<br />By default, this value is "0.0.0.0".'), {datatype: 'ipaddr'}],
	[form.Value, 'admin_port', _('Admin port'), _('AdminPort specifies the port for the admin server to listen on. If this value is 0, the admin server will not be started.<br />By default, this value is 0.'), {datatype: 'port'}],
	[form.Value, 'admin_user', _('Admin user'), _('AdminUser specifies the username that the admin server will use for login.<br />By default, this value is "admin".')],
	[form.Value, 'admin_pwd', _('Admin password'), _('AdminPwd specifies the password that the admin server will use for login.<br />By default, this value is "admin".'), {password: true}],
	[form.Value, 'assets_dir', _('Assets dir'), _('AssetsDir specifies the local directory that the admin server will load resources from. If this value is "", assets will be loaded from the bundled executable using statik.<br />By default, this value is "".')],
	[form.Flag, 'tcp_mux', _('TCP mux'), _('TcpMux toggles TCP stream multiplexing. This allows multiple requests from a client to share a single TCP connection. If this value is true, the server must have TCP multiplexing enabled as well.<br />By default, this value is true.'), {datatype: 'bool', default: 'true'}],
	[form.Value, 'user', _('User'), _('User specifies a prefix for proxy names to distinguish them from other clients. If this value is not "", proxy names will automatically be changed to "{user}.{proxy_name}".<br />By default, this value is "".')],
	[form.Flag, 'login_fail_exit', _('Exit when login fail'), _('LoginFailExit controls whether or not the client should exit after a failed login attempt. If false, the client will retry until a login attempt succeeds.<br />By default, this value is true.'), {datatype: 'bool', default: 'true'}],
	[form.ListValue, 'protocol', _('Protocol'), _('Protocol specifies the protocol to use when interacting with the server. Valid values are "tcp", "kcp", "quic", "websocket", and "wss".<br />By default, this value is "tcp".'), {values: ['tcp', 'kcp', 'quic', 'websocket', 'wss']}],
	[form.Flag, 'tls_enable', _('TLS'), _('TLSEnable specifies whether or not TLS should be used when communicating with the server.'), {datatype: 'bool'}],
	[form.Value, 'heartbeat_interval', _('Heartbeat interval'), _('HeartBeatInterval specifies at what interval heartbeats are sent to the server, in seconds. It is not recommended to change this value.<br />By default, this value is 30.'), {datatype: 'uinteger', placeholder: '30'}],
	[form.Value, 'heartbeat_timeout', _('Heartbeat timeout'), _('HeartBeatTimeout specifies the maximum allowed heartbeat response delay before the connection is terminated, in seconds. It is not recommended to change this value.<br />By default, this value is 90.'), {datatype: 'uinteger', placeholder: '90'}],
	[form.DynamicList, '_', _('Additional settings'), _('This list can be used to specify some additional parameters which have not been included in this LuCI.'), {placeholder: 'Key-A=Value-A'}]
];

var quicCommonConf = [
	[form.Value, 'quic_keepalivePeriod', _('QUIC Keep-alive Period.(Unit:second)'), _('QUIC Keep-alive Period. By default this value is 10.'), {datatype: 'integer', placeholder: '10'}],
	[form.Value, 'quic_maxIdleTimeout', _('QUIC Max Idle Timeout.(Unit:second)'), _('QUIC Max Idle Timeout. By default this value is 30.'), {datatype: 'integer', placeholder: '30'}],
	[form.Value, 'quic_maxIncomingStreams', _('QUIC Max Concurrent streams'), _('QUIC Max Concurrent streams. By default this value is 100000.'), {datatype: 'integer', placeholder: '100000'}],
];

var baseProxyConf = [
	[form.Value, 'name', _('Proxy name'), undefined, {rmempty: false, optional: false}],
	[form.ListValue, 'type', _('Proxy type'), _('ProxyType specifies the type of this proxy. Valid values include "tcp", "udp", "http", "https", "stcp", and "xtcp".<br />By default, this value is "tcp".'), {values: ['tcp', 'udp', 'http', 'https', 'stcp', 'xtcp']}],
	[form.Flag, 'use_encryption', _('Encryption'), _('UseEncryption controls whether or not communication with the server will be encrypted. Encryption is done using the tokens supplied in the server and client configuration.<br />By default, this value is false.'), {datatype: 'bool'}],
	[form.Flag, 'use_compression', _('Compression'), _('UseCompression controls whether or not communication with the server will be compressed.<br />By default, this value is false.'), {datatype: 'bool'}],
	[form.Value, 'local_ip', _('Local IP'), _('LocalIp specifies the IP address or host name to proxy to.'), {datatype: 'host'}],
	[form.Value, 'local_port', _('Local port'), _('LocalPort specifies the port to proxy to.'), {datatype: 'port'}],
];

var bindInfoConf = [
	[form.Value, 'remote_port', _('Remote port'), _('If remote_port is 0, frps will assign a random port for you'), {datatype: 'port'}],
];

var versionConf = [
	[form.ListValue, 'proxyprotocolversion', _('Proxy Protocol Version'), undefined, {values: [['', _('none')], ['v1', _('V1')], ['V2', _('V2')]]}, {default: ''}],
	[form.DynamicList, '_', _('Additional settings'), _('This list can be used to specify some additional parameters which have not been included in this LuCI.'), {placeholder: 'Key-A=Value-A'}]
];

var domainConf = [
	[form.Value, 'custom_domains', _('Custom domains')],
	[form.Value, 'subdomain', _('Subdomain')],
];

var httpProxyConf = [
	[form.Value, 'locations', _('Locations')],
	[form.Value, 'http_user', _('HTTP user')],
	[form.Value, 'http_pwd', _('HTTP password')],
	[form.Value, 'host_header_rewrite', _('Host header rewrite')],
	// [form.Value, 'headers', _('Headers')], // FIXME
];

var stcpProxyConf = [
	[form.Value, 'allowUsers', _('Allow Users'), _('If left empty, only visitors under the same user are allowed to connect by default.<br />To specify particular users, separate them with commas, for example: <code>user1, user2</code>.'), {values: [['', _('Empty')], ['*', _('Allow all users')]]}],
	[form.Value, 'secretKey', _('Secret Key'), _('Used for authentication by visitors')]
];

var pluginConf = [
	[form.ListValue, 'plugin', _('Plugin'), undefined, {values: ['', 'http_proxy', 'socks5', 'unix_domain_socket'], rmempty: true}],
	[form.Value, 'plugin_http_user', _('HTTP user'), undefined, {depends: {plugin: 'http_proxy'}}],
	[form.Value, 'plugin_http_passwd', _('HTTP password'), undefined, {depends: {plugin: 'http_proxy'}}],
	[form.Value, 'plugin_user', _('SOCKS5 user'), undefined, {depends: {plugin: 'socks5'}}],
	[form.Value, 'plugin_passwd', _('SOCKS5 password'), undefined, {depends: {plugin: 'socks5'}}],
	[form.Value, 'plugin_unix_path', _('Unix domain socket path'), undefined, {depends: {plugin: 'unix_domain_socket'}, optional: false, rmempty: false,
		datatype: 'file', placeholder: '/var/run/docker.sock', default: '/var/run/docker.sock'}],
];

function setParams(o, params) {
	if (!params) return;
	for (var key in params) {
		var val = params[key];
		if (key === 'values') {
			for (var j = 0; j < val.length; j++) {
				var args = val[j];
				if (!Array.isArray(args))
					args = [args];
				o.value.apply(o, args);
			}
		} else if (key === 'depends') {
			if (!Array.isArray(val))
				val = [val];

			var deps = [];
			for (var j = 0; j < val.length; j++) {
				var d = {};
				for (var vkey in val[j])
					d[vkey] = val[j][vkey];
				for (var k = 0; k < o.deps.length; k++) {
					for (var dkey in o.deps[k]) {
						d[dkey] = o.deps[k][dkey];
					}
				}
				deps.push(d);
			}
			o.deps = deps;
		} else {
			o[key] = params[key];
		}
	}
	if (params['datatype'] === 'bool') {
		o.enabled = 'true';
		o.disabled = 'false';
	}
}

function defTabOpts(s, t, opts, params) {
	for (var i = 0; i < opts.length; i++) {
		var opt = opts[i];
		var o = s.taboption(t, opt[0], opt[1], opt[2], opt[3]);
		setParams(o, opt[4]);
		setParams(o, params);
	}
}

function defOpts(s, opts, params) {
	for (var i = 0; i < opts.length; i++) {
		var opt = opts[i];
		var o = s.option(opt[0], opt[1], opt[2], opt[3]);
		setParams(o, opt[4]);
		setParams(o, params);
	}
}

const callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});

function getVersion() {
    return fs.exec("/usr/bin/frpc", ["-v"])
        .then(function (result) {
            if (result.code === 0) {
                return result.stdout.trim(); // 提取版本号
            }
            return _("Unknown version");
        });
}

function getServiceStatus() {
	return L.resolveDefault(callServiceList('frpc'), {}).then(function (res) {
		console.log(res);
		var isRunning = false;
		try {
			isRunning = res['frpc']['instances']['instance1']['running'];
		} catch (e) { }
		return isRunning;
	});
}

function renderStatus(isRunning, port) {
	var renderHTML = "";
	var spanTemp = '<em><span style="color:%s"><strong>%s %s</strong></span></em>';

	if (isRunning) {
		var button = String.format('&#160; <a class="btn cbi-button" href="%s:%s" target="_blank" rel="noreferrer noopener">%s</a>',
			window.location.origin, port, _('Open Web Interface'));
		renderHTML += String.format(spanTemp, 'green', _("frp Client"), _("RUNNING")) + button;
	} else {
		renderHTML += String.format(spanTemp, 'red', _("frp Client"), _("NOT RUNNING"));
	}

	return renderHTML;
}

return view.extend({
	load: function() {
		return Promise.all([
			uci.load('frpc')
		]);
	},

	render: function(data) {
		let m, s, o;
		var webport = (uci.get(data[0], 'common', 'admin_port'));

		m = new form.Map('frpc', _('frp Client'));
		L.resolveDefault(getVersion()).then(function(version) {
			m.description = _("Frp is a fast reverse proxy to help you expose a local server behind a NAT or firewall to the internet,it supports TCP and UDP, as well as HTTP and HTTPS protocols.<br/>Current Version")
				+ ": <b><font style=\"color:green\">" + version + "</font></b>";
		});

		s = m.section(form.NamedSection, '_status');
		s.anonymous = true;
		s.render = function (section_id) {
			L.Poll.add(function () {
				return L.resolveDefault(getServiceStatus()).then(function(res) {
					var view = document.getElementById('service_status');
					view.innerHTML = renderStatus(res, webport);
				});
			});

			return E('div', { class: 'cbi-section', id: 'status_bar' }, [
					E('p', { id: 'service_status' }, _('Collecting data...'))
			]);
		}

		s = m.section(form.NamedSection, 'common', 'conf');
		s.dynamic = true;

		s.tab('common', _('Common Settings'));
		s.tab('init', _('Startup Settings'));

		defTabOpts(s, 'common', commonConf, {optional: true});
		defTabOpts(s, 'common', quicCommonConf, {optional: true, depends: [{protocol: 'quic'}]});

		o = s.taboption('init', form.SectionValue, 'init', form.TypedSection, 'init', _('Startup Settings'));
		s = o.subsection;
		s.anonymous = true;
		s.dynamic = true;

		defOpts(s, startupConf);

		s = m.section(form.GridSection, 'conf', _('Proxy Settings'));
		s.anonymous = true;
		s.addremove = true;
		s.sortable = true;
		s.addbtntitle = _('Add new proxy...');

		s.filter = function(s) { return s !== 'common'; };

		s.tab('general', _('General Settings'));
		s.tab('http', _('HTTP Settings'));
		s.tab('plugin', _('Plugin Settings'));

		s.option(form.Value, 'name', _('Proxy name')).modalonly = false;
		s.option(form.Value, 'type', _('Proxy type')).modalonly = false;
		s.option(form.Value, 'local_ip', _('Local IP')).modalonly = false;
		s.option(form.Value, 'local_port', _('Local port')).modalonly = false;
		o = s.option(form.Value, 'remote_port', _('Remote port'));
		o.modalonly = false;
		o.depends('type', 'tcp');
		o.depends('type', 'udp');
		o.cfgvalue = function() {
			var v = this.super('cfgvalue', arguments);
			return v&&v!='0'?v:'#';
		};

		defTabOpts(s, 'general', baseProxyConf, {modalonly: true});

		// TCP and UDP
		defTabOpts(s, 'general', bindInfoConf, {optional: true, modalonly: true, depends: [{type: 'tcp'}, {type: 'udp'}]});

		// VERSION
		defTabOpts(s, 'general', versionConf, {optional: true, modalonly: true});

		// HTTP and HTTPS
		defTabOpts(s, 'http', domainConf, {optional: true, modalonly: true, depends: [{type: 'http'}, {type: 'https'}]});

		// HTTP
		defTabOpts(s, 'http', httpProxyConf, {optional: true, modalonly: true, depends: {type: 'http'}});

		// STCP and XTCP
		defTabOpts(s, 'general', stcpProxyConf, {modalonly: true, depends: [{type: 'stcp'}, {type: 'xtcp'}]});

		// Plugin
		defTabOpts(s, 'plugin', pluginConf, {modalonly: true});

		return m.render();
	}
});
