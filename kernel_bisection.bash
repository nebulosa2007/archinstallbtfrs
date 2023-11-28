#Use case is: kernel 6.6.0.arch1 ("bad") has regression and kernel 6.5.9.arch2 ("good") is not. We need make kernel bisection to findout witch commit is cause.

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
ccache -M 15G #at least
#then edit /etc/makekpg.conf [3]: 3.3.1, 3.3.4, 3.5 and [4]: 2.1, 3.1

#Recomended for reducing build kernel time
# git clone https://aur.archlinux.org/modprobed-db.git
# cd modprobed-db && makepkg -fsri && cd .. && rm -rf modpobed-db
#then do [5]: 1-2.1.1, 2.1.3.1


#GET SOURCES
mkdir -p Bisect && cd Bisect #For convinience 

#Versions (tags) can be found here: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/refs/tags
#Unfortunatly, vanilla kernel sources has only tags 6.6, 6.5, etc not an 6.6.1, 6.5.8 ... so it need make more steps (build kernels) as it should be.
#Also kernel sources has tags *-rc1, *-rc2 .., where (definitly) regression occurs, but for finding it out you should build kernel and again spend this time for complinig.
#If you have precompiled versions of -rc (in cache or something else) - downgrage to those versions at first and accurate neeeded tags

#Get PKGBUILD kernel verion 6.6 (first "bad" version) [2]: 3.1.1
#Other versions (tags) can be found here: https://aur.archlinux.org/cgit/aur.git/log/?h=linux-mainline
git clone https://aur.archlinux.org/linux-mainline.git linux-mainline && cd linux-mainline

#To found out which commit is needed
# git log --pretty=oneline
git checkout 1c5e87b

#Get kernel sources
#If make just git clone you have download about 5Gb sources, so we can download only desired verision of kernel.
#Lowest version for bisection is v6.4 (previous tag before v6.5) (about 400-500Mb or less)
git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git --shallow-exclude v6.4 src/linux-mainline

#EDITING PKGBUILD
#1. comment string: 'pkgbase=linux-mainline', uncomment next string and edit to: 'pkgbase=linux-bicest'
#2. comment also dependencies for 'htmldocs', strings: 'graphviz' 'imagemagick' 'python-sphinx' 'texlive-latexextra'
#3. for building from the source need to add function pkgver(), before prepare() function:

pkgver() {
  cd $_srcname
  git describe --long --always | sed -E 's/^v//;s/([^-]*-g)/r\1/;s/-/./g;s/\.rc/rc/'
}

#4. in prepare():
# 'patch -Np1 <../$src' -> 'patch -Np1 <../../$src'
# 'cp ../config .config' -> 'cp ../../config .config'
# 'diff -u ../config .config || :' -> 'diff -u ../../config .config || :'

#5. do [5]: 2.2.2 - add after 'diff -u ../../config .config || :' string in prepare() function: 
# 'make LSMOD=$HOME/.config/modprobed.db localmodconfig'

#6. comment '_make htmldocs' string in build () and '"$pkgbase-docs"' in pkgname at the end of PKGBUILD.

#Other edits could be when you will start compiling and get errors, please search answer with text of error on the Archlinux Forum: https://bbs.archlinux.org

#BISECTION SETUP
# do [1]: 3
cd src/linux-mainline
git bisect start
git bisect good v6.5
git bisect bad v6.6
#it will shows how many steps you have to do.
cd ../..


#PREPARE BUILDING
#when you using 'makepkg -e', it means "use only local sources", function prepare() in PKGBUILD will not executing
#it needs execute manually and ONLY ONCE (for ccache proper working).
#see: https://bbs.archlinux.org/viewtopic.php?id=233021
. /etc/makepkg.conf && . ./PKGBUILD && _srcname=$(readlink -f src/linux-mainline) && prepare && cd ../..


#BUILD KERNEL
time makepkg -efs
sudo pacman -U linux-*
# sudo grub-mkconfig -o /boot/grub/grub.cfg - if you use grub
sudo reboot
#choose linux-git to boot and double check that you booted in desired new kernel: uname -a

#BISECTION PROCEDURE
#test if regression is actual 
cd ~/Bisect/linux/src/linux-mainline
#if regression is gone
git bisect good
#otherwise
git bisect bad
#git shows you how many steps are left
#then go to item '#BUILD KERNEL' again and rebuild kernel

#See [6]: 'Final bisect' for more information

#LOGS
#When you will see the message '.... is first bad commit' it means that bisecting procedure is finished.
#To share results of bisecting do:
git bisect log ../../git_bisect.log
#And upload git_bisect.log to desired bugtracker.

#CLEANING AFTER FIXING REGRESSION
sudo pacman -Rsn linux-bisect-* linux-bisect-headers-*
# sudo grub-mkconfig -o /boot/grub/grub.cfg - if you use grub
cd ~ && rm -fr ~/Bicest/linux-mainline
ccache -C
