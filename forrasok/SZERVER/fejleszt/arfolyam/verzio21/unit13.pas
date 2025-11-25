unit Unit13;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, Unit1;

type
  TZOLDMENU = class(TForm)
    Panel1: TPanel;
    copygomb: TBitBtn;
    LEHUZOGOMB: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    procedure FormActivate(Sender: TObject);
    procedure copygombEnter(Sender: TObject);
    procedure copygombExit(Sender: TObject);
    procedure copygombClick(Sender: TObject);
    procedure copygombMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ZOLDMENU: TZOLDMENU;
  _mresult: integer;

implementation

{$R *.dfm}

// =============================================================================
             procedure TZOLDMENU.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top := _top + _zmenusor;
  Left := _left + _zmenuoszlop;
  if (_startsor=_endsor) then lehuzogomb.Enabled := false
  else Lehuzogomb.Enabled := true;
  Activecontrol := Copygomb;

end;

// =============================================================================
           procedure TZOLDMENU.copygombEnter(Sender: TObject);
// =============================================================================

begin
  TBitbtn(sender).Font.color := clNavy;
  Tbitbtn(sender).Font.Style := [fsBold];
end;

procedure TZOLDMENU.copygombExit(Sender: TObject);
begin
  Tbitbtn(sender).Font.Style := [];
  TBitbtn(sender).Font.Color := clBlack;
end;

// =============================================================================
            procedure TZOLDMENU.copygombClick(Sender: TObject);
// =============================================================================

begin
  _arfdataValtozott := true;
  _mresult := Tbitbtn(sender).Tag;
  ModalResult := _mResult;
end;

// =============================================================================
   procedure TZOLDMENU.copygombMouseMove(Sender: TObject; Shift: TShiftState;
                                                                X, Y: Integer);
// =============================================================================

begin
  ActiveControl := TBitbtn(sender);
end;

end.
