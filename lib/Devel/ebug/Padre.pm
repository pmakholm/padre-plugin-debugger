package Devel::ebug::Padre;

use String::Koremutake;
use IO::Socket::INET;
use Class::Accessor::Chained::Fast;

use base (Devel::ebug);

__PACKAGE__->mk_accessors(qw(
    interpreter interpreter_args program_args));

our $VERSION = "0.49";

# This is a copy paste from Devel::ebug, except that the $command variable is
# more configurable

sub load {
  my $self = shift;
  my $program = $self->program;
  my $interpreter = $self->interpreter || $^X;
  my $interpreter_args = defined( $self->interpreter_args ) ?  $self->interpreter_args : "-Ilib";
  my $program_args = defined( $self->program_args ) ? $self->program_args : "";

  # import all the plugins into our namespace
  do { eval "use $_ " } for $self->plugins;

  my $k = String::Koremutake->new;
  my $rand = int(rand(100_000));
  my $secret = $k->integer_to_koremutake($rand);
  my $port   = 3141 + ($rand % 1024);

  $ENV{SECRET} = $secret;
  my $command = join " ", $interpreter, $interpreter_args, "-d:ebug::Backend", $program, $program_args;
#  warn "Running: $command\n";
  my $proc = Proc::Background->new(
    {'die_upon_destroy' => 1},
    $command
  );
  croak(qq{Devel::ebug: Failed to start up "$program" in load()}) unless $proc->alive;
  $self->proc($proc);
  $ENV{SECRET} = "";

  # try and connect to the server
  my $socket;
  foreach (1..10) {
    $socket = IO::Socket::INET->new(
      PeerAddr => "localhost",
      PeerPort => $port,
      Proto    => 'tcp',
      Reuse      => 1,
      ReuserAddr => 1,
    );
    last if $socket;
    sleep 1;
  }
  die "Could not connect: $!" unless $socket;
  $self->socket($socket);
 
  my $response = $self->talk({
    command => "ping",
    version => $VERSION,
    secret  => $secret,
  });
  my $version = $response->{version};
  die "Client version $version != our version $VERSION" unless $version eq $VERSION;
  $self->basic; # get basic information for the first line
}

1;
