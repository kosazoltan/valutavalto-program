unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DB;

type
  TREKORDTORLOFORM = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    TOROLDGOMB: TBitBtn;
    NETOROLDGOMB: TBitBtn;
    procedure FormActivate(Sender: TObject);
    procedure NETOROLDGOMBClick(Sender: TObject);
    procedure TOROLDGOMBEnter(Sender: TObject);
    procedure TOROLDGOMBExit(Sender: TObject);
    procedure TOROLDGOMBClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  REKORDTORLOFORM: TREKORDTORLOFORM;

implementation

uses Unit1;

{$R *.dfm}

procedure TREKORDTORLOFORM.FormActivate(Sender: TObject);
begin
   Top := _TOP+ 460;
  Left := _LEFT + 350;
  ActiveControl := NeToroldGomb;
end;

procedure TREKORDTORLOFORM.NETOROLDGOMBClick(Sender: TObject);
begin
  ModalResult := 2;
end;

procedure TREKORDTORLOFORM.TOROLDGOMBEnter(Sender: TObject);
begin
  TBitBtn(Sender).Font.color := clMaroon;
  TBitBtn(Sender).Font.Style := [fsBold];
end;



procedure TREKORDTORLOFORM.TOROLDGOMBExit(Sender: TObject);
begin
  TBitBtn(Sender).Font.color := clGray;
  TBitBtn(Sender).Font.Style := [];
end;

procedure TREKORDTORLOFORM.TOROLDGOMBClick(Sender: TObject);
var _delRekord: TBookMark;
begin
  if not Form1.IbTabla.active then exit;
  _delRekord := Form1.IBtabla.GetBookmark;
  Form1.IbTabla.close;
  Form1.IbTabla.readOnly := False;

  Form1.IBDBASE.close;
  Form1.IBDBASE.Connected := True;
  if Form1.ibTranz.intransaction then Form1.ibTranz.commit;
  Form1.ibTranz.StartTransAction;

  Form1.ibTabla.Open;
  Form1.ibTabla.GotoBookMark(_delRekord);
  Form1.ibTabla.Edit;
  Form1.ibTabla.Delete;
  
  Form1.ibTabla.freeBookMark(_delRekord);
  Form1.ibTabla.Close;

  Form1.IbTranz.commit;

  Form1.ibTabla.ReadOnly := True;
  Form1.ibTabla.Open;
  Form1.ibtabla.first;
  Form1.IbTabla.Refresh;
  ModalResult := 1;
end;

end.
