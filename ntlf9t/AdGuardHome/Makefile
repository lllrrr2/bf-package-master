#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=AdGuardHome
PKG_VERSION:=0.107.57
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/AdguardTeam/AdGuardHome/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=9df951486dab0e83485b596c0393f91d4ff2994de26101b43af8344efb7c1536
PKG_BUILD_DIR:=$(BUILD_DIR)/AdGuardHome-$(PKG_VERSION)

PKG_LICENSE:=GPL-3.0-only
PKG_LICENSE_FILES:=LICENSE.txt
PKG_MAINTAINER:=Dobroslaw Kijowski <dobo90@gmail.com>

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

PKG_CONFIG_DEPENDS:= \
	CONFIG_ADGUARDHOME_COMPRESS_GOPROXY \
	CONFIG_ADGUARDHOME_COMPRESS_UPX

GO_PKG:=github.com/AdguardTeam/AdGuardHome
GO_PKG_BUILD_PKG:=$(GO_PKG)

AGH_BUILD_TIME:=$(shell date -d @$(SOURCE_DATE_EPOCH) +%FT%TZ%z)
GO_PKG_LDFLAGS:=-s -w
GO_PKG_LDFLAGS_X:= \
	$(GO_PKG)/internal/version.channel=release \
	$(GO_PKG)/internal/version.version=v$(PKG_VERSION) \
	$(GO_PKG)/internal/version.buildtime=$(AGH_BUILD_TIME) \
	$(GO_PKG)/internal/version.goarm=$(GO_ARM) \
	$(GO_PKG)/internal/version.gomips=$(GO_MIPS)

ifneq ($(findstring $(ARCH),mips mipsel),)
	ADG_CONF_NAME:=small_flash
else
	ADG_CONF_NAME:=big_space
endif

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/AdGuardHome
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Network-wide ads and trackers blocking DNS server
  URL:=https://github.com/AdguardTeam/AdGuardHome
  DEPENDS:=$(GO_ARCH_DEPENDS) +ca-bundle
endef

define Package/AdGuardHome/conffiles
/etc/AdGuardHome/AdGuardHome.yaml
endef

define Package/AdGuardHome/description
  Free and open source, powerful network-wide ads and trackers blocking DNS server.
endef

define Package/AdGuardHome/config
config ADGUARDHOME_COMPRESS_GOPROXY
	bool "Compiling with GOPROXY proxy"
	default n

config ADGUARDHOME_COMPRESS_UPX
	bool "Compress executable files with UPX"
	depends on !mips64
	default n
endef

ifeq ($(CONFIG_ADGUARDHOME_COMPRESS_GOPROXY),y)
export GO111MODULE=on
export GOPROXY=https://goproxy.cn
endif

FRONTEND_FILE:=$(PKG_NAME)-frontend-$(PKG_VERSION).tar.gz
define Download/AdGuardHome-frontend
	URL:=https://github.com/AdguardTeam/AdGuardHome/releases/download/v$(PKG_VERSION)/
	URL_FILE:=AdGuardHome_frontend.tar.gz
	FILE:=$(FRONTEND_FILE)
	HASH:=fc0b57d80dece4219bfba833b48122ffe7a140ee2026cd3cf4c7181ccdcf8c9e
endef

define Build/Prepare
	$(call Build/Prepare/Default)

	gzip -dc $(DL_DIR)/$(FRONTEND_FILE) | $(HOST_TAR) -C $(PKG_BUILD_DIR)/ $(TAR_OPTIONS)
endef

define Build/Compile
	$(call GoPackage/Build/Compile)
ifeq ($(CONFIG_ADGUARDHOME_COMPRESS_UPX),y)
	$(STAGING_DIR_HOST)/bin/upx --lzma --best $(GO_PKG_BUILD_BIN_DIR)/AdGuardHome
endif
endef

define Package/AdGuardHome/install
	$(call GoPackage/Package/Install/Bin,$(1))
	$(INSTALL_DIR) $(1)/etc/AdGuardHome

	$(INSTALL_CONF) ./conf/$(ADG_CONF_NAME).yaml $(1)/etc/AdGuardHome/AdGuardHome.yaml
endef

$(eval $(call Download,AdGuardHome-frontend))
$(eval $(call GoBinPackage,AdGuardHome))
$(eval $(call BuildPackage,AdGuardHome))
