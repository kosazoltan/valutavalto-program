unit Unit9;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet,
  IBQuery, unit1;

type
  TGETTANUSITVANY = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    TERMINALIDEDIT: TEdit;
    USERNAMEEDIT: TEdit;
    PASSWORDEDIT: TEdit;
    dataokegomb: TBitBtn;
    cancelgomb: TBitBtn;
    IBQuery: TIBQuery;
    IBDbase: TIBDatabase;
    IBTranz: TIBTransaction;
    Shape1: TShape;
    procedure FormActivate(Sender: TObject);
    procedure cancelgombClick(Sender: TObject);
    procedure dataokegombClick(Sender: TObject);
    procedure TERMINALIDEDITEnter(Sender: TObject);
    procedure TERMINALIDEDITExit(Sender: TObject);
    procedure TERMINALIDEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure USERNAMEEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure PASSWORDEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GETTANUSITVANY: TGETTANUSITVANY;

implementation

{$R *.dfm}

procedure TGETTANUSITVANY.FormActivate(Sender: TObject);
begin
  tOP := _TOP+264;
  Left := _LEFT + 224;
  terminalidedit.text := _terminalid;
  usernameedit.Text := _username;
  passwordedit.text := _password;
  Activecontrol := terminalidedit;
end;



procedure TGETTANUSITVANY.cancelgombClick(Sender: TObject);
begin
  ModalResult := 2;
end;

procedure TGETTANUSITVANY.dataokegombClick(Sender: TObject);
begin
  _terminalid := trim(TerminalIdedit.text);
  _username := trim(UsernameEdit.Text);
  _password := Trim(Passwordedit.Text);

  if length(_terminalId)<>4 then
    begin
      ActiveControl :=  Terminalidedit;
      exit;
    end;

  if length(_username)<4 then
    begin
      ActiveControl := Usernameedit;
      exit;
    end;

  if length(_password)<4 then
    begin
      Activecontrol := PasswordEdit;
      Exit;
    end;

  ibdbase.Connected := true;
  if ibtranz.InTransaction then ibtranz.Commit;
  ibtranz.StartTransaction;

  _pcs := 'UPDATE PARAMETERS SET TERMINALID='+chr(39)+_terminalid+chr(39)+',';
  _pcs := _pcs + 'USERNAME='+chr(39)+_username+chr(39)+',';
  _PCS := _pcs + 'JELSZO=' + chr(39)+_password + chr(39);

  with IbQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;
  ibTranz.commit;
  ibdbase.close;
  ModalResult := 1;
end;

procedure TGETTANUSITVANY.TERMINALIDEDITEnter(Sender: TObject);
begin
  Tedit(sender).Color := $B0FFFF;
end;

procedure TGETTANUSITVANY.TERMINALIDEDITExit(Sender: TObject);
begin
  tEDIT(Sender).Color := clWindow;
end;

procedure TGETTANUSITVANY.TERMINALIDEDITKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if ord(Key)<>13 then exit;
  ActiveControl := UsernameEdit; 
end;

procedure TGETTANUSITVANY.USERNAMEEDITKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  Activecontrol := Passwordedit;
end;

procedure TGETTANUSITVANY.PASSWORDEDITKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  ActiveControl := DataOkeGomb;
end;

end.
