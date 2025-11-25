unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, DateUtils, DB, DBTables,StrUtils,
  IBDatabase, IBCustomDataSet, IBTable, IBQuery, Buttons, Grids, Calendar,
  Wininet;

type
    TMakePack = class(TForm)

    EvHonapPanel : TPanel;
    Panel3       : TPanel;
    Panel4       : TPanel;
    UzenoPanel   : TPanel;

    Shape3       : TShape;
    Shape4       : TShape;
    Shape5       : TShape;

    Naptar       : TCalendar;

    CsomagoloGomb: TBitBtn;
    ElohoGomb    : TBitBtn;
    KovhoGomb    : TBitBtn;
    MegsemZarGomb: TBitBtn;
    Takaro       : TPanel;
    datumpanel   : TPanel;
    Memo1        : TMemo;
    AlsoTakaro   : TPanel;
    Shape1       : TShape;
    Panel1       : TPanel;
    CSUSZKA      : TPanel;

    MATRICAQUERY : TIBQuery;
    MATRICATABLA : TIBTable;
    MATRICADBASE : TIBDatabase;
    MATRICATRANZ : TIBTransaction;

    VALUTATABLA  : TIBTable;
    VALUTADBASE  : TIBDatabase;
    VALUTATRANZ  : TIBTransaction;
    VALUTAQUERY  : TIBQuery;

    VALDATATABLA : TIBTable;
    VALDATAQUERY : TIBQuery;
    VALDATADBASE : TIBDatabase;
    VALDATATRANZ : TIBTransaction;

    procedure CsomagoloGombClick(Sender: TObject);
    procedure BFPack;
    procedure BTPack;
    procedure CimtPack;
    procedure NarfPack;
    procedure WafaPack;
    procedure WuniPack;
    procedure TescPack;
    procedure ArfePack;
    Procedure KezdPack;
    procedure XkezPack;
    procedure WzarPack;
    procedure Tulajbedolgozas;

    procedure EfejPack;
    procedure EtetPack;
    procedure TradePack;
    procedure FoglaloPack;
    procedure ElohoGombClick(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);
    procedure FormActivate(Sender: TObject);
    procedure HonapDisplay;
    procedure KovhoGombClick(Sender: TObject);
    procedure MatricaKodolas;
    procedure Ugyfelpack;
    procedure UTombBeir(_usz: integer);

    procedure MegsemZarGombClick(Sender: TObject);
    procedure PutByte(_byte: byte);
    procedure Putword(_word: word);
    procedure PutInteger(_int: integer);
    procedure Putstring(_string: string);
    procedure Putchar(_char: string);
    procedure TulajPack;
    procedure TulajPackSorbeiras;
    procedure UgyfAndJogiPack;
    procedure UgyfelMegjeloles;

    procedure AllDirDelete(_adir: string);
    procedure JelentesBekuldese;

    procedure Csuszkalas;

    function FileKuldes: integer;
    function IrodaKod(_irodaSzam: word): string;
    function Kitkod(_kdatum: string):string;
    function Nulele(_int: byte): string;
    function ZArasBekuldese: boolean;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MAKEPACK: TMAKEPACK;

  _honapnev: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS',
                    'MÁJUS','JÚNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER',
                    'OKTÓBER','NOVEMBER','DECEMBER');

  _napnev: array[1..7] of string = ('HÉTFÕ','KEDD','SZERDA','CSÜTÖRTÖK',
                        'PÉNTEK','SZOMBAT','VASÁRNAP');


  _biniras : file of byte;
  _upLoaded: boolean;

  _mezoss  : array[1..29] of byte;

  _ugyrow,_jogrow: array[1..100] of integer;
  _udb,_jdb: word;

  _valutaPath  : string = 'c:\valuta\database\valuta.fdb';
  _valdataPath : string = 'c:\valuta\database\valdata.fdb';
  _matricaPath : string = 'c:\valuta\database\trade.fdb';

  _host       : string;
  _ftpPort    : integer = 21100;
  _userId     : string  = 'ebc-10%';
  _ftpPassword: string  = 'klc+45%';

  _tarspt: array[1..50] of string;
  _addjel: array[1..50] of byte;
  _forint: array[1..50] of integer;

  _kellforgalom,_kellmetroafa,_kelltescoAfa,_storno,_foe,_cikkszam,_okmindex: byte;
  _kellwestern,_kellmatrica,_ertektarszam,_tablasorszam,_tetel,_kulfoldi: byte;
  _ptarszam,_y,_mozgas,_mezodarab,_fizeszkoz,_konverzio,_kozszerep: byte;
  _tKozszerep: byte;

  _width,_height,_targyev,_targyhonap,_targynap,_kartya,_pp,_ugyfelszam: word;
  _mbszam,_tss,_zz: word;

  _pcs,_megnyitottnap,_evhos,_ptkods,_zarodstring,_farok,_nev,_elozonev: string;
  _kit,_fileAlap,_csomagFile,_markerFile,_markerPath,_csomagPath,_anyjaneve: string;
  _ido,_bizonylat,_tipus,_ugyftip,_ugyfnev,_prosnev,_idkod,_penztar: string;
  _sorszam,_szlaszam,_tranztip,_zPenztar,_tpt,_emailcim,_szulhely,_szulido: string;
  _tablanev,_datum,_valnem,_stbiz,_ugyfelcim,_adoszam,_referid,_tranzakcio: string;
  _localpath,_remotefile,_tortresz,_remotedir,_szolgaltato,_szolgaltatas: string;
  _rendszam,_kategoria,_startdatum,_enddatum,_telefonszam,_ugyftipus: string;
  _allampolgar,_lakcim,_okmtipus,_azonosito,_tarthely,_lcimcard,_leanykori: string;
  _irszam,_varos,_utca,_iso,_telephely,_fotevek,_kepvisnev,_mbbeo: string;
  _kepvisbeo,_orszag,_okirat,_dString,_plombaszam,_bizonylatszam: string;
  _ugyfelnev,_tulajnev,_erdjelleg,_erdmertek,_jogiszemnev,_jogiszemcim: string;

  _tulkozszer: array[1..255] of byte;
  _ufnev,_plbszam,_bizszam,_ufcim,_tulnev,_tulelonev,tullakcim: array[1..255] of string;
  _tullakcim,_tulszulhely,_tulszulido,_tulallamp,_tultarthely: array[1..255] of string;
  _tulerdjelleg,_tulerdmert,_joginev,_jogicim: array[1..255] of string;

  _csPos,_code,_ptszam,_tabladarab,_sPointer,_mresult,_recno,_aktspointer: integer;
  _bankjegy,_osszes,_rekordszam,_rekordDarab,_ugyfszam,_kezdij: integer;
  _arfolyam,_elszamarf,_forintertek,_varfoly,_earfoly,_nyito,_zaro: integer;
  _brutto,_afa,_kifizetve,_ellatmany,_zOsszeg,_zarokeszlet,_kerekites: integer;
  _matrica,_telefon,_atadas,_atvetel,_vodafon,_telenor,_paysafecard: integer;
  _fizetendo,_megbizott,_aktugyfelszam,_feladva: integer;

  _bytetomb: array[1..131072] of byte;
  _zByte: byte = 255;
  _sorveg: string = chr(13)+chr(10);

Function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll' name 'logirorutin';
function copyfiletoftprutin: integer; stdcall; external 'c:\valuta\bin\copy2ftp.dll' name 'copyfiletoftprutin';
function estizaraskuldes: integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
                function estizaraskuldes: integer; stdcall;
// =============================================================================

begin
  makepack := TMakePack.Create(Nil);
  result := MakePack.ShowModal;
  MakePack.Free;
end;

// =============================================================================
            procedure TMAKEPACK.FormActivate(Sender: TObject);
// =============================================================================

begin
  _width := Screen.Monitors[0].Width;
  _height:= Screen.Monitors[0].Height;

  Top := trunc((_height-353)/2);
  Left:= trunc((_width-450)/2);

  Takaro.Visible     := false;
  AlsoTakaro.Visible := False;
  UzenoPanel.Visible := false;

  // ---------------------------------------------------------------------------
  // Beolvassa: penztárszám, kellmatrica, megnyitottnap

  ValutaDbase.Connected := true;

  _pcs := 'SELECT * FROM PENZTAR';
  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      _ptkods := trim(FieldByName('PENZTARKOD').asString);

      Close;
      Sql.Clear;
      Sql.Add('SELECT * FROM HARDWARE');
      Open;

      _host          := trim(FieldByNAme('HOST').asstring);
      _kellforgalom  := FieldByName('KELLFORGALOM').asInteger;
      _kellMetroAfa  := FieldByName('KELLMETROAFA').asInteger;
      _kellTescoAfa  := FieldByName('KELLTESCOAFA').asInteger;
      _kellwestern   := FieldByName('KELLWESTERN').asInteger;
      _kellmatrica   := FieldByNAme('KELLMATRICA').asInteger;
      _megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').asstring);
      _ertektarszam  := FieldByName('ERTEKTAR').asInteger;
      Close;
    end;

  ValutaDbase.close;

  // Default dátum adatok meghatározása:

  _targyev    := strtoint(leftstr(_megnyitottNap,4));
  _targyhonap := strtoint(midstr(_megnyitottNap,6,2));
  _targynap   := strtoint(midstr(_megnyitottnap,9,2));

  // Beállítja a default dátumot a naptáron

  Naptar.Year  := _targyEv;
  Naptar.Month := _targyHonap;
  Naptar.Day   := _targyNap;

  _evhos := inttostr(_targyev)+ ' '+ _honapnev[_targyHonap];

  EvHonapPanel.Caption := _evhos;
  EvhonapPanel.Caption;

  // Ha a dátum oké. akkor megnyomja a csomagoló gombot:

  ActiveControl := CsomagoloGomb;
end;

// =============================================================================
              procedure TMAKEPACK.ELOHOGOMBClick(Sender: TObject);
// =============================================================================

// A naptárban az elözö hó billentyüt nyomta:

begin
  Naptar.PrevMonth;
  HonapDisplay;
end;

// =============================================================================
             procedure TMAKEPACK.KOVHOGOMBClick(Sender: TObject);
// =============================================================================

// A naptárban a következö hó billentyüt nyomta meg:

begin
  Naptar.NextMonth;
  HonapDisplay;
end;


// =============================================================================
                   procedure TMAKEPACK.HonapDisplay;
// =============================================================================

//  A naptár hónapváltoztása után kijelzi a kért hónapot:

begin
  _udb        := 0;
  _targyHonap := Naptar.Month;
  _targyev    := Naptar.year;
  _evhos      := inttostr(_targyev) + ' ' + _honapnev[_targyhonap];

  EvhonapPanel.caption := _evhos;
  EvhonapPanel.repaint;
end;


// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
          procedure TMAKEPACK.CsomagoloGombClick(Sender: TObject);
// =============================================================================

var _targydatum: TDateTime;
    _hetnap    : byte;

begin
   _targyEv   := Naptar.Year;
   _targyHonap:= Naptar.Month;
   _targynap  := Naptar.Day;
   _targydatum:= Naptar.CalendarDate;
   _hetnap    := DayoftheWeek(_targydatum);

   _dstring := inttostr(_targyev)+ ' '+_honapnev[_targyhonap]+' ';
   _dstring := _dstring +inttostr(_targynap)+ ' ' + _napnev[_hetnap];

   DatumPanel.Caption := _dString;
   Datumpanel.Repaint;
   Memo1.Lines.clear;

   logirorutin(pchar('Esti zaras bekuldeset szeretne: '+_dstring));

   with Takaro do
     begin
        Top := 48;
       Left := 16;
       Visible := true;
       Repaint;
     end;

   _csPos := -100;
   Csuszka.Left := _csPos;
   with AlsoTakaro do
     begin
       Top := 292;
       Left := 16;
       Visible := True;
       Repaint;
     end;

   (* A zárás dátuma és irodaszám alapján kialakitja a csomagfile nevét *)

  _zaroDString := IntToStr(_targyEv)+'.'+nulele(_targyHonap)+'.'+nulele(_targyNap);
  if _zarodstring>_megnyitottnap then
    begin
      logirorutin(pchar('Ervenytelen datum !'));
      ShowMessage('A megjelölt nap a jövõben lesz !');
      ModalResult := 2;
      Exit;
    end;

  _farok := midstr(_zarodstring,3,2)+midstr(_zarodstring,6,2);

  // Ez a pénztár száma:

  val(_ptkods,_ptszam,_code);

  if _code<>0 then _ptszam := 0;
  if _ptszam=0 then
    begin
      Showmessage('ÉRVÉNYTELEN A PÉNZTÁRSZÁM');
      Modalresult := 2;
      exit;
    end;

  // ---------------------------------------------------------------------------
  // Meghatározza a csomag kódolt nevét és path-ját

  _fileAlap   := Irodakod(_PtSzam);       // irodaszámból 8 tagu betüstring
  _kit        := KitKod(_zaroDString);    // a dátumból a kiterjesztés

  _csomagFile := _fileAlap + '.' + _kit;
  _markerFile := _fileAlap + '.m';

  _markerPath := 'C:\VALUTA\out\' + _markerFile;
  _csomagPath := 'C:\valuta\out\' + _csomagFile;

  // ---------------------------------------------------------------------------

  (* A tárgyév és tárgyhónap alapján meghatározza a gyüjtõ adatbázisok farkát *)

  _farok := nulele(_targyev-2000)+nulele(_targyhonap);

  // ------------------- itt lehet kezdeni irni a csomagot ---------------------

  // HA van adat és/vagy marker file, akkor az(oka)t törli:
  // Kiüriti az adott directoryt:

  AllDirDelete('c:\valuta\out');

  // Bytetombbe irja a csomagot:

  // A csomagjel = 'NQ'

  _bytetomb[1] := 78;  // N
  _bytetomb[2] := 88;  // X - jelzi a verziótipust !!!!

  // A tabladarabot átlépi

  _tabladarab := 0;
  _spointer   := 3;   // Tábladarab kimarad

  if _kellforgalom=1 then
    begin
      CimtPack;
      BfPack;
      BtPack;
      NarfPack;
      ArfePack;
      KezdPack;
      XkezPAck;
      TulajBedolgozas;
    end;

  if _kellMetroAfa=1 then WafaPack;
  if _kellTescoAfa=1 then TescPack;
  if _kellwestern=1  then WuniPack;

  if (_kellmetroAfa=1) or (_kelltescoAfa=1) or (_kellwestern=1) then WzarPAck;
  if (_kellMatrica=1) then MatricaKodolas;

  FoglaloPack;

//  if _kellForgalom=1 then UgyfAndJogiPack;

  //  A teljes csomagot lezárjuk 255-nel:

  putbyte(_zByte);

  // Beirjuk a feltöltött táblák darabszámát:

  _bytetomb[3] := _tabladarab;

  logirorutin(pchar('Osszesen '+inttostr(_tabladarab)+' táblát csomagolt be'));

  if _udb>0 then Ugyfelmegjeloles;

  // ---------------------------------------------------------------------------

  // Most felirjuk a csomagfile-t vagyis spointer db byte-ot a bytetomb-böl:

  AssignFile(_biniras,_CsomagPath);
  Rewrite(_biniras);

  Blockwrite(_biniras,_bytetomb,_spointer);
  CloseFile(_biniras);

  //  Végül felirjuk a merket-filet is:

  AssignFile(_biniras,_markerPath);
  Rewrite(_biniras);
  BlockWrite(_biniras,_zbyte,1);
  CloseFile(_biniras);

  Memo1.Lines.add(' ...');
  Memo1.Lines.Add('Az esti csomag küldésre elõkészítve');

  if _zaroDstring=_megnyitottnap then
    begin
      _pcs := 'UPDATE HARDWARE SET LEZARTNAP='+chr(39)+_zarodstring+chr(39);
      valutaparancs(_pcs);
    end;

  _mResult := 2;
  if ZarasBekuldese then _mResult := 1;
  Modalresult := _mresult;
end;


// =============================================================================
            procedure TMAKEPACK.MEGSEMZARGOMBClick(Sender: TObject);
// =============================================================================

// Meggondolta magát - mégsem akar zárni:

begin
  Modalresult := 2;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// ======================= KÓDOLÁSOK ===========================================

// =============================================================================
          function TMAKEPACK.IrodaKod(_irodaSzam: word): string;
// =============================================================================

var _szams: string;
    _betu,_plusz,i,_szor,_egy,_tiz,_b1,_b2: byte;
    _kodb: real;
    _ss: array[1..4] of string;

begin

  _szams := rightStr('000'+intToStr(_irodaSzam),4);

  for i := 1 to 4 do
    begin
      _betu  := ord(_szams[i])-48;
      _plusz := (i+1);
      _szor  := 10 - i;
      _kodb  := (_betu + _plusz)*_szor;
      _tiz   := trunc(_kodb/10);
      _egy   := trunc(_kodb) - (10*_tiz);
      _b1    := 64 + _tiz;
      _b2    := 72 + (2*_egy);
      _ss[i] := chr(_b1) + chr(_b2);
    end;

  result := _ss[3] + _ss[1] + _ss[4] + _ss[2];
end;

// =============================================================================
                function TMAKEPACK.Kitkod(_kdatum: string):string;
// =============================================================================

var _hos,_naps,_evs: string;
    _ev,_honap,_nap: word;


begin
   result := '000';
   if _kdatum='' then exit;

   _evs := leftstr(_kdatum,4);
   _hos := midstr(_kdatum,6,2);
   _naps:= midstr(_kdatum,9,2);

   val(_evs,_ev,_code);
   val(_hos,_honap,_code);
   val(_naps,_nap,_code);

   if _ev>2026 then _ev := _ev-26;

   if (_ev<2000) then exit;

   _ev := _ev - 2000;
   _hos := chr(64+trunc(2*_honap));

   if _nap<10 then _naps := chr(48+_nap)
   else _naps := chr(55+_nap);

   _evs := chr(64+_ev);
   result := _naps + _evs + _hos;
end;


// =============================================================================
              function TMAKEPACK.Nulele(_int: byte): string;
// =============================================================================

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;

// =============================================================================
               procedure TMAKEPACK.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  ValutaDbase.connected := true;
  if ValutaTranz.InTransaction then ValutaTranz.Commit;
  ValutaTranz.StartTransaction;

  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_ukaz);
      ExecSql;
    end;
  ValutaTranz.commit;
  Valutadbase.close;
end;


//§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
// =============================================================================
                procedure TMakePack.PutByte(_byte: byte);
// =============================================================================

begin
  inc(_spointer);
  _byteTomb[_sPointer] := _byte;
end;


// =============================================================================
                  procedure TMakePack.PutWord(_word: word);
// =============================================================================

var _hi,_lo: byte;

begin
  _hi := trunc(_word/256);
  _lo := _word - trunc(256*_hi);
  Putbyte(_lo);
  Putbyte(_hi);
end;

// =============================================================================
                  procedure TMakePack.PutInteger(_int: integer);
// =============================================================================

var _lo,_hi,_hlo,_hhi: byte;
    _maradt: integer;
    _elojel: string;

begin
  _elojel := '+';
  if _int<0 then
    begin
      _elojel:='-';
      _int := Abs(_int);
    end;

  _hhi := trunc(_int/16777216);
  _maradt := _int - trunc(16777216*_hhi);
  _hlo := trunc(_maradt/65536);
  _maradt := _maradt - trunc(65536*_hlo);
  _hi := trunc(_maradt/256);
  _lo := _maradt-trunc(256*_hi);
  if _elojel='-' then _hhi := 128+_hhi;

  Putbyte(_lo);
  Putbyte(_hi);
  Putbyte(_hlo);
  Putbyte(_hhi);
end;

// =============================================================================
                 procedure TmakePack.Putstring(_string: string);
// =============================================================================

var _slen,_byte: byte;

begin
  _slen := length(_string);
  if _slen=0 then
    begin
      Putbyte(0);
      exit;
    end;

  Putbyte(_slen);

  _y := 1;
  while _y<=_slen do
    begin
      _byte := _zByte - ord(_string[_y]);
      Putbyte(_byte);
      inc(_y);
    end;
end;

// =============================================================================
                    procedure TMakepack.Putchar(_char: string);
// =============================================================================

var _byte: byte;

begin
  if _char='' then _byte := 0
  else _byte := ord(_char[1]);
  Putbyte(_byte);
end;

// =============================================================================
          procedure TmakePack.AllDirDelete(_adir: string);
// =============================================================================


var  _minta,_delnev,_delpath: string;
     _srec: TSearchrec;

begin
  _minta := _adir + '\*.*';
  if FindFirst(_minta,faAnyfile,_srec) = 0 then
    begin
      repeat
        _delnev := _srec.Name;
        _delpath := _adir + '\' + _delnev;
        Sysutils.DeleteFile(_delpath);
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;
end;

// =============================================================================
                function TmakePAck.ZArasBekuldese: boolean;
// =============================================================================

var _recount: integer;

begin

  Memo1.Lines.add('Az esti zárás beküldésének kisérlete ...');

  result    := False;
  _uploaded := False;

  _remotedir  := 'IN'; //'IN';
  _localpath  := 'OUT\'+_csomagFile;
  _Remotefile := _csomagFile;

  logirorutin(pchar('Beküldi: ' + 'c:\valuta\' + _localpath));

  if FileKuldes<>1 then exit;

  _remotedir := 'IN';
  _localpath  := 'OUT\'+_markerfile;
  _Remotefile := _markerFile;

  logirorutin(pchar('Beküldi: ' + 'c:\valuta\' + _localpath));

   if FileKuldes=1 then
      begin
        _uploaded := True;
        result := True;
      end else exit;

  logirorutin(pchar('A zárás sikeresen belüldve'));
  Memo1.Lines.Add('Az esti zárást beküldtem');

  JelentesBekuldese;

  Memo1.Lines.Add('Várok a visszaigazolásra');
  _recount := 2;

  while _recount>0 do
    begin
      Csuszkalas;
      sleep(1000);
      dec(_recount);
    end;
end;


// =============================================================================
                         procedure TMakePack.Csuszkalas;
// =============================================================================

var _cc: byte;

begin
  _cc := 5;
  while _cc>0 do
    begin
      _csPos := -100;
      while _cspos<420 do
        begin
          Csuszka.left := _csPos;
          sleep(130);
          _cspos := _csPos + 100;
        end;
      dec(_cc);
    end;
end;

// =============================================================================
                  procedure Tmakepack.JelentesBekuldese;
// =============================================================================

var _tizes,_egyes: byte;
    _pts,_dats: string;

begin

  _tizes := trunc(_ptszam/10);
  _egyes := _ptszam-trunc(10*_tizes);

  if _tizes>9 then _tizes := _tizes + 7;

  _pts := chr(_tizes+48)+chr(_egyes+48);
  _dats := midstr(_zaroDstring,3,2)+midstr(_zarodstring,6,2)+midstr(_zarodstring,9,2);

  _remotedir  := 'JELENTES';
  _remoteFile := _pts + _dats + '.' + inttostr(_ertektarszam);
  _localPath  := 'jelentes\' + _remoteFile;

  if fileExists('c:\valuta\' +_localPath) then
    begin
      Memo1.lines.Add('Napi jelentés beküldése ...');
      if FileKuldes=1 then
        begin
          Memo1.Lines.add('Jelentés sikeresen beküldve');
          logirorutin(pchar('A napi jelentés sikeresen belüldve'));
          Sysutils.DeleteFile(_localpath);
        end else
        begin
          Memo1.Lines.add('Nem sikerült a jelentést beküldeni');
          logirorutin(pchar('Jelentés beküldése sikertelen'));
        end;
    end else logirorutin(pchar('Nincs napi jelentés elõkészitve'));
end;



// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$é
// =============================================================================
                   procedure TMakePack.CimtPack;   // 1.
// =============================================================================


(* Cimlet: Tablasorszam: 1; mezödarab= 17;

        1. DATUM                  -  30 - 4
        2. VALUTANEM              - 126 - 4
        3. OSSZESFORINTERTEK      -  76 - 3
        4. CIMLET1                -  15 - 2
        5. CIMLET2                -  16 - 2
        6. CIMLET3                -  17 - 2
        7. CIMLET4                -  18 - 2
        8. CIMLET5                -  19 - 2
        9. CIMLET6                -  20 - 2
       10. CIMLET7                -  21 - 2
       11. CIMLET8                -  22 - 2
       12. CIMLET9                -  23 - 2
       13. CIMLET10               -  24 - 2
       14. CIMLET11               -  25 - 2
       15. CIMLET12               -  26 - 2
       16. CIMLET13               -  27 - 2
       17. CIMLET14               -  28 - 2

       *)


var
    _c1,_c2,_c3,_c4,_c5,_c6,_c7,_c8,_c9,_c10,_c11,_c12,_c13,_c14: word;

begin
  _tablasorszam := 1;
  _mezodarab := 17;

  _mezoss[1] := 30;
  _mezoss[2] := 126;
  _mezoss[3] := 76;
  _mezoss[4] := 15;
  _mezoss[5] := 16;
  _mezoss[6] := 17;
  _mezoss[7] := 18;
  _mezoss[8] := 19;
  _mezoss[9] := 20;
  _mezoss[10]:= 21;
  _mezoss[11]:= 22;
  _mezoss[12]:= 23;
  _mezoss[13]:= 24;
  _mezoss[14]:= 25;
  _mezoss[15]:= 26;
  _mezoss[16]:= 27;
  _mezoss[17]:= 28;

  _TablaNev := 'CIMT' + _farok;

  Valdatadbase.Connected := True;
  ValdataTabla.TableName := _tablanev;
  if not ValdataTabla.Exists then
    begin
      Valdatadbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+ _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_zarodstring+chr(39);

  with Valdataquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  // Nincs zárónapi adat:

  if _recno=0 then
    begin
      ValdataQuery.close;
      Valdatadbase.close;
      exit;
    end;

   PutByte(_tablasorszam);

   logirorutin(pchar('Cimletek csomagolasas'));

   _rekordszam := _sPointer;
   _sPointer   := _sPointer + 2;

   Putbyte(_mezodarab);

   _y := 1;
   while _y<=_mezodarab do
     begin
       Putbyte(_mezoss[_y]);
       inc(_y);
     end;

   Putbyte(_zByte);  // fejléc záróbyte

   _rekordDarab := 0;
   while not ValdataQuery.Eof do
     begin
       with ValdataQuery do
         begin
           _datum := trim(FieldByName('DATUM').asString);
           _valnem:= FieldByName('VALUTANEM').asString;
           _osszes:= FieldByName('OSSZESFORINTERTEK').asInteger;
           _c1    := FieldByNAme('CIMLET1').asInteger;
           _c2    := FieldByNAme('CIMLET2').asInteger;
           _c3    := FieldByNAme('CIMLET3').asInteger;
           _c4    := FieldByNAme('CIMLET4').asInteger;
           _c5    := FieldByNAme('CIMLET5').asInteger;
           _c6    := FieldByNAme('CIMLET6').asInteger;
           _c7    := FieldByNAme('CIMLET7').asInteger;
           _c8    := FieldByNAme('CIMLET8').asInteger;
           _c9    := FieldByNAme('CIMLET9').asInteger;
           _c10   := FieldByNAme('CIMLET10').asInteger;
           _c11   := FieldByNAme('CIMLET11').asInteger;
           _c12   := FieldByNAme('CIMLET12').asInteger;
           _c13   := FieldByNAme('CIMLET13').asInteger;
           _c14   := FieldByNAme('CIMLET14').asInteger;
         end;

       putstring(_datum);
       putstring(_valnem);
       putInteger(_osszes);

       putword(_c1);
       putword(_c2);
       putword(_c3);
       putword(_c4);
       putword(_c5);
       putword(_c6);
       putword(_c7);
       putword(_c8);
       putword(_c9);
       putword(_c10);
       putword(_c11);
       putword(_c12);
       putword(_c13);
       putword(_c14);

       Putbyte(_zByte);
       inc(_rekordDarab);
       ValdataQuery.next;
     end;

   ValdataQuery.close;
   ValdataDbase.close;

   putbyte(_zByte);  // Tablazáró

   _aktSpointer := _spointer;  // spointer mentése
   _spointer := _rekordszam;

   putword(_rekorddarab);      // a rekordok számának beirása
   _spointer := _aktSpointer;  // spointer visszaállítása

   inc(_tabladarab);
end;


// =============================================================================
                           procedure TmakePack.BfPack;   // 2.
// =============================================================================

(* Blokkfej: Tablasorszam: 2; mezödarab= 22;

        1. DATUM            -  30 - 4
        2. IDO              -  49 - 4
        3. BIZONYLATSZAM    -  13 - 4
        4. TIPUS            - 102 - 5
        5. OSSZESEN         -  76 - 3
        6. UGYFELTIPUS      - 108 - 5
        7. UGYFELSZAM       - 106 - 2
        8. UGYFELNEV        - 107 - 4
        9. TETEL            - 101 - 1
       10. PENZTAROSNEV     -  80 - 4
       11. IDKOD            -  48 - 4
       12. PENZTAR          -  79 - 4
       13. TRBPENZTAR       - 105 - 4
       14. PLOMBASZAM       -  83 - 4
       15. SZALLITONEV      -  88 - 4
       16. KEZELESIDIJ      -  53 - 3
       17. STORNO           -  86 - 1
       18. STORNOBIZONYLAT  -  87 - 4
       19. FIZETOESZKOZ     -  57 - 1
       20. KONVERZIO        - 157 - 1
       21. UGYFELCIM        - 158 - 4
       22. ADOSZAM          - 159 - 4
       23. KEREKITES        - 161 - 3

       *)

var
    _trbPtar,_plomba,_szallito: string;

begin
  _tablasorszam := 2;
  _mezodarab := 23;

  _mezoss[1] := 30;
  _mezoss[2] := 49;
  _mezoss[3] := 13;
  _mezoss[4] := 102;
  _mezoss[5] := 76;
  _mezoss[6] := 108;
  _mezoss[7] := 106;
  _mezoss[8] := 107;
  _mezoss[9] := 101;
  _mezoss[10]:= 80;
  _mezoss[11]:= 48;
  _mezoss[12]:= 79;
  _mezoss[13]:= 105;
  _mezoss[14]:= 83;
  _mezoss[15]:= 88;
  _mezoss[16]:= 53;
  _mezoss[17]:= 86;
  _mezoss[18]:= 87;
  _mezoss[19]:= 57;
  _mezoss[20]:= 157;
  _mezoss[21]:= 158;
  _mezoss[22]:= 159;
  _mezoss[23]:= 161;

  _tablanev := 'BF' + _farok;

  Valdatadbase.Connected := true;
  ValdataTabla.TableName := _tablanev;
  if not ValdataTabla.Exists then
    begin
      Valdatadbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+ _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39)+ _zarodstring + chr(39);

  with Valdataquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      ValdataQuery.close;
      Valdatadbase.close;
      exit;
    end;

   logirorutin(pchar('Blokkfejek csomagolasa'));

   PutByte(_tablasorszam);
   _rekordszam := _Spointer;
   _sPointer := _sPointer + 2;

   Putbyte(_mezodarab);

   _y := 1;
   while _y<=_mezodarab do
     begin
       Putbyte(_mezoss[_y]);
       inc(_y);
     end;

   Putbyte(_zByte);

   _rekordDarab := 0;
   while not ValdataQuery.Eof do
     begin
       with ValdataQuery do
         begin
           _datum     := FieldByName('DATUM').asString;
           _ido       := FieldByName('IDO').asString;
           _bizonylat := trim(FieldByName('BIZONYLATSZAM').asString);
           _tipus     := FieldByNAme('TIPUS').asString;
           _osszes    := FieldByNAme('OSSZESFORINTERTEK').asInteger;
           _ugyftip   := trim(FieldByNAme('UGYFELTIPUS').asString);
           _ugyfszam  := FieldByNAme('UGYFELSZAM').asInteger;
           _ugyfnev   := trim(FieldByNAme('UGYFELNEV').asString);
           _tetel     := FieldByNAme('TETEL').asInteger;
           _prosnev   := trim(FieldByNAme('PENZTAROSNEV').asstring);
           _idkod     := trim(FieldByNAme('IDKOD').asstring);
           _penztar   := trim(FieldByNAme('TARSPENZTARKOD').asString);
           _trbptar   := trim(FieldByNAme('TRBPENZTAR').asstring);
           _plomba    := trim(FieldByNAme('PLOMBASZAM').asString);
           _szallito  := trim(FieldByname('SZALLITONEV').asString);
           _kezdij    := FieldByNAme('KEZELESIDIJ').asInteger;
           _STORNO    := FieldByNAme('STORNO').asInteger;
           _stBiz     := trim(FieldByNAme('STORNOBIZONYLAT').asstring);
           _fizeszkoz := FieldByName('FIZETOESZKOZ').asInteger;
           _konverzio := FieldByNAme('KONVERZIO').asInteger;
           _kerekites := FieldByName('KEREKITES').asInteger;
           _ugyfelcim := trim(FieldByName('UGYFELCIM').asString);
           _adoszam   := trim(FieldByNAme('ADOSZAM').AsString);
         end;

       putstring(_datum);
       putstring(_ido);
       putstring(_bizonylat);
       putchar(_tipus);
       putInteger(_osszes);
       putchar(_ugyftip);
       putword(_ugyfszam);
       putstring(_ugyfnev);
       putbyte(_tetel);
       putstring(_prosnev);
       putstring(_idkod);
       putstring(_penztar);
       putstring(_trbPtar);
       putstring(_plomba);
       putstring(_szallito);
       Putinteger(_kezdij);
       Putbyte(_storno);
       Putstring(_stBiz);
       Putbyte(_fizeszkoz);
       Putbyte(_konverzio);
       Putstring(_ugyfelcim);
       Putstring(_adoszam);
       Putinteger(_kerekites);

       Putbyte(_zByte);
       inc(_rekordDarab);
       ValdataQuery.next;
     end;

   ValdataQuery.close;
   ValdataDbase.close;

   putbyte(_zByte);  // Tablazáró

   _aktSpointer := _spointer;  // spointer mentése
   _spointer := _rekordszam;

   putword(_rekorddarab);      // a rekordok számának beirása
   _spointer := _aktSpointer;  // spointer visszaállítása
   inc(_tabladarab);

end;

// =============================================================================
                           procedure TmakePack.BTPack;    // 3.
// =============================================================================

(* Blokktetel: Tablasorszam: 3; mezödarab= 11;

        1. BIZONYLATSZAM        -  13 - 4
        2. DATUM                -  30 - 4
        3. VALUTANEM            - 126 - 4
        4. BANKJEGY             -   9 - 3
        5. ARFOLYAM             -   5 - 3
        6. ELSZAMOLASIARFOLYAM  -  38 - 3
        7. FORINTERTEK          -  41 - 3
        8. ELOJEL               -  35 - 5
        9. COIN                 -  29 - 1
       10. STORNO               -  86 - 1
       11. TORTRESZ             - 160 - 4


       *)

var
    _coin: byte;
    _elojel: string;

begin
  _tablasorszam := 3;
  _mezodarab := 11;

  _mezoss[1] := 13;
  _mezoss[2] := 30;
  _mezoss[3] := 126;
  _mezoss[4] := 9;
  _mezoss[5] := 5;
  _mezoss[6] := 38;
  _mezoss[7] := 41;
  _mezoss[8] := 35;
  _mezoss[9] := 29;
  _mezoss[10]:= 86;
  _mezoss[11]:= 160;


  _tablanev := 'BT' + _farok;

  Valdatadbase.Connected := true;
  ValdataTabla.TableName := _tablanev;
  if not ValdataTabla.Exists then
    begin
      Valdatadbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+ _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39)+_zarodstring+chr(39);

  with Valdataquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      ValdataQuery.close;
      Valdatadbase.close;
      exit;
    end;

  logirorutin(pchar('Blokktetelek csonagolása'));

   PutByte(_tablasorszam);
   _rekordszam := _Spointer;
   _sPointer := _sPointer + 2;

   Putbyte(_mezodarab);

   _y := 1;
   while _y<=_mezodarab do
     begin
       Putbyte(_mezoss[_y]);
       inc(_y);
     end;

   Putbyte(_zByte);

   _rekordDarab := 0;
   while not ValdataQuery.Eof do
     begin
       with ValdataQuery do
         begin
           _datum       := FieldByName('DATUM').asString;
           _valnem      := FieldByName('VALUTANEM').asString;
           _bizonylat   := trim(FieldByName('BIZONYLATSZAM').asString);
           _Bankjegy    := FieldByNAme('BANKJEGY').asInteger;
           _arfolyam    := FieldByNAme('ARFOLYAM').asInteger;
           _elszamarf   := FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
           _forintertek := FieldByNAme('FORINTERTEK').asInteger;
           _elojel      := FieldByNAme('ELOJEL').asString;
           _coin        := FieldByNAme('COIN').asInteger;
           _storno      := FieldByNAme('STORNO').asInteger;
           _tortresz    := trim(FieldByNAme('TORTRESZ').AsString);
         end;

       putstring(_bizonylat);
       putstring(_datum);
       putstring(_valnem);
       putinteger(_bankjegy);
       putinteger(_arfolyam);
       putinteger(_elszamarf);
       putInteger(_forintertek);
       putChar(_elojel);
       Putbyte(_coin);
       Putbyte(_storno);
       Putstring(_tortresz);

       Putbyte(_zByte);
       inc(_rekordDarab);
       ValdataQuery.next;
     end;

   ValdataQuery.close;
   ValdataDbase.close;

   putbyte(_zByte);  // Tablazáró

   _aktSpointer := _spointer;  // spointer mentése
   _spointer := _rekordszam;

   putword(_rekorddarab);      // a rekordok számának beirása
   _spointer := _aktSpointer;  // spointer visszaállítása
   inc(_tabladarab);
end;


// =============================================================================
                           procedure TmakePack.NarfPack;   // 4.
// =============================================================================

(* Napiárfolyam: Tablasorszam: 4; mezödarab= 7;

        1. DATUM                -  30 - 4
        2. VALUTANEM            - 126 - 4
        3. VETELIARFOLYAM       - 127 - 3
        4. ELADASIARFOLYAM      -  33 - 3
        5. ELSZAMOLASIARFOLYAM  -  38 - 3
        6. NYITO                -  73 - 3
        7. ZARO                 - 128 - 3
       *)


begin
  _tablasorszam := 4;
  _mezodarab := 7;

  _mezoss[1] := 30;
  _mezoss[2] := 126;
  _mezoss[3] := 127;
  _mezoss[4] := 33;
  _mezoss[5] := 38;
  _mezoss[6] := 73;
  _mezoss[7] := 128;

  _tablanev := 'NARF' + _farok;

  Valdatadbase.Connected := true;
  ValdataTabla.TableName := _tablanev;
  if not ValdataTabla.Exists then
    begin
      Valdatadbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+ _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_zarodstring+chr(39);

  with Valdataquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      ValdataQuery.close;
      Valdatadbase.close;
      exit;
    end;

  logirorutin(pchar('Napi arfolyamok csomagolasa'));

   PutByte(_tablasorszam);
   _rekordszam := _Spointer;
   _sPointer := _sPointer + 2;

   Putbyte(_mezodarab);

   _y := 1;
   while _y<=_mezodarab do
     begin
       Putbyte(_mezoss[_y]);
       inc(_y);
     end;

   Putbyte(_zByte); // fejléc záró

   _rekordDarab := 0;
   while not ValdataQuery.Eof do
     begin
       with ValdataQuery do
         begin
           _datum   := FieldByName('DATUM').asString;
           _valnem  := FieldByName('VALUTANEM').asString;
           _varfoly := FieldByName('VETELIARFOLYAM').asInteger;
           _earfoly := FieldByNAme('ELADASIARFOLYAM').asInteger;
           _elszamarf := FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
           _nyito   := FieldByNAme('NYITO').asInteger;
           _zaro    := FieldByNAme('ZARO').asInteger;
         end;

       putstring(_datum);
       putstring(_valnem);
       putinteger(_varfoly);
       putinteger(_earfoly);
       putinteger(_elszamarf);
       putInteger(_nyito);
       putinteger(_zaro);

       Putbyte(_zByte);      // rekordzáró
       inc(_rekordDarab);
       ValdataQuery.next;
     end;

   ValdataQuery.close;
   ValdataDbase.close;

   putbyte(_zByte);  // Tablazáró

   _aktSpointer := _spointer;  // spointer mentése
   _spointer := _rekordszam;

   putword(_rekorddarab);      // a rekordok számának beirása
   _spointer := _aktSpointer;  // spointer visszaállítása
   inc(_tabladarab);
end;

// =============================================================================
                           procedure TmakePack.ArfePack;   // 5.
// =============================================================================

(* Árfolyamengedmények: Tablasorszam: 5; mezödarab= 10;

        1. DATUM          -  30 - 4
        2. VALUTANEM      - 126 - 4
        3. ARFOLYAM       -   5 - 3
        4. UJARFOLYAM     - 110 - 3
        5. PENZTAROSNEV   -  80 - 4
        6. BIZONYLATSZAM  -  13 - 4
        7. BANKJEGY       -   9 - 3
        8. ELSZAMARFOLYAM -  37 - 3
        9. PENZTAROSIMAX  -  81 - 3
       10. ENGEDMENYTIPUS -  39 - 2

       *)

var
    _engtip: byte;
    _ujarfoly,_prosmax: integer;

begin
  _tablasorszam := 5;
  _mezodarab := 10;

  _mezoss[1] := 30;
  _mezoss[2] := 126;
  _mezoss[3] := 5;
  _mezoss[4] := 110;
  _mezoss[5] := 80;
  _mezoss[6] := 13;
  _mezoss[7] := 9;
  _mezoss[8] := 37;
  _mezoss[9] := 81;
  _mezoss[10]:= 39;

  _tablanev := 'ARFE' + _farok;

  Valdatadbase.Connected := true;
  ValdataTabla.TableName := _tablanev;
  if not ValdataTabla.Exists then
    begin
      Valdatadbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+ _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_zarodstring+chr(39);

  with Valdataquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      ValdataQuery.close;
      Valdatadbase.close;
      exit;
    end;

  logirorutin(pchar('Árengedmények csomagolása'));

   PutByte(_tablasorszam);
   _rekordszam := _Spointer;
   _sPointer := _sPointer + 2;

   Putbyte(_mezodarab);

   _y := 1;
   while _y<=_mezodarab do
     begin
       Putbyte(_mezoss[_y]);
       inc(_y);
     end;

   Putbyte(_zByte); // fejléc záró

   _rekordDarab := 0;
   while not ValdataQuery.Eof do
     begin
       with ValdataQuery do
         begin
           _datum     := FieldByName('DATUM').asString;
           _valnem    := FieldByName('VALUTANEM').asString;
           _arfolyAM  := FieldByName('ARFOLYAM').asInteger;
           _UJarfoly  := FieldByNAme('UJARFOLYAM').asInteger;
           _prosnev   := trim(FieldByNAme('PENZTAROSNEV').asString);
           _bizonylat := FieldByNAme('BIZONYLATSZAM').asString;
           _bankjegy  := FieldByNAme('BANKJEGY').asInteger;
           _elszamarf := FieldByNAme('ELSZAMARFOLYAM').asInteger;
           _prosmax   := FieldByname('PENZTAROSIMAX').asInteger;
           _engtip    := fieldbyname('ENGEDMENYTIPUSSZAM').asinteger;
         end;

       putstring(_datum);
       putstring(_valnem);
       putinteger(_arfolyam);
       putinteger(_ujarfoly);
       putstring(_prosnev);
       putstring(_bizonylat);
       putinteger(_bankjegy);
       putinteger(_elszamarf);
       putinteger(_prosmax);
       putword(_engtip);

       Putbyte(_zByte);      // rekordzáró
       inc(_rekordDarab);
       ValdataQuery.next;
     end;

   ValdataQuery.close;
   ValdataDbase.close;

   putbyte(_zByte);  // Tablazáró

   _aktSpointer := _spointer;  // spointer mentése
   _spointer := _rekordszam;

   putword(_rekorddarab);      // a rekordok számának beirása
   _spointer := _aktSpointer;  // spointer visszaállítása
   inc(_tabladarab);
end;

// =============================================================================
                           procedure TmakePack.WafaPack;   // 6
// =============================================================================

(* Áfavisszatérítés: Tablasorszam: 6; mezödarab= 15;

        1. DATUM            -  30 - 4
        2. FOEGYSEG         -  40 - 1
        3. PENZTARSZAM      -  82 - 2
        4. UGYFELSZAM       - 106 - 2
        5. SORSZAM          -  85 - 4
        6. SZAMLASZAM       -  89 - 4
        7. BRUTTO           -  14 - 3
        8. AFA              -   1 - 3
        9. KEZELESISZAZALEK -  54 - 1
       10. UGYKEZELESIDIJ   - 109 - 3
       11. KIFIZETVE        -  55 - 3
       12. ELLATMANY        -  34 - 3
       13. TRANZAKCIOTIPUS  - 103 - 4
       14. STORNO           -  86 - 1
       15. STORNOBIZONYLAT  -  87 - 4

       *)

var
    _kezszaz: byte;
    _ugykdij: integer;

begin
  _tablasorszam := 6;
  _mezodarab := 15;

  _mezoss[1] := 30;
  _mezoss[2] := 40;
  _mezoss[3] := 82;
  _mezoss[4] := 106;
  _mezoss[5] := 85;
  _mezoss[6] := 89;
  _mezoss[7] := 14;
  _mezoss[8] := 1;
  _mezoss[9] := 54;
  _mezoss[10]:= 109;
  _mezoss[11]:= 55;
  _mezoss[12]:= 34;
  _mezoss[13]:= 103;
  _mezoss[14]:= 86;
  _mezoss[15]:= 87;

  _tablanev := 'WAFA' + _farok;

  Valdatadbase.Connected := true;
  ValdataTabla.TableName := _tablanev;
  if not ValdataTabla.Exists then
    begin
      Valdatadbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+ _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_zarodstring+chr(39);

  with Valdataquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  if _recno=0 then
    begin
      ValdataQuery.close;
      Valdatadbase.close;
      exit;
    end;

   logirorutin(pchar('Afa fizetesek csomagolasa'));

   PutByte(_tablasorszam);
   _rekordszam := _Spointer;
   _sPointer := _sPointer + 2;

   Putbyte(_mezodarab);

   _y := 1;
   while _y<=_MEZODARAB do
     begin
       Putbyte(_mezoss[_y]);
       inc(_y);
     end;

   Putbyte(_zByte); // fejléc záró

   _rekordDarab := 0;
   while not ValdataQuery.Eof do
     begin
       with ValdataQuery do
         begin
           _datum     := FieldByName('DATUM').asString;
           _FOE       := FieldByName('FOEGYSEGSZAM').asInteger;
           _ptarszam  := FieldByName('PENZTARSZAM').asInteger;
           _ugyFszam  := FieldByNAme('UGYFELSZAM').asInteger;
           _sorszam   := trim(FieldByNAme('SORSZAM').asString);
           _szlaszam  := trim(FieldByName('SZAMLASZAM').asString);
           _brutto    := FieldByNAme('BRUTTOOSSZEG').asInteger;
           _afa       := FieldByNAme('AFAOSSZEG').asInteger;
           _kezszaz   := FieldByNAme('KEZELESISZAZALEK').asInteger;
           _ugykdij   := FieldByname('UGYKEZELESIDIJ').asInteger;
           _kifizetve := fieldbyname('KIFIZETETTOSSZEG').asinteger;
           _ellatmany := FieldByName('ELLATMANYFORINT').asInteger;
           _tranztip  := trim(FieldByName('TRANZAKCIOTIPUS').asString);
           _storno    := FieldbyName('STORNO').asInteger;
           _stbiz     := trim(FieldByName('STORNOBIZONYLAT').asString);
         end;

       putstring(_datum);
       putbyte(_foe);
       putword(_ptarszam);
       putword(_ugyfszam);
       putstring(_sorszam);
       putstring(_szlaszam);
       putinteger(_brutto);
       putinteger(_afa);
       putbyte(_kezszaz);
       putinteger(_ugykdij);
       putinteger(_kifizetve);
       putinteger(_ellatmany);
       putstring(_tranztip);
       putbyte(_storno);
       putstring(_stbiz);

       Putbyte(_zByte);      // rekordzáró
       inc(_rekordDarab);
       ValdataQuery.next;
     end;

   ValdataQuery.close;
   ValdataDbase.close;

   putbyte(_zByte);  // Tablazáró

   _aktSpointer := _spointer;  // spointer mentése
   _spointer := _rekordszam;

   putword(_rekorddarab);      // a rekordok számának beirása
   _spointer := _aktSpointer;  // spointer visszaállítása
   inc(_tabladarab);

end;


// =============================================================================
                           procedure TmakePack.TescPack;   // 7
// =============================================================================

(* Áfavisszatérítés: Tablasorszam: 7; mezödarab= 10;

        1. DATUM            -  30 - 4
        2. BIZONYLATSZAM    -  13 - 4
        3. TIPUS            - 102 - 5
        4. UGYFELSZAM       - 106 - 2
        5. UGYFELNEV        - 107 - 4
        6. SZAMLASZAM       -  89 - 4
        7. BRUTTO           -  14 - 3
        8. AFA              -   1 - 3
        9. AFA5             -   2 - 3
       10. OSSZESEN         -  76 - 3
       *)

var

    _afa5,_osszesen: integer;

begin
  _tablasorszam := 7;
  _mezodarab := 10;

  _mezoss[1] := 30;
  _mezoss[2] := 13;
  _mezoss[3] := 102;
  _mezoss[4] := 106;
  _mezoss[5] := 107;
  _mezoss[6] := 89;
  _mezoss[7] := 14;
  _mezoss[8] := 1;
  _mezoss[9] := 2;
  _mezoss[10]:= 76;

  _tablanev := 'TESC' + _farok;

  Valdatadbase.Connected := true;
  ValdataTabla.TableName := _tablanev;
  if not ValdataTabla.Exists then
    begin
      Valdatadbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+ _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_zarodstring+chr(39);
  with Valdataquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      ValdataQuery.close;
      Valdatadbase.close;
      exit;
    end;

   logirorutin(Pchar('Tesco afa csomagolasa'));

   PutByte(_tablasorszam);
   _rekordszam := _Spointer;
   _sPointer := _sPointer + 2;

   Putbyte(_mezodarab);

   _y := 1;
   while _y<=_mezodarab do
     begin
       Putbyte(_mezoss[_y]);
       inc(_y);
     end;

   Putbyte(_zByte); // fejléc záró

   _rekordDarab := 0;
   while not ValdataQuery.Eof do
     begin
       with ValdataQuery do
         begin
           _datum     := FieldByName('DATUM').asString;
           _bizonylat := trim(FieldbyName('BIZONYLATSZAM').AsString);
           _tipus     := trim(FieldByName('BIZONYLATTIPUS').AsString);
           _ugyfszam  := Fieldbyname('WUGYFELSZAM').asInteger;
           _ugyfnev   := trim(FieldByNAme('WUGYFELNEV').asString);
           _szlaszam  := trim(FieldByName('SZAMLASZAM').AsString);
           _brutto    := FieldByName('SZAMLABRUTTO').asInteger;
           _afa       := FieldbyNAme('AFA20SZAZALEKOS').asInteger;
           _afa5      := FieldByName('AFA5SZAZALEKOS').asInteger;
           _osszesen  := FieldByName('OSSZESFORINT').asInteger;
         end;

       putstring(_datum);
       putstring(_bizonylat);
       putchar(_tipus);
       putword(_ugyfszam);
       putstring(_ugyfnev);
       putstring(_szlaszam);
       putinteger(_brutto);
       putinteger(_afa);
       putinteger(_afa5);
       putinteger(_osszesen);

       Putbyte(_zByte);      // rekordzáró
       inc(_rekordDarab);
       ValdataQuery.next;
     end;

   ValdataQuery.close;
   ValdataDbase.close;

   putbyte(_zByte);  // Tablazáró

   _aktSpointer := _spointer;  // spointer mentése
   _spointer := _rekordszam;

   putword(_rekorddarab);      // a rekordok számának beirása
   _spointer := _aktSpointer;  // spointer visszaállítása
   inc(_tabladarab);
end;

// =============================================================================
                           procedure TmakePack.WuniPack;   // 8.
// =============================================================================

(* Western Union: Tablasorszam: 8; mezödarab= 14;

        1. DATUM            -  30 - 4
        2. FOEGYSEG         -  40 - 1
        3. PENZTARSZAM      -  82 - 2
        4. UGYFELTIPUS      - 108 - 5
        5. UGYFELSZAM       - 106 - 2
        6. SORSZAM          -  85 - 4
        7. VALUTANEM        - 126 - 4
        8. BANKJEGY         -   9 - 3
        9. TRANZAKCIOTIPUS  - 103 - 4
       10. MTCNSZAM         -  70 - 4
       11. PENZTAROSNEV     -  80 - 4
       12. IDKOD            -  48 - 4
       13. STORNO           -  86 - 1
       14. STORNOBIZONYLAT  -  87 - 4

       *)

var
    _mtcnszam: string;

begin
  _tablasorszam := 8;
  _mezodarab := 14;

  _mezoss[1] := 30;
  _mezoss[2] := 40;
  _mezoss[3] := 82;
  _mezoss[4] := 108;
  _mezoss[5] := 106;
  _mezoss[6] := 85;
  _mezoss[7] := 126;
  _mezoss[8] := 9;
  _mezoss[9] := 103;
  _mezoss[10]:= 70;
  _mezoss[11]:= 80;
  _mezoss[12]:= 48;
  _mezoss[13]:= 86;
  _mezoss[14]:= 87;

  _tablanev := 'WUNI' + _farok;

  Valdatadbase.Connected := true;
  ValdataTabla.TableName := _tablanev;
  if not ValdataTabla.Exists then
    begin
      Valdatadbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+ _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_zarodstring+chr(39);

  with Valdataquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      ValdataQuery.close;
      Valdatadbase.close;
      exit;
    end;

   logirorutin(pchar('Western Union bizonylatok csomagolása'));

   PutByte(_tablasorszam);
   _rekordszam := _Spointer;
   _sPointer := _sPointer + 2;

   Putbyte(_mezodarab);

   _y := 1;
   while _y<=_mezodarab do
     begin
       Putbyte(_mezoss[_y]);
       inc(_y);
     end;

   Putbyte(_zByte); // fejléc záró

   _rekordDarab := 0;
   while not ValdataQuery.Eof do
     begin
       with ValdataQuery do
         begin
           _datum     := FieldByName('DATUM').asString;
           _FOE       := FieldByName('FOEGYSEGSZAM').asInteger;
           _ptarszam  := FieldByName('PENZTARSZAM').asInteger;
           _ugyftip   := FieldbyNAme('UGYFELTIPUS').asString;
           _ugyFszam  := FieldByNAme('UGYFELSZAM').asInteger;
           _sorszam   := trim(FieldByNAme('SORSZAM').asString);
           _valnem    := FieldByNAme('VALUTANEM').asString;
           _bankjegy  := FieldByNAme('BANKJEGY').asInteger;
           _tranztip  := FieldByNAme('TRANZAKCIOTIPUS').asString;
           _mtcnszam  := trim(FieldByname('MTCNSZAM').asString);
           _prosnev   := trim(FieldByName('PENZTAROSNEV').asString);
           _idkod     := FieldByName('IDKOD').asString;
           _storno    := FieldbyName('STORNO').asInteger;
           _stbiz     := trim(FieldByName('STORNOBIZONYLAT').asString);
         end;

       putstring(_datum);
       putbyte(_foe);
       putword(_ptarszam);
       putchar(_ugyftip);
       putword(_ugyfszam);
       putstring(_sorszam);
       putstring(_valnem);
       putinteger(_bankjegy);
       putstring(_tranztip);
       putstring(_mtcnszam);
       putstring(_prosnev);
       putstring(_idkod);
       putbyte(_storno);
       putstring(_stbiz);

       Putbyte(_zByte);      // rekordzáró
       inc(_rekordDarab);
       ValdataQuery.next;
     end;

   ValdataQuery.close;
   ValdataDbase.close;

   putbyte(_zByte);  // Tablazáró

   _aktSpointer := _spointer;  // spointer mentése
   _spointer := _rekordszam;

   putword(_rekorddarab);      // a rekordok számának beirása
   _spointer := _aktSpointer;  // spointer visszaállítása
   inc(_tabladarab);
end;

// =============================================================================
                           procedure TmakePack.WzarPack;  // 9.
// =============================================================================

(* Afa-Wuni záró: Tablasorszam: 9; mezödarab= 20;

        1. DATUM          -  30 - 4

        2. USDNYITO       - 113 - 3
        3. HUFNYITO       -  46 - 3
        4. METRONYITO     -  66 - 3
        5. TESCONYITO     -  98 - 3

        6. USDBE          - 111 - 3
        7. HUFBE          -  44 - 3
        8. METROBE        -  64 - 3
        9. TESCOBE        -  96 - 3

       10. USDKI          - 112 - 3
       11. HUFKI          -  45 - 3
       12. METROKI        -  65 - 3
       13. TESCOKI        -  97 - 3

       14. USDZARO        - 114 - 3
       15. HUFZARO        -  47 - 3
       16. METROZARO      -  67 - 3
       17. TESCOZARO      - 100 - 3

       18. METROVISSZA    -  68 - 3
       19. TESCOVISSZA    -  99 - 3

       20. UGYKEZELESIDIJ - 109 - 3

       *)


var

    _usdnyito,_usdbe,_usdki,_usdzaro: integer;
    _hufnyito,_hufbe,_hufki,_hufzaro: integer;
    _metronyito,_metrobe,_metroki,_metrozaro: integer;
    _tesconyito,_tescobe,_tescoki,_tescozaro: integer;
    _metrovissza,_tescovissza,_ugykezdij: integer;

begin
  _tablasorszam := 9;
  _mezodarab := 20;

  _mezoss[1] := 30;

  _mezoss[2] := 113;
  _mezoss[3] := 46;
  _mezoss[4] := 66;
  _mezoss[5] := 98;

  _mezoss[6] := 111;
  _mezoss[7] := 44;
  _mezoss[8] := 64;
  _mezoss[9] := 96;

  _mezoss[10]:= 112;
  _mezoss[11]:= 45;
  _mezoss[12]:= 65;
  _mezoss[13]:= 97;

  _mezoss[14]:= 114;
  _mezoss[15]:= 47;
  _mezoss[16]:= 67;
  _mezoss[17]:= 100;

  _mezoss[18]:= 68;
  _mezoss[19]:= 99;

  _mezoss[20]:= 109;

  _tablanev := 'WZAR' + _farok;

  Valdatadbase.Connected := true;
  ValdataTabla.TableName := _tablanev;
  if not ValdataTabla.Exists then
    begin
      Valdatadbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+ _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_zarodstring+chr(39);

  with Valdataquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      ValdataQuery.close;
      Valdatadbase.close;
      exit;
    end;

   logirorutin(pchar('Wu és Afa bizonylatok napi zaras csomagolasa'));

   PutByte(_tablasorszam);
   Putword(1);    // egyetlen rekord;

   Putbyte(_mezodarab);

   _y := 1;
   while _y<=_mezodarab do
     begin
       Putbyte(_mezoss[_y]);
       inc(_y);
     end;

   Putbyte(_zByte); // fejléc záró


   with ValdataQuery do
     begin
       _datum := FieldByName('DATUM').asString;
       _usdnyito := FieldByNAme('USDNYITO').asInteger;
       _hufnyito := FieldByName('HUFNYITO').asInteger;
       _metronyito := FieldByName('METRONYITO').asInteger;
       _tesconyito := FieldByNAme('TESCONYITO').asInteger;

       _usdbe := FieldByNAme('USDBEVETEL').asInteger;
       _hufbe := FieldByNAme('HUFBEVETEL').asInteger;
       _metrobe := FieldByNAme('METROBEVETEL').asInteger;
       _tescobe := FieldByName('TESCOBEVETEL').asInteger;

       _usdki := FieldByNAme('USDKIADAS').asInteger;
       _hufki := FieldByNAme('HUFKIADAS').asInteger;
       _metroki := FieldByNAme('METROKIADAS').asInteger;
       _tescoki := FieldByName('TESCOKIADAS').asInteger;

       _usdzaro := FieldByNAme('USDZARO').asInteger;
       _hufzaro := FieldByNAme('HUFZARO').asInteger;
       _metrozaro := FieldByNAme('METROZARO').asInteger;
       _tescozaro := FieldByName('TESCOZARO').asInteger;

       _metrovissza := Fieldbyname('METROVISSZA').asInteger;
       _tescovissza := FieldByName('TESCOVISSZA').asInteger;

       _ugykezdij := FieldByNAme('UGYKEZELESIDIJ').asInteger;
     end;

   putstring(_datum);

   putinteger(_usdnyito);
   putinteger(_hufnyito);
   putinteger(_metronyito);
   putinteger(_tesconyito);

   putinteger(_usdbe);
   putinteger(_hufbe);
   putinteger(_metrobe);
   putinteger(_tescobe);

   putinteger(_usdki);
   putinteger(_hufki);
   putinteger(_metroki);
   putinteger(_tescoki);

   putinteger(_usdzaro);
   putinteger(_hufzaro);
   putinteger(_metrozaro);
   putinteger(_tescozaro);

   putinteger(_metrovissza);
   putinteger(_tescovissza);

   putinteger(_ugykezdij);

   Putbyte(_zByte);      // rekordzáró

   ValdataQuery.close;
   ValdataDbase.close;

   putbyte(_zByte);  // Tablazáró

   inc(_tabladarab);
end;


// =============================================================================
                           procedure TmakePack.KezdPack;          // 10.
// =============================================================================

(* kEZELÉSI DÍJAK: Tablasorszam: 10; mezödarab= 6;

        1. DATUM        -  30 - 4
        2. ELOJEL       -  35 - 5
        3. KEZELESIDIJ  -  53 - 3
        4. PENZTAR      -  79 - 4
        5. BIZONYLAT    -  11 - 4
        6. MOZGAS       -  69 - 1


       *)

var
    _elojel: string;
    _mozgas: byte;

begin
  _tablasorszam := 10;
  _mezodarab := 6;

  _mezoss[1] := 30;
  _mezoss[2] := 35;
  _mezoss[3] := 53;
  _mezoss[4] := 79;
  _mezoss[5] := 11;
  _mezoss[6] := 69;

  _tablanev := 'KEZD' + _farok;

  Valdatadbase.Connected := true;
  ValdataTabla.TableName := _tablanev;
  if not ValdataTabla.Exists then
    begin
      Valdatadbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+ _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+CHR(39)+_zarodstring+chr(39);

  with Valdataquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      ValdataQuery.close;
      Valdatadbase.close;
      exit;
    end;

  logirorutin(pchar('Kezelési költségek csomagolasa'));

   PutByte(_tablasorszam);
   _rekordszam := _Spointer;
   _sPointer := _sPointer + 2;

   Putbyte(_mezodarab);

   _y := 1;
   while _y<=_mezodarab do
     begin
       Putbyte(_mezoss[_y]);
       inc(_y);
     end;

   Putbyte(_zByte); // fejléc záró

   _rekordDarab := 0;
   while not ValdataQuery.Eof do
     begin
       with ValdataQuery do
         begin
           _datum     := FieldByName('DATUM').asString;
           _elojel    := FieldByName('ELOJEL').asString;
           _kezdij    := FieldByName('KEZELESIDIJ').asInteger;
           _penztar   := trim(FieldbyNAme('PENZTAR').asString);
           _bizonylat := trim(FieldByNAme('BIZONYLAT').asString);
           _mozgas    := FieldByNAme('MOZGAS').asInteger;
         end;

       putstring(_datum);
       putchar(_elojel);
       putinteger(_kezdij);
       putstring(_penztar);
       putstring(_bizonylat);
       putbyte(_mozgas);

       Putbyte(_zByte);      // rekordzáró
       inc(_rekordDarab);
       ValdataQuery.next;
     end;

   ValdataQuery.close;
   ValdataDbase.close;

   putbyte(_zByte);  // Tablazáró

   _aktSpointer := _spointer;  // spointer mentése
   _spointer := _rekordszam;

   putword(_rekorddarab);      // a rekordok számának beirása
   _spointer := _aktSpointer;  // spointer visszaállítása
   inc(_tabladarab);
end;

// =============================================================================
                           procedure TmakePack.XkezPack;    // 11.
// =============================================================================

(* Extra kezelési dijak: Tablasorszam: 11; mezödarab= 5;

        1. DATUM            -  30 - 4
        2. BIZONYLAT        -  11 - 4
        3. BIZONYLATFORINT  -  12 - 3
        4. TIPUS            - 102 - 5
        5. EGYEDIKEZDIJ     -  32 - 3

       *)

var
    _bizft,_xkezdij: integer;

begin
  _tablasorszam := 11;
  _mezodarab := 5;

  _mezoss[1] := 30;
  _mezoss[2] := 11;
  _mezoss[3] := 12;
  _mezoss[4] := 102;
  _mezoss[5] := 32;

  _tablanev := 'XKEZ' + _farok;

  Valdatadbase.Connected := true;
  ValdataTabla.TableName := _tablanev;
  if not ValdataTabla.Exists then
    begin
      Valdatadbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+ _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_zarodstring+chr(39);

  with Valdataquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      ValdataQuery.close;
      Valdatadbase.close;
      exit;
    end;

   logirorutin(pchar('Extra kedvezmények csomagolasa'));

   PutByte(_tablasorszam);
   _rekordszam := _Spointer;
   _sPointer := _sPointer + 2;

   Putbyte(_mezodarab);

   _y := 1;
   while _y<=_mezodarab do
     begin
       Putbyte(_mezoss[_y]);
       inc(_y);
     end;

   Putbyte(_zByte); // fejléc záró

   _rekordDarab := 0;
   while not ValdataQuery.Eof do
     begin
       with ValdataQuery do
         begin
           _datum     := FieldByName('DATUM').asString;
           _bizonylat := trim(FieldByNAme('BIZONYLAT').asString);
           _bizft     := FieldByName('BIZONYLATFORINT').asInteger;
           _tipus     := FieldByName('TIPUS').asString;
           _Xkezdij   := FieldByName('EGYEDIKEZDIJ').asInteger;
         end;

       putstring(_datum);
       putstring(_bizonylat);
       putinteger(_bizft);
       putchar(_tipus);
       putinteger(_xkezdij);

       Putbyte(_zByte);      // rekordzáró
       inc(_rekordDarab);
       ValdataQuery.next;
     end;

   ValdataQuery.close;
   ValdataDbase.close;

   putbyte(_zByte);  // Tablazáró

   _aktSpointer := _spointer;  // spointer mentése
   _spointer := _rekordszam;

   putword(_rekorddarab);      // a rekordok számának beirása
   _spointer := _aktSpointer;  // spointer visszaállítása
   inc(_tabladarab);
end;

// =============================================================================
                       procedure TMakePack.EfejPack;   // 13.
// =============================================================================

(*

        E-trade fejek: Tablasorszam: 13; mezödarab= 9;

        1. DATUM        -  30 - 4
        2. NYITO        -  73 - 3
        3. MATRICA      -  61 - 3
        4. TELEFON      -  93 - 3
        5. VODAFON      - 146 - 3
        6. PAYSAFECARD  - 147 - 3
        7. ATADAS       -   6 - 3
        8. ATVETEL      -   7 - 3
        9. ZARO         - 128 - 3
       10. TELENOR      - 154 - 3
       *)

var
    i,_mss: byte;

begin
   _mezoss[1] := 30;
   _mezoss[2] := 73;
   _mezoss[3] := 61;
   _mezoss[4] := 93;
   _mezoss[5] := 146;
   _mezoss[6] := 147;
   _mezoss[7] := 6;
   _mezoss[8] := 7;
   _mezoss[9] := 128;
   _mezoss[10]:= 154;

 (* Beirja az address számot és a rekordok számát *)

   inc(_tabladarab);

  Putbyte(13);  // táblasorszám = 18 = EFEJ;
  Putword(1);   // a fejben egyetlen rekord van

  Putbyte(10);   // mezõdarab;

  for i := 1 to 10 do
    begin
      _mss := _mezoss[i];
      putbyte(_mss);
    end;

  PutByte(255);  // fejléczáró byte

  Putstring(_zarodstring);
  Putinteger(_nyito);
  Putinteger(_matrica);
  Putinteger(_telefon);
  Putinteger(_vodafon);
  Putinteger(_paysafeCard);
  Putinteger(_atadas);
  Putinteger(_atvetel);
  Putinteger(_zaro);
  Putinteger(_telenor);

  Putbyte(255);   // rekordzáró
  Putbyte(255);   // Tábla-záró

  // ---------------------------------------------------------------------------

  // Ha nem volt forgalom akkor nincs tovább
  _rekordDarab := _recno;
  if _recno>0 then EtetPack;
end;


// =============================================================================
                      procedure TMakePack.EtetPack;   // 14.
// =============================================================================


  (* E-trade tetelek: Tablasorszam: 14; mezödarab=4 ;

        1. DATUM        -  30 - 4
        2. PENZTAR      -  79 - 4
        3. ATADAS       -   6 - 3
        4. ATVETEL      -   7 - 3
  *)

var i,_mss: byte;
    _zz: integer;
    _zIrany: string;

begin
   _mezoss[1] := 30;
   _mezoss[2] := 79;
   _mezoss[3] := 7;
   _mezoss[4] := 6;

  Putbyte(14);  // Táblasorszam   // ETET
  Putword(_rekordDarab);  // a tételek rekordszáma;

  Putbyte(4);  // 4 mezõ van a tételekben;

  for i := 1 to 4 do
    begin
      _mss := _mezoss[i];
      putbyte(_mss);
    end;

  Putbyte(255); // FEJLÉC ZÁRÓ BYTE

  _zz := 1;
  while _zz<=_rekordDarab do
    begin
      _zPenztar := trim(_tarspt[_zz]);
      _zIrany   := chr(_addjel[_zz]);
      _zOsszeg  := _forint[_zz];

      Putstring(_zarodstring);
      Putstring(_zPenztar);

      if _zirany='+' then
        begin
          PutInteger(0);
          Putinteger(_zOsszeg);
        end else
        begin
          PutInteger(_zOsszeg);
          Putinteger(0);
        end;
      Putbyte(255);       // RekordZáró
      inc(_zz);
    end;
  Putbyte(255);          // Táblazáró
  inc(_tabladarab);
end;


// =============================================================================
                       procedure TMakePack.TradePack;   // 15.
// =============================================================================

(*

        E-trade fejek: Tablasorszam: 15; mezödarab=20 ;

        1. TIPUS         - 102 - 5
        2. BIZONYLATSZAM -  13 - 4
        3. KATEGORIA     - 132 - 4
        4. STARTDATUM    - 130 - 4
        5. ENDDATUM      - 131 - 4
        6. TELEFENSZAM   -  94 - 4
        7. RENDSZAM      - 133 - 4
        8. REFERENCEID   - 134 - 4
        9. TRANZAKCIO    - 135 - 4
       10. FIZETENDO     - 138 - 3
       11. PENZTAROSNEV  -  80 - 4
       12. DATUM         -  30 - 4
       13. IDO           -  49 - 4
       14. SZOLGALTATO   - 140 - 4
       15. SZOLGALTATAS  - 141 - 4
       16. UGYFELNEV     - 107 - 4
       17. UGYFELCIM     - 158 - 4
       18. TARSPENZTAR   -  79 - 4
       19. STORNO        -  86 - 1
       20. CIKKSZAM      - 142 - 1

       *)

begin
  _mezodarab := 20;
  _tablasorszam := 15;
  _tablanev := 'TRAD' + _farok;
  MatricaTabla.TableName := _tablanev;
  MatricaDbase.connected := true;
  if not MatricaTabla.Exists then
    begin
      Matricadbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM ' + _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_zarodstring+chr(39);
  with MatricaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      MatricaQuery.close;
      Matricadbase.close;
      exit;
    end;


   _mezoss[1]  := 102;  // tipus
   _mezoss[2]  := 13;   // bizonylatszam
   _mezoss[3]  := 132;  // kategoria
   _mezoss[4]  := 130;  // startdatum
   _mezoss[5]  := 131;  // enddatum
   _mezoss[6]  := 94;   // telefonszam
   _mezoss[7]  := 133;  // rendszam
   _mezoss[8]  := 134;  // referenciaid
   _mezoss[9]  := 135;  // tranzakcio
   _mezoss[10] := 138;  // fizetendo
   _mezoss[11] := 80;   // penztarosnev
   _mezoss[12] := 30;   // datum
   _mezoss[13] := 49;   // ido
   _mezoss[14] := 140;  // szolgáltato
   _mezoss[15] := 141;  // szolgaltatas
   _mezoss[16] := 107;  // ugyfelnev
   _mezoss[17] := 158;  // ugyfelcim
   _mezoss[18] := 79;   // tarspenztar
   _mezoss[19] := 86;   // storno
   _mezoss[20] := 142;  // cikkszam

 (* Beirja az address számot és a rekordok számát *)

  if _recno=0 then
    begin
      MatricaQuery.close;
      Matricadbase.close;
      exit;
    end;

   logirorutin(pchar('Trade csomagolasa'));

   PutByte(_tablasorszam);
   _rekordszam := _Spointer;
   _sPointer := _sPointer + 2;

   Putbyte(_mezodarab);

   _y := 1;
   while _y<=_mezodarab do
     begin
       Putbyte(_mezoss[_y]);
       inc(_y);
     end;

   Putbyte(_zByte);

   _rekordDarab := 0;
   while not MatricaQuery.Eof do
     begin
       with MatricaQuery do
         begin
           _datum        := FieldByName('DATUM').asString;
           _ido          := FieldByName('IDO').asString;
           _bizonylat    := trim(FieldByName('BIZONYLATSZAM').asString);
           _tipus        := FieldByNAme('TIPUS').asString;
           _fizetendo    := FieldByNAme('FIZETENDO').asInteger;
           _ugyfnev      := trim(FieldByNAme('UGYFELNEV').asString);
           _ugyfelcim    := trim(FieldByName('UGYFELCIM').AsString);
           _referid      := trim(FieldByNAme('REFERENCEID').asString);
           _prosnev      := trim(FieldByNAme('PENZTAROSNEV').asstring);
           _tranzakcio   := trim(FieldByNAme('TRANZAKCIO').asstring);
           _penztar      := trim(FieldByNAme('TARSPENZTAR').asString);
           _storno       := FieldByNAme('STORNO').asInteger;
           _cikkszam     := FieldByNAme('ELKULDVE').asInteger;
           _szolgaltato  := trim(FieldByNAme('SZOLGALTATO').asString);
           _szolgaltatas := trim(FieldByname('SZOLGALTATAS').asString);
           _rendszam     := trim(FieldByNAme('RENDSZAM').asString);
           _kategoria    := trim(FieldbyName('KATEGORIA').asstring);
           _startdatum   := trim(FieldByName('STARTDATUM').asString);
           _enddatum     := trim(FieldByNAme('ENDDATUM').asString);
           _telefonszam  := trim(FieldByNAme('TELEFONSZAM').AsString);
         end;

       putchar(_tipus);
       putstring(_bizonylat);
       putstring(_kategoria);
       putstring(_startdatum);
       putstring(_enddatum);
       putstring(_telefonszam);
       putstring(_rendszam);
       putstring(_referid);
       putstring(_tranzakcio);
       putinteger(_fizetendo);
       putstring(_prosnev);
       putstring(_datum);
       putstring(_ido);
       putstring(_szolgaltato);
       putstring(_szolgaltatas);
       putstring(_ugyfnev);
       putstring(_ugyfelcim);
       putstring(_penztar);
       putbyte(_storno);
       putbyte(_cikkszam);

       Putbyte(_zByte);
       inc(_rekordDarab);
       MatricaQuery.next;
     end;

   MatricaQuery.close;
   MatricaDbase.close;

   putbyte(_zByte);  // Tablazáró

   _aktSpointer := _spointer;  // spointer mentése
   _spointer := _rekordszam;

   putword(_rekorddarab);      // a rekordok számának beirása
   _spointer := _aktSpointer;  // spointer visszaállítása
   inc(_tabladarab);
end;




// =============================================================================
                     procedure TMakePack.FoglaloPack;     // 20.
// =============================================================================

var _y,_valdarab: byte;
    _nmezo,_kmezo: string;
    _vnem: array[0..4] of string;
    _kdb: array[0..4] of integer;

begin
  _pcs := 'SELECT * FROM FOGLALOKESZLET';
  _tablasorszam := 20;

  ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
      _recno := Recno;
    end;

  if _recno=0 then
    begin
      ValutaQuery.close;
      Valutadbase.close;
      exit;
    end;

  _valdarab := ValutaQuery.FieldbyName('VALDARAB').asInteger;
  if _valdarab=0 then
    begin
      ValutaQuery.close;
      Valutadbase.close;
      exit;
    end;

   logirorutin(pchar('Foglalok csomagolasa'));

   _y := 0;
   while _y<5 do
     begin
       _Nmezo := 'V' + chr(_y+48);
       _kMezo := 'K' + chr(_y+48);
       _vNem[_y] := '';
       _kdb[_y] := 0;
       inc(_y);
     end;

   _y := 0;
   while _y<_valdarab do
     begin
       _Nmezo := 'V' + chr(_y+48);
       _kMezo := 'K' + chr(_y+48);

       _vNem[_y] := ValutaQuery.FieldByName(_nMezo).asString;
       _kdb[_y] := ValutaQuery.FieldbyName(_kMezo).asInteger;
       inc(_Y);
     end;

   ValutaQuery.close;
   Valutadbase.close;

   Putbyte(_tablasorszam);
   Putword(1);
   Putbyte(11);

   _y := 115;
   while _y<=125 do
     begin
       putbyte(_y);
       inc(_y);
     end;

   PutByte(255);

   // ----------------------

   Putstring(_vnem[0]);
   Putstring(_vnem[1]);
   Putstring(_vnem[2]);
   Putstring(_vnem[3]);
   Putstring(_vnem[4]);

   Putinteger(_kdb[0]);
   Putinteger(_kdb[1]);
   Putinteger(_kdb[2]);
   Putinteger(_kdb[3]);
   Putinteger(_kdb[4]);

   Putbyte(_valdarab);
   Putbyte(255);   // rekordzáró

   Putbyte(255);   // táblazáró
   inc(_tablaDarab);
end;



// #############################################################################
//  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                    procedure TMakepack.MatricaKodolas;
// =============================================================================

var _ftd: integer;
    _irany: byte;

begin
   // _kellmatrica=1 tipusu pénztárgépeken kell:

   if _kellMatrica=0 then exit;

   with Matricadbase do
     begin
       Close;
       DatabaseName := 'c:\valuta\database\trade.fdb';
       Connected := True;
     end;

   // A napi összesitõben van a mai napi TRADE forgalom:

   _pcs := 'SELECT * FROM NAPIOSSZESITO' + _sorveg;
   _pcs := _pcs + 'WHERE DATUM='+chr(39) + _zaroDString + chr(39);

   with MatricaQuery do
     begin
       close;
       sql.clear;
       Sql.Add(_pcs);
       Open;
       First;
       _recno := recno;
     end;

   // Ha nem volt forgalom, nincs mainapi zárás sem

   if _recno=0 then
     begin
       MatricaQuery.close;
       Matricadbase.close;
       exit;
     end;

   logirorutin(pchar('E-trade bizonylatok csomagolasa'));

   // A zárónapi rekord mezõit beolvassa és zárja a napiosszesito táblát:

   with MatricaQuery do
     begin
       _nyito       := FieldByName('NYITO').asInteger;
       _matrica     := FieldByName('MATRICA').asInteger;
       _telefon     := FieldByName('TELEFON').asInteger;
       _vodafon     := FieldByNAme('VODAFON').asInteger;
       _telenor     := FieldbyName('TELENOR').asInteger;
       _paySafeCard := FieldByName('PAYSAFECARD').asInteger;
       _atadas      := FieldByNAme('ATADAS').AsInteger;
       _atvetel     := FieldByName('ATVETEL').asInteger;
       _zaro        := FieldByName('ZARO').AsInteger;
     end;

   MatricaQuery.close;
   Matricadbase.close;

   // -------------------- Innentõl indul az új csomag -------------------------

   _rekordDarab := 1;
   _Tablanev := 'TRAD'+midstr(_zarodstring,3,2)+midstr(_zarodstring,6,2);

   _pcs := 'SELECT * FROM '+ _tablanev + _sorveg;
   _pcs := _pcs + 'WHERE (DATUM='+chr(39) + _zaroDString + chr(39);
   _pcs := _pcs + ') AND (TIPUS=' + chr(39) + 'F' + chr(39) + ')';

   Matricadbase.Connected := True;
   with MatricaQuery do
     begin
       close;
       sql.Clear;
       Sql.Add(_pcs);
       Open;
       first;
       _recno := recno;
     end;

   if _recno>0 then
     begin
       _reKorddarab := 0;
       while not MatricaQuery.Eof do
         begin
           inc(_rekordDarab);
           _ftd := MatricaQuery.fieldByNAme('FIZETENDO').asInteger;
           _tpt := MatricaQuery.FieldByName('TARSPENZTAR').asString;

           _irany := 45;  // minusz
           if _ftd<0 then  // forditott elõjelek !!!!!
             begin
               _irany := 43;  // plusz +
               _ftd := abs(_ftd);
             end;

           _forint[_rekordDarab] := _ftd;
           _addjel[_rekordDarab] := _irany;
           _tarspt[_rekordDarab] := _tpt;
           MatricaQuery.Next;
         end;
     end;

   MatricaQuery.close;
   MatricaDbase.close;

   // --------------------------------------------------------------------------
   // A matrica csomagot elkésziti:

   EfejPack;
   TradePack;
end;


// =============================================================================
                      function TMakePack.Filekuldes: integer;
// =============================================================================


begin
 
  _pcs := 'DELETE FROM MEDIA';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO MEDIA (LOCALPATH,REMOTEFILE,REMOTEDIR)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39)+_localpath+chr(39)+',';
  _pcs := _pcs + chr(39) + _remotefile + chr(39) + ',';
  _pcs := _pcs + chr(39) + _remotedir + chr(39) + ')';
  ValutaParancs(_pcs);
  result := copyfiletoftprutin;
end;



// =============================================================================
                   procedure TMakepack.UgyfAndJogiPack;
// =============================================================================


begin

  _TablaNev := 'BF' + _farok;

  Valdatadbase.Connected := True;
  ValdataTabla.TableName := _tablanev;
  if not ValdataTabla.Exists then
    begin
      Valdatadbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+ _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM='+chr(39)+_zarodstring+chr(39)+') ';
  _pcs := _pcs + 'AND (UGYFELSZAM>0) AND (STORNO=1) ';
  _pcs := _pcs + 'AND ((UGYFELTIPUS='+chr(39)+'N'+chr(39)+') OR (';
  _pcs := _pcs + 'UGYFELTIPUS='+chr(39)+'J'+chr(39)+')) AND (';
  _pcs := _pcs + 'FIZETENDO>=300000)';

  ValdataDbase.connected := True;
  with ValdataQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      Valdataquery.close;
      ValdataDbase.close;
      exit;
    end;

  // ============== ügyfélszámok tömbökbe irása ================================

  while not valdataquery.eof do
    begin
      _ugyfszam := ValdataQuery.FieldByNAme('UGYFELSZAM').asInteger;
      _ugyftipus:= ValdataQuery.FieldByName('UGYFELTIPUS').asString;
      _megbizott:= ValdataQuery.FieldByname('MEGBIZOTT').asInteger;

      if _ugyftipus='J' then UTombbeir(_megbizott) else UTombbeIr(_ugyfszam);

      ValdataQuery.next;
    end;

  ValdataQuery.close;
  ValdataDbase.close;

  if (_udb=0) then exit; // NINCS EGYETLEN  ÜGYFÉL SEM A ZÁRÓ NAPON

  // ======================== ÜGYÉL REKORDOK ===================================

  _tablasorszam := 18;
  _mezodarab := 19;

  _mezoss[1] := 106;
  _mezoss[2] := 72;
  _mezoss[3] := 36;
  _mezoss[4] := 4;
  _mezoss[5] := 60;
  _mezoss[6] := 90;
  _mezoss[7] := 91;
  _mezoss[8] := 3;
  _mezoss[9] := 58;
  _mezoss[10]:= 75;
  _mezoss[11]:= 8;
  _mezoss[12]:= 92;
  _mezoss[13]:= 59;
  _mezoss[14]:= 162;
  _mezoss[15]:= 163;
  _mezoss[16]:= 166;
  _mezoss[17]:= 167;
  _mezoss[18]:= 168;
  _mezoss[19]:= 164;

  PutByte(_tablasorszam);

  _rekordszam := _sPointer;
  _sPointer   := _sPointer + 2;
  Putbyte(_mezodarab);

  _y := 1;
  while _y<=_mezodarab do
    begin
      Putbyte(_mezoss[_y]);
      inc(_y);
    end;

  Putbyte(_zByte); // fejléc záró
  _rekordDarab := 0;

  ValutaDbase.Connected := true;

  _pp := 1;
  while _pp<=_udb do
    begin
      _aktugyfelszam := _ugyrow[_pp];
      _feladva := 0;
      with ValutaQuery do
        begin
          Close;
          sql.clear;
          SqL.add('SELECT * FROM UGYFEL WHERE UGYFELSZAM='+inttostr(_aktugyfelszam));
          Open;
          _recno := recno;
          if _recno>0 then
            begin
              _feladva := FieldByNAme('FELADVA').asInteger;
            end;
        end;
      if _recno>0 then
        begin
          _feladva := ValutaQuery.FieldByname('FELADVA').asInteger;
        end;

      if _feladva<>949 then UgyfelPack;

      inc(_pp);
    end;

  ValutaQuery.close;
  ValutaDbase.close;
  putbyte(_zByte);  // Tablazáró

  _aktSpointer := _spointer;  // spointer mentése
  _spointer := _rekordszam;

  putword(_rekordDarab);      // a rekordok számának beirása
  _spointer := _aktSpointer;  // spointer visszaállítása

  inc(_tabladarab);
end;

// =============================================================================
                procedure TMakePack.UTombBeir(_usz: integer);
// =============================================================================

begin
  if _usz=0 then exit;

  inc(_udb);
  _ugyrow[_udb] := _usz;
end;

// =============================================================================
                       procedure TMakePack.UgyfelPack;   // 18.
// =============================================================================

(*

        Ugyfel fejek: Tablasorszam: 18; mezödarab=19 ;

        1. UGYFELSZAM       - 106 - 2
        2. NEV              -  72 - 4
        3. ELOZONEV         -  36 - 4
        4. ANYJANEVE        -   4 - 4
        5. LEANYKORI        -  60 - 4
        6. SZULETESIHELY    -  90 - 4
        7. SZULETESIIDO     -  91 - 4
        8. ALLAMPOLGAR      -   3 - 4
        9. LAKCIM           -  58 - 4
       10. OKMANYTIPUS      -  75 - 4
       11. AZONOSITO        -   8 - 4
       12. TARTOZKODASIHELY -  30 - 4
       13. LAKCIMKARTYA     -  59 - 4
       14. KULFOLDI         - 162 - 1
       15. KOZSZEREPLO      - 163 - 1
       16. IRSZAM           - 166 - 4
       17. VAROS            - 167 - 4
       18. UTCA             - 168 - 4
       19. ISO              - 164 - 1
       *)

begin
  with ValutaQuery do
    begin
      _ugyfelszam  := FieldByNAme('UGYFELSZAM').asInteger;
      _nev         := trim(Fieldbyname('NEV').asString);
      _elozonev    := trim(FieldByNAme('ELOZONEV').asstring);
      _anyjaneve   := trim(FieldByNAme('ANYJANEVE').AsString);
      _leanykori   := trim(FieldByNAme('LEANYKORI').AsString);
      _szulhely    := trim(FieldByNAme('SZULETESIHELY').AsString);
      _szulido     := trim(FieldByNAme('SZULETESIIDO').AsString);
      _allampolgar := trim(FieldByNAme('ALLAMPOLGAR').AsString);
      _lakcim      := trim(FieldByNAme('LAKCIM').AsString);
      _okmtipus    := trim(FieldByNAme('OKMANYTIPUS').asString);
      _azonosito   := trim(FieldByNAme('AZONOSITO').asString);
      _tarthely    := trim(FieldByNAme('TARTOZKODASIHELY').AsString);
      _lcimcard    := trim(FieldByNAme('LAKCIMKARTYA').AsString);
      _kulfoldi    := FieldByNAme('KULFOLDI').asInteger;
      _kozszerep   := FieldByNAme('KOZSZEREPLO').asInteger;
      _irszam      := trim(FieldByNAme('IRSZAM').AsString);
      _varos       := trim(FieldByNAme('VAROS').AsString);
      _utca        := trim(fieldByNAme('UTCA').AsString);
      _iso         := trim(FieldByNAme('ISO').AsString);
    end;

  putword(_ugyfelszam);
  putstring(_nev);
  putstring(_elozonev);
  putstring(_anyjaneve);
  putstring(_leanykori);
  putstring(_szulhely);
  putstring(_szulido);
  putstring(_allampolgar);
  putstring(_lakcim);
  putstring(_okmTipus);
  putstring(_azonosito);
  putstring(_tarthely);
  putstring(_lcimcard);
  putbyte(_kulfoldi);
  putbyte(_kozszerep);
  putstring(_irszam);
  putstring(_varos);
  putstring(_utca);
  putstring(_iso);

  putbyte(_zbyte);
  inc(_rekordDarab);
end;

// =============================================================================
                    procedure TMakePack.Ugyfelmegjeloles;
// =============================================================================

begin
  if _udb=0 then exit;

  Valutadbase.Connected := true;
  if valutatranz.InTransaction then valutatranz.commit;
  Valutatranz.StartTransaction;

  _pp := 1;
  while _pp<=_udb do
    begin
      _ugyfelszam := _ugyrow[_pp];
      _pcs := 'UPDATE UGYFEL SET FELADVA=949 WHERE UGYFELSZAM='+inttostr(_ugyfelszam);
      with ValutaQuery do
        begin
          Close;
          sql.clear;
          sql.Add(_pcs);
          Execsql;
        end;
      inc(_pp);
    end;
  ValutaTranz.commit;
  Valutadbase.close;
end;

// =============================================================================
                   procedure TMakePack.Tulajbedolgozas;
// =============================================================================

begin
  _tss := 0;
  Valutadbase.Connected := true;

  _tablanev := 'BF' + _farok;

  _pcs := 'SELECT * FROM ' + _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM=' + chr(39)+ _zaroDstring + chr(39)+') AND (';
  _pcs := _pcs + 'UGYFELTIPUS='+chr(39)+'J'+chr(39)+') AND (STORNO=1)';

  ValdataDbase.connected := True;
  with ValdataQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      _recno := recno;
     end;

  if _recno=0 then
    begin
      ValdataQuery.close;
      Valdatadbase.close;
      Valutadbase.close;
      exit;
    end;

  while not ValdataQuery.Eof do
    begin
      _plombaszam := trim(ValdataQuery.fieldByNAme('PLOMBASZAM').asString);
      _bizonylatszam := ValdataQuery.FieldByNAme('BIZONYLATSZAM').asString;
      _ugyfelszam := ValdataQuery.FieldByNAme('UGYFELSZAM').asInteger;
      _jogiszemnev := trim(ValdataQuery.FieldByName('UGYFELNEV').asString);
      _jogiszemcim := trim(ValdataQuery.FieldByNAme('UGYFELCIM').asString);

      _pcs := 'SELECT * FROM UJTULAJOK WHERE UGYFELSZAM='+inttostr(_ugyfelszam);
      with Valutaquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _recno := recno;
        end;

      if _recno=0 then
        begin
          ValutaQuery.close;
          Valutadbase.close;
          exit;
        end;

      while not ValutaQuery.Eof do
        begin
          _tulajnev := trim(ValutaQuery.FieldByNAme('TULAJNEV').asString);
          _elozonev := trim(ValutaQuery.FieldByNAme('ELOZONEV').AsString);
          _lakcim := trim(ValutaQuery.FieldByNAme('LAKCIM').AsString);
          _szulhely := trim(ValutaQuery.fieldByNAme('SZULHELY').AsString);
          _szulido := trim(ValutaQuery.fieldByNAme('SZULIDO').AsString);
          _allampolgar := trim(ValutaQuery.fieldByNAme('ALLAMPOLGAR').asString);
          _tarthely := trim(ValutaQuery.fieldByNAme('TARTHELY').AsString);
          _erdjelleg := trim(Valutaquery.FieldByNAme('ERDJELLEG').asString);
          _erdMertek := trim(ValutaQuery.fieldByNAme('ERDMERTEK').asString);
          _tkozszerep := ValutaQuery.FieldByNAme('TULKOZSZEREP').asInteger;

          TulajPacKSorBeiras;
          ValutaQuery.next;
        end;
      ValutaQuery.close;
      Valutadbase.close;

      ValdataQuery.Next;
    end;
  ValdataQuery.close;
  ValdataDbase.close;
  Tulajpack;
end;


// =============================================================================
               procedure TMakePack.TulajPackSorbeiras;
// =============================================================================

begin
  inc(_tss);
  _plbszam[_tss]     := _plombaszam;
  _bizszam[_tss]     := _bizonylatszam;

  _joginev[_tss]     := _jogiszemnev;
  _jogicim[_tss]     := _jogiszemcim;
  _tulnev[_tss]      := _tulajnev;
  _tulelonev[_tss]   := _elozonev;
  _tullakcim[_tss]   := _lakcim;
  _tulszulhely[_tss] := _szulhely;
  _tulszulido[_tss]  := _szulido;
  _tulallamp[_tss]   := _allampolgar;
  _tultarthely[_tss] := _tarthely;
  _tulerdjelleg[_tss]:= _erdjelleg;
  _tulerdmert[_tss]  := _erdMertek;
  _tulkozszer[_tss]  := _tkozszerep;
end;

// =============================================================================
                       procedure TMakePack.TulajPack;   // 16.
// =============================================================================

(*

        Tulaj fejek: Tablasorszam: 16; mezödarab= 15;

        1. DATUM            -  30 - 4
        2. BIZONYLATSZAM    -  13 - 4
        3. PLOMBASZAM       -  83 - 4
        4. JOGISZEMELYNEV   -  50 - 4
        5. TELEPHELYCIM     -  95 - 4
        6. UGYFELNEV        - 107 - 4
        7. ELOZONEV         -  36 - 4
        8. LAKCIM           -  58 - 4
        9. SZULETESIHELY    -  90 - 4
       10. SZULETESIIDO     -  91 - 4
       11. ALLAMPOLGAR      -   3 - 4
       12. TARTOZKODASIHELY -  92 - 4
       13. ERDJELLEG        - 170 - 4
       14. ERDMERTEK        - 170 - 4
       15. KOZSZEREPLO      - 163 - 1

       *)

begin
  _mezodarab := 15;
  _tablasorszam := 16;

   _mezoss[1]  := 30;  // datum
   _mezoss[2]  := 13;  // bizonylatszam
   _mezoss[3]  := 83;  // plombaszam
   _mezoss[4]  := 50;  // jogiszemelynev
   _mezoss[5]  := 95;  // telephelycim
   _mezoss[6]  := 107; // ugyfelnev
   _mezoss[7]  := 36;  // elozonev
   _mezoss[8]  := 58;  // lakcim
   _mezoss[9]  := 90;  // szuletesihely
   _mezoss[10] := 91;  // szuletesiido
   _mezoss[11] := 3;   // allampolgar
   _mezoss[12] := 92;  // tartozkodasihely
   _mezoss[13] := 170; // erdjelleg
   _mezoss[14] := 171; // erdmert
   _mezoss[15] := 163; // kozszereplo

 (* Beirja az address számot és a rekordok számát *)


   logirorutin(pchar('Tulaj csomagolasa'));

   PutByte(_tablasorszam);
   Putword(_tss);
   Putbyte(_mezodarab);

   _y := 1;
   while _y<=_mezodarab do
     begin
       Putbyte(_mezoss[_y]);
       inc(_y);
     end;

   Putbyte(_zByte);

   _zz := 1;
   while _zz<=_tss do
     begin
       _datum := _zaroDstring;
       _bizonylatszam := _bizszam[_zz];
       _plombaszam    := _plbszam[_zz];
       _jogiszemnev   := _joginev[_zz];
       _jogiszemcim   := _jogicim[_zz];
       _tulajnev      := _tulnev[_zz];
       _elozonev      := _tulelonev[_zz];
       _lakcim        := _tullakcim[_zz];
       _szulhely      := _tulszulhely[_zz];
       _szulido       := _tulszulido[_zz];
       _allampolgar   := _tulallamp[_zz];
       _tarthely      := _tultarthely[_zz];
       _erdjelleg     := _tulerdjelleg[_zz];
       _erdmertek     := _tulerdmert[_zz];
       _tKozszerep    := _tulkozszer[_zz];

       putstring(_datum);
       putstring(_bizonylatszam);
       putstring(_plombaszam);
       putstring(_jogiszemnev);
       putstring(_jogiszemcim);
       putstring(_tulajnev);
       putstring(_elozonev);
       putstring(_lakcim);
       putstring(_szulhely);
       putstring(_szulido);
       putstring(_allampolgar);
       putstring(_tarthely);
       putstring(_erdjelleg);
       putstring(_erdmertek);
       putbyte(_tkozszerep);

       Putbyte(_zByte);

       inc(_zz);
     end;

   putbyte(_zByte);  // Tablazáró
   inc(_tabladarab);
end;
end.

