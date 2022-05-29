#!/bin/bash

find=/usr/bin/find
tar=/bin/tar

command_list=(cut date echo $find grep hostname mount sh $tar umount uname which)

for command in ${command_list[@]}; do
    if [ ! -x "`which $command 2>&1`" ]; then
        echo -e "\nERROR: $command not found! "
        base=`basename $command`
        if [ "`which $base 2>&1 | grep "no \`basename $command\` in"`" != "" ]; then
            echo -e "ERROR: $base is not in your \$PATH."
        fi
        exit -1
    fi
done

tar_output="--file"
tar_options=" --preserve-permissions --create --absolute-names --totals --ignore-failed-read"
stagelocation=/mnt/stage

stageprefix="stage3-amd64-musl-latest"
default_exclude_pattern=""
default_exclude_list="
/swap
/dev
/lost+found
/mnt
/proc
/sys
/tmp
/usr/src
/var/log/
/var/tmp
/var/cache/edb
"

default_include_list="
/dev/null
/dev/console
/home
/var/db/repos
/usr/src
/var/log/emerge.log"

default_include_folders="
/var/db"

find_command="$find /*"

for pattern in $default_exclude_pattern; do
    find_command="$find_command -not -name $pattern"
done

function find_files()
{
    for folder in $default_exclude_list; do
        find_command="$find_command -path $folder -prune -o"
    done

    find_command="$find_command -print"

    for i in $default_include_list; do
        find_command="echo $i; $find_command"
    done

    for i in $default_include_folders; do
        if [ -d $i ]; then
            find_command="$find $i; $find_command"
        else
            find_command="echo $i; $find_command"
        fi
    done
}

function verify()
{
    for i in $i; do
        if [ ! -e "`echo "$i" | cut -d'=' -f2 | cut -d'*' -f1`" -a "$i" != "/lost+found" -a "$i" != "$stagelocation" ]; then
            echo "ERROR: `echo "$i" | cut -d'=' -f2` not found! Check your "$2
            exit 0
        fi
    done
}

echo ""

verify "$default_exclude_list" "\$default_exclude_list"
verify "$default_include_list" "\$default_include_lis"
verify "$default_include_folders" "\$default_include_folders"

stagename=$stagelocation/$stageprefix.tar
default_exclude_list="$default_exclude_list"

find_files
find_command="($find_command)"

if [ "$tar_output" == "--file" ]; then
    tar_command="$find_command | $tar $tar_options -J --file $stagename.xz --no-recursion -T -"
fi

if [ ! -d "$stagelocation" ]; then
    echo "Creating directory $stagelocation"
    mkdir -p $stagelocation
fi

echo -e "\n Creating...\n"
sh -c "$tar_command"

echo -e "\n Finished with success."
