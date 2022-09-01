#!/usr/bin/env perl
use Getopt::Long;
use File::Slurp;
use JSON;
use strict;
use warnings;

my $dir = "output";
my $npz = 0;
my $spec_file;
GetOptions(
    "o|outdir=s"=> \$dir,
    "z|npz"	=> \$npz, 
);

if (@ARGV != 1) {
    die <<"USAGE";
usage: $0 [options] spec_file

options:
    -o, --outdir=string
    -z, --npz
USAGE
} else {
    $spec_file = shift @ARGV;
}

mkdir $dir unless -e $dir;

my @cmd = ('python', 'gen-data.py');
push @cmd, '-z' if $npz;
push @cmd, '-o', $dir;
push @cmd, $spec_file;
system @cmd;
system 'perl', 'find-vertex-of-body-part.pl', $dir;
system 'matlab', '-batch', "compute_inertia $dir";

my $fin;
my @joint_names = qw(
pelvis
lThigh
rThigh
abdomen
lCalf
rCalf
chest1
lFoot
rFoot
chest2
lSole
rSole
neck
lShoulder
rShoulder
head
lUpperArm
rUpperArm
lForearm
rForearm
lHand
rHand
);
my $num_joints = @joint_names;
my $width = 0.05;

sub read_list {
    my $fname = shift @_;
    my $i = 0;
    open $fin, '<', $fname;
    my @list;
    while (<$fin>) {
	chomp;
	my @a = split;
	$list[$i++] = \@a;
    }
    \@list;
}

my $pos = read_list("$dir/joints.txt");
my $mass = read_list("$dir/mass.txt");
my $com = read_list("$dir/center_of_mass.txt");
my $moi = read_list("$dir/inertia_tensor.txt");

my @kintree = @{read_list("$dir/kintree.txt")->[0]};

sub list_sub {
    my ($a, $b) = @_;
    die "lists don't have the same length" if @$a != @$b;
    map { $a->[$_] - $b->[$_] } (0 .. $#$a);
}

my $i = 0;
my @joints;
for my $name (@joint_names) {
    my $parent = $kintree[$i];
    my @pos;
    if ($parent < 10000) {
	@pos = list_sub($pos->[$i], $pos->[$parent]);	# from global to local frame
    } else {
	@pos = @{$pos->[$i]};
    }
    my $joint = {
	name	=> $name,
	pos	=> [map 0+$_, @pos],	# position in parent joint's local frame
	mass	=> 0+$mass->[$i][0],
	COM	=> [map 0+$_, @{$com->[$i]}],
	MOI	=> [map 0+$_, @{$moi->[$i]}],
	type	=> "ball",
    };
    push @joints, $joint;
    ++$i;
}

$joints[0]{type} = "free";

$i = 0;
for my $joint (@joints) {
    my $parent = $kintree[$i];
    my @a_pos = @{$joint->{pos}};
    if ($parent < 10000) {
	push @{$joints[$parent]{children}}, $joint;
	my @b_pos = @{$joints[$parent]{pos}};
	# find the long axis
	my $j = 0;
	my @box_pos;
	for (my $k = 0; $k < 3; ++$k) {
	    $j = $k if abs($a_pos[$k]) > abs($a_pos[$j]);
	    $box_pos[$k] = $a_pos[$k] / 2;
	}
	my @size = ($width) x 3;
	$size[$j] = abs($a_pos[$j]);
	my $shape = {
	    type => 'box',
	    size => \@size,
	    pos  => \@box_pos,
	};
	push @{$joints[$parent]{shape}}, $shape;
    }
    ++$i;
}

my $json = JSON->new;
$json->canonical(1);
write_file("$dir/character.json", $json->pretty->encode($joints[0]));
