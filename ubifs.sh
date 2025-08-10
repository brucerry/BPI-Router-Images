#!/bin/bash
# some parts are from here: https://github.com/openwrt/openwrt/blob/main/scripts/ubinize-image.sh

board=$1

ubivol() {
	local volid="$1"
	local name="$2"
	local image="$3"
	local autoresize="$4"
	local size="$5"
	local voltype="${6:-dynamic}"
	echo "[$name]"
	echo "mode=ubi"
	echo "vol_id=$volid"
	echo "vol_type=$voltype"
	echo "vol_name=$name"
	if [ "$image" ]; then
		if [[ -e $image ]];then
			echo "image=$image"
		fi
		[ -n "$size" ] && echo "vol_size=${size}"
	else
		echo "vol_size=1MiB"
	fi
	if [[ "$autoresize" == "1" ]]; then
		echo "vol_flags=autoresize"
	fi
}

rm -r ./ubifs
mkdir -p ./ubifs/

python3 downloadfiles.py ${board} 6.12 spim-nand

. sourcefiles_${board}.conf

if [[ -z "$initrd" ]];then
	FILEID=1g0lGE8OlYqvhhkAAn-9pI8qRA7IYx22S
	filename=initrd.zst
	wget --no-check-certificate -O $filename \
		"https://drive.usercontent.google.com/download?id=${FILEID}&confirm=t"
	if [[ $? -eq 0 ]];then
		initrd=$filename
		echo "initrd=$initrd" >>  sourcefiles_${board}.conf
	fi
fi
touch ./ubifs/uEnv.txt
if [[ -n "$initrd" ]];then
	cp $initrd ./ubifs/
	if [[ $? -eq 0 ]];then
		echo "initrd=$initrd" > ./ubifs/uEnv.txt
	fi
	ls -lh ./ubifs/
fi
#cp ${kernelfile} ./ubifs/
echo $kernelfile
tar -xzf ${kernelfile} --strip-components=1 -C ./ubifs/ --wildcards 'BPI-BOOT/*.itb'

mkfs.ubifs -m 2048 -e 124KiB -c 800 -r ./ubifs/ rootfs.ubifs

#[fip_volume]
#mode=ubi
#image=fip.ubifs
#vol_id=1
#vol_size=1MiB
#vol_name=fip
#vol_alignment=1

#[ubootenv_volume]
#mode=ubi
#image=ubootenv.ubifs
#vol_id=2
#vol_size=128KiB
#vol_name=ubootenv
#vol_alignment=1

#[ubootenv2_volume]
#mode=ubi
#image=ubootenv.ubifs
#vol_id=3
#vol_size=128KiB
#vol_name=ubootenv2
#vol_alignment=1

#[rootfs_volume]
#mode=ubi
#image=rootfs.ubifs
#vol_id=4
#vol_size=50MiB
#vol_type=dynamic
#vol_name=rootfs
#vol_alignment=1
#vol_flags=autoresize

if [[ -z "${fipfile}" ]]; then
	echo "fip file not defined";
	exit 1;
fi
(
# id name image autoresize size type
ubivol 1 fip ${fipfile} 0 1MiB
ubivol 2 ubootenv none.bin 0 128KiB
ubivol 3 ubootenv2 none.bin 0 128KiB
ubivol 4 rootfs rootfs.ubifs 1 50MiB
) > ubi.conf

peb_size=128
min_io_size=2048
ubinize -vv -o ${board}_nand.img -m ${min_io_size} -p ${peb_size}KiB ubi.conf
if [[ $? -eq 0 ]];then
	echo "${board}_nand.img created..."
fi
