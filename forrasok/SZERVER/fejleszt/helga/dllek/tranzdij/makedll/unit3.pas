unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, jpeg, ExtCtrls, StdCtrls, unit2, dateutils, StrUtils,
  IBDatabase, DB, IBQuery, IBCustomDataSet, IBTable, Buttons;

type
  TMNBARFOLYAM = class(TForm)
    o1: TPanel;
    V1: TPanel;
    a1: TPanel;
    a2: TPanel;
    a3: TPanel;
    a4: TPanel;
    a5: TPanel;
    a6: TPanel;
    a7: TPanel;
    a8: TPanel;
    a9: TPanel;
    a10: TPanel;
    a11: TPanel;
    a12: TPanel;
    a13: TPanel;
    a15: TPanel;
    a16: TPanel;
    a14: TPanel;
    a17: TPanel;
    a20: TPanel;
    a21: TPanel;
    a18: TPanel;
    a19: TPanel;
    a22: TPanel;
    a23: TPanel;
    a24: TPanel;
    a25: TPanel;
    a27: TPanel;
    a29: TPanel;
    a31: TPanel;
    a26: TPanel;
    a28: TPanel;
    a30: TPanel;
    o2: TPanel;
    o3: TPanel;
    o4: TPanel;
    o5: TPanel;
    o10: TPanel;
    o6: TPanel;
    o8: TPanel;
    o7: TPanel;
    o11: TPanel;
    o9: TPanel;
    V2: TPanel;
    V3: TPanel;
    V4: TPanel;
    V5: TPanel;
    V6: TPanel;
    V7: TPanel;
    V8: TPanel;
    V9: TPanel;
    V10: TPanel;
    V11: TPanel;
    b1: TPanel;
    b2: TPanel;
    b3: TPanel;
    b4: TPanel;
    b5: TPanel;
    b6: TPanel;
    b7: TPanel;
    b8: TPanel;
    b9: TPanel;
    b10: TPanel;
    b11: TPanel;
    c1: TPanel;
    c2: TPanel;
    c3: TPanel;
    c5: TPanel;
    c4: TPanel;
    c7: TPanel;
    c6: TPanel;
    c9: TPanel;
    c8: TPanel;
    c11: TPanel;
    c10: TPanel;
    c12: TPanel;
    c14: TPanel;
    c13: TPanel;
    c15: TPanel;
    d1: TPanel;
    d2: TPanel;
    d3: TPanel;
    d4: TPanel;
    d8: TPanel;
    d5: TPanel;
    d7: TPanel;
    d6: TPanel;
    d9: TPanel;
    d10: TPanel;
    d11: TPanel;
    d12: TPanel;
    d13: TPanel;
    d14: TPanel;
    d16: TPanel;
    d15: TPanel;
    e1: TPanel;
    e2: TPanel;
    e4: TPanel;
    e3: TPanel;
    e5: TPanel;
    e7: TPanel;
    e6: TPanel;
    e12: TPanel;
    e8: TPanel;
    e9: TPanel;
    e13: TPanel;
    e11: TPanel;
    e10: TPanel;
    e15: TPanel;
    e14: TPanel;
    f1: TPanel;
    f2: TPanel;
    f6: TPanel;
    f3: TPanel;
    f7: TPanel;
    f5: TPanel;
    f4: TPanel;
    f9: TPanel;
    f8: TPanel;
    f11: TPanel;
    f10: TPanel;
    f12: TPanel;
    f14: TPanel;
    f13: TPanel;
    f15: TPanel;
    f16: TPanel;
    g1: TPanel;
    g2: TPanel;
    g5: TPanel;
    g3: TPanel;
    g4: TPanel;
    g6: TPanel;
    g8: TPanel;
    g7: TPanel;
    g9: TPanel;
    g12: TPanel;
    g11: TPanel;
    g14: TPanel;
    g13: TPanel;
    g16: TPanel;
    g15: TPanel;
    g10: TPanel;
    g18: TPanel;
    g17: TPanel;
    h17: TPanel;
    h19: TPanel;
    h16: TPanel;
    h18: TPanel;
    h14: TPanel;
    h13: TPanel;
    h11: TPanel;
    h15: TPanel;
    h12: TPanel;
    h10: TPanel;
    h7: TPanel;
    h8: TPanel;
    h9: TPanel;
    h6: TPanel;
    h5: TPanel;
    h4: TPanel;
    h3: TPanel;
    h2: TPanel;
    h1: TPanel;
    i2: TPanel;
    i1: TPanel;
    i3: TPanel;
    i4: TPanel;
    i6: TPanel;
    i5: TPanel;
    i8: TPanel;
    i7: TPanel;
    i10: TPanel;
    i14: TPanel;
    i9: TPanel;
    i12: TPanel;
    i11: TPanel;
    i13: TPanel;
    i18: TPanel;
    i15: TPanel;
    i17: TPanel;
    i16: TPanel;
    j1: TPanel;
    j4: TPanel;
    j3: TPanel;
    j6: TPanel;
    j2: TPanel;
    j5: TPanel;
    j8: TPanel;
    j9: TPanel;
    j7: TPanel;
    j10: TPanel;
    j15: TPanel;
    j13: TPanel;
    j12: TPanel;
    j11: TPanel;
    j14: TPanel;
    j17: TPanel;
    j16: TPanel;
    k1: TPanel;
    k2: TPanel;
    k3: TPanel;
    k4: TPanel;
    k9: TPanel;
    k6: TPanel;
    k10: TPanel;
    k8: TPanel;
    k5: TPanel;
    k12: TPanel;
    k13: TPanel;
    k14: TPanel;
    k15: TPanel;
    k11: TPanel;
    k17: TPanel;
    k16: TPanel;
    k18: TPanel;
    k7: TPanel;
    b13: TPanel;
    b15: TPanel;
    b14: TPanel;
    b17: TPanel;
    b16: TPanel;
    b18: TPanel;
    b20: TPanel;
    b19: TPanel;
    b22: TPanel;
    b21: TPanel;
    b23: TPanel;
    b28: TPanel;
    b25: TPanel;
    b24: TPanel;
    b27: TPanel;
    b26: TPanel;
    c16: TPanel;
    c18: TPanel;
    c17: TPanel;
    c20: TPanel;
    c22: TPanel;
    c21: TPanel;
    c23: TPanel;
    c24: TPanel;
    c27: TPanel;
    c25: TPanel;
    c28: TPanel;
    c26: TPanel;
    d18: TPanel;
    d17: TPanel;
    d19: TPanel;
    d20: TPanel;
    d21: TPanel;
    d24: TPanel;
    d22: TPanel;
    d25: TPanel;
    d23: TPanel;
    d27: TPanel;
    d26: TPanel;
    e17: TPanel;
    e18: TPanel;
    e20: TPanel;
    e19: TPanel;
    e21: TPanel;
    e23: TPanel;
    e22: TPanel;
    e25: TPanel;
    e24: TPanel;
    e26: TPanel;
    e27: TPanel;
    f18: TPanel;
    f19: TPanel;
    f20: TPanel;
    f21: TPanel;
    f22: TPanel;
    f24: TPanel;
    f23: TPanel;
    f26: TPanel;
    f25: TPanel;
    f28: TPanel;
    f27: TPanel;
    f29: TPanel;
    g19: TPanel;
    g22: TPanel;
    g21: TPanel;
    g24: TPanel;
    g23: TPanel;
    g26: TPanel;
    g25: TPanel;
    g27: TPanel;
    g28: TPanel;
    h21: TPanel;
    h20: TPanel;
    h22: TPanel;
    h24: TPanel;
    h23: TPanel;
    h25: TPanel;
    h28: TPanel;
    h26: TPanel;
    h27: TPanel;
    i25: TPanel;
    i22: TPanel;
    i21: TPanel;
    i20: TPanel;
    i24: TPanel;
    i27: TPanel;
    i26: TPanel;
    i23: TPanel;
    i29: TPanel;
    i28: TPanel;
    i30: TPanel;
    j18: TPanel;
    j20: TPanel;
    j19: TPanel;
    j21: TPanel;
    j24: TPanel;
    j22: TPanel;
    j25: TPanel;
    j23: TPanel;
    j27: TPanel;
    j28: TPanel;
    j26: TPanel;
    k20: TPanel;
    k22: TPanel;
    k21: TPanel;
    k24: TPanel;
    k23: TPanel;
    k27: TPanel;
    k26: TPanel;
    k29: TPanel;
    k28: TPanel;
    k25: TPanel;
    k19: TPanel;
    k30: TPanel;
    i19: TPanel;
    e16: TPanel;
    f17: TPanel;
    g20: TPanel;
    c19: TPanel;
    b12: TPanel;
    b30: TPanel;
    b29: TPanel;
    b31: TPanel;
    c31: TPanel;
    c30: TPanel;
    c29: TPanel;
    d29: TPanel;
    d30: TPanel;
    d31: TPanel;
    d28: TPanel;
    e31: TPanel;
    e28: TPanel;
    e29: TPanel;
    e30: TPanel;
    f31: TPanel;
    f30: TPanel;
    g31: TPanel;
    g29: TPanel;
    g30: TPanel;
    h30: TPanel;
    h31: TPanel;
    h29: TPanel;
    i31: TPanel;
    j30: TPanel;
    j31: TPanel;
    j29: TPanel;
    k31: TPanel;
    o0: TPanel;
    n1: TPanel;
    EVPANEL: TPanel;
    n2: TPanel;
    n3: TPanel;
    n6: TPanel;
    n4: TPanel;
    n7: TPanel;
    n5: TPanel;
    n10: TPanel;
    n9: TPanel;
    n8: TPanel;
    n11: TPanel;
    n12: TPanel;
    n16: TPanel;
    n14: TPanel;
    n15: TPanel;
    n18: TPanel;
    n19: TPanel;
    n21: TPanel;
    n20: TPanel;
    n17: TPanel;
    n13: TPanel;
    n23: TPanel;
    n31: TPanel;
    n29: TPanel;
    n27: TPanel;
    n25: TPanel;
    n22: TPanel;
    n24: TPanel;
    n26: TPanel;
    n28: TPanel;
    n30: TPanel;
    Fuggony: TPanel;
    OLDALVALTOGOMB: TButton;
    VISSZAGOMB: TButton;

    AlsoFuggony: TPanel;
    INPUTPANEL: TPanel;
    ARFEDIT: TEdit;
    ARFPANEL: TPanel;
    ARFTABLA: TIBTable;
    ARFQUERY: TIBQuery;
    ARFDBASE: TIBDatabase;
    ARFTRANZ: TIBTransaction;
    HIDEEDIT: TEdit;
    Panel1: TPanel;
    T1: TPanel;
    Image1: TImage;
    T2: TPanel;
    Image2: TImage;
    T3: TPanel;
    Image3: TImage;
    T4: TPanel;
    Image4: TImage;
    T5: TPanel;
    Image5: TImage;
    T6: TPanel;
    Image6: TImage;
    T7: TPanel;
    Image7: TImage;
    T8: TPanel;
    Image8: TImage;
    T9: TPanel;
    Image9: TImage;
    T10: TPanel;
    Image10: TImage;
    T11: TPanel;
    Image11: TImage;
    FELGOMB: TBitBtn;
    LEGOMB: TBitBtn;
    felsotakaro: TPanel;
    O12: TPanel;
    v12: TPanel;
    T12: TPanel;
    L1: TPanel;
    L2: TPanel;
    L3: TPanel;
    L4: TPanel;
    L5: TPanel;
    L6: TPanel;
    L8: TPanel;
    L7: TPanel;
    L9: TPanel;
    L10: TPanel;
    L11: TPanel;
    L12: TPanel;
    L13: TPanel;
    L14: TPanel;
    L15: TPanel;
    L16: TPanel;
    L17: TPanel;
    L20: TPanel;
    L18: TPanel;
    L19: TPanel;
    L21: TPanel;
    L22: TPanel;
    L23: TPanel;
    L24: TPanel;
    L26: TPanel;
    L27: TPanel;
    L28: TPanel;
    L30: TPanel;
    L29: TPanel;
    L25: TPanel;
    Image12: TImage;
    L31: TPanel;
    O13: TPanel;
    v13: TPanel;
    T13: TPanel;
    M1: TPanel;
    M3: TPanel;
    M5: TPanel;
    M7: TPanel;
    M9: TPanel;
    M11: TPanel;
    M13: TPanel;
    M15: TPanel;
    M17: TPanel;
    M19: TPanel;
    M21: TPanel;
    M23: TPanel;
    M25: TPanel;
    M27: TPanel;
    M29: TPanel;
    M31: TPanel;
    M2: TPanel;
    M4: TPanel;
    M6: TPanel;
    M8: TPanel;
    M10: TPanel;
    M12: TPanel;
    M14: TPanel;
    M16: TPanel;
    M18: TPanel;
    M20: TPanel;
    M22: TPanel;
    M24: TPanel;
    M26: TPanel;
    M28: TPanel;
    m30: TPanel;
    Image13: TImage;

    procedure VISSZAGOMBClick(Sender: TObject);

    procedure OLDALVALTOGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure OldalDisplay;
    procedure DatumDisplay;
    procedure TablaTorles;
    procedure ElszamAdatokBetoltese;
    procedure Elszamadatokfelirasa;
    procedure SetSorOszlop(_pnev:string);
    function GetRightPanel: TPanel;
    function GetLeftPanel: TPanel;
    function GetUpPanel: TPanel;
    function GetDownPanel: TPanel;
    procedure Adatbeiras;

    procedure CaptiontoTomb;
    function GetTablaAdat(_aTab: TPanel): integer;
   

    function Nulele(_in: integer):string;
    procedure a1Click(Sender: TObject);
    procedure ARFEDITEnter(Sender: TObject);
    procedure ARFEDITExit(Sender: TObject);
    procedure ElszamParancs(_ukaz: string);
    procedure ARFEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  
    procedure HIDEEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FELGOMBClick(Sender: TObject);
    procedure LEGOMBClick(Sender: TObject);
    procedure N1Click(Sender: TObject);

 
   

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MNBARFOLYAM: TMNBARFOLYAM;

  _oldal: integer;
  _houtolsonap,_hnap,_napszam: word;
  _evhos,_aktdnem,_aktdatums,_aktpString,_vasnap: string;
  _aktpaneloszlop,_aktpanelsor,_oszdb: byte;

  _aktdatum : TDateTime;
  _input,_enter: boolean;
  _aktpanel,_pirosPanel: Tpanel;
  _aktcolor : TColor;
  _akttabla : TPanel;


implementation

{$R *.dfm}


// =============================================================================
              procedure TMNBARFOLYAM.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top := 0;
  Left := 0;

  width := 1280;
  height:= 1024;

  Fuggony.Visible := False;
  InputPanel.Visible := False;
  _pirospanel := Nil;
  _enter := False;
  _fenn := false;

  _ap[1] :=a1;
  _ap[2] :=a2;
  _ap[3] :=a3;
  _ap[4] :=a4;
  _ap[5] :=a5;
  _ap[6] :=a6;
  _ap[7] :=a7;
  _ap[8] :=a8;
  _ap[9] :=a9;
  _ap[10]:=a10;
  _ap[11]:=a11;
  _ap[12]:=a12;
  _ap[13]:=a13;
  _ap[14]:=a14;
  _ap[15]:=a15;
  _ap[16]:=a16;
  _ap[17]:=a17;
  _ap[18]:=a18;
  _ap[19]:=a19;
  _ap[20]:=a20;
  _ap[21]:=a21;
  _ap[22]:=a22;
  _ap[23]:=a23;
  _ap[24]:=a24;
  _ap[25]:=a25;
  _ap[26]:=a26;
  _ap[27]:=a27;
  _ap[28]:=a28;
  _ap[29]:=a29;
  _ap[30]:=a30;
  _ap[31]:=a31;


  _bp[1] :=b1;
  _bp[2] :=b2;
  _bp[3] :=b3;
  _bp[4] :=b4;
  _bp[5] :=b5;
  _bp[6] :=b6;
  _bp[7] :=b7;
  _bp[8] :=b8;
  _bp[9] :=b9;
  _bp[10]:=b10;
  _bp[11]:=b11;
  _bp[12]:=b12;
  _bp[13]:=b13;
  _bp[14]:=b14;
  _bp[15]:=b15;
  _bp[16]:=b16;
  _bp[17]:=b17;
  _bp[18]:=b18;
  _bp[19]:=b19;
  _bp[20]:=b20;
  _bp[21]:=b21;
  _bp[22]:=b22;
  _bp[23]:=b23;
  _bp[24]:=b24;
  _bp[25]:=b25;
  _bp[26]:=b26;
  _bp[27]:=b27;
  _bp[28]:=b28;
  _bp[29]:=b29;
  _bp[30]:=b30;
  _bp[31]:=b31;

  _cp[1] :=c1;
  _cp[2] :=c2;
  _cp[3] :=c3;
  _cp[4] :=c4;
  _cp[5] :=c5;
  _cp[6] :=c6;
  _cp[7] :=c7;
  _cp[8] :=c8;
  _cp[9] :=c9;
  _cp[10]:=c10;
  _cp[11]:=c11;
  _cp[12]:=c12;
  _cp[13]:=c13;
  _cp[14]:=c14;
  _cp[15]:=c15;
  _cp[16]:=c16;
  _cp[17]:=c17;
  _cp[18]:=c18;
  _cp[19]:=c19;
  _cp[20]:=c20;
  _cp[21]:=c21;
  _cp[22]:=c22;
  _cp[23]:=c23;
  _cp[24]:=c24;
  _cp[25]:=c25;
  _cp[26]:=c26;
  _cp[27]:=c27;
  _cp[28]:=c28;
  _cp[29]:=c29;
  _cp[30]:=c30;
  _cp[31]:=c31;

  _dp[1] :=d1;
  _dp[2] :=d2;
  _dp[3] :=d3;
  _dp[4] :=d4;
  _dp[5] :=d5;
  _dp[6] :=d6;
  _dp[7] :=d7;
  _dp[8] :=d8;
  _dp[9] :=d9;
  _dp[10]:=d10;
  _dp[11]:=d11;
  _dp[12]:=d12;
  _dp[13]:=d13;
  _dp[14]:=d14;
  _dp[15]:=d15;
  _dp[16]:=d16;
  _dp[17]:=d17;
  _dp[18]:=d18;
  _dp[19]:=d19;
  _dp[20]:=d20;
  _dp[21]:=d21;
  _dp[22]:=d22;
  _dp[23]:=d23;
  _dp[24]:=d24;
  _dp[25]:=d25;
  _dp[26]:=d26;
  _dp[27]:=d27;
  _dp[28]:=d28;
  _dp[29]:=d29;
  _dp[30]:=d30;
  _dp[31]:=d31;

  _ep[1] :=e1;
  _ep[2] :=e2;
  _ep[3] :=e3;
  _ep[4] :=e4;
  _ep[5] :=e5;
  _ep[6] :=e6;
  _ep[7] :=e7;
  _ep[8] :=e8;
  _ep[9] :=e9;
  _ep[10]:=e10;
  _ep[11]:=e11;
  _ep[12]:=e12;
  _ep[13]:=e13;
  _ep[14]:=e14;
  _ep[15]:=e15;
  _ep[16]:=e16;
  _ep[17]:=e17;
  _ep[18]:=e18;
  _ep[19]:=e19;
  _ep[20]:=e20;
  _ep[21]:=e21;
  _ep[22]:=e22;
  _ep[23]:=e23;
  _ep[24]:=e24;
  _ep[25]:=e25;
  _ep[26]:=e26;
  _ep[27]:=e27;
  _ep[28]:=e28;
  _ep[29]:=e29;
  _ep[30]:=e30;
  _ep[31]:=e31;

  _fp[1] :=f1;
  _fp[2] :=f2;
  _fp[3] :=f3;
  _fp[4] :=f4;
  _fp[5] :=f5;
  _fp[6] :=f6;
  _fp[7] :=f7;
  _fp[8] :=f8;
  _fp[9] :=f9;
  _fp[10]:=f10;
  _fp[11]:=f11;
  _fp[12]:=f12;
  _fp[13]:=f13;
  _fp[14]:=f14;
  _fp[15]:=f15;
  _fp[16]:=f16;
  _fp[17]:=f17;
  _fp[18]:=f18;
  _fp[19]:=f19;
  _fp[20]:=f20;
  _fp[21]:=f21;
  _fp[22]:=f22;
  _fp[23]:=f23;
  _fp[24]:=f24;
  _fp[25]:=f25;
  _fp[26]:=f26;
  _fp[27]:=f27;
  _fp[28]:=f28;
  _fp[29]:=f29;
  _fp[30]:=f30;
  _fp[31]:=f31;

  _gp[1] :=g1;
  _gp[2] :=g2;
  _gp[3] :=g3;
  _gp[4] :=g4;
  _gp[5] :=g5;
  _gp[6] :=g6;
  _gp[7] :=g7;
  _gp[8] :=g8;
  _gp[9] :=g9;
  _gp[10]:=g10;
  _gp[11]:=g11;
  _gp[12]:=g12;
  _gp[13]:=g13;
  _gp[14]:=g14;
  _gp[15]:=g15;
  _gp[16]:=g16;
  _gp[17]:=g17;
  _gp[18]:=g18;
  _gp[19]:=g19;
  _gp[20]:=g20;
  _gp[21]:=g21;
  _gp[22]:=g22;
  _gp[23]:=g23;
  _gp[24]:=g24;
  _gp[25]:=g25;
  _gp[26]:=g26;
  _gp[27]:=g27;
  _gp[28]:=g28;
  _gp[29]:=g29;
  _gp[30]:=g30;
  _gp[31]:=g31;

  _hp[1] :=h1;
  _hp[2] :=h2;
  _hp[3] :=h3;
  _hp[4] :=h4;
  _hp[5] :=h5;
  _hp[6] :=h6;
  _hp[7] :=h7;
  _hp[8] :=h8;
  _hp[9] :=h9;
  _hp[10]:=h10;
  _hp[11]:=h11;
  _hp[12]:=h12;
  _hp[13]:=h13;
  _hp[14]:=h14;
  _hp[15]:=h15;
  _hp[16]:=h16;
  _hp[17]:=h17;
  _hp[18]:=h18;
  _hp[19]:=h19;
  _hp[20]:=h20;
  _hp[21]:=h21;
  _hp[22]:=h22;
  _hp[23]:=h23;
  _hp[24]:=h24;
  _hp[25]:=h25;
  _hp[26]:=h26;
  _hp[27]:=h27;
  _hp[28]:=h28;
  _hp[29]:=h29;
  _hp[30]:=h30;
  _hp[31]:=h31;

  _ip[1] :=i1;
  _ip[2] :=i2;
  _ip[3] :=i3;
  _ip[4] :=i4;
  _ip[5] :=i5;
  _ip[6] :=i6;
  _ip[7] :=i7;
  _ip[8] :=i8;
  _ip[9] :=i9;
  _ip[10]:=i10;
  _ip[11]:=i11;
  _ip[12]:=i12;
  _ip[13]:=i13;
  _ip[14]:=i14;
  _ip[15]:=i15;
  _ip[16]:=i16;
  _ip[17]:=i17;
  _ip[18]:=i18;
  _ip[19]:=i19;
  _ip[20]:=i20;
  _ip[21]:=i21;
  _ip[22]:=i22;
  _ip[23]:=i23;
  _ip[24]:=i24;
  _ip[25]:=i25;
  _ip[26]:=i26;
  _ip[27]:=i27;
  _ip[28]:=i28;
  _ip[29]:=i29;
  _ip[30]:=i30;
  _ip[31]:=i31;

  _jp[1] :=j1;
  _jp[2] :=j2;
  _jp[3] :=j3;
  _jp[4] :=j4;
  _jp[5] :=j5;
  _jp[6] :=j6;
  _jp[7] :=j7;
  _jp[8] :=j8;
  _jp[9] :=j9;
  _jp[10]:=j10;
  _jp[11]:=j11;
  _jp[12]:=j12;
  _jp[13]:=j13;
  _jp[14]:=j14;
  _jp[15]:=j15;
  _jp[16]:=j16;
  _jp[17]:=j17;
  _jp[18]:=j18;
  _jp[19]:=j19;
  _jp[20]:=j20;
  _jp[21]:=j21;
  _jp[22]:=j22;
  _jp[23]:=j23;
  _jp[24]:=j24;
  _jp[25]:=j25;
  _jp[26]:=j26;
  _jp[27]:=j27;
  _jp[28]:=j28;
  _jp[29]:=j29;
  _jp[30]:=j30;
  _jp[31]:=j31;

  _kp[1] :=k1;
  _kp[2] :=k2;
  _kp[3] :=k3;
  _kp[4] :=k4;
  _kp[5] :=k5;
  _kp[6] :=k6;
  _kp[7] :=k7;
  _kp[8] :=k8;
  _kp[9] :=k9;
  _kp[10]:=k10;
  _kp[11]:=k11;
  _kp[12]:=k12;
  _kp[13]:=k13;
  _kp[14]:=k14;
  _kp[15]:=k15;
  _kp[16]:=k16;
  _kp[17]:=k17;
  _kp[18]:=k18;
  _kp[19]:=k19;
  _kp[20]:=k20;
  _kp[21]:=k21;
  _kp[22]:=k22;
  _kp[23]:=k23;
  _kp[24]:=k24;
  _kp[25]:=k25;
  _kp[26]:=k26;
  _kp[27]:=k27;
  _kp[28]:=k28;
  _kp[29]:=k29;
  _kp[30]:=k30;
  _kp[31]:=k31;

  _lp[1] :=l1;
  _lp[2] :=l2;
  _lp[3] :=l3;
  _lp[4] :=l4;
  _lp[5] :=l5;
  _lp[6] :=l6;
  _lp[7] :=l7;
  _lp[8] :=l8;
  _lp[9] :=l9;
  _lp[10]:=l10;
  _lp[11]:=l11;
  _lp[12]:=l12;
  _lp[13]:=l13;
  _lp[14]:=l14;
  _lp[15]:=l15;
  _lp[16]:=l16;
  _lp[17]:=l17;
  _lp[18]:=l18;
  _lp[19]:=l19;
  _lp[20]:=l20;
  _lp[21]:=l21;
  _lp[22]:=l22;
  _lp[23]:=l23;
  _lp[24]:=l24;
  _lp[25]:=l25;
  _lp[26]:=l26;
  _lp[27]:=l27;
  _lp[28]:=l28;
  _lp[29]:=l29;
  _lp[30]:=l30;
  _lp[31]:=l31;

  _mp[1] :=m1;
  _mp[2] :=m2;
  _mp[3] :=m3;
  _mp[4] :=m4;
  _mp[5] :=m5;
  _mp[6] :=m6;
  _mp[7] :=m7;
  _mp[8] :=m8;
  _mp[9] :=m9;
  _mp[10]:=m10;
  _mp[11]:=m11;
  _mp[12]:=m12;
  _mp[13]:=m13;
  _mp[14]:=m14;
  _mp[15]:=m15;
  _mp[16]:=m16;
  _mp[17]:=m17;
  _mp[18]:=m18;
  _mp[19]:=m19;
  _mp[20]:=m20;
  _mp[21]:=m21;
  _mp[22]:=m22;
  _mp[23]:=m23;
  _mp[24]:=m24;
  _mp[25]:=m25;
  _mp[26]:=m26;
  _mp[27]:=m27;
  _mp[28]:=m28;
  _mp[29]:=m29;
  _mp[30]:=m30;
  _mp[31]:=m31;




  _np[1] :=n1;
  _np[2] :=n2;
  _np[3] :=n3;
  _np[4] :=n4;
  _np[5] :=n5;
  _np[6] :=n6;
  _np[7] :=n7;
  _np[8] :=n8;
  _np[9] :=n9;
  _np[10]:=n10;
  _np[11]:=n11;
  _np[12]:=n12;
  _np[13]:=n13;
  _np[14]:=n14;
  _np[15]:=n15;
  _np[16]:=n16;
  _np[17]:=n17;
  _np[18]:=n18;
  _np[19]:=n19;
  _np[20]:=n20;
  _np[21]:=n21;
  _np[22]:=n22;
  _np[23]:=n23;
  _np[24]:=n24;
  _np[25]:=n25;
  _np[26]:=n26;
  _np[27]:=n27;
  _np[28]:=n28;
  _np[29]:=n29;
  _np[30]:=n30;
  _np[31]:=n31;

  _op[0] := o0;
  _op[1] := o1;
  _op[2] := o2;
  _op[3] := o3;
  _op[4] := o4;
  _op[5] := o5;
  _op[6] := o6;
  _op[7] := o7;
  _op[8] := o8;
  _op[9] := o9;
  _op[10]:= o10;
  _op[11]:= o11;
  _op[12]:= o12;
  _op[13]:= o13;

  _im[1]  := image1;
  _im[2]  := image2;
  _im[3]  := image3;
  _im[4]  := image4;
  _im[5]  := image5;
  _im[6]  := image6;
  _im[7]  := image7;
  _im[8]  := image8;
  _im[9]  := image9;
  _im[10] := image10;
  _im[11] := image11;
  _im[12] := image12;
  _im[13] := image13;

  _tp[1] := t1;
  _tp[2] := t2;
  _tp[3] := t3;
  _tp[4] := t4;
  _tp[5] := t5;
  _tp[6] := t6;
  _tp[7] := t7;
  _tp[8] := t8;
  _tp[9] := t9;
  _tp[10]:= t10;
  _tp[11]:= t11;
  _tp[12]:= t12;
  _tp[13]:= t13;

  _vp[1] := v1;
  _vp[2] := v2;
  _vp[3] := v3;
  _vp[4] := v4;
  _vp[5] := v5;
  _vp[6] := v6;
  _vp[7] := v7;
  _vp[8] := v8;
  _vp[9] := v9;
  _vp[10]:= v10;
  _vp[11]:= v11;
  _vp[12]:= v12;
  _vp[13]:= v13;

  Legomb.Enabled := false;

  ElszamAdatokBetoltese;

  _oldal := 1;
  DatumDisplay;
  OldalDisplay;
end;

// =============================================================================
                       procedure TMNBarfolyam.DatumDisplay;
// =============================================================================

var _akthonev: string;
    _plus,i,_nn: byte;
    _picpath,_pics: string;

begin

  Evpanel.caption := inttostr(_kertev);

  _hoUtolsonap := daysinamonth(_kertev,_kerthonap);
  _evhos       := inttostr(_kertev)+'.'+nulele(_kerthonap)+'.';
  _akthonev    := _honev[_kerthonap];

  if _Oldal=1 then _plus :=0 else _plus := 11;

  _picpath := 'c:\receptor\flags\';

  for i := 1 to 13 do
    begin
       _aktdnem      := _dnem[i+_plus];
      _vp[i].Caption := _aktdnem;

      _pics := _picpath + _aktdnem + '.jpg';
      _im[i].Picture.LoadFromFile(_pics);
    end;

  _nn := 1;
  while _nn<=_houtolsonap do
    begin
      _aktdatums := _evhos + nulele(_nn);
      _aktdatum  := strtodate(_aktdatums);

      _hnap := dayoftheweek(_aktdatum);
      _np[_nn].Caption := _akthonev+' '+inttostr(_nn);
      if _hnap=7 then
        begin
          _np[_nn].Color := $ffb0ff;
          _np[_nn].Cursor := crHandPoint;
          _ap[_nn].Color := $ffb0ff;
          _bp[_nn].Color := $ffb0ff;
          _cp[_nn].Color := $ffb0ff;
          _dp[_nn].Color := $ffb0ff;
          _ep[_nn].Color := $ffb0ff;
          _fp[_nn].Color := $ffb0ff;
          _gp[_nn].Color := $ffb0ff;
          _hp[_nn].Color := $ffb0ff;
          _ip[_nn].Color := $ffb0ff;
          _jp[_nn].Color := $ffb0ff;
          _kp[_nn].Color := $ffb0ff;
          _lp[_nn].Color := $ffb0ff;
          _Mp[_nn].Color := $ffb0ff;
        end else
        begin
          _np[_nn].Color := $b0ffff;
          _np[_nn].Cursor := crDefault;
          _ap[_nn].Color := clWhite;
          _bp[_nn].Color := clBtnFace;
          _cp[_nn].Color := clWhite;
          _dp[_nn].Color := clBtnFace;
          _ep[_nn].Color := clWhite;
          _fp[_nn].Color := clBtnFace;
          _gp[_nn].Color := clWhite;
          _hp[_nn].Color := clBtnFace;
          _ip[_nn].Color := clWhite;
          _jp[_nn].Color := clBtnFace;
          _kp[_nn].Color := clWhite;
          _lp[_nn].Color := clBtnFace;
          _mp[_nn].Color := clWhite;
        end;
       _ap[_nn].Cursor := crHandPoint;
       _bp[_nn].Cursor := crHandPoint;
       _cp[_nn].Cursor := crHandPoint;
       _dp[_nn].Cursor := crHandPoint;
       _ep[_nn].Cursor := crHandPoint;
       _fp[_nn].Cursor := crHandPoint;
       _gp[_nn].Cursor := crHandPoint;
       _hp[_nn].Cursor := crHandPoint;
       _ip[_nn].Cursor := crHandPoint;
       _jp[_nn].Cursor := crHandPoint;
       _kp[_nn].Cursor := crHandPoint;
       _lp[_nn].Cursor := crHandPoint;
       _mp[_nn].Cursor := crHandPoint;

       _ap[_nn].OnClick := a1click;
       _bp[_nn].OnClick := a1click;
       _cp[_nn].OnClick := a1click;
       _dp[_nn].OnClick := a1click;
       _ep[_nn].OnClick := a1click;
       _fp[_nn].OnClick := a1click;
       _gp[_nn].OnClick := a1click;
       _hp[_nn].OnClick := a1click;
       _ip[_nn].OnClick := a1click;
       _jp[_nn].OnClick := a1click;
       _kp[_nn].OnClick := a1click;
       _lp[_nn].OnClick := a1click;
       _mp[_nn].OnClick := a1click;

       inc(_nn);
    end;

  _ftop := 888;
  if _houtolsonap<31 then
    begin
      case _houtolsonap of
         30: _ftop := 888;
         29: _ftop := 864;
         28: _ftop := 840;
       end;

     with Alsofuggony do
       begin
         Top := _ftop;
         left := 64;
         Visible := true;
       end;
    end else alsofuggony.Visible := false;

  TablaTorles;
  _oldal := 1;

  OldaldISPLAY;

end;

// =============================================================================
                         procedure TMNBArfolyam.Tablatorles;
// =============================================================================

var i: integer;

begin
  for i := 1 to 31 do
    begin
      _ap[i].Caption := '';
      _bp[i].Caption := '';
      _cp[i].Caption := '';
      _dp[i].Caption := '';
      _ep[i].Caption := '';
      _fp[i].Caption := '';
      _gp[i].Caption := '';
      _hp[i].Caption := '';
      _ip[i].Caption := '';
      _jp[i].Caption := '';
      _kp[i].Caption := '';
      _lp[i].Caption := '';
      _mp[i].Caption := '';
    end;
end;

// =============================================================================
              procedure TMNBARFOLYAM.OldalValtoGombClick(Sender: TObject);
// =============================================================================

var _fl: integer;

begin
  // if _input then exit;

  CaptiontoTomb;

  if _oldal=1 then _oldal := 2 else _oldal := 1;

  Fuggony.left    := 200;
  Fuggony.color   := clRed;
  Fuggony.Visible := true;
  Fuggony.Repaint;

  _fl := 200;
  while _fl<1110 do
    begin
      _fl := _fl+25;
      fuggony.Left := _fl;
      sleep(10);
    end;

  Fuggony.Left := 1160;
  Fuggony.Visible := False;
  OldalDisplay;
end;

// =============================================================================
            function TMNBArfolyam.Nulele(_in: integer):string;
// =============================================================================

begin
  result := inttostr(_in);
  if _in<10 then result := '0' + result;
end;


// =============================================================================
                      procedure TMNBArfolyam.OldalDisplay;
// =============================================================================

var _plus,i,_pplus,_napszam,_data: integer;
    _picPath,_pics: string;


begin
  _picpath := 'c:\receptor\flags\';

  if _Oldal=1 then _plus := 0 else _plus := 13;

  for i := 1 to 13 do
    begin
      _pplus := i+ _plus;
      _aktdnem := _dnem[_pplus];
      _vp[i].caption := _aktdnem;

      _pics := _picpath + _aktdnem + '.jpg';
      _im[i].Picture.LoadFromFile(_pics);
    end;


  _napszam := 1;
  while _napszam<=_hoUtolsoNap do
    begin

      _data := _datatomb[1+_plus,_napszam];
      _aktTabla := _ap[_napszam];
      _aktTabla.Caption := '';
      if _data>0 then _akttabla.Caption := inttostr(_data);

      _data := _datatomb[2+_plus,_napszam];
      _aktTabla := _bp[_napszam];
      _aktTabla.Caption := '';
      if _data>0 then _akttabla.Caption := inttostr(_data);

      _data := _datatomb[3+_plus,_napszam];
      _aktTabla := _cp[_napszam];
      _aktTabla.Caption := '';
      if _data>0 then _akttabla.Caption := inttostr(_data);

      _data := _datatomb[4+_plus,_napszam];
      _aktTabla := _dp[_napszam];
      _aktTabla.Caption := '';
      if _data>0 then _akttabla.Caption := inttostr(_data);

      _data := _datatomb[5+_plus,_napszam];
      _aktTabla := _ep[_napszam];
      _aktTabla.Caption := '';
      if _data>0 then _akttabla.Caption := inttostr(_data);

      _data := _datatomb[6+_plus,_napszam];
      _aktTabla := _fp[_napszam];
      _aktTabla.Caption := '';
      if _data>0 then _akttabla.Caption := inttostr(_data);

      _data := _datatomb[7+_plus,_napszam];
      _aktTabla := _gp[_napszam];
      _aktTabla.Caption := '';
      if _data>0 then _akttabla.Caption := inttostr(_data);

      _data := _datatomb[8+_plus,_napszam];
      _aktTabla := _hp[_napszam];
      _aktTabla.Caption := '';
      if _data>0 then _akttabla.Caption := inttostr(_data);

      _data := _datatomb[9+_plus,_napszam];
      _aktTabla := _ip[_napszam];
      _aktTabla.Caption := '';
      if _data>0 then _akttabla.Caption := inttostr(_data);

      _data := _datatomb[10+_plus,_napszam];
      _aktTabla := _jp[_napszam];
      _aktTabla.Caption := '';
      if _data>0 then _akttabla.Caption := inttostr(_data);

      _data := _datatomb[11+_plus,_napszam];
      _aktTabla := _kp[_napszam];
      _aktTabla.Caption := '';
      if _data>0 then _akttabla.Caption := inttostr(_data);

      _data := _datatomb[12+_plus,_napszam];
      _aktTabla := _lp[_napszam];
      _aktTabla.Caption := '';
      if _data>0 then _akttabla.Caption := inttostr(_data);

      _data := _datatomb[13+_plus,_napszam];
      _aktTabla := _mp[_napszam];
      _aktTabla.Caption := '';
      if _data>0 then _akttabla.Caption := inttostr(_data);

      inc(_napszam);
    end;
  _input := false;
end;

// =============================================================================
                procedure TMNBARFOLYAM.a1Click(Sender: TObject);
// =============================================================================

begin
  _aktPanel    := Tpanel(sender);
  Adatbeiras;
end;

// =============================================================================
             procedure TMNBARFOLYAM.ARFEDITEnter(Sender: TObject);
// =============================================================================

begin
  aRFEDIT.Color := $B0FFFF;
  Arfpanel.Color := $b0ffff;
end;

// =============================================================================
             procedure TMNBARFOLYAM.ARFEDITExit(Sender: TObject);
// =============================================================================

begin
  aRFEDIT.Color := clwhite;
  Arfpanel.Color := clWhite;
end;


// =============================================================================
      procedure TMNBARFOLYAM.ARFEDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)=27 then
    begin
     // _aktpanel.color := _aktcolor;
      InputPanel.Visible := false;
      _input := False;
      Activecontrol := Hideedit;
      exit;
    end;

  if ord(key)<>13 then exit;
  _aktpstring := trim(arfedit.Text);
  _aktpanel.caption := _aktpstring;
  _input := false;
  Inputpanel.Visible := false;
  Activecontrol := Hideedit;
end;

// =============================================================================
              procedure TMNBARFOLYAM.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  if _input then exit;
  CaptiontoTomb;
  Elszamadatokfelirasa;
  ModalResult := 1;
end;


// =============================================================================
               procedure TMNBArfolyam.ElszamAdatokBetoltese;
// =============================================================================

var _nap: byte;

begin

  _farok := inttostr(_kertev-2000)+MNBarfolyam.nulele(_kertHonap);
  _havielszamTablanev := 'ELSZAM'+_farok;

  _pcs := 'SELECT * FROM ' + _haviElszamTablaNev + _sorveg;

  arfdbase.connected := true;
  with ArfQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  while not Arfquery.eof do
    begin
      with ArfQuery do
        begin
          _nap := fieldbyname('NAP').asInteger;
          _datatomb[1,_nap] := FieldByName('AUD').asInteger;
          _datatomb[2,_nap]:= FieldByName('BAM').asInteger;
          _datatomb[3,_nap] := FieldByName('BGN').asInteger;
          _datatomb[4,_nap] := FieldByName('BRL').asInteger;
          _datatomb[5,_nap] := FieldByName('CAD').asInteger;
          _datatomb[6,_nap] := FieldByName('CHF').asInteger;
          _datatomb[7,_nap] := FieldByName('CNY').asInteger;
          _datatomb[8,_nap] := FieldByName('CZK').asInteger;
          _datatomb[9,_nap] := FieldByName('DKK').asInteger;
          _datatomb[10,_nap]:= FieldByName('EUR').asInteger;
          _datatomb[11,_nap]:= FieldByName('GBP').asInteger;
          _datatomb[12,_nap]:= FieldByName('HRK').asInteger;
          _datatomb[13,_nap]:= FieldByName('ILS').asInteger;
          _datatomb[14,_nap]:= FieldByName('JPY').asInteger;
          _datatomb[15,_nap]:= FieldByNAme('MXN').asInteger;
          _datatomb[16,_nap]:= FieldByName('NOK').asInteger;
          _datatomb[17,_nap]:= FieldbyName('NZD').asInteger;
          _datatomb[18,_nap]:= FieldByName('PLN').asInteger;
          _datatomb[19,_nap]:= FieldByName('RON').asInteger;
          _datatomb[20,_nap]:= FieldByName('RSD').asInteger;
          _datatomb[21,_nap]:= FieldByName('RUB').asInteger;
          _datatomb[22,_nap]:= FieldByName('SEK').asInteger;
          _datatomb[23,_nap]:= FieldByName('THB').asInteger;
          _datatomb[24,_nap]:= FieldByName('TRY').asInteger;
          _datatomb[25,_nap]:= FieldByName('UAH').asInteger;
          _datatomb[26,_nap]:= FieldByName('USD').asInteger;
        end;
      Arfquery.next;
    end;
  Arfquery.close;
  Arfdbase.close;
end;

// =============================================================================
                   procedure TMNBArfolyam.ElszamadatokFelirasa;
// =============================================================================

var _vv: byte;
    _data: integer;

begin
  _pcs := 'DELETE FROM ' + _havielszamTablaNev;
  ElszamParancs(_pcs);

  _qq := 1;
  while _qq<=31 do
    begin
      _pcs := 'INSERT INTO ' + _havielszamTablanev + ' (NAP,AUD,BAM,BGN,BRL,';
      _pcs := _pcs + 'CAD,CHF,CNY,CZK,DKK,EUR,GBP,HRK,ILS,JPY,MXN,NOK,NZD,PLN,RON,';
      _pcs := _pcs + 'RSD,RUB,SEK,THB,TRY,UAH,USD)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + inttostr(_qq)+',';
      _vv := 1;

      while _vv<=25 do
        begin
          _data := _datatomb[_vv,_qq];
          _pcs := _pcs + inttostr(_data) + ',';
          inc(_vv);
        end;

      _data := _datatomb[26,_qq];
      _pcs := _pcs + inttostr(_data)+')';
      ElszamParancs(_pcs);
      inc(_qq);
    end;
end;

// =============================================================================
           procedure TMNBArfolyam.ElszamParancs(_ukaz: string);
// =============================================================================

begin
  Arfdbase.connected := true;
  if Arftranz.InTransaction then arftranz.Commit;
  Arftranz.StartTransaction;
  with ArfQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_ukaz);
      Execsql;
    end;
  Arftranz.Commit;
  Arfdbase.close;
end;


// =============================================================================
            function TMNBArfolyam.GetTablaAdat(_aTab: TPanel): integer;
// =============================================================================

var _datas: string;
    _code: integer;

begin
  _datas := _aTab.caption;
  val(_datas,result,_code);
  if _code<>0 then result := 0;
end;


// =============================================================================
                  procedure TMNBArfolyam.CaptiontoTomb;
// =============================================================================

// Feladata: A képernyõn látható féltáblázat tömbbe (datatomb) beirása:

var _datas: string;
    _data,_code: integer;

begin
  if _oldal=1 then
    begin
      _napszam := 1;
      while _napszam<=_houtolsonap do
        begin
          _akttabla := _ap[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[1,_napszam] := _data;
          // -------------------------
         _akttabla := _bp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[2,_napszam] := _data;
          // -------------------------
         _akttabla := _cp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[3,_napszam] := _data;
          // -------------------------
         _akttabla := _dp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[4,_napszam] := _data;
          // -------------------------
         _akttabla := _ep[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[5,_napszam] := _data;
          // -------------------------
         _akttabla := _fp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[6,_napszam] := _data;
          // -------------------------
          _akttabla := _gp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[7,_napszam] := _data;
          // -------------------------
           _akttabla := _hp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[8,_napszam] := _data;
          // -------------------------
         _akttabla := _ip[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[9,_napszam] := _data;
          // -------------------------
          _akttabla := _jp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[10,_napszam] := _data;
          // -------------------------
         _akttabla := _kp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[11,_napszam] := _data;
           // -------------------------
          _akttabla := _lp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[12,_napszam] := _data;
          // -------------------------
          _akttabla := _Mp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[13,_napszam] := _data;

          inc(_napszam);
        end;
    end else
    begin
      _Napszam := 1;
      while _napszam<=_houtolsonap do
        begin
          _akttabla := _ap[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[14,_napszam] := _data;
          // -------------------------
         _akttabla := _bp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[15,_napszam] := _data;
          // -------------------------
         _akttabla := _cp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[16,_napszam] := _data;
          // -------------------------
         _akttabla := _dp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[17,_napszam] := _data;
          // -------------------------
         _akttabla := _ep[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[18,_napszam] := _data;
          // -------------------------
         _akttabla := _fp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[19,_napszam] := _data;
          // -------------------------
          _akttabla := _gp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[20,_napszam] := _data;
          // -------------------------
           _akttabla := _hp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[21,_napszam] := _data;
          // -------------------------
         _akttabla := _ip[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[22,_napszam] := _data;
          // -------------------------
          _akttabla := _jp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[23,_napszam] := _data;
           // -------------------------
          _akttabla := _Kp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[24,_napszam] := _data;
          // -------------------------
          _akttabla := _Lp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[25,_napszam] := _data;
          // -------------------------
          _akttabla := _Mp[_napszam];
          _datas := _aktTabla.caption;
          val(_datas,_data,_code);
          if _code<>0 then _data := 0;
          _datatomb[26,_napszam] := _data;

          inc(_napszam);
        end;
    end;
end;


// =============================================================================
              procedure TMNBarfolyam.SetSorOszlop(_pnev:string);
// =============================================================================

var _asc: byte;

begin
  _aktpanelsor := strtoint(midstr(_pnev,2,length(_pnev)-1));
  _asc := ord(_pnev[1]);

  If _asc>90 then _asc := _asc - 32;
  _aktPanelOszlop := _asc-64;
end;



// =============================================================================
      procedure TMNBARFOLYAM.HIDEEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

var _bill: integer;
    _fnev: string;

begin
  if _input then exit;

  _bill := ord(key);
  case _bill of
    39: begin
          if _pirospanel=Nil then exit;
          _pirospanel.Color := _aktcolor;
          _pirospanel.Font.Style := [fsItalic];
          _pirospanel.Font.color := clBlack;
          _pirosPanel := GetRightPanel;
          if _pirospanel=Nil then exit;

          _aktcolor := _pirospanel.color;
          _pirospanel.Color := clred;
          _pirospanel.Font.style := [fsBold,fsItalic];
          _pirospanel.Font.Color := clWhite;
          _fnev := _pirospanel.name;
          Setsoroszlop(_fnev);
        end;

    37: begin
          if _pirospanel=Nil then exit;
          _pirospanel.Color := _aktcolor;
          _pirospanel.Font.Style := [fsItalic];
          _pirospanel.Font.color := clBlack;
          _pirosPanel := GetLeftPanel;
          if _pirospanel=Nil then exit;

          _aktcolor := _pirospanel.color;
          _pirospanel.Color := clred;
          _pirospanel.Font.style := [fsBold,fsItalic];
          _pirospanel.Font.Color := clWhite;
          _fnev := _pirospanel.name;
          Setsoroszlop(_fnev);
        end;

     38: begin    // fel
          if _pirospanel=Nil then exit;
          if _aktpanelsor=1 then exit;

          _pirospanel.Color := _aktcolor;
          _pirospanel.Font.Style := [fsItalic];
          _pirospanel.Font.color := clBlack;
          _pirosPanel := GetUpPanel;
          if _pirospanel=Nil then exit;

          _aktcolor := _pirospanel.color;
          _pirospanel.Color := clred;
          _pirospanel.Font.style := [fsBold,fsItalic];
          _pirospanel.Font.Color := clWhite;
          _fnev := _pirospanel.name;
          Setsoroszlop(_fnev);
        end;

      40: begin    // lefele

          if _pirospanel=Nil then exit;
          if _aktpanelsor=_hoUtolsonap then exit;

          _pirospanel.Color := _aktcolor;
          _pirospanel.Font.Style := [fsItalic];
          _pirospanel.Font.color := clBlack;
          _pirosPanel := GetDownPanel;
          if _pirospanel=Nil then exit;

          _aktcolor := _pirospanel.color;
          _pirospanel.Color := clred;
          _pirospanel.Font.style := [fsBold,fsItalic];
          _pirospanel.Font.Color := clWhite;
          _fnev := _pirospanel.name;
          Setsoroszlop(_fnev);
        end;

     13: begin
           _aktpanel := _pirosPanel;
           Adatbeiras;
           exit;
         end;

  end;
 Activecontrol := Hideedit;

end;

// =============================================================================
                  function TMNBArfolyam.GetRightPanel: TPanel;
// =============================================================================

begin
  result := Nil;
  if _aktpaneloszlop<=12 then
    begin
      case _aktpaneloszlop of
         1: result := _bp[_aktpanelsor];
         2: result := _cp[_aktpanelsor];
         3: result := _dp[_aktpanelsor];
         4: result := _ep[_aktpanelsor];
         5: result := _fp[_aktpanelsor];
         6: result := _gp[_aktpanelsor];
         7: result := _hp[_aktpanelsor];
         8: result := _ip[_aktpanelsor];
         9: result := _jp[_aktpanelsor];
        10: result := _kp[_aktpanelsor];
        11: result := _lp[_aktpanelsor];
        12: result := _mp[_aktpanelsor];
      end;
      exit;
    end;

  
  OLDALVALTOGOMBClick(Nil);
  result := _ap[_aktpanelsor];
end;

// =============================================================================
                   function TMNBArfolyam.GetLeftPanel: TPanel;
// =============================================================================

begin
  result := Nil;
  if _aktpaneloszlop>1 then
    begin
      case _aktpaneloszlop of
         2: result := _ap[_aktpanelsor];
         3: result := _bp[_aktpanelsor];
         4: result := _cp[_aktpanelsor];
         5: result := _dp[_aktpanelsor];
         6: result := _ep[_aktpanelsor];
         7: result := _fp[_aktpanelsor];
         8: result := _gp[_aktpanelsor];
         9: result := _hp[_aktpanelsor];
        10: result := _ip[_aktpanelsor];
        11: result := _jp[_aktpanelsor];
        12: result := _kp[_aktpanelsor];
        13: result := _lp[_aktpanelsor];
      end;
      exit;
    end;

  if (_aktpaneloszlop=1) then
    begin
      OLDALVALTOGOMBClick(Nil);
      result := _Mp[_aktpanelsor];
    end;
end;

// =============================================================================
                   function TMNBArfolyam.GetUpPanel: TPanel;
// =============================================================================

begin
  result := Nil;
  if _aktpanelsor>1 then
    begin
      dec(_aktpanelsor);
      case _aktpaneloszlop of
         1: result := _ap[_aktpanelsor];
         2: result := _bp[_aktpanelsor];
         3: result := _cp[_aktpanelsor];
         4: result := _dp[_aktpanelsor];
         5: result := _ep[_aktpanelsor];
         6: result := _fp[_aktpanelsor];
         7: result := _gp[_aktpanelsor];
         8: result := _hp[_aktpanelsor];
         9: result := _ip[_aktpanelsor];
        10: result := _jp[_aktpanelsor];
        11: result := _kp[_aktpanelsor];
        12: result := _Lp[_aktpanelsor];
        13: result := _Mp[_aktpanelsor];
      end;
      exit;
    end;
end;


// =============================================================================
                   function TMNBArfolyam.GetDownPanel: TPanel;
// =============================================================================

begin
  result := Nil;
  if _aktpanelsor<_Houtolsonap then
    begin
      inc(_aktpanelsor);
      case _aktpaneloszlop of
         1: result := _ap[_aktpanelsor];
         2: result := _bp[_aktpanelsor];
         3: result := _cp[_aktpanelsor];
         4: result := _dp[_aktpanelsor];
         5: result := _ep[_aktpanelsor];
         6: result := _fp[_aktpanelsor];
         7: result := _gp[_aktpanelsor];
         8: result := _hp[_aktpanelsor];
         9: result := _ip[_aktpanelsor];
        10: result := _jp[_aktpanelsor];
        11: result := _kp[_aktpanelsor];
        12: result := _Lp[_aktpanelsor];
        13: result := _Mp[_aktpanelsor];
      end;
      exit;
    end;
end;

// =============================================================================
                procedure TMNBARFOLYAM.AdatBeiras;
// =============================================================================

var
    _aktpanelnev: string;
    _pantop,_panleft,_itop,_ileft: word;

begin
  if _input then exit;

  if _pirospanel<>Nil then
    begin
      _pirospanel.Color := _aktColor;
      _pirosPanel.Font.Style := [fsItalic];
      _pirosPanel.Font.Color := clBlack;
    end;

 // _aktPanel    := Tpanel(sender);
  _aktPanelNev := _aktpanel.Name;
  _aktcolor    := _aktpanel.color;
  _aktpstring  := _aktPanel.caption;

  SetsorOszlop(_aktpanelnev);

  _pantop := 104 + trunc(24*_aktpanelsor);
  _panleft:= 104 + trunc(96*_aktPanelOszlop);

  _iTop  := _pantop-24;

  if _fenn then _iTop := _iTop - 220;

  _iLeft := _panLeft + 64;
  if _ileft>1120 then _iLeft := 1120;
  Arfedit.Text := _aktpstring;
  with InputPanel do
    begin
      Top := _itop;
      Left := _iLeft;
      Visible := true;
      _input := true;
    end;

  _aktpanel.Color := clRed;
  _aktpanel.Font.Style := [fsBold,fsItalic];
  _aktpanel.Font.Color := clWhite;
  _pirospanel := _aktpanel;
  ActiveControl := Arfedit;
end;

// =============================================================================
              procedure TMNBARFOLYAM.FELGOMBClick(Sender: TObject);
// =============================================================================

var i: integer;

begin
  if _input then exit;
  Felgomb.Enabled := false;
  for i := 1 to 13 do
    begin
      _op[i].Top := -176;
      _vp[i].Top := 221;
      _tp[i].Top := 279;
    end;
  o0.Top := -176;
  evpanel.Top := 221;
  Legomb.Enabled := True;
  _fenn := true;
  Alsofuggony.Top := _ftop-217;
end;

// =============================================================================
               procedure TMNBARFOLYAM.LEGOMBClick(Sender: TObject);
// =============================================================================

var i: integer;

begin
  if _input then exit;
  Legomb.Enabled := false;
  for i := 1 to 13 do
    begin
      _op[i].Top := 40;
      _vp[i].Top := 8;
      _tp[i].Top := 66;
    end;
  o0.Top := 40;
  evpanel.Top := 8;
  Felgomb.Enabled := True;
  _fenn := False;
  Alsofuggony.Top := _ftop;

end;

// =============================================================================
                 procedure TMNBARFOLYAM.n1Click(Sender: TObject);
// =============================================================================

var _szin: TColor;
    _vasarnap,_minta: integer;
begin

  // Ha a nap nem rózsaszín, akkor az nem vasárnap
  _szin := Tpanel(sender).color;
  if _szin=$B0FFFF then exit;

  _vasarnap := Tpanel(Sender).Tag;

  // Nincs péntek a képen:
  if _vasarnap<3 then exit;

  _minta := _vasarnap-2;
  _ap[_minta+1].caption := _ap[_minta].caption;
  _ap[_minta+2].Caption := _ap[_minta].caption;

  _bp[_minta+1].caption := _bp[_minta].caption;
  _bp[_minta+2].Caption := _bp[_minta].caption;

  _cp[_minta+1].caption := _cp[_minta].caption;
  _cp[_minta+2].Caption := _cp[_minta].caption;

  _dp[_minta+1].caption := _dp[_minta].caption;
  _dp[_minta+2].Caption := _dp[_minta].caption;

  _ep[_minta+1].caption := _ep[_minta].caption;
  _ep[_minta+2].Caption := _ep[_minta].caption;

  _fp[_minta+1].caption := _fp[_minta].caption;
  _fp[_minta+2].Caption := _fp[_minta].caption;

  _gp[_minta+1].caption := _gp[_minta].caption;
  _gp[_minta+2].Caption := _gp[_minta].caption;

  _hp[_minta+1].caption := _hp[_minta].caption;
  _hp[_minta+2].Caption := _hp[_minta].caption;

  _ip[_minta+1].caption := _ip[_minta].caption;
  _ip[_minta+2].Caption := _ip[_minta].caption;

  _jp[_minta+1].caption := _jp[_minta].caption;
  _jp[_minta+2].Caption := _jp[_minta].caption;

  if _oldal=1 then
    begin
      _kp[_minta+1].caption := _kp[_minta].caption;
      _kp[_minta+2].Caption := _kp[_minta].caption;
    end;
end;





end.


