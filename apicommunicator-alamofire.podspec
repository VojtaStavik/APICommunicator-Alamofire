Pod::Spec.new do |s|
  s.name = 'APICommunicator-Alamofire'
  s.version = '0.1'
  s.license = 'MIT'
  s.summary = 'API calls to NSOperation wrapper + Alamofire'
  s.homepage = 'https://github.com/VojtaStavik/APICommunicator-Alamofire'
  s.social_media_url = 'http://twitter.com/VojtaStavik'
  s.authors = { "Vojta Stavik" => "stavik@outlook.com" }
  s.source = { :git => 'https://github.com/VojtaStavik/APICommunicator-Alamofire', :tag => s.version }
  s.ios.deployment_target = '7.0'
  s.source_files   = '*.swift'
  s.frameworks = 'UIKit', 'CoreData'
  s.requires_arc = true
  s.dependency 'Alamofire', '< 3.0'
  s.dependency 'SwiftyJSON'
end
