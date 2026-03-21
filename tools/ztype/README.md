# ZType

Windows diktáló: **OpenAI Whisper API**, **csak magyar** (`language=hu`), **NumPad +** váltógomb → szöveg **Ctrl+V**-vel a fókuszban lévő mezőbe.

## API kulcs (biztonságos)

- **Ne írd be a kulcsot chatbe.**
- **Első indításkor** a program **maszkolt** (`***`) mezőt nyit — ott add meg a kulcsot.
- Mentés: **Windows Credential Manager** (`keyring`), nem sima szövegként a repóban.
- Haladó: `OPENAI_API_KEY` környezeti változó (felülírja a tárolt kulcsot).
- Tálca: **OpenAI kulcs megváltoztatása…** — új maszkolt ablak; mentés után **azonnal** érvényes (kivéve, ha `OPENAI_API_KEY` env felülír — akkor csak env-t töröld / indíts újra env nélkül).

## Egykattintásos telepítő

1. Telepíts **Python 3.10+**-ot ([python.org](https://www.python.org/downloads/)), pip-pel, és legyen a PATH-on / `py` launcher.
2. Dupla klikk: **`Install-ZType.cmd`** (ugyanabban a mappában, mint `install.ps1`).

A telepítő:

- másol **`%LOCALAPPDATA%\ZType`**
- létrehoz **venv**-et, **`pip install -r requirements.txt`**
- **Start menü → ZType → ZType** parancsikon
- **Startup** mappába parancsikon (**automatikus indulás**, mint WhisperTyping)

Első futtatás: **maszkolt API kulcs** ablak.

**Hibakeresés:** Start menü → **ZType (hibakeresés)** (konzolos), vagy `%LOCALAPPDATA%\ZType\ZType-debug.cmd`.

### Nem látszik a feladatkezelőben „ZType”?

A folyamat neve **nem** „ZType”, hanem tipikusan **Python** vagy **pythonw.exe** (háttér). Keresd ezeket, vagy a **Részletek** nézetben a parancssort (`ztype.py`).

Ha **egyáltalán nincs Python folyamat**: valószínűleg **azonnal kilép** (hiba). Ilyenkor:

1. **ZType (hibakeresés)** — látod a hibát a konzolon.  
2. **`ztype-crash.log`** — `%LOCALAPPDATA%\ZType\ztype-crash.log` (indulási hibánál felugró ablak is jelezheti).  
3. Futtasd újra **`Install-ZType.cmd`**, hogy minden fájl (`win_vk_hotkey.py` stb.) meglegyen.

## Kézi fejlesztői futtatás

```powershell
cd tools\ztype
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python ztype.py
```

## Napló

- `%LOCALAPPDATA%\ZType\ztype.log` — normál működés  
- `%LOCALAPPDATA%\ZType\ztype-crash.log` — váratlan összeomlás / indulási hiba

## Hotkey

Alap: **NumPad +** — Windows alatt **Win32 `RegisterHotKey` (VK_ADD)**: a `+` **nem** íródik a szövegmezőbe (ellentétben a `keyboard` csomag gyakori `numpad +` hibájával).

Másik billentyű (csak `keyboard` csomag):

```powershell
$env:ZTYPE_HOTKEY = "insert"
python ztype.py
```

Win32 NumPad + kikapcsolása (pl. ha más app foglalja a VK_ADD-ot):

```powershell
$env:ZTYPE_HOTKEY_WIN32 = "0"
python ztype.py
```

## Eltávolítás

1. Töröld a parancsikonokat: Start menü **ZType**, Startup **ZType**.
2. Töröld a mappát: `%LOCALAPPDATA%\ZType`
3. Windows **Credential Manager** → Windows hitelesítő adatok → keresés: **ZType** → eltávolítás (API kulcs).

## OpenAI költség

Whisper API díj az OpenAI aktuális árlistája szerint.
