CLI tool to upload photos to SmugMug using 'uploadfromuri'.

This instructs SmugMug to download the photo content directly from (for example) AWS S3 rather than having you upload using your local Internet connection.

# Preflight

This project requires Perl.

 * [Perl](https://perl.org) 5.8 or higher
 * [LWP::Authen::OAuth](https://metacpan.org/pod/LWP::Authen::OAuth)

## Debian

    sudo apt-get install -y perl liblwp-authen-oauth-perl

# Usage

...
