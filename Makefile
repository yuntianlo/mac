include $(TOPDIR)/rules.mk

PKG_NAME:=randconf
PKG_VERSION:=1.0
PKG_RELEASE:=2

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/randconf
  SECTION:=net
  CATEGORY:=Network
  TITLE:=路由器随机化工具 (MAC/网关/主机名)
  PKGARCH:=all
  DEPENDS:=+uhttpd +luci-base
endef

define Package/randconf/description
E8820S (MT7621) ImmortalWrt 随机化工具:
 - WAN/LAN 随机 MAC
 - LAN 网段/网关/路由器地址随机
 - 每次重启自动修改
 - 路由器名称随机
 - 定时无序 + 手动无序随机
 - 手动指定任意 MAC/网关
 - 无盘模式: 保持 LAN 网关、不影响 DHCP、屏蔽 LAN 进管理页
endef

define Package/randconf/conffiles
/etc/config/randconf
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Compile
endef

define Package/randconf/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/etc/config/randconf $(1)/etc/config/randconf
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/randconf $(1)/etc/init.d/randconf
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/99_randconf $(1)/etc/uci-defaults/99_randconf
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/usr/bin/randconf $(1)/usr/bin/randconf
	$(INSTALL_BIN) ./files/usr/bin/randconf-timer $(1)/usr/bin/randconf-timer
	$(INSTALL_DIR) $(1)/usr/lib/randconf
	$(INSTALL_DATA) ./files/usr/lib/randconf/common.sh $(1)/usr/lib/randconf/common.sh
	$(INSTALL_DIR) $(1)/www/cgi-bin
	$(INSTALL_BIN) ./files/www/cgi-bin/randconf $(1)/www/cgi-bin/randconf
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/randconf
	$(INSTALL_DATA) ./files/www/luci-static/resources/view/randconf/randconf.js $(1)/www/luci-static/resources/view/randconf/randconf.js
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./files/usr/share/luci/menu.d/randconf.json $(1)/usr/share/luci/menu.d/randconf.json
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./files/usr/share/rpcd/acl.d/randconf.json $(1)/usr/share/rpcd/acl.d/randconf.json
endef

$(eval $(call BuildPackage,randconf))
