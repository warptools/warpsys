#+warplark version 0
load("warpsys.star", "plot")
load("warpsys.star", "catalog_input_str")
load("bootstrap.star", "bootstrap_build_step")
load("bootstrap.star", "bootstrap_pack_step")

step_build = bootstrap_build_step(
    src=("warpsys.org/glibc", "v2.35", "src"),
    script=[
        "mkdir -v /build", "cd /build",
        "/src/*/configure --prefix=/warpsys-placeholder-prefix/", "make",
        "make DESTDIR=/out install",
        "rm /out/warpsys-placeholder-prefix/share/info/libc.info-8",
        "cp -R /usr/include/x86_64-linux-gnu /out/warpsys-placeholder-prefix/include",
        "cp -R /usr/include/asm-generic /out/warpsys-placeholder-prefix/include",
        "cp -R /usr/include/linux /out/warpsys-placeholder-prefix/include",
        "mkdir -vp /out/ld",
        "cp /out/warpsys-placeholder-prefix/lib/ld-linux-x86-64.so.2 /out/ld"
    ])

result = plot(steps={"build": step_build})
