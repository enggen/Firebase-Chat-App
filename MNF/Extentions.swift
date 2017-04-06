//
//  Extentions.swift
//  MNF
//
//  Created by Ang Sherpa on 05/02/2017.
//  Copyright © 2017 ES Studios Inc. All rights reserved.
//

import UIKit

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    func loadImageUsingCacheWithUrlString(urlString: String) {
        
        self.image = nil
        
        // Check cache for image first
        if let cacheImage = imageCache.object(forKey: urlString as AnyObject) {
            
            self.image = cacheImage as? UIImage
            return
        }
        
        // Otherwise fire off a new  download
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            
            if error != nil {
                print(error!)
            }
            
            
            DispatchQueue.main.async {
                
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                    
                    self.image = downloadedImage
                }
                
            }
            
        }).resume()
    }
}
