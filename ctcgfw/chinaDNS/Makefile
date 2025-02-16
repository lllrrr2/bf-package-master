# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2014-2018 Jian Chang <aa65535@live.com>
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=ChinaDNS
PKG_VERSION:=2.0.1
PKG_RELEASE:=$(AUTORELESE)

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/lrinQVQ/openwrt-chinadns/releases/download/v$(PKG_VERSION)
PKG_MD5SUM:=5c7aa6a89a969a1dd6469b4808b0759b

PKG_LICENSE:=GPL-3.0-only
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Jian Chang <aa65535@live.com>

PKG_FIXUP:=autoreconf
PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/ChinaDNS
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=IP Addresses and Names
  TITLE:=Protect yourself against DNS poisoning in China.
  URL:=https://github.com/shadowsocks/ChinaDNS
endef

define Package/ChinaDNS/conffiles
	/etc/config/chinadns
	/etc/chinadns_chnroute.txt
endef

define Package/ChinaDNS/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/chinadns.init $(1)/etc/init.d/chinadns
	$(INSTALL_CONF) $(PKG_INSTALL_DIR)/usr/share/chnroute.txt $(1)/etc/chinadns_chnroute.txt
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/chinadns.config $(1)/etc/config/chinadns
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/chinadns $(1)/usr/bin
endef

$(eval $(call BuildPackage,ChinaDNS))
