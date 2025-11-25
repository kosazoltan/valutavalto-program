unit Unit13;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls,Unit1;

type
  TKEZIADATPOTLASFORM = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    P1GOMB: TBitBtn;
    P2GOMB: TBitBtn;
    POTLASOKEGOMB: TBitBtn;
    POTLASKESOBBGOMB: TBitBtn;
    PENZTARPANEL: TPanel;
    DATUMPANEL: TPanel;
    POTMENUPANEL: TPanel;
    MANUALISGOMB: TBitBtn;
    PENZTARZAROGOMB: TBitBtn;
    procedure P1GOMBEnter(Sender: TObject);
    procedure P1GOMBExit(Sender: TObject);
    procedure POTLASKESOBBGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure PENZTARZAROGOMBClick(Sender: TObject);
    procedure MANUALISGOMBClick(Sender: TObject);
    procedure P1GOMBClick(Sender: TObject);
    procedure P2GOMBClick(Sender: TObject);
    procedure POTLASOKEGOMBClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  KEZIADATPOTLASFORM: TKEZIADATPOTLASFORM;

implementation

uses Unit14, Unit15, Unit8;

{$R *.dfm}

procedure TKEZIADATPOTLASFORM.P1GOMBEnter(Sender: TObject);
begin
  Tbitbtn(sender).Font.color := clRed;
  TBitbtn(sender).font.style := [fsBold];
end;

procedure TKEZIADATPOTLASFORM.P1GOMBExit(Sender: TObject);
begin
  TBitBtn(sender).Font.color := clBlack;
  TBitBtn(Sender).Font.Style := [];
end;

procedure TKEZIADATPOTLASFORM.POTLASKESOBBGOMBClick(Sender: TObject);
begin
  ModalResult := 2;
end;

procedure TKEZIADATPOTLASFORM.FormActivate(Sender: TObject);
begin
  Top := _top +180;
  Left := _left + 300;
  PenztarPanel.Caption := inttostr(_aktPenztar)+' '+_aktPenztarNev;
  datumPanel.Caption := Form1.hdatetostr(_aktdatum);
  PotmenuPanel.Visible := True;
  PotlasOkeGomb.Visible := False;
  ActiveControl := ManualisGomb;
end;

procedure TKEZIADATPOTLASFORM.PENZTARZAROGOMBClick(Sender: TObject);
begin
  ModalResult := 3;
end;

procedure TKEZIADATPOTLASFORM.MANUALISGOMBClick(Sender: TObject);
begin
  PotMenuPanel.Visible := False;
  Activecontrol := P1Gomb;
end;

procedure TKEZIADATPOTLASFORM.P1GOMBClick(Sender: TObject);
begin
   CimletezoForm.Showmodal;
   PotlasOkeGomb.Visible := true;
   ActiveControl := p2Gomb;
end;

procedure TKEZIADATPOTLASFORM.P2GOMBClick(Sender: TObject);

var _ufoke: integer;

begin
  _ufoke := UgyfelforgalomPotlo.ShowModal;
  if _ufoke<>1 then exit;
  PotlasOkeGomb.Visible := true;
  ActiveControl := potlasOkeGomb;
end;

procedure TKEZIADATPOTLASFORM.POTLASOKEGOMBClick(Sender: TObject);
begin
  ModalResult := 1; 
end;

end.
