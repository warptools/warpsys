#+warplark version 0
load("warpsys.star", "plot")
load("warpsys.star", "catalog_input_str")
load("warpsys.star", "gnu_build_step")

step_build = gnu_build_step(
    src=("warpsys.org/zlib", "v1.3", "src"),
    script=[
        "cd /src/*", "./configure --prefix=/warpsys-placeholder-prefix",
        "make", "make DESTDIR=/out install"
    ])

# for the pack step to work, the built step must be named "build"
# due to the pipe used in pack
result = plot(steps={"build": step_build}, outputs={"amd64": "pipe:build:out"})
