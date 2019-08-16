NR==FNR {       # while processing the first file (mapfile)
  sta[$1]=$2;      # remember the second field by the first
  next            # do nothing else
}
FNR == 1 {        # at the first line of the second file (datafile):
  FS  = ","       # start splitting by | instead of whitespace
  OFS = FS        # delimit output the same way as the input
  $0  = $0        # force resplitting of this first line
}

{$23=($23 in sta?sta[$23] : $23);}
{$22=($22 in sta?sta[$22] : $22);}
$26 {cmd="date -jf '%d/%m/%Y %r' '+%Y-%m-%d %T' \'"$26"\'"; cmd | getline $26; close(cmd)}
{$24=substr($24,1,5) }
1

