//
//  Resource.swift
//  RxEpub
//
//  Created by zhoubin on 2018/4/3.
//


import UIKit

open class Resource: NSObject {
    var id: String!
    var properties: String?
    var mediaType: MediaType!
    var mediaOverlay: String?
    
    public var href: String!
    public var fullHref: String!
    public var url: URL!
    func basePath() -> String! {
        if href == nil || href.isEmpty { return nil }
        var paths = fullHref.components(separatedBy: "/")
        paths.removeLast()
        return paths.joined(separator: "/")
    }
}

// MARK: Equatable

func ==(lhs: Resource, rhs: Resource) -> Bool {
    return lhs.id == rhs.id && lhs.href == rhs.href
}
