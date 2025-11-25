unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, jpeg, ExtCtrls, unit1, StrUtils, ComCtrls;

type
  TTELEFONFORM = class(TForm)

    BarangoloGomb     : TBitBtn;
    Bar1Gomb          : TBitBtn;
    Bar2Gomb          : TBitBtn;
    Bar3Gomb          : TBitBtn;
    BitBtn3           : TBitBtn;
    Ctrl4Gomb         : TBitBtn;
    Ctrl1Gomb         : TBitBtn;
    Ctrl2Gomb         : TBitBtn;
    Ctrl3Gomb         : TBitBtn;
    FB1               : TBitBtn;
    FB2               : TBitBtn;
    FB3               : TBitBtn;
    FB4               : TBitBtn;
    FeltoltoGomb      : TBitBtn;
    KontrolGomb       : TBitBtn;
    MegsemGomb        : TBitBtn;
    TelkonyveloGomb   : TBitBtn;
    TelCancelGomb     : TBitBtn;
    TranzCancelGomb   : TBitBtn;
    TVisszaGomb       : TBitBtn;

    Image5            : TImage;

    IsmetloLabel      : TLabel;
    Label1            : TLabel;
    Label2            : TLabel;
    Label3            : TLabel;
    Label4            : TLabel;
    Keremlabel        : TLabel;

    BarangoloPanel    : TPanel;
    ErtesitoPanel     : TPanel;
    ForintPanel       : TPanel;
    CIMLET2PANEL: TPanel;
    CIMLET4PANEL: TPanel;
    CIMLET5PANEL: TPanel;
    CIMLET1PANEL: TPanel;
    CIMLET3PANEL: TPanel;
    GombTakaroPanel   : TPanel;
    Hibapanel         : TPanel;
    KontrolPanel      : TPanel;
    KudarcPanel       : TPanel;
    LogoTakaro        : TPanel;
    Munkalap          : TPanel;
    RSECONDPANEL      : TPanel;
    PN1               : TPanel;
    PN2               : TPanel;
    PN3               : TPanel;
    PN4               : TPanel;
    PN5               : TPanel;
    PN6               : TPanel;
    PN7               : TPanel;
    RetakaroPanel     : TPanel;
    RMSPanel          : TPanel;
    RPN1              : TPanel;
    RPN2              : TPanel;
    RPN3              : TPanel;
    RPN4              : TPanel;
    RPN5              : TPanel;
    RPN6              : TPanel;
    RPN7              : TPanel;
    TcomPanel         : TPanel;
    VisszaIgazoloPanel: TPanel;

    LogoShape1        : TShape;
    LogoShape2        : TShape;
    LogoShape3        : TShape;
    LogoShape4        : TShape;
    NulShape          : TShape;
    Shape1            : TShape;
    Shape2            : TShape;
    Shape3            : TShape;
    Shape4            : TShape;
    CIMLETSHAPE       : TShape;
    CIMLET2SHAPE      : TShape;
    CIMLET5SHAPE      : TShape;
    CIMLET1SHAPE      : TShape;
    CIMLET3SHAPE      : TShape;
    CIMLET4SHAPE      : TShape;
    Shape12           : TShape;
    Shape13           : TShape;
    Shape14           : TShape;
    Shape15           : TShape;
    Shape16           : TShape;
    Shape17           : TShape;
    Shape18           : TShape;
    Shape19           : TShape;
    Shape20           : TShape;
    SmsShape          : TShape;
    SPN1              : TShape;
    SPN2              : TShape;
    SPN3              : TShape;
    SPN4              : TShape;
    SPN5              : TShape;
    SPN6              : TShape;
    SPN7              : TShape;
    SRPN1             : TShape;
    SRPN2             : TShape;
    SRPN3             : TShape;
    SRPN4             : TShape;
    SRPN5             : TShape;
    SRPN6             : TShape;
    SRPN7             : TShape;
    SrmsShape         : TShape;

    KilepoTimer       : TTimer;
    CIKKNEVPANEL      : TPanel;
    RETURNGOMB        : TBitBtn;
    UGYFELPANEL       : TPanel;
    Label5            : TLabel;
    Label6            : TLabel;
    Label7            : TLabel;
    UGYFOKEGOMB       : TBitBtn;
    NEMKELLNEVGOMB    : TBitBtn;
    NEVEDIT           : TEdit;
    CIMEDIT           : TEdit;
    KERAFASTPANEL     : TPanel;
    Label8            : TLabel;
    NEMKERGOMB        : TBitBtn;
    AFASTKERGOMB      : TBitBtn;
    LOGOSHAPE5        : TShape;
    FB5               : TBitBtn;
    NEOMUNKALAP       : TPanel;
    NEOTELSHAPE       : TShape;
    Image1            : TImage;
    Label9            : TLabel;
    SQN1              : TShape;
    SQN2              : TShape;
    SQN3              : TShape;
    SQN4  : TShape;
    SQN5  : TShape;
    SQN6  : TShape;
    SQN7  : TShape;
    SQN8  : TShape;
    SQN9: TShape;
    SQN10: TShape;
    SRQN1: TShape;
    SRQN3: TShape;
    SRQN4: TShape;
    SRQN5: TShape;
    SRQN6: TShape;
    SRQN7: TShape;
    SRQn8: TShape;
    SRQN9: TShape;
    SRQN10: TShape;
    SRQN2: TShape;
    Label10: TLabel;
    QN1: TPanel;
    QN2: TPanel;
    QN3: TPanel;
    QN4: TPanel;
    RQN1: TPanel;
    RQN2: TPanel;
    RQN3: TPanel;
    QN5: TPanel;
    QN6: TPanel;
    QN7: TPanel;
    QN8: TPanel;
    QN9: TPanel;
    QN10: TPanel;
    RQN4: TPanel;
    RQN5: TPanel;
    RQN6: TPanel;
    RQN7: TPanel;
    RQN8: TPanel;
    RQN9: TPanel;
    RQN10: TPanel;
    PHIDEEDIT: TEdit;
    QHIDEEDIT: TEdit;
    fizetendopanel: TPanel;
    HIDEEDIT: TEdit;
    CIMLET6SHAPE: TShape;
    CIMLET6PANEL: TPanel;
    Shape5: TShape;
    LOGOSHAPE6: TShape;
    fb6: TBitBtn;
    Panel1: TPanel;
    logo1: TImage;
    Panel2: TPanel;
    LOGO2: TImage;
    Panel3: TPanel;
    LOGO3: TImage;
    Panel4: TPanel;
    LOGO4: TImage;
    P5: TPanel;
    LOGO5: TImage;
    Panel5: TPanel;
    LOGO6: TImage;
    VODAPANEL: TPanel;
    TELENORPANEL: TPanel;
    T_COMPANEL: TPanel;
    TMOBILPANEL: TPanel;
    NEOPANEL: TPanel;
    TESCOMOBILPANEL: TPanel;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    Image6: TImage;
    Image7: TImage;
    Image8: TImage;
    cegboxedit: TEdit;
    paysafepanel: TPanel;
    LOGOSHAPE7: TShape;
    LOGO7: TImage;
    FB7: TBitBtn;
    SECONDEDIT: TEdit;
    VAROKPANEL: TPanel;
    Label11: TLabel;
    Label12: TLabel;


    procedure BackSpaceHandle;
    procedure QackSpaceHandle;
    procedure BarangoloGombClick(Sender: TObject);
    procedure CTRL1GombEnter(Sender: TObject);
    procedure CTRL1GombExit(Sender: TObject);
    procedure CTRL1GombMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Fb1Click(Sender: TObject);
    procedure FB1Enter(Sender: TObject);
    procedure TestTopupRutin;
    procedure LiveTopupRutin;
    procedure CancelTopupRutin;

    procedure FeltoltoGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);

    procedure KartyatValasztott;
    procedure KilepoTimerTimer(Sender: TObject);
    procedure KontrolGombClick(Sender: TObject);
    procedure KontrolGombEnter(Sender: TObject);
    procedure KontrolGombExit(Sender: TObject);
    procedure Logo1MouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
    procedure Logotakaras;
    procedure Logo1Click(Sender: TObject);
    procedure LogotValasztott;
    procedure MegsemGombClick(Sender: TObject);
    procedure PaySafetValasztott;

    procedure TelCancelGombClick(Sender: TObject);
    procedure TelKonyveloGombClick(Sender: TObject);
    procedure TranzCancelGombClick(Sender: TObject);
    procedure TVisszaGombClick(Sender: TObject);
    procedure LogoBekapcsol(_lss: integer);

    function NumByteBeiro(_byte: integer): boolean;
    function QumByteBeiro(_byte: integer): boolean;
    procedure CTRL1GOMBClick(Sender: TObject);
    procedure BAR1GOMBClick(Sender: TObject);
    procedure RETURNGOMBClick(Sender: TObject);
    procedure TranzakcioMenet;
    procedure ReplyErtekelo;
    procedure TombBetoltes;
  
    procedure eloKerelem;
    procedure NeoPhoneMunkalapdisplay;
    procedure PHIDEEDITKeyPress(Sender: TObject; var Key: Char);
    procedure QHIDEEDITKeyPress(Sender: TObject; var Key: Char);
    procedure FELTOLTOGOMBEnter(Sender: TObject);
    procedure CIMLET1PANELEnter(Sender: TObject);
    procedure CIMLET1PANELClick(Sender: TObject);
    procedure HIDEEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
 
    procedure CIMLET1PANELMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure cegboxeditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
 
    procedure LOGO7Click(Sender: TObject);
    procedure SECONDEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);

    function GetxrAdatok: boolean;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  TELEFONFORM: TTELEFONFORM;

  _aktShape  : TShape;
  _aktPanel  : TPanel;
  _aktButton : TBitbtn;

  _phMutato,_phplus,_bill,_lentel,_qq,_aktTag : integer;
  _loss,_fts,_egysegar,_arindex,_aktfogyar: integer;
  _cimletDarab,_aktcikkszam,_aktforint,_utloss: integer;

  _aktfonszam,_retelefonszam,_tnfls,_cegkezdonums: string;
  _cegsecondNums: string;
  _cegboxIndex: integer;
  _tLogo: array[1..7] of TPanel;

  _nev : string;
  _van,_jo: boolean;



implementation

uses Unit10;

{$R *.dfm}

// =============================================================================
            procedure TTELEFONFORM.FormActivate(Sender: TObject);
// =============================================================================

var i: integer;

begin
  Top    := _top;
  Left   := _left;
  Width  := 1024;
  Height := 768;

  TombBetoltes;

  VarokPanel.Visible         := False;
  Logotakaro.Visible         := False;
  KudarcPanel.Visible        := False;
  VisszaigazoloPanel.Visible := False;
  Tcompanel.Visible          := False;
  CimletShape.Visible        := False;
  HideEdit.Visible           := false;
  Munkalap.Visible           := False;
  NEOMunkalap.Visible        := False;
  Retakaropanel.Visible      := False;
  BarangoloPanel.Visible     := False;
  KontrolPanel.Visible       := False;
  ReturnGomb.Visible         := False;
  Ugyfelpanel.Visible        := False;
  FizetendoPanel.Visible     := False;
  TVisszagomb.Visible        := True;
  KeremLabel.Visible         := True;
  pHideedit.Visible          := False;
  qHideedit.Visible          := False;
  PaySafePanel.visible       := true;
  RetakaroPanel.Caption      := '';

  _mResult                   := 2;
  _PhPlus := -1;
  _loss := 1;

  // A kártyaösszegek gombjainak aktivizásása

   for i := 1 to 10 do
     begin
       _aktbutton := _fb[i];
       _aktbutton.Enabled := True;
       if i>7 then _aktbutton.Visible := false;
     end;

  ForintPanel.Font.Color := clBlack;
  _tipus := 'T';
end;


// =============================================================================
           procedure TTelefonForm.TVisszaGombClick(Sender: TObject);
// =============================================================================

begin
  Form1.Logbair('Vissza a menüre a telefon-feltöltö oldalról');
  Form1.Logbair(dupestring('-',80));

  _fizetendo  := 0;
  ModalResult := 2;
end;

// =============================================================================
   procedure TTelefonForm.LOGO1MouseMove(Sender: TObject; Shift: TShiftState;
                                                                X, Y: Integer);
// =============================================================================

begin
  _LOSS := TImage(sender).tag;
  if _loss=_utloss then exit;
  _utloss := _loss;
  _aktbutton := _fb[_loss];

  _nev := _aktbutton.name;
  _van := _aktbutton.visible;
  _jo  := _aktbutton.enabled;

  ActiveControl := _aktButton;
end;


// =============================================================================
           procedure TTelefonForm.LogoBekapcsol(_lss: integer);
// =============================================================================

var i: integer;

begin
  for i := 1 to 6 do _tLogo[i].Visible := false;
  _tlogo[_Lss].Visible := true;
  _tlogo[_lss].Repaint;
end;


// =============================================================================
                        procedure TTelefonForm.Logotakaras;
// =============================================================================

begin
  ForintPanel.Visible := true;
  CikknevPanel.Caption := '';
  LogoBekapcsol(_loss);
  case _loss of
    1: begin
         Logotakaro.Caption := 'T-MOBIL';
         _cimletDarab := 5;
       end;

    2: begin
         Logotakaro.Caption := 'TELENOR';
         _cimletDarab := 6;
       end;

    3: begin
         Logotakaro.Caption := 'VODAFON';
         _cimletDarab := 5;
       end;

    4: begin
         Logotakaro.Caption := 'T-COM';
         ForintPanel.Visible := False;
         TcomPanel.Visible := True;
       end;

     5: begin
          _CimletDarab := 4;
          Logotakaro.caption := 'NeoPhone';
        end;

     6: begin
          _cimletdarab := 5;
          Logotakaro.caption := 'Tesco Mobile';
        end;
    end;
 with Logotakaro do
   begin
     top := 128;
     Left := 56;
     Visible := true;
   end;

end;

// =============================================================================
              procedure TTELEFONFORM.LOGO1Click(Sender: TObject);
// =============================================================================

begin
  PaySafePanel.Visible := False;
  _loss := TImage(sender).tag;
  _szolgaltato := _tFirm[_loss];
  Form1.Logbair('Választott szolgáltató: '+ _szolgaltato);

  _cegKezdoNums := inttostr(_forenumber[_loss]);
  Cegboxedit.Text := _cegkezdonums;
  rmsPanel.Caption := _cegKezdoNums;
  rmspanel.repaint;
  Logotvalasztott;
end;

// =============================================================================
                    procedure TTelefonForm.LogotValasztott;
// =============================================================================

var i: integer;

begin
  for i := 1 to 6 do
    begin
      _aktbutton := _fb[i];
      _aktbutton.Enabled := false;
    end;
  Logotakaras;
  _szolgaltatas := 'Mobilfeltoltes';

  if _loss=2 then _tipus := 'N';   // telenor !!!
  if _loss=3 then _tipus := 'V';   // vodafon !!!

  if _loss = 4 then
    begin
      ActiveControl := kontrolGomb;
      exit;
    end;

  if _loss = 6 then _loss := 7;
  if _loss = 5 then _loss := 6;

  for i := 1 to _cimletDarab do
    begin
      _aktcikkszam := _mobilcikk[_loss,i];
      _aktforint := _cikkar[_aktcikkszam];
      _aktshape := _csh[i];
      _aktpanel := _ft[i];
      _aktpanel.Caption := Form1.FtForm(_aktforint);
      _aktshape.Visible := True;
      _aktpanel.Visible := True;
    end;
  CimletShape.Height := 249;
  if _cimletDarab<5 then Cimletshape.Height := 168;

  CimletShape.Visible := True;
  ActiveControl := Cimlet1Panel;
end;

// =============================================================================
               procedure TTELEFONFORM.megsemgombClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 2;
end;

// =============================================================================
          function TTelefonForm.NumByteBeiro(_byte: integer): boolean;
// =============================================================================

begin
  Result := False;
  _aktPanel := _phnumPanel[_phmutato+_phplus];
  _aktpanel.caption := chr(_byte);
  _aktpanel.Color := $A0FFFF;
  inc(_phmutato);
  if _phMutato>7 then
    begin
      Result := true;
      Exit;
    end;
  _aktShape := _phnumShape[_phmutato+_phplus];
  _aktShape.Brush.color := $A0FFFF;
end;


// =============================================================================
                      procedure TTelefonform.BackspaceHandle;
// =============================================================================

begin
  if _phMutato=1 then exit;

  _aktpanel := _phnumPanel[_phMutato+_phplus];
  _aktShape := _phnumshape[_phMutato+_phplus];

  _aktPanel.Color := clWhite;
  _aktshape.Brush.color := clWhite;

  dec(_phMutato);

  _aktpanel := _phnumPanel[_phMutato+_phplus];
  _aktPanel.Caption := '';
  _aktpanel.Color := clWhite;
end;

// =============================================================================
          procedure TTELEFONFORM.TELCANCELGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 2;
end;

// =============================================================================
         procedure TTelefonForm.TelKonyveloGombClick(Sender: TObject);
// =============================================================================


var _retelefon: string;
    i: integer;

begin
  IF (_loss<5) OR (_loss=7) then
    begin

      _cegkezdonums := cegboxedit.Text;
      _cegSecondNums := RsecondPanel.Caption;

      _telefonszam := _cegkezdonums+_cegsecondNums;


   //   if _loss=7 then _telefonszam := Mspanel.Caption + '1'
   //   else _telefonszam := Mspanel.Caption + '0';
   
      _retelefon := _telefonszam;
      for i := 1 to 7 do
        begin
          _aktpanel := _phnumpanel[i];
          _telefonszam := _telefonszam + _aktpanel.Caption;

          _aktpanel := _phnumpanel[i+7];
          _retelefon := _retelefon + _aktpanel.Caption;
        end;
    end else
    begin
       _telefonszam :='';
       _retelefon := '';
       for i := 1 to 10 do
         begin
           _aktpanel := _qhnumpanel[i];
           _telefonszam := _telefonszam + _aktpanel.caption;
           _aktpanel := _qhnumpanel[i+10];
           _retelefon := _retelefon + _aktpanel.caption;
         end;
    end;

   Form1.Logbair('Beadott telefonszám: '+_telefonszam);
   if _telefonszam<>_retelefon then
     begin
       Form1.Logbair('A megismételt telefonszám nem egyezik');
       Showmessage('A MEGISMÉTELT TELEFONSZÁM ELTÉR AZ EREDETITÖL');
       TelCancelGombClick(NIL);
       exit;
     end;

   TelkonyveloGomb.Enabled := False;
   TelCancelGomb.Enabled   := False;
   GombTakaroPanel.Visible := True;
   Tvisszagomb.Visible     := False;
   KeremLabel.Visible      := False;
   reTakaroPanel.Visible   := True;

   // --------------- 1. Feltöltö iránti test kérelem --------------------------

   _httpTipus := 'TEST TOPUP';
   _tranzakcioOke := 0;

   with VarokPanel do
     begin
       top := 296;
       Left:= 24;
       Visible := True;
       repaint;
     end;

   TranzakcioMenet;
   VarokPanel.visible := False;

   // Nem jött pozitiv válasz a test-kérelemre: Kijelzi és kilép

   if _tranzakcioOke<>1 then
     begin
       Form1.Logbair('Negativ válasz érkezett: '+_hibauzenet);
       Form1.Logbair('Sikertelen telefonfeltöltés');

       Tvisszagomb.Visible := True;
       HibaPanel.Caption   := _hibauzenet;
       ForintPanel.caption := '0 Ft';
       Forintpanel.Visible := True;

       with Kudarcpanel do
         begin
           Top     := 434;
           Left    := 280;
           Visible := true;
         end;
       Kilepotimer.Enabled := True;
       Exit;
     end;

   // A feltöltés test kérelem elfogadva - Tranzakciószám megküldve:

   Form1.Logbair('A kérést elfogadta a kupon kft');
   with visszaigazolopanel do
     begin
       Top     := 440;
       Left    := 270;
       Visible := True;
       repaint;
     end;

   // Most eldönthetö, hogy kéri-e az ügyfél a szolgáltatást:

   Activecontrol := FeltoltoGomb;
end;

// =============================================================================
           procedure TTELEFONFORM.FELTOLTOGOMBClick(Sender: TObject);
// =============================================================================

begin

  // Az ügyfél kéri a visszaigazolt telefon feltöltést:

  VisszaIgazoloPanel.visible := False;
  _kellafas := False;
  EloKerelem
end;

// =============================================================================
                     procedure TTelefonForm.EloKerelem;
// =============================================================================

begin
  //  ITT TÉNYLEGESEN TÖLTI A TELEFONT

   Form1.Logbair('Kéri az elözetesen megadott telefon feltöltését');

  // A konfirmált 'élõ' kérelem beküldése:

  _httpTipus := 'LIVE TOPUP';
  TranzakcioMenet;

  // Most nem jött pozitiv válasz, igy a tranzakció törölve, és vissza a fõmenüre

  if _tranzakcioOke<>1 then
    begin
       Form1.Logbair('Negativ visszajelzés: ' + _hibauzenet);
       HibaPanel.Caption   := _hibauzenet;
       ForintPanel.caption := '0 Ft';
       Forintpanel.Visible := True;
       with Kudarcpanel do
         begin
           Top     := 434;
           Left    := 280;
           Visible := true;
         end;
       _mResult := 2;
       Form1.Logbair('Visszalép a fömenüre');
       Kilepotimer.Enabled := true;
       Exit;
    end;

  // A kérelem visszaigazolva végelegesen, lehet könyvelni és nyomtatni a blokkot:

  inc(_lastTelefon);
  _bizonylatszam := 'MF'+ Form1.HatnulEle(_lastTelefon);

  Form1.Konyveles(_tipus);
  Form1.TelefonBlokk;

  if _kellafas then Form1.TelafasSzamla;

  _kellafas := False;
  RetakaroPanel.Caption := 'SIKERES TRANZAKCIÓ !';
  ReturnGomb.Visible := True;

  // A return gombbal visszatérhet a fömenüre:

  ActiveControl := ReturnGomb;
end;


// =============================================================================
            procedure TTelefonForm.Fb1Enter(Sender: TObject);
// =============================================================================


var i: integer;

begin
  _loss := TBitbtn(sender).Tag;
  for i := 1 to 7 do
    begin
      _aktshape := _logoshapes[i];
      _aktshape.Brush.Color := clWhite;
    end;
  _aktshape := _logoShapes[_loss];
  _aktshape.Brush.Color := clRed;
end;



// =============================================================================
              procedure TTelefonForm.Fb1Click(Sender: TObject);
// =============================================================================

begin
  _loss := TBitbtn(Sender).Tag;
  _szolgaltato := _tFirm[_loss];
  LogotValasztott;
end;

// =============================================================================
         procedure TTelefonForm.TranzCancelGombClick(Sender: TObject);
// =============================================================================

begin

  // Mégsem kérjük a testkérelmet visszaigazolt szolgáltatást:(és Vissza a fömenüre)

  VisszaIgazoloPanel.Visible := false;
  Form1.Logbair('Mésem kéri a telefonfeltöltést');

  _httpTipus := 'CANCEL TOPUP';
  TranzakcioMenet;

  _mResult := 2;
  KilepoTimer.Enabled := true;
end;

// =============================================================================
          procedure TTelefonForm.KilepoTimerTimer(Sender: TObject);
// =============================================================================

begin
  KilepoTimer.Enabled := False;
  Form1.Logbair('Vissza a fömenüre - a telefonfeltöltö lapról');
  Form1.Logbair(dupestring('-',80));
  ModalResult := _mResult;
end;


// =============================================================================
            procedure TTelefonForm.KontrolGombClick(Sender: TObject);
// =============================================================================

begin
  ForintPanel.Visible := true;
  with KontrolPanel do
    begin
      Top     := 264;
      Left    := 190;
      Visible := true;
    end;
  _tcomtip := 1;
  ActiveControl := Ctrl1Gomb;
end;

// =============================================================================
          procedure TTelefonForm.BarangoloGombClick(Sender: TObject);
// =============================================================================

begin
  ForintPanel.Visible := true;

  Bar1gomb.Caption := Form1.FtForm(_cikkar[74]);
  Bar2gomb.Caption := Form1.FtForm(_cikkar[75]);
  Bar3gomb.Caption := Form1.FtForm(_cikkar[76]);

  with BarangoloPanel do
    begin
      Top := 264;
      Left := 232;
      Visible := True;
    end;
    _tcomtip :=2;
  ActiveControl := Bar1Gomb;
end;

// =============================================================================
            procedure TTelefonForm.CTRL1GombEnter(Sender: TObject);
// =============================================================================

begin
  _cikkszam := TBitbtn(sender).Tag;
  _fizetendo := _cikkar[_cikkszam];
  ForintPanel.Caption := Form1.FtForm(_fizetendo);
  TBitbtn(sender).Font.Color := clRed;
end;

// =============================================================================
            procedure TTelefonForm.CTRL1GombExit(Sender: TObject);
// =============================================================================

begin
  TBitbtn(Sender).Font.Color := clBlack;
end;

// =============================================================================
        procedure TTELEFONFORM.CTRL1GombMouseMove(Sender: TObject;
                                           Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  ActiveControl := TBitbtn(sender);
end;

// =============================================================================
           procedure TTelefonForm.KontrolGombEnter(Sender: TObject);
// =============================================================================

begin
  TBitBtn(sender).Font.Style := [fsBold];
end;

// =============================================================================
            procedure TTelefonForm.KontrolGombExit(Sender: TObject);
// =============================================================================

begin
  TBitbtn(sender).Font.Style := [];
end;

// =============================================================================
             procedure TTelefonForm.CTRL1GombClick(Sender: TObject);
// =============================================================================


var i: integer;
begin
  Kontrolpanel.Visible := false;
  _cikkszam := TBitbtn(Sender).Tag;
  _fizetendo := _cikkar[_cikkszam];
  _szolgaltatas := _cikknev[_cikkszam];

  CikknevPanel.Caption := _szolgaltatas;
  for i := 1 to 14 do
    begin
      _aktpanel := _phNumPanel[i];
      _aktpanel.Caption := '';
    end;

  _cegboxindex := 1;
  RMsPanel.Caption := '3';

  _phplus := 0;
  _phMutato := 1;
  with RetakaroPanel do
    begin
      Top  := 445; // _top + 435;
      Left := 276; //_left + 280;
      Visible := true;
      repaint;
    end;

   _tnfLs := CegboxEdit.text;
   RMSpanel.Caption := _tnflS;
   pHideEdit.visible := true;
   with Munkalap do
    begin
      Top := 280;
      Left := 48;
      Visible := True;
    end;
  Cegboxedit.Enabled := true;  
  SpN1.Brush.Color := $A0FFFF;
  ActiveControl := pHideedit;
end;

// =============================================================================
            procedure TTelefonForm.Bar1GombClick(Sender: TObject);
// =============================================================================

var i: integer;

begin
  BarangoloPanel.Visible := false;
  _cikkszam := TBitbtn(Sender).Tag;
  _fizetendo := _cikkar[_cikkszam];
  _szolgaltatas := _cikknev[_cikkszam];

  CikknevPanel.Caption := _szolgaltatas;
  for i := 1 to 14 do
    begin
      _aktpanel := _phNumPanel[i];
      _aktpanel.Caption := '';
    end;


//  CegBox.Itemindex := 1;
//  MsPanel.Caption := '3';

  RMsPanel.Caption := '3';
  if _loss=7 then
    begin
      SecondEdit.Text := '1';
      rSecondPanel.Caption := '1';
    end else
    begin
      SecondEdit.Text := '0';
      rSecondPanel.Caption := '0';
    end;

  _phplus := 0;
  _phMutato := 1;
  with RetakaroPanel do
    begin
      Top := 435; //_top + 435;
      Left := 280;  // _left + 280;
      Visible := true;
    end;
   pHideEdit.visible := true;
   with Munkalap do
    begin
      Top := 280;
      Left := 48;
      Visible := True;
    end;
  SpN1.Brush.Color := $A0FFFF;
  ActiveControl := pHideedit;
end;

// =============================================================================
              procedure TTelefonForm.ReturnGombClick(Sender: TObject);
// =============================================================================

begin
  _fizetendo := 0;
  ModalResult := 1;
end;

// =============================================================================
              procedure TTelefonForm.NeoPhoneMunkalapdisplay;
// =============================================================================


var i: integer;

begin
 for i := 1 to 20 do
    begin
      _aktpanel := _qhNumPanel[i];
      _aktpanel.Caption := '';
    end;

  _phplus := 0;
  _phMutato := 1;
  with RetakaroPanel do
    begin
      Top :=435;  //  _top + 435;
      Left := 280; // _left + 280;
      Visible := true;
    end;

  with NeoMunkalap do
    begin
      Top := 280;
      Left := 48;
      Visible := True;
    end;
   with Munkalap do
    begin
      Top := 280;
      Left := 48;
      Visible := True;
    end;
  SQN1.Brush.Color := $A0FFFF;
  qHideedit.Visible := true;
  ActiveControl := qHideedit;
end;


// =============================================================================
    procedure TTELEFONFORM.PHIDEEDITKeyPress(Sender: TObject; var Key: Char);
// =============================================================================

begin
    if _phPlus<0 then exit;
   _bill := ord(key);

   if _bill=8 then
     begin
       BackSpaceHandle;
       Exit;
     end;

   if (_bill>47) and (_bill<58) then
     begin
       if not NumByteBeiro(_bill) then exit;
       if _phPlus=0 then
         begin
           _phMutato := 1;
           _phPlus := 7;
           RetakaroPanel.Visible := False;
           exit;
         end else
         begin
           _phPlus := -10;
           TelkonyveloGomb.Enabled := True;
           TelCancelGomb.Enabled := True;
           GombtakaroPanel.Visible := false;
           Activecontrol := TelKonyveloGomb;
           exit;
         end;
     end;
end;

// =============================================================================
   procedure TTELEFONFORM.QHIDEEDITKeyPress(Sender: TObject; var Key: Char);
// =============================================================================

begin
   if _phPlus<0 then exit;
   _bill := ord(key);

   if _bill=8 then
     begin
       QackSpaceHandle;
       Exit;
     end;

   if (_bill>47) and (_bill<58) then
     begin
       if not QumByteBeiro(_bill) then exit;
       if _phPlus=0 then
         begin
           _phMutato := 1;
           _phPlus := 10;
           RetakaroPanel.Visible := False;
           exit;
         end else
         begin
           _phPlus := -10;
           TelkonyveloGomb.Enabled := True;
           TelCancelGomb.Enabled := True;
           GombtakaroPanel.Visible := false;
           Activecontrol := TelKonyveloGomb;
           exit;
         end;
     end;

end;

// =============================================================================
          function TTelefonForm.QumByteBeiro(_byte: integer): boolean;
// =============================================================================

begin
  Result := False;
  _aktPanel := _qhnumPanel[_phmutato+_phplus];
  _aktpanel.caption := chr(_byte);
  _aktpanel.Color := $A0FFFF;
  inc(_phmutato);
  if _phMutato>10 then
    begin
      Result := true;
      Exit;
    end;
  _aktShape := _qhnumShape[_phmutato+_phplus];
  _aktShape.Brush.color := $A0FFFF;
end;


// =============================================================================
                      procedure TTelefonform.QackspaceHandle;
// =============================================================================

begin
  if _phMutato=1 then exit;

  _aktpanel := _qhnumPanel[_phMutato+_phplus];
  _aktShape := _qhnumshape[_phMutato+_phplus];

  _aktPanel.Color := clWhite;
  _aktshape.Brush.color := clWhite;

  dec(_phMutato);

  _aktpanel := _qhnumPanel[_phMutato+_phplus];
  _aktPanel.Caption := '';
  _aktpanel.Color := clWhite;
end;

// =============================================================================
        procedure TTELEFONFORM.FELTOLTOGOMBEnter(Sender: TObject);
// =============================================================================

begin
  ForintPanel.caption := Form1.FtForm(_fizetendo);
end;

// =============================================================================
         procedure TTELEFONFORM.CIMLET1PANELEnter(Sender: TObject);
// =============================================================================

var _aktstring: string;
    i: integer;
begin
  _aktTag := Tpanel(sender).tag;
  for i := 1 to _cimletDarab do _csh[i].Brush.Color := clWhite;

  _aktpanel := _ft[_aktTag];
  _aktShape := _csh[_aktTag];
  _aktstring := _aktpanel.caption;

  _aktShape.Brush.Color := clred;

  ForintPanel.Caption := _aktString;
  ForintPanel.Repaint;
  Hideedit.Visible := True;
  ActiveControl := Hideedit;
end;


// =============================================================================
        procedure TTELEFONFORM.CIMLET1PANELClick(Sender: TObject);
// =============================================================================

begin
 // _aktpanel := TPanel(sender);
 // ActiveControl := _aktpanel;
 KartyatValasztott;
end;



// =============================================================================
      procedure TTELEFONFORM.HIDEEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  _bill := ord(key);
  case _bill of
     37: // balra
       begin
         if (_akttag=1) or (_aktTag=3) or (_akttag=5) then exit;
         dec(_aktTag);
       end;

     39: // jobbra
       begin
         if (_akttag=2) or (_aktTag=4) or (_akttag=6) then exit;
         inc(_aktTag);

       end;

     38: // felfele
       begin
         if _aktTag<3 then exit;
         dec(_aktTag);
         dec(_akttag);
       end;

     40: // lefele
       begin
         if _aktTag>4 then exit;
         inc(_akttag);
         inc(_akttag);
       end;

     13: Begin
           KArtyatValasztott;
           exit;
         end;
  end;
  if _akttag>_cimletDarab then _akttag := _cimletDarab;
  ActiveControl := _ft[_aktTag];
end;

// =============================================================================
                   procedure TTelefonForm.KartyatValasztott;
// =============================================================================

var i: integer;
begin
  HideEdit.Visible := False;

  _cikkszam := _mobilcikk[_loss,_aktTag];
  _fizetendo := _cikkar[_cikkszam];

  Form1.Logbair('Valasztott cimlet: ('+inttostr(_cikkszam)+') '+inttostr(_fizetendo)+' Ft');

  ForintPanel.caption := Form1.FtForm(_fizetendo);
  Forintpanel.Visible := True;
  with GombTakaroPanel do
    begin
      Top := 304;
      Left := 16;
      Visible := True;
    end;

  if _loss = 6 then
    begin
      Form1.Logbair('NeoPhone-t választott');
      NeoPhoneMunkalapDisplay;
      exit;
    end;


  for i := 1 to 14 do
    begin
      _aktpanel := _phNumPanel[i];
      _aktPanel.Color := clWhite;
      _aktpanel.Caption := '';
      _aktshape := _phnumShape[i];
      _aktshape.Brush.Color := clWhite;
    end;

//  MsPanel.Caption := chr(48+_forenumber[_loss]);
//  RMsPanel.Caption := chr(48+_forenumber[_loss]);

  _phplus := 0;
  _phMutato := 1;
  with RetakaroPanel do
    begin
      Top := 435;  //  _top + 435;
      Left := 280; // _left + 280;
      Visible := true;
    end;


//  CegBox.ItemIndex := 1;
//  RmsPanel.Caption := '3';
  pHideEdit.visible := true;
  if _loss=7 then
    begin
      SecondEdit.Text := '1';
      rSecondPanel.Caption := '1';
    end else
    begin
      SecondEdit.Text := '0';
      rSecondPanel.Caption := '0';
    end;


  with Munkalap do
    begin
      Top := 280;
      Left := 48;
      Visible := True;
    end;
  SpN1.Brush.Color := $A0FFFF;
  ActiveControl := pHideedit;

end;

// ==============================================================
   procedure TTELEFONFORM.CIMLET1PANELMouseMove(Sender: TObject;
                     Shift: TShiftState; X, Y: Integer);
// ==============================================================


begin
  _aktTag := TPanel(sender).Tag;
  ActiveControl := _ft[_akttag];
end;

// =============================================================================
     procedure TTELEFONFORM.cegboxeditKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  _cegkezdoNums := CegboxEdit.text;
  RmsPanel.Caption := _cegkezdonums;
  ActiveControl := Secondedit;
end;


procedure TTELEFONFORM.SECONDEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  IF ord(key)<>13 then exit;
  _cegsecondNums := Secondedit.text;
  RSecondPanel.Caption := _cegsecondNums;
  Activecontrol := pHideEdit;
end;


// =============================================================================
             procedure TTELEFONFORM.LOGO7Click(Sender: TObject);
// =============================================================================

begin
  PaysafetValasztott;
end;

// =============================================================================
                 procedure TTelefonForm.PaySafetValasztott;
// =============================================================================

var _ok : integer;

begin
  Form1.Logbair(dupestring('-',80));
  Form1.Logbair('PAYSAFECARD-ot választott');
  _ok := PaySafeForm.ShowModal;
  Form1.Logbair('A paysafecard resultja: '+inttostr(_ok));
  ModalResult := _ok;
end;

// #############################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                procedure TTelefonForm.TranzakcioMenet;
// =============================================================================

Begin
  _tranzakcioOke := 0;
  
  if _httpTipus = 'TEST TOPUP' then
    begin
      TestTopupRutin;
      exit;
    end;

  if _httpTipus = 'LIVE TOPUP' then
    begin
      LiveTopupRutin;
      exit;
    end;

  if _httpTipus = 'CANCEL TOPUP' then  CancelTopupRutin;

end;

// =============================================================================
        procedure TTelefonForm.TestTopupRutin;
// =============================================================================


// Mobilfeltöltö TEST kérés elküldése:

var _rr: integer;

begin
  _AKCIO := 'TEST';

  _reqrow[1] := '<Message>';
  _reqrow[2] := '<MessageType>TEST TOPUP</MessageType>';
  _reqrow[3] := '<TerminalId>' + _terminalid + '</TerminalId>';
  _reqrow[4] := '<UserName>' + _username + '</UserName>';
  _reqrow[5] := '<UserPassword>' + _password + '</UserPassword>';
  _reqrow[6] := '<ProductId>'+inttostr(_cikkszam)+'</ProductId>';
  _rr := 6;
  if _loss=3 then
    begin
      _reqrow[7] := '<Amount>'+inttostr(_fizetendo)+'</Amount>';
      _rr := 7;
    end;
  _reqrow[_rr+1] := '<PhoneNumber>'+_telefonszam+'</PhoneNumber>';
  _reqrow[_rr+2] := '<LimitCheck>Y</LimitCheck>';
  _reqrow[_rr+3] := '</Message>';
  _reqPieces := _rr+3;

  Form1.CsomagKuldes;

  form1.Logbair('Csomagküldés feldolgozva, lehet kiértékelni');

  if _reppieces=0 then
    begin
      _hibauzenet := 'CSOMAG KÜLDÉS HIBA !';
      _mResult := 2;
      KilepoTimer.Enabled := true;
      Exit;
    end;
  ReplyErtekelo;
end;

//
// =============================================================================
        procedure TTELEFONForm.REPLYErtekelo;
// =============================================================================

begin

  if not GetxRAdatok then
    begin
      _MResult := 2;
      KilepoTimer.Enabled := true;
      exit;
    end;

  Form1.Logbair('A jelenlegi akcio: ' + _akcio);

  if _akcio='TEST' then
    begin
      val(_xrAmount,_fizetendo,_code);
      if _code<>0 then _fizetendo := 0;
      with TelefonForm.FizetendoPanel do
        begin
          Font.Color := clBlue;
          Caption := Form1.FtForm(_Fizetendo);
          Visible := true;
          Repaint;
        end;
    end;

  if _akcio='LIVE' then
    begin
      val(_xrAmount,_Fizetendo,_code);
      if _code<>0 then _Fizetendo := 0;

      if _Fizetendo=0 then
        begin
          _hibaUzenet := 'ÉRTÉK NÉLKÜLI VÁLASZ ÉRKEZETT';
          Exit;
        end;

      with TelefonForm.FizetendoPanel do
        begin
          Font.Color := clRed;
          Caption := Form1.FtForm(_Fizetendo);
          Repaint;
        end;
    END;
end;


// =============================================================================
                   procedure TTELEFONForm.LiveTopupRutin;
// =============================================================================

// Mobilfeltöltö LIVE kérésének elküldése:

begin

  _akcio := 'LIVE';

  _reqrow[1] := '<Message>';
  _reqrow[2] := '<MessageType>LIVE TOPUP</MessageType>';
  _reqrow[3] := '<TransactionId>'+_xrTransactionId+'</TransactionId>';
  _reqrow[4] := '</Message>';
  _reqpieces := 4;

  Form1.CsomagKuldes;

  if _reppieces=0 then
    begin
      _hibauzenet := 'CSOMAG KÜLDÉS HIBA !';
      _mResult := 2;
      KilepoTimer.Enabled := true;
      Exit;
    end;
  ReplyErtekelo;
end;



// =============================================================================
                  function TTelefonForm.GetxrAdatok: boolean;
// =============================================================================


begin
  result := False;

  _xrMessageType       := trim(Form1.GetMezo('MessageType'));
  _xrStatusId          := trim(Form1.Getmezo('StatusId'));
  _xrStatusDescription := trim(Form1.Getmezo('StatusDescription'));
  _xrTransactionId     := trim(Form1.Getmezo('TransactionId'));
  _xrTransactionDate   := trim(Form1.Getmezo('TransactionDate'));

  _xrProductId         := trim(Form1.Getmezo('ProductId'));
  _xrProductName       := trim(Form1.Getmezo('ProductName'));
  _xrAmount            := trim(Form1.Getmezo('Amount'));
  _xrPhoneNumber       := trim(Form1.Getmezo('PhoneNumber'));

  _xrOutletName        := trim(Form1.Getmezo('OutletName'));
  _xrOutletAddress     := trim(Form1.Getmezo('OutletAddress'));
  _xrOutletTaxNo       := trim(Form1.Getmezo('OutletTaxNo'));

  _xrOperatorId        := trim(Form1.Getmezo('OperatorId'));
  _xrReceiptNumber     := trim(Form1.Getmezo('ReceiptNumber'));
 
  _status := _xrStatusId;

  If leftstr(_status,4)<>'00OK' then
    begin
     _HibaUzenet := _xrStatusDescription;
    end
    else
    begin
       _tranzakcioOke := 1;
      _tranzakcio := _xrTransactionId;
      result := true;
    end
end;


// =============================================================================
                      procedure TTELEFONForm.CANCELTOPUPrutin;
// =============================================================================

begin

  _reqrow[1] := '<Message>';
  _reqrow[2] := '<MessageType>CANCEL TOPUP</MessageType>';
  _reqrow[3] := '<TransactionId>'+_xrTransactionId+'</TransactionId)';
  _reqrow[4] := '</Message>';

  _reqpieces := 4;

  Form1.CsomagKuldes;

  if _reppieces=0 then
    begin
      _hibauzenet := 'HTTP HIBA !';
      _mResult := 2;
      KilepoTimer.Enabled := true;
      Exit;
    end;

  ReplyErtekelo;
end;


// =============================================================================
                    procedure TTelefonForm.TombbeToltes;
// =============================================================================

var i: integer;

begin
  _fb[1] := Fb1;
  _fb[2] := Fb2;
  _fb[3] := Fb3;
  _fb[4] := Fb4;
  _fb[5] := Fb5;
  _fb[6] := Fb6;
  _fb[7] := FB7;

  _logoshapes[1] := logoshape1;
  _logoshapes[2] := logoshape2;
  _logoshapes[3] := logoshape3;
  _logoshapes[4] := logoshape4;
  _logoshapes[5] := logoshape5;
  _logoshapes[6] := logoshape6;
  _logoshapes[7] := logoshape7;

  _logos[1] := Logo1;
  _logos[2] := Logo2;
  _logos[3] := Logo3;
  _logos[4] := Logo4;
  _logos[5] := Logo5;
  _logos[6] := Logo6;
  _logos[7] := Logo7;

  _sh[1] := Logoshape1;
  _sh[2] := Logoshape2;
  _sh[3] := Logoshape3;
  _sh[4] := Logoshape4;
  _sh[5] := Logoshape5;
  _sh[6] := Logoshape6;
  _sh[7] := LogoShape7;

  _csh[1] := Cimlet1shape;
  _csh[2] := Cimlet2shape;
  _csh[3] := Cimlet3shape;
  _csh[4] := Cimlet4shape;
  _csh[5] := Cimlet5shape;
  _csh[6] := Cimlet6Shape;

  _ft[1] := Cimlet1Panel;
  _ft[2] := Cimlet2Panel;
  _ft[3] := Cimlet3Panel;
  _ft[4] := Cimlet4Panel;
  _ft[5] := Cimlet5Panel;
  _ft[6] := Cimlet6Panel;

  // T-mobil:

  _mobilcikk[1,1] := 84;
  _mobilcikk[1,2] := 6;
  _mobilcikk[1,3] := 7;
  _mobilcikk[1,4] := 8;
  _mobilcikk[1,5] := 9;

  // Telenor:

  {
  _mobilcikk[2,1] := 267;
  _mobilcikk[2,2] := 86;
  _mobilcikk[2,3] := 87;
  _mobilcikk[2,4] := 88;
  _mobilcikk[2,5] := 18;
  _mobilcikk[2,6] := 19;
  }

  _mobilcikk[2,1] := 77;
  _mobilcikk[2,2] := 16;
  _mobilcikk[2,3] := 17;

//  _mobilcikk[2,4] := 88;

  _mobilcikk[2,4] := 18;
  _mobilcikk[2,5] := 19;

  // Vodafone:

//_mobilcikk[3,1] := 13;

  _mobilcikk[3,1] := 78;
  _mobilcikk[3,2] := 10;
  _mobilcikk[3,3] := 14;
  _mobilcikk[3,4] := 11;
  _mobilcikk[3,5] := 12;

  // T-com: kontroll

  _mobilcikk[4,1] := 70;
  _mobilcikk[4,2] := 71;
  _mobilcikk[4,3] := 72;
  _mobilcikk[4,4] := 73;
  _mobilcikk[4,5] := 0;
  _mobilCikk[4,6] := 0;

  // T-com barangoló

  _mobilcikk[5,1] := 74;
  _mobilcikk[5,2] := 75;
  _mobilcikk[5,3] := 76;
  _mobilcikk[5,4] := 0;
  _mobilcikk[5,5] := 0;
  _mobilcikk[5,6] := 0;

  // neoPhone

  _mobilcikk[6,1] := 80;
  _mobilcikk[6,2] := 81;
  _mobilcikk[6,3] := 82;
  _mobilcikk[6,4] := 83;
  _mobilcikk[6,5] := 0;
  _mobilCikk[6,6] := 0;


   // Tesco

  _mobilcikk[7,1] := 89;
  _mobilcikk[7,2] := 268;
  _mobilcikk[7,3] := 91;
  _mobilcikk[7,4] := 92;
  _mobilcikk[7,5] := 93;
  _mobilCikk[7,6] := 0;


  // Telefonszám digit-panelek:

  _phnumPanel[1] := Pn1;
  _phnumPanel[2] := Pn2;
  _phnumPanel[3] := Pn3;
  _phnumPanel[4] := Pn4;
  _phnumPanel[5] := Pn5;
  _phnumPanel[6] := Pn6;
  _phnumPanel[7] := Pn7;

  _phnumPanel[8] := rPn1;
  _phnumPanel[9] := rPn2;
  _phnumPanel[10]:= rPn3;
  _phnumPanel[11]:= rPn4;
  _phnumPanel[12]:= rPn5;
  _phnumPanel[13]:= rPn6;
  _phnumPanel[14]:= rPn7;

  _qhnumPanel[1] := Qn1;
  _qhnumPanel[2] := Qn2;
  _qhnumPanel[3] := Qn3;
  _qhnumPanel[4] := Qn4;
  _qhnumPanel[5] := Qn5;
  _qhnumPanel[6] := Qn6;
  _qhnumPanel[7] := Qn7;
  _qhnumPanel[8] := Qn8;
  _qhnumPanel[9] := Qn9;
  _qhnumPanel[10]:= Qn10;

  _qhnumPanel[11]:= rQn1;
  _qhnumPanel[12]:= rQn2;
  _qhnumPanel[13]:= rQn3;
  _qhnumPanel[14]:= rQn4;
  _qhnumPanel[15]:= rQn5;
  _qhnumPanel[16]:= rQn6;
  _qhnumPanel[17]:= rQn7;
  _qhnumPanel[18]:= rQn8;
  _qhnumPanel[19]:= rQn9;
  _qhnumPanel[20]:= rQn10;


  // Telefonszám shape-keretek:

  _phnumShape[1] := sPn1;
  _phnumShape[2] := sPn2;
  _phnumShape[3] := sPn3;
  _phnumShape[4] := sPn4;
  _phnumShape[5] := sPn5;
  _phnumShape[6] := sPn6;
  _phnumShape[7] := sPn7;

  _phnumShape[8] := srPn1;
  _phnumShape[9] := srPn2;
  _phnumShape[10]:= srPn3;
  _phnumShape[11]:= srPn4;
  _phnumShape[12]:= srPn5;
  _phnumShape[13]:= srPn6;
  _phnumShape[14]:= srPn7;

  _qhnumShape[1] := sQn1;
  _qhnumShape[2] := sQn2;
  _qhnumShape[3] := sQn3;
  _qhnumShape[4] := sQn4;
  _qhnumShape[5] := sQn5;
  _qhnumShape[6] := sQn6;
  _qhnumShape[7] := sQn7;
  _qhnumShape[8] := sQn8;
  _qhnumShape[9] := sQn9;
  _qhnumShape[10]:= sQn10;

  _qhnumShape[11]:= srQn1;
  _qhnumShape[12]:= srQn2;
  _qhnumShape[13]:= srQn3;
  _qhnumShape[14]:= srQn4;
  _qhnumShape[15]:= srQn5;
  _qhnumShape[16]:= srQn6;
  _qhnumShape[17]:= srQn7;
  _qhnumShape[18]:= srQn8;
  _qhnumShape[19]:= srQn9;
  _qhnumShape[20]:= srQn10;

  _tlogo[1] := TmobilPanel;
  _tlogo[2] := TelenorPanel;
  _tlogo[3] := VodaPanel;
  _tLogo[4] := T_companel;
  _tLogo[5] := NeoPanel;
  _tLogo[6] := TescoMobilPanel;

  _Phplus := -10;  //billentyü

  for i := 1 to 6 do
    begin
      _aktshape := _csh[i];
      _aktshape.visible := False;

      _aktpanel := _ft[i];
      _aktpanel.visible := false;

    end;
end;
end.
