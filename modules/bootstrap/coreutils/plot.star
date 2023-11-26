#+warplark version 0
load("../../warpsys.star", "plot")
load("../../warpsys.star", "catalog_input_str")
load("../bootstrap.star", "bootstrap_build_step")
load("../bootstrap.star", "bootstrap_pack_step")

step_build = bootstrap_build_step(
    src=("warpsys.org/coreutils", "v9.1", "src"),
    script=[
        "cd /src/*", "export FORCE_UNSAFE_CONFIGURE=1",
        "./configure --prefix=/warpsys-placeholder-prefix ", "make",
        "make DESTDIR=/out install"
    ])

step_pack = bootstrap_pack_step(
    binaries=
    [],  # this is handled by the extra_script since there are many bins 
    libraries=[
        ("warpsys.org/bootstrap/glibc", "libc.so.6"),
        ("warpsys.org/bootstrap/glibc", "libdl.so.2"),
        ("warpsys.org/bootstrap/glibc", "libpthread.so.0"),
    ],
    extra_script=[
        "mv /pack/bin/* /pack/dynbin",
        "for FILE in /pack/dynbin/*; do cp /pkg/warpsys.org/bootstrap/ldshim/ldshim /pack/bin/`basename $FILE`; done"
    ])

result = plot(steps={"build": step_build, "pack": step_pack})
