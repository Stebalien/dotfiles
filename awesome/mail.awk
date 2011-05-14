#!/bin/awk -f
BEGIN {
    decoder = "base64 -d"
}

END {
    for (x = 1; x <=ARGIND; x++) {
        if(x in from)
            print from[x] ":"
        else
            print " Annonymous:"
        if(x in subject)
            print "  " subject[x]
    }
}

FNR==1 { i=0 }

function decode() {
    $1=""
    if ($2 ~ /^=\?.*\?B\?.*\?=/) {
        split($2, enc, "?")
        print enc[4] |& decoder
        close(decoder, "to")
        decoder |& getline $2
        close(decoder)
    }
}
/^From: / {
    i++
    decode()
    from[ARGIND] = $0
    if (i>=2) nextfile
    else next
}
/^Subject: / {
    i++
    decode()
    subject[ARGIND] = $0
    if (i>=2) nextfile
    else next
}
