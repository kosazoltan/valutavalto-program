# Dedup-felfedezés — a 287 "primer" valós egyedi tartalma (2026-05-22)

A `primary-worklist.csv` 287 fájljának tartalom-hash (MD5) elemzése:

- **160 EGYEDI** fájl (tartalom szerint)
- **127 pontos duplikátum** — a felmérés ugyanazokat a fájlokat több top-mappába is bemásolta (`Kósa Szervezés` / `Cégcsoport felmérése` / `Szervezés` / `Kósa Tervezés és fejlesztés` keresztben).

## Egyedi tartalom típus szerint (160)

| Típus | Egyedi db | Megjegyzés |
|---|---|---|
| jpeg + jpg + png | 94 | képernyőképek (sok már leírva a 27 specben) |
| docx | 40 | **zömében az interjúk + követelménylisták — ezek a 27 spec FORRÁSai** |
| xlsx | 14 | adat-/árfolyam-/címlet-táblázatok |
| m4a | **4** | a 8 hangfelvétel valójában 4 egyedi (helyi Whisper-átirat folyamatban) |
| csv/ods/odt/txt/zip | 8 | egyéb |

## Következmény a feldolgozási stratégiára

A "mindent egyenként MD-vé" hatóköre a valóságban **160 egyedi elem** (nem 287), és ezek nagy része:
- **docx interjúk/követelménylisták** → a b1–b10 spec-ek ezekből készültek, tehát új spec nagyrészt re-deriv-álás lenne; az ÉRDEMI munka: ellenőrizni, van-e bennük a 27 spec által NEM lefedett követelmény → csak arra új spec + gap.
- **képernyőképek** → UI-bizonyíték; sok a már leírt képernyő variánsa.
- **xlsx** → adattáblák (árfolyam/címlet) — ezekből konkrét adat-/funkció-gap jöhet.
- **4 hangfelvétel** → átirat után spec.

**Eljárás (no-busywork elv szerint):** a 160 egyedit végigvesszük, de spec CSAK ott készül, ahol a tartalom a 27 spechez / a programhoz képest ÚJ követelményt hordoz; a duplikátum/már-lefedett tartalmat a worklistben `COVERED`/`DUP` jelöléssel zárjuk. Így a "teljes feldolgozás" tényleges új-gap eredménnyel jár, nem 287 redundáns fájllal.
