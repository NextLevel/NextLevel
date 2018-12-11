Pod::Spec.new do |s|
  s.name = 'NextLevel'
  s.version = '0.13.0'
  s.license = 'MIT'
  s.summary = 'Rad Media Capture in Swift'
  s.homepage = 'https://github.com/nextlevel/NextLevel'
  s.authors = { 'patrick piemonte' => 'patrick.piemonte@gmail.com' }
  s.source = { :git => 'https://github.com/nextlevel/NextLevel.git', :tag => s.version }
  s.ios.deployment_target = '10.0'
  s.source_files = 'Sources/*.swift'
  s.requires_arc = true
  s.swift_version = '4.2'
end
