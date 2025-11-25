unit Unit12;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, strutils, Buttons, unit1;

type
  TSelectCounty = class(TForm)
    Vaszon      : TPaintBox;
    EscapeGomb  : TBitBtn;
    Panel1      : TPanel;
    Panel2      : TPanel;
    ValasztoGomb: TBitBtn;

    procedure AllCounty;
    procedure EscapeGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FillPolygon(ACanvas: TCanvas; APoints: array of TPoint);
    procedure Settombok;
    procedure Tombtotomb(_st: byte);
    procedure VaszonMouseDown(Sender: TObject; Button: TMouseButton;Shift: TShiftState; X, Y: Integer);
    procedure ValasztoGombClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SelectCounty: TSelectCounty;

  _meg    : array[0..18,0..60] of TPoint;
  _akttomb: array[0..60] of TPoint;
  _z      : integer;

  Acolor: TColor;

  _coltomb: array[0..18] of TCOlor = ($ffb0ff,$B0FFFF,$b0ffff,$FFFFB0,$FFFFB0,
      $FFB0FF,$FFB0FF,CLWHITE,$b0ffFF,$FFB0FF,$b0ffff,$ffB0ff,$FFFFB0,
      $FFFFB0,$FFB0FF,CLwHITE,$b0ffFF,clWhite,$FFB0FF);


type
  TRange = packed record
    X: Integer;
    Count: Word;
  end;

   TRangeList = array of TRange;
   TRangeListArray = array of TRangeList;

type
  pRangeItem = ^TRangeItem;
  TRangeItem = record
    X: Integer;
    Up: Boolean;
    Next: pRangeItem;
  end;


  function Polygon_GetBounds(const Points: array of TPoint): TRect;
  function Polygon_PtInside(const Points: array of TPoint; Pt: TPoint): Boolean;
  procedure Polygon_GetFillRange(const Points: array of TPoint; Y: Integer;
                                                   out ARangeList: TRangeList);

implementation

{$R *.dfm}


// =============================================================================
              procedure TSelectCounty.FormActivate(Sender: TObject);
// =============================================================================

var i,j,_x,_y: integer;

begin
  Top := _top +205;
  Left := _Left + 275;
  ValasztoGomb.Enabled := False;
  Settombok;
  for i := 0 to 18 do
    begin
      for j := 0 to 60 do
        begin
          _x := _meg[i,j].X;
          _y := _meg[i,j].Y;
          _meg[i,j] := Point(trunc(1.5*_x),trunc(1.5*_y));
        end;
    end;
  Allcounty;

end;

// =============================================================================
                      procedure TSelectCounty.Allcounty;
// =============================================================================

var _n: byte;
    _color: tcOLOR;
begin
  for _n := 0 to 18 do
    begin
      TombtoTomb(_n);
      _color := _coltomb[_n];
      Vaszon.Canvas.Brush.Color := _color;
      Vaszon.Canvas.Polygon(_akttomb);
    end;
end;

// =============================================================================
               procedure TSelectCounty.tombtotomb(_st: byte);
// =============================================================================

var i: byte;

begin
  for i := 0 to 60 do _akttomb[i] := _meg[_st,i];
end;

// =========================================================================
                          procedure TSelectCounty.Settombok;
// =========================================================================

begin

   _meg[0,0] := Point(159,228);
   _meg[0,1] := Point(160,230);
   _meg[0,2] := Point(159,232);
   _meg[0,3] := Point(165,231);
   _meg[0,4] := Point(171,229);
   _meg[0,5] := Point(176,222);
   _meg[0,6] := Point(182,225);
   _meg[0,7] := Point(195,218);
   _meg[0,8] := Point(200,210);
   _meg[0,9] := Point(204,210);
   _meg[0,10] := Point(208,210);
   _meg[0,11] := Point(205,201);
   _meg[0,12] := Point(206,194);
   _meg[0,13] := Point(211,194);
   _meg[0,14] := Point(216,190);
   _meg[0,15] := Point(217,186);
   _meg[0,16] := Point(219,182);
   _meg[0,17] := Point(213,179);
   _meg[0,18] := Point(218,175);
   _meg[0,19] := Point(222,176);
   _meg[0,20] := Point(224,161);
   _meg[0,21] := Point(228,155);
   _meg[0,22] := Point(226,150);
   _meg[0,23] := Point(231,146);
   _meg[0,24] := Point(230,141);
   _meg[0,25] := Point(230,139);
   _meg[0,26] := Point(230,138);
   _meg[0,27] := Point(225,139);
   _meg[0,28] := Point(220,140);
   _meg[0,29] := Point(216,138);
   _meg[0,30] := Point(213,142);
   _meg[0,31] := Point(210,142);
   _meg[0,32] := Point(206,141);
   _meg[0,33] := Point(203,136);
   _meg[0,34] := Point(200,130);
   _meg[0,35] := Point(197,130);
   _meg[0,36] := Point(195,130);
   _meg[0,37] := Point(192,136);
   _meg[0,38] := Point(188,136);
   _meg[0,39] := Point(186,138);
   _meg[0,40] := Point(184,140);
   _meg[0,41] := Point(188,131);
   _meg[0,42] := Point(180,128);
   _meg[0,43] := Point(178,133);
   _meg[0,44] := Point(170,138);
   _meg[0,45] := Point(162,138);
   _meg[0,46] := Point(165,145);
   _meg[0,47] := Point(161,153);
   _meg[0,48] := Point(166,165);
   _meg[0,49] := Point(159,172);
   _meg[0,50] := Point(161,185);
   _meg[0,51] := Point(160,188);
   _meg[0,52] := Point(162,201);
   _meg[0,53] := Point(156,205);
   _meg[0,54] := Point(160,208);
   _meg[0,55] := Point(156,212);
   _meg[0,56] := Point(157,214);
   _meg[0,57] := Point(156,215);
   _meg[0,58] := Point(158,220);
   _meg[0,59] := Point(160,223);
   _meg[0,60] := Point(159,228);

   // ----------------------------------

    _meg[1,0] := Point(94,236);
   _meg[1,1] := Point(93,233);
   _meg[1,2] := Point(92,230);
   _meg[1,3] := Point(88,220);
   _meg[1,4] := Point(89,219);
   _meg[1,5] := Point(90,218);
   _meg[1,6] := Point(90,215);
   _meg[1,7] := Point(91,214);
   _meg[1,8] := Point(91,212);
   _meg[1,9] := Point(90,210);
   _meg[1,10] := Point(92,208);
   _meg[1,11] := Point(92,205);
   _meg[1,12] := Point(95,207);
   _meg[1,13] := Point(97,205);
   _meg[1,14] := Point(100,206);
   _meg[1,15] := Point(102,205);
   _meg[1,16] := Point(104,205);
   _meg[1,17] := Point(106,200);
   _meg[1,18] := Point(113,198);
   _meg[1,19] := Point(115,198);
   _meg[1,20] := Point(120,196);
   _meg[1,21] := Point(120,192);
   _meg[1,22] := Point(124,191);
   _meg[1,23] := Point(128,190);
   _meg[1,24] := Point(129,194);
   _meg[1,25] := Point(131,194);
   _meg[1,26] := Point(130,197);
   _meg[1,27] := Point(131,201);
   _meg[1,28] := Point(129,204);
   _meg[1,29] := Point(130,206);
   _meg[1,30] := Point(133,205);
   _meg[1,31] := Point(135,204);
   _meg[1,32] := Point(136,202);
   _meg[1,33] := Point(136,200);
   _meg[1,34] := Point(140,203);
   _meg[1,35] := Point(140,204);
   _meg[1,36] := Point(140,205);
   _meg[1,37] := Point(143,206);
   _meg[1,38] := Point(143,210);
   _meg[1,39] := Point(144,210);
   _meg[1,40] := Point(145,210);
   _meg[1,41] := Point(146,210);
   _meg[1,42] := Point(157,214);
   _meg[1,43] := Point(156,215);
   _meg[1,44] := Point(158,220);
   _meg[1,45] := Point(159,222);
   _meg[1,46] := Point(160,223);
   _meg[1,47] := Point(159,228);
   _meg[1,48] := Point(154,228);
   _meg[1,49] := Point(148,228);
   _meg[1,50] := Point(147,231);
   _meg[1,51] := Point(146,235);
   _meg[1,52] := Point(136,241);
   _meg[1,53] := Point(131,241);
   _meg[1,54] := Point(128,241);
   _meg[1,55] := Point(126,241);
   _meg[1,56] := Point(113,240);
   _meg[1,57] := Point(106,238);
   _meg[1,58] := Point(99,237);
   _meg[1,59] := Point(96,236);
   _meg[1,60] := Point(94,236);

   // -------------------------------



   _meg[2,0] := Point(272,200);
   _meg[2,1] := Point(274,199);
   _meg[2,2] := Point(276,198);
   _meg[2,3] := Point(284,199);
   _meg[2,4] := Point(292,200);
   _meg[2,5] := Point(295,196);
   _meg[2,6] := Point(298,193);
   _meg[2,7] := Point(299,187);
   _meg[2,8] := Point(302,187);
   _meg[2,9] := Point(305,186);
   _meg[2,10] := Point(306,183);
   _meg[2,11] := Point(302,179);
   _meg[2,12] := Point(304,174);
   _meg[2,13] := Point(306,169);
   _meg[2,14] := Point(311,165);
   _meg[2,15] := Point(311,163);
   _meg[2,16] := Point(311,162);
   _meg[2,17] := Point(316,161);
   _meg[2,18] := Point(315,157);
   _meg[2,19] := Point(314,154);
   _meg[2,20] := Point(324,137);
   _meg[2,21] := Point(323,132);
   _meg[2,22] := Point(319,133);
   _meg[2,23] := Point(316,135);
   _meg[2,24] := Point(315,140);
   _meg[2,25] := Point(310,141);
   _meg[2,26] := Point(306,142);
   _meg[2,27] := Point(306,140);
   _meg[2,28] := Point(306,138);
   _meg[2,29] := Point(289,138);
   _meg[2,30] := Point(294,132);
   _meg[2,31] := Point(289,129);
   _meg[2,32] := Point(289,125);
   _meg[2,33] := Point(281,117);
   _meg[2,34] := Point(276,122);
   _meg[2,35] := Point(273,123);
   _meg[2,36] := Point(271,125);
   _meg[2,37] := Point(271,129);
   _meg[2,38] := Point(271,133);
   _meg[2,39] := Point(263,136);
   _meg[2,40] := Point(265,145);
   _meg[2,41] := Point(257,146);
   _meg[2,42] := Point(250,147);
   _meg[2,43] := Point(248,145);
   _meg[2,44] := Point(250,155);
   _meg[2,45] := Point(254,156);
   _meg[2,46] := Point(258,158);
   _meg[2,47] := Point(260,165);
   _meg[2,48] := Point(259,166);
   _meg[2,49] := Point(258,166);
   _meg[2,50] := Point(256,167);
   _meg[2,51] := Point(260,178);
   _meg[2,52] := Point(259,182);
   _meg[2,53] := Point(259,185);
   _meg[2,54] := Point(256,190);
   _meg[2,55] := Point(260,193);
   _meg[2,56] := Point(264,192);
   _meg[2,57] := Point(268,190);
   _meg[2,58] := Point(268,194);
   _meg[2,59] := Point(270,199);
   _meg[2,60] := Point(272,200);

   // -------------------------------

   _meg[3,0] := Point(226,42);
   _meg[3,1] := Point(230,41);
   _meg[3,2] := Point(232,46);
   _meg[3,3] := Point(238,43);
   _meg[3,4] := Point(241,46);
   _meg[3,5] := Point(244,40);
   _meg[3,6] := Point(249,43);
   _meg[3,7] := Point(247,48);
   _meg[3,8] := Point(250,50);
   _meg[3,9] := Point(248,57);
   _meg[3,10] := Point(252,62);
   _meg[3,11] := Point(246,62);
   _meg[3,12] := Point(251,70);
   _meg[3,13] := Point(257,79);
   _meg[3,14] := Point(265,80);
   _meg[3,15] := Point(269,80);
   _meg[3,16] := Point(270,82);
   _meg[3,17] := Point(283,74);
   _meg[3,18] := Point(284,66);
   _meg[3,19] := Point(285,57);
   _meg[3,20] := Point(284,51);
   _meg[3,21] := Point(292,49);
   _meg[3,22] := Point(294,50);
   _meg[3,23] := Point(296,51);
   _meg[3,24] := Point(304,48);
   _meg[3,25] := Point(303,44);
   _meg[3,26] := Point(302,41);
   _meg[3,27] := Point(306,38);
   _meg[3,28] := Point(320,35);
   _meg[3,29] := Point(323,33);
   _meg[3,30] := Point(324,32);
   _meg[3,31] := Point(326,30);
   _meg[3,32] := Point(328,30);
   _meg[3,33] := Point(331,31);
   _meg[3,34] := Point(335,25);
   _meg[3,35] := Point(339,25);
   _meg[3,36] := Point(340,20);
   _meg[3,37] := Point(341,15);
   _meg[3,38] := Point(330,17);
   _meg[3,39] := Point(322,18);
   _meg[3,40] := Point(319,17);
   _meg[3,41] := Point(316,7);
   _meg[3,42] := Point(310,5);
   _meg[3,43] := Point(305,1);
   _meg[3,44] := Point(303,1);
   _meg[3,45] := Point(300,2);
   _meg[3,46] := Point(295,5);
   _meg[3,47] := Point(291,3);
   _meg[3,48] := Point(286,8);
   _meg[3,49] := Point(275,7);
   _meg[3,50] := Point(270,2);
   _meg[3,51] := Point(253,7);
   _meg[3,52] := Point(245,23);
   _meg[3,53] := Point(240,29);
   _meg[3,54] := Point(239,24);
   _meg[3,55] := Point(238,20);
   _meg[3,56] := Point(235,32);
   _meg[3,57] := Point(230,32);
   _meg[3,58] := Point(230,35);
   _meg[3,59] := Point(225,37);
   _meg[3,60] := Point(226,42);

   // -------------------------------

   _meg[4,0] := Point(208,210);
   _meg[4,1] := Point(210,210);
   _meg[4,2] := Point(212,210);
   _meg[4,3] := Point(216,213);
   _meg[4,4] := Point(227,210);
   _meg[4,5] := Point(229,210);
   _meg[4,6] := Point(230,210);
   _meg[4,7] := Point(235,210);
   _meg[4,8] := Point(243,213);
   _meg[4,9] := Point(245,211);
   _meg[4,10] := Point(248,210);
   _meg[4,11] := Point(254,211);
   _meg[4,12] := Point(260,208);
   _meg[4,13] := Point(265,210);
   _meg[4,14] := Point(270,208);
   _meg[4,15] := Point(271,209);
   _meg[4,16] := Point(272,200);
   _meg[4,17] := Point(271,200);
   _meg[4,18] := Point(270,199);
   _meg[4,19] := Point(268,194);
   _meg[4,20] := Point(268,190);
   _meg[4,21] := Point(266,191);
   _meg[4,22] := Point(263,193);
   _meg[4,23] := Point(262,193);
   _meg[4,24] := Point(260,193);
   _meg[4,25] := Point(256,190);
   _meg[4,26] := Point(257,189);
   _meg[4,27] := Point(259,185);
   _meg[4,28] := Point(260,178);
   _meg[4,29] := Point(256,167);
   _meg[4,30] := Point(258,166);
   _meg[4,31] := Point(259,166);
   _meg[4,32] := Point(260,165);
   _meg[4,33] := Point(258,158);
   _meg[4,34] := Point(254,156);
   _meg[4,35] := Point(250,155);
   _meg[4,36] := Point(248,156);
   _meg[4,37] := Point(245,156);
   _meg[4,38] := Point(244,157);
   _meg[4,39] := Point(242,160);
   _meg[4,40] := Point(240,158);
   _meg[4,41] := Point(238,155);
   _meg[4,42] := Point(236,156);
   _meg[4,43] := Point(235,157);
   _meg[4,44] := Point(233,159);
   _meg[4,45] := Point(228,155);
   _meg[4,46] := Point(227,157);
   _meg[4,47] := Point(226,158);
   _meg[4,48] := Point(224,161);
   _meg[4,49] := Point(223,178);
   _meg[4,50] := Point(222,177);
   _meg[4,51] := Point(220,175);
   _meg[4,52] := Point(218,175);
   _meg[4,53] := Point(213,179);
   _meg[4,54] := Point(216,181);
   _meg[4,55] := Point(219,182);
   _meg[4,56] := Point(216,190);
   _meg[4,57] := Point(211,194);
   _meg[4,58] := Point(206,194);
   _meg[4,59] := Point(205,201);
   _meg[4,60] := Point(208,210);

   // -------------------------------

   _mEg[5,0] := Point(161,153);
   _mEg[5,1] := Point(165,145);
   _mEg[5,2] := Point(162,138);
   _mEg[5,3] := Point(158,135);
   _mEg[5,4] := Point(157,133);
   _mEg[5,5] := Point(156,132);
   _mEg[5,6] := Point(161,116);
   _mEg[5,7] := Point(153,106);
   _mEg[5,8] := Point(155,104);
   _mEg[5,9] := Point(153,99);
   _mEg[5,10] := Point(150,95);
   _mEg[5,11] := Point(150,91);
   _mEg[5,12] := Point(147,91);
   _mEg[5,13] := Point(144,91);
   _mEg[5,14] := Point(138,92);
   _mEg[5,15] := Point(137,95);
   _mEg[5,16] := Point(136,99);
   _mEg[5,17] := Point(133,100);
   _mEg[5,18] := Point(130,101);
   _mEg[5,19] := Point(129,103);
   _mEg[5,20] := Point(128,106);
   _mEg[5,21] := Point(126,105);
   _mEg[5,22] := Point(120,100);
   _mEg[5,23] := Point(120,102);
   _mEg[5,24] := Point(116,102);
   _mEg[5,25] := Point(116,108);
   _mEg[5,26] := Point(112,110);
   _mEg[5,27] := Point(113,113);
   _mEg[5,28] := Point(114,115);
   _mEg[5,29] := Point(118,118);
   _mEg[5,30] := Point(123,122);
   _mEg[5,31] := Point(122,134);
   _mEg[5,32] := Point(123,136);
   _mEg[5,33] := Point(124,138);
   _mEg[5,34] := Point(122,141);
   _mEg[5,35] := Point(120,144);
   _mEg[5,36] := Point(120,146);
   _mEg[5,37] := Point(120,147);
   _mEg[5,38] := Point(121,149);
   _mEg[5,39] := Point(121,150);
   _mEg[5,40] := Point(121,154);
   _mEg[5,41] := Point(121,158);
   _mEg[5,42] := Point(123,156);
   _mEg[5,43] := Point(124,155);
   _mEg[5,44] := Point(126,155);
   _mEg[5,45] := Point(130,160);
   _mEg[5,46] := Point(131,158);
   _mEg[5,47] := Point(132,157);
   _mEg[5,48] := Point(133,157);
   _mEg[5,49] := Point(136,162);
   _mEg[5,50] := Point(138,160);
   _mEg[5,51] := Point(140,159);
   _mEg[5,52] := Point(141,159);
   _mEg[5,53] := Point(142,160);
   _mEg[5,54] := Point(143,161);
   _mEg[5,55] := Point(146,166);
   _mEg[5,56] := Point(152,163);
   _mEg[5,57] := Point(152,160);
   _mEg[5,58] := Point(159,156);
   _mEg[5,59] := Point(159,155);
   _mEg[5,60] := Point(161,153);

   // -------------------------------

   _meg[6,0] := Point(33,99);
   _meg[6,1] := Point(36,103);
   _meg[6,2] := Point(40,100);
   _meg[6,3] := Point(45,100);
   _meg[6,4] := Point(45,103);
   _meg[6,5] := Point(48,103);
   _meg[6,6] := Point(49,104);
   _meg[6,7] := Point(50,105);
   _meg[6,8] := Point(56,100);
   _meg[6,9] := Point(56,105);
   _meg[6,10] := Point(60,103);
   _meg[6,11] := Point(63,101);
   _meg[6,12] := Point(72,102);
   _meg[6,13] := Point(75,99);
   _meg[6,14] := Point(77,99);
   _meg[6,15] := Point(80,98);
   _meg[6,16] := Point(82,100);
   _meg[6,17] := Point(85,99);
   _meg[6,18] := Point(88,100);
   _meg[6,19] := Point(90,102);
   _meg[6,20] := Point(95,100);
   _meg[6,21] := Point(98,100);
   _meg[6,22] := Point(103,100);
   _meg[6,23] := Point(104,95);
   _meg[6,24] := Point(108,92);
   _meg[6,25] := Point(105,90);
   _meg[6,26] := Point(106,88);
   _meg[6,27] := Point(105,85);
   _meg[6,28] := Point(104,81);
   _meg[6,29] := Point(106,79);
   _meg[6,30] := Point(105,74);
   _meg[6,31] := Point(100,73);
   _meg[6,32] := Point(95,72);
   _meg[6,33] := Point(94,71);
   _meg[6,34] := Point(93,69);
   _meg[6,35] := Point(91,67);
   _meg[6,36] := Point(86,67);
   _meg[6,37] := Point(72,50);
   _meg[6,38] := Point(68,49);
   _meg[6,39] := Point(63,51);
   _meg[6,40] := Point(60,61);
   _meg[6,41] := Point(55,63);
   _meg[6,42] := Point(56,65);
   _meg[6,43] := Point(57,68);
   _meg[6,44] := Point(58,77);
   _meg[6,45] := Point(52,77);
   _meg[6,46] := Point(51,73);
   _meg[6,47] := Point(50,68);
   _meg[6,48] := Point(48,59);
   _meg[6,49] := Point(29,71);
   _meg[6,50] := Point(27,73);
   _meg[6,51] := Point(26,75);
   _meg[6,52] := Point(23,76);
   _meg[6,53] := Point(22,80);
   _meg[6,54] := Point(25,80);
   _meg[6,55] := Point(28,81);
   _meg[6,56] := Point(30,85);
   _meg[6,57] := Point(35,84);
   _meg[6,58] := Point(36,92);
   _meg[6,59] := Point(34,94);
   _meg[6,60] := Point(33,99);

   // --------------------------------

   _meg[7,0] := Point(281,117);
   _meg[7,1] := Point(283,119);
   _meg[7,2] := Point(285,121);
   _meg[7,3] := Point(289,125);
   _meg[7,4] := Point(289,127);
   _meg[7,5] := Point(289,128);
   _meg[7,6] := Point(289,129);
   _meg[7,7] := Point(292,131);
   _meg[7,8] := Point(293,131);
   _meg[7,9] := Point(294,132);
   _meg[7,10] := Point(289,138);
   _meg[7,11] := Point(292,138);
   _meg[7,12] := Point(306,138);
   _meg[7,13] := Point(306,142);
   _meg[7,14] := Point(310,141);
   _meg[7,15] := Point(315,140);
   _meg[7,16] := Point(316,137);
   _meg[7,17] := Point(316,135);
   _meg[7,18] := Point(318,134);
   _meg[7,19] := Point(320,133);
   _meg[7,20] := Point(323,132);
   _meg[7,21] := Point(324,130);
   _meg[7,22] := Point(325,129);
   _meg[7,23] := Point(326,127);
   _meg[7,24] := Point(327,125);
   _meg[7,25] := Point(328,124);
   _meg[7,26] := Point(330,120);
   _meg[7,27] := Point(331,118);
   _meg[7,28] := Point(332,116);
   _meg[7,29] := Point(333,113);
   _meg[7,30] := Point(334,115);
   _meg[7,31] := Point(335,118);
   _meg[7,32] := Point(336,110);
   _meg[7,33] := Point(338,103);
   _meg[7,34] := Point(342,100);
   _meg[7,35] := Point(341,96);
   _meg[7,36] := Point(340,92);
   _meg[7,37] := Point(343,88);
   _meg[7,38] := Point(345,85);
   _meg[7,39] := Point(342,80);
   _meg[7,40] := Point(340,81);
   _meg[7,41] := Point(337,82);
   _meg[7,42] := Point(331,74);
   _meg[7,43] := Point(328,77);
   _meg[7,44] := Point(326,80);
   _meg[7,45] := Point(310,69);
   _meg[7,46] := Point(310,63);
   _meg[7,47] := Point(310,57);
   _meg[7,48] := Point(295,60);
   _meg[7,49] := Point(291,59);
   _meg[7,50] := Point(288,57);
   _meg[7,51] := Point(285,57);
   _meg[7,52] := Point(284,65);
   _meg[7,53] := Point(283,74);
   _meg[7,54] := Point(270,82);
   _meg[7,55] := Point(271,85);
   _meg[7,56] := Point(272,88);
   _meg[7,57] := Point(278,87);
   _meg[7,58] := Point(279,93);
   _meg[7,59] := Point(281,109);
   _meg[7,60] := Point(281,117);

  // ------------------------ -----------

   _meg[8,0] := Point(199,78);
   _meg[8,1] := Point(201,79);
   _meg[8,2] := Point(203,80);
   _meg[8,3] := Point(201,83);
   _meg[8,4] := Point(202,86);
   _meg[8,5] := Point(203,90);
   _meg[8,6] := Point(205,89);
   _meg[8,7] := Point(206,89);
   _meg[8,8] := Point(207,85);
   _meg[8,9] := Point(208,81);
   _meg[8,10] := Point(211,88);
   _meg[8,11] := Point(213,85);
   _meg[8,12] := Point(216,82);
   _meg[8,13] := Point(222,81);
   _meg[8,14] := Point(222,85);
   _meg[8,15] := Point(223,90);
   _meg[8,16] := Point(229,91);
   _meg[8,17] := Point(230,88);
   _meg[8,18] := Point(233,88);
   _meg[8,19] := Point(235,88);
   _meg[8,20] := Point(239,93);
   _meg[8,21] := Point(240,99);
   _meg[8,22] := Point(243,100);
   _meg[8,23] := Point(244,101);
   _meg[8,24] := Point(245,102);
   _meg[8,25] := Point(249,101);
   _meg[8,26] := Point(249,99);
   _meg[8,27] := Point(250,96);
   _meg[8,28] := Point(262,90);
   _meg[8,29] := Point(262,87);
   _meg[8,30] := Point(262,86);
   _meg[8,31] := Point(262,85);
   _meg[8,32] := Point(262,84);
   _meg[8,33] := Point(265,83);
   _meg[8,34] := Point(265,80);
   _meg[8,35] := Point(257,79);
   _meg[8,36] := Point(246,62);
   _meg[8,37] := Point(252,62);
   _meg[8,38] := Point(248,57);
   _meg[8,39] := Point(250,50);
   _meg[8,40] := Point(248,49);
   _meg[8,41] := Point(247,48);
   _meg[8,42] := Point(249,43);
   _meg[8,43] := Point(244,40);
   _meg[8,44] := Point(241,46);
   _meg[8,45] := Point(238,43);
   _meg[8,46] := Point(232,46);
   _meg[8,47] := Point(231,43);
   _meg[8,48] := Point(230,41);
   _meg[8,49] := Point(226,42);
   _meg[8,50] := Point(219,46);
   _meg[8,51] := Point(223,53);
   _meg[8,52] := Point(220,55);
   _meg[8,53] := Point(220,60);
   _meg[8,54] := Point(216,60);
   _meg[8,55] := Point(215,65);
   _meg[8,56] := Point(212,64);
   _meg[8,57] := Point(210,64);
   _meg[8,58] := Point(208,63);
   _meg[8,59] := Point(208,66);
   _meg[8,60] := Point(199,78);

    // ---------------------------------------------

   _meg[10,0] := Point(105,74);
   _meg[10,1] := Point(110,75);
   _meg[10,2] := Point(113,75);
   _meg[10,3] := Point(115,75);
   _meg[10,4] := Point(125,75);
   _meg[10,5] := Point(126,76);
   _meg[10,6] := Point(127,76);
   _meg[10,7] := Point(128,76);
   _meg[10,8] := Point(132,75);
   _meg[10,9] := Point(133,75);
   _meg[10,10] := Point(135,74);
   _meg[10,11] := Point(140,74);
   _meg[10,12] := Point(142,74);
   _meg[10,13] := Point(145,74);
   _meg[10,14] := Point(148,73);
   _meg[10,15] := Point(152,72);
   _meg[10,16] := Point(153,72);
   _meg[10,17] := Point(155,72);
   _meg[10,18] := Point(156,72);
   _meg[10,19] := Point(157,72);
   _meg[10,20] := Point(158,72);
   _meg[10,21] := Point(159,71);
   _meg[10,22] := Point(160,71);
   _meg[10,23] := Point(164,76);
   _meg[10,24] := Point(163,78);
   _meg[10,25] := Point(162,80);
   _meg[10,26] := Point(160,85);
   _meg[10,27] := Point(157,83);
   _meg[10,28] := Point(155,82);
   _meg[10,29] := Point(154,81);
   _meg[10,30] := Point(150,91);
   _meg[10,31] := Point(138,92);
   _meg[10,32] := Point(136,99);
   _meg[10,33] := Point(130,101);
   _meg[10,34] := Point(128,106);
   _meg[10,35] := Point(126,105);
   _meg[10,36] := Point(123,100);
   _meg[10,37] := Point(122,100);
   _meg[10,38] := Point(120,100);
   _meg[10,39] := Point(120,102);
   _meg[10,40] := Point(116,102);
   _meg[10,41] := Point(116,108);
   _meg[10,42] := Point(114,109);
   _meg[10,43] := Point(112,110);
   _meg[10,44] := Point(106,110);
   _meg[10,45] := Point(107,107);
   _meg[10,46] := Point(105,106);
   _meg[10,47] := Point(104,105);
   _meg[10,48] := Point(103,100);
   _meg[10,49] := Point(104,95);
   _meg[10,50] := Point(106,93);
   _meg[10,51] := Point(108,92);
   _meg[10,52] := Point(106,91);
   _meg[10,53] := Point(105,90);
   _meg[10,54] := Point(106,88);
   _meg[10,55] := Point(103,83);
   _meg[10,56] := Point(104,82);
   _meg[10,57] := Point(105,81);
   _meg[10,58] := Point(106,79);
   _meg[10,59] := Point(105,76);
   _meg[10,60] := Point(105,74);

   // ----------------------- -----------

   _meg[11,0] := Point(161,50);
   _meg[11,1] := Point(163,52);
   _meg[11,2] := Point(166,54);
   _meg[11,3] := Point(166,58);
   _meg[11,4] := Point(165,59);
   _meg[11,5] := Point(164,60);
   _meg[11,6] := Point(167,65);
   _meg[11,7] := Point(170,70);
   _meg[11,8] := Point(175,68);
   _meg[11,9] := Point(177,69);
   _meg[11,10] := Point(181,70);
   _meg[11,11] := Point(185,70);
   _meg[11,12] := Point(190,70);
   _meg[11,13] := Point(191,72);
   _meg[11,14] := Point(191,73);
   _meg[11,15] := Point(191,76);
   _meg[11,16] := Point(191,77);
   _meg[11,17] := Point(192,78);
   _meg[11,18] := Point(193,80);
   _meg[11,19] := Point(194,78);
   _meg[11,20] := Point(195,77);
   _meg[11,21] := Point(197,78);
   _meg[11,22] := Point(198,78);
   _meg[11,23] := Point(199,78);
   _meg[11,24] := Point(204,72);
   _meg[11,25] := Point(206,69);
   _meg[11,26] := Point(208,66);
   _meg[11,27] := Point(208,65);
   _meg[11,28] := Point(208,64);
   _meg[11,29] := Point(208,63);
   _meg[11,30] := Point(215,65);
   _meg[11,31] := Point(216,60);
   _meg[11,32] := Point(217,60);
   _meg[11,33] := Point(218,60);
   _meg[11,34] := Point(220,60);
   _meg[11,35] := Point(220,55);
   _meg[11,36] := Point(222,54);
   _meg[11,37] := Point(223,53);
   _meg[11,38] := Point(219,46);
   _meg[11,39] := Point(226,42);
   _meg[11,40] := Point(225,37);
   _meg[11,41] := Point(220,39);
   _meg[11,42] := Point(216,36);
   _meg[11,43] := Point(214,37);
   _meg[11,44] := Point(212,39);
   _meg[11,45] := Point(210,35);
   _meg[11,46] := Point(206,35);
   _meg[11,47] := Point(205,33);
   _meg[11,48] := Point(203,32);
   _meg[11,49] := Point(200,33);
   _meg[11,50] := Point(198,36);
   _meg[11,51] := Point(197,38);
   _meg[11,52] := Point(196,40);
   _meg[11,53] := Point(194,45);
   _meg[11,54] := Point(186,45);
   _meg[11,55] := Point(184,46);
   _meg[11,56] := Point(182,48);
   _meg[11,57] := Point(177,47);
   _meg[11,58] := Point(173,46);
   _meg[11,59] := Point(167,48);
   _meg[11,60] := Point(161,50);

   // ---------------------- ---

   _meg[12,0] := Point(160,71);
   _meg[12,1] := Point(164,76);
   _meg[12,2] := Point(162,80);
   _meg[12,3] := Point(160,85);
   _meg[12,4] := Point(154,81);
   _meg[12,5] := Point(150,91);
   _meg[12,6] := Point(150,95);
   _meg[12,7] := Point(153,99);
   _meg[12,8] := Point(155,104);
   _meg[12,9] := Point(153,106);
   _meg[12,10] := Point(161,116);
   _meg[12,11] := Point(156,132);
   _meg[12,12] := Point(158,135);
   _meg[12,13] := Point(162,138);
   _meg[12,14] := Point(170,138);
   _meg[12,15] := Point(178,133);
   _meg[12,16] := Point(180,128);
   _meg[12,17] := Point(188,131);
   _meg[12,18] := Point(184,140);
   _meg[12,19] := Point(188,136);
   _meg[12,20] := Point(192,136);
   _meg[12,21] := Point(195,130);
   _meg[12,22] := Point(200,130);
   _meg[12,23] := Point(203,136);
   _meg[12,24] := Point(206,141);
   _meg[12,25] := Point(213,142);
   _meg[12,26] := Point(216,138);
   _meg[12,27] := Point(220,140);
   _meg[12,28] := Point(225,139);
   _meg[12,29] := Point(230,138);
   _meg[12,30] := Point(232,136);
   _meg[12,31] := Point(229,135);
   _meg[12,32] := Point(226,126);
   _meg[12,33] := Point(228,120);
   _meg[12,34] := Point(222,117);
   _meg[12,35] := Point(224,111);
   _meg[12,36] := Point(210,100);
   _meg[12,37] := Point(209,95);
   _meg[12,38] := Point(205,95);
   _meg[12,39] := Point(202,92);
   _meg[12,40] := Point(203,90);
   _meg[12,41] := Point(201,83);
   _meg[12,42] := Point(203,80);
   _meg[12,43] := Point(199,78);
   _meg[12,44] := Point(195,77);
   _meg[12,45] := Point(193,80);
   _meg[12,46] := Point(191,76);
   _meg[12,47] := Point(190,70);
   _meg[12,48] := Point(181,70);
   _meg[12,49] := Point(175,68);
   _meg[12,50] := Point(170,70);
   _meg[12,51] := Point(164,60);
   _meg[12,52] := Point(166,58);
   _meg[12,53] := Point(166,54);
   _meg[12,54] := Point(161,50);
   _meg[12,55] := Point(157,51);
   _meg[12,56] := Point(156,53);
   _meg[12,57] := Point(153,56);
   _meg[12,58] := Point(154,65);
   _meg[12,59] := Point(156,68);
   _meg[12,60] := Point(160,71);

    // ----------------------------

   _meg[13,0] := Point(44,196);
   _meg[13,1] := Point(50,204);
   _meg[13,2] := Point(61,212);
   _meg[13,3] := Point(65,219);
   _meg[13,4] := Point(68,226);
   _meg[13,5] := Point(75,228);
   _meg[13,6] := Point(83,232);
   _meg[13,7] := Point(86,236);
   _meg[13,8] := Point(90,238);
   _meg[13,9] := Point(92,237);
   _meg[13,10] := Point(94,236);
   _meg[13,11] := Point(92,230);
   _meg[13,12] := Point(88,220);
   _meg[13,13] := Point(90,218);
   _meg[13,14] := Point(90,215);
   _meg[13,15] := Point(91,214);
   _meg[13,16] := Point(90,210);
   _meg[13,17] := Point(92,208);
   _meg[13,18] := Point(92,205);
   _meg[13,19] := Point(93,206);
   _meg[13,20] := Point(95,207);
   _meg[13,21] := Point(96,206);
   _meg[13,22] := Point(97,205);
   _meg[13,23] := Point(100,206);
   _meg[13,24] := Point(104,205);
   _meg[13,25] := Point(105,203);
   _meg[13,26] := Point(106,200);
   _meg[13,27] := Point(113,198);
   _meg[13,28] := Point(114,194);
   _meg[13,29] := Point(111,191);
   _meg[13,30] := Point(110,190);
   _meg[13,31] := Point(115,186);
   _meg[13,32] := Point(113,184);
   _meg[13,33] := Point(111,182);
   _meg[13,34] := Point(112,178);
   _meg[13,35] := Point(113,174);
   _meg[13,36] := Point(115,171);
   _meg[13,37] := Point(117,169);
   _meg[13,38] := Point(119,168);
   _meg[13,39] := Point(117,165);
   _meg[13,40] := Point(118,162);
   _meg[13,41] := Point(120,159);
   _meg[13,42] := Point(121,158);
   _meg[13,43] := Point(121,150);
   _meg[13,44] := Point(121,148);
   _meg[13,45] := Point(120,144);
   _meg[13,46] := Point(118,142);
   _meg[13,47] := Point(100,152);
   _meg[13,48] := Point(80,160);
   _meg[13,49] := Point(72,161);
   _meg[13,50] := Point(67,164);
   _meg[13,51] := Point(66,166);
   _meg[13,52] := Point(65,168);
   _meg[13,53] := Point(65,180);
   _meg[13,54] := Point(63,183);
   _meg[13,55] := Point(63,187);
   _meg[13,56] := Point(54,190);
   _meg[13,57] := Point(55,194);
   _meg[13,58] := Point(53,197);
   _meg[13,59] := Point(50,195);
   _meg[13,60] := Point(44,196);

   // ---------------------- --------

   _meg[14,0] := Point(285,57);
   _meg[14,1] := Point(284,51);
   _meg[14,2] := Point(288,50);
   _meg[14,3] := Point(292,49);
   _meg[14,4] := Point(296,51);
   _meg[14,5] := Point(304,48);
   _meg[14,6]:= Point(303,44);
   _meg[14,7] := Point(302,41);
   _meg[14,8] := Point(304,39);
   _meg[14,9] := Point(306,38);
   _meg[14,10] := Point(320,35);
   _meg[14,11] := Point(322,34);
   _meg[14,12] := Point(323,33);
   _meg[14,13] := Point(326,30);
   _meg[14,14] := Point(331,31);
   _meg[14,15] := Point(335,25);
   _meg[14,16] := Point(336,25);
   _meg[14,17] := Point(337,25);
   _meg[14,18] := Point(339,25);
   _meg[14,19] := Point(341,15);
   _meg[14,20] := Point(346,11);
   _meg[14,21] := Point(351,12);
   _meg[14,22] := Point(353,15);
   _meg[14,23] := Point(355,19);
   _meg[14,24] := Point(358,27);
   _meg[14,25] := Point(361,27);
   _meg[14,26] := Point(366,27);
   _meg[14,27] := Point(371,33);
   _meg[14,28] := Point(375,40);
   _meg[14,29] := Point(380,38);
   _meg[14,30] := Point(385,37);
   _meg[14,31] := Point(388,41);
   _meg[14,32] := Point(390,53);
   _meg[14,33] := Point(387,55);
   _meg[14,34] := Point(384,57);
   _meg[14,35] := Point(382,61);
   _meg[14,36] := Point(380,65);
   _meg[14,37] := Point(377,66);
   _meg[14,38] := Point(375,66);
   _meg[14,39] := Point(366,64);
   _meg[14,40] := Point(363,67);
   _meg[14,41] := Point(360,70);
   _meg[14,42] := Point(357,72);
   _meg[14,43] := Point(354,74);
   _meg[14,44] := Point(352,77);
   _meg[14,45] := Point(350,81);
   _meg[14,46] := Point(347,83);
   _meg[14,47] := Point(345,85);
   _meg[14,48] := Point(342,80);
   _meg[14,49] := Point(337,82);
   _meg[14,50] := Point(334,78);
   _meg[14,51] := Point(331,74);
   _meg[14,52] := Point(326,80);
   _meg[14,53] := Point(310,69);
   _meg[14,54] := Point(310,63);
   _meg[14,55] := Point(310,57);
   _meg[14,56] := Point(295,60);
   _meg[14,57] := Point(293,59);
   _meg[14,58] := Point(291,58);
   _meg[14,59] := Point(288,57);
   _meg[14,60] := Point(285,57);

   // -------------------------------

   _meg[9,0] := Point(228,155);
   _meg[9,1] := Point(233,159);
   _meg[9,2] := Point(238,155);
   _meg[9,3] := Point(242,160);
   _meg[9,4] := Point(243,158);
   _meg[9,5] := Point(245,156);
   _meg[9,6] := Point(250,155);
   _meg[9,7] := Point(248,145);
   _meg[9,8] := Point(250,147);
   _meg[9,9] := Point(265,145);
   _meg[9,10] := Point(264,140);
   _meg[9,11] := Point(263,136);
   _meg[9,12] := Point(271,133);
   _meg[9,13] := Point(271,129);
   _meg[9,14] := Point(271,125);
   _meg[9,15] := Point(276,122);
   _meg[9,16] := Point(281,117);
   _meg[9,17] := Point(280,108);
   _meg[9,18] := Point(280,100);
   _meg[9,19] := Point(278,87);
   _meg[9,20] := Point(272,88);
   _meg[9,21] := Point(270,82);
   _meg[9,22] := Point(269,80);
   _meg[9,23] := Point(265,80);
   _meg[9,24] := Point(265,83);
   _meg[9,25] := Point(262,84);
   _meg[9,26] := Point(262,90);
   _meg[9,27] := Point(250,96);
   _meg[9,28] := Point(249,101);
   _meg[9,29] := Point(245,102);
   _meg[9,30] := Point(240,99);
   _meg[9,31] := Point(239,93);
   _meg[9,32] := Point(235,88);
   _meg[9,33] := Point(230,88);
   _meg[9,34] := Point(229,91);
   _meg[9,35] := Point(223,90);
   _meg[9,36] := Point(222,81);
   _meg[9,37] := Point(216,82);
   _meg[9,38] := Point(211,88);
   _meg[9,39] := Point(208,81);
   _meg[9,40] := Point(206,89);
   _meg[9,41] := Point(203,90);
   _meg[9,42] := Point(202,92);
   _meg[9,43] := Point(205,95);
   _meg[9,44] := Point(209,95);
   _meg[9,45] := Point(210,100);
   _meg[9,46] := Point(224,111);
   _meg[9,47] := Point(223,114);
   _meg[9,48] := Point(222,117);
   _meg[9,49] := Point(228,120);
   _meg[9,50] := Point(225,123);
   _meg[9,51] := Point(223,126);
   _meg[9,52] := Point(229,135);
   _meg[9,53] := Point(232,136);
   _meg[9,54] := Point(231,137);
   _meg[9,55] := Point(230,138);
   _meg[9,56] := Point(230,141);
   _meg[9,57] := Point(231,146);
   _meg[9,58] := Point(228,148);
   _meg[9,59] := Point(226,150);
   _meg[9,60] := Point(228,155);

   // -------------------------------

   _meg[15,0] := Point(156,215);
   _meg[15,1] := Point(157,214);
   _meg[15,2] := Point(156,212);
   _meg[15,3] := Point(160,208);
   _meg[15,4] := Point(158,207);
   _meg[15,5] := Point(156,205);
   _meg[15,6] := Point(162,201);
   _meg[15,7] := Point(160,188);
   _meg[15,8] := Point(161,185);
   _meg[15,9] := Point(160,178);
   _meg[15,10] := Point(159,172);
   _meg[15,11] := Point(166,165);
   _meg[15,12] := Point(161,153);
   _meg[15,13] := Point(159,153);
   _meg[15,14] := Point(159,156);
   _meg[15,15] := Point(152,160);
   _meg[15,16] := Point(152,163);
   _meg[15,17] := Point(146,166);
   _meg[15,18] := Point(144,163);
   _meg[15,19] := Point(143,161);
   _meg[15,20] := Point(140,159);
   _meg[15,21] := Point(138,160);
   _meg[15,22] := Point(136,162);
   _meg[15,23] := Point(133,157);
   _meg[15,24] := Point(130,160);
   _meg[15,25] := Point(128,157);
   _meg[15,26] := Point(126,155);
   _meg[15,27] := Point(121,158);
   _meg[15,28] := Point(118,162);
   _meg[15,29] := Point(117,165);
   _meg[15,30] := Point(119,168);
   _meg[15,31] := Point(115,171);
   _meg[15,32] := Point(113,175);
   _meg[15,33] := Point(112,178);
   _meg[15,34] := Point(111,182);
   _meg[15,35] := Point(115,186);
   _meg[15,36] := Point(110,190);
   _meg[15,37] := Point(114,194);
   _meg[15,38] := Point(113,198);
   _meg[15,39] := Point(117,197);
   _meg[15,40] := Point(120,196);
   _meg[15,41] := Point(120,192);
   _meg[15,42] := Point(128,190);
   _meg[15,43] := Point(129,194);
   _meg[15,44] := Point(131,194);
   _meg[15,45] := Point(130,197);
   _meg[15,46] := Point(131,201);
   _meg[15,47] := Point(130,203);
   _meg[15,48] := Point(129,204);
   _meg[15,49] := Point(130,206);
   _meg[15,50] := Point(135,204);
   _meg[15,51] := Point(135,202);
   _meg[15,52] := Point(136,200);
   _meg[15,53] := Point(140,203);
   _meg[15,54] := Point(140,204);
   _meg[15,55] := Point(140,205);
   _meg[15,56] := Point(142,207);
   _meg[15,57] := Point(143,210);
   _meg[15,58] := Point(146,210);
   _meg[15,59] := Point(157,214);
   _meg[15,60] := Point(156,215);

   // -------------------------------

   _meg[16,0] := Point(12,158);
   _meg[16,1] := Point(25,155);
   _meg[16,2] := Point(30,153);
   _meg[16,3] := Point(35,150);
   _meg[16,4] := Point(31,144);
   _meg[16,5] := Point(40,145);
   _meg[16,6] := Point(41,142);
   _meg[16,7] := Point(42,140);
   _meg[16,8] := Point(50,142);
   _meg[16,9] := Point(52,139);
   _meg[16,10] := Point(54,136);
   _meg[16,11] := Point(58,136);
   _meg[16,12] := Point(56,134);
   _meg[16,13] := Point(64,132);
   _meg[16,14] := Point(65,128);
   _meg[16,15] := Point(64,126);
   _meg[16,16] := Point(64,125);
   _meg[16,17] := Point(63,124);
   _meg[16,18] := Point(64,117);
   _meg[16,19] := Point(65,114);
   _meg[16,20] := Point(66,111);
   _meg[16,21] := Point(65,109);
   _meg[16,22] := Point(63,105);
   _meg[16,23] := Point(63,103);
   _meg[16,24] := Point(63,101);
   _meg[16,25] := Point(59,102);
   _meg[16,26] := Point(56,105);
   _meg[16,27] := Point(56,102);
   _meg[16,28] := Point(56,101);
   _meg[16,29] := Point(56,100);
   _meg[16,30] := Point(65,101);
   _meg[16,31] := Point(53,102);
   _meg[16,32] := Point(50,105);
   _meg[16,33] := Point(49,104);
   _meg[16,34] := Point(48,103);
   _meg[16,35] := Point(43,103);
   _meg[16,36] := Point(44,103);
   _meg[16,37] := Point(45,103);
   _meg[16,38] := Point(45,102);
   _meg[16,39] := Point(45,100);
   _meg[16,40] := Point(42,100);
   _meg[16,41] := Point(41,100);
   _meg[16,42] := Point(40,100);
   _meg[16,43] := Point(36,103);
   _meg[16,44] := Point(34,101);
   _meg[16,45] := Point(33,99) ;
   _meg[16,46] := Point(28,101);
   _meg[16,47] := Point(20,103);
   _meg[16,48] := Point(21,107);
   _meg[16,49] := Point(22,112);
   _meg[16,50] := Point(18,120);
   _meg[16,51] := Point(20,123);
   _meg[16,52] := Point(22,126);
   _meg[16,53] := Point(20,137);
   _meg[16,54] := Point(12,136);
   _meg[16,55] := Point(10,138);
   _meg[16,56] := Point(8,140) ;
   _meg[16,57] := Point(3,140) ;
   _meg[16,58] := Point(0,148) ;
   _meg[16,59] := Point(10,148);
   _meg[16,60] := Point(12,158);

   // -------------------------------

   _meg[17,0] := Point(67,164);
   _meg[17,1] := Point(68,163);
   _meg[17,2] := Point(69,163);
   _meg[17,3] := Point(70,162);
   _meg[17,4] := Point(72,161);
   _meg[17,5] := Point(74,161);
   _meg[17,6] := Point(76,160);
   _meg[17,7] := Point(80,160);
   _meg[17,8] := Point(90,156);
   _meg[17,9] := Point(100,152);
   _meg[17,10] := Point(118,142);
   _meg[17,11] := Point(120,144);
   _meg[17,12] := Point(124,138);
   _meg[17,13] := Point(123,136);
   _meg[17,14] := Point(122,134);
   _meg[17,15] := Point(123,122);
   _meg[17,16] := Point(120,120);
   _meg[17,17] := Point(118,118);
   _meg[17,18] := Point(113,113);
   _meg[17,19] := Point(112,111);
   _meg[17,20] := Point(109,111);
   _meg[17,21] := Point(106,110);
   _meg[17,22] := Point(107,107);
   _meg[17,23] := Point(105,106);
   _meg[17,24] := Point(104,105);
   _meg[17,25] := Point(103,100);
   _meg[17,26] := Point(101,100);
   _meg[17,27] := Point(98,100);
   _meg[17,28] := Point(95,100);
   _meg[17,29] := Point(90,102);
   _meg[17,30] := Point(87,100);
   _meg[17,31] := Point(86,99);
   _meg[17,32] := Point(85,99);
   _meg[17,33] := Point(82,100);
   _meg[17,34] := Point(80,98);
   _meg[17,35] := Point(75,99);
   _meg[17,36] := Point(73,101);
   _meg[17,37] := Point(72,102);
   _meg[17,38] := Point(63,101);
   _meg[17,39] := Point(63,105);
   _meg[17,40] := Point(65,108);
   _meg[17,41] := Point(66,111);
   _meg[17,42] := Point(63,124);
   _meg[17,43] := Point(64,126);
   _meg[17,44] := Point(65,128);
   _meg[17,45] := Point(64,132);
   _meg[17,46] := Point(60,133);
   _meg[17,47] := Point(56,134);
   _meg[17,48] := Point(58,136);
   _meg[17,49] := Point(60,139);
   _meg[17,50] := Point(63,139);
   _meg[17,51] := Point(64,139);
   _meg[17,52] := Point(65,139);
   _meg[17,53] := Point(65,145);
   _meg[17,54] := Point(72,148);
   _meg[17,55] := Point(71,150);
   _meg[17,56] := Point(70,152);
   _meg[17,57] := Point(75,158);
   _meg[17,58] := Point(70,159);
   _meg[17,59] := Point(66,160);
   _meg[17,60] := Point(67,164);

   //----------------------- ----------

   _meg[18,0] := Point(12,158);
   _meg[18,1] := Point(13,160);
   _meg[18,2] := Point(15,162);
   _meg[18,3] := Point(18,162);
   _meg[18,4] := Point(17,165);
   _meg[18,5] := Point(16,168);
   _meg[18,6] := Point(19,170);
   _meg[18,7] := Point(22,173);
   _meg[18,8] := Point(25,180);
   _meg[18,9] := Point(26,183);
   _meg[18,10] := Point(26,186);
   _meg[18,11] := Point(29,187);
   _meg[18,12] := Point(32,188);
   _meg[18,13] := Point(39,190);
   _meg[18,14] := Point(40,191);
   _meg[18,15] := Point(41,192);
   _meg[18,16] := Point(42,193);
   _meg[18,17] := Point(42,194);
   _meg[18,18] := Point(43,195);
   _meg[18,19] := Point(44,196);
   _meg[18,20] := Point(45,196);
   _meg[18,21] := Point(46,196);
   _meg[18,22] := Point(48,196);
   _meg[18,23] := Point(50,195);
   _meg[18,24] := Point(52,196);
   _meg[18,25] := Point(53,197);
   _meg[18,26] := Point(54,195);
   _meg[18,27] := Point(55,194);
   _meg[18,28] := Point(54,190);
   _meg[18,29] := Point(58,188);
   _meg[18,30] := Point(63,187);
   _meg[18,31] := Point(63,183);
   _meg[18,32] := Point(64,181);
   _meg[18,33] := Point(65,180);
   _meg[18,34] := Point(65,174);
   _meg[18,35] := Point(65,168);
   _meg[18,36] := Point(67,164);
   _meg[18,37] := point(66,162);
   _meg[18,38] := Point(66,160);
   _meg[18,39] := Point(75,158);
   _meg[18,40] := Point(73,155);
   _meg[18,41] := Point(70,152);
   _meg[18,42] := Point(72,148);
   _meg[18,43] := Point(65,145);
   _meg[18,44] := Point(65,142);
   _meg[18,45] := Point(65,139);
   _meg[18,46] := Point(60,139);
   _meg[18,47] := Point(59,137);
   _meg[18,48] := Point(58,136);
   _meg[18,49] := Point(54,136);
   _meg[18,50] := Point(52,139);
   _meg[18,51] := Point(50,142);
   _meg[18,52] := Point(42,140);
   _meg[18,53] := Point(41,143);
   _meg[18,54] := Point(40,145);
   _meg[18,55] := Point(31,144);
   _meg[18,56] := Point(33,147);
   _meg[18,57] := Point(35,150);
   _meg[18,58] := Point(25,155);
   _meg[18,59] := Point(19,157);
   _meg[18,60] := Point(12,158);
end;

// =============================================================================
           procedure TSelectCounty.ESCAPEGOMBClick(Sender: TObject);
// =============================================================================

begin
  modalresult := -1;
end;

// =============================================================================
procedure TSelectCounty.FillPolygon(ACanvas: TCanvas; APoints: array of TPoint);
// =============================================================================

var
  i, j: Integer;
  R: TRect;
  ARangeList: TRangeList;
begin
  ACanvas.Pen.Color := AColor;
  {Find polygon bounds because we only need to calculate fill-ranges from
  top to bottom value of rectangle}
  R := Polygon_GetBounds(APoints);
  for i := R.Top to R.Bottom do
  begin
    Polygon_GetFillRange(APoints, i, ARangeList);
    {Since there can be many fill ranges for one Y, function returns a list of all}
    for j := 0 to Length(ARangeList) - 1 do
    begin
      {fill pixels inside range}
      {so far I'll just draw a line with GDI but this part can be substituted with your own draw function}
      ACanvas.MoveTo(ARangeList[j].X, i);
      ACanvas.LineTo(ARangeList[j].X + ARangeList[j].Count, i);
    end;
  end;
end;


// =============================================================================
        function Polygon_GetBounds(const Points: array of TPoint): TRect;
// =============================================================================

var
  i: Integer;

begin
  Result := Rect(0, 0, 0, 0);
  for i := 0 to Length(Points) - 1 do
  begin
    if i = 0 then
      Result := Rect(Points[i].X, Points[i].Y, Points[i].X, Points[i].Y)
    else
    begin
      if Points[i].X < Result.Left then
        Result.Left := Points[i].X;
      if Points[i].Y < Result.Top then
        Result.Top := Points[i].Y;
      if Points[i].X > Result.Right then
        Result.Right := Points[i].X;
      if Points[i].Y > Result.Bottom then
        Result.Bottom := Points[i].Y;
    end;
  end;
  Result.Right := Result.Right + 1;
  Result.Bottom := Result.Bottom + 1;
end;

// =============================================================================
  function Polygon_PtInside(const Points: array of TPoint; Pt: TPoint): Boolean;
// =============================================================================

var
  RL: TRangeList;
  i: Integer;
begin
  Result := False;
  Polygon_GetFillRange(Points, Pt.Y, RL);
  for i := 0 to Length(RL) - 1 do
  begin
    Result := (Pt.X >= RL[i].X) and (Pt.X < RL[i].X + RL[i].Count);
    if Result then
      Exit;
  end;
end;

// =============================================================================
    procedure Polygon_GetFillRange(const Points: array of TPoint; Y: Integer;
                                                   out ARangeList: TRangeList);
// =============================================================================

var
  {first item in list}
  AItem: pRangeItem;

  procedure AddIntersection(X: Integer; Up: Boolean);
  var
    p, p2, Prev: pRangeItem;
  begin
    New(p);
    Prev := nil;
    p^.X := X;
    p^.Up := Up;
    p^.Next := nil;
    if Assigned(AItem) then
    begin
      {insert into sorted position}
      p2 := AItem;
      while Assigned(p2) do
      begin
        if p2^.X > X then
        begin
          if Assigned(Prev) then
          begin
            Prev^.Next := p;
            p^.Next := p2;
            Break;
          end
          else
          begin
            p^.Next := p2;
            AItem := p;
            Break;
          end;
        end;
        if p2^.Next = nil then
        begin
          {add to the end}
          p2^.Next := p;
          Break;
        end;
        Prev := p2;
        p2 := p2^.Next;
      end;
    end
    else
      AItem := p;
  end;

var
  i, X, X0, Cnt: Integer;
  LastDirection: Boolean;
  p: pRangeItem;

begin
  Lastdirection := False;
  if Length(Points) = 0 then
    Exit;
  AItem := nil;
  Cnt := 0;
  for i := 0 to Length(Points) - 2 do
  begin
    if ((Points[i].Y > Y) and (Points[i + 1].Y <= Y)) or ((Points[i].Y <= Y) and
      (Points[i + 1].Y > Y)) then
      if Points[i + 1].Y <> points[i].Y then
      begin
        X := Round(Points[i].X + ((Points[i + 1].X - Points[i].X) *
          (Y - Points[i].Y) / (Points[i + 1].Y - points[i].Y)));
        AddIntersection(X, Points[i + 1].Y > Points[i].Y);
        Inc(Cnt);
      end;
  end;
  {close polygon}
  i := Length(Points) - 1;
  if ((Points[i].Y > Y) and (Points[0].Y <= Y)) or ((Points[i].Y <= Y) and (Points[0].Y
    > Y)) then
    if Points[0].Y <> points[i].Y then
    begin
      X := Round(Points[i].X + ((Points[0].X - Points[i].X) * (Y - Points[i].Y) /
        (Points[0].Y - points[i].Y)));
      AddIntersection(X, Points[0].Y > Points[i].Y);
      Inc(Cnt);
    end;
  p := AItem;
  {calculate fill ranges}
  i := 1; {use as acumulative direction counter}
  SetLength(ARangeList, Cnt);
  Cnt := 0; {number of range items in array}
  x0 := 0;

  if Assigned(AItem) then
  begin
    LastDirection := AItem^.Up; {init last direction}
    X0 := AItem^.X;
    AItem := AItem^.Next;
  end;
  while Assigned(AItem) do
  begin
    if AItem^.Up = LastDirection then
    begin
      Inc(i);
      if i = 1 then
        X0 := AItem^.X; {init start position}
    end
    else
    begin
      Dec(i);
      if i = -1 then
        X0 := AItem^.X; {init start position}
    end;
    if i = 0 then
    begin
      ARangeList[Cnt].X := X0;
      ARangeList[Cnt].Count := AItem^.X - X0;
      Inc(Cnt);
      LastDirection := AItem^.Up;
    end;
    AItem := AItem^.Next;
  end;
  {shrink list}
  SetLength(ARangeList, Cnt);
  {delete internal range list}
  while Assigned(p) do
  begin
    AItem := p;
    p := p^.Next;
    Dispose(AItem);
  end;
end;




{

// =============================================================================
procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  if Polygon_PtInside(APoints, Point(X, Y)) then
  begin
    if not APtInside then
    begin
      Caption := 'Inside: YES';
      AColor := clRed;
      APtInside := True;
      Repaint;
    end;
  end
  else
  begin
    if APtInside then
    begin
      Caption := 'Inside: NO';
      AColor := clBlack;
      APtInside := False;
      Repaint;
    end;
  end;
end;
}


// =============================================================================
   procedure TSelectCounty.vaszonMouseDown(Sender: TObject; Button: TMouseButton;
                            Shift: TShiftState; X, Y: Integer);
// =============================================================================

var
    _bennvan: boolean;
    _aktpoint: TPoint;

begin
   Allcounty;

   _z := 0;
   _aktpoint := Point(x,y);
   while _z<19 do
     begin
       tombtotomb(_z);
       _bennvan := Polygon_PtInside(_akttomb,_aktpoint);
       if _bennvan then break;
       inc(_z);
     end;

   if _z<19 then
     begin
       Panel1.caption := _megyenev[_z]+ ' VARMEGYE';
       Valasztogomb.Enabled := true;
     end else
     begin
       Panel1.Caption := 'Ez külföld !';
       Valasztogomb.Enabled := false;
       exit;
     end;
   Vaszon.Canvas.Brush.Color := clRed;
   Vaszon.Canvas.Polygon(_akttomb);
end;

// =============================================================================
            procedure TSelectCounty.VALASZTOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := (_z+1);
end;

end.
