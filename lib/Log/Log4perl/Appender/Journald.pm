=head1 NAME

Log::Log4perl::Appender::Journald - Journald appender for Log4perl

=head1 SYNOPSIS

  use Log::Log4perl;

  my $log4perl_conf = <<EOC;
  log4perl.rootLogger = DEBUG, Journal
  log4perl.appender.Journal = Log::Log4perl::Appender::Journald
  log4perl.appender.Journal.layout = Log::Log4perl::Layout::NoopLayout
  log4perl.appender.Journal.ifundef = "<not set>"
  EOC

  Log::Log4perl->init(\$log4perl_conf);
  Log::Log4perl::MDC->put(HELLO => 'World');
  my $logger = Log::Log4perl->get_logger('log4perl.rootLogger');
  $logger->info("Time to die.");
  $logger->error("Time to err.");

=head1 DESCRIPTION

This module provides a L<Log::Log4Perl> appender that directs log messages to
L<systemd-journald.service(8)> via L<Log::Journald>. It makes use of the
structured logging capability, appending Log4perl MDCs with each message.

=head2 OPTIONS

=over 4

=item ifundef

MDC items having an undef value are not logged by default. If you want to
see undef values in the log provide a string to be used.

=back

=cut

package Log::Log4perl::Appender::Journald;

our @ISA = qw/Log::Log4perl::Appender/;

use warnings;
use strict;

use Log::Log4perl;
use Log::Journald;
use Log::Log4perl::MDC;

sub new
{
	my($class, @options) = @_;
	bless { @options }, $class;
}

sub log
{
	my $self = shift;
	my %params = @_;
	my $mdc = Log::Log4perl::MDC->get_context();
	my %log;

	while (my ($key, $value) = each %params) {
		$log{uc $key} = $value;
	}

	# Add MDCs
	while (my ($key, $value) = each %$mdc) {
		$value = ($self->{ifundef} || next) unless (defined $value);
		$log{uc $key} = $value;
	}

	# Turn syslog level into journald priority
	$log{PRIORITY} = 7 - delete $log{LEVEL};

	# add the original line/file to the journal item
	my ($package, $file, $line) = caller( $Log::Log4perl::caller_depth + 3 );
	$log{LOG4P_LINE} = $line;
	$log{LOG4P_FILE} = $file;

	Log::Journald::send (%log) or warn $!;
}

1;

=head1 SEE ALSO

=over

=item *

L<Log::Journald> -- Journal daemon client bindings.

=item *

L<Log::Log4perl> -- A logging framework

=back

=head1 COPYRIGHT

Copyright 2014 Lubomir Rintel

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHORS

Lubomir Rintel, L<< <lkundrak@v3.sk> >>
Oliver Welter , L<< <owelter@whiterabbitsecurity.com> >>

The code is hosted on GitHub L<http://github.com/lkundrak/perl-Log-Journald>.
Bug fixes and feature enhancements are always welcome.
