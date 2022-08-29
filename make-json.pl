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

my $i = 0;
my @joints;
for my $name (@joint_names) {
    my $joint = {
	name	=> $name,
	pos	=> join(', ', @{$pos->[$i]}),
	mass	=> join(', ', @{$mass->[$i]}),
	COM	=> join(', ', @{$com->[$i]}),
	MOI	=> join(', ', @{$moi->[$i]}),
	type	=> "ball",
    };
    push @joints, $joint;
    ++$i;
}

$joints[0]{type} = "free";

$i = 0;
for my $joint (@joints) {
    my $parent = $kintree[$i];
    if ($parent < 10000) {
	push @{$joints[$parent]{children}}, $joint;
    }
    ++$i;
}

my $json = JSON->new;
$json->canonical(1);
write_file("$dir/character.json", $json->pretty->encode($joints[0]));
