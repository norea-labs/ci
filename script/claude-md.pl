#!/usr/bin/env perl
# Controllo Norea sul CLAUDE.md alla radice del repo: deve esistere, stare sotto le 100 righe
# e contenere la parte fissa identica al modello, tra i due segnaposto.
#
# Uso: claude-md.pl <file con la parte fissa del modello>
# Esce con 1 se qualcosa non va, con 0 altrimenti.
use strict;
use warnings;
use utf8;

binmode STDOUT, ':encoding(UTF-8)';

my $max_righe = 100;
my $inizio = '<!-- inizio parte fissa Norea -->';
my $fine = '<!-- fine parte fissa Norea -->';

my $modello = shift or die "Uso: claude-md.pl <parte fissa del modello>\n";
my $file = 'CLAUDE.md';

sub leggi {
    my ($percorso) = @_;
    open my $fh, '<:encoding(UTF-8)', $percorso or return;
    local $/;
    my $testo = <$fh>;
    $testo =~ s/\r\n/\n/g;
    return $testo;
}

# La parte fissa: il testo tra il segnaposto di inizio e quello di fine,
# senza spazi in fondo alle righe e senza righe vuote ai bordi.
sub parte_fissa {
    my ($testo) = @_;
    return unless $testo =~ /^\Q$inizio\E[ \t]*\n(.*?)^\Q$fine\E[ \t]*$/ms;
    my $dentro = $1;
    $dentro =~ s/[ \t]+$//mg;
    $dentro =~ s/\A\n+|\n+\z//g;
    return $dentro;
}

sub errore {
    my ($riga, $messaggio) = @_;
    print "::error file=$file", (defined $riga ? ",line=$riga" : ''), ",title=CLAUDE.md::$messaggio\n";
    print "$file: $messaggio\n";
}

my $atteso = parte_fissa(leggi($modello) // die "Modello $modello non leggibile\n")
    // die "Il modello $modello non contiene i segnaposto della parte fissa\n";

my $testo = leggi($file);
unless (defined $testo) {
    errore(undef, 'manca il CLAUDE.md alla radice del repo. Copialo dal repo modello.');
    exit 1;
}

my $ok = 1;
my $righe = () = $testo =~ /\n/g;
$righe++ if length $testo && $testo !~ /\n\z/;
if ($righe >= $max_righe) {
    errore($max_righe, "ha $righe righe, il massimo è " . ($max_righe - 1)
        . '. Sposta i dettagli in altri file e lascia nel CLAUDE.md solo i rimandi.');
    $ok = 0;
}

my $trovato = parte_fissa($testo);
if (!defined $trovato) {
    errore(1, "manca la parte fissa: deve stare tra le righe \"$inizio\" e \"$fine\". Copiala dal repo modello.");
    $ok = 0;
}
elsif ($trovato ne $atteso) {
    my @a = split /\n/, $atteso, -1;
    my @t = split /\n/, $trovato, -1;
    my $i = 0;
    $i++ while $i < @a && $i < @t && $a[$i] eq $t[$i];
    my @linee = split /\n/, $testo;
    my ($riga_inizio) = grep { $linee[$_ - 1] =~ /^\Q$inizio\E/ } 1 .. @linee;
    my $riga = ($riga_inizio // 0) + 1 + $i;
    errore($riga, 'la parte fissa è diversa dal modello. Non va modificata a mano: copiala dal repo modello.');
    print "  atteso:  ", ($a[$i] // '(fine della parte fissa)'), "\n";
    print "  trovato: ", ($t[$i] // '(fine della parte fissa)'), "\n";
    $ok = 0;
}

print "CLAUDE.md: a posto.\n" if $ok;
exit($ok ? 0 : 1);
