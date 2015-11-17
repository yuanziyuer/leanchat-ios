//
//  ChatList.swift
//  LeanChatSwift
//
//  Created by lzw on 15/11/17.
//  Copyright © 2015年 LeanCloud. All rights reserved.
//

import Foundation

class ChatListViewController: CDChatListVC, CDChatListVCDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "消息";
        let image = UIImage(named: "tabbar_chat_active")
        self.tabBarItem.image = image
        
        self.chatListDelegate = self
        
        let addItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addButtonClicked")
        self.navigationItem.rightBarButtonItem = addItem
    }
    
    func addButtonClicked() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let addVC = storyboard.instantiateViewControllerWithIdentifier("AddChat")
        addVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(addVC, animated: true)
    }
    
    func viewController(viewController: UIViewController!, didSelectConv conv: AVIMConversation!) {
        let vc = ChatRoomViewController(conv: conv)
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func setBadgeWithTotalUnreadCount(totalUnreadCount: Int) {
        if (totalUnreadCount > 0) {
            self.tabBarItem.badgeValue = "\(totalUnreadCount)"
        } else {
            self.tabBarItem.badgeValue = nil
        }
    }
}