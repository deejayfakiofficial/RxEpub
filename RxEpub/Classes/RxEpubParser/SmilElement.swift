//
//  SmilElement.swift
//  RxEpub
//
//  Created by zhoubin on 2018/4/3.
//


import UIKit

class SmilElement: NSObject {
    var name: String // the name of the tag: <seq>, <par>, <text>, <audio>
    var attributes: [String: String]!
    var children: [SmilElement]

    init(name: String, attributes: [String:String]!) {
        self.name = name
        self.attributes = attributes
        self.children = [SmilElement]()
    }

    // MARK: - Element attributes

    func getId() -> String! {
        return getAttribute("id")
    }

    func getSrc() -> String! {
        return getAttribute("src")
    }

    /**
     Returns array of Strings if `epub:type` attribute is set. An array is returned as there can be multiple types specified, seperated by a whitespace
     */
    func getType() -> [String]! {
        let type = getAttribute("epub:type", defaultVal: "")
        return type!.components(separatedBy: " ")
    }

    /**
     Use to determine if this element matches a given type

     **Example**

     epub:type="bodymatter chapter"
     isType("bodymatter") -> true
     */
    func isType(_ aType:String) -> Bool {
        return getType().contains(aType)
    }

    func getAttribute(_ name: String, defaultVal: String!) -> String! {
        return attributes[name] != nil ? attributes[name] : defaultVal;
    }

    func getAttribute(_ name: String ) -> String! {
        return getAttribute(name, defaultVal: nil)
    }

    // MARK: - Retrieving children elements

    // if <par> tag, a <text> is required (http://www.idpf.org/epub/301/spec/epub-mediaoverlays.html#sec-smil-par-elem)
    func textElement() -> SmilElement! {
        return childWithName("text")
    }

    func audioElement() -> SmilElement! {
        return childWithName("audio")
    }

    func videoElement() -> SmilElement! {
        return childWithName("video")
    }

    func childWithName(_ name:String) -> SmilElement! {
        for el in children {
            if( el.name == name ){
                return el
            }
        }
        return nil;
    }

    func childrenWithNames(_ name:[String]) -> [SmilElement]! {
        var matched = [SmilElement]()
        for el in children {
            if( name.contains(el.name) ){
                matched.append(el)
            }
        }
        return matched
    }

    func childrenWithName(_ name:String) -> [SmilElement]! {
        return childrenWithNames([name])
    }
}
