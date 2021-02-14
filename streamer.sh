#! /bin/bash

# This script generates streams for the UDP source

echo "Sending H264 video and AAC audio stream ...\n"

PORT=$1

if [ $PORT == $() ]
then
	PORT=5000
fi

echo "Using port $PORT ...\n"

gst-launch-1.0 -v audiotestsrc ! audio/x-raw,rate=44100 ! faac ! rtpmp4gpay  pt=127 ! udpsink host=127.0.0.1 port=$PORT \
    videotestsrc ! video/x-raw,format=I420 ! x264enc key-int-max=10 tune=zerolatency ! rtph264pay pt=96 ! udpsink host=127.0.0.1 port=$PORT

echo "\nDone sending stream ..."