#! /bin/bash

# This script generates streams for the UDP source

echo "Sending H264 video and AAC audio stream ...\n"

gst-launch-1.0 -v audiotestsrc ! audio/x-raw,rate=44100 ! faac ! rtpmp4gpay  pt=127 ! udpsink host=127.0.0.1 port=5000 \
    videotestsrc ! video/x-raw,format=I420 ! x264enc key-int-max=10 tune=zerolatency ! rtph264pay pt=96 ! udpsink host=127.0.0.1 port=5000

echo "\nDone sending stream ..."