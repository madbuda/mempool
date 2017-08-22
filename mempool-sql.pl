#!/usr/bin/perl
use strict;
use warnings;

my $SQLITE="sqlite3";
my $MEMPOOLLOG="mempool.log";
my $MEMPOOLDB="mempool.s3db";
my ($size,$fee,$feeperbyte) = (0,0.0,0.0);
my @feelimit=(0.0001,5,10,20,30,40,50,60,70,80,90,100,120,140,160,180,200,220,240,260,280,300,350,400,450,500,550,600,650,700,750,800,850,900,950,1000);
my @total=( (0) x @feelimit);
my @count=( (0) x @feelimit);
my @fees =( (0) x @feelimit);
my $time = time;

while(<>) {
    /"size": (\d+)/ and $size = $1;
    /"fee": (\d*\.\d+)/ and $fee = int($1*1e8 + .5);

    if (/},/) {
    $feeperbyte = $fee / $size;
    for (my $i = 0; $i< @feelimit; $i++) {
        if ($feeperbyte >= $feelimit[$i]) {
        $total[$i] += $size;
        $count[$i]++;
        $fees[$i] += $fee;
        }
    }
    }
}
if ($count[0]) {
    my $cnt  = join(",", @count);
    my $size = join(",", @total);
    my $fee  = join(",", @fees);
    open(LOG, ">>$MEMPOOLLOG") or die $!;
    print LOG "[$time,[$cnt],[$size],[$fee]],\n";
    close(LOG);
    open(SQL, "|$SQLITE $MEMPOOLDB") or die $!;
    print SQL ".timeout 20000\n";
    my $line = "INSERT INTO mempool VALUES($time,$cnt,$size,$fee);\n";
    print SQL $line;
    close SQL;
}
