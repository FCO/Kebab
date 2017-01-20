use lib "lib";
use Kebab;

my @a.push: start {
	my $s = Stream.new;
	for ^10 {
		say "write: ", $s.add: "value: $_".encode
	}
}

@a.push: start {
	my $s = Stream.new;
	my $pos = 0;
	for ^10 {
		say "read: $pos";
		for $s.get($pos, 3).map: { .decode } -> $data {
			say "DATA: $data"
		}
	}
}

await @a;
