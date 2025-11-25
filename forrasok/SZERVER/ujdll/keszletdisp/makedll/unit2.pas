unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, DB, IBDatabase, IBCustomDataSet, IBTable,
  Grids, DBGrids, Buttons, strUtils, IBQuery;

type
  TKESZLETDISPLAY = class(TForm)

    IrodaPanel   : TPanel;
    IdoszakPanel : TPanel;
    ValutaPanel  : TPanel;
    ForintPanel  : TPanel;
    OsszesPanel  : TPanel;

    KeszletRacs  : TDBGrid;
    KeszletDBase : TIBDatabase;
    Keszlettranz : TIBTransaction;
    KeszletQuery : TIBQuery;
    KeszletSource: TDataSource;

    KilepoGomb   : TBitBtn;
    MasAdatGomb  : TBitBtn;
    MasEgysegGomb: TBitBtn;
    MasDatumGomb : TBitBtn;

    Shape1       : TShape;
    Shape2       : TShape;
    Shape3       : TShape;
    Shape4       : TShape;
    Shape5       : TShape;
    Shape6       : TShape;

    Label1       : TLabel;
    Label2       : TLabel;
    Label3       : TLabel;
    Label4       : TLabel;
    Label5       : TLabel;
    Label6       : TLabel;

    ParaQuery    : TIBQuery;
    ParaDbase    : TIBDatabase;
    ParaTranz    : TIBTransaction;

    Kilepo       : TTimer;

    KeszletQueryIrodaszam          : TIntegerField;
    KeszletQueryErtektar           : TIntegerField;
    KeszletQueryValutanem          : TIBStringField;
    KeszletQueryElszamolasiArfolyam: TFloatField;
    KeszletQueryKeszlet            : TFloatField;
    KeszletQueryForintertek        : TFloatField;
    KeszletQueryCimlet1            : TIntegerField;
    KeszletQueryCimlet2            : TIntegerField;
    KeszletQueryCimlet3            : TIntegerField;
    KeszletQueryCimlet4            : TIntegerField;
    KeszletQueryCimlet5            : TIntegerField;
    KeszletQueryCimlet6            : TIntegerField;
    KeszletQueryCimlet7            : TIntegerField;
    KeszletQueryCimlet8            : TIntegerField;
    KeszletQueryCimlet9            : TIntegerField;
    KeszletQueryCimlet10           : TIntegerField;
    KeszletQueryCimlet11           : TIntegerField;
    KeszletQueryCimlet12           : TIntegerField;
    KeszletQueryCimlet13           : TIntegerField;
    KeszletQueryCimlet14           : TIntegerField;
    KeszletQueryCegbetu            : TIBStringField;
    ZALOGPLUSBOX: TCheckBox;

    procedure FormActivate(Sender: TObject);
    procedure KilepoGombClick(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure Kozepreir(_mm: string);
    procedure MasAdatGombClick(Sender: TObject);
    procedure MasEGYSEGGombClick(Sender: TObject);
    procedure MasDATUMGombClick(Sender: TObject);
    procedure ParameterBeolvasas;
    procedure PostabaTesz(sender: TObject);
    procedure PostaGombEnter(Sender: TObject);
    procedure PostaGombExit(Sender: TObject);
    procedure PostaGombMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure TablaDisplay;
    procedure VonalHuzo;

    function ArfFormat(_rr:real): string;
    function FFormat(_rr:real): string;
    function ScanBetu(_b: string): byte;
    function ScanKorzet(_k: integer): byte;
    procedure ZALOGPLUSBOXClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  KESZLETDISPLAY: TKESZLETDISPLAY;

  _korzetszam: array[1..9] of byte = (10,20,40,50,63,75,120,145,180);
  _korzetnev: array[1..9] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
           'DEBRECEN','NYIREGYHÁZ','BÉKÉSCSABA','PÉCS','KAPOSVÁR','ZÁLOG');

  _honev: array[1..12] of string = ('január','február','március','április',
                 'május','junius','július','augusztus','szeptember',
                          'október','november','december');

  _betusor: array[1..4] of string = ('B','P','E','Z');

  _cegnevsor: array[1..4] of string =('BEST CHANGE','PANNON CHANGE','EAST CHANGE',
                                           'EXPRESSZ ZÁLOG');

  _idoszakstring,_pcs,_filter,_valutanem,_aktcegbetu,_tolstring,_igstring: string;
  _evs,_hos,_tolnaps,_ignaps,_idsz,_cegnev,_aktegyseg: string;
  _sorveg: string = chr(13)+chr(10);
  _displaytipus,_keszlet,_elszarfolyam,_ertek,_egysegtipus,_aktkorzet: integer;
  _aktpenztar,_code,_mResult: integer;
  _aktho,_tolnap,_ignap: word;
  _bss,_korzss,_y: byte;
  _sumertek,_valertek,_hufertek,_aktarfolyam,_sForint,_ftertek: real;
  _iras: Textfile;

// =============================================================================
             function keszletdisplayrutin: integer; stdcall;
// =============================================================================

implementation

{$R *.dfm}


// =============================================================================
              function keszletdisplayrutin: integer; stdcall;
// =============================================================================

begin
  keszletdisplay := TKeszletdisplay.Create(Nil);
  result := Keszletdisplay.showmodal;
  Keszletdisplay.free;
end;


// =============================================================================
          procedure TKESZLETDISPLAY.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top := 230;
  Left := 208;

  ZalogPlusBox.Visible := False;

  parameterbeolvasas;

//  PostaGomb.Visible := True;
  KeszletSource.Enabled := false;
  TablaDisplay;
end;  


procedure TKeszletdisplay.TablaDisplay;

begin
  _pcs := 'SELECT * FROM CIMLETGYUJTO' + _sorveg;
  _pcs := _pcs + 'WHERE ' + _FILTER + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  KeszletDbase.Close;
  KeszletDbase.Connected := True;
  with KeszletQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _hufertek := 0;
  _valertek := 0;
  _sumertek := 0;
  while not KeszletQuery.Eof do
    begin
      with KeszletQuery do
        begin
          _elszarfolyam := FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
          _keszlet := FieldByName('KESZLET').asInteger;
          _valutanem := FieldByName('VALUTANEM').asstring;
          _ftertek := FieldByName('FORINTERTEK').asInteger;
        end;
      if _valutanem='HUF' then _hufertek :=  _keszlet
      else _valertek := _valertek + _ftErtek;             //(_elszarfolyam*_keszlet/100);
      KeszLetQuery.Next;
    end;

  _sumErtek := _valertek+_hufertek;

  Valutapanel.Caption := FormatFloat('###,###,###',_valertek)+' Ft';
  ForintPanel.Caption := FormatFloat('###,###,###',_hufertek)+' Ft';
  OsszesPanel.Caption := FormatFloat('###,###,###',_sumertek)+' Ft';

  KeszletQuery.First;
  KeszletSource.Enabled := true;
end;

// =============================================================================
            procedure TKeszletDisplay.PostabaTesz(sender: Tobject);
// =============================================================================

var _listaPath: string;


begin
//   PostaGomb.visible := False;
   _listaPath := 'c:\receptor\mail\posta\Keszlet.txt';
   if fileExists(_listaPath) then DeleteFile(_ListaPath);

   _sforint := 0;

   AssignFile(_iras,_listaPath);
   Rewrite(_iras);
   writeln(_iras,chr(13)+chr(10));
   writeln(_iras,chr(13)+chr(10));
   writeln(_iras,chr(13)+chr(10));

   writeLn(_iras,'                    NAPI VALUTAKESZLET KIMUTATASA');

//   WriteLn(_iras,'        '+_displayfocim+'              '+_idoszaklabel);
   VonalHuzo;

   WriteLn(_iras,'      VALUTA        MENNYISEG         ARFOLYAM        FORINTERTEK');
   VonalHuzo;
   KeszletQuery.First;
   while not keszletQuery.eof do
     begin
       _valutanem := KeszletQuery.FieldByName('VALUTANEM').asString;
       _keszlet := KeszletQuery.FieldByNAme('KESZLET').asInteger;
       _aktarfolyam := KeszletQuery.FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
       _ertek := KeszletQuery.FieldByName('FORINTERTEK').asInteger;
       _sforint := _sforint + _ertek;

       write(_iras,'       '+_valutanem);
       write(_iras,'         ');
       write(_iras,fformat(_keszlet));
       write(_iras,'         ');
       write(_iras,arfformat(_aktarfolyam)+'       ');
       writeLn(_iras,fformat(_ertek));
       KeszletQuery.Next;
     end;
   Vonalhuzo;
   writeln(_iras,'                     Osszes forintertek: '+ fformat(_sforint)+' Ft');
   closefile(_iras);
   KeszletQuery.First;
   ShowMessage('A KÉSZLETET KITETTEM A POSTÁBA >> KESZLET.TXT << NÉVEN');
end;

// =============================================================================
                 procedure TKeszletDisplay.VonalHuzo;
// =============================================================================

begin
  writeLn(_iras,'     '+dupestring('-',63));
end;

// =============================================================================
           procedure TKeszletDisplay.Kozepreir(_mm: string);
// =============================================================================

var _len,_marad: integer;

begin
  _len := length(_mm);
  _marad := trunc((80-_len)/2);
  writeLn(_iras,dupestring(chr(32),_marad)+_mm);
end;

// =============================================================================
          function TKeszletDisplay.FFormat(_rr:real): string;
// =============================================================================

begin
  result := formatfloat('### ### ###',_rr);
  while length(result)<11 do Result := ' '+Result;
end;

// =============================================================================
          function TKeszletDisplay.arFFormat(_rr:real): string;
// =============================================================================

begin
  result := formatfloat('## ###.00',_rr);
  while length(result)<9 do result := ' '+result;
end;



// =============================================================================
         procedure TKESZLETDISPLAY.POSTAGOMBEnter(Sender: TObject);
// =============================================================================

begin
  TBitbtn(sender).Font.Color := clBlack;
end;

// =============================================================================
           procedure TKESZLETDISPLAY.POSTAGOMBExit(Sender: TObject);
// =============================================================================

begin
  TBitbtn(sender).Font.Color := clGray;
end;

// =============================================================================
       procedure TKESZLETDISPLAY.POSTAGOMBMouseMove(Sender: TObject;
                                          Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  ActiveControl := TBitbtn(sender);
end;


// =============================================================================
                procedure TKeszletDisplay.ParameterBeolvasas;
// =============================================================================

begin
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

  _korzss := Scankorzet(_aktkorzet);

  case _egysegtipus of
    1: _aktegyseg := inttostr(_aktpenztar)+'. PÉNZTÁR ADATAI';
    2: _aktegyseg := _korzetnev[_korzss]+'I KÖRZET ADATAI';
    3: _aktegyseg := _cegnev +' ADATAI';
    4: _aktegyseg := 'PÉNZTÁRAK ÖSSZESITETT ADATAI';
  end;
  ZalogPlusBox.Visible := true;
  if _egysegtipus=4 then ZalogPlusBox.Visible := True;
  IrodaPanel.Caption := _aktegyseg;
  Irodapanel.repaint;
end;

// =============================================================================
              function TKeszletDisplay.ScanBetu(_b: string): byte;
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
           procedure TKESZLETDISPLAY.MASADATGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 1;
  Kilepo.enabled := True;
end;

// =============================================================================
           procedure TKESZLETDISPLAY.MASEGYSEGGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 2;
  Kilepo.enabled := True;
end;

// =============================================================================
          procedure TKESZLETDISPLAY.MASDATUMGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 3;
  Kilepo.enabled := True;
end;

// =============================================================================
          procedure TKESZLETDISPLAY.kilepogombClick(Sender: TObject);
// =============================================================================

begin
  _mResult := -1;
  Kilepo.enabled := True;
end;

// =============================================================================
          procedure TKESZLETDISPLAY.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  KeszletQuery.close;
  KeszletDbase.close;
  Modalresult := _mResult;
end;

// =============================================================================
          function TKeszletDisplay.ScanKorzet(_k: integer): byte;
// =============================================================================

begin
  result := 0;
  _y := 1;
  while _y<=9 do
    begin
      if _korzetszam[_y]=_k then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

procedure TKESZLETDISPLAY.ZALOGPLUSBOXClick(Sender: TObject);

var _csekk: integer;

begin
  _csekk := -1;
  if ZalogPlusBox.Checked then _csekk := -2;
  _filter := '(ERTEKTAR='+inttostr(_csekk)+')';
  TablaDisplay;
end;

end.
