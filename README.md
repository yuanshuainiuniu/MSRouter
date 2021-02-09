# MSRouter

[![CI Status](https://img.shields.io/travis/717999274@qq.com/ZRouter.svg?style=flat)](https://travis-ci.org/717999274@qq.com/ZRouter)
[![Version](https://img.shields.io/cocoapods/v/ZRouter.svg?style=flat)](https://cocoapods.org/pods/ZRouter)
[![License](https://img.shields.io/cocoapods/l/ZRouter.svg?style=flat)](https://cocoapods.org/pods/ZRouter)
[![Platform](https://img.shields.io/cocoapods/p/ZRouter.svg?style=flat)](https://cocoapods.org/pods/ZRouter)

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
//手动注册路由,如果已经被注册过，返回注册失败的路由地址
MSRouter.addRouter(withParams: ["url":"vc1","object":"V1RouterBridge"], forModule: moduleName) { (res) in
    print("注册失败的链接：\(res)")
    
    
}
//通过配置文件注册路由，如果已经被注册过，返回注册失败的路由地址
let path = Bundle.main.path(forResource: "router", ofType: "plist")
MSRouter.addRouter(withPlistPath: path, forModule: moduleName) { (res) in
    print("注册失败的链接：\(res)")
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
```

## Author

717999274@qq.com, Marshal

## License

MSRouter is available under the MIT license. See the LICENSE file for more info.
