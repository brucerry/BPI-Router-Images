#!/bin/bash

time {
    sudo losetup -D
    sudo umount -l ubuntu_noble_arm64
    sudo rm -rf ubuntu_noble_arm64 noble_arm64.tar.gz
    git restore .
    ./buildimg.sh bpi-r3 noble
}
