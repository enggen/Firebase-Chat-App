//
//  Message.swift
//  MNF
//
//  Created by Ang Sherpa on 08/02/2017.
//  Copyright © 2017 ES Studios Inc. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    
    var fromId: String?
    var toId: String?
    var timeStamp: NSNumber?
    var text: String?
    
    var imageUrl: String?
    
    var imageHeight: NSNumber?
    var imageWidth: NSNumber?
    
    var videoUrl: String?
    
    func chatPartnetId() -> String? {
        return fromId == FIRAuth.auth()?.currentUser?.uid ? toId : fromId
    }
    
    init(dictionary: [String: AnyObject]) {
        super.init()
        
        fromId = dictionary["fromId"] as? String
        toId = dictionary["toId"] as? String
        timeStamp = dictionary["timeStamp"] as? NSNumber
        text = dictionary["text"] as? String
        
        imageUrl = dictionary["imageUrl"] as? String
        imageHeight = dictionary["imageHeight"] as? NSNumber
        imageWidth = dictionary["imageWidth"] as? NSNumber
        
        videoUrl = dictionary["videoUrl"] as? String
    }

}
