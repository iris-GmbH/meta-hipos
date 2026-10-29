# Copyright (C) 2026 iris-GmbH infrared & intelligent sensors

DESCRIPTION = "Provide HYDRA CA certificates"
SECTION = "support"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
FILES:${PN} = "\
    ${sysconfdir}/iris/signing \
"

install_identity_ca_crt() {
    install -d ${D}${sysconfdir}/iris/signing
    if [ ! -e "${IDENTITY_CA}" ]; then
        bbfatal "Error: IDENTITY_CA: ${IDENTITY_CA} does not exist!"
    fi
    install -m 0644 ${IDENTITY_CA} ${D}${sysconfdir}/iris/signing/device-identity-ca.crt
}

do_install() {
    install_identity_ca_crt
}

