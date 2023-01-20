use Cro::HTTP::Router;
use Cro::HTTP::Server;

use Kebab::Shard;

my $topic = Kebab::Shard.new;

my $application = route {
  get -> 'index', UInt $index {
    my :(Str() $key, Str() $value) := await $topic.get($index);
    content 'application/json', %( :$key, :value($value.subst: /\0+$/, "") )
  }
  post {
    request-body -> $parts {
      for $parts.parts -> (Str :$name, Blob :$body-blob, |) {
        dd $name, $body-blob;
        $topic.add: $name, $body-blob;
      }
      content 'application/json', %( :status )
    }
  }
}
my Cro::Service $hello = Cro::HTTP::Server.new:
    :host<localhost>, :port<10000>, :$application;
$topic.start;
$hello.start;
react whenever signal(SIGINT) { $hello.stop; $$topic.stop; exit; }
