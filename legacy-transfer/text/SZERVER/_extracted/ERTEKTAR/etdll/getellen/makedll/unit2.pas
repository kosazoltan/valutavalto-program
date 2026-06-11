unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB,
  IBCustomDataSet, IBQuery;

type
  TGETELLENOR = class(TForm)
    Label1: TLabel;
    BEOEDIT: TEdit;
    Label2: TLabel;
    RENDBENGOMB: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    Label3: TLabel;
    Shape1: TShape;
    VALQUERY: TIBQuery;
    VALDBASE: TIBDatabase;
    VALTRANZ: TIBTransaction;
    NEVEDIT: TEdit;

    procedure FormActivate(Sender: TObject);
    procedure NEVEDITEnter(Sender: TObject);
    procedure NEVEDITExit(Sender: TObject);

    procedure BEOEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure RENDBENGOMBClick(Sender: TObject);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);
  
    procedure NEVEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
   
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GETELLENOR: TGETELLENOR;
  _top,_left,_width,_height: word;
  _pcs,_prosbeo,_prosnev: string;

  _sorveg: string = chr(13)+chr(10);


function getellenorrutin: integer; stdcall;

implementation

{$R *.dfm}


function getellenorrutin: integer; stdcall;
begin
  GetEllenor := TGetEllenor.Create(Nil);
  result := Getellenor.ShowModal;
  Getellenor.Free;
end;  



procedure TGETELLENOR.FormActivate(Sender: TObject);
begin
  _height     := Screen.Monitors[0].Height;
  _width     := Screen.Monitors[0].Width;

  _top := 0;
  _left := 0;

  if (_height>768) or (_width>1024) then
    begin
      _top := trunc((_height-768)/2);
      _left := trunc((_width-1024)/2);
    end;

  Top := _Top + 100;
  Left := _left + 220;

  Nevedit.clear;
  Beoedit.clear;
  RendbenGomb.Enabled := False;

  ActiveControl := NevEdit;
end;

procedure TGETELLENOR.NEVEDITEnter(Sender: TObject);
begin
  TEdit(sender).Color := clYellow;
end;

procedure TGETELLENOR.NEVEDITExit(Sender: TObject);
begin
  TEdit(sender).Color := clWindow;
end;


procedure TGETELLENOR.MEGSEMGOMBClick(Sender: TObject);
begin
  ModalResult := 2;
end;


procedure TGetEllenor.ValutaParancs(_ukaz: string);

begin
  valdbase.connected := true;
  if valtranz.InTransaction then valtranz.Commit;
  Valtranz.StartTransaction;

  with valquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Valtranz.commit;
  Valdbase.close;
end;

procedure TGETELLENOR.NEVEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  If ord(key)<>13 then exit;
  _prosnev := trim(Nevedit.Text);
  if _prosnev='' then exit;
  Activecontrol := Beoedit;
end;

procedure TGetEllenor.BeoEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

begin
  if ord(key)<>13 then exit;
  _prosbeo := trim(Beoedit.text);
  if _prosbeo='' then exit;

  Rendbengomb.enabled := true;
  ActiveControl := RendbenGomb;
end;


procedure TGETELLENOR.RENDBENGOMBClick(Sender: TObject);
begin

  _pcs := 'UPDATE VTEMP SET ELLENORNEV=' + chr(39)+ _prosnev + chr(39);
  _pcs := _pcs + ',ELLENORBEO=' + chr(39) + _prosbeo + chr(39);
  ValutaParancs(_pcs);
  ModalResult := 1;
end;


end.
