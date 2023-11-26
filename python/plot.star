#+warplark version 0
load("warpsys.star", "plot")
load("warpsys.star", "catalog_input_str")
load("warpsys.star", "gnu_build_step")
load("warpsys.star", "zapp_pack_step")

step_build = gnu_build_step(
    src=("warpsys.org/python", "v3.10.4", "src"),
    script=[
        "mkdir -p /usr/lib/x86_64-linux-gnu",
        "export CPPFLAGS=-I/pkg/warpsys.org/zlib/include",
        "cp -r /pkg/warpsys.org/zlib/lib/* /usr/lib/x86_64-linux-gnu",
        "cd /src/*", "./configure --prefix=/warpsys-placeholder-prefix ",
        "make", "make DESTDIR=/out install"
    ],
    extra_inputs=[
        ("warpsys.org/zlib", "v1.3", "amd64"),
    ])

step_pack = zapp_pack_step(
    binaries=["python3", "python3.10"],
    extra_inputs=[
        ("warpsys.org/zlib", "v1.3", "amd64"),
        ("warpsys.org/findutils", "v4.9.0-2", "amd64"),
    ],
    libraries=[
        ("warpsys.org/bootstrap/glibc", "libc.so.6"),
        ("warpsys.org/bootstrap/glibc", "libdl.so.2"),
        ("warpsys.org/bootstrap/glibc", "libm.so.6"),
        ("warpsys.org/bootstrap/glibc", "libpthread.so.0"),
        ("warpsys.org/bootstrap/glibc", "libutil.so.1"),
        ("warpsys.org/bootstrap/glibc", "libcrypt.so.1"),
        ("warpsys.org/zlib", "libz.so.1"),
    ],
    extra_script=["find /pack -type d -name __pycache__ -exec rm -rf {} +"])

# for the pack step to work, the built step must be named "build"
# due to the pipe used in pack
result = plot(steps={"build": step_build, "pack": step_pack})
