SHARED_BASE_DIR = "${TOPDIR}/shared"

SHARED_DIR = "${SHARED_BASE_DIR}/${MACHINE}"
SHARED_DIR[doc] = "For recipes that inherit the shared class, this variable points to a temporary area for shared files between recipes."

SHAREDDIR = "${WORKDIR}/shared-${PN}"

SSTATETASKS += "do_populate_shared_dir"

python do_populate_shared_dir_setscene() {
    sstate_setscene(d)
}

addtask do_populate_shared_dir_setscene

do_populate_shared_dir[cleandirs] = "${SHAREDDIR}"
do_populate_shared_dir[dirs] = "${B}"
do_populate_shared_dir[sstate-inputdirs] = "${SHAREDDIR}"
do_populate_shared_dir[sstate-outputdirs] = "${SHARED_DIR}"
do_populate_shared_dir[stamp-extra-info] = "${MACHINE_ARCH}"

do_populate_shared_dir() {
	:
}
