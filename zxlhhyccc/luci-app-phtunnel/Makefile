#-- Copyright (C) 2018 hefeng <a520ass@hotmail.com>

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Support for the PHTunnel
LUCI_DEPENDS:=+cgi-io +curl +luci-compat +luci-lib-json +phtunnel
LUCI_PKGARCH:=all
PKG_VERSION:=1.0
PKG_RELEASE:=3

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
