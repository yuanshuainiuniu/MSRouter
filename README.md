# MSRouter

[![CI Status](https://img.shields.io/travis/717999274@qq.com/ZRouter.svg?style=flat)](https://travis-ci.org/717999274@qq.com/ZRouter)
[![Version](https://img.shields.io/cocoapods/v/ZRouter.svg?style=flat)](https://cocoapods.org/pods/ZRouter)
[![License](https://img.shields.io/cocoapods/l/ZRouter.svg?style=flat)](https://cocoapods.org/pods/ZRouter)
[![Platform](https://img.shields.io/cocoapods/p/ZRouter.svg?style=flat)](https://cocoapods.org/pods/ZRouter)

## 为什么需要路由？
这里笼统的介绍了下组件化开发的场景，路由作为中介组件，我单独剥离出来，提供一种解题思路
https://mp.weixin.qq.com/s/Lz7JbiN-ccMSg0F-afzTUg

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

MSRouter is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'MSRouter'
```
## 注册路由
```swift
//1.手动注册路由,如果已经被注册过，返回注册失败的路由地址
//参数key为固定参数，url：注册链接，object：路由处理对象的classString
//因swift存在命名空间，需要配置moduleName，一般为object类所在的target名称，如未配置，默认取 Bundle.main.infoDictionary?["CFBundleExecutable"]
MSRouter.addRouter(withParams: ["url":"vc1","object":"V1RouterBridge"], forModule: moduleName) { (res) in
    print("注册失败的链接：\(res)")
    
    
}
//2.通过配置文件注册路由，如果已经被注册过，返回注册失败的路由地址
//plist为数组类型，[["url":"xx","object":"xxx","module":"xxx"],["url":"xx","object":"xxx","module":"xxx"]]
//因swift存在命名空间，需要配置moduleName，一般为object类所在的target名称，如未配置，默认取 Bundle.main.infoDictionary?["CFBundleExecutable"]

let path = Bundle.main.path(forResource: "router", ofType: "plist")
MSRouter.addRouter(withPlistPath: path, forModule: moduleName) { (res) in
    print("注册失败的链接：\(res)")
}

//3.通过target-action方式注册路由
MSRouter.addRouter(withUrl: "RouterAdapter1", forObject: RouterAdapter(), completed: nil) { (request) in
    let vc = ViewController3()
    MSRouter.getNavigation()?.pushViewController(vc, animated: true)
}
```
## 访问路由
```swift
//路由链接：scheme://host?xx=aa&yy=bb,路由识别通过注册url与scheme://host进行匹配
var callBack = { (data:String) in
    print("----\(data)")
}
MSRouter.handleUrl("vc1?title=vc1&present=0", ["callback":callBack])
MSRouter.handleUrl("vc2?title=vc2", ["callback":callBack])
@IBAction func dosync(_ sender: Any) {
  let res =  MSRouter.callData("CallDataBridge", nil) as? String
    print("同步执行结果\(res ?? "")")
}
    
@IBAction func doAsync(_ sender: Any) {
    MSRouter.asyncCallData("CallDataBridge", nil) { result in
        let res = result as? String
        print("异步同步执行结果\(res ?? "")")
    }
}

//注册类的参数解析后可通过ms_routerRequest进行访问

var callBack:((String)->())?
override func viewDidLoad() {
    super.viewDidLoad()
    if let request = self.ms_routerRequest {
        if let params = request.params{
            self.navigationItem.title = params["title"] as? String
        }
        if let nativeParams = request.nativeParams,let block = nativeParams["callback"] as? ((String)->()){
            callBack = block
        }
        
    }
}
```
## 拦截路由


```swift
//通过MSRouterProtocol协议拦截路由，自定义处理逻辑，注路由拦截类必须继承自NSObject
class V1RouterBridge:NSObject {
    override func ms_handleRouter(_ request: MSRouterRequest) -> Any? {
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

class CallDataBridge:NSObject{
    ///同步方法拦截
    override func ms_handleRouter(_ request: MSRouterRequest) -> Any? {
        return "123"
    }
    ///异步方法拦截
    override func ms_asyncHandleRouter(_ request: MSRouterRequest, callBack: ((Any?) -> (Void))?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            callBack?("1234")
        }
    }
}
```

## Author

717999274@qq.com, Marshal

## License

MSRouter is available under the MIT license. See the LICENSE file for more info.
