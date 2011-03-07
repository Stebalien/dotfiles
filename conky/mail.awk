#!/bin/awk -f
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

FNR ~ 0 { i=0 }
i ~ 3 { nextfile }

function decode(text) {
    if (text ~ /^=\?.*\?B\?.*\?=/) {
        split(text, enc, "?")
        print enc[4] |& "base64 -d"
        close("base64 -d", "to")
        "base64 -d" |& getline text
        close("base64 -d")
    }
    return text
}
/^From:/ {
    i++
    $2=decode($2)
    $1=""
    from[ARGIND] = $0
    next
}
/^Subject:/ {
    i++
    $2=decode($2)
    $1=""
    subject[ARGIND] = $0
    next
}
