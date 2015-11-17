//
//  User.swift
//  LeanChatSwift
//
//  Created by lzw on 15/11/17.
//  Copyright © 2015年 LeanCloud. All rights reserved.
//

import Foundation

class User: NSObject, CDUserModel {
    private var _username: String!
    private var _userId: String!
    private var _avatarUrl: String!
    
    func username() -> String! {
        return _username
    }
    
    func userId() -> String! {
        return _userId
    }
    
    func avatarUrl() -> String! {
        return _avatarUrl
    }
    
    func setUsername(username: String!) {
        _username = username
    }
    
    func setUserId(userId: String!) {
        _userId = userId
    }
    
    func setAvatarUrl(avatarUrl: String!) {
        _avatarUrl = avatarUrl
    }
}
