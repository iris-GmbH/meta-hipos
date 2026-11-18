# SPDX-License-Identifier: MIT
# Copyright (C) 2026 iris-GmbH infrared & intelligent sensors

SUMMARY = "initramfs-framework module for bind-mounting rw files from the userdata volume"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
RDEPENDS:${PN} = " \
    initramfs-framework-base \
    busybox \
"

inherit allarch
inherit only-for-hipos-cyber-security

SRC_URI = "file://hiposbindmounts"

S = "${WORKDIR}"

do_install() {
    install -d ${D}/init.d
    install -m 0755 ${WORKDIR}/hiposbindmounts ${D}/init.d/83-hiposbindmounts
}

FILES:${PN} = "\
    /init.d/83-hiposbindmounts \
"
