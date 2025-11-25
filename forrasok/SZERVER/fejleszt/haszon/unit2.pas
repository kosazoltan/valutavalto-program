unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, TeEngine, Series, ExtCtrls, TeeProcs, Chart, StdCtrls, Buttons,TlHelp32,
  IBDatabase, DB, IBCustomDataSet, IBQuery, unit1, strutils, Excel97, comobj;

type
  Tkijelzes = class(TForm)
    P131: TPanel;
    P17: TPanel;
    P121: TPanel;
    P28: TPanel;
    P12: TPanel;
    P129: TPanel;
    P6: TPanel;
    P35: TPanel;
    P42: TPanel;
    P29: TPanel;
    P45: TPanel;
    P52: TPanel;
    P69: TPanel;
    P68: TPanel;
    P71: TPanel;
    P62: TPanel;
    P15: TPanel;
    P113: TPanel;
    P100: TPanel;
    P66: TPanel;
    P93: TPanel;
    P141: TPanel;
    P123: TPanel;
    P20: TPanel;
    P142: TPanel;
    P135: TPanel;
    P149: TPanel;
    P7: TPanel;
    P47: TPanel;
    P58: TPanel;
    P24: TPanel;
    P105: TPanel;
    P87: TPanel;
    P34: TPanel;
    P61: TPanel;
    P39: TPanel;
    P23: TPanel;
    P33: TPanel;
    P11: TPanel;
    P9: TPanel;
    P57: TPanel;
    P43: TPanel;
    P94: TPanel;
    P74: TPanel;
    P55: TPanel;
    P5: TPanel;
    P4: TPanel;
    P64: TPanel;
    P84: TPanel;
    P115: TPanel;
    P73: TPanel;
    P10: TPanel;
    P8: TPanel;
    P138: TPanel;
    P112: TPanel;
    P111: TPanel;
    P98: TPanel;
    P118: TPanel;
    P79: TPanel;
    P97: TPanel;
    P127: TPanel;
    P80: TPanel;
    P78: TPanel;
    P63: TPanel;
    P1: TPanel;
    P89: TPanel;
    P150: TPanel;
    P103: TPanel;
    P109: TPanel;
    P38: TPanel;
    P72: TPanel;
    P56: TPanel;
    P124: TPanel;
    P114: TPanel;
    P104: TPanel;
    P119: TPanel;
    P128: TPanel;
    P81: TPanel;
    P88: TPanel;
    P144: TPanel;
    P21: TPanel;
    P44: TPanel;
    P49: TPanel;
    P67: TPanel;
    P54: TPanel;
    P101: TPanel;
    P77: TPanel;
    P91: TPanel;
    P25: TPanel;
    P48: TPanel;
    P13: TPanel;
    P148: TPanel;
    P147: TPanel;
    P133: TPanel;
    P85: TPanel;
    P83: TPanel;
    P116: TPanel;
    P31: TPanel;
    P140: TPanel;
    P50: TPanel;
    P65: TPanel;
    P82: TPanel;
    P90: TPanel;
    P145: TPanel;
    P143: TPanel;
    P107: TPanel;
    P106: TPanel;
    P122: TPanel;
    P126: TPanel;
    P27: TPanel;
    P3: TPanel;
    P19: TPanel;
    P108: TPanel;
    P110: TPanel;
    P139: TPanel;
    P102: TPanel;
    P146: TPanel;
    P96: TPanel;
    P18: TPanel;
    P59: TPanel;
    P92: TPanel;
    P137: TPanel;
    P36: TPanel;
    P2: TPanel;
    P22: TPanel;
    P132: TPanel;
    P76: TPanel;
    P40: TPanel;
    P60: TPanel;
    P117: TPanel;
    P41: TPanel;
    P37: TPanel;
    P32: TPanel;
    P14: TPanel;
    P136: TPanel;
    P30: TPanel;
    P46: TPanel;
    P16: TPanel;
    P95: TPanel;
    P53: TPanel;
    P134: TPanel;
    P70: TPanel;
    P99: TPanel;
    P125: TPanel;
    P86: TPanel;
    P75: TPanel;
    P130: TPanel;
    P120: TPanel;
    P26: TPanel;
    P51: TPanel;
    STARTNAPPANEL: TPanel;
    ENDNAPPANEL: TPanel;
    Label1: TLabel;
    ALAPPANEL: TPanel;
    Shape1: TShape;
    visszagomb: TBitBtn;
    GYUJTOQUERY: TIBQuery;
    GYUJTODBASE: TIBDatabase;
    GYUJTOTRANZ: TIBTransaction;
    Label2: TLabel;
    Shape3: TShape;
    Shape4: TShape;
    IRODANEVPANEL: TPanel;
    Shape2: TShape;
    ATLAGPANEL: TPanel;
    Panel2: TPanel;
    e1: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    Panel10: TPanel;
    v1: TPanel;
    Panel12: TPanel;
    Panel13: TPanel;
    Panel14: TPanel;
    Panel15: TPanel;
    Panel16: TPanel;
    Panel17: TPanel;
    Panel18: TPanel;
    Panel19: TPanel;
    Panel20: TPanel;
    Panel22: TPanel;
    Panel23: TPanel;
    Panel24: TPanel;
    v2: TPanel;
    v3: TPanel;
    v5: TPanel;
    v6: TPanel;
    v8: TPanel;
    v9: TPanel;
    v11: TPanel;
    v12: TPanel;
    v14: TPanel;
    v4: TPanel;
    v7: TPanel;
    v10: TPanel;
    v13: TPanel;
    v15: TPanel;
    e10: TPanel;
    e12: TPanel;
    e15: TPanel;
    e8: TPanel;
    e7: TPanel;
    e16: TPanel;
    e17: TPanel;
    e19: TPanel;
    v20: TPanel;
    e20: TPanel;
    e13: TPanel;
    e11: TPanel;
    v18: TPanel;
    e18: TPanel;
    e9: TPanel;
    v17: TPanel;
    v16: TPanel;
    e14: TPanel;
    v19: TPanel;
    Panel57: TPanel;
    e3: TPanel;
    e5: TPanel;
    e2: TPanel;
    e4: TPanel;
    e6: TPanel;
    Panel63: TPanel;
    Panel64: TPanel;
    BitBtn1: TBitBtn;
    Shape5: TShape;
    NAPIARFGOMB: TBitBtn;
    Shape6: TShape;
    Shape7: TShape;
    MNBARFGOMB: TBitBtn;
    Shape8: TShape;
    excelgomb: TBitBtn;
    Shape9: TShape;
    ATLAGELSZAMGOMB: TBitBtn;
    Panel1: TPanel;
    Panel3: TPanel;
    Panel11: TPanel;
    V21: TPanel;
    E23: TPanel;
    V23: TPanel;
    V22: TPanel;
    E22: TPanel;
    E21: TPanel;
    Shape10: TShape;
    PROFITGOMB: TPanel;
    NYERSPANEL: TPanel;
    PROFITLISTA: TListBox;
    BitBtn2: TBitBtn;
    Label3: TLabel;
    ARFRESEXCELGOMB: TBitBtn;

    procedure FormActivate(Sender: TObject);
    procedure visszagombClick(Sender: TObject);
    procedure AdatKijelzes;
    function FtForm(_sum: integer): string;
    function Nulele(_int: integer):string;
    procedure P1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure P1Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure NAPIARFGOMBClick(Sender: TObject);
    procedure MNBARFGOMBClick(Sender: TObject);
    procedure Irodaregiszter(_k,_i: integer);
    procedure excelgombClick(Sender: TObject);
    procedure ATLAGELSZAMGOMBClick(Sender: TObject);
    procedure PROFITGOMBClick(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure ExcelKill;
    procedure ExcelZaras;

    function Kieg(_s: string; _h: byte): string;
    function EloKieg(_s: string; _h: byte): string;
    procedure ARFRESEXCELGOMBClick(Sender: TObject);
   
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  kijelzes: Tkijelzes;
  _dpanel: array[1..150] of TPanel;
  _va,_ea: array[1..150,1..26] of integer;

  _aktPanel: TPanel;
  _qq,_aktprofit,_vv,_aktmnbprofit,_forgalom,_aktkprofit,_kforgalom: integer;
  _ptss: word;
  _penztarsor: array[1..150] of byte;
  _formula: string;

  _aktirodanev: string;
  _arfolyamTabla: boolean;
  _vp,_ep: array[1..26] of TPanel;

  proc   : PROCESSENTRY32;
  _handle : HWND;
  _Looper : BOOL;



implementation

uses Unit4, Unit5;

{$R *.dfm}

// =============================================================================
               procedure Tkijelzes.FormActivate(Sender: TObject);
// =============================================================================

var i: integer;

begin
  Top    := _top;
  Left   := _left;
  Height := 768;
  width  := 1024;

  for i := 1 to 8 do _korzetIrodadarab[i] := 0;

  Atlagpanel.visible := false;
  _Arfolyamtabla := false;
  
  if _fullMonth then
    begin
      MNBarfGomb.Enabled := true;
      AtlagelszamGomb.Enabled := True;
    end else
    begin
      MNBArfGomb.Enabled := false;
      AtlagelszamGomb.Enabled := False;
    end;  

  _dpanel[1] := P1;
  _dpanel[2] := P2;
  _dpanel[3] := P3;
  _dpanel[4] := P4;
  _dpanel[5] := P5;
  _dpanel[6] := P6;
  _dpanel[7] := P7;
  _dpanel[8] := P8;
  _dpanel[9] := P9;
  _dpanel[10]:= P10;
  _dpanel[11]:= P11;
  _dpanel[12]:= P12;
  _dpanel[13]:= P13;
  _dpanel[14]:= P14;
  _dpanel[15]:= P15;
  _dpanel[16]:= P16;
  _dpanel[17]:= P17;
  _dpanel[18]:= P18;
  _dpanel[19]:= P19;
  _dpanel[20]:= P20;
  _dpanel[21]:= P21;
  _dpanel[22]:= P22;
  _dpanel[23]:= P23;
  _dpanel[24]:= P24;
  _dpanel[25]:= P25;
  _dpanel[26]:= P26;
  _dpanel[27]:= P27;
  _dpanel[28]:= P28;
  _dpanel[29]:= P29;
  _dpanel[30]:= P30;
  _dpanel[31]:= P31;
  _dpanel[32]:= P32;
  _dpanel[33]:= P33;
  _dpanel[34]:= P34;
  _dpanel[35]:= P35;
  _dpanel[36]:= P36;
  _dpanel[37]:= P37;
  _dpanel[38]:= P38;
  _dpanel[39]:= P39;
  _dpanel[40]:= P40;
  _dpanel[41]:= P41;
  _dpanel[42]:= P42;
  _dpanel[43]:= P43;
  _dpanel[44]:= P44;
  _dpanel[45]:= P45;
  _dpanel[46]:= P46;
  _dpanel[47]:= P47;
  _dpanel[48]:= P48;
  _dpanel[49]:= P49;
  _dpanel[50]:= P50;
  _dpanel[51]:= P51;
  _dpanel[52]:= P52;
  _dpanel[53]:= P53;
  _dpanel[54]:= P54;
  _dpanel[55]:= P55;
  _dpanel[56]:= P56;
  _dpanel[57]:= P57;
  _dpanel[58]:= P58;
  _dpanel[59]:= P59;
  _dpanel[60]:= P60;
  _dpanel[61]:= P61;
  _dpanel[62]:= P62;
  _dpanel[63]:= P63;
  _dpanel[64]:= P64;
  _dpanel[65]:= P65;
  _dpanel[66]:= P66;
  _dpanel[67]:= P67;
  _dpanel[68]:= P68;
  _dpanel[69]:= P69;
  _dpanel[70]:= P70;
  _dpanel[71]:= P71;
  _dpanel[72]:= P72;
  _dpanel[73]:= P73;
  _dpanel[74]:= P74;
  _dpanel[75]:= P75;
  _dpanel[76]:= P76;
  _dpanel[77]:= P77;
  _dpanel[78]:= P78;
  _dpanel[79]:= P79;
  _dpanel[80]:= P80;
  _dpanel[81]:= P81;
  _dpanel[82]:= P82;
  _dpanel[83]:= P83;
  _dpanel[84]:= P84;
  _dpanel[85]:= P85;
  _dpanel[86]:= P86;
  _dpanel[87]:= P87;
  _dpanel[88]:= P88;
  _dpanel[89]:= P89;
  _dpanel[90]:= P90;
  _dpanel[91]:= P91;
  _dpanel[92]:= P92;
  _dpanel[93]:= P93;
  _dpanel[94]:= P94;
  _dpanel[95]:= P95;
  _dpanel[96]:= P96;
  _dpanel[97]:= P97;
  _dpanel[98]:= P98;
  _dpanel[99]:= P99;
  _dpanel[100]:= P100;
  _dpanel[101]:= P101;
  _dpanel[102]:= P102;
  _dpanel[103]:= P103;
  _dpanel[104]:= P104;
  _dpanel[105]:= P105;
  _dpanel[106]:= P106;
  _dpanel[107]:= P107;
  _dpanel[108]:= P108;
  _dpanel[109]:= P109;
  _dpanel[110]:= P110;
  _dpanel[111]:= P111;
  _dpanel[112]:= P112;
  _dpanel[113]:= P113;
  _dpanel[114]:= P114;
  _dpanel[115]:= P115;
  _dpanel[116]:= P116;
  _dpanel[117]:= P117;
  _dpanel[118]:= P118;
  _dpanel[119]:= P119;
  _dpanel[120]:= P120;
  _dpanel[121]:= P121;
  _dpanel[122]:= P122;
  _dpanel[123]:= P123;
  _dpanel[124]:= P124;
  _dpanel[125]:= P125;
  _dpanel[126]:= P126;
  _dpanel[127]:= P127;
  _dpanel[128]:= P128;
  _dpanel[129]:= P129;
  _dpanel[130]:= P130;
  _dpanel[131]:= P131;
  _dpanel[132]:= P132;
  _dpanel[133]:= P133;
  _dpanel[134]:= P134;
  _dpanel[135]:= P135;
  _dpanel[136]:= P136;
  _dpanel[137]:= P137;
  _dpanel[138]:= P138;
  _dpanel[139]:= P139;
  _dpanel[140]:= P140;
  _dpanel[141]:= P141;
  _dpanel[142]:= P142;
  _dpanel[143]:= P143;
  _dpanel[144]:= P144;
  _dpanel[145]:= P145;
  _dpanel[146]:= P146;
  _dpanel[147]:= P147;
  _dpanel[148]:= P148;
  _dpanel[149]:= P149;
  _dpanel[150]:= P150;

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
  _vp[14]:= v14;
  _vp[15]:= v15;
  _vp[16]:= v16;
  _vp[17]:= v17;
  _vp[18]:= v18;
  _vp[19]:= v19;
  _vp[20]:= v20;
  _vp[21]:= v21;
  _vp[22]:= v22;
  _vp[23]:= v23;

  _ep[1] := e1;
  _ep[2] := e2;
  _ep[3] := e3;
  _ep[4] := e4;
  _ep[5] := e5;
  _ep[6] := e6;
  _ep[7] := e7;
  _ep[8] := e8;
  _ep[9] := e9;
  _ep[10]:= e10;
  _ep[11]:= e11;
  _ep[12]:= e12;
  _ep[13]:= e13;
  _ep[14]:= e14;
  _ep[15]:= e15;
  _ep[16]:= e16;
  _ep[17]:= e17;
  _ep[18]:= e18;
  _ep[19]:= e19;
  _ep[20]:= e20;
  _ep[21]:= e21;
  _ep[22]:= e22;
  _ep[23]:= e23;

  AlapPanel.Visible := False;
  _startNaps:= inttostr(_kertev)+'.'+nulele(_kertho)+'.'+nulele(_tolnap);
  _endNaps  := leftstr(_startNaps,8)+nulele(_ignap);

  StartNappanel.Caption := _startnaps;
  EndNapPanel.Caption   := _endNaps;

  StartNapPanel.repaint;
  EndNapPanel.Repaint;
  AdatKijelzes;
end;

// =============================================================================
                     procedure TKijelzes.AdatKijelzes;
// =============================================================================


begin

  _maxPtar   := 0;
  _maxprofit := 0;
  _qq :=1;
  while _qq<=150 do
    begin
      if _tprofit[_qq]>_maxprofit then
        begin
          _maxProfit := _tprofit[_qq];
          _maxPtar := _qq;
        end;
      inc(_qq);
    end;

  // ---------------------------------------------------------------------------

  _qq := 1;
  while _qq<=150 do
    begin
      _aktpanel := _dpanel[_qq];
      _aktprofit := _tprofit[_qq];
      if _aktprofit=0 then
        begin
          _aktpanel.color := $d0d0d0;
          _aktpanel.Caption := '';
          _aktpanel.Cursor := crDefault;
        end else
        begin
          _aktKorzet  := _hErtekTar[_qq];
          Irodaregiszter(_aktkorzet,_qq);

          if _aktprofit<0 then _aktpanel.Color := $D0FFFF
          else _aktpanel.Color := clWhite;

          if _maxptar=_qq then _aktpanel.color := $FFB0FF;

          _aktpanel.Font.Color := clTeal;
          _aktpanel.Caption := ftform(_aktprofit);
          _aktpanel.Cursor := crHandPoint;
        end;

      _aktpanel.Repaint;
      inc(_qq);
    end;
  AlapPanel.visible := true;
  AlapPanel.repaint;
end;

// =============================================================================
             procedure Tkijelzes.visszagombClick(Sender: TObject);
// =============================================================================

begin
  if _vanexcel then ExcelZaras;
  Modalresult := 1;
end;

// =============================================================================
             function Tkijelzes.FtForm(_sum: integer): string;
// =============================================================================


var _p1,_wsum: integer;
   _elojel,_sums: string;

begin
  result := '';
  if _sum=0 then exit;
  result := inttostr(_sum);
  _elojel := '';
  if _sum<0 then
    begin
      _elojel := '-';
      _sum := abs(_sum);
    end;
  _sums := inttostr(_sum);

  if _sum<1000 then
    begin
      result := _elojel + _sums;
      exit;
    end;  
  _wsum := length(_sums);
  if _wsum>6 then
    begin
      _p1 := _wsum-6;
      result := leftstr(_sums,_p1)+' '+midstr(_sums,_p1+1,3)+' '+midstr(_sums,_p1+4,3);
    end;
  if (_wsum>3) and (_wsum<7) then
    begin
      _p1 := _wsum-3;
      result := leftstr(_sums,_p1)+' '+midstr(_sums,_p1+1,3);
    end;
  result := _elojel + result;
end;

// =============================================================================
               function TKijelzes.Nulele(_int: integer):string;
// =============================================================================

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;


// =============================================================================
     procedure Tkijelzes.P1MouseMove(Sender: TObject; Shift: TShiftState; X,
                                                                  Y: Integer);
// =============================================================================


begin
  if _arfolyamTabla then exit;

  _tag := TPanel(sender).Tag;
  _aktirodanev := _irodaNev[_tag];
  Irodanevpanel.Caption := inttostr(_tag)+'. '+_aktirodanev;
  Irodanevpanel.repaint;
end;



// =============================================================================
               procedure Tkijelzes.P1Click(Sender: TObject);
// =============================================================================


var _tag,_sor,_oszlop,_tleft: integer;

begin
  if _arfolyamtabla then exit;

  _arfolyamTabla := True;
  _tag := TPanel(Sender).tag;
  _sor := trunc((_tag-1)/8);
  _oszlop := _tag - trunc(8*_sor);
  _tleft := 0;
  if _tag>144 then _oszlop := _oszlop + 1;

  case _oszlop of
    1: _tleft := 140;
    2: _tleft := 270;
    3: _tLeft := 395;
    4: _tleft := 520;
    5: _tleft := 650;
    6: _tleft := 310;
    7: _tleft := 440;
    8: _tleft := 560;
  end;

  _vv := 1;
  while _vv<=26 do
    begin
      _aktPanel := _vp[_vv];
      _aktpanel.Caption := Ftform(_tVatlagArf[_tag,_vv]);
      _aktPanel := _ep[_vv];
      _aktpanel.Caption := Ftform(_tEatlagArf[_tag,_vv]);
      inc(_vv);
    end;

  with atlagPanel do
    begin
      Top := 122;
      Left := _tleft;
      Visible := True;
    end;
  Atlagpanel.repaint;
end;

// =============================================================================
               procedure Tkijelzes.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  AtlagPanel.Visible := False;
  _ArfolyamTabla := false;
end;

procedure Tkijelzes.NAPIARFGOMBClick(Sender: TObject);
begin
  _QQ := 1;
  while _qq<=150 do
    begin
      _aktpanel := _dpanel[_qq];
      _aktprofit := _tprofit[_qq];
      if _aktprofit=0 then
        begin
          _aktpanel.color := $d0d0d0;
          _aktpanel.Caption := '';
          _aktpanel.Cursor := crDefault;
        end else
        begin
          if _aktprofit<0 then _aktpanel.Color := $D0FFFF
          ELSE _aktpanel.Color := clWhite;
          if _maxptar=_qq then _aktpanel.color := $FFB0FF;
          _aktpanel.Font.Color := clTeal;
          _aktpanel.Caption := ftform(_aktprofit);
          _aktpanel.Cursor := crHandPoint;
        end;

      _aktpanel.Repaint;
      inc(_qq);
    end;
end;

procedure Tkijelzes.MNBARFGOMBClick(Sender: TObject);
begin
  _QQ := 1;
  while _qq<=150 do
    begin
      _aktpanel := _dpanel[_qq];
      _aktprofit := _tmnbprofit[_qq];
      if _aktprofit=0 then
        begin
          _aktpanel.color := $d0d0d0;
          _aktpanel.Caption := '';
          _aktpanel.Cursor := crDefault;
        end else
        begin
          if _aktprofit<0 then _aktpanel.Color := $D0FFFF
          ELSE _aktpanel.Color := clWhite;
          if _maxptar=_qq then _aktpanel.color := $FFB0FF;
          _aktpanel.Font.Color := clred;
          _aktpanel.Caption := ftform(_aktprofit);
          _aktpanel.Cursor := crHandPoint;
        end;
      _aktpanel.Repaint;
      inc(_qq);
    end;

end;


procedure TKijelzes.Irodaregiszter(_k,_i: integer);

var _aktkdb,_yy: integer;

begin
  _yy := Form1.scanetar(_k);
  _aktkdb := _korzetIrodadarab[_yy];
  inc(_aktkdb);
  _korzetIrodaDarab[_yy] := _aktkdb;
  _korzetirodak[_yy,_aktkdb] := _i;
end;


procedure Tkijelzes.excelgombClick(Sender: TObject);

var _haszbe: integer;

begin
  _haszbe := HaszonfelvivoForm.showModal;
  if _haszbe<>1 then exit;

  excelGomb.Visible := false;
  
  _qq := 1;
  while _qq<=150 do
    begin
      _aktpanel := _dpanel[_qq];
      _aktprofit := _wprofit[_qq];
      if _aktprofit>0 then
        begin
          _aktpanel.Color := clYellow;
          _aktpanel.Font.Color := clBlack;
          _aktpanel.Caption := ftform(_aktprofit);
          _aktpanel.Cursor := crHandPoint;
        end else
        begin
          _aktpanel.Caption := '';
          _aktpanel.Color := $808080;
        end;  
      inc(_qq);
    end;

   excelkeszites.showmodal;
end;

procedure Tkijelzes.ATLAGELSZAMGOMBClick(Sender: TObject);
begin
   _QQ := 1;
  while _qq<=150 do
    begin
      _aktpanel := _dpanel[_qq];
      _aktprofit := _tSprofit[_qq];
      if _aktprofit=0 then
        begin
          _aktpanel.color := $d0d0d0;
          _aktpanel.Caption := '';
          _aktpanel.Cursor := crDefault;
        end else
        begin
          if _aktprofit<0 then _aktpanel.Color := $D0FFFF
          ELSE _aktpanel.Color := clWhite;
          if _maxptar=_qq then _aktpanel.color := $FFB0FF;
          _aktpanel.Font.Color := clBlue;
          _aktpanel.Caption := ftform(_aktprofit);
          _aktpanel.Cursor := crHandPoint;
        end;
      _aktpanel.Repaint;
      inc(_qq);
    end;

end;


procedure Tkijelzes.PROFITGOMBClick(Sender: TObject);

var _y: byte;
    _mondat,_aktirnev: string;

begin
  _ptss := 0;
  _y := 1;
  while _y<=150 do
    begin
      _aktirnev := KIEG(_irodanev[_y],25);
      _aktnyersProfit := _nyersProfit[_y];
      if _aktnyersProfit<>0 then
        begin
         inc(_ptss);
         _penztarsor[_ptss] := _y;
         _mondat := elokieg(inttostr(_y),3)+'. ' + _aktirnev + ' = ';
          _mondat := _mondat + eloKieg(ftform(_aktnyersprofit),13)+' Ft';
          ProfitLista.Items.Add(_mondat);
        end;
      inc(_y);
    end;

  with NyersPanel do
    begin
      top := 56;
      left := 8;
      Visible := true;
      Repaint;
    end;

  ArfresexcelGomb.Enabled := True;  
  ProfitLista.ItemIndex := 0;
  Activecontrol := ProfitLista;


end;

procedure Tkijelzes.BitBtn2Click(Sender: TObject);
begin
  nYERSPANEL.Visible := FALSE;
end;


function TKijelzes.Kieg(_s: string; _h: byte): string;

begin
  while length(_s)<_h do _s := _s + ' ';
  result := _s;
end;


function TKijelzes.EloKieg(_s: string; _h: byte): string;

begin
  while length(_s)<_h do _s := ' ' + _s;
  result := _s;
end;



procedure Tkijelzes.ARFRESEXCELGOMBClick(Sender: TObject);

var _focim: string;
    _korzet,_kdarab,_kkezdosor,_pt,_aktpt,_kvegsor: word;

begin

  ArfresExcelGomb.Enabled := False;
  _vanexcel := true;

  _oxl := CreateOleObject('EXCEL.APPLICATION');
  _OWB := _oxl.workbooks.add[1];

  _oxl.range['A1:A1'].Columnwidth := 1;
  _oxl.range['B1:B1'].Columnwidth := 1;
  _oxl.range['C1:C1'].Columnwidth := 10;
  _oxl.range['D1:D1'].Columnwidth := 32;
  _oxl.range['E1:E1'].Columnwidth := 17;
  _oxl.range['F1:F1'].Columnwidth := 17;
  _oxl.range['G1:G1'].Columnwidth := 17;
  _oxl.range['H1:H1'].Columnwidth := 17;
  _oxl.range['I1:I1'].Columnwidth := 17;
  _oxl.range['J1:J1'].Columnwidth := 17;
  _oxl.range['K1:K1'].Columnwidth := 17;

  _rangestr := 'B2:K2';
  _oxl.range[_rangestr].Mergecells := true;
  _oxl.range[_rangestr].Horizontalalignment := -4108;
  _oxl.range[_rangestr].Font.size := 16;
  _oxl.range[_rangestr].font.italic := True;
  _focim := _kdatums+' ÉS ' + _vDatums + ' KÖZÖTTI NETTÓ ÁRFOLYAMRÉSEK';
  _oxl.cells[2,2] := _focim;

  _rangestr := 'C4:K4';
  _oxl.range[_rangestr].Font.Size := 12;
  _oxl.range[_rangestr].Font.Bold := True;
  _oxl.range[_rangestr].Horizontalalignment := -4108;

  _rangestr := 'I5:K5';
  _oxl.range[_rangestr].Font.Bold := True;

  _rangestr := 'E5:K5';
  _oxl.range[_rangestr].Font.Size := 12;
  _oxl.range[_rangestr].Font.Italic := True;
  _oxl.range[_rangestr].Horizontalalignment := -4108;

  _oxl.range['C4:C5'].MergeCells := True;
  _oxl.range['D4:D5'].MergeCells := True;
  _oxl.range['E4:F4'].MergeCells := True;
  _oxl.range['G4:H4'].MergeCells := True;


  _oxl.range['C4:D5'].Verticalalignment := -4108;

  _oxl.cells[4,3] := 'PÉNZTÁRSZÁM';
  _oxl.cells[4,4] := 'PÉNZTÁR MEGNEVEZÉSE';
  _oxl.cells[4,5] := 'ENGEDMÉNY NÉLKÜLI';
  _oxl.cells[4,7] := 'áRFOLYAM ENGEDMÉNNYEL';

  _oxl.cells[5,5] := 'ÁRFOLYAMRÉS';
  _oxl.cells[5,6] := 'FORGALOM';
  _oxl.cells[5,7] := 'ÁRFOLYAMRÉS';
  _oxl.cells[5,8] := 'FORGALOM';

  _oxl.cells[4,9] := '50.000';
  _oxl.cells[5,9] := 'ALATT';

  _oxl.cells[4,10] := '50.000';
  _oxl.cells[5,10] := '-300.000';

  _oxl.cells[4,11] := '300.000';
  _oxl.cells[5,11] := 'FELETT';

  _oxl.range['A6:A6'].Select;
  _oxl.activewindow.FreezePanes := True;

  _PRISOR := 7;
  _KORZET := 1;

  while _korzet<=8 do
    begin
      _kzNev  := _korzetNev[_korzet];
      _kdarab := _korzetIrodaDarab[_korzet];

      _rangestr := 'D' + inttostr(_prisor)+':G'+inttostr(_prisor);
      _oxl.range[_rangestr].Mergecells := True;
      _oxl.cells[_prisor,4] := _kznev + ' KÖRZET';
      _oxl.range[_rangestr].font.Size := 14;
      _oxl.range[_rangestr].font.Bold := True;
      _oxl.range[_rangestr].font.Italic := True;
      _oxl.range[_rangestr].Horizontalalignment := -4108;
      _prisor := _prisor + 2;
      _kkezdosor := _prisor;

      _pt := 1;
      while _pt<=_kdarab do
        begin
          _aktpt      := _korzetirodak[_korzet,_pt];
          _xsprofit   := _xpsprofit[_aktpt];
          _xsforgalom := _xpsForgalom[_aktpt];
          _xsminiforg := _xpsminiforg[_aktpt];
          _xsmidiforg := _xpsmidiforg[_aktpt];
          _xsmaxiforg := _xpsmaxiforg[_aktpt];
          _xkprofit   := _xpkprofit[_aktpt];
          _xkforgalom := _xpkforgalom[_aktpt];
          if _aktprofit<>0 then
            begin
              _oxl.cells[_prisor,3] := _aktpt;
              _oxl.cells[_prisor,4] := _irodanev[_aktpt];
              _oxl.cells[_prisor,5] := _xsprofit;
              _oxl.cells[_prisor,6] := _xsforgalom;
              _oxl.cells[_prisor,7] := _xkprofit;
              _oxl.cells[_prisor,8] := _xkforgalom;
              _oxl.cells[_prisor,9] := _xsminiforg;
              _oxl.cells[_prisor,10]:= _xsmidiforg;
              _oxl.cells[_prisor,11]:= _xsmaxiforg;

              inc(_prisor);
            end;
          inc(_pt);
        end;

      _kvegsor := _prisor-1;
      _rangestr := 'C'+inttostr(_kkezdosor)+':C' + inttostr(_kvegsor);
      _oxl.range[_rangestr].Horizontalalignment := -4108;

      _rangestr := 'E'+inttostr(_kkezdosor)+':K' + inttostr(_kvegsor);
      _oxl.range[_rangestr].Horizontalalignment := -4108;
      _oxl.range[_rangestr].Numberformat := '### ### ###';

      _rangestr := 'C'+inttostr(_kkezdosor)+':H' + inttostr(_kvegsor);
      _oxl.range[_rangestr].Font.Size := 12;

      _rangestr := 'C'+inttostr(_prisor)+':D'+inttostr(_prisor);
      _oxl.range[_rangestr].mergeCells := True;
      _oxl.cells[_prisor,5].numberformat := '### ### ###';

      _rangestr := 'C'+inttostr(_prisor)+':K'+inttostr(_prisor);
      _oxl.range[_rangestr].font.size := 14;
      _oxl.range[_rangestr].font.Bold := True;
      _oxl.range[_rangestr].font.Italic := True;
      _oxl.range[_rangestr].Horizontalalignment := -4108;

      _oxl.cells[_prisor,3] := lowercase(_kzNev)+' körzet összesen';
      _rangestr := 'E' + inttostr(_kkezdosor)+':E'+inttostr(_kvegsor);
      _formula := '=SUM('+_rangestr+')';
      _rangestr := 'E'+inttostr(_prisor)+':E'+inttostr(_prisor);
      _oxl.range[_rangestr].formula := _formula;

      _rangestr := 'F' + inttostr(_kkezdosor)+':F'+inttostr(_kvegsor);
      _formula := '=SUM('+_rangestr+')';
      _rangestr := 'F'+inttostr(_prisor)+':F'+inttostr(_prisor);
      _oxl.range[_rangestr].formula := _formula;

      _rangestr := 'G' + inttostr(_kkezdosor)+':G'+inttostr(_kvegsor);
      _formula := '=SUM('+_rangestr+')';
      _rangestr := 'G'+inttostr(_prisor)+':G'+inttostr(_prisor);
      _oxl.range[_rangestr].formula := _formula;

      _rangestr := 'H' + inttostr(_kkezdosor)+':H'+inttostr(_kvegsor);
      _formula := '=SUM('+_rangestr+')';
      _rangestr := 'H'+inttostr(_prisor)+':H'+inttostr(_prisor);
      _oxl.range[_rangestr].formula := _formula;

      _rangestr := 'I' + inttostr(_kkezdosor)+':I'+inttostr(_kvegsor);
      _formula := '=SUM('+_rangestr+')';
      _rangestr := 'I'+inttostr(_prisor)+':I'+inttostr(_prisor);
      _oxl.range[_rangestr].formula := _formula;

      _rangestr := 'J' + inttostr(_kkezdosor)+':J'+inttostr(_kvegsor);
      _formula := '=SUM('+_rangestr+')';
      _rangestr := 'J'+inttostr(_prisor)+':J'+inttostr(_prisor);
      _oxl.range[_rangestr].formula := _formula;

      _rangestr := 'K' + inttostr(_kkezdosor)+':K'+inttostr(_kvegsor);
      _formula := '=SUM('+_rangestr+')';
      _rangestr := 'K'+inttostr(_prisor)+':K'+inttostr(_prisor);
      _oxl.range[_rangestr].formula := _formula;

      _prisor := _prisor + 2;
      inc(_korzet);
    end;
  _oxl.visible := true;
end;

procedure TKijelzes.ExcelZaras;

begin
   _oxl.Quit;
   _oxl := Unassigned;
   _owb := Unassigned;

   _vanexcel := False;

   ExcelKill;
end;

// =============================================================================
                  procedure TKijelzes.ExcelKill;
// =============================================================================


var
  _fileName,_filePath: String;

begin

  Proc.dwSize := SizeOf(Proc);
  _handle := CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
  _Looper := Process32First(_handle,proc);

  while Integer(_Looper) <> 0 do
    begin
      _filepath := Proc.szExeFile;
      _fileName := UpperCase(ExtractFileName(_filepath));

      if _fileName = 'EXCEL.EXE' then
        begin
          TerminateProcess(OpenProcess(1,Bool(1),proc.th32ProcessID),0);
          break;
        end;

      _Looper := Process32Next(_handle,proc);
    end;
  CloseHandle(_handle);
end;


end.
