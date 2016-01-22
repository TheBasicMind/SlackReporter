#
# Be sure to run `pod lib lint SlackReporter.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = "SlackReporter"
s.version          = "0.6.0"
s.summary          = "A light iOS framework for presenting feedback forms and posting the results to Slack."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!
s.description      = <<-DESC
Slack Reporter provides a light framework allowing the easy presentation of in-App feedback forms and posting the results to Slack. Slack Reporter was developed by Radical Fraction to facilitate gathering Beta user feedback for the Bead Calculator App and can utilise both Webhooks and Slack Bots. The objectives have been 1) Make it light on memory, 2) Have no futher requirements on for third party library dependencies, 3) Make is very easy to Integrate, 4) Provide a good default set forms "out the box"
DESC

s.homepage         = "https://github.com/TheBasicMind/SlackReporter"
s.screenshots      = "http://static1.squarespace.com/static/5321b654e4b0e62e85932885/t/56a0fe36a12f441d60630848/1453391415843/?format=500w", "http://static1.squarespace.com/static/5321b654e4b0e62e85932885/t/56a0fe6ba12f441d60630a7c/1453391468987/?format=500w"
s.license          = 'MIT'
s.author           = { "Paul Lancefield" => "subs@radicalfraction.com" }
s.source           = { :git => "https://github.com/TheBasicMind/SlackReporter.git", :tag => s.version.to_s }
# s.social_media_url = 'https://twitter.com/RadicalFraction'

s.platform     = :ios, '8.3'
s.requires_arc = true

s.source_files = 'Pod/Classes/**/*'
s.resource_bundles = {
'SlackReporter' => ['Pod/Assets/*.png']
}

s.public_header_files = 'Pod/Classes/**/*.h'
# s.frameworks = 'UIKit', 'MapKit'
# s.dependency 'AFNetworking', '~> 2.3'
end
