NR==FNR {       # while processing the first file (mapfile)
  bar[$1]=$2;      # remember the second field by the first
  next            # do nothing else
}
FNR == 1 {        # at the first line of the second file (datafile):
  FS  = ","       # start splitting by | instead of whitespace
  OFS = FS        # delimit output the same way as the input
  $0  = $0        # force resplitting of this first line
}

{print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10, $7 in bar?bar[$7]: "0",$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26}

	