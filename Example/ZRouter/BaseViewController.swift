//
//  BaseViewController.swift
//  ZRouter_Example
//
//  Created by marshal on 2021/2/26.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    deinit {
        print("\(self.classForCoder)--deinit")
    }
}
