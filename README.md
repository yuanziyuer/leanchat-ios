![image](https://raw.githubusercontent.com/lzwjava/plan/master/leanchat-ios/shot.png)

## 介绍
这个示例项目是为了帮助使用 LeanCloud 的开发者快速实现具有实时通讯功能的应用。

## 子项目介绍
* LeanChatLib ，聊天界面与逻辑的封装库
* LeanChatExample，展示了如何用少量代码调用LeanChatLib，加入聊天
* LeanChat-ios，为LeanChat IM 整个应用，包含了对 LeanChatLib 更复杂的运用。

## 分支
* master 分支，使用了 LeanCloud 的实时通信服务2.0 （推荐）
* v1 分支，使用了 LeanCloud 的实时通信服务 1.0

## 如何三步加入聊天
1. LeanCloud 中创建应用       
2. 创建项目，加入 LeanChatLib 作为Library，复制几个文件，      
![qq20150403-4](https://cloud.githubusercontent.com/assets/5022872/6982056/c766f686-da3e-11e4-9908-313d65e2016b.png)
3. 依次在合适的地方加入以下代码，      

应用启动后，
```objc
   [AVOSCloud setApplicationId: YourAppID clientKey: YourAppKey];
```

登录时，
```objc
        CDIM* im=[CDIM sharedInstance];
        im.userDelegate=[CDIMService shareInstance];
        [im openWithClientId:self.selfIdTextField.text callback:^(BOOL succeeded, NSError *error) {
            if(error){
                DLog(@"%@",error);
            }else{
                [self performSegueWithIdentifier:@"goMain" sender:sender];
            }
        }];
```

和某人聊天，
```objc
    [[CDIMService shareInstance] goWithUserId:self.otherIdTextField.text fromVC:self];
```

注销时，
```objc
    [[CDIM sharedInstance] closeWithCallback:^(BOOL succeeded, NSError *error) {
        DLog(@"%@",error);
    }];
```

然后，就可以像上面截图那样聊天了。

至于配置用户名、用户头像，可完善下面这个 delegate，
```objc
@protocol CDUserModel <NSObject>

-(NSString*)userId;
-(NSString*)avatarUrl;
-(NSString*)username;

@end

@protocol CDUserDelegate <NSObject>

@required

// run in main queue
-(id<CDUserModel>) getUserById:(NSString*)userId;

// please cache users which will be used by getUserById
-(void)cacheUserByIds:(NSSet*)userIds block:(AVIMArrayResultBlock)block;

@end

```


## 使用 LeanChatLib 需知
1. 必须允许 LeanChatLib中的项目直接include framework里的头文件，设置选项为 YES，如图，
![qq20150403-1](https://cloud.githubusercontent.com/assets/5022872/6982020/5d34db2a-da3e-11e4-8ef2-2521255bb923.png)

2. 加入 embededLib，
![qq20150403-3](https://cloud.githubusercontent.com/assets/5022872/6982016/3df508ac-da3e-11e4-963b-c05342579b86.png)


## 开发指南

[实时通信服务开发指南](https://leancloud.cn/docs/realtime_v2.html)

[Wiki](https://github.com/leancloud/leanchat-android/wiki)

## [更多介绍](https://github.com/leancloud/leanchat-android)

## 致谢

感谢曾宪华大神的 [MessageDisplayKit](https://github.com/xhzengAIB/MessageDisplayKit) 开源库。
