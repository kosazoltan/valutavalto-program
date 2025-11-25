unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, Unit1, DB, DBTables, DateUtils,
  IBDatabase, IBCustomDataSet, IBTable, IBQuery,strutils;

type
  TAFATABLAZATFORM = class(TForm)
    VALDATATABLA: TIBTable;
    VALDATADBASE: TIBDatabase;
    VALDATATRANZ: TIBTransaction;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    Panel10: TPanel;
    Panel11: TPanel;
    Panel12: TPanel;
    Panel13: TPanel;
    Panel14: TPanel;
    Panel15: TPanel;
    DATUMLISTBOX: TListBox;
    Panel17: TPanel;
    Panel18: TPanel;
    Panel19: TPanel;
    Panel20: TPanel;
    Panel21: TPanel;
    WUUNYPANEL: TPanel;
    WUHNYPANEL: TPanel;
    ANYPANEL: TPanel;
    WUUBPANEL: TPanel;
    WUUKPANEL: TPanel;
    WUUVPANEL: TPanel;
    WUUZPANEL: TPanel;
    WUHBPANEL: TPanel;
    WUHKPANEL: TPanel;
    WUHVPANEL: TPanel;
    WUHZPANEL: TPanel;
    ABPANEL: TPanel;
    AKPANEL: TPanel;
    AVPANEL: TPanel;
    AZPANEL: TPanel;
    Panel41: TPanel;
    Panel42: TPanel;
    Panel43: TPanel;
    Panel44: TPanel;
    ESCAPEGOMB: TBitBtn;
    INYPANEL: TPanel;
    IBPANEL: TPanel;
    IKPANEL: TPanel;
    IVPANEL: TPanel;
    IZPANEL: TPanel;
    VALDATAQUERY: TIBQuery;

    procedure ESCAPEGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure EgynapDisplay;
    procedure DATUMLISTBOXKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure RekordValtas;
    procedure WzdataBeolvasas(_adat: string);
    procedure DATUMLISTBOXClick(Sender: TObject);
    procedure AlapadatBeolvasas;
    function ForintForm(_osszeg:integer):string;
 
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AFATABLAZATFORM: TAFATABLAZATFORM;
  _wzFile: string;
  _napDarab,_cc: integer;
  _wzNap: array of string;

  _TOP,_LEFT,_WIDTH,_HEIGHT: word;
  _farok,_megnyitottnap,_pcs: string;
  _sorveg: string = chr(13)+chr(10);

  _usdnyito,_hufnyito,_metronyito,_tesconyito: integer;
  _usdbe,_hufbe,_metrobe,_tescobe: integer;
  _usdki,_hufki,_metroki,_tescoki: integer;
  _usdZaro,_hufzaro,_metrozaro,_tescozaro: integer;
  _metrovissza,_tescovissza,_eusafavissza: integer;

implementation

{$R *.dfm}


// =============================================================================
           procedure TAFATABLAZATFORM.FormActivate(Sender: TObject);
// =============================================================================

var _egyDatum: string;
begin
  _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  _top := round((_height-392)/2);
  _left := round((_width-742)/2);

  Top := _top;
  Left := _left;
  Width := 742;
  Height := 392;

  Alapadatbeolvasas;

  _farok := midstr(_megnyitottnap,3,2)+midstr(_megnyitottnap,6,2);
  _wzFile := 'WZAR'+_farok;

  ValdataDbase.connected := true;
  ValdataTabla.close;
  valdataTabla.tablename := _wzFile;
  if not ValdataTabla.Exists then
    begin
      ValdataDbase.close;
      ShowMessage('NINCSENEK E-HAVI ADATOK');
      ModalResult := 2;
      Exit;
    end;

  _pcs := 'SELECT * FROM '+ _WZfILE + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with ValdataQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _napDarab := 0;
  while not ValdataQuery.Eof do
    begin
      inc(_napDarab);
      ValdataQuery.Next;
    end;

  ValdataQuery.First;
  DatumlistBox.Clear;
  Setlength(_wznap,_napdarab);
  _cc := 0;
  while not ValdataQuery.Eof do
    begin
      _egydatum := ValdataQuery.FieldByName('DATUM').asString;
      _wznap[_cc] := '  ' + _egydatum +'  ';
      DatumlistBox.Items.Add(_wznap[_cc]);
      inc(_cc);
      ValdataQuery.Next;
    end;

  ValdataQuery.Close;
  ValdataDbase.close;
  DatumListBox.ItemIndex := 0;
  RekordValtas;
  ActiveControl := DatumListBox;
end;


procedure TafatablazatForm.AlapadatBeolvasas;

begin
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      sql.add('SELECT* FROM HARDWARE');
      Open;
      _megnyitottnap := FieldByNAme('MEGNYITOTTNAP').asString;
      Close;
    end;
  Valutadbase.close;
end;




// =============================================================================
           procedure TAFATABLAZATFORM.ESCAPEGOMBClick(Sender: TObject);
// =============================================================================

begin
  ValdataTabla.Close;
  ModalResult := 2;
end;

// =============================================================================
                   procedure TafaTablazatForm.EgyNapdisplay;
// =============================================================================

begin
  wuunypanel.Caption := ForintForm(_usdNyito);
  wuhnypanel.Caption := ForintForm(_hufNyito);
  anypanel.Caption   := ForintForm(_MetroNyito);
  inypanel.Caption   := ForintForm(_TescoNyito);

  wuubpanel.Caption := ForintForm(_usdbe);
  wuhbpanel.Caption := ForintForm(_hufbe);
  abpanel.Caption   := ForintForm(_metroBe);
  ibpanel.Caption   := ForintForm(_tescoBe);

  wuukpanel.Caption := ForintForm(_usdki);
  wuhkpanel.Caption := ForintForm(_hufki);
  akpanel.Caption := ForintForm(_metroKi);
  ikpanel.Caption := ForintForm(_tescoki);

  avpanel.Caption := ForintForm(_metrovissza+_EUSAFAVISSZA);
  ivpanel.Caption := ForintForm(_tescovissza);

  wuuzpanel.Caption := ForintForm(_usdZaro);
  wuhzpanel.Caption := ForintForm(_hufZaro);
  azpanel.Caption := ForintForm(_metroZaro);
  izpanel.Caption := ForintForm(_tescoZaro);

  DatumListBox.ItemIndex := 0;
  ActiveControl := DatumListBox;

end;


// =============================================================================
     procedure TAFATABLAZATFORM.DATUMLISTBOXKeyUp(Sender: TObject;
                                            var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  if (ord(key)=38) or (ord(key)=40) then
    begin
      RekordValtas;
      ActiveControl := DatumListBox;
      exit;
    end;
end;

// =============================================================================
                    procedure TAfaTablazatForm.RekordValtas;
// =============================================================================

var _aktrekord: integer;
    _aktdatum: string;
begin
  _aktrekord := DatumlistBox.ItemIndex;
  IF _aktrekord<0 then _aktrekord := 0;
  _aktdatum := trim(_wznap[_aktRekord]);
  WzDataBeolvasas(_aktDatum);
  EgynapDisplay;
  ActiveControl := DatumListbox;
  datumlistBox.ItemIndex := _aktrekord;
end;


// =============================================================================
           procedure TafaTablazatForm.WzdataBeolvasas(_adat: string);
// =============================================================================

begin
  _pcs := 'SELECT * FROM '+ _wzFile + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_adat+chr(39);

  ValdataDbase.Connected := true;
  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;

      _usdNyito := FieldByName('USDNYITO').asInteger;
      _hufNyito := FieldByName('HUFNYITO').asInteger;
      _MetroNyito := FieldByName('METRONYITO').asInteger;
      _TescoNyito := FieldByName('TESCONYITO').asInteger;

      _usdBe := FieldByName('USDBEVETEL').asInteger;
      _hufBe := FieldByName('HUFBEVETEL').asInteger;
      _metroBe := FieldByName('METROBEVETEL').asInteger;
      _tescoBe := FieldByName('TESCOBEVETEL').asInteger;

      _usdKi := FieldByName('USDKIADAS').asInteger;
      _hufKi := FieldByName('HUFKIADAS').asInteger;
      _metroKi := FieldByName('METROKIADAS').asInteger;
      _tescoKi := FieldByName('TESCOKIADAS').asInteger;

      _usdZaro := FieldByName('USDZARO').asInteger;
      _hufZaro := FieldByName('HUFZARO').asInteger;
      _metroZaro := FieldByName('METROZARO').asInteger;
      _tescoZaro := FieldByName('TESCOZARO').asInteger;

      _metroVissza := FieldByName('METROVISSZA').asInteger;
      _tescovissza := FieldByName('TESCOVISSZA').asInteger;
      Close;
    end;
  ValdataQuery.close;
end;

// =============================================================================
        procedure TAFATABLAZATFORM.DATUMLISTBOXClick(Sender: TObject);
// =============================================================================

begin
   RekordValtas;
   ActiveControl := DatumListBox;
end;


// =============================================================================
             function TAfaTablazatForm.ForintForm(_osszeg:integer):string;
// =============================================================================

var _slen,_pp: integer;
    _ejel : string;

begin
  Result := '-';

  if _osszeg=0 then exit;

  _ejel := '';

  if _osszeg<0 then
    begin
      _ejel := '-';
      _osszeg := abs(_osszeg);
    end;

  Result := intTostr(_osszeg);

  if _osszeg<1000 then
    begin
      Result := _ejel + Result;
      Exit;
    end;

  _sLen := length(Result);
  if _osszeg>999999 then
    begin
      _pp := _sLen-5;
      Result := _ejel + midStr(Result,1,_pp-1)+','+midStr(Result,_pp,3)+','+midStr(Result,_pp+3,3);
      Exit;
    end;

  _pp := _sLen-2;
  Result := _ejel + midStr(result,1,_pp-1)+','+midStr(result,_pp,3);

end;






end.
