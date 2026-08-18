#!/bin/sh
# randconf 公共函数 (busybox ash 兼容)

CFG=randconf

# 一个 0-255 的随机字节
# 兼容写法: 从 /dev/urandom 取字节, 仅保留 ASCII 数字后用 %256
# 不依赖 od / hexdump / xxd, 也不依赖 bash 的 $RANDOM (路由器是 busybox ash)
rand_byte() {
	local n
	n=$(head -c 256 /dev/urandom 2>/dev/null | tr -dc '0-9' | head -c 9)
	# 去前导零: 数字串以 08/09 开头时 busybox ash 会按八进制解析直接报错
	n=$(printf '%s' "$n" | sed 's/^0*//')
	[ -z "$n" ] && n=0
	echo $(( n % 256 ))
}

# 生成本地管理位(第2位=1) + 单播位(第1位=0) 的随机 MAC
gen_mac() {
	local o1=$(( ($(rand_byte) & 0xFC) | 0x02 ))
	printf '%02x:%02x:%02x:%02x:%02x:%02x' \
		"$o1" "$(rand_byte)" "$(rand_byte)" "$(rand_byte)" "$(rand_byte)" "$(rand_byte)"
}

valid_mac() {
	echo "$1" | grep -qiE '^([0-9a-f]{2}:){5}[0-9a-f]{2}$'
}

valid_ip() {
	echo "$1" | grep -qiE '^([0-9]{1,3}\.){3}[0-9]{1,3}$'
}

# 生成 192.168.A.B  A:2-254  B:2-99 (避开 DHCP 分配段 100-199)
gen_lan_ip() {
	local a=$(( ($(rand_byte) % 253) + 2 ))
	local b=$(( ($(rand_byte) % 98) + 2 ))
	printf '192.168.%d.%d' "$a" "$b"
}

random_hostname() {
	printf 'RTR-%02X%02X%02X%02X' "$(rand_byte)" "$(rand_byte)" "$(rand_byte)" "$(rand_byte)"
}

# 把 MAC 写入指定接口对应的 device 段 (现代 OpenWrt 的正确方式)
# 解析 interface 的 device 名(如 br-lan / wan), 找到或新建该 device 段并设置 macaddr
	set_iface_mac() {
	local iface="$1" mac="$2" dev section
	[ -z "$iface" ] && return 1
	dev=$(uci -q get "network.${iface}.device")
	[ -z "$dev" ] && dev="$iface"
	section=$(uci show network 2>/dev/null | grep "\.name='${dev}'" | head -n1 | cut -d. -f1-2)
	if [ -z "$section" ]; then
		# 新建 device 段: 根据设备名推测类型 (br-lan=bridge, 其它=物理接口)
		section="network.$(uci add network device)"
		uci set "${section}.name=${dev}"
		case "$dev" in
			br-*) uci set "${section}.type='bridge'" ;;
			*)    uci set "${section}.type=''";;
		esac
	fi
	uci set "${section}.macaddr=${mac}"
}

# 读取接口当前运行中的 MAC (从 /sys/class/net 取真实值)
iface_mac() {
	local dev
	dev=$(uci -q get "network.$1.device")
	[ -z "$dev" ] && dev="$1"
	cat "/sys/class/net/${dev}/address" 2>/dev/null
}

get_opt() {
	uci -q get "$CFG.@$CFG[0].$1"
}

set_opt() {
	uci -q set "$CFG.@$CFG[0].$1=$2"
}
