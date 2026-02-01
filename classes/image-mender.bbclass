IMAGE_INSTALL:append = " mender-client"
DEPENDS += " mender-artifact-native"

FIT_PARTITION_SIZE ??= "32768"
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

    mkdosfs -n FIT -C ${DEPLOY_DIR_IMAGE}/FIT_PART ${FIT_PARTITION_SIZE}
    mcopy -v -i ${DEPLOY_DIR_IMAGE}/FIT_PART -s ${DEPLOY_DIR_IMAGE}/fitImage ::/

    mender-artifact write module-image \
    -t mt-rpi0-w \
    -o ${DEPLOY_DIR_IMAGE}/FIT_PART.mender \
    -T update \
    -n system_update \
    -f ${DEPLOY_DIR_IMAGE}/FIT_PART
}

do_create_peristant_data_partitions() {
    if [ -e ${DEPLOY_DIR_IMAGE}/PERSISTANT_DATA ]
    then
        rm ${DEPLOY_DIR_IMAGE}/PERSISTANT_DATA
    fi
    mkdosfs -n data -C ${DEPLOY_DIR_IMAGE}/PERSISTANT_DATA 8192
}

PARTITION_CREATION_DEP =   "dosfstools-native:do_populate_sysroot \
                            mtools-native:do_populate_sysroot \
                            ${PN}:do_deploy_fitimage \
                            virtual/kernel:do_deploy"

do_create_peristant_data_partitions[depends] += "${PARTITION_CREATION_DEP}"
do_create_fit_partitions[depends] += "${PARTITION_CREATION_DEP}"
do_kernel_version_tester[depends] += "${PARTITION_CREATION_DEP}"

do_image_wic[depends] += "${PN}:do_kernel_version_tester \
                            ${PN}:do_create_fit_partitions \
                            ${PN}:do_create_peristant_data_partitions"

addtask do_kernel_version_tester  
addtask do_create_fit_partitions 
addtask do_create_peristant_data_partitions