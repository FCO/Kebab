constant size		= 256;
constant max-size	= 256;

class Shard {
	has Str			$.stream-name	= "stream";
	has IO::Path	$.root-dir		.= new: ".";
	has IO::Path	$.stream-dir	= $!root-dir.child: $!stream-name;
	has Int			$!last-pos		= 0;
	has Channel		$!write-channel .= new;
	has Promise		$!writing		= self!start-writing;

	method !initial-file(--> IO::Path) {
		my IO::Path %files{Int}	= $!stream-dir.dir.classify({ .basename.Int });
		my Int $file-num		= %files.keys.max;
		my IO::Path $file		= %files{$file-num};
		$!last-pos				= $file-num × max-size + $file.s ÷ size;
		$file
	}

	method !file-from-pos(Int $pos) {
		$!stream-dir.child: $pos div max-size
	}

	method !start-writing {
		my $write = self!initial-file.open: :a;
		start {
			react {
				whenever $!write-channel -> Blob $data where *.elems == size {
					$write.write: $data;
					my $file = self!file-from-pos(++$!last-pos);
					if $file !~~ $write {
						$write.close;
						$write = $file.open: :a
					}
				}
			}
		}
	}

	method add(Blob $data) {
		$!write-channel.send: $data.subbuf: ^size;
	}

	method get(Int $pos, Int $records = 1) {
		return unless "stream".IO.e;
		my $read  = open "stream", :r;
		$read.seek($pos × size, SeekFromBeginning);
		my $ret = $read.read: size × $records;
		$ret.rotor(size, :partial).map: -> @data { utf8.new: @data }
	}
}
