#
# Be sure to run `pod lib lint DURabbitManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DURabbitManager'
  s.version          = '0.1.2'
  s.summary          = 'An easy to use RabbitMQ integration to be used in iOS apps'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'This repository contains source code of the RabbitMQ Objective C client. The client is maintained by the Duriana team at Duriana Internet.'

  s.homepage         = 'https://github.com/duriana/DURabbitManager'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'iamariffikri@hotmail.com' => 'iamariffikri@hotmail.com' }
  s.source           = { :git => 'https://github.com/duriana/DURabbitManager.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/durianaapp>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'DURabbitManager/Classes/**/*'
  
  # s.resource_bundles = {
  #   'DURabbitManager' => ['DURabbitManager/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
