//
//  RxEpubViewController.swift
//  RxEpub
//
//  Created by zhoubin on 2018/7/19.
//

import UIKit
import RxSwift
class RxEpubViewController: UIViewController {

    var resource:Resource!
    let webView = RxEpubWebView()
    let titleLab = UILabel()
    let batteryIndicator = BatteryView()
    let timeLab = UILabel()
    let color = UIColor(hexString: "#818181")!
    let disposeBag = DisposeBag()
    weak var timer:Timer? = nil
    init(resource:Resource){
        super.init(nibName: nil, bundle: nil)
        self.resource = resource
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTitle()
        setUpWebView()
        setUpBattery()
        setUpTimeLab()
        setUpGesture()
        loadData()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        updateTime()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }
    func setUpTitle(){
        view.addSubview(titleLab)
        titleLab.translatesAutoresizingMaskIntoConstraints = false
        let left1 = NSLayoutConstraint(item: titleLab, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 20)
        let right1 = NSLayoutConstraint(item: titleLab, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: -20)
        let top1 = NSLayoutConstraint(item: titleLab, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 10)
        let height1 = NSLayoutConstraint(item: titleLab, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: 20)
        titleLab.addConstraint(height1)
        view.addConstraints([left1,right1,top1])
        titleLab.textColor = color
        titleLab.font = UIFont.systemFont(ofSize: 15)
        webView.rx.title
            .bind(to: titleLab.rx.text)
            .disposed(by: disposeBag)
    }
    func setUpTimeLab(){
        view.addSubview(timeLab)
        timeLab.translatesAutoresizingMaskIntoConstraints = false
        let right4 = NSLayoutConstraint(item: timeLab, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: -20)
        let bottom4 = NSLayoutConstraint(item: timeLab, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: -10)
        let height4 = NSLayoutConstraint(item: timeLab, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: 20)
        timeLab.addConstraints([height4])
        view.addConstraints([right4,bottom4])
        
        timeLab.textColor = color
        timeLab.font = UIFont.systemFont(ofSize: 15)
    }
    @objc func updateTime(){
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        let fmtStr = fmt.string(from: Date())
        timeLab.text = fmtStr
        batteryIndicator.level = Int(UIDevice.current.batteryLevel * 100)
    }
    func setUpBattery(){
        view.addSubview(batteryIndicator)
        batteryIndicator.translatesAutoresizingMaskIntoConstraints = false
        let left3 = NSLayoutConstraint(item: batteryIndicator, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 20)
        let bottom3 = NSLayoutConstraint(item: batteryIndicator, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: -10)
        let width3 = NSLayoutConstraint(item: batteryIndicator, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 25)
        let height3 = NSLayoutConstraint(item: batteryIndicator, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: 10)
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryIndicator.cornerRadius = 1
        batteryIndicator.backgroundColor = UIColor.clear
        batteryIndicator.borderColor = color
        batteryIndicator.noLevelColor = color
        batteryIndicator.lowLevelColor = color
        batteryIndicator.highLevelColor = color
        batteryIndicator.direction = .maxXEdge
        batteryIndicator.addConstraints([width3,height3])
        view.addConstraints([left3,bottom3])
    }
    
    func setUpWebView(){
        automaticallyAdjustsScrollViewInsets = false
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        let left2 = NSLayoutConstraint(item: webView, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0)
        let right2 = NSLayoutConstraint(item: webView, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: 0)
        let top2 = NSLayoutConstraint(item: webView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 30)
        let bottom2 = NSLayoutConstraint(item: webView, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: -30)
        view.addConstraints([left2,right2,top2,bottom2])
        view.layoutIfNeeded()
    }
    func loadData(){
        if let url = resource.url{
            let req = URLRequest(url: url)
            webView.load(req)
        }
    }
    func setUpGesture(){
        let gs = UITapGestureRecognizer(target: self, action: #selector(tap))
        gs.delegate = self
        view.addGestureRecognizer(gs)
    }
    @objc func tap(){
        RxEpubReader.shared.clickCallBack?()
    }
    deinit {
        timer?.invalidate()
        timer = nil
    }
}
extension RxEpubViewController:UIGestureRecognizerDelegate{
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer {
            return true
        }
        return false
    }
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
