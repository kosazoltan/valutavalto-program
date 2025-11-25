unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, ComCtrls, jpeg, IBDatabase, DB,
  IBCustomDataSet, IBQuery, IBTable, wininet, strutils;

type
  TSETUPFORM = class(TForm)
    SP1: TPanel;
    PFUNC: TRadioButton;
    EFUNC: TRadioButton;
    AFUNC: TRadioButton;
    Label1: TLabel;
    Shape2: TShape;
    SP2: TPanel;
    Label2: TLabel;
    VVBOX: TCheckBox;
    WUBOX: TCheckBox;
    TAFABOX: TCheckBox;
    MAFABOX: TCheckBox;
    EKERBOX: TCheckBox;
    Shape3: TShape;
    SP4: TPanel;
    Label4: TLabel;
    JELSZOEDIT: TEdit;
    JELSZOPANEL: TPanel;
    Shape5: TShape;
    SP5: TPanel;
    Label5: TLabel;
    ZOLD: TRadioButton;
    PIROS: TRadioButton;
    SARGA: TRadioButton;
    ZOLDPANEL: TPanel;
    Image1: TImage;
    SARGAPANEL: TPanel;
    Image2: TImage;
    PIROSPANEL: TPanel;
    Image3: TImage;
    Shape6: TShape;
    SP6: TPanel;
    Label6: TLabel;
    futofenypanel: TPanel;
    SPEED: TTrackBar;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Shape7: TShape;
    SP7: TPanel;
    Label10: TLabel;
    Label11: TLabel;
    KPPANEL: TPanel;
    Label12: TLabel;
    Panel13: TPanel;
    MINCSUSZKA: TTrackBar;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Shape8: TShape;
    SP8: TPanel;
    Label19: TLabel;
    NOFEERADIO: TRadioButton;
    EZRELEKRADIO: TRadioButton;
    SAVRADIO: TRadioButton;
    ezreleklap: TPanel;
    Label20: TLabel;
    EZRELEKEDIT: TEdit;
    Label21: TLabel;
    EZRELEKPANEL: TPanel;
    Label22: TLabel;
    maxedit: TEdit;
    Label23: TLabel;
    EZRELEKMODYGOMB: TBitBtn;
    Shape9: TShape;
    SP9: TPanel;
    Label24: TLabel;
    Shape10: TShape;
    SP10: TPanel;
    Label25: TLabel;
    LPTPORT: TRadioButton;
    USBPORT: TRadioButton;
    Shape11: TShape;
    SP11: TPanel;
    Label26: TLabel;
    NOADS: TRadioButton;
    ISADS: TRadioButton;
    Shape12: TShape;
    Label28: TLabel;
    pwmodygomb: TPanel;
    Label29: TLabel;
    EMAILEDIT: TEdit;
    Label30: TLabel;
    SATOPEN: TRadioButton;
    SATCLOSED: TRadioButton;
    VALUTATABLA: TIBTable;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    ALAPPANEL: TPanel;
    Shape15: TShape;
    Shape16: TShape;
    Shape17: TShape;
    Label33: TLabel;
    Label34: TLabel;
    MP1: TPanel;
    MP2: TPanel;
    MP3: TPanel;
    MP4: TPanel;
    MP5: TPanel;
    MP6: TPanel;
    MP7: TPanel;
    MP8: TPanel;
    MP9: TPanel;
    MP10: TPanel;
    MP11: TPanel;
    SAVEGOMB: TBitBtn;
    NOMODYGOMB: TBitBtn;
    QUITGOMB: TBitBtn;
    Shape1: TShape;
    kilepotimer: TTimer;
    Image4: TImage;
    Label31: TLabel;
    FFDBEDIT: TEdit;
    TXT1: TPanel;
    TXT2: TPanel;
    FCP1EDIT: TEdit;
    FCP2EDIT: TEdit;
    reklampanel: TPanel;
    RL1: TCheckBox;
    RL2: TCheckBox;
    RL3: TCheckBox;
    RL4: TCheckBox;
    RL5: TCheckBox;
    MM1: TBitBtn;
    MM2: TBitBtn;
    MM3: TBitBtn;
    MM4: TBitBtn;
    MM5: TBitBtn;
    LT1: TBitBtn;
    LT2: TBitBtn;
    LT3: TBitBtn;
    LT4: TBitBtn;
    LT5: TBitBtn;
    DISPPANEL: TPanel;
    visszagomb: TBitBtn;
    VASZON: TImage;
    CSAKARFRADIO: TRadioButton;
    CSAKTEXTRADIO: TRadioButton;
    VEGYESRADIO: TRadioButton;
    Bevel1: TBevel;
    TEXTEDITGOMB: TBitBtn;
    TEXTEDITPANEL: TPanel;
    Label27: TLabel;
    FENYTEXTMEMO: TMemo;
    TEXTOKEGOMB: TBitBtn;
    TEXTMEGSEMGOMB: TBitBtn;
    Bevel2: TBevel;
    SECONDTAKARO: TPanel;
    MESSPANEL: TPanel;
    FUTOFENYBEKAPCSOLO: TBitBtn;
    FUTOFENYKIKAPCSOLO: TBitBtn;
    ENGEDELYPANEL: TPanel;
    NOPOSTERM: TRadioButton;
    ISPOSTERM: TRadioButton;
    OTPPANEL: TPanel;
    Label3: TLabel;
    Label32: TLabel;
    Label35: TLabel;
    HOSTEDIT: TEdit;
    PORTEDIT: TEdit;
    SP3: TPanel;
    OTPOKEGOMB: TBitBtn;
    Label36: TLabel;
    IP1: TEdit;
    IP2: TEdit;
    IP3: TEdit;
    IP4: TEdit;
    ipokegomb: TBitBtn;
    IPMEGSEMGOMB: TBitBtn;
    MP12: TPanel;
    sp12: TPanel;
    Label37: TLabel;
    SCAN0: TRadioButton;
    SCAN1: TRadioButton;
    Label38: TLabel;

    procedure FormActivate(Sender: TObject);
    procedure MPColorClear;

    procedure MP1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Tabladisplay(_ss: byte);
    procedure PFUNCClick(Sender: TObject);
    procedure EFUNCClick(Sender: TObject);
    procedure AFUNCClick(Sender: TObject);
    procedure VVBOXClick(Sender: TObject);
    procedure WUBOXClick(Sender: TObject);
    procedure TAFABOXClick(Sender: TObject);
    procedure MAFABOXClick(Sender: TObject);
    procedure EKERBOXClick(Sender: TObject);
   
   
    procedure bestClick(Sender: TObject);
    procedure eastClick(Sender: TObject);
    procedure pannonClick(Sender: TObject);
    procedure pwmodygombClick(Sender: TObject);
    procedure savegombClick(Sender: TObject);
    procedure ReklamFeldolgozas;
    procedure FutoFenyBekapcsolasa;
   
    procedure quitgombClick(Sender: TObject);
    procedure JELSZOEDITEnter(Sender: TObject);
    procedure JELSZOEDITExit(Sender: TObject);
    procedure JELSZOEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure EMAILEDITEnter(Sender: TObject);
    procedure EMAILEDITExit(Sender: TObject);
    procedure EMAILEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SATOPENClick(Sender: TObject);
    procedure SATCLOSEDClick(Sender: TObject);
    procedure ZOLDClick(Sender: TObject);
    procedure SARGAClick(Sender: TObject);
    procedure PIROSClick(Sender: TObject);
 
    procedure MINCSUSZKAChange(Sender: TObject);
    procedure NOFEERADIOClick(Sender: TObject);
    procedure SAVRADIOClick(Sender: TObject);
    procedure EZRELEKRADIOClick(Sender: TObject);
    procedure EZRELEKMODYGOMBClick(Sender: TObject);
    procedure EZRELEKEDITEnter(Sender: TObject);
    procedure EZRELEKEDITExit(Sender: TObject);
    procedure EZRELEKEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure maxeditEnter(Sender: TObject);
    procedure maxeditExit(Sender: TObject);
    procedure maxeditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ISPOSTERMClick(Sender: TObject);
    procedure NOPOSTERMClick(Sender: TObject);
    procedure LPTPORTClick(Sender: TObject);
    procedure USBPORTClick(Sender: TObject);
    procedure NOADSClick(Sender: TObject);
    procedure SplitHost;

    procedure SPEEDChange(Sender: TObject);
    procedure kilepotimerTimer(Sender: TObject);
    procedure FFDBEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FCP1EDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FCP2EDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);

    procedure Adategyeztetes;
    function Getfutofeny: integer;
    function GetReklamString: string;
    procedure reklamsetup(sender: TObject);
    procedure MM1Click(Sender: TObject);
    procedure visszagombClick(Sender: TObject);
    procedure RL1Click(Sender: TObject);
    procedure LT1Click(Sender: TObject);
    function ReklamLoad(_aktfile: string): boolean;
    procedure MP1Click(Sender: TObject);
    procedure TEXTEDITGOMBClick(Sender: TObject);
    procedure CSAKARFRADIOClick(Sender: TObject);
    procedure CSAKTEXTRADIOClick(Sender: TObject);
    procedure FFDBEDITEnter(Sender: TObject);
    procedure FFDBEDITExit(Sender: TObject);
    procedure TEXTOKEGOMBClick(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);
    procedure VEGYESRADIOClick(Sender: TObject);
    procedure FUTOFENYKIKAPCSOLOClick(Sender: TObject);
    procedure FUTOFENYBEKAPCSOLOClick(Sender: TObject);
    procedure TEXTMEGSEMGOMBClick(Sender: TObject);
    procedure expresszClick(Sender: TObject);
    procedure OTPClick(Sender: TObject);
    procedure HOSTEDITEnter(Sender: TObject);
    procedure HOSTEDITExit(Sender: TObject);
    procedure HOSTEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure PORTEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure KANDHClick(Sender: TObject);
    procedure OTPOKEGOMBClick(Sender: TObject);
    procedure IP1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ipokegombClick(Sender: TObject);
    procedure SCAN0Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SETUPFORM: TSETUPFORM;

  _gepfunkcio,_kellforgalom,_kellMetroAfa,_kellTescoAfa,_kellMatrica: byte;
  _printer,_saturday,_szinkod,_scantype: byte;
  _posterm,_akttabla,_rdb,_kellwestern,_speed,_reklamdarab,_fType: byte;
  _realezrelek,_kezdijmax,_futofeny,_keszletperc,_tag,_code: integer;
  _ezsupervisor,_futodb,_posport: integer;
  _reklamstring,_pcs,_f1ps,_f2ps: string;

  _sip: array[1..4] of TEdit;
  _mm,_lt: array[1..5] of TBitBtn;
  _RL: array[1..5] of TCheckbox;
  _vanrek: array[1..5] of boolean;

  _kftnev,_emailcim,_jelszo,_futs,_fdbs,_fp1s,_fp2s,_sps,_aktips: string;
  _fenytext,_pecs,_poshost: string;

  _sp,_mp: array[1..12] of TPanel;
  _nIp: array[1..4] of string;

  _aktPanel,_aktGomb: TPanel;

  _rek1Path: string ='c:\valuta\flags\reklam1.jpg';
  _rek2Path: string ='c:\valuta\flags\reklam2.jpg';

  _hasChanged,_tiltas,_setup: boolean;

  _hNet,_hFTP: HINTERNET;
  _findData   : WIN32_FIND_DATA;
  _ftpPort    : integer = 21100;

  _host       : string;

  _ftpPassword: string = 'klc+45%';
  _tab        : char = chr(9);
  _userid     : string = 'ebc-10%';
  _frissreklam: boolean;
  _csaktext,_csakarf,_vegyes: boolean;

  _top,_left,_height,_width: word;
  _sorveg: string = chr(13) + chr(10);

  _wh,_pp,_asc: byte;

  _aktip: byte;
  _nums: string;



function parameterezes: integer; stdcall;


implementation

{$R *.dfm}


// =============================================================================
                    function parameterezes: integer; stdcall;
// =============================================================================

begin
  Setupform := TsetupForm.Create(Nil);
  Result := setupform.showmodal;
  Setupform.Free;
end;


// =============================================================================
               procedure TSETUPFORM.FormActivate(Sender: TObject);
// =============================================================================

var i: integer;

begin
  AlapPAnel.visible := false;


  _width  := Screen.Monitors[0].Width;
  _height := screen.Monitors[0].Height;
  _top    := trunc((_height-745)/2);
  _left   := trunc((_width-1017)/2);

  Top    := _top;
  Left   := _left;
  width  := 1017;
  height := 745;

  _sp[1] := SP1;
  _sp[2] := SP2;
  _sp[3] := SP3;
  _sp[4] := SP4;
  _sp[5] := SP5;
  _sp[6] := SP6;
  _sp[7] := SP7;
  _sp[8] := SP8;
  _sp[9] := SP9;
  _sp[10]:= SP10;
  _sp[11]:= SP11;
  _sp[12]:= SP12;

  _mp[1] := MP1;
  _mp[2] := MP2;
  _mp[3] := MP3;
  _mp[4] := MP4;
  _mp[5] := MP5;
  _mp[6] := MP6;
  _mp[7] := MP7;
  _mp[8] := MP8;
  _mp[9] := MP9;
  _mp[10]:= MP10;
  _mp[11]:= MP11;
  _mp[12]:= MP12;

  _sip[1] := Ip1;
  _sip[2] := Ip2;
  _sip[3] := Ip3;
  _sip[4] := Ip4;

  _mm[1] := mm1;
  _lt[1] := Lt1;
  _rl[1] := Rl1;

  _mm[2] := mm2;
  _lt[2] := Lt2;
  _rl[2] := Rl2;

  _mm[3] := mm3;
  _lt[3] := Lt3;
  _rl[3] := Rl3;

  _mm[4] := mm4;
  _lt[4] := Lt4;
  _rl[4] := Rl4;

  _mm[5] := mm5;
  _lt[5] := Lt5;
  _rl[5] := Rl5;

  _hasChanged := False;
  _tiltas     := False;

  for i := 1 to 4 do _nip[i] := '';
  for i := 1 to 11 do _sp[i].Left := -888;
  _akttabla := 0;

  ValutaDbase.Connected := true;
  with ValutaQuery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _gepfunkcio   := FieldByName('GEPFUNKCIO').asInteger;
      _kftnev       := trim(FieldByName('KFTNEV').asstring);
      _emailcim     := trim(FieldByName('ERTEKTAREMAILCIM').asstring);
      _jelszo       := trim(FieldByName('JELSZO').asString);
      _realezrelek  := FieldByNAme('REALEZRELEK').asInteger;
      _kellforgalom := FieldByname('KELLFORGALOM').asInteger;
      _kellwestern  := FieldByName('KELLWESTERN').asInteger;
      _kellMetroAfa := FieldByNAme('KELLMETROAFA').asInteger;
      _kelltescoAfa := FieldByNAme('KELLTESCOAFA').asInteger;
      _kellMatrica  := FieldByNAme('KELLMATRICA').asInteger;
      _host         := trim(FieldByNAme('HOST').AsString);
    
      _printer      := FieldByNAme('PRINTER').asInteger;
      _saturday     := FieldByNAme('SATURDAY').asInteger;
      _reklamString := trim(FieldByNAme('REKLAMSTRING').asString);
      _szinkod      := FieldByNAme('SZINKOD').asInteger;
      _kezdijmax    := FieldByName('KEZDIJMAX').asInteger;
      _futofeny     := FieldByNAme('FUTOFENY').asInteger;
      _keszletperc  := FieldByName('KESZLETPERC').asInteger;

      _posterm      := FieldByNAme('POSTTERM').asInteger;
      _posHost      := trim(FieldByname('POSHOST').asString);
      _posPort      := FieldByNAme('POSPORT').asInteger;

      _scantype     := FieldByNAme('SCANNER').asInteger;

      Close;
      sql.Clear;
      Sql.Add('SELECT * FROM MEDIA');
      Open;
      _fenytext     := trim(FieldByname('FENYTEXT').asstring);
      close;
    end;
  ValutaDbase.close;

  if _host<>'' then splithost;

  _setUp := true;

  // ----------------------------------------------------------------

  if _gepfunkcio=1 then Pfunc.Checked := true;
  if _gepfunkcio=2 then Efunc.Checked := True;
  if _gepfunkcio=3 then Afunc.Checked := true;

   // ----------------------------------------------------------------

  if _printer=0 then LPTPORT.Checked := true;
  if _printer=1 then USBPort.Checked := True;

  // ------------------------------------------------------------------

  if _scantype=0 then scan0.Checked := True else Scan1.Checked := True;


  // _reks := '313000' = 3 db 1-es 3-as

  ReklamFeldolgozas;

  // --------------------------------------------------------------------

  if _kellforgalom=1 then vvbox.Checked := true else vvbox.Checked := False;
  if _kellwestern=1  then wubox.Checked := true else wubox.Checked := False;
  if _kelltescoafa=1 then tafabox.Checked := true else tafabox.Checked := False;
  if _kellmetroafa=1 then mafabox.Checked := true else Mafabox.checked := False;
  if _kellmatrica=1  then ekerbox.Checked := True else ekerbox.Checked := False;

  // ----------------------------------------------------------------------

  JelszoPanel.Caption := _jelszo;
  JelszoEdit.Text     := _jelszo;
  Jelszopanel.Visible := True;

  Emailedit.Text      := _emailcim;
  if _saturday=1 then satclosed.Checked := true
  else satopen.Checked := true;

  // -----------------------------------------------------------------------

  PirosPanel.Visible := False;
  SargaPanel.Visible := False;
  ZoldPanel.Visible  := False;

  if _szinkod=1 then
    begin
      Zold.Checked := true;
      ZoldPanel.Visible := true;
    end;

  if _szinkod=2 then
    begin
      Sarga.Checked := true;
      SargaPanel.Visible := true;
    end;

  if _szinkod=3 then
    begin
      Piros.Checked := true;
      PirosPanel.Visible := true;
    end;

  // ------------ futófény adatai ----------------------------------------------

  _csaktext := False;
  _vegyes   := False;
  _csakarf  := False;
  
  TexteditPanel.visible := False;

  if (_futofeny<1) then Futofenypanel.Visible := False   // -1 = nincs futófény
  else
  begin
    _futs := inttostr(_futofeny);  // négy számjegyü paraméter:
    if length(_futs)<>4 then
      begin
        _futofeny := -1;
        Futofenypanel.Visible := false;
      end else FutoFenyBekapcsolasa;
  end;

  // ------------------------------------------------------------------------

  KpPanel.caption := inttostr(_keszletperc);
  Mincsuszka.Position := _keszletperc;

  // ------------------------------------------------------------------------

  ezrelekEdit.text := inttostr(_realEzrelek);

  if _realEzrelek=0 then
    begin
      NofeeRadio.Checked := true;
      Ezreleklap.Visible := False;
    end;

  if _realEzrelek=-1 then
    begin
      EzrelekLap.visible := False;
      Savradio.Checked := true;
    end;

  if _realEzrelek>0 then
    begin
      EzrelekRadio.Checked := true;
      Ezrelekpanel.Caption := inttostr(_realezrelek)+' ezrelék  Max: '+inttostr(_kezdijmax)+' Ft';
      EzrelekPanel.Visible := true;
      Ezrelekpanel.repaint;
      EzrelekLap.Visible := true;
      EzrelekLap.repaint;
    end;

  // ------------------------------------------------------------------------


  if _posTerm=0 then NoPosterm.Checked := true else ISPOSTERM.Checked := True;
  _setUp := False;

  AlapPanel.Visible := true;
  Alappanel.repaint;

end;


// =============================================================================
     procedure TSETUPFORM.MP1MouseMove(Sender: TObject; Shift: TShiftState; X,
                                                                   Y: Integer);
// =============================================================================

begin
  if _tiltas then exit;

  _tag := TPanel(sender).tag;
  MpColorClear;
  _aktgomb       := _mp[_tag];
  _aktgomb.color := $B0FFFF;
  Tabladisplay(_tag);
end;

// =============================================================================
                      procedure TSETUPFORM.MPColorClear;
// =============================================================================

var i: integer;

begin
  for i := 1 to 12 do _mp[i].Color := clBtnFace;
end;


// =============================================================================
                procedure TSETUPFORM.Tabladisplay(_ss: byte);
// =============================================================================

var i: integer;

begin
  if _akttabla=_ss then exit;
  _akttabla := _ss;

  if _aktTabla=3 then for i := 1 to 4 do _sip[i].text := _nip[i];

  for i := 1 to 12 do _sp[i].Left := -888;

  _aktPanel := _sp[_ss];

  _aktpanel.Left := 392;
  _aktpanel.Top  := 180;

end;

// =============================================================================
              procedure TSETUPFORM.PFUNCClick(Sender: TObject);
// =============================================================================

begin
  _gepfunkcio := 1;
end;


// =============================================================================
               procedure TSETUPFORM.EFUNCClick(Sender: TObject);
// =============================================================================

begin
  _gepfunkcio := 2;
end;

// =============================================================================
                procedure TSETUPFORM.AFUNCClick(Sender: TObject);
// =============================================================================

begin
  _gepfunkcio := 3;
end;

// =============================================================================
                procedure TSETUPFORM.VVBOXClick(Sender: TObject);
// =============================================================================

begin
  if vvbox.Checked then _kellforgalom := 1 else _kellforgalom := 0;
end;

// =============================================================================
              procedure TSETUPFORM.WUBOXClick(Sender: TObject);
// =============================================================================

begin
  if wubox.Checked then _kellwestern := 1 else _kellwestern := 0;
end;


// =============================================================================
             procedure TSETUPFORM.TAFABOXClick(Sender: TObject);
// =============================================================================

begin
  if Tafabox.Checked then _kelltescoafa := 1 else _kelltescoafa := 0;
end;

// =============================================================================
          procedure TSETUPFORM.MAFABOXClick(Sender: TObject);
// =============================================================================

begin
  if MafaBox.Checked then _kellMetroAfa := 1 else _kellmetroafa := 0;
end;

// =============================================================================
            procedure TSETUPFORM.EKERBOXClick(Sender: TObject);
// =============================================================================

begin
  if Ekerbox.Checked then _kellmatrica := 1 else _kellmatrica := 0;
end;




// =============================================================================
            procedure TSETUPFORM.bestClick(Sender: TObject);
// =============================================================================

begin
  _kftnev := 'BEST';
end;

// =============================================================================
               procedure TSETUPFORM.eastClick(Sender: TObject);
// =============================================================================

begin
  _kftnev := 'EAST';
end;

// =============================================================================
             procedure TSETUPFORM.pannonClick(Sender: TObject);
// =============================================================================

begin
  _kftnev := 'PANNON';
end;

// =============================================================================
           procedure TSETUPFORM.pwmodygombClick(Sender: TObject);
// =============================================================================

begin
  PwModyGomb.Enabled := false;
  Jelszopanel.Visible := False;
  ActiveControl := JelszoEdit;
  _tiltas := true;
end;

// =============================================================================
             procedure TSETUPFORM.quitgombClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 2;
end;

// =============================================================================
            procedure TSETUPFORM.JELSZOEDITEnter(Sender: TObject);
// =============================================================================

begin
  Jelszoedit.Color := clYellow;
end;

// =============================================================================
           procedure TSETUPFORM.JELSZOEDITExit(Sender: TObject);
// =============================================================================

begin
  Jelszoedit.Color := clWIndow;
end;

// =============================================================================
       procedure TSETUPFORM.JELSZOEDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================


var _pw: string;

begin
  if ord(key)<>13 then exit;

  _pw := trim(Jelszoedit.Text);
  if length(_pw)=0 then exit;

  _jelszo := _pw;
  JelszoPanel.Caption := _jelszo;
  Jelszopanel.visible := True;
  Jelszopanel.repaint;
  PwModyGomb.Enabled := True;
  _tiltas := false;
end;

// =============================================================================
               procedure TSETUPFORM.EMAILEDITEnter(Sender: TObject);
// =============================================================================

begin
  tedit(SENDER).Color := clYellow;
end;

// =============================================================================
            procedure TSETUPFORM.EMAILEDITExit(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clWindow;
end;

// =============================================================================
      procedure TSETUPFORM.EMAILEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  _emailcim := Trim(emailedit.Text);
end;

// =============================================================================
             procedure TSETUPFORM.SATOPENClick(Sender: TObject);
// =============================================================================

begin
  _saturday := 0;
end;

// =============================================================================
            procedure TSETUPFORM.SATCLOSEDClick(Sender: TObject);
// =============================================================================

begin
  _saturday := 1;
end;

// =============================================================================
              procedure TSETUPFORM.ZOLDClick(Sender: TObject);
// =============================================================================


begin
  _szinkod := 1;
  PirosPanel.Visible := false;
  SargaPanel.Visible := false;
  ZoldPanel.Visible  := True;
end;

// =============================================================================
             procedure TSETUPFORM.SARGAClick(Sender: TObject);
// =============================================================================

begin
  _szinkod := 2;
  PirosPanel.Visible := false;
  SargaPanel.Visible := True;
  ZoldPanel.Visible  := False;
end;

// =============================================================================
              procedure TSETUPFORM.PIROSClick(Sender: TObject);
// =============================================================================

begin
  _szinkod := 3;
  PirosPanel.Visible := True;
  SargaPanel.Visible := False;
  ZoldPanel.Visible  := False;
end;


// =============================================================================
             procedure TSETUPFORM.MINCSUSZKAChange(Sender: TObject);
// =============================================================================

begin
  _keszletperc := Mincsuszka.Position;
  KpPanel.Caption := inttostr(_keszletperc);
  KpPanel.repaint;
end;

// =============================================================================
            procedure TSETUPFORM.NOFEERADIOClick(Sender: TObject);
// =============================================================================

begin
  _realezrelek := 0;
  ezrelekLap.Visible := False;
end;

// =============================================================================
               procedure TSETUPFORM.SAVRADIOClick(Sender: TObject);
// =============================================================================

begin
  _realezrelek := -1;
  Ezreleklap.Visible := false;
end;

// =============================================================================
          procedure TSETUPFORM.EZRELEKRADIOClick(Sender: TObject);
// =============================================================================

begin
  ezrelekPanel.Caption := inttostr(_realezrelek)+' ezrelék Max: '+inttostr(_kezdijmax)+ ' Ft';
  EzrelekPanel.Visible := true;
  EzrelekPanel.repaint;
  EzrelekLap.Visible := true;
  EzrelekLap.repaint;
end;

// =============================================================================
           procedure TSETUPFORM.EZRELEKMODYGOMBClick(Sender: TObject);
// =============================================================================

begin
  EzrelekModyGomb.Enabled := false;
  _tiltas := true;
  EzrelekEdit.Text := inttostr(_realezrelek);
  Maxedit.Text := inttostr(_kezdijmax);
  EzrelekPanel.Visible := false;
  Activecontrol := Ezrelekedit;

end;

// =============================================================================
             procedure TSETUPFORM.EZRELEKEDITEnter(Sender: TObject);
// =============================================================================

begin
  Ezrelekedit.Color := clYellow;
end;

// =============================================================================
            procedure TSETUPFORM.EZRELEKEDITExit(Sender: TObject);
// =============================================================================

begin
  Ezrelekedit.color := clWindow;
end;

// =============================================================================
     procedure TSETUPFORM.EZRELEKEDITKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

var _rezs: string;
    _rez : integer;

begin
  if ord(key)<>13 then exit;

  _rezs := trim(ezrelekedit.Text);
  val(_rezs,_rez,_code);
  if _code<>0 then _rez := 0;

  _realezrelek := _rez;
  Activecontrol := Maxedit;
end;



// =============================================================================
             procedure TSETUPFORM.maxeditEnter(Sender: TObject);
// =============================================================================

begin
  Maxedit.Color := clYellow;
end;

// =============================================================================
             procedure TSETUPFORM.maxeditExit(Sender: TObject);
// =============================================================================

begin
  Maxedit.Color := clWindow;
end;


// =============================================================================
       procedure TSETUPFORM.maxeditKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

var _mxs: string;
    _mx : integer;

begin
  if ord(key)<>13 then exit;
  _mxs := trim(Maxedit.Text);
  Val(_mxs,_mx,_code);
  if _code<>0 then _mx := 0;
  if _mx=0 then exit;

  _kezdijmax := _mx;
  EzrelekPanel.Caption := inttostr(_realezrelek)+' ezrelék Max: '+ inttostr(_mx)+' Ft';
  Ezrelekpanel.Visible := true;
  EzrelekPanel.repaint;

  EzrelekModyGomb.Enabled := true;
  _tiltas := False;
end;

// =============================================================================
             procedure TSETUPFORM.ISPosTermClick(Sender: TObject);
// =============================================================================

begin
  IF _setup then exit;
  _posterm := 1;
  HostEdit.Text    := _posHost;
  PortEdit.Text    := inttostr(_posPort);
  OtpPanel.Visible := True;
  OtpPanel.repaint;
  Activecontrol    := Hostedit;
end;

// =============================================================================
           procedure TSETUPFORM.NOPosTermClick(Sender: TObject);
// =============================================================================

begin
  if _setup then exit;
  _posterm := 0;
  otpPanel.Visible := False;
end;

// =============================================================================
              procedure TSETUPFORM.LPTPORTClick(Sender: TObject);
// =============================================================================

begin
  _printer := 0;
end;

// =============================================================================
               procedure TSETUPFORM.USBPORTClick(Sender: TObject);
// =============================================================================

begin
  _printer := 1;
end;

// =============================================================================
               procedure TSETUPFORM.NOADSClick(Sender: TObject);
// =============================================================================

begin
  _reklamstring := '000000';
  ReklamPanel.Visible := false;
end;

// =============================================================================
            procedure TSETUPFORM.savegombClick(Sender: TObject);
// =============================================================================


begin
  AdatEgyeztetes;

  _pcs := 'UPDATE HARDWARE SET GEPFUNKCIO='+inttostr(_gepfunkcio);
  _pcs := _pcs + ',KFTNEV=' + chr(39) + _kftnev + chr(39);
  _pcs := _pcs + ',ERTEKTAREMAILCIM=' + chr(39) + _emailcim + chr(39);
  _pcs := _pcs + ',JELSZO=' + chr(39) + _jelszo + chr(39);
  _pcs := _pcs + ',REALEZRELEK=' + inttostr(_realezrelek);
  _pcs := _pcs + ',KELLFORGALOM=' + inttostr(_kellforgalom);
  _pcs := _pcs + ',KELLWESTERN=' + inttostr(_kellwestern);
  _pcs := _pcs + ',KELLMETROAFA=' + inttostr(_kellmetroafa);
  _pcs := _pcs + ',KELLTESCOAFA=' + inttostr(_kelltescoafa);
  _pcs := _pcs + ',KELLMATRICA=' + inttostr(_kellmatrica);
  _pcs := _pcs + ',PRINTER=' + inttostr(_printer);
  _pcs := _pcs + ',SATURDAY=' + inttostr(_saturday);
  _pcs := _pcs + ',REKLAMSTRING=' + chr(39)+ _reklamstring + chr(39);
  _pcs := _pcs + ',POSTTERM=' + inttostr(_posterm);
  _pcs := _pcs + ',SZINKOD=' + inttostr(_szinkod);
  _pcs := _pcs + ',KEZDIJMAX=' + inttostr(_kezdijmax);
  _pcs := _pcs + ',FUTOFENY=' + inttostr(_futofeny);
  _pcs := _pcs + ',KESZLETPERC=' + inttostr(_keszletperc);
  _pcs := _pcs + ',POSHOST=' + chr(39) + _poshost + chr(39);
  _pcs := _pcs + ',POSPORT=' + inttostr(_posport);
  _pcs := _pcs + ',HOST=' + chr(39) + _host + chr(39);
  _pcs := _pcs + ',SCANNER=' + inttostr(_scantype);

  ValutaParancs(_pcs);
  Modalresult := 1;
end;


// =============================================================================
                      procedure Tsetupform.Adategyeztetes;
// =============================================================================

var _ezres,_kmaxs: string;

begin
  // --------------------- SP1 ----------------

  if pfunc.checked then _gepfunkcio := 1;
  if efunc.checked then _gepfunkcio := 2;
  if aFunc.checked then _gepfunkcio := 3;

  // --------------------- SP2 -------------------------------------------

  If VVBox.checked then _kellforgalom := 1 else _kellforgalom := 0;
  if Wubox.checked then _kellwestern := 1 else _kellwestern := 0;
  if Tafabox.checked then _kelltescoafa := 1 else _kelltescoafa := 0;
  if Mafabox.checked then _kellmetroafa := 1 else _kellmetroafa := 0;
  if Ekerbox.checked then _kellmatrica := 1 else _kellmatrica := 0;
 
  // -------------------- SP3 --------------------------------------------

 
  // -------------------- SP4 ---------------------------------

  _jelszo := trim(JELSZOEDIT.Text);
  _emailcim := trim(EMAILEDIT.Text);
  if SatOpen.checked then _saturday := 1 else _saturday := 0;

  // -------------------- SP5  --------------------------------

  If zold.checked then _szinkod := 1;
  if sarga.checked then _szinkod := 2;
  if piros.checked then _szinkod := 3;

  // -------------------- SP6 ---------------------------------

  _futofeny := Getfutofeny;

  // -------------------- SP7 ----------------------------------

  _KESZLETPERC := Mincsuszka.position;

  // -------------------- SP8 ------------------------

  _kezdijmax := 6000;

  If nofeeradio.checked then _realezrelek := 0;
  if savradio.checked then _realezrelek := -1;

  if Ezrelekradio.checked then
    begin
      _ezres := trim(ezrelekedit.text);
      _kmaxs := trim(maxedit.text);
      val(_ezres,_realezrelek,_code);
      if _code<>0 then _realezrelek := -1;
      val(_kmaxs,_kezdijmax,_code);
      if _code<>0 then _kezdijmax := 6000;
    end;

  // -------------------- SP9 -----------------------------------

  if isposterm.checked then _posterm := 1 else _posterm := 0;

  // -------------------- SP10 ----------------------------------

  if lptport.checked then _printer := 0 else _printer := 1;

  // -------------------- SP11 -----------------------------------

  _reklamstring := getReklamstring;

end;  





// =============================================================================
               procedure TSETUPFORM.SPEEDChange(Sender: TObject);
// =============================================================================

begin
  _speed := Speed.Position;


end;

// =============================================================================
             procedure TSETUPFORM.kilepotimerTimer(Sender: TObject);
// =============================================================================

begin
  Kilepotimer.Enabled := false;
  Modalresult := 2;
end;

// =============================================================================
        procedure TSETUPFORM.FFDBEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;

  _fdbs := trim(ffdbedit.Text);
  val(_fdbs,_futodb,_code);
  if _code<>0 then _futodb := 0;
  if (_futodb=0) or (_futodb>2) then
    begin
      FutoFenyPanel.Visible := False;
      exit;
    end;

  if _futodb<2 then
    begin
      with SecondTakaro do
        begin
          Left := 0;
          top := 56;
          Visible := true;
        end;
    end else secondTakaro.Visible := False;

  Fcp1edit.Text := '1';
  Activecontrol := Fcp1edit;
end;

// =============================================================================
       procedure TSETUPFORM.FCP1EDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  if _futodb=2 then
    begin
      Fcp2edit.Text := '2';
      Activecontrol := Fcp2edit
    end else Activecontrol := Speed;

end;

// =============================================================================
        procedure TSETUPFORM.FCP2EDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  Activecontrol := Speed;
end;


// =============================================================================
                  function Tsetupform.GetReklamstring: string;
// =============================================================================

var _rekdb: integer;
    _q: byte;
    _reqs: string;

begin
  _rekdb := 0;
  _q := 1;
  _reqs := '';

  while _q<=5 do
    begin
      if _rl[_q].Checked then
        begin
          inc(_rekdb);
          _vanrek[_q] := true;
        end
        else _vanrek[_q] := False;
       inc(_q);
     end;

  if _rekdb= 0 then
    begin
      result := '000000';
      exit;
    end;

  _q := 1;
  while _q<=5 do
    begin
      if _vanrek[_q] then _reqs := _reqs + chr(48+_q);
      inc(_q);
    end;

  result := chr(48+_rekdb)+_reqs;
  while length(result)<6 do result := result + '0';
end;


// =============================================================================
                    procedure TSetupForm.Reklamfeldolgozas;
// =============================================================================

var _y,_aktrss: byte;
    _rss: array[1..5] of byte;
    _rsors,_dbs: string;


begin
  _dbs := leftstr(_reklamstring,1);
  val(_dbs,_reklamdarab,_code);

  if _code<>0 then _reklamdarab := 0;

  if _reklamdarab<1 then
    begin
      Noads.checked := True;
      _reklamstring := '000000';
      ReklamPanel.visible := false;
      exit;
    end;

  if length(_reklamstring)<>6 then
    begin
      _reklamstring := '000000';
      Noads.checked := True;
      ReklamPanel.visible := false;
      exit;
    end;

   _y :=1;
   while _y<=_reklamdarab do
     begin
       _rsors := midstr(_reklamstring,1+_y,1);
       _rss[_y] := ord(_rsors[1])-48;
       inc(_y);
     end;

   _y := 1;
   while _y<=5 do
     begin
       _rl[_y].Checked := false;
       inc(_y);
     end;

   _y := 1;
   while _y<=_reklamdarab do
     begin
       _aktrss :=_rss[_y];
       _rl[_aktrss].Checked := true;
       inc(_y);
     end;

   isads.checked := true;
   ReklamPanel.visible := true;
end;


// =============================================================================
                procedure Tsetupform.reklamsetup(sender: TObject);
// =============================================================================

var
    _y: byte;
    _rfileName,_rPath: string;

begin
  DispPanel.Visible := false;

  _y := 1;
  while _y<=5 do
    begin
      _rfilename := 'REKLAM'+chr(48+_y)+'.JPG';
      _rPath := 'C:\VALUTA\FLAGS\' + _rFileName;
      if FileExists(_rPath) then _vanrek[_y] := true else _vanrek[_y] := False;

      inc(_y);
    end;

  _y := 1;
  while _y<=5 do
    begin
      if _vanRek[_y] then
        begin
          _mm[_y].Enabled := True;
          _lt[_y].Enabled := False;
          _rl[_y].Enabled := True;
        end else
        begin
          _mm[_y].Enabled := False;
          _rl[_y].Enabled := False;
          _rl[_y].Checked := False;
          _lt[_y].Enabled := True;
        end;
      inc(_y);
    end;
  ReklamPanel.visible := true;
  Isads.checked := true;
end;

// =============================================================================
               procedure TSETUPFORM.MM1Click(Sender: TObject);
// =============================================================================

var _tag: byte;
    _rekname,_rekPath: string;

begin
  _tag := TBitbtn(sender).Tag;
  _rekname := 'REKLAM' + chr(48+_tag)+'.JPG';
  _rekPath := 'c:\valuta\flags\' + _rekname;
  vaszon.Picture.LoadFromFile(_rekpath);
  with dispPanel do
    begin
      top := 8;
      left := 8;
      Visible := true;
      repaint;
    end;
  Activecontrol := VisszaGomb;
end;

// =============================================================================
               procedure TSETUPFORM.visszagombClick(Sender: TObject);
// =============================================================================

begin
  DispPanel.visible := false;

end;

// =============================================================================
                 procedure TSETUPFORM.RL1Click(Sender: TObject);
// =============================================================================

var _tag: byte;
    _marked : boolean;

begin
  if _setup then exit;
 
  _setup := true;
  _tag := TcheckBox(sender).tag;
  
  _marked := _rl[_tag].checked;
  if _marked then
   begin
     _setup := False;
     exit;
   end;

  _rl[_tag].Checked := false;

  _setup := false;

end;

// =============================================================================
               procedure TSETUPFORM.LT1Click(Sender: TObject);
// =============================================================================

var _tag: byte;
    _rekname: string;
    _ok: boolean;

begin
  _tag := TBitbtn(Sender).tag;
  _rekname := 'REKLAM' + chr(48+_tag) + '.JPG';
  _ok := ReklamLoad(_rekname);

  if _ok then
    begin
      _mm[_tag].Enabled := true;
      _lt[_tag].Enabled := false;
      _rl[_tag].Enabled := true;
    end;
end;



// =============================================================================
           function TsetupForm.ReklamLoad(_aktfile: string): boolean;
// =============================================================================

var _aktpath: string;

begin
  result := False;

  _hnet := InternetOpen(pchar('LoadFormServer'),INTERNET_OPEN_TYPE_DIRECT,nil,nil,0);
  if _hNet = nil then exit;
  _hFTP := InternetConnect(_hNet,Pchar(_Host),_ftpPort,Pchar(_userId),
                           PChar(_ftpPassword),INTERNET_SERVICE_FTP,
                           INTERNET_FLAG_PASSIVE,
                           0);

  if _hFtp=NIL then
    begin
      InternetCloseHandle(_hnet);
      exit;
    end;

  result :=  FTPSetCurrentDirectory(_hFTP,pchar('\REKLAM'));
  if not result then
    begin
      InternetCloseHandle(_hFtp);
      InternetCloseHandle(_hnet);
      exit;
    end;

  _aktpath := 'c:\valuta\flags\' + _aktfile;

  if Fileexists(_aktPath) then DeleteFile(_aktpath);
  result := FtpGetfile(_hFTP,pchar(_aktFile),pchar(_aktPath),
                                           False,0,FTP_TRANSFER_TYPE_BINARY,0);

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);
end;

procedure TSETUPFORM.MP1Click(Sender: TObject);
begin
  _tiltas := true;
  if (_tag=9) and (_posterm=1) then
    begin
      HostEdit.Text    := _posHost;
      PortEdit.Text    := inttostr(_posPort);
      OtpPanel.Visible := True;
      Activecontrol    := Hostedit;
      EXIT;
    end;
  if _tag=3 then activecontrol := IP1;
end;

procedure TSETUPFORM.TEXTEDITGOMBClick(Sender: TObject);
begin
  FenytextMemo.clear;
  if _fenytext<>'' then FenyTextMemo.Lines.Add(_fenytext)
  else fenytextmemo.Lines.clear;

  with TextEditPanel do
    begin
      top := 0;
      left := 0;
      Visible := true;
    end;

  ActiveControl := FenytextMemo;

end;





procedure TSETUPFORM.FFDBEDITEnter(Sender: TObject);
begin
  Tedit(sender).Color := clYellow;
end;

procedure TSETUPFORM.FFDBEDITExit(Sender: TObject);
begin
  Tedit(Sender).Color := clWindow;
end;

procedure TSETUPFORM.TEXTOKEGOMBClick(Sender: TObject);

var _temptext: string;
    _templen,_y,_kod: byte;

begin
  _temptext := trim(FenyTextMemo.Text);
  _templen  := length(_temptext);
  _fenytext := '';

  _y := 1;
  while _y<=_templen do
    begin
      _kod := ord(_temptext[_y]);
      if (_kod<48) then _kod := 32;
      _fenytext := _fenytext + chr(_kod);
      inc(_y);
    end;

  _fenytext := uppercase(_fenytext);

  _pcs := 'DELETE FROM MEDIA';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO MEDIA (FENYTEXT)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _fenytext + chr(39) + ')';
  ValutaParancs(_pcs);
  Texteditpanel.Visible := false;
end;

procedure TsetupForm.ValutaParancs(_ukaz: string);

begin
  ValutaDbase.Connected := true;
  if Valutatranz.InTransaction then valutatranz.Commit;
  Valutatranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  Valutatranz.commit;
  Valutadbase.close;
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$  FUTOFÉNY BEÁLLITÁS RUTINJAI $$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

procedure TSETUPFORM.CSAKARFRADIOClick(Sender: TObject);
begin
  TextEditGomb.Enabled := false;
  _csakarf  := True;
  _csaktext := False;
  _vegyes   := False;
  _ftYPE    := _futoDb;

end;

// =============================================================================
            procedure TSETUPFORM.CSAKTEXTRADIOClick(Sender: TObject);
// =============================================================================

begin
  TexteditGomb.Enabled := True;
  _csakarf  := False;
  _csaktext := True;
  _vegyes   := False;
  _fType    := 2 +_futodb;
end;


// =============================================================================
          procedure TSETUPFORM.VEGYESRADIOClick(Sender: TObject);
// =============================================================================

begin
   TexteditGomb.Enabled := True;
  _csakarf  := False;
  _csaktext := False;
  _vegyes   := True;
  _ftype := 4 + _futodb;
end;


// =============================================================================
                function TSetupForm.GetFutofeny: integer;
// =============================================================================

var _ff: byte;
    _ffs: string;

begin
  result := -1;
  if _futofeny=-1 then exit;

  _futs := trim(FFdbedit.text);
  _f1ps := trim(Fcp1edit.text);
  _f2ps := trim(Fcp2edit.text);

  if (_futs>'2') or (_futs<'1') then exit;
  if (_f1ps<'1') or (_f1ps>'8') then exit;

  val(_futs,_futodb,_code);
  if _code<>0 then _futodb := 0;
  if _futodb=0 then exit;

  if _futodb=2 then
    begin
      if (_f2ps<'1') or (_f2ps>'8') then exit;
    end;

  _ff := _futodb;
  if csaktextradio.Checked then _ff := 2+_futodb;
  if vegyesradio.Checked then _ff := 4 + _futodb;

  _speed := Speed.Position;
  _sps := chr(48+_speed);

  _ffs := chr(_ff+48)+ _f1ps + _f2ps + _sps;
  val(_ffs,result,_code);
  if _code<>0 then result := -1;
end;

// =============================================================================
          procedure TSETUPFORM.FUTOFENYKIKAPCSOLOClick(Sender: TObject);
// =============================================================================

begin
  Futofenypanel.Visible := False;
  _futofeny := -1;
end;

// =============================================================================
             procedure TsetupForm.FutofenyBekapcsolasa;
// =============================================================================

begin
  _futs := inttostr(_futofeny);  // négy számjegyü paraméter:
  if length(_futs)<>4 then
    begin
      _futofeny := -1;
      Futofenypanel.Visible := false;
    end else
    begin
      _ftype  := ord(_futs[1])-48;

          {
           1=egy futófény + csak árfolyam
           2=két futófény + csak árfolyam
           3=egy futófény + csak text
           4=két futófény + csak text
           5=egy futofény + vegyes
           6=két futófény + vegyes
          }

      _fp1s   := midstr(_futs,2,1);
      _fp2s   := midstr(_futs,3,1);
      _sps    := midstr(_futs,4,1);

      _ftype  := ord(_futs[1])-48;

      if (_ftype=1) or (_ftype=3) or (_ftype=5) then _futodb := 1
      else _futodb := 2;

      if (_ftype=3) or (_ftype=4) then _csaktext := True;
      if (_ftype=5) or (_ftype=6) then _vegyes := true;

      if _ftype<3 then _csakarf := True;

      val(_sps,_speed,_code);
      if _code<>0 then _speed := 5;

      FFdbedit.Text := inttostr(_futodb);
      Fcp1edit.Text := _fp1s;

      if _futodb=2 then secondTakaro.Visible := False
      else
      begin
        Fcp2edit.text := _fp2s;
        with SecondTakaro do
          begin
            top := 50;
            Left := 0;
            Visible := true;
          end;
      end;

      Speed.Position := _speed;

      if _csakarf then csakarfradio.Checked := true;
      if _csaktext then CsaktextRadio.Checked := True;
      if _vegyes then VegyesRadio.Checked := True;

      with FutoFenyPanel do
        begin
          Top := 40;
          Left := 8;
          Visible := True;
        end;
    end;
end;

// =============================================================================
          procedure TSETUPFORM.FUTOFENYBEKAPCSOLOClick(Sender: TObject);
// =============================================================================

begin
  _futofeny := 1105;
  Speed.Position := 5;
  FutoFenyBekapcsolasa;
end;

// =============================================================================
          procedure TSETUPFORM.TEXTMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  TextEditPanel.Visible := false;
end;


// =============================================================================
           procedure TSETUPFORM.expresszClick(Sender: TObject);
// =============================================================================

begin
  _kftnev := 'EXPRES';
end;


// =============================================================================
                procedure TSETUPFORM.OTPClick(Sender: TObject);
// =============================================================================

begin
  if _setup then exit;

  Hostedit.Text := _PosHost;
  PortEdit.Text := inttostr(_posport);
  OTPPanel.visible := true;
  Activecontrol := Savegomb;
end;

// =============================================================================
            procedure TSETUPFORM.HOSTEDITEnter(Sender: TObject);
// =============================================================================

begin
  TEdit(sender).Color := clYellow;
end;

// =============================================================================
            procedure TSETUPFORM.HOSTEDITExit(Sender: TObject);
// =============================================================================

begin
  TEdit(sender).color := clWindow;
end;

// =============================================================================
      procedure TSETUPFORM.HOSTEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Activecontrol := Portedit;
end;



// =============================================================================
    procedure TSETUPFORM.PORTEDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

var _posports: string;

begin
  if ord(key)<>13 then exit;
  _posHost := trim(Hostedit.Text);
  _posports := trim(Portedit.Text);
  val(_posports,_posport,_code);
  if _code<>0 then _posport := 0;
  Activecontrol := SaveGomb;

end;

// =============================================================================
               procedure TSETUPFORM.KANDHClick(Sender: TObject);
// =============================================================================

begin
  IF _SETUP THEN EXIT;

  OtpPanel.Visible := false;

end;

// =============================================================================
                procedure TSETUPFORM.OTPOKEGOMBClick(Sender: TObject);
// =============================================================================

var _posports: string;

begin
  _poshost := trim(HostEdit.Text);
  _posports := trim(PortEdit.Text);
  val(_posports,_posport,_code);
  activeCOntrol := SaveGomb;
end;

// =============================================================================
     procedure TSETUPFORM.IP1KeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  _tag := Tedit(sender).tag;
  if _tag=4 then Activecontrol := IpokeGomb
  else ActiveControl := _sip[_tag+1];

end;

// =============================================================================
              procedure TSETUPFORM.ipokegombClick(Sender: TObject);
// =============================================================================

begin
  _tag := 1;
  while _tag<=4 do
    begin
      _aktips := trim(_sip[_tag].text);
      if _aktips='' then
        begin
          ActiveCOntrol := _sip[_tag];
          exit;
        end;
      inc(_tag);
    end;


  _aktips := trim(ip1.Text)+'.'+trim(ip2.Text)+'.'+trim(ip3.Text)+'.'+trim(ip4.Text);
  _pcs := 'UPDATE HARDWARE SET HOST='+chr(39)+_aktips+chr(39);
  ValutaParancs(_pcs);

  QuitGombClick(Nil);
end;

// =============================================================================
                          procedure TSetupForm.SplitHost;
// =============================================================================

begin
  _wh := length(_host);
  if _wh=0 then exit;

  _tag := 0;
  _pp := 1;
  _nums := '';

  while _pp<=_wh do
    begin
      _asc := ord(_host[_pp]);
      if _asc=46 then
        begin
          inc(_tag);
          _nip[_tag] := _nums;
          _nums := '';
        end else
        begin
          _nums := _nums + chr(_asc);
        end;
      inc(_pp);
    end;
  _nip[4] := _nums;
end;




procedure TSETUPFORM.SCAN0Click(Sender: TObject);
begin
  if Scan0.Checked then _scanType :=0 else _scantype := 1;
end;

end.
