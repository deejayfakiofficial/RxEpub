//
//  RxEpubURLProtocol+Ex.swift
//  RxEpub
//
//  Created by zhoubin on 2018/4/10.
//

import UIKit
import WebKit
extension URLProtocol {
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
        let cls = contextControllerClass()
        let sel = registerSchemeSelector()
        if cls.responds(to: sel) {
            (cls as AnyObject).perform(sel, with: scheme)
        }
    }
    class func wk_unregister(scheme:String){
        let cls = contextControllerClass()
        let sel = unregisterSchemeSelector()
        if cls.responds(to: sel) {
            (cls as AnyObject).perform(sel, with: scheme)
        }
    }
}
