//
//  RxEpubPageController.swift
//  RxEpub
//
//  Created by zhoubin on 2018/4/4.
//

import UIKit
import RxSwift
import RxCocoa
open class RxEpubPageController: UIViewController {
    let indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    var pageViewController:UIPageViewController!
    var currentViewController:RxEpubViewController? = nil
    var url:URL!
    let disposeBag = DisposeBag()
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
        }).disposed(by: disposeBag)
        
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
        }).disposed(by: disposeBag)
    }
    
    func setUpPageViewController(){
        let options = [UIPageViewController.OptionsKey.spineLocation:NSNumber(integerLiteral: UIPageViewController.SpineLocation.min.rawValue)]
        pageViewController = UIPageViewController(transitionStyle: UIPageViewController.TransitionStyle.scroll, navigationOrientation: UIPageViewController.NavigationOrientation.horizontal, options: options)
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
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
            RxEpubReader.shared.book.accept(book)
            self?.title = book.title
            if let vc = self?.epubViewController(at: 0){
                self?.pageViewController.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
                self?.indicator.stopAnimating()
                self?.indicator.removeFromSuperview()
                self?.pageViewController.delegate = self
                self?.pageViewController.dataSource = self
            }else{
                self?.showError()
            }
        },onError:{[weak self] _ in
            self?.showError()
        }).disposed(by: disposeBag)
        
        RxEpubReader.shared.config.backgroundColor.asObservable().subscribe(onNext:{[weak self] in
            self?.view.backgroundColor = UIColor(hexString: $0)
        }).disposed(by: disposeBag)
        
        Observable.combineLatest(RxEpubReader.shared.config.fontSize.asObservable(), RxEpubReader.shared.config.textColor.asObservable()).skip(1).subscribe(onNext: {[weak self] (_,_) in
            guard let sf = self,let vcs = sf.pageViewController.viewControllers as? [RxEpubViewController] else{
                return
            }
            for vc in vcs{
                vc.webView.updateCss()
            }
        }).disposed(by: disposeBag)
        
        RxEpubReader.shared.catalogItemClickCallBack = {[weak self] in
            guard let resource = $0.resource else {
                return
            }
            let toChapterIndex = RxEpubReader.shared.book.value?.spine.spineReferences.firstIndex(of: resource) ?? 0
            var direction:UIPageViewController.NavigationDirection = .forward
            if toChapterIndex <= RxEpubReader.shared.currentChapter.value {
                direction = .reverse
            }
            let vc = RxEpubViewController(resource: resource)
            self?.pageViewController.setViewControllers([vc], direction: direction, animated: false, completion: nil)
            RxEpubReader.shared.currentChapter.accept(toChapterIndex)
            RxEpubReader.shared.currentPage.accept(0)
        }
    }
    func showError(){
        indicator.stopAnimating()
        indicator.removeFromSuperview()
        let lab = UILabel()
        lab.translatesAutoresizingMaskIntoConstraints = false
        lab.text = "Error!"
        lab.textColor = UIColor.gray
        view.addSubview(lab)
        lab.sizeToFit()
        let centerX = NSLayoutConstraint(item: lab, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
        let centerY = NSLayoutConstraint(item: lab, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0)
        view.addConstraints([centerX,centerY])
        NSLayoutConstraint.activate([centerX,centerY])
    }
    func pageIndex(for viewController:RxEpubViewController)->Int?{
        return RxEpubReader.shared.book.value?.spine.spineReferences.map{$0.id}.firstIndex(of: viewController.resource.id)
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
        guard let vc = viewController as? RxEpubViewController,let index = pageIndex(for: vc) else {
            return nil
        }
        return epubViewController(at: index + 1)
    }
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? RxEpubViewController,let index = pageIndex(for: vc) else {
            return nil
        }
        return epubViewController(at: index - 1)
    }
    public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        pageViewController.view.isUserInteractionEnabled = false
    }
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if finished && completed,
            let vc = pageViewController.viewControllers?.first as? RxEpubViewController,
            let index = pageIndex(for: vc) {
            let shouldSrollToBottom = RxEpubReader.shared.currentChapter.value>index
            if shouldSrollToBottom{
                vc.webView.scrollsToBottom()
            }
            RxEpubReader.shared.currentChapter.accept(index)
        }
        pageViewController.view.isUserInteractionEnabled = true
    }
}
