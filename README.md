iMageManager
============

Picture and video player tool on iOS.  
Include: kxmovie (ffmpeg 1.2), SCGIFImageView, SPLockScreen, ZipArchive, CocoaWebResource, RegexKitLite 


Build:    
     
put ffmpeg 1.2 under kxmovie folder;    
$ cp BuildFFmpeg/* ffmpeg     
$ cd ffmpeg     
$ sudo cp gas-preprocessor.pl /usr/local/bin    
$ sudo chmod 777 /usr/local/bin/gas-preprocessor.pl     
$ sh ./build_i386.sh    
$ sh ./build_armv7.sh    
$ sh ./build_universal.sh    
