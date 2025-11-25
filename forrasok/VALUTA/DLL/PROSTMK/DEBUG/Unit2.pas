unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Grids, ExtCtrls, DBGrids, DB, DBTables,
  StrUtils, IBDatabase, IBCustomDataSet, IBTable, IBQuery, wininet;

type
  TPROSFORM = class(TForm)
       TORLESPANEL: TPanel;
    TORLESNEVPANEL: TPanel;
            Label6: TLabel;
      TORLESIGENGOMB: TBitBtn;
       TORLESNEMGOMB: TBitBtn;
   PENZTAROSOKSOURCE: TDataSource;
    PENZTAROSOKDBASE: TIBDatabase;
    PENZTAROSOKTRANZ: TIBTransaction;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    PENZTAROSOKQUERY: TIBQuery;
    IDKODLISTAPANEL: TPanel;
    IDKODLISTA: TListBox;
    PENZTAROSOKPANEL: TPanel;
    Shape4: TShape;
    PENZTAROSOKRACS: TDBGrid;
    Label7: TLabel;
    Shape5: TShape;
    UJPENZTAROSGOMB: TBitBtn;
    MODOSITASGOMB: TBitBtn;
    PENZTAROSTORLOGOMB: TBitBtn;
    VISSZAGOMB: TBitBtn;
    PENZTAROSKARTON: TPanel;
    KARTONFOCIMPANEL: TPanel;
    PROSIDEDIT: TEdit;
    PROSNEVEDIT: TEdit;
    PASSWORDEDIT: TEdit;
    PASSWORD2EDIT: TEdit;
    KARTONOKEGOMB: TBitBtn;
    KARTONCANCELGOMB: TBitBtn;
    Label1: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Shape1: TShape;
    Shape2: TShape;
    BitBtn1: TBitBtn;
    LISTAFOCIM: TPanel;
    modositopanel: TPanel;
    nevpanel: TPanel;
    Label2: TLabel;
    Label3: TLabel;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    Shape3: TShape;

    procedure Adatbeolvaso;
    procedure Penztarosnyitas;
    procedure GetAktualAdatok;
    procedure EscapeGombClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure KartonCancelGombClick(Sender: TObject);
    procedure KartonOkeGombClick(Sender: TObject);
    procedure IbValutaParancs(_ukaz:string);


    procedure PasswordEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Password2EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    procedure ProsnevEditChange(Sender: TObject);
    procedure ProsnevEditEnter(Sender: TObject);
    procedure ProsnevEditExit(Sender: TObject);


    procedure TorlesNemGombClick(Sender: TObject);
    procedure TorlesIgenGombClick(Sender: TObject);

    function PWstringbolHexapw(_pw: string):string;
    function HexapwbolPwstring(_hpw: string):string;
    procedure FormActivate(Sender: TObject);
    function ProsTextFileLoad: boolean;
    function Vaninternet: boolean;
    procedure BitBtn1Click(Sender: TObject);
    procedure IDKODLISTADblClick(Sender: TObject);

    procedure PenztarostValasztott;
    procedure VISSZAGOMBClick(Sender: TObject);
    procedure MODOSITASGOMBClick(Sender: TObject);
    procedure UjPenztaros(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure IDKODLISTAKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure PENZTAROSTORLOGOMBClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PROSFORM: TPROSFORM;

  _aktprosnev,_aktidkod,_prosidkod: string;
  _ujprosidkod,_ujprosnev: string;
  _password,_password2,_akcio,_hexpword: string;
  _hexaPw,_kpword,_pcs,_prosnev: string;
  _sorveg: string = chr(13) + chr(10);
  _spk,_ptdb: integer;
  _proskod,_spvoke,_index: integer;
  _height,_width,_top,_left: word;
  _valtozas,_vanidTabla,_enterzar: boolean;
  _hnet,_hFTP: HINTERNET;

  _host: string;   
  _userid: string = 'ebc-10%';
  _ftpPassword: string = 'klc+45%';
  _ftpPort: integer = 21100;

  _remotefile,_localPath,_mondat: string;
  _txtOLvas: TextFile;
  _ptid,_ptnev: array[1..800] of string;


function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';

function penztaroskarbantartas: integer; stdcall;

implementation


{$R *.dfm}

// =============================================================================
                    function penztaroskarbantartas: integer; stdcall;
// =============================================================================

begin
  Prosform := TProsform.Create(Nil);
  result := Prosform.showmodal;
  Prosform.Free;
end;

// =============================================================================
             procedure TPROSFORM.FormActivate(Sender: TObject);
// =============================================================================


begin
  Top := _top;
  Left := _left;

  Height := 376;
  Width  := 536;

  ValutaDbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _host := trim(FieldByNAme('HOST').AsString);
      Close;
    end;

  idkodlistaPanel.Visible := false;
  ModositoPanel.Visible := False;
  Penztaroskarton.Visible := false;
  TorlesPanel.Visible := false;

  _vanidTabla := ProsTextFileLoad;
  GetaktualAdatok;
  PenztarosNyitas;
  ActiveControl := PenztarosokRacs;
end;

// =============================================================================
                  procedure Tprosform.PenztarosNyitas;
// =============================================================================

begin
  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAROSNEV';

  Penztarosokdbase.close;
  PenztarosokDbase.Connected := True;
  with PenztarosokQuery do
    begin
      Close;
      sql.clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;
end;

// =============================================================================
                      procedure Tprosform.getaktualAdatok;
// =============================================================================

begin
  Valutadbase.connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      oPEN;
      _aktprosnev := trim(FieldByName('PENZTAROSNEV').asstring);
      _aktidkod   := FieldByName('IDKOD').asstring;
      Close;
    end;
  ValutaDbase.close;
end;



// =============================================================================
                   procedure TPROSFORM.UjPenztaros(Sender: TObject);
// =============================================================================

begin
  KartonFocimPanel.Caption := 'ÚJ PÉNZTÁROS FELVÉTELE';

  with PenztarosKarton do
    begin
      Top     := 8;
      Left    := 8;
      Visible := True;
    end;

  _akcio := 'U';
  _pcs := 'SELECT * FROM UTOLSOBLOKKOK';

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      _proskod := FieldByName('UTPENZTAROS').asInteger;
      Close;
    end;

  Valutadbase.close;
  inc(_proskod);

  ListaFoCim.Caption := 'Válassza ki az új dolgozót';
  _enterzar := true;
  with IdkodlistaPanel do
    begin
      Top := 8;
      Left := 8;
      Visible := True;
    end;

  Idkodlista.ItemIndex := 0;
  Idkodlista.SetFocus;

end;

// =============================================================================
           procedure TPROSFORM.IDKODLISTADblClick(Sender: TObject);
// =============================================================================

begin
  PenztarostValasztott;
end;


// =============================================================================
               procedure TProsForm.PenztarostValasztott;
// =============================================================================

begin

  _index       := 1+ Idkodlista.ItemIndex;
  _ujprosidkod := _ptid[_index];
  _ujprosnev   := _ptnev[_index];

  if _akcio='M' then
    begin
      _pcs := 'UPDATE PENZTAROSOK SET PENZTAROSNEV='+chr(39)+_ujprosnev+chr(39)+',';
      _pcs := _pcs + 'IDKOD='+chr(39)+_ujprosidkod+chr(39)+ _sorveg;
      _pcs := _pcs + 'WHERE PENZTAROSSZAM='+inttostr(_proskod);

      IbvalutaParancs(_pcs);
      Idkodlistapanel.Visible := false;
      ModositoPanel.Visible := False;

      Penztarosnyitas;
      ActiveControl := PenztarosokRacs;
      Penztarosokracs.SetFocus;
      exit;
    end;


  Prosidedit.ReadOnly  := true;
  ProsNevedit.ReadOnly := true;

  IdkodlistaPanel.Visible := False;
  Prosidedit.Text         := _ujprosidkod;
  Prosnevedit.Text        := _ujprosnev;

  Passwordedit.clear;
  Password2edit.clear;
  Activecontrol           := PasswordEdit;
end;


// =============================================================================
        procedure TPROSFORM.PASSWORDEDITKeyDown(Sender: TObject;
                                            var Key: Word; Shift: TShiftState);
// =============================================================================

begin
   if (ord(key)=13) or (ord(key)=40) then
     begin
       if PasswordEdit.Text<>'' then ActiveControl := PassWord2Edit;
       exit;
     end;
   if (ord(key)=38) then ActiveControl := ProsNevedit;
end;

// =============================================================================
       procedure TPROSFORM.Password2EditKeyDown(Sender: TObject;
                                            var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  if (ord(key)=13) or (ord(key)=40) then
    begin
      if Password2edit.Text<>'' then ActiveControl := KartonOkeGomb;
      exit;
    end;
  if (ord(key)=38) then activecontrol := PasswordEdit;
end;

// =============================================================================
         procedure TPROSFORM.KartonOkeGombClick(Sender: TObject);
// =============================================================================

begin
  _password := PasswordEdit.Text;
  _password2 := Password2edit.Text;
  if _password='' then exit;

  if _password<>_password2 then
    begin
      ShowMessage('Nem egyezik a megismételt jelszó');
      ActiveControl := Password2Edit;
      exit;
    end;

  _hexaPw := PwstringbolHexaPw(_password);

  if _akcio='U' then
    begin
      _pcs := 'INSERT INTO PENZTAROSOK (PENZTAROSSZAM,PENZTAROSNEV,JELSZO,IDKOD)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + inttostr(_proskod)+',';
      _pcs := _pcs + chr(39) + _ujprosnev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _hexapw  + chr(39)+',';
      _pcs := _pcs + chr(39) + _ujprosidkod + chr(39) + ')';

      IbValutaParancs(_pcs);

      _pcs := 'UPDATE UTOLSOBLOKKOK SET UTPENZTAROS='+inttostr(_proskod);
      IbValutaParancs(_pcs);

    end;

  if _akcio='M' then
    begin
      _pcs := 'UPDATE PENZTAROSOK SET ';
      _pcs := _pcs + 'JELSZO='+ chr(39) + _hexapw + chr(39)+_SORVEG;
      _pcs := _pcs + 'WHERE PENZTAROSSZAM='+inttostr(_proskod);

      IbValutaParancs(_pcs);
    end;

  PenztarosKarton.Visible := False;
  PenztarosNyitas;

  Penztarosokracs.SetFocus;
end;



// =============================================================================
        procedure TPROSFORM.KARTONCANCELGOMBClick(Sender: TObject);
// =============================================================================

begin
  PenzTarosKarton.Visible := False;
  ActiveControl := Penztarosokracs;
  PenztarosokRacs.SetFocus;
end;


// =============================================================================
                     procedure TPROSFORM.Adatbeolvaso;
// =============================================================================

begin
  with PenztarosokQuery do
    begin
      _proskod   := FieldByName('PENZTAROSSZAM').asInteger;
      _prosidkod := FieldByName('IDKOD').asString;
      _prosnev   := trim(FieldByName('PENZTAROSNEV').asString);
      _hexpword  := trim(FieldByName('JELSZO').asString);
    end;
  _prosnev  := trim(_prosnev);
  _password := HexapwbolPwstring(_hexpword);
end;

function TPROSFORM.HexapwbolPwstring(_hpw: string):string;

var _whpw,_pp,_pwkod: byte;

begin
  result := '';
  _hpw := trim(_hpw);
  _whpw := length(_hpw);
  if _whpw=0 then exit;

  if leftstr(_hpw,1)<>'$' then exit;
  dec(_whpw);
  if _whpw=0 then exit;

  _hpw := midstr(_hpw,2,_whpw);
  _pp := 1;
  while _pp<=_whpw do
    begin
      _pwkod := 255 - ord(_hpw[_pp]);
      result := result + chr(_pwkod);
      inc(_pp);
    end;
end;

// =============================================================================
         function TPROSFORM.PWstringbolHexapw(_pw: string):string;
// =============================================================================

var  _wpw,_pp,_pwkod: byte;

begin

  _pw := trim(_pw);

  result := '';
  _wpw := length(_pw);
  if _wpw=0 then exit;

  result := '$';
  _pp := 1;
  while _pp<=_wpw do
    begin
      _pwkod := 255 - ord(_pw[_pp]);
      result := result + chr(_pwkod);
      inc(_pp);
    end;
end;


// =============================================================================
         procedure TPROSFORM.ProsNeveditChange(Sender: TObject);
// =============================================================================

begin
  _valtozas := True;
end;

// =============================================================================
          procedure TPROSFORM.EscapeGombClick(Sender: TObject);
// =============================================================================

begin
  PenztarosokQuery.Close;
  Penztarosokdbase.Close;
  ModalResult := 2;
end;

// =============================================================================
          procedure TPROSFORM.ProsNeveditEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clYellow;
end;


// =============================================================================
           procedure TPROSFORM.prosneveditExit(Sender: TObject);
// =============================================================================

begin
  Tedit(Sender).Color := clWindow;
end;


// =============================================================================
         procedure TPROSFORM.TorlesNemGombClick(Sender: TObject);
// =============================================================================

begin
  TorlesPanel.visible := False;
  ActiveControl := PenztarosokRacs;
  PenztarosokRacs.SetFocus;
end;

// =============================================================================
        procedure TPROSFORM.TORLESIGENGOMBClick(Sender: TObject);
// =============================================================================

begin

  _pcs := 'DELETE FROM PENZTAROSOK WHERE PENZTAROSSZAM='+inttostr(_proskod);
  ibValutaParancs(_pcs);

  TorlesPanel.visible := False;
  PenztarosNyitas;


  ActiveControl := PenztarosokRacs;
  PenztarosokRacs.SetFocus;
end;





// =============================================================================
              procedure TPROSFORM.FormCreate(Sender: TObject);
// =============================================================================

begin
   _height := Screen.Monitors[0].Height;
  _width := screen.Monitors[0].Width;

  _top := trunc((_height-376)/2)+70;
  _left := trunc((_width-536)/2);

  PenztarosKarton.Visible := False;

end;

procedure TProsform.IbValutaParancs(_ukaz:string);

begin
  ValutaDbase.Connected := true;
  if ValutaTranz.InTransaction then Valutatranz.commit;
  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_ukaz);
      ExecSql;
    end;
  ValutaTranz.commit;
  Valutadbase.close;
end;


// =============================================================================
                      function TProsForm.ProsTextFileLoad: boolean;
// =============================================================================

var _proslen: integer;
    _prosname: string;

begin
  result := false;

  if not Vaninternet then
    begin
      Showmessage('NINCS INTERNETKAPCSOLAT !');
      exit;
    end;

  _hNet := InternetOpen('Penztarosok',INTERNET_OPEN_TYPE_PRECONFIG,Nil,Nil,0);

  if _hNet=nil then
    begin
      ShowMessage('NEM TALÁLOM A WININET.DLL KÖNYVTÁRAT');
      Exit;
    end;

  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
           Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  if _hftp=Nil then
    begin
      InternetCloseHandle(_hNet);
      exit;
    end;

  // ---------------------------------------------------------------------------

  _remoteFile := '\ptarosok\ptarosok.txt';
  _localpath  := 'c:\valuta\irodak\ptarosok.txt';

  result := FTPGetFile(_hFTP,pchar(_remotefile),pchar(_localPath),False,0,FTP_TRANSFER_TYPE_BINARY,0);

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);
  _ptdb := 0;
  idKodlista.items.clear;

  if result then
    begin
      _ptdb := 0;
      Assignfile(_txtOlvas,'c:\valuta\irodak\ptarosok.txt');
      reset(_txtolvas);
      while not eof(_txtolvas) do
        begin
          readln(_txtolvas,_mondat);
          inc(_ptdb);
          _proslen := length(_mondat)-8;
          _ptid[_ptdb] := midstr(_mondat,4,5);
          _prosname := midstr(_mondat,9,_proslen);
          _ptnev[_ptdb] := _prosname;
          idkodlista.Items.add(_prosname);
        end;
      closefile(_txtolvas);
    end;
   _ptdb := idkodlista.count;
end;


// =============================================================================
                 function TProsForm.Vaninternet: boolean;
// =============================================================================

var
    _dwConnType: integer;

begin

   Result := False;
   TRY
     _dwConntype := 7;
     if InternetGetConnectedState(@_dwConnType,0) then result := true;
   except
   end;
end;


procedure TPROSFORM.BitBtn1Click(Sender: TObject);
begin
   IdkodlistaPanel.Visible := false;
   PenztarosKarton.Visible := false;
   ActiveControl := PenztarosokRacs;
   Penztarosokracs.SetFocus;
end;








procedure TPROSFORM.VISSZAGOMBClick(Sender: TObject);
begin
  ModalResult := 1;
end;

procedure TPROSFORM.MODOSITASGOMBClick(Sender: TObject);
begin
  Adatbeolvaso;
  Nevpanel.Caption := _prosnev;
  with ModositoPanel do
    begin
      top := 8;
      Left := 8;
      visible := True;
    end;
end;

  (*
  _spk := supervisorjelszo(0);
  if _spk<>1 then exit;
  AdatBeolvaso;





  KartonFocimPanel.Caption := 'EGY PÉNZTÁROS MÓDOSITÁSA';
  pROSIDEDIT.Text := _prosidkod;
  Prosnevedit.Text := _prosnev;
  Passwordedit.Text := _password;
  Password2edit.Text := _password;

  with PenztarosKarton do
    begin
      Top     := 8;
      Left    := 8;
      Visible := True;
    end;

  if _prosidkod<>_aktidkod then
    begin
      _spk := supervisorjelszo(0);
      if _spk<>1 then exit;
    end;
  _akcio := 'M';

  ListaFoCim.Caption := 'Kit módosítunk ?';
  with IdkodlistaPanel do
    begin
      Top := 8;
      Left := 8;
      Visible := True;
    end;

  Idkodlista.ItemIndex := 0;
  Idkodlista.SetFocus;
end;
*)


procedure TPROSFORM.BitBtn4Click(Sender: TObject);
begin
  ModositoPanel.Visible := false;
  Activecontrol := Penztarosokracs;
  Penztarosokracs.setfocus;
end;

procedure TPROSFORM.BitBtn2Click(Sender: TObject);
begin
  _spk := supervisorjelszo(0);
  if _spk<>1 then exit;
  ListaFoCim.Caption := 'Válassza ki a nevet a központi listáról';
  _enterzar := True;
  with IdkodlistaPanel do
    begin
      Top := 8;
      Left := 8;
      Visible := True;
    end;
  idkodlista.ItemIndex := 0;
  idkodlista.SetFocus;

  _Akcio := 'M';
end;

procedure TPROSFORM.BitBtn3Click(Sender: TObject);
begin
  IF _PROSIDKOD<>_AKTIDKOD then
    begin
      _spk := supervisorjelszo(0);
      if _spk<>1 then
        begin
          ModositoPanel.visible := false;
          Activecontrol := PenztarosokRacs;
          Penztarosokracs.SetFocus;
          exit;
        end;
    end;

  KartonFocimPanel.Caption := 'JELSZÓ MÓDOSÍTÁSA';
  ProsIdedit.Text := _prosidkod;
  Prosnevedit.Text := _prosnev;
  Passwordedit.Text := _password;
  Password2edit.Text := _password;

  ModositoPanel.Visible := false;

  with PenztarosKarton do
    begin
      Top     := 8;
      Left    := 8;
      Visible := True;
    end;

  _akcio := 'M';
  Activecontrol := Passwordedit;

end;

procedure TPROSFORM.IDKODLISTAKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then
    begin
      _enterzar := False;
      exit;
    end;
  if _enterzar then
    begin
      _enterzar := false;
      exit;
    end;
  PenztarostValasztott;

end;

procedure TPROSFORM.PENZTAROSTORLOGOMBClick(Sender: TObject);
begin
  _prosnev := PenztarosokQuery.FieldByName('PENZTAROSNEV').asstring;
  _proskod := PenztarosokQuery.FieldByName('PENZTAROSSZAM').asInteger;
  Torlesnevpanel.Caption := _prosnev;

  _spk := supervisorjelszo(0);
  if _spk<>1 then exit;

  with TorlesPanel do
    begin
      Left := 50;
      Top := 128;
      Visible := true;
    end;
  Activecontrol := Torlesnemgomb;
end;







end.

