Pod::Spec.new do |s|
  s.name         = 'WHCNetWorkKit'
  s.version      = '0.0.3'
  s.summary      = 'WHCNetWorkKit 是http网络请求开源库(支持GET/POST 文件上传 后台文件下载 UIButton UIImageView 控件设置网络图片 网络数据工具json/xml 转模型类对象 网络状态监听)'
  s.homepage     = 'https://github.com/netyouli/WHCNetWorkKit'
  #s.screenshots  = 'https://github.com/netyouli/WHCNetWorkKit/blob/master/show.gif'
  s.license      = 'MIT'
  s.author             = { '吴海超' => '712641411@qq.com' }
  s.platform     = :ios, '7.0'
  s.ios.deployment_target = '7.0'
  #s.osx.deployment_target = '10.8'
  #s.watchos.deployment_target = '2.0'
  #s.tvos.deployment_target = '9.0'



  s.source       = { :git => 'https://github.com/netyouli/WHCNetWorkKit.git', :tag => s.version, :submodules => true}

  s.source_files  = 'WHCNetWorkKit/*.h'

  s.public_header_files = 'WHCNetWorkKit/*.h'

  s.subspec 'Reachability' do |ss|
    ss.source_files = 'WHCNetWorkKit/Reachability/*.{h,m}'
    ss.public_header_files = 'WHCNetWorkKit/Reachability/*.h'
  end

  s.subspec 'NSURLConnection' do |ss|
    ss.dependency 'WHCNetWorkKit/Reachability'
    ss.source_files = 'WHCNetWorkKit/NSURLConnection/*.{h,m}'
    ss.public_header_files = 'WHCNetWorkKit/NSURLConnection/*.h'
  end

  s.subspec 'NSURLSession' do |ss|
    ss.dependency 'WHCNetWorkKit/NSURLConnection'
    ss.source_files = 'WHCNetWorkKit/NSURLSession/*.{h,m}'
    ss.public_header_files = 'WHCNetWorkKit/NSURLSession/*.h'
  end

  s.subspec 'UIKit' do |ss|
    ss.dependency 'WHCNetWorkKit/NSURLConnection'
    ss.source_files = 'WHCNetWorkKit/UIKit+WHCNetWorkKit/*.{h,m}'
    ss.public_header_files = 'WHCNetWorkKit/UIKit+WHCNetWorkKit/*.h'
  end

  s.subspec 'UtillKit' do |ss|
    ss.source_files = 'WHCNetWorkKit/UtilKit+WHCNetWorkKit/*.{h,m}'
    ss.public_header_files = 'WHCNetWorkKit/UtilKit+WHCNetWorkKit/*.h'
  end

  s.requires_arc = true

end
