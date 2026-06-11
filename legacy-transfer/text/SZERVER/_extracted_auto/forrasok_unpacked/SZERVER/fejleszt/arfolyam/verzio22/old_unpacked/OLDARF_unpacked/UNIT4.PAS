unit Unit4;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, unit1, Printers;

type

  TNyomtatoForm = class(TForm)

    BS1      : TPanel;
    BS3      : TPanel;
    BS5      : TPanel;
    BS8      : TPanel;
    BS10     : TPanel;
    BS11     : TPanel;
    BS12     : TPanel;
    BS13     : TPanel;
    BS14     : TPanel;
    BS15     : TPanel;
    BS16     : TPanel;
    BS17     : TPanel;
    BS18     : TPanel;
    BS19     : TPanel;
    BS20     : TPanel;
    BV1      : TPanel;
    BV2      : TPanel;
    BV12     : TPanel;
    BV18     : TPanel;
    BV19     : TPanel;
    BV20     : TPanel;
    D1       : TPanel;
    D2       : TPanel;
    E1       : TPanel;
    E2       : TPanel;
    E3       : TPanel;
    E4       : TPanel;
    E5       : TPanel;
    E6       : TPanel;
    E7       : TPanel;
    E8       : TPanel;
    E9       : TPanel;
    E10      : TPanel;
    E11      : TPanel;
    E12      : TPanel;
    E13      : TPanel;
    E14      : TPanel;
    E15      : TPanel;
    E16      : TPanel;
    E17      : TPanel;
    E18      : TPanel;
    E19      : TPanel;
    E20      : TPanel;
    Panel1   : TPanel;
    Panel2   : TPanel;
    Panel3   : TPanel;
    Panel4   : TPanel;
    Panel5   : TPanel;
    Panel6   : TPanel;
    Panel8   : TPanel;
    Panel9   : TPanel;
    Panel7   : TPanel;
    Panel10  : TPanel;
    Panel11  : TPanel;
    Panel12  : TPanel;
    Panel13  : TPanel;
    Panel14  : TPanel;
    Panel67  : TPanel;
    Panel77  : TPanel;
    Panel86  : TPanel;
    Panel87  : TPanel;
    Panel88  : TPanel;
    Panel89  : TPanel;
    Panel90  : TPanel;
    Panel91  : TPanel;
    Panel92  : TPanel;
    Panel93  : TPanel;
    Panel94  : TPanel;
    Panel95  : TPanel;
    Panel96  : TPanel;
    Panel97  : TPanel;
    Panel98  : TPanel;
    Panel99  : TPanel;
    Panel100 : TPanel;

    Label1   : TLabel;
    Label2   : TLabel;
    Label3   : TLabel;
    Label4   : TLabel;
    Label5   : TLabel;

    BS4      : TPanel;
    BS6      : TPanel;
    BS7      : TPanel;
    BS2      : TPanel;
    BS9      : TPanel;

    BV3      : TPanel;
    BV4      : TPanel;
    BV5      : TPanel;
    BV6      : TPanel;
    BV7      : TPanel;
    BV8      : TPanel;
    BV9      : TPanel;
    BV10     : TPanel;
    BV11     : TPanel;
    BV13     : TPanel;
    BV14     : TPanel;
    BV15     : TPanel;
    BV16     : TPanel;
    BV17     : TPanel;

    D3       : TPanel;
    D4       : TPanel;
    D5       : TPanel;
    D6       : TPanel;
    D7       : TPanel;
    D8       : TPanel;
    D9       : TPanel;
    D10      : TPanel;
    D11      : TPanel;
    D12      : TPanel;
    D13      : TPanel;
    D14      : TPanel;
    D15      : TPanel;
    D16      : TPanel;
    D17      : TPanel;
    D18      : TPanel;
    D19      : TPanel;
    D20      : TPanel;

    S1       : TPanel;
    S2       : TPanel;
    S3       : TPanel;
    S4       : TPanel;
    S5       : TPanel;
    S6       : TPanel;
    S7       : TPanel;
    S8       : TPanel;
    S9       : TPanel;
    S10      : TPanel;
    S11      : TPanel;
    S12      : TPanel;
    S13      : TPanel;
    S14      : TPanel;
    S15      : TPanel;
    S16      : TPanel;
    S17      : TPanel;
    S18      : TPanel;
    S19      : TPanel;
    S20      : TPanel;

    US1      : TPanel;
    US2      : TPanel;
    US3      : TPanel;
    US4      : TPanel;
    US5      : TPanel;
    US6      : TPanel;
    US7      : TPanel;
    US8      : TPanel;
    US9      : TPanel;
    US10     : TPanel;
    US11     : TPanel;
    US12     : TPanel;
    US13     : TPanel;
    US14     : TPanel;
    US15     : TPanel;
    US16     : TPanel;
    US17     : TPanel;
    US18     : TPanel;
    US19     : TPanel;
    US20     : TPanel;

    UV1      : TPanel;
    UV2      : TPanel;
    UV3      : TPanel;
    UV4      : TPanel;
    UV5      : TPanel;
    UV6      : TPanel;
    UV7      : TPanel;
    UV8      : TPanel;
    UV9      : TPanel;
    UV10     : TPanel;
    UV11     : TPanel;
    UV12     : TPanel;
    UV13     : TPanel;
    UV14     : TPanel;
    UV15     : TPanel;
    UV16     : TPanel;
    UV17     : TPanel;
    UV18     : TPanel;
    UV19     : TPanel;
    UV20     : TPanel;

    V1       : TPanel;
    V2       : TPanel;
    V3       : TPanel;
    V4       : TPanel;
    V5       : TPanel;
    V6       : TPanel;
    V7       : TPanel;
    V8       : TPanel;
    V9       : TPanel;
    V10      : TPanel;
    V11      : TPanel;
    V12      : TPanel;
    V13      : TPanel;
    V14      : TPanel;
    V15      : TPanel;
    V16      : TPanel;
    V17      : TPanel;
    V18      : TPanel;
    V19      : TPanel;
    V20      : TPanel;

    Panel102 : TPanel;
    Panel103 : TPanel;
    Panel104 : TPanel;

    Kilepo   : TTimer;

    PrintDialog1: TPrintDialog;
    K1PANEL: TPanel;
    K2PANEL: TPanel;
    K5PANEL: TPanel;
    Panel18: TPanel;
    K3PANEL: TPanel;
    K4PANEL: TPanel;

    procedure FormActivate(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  NyomtatoForm: TNyomtatoForm;

  _aktPanel: Tpanel;


  _ye,
  _yd,
  _yv,
  _ys,
  _yuv,
  _yus,
  _ybv,
  _ybs: array[1..20] of TPanel;

  _aktlista: TListbox;

  _peldany : integer;

implementation

{$R *.dfm}


// ================================================================
        procedure TNyomtatoForm.FormActivate(Sender: TObject);
// ================================================================

//var
//    _k1,_k2,_k3,_k4,_k5: real;

begin
  Top    := _top;
  Left   := _left;
  Height := 729;
  Width  := 1024;

  (*
  _ye[ 1] := E1;
  _ye[ 2] := E2;
  _ye[ 3] := E3;
  _ye[ 4] := E4;
  _ye[ 5] := E5;
  _ye[ 6] := E6;
  _ye[ 7] := E7;
  _ye[ 8] := E8;
  _ye[ 9] := E9;
  _ye[10] := E10;
  _ye[11] := E11;
  _ye[12] := E12;
  _ye[13] := E13;
  _ye[14] := E14;
  _ye[15] := E15;
  _ye[16] := E16;
  _ye[17] := E17;
  _ye[18] := E18;
  _ye[19] := E19;
  _ye[20] := E20;

  _yD[ 1] := D1;
  _yD[ 2] := D2;
  _yD[ 3] := D3;
  _yD[ 4] := D4;
  _yD[ 5] := D5;
  _yD[ 6] := D6;
  _yD[ 7] := D7;
  _yD[ 8] := D8;
  _yD[ 9] := D9;
  _yD[10] := D10;
  _yD[11] := D11;
  _yD[12] := D12;
  _yD[13] := D13;
  _yD[14] := D14;
  _yD[15] := D15;
  _yD[16] := D16;
  _yD[17] := D17;
  _yD[18] := D18;
  _yD[19] := D19;
  _yD[20] := D20;

  _yV[ 1] := V1;
  _yV[ 2] := V2;
  _yV[ 3] := V3;
  _yV[ 4] := V4;
  _yV[ 5] := V5;
  _yV[ 6] := V6;
  _yV[ 7] := V7;
  _yV[ 8] := V8;
  _yV[ 9] := V9;
  _yV[10] := V10;
  _yV[11] := V11;
  _yV[12] := V12;
  _yV[13] := V13;
  _yV[14] := V14;
  _yV[15] := V15;
  _yV[16] := V16;
  _yV[17] := V17;
  _yV[18] := V18;
  _yV[19] := V19;
  _yV[20] := V20;

  _yS[ 1] := S1;
  _yS[ 2] := S2;
  _yS[ 3] := S3;
  _yS[ 4] := S4;
  _yS[ 5] := S5;
  _yS[ 6] := S6;
  _yS[ 7] := S7;
  _yS[ 8] := S8;
  _yS[ 9] := S9;
  _yS[10] := S10;
  _yS[11] := S11;
  _yS[12] := S12;
  _yS[13] := S13;
  _yS[14] := S14;
  _yS[15] := S15;
  _yS[16] := S16;
  _yS[17] := S17;
  _yS[18] := S18;
  _yS[19] := S19;
  _yS[20] := S20;

  _yUV[ 1] := UV1;
  _yUV[ 2] := UV2;
  _yUV[ 3] := UV3;
  _yUV[ 4] := UV4;
  _yUV[ 5] := UV5;
  _yUV[ 6] := UV6;
  _yUV[ 7] := UV7;
  _yUV[ 8] := UV8;
  _yUV[ 9] := UV9;
  _yUV[10] := UV10;
  _yUV[11] := UV11;
  _yUV[12] := UV12;
  _yUV[13] := UV13;
  _yUV[14] := UV14;
  _yUV[15] := UV15;
  _yUV[16] := UV16;
  _yUV[17] := UV17;
  _yUV[18] := UV18;
  _yUV[19] := UV19;
  _yUV[20] := UV20;

  _yUS[ 1] := US1;
  _yUS[ 2] := US2;
  _yUS[ 3] := US3;
  _yUS[ 4] := US4;
  _yUS[ 5] := US5;
  _yUS[ 6] := US6;
  _yUS[ 7] := US7;
  _yUS[ 8] := US8;
  _yUS[ 9] := US9;
  _yUS[10] := US10;
  _yUS[11] := US11;
  _yUS[12] := US12;
  _yUS[13] := US13;
  _yUS[14] := US14;
  _yUS[15] := US15;
  _yUS[16] := US16;
  _yUS[17] := US17;
  _yUS[18] := US18;
  _yUS[19] := US19;
  _yUS[20] := US20;

  _yBV[ 1] := BV1;
  _yBV[ 2] := BV2;
  _yBV[ 3] := BV3;
  _yBV[ 4] := BV4;
  _yBV[ 5] := BV5;
  _yBV[ 6] := BV6;
  _yBV[ 7] := BV7;
  _yBV[ 8] := BV8;
  _yBV[ 9] := BV9;
  _yBV[10] := BV10;
  _yBV[11] := BV11;
  _yBV[12] := BV12;
  _yBV[13] := BV13;
  _yBV[14] := BV14;
  _yBV[15] := BV15;
  _yBV[16] := BV16;
  _yBV[17] := BV17;
  _yBV[18] := BV18;
  _yBV[19] := BV19;
  _yBV[20] := BV20;

  _yBS[ 1] := BS1;
  _yBS[ 2] := BS2;
  _yBS[ 3] := BS3;
  _yBS[ 4] := BS4;
  _yBS[ 5] := BS5;
  _yBS[ 6] := BS6;
  _yBS[ 7] := BS7;
  _yBS[ 8] := BS8;
  _yBS[ 9] := BS9;
  _yBS[10] := BS10;
  _yBS[11] := BS11;
  _yBS[12] := BS12;
  _yBS[13] := BS13;
  _yBS[14] := BS14;
  _yBS[15] := BS15;
  _yBS[16] := BS16;
  _yBS[17] := BS17;
  _yBS[18] := BS18;
  _yBS[19] := BS19;
  _yBS[20] := BS20;

  for _sor := 1 to 20 do
    begin
      _aktpanel := _ye[_sor];
      _aktpanel.caption := '';
      _aktpanel := _yd[_sor];
      _aktpanel.caption := '';
      _aktpanel := _yv[_sor];
      _aktpanel.caption := '';
      _aktpanel := _ys[_sor];
      _aktpanel.caption := '';
      _aktpanel := _yuv[_sor];
      _aktpanel.caption := '';
      _aktpanel := _yus[_sor];
      _aktpanel.caption := '';
      _aktpanel := _ybv[_sor];
      _aktpanel.caption := '';
      _aktpanel := _ybs[_sor];
      _aktpanel.caption := '';
    end;


  for _sor := 1 to 20 do
    begin
      _ye[_sor].caption  := _jErtek[_aktcsoport,_sor];
      _yd[_sor].Caption  := _dnem[_sor];
      _yv[_sor].caption  := _av[_aktcsoport,_sor];
      _ys[_sor].caption  := _ae[_aktcsoport,_sor];
      _yuv[_sor].caption := _uv[_aktcsoport,_sor];
      _yus[_sor].caption := _ue[_aktcsoport,_sor];
      _ybv[_sor].caption := _bv[_aktcsoport,_sor];
      _ybs[_sor].caption := _be[_aktcsoport,_sor];
    end;

  _K1 := (1000*_klimit[_aktcsoport,1])+1;
  _k2 := (1000*_klimit[_aktcsoport,2]);
  _k3 := (1000*_klimit[_aktcsoport,2])+1;
  _k4 := (1000*_klimit[_aktcsoport,3]);
  _k5 := (1000*_klimit[_aktcsoport,3])+1;

  K1Panel.Caption := formatfloat('### ### ###',_k1)+' -';
  k2Panel.Caption := FormatFloat('### ### ###',_k2);

  K3Panel.Caption := formatfloat('### ### ###',_k3)+' -';
  k4Panel.Caption := FormatFloat('### ### ###',_k4);
  
  k5Panel.Caption := FormatFloat('### ### ###',_k5)+' -';




  if printDialog1.Execute then
    begin
      Printer.Orientation := poLandscape;
      Print;
    end;

  *)
  Kilepo.enabled := True;

end;

// ================================================================
        procedure TNyomtatoForm.KilepoTimer(Sender: TObject);
// ================================================================


begin

  Kilepo.Enabled := false;
  ModalResult := 1;
end;

end.
