# ci

I controlli automatici di Norea Labs, scritti una volta sola e richiamati da ogni repo su ogni PR.

<!-- inizio parte fissa Norea -->
## Regole Norea

Questa parte è uguale in ogni repo di Norea Labs e non si modifica a mano: arriva dal repo modello.

- Le regole per l'AI sono nella skill `regole-norea` del plugin `norea`, attivo da `.claude/settings.json`.
- Testi, commit e PR in italiano. Vietati il punto mediano, il trattino lungo e le emoji.
- Prima si propone, poi si costruisce dopo l'ok.
- Il branch ha il nome dato da Linear. La PR si apre appena si inizia, con la chiave della issue nel titolo.
- Password, chiavi e segreti solo in 1Password.
- Ogni PR passa i controlli centrali di `norea-labs/ci`.
<!-- fine parte fissa Norea -->

## Questo repo

- `action.yml` e `script/`: i controlli. Gli script sono in Perl con solo moduli di base.
- `.github/workflows/controlli.yml`: il workflow riutilizzabile che gli altri repo richiamano.
- `modello/claude-parte-fissa.md`: la parte fissa del CLAUDE.md, l'unica copia di riferimento.
- Prima di aprire una PR: `test/prova.sh`.
