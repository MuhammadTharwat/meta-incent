# This bbclass is used to generate a U-Boot-compatible FIT image.
#
# Inspired from kernel-fitimage but useable outside kernel recipes.
#
# Usage:
#   fitimage_assemble ...
#
# Arguments:
#     FITIMAGE-ITS  Output fitimage.its
#     FITIMAGE      Output fitimage
#     KERNEL        Input kernel image
#     UBOOT-SCRIPT  Input u-boot script
#     INITRAMFS     Input initramfs image
#
# Input variables:
#
#   KERNEL_DEVICETREE      List of dtb to be integrated (possibly overlays),
#                          searched in DEPLOY_DIR_IMAGE.
#   UBOOT_ARCH
#   UBOOT_DTB_LOADADDRESS
#   UBOOT_DTBO_LOADADDRESS
#   UBOOT_ENTRYPOINT
#   UBOOT_ENTRYSYMBOL
#   UBOOT_LOADADDRESS
#   UBOOT_RD_ENTRYPOINT
#   UBOOT_RD_LOADADDRESS
#
# Prerequisites:
#   Have a uboot-compatible kernel deployed (inherit kernel-uboot-deploy from
#   your kernel recipe) and a companion .comp file that indicates the
#   compression scheme:
#   - KERNEL
#   - KERNEL.comp

inherit kernel-arch

DEPENDS += "dtc-native u-boot-tools-native"

# fitImage Hash Algo
FITIMAGE_HASH_ALG ?= "sha256"
FITIMAGE_SIGN_ALG ?= "rsa4096"
UBOOT_MKIMAGE_DTCOPTS ?= '" -I dts -O dtb -p 2000 "'

UBOOT_LOADADDRESS ??= "${UBOOT_ENTRYPOINT}"

# Description string
FITIMAGE_DESC ?= "FIT image for ${DISTRO_NAME}/${PV}/${MACHINE}"

#
# Emit the fitImage ITS header
#
# $1 ... .its filename
fitimage_emit_fit_header() {
	cat << EOF >> $1
/dts-v1/;

/ {
        description = "${FITIMAGE_DESC}";
        #address-cells = <1>;
EOF
}

#
# Emit the fitImage section bits
#
# $1 ... .its filename
# $2 ... Section bit type: imagestart - image section start
#                          confstart  - configuration section start
#                          sectend    - section end
#                          fitend     - fitimage end
#
fitimage_emit_section_maint() {
	case $2 in
	imagestart)
		cat << EOF >> $1

        images {
EOF
	;;
	confstart)
		cat << EOF >> $1

        configurations {
EOF
	;;
	sectend)
		cat << EOF >> $1
	};
EOF
	;;
	fitend)
		cat << EOF >> $1
};
EOF
	;;
	esac
}

#
# Emit the fitImage ITS kernel section
#
# $1 ... .its filename
# $2 ... Image counter
# $3 ... Path to kernel image
# $4 ... Compression type
fitimage_emit_section_kernel() {

	local kernel_csum="${FITIMAGE_HASH_ALG}"

	ENTRYPOINT="${UBOOT_ENTRYPOINT}"
	if [ -n "${UBOOT_ENTRYSYMBOL}" ]; then
		ENTRYPOINT=`${HOST_PREFIX}nm vmlinux | \
			awk '$3=="${UBOOT_ENTRYSYMBOL}" {print "0x"$1;exit}'`
	fi

	cat << EOF >> $1
                kernel-$2 {
                        description = "Linux kernel";
                        data = /incbin/("$3");
                        type = "kernel";
                        arch = "${UBOOT_ARCH}";
                        os = "linux";
                        compression = "$4";
                        load = <${UBOOT_LOADADDRESS}>;
                        entry = <$ENTRYPOINT>;
                        hash-1 {
                                algo = "$kernel_csum";
                        };
                };
EOF
}

#
# Emit the fitImage ITS DTB section
#
# $1 ... .its filename
# $2 ... Image counter
# $3 ... Path to DTB image
fitimage_emit_section_dtb() {
	local dtb_loadline=""
	local dtb_ext=${3##*.}
	local dtb_csum="${FITIMAGE_HASH_ALG}"

	if [ "${dtb_ext}" = "dtbo" ]; then
		if [ -n "${UBOOT_DTBO_LOADADDRESS}" ]; then
			dtb_loadline="load = <${UBOOT_DTBO_LOADADDRESS}>;"
		fi
	elif dtb_is_overlay "$3"; then
		if [ -n "${UBOOT_DTBO_LOADADDRESS}" ]; then
		dtb_loadline="load = <${UBOOT_DTBO_LOADADDRESS}>;"
		fi
	elif [ -n "${UBOOT_DTB_LOADADDRESS}" ]; then
		dtb_loadline="load = <${UBOOT_DTB_LOADADDRESS}>;"
	fi
	cat << EOF >> $1
                fdt-$2 {
                        description = "Flattened Device Tree blob";
                        data = /incbin/("$3");
                        type = "flat_dt";
                        arch = "${UBOOT_ARCH}";
                        compression = "none";
                        $dtb_loadline
                        hash-1 {
                                algo = "$dtb_csum";
                        };
                };
EOF
}

#
# Emit the fitImage ITS u-boot script section
#
# $1 ... .its filename
# $2 ... Image counter
# $3 ... Path to boot script image
fitimage_emit_section_boot_script() {

	bootscr_csum="${FITIMAGE_HASH_ALG}"

	cat << EOF >> $1
                bootscr-$2 {
                        description = "U-boot script";
                        data = /incbin/("$3");
                        type = "script";
                        arch = "${UBOOT_ARCH}";
                        compression = "none";
                        hash-1 {
                                algo = "$bootscr_csum";
                        };
                };
EOF
}

#
# Emit the fitImage ITS setup section
#
# $1 ... .its filename
# $2 ... Image counter
# $3 ... Path to setup image
fitimage_emit_section_setup() {

	setup_csum="${FITIMAGE_HASH_ALG}"

	cat << EOF >> $1
                setup-$2 {
                        description = "Linux setup.bin";
                        data = /incbin/("$3");
                        type = "x86_setup";
                        arch = "${UBOOT_ARCH}";
                        os = "linux";
                        compression = "none";
                        load = <0x00090000>;
                        entry = <0x00090000>;
                        hash-1 {
                                algo = "$setup_csum";
                        };
                };
EOF
}

#
# Emit the fitImage ITS ramdisk section
#
# $1 ... .its filename
# $2 ... Image counter
# $3 ... Path to ramdisk image
fitimage_emit_section_ramdisk() {

	local path_initramfs="$3"
	local name=$(basename "$path_initramfs")
	local ramdisk_csum="${FITIMAGE_HASH_ALG}"

	local ramdisk_loadline=""
	local ramdisk_entryline=""

	if [ -n "${UBOOT_RD_LOADADDRESS}" ]; then
		ramdisk_loadline="load = <${UBOOT_RD_LOADADDRESS}>;"
	fi
	if [ -n "${UBOOT_RD_ENTRYPOINT}" ]; then
		ramdisk_entryline="entry = <${UBOOT_RD_ENTRYPOINT}>;"
	fi

	cat << EOF >> $1
                ramdisk-$2 {
                        description = "$name";
                        data = /incbin/("$path_initramfs");
                        type = "ramdisk";
                        arch = "${UBOOT_ARCH}";
                        os = "linux";
                        compression = "none";
                        $ramdisk_loadline
                        $ramdisk_entryline
                        hash-1 {
                                algo = "$ramdisk_csum";
                        };
                };
EOF
}

#
# Emit the fitImage ITS configuration section
#
# $1 ... .its filename
# $2 ... Linux kernel ID
# $3 ... DTB image name
# $4 ... ramdisk ID
# $5 ... config ID
# $6 ... config sequence number (number '1' selected as default config)
fitimage_emit_section_config() {

	local conf_csum="${FITIMAGE_HASH_ALG}"
	local conf_sign_algo="${FITIMAGE_SIGN_ALG}"

	local its_file="$1"
	local kernel_id="$2"
	local dtb_image="$3"
	local ramdisk_id="$4"
	local config_id="$5"
	local configcount="$6"

	# Test if we have any DTBs at all
	local sep=""
	local conf_desc=""
	local conf_node="conf-"
	local kernel_line=""
	local fdt_line=""
	local ramdisk_line=""
	local setup_line=""
	local default_line=""

	# conf node name is selected based on dtb ID if it is present,
	# otherwise its selected based on kernel ID
	if [ -n "$dtb_image" ]; then
		conf_node=$conf_node$dtb_image
	else
		conf_node=$conf_node$kernel_id
	fi

	if [ -n "$kernel_id" ]; then
		conf_desc="Linux kernel"
		sep=", "
		kernel_line="kernel = \"kernel-$kernel_id\";"
	fi

	if [ -n "$dtb_image" ]; then
		conf_desc="$conf_desc${sep}FDT blob"
		sep=", "
		fdt_line="fdt = \"fdt-$dtb_image\";"
	fi

	if [ -n "$ramdisk_id" ]; then
		conf_desc="$conf_desc${sep}ramdisk"
		sep=", "
		ramdisk_line="ramdisk = \"ramdisk-$ramdisk_id\";"
	fi

	if [ -n "$bootscr_id" ]; then
		conf_desc="$conf_desc${sep}u-boot script"
		sep=", "
		bootscr_line="bootscr = \"bootscr-$bootscr_id\";"
	fi

	if [ -n "$config_id" ]; then
		conf_desc="$conf_desc${sep}setup"
		setup_line="setup = \"setup-$config_id\";"
	fi

	if [ "$configcount" = "1" ]; then
		if [ -n "$dtb_image" ]; then
			default_line="default = \"conf-$dtb_image\";"
		else
			default_line="default = \"conf-$kernel_id\";"
		fi
	fi

	cat << EOF >> $its_file
                $default_line
                $conf_node {
                        description = "$configcount $conf_desc";
                        $kernel_line
                        $fdt_line
                        $ramdisk_line
                        $bootscr_line
                        $setup_line
EOF
	cat << EOF >> $its_file
                };
EOF
}

# $1 ... DTB name
#        It is searched after its basename in ${DEPLOY_DIR_IMAGE}
dtb_is_overlay() {
	local dtbname=$(basename "$1")
	dtc -I dtb -O dts < ${DEPLOY_DIR_IMAGE}/${dtbname} 2>&1 |grep __overlay__ > /dev/null
}

#
# Assemble fitImage
#
# $1 ... .its filename
# $2 ... fitImage name
# $3 ... u-boot prepared kernel image
# $4 ... u-boot script
# $5 ... optional ramdisk
fitimage_assemble() {
	local its=$1
	local image=$2
	local kernel=$3
	local uboot_script=$4
	local ramdisk=$5

	local ramdisk_id

	rm -f $its
	if [ -n "$ramdisk" ]; then
		if [ ! -e "$ramdisk" ]; then
			bberror "ramdisk file does not exists: $ramdisk"
		fi
		ramdisk_id=1
	fi

	fitimage_emit_fit_header ${its}

	#
	# Step 1: Prepare a kernel image section.
	#
	fitimage_emit_section_maint $its imagestart

	# The .comp file is generated by the kernel recipe when it
	# inherits kernel-uboot-deploy.
	local comp="$(cat ${kernel}.comp)"
	fitimage_emit_section_kernel ${its} 1 ${kernel} "${comp}"

	#
	# Step 2: Prepare a DTB image section
	#

	local dtbs=""
	if [ -n "${KERNEL_DEVICETREE}" ]; then
		dtbcount=1
		for DTB in ${KERNEL_DEVICETREE}; do
			if echo $DTB | grep -q '/dts/'; then
				bbwarn "$DTB contains the full path to the the dts file, but only the dtb name should be used."
				DTB=`basename $DTB | sed 's,\.dts$,.dtb,g'`
			fi

			DTB=$(basename $DTB)

			dtbs="$dtbs $DTB"
			fitimage_emit_section_dtb $its $DTB ${DEPLOY_DIR_IMAGE}/$DTB
		done
	fi

	#
	# Step 3: Prepare a u-boot script section
	#

	if [ -n "$uboot_script" ]; then
		if [ -e "$uboot_script" ]; then
			bootscr_id=$(basename "$uboot_script")
			fitimage_emit_section_boot_script $its "$bootscr_id" "$uboot_script"
		else
			bberror "U-Boot script '$uboot_script' not found."
		fi
	fi

	#
	# Step 4: Prepare a ramdisk section.
	#
	[ -n "$ramdisk_id" ] && fitimage_emit_section_ramdisk $its 1 $ramdisk

	fitimage_emit_section_maint $its sectend

	# Force the first Kernel and DTB in the default config
	local withkernel=1

	[ -n "${ramdisk}" ] && ramdiskcount=1

	#
	# Step 5: Prepare a configurations section
	#
	fitimage_emit_section_maint $its confstart

	# Default configuration: set the first one as default
	local configcount=1

	if [ -n "$dtbs" ]; then
		for dtb in ${dtbs}; do
			local dtb_ext=${dtb##*.}
			if [ "${dtb_ext}" = "dtbo" ]; then
				bbdebug 1 "${dtb} is overlay (with extension dtbo)"
				# just the DTB, without kernel nor initramfs
				fitimage_emit_section_config ${its} "" "${dtb}" "" "" "$configcount"
			elif dtb_is_overlay "${dtb}"; then
				bbdebug 1 "${dtb} is overlay (binary analysis)"
				# just the DTB, without kernel nor initramfs
				fitimage_emit_section_config ${its} "" "${dtb}" "" "" "$configcount"
			else
				bbdebug 1 "${dtb} is not overlay"
				# kernel, DTB, initramfs
				fitimage_emit_section_config ${its} ${withkernel} "${dtb}" "${ramdisk_id}" "$configcount"
			fi
			configcount=$(expr $configcount + 1)
		done
	else
		# kernel, initramfs (no DTB)
		fitimage_emit_section_config ${its} ${withkernel} "" "${ramdisk_id}" ${configcount}
	fi

	fitimage_emit_section_maint $its sectend

	fitimage_emit_section_maint $its fitend

	#
	# Step 7: Assemble the image
	#
	local opts=""
	[ -n "${UBOOT_MKIMAGE_DTCOPTS}" ] && opts="-D \"${UBOOT_MKIMAGE_DTCOPTS}\""
	uboot-mkimage $opts -f $its $image
}
