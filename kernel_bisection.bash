#Usecase is: kernel 6.6.0.arch1 ("bad") has regression and kernel 6.5.9.arch2 ("good") is not. We need make kernel bisection to findout witch commit is cause.

#Articles:
# [1] https://wiki.archlinux.org/title/Bisecting_bugs_with_Git
# [2] https://wiki.archlinux.org/title/Arch_build_system
# [3] https://wiki.archlinux.org/title/Makepkg
# [4] https://wiki.archlinux.org/title/Ccache
# [5] https://wiki.archlinux.org/title/Modprobed-db
# [6] https://wiki.gentoo.org/wiki/Kernel_git-bisect


#PREPARING

#Check needed packages
sudo pacman -Syu --needed git base-devel devtools ccache mold
ccache -M 10G #at least
#then edit /etc/makekpg.conf [3]: 3.3.1, 3.3.4, 3.5 and [4]: 2.1, 3.1

#TODO: Errors when hook do 'mkinitcpio' for now
#Recomended for reducing build kernel time
# git clone https://aur.archlinux.org/modprobed-db.git
# cd modprobed-db && makepkg -fsri && cd .. && rm -rf modpobed-db
#then do [5]: 1-2.1.1, 2.1.3.1


#GET SOURCES
mkdir -p Bisect && cd Bisect #For convinience 

#Get PKGBUILD kernel verion 6.5.9.arch2-1 ("good") [2]: 3.1.1
#Other versions (tags) can be found here: https://gitlab.archlinux.org/archlinux/packaging/packages/linux/-/tags
pkgctl repo clone --protocol=https --switch="6.5.9.arch2-1" linux && cd linux

#Get kernel sources
#If make just git clone you have download about 5Gb sources, so we can download only desired verision of kernel.
#Lowest version for bisection is 6.5 (about 400-500Mb or less)
#Versions (tags) can be found here: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/refs/tags
mkdir src && cd src
git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git --shallow-exclude v6.5
cd ..

#For downloadins Arch specific patch
makepkg -g
unzstd linux-6.5.9.arch2.patch.zst

#EDITING PKGBUILD
#1. pkgbase: 'linux-git'
#2. _scrname: 'linux'
#3. for building from the source need to add function pkgver(), before prepare() function:

pkgver() {
  cd $_srcname
  git describe --long --always | sed -E 's/^v//;s/([^-]*-g)/r\1/;s/-/./g;s/\.rc/rc/'
}

#4. in prepare():
# 'patch -Np1 <../$src' -> 'patch -Np1 <../../$src'
# 'cp ../config .config' -> 'cp ../../config .config'
# 'diff -u ../config .config' -> 'diff -u ../../config .config'

#5. do [5]: 2.2.2 - add before 'make -s kernelrelease > verion' string in prepare() function: 
# make LSMOD=$HOME/.config/modprobed.db localmodconfig

#6. comment 'make htmldocs' string in build () and '"$pkgbase-docs"' in pkgname at the end of PKGBUILD.


#BISECTION SETUP
# do [1]: 3
cd src/linux
git bisect start | tee -a ../../bisect.log
git bisect good v6.5 | tee -a ../../bisect.log
git bisect bad v6.6 | tee -a ../../bisect.log
cd ../..


#PREPARE BUILDING
#when you using 'makepkg -e', it means "use only local sources", function prepare() in PKGBUILD will not executing
#it needs execute manually and _once_only_ (for ccache proper working).
#see: https://bbs.archlinux.org/viewtopic.php?id=233021
#for kernel package it will be:
. /etc/makepkg.conf && . ./PKGBUILD && _srcname=$(readlink -f src/linux) && prepare && cd ../..


#BUILD KERNEL
time makepkg -efs
sudo pacman -U linux-*
sudo reboot
#test if regression is gone


#BISECTION PROCEDURE
#if regression is gone
git bisect good | tee -a /../../bisect.log
#otherwise
git bisect bad | tee -a /../../bisect.log

#then go to #BUILD KERNEL again and rebuild kernel

#in bisection process it will shows how many steps you have to do.
#See [6]: 'Final bisect' for more information

#CLEANING after
#TODO: delete files and cache
