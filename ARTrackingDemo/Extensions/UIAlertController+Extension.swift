//
//  UIAlertController+Extension.swift
//  ARTrackingDemo
//
//  Created by HereTrix on 6/2/20.
//

import UIKit

extension UIAlertController {
    
    class func show(message: String, from controller: UIViewController) {
        let ac = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        ac.addAction(action)
        
        controller.present(ac, animated: true, completion: nil)
    }
}
