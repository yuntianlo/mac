#!/bin/sh
# randconf 公共函数 (busybox ash 兼容)

CFG=randconf

# 一个 0-255 的随机字节
# 兼容写法: 从 /dev/urandom 取字节, 仅保留 ASCII 数字后用 %256
# 不依赖 od / hexdump / xxd, 也不依赖 bash 的 $RANDOM (路由器是 busybox ash)
rand_byte() {
	local n
	n=$(head -c 256 /dev/urandom 2>/dev/null | tr -dc '0-9' | head -c 9)
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

get_opt() {
	uci -q get "$CFG.@$CFG[0].$1"
}

set_opt() {
	uci -q set "$CFG.@$CFG[0].$1=$2"
}
