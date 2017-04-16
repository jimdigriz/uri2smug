CLI tool to upload photos to SmugMug using 'uploadfromuri'.

This instructs SmugMug to download the photo content directly from (for example) AWS S3 rather than having you upload using your local Internet connection.

**N.B.** THIS TOOL IS STILL NOT YET FUNCTIONAL AND UNDER ACTIVE DEVELOPMENT

# Preflight

This project requires Perl.

 * [Perl](https://perl.org) 5.8 or higher
 * [LWP::Authen::OAuth](https://metacpan.org/pod/LWP::Authen::OAuth)

## Debian

    sudo apt-get install -y perl liblwp-authen-oauth-perl

# Usage

Pipe in a line seperated list of URLs that you wish to import into an album like so:

    cat list-of-urls | ./uri2smug.pl album-name

For example you can do:

    aws s3 ls 's3://mybucket.photos/20170416 - Example/' \
    	| sed -n 's/.* \(.*\.JPG\)$/\1/ p' \
    	| xargs -n1 printf "s3://mybucket.photos/20170416 - Example/%s\0" \
    	| xargs -0 -n1 aws --profile digriz s3 presign --expires-in 300 \
    	| ./uri2smug.pl '20170416 - Example'

**N.B.** you have to first create the album (called 'Gallery') via the web frontend under 'Organize'

## First Time

Get yourself a [SmugMug API Key](https://api.smugmug.com/api/v2/doc/tutorial/api-key.html)

 1. set the application name to 'uri2smug'
 1. set the type to 'Toy'
 1. set platform to whatever your OS is
 1. set use to 'Non-Commercial'
 1. set a description of your choosing
 1. agree to both the API terms and conditions *and* the API 2.0 beta terms.
 1. click on 'APPLY'

You will instantly be provided with your keys so you need to now configure `uri2smug`, which you can do by just running it:

    alex@quatermain:/usr/src/uri2smug$ ./uri2smug.pl
    first time configuration
    enter username: your@smugmug-username.com
    enter API key: 1234567890abcdefghijklmnopqrstuv
    enter API secret: 1234567890abcdefghijklmnopqrstuv1234567890abcdefghijklmnopqrstuv
    open the following in your web browser and enter in the pin:
    https://secure.smugmug.com/services/oauth/1.0a/authorize?.....
    enter pin: 123456

You should be now set to go.
