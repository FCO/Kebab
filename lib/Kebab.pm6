constant size   = 256;
constant max    = 256;

class Shard {
	has Channel $!write-channel .= new;
	has Promise $!writing		= start {
		my $write = open "stream", :a;
		react {
			whenever $!write-channel -> Blob $data where *.elems == size {
				$write.write: $data
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
