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
  s.source_files     = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  
  # Use direct library dependency instead of xcframework for macOS
  # Preserve the dylib file so it can be accessed during build
  s.preserve_paths = 'Libraries/libopus_ffi.dylib'
  
  # Script phase to ensure the dylib is available at runtime
  s.script_phase = {
    :name => 'Setup opus_ffi dylib',
    :script => <<-SCRIPT
      DYLIB_SRC="${PODS_TARGET_SRCROOT}/Libraries/libopus_ffi.dylib"
      if [ -f "${DYLIB_SRC}" ]; then
        # Copy dylib to Frameworks folder
        mkdir -p "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
        cp "${DYLIB_SRC}" "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/libopus_ffi.dylib"
        # Fix install name to use @rpath
        install_name_tool -id "@rpath/libopus_ffi.dylib" "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/libopus_ffi.dylib" 2>/dev/null || true
      fi
    SCRIPT
  }

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'opus_ffi_privacy' => ['Resources/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES',
    'LIBRARY_SEARCH_PATHS' => '$(inherited) $(PODS_TARGET_SRCROOT)/Libraries',
    'OTHER_LDFLAGS' => '$(inherited) -L$(PODS_TARGET_SRCROOT)/Libraries -lopus_ffi',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/../Frameworks'
  }
  s.swift_version = '5.0'
end
