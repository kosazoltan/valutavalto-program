unit Unit9;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet,
  IBQuery, unit1;

type
  TGETTANUSITVANY = class(TForm)

    Panel1        : TPanel;

    Label1        : TLabel;
    Label2        : TLabel;
    Label3        : TLabel;
    Label4        : TLabel;

    TerminalIdEdit: TEdit;
    UserNameEdit  : TEdit;
    PasswordEdit  : TEdit;

    DataOkeGomb   : TBitBtn;
    CancelGomb    : TBitBtn;

    IbQuery       : TIBQuery;
    IbDbase       : TIBDatabase;
    IbTranz       : TIBTransaction;

    Shape1        : TShape;

    procedure CancelgombClick(Sender: TObject);
    procedure DataokegombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure PasswordEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TerminalIdEditEnter(Sender: TObject);
    procedure TerminalIdEditExit(Sender: TObject);
    procedure TerminalIdEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure UserNameEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GetTanusitvany: TGetTanusitvany;

implementation

{$R *.dfm}

// =============================================================================
          procedure TGetTanusitvany.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top  := _top + 264;
  Left := _left + 224;

  TerminalIdEdit.text := _terminalid;
  UserNameEdit.Text   := _username;
  PasswordEdit.text   := _password;

  ActiveControl       := TerminalIdedit;
end;

// =============================================================================
         procedure TGetTanusitvany.CancelGombClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 2;
end;

// =============================================================================
          procedure TGetTanusitvany.DataOkeGombClick(Sender: TObject);
// =============================================================================

begin
  _terminalid := trim(TerminalIdedit.Text);
  _username   := trim(UserNameEdit.Text);
  _password   := Trim(PasswordEdit.Text);

  if length(_terminalId)<>4 then
    begin
      ActiveControl :=  TerminalIdedit;
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

// =============================================================================
        procedure TGETTANUSITVANY.TERMINALIDEDITEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := $B0FFFF;
end;

// =============================================================================
          procedure TGETTANUSITVANY.TERMINALIDEDITExit(Sender: TObject);
// =============================================================================

begin
  tEDIT(Sender).Color := clWindow;
end;

// =============================================================================
       procedure TGETTANUSITVANY.TERMINALIDEDITKeyDown(Sender: TObject;
                                            var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  if ord(Key)<>13 then exit;
  ActiveControl := UsernameEdit;
end;

// =============================================================================
         procedure TGETTANUSITVANY.USERNAMEEDITKeyDown(Sender: TObject;
                                            var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Activecontrol := Passwordedit;
end;

// =============================================================================
         procedure TGETTANUSITVANY.PASSWORDEDITKeyDown(Sender: TObject;
                                          var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  ActiveControl := DataOkeGomb;
end;

end.
