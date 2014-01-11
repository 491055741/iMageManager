iMageManager
============

Picture and video player tool on iOS.</br>
include: kxmovie (ffmpeg 1.2), SCGIFImageView, SPLockScreen, ZipArchive, CocoaWebResource, RegexKitLite</br>

Build:</br>
</br>
put ffmpeg 1.2 under kxmovie folder;</br>
$ cp BuildFFmpeg/* ffmpeg</br>
$ cd ffmpeg</br>
$ sudo cp gas-preprocessor.pl /usr/local/bin</br>
$ sudo chmod 777 /usr/local/bin/gas-preprocessor.pl</br>
$ sh ./build_i386.sh</br>
$ sh ./build_armv7.sh</br>
$ sh ./build_universal.sh</br>
