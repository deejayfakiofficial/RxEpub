//
//  Spine.swift
//  RxEpub
//
//  Created by zhoubin on 2018/4/3.
//


import UIKit

public class Spine: NSObject {
    var pageProgressionDirection: String?
    public var spineReferences = [Resource]()

    var isRtl: Bool {
        if let pageProgressionDirection = pageProgressionDirection , pageProgressionDirection == "rtl" {
            return true
        }
        return false
    }

    func nextChapter(_ href: String) -> Resource? {
        var found = false;

        for item in spineReferences {
            if(found){
                return item
            }

            if(item.href == href) {
                found = true
            }
        }
        return nil
    }
}
