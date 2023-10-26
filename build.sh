#!/bin/bash

PACKAGE_NAME="halrepo"

SRC_DIR="${PWD}/$(dirname $0)"

# Architecture of the software packed into .deb package file
ARCH="amd64"
# Version of the actual software packed into .deb package file
VERSION="1.0.0"
# Revision of .deb package file
REVISION="1.0.0"
# Location of build files
BUILD_DIR="${SRC_DIR}/build"
# Location of package files
DEB_DIR="${BUILD_DIR}/deb"
# <name>_<version>-<revision>_<architecture>.deb
DEB_FILE_NAME="${BUILD_DIR}/${PACKAGE_NAME}_${VERSION}-${REVISION}_${ARCH}.deb"

LINTIAN="lintian --no-tag-display-limit"
DPKG_DEB="dpkg-deb --debug"
DEBSIGS="debsigs"

# Create working directory
rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

# Ensure source files of the debian package are there
mkdir -p ${DEB_DIR}
cp -r ${SRC_DIR}/package/* ${DEB_DIR}
cd ${DEB_DIR}

mkdir -p debian && touch debian/control	# don't know why but this file is needed for dpkg-shlibdeps to work
DEPENDS="$(find ${DEB_DIR} -executable -type f -exec dpkg-shlibdeps -O {} + | sed 's/shlibs:Depends=//g' )"
INSTALLED_SIZE="$(du ${DEB_DIR} --exclude DEBIAN --summarize | cut -f1)"
rm debian/control && rmdir debian

# Build debian package file
mkdir ${DEB_DIR}/DEBIAN
cat <<EOF  > ${DEB_DIR}/DEBIAN/control
Package: ${PACKAGE_NAME}
Source: halacs.hu
Version: ${VERSION}
Architecture: ${ARCH}
Maintainer: Gábor Nyíri
Installed-Size: ${INSTALLED_SIZE}
#Depends: ${DEPENDS}
#Suggests: 
#Breaks: 
Replaces: ${PACKAGE_NAME} (<< 1.0.0)
Section: net
Priority: optional
Homepage: https://halacs.hu/
Description: Provides access to apt repository located at apt.halacs.hu
 This repository was made for private usage.
Original-Maintainer: Gábor Nyíri
EOF

# List configuration files
find ${DEB_DIR}/etc -type f | sed 's!'${DEB_DIR}'!!g' > ${DEB_DIR}/DEBIAN/conffiles

# Create MD5 hases for all files
find ${DEB_DIR} -type f -exec md5sum {} + | grep -v '/DEBIAN/' | sed 's!'${DEB_DIR}/'!!g' > ${DEB_DIR}/DEBIAN/md5sums

# Generate deb package
${DPKG_DEB} --build --root-owner-group ${DEB_DIR} ${DEB_FILE_NAME}

# Sign deb package
#${DEBSIGS} --sign=origin -k FB4DCAD16D547D4EF5D0844E4AB1940A2044CCC4 ${DEB_FILE_NAME}
#${DEBSIGS} --sign=maint -k FB4DCAD16D547D4EF5D0844E4AB1940A2044CCC4 ${DEB_FILE_NAME}
#${DEBSIGS} --list ${DEB_FILE_NAME}

# Linting generated deb file
${LINTIAN} ${DEB_FILE_NAME}

echo "Done."
echo "${DEB_FILE_NAME}"

