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
    [ 'TestSchemaDSN', 'DBIC::Schema', qw/fakedsn fakeuser fakepass/, '{ AutoCommit => 1 }' ],
    [ 'TestSchemaDSN', 'DBIC::Schema', 'create=static', 'traits=Caching', 'moniker_map={ roles => "ROLE" }', 'constraint=^users\z', 'dbi:SQLite:testdb.db' ],
    [ 'TestSchemaDSN', 'DBIC::Schema', 'create=static', 'traits=Caching', 'moniker_map={ roles => "ROLE" }', 'constraint=^users\z', 'dbi:SQLite:testdb.db', '', '', 'on_connect_do=["select 1", "select 2"]', 'quote_char="' ],
    [ 'TestSchemaDSN', 'DBIC::Schema', 'create=static', 'traits=Caching', 'moniker_map={ roles => "ROLE" }', 'dbi:SQLite:testdb.db', 'on_connect_do=["select 1", "select 2"]', 'quote_char="' ],
    [ 'TestSchemaDSN', 'DBIC::Schema', 'create=static', 'traits=Caching', 'inflect_singular=sub { $_[0] =~ /\A(.+?)(_id)?\z/; $1 }', q{moniker_map=sub { return join('', map ucfirst, split(/[\W_]+/, lc $_[0])); }}, 'dbi:SQLite:testdb.db' ],
];

my $test_dir   = $FindBin::Bin;
my $blib_dir   = File::Spec->catdir ($test_dir, '..', 'blib', 'lib');
my $cat_dir    = File::Spec->catdir ($test_dir, 'TestApp');
my $catlib_dir = File::Spec->catdir ($cat_dir, 'lib');
my $schema_dir = File::Spec->catdir ($catlib_dir, 'TestSchemaDSN');
my $creator    = File::Spec->catfile($cat_dir, 'script', 'testapp_create.pl');
my $model_dir  = File::Spec->catdir ($catlib_dir, 'TestApp', 'Model');
my $db         = File::Spec->catdir ($cat_dir, 'testdb.db');

chdir($test_dir);
system("catalyst.pl TestApp");
chdir($cat_dir);

# create test db
open my $sql, '|-', 'sqlite3', $db or die $!;
print $sql <<'EOF';
CREATE TABLE users (                       
        id            INTEGER PRIMARY KEY, 
        username      TEXT,                
        password      TEXT,                
        email_address TEXT,                
        first_name    TEXT,                
        last_name     TEXT,                
        active        INTEGER              
);
CREATE TABLE roles (
        id   INTEGER PRIMARY KEY,
        role TEXT
);
EOF
close $sql;

foreach my $tparam (@$test_params) {
   my ($model, $helper, @args) = @$tparam;

   cleanup_schema();

   system($^X, "-I$blib_dir", $creator, 'model', $model, $helper, $model, @args);

   my $model_path = File::Spec->catfile($model_dir, $model . '.pm');
   ok( -f $model_path, "$model_path is a file" );
   my $compile_rv = system("$^X -I$blib_dir -I$catlib_dir -c $model_path");
   ok($compile_rv == 0, "perl -c $model_path");

   if (grep /create=static/, @args) {
      my @result_files = result_files();

      if (grep /constraint/, @args) {
         is scalar @result_files, 1, 'constraint works';
      } else {
         is scalar @result_files, 2, 'correct number of tables';
      }

      for my $file (@result_files) {
         my $code = code_for($file);

         like $code, qr/use Moose;\n/, 'use_moose enabled';
         like $code, qr/__PACKAGE__->meta->make_immutable;\n/, 'use_moose enabled';
      }
   }
}

# Test that use_moose=1 is not applied to existing non-moose schemas (RT#60558)
{
   cleanup_schema();

   system($^X, "-I$blib_dir", $creator, 'model',
      'TestSchemaDSN', 'DBIC::Schema', 'TestSchemaDSN',
      'create=static', 'use_moose=0', 'dbi:SQLite:testdb.db'
   );

   my @result_files = result_files();

   for my $file (@result_files) {
      my $code = code_for($file);

      unlike $code, qr/use Moose;\n/, 'non use_moose=1 schema';
      unlike $code, qr/__PACKAGE__->meta->make_immutable;\n/, 'non use_moose=1 schema';
   }

   system($^X, "-I$blib_dir", $creator, 'model',
      'TestSchemaDSN', 'DBIC::Schema', 'TestSchemaDSN',
      'create=static', 'dbi:SQLite:testdb.db'
   );

   for my $file (@result_files) {
      my $code = code_for($file);

      unlike $code, qr/use Moose;\n/,
         'non use_moose=1 schema not upgraded to use_moose=1';
      unlike $code, qr/__PACKAGE__->meta->make_immutable;\n/,
         'non use_moose=1 schema not upgraded to use_moose=1';
   }
}

# Test that a moose schema is not detected as a non-moose schema due to an
# errant file.
{
   cleanup_schema();

   system($^X, "-I$blib_dir", $creator, 'model',
      'TestSchemaDSN', 'DBIC::Schema', 'TestSchemaDSN',
      'create=static', 'dbi:SQLite:testdb.db'
   );

   mkdir "$schema_dir/.svn";
   open my $fh, '>', "$schema_dir/.svn/foo"
      or die "Could not open $schema_dir/.svn/foo for writing: $!";
   print $fh "gargle\n";
   close $fh;

   mkdir "$schema_dir/Result/.svn";
   open $fh, '>', "$schema_dir/Result/.svn/foo"
      or die "Could not open $schema_dir/Result/.svn/foo for writing: $!";
   print $fh "hlagh\n";
   close $fh;

   system($^X, "-I$blib_dir", $creator, 'model',
      'TestSchemaDSN', 'DBIC::Schema', 'TestSchemaDSN',
      'create=static', 'dbi:SQLite:testdb.db'
   );

   for my $file (result_files()) {
      my $code = code_for($file);

      like $code, qr/use Moose;\n/,
         'use_moose detection not confused by version control files';
      like $code, qr/__PACKAGE__->meta->make_immutable;\n/,
         'use_moose detection not confused by version control files';
   }
}

done_testing;

sub rm_rf {
    my $name = $File::Find::name;
    if(-d $name) { rmdir $name or die "Cannot rmdir $name: $!" }
    else { unlink $name or die "Cannot unlink $name: $!" }
}

sub cleanup_schema {
   return unless -d $schema_dir;
   finddepth(\&rm_rf, $schema_dir);
   unlink "${schema_dir}.pm";
}

sub code_for {
   my $file = shift;

   open my $fh, '<', $file;
   my $code = do { local $/; <$fh> };
   close $fh;

   return $code;
}

sub result_files {
   my $glob = File::Spec->catfile($schema_dir, 'Result', '*');

   return glob($glob);
}

END {
    if ($ENV{C_M_DBIC_SCHEMA_TESTAPP}) {
        chdir($test_dir);
        finddepth(\&rm_rf, $cat_dir);
    }
}

# vim:sts=3 sw=3 et tw=80:
