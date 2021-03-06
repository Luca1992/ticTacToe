//
//  User.swift
//  TrisTest1
//
//  Created by Mac Luca on 26/03/18.
//  Copyright © 2018 Mac Luca. All rights reserved.
//

import Foundation
import UIKit

class User {
    
    var id: String = ""
    var nickName: String = ""
    var email: String = ""
    var vittorie: Int = 0
    var sconfitte: Int = 0
    var stato: String = ""
    var image: UIImage?
    var nameImage: String = ""
    
    
    init() {
        nickName = ""
        email = ""
        vittorie = 0
        sconfitte = 0
        stato = "offline"
    }
    init(_ nickName: String) {
        self.nickName = nickName
    }
    init(_ nickName: String, _ email: String, _ image: UIImage){
        self.nickName = nickName
        self.email = email
        self.image = image
    }
}
