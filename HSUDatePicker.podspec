Pod::Spec.new do |s|
  s.name             = "HSUDatePicker"
  s.version          = "0.1.0"
  s.summary          = "A date picker just like a Calendar App"
  s.description      = <<-DESC
                       A date picker just like a Calendar App, you can set start year, end year and
                       disable past date selection.
                       DESC
  s.homepage         = "https://github.com/Moove-it/HSUDatePicker"
  s.screenshots     = "https://raw.githubusercontent.com/Moove-it/HSUDatePicker/master/1.png"
  s.license          = 'MIT'
  s.author           = { "Adrian Gomez" => "adrian.gomez@moove-it.com", "Jason Hsu" => "support@tuoxie.me", "Haechan Lee" => "soport55@thefermata.net" }
  s.source           = { :git => "https://github.com/Moove-it/HSUDatePicker.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'

  s.public_header_files = 'Pod/Classes/HSUDatePicker.h'

  s.frameworks = 'UIKit', 'MapKit'
end