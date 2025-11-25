unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, strutils, DB, IBDatabase, DateUtils,
  IBCustomDataSet, IBQuery, Grids, DBGrids;

type
  TForm2 = class(TForm)

    KUgyfelPanel    : TPanel;
    KeresoPanel     : TPanel;
    Label2          : TLabel;
    Label3          : TLabel;
    Label4          : TLabel;
    Label5          : TLabel;

    KugySource      : TDataSource;

    KugyOkeGomb     : TBitBtn;
    KugyMegsemGomb  : TBitBtn;
    NoChooseGomb    : TBitBtn;
    ListaGomb       : TBitBtn;

    KeresoEdit      : TEdit;
    NevEdit         : TEdit;
    SzulhelyEdit    : TEdit;
    SzulidoEdit     : TEdit;

    Shape1          : TShape;
    KugyRacs        : TDBGrid;

    LocalQuery      : TIBQuery;
    LocalDbase      : TIBDatabase;
    LocalTranz      : TIBTransaction;

    RemoteQuery     : TIBQuery;
    RemoteDbase     : TIBDatabase;
    RemoteTranz     : TIBTransaction;
    Kilepo          : TTimer;
    Label6: TLabel;
    UZENOPANEL: TPanel;
    Shape2: TShape;
    INDOKPANEL: TPanel;
    Label1: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    ZDATUMPANEL: TPanel;
    UTFTPANEL: TPanel;
    AKTFTPANEL: TPanel;
    OSSZFTPANEL: TPanel;
    TOVABBGOMB: TButton;
    Shape3: TShape;

    procedure FormActivate(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure KugyMegsemGombClick(Sender: TObject);
    procedure KugyOkeGombClick(Sender: TObject);
    procedure KugyRacsDblClick(Sender: TObject);
    procedure KugyRacsCellClick(Column: TColumn);
    procedure KugyRacsKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ListaGombClick(Sender: TObject);

    procedure LocalParancs(_ukaz: string);
    procedure NevEditEnter(Sender: TObject);
    procedure NevEditExit(Sender: TObject);
    procedure NevEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure NoChooseGOMBClick(Sender: TObject);
    procedure ParameterBeolvasas;

    procedure RemoteInsert;
    procedure Remoteparancs(_ukaz: string);
    procedure SaveLocalUgyfel;
    procedure UpdateVtemp;
    procedure UgyfelKiertekeles;
    procedure UgyfeletValasztott;
    procedure VtempAlapraAllitas;

    function Angolra(_huName: string): string;
    function Datumctrl(_ds: string): boolean;
    function DoubleKill(_s: string): string;
    function Getnapdiff(_ds1,_ds2: string): extended;
    function Hunstrtodate(_s: string): Tdatetime;
    function HutoGb(_kod: byte): byte;
    function RemoteKereses: boolean;
    function Tomorito(_ts: string): string;
    function Ftform(_numft: integer): string;
    procedure TOVABBGOMBClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _host: string;

  _kulfoldi,_bill: byte;

  _maidate,_lastDate: TDateTime;
  _diff: extended;
  _top,_left,_height,_width,_success,_konverzio: word;

  _code,_recno,_sorszam,_remoteosszeg,_mResult,_rOsszeg,_ss: integer;
  _ugyfelszam,_fizetendo,_gongyolt: integer;

  _nev,_szulhely,_szulido,_pcs,_kernev,_kbetu,_megnyitottnap: string;
  _engnev,_enghely,_engido,_nevtabla,_remotedatum,_lastmezo: string;
  _keres,_edker,_ugyfeltipus,_mess,_rSzulido,_rSzulhely,_rLastday: string;
  _szhely,_szIdo,_plombaszam,_remoteFdbPath: string;

  _sorveg: string = chr(13)+chr(10);
  _connected,_listabol,_remoteRegisztralt,_vanszerver: boolean;

function getengedelyrutin(_para: integer):integer; stdcall; external 'c:\valuta\bin\getenged.dll' name 'getengedelyrutin';
Function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll' name 'logirorutin';
function kisugyfelrutin: integer; stdcall;

implementation

{$R *.dfm}


// Vissza: result = 3 -> nem kell azonositani (kicsi az összeg)
//                = 2 -> teljes azonositást szükséges
//                = 1 -> kisugyfel rendben vagy server nem érhetõ el
//                = -1 -> tranzkaciót befejezni


// =============================================================================
              function kisugyfelrutin: integer; stdcall;
// =============================================================================


begin
  Form2  := TForm2.Create(NIL);
  Result := Form2.Showmodal;
  Form2.Free;
end;

// =============================================================================
                procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

//              VISSZATÉRÉS:
//
//  -1: Az egész tranzakciót el kell vetni
//   1: a kisügyfél regisztrálva
//   2: csak nagyügyfélként kezelhetö
//   3: nem kell azonositani (100 ezer alatt)


begin

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;
  _left   := Round((_width-1024)/2);
  _top    := round((_height-768)/2);

  Top     := _top+144;
  Left    := _left+240;
  repaint;

  logirorutin(pchar('...'));
  logirorutin(pchar('Indul a kisugyfel rutin'));

  VtempAlapraAllitas;   // ugyftip,ugyfszam,nevtabla,sorszam clear
  ParameterBeolvasas;  // fizetendo,külfoldi,megnyitottnap
  _remoteFdbPath := _host + ':C:\RECEPTOR\DATABASE\KISUGYFEL.FDB';

  if _fizetendo>=300000 then
    begin
      logirorutin(pchar('Nagy az összeg - teljes azonositás kell.'));

      // Teljes azonositás szükséges, mert nagyobb azössze 300 ezernél
      UzenoPanel.Caption := 'TELJES AZONOSITÁS KELL';
      UzenoPanel.Visible := true;
      UzenoPanel.repaint;
      Sleep(2500);

      _mResult := 2;
      Kilepo.Enabled := True;
      exit;
    end;

  _vanszerver := False;
  RemoteDbase.close;
  Remotedbase.DatabaseName := _remoteFdbPath;

  TRY
    RemoteDbase.connected := true;
    _vanszerver := True;
  FINALLY
    RemoteDbase.close;
  END;

  if not _vanszerver then
    begin
      UzenoPanel.Caption := 'NINCS SZERVER - TOVÁBB';
      UzenoPanel.Visible := true;
      repaint;
      Sleep(2500);

      _mResult := 3;
      Kilepo.enabled := true;
      exit;
    end;

  //  --------------------- itt kezdjük az ügyfél azonositást ------------------

  KeresoPanel.Visible := False;

  _ugyfelszam  := 0;
  _ugyfeltipus := 'K';
  _sorszam     := 0;
  _nevtabla    := '';
  _listabol    := False;

  //  A kisügyfél adatainak meghatározása
  // A három adat kérésének elõkészítése:

  NevEdit.Clear;
  SzulhelyEdit.Clear;
  SzulidoEdit.Clear;

  Height := 284;

  with KugyfelPanel do
    begin
      top := 48;
      left := 0;
      Visible := True;
      Repaint;
    end;

  logirorutin(pchar('Nevedit a fokuszban'));

  _keres := '';
  Activecontrol := NevEdit;
end;

//              BILLENTYÜK KIÉRTÉKELÉS A 3 ADAT BEOLVASÁSA KÖZBEN
//
// =============================================================================
      procedure TForm2.NEVEDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

var _tag: byte;

begin
  if ord(key)<>13 then exit;

  _tag := Tedit(sender).tag;

  case _tag of
    1: activecontrol  := SzulhelyEdit;
    2: activecontrol  := SzulidoEdit;
    3: activecontrol  := kugyOkeGomb;
  end;
end;


// =============================================================================
             procedure TForm2.KugyOkeGombClick(Sender: TObject);
// =============================================================================

begin

  logirorutin(pchar('Beirt adatok ellenörzése'));

  _nev := trim(nevedit.Text);
  if length(_nev)<5 then
    begin
      logirorutin(pchar('Hibás név'));
      Activecontrol := NevEdit;  // NÉV legalább 5 betü
      exit;
    end;

  _szulhely := trim(SzulhelyEdit.Text);
  if length(_szulhely)<3 then    // SZÜLHELY legalább 2 betü
    begin
      logirorutin(pchar('Hibás születési hely'));
      Activecontrol := SzulhelyEdit;
      exit;
    end;

  _szulido := trim(SzulidoEdit.Text);
  if not Datumctrl(_szulido) then   // Csak érvényes dátum lehetséges
    begin
      logirorutin(pchar('Hibás születési idõ'));
      Activecontrol := SzulidoEdit;
      exit;
    end;

  // Itt a 3 beirt adat rendben van

  _engnev   := Angolra(_nev);
  _enghely  := Angolra(_szulhely);
  _engido   := Tomorito(_szulido);

  _kbetu    := leftstr(_engnev,1);
  _nevtabla := _kBetu + 'NEV';

  _remoteRegisztralt := remoteKereses;
  if not _remoteRegisztralt then RemoteInsert;

  UgyfelKiertekeles;
end;

// =============================================================================
                function TForm2.RemoteKereses: boolean;
// =============================================================================

begin
  result := False;

  _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
  _pcs := _pcs + 'WHERE NEV LIKE ' + chr(39) + _engnev + '%' + chr(39);

  RemoteDbase.close;
  RemoteDbase.DatabaseName := _remoteFdbPath;
  RemoteDbase.Connected := true;
  with RemoteQuery do
    begin
      Close;
      Sql.Clear;
      Sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      RemoteQuery.close;
      RemoteDbase.Close;
      exit;
    end;

  while not RemoteQuery.eof do
    begin
      _rszulhely := trim(RemoteQuery.FieldByNAme('SZULHELY').asString);
      _rSzulido  := trim(RemoteQuery.FieldByNAme('SZULIDO').asString);
      _rLastday  := RemoteQuery.FieldByName('LASTDATE').asString;
      _rOsszeg   := RemoteQuery.FieldByNAme('OSSZEG').asInteger;
      _sorszam   := RemoteQuery.FieldByNAme('SORSZAM').asInteger;

      if (_rszulhely=_enghely) AND (_rszulido=_engido) then
        begin
          RemoteQuery.close;
          RemoteDbase.close;
          result := True;
          exit;
        end;
      remoteQuery.next;
    end;
  remoteQuery.close;
  Remotedbase.close;
end;

// =============================================================================
                   procedure TForm2.RemoteInsert;
// =============================================================================

begin
  _lastmezo := _kbetu + 'NUM';
  RemoteDbase.close;
  RemoteDbase.DatabaseName := _remoteFdbPath;

  RemoteDbase.Connected := True;
  _pcs := 'SELECT * FROM LASTNUM' + _sorveg;
  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _ss := RemoteQuery.FieldByNAme(_lastmezo).asInteger;
      Close;
    end;
  _sorszam := _ss+1;
  RemoteDbase.close;

  _rOsszeg := 0;
  _rLastDay := '2000.01.01';

  _pcs := 'UPDATE LASTNUM SET ' + _lastmezo + '=' + inttostr(_sorszam);
  RemoteParancs(_pcs);

  _pcs := 'INSERT INTO ' + _nevtabla + ' (SORSZAM,NEV,SZULHELY,SZULIDO,';
  _pcs := _pcs + 'LASTDATE,OSSZEG)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_sorszam) + ',';
  _pcs := _pcs + chr(39) + _engnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _enghely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _engido + chr(39) + ',';
  _pcs := _pcs + chr(39) + _rLastDay + chr(39) + ',';
  _pcs := _pcs + inttostr(_rOsszeg) + ')';
  RemoteParancs(_pcs);
end;

// =============================================================================
            procedure TForm2.ListaGombClick(Sender: TObject);
// =============================================================================

// Beirás helyett inkább választ az UGYFEL tábla rekordjai közül
//  az UGYFEL.TOROLVE mezönek 1-nek kell lenni
//
begin
  logirorutin(pchar('Listából akar választani gombot nyomta'));

  Keresoedit.clear;
  _keres := '';

  _pcs := 'SELECT* FROM UGYFEL' + _sorveg;
  _PCS := _pcs + 'WHERE TOROLVE=1' + _SORVEG;
  _pcs := _pcs + 'ORDER BY NEV';

  LocalDbase.Connected := true;
  with LocalQuery do
    begin
      Close;
      sql.clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  with KeresoPanel do
    begin
      top     := 8;
      left    := 16;
      Visible := True;
      repaint;
    end;
  ActiveControl := KugyRacs;
end;

// =============================================================================
         procedure TForm2.KUGYRACSKeyUp(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

// A billentyükkel választja ki az ügyfelet az adatbázisból

var _okl: boolean;
    _wk: byte;
begin
  _bill := ord(key);

  if (_bill>96) and (_bill<123) then _bill := _bill-32;
  if (_bill>64) and (_bill<91) then
    begin
      _edker := _keres;
      _okL := LocalQuery.Locate('NEV',(_edker+chr(_bill)),[loPartialKey]);
      if _okl then _Keres := _keres + chr(_bill);
      Keresoedit.Text := _keres;
      exit;
    end;

  if _bill=8 then
    begin
      if _keres='' then exit;
      _wk := length(_keres);
      if _wk=1 then
        begin
          _keres := '';
          Keresoedit.Text := '';
          exit;
        end;
      _keres := leftstr(_keres,_wk-1);
      Keresoedit.Text := _keres;
      LocalQuery.Locate('NEV',(_edker+chr(_bill)),[loPartialKey]);
      exit;
    end;

  if _bill = 13 then
    begin
      UgyfeletValasztott;
    end;
end;

// =============================================================================
           procedure TForm2.KugyRacsCellClick(Column: TColumn);
// =============================================================================

begin
  Ugyfeletvalasztott;
end;

// =============================================================================
             procedure TForm2.KugyRacsDblClick(Sender: TObject);
// =============================================================================

begin
  UgyfeletValasztott;
end;

// =============================================================================
                    procedure TForm2.UgyfeletValasztott;
// =============================================================================

// Kiválasztott egy regisztrált ügyfelet a VALUTA.UGYFEL helyi adatbázisból

begin
  logirorutin(pchar('Ügyfelet választott a rögzitettek közül'));
  // A kisügyfél adatait kiolvassa az adatbázisból:

  _ugyfelszam   := LocalQuery.FieldByNAme('UGYFELSZAM').asInteger;
  _Nev          := trim(LocalQuery.FieldByName('NEV').asString);
  _SzulHely     := trim(LocalQuery.FieldByName('SZULETESIHELY').asString);
  _SzulIdo      := leftstr(LocalQuery.FieldByName('SZULETESIIDO').AsString,10);


  _mess := inttostr(_ugyfelszam)+'-'+_nev+'/'+_szulhely+'-'+_szulido;
  logirorutin(pchar(_mess));

  LocalQuery.close;
  LocalDbase.close;

  // A kiválasztott adatokat beirja a szerkesztö edit-ekbe:

  NevEdit.text      := _nev;
  SzulhelyEdit.text := _Szulhely;
  SzulidoEdit.text  := _Szulido;

  // Az ugyfélrács eltünik:
  KeresoPanel.visible   := False;
  Activecontrol := KugyOkeGomb;
end;

// =============================================================================
                      procedure TForm2.UgyfelKiertekeles;
// =============================================================================

begin
  _mResult  := 3;
  _maidate  := HunStrTodate(_megnyitottnap);
  _lastDate := HunstrToDate(_rLastDay);
  _diff := _maidate-_lastDate;

  _gongyolt := _rOsszeg+_fizetendo;

  if (_diff<=7) and (_gongyolt>=300000) then
    begin

      KugyfelPanel.visible := False;
      KeresoPanel.visible  := False;

      _mess := 'A heti váltás>300 ezer (összeg: '+inttostr(_gongyolt);
      logirorutin(pchar(_mess));

      ZdatumPanel.Caption := _rLastDay;
      UtftPanel.Caption   := ftform(_rOsszeg)+' Ft';
      AktFtPanel.caption  := ftForm(_fizetendo)+' Ft';
      OsszFtPanel.Caption := ftform(_gongyolt)+' Ft';
      height := 392;

      with Indokpanel do
        begin
          top := 64;
          left := 24;
          Visible := True;
          repaint;
        end;

      Activecontrol := TovabbGomb;
      exit;
    end;

  if _ugyfelszam=0 then SaveLocalUgyfel;

  UpdateVtemp;
  if _kulfoldi=1 then
    begin
      _mResult := getengedelyrutin(2);
      if _mresult=1 then _mResult := 3;
    end;
  Kilepo.enabled := true;
end;

// =============================================================================
                      procedure TForm2.SaveLocalUgyfel;
// =============================================================================

begin
  if _ugyfelszam>0 then exit;

  _pcs := 'SELECT * FROM UGYFEL' + _sorveg;
  _pcs := _pcs + 'WHERE NEV LIKE '+chr(39) + trim(_nev) + '%' + chr(39);

  LocalDbase.Connected := True;
  with LocalQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;
  while not LocalQuery.Eof do
    begin
      _szhely := trim(LocalQuery.fieldByNAme('SZULETESIHELY').asString);
      _szIdo  := LocalQuery.FieldByNAme('SZULETESIIDO').asString;
      _ugyfelszam := LocalQuery.fieldByNAme('UGYFELSZAM').asInteger;

      if (_szulhely=_szhely) or (_szulido=_szido) then
         begin
           LocalQuery.close;
           Localdbase.close;
           exit;
         end;
      Localquery.next;
    end;

  with LocalQuery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM UTOLSOBLOKKOK');
      Open;
      _ugyfelszam := FieldByName('UTOLSOUGYFELSZAM').asInteger;
      Close;
    end;
  LocalDbase.close;

  inc(_ugyfelszam);

  _pcs := 'UPDATE UTOLSOBLOKKOK SET UTOLSOUGYFELSZAM='+inttostr(_ugyfelszam);
  LocalParancs(_pcs);

  _pcs := 'INSERT INTO UGYFEL (UGYFELSZAM,NEV,SZULETESIHELY,SZULETESIIDO,';
  _pcs := _pcs + 'KULFOLDI,TOROLVE)'+_sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_ugyfelszam) + ',';
  _pcs := _pcs + chr(39) + _nev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _szulhely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _szulido + chr(39) + ',';
  _pcs := _pcs + inttostr(_kulfoldi)+',1)';
  LocalParancs(_pcs);
end;


// =============================================================================
                       procedure TForm2.UpdateVtemp;
// =============================================================================

// Az összes eredmény adatot a VTEMP-be menti bele

begin
  _mess := 'Az ügyfél adatait végül beirja a Vtemp adatbázisba';
  logirorutin(pchar(_mess));

  _plombaszam := _nevtabla + inttostr(_sorszam);
  _pcs := 'UPDATE VTEMP SET UGYFELTIPUS='+chr(39)+'K'+chr(39);
  _pcs := _pcs + ',UGYFELNEV=' + chr(39)+_nev + chr(39);
  _pcs := _pcs + ',UGYFELSZAM='+inttostr(_ugyfelszam);
  _pcs := _pcs + ',SORSZAM=' + inttostr(_sorszam);
  _pcs := _pcs + ',NEVTABLA='+chr(39)+_nevtabla+chr(39);
  _pcs := _pcs + ',PLOMBASZAM=' + chr(39) + _plombaszam + chr(39);
  LocalParancs(_pcs);
end;


// =============================================================================
              procedure TForm2.Remoteparancs(_ukaz: string);
// =============================================================================

begin
  RemoteDbase.close;
  remotedbase.DatabaseName := _remoteFdbPath;
  remotedbase.connected := True;
  if remotetranz.InTransaction then remoteTranz.commit;
  remotetranz.StartTransaction;

  with remoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  RemoteTranz.commit;
  remoteDbase.close;
end;


// =============================================================================
           procedure TForm2.KUGYMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

// Mégsem akarja azonositani az ügyfélt - igy kilép a programból -1-gyel

begin
  logirorutin(pchar('Mégsem akarja magát azonositani'));
  _mResult := -1;
  Kilepo.Enabled := true;
end;


// =============================================================================
                  procedure Tform2.VTempAlapraAllitas;
// =============================================================================

begin
  _pcs := 'UPDATE VTEMP SET UGYFELTIPUS='+chr(39)+' '+chr(39);
  _pcs := _pcs + ',UGYFELSZAM=0,NEVTABLA='+chr(39)+' '+chr(39);
  _pcs := _pcs + ',SORSZAM=0,PLOMBASZAM='+chr(39)+' '+chr(39);
  LocalParancs(_pcs);
end;

// =============================================================================
          procedure TForm2.NOCHOOSEGOMBClick(Sender: TObject);
// =============================================================================

begin
  LocalQuery.close;
  LocalDbase.close;

  logirorutin(pchar('Mégsem választ a helyi ügyfelek közül'));

  KeresoPanel.Visible := False;
  Activecontrol := NevEdit;
end;


// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                        SEGÉD PROGRAMOK ÉS FUNKCIÓK                         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                  procedure TForm2.ParameterBeolvasas;
// =============================================================================

begin
  Localdbase.Connected := true;
  with LocalQuery do
    begin
      Close;
      sql.clear;
      Sql.Add('SELECT * FROM VTEMP');
      Open;

      _fizetendo := FieldByName('FIZETENDO').asInteger;
      _kulfoldi := FieldByNAme('KULFOLDI').asInteger;
      _konverzio := FieldByNAme('KONVERZIO').asInteger;

      Close;

      Sql.clear;
      Sql.add('SELECT * FROM HARDWARE');
      Open;
      _host := trim(FieldByName('HOST').asString);
      _megnyitottnap := trim(fieldbyname('MEGNYITOTTNAP').AsString);
      close;
    end;
  Localdbase.close;

  if _konverzio=1 then _fizetendo := round(2*_fizetendo);

end;

// =============================================================================
                 procedure TForm2.LocalParancs(_ukaz: string);
// =============================================================================

begin
  LocalDbase.connected := True;
  if LocalTranz.InTransaction then LocalTranz.StartTransaction;
  LocalTranz.StartTransaction;

  with LocalQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  LocalTranz.commit;
  LocalDbase.close;
end;


// =============================================================================
                 function TForm2.Angolra(_huName: string): string;
// =============================================================================

var _whn,_z,_asc: byte;

begin
  result  := '';

  _huname := uppercase(trim(_huname));
  _whn    := length(_huname);

  if _whn=0 then exit;

  _z := 1;
  while _z<=_whn do
    begin
      _asc := ord(_huname[_z]);
      _asc := HutoGb(_asc);

      result := result + chr(_asc);
      inc(_z);
    end;
  result := DoubleKill(result);
end;

// =============================================================================
                   function TForm2.DoubleKill(_s: string): string;
// =============================================================================

var _w,_asc,_utasc,_y: byte;

begin
  result := '';

  _s := trim(_s);
  _w := length(_s);

  // Ha üres string -> nincs mit tömöriteni
  if _w=0 then exit;

  _y     := 1;
  _utasc := 0;       // default

  while _y<=_w do
    begin
      _asc := ord(_s[_y]);
      if (_asc=32) and (_utasc=32) then
        begin
          inc(_y);
          continue;
        end;

      if _asc=32 then
        begin
          result := result + ' ';
          _utasc := 32;
          inc(_y);
          Continue;
        end;

      if (_asc<48) or (_asc>90) then
        begin
          inc(_y);
          Continue;
        end;

      if (_asc>57) and (_asc<65) then
        begin
          inc(_y);
          Continue;
        end;

      result := Result + chr(_asc);
      _utasc := _asc;
      inc(_y);
    end;
end;

// =============================================================================
                   function TForm2.HutoGb(_kod: byte): byte;
// =============================================================================

var _r: byte;

begin
  _r := _kod;
  case _kod of
    186: _r := 69;  // E
    187: _r := 79;  // O
    193: _r := 65;  // A
    201: _r := 69;  // E
    211: _r := 79;  // O
    213: _r := 79;  // O
    214: _r := 79;  // O
    218: _r := 85;  // U
    219: _r := 85;  // U
    220: _r := 85;  // U
    222: _r := 65;  // A
    226: _r := 73;  // I
    205: _r := 73;  // I

    225: _r := 97;  // a
    233: _r := 101; // e
    237: _r := 105; // i
    243: _r := 111; // o
    246: _r := 111; // o
    245: _r := 111; // o
    250: _r := 117; // u
    252: _r := 117; // u
    251: _r := 117; // u
  end;
  result := _r;
end;

// =============================================================================
               function TForm2.Tomorito(_ts: string): string;
// =============================================================================

var _ws,_y,_aktasc: byte;

begin
  _ts := trim(_ts);
  result := '';

  if _ts='' then exit;

  _ts := uppercase(_ts);
  _ws := length(_ts);
  _y := 1;

  while _y<=_ws do
    begin
      _aktasc := ord(_ts[_y]);
      if (_aktasc>47) and (_aktasc<58) then result := result + chr(_aktasc);
      if (_aktasc>64) and (_aktasc<91) then result := result + chr(_aktasc);
      inc(_y);
    end;
end;

// =============================================================================
                procedure TForm2.KilepoTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  if _mresult=0 then _mresult := 3;
  Modalresult := _mResult;
end;

// =============================================================================
              function TForm2.DatumCtrl(_ds: string): boolean;
// =============================================================================

var _cevs,_chos,_cnaps: string;

begin
  result := False;

  if length(_ds)<>10 then exit;

  if (midstr(_ds,5,1)<>'.') or (midstr(_ds,8,1)<>'.')  then exit;

  _cevs := leftstr(_ds,4);
  _chos := midstr(_ds,6,2);
  _cnaps := midstr(_ds,9,2);

  if (_cevs<'1920') or (_cevs>'2020') then exit;
  if (_chos<'01') or (_chos>'12') then exit;
  if (_cnaps<'01') or (_cnaps>'31') then exit;

  result := True;

end;

// =============================================================================
            procedure TForm2.NevEditEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clyellow;
end;

// =============================================================================
            procedure TForm2.NevEditExit(Sender: TObject);
// =============================================================================

begin
   Tedit(sender).Color := clwindow;
end;

// =============================================================================
              function TForm2.HunStrToDate(_s: string): Tdatetime;
// =============================================================================


var _xevs,_xhos,_xnaps: string;
    _xev,_xho,_xnap: word;

begin
  _xevs := leftstr(_s,4);
  _xhos := midstr(_s,6,2);
  _xnaps:= midstr(_s,9,2);

  Val(_xevs,_xev,_code);
  val(_xhos,_xho,_code);
  val(_xnaps,_xnap,_code);

  result := encodedate(_xev,_xho,_xnap);
end;

// =============================================================================
            function TForm2.Getnapdiff(_ds1,_ds2: string): extended;
// =============================================================================

var _dt1,_dt2: TDateTime;

begin
  _dt1 := Hunstrtodate(_ds1);
  _dt2 := Hunstrtodate(_ds2);
  result := _dt1-_dt2;
end;


// =============================================================================
               function TForm2.Ftform(_numft: integer): string;
// =============================================================================

var _wres,_f1: byte;

begin
  result := inttostr(_numFt);
  _wres := length(result);
  if _wres<4 then exit;

  if _wres>6 then
    begin
      _f1 := _wres-6;
      result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3)+' '+midstr(result,_f1+4,3);
      exit;
    end;
  _f1 := _wres-3;
  result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3);
end;




procedure TForm2.TOVABBGOMBClick(Sender: TObject);
begin
  Modalresult := 2;
end;

end.
