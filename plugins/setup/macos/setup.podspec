Pod::Spec.new do |s|
  s.name             = 'setup'
  s.version          = '0.0.1'
  s.summary          = 'Panorama Secure Access Go core build harness'
  s.description      = <<-DESC
Panorama Secure Access Go core build harness (FFI plugin).
                       DESC
  s.homepage         = 'https://panorama-sg.com/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Publishing Society Group' => 'wainixueer3334@gmail.com' }
  s.module_name      = 'setup'
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '11.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  s.script_phase = {
    :name => 'Build Go core',
    :script => 'sh "$PODS_TARGET_SRCROOT/../buildkit/build_pod.sh"',
    :execution_position => :before_compile,
    :input_files => ['${BUILT_PRODUCTS_DIR}/buildkit_phony'],
    :output_files => ["${SRCROOT}/../libclash/macos/PSGCore"],
  }
end
