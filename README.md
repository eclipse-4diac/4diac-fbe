# 4Diac Runtime Environment (FORTE) Build System

This repository contains a build environment for building FORTE, the run-time
engine of the 4Diac IEC 61499 implementation.  Part of its workflow is code
generation and recompilation of FORTE, and this environment provides the
means to do this with as little effort as possible.

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


## Installation

In case you have got a packaged runtime ZIP file and some accompanying toolchain
files (including a subdirectory ``Windows`` or ``Linux``), just put all files
into an empty directory -- but leave out the platform subdirectory that does not
apply to you (Linux/Windows).  Then run ``install.cmd`` or ``./install.sh``.

IMPORTANT NOTE for Windows users: By default, Windows has a rather short file
name length limit. It is therefore recommended to use an installation directory
close to the root of your drive, like ``D:\4diac-runtime``.

The first time you run one of these scripts, the build environment will be set
up.  If you have all neccessary toolchain files, this just means extracting them
into the correct folders.  Otherwise, a lengthy bootstrap process is executed,
so using pre-packaged toolchain files is heavily recommended.

Furthermore, each target configuration will first have its dependencies built.
The second build will be much faster, as only the FORTE runtime is re-built.


### Updating

If you have a working installation and get an updated packaged runtime ZIP file,
the update procedure works in a few easy steps:

 1. rename your old runtime directory, e.g. into ``runtime.old``
 2. extract runtime zip into the now *empty* old folder, e.g. ``runtime``
 3. remove the new toolchains directory ``runtime/toolchains``
 4. move the old toolchains directory to the new runtime folder
 5. copy configurations from ``configurations`` to the new runtime as needed
 6. copy custom dependencies, modules, types, and other extra files as needed

Once you have made sure your code works fine using the new runtime build
environment, you can delete the old runtime directory. To switch back to the old
runtime, just rename the folders and move the toolchains directory back.


# Usage

### Compiling a runtime executable

Builds are executed by ``./compile.sh``.  For convenience, a Windows
``compile.cmd`` allows single-doubleclick-builds with no console interaction on
Windows.

In order to start over (i.e., to rebuild everything from scratch), delete
subdirectories ``cget``, ``build``, and ``output``. This should never be needed
for simple code or configuration changes. However, if you change build
instructions below subdirectory ``dependencies``, then such a clean restart may
be neccessary.


### Configuration management

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


### Cross Compilation

If your ``toolchains`` directory has cross-compilers installed, you can select a
cross-compiled build by setting ``ARCH`` in the build configuration file (see
above).  There is a file ``README.rst`` inside that directory that shows you how
to add cross-compilers.


### Adding generated function blocks

When designing new Basic Function Blocks, Composite Function Blocks or Service
Function Blocks, the runtime has to be re-compiled to include code generated by
4DIAC-IDE.  This is the main reason this build system exists.

To add your own blocks, place the code generated by 4DIAC-IDE into
``Modules/EclipseGeneratedFBs/generated/``.  During the next build, it will be
moved into ``Modules/EclipseGeneratedFBs/edited/``, where you can edit it as you
like.  Do not edit it while it is in ``.../generated/``; run a build first, then
edit, then rebuild!

When you export code into ``.../generated/`` again, the build system will make
sure that your changes will not be overwritten.  Most of the time, it will keep
them perfectly intact; if it can't do so automatically, the build will abort and
tell you how to resolve the situation manually.


### Adding custom FORTE modules

If you write custom FORTE modules, put them into their own subdirectories below
``Modules``.

You can place the type definition files for 4diac IDE into subdirectory
``Types``. The idea is that you copy the contents of the ``Types`` directory
into new 4diac projects to get access to all custom modules.


### Adding external code

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


### Debugging Compile Problems

If you have unexplainable compiler errors or missing include files or things
like that, you can use the option ``./compile.sh -v ...`` to force the build to
be single-threaded and output the individual compiler command lines. This helps
you to get more readable error outpu and check that all appropriate search paths
and compiler options have been set. NOTE: you must delete the build directory
``build/<config-name>/`` every time you switch between verbose builds and normal
builds!
