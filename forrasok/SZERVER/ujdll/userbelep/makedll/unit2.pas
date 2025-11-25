unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, DBTables, Grids, DBGrids, ExtCtrls, StdCtrls, Buttons,
  StrUtils, IBDatabase, IBCustomDataSet, IBTable, IBQuery;

type
  TUSERFORM = class(TForm)

    TorloQuery             : TIBQuery;
    TorloDbase             : TIBDatabase;
    TorloTranz             : TIBTransaction;

    UserSource             : TDataSource;
    UserTabla              : TIBTable;
    UserDbase              : TIBDatabase;
    UserTranz              : TIBTransaction;
    UserQuery              : TIBQuery;

    KisMenuPanel           : TPanel;
    PWBekeroPanel          : TPanel;
    UjUserPanel            : TPanel;
    UserNevPanel           : TPanel;
    JELSZOPanel            : TPanel;
    FHNevPanel             : TPanel;
    FHJelszoPanel          : TPanel;
    PWModositoPanel        : TPanel;
    TORLOPanel             : TPanel;
    UserValPanel           : TPanel;
    TOROLOKEGOMB: TBitBtn;
    MEGSEMTOROLGOMB: TBitBtn;
    Mg1                    : TBitBtn;
    Mg2                    : TBitBtn;
    Mg3                    : TBitBtn;
    Mg4                    : TBitBtn;
    MegsemGomb             : TBitBtn;
    ModJelszoOkeGomb       : TBitBtn;
    ModJelszoMegsemGomb    : TBitBtn;
    KonfirmGomb            : TBitBtn;
    SemGomb                : TBitBtn;

    Shape1                 : TShape;
    Shape2                 : TShape;
    Shape3                 : TShape;
    Shape4                 : TShape;
    Shape7                 : TShape;
    Shape8                 : TShape;
    Shape9                 : TShape;
    Shape10                : TShape;

    Label1                 : TLabel;
    Label2                 : TLabel;
    Label3                 : TLabel;
    Label4                 : TLabel;
    Label5                 : TLabel;
    Label6                 : TLabel;
    Label7                 : TLabel;
    Label8                 : TLabel;
    Label9                 : TLabel;
    Label10                : TLabel;
    Label11                : TLabel;

    Jelszo1Edit            : TEdit;
    Jelszo2Edit            : TEdit;
    JelszoEdit             : TEdit;
    ModIsmeteltEdit        : TEdit;
    MODJelszoEdit          : TEdit;
    NevEdit                : TEdit;

    TorloRacs              : TDBGrid;
    UserRacs               : TDBGrid;

    TorloSource            : TDataSource;
    TorloQueryUsers        : TIBStringField;
    TorloQueryHEXAPassword : TIBStringField;
    TorloQuerySorszam      : TSmallintField;

    procedure MEGSEMTOROLGOMBClick(Sender: TObject);
    procedure TOROLOKEGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure JelszoEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Jelszo1EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Jelszo2EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Jelszo1EditEnter(Sender: TObject);
    procedure Jelszo1EditExit(Sender: TObject);
    procedure KonfirmGombClick(Sender: TObject);
    procedure Kivalasztas(Sender: TObject);
    procedure M1Enter(Sender: TObject);
    procedure M1Exit(Sender: TObject);
    procedure M1Click(Sender: TObject);
    procedure M2Click(Sender: TObject);
    procedure M3Click(Sender: TObject);
    procedure M4Click(Sender: TObject);
    procedure MegsemGombClick(Sender: TObject);
    procedure ModIsmeteltEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ModJelszoOkeGombClick(Sender: TObject);
    procedure ModJelszoEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure NevEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Torlorutin;
    procedure TorloRacsDblClick(Sender: TObject);
    procedure Uparancs(_ukaz: string);
    procedure UserValasztas;
    procedure UserRacsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    function HexaToDec(_hexa: string): integer;
    function DecitoHexa(_deci: byte):string;
    function Kodol(_natstr: string): string;
    function Dekodol(_kodstr: string): string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  USERFORM: TUSERFORM;
  _kodoltPw,_ujUsernev,_pw1,_pw2,_usernev,_pcs,_removenev: string;
  _sorveg: string = chr(13)+chr(10);
  _ujUser,_torles,_modPassword: boolean;
  _injelszo,_jojelszo,_modjelszo,_ismetelt: string;
  _fhsorszam,_lastsorszam,_aktsorszam: integer;

function userbelepes: integer; stdcall;


implementation

{$R *.dfm}


function userbelepes: integer; stdcall;

begin
  Userform := TUserform.create(Nil);
  result := Userform.showmodal;
  Userform.free;
end;



// =============================================================================
            procedure TUSERFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
   Top := 390;
  Left := 430;
  width := 409;

  UJUserPanel.Visible    := False;
  KismenuPanel.Visible   := false;
  PWBekeroPanel.Visible  := False;

  _pcs := 'SELECT * FROM USERS ORDER BY SORSZAM';
  Usertabla.close;
  UserDbase.Connected := true;
  with UserQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _lastsorszam := FieldByNAme('SORSZAM').asInteger;
      Close;
    end;

  UserTabla.Open;
  UserTabla.Refresh;
  UserTabla.First;
  UserValasztas;
end;

// =============================================================================
                      procedure TUserForm.UserValasztas;
// =============================================================================

begin
  with UserValpanel do
    begin
      Left    := 0;
      Top     := 0;
      Visible := true
    end;

  Userracs.SelectedIndex := 0;
  ActiveControl := UserRacs;
  Userracs.SetFocus;
end;

// =============================================================================
            procedure TUSERFORM.MEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  UserTabla.Close;
  Userdbase.close;
  Modalresult := 2;
end;

// =============================================================================
     procedure TUSERFORM.USERRACSKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Kivalasztas(Nil);
end;


// =============================================================================
           procedure TUserForm.Kivalasztas(Sender: TObject);
// =============================================================================

begin
  if _torles then
    begin
      _removeNev := UserTabla.FieldByName('USERS').asstring;
      if _removeNev=_usernev then
        begin
          ShowMessage('ÖNMAGADAT NEM TÖRÖLHETED !');
          Usertabla.close;
          UserDbase.close;
          Modalresult :=2;
          exit;
        end;
      _pcs := 'DELETE FROM USERS' + _sorveg;
      _pcs := _pcs + 'WHERE USERS=' + chr(39)+_removenev + chr(39);
      Uparancs(_pcs);

      ShowMessage(trim(_usernev) + ' törölve !');
      ModalResult := 1;
      exit;
    end;

  _usernev := TRIM(UserTabla.FieldByName('USERS').asstring);
  _kodoltpw := TRIM(UserTabla.FieldByName('HEXAPASSWORD').asstring);
  _fhSorszam := UserTabla.FieldByName('SORSZAM').asInteger;

  UserNevPanel.Caption := _usernev;
  JelszoEdit.Clear;
  UserValPanel.visible := False;
  with PwBekeroPanel do
    begin
      Top     := 3;
      Left    := 3;
      Visible := True;
      Bringtofront;
    end;
  ActiveControl := Jelszoedit;
end;

// =============================================================================
       procedure TUSERFORM.JELSZOEDITKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

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
   PWBekeroPanel.Visible := False;
   with KisMenuPanel do
     begin
       Left := 3;
       Top := 3;
       Visible := True;
     end;

   activeControl := MG1;
end;

// =============================================================================
                    procedure TUSERFORM.m1Enter(Sender: TObject);
// =============================================================================

begin
  with TBitBtn(Sender) do
    begin
      Font.Color := clmAROON;
      Font.Style := [fsBold];
    end;
end;

// =============================================================================
               procedure TUSERFORM.m1Exit(Sender: TObject);
// =============================================================================

begin
  with TBitBtn(Sender) do
    begin
      Font.Color := clBlack;
      Font.Style := [];
    end;
end;

// =============================================================================
                procedure TUSERFORM.m1Click(Sender: TObject);
// =============================================================================

begin
  UserTabla.Close;
  Modalresult := 1;
end;

// =============================================================================
                   procedure TUSERFORM.M2Click(Sender: TObject);
// =============================================================================

begin
  // Uj felhasználó

  uSERfORM.Caption := 'EGY ÚJ FELHASZNÁLÓ FELVÉTELE A LISTÁBA';

  _ujUsernev := '';
  _pw1       := '';
  _pw2       := '';

  Nevedit.Clear;
  Jelszo1edit.clear;
  Jelszo2edit.Clear;

  KisMenupanel.visible := False;
  with UjUserPanel do
    begin
      Top     := 3;
      Left    := 3;
      Visible := true;
    end;
  ActiveControl := Nevedit;
end;

// =============================================================================
       procedure TUSERFORM.NEVEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;

  _ujusernev := Nevedit.Text;
  if _ujUsernev='' then
    begin
      activecontrol := nevedit;
      exit;
    end;
  ActiveControl := Jelszo1Edit;
end;

// =============================================================================
      procedure TUSERFORM.JELSZO1EDITKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================
begin
  if ord(key)<>13 then exit;

  _pw1 := Jelszo1Edit.text;
  if _pw1='' then exit;

  ActiveControl := Jelszo2Edit;
end;

// =============================================================================
     procedure TUSERFORM.JELSZO2EDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

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

   ActiveControl := KonfirmGomb;
end;

// =============================================================================
            procedure TUSERFORM.KONFIRMGOMBClick(Sender: TObject);
// =============================================================================

var _pwKod: string;
begin
  _ujusernev := Nevedit.Text;
  if _ujUsernev='' then
    begin
      activecontrol := nevedit;
      exit;
    end;

  _pw1 := trim(Jelszo1Edit.Text);
  if _pw1='' then
    begin
      activecontrol := Jelszo1Edit;
      exit;
    end;

  _pw2 := trim(Jelszo2Edit.Text);
  if _pw2='' then
    begin
      activecontrol := Jelszo2edit;
      exit;
    end;

  if _pw1<>_pw2 then
    begin
      Jelszo1edit.Text := '';
      Jelszo2edit.Text := '';

      Activecontrol := Jelszo1edit;
      exit;
    end;

  _pwkod := Kodol(_pw1);

  _pcs := 'INSERT INTO USERS (USERS,HEXAPASSWORD,SORSZAM)'+_sorveg;
  _pcs := _pcs + 'VALUES ('+chr(39)+_ujUsernev+chr(39)+',';
  _pcs := _pcs + chr(39)+_pwkod+chr(39)+',';
  _pcs := _pcs + inttostr(_lastsorszam+1)+')';

  uParancs(_pcs);
  ModalResult := 2;
end;

// =============================================================================
                 procedure TUSERFORM.M4Click(Sender: TObject);
// =============================================================================

begin
  // Jelszó módositás

  UserForm.Caption := 'FELHASZNÁLÓ JELSZAVÁNAK MÓDOSITÁSA';

  FHnevpanel.Caption := _usernev;
  FHJelszoPanel.Caption := _jojelszo;
  kISMENUPANEL.Visible := False;
  with PWModositoPanel do
    begin
      top := 3;
      left := 3;
      Visible := true;
      repaint;
    end;
  ActiveControl := ModJelszoEdit;
end;

// =============================================================================
             function Tuserform.Kodol(_natstr: string): string;
// =============================================================================

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
      _kods := decitohexa(_aktkod);
      result := result + _kods;
    end;
end;     

// =============================================================================
          function TUserForm.Dekodol(_kodstr: string): string;
// =============================================================================

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
      _szam := HexaToDec(_betupar);
      _betu := chr(255-_szam);
      result := result + _betu;
      j :=  J + 2;
    end;
end;

// =============================================================================
            function TUserForm.DecitoHexa(_deci: byte):string;
// =============================================================================

var _dhi,_dlo: byte;

begin
  _dhi := trunc(_deci/16);
  _dlo := _deci-trunc(16*_dhi);
  if _dlo>9 then _dlo := _dlo + 7;
  if _dhi>9 then _dhi := _dhi + 7;
  result := chr(_dhi+48)+chr(_dlo+48);
end;


// =============================================================================
           function TUserForm.HexaToDec(_hexa: string): integer;
// =============================================================================

var _tizes,_egyes: byte;
begin
  _tizes := ord(_hexa[1]);
  _egyes := ord(_hexa[2]);
  _tizes := _tizes - 48;
  _egyes := _egyes - 48;
  if _tizes>9 then _tizes := _tizes-7;
  if _egyes>9 then _egyes := _egyes - 7;
  result := trunc((16*_tizes)+_egyes);
end;

// =============================================================================
              procedure TUserForm.Uparancs(_ukaz: string);
// =============================================================================

begin
  Usertabla.close;
  Userdbase.close;
  Userdbase.connected := true;
  if UserTranz.InTransaction then UserTranz.commit;
  UserTranz.StartTransaction;
  with UserQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  UserTranz.commit;
  Userdbase.close;
end;


// =============================================================================
          procedure TUSERFORM.JELSZO1EDITEnter(Sender: TObject);
// =============================================================================

begin
  TEdit(Sender).Color := clyellow;
end;

// =============================================================================
            procedure TUSERFORM.JELSZO1EDITExit(Sender: TObject);
// =============================================================================

begin
  TEdit(sender).Color := clWindow;
end;

// =============================================================================
    procedure TUSERFORM.MODJELSZOEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Activecontrol := ModIsmeteltEdit;
end;

// =============================================================================
   procedure TUSERFORM.MODISMETELTEDITKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Activecontrol  := ModjelszoOkegomb;
end;

// =============================================================================
          procedure TUSERFORM.MODJELSZOOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _ModJelszo := trim(Modjelszoedit.Text);
  _Ismetelt  := trim(Modismeteltedit.Text);

  if (_modjelszo<>_ismetelt) then
    begin
      ShowMessage('AZ ISMÉTELT JELSZÓ NEM AZONOS');
      Modjelszoedit.Text := '';
      Modismeteltedit.Text := '';
      Activecontrol := Modjelszoedit;
      exit;
    end;

  _kodoltPw := kodol(_modjelszo);
  _pcs := 'UPDATE USERS SET HEXAPASSWORD='+chr(39)+_kodoltPw+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE SORSZAM='+inttostr(_fhSorszam);
  uParancs(_pcs);
  Modalresult := 2;

end;

// =============================================================================
                 procedure TUSERFORM.M3Click(Sender: TObject);
// =============================================================================

begin
  // EGY FELHASZNÁLO TÖRLÉSE

  UserForm.Caption := 'EGY FELHASZNÁLÓ TÖRLÉSE A LISTÁRÓL';

  KismenuPanel.Visible := False;
  UserTabla.close;
  Userdbase.close;

  with TorloPanel do
    begin
      top := 3;
      left := 3;
      Visible := True;
      repaint;
    end;  

  _pcs := 'SELECT * FROM USERS' + _sorveg;
  _pcs := _pcs + 'ORDER BY USERS';

  TorloDbase.Connected := true;
  with TorloQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  Torloracs.SetFocus;
end;

// =============================================================================
               procedure TUSERFORM.MEGSEMTOROLGOMBClick(Sender: TObject);
// =============================================================================

begin
  TorloQuery.close;
  Torlodbase.close;
  Modalresult := 2;
end;

// =============================================================================
             procedure TUSERFORM.TOROLOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  Torlorutin;
end;

// =============================================================================
           procedure TUSERFORM.TORLORACSDblClick(Sender: TObject);
// =============================================================================

begin
  TorloRutin;
end;

// =============================================================================
                      procedure TUserForm.Torlorutin;
// =============================================================================

begin
  _aktsorszam := TorloQuery.fieldByName('SORSZAM').asInteger;
  torloQuery.close;
  Torlodbase.close;

  if _aktsorszam=_fhsorszam then
    begin
      ShowMessage('ÖNMAGADAT NEM TÖRÖLHETED !');
      Modalresult := 2;
      exit;
    end;  

  _pcs := 'DELETE FROM USERS' + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_aktsorszam);
  Uparancs(_pcs);

  Modalresult := 2;
end;


end.
