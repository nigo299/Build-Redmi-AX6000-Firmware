#!/bin/bash

git clone https://github.com/tty228/luci-app-wechatpush -b master package/custom/luci-app-wechatpush
git clone https://github.com/hubbylei/wrtbwmon -b master package/custom/wrtbwmon
git clone https://github.com/hubbylei/openwrt-cdnspeedtest -b master package/custom/openwrt-cdnspeedtest
git clone https://github.com/hubbylei/luci-app-cloudflarespeedtest -b main package/custom/luci-app-cloudflarespeedtest
git clone https://github.com/openwrt/packages -b master tmp/packages

# 添加Nikki feed源
echo "src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git" >> feeds.conf.default
