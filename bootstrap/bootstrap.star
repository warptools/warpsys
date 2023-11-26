load("warpsys.star", "catalog_input_str")


def bootstrap_build_step(src, script, extra_inputs=[]):
    # build our input map, $PATH, and $CPATH based on the deps
    inputs = {}

    # add the bootstrapping debian rootfs
    inputs["/"] = catalog_input_str(
        ("warpsys.org/bootstrap/debian", "bullseye-1646092800", "amd64"))
    # add the source catalog input
    inputs["/src"] = catalog_input_str(src)

    for i in extra_inputs:
        dest = "/pkg/" + i[0]
        inputs[dest] = catalog_input_str(i)

    # set up the environment vars for the build
    inputs["$SOURCE_DATE_EPOCH"] = "literal:1262304000"
    inputs["$LDFLAGS"] = "literal:-Wl,-rpath=XORIGIN/../lib"
    inputs["$ARFLAGS"] = "literal:rvD"

    # create and return the protoformula
    return {
        "protoformula": {
            "inputs": inputs,
            "action": {
                "script": {
                    "interpreter": "/bin/sh",
                    "contents": script
                }
            },
            "outputs": {
                "out": {
                    "from": "/out/warpsys-placeholder-prefix",
                    "packtype": "tar",
                }
            }
        }
    }


def bootstrap_pack_step(binaries, libraries=[], extra_script=[]):
    # list of dependencies needed for packing
    pack_deps = [
        ("warpsys.org/bootstrap/ldshim", "v1.0", "amd64"),
        ("warpsys.org/bootstrap/glibc", "v2.35", "amd64"),
    ]

    # create input map and $PATH
    inputs = {}
    # add the bootstrapping debian rootfs
    inputs["/"] = catalog_input_str(
        ("warpsys.org/bootstrap/debian", "bullseye-1646092800", "amd64"))
    for dep in pack_deps:
        path = "/pkg/" + dep[0]
        inputs[path] = catalog_input_str(dep)

    # add the output of our build to the inputs
    inputs["/pack"] = "pipe:build:out"

    # create dirs for packing, copy ld to our package as a library
    script = [
        "mkdir -vp /pack/lib", "mkdir -vp /pack/dynbin",
        "cp /pkg/warpsys.org/bootstrap/glibc/lib/ld-linux-x86-64.so.2 /pack/lib"
    ]

    # iterate over the libraries to pack as a (module_name, library_name) tuple
    # for each, create a cp command to add to our package
    for lib in libraries:
        script.append("cp /pkg/{module}/lib/{library} /pack/lib".format(
            module=lib[0], library=lib[1]))

    # iterate over the binaries to pack
    # for each, move the binary to dynbin and add an ldshim in bin
    for bin in binaries:
        script.append("mv /pack/bin/{bin} /pack/dynbin".format(bin=bin))
        script.append(
            "cp /pkg/warpsys.org/bootstrap/ldshim/ldshim /pack/bin/{bin}".
            format(bin=bin))

    # add any extra script actions from the user
    script = script + extra_script

    # apply XORIGIN hack to all dynbin binaries
    script.append("sed -i '0,/XORIGIN/{s/XORIGIN/$ORIGIN/}' /pack/dynbin/*")

    # create and return the protoformula
    return {
        "protoformula": {
            "inputs": inputs,
            "action": {
                "script": {
                    "interpreter": "/bin/sh",
                    "contents": script
                }
            },
            "outputs": {
                "out": {
                    "from": "/pack",
                    "packtype": "tar",
                }
            }
        }
    }


# bootstrap_auto_pack will attempt to detect and move all ELF executable files.
# pathmap selects the paths to map, by default the pathmap will be {"bin": "dynbin"}
# meaning that all ELF binaries in /pack/bin will be mapped to /pack/dynbin recursively.
# '/pack/bin/some-other-dir/myexec' should map to '/pack/dynbin/some-other-dir/myexec'.
# The /pack/bin directory will then be repopulated with shims for the moved files.
def bootstrap_auto_pack_step(binpaths=[], libraries=[], extra_script=[]):
    if len(binpaths) == 0:
        binpaths = ["bin"]

    # list of dependencies needed for packing
    pack_deps = [
        ("warpsys.org/bootstrap/ldshim", "v1.0", "amd64"),
        ("warpsys.org/bootstrap/glibc", "v2.35", "amd64"),
    ]

    # create input map and $PATH
    inputs = {}
    # add the bootstrapping debian rootfs
    inputs["/"] = catalog_input_str(
        ("warpsys.org/bootstrap/debian", "bullseye-1646092800", "amd64"))
    for dep in pack_deps:
        path = "/pkg/" + dep[0]
        inputs[path] = catalog_input_str(dep)

    # add the output of our build to the inputs
    inputs["/pack"] = "pipe:build:out"

    # detect ELF binaries
    # for each, move the binary to dynbin and add an ldshim in bin
    script = ["set -eu"]
    for binpath in binpaths:
        script.extend([
            # ELF header begins with [0x7F, E, L, F, 0x01|0x02, 0x01|0x02, 0x01]
            # Matching at least this should be sufficient to call it an ELF file.
            "find -P /pack/{binpath} -type f -executable | xargs grep -l '^.ELF...' >/tmp/pack_bin_list".format(binpath=binpath),
            # Create lib/dynbin directories
            "xargs -a /tmp/pack_bin_list dirname | xargs dirname | sort | uniq >/tmp/pack_bin_dirs",
            "xargs -I_ -a /tmp/pack_bin_dirs mkdir -vp _/lib",
            "xargs -I_ -a /tmp/pack_bin_dirs mkdir -vp _/dynbin",
        ])
        # iterate over the libraries to pack as a (module_name, library_name) tuple
        # for each, create a cp command to add to our package at
        for lib in libraries:
            script.append("xargs -t -I_ -a /tmp/pack_bin_dirs cp /pkg/{module}/lib/{library} _/lib".format(
                module=lib[0], library=lib[1]))

        script.extend([
            # Add linker to lib dir
            "xargs -t -I_ -a /tmp/pack_bin_dirs cp /pkg/warpsys.org/bootstrap/glibc/lib/ld-linux-x86-64.so.2 _/lib",
            # Move bin to dynbin and shim original locations
            "while read -r binpath; do " + " ; ".join([
                'dirpath=$(dirname $(dirname "${binpath}" ))',
                'mv -v "$binpath" "${dirpath}/dynbin/"',
                'cp -v /pkg/warpsys.org/bootstrap/ldshim/ldshim "${binpath}"',
                "done < /tmp/pack_bin_list",
            ]),
            "while read -r dirpath; do " + " ; ".join([
                # apply XORIGIN hack to all dynbin binaries
                "sed -i '0,/XORIGIN/{{s/XORIGIN/$ORIGIN/}}' ${dirpath}/dynbin/*",
                "done < /tmp/pack_bin_dirs",
            ])
        ])

    # add any extra script actions from the user
    script = script + extra_script

    # create and return the protoformula
    return {
        "protoformula": {
            "inputs": inputs,
            "action": {
                "script": {
                    "interpreter": "/bin/sh",
                    "contents": script
                }
            },
            "outputs": {
                "out": {
                    "from": "/pack",
                    "packtype": "tar",
                }
            }
        }
    }
