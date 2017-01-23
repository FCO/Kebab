use lib "lib";
use Kebab;

my @a;
my $s = Shard.new;
for ^10 {
	@a.push: start {
		$s.add: "value: $_".encode;
		say "write: $_"
	}
}

my $pos = 0;
for ^10 {
	say "read: $pos";
	for $s.get($pos, 3).map: { .decode } -> $data {
		say "DATA: $data";
		$pos++
	}
}

await @a;
