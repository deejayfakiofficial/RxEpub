//
//  RxEpubReader.swift
//  RxEpub
//
//  Created by zhoubin on 2018/3/26.
//

import UIKit
import RxSwift
import RxCocoa
enum ScrollType: Int {
    case page
    case chapter
}

//public struct Page {
//    public var chapter:Int
//    public var page:Int
//}
public class RxEpubReader: NSObject {
    private static var reader:RxEpubReader? = nil
    public var catalogItemClickCallBack:((TocReference)->())? = nil
    
    public let currentChapter:BehaviorRelay<Int> = BehaviorRelay(value:0)
    public let currentPage:BehaviorRelay<Int> = BehaviorRelay(value:0)
    public var config:RxEpubConfig! = RxEpubConfig()
    public var clickCallBack:(()->())? = nil
    public var book:BehaviorRelay<Book?> = BehaviorRelay(value:nil)
    public static var shared:RxEpubReader{
        if reader == nil{
            reader = RxEpubReader()
        }
        return reader!
    }
    public static func remove(){
        reader = nil
    }
}

internal func Log<T>(_ object: T?, filename: String = #file, line: Int = #line, funcname: String = #function) {
    #if DEBUG
    if RxEpubReader.shared.config.logEnabled == false {
        return
    }
    let fmt = DateFormatter()
    fmt.dateFormat = "HH:mm:ss"
    let dateStr = fmt.string(from: Date())
    let infoStr = "* \(dateStr) \(filename.components(separatedBy: "/").last ?? "") (line: \(line)) :: \(funcname) * "
    let output = object == nil ? "nil" : "\(object!)"
    print(infoStr + output)
    #endif
}
