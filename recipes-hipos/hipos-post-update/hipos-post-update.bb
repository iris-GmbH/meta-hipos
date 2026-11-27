DESCRIPTION = "Housekeeping systemd-service that runs on the first boot after an update"
SECTION = "base"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit systemd allarch

RDEPENDS:${PN} = " \
  cryptsetup \
  keyutils \
  libubootenv-bin \
  lvm2 \
"

SRC_URI = " \
  file://hipos-post-update.service \
  file://hipos-post-update.sh \
"

FILES:${PN} = " \
  ${sbindir}/hipos-post-update.sh \
  ${systemd_system_unitdir}/hipos-post-update.service \
"

SYSTEMD_SERVICE:${PN} = "hipos-post-update.service"

do_install () {
  install -d ${D}${sbindir}
  install -m 0755 ${WORKDIR}/hipos-post-update.sh ${D}${sbindir}/hipos-post-update.sh

  install -d ${D}${systemd_system_unitdir}
  install -m 0644 ${WORKDIR}/hipos-post-update.service ${D}${systemd_system_unitdir}/hipos-post-update.service
}
