4Diac Runtime Environment (FORTE) Build System (4diac-fbe)
==========================================================

This repository contains a build environment for building 4diac FORTE, the
run-time engine of the 4Diac IEC 61499 implementation.  Part of its workflow
is code generation and recompilation of FORTE, and this environment provides
the means to do this with as little effort as possible.

Furthermore, you can manage multiple builds for multiple target platforms.  As
of this writing, it works on Linux and Windows hosts.  There should be no
fundamental issues getting this to work on macOS, but no one did so.  Supported
targets are Linux (x86, ARM, MIPS, …) and Windows as well; again macOS should be
easy to add, others might need some more work.

Cross-compilation is built-in: you can generate binaries for all supported
platforms on a single build host.

The FORTE executable built by this build environment will have all optional
features enabled: OPC-UA, MQTT, modbus, and with an extra setup step also
openPOWERLINK.  It does not enable platform-specific features like OPC (no -UA)
by default, but different builds can have different target-specific
configuration options.

All resulting executables will be statically linked, so there is nothing to
deploy beyond the actual executable file, and it will not depend on any system
packages/features.  Exception: Windows targets will depend on system DLLs that
probably come with Windows since XP, maybe even earlier.  Full-featured
executable size is around 4MB, this varies slightly across targets.


Installation
============

The easiest way to install 4diac-fbe is through an official release: Check out
the `release` branch of `4diac-fbe` and copy either `scripts/compile.sh` or
`scripts/compile.cmd` to the toplevel directory.  That's all.

IMPORTANT NOTE for Windows users: By default, Windows has a rather short file
name length limit.  It is therefore recommended to use an installation
directory close to the root of your drive, like ``D:\4diac-fbe``. Also, avoid
a path containing whitespace.

The first time you run the compile script, the build environment will be set
up by securely downloading and installing a binary release of
`4diac-toolchains`.  If cross-compiling 4diac FORTE for a new target for the
first time, the build environment will download an appropriate cross-compiler
from the current `4diac-toolchains` release.


Updating
--------

If you run this from the git `release` branch, simply update the repo and all
subrepositories in place. In case there were significant toolchain updates,
run `toolchains/etc/bootstrap/clean.sh` to force downloading a current
toolchain release.


Usage
=====


Compiling a runtime executable
------------------------------

Builds are executed by ``./compile.sh``.  For convenience, a Windows
``compile.cmd`` allows single-doubleclick-builds with no console interaction
on Windows. If run in this way, all configurations are built (see below). The
final binaries will be created at ``build/<config-name>/output/bin``.

In order to start over (i.e., to rebuild everything from scratch), delete
subdirectory ``build``. This should never be needed for simple code or
configuration changes. However, if you change library recipes in subdirectory
``dependencies``, then such a clean restart may be neccessary.

You can also build executables outside the `4diac-fbe` directory.  In your
desired target directory, create a subdirectory `configurations` just like
the one in `4diac-fbe` and call `compile.sh`/`compile.cmd` with your target
directory as the current working directory. This will create the `build`
directory in this location instead of the `4diac-fbe` directory, allowing you
to reuse a single 4diac-fbe installation for multiple projects.


Configuration management
------------------------

By default, the build script will build FORTE for all configurations present in
subdirectory ``configurations``.  Every time the script is called, it will
update all builds with the exact same configuration.  The resulting executables
are located in subdirectory ``output``.

You may customize builds by copying and modifying the default configuration file
``configurations/native-toolchain.txt``. By default, all configurations present
in that directory will be built. To temporarily disable a configuration, rename
it so that it does not end in ``.txt`` anymore.

If you want to build just a single configuration, specify its base name on the
command line.  Example: ``./compile.sh native-toolchain`` only builds the
default version configured through ``configurations/native-toolchain.txt``.

In order to manage complex sets of configurations, you can organize them in
subdirectories. Configurations in a subdirectory will not be built by default.
To process an entire subdirectory instead of the default set of configurations,
specify its name on the command line, e.g. ``./compile.sh configurations/test``.
Note that configuration names must still be unique, even when separated into
different directories (i.e. no two files with the same name in different
configuration directories).


Cross Compilation
-----------------

You can select a cross-compiled build by setting ``ARCH`` in the build
configuration file (see above).  If cross-compiling 4diac FORTE for a new
target architecture for the first time, the build environment will download
an appropriate cross-compiler from the current `4diac-toolchains` release.
See `toolchains/etc/crosscompilers.sha256` for a list of pre-built
crosscompilers for the current release.


Adding generated function blocks
--------------------------------

When designing new Basic Function Blocks, Composite Function Blocks or Service
Function Blocks, the runtime has to be re-compiled to include code generated by
4DIAC-IDE.  This is the original reason this build system was created.

To add your own blocks, place the code generated by 4DIAC-IDE into
``Modules/EclipseGeneratedFBs/generated/``.  During the next build, it will be
moved into ``Modules/EclipseGeneratedFBs/edited/``, where you can edit it as you
like.  Do not edit it while it is in ``.../generated/``; run a build first, then
edit, then rebuild!

When you export code into ``.../generated/`` again, the build system will make
sure that your changes will not be overwritten.  Most of the time, it will keep
them perfectly intact; if it can't do so automatically, the build will abort and
tell you how to resolve the situation manually.


Adding custom FORTE modules
---------------------------

If you write custom FORTE modules, put them into their own subdirectories below
``Modules``.

You can place the type definition files for 4diac IDE into subdirectory
``Types``. The idea is that you copy the contents of the ``Types`` directory
into new 4diac projects to get access to all custom modules.

The git repository has been set up to ignore all modules by default. If you
want to add modules to a local branch or fork, put the following `.gitignore`
file into your module directory:

```
!*
```

That way you can selectively manage modules in subrepos or local branches and
leave other modules unmanaged as needed.


Adding external code
--------------------

If your code has additional dependencies, put them as ``cget`` recipes into
subdirectory ``dependencies/recipes``, then add the package name to the ``DEPS``
setting in the build configuration file (see above). In the configuration file,
you can also add any additional CMake settings required for your code, for
example additional compiler flags in ``EXTRA_COMPILER_FLAGS`` or additional
dependency packages in ``DEPS``. See ``configurations/native-toolchain.txt``
for some common examples.

For well-known external libraries, you might find ``cget`` recipes at
https://github.com/pfultz2/cget-recipes/tree/master/recipes/ -- but be aware
that some of these will need manual adaptions for static linking.

If you have to use pre-built external libraries (e.g. due to proprietary code or
huge external packages that take a lot of effort to build), you will need a
toolchain based on the GNU C library instead of the default MUSL-based
toolchains. These contain ``-gnu`` in their name and support dynamic linking,
but the drawback is more complicated distribution. The build system tries to
create a self-contained ``bin`` directory containing all dependency files, but
the result still might not be sufficient to run on a different system. This
depends on many details, you have been warned. Avoid it if you can.


Debugging Compile Problems
--------------------------

If you have unexplainable compiler errors or missing include files or things
like that, you can use the option ``./compile.sh -v ...`` to force the build to
be single-threaded and output the individual compiler command lines. This helps
you to get more readable error outpu and check that all appropriate search paths
and compiler options have been set. NOTE: you must delete the build directory
``build/<config-name>/`` every time you switch between verbose builds and normal
builds!
