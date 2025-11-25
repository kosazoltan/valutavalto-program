unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, DB, DBTables, StrUtils, DateUtils, Buttons,
  IBDatabase, IBCustomDataSet, IBTable;

type
  TGETDATADISP = class(TForm)
    GETPANEL: TPanel;
    KILEPOGOMB: TButton;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    Panel10: TPanel;
    Panel11: TPanel;
    Panel12: TPanel;
    Panel13: TPanel;
    Panel14: TPanel;
    Panel15: TPanel;
    Panel16: TPanel;
    Panel17: TPanel;
    Panel18: TPanel;
    Panel19: TPanel;
    Panel20: TPanel;
    Panel21: TPanel;
    Panel22: TPanel;
    Panel23: TPanel;
    Panel24: TPanel;
    Panel25: TPanel;
    Panel26: TPanel;
    Panel27: TPanel;
    Panel28: TPanel;
    Panel29: TPanel;
    Panel30: TPanel;
    Panel31: TPanel;
    Panel32: TPanel;
    Panel33: TPanel;
    Panel34: TPanel;
    Panel35: TPanel;
    Panel36: TPanel;
    Panel37: TPanel;
    Panel38: TPanel;
    Panel39: TPanel;
    Panel40: TPanel;
    Panel41: TPanel;
    Panel42: TPanel;
    Panel43: TPanel;
    Panel44: TPanel;
    Panel45: TPanel;
    Panel46: TPanel;
    Panel47: TPanel;
    Panel48: TPanel;
    Panel49: TPanel;
    Panel50: TPanel;
    Panel51: TPanel;
    Panel52: TPanel;
    Panel53: TPanel;
    Panel54: TPanel;
    Panel55: TPanel;
    Panel56: TPanel;
    Panel57: TPanel;
    Panel58: TPanel;
    Panel59: TPanel;
    Panel60: TPanel;
    panel61: tpanel;
    Panel62: TPanel;
    Panel63: TPanel;
    Panel64: TPanel;
    Panel65: TPanel;
    Panel66: TPanel;
    Panel67: TPanel;
    Panel68: TPanel;
    Panel69: TPanel;
    Panel70: TPanel;
    Panel71: TPanel;
    Panel72: TPanel;
    Panel73: TPanel;
    Panel74: TPanel;
    Panel75: TPanel;
    Panel76: TPanel;
    Panel77: TPanel;
    Panel78: TPanel;
    Panel79: TPanel;
    Panel80: TPanel;
    panel81: tpanel;
    Panel82: TPanel;
    Panel83: TPanel;
    Panel84: TPanel;
    Panel85: TPanel;
    Panel86: TPanel;
    Panel87: TPanel;
    Panel88: TPanel;
    Panel89: TPanel;
    Panel90: TPanel;
    Panel91: TPanel;
    Panel92: TPanel;
    Panel93: TPanel;
    Panel94: TPanel;
    Panel95: TPanel;
    Panel96: TPanel;
    Panel97: TPanel;
    Panel98: TPanel;
    Panel99: TPanel;
    Panel100: TPanel;
    Panel101: TPanel;
    Panel102: TPanel;
    Panel103: TPanel;
    Panel104: TPanel;
    Panel105: TPanel;
    Panel106: TPanel;
    Panel107: TPanel;
    Panel108: TPanel;
    Panel109: TPanel;
    Panel110: TPanel;
    Panel111: TPanel;
    Panel112: TPanel;
    Panel113: TPanel;
    Panel114: TPanel;
    Panel115: TPanel;
    Panel116: TPanel;
    Panel117: TPanel;
    Panel118: TPanel;
    Panel119: TPanel;
    Panel120: TPanel;
    Panel121: TPanel;
    Panel122: TPanel;
    Panel123: TPanel;
    Panel124: TPanel;
    Panel125: TPanel;
    Panel126: TPanel;
    Panel127: TPanel;
    Panel128: TPanel;
    Panel129: TPanel;
    Panel130: TPanel;
    Panel131: TPanel;
    Panel132: TPanel;
    Panel133: TPanel;
    Panel134: TPanel;
    Panel135: TPanel;
    Panel136: TPanel;
    Panel137: TPanel;
    Panel138: TPanel;
    Panel139: TPanel;
    Panel140: TPanel;
    Panel141: TPanel;
    Panel142: TPanel;
    Panel143: TPanel;
    Panel144: TPanel;
    Panel145: TPanel;
    Panel146: TPanel;
    Panel147: TPanel;
    Panel148: TPanel;
    Panel149: TPanel;
    Panel150: TPanel;

    STATUSSZO: TLabel;
    EVKOMBO: TComboBox;
    HONAPKOMBO: TComboBox;
    NAPKOMBO: TComboBox;
    NAPNEVEDIT: TEdit;
    IRODANEV: TPanel;
    ERTEKTARNEV: TPanel;
    STATUS: TPanel;
    BitBtn1: TBitBtn;
    DAYBOOKTABLA: TIBTable;
    DAYBOOKDBASE: TIBDatabase;
    DAYBOOKTRANZ: TIBTransaction;
    Shape1: TShape;
    Shape2: TShape;
    Panel151: TPanel;
    p151: TPanel;
    P162: TPanel;
    P161: TPanel;
    P178: TPanel;
    P163: TPanel;
    P164: TPanel;
    P172: TPanel;
    P173: TPanel;
    P177: TPanel;
    P176: TPanel;
    P165: TPanel;
    P175: TPanel;
    P174: TPanel;
    P179: TPanel;
    P171: TPanel;
    P170: TPanel;
    P169: TPanel;
    P158: TPanel;
    P157: TPanel;
    P160: TPanel;
    P154: TPanel;
    P159: TPanel;
    P168: TPanel;
    P180: TPanel;
    P167: TPanel;
    P166: TPanel;
    P156: TPanel;
    P155: TPanel;
    P153: TPanel;
    P152: TPanel;
    Panel182: TPanel;

    procedure FormActivate(Sender: TObject);
    procedure Kijelzes(_pc:integer);
    procedure TablaSzinezo;
    function SetStatus(_as: string): integer;

    procedure EVKOMBOChange(Sender: TObject);
    procedure Panel1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Panel1Click(Sender: TObject);
    procedure KMG1Enter(Sender: TObject);
    procedure KMG1Exit(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BetutBeir(_ksors: integer; _betu: string; _Nmezo: string);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GETDATADISP: TGETDATADISP;
  _pKocka,_aktKockaSorszam : integer;
  _kocka: array[1..180] of TPanel;
 
  _aktDstring : string;
  _elso: boolean;
  _pnev,_ernev: string;
  _aktKocka: TPanel;
  _fcol : TColor;
  _aktcolor,_aktbcColor: TColor;
  _lenstatus: integer;

implementation

uses Unit1, Unit8, Unit13;

{$R *.dfm}




procedure TGETDATADISP.FormActivate(Sender: TObject);

var i: integer;
   
begin
  Top := _top+120;
  Left := _left+140;
  width := 750;
  Height := 650;


  _kocka[1] := Panel1;
  _kocka[2] := Panel2;
  _kocka[3] := Panel3;
  _kocka[4] := Panel4;
  _kocka[5] := Panel5;
  _kocka[6] := Panel6;
  _kocka[7] := Panel7;
  _kocka[8] := Panel8;
  _kocka[9] := Panel9;
  _kocka[10] := Panel10;
  _kocka[11] := Panel11;
  _kocka[12] := Panel12;
  _kocka[13] := Panel13;
  _kocka[14] := Panel14;
  _kocka[15] := Panel15;
  _kocka[16] := Panel16;
  _kocka[17] := Panel17;
  _kocka[18] := Panel18;
  _kocka[19] := Panel19;
  _kocka[20] := Panel20;
  _kocka[21] := Panel21;
  _kocka[22] := Panel22;
  _kocka[23] := Panel23;
  _kocka[24] := Panel24;
  _kocka[25] := Panel25;
  _kocka[26] := Panel26;
  _kocka[27] := Panel27;
  _kocka[28] := Panel28;
  _kocka[29] := Panel29;
  _kocka[30] := Panel30;
  _kocka[31] := Panel31;
  _kocka[32] := Panel32;
  _kocka[33] := Panel33;
  _kocka[34] := Panel34;
  _kocka[35] := Panel35;
  _kocka[36] := Panel36;
  _kocka[37] := Panel37;
  _kocka[38] := Panel38;
  _kocka[39] := Panel39;
  _kocka[40] := Panel40;
  _kocka[41] := Panel41;
  _kocka[42] := Panel42;
  _kocka[43] := Panel43;
  _kocka[44] := Panel44;
  _kocka[45] := Panel45;
  _kocka[46] := Panel46;
  _kocka[47] := Panel47;
  _kocka[48] := Panel48;
  _kocka[49] := Panel49;
  _kocka[50] := Panel50;
  _kocka[51] := Panel51;
  _kocka[52] := Panel52;
  _kocka[53] := Panel53;
  _kocka[54] := Panel54;
  _kocka[55] := Panel55;
  _kocka[56] := Panel56;
  _kocka[57] := Panel57;
  _kocka[58] := Panel58;
  _kocka[59] := Panel59;
  _kocka[60] := Panel60;
  _kocka[61] := Panel61;
  _kocka[62] := Panel62;
  _kocka[63] := Panel63;
  _kocka[64] := Panel64;
  _kocka[65] := Panel65;
  _kocka[66] := Panel66;
  _kocka[67] := Panel67;
  _kocka[68] := Panel68;
  _kocka[69] := Panel69;
  _kocka[70] := Panel70;
  _kocka[71] := Panel71;
  _kocka[72] := Panel72;
  _kocka[73] := Panel73;
  _kocka[74] := Panel74;
  _kocka[75] := Panel75;
  _kocka[76] := Panel76;
  _kocka[77] := Panel77;
  _kocka[78] := Panel78;
  _kocka[79] := Panel79;
  _kocka[80] := Panel80;
  _kocka[81] := Panel81;
  _kocka[82] := Panel82;
  _kocka[83] := Panel83;
  _kocka[84] := Panel84;
  _kocka[85] := Panel85;
  _kocka[86] := Panel86;
  _kocka[87] := Panel87;
  _kocka[88] := Panel88;
  _kocka[89] := Panel89;
  _kocka[90] := Panel90;
  _kocka[91] := Panel91;
  _kocka[92] := Panel92;
  _kocka[93] := Panel93;
  _kocka[94] := Panel94;
  _kocka[95] := Panel95;
  _kocka[96] := Panel96;
  _kocka[97] := Panel97;
  _kocka[98] := Panel98;
  _kocka[99] := Panel99;
  _kocka[100] := Panel100;
  _kocka[101] := Panel101;
  _kocka[102] := Panel102;
  _kocka[103] := Panel103;
  _kocka[104] := Panel104;
  _kocka[105] := Panel105;
  _kocka[106] := Panel106;
  _kocka[107] := Panel107;
  _kocka[108] := Panel108;
  _kocka[109] := Panel109;
  _kocka[110] := Panel110;
  _kocka[111] := Panel111;
  _kocka[112] := Panel112;
  _kocka[113] := Panel113;
  _kocka[114] := Panel114;
  _kocka[115] := Panel115;
  _kocka[116] := Panel116;
  _kocka[117] := Panel117;
  _kocka[118] := Panel118;
  _kocka[119] := Panel119;
  _kocka[120] := Panel120;
  _kocka[121] := Panel121;
  _kocka[122] := Panel122;
  _kocka[123] := Panel123;
  _kocka[124] := Panel124;
  _kocka[125] := Panel125;
  _kocka[126] := Panel126;
  _kocka[127] := Panel127;
  _kocka[128] := Panel128;
  _kocka[129] := Panel129;
  _kocka[130] := Panel130;
  _kocka[131] := Panel131;
  _kocka[132] := Panel132;
  _kocka[133] := Panel133;
  _kocka[134] := Panel134;
  _kocka[135] := Panel135;
  _kocka[136] := Panel136;
  _kocka[137] := Panel137;
  _kocka[138] := Panel138;
  _kocka[139] := Panel139;
  _kocka[140] := Panel140;
  _kocka[141] := Panel141;
  _kocka[142] := Panel142;
  _kocka[143] := Panel143;
  _kocka[144] := Panel144;
  _kocka[145] := Panel145;
  _kocka[146] := Panel146;
  _kocka[147] := Panel147;
  _kocka[148] := Panel148;
  _kocka[149] := Panel149;
  _kocka[150] := Panel150;

  _kocka[151] := P151;
  _kocka[152] := P152;
  _kocka[153] := P153;
  _kocka[154] := P154;
  _kocka[155] := P155;
  _kocka[156] := P156;
  _kocka[157] := P157;
  _kocka[158] := P158;
  _kocka[159] := P159;
  _kocka[160] := P160;
  _kocka[161] := P161;
  _kocka[162] := P162;
  _kocka[163] := P163;
  _kocka[164] := P164;
  _kocka[165] := P165;
  _kocka[166] := P166;
  _kocka[167] := P167;
  _kocka[168] := P168;
  _kocka[169] := P169;
  _kocka[170] := P170;
  _kocka[171] := P171;
  _kocka[172] := P172;
  _kocka[173] := P173;
  _kocka[174] := P174;
  _kocka[175] := P175;
  _kocka[176] := P176;
  _kocka[177] := P177;
  _kocka[178] := P178;
  _kocka[179] := P179;
  _kocka[180] := P180;

  _pKocka := 1;

  Evkombo.Clear;
  HonapKombo.Clear;
  Napkombo.Clear;

  _aktDatum  := yesterday;
  _aktdatums := leftstr(Form1.hdatetostr(_aktdatum),10);

  decodedate(_aktdatum,_aktev,_aktho,_aktnap);
  _houtnap := daysinamonth(_aktev,_aktho);
  for i := 0 to 4 do
      Evkombo.Items.Add(inttostr(_aktev-i));
  Evkombo.ItemIndex := 0;

  for i := 1 to 12 do Honapkombo.Items.Add(_honapnev[i]);
  HonapKombo.ItemIndex := _aktho-1;

  for i := 1 to _houtnap do NapKombo.Items.Add(inttostr(i));
  Napkombo.ItemIndex := _aktnap-1;
  _hetnap := Dayoftheweek(_aktdatum);
  Napnevedit.Text := _napnev[_hetnap];

  if not Form1.DayBookReader(_aktDatums) then
    begin
      Modalresult := 2;
      exit;
    end;

  TablaSzinezo;

  _pkocka    := 0;
  _utSorszam := 0;
  _elso      := True;
end;



// =====================================================
       procedure TGetDataDisp.Kijelzes(_pc:integer);
// =====================================================

var
    _exx: integer;
    _UZENET: string;

begin
   _aktPenztarnev := '';
   _aktkorzetnev  := '';
   _aktPenztar    := 0;

   _aktstatus := '';
   if Form1.Vanilyeniroda(_pc) then
     begin
       _aktpenztar    := _pc;
       _aktpenztarnev := _irodanev[_pc];
       _aktkorzet     := _korzet[_pc];

       _exx   := Form1.ertTarScan(_aktkorzet);

       _aktkorzetNev := _korzetNev[_exx];
       _aktstatus    := _nStatus[_pc];
     end;

  _lenstatus := length(trim(_aktstatus));
  if _lenstatus=0 then _aktstatus := '0';

  Irodanev.Caption    := _aktpenztarnev;         // kiirja az irodanevet
  Ertektarnev.Caption := _aktkorzetnev;     // kiirja az értéktárnevet
  _stip               := SetStatus(_aktStatus);
  _uzenet             := _statUzen[_sTip];

  Status.Caption      := _uzenet;
end;


// =============================================
        procedure TGetDataDisp.TablaSzinezo;
// =============================================

(*   A 180 kocka nstatus tömbje szerint színezi a kockákat

*)
var i:integer;
      _aktKocka : TPanel;

begin
  i := 1;
  while i<=180 do
    begin
      _aktkocka  := _kocka[i];
      _aktStatus := _nStatus[i];
      _lenstatus := length(trim(_aktstatus));

      if _lenstatus=0 then _aktstatus := '0';

      _stip := setstatus(_aktstatus);

      if _stip=4 then _aktkocka.Cursor := crHandPoint else _aktkocka.Cursor := crCross;

      _aktKocka.Color      := _kockaSzin[_stip];
      _aktkocka.Font.Color := _betuszin[_stip];
      inc(i);
    end;
end;


//==========================================================
     procedure TGETDATADISP.EVKOMBOChange(Sender: TObject);
// =========================================================

(* Ha a dátum-elemek közül bármelyik megváltozik -> idekerül a vezérlés *)

var
    _ujev,_ujho,_ujnap: word;
    i: integer;

begin

  _ujev   := _aktev-(evkombo.itemindex);   // a kombóban lévõ év
  _ujho   := (honapKombo.Itemindex)+1;     // a kombóban lévõ hónap
  _ujnap  := (napkombo.itemindex)+1;      // a kombóban lévõ nap
  _AKTNAP := _ujnap;

  _aktdatum  := encodedate(_ujev,_ujho,_ujnap);  // ez a dátum lett beállitva
  _aktdatums := leftstr(Form1.hdatetostr(_aktdatum),10);

  _houtnap   := daysinamonth(_ujev,_ujho);  // a megadott hónap utolsó napja

  Napkombo.Clear;                         // a napkombót át kell állitani, mert lehet
  for i := 1 to _houtnap do NapKombo.Items.Add(inttostr(i)); // hogy ebben a hónapban
  Napkombo.ItemIndex := _ujnap-1;          //  lehet 31-ike például

  _hetnap := Dayoftheweek(_aktdatum);       // A nap sorszáma a héten
  Napnevedit.Text := _napnev[_hetnap];     // Kiirjuk (pl. 'csütörtök'

  if Form1.DaybookReader(_aktdatums) then TablaSzinezo  // Uj dátum alapján beállitja a
  else ShowMessage('A MEGADOTT DÁTUMRA NINCSENEK ADATAIM !');

  ActiveControl := KilepoGomb;
end;

// ==============================================================================
    procedure TGETDATADISP.Panel1MouseMove(Sender: TObject; Shift: TShiftState;
                                                              X, Y: Integer);
// ==============================================================================

var _aktPanel,_utpanel: TPanel;
    _sorszam: integer;

begin
  _sorszam   := TPanel(sender).Tag;
  _aktPanel  := _kocka[_sorszam];
  _aktStatus := _nStatus[_sorszam];
  _lenstatus := length(trim(_aktstatus));

  if _lenstatus=0 then _aktstatus := '0';

  _stip := Setstatus(_aktstatus);
  _fcol := _kockaszin[_stip];

  Status.Color := _aktbcColor;
  Status.Font.Color := _aktcolor;

  if _sorszam=_utsorszam then exit;
  if _utsorszam>0 then
    begin
      _utpanel  := _kocka[_utsorszam];
      _utStatus := _nStatus[_utSorszam];

      _utpanel.height := 40;
      _utpanel.width  := 40;

      IF _utsorszam>90 then _utpanel.Font.Size :=12
      else _utpanel.Font.Size := 14;

      _utpanel.Font.Style := [];
    end;

  _stip := setstatus(_aktstatus);

  if _stip=0 then
   begin
     _utsorszam := 0;
     Status.Caption := 'Itt nincs iroda !';
     Irodanev.Caption := '';
     ErtekTarNev.Caption := '';
     exit;
   end;

  _utsorszam := _sorszam;
  _aktPanel.Height := 50;
  _aktPanel.Width := 50;
  _aktPanel.Font.Size := 14;
  _aktPanel.Font.Style := [fsBold];
 // _aktpanel.Font.Color := clWhite;
  _aktpanel.BringToFront;
  Kijelzes(_sorszam);
end;

procedure TGETDATADISP.Panel1Click(Sender: TObject);
var _ss,_potOke: integer;
    _napmezo: string;
begin
  _ss := TPanel(Sender).Tag;
  _aktpenztar := _ss;
  _napMezo := 'N'+inttostr(_aktnap);
  _aktstatus := _Nstatus[_ss];
  _lenstatus := length(trim(_aktstatus));
  if _lenStatus=0 then _aktstatus:='0';
  _stip := Setstatus(_aktstatus);

  if _stip=1 then
    begin
      _nstatus[_ss] := '';
      Betutbeir(_ss,'',_napmezo);
      Tablaszinezo;
      exit;
    end;

  if _stip<>3 then
    begin
      _potOke := KeziAdatPotlasForm.ShowModal;
      if _potOke=3 then
         begin
           _nStaTus[_ss] := 'X';
           BetutBeir(_ss,'X',_napmezo);
           Tablaszinezo;
           exit;
         end;
      if _potoke = 2 then exit;

      _Nstatus[_ss] := 'K';
      Betutbeir(_ss,'K',_napmezo);
      Form1.DayBookReader(_aktDatums);
      Tablaszinezo;

    end;
end;


procedure TGetDataDisp.BetutBeir(_ksors: integer; _betu: string; _Nmezo: string);

begin

  DayBookdbase.close;
  DayBookDbase.connected := true;
  if DayBooktranz.InTransaction then Form1.DAYBOOKTRANZ.commit;
  DAYBOOKTRANZ.StartTransaction;

  with DAYBOOKTABLA do
    begin
      TableName := _fbkFile;
      IndexFieldNames := 'PENZTAR';
      Open;
      Refresh;
      First;
      Locate('PENZTAR',_KSORS,[]);
      Edit;
      FieldByNAme(_nMezo).asstring := _betu;
      Post;
    end;
  DayBookTranz.commit;
  DAYBOOKTABLA.Close;
end;





procedure TGETDATADISP.KMG1Enter(Sender: TObject);
begin
   TBitbtn(Sender).Font.Style := [fsBold];
   TBitBtn(Sender).Font.Color := clBlue;
end;

procedure TGETDATADISP.KMG1Exit(Sender: TObject);
begin
   TBitBtn(sender).Font.Style := [];
   TBitbtn(Sender).Font.Color := clBlack;
end;
procedure TGETDATADISP.BitBtn1Click(Sender: TObject);
begin
 ModalResult := 1;
end;



function TGetDataDisp.SetStatus(_as: string): integer;
begin
  result      := 0;
  _aktColor   := clWhite;
  _aktbcColor := clBlack;

  if _as = 'B' then
    begin
      _aktcolor   := clTeal;
      _aktbccolor := clLime;
      result      := 3;
    end;

  if _as = 'K' then
    begin
      _aktColor   := clTeal;
      _aktBcColor := clYellow;
      result      := 2;
    end;

  if _as = 'X' then
    begin
      _aktCOlor   := clBlack;
      _aktBcColor := clGray;
      Result      := 1;
    end;

  if _as = 'E' then
    begin
      _aktColor   := clWhite;
      _aktbcColor := clBlack;
      result      := 0;
    end;


  if (_as = '0') then
    begin
      _aktcolor   := clWhite;
      _aktbcCOlor := clRed;
      Result      := 4;
    end;
end;

end.