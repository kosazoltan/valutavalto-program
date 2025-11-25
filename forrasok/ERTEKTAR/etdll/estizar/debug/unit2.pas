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

    VALUTATABLA  : TIBTable;
    VALUTADBASE  : TIBDatabase;
    VALUTATRANZ  : TIBTransaction;
    VALUTAQUERY  : TIBQuery;

    VALDATATABLA : TIBTable;
    VALDATAQUERY : TIBQuery;
    VALDATADBASE : TIBDatabase;
    VALDATATRANZ : TIBTransaction;
    EREDMENYLAP: TPanel;
    PSZALLQUERY: TIBQuery;
    PSZALLDBASE: TIBDatabase;
    PSZALLTRANZ: TIBTransaction;

    procedure CsomagoloGombClick(Sender: TObject);

    procedure BFPack;
    procedure BTPack;
    procedure CimtPack;
    procedure NarfPack;
    procedure WafaPack;
    procedure WuniPack;
    procedure WzarPack;

    Procedure KezdPack;
    procedure EfejPack;
    procedure EtetPack;

    procedure ElohoGombClick(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);

    procedure FormActivate(Sender: TObject);
    procedure HonapDisplay;
    procedure KovhoGombClick(Sender: TObject);

    procedure MegsemZarGombClick(Sender: TObject);
    procedure PutByte(_byte: byte);
    procedure Putword(_word: word);
    procedure PutInteger(_int: integer);
    procedure Putstring(_string: string);
    procedure Putchar(_char: string);

    procedure AllDirDelete(_adir: string);
  
    procedure Csuszkalas;

    function IrodaKod(_irodaSzam: word): string;
    function Kitkod(_kdatum: string):string;
    function Nulele(_int: byte): string;
    function ZArasBekuldese: boolean;
    procedure FTPszerverbeBelep;
    function Vaninternet: boolean;
    function Jottvalasz: boolean;

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


  _biniras: file of byte;

  _mezoss: array[1..29] of byte;

  _valutaPath  : string = 'c:\ERTEKTAR\database\valuta.fdb';
  _valdataPath : string = 'c:\ERTEKTAR\database\valdata.fdb';

  _host        : string;
  _ftpPort     : integer = 21100;
  _userId      : string  = 'ebc-10%';
  _ftpPassword : string  = 'klc+45%';

  _bytetomb    : array[1..131072] of byte;
  _zByte       : byte = 255;
  _sorveg      : string = chr(13)+chr(10);

  _hNet,_hFTP  : HINTERNET;
  _hsearch     : HINTERNET;
  _findData    : WIN32_FIND_DATA;


  _ertektarszam,_tablasorszam,_tetel,_storno: byte;
  _ptarszam,_mozgas,_mezodarab: byte;

  _width,_height,_targyev,_targyhonap,_targynap,_kartya: word;

  _aktdnem,_pcs,_megnyitottnap,_farok,_penztar,_homepenztarkod: string;
  _evhos,_zarodstring,_okFile,_kit,_fileAlap,_csomagfile: string;
  _markerFile,_markerPath,_csomagPath,_ido,_bizonylat,_tipus: string;
  _tranztip,_zPenztar,_tablanev,_datum,_stbiz,_elojel,_kftnev: string;
  _localpath,_remotefile,_tortresz,_prosnev,_idkod: string;
  _szallnev,_plomba: string;

  _csPos,_code,_ptszam,_tabladarab,_sPointer,_mresult,_recno,_aktspointer: integer;
  _bankjegy,_osszes,_rekordszam,_rekordDarab,_kezdij,_atadas,_atvetel: integer;
  _arfolyam,_elszamarf,_forintertek,_nyito,_zaro,_ellatmany,_elszarf: integer;

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
  // Beolvassa: penztárszám, gépfunkcio, kellmatrica, megnyitottnap

  ValutaDbase.Connected := true;

  _pcs := 'SELECT * FROM PENZTAR';
  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      _homepenztarkod := trim(FieldByName('PENZTARKOD').asString);

      Close;
      Sql.Clear;
      Sql.Add('SELECT * FROM HARDWARE');
      Open;

      _megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').asstring);
      _kftnev        := trim(FieldByName('KFTNEV').asString);
      _prosnev       := trim(FieldByName('PENZTAROSNEV').AsString);
      _idkod         := trim(FieldByName('IDKOD').AsString);
      _host          := trim(FieldByNAme('HOST').AsString);

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
    _dstring   : string;
    _oke: boolean;

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
      ShowMessage('A megjelölt nap a jövõben lesz !');
      ModalResult := 2;
      Exit;
    end;

  _farok := midstr(_zarodstring,3,2)+midstr(_zarodstring,6,2);

  // Ez a pénztár száma:

  val(_homepenztarkod,_ertektarszam,_code);
  if _code<>0 then _ertektarszam := 0;

  if _ertektarszam=0 then
    begin
      Showmessage('ÉRVÉNYTELEN A ÉRTÉKTÁRSZÁM');
      Modalresult := 2;
      exit;
    end;

  _okFile := 'OK'+inttostr(_ERTEKTARSzam)+'.OK';

  // ---------------------------------------------------------------------------
  // Meghatározza a csomag kódolt nevét és path-ját

  _fileAlap   := Irodakod(_ertektarszam);       // irodaszámból 8 tagu betüstring
  _kit        := KitKod(_zaroDString);    // a dátumból a kiterjesztés

  _csomagFile := _fileAlap + '.' + _kit;
  _markerFile := _fileAlap + '.m';

  _markerPath := 'C:\ERTEKTAR\out\' + _markerFile;
  _csomagPath := 'C:\ERTEKTAR\out\' + _csomagFile;

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

  BfPack;
  BtPack;
  CimtPack;
  NarfPack;

  WafaPack;
  WuniPack;
  WzarPack;
  KezdPack;
  EfejPack;
  EtetPack;

  //  A teljes csomagot lezárjuk 255-nel:

  putbyte(_zByte);

  // Beirjuk a feltöltött táblák darabszámát:

  _bytetomb[3] := _tabladarab;

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
  _oke := ZarasBekuldese;

  with Eredmenylap do
    begin
      top := 8;
      left := 8;
    end;

  if _oke then
    begin
      Eredmenylap.caption := 'Esti zárás sikeresen beküldve';
      EredmenyLap.Color := clGreen;
      Eredmenylap.Font.Color := clWhite;
      _mresult := 1;
    end else
    begin
      Eredmenylap.caption := 'Sikertelen csomagküldés';
      EredmenyLap.Color := clRed;
      Eredmenylap.Font.Color := clRed;
      _mResult := 2;
    end;

  Eredmenylap.Visible := true;
  Eredmenylap.repaint;
  sleep(3500);

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

   if (_ev<2000) or (_ev>2036) then exit;

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

var _slen,_byte,_y: byte;

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
  result := false;
  if not Vaninternet then
    begin
      Memo1.lines.add('Nincs internet !');
      exit;
    end;

  _hNet := InternetOpen('Szerverbe',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if _hNet=nil then
    begin
      Memo1.Lines.add('Nem találom a WININET.DLL könyvtárt !');
      Exit;
    end;

  FTPszerverbeBelep;
  if _hFTP=Nil then
    begin
      InternetCLoseHandle(_hNet);
      exit;
    end;

  result :=  FTPSetCurrentDirectory(_hFTP,pchar('\IN'));
  if not result then
    begin
      Memo1.Lines.add('Nem tudok belépni az IN könyvtárba');
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  // ---------------------------------------------------------------------------

  _localpath  := _csomagPath;
  _Remotefile := _csomagFile;

  result := FtpPutFile(_hFTP,pChar(_localPath),pChar(_remoteFile),
                                              FTP_TRANSFER_TYPE_BINARY,0);

  if result then
    begin
      _localPath  := _markerPath;
      _remotefile := _markerfile;
      result := FtpPutFile(_hFTP,pChar(_localPath),pChar(_remoteFile),
                                                 FTP_TRANSFER_TYPE_BINARY,0);
    end;

  if not result then exit;

  Memo1.Lines.Add('Az esti zárást beküldtem');
  mEMO1.Lines.Add('Várok a visszaigazolásra');
  if result then
    begin
      _recount := 5;
      while _recount>0 do
        begin
          Csuszkalas;
          result := Jottvalasz;
          if result then exit;
          sleep(2500);
          dec(_recount);
        end;
    end;

  InternetCLosehandle(_hFTP);
  InternetCloseHandle(_hnet);
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
                      procedure Tmakepack.FTPszerverbeBelep;
// =============================================================================

begin
  _hFtp := Nil;

  // ---------------------------------------------------------------------------

  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
           Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  // ---------------------------------------------------------------------------

  if _hFTP=nil then
    begin
      Memo1.lines.add('A központi szerver nem érhetõ el !');
      InternetCloseHandle(_hNet);
    end;
end;

// =============================================================================
                 function TMakePack.Vaninternet: boolean;
// =============================================================================

var
    _dwConnType: integer;

begin

   Result := False;
   TRY
     _dwConntype := 7;
     if InternetGetConnectedState(@_dwConnType,0) then result := true;
   except
   end;
end;



// =============================================================================
                       function TmakePack.Jottvalasz: boolean;
// =============================================================================

begin
  result := False;
  _hSearch := FtpFindFirstFile(
              _hFtp,
              pchar('\OUT\'+ _okFile),
              _findData,
              0,0);
  if _hsearch<>NIL then
    begin
      InternetCloseHandle(_hSearch);
      result := true;
    end;
end;



//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//$$$$$$$$$$$$$$$$$$$$$          PACKOK       $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                           procedure TmakePack.BfPack;   // 2.
// =============================================================================

(* Blokkfej: Tablasorszam: 2; mezödarab= 14;

        1. DATUM            -  30 - 4
        2. IDO              -  49 - 4
        3. BIZONYLATSZAM    -  13 - 4
        4. TIPUS            - 102 - 5
        5. OSSZESEN         -  76 - 3
        6. TETEL            - 101 - 1
        7. PENZTAR          -  79 - 4
        8. TRBPENZTAR       - 105 - 4
        9. STORNO           -  86 - 1
       10. STORNOBIZONYLAT  -  87 - 4
       11. PENZTAROSNEV     -  80 - 4
       12. IDKOD            -  48 - 4
       13. PLOMBASZAM       -  83 - 4
       14. SZALLITONEV      -  88 - 4

       *)

var
    _trbPtar: string;
    _y: word;

begin
  _tablasorszam := 2;
  _mezodarab := 14;

  _mezoss[1] := 30;
  _mezoss[2] := 49;
  _mezoss[3] := 13;
  _mezoss[4] := 102;
  _mezoss[5] := 76;
  _mezoss[6] := 101;
  _mezoss[7] := 79;
  _mezoss[8] := 105;
  _mezoss[9] := 86;
  _mezoss[10]:= 87;
  _mezoss[11]:= 80;
  _mezoss[12]:= 48;
  _mezoss[13]:= 83;
  _mezoss[14]:= 88;

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
   Pszalldbase.connected := true;
   while not ValdataQuery.Eof do
     begin
       with ValdataQuery do
         begin
           _datum     := FieldByName('DATUM').asString;
           _ido       := FieldByName('IDO').asString;
           _bizonylat := trim(FieldByName('BIZONYLATSZAM').asString);
           _tipus     := FieldByNAme('TIPUS').asString;
           _osszes    := FieldByNAme('FORINTERTEK').asInteger;
           _tetel     := FieldByNAme('TETEL').asInteger;
           _penztar   := trim(FieldByNAme('TARSPENZTARKOD').asString);
           _trbptar   := trim(FieldByNAme('TRBPENZTAR').asstring);
           _STORNO    := FieldByNAme('STORNO').asInteger;
           _stBiz     := trim(FieldByNAme('STORNOBIZONYLAT').asstring);
         end;

       _szallnev := '';
       _plomba   := '';

       _pcs := 'SELECT * FROM WPENZSZALLITAS' + _sorveg;
       _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39)+_bizonylat+chr(39);
       with PszallQuery do
         begin
           Close;
           Sql.clear;
           sql.add(_pcs);
           Open;
           _recno := recno;
         end;

       if _recno>0 then
         begin
           _szallnev := trim(PszallQuery.FieldByName('SZALLITONEV').asstring);
           _plomba   := trim(Pszallquery.FieldByNAme('PLOMBASZAM').AsString);
         end;
       Pszallquery.close;

       putstring(_datum);
       putstring(_ido);
       putstring(_bizonylat);
       putchar(_tipus);
       putInteger(_osszes);

       putbyte(_tetel);

       putstring(_penztar);
       putstring(_trbPtar);

       Putbyte(_storno);
       Putstring(_stBiz);

       Putstring(_prosnev);
       Putstring(_idkod);

       Putstring(_plomba);
       Putstring(_szallnev);

       Putbyte(_zByte);
       inc(_rekordDarab);
       ValdataQuery.next;
     end;

   ValdataQuery.close;
   ValdataDbase.close;
   PszallDbase.close;

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

(* Blokktetel: Tablasorszam: 3; mezödarab= 10;

        1. BIZONYLATSZAM        -  13 - 4
        2. DATUM                -  30 - 4
        3. VALUTANEM            - 126 - 4
        4. BANKJEGY             -   9 - 3
        5. ARFOLYAM             -   5 - 3
        6. ELSZAMOLASIARFOLYAM  -  38 - 3

        7. FORINTERTEK          -  41 - 3
        8. ELOJEL               -  35 - 5

        9. STORNO               -  86 - 1
       10. TORTRESZ             - 160 - 4


       *)


var _y: word;

begin
  _tablasorszam := 3;
  _mezodarab := 10;

  _mezoss[1] := 13;
  _mezoss[2] := 30;
  _mezoss[3] := 126;
  _mezoss[4] := 9;
  _mezoss[5] := 5;
  _mezoss[6] := 38;

  _mezoss[7] := 41;
  _mezoss[8] := 35;

  _mezoss[9]:= 86;
 _mezoss[10]:= 160;


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
           _aktdnem     := FieldByName('VALUTANEM').asString;
           _bizonylat   := trim(FieldByName('BIZONYLATSZAM').asString);
           _Bankjegy    := FieldByNAme('BANKJEGY').asInteger;
           _arfolyam    := FieldByNAme('ARFOLYAM').asInteger;
           _elszarf     := FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
           _forintertek := FieldByNAme('FORINTERTEK').asInteger;
           _elojel      := FieldByNAme('ELOJEL').asString;
           _storno      := FieldByNAme('STORNO').asInteger;
           _tortresz    := trim(FieldByNAme('TORTRESZ').AsString);
         end;

       putstring(_bizonylat);
       putstring(_datum);
       putstring(_aktdnem);
       putinteger(_bankjegy);
       putinteger(_arfolyam);
       putinteger(_elszarf);

       putInteger(_forintertek);
       putChar(_elojel);

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
    _c1,_c2,_c3,_c4,_c5,_c6,_c7,_c8,_c9,_c10,_c11,_c12,_c13,_c14,_y: word;

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
           _datum   := trim(FieldByName('DATUM').asString);
           _aktdnem := FieldByName('VALUTANEM').asString;
           _osszes  := FieldByName('BANKJEGY').asInteger;
           _c1      := FieldByNAme('CIMLET1').asInteger;
           _c2      := FieldByNAme('CIMLET2').asInteger;
           _c3      := FieldByNAme('CIMLET3').asInteger;
           _c4      := FieldByNAme('CIMLET4').asInteger;
           _c5      := FieldByNAme('CIMLET5').asInteger;
           _c6      := FieldByNAme('CIMLET6').asInteger;
           _c7      := FieldByNAme('CIMLET7').asInteger;
           _c8      := FieldByNAme('CIMLET8').asInteger;
           _c9      := FieldByNAme('CIMLET9').asInteger;
           _c10     := FieldByNAme('CIMLET10').asInteger;
           _c11     := FieldByNAme('CIMLET11').asInteger;
           _c12     := FieldByNAme('CIMLET12').asInteger;
           _c13     := FieldByNAme('CIMLET13').asInteger;
           _c14     := FieldByNAme('CIMLET14').asInteger;
         end;

       putstring(_datum);
       putstring(_aktdnem);
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
                           procedure TmakePack.NarfPack;   // 4.
// =============================================================================

(* Napiárfolyam: Tablasorszam: 4; mezödarab= 5;

        1. DATUM                -  30 - 4
        2. VALUTANEM            - 126 - 4

        3. ELSZAMOLASIARFOLYAM  -  38 - 3
        4. NYITO                -  73 - 3
        5. ZARO                 - 128 - 3
       *)

var _y: word;       

begin
  _tablasorszam := 4;
  _mezodarab := 5;

  _mezoss[1] := 30;
  _mezoss[2] := 126;

  _mezoss[3] := 38;
  _mezoss[4] := 73;
  _mezoss[5] := 128;

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
           _aktdnem   := FieldByName('VALUTANEM').asString;
           _elszamarf := FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
           _nyito     := FieldByNAme('NYITO').asInteger;
           _zaro      := FieldByNAme('ZARO').asInteger;
         end;

       putstring(_datum);
       putstring(_aktdnem);
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
                           procedure TmakePack.WafaPack;   // 6
// =============================================================================

(* Áfavisszatérítés: Tablasorszam: 6; mezödarab= 6;

        1. DATUM            -  30 - 4
        2. PENZTARSZAM      -  82 - 2
        3. SORSZAM          -  85 - 4
        4. ELLATMANY        -  34 - 3
        5. TRANZAKCIOTIPUS  - 103 - 4
        6. STORNO           -  86 - 1

       *)

var _ptarszam,_y: word;

begin
  _tablasorszam := 6;
  _mezodarab := 6;

  _mezoss[1] := 30;
  _mezoss[2] := 82;
  _mezoss[3] := 85;
  _mezoss[4] := 34;
  _mezoss[5] := 103;
  _mezoss[6] := 86;

  _tablanev := 'WUNI' + _farok;

  Valdatadbase.Connected := true;
  ValdataTabla.TableName := _tablanev;
  if not ValdataTabla.Exists then
    begin
      Valdatadbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+ _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM='+chr(39)+_zarodstring+chr(39)+') ';
  _pcs := _pcs + 'AND (BIZTIPUS='+chr(39)+'WA'+chr(39)+')';

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
           _penztar   := trim(FieldByName('PENZTAR').asString);
           _bizonylat := trim(FieldByNAme('BIZONYLAT').asString);
           _bankjegy  := FieldByName('BANKJEGY').asInteger;
           _tranztip  := trim(FieldByName('BIZTIPUS').asString);
           _storno    := FieldbyName('STORNO').asInteger;
         end;

       val(_penztar,_ptarszam,_code);
       if _code<>0 then _ptarszam := 0;

       putstring(_datum);
       putword(_ptarszam);
       putstring(_bizonylat);
       putinteger(_bankjegy);
       putstring(_tranztip);
       putbyte(_storno);

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

(* Western Union: Tablasorszam: 8; mezödarab= 7;

        1. DATUM            -  30 - 4
        2. PENZTARSZAM      -  82 - 2
        3. SORSZAM          -  85 - 4
        4. VALUTANEM        - 126 - 4
        5. BANKJEGY         -   9 - 3
        6. TRANZAKCIOTIPUS  - 103 - 4
        7. STORNO           -  86 - 1

       *)

var _ptarszam,_y: word;

begin
  _tablasorszam := 8;
  _mezodarab := 7;

  _mezoss[1] := 30;
  _mezoss[2] := 82;
  _mezoss[3] := 85;
  _mezoss[4] := 126;
  _mezoss[5] := 9;
  _mezoss[6] := 103;
  _mezoss[7]:= 86;

  _tablanev := 'WUNI' + _farok;

  Valdatadbase.Connected := true;
  ValdataTabla.TableName := _tablanev;
  if not ValdataTabla.Exists then
    begin
      Valdatadbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+ _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM='+chr(39)+_zarodstring+chr(39)+') ';
  _pcs := _pcs + 'AND (BIZTIPUS='+chr(39)+'WU'+chr(39)+')';

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
           _penztar   := trim(FieldByName('PENZTAR').asstring);
           _bizonylat := trim(FieldByNAme('BIZONYLAT').asString);
           _aktdnem   := FieldByNAme('VALUTANEM').asString;
           _bankjegy  := FieldByNAme('BANKJEGY').asInteger;
           _tranztip  := FieldByNAme('BIZTIPUS').asString;
           _storno    := FieldbyName('STORNO').asInteger;
         end;

       val(_penztar,_ptarszam,_code);
       if _code<>0 then _ptarszam := 0;

       putstring(_datum);
       putword(_ptarszam);
       putstring(_bizonylat);
       putstring(_aktdnem);
       putinteger(_bankjegy);
       putstring(_tranztip);
       putbyte(_storno);


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

(* Afa-Wuni záró: Tablasorszam: 9; mezödarab= 13;

        1. DATUM          -  30 - 4

        2. USDNYITO       - 113 - 3
        3. HUFNYITO       -  46 - 3
        4. AFANYITO     -  66 - 3


        5. USDBE          - 111 - 3
        6. HUFBE          -  44 - 3
        7. AFABE        -  64 - 3


        8. USDKI          - 112 - 3
        9. HUFKI          -  45 - 3
       10. AFAKI        -  65 - 3


       11. USDZARO        - 114 - 3
       12. HUFZARO        -  47 - 3
       13. AFAZARO      -  67 - 3


       *)


var

    _usdnyito,_usdbe,_usdki,_usdzaro: integer;
    _hufnyito,_hufbe,_hufki,_hufzaro: integer;
    _afanyito,_afabe,_afaki,_afazaro: integer;
    _y: word;
   
begin
  _tablasorszam := 9;
  _mezodarab := 13;

  _mezoss[1] := 30;
  _mezoss[2] := 113;
  _mezoss[3] := 46;
  _mezoss[4] := 66;
  _mezoss[5] := 111;
  _mezoss[6] := 44;
  _mezoss[7] := 64;
  _mezoss[8] := 112;
  _mezoss[9] := 45;
  _mezoss[10]:= 65;
  _mezoss[11]:= 114;
  _mezoss[12]:= 47;
  _mezoss[13]:= 67;

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
       _AFAnyito := FieldByName('AFANYITO').asInteger;

       _usdbe := FieldByNAme('USDBEVETEL').asInteger;
       _hufbe := FieldByNAme('HUFBEVETEL').asInteger;
       _afabe := FieldByNAme('AFABEVETEL').asInteger;

       _usdki := FieldByNAme('USDKIADAS').asInteger;
       _hufki := FieldByNAme('HUFKIADAS').asInteger;
       _afaki := FieldByNAme('AFAKIADAS').asInteger;

       _usdzaro := FieldByNAme('USDZARO').asInteger;
       _hufzaro := FieldByNAme('HUFZARO').asInteger;
       _afazaro := FieldByNAme('AFAZARO').asInteger;

     end;

   putstring(_datum);

   putinteger(_usdnyito);
   putinteger(_hufnyito);
   putinteger(_afanyito);

   putinteger(_usdbe);
   putinteger(_hufbe);
   putinteger(_afabe);

   putinteger(_usdki);
   putinteger(_hufki);
   putinteger(_afaki);

   putinteger(_usdzaro);
   putinteger(_hufzaro);
   putinteger(_afazaro);

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

var _y: word;       

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
  _pcs := _pcs + 'WHERE (DATUM='+CHR(39)+_zarodstring+chr(39)+')';

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
           _bankjegy   := FieldByName('BANKJEGY').asInteger;
           _penztar   := trim(FieldbyNAme('PENZTAR').asString);
           _bizonylat := trim(FieldByNAme('BIZONYLAT').asString);
         end;

       putstring(_datum);
       putchar(_elojel);
       putinteger(_bankjegy);
       putstring(_penztar);
       putstring(_bizonylat);
       if _elojel='-' then putbyte(3) else putbyte(4);

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

        E-trade fejek: Tablasorszam: 13; mezödarab= 5;

        1. DATUM        -  30 - 4
        2. NYITO        -  73 - 3
        3. ATADAS       -   6 - 3
        4. ATVETEL      -   7 - 3
        5. ZARO         - 128 - 3

       *)

var
    i,_mss: byte;

begin
  _TABLANEV :=  'EDAT'+_farok;

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
  _nyito   := ValdataQuery.fieldByNAme('NYITO').asInteger;
  _zaro    := ValdataQuery.FieldByNAme('ZARO').asInteger;
  _atadas  := ValdataQuery.FieldByNAme('KIADAS').asInteger;
  _atvetel := ValdataQuery.FieldByNAme('BEVETEL').asInteger;

  ValdataQuery.close;
  ValdataDbase.close;

  _mezoDarab := 5;
  _tablasorszam := 13;

   _mezoss[1] := 30;
   _mezoss[2] := 73;
   _mezoss[3] := 6;
   _mezoss[4] := 7;
   _mezoss[5] := 128;

 (* Beirja az address számot és a rekordok számát *)

   inc(_tabladarab);

  Putbyte(13);  // táblasorszám = 18 = EFEJ;
  Putword(1);   // a fejben egyetlen rekord van

  Putbyte(_mezodarab);   // mezõdarab;

  for i := 1 to _mezodarab do
    begin
      _mss := _mezoss[i];
      putbyte(_mss);
    end;

  PutByte(255);  // fejléczáró byte

  Putstring(_zarodstring);
  Putinteger(_nyito);
  Putinteger(_atadas);
  Putinteger(_atvetel);
  Putinteger(_zaro);

  Putbyte(255);   // rekordzáró
  Putbyte(255);   // Tábla-záró

  // ---------------------------------------------------------------------------

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

var _exPt,_exej: array[1..200] of string;
    _exBj: array[1..200] of integer;
    i,_mss: byte;
    _zz: word;
    _zBankjegy: integer;

begin
  _tablasorszam := 14;
  _tablanev := 'EKER' + _farok;

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

  _rekordDarab  := 0;
  while not ValdataQuery.Eof do
    begin
      inc(_rekordDarab);

      _penztar := trim(ValdataQuery.fieldByNAme('PENZTAR').asString);
      _elojel  := ValdataQuery.FieldByNAme('ELOJEL').asstring;
      _bankjegy := ValdataQuery.FieldByName('BANKJEGY').asInteger;

      _exPt[_rekordDarab] := _penztar;
      _exEj[_rekordDarab] := _elojel;
      _exBj[_rekordDarab] := _bankjegy;
      ValdataQuery.next;
    end;
  ValdataQuery.close;
  ValdataDbase.close;
  if _rekordDarab=0 then exit;

  // -------------------------------------

  _mezodarab := 4;

  _mezoss[1] := 30;
  _mezoss[2] := 79;
  _mezoss[3] := 7;
  _mezoss[4] := 6;

  Putbyte(_tablasorszam);  // Táblasorszam   // ETET
  Putword(_rekordDarab);  // a tételek rekordszáma;

  Putbyte(_MEZODARAB);  // 4 mezõ van a tételekben;

  for i := 1 to _mezodarab do
    begin
      _mss := _mezoss[i];
      putbyte(_mss);
    end;

  Putbyte(255); // FEJLÉC ZÁRÓ BYTE

  _zz := 1;
  while _zz<=_rekordDarab do
    begin
      _zPenztar  := _exPt[_zz];
      _elojel    := _exEj[_zz];
      _zbankjegy := _exBj[_zz];

      Putstring(_zarodstring);
      Putstring(_zPenztar);

      if _elojel='+' then
        begin
          PutInteger(0);
          Putinteger(_zBankjegy);
        end else
        begin
          PutInteger(_zBankjegy);
          Putinteger(0);
        end;
      Putbyte(255);       // RekordZáró
      inc(_zz);
    end;

  Putbyte(255);          // Táblazáró
  inc(_tabladarab);
end;






end.
