# Membrane RTP to HLS

This project was initially cloned from [the membrane demo repository](https://github.com/membraneframework/membrane_demo/tree/master/rtp_to_hls). It includes some custom implementations which are being added as I learn to use the framework better. The project dependencies have been updated.

Currently, the major addition is the use of [Google Cloud Storage (GCS)](https://cloud.google.com/storage) buckets for storing manifests and stream segments. For my setup, the GCS bucket is interfaced with a HTTP load balancer which has Cloud CDN enabled.

The file system storage option is still available.


More documentation coming up for setup, etc

===