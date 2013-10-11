
./configure \
--disable-doc \
--disable-ffmpeg \
--disable-ffplay \
--disable-ffserver \
--enable-cross-compile \
--arch=arm \
--target-os=darwin \
--cc=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/llvm-gcc-4.2/bin/arm-apple-darwin10-llvm-gcc-4.2 \
--as='gas-preprocessor/gas-preprocessor.pl /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/llvm-gcc-4.2/bin/arm-apple-darwin10-llvm-gcc-4.2' \
--sysroot=/applications/xcode.app/contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk \
--disable-asm \
--prefix=compiled/armv7 \
--cpu=cortex-a8 \
--extra-ldflags='-arch=armv7 -isysroot /applications/xcode.app/contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk' \
--enable-pic \
--disable-bzlib \
--disable-gpl \
--disable-shared \
--enable-static \
--disable-mmx \
--disable-debug \
--enable-neon \
--enable-decoder=h264 \
--extra-cflags='-mfpu=neon -pipe -Os -gdwarf-2 -isysroot /applications/xcode.app/contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk -m${thumb_opt:-no-thumb} -mthumb-interwork'


make clean
make && 
make install
