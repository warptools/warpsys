def plot(inputs={}, steps={}, outputs={}):
    plot = {"inputs": inputs, "steps": steps, "outputs": outputs}
    return plot


def catalog_input_str(input):
    return "catalog:{module}:{release}:{item}".format(module=input[0],
                                                      release=input[1],
                                                      item=input[2])


def script_protoformula(inputs, interp, script):
    pathstr = "literal:"
    for i in inputs.keys():
        pathstr = pathstr + "{path}/bin:".format(path=i)
        inputs["$PATH"] = pathstr
        protoformula = {
            "protoformula": {
                "inputs": inputs,
                "action": {
                    "script": {
                        "interpreter": interp,
                        "contents": script
                    }
                },
                "outputs": {}
            }
        }
    return protoformula


def gnu_build_step(src, script, extra_inputs=[]):
    # define the default deps for building
    build_deps = [
        ("warpsys.org/bootstrap/glibc", "v2.35", "amd64"),
        ("warpsys.org/bootstrap/busybox", "v1.35.0", "amd64"),
        ("warpsys.org/bootstrap/ldshim", "v1.0", "amd64"),
        ("warpsys.org/bootstrap/make", "v4.3", "amd64"),
        ("warpsys.org/bootstrap/gcc", "v11.2.0", "amd64"),
        ("warpsys.org/bootstrap/grep", "v3.7", "amd64"),
        ("warpsys.org/bootstrap/coreutils", "v9.1", "amd64"),
        ("warpsys.org/bootstrap/binutils", "v2.38", "amd64"),
        ("warpsys.org/bootstrap/sed", "v4.8", "amd64"),
        ("warpsys.org/bootstrap/gawk", "v5.1.1", "amd64"),
        ("warpsys.org/findutils", "v4.9.0-2", "amd64"),
        ("warpsys.org/diffutils", "v3.8", "amd64"),
    ] + extra_inputs

    # build our input map, $PATH, and $CPATH based on the deps
    inputs = {}
    pathstr = "literal:"
    cpathstr = "literal:"
    ldpathstr = "literal:"
    for dep in build_deps:
        path = "/pkg/" + dep[0]
        inputs[path] = catalog_input_str(dep)
        pathstr = pathstr + path + "/bin:"
        cpathstr = cpathstr + path + "/include:"
        ldpathstr = ldpathstr + path + "/lib:"
        cpathstr = cpathstr + "/pkg/warpsys.org/bootstrap/glibc/include/x86_64-linux-gnu"

    # add the source catalog input
    inputs["/src"] = catalog_input_str(src)

    # add the dynamic linker (ld) to /lib64
    inputs["/lib64"] = catalog_input_str(
        ("warpsys.org/bootstrap/glibc", "v2.35", "ld-amd64"))

    # set up the environment vars for the build
    inputs["$PATH"] = pathstr
    inputs["$CPATH"] = cpathstr
    inputs["$LD_LIBRARY_PATH"] = ldpathstr
    inputs["$SOURCE_DATE_EPOCH"] = "literal:1262304000"
    inputs["$LDFLAGS"] = "literal:-Wl,-rpath=XORIGIN/../lib"
    inputs["$ARFLAGS"] = "literal:rvD"

    # this script runs before the build script to set up the environment
    setup_script = [
        "mkdir -p /bin /tmp /prefix /usr/include/",
        "ln -s /pkg/warpsys.org/bootstrap/glibc/lib /prefix/lib",
        "ln -s /pkg/warpsys.org/bootstrap/glibc/lib /lib",
        "ln -s /pkg/warpsys.org/bootstrap/busybox/bin/sh /bin/sh",
        "ln -s /pkg/warpsys.org/bootstrap/gcc/bin/cpp /lib/cpp"
    ]
    script = setup_script + script

    # create and return the protoformula
    return {
        "protoformula": {
            "inputs": inputs,
            "action": {
                "script": {
                    "interpreter": "/pkg/warpsys.org/bootstrap/busybox/bin/sh",
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


def zapp_pack_step(binaries, libraries=[], extra_script=[], extra_inputs=[]):
    # list of dependencies needed for packing
    pack_deps = [
        ("warpsys.org/bootstrap/sed", "v4.8", "amd64"),
        ("warpsys.org/bootstrap/busybox", "v1.35.0", "amd64"),
        ("warpsys.org/bootstrap/glibc", "v2.35", "amd64"),
        ("warpsys.org/bootstrap/ldshim", "v1.0", "amd64"),
    ] + extra_inputs

    # create input map and $PATH
    inputs = {}
    pathstr = "literal:"
    for dep in pack_deps:
        path = "/pkg/" + dep[0]
        inputs[path] = catalog_input_str(dep)
        pathstr = pathstr + path + "/bin:"
        inputs["$PATH"] = pathstr

    # add the output of our build to the inputs
    inputs["/pack"] = "pipe:build:out"
    # add ld to our inputs so we can execute dynamic binaries
    inputs["/lib64"] = catalog_input_str(
        ("warpsys.org/bootstrap/glibc", "v2.35", "ld-amd64"))

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
                    "interpreter": "/pkg/warpsys.org/bootstrap/busybox/bin/sh",
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
