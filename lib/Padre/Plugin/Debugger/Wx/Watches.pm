package Padre::Plugin::Debugger::Wx::Watches;

use base 'Padre::Wx::Output';

sub gettext_label {
    Wx::gettext("Watches");
}

1;
