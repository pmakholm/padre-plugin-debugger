package Padre::Plugin::Debugger::Wx::Menu;

use Padre::Wx::Menu ();
use base 'Padre::Wx::Menu';

sub new {
    my $class  = shift;
    my $main   = shift;
    my $plugin = shift;

    # Create the empty menu as normal
    my $self   = $class->SUPER::new(@_);

    # Add additional properties
    $self->{main}   = $main;
    $self->{plugin} = $plugin;

    $self->{start} = $self->Append(
        -1,
        "Start debugger\tShift+Alt+F5",
    );
    Wx::Event::EVT_MENU(
        $main,
        $self->{start},
        sub { 
            $plugin->start_debugger;
        },
    );

    $self->{stop} = $self->Append(
        -1,
        "Stop debugger",
    );
    Wx::Event::EVT_MENU(
        $main,
        $self->{stop},
        sub { 
            $plugin->stop_debugger;
        },
    );

    # View sub menu
    my $view_menu = Wx::Menu->new();
    $self->Append(
        -1,
        "View...",
        $view_menu
    );

    $self->{view_stacktrace} = $view_menu->AppendCheckItem(
        -1,
        "Show stacktrace",
    );
    Wx::Event::EVT_MENU(
        $main,
        $self->{view_stacktrace},
        sub { 
            $plugin->show_stacktrace( $_[1]->IsChecked );
        },
    );

    $self->{view_watches} = $view_menu->AppendCheckItem(
        -1,
        "Show watches",
    );
    Wx::Event::EVT_MENU(
        $main,
        $self->{view_watches},
        sub { 
            $plugin->show_watches( $_[1]->IsChecked );
        },
    );

    # Run sub menu
    my $run_menu = Wx::Menu->new();
    $self->Append(
        -1,
        "Run...",
        $run_menu
    );

    $self->{continue} = $run_menu->Append(
        -1,
        "Continue\tShift+Alt+C",
    );
    Wx::Event::EVT_MENU(
        $main,
        $self->{continue},
        sub { 
            $plugin->debug_continue;
        },
    );

    $self->{step} = $run_menu->Append(
        -1,
        "Step\tShift+Alt+S",
    );
    Wx::Event::EVT_MENU(
        $main,
        $self->{step},
        sub { 
            $plugin->debug_step;
        },
    );

    $self->{next} = $run_menu->Append(
        -1,
        "Next\tShift+Alt+N",
    );
    Wx::Event::EVT_MENU(
        $main,
        $self->{stop},
        sub { 
            $plugin->debug_next;
        },
    );

    $self->{return} = $run_menu->Append(
        -1,
        "Return\tShift+Alt+R",
    );
    Wx::Event::EVT_MENU(
        $main,
        $self->{return},
        sub { 
            $plugin->debug_return;
        },
    );


    # Breakpoints and watches
    my $break_menu = Wx::Menu->new();
    $self->Append(
        -1,
        "Breakpoints and watches...",
        $break_menu,
    );

    $self->{breakpoint} = $break_menu->Append(
        -1,
        "Add breakpoint\tShift+Alt+B",
    );
    Wx::Event::EVT_MENU(
        $main,
        $self->{breakpoint},
        sub { 
            $plugin->debug_breakpoint;
        },
    );

    $self->{breakpoint_cond} = $break_menu->Append(
        -1,
        "Add breakpoint (conditional)\tCtrl+Shift+Alt+B",
    );
    Wx::Event::EVT_MENU(
        $main,
        $self->{breakpoint_cond},
        sub { 
            $plugin->debug_breakpoint_cond;
        },
    );

    $self->{watch} = $break_menu->Append(
        -1,
        "Add watch\tShift+Alt+W",
    );
    Wx::Event::EVT_MENU(
        $main,
        $self->{watch},
        sub { 
            $plugin->debug_watch;
        },
    );

    # Main menu
    $self->{eval} = $self->Append(
        -1,
        "Eval expression\tShift+Alt+E",
    );
    Wx::Event::EVT_MENU(
        $main,
        $self->{eval},
        sub { 
            $plugin->debug_eval;
        },
    );

    $self->AppendSeparator;
    $self->{about} = $self->Append(
         Wx::wxID_ABOUT,
        "About",
    );
    Wx::Event::EVT_MENU(
        $main,
        $self->{about},
        sub { 
            $plugin->show_about;
        },
    );

    return $self;
}

sub refresh {
    my $self       = shift;
    my $plugin     = $self->{plugin};
    my $main       = $self->{main};
    my $document   = $main->current->document;
    my $is_running = $plugin->is_running;

    $self->{start}->Enable( !$is_running );
    $self->{stop}->Enable(  $is_running );

    $self->{$_}->Enable( $is_running )
        for qw( 
            continue step next return
            breakpoint breakpoint_cond watch
            eval
        );

    return 1;
}

1;
