use strict;
use Test::More;
use FindBin;
use File::Spec;
use File::Find;

plan skip_all => 'Enable this optional test with $ENV{C_M_DBIC_SCHEMA_TESTAPP}'
    unless $ENV{C_M_DBIC_SCHEMA_TESTAPP};

# XXX this test needs a re-write to fully test the current set of capabilities...

my $test_params = [
    [ 'TestSchema', 'DBIC::Schema', '' ],
    [ 'TestSchemaDSN', 'DBIC::Schema', q{fakedsn fakeuser fakepass "{ AutoCommit => 1 }"} ],
];

plan tests => (2 * @$test_params);

my $test_dir   = $FindBin::Bin;
my $blib_dir   = File::Spec->catdir ($test_dir, '..', 'blib', 'lib');
my $cat_dir    = File::Spec->catdir ($test_dir, 'TestApp');
my $catlib_dir = File::Spec->catdir ($cat_dir, 'lib');
my $creator    = File::Spec->catfile($cat_dir, 'script', 'testapp_create.pl');
my $model_dir  = File::Spec->catdir ($catlib_dir, 'TestApp', 'Model');

chdir($test_dir);
system("catalyst.pl TestApp");
chdir($cat_dir);

foreach my $tparam (@$test_params) {
   my ($model, $helper, $args) = @$tparam;
   system("$^X -I$blib_dir $creator model $model $helper $model $args");
   my $model_path = File::Spec->catfile($model_dir, $model . '.pm');
   ok( -f $model_path, "$model_path is a file" );
   my $compile_rv = system("$^X -I$blib_dir -I$catlib_dir -c $model_path");
   ok($compile_rv == 0, "perl -c $model_path");
}

chdir($test_dir);

sub rm_rf {
    my $name = $File::Find::name;
    if(-d $name) { rmdir $name or die "Cannot rmdir $name: $!" }
    else { unlink $name or die "Cannot unlink $name: $!" }
}
finddepth(\&rm_rf, $cat_dir);
