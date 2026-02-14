IMAGE_INSTALL:append = " mender mender-connect"
SYSTEMD_AUTO_ENABLE:pn-mender-connect = "enable"

DEPENDS += " mender-artifact-native"

FIT_PARTITION_SIZE_KB ??= "32768"
DATA_PARTITION_SIZE_KB ??= "1048576"
ROOTFS_POSTPROCESS_COMMAND:remove = "mender_update_fstab_file"

do_kernel_version_tester() {
    
    echo Image1 > ${DEPLOY_DIR_IMAGE}/kernel_tester.txt
    if [ -e ${DEPLOY_DIR_IMAGE}/KERNETL_TESTER ]
    then
        rm ${DEPLOY_DIR_IMAGE}/KERNETL_TESTER
    fi

    mkdosfs -n tester -C ${DEPLOY_DIR_IMAGE}/KERNETL_TESTER 8192
    mcopy -v -i ${DEPLOY_DIR_IMAGE}/KERNETL_TESTER -s ${DEPLOY_DIR_IMAGE}/kernel_tester.txt ::/
}

do_create_fit_partitions() {

    if [ -e ${DEPLOY_DIR_IMAGE}/FIT_PART ]
    then
        rm ${DEPLOY_DIR_IMAGE}/FIT_PART
    fi

    mkdosfs -n FIT -C ${DEPLOY_DIR_IMAGE}/FIT_PART ${FIT_PARTITION_SIZE_KB}
    mcopy -v -i ${DEPLOY_DIR_IMAGE}/FIT_PART -s ${DEPLOY_DIR_IMAGE}/fitImage ::/

    mender-artifact write module-image \
    -t mt-rpi0-w \
    -o ${DEPLOY_DIR_IMAGE}/FIT_PART.mender \
    -T update \
    -n system_update \
    -f ${DEPLOY_DIR_IMAGE}/FIT_PART
}

do_create_rootfs_partitions() {
    
    if [ -e ${DEPLOY_DIR_IMAGE}/ROOTFS_PART ]
    then
        rm ${DEPLOY_DIR_IMAGE}/ROOTFS_PART
    fi

    ln -sf ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.ext4 ${DEPLOY_DIR_IMAGE}/ROOTFS_PART
    mender-artifact write module-image \
    -t mt-rpi0-w \
    -o ${DEPLOY_DIR_IMAGE}/ROOTFS_PART.mender \
    -T update \
    -n system_update \
    -f ${DEPLOY_DIR_IMAGE}/ROOTFS_PART

    rm ${DEPLOY_DIR_IMAGE}/ROOTFS_PART
}

do_create_peristant_data_partitions() {
    if [ -e ${DEPLOY_DIR_IMAGE}/PERSISTANT_DATA.ext4 ]
    then
        rm ${DEPLOY_DIR_IMAGE}/PERSISTANT_DATA.ext4
    fi

    truncate -s ${DATA_PARTITION_SIZE_KB}K ${DEPLOY_DIR_IMAGE}/PERSISTANT_DATA.ext4
    mkfs.ext4 -L data ${DEPLOY_DIR_IMAGE}/PERSISTANT_DATA.ext4
}

python do_clean:append() {
    import shutil
    import os
    
    deploy_dir = d.getVar('DEPLOY_DIR_IMAGE')
    rootfs_path = os.path.join(deploy_dir, 'ROOTFS_PART.mender')
    if os.path.exists(rootfs_path):
        os.remove(rootfs_path)

    fit_path = os.path.join(deploy_dir, 'FIT_PART.mender')
    if os.path.exists(fit_path):
        os.remove(fit_path)

    fit_path = os.path.join(deploy_dir, 'FIT_PART')
    if os.path.exists(fit_path):
        os.remove(fit_path)
}


PARTITION_CREATION_DEP =   "dosfstools-native:do_populate_sysroot \
                            mtools-native:do_populate_sysroot \
                            ${PN}:do_deploy_fitimage \
                            virtual/kernel:do_deploy"

do_create_peristant_data_partitions[depends] += "${PARTITION_CREATION_DEP}"
do_create_fit_partitions[depends] += "${PARTITION_CREATION_DEP}"
do_create_rootfs_partitions[depends] += "${PARTITION_CREATION_DEP}"
do_kernel_version_tester[depends] += "${PARTITION_CREATION_DEP}"

do_image_wic[depends] += "${PN}:do_kernel_version_tester \
                            ${PN}:do_create_fit_partitions \
                            ${PN}:do_create_peristant_data_partitions"


addtask do_kernel_version_tester  
addtask do_create_fit_partitions 
addtask do_create_rootfs_partitions after do_image_complete before do_build
addtask do_create_peristant_data_partitions