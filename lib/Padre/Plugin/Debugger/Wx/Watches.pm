package Padre::Plugin::Debugger::Wx::Watches;

use base 'Padre::Wx::Output';

sub gettext_label {
    Wx::gettext("Watches");
}

sub set_debugger {
    my $self     = shift;
    my $debugger = shift;

    $self->{debugger} = $debugger;
}


1;
