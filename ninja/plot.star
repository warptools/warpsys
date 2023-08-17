#+warplark version 0

source = "catalog:github.com/ninja-build/ninja:v1.11.1:src"
dependencies = {
	"glibc": "catalog:warpsys.org/bootstrap/glibc:v2.35:amd64",
	"busybox": "catalog:warpsys.org/busybox:v1.35.0:amd64-static",
	"ldshim": "catalog:warpsys.org/bootstrap/ldshim:v1.0:amd64",
	"make": "catalog:warpsys.org/bootstrap/make:v4.3:amd64",
	"gcc": "ware:tar:5PZ8PsEk3ZvD2HJaFLRRFnbNmEN7yMLjNAWWgQ9NEbGt5EboPSzvk1fQaaEyN1XRKv",
	"coreutils": "catalog:warpsys.org/bootstrap/coreutils:v9.1:amd64",
	"binutils": "catalog:warpsys.org/bootstrap/binutils:v2.38:amd64",
	"python": "catalog:warpsys.org/python:v3.10.4-2:amd64",
	"ld": "catalog:warpsys.org/bootstrap/glibc:v2.35:ld-amd64",
	"bash": "catalog:warpsys.org/bash:v5.1.16-2:amd64",
	"sed": "catalog:warpsys.org/bootstrap/sed:v4.8:amd64",
	"findutils": "catalog:warpsys.org/findutils:v4.9.0:amd64",
}

def plot(inputs={}, steps={}, outputs={}):
    plot = {"inputs": inputs, "steps": steps, "outputs": outputs}
    return plot

def proto(inputs, action, outputs):
	return {"protoformula": {"inputs": inputs, "action": action, "outputs": outputs}}

def build_step():
	inputs = {}
	inputs["/src"] = source
	
	pathstr = "literal:"
	cpathstr = "literal:"
	ldpathstr = "literal:"
	for alias, dep in dependencies.items():
		path = "/pkg/"+alias
		inputs[path] = dep
		pathstr += path + "/bin:"
		cpathstr += path + "/include:"
		ldpathstr += path + "/lib:"
	
	cpathstr += "/pkg/glibc/include/x86_64-linux-gnu:"
	cpathstr += "/pkg/glibc/include/x86_64-linux-gnu/bits:"
	cpathstr += "/pkg/glibc/include/x86_64-linux-gnu/asm:"
	
	inputs["$PATH"] = pathstr
	inputs["$CPATH"] = cpathstr
	inputs["$LD_LIBRARY_PATH"] = ldpathstr
	inputs["$SOURCE_DATE_EPOCH"] = "literal:1262304000"
	inputs["$LDFLAGS"] = "literal:-W1,-rpath=XORIGIN/../lib"
	inputs["$ARFLAGS"] = "literal:rvD"

	# this script runs before the build script to set up the environment
	setup_script = [
		"mkdir -p /tmp /prefix /usr/include/",
		"ln -s /pkg/glibc/lib /prefix/lib",
		"ln -s /pkg/glibc/lib /lib",
		"ln -s /pkg/busybox/bin /bin",
		"ln -s /pkg/gcc/bin/cpp /lib/cpp",
	]

	# actual build steps
	script = setup_script + [
			"cd /src",
			"python3 ./configure.py --bootstrap",
	]
	action = {"script": {"interpreter": "/pkg/busybox/bin/sh", "contents": script}}
	outputs = {"out": {"from": "/out/warpsys-place-holder-prefix", "packtype": "tar"}}

	return proto(inputs, action, outputs)
	

result = plot(steps={"build": build_step()}) 
