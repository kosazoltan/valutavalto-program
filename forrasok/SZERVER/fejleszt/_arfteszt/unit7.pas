unit Unit7;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, unit1, Buttons, jpeg;

type
  TCSOPORTDISPLAY = class(TForm)
    SH11: TShape;
    SH5: TShape;
    SH42: TShape;
    SH41: TShape;
    SH31: TShape;
    SH15: TShape;
    SH22: TShape;
    SH24: TShape;
    SH26: TShape;
    SH28: TShape;
    SH2: TShape;
    SH13: TShape;
    SH7: TShape;
    CSOPORTSHAPE: TShape;
    SH14: TShape;
    SH39: TShape;
    SH46: TShape;
    SH47: TShape;
    SH40: TShape;
    Sh1: TShape;
    SH34: TShape;
    SH36: TShape;
    SH43: TShape;
    SH37: TShape;
    SH44: TShape;
    SH38: TShape;
    SH3: TShape;
    SH10: TShape;
    SH4: TShape;
    SH12: TShape;
    SH6: TShape;
    SH23: TShape;
    SH9: TShape;
    SH32: TShape;
    SH27: TShape;
    SH45: TShape;
    SH29: TShape;
    CSOPORTLISTA: TListBox;
    CS1: TPanel;
    CS2: TPanel;
    CS3: TPanel;
    CS4: TPanel;
    CS15: TPanel;
    CS9: TPanel;
    CS10: TPanel;
    CS11: TPanel;
    CS5: TPanel;
    CS12: TPanel;
    CS22: TPanel;
    CS6: TPanel;
    CS7: TPanel;
    CS14: TPanel;
    CS19: TPanel;
    CS13: TPanel;
    CS21: TPanel;
    CS25: TPanel;
    CS27: TPanel;
    CS34: TPanel;
    CS40: TPanel;
    CS47: TPanel;
    CS46: TPanel;
    CS39: TPanel;
    CS45: TPanel;
    CS38: TPanel;
    CS44: TPanel;
    CS37: TPanel;
    CS43: TPanel;
    CS42: TPanel;
    CS49: TPanel;
    CS24: TPanel;
    CS26: TPanel;
    CS28: TPanel;
    CS32: TPanel;
    CS35: TPanel;
    SH49: TShape;
    SH21: TShape;
    CS23: TPanel;
    CS41: TPanel;
    SH30: TShape;
    SH48: TShape;
    SH8: TShape;
    SH35: TShape;
    SH16: TShape;
    SH17: TShape;
    SH18: TShape;
    SH19: TShape;
    SH20: TShape;
    SH25: TShape;
    SH33: TShape;
    SH50: TShape;
    SH51: TShape;
    SH52: TShape;
    SH53: TShape;
    SH54: TShape;
    CS8: TPanel;
    CS30: TPanel;
    CS16: TPanel;
    CS17: TPanel;
    CS18: TPanel;
    CS29: TPanel;
    CS20: TPanel;
    CS36: TPanel;
    CS48: TPanel;
    CS50: TPanel;
    CS51: TPanel;
    CS52: TPanel;
    CS53: TPanel;
    CS54: TPanel;
    CS33: TPanel;
    CS31: TPanel;
    NINCSIRODAPANEL: TPanel;
    BitBtn2: TBitBtn;
    csoport1GOMB: TBitBtn;
    BitBtn4: TBitBtn;
    BitBtn5: TBitBtn;
    BitBtn6: TBitBtn;
    BitBtn7: TBitBtn;
    BitBtn8: TBitBtn;
    BitBtn9: TBitBtn;
    BitBtn10: TBitBtn;
    BitBtn11: TBitBtn;
    BitBtn12: TBitBtn;
    BitBtn13: TBitBtn;
    BitBtn14: TBitBtn;
    BitBtn15: TBitBtn;
    BitBtn16: TBitBtn;
    BitBtn17: TBitBtn;
    BitBtn18: TBitBtn;
    BitBtn19: TBitBtn;
    BitBtn20: TBitBtn;
    BitBtn21: TBitBtn;
    BitBtn22: TBitBtn;
    BitBtn23: TBitBtn;
    BitBtn24: TBitBtn;
    BitBtn25: TBitBtn;
    BitBtn26: TBitBtn;
    BitBtn27: TBitBtn;
    BitBtn28: TBitBtn;
    BitBtn29: TBitBtn;
    BitBtn30: TBitBtn;
    BitBtn31: TBitBtn;
    BitBtn32: TBitBtn;
    BitBtn33: TBitBtn;
    BitBtn34: TBitBtn;
    BitBtn35: TBitBtn;
    BitBtn36: TBitBtn;
    BitBtn37: TBitBtn;
    BitBtn38: TBitBtn;
    BitBtn39: TBitBtn;
    BitBtn40: TBitBtn;
    BitBtn41: TBitBtn;
    BitBtn42: TBitBtn;
    BitBtn43: TBitBtn;
    BitBtn44: TBitBtn;
    BitBtn45: TBitBtn;
    BitBtn46: TBitBtn;
    BitBtn47: TBitBtn;
    BitBtn48: TBitBtn;
    BitBtn49: TBitBtn;
    BitBtn50: TBitBtn;
    BitBtn51: TBitBtn;
    BitBtn52: TBitBtn;
    BitBtn53: TBitBtn;
    BitBtn56: TBitBtn;
    BitBtn59: TBitBtn;
    RENAMEPANEL: TPanel;
    Label4: TLabel;
    RENCSOPPANEL: TPanel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    EDDIGINEVEDIT: TEdit;
    UJNEVEDIT: TEdit;
    atnevezogomb: TBitBtn;
    BitBtn3: TBitBtn;
    MUVELETPANEL: TPanel;
    MUVELETXPANEL: TPanel;
    UZENOPANEL: TPanel;
    BESOROLOPANEL: TPanel;
    Label3: TLabel;
    IRODANEVPANEL: TPanel;
    Label8: TLabel;
    CSOPORTSZAMPANEL: TPanel;
    Label9: TLabel;
    BESOROLOKEGOMB: TBitBtn;
    MEGSEMSOROLBEGOMB: TBitBtn;
    TORLESSUREPANEL: TPanel;
    Label10: TLabel;
    Label11: TLabel;
    TORNEVPANEL: TPanel;
    Label12: TLabel;
    TORLESOKEGOMB: TBitBtn;
    TORLESMEGSEMGOMB: TBitBtn;
    TORLESPANEL: TPanel;
    TORLESLISTA: TListBox;
    PCIMLABEL: TLabel;
    BitBtn1: TBitBtn;
    BitBtn54: TBitBtn;
    MOVESUREPANEL: TPanel;
    Label13: TLabel;
    MOVENEVPANEL: TPanel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    UJCSOPEDIT: TEdit;
    BitBtn55: TBitBtn;
    BitBtn57: TBitBtn;
    csopmenupanel: TPanel;
    CM2: TPanel;
    CM1: TPanel;
    CM3: TPanel;
    CM4: TPanel;
    CM5: TPanel;
    CM7: TPanel;
    CM6: TPanel;
    Panel1: TPanel;
    CB2: TCheckBox;
    CB3: TCheckBox;
    CB4: TCheckBox;
    CB5: TCheckBox;
    CB6: TCheckBox;
    CB7: TCheckBox;
    CB8: TCheckBox;
    CB9: TCheckBox;
    CB10: TCheckBox;
    CB11: TCheckBox;
    CB12: TCheckBox;
    CB13: TCheckBox;
    CB14: TCheckBox;
    CB15: TCheckBox;
    CB16: TCheckBox;
    CB17: TCheckBox;
    CB18: TCheckBox;
    CB19: TCheckBox;
    CB20: TCheckBox;
    CB21: TCheckBox;
    CB22: TCheckBox;
    CB23: TCheckBox;
    CB24: TCheckBox;
    CB25: TCheckBox;
    CB26: TCheckBox;
    CB27: TCheckBox;
    CB1: TCheckBox;
    CB28: TCheckBox;
    CB29: TCheckBox;
    CB30: TCheckBox;
    CB31: TCheckBox;
    CB32: TCheckBox;
    CB33: TCheckBox;
    CB34: TCheckBox;
    CB35: TCheckBox;
    CB36: TCheckBox;
    CB37: TCheckBox;
    CB38: TCheckBox;
    CB39: TCheckBox;
    CB40: TCheckBox;
    CB41: TCheckBox;
    CB42: TCheckBox;
    CB43: TCheckBox;
    CB44: TCheckBox;
    CB45: TCheckBox;
    CB46: TCheckBox;
    CB47: TCheckBox;
    CB48: TCheckBox;
    CB49: TCheckBox;
    CB50: TCheckBox;
    CB51: TCheckBox;
    CB52: TCheckBox;
    CB53: TCheckBox;
    CB54: TCheckBox;
    Label1: TLabel;
    procedure FormActivate(Sender: TObject);
    procedure MakeCsTomb;
    procedure CmClear;

    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure CS1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ARFTmKGOMBEnter(Sender: TObject);
    procedure ARFTmKGOMBExit(Sender: TObject);
    procedure BACKTOMENUGOMBClick(Sender: TObject);
    procedure Gombotnyomott(_cs: integer);
    procedure ARFTmKGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ARFTmKGOMBClick(Sender: TObject);
    procedure megsemgombClick(Sender: TObject);
    procedure CM6Click(Sender: TObject);
    procedure UJNEVEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure BitBtn3Click(Sender: TObject);
    
    procedure atnevezogombClick(Sender: TObject);
    procedure MENUGOMBClick(Sender: TObject);
    procedure MunkacsoportEditor;
    procedure CS16MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BitBtn4MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure CSOPORTLISTAMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MUVELETXPANELClick(Sender: TObject);
    procedure IRODAINSERTGOMBClick(Sender: TObject);
    procedure BESOROLOKEGOMBClick(Sender: TObject);
    procedure MEGSEMSOROLBEGOMBClick(Sender: TObject);
    procedure IRODADELETEGOMBClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn54Click(Sender: TObject);
    procedure TORLESLISTADblClick(Sender: TObject);
    procedure TORLESOKEGOMBClick(Sender: TObject);
    procedure TORLESMEGSEMGOMBClick(Sender: TObject);
    procedure IRODAMOVEGOMBClick(Sender: TObject);
    procedure UJCSOPEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure BitBtn58Click(Sender: TObject);
    procedure MoveRutin;
    procedure BitBtn55Click(Sender: TObject);
    procedure BitBtn57Click(Sender: TObject);
    procedure CM1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure CM3Click(Sender: TObject);
    procedure CM1Click(Sender: TObject);
    procedure csopmenupanelMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure CM2Click(Sender: TObject);
    procedure CB1Click(Sender: TObject);
   


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CSOPORTDISPLAY: TCSOPORTDISPLAY;

  _cBox: array[1..54] of TCheckbox;
  _cspan: array[1..54] of tPanel;
  _cshan: array[1..54] of TShape;
  _cm: array[1..7] of TPanel;

  _aktirodacim,_aktcsopnev,_ujcsopnev,_delnev,_text,_movnev: string;
  _aktPanel: Tpanel;
  _Process,_aktstatusz,_deliroda,_moviroda,_ujcsoport: integer;
  _menuProcess,_torloProcess: boolean;
  _ujcsoptext: string;

implementation

uses Unit8, Unit16, Unit6, Unit5;

{$R *.dfm}


// =============================================================================
           procedure TCsoportDisplay.FormActivate(Sender: TObject);
// =============================================================================

var I: integer;
    _aktcsoportnev: string;
    _kellc: boolean;
    _aktcbox: TCheckbox;

begin
  Top    := _top;
  Left   := _left;
  Width  := 1366;
  Height := 729;

  _utolsoTag    := 0;
  _Process      := 0;   // karbantartás
  _torloProcess := False;

  MuveletPanel.caption    := 'MÜVELET = KARBANTARTÁS';
  MuveletxPanel.Visible   := False;
  Torlespanel.Visible     := False;
  TorlesSurePanel.Visible := False;
  MovesurePanel.Visible   := false;

  Uzenopanel.Caption := 'VÁLASSZON CSOPORTOT';
  UzenoPanel.Visible := False;

  _cm[1] := CM1;
  _cm[2] := CM2;
  _cm[3] := CM3;
  _cm[4] := CM4;
  _cm[5] := CM5;
  _cm[6] := CM6;
  _cm[7] := CM7;

  _cbox[1] := cb1;
  _cbox[2] := cb2;
  _cbox[3] := cb3;
  _cbox[4] := cb4;
  _cbox[5] := cb5;
  _cbox[6] := cb6;
  _cbox[7] := cb7;
  _cbox[8] := cb8;
  _cbox[9] := cb9;
  _cbox[10] := cb10;

  _cbox[11] := cb11;
  _cbox[12] := cb12;
  _cbox[13] := cb13;
  _cbox[14] := cb14;
  _cbox[15] := cb15;
  _cbox[16] := cb16;
  _cbox[17] := cb17;
  _cbox[18] := cb18;
  _cbox[19] := cb19;
  _cbox[20] := cb20;

  _cbox[21] := cb21;
  _cbox[22] := cb22;
  _cbox[23] := cb23;
  _cbox[24] := cb24;
  _cbox[25] := cb25;
  _cbox[26] := cb26;
  _cbox[27] := cb27;
  _cbox[28] := cb28;
  _cbox[29] := cb29;
  _cbox[30] := cb30;

  _cbox[31] := cb31;
  _cbox[32] := cb32;
  _cbox[33] := cb33;
  _cbox[34] := cb34;
  _cbox[35] := cb35;
  _cbox[36] := cb36;
  _cbox[37] := cb37;
  _cbox[38] := cb38;
  _cbox[39] := cb39;
  _cbox[40] := cb40;

  _cbox[41] := cb41;
  _cbox[42] := cb42;
  _cbox[43] := cb43;
  _cbox[44] := cb44;
  _cbox[45] := cb45;
  _cbox[46] := cb46;
  _cbox[47] := cb47;
  _cbox[48] := cb48;
  _cbox[49] := cb49;
  _cbox[50] := cb50;

  _cbox[51] := cb51;
  _cbox[52] := cb52;
  _cbox[53] := cb53;
  _cbox[54] := cb54;

  NincsIrodaPanel.Visible := False;
  RenamePanel.Visible     := False;
  BesoroloPanel.Visible   := False;
  _menuprocess            := False;

  MakeCsTomb;

  for i := 1 to 54 do
    begin
      _aktPanel := _csPan[i];
      _aktcsoportnev := uppercase(_csoportnevek[i]);
      _aktpanel.Caption := _aktcsoportnev;
      _aktcbox := _cbox[i];
      _kellc := _ccontrol[i];
      if _kellc then _aktcbox.checked := true else _aktcbox.checked := False;
      _aktcbox.Caption := inttostr(i)+' - '+ _aktcsoportnev;
    end;
end;


procedure TcsoportDisplay.CMclear;

var _aktcm: TPanel;
    i: integer;

begin
  for i := 1 to 7 do
    begin
      _aktcm := _cm[i];
      _aktcm.Color := clBtnface;
      _aktcm.Font.Style := [];
    end;
end;


// =============================================================================
                    procedure TCsoportDisplay.MAkecstomb;
// =============================================================================

begin
  _cspan[1]  := Cs1;
  _cspan[2]  := Cs2;
  _cspan[3]  := Cs3;
  _cspan[4]  := Cs4;
  _cspan[5]  := Cs5;
  _cspan[6]  := Cs6;
  _cspan[7]  := Cs7;
  _cspan[8]  := Cs8;
  _cspan[9]  := Cs9;
  _cspan[10] := Cs10;
  _cspan[11] := Cs11;
  _cspan[12] := Cs12;
  _cspan[13] := Cs13;
  _cspan[14] := Cs14;
  _cspan[15] := Cs15;
  _cspan[16] := Cs16;
  _cspan[17] := Cs17;
  _cspan[18] := Cs18;
  _cspan[19] := Cs19;
  _cspan[20] := Cs20;
  _cspan[21] := Cs21;
  _cspan[22] := Cs22;
  _cspan[23] := Cs23;
  _cspan[24] := Cs24;
  _cspan[25] := Cs25;
  _cspan[26] := Cs26;
  _cspan[27] := Cs27;
  _cspan[28] := Cs28;
  _cspan[29] := Cs29;
  _cspan[30] := Cs30;
  _cspan[31] := Cs31;
  _cspan[32] := Cs32;
  _cspan[33] := Cs33;
  _cspan[34] := Cs34;
  _cspan[35] := Cs35;
  _cspan[36] := Cs36;
  _cspan[37] := Cs37;
  _cspan[38] := Cs38;
  _cspan[39] := Cs39;
  _cspan[40] := Cs40;
  _cspan[41] := Cs41;
  _cspan[42] := Cs42;
  _cspan[43] := Cs43;
  _cspan[44] := Cs44;
  _cspan[45] := Cs45;
  _cspan[46] := Cs46;
  _cspan[47] := Cs47;
  _cspan[48] := Cs48;
  _cspan[49] := Cs49;
  _cspan[50] := Cs50;
  _cspan[51] := Cs51;
  _cspan[52] := Cs52;
  _cspan[53] := Cs53;
  _cspan[54] := Cs54;

  _cshan[1]  := sh1;
  _cshan[2]  := sh2;
  _cshan[3]  := sh3;
  _cshan[4]  := sh4;
  _cshan[5]  := sh5;
  _cshan[6]  := sh6;
  _cshan[7]  := sh7;
  _cshan[8]  := sh8;
  _cshan[9]  := sh9;
  _cshan[10] :=sh10;
  _cshan[11] :=sh11;
  _cshan[12] :=sh12;
  _cshan[13] :=sh13;
  _cshan[14] :=sh14;
  _cshan[15] :=sh15;
  _cshan[16] :=sh16;
  _cshan[17] :=sh17;
  _cshan[18] :=sh18;
  _cshan[19] :=sh19;
  _cshan[20] :=sh20;
  _cshan[21] :=sh21;
  _cshan[22] :=sh22;
  _cshan[23] :=sh23;
  _cshan[24] :=sh24;
  _cshan[25] :=sh25;
  _cshan[26] :=sh26;
  _cshan[27] :=sh27;
  _cshan[28] :=sh28;
  _cshan[29] :=sh29;
  _cshan[30] :=sh30;
  _cshan[31] :=sh31;
  _cshan[32] :=sh32;
  _cshan[33] :=sh33;
  _cshan[34] :=sh34;
  _cshan[35] :=sh35;
  _cshan[36] :=sh36;
  _cshan[37] :=sh37;
  _cshan[38] :=sh38;
  _cshan[39] :=sh39;
  _cshan[40] :=sh40;
  _cshan[41] :=sh41;
  _cshan[42] :=sh42;
  _cshan[43] :=sh43;
  _cshan[44] :=sh44;
  _cshan[45] :=sh45;
  _cshan[46] :=sh46;
  _cshan[47] :=sh47;
  _cshan[48] :=sh48;
  _cshan[49] :=sh49;
  _cshan[50] :=sh50;
  _cshan[51] :=sh51;
  _cshan[52] :=sh52;
  _cshan[53] :=sh53;
  _cshan[54] :=sh54;
end;


// =============================================================================
         procedure TCSOPORTDISPLAY.FormMouseMove(Sender: TObject;
                                         Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
//  UzenoPanel.Visible := false;
  CsoportLista.Items.clear;
  CsoportLista.Clear;
end;

// =============================================================================
   procedure TCSOPORTDISPLAY.CS1MouseMove(Sender: TObject; Shift: TShiftState;
                                                                X, Y: Integer);
// =============================================================================

var _tag: integer;
    _text: string;

begin
  if _torloprocess then exit;

  _tag := TPanel(sender).tag;
  if _tag=_utolsoTag then exit;

  if _utolsoTag>0 then
    begin
      _csPan[_utolsotag].Color := clwindow;
      _csPan[_utolsotag].Font.Color := clBlack;
      _csHan[_utolsotag].Brush.Color := Clwindow;
    end;

  _utolsotag := _tag;
  _aktcsoportDarab := _csoportTagDarab[_tag];
  _csPan[_utolsotag].Color := clRed;
  _csPan[_utolsotag].Font.color := clWhite;
  _csHan[_utolsotag].Brush.Color := clRed;

  if _aktcsoportDarab=0 then
     begin
        NincsIrodaPanel.Visible := true;
        _utolsotag := _tag;
        exit;
      end;

  NincsIrodaPanel.Visible := false;
  CsoportLista.Items.Clear;
  CsoportLista.Clear;

  _qq := 1;
  _listdb := _aktcsoportDarab;
  while _qq<=_aktcsoportDarab do
    begin
      _aktiroda := _csoporttagok[_tag,_qq];
      _xx := Form1.ScanIroda(_aktiroda);
      _aktirodaNev := _ptarnev[_xx];
      _aktirodacim := _ptarcim[_xx];
      _text := _aktirodanev+'/'+_aktirodacim;

      // -------------------------------------------

      _listSS[_qq-1] := _aktiroda;
      _listText[_qq-1] := _text;

      // --------------------------------------------

      CsoportLista.Items.add(_text);
      CsoportLista.Color := $B0FFFF;
      CsoportShape.Brush.Color := $B0FFFF;
      inc(_QQ);
    end;
  _utolsoTag := _tag;
end;

// =============================================================================
            procedure TCSOPORTDISPLAY.ARFTmKGOMBEnter(Sender: TObject);
// =============================================================================

begin
  with tBitbtn(sender).Font do
    begin
      Style := [fsBold,fsItalic];
      Color := clNavy;
    end;
end;

// =============================================================================
           procedure TCSOPORTDISPLAY.ARFTmKGOMBExit(Sender: TObject);
// =============================================================================

begin
   with tBitbtn(sender).Font do
     begin
       Style := [fsItalic];
       Color := clBlack;
     end;
end;

// =============================================================================
           procedure TCSOPORTDISPLAY.BACKTOMENUGOMBClick(Sender: TObject);
// =============================================================================

begin
  _menuprocess := false;
  _process := 0;
  ModalResult := 1;
end;

// =============================================================================
             procedure TcsoportDisplay.Gombotnyomott(_cs: integer);
// =============================================================================

begin
  UzenoPanel.Visible := false;
  _aktcsoport := _cs;

  if _process=0 then
    begin
      MunkacsoportEditor;
      exit;
    end;

  // ========================================

  if _process=1 then
    begin
      UzenoPanel.Visible := False;
      _aktCsopnev := _csoportNevek[_aktcsoport];
      RenCsopPanel.Caption := inttostr(_aktcsoport)+'.';
      Eddiginevedit.Text := _aktcsopNev;
      Ujnevedit.clear;
      Atnevezogomb.Enabled := false;

      with RenamePanel do
        begin
          Top     := 270;
          Left    := 200;
          Visible := True;
        end;

      ActiveControl := UjNevEdit;
      exit;
    end;

   // ========================================

   if _process=2 then
     begin
       _aktcsoport := _cs;

       CsoportSzampanel.caption := inttostr(_cs);
       IrodaNevPanel.Caption := _valasztottirodanev;
       with BesoroloPanel do
         begin
           Top     := 296;
           Left    := 296;
           Visible := True;
         end;
       ActiveControl := BesorolOkegomb;
       exit;
     end;

   // ============================================

   if _process=3 then  // iroda törlése
     begin
       _torloProcess := true;
       TorlesLista.clear;
       TorlesLista.Items.clear;

       _qq := 0;
       while _qq<_listdb do
         begin
           _text := _listText[_qq];
           TorlesLista.Items.add(_text);
           inc(_qq);
         end;

       pCimLabel.Caption :='VÁLASSZA KI A TÖRLENDÕ IRODÁT';

       with torlesPanel do
         begin
           Top := 270;
           Left := 200;
           Visible := true;
         end;

       ActiveControl := TorlesLista;
       TorlesLista.ItemIndex := 0;
       TorlesLista.SetFocus;
       exit;
     end;

   // =============================================

   IF _process=4 then   // iroda áthelyezése
     begin
       _torloprocess := True;
       TorlesLista.clear;
       Torleslista.Items.Clear;

       _qq := 0;
       while _qq<_listdb do
         begin
           _text := _listText[_qq];
           TorlesLista.Items.add(_text);
           inc(_qq);
         end;
       PCimLabel.Caption := 'MELYIK IRODÁT HELYEZZEM ÁT ?';
       with torlesPanel do
         begin
           Top     := 270;
           Left    := 200;
           Visible := true;
         end;
       ActiveControl := TorlesLista;
       TorlesLista.ItemIndex := 0;
       TorlesLista.SetFocus;
       exit;
     end;
end;

// =============================================================================
        procedure TCSOPORTDISPLAY.ARFTmKGOMBMouseMove(Sender: TObject;
                                          Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
   ActiveControl := TBitbtn(sender);
end;

// =============================================================================
           procedure TCsoportDisplay.ArfTmkGombClick(Sender: TObject);
// =============================================================================

begin
  MunkacsoportEditor;
 
end;

// =============================================================================
          procedure TCSOPORTDISPLAY.MegsemGombClick(Sender: TObject);
// =============================================================================

begin
  _menuProcess      := False;
  _process          := 0;
end;

// =============================================================================
          procedure TCSOPORTDISPLAY.CM6Click(Sender: TObject);
// =============================================================================

begin
  // Munkacsoport átnevezése;
 
  _MenuProcess := False;
  _process :=1;
  Muveletpanel.Caption := 'MÜVELET = ÁTNEVEZÉS';
  MuveletXPanel.Visible := true;
  UzenoPanel.Visible := true;
end;

// =============================================================================
   procedure TCSOPORTDISPLAY.UjNevEditKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  _ujcsopnev := trim(ujnevedit.text);
  if _ujcsopnev = '' then exit;

  Atnevezogomb.Enabled := True;
  ActiveControl := Atnevezogomb;
end;

// =============================================================================
             procedure TCSOPORTDISPLAY.BitBtn3Click(Sender: TObject);
// =============================================================================

begin
  RenamePanel.Visible := false;
end;

// =============================================================================
           procedure TCSOPORTDISPLAY.atnevezogombClick(Sender: TObject);
// =============================================================================

begin
  _arfdataValtozott := true;
  _aktpanel := _cspan[_aktcsoport];
  _aktpanel.Caption := _ujcsopnev;
  _aktpanel.repaint;

  _csoportnevek[_aktcsoport] := _ujcsopnev;
  Renamepanel.visible := False;
end;

// =============================================================================
              procedure TCSOPORTDISPLAY.MENUGOMBClick(Sender: TObject);
// =============================================================================

begin
  _menuprocess := true;
  ActiveControl := Cm1;
end;

// =============================================================================
               procedure Tcsoportdisplay.Munkacsoporteditor;
// =============================================================================

var _oke: integer;

begin
   _oke := Munkaform.ShowModal;
   if _oke=2 then Modalresult := 2;
end;

// =============================================================================
         procedure TCSOPORTDISPLAY.CS16MouseDown(Sender: TObject;
                      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
// =============================================================================

var _tag: integer;

begin

  if _menuProcess then exit;

  if Button = mbRight then
    begin
      _menuProcess := true;
      Menugombclick(Nil);
      exit;
    end;

  _tag := Tpanel(sender).Tag;
  GombotNyomott(_tag);
end;

// =============================================================================
         procedure TCSOPORTDISPLAY.BitBtn4MouseDown(Sender: TObject;
                     Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
// =============================================================================

var _tag: integer;

begin
  if _menuprocess then exit;

  if Button= mbright then
    begin
      _menuProcess := True;
      MenugombClick(Nil);
      exit;
    end;

  _tag := TBitbtn(Sender).Tag;
  Gombotnyomott(_tag);
end;

// =============================================================================
       procedure TCSOPORTDISPLAY.CSOPORTLISTAMouseDown(Sender: TObject;
                      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  if button=mbright then
    begin
      Menugombclick(Nil);
      exit;
    end;
end;

// =============================================================================
         procedure TCSOPORTDISPLAY.FormMouseDown(Sender: TObject;
                     Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  CMClear;
end;

// =============================================================================
          procedure TCSOPORTDISPLAY.MuveletXPanelClick(Sender: TObject);
// =============================================================================

begin
  MuveletXPanel.Visible := false;
  _process := 0;
  MuveletPanel.Caption := 'MÜVELET = KARBANTARTÁS';
  UzenoPanel.Visible := True;
end;

// =============================================================================
        procedure TCSOPORTDISPLAY.IRODAINSERTGOMBClick(Sender: TObject);
// =============================================================================



begin
  // Új iroda felvétele egy munkacsoportba

   _process := 2;   // 2-ES PROCESS = Új iroda felvétele:
   _menuprocess := False;

   MuveletPanel.Caption  := 'MÜVELET = ÚJ IRODA';
   MuveletXPanel.visible := True;

  _valasztottirodaszam := IrodanevLista.Showmodal;
  if _valasztottirodaszam=-1 then exit;

  _xx := Form1.ScanIroda(_valasztottirodaszam);

  _aktcsoport :=_ptarcsop[_xx];
  _valasztottirodanev := _ptarnev[_xx];

  if _aktcsoport>0 then
    begin
      ShowMessage('AZ IRODA MÁR BENN VAN EGY MUNKACSOPORTBAN !');
      MuveletPanel.Caption := 'MÜVELET = KARBANTARTÁS';
      _process := 0;
      MuveletxPanel.Visible := False;
      exit;
    end;

  UzenoPanel.Caption := 'VÁLASSZON IRODÁT';
  UzenoPanel.Visible := true;
end;

// =============================================================================
        procedure TCSOPORTDISPLAY.BesorolOkeGombClick(Sender: TObject);
// =============================================================================

var _csdb: integer;

begin
  _arfdataValtozott := true;
  BesoroloPanel.Visible := False;
  _csdb := _csoportszamok[_aktcsoport];

  if _csdb=0 then inc(_aktivcsoportdarab);

  _xx := Form1.Scaniroda(_valasztottIrodaszam);
  _ptarcsop[_xx] := _aktcsoport;

  Form1.CsoportTagSzamito;

  MuveletPanel.Caption := 'MÜVELET = KARBANTARTÁS';
  UzenoPanel.Caption   := 'VÁLASSZON CSOPORTOT';

  _process := 0;

  MuveletxPanel.Visible := False;
  UzenoPanel.Visible := True;
end;

// =============================================================================
         procedure TCSOPORTDISPLAY.MegsemSorolBeGombClick(Sender: TObject);
// =============================================================================

begin
  BesoroloPanel.Visible := false;
end;

// =============================================================================
        procedure TCSOPORTDISPLAY.IrodaDeleteGombClick(Sender: TObject);
// =============================================================================

begin
  _process := 3;
  _Menuprocess := false;

  MuveletPanel.Caption  := 'MÜVELET = IRODA TÖRLÉSE';
  MuveletXPanel.visible := True;
  UzenoPanel.Caption    := 'VÁLASSZON IRODÁT';
  UzenoPanel.Visible    := True;
end;

// =============================================================================
           procedure TCSOPORTDISPLAY.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  TorlesPanel.visible := False;
  TorlessurePanel.Visible := False;
end;

// =============================================================================
          procedure TCSOPORTDISPLAY.BitBtn54Click(Sender: TObject);
// =============================================================================

begin
  _torloProcess := False;
  TorlesPanel.Visible := false;
end;

// =============================================================================
          procedure TCSOPORTDISPLAY.TORLESLISTADblClick(Sender: TObject);
// =============================================================================

begin
  IF _PROCESS=3 THEN   // iroda törlése
    begin
      _index    := Torleslista.ItemIndex;
      _delnev   := _listText[_index];
      _deliroda := _listss[_index];

      TornevPanel.caption := _delnev;

      with TorlesSurePanel do
        begin
          Top     := 270;
          Left    := 200;
          Visible := true;
        end;

      ActiveControl := TorlesOkegomb;
      exit;
    end;

  // --------------------------------------------

  //  itt az áthelyezés következik
  _index    := TorlesLista.Itemindex;
  _movNev   := _listText[_index];
  _moviroda := _listSS[_index];

  MoveNevPanel.Caption := _movnev;

  with MoveSurePanel do
    begin
      Top     := 270;
      Left    := 200;
      Visible := True;
    end;

  Ujcsopedit.Text := '';
  Activecontrol := UjcsopEdit;
  exit;
end;

// =============================================================================
         procedure TCSOPORTDISPLAY.TORLESOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _arfdataValtozott := True;
  _xx := Form1.ScanIroda(_deliroda);
  _ptarcsop[_xx] := 0;
  TorlesPanel.visible := False;
  TorlesSurePanel.Visible := false;
  _TorloProcess := false;
  Form1.CsoportTagSzamito;
end;

// =============================================================================
        procedure TCSOPORTDISPLAY.TORLESMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
   TorlesPanel.visible := False;
  TorlesSurePanel.Visible := false;
  _torloProcess := False;
end;

// =============================================================================
         procedure TCSOPORTDISPLAY.IRODAMOVEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _process := 4;  // áthelyezés

 // Menupanel.Visible := False;
  _Menuprocess      := False;

  MuveletPanel.Caption  := 'MÜVELET = IRODA ÁTHELYEZÉSE';
  MuveletXPanel.visible := True;
  UzenoPanel.Caption    := 'VÁLASSZON IRODÁT';
  UzenoPanel.Visible    := True;
end;

// =============================================================================
   procedure TCSOPORTDISPLAY.UJCSOPEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Moverutin;
end;

// =============================================================================
         procedure TCSOPORTDISPLAY.BitBtn58Click(Sender: TObject);
// =============================================================================

begin
  if not Form1.Vegcontrol then exit;
  adatszetkuldes.showmodal;
  ArfdataIras.showmodal;
end;

// =============================================================================
                   procedure TcsoportDisplay.MoveRutin;
// =============================================================================

var _eddigicsop: integer;

begin
  _ujcsoptext := trim(Ujcsopedit.text);

  if _ujcsoptext = '' then exit;
  val(_ujcsoptext,_ujcsoport,_code);

  if _code<>0 then exit;
  if (_ujcsoport=0) or (_ujcsoport>54) then exit;

  _xx := Form1.ScanIroda(_moviroda);
  _eddigicsop := _ptarcsop[_xx];
  
  if _eddigiCsop=_ujcsoport then ShowMessage('AZ ÚJ CSOPORT AZONOS A RÉGIVEL !')
  else _ptarcsop[_xx] := _ujcsoport;

  TorlesPanel.visible   := False;
  MoveSurePanel.Visible := False;
  _TorloProcess         := False;

  Form1.CsoportTagSzamito;
end;


// =============================================================================
          procedure TCSOPORTDISPLAY.BitBtn55Click(Sender: TObject);
// =============================================================================

begin
  Moverutin;
end;

// =============================================================================
           procedure TCSOPORTDISPLAY.BitBtn57Click(Sender: TObject);
// =============================================================================

begin
  TorlesPanel.visible   := False;
  MoveSurePanel.Visible := False;
  _TorloProcess         := False;
end;





procedure TCSOPORTDISPLAY.CM1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);

var _tag: integer;
    _aktcm: TPanel;

begin
  CmClear;
  _tag := TPanel(Sender).Tag;
  _aktcm := _cm[_tag];
  _aktcm.color := $FFB0FF;
  _aktcm.Font.Style := [fsBold];
end;

procedure TCSOPORTDISPLAY.CM3Click(Sender: TObject);
begin
  ArfdataIras.showmodal;  // TEST ALATT NEM KELL
  Application.Terminate;
end;

procedure TCSOPORTDISPLAY.CM1Click(Sender: TObject);
begin
  ModalResult := 1;
end;

procedure TCSOPORTDISPLAY.csopmenupanelMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  Cmclear;
end;



procedure TCSOPORTDISPLAY.CM2Click(Sender: TObject);
begin
  if not Form1.Vegcontrol then exit;
  AdatSzetkuldes.Showmodal;
  ArfdataIras.showmodal;
end;


procedure TCSOPORTDISPLAY.CB1Click(Sender: TObject);

var _tag: byte;
    _aktcbox: Tcheckbox;

begin

  _tag := TCheckbox(sender).Tag;
  _aktcbox := _cbox[_tag];
  _ccontrol[_tag] := _aktcbox.checked;

end;

end.
