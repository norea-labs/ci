# ci

I controlli automatici di Norea Labs, scritti una volta sola. Ogni repo li richiama su ogni PR e, se un controllo fallisce, la PR resta rossa.

## Cosa controlla

- **Caratteri vietati**: il punto mediano (U+00B7), il trattino lungo (U+2014) e le emoji nelle righe che la PR aggiunge o cambia, in qualsiasi file e da chiunque siano state scritte. Le righe che la PR non tocca non contano, così un repo già esistente può adottare i controlli senza ripulire tutto prima. Titolo, descrizione e commit della PR non vengono controllati.
- **CLAUDE.md**: deve esistere alla radice del repo, avere meno di 100 righe e contenere la parte fissa identica a `modello/claude-parte-fissa.md`, tra le righe `<!-- inizio parte fissa Norea -->` e `<!-- fine parte fissa Norea -->`. Il resto del file è libero.

Non c'è un controllo sui colori: molti lavori sono per clienti con una palette propria.

## Usarlo in un repo

Crea `.github/workflows/norea.yml`:

```yaml
name: Norea

on:
  pull_request:

jobs:
  controlli:
    uses: norea-labs/ci/.github/workflows/controlli.yml@main
```

I repo creati dal repo modello hanno già questo file. Il riferimento è `@main`: ogni modifica ai controlli vale subito per tutti i repo.

Per saltare file che non scriviamo noi, per esempio librerie copiate dentro il repo, passa i percorsi a `escludi`, uno per riga:

```yaml
    uses: norea-labs/ci/.github/workflows/controlli.yml@main
    with:
      escludi: |
        vendor/
        public/font/
```

## Impostazione del repo

Il repo è pubblico, così ogni repo dell'organizzazione può usarlo senza altre impostazioni. Dentro non c'è nulla di riservato. Se un giorno diventa privato, bisogna permettere l'accesso agli altri repo: Settings, Actions, General, Access, "Accessible from repositories in the 'norea-labs' organization".

## Provare in locale

```sh
test/prova.sh
```

Serve solo Perl, già presente su macOS e Linux.
