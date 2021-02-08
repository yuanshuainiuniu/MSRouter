//
//  ViewController2.swift
//  ZRouter_Example
//
//  Created by marshal on 2021/2/7.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

class ViewController2: UIViewController {

    
    
    var callBack:((String)->())?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        // Do any additional setup after loading the view.
        if let request = self.ms_routerRequest {
            if let params = request.params{
                self.navigationItem.title = params["title"] as? String
            }
            if let nativeParams = request.nativeParams,let block = nativeParams["callback"] as? ((String)->()){
                callBack = block
            }
            
        }
    }

    @IBAction func click(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)

        callBack?("返回了---")
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    
}
