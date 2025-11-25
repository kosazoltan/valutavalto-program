unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,  Printers, Buttons, IBDatabase, DB, strutils,
  IBCustomDataSet, IBQuery;

type
  TIRODAARFOLYAMOK = class(TForm)
    E1: TPanel;
    E2: TPanel;
    E4: TPanel;
    E5: TPanel;
    E6: TPanel;
    E7: TPanel;
    E8: TPanel;
    E9: TPanel;
    E10: TPanel;
    E12: TPanel;
    E11: TPanel;
    E13: TPanel;
    E14: TPanel;
    E15: TPanel;
    E16: TPanel;
    E18: TPanel;
    E17: TPanel;
    E19: TPanel;
    E20: TPanel;
    E3: TPanel;
    D1: TPanel;
    D2: TPanel;
    UV1: TPanel;
    UV2: TPanel;
    US1: TPanel;
    V1: TPanel;
    V2: TPanel;
    S1: TPanel;
    BS15: TPanel;
    S18: TPanel;
    BV20: TPanel;
    V19: TPanel;
    BV18: TPanel;
    BS19: TPanel;
    BS14: TPanel;
    BV2: TPanel;
    BS10: TPanel;
    UV19: TPanel;
    BS16: TPanel;
    US18: TPanel;
    BV19: TPanel;
    BS12: TPanel;
    BV1: TPanel;
    V20: TPanel;
    S19: TPanel;
    V18: TPanel;
    UV20: TPanel;
    BS11: TPanel;
    BS8: TPanel;
    US2: TPanel;
    BS17: TPanel;
    BS1: TPanel;
    Panel67: TPanel;
    UV18: TPanel;
    BS13: TPanel;
    S2: TPanel;
    D18: TPanel;
    D20: TPanel;
    BS5: TPanel;
    BS20: TPanel;
    BS18: TPanel;
    BS3: TPanel;
    Panel77: TPanel;
    US19: TPanel;
    S20: TPanel;
    BS6: TPanel;
    BS7: TPanel;
    BS2: TPanel;
    BS9: TPanel;
    US20: TPanel;
    D19: TPanel;
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
    BS4: TPanel;
    Panel102: TPanel;
    Panel103: TPanel;
    Panel104: TPanel;
    BV14: TPanel;
    V15: TPanel;
    BV15: TPanel;
    S15: TPanel;
    US15: TPanel;
    UV16: TPanel;
    D15: TPanel;
    V14: TPanel;
    BV16: TPanel;
    BV17: TPanel;
    V16: TPanel;
    D14: TPanel;
    UV15: TPanel;
    V17: TPanel;
    S16: TPanel;
    US16: TPanel;
    US17: TPanel;
    UV17: TPanel;
    D16: TPanel;
    S17: TPanel;
    D17: TPanel;
    S11: TPanel;
    UV11: TPanel;
    BV12: TPanel;
    S12: TPanel;
    V11: TPanel;
    V12: TPanel;
    D11: TPanel;
    US13: TPanel;
    BV13: TPanel;
    US12: TPanel;
    S13: TPanel;
    UV13: TPanel;
    V13: TPanel;
    D12: TPanel;
    UV12: TPanel;
    UV14: TPanel;
    US14: TPanel;
    S14: TPanel;
    D13: TPanel;
    D6: TPanel;
    US8: TPanel;
    D5: TPanel;
    US7: TPanel;
    S8: TPanel;
    UV9: TPanel;
    V8: TPanel;
    US10: TPanel;
    V10: TPanel;
    S10: TPanel;
    BV9: TPanel;
    V9: TPanel;
    D7: TPanel;
    D9: TPanel;
    US11: TPanel;
    US9: TPanel;
    UV8: TPanel;
    D10: TPanel;
    BV8: TPanel;
    UV7: TPanel;
    UV10: TPanel;
    BV10: TPanel;
    D8: TPanel;
    BV11: TPanel;
    BV7: TPanel;
    S9: TPanel;
    D3: TPanel;
    D4: TPanel;
    V3: TPanel;
    S3: TPanel;
    V5: TPanel;
    UV5: TPanel;
    V7: TPanel;
    S7: TPanel;
    US6: TPanel;
    V6: TPanel;
    S6: TPanel;
    V4: TPanel;
    UV3: TPanel;
    BV6: TPanel;
    UV6: TPanel;
    US3: TPanel;
    S4: TPanel;
    US5: TPanel;
    S5: TPanel;
    UV4: TPanel;
    US4: TPanel;
    BV3: TPanel;
    BV5: TPanel;
    BV4: TPanel;
    INDITOTIMER: TTimer;
    IRODAVALASZTOPANEL: TPanel;
    Label12: TLabel;
    MASIRODAGOMB: TBitBtn;
    KILEPOGOMB: TBitBtn;
    NYOMTATOGOMB: TBitBtn;
    PENZTARSZAMPANEL: TPanel;
    PrintDialog1: TPrintDialog;
    K1PANEL: TPanel;
    K2PANEL: TPanel;
    K3PANEL: TPanel;
    K4PANEL: TPanel;
    K5PANEL: TPanel;
    Panel21: TPanel;
    Shape3: TShape;
    Shape4: TShape;
    Shape5: TShape;
    Shape6: TShape;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label10: TLabel;
    Shape7: TShape;
    Label1: TLabel;
    Shape8: TShape;
    Shape9: TShape;
    Shape10: TShape;
    Shape11: TShape;
    Shape12: TShape;
    Shape13: TShape;
    Shape14: TShape;
    Label2: TLabel;
    Shape15: TShape;
    Shape16: TShape;
    Label3: TLabel;
    Label11: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    E21: TPanel;
    D21: TPanel;
    V21: TPanel;
    S21: TPanel;
    UV21: TPanel;
    US21: TPanel;
    BV21: TPanel;
    BS21: TPanel;
    Panel8: TPanel;
    E22: TPanel;
    D22: TPanel;
    V22: TPanel;
    S22: TPanel;
    UV22: TPanel;
    US22: TPanel;
    BV22: TPanel;
    BS22: TPanel;
    Panel9: TPanel;
    E23: TPanel;
    D23: TPanel;
    V23: TPanel;
    S23: TPanel;
    UV23: TPanel;
    BS23: TPanel;
    Panel6: TPanel;
    US23: TPanel;
    BV23: TPanel;
    E24: TPanel;
    D24: TPanel;
    V24: TPanel;
    S24: TPanel;
    UV24: TPanel;
    US24: TPanel;
    BV24: TPanel;
    BS24: TPanel;
    Panel11: TPanel;
    E25: TPanel;
    E26: TPanel;
    E27: TPanel;
    Panel1: TPanel;
    Panel2: TPanel;
    BS25: TPanel;
    Panel4: TPanel;
    BS27: TPanel;
    BS26: TPanel;
    US27: TPanel;
    BV26: TPanel;
    BV27: TPanel;
    BV25: TPanel;
    US26: TPanel;
    UV27: TPanel;
    S27: TPanel;
    US25: TPanel;
    UV26: TPanel;
    UV25: TPanel;
    S25: TPanel;
    S26: TPanel;
    V27: TPanel;
    V26: TPanel;
    V25: TPanel;
    D27: TPanel;
    D26: TPanel;
    D25: TPanel;
    Panel30: TPanel;
    SERVERQUERY: TIBQuery;
    SERVERDBASE: TIBDatabase;
    SERVERTRANZ: TIBTransaction;
    Panel3: TPanel;
    PT1: TPanel;
    PT4: TPanel;
    PT6: TPanel;
    PT3: TPanel;
    PT2: TPanel;
    PT9: TPanel;
    PT7: TPanel;
    PT8: TPanel;
    PT12: TPanel;
    PT10: TPanel;
    PT11: TPanel;
    PT15: TPanel;
    PT13: TPanel;
    PT14: TPanel;
    PT18: TPanel;
    PT16: TPanel;
    PT17: TPanel;
    PT23: TPanel;
    PT19: TPanel;
    PT20: TPanel;
    PT21: TPanel;
    PT22: TPanel;
    PT5: TPanel;
    PT24: TPanel;
    BitBtn1: TBitBtn;
    ETQUERY: TIBQuery;
    ETDBASE: TIBDatabase;
    ETTRANZ: TIBTransaction;
    Shape1: TShape;

    procedure FormActivate(Sender: TObject);
    procedure INDITOTIMERTimer(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure EgyirodatValaszt;
//    function GetCrdatNev: string;
    procedure EgyarfolyamlapDisplay(_irnum: integer);
    function dnemDekoder(_dns: string): string;
    function Intdekodol(_bs: integer): real;
    procedure MASIRODAGOMBClick(Sender: TObject);
    procedure NYOMTATOGOMBClick(Sender: TObject);
    procedure TombBetoltes;
    procedure GetPenztarszamok;
    procedure GetAlapadatok;

    procedure PT1Click(Sender: TObject);
    procedure PT1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Shape1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  IRODAARFOLYAMOK: TIRODAARFOLYAMOK;
  _uvetarf,_ueladarf,_bvetarf,_beladarf: array[1..27] of real;
  _ye,_yd,_yv,_ys,_yuv,_yus,_ybv,_ybs: array[1..27] of TPanel;
  _aktPanel,_mPanel: Tpanel;
  _aktlista: TListbox;
  _peldany,_sajcsoport,_kezdet,_code: integer;
  _aktypath: string;
  _bytetomb: array[1..4096] of byte;
  _ptnev : array[1..25] of string;
  _ptnum : array[1..25] of byte;

  _pt: array[1..24] of TPanel;

  _sdnem:array[1..27] of string = ('EUR','USD','GBP','CHF','AUD','CAD','DKK',
           'JPY','NOK','SEK','CZK','HRK','PLN','RON','RSD','BGN','ILS','UAH',
           'RUB','EUA','TRY','CNY','BAM','THB','BRL','MXN','NZD');

  _ertektar,_uzlet,_ptdarab,_kertPtnum,_lastTag: byte;
  _top,_left,_width,_height,_cc: word;
  _aktdnem,_serverPath,_pcs,_kesznev,_aktnev,_kertptnev: string;
  _sorveg: string = chr(13)+chr(10);

  _host: string;

  _elszamarf,_vetarf,_eladarf: array[1..27] of real;

function irodaarfolyamrutin: integer; stdcall;

implementation
{$R *.dfm}

function irodaarfolyamrutin: integer; stdcall;
begin
  irodaarfolyamok := TIrodaarfolyamok.Create(Nil);

  result := irodaarfolyamok.showmodal;
  irodaarfolyamok.Free;
end;



// =============================================================================
           procedure TIRODAARFOLYAMOK.FormActivate(Sender: TObject);
// =============================================================================

var i: integer;


begin
  _height := Screen.Monitors[0].height;
  _width  := Screen.Monitors[0].Width;

  _top := round((_height-768)/2);
  _left := round((_width-1024)/2);

  Top    := _TOP;
  Left   := _LEFT;
  Height := 768;
  Width  := 1024;

  TombBetoltes;
  _lastTag:= 0;

  for i := 1 to 27 do
    begin
      _aktpanel := _ye[i];
      _aktpanel.caption := '';
      _aktpanel := _yd[i];
      _aktpanel.caption := '';
      _aktpanel := _yv[i];
      _aktpanel.caption := '';
      _aktpanel := _ys[i];
      _aktpanel.caption := '';
      _aktpanel := _yuv[i];
      _aktpanel.caption := '';
      _aktpanel := _yus[i];
      _aktpanel.caption := '';
      _aktpanel := _ybv[i];
      _aktpanel.caption := '';
      _aktpanel := _ybs[i];
      _aktpanel.caption := '';
    end;

 GetAlapAdatok;
 GetPenztarszamok;

// IrodaszamShape.Visible := False;
// IrodaszamPanel.Visible := False;

 InditoTimer.Enabled    := True;
end;


//  Printer.Orientation := poLandscape;
//  Print;
//  end;


// =============================================================================
          procedure TIRODAARFOLYAMOK.INDITOTIMERTimer(Sender: TObject);
// =============================================================================


begin
  InditoTimer.Enabled := False;

  _aktypath := 'c:\ertektar\arfolyam\arfolyam.dat';  // GetCrdatNev;
  if _aktyPath='' then exit;

   with IrodaValasztoPanel do
    begin
      Top := 10;
      Left := 24;
      visible := True;
      BringtoFront;
    end;
  EgyirodatValaszt;
end;

// =============================================================================
          procedure TIRODAARFOLYAMOK.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
                 procedure TirodaArfolyamok.EgyirodatValaszt;
// =============================================================================

begin
  with IrodaValasztoPanel do
    begin
      Top := 10;
      Left := 24;
      Visible := true;
      Repaint;
    end;
end;

// =============================================================================
      procedure TIrodaarfolyamok.EgyarfolyamlapDisplay(_irnum: integer);
// =============================================================================


var _arfolvas: file of byte;
    i: integer;

    _k1,_k2,_k3,_sk1,_sk2,_sk3,_sk4,_sk5: real;
begin
  Assignfile(_arfolvas,_aktyPath);
  Reset(_arfOlvas);
  Blockread(_arfolvas,_bytetomb,1);
  Blockread(_arfolvas,_bytetomb,200);

   _sajcsoport := _bytetomb[_irnum];

   if (_sajcsoport<1) or (_sajcsoport>54) then
     begin
       CloseFile(_arfolvas);
       ShowMessage('HIBÁS PÉNZTÁRSZÁM !');
       Exit;
     end;

   _kezdet := 201+trunc((_sajcsoport-1)*1221);
   reset(_arfolvas);
   seek(_arfolvas,_kezdet);

   for i := 1 to 27 do
     begin
       Blockread(_arfolvas,_bytetomb,45);
       _aktdnem      := _sdnem[i];
       _elszamarf[i] := intdekodol(1);
       _vetarf[i]    := intdekodol(6);
       _eladarf[i]   := intdekodol(11);
       _uvetarf[i]   := intdekodol(16);
       _ueladarf[i]  := intdekodol(21);
       _bvetarf[i]   := intdekodol(26);
       _beladarf[i]  := intdekodol(31);
     end;

   // ------------------- A LIMITÉRTÉKEK BEOLVASÁSA ----------------------------

   Blockread(_arfolvas,_bytetomb,6);
   closeFile(_arfolvas);

   // --------------------------------------------------------------------------

   _k1 := _bytetomb[1] + (256*_bytetomb[2]);
   _k2 := _bytetomb[3] + (256*_bytetomb[4]);
   _k3 := _bytetomb[5] + (256*_bytetomb[6]);

   _sk1 := 1+(1000*_k1);
   _sk2 := (1000*_k2);

   _sk3 := 1+(1000*_k2);
   _sk4 := (1000*_k3);

   _sk5 := 1+(1000*_k3);

   k1Panel.Caption := Formatfloat('### ### ###',_sk1) + ' -';
   k2Panel.Caption := Formatfloat('### ### ###',_sk2);
   k3Panel.Caption := Formatfloat('### ### ###',_sk3) + ' -';
   k4Panel.Caption := Formatfloat('### ### ###',_sk4);
   k5Panel.Caption := Formatfloat('### ### ###',_sk5) + ' -';

   // -------------------------------------------------------

   for i := 1 to 27 DO
     begin
       _ye[i].Caption := formatfloat('### ###.##',_elszamarf[i]);
       _yd[i].caption := _sdnem[i];
       _yv[i].Caption := formatfloat('### ###.##',_vetarf[i]);
       _ys[i].caption := formatfloat('### ###.##',_eladarf[i]);
       _yuv[i].caption := formatfloat('### ###.##',_uvetarf[i]);
       _yus[i].caption := formatfloat('### ###.##',_ueladarf[i]);
       _ybv[i].caption := formatfloat('### ###.##',_bvetarf[i]);
       _ybs[i].caption := formatfloat('### ###.##',_beladarf[i]);
     end;
 //  PenztarSzamPanel.Caption := inttostr(_irnum)+'. SZÁMU PÉNZTÁR';
   IrodaValasztoPanel.visible := False;
end;

// =============================================================================
        function TIrodaarfolyamok.dnemDekoder(_dns: string): string;
// =============================================================================


var _b1,_b2,_r1,_r2,_r3: byte;

begin
  _b1 := ord(_dns[1]);
  _b2 := ord(_dns[2]);
  _r1 := trunc(_b1/4);
  _r2 := trunc(_b1*64);
  _r2 := trunc(_r2/8)+trunc(_b2/32);
  _r3 := trunc(_b2*8);
  _r3 := trunc(_r3/8);
  result := chr(_r1+64)+chr(_r2+64)+chr(_r3+64);
end;

// =============================================================================
          function TIrodaarfolyamok.Intdekodol(_bs: integer): real;
// =============================================================================


var _b1,_b2,_b3,_b4,_b5: byte;
    _egesz: integer;
    _real: real;
begin

   _b1 := _bytetomb[_bs];
   _b2 := _bytetomb[_bs+1];
   _b3 := _bytetomb[_bs+2];
   _b4 := _bytetomb[_bs+3];
   _b5 := _bytetomb[_bs+4];

   _real := _b5*65536*65536;
   _real := _real + (_b4*65536*256);
   _real := _real + (65536*_b3);
   _real := _real + (256*_b2);
   _egesz := trunc(_real + _b1);
   if _aktdnem= 'JPY' then _real := _egesz/1000
   else _real := _egesz/100;

   result := _real;


end;

// =============================================================================
        procedure TIRODAARFOLYAMOK.MASIRODAGOMBClick(Sender: TObject);
// =============================================================================

begin
  EgyIrodatValaszt;
end;

// =============================================================================
        procedure TIRODAARFOLYAMOK.NYOMTATOGOMBClick(Sender: TObject);
// =============================================================================

begin
  if Printdialog1.Execute then
    begin
      Printer.Orientation := poLandscape;
      IrodaArfolyamok.Color := clWhite;
      Print;
      IrodaArfolyamok.Color := clSilver;
    end;
end;


{
// =============================================================================
                function TIrodaArfolyamok.GetCrdatNev: string;
// =============================================================================

var _srec: Tsearchrec;
    _minta,_arfdir: string;

begin
  _arfdir := 'c:\ertektar\arfolyam';
  result := '';
  _minta := _arfdir + '\NR*.dat';
  if FindFirst(_minta, faAnyFile, _srec) = 0 then result := _arfdir+'\'+_srec.Name;
  FindClose(_srec);
end;
}



procedure TirodaArfolyamok.GetPenztarszamok;

begin
  _serverpath := _host + ':C:\receptor\database\receptor.fdb';
  ServerDbase.close;
  ServerDbase.DatabaseName := _serverPath;
  Serverdbase.Connected := true;

  _pcs := 'SELECT * FROM IRODAK WHERE (CLOSED<>'+chr(39)+'X'+chr(39)+') ';
  _pcs := _pcs + 'AND (ERTEKTAR=' + inttostr(_ertektar)+ ')' + _sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';
  with ServerQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
    end;

  _cc:= 0;
  while not ServerQuery.Eof do
    begin
      _uzlet := ServerQuery.fieldByNAme('UZLET').asInteger;
      _kesznev := Trim(ServerQuery.FieldByNAme('KESZLETNEV').AsString);
      inc(_cc);
      _ptnum[_cc] := _uzlet;
      _ptnev[_cc] := _kesznev;
      Serverquery.Next;
    end;
  ServerQuery.close;
  ServerDbase.close;
  _Ptdarab := _cc;

  _cc := 1;
  while _cc<=_ptdarab do
    begin
      _aktnev := _ptnev[_cc];
      _aktPanel := _pt[_cc];
      _aktPanel.caption := _aktnev;
      _aktPanel.repaint;
      inc(_cc);
    end;
end;

//==============================================================================
                    procedure TIrodaArfolyamok.TombBetoltes;
// =============================================================================

begin
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
  _ye[21] := E21;
  _ye[22] := E22;
  _ye[23] := E23;
  _ye[24] := E24;
  _ye[25] := E25;
  _ye[26] := E26;
  _ye[27] := E27;

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
  _yD[21] := D21;
  _yD[22] := D22;
  _yD[23] := D23;
  _yD[24] := D24;
  _yD[25] := D25;
  _yD[26] := D26;
  _yD[27] := D27;

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
  _yV[21] := V21;
  _yV[22] := V22;
  _yV[23] := V23;
  _yV[24] := V24;
  _yV[25] := V25;
  _yV[26] := V26;
  _yV[27] := V27;


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
  _yS[21] := S21;
  _yS[22] := S22;
  _yS[23] := S23;
  _yS[24] := S24;
  _yS[25] := S25;
  _yS[26] := S26;
  _yS[27] := S27;

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
  _yUV[21] := UV21;
  _yUV[22] := UV22;
  _yUV[23] := UV23;
  _yUV[24] := UV24;
  _yUV[25] := UV25;
  _yUV[26] := UV26;
  _yUV[27] := UV27;


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
  _yUS[21] := US21;
  _yUS[22] := US22;
  _yUS[23] := US23;
  _yUS[24] := US24;
  _yUS[25] := US25;
  _yUS[26] := US26;
  _yUS[27] := US27;

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
  _yBV[21] := BV21;
  _yBV[22] := BV22;
  _yBV[23] := BV23;
  _yBV[24] := BV24;
  _yBV[25] := BV25;
  _yBV[26] := BV26;
  _yBV[27] := BV27;

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
  _yBS[21] := BS21;
  _yBS[22] := BS22;
  _yBS[23] := BS23;
  _yBS[24] := BS24;
  _yBS[25] := BS25;
  _yBS[26] := BS26;
  _yBS[27] := BS27;

  _pt[1] := PT1;
  _pt[2] := PT2;
  _pt[3] := PT3;
  _pt[4] := PT4;
  _pt[5] := PT5;
  _pt[6] := PT6;
  _pt[7] := PT7;
  _pt[8] := PT8;
  _pt[9] := PT9;
  _pt[10]:= PT10;
  _pt[11]:= PT11;
  _pt[12]:= PT12;
  _pt[13]:= PT13;
  _pt[14]:= PT14;
  _pt[15]:= PT15;
  _pt[16]:= PT16;
  _pt[17]:= PT17;
  _pt[18]:= PT18;
  _pt[19]:= PT19;
  _pt[20]:= PT20;
  _pt[21]:= PT21;
  _pt[22]:= PT22;
  _pt[23]:= PT23;
  _pt[24]:= PT24;

end;

procedure TIRODAARFOLYAMOK.PT1Click(Sender: TObject);

var _panelnev,_ptnums: string;
    _w,_ptss,_h: byte;

begin
  _PanelNEV := TPanel(sender).name;
  _w := length(_panelnev);
  _h := 2;
  if _w=3 then _h := 1;
  _ptnums := midstr(_panelnev,3,_h);
  val(_ptnums,_ptss,_code);

  if _ptss>_ptdarab then exit;

  _kertPtnum := _ptnum[_ptss];
  _kertptnev := _ptnev[_ptss];

  PenztarszamPanel.Caption := inttostr(_kertptnum)+' - '+_kertptnev;
  PenztarszamPanel.repaint;

  EgyarfolyamLapDisplay(_kertptnum);

end;

procedure TIrodaArfolyamok.GetAlapAdatok;

var _pks: string;

begin
  etdbase.connected := true;
  with etquery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _host := trim(FieldByNAme('HOST').asstring);
      Close;
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _pks := trim(FieldByNAme('PENZTARKOD').AsString);
      Close;
    end;
  etdbase.close;

  val(_pks,_ertektar,_code);    


end;
procedure TIRODAARFOLYAMOK.PT1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);

var _tag,i: byte;


begin
  _tag := TPanel(sender).Tag;
  if _tag=_lastTag then exit;
  if _tag>_ptdarab then exit;

  _lastTag := _tag;
  _aktpanel := _pt[_tag];

  for i := 1 to 24 do
    begin
      _mPanel := _pt[i];
      _mPanel.color := clBtnFace;
    end;
  _aktpanel.Color := $D0FFFF;
end;


procedure TIRODAARFOLYAMOK.Shape1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);

var i: byte;  

begin
  if _lasttag=0 then exit;
  _lasttag := 0;
  for i := 1 to 24 do
    begin
      _aktPanel := _pt[i];
      _aktPanel.Color := clBtnFace;
    end;
end;

end.
