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
    public let backgroundColor = Variable("#ffffff")
    public let textColor = Variable("#666666")
    public let fontSize:Variable<CGFloat> = Variable(14)
    public var logEnabled = false
}
