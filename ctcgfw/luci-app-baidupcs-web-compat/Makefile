#
# <https://github.com/KFERMercer/luci-app-baidupcs-web>
# 
# Copyright (C) 2020 KFERMercer <KFER.Mercer@gmail.com>
# Copyright (C) 2021 ImmortalWrt
# 
# THIS IS FREE SOFTWARE, LICENSED UNDER GPLv3.
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for BaiduPCS-Go
LUCI_DEPENDS:=+baidupcs-web +wget-ssl +openssl-util
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-baidupcs-web-compat
PKG_VERSION:=1.0
PKG_RELEASE:=5

PKG_MAINTAINER:=KFERMercer <KFER.Mercer@gmail.com>

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
