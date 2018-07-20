//
//  RxEpubPageController.swift
//  RxEpub
//
//  Created by zhoubin on 2018/4/4.
//

import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt
import NSObject_Rx
open class RxEpubPageController: UIViewController {
    var book:Book? = nil
    let bag = DisposeBag()
    let scrollDirection:Variable<ScrollDirection> = Variable(.none)
    let indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    var pageViewController:UIPageViewController!
    var url:URL!
    public convenience init(url:URL) {
        self.init(nibName: nil, bundle: nil)
        self.url = url
    }
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        setUpShemes()
        setUpPageViewController()
        setUpIndicator()
        setUpRx()
    }
    func setUpPageViewController(){
        let options = [UIPageViewControllerOptionSpineLocationKey:NSNumber(integerLiteral: UIPageViewControllerSpineLocation.min.rawValue)]
        pageViewController = UIPageViewController(transitionStyle: UIPageViewControllerTransitionStyle.scroll, navigationOrientation: UIPageViewControllerNavigationOrientation.horizontal, options: options)
        
        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParentViewController: self)
        pageViewController.delegate = self
        pageViewController.dataSource = self
    }
    func setUpIndicator(){
        view.addSubview(indicator)
        indicator.startAnimating()
        indicator.hidesWhenStopped = true
    }
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        indicator.center = CGPoint(x: view.center.x, y: view.center.y)
    }
    func setUpRx(){
        let startOffset = pageViewController.scrollView!.rx.willBeginDragging.map{[weak self] in
            return self?.pageViewController.scrollView?.contentOffset ?? CGPoint.zero
        }
        
        Observable.combineLatest(startOffset, pageViewController.scrollView!.rx.contentOffset) { (p1, p2) -> ScrollDirection in
            if p1.x > p2.x{
                return .right
            }else if p1.x < p2.x{
                return .left
            }else{
                return .none
            }
        }.subscribe(onNext: { (direction) in
            if direction != .none{
                RxEpubReader.shared.scrollDirection = direction
            }
        }).disposed(by: bag)
        
        RxEpubReader.shared.config.backgroundColor.asObservable().subscribe(onNext:{[weak self] in
            self?.view.backgroundColor = UIColor(hexString: $0)
        }).disposed(by: bag)

        RxEpubParser(url: url).parse().subscribe(onNext: {[weak self] (book) in
            self?.book = book
            if let vc = self?.epubViewController(at: 0){
                self?.pageViewController.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
                self?.indicator.stopAnimating()
                self?.indicator.removeFromSuperview()
            }
        }, onError: { (err) in
            print("Error",err)
        }).disposed(by: bag)
    }
    func pageIndex(for viewController:RxEpubViewController)->Int?{
        return book?.spine.spineReferences.index(of: viewController.resource)
    }
    func epubViewController(at index:Int)->UIViewController?{
        if let resources = book?.spine.spineReferences,
            index >= 0,
            index < resources.count{
            let resource = resources[index]
            return RxEpubViewController(resource: resource)
        }
        return nil
    }
    func setUpShemes(){
        URLProtocol.registerClass(RxEpubURLProtocol.self)
        URLProtocol.wk_register(scheme: "http")
        URLProtocol.wk_register(scheme: "https")
        URLProtocol.wk_register(scheme: "file")
        URLProtocol.wk_register(scheme: "App")
    }
    deinit {
        URLProtocol.wk_unregister(scheme: "http")
        URLProtocol.wk_unregister(scheme: "https")
        URLProtocol.wk_unregister(scheme: "file")
        URLProtocol.wk_unregister(scheme: "App")
        URLProtocol.unregisterClass(RxEpubURLProtocol.self)
        RxEpubReader.remove()
    }
    @objc func tap(){
        RxEpubReader.shared.clickCallBack?()
    }
}
extension RxEpubPageController:UIPageViewControllerDataSource,UIPageViewControllerDelegate{
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let vc = viewController as! RxEpubViewController
        if let index = pageIndex(for: vc){
            return epubViewController(at: index + 1)
        }
        return nil
    }
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let vc = viewController as! RxEpubViewController
        if let index = pageIndex(for: vc){
            return epubViewController(at: index - 1)
        }
        return nil
    }
    public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        pageViewController.view.isUserInteractionEnabled = false
    }
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if finished && completed,
            let vc = pageViewController.viewControllers?.first as? RxEpubViewController,
            let index = pageIndex(for: vc) {
            RxEpubReader.shared.currentChapter.value = index
        }
        pageViewController.view.isUserInteractionEnabled = true
    }
}
extension UIPageViewController {
    
    var scrollView: UIScrollView? {
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
extension UIColor{
    public static var random: UIColor {
        let red = CGFloat(arc4random_uniform(255))/255.0
        let green = CGFloat(arc4random_uniform(255))/255.0
        let blue = CGFloat(arc4random_uniform(255))/255.0
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
    public convenience init?(hexString: String, transparency: CGFloat = 1) {
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
