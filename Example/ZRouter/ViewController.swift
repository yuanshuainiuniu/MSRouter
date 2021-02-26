//
//  ViewController.swift
//  ZRouter
//
//  Created by 717999274@qq.com on 02/07/2021.
//  Copyright (c) 2021 717999274@qq.com. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    var callBack = { (data:String) in
        print("----\(data)")
    }
    

    @IBAction func clickAction(_ sender: UIButton) {
        MSRouter.handleUrl("vc1?title=vc1&present=0", ["callback":callBack])
    }
    @IBAction func clickV2(_ sender: Any) {
        MSRouter.handleUrl("vc2?title=vc2", ["callback":callBack])
    }
    @IBAction func clickV3(_ sender: Any) {
        MSRouter.handleUrl("RouterAdapter1", nil)
//        MSRouter.handleUrl("RouterAdapter2", nil)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

