#
# Be sure to run `pod lib lint DURabbitManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DURabbitManager'
  s.version          = '1.0.0'
  s.summary          = 'An easy to use RabbitMQ integration to be used in iOS apps'
  s.description      = 'This repository contains source code of the RabbitMQ Objective C client. The client is maintained by the Duriana team at Duriana Internet.'
  s.homepage         = 'https://github.com/duriana/DURabbitManager'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'iamariffikri@hotmail.com' => 'iamariffikri@hotmail.com' }
  s.source           = { :git => 'https://github.com/duriana/DURabbitManager.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/durianaapp'

  s.ios.deployment_target = '8.0'

  s.source_files = 'DURabbitManager/Classes/**/*'

  s.public_header_files = 'Pod/Headers/**/*.h'
  s.vendored_libraries = 'DURabbitManager/Library/libDURabbit.a'

end
