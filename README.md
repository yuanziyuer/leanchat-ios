![leanchat](https://cloud.githubusercontent.com/assets/5022872/7810175/5edda692-03d2-11e5-875d-d32ebfc887a6.gif)


## App Store  
LeanChat 已经在 Apple Store 上架，可前往 https://itunes.apple.com/gb/app/leanchat/id943324553 或搜 LeanChat。

## 介绍
这个示例项目全面展示了 LeanCloud 实时通讯功能的应用，但含杂着许多 UI 代码和其它功能，并不适合快速上手学习，如果你第一次接触 LeanMessage，更推荐 [LeanMessage-Demo](https://github.com/leancloud/LeanMessage-Demo) 项目。等熟悉了之后，可前往 [LeanCloud-Demos](https://github.com/leancloud/leancloud-demos) 挑选你喜欢的 IM 皮肤进行集成。集成的过程中，若遇到疑难问题，不妨再来参考 LeanChat 项目。

## 子项目介绍
* LeanChatLib ，核心的聊天逻辑和聊天界面库。有了它，可以快速集成聊天功能，支持文字、音频、图片、表情消息，消息通知。同时也有相应的 [Android 版本](https://github.com/leancloud/leanchat-android)。
* LeanChatExample，leanchatlib 最简单的使用例子。展示了如何用少量代码调用 LeanChatLib 来加入聊天，无论是用 LeanCloud 的用户系统还是自己的用户系统。
* LeanChat-ios，为 LeanChat 整个应用。它包含好友管理、群组管理、地理消息、附近的人、个人页面、登录注册的功能，完全基于 LeanCloud 的存储和通信功能。它也是对 LeanChatLib 更复杂的应用。

## 分支
* master 分支，使用了 LeanCloud 的实时通信服务2.0 （推荐）
* v1 分支，使用了 LeanCloud 的实时通信服务 1.0

## 运行
LeanChatExample(推荐):
```bash
  cd LeanChatExample
  pod install
  open LeanChatExample.workspace
```

LeanChat:
```bash
  cd LeanChat
  pod install
  open LeanChat.workspace
```

## LeanChatLib 介绍

封装了最近对话页面和聊天页面，LeanChat 和 LeanChatExample 项目都依赖于它。可通过以下方式安装，
```
    pod 'LeanChatLib'
```

## 如何三步加入IM
1. LeanCloud 中创建应用       
2. 加入 LeanChatLib 的 pod 依赖
3. 依次在合适的地方加入以下代码，

应用启动后，初始化，以及配置 IM User
```objc
   [AVOSCloud setApplicationId: YourAppID clientKey: YourAppKey];
   [CDIMConfig config].userDelegate=[[CDUserFactory alloc] init];   
```

配置一个 UserFactory，遵守 CDUserDelegate协议即可。

```objc
#import "CDUserFactory.h"

#import <LeanChatLib/LeanChatLib.h>

@interface CDUserFactory ()<CDUserDelegate>

@end


@implementation CDUserFactory

#pragma mark - CDUserDelegate
-(void)cacheUserByIds:(NSSet *)userIds block:(AVIMArrayResultBlock)block{
    block(nil,nil); // don't forget it
}

-(id<CDUserModel>)getUserById:(NSString *)userId{
    CDUser* user=[[CDUser alloc] init];
    user.userId=userId;
    user.username=userId;
    user.avatarUrl=@"http://ac-x3o016bx.clouddn.com/86O7RAPx2BtTW5zgZTPGNwH9RZD5vNDtPm1YbIcu";
    return user;
}

@end

```

这里的 CDUser 是应用内的User对象，你可以在你的User对象实现 CDUserModel 协议即可。

CDUserModel，
```objc
@protocol CDUserModel <NSObject>

@required

-(NSString*)userId;

-(NSString*)avatarUrl;

-(NSString*)username;

@end
```

登录时调用，
```objc
        CDIM* im=[CDIM sharedInstance];
        [im openWithClientId:selfId callback:^(BOOL succeeded, NSError *error) {
            if(error){
                DLog(@"%@",error);
            }else{
                [self performSegueWithIdentifier:@"goMain" sender:sender];
            }
        }];
```

和某人聊天，
```objc
        [[CDIM sharedInstance] fetchConvWithOtherId:otherId callback:^(AVIMConversation *conversation, NSError *error) {
            if(error){
                DLog(@"%@",error);
            }else{
                LCEChatRoomVC* chatRoomVC=[[LCEChatRoomVC alloc] initWithConv:conversation];
                [weakSelf.navigationController pushViewController:chatRoomVC animated:YES];
            }
        }];
```

和多人群聊，
```objc
        CDIM* im=[CDIM sharedInstance];
        NSMutableArray* memberIds=[NSMutableArray array];
        [memberIds addObject:groupId1];
        [memberIds addObject:groupId2];
        [memberIds addObject:im.selfId];
        [im fetchConvWithMembers:memberIds callback:^(AVIMConversation *conversation, NSError *error) {
            if(error){
                DLog(@"%@",error);
            }else{
                LCEChatRoomVC* chatRoomVC=[[LCEChatRoomVC alloc] initWithConv:conversation];
                [weakSelf.navigationController pushViewController:chatRoomVC animated:YES];
            }
        }];
```

注销时，
```objc
    [[CDIM sharedInstance] closeWithCallback:^(BOOL succeeded, NSError *error) {
        DLog(@"%@",error);
    }];
```

然后，就可以像上面截图那样聊天了。

## 部署 LeanChat 需知

如果要部署完整的LeanChat的话，因为该应用有添加好友的功能，请在设置->应用选项中，勾选互相关注选项，以便一方同意的时候，能互相加好友。

![qq20150407-5](https://cloud.githubusercontent.com/assets/5022872/7016645/53f91bb8-dd1b-11e4-8ce0-72312c655094.png)

## 开发指南

[实时通信服务开发指南](https://leancloud.cn/docs/realtime_v2.html)

[Wiki](https://github.com/leancloud/leanchat-android/wiki)

[更多介绍](https://github.com/leancloud/leanchat-android)

## 致谢

感谢曾宪华大神的 [MessageDisplayKit](https://github.com/xhzengAIB/MessageDisplayKit) 开源库。
