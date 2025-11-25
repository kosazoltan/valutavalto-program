unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Unit1, DB, DBTables, Grids, DBGrids, Buttons, StrUtils,
  IBDatabase, IBCustomDataSet, IBTable, IBQuery;

type
  TGETWUGYF = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    KERESEDIT: TEdit;
    WUGYFELRACS: TDBGrid;
    UGYFELSOURCE: TDataSource;
    Label2: TLabel;
    KARTONGOMB: TBitBtn;
    ujugyfelgomb: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    UGYFELKARTON: TPanel;
    Label3: TLabel;
    WNEVEDIT: TEdit;
    WANYJAEDIT: TEdit;
    WSZULHELYEDIT: TEdit;
    WSZULIDOEDIT: TEdit;
    WLAKCIMEDIT: TEdit;
    WOKMTIPEDIT: TEdit;
    WAZONOSITOEDIT: TEdit;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    WUUGYFELTABLA: TIBTable;
    WUUGYFELDBASE: TIBDatabase;
    WUUGYFELTRANZ: TIBTransaction;
    RENDBENGOMB: TBitBtn;
    Shape1: TShape;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    KILEP: TTimer;
    Shape2: TShape;
    Shape3: TShape;
    WESTERNPANEL: TPanel;
    Label11: TLabel;
    Label12: TLabel;
    Shape4: TShape;
    METROPANEL: TPanel;
    TESCOPANEL: TPanel;
    Shape5: TShape;
    Label13: TLabel;
    Shape6: TShape;
    Label14: TLabel;

    procedure FormActivate(Sender: TObject);
    procedure ibValutaParancs(_ukaz: string);

    procedure KartonDisplay;
    procedure GetWuData;
    procedure KARTONGOMBClick(Sender: TObject);
    function GetNextWudata(_mezo: string;_write:boolean): integer;

    procedure WNEVEDITEnter(Sender: TObject);
    procedure WNEVEDITExit(Sender: TObject);
    procedure WNEVEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ujugyfelgombClick(Sender: TObject);

    procedure WUGYFELRACSKeyPress(Sender: TObject; var Key: Char);
    procedure BackspaceRutin;
    procedure KERESEDITEnter(Sender: TObject);
    procedure WNEVEDITChange(Sender: TObject);
    procedure Adatfeliras(_sorszam:integer);
    procedure AdatKiolvasas;
    procedure Ugyfeletvalasztott;
    procedure RENDBENGOMBClick(Sender: TObject);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure RENDBENGOMBEnter(Sender: TObject);
    procedure RENDBENGOMBExit(Sender: TObject);
    procedure RENDBENGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure WUGYFELRACSDblClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure KILEPTimer(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GETWUGYF: TGETWUGYF;
  _pcs,_keresText,_partnernev,_aktcegnev,_tallon: String;
  _sorveg: string = chr(13)+ chr(10);
  _wedit: array[1..7] of TEdit;
  _aktEdit : TEdit;
  _ezkarton: boolean;
  _kartongomb,_megvan,_ezUjUgyfel,_valtoztatas: boolean;
  _tabtip: integer;   // 1=western, 2=metro, 3=tesco
  _mResult,_top,_left,_height,_width: integer;
  _aktcegszam,_ugyfelszam,_maxlen: integer;
  _anyjaneve,_szulhely,_szulido,_lakcim,_okmanyTipus,_azonosito: string;


function getwesternugyfel(_para: integer): integer; stdcall;

implementation


{$R *.dfm}



function getwesternugyfel(_para: integer):integer; stdcall;

begin
  Getwugyf := TGetwUgyf.Create(Nil);
  _tabtip := _para;
  result := Getwugyf.showmodal;
  Getwugyf.free;
end;


// =============================================================================
            procedure TGETWUGYF.FormActivate(Sender: TObject);
// =============================================================================

begin
   UgyfelKarton.Visible := False;
   WesternPanel.Visible := false;
   MetroPanel.Visible := False;
   TescoPanel.Visible := false;

   case _tabtip of
     1: WesternPanel.visible := true;

     2: Metropanel.visible := true;
     3: TescoPanel.Visible := True;

   end;  

   _height := Screen.Monitors[0].Height;
   _width  := Screen.Monitors[0].width;

   _top    := 0;
   _left   := 0;

   if _height>768 then _top := trunc((_height-768)/2);
   if _width>1024 then _left:= trunc((_width-1024)/2);

   Top    := _top + 109;
   Left   := _left + 20;

   Height := 550;
   Width := 985;
   _mresult := -1;

   _ezUjUgyfel := False;
     _ezKarton := False;

   KeyPreview := True;
   UjUgyfelGomb.Enabled := True;
   KartonGomb.Enabled := True;
   RendbenGomb.Enabled := False;
   _kartonGomb := True;

   _wedit[1] := WNEVEDIT;
   _wedit[2] := WANYJAEDIT;
   _wedit[3] := WSZULHELYEDIT;
   _wedit[4] := WSZULIDOEDIT;
   _wedit[5] := WLAKCIMEDIT;
   _wedit[6] := WOKMTIPEDIT;
   _wedit[7] := WAZONOSITOEDIT;

   wuUgyfeldbase.Close;
   wuUgyfelDbase.Connected := true;
   with Wuugyfeltabla do
     begin
       IndexFieldNames := 'NEV';
       Open;    //*
       Refresh;
       First;
     END;

   wUgyfelRacs.Visible := True;

   KeresEdit.Text := '';
   _keresText := '';
   _valtoztatas := False;
   ActiveControl := wUgyfelRacs;
   wUgyfelRacs.SetFocus;
end;


// =============================================================================
                procedure TGetWUGYF.BackspaceRutin;
// =============================================================================

var _ww: integer;
begin
  if _keresText ='' then
    begin
      Keresedit.Clear;
      exit;
    end;
  _ww := length(_keresText);
  if _ww=1 then
    begin
      Keresedit.Text := '';
      _keresText := '';
      Exit;
    end;
  _keresText := leftstr(_keresText,_ww-1);
  Keresedit.Text := _keresText;
  wuUgyfelTabla.Locate('NEV',_keresText,[loCaseInsensitive,loPartialKey]);
end;

// =============================================================================
    procedure TGETWUGYF.WUGYFELRACSKeyPress(Sender: TObject;
                                           var Key: Char);
// =============================================================================

begin
  if ord(key)=8 then BackspaceRutin;
end;


// =============================================================================
         procedure TGETWUGYF.KARTONGOMBClick(Sender: TObject);
// =============================================================================

begin
  _ezUjUgyfel := False;
  _ugyfelszam := WuUgyfelTabla.FieldByNAme('UGYFELSZAM').asInteger;
  GetwuData;
  KartonDisplay;
end;


// =============================================================================
                 procedure TGetWUgyf.AdatKiolvasas;
// =============================================================================

begin
  _partnerNev := wnevedit.Text;
  _AnyjaNeve := wAnyjaEdit.Text;
  _szulhely := wszulhelyedit.TExt;
  _Szulido := wSzulidoEdit.Text;
  _Lakcim := wLakcimedit.Text;
  _OkmanyTipus := WokmTipEdit.text;
  _Azonosito := wazonositoEdit.Text;
end;



// =============================================================================
            procedure TGetWUgyf.Adatfeliras(_sorszam: integer);
// =============================================================================

begin

  Valutadbase.Connected := True;
  if ValutaTranz.Intransaction then ValutaTranz.commit;
  ValutaTranz.startTransaction;

  if _ezujugyfel then
    begin
      _pcs := 'INSERT INTO WUGYFEL (UGYFELSZAM,NEV,ANYJANEVE,SZULETESIHELY,';
      _pcs := _pcs + 'SZULETESIIDO,LAKCIM,OKMANYTIPUS,AZONOSITO)'+_sorveg;

      _pcs := _pcs + 'VALUES ('+inttostr(_sorszam)+',';
      _pcs := _pcs + chr(39)+_partnernev+chr(39)+',';
      _pcs := _pcs + chr(39)+_anyjaneve+chr(39)+',';
      _pcs := _pcs + chr(39)+_szulhely+chr(39)+',';
      _pcs := _pcs + chr(39)+_szulido+chr(39)+',';
      _pcs := _pcs + chr(39)+_lakcim+chr(39)+',';
      _pcs := _pcs + chr(39)+_okmanytipus+chr(39)+',';
      _pcs := _pcs + chr(39)+_azonosito+chr(39)+ ')';
    end else
    begin
      _pcs := 'UPDATE WUGYFEL SET NEV='+chr(39)+_partnernev+chr(39);
      _pcs := _pcs +',ANYJANEVE='+chr(39)+_anyjaneve+chr(39);
      _pcs := _pcs +',SZULETESIHELY='+chr(39)+_szulhely+chr(39);
      _pcs := _pcs + ',SZULETESIIDO='+chr(39)+_szulido+chr(39);
      _pcs := _pcs + ',LAKCIM='+CHR(39)+_lakcim + chr(39);
      _pcs := _pcs + ',OKMANYTIPUS='+chr(39)+_okmanytipus+chr(39);
      _pcs := _pcs + ',AZONOSITO='+chr(39)+_azonosito+chr(39)+_sorveg;
      _pcs := _pcs + 'WHERE UGYFELSZAM='+inttostr(_sorszam);
    end;

  with VAlutaquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Execsql;
    end;
  ValutaTranz.commit;
end;


// =============================================================================
           procedure TGETWUgyf.WNEVEDITEnter(Sender: TObject);
// =============================================================================

begin
  _aktedit := TEdit(sender);
  _AKTEDIT.Modified := TRUE;
  _aktedit.color := $FFB0FF;
end;




// =============================================================================
            procedure TGETWUgyf.WNEVEDITExit(Sender: TObject);
// =============================================================================

begin

  TEdit(sender).Color := clWindow;
end;

// =============================================================================
     procedure TGETWUgyf.WNEVEDITKeyDown(Sender: TObject; var Key: Word;
                                                    Shift: TShiftState);
// =============================================================================

var _tag: integer;

begin
  if (ord(key)=13) or (ord(key)=40) then
    begin
      _tag := Tedit(sender).Tag;
      if (_tag=1) and (wnevedit.Text='') then exit;
      RendbenGomb.Enabled := True;
      inc(_tag);
      if _tag<8 then
        begin
          _aktEdit := _wedit[_tag];
          ActiveControl := _aktedit;
          Exit;
        end;
      ActiveControl := RendbenGomb;
   //   UjugyfelGomb.Enabled := true;
      Exit;
    end;

  if (ord(key)=38) then  // Up
    begin
      _tag := TEdit(Sender).Tag;
      if _tag>1 then
        begin
          _aktedit := _wedit[_tag-1];
          ActiveControl := _aktEdit;
        end;
    end;
end;

// =============================================================================
           procedure TGETWUgyf.ujugyfelgombClick(Sender: TObject);
// =============================================================================

var i: integer;

begin
  UjugyfelGomb.Enabled := False;
  KartonGomb.Enabled := False;
  _kartonGomb := False;

  for i := 1 to 7 do _wedit[i].Clear;

  with UgyfelKarton do
    begin
      Left := 24;
      Top := 88;
      Visible := True;
    end;

  ActiveControl := wNevedit;
  _ezUjUgyfel := True;
end;



// =============================================================================
                    procedure TGetWUgyf.KartonDisplay;
// =============================================================================

begin

  KartonGomb.Enabled := False;
  _kartonGomb := False;
  _valtoztatas := False;

 // _ugyfelszam := WuUgyfelTabla.FieldByNAme('UGYFELSZAM').asInteger;
//  GetwuData;

  wNevedit.Text := TRIM(_partnernev);
  wAnyjaEdit.Text := trim(_anyjaNeve);
  wSzulhelyedit.TExt := trim(_szulhely);
  wSzulidoEdit.Text := trim(_Szulido);
  wLakcimedit.Text := trim(_lakcim);
  WOkmTipEdit.text := trim(_OkmanyTipus);
  wAzonositoEdit.Text := trim(_Azonosito);

  with UgyfelKarton do
    begin
      Top := 88;
      Left := 24;
      Visible := True;
    end;

  RendbenGomb.Enabled := True;
  ActiveControl := RendbenGomb;
end;

// =============================================================================
                    procedure TGetWUgyf.GetWudata;
// =============================================================================

begin
  ValutaDbase.close;
  ValutaDbase.Connected := True;

  if ValutaTranz.Intransaction then ValutaTranz.commit;

  _pcs := 'SELECT * FROM WUGYFEL'+ _sorveg;
  _pcs := _pcs + 'WHERE UGYFELSZAM='+inttostr(_ugyfelszam);

  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
    end;

  if ValutaQuery.Recno>0 then
    begin
      with ValutaQuery do
        begin
          _partNernev := FieldByName('NEV').asString;
          _AnyjaNeve := FieldByNAme('ANYJANEVE').asString;
          _szulhely := FieldByName('SZULETESIHELY').AsString;
          _Szulido := FieldByName('SZULETESIIDO').asstring;
          _lakcim := FieldByName('LAKCIM').AsString;
          _Okmanytipus := FieldByName('OKMANYTIPUS').asstring;
          _Azonosito := FieldByNAme('AZONOSITO').asstring;
        end;
    end;
  ValutaQuery.close;
end;


// =============================================================================
            procedure TGETWUgyf.KERESEDITEnter(Sender: TObject);
// =============================================================================

begin
  ActiveControl := WugyfelRacs;
end;


// =============================================================================
          procedure TGETWUgyf.WNEVEDITChange(Sender: TObject);
// =============================================================================

begin
  _valtoztatas := True;
end;

// =============================================================================
                  procedure TGetWUgyf.UgyfeletValasztott;
// =============================================================================

begin
  UjugyfelGomb.Enabled := False;
  KartonGomb.Enabled := False;
  _kartonGomb := False;
  _ugyfelszam := WuUgyfelTabla.FieldByNAme('UGYFELSZAM').asInteger;
  GetwuData;
  RendbenGombClick(WUgyfelRacs);
end;


// =============================================================================
            procedure TGETWUgyf.RENDBENGOMBClick(Sender: TObject);
// =============================================================================

begin
  if _ezUjUgyfel then
    begin
      _ugyfelszam := GetNextWudata('UTOLSOWUGYFEL',True);
    end;

  if _valtoztatas then
    begin
      AdatKiolvasas; // editekböl változókba
    end;

  Adatfeliras(_ugyfelszam);

  WuUgyfelTabla.close;
  ModalResult := _ugyfelszam;
  exit;
end;

// =============================================================================
           procedure TGETWUgyf.MEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  WuUgyfelTabla.Close;
  ModalResult := -1;
end;

// =============================================================================
          procedure TGETWUgyf.RENDBENGOMBEnter(Sender: TObject);
// =============================================================================

begin
  with Tbitbtn(Sender).Font do
    begin
      Color := clRed;
      Style := [fsBold];
    end;
end;

// =============================================================================
         procedure TGETWUgyf.RENDBENGOMBExit(Sender: TObject);
// =============================================================================

begin
  with Tbitbtn(Sender).Font do
    begin
      Color := clBlack;
      Style := [];
    end;
end;

// =============================================================================
      procedure TGETWUgyf.RENDBENGOMBMouseMove(Sender: TObject;
                                            Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  ActiveControl := TBitBtn(sender);
end;

// =============================================================================
          procedure TGETWUgyf.WUGYFELRACSDblClick(Sender: TObject);
// =============================================================================

begin
  if not _kartonGomb then exit;
  KartonGombClick(wugyfelRacs);
end;

// =============================================================================
     procedure TGETWUgyf.FormKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

var _kod: integer;
begin
   _kod := Ord(key);

  // Keres egy nevet
  if (_kod>64) or (_kod=32) then
    begin
      _kerestext := _keresText + chr(_kod);
      _megvan := wuUgyfelTabla.Locate('NEV',_keresText,[loCaseInsensitive,loPartialKey]);
      if not _megvan then BackspaceRutin else Keresedit.Text := _keresText;
      exit;
    end;

  // enter -> Kiválasztott egy ügyfelet:

  if (_kod=13) and (_kartongomb) then
    begin
      KartonGombClick(wugyfelRacs);
      exit;
    end;

  // Le-fel kurzor után keresö string üritve

  if (_kod=38) or (_kod=40) then
    begin
      _keresText := '';
      Keresedit.Clear;
      exit;
    end;
end;

// =============================================================================
      function TGetwUgyf.GetNextWudata(_mezo: string;_write:boolean): integer;
// =============================================================================

begin

  ValutaDbase.Close;
  ValutaDbase.Connected := true;
  if ValutaTranz.InTransaction then ValutaTranz.Commit;
  _pcs := 'SELECT * FROM WUAFAADATOK';
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.add(_pcs);
      Open;
    end;

  result := ValutaQuery.FieldByName(_mezo).asInteger;
  ValutaQuery.close;
  ValutaDbase.close;

 // -------------------------------------------------------

  inc(result);

  if _write then
    begin
      _pcs := 'UPDATE WUAFAADATOK SET '+_mezo+'='+inttostr(result);
      ibValutaParancs(_pcs);
    end;
end;


procedure TGETWUgyf.KILEPTimer(Sender: TObject);
begin
  Kilep.Enabled := False;
  ModalResult := _mResult;
end;

procedure TGetwUgyf.ibValutaParancs(_ukaz: string);

begin
 ValutaDbase.connected := true;
 if ValutaTranz.InTransaction then ValutaTranz.Commit;
 ValutaTranz.StartTransaction;
 with ValutaQuery do
   begin
     Close;
     Sql.Clear;
     Sql.Add(_ukaz);
     ExecSql;
   end;
 ValutaTranz.Commit;
 ValutaDbase.close;

end;

end.
