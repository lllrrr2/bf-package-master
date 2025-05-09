include $(TOPDIR)/rules.mk

PKG_NAME:=filerun
PKG_VERSION:=2021_06_27
PKG_RELEASE:=20210628

PKG_FILE:=$(PKG_NAME)-$(PKG_VERSION).zip
PKG_URL:=https://www.filerun.com/download-latest
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_HASH:=skip
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_MAINTAINER:=GaryPang <https://github.com/garypang13/openwrt-filerun>

include $(INCLUDE_DIR)/package.mk

define Package/filerun
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Filerun
	PKGARCH:=all
	DEPENDS:=@x86_64 +luci-ssl-nginx +php8 +php8-mod-filter +php8-fpm +php8-mod-ctype +php8-mod-dom +php8-mod-fileinfo +php8-mod-session +php8-mod-curl +php8-mod-gd \
	+php8-mod-mbstring +php8-mod-opcache +php8-mod-sockets +php8-mod-pdo-mysql +php8-mod-mysqli +php8-mod-exif +php8-mod-xml \
	+php8-mod-openssl +php8-mod-zip +mariadb-server-base +mariadb-server +mariadb-client \
	+@BUILD_PATENTED +ffmpeg +libx264 +imagemagick
endef

define Package/filerun/conffiles
/etc/config/filerun
/etc/nginx/conf.d/filerun.conf
/etc/php8/custom.ini
/etc/mysql/conf.d/custom.cnf	
endef

define Build/Prepare
	if [ ! -f $(DL_DIR)/$(PKG_FILE) ] ; then \
		curl -f --connect-timeout 20 --retry 5 --location --insecure $(PKG_URL) -o $(DL_DIR)/$(PKG_FILE); \
	fi
	rm -r $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)
	unzip $(DL_DIR)/$(PKG_FILE) -d $(PKG_BUILD_DIR)
endef

define Build/Compile
endef

define Package/filerun/extra_provides
    echo 'libc.so.6'; \
    echo 'librt.so.1';
endef

define Package/filerun/install
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d $(1)/etc/nginx/conf.d $(1)/etc/php8 $(1)/etc/mysql/conf.d
	$(INSTALL_CONF) ./files/filerun.config $(1)/etc/config/filerun
	$(INSTALL_BIN) ./files/filerun.init $(1)/etc/init.d/filerun
	$(INSTALL_DATA) ./files/filerun_nginx.conf $(1)/etc/nginx/conf.d/filerun.conf
	$(INSTALL_DATA) ./files/custom_php.ini $(1)/etc/php8/custom.ini
	$(INSTALL_DATA) ./files/custom_mysql.ini $(1)/etc/mysql/conf.d/custom.cnf
	$(INSTALL_DIR) $(1)/www/filerun
	$(CP) \
		$(PKG_BUILD_DIR)/{a,cron,css,customizables,images,js,logout,oauth2,ocs,oembed,panel,sounds,sso,system,weblinks,wl} \
		$(PKG_BUILD_DIR)/{api.php,dav.php,favicon.ico,guest.php,index.php,initial_version.txt,recommended.web.config,remote.php,status.php,t.php} \
		$(1)/www/filerun
	find $(1)/www/filerun -type d -exec chmod +x {} \;
endef

$(eval $(call BuildPackage,filerun))
