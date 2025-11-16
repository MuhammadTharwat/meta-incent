DEPLOY_FILES ??= ""
DEPLOY_FILES[doc] = "List of patterns describing files to copy into the recipe's deploy directory (DEPLOYDIR)."

do_deploy[vardeps] += "DEPLOY_FILES"

python do_populate_files_deploy_dir() {
    bbe.utils.populate_files(d, "${DEPLOY_FILES}", "${DEPLOYDIR}")
}

SHARED_FILES ??= ""
SHARED_FILES[doc] = "List of patterns describing files to copy into the recipe's shared directory (SHAREDDIR)."

do_populate_shared_dir[vardeps] += "SHARED_FILES"

python do_populate_files_shared_dir() {
    bbe.utils.populate_files(d, "${SHARED_FILES}", "${SHAREDDIR}")
}

python () {
    # Note: We are here prepending to the tasks 'postfuncs' as we must execute
    # those before the 'sstate_task_postfunc' function, to ensure files are
    # properly captured by the sstate cache.

    if bb.data.inherits_class("deploy", d):
        d.prependVarFlag("do_deploy", "postfuncs", "do_populate_files_deploy_dir ")

    elif d.getVar("DEPLOY_FILES"):
        bb.warn(f"Recipe {d.getVar('PN')} sets DEPLOY_FILES variable but does not inherit deploy.bbclass.")

    if bb.data.inherits_class("shared", d):
        d.prependVarFlag("do_populate_shared_dir", "postfuncs", "do_populate_files_shared_dir ")

    elif d.getVar("SHARED_FILES"):
        bb.warn(f"Recipe {d.getVar('PN')} sets SHARED_FILES variable but does not inherit shared.bbclass.")
}
