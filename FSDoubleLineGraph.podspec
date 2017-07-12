#
# Be sure to run `pod lib lint FSDoubleLineGraph.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FSDoubleLineGraph'
  s.version          = '0.2.0'
  s.summary          = 'Addition to FSLineChart repo with htability to plot two lines on one graph.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
See FSLineChart for a better understanding of the basic functions.  This framework is used to create a basic line graph with two sets of data.  It also has the added option to 'shift' the second line plot along the x axis.'
                       DESC

  s.homepage         = 'https://github.com/Connorrr/DoubleFSLineChart.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Connor Reid' => 'connor.reid87@gmail.com' }
  s.source           = { :git => 'https://github.com/Connorrr/DoubleFSLineChart.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'FSDoubleLineGraph/Classes/**/*'
  
  # s.resource_bundles = {
  #   'FSDoubleLineGraph' => ['FSDoubleLineGraph/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
