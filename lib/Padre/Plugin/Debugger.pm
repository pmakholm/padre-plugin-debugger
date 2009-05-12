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
use File::Spec::Functions qw(catfile abs2rel rel2abs);
use YAML;

use Padre::Wx;
use Padre::Plugin;

use parent qw(Padre::Plugin);

our $VERSION = "0.2";

# -- Padre API, see Padre::Plugin

sub plugin_name { "Debugger" }

sub padre_interfaces {
    "Padre::Plugin" => 0.28,
}

sub menu_plugins_simple {
    my $self = shift;
    return $self->plugin_name => [
        "About" => sub { $self->show_about },
        "Start debugger" => sub { $self->start_debugger },
        "Stop debugger" => sub { $self->stop_debugger },
        "Running code..." => [
            "Continue\tShift+Alt+C" => sub { $self->debug_continue },
            "Step\tShift+Alt+S" => sub { $self->debug_step },
            "Next\tShift+Alt+N" => sub { $self->debug_next },
            "Return\tShift+Alt+R" => sub { $self->debug_return },
        ],
        "Breakpoint/Watches..." => [
            "Breakpoint\tShift+Alt+B" => sub { $self->debug_breakpoint },
            "Breakpoint (conditional)\tCtrl+Shift+Alt+B" => sub { $self->debug_breakpoint_cond },
            "Watch" => sub { $self->debug_watch },
        ],
        "Evaluate expression\tShift+Alt+E" => sub { $self->debug_eval },
        "Show stacktrace" => sub { $self->show_stacktrace },
    ]
}

# Public functions

sub show_about {
    my $self = shift;

    # Generate the About dialog
    my $about = Wx::AboutDialogInfo->new;
    $about->SetName("Padre::Plugin::Debugger");
    $about->SetDescription( <<"END_MESSAGE" );
Padre Perl5 Debugger
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
    $self->update_view;
}

sub stop_debugger {
    my $self = shift;
    my $main = Padre->ide->wx->main;
    my $doc  = $main->current->document;

    unless (exists $self->{debugger}) {
        $main->error("Debugger isn't running");
        return;
    }

    $main->message("Debugger stopped");

    delete $self->{debugger};
}

sub debug_step {
    my $self = shift;
    my $ebug = $self->{debugger};
    my $main = Padre->ide->wx->main;
    my $file = $main->current->document->filename;

    unless (defined $ebug) {
        $main->error("Debugger isn't running");
        return;
    }

    do { $ebug->step } until $self->update_view;
}

sub debug_continue {
    my $self = shift;
    my $ebug = $self->{debugger};
    my $main = Padre->ide->wx->main;

    unless (defined $ebug) {
        $main->error("Debugger isn't running");
        return;
    }

    $ebug->run;
    $self->update_view;
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
    $self->update_view;
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
    $self->update_view;
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

    if ($eval) {
        my $yaml = $ebug->yaml($eval);
        $main->message($yaml, "Result");
    }
    return 1;
}

sub debug_breakpoint {
    my $self = shift;
    my $cond = shift;
    my $ebug = $self->{debugger};
    my $main = Padre->ide->wx->main;
    my $file = $main->current->document->filename;

    $file = $self->resolve_file( $file );

    unless (defined $ebug) {
        $main->error("Debugger isn't running");
        return;
    }

    my $editor = Padre::Current->editor;
    my $line   = $editor->LineFromPosition($editor->GetCurrentPos);
    my $break  = $ebug->break_point($file, $line + 1, $cond) - 1;

    # Make marker:
    my $red    = Wx::Colour->new("red");

    $editor->MarkerDefine( MarkBreakPoint(), Wx::wxSTC_MARK_ARROW, $red, $red );
    $editor->MarkerAdd( $break, MarkBreakPoint() );

    return 1;
}
    
sub debug_breakpoint_cond {
    my $self = shift;
    my $ebug = $self->{debugger};
    my $main = Padre->ide->wx->main;

    unless (defined $ebug) {
        $main->error("Debugger isn't running");
        return;
    }

    my $cond = $main->prompt("Conditional breakpoint", "Please type condition to break on", "MY_DEBUGGER_BREAK");

    $self->debug_breakpoint($cond);
}

sub debug_watch {
    my $self = shift;
    my $ebug = $self->{debugger};

    my $main = Padre->ide->wx->main;

    unless (defined $ebug) {
        $main->error("Debugger isn't running");
        return;
    }

    my $watch = $main->prompt("Watch expression", "Please type expression to watch", "MY_DEBUGGER_WATCH");

    require Padre::Plugin::Debugger::Wx::Watches;

    $self->{watchbox} ||= Padre::Plugin::Debugger::Wx::Watches->new($main);
    $self->{watches}  ||= {};

    $self->{watches}->{$watch} = $ebug->eval($watch);

    $ebug->watch_point($watch);
    $main->bottom->show( $self->{watchbox} );

    $self->update_view();
}

sub show_stacktrace {
    my $self = shift;
    my $ebug = $self->{debugger};

    my $main = Padre->ide->wx->main;

    unless (defined $ebug) {
        $main->error("Debugger isn't running");
        return;
    }

    require Padre::Plugin::Debugger::Wx::StackTrace;

    $self->{stacktrace} ||= Padre::Plugin::Debugger::Wx::StackTrace->new($main);
    $self->{stacktrace}->set_debugger($self);

    $main->right->show( $self->{stacktrace} );

    $self->update_view();
}

sub goto_frame {
    my $self = shift;
    my $line = shift;

    my @stack = $self->{debugger}->stack_trace;
    my $frame = $stack[$line];

    my $main = Padre->ide->wx->main;
    my $id   = $main->find_editor_of_file( $frame->filename );
    unless ( defined $id ) {
        my $load = Wx::MessageBox(
	    "Unknown file, Should I load it?",
            "Padre", 
            Wx::wxYES_NO | Wx::wxCENTRE, 
            $main
        );
        return if $load == Wx::wxNO;

        $id = $main->setup_editor( $frame->filename );
    }

    $main->on_nth_pane($id);
    Padre::Current->editor->goto_line_centerize($frame->line - 1);

    return 1;
}

# Internal functions

sub MarkBreakPoint { 17 }

sub resolve_file {
    my $self = shift;
    my $file = shift;
    my $ebug = $self->{debugger};

    my $base  = $ebug->eval("require Cwd; Cwd::cwd;");
    my %known = map { rel2abs($_, $base) => $_ } $ebug->filenames;

    return $known{$file};
}

sub update_view {
    my $self   = shift;
    my $ebug   = $self->{debugger};
    my $editor = Padre::Current->editor;
    my $main = Padre->ide->wx->main;
    return unless $ebug;
    
    if ( $ebug->finished ) {
        $self->stop_debugger;
        return 1;
    }

    # Try to change to right file
    if ( $main->current->document->filename ne $ebug->filename ) {
        my $id = $main->find_editor_of_file( $ebug->filename );
	return unless defined $id; # Autoload files?

	$main->on_nth_pane($id);
        $editor = Padre::Current->editor;
    }

    # Move to current line
    my $line   = $ebug->line() - 1;
    $editor->goto_line_centerize($line);

    # Update watches
    if ($self->{watchbox}) {
        $self->{watches}->{$_} = $ebug->eval($_) for keys %{ $self->{watches} };

        $self->{watchbox}->clear;
        $self->{watchbox}->AppendText( YAML::Dump( $self->{watches} ) );
    }

    # Update stack trace
    if ($self->{stacktrace}) {
        $self->{stacktrace}->DeleteAllItems;

        my @stack = $ebug->stack_trace;

        $self->{stacktrace}->InsertStringItem( 0, $_->filename. "::" .  $_->line)
            for reverse @stack;
        
        $self->{stacktrace}->SetColumnWidth( 0, Wx::wxLIST_AUTOSIZE );
    }

    # Update output
    my($stdout, $stderr) = $ebug->output;
    $main->output->clear;               # We get the full output each time...
    $main->output->AppendText($stdout);
    $main->output->AppendText($stderr);

    return 1;
}

1;

__END__

=head1 NAME

Padre::Plugin::Debugger - Debug Perl code from Padre editor



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

L<Devel::ebug> - The backend debugger.

L<http://github.com/pmakholm/padre-plugin-debugger/tree/master> - Git repository

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-Debugger> - Bug tracking

=back



=head1 AUTHOR

Peter Makholm, C<< <peter@makholm.net> >>



=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 Peter Makholm, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
