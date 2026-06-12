unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, DBTables, StdCtrls, ExtCtrls, unit1, Buttons, IBDatabase,
  IBCustomDataSet, IBTable, IBQuery;

type
  TRENDSZERADATOK = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    BANKJELBOX: TComboBox;
    VISSZAGOMB: TButton;
    NEVEDIT: TEdit;
    IDEDIT: TEdit;
    PWEDIT: TEdit;
    rogzitogomb: TBitBtn;
    UJBANKJEL: TEdit;
    ujlabel: TLabel;
    RENDSZERTABLA: TIBTable;
    RENDSZERDBASE: TIBDatabase;
    RENDSZERTRANZ: TIBTransaction;
    RENDSZERQUERY: TIBQuery;
    Label4: TLabel;
    Label6: TLabel;
    NEVEDIT1: TEdit;
    IDEDIT1: TEdit;
    NEVEDIT2: TEdit;
    IDEDIT2: TEdit;
    Label2: TLabel;
    Label7: TLabel;
    Shape1: TShape;
    NEVEDIT3: TEdit;
    IDEDIT3: TEdit;
    Label8: TLabel;
    procedure FormActivate(Sender: TObject);
    procedure NEVEDITEnter(Sender: TObject);
    procedure NEVEDITExit(Sender: TObject);
    procedure UJBANKJELKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure rogzitogombClick(Sender: TObject);
   
    procedure VISSZAGOMBClick(Sender: TObject);
    procedure NEVEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
   
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  RENDSZERADATOK: TRENDSZERADATOK;

  _BjDb: integer;
  _ujbankjel: boolean;

implementation

{$R *.dfm}

procedure TRENDSZERADATOK.FormActivate(Sender: TObject);
var i: integer;
begin
  top := _top+350;
  left := _left+210;
  _ujbankJel := False;
  RogzitoGomb.Font.Color := clGray;
  RogzitoGomb.Enabled := False;

  Form1.RendszerAdatBeolvasas;

  NevEDit.Text  := _valtonev[1];
  NevEDit1.Text := _valtonev[2];
  NevEDit2.Text := _valtonev[3];
  Nevedit3.Text := _valtoNev[4];


  Idedit.Text  := _azonosito[1];
  Idedit1.Text := _azonosito[2];
  Idedit2.Text := _azonosito[3];
  IdEdit3.Text := _azonosito[4];

  BankJelBox.Clear;
  _BJdb := 0;

  for i := 1 to 9 do
    begin
      Bankjelbox.Items.Add(_bankjel[i]);
      if _bankjel[i]='' then
        begin
          _bjdb := i-1;
          break;
        end;
    end;
  if _bjdb=9 then
    begin
      Ujbankjel.Enabled := fALSE;
      Ujlabel.Enabled := False;
    end;

  BankjelBox.Text := _bankjel[1];
  Pwedit.Text := _jelszo;
  ActiveControl := VisszaGomb;
end;



procedure TRENDSZERADATOK.NEVEDITEnter(Sender: TObject);
begin
  TEdit(sender).Color := clYellow;
end;

procedure TRENDSZERADATOK.NEVEDITExit(Sender: TObject);
begin
  TEdit(Sender).Color := clWindow;
  RogzitoGomb.Font.Color := clBlue;
  RogzitoGomb.Enabled := True;
end;

procedure TRENDSZERADATOK.UJBANKJELKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var i:integer;
   _ujkod: string;
begin
  if ord(key)<>13 then exit;
  _ujkod := Ujbankjel.Text;
  if _ujkod='' then exit;
  inc(_bjDb);
  IF _bjdb=9 then
    begin
      Ujbankjel.enabled := false;
      Ujlabel.Enabled := false;
    end;
  _ujBankjel := True;
  _bankjel[_bjdb] := _ujkod;
  BankJelBox.Clear;
  for i := 1 to 9 do
      Bankjelbox.Items.Add(_bankjel[i]);
      
  Ujbankjel.Clear;
  RogzitoGomb.Enabled := true;
  ActiveControl := Rogzitogomb;
end;

// =============================================================================
           procedure TRENDSZERADATOK.rogzitogombClick(Sender: TObject);
// =============================================================================


var z: integer;
    _mezonev: string;
begin

  _valtoNev[1] := trim(Nevedit.Text);
  _valtoNev[2] := trim(Nevedit1.Text);
  _valtoNev[3] := trim(Nevedit2.Text);
  _valtoNev[4] := trim(Nevedit3.Text);


  _azonosito[1]  := trim(Idedit.Text);
  _azonosito[2]  := trim(Idedit1.Text);
  _azonosito[3]  := trim(Idedit2.Text);
  _azonosito[4]  := trim(Idedit3.Text);

  _jelszo := trim(pwedit.text);

  RendszerDbase.Connected := True;
  if RendszerTranz.InTransaction then Rendszertranz.Commit;
  RendszerTranz.StartTransaction;

  _pcs := 'UPDATE RENDSZER SET AZONOSITO='+ chr(39) + _azonosito[1] + chr(39) + ',';

  _pcs := _pcs + 'AZONOSITO1='+chr(39)+_azonosito[2]+chr(39)+',';
  _pcs := _pcs + 'AZONOSITO2='+chr(39)+_azonosito[3]+chr(39)+',';
  _pcs := _pcs + 'AZONOSITO3='+chr(39)+_azonosito[4]+chr(39)+',';
  _pcs := _pcs + 'VALTONEV=' + chr(39) +_valtonev[1]+chr(39)+',';
  _pcs := _pcs + 'VALTONEV1='+ chr(39)+_valtonev[2]+chr(39)+',';
  _pcs := _pcs + 'VALTONEV2='+ chr(39)+_valtonev[3]+chr(39)+',';
  _pcs := _pcs + 'VALTONEV3='+ chr(39)+_valtonev[4]+chr(39)+',';
  _pcs := _pcs + 'JELSZO='+ chr(39) + _jelszo + chr(39) + ',';

  for z := 1 to 8 do
    begin
      _mezonev := 'BANKFK'+chr(48+z);
      _pcs := _pcs + _mezonev+'='+chr(39)+_bankjel[z]+chr(39)+',';
    end;
  _pcs := _pcs + 'BANKFK9='+chr(39)+_bankjel[9]+chr(39);

  with RendszerQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Execsql;
    end;
  RendszerTranz.Commit;
  rendszerDbase.close;
  Form1.RendszerAdatBeolvasas;
  ModalResult := 1;
end;


procedure TRENDSZERADATOK.VISSZAGOMBClick(Sender: TObject);
begin
  ModalResult := 2;
end;

procedure TRENDSZERADATOK.NEVEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  RogzitoGomb.enabled := True;
  ActiveControl := Rogzitogomb;
end;



end.
