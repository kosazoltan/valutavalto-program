unit Unit9;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ExtCtrls, StdCtrls, Buttons, unit1, strUtils, jpeg;

type
  TALAPLAP = class(TForm)
    A016: TPanel;
    A022: TPanel;
    A062: TPanel;
    A025: TPanel;
    A032: TPanel;
    A042: TPanel;
    A206: TPanel;
    A171: TPanel;
    A152: TPanel;
    A072: TPanel;
    A023: TPanel;
    A161: TPanel;
    A081: TPanel;
    A061: TPanel;
    A051: TPanel;
    A122: TPanel;
    A091: TPanel;
    Panel26: TPanel;
    A182: TPanel;
    A162: TPanel;
    A201: TPanel;
    A191: TPanel;
    A151: TPanel;
    A141: TPanel;
    A111: TPanel;
    A112: TPanel;
    A092: TPanel;
    A013: TPanel;
    A015: TPanel;
    A205: TPanel;
    A011: TPanel;
    A024: TPanel;
    A014: TPanel;
    A031: TPanel;
    A071: TPanel;
    A102: TPanel;
    A082: TPanel;
    A132: TPanel;
    A142: TPanel;
    A131: TPanel;
    A121: TPanel;
    A101: TPanel;
    A202: TPanel;
    A181: TPanel;
    A192: TPanel;
    A203: TPanel;
    A172: TPanel;
    A204: TPanel;
    A052: TPanel;
    A021: TPanel;
    A012: TPanel;
    A041: TPanel;
    A036: TPanel;
    A046: TPanel;
    A053: TPanel;
    A026: TPanel;
    A064: TPanel;
    A055: TPanel;
    A113: TPanel;
    A097: TPanel;
    A098: TPanel;
    A096: TPanel;
    A086: TPanel;
    A076: TPanel;
    A066: TPanel;
    A056: TPanel;
    A033: TPanel;
    A043: TPanel;
    A093: TPanel;
    A133: TPanel;
    A123: TPanel;
    A106: TPanel;
    A085: TPanel;
    A099: TPanel;
    A136: TPanel;
    A126: TPanel;
    A146: TPanel;
    A186: TPanel;
    A196: TPanel;
    A176: TPanel;
    A156: TPanel;
    A143: TPanel;
    A166: TPanel;
    A109: TPanel;
    A103: TPanel;
    A116: TPanel;
    A034: TPanel;
    A035: TPanel;
    A073: TPanel;
    A063: TPanel;
    A044: TPanel;
    A037: TPanel;
    A049: TPanel;
    A057: TPanel;
    A089: TPanel;
    A045: TPanel;
    A084: TPanel;
    A047: TPanel;
    A075: TPanel;
    A054: TPanel;
    A074: TPanel;
    A065: TPanel;
    A163: TPanel;
    A183: TPanel;
    A173: TPanel;
    A058: TPanel;
    A048: TPanel;
    A078: TPanel;
    A068: TPanel;
    A088: TPanel;
    A059: TPanel;
    A193: TPanel;
    A083: TPanel;
    A038: TPanel;
    A067: TPanel;
    A039: TPanel;
    A079: TPanel;
    A087: TPanel;
    A194: TPanel;
    A095: TPanel;
    A153: TPanel;
    A158: TPanel;
    A154: TPanel;
    A137: TPanel;
    A148: TPanel;
    A138: TPanel;
    A157: TPanel;
    A147: TPanel;
    A167: TPanel;
    A149: TPanel;
    A177: TPanel;
    A169: TPanel;
    A139: TPanel;
    A069: TPanel;
    A104: TPanel;
    A105: TPanel;
    A115: TPanel;
    A114: TPanel;
    A125: TPanel;
    A135: TPanel;
    A107: TPanel;
    A108: TPanel;
    A119: TPanel;
    A117: TPanel;
    A128: TPanel;
    A127: TPanel;
    A094: TPanel;
    A134: TPanel;
    A144: TPanel;
    A159: TPanel;
    A077: TPanel;
    A155: TPanel;
    A118: TPanel;
    A164: TPanel;
    A145: TPanel;
    A168: TPanel;
    A175: TPanel;
    A185: TPanel;
    A174: TPanel;
    A184: TPanel;
    A165: TPanel;
    A195: TPanel;
    A129: TPanel;
    A124: TPanel;
    A199: TPanel;
    A188: TPanel;
    A187: TPanel;
    A189: TPanel;
    A198: TPanel;
    A197: TPanel;
    A178: TPanel;
    A179: TPanel;
    Panel202: TPanel;
    Panel203: TPanel;
    Panel204: TPanel;
    Panel205: TPanel;
    Panel206: TPanel;
    Panel207: TPanel;
    Panel208: TPanel;
    Panel209: TPanel;
    Panel210: TPanel;
    Panel211: TPanel;
    Panel212: TPanel;
    INTERNETPANEL: TPanel;
    IG12: TBitBtn;
    IG13: TBitBtn;
    IG14: TBitBtn;
    IG15: TBitBtn;
    IG17: TBitBtn;
    IG18: TBitBtn;
    IG19: TBitBtn;
    Label1: TLabel;
    Label2: TLabel;
    Shape1: TShape;
    FUGGVENYSHOW: TPanel;
    JELOLOPANEL: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    Panel10: TPanel;
    A017: TPanel;
    A018: TPanel;
    A019: TPanel;
    A027: TPanel;
    A028: TPanel;
    A029: TPanel;
    A207: TPanel;
    A208: TPanel;
    A209: TPanel;
    Shape2: TShape;
    URLSHOW: TPanel;
    HIDEEDIT: TEdit;
    bignumpanel: TPanel;
    BIGNUMEDIT: TEdit;
    IG10: TBitBtn;
    IG1: TBitBtn;
    IG2: TBitBtn;
    IG3: TBitBtn;
    IG4: TBitBtn;
    IG5: TBitBtn;
    IG6: TBitBtn;
    IG7: TBitBtn;
    IG8: TBitBtn;
    IG9: TBitBtn;
    IG11: TBitBtn;
    IG16: TBitBtn;
    IG0: TBitBtn;
    IG20: TBitBtn;
    ALAPMENUBETOLTO: TTimer;
    ZOLDMENUPANEL: TPanel;
    ZMLEHUZOGOMB: TBitBtn;
    ZMMEGSEMGOMB: TBitBtn;
    A211: TPanel;
    A212: TPanel;
    A213: TPanel;
    A215: TPanel;
    A216: TPanel;
    A217: TPanel;
    A218: TPanel;
    A219: TPanel;
    A214: TPanel;
    IG21: TBitBtn;
    A221: TPanel;
    A222: TPanel;
    A223: TPanel;
    A224: TPanel;
    A225: TPanel;
    A226: TPanel;
    A227: TPanel;
    A228: TPanel;
    A229: TPanel;
    IG22: TBitBtn;
    ALAPIMAGE: TImage;
    Label4: TLabel;
    Label5: TLabel;
    menupanel: TPanel;
    csoporttmkgomb: TPanel;
    SZETKULDOGOMB: TPanel;
    URLTMKGOMB: TPanel;
    KILEPESGOMB: TPanel;
    A231: TPanel;
    A232: TPanel;
    A233: TPanel;
    A234: TPanel;
    A235: TPanel;
    A236: TPanel;
    A238: TPanel;
    A239: TPanel;
    A237: TPanel;
    IG23: TBitBtn;
    A245: TPanel;
    A241: TPanel;
    A242: TPanel;
    A243: TPanel;
    A244: TPanel;
    A246: TPanel;
    A247: TPanel;
    A248: TPanel;
    A249: TPanel;
    IG24: TBitBtn;
    A251: TPanel;
    A261: TPanel;
    A271: TPanel;
    A259: TPanel;
    A268: TPanel;
    A279: TPanel;
    A278: TPanel;
    A258: TPanel;
    A277: TPanel;
    A267: TPanel;
    A257: TPanel;
    A276: TPanel;
    A256: TPanel;
    A269: TPanel;
    A275: TPanel;
    A265: TPanel;
    A255: TPanel;
    A274: TPanel;
    A254: TPanel;
    A264: TPanel;
    A273: TPanel;
    A263: TPanel;
    A253: TPanel;
    A272: TPanel;
    A262: TPanel;
    A252: TPanel;
    A266: TPanel;
    ig25: TBitBtn;
    IG26: TBitBtn;
    IG27: TBitBtn;
    A281: TPanel;
    A282: TPanel;
    A283: TPanel;
    A284: TPanel;
    A285: TPanel;
    A286: TPanel;
    A287: TPanel;
    A288: TPanel;
    A289: TPanel;
    IG28: TBitBtn;

    procedure BitBtn3Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure TeglaTombbeTolt;
    procedure LapfelFrissito;
    procedure INTERNETGOMBClick(Sender: TObject);
    procedure SetKoord(_nn: string);
   
    procedure A011MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure OTPGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure A011MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);

   procedure SetJeloloKoord(_szin: TCOlor);
   procedure Alapteglaba(_zsor,_soszlop: integer);
   procedure ZoldRutin;
   procedure FuggvenyKezelo(_fsor,_foszlop: integer);
   procedure GetTeglaAdatok(_xsor,_xoszlop: integer);
    procedure HIDEEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure BIGNUMEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure IG0Click(Sender: TObject);
    procedure INTERNETPANELMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure INTERNETPANELClick(Sender: TObject);
 
    procedure SZETKULDOGOMBEnter(Sender: TObject);
    procedure SZETKULDOGOMBExit(Sender: TObject);
    procedure SZETKULDOGOMBMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);

    procedure FmbillClear;
    procedure BignumPuffan;
    procedure INTERNETTMKGOMBClick(Sender: TObject);
    procedure ZMLEHUZOGOMBClick(Sender: TObject);
    procedure ZMMEGSEMGOMBClick(Sender: TObject);
    procedure A011DblClick(Sender: TObject);
    procedure SZETKULDOGOMBClick(Sender: TObject);
    procedure csoporttmkgombMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure KILEPESGOMBClick(Sender: TObject);

    procedure csoporttmkgombClick(Sender: TObject);
    procedure Panel202MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ALAPLAP: TALAPLAP;
  _wTegla: array[1..28,1..9] of TPanel;
  _itGomb: array[0..28] of TBitBtn;
  _fmbill: array[1..4] of Tpanel;
  _teglaNev: string;
  _aktgomb: TBitbtn;
  _amHeight,_amWidth,_bnheight,_bnWidth: integer;

implementation

uses Unit11, Unit8, Unit3, Unit2, Unit6, Unit5, Unit7;

{$R *.dfm}


// =============================================================================
                procedure TALAPLAP.FormActivate(Sender: TObject);
// =============================================================================


begin
  Top    := _top;
  Left   := _left;
  Width  := 1366;
  Height := 729;

  JeloloPanel.visible := False;
  BignumPanel.Visible := False;
  ZoldMenuPanel.Visible := False;

  _fmbill[1] := CsoportTMKGomb;
  _fmbill[2] := SzetkuldoGomb;
  _fmbill[3] := URLTmkGomb;
  _fmbill[4] := KilepesGomb;

  Urlshow.caption := '';
  Fuggvenyshow.Caption := '';
  TeglaTombbeTolt;

  _aktcsoport := 0;

  LapfelFrissito;
  _utteglanev := 'xx';

  _zold    := False;
  _double  := False;
  _manual  := False;
  _signing := false;
end;


// =============================================================================
                    procedure TalapLap.LapfelFrissito;
// =============================================================================

var _ugomb: integer;
    _akturlnev,_gombnev: string;

begin

  Form1.MindentAtszamolo;

  _sor := 1;
  while _sor<=_dnemdarab do
    begin
      _oszlop := 1;
      while _oszlop<=9 do
        begin
          _akttegla := _wtegla[_sor,_oszlop];
          _aktErtekstring := _wertek[_sor,_oszlop];
          _aktBetuszin := _wBetuszin[_sor,_oszlop];
          _aktHatterszin := _wHatterszin[_sor,_oszlop];
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

  _qq := 1;
  while _qq<=_dnemdarab do
    begin
      _aktgomb := _itgomb[_qq];
      _aktgomb.Caption := '';
      _aktgomb.Tag := 255;
      _aktgomb.cursor := crNo;
      inc(_qq);
    end;

  _qq := 1;
  while _qq<=_urldarab do
    begin
      _ugomb := _urlGombszam[_qq];
      _gombnev := _urlGombNevek[_qq];
      _akturlnev := _urlNevek[_qq];

      _aktgomb := _itgomb[_ugomb];
      _aktgomb.Caption := _gombnev;
      _aktgomb.tag := _qq;
      _aktgomb.Cursor := crHandPoint;
      inc(_qq);
    end;
end;


// =============================================================================
             procedure TALAPLAP.INTERNETGOMBClick(Sender: TObject);
// =============================================================================

var _oke,_urlss: integer;

begin
  if _nyitottWeblap then
    begin
      ShowMessage('EGY WEBLAP NYITVA VAN. ELÖBB AZT BE KELL ZÁRNI');
      InternetBongeszo.Showmodal;
      Exit;
    end;

  _urlss := TBitbtn(sender).Tag;
  if _urlss=255 then exit;

  _aktUrl := _urlnevek[_urlss];
  _oke := InternetBongeszo.Showmodal;
  if _oke=1 then _NyitottWebLap := False;
end;

// =============================================================================
                     procedure TAlaplap.TeglaTombbeTolt;
// =============================================================================

begin
  _wTegla[1,1] := A011;
  _wTegla[1,2] := A012;
  _wTegla[1,3] := A013;
  _wTegla[1,4] := A014;
  _wTegla[1,5] := A015;
  _wTegla[1,6] := A016;
  _wTegla[1,7] := A017;
  _wTegla[1,8] := A018;
  _wTegla[1,9] := A019;

  _wTegla[2,1] := A021;
  _wTegla[2,2] := A022;
  _wTegla[2,3] := A023;
  _wTegla[2,4] := A024;
  _wTegla[2,5] := A025;
  _wTegla[2,6] := A026;
  _wTegla[2,7] := A027;
  _wTegla[2,8] := A028;
  _wTegla[2,9] := A029;

  _wTegla[3,1] := A031;
  _wTegla[3,2] := A032;
  _wTegla[3,3] := A033;
  _wTegla[3,4] := A034;
  _wTegla[3,5] := A035;
  _wTegla[3,6] := A036;
  _wTegla[3,7] := A037;
  _wTegla[3,8] := A038;
  _wTegla[3,9] := A039;

  _wTegla[4,1] := A041;
  _wTegla[4,2] := A042;
  _wTegla[4,3] := A043;
  _wTegla[4,4] := A044;
  _wTegla[4,5] := A045;
  _wTegla[4,6] := A046;
  _wTegla[4,7] := A047;
  _wTegla[4,8] := A048;
  _wTegla[4,9] := A049;

  _wTegla[5,1] := A051;
  _wTegla[5,2] := A052;
  _wTegla[5,3] := A053;
  _wTegla[5,4] := A054;
  _wTegla[5,5] := A055;
  _wTegla[5,6] := A056;
  _wTegla[5,7] := A057;
  _wTegla[5,8] := A058;
  _wTegla[5,9] := A059;

  _wTegla[6,1] := A061;
  _wTegla[6,2] := A062;
  _wTegla[6,3] := A063;
  _wTegla[6,4] := A064;
  _wTegla[6,5] := A065;
  _wTegla[6,6] := A066;
  _wTegla[6,7] := A067;
  _wTegla[6,8] := A068;
  _wTegla[6,9] := A069;

  _wTegla[7,1] := A071;
  _wTegla[7,2] := A072;
  _wTegla[7,3] := A073;
  _wTegla[7,4] := A074;
  _wTegla[7,5] := A075;
  _wTegla[7,6] := A076;
  _wTegla[7,7] := A077;
  _wTegla[7,8] := A078;
  _wTegla[7,9] := A079;

  _wTegla[8,1] := A081;
  _wTegla[8,2] := A082;
  _wTegla[8,3] := A083;
  _wTegla[8,4] := A084;
  _wTegla[8,5] := A085;
  _wTegla[8,6] := A086;
  _wTegla[8,7] := A087;
  _wTegla[8,8] := A088;
  _wTegla[8,9] := A089;

  _wTegla[9,1] := A091;
  _wTegla[9,2] := A092;
  _wTegla[9,3] := A093;
  _wTegla[9,4] := A094;
  _wTegla[9,5] := A095;
  _wTegla[9,6] := A096;
  _wTegla[9,7] := A097;
  _wTegla[9,8] := A098;
  _wTegla[9,9] := A099;

  _wTegla[10,1] := A101;
  _wTegla[10,2] := A102;
  _wTegla[10,3] := A103;
  _wTegla[10,4] := A104;
  _wTegla[10,5] := A105;
  _wTegla[10,6] := A106;
  _wTegla[10,7] := A107;
  _wTegla[10,8] := A108;
  _wTegla[10,9] := A109;

  _wTegla[11,1] := A111;
  _wTegla[11,2] := A112;
  _wTegla[11,3] := A113;
  _wTegla[11,4] := A114;
  _wTegla[11,5] := A115;
  _wTegla[11,6] := A116;
  _wTegla[11,7] := A117;
  _wTegla[11,8] := A118;
  _wTegla[11,9] := A119;

  _wTegla[12,1] := A121;
  _wTegla[12,2] := A122;
  _wTegla[12,3] := A123;
  _wTegla[12,4] := A124;
  _wTegla[12,5] := A125;
  _wTegla[12,6] := A126;
  _wTegla[12,7] := A127;
  _wTegla[12,8] := A128;
  _wTegla[12,9] := A129;

  _wTegla[13,1] := A131;
  _wTegla[13,2] := A132;
  _wTegla[13,3] := A133;
  _wTegla[13,4] := A134;
  _wTegla[13,5] := A135;
  _wTegla[13,6] := A136;
  _wTegla[13,7] := A137;
  _wTegla[13,8] := A138;
  _wTegla[13,9] := A139;

  _wTegla[14,1] := A141;
  _wTegla[14,2] := A142;
  _wTegla[14,3] := A143;
  _wTegla[14,4] := A144;
  _wTegla[14,5] := A145;
  _wTegla[14,6] := A146;
  _wTegla[14,7] := A147;
  _wTegla[14,8] := A148;
  _wTegla[14,9] := A149;

  _wTegla[15,1] := A151;
  _wTegla[15,2] := A152;
  _wTegla[15,3] := A153;
  _wTegla[15,4] := A154;
  _wTegla[15,5] := A155;
  _wTegla[15,6] := A156;
  _wTegla[15,7] := A157;
  _wTegla[15,8] := A158;
  _wTegla[15,9] := A159;

  _wTegla[16,1] := A161;
  _wTegla[16,2] := A162;
  _wTegla[16,3] := A163;
  _wTegla[16,4] := A164;
  _wTegla[16,5] := A165;
  _wTegla[16,6] := A166;
  _wTegla[16,7] := A167;
  _wTegla[16,8] := A168;
  _wTegla[16,9] := A169;

  _wTegla[17,1] := A171;
  _wTegla[17,2] := A172;
  _wTegla[17,3] := A173;
  _wTegla[17,4] := A174;
  _wTegla[17,5] := A175;
  _wTegla[17,6] := A176;
  _wTegla[17,7] := A177;
  _wTegla[17,8] := A178;
  _wTegla[17,9] := A179;

  _wTegla[18,1] := A181;
  _wTegla[18,2] := A182;
  _wTegla[18,3] := A183;
  _wTegla[18,4] := A184;
  _wTegla[18,5] := A185;
  _wTegla[18,6] := A186;
  _wTegla[18,7] := A187;
  _wTegla[18,8] := A188;
  _wTegla[18,9] := A189;

  _wTegla[19,1] := A191;
  _wTegla[19,2] := A192;
  _wTegla[19,3] := A193;
  _wTegla[19,4] := A194;
  _wTegla[19,5] := A195;
  _wTegla[19,6] := A196;
  _wTegla[19,7] := A197;
  _wTegla[19,8] := A198;
  _wTegla[19,9] := A199;

  _wTegla[20,1] := A201;
  _wTegla[20,2] := A202;
  _wTegla[20,3] := A203;
  _wTegla[20,4] := A204;
  _wTegla[20,5] := A205;
  _wTegla[20,6] := A206;
  _wTegla[20,7] := A207;
  _wTegla[20,8] := A208;
  _wTegla[20,9] := A209;

  _wtegla[21,1] := A211;
  _wtegla[21,2] := A212;
  _wtegla[21,3] := A213;
  _wtegla[21,4] := A214;
  _wtegla[21,5] := A215;
  _wtegla[21,6] := A216;
  _wtegla[21,7] := A217;
  _wtegla[21,8] := A218;
  _wtegla[21,9] := A219;

  _wtegla[22,1] := A221;
  _wtegla[22,2] := A222;
  _wtegla[22,3] := A223;
  _wtegla[22,4] := A224;
  _wtegla[22,5] := A225;
  _wtegla[22,6] := A226;
  _wtegla[22,7] := A227;
  _wtegla[22,8] := A228;
  _wtegla[22,9] := A229;

  _wtegla[23,1] := A231;
  _wtegla[23,2] := A232;
  _wtegla[23,3] := A233;
  _wtegla[23,4] := A234;
  _wtegla[23,5] := A235;
  _wtegla[23,6] := A236;
  _wtegla[23,7] := A237;
  _wtegla[23,8] := A238;
  _wtegla[23,9] := A239;

  _wtegla[24,1] := A241;
  _wtegla[24,2] := A242;
  _wtegla[24,3] := A243;
  _wtegla[24,4] := A244;
  _wtegla[24,5] := A245;
  _wtegla[24,6] := A246;
  _wtegla[24,7] := A247;
  _wtegla[24,8] := A248;
  _wtegla[24,9] := A249;

  _wtegla[25,1] := A251;
  _wtegla[25,2] := A252;
  _wtegla[25,3] := A253;
  _wtegla[25,4] := A254;
  _wtegla[25,5] := A255;
  _wtegla[25,6] := A256;
  _wtegla[25,7] := A257;
  _wtegla[25,8] := A258;
  _wtegla[25,9] := A259;

  _wtegla[26,1] := A261;
  _wtegla[26,2] := A262;
  _wtegla[26,3] := A263;
  _wtegla[26,4] := A264;
  _wtegla[26,5] := A265;
  _wtegla[26,6] := A266;
  _wtegla[26,7] := A267;
  _wtegla[26,8] := A268;
  _wtegla[26,9] := A269;

  _wtegla[27,1] := A271;
  _wtegla[27,2] := A272;
  _wtegla[27,3] := A273;
  _wtegla[27,4] := A274;
  _wtegla[27,5] := A275;
  _wtegla[27,6] := A276;
  _wtegla[27,7] := A277;
  _wtegla[27,8] := A278;
  _wtegla[27,9] := A279;

  _wtegla[28,1] := A281;
  _wtegla[28,2] := A282;
  _wtegla[28,3] := A283;
  _wtegla[28,4] := A284;
  _wtegla[28,5] := A285;
  _wtegla[28,6] := A286;
  _wtegla[28,7] := A287;
  _wtegla[28,8] := A288;
  _wtegla[28,9] := A289;


  _itgomb[0]  := IG0;
  _itgomb[1]  := IG1;
  _itgomb[2]  := IG2;
  _itgomb[3]  := IG3;
  _itgomb[4]  := IG4;
  _itgomb[5]  := IG5;
  _itgomb[6]  := IG6;
  _itgomb[7]  := IG7;
  _itgomb[8]  := IG8;
  _itgomb[9] :=  IG9;
  _itgomb[10] := IG10;
  _itgomb[11] := IG11;
  _itgomb[12] := IG12;
  _itgomb[13] := IG13;
  _itgomb[14] := IG14;
  _itgomb[15] := IG15;
  _itgomb[16] := IG16;
  _itgomb[17] := IG17;
  _itgomb[18] := IG18;
  _itgomb[19] := IG19;
  _itgomb[20] := IG20;
  _itgomb[21] := IG21;
  _itgomb[22] := IG22;
  _itgomb[23] := IG23;
  _itgomb[24] := IG24;
  _itgomb[25] := IG25;
  _itgomb[26] := IG26;
  _itgomb[27] := IG27;
  _itgomb[28] := IG28;



end;


// =============================================================================
     procedure TALAPLAP.A011MouseMove(Sender: TObject; Shift: TShiftState; X,
                                                                   Y: Integer);
// =============================================================================

var _dispFuggvenyString: string;

begin
  _aktTegla := TPanel(sender);
  _teglanev := _akttegla.name;
  SetKoord(_teglanev);

  _dispfuggvenystring := _wFuggveny[_aktsor,_aktoszlop];
  FuggvenyShow.Caption := _dispFuggvenystring;

  if _teglanev=_utteglanev then exit;
  _utteglanev := _teglanev;

  if not _signing then exit;
  if _zold then exit;

  if (_aktoszlop<>_startoszlop) or (_aktsor<_startsor) then exit;
  _endsor := _aktsor;
  SetjeloloKoord(clFuchsia);
end;

// =============================================================================
   procedure TALAPLAP.OTPGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
                                                                   Y: Integer);
// =============================================================================

var _tag: integer;
begin
  _tag := TBitbtn(Sender).Tag;
  if _tag=255 then exit;
  _aktUrl := _urlnevek[_tag];
  UrlShow.caption := _akturl;
end;

// =============================================================================
     procedure TALAPLAP.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
                                                                   Y: Integer);
// =============================================================================

begin
  FuggvenyShow.Caption := '';
  UrlShow.Caption := '';
end;

// =============================================================================
              procedure TALAPLAP.BitBtn3Click(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
    procedure TALAPLAP.A011MouseDown(Sender: TObject; Button: TMouseButton;
                                           Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin


  if _double then
    begin
      _double := false;
      exit;
     end;

  if _zold then exit;

  _teglanev := TPanel(sender).Name;
  SetKoord(_teglanev);

  // Ha nincs lenyomva a ctrl billentyü:
  if shift<>[ssCtrl..ssLeft] then
    begin
      // Ha nincs éppen jelölés közben:
      if not _signing then
        begin
          _aktfuggvenystring := _wFuggveny[_aktsor,_aktoszlop];

          // Kézi bevitel következik (piros téglakeret !)
          _manual      := true;

          // A elsõ és utolsó tégla is ez:
          _startoszlop := _aktoszlop;
          _endoszlop   := _aktoszlop;
          _startsor    := _aktsor;
          _endsor      := _aktsor;

          // Piros keretezés a téglának:
          Setjelolokoord(clRed);

          // Ha ez függvény, akkor függvénykezelés:
     //     if _aktfuggvenystring<>'' then FuggvenyKezelo(_aktsor,_aktoszlop);

          // A kurzorok kézi kezelése a hidediten keresztül:
          ActiveControl := HideEdit;
          exit;
        end;

      // Itt jelölés közben nyomta a bal-billentyüt:

      JeloloPanel.Color := clLime;
      _zold := True;
      _signing := false;
      ZoldRutin;
      exit;
    end;

  // Itt a control billentyü mellett balegér gomb:

  // Ha már megy a jelölés akkor itt kilép
  if _signing then exit;

  // Tehát indul a kijelölés

  _manual      := False;
  _signing     := True;

  _startoszlop := _aktoszlop;
  _endOszlop   := _aktoszlop;
  _startSor    := _aktsor;
  _endsor      := _aktsor;

  SetJeloloKoord(clFuchsia);
end;

// =============================================================================
            procedure TAlaplap.SetJeloloKoord(_szin: TCOlor);
// =============================================================================


begin
  _jLeft   := 3 + 88*(_startoszlop-1);
  _jTop    := 103+ 22*(_startSor-1);
  _jHeight := 22*(_endSor-_startSor+1)+3;
  _jWidth  := 88*(_endOszlop-_startOszlop+1) +3;

  with JELOLOPANEL do
    begin
      Top     := _jTop;
      Left    := _jLeft;
      Width   := _jWidth;
      Height  := _jHeight;
      COlor   := _szin;
      Visible := True;
    end;
end;

// =============================================================================
         procedure TaLAPLAP.FuggvenyKezelo(_fsor,_foszlop: integer);
// =============================================================================

var _oke: integer;

begin
  _getfx := 25 + trunc(86*_foszlop);
  _getfy := trunc(29*_fSor)-25;

  GetteglaAdatok(_fsor,_foszlop);
  _oke := GetFuggveny.Showmodal;

  if _oke =1 then
    begin
      AlapTeglaba(_fsor,_foszlop);
      LapFelfrissito;
    end;
end;

// =============================================================================
         procedure TaLAPLAP.GetTeglaAdatok(_xsor,_xoszlop: integer);
// =============================================================================


begin
  _aktErtekstring := _Wertek[_xsor,_xoszlop];
  _aktfuggvenystring := _wFuggveny[_xsor,_xoszlop];
  _aktbetuszin := _wBetuszin[_xsor,_xoszlop];
  _aktHatterszin := _wHatterSzin[_xsor,_xoszlop];
end;


// =============================================================================
     procedure TALAPLAP.HIDEEDITKeyDown(Sender: TObject; var Key: Word;
                                                        Shift: TShiftState);
// =============================================================================

var _bill: integer;


begin
   _bill := ord(key);
  if not _manual then exit;

  if (_bill>95) and (_bill<106) then _bill := _bill-48;
  if (_bill=110) or (_bill=44) then _bill := 46;

  case _bill of
    37: begin    // balra

          if _startOszlop = 1 then exit;
          dec(_startOszlop);
          dec(_endoszlop);
          SetjeloloKoord(clRed);
        end;

    38: begin  // felfelé
          if _startSor = 1 then exit;
          if (_startsor=3) and (_startoszlop>6) then exit;
          if (_startsor=_dnemDarab) and (_startOszlop>6) then exit;
          dec(_startSor);
          dec(_endSor);
          SetjeloloKoord(clRed);
        end;

    39: begin    // jobbra
          if _startOszlop = 9 then exit;
          if (_startoszlop=6) and (_startsor<3) then exit;
          if (_startOszlop=6) and (_startsor=20) then exit;
          inc(_startOszlop);
          inc(_endoszlop);
          SetjeloloKoord(clRed);
        end;

    40: begin    // lefelé
          if _startSor = _DNEMDARAB then exit;
          if (_startsor=19) and (_startoszlop>6) then exit;
          inc(_startSor);
          inc(_endSor);
          SetjeloloKoord(clRed);
        end;

    27: begin
          _manual := False;
          JeloloPanel.Visible := False;
          exit;
         end;

     13: begin
           if _startoszlop=4 then exit;
           GetTeglaadatok(_startsor,_startoszlop);
           if _aktfuggvenystring<>'' then
             begin
               FuggvenyKezelo(_startsor,_startoszlop);
               Exit;
             end;
           Bignumedit.Text := _aktertekstring;
           BignumPuffan;
           exit;
         end;
    end;

  _aktfuggvenystring := _wFuggveny[_startsor,_startoszlop];
  if _aktfuggvenystring<>'' then
    begin
      Fuggvenyshow.Caption := _aktfuggvenystring;
      FuggvenyShow.Refresh;
      Fuggvenyshow.Repaint;
    end;
end;

// =============================================================================
      procedure TALAPLAP.BIGNUMEDITKeyDown(Sender: TObject; var Key: Word;
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
  _aktcsoport := 0;
  _aktertekstring := Form1.VesszobolPont(bignumedit.text);
  Form1.ErtekControl;
  AlapTeglaba(_startsor,_startoszlop);
  LapfelFrissito;
  if _startsor<_dnemdarab then
    begin
      inc(_startsor);
      inc(_endsor);
      Setjelolokoord(clRed);
    end;

  ActiveControl := Hideedit;
end;

// =============================================================================
                procedure TALAPLAP.IG0Click(Sender: TObject);
// =============================================================================

var _urlss,_oke: integer;

begin
   _urlss := TBitbtn(sender).Tag;
   if _urlss=255 then exit;

   if _nyitottWeblap then
    begin
      if _aktweblapszam<>_urlSs then  ShowMessage('EGY WEBLAP NYITVA VAN. ELÖBB AZT BE KELL ZÁRNI');
      _oke := InternetBongeszo.Showmodal;

    end else
    begin
      _aktUrl := _urlnevek[_urlss];
      _aktweblapszam := _urlss;

     _oke := InternetBongeszo.Showmodal;
    end;
   if _oke=1 then
        begin
          _NyitottWebLap := False; // oke=1 bezárva
          _aktweblapszam := 255;
        end;
end;

// =============================================================================
  procedure TALAPLAP.INTERNETPANELMouseMove(Sender: TObject; Shift: TShiftState;
                                                                X, Y: Integer);
// =============================================================================

begin
  FmbillClear;
  if _nyitottweblap then Internetpanel.Cursor := crHandPoint
  else Internetpanel.Cursor := crNo;
end;

// =============================================================================
           procedure TALAPLAP.INTERNETPANELClick(Sender: TObject);
// =============================================================================

var _bezart: integer;

begin
  if _nyitottWeblap then
    begin
      _bezart := InternetBongeszo.ShowModal;
      if _bezart=1 then
        begin
          _NyitottWebLap := False; // oke=1 bezárva
          _aktweblapszam := 255;
        end;
    end;
end;


// =============================================================================
         procedure TALAPLAP.SZETKULDOGOMBEnter(Sender: TObject);
// =============================================================================

begin
  with TBitbtn(sender).Font do
    begin
      Color := clNavy;
      Style := [fsBold,fsItalic];
    end;
end;

// =============================================================================
            procedure TALAPLAP.SZETKULDOGOMBExit(Sender: TObject);
// =============================================================================

begin
  with TBitbtn(sender).Font do
    begin
      Color := clBlack;
      Style := [fsItalic];
    end;
end;

// =============================================================================
        procedure TALAPLAP.SZETKULDOGOMBMouseMove(Sender: TObject;
                                           Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  ActiveControl := TBitbtn(sender);
end;


// =============================================================================
                          procedure Talaplap.BignumPuffan;
// =============================================================================

begin

  with BignumPanel do
    begin
      Top := _jTop-19;
      Left := _jleft+100;
      Visible := true
    end;
  ActiveControl := Bignumedit;
end;


// =============================================================================
           procedure TALAPLAP.INTERNETTMKGOMBClick(Sender: TObject);
// =============================================================================

var _valt: integer;

begin
  _valt := InternetTmkForm.showModal;
  if _valt=1 then LapfelFrissito;
end;

// =============================================================================
                        procedure TAlaplap.Zoldrutin;
// =============================================================================

begin

  with ZoldmenuPanel do
    begin
      Top := _jtop - 20;
      Left := _jleft + 100;
      Visible := true;
    end;
  ActiveControl := zmlehuzogomb;
end;

// =============================================================================
            procedure TALAPLAP.ZMLEHUZOGOMBClick(Sender: TObject);
// =============================================================================

begin
  _arfdataValtozott := true;
  zoldmenupanel.Visible := False;
  JeloloPanel.Visible   := False;

  _signing := False;
  _zold    := False;
  _double  := False;

  GetTeglaAdatok(_startsor,_startoszlop);

  _aktsor := _startsor + 1;
  _aktoszlop := _startoszlop;

  while _aktsor<=_endsor do
    begin
      _aktTegla := _wTegla[_aktsor,_aktoszlop];
      _akttegla.Color := clLime;
      _akttegla.repaint;
      _wertek[_aktsor,_aktoszlop] := _aktertekstring;
      _wFuggveny[_aktsor,_aktoszlop] := _aktFuggvenyString;
      _wBetuszin[_aktsor,_aktoszlop] := _aktBetuszin;
      _wHatterSzin[_aktsor,_aktoszlop] := _aktHatterszin;
      sleep(50);
      inc(_aktsor);
    end;

  Lapfelfrissito;
end;

// =============================================================================
            procedure TALAPLAP.ZMMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  _signing := False;
  _zold := False;
  _double := False;
  ZoldMenuPanel.Visible := False;
  JeloloPanel.Visible := False;
end;

// =============================================================================
          procedure TAlaplap.Alapteglaba(_zsor,_soszlop: integer);
// =============================================================================

begin
  _wertek[_zsor,_soszlop] := _aktertekstring;
  _wFuggveny[_zsor,_soszlop] := _aktFuggvenyString;
  _wBetuszin[_zsor,_soszlop] := _aktBetuszin;
  _wHatterSzin[_zsor,_soszlop] := _aktHatterszin;
end;

// =============================================================================
              procedure TALAPLAP.A011DblClick(Sender: TObject);
// =============================================================================

begin
  if _signing then exit;
  if _aktoszlop=2 then exit;
  _teglanev := TPanel(Sender).name;

  SetKoord(_teglanev);
  _aktfuggvenystring := _wFuggveny[_aktsor,_aktoszlop];

  FuggvenyShow.Caption := _aktFuggvenystring;

  _manual      := True;
  _startOszlop := _aktoszlop;
  _startSor    := _aktsor;
  _endOszlop   := _aktOszlop;
  _endSor      := _aktsor;

  SetjeloloKoord(clred);
  FuggvenyKezelo(_aktsor,_aktoszlop);

  ActiveControl := HideEdit;
end;


// =============================================================================
           procedure TALAPLAP.SZETKULDOGOMBClick(Sender: TObject);
// =============================================================================

begin
  if not Form1.Vegcontrol then exit;
  AdatSzetkuldes.Showmodal;
end;


// =============================================================================
        procedure TALAPLAP.csoporttmkgombMouseMove(Sender: TObject;
                                              Shift: TShiftState; X,Y: Integer);
// =============================================================================

var _aktbill: TPanel;
    _tag: integer;

begin
  FmBillClear;
  _tag := Tpanel(Sender).Tag;
  _aktbill := _fmBill[_tag];
  _aktbill.Font.Style := [fsBold];
  _aktbill.Color := $ffb0ff;
end;

// =============================================================================
                    procedure  TalapLap.FmbillClear;
// =============================================================================


var _aktbill : TPanel;
    i: integer;

begin
  for i := 1 to 4 do
    begin
      _aktbill := _fmbill[i];
      _aktbill.Font.Style := [];
      _aktbill.Color := clBtnFace;
    end;
end;

// =============================================================================
               procedure TALAPLAP.KILEPESGOMBClick(Sender: TObject);
// =============================================================================

begin
  ArfdataIras.showmodal;
  Application.Terminate;
end;

// =============================================================================
         procedure TALAPLAP.csoporttmkgombClick(Sender: TObject);
// =============================================================================

var _ok: integer;

begin
  _ok := CsoportDisplay.Showmodal;
  if _ok>1 then
    begin
      Modalresult := 2;
      exit;
    end;
end;

// =============================================================================
     procedure TALAPLAP.Panel202MouseMove(Sender: TObject; Shift: TShiftState;
                                                                 X, Y: Integer);
// =============================================================================

begin
  FmbillClear;
end;



// =============================================================================
                    procedure TALAPLAP.SetKoord(_nn: string);
// =============================================================================



begin
  _aktsor := strtoint(midstr(_nn,2,2));
  _aktoszlop := ord(_nn[4])-48;
  if _aktoszlop>9 then _aktoszlop := 10;

  _kpLeft := 8  + 88*(_aktoszlop-1);
  _kpTop  := 106 + 22*(_aktSor-1);
  _pleft := _kpleft - 5;
  _pTop  := _kpTop  - 3;
end;
















































end.
