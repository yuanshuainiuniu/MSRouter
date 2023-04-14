//
//  ZRouter.swift
//  ZRouter_Example
//
//  Created by marshal on 2021/2/7.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

let MSUrl = "url"
let MSObject = "object"
let MSModule = "module"
let MSKey = "key"



/// 发起路由请求类
@objc public class MSRouterRequest:NSObject{
    
    /// 路由完整链接
    public var url:String?
    
    /// 解析后参数
    public var params:[AnyHashable:Any]?{
        didSet{
            if let animated = params?["animate"] as? String,let value = animated.ms_toBool(){
                self.animated = value
            }
            if let presented = params?["presented"] as? String,let value = presented.ms_toBool(){
                self.presented = value
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
    ///请求体
    public var request:MSRouterRequest? = nil
}

/// 路由拦截协议
@objc public protocol MSRouterProtocol:NSObjectProtocol{
    /// 路由处理
    /// - Parameter request:
    @objc optional func ms_handleRouter(_ request:MSRouterRequest) -> Any?
    @objc optional func ms_asyncHandleRouter(_ request:MSRouterRequest,callBack:((_ data:Any?)->(Void))?)
}

@objc public class MSRouter:NSObject {
    
    
    /// 打开路由页面，url注册的object要为UIViewController类型
    /// - Parameters:
    ///   - url: 路由地址
    ///   - nativeParams: {block:回调}
    ///   请在主线程调用
    @discardableResult
    public static func openUrl(_ url:String,_ nativeParams:[AnyHashable:Any]?) -> Any?{
        assert(Thread.isMainThread,"openUrl must called in main thread")
        let response = callData(url, nativeParams) as? MSRouterResponse
        guard let handler = response?.object else { return false }
        var result = false
        if let vc = handler as? UIViewController,let request = response?.request,let navi =  (request.routerFrom ?? getNavigation()){
            vc.ms_routerRequest = request
            if request.presented {
                vc.modalPresentationStyle = request.presentedType
                navi.present(vc, animated: request.animated, completion: nil)
            }else{
                navi.pushViewController(vc, animated: request.animated)
            }
            result = true
        }
        return result
    }
    
    /// 同步执行
    /// - Parameters:
    ///   - url: 执行的key
    ///   - nativeParams: 原生参数
    @discardableResult
    public static func callData(_ url:String,_ nativeParams:[AnyHashable:Any]?) ->Any?{
        sema.wait()
        var handler:Any? = nil
        var response:Any? = nil
        
        if let routerObject = ZRouterManager.shared.routerObjectLsit[url] {
            handler = routerObject
            
        }else if let objectClass = getObjectClass(fromUrl: url) as? NSObject.Type {
            handler = objectClass.init()
        }
        if let delegate:MSRouterProtocol = handler as? MSRouterProtocol{
            let request = MSRouterRequest()
            request.url = url
            request.nativeParams = nativeParams
            request.params = getParams(fromUrl: url)
            
            var mDelegate:MSRouterProtocol = delegate
            if let router = handler as? ZRouterObject{
                if let handleObject = router.object{
                    mDelegate = handleObject
                }
              if let handlerBlock = router.handler{
                    handlerBlock(request)
                    sema.signal()

                    return response
              }
            }
            
            if mDelegate.responds(to: #selector(MSRouterProtocol.ms_handleRouter(_:))) {
                response = mDelegate.ms_handleRouter?(request)
                (response as? MSRouterResponse)?.request = request
            }
            sema.signal()
            return response
        }
        sema.signal()
        return response
    }
    
    /// 异步执行
    /// - Parameters:
    ///   - url
    ///   - nativeParams
    ///   - callBack
    public static func asyncCallData(_ url:String,_ nativeParams:[AnyHashable:Any]?,callBack:((_ result:Any?)->(Void))?){
        
        sema.wait()
        var handler:Any? = nil
        
        if let routerObject = ZRouterManager.shared.routerObjectLsit[url] {
            handler = routerObject
            
        }else if let objectClass = getObjectClass(fromUrl: url) as? NSObject.Type {
            handler = objectClass.init()
        }
        routerQueue.async {
            if let delegate:MSRouterProtocol = handler as? MSRouterProtocol{
                let request = MSRouterRequest()
                request.url = url
                request.nativeParams = nativeParams
                request.params = getParams(fromUrl: url)
                
                var mDelegate:MSRouterProtocol = delegate
                if let router = handler as? ZRouterObject{
                    if let handleObject = router.object{
                        mDelegate = handleObject
                    }
                  if let handlerBlock = router.handler{
                      DispatchQueue.main.async {
                          handlerBlock(request)
                          callBack?(nil)
                      }
                  }
                }else if mDelegate.responds(to: #selector(MSRouterProtocol.ms_asyncHandleRouter(_:callBack:))) {
                    mDelegate.ms_asyncHandleRouter?(request, callBack: { data in
                        DispatchQueue.main.async {
                            callBack?(data)
                        }
                    })
                }
            }
        }
        sema.signal()

    }
    
    /// 获取注册的路由类
    /// - Parameter fromUrl: 路由地址
    /// - Returns: 返回类实例
    public static func getObjectClass(fromUrl:String) -> AnyObject?{
        let routerList = ZRouterManager.shared.routerList
        for item in routerList{
            if let map = item as? [String:Any],let host = getHost(fromUrl: fromUrl) {
                if let url = map[MSUrl] as? String,host == url {
                    if let object = map[MSObject] as? String {
                        var className: AnyClass? = NSClassFromString(object)
                        if className == nil {
                            var moduleName = ""
                            if let module = map[MSModule] as? String,!module.isEmpty {
                                moduleName = module
                            }else{
                                moduleName = Bundle.main.infoDictionary?["CFBundleExecutable"] as? String ?? ""
                                moduleName = moduleName.replacingOccurrences(of: "-", with: "_")
                            }
                            className = NSClassFromString("\(moduleName).\(object)")
                            if className == nil {
                                let ttcname = "_TtC\(moduleName.count)\(moduleName)\(object.count)\(object)"
                                className  = NSClassFromString(ttcname)
                            }
                        }

                        return className
                    }
                }
            }
        }
        
                
        return nil
    }
    
    /// 通过plist列表注册路由
    /// - Parameters:
    ///   - plistPath: plist路径
    ///   plist:{"url","module","object"},url:路由链接，module:命名空间,object:反射的类，优先取配置的module
    ///
    ///   - name: module 名称，为空的话默认主工程module
    ///   - completed: 返回注册失败的路由
    public static func addRouter(withPlistPath plistPath:String?,forModule name:String? = nil,completed:((_ failedUrls:[String])->())? = nil){
        sema.wait()
        routerQueue.async {
            guard let plistPath = plistPath else {
                sema.signal()
                print("MSRouter 路径不能为空")
                return
                
            }
            guard let list = NSArray(contentsOfFile: plistPath) as? [[AnyHashable:Any]] else {
                sema.signal()
                print("MSRouter 检查plist文件是否有问题")

                return
                
            }
            var temp = [String]()
            var moduleName = (name ?? "")
            let routerList = ZRouterManager.shared.routerList
            for item in list{
                if let url = item[MSUrl] as? String{
                    if let defModule = item[MSModule] as? String,defModule.count > 0 {
                        moduleName = defModule
                    }
                    let moduleUrl = url + moduleName
                    for cacheItem in  routerList{
                        if let cacheUrl = cacheItem[MSKey] as? String,cacheUrl == moduleUrl {
                            temp.append(url)
                            break
                        }
                    }
                    var module = item
                    module[MSKey] = moduleUrl
                    module[MSModule] = moduleName
                    ZRouterManager.shared.routerList.append(module)
                }
            }
            sema.signal()
            DispatchQueue.main.async {
                completed?(temp)
            }
        }
    }
    
    /// 注册单个路由
    /// - Parameters:
    ///   - params: {url:String,object:String}
    ///   - name: module 名称，为空的话默认主工程module
    ///   - completed: 返回注册失败的路由
    static let sema = DispatchSemaphore.init(value: 1)
    static let routerQueue = DispatchQueue(label: "com.msrouter.serialQueue")
    public static func addRouter(withParams params:[AnyHashable:Any],forModule name:String? = nil,completed:((_ failedUrls:[String])->())? = nil){
        sema.wait()
        routerQueue.async {
            var temp = [String]()
            let moduleName = (name ?? "")
            if let url = params[MSUrl] as? String{
                let moduleUrl = url + moduleName
                let routerList = ZRouterManager.shared.routerList
                for cacheItem in  routerList{
                    if let cacheUrl = cacheItem[MSKey] as? String,cacheUrl == moduleUrl {
                        temp.append(url)
                        break
                    }
                }
                var module = params
                module[MSKey] = moduleUrl
                module[MSModule] = moduleName
                ZRouterManager.shared.routerList.append(module)
            }
            sema.signal()
            DispatchQueue.main.async {
                completed?(temp)
            }
        }
    }
    
    /// target-action注册路由
    /// - Parameters:
    ///   - url: 路由链接
    ///   - object: target
    ///   - completed: 注册结果
    ///   - handler: action
    public static func addRouter(withUrl url:String,forObject object:NSObject?,completed:((_ success: Bool)->())? = nil,handler:((MSRouterRequest)->())? = nil){
        let manager = ZRouterManager.shared
        routerQueue.async {
            let hasCache = manager.routerObjectLsit[url] != nil
            if !hasCache{
                var router = ZRouterObject()
                router.url = url
                router.object = object
                router.handler = handler
                manager.routerObjectLsit[url] = router
            }
            completed?(!hasCache)
        }
        
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
                let navi = (root as? UITabBarController)?.selectedViewController as? UINavigationController
                let visibleViewControllerNavi = navi?.visibleViewController?.navigationController
                return visibleViewControllerNavi ?? navi
            }else if(root.isKind(of: UINavigationController.self)){
                let navi = root as? UINavigationController
                let visibleViewControllerNavi = navi?.visibleViewController?.navigationController
                return visibleViewControllerNavi ?? navi
            }else if(root.isKind(of: UIViewController.self)){
                let navi = root.navigationController
                let visibleViewControllerNavi = navi?.visibleViewController?.navigationController
                return visibleViewControllerNavi ?? navi
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

/// 路由管理器
class ZRouterManager {
    static let shared = ZRouterManager()
    //private
    
    /// 缓存路由表
    var routerList = [[AnyHashable:Any]]()
    
    /// 缓存路由实例
    var routerObjectLsit = [AnyHashable:ZRouterObject]()
    
}
//
struct ZRouterObject {
    var url:String?
    var object:NSObject?
    var handler:((MSRouterRequest)->())?
}

extension NSObject:MSRouterProtocol{
    open func ms_handleRouter(_ request: MSRouterRequest) -> Any? {
        let response = MSRouterResponse()
        response.object = self
        response.request = request
        return response
    }
    open func ms_asyncHandleRouter(_ request: MSRouterRequest, callBack: ((Any?) -> (Void))?) {
        
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
    @objc class func ms_buldle(forModule name:String,bundleName:String? = nil) -> Bundle? {
        var bundlePath:String?
       if let path = Bundle.main.path(forResource: name, ofType: "bundle") {
           bundlePath = path
       }else{
        var path1 = name
        if path1.contains("-") {
            path1 = path1.replacingOccurrences(of: "-", with: "_")
        }
       
        let fullPath = "Frameworks/" + path1 + ".framework/" + (bundleName ?? name)
           bundlePath = Bundle.main.path(forResource: fullPath, ofType: "bundle")
       }
       return Bundle(path: bundlePath ?? "")
    }
}
public extension String{
    func ms_toBool() -> Bool? {
        switch self {
        case "True","TRUE", "true","YES", "yes", "1":
            return true
        case "False","FALSE", "false","NO", "no", "0":
            return false
        default:
            return nil
        }
    }
}
