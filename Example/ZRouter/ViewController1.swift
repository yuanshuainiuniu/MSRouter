//
//  ViewController1.swift
//  ZRouter_Example
//
//  Created by marshal on 2021/2/7.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

class ViewController1: UIViewController {
    
    var callBack:((String)->())?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    

    @IBAction func backAction(_ sender: UIButton) {
        callBack?("携带参数返回了")
        guard let navi = self.navigationController,navi.children.count > 1 else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        navi.popViewController(animated: true)

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

class V1RouterBridge:NSObject {
    override func ms_handleRouter(_ request: MSRouterRequest) -> MSRouterResponse? {
        let res = MSRouterResponse()
        res.object = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "ViewController1")
        request.presented = true
        print("拦截了路由\(String(describing: request.params))")
        if let callback = request.nativeParams?["callback"] as? (String)->(){
            callback("路由被拦截")
        }
        return res
    }
}
