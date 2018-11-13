//
//  ViewController.swift
//  RxEpub
//
//  Created by izhoubin on 03/26/2018.
//  Copyright (c) 2018 izhoubin. All rights reserved.
//

import UIKit
import RxEpub
import RxSwift
class ViewController: UIViewController {
    let bag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //1. Load local epub
        //let url = Bundle.main.url(forResource: "330151", withExtension: "epub")!
        
        //2. Load local epub (unziped)
        //let url = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("Epubs").appendingPathComponent("330151")!
        
        //3. Load remote epub
        let url = URL(string: "http://d18.ixdzs.com/113/113933/113933.epub")!
        //let url = URL(string: "http://localhost/330151.epub")!
        
        //4. Load remote epub （unziped）
        //let url =  URL(string:"http://localhost/330151")!
//        let url = URL(string:"http://mebookj.magook.com/epub1/14887/14887-330151/330151_08e3035f")!
        
        let vc = RxEpubPageController(url:url)
        navigationController?.pushViewController(vc, animated: true)
        RxEpubReader.shared.config.backgroundColor.value = "#C7EDCC"
        RxEpubReader.shared.config.textColor.value = "#888888"
        RxEpubReader.shared.config.fontSize.value = 14
        RxEpubReader.shared.config.logEnabled = false
        RxEpubReader.shared.clickCallBack = {[weak self] in
            let isHidden = self?.navigationController?.isNavigationBarHidden ?? false
            self?.navigationController?.setNavigationBarHidden(!isHidden, animated: true)
//            UIApplication.shared.isStatusBarHidden = !isHidden
        }
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "目录", style: UIBarButtonItem.Style.plain, target: self, action: #selector(openCatalog))
        RxEpubReader.shared.currentChapter.asObservable().subscribe(onNext: { (chapter) in
            print("chapter: \(chapter)")
        }).disposed(by: bag)
        
        RxEpubReader.shared.currentPage.asObservable().subscribe(onNext: { (page) in
            print("page: \(page)")
        }).disposed(by: bag)
    }
    @objc func openCatalog(){
        let vc = RxEpubCatalogViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

