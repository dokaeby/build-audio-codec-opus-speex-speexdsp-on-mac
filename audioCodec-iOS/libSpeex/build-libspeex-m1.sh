
# https://gist.github.com/marcelosarquis/8815680cf0fe03defd09b3abb2133f00

# apple#!/bin/bash

VERSION="1.2.0"

SDKVERSION_IPHONE="15.2" 
ARCHS_DEVICES_IPHONE="arm64e arm64 armv7s"
ARCHS_SIMULATOR_IPHONE="x86_64"

# SDKVERSION_WATCH="7.4" 
# ARCHS_DEVICES_WATCH="arm64_32 armv7k"
# ARCHS_SIMULATOR_WATCH="i386"

SDKVERSION_MAC="12.1" 
# ARCHS_DEVICES_MACX="x86_64 x86_64h arm64"

# by default, we won't build for debugging purposes
if [ "${DEBUG}" == "true" ]; then
    echo "Compiling for debugging..."
    OPT_CFLAGS="-O0 -fno-inline -g"
    OPT_LDFLAGS=""
    OPT_CONFIG_ARGS="--enable-assertions --disable-asm"
else
	echo "Compiling for release ..."
    OPT_CFLAGS="-Ofast -flto -g"
    OPT_LDFLAGS="-flto"
    OPT_CONFIG_ARGS=""
fi

# No need to change this since xcode build will only compile in the
# necessary bits from the libraries we create

# DEVELOPER=`xcode-select -print-path`
# add Your Xcode path
DEVELOPER="/Applications/Xcode.app/Contents/Developer"
# DEVELOPER="/Volumes/WORK/Apps/Xcode.app/Contents/Developer"

cd "`dirname \"$0\"`"
REPOROOT=$(pwd)

# Where we'll end up storing things in the end
OUTPUTDIR="${REPOROOT}/dependencies"
mkdir -p ${OUTPUTDIR}/include
mkdir -p ${OUTPUTDIR}/lib


BUILDDIR="${REPOROOT}/build"

# where we will keep our sources and build from.
SRCDIR="${BUILDDIR}/src"
mkdir -p $SRCDIR
# where we will store intermediary builds
INTERDIR="${BUILDDIR}/built"
mkdir -p $INTERDIR

########################################

cd $SRCDIR

# Exit the script if an error happens
set -e

if [ ! -e "${SRCDIR}/speex-${VERSION}.tar.gz" ]; then
	echo "Downloading speex-${VERSION}.tar.gz"
	curl -LO http://downloads.xiph.org/releases/speex/speex-${VERSION}.tar.gz
fi
echo "Using speex-${VERSION}.tar.gz"

tar zxf speex-${VERSION}.tar.gz -C $SRCDIR
cd "${SRCDIR}/speex-${VERSION}"

set +e # don't bail out of bash script if ccache doesn't exist
CCACHE=`which ccache`
if [ $? == "0" ]; then
	echo "Building with ccache: $CCACHE"
	CCACHE="${CCACHE} "
else
	echo "Building without ccache"
	CCACHE=""
fi
set -e # back to regular "bail out on error" mode

export ORIGINALPATH=$PATH

# Build the application and install it to the fake SDK intermediary dir
# we have set up. Make sure to clean up afterward because we will re-use
# this source tree to cross-compile other targets.

for ARCH in ${ARCHS_DEVICES_IPHONE}
do
    PLATFORM="iPhoneOS"
	EXTRA_CFLAGS="-arch ${ARCH}"
	EXTRA_CONFIG="--host=arm-apple-darwin"

	mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION_IPHONE}-${ARCH}.sdk"

	./configure --enable-float-approx --disable-shared --enable-static --with-pic --disable-extra-programs --disable-doc ${EXTRA_CONFIG} \
    --prefix="${INTERDIR}/${PLATFORM}${SDKVERSION_IPHONE}-${ARCH}.sdk" \
    LDFLAGS="$LDFLAGS ${OPT_LDFLAGS} -fPIE -L${OUTPUTDIR}/lib" \
    CFLAGS="$CFLAGS ${EXTRA_CFLAGS} ${OPT_CFLAGS} -fPIE -I${OUTPUTDIR}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION_IPHONE}.sdk" \

	make -j4
	make install
	make clean
done

for ARCH in ${ARCHS_SIMULATOR_IPHONE}
do
    PLATFORM="iPhoneSimulator"
	EXTRA_CFLAGS="-arch ${ARCH}"
#	EXTRA_CONFIG="--host=x86_64-apple-darwin"
	if [ "${ARCH}" == "x86_64h" ] || [ "${ARCH}" == "x86_64" ]; then
        EXTRA_CONFIG="--host=x86_64-apple-darwin"
    else
        EXTRA_CONFIG="--host=arm-apple-darwin"
    fi
	mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION_IPHONE}-${ARCH}.sdk"

	./configure --enable-float-approx --disable-rtcd --disable-shared --enable-static --with-pic --disable-extra-programs --disable-doc ${EXTRA_CONFIG} \
    --prefix="${INTERDIR}/${PLATFORM}${SDKVERSION_IPHONE}-${ARCH}.sdk" \
    LDFLAGS="$LDFLAGS ${OPT_LDFLAGS} -fPIE -L${OUTPUTDIR}/lib" \
    CFLAGS="$CFLAGS ${EXTRA_CFLAGS} ${OPT_CFLAGS} -fPIE -I${OUTPUTDIR}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION_IPHONE}.sdk" \

	make -j4
	make install
	make clean
done

# for ARCH in ${ARCHS_DEVICES_WATCH}
# do
#     PLATFORM="WatchOS"
# 	EXTRA_CFLAGS="-arch ${ARCH}"
# 	EXTRA_CONFIG="--host=arm-apple-darwin"

# 	mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION_WATCH}-${ARCH}.sdk"

# 	./configure --enable-float-approx --disable-shared --enable-static --with-pic ${EXTRA_CONFIG} \
#     --prefix="${INTERDIR}/${PLATFORM}${SDKVERSION_WATCH}-${ARCH}.sdk" \
#     LDFLAGS="$LDFLAGS ${OPT_LDFLAGS} -fPIE -L${OUTPUTDIR}/lib" \
#     CFLAGS="$CFLAGS ${EXTRA_CFLAGS} ${OPT_CFLAGS} -fPIE -I${OUTPUTDIR}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION_WATCH}.sdk" \

# 	make -j4
# 	make install
# 	make clean
# done

# for ARCH in ${ARCHS_SIMULATOR_WATCH}
# do
#     PLATFORM="WatchSimulator"
# 	EXTRA_CFLAGS="-arch ${ARCH}"
# 	EXTRA_CONFIG="--host=x86_64-apple-darwin"

# 	mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION_WATCH}-${ARCH}.sdk"

# 	./configure --enable-float-approx --disable-shared --enable-static --with-pic ${EXTRA_CONFIG} \
#     --prefix="${INTERDIR}/${PLATFORM}${SDKVERSION_WATCH}-${ARCH}.sdk" \
#     LDFLAGS="$LDFLAGS ${OPT_LDFLAGS} -fPIE -L${OUTPUTDIR}/lib" \
#     CFLAGS="$CFLAGS ${EXTRA_CFLAGS} ${OPT_CFLAGS} -fPIE -I${OUTPUTDIR}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION_WATCH}.sdk" \

# 	make -j4
# 	make install
# 	make clean
# done

# for ARCH in ${ARCHS_DEVICES_MACX}
# do
#     PLATFORM="MacOSX"
# 	EXTRA_CFLAGS="-arch ${ARCH}"
# 	if [ "${ARCH}" == "x86_64h" ] || [ "${ARCH}" == "x86_64" ]; then
#         EXTRA_CONFIG="--host=x86_64-apple-darwin"
#     else
#         EXTRA_CONFIG="--host=arm-apple-darwin"
#     fi

# 	mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION_MAC}-${ARCH}.sdk"

# 	./configure --enable-float-approx --disable-shared --enable-static --with-pic --disable-extra-programs --disable-doc ${EXTRA_CONFIG} \
#     --prefix="${INTERDIR}/${PLATFORM}${SDKVERSION_MAC}-${ARCH}.sdk" \
#     LDFLAGS="$LDFLAGS ${OPT_LDFLAGS} -fPIE -L${OUTPUTDIR}/lib" \
#     CFLAGS="$CFLAGS ${EXTRA_CFLAGS} ${OPT_CFLAGS} -fPIE -I${OUTPUTDIR}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION_MAC}.sdk" \

# 	make -j4
# 	make install
# 	make clean
# done

########################################

echo "Build library..."

# These are the libs that comprise libspeex.
OUTPUT_LIB="libspeex.a"
INPUT_LIBS=""
for ARCH in ${ARCHS_DEVICES_IPHONE}; do
	PLATFORM="iPhoneOS"
	INPUT_ARCH_LIB="${INTERDIR}/${PLATFORM}${SDKVERSION_IPHONE}-${ARCH}.sdk/lib/${OUTPUT_LIB}"
	if [ -e $INPUT_ARCH_LIB ]; then
		INPUT_LIBS="${INPUT_LIBS} ${INPUT_ARCH_LIB}"
	fi
done

for ARCH in ${ARCHS_SIMULATOR_IPHONE}; do
	PLATFORM="iPhoneSimulator"
	INPUT_ARCH_LIB="${INTERDIR}/${PLATFORM}${SDKVERSION_IPHONE}-${ARCH}.sdk/lib/${OUTPUT_LIB}"
	if [ -e $INPUT_ARCH_LIB ]; then
		INPUT_LIBS="${INPUT_LIBS} ${INPUT_ARCH_LIB}"
	fi
done

# for ARCH in ${ARCHS_DEVICES_WATCH}; do
# 	PLATFORM="WatchOS"
# 	INPUT_ARCH_LIB="${INTERDIR}/${PLATFORM}${SDKVERSION_WATCH}-${ARCH}.sdk/lib/${OUTPUT_LIB}"
# 	if [ -e $INPUT_ARCH_LIB ]; then
# 		INPUT_LIBS="${INPUT_LIBS} ${INPUT_ARCH_LIB}"
# 	fi
# done

# for ARCH in ${ARCHS_SIMULATOR_WATCH}; do
# 	PLATFORM="WatchSimulator"
# 	INPUT_ARCH_LIB="${INTERDIR}/${PLATFORM}${SDKVERSION_WATCH}-${ARCH}.sdk/lib/${OUTPUT_LIB}"
# 	if [ -e $INPUT_ARCH_LIB ]; then
# 		INPUT_LIBS="${INPUT_LIBS} ${INPUT_ARCH_LIB}"
# 	fi
# done

# for ARCH in ${ARCHS_DEVICES_MACX}; do
# 	PLATFORM="MacOSX"
# 	INPUT_ARCH_LIB="${INTERDIR}/${PLATFORM}${SDKVERSION_MAC}-${ARCH}.sdk/lib/${OUTPUT_LIB}"
# 	if [ -e $INPUT_ARCH_LIB ]; then
# 		INPUT_LIBS="${INPUT_LIBS} ${INPUT_ARCH_LIB}"
# 	fi
# done

# Combine the three architectures into a universal library.
if [ -n "$INPUT_LIBS"  ]; then
	lipo -create $INPUT_LIBS \
	-output "${OUTPUTDIR}/lib/${OUTPUT_LIB}"
else
	echo "$OUTPUT_LIB does not exist, skipping (are the dependencies installed?)"
fi

# We only need to copy the headers over once. (So break out of forloop
# once we get first success.)
for ARCH in ${ARCHS_DEVICES_IPHONE}; do
	PLATFORM="iPhoneOS"
	cp -R ${INTERDIR}/${PLATFORM}${SDKVERSION_IPHONE}-${ARCH}.sdk/include/* ${OUTPUTDIR}/include/
	if [ $? == "0" ]; then
		break
	fi
done

for ARCH in ${ARCHS_SIMULATOR_IPHONE}; do
	PLATFORM="iPhoneSimulator"
	cp -R ${INTERDIR}/${PLATFORM}${SDKVERSION_IPHONE}-${ARCH}.sdk/include/* ${OUTPUTDIR}/include/
	if [ $? == "0" ]; then
		break
	fi
done

# for ARCH in ${ARCHS_DEVICES_WATCH}; do
# 	PLATFORM="WatchOS"
# 	cp -R ${INTERDIR}/${PLATFORM}${SDKVERSION_WATCH}-${ARCH}.sdk/include/* ${OUTPUTDIR}/include/
# 	if [ $? == "0" ]; then
# 		break
# 	fi
# done

# for ARCH in ${ARCHS_SIMULATOR_WATCH}; do
# 	PLATFORM="WatchSimulator"
# 	cp -R ${INTERDIR}/${PLATFORM}${SDKVERSION_WATCH}-${ARCH}.sdk/include/* ${OUTPUTDIR}/include/
# 	if [ $? == "0" ]; then
# 		break
# 	fi
# done

# for ARCH in ${ARCHS_DEVICES_MACX}; do
# 	PLATFORM="MacOSX"
# 	cp -R ${INTERDIR}/${PLATFORM}${SDKVERSION_MAC}-${ARCH}.sdk/include/* ${OUTPUTDIR}/include/
# 	if [ $? == "0" ]; then
# 		break
# 	fi
# done

echo "======== CHECK FAT ARCH ========"
lipo -info "${OUTPUTDIR}/lib/${OUTPUT_LIB}"

####################

echo "Building done."
echo "Cleaning up..."
rm -fr ${INTERDIR}
rm -fr "${SRCDIR}/speex-${VERSION}"
echo "Done."
