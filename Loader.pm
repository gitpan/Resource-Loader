# -*- perl -*- --------------------------------------------------
#
# Resource::Loader - load different resources depending...
#
# Joshua Keroes
#
# This number is *not* the $VERSION (see below):
# $Id: Loader.pm,v 1.6 2003/04/25 02:35:01 jkeroes Exp $

package Resource::Loader;

use strict;
use warnings;
use Carp;
use vars qw/$VERSION/;

$VERSION = '0.01';

# In:  hash-style args. See docs.
# Out: object
sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self  = {};

    bless $self, $class;

    $self->_init( @_ );
}

# In:  hash-style args. See docs for new()
# Out: object
sub _init {
    my $self = shift;
    my %args = @_;

    while ( my ( $method, $args ) = each %args ) {
	$self->$method( $args );
    }

    return $self;
}


# In:  array or arrayref. See docs.
# Out: array or arrayref of resources.
sub resources {
    my $self = shift;

    if ( @_ ) {
	undef $self->{resources};

	for ( ref $_[0] eq 'ARRAY' ? @{ $_[0] } : $_[0] ) {
	    croak "Malformed resource. Needs 'name', 'when', and 'code' args"
		unless defined $_->{name}
		    && defined $_->{when}
	            && defined $_->{code};

	    croak "Malformed resource. 'when' and 'code' need to be coderefs."
		unless ref $_->{code} eq "CODE"
		    && ref $_->{when} eq "CODE";

	    croak "Malformed resource. 'args' needs to be an arrayref."
		if $_->{args}
		    && ref $_->{args} ne "ARRAY";

	    push @{ $self->{resources} }, $_;
	}	
    }

    return wantarray ? @{ $self->{resources} } : $self->{resources};
}

# In:  optional new value
# Out: current value
sub testing {
    my $self = shift;
    $self->{testing} = shift if @_;
    return defined $ENV{RMTESTING} ? $ENV{RMTESTING} : $self->{testing};
}

# In:  optional new value
# Out: current value
sub verbose {
    my $self = shift;
    $self->{verbose} = shift if @_;
    return defined $ENV{RMVERBOSE} ? $ENV{RMVERBOSE} :  $self->{verbose};
}

# In:  optional new value
# Out: current value
sub cont {
    my $self = shift;
    $self->{cont} = shift if @_;
    return defined $ENV{RMCONT} ? $ENV{RMCONT} : $self->{cont};
}

# In:  n/a
# Out: hashref of our environment variables
sub env {
    my $self = shift;
    return { RMTESTING => $ENV{RMTESTING},
	     RMVERBOSE => $ENV{RMVERBOSE},
	     RMSTATES  => $ENV{RMSTATES},
	     RMCONT    => $ENV{RMCONT},
	   };
}

# In:  n/a
# Out: hashref of loaded states and their returns values.
sub loaded {
    my $self = shift;
    return $self->{loaded};
}

# In:  n/a
# Out: status report
#
# Runs the appropriate resources()
sub load {
    my $self = shift;

    # clear out loaded() and status() tables.
    undef $self->{loaded};
    undef $self->{status};
    $self->{status} = { map { $_->{name} => 'inactive' } @{ $self->{resources} } };

    for( @{ $self->{resources} } ) {
	my $name = $_->{name};


	if ( defined $ENV{RMSTATES} ) {
	    if ( grep { $_ eq $name } split /:/, $ENV{RMSTATES} ) {
		print __PACKAGE__ . " state '$name' present in RMSTATES environment var\n";
	    } else {
		print __PACKAGE__ . " state '$name' skipped due to RMSTATES environment var\n";
		$self->{status}{$name} = 'skipped';
		next;
	    }
	}

	if ( &{ $_->{when} } ) {
	    print __PACKAGE__ . " state '$name' active\n" if $self->verbose;

	    if ( $self->testing ) {
		print __PACKAGE__ . " in testing: won't run code for state '$name'\n" if $self->verbose;
		$self->{status}{$name} = 'notrun';
	    } else {
		my $code = $_->{code};
		$self->{loaded}{$name} = $code->( ref $_->{args} eq "ARRAY"
						  ? @{ $_->{args} }
						  : $_->{args}
						);
		$self->{status}{$name} = 'loaded';
	    }

	    last unless $self->cont;
	} else {
	    print __PACKAGE__ . " state '$name' inactive\n" if $self->verbose;
	    $self->{status}{$name} = 'inactive';
	}
    }

    return $self->loaded;
}

# In:  n/a
# Out: status report, e.g. { name => status, ... }
sub status {
    my $self = shift;

    return unless $self->{status}
	&& ref    $self->{status} eq "HASH";

    return $self->{status};
}

1;

__END__

=head1 NAME

Resource::Loader - Load different resources depending...

=head1 SYNOPSIS

  use Resource::Loader;

  $loader = Resource::Loader->new(
    testing => 0, # default
    verbose => 0, # default
    cont    => 0, # default
    resources =>
      [
	{ name => 'never',
	  when => sub { 0 },
	  code => sub { die "this will never be loaded" },
	},
	{ name => 'sometimes',
	  when => sub { int rand 2 > 0 },
	  code => sub { "'sometimes' was loaded. args: [@_]" },
	  args => [ qw/foo bar baz/ ],
	},
	{ name => 'always',
	  when => sub { 1 },
	  code => sub { "always' was loaded" },
	},
      ],
  );

  $loaded = $loader->load;
  $status = $loader->status;

=head1 DESCRIPTION

Resource::Loader is simple at its core: You give it a list of
resources. Each resource knows when it should be triggered, and if
it's triggered, will run its code segment.

Both the 'when' and the 'code' pieces are coderefs, so you can be as
devious as you want in determining when a resource will be loaded.

I originally wrote this to solve a simple problem but realized that
the class is probably applicable to a whole slew of problems. I look
forward to hearing to what devious ends you push this module.  Really,
send me an email - I love hearing about people using my toys.

Want to know what my simple problem was? See the L<EXAMPLES>.

=head1 METHODS

=head2 resources()

What to run and when to run it.

Accepts a listref of hashrefs like:

  [
    { name => 'never',
      when => sub { 0 },
      code => sub { die "this will never be loaded" },
    },
    { name => 'sometimes',
      when => sub { int rand 2 > 0 },
      code => sub { "'sometimes' was loaded. args: [@_]" },
      args => [ qw/foo bar baz/ ],
    },
    { name => 'always',
      when => sub { 1 },
      code => sub { "always' was loaded" },
    },
  ],

Each resource is a hashref that takes the same arguments:

  name: what is this resource called?

  when: a coderef that controls whether the resource will be activated

  code: a coderef that is only run if the 'when' code returns true

  args: an optional arrayref of args that are passed to the 'code'.

Note: using colons in your 'name's is not recommended. It will break
the $ENV{RMSTATES} handling.

=head2 load()

Load the resources.

Walks through the resources() in order. For each resource, if the
'when' coderef returns true, then the 'code' coderef will be run as well.

That behaviour can be changed by the cont() and  testing() methods
as well as the RMCONT and RMTESTING environment variables.

load() returns the output of loaded(); a hashref of statenames that
loaded successfully and the respective return values. See loaded().

Note: Running this method will overwrite the current status() and
loaded() tables with new info.

=head2 cont()

Do you want to continue loading resources after the first one is
loaded?  Sometimes you want the first successful resource to load and
then skip all the others. That's the default behaviour. If you set
cont() to 1, then load() will keep checking (and loading resources).

When true, all states with true 'when' coderefs will be loaded.

When false, execution of states will stop after the first. (default)

The RMCONT environment variable value takes precedence to any
value that this method is set to.

cont() will return true if either $ENV{RMCONT} or this method has
been set to true.

=head2 testing()

When true, don't actually run the 'code' resources.

When false, it will.

The RMTESTING environment variable value takes precedence to any value
that this is set to.  It will return true if either $ENV{RMTESTING} or
this method has been set to true.

When testing() is on, status() results will be set to 'skipped' if the
'when' coderef if true but the 'code' coderef wasn't run.

=head2 verbose() - be chatty

When true, print internal processing messages to STDOUT

When false, run quietly.

The RMCONT environment variable value takes precedence to any value
that this is set to. It will return true if either $ENV{RMCONT} or
this method has been set to true.

=head2 status()

Returns a hashref of which resources loading stati. Maps state names to one of these values:

  loaded: 'when' succeded so 'code' was run

  skipped: the state name wasn't in $ENV{RMSTATES} so neither 'when' nor 'code' was run

  notrun: 'when' succeeded and but 'code' wasn't run because we're in testing mode.

  inactive: 'code' wasn't run.

sub loaded()

Returns a hashref that maps state names to the return values of loaded resources.

=head2 env()

Returns a hashref of the Resource::Loader-related environment variables and their current
values. Probably only useful for debugging.

=head1 ENVIRONMENT

Use these environment variables to override the local behavior of the
object (e.g. to test your Resource::Loader's responses)

=head2 RMSTATES

colon-separated list of states to run resources for. The 'when'
coderefs won't even be run if the state names aren't listed here.

=head2 RMCONT

See cont()

=head2 RMTESTING

See testing()

=head2 RMVERBOSE

See verbose()

=head1 EXAMPLES

I originally wrote this to handle software deployment. Our software
starts its life on our development machine. From there, it's pushed to
a test machine. If it tests clean, it's eventually moved to a
production machine. The test and production machines are supposed to
be as similar as possible to prevent surprises when we deploy to
production.

We don't want to mix environments by, say, testing code on the dev
box with the production database.

The source code for this is in the examples/ directory.

=head1 SEE ALSO

City of God. It's quite a movie.

=head1 AUTHOR

Joshua Keroes, E<lt>skunkworks@eli.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Joshua Keroes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
