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
    let scrollDirection:Variable<ScrollDirection> = Variable(.none)
    let indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    var pageViewController:UIPageViewController!
    var currentViewController:RxEpubViewController? = nil
    var url:URL!
    public init(url:URL) {
        super.init(nibName: nil, bundle: nil)
        self.url = url
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        setUpShemes()
        setUpPageViewController()
        setUpIndicator()
        setUpRx()
    }
    public func scrollTo(chapter:Int){
        RxEpubReader.shared.book.asObservable().subscribe(onNext: {[weak self] in
            if $0 == nil{
                return
            }
            DispatchQueue.main.async {
                if let vc = self?.epubViewController(at: chapter){
                    self?.pageViewController.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
                }
            }
        }).disposed(by: rx.disposeBag)
        
    }
    public func scrollTo(page:Int){
        RxEpubReader.shared.book.asObservable().subscribe(onNext: {[weak self] in
            if $0 == nil{
                return
            }
            DispatchQueue.main.async {
                if let vc = self?.pageViewController.viewControllers?.first as? RxEpubViewController{
                    vc.webView.scrollTo(page: page)
                }
            }
        }).disposed(by: rx.disposeBag)
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
        RxEpubParser(url: url).parse().subscribe(onNext: {[weak self] (book) in
            RxEpubReader.shared.book.value = book
            if let vc = self?.epubViewController(at: 0){
                self?.pageViewController.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
                self?.indicator.stopAnimating()
                self?.indicator.removeFromSuperview()
            }
            self?.title = book.title
        }).disposed(by: rx.disposeBag)
        
        
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
        }).disposed(by: rx.disposeBag)
        
        RxEpubReader.shared.config.backgroundColor.asObservable().subscribe(onNext:{[weak self] in
            self?.view.backgroundColor = UIColor(hexString: $0)
        }).disposed(by: rx.disposeBag)

        Observable.combineLatest(RxEpubReader.shared.config.fontSize.asObservable(), RxEpubReader.shared.config.textColor.asObservable()).skip(1).subscribe(onNext: {[weak self] (_,_) in
            guard let sf = self,let vcs = sf.pageViewController.viewControllers as? [RxEpubViewController] else{
                return
            }
            for vc in vcs{
                vc.webView.updateCss()
            }
        }).disposed(by: rx.disposeBag)
        
        RxEpubReader.shared.catalogItemClickCallBack = {[weak self] in
            guard let resource = $0.resource else {
                return
            }
            let vc = RxEpubViewController(resource: resource)
            self?.pageViewController.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
        }
    }
    func pageIndex(for viewController:RxEpubViewController)->Int?{
        return RxEpubReader.shared.book.value?.spine.spineReferences.map{$0.id}.index(of: viewController.resource.id)
    }
    
    func epubViewController(at index:Int)->UIViewController?{
        if let resources = RxEpubReader.shared.book.value?.spine.spineReferences,
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
    }
    deinit {
        URLProtocol.wk_unregister(scheme: "http")
        URLProtocol.wk_unregister(scheme: "https")
        URLProtocol.wk_unregister(scheme: "file")
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
            vc.webView.rx.loading.asObservable().subscribe(onNext: {
                if !$0{
                    vc.webView.catulatePage()
                }
            }).disposed(by: rx.disposeBag)
        }
        pageViewController.view.isUserInteractionEnabled = true
    }
}
