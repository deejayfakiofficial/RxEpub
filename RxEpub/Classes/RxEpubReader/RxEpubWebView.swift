//
//  RxEpubWebView.swift
//  RxEpub
//
//  Created by zhoubin on 2018/4/3.
//

import UIKit
import WebKit
import RxSwift
import RxCocoa
public class RxEpubWebView: WKWebView {
    enum ScrollDestination {
        case top
        case bottom
    }
    var tapCallBack:(()->())? = nil
    let indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    let bag = DisposeBag()
    let scrollSubject = PublishSubject<ScrollDestination>()
    var totalPage:BehaviorRelay<Int> = BehaviorRelay(value: 0)
    let disposeBag = DisposeBag()
    public convenience init(frame:CGRect) {
        let js = """
        var html = document.querySelector('html');
        
        html.style['-webkit-column-width']=window.innerWidth+'px'
        html.style['color']='\(RxEpubReader.shared.config.textColor.value)';
        html.style['font-size']='\(Int(RxEpubReader.shared.config.fontSize.value/3.0*4.0))'+'px';
        
        var head = document.querySelector('head');

        var meta = document.createElement('meta');
        meta.setAttribute('name', 'viewport');
        meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
        head.appendChild(meta);
        
        var link = document.createElement('link');
        link.setAttribute('rel', 'stylesheet');
        link.setAttribute('href', 'https://RxEpub/Style.css');
        head.appendChild(link);
        
        var body = document.querySelector('body');
        

        var script = document.createElement('script');
        script.setAttribute('type', 'text/javascript');
        script.setAttribute('src', 'https://RxEpub/Bridge.js');
        body.appendChild(script);
        
        var a = document.querySelector('a');
        
        if (a){
            a['color']='\(RxEpubReader.shared.config.textColor.value)';
            a.style['font-size']='\(Int(RxEpubReader.shared.config.fontSize.value/3.0*4.0))'+'px'
        }
        
        document.documentElement.style.webkitTouchCallout='none';
        
        """
        
        let uerScript = WKUserScript(source: js, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
        let controller = WKUserContentController()
        controller.addUserScript(uerScript)
        
        let config = WKWebViewConfiguration()
        config.userContentController = controller
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.allowsInlineMediaPlayback = true
        config.preferences.javaScriptEnabled = true
        //        config.preferences.minimumFontSize = 15
        config.processPool = WKProcessPool()
        
        if #available(iOS 10.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = .init(rawValue: 0)
        } else {
            config.requiresUserActionForMediaPlayback = false
        }
        self.init(frame: frame, configuration: config)
        controller.add(self, name: "Native")
        
        setUpUI()
        setUpRx()
    }
    func setUpUI(){
        isOpaque = false
        uiDelegate = self
        navigationDelegate = self
        scrollView.bounces = false
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = UIColor.clear
        if #available(iOS 11, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            
        }
        indicator.hidesWhenStopped = true
        addSubview(indicator)
    }
    func setUpRx(){
        Observable.merge(scrollView.rx.didEndDecelerating.asObservable(),
                         scrollView.rx.didEndScrollingAnimation.asObservable())
            .subscribe(onNext: {[weak self] (_) in
                guard let sf = self else{
                    return
                }
                sf.catulatePage()
            }).disposed(by: bag)
        
        NotificationCenter.default.rx.notification(UIApplication.didChangeStatusBarOrientationNotification).subscribe(onNext: {[weak self] (_) in
            self?.reload()
        }).disposed(by: disposeBag)
        
        Observable.combineLatest(scrollSubject, totalPage).subscribe(onNext: {[weak self] in
            if $1>0 && $0 == .bottom{
                self?.scrollTo(page: $1)
            }else{
                self?.scrollTo(page: 0)
            }
        }).disposed(by:bag)
    }
    func catulatePage(){
        let js = "document.documentElement.scrollLeft"
        evaluateJavaScript(js, completionHandler: {[weak self](left ,error) in
            if let left = left as? CGFloat,let sf = self{
                let pageIndex = left/sf.scrollView.frame.width
                RxEpubReader.shared.currentPage.accept(Int(pageIndex))
            }
            
        })
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        indicator.center = CGPoint(x: self.center.x, y: self.center.y - 30)
    }
    
    public override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    @discardableResult
    public override func load(_ request: URLRequest) -> WKNavigation? {
        indicator.startAnimating()
        return super.load(request)
    }
}
extension RxEpubWebView:WKUIDelegate,WKNavigationDelegate{
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        
    }
    //Alert弹框
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        if UIApplication.shared.keyWindow?.rootViewController?.presentedViewController != nil {
            completionHandler()
            return
        }
        let alert = UIAlertController(title: "温馨提示", message: message, preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: "确定", style: UIAlertAction.Style.cancel) { (_) in
            completionHandler()
        }
        alert.addAction(action)
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    //confirm弹框
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "温馨提示", message: message, preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: "确定", style: UIAlertAction.Style.default) { (_) in
            completionHandler(true)
        }
        let cancelAction = UIAlertAction(title: "取消", style: UIAlertAction.Style.cancel) { (_) in
            completionHandler(false)
        }
        
        alert.addAction(action)
        alert.addAction(cancelAction)
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    //TextInput弹框
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: "", message: nil, preferredStyle: UIAlertController.Style.alert)
        alert.addTextField { (_) in}
        let action = UIAlertAction(title: "确定", style: UIAlertAction.Style.default) { (_) in
            completionHandler(alert.textFields?.last?.text)
        }
        alert.addAction(action)
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
//        print("didFailProvisionalNavigation:",error)
    }
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
//        print("didFailnavigation:",error)
    }
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        indicator.stopAnimating()
        webView.evaluateJavaScript("document.documentElement.scrollWidth") {[weak self] (width, err) in
            if let width = width as? CGFloat{
                let page = width/UIScreen.main.bounds.width
                self?.totalPage.accept(Int(page))
            }
            self?.catulatePage()
        }
        catulatePage()
    }
    func updateCss(){
        let js = """
        var html = document.querySelector('html');
        html.style['color']='\(RxEpubReader.shared.config.textColor.value)';
        html.style['font-size']='\(Int(RxEpubReader.shared.config.fontSize.value/3.0*4.0))'+'px'
        var a = document.querySelector('a');
        if (a){
            a['color']='\(RxEpubReader.shared.config.textColor.value)';
            a.style['font-size']='\(Int(RxEpubReader.shared.config.fontSize.value/3.0*4.0))'+'px'
        }
        """
        evaluateJavaScript(js, completionHandler: {_,err in
            if err != nil{
                Log(err)
            }
        })
    }
    func scrollTo(page:Int){
        print(page)
        let offset = UIScreen.main.bounds.width*CGFloat(page)
        let js = "document.documentElement.scrollLeft=\(offset)"
        evaluateJavaScript(js, completionHandler: nil)
    }
    
    func scrollsToBottom(){
        scrollSubject.onNext(.bottom)
    }
    func scrollsToTop(){
        scrollSubject.onNext(.top)
    }
}
extension RxEpubWebView:WKScriptMessageHandler{
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("message",message.body)
    }
}
