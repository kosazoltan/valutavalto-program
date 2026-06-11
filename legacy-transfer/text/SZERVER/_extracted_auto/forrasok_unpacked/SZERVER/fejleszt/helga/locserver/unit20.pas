unit Unit20;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons,Unit1, ExtCtrls;

type
  TKELLTEGNAP = class(TForm)
    Label1: TLabel;
    IGENGOMB: TBitBtn;
    NEMGOMB: TBitBtn;
    Shape1: TShape;
    procedure FormActivate(Sender: TObject);
    procedure IGENGOMBEnter(Sender: TObject);
    procedure IGENGOMBExit(Sender: TObject);
    procedure IGENGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure IGENGOMBClick(Sender: TObject);
    procedure NEMGOMBClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  KELLTEGNAP: TKELLTEGNAP;

implementation

{$R *.dfm}

procedure TKELLTEGNAP.FormActivate(Sender: TObject);
begin
  TOP := _TOP + 350;
  lEFT := _left + 210;
  Activecontrol := NemGomb;
end;

procedure TKELLTEGNAP.IGENGOMBEnter(Sender: TObject);
begin
  with TBitbtn(Sender) do
    begin
      Font.Style := [fsBold];
      Font.Color := clNavy;
    end;
end;

procedure TKELLTEGNAP.IGENGOMBExit(Sender: TObject);
begin
   with TBitbtn(Sender) do
    begin
      Font.Style := [];
      Font.Color := clGray;
    end;
end;

procedure TKELLTEGNAP.IGENGOMBMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  ActiveControl := TBitbtn(Sender);
end;

procedure TKELLTEGNAP.IGENGOMBClick(Sender: TObject);
begin
  ModalResult := 1;
end;

procedure TKELLTEGNAP.NEMGOMBClick(Sender: TObject);
begin
  ModalResult := 2;
end;

end.
