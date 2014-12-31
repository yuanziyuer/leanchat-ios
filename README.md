[LeanCloud 镜像下载地址](https://download.leancloud.cn/demo/)

![image](https://raw.githubusercontent.com/lzwjava/plan/master/leanchat-ios/shot.png)

![image](https://raw.githubusercontent.com/lzwjava/plan/master/leanchat-ios/contact.png)

![a](https://raw.githubusercontent.com/lzwjava/plan/master/leanchat-ios/group.png)

## Leanchat 项目构成
* [Leanchat-android](https://github.com/leancloud/leanchat)
* [Leanchat-ios](https://github.com/leancloud/leanchat-ios)
* [Leanchat-cloud-code](https://github.com/leancloud/leanchat-cloudcode)，Leanchat 云代码后端


## 介绍
这个示例项目是为了帮助使用AVOSCloud的开发者快速实现具有实时通讯功能的应用.

## 如何运行

1.  `pod install` 
2.  用XCode打开`AVOSChatDemo.xcworkspace`（注意不是`AVOSChatDemo.xcodeproj`，因为用了pods来引入模块），选择运行的scheme和设备，点击运行按钮或菜单`Product`->`Run`或快捷键`Command(⌘)`+`r`就可以运行此示例

----

## 使用说明

此Demo提供用户注册、用户登录、聊天会话记录、创建群组、生成群组和个人二维码、扫描二维码加入群组或个人聊天、联系人列表、用户退出等功能。
AppID和AppKey可以在[www.avoscloud.com](http://www.avoscloud.com)创建应用获取。

----
## 其他

如果您在使用AVOSCloud SDK中, 有自己独特高效的用法, 非常欢迎您fork 并提交pull request, 帮助其他开发者更好的使用SDK. 我们将在本项目的贡献者中, 加入您的名字和联系方式(如果您同意的话)

## 部署项目
*  申请应用，替换[CDCommonDefine.h](https://github.com/leancloud/leanchat-ios/blob/master/AVOSChatDemo/settings/CDCommonDefine.h)中的appId,appKey
*  fork [AdventureCloud](https://github.com/avoscloud/AdventureCloud)，[部署云代码](https://github.com/leancloud/leanchat-cloudcode)
*  建表`AddRequest`

## 阅读源码
iOS 源码，推荐阅读 [CDSessionManager.m](https://github.com/leancloud/leanchat-ios/blob/master/AVOSChatDemo/service/CDSessionManager.m)与 [CDDatabaseService.m](https://github.com/leancloud/leanchat-ios/blob/master/AVOSChatDemo/service/CDDatabaseService.m)

更多请见 [wiki](https://github.com/leancloud/leanchat-android/wiki)

## 发布日志

v1.1.9
1. 群成员也可以加人
2. 增加消息发送状态显示，发送中、已发送、已接收，发送失败。
3. 解决iOS中收到iOS录音，不能播放的bug。
4. 发送图片、音频时，能提示正在上传发送中。
5. 增加桌面图标中未读消息红点显示

v1.1.10
1. 优化消息发送状态显示，支持重发消息
2. 提示会话暂停
3. 离线消息支持声音提示
4. 修复收不到群组消息的bug


## 致谢

感谢曾宪华大神的 [MessageDisplayKit](https://github.com/xhzengAIB/MessageDisplayKit) 开源库。
