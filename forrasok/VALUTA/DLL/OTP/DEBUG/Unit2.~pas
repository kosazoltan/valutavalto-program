unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IdBaseComponent, IdComponent, IdTCPConnection,DateUtils,
  IBDatabase, DB, IBCustomDataSet, IBQuery, ExtCtrls, IdTCPClient, Buttons,
  jpeg,strutils;

type
  TOTPTERM = class(TForm)

    IdTCPClient1        : TIdTCPClient;

    AruVissz            : TLabel;
    AVBC                : TLabel;
    Label1              : TLabel;
    Label2              : TLabel;
    Label3              : TLabel;
    Label4              : TLabel;
    Label5              : TLabel;
    Label6              : TLabel;
    Label7              : TLabel;
    Label8              : TLabel;
    Label9              : TLabel;
    Label10             : TLabel;
    Label11             : TLabel;
    Label12             : TLabel;
    Label13             : TLabel;
    Label14             : TLabel;
    Label15             : TLabel;
    Label16             : TLabel;
    Label17             : TLabel;
    Label18             : TLabel;
    Label19             : TLabel;
    Label20             : TLabel;
    Label21             : TLabel;
    Label22             : TLabel;
    Label23             : TLabel;
    Label24             : TLabel;
    Label25             : TLabel;
    Label26             : TLabel;
    Label27             : TLabel;
    Label28             : TLabel;
    Label29             : TLabel;
    Label30             : TLabel;
    Label31             : TLabel;
    Label32             : TLabel;
    Label33             : TLabel;
    Label34             : TLabel;


    AlapPanel           : TPanel;
    AruVisszaCancelPanel: TPanel;
    AruVisszaOkePanel   : TPanel;
    AruVisszavetPanel   : TPanel;
    AvSubHMessPanel     : TPanel;
    AvHMessPanel        : TPanel;
    AvHTextPanel        : TPanel;
    CcHMessPanel        : TPanel;
    CcHTextPanel        : TPanel;
    CcSubHMessPanel     : TPanel;
    CloseCancelPanel    : TPanel;
    CloseOkePanel       : TPanel;
    ClHMessPanel        : TPanel;
    ClSubHmessPanel     : TPanel;
    ClHTextPanel        : TPanel;
    ComCtrlPanel        : TPanel;
    HMessPanel          : TPanel;
    HTextPanel          : TPanel;
    IdPanel             : TPanel;
    ParaLetoltoPanel    : TPanel;
    PbCancelPanel       : TPanel;
    PbHMessPanel        : TPanel;
    PbHTextPanel        : TPanel;
    PbSubHMessPanel     : TPanel;
    PkCancelPanel       : TPanel;
    PbOkePanel          : TPanel;
    PkHMessPanel        : TPanel;
    PkHTextPanel        : TPanel;
    PkOkePanel          : TPanel;
    PkSubHMessPanel     : TPanel;
    PlCancelPanel       : TPanel;
    PlSubHMessPanel     : TPanel;
    PlHMessPanel        : TPanel;
    PlHTextPanel        : TPanel;
    PlOkePanel          : TPanel;
    ProsBelepPanel      : TPanel;
    ProsKilepEsZarPanel : TPanel;
    RejectPanel         : TPanel;
    StHMessPanel        : TPanel;
    StHTextPanel        : TPanel;
    StSubHMessPanel     : TPanel;
    StornoCancelPanel   : TPanel;
    StornoOkePanel      : TPanel;
    StornoPanel         : TPanel;
    SubHMessPanel       : TPanel;
    TermClosePanel      : TPanel;
    TranzCimPanel       : TPanel;
    VasarlasPanel       : TPanel;
    VasarOkePanel       : TPanel;

    ValutaDbase         : TIBDatabase;
    ValutaQuery         : TIBQuery;
    ValutaTranz         : TIBTransaction;

    AruVisszaCancelGomb : TBitBtn;
    AruVisszaOKEGomb    : TBitBtn;
    ClCancelGomb        : TBitBtn;
    CloseOkeGomb        : TBitBtn;
    PbCancelGomb        : TBitBtn;
    PbOkeGomb           : TBitBtn;
    PkCancelGomb        : TBitBtn;
    PkOkeGomb           : TBitBtn;
    PlCancelGomb        : TBitBtn;
    PlOkeGomb           : TBitBtn;
    StornoCancelGomb    : TBitBtn;
    StornoOkeGomb       : TBitBtn;
    VasarOkeGomb        : TBitBtn;

    FizetendoEdit       : TEdit;
    BizonylatEdit       : TEdit;
    NevEdit             : TEdit;
    StornoBizEdit       : TEdit;
    StornoFTEdit        : TEdit;
    VisszaFtEdit        : TEdit;

    Image1              : TImage;
    Kilepo              : TTimer;
    Shape2              : TShape;
    UzenoBox            : TListBox;
    Label35: TLabel;
    BIZPANEL: TPanel;
    BitBtn1: TBitBtn;
    VASARCANCELGOMB: TBitBtn;
    VREPGOMB: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    BitBtn5: TBitBtn;


    procedure AdatBeolvasas;
    procedure AruvisszaCancel;
    procedure AruvisszaCancelGombClick(Sender: TObject);
    procedure Aruvisszavet;
    procedure AruvisszaOkeGombClick(Sender: TObject);
    procedure CashGombClick(Sender: TObject);
    procedure ClCancelGombClick(Sender: TObject);
    procedure CloseCancel;
    procedure CloseOkeGombClick(Sender: TObject);
    procedure ComCtrl;
    procedure FormActivate(Sender: TObject);
    procedure FunkcioValasztas;
    procedure IdTCPClient1Connected(Sender: TObject);
    procedure IdTCPClient1Disconnected(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure Logwrite(_lgmess: string);
    procedure Memoiro(_text: string);
    procedure Paraletoltes;
    procedure PenztarosBelep;
    procedure PenztarosKilepAndClose;
    procedure PBCancelGombClick(Sender: TObject);
    procedure PBOkeGombClick(Sender: TObject);
    procedure PkCancelGombClick(Sender: TObject);
    procedure PkOkeGombClick(Sender: TObject);
    procedure PLCancelGombClick(Sender: TObject);
    procedure PLoadCancel;
    procedure PLOkeGombClick(Sender: TObject);
    procedure ProsBelepCancel;
    procedure ProskiCancel;
    procedure ReprintRutin;
    procedure Storno;
    procedure StornoCancel;
    procedure StornoCancelGombClick(Sender: TObject);
    procedure StornoOkeGombClick(Sender: TObject);
    procedure StringToBytetomb(_m: string);
    procedure TerminalZaras;
    procedure ValutaParancs(_ukaz: string);
    procedure VasarCancel;
    procedure VasarCancelGombClick(Sender: TObject);
    procedure Vasarlas;
    procedure VasarOkeGombClick(Sender: TObject);
  
    function Csatlakozas: boolean;
    function CsomagKuldes: boolean;
    function Comrepeat: boolean;
    function DeKonv(_s: string): string;
    function FildSelector(_ry: string): boolean;
    function FtForm(_ft: integer): string;
    function GetHibaText(_hks: string): string;
    function GetLrcKod(_m: string): word;
    function GetMessString(_m: string): string;
    function GetSubHmess54(_g: string): string;
    function GetSubHmess90(_g: string): string;
    function GetHmess(_kods: string): string;
    function GetStamp: string;
    function KodSeek(_a: byte): string;
    function LeftZeroLevag(_bes: string): string;
    function Nulele(_b: byte): string;
    function ReplyCOntrol(_rs: string): boolean;
    procedure VREPGOMBClick(Sender: TObject);
   

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  OTPTERM: TOTPTERM;

  STX: CHAR = chr(2);
  ETX: CHAR = chr(3);
  EOT: CHAR = chr(4);
  ENQ: CHAR = chr(5);
  ACK: CHAR = chr(6);
  DLE: CHAR = chr(16);
  NAK: CHAR = chr(21);
  BSY: CHAR = chr(22);
   FS: CHAR = chr(28);
   GS: CHAR = chr(29);
   RS: CHAR = chr(30);

  _vasarlas : string = 'A000';
  _backpay  : string = 'A004';
  _prosenter: string = 'A050';
  _prosexit : string = 'A051';
  _termclose: string = 'A060';
  _paraload : string = 'A090';
  _termctrl : string = 'A095';
  _buycancel: string = 'A100';
  _recomm   : string = 'A101';
  _reprint  : string = 'A102';

  _verzio   : string = '2900';

  _logir    : textFile;
  _olvas    : textFile;

  _host     : string;
  _port     : integer;

  _fild     : array[1..100] of string;
  _bytetomb : array[1..4096] of byte;

  _srec     : TSearchrec;

  _sendA,_sendB,_sendY: string;
  _mess,_ftfiller,_bizonylat,_lens,_LHis,_Llos,_messString,_reply,_pcs   : string;
  _logpath,_logFile,_mezostring,_txtreply,_aktmezo,_mondat,_deText,_hmess: string;
  _fmezo,_gmezo,_lmezo,_valutadir,_logdir,_minta,_logcim,_prosid,_prosnev: string;
  _subHmess,_htext,_amezo,_bmezo,_ymezo: string;

  _lrchi,_lrclo,_asc,_mezoss,_filledfield,_otpfuncType : byte;
  _lrckod,_messlen,_replen,_y,_top,_left,_width,_height: word;
  _aktev,_aktho,_aktnap: word;

  _fizetendo,_mLen,_mResult,_code: integer;

  _wm,_pp: word;
  _hKods,_bdekodolt: string;

  _sikeres,_elfogadva,_termOnline,_ujra: boolean;


function otpterminal: integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
                function otpterminal: integer; stdcall;
// =============================================================================

begin
   OtpTerm := TOtpterm.Create(Nil);
   result  := Otpterm.showmodal;
   Otpterm.free;
end;

// =============================================================================
               procedure TOTPTerm.FormActivate(Sender: TObject);
// =============================================================================

begin
  _width  := Screen.Monitors[0].width;
  _height := Screen.Monitors[0].Height;
  _left   := trunc((_width-810)/2);
  _top    := trunc((_height-562)/2);

  Top     := _top;
  Left    := _left;

  Clientwidth  := 810;
  ClientHeight := 562;

  OtpTerm.repaint;
  Image1.repaint;
  AlapPanel.repaint;

  _aktev := yearof(date);
  _aktho := monthof(date);
  _aktnap:= dayof(date);


  // Ez hülyeség, miért ne lenne VALUTA könyvtár:

  _valutadir := 'c:\valuta';
  if not DirectoryExists(_valutadir) then
    begin
      _valutadir := 'C:\TEMP';
      createdir(_VALUTADIR);
    end;

  // Ha nincs LOG könyvtár - akkor létrehoz egyet

  _logdir := _valutadir + '\log';
  if not DirectoryExists(_logdir) then Createdir(_logdir);


  // Ha méh ma nem volt logbejegyzés, akkor nyit egy üres LOG-file-t:

  _logfile := 'POS' + inttostr(_aktev-2000)+nulele(_aktho)+nulele(_aktnap)+'.log';
  _logpath := _logdir + '\' + _logfile;

  if not fileExists(_logpath) then
    begin
      Assignfile(_logir,_logpath);
      rewrite(_logir);
      closefile(_logir);
    end;

  // A terminál nincs ONLINE-ban még:

  _termonline := False;

  // Uzenõbox-ot kiüresiti:

  UzenoBox.Items.clear;
  Uzenobox.Clear;

  // Beolvassa az összes paramétert: POSPORT, POSHOST, IDKOD, PENZTARPSNEV
  //                                      OTPFUNCTYPE, BIZONYLAT, FIZETENDO

  AdatBeolvasas;

  // Beállitjuk a terminal paramétereit:

  idTcpClient1.Host := _host;
  idTcpClient1.Port := _port;

  // OtpFuncType alapján kiválasztja a kért sub-programot

  FunkcioValasztas;
end;

// =============================================================================
                      procedure TOtpTerm.FunkcioValasztas;
// =============================================================================


// OtpFuncType alapján belép a kivánt sub-procedurába

begin
  case _otpfuncType of

      0: Vasarlas;
      4: Aruvisszavet;
     50: PenztarosBelep;
     51: PenztarosKilepAndClose;
     60: TerminalZaras;
     90: ParaLetoltes;
     95: ComCtrl;
    100: Storno;
    102: RePrintRutin;
  end;
end;

// -----------------------------------------------------------------------------
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                   procedure TOtpterm.ComCtrl;
// =============================================================================

//         POS-terminál elérhetõségének ellenörzése:


begin
  // default = Nem elérhetõ !

  _mResult := 2;

  TranzCimPanel.caption := 'A POS TERMINÁL KOMMUNIKÁCIÓ ELLENÕRZÉSE';
  TranzcimPanel.repaint;

  with ComCtrlPanel do
    begin
      top     := 16;
      left    := 24;
      Visible := True;
      repaint;
    end;

  // Terminal-connect:

  _sikeres := Csatlakozas;

  if not _sikeres then
    begin
      Memoiro('Nem sikerült kapcsolódni a terminálhoz');
      sleep(2800);
      _mResult := 2;
      Kilepo.Enabled := True;
      exit;
    end;

  // Ctrl-uzenet kiküldése a terminálhoz.
     // A kiküldendõ parancs összeállitása

  _sendA := _termctrl;
  _sendB := '';
  _sendY := '';

  _mess := _termctrl + ETX;
  _messString := GetMessString(_mess);
  StringtoBytetomb(_messString);

  // A parancs kiküldése a terminálhoz

  if not CsomagKuldes then
    begin
      _subHmess := 'Sikertelen kommunikáció';
      Memoiro(_subhmess);
      sleep(2800);
      _mresult := 2;
      Kilepo.Enabled := true;
      exit;
    end;

  if _termOnline then idTCPclient1.Disconnect;

  if FildSelector(_reply) then
    begin
      Memoiro('Otp-terminál kapcsolat rendben van');
      ccHmessPanel.Color := clLime;
      ccHmessPanel.Font.Color := clteal;
      ccHmessPanel.caption := 'OTP KAPCSOLAT RENDBEN';
      ccHmesspanel.repaint;
      sleep(2800);
      _mResult := 1;
      Kilepo.Enabled := true;
      exit;
    end;

  ccHmessPanel.Caption    :=  'SIKERTELEN OTP KAPCSOLAT';
  ccHmessPanel.Color      := clRed;
  ccHmesspanel.Font.Color := clyellow;

  ccSubHmessPanel.Caption := _subhmess;
  ccHtextPanel.Caption    := _hText;

  ccHmessPanel.Repaint;
  ccSubHmessPanel.Repaint;
  cchTextPanel.repaint;

  MemoIro(_hmess);
  Memoiro(_subhmess);
  Memoiro(_hText);

  ComctrlPanel.repaint;
  sleep(2880);
  _mResult := 2;
  Kilepo.Enabled := true;
end;

// -----------------------------------------------------------------------------
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                          procedure TOtpTerm.Vasarlas;
// =============================================================================

begin
  if _fizetendo=0 then
    begin
      ShowMessage('Nincs kifizetendõ összeg');
      _Mresult := 2;
      Kilepo.Enabled := true;
      exit;
    end;

  if _bizonylat='' then
    begin
      ShowMessage('Nincs bizonylatszám !');
      _Mresult := 2;
      Kilepo.Enabled := True;
      exit;
    end;

  BizonylatEdit.Text := _bizonylat;
  FizetendoEdit.Text := FtForm(_fizetendo)+' Ft';

  BizonylatEdit.repaint;
  FizetendoEdit.repaint;

  TranzcimPanel.caption := 'FIZETÉS OTP TERMINÁLON KERESZTÜL';
  Tranzcimpanel.repaint;

  with VasarlasPanel do
    begin
      Top     := 16;
      Left    := 24;
      Visible := True;
      Repaint;
    end;

  _sendA := _vasarlas;
  _sendB := inttostr(_fizetendo)+'00';

  _ftfiller := 'B'+_sendB;

  _sendY := _bizonylat + '_' + _verzio;

  _mess := _vasarlas + FS + _ftfiller + FS + 'HABDEFKLMOPY' + FS;
  _mess := _mess + 'Y' + _sendY + ETX;

  _messString := GetMessString(_mess);
  StringtoBytetomb(_messString);

  _sikeres := Csatlakozas;
  if not _sikeres then
    begin
      _subhmess := 'Nem sikerült csatlakozni a terminálhoz';
      Memoiro(_subhmess);
      VasarCancel;
      exit;
    end;

  if not CsomagKuldes then
    begin
     _subhmess := 'Sikertelen kommunikáció';
      Memoiro(_subhmess);
      VasarCancel;
      exit;
    end;

  _elfogadva := FildSelector(_reply);
  if _elfogadva then
    begin
      MemoIro('BANK KÁRTYA ELFOGADVA');
      with VasarOkePanel do
        begin
          Left := 24;
          Top  := 16;
          visible := true;
          repaint;
        end;
      Activecontrol := VasarOkeGomb;
      exit;
    end;

  if _ujra then
    begin
      IF comrepeat then
        begin
          _elfogadva := true;
          MemoIro('BANK KÁRTYA ELFOGADVA');
          with VasarOkePanel do
            begin
              Left := 24;
              Top  := 16;
              visible := true;
              repaint;
            end;
          Activecontrol := VasarOkeGomb;
          exit;
        end;
    end;

  VasarCancel;
end;

// =============================================================================
                       procedure TOTPTerm.Vasarcancel;
// =============================================================================

begin

  HMessPanel.Caption    := _hMess;
  SubHmessPanel.Caption := _subHMess;
  HtextPanel.Caption    := _hText;

  Hmesspanel.repaint;
  SubHmessPanel.repaint;
  HtextPanel.repaint;

  with RejectPanel do
    begin
      Left    := 24;
      Top     := 16;
      Visible := True;
      repaint;
    end;

end;

// =============================================================================
           procedure TOTPTerm.VasarOkeGombClick(Sender: TObject);
// =============================================================================

begin
  VasarlasPanel.Visible := False;
  VasarOkePanel.Visible := false;
  _mResult := 1;
  Kilepo.Enabled := True;
end;


// =============================================================================
             procedure TOTPTerm.CashGombClick(Sender: TObject);
// =============================================================================

begin
  VasarlasPanel.Visible := False;
  RejectPanel.visible := False;
  _mresult := 3;
  Kilepo.Enabled := true;
end;


// =============================================================================
            procedure TOTPTerm.VasarCancelGombClick(Sender: TObject);
// =============================================================================

begin
  VasarlasPanel.Visible := False;
  Rejectpanel.Visible   := false;
  _mResult := 2;
  Kilepo.Enabled := True;
end;


// -----------------------------------------------------------------------------
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                       procedure TOTPTerm.Storno;
// =============================================================================

begin
  TranzCimPanel.caption := 'UTOLSÓ ÉRVÉNYES BIZONYLAT STORNÓZÁSA';
  TranzCimPanel.repaint;

  _hMess    := '';
  _subhMess := '';
  _htext    := '';

  StornoBizedit.Text := _bizonylat;
  StornoFtEdit.Text  := FtForm(_fizetendo)+' Ft';

  StornoBizEdit.repaint;
  StornoFtEdit.repaint;

  with StornoPanel do
    begin
      top     := 16;
      left    := 24;
      Visible := True;
      repaint;
    end;

  if _bizonylat='' then
    begin
      _subHMess := 'Nincs bizonylatszám !';
      Sleep(1000);
      StornoCancel;
      exit;
    end;

  _sendA := _buyCancel;
  _sendB := '';
  _sendY := _bizonylat + '_' + _verzio;
  _mess := _buycancel + FS + 'Y' + _sendY + ETX;

  _messString := GetMessString(_mess);
  StringToBytetomb(_messString);

  _sikeres := Csatlakozas;
  if not _sikeres then
    begin
      _subHMess := 'Nem sikerült kapcsolódni a terminálhoz';
      MemoIro(_subHMess);
      StornoCancel;
      Exit;
    end;

  if not CsomagKuldes then
    begin
      _subHMess := 'Sikertelen kommunikáció';
      Memoiro(_subHMess);
      StornoCancel;
      Exit;
    end;

  _sikeres := FildSelector(_reply);
  if _sikeres then
    begin
      MemoIro('Sikeres érvénytelenítés');
      with StornoOkePanel do
        begin
          Left    := 0;
          Top     := 120;
          visible := true;
          repaint;
        end;
      ActiveControl := StornoOkeGomb;
      exit;
    end;

  if _ujra then
    begin
      IF comrepeat then
        begin
          _sikeres := True;
          MemoIro('SIKERES ÉRVÉNYTELENÍTÉS');
          with StornoOkePanel do
            begin
              Left := 0;
              Top  := 120;
              visible := true;
              repaint;
            end;
          Activecontrol := StornoOkeGomb;
          exit;
        end;
    end;

  StornoCancel;
end;

// =============================================================================
                   procedure TOtpTerm.StornoCancel;
// =============================================================================

begin
  StHMessPanel.Caption    := _hMess;
  STSubHMessPanel.Caption := _subHMess;
  STHtextPanel.Caption    := _hText;

  StHMessPanel.repaint;
  StSubHMessPanel.repaint;
  StHTextPanel.repaint;

  with StornoCancelPanel do
    begin
      Left    := 0;
      Top     := 48;
      Visible := True;
      repaint;
    end;
  ActiveControl := StornoCancelGomb;
end;

// =============================================================================
           procedure TOTPTerm.StornoCancelGombClick(Sender: TObject);
// =============================================================================

begin
  StornoPanel.Visible       := False;
  StornoCancelPanel.Visible := False;
  _mResult := 2;
  Kilepo.Enabled := True;
end;

// =============================================================================
          procedure TOtpTerm.StornoOkeGombClick(Sender: TObject);
// =============================================================================

begin
  StornoPanel.Visible    := False;
  StornoOkePanel.Visible := False;
  _mResult := 1;
  Kilepo.Enabled := True;
end;


// -----------------------------------------------------------------------------
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// -----------------------------------------------------------------------------
// =============================================================================
                procedure TOtpterm.PenztarosKilepAndClose;
// =============================================================================

begin
  TranzCimPanel.caption := 'PÉNZTÁROS KILÉP - POS TERMINÁL ZÁR';
  TranzCimPanel.repaint;

  _hMess    := '';
  _subHMess := '';
  _hText    := '';

  with ProsKilepEsZarPanel do
    begin
      top     := 16;
      left    := 24;
      Visible := True;
      repaint;
    end;

  _sendA := _prosexit;
  _sendB := '';
  _sendY := '';

  _mess       := _prosExit + ETX;
  _messString := GetMessString(_mess);
  StringToBytetomb(_messString);

  _sikeres := Csatlakozas;
  if not _sikeres then
    begin
      _subHMess := 'Nem sikerült kapcsolódni a terminálhoz';
      MemoIro(_subHmess);
      ProskiCancel;
      exit;
    end;

  if not CsomagKuldes then
    begin
      _SubHMess := 'Sikertelen adatforgalom';
      MemoIro(_subHMess);
      ProskiCancel;
      exit;
    end;

  _sikeres := FildSelector(_reply);
  if _sikeres then
    begin
      MemoIro('Sikeres pénzáros kilépés és zárás');
      with PkOkePanel do
        begin
          top     := 64;
          left    := 0;
          Visible := true;
          repaint;
        end;
      ActiveControl := PkOkeGomb;
      exit;
    end;

  if _ujra then
    begin
      IF comrepeat then
        begin
          _sikeres := True;
          MemoIro('Sikeres pénztárzárás');
          with pkOkePanel do
            begin
              Left := 0;
              Top  := 64;
              visible := true;
              repaint;
            end;
          Activecontrol := PkOkeGomb;
          exit;
        end;
    end;

  ProskiCancel;
end;

// =============================================================================
                       procedure TOtpTerm.ProskiCancel;
// =============================================================================

begin
  pkHMessPanel.Caption    := _hMess;
  pkSubHMessPanel.Caption := _subHMess;
  pkHtextPanel.Caption    := _hText;

  pkHmessPanel.repaint;
  pkSubHmessPanel.repaint;
  pkHtextPanel.repaint;

  with PkCancelPanel do
    begin
      Left    := 0;
      Top     := 56;
      Visible := True;
      repaint;
    end;
  Activecontrol := PkCancelGomb;
end;

// =============================================================================
           procedure TOTPTerm.PkCancelGombClick(Sender: TObject);
// =============================================================================

begin
  ProsKilepEsZarPanel.Visible := False;
  PkCancelPanel.Visible := False;
  _mResult := 2;
  Kilepo.Enabled := True;
end;

// =============================================================================
          procedure TOTPTerm.PkOkeGombClick(Sender: TObject);
// =============================================================================

begin
  ProsKilepEsZarPanel.Visible := False;
  PkOkePanel.Visible := False;
  _mResult := 1;
  Kilepo.Enabled := True;
end;

// -----------------------------------------------------------------------------
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// -----------------------------------------------------------------------------
// =============================================================================
// =============================================================================
                     procedure TOtpTerm.PenztarosBelep;
// =============================================================================

begin
  TranzCimPanel.caption := 'PÉNZTÁROS BELÉPÉSE A POS-TERMINÁLBA';
  TranzCimPanel.repaint;

  _hMess    := '';
  _subHMess := '';
  _hText    := '';

  with ProsBelepPanel do
    begin
      top     := 16;
      left    := 24;
      Visible := True;
      repaint;
    end;

  if _prosId='' then
    begin
      _subhMess := 'NINCS PÉNZTÁROS ID-KÓD';
      sleep(1000);
      ProsBelepCancel;
      exit;
    end;

  NevEdit.Text := _prosNev;
  IdPanel.Caption  := _prosId;

  NevEdit.Repaint;
  idPanel.Repaint;

  with ProsBelepPanel do
    begin
      top     := 16;
      left    := 24;
      Visible := True;
      repaint;
    end;

  _sendA := _prosenter;
  _sendB := '';
  _sendY := '';

  _mess := _prosEnter + FS + 'M' + _prosId + ETX;
  _messString := GetMessString(_mess);
  StringToBytetomb(_messString);

  _sikeres := Csatlakozas;
  if not _sikeres then
    begin
      _subHMess := 'Nem sikerült kapcsolódni a terminálhoz';
      MemoIro(_subHMess);
      ProsBelepCancel;
      exit;
    end;

  if not CsomagKuldes then
    begin
      _subHMess := 'Sikertelen kommunikáció';
      MemoIro(_subhmess);
      ProsBelepCancel;
      exit;
    end;

  _sikeres := FildSelector(_reply);
  if _sikeres then
    begin
      MemoIro('A PÉNZTÁROS BELÉPTETVE');
      with PbOkePanel do
        begin
          top     := 120;
          left    := 24;
          Visible := true;
          Repaint;
        end;
      ActiveControl := PbOkeGomb;
      exit;
    end;

  if _ujra then
    begin
      IF comrepeat then
        begin
          _sikeres := True;
          MemoIro('PÉNZTÁROS BELÉPTETVE');
          with pbOkePanel do
            begin
              Left := 24;
              Top  := 120;
              visible := true;
              repaint;
            end;
          Activecontrol := PbOkeGomb;
          exit;
        end;
    end;

  ProsBelepCancel;
end;

// =============================================================================
                      procedure TOtpTerm.ProsBelepCancel;
// =============================================================================

begin
  PbHMessPanel.Caption := _hMess;
  PbSubHmessPanel.caption :=_subHMess;
  PbHTextPanel.Caption := _hText;

  PbHMessPanel.Repaint;
  PbsubHMessPanel.Repaint;
  PbhtextPanel.Repaint;

  with PbCancelPanel do
    begin
      top     := 64;
      left    := 24;
      Visible := True;
      Repaint;
    end;
  ActiveControl := PBCancelGomb;
end;

// =============================================================================
          procedure TOTPTerm.PBCancelGombClick(Sender: TObject);
// =============================================================================

begin
  ProsBelepPanel.Visible := False;
  PbCancelpanel.Visible := False;
  _mResult := 2;
  Kilepo.Enabled := True;
end;

// =============================================================================
             procedure TOTPTerm.PBOkeGombClick(Sender: TObject);
// =============================================================================

begin
  ProsBelepPanel.Visible := False;
  PbOkePanel.Visible := False;
  _mResult := 1;
  Kilepo.Enabled := True;
end;

// -----------------------------------------------------------------------------
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// -----------------------------------------------------------------------------
// =============================================================================
                    procedure TOtpTerm.TerminalZaras;
// =============================================================================

begin
  TranzCimPanel.caption := 'OTP POS-TERMINÁL LEZÁRÁSA';
  TranzCimPanel.repaint;

  _hMess    := '';
  _subHMess := '';
  _hText    := '';

  with TermclosePanel do
    begin
      top     := 136;
      left    := 298;
      Visible := True;
      repaint;
    end;

  _sendA := _termclose;
  _sendB := '';
  _sendY := '';

  _mess := _termclose + ETX;
  _messString := GetMessString(_mess);
  StringtoBytetomb(_messString);

  _sikeres := Csatlakozas;

  if not _sikeres then
    begin
      _subHmess := 'Nem sikerült kapcsolódni a terminálhoz';
      MemoIro(_subHmess);
      CloseCancel;
      exit;
    end;

  if not CsomagKuldes then
    begin
      _subHmess := 'Sikertelen kommunikáció';
      Memoiro(_subhmess);
      CloseCancel;
      exit;
    end;

  if _termOnline then idTCPclient1.Disconnect;

  if FildSelector(_reply) then
    begin
      Memoiro('Otp-terminál sikeresen lezárva');
      with CLoseOkePanel do
        begin
          top := 48;
          left := 0;
          Visible := true;
          repaint;
        end;
      Activecontrol := closeokegomb;
      exit;
    end;

  if _ujra then
    begin
      IF comrepeat then
        begin
          _sikeres := True;
          MemoIro('Otp-terminál sikeresen lezárva');
          with CloseOkePanel do
            begin
              Left := 0;
              Top  := 48;
              visible := true;
              repaint;
            end;
          Activecontrol := CloseOkeGomb;
          exit;
        end;
    end;

 CloseCancel;
end;


// =============================================================================
                    procedure TOTPTerm.CLoseCancel;
// =============================================================================

begin
  ClHMessPanel.Caption := _hMess;
  ClSubHmessPanel.caption :=_subHMess;
  CLHTextPanel.Caption := _hText;

  ClHMessPanel.Repaint;
  ClsubHMessPanel.Repaint;
  CLhtextPanel.Repaint;

  with CloseCancelPanel do
    begin
      top     := 48;
      left    := 0;
      Visible := True;
      Repaint;
    end;
  ActiveControl := clCancelGomb;
end;

// =============================================================================
            procedure TOTPTERM.CLCANCELGOMBClick(Sender: TObject);
// =============================================================================

begin
  TermClosePanel.Visible := False;
  CloseCancelPanel.visible := False;
  _mResult := 2;
  Kilepo.Enabled := true;
end;

// =============================================================================
            procedure TOTPTERM.CLOSEOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  TermClosePanel.Visible := False;
  CloseOkePanel.visible := False;
  _mResult := 1;
  Kilepo.Enabled := true;
end;


// -----------------------------------------------------------------------------
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// -----------------------------------------------------------------------------
                       procedure TOtpTerm.ReprintRutin;
// =============================================================================

begin
  _mess := _reprint + ETX;
  _messString := GetMessString(_mess);
  StringtoBytetomb(_messString);

  _sikeres := Csatlakozas;

  if _sikeres then csomagkuldes;
   
  _mResult := 1;
  Kilepo.Enabled := True;
end;



// -----------------------------------------------------------------------------
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// -----------------------------------------------------------------------------
                       procedure TOtpTerm.Aruvisszavet;
// =============================================================================

begin
  if _fizetendo=0 then
    begin
      ShowMessage('Nincs átutalandó összeg');
      _Mresult := 2;
      Kilepo.Enabled := true;
      exit;
    end;

  if _bizonylat='' then
    begin
      ShowMessage('Nincs bizonylatszám !');
      _Mresult := 2;
      Kilepo.Enabled := True;
      exit;
    end;

  BizPanel.caption := _bizonylat;
  BizPanel.repaint;

  VisszaFtEdit.Text := FtForm(_fizetendo)+' Ft';
  VisszaFtEdit.repaint;

  with AruvisszavetPanel do
    begin
      Top     := 16;
      Left    := 24;
      Visible := True;
      Repaint;
    end;

  _sikeres := Csatlakozas;

  if not _sikeres then
    begin
      Memoiro('Nem sikerült kapcsolódni a terminálhoz');
      sleep(2800);
      _mResult := 2;
      Kilepo.Enabled := True;
      exit;
    end;

  _sendA := _backPay;
  _sendB := inttostr(_fizetendo)+'00';
  _sendY := _bizonylat + '_' + _verzio;

  _ftfiller := 'B' + _sendB;
  _mess := _backpay + FS + _ftfiller + FS + 'HABDEFKLMOPY' + FS;
  _mess := _mess + 'Y' + _sendY + ETX;

  _messString := GetMessString(_mess);
  StringtoBytetomb(_messString);

  if not CsomagKuldes then
    begin
      _subHmess := 'Sikertelen kommunikáció';
      Memoiro(_subhmess);
      sleep(2800);
      _mresult := 2;
      Kilepo.Enabled := true;
      exit;
    end;

  if _termOnline then idTCPclient1.Disconnect;

  _sikeres := FildSelector(_reply);
  if _sikeres then
    begin
      MemoIro('Sikeres áruvisszavétel');
      with AruVisszaOkePanel do
        begin
          Left    := 0;
          Top     := 0;
          visible := true;
          repaint;
        end;
      ActiveControl := AruVisszaOkeGomb;
      exit;
    end;

  if _ujra then
    begin
      IF comrepeat then
        begin
          _sikeres := True;
          MemoIro('Sikeres áruvisszavétel');
          with AruVisszaOkePanel do
            begin
              Left := 0;
              Top  := 0;
              visible := true;
              repaint;
            end;
          Activecontrol := AruvisszaOkeGomb;
          exit;
        end;
    end;

  AruvisszaCancel;
end;

// =============================================================================
                     procedure TOtpTerm.AruvisszaCancel;
// =============================================================================

begin
  AvHMessPanel.Caption := _hMess;
  AvSubHmessPanel.caption :=_subHMess;
  AvHTextPanel.Caption := _hText;

  AvHMessPanel.Repaint;
  AvsubHMessPanel.Repaint;
  AvhtextPanel.Repaint;

  with AruVisszaCancelPanel do
    begin
      top := 0;
      left := 0;
      Visible := true;
      repaint;
    end;

  Activecontrol := AruVisszaCancelGomb;

end;

procedure TOtpTerm.AruvisszaOkeGombClick(Sender: TObject);

begin
  Aruvisszavetpanel.Visible := false;
  AruvisszaOkePanel.visible := False;
  _mResult := 1;
  Kilepo.enabled := true;
end;

// =============================================================================
           procedure TOTPTerm.AruvisszaCancelGombClick(Sender: TObject);
// =============================================================================

begin
  AruvisszavetPanel.Visible    := False;
  AruvisszaCancelPanel.Visible := False;
  _mResult := 2;
  Kilepo.Enabled := True;
end;



// -----------------------------------------------------------------------------
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// -----------------------------------------------------------------------------
                      procedure TOtpTerm.Paraletoltes;
// =============================================================================

begin
  with ParaLetoltoPanel do
    begin
      top := 16;
      left := 24;
      Visible := True;
      repaint;
    end;

  _sendA := _paraload;
  _sendB := '';
  _sendY := '';

  _mess := _paraload + ETX;
  _messString := GetMessString(_mess);
  StringtoBytetomb(_messString);

  _sikeres := Csatlakozas;

  if not _sikeres then
    begin
      _Lmezo := 'Nem sikerült kapcsolódni a terminálhoz';
      MemoIro(_subHmess);
      PloadCancel;
      exit;
    end;

  if not CsomagKuldes then
    begin
      _Lmezo := 'Sikertelen kommunikáció';
      Memoiro(_subhmess);
      PloadCancel;
      exit;
    end;

  if _termOnline then idTCPclient1.Disconnect;

  if FildSelector(_reply) then
    begin
      Memoiro('Sikeres paraméter letöltés');
      with PlOkePanel do
        begin
          top     := 0;
          left    := 0;
          Visible := true;
          repaint;
        end;
      Activecontrol := Plokegomb;
      exit;
    end;

  if _ujra then
    begin
      IF comrepeat then
        begin
          MemoIro('Sikeres paraméter letöltés');
          with plOkePanel do
            begin
              Left := 0;
              Top  := 0;
              visible := true;
              repaint;
            end;
          Activecontrol := PlOkeGomb;
          exit;
        end;
    end;

 PloadCancel;
end;

// =============================================================================
                       procedure TOtpTerm.PLoadCancel;
// =============================================================================

begin
//  pLHMessPanel.Caption    := _hMess;
  pLSubHMessPanel.Caption := _Lmezo;
//  pLHtextPanel.Caption    := _hText;

//  pLHmessPanel.repaint;
  pLSubHmessPanel.repaint;
//  pLHtextPanel.repaint;

  with PLCancelPanel do
    begin
      Left    := 0;
      Top     := 56;
      Visible := True;
      repaint;
    end;
  Activecontrol := PLCancelGomb;
end;

// =============================================================================
           procedure TOTPTerm.PLCancelGombClick(Sender: TObject);
// =============================================================================

begin
  ParaletoltoPanel.Visible := False;
  PLCancelPanel.Visible := False;
  _mResult := 2;
  Kilepo.Enabled := True;
end;

// =============================================================================
          procedure TOTPTerm.PLOkeGombClick(Sender: TObject);
// =============================================================================

begin
  ParaletoltoPanel.Visible := False;
  PLOkePanel.Visible := False;
  _mResult := 1;
  Kilepo.Enabled := True;
end;

// -----------------------------------------------------------------------------
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// -----------------------------------------------------------------------------
// =============================================================================
               function TOtpTerm.Csatlakozas: boolean;
// =============================================================================

begin
  Result := False;
  TRY
    LogWrite('  TO POS:CONNECT');
    MemoIro('Kapcsolódás a POS - terminálhoz');
    idTcpClient1.Connect;
    Result := True;
  EXCEPT
    ON E: exCeption DO MemoIro(E.message);
  END;
end;


// =============================================================================
                    function TOTPTerm.CsomagKuldes: boolean;
// =============================================================================

// Paraméter: bytetomb,_mlen

begin
  Result := False;
  MemoIro('Tranzakció adatainak küldése');
  _deText := DeKonv(_messString);
  logWrite('  TO POS:' + _deText);

  _sikeres := True;

  TRY
    idTcpClient1.WriteBuffer(_bytetomb,_mlen,_sikeres);
  except
    ON E: exception do MemoIro(E.Message);
  END;

  MemoIro('Sikeres kommunikáció');

  TRY
    _Reply := idTcpClient1.AllData;
  EXCEPT
    on E: exception do MemoIro(E.message);
  END;

  _reply  := trim(_reply);
  _repLen := length(_reply);

  IF _repLen=0 then
    begin
      MemoIro('Üres válasz érkezett');
      exit;
    end;

  MemoIro('Megérkezett a válasz');

  _y := 1;
  while _y<=_repLen do
    begin
      _bytetomb[_y] := ord(_reply[_y]);
      inc(_y);
    end;

  _txtReply := deKonv(_reply);
  LogWrite('FROM POS:'+_txtreply);
  Result := True;
end;


// $$$$$$$$$$$$$$$$$$$$$  egyéb rutinok, funkciók $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                   procedure TOtpTerm.AdatBeolvasas;
// =============================================================================

begin
  _pcs := 'SELECT * FROM HARDWARE';
  ValutaDbase.Connected := true;

  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.add(_pcs);
      Open;
      _host    := trim(FieldbyName('POSHOST').asString);
      _port    := FieldByNAme('POSPORT').asInteger;
      _prosId  := trim(FieldByNAme('IDKOD').asString);
      _prosNev := trim(FieldByNAme('PENZTAROSNEV').AsString);
      Close;
    end;

  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM VTEMP');
      Open;
      _otpFuncType := FieldByNAme('OTPFUNCTYPE').asInteger;
      _bizonylat   := trim(FieldByNAme('BIZONYLATSZAM').asString);
      _fizetendo   := FieldByNAme('FIZETENDO').asInteger;
      Close;
    end;
  ValutaDbase.close;
end;

// =============================================================================
                function TOtpTerm.GetmessString(_m: string): string;
// =============================================================================

begin

  _LrcKod := GetLrcKod(_m);
  _LrcHi  := trunc(_Lrckod/16);
  _LrcLo  := _Lrckod-trunc(16*_LRchi);

  _LrcHi := 48 + _LrcHi;
  if _LrcHi>57 then _LrcHi :=_LrcHi+7;

  _LrcLo := _Lrclo +48;
  if _Lrclo>57 then _Lrclo := _LrcLo+7;

  _LHis := chr(_LrcHi);
  _LLos := chr(_LrcLo);

  _m := STX + _m + _LHis + _LLos;

  _messLen := length(_m);
  _lens := inttostr(_messlen);

  while length(_lens)<4 do _lens := '0' + _lens;

  Result := _lens + _m;
end;

// =============================================================================
               procedure TOtpTerm.StringToBytetomb(_m: string);
// =============================================================================

begin
  _mLen := Length(_messString);

  _y := 1;
  while _y<=_mLen do
    begin
      _asc := ord(_messString[_y]);
      _bytetomb[_y] := _asc;
      inc(_y);
    end;
end;


// =============================================================================
           function TOtpTerm.FildSelector(_ry: string): boolean;
// =============================================================================

VAR I: byte;

begin
  Result    := False;
  _ujra     := False;
  _hMess    := '';
  _subHmess := '';
  _hText    := '';

  for i := 1 to 100 do _fild[i] := '';

  if not ReplyControl(_ry) then
    begin
      _ujra := True;
      exit;
    end;

  _wm    := length(_ry);

  //  A mutató a STX utáni byte-ra mutat:

  _pp := 6;  // A pp-mutató a STX utáni byte-ra mutat

  // A betü jelzi az adatsorszámot: (pl A=1, B=2, C=3  etc ....

  _mezoss := ord(_ry[_pp])-64;

  _mezoString := '';
  inc(_pp);

  while _pp<=_wm do
    begin
      _asc := ord(_ry[_pp]);

      // Ha az aktuális karakter (_asc) nem vezérlõkarakter, akkor az adat betüje
      if _asc>31 then
        begin
          _mezoString := _mezoString + chr(_asc);
        end else
        begin
          if (_asc=ord(FS)) OR (_asc=ord(ETX)) then
            begin
              _fild[_mezoss] := _mezoString;
              _mezoString := '';

              if _asc=ord(FS) then
                begin
                  inc(_pp);
                  _mezoSs := ord(_ry[_pp])-64;
                end;
              if _asc=ord(ETX) then break;
            end;
        end;
      inc(_pp);
    end;

  _amezo := _Fild[1];
  _bmezo := _Fild[2];
  _Fmezo := _Fild[6];
  _Gmezo := _Fild[7];
  _Lmezo := _Fild[12];
  _Ymezo := _fild[25];

  if (length(_fmezo))>10 then _fMezo := leftstr(_fmezo,10);
  if (length(_gmezo))>10 then _gMezo := leftstr(_gmezo,10);

  _pcs := 'UPDATE VTEMP SET FMEZO='+chr(39)+_fmezo+chr(39);
  _pcs := _pcs + ',GMEZO=' + chr(39) + _gmezo + chr(39);
  ValutaParancs(_pcs);

  if _fmezo='' then
    begin
      _subhmess := 'NINCS FMEZÕ';
      _ujra := true;
      exit;
    END;


  if _sendA<>'A'+_aMezo then
    begin
      _subhmess := 'NEM EGYEZIK A PARANCS MEZÕ';
      _ujra := true;
      exit;
    end;

  if _sendB<>'' then
    begin
      _bdekodolt := leftzerolevag(_bMezo);
      if _bdekodolt<>_sendb then
        begin
          _ujra := true;
          _subHmess := 'NEM EGYEZIK AZ ÖSSZEG';
          exit;
        end;
    end;

  if _sendY<>'' then
    begin
      if _sendY<>_Ymezo then
        begin
          _ujra := true;
          _subHmess := 'NEM EGYEZIK AZ Y-mezõ';
          exit;
        end;
    end;

  if _amezo='090' then
    begin
      if _fmezo='880' then RESULT := True;
      exit;
    end;

  if (leftstr(_fMezo,2)='00') or (_fMezo='L00') then
    begin
      result := true;
      exit;
    end;

  // ------------------- innen negativ válasz érkezett -------------------------

  if leftstr(_fMezo,1)<>'L' then // nem lokális hiba !
    begin
      _hKods := midstr(_fmezo,2,3);
      _htext := GetHibaText(_hkods);
      exit;
    end;

  _wm := length(_fMezo);
  _hKods := midstr(_fMezo,2,_wm-1);
  _hMess := GetHmess(_hKods);

  if _fMezo='L54' then
    begin
     if _gMezo<>'' then _subHMess := GetSubHMess54(_gMezo);
    end;

  if _fMezo='L90' then
    begin
      if _gMezo<>'' then _subHMess := GetSubHMess90(_gMezo);
    end;

  _hText := trim(_Lmezo);
end;


// =============================================================================
               function TOtpTerm.Dekonv(_s: string): string;
// =============================================================================

var _ws: word;
    _y : word;
    _ps: string;

begin
  Result := '';

  _ws := length(_s);
  _y := 1;

  while _y<=_ws do
    begin
      _asc := ord(_s[_y]);
      if _asc>30 then _ps := chr(_asc)
      else _ps := kodSeek(_asc);
      Result := Result + _ps;
      inc(_y);
    end;
end;

// =============================================================================
              function TOtpTerm.Kodseek(_a: byte): string;
// =============================================================================

begin
  if _a=2  then Result := '<STX>';
  if _a=3  then Result := '<ETX>';
  if _a=28 then Result := '<FS>';
end;

// =============================================================================
               function TOtpTerm.GetLrcKod(_m: string): word;
// =============================================================================

begin
  asm
    push ebx
    push esi
    push edi
    push edx
    push ebx
    push eax

    mov ebx,0
    mov edx,_m
    cmp edx,0
    jz @vege

    @ciklus:
    mov al,byte ptr[edx];
    cmp al,0
    je @vege

    xor bl,al
    inc dx
    jmp @ciklus

    @vege:
    mov bh,0
    mov result,bx

    pop eax
    pop ebx
    pop edx
    pop edi
    pop esi
    pop ebx
  end;
end;


// =============================================================================
            function TOTPTerm.FtForm(_ft: integer): string;
// =============================================================================

var _fts: string;
    _ftlen,_f1: byte;

begin
  Result :='';
  if _ft=0 then exit;

  if _ft<1000 then
    begin
      Result := inttostr(_ft);
      exit;
    end;

  _fts   := inttostr(_ft);
  _ftLen := length(_fts);

  if _ftLen<7 then
    begin
      _f1 := _ftlen-3;
      Result := leftstr(_fts,_f1)+'.'+midstr(_fts,_f1+1,3);
      exit;
    end;
  _f1 := _ftLen-6;
  Result := leftstr(_fts,_f1)+'.'+midstr(_fts,_f1+1,3)+'.'+midstr(_fts,_f1+4,3);
end;


// =============================================================================
              function TOtpTerm.Nulele(_b: byte): string;
// =============================================================================

begin
  Result := inttostr(_b);
  if _b<10 then Result := '0' + Result;
end;

// =============================================================================
              procedure TotpTerm.LogWrite(_lgMess: string);
// =============================================================================

var _stamp: string;

begin
  _stamp := GetStamp;

  AssignFile(_logir,_logPath);
  Append(_logir);
  writeLn(_logir,_stamp+': '+_lgMess);
  Closefile(_logir);
end;

// =============================================================================
                    function TOTPTerm.GetStamp: string;
// =============================================================================


var _xtm: TDatetime;
    _xy,_xm,_xd,_xh,_xP,_xs,_xt: word;
    _rs,_xts: string;

begin
  _xtm := now;
  DecodeDateTime(_xtm,_xy,_xm,_xd,_xh,_xp,_xs,_xt);
  _rs := inttostr(_xy)+'.'+nulele(_xm)+'.'+nulele(_xd)+' '+nulele(_xh);
  _xts := inttostr(_xt);
  while length(_xts)<3 do _xts := '0' + _xts;
  Result := _rs + ':'+nulele(_xp)+':'+nulele(_xs)+'_'+_xts;
end;


// =============================================================================
                 procedure TOTPTerm.MemoIro(_text: string);
// =============================================================================

begin
  UzenoBox.items.add(_text);
  UzenoBox.repaint;
end;


// =============================================================================
              function TOtpTerm.getHibaText(_hks: string): string;
// =============================================================================

var _hk: word;

begin
  result := '';
  val(_hks,_hk,_code);
  case _hk of
    201: result := 'HIBÁS PIN KÓD';
    89: result  := 'ZÁROLT KÁRTYA';
    52: result  := 'SOK HIBÁS PIN-KÓD';
    76: result  := 'NINCS FEDEZETE';
  end;
end;



// =============================================================================
           function TOTPterm.GetHMess(_kods: string): string;
// =============================================================================

var _hibakod: byte;

begin
  Result := '';

  val(_kods,_hibaKod,_code);
  if _code<>0 then exit;

  case _hibaKod of
     0: result := 'Tranzakció rendben';
     1: result := 'Adatátviteli hiba';
     2: result := 'PIN PAD-en piros vagy sárga gombot nyomott';
     9: result := 'Küldött string nem jelenithetõ meg';
    10: result := 'Zárja be a terminált !';
    11: result := 'Kifogyott a papir';
    20: result := 'Stornó igény érvénytelen';
    21: result := 'Nem engedélyezett tranzakció';
    22: result := 'Tranzakció ismétlés';
    23: result := 'Nem engedélyezett stornó';
    24: result := 'Sikertelen küldés';
    25: result := 'Ügyfél nem hagyta jóvá az összeget';
    29: result := 'Kártyát kivették a tranzakció alatt';
    30: result := 'Nem ismert pénztáros';
    31: result := 'Pénztáros már létezik';
    32: result := 'Pénztáros már be van jelentkezve';
    33: result := 'Pénztáros nincs bejelentkezve';
    54: result := 'Tranzakció megszakitva';
    56: result := 'Használhatatlan kártya';
    57: result := 'Lejárt kártya';
    58: result := 'Hibásan beolvasott kártya';
    59: result := 'Ismeretlen kártya';
    60: result := 'Tiltott kártya ! Bevonandó !';
    61: result := 'Tiltott kártya ! Nem kell bevonni';
    80: result := 'Nyomtató vita';
    90: result := 'Foglalt státusz';
    97: result := 'Hibás LRC-kód az üzenetben';
    99: result := 'Formai hiba az üzenetben';
  end;
end;


// =============================================================================
             function TOTPTerm.GetSubHmess54(_g: string): string;
// =============================================================================


var _gkod: byte;

begin
  Result := '';
  val(_g,_gkod,_code);
  case _gkod of

     0: result := 'A kezelõ a kártyabehúzást megszakította';
     1: result := 'A kezelõ az összeg megadását megszakította';
     2: result := 'A kezelõ vagy az ügyfél az összeget  nem hagyta jóvá';
     3: result := 'Az ügyfél a PIN megadását megszakította';
     4: result := 'A kezelõ a számlatípus megadását megszakította';
     5: result := 'Az ügyfél a számlatípust nem hagyta jóvá';
     6: result := 'A hivatkozás megadását megszakította';
     7: result := 'A kezelõ a TeleBank – Házibank tranzakció adatait nem adta meg';
     8: result := 'A kezelõ az engedélyszám megadását megszakította vagy idõtúllépés';
    10: result := 'A kártyabehúzásra szánt idõ alatt a kártyabehúzás nem történt meg';
    11: result := 'Az összeg megadására szánt idõ alatt a megadás nem történt meg';
    12: result := 'Az összeg jóváhagyására szánt idõ alatt a jóváhagyás nem történt meg';
    13: result := 'A PIN megadására szánt idõ alatt a megadás nem történt meg';
    14: result := 'A számlatípus megadására szánt idõ alatt a megadás nem történt meg';
    15: result := 'A számlatípus jóváhagyására szánt idõ alatt a jóváhagyás nem történt meg';
    16: result := 'A hivatkozás jóváhagyására szánt idõ alatt a jóváhagyás nem történt meg';
    17: result := 'PIN PAD kommunikációs hiba';
    18: result := 'Referál után a kezelo nem kért vagy nem kapott engedélyszámot';
    19: result := 'Az aláírást a pénztáros nem fogadta el, a terminál a tranzakciót megreverzálta';
  end;
end;

// =============================================================================
            function TOTPTerm.GetSubHmess90(_g: string): string;
// =============================================================================

var _gkod: byte;

begin
  Result := '';
  val(_g,_gkod,_code);
  case _gkod of
    50: result := 'Távolítsa el a kártyát a chip olvasóból!';
    51: result := 'Nyomtatás folyamatban';
    52: result := 'Elõzõ tranzakció még nem zárult le';
  end;
end;

// =============================================================================
          procedure TOTPTerm.IdTCPClient1Connected(Sender: TObject);
// =============================================================================

begin
  MemoIro('Csatlakoztam a POS-Terminálhoz');
  _termonline := True;
  LogWrite('FROM POS:CONNECTED');
end;

// =============================================================================
         procedure TOTPTerm.IdTCPClient1Disconnected(Sender: TObject);
// =============================================================================

begin
  MemoIro('Lekapcsolódtam a POS-terminálról');
  _termOnLine := False;
  logWrite('FROM POS:DISCONNECTED');
end;

// =============================================================================
             procedure TOTPTerm.KilepoTimer(Sender: TObject);
// =============================================================================

begin
  if _termOnline then idTCPclient1.Disconnect;
  Kilepo.Enabled := False;
  Modalresult := _mResult;
end;

// =============================================================================
          function TOTPTerm.LeftZeroLevag(_bes: string): string;
// =============================================================================

var _ws,_y,_asc: byte;

begin
  result := '';
  _ws := length(_bes);
  _y := 1;
  _asc := 0;
  while _y<=_ws do
    begin
      _asc := ord(_bes[_y]);
      if _asc<>48 then break;
      inc(_y);
    end;

  result := char(_asc);
  inc(_y);
  while _y<=_ws do
    begin
      _asc := ord(_bes[_y]);
      result := result + chr(_asc);
      inc(_y);
    end;
end;

// =============================================================================
             procedure TOtpTerm.Valutaparancs(_ukaz: string);
// =============================================================================

begin
  valutadbase.connected := True;
  if valutatranz.InTransaction then valutatranz.Commit;
  Valutatranz.StartTransaction;
  with valutaquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  Valutatranz.Commit;
  Valutadbase.close;
end;

// =============================================================================
             function TOtpterm.ReplyCOntrol(_rs: string): boolean;
// =============================================================================

var _ctmess,_ctkods,_numctkod: string;
    _ctlrc,_ctLrcHi,_ctLrcLo: word;

begin
  result := False;

  _wm := length(_rs);
  _ctmess := midstr(_rs,6,_wm-7);
  _ctkods := midstr(_rs,_wm-1,2);

  _ctLrc   := GetLrcKod(_ctmess);
  _ctLrcHi := trunc(_ctLrc/16);
  _ctLrcLo := _ctLrc-trunc(16*_ctLRchi);

  _ctLrcHi := 48 + _ctLrcHi;
  if _ctLrcHi>57 then _ctLrcHi :=_LrcHi+7;

  _ctLrcLo := _ctLrclo +48;
  if _ctLrclo>57 then _ctLrclo := _ctLrcLo+7;

  _numctkod := chr(_ctLrcHi)+chr(_ctLrcLo);

  if _numctkod=_ctkods then
    BEGIN
      result := true;
      exit;
    end;

  _subhmess := 'HIBÁS LRC A VÁLASZBAN';
end;

// =============================================================================
                   function TOTpTerm.Comrepeat: boolean;
// =============================================================================

begin
  result := False;

  Memoiro(_subhmess);
  MemoIro('ÚJRA PRÓBÁLKOZOM');

  _mess := _recomm + ETX;
  _messString := GetMessString(_mess);

  StringtoBytetomb(_messString);

  _sikeres := Csatlakozas;

  if not _sikeres then
    begin
      _subHmess := 'Nem sikerült kapcsolódni a terminálhoz';
      MemoIro(_subHmess);
      exit;
    end;

  if not CsomagKuldes then
    begin
      _subHmess := 'Sikertelen kommunikáció';
      Memoiro(_subhmess);
      exit;
    end;

  if _termOnline then idTCPclient1.Disconnect;

  if FildSelector(_reply) then Result := true;

end;
procedure TOTPTERM.VREPGOMBClick(Sender: TObject);
begin
  RePrintRutin;
end;


end.

