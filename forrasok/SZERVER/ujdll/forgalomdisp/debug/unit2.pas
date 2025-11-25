unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, DBGrids, ExtCtrls, StdCtrls, DB, IBDatabase,strutils,
  IBCustomDataSet, IBTable, Buttons, IBQuery;

type
  TFORGDISPLAY = class(TForm)
    Label1         : TLabel;
    IrodaPanel     : TPanel;
    Panel2         : TPanel;
    Panel3         : TPanel;
    Panel4         : TPanel;
    Panel5         : TPanel;
    Panel6         : TPanel;
    Panel7         : TPanel;
    Panel8         : TPanel;
    Panel9         : TPanel;
    FORGALOMRACS   : TDBGrid;
    IDOSZAKPANEL   : TPanel;

    Label2         : TLabel;
    Label3         : TLabel;
    Label4         : TLabel;
    Label5         : TLabel;
    Label6         : TLabel;
    Label7         : TLabel;
    MasEgysegGomb  : TBitBtn;
    Panel11        : TPanel;
    KilepoGomb     : TBitBtn;
    ReceptorDbase  : TIBDatabase;
    ReceptorTranz  : TIBTransaction;
    ForgalomSource : TDataSource;
    SVettFtPanel   : TPanel;
    SEladottFtPanel: TPanel;
    Shape1         : TShape;
    Label8         : TLabel;
    Label9         : TLabel;
    Shape2         : TShape;
    ReceptorQuery  : TIBQuery;
    Kilepo         : TTimer;

    ReceptorQueryIrodaszam          : TIntegerField;
    ReceptorQueryErtektar           : TIntegerField;
    ReceptorQueryValutanem          : TIBStringField;
    ReceptorQueryElszamolasiArfolyam: TFloatField;
    ReceptorQueryVett               : TFloatField;
    ReceptorQueryEladott            : TFloatField;
    ReceptorQueryVettertek          : TFloatField;
    ReceptorQueryEladottertek       : TFloatField;
    ReceptorQueryCegbetu            : TIBStringField;

    ParaQuery    : TIBQuery;
    ParaDbase    : TIBDatabase;
    ParaTranz    : TIBTransaction;

    MasAdatGomb  : TBitBtn;
    MasDatumGomb : TBitBtn;
    ZALOGPLUSBOX: TCheckBox;

    procedure FormActivate(Sender: TObject);
    procedure KilepoGombClick(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure MasAdatGombClick(Sender: TObject);
    procedure MasEgysegGombClick(Sender: TObject);
    procedure MasDatumGombClick(Sender: TObject);
    procedure TablaDisplay;
    procedure ZalogPlusBoxClick(Sender: TObject);

    function ScanBetu(_b: string): byte;
    function Scankorzet(_k: integer): byte;
   
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FORGDISPLAY: TFORGDISPLAY;

  _irodanev: array[1..180] of string;
  _korzetszam: array[1..9] of byte = (10,20,40,50,63,75,120,145,180);
  _korzetnev: array[1..9] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
           'DEBRECEN','NYIREGYHÁZ','BÉKÉSCSABA','PÉCS','KAPOSVÁR','ZÁLOG');

  _honev: array[1..12] of string = ('január','február','március','április',
                 'május','junius','július','augusztus','szeptember',
                          'október','november','december');

  _betusor: array[1..4] of string = ('B','P','E','Z');

  _cegnevsor: array[1..4] of string =('BEST CHANGE','PANNON CHANGE','EAST CHANGE',
                                           'EXPRESSZ ZÁLOG');

  _aktho,_tolnap,_ignap: word;

  _egysegtipus,_aktkorzet,_aktpenztar,_korzss,_y,_bss: byte;
  _vettft,_eladottft,_svett,_seladott,_sVettFt,_sEladottFt,_ve,_ee: real;
  _mResult,_code: integer;
  _aktegyseg: string;
  _szuro,_filter,_pcs,_aktcegbetu,_tolstring,_igstring,_idsz: string;
  _sorveg: string = chr(13)+chr(10);
  _evs,_hos,_tolnaps,_ignaps,_cegnev: string;

function getegysegkod: integer; stdcall; external 'c:\receptor\getegyseg.dll' name 'getegysegkod';
function forgalomdisplayrutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
              function forgalomdisplayrutin: integer; stdcall;
// =============================================================================

begin
  forgdisplay := TForgdisplay.Create(Nil);
  result := Forgdisplay.ShowModal;
  forgdisplay.free;
end;

// =============================================================================
          procedure TFORGDISPLAY.FormActivate(Sender: TObject);
// =============================================================================


begin
  Top  := 230;
  Left := 208;
  ZalogPlusBox.Visible := False;

  _pcs := 'SELECT * FROM ADATATADO';

  ParaDbase.Connected := True;
  with ParaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;

      _filter      := trim(FieldByNAme('SZURO').AsString);
      _egysegtipus := FieldByNAme('TIPUS').asInteger;
      _aktcegbetu  := FieldByName('CEGBETU').asString;
      _aktkorzet   := FieldByName('KORZET').asInteger;
      _aktpenztar  := FieldByName('IRODA').asInteger;
      Close;

      Sql.clear;
      sql.add('SELECT * FROM IDOSZAK');
      Open;

      _tolstring := FieldByName('STARTDATE').asString;
      _igstring := FieldByName('ENDDATE').asString;
      Close;
    end;
  Paradbase.close;

  _korzss := scankorzet(_aktkorzet);


  if _egysegtipus=3 then _filter:=_filter+chr(39)+_aktcegbetu+chr(39)+')';

  _evs     := leftstr(_tolstring,4);
  _hos     := midstr(_tolstring,6,2);
  _tolnaps := midstr(_tolstring,9,2);
  _ignaps  := midstr(_igstring,9,2);

  val(_hos,_aktho,_code);
  val(_tolnaps,_tolnap,_code);
  val(_ignaps,_ignap,_code);

  _idsz := _evs + ' '+_honev[_aktho] + ' ' + inttostr(_tolnap)+' - '+inttostr(_ignap);
  IdoszakPanel.Caption := _idsz;
  IdoszakPanel.repaint;

  _bss    := ScanBetu(_AKTCEGBETU);
  _cegnev := '';

  if _bss>0 then _cegnev := _cegnevsor[_bss]+' KFT';

  case _egysegtipus of
    1: _aktegyseg := inttostr(_aktpenztar)+'. PÉNZTÁR ADATAI';
    2: _aktegyseg := _korzetnev[_korzss]+'I KÖRZET ADATAI';
    3: _aktegyseg := _cegnev +' ADATAI';
    4: _aktegyseg := 'PÉNZTÁRAK ÖSSZESITETT ADATAI';
  end;

  if _egysegtipus=4 then ZalogplusBox.Visible := true;

  IrodaPanel.Caption := _aktegyseg;
  Irodapanel.repaint;
  Tabladisplay;
end;


procedure TForgDisplay.Tabladisplay;

begin

  _pcs := 'SELECT * FROM FORGALOMGYUJTO' + _sorveg;
  _pcs := _pcs + 'WHERE ' + _FILTER + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  Forgalomsource.Enabled := False;

  ReceptorDbase.Connected := true;
  with ReceptorQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  _svettft := 0;
  _sEladottFt := 0;
  while not ReceptorQuery.eof do
    begin
      _ve := ReceptorQuery.FieldByName('VETTERTEK').asFloat;
      _ee := ReceptorQuery.FieldByName('ELADOTTERTEK').asFloat;
      _svettft := _svettft + _ve;
      _seladottft := _seladottft + _ee;
      ReceptorQuery.next;
    end;
  receptorQuery.first;
  SvettFtPanel.Caption := 'VETT: '+formatfloat('### ### ###',_svettft)+' Ft';
  SeladottFtPanel.caption := 'ELADOTT: '+ formatfloat('### ### ###',_seladottFt)+' Ft';
  ReceptorQuery.first;
  ForgalomSource.Enabled := true;

end;

// =============================================================================
           procedure TFORGDISPLAY.KILEPOGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := -1;
  Kilepo.Enabled := True;
end;

// =============================================================================
              function TForgDisplay.ScanBetu(_b: string): byte;
// =============================================================================

var _y: byte;

begin
  result := 0;
  _y :=1;
  while _y<=4 do
    begin
      if _betusor[_y]=_b THEN
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;


// =============================================================================
             procedure TFORGDISPLAY.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.enabled := False;
  ReceptorQuery.close;
  Receptordbase.close;
  Modalresult := _mResult;
end;

// =============================================================================
           procedure TForgDisplay.MasAdatGombClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 1;
  Kilepo.Enabled := true;
end;

// =============================================================================
          procedure TForgDisplay.MasEgysegGombClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 2;
  Kilepo.Enabled := true;
end;

// =============================================================================
          procedure TForgDisplay.MasDatumGombClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 3;
  Kilepo.Enabled := true;
end;


// =============================================================================
              function TForgdisplay.Scankorzet(_k: integer): byte;
// =============================================================================

begin
  result :=0;
  _y := 1;
  while _y<=9 do
    begin
      if _korzetszam[_y]= _k then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;


procedure TFORGDISPLAY.ZalogPlusBoxClick(Sender: TObject);

var _csekk: integer;

begin
  _csekk:= -1;
  if ZalogPlusBox.Checked then _csekk := -2;
  _filter := '(ERTEKTAR='+inttostr(_csekk)+')';
  Tabladisplay;
end;

end.
