# look for a particular string
sub look_for {
    my $file1 = shift;
    my $look = shift;

    open(F1, $file1) || return 0;

    my $res = 0;
    my $count = 0;
    while (<F1>)
    {
	$count++;
	my $comp1 = $_;
	# remove newline/carriage return (in case these aren't both Unix)
	$comp1 =~ s/\n//;
	$comp1 =~ s/\r//;
	if ($comp1 =~ /$look/)
	{
	    $res = 1;
	    last;
	}
    }
    close(F1);

    return $res;
}

1;
