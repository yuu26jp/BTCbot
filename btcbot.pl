#!/usr/bin/perl
use strict;
use Encode;
use LWP::UserAgent;
use JSON;

my $ua      = LWP::UserAgent->new();
my $json    = new JSON();
my $yenmark = encode("utf8", "\x{a5}");

# currency settings
my $coincheck_api = "https://coincheck.com/api/rate/";
my @pair_list = ("btc_jpy", "xrp_jpy", "xem_jpy");

# slack settings
my $slack_channel = '#<SLACK_CHANNEL_NAME>';
my $slack_webhook = 'https://hooks.slack.com/<SLACK_INCOMMING_WEBHOOKS_ENDPOINT>';

# generate message
my $message = "";
foreach my $pair(@pair_list){
	
	# get exchange rate
	my $res  = $ua->get($coincheck_api . $pair);
	my $rate = $json->decode($res->decoded_content)->{rate};
	
	# get coin name
	my $coin_name = (split(/_/, $pair))[0];	# Cut Before "_"
	$coin_name    = uc($coin_name);
	
	# add message
	$message .= "1$coin_name : " . $yenmark . coin_printf($rate) . "\n";
}

# message to slack
my $objdata = {
	"channel" => "$slack_channel",
	"text"    => "$message"
};
my $jsonstr = $json->utf8(0)->encode($objdata);

# post to slack
my $req = HTTP::Request->new("POST", $slack_webhook);
$req->header("Content-Type" => "application/json");
$req->content($jsonstr);
$ua->request($req);

# normal response
print "Status: 204 No Content\n\n";

# formatter
sub coin_printf {
	my $tmp = $_[0];
	
	# Less than 1000 yen -> \xxx.yy
	if ($tmp < 1000){
		$tmp = sprintf("%.2f", $tmp);
	}
	# Over 1000 yen -> \x,xxx
	else {
		$tmp = sprintf("%d", $tmp);
		while ($tmp =~ /\d{4}/){
			$tmp =~ s/(\d+)(\d{3})/$1,$2/
		}
	}
	
	return $tmp;
}
