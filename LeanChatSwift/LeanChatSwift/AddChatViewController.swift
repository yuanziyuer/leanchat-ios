//
//  AddChatViewController.swift
//  LeanChatSwift
//
//  Created by lzw on 15/11/17.
//  Copyright © 2015年 LeanCloud. All rights reserved.
//

import Foundation

class AddChatViewController: UIViewController {
    
    @IBOutlet weak var otherIdTextField: UITextField!
    
    @IBAction func goChat(sender: AnyObject) {
        if let otherId = otherIdTextField.text {
            CDChatManager.sharedManager().fetchConvWithOtherId(otherId, callback: { (conv: AVIMConversation!, error: NSError!) -> Void in
                if (error != nil) {
                    print("error: \(error)")
                } else {
                    let chatRoomVC = ChatRoomViewController(conv:conv)
                    self.navigationController?.pushViewController(chatRoomVC, animated: true)
                }
            })
        }
    }
}