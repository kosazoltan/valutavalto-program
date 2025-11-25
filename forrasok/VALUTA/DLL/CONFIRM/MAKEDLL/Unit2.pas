unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB,
  IBCustomDataSet, IBQuery;

type
  TCONFIRMFORM = class(TForm)
    KITOLPANEL: TPanel;
    MENNYITPANEL: TPanel;
    IGENGOMB: TBitBtn;
    NEMGOMB: TBitBtn;
    Label2: TLabel;
    TRANSPANEL: TPanel;
    IBQUERY: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    Shape1: TShape;
    Panel1: TPanel;

    procedure FormActivate(Sender: TObject);
    procedure IGENGOMBClick(Sender: TObject);
    procedure NEMGOMBClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CONFIRMFORM: TCONFIRMFORM;
  _top,_left,_width,_height: word;
  _pcs,_ugyfelnev,_tipus,_kitol,_trans,_mennyit: string;
  _sorveg: string = chr(13)+chr(10);
  _fizetendo: integer;


function confirmrutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
                function confirmrutin: integer; stdcall;
// =============================================================================

begin
   Confirmform := TConfirmform.Create(Nil);
   result := ConfirmForm.ShowModal;
   Confirmform.Free;
end;

// =============================================================================
            procedure TCONFIRMFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].width;

  _top := trunc((_height-768)/2);
  _left := trunc((_width-1024)/2);

  Top    := _top+250;
  Left   := _left +350;
  Height := 265;
  Width  := 320;

  _pcs := 'SELECT * FROM VTEMP';
  ibdbase.Connected := true;
  with Ibquery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      _ugyfelnev := trim(FieldByName('UGYFELNEV').AsString);
      _fizetendo := fieldByName('FIZETENDO').asInteger;
      _tipus     := FieldByNAme('TIPUS').AsString;
      close;
    end;

  ibdbase.close;

  if _tipus='V' then
    begin
      _trans := 'VALUTÁT VÁSÁROLUNK';
      _kitol := _ugyfelnev+'-TÕL';
    end;

  if _tipus='E' then
    begin
     _trans := 'VALUTÁT ADUNK EL';
     _kitol := _ugyfelnev+'-NEK';
    end;

  _mennyit := inttostr(_fizetendo)+' FT ÉRTÉKBEN';

  TransPanel.Caption   := _trans;
  IF _UGYFELNEV<>'' then KitolPanel.Caption   := _kitol;
  Mennyitpanel.Caption := _mennyit;
  Repaint;

  ActiveControl := IgenGomb;
end;

// =============================================================================
          procedure TCONFIRMFORM.IGENGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;

// =============================================================================
            procedure TCONFIRMFORM.NEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 2;
end;




end.
