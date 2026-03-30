#!/bin/sh -e

CHROOT=${CHROOT=$(pwd)/rootfs}
SRCDIR=$(pwd)/src

# build and install gt
(
cd src/libusbgx/
autoreconf -i
)

mkdir -p build
(
cd build
PKG_CONFIG_PATH=${CHROOT}/usr/lib/aarch64-linux-gnu/pkgconfig \
    ${SRCDIR}/libusbgx/configure \
        --host aarch64-linux-gnu \
        --prefix=/usr \
        --with-sysroot=${CHROOT}
)
make -j$(nproc) -C build DESTDIR=$(pwd)/dist CFLAGS="--sysroot=${CHROOT}" install
make -j$(nproc) -C build CFLAGS="--sysroot=${CHROOT}" install

rm -rf build/*
# PKG_CONFIG_PATH=${CHROOT}/usr/lib/pkgconfig:${CHROOT}/usr/lib/aarch64-linux-gnu/pkgconfig \
#     cmake -DCMAKE_INSTALL_PREFIX=/usr \
#         -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
#         -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
#         -DCMAKE_C_FLAGS=-I$(pwd)/dist/usr/include \
#         -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
#         -DCMAKE_SYSROOT=${CHROOT} \
#         -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
#         -S ${SRCDIR}/gt/source \
#         -B build
# 核心调整：强化交叉编译环境隔离，确保只使用chroot中的依赖
PKG_CONFIG_PATH=${CHROOT}/usr/lib/pkgconfig:${CHROOT}/usr/lib/aarch64-linux-gnu/pkgconfig \
PKG_CONFIG_SYSROOT_DIR=${CHROOT} \
    cmake -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
        -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
        -DCMAKE_C_FLAGS="--sysroot=${CHROOT} -I$(pwd)/dist/usr/include" \
        -DCMAKE_CXX_FLAGS="--sysroot=${CHROOT}" \
        -DCMAKE_FIND_ROOT_PATH=${CHROOT} \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_SYSROOT=${CHROOT} \
        -DCMAKE_SYSTEM_NAME=Linux \
        -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
        -S ${SRCDIR}/gt/source \
        -B build
        
make -j$(nproc) -C build DESTDIR=$(pwd)/dist install

rm -rf dist/usr/share dist/usr/lib/cmake dist/usr/lib/pkgconfig \
    dist/usr/lib/*a dist/usr/bin/ga* dist/usr/bin/s* dist/usr/include

cp -a configs/templates dist/etc/gt
