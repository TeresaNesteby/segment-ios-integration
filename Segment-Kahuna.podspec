Pod::Spec.new do |s|
  s.name             = "Segment-Kahuna"
  s.version          = "1.0.0"
  s.summary          = "Kahuna's segment wrapper for iOS library."

  s.description      = <<-DESC
                       Kahuna's wrapper integration for Segment's analytics-ios library.
                       DESC

  s.homepage         = "http://kahuna.com/"
  s.license      = {
    :type => 'Commercial',
    :text => <<-LICENSE
              All text and design is copyright © 2012-2016 Kahuna, Inc.

              All rights reserved.

              http://www.kahuna.com/privacy/
    LICENSE
  }
  s.author           = { "Kahuna" => "support@kahuna.com" }
  s.source           = { :git => "https://github.com/Kahuna/segment-ios-integration.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'

  s.dependency 'Analytics'
  s.dependency 'Kahuna'
end
