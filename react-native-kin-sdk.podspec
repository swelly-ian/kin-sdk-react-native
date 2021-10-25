require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-kin-sdk"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "10.0" }
  s.source       = { :git => "https://github.com/kin-sdk/react-native-kin-sdk.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift}"
  s.requires_arc = true

  s.dependency "React"
  s.swift_version = '5'
  s.dependency "KinBase", "~> 2.1.1"

  # s.subspec 'no-arc' do |sna|
    #   sna.requires_arc = false
      # sna.source_files = non_arc_files
      # sna.dependency 'Protobuf', '~> 3.0'
    # end

  s.pod_target_xcconfig = {
      # This is needed by all pods that depend on Protobuf:
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1 GPB_GRPC_FORWARD_DECLARE_MESSAGE_PROTO=1',
      # This is needed by all pods that depend on gRPC-RxLibrary:
      'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
      # This is needed for the user Podfile to use_framework! https://github.com/CocoaPods/CocoaPods/issues/4605
      'USE_HEADERMAP' => 'NO',
      'ALWAYS_SEARCH_USER_PATHS' => 'NO',
      'USER_HEADER_SEARCH_PATHS' => '$(PODS_ROOT)/KinGrpcApi/KinGrpcApi/gen',
      'HEADER_SEARCH_PATHS' => '$(PODS_ROOT)/KinGrpcApi/KinGrpcApi/gen'
  }
  # s.ios.vendored_frameworks = 'KinSDK.xcframework'
end
