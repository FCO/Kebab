unit class Kebab::Shard;

has UInt    $.size                 = 256;
has UInt    $.key-size             = 256;
has UInt    $.max-elems            = 256;
has UInt    $.max-interval         = 60;

has Channel $!writter             .= new;
has Int     $!current-bucket       = 0;
has Int     $!current-bucket-size  = 0;
has UInt    $!current-id           = 0;
has         $!write;
has Pair    @!files;
has Promise %!proms;

multi method add($data) {
	$.add: Blob.new(0 xx $!key-size), $data
}

multi method add(Str $key, $data) {
	$.add: $key.encode, $data
}

multi method add(Blob $key, Str $data) {
	$.add: $key, $data.encode
}

multi method add(Blob $key, Blob $data) {
	$!writter.send: Blob.new: |$key, 0 xx $!size - $key.elems, |$data, 0 xx $!size - $data.elems
}

method pair-for-index(UInt $index where * < $!current-id) {
	@!files.first: :end, { .key <= $index }
}

method resp-from-blob(Blob $data) {
	utf8.new(|$data[^$!key-size]).Str.subst(/\0+$/, ""), utf8.new(|$data[$!key-size .. $!key-size + $!size - 1])
}

method sync-get(Int $pos, UInt $records?) {
	my (UInt $first-id, IO() $file) = .key, .value given $.pair-for-index: $pos;
	return unless $file.e;
	my $read = $file.open: :r, :bin;
	$read.seek(($pos - $first-id) × ($!key-size + $!size), SeekFromBeginning);
	my $ret = $read.read: ($!key-size + $!size) × ($records // 1);
	$read.close;
	do with $records {
		$ret.rotor($!key-size + $!size, :partial).map: -> @data { $.resp-from-blob: @data }
	} else {
		$.resp-from-blob: $ret
	}
}

method get(UInt $index, UInt $records?) {
	return Promise.kept: $.sync-get: $index if $index < $!current-id;
	%!proms{$index} //= Promise.new;
}

method start {
	start react {
		whenever $!writter -> Blob $data where *.elems == $!key-size + $!size {
			my UInt $id = $!current-id++;
			my IO() $file = $.file-name;
			if !$!write || !$file.f {
				$!write = $file.open: :a, :bin;
				$!current-bucket-size = 0;
				@!files.push: Pair.new: $id, $file
			}
			$!write.write: $data;
			.keep: $.resp-from-blob: $data with %!proms{$id};
			$!current-bucket++ if ++$!current-bucket-size > $!max-elems;
			$!write.flush
		}
	}
}

method stop {
	$!writter.close
}

method time-bucket {
	my Rat() $now = now;
	my Int() $bucket = $now - ($now % $!max-interval);
}

method file-name { "{ $.time-bucket }-{ $!current-bucket }.stream"}
