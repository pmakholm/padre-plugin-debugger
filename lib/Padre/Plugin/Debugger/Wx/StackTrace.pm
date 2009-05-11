package Padre::Plugin::Debugger::Wx::StackTrace;

use base 'Padre::Wx::FunctionList';

sub gettext_label {
    Wx::gettext("StackTrace");
}

sub set_debugger {
    my $self     = shift;
    my $debugger = shift;

    $self->{debugger} = $debugger;
}

sub on_list_item_activated {
    my $self     = shift;
    my $event    = shift;
    my $debugger = $self->{debugger};
   
    return unless $debugger;

    my $frame = $event->GetIndex;

    $debugger->goto_frame($frame);
}

1;
