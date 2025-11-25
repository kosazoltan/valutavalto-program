unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet,
  IBQuery, ExtCtrls, strutils, IBTable;

type
  Tarfolyamtablakijelzes = class(TForm)
    VISSZAGOMB: TBitBtn;
    Panel1: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    LIMPANEL1: TPanel;
    LIMPANEL2: TPanel;
    LIMPANEL3: TPanel;
    ARFOLYAMQUERY: TIBQuery;
    ARFOLYAMDBASE: TIBDatabase;
    ARFOLYAMTRANZ: TIBTransaction;
    TEMPQUERY: TIBQuery;
    TEMPDBASE: TIBDatabase;
    TEMPTRANZ: TIBTransaction;
    CUPPANEL: TPanel;
    OKEGOMB: TBitBtn;
    NYUJTO: TTimer;
    BitBtn2: TBitBtn;
    Panel9: TPanel;
    Panel10: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label6: TLabel;
    Label9: TLabel;
    Panel11: TPanel;
    Shape1: TShape;
    Label7: TLabel;
    DNEMPANEL: TPanel;
    UJARFPANEL: TPanel;
    CUPPANEL2: TPanel;
    Label10: TLabel;
    DNEM2PANEL: TPanel;
    Label11: TLabel;
    TOLARFPANEL: TPanel;
    IGARFPANEL: TPanel;
    Label12: TLabel;
    Label13: TLabel;
    UJARFEDIT: TEdit;
    SHKOKEGOMB: TBitBtn;
    SHKMEGSEMGOMB: TBitBtn;
    Shape2: TShape;
    NYUJTO2: TTimer;
    SHKFUGGONY: TPanel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    SP1: TPanel;
    SP2: TPanel;
    SP3: TPanel;
    SP4: TPanel;
    SP5: TPanel;
    SP6: TPanel;
    SP7: TPanel;
    SP8: TPanel;
    SP19: TPanel;
    SP20: TPanel;
    SP12: TPanel;
    SP11: TPanel;
    SP18: TPanel;
    SP14: TPanel;
    SP10: TPanel;
    SP13: TPanel;
    SP17: TPanel;
    SP16: TPanel;
    SP15: TPanel;
    SP9: TPanel;
    SP22: TPanel;
    SP21: TPanel;
    SP23: TPanel;
    D2: TPanel;
    N2: TPanel;
    VA2: TPanel;
    EA2: TPanel;
    VK2: TPanel;
    EF2: TPanel;
    EK2: TPanel;
    VX2: TPanel;
    VF2: TPanel;
    EX2: TPanel;
    D3: TPanel;
    N3: TPanel;
    VA3: TPanel;
    EA3: TPanel;
    VK3: TPanel;
    D4: TPanel;
    N4: TPanel;
    D5: TPanel;
    N5: TPanel;
    D6: TPanel;
    N6: TPanel;
    D7: TPanel;
    N7: TPanel;
    D8: TPanel;
    N8: TPanel;
    D9: TPanel;
    N9: TPanel;
    D10: TPanel;
    N10: TPanel;
    D11: TPanel;
    N11: TPanel;
    D12: TPanel;
    N12: TPanel;
    D13: TPanel;
    N13: TPanel;
    D14: TPanel;
    N14: TPanel;
    D15: TPanel;
    N15: TPanel;
    D16: TPanel;
    N16: TPanel;
    D17: TPanel;
    N17: TPanel;
    D18: TPanel;
    N18: TPanel;
    D19: TPanel;
    N19: TPanel;
    D20: TPanel;
    N20: TPanel;
    D21: TPanel;
    N21: TPanel;
    D22: TPanel;
    N22: TPanel;
    D23: TPanel;
    N23: TPanel;
    EK3: TPanel;
    VA4: TPanel;
    EA4: TPanel;
    VK4: TPanel;
    EK4: TPanel;
    VA6: TPanel;
    EA6: TPanel;
    VK6: TPanel;
    EK6: TPanel;
    VA8: TPanel;
    EA8: TPanel;
    VK8: TPanel;
    EK8: TPanel;
    VA10: TPanel;
    EA10: TPanel;
    VK10: TPanel;
    EK10: TPanel;
    VA12: TPanel;
    EA12: TPanel;
    VK12: TPanel;
    EK12: TPanel;
    VA14: TPanel;
    EA14: TPanel;
    VK14: TPanel;
    EK14: TPanel;
    VA16: TPanel;
    EA16: TPanel;
    VK16: TPanel;
    EK16: TPanel;
    VA18: TPanel;
    EA18: TPanel;
    VK18: TPanel;
    EK18: TPanel;
    VA20: TPanel;
    EA20: TPanel;
    VK20: TPanel;
    EK20: TPanel;
    VA22: TPanel;
    EA22: TPanel;
    VK22: TPanel;
    EK22: TPanel;
    VF3: TPanel;
    EF3: TPanel;
    VK5: TPanel;
    EK5: TPanel;
    VK7: TPanel;
    EK7: TPanel;
    VK9: TPanel;
    EK9: TPanel;
    VK11: TPanel;
    EK11: TPanel;
    VK13: TPanel;
    EK13: TPanel;
    VK15: TPanel;
    EK15: TPanel;
    VK17: TPanel;
    EK17: TPanel;
    VK19: TPanel;
    EK19: TPanel;
    VK21: TPanel;
    EK21: TPanel;
    VA5: TPanel;
    EA5: TPanel;
    VA7: TPanel;
    EA7: TPanel;
    VA9: TPanel;
    EA9: TPanel;
    VA11: TPanel;
    EA11: TPanel;
    VA13: TPanel;
    EA13: TPanel;
    VA15: TPanel;
    EA15: TPanel;
    VA17: TPanel;
    EA17: TPanel;
    VA19: TPanel;
    EA19: TPanel;
    VA21: TPanel;
    EA21: TPanel;
    VA23: TPanel;
    EA23: TPanel;
    VK23: TPanel;
    EK23: TPanel;
    VF4: TPanel;
    EF4: TPanel;
    VF5: TPanel;
    EF5: TPanel;
    VF6: TPanel;
    EF6: TPanel;
    VF7: TPanel;
    EF7: TPanel;
    VF8: TPanel;
    EF8: TPanel;
    VF9: TPanel;
    EF9: TPanel;
    VF10: TPanel;
    EF10: TPanel;
    VF11: TPanel;
    EF11: TPanel;
    VF12: TPanel;
    EF12: TPanel;
    VF13: TPanel;
    EF13: TPanel;
    VF14: TPanel;
    EF14: TPanel;
    VF15: TPanel;
    EF15: TPanel;
    VF16: TPanel;
    EF16: TPanel;
    VF17: TPanel;
    EF17: TPanel;
    VF18: TPanel;
    EF18: TPanel;
    VF19: TPanel;
    EF19: TPanel;
    VF20: TPanel;
    EF20: TPanel;
    VF21: TPanel;
    EF21: TPanel;
    VF22: TPanel;
    EF22: TPanel;
    VF23: TPanel;
    EF23: TPanel;
    VX3: TPanel;
    VX4: TPanel;
    VX5: TPanel;
    VX6: TPanel;
    VX7: TPanel;
    VX8: TPanel;
    VX9: TPanel;
    VX10: TPanel;
    VX11: TPanel;
    VX12: TPanel;
    VX13: TPanel;
    VX14: TPanel;
    VX15: TPanel;
    VX16: TPanel;
    VX17: TPanel;
    VX18: TPanel;
    VX19: TPanel;
    VX20: TPanel;
    VX21: TPanel;
    VX22: TPanel;
    VX23: TPanel;
    EX3: TPanel;
    EX4: TPanel;
    EX5: TPanel;
    EX6: TPanel;
    EX7: TPanel;
    EX8: TPanel;
    EX9: TPanel;
    EX10: TPanel;
    EX11: TPanel;
    EX12: TPanel;
    EX13: TPanel;
    EX14: TPanel;
    EX15: TPanel;
    EX16: TPanel;
    EX17: TPanel;
    EX18: TPanel;
    EX19: TPanel;
    EX20: TPanel;
    EX21: TPanel;
    EX22: TPanel;
    EX23: TPanel;
    HINTPANEL: TPanel;
    Label3: TLabel;
    Shape3: TShape;
    D1: TPanel;
    N1: TPanel;
    VA1: TPanel;
    EA1: TPanel;
    VK1: TPanel;
    EK1: TPanel;
    VF1: TPanel;
    EF1: TPanel;
    VX1: TPanel;
    EX1: TPanel;
    SP24: TPanel;
    D24: TPanel;
    N24: TPanel;
    VA24: TPanel;
    EA24: TPanel;
    VK24: TPanel;
    EK24: TPanel;
    VF24: TPanel;
    EF24: TPanel;
    VX24: TPanel;
    EX24: TPanel;
    SP25: TPanel;
    SP27: TPanel;
    SP26: TPanel;
    EX25: TPanel;
    VX25: TPanel;
    EF25: TPanel;
    VF25: TPanel;
    EK25: TPanel;
    VK25: TPanel;
    EA25: TPanel;
    VA25: TPanel;
    N25: TPanel;
    D25: TPanel;
    EX26: TPanel;
    VX26: TPanel;
    EF26: TPanel;
    VF26: TPanel;
    EK26: TPanel;
    VK26: TPanel;
    EA26: TPanel;
    VA26: TPanel;
    N26: TPanel;
    D26: TPanel;
    EX27: TPanel;
    VX27: TPanel;
    EF27: TPanel;
    VF27: TPanel;
    EK27: TPanel;
    VK27: TPanel;
    EA27: TPanel;
    VA27: TPanel;
    N27: TPanel;
    D27: TPanel;

    procedure FormActivate(Sender: TObject);

    procedure Adatbeolvasas;

    function Limformat(_int: integer):string;
    function RealToStr(_rr: real): string;
    function VesszobolPont(_ss: string): string;
    function ScanDnem(_adnem: string): integer;
    function ScanLive(_adnem: string): integer;

    procedure NyujtoTimer(Sender: TObject);
    procedure AdatNullazas;

    procedure Becuppanas;
    procedure OkeGombClick(Sender: TObject);

    function Nulele(_int: integer): string;
    procedure GetTablasoroszlop(_cnev: string);

    procedure shkcuppanas;
    procedure TombokbeToltes;
    procedure PanelFeltoltes;
    procedure CellaRegeneracio;
    procedure GetCellaColor;


    function Realform(_real:real):string;
    function Arfformat(_real:real):string;

    procedure Nyujto2Timer(Sender: TObject);
    procedure SHKOkeGombClick(Sender: TObject);
    procedure UjarfEditKeyDown(Sender: TObject; var Key: Word;
                                                       Shift: TShiftState);
    procedure ESCAPEGOMBClick(Sender: TObject);
    procedure VK2MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure SP1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure VK2MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure VX2MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure VX2MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
   

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  arfolyamtablakijelzes: Tarfolyamtablakijelzes;
  _top,_left,_height,_width,_pp,_sav,_aktbankjegy: integer;
  _coszlop,_csor,_dnemDarab,_blokkErtek,_code,_ujarfint,_kod: integer;
  _eles,_cellChange: boolean;
  _ujArfolyam: real;
  _aktcella: TPanel;
  _cellarow,_cellacolumn: word;

  _hpTop,_hpLeft,_aktmenet: word;
  _xx,_SAJATHATASKORU: integer;

  _pcs,_elojel,_cellatype,_cellaOszlopBetu: string;
  _sorveg: string = #13#10;
  _dnem,_dnev: array[0..26] of string;
  _varf,_earf,_k1vet,_k2vet,_k1ela,_k2ela,_shkv,_shke: array[0..26] of real;
  _limit1,_limit2,_limit3,_recno,_ftErtek: integer;
  _cl,_ct,_ch,_cw: integer;
  _qq,_aktbjegy,_aktosszeg,_kategoria,_cellasor,_cellaoszlop: integer;
  _aktdnem,_aktdnev: string;
  _aktvarf,_aktearf,_aktk1vet,_aktk1ela,_aktk2vet,_aktk2ela: real;
  _aktmaxvet,_aktminelad,_tolarfolyam,_igarfolyam: real;
  _aktmaxvarf,_aktminearf,_eurvetarf: real;
  _l1str,_l2str,_l3str,_cellanev: string;
  _liveDnemDarab: integer;
  _livednem,_liveelojel: array[1..6] of string;
  _livebjegy: array[1..6] of integer;
  _shklimit,_aktlimit,_fizetendo,_index: integer;
  _voltshk,_mayshk: boolean;
  _lastcella: TPanel;
  _lastColor: TColor;

  _dpanel,_npanel,_vaPanel,_eaPanel,_vkPanel,_ekPanel: array[0..26] of TPanel;
  _vfPanel,_efPanel,_vxPanel,_exPanel,_sp: array[0..26] of TPanel;
  _maymove: boolean;

  _VTIPUS: STRING; // = 'V';  //  = 'K';  // TESZT !!!!!!!!!!!!!!!!!!!!!

Function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll' name 'logirorutin';
 function arfolyamkijelzes(_para: string): integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
         function arfolyamkijelzes(_para:string): integer; stdcall;
// =============================================================================

begin
  // Parameter: '0' = csak árfolyamtábla megtekintése
  //            'V' vagy 'E' vagy 'K' = vétel vagy eladás vagy konverzió

  arfolyamtablakijelzes := TarfolyamtablaKijelzes.create(Nil);
  _eles   := False;
  _vtipus := _para;
  _mayShk := False;
  if _vTipus<>'0' then _eles := True;

  Result := ArfolyamTablakijelzes.Showmodal;
  ArfolyamtablaKijelzes.Free;
end;



// =============================================================================
        procedure Tarfolyamtablakijelzes.FormActivate(Sender: TObject);
// =============================================================================

begin
  // _eles := true;    // TESZT !!!!!!!!!!!!!!!!!!!!!

  // Képernyõ betájolása -----------------------------------------------------

  _top   := 0;
  _left  := 0;

  CupPanel.Visible  := False;
  CupPanel2.visible := False;
  HintPanel.Visible := False;

  _height:= Screen.Monitors[0].Height;
  _width := Screen.Monitors[0].width;

  if _height>768 then _top := trunc((_height-768)/2);
  if _width>1024 then _left := trunc((_width-1024)/2);

  Top    := _top;
  Left   := _left;
  width  := 1024;
  Height := 768;

  _voltshk := False;  // Sajáthatáskörü jelzõ flag alapra

  _lastColor := 0;
  _lastCella := Nil;
  _mayMove   := true;

  Adatnullazas;    // Arfolyam-tömbök kinullázása
  TombokbeToltes;  // A cellapanelek tömbökbe töltése

  // Beolvassa: - a kedvezmény-limiteket és hogy hány sajátkörü volt már ma
  //              a hardware táblából
  //
  //            - a HUF kivitelével az összes valuta 8-8 árfolyamát
  // Meghatározza: - a külf-i valutár darabszámát (_dnemDarab)
  //               - az sajáthatáskörü kedvezmény alsó határát (_shklimit)
  //
  // Betölti:  - az árfolyamadatokat a cella-panelekbe
  //           - az aktuális tranzakció valutáit (ha bankjegy>0)
  //             és mennyiségét, és hogy hány ilyen van
  //             _livednem,_livebjegy  (_livednemdarab)


  AdatBeolvasas;

  // Ha már mind az 5 lehetõség kimerült a függöny legördül:

  IF _sajathataskoru>4 then
    begin
      with SHKFuggony do
        begin
          Top := 8;
          Left := 808;
          Visible := True;
          Repaint;
        end;
    end else SHKFuggony.Visible := false;
end;


// =============================================================================
          procedure TArfolyamTablaKijelzes.Adatbeolvasas;
// =============================================================================

var _cc,i: integer;

begin

  ArfolyamDbase.connected := True;

  _pcs := 'SELECT * FROM HARDWARE' + _sorveg;

  with ArfolyamQuery do
    begin
      Close;
      sql.clear;
      Sql.Add(_pcs);
      Open;

      _limit1 := FieldByName('LIMIT1').asInteger;
      _limit2 := FieldByName('LIMIT2').asInteger;
      _limit3 := FieldByName('LIMIT3').asInteger;
      _sajathataskoru := FieldByNAme('SAJATHATASKORU').asInteger;

      close;
    end;


   _pcs := 'SELECT* FROM ARFOLYAM' + _sorveg;
   _pcs := _pcs + 'WHERE VALUTANEM<>'+chr(39)+'RCH'+chr(39)+_sorveg;
   _pcs := _pcs + 'ORDER BY VALUTANEM';

   with ArfolyamQuery do
     begin
       close;
       sql.Clear;
       sql.Add(_pcs);
       Open;
       First;
     end;

   _cc := 0;
   while not ArfolyamQuery.eof do
     begin
       _aktdnem := ArfolyamQuery.FieldByName('VALUTANEM').asString;
       if _aktdnem<>'HUF' then
         begin
           _dnem[_cc] := _aktdnem;
           with ArfolyamQuery do
             begin
               _dnev[_cc] := TRIM(FieldByNAme('VALUTANEV').asstring);
               _varf[_cc] := FieldByNAme('VETELIARFOLYAM').asFloat;
               _earf[_cc] := FieldByNAme('ELADASIARFOLYAM').asFloat;
               _k1vet[_cc]:= FieldByName('K1VETEL').asFloat;
               _k2vet[_cc]:= FieldByName('K2VETEL').asFloat;
               _k1ela[_cc]:= FieldByName('K1ELADAS').asFloat;
               _k2ela[_cc]:= FieldByName('K2ELADAS').asFloat;
               _shkv[_cc] := FieldByName('SHKVETARFOLYAM').asFloat;
               _shke[_cc] := FieldByName('SHKELADARFOLYAM').asFloat;
             end;

           if _aktdnem='EUR' then _eurvetarf := _varf[_cc];
           inc(_cc);
         end;
       ArfolyamQuery.Next;
     end;

   _dnemDarab := _cc;
   _shklimit := trunc(10*_eurvetarf);
   ArfolyamQuery.close;
   ArfolyamDbase.close;

   // --------------------------------------------------------------------------

   PanelFeltoltes;

   // --------------------------------------------------------------------------

   TempDbase.Connected := true;
   _pcs := 'SELECT * FROM VTEMP'+_sorveg;
   _pcs := _pcs + 'WHERE BANKJEGY>0';
   with TempQuery do
     begin
       Close;
       Sql.Clear;
       sql.Add(_pcs);
       Open;
       First;
     end;

   _livednemdarab := 0;
   _fizetendo := 0;

   _aktmenet := TempQuery.FieldByName('MENET').asInteger;
   while not TempQuery.eof do
     begin
       _aktdnem  := Tempquery.FieldbyNAme('VALUTANEM').asString;
       _aktbjegy := Tempquery.FieldByName('BANKJEGY').asInteger;
       _ftertek  := Tempquery.FieldByName('FORINTERTEK').asInteger;
       _elojel   := TempQuery.FieldByNAme('ELOJEL').asstring;

       inc(_liveDnemdarab);

       _liveDnem[_liveDnemDarab] := _aktdnem;
       _livebjegy[_liveDnemdarab]:= _aktbjegy;
       _liveelojel[_livednemDarab] := _elojel;

       _fizetendo := _fizetendo + _ftErtek;
       Tempquery.Next;
     end;
   Tempquery.close;
   TempDbase.close;

//   _kategoria := 1;
//   if (_fizetendo>=_limit1) and (_fizetendo<_limit2) then _kategoria := 2;
//   if _fizetendo>=_limit2 then _kategoria := 3;

   if _fizetendo>=_shklimit then _mayshk := True;  // !!!!!
//   if _otvenedik=50 then _mayshk := true;

   for i := 0 to 26 do
     begin
       _sp[i].Color := clGray;
       _vkpanel[i].Cursor := crDefault;
       _ekpanel[i].Cursor := crDefault;
       _vfpanel[i].Cursor := crDefault;
       _efpanel[i].Cursor := crDefault;
       _vxpanel[i].Cursor := crDefault;
       _expanel[i].Cursor := crDefault;
     end;

   if _eles then
     begin
       if _livednemDarab>0 then
         begin
           for i := 1 to _liveDnemDarab do
             begin
               _aktdnem := _livednem[i];
               _aktbjegy:= _livebjegy[i];
               _elojel  := _liveElojel[i];

               _xx := scandnem(_aktdnem);

               if (_vtipus='V') OR ((_vtipus='K') AND (_elojel='+') AND (_aktmenet=1)) then
                 begin
                //   _vaPanel[_xx].Cursor := crHandPoint;
                //   if _fizetendo>_limit1 then _vkpanel[_xx].Cursor := crHandPoint;
                //   if _fizetendo>_limit2 then _vfpanel[_xx].Cursor := crHandPoint;

                   _vkpanel[_xx].Cursor := crHandPoint;
                   _vfpanel[_xx].Cursor := crHandPoint;

                   if _mayshk then _vxPanel[_xx].Cursor := crHandPoint;
                 end;

               if (_vtipus='E') OR ((_vtipus='K') AND (_elojel='-') AND (_aktmenet=2))  then
                 begin

                   // if _fizetendo>_limit1 then _ekpanel[_xx].Cursor := crHandPoint;
                   // if _fizetendo>_limit2 then _efpanel[_xx].Cursor := crHandPoint;

                   _ekpanel[_xx].Cursor := crHandPoint;
                   _efpanel[_xx].Cursor := crHandPoint;

                   if _mayshk then _exPanel[_xx].Cursor := crHandPoint;
                 end;

             end;
         end;
     end;
end;

// =============================================================================
          function TarfolyamtablaKijelzes.Arfformat(_real:real):string;
// =============================================================================


begin
  result := realform(_real);
//  while length(result)<18 do result := ' '+result;
end;

// =============================================================================
        function TarfolyamTablaKijelzes.Limformat(_int: integer):string;
// =============================================================================


var _pp: integer;

begin
  result := inttostr(_int);
  _pp := length(result);

  if _pp<4 then exit;

  if _pp>6 then
    begin
      _pp := _pp - 6;
      result := leftstr(result,_pp)+'.'+midstr(result,_pp+1,3)+'.'+midstr(result,_pp+4,3);
      exit;
    end;
  _pp := _pp-3;
  result := leftstr(result,_pp)+'.'+midstr(result,_pp+1,3);
end;


(*

// =============================================================================
    procedure Tarfolyamtablakijelzes.ARFOLYAMRACSSelectCell(Sender: TObject;
                                  ACol, ARow: Integer; var CanSelect: Boolean);
// =============================================================================

begin
  if not _eles then exit;
  if _livednemdarab=0 then exit;

  _cSor := Arow;
  _cOszlop := Acol;
  if _coSzlop<4 then exit;

  _aktdnem := _dnem[_cSor]; // ennek a valutának a sorára kattintott

  _xx := 1;
  while _xx<=_liveDnemDarab do
    begin
      if _livednem[_xx]=_aktdnem then break;
      inc(_xx);
      if _xx>_livednemDarab then exit;
    end;

  _aktbjegy := _livebjegy[_xx];

  if _vtipus='V' then
    begin
      case _cOszlop of
      //  2: _ujarfolyam := _varf[_csor];
      //  3: exit;
        4: _ujarfolyam := _k1Vet[_cSor];
        5: exit;
        6: _ujarfolyam := _k2Vet[_cSor];
        7: exit;
        8: begin
             _igarfolyam := _shkv[_csor];
             _tolarfolyam  := _varf[_csor];
           end;

        9: exit;
      end;
    end else
    begin
      case _cOszlop of
      //  2: exit;
      //  3: _ujarfolyam := _earf[_cSor];
        4: exit;
        5: _ujarfolyam := _k1Ela[_cSor];
        6: exit;
        7: _ujarfolyam := _k2Ela[_cSor];
        8: exit;
        9: begin
            _tolarfolyam := _shke[_cSor];
            _igarfolyam:= _earf[_cSor];
           end;
      end;
    end;

  if _coszlop<8 then
    begin
      Becuppanas;
      Exit;
    end;

  _aktosszeg := trunc(_tolarfolyam*_aktbjegy/100);
  if _aktosszeg>=_shklimit then sHKCUPPANAS;
end;
*)


// =============================================================================
       function TarfolyamTablaKijelzes.ScanDnem(_adnem: string): integer;
// =============================================================================

var y: integer;

begin
  result := -1;
  for y := 0 to _dnemDarab-1 do
    begin
      if _dnem[y]=_adnem then
        begin
          result := y;
          break;
        end;
    end;
end;


// =============================================================================
       function TarfolyamTablaKijelzes.ScanLive(_adnem: string): integer;
// =============================================================================

var y: integer;

begin
  result := 0;
  for y := 1 to _liveDnemDarab do
    begin
      if _livednem[y]=_adnem then
        begin
          result := y;
          break;
        end;
    end;
end;


// =============================================================================
        procedure Tarfolyamtablakijelzes.NYUJTOTimer(Sender: TObject);
// =============================================================================

begin
  Nyujto.enabled := false;
  _cl := _cl - 12;
  _ct := _ct -2;
  _cw := _cw + 24;
  _ch := _ch + 5;
  with cuppanel do
    begin
      top := _ct;
      Left := _cl;
      Height := _ch;
      Width := _cw;
    end;
  if _cw<430 then Nyujto.Enabled := True
  else Activecontrol := okeGomb;
end;

// =============================================================================
        procedure Tarfolyamtablakijelzes.OKEGOMBClick(Sender: TObject);
// =============================================================================


begin
  CellaRegeneracio;

  if _aktdnem='JPY' then _ujarfolyam := _ujarfolyam*10;
  _ujarfint := round(_ujarfolyam);
  if _aktdnem='JPY' then _ujarfolyam := _ujarfint/10
  else _ujarfolyam := 1*_ujarfint;

  _pcs := 'UPDATE VTEMP SET ARFOLYAM=' + realtostr(_ujarfolyam)+',';
  _PCS := _PCS + 'KEDVEZMENYESARFOLYAM=' + realtostr(_ujarfolyam) + _sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39) + _aktdnem + chr(39);

  TempDbase.Connected := true;
  if TempTranz.InTransaction then TempTranz.Commit;
  Temptranz.StartTransaction;
  with TempQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Execsql;
    end;
  TempTranz.Commit;
  Tempdbase.close;

  logirorutin(pchar('Pénztáros kedvezménye: '+_aktdnem+'-nél '+inttostr(_ujarfint)));

  _xx := ScanLive(_aktdnem);
  Modalresult := _xx;
end;


// =============================================================================
       function TArfolyamTablaKijelzes.Realform(_real:real):string;
// =============================================================================

var _egesz,_tort,_lenegesz,_pp: integer;

begin
  _egesz    := trunc(_real);
  _tort     := trunc(100*(_real-_egesz));
  result    := inttostr(_egesz);
  _lenegesz := length(result);
  if _lenegesz>3 then
    begin
      if _lenegesz>6 then
        begin
          _pp := _lenegesz-6;
          result := leftstr(result,_pp)+','+midstr(result,_pp+1,3)+','+midstr(result,_pp+4,3);
        end else
        begin
          _pp := _lenegesz-3;
          result := leftstr(result,_pp)+','+midstr(result,_pp+1,3);
        end;
    end;
   if _tort>0 then
             result := result + '.' + nulele(_tort);
end;

// =============================================================================
        function TArfolyamTablaKijelzes.Nulele(_int: integer): string;
// =============================================================================

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;

// =============================================================================
          function TArfolyamTablaKijelzes.RealToStr(_rr: real): string;
// =============================================================================

var _pos: integer;

begin
  Result := '0';
  if _rr=0 then exit;

  Result := Floattostr(_rr);
  _pos := pos(chr(44),result);
  if _pos>0 then result[_pos] := chr(46);
end;


// =============================================================================
           procedure Tarfolyamtablakijelzes.NYUJTO2Timer(Sender: TObject);
// =============================================================================

begin
   Nyujto2.enabled := false;
  _cw := _cw + 20;
  _ch := _ch + 10;
  with cuppanel2 do
    begin
      Height := _ch;
      Width := _cw;
    end;
  if _cw<430 then Nyujto2.Enabled := True
  else Activecontrol := SHKOKEGOMB;
end;


// =============================================================================
        procedure Tarfolyamtablakijelzes.SHKOKEGOMBClick(Sender: TObject);
// =============================================================================

var _arfs: string;

begin

  CellaRegeneracio;

  _arfs := trim(ujarfedit.Text);
  _arfs := vesszobolpont(_arfs);
  val(_arfs,_ujarfolyam,_code);

  if _code<>0 then _ujarfolyam:=0;

  if (_ujarfolyam<_tolarfolyam) or (_ujarfolyam>_igarfolyam) then
    begin
      Cuppanel2.Visible := false;
      exit;
    end;

   if _aktdnem='JPY' then _ujarfolyam := _ujarfolyam*10;
  _ujarfint := round(_ujarfolyam);

  if _aktdnem='JPY' then _ujarfolyam := _ujarfint/10
  else _ujarfolyam := 1*_ujarfint;

  logirorutin(pchar('Saját hatáskörben a '+_aktdnem+' valuta kedvezmémyes árfolyama: '+inttostr(_ujarfint)));

  _pcs := 'UPDATE VTEMP SET ARFOLYAM=' + realtostr(_ujarfolyam)+',';
  _PCS := _PCS + 'KEDVEZMENYESARFOLYAM=' + realtostr(_ujarfolyam) + _sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39) + _aktdnem + chr(39);

  TempDbase.Connected := true;
  if TempTranz.InTransaction then TempTranz.Commit;
  Temptranz.StartTransaction;
  with TempQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Execsql;
    end;
  TempTranz.Commit;
  Tempdbase.close;

  _xx := ScanLive(_aktdnem);
  Modalresult := _xx+100;
end;



// =============================================================================
        function TarfolyamTablaKijelzes.VesszobolPont(_ss: string): string;
// =============================================================================


var _y: integer;

begin
  result := '';
  _y := 1;
  if length(_ss)=0 then exit;

  while _y<=length(_ss) do
    begin
      _kod := ord(_ss[_y]);
      if _kod=44 then _kod := 46;
      result := result + chr(_kod);
      inc(_y);
    end;
end;


// =============================================================================
            procedure TarfolyamTablaKijelzes.PanelFeltoltes;
// =============================================================================

var i: integer;

begin
  for i := 0 to _dnemdarab-1 do
    begin
      _dpanel[i].Caption  := _dnem[i];
      _nPanel[i].Caption  := _dNev[i];
      _vaPanel[i].Caption := arfformat(_varf[i]);
      _eaPanel[i].Caption := arfformat(_earf[i]);
      _vkPanel[i].Caption := arfformat(_k1vet[i]);
      _ekPanel[i].Caption := arfformat(_k1ela[i]);
      _vfPanel[i].Caption := arfformat(_k2vet[i]);
      _efPanel[i].Caption := arfformat(_k2ela[i]);
      _vxPanel[i].Caption := arfformat(_shkv[i]);
      _exPanel[i].Caption := arfformat(_shke[i]);
    end;
end;


// =============================================================================
            procedure TarfolyamTablaKijelzes.Adatnullazas;
// =============================================================================

var i: integer;

begin
  for i := 0 to 26 do
    begin
      _dnem[i]  := '';
      _dNev[i]  := '';
      _varf[i]  := 0;
      _earf[i]  := 0;
      _k1vet[i] := 0;
      _k1ela[i] := 0;
      _k2vet[i] := 0;
      _k2ela[i] := 0;
       _shkv[i] := 0;
       _shke[i] := 0;
    end;
end;



// =============================================================================
        procedure Tarfolyamtablakijelzes.UJARFEDITKeyDown(Sender: TObject;
// =============================================================================

var Key: Word; Shift: TShiftState);

begin
  if ord(key)<>13 then exit;
  if ujarfedit.text = '' then exit;
  Activecontrol := ShkOkeGomb;
end;


// =============================================================================
              procedure TArfolyamTablaKijelzes.TombokbeToltes;
// =============================================================================

begin
   _sp[0] := sp1;
   _sp[1] := sp2;
   _sp[2] := sp3;
   _sp[3] := sp4;
   _sp[4] := sp5;
   _sp[5] := sp6;
   _sp[6] := sp7;
   _sp[7] := sp8;
   _sp[8] := sp9;
   _sp[9] := sp10;

   _sp[10] := sp11;
   _sp[11] := sp12;
   _sp[12] := sp13;
   _sp[13] := sp14;
   _sp[14] := sp15;
   _sp[15] := sp16;
   _sp[16] := sp17;
   _sp[17] := sp18;
   _sp[18] := sp19;
   _sp[19] := sp20;
   _sp[20] := sp21;
   _sp[21] := sp22;
   _sp[22] := sp23;
   _sp[23] := sp24;
   _sp[24] := sp25;
   _sp[25] := sp26;
   _sp[26] := sp27;

   _dPanel[0] := d1;
   _nPanel[0] := n1;
  _vaPanel[0] := va1;
  _eaPanel[0] := ea1;
  _vkPanel[0] := vk1;
  _ekPanel[0] := ek1;
  _vfPanel[0] := vf1;
  _efPanel[0] := ef1;
  _vxPanel[0] := vx1;
  _exPanel[0] := ex1;

   _dPanel[1] := d2;
   _nPanel[1] := n2;
  _vaPanel[1] := va2;
  _eaPanel[1] := ea2;
  _vkPanel[1] := vk2;
  _ekPanel[1] := ek2;
  _vfPanel[1] := vf2;
  _efPanel[1] := ef2;
  _vxPanel[1] := vx2;
  _exPanel[1] := ex2;

   _dPanel[2] := d3;
   _nPanel[2] := n3;
  _vaPanel[2] := va3;
  _eaPanel[2] := ea3;
  _vkPanel[2] := vk3;
  _ekPanel[2] := ek3;
  _vfPanel[2] := vf3;
  _efPanel[2] := ef3;
  _vxPanel[2] := vx3;
  _exPanel[2] := ex3;

   _dPanel[3] := d4;
   _nPanel[3] := n4;
  _vaPanel[3] := va4;
  _eaPanel[3] := ea4;
  _vkPanel[3] := vk4;
  _ekPanel[3] := ek4;
  _vfPanel[3] := vf4;
  _efPanel[3] := ef4;
  _vxPanel[3] := vx4;
  _exPanel[3] := ex4;

   _dPanel[4] := d5;
   _nPanel[4] := n5;
  _vaPanel[4] := va5;
  _eaPanel[4] := ea5;
  _vkPanel[4] := vk5;
  _ekPanel[4] := ek5;
  _vfPanel[4] := vf5;
  _efPanel[4] := ef5;
  _vxPanel[4] := vx5;
  _exPanel[4] := ex5;

   _dPanel[5] := d6;
   _nPanel[5] := n6;
  _vaPanel[5] := va6;
  _eaPanel[5] := ea6;
  _vkPanel[5] := vk6;
  _ekPanel[5] := ek6;
  _vfPanel[5] := vf6;
  _efPanel[5] := ef6;
  _vxPanel[5] := vx6;
  _exPanel[5] := ex6;

   _dPanel[6] := d7;
   _nPanel[6] := n7;
  _vaPanel[6] := va7;
  _eaPanel[6] := ea7;
  _vkPanel[6] := vk7;
  _ekPanel[6] := ek7;
  _vfPanel[6] := vf7;
  _efPanel[6] := ef7;
  _vxPanel[6] := vx7;
  _exPanel[6] := ex7;

   _dPanel[7] := d8;
   _nPanel[7] := n8;
  _vaPanel[7] := va8;
  _eaPanel[7] := ea8;
  _vkPanel[7] := vk8;
  _ekPanel[7] := ek8;
  _vfPanel[7] := vf8;
  _efPanel[7] := ef8;
  _vxPanel[7] := vx8;
  _exPanel[7] := ex8;

   _dPanel[8] := d9;
   _nPanel[8] := n9;
  _vaPanel[8] := va9;
  _eaPanel[8] := ea9;
  _vkPanel[8] := vk9;
  _ekPanel[8] := ek9;
  _vfPanel[8] := vf9;
  _efPanel[8] := ef9;
  _vxPanel[8] := vx9;
  _exPanel[8] := ex9;

   _dPanel[9] := d10;
   _nPanel[9] := n10;
  _vaPanel[9] := va10;
  _eaPanel[9] := ea10;
  _vkPanel[9] := vk10;
  _ekPanel[9] := ek10;
  _vfPanel[9] := vf10;
  _efPanel[9] := ef10;
  _vxPanel[9] := vx10;
  _exPanel[9] := ex10;

   _dPanel[10] := d11;
   _nPanel[10] := n11;
  _vaPanel[10] := va11;
  _eaPanel[10] := ea11;
  _vkPanel[10] := vk11;
  _ekPanel[10] := ek11;
  _vfPanel[10] := vf11;
  _efPanel[10] := ef11;
  _vxPanel[10] := vx11;
  _exPanel[10] := ex11;

   _dPanel[11] := d12;
   _nPanel[11] := n12;
  _vaPanel[11] := va12;
  _eaPanel[11] := ea12;
  _vkPanel[11] := vk12;
  _ekPanel[11] := ek12;
  _vfPanel[11] := vf12;
  _efPanel[11] := ef12;
  _vxPanel[11] := vx12;
  _exPanel[11] := ex12;

   _dPanel[12] := d13;
   _nPanel[12] := n13;
  _vaPanel[12] := va13;
  _eaPanel[12] := ea13;
  _vkPanel[12] := vk13;
  _ekPanel[12] := ek13;
  _vfPanel[12] := vf13;
  _efPanel[12] := ef13;
  _vxPanel[12] := vx13;
  _exPanel[12] := ex13;

   _dPanel[13] := d14;
   _nPanel[13] := n14;
  _vaPanel[13] := va14;
  _eaPanel[13] := ea14;
  _vkPanel[13] := vk14;
  _ekPanel[13] := ek14;
  _vfPanel[13] := vf14;
  _efPanel[13] := ef14;
  _vxPanel[13] := vx14;
  _exPanel[13] := ex14;

   _dPanel[14] := d15;
   _nPanel[14] := n15;
  _vaPanel[14] := va15;
  _eaPanel[14] := ea15;
  _vkPanel[14] := vk15;
  _ekPanel[14] := ek15;
  _vfPanel[14] := vf15;
  _efPanel[14] := ef15;
  _vxPanel[14] := vx15;
  _exPanel[14] := ex15;

   _dPanel[15] := d16;
   _nPanel[15] := n16;
  _vaPanel[15] := va16;
  _eaPanel[15] := ea16;
  _vkPanel[15] := vk16;
  _ekPanel[15] := ek16;
  _vfPanel[15] := vf16;
  _efPanel[15] := ef16;
  _vxPanel[15] := vx16;
  _exPanel[15] := ex16;

   _dPanel[16] := d17;
   _nPanel[16] := n17;
  _vaPanel[16] := va17;
  _eaPanel[16] := ea17;
  _vkPanel[16] := vk17;
  _ekPanel[16] := ek17;
  _vfPanel[16] := vf17;
  _efPanel[16] := ef17;
  _vxPanel[16] := vx17;
  _exPanel[16] := ex17;

   _dPanel[17] := d18;
   _nPanel[17] := n18;
  _vaPanel[17] := va18;
  _eaPanel[17] := ea18;
  _vkPanel[17] := vk18;
  _ekPanel[17] := ek18;
  _vfPanel[17] := vf18;
  _efPanel[17] := ef18;
  _vxPanel[17] := vx18;
  _exPanel[17] := ex18;

   _dPanel[18] := d19;
   _nPanel[18] := n19;
  _vaPanel[18] := va19;
  _eaPanel[18] := ea19;
  _vkPanel[18] := vk19;
  _ekPanel[18] := ek19;
  _vfPanel[18] := vf19;
  _efPanel[18] := ef19;
  _vxPanel[18] := vx19;
  _exPanel[18] := ex19;

   _dPanel[19] := d20;
   _nPanel[19] := n20;
  _vaPanel[19] := va20;
  _eaPanel[19] := ea20;
  _vkPanel[19] := vk20;
  _ekPanel[19] := ek20;
  _vfPanel[19] := vf20;
  _efPanel[19] := ef20;
  _vxPanel[19] := vx20;
  _exPanel[19] := ex20;

   _dPanel[20] := d21;
   _nPanel[20] := n21;
  _vaPanel[20] := va21;
  _eaPanel[20] := ea21;
  _vkPanel[20] := vk21;
  _ekPanel[20] := ek21;
  _vfPanel[20] := vf21;
  _efPanel[20] := ef21;
  _vxPanel[20] := vx21;
  _exPanel[20] := ex21;

   _dPanel[21] := d22;
   _nPanel[21] := n22;
  _vaPanel[21] := va22;
  _eaPanel[21] := ea22;
  _vkPanel[21] := vk22;
  _ekPanel[21] := ek22;
  _vfPanel[21] := vf22;
  _efPanel[21] := ef22;
  _vXPanel[21] := vx22;
  _eXPanel[21] := ex22;

   _dPanel[22] := d23;
   _nPanel[22] := n23;
  _vaPanel[22] := va23;
  _eaPanel[22] := ea23;
  _vkPanel[22] := vk23;
  _ekPanel[22] := ek23;
  _vfPanel[22] := vf23;
  _efPanel[22] := ef23;
  _vXPanel[22] := vx23;
  _eXPanel[22] := ex23;

   _dPanel[23] := d24;
   _nPanel[23] := n24;
  _vaPanel[23] := va24;
  _eaPanel[23] := ea24;
  _vkPanel[23] := vk24;
  _ekPanel[23] := ek24;
  _vfPanel[23] := vf24;
  _efPanel[23] := ef24;
  _vXPanel[23] := vx24;
  _eXPanel[23] := ex24;

  _dPanel[24] := d25;
  _nPanel[24] := n25;
  _vaPanel[24]:= va25;
  _eaPanel[24]:= ea25;
  _vkPanel[24]:= vk25;
  _ekPanel[24]:= ek25;
  _vfPanel[24]:= vf25;
  _efPanel[24]:= ef25;
  _vXPanel[24]:= vx25;
  _eXPanel[24]:= ex25;

  _dPanel[25] := d26;
  _nPanel[25] := n26;
  _vaPanel[25]:= va26;
  _eaPanel[25]:= ea26;
  _vkPanel[25]:= vk26;
  _ekPanel[25]:= ek26;
  _vfPanel[25]:= vf26;
  _efPanel[25]:= ef26;
  _vXPanel[25]:= vx26;
  _eXPanel[25]:= ex26;

  _dPanel[26] := d27;
  _nPanel[26] := n27;
  _vaPanel[26]:= va27;
  _eaPanel[26]:= ea27;
  _vkPanel[26]:= vk27;
  _ekPanel[26]:= ek27;
  _vfPanel[26]:= vf27;
  _efPanel[26]:= ef27;
  _vXPanel[26]:= vx27;
  _eXPanel[26]:= ex27;
end;

// =============================================================================
         procedure Tarfolyamtablakijelzes.ESCAPEGOMBClick(Sender: TObject);
// =============================================================================

begin
  CellaRegeneracio;
  Modalresult := -1;
end;

// =============================================================================
        procedure TarfolyamTablakijelzes.GetTablasoroszlop(_cnev: string);
// =============================================================================

var _ww: integer;

begin
  _cellaType := leftstr(_cnev,1);
  _cellaOszlopBetu := midstr(_cnev,2,1);
  _ww := length(_cnev);
  _cellasor := strtoint(midstr(_cnev,3,_ww-2));

  if _cellaOszlopBetu='K' then _cellaoszlop := 5;
  if _cellaOszlopBetu='F' then _cellaoszlop := 7;
  if _cellaOszlopBetu='X' then _cellaoszlop := 9;
  if _cellaType='E' then inc(_cellaoszlop);

  _cellaRow    := 76 + trunc(21*_cellaSor);
  _cellaColumn := 424 + trunc(97*(_cellaoszlop-5));

end;


// =============================================================================
            procedure TArfolyamTablaKijelzes.CellaRegeneracio;
// =============================================================================

begin
  if _lastcolor=0 then exit;

  _lastcella.color := _lastColor;
  _lastcella.Font.Color := clBlack;
  _cellChange := False;
end;


// =============================================================================
                  procedure TArfolyamTablaKijelzes.GetCellaColor;
// =============================================================================

begin
   _lastCella := _aktcella;
   _lastColor := _aktcella.color;
   _aktcella.Color := clRed;
   _aktcella.Font.Color := clwhite;
   _cellchange := True;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// ------------------------- EGÉR MÜVELETEK ------------------------------------
//

// =============================================================================
       procedure Tarfolyamtablakijelzes.SP1MouseMove(Sender: TObject;
                                          Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  if not _maymove  then exit;
  HintPanel.Visible := False;
  CellaRegeneracio;
end;



// =============================================================================
       procedure Tarfolyamtablakijelzes.VK2MouseMove(Sender: TObject;
                                            Shift: TShiftState; X, Y: Integer);
// =============================================================================


begin
  if not _maymove then exit;
  _aktCella := TPanel(sender);
  if (_aktCella.Cursor<>crHandPoint) then
    begin
      CellaRegeneracio;
      exit;
    end;

  if not _cellChange  then GetcellaColor;

  _cellaNev := uppercase(_aktCella.name);
  GetTablasorOszlop(_cellanev);

  _hptop := _cellarow - 80;
  _hpleft := _cellacolumn-73;

  Hintpanel.Top     := _hpTop;
  Hintpanel.Left    := _hpLeft;
  HintPanel.Visible := true;
end;



// =============================================================================
        procedure Tarfolyamtablakijelzes.VK2MouseDown(Sender: TObject;
                      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
// =============================================================================


begin
  if not _maymove then exit;

  HintPanel.Visible := False;

  _aktCella := Tpanel(Sender);
  if _aktCella.cursor<>crHandPoint then exit;
  if Button<>mbleft then exit;
   _maymove := False;

  _cellanev := _aktcella.name;
  GetTablaSorOszlop(_cellanev);
  Becuppanas;
end;


// =============================================================================
         procedure Tarfolyamtablakijelzes.VX2MouseMove(Sender: TObject;
                                           Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin

  if not _maymove then exit;
  if not _mayshk then exit;

  _aktCella := TPanel(sender);
  if (_aktCella.Cursor<>crHandPoint) then
    begin
      Cellaregeneracio;
      exit;
    end;

  if not _cellChange  then GetcellaColor;

  _cellaNev := uppercase(_aktCella.name);
  GetTablasorOszlop(_cellanev);

  _hptop := _cellarow - 80;
  _hpleft := 740;

  Hintpanel.Top     := _hpTop;
  Hintpanel.Left    := _hpLeft;
  HintPanel.Visible := true;

end;


// =============================================================================
      procedure Tarfolyamtablakijelzes.VX2MouseDown(Sender: TObject;
                     Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  if not _maymove then exit;
  if not _mayshk then exit;

  HintPanel.Visible := False;

  _aktCella := Tpanel(Sender);
  if _aktCella.cursor<>crHandPoint then exit;
  if Button<>mbleft then exit;

  _maymove := False;

  _cellanev := _aktcella.name;
  GetTablaSorOszlop(_cellanev);
  Shkcuppanas;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

// ----------------------------- BECUPPANÁSOK ----------------------------------


// =============================================================================
                 procedure TarfolyamTablaKijelzes.Becuppanas;
// =============================================================================

begin
  _index := _cellasor-1;
  if _cellaOszlopBetu='K' then
    begin
      if _cellaType='V' then _ujarfolyam := _k1vet[_index]
      else _ujarfolyam := _k1ela[_index];
    end else
    begin
      if _cellaType='V' then _ujarfolyam := _k2vet[_index]
      else _ujarfolyam := _k2ela[_index];
    end;
  _aktdnem := _dnem[_index];

  dNemPanel.Caption := _aktdnem;
  UjarfPanel.Caption := realform(_ujarfolyam);
  _ct := _cellarow -75;
  _cl := _cellacolumn-60;
  _ch := 35;
  _cw := 190;
  with cuppanel do
    begin
      width   := _cw;
      height  := _ch;
      top     := _ct;
      left    := _cl;
      Visible := True;
    end;
  Nyujto.Enabled := True;
end;

// =============================================================================
                 procedure TarfolyamTablaKijelzes.Shkcuppanas;
// =============================================================================


begin
  if _sajathataskoru>4 then
    begin
      showmessage('A MAI NAPON MÁR 5 SAJÁTHATÁSKÖRÜ BIZONYLAT VOLT. TÖBBRE NINCS LEHETÕSÉG');
      exit;
    end;

   _index := _cellasor-1;
   _aktdnem := _dnem[_index];
   if _cellatype='E' then
      begin
        _igarfolyam := _earf[_index];
        _tolarfolyam:= _shke[_index];
      end else
      begin
        _tolarfolyam := _varf[_index];
        _igarfolyam  := _shkv[_index];
      end;

  Dnem2Panel.Caption := _aktdnem;
  TolarfPanel.Caption := realform(_tolarfolyam);
  IgArfPanel.Caption := realform(_igarfolyam);
  if (_vTipus='V') or ((_VTIPUS='K') and (_elojel='+'))  then
      Ujarfedit.Text := floattostr(_igarfolyam) else
      Ujarfedit.Text := floattostr(_tolarfolyam);


  _ch := 65;
  _cw := 190;
  _ct := _cellarow-80;
  if _ct>520 then _ct := 520;
  with cuppaneL2 do
    begin
      width := _cw;
      height := _ch;
      top    := _ct;
      left   := 460;
      Visible := True;
    end;
  Nyujto2.Enabled := True;
end;


end.
