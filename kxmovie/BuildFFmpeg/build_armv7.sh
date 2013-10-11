./configure \
--disable-doc \
--disable-ffmpeg \
--disable-ffplay \
--disable-ffserver \
--disable-ffprobe \
--enable-cross-compile \
--arch=arm \
--target-os=darwin \
--cc=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang \
--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS7.0.sdk \
--extra-cflags='-arch armv7' \
--extra-ldflags='-arch armv7 -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS7.0.sdk/usr/lib/system' \
--disable-asm \
--prefix=compiled/armv7 \
--cpu=cortex-a8 \
--disable-logging \
--disable-debug \
--enable-shared


make clean
make && 
make install