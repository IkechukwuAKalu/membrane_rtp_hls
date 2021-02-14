# Membrane RTP to HLS

This project was initially cloned from [the membrane demo repository](https://github.com/membraneframework/membrane_demo/tree/master/rtp_to_hls). It includes some custom implementations which are being added as I learn to use the framework better. The project dependencies have been updated.

Currently, the major addition is the use of [Google Cloud Storage (GCS)](https://cloud.google.com/storage) buckets for storing manifests and stream segments. For my setup, the GCS bucket is interfaced with a HTTP load balancer which has Cloud CDN enabled.

The file system storage option is still available.

## Generating test Streams
To generate test streams, you can run the `streamer.sh` shell script. It uses [GStreamer](https://gstreamer.freedesktop.org) to achieve this. It sends streams on the localhost (127.0.0.1) and to a port (`5000` by default). You can either use the defalut port or specify your own port. To specify your own port,
run `sh streamer.sh [PORT]`. Example: `sh streamer.sh 8000`

More documentation coming up for setup, etc

===