//
//  RxEpubConfig.swift
//  RxEpub
//
//  Created by zhoubin on 2018/4/11.
//

import UIKit
import RxCocoa
import RxSwift
public class RxEpubConfig: NSObject {
    public let backgroundColor = BehaviorRelay(value:"#ffffff")
    public let textColor = BehaviorRelay(value:"#666666")
    public let fontSize:BehaviorRelay<CGFloat> = BehaviorRelay(value:14)
    public var logEnabled = false
}
