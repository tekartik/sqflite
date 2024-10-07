#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'sqflite_darwin'
  s.version          = '0.0.4'
  s.summary          = 'An iOS and macOS implementation for the sqflite plugin.'
  s.description      = <<-DESC
Access SQLite database.
                       DESC
  s.homepage         = 'https://github.com/tekartik/sqflite/sqflite_darwin'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'Tekartik' => 'alex@tekartik.com' }
  s.source           = { :http => 'https://github.com/tekartik/sqflite/tree/master/sqflite_darwin' }
  s.source_files = 'sqflite_darwin/Sources/sqflite_darwin/**/*.{h,m}'
  s.public_header_files = 'sqflite_darwin/Sources/sqflite_darwin/include/**/*.{h,m}'
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.resource_bundles = {'sqflite_darwin_privacy' => ['sqflite_darwin/Sources/sqflite_darwin/Resources/PrivacyInfo.xcprivacy']}
end

