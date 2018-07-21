//
//  Extesions.swift
//  RxEpub
//
//  Created by zhoubin on 2018/7/21.
//

import UIKit
import WebKit
import RxSwift
import RxCocoa
internal extension URLProtocol {
    class func contextControllerClass()->AnyClass {
        return NSClassFromString("WKBrowsingContextController")!
    }
    class func registerSchemeSelector()->Selector {
        return NSSelectorFromString("registerSchemeForCustomProtocol:")
    }
    class func unregisterSchemeSelector()->Selector {
        return NSSelectorFromString("unregisterSchemeForCustomProtocol:")
    }
    class func wk_register(scheme:String){
        let cls:AnyClass = contextControllerClass()
        let sel = registerSchemeSelector()
        if cls.responds(to: sel) {
            _ = (cls as AnyObject).perform(sel, with: scheme)
        }
    }
    class func wk_unregister(scheme:String){
        let cls:AnyClass = contextControllerClass()
        let sel = unregisterSchemeSelector()
        if cls.responds(to: sel) {
            _ = (cls as AnyObject).perform(sel, with: scheme)
        }
    }
}

internal extension Reactive where Base: WKWebView {
    internal var loading: Observable<Bool> {
        return self.observeWeakly(Bool.self, "loading")
            .map { $0 ?? false }
    }
    internal var title: Observable<String> {
        return self.observeWeakly(String.self, "title")
            .map { $0 ?? "" }
    }
}
internal extension UIPageViewController {
    
    internal var scrollView: UIScrollView? {
        get {
            for subview in self.view.subviews {
                if let scrollView = subview as? UIScrollView {
                    return scrollView
                }
            }
            return nil
        }
    }
}
internal extension UIColor{
    internal static var random: UIColor {
        let red = CGFloat(arc4random_uniform(255))/255.0
        let green = CGFloat(arc4random_uniform(255))/255.0
        let blue = CGFloat(arc4random_uniform(255))/255.0
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
    internal convenience init?(hexString: String, transparency: CGFloat = 1) {
        var string = ""
        if hexString.lowercased().hasPrefix("0x") {
            string =  hexString.replacingOccurrences(of: "0x", with: "")
        } else if hexString.hasPrefix("#") {
            string = hexString.replacingOccurrences(of: "#", with: "")
        } else {
            string = hexString
        }
        
        if string.count == 3 { // convert hex to 6 digit format if in short format
            var str = ""
            string.forEach { str.append(String(repeating: String($0), count: 2)) }
            string = str
        }
        
        guard let hexValue = Int(string, radix: 16) else { return nil }
        
        var trans = transparency
        if trans < 0 { trans = 0 }
        if trans > 1 { trans = 1 }
        
        let red = (hexValue >> 16) & 0xff
        let green = (hexValue >> 8) & 0xff
        let blue = hexValue & 0xff
        guard red >= 0 && red <= 255 else { return nil }
        guard green >= 0 && green <= 255 else { return nil }
        guard blue >= 0 && blue <= 255 else { return nil }
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: trans)
    }
}
