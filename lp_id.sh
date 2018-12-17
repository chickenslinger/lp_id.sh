#!/bin/bash
##
##To Do list
##need to create function to catch sig
##Need to account for multiple optional input to narrow or expand search scope

###################################################################
#Variables
###################################################################

#setting lp hosts array... 
##Need to use curl for this feature with cmdb api... figure it out

loginPortalED1=('#####')


loginPortalED5=('#####')


#Initailize lp id array
loginPortalID=()


#sets lp search path + search files
lpPath='/var/www/app0/data/login_portal/'
file='login-portal.log'
globFile="login-portal.log-*"

#cache file for ID var
cacheFileID='/tmp/idCache'

#cahce file or output var
cacheFileOut='/tmp/outcache'

#final output file
finalOutput=''$HOME'/lp.txt'

#datacenter flag
dcFlag='0'

###################################################################
#Functions go here
###################################################################

#help used for -h or --help
help_flag()  { 
echo "Help:  $0 [-s <site id>] [-d <datacenter id (ed1|ed5)>] [-g <grep string>]  [-h help]" 1>&2
exit 0
}

#usage used for incorrect usage of flags
usage() { 
echo "Usage: $0 [-s <site id>] [-d <datacenter id (ed1|ed5)>] [-g <grep string>]" 1>&2
exit 1 
}

#loop through LP to search for loginPortal ID'S
searchLoop()
{
printf "Serching....\n\n"
if [[ "$d" == [Ee][Dd]1 ]]; then
    #set dcFlag
    dcFlag='1'
    #echo ${dcFlag}
    #find id's and build cache
    for i in "${loginPortalED1[@]}"
        do
            echo "${i}"
            ssh $i 'grep -i '$s' '$lpPath$file' |grep -i '$g' | cut -d" " -f7 | sed -e 's/^.//' -e 's/.$//'' | sort -u  > $cacheFileID
        done
fi
if [[ "$d" == [Ee][Dd]5 ]];then
    #set dcFlag
    dcFlag='5'
    #echo ${dcFlag}
    #find ids and build cache
    for i in "${loginPortalED5[@]}"
        do
             echo ${i}
             ssh $i 'grep -i '$s' '$lpPath$file' |grep -i '$g' | cut -d" " -f7 | sed -e 's/^.//' -e 's/.$//'' | sort -u  > $cacheFileID
        done 
fi

  idArray
  
}

#build id array
idArray()
{
printf "\nBuiding ID array...\n"
if [[ -s $cacheFileID ]] ; then
    readarray loginPortalID < "/tmp/idCache"    
    echo "${loginPortalID[@]}"
else
        echo "No Data Found"
        exit 0
fi

}

#loop through lp's searching for lp id outputing info to files
##
##
##
##This needs changed to this
##for i in "${loginPortalED*[@]}";do ssh $i "$(typeset -f); f" - where f is the function that contains the for loop grep.....
##
##
##

logLoop()
{
  printf "\nBuilding output, Please be patient...\n"
  if [ ${dcFlag} -eq 1 ]; then
    for i in "${loginPortalED1[@]}"
      do 
        echo $i
        ssh $i 'for j in '${loginPortalID[@]}';do grep ${j} '${lpPath}${file}';done' >> "$cacheFileOut"
      done  
  else 
    for i in "${loginPortalED5[@]}"
      do
        echo $i
        ssh $i 'for j in '${loginPortalID[@]}';do grep ${j} '${lpPath}${file}';done' >> "$cacheFileOut"
      done
  fi
  
cleanup
gedit $finalOutput
}

idGrep()
{
    for j in "${loginPortalID[@]}"
      do 
        grep "$j" "$lpPath$file" 
      done
}

cleanup()
{
    cat $cacheFileOut | sort -k 7,7 -k 3,3 > "$finalOutput"
 #clean up cache
    rm $cacheFileID
    rm $cacheFileOut     
 #set flag to 0
    dcFlag='0'
}

gedit()
{
    /usr/bin/gedit $@ & disown
}


###################################################################
#Input flags
###################################################################

#Gather input with flags, set vars,  and eval
while getopts ":s:d:g:h" o; do
    case "${o}" in
        s)
            s=${OPTARG}
            ;;
        d)
            d=${OPTARG}
            ;;
        g)
            g=${OPTARG}
            ;;
	    h)
	        help_flag
	        ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${s}" ] || [ -z "${d}" ] || [ -z "${g}" ]; then
    usage
fi

###################################################################
#Call Functions
###################################################################

searchLoop
logLoop

exit 0
