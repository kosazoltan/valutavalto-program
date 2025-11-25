unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, StrUtils, DB, IBDatabase, MAPI,
  IBCustomDataSet, IBTable, ShellAPI, IBQuery, ComCtrls, jpeg;

type
  TTERMINALFORM = class(TForm)
    Label2: TLabel;
    JELZOSHAPE: TShape;
    UZENOPANEL: TPanel;
    VISSZAGOMB: TBitBtn;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    Image1: TImage;

    procedure FormActivate(Sender: TObject);
    procedure VISSZAGOMBClick(Sender: TObject);
 
  private

    { Private declarations }
  public
    { Public declarations }
  end;

var
  TERMINALFORM: TTERMINALFORM;
  _oke: integer;

  _top,_left,_height,_width: word;
 

function estizarasbekuldes: integer; stdcall; external 'c:\ERTEKTAR\bin\estizar.dll' name 'estizaraskuldes';

function terminalrutin: integer; stdcall;

implementation


{$R *.dfm}

function terminalrutin: integer; stdcall;

begin
  terminalform := Tterminalform.create(Nil);
  result := Terminalform.ShowModal;
  Terminalform.Free;
end;


// =============================================================================
            procedure TTerminalForm.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := screen.Monitors[0].Height;
  _width := screen.Monitors[0].width;

  _top := round((_height-768)/2);
  _left:= round((_width-1024)/2);


  Top  := _top+45;
  Left := _left+106;

  Height := 678;
  Width  := 811;

  Uzenopanel.Visible := False;
  Visszagomb.visible := false;
  Jelzoshape.Brush.Color := $555555;

  _oke := estizarasbekuldes;
  if _oke=1 then
    begin
      Uzenopanel.caption := 'Esti zárás sikeresen beküldve';
      JelzoShape.Brush.color := clGreen;
      Uzenopanel.color := clGreen;
    end else
    begin
      UzenoPanel.caption := 'Sikertelen csomagküldés';
      Jelzoshape.Brush.Color := clRed;
      Uzenopanel.color := clRed;
    end;

   Uzenopanel.Visible := true;
   Uzenopanel.repaint;
   Visszagomb.visible := True;

end;


// =============================================================================
             procedure TTERMINALFORM.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := _oke
end;

end.
