//
//  RouterAdapter.swift
//  ZRouter_Example
//
//  Created by marshal on 2021/2/26.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

class RouterAdapter:NSObject {
    static func addRouter(){
        MSRouter.addRouter(withUrl: "RouterAdapter1", forObject: nil, completed: nil) { (request) in
            let vc = ViewController3()
            MSRouter.getNavigation()?.pushViewController(vc, animated: true)
        }
    }
    override init() {
        
    }
}
