//
//  RxEpubCatalogViewController.swift
//  RxEpub
//
//  Created by zhoubin on 2018/5/7.
//

import UIKit
public class RxEpubCatalogViewController: UIViewController {

    let tableView = UITableView()
    var dataArray:[TocReference] = []
    override public func viewDidLoad() {
        super.viewDidLoad()
        setUpTable()
        RxEpubReader.shared.book.asObservable().unwrap().subscribe(onNext: {[weak self] (book) in
            self?.dataArray = book.tableOfContents
            self?.tableView.reloadData()
        }).disposed(by: rx.disposeBag)
        
        title = "目录"
        view.backgroundColor = UIColor(hexString: RxEpubReader.shared.config.backgroundColor.value)
        
        if self.presentingViewController != nil{
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "关闭", style: UIBarButtonItemStyle.plain, target: self, action: #selector(close))
        }
        
    }
    @objc func close(){
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
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 50
        tableView.estimatedSectionFooterHeight = 0
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        let left = NSLayoutConstraint(item: tableView, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: tableView, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item: tableView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: topLayoutGuide, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: tableView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
        view.addConstraints([left,right,top,bottom])
        
        tableView.rx.itemSelected.subscribe(onNext: {[weak self](indexPath) in
            if let md = self?.dataArray[indexPath.section].children[indexPath.row]{
                RxEpubReader.shared.catalogItemClickCallBack?(md)
                self?.dismiss(animated: true, completion: nil)
            }
        }).disposed(by: rx.disposeBag)
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
        bt.setTitleColor(UIColor(hexString: RxEpubReader.shared.config.textColor.value), for: UIControlState.normal)
        bt.contentHorizontalAlignment = .left
        bt.titleLabel?.font = UIFont.systemFont(ofSize: RxEpubReader.shared.config.fontSize.value)
        let md = dataArray[section]
        bt.setTitle(md.title, for: UIControlState.normal)
        header.addSubview(bt)

        bt.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: {[weak self](_) in
            RxEpubReader.shared.catalogItemClickCallBack?(md)
            self?.close()
        }).disposed(by: rx.disposeBag)

        bt.translatesAutoresizingMaskIntoConstraints = false
        let left = NSLayoutConstraint(item: bt, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: header, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: bt, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: header, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item: bt, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: header, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: bt, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: header, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
        header.addConstraints([left,right,top,bottom])
        return header
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
}
