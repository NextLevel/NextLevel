Pod::Spec.new do |s|
  s.name = 'NextLevel'
  s.version = '0.3.3'
  s.license = 'MIT'
  s.summary = 'Rad Media Capture in Swift'
  s.homepage = 'https://github.com/nextlevel/NextLevel'
  s.authors = { 'patrick piemonte' => 'piemonte@alumni.cmu.edu' }
  s.source = { :git => 'https://github.com/nextlevel/NextLevel.git', :tag => s.version }
  s.ios.deployment_target = '9.0'
  s.source_files = 'Sources/*.swift'
  s.requires_arc = true
  s.pod_target_xcconfig = {
                 'SWIFT_VERSION' => '3.0'
               }
end
