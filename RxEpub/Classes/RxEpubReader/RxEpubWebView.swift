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
    var tapCallBack:(()->())? = nil
    let indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    let bag = DisposeBag()
    public convenience init(frame:CGRect) {
        let js = """
        var head = document.querySelector('head');

        var meta = document.createElement('meta');
        meta.setAttribute('name', 'viewport');
        meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
        head.appendChild(meta);

        var script = document.createElement('script');
        script.setAttribute('type', 'text/javascript');
        script.setAttribute('src', 'https://RxEpub/Bridge.js');
        head.appendChild(script);
        
        var link = document.createElement('link');
        link.setAttribute('rel', 'stylesheet');
        link.setAttribute('href', 'https://RxEpub/Style.css');
        head.appendChild(link);

        var html = document.querySelector('html');
        html.style['-webkit-column-width']=window.innerWidth+'px'
        
        html.style['color']='\(RxEpubReader.shared.config.textColor.value)';
        html.style['font-size']='\(Int(RxEpubReader.shared.config.fontSize.value/3.0*4.0))'+'px';
        var a = document.querySelector('a');
        if (a){
            a['color']='\(RxEpubReader.shared.config.textColor.value)';
            a.style['font-size']='\(Int(RxEpubReader.shared.config.fontSize.value/3.0*4.0))'+'px'
        }
        
        document.documentElement.style.webkitTouchCallout='none';
        
        """
        //'html','height: window.innerHeight; -webkit-column-gap: 0px; -webkit-column-width: window.innerWidth;
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
        
        setUpUI()
        setUpRx()
    }
    func setUpUI(){
        isOpaque = false
        uiDelegate = self
        navigationDelegate = self
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
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
                let pageIndex = sf.scrollView.contentOffset.x/sf.scrollView.frame.width
                RxEpubReader.shared.currentPage.value = Int(pageIndex)
            }).disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.UIApplicationDidChangeStatusBarOrientation).subscribe(onNext: {[weak self] (_) in
            self?.reload()
        }).disposed(by: rx.disposeBag)
        
        rx.loading.asObservable().subscribe(onNext: {[weak self] in
            guard let sf = self,!$0 else{
                return
            }
            if RxEpubReader.shared.scrollDirection == .right {
                sf.scrollsToBottom()
            }else{
                sf.scrollsToTop()
            }
            sf.indicator.stopAnimating()
            
        }).disposed(by: rx.disposeBag)
        
        scrollView.rx.contentOffset.subscribe(onNext: {[weak self] in
            guard let sf = self,sf.scrollView.frame.width > 0 else{
                return
            }
            let page = $0.x/sf.scrollView.frame.width
            RxEpubReader.shared.currentPage.value = Int(page)
        }).disposed(by: rx.disposeBag)
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
        let alert = UIAlertController(title: "温馨提示", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "确定", style: UIAlertActionStyle.cancel) { (_) in
            completionHandler()
        }
        alert.addAction(action)
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    //confirm弹框
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "温馨提示", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "确定", style: UIAlertActionStyle.default) { (_) in
            completionHandler(true)
        }
        let cancelAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.cancel) { (_) in
            completionHandler(false)
        }
        
        alert.addAction(action)
        alert.addAction(cancelAction)
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    //TextInput弹框
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: "", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        alert.addTextField { (_) in}
        let action = UIAlertAction(title: "确定", style: UIAlertActionStyle.default) { (_) in
            completionHandler(alert.textFields?.last?.text)
        }
        alert.addAction(action)
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("didFailProvisionalNavigation:",error)
    }
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("didFailnavigation:",error)
    }
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        if RxEpubReader.shared.scrollDirection == .right {
//            scrollsToBottom()
//        }else{
//            scrollsToTop()
//        }
//        indicator.stopAnimating()
//        let page = scrollView.contentOffset.x/scrollView.frame.width
//        Log("p2:\(page)")
//        RxEpubReader.shared.currentPage.value = Int(page)
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
        
        rx.loading.asObservable().subscribe(onNext: {[weak self] in
            guard let sf = self ,!$0 else{
                return
            }
            
            DispatchQueue.main.async {
                let js = """
                document.body.scrollTo(\(sf.scrollView.frame.width * CGFloat(page)),0);
                """
                self?.evaluateJavaScript(js, completionHandler:nil)
            }
        }).disposed(by: rx.disposeBag)
    }
    
    func scrollsToBottom(){
        let js = """
                document.body.scrollTop =  document.body.scrollHeight;
                document.body.scrollLeft =  document.body.scrollWidth;
                """
        evaluateJavaScript(js, completionHandler: nil)
    }
    func scrollsToTop(){
        let js = """
                document.body.scrollTop =  0;
                document.body.scrollLeft =  0;
                """
        evaluateJavaScript(js, completionHandler: nil)
    }
}
