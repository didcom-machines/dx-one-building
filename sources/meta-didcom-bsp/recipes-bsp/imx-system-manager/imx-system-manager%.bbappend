# Patching System Manager for custom ignition tracking
# Base recipe located at: sources/meta-imx/meta-imx-bsp/recipes-bsp/imx-system-manager/imx-system-manager_1.0.0.bb

#SRC_URI:var-som = "git://github.com/varigit/imx-sm;protocol=https;branch=${SRCBRANCH}"
#SRCBRANCH:var-som = "lf-6.12.20-2.0.0_var01"
#SRCREV:var-som = "9922e00fc09049a12c2737513c0f36becbadd316"

#COMPATIBLE_MACHINE = "(mx95-generic-bsp)"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append:var-som = " file://sm_ap_button_controlled.patch"
