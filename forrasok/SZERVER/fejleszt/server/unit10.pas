unit Unit10;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, Unit1;

type
  TFOMENUFORM = class(TForm)
    FOMENUPANEL: TPanel;
    MPanel1: TPanel;
    MPanel2: TPanel;
    MPanel3: TPanel;
    MPanel4: TPanel;
    MPanel5: TPanel;
    MPanel6: TPanel;
    MPanel7: TPanel;
    MPanel8: TPanel;
    MPanel9: TPanel;
    MPANEL10: TPanel;
    MPANEL11: TPanel;
    MENUEDIT: TEdit;
    NINCSMENUGOMB: TBitBtn;
    Shape1: TShape;
    MPANEL12: TPanel;
    MPANEL13: TPanel;
    MPANEL14: TPanel;
    MPANEL15: TPanel;
    MPANEL16: TPanel;
    MPANEL17: TPanel;
    MPANEL18: TPanel;
    MPANEL19: TPanel;
    MPANEL20: TPanel;
    MPANEL21: TPanel;
    MPANEL22: TPanel;

    procedure FormActivate(Sender: TObject);
    procedure NINCSMENUGOMBClick(Sender: TObject);
    procedure MENUEDITKeyDown(Sender: TObject; var Key: Word;
                      Shift: TShiftState);
    procedure MenuFesto;
    procedure MPanel1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure MPanel1Click(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FOMENUFORM: TFOMENUFORM;
  _menurudak: array[1..14] of TPanel;
  _aktPanel: TPanel;

implementation

{$R *.dfm}

// ============================================================
      procedure TFOMENUFORM.FormActivate(Sender: TObject);
// ============================================================

begin
  Top := _top + 300;
  Left := _left +250;
  _menurudak[1] := mPanel1;
  _menurudak[2] := mPanel2;
  _menurudak[3] := mPanel3;
  _menurudak[4] := mPanel4;
  _menurudak[5] := mPanel5;
  _menurudak[6] := mPanel6;
  _menurudak[7] := mPanel7;
  _menurudak[8] := mPanel8;
  _menurudak[9] := mPanel9;
  _menurudak[10]:= mPanel10;
  _menurudak[11]:= mPanel11;
  _menurudak[12]:= mPanel12;
  _menurudak[13]:= mPanel13;
  _menurudak[14]:= mPanel14;

  MenuFesto;
  ActiveControl := Menuedit;
end;

// ====================================
       procedure TFomenuForm.Menufesto;
// ====================================

var _m: integer;

begin
  for _m := 1 to 14 do
    begin
      _aktPanel := _menurudak[_m];
      if _m=_aktmenurud then
        begin
          _aktpanel.Font.Style := [fsBold];
          _aktPanel.Font.Color := clRed;
        end else
        begin
          _aktpanel.Font.Style := [];
          _aktPanel.Font.Color := clBlack;
        end;
    end;
end;

// ====================================================================
    procedure TFomenuForm.MENUEDITKeyDown(Sender: TObject; var Key: Word;
                      Shift: TShiftState);
// ====================================================================

begin
  case ord(key) of
    40:  // down
      begin
         inc(_aktmenurud);
         if _aktmenurud>14 then _aktmenurud := 1;
         menuFesto;
      end;

    38:  // up
       begin
         dec(_aktmenurud);
         if _aktmenurud<1 then _aktmenurud := 14;
         menufesto;
       end;

    13: begin
          ModalResult := _aktMenuRud;
          exit;
        end;
     end;
end;

// ============================================================
   procedure TFOMENUFORM.NINCSMENUGOMBClick(Sender: TObject);
// ============================================================

begin
  Modalresult :=-1;
end;

// =============================================================================
    procedure TFOMENUFORM.MPanel1MouseMove(Sender: TObject; Shift: TShiftState;
                                                              X, Y: Integer);
// =============================================================================
begin
   _aktmenurud := TPanel(Sender).Tag;
   menuFesto;
end;

// ============================================================
      procedure TFOMENUFORM.MPanel1Click(Sender: TObject);
// ============================================================

var _tag: integer;

begin
  _tag := Tpanel(sender).Tag;
  ModalResult := _tag;
end;

end.
