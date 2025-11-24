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
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Jesse Smith' => 'jesses2025smith@gmail.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.vendored_libraries = 'Libraries/**/*.dylib'
  s.preserve_paths = 'Libraries'

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'opus_ffi_privacy' => ['Resources/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  build_script = <<-SCRIPT
    set -euo pipefail
    "${PODS_TARGET_SRCROOT}/../tool/build_apple.sh"
  SCRIPT

  s.script_phases = [
    {
      :name => 'Build Rust opus_ffi library',
      :execution_position => :before_compile,
      :shell_path => '/bin/bash',
      :script => build_script,
    },
  ]
end
