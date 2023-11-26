#+warplark version 0
load("../../warpsys.star", "plot")
load("../../warpsys.star", "catalog_input_str")
load("../bootstrap.star", "bootstrap_build_step")
load("../bootstrap.star", "bootstrap_pack_step")

step_build = bootstrap_build_step(
    src=("warpsys.org/make", "v4.3", "src"),
    script=[
        "cd /src/*", "./configure --prefix=/warpsys-placeholder-prefix",
        "make", "make DESTDIR=/out install"
    ])

step_pack = bootstrap_pack_step(binaries=["make"],
                                libraries=[
                                    ("warpsys.org/bootstrap/glibc",
                                     "libc.so.6"),
                                    ("warpsys.org/bootstrap/glibc",
                                     "libdl.so.2"),
                                ])

result = plot(steps={"build": step_build, "pack": step_pack})
