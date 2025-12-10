#!/bin/sh
set -e

if [ "$1" != "--fbe-inside-userns" ]; then
	fberoot="$(cd "$(dirname "$0")"/..; pwd)"
	testroot="$fberoot/build/testroot.$$"
	mkdir -p "$testroot"
	cd "$testroot"

	exec unshare --user --map-root-user --mount-proc --pid --fork "../../scripts/$(basename "$0")" --fbe-inside-userns "$@"
fi

shift

fbedir="4diac-fbe-${PWD##*/}"
mkdir -p bin dev etc proc tmp "$fbedir"

ln -s "../$fbedir/toolchains/bin/sh" bin/
export SHELL=/bin/sh

touch dev/null
mount --bind /dev/null dev/null

cp /etc/resolv.conf etc/

ln -s "$fbedir/toolchains/x86_64-linux-gnu/x86_64-buildroot-linux-gnu/sysroot/lib" .
ln -s lib lib64

mount -t proc proc proc

mount --bind ../.. "$fbedir"

exec /usr/sbin/chroot . /bin/sh -c 'cd "$0"; ./compile.cmd "$@"' "$fbedir" "$@"
