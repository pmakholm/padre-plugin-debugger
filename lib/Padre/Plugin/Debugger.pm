#
# This file is part of Padre::Plugin::Debugger.
# Copyright (c) 2009 Peter Makholm, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Padre::Plugin::Debugger;

use strict;
use warnings;

use File::Basename qw(fileparse);
use File::Spec::Functions qw(catfile);

use Padre::Wx;
use Padre::Plugin;

use parent qw(Padre::Plugin);

our $VERSION = "0.0_1";

# -- Padre API, see Padre::Plugin

sub plugin_name { "Debugger" }

sub padre_interfaces {
    "Padre::Plugin" => 0.28,
}

sub menu_plugins_simple {
    my $self = shift;
    return $self->plugin_name => [
        "About" => sub { $self->show_about },
        "Run debugger" => sub { $self->start_debugger },
        "Stop debugger" => sub { $self->stop_debugger },
        "Step\tShift+Alt+S" => sub { $self->debug_step },
        "Next\tShift+Alt+N" => sub { $self->debug_next },
        "Return\tShift+Alt+R" => sub { $self->debug_return },
        "Eval\tShift+Alt+E" => sub { $self->debug_eval },
    ]
}

# Public functions

sub show_about {
    my $self = shift;

    # Generate the About dialog
    my $about = Wx::AboutDialogInfo->new;
    $about->SetName("Padre::Plugin::Debugger");
    $about->SetDescription( <<"END_MESSAGE" );
Initial debugger plugin for Padre
END_MESSAGE
    $about->SetVersion( $VERSION );

    # Show the About dialog
    Wx::AboutBox( $about );

    return;
}

sub start_debugger {
    my $self = shift;
    my $main = Padre->ide->wx->main;
    my $doc  = $main->current->document;

    if (exists $self->{debugger}) {
        $main->error("Debugger is allready running");
        return;
    }

    require Devel::ebug;
    my $ebug = Devel::ebug->new();
    $ebug->program($doc->filename);
    $ebug->load;

    $self->{debugger} = $ebug;
    $self->mark_current_line;
}

sub stop_debugger {
    my $self = shift;
    my $main = Padre->ide->wx->main;
    my $doc  = $main->current->document;

    unless (exists $self->{debugger}) {
        $main->error("Debugger isn't running");
        return;
    }

    delete $self->{debugger};
}

sub debug_step {
    my $self = shift;
    my $ebug = $self->{debugger};
    my $main = Padre->ide->wx->main;

    unless (defined $ebug) {
        $main->error("Debugger isn't running");
        return;
    }

    $ebug->step;
    $self->mark_current_line;
}

sub debug_next {
    my $self = shift;
    my $ebug = $self->{debugger};
    my $main = Padre->ide->wx->main;

    unless (defined $ebug) {
        $main->error("Debugger isn't running");
        return;
    }

    $ebug->next;
    $self->mark_current_line;
}

sub debug_return {
    my $self = shift;
    my $ebug = $self->{debugger};
    my $main = Padre->ide->wx->main;

    unless (defined $ebug) {
        $main->error("Debugger isn't running");
        return;
    }

    $ebug->return;
    $self->mark_current_line;
}

sub debug_eval {
    my $self = shift;
    my $ebug = $self->{debugger};
    my $main = Padre->ide->wx->main;

    unless (defined $ebug) {
        $main->error("Debugger isn't running");
        return;
    }

    my $eval = $main->prompt("Evaluate in debugger", "Please type expression to evaluate", "MY_DEBUGGER_EVAL");

    print STDERR "Debugger going to evaluate: $eval\n";

    if ($eval) {
        my $yaml = $ebug->yaml($eval);
        print STDERR $yaml;
    }

    print STDERR "...\n";

    return 1;
}

# Internal functions

sub MarkCurrent { 42 };

sub mark_current_line {
    my $self   = shift;
    my $ebug   = $self->{debugger};
    my $line   = $ebug->line() - 1;
    my $editor = Padre::Current->editor;
    my $syntax = Padre->ide->wx->main->syntax;

    $editor->goto_line_centerize($line);

    $syntax->clear;

    my $green = Wx::Colour->new("green");
    $editor->MarkerDefine( MarkCurrent(), Wx::wxSTC_MARK_SMALLRECT, $green, $green );

    $editor->MarkerAdd( $line, MarkCurrent() );

    return 1;
}

1;

__END__

=head1 NAME

Padre::Plugin::Debugger - send code on a nopaste website from padre



=head1 SYNOPSIS

    $ padre



=head1 DESCRIPTION

This plugin allows one to debug perl code from within Padre. 

=head1 BUGS

Many! This is an very early alpha release. You did notice the version number,
right?

Please report any bugs or feature requests to C<padre-plugin-debugger at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-Debugger>. I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.



=head1 SEE ALSO

Our git repository is located at L<git://github.com/pmakholm/padre-plugin-debugger.git>,
and can be browsed at L<http://github.com/pmakholm/padre-plugin-debugger/tree/master>.


You can also look for information on this module at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-Debugger>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-Debugger>

=item * Open bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-Debugger>

=back



=head1 AUTHOR

Peter Makholm, C<< <peter@makholm.net> >>



=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 Peter Makholm, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
