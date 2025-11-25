unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB, IBCustomDataSet,
  IBQuery, Grids, DBGrids, IBTable;

type
  Tsuperform = class(TForm)

    BanPanel        : TPanel;
    DelPanel        : TPanel;
    FolyamatPanel   : TPanel;
    InsPanel        : TPanel;
    KismenuPanel    : TPanel;
    ValasztottPanel : TPanel;

    Label1          : TLabel;
    Label2          : TLabel;
    Label3          : TLabel;
    Label4          : TLabel;
    Label5          : TLabel;

    BanSign         : TBitBtn;
    DelReturnGomb   : TBitBtn;
    InsertGomb      : TBitBtn;
    KlDelete        : TBitBtn;
    KlInsert        : TBitBtn;
    KlReadList      : TBitBtn;
    KilepoGomb      : TBitBtn;
    MegsemTiltGomb  : TBitBtn;
    RemoveGomb      : TBitBtn;
    Tiltogomb       : TBitBtn;
    ValasztoGomb    : TBitBtn;
    VisszaGomb      : TBitBtn;

    Shape1          : TShape;

    KorlQuery       : TIBQuery;
    KorlDbase       : TIBDatabase;
    KorlTranz       : TIBTransaction;
    KorlTabla       : TIBTable;

    DelRacs         : TDBGrid;
    InsRacs         : TDBGrid;

    DelSource       : TDataSource;
    InsSource       : TDataSource;

    Szignoedit      : TEdit;
    FOCIMPANEL: TPanel;
    OpenDialog1: TOpenDialog;
    emailTMKGOMB: TBitBtn;
    EMAILPANEL: TPanel;
    emailquery: TIBQuery;
    EMAILDBASE: TIBDatabase;
    EMAILTRANZ: TIBTransaction;
    EMAILRACS: TDBGrid;
    EMAILSOURCE: TDataSource;
    EMAILMODIGOMB: TBitBtn;
    UJVEZETOGOMB: TBitBtn;
    TORLOGOMB: TBitBtn;
    MENUREGOMB: TBitBtn;
    Label6: TLabel;
    MODIPANEL: TPanel;
    Label7: TLabel;
    Label8: TLabel;
    EMAILEDIT: TEdit;
    NEVEDIT: TEdit;
    Label9: TLabel;
    EMAILOKEGOMB: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    Shape2: TShape;
    ujvezetopanel: TPanel;
    Shape3: TShape;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    UJNEVEDIT: TEdit;
    UJEMAILEDIT: TEdit;
    UJNEVOKEGOMB: TBitBtn;
    UJNEVMEGSEMGOMB: TBitBtn;
    TORLOPANEL: TPanel;
    Shape4: TShape;
    Label13: TLabel;
    Label14: TLabel;
    TORLONEVEDIT: TEdit;
    Label15: TLabel;
    TORLOOKEGOMB: TBitBtn;
    TORLOMEGSEMGOMB: TBitBtn;
    PROSQUERY: TIBQuery;
    PROSDBASE: TIBDatabase;
    PROSTRANZ: TIBTransaction;


    procedure BanSignClick(Sender: TObject);
    procedure DelReturnGombClick(Sender: TObject);
    procedure FolyamatDisplay;
    procedure AddressParancs(_ukaz: string);
    procedure FormActivate(Sender: TObject);
    procedure InsertGombClick(Sender: TObject);
    procedure KilepoGombClick(Sender: TObject);
    procedure KismenuStart;
    procedure KlDeleteClick(Sender: TObject);
    procedure KlInsertClick(Sender: TObject);
    procedure KlReadLISTClick(Sender: TObject);
    procedure EmailModify;
    procedure KorlOpen;
    procedure RemoveGombClick(Sender: TObject);
    procedure SzignoEditEnter(Sender: TObject);
    procedure SzignoeditExit(Sender: TObject);
    procedure SzignoeditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure TiltogombClick(Sender: TObject);
    procedure ValasztoGombClick(Sender: TObject);
    procedure VisszaGombClick(Sender: TObject);
    procedure MEGSEMTILTGOMBClick(Sender: TObject);
    procedure emailTMKGOMBClick(Sender: TObject);
    procedure MENUREGOMBClick(Sender: TObject);
    procedure EMAILMODIGOMBClick(Sender: TObject);
    procedure EMAILRACSKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure EMAILOKEGOMBClick(Sender: TObject);
    procedure UJVEZETOGOMBClick(Sender: TObject);
    procedure RacsAktivalo;
    procedure UJNEVEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure UJEMAILEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure UJNEVOKEGOMBClick(Sender: TObject);
    procedure TORLOGOMBClick(Sender: TObject);
    procedure TORLOMEGSEMGOMBClick(Sender: TObject);
    procedure TORLOOKEGOMBClick(Sender: TObject);
    function GetProskod(_prosnev: string): word;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  superform: Tsuperform;
  _ed: array[1..13] of TEdit;
  _xP: array[1..13] of TPanel;

  _sorveg: string = chr(13)+chr(10);
  _masEmail: boolean;

  _insFilePath,
  _last,
  _mchmail,
  _mchname,
  _pcs,
  _tiltottszigno,
  _ujnev,
  _ujemailcim: string;

  _aktorder,
  _aktsorszam,
  _aktsorrend,
  _dIndex,
  _kod,
  _lastsorrend,
  _left1,
  _sorszam,
  _top1,
  _sr: word;

  _storno: byte;

implementation

uses Unit1, Unit3, Unit4;

{$R *.dfm}


// =============================================================================
              procedure Tsuperform.FormActivate(Sender: TObject);
// =============================================================================

begin
  _top1  := Form1.top;
  _left1 := Form1.Left;

  top    := _top1;
  Left   := _left1;
  Height := 410;

  EmailPanel.Visible := False;
  FocimPanel.Visible := false;
  BanPanel.visible := False;
  DelPanel.Visible := False;
  InsPanel.Visible := False;
  FolyamatPanel.Visible := False;
  KismenuStart;

end;

// =============================================================================
            procedure Tsuperform.KLINSERTClick(Sender: TObject);
// =============================================================================

var _vipnum: integer;

begin
  InsertGomb.Enabled := False;
  Valasztogomb.Enabled := True;
  KismenuPanel.Visible := False;

  with FocimPanel do
    begin
      top := 200;
      Left := 200;
      Caption := 'Egy körlevél beszurása';
      Visible := True;
      Repaint;
    end;

  _vipnum := GetVipForm.showmodal;
  if _vipnum<0 then
    begin
      Modalresult := 2;
      exit;
    end;
  FocimPanel.Visible := False;
  if _VIPNUM=1 then _destiny := 'EBC';
  if _VIPNUM=2 then _destiny := 'ZALOG';
  if _vipNum=3 then _DESTINY := 'VIP';
  KorlOpen;

  with InsPanel do
    begin
      Top  := 16;
      Left := 128;
      Visible := True;
    end;
  InsSource.Enabled := true;
  InsRacs.SetFocus;
end;

// =============================================================================
             procedure Tsuperform.KilepoGombClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
               procedure Tsuperform.KlDeleteClick(Sender: TObject);
// =============================================================================

VAR _Dnum: integer;

begin
  KismenuPanel.Visible := False;
  with FocimPanel do
    begin
      top := 200;
      Left := 200;
      Caption := 'Egy körlevél törlése';
      Visible := True;
      Repaint;
    end;


  _DNUM := GetVipForm.showmodal;
  if _dnum<0 then
    begin
      Modalresult := 2;
      exit;
    end;
      
  FocimPanel.Visible := False;
  IF _dnum=1 then _destiny := 'EBC';
  IF _DNUM=2 then _destiny := 'ZALOG';
  IF _DNUM=3 then _destiNy := 'VIP';

  KorlOpen;

  with DelPanel do
    begin
      Top  := 16;
      Left := 128;
      Visible := True;
    end;
  DelSource.Enabled := true;
  DelRacs.SetFocus;

end;

// =============================================================================
               procedure Tsuperform.DelReturnGombClick(Sender: TObject);
// =============================================================================

begin
  KorlQuery.close;
  KorlDbase.close;
  DelPanel.Visible := False;
  Kismenustart;
end;


// =============================================================================
                          procedure TsuperForm.KorlOpen;
// =============================================================================

begin
  _currLettName := 'KORLEVEL';
  if _destiny='VIP' then _currlettname := 'VIPLEVEL';
  if _destiny='ZALOG' then _currlettname := 'ZALOGLEVEL';

  _pcs := 'SELECT * FROM '+_currLettName + _sorveg;
  _pcs := _pcs + 'WHERE STORNO<2' + _sorveg;
  _pcs := _pcs + 'ORDER BY SORREND';

  KorlDbase.close;
  Korldbase.DatabaseName := _serverKorDbasePath;
  KorlDbase.Connected := true;
  with KorlQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _Lastsorrend := FieldByName('SORREND').asInteger;
      First;
    end;
end;


// =============================================================================
                      procedure TSuperForm.KismenuStart;
// =============================================================================

begin
  with KismenuPanel do
    begin
      top  := 130;
      left := 230;
      Visible := True;
    end;
end;

// =============================================================================
            procedure Tsuperform.RemoveGombClick(Sender: TObject);
// =============================================================================

begin
  _aktsorszam := Korlquery.fieldByName('SORSZAM').asInteger;
  _aktSorrend := Korlquery.FieldByName('SORREND').asInteger;
  Korlquery.Close;
  Korldbase.close;

  _pcs := 'UPDATE ' + _currLettName + ' SET STORNO=2' + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_aktsorszam);

  fORM1.SERVERParancs(_pcs);
  DelSource.Enabled := False;

  Form1.SorrendRegen;
  DelPanel.Visible := false;
  Kismenustart;

end;


// =============================================================================
               procedure Tsuperform.ValasztoGombClick(Sender: TObject);
// =============================================================================

begin
  if not OpenDialog1.Execute then exit;

  Valasztogomb.Enabled := false;
  _localPath := Opendialog1.FileName;

  Form1.SetvalasztottFile;

  ValasztottPanel.Caption := _tartalom;
  Insertgomb.Enabled := True;
  Insracs.SetFocus;
end;


// =============================================================================
             procedure Tsuperform.InsertGombClick(Sender: TObject);
// =============================================================================

begin
  if _localPath='' then exit;
  _remotefile := extractfileName(_localpath);

  Folyamatdisplay;

  _aktorder := KorlQuery.FieldByName('SORREND').asInteger;

  KorlQuery.close;
  Korldbase.close;

  Insertgomb.Enabled := False;
  VisszaGomb.Enabled := false;

  _iktatoszam := Form1.GetIktatoszam(_DESTINY);
  _iktatostring := _sign + Form1.fillnull(_iktatoszam);

  if not Form1.SendRoundletter then exit;

  _pcs := 'INSERT INTO ' + _currLettName + ' (IKTATOSZAM,DATUM,TARTALOM,';
  _pcs := _pcs + 'SORSZAM,SORREND,STORNO,FILENEV)'+ _sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _iktatostring + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mamas + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tartalom + chr(39) + ',';
  _pcs := _pcs + inttostr(_iktatoszam) + ',';
  _pcs := _pcs + inttostr(_aktOrder+1) + ',1,';
  _pcs := _pcs + chr(39) + _remotefile + chr(39)+')';

  Form1.ServerParancs(_pcs);

  _last := 'UTSORSZAM';
  If _destiny='VIP'  then _last := 'UTVIPSORSZAM';
  if _destiny='ZALOG' then _last := 'UTZALOGSORSZAM';
  
  _pcs := 'UPDATE ADATOK SET ' + _last + '='+inttostr(_iktatoszam);
  Form1.ServerParancs(_pcs);

  Form1.SorrendRegen;

  InsPanel.Visible := False;
  Visszagomb.Enabled := True;
  Folyamatpanel.Visible := false;
  KismenuStart;

end;

// =============================================================================
           procedure Tsuperform.VisszaGombClick(Sender: TObject);
// =============================================================================

begin
  KorlQuery.close;
  Korldbase.close;
  InsPanel.Visible := False;
  KismenuStart;
end;


// =============================================================================
                    procedure TsuperForm.FolyamatDisplay;
// =============================================================================

begin
  with FolyamatPanel do
    begin
      Top     := 328;
      Left    := 192;
      Visible := True;
      repaint;
    end;
end;


procedure Tsuperform.BANSIGNClick(Sender: TObject);
begin
  kISMENUPANEL.Visible := False;
  szignoedit.clear;
  with BanPanel do
    begin
      Top := 100;
      Left := 240;
      Visible := True;
    end;
  Activecontrol := szignoedit;
end;

// =============================================================================
           procedure Tsuperform.szignoeditEnter(Sender: TObject);
// =============================================================================

begin
  SzignoEdit.Color := clyellow;
end;

// =============================================================================
          procedure Tsuperform.szignoeditExit(Sender: TObject);
// =============================================================================

begin
  Szignoedit.Color := clwhite;
end;

// =============================================================================
    procedure Tsuperform.szignoeditKeyDown(Sender: TObject; var Key: Word;
                                                         Shift: TShiftState);
// =============================================================================

begin
  if ord(Key)<>13 then exit;
  Activecontrol := Tiltogomb;
end;


// =============================================================================
           procedure Tsuperform.tiltogombClick(Sender: TObject);
// =============================================================================

begin
  _tiltottszigno := trim(Szignoedit.Text);
  if _tiltottszigno='' then exit;

  Banpanel.Visible := False;
  _pcs := 'INSERT INTO TILTOTT (SZIGNO)'+_sorveg;
  _pcs := _pcs + 'VALUES ('+chr(39)+_tiltottszigno+chr(39)+')';
  Form1.serverParancs(_pcs);
  Form1.GetTiltott;
  Kismenustart;
end;

// =============================================================================
             procedure Tsuperform.KlReadListClick(Sender: TObject);
// =============================================================================

begin
  ReadTimeForm.Showmodal;
end;


// =============================================================================
         procedure Tsuperform.MEGSEMTILTGOMBClick(Sender: TObject);
// =============================================================================

begin
  Banpanel.Visible := False;
  Kismenustart;
end;

// =============================================================================
            procedure Tsuperform.emailTMKGOMBClick(Sender: TObject);
// =============================================================================


begin
  Height := 621;

  ModiPanel.Visible     := False;
  TorloPanel.Visible    := False;
  Ujvezetopanel.Visible := False;

  with EmailPanel do
    begin
      top  := 80;
      left := 56;
      Visible := true;
      repaint;
    end;

  RacsAktivalo;

end;

// =============================================================================
           procedure Tsuperform.MENUREGOMBClick(Sender: TObject);
// =============================================================================

begin
  emailquery.Close;
  emaildbase.close;

  EmailPanel.Visible := False;
  Height := 410;
end;

// =============================================================================
            procedure Tsuperform.EMAILMODIGOMBClick(Sender: TObject);
// =============================================================================

// E-mail címek módositása ....

begin
  eMailModify;
end;

// =============================================================================
      procedure Tsuperform.EMAILRACSKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

// enter a rácson -> email módositása

begin
  if ord(key)<>13 then exit;

  emailModify;
end;

// ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
// =============================================================================
                       procedure Tsuperform.EmailModify;
// =============================================================================

// Az aktuális e-mailcím módositása ....

begin

  // Az aktuális vezetõ adatai:

  _sorszam := EmailQuery.FieldByName('SORSZAM').asInteger;
  _mchName := trim(EmailQuery.FieldByName('NEV').asstring);
  _mchmail := trim(EmailQuery.FieldByName('EMAIL').asString);

  // Kiirja a vezetõ nevét:

  with Nevedit do
    begin
      Text := _mchName;
      repaint;
    end;

  // Kiirja a jelenlegi e-mail címet, amit módosithat

  emailedit.Text := _mchMail;
  with ModiPanel do
    begin
      top := 144;
      left := 72;
      Visible := true;
    end;

  // Ha akarja -> megváltoztathatja:

  ActiveControl := Emailedit;
end;

// =============================================================================
          procedure Tsuperform.MEGSEMGOMBClick(Sender: TObject);
// =============================================================================

// Mégsem módositja az e-mail címet:

begin
  ModiPanel.Visible := false;
end;

// =============================================================================
           procedure Tsuperform.EMAILOKEGOMBClick(Sender: TObject);
// =============================================================================

// Módositotta (vagy nem) az eredeti e-mail címet:

begin
  // A módositó panel eltünik:

  ModiPanel.Visible := false;

  _ujeMailCim := trim(emailedit.Text);

  // Nem is változott az e-mail cim:

  if _ujeMailcim=_mchMail then exit;

  // Az új email-cím felirása az az ADDRESS adatbázisba:

  _pcs := 'UPDATE ADDRESS SET EMAIL='+chr(39)+_ujEmailcim+chr(39)+_sorveg;
  _pcs := _Pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);

  AddressParancs(_pcs);
  RacsAktivalo;
end;

// ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
// =============================================================================
           procedure Tsuperform.UJVEZETOGOMBClick(Sender: TObject);
// =============================================================================

// Új vezetõt kiván felvenni:

begin
  UjNevedit.clear;
  UjEmailedit.clear;

  with UjvezetoPanel do
    begin
       top := 144;
      left := 72;
      Visible := true;
    end;
  Activecontrol := Ujnevedit;
end;

// =============================================================================
     procedure Tsuperform.UJNEVEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

// Az új vezetõ nevének beirása után entert nyomott:

begin
  if ord(key)<>13 then exit;
  Activecontrol := ujemailedit;
end;

// =============================================================================
    procedure Tsuperform.UJEMAILEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

// Az új vezetõ emailcime után entert nyomott:

begin
   if ord(key)<>13 then exit;
  Activecontrol := UjnevOkeGomb;
end;

// =============================================================================
            procedure Tsuperform.UJNEVOKEGOMBClick(Sender: TObject);
// =============================================================================

// Rákattintott az új vezetõ rendben gombra:

begin

  // Ellenõrzi. hogy van-e új név:

  _ujnev := trim(ujnevedit.text);
  if _ujnev='' then
    begin
      Activecontrol := ujNevedit;
      exit;
    end;

  // ellenõrzi, hogy van-e új emailcim:

  _ujemailcim := trim(ujemailedit.Text);
  if _ujemailcim='' then
    begin
      Activecontrol := ujEmailedit;
      exit;
    end;

  // Az utolsó sorszámra lép és beolvassa:

  Emailquery.last;
  _sorszam := Emailquery.fieldByName('SORSZAM').asInteger;
  inc(_sorszam);

  // Lépteti a sorszámot:

  _kod := GetProskod(_ujnev);

  if _kod=0 then
    begin
      ShowMessage('AZ ÚJ VEZETÕ NINCS A DOLGOZÓI ADATBÁZISBAN !');
      UjVezetoPanel.Visible := false;
      exit;
    end;

  // Rögziti az új vezetõt az email adatbázisban:

  _pcs := 'INSERT INTO ADDRESS (SORSZAM,NEV,EMAIL,KOD)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + inttostr(_sorszam) + ',';
  _pcs := _pcs + chr(39) + _ujnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _ujemailcim + chr(39) + ',';
  _pcs := _pcs + inttostr(_kod) + ')';

  AddressParancs(_pcs);

  UjvezetoPanel.Visible := False;

  // Újranyitja a vezetõi adatbázist és rácsot:

  RacsAktivalo;
end;

// ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
// =============================================================================
            procedure Tsuperform.TORLOGOMBClick(Sender: TObject);
// =============================================================================

// Törlögombot nyomott

begin
   // Az aktuális vezetõ adatai:

  _sorszam := EmailQuery.FieldByName('SORSZAM').asInteger;
  _mchName := trim(EmailQuery.FieldByName('NEV').asstring);
  _mchmail := trim(EmailQuery.FieldByName('EMAIL').asString);

  // Kiirja a vezetõ nevét:

  with TorloNevedit do
    begin
      Text := _mchName;
      repaint;
    end;

  with TorloPanel do
    begin
      top := 144;
      left := 72;
      Visible := true;
      repaint;
    end;

  // Ha akarja -> megváltoztathatja:

  ActiveControl := TorloMegsemgomb;
end;

// =============================================================================
         procedure Tsuperform.TORLOMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  TorloPanel.Visible := False;
end;


// =============================================================================
        procedure Tsuperform.TORLOOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'DELETE FROM ADDRESS' + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);

  addressParancs(_pcs);
  TorloPanel.Visible := False;

  RacsAktivalo;
end;

// =============================================================================
                procedure Tsuperform.AddressParancs(_ukaz: string);
// =============================================================================

begin
  EmailQuery.close;
  Emaildbase.close;
  Emaildbase.DatabaseName := _midchiefPath;
  Emaildbase.Connected := true;

  if EmailTranz.InTransaction then emailTranz.Commit;
  Emailtranz.StartTransaction;
  with EmailQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      execSql;
    end;
  Emailtranz.Commit;
  Emaildbase.close;
end;

// =============================================================================
                      procedure Tsuperform.RacsAktivalo;
// =============================================================================

begin
  EmailQuery.close;
  Emaildbase.close;
  Emaildbase.DatabaseName := _midchiefPath;
  Emaildbase.Connected := true;
  with Emailquery do
    begin
      Close;
      Sql.clear;
      sql.add('SELECT * FROM ADDRESS ORDER BY SORSZAM');
      Open;
      First;
    end;
  Activecontrol := Emailracs;
end;

function tSuperForm.GetProskod(_prosnev: string): word;

begin
   // Penztárosok között megkeresi a most megadott vezetõ nevét:
  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'WHERE PENZTAROSNEV LIKE ' + chr(39) + _prosnev + '%' + CHR(39);

  Prosdbase.close;
  prosdbase.databasename := _host + ':c:\receptor\database\ptarosok.fdb';
  prosdbase.connected := true;

  with Prosquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  result := 0;
  if _recno>0 then result := Prosquery.FieldByName('SORSZAM').asInteger;

  prosquery.close;
  prosdbase.close;
end;



end.

