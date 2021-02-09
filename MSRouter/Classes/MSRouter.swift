//
//  ZRouter.swift
//  ZRouter_Example
//
//  Created by marshal on 2021/2/7.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

let ZUrl = "url"
let ZObject = "object"

/// 发起路由请求类
@objc public class MSRouterRequest:NSObject{
    
    /// 路由完整链接
    public var url:String?
    
    /// 解析后参数
    public var params:[AnyHashable:Any]?{
        didSet{
            if let animated = params?["animate"] as? Bool{
                self.animated = animated
            }
            if let presented = params?["presented"] as? Bool{
                self.presented = presented
            }
            if let presentedType = params?["presentedType"] as? String{
                if presentedType  == "auto"{
                    if #available(iOS 13.0, *) {
                        self.presentedType = .automatic
                    } else {
                        // Fallback on earlier versions
                    }
                }else if presentedType  == "overFull"{
                    self.presentedType = .overFullScreen
                }
            }
        }
    }
    
    /// 原生传参
    public var nativeParams:[AnyHashable:Any]?{
        didSet{
            if let navi = nativeParams?["routerFrom"] as? UIViewController{
                routerFrom = navi.navigationController
            }else if let navi = nativeParams?["routerFrom"] as? UINavigationController{
                routerFrom = navi
            }
        }
    }
    
    /// 自定义来源导航
    public var routerFrom:UINavigationController?
    
    /// 是否需要动画
    public var animated:Bool = true
    
    /// 默认是push动画，如需要present，设置此值
    public var presented:Bool = false
    
    /// present样式
    public var presentedType:UIModalPresentationStyle = .fullScreen
}

/// 路由响应处理类
@objc public class MSRouterResponse:NSObject{
    public enum ZRouterType:Int {
        ///页面跳转路由
        case jump = 0
        ///方法路由
        case method = 1
    }
    ///路由处理对象
    public var object:Any? = nil
    
}

/// 路由拦截协议
@objc public protocol MSRouterProtocol:NSObjectProtocol{
    /// 路由处理
    /// - Parameter request:
    @objc optional func handleRouter(_ request:MSRouterRequest) -> MSRouterResponse?
    
}

@objc public class MSRouter:NSObject {
    
    
    /// 处理路由
    /// - Parameters:
    ///   - url: 路由地址
    ///   - nativeParams: {block:回调}
    @discardableResult
    public static func handleUrl(_ url:String,_ nativeParams:[AnyHashable:Any]?) -> Bool?{
        if let objectClass = getObjectClass(fromUrl: url) as? NSObject.Type {//存在注册路由
            var handle:Any? = objectClass.init()
            let request = MSRouterRequest()
            request.url = url
            request.nativeParams = nativeParams
            request.params = getParams(fromUrl: url)
            
            
            if let delegate:MSRouterProtocol = handle as? MSRouterProtocol{
                if delegate.responds(to: #selector(MSRouterProtocol.handleRouter(_:))) {
                    if let response = delegate.handleRouter?(request) {
                        handle = response.object
                    }
                }
                
            }
            if let vc = handle as? UIViewController,let navi = getNavigation(){
                vc.ms_routerRequest = request
                if request.presented {
                    vc.modalPresentationStyle = request.presentedType
                    navi.present(vc, animated: request.animated, completion: nil)
                }else{
                    navi.pushViewController(vc, animated: request.animated)
                }
            }
            
            return true
        }
        return false
    }
    
    /// 获取注册的路由类
    /// - Parameter fromUrl: 路由地址
    /// - Returns: 返回类实例
    public static func getObjectClass(fromUrl:String) -> AnyObject?{
        for item in ZRouterManager.shared.routerList {
            if let map = item as? [String:Any],let host = getHost(fromUrl: fromUrl) {
                if let url = map[ZUrl] as? String,host == url {
                    if let object = map[ZObject] as? String {
                        let workName = Bundle.main.infoDictionary?["CFBundleExecutable"] as! String
                        return NSClassFromString("\(workName).\(object)")
                    }
                }
            }
        }
        return nil
    }
    
    /// 通过plist列表注册路由
    /// - Parameter PlistPath: plist路径
    public static func addRouter(withPlistPath plistPath:String?){
        guard let plistPath = plistPath else { return }
        guard let list = NSArray(contentsOfFile: plistPath) as? [[AnyHashable:Any]] else { return }
        ZRouterManager.shared.routerList.append(contentsOf: list)
    }
    
    /// 注册单个路由
    /// - Parameter params: {url:String,object:String}
    public static func addRouter(withParams params:[AnyHashable:Any]){
        ZRouterManager.shared.routerList.append(params)
    }
    
    /// 获取当前栈导航控制器
    /// - Returns: 导航
    public static func getNavigation() -> UINavigationController?{
        var currentWindow = UIApplication.shared.delegate?.window
        if currentWindow == nil {
            if #available(iOS 13.0, *) {
                currentWindow = (UIApplication.shared.connectedScenes.first?.delegate as? UIWindowSceneDelegate)?.window
            } else {
                // Fallback on earlier versions
            }
            if currentWindow == nil {
                currentWindow = UIApplication.shared.keyWindow
            }
        }
        
        if let window = currentWindow,let root = window?.rootViewController {
            if var presentVC = root.presentedViewController,presentVC.isKind(of: UIAlertController.self){
                while presentVC.presentedViewController != nil {
                    if presentVC.isKind(of: UINavigationController.self) {
                        break
                    }
                    presentVC = presentVC.presentedViewController!
                }
                return presentVC as? UINavigationController
            }
            if root.isKind(of: UITabBarController.self) {
                return (root as? UITabBarController)?.selectedViewController as? UINavigationController
            }else if(root.isKind(of: UINavigationController.self)){
                return root as? UINavigationController
            }
        }
        return nil
    }
    
    
    /// 通过url解析参数
    /// - Parameter url: url
    /// - Returns: [key:value]
    private static func getParams(fromUrl url:String) -> [String:Any]?{
        let urls = url.components(separatedBy: "?")
        if urls.count > 1 {
            let urlParams = urls.last
            var params = [String:Any]()
            if let keyValues = urlParams?.components(separatedBy: "&") {
                for keyValue in keyValues {
                    let kv = keyValue.components(separatedBy: "=")
                    if kv.count == 2,let key = kv.first {
                        params[key] = kv.last?.removingPercentEncoding
                    }
                }
            }
            return params
        }
        return nil
    }
    
    /// 通过url获取路由
    /// - Parameter url: url
    /// - Returns: 返回路由string，用于匹配路由表
    private static func getHost(fromUrl url:String) -> String?{
        return url.components(separatedBy: "?").first
    }
    
    
}

class ZRouterManager {
    
    static let shared = ZRouterManager()
    //private
    var routerList = [[AnyHashable:Any]]()
    
}

extension NSObject:MSRouterProtocol{
    public func handleRouter(_ request: MSRouterRequest) -> MSRouterResponse? {
        let response = MSRouterResponse()
        response.object = self
        return response
    }

    public var ms_routerRequest:MSRouterRequest?{
        get{
            return objc_getAssociatedObject(self, AssociateKeys.ms_routerKey) as? MSRouterRequest
        }
        set{
            objc_setAssociatedObject(self, AssociateKeys.ms_routerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    private struct AssociateKeys{
        static let ms_routerKey = UnsafeRawPointer(bitPattern: "_buttfly_ms_routerKey".hashValue)!
    }
}
public extension Bundle{
    @objc class func ms_buldle(forModule name:String!) -> Bundle? {
        var bundlePath:String?
       if let path = Bundle.main.path(forResource: name, ofType: "bundle") {
           bundlePath = path
       }else{
        var path1 = name
        if path1!.contains("-") {
            path1 = path1!.replacingOccurrences(of: "-", with: "_")
        }
        let fullPath = "Frameworks/" + path1! + ".framework/" + name
        
           bundlePath = Bundle.main.path(forResource: fullPath, ofType: "bundle")
       }
       return Bundle(path: bundlePath ?? "")
    }
}
