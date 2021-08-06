#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 26;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catdir catfile/;
use AmuseWikiFarm::Archive::BookBuilder;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site run_all_jobs/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;
use Path::Tiny;
use File::Copy::Recursive qw/dircopy/;
use File::Path qw/remove_tree make_path/;
use AmuseWikiFarm::Utils::Amuse qw/from_json/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site_1 = $schema->resultset('Site')->find('0federation0') || create_site($schema, '0federation0');
my $site_2 = $schema->resultset('Site')->find('0federation0') || create_site($schema, '0federation1');

if (0) {
    my $src = catdir(qw/t test-repos 0opds0/);
    my $dest = catdir(repo => $site_1->id);
    remove_tree($dest);
    die "dest exists" if -d $dest;
    dircopy($src, $dest);
    dircopy(catdir(qw/t test-repos 0blog0 f/),
            catdir($dest, 'f'));
    $site_1->update_db_from_tree(sub { diag join(' ', @_) });

    is $site_1->titles->count,
      $site_1->titles->search_related('mirror_info')->count, "Mirror info generated for titles";

    is $site_1->attachments->count,
      $site_1->attachments->search_related('mirror_info')->count, "Mirror info generated for attachments";
}

# diag Dumper($site_1->titles->mirror_manifest);
is scalar(@{$site_1->titles->mirror_manifest}), $site_1->titles->count + $site_1->attachments->count;

my $just_one = $site_1->titles->search({ 'me.uri' => 'first-test' })->mirror_manifest;
diag Dumper($just_one);

is_deeply([ sort map { $_->{uri} } @$just_one ],
          ['f-t-cata.jpg', 'f-t-testimage.png', 'first-test' ]);

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site_1->canonical);

foreach my $m (qw|
                     /manifest.json
                     /category/author/cao/manifest.json
                     /category/author/cao/en/manifest.json
                     /category/topic/ecole/manifest.json
                     /category/topic/ecole/en/manifest.json
                     /library/first-test/manifest.json
                 |) {
    $mech->get_ok($m);
    my $data = from_json($mech->content);
    ok $data->[0]->{f_class};
    ok $data->[0]->{sha1sum};
    ok $data->[0]->{uri};
}

__END__


* Origin:

 - store checksums for indexed files
 - provide manifest.json with URLs and checksums to various access points
   like /listing /category/x/y/manifest.json

* Client:

 - has a list of URLs to mirror.
 - retrieves the manifest
 - exclude exceptions
 - checks the netto list. Use a timestamp as reference
    - already mirrored? compare the checksums. 
       - If different? Fetch the resource.
       - Update the mirroring timestamp

    - new file? Fetch the resource and add the mirroring info,
      including the mirroring timestamp.

    - check files having that resource as origin and a timestamp which
      is not the same. Remove them.

* Interface:

 - you can add one or more origins
 - each origin can have exceptions
 - when adding exceptions, define a behavior. Remove files? Unlink
   them?
 - when removing origins, define a behavior. Remove files? Unlink
   them?


* Schema

Each site can have one or more mirror_origin. It defines a domain and
a path where to fetch the manifests.

Each text and attachment has a mirror_info record attached. With
mirror_origin_id null, it's a regular, local file. It still carries
the md5sum. We point to this record for exclusions and conflicts.

mirror_exclusion can be "exclusion" or "conflict".




