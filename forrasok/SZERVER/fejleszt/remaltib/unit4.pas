unit Unit4;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  TZAPPOLOFORM = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    ADATBAZISNEVPANEL: TPanel;
    Label2: TLabel;
    TORLESOKEGOMB: TBitBtn;
    NEMTORLOKGOMB: TBitBtn;
    procedure TORLESOKEGOMBEnter(Sender: TObject);
    procedure TORLESOKEGOMBExit(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure NEMTORLOKGOMBClick(Sender: TObject);
    procedure TORLESOKEGOMBClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ZAPPOLOFORM: TZAPPOLOFORM;

implementation

uses Unit1;

{$R *.dfm}

procedure TZAPPOLOFORM.TORLESOKEGOMBEnter(Sender: TObject);
begin
  TBitBtn(sender).Font.color := clBlue;
  TBitBtn(Sender).Font.Style := [fsBold];
end;

procedure TZAPPOLOFORM.TORLESOKEGOMBExit(Sender: TObject);
begin
  TBitbtn(Sender).Font.Color := clGray;
  TBitBtn(Sender).Font.Style := [];
end;

procedure TZAPPOLOFORM.FormActivate(Sender: TObject);
begin
  tOP := _top + 350;
  Left := _left + 290;
  AdatbazisNevPanel.Caption := _aktTablaNev;
  ActiveControl := NemtorlokGomb;
end;

procedure TZAPPOLOFORM.NEMTORLOKGOMBClick(Sender: TObject);
begin
  ModalResult := 2;
end;

procedure TZAPPOLOFORM.TORLESOKEGOMBClick(Sender: TObject);
begin
  Form1.IBdbase.close;
  Form1.IBdbase.connected := True;
  if Form1.Ibtranz.intransaction then Form1.ibTranz.commit;
  Form1.IBTRANZ.StartTransaction;

  Form1.ibtabla.Open;
  Form1.IBTABLA.EmptyTable;
  Form1.IBTABLA.Refresh;
  ModalResult := 1;
end;

end.
