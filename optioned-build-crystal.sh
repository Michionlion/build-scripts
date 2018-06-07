#!/bin/sh

MAIN="/home/saejin/projects/mcm/ransac"

# parse flags
dotest=false
dorun=false
dodep=false
pure=false
doformat=true
cleandeps=false
while [ $# -gt 0 ]; do
    case $1 in
        -t|--test|test)
            dotest=true
        ;;
        -r|--run|run)
            dorun=true
        ;;
        -tr|-rt|all)
            dotest=true
            dorun=true
	;;
        -d|-dep|deps|--dependencies)
            dodep=true
        ;;
        -nf|--no-format)
            doformat=false
        ;;
        -p|--pure)
            pure=true
        ;;
        -c|--clean|--clean-dependencies)
            cleandeps=true
        ;;
        -o|--output)
            if [ $# -gt 1 ]; then
                OUTPUT=$2
                shift
            else
                echo -e "\033[91mNo output file specified with $1!'\033[0m"
            fi
        ;;
        *)
            echo -e "\033[2;91mUnrecognized flag '$1!'\033[0m"
    esac
shift
done

if [ "$pure" = true ]; then
    dodep=false
    dotest=false
    dorun=false
    cleandeps=false
fi

# define a quick spinner for effect
# shellcheck disable=SC1003,SC2143
spinner()
{
    pid=$!
    delay=0.0833

    spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# make cursor invisible
command tput civis

trap 'command tput cnorm' INT TERM HUP EXIT

# use command to bypass any aliases, cd to package
command cd "$MAIN"


if [ "$cleandeps" = true ]; then
	command rm -rf lib/
fi

if [ "$dodep" = true ]; then
    printf "\033[2mGetting dependencies\033[0m\n"
    crystal deps update
fi

tmpfile=".tmpbuild"
trap 'rm -f -- "$tmpfile"' INT TERM HUP EXIT


# run format
printf "\033[2mFormatting\033[0m"
crystal tool format 1> "$tmpfile" & spinner
printf "\033[2m...\033[0m\n"

errors=$(cat "$tmpfile")

if [ "$errors" != "" ]; then
        echo "$errors"
fi


# actually build
printf "\033[2mBuilding\033[0m"
crystal build src/ransac.cr 2> "$tmpfile" & spinner
printf "\033[2m...\033[0m\n"

errors=$(cat "$tmpfile")

if [ "$errors" != "" ]; then
	printf "\033[1;31mBuild errors detected!\033[0m\n"
	echo "$errors"
	command tput cnorm
	rm -f -- "$tmpfile"
	exit 1
fi

# we're done with the tmpfile
rm -f -- "$tmpfile"

printf "\033[1;32mComplete!\033[0m\n"

# reset cursor to normal
command tput cnorm

# execute flags
if [ "$dotest" = true ]; then
	echo
	echo -e "\033[1;90m- - - - - - - - - -"
	echo -e "|\033[1;96m     TESTING     \033[1;90m|"
	echo -e "- - - - - - - - - -\033[0m"
	sleep 1
        crystal spec --verbose
fi
if [ "$dorun" = true ]; then
	echo
	echo -e "\033[1;90m- - - - - - - - - -"
	echo -e "|\033[1;96m     RUNNING     \033[1;90m|"
	echo -e "- - - - - - - - - -\033[0m"
        sleep 1
	./ransac -c test_config.yml
fi

