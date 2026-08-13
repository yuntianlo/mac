'use strict';
'require view';
'require form';
'require uci';
'require ui';

// 读取 randconf 匿名区段里的某个键
function rc(key) {
	return uci.sections('randconf', 'randconf').then(function(s) {
		return (s && s.length) ? (s[0][key] != null ? s[0][key] : '-') : '-';
	});
}

return view.extend({
	render: function() {
		var m, s, o;

		m = new form.Map('randconf', _('路由器随机化'),
			_('WAN/LAN 随机 MAC、随机网关、随机主机名、定时无序随机、无盘模式。所有操作均通过本机脚本执行。'));

		s = m.section(form.TypedSection, 'randconf', _('基础设置'));
		o = s.option(form.Flag, 'enabled', _('启用'));
		o = s.option(form.Flag, 'boot_randomize', _('每次重启自动随机化'));
		o = s.option(form.Flag, 'timer', _('定时无序随机'));
		o = s.option(form.Value, 'timer_min', _('定时最小间隔(秒)'));
		o = s.option(form.Value, 'timer_max', _('定时最大间隔(秒)'));
		o = s.option(form.Value, 'admin_port', _('运维端口(无盘模式专用, 0=不变)'));

		s = m.section(form.TypedSection, 'randconf', _('手动指定(留空=随机)'));
		o = s.option(form.Value, 'wan_mac', _('WAN MAC'));
		o = s.option(form.Value, 'lan_mac', _('LAN MAC'));
		o = s.option(form.Value, 'lan_ip', _('LAN 网关/路由器地址'));
		o = s.option(form.Value, 'hostname', _('主机名'));

		s = m.section(form.TypedSection, 'randconf', _('操作(点击执行)'));
		o = s.option(form.Button, '_rand', _('立即随机化(无序)'));
		o.inputtitle = _('执行');
		o.onclick = function() {
			return fetch('/cgi-bin/randconf?action=randomize')
				.then(function() { return ui.showModal(_('已执行'), _('已触发随机化，网络即将重连。')); })
				.then(function() { location.reload(); });
		};

		o = s.option(form.Button, '_apply', _('应用手动指定'));
		o.inputtitle = _('执行');
		o.onclick = function() {
			return fetch('/cgi-bin/randconf?action=apply_overrides')
				.then(function() { return ui.showModal(_('已执行'), _('已应用手动指定的 MAC/网关/主机名。')); })
				.then(function() { location.reload(); });
		};

		o = s.option(form.Button, '_don', _('无盘模式：开'));
		o.inputtitle = _('执行');
		o.onclick = function() {
			return fetch('/cgi-bin/randconf?action=diskless_on')
				.then(function() { return ui.showModal(_('已执行'), _('无盘模式已开启，LAN 客户端无法访问管理页。')); })
				.then(function() { location.reload(); });
		};

		o = s.option(form.Button, '_doff', _('无盘模式：关'));
		o.inputtitle = _('执行');
		o.onclick = function() {
			return fetch('/cgi-bin/randconf?action=diskless_off')
				.then(function() { return ui.showModal(_('已执行'), _('无盘模式已关闭。')); })
				.then(function() { location.reload(); });
		};

		s = m.section(form.TypedSection, 'randconf', _('当前运行(只读)'));
		o = s.option(form.DummyValue, '_lip', _('LAN 网关'));
		o.cfgvalue = function() { return uci.get('network', 'lan', 'ipaddr') || '-'; };
		o = s.option(form.DummyValue, '_host', _('主机名'));
		o.cfgvalue = function() {
			return uci.sections('system', 'system').then(function(secs) {
				return (secs && secs.length) ? (secs[0].hostname || '-') : '-';
			});
		};
		o = s.option(form.DummyValue, '_wmac', _('WAN MAC'));
		o.cfgvalue = function() { return uci.get('network', 'wan', 'macaddr') || '-'; };
		o = s.option(form.DummyValue, '_lmac', _('LAN MAC'));
		o.cfgvalue = function() { return uci.get('network', 'lan', 'macaddr') || '-'; };
		o = s.option(form.DummyValue, '_disk', _('无盘模式'));
		o.cfgvalue = function() { return rc('diskless'); };

		return m.render();
	}
});
