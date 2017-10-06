#!/bin/bash

BASEURL='https://yggtorrent.com/torrents/filmvideo/'
TARGETSUFFIX=.psv
TMPFILE=yggTmp.html
PERPAGE=100

fetchIndexPage(){
 echo "$URL"
 wget -q "$URL" -O $TMPFILE
}

psv2html(){
  cat $TARGETFILE | ./psv2html.sh >$HTMLFILE

 echo '<html><head> <meta charset="UTF-8"> <body>' >$HTMLFILE
 echo '<ol>' >>$HTMLFILE
 while read line; do
  echo "$line"|awk -F'|' '{print "<li><a target=\"_blank\" href=\"" $2 "\">" $1 "</a></li>"}' >>$HTMLFILE
 done < $TARGETFILE
 echo '</ol>' >>$HTMLFILE
 echo '</body></html>' >>$HTMLFILE

}

indexOne(){
 local OFFSET=0
 TARGETFILE=$HEADNAME$TARGETSUFFIX
 rm -f $TARGETFILE
 local TPLURL="${HEADURL}?per_page=${PERPAGE}&page=_PAGE_"
 URL=${TPLURL/_PAGE_/$OFFSET}
 echo "ITERATE $URL"
 wget -q "$URL" -O $TMPFILE
 local NBTORRENTS=$(grep panel-title $TMPFILE |awk -F'[<>]' '{print $9}'|awk -F' ' '{print $1}')
 local NBPAGES=$(($NBTORRENTS/$PERPAGE))
 echo "Torrents: $NBTORRENTS   Pages: $NBPAGES"

while [ $OFFSET -lt $NBTORRENTS ]; do
  echo $OFFSET
  URL=${TPLURL/_PAGE_/$OFFSET}
  echo "$OFFSET/$NBTORRENTS $URL"
  sleep 0.5
  wget -q "$URL" -O $TMPFILE
  DATA=$(grep torrent-name $TMPFILE |sed 's/<td>//'|awk -F'["<>]' '{print $7 "|" $5}')
  if [ -z "$DATA" ]; then
    echo END
    return
  fi
  echo "$DATA" >> $TARGETFILE
  OFFSET=$(($OFFSET+$PERPAGE))
done
}

indexAllHeadings(){
 local HEADINGS=$(grep "$BASEURL" $TMPFILE | awk -F'["/]' '{print $7}') 
 local line
 echo "$HEADINGS" | while read line; do 
  echo FOUND Heading $line
  HEADURL=$BASEURL$line
  HEADNAME=$(echo $line| cut -d - -f 2-)
  indexOne
  HTMLFILE=${HEADNAME}.html
  rm -f $HTMLFILE
  echo "To HTML $HTMLFILE"
#  cat $TARGETFILE | ./psv2html.sh >$HTMLFILE
 psv2html
 done
}

Main(){
 URL=$BASEURL
 fetchIndexPage
 indexAllHeadings
}

Main

