Pod::Spec.new do |s|
  s.name             = "Segment-Kahuna"
  s.version          = "1.0.0"
  s.summary          = "Kahuna's wrapper for Segment's analytics-ios library."

  s.description      = <<-DESC
                       Analytics for iOS provides a single API that lets you
                       integrate with over 100s of tools.

                       This is Kahuna's integration wrapper for Segment's analytics-ios library.
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


  s.dependency 'Analytics', '~> 3.0'
  s.default_subspec = 'Segment-Kahuna'

  s.subspec 'Segment-Kahuna' do |default|
    #This will get bundled unless a subspec is specified
    default.dependency 'Kahuna'
  end


  s.subspec 'StaticLibWorkaround' do |workaround|
    # For users who are unable to bundle static libraries as dependencies
    # you can choose this subspec, but be sure to include the folling in your podfile
    # pod 'Kahuna'
    # Please manually add the following file preserved by Cocoapods to your xcodeproj file
    workaround.preserve_paths = 'Pod/Classes/**/*'
  end

end