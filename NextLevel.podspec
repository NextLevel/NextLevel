Pod::Spec.new do |s|
  s.name = 'NextLevel'
  s.version = '0.0.1'
  s.license = 'MIT'
  s.summary = 'Radical Audio Video in Swift'
  s.homepage = 'https://github.com/nextlevel/NextLevel'
  s.authors = { "Simon Corsin" => "simon@corsin.me", "patrick piemonte" => "piemonte@alumni.cmu.edu" }
  s.source = { :git => 'https://github.com/nextlevel/NextLevel.git', :tag => s.version }
  s.ios.deployment_target = '9.0'
  s.source_files = 'Sources/*.swift'
  s.requires_arc = true
end
