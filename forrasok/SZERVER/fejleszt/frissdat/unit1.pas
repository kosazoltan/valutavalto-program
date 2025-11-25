unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  strutils, ExtCtrls, IBTable;

type
  TForm1 = class(TForm)
    quitgomb: TBitBtn;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    Label1: TLabel;
    Label2: TLabel;
    verziolabel: TLabel;
    KOCKAPANEL: TPanel;
    P1: TPanel;
    P18: TPanel;
    P35: TPanel;
    P52: TPanel;
    P69: TPanel;
    P86: TPanel;
    P103: TPanel;
    P120: TPanel;
    P137: TPanel;
    P154: TPanel;
    P19: TPanel;
    P9: TPanel;
    P8: TPanel;
    P12: TPanel;
    P10: TPanel;
    P11: TPanel;
    P7: TPanel;
    P6: TPanel;
    P5: TPanel;
    P4: TPanel;
    P2: TPanel;
    P15: TPanel;
    P13: TPanel;
    P16: TPanel;
    P17: TPanel;
    P14: TPanel;
    P3: TPanel;
    P23: TPanel;
    P75: TPanel;
    P42: TPanel;
    P58: TPanel;
    P74: TPanel;
    P57: TPanel;
    P40: TPanel;
    P97: TPanel;
    P90: TPanel;
    P39: TPanel;
    P162: TPanel;
    P25: TPanel;
    P161: TPanel;
    P160: TPanel;
    P159: TPanel;
    P158: TPanel;
    P92: TPanel;
    P73: TPanel;
    P56: TPanel;
    P98: TPanel;
    P89: TPanel;
    P72: TPanel;
    P146: TPanel;
    P145: TPanel;
    P144: TPanel;
    P109: TPanel;
    P142: TPanel;
    P141: TPanel;
    P157: TPanel;
    P156: TPanel;
    P139: TPanel;
    P99: TPanel;
    P88: TPanel;
    P84: TPanel;
    P85: TPanel;
    P153: TPanel;
    P152: TPanel;
    P151: TPanel;
    P167: TPanel;
    P150: TPanel;
    P149: TPanel;
    P148: TPanel;
    P147: TPanel;
    P166: TPanel;
    P82: TPanel;
    P91: TPanel;
    P93: TPanel;
    P140: TPanel;
    P164: TPanel;
    P163: TPanel;
    P55: TPanel;
    P37: TPanel;
    P24: TPanel;
    P71: TPanel;
    P22: TPanel;
    P20: TPanel;
    P21: TPanel;
    P36: TPanel;
    P53: TPanel;
    P70: TPanel;
    P87: TPanel;
    P100: TPanel;
    P38: TPanel;
    P54: TPanel;
    P155: TPanel;
    P121: TPanel;
    P138: TPanel;
    P33: TPanel;
    P31: TPanel;
    P30: TPanel;
    P80: TPanel;
    P67: TPanel;
    P46: TPanel;
    P45: TPanel;
    P44: TPanel;
    P43: TPanel;
    P77: TPanel;
    P78: TPanel;
    P83: TPanel;
    P96: TPanel;
    P79: TPanel;
    P76: TPanel;
    P169: TPanel;
    P170: TPanel;
    P136: TPanel;
    P119: TPanel;
    P68: TPanel;
    P34: TPanel;
    P51: TPanel;
    P94: TPanel;
    P95: TPanel;
    P64: TPanel;
    P66: TPanel;
    P81: TPanel;
    P168: TPanel;
    P65: TPanel;
    P63: TPanel;
    P62: TPanel;
    P47: TPanel;
    P48: TPanel;
    P49: TPanel;
    P32: TPanel;
    P50: TPanel;
    P165: TPanel;
    P108: TPanel;
    P110: TPanel;
    P143: TPanel;
    P111: TPanel;
    P107: TPanel;
    P104: TPanel;
    P113: TPanel;
    P122: TPanel;
    P112: TPanel;
    P105: TPanel;
    P106: TPanel;
    P114: TPanel;
    P116: TPanel;
    P115: TPanel;
    P117: TPanel;
    P123: TPanel;
    P124: TPanel;
    P125: TPanel;
    P29: TPanel;
    P28: TPanel;
    P27: TPanel;
    P61: TPanel;
    P60: TPanel;
    P26: TPanel;
    P41: TPanel;
    P59: TPanel;
    P101: TPanel;
    P118: TPanel;
    P126: TPanel;
    P131: TPanel;
    P129: TPanel;
    P127: TPanel;
    P128: TPanel;
    P102: TPanel;
    P130: TPanel;
    P134: TPanel;
    P135: TPanel;
    P133: TPanel;
    P132: TPanel;
    FRISSQUERY: TIBQuery;
    FRISSDBASE: TIBDatabase;
    FRISSTRANZ: TIBTransaction;
    ALTQUERY: TIBQuery;
    ALTDBASE: TIBDatabase;
    ALTTRANZ: TIBTransaction;
    FRISSTABLA: TIBTable;
    VERZIOCOMBO: TComboBox;
    CIKLUS: TTimer;
    VERZIOVALTOGOMB: TBitBtn;
    Panel1: TPanel;
    Label3: TLabel;
    Label4: TLabel;
    PNEVEDIT: TEdit;
    DATUMPANEL: TPanel;
    IDOPANEL: TPanel;
    Label5: TLabel;

    procedure FormActivate(Sender: TObject);
    procedure PenztarBeolvasas;
    procedure quitgombClick(Sender: TObject);
    procedure SetTombok;
    procedure DispCiklus;
    procedure CIKLUSTimer(Sender: TObject);
    procedure VERZIOCOMBOChange(Sender: TObject);
    procedure VERZIOVALTOGOMBClick(Sender: TObject);
    procedure P1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure KOCKAPANELMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _p: array[1..170] of TPanel;
  _verznames: array[1..99] of string;
  _dtime: array[1..170] of string;
  _aktKocka: TPanel;
  _vdb,_y,_elo,_pt,_wat: byte;
  _ss,_qq,_zz,_flen,_aktptnum,_vIndex: integer;
  _srec: TSearchRec;
  _minta,_aktfile,_aktpath,_mondat,_nums,_aktido,_ptarnev,_pcs,_aktnap: string;
  _vs,_mezo,_dstring,_dTimeData,_aktdate,_akttime: string;
  _sorveg: string = chr(13)+ chr(10);
  _textolvas: textfile;
  _irstat: array[1..170] of byte;
  _irnev: array[1..170] of string;
  _verzio,_aktverzio,_aktptnev,_aktdtime: string;
  _pcolor : Tcolor;


implementation

{$R *.dfm}

// =============================================================================
                  procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top  := 180;
  Left := 200;

  Settombok;
  PenztarBeolvasas;
  VerzioCombo.Items.clear;

  _pcs := 'SELECT * FROM FRISSITESEK' + _sorveg;
  _pcs := _pcs + 'ORDER BY VERZIO DESC';
  Frissdbase.Connected := True;
  with FrissQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;
  FrissQuery.First;

  _vdb := 0;
  while not FrissQuery.Eof do
    begin
      _vs := FrissQuery.FieldByName('VERZIO').asString;
      inc(_vdb);
      _verznames[_vdb] := _vs;
      VerzioCombo.Items.add(_vs);
      FrissQuery.next;
    end;

  FrissQuery.close;
  Frissdbase.close;

  VerzioCombo.ItemIndex := 0;
  _aktverzio := VerzioCOmbo.items[0];

  Dispciklus;
end;

// =============================================================================
            procedure TForm1.quitgombClick(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;

// =============================================================================
               procedure TForm1.PenztarBeolvasas;
// =============================================================================

var _uzlet: integer;
    _nev: string;
    i: byte;

begin

  for i := 1 to 170 do
    begin
      _irnev[i]  := '';
      _irStat[i] := 0;
    end;

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE CLOSED=' + chr(39)+'N' + chr(39) + _sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  recdbase.Connected := TRUE;
  with recquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not recquery.eof do
    begin
      _uzlet := recquery.FieldByname('UZLET').asInteger;
      _nev := recQuery.FieldByName('KESZLETNEV').ASsTRING;
      _irnev[_uzlet] := trim(_nev);
      _irstat[_uzlet] := 1;
      recquery.next;
    end;
  recquery.close;
  recdbase.close;

  // -----------------------------------------------------

  altdbase.Connected := TRUE;
  with altquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not altquery.eof do
    begin
      _uzlet := altquery.FieldByname('UZLET').asInteger;
      _nev := altQuery.FieldByName('KESZLETNEV').ASsTRING;
      _irnev[_uzlet] := _nev;
      _irstat[_uzlet]:= 1;
      altquery.next;
    end;
  altquery.close;
  altdbase.close;
  
  _irstat[10] := 0;
  _irstat[20] := 0;
  _irstat[40] := 0;
  _irstat[50] := 0;
  _irstat[63] := 0;
  _irstat[75] := 0;
  _irstat[120] := 0;
  _irstat[145] := 0;


  _y := 1;
  while _y<=170 do // 170 do
    begin
      _aktKocka := _p[_y];

      if _irstat[_y]=0 then
        begin
          _aktkocka.color := clBlack;
          _aktkocka.Font.Color := clSilver;
        end else
        begin
          _aktkocka.color := clRed;
          _aktkocka.Font.Color := clyellow;
        end;
      inc(_y);
    end;
end;


// =============================================================================
                         procedure tform1.dispciklus;
// =============================================================================

var i: byte;

begin
  Activecontrol := quitGomb;
  for i := 1 to 170 do _dtime[i] := '';
  VerzioLabel.Caption := _aktverzio;
  VerzioLabel.repaint;

  _pcs := 'SELECT * FROM FRISSITESEK' + _sorveg;
  _pcs := _pcs + 'WHERE VERZIO=' + chr(39)+_aktverzio+chr(39);

  FrissDbase.Connected := true;
  with FrissQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  _y := 1;
  while _y<=170 do
    begin
      _mezo := 'V' + inttostr(_y);
      _dtimeData := trim(FrissQuery.FieldByName(_mezo).AsString);
      _dTime[_y] := _dTimeData;
      _aktkocka := _p[_y];

      if leftstr(_dTimeData,1)='2' then
        begin
          _aktkocka.Color := clLime;
          _aktkocka.Font.Color := clBlack;
        end else
        begin
          if _aktkocka.color<>clBlack then
            begin
              _aktkocka.Color := clRed;
              _aktkocka.Font.Color := clyellow;
            end;  
        end;
      inc(_y);
    end;
  Ciklus.enabled := true;
end;

// =============================================================================
                         procedure TForm1.setTombok;
// =============================================================================

begin
  _p[1] := P1;
  _p[2] := P2;
  _p[3] := P3;
  _p[4] := P4;
  _p[5] := P5;
  _p[6] := P6;
  _p[7] := P7;
  _p[8] := P8;
  _p[9] := P9;

  _p[10] := P10;
  _p[11] := P11;
  _p[12] := P12;
  _p[13] := P13;
  _p[14] := P14;
  _p[15] := P15;
  _p[16] := P16;
  _p[17] := P17;
  _p[18] := P18;
  _p[19] := P19;

  _p[20] := P20;
  _p[21] := P21;
  _p[22] := P22;
  _p[23] := P23;
  _p[24] := P24;
  _p[25] := P25;
  _p[26] := P26;
  _p[27] := P27;
  _p[28] := P28;
  _p[29] := P29;

  _p[30] := P30;
  _p[31] := P31;
  _p[32] := P32;
  _p[33] := P33;
  _p[34] := P34;
  _p[35] := P35;
  _p[36] := P36;
  _p[37] := P37;
  _p[38] := P38;
  _p[39] := P39;

  _p[40] := P40;
  _p[41] := P41;
  _p[42] := P42;
  _p[43] := P43;
  _p[44] := P44;
  _p[45] := P45;
  _p[46] := P46;
  _p[47] := P47;
  _p[48] := P48;
  _p[49] := P49;

  _p[50] := P50;
  _p[51] := P51;
  _p[52] := P52;
  _p[53] := P53;
  _p[54] := P54;
  _p[55] := P55;
  _p[56] := P56;
  _p[57] := P57;
  _p[58] := P58;
  _p[59] := P59;

  _p[60] := P60;
  _p[61] := P61;
  _p[62] := P62;
  _p[63] := P63;
  _p[64] := P64;
  _p[65] := P65;
  _p[66] := P66;
  _p[67] := P67;
  _p[68] := P68;
  _p[69] := P69;

  _p[70] := P70;
  _p[71] := P71;
  _p[72] := P72;
  _p[73] := P73;
  _p[74] := P74;
  _p[75] := P75;
  _p[76] := P76;
  _p[77] := P77;
  _p[78] := P78;
  _p[79] := P79;

  _p[80] := P80;
  _p[81] := P81;
  _p[82] := P82;
  _p[83] := P83;
  _p[84] := P84;
  _p[85] := P85;
  _p[86] := P86;
  _p[87] := P87;
  _p[88] := P88;
  _p[89] := P89;

  _p[90] := P90;
  _p[91] := P91;
  _p[92] := P92;
  _p[93] := P93;
  _p[94] := P94;
  _p[95] := P95;
  _p[96] := P96;
  _p[97] := P97;
  _p[98] := P98;
  _p[99] := P99;

  _p[100] := P100;
  _p[101] := P101;
  _p[102] := P102;
  _p[103] := P103;
  _p[104] := P104;
  _p[105] := P105;
  _p[106] := P106;
  _p[107] := P107;
  _p[108] := P108;
  _p[109] := P109;

  _p[110] := P110;
  _p[111] := P111;
  _p[112] := P112;
  _p[113] := P113;
  _p[114] := P114;
  _p[115] := P115;
  _p[116] := P116;
  _p[117] := P117;
  _p[118] := P118;
  _p[119] := P119;

  _p[120] := P120;
  _p[121] := P121;
  _p[122] := P122;
  _p[123] := P123;
  _p[124] := P124;
  _p[125] := P125;
  _p[126] := P126;
  _p[127] := P127;
  _p[128] := P128;
  _p[129] := P129;

  _p[130] := P130;
  _p[131] := P131;
  _p[132] := P132;
  _p[133] := P133;
  _p[134] := P134;
  _p[135] := P135;
  _p[136] := P136;
  _p[137] := P137;
  _p[138] := P138;
  _p[139] := P139;

  _p[140] := P140;
  _p[141] := P141;
  _p[142] := P142;
  _p[143] := P143;
  _p[144] := P144;
  _p[145] := P145;
  _p[146] := P146;
  _p[147] := P147;
  _p[148] := P148;
  _p[149] := P149;

  _p[150] := P150;
  _p[151] := P151;
  _p[152] := P152;
  _p[153] := P153;
  _p[154] := P154;
  _p[155] := P155;
  _p[156] := P156;
  _p[157] := P157;
  _p[158] := P158;
  _p[159] := P159;

  _p[160] := P160;
  _p[161] := P161;
  _p[162] := P162;
  _p[163] := P163;
  _p[164] := P164;
  _p[165] := P165;
  _p[166] := P166;
  _p[167] := P167;
  _p[168] := P168;
  _p[169] := P169;
  _p[170] := P170;
end;

// =============================================================================
               procedure TForm1.CIKLUSTimer(Sender: TObject);
// =============================================================================

begin
  Ciklus.Enabled := False;
  dispciklus;
end;

procedure TForm1.VERZIOCOMBOChange(Sender: TObject);
begin
  VerzioValtogomb.Visible := true;
  Verziovaltogomb.repaint;
  _vindex := VerzioCombo.itemindex;
  _aktverzio := trim(VerzioCombo.Items[_vindex]);
  DispCiklus;
end;



procedure TForm1.VERZIOVALTOGOMBClick(Sender: TObject);
begin
  Verziovaltogomb.Visible := False;
  Activecontrol := VerzioCombo;
end;



procedure TForm1.P1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  _aktKocka := TPanel(sender);
  _pt := _aktKocka.tag;
  _pcolor := _aktkocka.color;

  if _pcolor=clBlack then
    begin
      Pnevedit.Text := 'itt nincsen pénztár';
      DatumPanel.Caption := '';
      IdoPanel.Caption := '';
      exit;
    end;

  _aktptnev := _irnev[_pt];
  Pnevedit.Text := _aktptnev;

  if _pcolor=clLime then
    begin
      _aktdtime := _dtime[_pt];
      _aktdate := leftstr(_aktdtime,10);
      _akttime := midstr(_aktdTime,12,5);

      _wat := length(_akttime);
      if ord(_akttime[_wat])=58 then _akttime := leftstr(_akttime,_wat-1);

      Datumpanel.Caption := _aktdate;
      IdoPanel.Caption := _akttime;
    end;

end;











procedure TForm1.KOCKAPANELMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  pnevedit.text := '';
  DatumPanel.Caption := '';
  IdoPanel.Caption := '';
end;

end.
