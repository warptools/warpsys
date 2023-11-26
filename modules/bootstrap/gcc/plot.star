#+warplark version 0
load("../../warpsys.star", "plot")
load("../../warpsys.star", "catalog_input_str")
load("../bootstrap.star", "bootstrap_build_step")
load("../bootstrap.star", "bootstrap_auto_pack_step")

step_build = bootstrap_build_step(
    src=("warpsys.org/gcc", "v11.2.0", "src"),
    extra_inputs=[
        ("warpsys.org/mpfr", "v4.1.0", "src"),
        ("warpsys.org/gmp", "v6.2.1", "src"),
        ("warpsys.org/mpc", "v1.2.1", "src"),
    ],
    script=[
        "set -eu",
        #"export BOOT_CFLAGS=\"$CFLAGS\"", # We don't have any of these, at present.
        # LDFLAGS, though, is important: This contains the XORIGIN hack.  The bootstrap lark lib inserted it already.
        "export BOOT_LDFLAGS=\"$LDFLAGS\"", # This is a GCC special sauce for "phase 2".
        "export LDFLAGS_FOR_TARGET=\"$LDFLAGS\"", # This is a GCC special sauce for "phase 3".
        "cd /src/*",
        "cp -vpR -v /pkg/warpsys.org/mpfr/* mpfr", # FUTURE: can this be replaced with symlinks?  wasteful of time.
        "cp -vpR -v /pkg/warpsys.org/gmp/* gmp",
        "cp -vpR -v /pkg/warpsys.org/mpc/* mpc",
        "mkdir -p /prefix/build",
        # Create an extremely cursed ld shim, because I can't figure how how to get flags through gcc any other way.
        # (This doesn't use our existing $LDFLAGS var because that contains "-Wl," preambles, which aren't necessary when pushing the flags in at this depth.)
        "echo \"ld -rpath=XORIGIN/../lib \\$@\" > /prefix/cursed-ld ; chmod +x /prefix/cursed-ld",
        "cd /prefix/build",
        # Disabling "boostrap" saves time and skips a step that's not interesting to us.  (We check sanity in other ways.)
        "/src/*/configure --prefix=/warpsys-placeholder-prefix --disable-bootstrap --disable-multilib --enable-languages=c,c++ --with-ld=/prefix/cursed-ld LDFLAGS=$LDFLAGS",
        "make", "make DESTDIR=/out install"
    ])

step_pack = bootstrap_auto_pack_step(
                            binpaths=["bin", "libexec"],
                            libraries=[
                                    ("warpsys.org/bootstrap/glibc",
                                     "libc.so.6"),
                                    ("warpsys.org/bootstrap/glibc",
                                     "libm.so.6"),
                                    ("warpsys.org/bootstrap/glibc",
                                    "libdl.so.2"),
                                ])


result = plot(
    steps={
        "build": step_build,
        "pack": step_pack,
        "test":  {"protoformula": {
            "inputs": {
                "/": "catalog:warpsys.org/busybox:v1.35.0-2:amd64-static",
                "/app/binutils": "catalog:warpsys.org/bootstrap/binutils:v2.38:amd64",
                "/testme": "pipe:pack:out"
            },
            "action": {"script": {
                "interpreter": "/bin/sh",
                "contents": [
                    "/app/binutils/bin/readelf -d /testme/dynbin/gcc",
                    "/testme/bin/gcc --version"
                ]
            }},
            "outputs": {}
        }},
    },
    outputs={"out":"pipe:pack:out"},
)
