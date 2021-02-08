#
# Be sure to run `pod lib lint ZRouter.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ZRouter'
  s.version          = '0.1.0'
  s.summary          = '路由组件'


  s.homepage         = 'https://github.com/yuanshuainiuniu/MSRouter.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Marshal' => 'marshal819@zto.com' }
  s.source           = { :git => 'https://github.com/yuanshuainiuniu/MSRouter.git', :tag => s.version.to }

  s.ios.deployment_target = '9.0'

  s.source_files = 'ZRouter/Classes/**/*'
  
  # s.resource_bundles = {
  #   'ZRouter' => ['ZRouter/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
