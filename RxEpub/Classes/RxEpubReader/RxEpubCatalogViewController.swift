//
//  RxEpubCatalogViewController.swift
//  RxEpub
//
//  Created by zhoubin on 2018/5/7.
//

import UIKit
import RxSwift
public class RxEpubCatalogViewController: UIViewController {

    let tableView = UITableView()
    var dataArray:[TocReference] = []
    let disposeBag = DisposeBag()
    override open func viewDidLoad() {
        super.viewDidLoad()
        setUpTable()
        RxEpubReader.shared.book.asObservable().compactMap{$0}.subscribe(onNext: {[weak self] (book) in
            self?.dataArray = book.tableOfContents
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
        
        title = "目录"
        view.backgroundColor = UIColor(hexString: RxEpubReader.shared.config.backgroundColor.value)
        
        if self.presentingViewController != nil{
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "关闭", style: UIBarButtonItem.Style.plain, target: self, action: #selector(close))
        }
        
    }
    @objc open func close(){
        if self.presentingViewController != nil{
            dismiss(animated: true, completion: nil)
        }else{
            navigationController?.popViewController(animated: true)
        }
    }
    func setUpTable(){
        if #available(iOS 11, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        view.addSubview(tableView)
        tableView.backgroundColor = UIColor.clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 50
        tableView.estimatedSectionFooterHeight = 0
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        let left = NSLayoutConstraint(item: tableView, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: tableView, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item: tableView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: topLayoutGuide, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: tableView, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0)
        view.addConstraints([left,right,top,bottom])
        
        tableView.rx.itemSelected.subscribe(onNext: {[weak self](indexPath) in
            if let md = self?.dataArray[indexPath.section].children[indexPath.row]{
                RxEpubReader.shared.catalogItemClickCallBack?(md)
                self?.close()
            }
        }).disposed(by: disposeBag)
    }
}
extension RxEpubCatalogViewController:UITableViewDelegate,UITableViewDataSource{
    public func numberOfSections(in tableView: UITableView) -> Int {
        return dataArray.count
    }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray[section].children.count
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        let md = dataArray[indexPath.section].children[indexPath.row]
        cell.textLabel?.text = md.title
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.textColor = UIColor(hexString: RxEpubReader.shared.config.textColor.value)
        cell.textLabel?.font = UIFont.systemFont(ofSize: RxEpubReader.shared.config.fontSize.value)
        cell.selectionStyle = .none
        return cell
    }
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = UIColor.clear
        let bt = UIButton()
        bt.titleLabel?.numberOfLines = 0
        bt.titleLabel?.lineBreakMode = .byWordWrapping
        bt.setTitleColor(UIColor(hexString: RxEpubReader.shared.config.textColor.value), for: UIControl.State.normal)
        bt.contentHorizontalAlignment = .left
        bt.titleLabel?.font = UIFont.systemFont(ofSize: RxEpubReader.shared.config.fontSize.value)
        let md = dataArray[section]
        bt.setTitle(md.title, for: UIControl.State.normal)
        header.addSubview(bt)

        bt.rx.controlEvent(UIControl.Event.touchUpInside).subscribe(onNext: {[weak self](_) in
            RxEpubReader.shared.catalogItemClickCallBack?(md)
            self?.close()
        }).disposed(by: disposeBag)

        bt.translatesAutoresizingMaskIntoConstraints = false
        let left = NSLayoutConstraint(item: bt, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: header, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: bt, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: header, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item: bt, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: header, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: bt, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: header, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0)
        header.addConstraints([left,right,top,bottom])
        return header
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
}
