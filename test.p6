use lib "lib";
use Kebab::Shard;

my Kebab::Shard $s .= new;
my $p = $s.start;

for ^500 {
	$s.add: "test", "blablabla: $_"
}

my (Str $key, utf8 $value) := await($s.get: 345);

say "$key => { $value.Str }";
