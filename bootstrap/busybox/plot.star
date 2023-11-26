#+warplark version 0
load("../../warpsys.star", "plot")
load("../../warpsys.star", "catalog_input_str")
load("../bootstrap.star", "bootstrap_build_step")
load("../bootstrap.star", "bootstrap_pack_step")

step_build = bootstrap_build_step(
    src=("warpsys.org/busybox", "v1.35.0", "src"),
    script=[
        "cd /src/*", "make defconfig",
        "sed -e 's/.*CONFIG_SELINUXENABLED.*/CONFIG_SELINUXENABLED=n/' -i .config",
        "make",
        "LDFLAGS='--static' make CONFIG_PREFIX=/out/warpsys-placeholder-prefix install"
    ])

result = plot(steps={"build": step_build})
