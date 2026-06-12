unit Unit18;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, unit1, StrUtils;

type
  TGETUZLETSZAM = class(TForm)
    FOMENUPANEL: TPanel;
    BESTCHANGEGOMB: TBitBtn;
    ERTEKTARAKGOMB: TBitBtn;
    PENZTARAKGOMB: TBitBtn;
    ERTEKTARPANEL: TPanel;
    Label1: TLabel;
    PENZTARPANEL: TPanel;
    ERTEKTARCANCELGOMB: TBitBtn;
    PENZTARCANCELGOMB: TBitBtn;
    megsemgomb: TBitBtn;
    ERTEKTARLIST: TListBox;
    PENZTARLIST: TListBox;
    Label2: TLabel;
    Shape3: TShape;
    Shape2: TShape;
    SHAPE4: TShape;
    Shape1: TShape;
    Label3: TLabel;
    VALASZTOGOMB: TBitBtn;
    EXCELSHAPE: TShape;
    EXCELGOMB: TBitBtn;
    BitBtn1: TBitBtn;
    Shape5: TShape;
    Shape6: TShape;
    Shape7: TShape;
    Shape8: TShape;
    Shape9: TShape;
    Shape10: TShape;
    BESTGOMB: TBitBtn;
    PANNONGOMB: TBitBtn;
    EASTGOMB: TBitBtn;
    Shape11: TShape;
    BitBtn2: TBitBtn;

    procedure FormActivate(Sender: TObject);
    procedure BESTCHANGEGOMBClick(Sender: TObject);
    procedure ERTEKTARAKGOMBClick(Sender: TObject);
    procedure megsemgombClick(Sender: TObject);
    procedure PENZTARAKGOMBClick(Sender: TObject);
 
    function Kibovit(_pp:integer): string;
    procedure BESTCHANGEGOMBEnter(Sender: TObject);
    procedure BESTCHANGEGOMBExit(Sender: TObject);
    procedure PENZTARLISTDblClick(Sender: TObject);
    procedure ERTEKTARLISTDblClick(Sender: TObject);
    procedure ERTEKTARLISTKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure PENZTARLISTKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure BESTCHANGEGOMBMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure VALASZTOGOMBClick(Sender: TObject);
    procedure VALASZTOGOMBEnter(Sender: TObject);
    procedure VALASZTOGOMBExit(Sender: TObject);
    procedure EXCELGOMBClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BESTGOMBClick(Sender: TObject);
    procedure PANNONGOMBClick(Sender: TObject);
    procedure EASTGOMBClick(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GETUZLETSZAM: TGETUZLETSZAM;
  _PENZTARINDEX: integer;
  
implementation

uses Unit6;

{$R *.dfm}

procedure TGETUZLETSZAM.mEGSEMGOMBClick(Sender: TObject);
begin
  Modalresult := 1;
end;

procedure TGETUZLETSZAM.FormActivate(Sender: TObject);

var i,_ptsz: integer;
    _aktItem: string;

begin
  tOP := _TOP + 123;
  Left := _left + 143;
  hEIGHT := 524;
  Width := 744;

  ErtekTarPanel.Visible := False;
  PenztarPanel.Visible := False;

  excelshape.Visible := _kellExcel;
  excelgomb.Visible := _kellexcel;


  ErtekTarList.Clear;
  for i := 0 to _ertekTarDArab-1 do ErtekTarList.Items.Add(_korzetnev[i]);
  ErtekTarList.ItemIndex := 0;

  PenztarList.Clear;
  for i := 0 to _irodadarab-1 do
    begin
      _ptsz := _irodaszam[i];
      _aktitem := kibovit(_ptsz)+'-'+_irodanev[_ptsz];
      PenztarList.Items.Add(_aktitem);
    end;

  PenztarList.ItemIndex := 0;

  with FomenuPanel do
    begin
      Top := 90;
      Left := 130;
      Visible := true;
    end;
  ActiveControl := BestChangeGomb;
end;

function TGetUzletszam.Kibovit(_pp:integer): string;

begin
  result := inttostr(_pp);
  while length(result)<3 do result := ' '+result;
end;



procedure TGETUZLETSZAM.BESTCHANGEGOMBClick(Sender: TObject);
begin
  Modalresult := 2;
end;

procedure TGETUZLETSZAM.ERTEKTARAKGOMBClick(Sender: TObject);
begin
  FomenuPanel.Visible := False;
  with ertekTarpanel do
    begin
      Top := 100;
      Left := 250;
      Visible := true;
    end;
  ActiveControl := ertekTarList;
  ErtektarList.SetFocus;
end;


procedure TGETUZLETSZAM.PENZTARAKGOMBClick(Sender: TObject);
begin
  FomenuPanel.Visible := False;
  with PenztarPanel do
    begin
      Top := 40;
      Left := 220;
      Visible := true;
    end;
  ActiveControl := PenztarList;
  PenztarList.SetFocus;
end;

procedure TGETUZLETSZAM.BESTCHANGEGOMBEnter(Sender: TObject);
begin
  with TBitBtn(sender).Font do
    begin
      Color := clRed;
      style := [fsBold,fsItalic];
      size := 12;
    end;
end;

procedure TGETUZLETSZAM.BESTCHANGEGOMBExit(Sender: TObject);
begin
  with TBitBtn(sender).Font do
    begin
      Color := clGray;
      style := [];
      size := 10;
    end;
end;

procedure TGETUZLETSZAM.PENZTARLISTDblClick(Sender: TObject);

begin
   _penztarIndex := PenztarList.ItemIndex;
  _aktPenztarnev := PenztarList.Items[_penztarindex];
  _aktpenztar := strtoint(leftstr(_aktpenztarnev,3));
  ModalResult := _aktpenztar+3;
end;

procedure TGETUZLETSZAM.ERTEKTARLISTDblClick(Sender: TObject);
var _etarIndex: integer;
begin
  _etarindex := ErtektarList.itemindex;
  _aktkorzet := _korzetszam[_etarIndex];
  _aktkorzetnev := _korzetnev[_etarIndex];
  Modalresult := 3;
end;

procedure TGETUZLETSZAM.ERTEKTARLISTKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var _etarIndex: integer;
begin
  if ord(key)<>13 then exit;
  _etarindex := ErtektarList.itemindex;
  _aktkorzet := _korzetszam[_etarIndex];
  _aktkorzetnev := _korzetnev[_etarIndex];
  Modalresult := 3;
end;

procedure TGETUZLETSZAM.PENZTARLISTKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var _penztarIndex: integer;  
begin
  if ord(key)<>13 then exit;
   _penztarIndex := PenztarList.ItemIndex;
  _aktPenztarnev := PenztarList.Items[_penztarindex];
  _aktpenztar := strtoint(leftstr(_aktpenztarnev,3));
  ModalResult := _aktpenztar+3;
end;

procedure TGETUZLETSZAM.BESTCHANGEGOMBMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  ActiveControl := TBitbtn(Sender);
end;

procedure TGETUZLETSZAM.VALASZTOGOMBClick(Sender: TObject);
var _etarindex : integer;
begin
  _etarindex := ErtektarList.itemindex;
  _aktkorzet := _korzetszam[_etarIndex];
  _aktkorzetnev := _korzetnev[_etarIndex];
  Modalresult := 3;
end;

procedure TGETUZLETSZAM.VALASZTOGOMBEnter(Sender: TObject);
begin
  with Tbitbtn(sender).Font do
    begin
      Color := clRed;
      styLe := [fsBold];
    end;
end;

procedure TGETUZLETSZAM.VALASZTOGOMBExit(Sender: TObject);
begin
  with Tbitbtn(sender).Font do
    begin
      Color := clBlack;
      styLe := [];
    end;
end;

procedure TGETUZLETSZAM.EXCELGOMBClick(Sender: TObject);
begin
  MNBListak.MakeExcelCsv;
end;

procedure TGETUZLETSZAM.BitBtn1Click(Sender: TObject);

begin
   _penztarIndex := PenztarList.ItemIndex;
  _aktPenztarnev := PenztarList.Items[_penztarindex];
  _aktpenztar := strtoint(leftstr(_aktpenztarnev,3));
  ModalResult := _aktpenztar+3;
end;



procedure TGETUZLETSZAM.BESTGOMBClick(Sender: TObject);
begin
  Modalresult := -1;
end;

procedure TGETUZLETSZAM.PANNONGOMBClick(Sender: TObject);
begin
  Modalresult := -2;
end;

procedure TGETUZLETSZAM.EASTGOMBClick(Sender: TObject);
begin
  ModalResult := -3;
end;

procedure TGETUZLETSZAM.BitBtn2Click(Sender: TObject);
begin
  ModalResult := -4;
end;

end.
