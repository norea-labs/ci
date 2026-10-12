#!/usr/bin/env perl
# Controllo Norea: cerca il punto mediano (U+00B7), il trattino lungo (U+2014) ed emoji
# nelle righe aggiunte o cambiate dalla PR. Le righe che la PR non tocca non vengono lette.
#
# Variabili d'ambiente:
#   NOREA_BASE     commit di partenza (base della PR). Vuoto: si controllano tutti i file.
#   NOREA_HEAD     commit da controllare. Predefinito: HEAD.
#   NOREA_ESCLUDI  percorsi da saltare, uno per riga, nel formato pathspec di git.
# Esce con 1 se trova caratteri vietati, con 0 altrimenti.
use strict;
use warnings;
use utf8;
use Encode ();

binmode STDOUT, ':encoding(UTF-8)';

# Stessa regola dell'hook del plugin norea: i blocchi delle emoji, il selettore che
# trasforma un simbolo in emoji e, dove Perl lo conosce, ogni carattere che si mostra come emoji.
my $vietato = eval 'qr/[\x{00B7}\x{2014}\x{FE0F}\x{1F000}-\x{1FAFF}\p{Emoji_Presentation}]/'
    || qr/[\x{00B7}\x{2014}\x{FE0F}\x{1F000}-\x{1FAFF}]/;

my $albero_vuoto = '4b825dc642cb6eb9a060e54bf8d69288fbee4904';
my $max_annotazioni = 50;

my $base = $ENV{NOREA_BASE} // '';
my $head = $ENV{NOREA_HEAD} || 'HEAD';
$base = '' if $base =~ /^0*$/;
if ($base ne '' && system('git', 'cat-file', '-e', "$base^{commit}") != 0) {
    print "Il commit di partenza $base non è nella storia: controllo tutti i file.\n";
    $base = '';
}

my @escludi = map { ":(exclude)$_" } grep { length } map { s/^\s+|\s+$//gr } split /\n/, ($ENV{NOREA_ESCLUDI} // '');
my @confronto = $base ne '' ? ("$base...$head") : ($albero_vuoto, $head);

open my $diff, '-|', 'git', '-c', 'core.quotePath=false', 'diff', '--no-color', '--no-ext-diff',
    '--unified=0', '--diff-filter=AMRC', @confronto, '--', '.', @escludi
    or die "git diff non riuscito: $!\n";

my ($file, $riga, $nell_intestazione) = (undef, 0, 0);
my @trovati;
while (my $linea = <$diff>) {
    chomp $linea;
    if ($linea =~ /^diff --git /) {
        ($file, $nell_intestazione) = (undef, 1);
        next;
    }
    if ($nell_intestazione) {
        if ($linea =~ m{^\+\+\+ (?:b/)?(.*)$}) {
            $file = Encode::decode('UTF-8', $1);
        }
        elsif ($linea =~ /^@@ -\d+(?:,\d+)? \+(\d+)/) {
            ($riga, $nell_intestazione) = ($1, 0);
        }
        next;
    }
    if ($linea =~ /^@@ -\d+(?:,\d+)? \+(\d+)/) {
        $riga = $1;
        next;
    }
    next unless defined $file && $linea =~ s/^\+//;
    my $testo = Encode::decode('UTF-8', $linea);
    while ($testo =~ /($vietato)/g) {
        push @trovati, [$file, $riga, ord $1];
    }
    $riga++;
}
close $diff or die "git diff non riuscito\n";

unless (@trovati) {
    print "Caratteri vietati: nessuno.\n";
    exit 0;
}

my %nome = (0x00B7 => 'punto mediano', 0x2014 => 'trattino lungo');
my $n = 0;
for my $t (@trovati) {
    my ($f, $r, $codice) = @$t;
    my $cosa = sprintf('U+%04X %s', $codice, $nome{$codice} // 'emoji');
    if ($n++ < $max_annotazioni) {
        print "::error file=$f,line=$r,title=Carattere vietato::$cosa\n";
    }
    print "$f:$r: $cosa\n";
}
print "\nTrovati ", scalar(@trovati), " caratteri vietati.\n",
    "Vietati ovunque: il punto mediano (U+00B7), il trattino lungo (U+2014) e le emoji.\n",
    "Usa il trattino normale, una virgola o i due punti al posto del trattino lungo, e togli le emoji.\n";
exit 1;
