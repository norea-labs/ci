# ci

I controlli automatici di Norea Labs, scritti una volta sola e richiamati da ogni repo su ogni PR.

<!-- inizio parte fissa Norea -->
## Regole Norea

Questa parte è uguale in ogni repo di Norea Labs e non si modifica a mano.

- Le regole per l'AI sono nel manuale (`ai/regole-per-tutte-le-ai-di-norea.md` in `norea-labs/knowledge-base`): il plugin `norea`, attivo da `.claude/settings.json`, le carica a ogni sessione.
- Ogni PR passa i controlli centrali di `norea-labs/ci`.
<!-- fine parte fissa Norea -->

## Questo repo

- `action.yml` e `script/`: i controlli. Gli script sono in Perl con solo moduli di base.
- `.github/workflows/controlli.yml`: il workflow riutilizzabile che gli altri repo richiamano.
- `modello/claude-parte-fissa.md`: la parte fissa del CLAUDE.md, l'unica copia di riferimento.
- Prima di aprire una PR: `test/prova.sh`.
