use lib "lib";
use Kebab;

my @a.push: start {
	my $s = Shard.new;
	for ^10 {
		$s.add: "value: $_".encode;
		say "write: $_"
	}
}

@a.push: start {
	my $s = Shard.new;
	my $pos = 0;
	for ^10 {
		say "read: $pos";
		for $s.get($pos, 3).map: { .decode } -> $data {
			say "DATA: $data"
		}
	}
}

await @a;
