#!/usr/bin/env perl
use File::Slurp;
use strict;
use warnings;

die "usage: $0 directory ...\n" if @ARGV == 0;

for my $dir (@ARGV) {
    my @par_of_vtx = read_file("$dir/parent_of_vertex.txt");

    open my $fin, '<', "$dir/vertices.txt";
    my @vtx_of;
    my $idx = 0;
    while (<$fin>) {
	chomp;
	push @{$vtx_of[$par_of_vtx[$idx]]}, $_;
	++$idx;
    }

    mkdir "$dir/body_parts" unless -e "$dir/body_parts";
    $idx = 0;
    for my $vertices(@vtx_of) {
	open my $fout, '>', sprintf("$dir/body_parts/vertices-%02d.txt", $idx);
	print $fout join("\n", @$vertices);
	++$idx;
    }
}
