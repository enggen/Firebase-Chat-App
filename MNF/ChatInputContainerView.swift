//
//  ChatInputContainerView.swift
//  MNF
//
//  Created by Ang Sherpa on 18/02/2017.
//  Copyright © 2017 ES Studios Inc. All rights reserved.
//

import UIKit

class ChatInputContainerView: UIView, UITextFieldDelegate {
    
    var chatLogController: ChatLogController? {
        didSet {
            sendButton?.addTarget(chatLogController, action: #selector(ChatLogController.handleSend), for: .touchUpInside)
            
            uploadImageView?.addGestureRecognizer(UITapGestureRecognizer(target: chatLogController, action: #selector(ChatLogController.handleUploadTap)))
        }
    }
    
    lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter Message..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()
    
    var sendButton: UIButton?
    var uploadImageView: UIImageView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        uploadImageView = UIImageView()
        uploadImageView?.image = UIImage(named: "upload_image_icon")
        uploadImageView?.isUserInteractionEnabled = true
        uploadImageView?.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(uploadImageView!)
        
        //iOS 9 Constraints
        uploadImageView?.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        uploadImageView?.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        uploadImageView?.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView?.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        sendButton = UIButton(type: .system)
        sendButton?.setTitle("Send", for: .normal)
        sendButton?.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(sendButton!)
        
        //ios 9 Constraints
        sendButton?.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        sendButton?.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        sendButton?.widthAnchor.constraint(equalToConstant: 70).isActive = true
        sendButton?.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        
        addSubview(self.inputTextField)
        
        //ios9 Constraints
        self.inputTextField.leftAnchor.constraint(equalTo: (uploadImageView?.rightAnchor)!, constant: 8).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: (sendButton?.leftAnchor)!).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor.black
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(separatorLineView)
        
        //ios9 constraints
        separatorLineView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        chatLogController?.handleSend()
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
