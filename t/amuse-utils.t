use strict;
use warnings;
use utf8;
use Test::More tests => 16;
use File::Spec::Functions qw/catfile/;

use AmuseWikiFarm::Utils::Amuse qw/muse_get_full_path
                                   muse_parse_file_path
                                  /;

is_deeply(muse_get_full_path("cacca"), [ "c", "ca", "cacca" ]);
is_deeply(muse_get_full_path("th-the-best"), [ "t", "tt", "th-the-best" ]);
is(muse_get_full_path("th the-best"),
   undef,
   "Testing bad paths");
is(muse_get_full_path("../../etc/passwd"),
   undef,
   "Testing bad paths");

is(muse_get_full_path("/etc/passwd"),
   undef,
   "Testing bad paths");
is(muse_get_full_path('%a0/passwd'),
   undef,
   "Testing bad paths");

is_deeply(muse_get_full_path("zo-d-axa-us"), ["z", "zd", "zo-d-axa-us"],
	  "Testing new algo for path");


my $file = catfile(qw/t a at another-test.muse/);
ok (-f $file);
my $info = muse_parse_file_path($file);
ok ($info);
is $info->{f_name}, 'another-test';
is $info->{f_suffix}, '.muse';

$file = catfile(qw/t files shot.jpg/);

ok (-f $file);
$info = muse_parse_file_path($file);
ok !$info, "Nothing returned";
$info = muse_parse_file_path($file, 1);
is $info->{f_name}, 'shot';
is $info->{f_suffix}, '.jpg';
ok $info->{f_full_path_name}, $info->{f_full_path_name};
