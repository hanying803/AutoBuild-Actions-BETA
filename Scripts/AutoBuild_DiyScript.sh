#!/bin/bash
# AutoBuild Module by Hyy2001 <https://github.com/Hyy2001X/AutoBuild-Actions-BETA>
# AutoBuild DiyScript

Firmware_Diy_Core() {

	Author=AUTO
	# 作者名称, AUTO: [自动识别]
	Author_URL=AUTO
	# 自定义作者网站或域名, AUTO: [自动识别]
	Default_Flag=AUTO
	# 固件标签 (名称后缀), 适用不同配置文件, AUTO: [自动识别]
	Default_IP="192.168.1.1"
	# 固件 IP 地址
	Default_Title="Powered by AutoBuild-Actions"
	# 固件终端首页显示的额外信息
	
	Short_Fw_Date=true
	# 简短的固件日期, true: [20210601]; false: [202106012359]
	x86_Full_Images=false
	# 额外上传已检测到的 x86 虚拟磁盘镜像, true: [上传]; false: [不上传]
	Fw_MFormat=AUTO
	# 自定义固件格式, AUTO: [自动识别]
	Regex_Skip="packages|buildinfo|sha256sums|manifest|kernel|rootfs|factory|itb|profile|ext4|json"
	# 输出固件时丢弃包含该内容的固件/文件
	AutoBuild_Features=true
	# 添加 AutoBuild 固件特性, true: [开启]; false: [关闭]
	
	AutoBuild_Features_Patch=false
	AutoBuild_Features_Kconfig=false
}

Firmware_Diy() {

	# 请在该函数内定制固件

	# 可用预设变量, 其他可用变量请参考运行日志
	# ${OP_AUTHOR}			OpenWrt 源码作者
	# ${OP_REPO}				OpenWrt 仓库名称
	# ${OP_BRANCH}			OpenWrt 源码分支
	# ${TARGET_PROFILE}		设备名称
	# ${TARGET_BOARD}			设备架构
	# ${TARGET_FLAG}			固件名称后缀

	# ${WORK}				OpenWrt 源码位置
	# ${CONFIG_FILE}			使用的配置文件名称
	# ${FEEDS_CONF}			OpenWrt 源码目录下的 feeds.conf.default 文件
	# ${CustomFiles}			仓库中的 /CustomFiles 绝对路径
	# ${Scripts}				仓库中的 /Scripts 绝对路径
	# ${FEEDS_LUCI}			OpenWrt 源码目录下的 package/feeds/luci 目录
	# ${FEEDS_PKG}			OpenWrt 源码目录下的 package/feeds/packages 目录
	# ${BASE_FILES}			OpenWrt 源码目录下的 package/base-files/files 目录

	case "${OP_AUTHOR}/${OP_REPO}:${OP_BRANCH}" in
	coolsnowwolf/lede:master)
		cat >> ${Version_File} <<EOF
sed -i '/check_signature/d' /etc/opkg.conf
if [ -z "\$(grep "REDIRECT --to-ports 53" /etc/firewall.user 2> /dev/null)" ]
then
	echo '# iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user
	echo '# iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user
	echo '# [ -n "\$(command -v ip6tables)" ] && ip6tables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user
	echo '# [ -n "\$(command -v ip6tables)" ] && ip6tables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user
fi
exit 0
EOF
		# sed -i "s?/bin/login?/usr/libexec/login.sh?g" ${FEEDS_PKG}/ttyd/files/ttyd.config
		# sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
		# sed -i '/uci commit luci/i\uci set luci.main.mediaurlbase="/luci-static/argon-mod"' $(PKG_Finder d package default-settings)/files/zzz-default-settings

		rm -r ${FEEDS_LUCI}/luci-theme-argon*
		AddPackage git themes luci-theme-argon jerrykuku 18.06
		AddPackage git other OpenClash vernesong dev
		AddPackage git other luci-app-argon-config jerrykuku master
		AddPackage git other helloworld fw876 main
		AddPackage git themes luci-theme-neobird thinktip main
		svn co https://github.com/immortalwrt/luci/branches/openwrt-18.06-k5.4/themes/luci-theme-bootstrap-mod ${FEEDS_LUCI}/luci-theme-bootstrap-mod
		
		case "${TARGET_BOARD}" in
		ramips)
			sed -i "/DEVICE_COMPAT_VERSION := 1.1/d" target/linux/ramips/image/mt7621.mk
			Copy ${CustomFiles}/Depends/automount $(PKG_Finder d "package" automount)/files 15-automount
		;;
		esac

		case "${TARGET_PROFILE}" in
		d-team_newifi-d2)
			Copy ${CustomFiles}/${TARGET_PROFILE}_system ${BASE_FILES}/etc/config system
		;;
		x86_64)
			Copy ${CustomFiles}/Depends/cpuset ${BASE_FILES}/bin
			AddPackage git passwall-depends openwrt-passwall-packages xiaorouji main
			AddPackage git passwall-luci openwrt-passwall xiaorouji main
			AddPackage git passwall2-luci openwrt-passwall2 xiaorouji main
			#rm -rf packages/lean/autocore
			#AddPackage git lean autocore-modify Hyy2001X master
			sed -i -- 's:/bin/ash:'/bin/bash':g' ${BASE_FILES}/etc/passwd

			singbox_version="1.7.2"
			hysteria_version="2.2.3"
			naiveproxy_version="119.0.6045.66-1"

			wget --quiet --no-check-certificate -P /tmp \
				https://github.com/SagerNet/sing-box/releases/download/v${singbox_version}/sing-box-${singbox_version}-linux-amd64.tar.gz
			wget --quiet --no-check-certificate -P /tmp \
				https://github.com/apernet/hysteria/releases/download/app%2Fv${hysteria_version}/hysteria-linux-amd64
			wget --quiet --no-check-certificate -P /tmp \
				https://github.com/klzgrad/naiveproxy/releases/download/v${naiveproxy_version}/naiveproxy-v${naiveproxy_version}-openwrt-x86_64.tar.xz
			wget --quiet --no-check-certificate -P /tmp \
				https://raw.githubusercontent.com/vernesong/OpenClash/core/master/dev/clash-linux-amd64.tar.gz

			tar -xvzf /tmp/sing-box-${singbox_version}-linux-amd64.tar.gz -C /tmp
			Copy /tmp/sing-box-${singbox_version}-linux-amd64/sing-box ${BASE_FILES}/usr/bin

			Copy /tmp/hysteria-linux-amd64 ${BASE_FILES}/usr/bin hysteria

			tar -xvf /tmp/naiveproxy-v${naiveproxy_version}-openwrt-x86_64.tar.xz -C /tmp
			Copy /tmp/naiveproxy-v${naiveproxy_version}-openwrt-x86_64/naive ${BASE_FILES}/usr/bin

			tar -xvzf /tmp/clash-linux-amd64.tar.gz -C /tmp
			Copy /tmp/clash ${BASE_FILES}/etc/openclash/core

			chmod 777 ${BASE_FILES}/usr/bin/sing-box ${BASE_FILES}/usr/bin/hysteria ${BASE_FILES}/usr/bin/naive ${BASE_FILES}/etc/openclash/core

			# ReleaseDL https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest geosite.dat ${BASE_FILES}/usr/v2ray
			# ReleaseDL https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest geoip.dat ${BASE_FILES}/usr/v2ray
		;;
		xiaomi_redmi-router-ax6s)
			AddPackage git passwall-depends openwrt-passwall-packages xiaorouji main
			AddPackage git passwall-luci openwrt-passwall xiaorouji main
		;;
		esac
	;;
	immortalwrt/immortalwrt*)
		case "${TARGET_PROFILE}" in
		x86_64)
			AddPackage git passwall2-luci openwrt-passwall2 xiaorouji main
		;;
		esac
		# sed -i "s?/bin/login?/usr/libexec/login.sh?g" ${FEEDS_PKG}/ttyd/files/ttyd.config
	;;
	esac
}
