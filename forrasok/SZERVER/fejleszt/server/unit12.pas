unit Unit12;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, DBTables, Grids, DBGrids, ExtCtrls, StdCtrls, Buttons,Unit1,
  StrUtils, IBDatabase, IBCustomDataSet, IBTable, IBQuery;

type
  TUSERFORM = class(TForm)
    USERVALPANEL: TPanel;
    USERRACS: TDBGrid;
    USERSOURCE: TDataSource;
    MEGSEMGOMB: TBitBtn;
    PWBEKEROPANEL: TPanel;
    USERNEVPANEL: TPanel;
    JELSZOPANEL: TPanel;
    Label1: TLabel;
    JELSZOEDIT: TEdit;
    kismenupanel: TPanel;
    mg1: TBitBtn;
    MG2: TBitBtn;
    MG3: TBitBtn;
    MG4: TBitBtn;
    USERPANEL: TPanel;
    Label2: TLabel;
    NEVEDIT: TEdit;
    Label3: TLabel;
    JELSZO1EDIT: TEdit;
    JELSZO2EDIT: TEdit;
    Label4: TLabel;
    KONFIRMGOMB: TBitBtn;
    USERTABLA: TIBTable;
    USERDBASE: TIBDatabase;
    USERTRANZ: TIBTransaction;
    USERQUERY: TIBQuery;
    Shape1: TShape;
    Shape2: TShape;
    Shape3: TShape;
    Shape4: TShape;
    Shape5: TShape;
    Shape6: TShape;

    procedure FormActivate(Sender: TObject);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure UserValasztas;
    procedure USERRACSKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure JELSZOEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure mg1Enter(Sender: TObject);
    procedure mg1Exit(Sender: TObject);
    procedure mg1Click(Sender: TObject);
    procedure MG2Click(Sender: TObject);
    procedure NEVEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure JELSZO1EDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure JELSZO2EDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure KONFIRMGOMBClick(Sender: TObject);
    procedure MG4Click(Sender: TObject);
    procedure Kivalasztas(Sender: TObject);
    function Kodol(_natstr: string): string;
    function Dekodol(_kodstr: string): string;
    procedure MG3Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  USERFORM: TUSERFORM;
  _kodoltPw,_ujUsernev,_pw1,_pw2,_usernev: string;
  _ujUser,_TORLES: boolean;

implementation

{$R *.dfm}

// =========================================================
       procedure TUSERFORM.FormActivate(Sender: TObject);
// =========================================================

begin
   Top := _top +340;
  Left := _left +290;

      UserPanel.Visible := False;
   KismenuPanel.Visible := false;
  PWBekeroPanel.Visible := False;
                _ujUser := False;
                _TORLES := False;

  UserDbase.Close;
  UserDbase.Connected := true;

  UserTabla.Open;
  UserTabla.Refresh;
  UserTabla.First;
  UserValasztas;
  
end;

// =======================================
      procedure TUserForm.UserValasztas;
// =======================================

begin
  with UserValpanel do
    begin
      Left := 0;
      Top := 0;
      Visible := true
    end;

  Userracs.SelectedIndex := 0;
  ActiveControl := UserRacs;
  Userracs.SetFocus;
end;

procedure TUSERFORM.MEGSEMGOMBClick(Sender: TObject);
begin
  UserTabla.Close;
  Modalresult := 2;
end;

procedure TUSERFORM.USERRACSKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);

begin
  if ord(key)<>13 then exit;
  if _torles then
    begin
      _usernev := UserTabla.FieldByName('USERS').asstring;
      UserTabla.delete;
      UserTranz.commit;
      ShowMessage(trim(_usernev) + ' törölve !');
      _torles := False;
      ModalResult := 1;
      exit;
    end;

  Kivalasztas(UserRacs);
end;

// =======================================================
       procedure TUserForm.Kivalasztas(Sender: TObject);
// =======================================================

begin
  _usernev := UserTabla.FieldByName('USERS').asstring;
  _kodoltpw := UserTabla.FieldByName('HEXAPASSWORD').asstring;
  _kodoltPw := trim(_kodoltPw);
  UserNevPanel.Caption := _usernev;
  JelszoEdit.Clear;
  JelszoPanel.Visible := True;
  with PwBekeroPanel do
    begin
      Top := 0;
      Left := 0;
      Visible := True;
    end;
  
  ActiveControl := Jelszoedit;
end;

procedure TUSERFORM.JELSZOEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var _injelszo,_jojelszo: string;
begin
  if ord(key)<>13 then exit;
  _injelszo := Jelszoedit.Text;

  if _injelszo='' then exit;
  _JoJelszo := UPPERCASE(Dekodol(_kodoltpw));

  if _jojelszo<>_injelszo then
    begin
      ShowMessage('A JELSZÓ NEM MEGFELELÕ');
      Beep;
      JelszoEdit.Clear;
      ActiveControl := Jelszoedit;
      Exit;
    end;
   JelszoPanel.Visible := False;
   with KisMenuPanel do
     begin
       Left := 0;
       Top := 10;
       Visible := True;
     end;
   
   activeControl := MG1;
end;

procedure TUSERFORM.mg1Enter(Sender: TObject);
begin
  with TBitBtn(Sender) do
    begin
      Font.Color := clRed;
      Font.Style := [fsBold];
    end;
end;

procedure TUSERFORM.mg1Exit(Sender: TObject);
begin
  with TBitBtn(Sender) do
    begin
      Font.Color := clBlack;
      Font.Style := [];
    end;
end;

procedure TUSERFORM.mg1Click(Sender: TObject);
begin
  UserTabla.Close;
  Modalresult := 1;
end;

procedure TUSERFORM.MG2Click(Sender: TObject);
begin
  // Uj felhasználó
  _ujuser := true;
  _ujUsernev := '';
  _pw1 := '';
  _pw2 := '';
  Nevedit.Clear;
  Jelszo1edit.clear;
  Jelszo2edit.Clear;
  Konfirmgomb.Caption := 'ADATOK RÖGZITHETÕK';
  KonfirmGomb.Enabled := False;
  with UserPanel do
    begin
      Top := 8;
      Left := 8;
      Visible := true;
    end;
  ActiveControl := Nevedit;
end;

procedure TUSERFORM.NEVEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);

begin
  if ord(key)<>13 then exit;
  _ujusernev := Nevedit.Text;
  if _ujUsernev='' then exit;
  _usernev := _ujusernev;
  ActiveControl := Jelszo1Edit;
end;

procedure TUSERFORM.JELSZO1EDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  _pw1 := Jelszo1Edit.text;
  if _pw1='' then exit;
  ActiveControl := Jelszo2Edit;
end;

procedure TUSERFORM.JELSZO2EDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  _pw2 := Jelszo2Edit.text;
  if _pw2='' then exit;
  if _pw1<>_pw2 then
    begin
      Jelszo1edit.Clear;
      Jelszo2Edit.Clear;
      Showmessage('NEM AZONOS A MEGISMÉTELT JELSZÓ !');
      Beep;
      ActiveControl := Jelszo1edit;
      Exit;
    end;
   Konfirmgomb.enabled := True;
   ActiveControl := KonfirmGomb;
end;

procedure TUSERFORM.KONFIRMGOMBClick(Sender: TObject);
var _pwKod: string;
begin
  if _usernev='' then exit;
  if _pw1='' then exit;
  if _pw1<>_pw2 then exit;
  _pwkod := Kodol(_pw1);
  UserTabla.close;
  if _ujUser then
    begin
      UserDbase.Connected := True;
      if UserTranz.InTransaction then UserTranz.Commit;
      UserTranz.StartTransaction;

      _pcs := 'INSERT INTO USERS (USERS,HEXAPASSWORD)'+_sorveg;
      _pcs := _pcs + 'VALUES ('+chr(39)+_ujUsernev+chr(39)+',';
      _pcs := _pcs + chr(39)+_pwkod+chr(39)+')';

      with UserQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          ExecSql;
        end;
      UserTranz.Commit;
      UserDbase.Close;
      ModalResult := 1;
      Exit;
    end;
  ModalResult := 1;
  Exit;
end;


procedure TUSERFORM.MG4Click(Sender: TObject);
begin
  // Jelszó módositás

  Nevedit.Text := _usernev;
  Jelszo1edit.Clear;
  Jelszo2Edit.Clear;
  with UserPanel do
    begin
      Top := 8;
      Left := 8;
      Visible := True;
    end;
  
  ActiveControl := Jelszo1Edit;
end;

function Tuserform.Kodol(_natstr: string): string;

var _aktkod: byte;
    _kods: string;
    _lennat,i: integer;
begin
  result := '';
  if _natstr='' then exit;
  _natstr := uppercase(_natstr);
  _lennat := length(_natstr);
  for i := 1 to _lennat do
    begin
      _aktkod := 255-(ord(_natstr[i]));
      _kods := Form1.decitohexa(_aktkod);
      result := result + _kods;
    end;
end;     

function TUserForm.Dekodol(_kodstr: string): string;

var _betu,_betupar: string;
    _kodlen,j,_szam : integer;
begin
  result := '';
  if _kodstr='' then exit;
  _kodlen := length(_kodstr);
  j := 1;
  while j<_kodlen do
    begin
      _betupar := midstr(_kodstr,j,2);
      _szam := Form1.HexaToDec(_betupar);
      _betu := chr(255-_szam);
      result := result + _betu;
      j :=  J + 2;
    end;
end;

procedure TUSERFORM.MG3Click(Sender: TObject);
begin
  // EGY FELHASZNÁLO TÖRLÉSE
  _torles := True;
  KismenuPanel.Visible := False;
  PwBekeroPanel.Visible := False;
  UserDbase.Close;
  UserDbase.Connected := true;

  UserTabla.Open;
  UserTabla.Refresh;
  UserTabla.First;
  UserValasztas;
end;

end.
