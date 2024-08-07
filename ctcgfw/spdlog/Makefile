####
 #  File: /spdlog/Makefile
 #  Project: ootoc-OpenWRT
 #  File Created: Thursday, 12th March 2020 11:09:54 pm
 #  Author: ElonH[EH](elonhhuang@gmail.com)
 #  License: GNU General Public License v3.0 or later(http://www.gnu.org/licenses/gpl-3.0-standalone.html)
 #  Copyright (C) 2020 [ElonH]
####

include $(TOPDIR)/rules.mk

PKG_NAME:=spdlog
PKG_VERSION:=1.12.0
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=https://github.com/gabime/spdlog.git
PKG_SOURCE_VERSION:=c1569a3d293a6b511ecb9c18b2298826c9578d9f
PKG_MIRROR_HASH:=51b55881dd6f2676225fe462e9f9880aae5518ff3f58602e96a4c8edb8b1280e

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz

PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=ElonH <elonhhuang@gmail.com>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

PKG_INSTALL:=1
PKG_USE_MIPS16:=0
PKG_BUILD_FLAGS:=no-mips16
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

CMAKE_OPTIONS+= -DSPDLOG_BUILD_EXAMPLE:BOOL=OFF \
	-DSPDLOG_BUILD_TESTS:BOOL=OFF -DSPDLOG_BUILD_SHARED:BOOL=ON \
	-DSPDLOG_FMT_EXTERNAL:BOOL=ON -DSPDLOG_FMT_EXTERNAL_HO:BOOL=OFF

define Package/spdlog
	SECTION:=lib
	CATEGORY:=Libraries
	URL:=https://github.com/gabime/spdlog
	TITLE:=Fast C++ logging library.
	DEPENDS:=+libfmt
	MENU:=1
endef

define Package/spdlog/description
	Very fast, header-only/compiled, C++ logging library.
endef


define Build/InstallDev
	$(INSTALL_DIR) $(PKG_INSTALL_DIR)/usr/include/spdlog/fmt/bundled
	$(CP) $(PKG_BUILD_DIR)/include/spdlog/fmt/bundled $(PKG_INSTALL_DIR)/usr/include/spdlog/fmt
	$(Build/InstallDev/cmake)
endef

define Package/spdlog/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libspdlog.so* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,spdlog))
