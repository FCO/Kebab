class Shard {
	has Int			$.register-size	= 256;
	has Int			$.max-file-size	= 256;
	has Str			$.stream-name	= "stream";
	has IO::Path	$.root-dir		.= new: ".";
	has IO::Path	$.stream-dir	= $!root-dir.child: $!stream-name;
	has Int			$!last-pos		= 0;
	has Channel		$!write-channel .= new;
	has Promise		$!writing		= self!start-writing;

	method BUILDALL(|) {
		callsame;
		$!stream-dir.mkdir unless $!stream-dir.e;
		self
	}

	method !initial-file(--> IO::Path) {
		my @files			= $!stream-dir.dir;
		return $!stream-dir.child: 0 unless @files;
		my %files{Int}		= $!stream-dir.dir.classify({ .basename.Int });
		my Int $file-num	= %files.keys.max;
		my IO::Path $file	= %files{$file-num}.first;
		$!last-pos			= $file-num × $!max-file-size + $file.s div $!register-size;
		$file
	}

	method !file-from-pos(Int $pos) {
		$!stream-dir.child: $pos div $!max-file-size
	}

	method !start-writing {
		my $write = self!initial-file.open: :a;
		start {
			react {
				whenever $!write-channel -> Blob $data where *.elems == $!register-size {
					$write.write: $data;
					my $file = self!file-from-pos(++$!last-pos);
					if $file ne $write {
						$write.close;
						$write = $file.open: :a
					}
				}
			}
		}
	}

	method add(Blob $data) {
		$!write-channel.send: $data.subbuf: ^$!register-size;
	}

	method get(Int $pos, Int $records = 1) {
		my $file  = self!file-from-pos($pos);
		return unless $file.e;
		my $read  = $file.open;
		$read.seek($pos × $!register-size, SeekFromBeginning);
		my $ret = $read.read: $!register-size × $records;
		$ret.rotor($!register-size, :partial).map: -> @data { utf8.new: @data }
	}
}
