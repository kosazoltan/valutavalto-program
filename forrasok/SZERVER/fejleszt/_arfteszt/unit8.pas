unit Unit8;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, unit1, StrUtils, jpeg;

type
  TMUNKAFORM = class(TForm)
    P011: TPanel;
    P021: TPanel;
    P031: TPanel;
    P041: TPanel;
    P051: TPanel;
    P061: TPanel;
    P071: TPanel;
    P081: TPanel;
    P091: TPanel;
    P101: TPanel;
    P111: TPanel;
    P121: TPanel;
    P131: TPanel;
    P141: TPanel;
    P012: TPanel;
    P201: TPanel;
    P191: TPanel;
    P181: TPanel;
    P171: TPanel;
    P161: TPanel;
    P151: TPanel;
    P013: TPanel;
    P014: TPanel;
    P015: TPanel;
    P016: TPanel;
    P017: TPanel;
    P018: TPanel;
    EPAN: TPanel;
    VALPAN: TPanel;
    VP: TPanel;
    EP: TPanel;
    V1P: TPanel;
    E1P: TPanel;
    LIMITS1PANEL: TPanel;
    LIMITS2PANEL: TPanel;
    LIMITS3PANEL: TPanel;
    P032: TPanel;
    P033: TPanel;
    P043: TPanel;
    P025: TPanel;
    P056: TPanel;
    P076: TPanel;
    P062: TPanel;
    P106: TPanel;
    P068: TPanel;
    P038: TPanel;
    P173: TPanel;
    P126: TPanel;
    P108: TPanel;
    P086: TPanel;
    P036: TPanel;
    P052: TPanel;
    P188: TPanel;
    P088: TPanel;
    P138: TPanel;
    P048: TPanel;
    P158: TPanel;
    P087: TPanel;
    P146: TPanel;
    P207: TPanel;
    P073: TPanel;
    P205: TPanel;
    P186: TPanel;
    P178: TPanel;
    P027: TPanel;
    P037: TPanel;
    P206: TPanel;
    P166: TPanel;
    P116: TPanel;
    P023: TPanel;
    P042: TPanel;
    P203: TPanel;
    P196: TPanel;
    P128: TPanel;
    P163: TPanel;
    P072: TPanel;
    P046: TPanel;
    P024: TPanel;
    P202: TPanel;
    P148: TPanel;
    P078: TPanel;
    P026: TPanel;
    P063: TPanel;
    P183: TPanel;
    P136: TPanel;
    P208: TPanel;
    P198: TPanel;
    P156: TPanel;
    P204: TPanel;
    P168: TPanel;
    P096: TPanel;
    P034: TPanel;
    P022: TPanel;
    P082: TPanel;
    P053: TPanel;
    P058: TPanel;
    P118: TPanel;
    P098: TPanel;
    P066: TPanel;
    P193: TPanel;
    P176: TPanel;
    P035: TPanel;
    P028: TPanel;
    P187: TPanel;
    P167: TPanel;
    P135: TPanel;
    P093: TPanel;
    P113: TPanel;
    P064: TPanel;
    P115: TPanel;
    P132: TPanel;
    P104: TPanel;
    P095: TPanel;
    P117: TPanel;
    P125: TPanel;
    P044: TPanel;
    P045: TPanel;
    P133: TPanel;
    P107: TPanel;
    P185: TPanel;
    P105: TPanel;
    P147: TPanel;
    P054: TPanel;
    P083: TPanel;
    P143: TPanel;
    P184: TPanel;
    P137: TPanel;
    P094: TPanel;
    P092: TPanel;
    P084: TPanel;
    P067: TPanel;
    P077: TPanel;
    P065: TPanel;
    P103: TPanel;
    P192: TPanel;
    P114: TPanel;
    P153: TPanel;
    P085: TPanel;
    P157: TPanel;
    P124: TPanel;
    P075: TPanel;
    P102: TPanel;
    P057: TPanel;
    P197: TPanel;
    P122: TPanel;
    P074: TPanel;
    P127: TPanel;
    P047: TPanel;
    P055: TPanel;
    P123: TPanel;
    P112: TPanel;
    P097: TPanel;
    P195: TPanel;
    P165: TPanel;
    P194: TPanel;
    P172: TPanel;
    P164: TPanel;
    P144: TPanel;
    P134: TPanel;
    P142: TPanel;
    P152: TPanel;
    P162: TPanel;
    P182: TPanel;
    P145: TPanel;
    P177: TPanel;
    P175: TPanel;
    P174: TPanel;
    P154: TPanel;
    P155: TPanel;
    V2P: TPanel;
    E2P: TPanel;
    Shape2: TShape;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Shape1: TShape;
    Shape3: TShape;
    CSOPORTSZAMPANEL: TPanel;
    PENZTARLISTA: TListBox;
    LIMIT1EDIT: TEdit;
    LIMIT2EDIT: TEdit;
    LIMIT3EDIT: TEdit;
    FUGGVENYSHAPE: TShape;
    FUGGVENYPANEL: TPanel;
    Label17: TLabel;
    CSOPNEVPANEL: TPanel;
    J: TPanel;
    K: TPanel;
    L: TPanel;
    M: TPanel;
    N: TPanel;
    O: TPanel;
    P: TPanel;
    Q: TPanel;
    JELOLOPANEL: TPanel;
    HIDEEDIT: TEdit;
    BIGNUMPANEL: TPanel;
    BIGNUMEDIT: TEdit;
    Label10: TLabel;
    Label11: TLabel;
    MMENUBE: TTimer;
    BitBtn2: TBitBtn;
    P211: TPanel;
    P212: TPanel;
    P213: TPanel;
    P214: TPanel;
    P215: TPanel;
    P216: TPanel;
    P217: TPanel;
    P218: TPanel;
    p221: TPanel;
    P222: TPanel;
    P223: TPanel;
    P224: TPanel;
    P225: TPanel;
    P226: TPanel;
    P227: TPanel;
    P228: TPanel;
    P019: TPanel;
    P01A: TPanel;
    R: TPanel;
    S: TPanel;
    SKP: TPanel;
    VMAXP: TPanel;
    EMINP: TPanel;
    P02A: TPanel;
    P029: TPanel;
    P03A: TPanel;
    P039: TPanel;
    P05A: TPanel;
    P059: TPanel;
    P049: TPanel;
    P069: TPanel;
    P07A: TPanel;
    P089: TPanel;
    P09A: TPanel;
    P079: TPanel;
    P08A: TPanel;
    P10A: TPanel;
    P119: TPanel;
    P109: TPanel;
    P129: TPanel;
    P11A: TPanel;
    P139: TPanel;
    P12A: TPanel;
    P149: TPanel;
    P13A: TPanel;
    P099: TPanel;
    P06A: TPanel;
    P04A: TPanel;
    P15A: TPanel;
    P169: TPanel;
    P179: TPanel;
    P16A: TPanel;
    P18A: TPanel;
    P189: TPanel;
    P219: TPanel;
    P209: TPanel;
    P17A: TPanel;
    P19A: TPanel;
    P21A: TPanel;
    P199: TPanel;
    P14A: TPanel;
    P20A: TPanel;
    P229: TPanel;
    P159: TPanel;
    P22A: TPanel;
    Image1: TImage;
    menupanel: TPanel;
    FM1: TPanel;
    FM2: TPanel;
    FM3: TPanel;
    FM4: TPanel;
    P231: TPanel;
    P232: TPanel;
    P233: TPanel;
    P234: TPanel;
    P235: TPanel;
    P236: TPanel;
    P237: TPanel;
    P238: TPanel;
    P239: TPanel;
    P23A: TPanel;
    P241: TPanel;
    P242: TPanel;
    P243: TPanel;
    P244: TPanel;
    P245: TPanel;
    P246: TPanel;
    P247: TPanel;
    P248: TPanel;
    P249: TPanel;
    P24A: TPanel;
    P276: TPanel;
    P259: TPanel;
    P267: TPanel;
    P27A: TPanel;
    P25A: TPanel;
    P26A: TPanel;
    P279: TPanel;
    P269: TPanel;
    P266: TPanel;
    P258: TPanel;
    P257: TPanel;
    P268: TPanel;
    P256: TPanel;
    P255: TPanel;
    P278: TPanel;
    P277: TPanel;
    P275: TPanel;
    P265: TPanel;
    P274: TPanel;
    P264: TPanel;
    P254: TPanel;
    P273: TPanel;
    P263: TPanel;
    P253: TPanel;
    P272: TPanel;
    P262: TPanel;
    P252: TPanel;
    P271: TPanel;
    P261: TPanel;
    P251: TPanel;
    P281: TPanel;
    P282: TPanel;
    P283: TPanel;
    P28A: TPanel;
    P289: TPanel;
    P288: TPanel;
    P287: TPanel;
    P286: TPanel;
    P285: TPanel;
    P284: TPanel;

    procedure BACKTOMENUClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure PenztarlistaTolto;
    procedure TeglaBetolt;
    procedure LehuzoRutin;
    procedure GetTeglaAdatok(_xsor,_xoszlop: integer);
    procedure Lapfelfrissito;
    procedure SetJeloloKoord(_szin: TColor);
    procedure FuggvenyKijelzes;
    procedure DataCopy;
    procedure SetKoord(_nn: string);
    procedure P011MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure P011MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure HIDEEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure BIGNUMEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FuggvenyKezelo(_fsor,_foszlop: integer);
    procedure P011DblClick(Sender: TObject);
   
    procedure Zoldrutin;
    function Pontos(_lim: integer): string;
    procedure Adatmasolorutin;
    procedure MODOSITOPANELClick(Sender: TObject);
    procedure TombbeTegla(_zSor,_zOszlop: integer);

    procedure VISSZAGOMBClick(Sender: TObject);
    procedure masikcsoportgombClick(Sender: TObject);
    procedure alapeditgombEnter(Sender: TObject);
    procedure alapeditgombExit(Sender: TObject);
    procedure alapeditgombMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  
    procedure limiteditgombClick(Sender: TObject);
    procedure LapRegeneralo;
    procedure ClearFms;

    procedure BitBtn2Click(Sender: TObject);
    procedure szetkuldogombClick(Sender: TObject);
    procedure FM4Click(Sender: TObject);
    procedure FM1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
   
   



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MUNKAFORM: TMUNKAFORM;
  _pTegla: array[1..28,1..10] of TPanel;
  _cslimit: array[1..3] of integer;
  _mWidth,_mHeight: integer;
  _aktfm: TPanel;

  _fm: array[1..4] of TPanel;

implementation

uses Unit3, Unit13, Unit14, Unit15, Unit10, Unit6, Unit5;

{$R *.dfm}

// =============================================================================
              procedure TMUNKAFORM.BACKTOMENUClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;

// =============================================================================
              procedure TMUNKAFORM.FormActivate(Sender: TObject);
// =============================================================================


begin
  Top    := _top;
  Left   := _left;
  width  := 1366;
  Height := 729;

  _fm[1] := Fm1;
  _fm[2] := Fm2;
  _fm[3] := Fm3;
  _fm[4] := Fm4;

  JeloloPanel.Visible := false;
  BignumPanel.Visible := false;

  LapRegeneralo;

  _utteglanev := 'xx';
  _zold := false;
  _double := False;
  _manual := False;
end;


// =============================================================================
                  procedure TMunkaForm.LapfelFrissito;
// =============================================================================


begin

  CsoportszamPanel.Caption := inttostr(_aktcsoport);
  Form1.CsoportLapAtszamolo(_aktcsoport);
  _sor := 1;
  while _sor<=_dnemdarab do
    begin
      _oszlop := 1;
      while _oszlop<=10 do
        begin
          _akttegla := _ptegla[_sor,_oszlop];
          GetTeglaAdatok(_sor,_oszlop);

          with _AktTegla do
            begin
              Caption := _aktertekString;
              Font.Color := _aktbetuszin;
              Color := _aktHatterSzin;
            end;
          inc(_oszlop);
        end;
      inc(_sor);
    end;
  Munkaform.Refresh;
  Munkaform.Repaint;
end;


// =============================================================================
                        procedure TMunkaForm.TeglaBetolt;
// =============================================================================

begin
  
  _pTegla[1,1] := P011;
  _pTegla[1,2] := P012;
  _pTegla[1,3] := P013;
  _pTegla[1,4] := P014;
  _pTegla[1,5] := P015;
  _pTegla[1,6] := P016;
  _pTegla[1,7] := P017;
  _pTegla[1,8] := P018;
  _pTegla[1,9] := P019;
  _pTegla[1,10]:= P01A;

  _pTegla[2,1] := P021;
  _pTegla[2,2] := P022;
  _pTegla[2,3] := P023;
  _pTegla[2,4] := P024;
  _pTegla[2,5] := P025;
  _pTegla[2,6] := P026;
  _pTegla[2,7] := P027;
  _pTegla[2,8] := P028;
  _pTegla[2,9] := P029;
  _pTegla[2,10]:= P02A;

  _pTegla[3,1] := P031;
  _pTegla[3,2] := P032;
  _pTegla[3,3] := P033;
  _pTegla[3,4] := P034;
  _pTegla[3,5] := P035;
  _pTegla[3,6] := P036;
  _pTegla[3,7] := P037;
  _pTegla[3,8] := P038;
  _pTegla[3,9] := P039;
  _pTegla[3,10]:= P03A;

  _pTegla[4,1] := P041;
  _pTegla[4,2] := P042;
  _pTegla[4,3] := P043;
  _pTegla[4,4] := P044;
  _pTegla[4,5] := P045;
  _pTegla[4,6] := P046;
  _pTegla[4,7] := P047;
  _pTegla[4,8] := P048;
  _pTegla[4,9] := P049;
  _pTegla[4,10]:= P04A;

  _pTegla[5,1] := P051;
  _pTegla[5,2] := P052;
  _pTegla[5,3] := P053;
  _pTegla[5,4] := P054;
  _pTegla[5,5] := P055;
  _pTegla[5,6] := P056;
  _pTegla[5,7] := P057;
  _pTegla[5,8] := P058;
  _pTegla[5,9] := P059;
  _pTegla[5,10]:= P05A;

  _pTegla[6,1] := P061;
  _pTegla[6,2] := P062;
  _pTegla[6,3] := P063;
  _pTegla[6,4] := P064;
  _pTegla[6,5] := P065;
  _pTegla[6,6] := P066;
  _pTegla[6,7] := P067;
  _pTegla[6,8] := P068;
  _pTegla[6,9] := P069;
  _pTegla[6,10]:= P06A;

  _pTegla[7,1] := P071;
  _pTegla[7,2] := P072;
  _pTegla[7,3] := P073;
  _pTegla[7,4] := P074;
  _pTegla[7,5] := P075;
  _pTegla[7,6] := P076;
  _pTegla[7,7] := P077;
  _pTegla[7,8] := P078;
  _pTegla[7,9] := P079;
  _pTegla[7,10]:= P07A;

  _pTegla[8,1] := P081;
  _pTegla[8,2] := P082;
  _pTegla[8,3] := P083;
  _pTegla[8,4] := P084;
  _pTegla[8,5] := P085;
  _pTegla[8,6] := P086;
  _pTegla[8,7] := P087;
  _pTegla[8,8] := P088;
  _pTegla[8,9] := P089;
  _pTegla[8,10]:= P08A;

  _pTegla[9,1] := P091;
  _pTegla[9,2] := P092;
  _pTegla[9,3] := P093;
  _pTegla[9,4] := P094;
  _pTegla[9,5] := P095;
  _pTegla[9,6] := P096;
  _pTegla[9,7] := P097;
  _pTegla[9,8] := P098;
  _pTegla[9,9] := P099;
  _pTegla[9,10]:= P09A;

  _pTegla[10,1] := P101;
  _pTegla[10,2] := P102;
  _pTegla[10,3] := P103;
  _pTegla[10,4] := P104;
  _pTegla[10,5] := P105;
  _pTegla[10,6] := P106;
  _pTegla[10,7] := P107;
  _pTegla[10,8] := P108;
  _pTegla[10,9] := P109;
  _pTegla[10,10]:= P10A;

  _pTegla[11,1] := P111;
  _pTegla[11,2] := P112;
  _pTegla[11,3] := P113;
  _pTegla[11,4] := P114;
  _pTegla[11,5] := P115;
  _pTegla[11,6] := P116;
  _pTegla[11,7] := P117;
  _pTegla[11,8] := P118;
  _pTegla[11,9] := P119;
  _pTegla[11,10]:= P11A;

  _pTegla[12,1] := P121;
  _pTegla[12,2] := P122;
  _pTegla[12,3] := P123;
  _pTegla[12,4] := P124;
  _pTegla[12,5] := P125;
  _pTegla[12,6] := P126;
  _pTegla[12,7] := P127;
  _pTegla[12,8] := P128;
  _pTegla[12,9] := P129;
  _pTegla[12,10]:= P12A;

  _pTegla[13,1] := P131;
  _pTegla[13,2] := P132;
  _pTegla[13,3] := P133;
  _pTegla[13,4] := P134;
  _pTegla[13,5] := P135;
  _pTegla[13,6] := P136;
  _pTegla[13,7] := P137;
  _pTegla[13,8] := P138;
  _pTegla[13,9] := P139;
  _pTegla[13,10]:= P13A;

  _pTegla[14,1] := P141;
  _pTegla[14,2] := P142;
  _pTegla[14,3] := P143;
  _pTegla[14,4] := P144;
  _pTegla[14,5] := P145;
  _pTegla[14,6] := P146;
  _pTegla[14,7] := P147;
  _pTegla[14,8] := P148;
  _pTegla[14,9] := P149;
  _pTegla[14,10]:= P14A;

  _pTegla[15,1] := P151;
  _pTegla[15,2] := P152;
  _pTegla[15,3] := P153;
  _pTegla[15,4] := P154;
  _pTegla[15,5] := P155;
  _pTegla[15,6] := P156;
  _pTegla[15,7] := P157;
  _pTegla[15,8] := P158;
  _pTegla[15,9] := P159;
  _pTegla[15,10]:= P15A;

  _pTegla[16,1] := P161;
  _pTegla[16,2] := P162;
  _pTegla[16,3] := P163;
  _pTegla[16,4] := P164;
  _pTegla[16,5] := P165;
  _pTegla[16,6] := P166;
  _pTegla[16,7] := P167;
  _pTegla[16,8] := P168;
  _pTegla[16,9] := P169;
  _pTegla[16,10]:= P16A;

  _pTegla[17,1] := P171;
  _pTegla[17,2] := P172;
  _pTegla[17,3] := P173;
  _pTegla[17,4] := P174;
  _pTegla[17,5] := P175;
  _pTegla[17,6] := P176;
  _pTegla[17,7] := P177;
  _pTegla[17,8] := P178;
  _pTegla[17,9] := P179;
  _pTegla[17,10]:= P17A;

  _pTegla[18,1] := P181;
  _pTegla[18,2] := P182;
  _pTegla[18,3] := P183;
  _pTegla[18,4] := P184;
  _pTegla[18,5] := P185;
  _pTegla[18,6] := P186;
  _pTegla[18,7] := P187;
  _pTegla[18,8] := P188;
  _pTegla[18,9] := P189;
  _pTegla[18,10]:= P18A;

  _pTegla[19,1] := P191;
  _pTegla[19,2] := P192;
  _pTegla[19,3] := P193;
  _pTegla[19,4] := P194;
  _pTegla[19,5] := P195;
  _pTegla[19,6] := P196;
  _pTegla[19,7] := P197;
  _pTegla[19,8] := P198;
  _pTegla[19,9] := P199;
  _pTegla[19,10]:= P19A;

  _pTegla[20,1] := P201;
  _pTegla[20,2] := P202;
  _pTegla[20,3] := P203;
  _pTegla[20,4] := P204;
  _pTegla[20,5] := P205;
  _pTegla[20,6] := P206;
  _pTegla[20,7] := P207;
  _pTegla[20,8] := P208;
  _pTegla[20,9] := P209;
  _pTegla[20,10]:= P20A;

  _pTegla[21,1] := P211;
  _pTegla[21,2] := P212;
  _pTegla[21,3] := P213;
  _pTegla[21,4] := P214;
  _pTegla[21,5] := P215;
  _pTegla[21,6] := P216;
  _pTegla[21,7] := P217;
  _pTegla[21,8] := P218;
  _pTegla[21,9] := P219;
  _pTegla[21,10]:= P21A;

  _pTegla[22,1] := P221;
  _pTegla[22,2] := P222;
  _pTegla[22,3] := P223;
  _pTegla[22,4] := P224;
  _pTegla[22,5] := P225;
  _pTegla[22,6] := P226;
  _pTegla[22,7] := P227;
  _pTegla[22,8] := P228;
  _pTegla[22,9] := P229;
  _pTegla[22,10]:= P22A;

  _pTegla[23,1] := P231;
  _pTegla[23,2] := P232;
  _pTegla[23,3] := P233;
  _pTegla[23,4] := P234;
  _pTegla[23,5] := P235;
  _pTegla[23,6] := P236;
  _pTegla[23,7] := P237;
  _pTegla[23,8] := P238;
  _pTegla[23,9] := P239;
  _pTegla[23,10]:= P23A;

  _pTegla[24,1] := P241;
  _pTegla[24,2] := P242;
  _pTegla[24,3] := P243;
  _pTegla[24,4] := P244;
  _pTegla[24,5] := P245;
  _pTegla[24,6] := P246;
  _pTegla[24,7] := P247;
  _pTegla[24,8] := P248;
  _pTegla[24,9] := P249;
  _pTegla[24,10]:= P24A;

  _pTegla[25,1] := P251;
  _pTegla[25,2] := P252;
  _pTegla[25,3] := P253;
  _pTegla[25,4] := P254;
  _pTegla[25,5] := P255;
  _pTegla[25,6] := P256;
  _pTegla[25,7] := P257;
  _pTegla[25,8] := P258;
  _pTegla[25,9] := P259;
  _pTegla[25,10]:= P25A;

  _pTegla[26,1] := P261;
  _pTegla[26,2] := P262;
  _pTegla[26,3] := P263;
  _pTegla[26,4] := P264;
  _pTegla[26,5] := P265;
  _pTegla[26,6] := P266;
  _pTegla[26,7] := P267;
  _pTegla[26,8] := P268;
  _pTegla[26,9] := P269;
  _pTegla[26,10]:= P26A;

  _pTegla[27,1] := P271;
  _pTegla[27,2] := P272;
  _pTegla[27,3] := P273;
  _pTegla[27,4] := P274;
  _pTegla[27,5] := P275;
  _pTegla[27,6] := P276;
  _pTegla[27,7] := P277;
  _pTegla[27,8] := P278;
  _pTegla[27,9] := P279;
  _pTegla[27,10]:= P27A;

  _pTegla[28,1] := P281;
  _pTegla[28,2] := P282;
  _pTegla[28,3] := P283;
  _pTegla[28,4] := P284;
  _pTegla[28,5] := P285;
  _pTegla[28,6] := P286;
  _pTegla[28,7] := P287;
  _pTegla[28,8] := P288;
  _pTegla[28,9] := P289;
  _pTegla[28,10]:= P28A;


end;


// =============================================================================
            procedure TmunkaForm.SetJeloloKoord(_szin: TCOlor);
// =============================================================================


begin
  _jLeft := 27 + 70*(_startoszlop-1);
  _jTop  := 97 + 22*(_startSor-1);
  _jHeight := 22*(_endSor-_startSor+1)+3;
  _jWidth := 70*(_endOszlop-_startOszlop+1) +5;

  with JELOLOPANEL do
    begin
      Top := _jTop;
      Left := _jLeft;
      Width := _jWidth;
      Height := _jHeight;
      COlor := _szin;
      Visible := True;
    end;
end;

// =============================================================================
    procedure TMUNKAFORM.P011MouseDown(Sender: TObject; Button: TMouseButton;
                                             Shift: TShiftState; X, Y: Integer);
// =============================================================================


begin
   // Meghatározza a tégla aktuális sorát és oszlopát
   _teglanev := TPanel(sender).Name;
   SetKoord(_teglanev);

  // A duplakattintás után itt már nem kell semmit csinálni
  if _double then
    begin
      _double := false;
      exit;
     end;

  // Ha kijelölt egy területet, akkor azt kell lekezelnie
  if _zold then
    begin
      Zoldrutin;
      exit;
    end;

  // Ha nem a ctrl + mouse left van, akkor
  if shift<>[ssCtrl..ssLeft] then
    begin
   //   if _isMarker then exit;

      // Ha nem éppen jelölésben van

      if not _signing then
        begin

          // Itt megállapitja az aktfuggvény értékét:

      //    Fuggvenykijelzes;

          // Bepirositja az aktuális téglát,
          // itt kézi vezérlés következik:

          _manual      := true;        // kézi vezérlés cursor bill-vel

          // A kezdõ és végkoordináták azonosak:
          _startoszlop := _aktoszlop;
          _endoszlop   := _aktoszlop;
          _startsor    := _aktsor;
          _endsor      := _aktsor;

          // Aláteszi a piros jelölõpanelt:

          Setjelolokoord(clRed);

          // Ha van a téglának függvénye, akkor függvénykezelés;
        //  if _aktfuggveny<>'' then FuggvenyKezelo(_aktsor,_aktoszlop);

          // A kézi kezelés eszköze a Hideedit:
          ActiveControl := HideEdit;
          exit;
        end;

      // Ha kijelölés közben nyomott, akkor jelölés kész

      // A jelölt terület zöldre vált:
      JeloloPanel.Color := clLime;
      _zold    := True;
      _signing := false;
      Zoldrutin;
      exit;
    end;

  // Itt kezdünk egy lila jelölést:

  _manual := False;    // nem kézi
  _signing := True;    // jelölés folyamatban

  // Minden koordináta ezen a téglán:
  _startoszlop := _aktoszlop;
  _endOszlop   := _aktoszlop;
  _startSor    := _aktsor;
  _endsor      := _aktsor;

  // Lilával körberajzolja a téglát:
  SetJeloloKoord(clFuchsia);
end;

// =============================================================================
    procedure TMUNKAFORM.P011MouseMove(Sender: TObject; Shift: TShiftState; X,
                                                                   Y: Integer);
// =============================================================================

begin
  // Ha még ugyanazon téglán utazik, akkor semmi
  _teglanev := Tpanel(Sender).Name;
  if _teglanev=_utteglanev then exit;

  // ez már egy másik tégla
  _utteglanev := _teglanev;

  // Aktsor és aktoszlop meghatározása:
  SetKoord(_teglanev);

  // Ha itt ,ég nincs kijelölésrõl szó - függvénykijelzés
  if not _signing then
    begin
      FuggvenyKijelzes;
      exit;
    end;

  // ha már ki van jelölve terület, akkor nem megy tovább
  if _zold then exit;

  // Ha nem jó irányba megy az egér, akkor kilép
  if (_aktsor<_startsor) or (_aktoszlop<_startoszlop) then exit;

  // Jó irányba ment az egér, lila jelölés növekedik
  _endsor := _aktsor;
  _endoszlop := _aktoszlop;
  SetjeloloKoord(clFuchsia);
end;

// =============================================================================
                    procedure TMunkaForm.SetKoord(_nn: string);
// =============================================================================



begin
  _aktsor := strtoint(midstr(_nn,2,2));
  _aktoszlop := ord(_nn[4])-48;
  if _aktoszlop>9 then _aktoszlop := 10;

  _kpLeft := 32  + 70*(_aktoszlop-1);
  _kpTop  := 101 + 28*(_aktSor-1);
  _pleft := _kpleft - 5;
  _pTop  := _kpTop  - 5;
end;

// =============================================================================
                     procedure Tmunkaform.FuggvenyKijelzes;
// =============================================================================

var _dispFuggveny: string;

begin
  _dispFuggveny := '';
  case _aktoszlop of
    1: _dispFuggveny := _jfuggveny[_aktcsoport,_aktsor];
    3: _dispFuggveny := _lfuggveny[_aktcsoport,_aktsor];
    4: _dispFuggveny := _mfuggveny[_aktcsoport,_aktsor];
    5: _dispFuggveny := _nfuggveny[_aktcsoport,_aktsor];
    6: _dispFuggveny := _ofuggveny[_aktcsoport,_aktsor];
    7: _dispFuggveny := _pfuggveny[_aktcsoport,_aktsor];
    8: _dispFuggveny := _qfuggveny[_aktcsoport,_aktsor];
    9: _dispFuggveny := _rfuggveny[_aktcsoport,_aktsor];
   10: _dispFuggveny := _sfuggveny[_aktcsoport,_aktsor];
  end;
  if _dispfuggveny='' then
    begin
      fuggvenyPanel.caption := '';
      FuggvenyPanel.color := clWhite;
      FuggvenyShape.Brush.color := clWhite;
    end else
    begin
      fuggvenyPanel.caption := _dispfuggveny;
      FuggvenyPanel.color := $B0FFFF;
      FuggvenyShape.Brush.color := $B0FFFF;
    end;
end;

// =============================================================================
     procedure TMUNKAFORM.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
                                                                   Y: Integer);
// =============================================================================

begin
  ClearFms;
end;

// =============================================================================
         procedure TMunkaForm.GetTeglaAdatok(_xsor,_xoszlop: integer);
// =============================================================================


begin
  case _xOszlop of
    1: begin
         _aktErtekstring := _jertek[_aktcsoport,_xsor];
         _aktfuggvenystring := _jFuggveny[_aktcsoport,_xsor];
         _aktbetuszin := _jBetuszin[_aktcsoport,_xsor];
         _aktHatterszin := _jHatterSzin[_aktcsoport,_xsor];
       end;

    2: begin
         _aktErtekstring := _kertek[_aktcsoport,_xsor];
         _aktfuggvenystring := _kFuggveny[_aktcsoport,_xsor];
         _aktbetuszin := _kBetuszin[_aktcsoport,_xsor];
         _aktHatterszin := _kHatterSzin[_aktcsoport,_xsor];
       end;

    3: begin
         _aktErtekstring := _lertek[_aktcsoport,_xsor];
         _aktfuggvenystring := _lFuggveny[_aktcsoport,_xsor];
         _aktbetuszin := _lBetuszin[_aktcsoport,_xsor];
         _aktHatterszin := _lHatterSzin[_aktcsoport,_xsor];
       end;

    4: begin
         _aktErtekstring := _mertek[_aktcsoport,_xsor];
         _aktfuggvenystring := _mFuggveny[_aktcsoport,_xsor];
         _aktbetuszin := _mBetuszin[_aktcsoport,_xsor];
         _aktHatterszin := _mHatterSzin[_aktcsoport,_xsor];
       end;

    5: begin
         _aktErtekstring := _nertek[_aktcsoport,_xsor];
         _aktfuggvenystring := _nFuggveny[_aktcsoport,_xsor];
         _aktbetuszin := _nBetuszin[_aktcsoport,_xsor];
         _aktHatterszin := _nHatterSzin[_aktcsoport,_xsor];
        end;

    6: begin
         _aktErtekstring := _oertek[_aktcsoport,_xsor];
         _aktfuggvenystring := _oFuggveny[_aktcsoport,_xsor];
         _aktbetuszin := _oBetuszin[_aktcsoport,_xsor];
         _aktHatterszin := _oHatterSzin[_aktcsoport,_xsor];
       end;

    7: begin
         _aktErtekstring := _pertek[_aktcsoport,_xsor];
         _aktfuggvenystring := _pFuggveny[_aktcsoport,_xsor];
         _aktbetuszin := _pBetuszin[_aktcsoport,_xsor];
         _aktHatterszin := _pHatterSzin[_aktcsoport,_xsor];
       end;

    8: begin
         _aktErtekstring := _qertek[_aktcsoport,_xsor];
         _aktfuggvenystring := _qFuggveny[_aktcsoport,_xsor];
         _aktbetuszin := _qBetuszin[_aktcsoport,_xsor];
         _aktHatterszin := _qHatterSzin[_aktcsoport,_xsor];
       end;

      9: begin
         _aktErtekstring := _rertek[_aktcsoport,_xsor];
         _aktfuggvenystring := _rFuggveny[_aktcsoport,_xsor];
         _aktbetuszin := _rBetuszin[_aktcsoport,_xsor];
         _aktHatterszin := _rHatterSzin[_aktcsoport,_xsor];
       end;

     10: begin
         _aktErtekstring := _sertek[_aktcsoport,_xsor];
         _aktfuggvenystring := _sFuggveny[_aktcsoport,_xsor];
         _aktbetuszin := _sBetuszin[_aktcsoport,_xsor];
         _aktHatterszin := _sHatterSzin[_aktcsoport,_xsor];
       end;

  end;
end;


// =============================================================================
     procedure TMUNKAFORM.HIDEEDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================


var _bill: integer;

begin
  _bill := ord(key);
  if not _manual then exit;

  if (_bill>95) and (_bill<106) then _bill := _bill-48;
  if (_bill=110) or (_bill=44) then _bill := 46;

  case _bill of
    37: begin   // balra
          if _startOszlop = 1 then exit;
          dec(_startOszlop);
          dec(_endoszlop);
          SetjeloloKoord(clRed);
          _aktoszlop := _startoszlop;
          _aktsor := _startsor;
          FuggvenyKijelzes;
        end;

    38: begin   // felfele
          if _startSor = 1 then exit;
          dec(_startSor);
          dec(_endSor);
          SetjeloloKoord(clRed);
          _aktoszlop := _startoszlop;
          _aktsor := _startsor;
          FuggvenyKijelzes;
        end;

    39: begin  // jobbra
          if _startOszlop = 10 then exit;
          inc(_startOszlop);
          inc(_endoszlop);
          SetjeloloKoord(clRed);
          _aktoszlop := _startoszlop;
          _aktsor := _startsor;
          FuggvenyKijelzes;
        end;

    40: begin  // lefele
          if _startSor = _DNEMDARAB then exit;
          inc(_startSor);
          inc(_endSor);
          SetjeloloKoord(clRed);
          _aktoszlop := _startoszlop;
          _aktsor := _startsor;
          FuggvenyKijelzes;
        end;

    27: begin
          _manual := False;
          JeloloPanel.Visible := False;
         end;

     13: begin
           if _startoszlop=2 then exit;
           GetTeglaadatok(_startsor,_startoszlop);
           if _aktfuggvenystring<>'' then
             begin
               FuggvenyKezelo(_startsor,_startoszlop);
               Exit;
             end;

           Bignumedit.Text := _aktertekstring;
           with BignumPanel do
             begin
               Top := _jTop-19;
               Left := _jleft+100;
               Visible := true;
             end;

           ActiveControl := BignumEdit;
         end;


    end;
end;

// =============================================================================
      procedure TMUNKAFORM.BIGNUMEDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)=27 then
    begin
      Bignumpanel.Visible := false;
      ActiveControl := Hideedit;
      exit;
    end;

  if ord(key)<>13 then exit;
  _arfdataValtozott := True;
  Bignumpanel.Visible := false;

  _aktertekstring := Form1.VesszobolPont(bignumedit.text);
  Form1.ErtekControl;
  TombbeTegla(_startsor,_startoszlop);
  LapfelFrissito;
  if _startsor<20 then
    begin
      inc(_startsor);
      inc(_endsor);
      Setjelolokoord(clRed);
    end;

  ActiveControl := Hideedit;
end;

// =============================================================================
         procedure TMunkaForm.FuggvenyKezelo(_fsor,_foszlop: integer);
// =============================================================================

var _oke: integer;

begin
  _getfx := 36 + trunc(70*_foszlop);
  _getfy := 10 + trunc(29*_fSor);

  GetteglaAdatok(_fsor,_foszlop);
  _oke := GetFuggveny.Showmodal;

  if _oke =1 then
    begin
      TombbeTegla(_fsor,_foszlop);
      LapFelFrissito;
    end;
end;

// =============================================================================
               procedure TMUNKAFORM.P011DblClick(Sender: TObject);
// =============================================================================

begin
  if _signing then exit;
  if _zold then exit;
  _teglanev := TPanel(sender).Name;
  SetKoord(_teglanev);
  Fuggvenykijelzes;
  _manual      := true;
  _startoszlop := _aktoszlop;
  _endoszlop   := _aktoszlop;
  _startsor    := _aktsor;
  _endsor      := _aktsor;
  Setjelolokoord(clRed);
  FuggvenyKezelo(_aktsor,_aktoszlop);
  ActiveControl := HideEdit;
end;

// =============================================================================
                procedure TmunkaForm.Zoldrutin;
// =============================================================================


var _zmFlag: integer;
    _tmpNev: string;

begin
  _tmpnev := 'P'+ Form1.nulele(_startsor)+inttostr(_endoszlop);
  setKoord(_tmpnev);
  if _endoszlop<8 then _zMenuoszlop := _kpleft + 120
  else
  begin
    _zMenuoszlop := _kpleft - 340;
    if _zmenuoszlop<0 then _zMenuOszlop := 16;
  end;

  if _startsor>2 then _zmenusor := _KPTOP-168
  else _zmenusor := 16;

  // 1 = Másolás,  2= Lehuzás

  _zmFlag := zoldmenu.showmodal;

   _zold := False;
   _isMarker := False;
   _Signing := false;
   JeloloPanel.visible := false;

  case _zmflag of
     1: begin    // Másolás;
          _isMarker    := true;
          _MarkCsoport := _aktcsoport;
          _sMarkSor    := _startsor;
          _smarkOszlop := _startOszlop;
          _eMarkSor    := _endsor;
          _eMarkOszlop := _endOszlop;
          DataCopy;
         end;

     2: begin  // Lehuzás
          LehuzoRutin;
          LapRegeneralo;
          MunkaForm.repaint;
        end;
     end;



end;



// =============================================================================
                   procedure TMunkaForm.PenztarListaTolto;
// =============================================================================


begin
  PenztarLista.Items.Clear;
  PenztarLista.clear;
  _aktcsoportDarab := _csoportTagDarab[_aktcsoport];
  if _aktcsoportDarab=0 then exit;

  _qq := 1;
  while _qq<=_aktcsoportDarab do
    begin
      _aktiroda := _csoporttagok[_aktcsoport,_qq];
      _xx := Form1.ScanIroda(_aktiroda);
      _aktirodaNev := _ptarnev[_xx];
      _aktirodacim := _ptarcim[_xx];
      PenztarLista.Items.add(_aktirodanev+'/'+_aktirodacim);
      inc(_QQ);
    end;
end;

// =============================================================================
             procedure TMUNKAFORM.MODOSITOPANELClick(Sender: TObject);
// =============================================================================

begin
  ShowMessage('KEDVEZMÉNYHATÁROK MÓDOSITÁSA');
end;



// =============================================================================
            procedure TMUNKAFORM.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;



// =============================================================================
         procedure TMUNKAFORM.masikcsoportgombClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;

// =============================================================================
          procedure TMUNKAFORM.alapeditgombEnter(Sender: TObject);
// =============================================================================

begin
  with TBitbtn(sender).Font do
    begin
      Color := clNavy;
      style := [fsBold, fsItalic];
    end;
end;

// =============================================================================
            procedure TMUNKAFORM.alapeditgombExit(Sender: TObject);
// =============================================================================

begin
  with TBitbtn(sender).Font do
    begin
      Color := clBlack;
      style := [fsItalic];
    end;
end;

// =============================================================================
                         procedure TMunkaform.Lapregeneralo;
// =============================================================================

var _pars1,_pars2,_pars3: string;
    _cs1,_cs2,_cs3: integer;

begin
  Csopnevpanel.Caption := _csoportnevek[_aktcsoport];
  PenztarListaTolto;
  if _aktcsoport=0 then _aktcsoport := 3;

  _cslimit[1] := _klimit[_aktcsoport,1];
  _cslimit[2] := _klimit[_aktcsoport,2];
  _cslimit[3] := _klimit[_aktcsoport,3];

  Limit1edit.text :=  form1.forintform(trunc(1000*_cslimit[1]));
  Limit2edit.text :=  form1.forintform(trunc(1000*_cslimit[2]));
  Limit3edit.Text :=  form1.forintform(trunc(1000*_cslimit[3]));

  _cs1 := trunc(1000*_cslimit[1]);
  _cs2 := trunc(1000*_cslimit[2]);
  _cs3 := trunc(1000*_cslimit[3]);

  _pars1 := '0-'+pontos(_cs1);
  _pars2 := pontos(1+_cs1)+'-'+pontos(_cs2);
  _pars3 := pontos(1+_cs2)+'-'+pontos(_cs3);

  Limits1Panel.Caption := _pars1;
  Limits2Panel.Caption := _pars2;
  Limits3Panel.Caption := _pars3;
  TeglaBetolt;

  Lapfelfrissito;
end;

function TMunkaForm.Pontos(_lim: integer): string;

var _lims: string;
    _p1: integer;
begin
  _lims := inttostr(_lim);

  if _lim>=1000000 then
    begin
      _p1 := length(_lims)-6;
      result := leftstr(_lims,_p1)+'.'+midstr(_lims,_p1+1,3)+'.'+midstr(_lims,_p1+4,3);
      exit;
    end;

  if _lim<1000 then
    begin
      result := _lims;
      Exit;
    end;

  _p1 := length(_lims)-3;
  result := leftstr(_lims,_p1)+'.'+midstr(_lims,_p1+1,3);
end;



// =============================================================================
       procedure TMUNKAFORM.alapeditgombMouseMove(Sender: TObject;
                                          Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  ActiveControl := TBitbtn(sender);
end;


// =============================================================================
          procedure TMUNKAFORM.limiteditgombClick(Sender: TObject);
// =============================================================================


var _maslimit: integer;

begin
  _maslimit := LimitAllitoForm.ShowModal;
  if _maslimit = 1 then
    begin
      _arfdataValtozott := True;
      LapRegeneralo;
    end;
end;

// =============================================================================
                           procedure TMunkaForm.Datacopy;
// =============================================================================


var _hova: integer;

begin
  _markdb := 1;
  _marklista[1] := _aktcsoport;
  while true do
    begin
      _hova := Hovamasoljak.showmodal;
      if _hova=-1 then exit;
      inc(_markdb);
      _marklista[_markdb] := _hova;
      _aktcsoport := _hova;

      LapRegeneralo;
      Adatmasolorutin;
      LapRegeneralo;

      if Messagedlg('MÁSOLÁS SIKERES. MÁSIK CSOPORTBA IS MÁSOLJAK',
         mtconfirmation,[mbNo, mbYes],3)= mrNo then exit;
    end;
end;


// =============================================================================
                     procedure TmunkaForm.Lehuzorutin;
// =============================================================================

var _oo: integer;

begin
  _oo := _StartOszlop;
  while _oo<=_endoszlop do
    begin
      _aktsor := _startsor;
      GetTeglaAdatok(_aktsor,_oo);
      while _aktsor<=_endsor do
        begin
          TombbeTegla(_aktsor,_oo);
          _akttegla := _pTegla[_aktsor,_oo];

          _akttegla.color := clLime;
          _akttegla.Refresh;
          _akttegla.Repaint;

          Sleep(50);
          inc(_aktsor);
        end;
      inc(_oo);
    end;
end;

// =============================================================================
                 procedure TMunkaForm.AdatMAsolorutin;
// =============================================================================

begin
  // A _markcsoport _smarksor,_smarkoszlop - tól
  // az emarksor,_emarkoszlop celláit kell bamásolni
  // az _aktcsoport munkacsoport táblázatába.

  _ss := _smarksor;
  while _ss<=_emarksor do
    begin
      _oo := _smarkOszlop;
      while _oo<=_eMarkOszlop do
        begin
          _aktTegla := _pTegla[_ss,_oo];
          _aktTegla.Color := clLime;
          case _oo of
            1: begin
                 _cHatter := _jHatterszin[_markcsoport,_ss];
                 _jertek[_aktcsoport,_ss] := _cErtek;
                 _jfuggveny[_aktcsoport,_ss] := _cFuggveny;
                 _jBetuszin[_aktcsoport,_ss] := _cBetu;
                 _certek := _jertek[_markCsoport,_ss];
                 _cFuggveny := _jFuggveny[_markCsoport,_ss];
                 _cBetu := _jBetuszin[_markCsoport,_ss];
                 _jHatterszin[_aktcsoport,_ss] := _cHatter;
               end;

            3: begin
                 _certek := _lertek[_markCsoport,_ss];
                 _cFuggveny := _lFuggveny[_markCsoport,_ss];
                 _cBetu := _lBetuszin[_markCsoport,_ss];
                 _cHatter := _lHatterszin[_markcsoport,_ss];
                 _lertek[_aktcsoport,_ss] := _cErtek;
                 _lfuggveny[_aktcsoport,_ss] := _cFuggveny;
                 _lBetuszin[_aktcsoport,_ss] := _cBetu;
                 _lHatterszin[_aktcsoport,_ss] := _cHatter;
               end;

            4: begin
                 _certek := _mertek[_markCsoport,_ss];
                 _cFuggveny := _mFuggveny[_markCsoport,_ss];
                 _cBetu := _mBetuszin[_markCsoport,_ss];
                 _cHatter := _mHatterszin[_markcsoport,_ss];
                 _mertek[_aktcsoport,_ss] := _cErtek;
                 _mfuggveny[_aktcsoport,_ss] := _cFuggveny;
                 _mBetuszin[_aktcsoport,_ss] := _cBetu;
                 _mHatterszin[_aktcsoport,_ss] := _cHatter;
               end;

            5: begin
                 _certek := _nertek[_markCsoport,_ss];
                 _cFuggveny := _nFuggveny[_markCsoport,_ss];
                 _cBetu := _nBetuszin[_markCsoport,_ss];
                 _cHatter := _nHatterszin[_markcsoport,_ss];
                 _nertek[_aktcsoport,_ss] := _cErtek;
                 _nfuggveny[_aktcsoport,_ss] := _cFuggveny;
                 _nBetuszin[_aktcsoport,_ss] := _cBetu;
                 _nHatterszin[_aktcsoport,_ss] := _cHatter;
               end;

            6: begin
                 _certek := _oertek[_markCsoport,_ss];
                 _cFuggveny := _oFuggveny[_markCsoport,_ss];
                 _cBetu := _oBetuszin[_markCsoport,_ss];
                 _cHatter := _oHatterszin[_markcsoport,_ss];
                 _oertek[_aktcsoport,_ss] := _cErtek;
                 _ofuggveny[_aktcsoport,_ss] := _cFuggveny;
                 _oBetuszin[_aktcsoport,_ss] := _cBetu;
                 _oHatterszin[_aktcsoport,_ss] := _cHatter;
               end;

            7: begin
                 _certek := _pertek[_markCsoport,_ss];
                 _cFuggveny := _pFuggveny[_markCsoport,_ss];
                 _cBetu := _pBetuszin[_markCsoport,_ss];
                 _cHatter := _pHatterszin[_markcsoport,_ss];
                 _pertek[_aktcsoport,_ss] := _cErtek;
                 _pfuggveny[_aktcsoport,_ss] := _cFuggveny;
                 _pBetuszin[_aktcsoport,_ss] := _cBetu;
                 _pHatterszin[_aktcsoport,_ss] := _cHatter;
               end;

            8: begin
                 _certek := _qertek[_markCsoport,_ss];
                 _cFuggveny := _qFuggveny[_markCsoport,_ss];
                 _cBetu := _qBetuszin[_markCsoport,_ss];
                 _cHatter := _qHatterszin[_markcsoport,_ss];
                 _qertek[_aktcsoport,_ss] := _cErtek;
                 _qfuggveny[_aktcsoport,_ss] := _cFuggveny;
                 _qBetuszin[_aktcsoport,_ss] := _cBetu;
                 _qHatterszin[_aktcsoport,_ss] := _cHatter;
               end;

            9: begin
                 _certek := _rertek[_markCsoport,_ss];
                 _cFuggveny := _rFuggveny[_markCsoport,_ss];
                 _cBetu := _rBetuszin[_markCsoport,_ss];
                 _cHatter := _rHatterszin[_markcsoport,_ss];
                 _rertek[_aktcsoport,_ss] := _cErtek;
                 _rfuggveny[_aktcsoport,_ss] := _cFuggveny;
                 _rBetuszin[_aktcsoport,_ss] := _cBetu;
                 _rHatterszin[_aktcsoport,_ss] := _cHatter;
               end;

           10: begin
                 _certek := _sertek[_markCsoport,_ss];
                 _cFuggveny := _sFuggveny[_markCsoport,_ss];
                 _cBetu := _sBetuszin[_markCsoport,_ss];
                 _cHatter := _sHatterszin[_markcsoport,_ss];
                 _sertek[_aktcsoport,_ss] := _cErtek;
                 _sfuggveny[_aktcsoport,_ss] := _cFuggveny;
                 _sBetuszin[_aktcsoport,_ss] := _cBetu;
                 _sHatterszin[_aktcsoport,_ss] := _cHatter;
               end;

            end;
          _akttegla.Refresh;
          _akttegla.Repaint;
          sleep(50);
          inc(_oo);
        end;
      inc(_ss);
    end;
end;



procedure TMUNKAFORM.BitBtn2Click(Sender: TObject);
begin
  HelpForm.ShowModal;
end;

procedure TMUNKAFORM.szetkuldogombClick(Sender: TObject);
begin
  if not Form1.Vegcontrol then exit;
  AdatSzetkuldes.showmodal;
  ArfdataIras.showmodal;
end;




procedure TMUNKAFORM.FM4Click(Sender: TObject);
begin
  ArfdataIras.showmodal;
  Application.Terminate;
end;

procedure TMUNKAFORM.FM1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);

var _tag: integer;  

begin
  Clearfms;
  _tag := TPanel(Sender).Tag;
  _aktfm := _fm[_tag];
  _aktfm.color := $ffb0ff;
  _aktfm.Font.Style := [fsbold];
end;


procedure TMunkaform.ClearFms;

var i: integer;

begin
  for i := 1 to 4 do
    begin
      _aktfm := _fm[i];
      _aktfm.color := clBtnFace;
      _aktfm.Font.style := [];
    end;
end;

// =============================================================================
             procedure TMunkaForm.TombbeTegla(_zSor,_zOszlop: integer);
// =============================================================================

begin
  case _zOszlop of
    1: begin
         _jErtek[_aktcsoport,_zsor] := _aktErtekstring;
         _jFuggveny[_aktcsoport,_zsor] := _aktFuggvenyString;
         _jBetuszin[_aktcsoport,_zsor] := _aktBetuSzin;
         _jHatterSzin[_aktcsoport,_zsor] := _aktHatterSzin;
       end;

    3: begin
         _lErtek[_aktcsoport,_zsor] := _aktErtekstring;
         _lFuggveny[_aktcsoport,_zsor] := _aktFuggvenyString;
         _lBetuszin[_aktcsoport,_zsor] := _aktBetuSzin;
         _lHatterSzin[_aktcsoport,_zsor] := _aktHatterSzin;
       end;

    4: begin
         _mErtek[_aktcsoport,_zsor] := _aktErtekstring;
         _mFuggveny[_aktcsoport,_zsor] := _aktFuggvenyString;
         _mBetuszin[_aktcsoport,_zsor] := _aktBetuSzin;
         _mHatterSzin[_aktcsoport,_zsor] := _aktHatterSzin;
       end;

    5: begin
         _nErtek[_aktcsoport,_zsor] := _aktErtekstring;
         _nFuggveny[_aktcsoport,_zsor] := _aktFuggvenyString;
         _nBetuszin[_aktcsoport,_zsor] := _aktBetuSzin;
         _nHatterSzin[_aktcsoport,_zsor] := _aktHatterSzin;
       end;

    6: begin
         _oErtek[_aktcsoport,_zsor] := _aktErtekstring;
         _oFuggveny[_aktcsoport,_zsor] := _aktFuggvenyString;
         _oBetuszin[_aktcsoport,_zsor] := _aktBetuSzin;
         _oHatterSzin[_aktcsoport,_zsor] := _aktHatterSzin;
       end;

    7: begin
         _pErtek[_aktcsoport,_zsor] := _aktErtekstring;
         _pFuggveny[_aktcsoport,_zsor] := _aktFuggvenyString;
         _pBetuszin[_aktcsoport,_zsor] := _aktBetuSzin;
         _pHatterSzin[_aktcsoport,_zsor] := _aktHatterSzin;
       end;

    8: begin
         _qErtek[_aktcsoport,_zsor] := _aktErtekstring;
         _qFuggveny[_aktcsoport,_zsor] := _aktFuggvenyString;
         _qBetuszin[_aktcsoport,_zsor] := _aktBetuSzin;
         _qHatterSzin[_aktcsoport,_zsor] := _aktHatterSzin;
       end;

      9: begin
         _rErtek[_aktcsoport,_zsor] := _aktErtekstring;
         _rFuggveny[_aktcsoport,_zsor] := _aktFuggvenyString;
         _rBetuszin[_aktcsoport,_zsor] := _aktBetuSzin;
         _rHatterSzin[_aktcsoport,_zsor] := _aktHatterSzin;
       end;

      10: begin
         _sErtek[_aktcsoport,_zsor] := _aktErtekstring;
         _sFuggveny[_aktcsoport,_zsor] := _aktFuggvenyString;
         _sBetuszin[_aktcsoport,_zsor] := _aktBetuSzin;
         _sHatterSzin[_aktcsoport,_zsor] := _aktHatterSzin;
       end;
    end;
end;




































































end.
