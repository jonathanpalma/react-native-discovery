require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = "RNDiscovery"
  s.version      = package['version']
  s.summary      = package['description']

  s.homepage     = package['repository']['url']

  s.license      = package['license']
  s.authors      = package['author']
  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '10.0'

  s.source       = { :git => "https://github.com/N3TC4T/react-native-discovery.git" }

  s.source_files	= "ios/**/*.{h,m}"

  s.dependency 'React'
end