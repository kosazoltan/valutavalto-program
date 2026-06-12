unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, DBTables, Grids, DBGrids, ExtCtrls, StdCtrls, Buttons, Unit1,StrUtils,
  IBDatabase, IBCustomDataSet, IBTable, IBQuery;

type
  TGETWCEG = class(TForm)
    Panel1: TPanel;
    WCEGRACS: TDBGrid;
    WACEGEKSOURCE: TDataSource;
    RENDBENGOMB: TBitBtn;
    UJCEGGOMB: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    UJCEGPANEL: TPanel;
    WCEGNEVEDIT: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    keresedit: TEdit;
    WUCEGEKTABLA: TIBTable;
    WUCEGEKDBASE: TIBDatabase;
    WUCEGEKTRANZ: TIBTransaction;
    Shape1: TShape;
    Panel2: TPanel;
    Label1: TLabel;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;

    procedure WCEGNEVEDITEnter(Sender: TObject);
    function GetNextWudata(_mezo: string;_write:boolean): integer;
    procedure BackspaceRutin;
    procedure WCEGNEVEDITExit(Sender: TObject);
    procedure WCEGNEVEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormActivate(Sender: TObject);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure RENDBENGOMBClick(Sender: TObject);

    procedure UJCEGGOMBClick(Sender: TObject);


    procedure WCEGRACSKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure WCEGRACSKeyPress(Sender: TObject; var Key: Char);
    procedure kereseditEnter(Sender: TObject);


    procedure CegetValasztott;
    procedure RENDBENGOMBEnter(Sender: TObject);
    procedure RENDBENGOMBExit(Sender: TObject);
    procedure RENDBENGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure WCEGRACSDblClick(Sender: TObject);
    procedure WCEGRACSMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GETWCEG: TGETWCEG;
  _EZUJCEG,_megvan: boolean;
  _KERESTEXT,_partnernev,_aktcegnev,_pcs: STRING;
  _sorveg: string = chr(13)+chr(10);
  _top,_left,_height,_width,_aktcegszam: integer;


function getwesternceg: integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
                function getwesternceg: integer; stdcall;
// =============================================================================

begin
  Getwceg := TGetwceg.Create(Nil);
  result := getwceg.showmodal;
  getwceg.free;
end;


// =============================================================================
             procedure TGETWCEG.FormActivate(Sender: TObject);
// =============================================================================

begin
  UjCegPanel.Visible := False;

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;

  _top := trunc((_height-450)/2);
  _left:= trunc((_width-490)/2);

  Top := _top;
  Left := _left;
  Height := 450;
  width := 490;
  _ezUjCeg := False;

  WucegekDbase.Close;
  WucegekDbase.Connected := true;
  if wucegekTranz.InTransaction then wucegektranz.Commit;
  Wucegektranz.StartTransaction;

  with WUCegekTabla do
    begin
      IndexFieldNames := 'CEGNEV';
      Open;   //*
      Refresh;
      First;
    end;

  wCegRacs.Visible := True;
  KeresEdit.Text := '';
  _keresText := '';
  ActiveControl := wCegRacs;
  wcegracs.SetFocus;
end;

// =============================================================================
     procedure TGetWCeg.WCegRacsKeyDown(Sender: TObject; var Key: Word;
                                    Shift: TShiftState);
// =============================================================================

var _kod: Integer;

begin
  _kod := ord(key);
  if (_kod>64)  or (_kod=32) then
    begin
      _keresText := _kerestext + chr(_kod);
      _megvan := WUcegekTabla.Locate('CEGNEV',_keresText,[loCaseInSensitive,loPartialKey]);
      if not _megvan then BackspaceRutin else Keresedit.Text := _keresText;
      exit;
    end;

  if _kod=13 then
    begin
      CegetValasztott;
      exit;
    end;

  if (_kod=38) or (_kod=40) then
    begin
      _kerestext := '';
      Keresedit.Clear;
      exit;
    end;
end;

// =============================================================================
                     procedure TGetWCeg.BackspaceRutin;
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
  wUcegekTabla.Locate('CegNEV',_keresText,[loCaseInsensitive,loPartialKey]);
end;

// =============================================================================
    procedure TGetWCeg.WCegRacsKeyPress(Sender: TObject;
                                                        var Key: Char);
// =============================================================================

begin
  if ord(key)=8 then
          BackspaceRutin;
end;

// =============================================================================
            procedure TGETWCEG.WCEGNEVEDITEnter(Sender: TObject);
// =============================================================================

begin
  WCEGNEVEDIT.Color := clYellow;
end;


// =============================================================================
            procedure TGETWCEG.WCEGNEVEDITExit(Sender: TObject);
// =============================================================================

begin
  WCegnevedit.Color := clWindow;
end;

// =============================================================================
       procedure TGETWCEG.WCEGNEVEDITKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  _partnernev := wCegNevedit.text;
  if _partnernev='' then exit;
  ActiveControl := RendbenGomb;
end;


// =============================================================================
                 procedure TGETWCEG.MEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  if wucegekTranz.InTransaction then wucegektranz.Commit;
  WUcegekTabla.Close;
  Wucegekdbase.close;
  ModalResult := -1;
end;

// =============================================================================
            procedure TGETWCEG.RENDBENGOMBClick(Sender: TObject);
// =============================================================================

begin
   if _ezUjCeg then
    begin
      if WcegnevEdit.Text='' then exit;
      _aktCegNev := wCegnevEdit.Text;
      _aktCegszam := GetNextWudata('UTOLSOWUCEG',True);
      with WuCegekTabla do
        begin
          Append;
          Edit;
          FieldbyName('CEGSZAM').AsInteger := _aktCegSzam;
          FieldByName('CEGNEV').AsString := _aktCegNev;
          Post;
        end;
    end else
    Begin
      _aktCegSzam := WuCegekTabla.FieldByName('CEGSZAM').asInteger;
      _aktCegnev := wuCegekTabla.FieldByName('CEGNEV').asString;
    end;

  WucegekTranz.Commit;
  WucegekDbase.close;

  _partnerNev := _aktcegnev;
  ModalResult := _aktcegszam;
end;


// =============================================================================
          procedure TGETWCEG.UJCEGGOMBClick(Sender: TObject);
// =============================================================================

begin
   _ezUjCeg := True;
   with UjcegPanel do
     begin
       top := 96;
       Left := 24;
       Visible := true;
     end;
  wCegNevedit.Clear;
  ActiveControl := wCegNevedit;
  WcegNevedit.SetFocus;
end;



// =============================================================================
            procedure TGETWCEG.kereseditEnter(Sender: TObject);
// =============================================================================

begin
  ActiveControl := wcegRacs;
end;


// =============================================================================
                    procedure TGetWCeg.Cegetvalasztott;
// =============================================================================


begin
   _partNernev := wUcegekTabla.FieldByName('CEGNEV').asString;
   _aktcegSzam := WUCEGEKTabla.FieldByName('CEGSZAM').asInteger;
   KeresEdit.Text := _partnerNev;
   RendbenGombClick(wcegracs);
end;



// =============================================================================
         procedure TGETWCEG.RENDBENGOMBEnter(Sender: TObject);
// =============================================================================

begin
  with TBitbtn(sender).Font do
    begin
      Color := clRed;
      Style := [fsBold];
    end;
end;


// =============================================================================
             procedure TGETWCEG.RENDBENGOMBExit(Sender: TObject);
// =============================================================================

begin
  with TBitbtn(sender).Font do
    begin
      Color := clBlack;
      Style := [];
    end;
end;

// =============================================================================
     procedure TGETWCEG.RENDBENGOMBMouseMove(Sender: TObject;
                                            Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  ActiveControl := Tbitbtn(sender);
end;

// =============================================================================
      procedure TGETWCEG.WCEGRACSDblClick(Sender: TObject);
// =============================================================================

begin
  CegetValasztott;
end;

// =============================================================================
     procedure TGETWCEG.WCEGRACSMouseMove(Sender: TObject;
                                            Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  ActiveControl := Wcegracs;
end;

// =============================================================================
      function TGetwCeg.GetNextWudata(_mezo: string;_write:boolean): integer;
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
      ValutaDbase.Connected := true;
      if ValutaTranz.InTransaction then valutaTranz.Commit;
      ValutaTranz.StartTransaction;
      with ValutaQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          ExecSql;
        end;
      Valutatranz.Commit;
      ValutaDbase.close;
    end;
end;




end.
