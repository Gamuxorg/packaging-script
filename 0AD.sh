#!/bin/bash
BUILDPATH=$(pwd)/0ad-${1}-alpha
ARCH=$(uname -m)
APPDIR=$(pwd)/0ad-${1}-alpha/0ad-${1}-${ARCH}
if [ -f '/usr/bin/sudo' ];then
SUDO="/usr/bin/sudo"
else
SUDO=
fi

echo "Installing dependencies on Debian 10"
echo "===================================="
${SUDO} apt-get install -y build-essential cargo cmake libboost-dev libboost-system-dev   \
    libboost-filesystem-dev libcurl4-gnutls-dev libenet-dev libfmt-dev   \
    libfreetype6 libfreetype6-dev   \
    libgloox-dev libicu-dev libminiupnpc-dev libnvtt-dev libogg-dev   \
    libopenal-dev libpng-dev libsdl2-dev libsodium-dev libvorbis-dev   \
    libwxgtk3.0-gtk3-dev libxml2-dev python3 rustc subversion zlib1g-dev \
    wx3.0-headers libwxbase3.0-dev libwxgtk3.0-gtk3-dev libwxbase3.0-0v5 libwxgtk3.0-gtk3-0v5 wget

if [ ! $? -eq 0 ];then
    echo "did not you use debian-series system?"
    exit
fi

echo "Downloading source code"
echo "Version: ${1}"
echo "===================================="
wget -nc https://releases.wildfiregames.com/0ad-${1}-alpha-unix-build.tar.xz
wget -nc https://releases.wildfiregames.com/0ad-${1}-alpha-unix-data.tar.xz

if [ ! $? -eq 0 ];then
    echo "did not you input a version number as para?"
    exit
fi

rm -rf 0ad-${1}-alpha
tar axvf 0ad-${1}-alpha-unix-build.tar.xz
tar axvf 0ad-${1}-alpha-unix-data.tar.xz
mkdir -p ${APPDIR}

echo "Entering building directory"
echo "===================================="
cd ${BUILDPATH}/build/workspaces

echo "Patching code"
echo "===================================="
sed -i "3,6d" ./update-workspaces.sh

echo "Configing"
echo "===================================="
./update-workspaces.sh -j$(nproc)

echo "Building"
echo "===================================="
make config=release -C gcc -j$(nproc)
cd ${BUILDPATH}

echo "Testing"
echo "===================================="
cd ${BUILDPATH}
${BUILDPATH}/binaries/system/test

echo "Downloading needed files to package"
echo "===================================="
cd ${BUILDPATH}

wget -nc https://raw.githubusercontent.com/shouhuanxiaoji/pkg2appimage/patch-1/functions.sh -P ${BUILDPATH}/binaries/system/
chmod +x ${BUILDPATH}/binaries/system/functions.sh

wget -nc https://binary.modcdn.io/mods/093f/59/zh-lang-0.26.1.zip -P ${BUILDPATH}/

wget -nc https://github.com/AppImage/AppImageKit/releases/download/continuous/AppRun-${ARCH} -P ${APPDIR}

mv ${APPDIR}/AppRun-${ARCH} ${APPDIR}/AppRun
chmod +x ${APPDIR}/AppRun

echo "Get depending libraries"
echo "===================================="
cd ${BUILDPATH}/binaries/system
source ./functions.sh
copy_deps
move_lib
delete delete_blacklisted

cd usr
find . -type f  -name "*.so*" -exec cp -f {} ${BUILDPATH}/binaries/system \;
cd ${BUILDPATH}

echo "Installing"
echo "===================================="
mkdir -p ${APPDIR}/usr/bin
mkdir -p ${APPDIR}/usr/lib
mkdir -p ${APPDIR}/usr/data/config

install -s ${BUILDPATH}/binaries/system/pyrogenesis -Dt ${APPDIR}/usr/bin/
install -s ${BUILDPATH}/binaries/system/ActorEditor -Dt ${APPDIR}/usr/bin/
install ${BUILDPATH}/binaries/system/*.so* -Dt ${APPDIR}/usr/lib/
rm ${APPDIR}/usr/lib/libmozjs78-ps-debug.so
install ${BUILDPATH}/build/resources/0ad.appdata.xml -Dt ${APPDIR}/usr/share/metainfo
install ${BUILDPATH}/build/resources/0ad.desktop -Dt ${APPDIR}/usr/share/applications
install ${BUILDPATH}/build/resources/0ad.png -Dt ${APPDIR}/usr/share/pixmaps
cp -a ${BUILDPATH}/binaries/data/config/default.cfg $APPDIR/usr/data/config
cp -a ${BUILDPATH}/binaries/data/l10n ${APPDIR}/usr/data/
cp -a ${BUILDPATH}/binaries/data/tools ${APPDIR}/usr/data/ # for Atlas
mv ${BUILDPATH}/zh-lang-0.26.1.zip ${BUILDPATH}/binaries/data/mods
pushd ${BUILDPATH}/binaries/data/mods
unzip zh-lang-0.26.1.zip
rm -f zh-lang-0.26.1.zip
popd
cp -a ${BUILDPATH}/binaries/data/mods ${APPDIR}/usr/data/
cp -a ${BUILDPATH}/build/resources/0ad.png ${APPDIR}/

cd ${APPDIR}/usr/bin
ln -s pyrogenesis 0ad

echo "Striping"
echo "===================================="
cd ${APPDIR}

for i in $(find . -type f)
do
    strip ${i}
done

# generate desktop file
cd ${APPDIR}
cat >> 0ad.desktop <<EOF 
[Desktop Entry]
Type=Application
Name=0AD
Exec=0ad
Icon=0ad.png
Terminal=false
Categories=Game;
Keywords=game;0ad;游戏;
EOF

echo "Ending"