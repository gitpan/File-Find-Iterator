# -*- perl -*-

use Test::More;
BEGIN { plan tests => 4 };
use File::Find::Iterator;

my $find = File::Find::Iterator->new(dir => ["."]);

# test creation
ok $find;

# test next method
my @res = ();
while (my $f =  $find->next) {
    push @res, $f;
}
ok @res;

# test first method
$find->first;
my @res2 = ();
while (my $f = $find->next) {
    push @res2, $f;
}
ok @res == @res2;

# test the filter feature
sub isdir { return -d $_[0] }
$find->filter(\&isdir);
$find->first;
my $res3 = 1;
while (my $f =  $find->next) {
    $res3 &&= -d $f;
}
ok $res3;
