unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StrUtils, IBQuery, IBDatabase, DB, IBCustomDataSet,
  IBTable, StdCtrls, DateUtils, Buttons, ComCtrls, idGlobal,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP;

type
  TForm1 = class(TForm)

  Kilepo      : TTimer;

  ReceptTabla : TIBTable;
  ReceptDbase : TIBDatabase;
  ReceptTranz : TIBTransaction;
  ReceptQuery : TIBQuery;

  DatumPanel  : TPanel;
  UzenoPanel  : TPanel;

  K1          : TShape;
  K2          : TShape;
  K3          : TShape;
  K4          : TShape;
  K5          : TShape;
  K6          : TShape;
  k7          : TShape;
  k8          : TShape;
  k9          : TShape;
  k10         : TShape;
  k11         : TShape;
  k12         : TShape;
  k13         : TShape;
  k14         : TShape;
  k15         : TShape;
  k16         : TShape;
  k17         : TShape;
  k18         : TShape;
  k19         : TShape;
  k20         : TShape;
  k21         : TShape;
  k22         : TShape;
  k23         : TShape;
  k24         : TShape;
  k25         : TShape;
  k26         : TShape;
  k27         : TShape;
  k28         : TShape;
  k29         : TShape;
  k30         : TShape;
  k31         : TShape;
  k32         : TShape;
  k33         : TShape;
  k34         : TShape;
  k35         : TShape;
  k36         : TShape;
  k37         : TShape;
  k38         : TShape;
  k39         : TShape;
  k41         : TShape;
  k40         : TShape;
  k42         : TShape;
  k43         : TShape;
  K44         : TShape;
  k45         : TShape;
  k46         : TShape;
  k47         : TShape;
  k48         : TShape;
  k49         : TShape;
  k51         : TShape;
  k50         : TShape;
  k53         : TShape;
  k52         : TShape;
  k55         : TShape;
  k54         : TShape;

  Shape2      : TShape;
  Shape6      : TShape;
  Shape7      : TShape;
  Shape8      : TShape;
  Shape10     : TShape;

  KilepoGomb  : TBitBtn;
  TalcaraGomb : TBitBtn;

  ARTCDbase   : TIBDatabase;
  ARTCTranz   : TIBTransaction;
  ARTCQuery   : TIBQuery;

  TempQuery   : TIBQuery;
  TempDbase   : TIBDatabase;
  TempTranz   : TIBTransaction;

  DayBookQuery: TIBQuery;
  DayBookDbase: TIBDatabase;
  DayBookTranz: TIBTransaction;

  BigMenet    : TTimer;
  Figyelo     : TTimer;
    SEGEDGOMB: TBitBtn;
    SEGEDPANEL: TPanel;
    Label1: TLabel;
    SEGEDVISSZAGOMB: TBitBtn;
    Shape1: TShape;
    NAPIFORGGOMB: TBitBtn;
    TABLOGOMB: TBitBtn;
    Shape3: TShape;
    MENTESGOMB: TBitBtn;
    Panel1: TPanel;
    Shape4: TShape;

   // ----------------------------------------------------

   procedure BigMenetTimer(Sender: TObject);
   procedure ColorKor;
   procedure CsomagFeldolgozas;
   procedure Datumkijelzes;
   procedure daybookParancs(_dpath,_ukaz: string);
   procedure DayRegister(_kelt: string;_ptsz: integer);
   procedure Delemaildir;
   procedure EzUjnap;
   procedure EgyebFeladatok;
   procedure EmailKuldes;
   procedure FigyeloTimer(Sender: TObject);
   procedure FormActivate(Sender: TObject);
   procedure FormClick(Sender: TObject);
   procedure GetDatumIdo;
   procedure KilepoGombClick(Sender: TObject);
   procedure KilepoTimer(Sender: TObject);
   procedure KorClear;
   procedure KortombBetolto;
   procedure MakeFDBFile(_fdbPath: string);
   procedure OkmanyCopy;
   procedure OkmanySaveDre;
   procedure PenztarBeolvasas;
   procedure ReceptParancs(_ukaz: string);
   procedure SegedMenu;
   procedure StatusBeolvaso;
   procedure TalcaraGombClick(Sender: TObject);
   procedure TempParancs(_ukaz: string);

   function BejelentesDekodolo(_kodstr: string): String;
   function DatumbolString(_dstring: string): string;
   function HunDatetostr(_d: TDateTime): string;
   function Hunstrtodate(_s: string): TDatetime;
   function KitDekod(_kdatkod: string): string;
   function Nulele(_nn: integer): string;
   function PenztarDekod(_szams: string):integer;
   function TalaltMFilet: boolean;
   function VanPenztar(_ptsz:integer):integer;
   function WinExecAndWait32(Path: PChar; Visibility: Word): integer;
    procedure SEGEDGOMBClick(Sender: TObject);
    procedure SEGEDVISSZAGOMBClick(Sender: TObject);
    procedure NAPIFORGGOMBClick(Sender: TObject);
    procedure TABLOGOMBClick(Sender: TObject);
    procedure MENTESGOMBClick(Sender: TObject);
 


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var

  Form1: TForm1;

  _pacs: pchar;

  // ----------------------- STRING ARRAYS -------------------------------------

  _napnev: array[1..7] of string = ('hétfõ','kedd','szerda','csütörtök','péntek',
                     'szombat','vasárnap');

  _honev : array[1..12] of string = ('január','február','március','április','május','junius',
                    'július','augusztus','szeptember','október','november','december');

  _inputdirectory : string = 'C:\RECEPTOR\MAIL\IN\';
  _sorveg         : string = chr(13)+chr(10);

  _olvas          : file of byte;

  // ----------------------- INTEGER ARRAYS ------------------------------------

  _vPenztarDarab  : byte;
  _bigcount       : byte;
  _filelen,_y     : word;

  _vPenztarNev    : array[1..180] of string;
  _vPenztarszam   : array[1..180] of byte;

  // ------------------- EGYÉB ARRAY VÁLTOZÓK ----------------------------------

  _byteTomb       : array[1..1024] of byte;
  _kor            : array[1..55] of TShape;
  _szinek         : array[1..4] of Tcolor = (clRed,clBlue,clFuchsia,clAqua);

  // ---------------- BOOLEAN VÁLTOZÓK -----------------------------------------

  _voltnapiforg: boolean;

  // --------------- EGYÉB VÁLTOZÓK --------------------------------------------

  _workday     : byte;
  _aktszin     : TColor;

  _munkaDatum  : TDateTime;

  _srec,
  _srec2      : TSearchRec;
  _aktshape   : TShape;

  // ------------- STRING VÁLTOZÓK ---------------------------------------------

  _adir,
  _aktFdbPath,
  _aktidos,
  _aktPenztarNev,
  _aktOras,
  _archivePath,
  _atpath,
  _bpara,
  _csomagDatum,
  _csomagDatumString,
  _csomagFarok,
  _csomagFile,
  _csomagFileSample,
  _csomagPathSample,
  _csomagPath,
  _datum,
  _datumCim,
  _datumnap,

  _dayBook,
  _daybooknev,
  _eloJel,
  _elozoNev,
  _evs,
  _farok,
  _fileTorzs,
  _hos,
  _kiterjesztes,
  _lastforg,
  _lastnapiforg,
  _lasttablo,
  _lezartnap,
  _mamas,
  _mess,
  _mFileNev,
  _munkaNap,
  _napMezo,
  _pcs,
  _tablaNev,
  _targetdir,
  _text,
  _tipus,
  _utDatum,
  _utolsodatum,
  _uzenet,
  _valutanem: string;


  // ------------- INTEGER VÁLTOZÓK --------------------------------------------

  _aktev,
  _aktho,
  _aktnap,
  _aktnum,
  _aktora,
  _aktPenztarSzam,
  _aktpenztar,
  _code,
  _count,
  _ertek,
  _ev,
  _feldOke,
  _hNap,
  _ho,
  _honap,
  _listindex,
  _mResult,
  _nap,
  _penztarTipus,
  _recno,
  _scancount,
  _szinPointer,
  _uzlet,
  _uzletdb: integer;



function daybookcontrol: integer; stdcall; external 'c:\receptor\newdll\dbctrl.dll' name 'daybookcontrol';
function napimentesrutin: integer; stdcall; external 'c:\receptor\mentes.dll' name 'napimentesrutin';
function makeexclusivetablo: integer; stdcall; external 'c:\receptor\tablomake.dll';

function sendmailrutin: integer; stdcall; external 'c:\receptor\smail.dll' name 'sendmailrutin';
function logirorutin(_para: pchar): integer; stdcall; external 'c:\receptor\logiro.dll' name 'logirorutin';
function scannedpictcopy: integer; stdcall; external 'c:\receptor\scancopy.dll' name 'scannedpictcopy';
function okmanymasolo: integer; stdcall; external 'c:\receptor\askcopy.dll' name 'okmanymasolo';
function unpackerrutin: integer; stdcall; external 'c:\receptor\unpacker.dll' name 'unpackerrutin';
function jelenletiivek: integer; stdcall; external 'c:\receptor\jelivek.dll' name 'jelenletiivek';
function foglalokeszletek: integer; stdcall; external 'c:\receptor\foglalok.dll' name 'foglalokeszletek';
function havikedvezmenyiro(_para: string): integer;stdcall; external 'c:\receptor\kedviro.dll' name 'havikedvezmenyiro';
function napiforgalomkuldo: integer; stdcall; external 'c:\receptor\napiforg.dll' name 'napiforgalomkuldo';


implementation


{$R *.dfm}

// =============================================================================
                  procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

(*
   _munkanap : Az utolsó lezáratlan nap a receptorban
   _aktualnap: A tényleges naptári nap
   _lastsave : Az utolsó mentett nap

*)


begin

  Top    := 10;
  Left   := 5;
  Height := 100;

  logirorutin(pchar('A receptort bekapcsolták'));

  UzenoPanel.Caption := '';
  UzenoPanel.repaint;

  Kilepo.Enabled   := False;
  KortombBetolto;             // a jelzõ körök tömbbe irása
  PenztarBeolvasas;
  Korclear;                   // A körök színe: fehér

  _szinPointer := 1;          // A 6 szin pointerre
  _aktszin     := _szinek[1]; // Kezdõ kör színe: piros
  _count       := 0;
  _bigcount    := 150;
  _scancount   := 0;

  BigMenet.Enabled := True;
end;

// =============================================================================
           procedure TForm1.BIGMENETTimer(Sender: TObject);
// =============================================================================

begin
  Bigmenet.Enabled := False;

  GetDatumido;     // _mamas,_akttora bekérése
  StatusBeolvaso;  // munkanap, lezartnap
  if _mamas>_munkanap then ezujnap;
  Figyelo.Enabled := True;

end;

// =============================================================================
                        procedure TForm1.Ezujnap;
// =============================================================================


begin
  _pcs := 'UPDATE RENDSZER SET LEZARTNAP=' + chr(39) + _munkanap + chr(39);
  _pcs := _pcs + ',MUNKANAP=' + chr(39) + _mamas + chr(39);
  ReceptParancs(_pcs);

  _lezartnap := _munkanap;
  _munkanap  := _mamas;

  DatumKijelzes;

  daybookcontrol;  // havi nyito fdb-ek létrehozása
  napimentesrutin;
  napiforgalomkuldo;
  makeexclusivetablo;
  jelenletiivek;
  foglalokeszletek;
  scannedpictcopy;

  _pcs := 'c:\receptor\ugyfreg.exe';
  _pacs := pchar(_pcs);

  winexec(_pacs,sw_normal);
end;

// =============================================================================
               procedure TForm1.FIGYELOTimer(Sender: TObject);
// =============================================================================

var _foundM: boolean;


begin
  colorKor;
  inc(_count);
  if _count<4 then exit;

  _count := 0;
  Figyelo.Enabled := False;

  _foundM := True;
  while _foundM do
    begin
      _foundM := TalaltMFilet;
      if _foundM then CsomagFeldolgozas;
      sleep(200);
    end;

  EgyebFeladatok;

  dec(_bigcount);
  if _bigcount<1 then BigMenet.Enabled := True else Figyelo.Enabled := True;

end;

// =============================================================================
                  function TForm1.TalaltMFilet: boolean;
// =============================================================================

var _delPath: string;

begin
  result := False;
  if FindFirst(_inputDirectory+'*.m', faAnyFile,_srec) <> 0 then exit;

  // A megtalált Marker file : _mFilenev

  _mFileNev := _sRec.Name;

  _uzenet := 'Markerfile-t detektáltam ';
  logirorutin(pchar('RECEPTOR='+_uzenet+_mfilenev));

  Uzenopanel.caption := _uzenet;
  Uzenopanel.Repaint;
  FindClose(_sRec);

  _delpath := _inputDirectory + _mFileNev;
  Sysutils.DeleteFile(_delPath);

  result := true;
end;

// =============================================================================
                    procedure TForm1.CsomagFeldolgozas;
// =============================================================================

begin
  _fileTorzs      := leftstr(_mFileNev,8);
  _aktPenztarSzam := PenztarDekod(_fileTorzs);

  // Létezik ez a pénztár ? Ha van, akkor megadja -> _aktpenztarnev

  _penztarTipus := VanPenztar(_aktPenztarSzam);

  // Ha nem létezö a pénztár, akkor  ennyi !

   if _penztarTipus=0 then
     begin
       logirorutin(pchar('RECEPTOR = Nem létezõ pénztárszám'));
       UzenoPanel.Caption := 'NEM LÉTEZÕ PÉNZTÁRSZÁM !';
       Uzenopanel.Repaint;
       exit;
     end;

  // _AKTFDBPATH = 'c:\receptor\database\v13.fdb'  vagy c:\cartcash\ ...

  if _penztarTipus=1 then _adir := 'receptor' else _adir := 'cartcash';

  _aktFdbPath := 'c:\'+_adir+'\database\v'+inttostr(_aktPenztarSzam)+'.fdb';
  MakeFdbFile(_aktfdbPath);  // Ha nincs a penztárnak Vxxx.fdb fuke-ja akkor csinál

  // ========== A MARKERFILE ALAPJÁN MEG KELL KERESNI A CSOMAGFILE-T

  // _ADATFILESAMPLE = 'CRAXDXBP.*'

  _csomagFileSample := _fileTorzs + '.*';

  // _PATHSAMPLE = 'C:\RECEPTOR\MAIL\IN\CRAXDXBP.*'

  _csomagpathSample := _inputdirectory + _csomagFileSample;

  // Ha nincs csomagfile ->  ennyi ( megj: marker már törölve van !)

  if Findfirst(_csomagPathSample,faAnyFile,_srec)<>0 then
    begin
      FindClose(_srec);
      logirorutin(pchar('RECEPTOR=Nem jött adatállomány'));
      UzenoPanel.Caption := 'Nem jött meg az adatállomány !';
      UzenoPanel.Repaint;
      Exit;
    end;

  // ------------- MEGVAN A CSOMAGFILE !!! ---------------------------

  // Ezt az adatfile-t találta: 'CRAXDXBP.2IB'

  _csomagFile := _srec.Name;

  // Csomagpath = 'c:\receptor\mail\in\CRAXDXBP.2IB'

  _csomagPath := _inputDirectory + _csomagFile;
  FindClose(_srec);

  // A CSOMAGFILE KITERJESZTÉSÉBÕL KIDERÜL A CSOMAG DÁTUMA

  // Az adatfile Kiterjesztése: '2IB'
  _kiterjesztes := midstr(_csomagFile,10,3);

  // Aktdatum : '2009.01.02'
  _csomagDatum := KitDekod(_kiterjesztes);

  // Datumstring = '2009 január 02 péntek'
  _csomagDatumstring := datumbolString(_csomagDatum);

  if _CsomagDatumString='' then exit;

  // ---------------------------------------------------------------------------
  // A DÁTUM ALAPJÁN ADOTT A HAVI FILE-OK FARKA:

  _uzenet := _aktPenztarNev +' ' + _csomagDatumString+'i zárását megkezdtem ...';

  logirorutin(pchar('RECEPTOR='+_uzenet));

  Uzenopanel.Caption := _uzenet;
  Uzenopanel.Repaint;

  // %%%%%%%%%%%%%%%%%% CSOMAGBONTÁS INDITÁSA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  // Az adatfile feldolgozása

  _pcs := ' DELETE FROM VTEMP';
  TempParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (DATUM,PENZTAR,CSOMAGNEV)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _csomagdatum + chr(39) + ',';

  _pcs := _pcs + inttostr(_aktpenztarszam) + ',';
  _pcs := _pcs + chr(39) + _csomagFile + chr(39) + ')';
  TempParancs(_pcs);

  _feldoke := unpackerrutin;

  // Mielött törölnénk a csomagfilet, elöbb archiváljuk azt

  _archivePath := 'c:\receptor\mail\archive\' + _csomagFile;
  if FileExists(_archivePath) then DeleteFile(_archivePath);
  copyfileto(_csomagpath,_archivePath);

  // HA A FELDOLGOZÁS SIKERTELEN VOLT NINCS MIT TENNI AZUTÁN

  if (_feldoke<>1) then
    begin
      _uzenet := _aktPenztarNev+' SIKERTELEN NAPIZÁRÁS';
      logirorutin(pchar('RECEPTOR='+_uzenet));
      UzenoPanel.Caption := _uzenet;
      UzenoPanel.Repaint;

      DeleteFile(_csomagPath);
      exit;
    end;

  // ================= SIKERES FELDOLGOZÁS !! =================================

  // MOST MAR TÖRÖLHETÖ A CSOMAGFILE

  DeleteFile(_csomagPath);

  // A BEÉRKEZETT CSOMAG REGISZTRÁLÁSA A DAYBOOK TÁBLÁBAN :

  DayRegister(_csomagdatum,_aktPenztarszam);

  // Értesités a sikeres feldolgozásról
  _uzenet := _aktPenztarNev+' '+ _csomagDatumString+'-i zárása feldolgozva';

  logirorutin(pchar('RECEPTOR='+_uzenet));
  Uzenopanel.Caption := _uzenet;
  UzenoPanel.Repaint;

end;


// =============================================================================
       procedure TForm1.DayRegister(_kelt: string;_ptsz: integer);
// =============================================================================


//         A CSOMAG BEÉRKEZÉSÉNEK REGISZTRÁLÁSA A DAYBOOK-BAN


var _naps,_dbknev,_dbkpath: string;
     _knap: integer;

begin
  _evs  := midstr(_kelt,3,2);
  _hos  := midstr(_kelt,6,2);
  _naps := midstr(_kelt,9,2);

  _knap   := strtoint(_naps);
  _farok  := _evs + _hos;
  _dbkNev := 'DAYB' + _farok;

  _napmezo := 'N' + inttostr(_knap);
  _pcs := 'UPDATE ' + _dbkNev + ' SET ' + _napmezo + '=' + chr(39)+'B'+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE PENZTAR=' +inttostr(_ptsz);

  _dbkPath := 'c:\receptor\database\daybook.fdb';
  DayBookParancs(_dbkPath,_pcs);

  if _ptsz>150 then
    begin
      _dbkPath := 'c:\cartcash\database\daybook.fdb';
      DayBookParancs(_dbkPath,_pcs);
    end;
end;


// =============================================================================
        procedure TForm1.daybookParancs(_dpath,_ukaz: string);
// =============================================================================

begin

  Daybookdbase.close;
  daybookdbase.DatabaseName := _dPath;
  Daybookdbase.connected := true;
  if daybooktranz.InTransaction then daybooktranz.commit;
  Daybooktranz.StartTransaction;

  with daybookquery do
    begin
      Close;
      sql.clear;
      sql.Add(_ukaz);
      Execsql;
    end;
  DaybookTranz.commit;
  daybookdbase.close;
end;


// =============================================================================
                     procedure TForm1.Egyebfeladatok;
// =============================================================================

begin
   EmailKuldes;
   sendmailrutin;
   OkmanyCopy;

end;


// =============================================================================
                  procedure TForm1.OkmanySavedre;
// =============================================================================

begin
  _aktora := Hourof(Time);
  if _aktora<8 then exit;

  dec(_scancount);
  if _scancount>0 then exit;

  _scancount := 15;
//  scannedpictcopy;
end;

// =============================================================================
          function TForm1.DatumbolString(_dstring: string): string;
// =============================================================================


var _sDatum: TDateTime;
    _naps,_honapnev,_hnapnev: string;
    _ho,_napss: integer;

begin
  Result := '';
  Try
    _sdatum := Hunstrtodate(_dstring);
  except
     exit;
  end;
  _evs := leftstr(_dstring,4);
  _ho  := monthof(_sDatum);
  _naps := midstr(_dstring,9,2);
  _honapnev := _honev[_ho];
  _napss := dayoftheweek(_sDatum);
  _hnapnev := _napnev[_napss];
  Result := _evs+' '+_honapnev+' '+ _naps + ' '+_hnapnev;
end;

// =============================================================================
               function TForm1.Nulele(_nn: integer): string;
// =============================================================================

begin
  Result := inttostr(_nn);
  if _nn<10 then result := '0' + result;
end;

// =============================================================================
            procedure TForm1.KILEPOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Figyelo.Enabled := False;
  Bigmenet.Enabled := False;
  Application.Terminate;

end;


// =============================================================================
                        procedure TForm1.StatusBeolvaso;
// =============================================================================

begin
  ReceptDbase.Connected := True;
  with ReceptQuery do
    begin
      close;
      Sql.Clear;
      Sql.Add('SELECT * FROM RENDSZER');
      Open;

      _munkanap    := FieldByName('MUNKANAP').asString;
      _lezartnap   := FieldByNAme('LEZARTNAP').asString;
      _lasttablo   := FieldByNAme('LASTTABLO').asString;
      _lastnapiforg:= FieldByNAme('CAMCLEAR').asString;
      Close;
    end;
  ReceptDbase.close;
  DatumKijelzes;
end;


// =============================================================================
             procedure TForm1.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Application.Terminate;
end;


// =============================================================================
                   procedure TForm1.DatumKijelzes;
// =============================================================================

begin
  _munkadatum := Hunstrtodate(_munkanap);
  _ev := yearof(_munkaDatum);
  _ho := monthof(_munkaDatum);
  _nap := dayof(_munkaDatum);
  _hnap := dayoftheweek(_munkadatum);

  _datumcim := inttostr(_ev)+' '+ _honev[_ho]+' '+inttostr(_nap)+' '+ _napnev[_hnap];
  DatumPanel.Caption := _datumCim;
  DatumPanel.Repaint;
end;

// =============================================================================
              procedure Tform1.ReceptParancs(_ukaz: string);
// =============================================================================

begin
  ReceptDbase.Connected := True;
  if ReceptTranz.inTransaction then ReceptTranz.Commit;
  ReceptTranz.StartTransaction;
  with ReceptQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_ukaz);
      ExecSql;
    end;
  ReceptTranz.Commit;
  ReceptDbase.Close;
end;

// =============================================================================
                             procedure TForm1.Korclear;
// =============================================================================

var i: integer;

begin
  for i := 1 to 55 do
    begin
      _aktShape := _kor[i];
      _aktshape.Brush.Color := clWhite;
    end;
end;

// =============================================================================
                           procedure TForm1.ColorKor;
// =============================================================================

var _y: integer;

begin
  _y := 1;
  while _y<=55 do
    begin
      _aktShape := _kor[_y];
      with _aktShape do
        begin
          Brush.Color := _aktszin;
          Repaint;
        end;

      sleep(30);
      inc(_y);
    end;

  inc(_szinPointer);

  if _szinPointer>4 then _szinpointer :=1;

  _aktszin := _szinek[_szinPointer];
end;


// =============================================================================
              procedure TForm1.TALCARAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Form1.WindowState := wsminimized;
end;

// =============================================================================
                  procedure TForm1.FormClick(Sender: TObject);
// =============================================================================

begin
  Form1.WindowState := wsNormal;
end;

// =============================================================================
                            procedure TForm1.EmailKuldes;
// =============================================================================


var _pacs: pchar;
    _minta,_atname,_exts,_tema: string;
    _vanEmail: boolean;
    _extlen,_ext: byte;
    _code: integer;
    _olvas: textfile;

begin
  _vanEmail := False;

  _minta := 'c:\receptor\mail\email\at*.*';
  if FindFirst(_minta, faAnyfile, _srec) = 0 then
    begin
      _atname := _srec.Name;
      _vanEmail := True;
    end;
  FindClose(_srec);

  if not _vanEmail then exit;

  _atPath := 'c:\receptor\mail\email\'+_atname;

  Assignfile(_olvas,_atPath);
  reset(_olvas);
  readln(_olvas,_tema);
  Closefile(_olvas);

  delEmailDir;

  _exts := ExtractFileExt(_atname);
  _extlen := length(_exts);
  _exts := midstr(_exts,2,_extlen-1);

  val(_exts,_ext,_code);
  if _code<>0 then _ext := 0;

  if _ext=0 then exit;

  _pcs := 'c:\receptor\mail\email\ertesito.exe '+ _exts+' '+_tema;
  _pacs := pchar(_pcs);

  winexec(_pacs,sw_normal);
end;





// =============================================================================
                         procedure TForm1.DelemailDir;
// =============================================================================


var _minta,_delpath: string;
    _srec: TSearchrec;
    _y,_ddb: byte;
    _atn: array[0..9] of string;

begin
  _minta := 'c:\receptor\mail\email\at*.*';
  _y := 0;
  if FindFirst(_minta, faAnyfile, _srec) = 0 then
    begin
      repeat
        _atn[_y] := _srec.Name;
        inc(_y);
       until FindNext(_srec) <> 0;
    end;
  FindClose(_srec);

  if _y=0 then exit;

  _ddb := _y;
  _y := 0;
  while _y<_ddb do
    begin
      _delPath := 'c:\receptor\mail\email\'+_atn[_y];
      sysutils.DeleteFile(_delpath);
      inc(_y);
    end;
end;



// =============================================================================
            function TForm1.hunDatetostr(_d: TDateTime): string;
// =============================================================================

var _yev,_yho,_ynap: word;

begin
  _yev := yearof(_d);
  _yho := monthof(_d);
  _ynap := dayof(_d);

  result := inttostr(_yev)+'.'+nulele(_yho)+'.'+nulele(_ynap);
end;

// =============================================================================
             function TForm1.Hunstrtodate(_s: string): TDatetime;
// =============================================================================

var _yevs,_yhos,_ynaps: string;
    _yev,_yho,_ynap: word;
    _code: integer;

begin
  _yevs := leftstr(_s,4);
  _yhos := midstr(_s,6,2);
  _yNaps := midstr(_s,9,2);

  val(_Yevs,_yev,_code);
  val(_yhos,_yho,_code);
  val(_ynaps,_yNap,_code);

  result := encodedate(_yev,_yho,_ynap);
end;


// =============================================================================
             procedure TForm1.TempParancs(_ukaz: string);
// =============================================================================

begin
  TempDbase.Connected := true;
  if TempTranz.InTransaction then TempTranz.commit;
  TempTranz.StartTransaction;

  with TempQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_ukaz);
      ExecSql;
    end;
  TempTranz.commit;
  Tempdbase.close;
end;



// =============================================================================
              function TForm1.VanPenztar(_ptsz:integer): integer;
// =============================================================================

// MEGNÉZI, HOGY VAN-E ILYEN SZÁMÚ PÉNZTÁR

var _y: byte;

begin
  Result := 0;
  if (_ptsz<180) then
    begin
      _y := 1;
      while _y<=_vPenztarDarab do
        begin
          if _vPenztarszam[_y]=_ptsz then
             begin
               _aktPenztarNev := _vPenztarnev[_y];
               result := 1;
               exit;
             end;
          inc(_y);
        end;
      exit;
    end;
end;

// =============================================================================
                      procedure Tform1.PenztarBeolvasas;
// =============================================================================

var _cc,_uzlet: integer;

begin
  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE CLOSED=' + chr(39)+'N'+chr(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  ReceptDbase.Connected := true;
  with ReceptQuery do
    begin
      close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _vPenztardarab := recno;
      First;
    end;

  _cc := 0;
  while not ReceptQuery.Eof do
    begin
      inc(_cc);
      _uzlet             := ReceptQuery.FieldByName('UZLET').asInteger;
       _vPenztarSzam[_cc] := _uzlet;
      _vPenztarNev[_cc]  := trim(ReceptQuery.FieldByname('KESZLETNEV').asString);
      ReceptQuery.Next;
    end;
  ReceptQuery.close;
  ReceptDbase.close;

  // ---------------------------------------------------------------------------

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE CLOSED=' + chr(39) + 'N' + chr(39) + _sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';
  inc(_cc);
  ArtcDbase.Connected := true;
  with ArtcQuery do
    begin
      close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;


  while not ArtcQuery.Eof do
    begin
      _uzlet             := ArtcQuery.FieldByName('UZLET').asInteger;
      _vPenztarSzam[_cc] := _UZLET;
      _vPenztarNev[_cc]  := trim(ArtcQuery.FieldByname('KESZLETNEV').asString);
      inc(_cc);
      ArtcQuery.Next;
    end;
  ArtcQuery.close;
  ArtcDbase.close;
  _vPenztarDarab := _cc;

end;

// %%%%%%%%%%% HA A PÉNZTÁRNAK NINCS ILYEN FDB-JE AKKOR CSINÁL %%%%%%%%%%%%%%%%
// =============================================================================
              procedure TForm1.MakeFDBFile(_fdbPath: string);
// =============================================================================

var Valutafdb: TIBdatabase;

begin
  if FileExistS(_fdbpATH) then exit;

  ValutaFdb := TIbDatabase.Create(nil);
  with ValutaFdb do
    begin
      Connected := False;
      DatabaseName := _fdbPath;

      Params.Add('USER ''SYSDBA''PASSWORD ''dek@nySo''');
      Params.Add('DEFAULT CHARACTER SET WIN1250');

      SqlDialect := 3;
      LoginPrompt := False;
      CreateDatabase;
    end;
  valutaFDb.Free;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$ BIZALMAS VÉGE $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
// SSSSSSSSSSSSSS    DEKODER FUNKCIOK   SSSSSSSSSSSSSSSSSSSSSSSS
// =============================================================================
            function Tform1.PenztarDekod(_szams: string):integer;
// =============================================================================

  (* 8 nagybetübõl álló stringbõl 1-999 közötti irodaszámot dekodol *)
var i,_plusz,_b1,_b2,_egy,_tiz,_kodb,_szor,_betu: integer;
     _ss: array[1..4] of string;
     _par : string;

begin
   result := 0;
   if length(_szams)<>8 then exit;
   _szams := uppercase(_szams);
   _ss[1] := midstr(_szams,3,2);
   _ss[2] := midstr(_szams,7,2);
   _ss[3] := leftstr(_szams,2);
   _ss[4] := midstr(_szams,5,2);
   _szams := '';
   for i:= 1 to 4 do
     begin
       _par := _ss[i];
       _b1 := ord(_par[1]);
       _b2 := ord(_par[2]);
       _egy := trunc((_b2-72)/2);
       _tiz := _b1 - 64;
       _kodb := (10*_tiz) + _egy;
       _plusz := i + 1;
       _szor := 10 -i;
       _betu := trunc(_kodb/_szor) - _plusz;
       _szams := _szams + chr(_betu + 48);
     end;
   result := strtoint(_szams);
end;

// =============================================================================
         function TForm1.KitDekod(_kdatkod: string): string;
// =============================================================================

(* Három betüs file-kiterjesztésböl egy dátumot generál *)

var _nap,_ev: word;

begin
  result := '';
  if _kdatkod='' then exit;
  _nap := ord(_kdatkod[1]);
  _ev := ord(_kdatkod[2]);
  _honap := ord(_kdatkod[3]);
  _ev := _ev + 2000 - 64;
  _honap := trunc((_honap-64)/2);
  if _nap>64 then _nap := _nap - 55
  else _nap := _nap - 48;
  result := inttostr(_ev)+'.'+nulele(_honap)+'.'+nulele(_nap);
end;

// $$$$$$$$$$$$$$$$$$$ DEKODER RUTINOK BEFEJEZVE $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
// =============================================================================
                       procedure TForm1.KortombBetolto;
// =============================================================================

begin
  _kor[1]  := k1;
  _kor[2]  := k2;
  _kor[3]  := k3;
  _kor[4]  := k4;
  _kor[5]  := k5;
  _kor[6]  := k6;
  _kor[7]  := k7;
  _kor[8]  := k8;
  _kor[9]  := k9;
  _kor[10] := k10;
  _kor[11] := k11;
  _kor[12] := k12;
  _kor[13] := k13;
  _kor[14] := k14;
  _kor[15] := k15;
  _kor[16] := k16;
  _kor[17] := k17;
  _kor[18] := k18;
  _kor[19] := k19;
  _kor[20] := k20;
  _kor[21] := k21;
  _kor[22] := k22;
  _kor[23] := k23;
  _kor[24] := k24;
  _kor[25] := k25;
  _kor[26] := k26;
  _kor[27] := k27;
  _kor[28] := k28;
  _kor[29] := k29;
  _kor[30] := k30;
  _kor[31] := k31;
  _kor[32] := k32;
  _kor[33] := k33;
  _kor[34] := k34;
  _kor[35] := k35;
  _kor[36] := k36;
  _kor[37] := k37;
  _kor[38] := k38;
  _kor[39] := k39;
  _kor[40] := k40;
  _kor[41] := k41;
  _kor[42] := k42;
  _kor[43] := k43;
  _kor[44] := k44;
  _kor[45] := k45;
  _kor[46] := k46;
  _kor[47] := k47;
  _kor[48] := k48;
  _kor[49] := k49;
  _kor[50] := k50;
  _kor[51] := k51;
  _kor[52] := k52;
  _kor[53] := k53;
  _kor[54] := k54;
  _kor[55] := k55;
end;

// =============================================================================
     function TFORM1.WinExecAndWait32(Path: PChar; Visibility: Word): integer;
// =============================================================================

var Msg: TMsg;
    lpExitCode: cardinal;
    StartupInfo: TStartupInfo;
    ProcessInfo: TProcessInformation;

begin
  FillChar(StartupInfo, SizeOf(TStartupInfo), 0);
  with StartupInfo do
    begin
      cb := SizeOf(TStartupInfo);
      dwFlags := STARTF_USESHOWWINDOW or STARTF_FORCEONFEEDBACK;
      wShowWindow := visibility; {you could pass sw_show or sw_hide as parameter}
    end;

  if CreateProcess(nil, path, nil, nil, False, NORMAL_PRIORITY_CLASS,
                                      nil, nil, StartupInfo,ProcessInfo) then

    begin
      repeat
        while PeekMessage(Msg, 0, 0, 0, pm_Remove) do
          begin
            if Msg.Message = wm_Quit then Halt(Msg.WParam);
            TranslateMessage(Msg);
            DispatchMessage(Msg);
          end;

        GetExitCodeProcess(ProcessInfo.hProcess,lpExitCode);
      until lpExitCode <> Still_Active;

    with ProcessInfo do {not sure this is necessary but seen in in some code elsewhere}
      begin
        CloseHandle(hThread);
        CloseHandle(hProcess);
      end;

    Result := 0; {success}
  end else Result := GetLastError;
end;

// =============================================================================
                        procedure TForm1.GetDatumIdo;
// =============================================================================

var _code: integer;

begin
  _mamas := leftstr(Form1.Hundatetostr(Date),10);

  _aktidos := Timetostr(Time);
  if midstr(_aktidos,2,1)=':' then _aktidos := '0' + _aktidos;
  _aktoras := leftstr(_aktidos,2);
  val(_aktoras,_aktora,_code);
  if _code<>0 then _aktora := 0;
end;

// =============================================================================
                       procedure TForm1.OkmanyCopy;
// =============================================================================

var _needcopy: boolean;
    _minta: string;

begin
  _needcopy := False;
  _minta := 'c:\receptor\mail\scans\ask\*.A*';
  if findfirst(_minta,faAnyfile,_srec)=0 then
    begin
      _needcopy := True;
      Findclose(_srec);
    end;

  if not _needcopy then exit;
  okmanymasolo;
end;

// =============================================================================
              procedure TForm1.SEGEDGOMBClick(Sender: TObject);
// =============================================================================

begin
  Figyelo.Enabled := False;
  Bigmenet.Enabled := False;
  Segedmenu;
end;

// =============================================================================
                     procedure TForm1.Segedmenu;
// =============================================================================

begin
  Form1.Height := 380;
  with SegedPanel do
    begin
      top := 96;
      Left := 424;
      Visible := True;
      repaint;
    end;
end;

// =============================================================================
          procedure TForm1.SEGEDVISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Segedpanel.Visible := False;
  Form1.Height := 137;
  Figyelo.Enabled := True;
end;

// =============================================================================
             procedure TForm1.NAPIFORGGOMBClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'UPDATE RENDSZER SET LASTFORGTABLA='+chr(39)+'2020.06.00'+chr(39);
  ReceptParancs(_pcs);
  napiforgalomkuldo;
  SegedVisszaGombClick(Nil);
end;

// =============================================================================
              procedure TForm1.TABLOGOMBClick(Sender: TObject);
// =============================================================================

begin
   _pcs := 'UPDATE RENDSZER SET LASTTABLO='+chr(39)+'2020.06.00'+chr(39);
  ReceptParancs(_pcs);
  makeexclusivetablo;
  SegedVisszaGombClick(Nil);
end;

// =============================================================================
            procedure TForm1.MENTESGOMBClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'UPDATE RENDSZER SET LASTSAVE='+chr(39)+'2020.01.01'+chr(39);
  ReceptParancs(_pcs);
  napimentesrutin;
  SegedVisszaGombClick(Nil);
end;



function TForm1.BejelentesDekodolo(_kodstr: string): String;

var _sordb,_sor,_betu,_sorlen:byte;
    _bb,_pp: word;

begin
  result := '';
  if _kodstr='' then exit;

  _sordb := 255 - ord(_kodstr[1]);
  _pp := 8;
  _sor := 1;
  while _sor<_sordb do
    begin
      _sorlen := ord(_kodstr[_pp]);
      _bb := 1;
      inc(_pp);
      while _bb<=_SORLEN do
        begin
          _betu := 255-ord(_kodstr[_pp]);
          result := result + chr(_betu);
          inc(_pp);
          inc(_bb);
        end;
      inc(_sor);
    end;
  _bb := ord(_kodstr[_pp]);
  _bb := _bb+ord(_kodstr[_pp+1]);
  _bb := _bb+ord(_kodstr[_pp+2]);
  if _BB<>765 then
    begin
      result := 'HIBÁS KÓDOLÁSÚ ÜZENET';
      EXIT;
    end;
end;



end.

