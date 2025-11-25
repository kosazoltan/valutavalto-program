unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Calendar, ExtCtrls, DB, IBCustomDataSet, Grids,
  DBGrids, IBTable, IBDatabase, IBQuery, Mask, DBCtrls, Buttons,dateUtils,
  StrUtils, jpeg;

type
  TBIZONYLATDISP = class(TForm)
    HAVIFEJTABLA: TIBTable;
    HAVIFEJQUERY: TIBQuery;
    HAVIFEJDBASE: TIBDatabase;
    HAVIFEJTRANZ: TIBTransaction;
    BLOKKFEJRACS: TDBGrid;
    BLOKKFEJSOURCE: TDataSource;
    TETELQUERY: TIBQuery;
    TETELDBASE: TIBDatabase;
    TETELTRANZ: TIBTransaction;
    HAVITETELQUERY: TIBQuery;
    HAVITETELDBASE: TIBDatabase;
    HAVITETELTRANZ: TIBTransaction;
    BLOKKTETELSOURCE: TDataSource;
    BLOKKTETELRACS: TDBGrid;
    NAPTAR: TCalendar;
    Panel10: TPanel;
    blokkfejpanel: TPanel;
    Panel4: TPanel;
    DATUMPANEL: TPanel;
    ELOHOGOMB: TPanel;
    KOVHOGOMB: TPanel;
    Panel2: TPanel;
    Panel43: TPanel;
    STORNOGOMB: TPanel;
    SUMBIZGOMB: TPanel;
    STORNOZOTTGOMB: TPanel;
    ATVETGOMB: TPanel;
    TCIM3PANEL: TPanel;
    TCIM2PANEL: TPanel;
    ATADGOMB: TPanel;
    TAP2PANEL: TPanel;
    TAP3PANEL: TPanel;
    BIZONYLATTIPUSPANEL: TPanel;
    STORNOPANEL: TPanel;
    TNEV4PANEL: TPanel;
    REPRINTGOMB: TPanel;
    FEJSOURCE: TDataSource;
    TETELSOURCE: TDataSource;
    FEJTABLA: TIBTable;
    FEJQUERY: TIBQuery;
    FEJDBASE: TIBDatabase;
    FEJTRANZ: TIBTransaction;
    PENZTARQUERY: TIBQuery;
    PENZTARDBASE: TIBDatabase;
    PENZTARTRANZ: TIBTransaction;
    SZUROPANEL: TPanel;
    Label3: TLabel;
    GroupBox1: TGroupBox;
    RR1: TRadioButton;
    RR2: TRadioButton;
    RR3: TRadioButton;
    RR4: TRadioButton;
    RR5: TRadioButton;
    RR6: TRadioButton;
    RR7: TRadioButton;
    RR8: TRadioButton;
    BitBtn1: TBitBtn;
    Shape19: TShape;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    COPYPANEL: TPanel;
    Label4: TLabel;
    INDOKEDIT: TEdit;
    Label5: TLabel;
    Shape20: TShape;
    LAKCIMCSIK: TBitBtn;
    Image1: TImage;
    Panel1: TPanel;
    Image2: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label6: TLabel;
    Shape1: TShape;
    PARTNERSZAMPANEL: TPanel;
    PARTNERNEVPANEL: TPanel;
    Label7: TLabel;
    Label8: TLabel;
    BIZTIPUSPANEL: TPanel;
    FEJQUERYFORINTERTEK: TIntegerField;
    FEJQUERYBIZONYLATSZAM: TIBStringField;
    FEJQUERYTIPUS: TIBStringField;
    FEJQUERYIDO: TIBStringField;
    FEJQUERYTETEL: TSmallintField;
    FEJQUERYTRBPENZTAR: TIBStringField;
    FEJQUERYTARSPENZTARKOD: TIBStringField;
    FEJQUERYSTORNO: TSmallintField;
    FEJQUERYSTORNOBIZONYLAT: TIBStringField;
    FEJQUERYDATUM: TIBStringField;
    HAVIFEJTABLABIZONYLATSZAM: TIBStringField;
    HAVIFEJTABLATIPUS: TIBStringField;
    HAVIFEJTABLADATUM: TIBStringField;
    HAVIFEJTABLAIDO: TIBStringField;
    HAVIFEJTABLAFORINTERTEK: TIntegerField;
    HAVIFEJTABLATETEL: TSmallintField;
    HAVIFEJTABLATRBPENZTAR: TIBStringField;
    HAVIFEJTABLATARSPENZTARKOD: TIBStringField;
    HAVIFEJTABLASTORNO: TSmallintField;
    HAVIFEJTABLASTORNOBIZONYLAT: TIBStringField;
    HAVITETELQUERYDATUM: TIBStringField;
    HAVITETELQUERYBIZONYLATSZAM: TIBStringField;
    HAVITETELQUERYVALUTANEM: TIBStringField;
    HAVITETELQUERYARFOLYAM: TIntegerField;
    HAVITETELQUERYBANKJEGY: TIntegerField;
    HAVITETELQUERYFORINTERTEK: TIntegerField;
    HAVITETELQUERYELOJEL: TIBStringField;
    HAVITETELQUERYTORTRESZ: TIBStringField;
    HAVITETELQUERYSTORNO: TSmallintField;
    HAVIFEJQUERYBIZONYLATSZAM: TIBStringField;
    HAVIFEJQUERYTIPUS: TIBStringField;
    HAVIFEJQUERYDATUM: TIBStringField;
    HAVIFEJQUERYIDO: TIBStringField;
    HAVIFEJQUERYFORINTERTEK: TIntegerField;
    HAVIFEJQUERYTETEL: TSmallintField;
    HAVIFEJQUERYTRBPENZTAR: TIBStringField;
    HAVIFEJQUERYTARSPENZTARKOD: TIBStringField;
    HAVIFEJQUERYSTORNO: TSmallintField;
    HAVIFEJQUERYSTORNOBIZONYLAT: TIBStringField;
    VISSZAGOMB: TBitBtn;
    PENZSZALLQUERY: TIBQuery;
    PENZSZALLDBASE: TIBDatabase;
    PENZSZALLTRANZ: TIBTransaction;

    procedure FormActivate(Sender: TObject);
    procedure VISSZAGOMBClick(Sender: TObject);
    procedure FejrekordValtozott;
    procedure StornoKijelzo;
  
    procedure MindentLezar;
  
    procedure MainapDisplay;
    function Setcondi(_css: byte): string;
    procedure Ujranyomtatas(Sender: TObject);
  
    procedure DatumKiertekeles(sender: TObject);
    function Nulele(_int: integer): string;
 
    procedure BlokktipusKijelzo;
 
    procedure NAPTARChange(Sender: TObject);
    procedure BLOKKFEJRACSKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);

    procedure BLOKKFEJRACSCellClick(Column: TColumn);
    procedure BLOKKFEJRACSDblClick(Sender: TObject);
    procedure PenztarBetoltes;
    procedure PenztarKijelzo(_pk: string);

    function Blokkfejnyitas: integer;
    function ScanPenztar(_ptk: string): string;
    procedure Button1Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
  
    procedure ValutaParancs(_ukaz: string);
    procedure VTempKitoltes;
    procedure INDOKEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure INDOKEDITExit(Sender: TObject);
    procedure GetReprintIndok;
  
    function HunDatetostr(_caldat: TDateTime): string;
    procedure ATVETGOMBClick(Sender: TObject);
    procedure KOVHOGOMBClick(Sender: TObject);
    procedure ELOHOGOMBClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  BIZONYLATDISP: TBIZONYLATDISP;
  _height,_width: word;
  _honev: array[1..12] of string = ('január','február','március','április','május',
                 'június','július','augusztus','szeptember','október',
                 'november','december');

  _conditext: array[1..5] of string = ('AZ ÖSSZES BIZONYLAT','ÁTVÉTELI BIZONYLATOK',
        'ÁTADÁSI BIZONYLATOK','STORNO BIZONYLATOK','STORNOZOTT BIZONYLATOK');



  _sorveg: string = chr(13)+chr(10);
  _kertev,_kertho,_kertnap,_maiev,_maiho,_mainap: word;
  _kertDatum : TDateTime;
  _bizonylat,_mamas,_datumstring,_kertdatumstring,_farok,_aktdnem: string;
  _fejnev,_tetelnev,_pcs,_tipus,_ugyfeltipus,_ptarkod,_condition,_elojel: string;
  _bizonylatszam,_ttipus,_datum,_aktidos,_szallitonev,_plombaszam: string;
  _aktprosid,_aktpenztarosnev,_megjegyzes,_aktpenztarnev: string;
  _aktpenztarszam,_copyindok,_prosnev: string;

  _varos,_utca,_irszam,_lakcim,_forras,_engedo: string;

  _mai: boolean;
  _aktFejQuery,_aktTetelQuery: TIbQuery;
  _aktFejdbase,_aktTetelDbase: TibDatabase;
  _recno,_ugyfelszam,_storno,_megbizott,_bankjegy,_ertek: integer;
  _penztardarab,_arfolyam,_forintertek,_netto,_tetel,_tranzdij: integer;
  _bill: integer;

  _penztarkod,_penztarnev: array[1..150] of string;
  _rcondi: array[1..8] of TRadioButton;
  _aktCondi: byte;
  _csaknap: boolean;
  _cimDatPath: string = 'c:\valuta\aktcim.dat';


function supervisorjelszo(_para:integer):integer;stdcall; external 'c:\ERTEKTAR\bin\super.dll' name 'supervisorjelszo';
function blokknyomtatas(_para: integer):integer; stdcall; external 'c:\ertektar\bin\bloknyom.dll' name 'blokknyomtatas';
function bizonylattallozo: integer; stdcall;


implementation

{$R *.dfm}

// =============================================================================
               function bizonylattallozo: integer; stdcall;
// =============================================================================

begin
  Bizonylatdisp := TBizonylatDisp.Create(Nil);
  result := Bizonylatdisp.Showmodal;
  BizonylatDisp.Free;
end;


// =============================================================================
           procedure TBIZONYLATDISP.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  top     := trunc((_height-768)/2);
  Left    := trunc((_width-1024)/2);
  Height  := 768;
  Width   := 1024;

  _maiev  := yearof(date);
  _maiho  := monthof(date);
  _mainap := dayof(date);
  _mamas  := Hundatetostr(Date);

  Naptar.CalendarDate := date;
  PenztarBetoltes;

  Naptarchange(Nil);

  BizonylatTipusPanel.Caption := '';
  stornoPanel.caption := '';

  _condition := '';
  _aktcondi := 1;

  DatumKiertekeles(Nil);
end;

// =============================================================================
         procedure TBizonylatdisp.DatumKiertekeles(sender: TObject);
// =============================================================================

begin
  MindentLezar;

  _kertev := Naptar.Year;
  _kertho := Naptar.Month;
  _kertnap:= Naptar.day;
  _kertDatum := Naptar.CalendarDate;
  _kertdatumstring := Hundatetostr(_kertdatum);

  if _kertDatum>date then
    begin
      Showmessage('A KÉRT NAP MÉG A JÖVÕBEN VAN');
      exit;
    end;

  _mai := False;
  if _kertDatum=date then
   begin
      Mainapdisplay;
      exit;
    end;

  _farok    := inttostr(_kertev-2000)+nulele(_kertho);
  _fejnev   := 'BF' + _farok;
  _tetelnev := 'BT' + _farok;

  BlokkfejRacs.DataSource := BlokkfejSource;
  BlokkTetelRacs.DataSource := BlokktetelSource;

  HavifejTabla.close;
  HavifejDbase.connected := true;

  HavifejTabla.TableName := _fejnev;
  if not Havifejtabla.Exists then
    begin
      HavifejDbase.close;
      ShowMessage('Nincs adat a kért hónapról');
      exit;
    end;

  _aktfejQuery := haviFejQuery;
  _aktfejDbase := haviFejDbase;

  _aktTetelQuery := HavitetelQuery;
  _aktTetelDbase := HaviTetelDbase;

  _condition := Setcondi(_aktcondi);

  _pcs := 'SELECT * FROM ' + _fejnev;
  _pcs := _pcs + _sorveg +'WHERE (DATUM=' + chr(39) + _kertdatumstring + chr(39) + ')';
  if _conditIon<>'' then _pcs := _pcs + ' AND ('+ _condition + ')'+ _sorveg
  else _Pcs := _pcs + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM,IDO';

  _aktfejdbase.Connected := True;
  with _aktFejQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      _aktFejquery.close;
      _aktFejdbase.close;
      ShowMessage('A kért napról nincsenek adataim az adott feltételek mellett!');
      exit;
    end;

  FejrekordValtozott;

  ActiveControl := BlokkFejracs;
  Blokkfejracs.SetFocus;
end;


function TBizonylatDisp.Setcondi(_css: byte): string;

begin
  result := '';
  case _css of
    1: result := '';
    2: result := 'TIPUS='+chr(39)+'U'+chr(39);
    3: result := 'TIPUS='+chr(39)+'F'+chr(39);
    4: result := 'STORNO=2';
    5: result := 'STORNO=3';
  end;
end;




// =============================================================================
                   procedure TBizonylatDisp.FejrekordValtozott;
// =============================================================================

begin

  _bizonylat   := _aktFejquery.Fieldbyname('BIZONYLATSZAM').asstring;
  _tipus       := _aktfejQuery.FieldByNAme('TIPUS').asString;
  _storno      := _aktfejQuery.fieldByName('STORNO').asInteger;
  _ptarkod     := trim(_aktfejquery.FieldByName('TARSPENZTARKOD').ASsTRING);

  BlokktipusKijelzo;
  StornoKijelzo;

  PenztarKijelzo(_ptarkod);

  _pcs := 'SELECT * FROM ' + _tetelnev + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39)+_bizonylat + chr(39);

  _akttetelDbase.Connected := true;
  with _aktTetelQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;
end;



// =============================================================================
            procedure TBizonylatDisp.PenztarKijelzo(_pk: string);
// =============================================================================

var _pknev: string;

begin
  
  _pknev := ScanPenztar(_pk);
  Partnerszampanel.caption := _pk;
  PartnernevPanel.caption := _pknev;

end;

// =============================================================================
           procedure TBIZONYLATDISP.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  MindentLezar;
  Modalresult := 1;
end;


// =============================================================================
            function TBizonylatdisp.Nulele(_int: integer): string;
// =============================================================================

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;


// =============================================================================
            procedure TBIZONYLATDISP.NAPTARChange(Sender: TObject);
// =============================================================================

var _nev,_nho,_nnap: word;

begin
 
  _nev := Naptar.Year;
  _nHo := Naptar.Month;
  _nnap:= Naptar.Day;

  _datumstring := inttostr(_nev)+' '+_honev[_nho] + ' '+inttostr(_nnap);
  DatumPanel.Caption := _datumstring;
  Datumpanel.Repaint;
end;


// =============================================================================
            procedure TBizonylatDisp.BlokktipusKijelzo;
// =============================================================================

var _tips: string;

begin
 
  if _tipus='F' then
    begin
      if leftstr(_bizonylat,2)='FF' then _tips := 'Forint átadási bizonylat'
      else _tips := 'Valuta átadási bizonylat';
    end;

  if _tipus='U' then
    begin
      if leftstr(_bizonylat,2)='UF' then _tips := 'Forint átvétel bizonylat'
      else _tips := 'Valuta átvételi bizonylat';
    end;

  BizonylatTipusPanel.caption := _tips;
  BizonylatTipusPanel.repaint;
  
end;


// =============================================================================
procedure TBizonylatDisp.StornoKijelzo;
// =============================================================================

begin
  if _storno=1 then StornoPanel.caption := '';
  if _storno=2 then  StornoPanel.caption := 'Stornózott bizonylat !';
  if _storno=3 then  StornoPanel.caption := 'Stornó bizonylat !';
  if _storno=4 then StornoPanel.caption := 'Rontott bizonylat !';
  StornoPanel.repaint;
end;


// =============================================================================
procedure TBIZONYLATDISP.BLOKKFEJRACSKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
// =============================================================================

var _bill: integer;

begin
  _bill:= ord(key);
  if (_bill>32) AND (_bill<41) then
    begin
      Fejrekordvaltozott;
      exit;
    end;
end;




// =============================================================================
       procedure TBIZONYLATDISP.BLOKKFEJRACSCellClick(Column: TColumn);
// =============================================================================

begin
  FejRekordValtozott;
end;

// =============================================================================
         procedure TBIZONYLATDISP.BLOKKFEJRACSDblClick(Sender: TObject);
// =============================================================================

begin
  FejrekordValtozott;
end;

// =============================================================================
                   procedure TBizonylatDisp.MindentLezar;
// =============================================================================

begin
  if Fejquery.Active then Fejquery.close;
  if fejdbase.Connected then fejdbase.close;

  if TetelQuery.Active then TetelQuery.close;
  if TetelDbase.connected then TetelDbase.close;

  if HaviFejQuery.Active then HavifejQuery.close;
  if HaviFejDbase.connected then Havifejdbase.close;

  if HaviTetelQuery.Active then HaviTetelQuery.close;
  if Haviteteldbase.connected then HavitetelDbase.close;


end;


// =============================================================================
                 procedure TBizonylatDisp.MainapDisplay;
// =============================================================================

begin


  _aktfejQuery := FejQuery;
  _aktfejDbase := FejDbase;

  _aktTetelQuery := TetelQuery;
  _aktTetelDbase := TetelDbase;

  _tetelnev := 'BLOKKTETEL';
  _recno := Blokkfejnyitas;

  if _recno=0 then
    begin
      Fejquery.close;
      Fejdbase.close;
      ShowMessage('A kért napról nincsenek adataim !');
      exit;
    end;

  _mai := True;
  BlokkfejRacs.DataSource   := FejSource;
  BlokkTetelRacs.DataSource := TetelSource;

  FejrekordValtozott;

  ActiveControl := BlokkFejracs;
  Blokkfejracs.SetFocus;
end;



function TBizonylatDisp.BlokkfejNyitas: integer;

begin
  
  _condition := Setcondi(_aktcondi);

  _pcs := 'SELECT * FROM BLOKKFEJ' + _sorveg;

  if _condition<>'' then  _pcs := _pcs + 'WHERE '+_condition + _sorveg;
  _pcs := _pcs + 'ORDER BY IDO';

  fEJdbase.connected := true;
  with fEJQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      result := recno;
    end;
end;

procedure TBizonylatdisp.PenztarBetoltes;

var _ptkod,_ptnev: string;

begin
  Penztardbase.Connected := true;
  with PenztarQuery do
    begin
      close;
      sql.clear;
      sql.Add('SELECT * FROM PENZTAR');
      Open;
      First;
    end;

  _penztardarab := 0;
  while not PenztarQuery.eof do
    begin
      _ptkod := trim(PenztarQuery.FieldByName('PENZTARKOD').asString);
      _ptnev := trim(PenztarQuery.FieldByName('PENZTARNEV').asString);
      inc(_penztardarab);

      _penztarkod[_penztardarab] := _ptkod;
      _penztarnev[_penztardarab] := _ptnev;

      PenztarQuery.next;
    end;
  PenztarQuery.close;
  Penztardbase.close;
end;

function TBizonylatdisp.ScanPenztar(_ptk: string): string;

var _y: byte;

begin
  result := '';
  _y := 1;
  while _y<=_penztardarab do
    begin
      if _penztarkod[_y]=_ptk then
        begin
          result := _penztarnev[_y];
          exit;
        end;
      inc(_y);
    end;
end;



procedure TBIZONYLATDISP.Button1Click(Sender: TObject);
begin
  with szuropanel do
    begin
      Left := 48;
      Top  := 128;
      Visible := true;
    end;
end;


procedure TBIZONYLATDISP.BitBtn1Click(Sender: TObject);

var i: integer;

begin
  _aktcondi := 0;
  for i := 1 to 8 do
    begin
      if _rcondi[i].Checked then
        begin
          _aktcondi := i;
          break;
        end;
    end;
  szuropanel.Visible := false;
  if _aktcondi=1 then Blokkfejpanel.caption := 'Blokkfejek'
  else BlokkfejPanel.caption := 'Blokkfejek (szûrve)';
  BlokkfejPanel.Repaint;
  DatumKiertekeles(Nil);
end;


procedure TBizonylatDisp.Ujranyomtatas(Sender: TObject);

var _spk: integer;

begin
  _spk := supervisorjelszo(0);
  if _spk<>1 then exit;
  GetReprintIndok;
end;

// =============================================================================
                 procedure TBizonylatdisp.GetReprintIndok;
// =============================================================================


begin
  Indokedit.clear;
  with CopyPanel do
    begin
      Top := 200;
      Left := 80;
      Visible := True;
    end;
  Activecontrol := indokedit;
end;




// =============================================================================
                      procedure TBizonylatdisp.VtempKitoltes;
// =============================================================================


begin


  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _aktTetelQuery.first;
  while not _aktTetelQuery.Eof do
    begin
      with _aktTetelQuery do
        begin
          _aktdnem   := FieldByName('VALUTANEM').asstring;
          _bankjegy  := FieldByName('BANKJEGY').asInteger;
          _ertek     := FieldByName('FORINTERTEK').asInteger;
          _elojel    := FieldByName('ELOJEL').asstring;
          _arfolyam  := FieldByName('ARFOLYAM').asInteger;
        end;

      _pcs := 'INSERT INTO VTEMP (VALUTANEM,ARFOLYAM,';
      _pcs := _pcs + 'BANKJEGY,FORINTERTEK,ELOJEL)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + inttostr(_arfolyam) + ',';
      _pcs := _pcs + inttostr(_bankjegy) + ',';
      _pcs := _pcs + inttostr(_ertek) + ',';
      _pcs := _pcs + chr(39) + _elojel + chr(39)+')';
      ValutaParancs(_pcs);

      _akttetelQuery.next;
    end;

  _akttetelquery.first;

  // ---------------------------------------------------------------------------

  with _aktFejquery do
    begin
      _bizonylatszam  := FieldByName('BIZONYLATSZAM').asstring;
      _ttipus         := FieldByName('TIPUS').asstring;
      _datum          := FieldByName('DATUM').asstring;
      _aktidos        := FieldByName('IDO').asstring;
      _forintertek    := FieldByName('FORINTERTEK').asInteger;

      _tetel          := FieldByName('TETEL').asInteger;
      _aktpenztarszam := FieldByName('TARSPENZTARKOD').asstring;

      _storno         := FieldByName('STORNO').asInteger;

    end;

  _pcs := 'SELECT * FROM WPENZSZALLITAS' + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_bizonylatszam+chr(39);

  _plombaszam := '';
  _szallitonev := '';
  _megjegyzes := '';

  Penzszalldbase.connected := true;
  with PenzszallQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;
  if _recno>0 then
    begin
      _plombaszam := trim(PenzszallQuery.Fieldbyname('PLOMBASZAM').asString);
      _szallitonev := trim(PenzSzallQuery.Fieldbyname('SZALLITONEV').asString);
      _megjegyzes := trim(PenzszallQuery.Fieldbyname('MEGJEGYZES').ASsTRING);
    end;
  PenzSzallQuery.close;
  PenzSzalldbase.close;

  _pcs := 'UPDATE VTEMP SET BIZONYLATSZAM=' + chr(39) + _bizonylatszam + chr(39);
  _pcs := _pcs + ',DATUM=' + chr(39) + _datum + chr(39);
  _pcs := _pcs + ',TIPUS=' + chr(39) + _ttipus + chr(39);
  _pcs := _pcs + ',OSSZESFORINTERTEK=' + inttostr(_forintertek);
  _pcs := _pcs + ',IDO=' + chr(39) + leftstr(_aktidos,5) + chr(39);
  _pcs := _pcs + ',TETEL=' + inttostr(_tetel);
  _pcs := _pcs + ',STORNO=' + inttostr(_storno);

  if _copyindok<>'' then _pcs := _pcs +',COPYINDOK='+chr(39)+leftstr(_copyindok,10)+chr(39);
  
  _pcs := _pcs + ',PENZTARKOD='+CHR(39) +_aktPenztarszam+chr(39);
  _pcs := _pcs + ',SZALLITONEV='+chr(39) + _szallitonev+chr(39);
  _pcs := _pcs + ',PLOMBASZAM='+chr(39) + _plombaszam+chr(39);
  _PCS := _pcs + ',TARSPENZTARNEV=' + chr(39) + _aktpenztarnev + chr(39);
  _pcs := _pcs + ',MEGJEGYZES='+chr(39)+_MEGJEGYZES+CHR(39);

  ValutaParancs(_pcs);


end;

procedure TBizonylatdisp.ValutaParancs(_ukaz: string);

begin
  Valutadbase.connected := true;
  if Valutatranz.InTransaction then Valutatranz.Commit;
  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      CLose;
      Sql.clear;
      sql.Add(_pcs);
      Execsql;
    end;
  ValutaTranz.commit;
  Valutadbase.close;
end;


procedure TBIZONYLATDISP.INDOKEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);

var 
    _pp : byte;

begin
  _bill := ord(key);
  if (_bill<>13) then exit;
  _copyindok := trim(Indokedit.Text);
  if _copyIndok='' then
    begin
      Activecontrol := Blokkfejracs;
      exit;
    end;
  Vtempkitoltes;

  _pp := 2;
  if _copyindok='@' then _pp := 1;

  blokknyomtatas(_pp);

  Activecontrol := Blokkfejracs;
end;

procedure TBIZONYLATDISP.INDOKEDITExit(Sender: TObject);
begin
  CopyPanel.Visible := false;
end;




function TBizonylatdisp.HunDatetostr(_caldat: TDateTime): string;
var _h_ev,_h_ho,_h_nap: word;
begin
  _h_ev := yearof(_caldat);
  _h_ho := monthof(_caldat);
  _h_nap:= dayof(_caldat);

  result := inttostr(_h_ev)+'.'+nulele(_h_ho)+'.'+nulele(_h_nap);
end;


procedure TBIZONYLATDISP.ATVETGOMBClick(Sender: TObject);
begin
  _aktcondi := TPanel(sender).tag;
  _condition := Setcondi(_aktcondi);
  BiztipusPanel.Caption := _conditext[_aktcondi];
  BiztipusPanel.repaint;

  DatumKiertekeles(Nil);
end;

procedure TBIZONYLATDISP.KOVHOGOMBClick(Sender: TObject);
begin
  nAPTAR.NextMonth;
end;

procedure TBIZONYLATDISP.ELOHOGOMBClick(Sender: TObject);
begin
  nAPTAR.PrevMonth;
end;

end.
