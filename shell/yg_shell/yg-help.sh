#!/bin/bash

function yg_usage {
    echo "Hello user, welcome to use yg-shell !!!"
    echo "Usage: yg-shell [OPTION] [ARGUMENTS]"
    echo 
    echo "OPTION:"
    echo "-i <directory>        Install, install a ygtool"
    echo "-u <directory>        Uninstall, uninstall a ygtool"
    echo "-l                    List, list all ygtools installed"
    echo "-h                    Help, show the usage of yg-shell"
    echo
    echo "EXAMPLE:"
    echo "yg-shell -l"
    echo "yg-shell -i yg_tools/"
}

function yg_help {
    yg_usage
}

yg_help
