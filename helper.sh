#!/usr/bin/env bash

# Root check

if [ "$(id -u)" -eq 0 ];
then
    echo "Please do not run this script as root or using sudo" >&2
    exit 1
fi

# Functions

dependencies_gki() {
    echo ""
    echo "Checking dependencies"
    echo ""
    if [ ! -f /etc/os-release ]; then
        echo "Unsupported OS"
        exit 1
        #. /etc/os-release
        #OS=$NAME      
    fi

    if [ -x "$(command -v apt-get)" ]; then
        if ! apt -qq list adb fastboot >/dev/null 2>&1; then
        sudo apt-get install adb fastboot
        fi
    elif [ -x "$(command -v dnf)" ]; then
        if ! dnf list installed "android-tools" >/dev/null 2>&1; then
        sudo dnf install android-tools
        fi
    elif [ -x "$(command -v pacman)" ]; then
        if ! pacman -Q android-tools >/dev/null 2>&1; then
            sudo pacman -S --needed android-tools
        fi
    else
        echo " Package manager not found. You must manually install: adb fastboot ">&2;
        exit 1
    fi
}

kernelmenu() {
    echo -ne "
Select kernel running mode : 
1) Use KSU-Next in GKI mode (replace your current kernel) [recommended]
2) Use KSU-Next in LKM mode (patch your current boot.img)
3) What's the difference?
0) Abort
Choose an option:  "

        read -r ans
        case $ans in

        1)
            dependencies_gki

            echo -ne "
Select kernel provider : 
1) Discussion Verse (DV) kernel By @picasso170606
2) Mahiru Kernel By @Shirayuki428
0) Exit
Choose an option:  "
                
                read -r ans
                case $ans in

                1)
                    cache_dir="$(mktemp -d)"
                    mkdir -p "$cache_dir"/workdir
                
                    echo ""
                    echo "Downloading the lastest Discussion Verse kernel"
                    echo ""
                    curl -L https://sourceforge.net/projects/dv-kernel/files/latest/download > "$cache_dir"/kernel.zip
                    
                    echo "Extracting"
                    echo ""
                    unzip "$cache_dir"/kernel.zip -d "$cache_dir"/kernel
                    mv "$cache_dir"/kernel/Image "$cache_dir"/workdir
                    rm -rd "$cache_dir"/kernel

                    echo "Waiting for adb conenction"
                    echo ""
                    while true; do adb get-state > /dev/null 2>&1 && break; done
                    
                    echo "Reboot to fastboot"
                    echo ""
                    adb reboot bootloader

                    echo "Waiting for fastboot conenction"
                    echo ""
                    until fastboot getvar version >/dev/null 2>&1; do sleep 1; done
                    
                    echo "flashing kernel"
                    echo ""
                    fastboot flash boot "$cache_dir"/workdir/Image

                    echo "kernel has been flashed"
                    ;;
                
                2)
                    echo "This option has not been implemented yet">&2;
                    kernelmenu
                    ;;
                
                0)
                    kernelmenu
                    ;;
                esac
            ;;

        2)
            echo "This option has not been implemented yet">&2;
            kernelmenu
            ;;

        3)  
            xdg-open https://kernelsu.org/guide/installation.html#introduction
            kernelmenu
            ;;
        
        0)      
            echo "Aborting..."
            exit 0
            ;;
        
        *)
            echo "Wrong option."
            kernelmenu
            ;; 

        esac

}

# Main Program

kernelmenu
