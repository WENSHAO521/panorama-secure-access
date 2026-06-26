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
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
