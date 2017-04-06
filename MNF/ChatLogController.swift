//
//  ChatLogController.swift
//  MNF
//
//  Created by Ang Sherpa on 07/02/2017.
//  Copyright © 2017 ES Studios Inc. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            
            obseveMessages()
        }
    }
    
    var messages = [Message]()
    
    func obseveMessages() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid, let toId = user?.id else {
            return
        }
        
        let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(uid).child(toId)
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            
            let messageId = snapshot.key
            let messagesRef = FIRDatabase.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                guard let dictionary = snapshot.value as? [String: AnyObject] else {
                    return
                }
                
                //do we need to attemptfilltering anymore?
                self.messages.append(Message(dictionary: dictionary))
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    //scroll to the last index
                    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                }
                
            }, withCancel: nil)
            
        }, withCancel: nil)
    }
    
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.contentInset = UIEdgeInsetsMake(8, 0, 8, 0)
        //collectionView?.scrollIndicatorInsets = UIEdgeInsetsMake(8, 0, 8, 0)
        collectionView?.alwaysBounceVertical = true 
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        collectionView?.keyboardDismissMode = .interactive
        
//        setupInputComponents()
//        
//        setupKeyboardObservers()
        
    }
    
    lazy var inputContainerView: ChatInputContainerView = {
        
        let chatInputContainerView = ChatInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        chatInputContainerView.chatLogController = self
        return chatInputContainerView
    }()
    
    override var inputAccessoryView: UIView {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
//    func setupKeyboardObservers() {
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: .UIKeyboardDidShow, object: nil)
////        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: .UIKeyboardWillShow, object: nil)
////        
////        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: .UIKeyboardWillHide, object: nil)
//    }
    
    func handleKeyboardDidShow() {
        if messages.count > 0 {
            let indexPath = IndexPath(item: messages.count - 1, section: 0)
            collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func handleKeyboardWillHide(notification: Notification) {
        
        let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double
        
        containerViewBottomAnchor?.constant = 0
        UIView.animate(withDuration: keyboardDuration, animations: {
            
            self.view.layoutIfNeeded()
        })
        
    }
    
    func handleKeyboardWillShow(notification: Notification) {
        
        let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double
        
        if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            containerViewBottomAnchor?.constant = -keyboardFrame.height
            UIView.animate(withDuration: keyboardDuration, animations: { 
                
                self.view.layoutIfNeeded()
            })
        }
        
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? ChatMessageCell
        cell?.chatLogController = self
        
        let message = messages[indexPath.item]
        cell?.textView.text = message.text
        
        //play video - code
        cell?.message = message
        
        setupCell(cell: cell!, message: message)
        
        //estimated width
        if let text = message.text {
            cell?.bubbleWidthAnchor?.constant = estimatFrameForText(text: text).width + 32
            cell?.textView.isHidden = false
            
        } else if message.imageUrl != nil {
            //fall in here if it is an image message
            cell?.bubbleWidthAnchor?.constant = 200
            cell?.textView.isHidden = true
        }

        cell?.playButton .isHidden = message.videoUrl == nil
        
        return cell!
    }
    
    
    
    private func setupCell(cell: ChatMessageCell, message: Message) {
        
        if let profileImageUrl = self.user?.profileImageUrl {
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        if let messageImageUrl = message.imageUrl {
            cell.messageImageView.loadImageUsingCacheWithUrlString(urlString: messageImageUrl)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = UIColor.clear
        } else {
            cell.messageImageView.isHidden = true
        }
        
        if message.fromId == FIRAuth.auth()?.currentUser?.uid {
            // outgoing blue
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white
            
            cell.profileImageView.isHidden = true
            
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
            
        } else {
            //incomming gray
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = UIColor.black
            
            cell.profileImageView.isHidden = false
            
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true 
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 80
        let message = messages[indexPath.item]
        
        // estimated hight
        if let text = message.text {
            height = estimatFrameForText(text: text).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue {
        
            //h1/h2 = w1/w2
            //solve for h1
            // h1 = h2/w2 * h2
            
            height = CGFloat(imageHeight / imageWidth * 200)
        }
        
        return CGSize(width: view.frame.width, height: height)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    private func estimatFrameForText(text: String) -> CGRect {
        
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    var containerViewBottomAnchor: NSLayoutConstraint?
    
//    func setupInputComponents() {
//        
//        let containerView = UIView()
//        containerView.backgroundColor = UIColor.white
//        containerView.translatesAutoresizingMaskIntoConstraints = false
//        
//        view.addSubview(containerView)
//    
//        //iOS 9 Constraints
//        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
//        
//        containerViewBottomAnchor = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        containerViewBottomAnchor?.isActive = true
//        
//        containerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
//        containerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
//        
//        let uploadImageView = UIImageView()
//        uploadImageView.image = UIImage(named: "upload_image_icon")
//        uploadImageView.isUserInteractionEnabled = true
//        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
//        
//        uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUploadTap)))
//        containerView.addSubview(uploadImageView)
//        
//        //iOS 9 Constraints
//        uploadImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
//        uploadImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
//        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
//        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
//        
//        let sendButton = UIButton(type: .system)
//        sendButton.setTitle("Send", for: .normal)
//        sendButton.translatesAutoresizingMaskIntoConstraints = false
//        
//        containerView.addSubview(sendButton)
//        
//        //ios 9 Constraints
//        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
//        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
//        sendButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
//        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
//        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
//        
//        containerView.addSubview(inputTextField)
//        
//        //ios9 Constraints
//        inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 8).isActive = true
//        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
//        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
//        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
//        
//        let separatorLineView = UIView()
//        separatorLineView.backgroundColor = UIColor.black
//        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
//        
//        containerView.addSubview(separatorLineView)
//        
//        //ios9 constraints
//        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
//        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
//        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
//        separatorLineView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
//        
//    }
    
    func handleUploadTap() {
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // Selected the video
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL {
            
            handleVideoSelectedForUrl(url: videoUrl)
        } else {
            
            // selected an image
            handleImageSelectedForInfo(info: info as [String : AnyObject])
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    private func handleVideoSelectedForUrl(url: URL) {
        let fileName = NSUUID().uuidString + ".mov"
        let uploadTask = FIRStorage.storage().reference().child("message_movies").child(fileName).putFile(url, metadata: nil, completion: { (metadata, error) in
            
            if error != nil {
                print("Failed to upload: ", error!)
                return
            }
            
            if let videoUrl = metadata?.downloadURL()?.absoluteString {
                
                if let thumbnailImage = self.thumbnailImageForFileUrl(fileUrl: url) {
                    //
                    self.uploadToFirebaseStorageUsingImage(image: thumbnailImage, completion: { (imageUrl) in
                        
                        let properties = ["imageUrl": imageUrl, "imageWidth": thumbnailImage.size.width, "imageHeight": thumbnailImage.size.height, "videoUrl": videoUrl] as [String : Any]
                        self.sendMessageWithProperties(properties: properties as [String : AnyObject])
                    })

                }
                
            }
        })
        
        uploadTask.observe(.progress) { (snapshot) in
            if let completedUnitCount = snapshot.progress?.completedUnitCount {
                self.navigationItem.title = String(completedUnitCount)
            }
        }
        
        uploadTask.observe(.success) { (snapshot) in
            self.navigationItem.title = self.user?.name
        }
    }
    
    private func thumbnailImageForFileUrl(fileUrl: URL) -> UIImage? {
        let assets = AVAsset(url: fileUrl)
        let imageGenerator = AVAssetImageGenerator(asset: assets)
        
        do {
            
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            
            return UIImage(cgImage: thumbnailCGImage)
            
        } catch let err {
            print(err)
        }
        
        return nil
    
    }
    
    private func handleImageSelectedForInfo(info: [String: AnyObject]) {
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            uploadToFirebaseStorageUsingImage(image: selectedImage, completion: { (imageUrl) in
                self.sendMessageWithImageUrl(imageUrl: imageUrl, image: selectedImage)
            })
            
        }
    }
    
    private func uploadToFirebaseStorageUsingImage(image: UIImage, completion: @escaping (_ imageUrl: String) -> ()) {
        let imageName = NSUUID().uuidString
        let ref = FIRStorage.storage().reference().child("message_images").child(imageName)
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
            ref.put(uploadData, metadata: nil, completion: { (metadata, error) in
                
                if error != nil {
                    print("Failed to upload image:",error!)
                    return
                }
                
                if let imageUrl = metadata?.downloadURL()?.absoluteString {
                    completion(imageUrl)
                    
                }
                
            })
        }
        
    }
    
    func handleSend() {
        
        let properties = ["text": inputContainerView.inputTextField.text!] as [String : Any]
        
        sendMessageWithProperties(properties: properties as [String : AnyObject])
    }
    
    private func sendMessageWithImageUrl(imageUrl: String, image: UIImage) {
        let properties = ["imageUrl": imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height] as [String : Any]
        
        sendMessageWithProperties(properties: properties as [String : AnyObject])
    }
    
    private func sendMessageWithProperties(properties: [String: AnyObject]) {
        let ref = FIRDatabase.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toId = user?.id
        let fromId = FIRAuth.auth()?.currentUser?.uid
        let timeStamp = Date().timeIntervalSince1970
        var values = ["toId": toId!, "fromId": fromId!, "timeStamp": timeStamp] as [String : Any]
        
        //append roperties dictionary onto values somehow?
        //key $0, value $1
        properties.forEach({values[$0] = $1})
        
        childRef.updateChildValues(values) { (error, ref) in
            
            if error != nil {
                print(Error.self)
                return
            }
            
            self.inputContainerView.inputTextField.text = nil
            
            let userMessageRef = FIRDatabase.database().reference().child("user-messages").child(fromId!).child(toId!)
            
            let messageId = childRef.key
            userMessageRef.updateChildValues([messageId: 1])
            
            let receipientUserMessagesRef = FIRDatabase.database().reference().child("user-messages").child(toId!).child(fromId!)
            receipientUserMessagesRef.updateChildValues([messageId: 1])
        }
    }
    
    var startingFrame: CGRect?
    var blackBackgroundView: UIView?
    var startingImageView: UIImageView?
    
    //custom image zooming logic
    func perfomZoomInForStartingImageView(startingImageView: UIImageView) {
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
        
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.image = startingImageView.image
        zoomingImageView.backgroundColor = UIColor.red
        zoomingImageView.translatesAutoresizingMaskIntoConstraints = false
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        
        
        if let keyWindow = UIApplication.shared.keyWindow {
            blackBackgroundView = UIView(frame: keyWindow.frame)
            blackBackgroundView?.backgroundColor = UIColor.black
            blackBackgroundView?.alpha = 0
            keyWindow.addSubview(blackBackgroundView!)
            
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.blackBackgroundView?.alpha = 1
                self.inputContainerView.alpha = 0
                
                let height = (self.startingFrame?.height)! / (self.startingFrame?.width)! * keyWindow.frame.width
                //zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                
                zoomingImageView.leftAnchor.constraint(equalTo: keyWindow.leftAnchor).isActive = true
                zoomingImageView.centerYAnchor.constraint(equalTo: keyWindow.centerYAnchor).isActive = true
                zoomingImageView.widthAnchor.constraint(equalTo: keyWindow.widthAnchor).isActive = true
                zoomingImageView.heightAnchor.constraint(equalToConstant: height).isActive = true
                
                //zoomingImageView.center = keyWindow.center
                
            }, completion: { (completed: Bool) in
                
            })
            
        }
    }
    
    func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        if let zoomOutImageView = tapGesture.view {
            
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: { 
                
                zoomOutImageView.frame = self.startingFrame!
                self.blackBackgroundView?.alpha = 0
                self.inputContainerView.alpha = 1
                
            }, completion: { (completed: Bool) in
                
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
                
            })
            
        }
    }
    
}
