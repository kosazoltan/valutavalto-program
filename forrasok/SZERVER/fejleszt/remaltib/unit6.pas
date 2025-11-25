unit Unit6;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, StrUtils, ExtCtrls;

type
  TMEZOTOLTOFORM = class(TForm)
    Label1: TLabel;
    Panel1: TPanel;
    Label3: TLabel;
    Label5: TLabel;
    Label2: TLabel;
    FILLMEZOCOMBO: TComboBox;
    TIPINFOLABEL: TLabel;
    ILABEL: TLabel;
    FILLEDIT: TEdit;
    TOLTESGOMB: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    procedure FormActivate(Sender: TObject);
    procedure FILLMEZOCOMBOChange(Sender: TObject);
    procedure FILLEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure TOLTESGOMBClick(Sender: TObject);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure TOLTESGOMBEnter(Sender: TObject);
    procedure TOLTESGOMBExit(Sender: TObject);
    procedure FILLEDITEnter(Sender: TObject);
    procedure FILLEDITExit(Sender: TObject);
    procedure FILLMEZOCOMBOEnter(Sender: TObject);
    procedure FILLMEZOCOMBOExit(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MEZOTOLTOFORM: TMEZOTOLTOFORM;
  _fmIndex: integer;
  _aktmezo,_aktTipus,_tip,_tolto: string;
  _aktHossz: integer;

implementation

uses Unit1;

{$R *.dfm}

procedure TMEZOTOLTOFORM.FormActivate(Sender: TObject);

var i: integer;

begin
  tOP := _TOP+200;
  LEFT := _left + 390;
  
  FillEdit.Clear;
  FillMezoCombo.Clear;
  for i := 1 to _mezoDarab do FillmezoCombo.Items.Add(_mezonev[i]);

  FillmezoCombo.ItemIndex := -1;
  ActiveControl := FillMezoCombo;
end;

procedure TMEZOTOLTOFORM.FILLMEZOCOMBOChange(Sender: TObject);
begin
  _fmIndex := (FillMezoCOmbo.Itemindex)+1;
  if _fmIndex = 0 then exit;

  _aktmezo := _mezonev[_fmIndex];
  _akthossz := _mezoHossz[_fmIndex];
  _akttipus := _mezoTipus[_fmIndex];

  if _akttipus='SZÖVEG' then
    begin
      Filledit.Left := 88;
      FillEdit.Width := 281;
      TipInfoLabel.Caption := 'A VÁLASZTOTT MEZÕ EGY SZÖVEGES ADAT';
      ILabel.Left := 80;
      ILabel.Caption := 'A MEZÕ FELTÖLTÉSE (TÖRLÉSE)AZ ALÁBBI SZÖVEGGEL';
      _tip := 'C';
    end else
    begin
      Filledit.Left := 150;
      FillEdit.Width := 145;
      TipInfoLabel.Caption := '   A VÁLASZTOTT MEZÕ EGY SZÁM ADAT';
      ILabel.Left := 120;
      ILabel.Caption := 'A MEZÕ FELTÖLTÉSE AZ ALÁBBI SZÁMMAL';
      _tip := 'N';
    end;

  Filledit.Clear;
  ActiveControl := Filledit;
end;

procedure TMEZOTOLTOFORM.FILLEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  Activecontrol := ToltesGomb;
end;

procedure TMEZOTOLTOFORM.TOLTESGOMBClick(Sender: TObject);
var _lt: integer;
begin
  _fmIndex := FillMezoCombo.ItemIndex;
  if _fmIndex = -1 then exit;
  _tolto := Filledit.text;
  if (_tip='C') then
    begin
      _lt := length(_tolto);
      if _LT>_akthossz then _tolto := Leftstr(_tolto,_akthossz);
    end;
  if (_tip='N') then
    begin
      val(_tolto,_float,_code);
      if _code<>0 then _float := 0;
      _tolto := floattostr(_float);
    end;

  Form1.Ibdbase.close;
  Form1.IBtabla.readOnly := False;
  Form1.IBDbase.connected := True;
  if Form1.IbTranz.intransaction then Form1.IbTranz.commit;
  Form1.IBTranz.startTransaction;

  Form1.IBtabla.Open;
  while not Form1.IBtabla.eof do
    begin
      with Form1.IBTABLA do
        begin
          Edit;
          FieldByName(_aktmezo).asstring := _tolto;
          Post;
          Next;
        end;
    end;
  Form1.IBTRANZ.Commit;

  Form1.IBDBASE.close;
  Form1.IBTABLA.ReadOnly := True;
  Form1.Ibdbase.Connected := true;
  Form1.IBTABLA.Open;
  Form1.IBTABLA.Refresh;
  Form1.IBTABLA.First;
  ModalResult := 1;
end;


procedure TMEZOTOLTOFORM.MEGSEMGOMBClick(Sender: TObject);
begin
  Modalresult := 2;
end;

procedure TMEZOTOLTOFORM.TOLTESGOMBEnter(Sender: TObject);
begin
  TBitbtn(sender).Font.color := clBlue;
  TBitBtn(sender).Font.Style := [fsBold];
end;

procedure TMEZOTOLTOFORM.TOLTESGOMBExit(Sender: TObject);
begin
   TBitbtn(sender).font.color := clGray;
  TBitBtn(sender).Font.Style := [];
end;

procedure TMEZOTOLTOFORM.FILLEDITEnter(Sender: TObject);
begin
  Filledit.Color := clAqua;
end;

procedure TMEZOTOLTOFORM.FILLEDITExit(Sender: TObject);
begin
  Filledit.Color := clWindow;
end;

procedure TMEZOTOLTOFORM.FILLMEZOCOMBOEnter(Sender: TObject);
begin
  FillMezocombo.Color := clAqua;
end;

procedure TMEZOTOLTOFORM.FILLMEZOCOMBOExit(Sender: TObject);
begin
  FillMezocombo.Color := clWindow;
end;

end.
