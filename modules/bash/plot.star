#+warplark version 0
load("warpsys.star", "plot")
load("warpsys.star", "catalog_input_str")
load("warpsys.star", "gnu_build_step")
load("warpsys.star", "zapp_pack_step")

step_build = gnu_build_step(
    src=("warpsys.org/bash", "v5.1.16", "src"),
    script=[
        "cd /src/*", "./configure --prefix=/warpsys-placeholder-prefix",
        "make", "make DESTDIR=/out install"
    ])
step_pack = zapp_pack_step(
    binaries=["bash"],
    libraries=[
        ("warpsys.org/bootstrap/glibc", "libc.so.6"),
        ("warpsys.org/bootstrap/glibc", "libdl.so.2"),
        ("warpsys.org/bootstrap/glibc", "libm.so.6"),
    ],
    extra_script=[
        "rm -rf /pack/lib/bash /pack/lib/pkgconfig /pack/include /pack/share"
    ])

# for the pack step to work, the built step must be named "build"
# due to the pipe used in pack
result = plot(steps={"build": step_build, "pack": step_pack})
