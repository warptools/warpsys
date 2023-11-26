#+warplark version 0
load("../../warpsys.star", "plot")
load("../../warpsys.star", "catalog_input_str")
load("../bootstrap.star", "bootstrap_build_step")
load("../bootstrap.star", "bootstrap_pack_step")

step_build = bootstrap_build_step(
    src=("warpsys.org/ldshim", "v1.0", "src"),
    script=[
        "mkdir -p /out/warpsys-placeholder-prefix/bin", "cd /src", "make",
        "cp ldshim /out/warpsys-placeholder-prefix/bin"
    ])

result = plot(steps={"build": step_build})
