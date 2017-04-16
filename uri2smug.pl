#!/usr/bin/env perl

use strict;
use warnings;

use LWP::Authen::OAuth;
use URI::Escape;
use Storable qw/nstore retrieve/;
use JSON qw/decode_json encode_json/;

use Data::Dumper;

use constant VERSION => '0.1';

use constant CONFIG => $ENV{HOME} . '/.uri2smug';

use constant {
	BASE			=> 'https://api.smugmug.com/api/v2',
	REQUEST_TOKEN_PATH	=> 'https://secure.smugmug.com/services/oauth/1.0a/getRequestToken',
	AUTHORIZE_PATH		=> 'https://secure.smugmug.com/services/oauth/1.0a/authorize',
	ACCESS_TOKEN_PATH	=> 'https://secure.smugmug.com/services/oauth/1.0a/getAccessToken',
};

sub config() {
	my %config;

	print "first time configuration\n";
	print 'enter username: ';
	$config{user} = <STDIN>;
	chomp $config{user};

	print 'enter API key: ';
	$config{key} = <STDIN>;
	chomp $config{key};

	print 'enter API secret: ';
	$config{secret} = <STDIN>;
	chomp $config{secret};

	print "\n";

	my $orig = umask;
	umask 077;
	nstore \%config, CONFIG;
	umask $orig;
}

sub auth($$) {
	my ($config, $ua) = @_;

	my $r = $ua->post(REQUEST_TOKEN_PATH, [
		oauth_callback	=> 'oob',
	]);
	die $r->as_string if $r->is_error;

	$ua->oauth_update_from_response($r);

	print "open the following in your web browser and enter in the pin:\n";
	print AUTHORIZE_PATH . '?username=' . uri_escape($config->{user}) . '&showSignUpButton=false&access=Full&permissions=Modify&oauth_token=' . uri_escape($ua->oauth_token) . "\n\n";

	print 'enter pin: ';
	my $pin = <STDIN>;
	chomp $pin;

	$r = $ua->post(ACCESS_TOKEN_PATH, [
		oauth_verifier		=> $pin,
	]);
	die $r->as_string if $r->is_error;

	$ua->oauth_update_from_response($r);

	$config->{oauth_token} = $ua->oauth_token();
	$config->{oauth_token_secret} = $ua->oauth_token_secret();

	my $orig = umask;
	umask 077;
	nstore $config, CONFIG;
	umask $orig;
}

config() unless -f CONFIG;

my $config = retrieve(CONFIG);
die "broken config, delete '" . CONFIG . "' and rerun"
	unless (defined($config->{key}) && defined($config->{secret}));

my $ua = LWP::Authen::OAuth->new(
	oauth_consumer_key	=> $config->{key},
	oauth_consumer_secret	=> $config->{secret},
);
$ua->timeout(10);
$ua->env_proxy;
$ua->agent('uri2smug/' . VERSION . ' (+https://gitlab.com/jimdigriz/uri2smug; ' . $ua->_agent . ')');
$ua->from($config->{user});

unless (defined($config->{oauth_token}) && defined($config->{oauth_token_secret})) {
	die "please re-run standalone to refetch auth token"
		if (scalar @ARGV);

	auth($config, $ua);
}

exit 0 unless (scalar @ARGV);

$ua->oauth_token($config->{oauth_token});
$ua->oauth_token_secret($config->{oauth_token_secret});

# oauth_update_from_response() calls content so we cannot use compression during compression
$ua->default_header(
	'Accept'		=> 'application/json',
	'Accept-Encoding'	=> scalar HTTP::Message::decodable(),
);

my $r = $ua->get(BASE . '!authuser');
die $r->as_string . "\n" . $r->decoded_content if $r->is_error;

my $j = decode_json $r->decoded_content;
my $nickname = $j->{Response}->{User}->{NickName};

print "nickname: $nickname\n";

$r = $ua->get(BASE . '/user/digriz!albums');
die $r->as_string . "\n" . $r->decoded_content if $r->is_error;

$j = decode_json $r->decoded_content;
my $albums_all = $j->{Response}->{Album};

my @albums = grep { $_->{Name} eq $ARGV[0] } @{$j->{Response}->{Album}};

die "argument did not match a single gallery entry\n"
	unless (scalar @albums == 1);

my $album = (split '/', $albums[0]->{Uri})[-1];

print "album id: $album\n\n";

my $fail = 0;
while (<STDIN>) {
	chomp;

	print "importing: $_...";

	my $p = encode_json {
		'AllowInsecure'	=> JSON::true,
		'Uri'		=> $_,
	};
	$r = $ua->post(BASE . '/api/v2/album/' . $album . '!uploadfromuri', 'Content-Type' => 'application/json', Content => $p);

	if ($r->is_error) {
		print "FAIL\n";
	} else {
		print "done\n";
	}
}

print "\n";
print "imported " . ($. - $fail) . " of $.\n";

exit 0;
