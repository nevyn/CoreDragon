Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.name         = "CoreDragon"
  s.version      = "0.1.1"
  s.summary      = "Stop using context menus. Drag and drop instead, even between apps!"

  s.description  = <<-DESC
    CoreDragon is a drag'n'drop library for iOS applications.
    Instead of using context menus, modal view controllers, share sheets
    and other "indirect manipulation" ways of moving data around, it's
    much more intuitive to just grab the thing you want to move, and drop
    it on the place where you want to move it to.

    CoreDragon uses similar concepts as the drag'n' drop APIs on MacOS,
    and modifies them to work better in a world with view controllers.
    It works within a single application, and on modern iPads, between
    applications that are running in split screen mode.

                   DESC

  s.homepage     = "https://github.com/nevyn/CoreDragon"
  s.screenshots  = "https://camo.githubusercontent.com/8702afc61cb51f6576177ef94ccd906ec4a6b846/68747470733a2f2f646c2e64726f70626f7875736572636f6e74656e742e636f6d2f752f363737352f647261676e64726f702e676966"
  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE.txt" }

  s.author             = { "Nevyn Bengtsson" => "nevyn.jpg@gmail.com" }
  s.social_media_url   = "http://twitter.com/nevyn"


  # ――― Build settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.platform     = :ios, "9.1"
  s.source       = { :git => "https://github.com/nevyn/CoreDragon.git", :tag => s.version }

  s.source_files  = "CoreDragon", "CoreDragon/*.{h,m}"
  s.public_header_files = "CoreDragon/CoreDragon.h", "CoreDragon/DragonController.h"
  s.resources = "Resources/*.png"
  
  s.dependency "Cerfing", '~> 2.0'
  s.dependency "MeshPipe/CerfingMeshPipe", '~> 0.1.2'

end
