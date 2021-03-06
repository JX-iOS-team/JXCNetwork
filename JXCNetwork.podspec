#
# Be sure to run
# `pod lib lint JXCNetwork.podspec`
#  to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# 
# push :
# `pod trunk push JXCNetwork.podspec`
#

Pod::Spec.new do |s|
  s.name             = 'JXCNetwork'
  s.version          = '0.1.3'
  s.summary          = 'JXCNetwork is a lightweight and high level request kit based on AFNetworking.'

  s.description      = <<-DESC
            JXCNetwork is a lightweight and high level request kit based on AFNetworking 3.x, Enjoy it!
                       DESC

  s.homepage         = 'https://github.com/JX-iOS-team/JXCNetwork'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'otnp50' => 'otnp50@hotmail.com' }
  s.source           = { :git => 'https://github.com/JX-iOS-team/JXCNetwork.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'JXCNetwork/Classes/**/*'
  
  # s.resource_bundles = {
  #   'JXCNetwork' => ['JXCNetwork/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'AFNetworking', '~> 3.0'
end
