unit Unit15;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, unit1;

type
  TLIMITALLITOFORM = class(TForm)
    Panel1: TPanel;
    Shape1: TShape;
    Shape2: TShape;
    Shape3: TShape;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    K3EDIT: TEdit;
    Label4: TLabel;
    K1EDIT: TEdit;
    K2EDIT: TEdit;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    CSOPORTPANEL: TPanel;
    Label8: TLabel;
    KEDVOKEGOMB: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    KILEPO: TTimer;
    procedure K1EDITEnter(Sender: TObject);
    procedure K1EDITExit(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure K1EDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure K2EDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure K3EDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure KEDVOKEGOMBClick(Sender: TObject);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);
    procedure K1EDITChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  LIMITALLITOFORM: TLIMITALLITOFORM;
  _k1,_k2,_k3,_mresult: integer;
  _kedvezmeny1,_kedvezmeny2,_kedvezmeny3: integer;

implementation

{$R *.dfm}

// =============================================================================
            procedure TLIMITALLITOFORM.K1EDITEnter(Sender: TObject);
// =============================================================================

begin
  tEDIT(SENDER).Color := $B0FFFF;
end;

// =============================================================================
            procedure TLIMITALLITOFORM.K1EDITExit(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).color := clWhite;
end;

// =============================================================================
           procedure TLIMITALLITOFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top := _top + 150;
  Left := _left + 120;
  KedvOkeGomb.Enabled := false;
  Csoportpanel.Caption := inttostr(_aktcsoport);
  CsoportPanel.Repaint;

  _k1 := trunc(1000*_klimit[_aktcsoport,1]);
  _k2 := trunc(1000*_klimit[_aktcsoport,2]);
  _k3 := trunc(1000*_kLimit[_aktcsoport,3]);

  K1edit.Text := inttostr(_k1);
  K2edit.Text := inttostr(_k2);
  K3edit.Text := inttostr(_k3);
  KedvOkegomb.Enabled := false;
  ActiveControl := k1edit;
end;

// =============================================================================
   procedure TLIMITALLITOFORM.K1EDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  ActiveControl := K2edit;
end;

// =============================================================================
    procedure TLIMITALLITOFORM.K2EDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)=38 then
    begin
      ActiveControl := K1Edit;
      exit;
    end;

  if ord(key)<>13 then exit;
  ActiveControl := K3edit;
end;

// =============================================================================
   procedure TLIMITALLITOFORM.K3EDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
   if ord(key)=38 then
    begin
      ActiveControl := K2Edit;
      exit;
    end;
  if ord(key)<>13 then exit;

  if Kedvokegomb.Enabled then activecontrol := Kedvokegomb
  else activeControl := Megsemgomb;
end;

// =============================================================================
          procedure TLIMITALLITOFORM.KEDVOKEGOMBClick(Sender: TObject);
// =============================================================================

var _kedv1str,_kedv2str,_kedv3str: string;

begin
  _kedv1str := K1edit.text;
  _kedv2str := K2edit.text;
  _kedv3str := K3edit.text;

  val(_kedv1str,_kedvezmeny1,_code);
  if _code<>0 then _kedvezmeny1 := 0;

  val(_kedv2str,_kedvezmeny2,_code);
  if _code<>0 then _kedvezmeny2 := 0;

  val(_kedv3str,_kedvezmeny3,_code);
  if _code<>0 then _kedvezmeny3 := 0;

  if (_kedvezmeny1=0) or (_kedvezmeny2=0) or (_kedvezmeny3=0) then exit;
  if (_kedvezmeny1>=_kedvezmeny2) or (_kedvezmeny2>=_kedvezmeny3) then exit;

  _k1 := trunc(_kedvezmeny1/1000);
  _k2 := trunc(_kedvezmeny2/1000);
  _k3 := trunc(_kedvezmeny3/1000);

  _klimit[_aktcsoport,1] := _k1;
  _klimit[_aktcsoport,2] := _k2;
  _klimit[_aktcsoport,3] := _k3;

  _Mresult := 1;
  Kilepo.Enabled := true;
end;

// =============================================================================
          procedure TLIMITALLITOFORM.MEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  _Mresult := 2;
  Kilepo.Enabled := True;
end;

procedure TLIMITALLITOFORM.KILEPOTimer(Sender: TObject);
begin
 Kilepo.Enabled := False;
 Modalresult := _mresult;
end;

procedure TLIMITALLITOFORM.K1EDITChange(Sender: TObject);
begin
  kedvokegomb.Enabled := true;
end;

end.
