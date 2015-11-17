//
//  ViewController.swift
//  LeanChatSwift
//
//  Created by lzw on 15/11/17.
//  Copyright © 2015年 LeanCloud. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var clientIdTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func login(sender: AnyObject) {
        if let clientId = clientIdTextField.text {
            if (clientId.characters.count > 0) {
                CDChatManager.sharedManager().openWithClientId(clientId, callback: { (result: Bool, error: NSError!) -> Void in
                    if (error == nil) {
                        let tabbarC = UITabBarController()
                        let chatListVC = ChatListViewController()
                        let nav = UINavigationController(rootViewController: chatListVC)
                        tabbarC.addChildViewController(nav)
                        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                        appDelegate.window?.rootViewController = tabbarC
                    }
                })
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

