#!/usr/bin/env bash
# Prova degli script su repo git temporanei. I caratteri vietati sono scritti con printf,
# così questo file non li contiene.
set -u

radice=$(cd "$(dirname "$0")/.." && pwd)
caratteri="$radice/script/caratteri-vietati.pl"
claude_md="$radice/script/claude-md.pl"
modello="$radice/modello/claude-parte-fissa.md"
skill="$radice/script/skill-nel-plugin.pl"
lungo=$(printf '\xe2\x80\x94')
mediano=$(printf '\xc2\xb7')
emoji=$(printf '\xf0\x9f\x98\x80')
falliti=0

atteso() {
    local nome=$1 codice=$2
    shift 2
    local uscita
    uscita=$("$@" 2>&1)
    local ottenuto=$?
    if [ "$ottenuto" -eq "$codice" ]; then
        echo "ok    $nome"
    else
        echo "FALLITO $nome: atteso $codice, ottenuto $ottenuto"
        echo "$uscita" | sed 's/^/      /'
        falliti=$((falliti + 1))
    fi
}

nuovo_repo() {
    cd "$(mktemp -d)" || exit 1
    git init -q
    git config user.email prova@norea.it
    git config user.name prova
    printf 'riga vecchia %s\n' "$lungo" > vecchio.txt
    cp "$modello" CLAUDE.md
    git add . && git commit -qm base
    base=$(git rev-parse HEAD)
}

cambia() {
    git add -A && git commit -qm cambio
}

# Caratteri vietati
nuovo_repo
echo 'testo pulito' > nuovo.txt; cambia
atteso 'riga pulita passa' 0 env NOREA_BASE="$base" perl "$caratteri"
atteso 'riga vecchia non toccata non conta' 0 env NOREA_BASE="$base" perl "$caratteri"

nuovo_repo
printf 'uno\ndue %s\n' "$lungo" > nuovo.txt; cambia
atteso 'trattino lungo blocca' 1 env NOREA_BASE="$base" perl "$caratteri"
uscita=$(NOREA_BASE="$base" perl "$caratteri")
atteso 'riga indicata giusta' 0 grep -q '^::error file=nuovo.txt,line=2,' <<<"$uscita"

nuovo_repo
printf 'a %s b\n' "$mediano" > nuovo.txt; cambia
atteso 'punto mediano blocca' 1 env NOREA_BASE="$base" perl "$caratteri"

nuovo_repo
printf 'ciao %s\n' "$emoji" > nuovo.txt; cambia
atteso 'emoji blocca' 1 env NOREA_BASE="$base" perl "$caratteri"

nuovo_repo
printf '++ %s\n' "$lungo" > nuovo.txt; cambia
atteso 'riga che inizia con ++ controllata' 1 env NOREA_BASE="$base" perl "$caratteri"

nuovo_repo
mkdir -p esterno; printf 'x %s\n' "$lungo" > esterno/libreria.txt; cambia
atteso 'percorso escluso saltato' 0 env NOREA_BASE="$base" NOREA_ESCLUDI="esterno/" perl "$caratteri"

nuovo_repo
atteso 'senza base controlla tutti i file' 1 env NOREA_BASE= perl "$caratteri"
atteso 'base a zero come senza base' 1 env NOREA_BASE=0000000000000000000000000000000000000000 perl "$caratteri"

# CLAUDE.md
nuovo_repo
atteso 'CLAUDE.md uguale al modello passa' 0 perl "$claude_md" "$modello"
{ echo '# Progetto'; echo; cat "$modello"; echo; echo 'Parte del progetto.'; } > CLAUDE.md
atteso 'parte del progetto intorno passa' 0 perl "$claude_md" "$modello"
sed -i '/inizio parte fissa Norea/a riga aggiunta a mano' CLAUDE.md
atteso 'parte fissa cambiata blocca' 1 perl "$claude_md" "$modello"
cp "$modello" CLAUDE.md
grep -v 'fine parte fissa' "$modello" > CLAUDE.md
atteso 'segnaposto mancante blocca' 1 perl "$claude_md" "$modello"
cp "$modello" CLAUDE.md
while [ "$(wc -l < CLAUDE.md)" -lt 99 ]; do echo 'riga' >> CLAUDE.md; done
atteso '99 righe passano' 0 perl "$claude_md" "$modello"
echo 'riga' >> CLAUDE.md
atteso '100 righe bloccano' 1 perl "$claude_md" "$modello"
rm CLAUDE.md
atteso 'CLAUDE.md mancante blocca' 1 perl "$claude_md" "$modello"

# Skill nel plugin
nuovo_repo
mkdir -p .claude; echo '{}' > .claude/settings.json; cambia
atteso 'repo senza skill passa' 0 perl "$skill"
mkdir -p .claude/skills/copy; echo 'skill' > .claude/skills/copy/SKILL.md; cambia
atteso 'skill nel repo blocca' 1 perl "$skill"
uscita=$(perl "$skill")
atteso 'file indicato giusto' 0 grep -q '^::error file=.claude/skills/copy/SKILL.md,' <<<"$uscita"
git rm -rq .claude/skills; cambia
atteso 'skill tolta passa' 0 perl "$skill"
mkdir -p sito/.claude/commands; echo 'comando' > sito/.claude/commands/prova.md; cambia
atteso 'comando in una sottocartella blocca' 1 perl "$skill"
git rm -rq sito; mkdir -p .claude/agents; echo 'agente' > .claude/agents/revisore.md; cambia
atteso 'agente nel repo blocca' 1 perl "$skill"
git rm -rq .claude/agents; mkdir -p plugins/norea/skills/copy; echo 'skill' > plugins/norea/skills/copy/SKILL.md; cambia
atteso 'skill di un plugin fuori da .claude passa' 0 perl "$skill"

if [ "$falliti" -gt 0 ]; then
    echo "$falliti prove fallite."
    exit 1
fi
echo 'Tutte le prove passate.'
