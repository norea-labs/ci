#!/usr/bin/env perl
# Controllo Norea: nessuna skill, comando o agente di Claude dentro il repo. Stanno tutti nel
# plugin norea (repo norea-labs/claude-plugins), così il team ha le stesse e si aggiornano da sole.
# Guarda tutti i file del commit, a qualsiasi profondità, non solo quelli cambiati dalla PR.
#
# Variabili d'ambiente:
#   NOREA_HEAD                commit da controllare. Predefinito: HEAD.
#   NOREA_SKILL_DEL_PROGETTO  true nei repo dei progetti clienti: possono tenere le skill
#                             che servono solo a quel progetto, e il controllo non blocca.
# Esce con 1 se trova file in .claude/skills, .claude/commands o .claude/agents, con 0 altrimenti.
use strict;
use warnings;
use utf8;
use Encode ();

binmode STDOUT, ':encoding(UTF-8)';

if (($ENV{NOREA_SKILL_DEL_PROGETTO} // '') eq 'true') {
    print "Skill di Claude: repo di un progetto cliente, le skill del progetto sono ammesse.\n";
    exit 0;
}

my $head = $ENV{NOREA_HEAD} || 'HEAD';
my $vietato = qr{(?:^|/)\.claude/(?:skills|commands|agents)/};

open my $git, '-|', 'git', '-c', 'core.quotePath=false', 'ls-tree', '-r', '--name-only', $head
    or die "git ls-tree non riuscito: $!\n";
my @trovati = grep { $_ =~ $vietato } map { chomp; Encode::decode('UTF-8', $_) } <$git>;
close $git or die "git ls-tree non riuscito\n";

if (!@trovati) {
    print "Skill di Claude: nessuna dentro il repo, a posto.\n";
    exit 0;
}

for my $file (@trovati) {
    print "::error file=$file,title=Skill nel repo::le skill, i comandi e gli agenti di Claude stanno nel plugin norea (repo norea-labs/claude-plugins), non dentro un repo.\n";
    print "$file\n";
}
print "Trovati ", scalar @trovati, " file in .claude/skills, .claude/commands o .claude/agents. ",
    "Toglili da questo repo e aggiungili al plugin norea con una PR su norea-labs/claude-plugins. ",
    "Solo il repo di un progetto cliente può tenere le skill del suo progetto, con il topic \"cliente\" nelle impostazioni del repo su GitHub.\n";
exit 1;
