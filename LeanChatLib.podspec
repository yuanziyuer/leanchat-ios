Pod::Spec.new do |s|
  s.name         = "LeanChatLib"
  s.version      = "0.1.0"
  s.summary      = "An IM App like WeChat App has to send text, pictures, audio, video, location messaging, managing address book, more interesting features."
  s.homepage     = "https://github.com/leancloud/leanchat-ios"
  s.license      = "MIT"
  s.authors      = { "LeanCloud" => "support@leancloud.cn" }
	s.ios.vendored_frameworks = 'LeanChatLib/Frameworks/AVOSCloud.framework','LeanChatLib/Frameworks/AVOSCloudIM.framework'
  s.source       = { :git => "https://github.com/leancloud/leanchat-ios.git", :tag => "0.1.0" }
  s.frameworks   = 'Foundation', 'CoreGraphics', 'UIKit', 'MobileCoreServices', 'AVFoundation', 'CoreLocation', 'MediaPlayer', 'CoreMedia', 'CoreText', 'AudioToolbox','MapKit','ImageIO','SystemConfiguration','CFNetwork','QuartzCore','Security','CoreTelephony'
  s.platform     = :ios, '7.0'
  s.source_files = 'LeanChatLib/Classes/**/*.{h,m}'
  s.resources    = 'LeanChatLib/Resources/*'
	s.libraries    = 'icucore'
  s.requires_arc = true
end
