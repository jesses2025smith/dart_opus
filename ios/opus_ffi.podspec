#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint opus_ffi.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'opus_ffi'
  s.version          = '0.0.1'
  s.summary          = 'Opus ffi plugin project.'
  s.description      = <<-DESC
Opus ffi plugin project.
                       DESC
  s.homepage         = 'https://github.com/jesses2025smith/dart_opus.git'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Jesse Smith' => 'jesses2025smith@gmail.com' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.vendored_frameworks = 'Libraries/opus_ffi.xcframework'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
