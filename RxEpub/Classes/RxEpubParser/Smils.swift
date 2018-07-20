//
//  FRSmilFile.swift
//  RxEpub
//
//  Created by zhoubin on 2018/4/3.
//


import UIKit

struct FRSmilFile {
    var resource: Resource
    var data = [SmilElement]()

    init(resource: Resource){
        self.resource = resource;
    }

    // MARK: - shortcuts

    func ID() -> String {
        return self.resource.id;
    }

    func href() -> String {
        return self.resource.href;
    }

    // MARK: - data methods

    /**
     Returns a smil <par> tag which contains info about parallel audio and text to be played
     */
    func parallelAudioForFragment(_ fragment: String!) -> SmilElement! {
        return findParElement(forTextSrc: fragment, inData: data)
    }

    fileprivate func findParElement(forTextSrc src:String!, inData _data:[SmilElement]) -> SmilElement! {
        for el in _data {

            // if its a <par> (parallel) element and has a <text> node with the matching fragment
            if( el.name == "par" && (src == nil || el.textElement().attributes["src"]?.contains(src) != false ) ){
                return el

                // if its a <seq> (sequence) element, it should have children (<par>)
            }else if el.name == "seq" && el.children.count > 0 {
                let parEl = findParElement(forTextSrc: src, inData: el.children)
                if parEl != nil { return parEl }
            }
        }
        return nil
    }

    /**
     Returns a smil <par> element after the given fragment
     */
    func nextParallelAudioForFragment(_ fragment: String) -> SmilElement! {
        return findNextParElement(forTextSrc: fragment, inData: data)
    }

    fileprivate func findNextParElement(forTextSrc src:String!, inData _data:[SmilElement]) -> SmilElement! {
        var foundPrev = false
        for el in _data {

            if foundPrev { return el }

            // if its a <par> (parallel) element and has a <text> node with the matching fragment
            if( el.name == "par" && (src == nil || el.textElement().attributes["src"]?.contains(src) != false) ){
                foundPrev = true

                // if its a <seq> (sequence) element, it should have children (<par>)
            }else if el.name == "seq" && el.children.count > 0 {
                let parEl = findNextParElement(forTextSrc: src, inData: el.children)
                if parEl != nil { return parEl }
            }
        }
        return nil
    }


    func childWithName(_ name:String) -> SmilElement! {
        for el in data {
            if( el.name == name ){
                return el
            }
        }
        return nil;
    }

    func childrenWithNames(_ name:[String]) -> [SmilElement]! {
        var matched = [SmilElement]()
        for el in data {
            if( name.contains(el.name) ){
                matched.append(el)
            }
        }
        return matched;
    }

    func childrenWithName(_ name:String) -> [SmilElement]! {
        return childrenWithNames([name])
    }
}

/**
 Holds array of `FRSmilFile`
 */
class Smils: NSObject {
    var baseUrl            : URL!
    var smils               = [String: FRSmilFile]()

    /**
     Adds a smil to the smils.
     */
    func add(_ smil: FRSmilFile) {
        self.smils[smil.resource.href] = smil
    }

    /**
     Gets the resource with the given href.
     */
    func findByHref(_ href: String) -> FRSmilFile? {
        for smil in smils.values {
            if smil.resource.href == href {
                return smil
            }
        }
        return nil
    }

    /**
     Gets the resource with the given id.
     */
    func findById(_ ID: String) -> FRSmilFile? {
        for smil in smils.values {
            if smil.resource.id == ID {
                return smil
            }
        }
        return nil
    }
}
