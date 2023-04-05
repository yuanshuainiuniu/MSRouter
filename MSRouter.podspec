#
# Be sure to run `pod lib lint ZRouter.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MSRouter'
  s.version          = '0.2.3'
  s.summary          = 'swift路由组件'


  s.homepage         = 'https://github.com/yuanshuainiuniu/MSRouter.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Marshal' => '717999274@qq.com' }
  s.source           = { :git => 'https://github.com/yuanshuainiuniu/MSRouter.git', :tag => s.version }
  s.ios.deployment_target = '9.0'
  s.source_files = 'MSRouter/Classes/**/*'
  s.resource_bundles = {
      s.name => 'MSRouter/Assets/**/*'
  }
  s.swift_version         = "5.0"
  
end
