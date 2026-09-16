# Codex ja AGENTS.md

Käytämme `AGENTS.md`-tiedostoa yhteisten Codex-ohjeiden määrittelyyn. Tavoitteena on, että Codex noudattaa kaikissa projekteissamme samoja turvallisen kehittämisen periaatteita.

## Yhteinen AGENTS.md

Jokaisen repositoryn juuressa on versionhallintaan kuuluva:
```text
AGENTS.md
```

Se sisältää kaikille kehittäjille yhteiset Codex-ohjeet, kuten turvallisuuteen, API- ja verkkokutsuihin sekä koodin kieleen liittyvät periaatteet.
```text
repository/
├── AGENTS.md
├── .gitignore
├── src/
└── ...
```

Yhteistä `AGENTS.md`-tiedostoa ei tule muuttaa henkilökohtaisten asetusten vuoksi. Kaikkia kehittäjiä koskevat muutokset tehdään normaalisti versionhallinnan kautta.

## Kehittäjän omat paikalliset ohjeet

Kehittäjä voi täydentää yhteisiä ohjeita repositorykohtaisilla henkilökohtaisilla ohjeilla.

Luo repositoryn juureen:
```text
AGENTS.override.md
```

Rakenne on tällöin:
```text
repository/
├── AGENTS.md
├── AGENTS.override.md
├── .gitignore
├── src/
└── ...
```

`AGENTS.override.md` on kehittäjäkohtainen eikä sitä tallenneta versionhallintaan.

Lisää `.gitignore`-tiedostoon:
```gitignore
AGENTS.override.md
**/AGENTS.override.md
```

Paikallisen tiedoston voi tämän jälkeen luoda esimerkiksi:
```bash
touch AGENTS.override.md
```

## Mitä AGENTS.override.md-tiedostoon voi laittaa?

Override-tiedosto on tarkoitettu henkilökohtaisiin työskentelytapoihin ja Codexin käyttäytymistä koskeviin lisäohjeisiin.

Esimerkiksi:
```md
# Personal Codex instructions

- Explain larger changes before implementing them.
- Prefer small and focused changes.
- Show alternative implementations when there are meaningful trade-offs.
- Do not run tests or write documentation unless I request it.
```

Jos ohjeen pitäisi koskea kaikkia kehittäjiä, se kuuluu yhteiseen `AGENTS.md`-tiedostoon eikä henkilökohtaiseen override-tiedostoon.

Paikallisia ohjeita ei tule käyttää yhteisten turvallisuusperiaatteiden tarkoitukselliseen kiertämiseen.

## Pidä ohjeet lyhyinä

`AGENTS.md` ja `AGENTS.override.md` kannattaa pitää mahdollisimman lyhyinä ja tarkoituksenmukaisina.

Codex lukee soveltuvat ohjeet osaksi työskentelykontekstiaan, joten pitkät ohjetiedostot lisäävät tokenien kulutusta. Pitkä ja tarpeettoman yksityiskohtainen ohjeistus voi myös vaikeuttaa olennaisten ohjeiden erottamista.

Ohjeisiin kannattaa kirjoittaa ensisijaisesti asioita, joita Codex ei voi helposti päätellä lähdekoodista tai repositoryn muista tiedostoista.

Vältä erityisesti:

- saman asian toistamista
- yleisen ohjelmointitiedon kirjoittamista
- projektidokumentaation kopioimista `AGENTS.md`
- tarpeettoman yksityiskohtaisia ohjeita

## Lyhyesti

Yhteiset ohjeet:
```text
AGENTS.md
```

- kuuluu versionhallintaan
- sama yhteinen pohja jokaisessa repositoryssa
- sisältää yhteiset turvallisuus- ja toimintaperiaatteet

Kehittäjän omat lisäohjeet:
```text
AGENTS.override.md
```

- vain kehittäjän omalla koneella
- ei versionhallintaan
- sisältää henkilökohtaiset työskentelytavat ja lisäohjeet

**Nyrkkisääntö:** jos ohje koskee kaikkia, muuta `AGENTS.md`ä. Jos ohje koskee vain omaa työskentelyäsi, lisää se `AGENTS.override.md`.
