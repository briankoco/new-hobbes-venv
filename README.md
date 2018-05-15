# Hobbes-venv

Scripts and infrastructure for generating simple busybox Linux environments
compatible with the Hobbes node virtualization layer (NVL)

### Prerequisites

If you just want to play around with the infrastructure, a pre-built isoimage
containing busybox and a 4.16.7 Linux kernel is shipped with this repository
(`images/linux4-16-7-with-nvl.iso`). This image can boot on raw x86_64 hardware,
but it is easier to play around with via QEMU. Prerequisites for this image
are:

* QEMU 2.7<sup>1</sup>

On the other hand, if you want to be able to build images with full NVL support
and with your own custom kernel images, you need the following:

* QEMU 2.7<sup>1</sup>
* Autoconf
* Autoheader
* gcc
* git
* Compiled version of the Linux kernel<sup>2</sup>

<p>
<sup>1</sup>
<sub>If you want **Palacios virtualization** support in the image, then you
need to have at least QEMU version 2.7 installed. This is because older
versions of QEMU do not properly expose MSRs needed to support nested
virtualization. The rest of the NVL infrastructure (Leviathan, XEMEM, Pisces,
Petos) will function with older versions of QEMU. It is not difficult to install
QEMU via source, should you desire Palacios functionality
</sub>
<br>
<sup>2</sup>
<sub>A compiled kernel is required (i.e., a <code>bzImage</code>), not just
kernel headers. Headers are sufficient for building several of the Hobbes NVL
components, but an image is needed for booting into the environment.
</sub>
</p>

## Getting Started

### Quick Start

Invoke: 

    ./run-in-qemu.sh images/lnx4-16-7-with-nvl.iso

to boot a pre-built version of the Hobbes NVL with version 4.16.7 of the Linux
kernel via QEMU/KVM

### Customizing your Builds

If you plan to make modifications to the Hobbes NVL components, or you want to
add different utilities/applications/etc. to the initramfs, then you will need
to setup a build environment. 

1. The first step to do so is to run the setup script:

    ```
    ./setup.sh
    ```

    This will clone any required external repositories, and then configure and
    complile them.

2. Open the `config.sh` file with a text editor of choice. In it, you will see
   several environment variables required by the build process. Most have default
   values that you probably don't need to modify at first. *The one exception* is
   the `KERNEL_SOURCE` variable, which you must set to the location of the Linux
   source code that you want to run your NVL environment in:
   ```
   KERNEL_SOURCE=${KERNEL_SOURCE:-""}
   ```

   For each variable in `config.sh`, you can modify the value in 1 of 2 ways:
    * Modify the value to the left of the `:-` value to change the default
    * Set the value in your environment

   Once you have determined your desired settings, invoke the build script as follows:

   ```
   key1=val1 key2=val2 ... ./build.sh
    ```

   where key/val pairs are your desired environment values. You can also export them via
   `export` in most shells, rather than prepending them to he `./build.sh` command.
   
3. Assuming you left the `WANT_ISOIMAGE` option on, if the build script
   succeeds you will have an isoimage located in `images/image.iso`. This image
   can now be booted on hardware via, e.g., USB, or loaded via QEMU/KVM using
   the `./run-in-qemu.sh` command. If you chose to disable `WANT_ISOIMAGE`, two
   files will be created: `images/initrd.img` and `images/bzImage`, which are the
   initrd and kernel images respectively, which can also be loaded via QEMU, or booted 
   on hardware via, e.g, PXE.

4. At any point in time you can add additional programs and libraries to the
   initramfs. The safest way to do so is to compile everything statically in your
   host build environment and then copy the binaries into the initramfs (e.g.,
   under the opt/ directory). However, dynamic binaries are supported as well,
   provided all of their shared libraries are present. You can use `ldd` on the
   binary to determine its dependencies, and if they are not present under
   `initramfs/lib` , you will need to manually copy them in.


### `config.sh` configuration options

This section enumerates the `config.sh` configuration options:

* `KERNEL_SOURCE`: top level directory of a **pre-compiled** Linux kernel
* `WANT_LEVIATHAN`: (0/1) whether or not to install the
  [Leviathan](http://www.prognosticlab.org/leviathan/) framework in your initramfs
    * **Note:**Currently, Leviathan utilities must be pre-compiled using the
      setup scripts in the [Leviathan repository](https://gitlab.prognosticlab.org/prognosticlab/leviathan)
    * See the section Building Leviathan below

* `LEVIATHAN_SOURCE`: top level directory of a **pre-compiled** Leviathan source tree.
  Only used if `WANT_LEVIATHAN` is set to 1

* `WANT_MODULES`: (0/1) whether or not to install kernel modules from `KERNEL_SOURCE` into
  the `/lib/modules/` directory of the initramfs

* `WANT_ISOIMAGE`: (0/1) whether or not to build an isoimage containing the initramfs and 
  the kernel bzImage

* `WANT_GUEST_ISOIMAGE`: (0/1) whether or not to build an isoimage containing
  the `guest-initramfs`, and to store this isoimage within the initramfs itself. This is
  useful if you want to run the Palacios VMM in the resulting NVL image

* `GUEST_KERNEL_SOURCE`: top level directory of a **pre-compiled** Linux kernel, but to be
  used as the guest OS kernel. Defaults to `KERNEL_SOURCE`. Only used if `WANT_GUEST_ISOIMAGE`
  is set to 1



### Building Leviathan

If you want to install the full Hobbes NVL infrastructure, you need to download and compile
the Leviathan framework. 

1. First run:
    ```
    git clone https://gitlab.prognosticlab.org/prognosticlab/leviathan.git
    ```

2. You need to ensure that the Leviathan components are built against the same
   version of the Linux kernel that you are specified in `config.sh`. The easiest
   way to do this is to export the following variable in your current shell:

    ```
    export LINUX_KERN=*path to Linux kernel*
    ```

   Then, from the top level of the source code, run:
    ```
    ./setup.sh
    ```

3.
   Finally, invoke:

    ```
    make
    ```

   from the top level of the Leviathan tree to build each of the NVL components against
   this kernel version.

If these steps succeed, you can then set the `WANT_LEVIATHAN` to 1 and
`LEVIATHAN_SOURCE` to the top of the Leviathan source tree in your `config.sh`
file. This will allow the build script to install Leviathan utilities in the
initramfs under the `initramfs/opt/` directory.


## TODO

1. Automate kernel build process
2. Automate Leviathan build process
3. Support mounting of root filesystem

## Authors

* **Brian Kocoloski**
