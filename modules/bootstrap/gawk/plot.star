#+warplark version 0
load("warpsys.star", "plot")
load("warpsys.star", "catalog_input_str")
load("bootstrap.star", "bootstrap_build_step")
load("bootstrap.star", "bootstrap_pack_step")

step_build = bootstrap_build_step(
    src=("warpsys.org/gawk", "v5.1.1", "src"),
    script=[
        "cd /src/*", "./configure --prefix=/warpsys-placeholder-prefix ",
        "make", "make DESTDIR=/out install"
    ])

step_pack = bootstrap_pack_step(
    binaries=["awk", "gawk", "gawk-5.1.1"],
    libraries=[
        ("warpsys.org/bootstrap/glibc", "libc.so.6"),
        ("warpsys.org/bootstrap/glibc", "libdl.so.2"),
        ("warpsys.org/bootstrap/glibc", "libpthread.so.0"),
    ])

result = plot(steps={"build": step_build, "pack": step_pack})
