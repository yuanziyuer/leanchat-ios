[LeanCloud 镜像下载地址](https://download.leancloud.cn/demo/)

![image](https://raw.githubusercontent.com/lzwjava/plan/master/leanchat-ios/shot.png)

![image](https://raw.githubusercontent.com/lzwjava/plan/master/leanchat-ios/contact.png)

![a](https://raw.githubusercontent.com/lzwjava/plan/master/leanchat-ios/group.png)

## [Leanchat 项目构成](https://github.com/leancloud/leanchat-android/wiki)


## 介绍
这个示例项目是为了帮助使用AVOSCloud的开发者快速实现具有实时通讯功能的应用.

## 如何运行

1.  `pod install`       
2.  用XCode打开`AVOSChatDemo.xcworkspace`（注意不是`AVOSChatDemo.xcodeproj`，因为用了pods来引入模块），选择运行的scheme和设备，点击运行按钮或菜单`Product`->`Run`或快捷键`Command(⌘)`+`r`就可以运行此示例



## 部署项目
*  申请应用，替换[CDCommonDefine.h](https://github.com/leancloud/leanchat-ios/blob/master/AVOSChatDemo/settings/CDCommonDefine.h)中的appId,appKey
*  参考[如何替换 AppId 部署应用](https://github.com/leancloud/leanchat-android/wiki/%E5%A6%82%E4%BD%95%E6%9B%BF%E6%8D%A2-AppId-%E9%83%A8%E7%BD%B2%E5%BA%94%E7%94%A8)

## 阅读源码
iOS 源码，推荐阅读 [CDSessionManager.m](https://github.com/leancloud/leanchat-ios/blob/master/AVOSChatDemo/service/CDSessionManager.m)与 [CDDatabaseService.m](https://github.com/leancloud/leanchat-ios/blob/master/AVOSChatDemo/service/CDDatabaseService.m)

## 其他

如果您在使用AVOSCloud SDK中, 有自己独特高效的用法, 非常欢迎您fork 并提交pull request, 帮助其他开发者更好的使用SDK. 我们将在本项目的贡献者中, 加入您的名字和联系方式(如果您同意的话)

更多请见 [wiki](https://github.com/leancloud/leanchat-android/wiki)


## 致谢

感谢曾宪华大神的 [MessageDisplayKit](https://github.com/xhzengAIB/MessageDisplayKit) 开源库。
