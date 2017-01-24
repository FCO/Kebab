use lib "lib";
use Kebab;

my @a;
my $s = Shard.new: :2max-file-size, :stream-name<my-test>;
for ^10 {
	@a.push: start {
		$s.add: "value: $_".encode;
		say "write: $_"
	}
}

for ^2 -> $tid {
	@a.push: start {
		my $pos = 0;
		say "read $tid: $pos";
		my $has-data = True;
		for ^10 {
			for $s.get($pos, 3).map: { .decode } -> $data {
				note $data;
				if ?$data {
					say "DATA $tid: $data";
					$pos++
				} else {
					$has-data = False
				}
			}
		}
	}
}

await @a;
