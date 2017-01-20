constant size   = 256;
constant max    = 256;

class Stream {
	has $!write = open "streem", :w;
	has $!read  = open "streem", :r;

	method add(Blob $data) {
		$!write.seek(0, SeekFromEnd);
		$!write.write: $data.subbuf: ^size;
		$!write.tell / size
	}

	method get(Int $pos is rw, Int $records = 1) {
		$!read.seek($pos * size, SeekFromBeginning);
		my $ret = $!read.read: size * $records;
		$pos += Int($ret.elems / size);
		$ret.rotor(size).map: -> @data { utf8.new: @data }
	}
}
