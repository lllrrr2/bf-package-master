# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=simple-torrent
PKG_VERSION:=1.3.9
PKG_RELEASE:=$(AUTORELEASE)

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/boypt/simple-torrent/tar.gz/$(PKG_VERSION)?
PKG_HASH:=3bdc4df30d04e4e94c04961bd001b7e7e4182bf171475d68de1560c3af1dc7bf

PKG_LICENSE:=AGPL-3.0
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

PKG_CONFIG_DEPENDS:= \
	CONFIG_SIMPLE_TORRENT_COMPRESS_GOPROXY \
	CONFIG_SIMPLE_TORRENT_COMPRESS_UPX

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
# PKG_USE_MIPS16:=0
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=github.com/boypt/simple-torrent
GO_PKG_LDFLAGS:=-s -w
GO_PKG_LDFLAGS_X:=main.VERSION=$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/simple-torrent
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=BitTorrent
  TITLE:=A self-hosted remote torrent client
  URL:=https://github.com/boypt/simple-torrent
  DEPENDS:=$(GO_ARCH_DEPENDS) +ca-bundle +libstdcpp
endef

define Package/simple-torrent/description
  SimpleTorrent is a a self-hosted remote torrent client, written in Go (golang).
  Started torrents remotely, download sets of files on the local disk of the server,
  which are then retrievable or streamable via HTTP.
endef

define Package/simple-torrent/config
config SIMPLE_TORRENT_COMPRESS_GOPROXY
	bool "Compiling with GOPROXY proxy"
	default n

config SIMPLE_TORRENT_COMPRESS_UPX
	bool "Compress executable files with UPX"
	depends on !mips64
	default y if mips||mipsel
endef

ifeq ($(CONFIG_SIMPLE_TORRENT_COMPRESS_GOPROXY),y)
	export GO111MODULE=on
	export GOPROXY=https://goproxy.baidu.com
endif

define Build/Compile
	$(call GoPackage/Build/Compile)
ifeq ($(CONFIG_SIMPLE_TORRENT_COMPRESS_UPX),y)
	$(STAGING_DIR_HOST)/bin/upx --lzma --best $(GO_PKG_BUILD_BIN_DIR)/simple-torrent
endif
endef

$(eval $(call GoBinPackage,simple-torrent))
$(eval $(call BuildPackage,simple-torrent))
