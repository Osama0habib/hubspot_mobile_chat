#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint hubspot_mobile_chat.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'hubspot_mobile_chat'
  s.version          = '0.0.1'
  s.summary          = "Flutter plugin wrapping HubSpot's native Mobile Chat SDKs."
  s.description      = <<-DESC
Flutter plugin wrapping HubSpot's native Android & iOS Mobile Chat SDKs.
                       DESC
  s.homepage         = 'https://github.com/debuggersight/hubspot_mobile_chat'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'debuggersight' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'hubspot_mobile_chat/Sources/hubspot_mobile_chat/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # NOTE: HubSpot's iOS Mobile Chat SDK ships via Swift Package Manager, not
  # CocoaPods. The integrating app must add the SPM package
  # (https://github.com/HubSpot/mobile-chat-sdk-ios) so the `HubspotMobileSDK`
  # module resolves at build time. If/when HubSpot publishes a Pod, declare it
  # here with an exact version, e.g.:
  #   s.dependency 'HubspotMobileSDK', '1.0.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'hubspot_mobile_chat_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
