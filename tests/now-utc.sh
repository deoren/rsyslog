#!/bin/bash
# test many concurrent tcp connections
# addd 2016-02-23 by RGerhards, released under ASL 2.0
# requires faketime
echo \[now-utc\]: test \$NOW-UTC
. ${srcdir:=.}/diag.sh init
generate_conf
add_conf '
$ModLoad ../plugins/imtcp/.libs/imtcp
$InputTCPServerRun '$TCPFLOOD_PORT'

template(name="outfmt" type="string"
	 string="%$now%,%$now-utc%\n")
:msg, contains, "msgnum:" action(type="omfile" template="outfmt"
			         file=`echo $RSYSLOG_OUT_LOG`)
'

. $srcdir/faketime_common.sh

export TZ=TEST-02:00

FAKETIME='2016-01-01 01:00:00' startup
# what we send actually is irrelevant, as we just use system properties.
# but we need to send one message in order to gain output!
tcpflood -m1
shutdown_when_empty
wait_shutdown
echo "2016-01-01,2015-12-31" | cmp - $RSYSLOG_OUT_LOG
if [ ! $? -eq 0 ]; then
  echo "invalid timestamps generated, $RSYSLOG_OUT_LOG is:"
  cat $RSYSLOG_OUT_LOG
  exit 1
fi;


exit_test
