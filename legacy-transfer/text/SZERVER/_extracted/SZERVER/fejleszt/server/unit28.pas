unit Unit28;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, UNIT1;

type
  TADATMENU = class(TForm)
    Panel1: TPanel;
    FOCIMPANEL: TPanel;
    FORGALOMGOMB: TBitBtn;
    KESZLETGOMB: TBitBtn;
    WUNIGOMB: TBitBtn;
    PTARKOZTGOMB: TBitBtn;
    BANKIFORGGOMB: TBitBtn;
    VISSZAGOMB: TBitBtn;
    TRBGOMB: TBitBtn;
    stornogomb: TBitBtn;
    Shape1: TShape;
    Shape2: TShape;

    procedure FormActivate(Sender: TObject);
    procedure FORGALOMGOMBClick(Sender: TObject);
    procedure FORGALOMGOMBEnter(Sender: TObject);
    procedure FORGALOMGOMBExit(Sender: TObject);
    procedure FORGALOMGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ADATMENU: TADATMENU;

implementation

uses Unit23, Unit24, Unit25;

{$R *.dfm}



procedure TADATMENU.FormActivate(Sender: TObject);
var _latni: boolean;
begin
  Top := _top + 220;
  Left := _left +175;

  FocimPanel.Caption := _DisplayFocim;
  _latni := false;
  if _DisplayTipus=1 then _latni := True;
  Ptarkoztgomb.Enabled := _latni;
  BankiForgGomb.Enabled := _latni;
  Trbgomb.Enabled := _latni;
  StornoGomb.enabled := _latni;
end;


procedure TADATMENU.FORGALOMGOMBClick(Sender: TObject);
var _tag: integer;
begin
  _tag := TBitbtn(sender).Tag;
  ModalResult := _tag;
end;

procedure TADATMENU.FORGALOMGOMBEnter(Sender: TObject);
begin
  WITH TBitBtn(sender).Font do
    begin
      Color := clNavy;
      STyle := [fsBold];
      Size := 10;
    end;

end;

procedure TADATMENU.FORGALOMGOMBExit(Sender: TObject);
begin
  WITH TBitBtn(sender).Font do
    begin
      Color := clBlack;
      STyle := [];
      Size := 8;
    end;

end;

procedure TADATMENU.FORGALOMGOMBMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  ActiveControl := TBitbtn(Sender);
end;



end.
