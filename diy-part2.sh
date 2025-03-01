#!/bin/bash

del_data="
feeds/luci/applications/luci-app-wechatpush
feeds/luci/applications/luci-app-serverchan
feeds/packages/net/brook
feeds/packages/net/dns2socks
feeds/packages/net/microsocks
feeds/packages/net/pdnsd-alt
feeds/packages/net/naiveproxy
feeds/packages/net/shadowsocks-rust
feeds/packages/net/shadowsocksr-libev
feeds/packages/net/simple-obfs
feeds/packages/net/sing-box
feeds/packages/net/tcping
feeds/packages/net/trojan
feeds/packages/net/trojan-go
feeds/packages/net/trojan-plus
feeds/packages/net/v2ray-core
feeds/packages/net/v2ray-plugin
feeds/packages/net/xray-plugin
feeds/packages/net/chinadns-ng
feeds/packages/net/dns2tcp
feeds/packages/net/tcping
feeds/packages/net/hysteria
feeds/packages/net/tuic-client
feeds/packages/net/ipt2socks
feeds/packages/net/xray-core
feeds/packages/net/cdnspeedtest
feeds/packages/lang/golang
feeds/packages/lang/rust
feeds/packages/devel/gn
target/linux/mediatek/patches-5.4/0504-macsec-revert-async-support.patch
target/linux/mediatek/patches-5.4/0005-dts-mt7622-add-gsw.patch
target/linux/mediatek/patches-5.4/0993-arm64-dts-mediatek-Split-PCIe-node-for-MT2712-MT7622.patch
target/linux/mediatek/patches-5.4/1024-pcie-add-multi-MSI-support.patch
"

for data in ${del_data};
do
    if [[ -d ${data} || -f ${data} ]];then
        rm -rf ${data}
        echo "Deleted ${data}"
    fi
done

cp -rf tmp/packages/lang/rust feeds/packages/lang/

# golang
git clone --depth 1 --single-branch https://github.com/sbwml/packages_lang_golang -b 23.x feeds/packages/lang/golang

# frp
FRP_VER=$(curl -sL https://api.github.com/repos/fatedier/frp/releases/latest | jq -r .name | sed 's/v//g')
curl -sL -o /tmp/frp-${FRP_VER}.tar.gz https://codeload.github.com/fatedier/frp/tar.gz/v${FRP_VER}
FRP_PKG_SHA=$(sha256sum /tmp/frp-${FRP_VER}.tar.gz | awk '{print $1}')
rm -rf /tmp/frp-${FRP_VER}.tar.gz

sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='${FRP_VER}'/g' feeds/packages/net/frp/Makefile
sed -i 's/PKG_HASH:=.*/PKG_HASH:='${FRP_PKG_SHA}'/g' feeds/packages/net/frp/Makefile
sed -i 's/\$(2)_full.ini/legacy\/\$(2)_legacy_full.ini/g' feeds/packages/net/frp/Makefile

# iptables
IMS=$(grep "iptables-mod-socket" package/network/utils/iptables/Makefile)
if [ -z "${IMS}" ];then
	echo "Add iptables-mod-socket"
    echo -e "\ndefine Package/iptables-mod-socket\n\$(call Package/iptables/Module, +kmod-ipt-socket)\n  TITLE:=Socket match iptables extensions\nendef\n\ndefine Package/iptables-mod-socket/description\nSocket match iptables extensions.\n\n Matches:\n  - socket\n\nendef\n\n\$(eval \$(call BuildPlugin,iptables-mod-socket,\$(IPT_SOCKET-m)))" >> package/network/utils/iptables/Makefile
fi

# netfilter.mk
IS=$(grep "ipt-socket" package/kernel/linux/modules/netfilter.mk)
NS=$(grep "nf-socket" package/kernel/linux/modules/netfilter.mk)
if [ -z "${IS}" ];then
	echo "Add ipt-socket"
    echo -e "\ndefine KernelPackage/ipt-socket\n  TITLE:=Iptables socket matching support\n  DEPENDS+=+kmod-nf-socket +kmod-nf-conntrack\n  KCONFIG:=\$(KCONFIG_IPT_SOCKET)\n  FILES:=\$(foreach mod,\$(IPT_SOCKET-m),\$(LINUX_DIR)/net/\$(mod).ko)\n  AUTOLOAD:=\$(call AutoProbe,\$(notdir \$(IPT_SOCKET-m)))\n  \$(call AddDepends/ipt)\nendef\n\ndefine KernelPackage/ipt-socket/description\n  Kernel modules for socket matching\nendef\n\n\$(eval \$(call KernelPackage,ipt-socket))" >> package/kernel/linux/modules/netfilter.mk
fi
if [ -z "${NS}" ];then
	echo "Add nf-socket"
    echo -e "\ndefine KernelPackage/nf-socket\n  SUBMENU:=\$(NF_MENU)\n  TITLE:=Netfilter socket lookup support\n  KCONFIG:= \$(KCONFIG_NF_SOCKET)\n  FILES:=\$(foreach mod,\$(NF_SOCKET-m),\$(LINUX_DIR)/net/\$(mod).ko)\n  AUTOLOAD:=\$(call AutoProbe,\$(notdir \$(NF_SOCKET-m)))\nendef\n\n\$(eval \$(call KernelPackage,nf-socket))" >> package/kernel/linux/modules/netfilter.mk
fi

# ssh
sed -i '/sed -r -i/a\\tsed -i "s,#Port 22,Port 22,g" $(1)\/etc\/ssh\/sshd_config\n\tsed -i "s,#ListenAddress 0.0.0.0,ListenAddress 0.0.0.0,g" $(1)\/etc\/ssh\/sshd_config\n\tsed -i "s,#PermitRootLogin prohibit-password,PermitRootLogin yes,g" $(1)\/etc\/ssh\/sshd_config' feeds/packages/net/openssh/Makefile

# vlmcsd
VLMCSD_JSON=$(curl -sL https://api.github.com/repos/Wind4/vlmcsd/commits)
VLMCSD_SHA=$(echo ${VLMCSD_JSON} | jq -r .[0].sha)

curl -sL -o /tmp/vlmcsd-${VLMCSD_SHA}.tar.gz https://codeload.github.com/Wind4/vlmcsd/tar.gz/${VLMCSD_SHA}
VLMCSD_PKG_SHA=$(sha256sum /tmp/vlmcsd-${VLMCSD_SHA}.tar.gz | awk '{print $1}')
rm -rf /tmp/vlmcsd-${VLMCSD_SHA}.tar.gz

sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='${VLMCSD_SHA}'/g' feeds/packages/net/vlmcsd/Makefile
sed -i 's/PKG_RELEASE:=3/PKG_RELEASE:=1/g' feeds/packages/net/vlmcsd/Makefile
sed -i 's/PKG_HASH:=.*/PKG_HASH:='${VLMCSD_PKG_SHA}'/g' feeds/packages/net/vlmcsd/Makefile
sed -i 's/;Listen = 0.0.0.0:1688/Listen = 0.0.0.0:1688/g' feeds/packages/net/vlmcsd/files/vlmcsd.ini
sed -i 's/ -L \[::\]:1688//g' feeds/luci/applications/luci-app-vlmcsd/root/etc/init.d/kms
echo -e "\n#Windows 10/ Windows 11 KMS 安装激活密钥\n#Windows 10/11 Pro：W269N-WFGWX-YVC9B-4J6C9-T83GX\n#Windows 10/11 Enterprise：NPPR9-FWDCX-D2C8J-H872K-2YT43\n#Windows 10/11 Pro for Workstations：NRG8B-VKK3Q-CXVCJ-9G2XF-6Q84J\n" >> feeds/packages/net/vlmcsd/files/vlmcsd.ini

# default-settings
Build_Date=R`date "+%y.%m.%d"`
sed -i '/exit 0/i\sed -i "s\/DISTRIB_REVISION=.*\/DISTRIB_REVISION='"'${Build_Date}'"'\/g" \/etc\/openwrt_release' package/emortal/default-settings/files/99-default-settings
sed -i '/exit 0/i\sed -i "s\/DISTRIB_DESCRIPTION=.*\/DISTRIB_DESCRIPTION='"'IWRT ${Build_Date} '"'\/g" \/etc\/openwrt_release\n' package/emortal/default-settings/files/99-default-settings
sed -i '/exit 0/i\echo "vm.min_free_kbytes=65536" > \/etc\/sysctl.d\/11-nf-conntrack-max.conf' package/emortal/default-settings/files/99-default-settings
sed -i '/exit 0/i\echo "net.netfilter.nf_conntrack_max=65535" >> \/etc\/sysctl.d\/11-nf-conntrack-max.conf' package/emortal/default-settings/files/99-default-settings

# Lan IP
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate

# 添加Nikki相关包配置到.config
if [ -f .config ]; then
    echo -e "\nCONFIG_PACKAGE_nikki=y\nCONFIG_PACKAGE_luci-app-nikki=y\nCONFIG_PACKAGE_luci-i18n-nikki-zh-cn=y" >> .config
fi
