unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, StrUtils;

type
  TCIMLETSETUPFORM = class(TForm)

    Panel1: TPanel;
    Panel39: TPanel;

    // ================ name panels ========================

    NMA: TPanel;
    NMB: TPanel;
    NMC: TPanel;
    NMD: TPanel;
    NME: TPanel;
    NMF: TPanel;
    NMG: TPanel;
    NMH: TPanel;
    NMI: TPanel;
    NMJ: TPanel;
    NMK: TPanel;
    NML: TPanel;
    NMM: TPanel;
    NMN: TPanel;
    NMO: TPanel;
    NMP: TPanel;
    NMQ: TPanel;
    NMR: TPanel;
    NMS: TPanel;
    NMT: TPanel;
    NMU: TPanel;

    // ==================== rate columns ===========================

    RUD1: TPanel;
    RUD2: TPanel;
    RUD3: TPanel;
    RUD4: TPanel;
    RUD5: TPanel;
    RUD6: TPanel;
    RUD7: TPanel;
    RUD8: TPanel;
    RUD9: TPanel;
    RUD10: TPanel;
    RUD11: TPanel;
    RUD12: TPanel;
    RUD13: TPanel;
    RUD14: TPanel;



    // =================== value panels =========================

    C1: TPanel;
    C2: TPanel;
    C3: TPanel;
    C4: TPanel;
    C5: TPanel;
    C6: TPanel;
    C7: TPanel;
    C8: TPanel;
    C9: TPanel;
   C10: TPanel;
   C11: TPanel;
   C12: TPanel;
   C13: TPanel;
   C14: TPanel;

    VNA: TPanel;
    VNB: TPanel;
    VNC: TPanel;
    VND: TPanel;
    VNE: TPanel;
    VNF: TPanel;
    VNG: TPanel;
    VNH: TPanel;
    VNI: TPanel;
    VNJ: TPanel;
    VNK: TPanel;
    VNL: TPanel;
    VNM: TPanel;
    VNN: TPanel;
    VNO: TPanel;
    VNP: TPanel;
    VNQ: TPanel;
    VNR: TPanel;
    VNS: TPanel;
    VNT: TPanel;
    VNU: TPanel;

    CHA1: TCheckBox;
    CHA2: TCheckBox;
    CHA3: TCheckBox;
    CHA4: TCheckBox;
    CHA5: TCheckBox;
    CHA6: TCheckBox;
    CHA7: TCheckBox;
    CHA8: TCheckBox;
    CHA9: TCheckBox;
   CHA10: TCheckBox;
   CHA11: TCheckBox;
   CHA12: TCheckBox;
   CHA13: TCheckBox;
   CHA14: TCheckBox;

    CHB1: TcheckBox;
    CHB2: TCheckBox;
    CHB3: TCheckBox;
    CHB4: TCheckBox;
    CHB5: TCheckBox;
    CHB6: TCheckBox;
    CHB7: TCheckBox;
    CHB8: TCheckBox;
    CHB9: TCheckBox;
   CHB10: TCheckBox;
   CHB11: TCheckBox;
   CHB12: TCheckBox;
   CHB13: TCheckBox;
   CHB14: TCheckBox;

    CHC1: TcheckBox;
    CHC2: TCheckBox;
    CHC3: TCheckBox;
    CHC4: TCheckBox;
    CHC5: TCheckBox;
    CHC6: TCheckBox;
    CHC7: TCheckBox;
    CHC8: TCheckBox;
    CHC9: TCheckBox;
   CHC10: TCheckBox;
   CHC11: TCheckBox;
   CHC12: TCheckBox;
   CHC13: TCheckBox;
   CHC14: TCheckBox;

    CHD1: TcheckBox;
    CHD2: TCheckBox;
    CHD3: TCheckBox;
    CHD4: TCheckBox;
    CHD5: TCheckBox;
    CHD6: TCheckBox;
    CHD7: TCheckBox;
    CHD8: TCheckBox;
    CHD9: TCheckBox;
   CHD10: TCheckBox;
   CHD11: TCheckBox;
   CHD12: TCheckBox;
   CHD13: TCheckBox;
   CHD14: TCheckBox;

    CHE1: TcheckBox;
    CHE2: TCheckBox;
    CHE3: TCheckBox;
    CHE4: TCheckBox;
    CHE5: TCheckBox;
    CHE6: TCheckBox;
    CHE7: TCheckBox;
    CHE8: TCheckBox;
    CHE9: TCheckBox;
   CHE10: TCheckBox;
   CHE11: TCheckBox;
   CHE12: TCheckBox;
   CHE13: TCheckBox;
   CHE14: TCheckBox;

    CHF1: TcheckBox;
    CHF2: TCheckBox;
    CHF3: TCheckBox;
    CHF4: TCheckBox;
    CHF5: TCheckBox;
    CHF6: TCheckBox;
    CHF7: TCheckBox;
    CHF8: TCheckBox;
    CHF9: TCheckBox;
   CHF10: TCheckBox;
   CHF11: TCheckBox;
   CHF12: TCheckBox;
   CHF13: TCheckBox;
   CHF14: TCheckBox;

    CHG1: TcheckBox;
    CHG2: TCheckBox;
    CHG3: TCheckBox;
    CHG4: TCheckBox;
    CHG5: TCheckBox;
    CHG6: TCheckBox;
    CHG7: TCheckBox;
    CHG8: TCheckBox;
    CHG9: TCheckBox;
   CHG10: TCheckBox;
   CHG11: TCheckBox;
   CHG12: TCheckBox;
   CHG13: TCheckBox;
   CHG14: TCheckBox;

    CHH1: TcheckBox;
    CHH2: TCheckBox;
    CHH3: TCheckBox;
    CHH4: TCheckBox;
    CHH5: TCheckBox;
    CHH6: TCheckBox;
    CHH7: TCheckBox;
    CHH8: TCheckBox;
    CHH9: TCheckBox;
   CHH10: TCheckBox;
   CHH11: TCheckBox;
   CHH12: TCheckBox;
   CHH13: TCheckBox;
   CHH14: TCheckBox;

    CHI1: TcheckBox;
    CHI2: TCheckBox;
    CHI3: TCheckBox;
    CHI4: TCheckBox;
    CHI5: TCheckBox;
    CHI6: TCheckBox;
    CHI7: TCheckBox;
    CHI8: TCheckBox;
    CHI9: TCheckBox;
   CHI10: TCheckBox;
   CHI11: TCheckBox;
   CHI12: TCheckBox;
   CHI13: TCheckBox;
   CHI14: TCheckBox;

    CHJ1: TcheckBox;
    CHJ2: TCheckBox;
    CHJ3: TCheckBox;
    CHJ4: TCheckBox;
    CHJ5: TCheckBox;
    CHJ6: TCheckBox;
    CHJ7: TCheckBox;
    CHJ8: TCheckBox;
    CHJ9: TCheckBox;
   CHJ10: TCheckBox;
   CHJ11: TCheckBox;
   CHJ12: TCheckBox;
   CHJ13: TCheckBox;
   CHJ14: TCheckBox;

    CHK1: TcheckBox;
    CHK2: TCheckBox;
    CHK3: TCheckBox;
    CHK4: TCheckBox;
    CHK5: TCheckBox;
    CHK6: TCheckBox;
    CHK7: TCheckBox;
    CHK8: TCheckBox;
    CHK9: TCheckBox;
   CHK10: TCheckBox;
   CHK11: TCheckBox;
   CHK12: TCheckBox;
   CHK13: TCheckBox;
   CHK14: TCheckBox;

    CHL1: TcheckBox;
    CHL2: TCheckBox;
    CHL3: TCheckBox;
    CHL4: TCheckBox;
    CHL5: TCheckBox;
    CHL6: TCheckBox;
    CHL7: TCheckBox;
    CHL8: TCheckBox;
    CHL9: TCheckBox;
   CHL10: TCheckBox;
   CHL11: TCheckBox;
   CHL12: TCheckBox;
   CHL13: TCheckBox;
   CHL14: TCheckBox;

    CHM1: TcheckBox;
    CHM2: TCheckBox;
    CHM3: TCheckBox;
    CHM4: TCheckBox;
    CHM5: TCheckBox;
    CHM6: TCheckBox;
    CHM7: TCheckBox;
    CHM8: TCheckBox;
    CHM9: TCheckBox;
   CHM10: TCheckBox;
   CHM11: TCheckBox;
   CHM12: TCheckBox;
   CHM13: TCheckBox;
   CHM14: TCheckBox;

    CHN1: TcheckBox;
    CHN2: TCheckBox;
    CHN3: TCheckBox;
    CHN4: TCheckBox;
    CHN5: TCheckBox;
    CHN6: TCheckBox;
    CHN7: TCheckBox;
    CHN8: TCheckBox;
    CHN9: TCheckBox;
   CHN10: TCheckBox;
   CHN11: TCheckBox;
   CHN12: TCheckBox;
   CHN13: TCheckBox;
   CHN14: TCheckBox;

    CHO1: TcheckBox;
    CHO2: TCheckBox;
    CHO3: TCheckBox;
    CHO4: TCheckBox;
    CHO5: TCheckBox;
    CHO6: TCheckBox;
    CHO7: TCheckBox;
    CHO8: TCheckBox;
    CHO9: TCheckBox;
   CHO10: TCheckBox;
   CHO11: TCheckBox;
   CHO12: TCheckBox;
   CHO13: TCheckBox;
   CHO14: TCheckBox;

    CHP1: TcheckBox;
    CHP2: TCheckBox;
    CHP3: TCheckBox;
    CHP4: TCheckBox;
    CHP5: TCheckBox;
    CHP6: TCheckBox;
    CHP7: TCheckBox;
    CHP8: TCheckBox;
    CHP9: TCheckBox;
   CHP10: TCheckBox;
   CHP11: TCheckBox;
   CHP12: TCheckBox;
   CHP13: TCheckBox;
   CHP14: TCheckBox;

    CHQ1: TcheckBox;
    CHQ2: TCheckBox;
    CHQ3: TCheckBox;
    CHQ4: TCheckBox;
    CHQ5: TCheckBox;
    CHQ6: TCheckBox;
    CHQ7: TCheckBox;
    CHQ8: TCheckBox;
    CHQ9: TCheckBox;
   CHQ10: TCheckBox;
   CHQ11: TCheckBox;
   CHQ12: TCheckBox;
   CHQ13: TCheckBox;
   CHQ14: TCheckBox;

    CHR1: TcheckBox;
    CHR2: TCheckBox;
    CHR3: TCheckBox;
    CHR4: TCheckBox;
    CHR5: TCheckBox;
    CHR6: TCheckBox;
    CHR7: TCheckBox;
    CHR8: TCheckBox;
    CHR9: TCheckBox;
   CHR10: TCheckBox;
   CHR11: TCheckBox;
   CHR12: TCheckBox;
   CHR13: TCheckBox;
   CHR14: TCheckBox;

    CHS1: TcheckBox;
    CHS2: TCheckBox;
    CHS3: TCheckBox;
    CHS4: TCheckBox;
    CHS5: TCheckBox;
    CHS6: TCheckBox;
    CHS7: TCheckBox;
    CHS8: TCheckBox;
    CHS9: TCheckBox;
   CHS10: TCheckBox;
   CHS11: TCheckBox;
   CHS12: TCheckBox;
   CHS13: TCheckBox;
   CHS14: TCheckBox;

    CHT1: TcheckBox;
    CHT2: TCheckBox;
    CHT3: TCheckBox;
    CHT4: TCheckBox;
    CHT5: TCheckBox;
    CHT6: TCheckBox;
    CHT7: TCheckBox;
    CHT8: TCheckBox;
    CHT9: TCheckBox;
   CHT10: TCheckBox;
   CHT11: TCheckBox;
   CHT12: TCheckBox;
   CHT13: TCheckBox;
   CHT14: TCheckBox;

    CHU1: TcheckBox;
    CHU2: TCheckBox;
    CHU3: TCheckBox;
    CHU4: TCheckBox;
    CHU5: TCheckBox;
    CHU6: TCheckBox;
    CHU7: TCheckBox;
    CHU8: TCheckBox;
    CHU9: TCheckBox;
   CHU10: TCheckBox;
   CHU11: TCheckBox;
   CHU12: TCheckBox;
   CHU13: TCheckBox;
   CHU14: TCheckBox;

       SetupOkeGomb: TBitBtn;
    SetupCancelGomb: TBitBtn;

    VNV: TPanel;
    NMV: TPanel;

    CHV1: TCheckBox;
    CHV2: TCheckBox;
    CHV3: TCheckBox;
    CHV4: TCheckBox;
    CHV5: TCheckBox;
    CHV6: TCheckBox;
    CHV7: TCheckBox;
    CHV8: TCheckBox;
    CHV9: TCheckBox;
    CHV10: TCheckBox;
    CHV11: TCheckBox;
    CHV12: TCheckBox;
    CHV13: TCheckBox;
    CHV14: TCheckBox;
    VNW: TPanel;
    NMW: TPanel;
    CHW1: TCheckBox;
    CHW2: TCheckBox;
    CHW3: TCheckBox;
    CHW4: TCheckBox;
    CHW5: TCheckBox;
    CHW6: TCheckBox;
    CHW7: TCheckBox;
    CHW8: TCheckBox;
    CHW9: TCheckBox;
    CHW10: TCheckBox;
    CHW11: TCheckBox;
    CHW12: TCheckBox;
    CHW13: TCheckBox;
    CHW14: TCheckBox;
    Shape1: TShape;
    VNX: TPanel;
    CHX1: TCheckBox;
    NMX: TPanel;
    CHX2: TCheckBox;
    CHX3: TCheckBox;
    CHX4: TCheckBox;
    CHX5: TCheckBox;
    CHX6: TCheckBox;
    CHX7: TCheckBox;
    CHX8: TCheckBox;
    CHX9: TCheckBox;
    CHX10: TCheckBox;
    CHX11: TCheckBox;
    CHX12: TCheckBox;
    CHX13: TCheckBox;
    CHX14: TCheckBox;
    CHY1: TCheckBox;
    CHZ1: TCheckBox;
    CHAA1: TCheckBox;
    NMY: TPanel;
    NMZ: TPanel;
    NMAA: TPanel;
    VNAA: TPanel;
    VNZ: TPanel;
    VNY: TPanel;
    CHY2: TCheckBox;
    CHZ2: TCheckBox;
    CHAA2: TCheckBox;
    CHY3: TCheckBox;
    CHZ3: TCheckBox;
    CHAA3: TCheckBox;
    CHY4: TCheckBox;
    CHZ4: TCheckBox;
    CHAA4: TCheckBox;
    CHY5: TCheckBox;
    CHZ5: TCheckBox;
    CheckBox15: TCheckBox;
    CHAA5: TCheckBox;
    CHY6: TCheckBox;
    CHZ6: TCheckBox;
    CHAA6: TCheckBox;
    CHY7: TCheckBox;
    CHZ7: TCheckBox;
    CheckBox22: TCheckBox;
    CHAA7: TCheckBox;
    CHY8: TCheckBox;
    CHZ8: TCheckBox;
    CHAA8: TCheckBox;
    CHY9: TCheckBox;
    CHZ9: TCheckBox;
    CheckBox29: TCheckBox;
    CHAA9: TCheckBox;
    CHY10: TCheckBox;
    CHZ10: TCheckBox;
    CHAA10: TCheckBox;
    CHY11: TCheckBox;
    CHZ11: TCheckBox;
    CHAA11: TCheckBox;
    CHY12: TCheckBox;
    CHZ12: TCheckBox;
    CHAA12: TCheckBox;
    CHY13: TCheckBox;
    CHZ13: TCheckBox;
    CHAA13: TCheckBox;
    CHY14: TCheckBox;
    CHZ14: TCheckBox;
    CHAA14: TCheckBox;

    procedure Cha1Exit(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SetupBeolvas;
    procedure SetupCancelGombClick(Sender: TObject);
    procedure SetupOkeGombClick(Sender: TObject);
    function Dnemscan(_dn: string): byte;
    procedure C1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);

    procedure Panel1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure RUD1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CimletSetupForm: TCimletSetupForm;

  _aktBox : TCheckBox;

  Cbox: array[1..27,1..14] of TcheckBox;

   RovnevPanel: array[1..27] of Tpanel;
  LongNevPanel: array[1..27] of TPanel;

   _cimDnem: array[1..27] of String;
   _cimDnev: array[1..27] of string;
  _cimDarab: array[1..27] of Integer;
    _cimSor: array[1..27] of string;

  rud,cp: array[1..14] of TPanel;

  _aktsor,_aktosz,_aktDarab: byte;
  _cimValDarab,_Ss: integer;

  _config : TextFile;

  _aktcimsor,_aktdnem: string;

  _betu: char;

  _voltvaltozas: Boolean;

  _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                             'CZK','DKK','EUR','GBP','HRK','HUF','ILS','JPY',
                             'MXN','NOK','NZD','PLN','RON','RSD','RUB','SEK',
                             'THB','TRY','UAH','USD');

  _dnev: array[1..27] of string = ('AUSZTRÁL DOLLÁR','BOSNYÁK MÁRKA','BOLGÁR LEVA',
         'BRAZIL REÁL','KANADAI DOLLÁR','SVÁJCI FRANK','KINAI YUAN','CSEH KORONA',
                  'DÁN KORONA','EURÓ','ANGOL FONT','HORVÁT KUNA','MAGYAR FORINT',
                  'IZRAELI SHAKEL','JAPÁN YEN','MEXIKÓI PESO','NORVÉG KORONA',
                  'ÚJ-ZÉLANDI DOLLÁR','LENGYEL ZLOTY','ROMÁN LEI','SZERB DINÁR',
                  'OROSZ RUBEL','SVÉD KORONA','THAI BAHT','TÖRÖK LÍRA',
                  'UKRÁN HRIVNYA','USA DOLLÁR');

  _height,_width: word;

function cimletbeallito: integer;stdcall;

implementation

{$R *.dfm}


function cimletbeallito: integer;stdcall;

begin
  CimletSetupForm := TCimletSetupForm.create(Nil);
  result := CimletSetupForm.ShowModal;
  CimletSetupForm.Free;
end;



// =============================================================================
           procedure TCimletSetupForm.FormCreate(Sender: TObject);
// =============================================================================

var j: integer;

begin
  _height := screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  Top    := trunc((_height-768)/2);
  Left   := trunc((_width-1024)/2);

  width  := 1024;
  height := 768;

  Panel1.Top := 8;

  RovnevPanel[1] := VNA;
  RovnevPanel[2] := VNB;
  RovnevPanel[3] := VNC;
  RovnevPanel[4] := VND;
  RovnevPanel[5] := VNE;
  RovnevPanel[6] := VNF;
  RovnevPanel[7] := VNG;
  RovnevPanel[8] := VNH;
  RovnevPanel[9] := VNI;
  RovnevPanel[10]:= VNJ;
  RovnevPanel[11]:= VNK;
  RovnevPanel[12]:= VNL;
  RovnevPanel[13]:= VNM;
  RovnevPanel[14]:= VNN;
  RovnevPanel[15]:= VNO;
  RovnevPanel[16]:= VNP;
  RovnevPanel[17]:= VNQ;
  RovnevPanel[18]:= VNR;
  RovnevPanel[19]:= VNS;
  RovnevPanel[20]:= VNT;
  RovnevPanel[21]:= VNU;
  RovnevPanel[22]:= VNV;
  RovnevPanel[23]:= VNW;
  RovnevPanel[24]:= VNX;
  RovnevPanel[25]:= VNY;
  RovnevPanel[26]:= VNZ;
  RovnevPanel[27]:= VNAA;


  LongnevPanel[1] := NMA;
  LongnevPanel[2] := NMB;
  LongnevPanel[3] := NMC;
  LongnevPanel[4] := NMD;
  LongnevPanel[5] := NME;
  LongnevPanel[6] := NMF;
  LongnevPanel[7] := NMG;
  LongnevPanel[8] := NMH;
  LongnevPanel[9] := NMI;
  LongnevPanel[10]:= NMJ;
  LongnevPanel[11]:= NMK;
  LongnevPanel[12]:= NML;
  LongnevPanel[13]:= NMM;
  LongnevPanel[14]:= NMN;
  LongnevPanel[15]:= NMO;
  LongnevPanel[16]:= NMP;
  LongnevPanel[17]:= NMQ;
  LongnevPanel[18]:= NMR;
  LongnevPanel[19]:= NMS;
  LongnevPanel[20]:= NMT;
  LongnevPanel[21]:= NMU;
  LongnevPanel[22]:= NMV;
  LongnevPanel[23]:= NMW;
  LongnevPanel[24]:= NMX;
  LongnevPanel[25]:= NMY;
  LongnevPanel[26]:= NMZ;
  LongnevPanel[27]:= NMAA;

  Cbox[1,1] := chA1;
  Cbox[1,2] := cha2;
  Cbox[1,3] := cha3;
  Cbox[1,4] := cha4;
  Cbox[1,5] := cha5;
  Cbox[1,6] := cha6;
  Cbox[1,7] := cha7;
  Cbox[1,8] := cha8;
  Cbox[1,9] := cha9;
  Cbox[1,10]:= cha10;
  Cbox[1,11]:= cha11;
  Cbox[1,12]:= cha12;
  Cbox[1,13]:= cha13;
  Cbox[1,14]:= cha14;

  Cbox[2,1] := chb1;
  Cbox[2,2] := chb2;
  Cbox[2,3] := chb3;
  Cbox[2,4] := chb4;
  Cbox[2,5] := chb5;
  Cbox[2,6] := chb6;
  Cbox[2,7] := chb7;
  Cbox[2,8] := chb8;
  Cbox[2,9] := chb9;
  Cbox[2,10]:= chb10;
  Cbox[2,11]:= chb11;
  Cbox[2,12]:= chb12;
  Cbox[2,13]:= chb13;
  Cbox[2,14]:= chb14;

  Cbox[3,1] := chc1;
  Cbox[3,2] := chc2;
  Cbox[3,3] := chc3;
  Cbox[3,4] := chc4;
  Cbox[3,5] := chc5;
  Cbox[3,6] := chc6;
  Cbox[3,7] := chc7;
  Cbox[3,8] := chc8;
  Cbox[3,9] := chc9;
  Cbox[3,10]:= chc10;
  Cbox[3,11]:= chc11;
  Cbox[3,12]:= chc12;
  Cbox[3,13]:= chc13;
  Cbox[3,14]:= chc14;

  Cbox[4,1] := chd1;
  Cbox[4,2] := chd2;
  Cbox[4,3] := chd3;
  Cbox[4,4] := chd4;
  Cbox[4,5] := chd5;
  Cbox[4,6] := chd6;
  Cbox[4,7] := chd7;
  Cbox[4,8] := chd8;
  Cbox[4,9] := chd9;
  Cbox[4,10]:= chd10;
  Cbox[4,11]:= chd11;
  Cbox[4,12]:= chd12;
  Cbox[4,13]:= chd13;
  Cbox[4,14]:= chd14;

  Cbox[5,1] := che1;
  Cbox[5,2] := che2;
  Cbox[5,3] := che3;
  Cbox[5,4] := che4;
  Cbox[5,5] := che5;
  Cbox[5,6] := che6;
  Cbox[5,7] := che7;
  Cbox[5,8] := che8;
  Cbox[5,9] := che9;
  Cbox[5,10]:= che10;
  Cbox[5,11]:= che11;
  Cbox[5,12]:= che12;
  Cbox[5,13]:= che13;
  Cbox[5,14]:= che14;

  Cbox[6,1] := chf1;
  Cbox[6,2] := chf2;
  Cbox[6,3] := chf3;
  Cbox[6,4] := chf4;
  Cbox[6,5] := chf5;
  Cbox[6,6] := chf6;
  Cbox[6,7] := chf7;
  Cbox[6,8] := chf8;
  Cbox[6,9] := chf9;
  Cbox[6,10]:= chf10;
  Cbox[6,11]:= chf11;
  Cbox[6,12]:= chf12;
  Cbox[6,13]:= chf13;
  Cbox[6,14]:= chf14;

  Cbox[7,1] := chg1;
  Cbox[7,2] := chg2;
  Cbox[7,3] := chg3;
  Cbox[7,4] := chg4;
  Cbox[7,5] := chg5;
  Cbox[7,6] := chg6;
  Cbox[7,7] := chg7;
  Cbox[7,8] := chg8;
  Cbox[7,9] := chg9;
  Cbox[7,10]:= chg10;
  Cbox[7,11]:= chg11;
  Cbox[7,12]:= chg12;
  Cbox[7,13]:= chg13;
  Cbox[7,14]:= chg14;

  Cbox[8,1] := chh1;
  Cbox[8,2] := chh2;
  Cbox[8,3] := chh3;
  Cbox[8,4] := chh4;
  Cbox[8,5] := chh5;
  Cbox[8,6] := chh6;
  Cbox[8,7] := chh7;
  Cbox[8,8] := chh8;
  Cbox[8,9] := chh9;
  Cbox[8,10]:= chh10;
  Cbox[8,11]:= chh11;
  Cbox[8,12]:= chh12;
  Cbox[8,13]:= chh13;
  Cbox[8,14]:= chh14;

  Cbox[9,1] := chi1;
  Cbox[9,2] := chi2;
  Cbox[9,3] := chi3;
  Cbox[9,4] := chi4;
  Cbox[9,5] := chi5;
  Cbox[9,6] := chi6;
  Cbox[9,7] := chi7;
  Cbox[9,8] := chi8;
  Cbox[9,9] := chi9;
  Cbox[9,10]:= chi10;
  Cbox[9,11]:= chi11;
  Cbox[9,12]:= chi12;
  Cbox[9,13]:= chi13;
  Cbox[9,14]:= chi14;

  Cbox[10,1] := chj1;
  Cbox[10,2] := chj2;
  Cbox[10,3] := chj3;
  Cbox[10,4] := chj4;
  Cbox[10,5] := chj5;
  Cbox[10,6] := chj6;
  Cbox[10,7] := chj7;
  Cbox[10,8] := chj8;
  Cbox[10,9] := chj9;
  Cbox[10,10]:= chj10;
  Cbox[10,11]:= chj11;
  Cbox[10,12]:= chj12;
  Cbox[10,13]:= chj13;
  Cbox[10,14]:= chj14;

  Cbox[11,1] := chk1;
  Cbox[11,2] := chk2;
  Cbox[11,3] := chk3;
  Cbox[11,4] := chk4;
  Cbox[11,5] := chk5;
  Cbox[11,6] := chk6;
  Cbox[11,7] := chk7;
  Cbox[11,8] := chk8;
  Cbox[11,9] := chk9;
  Cbox[11,10]:= chk10;
  Cbox[11,11]:= chk11;
  Cbox[11,12]:= chk12;
  Cbox[11,13]:= chk13;
  Cbox[11,14]:= chk14;

  Cbox[12,1] := chl1;
  Cbox[12,2] := chl2;
  Cbox[12,3] := chl3;
  Cbox[12,4] := chl4;
  Cbox[12,5] := chl5;
  Cbox[12,6] := chl6;
  Cbox[12,7] := chl7;
  Cbox[12,8] := chl8;
  Cbox[12,9] := chl9;
  Cbox[12,10]:= chl10;
  Cbox[12,11]:= chl11;
  Cbox[12,12]:= chl12;
  Cbox[12,13]:= chl13;
  Cbox[12,14]:= chl14;

  Cbox[13,1] := chm1;
  Cbox[13,2] := chm2;
  Cbox[13,3] := chm3;
  Cbox[13,4] := chm4;
  Cbox[13,5] := chm5;
  Cbox[13,6] := chm6;
  Cbox[13,7] := chm7;
  Cbox[13,8] := chm8;
  Cbox[13,9] := chm9;
  Cbox[13,10]:= chm10;
  Cbox[13,11]:= chm11;
  Cbox[13,12]:= chm12;
  Cbox[13,13]:= chm13;
  Cbox[13,14]:= chm14;

  Cbox[14,1] := chn1;
  Cbox[14,2] := chn2;
  Cbox[14,3] := chn3;
  Cbox[14,4] := chn4;
  Cbox[14,5] := chn5;
  Cbox[14,6] := chn6;
  Cbox[14,7] := chn7;
  Cbox[14,8] := chn8;
  Cbox[14,9] := chn9;
  Cbox[14,10]:= chn10;
  Cbox[14,11]:= chn11;
  Cbox[14,12]:= chn12;
  Cbox[14,13]:= chn13;
  Cbox[14,14]:= chn14;

  Cbox[15,1] := cho1;
  Cbox[15,2] := cho2;
  Cbox[15,3] := cho3;
  Cbox[15,4] := cho4;
  Cbox[15,5] := cho5;
  Cbox[15,6] := cho6;
  Cbox[15,7] := cho7;
  Cbox[15,8] := cho8;
  Cbox[15,9] := cho9;
  Cbox[15,10]:= cho10;
  Cbox[15,11]:= cho11;
  Cbox[15,12]:= cho12;
  Cbox[15,13]:= cho13;
  Cbox[15,14]:= cho14;

  Cbox[16,1] := chp1;
  Cbox[16,2] := chp2;
  Cbox[16,3] := chp3;
  Cbox[16,4] := chp4;
  Cbox[16,5] := chp5;
  Cbox[16,6] := chp6;
  Cbox[16,7] := chp7;
  Cbox[16,8] := chp8;
  Cbox[16,9] := chp9;
  Cbox[16,10]:= chp10;
  Cbox[16,11]:= chp11;
  Cbox[16,12]:= chp12;
  Cbox[16,13]:= chp13;
  Cbox[16,14]:= chp14;

  Cbox[17,1] := chq1;
  Cbox[17,2] := chq2;
  Cbox[17,3] := chq3;
  Cbox[17,4] := chq4;
  Cbox[17,5] := chq5;
  Cbox[17,6] := chq6;
  Cbox[17,7] := chq7;
  Cbox[17,8] := chq8;
  Cbox[17,9] := chq9;
  Cbox[17,10]:= chq10;
  Cbox[17,11]:= chq11;
  Cbox[17,12]:= chq12;
  Cbox[17,13]:= chq13;
  Cbox[17,14]:= chq14;

  Cbox[18,1] := chr1;
  Cbox[18,2] := chr2;
  Cbox[18,3] := chr3;
  Cbox[18,4] := chr4;
  Cbox[18,5] := chr5;
  Cbox[18,6] := chr6;
  Cbox[18,7] := chr7;
  Cbox[18,8] := chr8;
  Cbox[18,9] := chr9;
  Cbox[18,10]:= chr10;
  Cbox[18,11]:= chr11;
  Cbox[18,12]:= chr12;
  Cbox[18,13]:= chr13;
  Cbox[18,14]:= chr14;

  Cbox[19,1] := chs1;
  Cbox[19,2] := chs2;
  Cbox[19,3] := chs3;
  Cbox[19,4] := chs4;
  Cbox[19,5] := chs5;
  Cbox[19,6] := chs6;
  Cbox[19,7] := chs7;
  Cbox[19,8] := chs8;
  Cbox[19,9] := chs9;
  Cbox[19,10]:= chs10;
  Cbox[19,11]:= chs11;
  Cbox[19,12]:= chs12;
  Cbox[19,13]:= chs13;
  Cbox[19,14]:= chs14;

  Cbox[20,1] := cht1;
  Cbox[20,2] := cht2;
  Cbox[20,3] := cht3;
  Cbox[20,4] := cht4;
  Cbox[20,5] := cht5;
  Cbox[20,6] := cht6;
  Cbox[20,7] := cht7;
  Cbox[20,8] := cht8;
  Cbox[20,9] := cht9;
  Cbox[20,10]:= cht10;
  Cbox[20,11]:= cht11;
  Cbox[20,12]:= cht12;
  Cbox[20,13]:= cht13;
  Cbox[20,14]:= cht14;

  Cbox[21,1] := chu1;
  Cbox[21,2] := chu2;
  Cbox[21,3] := chu3;
  Cbox[21,4] := chu4;
  Cbox[21,5] := chu5;
  Cbox[21,6] := chu6;
  Cbox[21,7] := chu7;
  Cbox[21,8] := chu8;
  Cbox[21,9] := chu9;
  Cbox[21,10]:= chu10;
  Cbox[21,11]:= chu11;
  Cbox[21,12]:= chu12;
  Cbox[21,13]:= chu13;
  Cbox[21,14]:= chu14;

  Cbox[22,1] := chv1;
  Cbox[22,2] := chv2;
  Cbox[22,3] := chv3;
  Cbox[22,4] := chv4;
  Cbox[22,5] := chv5;
  Cbox[22,6] := chv6;
  Cbox[22,7] := chv7;
  Cbox[22,8] := chv8;
  Cbox[22,9] := chv9;
  Cbox[22,10]:= chv10;
  Cbox[22,11]:= chv11;
  Cbox[22,12]:= chv12;
  Cbox[22,13]:= chv13;
  Cbox[22,14]:= chv14;

  Cbox[23,1] := chw1;
  Cbox[23,2] := chw2;
  Cbox[23,3] := chw3;
  Cbox[23,4] := chw4;
  Cbox[23,5] := chw5;
  Cbox[23,6] := chw6;
  Cbox[23,7] := chw7;
  Cbox[23,8] := chw8;
  Cbox[23,9] := chw9;
  Cbox[23,10]:= chw10;
  Cbox[23,11]:= chw11;
  Cbox[23,12]:= chw12;
  Cbox[23,13]:= chw13;
  Cbox[23,14]:= chw14;

  Cbox[24,1] := chx1;
  Cbox[24,2] := chx2;
  Cbox[24,3] := chx3;
  Cbox[24,4] := chx4;
  Cbox[24,5] := chx5;
  Cbox[24,6] := chx6;
  Cbox[24,7] := chx7;
  Cbox[24,8] := chx8;
  Cbox[24,9] := chx9;
  Cbox[24,10]:= chx10;
  Cbox[24,11]:= chx11;
  Cbox[24,12]:= chx12;
  Cbox[24,13]:= chx13;
  Cbox[24,14]:= chx14;

  Cbox[25,1] := chy1;
  Cbox[25,2] := chy2;
  Cbox[25,3] := chy3;
  Cbox[25,4] := chy4;
  Cbox[25,5] := chy5;
  Cbox[25,6] := chy6;
  Cbox[25,7] := chy7;
  Cbox[25,8] := chy8;
  Cbox[25,9] := chy9;
  Cbox[25,10]:= chy10;
  Cbox[25,11]:= chy11;
  Cbox[25,12]:= chy12;
  Cbox[25,13]:= chy13;
  Cbox[25,14]:= chy14;

  Cbox[26,1] := chz1;
  Cbox[26,2] := chz2;
  Cbox[26,3] := chz3;
  Cbox[26,4] := chz4;
  Cbox[26,5] := chz5;
  Cbox[26,6] := chz6;
  Cbox[26,7] := chz7;
  Cbox[26,8] := chz8;
  Cbox[26,9] := chz9;
  Cbox[26,10]:= chz10;
  Cbox[26,11]:= chz11;
  Cbox[26,12]:= chz12;
  Cbox[26,13]:= chz13;
  Cbox[26,14]:= chz14;

  Cbox[27,1] := chaa1;
  Cbox[27,2] := chaa2;
  Cbox[27,3] := chaa3;
  Cbox[27,4] := chaa4;
  Cbox[27,5] := chaa5;
  Cbox[27,6] := chaa6;
  Cbox[27,7] := chaa7;
  Cbox[27,8] := chaa8;
  Cbox[27,9] := chaa9;
  Cbox[27,10]:= chaa10;
  Cbox[27,11]:= chaa11;
  Cbox[27,12]:= chaa12;
  Cbox[27,13]:= chaa13;
  Cbox[27,14]:= chaa14;

  Rud[1] := Rud1;
  Rud[2] := Rud2;
  Rud[3] := Rud3;
  Rud[4] := Rud4;
  Rud[5] := Rud5;
  Rud[6] := Rud6;
  Rud[7] := Rud7;
  Rud[8] := Rud8;
  Rud[9] := Rud9;
  Rud[10]:= Rud10;
  Rud[11]:= Rud11;
  Rud[12]:= Rud12;
  Rud[13]:= Rud13;
  Rud[14]:= Rud14;

  Cp[1] := C1;
  Cp[2] := C2;
  Cp[3] := C3;
  Cp[4] := C4;
  Cp[5] := C5;
  Cp[6] := C6;
  Cp[7] := C7;
  Cp[8] := C8;
  Cp[9] := C9;
  Cp[10]:= C10;
  Cp[11]:= C11;
  Cp[12]:= C12;
  Cp[13]:= C13;
  Cp[14]:= C14;


  SetupBeolvas; // cimDnem,cimDnev,Cimdb,Cimsor [1..22]

  _aktsor := 1;
  while _aktsor<=27 do
    begin
      rovnevpanel[_aktsor].Caption  := _dnem[_aktsor];
      LongNevPanel[_aktsor].Caption := _dnev[_aktsor];

      _aktDarab  := _cimDarab[_aktsor];
      _aktcimsor := _cimsor[_aktsor];

      for j := 1 to _aktdarab do
        begin
          _betu := _aktCimsor[j];
          _aktosz := ord(_betu)-65;
          _aktbox := cbox[_aktsor,_aktosz];
          _aktbox.Checked := True;
          _aktbox.Color := clred;
        end;
      inc(_aktsor);
    end;
  _voltValtozas := False;
end;


// =============================================================================
      procedure TCIMLETSETUPFORM.SETUPCANCELGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 2;
end;


// =============================================================================
          procedure TCimletSetupForm.SetupOkeGombClick(Sender: TObject);
// =============================================================================

VAR j: integer;
     _aktstr,_confignev: string;

begin
  if not _voltvaltozas then
    begin
      Showmessage('NEM VÁLTOZOTT SEMMI !');
      Modalresult := 2;
      exit;
    end;

  _aktsor := 1;
  while _aktsor <= 27 do
    begin
      _aktdarab := 0;
      _aktcimsor := '';

      for j := 1 to 14 do
        begin
           _aktBox := Cbox[_aktsor,j];

          if _aktbox.Checked then
            begin
              inc(_aktdarab);
              _aktcimsor := _aktcimsor + chr(65+j);
            end;
        end;
      _cimDarab[_aktsor] := _aktdarab;
        _cimsor[_aktsor] := _aktcimsor;

      inc(_aktsor);

    end;

// Most fel lehet irni az új config file-t

  _confignev := 'c:\valuta\Cimlet.cfg';

  AssignFile(_config,_confignev);
  Rewrite(_config);

  _aktsor := 1;
  while _aktsor<=27 do
    begin
      _aktDarab := _cimDarab[_aktsor];
        _aktstr := _dnem[_aktsor]+chr(_aktdarab+65);
        _aktstr := _aktstr + _cimsor[_aktsor];

      WriteLn(_config,_aktstr);
      inc(_aktsor);

    end;

  CloseFile(_config);
  ShowMessage('A MÓDOSITOTT CIMLETTÁBLÁT RÖGZITETTEM !');
  ModalResult := 1;
end;


// =============================================================================
                      procedure TCimletSetupForm.SetupBeolvas;
// =============================================================================

(* A konfigurációs adatok (cimletdarab, és sorszámok) tömbbe irja *)

var _cfdarab,_yy,i: integer;
    _mondat,_cfsor,_configNev: string;

begin

    for i := 1 to 27 do
      begin
        _cimDarab[i]:= 0;
        _cimSor[i]  := '';
      end;

   // Megnyitja a Cimlet konfigurációs file-ját:

   _confignev := 'c:\valuta\Cimlet.cfg';
   AssignFile(_config,_confignev);
   Reset(_config);
   while not eof(_config) do
     begin

       // Beolvas egy-egy sort a konfigurációból:

       ReadLn(_config,_mondat);
       _aktdnem := leftstr(_mondat,3);

       // A sor a valutanévvel kezdödik, megnézi, hogy van-e ilyen valuta
       _yy := DnemScan(_aktdnem);
       if _yy>0 then   // Ha van ilyen valuta:
         begin

           _cfdarab := ord(_mondat[4])-65;
           _cfsor := midstr(_mondat,5,_cfDarab);

           // A valuták tömbjeibe iródnak:

           _CimDarab[_yy] := _cfDarab;
             _CimSor[_yy] := _cfSor;
         end;
     end;
   CloseFile(_config);
end;

// =============================================================================
            function TCimletSetupForm.Dnemscan(_dn: string): byte;
// =============================================================================

var _y: byte;

begin
  result := 0;
  _y :=1;
  while _y<=27 do
    begin
      if _dnem[_y]=_dn then
        begin
          result := _y;
          break;
        end;
      inc(_y);
    end;
end;




// =============================================================================
           procedure TCimletSetupForm.CHA1Exit(Sender: TObject);
// =============================================================================

begin
   _aktBox := TCheckBox(Sender);
   if _aktbox.checked then _aktbox.Color := clRed
        else _aktbox.Color := clWindow;
   _voltvaltozas := True;
end;

procedure TCIMLETSETUPFORM.C1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);

var _rudss: byte;

begin
  _rudss := TPanel(sender).tag;
  Cp[_rudss].Color := clwhite;
  rud[_rudss].Color := clwhite;
end;


procedure TCIMLETSETUPFORM.Panel1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);

var i: byte;

begin
   for i := 1 to 14 do
     begin
       rud[i].Color := clBtnFace;
       cp[i].Color := $e0e0e0;
     end;

end;

procedure TCIMLETSETUPFORM.RUD1MouseMove(Sender: TObject;
                                  Shift: TShiftState; X, Y: Integer);

var _rudss: byte;

begin
   _rudss := TPanel(sender).tag;
  Cp[_rudss].Color := clwhite;
  rud[_rudss].Color := clwhite;
end;














end.
