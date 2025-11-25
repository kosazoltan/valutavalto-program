unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, ExtCtrls,
  StrUtils, Buttons, jpeg;

type
  TForm2 = class(TForm)

    HrkQuery      : TIBQuery;
    HrkDbase      : TIBDatabase;
    HrkTranz      : TIBTransaction;

    ValQuery      : TIBQuery;
    ValDbase      : TIBDatabase;
    ValTranz      : TIBTransaction;

    Kilepo        : TTimer;

    E1            : TEdit;
    E2            : TEdit;
    E3            : TEdit;
    E4            : TEdit;
    E5            : TEdit;
    E6            : TEdit;
    E7            : TEdit;

    Label2        : TLabel;
    Label3        : TLabel;
    Label4        : TLabel;
    Label5        : TLabel;
    Label6        : TLabel;
    Label7        : TLabel;
    Label8        : TLabel;
    Label1        : TLabel;
    Label9        : TLabel;
    Label10       : TLabel;

    CimletezoPanel: TPanel;
    CimletPanel   : TPanel;
    KeszletPanel  : TPanel;
    P1            : TPanel;
    P2            : TPanel;
    P3            : TPanel;
    P4            : TPanel;
    P5            : TPanel;
    P6            : TPanel;
    P7            : TPanel;

    CimMegsemGomb : TBitBtn;
    CimOkeGomb    : TBitBtn;

    Shape1        : TShape;
    ALAPPANEL: TPanel;
    Shape2: TShape;
    Label11: TLabel;
    Memo1: TMemo;
    Label12: TLabel;
    Image1: TImage;

    procedure AlapadatBeolvasas;
    procedure BlokkFejKitoltes;
    procedure BlokkTetelKitoltes;
    procedure Cimletezes;
    procedure CimOkeGombClick(Sender: TObject);
    procedure CimMegsemGombClick(Sender: TObject);
    procedure E1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure E1Enter(Sender: TObject);
    procedure E1Exit(Sender: TObject);
    procedure EladasQRKodja;
    procedure ForintKivezetes;
    procedure FormActivate(Sender: TObject);
    procedure HaziPenztarBevetel;
    procedure HrkEladas;
    procedure Hrkparancs(_ukaz: string);
    procedure KilepoTimer(Sender: TObject);
    procedure ThFejKitoltes;
    procedure ThtetelKitoltes;
    procedure ThQrKodja;
    procedure ThTempKitoltes;
    procedure Tombbetoltes;
    procedure ValParancs(_ukaz: string);
    procedure Vegigszamol;
    procedure VTempKitoltes;

    function Ftform(_n: integer): string;
    function Getidos: string;
    function GetHaziZaro: integer;
    function GetNapiZaro: integer;
    function Nulele(_n: integer; _h: byte): string;
    
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _top,_left,_height,_width: word;

  _edit  : array[1..7] of TEdit;
  _panel : array[1..7] of TPanel;
  _cimlet: array[1..7] of integer = (1000,500,200,100,50,20,10);
  _cert  : array[1..7] of integer;

  _aktedit : TEdit;
  _aktPanel: TPanel;

  _LastE,_LastFf,_ugyfelszam,_penztar,_code,_ftOsszeg,_megbizott: integer;
  _aktbj,_aktcert,_sumcert: integer;

  _mamas,_pcs,_prosnev,_idkod,_penztars,_bizonylatszam,_idos,_lastdatum: string;
  _aktbjs: string;

  _sorveg: string = chr(13) + chr(10);

  _hazizaro,_napizaro,_mresult,_jogiugyfelszam,_lastbevetel,_lastkiadas: integer;
  _lastnyito,_recno,_nyito,_bevetel,_zaro,_kiadas,_be: integer;

  _y,_tag,_bill: byte;

  _ujRekord: boolean;

function qrdisplayrutin: integer; stdcall; external 'c:\valuta\bin\QRGENER.dll';
function blokknyomtatas(_para: integer):integer; stdcall; external 'c:\valuta\bin\bloknyom.dll';
function regeneralorutin(_para: integer): integer; stdcall; external 'c:\valuta\bin\regen.dll';
function horvatkunazaro: integer; stdcall;


implementation

{$R *.dfm}


// =============================================================================
              function horvatkunazaro: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.showmodal;
  form2.free;
end;



// =============================================================================
                procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].width;

  _top := round((_height-768)/2);
  _left := round((_width-1024)/2);

  Top := _top;
  Left := _left;
  Height := 761;
  Width := 1015;

  Memo1.Lines.clear;
  Memo1.Clear;

  HrkDbase.close;
  Hrkdbase.DatabaseName := 'c:\valuta\database\hazihrk.fdb';

  with AlapPanel do
    begin
      Top := 140;
      left := 8;
      Visible := true;
      Repaint;
    end;

  TombbeToltes;
  _haziZaro := GetHaziZaro;
  _napizaro := GetNapiZaro;

  if _hazizaro=0 then
    begin
      if _napiZaro=0 then
        begin
          Memo1.Lines.Add('NINCS HRK KÉSZLET');
          _mResult := 2;
          Kilepo.enabled := true;
          exit;
        end;
    end;

  if _napizaro>0 then
    begin
      AlapAdatBeolvasas;
      HaziPenztarBevetel;
      Hrkeladas;
      ForintKivezetes;
      regeneralorutin(0);

      _pcs := 'UPDATE CIMINI SET AKTKESZLET=0,CIMLETEZETT=0' + _sorveg;
      _pcs := _pcs + 'WHERE VALUTANEM='+chr(39)+'HRK'+chr(39);
      ValParancs(_pcs);
    end;
  Cimletezes;
end;


// =============================================================================
                    procedure TForm2.AlapadatBeolvasas;
// =============================================================================

begin
  memo1.Lines.add('Alapadatok beolvasása ...');
  _pcs := 'SELECT * FROM JOGISZEMELY WHERE (JOGISZEMELYNEV LIKE '+chr(39);
  _pcs := _pcs + 'EXCLUSIVE BEST%' + chr(39)+ ') AND (MEGBIZOTTNEVE=';
  _pcs := _pcs + chr(39) + 'KOSA ZOLTAN' + chr(39) + ')';

  Valdbase.connected := true;
  with Valquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;

      _mamas := FieldByNAme('MEGNYITOTTNAP').asString;
      _prosnev := trim(FieldByNAme('PENZTAROSNEV').asString);
      _idkod := TRIM(FieldByNAme('IDKOD').asString);

      Close;
      sql.clear;
      sql.Add('SELECT * FROM PENZTAR');
      Open;
      _penztars := trim(FieldByNAme('PENZTARKOD').asString);

      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _jogiugyfelszam := FieldByNAme('UGYFELSZAM').asInteger;
      _megbizott:= FieldByNAme('MEGBIZOTTSZAMA').asInteger;


      close;
      Sql.clear;
      sql.add('SELECT * FROM UTOLSOBLOKKOK');
      Open;
      _lastE  := FieldByNAme('UTOLSOELADASBLOKK').asInteger;
      _lastFF := FieldByNAme('UTOLSOFORINTATADASBLOKK').asInteger;
      Close;
    end;
  Valdbase.close;

  val(_penztars,_penztar,_code);
  _penztars := Nulele(_penztar,3);

  _idos := Getidos;

end;

// =============================================================================
                     procedure TForm2.HaziPenztarBevetel;
// =============================================================================

begin
  Memo1.Lines.Add('Kuna bevétele a házipénztárba ...');

  Hrkdbase.Connected := true;
  with HrkQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HRKDATA');
      Open;
      _be := fieldByName('BESORSZAM').asInteger;
      Close;
    end;
  Hrkdbase.close;

  inc(_be);
  _bizonylatszam := 'B-'+nulele(_be,5);

  _pcs := 'INSERT INTO HRKSZAMLAK (DATUM,IDO,BIZONYLATSZAM,BEVETEL,STORNO)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + CHR(39) + _mamas +chr(39) + ',';
  _pcs := _pcs + chr(39) + _idos + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_napizaro) + ',1)';
  HrkParancs(_pcs);

  _pcs := 'UPDATE HRKDATA SET BESORSZAM='+inttostr(_be);
  HrkParancs(_pcs);

  // ---------------------- HRK BEVÉTEL A HÁZI PÉNZTÁRBA -----------------------

  _nyito   := 0;
  _bevetel := 0;
  _kiadas  := 0;
  _ujrekord:= True;

  Hrkdbase.Connected := true;

  _pcs := 'SELECT * FROM HRKNAPLO';
  with Hrkquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
      Close;
    end;

  if _recno>0 then
    begin
      _pcs := 'SELECT * FROM HRKNAPLO WHERE DATUM='+CHR(39)+_mamas+chr(39);
      with Hrkquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _recno := recno;
         end;

      if _recno>0 then
        begin
          _ujrekord := False;
          _nyito := Hrkquery.FieldByName('NYITO').asInteger;
          _bevetel := HrkQuery.fieldbyname('BEVETEL').asInteger;
          _kiadas := HrkQuery.FieldByNAme('KIADAS').asInteger;
          HrkQuery.close;
        end else
        begin
           _pcs := 'SELECT * FROM HRKNAPLO ORDER BY DATUM';
           with Hrkquery do
             begin
               Close;
               sql.clear;
               sql.add(_pcs);
               Open;
               Last;
               _nyito := Fieldbyname('ZARO').asInteger;
               Close;
             end;
        end;
    end;

  Hrkdbase.close;

  _bevetel := _bevetel + _napizaro;
  _zaro := _nyito+_bevetel-_kiadas;

  if _ujrekord then
    begin
      _pcs := 'INSERT INTO HRKNAPLO (DATUM,IDO,NYITO,BEVETEL,KIADAS,ZARO)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + CHR(39) + _mamas + chr(39) + ',';
      _pcs := _pcs + chr(39) + _idos + chr(39) + ',';
      _pcs := _pcs + inttostr(_nyito) + ',';
      _pcs := _pcs + inttostr(_bevetel) + ',';
      _pcs := _pcs + inttostr(_kiadas) + ',';
      _pcs := _pcs + inttostr(_zaro) + ')';
    end else
    begin
      _pcs := 'UPDATE HRKNAPLO SET BEVETEL='+inttostr(_bevetel)+',ZARO=';
      _pcs := _pcs + inttostr(_zaro) + _sorveg;
      _pcs := _pcs + 'WHERE DATUM='+chr(39)+_mamas + chr(39);
    end;
    
  HrkParancs(_pcs);

  _pcs := 'UPDATE HRKDATA SET AKTKESZLET='+inttostr(_zaro);
  HrkParancs(_pcs);
end;

// =============================================================================
                           procedure TForm2.HrkEladas;
// =============================================================================

begin
  mEMO1.Lines.Add('Kuna eladása Exclusive Change-nek');
  inc(_laste);
  _pcs := 'UPDATE UTOLSOBLOKKOK SET UTOLSOELADASBLOKK=' + inttostr(_Laste);
  ValParancs(_pcs);

  _bizonylatszam := 'E' + _penztars + nulele(_lastE,6);
  _ftOsszeg := trunc(35*_napiZaro);

  BlokkFejKitoltes;
  BlokkTetelKitoltes;

  EladasQrkodja;

  VtempKitoltes;
  blokknyomtatas(1);
end;


// =============================================================================
                      procedure TForm2.BlokkFejKitoltes;
// =============================================================================

begin

  // Blokkfej összeállitás:

  _pcs := 'INSERT INTO BLOKKFEJ (BIZONYLATSZAM,TIPUS,DATUM,IDO,OSSZESFORINTERTEK,';
  _pcs := _pcs + 'UGYFELTIPUS,UGYFELSZAM,UGYFELNEV,TETEL,PENZTAROSNEV,MEGBIZOTT,';
  _pcs := _pcs + 'MEGBIZOSZAM,STORNO,PLOMBASZAM,NETTO,KEZELESIDIJ,FIZETENDO,';
  _pcs := _pcs + 'IDKOD,FIZETOESZKOZ,ADOSZAM,UGYFELCIM,KEREKITES)'+_sorveg;

  _pcs := _pcs + 'VALUES (' +chr(39)+_bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + 'E' + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mamas + chr(39) + ',';
  _pcs := _pcs + chr(39) + _idos + chr(39) + ',';
  _pcs := _pcs + inttostr(_Ftosszeg) + ',';
  _pcs := _pcs + chr(39) + 'J' + chr(39) + ',';
  _pcs := _pcs + inttostr(_jogiugyfelszam) + ',';
  _pcs := _pcs + chr(39) + 'EXCLUSIVE BEST CHANGE ZRT' + chr(39) + ',';
  _pcs := _pcs + '1,';
  _pcs := _pcs + chr(39) + _prosnev + chr(39) + ',';
  _pcs := _pcs + '0,';
  _pcs := _pcs + inttostr(_megbizott) + ',';
  _pcs := _pcs + '1,';
  _pcs := _pcs + chr(39) + 'JOGI43' + chr(39) + ',';
  _pcs := _pcs + inttostr(_ftosszeg) + ',';
  _pcs := _pcs + '0,';
  _pcs := _pcs + inttostr(_ftosszeg) + ',';
  _pcs := _pcs + chr(39) + _idkod + chr(39) + ',';
  _pcs := _pcs + '1,';
  _pcs := _pcs + chr(39) + '11788670-2-02' + chr(39) + ',';
  _pcs := _pcs + chr(39) + '7621 PÉCS CITROM UTCA 2-6' + chr(39) + ',0)';
  Valparancs(_pcs);
end;

// =============================================================================
                      procedure TForm2.BlokkTetelKitoltes;
// =============================================================================

begin
  _pcs := 'INSERT INTO BLOKKTETEL (BIZONYLATSZAM,VALUTANEM,ARFOLYAM,ELSZAMOLASIARFOLYAM,';
  _pcs := _pcs + 'BANKJEGY,FORINTERTEK,ELOJEL,COIN,STORNO,DATUM)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + CHR(39) + _bizonylatszam +  chr(39) + ',';
  _pcs := _pcs + chr(39) + 'HRK' + chr(39) + ',';
  _pcs := _pcs + inttostr(3500) + ',';
  _pcs := _pcs + inttostr(3500) + ',';
  _pcs := _pcs + inttostr(_napizaro) + ',';
  _pcs := _pcs + inttostr(_ftOsszeg) + ',';
  _pcs := _pcs + chr(39) + '-' + chr(39) + ',0,1,';
  _pcs := _pcs + chr(39) + _mamas + chr(39) + ')';

  ValParancs(_pcs);
end;

// =============================================================================
                        procedure TForm2.EladasQRKodja;
// =============================================================================

begin
  _pcs := 'DELETE FROM QRPARAMS';
  ValParancs(_pcs);

  _pcs := 'INSERT INTO QRPARAMS (VALUTANEM,ARFOLYAM,BANKJEGY,BIZONYLATSZAM,';
  _pcs := _pcs + 'OKMANYTIPUS,AZONOSITO,KEZELESIDIJ,KULFOLDI,FIZETENDO,NUMBER)'+_sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + 'HRK' + chr(39) + ',';
  _pcs := _pcs + inttostr(3500) + ',';
  _pcs := _pcs + inttostr(_napizaro) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39)  + ',';
  _pcs := _pcs + chr(39) + 'SZIG' + chr(39) + ',';
  _pcs := _pcs + chr(39) + '949851TA' +chr(39) + ',';
  _pcs := _pcs + '0,';
  _pcs := _pcs + '0,';
  _pcs := _pcs + inttostr(_ftOsszeg) + ',';
  _pcs := _pcs + '8)';
  ValParancs(_pcs);
  qrdisplayrutin;
end;


// =============================================================================
                        procedure TForm2.VtempKitoltes;
// =============================================================================

begin
  _pcs := 'DELETE FROM VTEMP';
  ValParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (VALUTANEM,VALUTANEV,ARFOLYAM,ELSZAMOLASIARFOLYAM,';
  _pcs := _pcs + 'BANKJEGY,FORINTERTEK,BIZONYLATSZAM,DATUM,TIPUS,STORNO,UGYFELTIPUS,';
  _pcs := _pcs + 'UGYFELSZAM,TETEL,PENZTAROSNEV,ELOJEL,OSSZESFORINTERTEK,KEZELESIDIJ,';
  _pcs := _pcs + 'SECURLEVEL,NETTO,FIZETENDO,IDO,IDKOD,PLOMBASZAM,FIZETOESZKOZ)';

  _pcs := _pcs + 'VALUES (' + chr(39) + 'HRK' + chr(39) + ',';
  _pcs := _pcs + chr(39) + 'HORVAT KUNA' + chr(39) + ',';
  _pcs := _pcs + inttostr(3500) + ',';
  _pcs := _pcs + inttostr(3500) + ',';
  _pcs := _pcs + inttostr(_napiZaro) + ',';
  _pcs := _pcs + inttostr(_ftOsszeg) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mamas + chr(39) + ',';
  _pcs := _pcs + chr(39) + 'E' + CHR(39) + ',';
  _pcs := _pcs + '1,';
  _pcs := _pcs + CHR(39) + 'J' + CHR(39) + ',';
  _pcs := _pcs + inttostr(_ugyfelszam) + ',';
  _pcs := _pcs + '1,';
  _pcs := _pcs + chr(39) + _prosnev + CHR(39) + ',';
  _pcs := _pcs + CHR(39) + '-' + chr(39) + ',';
  _pcs := _pcs + inttostr(_ftosszeg) + ',';
  _pcs := _pcs + '0,';
  _pcs := _pcs + '1,';
  _pcs := _pcs + inttostr(_ftOsszeg) + ',';
  _pcs := _pcs + inttostr(_ftOsszeg) + ',';
  _pcs := _pcs + chr(39) + _idos + chr(39) + ',';
  _pcs := _pcs + chr(39) + _idkod + chr(39) + ',';
  _pcs := _pcs + chr(39) + 'JOGI43' +chr(39) + ',';
  _pcs := _pcs + '1)';
  ValParancs(_pcs);
end;

// =============================================================================
                procedure TForm2.ForintKivezetes;
// =============================================================================

begin
  Memo1.Lines.add('Forint kivitele a TH pénztárba ...');
  THFejkitoltes;
  ThTetelKitoltes;
  THqrKodja;
  ThTempKitoltes;
  blokknyomtatas(1);
end;

// =============================================================================
                          procedure TForm2.THFejKitoltes;
// =============================================================================

begin
  inc(_lastFF);
  _pcs := 'UPDATE UTOLSOBLOKKOK SET UTOLSOFORINTATADASBLOKK=' + inttostr(_LastFF);
  ValParancs(_pcs);

  _bizonylatszam := 'FF' + _penztars + nulele(_lastFF,5);

  _pcs := 'INSERT INTO BLOKKFEJ (BIZONYLATSZAM,TIPUS,DATUM,IDO,OSSZESFORINTERTEK,';
  _pcs := _pcs + 'TETEL,TARSPENZTARKOD,MEGBIZOTT,MEGBIZOSZAM,STORNO,PLOMBASZAM,';
  _pcs := _pcs + 'SZALLITONEV,KEZELESIDIJ,FIZETENDO,PENZTAROSNEV,IDKOD,';
  _pcs := _pcs + 'FIZETOESZKOZ)'+_sorveg;

  _pcs := _pcs + 'VALUES (' +chr(39)+_bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + 'F' + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mamas + chr(39) + ',';
  _pcs := _pcs + chr(39) + _idos + chr(39) + ',';
  _pcs := _pcs + inttostr(_Ftosszeg) + ',';
  _pcs := _pcs + '1,';
  _pcs := _pcs + chr(39) + 'TH' + chr(39) + ',';
  _pcs := _pcs + '0,0,1,';
  _pcs := _pcs + chr(39) + 'x' + chr(39) + ',';
  _pcs := _pcs + chr(39) + 'x' + chr(39) + ',';
  _pcs := _pcs + '0,';
  _pcs := _pcs + inttostr(_ftosszeg) + ',';
  _pcs := _pcs + chr(39) + _prosnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _idkod + chr(39) + ',';
  _pcs := _pcs + '1)';
  Valparancs(_pcs);
end;

// =============================================================================
                      procedure TForm2.THTetelKitoltes;
// =============================================================================

begin
  _pcs := 'INSERT INTO BLOKKTETEL (BIZONYLATSZAM,VALUTANEM,ARFOLYAM,ELSZAMOLASIARFOLYAM,';
  _pcs := _pcs + 'BANKJEGY,FORINTERTEK,ELOJEL,COIN,STORNO,DATUM)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _bizonylatszam +  chr(39) + ',';
  _pcs := _pcs + chr(39) + 'HUF' + chr(39) + ',';
  _pcs := _pcs + inttostr(100) + ',';
  _pcs := _pcs + inttostr(100) + ',';
  _pcs := _pcs + inttostr(_ftOsszeg) + ',';
  _pcs := _pcs + inttostr(_ftOsszeg) + ',';
  _pcs := _pcs + chr(39) + '-' + chr(39) + ',';
  _pcs := _pcs + '0,1,';
  _pcs := _pcs + chr(39) + _mamas + chr(39) + ')';

  ValParancs(_pcs);
end;

// =============================================================================
                       procedure TForm2.ThqrKodja;
// =============================================================================

begin
  _pcs := 'DELETE FROM QRPARAMS';
  ValParancs(_pcs);

  _pcs := 'INSERT INTO QRPARAMS (NUMBER,VALUTANEM,BANKJEGY,BIZONYLATSZAM)' + _sorveg;
  _pcs := _pcs + 'VALUES (6,';
  _pcs := _pcs + chr(39) + 'HUF' + chr(39) + ',';
  _pcs := _pcs + inttostr(_ftOsszeg) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ')';
  ValParancs(_pcs);
  qrdisplayrutin;
end;


// =============================================================================
                   procedure TForm2.THTempKitoltes;
// =============================================================================

begin
  _pcs := 'DELETE FROM VTEMP';
  ValParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (VALUTANEM,VALUTANEV,ARFOLYAM,ELSZAMOLASIARFOLYAM,';
  _pcs := _pcs + 'BANKJEGY,FORINTERTEK,BIZONYLATSZAM,DATUM,TIPUS,STORNO,TETEL,';
  _pcs := _pcs + 'PENZTARKOD,OSSZESFORINTERTEK,FIZETENDO,IDO,SZALLITONEV,';
  _pcs := _pcs + 'PLOMBASZAM,TARSPENZTARNEV,FIZETOESZKOZ)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + CHR(39) + 'HUF' +chr(39) + ',';
  _pcs := _pcs + chr(39) + 'MAGYAR FORINT' + chr(39) + ',';
  _pcs := _pcs + inttostr(100) + ',';
  _pcs := _pcs + inttostr(100) + ',';
  _pcs := _pcs + inttostr(_ftOsszeg) + ',';
  _pcs := _pcs + inttostr(_ftOsszeg) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mamas + chr(39) + ',';
  _pcs := _pcs + chr(39) + 'F' + chr(39) + ',';
  _pcs := _pcs + '1,1,';
  _pcs := _pcs + chr(39) + 'TH' + chr(39) + ',';
  _pcs := _pcs + inttostr(_ftOsszeg) + ',';
  _pcs := _pcs + inttostr(_ftOsszeg) + ',';
  _pcs := _pcs + chr(39) + _idos + chr(39) + ',';
  _pcs := _pcs + chr(39) + 'x' + chr(39) + ',';
  _pcs := _pcs + chr(39) + 'x' + chr(39) + ',';
  _pcs := _pcs + chr(39) + 'TOBBLET-HIANY PENZTAR' + chr(39) + ',';
  _pcs := _pcs + '1)';
  Valparancs(_pcs);
end;

// =============================================================================
               function TForm2.Nulele(_n: integer; _h: byte): string;
// =============================================================================

begin
  result := inttostr(_n);
  while length(result)<_h do result := '0' + result;
end;

// =============================================================================
              procedure TForm2.valparancs(_ukaz: string);
// =============================================================================

begin
  Valdbase.connected := true;
  if valtranz.InTransaction then valtranz.Commit;
  Valtranz.StartTransaction;
  with Valquery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Valtranz.commit;
  Valdbase.close;
end;


// =============================================================================
              procedure TForm2.Hrkparancs(_ukaz: string);
// =============================================================================

begin
  HRKdbase.connected := true;
  if Hrktranz.InTransaction then Hrktranz.Commit;
  Hrktranz.StartTransaction;
  with Hrkquery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Hrktranz.commit;
  Hrkdbase.close;
end;


// =============================================================================
                  function TForm2.Getidos: string;
// =============================================================================

begin
  result := timetostr(time);
  if midstr(result,2,1)=':' then result := '0' + RESULT;
  result := leftstr(result,5);
end;


// =============================================================================
                  procedure TForm2.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := _mResult;
end;

// =============================================================================
                function TForm2.GetHaziZaro: integer;
// =============================================================================

begin
  result       := 0;
  _lastdatum   := '2023.01.01';
  _lastnyito   := 0;
  _lastBevetel := 0;
  _lastKiadas  := 0;

  _pcs := 'SELECT * FROM HRKNAPLO ORDER BY DATUM';

  HrkDbase.close;
  Hrkdbase.DatabaseName := 'c:\valuta\database\hazihrk.fdb';
  Hrkdbase.Connected := true;

  with HrkQuery do
    begin
      Close;
      Sql.clear;
      sql.add(_PCS);
      Open;
      Last;
      _recno := Recno;
    end;

   if _recno>0 then
     begin
       result       := HrkQuery.FieldByNAme('ZARO').asInteger;
       _lastDatum   := HrkQuery.FieldByNAme('DATUM').asString;
       _lastNyito   := HrkQuery.FieldByNAme('NYITO').asInteger;
       _lastBevetel := HrkQuery.Fieldbyname('BEVETEL').asInteger;
       _lastkiadas  := HrkQuery.Fieldbyname('KIADAS').asInteger;
       Close;
     end;
  Hrkdbase.close;
end;

// =============================================================================
                  function TForm2.GetNapiZaro: integer;
// =============================================================================

begin
  _pcs := 'SELECT * FROM ARFOLYAM WHERE VALUTANEM='+chr(39)+'HRK'+chr(39);
  _napiZaro := 0;
  valdbase.Connected := True;
  with ValQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      result := FieldByNAme('ZARO').asInteger;
      Close;
    end;
  Valdbase.Close;
end;


// =============================================================================
                    procedure TForm2.Cimletezes;
// =============================================================================

begin
  AlapPanel.Visible := false;
  _hazizaro := getHaziZaro;
  _y := 1;
  while _y<=7 do
    begin
      _edit[_y].Text := '';
      _panel[_y].Caption := '0';
      _cert[_y] := 0;
      inc(_y);
    end;

  CimletPanel.Caption := '0';
  KeszletPanel.caption := Ftform(_haziZaro);
  with CimletezoPanel do
    begin
      top := 120;
      left := 300;
      Visible := true;
      BringtoFront;
      Repaint;
    end;
  Activecontrol := E1;
end;

// =============================================================================
             function TForm2.Ftform(_n: integer): string;
// =============================================================================

var _f1,_wlen: byte;

begin
  result := inttostr(_n);
  _wlen := length(result);
  if _wlen<4 then exit;

  if _wlen>6 then
    begin
      _f1 := _wlen-6;
      result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3)+' '+midstr(result,_f1+4,3);
      exit;
    end;
  _f1 := _wlen-3;
  result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3);
end;

// =============================================================================
        procedure TForm2.E1KeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  _tag := Tedit(Sender).Tag;
  _bill := ord(key);
  if _bill=40 then
    begin
      Vegigszamol;
      if _tag<7 then inc(_tag) else _tag := 1;
      _aktedit := _edit[_tag];
      Activecontrol := _aktEdit;
      exit;
    end;

  if _bill=38 then
    begin
      Vegigszamol;
      if _tag>1 then dec(_tag) else _tag := 7;
      _aktedit := _edit[_tag];
      Activecontrol := _aktEdit;
      exit;
    end;

  if ord(key)<>13 then exit;

  VegigSzamol;

  inc(_tag);
  if _tag>7 then _tag := 1;
  _aktedit := _edit[_tag];
  Activecontrol := _aktedit;
end;

// =============================================================================
                   procedure TForm2.Vegigszamol;
// =============================================================================

begin
 _aktedit  := _edit[_tag];
  _aktbjs  := trim(_aktedit.Text);
  val(_aktbjs,_aktbj,_code);

  _aktcert := trunc(_aktbj*_cimlet[_tag]);
  _panel[_tag].Caption := FtForm(_aktcert);

  _cert[_tag] := _aktcert;
  _sumcert := 0;

  _y := 1;
  while _y<=7 do
    begin
      _sumcert := _sumcert + _cert[_y];
      inc(_y);
    end;

  Cimletpanel.Caption := ftform(_sumcert);

  if _sumcert = _haziZaro then
    begin
      Cimletpanel.Font.Color := clRed;
      Keszletpanel.Font.Color := clRed;
      CimOkeGomb.Enabled := True;
    end else
    begin
      Cimletpanel.Font.Color := clBlack;
      Keszletpanel.Font.Color := clBlack;
      CimOkeGomb.Enabled := False;
    end;
end;


// =============================================================================
               procedure TForm2.E1Enter(Sender: TObject);
// =============================================================================

begin
  Tedit(Sender).Color := clYellow;
end;

// =============================================================================
                procedure TForm2.E1Exit(Sender: TObject);
// =============================================================================

begin
  tEdit(sender).Color := clWhite;
end;

// =============================================================================
                    procedure TForm2.TombBetoltes;
// =============================================================================

begin
  _edit[1] := E1;
  _edit[2] := E2;
  _edit[3] := E3;
  _edit[4] := E4;
  _edit[5] := E5;
  _edit[6] := E6;
  _edit[7] := E7;

  _panel[1] := P1;
  _panel[2] := P2;
  _panel[3] := P3;
  _panel[4] := P4;
  _panel[5] := P5;
  _panel[6] := P6;
  _panel[7] := P7;
end;

// =============================================================================
            procedure TForm2.CIMOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 1;
  Kilepo.Enabled := true;
end;

// =============================================================================
           procedure TForm2.CIMMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := -1;
  Kilepo.Enabled := true;
end;

end.
