#!/bin/bash

# support to
# filename pattern must be ...
#   - [path-to-dir/]'*yyyy*mm*dd*hh*'
#   - [path-to-dir/]'*yyyy*mm*dd*'

# default pattern will help you
declare -r default_basename_pattern="daily_rotated_file-yyyy_mm_dd-hh.log"

# load file list(log_file_list) from file
# 'declare -ar log_file_list=(...)'
_flist="${0%.sh}.cfg"
[ -f "$_flist" -a -r "$_flist" ] && source "$_flist"

# show usage
[ "$1" = "-h" ] && echo "Usage : '$0' [-h] [-p FilenamePattern] [yyyy] [mm] [yyyy] [mm]" && exit 0

# pattern of path-to-files
if [ "$1" = "-p" ]; then { p2f="$2"; shift 2; }
elif [ -n "$log_file_list" ];then
  select p2f in "${log_file_list[@]}";do [ -n "$p2f" ] && break; done
else
  p2f="$(basename "${default_basename_pattern?"Default filename pattern not defined"}")"
fi
declare -r _dir="$(dirname "$p2f")"
declare -r _basename_pattern="$(basename "$p2f")"
[[ "$_basename_pattern" != *yyyy*mm*dd* ]] && echo "filename must be '*yyyy*mm*dd*" && exit 1

# fix date range
for arg; do [ "$(expr "$arg" : '\([0-9][0-9]*\)')" != "$arg" ] && echo "'$arg' is not digit" && exit 1; done
declare -i y1=${1:-$(date +%Y)}
[ 2000 -ge $y1 ] && y1=2001
declare -i m1=${2:-$([ -z $1 ] && echo $(date +%m) || echo 1)}
[ 12 -lt $m1 ] && m1=12
declare -i y2=${3:-$y1}
declare -i m2=${4:-12}
if [ -z $1 ]; then m2=$m1
elif [ -z $2 ]; then m2=12
elif [ -z $3 ];then m2=$m1
fi
[ 12 -lt $m2 ] && m2=12

# basename's pattern 
_patternf=${_basename_pattern}
_patternf="${_patternf/yyyy/${yyyyf:="{yyyy}"}}"
_patternf="${_patternf/mm/${mmf:="{mm}"}}"
_patternf="${_patternf/dd/${ddf:="{dd}"}}"
_patternf="${_patternf/hh/${hhf:="{hh}"}}"

# run or quit
printf "\nFind files by this pattern?\n"
_msg_proc=$(printf "\n  '%s/%s'\n" $_dir $_patternf)
_msg_proc+=$(printf "\n  [yyyy] [mm] : %04d-%02d" $y1 $m1)
_msg_proc+=$([ $y1 -eq $y2 -a $m1 -eq $m2 ] && echo || printf " to %04d-%02d\n" $y2 $m2)
echo "$_msg_proc"
printf "\n[Y/N] > "
read -r yn
[ "$yn" = "Y" -o "$yn" = "y" ] && echo || exit 0 # for bash 3.2.25

_patternf="${_patternf/$yyyyf/%04d}"
_patternf="${_patternf/$mmf/%02d}"
_patternf="${_patternf/$ddf/%02d}"
_patternf="${_patternf/$hhf/%02d}"

function is_leapyear () {
  [ -z "$1" ] && exit 1
  if [[ $(($1 % 4)) == 0 && $(($1 % 100)) != 0 ]] || [ $(($1 % 400)) == 0 ]; then return 0; else return 1; fi
}

nof0=0; nof1=0; declare -a nof_stats;
for yyyy in $(seq $y1 $y2); do
  for mm in $( seq $( test $y1 -eq $yyyy && echo $m1 || echo 1) $( test $y2 -eq $yyyy && echo $m2 || echo 12) ); do
    declare -ai nof_iam=()
    case $mm in
      1|3|5|7|8|10|12) _dd=( $(seq 31) ) ;;
      2) _dd=( $(seq $(is_leapyear $yyyy && echo 29 || echo 28) ) ) ;;
      4|6|9|11) _dd=( $(seq 30) ) ;;
    esac
    for dd in ${_dd[@]}; do
      printf "\x23 -- %04d-%02d-%02d ----------\n" $yyyy $mm $dd
      nof_iam[$dd]=0
      # log file created every hour
      if [[ "$_basename_pattern" == *hh* ]]; then
        for hh in $(seq 0 23); do
          file_basename=$(printf "$_patternf" $yyyy $mm $dd $hh)
          eval ls -1d "$_dir/$file_basename" 2>&1 1>/dev/null && { let ++nof_iam[$dd]; let ++nof0; } || let ++nof1
        done
      # log file created every hour
      else
        file_basename=$(printf "$_patternf" $yyyy $mm $dd) 
        eval ls -1d "$_dir/$file_basename" 2>&1 1>/dev/null && { let ++nof_iam[$dd]; let ++nof0; } || let ++nof1
      fi
    done
    #declare -p nof_iam
    nof_stats+=("$(printf "[%04d-%02d]" $yyyy $mm) ${nof_iam[*]}")
  done
done

# info
echo
echo "# ["$(date +'%F %T.%N %z')"] CWD : '$(pwd)'"
echo "$_msg_proc"

# show number of lacked files
echo
echo $nof1 / $(($nof0+$nof1)) files lacked
echo
_header="[YYYY-MM]"
for i in $(seq 31);do _header+=$(printf " %2d" $i); done
echo "$_header"
for i in $(seq ${#_header});do echo -n '-'; done

printf "\n"
for _tmp1 in "${nof_stats[@]}"; do
  _tmp_a=( $(eval echo $_tmp1) )
  for _tmp2 in ${_tmp_a[@]}; do
    test 2 -lt ${#_tmp2} && echo -n "$_tmp2" || printf "%3d" $_tmp2
  done
  echo
done

# show stats
echo
echo "# -- stats" 
echo "[YYYY-MM]123456789X123456789X123456789X1"
for s in "${nof_stats[@]}"; do
  [[ "$_basename_pattern" == *hh* ]] && s="${s// 24/o}" || s="${s// 1/o}"
  s="${s// 0/-}"
  s="${s// [12][0-9]/x}"
  echo "${s// ?/x}"
done




