

mkdir -p ./compiled/fat/lib
lipo -output ./compiled/fat/lib/libavcodec.a -create \
-arch armv7 ./compiled/armv7/lib/libavcodec.a \
-arch i386 ./compiled/i386/lib/libavcodec.a
lipo -output ./compiled/fat/lib/libavdevice.a -create \
-arch armv7 ./compiled/armv7/lib/libavdevice.a \
-arch i386 ./compiled/i386/lib/libavdevice.a
lipo -output ./compiled/fat/lib/libavformat.a -create \
-arch armv7 ./compiled/armv7/lib/libavformat.a \
-arch i386 ./compiled/i386/lib/libavformat.a
lipo -output ./compiled/fat/lib/libavutil.a -create \
-arch armv7 ./compiled/armv7/lib/libavutil.a \
-arch i386 ./compiled/i386/lib/libavutil.a
lipo -output ./compiled/fat/lib/libswresample.a -create \
-arch armv7 ./compiled/armv7/lib/libswresample.a \
-arch i386 ./compiled/i386/lib/libswresample.a
#!lipo -output ./compiled/fat/lib/libpostproc.a -create \
#!-arch armv7 ./compiled/armv7/lib/libpostproc.a \
#!-arch i386 ./compiled/i386/lib/libpostproc.a
lipo -output ./compiled/fat/lib/libswscale.a -create \
-arch armv7 ./compiled/armv7/lib/libswscale.a \
-arch i386 ./compiled/i386/lib/libswscale.a
lipo -output ./compiled/fat/lib/libavfilter.a -create \
-arch armv7 ./compiled/armv7/lib/libavfilter.a \
-arch i386 ./compiled/i386/lib/libavfilter.a
