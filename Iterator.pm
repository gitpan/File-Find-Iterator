package File::Find::Iterator;


# Copyright (c) 2003 Robert Silve
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself. 

use Carp;
use IO::Dir;
use Storable;
use vars qw($VERSION);

$VERSION = "0.2";

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {@_};
    bless $self => $class;

    $self->code(
		walktree({statefile => $self->statefile} ,
			 @{$self->dir})
		);
    $self->filter(sub { 1 }) unless $self->filter; 

    return $self;
}


sub walktree {
    my ($opt, @TODO) = @_;
    my %opt = %$opt;

    return sub {

	if ($opt{statefile} && -e $opt{statefile} ) {
	    my $rTODO = retrieve($opt{statefile}) || 
		croak "Can't retrieve from $opt{statefile} : $!\n";
	    @TODO = @$rTODO;
	}
	
	return unless @TODO;
	my $item = pop @TODO;
	$item =~ s%/+$%%;
	if (-d  $item  ) {
	    my $d = IO::Dir->new($item);
	    while (defined($_ = $d->read)) { 
		next if ($_ eq '.' || $_ eq '..');
		push @TODO, "$item/$_";
	    }
	}

	if ($opt{statefile}) {
	    store(\@TODO, $opt{statefile}) ||
		croak "Can't store to $opt{statefile} : $!\n";
	}
	
	return $item;
    }
}

sub first {
    my $self = shift;
    $self->code(
		walktree({statefile => $self->statefile},
			 @{$self->dir})
		);
}

sub next {
    my $self = shift;
    my $item = undef;
    do {
	$item = $self->code->();
    } while ($item && ! $self->filter->($item));
    return $item;
    
}

sub AUTOLOAD {
    my ($self) = @_;
    my ($pack, $meth) =($AUTOLOAD =~ /^(.*)::(.*)$/);
    my @auth = qw(dir code filter statefile);
    my %auth = map { $_ => 1 } @auth;
    unless ($auth{$meth}) {
	croak "Unknow method $meth";
    }
    
    my $code = sub {
	my $self = shift;
	my $arg = shift;
	if ($arg) {
	    $self->{$meth} = $arg;
	} else {
	    return $self->{$meth};
	}
    };
    
    *$AUTOLOAD = $code;
    goto &$AUTOLOAD;
	    
}

1;


__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Find::File::Iterator - Iterator interface for search files

=head1 SYNOPSIS

  use File::Find::Iterator;
  my $find = File::Find::Iterator->new(dir => ["/home", "/var"],
                                       filter => \&isdir);

  while (my $f = $find->next) { print "file : $f\n" }
  
  #reread with different filter 
  $find->filter(\&ishtml);
  $find->first;
  while (my $f = $find->next) { print "file : $f\n" }

  # using file for storing state
  $find->statefile($statefile);
  $find->first;
  # this time it could crash
  while (my $f = $find->next) 
  { print "file : $f\n" }

=head1 DESCRIPTION

Find::File::Iterator is an iterator object for searching through directory
trees. You can easily run filter on each file name. You can easily save the
search state when you want to stop the search and continue the same search 
later.

=over 4

=item new(%opt)

This is the constructor. The C<%opt> accept the following key :

=over 4

=item dir C<< => \@dir >> 

which take a reference to a list of directory.

=item filter C<< => \&code >>

which take a code reference

=item statefile C<< => $file >>

which take a filename

=back

=item next

calling this method make one iteration. It return file name or 
C<undef> if there is no more work to do.

=item first

calling this method make an initialisation of the iterator.
You can use it for do a search again, but with some little 
change (directory root, statefile option, different filter).

=item dir([ \@dir ])

this method get or set the directory list for the search.

=item filter([ \&code ])

this method get or set the filter method use by C<next> method.

=item statefile([ $file ])

this method get or set the name of the file use for store state of the 
search (see L</"STORING STATE">).

=back



=head1 STORING STATE

If the option C<statefile> of the constructor or the C<statefile> field
of the object is set, the iterator use the L<Storable> module to record
is internal state after one iteration and to set is internal state before
a new iteration. With this mechanism you can continue your search after 
an error occurred.

=head1 AUTHOR

Robert Silve <robert@silve.net>

=cut
