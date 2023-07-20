#!/bin/bash

ROOT=$(pwd)

config_linux ()
{
    make -C ${ROOT}/linux ARCH=x86_64  O=${ROOT}/linux_output menuconfig
}

build_linux ()
{
    make -C ${ROOT}/linux ARCH=x86_64 O=${ROOT}/linux_output -j12
}

export_header ()
{
    make headers_install -C ${ROOT}/linux ARCH=x86_64  INSTALL_HDR_PATH=/Volumes/xcompile/x86_64-linux-gnu/sys-root/usr

}

run_bash ()
{
    /bin/bash
}

copy_app () {
    losetup /dev/loop1 /Code/build_linux/rootfs.ext4
    mount /dev/loop1 /mnt

    cp /Code/build_linux/a.out /mnt/a.out

    umount /mnt
    losetup -d /dev/loop1

}


if [[ $# -gt 0 ]]
then
    if [[ $1 = 'config' ]]
    then
        config_linux
    elif [[ $1 = 'build' ]]
    then
        build_linux
    elif [[ $1 = 'header' ]]
    then 
        export_header
    elif [[ $1 = 'copy' ]]
    then
        copy_app
    elif [[ $1 = 'bash' ]]
    then
        run_bash
    fi
    
fi
