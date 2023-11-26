#+warplark version 0
load("warpsys.star", "plot")
load("warpsys.star", "catalog_input_str")
load("warpsys.star", "gnu_build_step")
load("warpsys.star", "zapp_pack_step")

step_build = gnu_build_step(
    src=("warpsys.org/busybox", "v1.35.0", "src"),
    script=[
        "cd /src/*", "make defconfig",
        "sed -e 's/.*CONFIG_SELINUXENABLED.*/CONFIG_SELINUXENABLED=n/' -i .config",
        "sed -e 's/.*CONFIG_NANDWRITE.*/CONFIG_NANDWRITE=n/' -i .config",
        "sed -e 's/.*CONFIG_NANDDUMP.*/CONFIG_NANDDUMP=n/' -i .config",
        "sed -e 's/.*CONFIG_UBIATTACH.*/CONFIG_UBIATTACH=n/' -i .config",
        "sed -e 's/.*CONFIG_UBIDETACH.*/CONFIG_UBIDETACH=n/' -i .config",
        "sed -e 's/.*CONFIG_UBIMKVOL.*/CONFIG_UBIMKVOL=n/' -i .config",
        "sed -e 's/.*CONFIG_UBIRMVOL.*/CONFIG_UBIRMVOL=n/' -i .config",
        "sed -e 's/.*CONFIG_UBIRSVOL.*/CONFIG_UBIRSVOL=n/' -i .config",
        "sed -e 's/.*CONFIG_UBIUPDATEVOL.*/CONFIG_UBIUPDATEVOL=n/' -i .config",
        "sed -e 's/.*CONFIG_UBIRENAME.*/CONFIG_UBIRENAME=n/' -i .config",
        "make",
        "LDFLAGS='--static' make CONFIG_PREFIX=/out/warpsys-placeholder-prefix install"
    ])

# for the pack step to work, the built step must be named "build"
# due to the pipe used in pack
result = plot(steps={"build": step_build},
              outputs={"amd64-static": "pipe:build:out"})
