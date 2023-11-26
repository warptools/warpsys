#+warplark version 0
load("warpsys.star", "plot")
load("warpsys.star", "catalog_input_str")
load("warpsys.star", "gnu_build_step")
load("warpsys.star", "zapp_pack_step")

step_build = gnu_build_step(("warpsys.org/perl", "v5.36.0", "src"), [
    "ln -s /pkg/warpsys.org/bootstrap/gcc/bin/gcc /bin/cc",
    "ln -s /pkg/warpsys.org/bootstrap/gcc/bin/cpp /lib/cpp", "cd /src/*",
    "sh Configure -Dcc=/pkg/warpsys.org/bootstrap/gcc/bin/gcc -Dprefix=/warpsys-placeholder-prefix -Aldflags=-Wl,-rpath=XORIGIN/../lib -Aarflags=rvD -de",
    "make", "make DESTDIR=/out install",
    "sed -i '0,/XORIGIN/{s/XORIGIN/$ORIGIN/}' /out/warpsys-placeholder-prefix/bin/*"
])

step_pack = zapp_pack_step(
    binaries=["perl", "perl5.36.0"],
    libraries=[
        ("warpsys.org/bootstrap/glibc", "libc.so.6"),
        ("warpsys.org/bootstrap/glibc", "libdl.so.2"),
        ("warpsys.org/bootstrap/glibc", "libm.so.6"),
        ("warpsys.org/bootstrap/glibc", "libcrypt.so.1"),
    ],
    extra_script=[
        "sed -i \"s/\\$config_tag1 = '\\([^ ]\\+\\)*.*/\\$config_tag1 = '\\1'/\" /pack/bin/perlbug /pack/bin/perlthanks",
        "sed -i \"s/Configuration time:.*//\" /pack/lib/perl5/5.36.0/x86_64-linux/CORE/config.h /pack/lib/perl5/5.36.0/x86_64-linux/Config_heavy.pl",
        "sed -i \"s/cf_time='[^']\\+/cf_time='`date --date='@1262304000'`/\" /pack/lib/perl5/5.36.0/x86_64-linux/Config_heavy.pl",
        "sed -i \"s/Target system.*//\" /pack/lib/perl5/5.36.0/x86_64-linux/CORE/config.h /pack/lib/perl5/5.36.0/x86_64-linux/Config_heavy.pl",
        "sed -i \"s/myuname='.*/myuname='linux'/\" /pack/lib/perl5/5.36.0/x86_64-linux/Config_heavy.pl",
        "sed -i \"s/[[:digit:]]\\+.[[:digit:]]\\+.[[:digit:]]\\+-[[:digit:]]\\+/linux/\" /pack/lib/perl5/5.36.0/x86_64-linux/Errno.pm /pack/lib/perl5/5.36.0/x86_64-linux/CORE/config.h /pack/lib/perl5/5.36.0/x86_64-linux/Config_heavy.pl /pack/lib/perl5/5.36.0/x86_64-linux/Config.pm"
    ])

result = plot(steps={"pack": step_pack, "build": step_build})
