# MSRouter

[![CI Status](https://img.shields.io/travis/717999274@qq.com/ZRouter.svg?style=flat)](https://travis-ci.org/717999274@qq.com/ZRouter)
[![Version](https://img.shields.io/cocoapods/v/ZRouter.svg?style=flat)](https://cocoapods.org/pods/ZRouter)
[![License](https://img.shields.io/cocoapods/l/ZRouter.svg?style=flat)](https://cocoapods.org/pods/ZRouter)
[![Platform](https://img.shields.io/cocoapods/p/ZRouter.svg?style=flat)](https://cocoapods.org/pods/ZRouter)

## 需要解决的问题

首先思考如下的问题，平时我们开发中是如何优雅的解决的：


2.1.3D-Touch功能或者点击推送消息，要求外部跳转到App内部一个很深层次的一个界面。
比如3D-Touch可以直接跳转到“我的二维码名片”。“我的二维码名片”界面在我的里面的第三级界面。或者再极端一点，产品需求给了更加变态的需求，要求跳转到App内部第n层的界面，怎么处理？

2.2.自家的一系列App之间如何相互跳转？
如APP1使用APP2授权登录怎么处理？

2.3.如何解除App组件之间和App页面之间的耦合性？
随着项目越来越复杂，各个组件，各个页面之间的跳转逻辑关联性越来越多，如何能优雅的解除各个组件和页面之间的耦合性？

2.4.如何能统一iOS和Android两端的页面跳转逻辑？甚至如何能统一三端的请求资源的方式？
项目里面某些模块会混合ReactNative，H5界面，这些界面还会调用Native的界面，以及Native的组件。那么，如何能统一Web端和Native端请求资源的方式？

2.5.如果使用了动态下发配置文件来配置App的跳转逻辑，那么如果做到iOS和Android两边只要共用一套配置文件？

2.6.如果App出现bug了，如何不用JSPatch，就能做到简单的热修复功能？
比如App上线突然遇到了紧急bug，能否把页面动态降级成H5，ReactNative？或者是直接换成一个本地的错误界面？

2.7.如何在每个组件间调用和页面跳转时都进行埋点统计？每个跳转的地方都手写代码埋点？利用Runtime AOP ？

2.8.如何在每个组件间调用的过程中，加入调用的逻辑检查，令牌机制，配合灰度进行风控逻辑？

2.9.如何在App任何界面都可以调用同一个界面或者同一个组件？只能在AppDelegate里面注册单例来实现？
比如App出现问题了，用户可能在任何界面，如何随时随地的让用户强制登出？或者强制都跳转到同一个本地的error界面？或者跳转到相应的H5，ReactNative界面？如何让用户在任何界面，随时随地的弹出一个View ？

这些都是实践过程中遇到的客观问题，为了解决这些问题我们经过多次迭代演变成现有的app架构，大部分问题通过路由组件都能友好的解决掉

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
MSRouter.addRouter(withParams: ["url":"vc1","object":"V1RouterBridge"], forModule: moduleName) { (res) in
    print("注册失败的链接：\(res)")
    
    
}
//2.通过配置文件注册路由，如果已经被注册过，返回注册失败的路由地址
//plist为数组类型，[["url":"xx","object":"xxx"],["url":"xx","object":"xxx"]]
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
