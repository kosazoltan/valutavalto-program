unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, IBDatabase, DB, IBCustomDataSet,strutils,
  IBQuery, Buttons, jpeg;

type
  TForm2 = class(TForm)
    Panel1: TPanel;
    DN1: TPanel;
    DV1: TPanel;
    DB1: TPanel;
    DA1: TPanel;
    DE1: TPanel;
    DN2: TPanel;
    DN3: TPanel;
    DN4: TPanel;
    DN5: TPanel;
    DN6: TPanel;
    DN7: TPanel;
    DN9: TPanel;
    DN10: TPanel;
    DN11: TPanel;
    DN12: TPanel;
    DN8: TPanel;
    DN13: TPanel;
    DN14: TPanel;
    DN15: TPanel;
    DN16: TPanel;
    DN17: TPanel;
    DN18: TPanel;
    DV2: TPanel;
    DV3: TPanel;
    DV4: TPanel;
    DV6: TPanel;
    DV7: TPanel;
    DV9: TPanel;
    DV10: TPanel;
    DV12: TPanel;
    DV13: TPanel;
    DV15: TPanel;
    DV16: TPanel;
    DV18: TPanel;
    DB2: TPanel;
    DB3: TPanel;
    DB4: TPanel;
    DB6: TPanel;
    DB7: TPanel;
    DB9: TPanel;
    DB10: TPanel;
    DB12: TPanel;
    DB13: TPanel;
    DB15: TPanel;
    DB16: TPanel;
    DB18: TPanel;
    DA2: TPanel;
    DA3: TPanel;
    DA4: TPanel;
    DA6: TPanel;
    DA7: TPanel;
    DA9: TPanel;
    DA10: TPanel;
    DA12: TPanel;
    DA13: TPanel;
    DA15: TPanel;
    DA16: TPanel;
    DA18: TPanel;
    DE2: TPanel;
    DE3: TPanel;
    DE4: TPanel;
    DE6: TPanel;
    DE7: TPanel;
    DE9: TPanel;
    DE10: TPanel;
    DE12: TPanel;
    DE13: TPanel;
    DE15: TPanel;
    DE16: TPanel;
    DE18: TPanel;
    DV5: TPanel;
    DB5: TPanel;
    DA5: TPanel;
    DE5: TPanel;
    DV8: TPanel;
    DB8: TPanel;
    DA8: TPanel;
    DE8: TPanel;
    DV11: TPanel;
    DB11: TPanel;
    DA11: TPanel;
    DE11: TPanel;
    DV14: TPanel;
    DB14: TPanel;
    DA14: TPanel;
    DE14: TPanel;
    DV17: TPanel;
    DB17: TPanel;
    DA17: TPanel;
    DE17: TPanel;
    DN19: TPanel;
    DN20: TPanel;
    DN21: TPanel;
    DN22: TPanel;
    DN23: TPanel;
    DN24: TPanel;
    DN25: TPanel;
    DV19: TPanel;
    DV20: TPanel;
    DV23: TPanel;
    DV24: TPanel;
    DV25: TPanel;
    DV22: TPanel;
    DV21: TPanel;
    DB19: TPanel;
    DB20: TPanel;
    DB21: TPanel;
    DB22: TPanel;
    DB23: TPanel;
    DB25: TPanel;
    DB24: TPanel;
    DA19: TPanel;
    DA20: TPanel;
    DE19: TPanel;
    DE20: TPanel;
    DE23: TPanel;
    DE22: TPanel;
    DE24: TPanel;
    DE25: TPanel;
    DA25: TPanel;
    DA23: TPanel;
    DA22: TPanel;
    DA24: TPanel;
    DE21: TPanel;
    DA21: TPanel;
    DNHIDEEDIT: TEdit;
    DBHIDEEDIT: TEdit;
    DAHIDEEDIT: TEdit;
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    DT1: TPanel;
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
    DT2: TPanel;
    DT3: TPanel;
    DT4: TPanel;
    DT5: TPanel;
    DT6: TPanel;
    DT7: TPanel;
    DT9: TPanel;
    DT8: TPanel;
    DT10: TPanel;
    DT11: TPanel;
    DT12: TPanel;
    DT13: TPanel;
    DT14: TPanel;
    DT15: TPanel;
    DT16: TPanel;
    DT17: TPanel;
    DT19: TPanel;
    DT18: TPanel;
    DT20: TPanel;
    DT21: TPanel;
    DT22: TPanel;
    DT23: TPanel;
    DT24: TPanel;
    DT25: TPanel;
    DTHIDEEDIT: TEdit;
    CI1: TCheckBox;
    CI2: TCheckBox;
    CI3: TCheckBox;
    CI4: TCheckBox;
    CI5: TCheckBox;
    CI6: TCheckBox;
    CI7: TCheckBox;
    CI8: TCheckBox;
    CI9: TCheckBox;
    CI10: TCheckBox;
    CI11: TCheckBox;
    CI12: TCheckBox;
    CI13: TCheckBox;
    CI14: TCheckBox;
    CI15: TCheckBox;
    CI16: TCheckBox;
    CI17: TCheckBox;
    CI18: TCheckBox;
    CI19: TCheckBox;
    CI20: TCheckBox;
    CI21: TCheckBox;
    CI22: TCheckBox;
    CI23: TCheckBox;
    CI24: TCheckBox;
    CI25: TCheckBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    ENDGOMB: TBitBtn;
    QUITGOMB: TBitBtn;
    EREDMENYPANEL: TPanel;
    RCIMPANEL: TPanel;
    DARABPANEL: TPanel;
    ERTEKPANEL: TPanel;
    TRANZOKEGOMB: TBitBtn;
    TRANZMEGSEMGOMB: TBitBtn;
    Shape1: TShape;
    Image1: TImage;
    ARFCHANGEBOX: TCheckBox;
    BOXTAKARO: TPanel;
    FOCIMPANEL: TPanel;


    procedure AdatNullazas;
    procedure FormActivate(Sender: TObject);
    procedure TombeToltes;
    procedure PanelClear;
    procedure PanelsWhiting;
    procedure DN1Click(Sender: TObject);
    procedure DNHIDEEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    function ScanDnem(_d: string): byte;
    procedure ValutaAdatokBetoltese;
    procedure ErtekKijelzes;
    procedure DB1Click(Sender: TObject);
    function Realtostr(_r: real): string;
    procedure DBHIDEEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
   function Ftform(_ft: integer): string;
    procedure DA1Click(Sender: TObject);
    procedure DAHIDEEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure DT1Click(Sender: TObject);
    procedure DTHIDEEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CI1Click(Sender: TObject);
    procedure NextCurrency;
    procedure PrevCurrency;
    function GetCimletezettBankjegy: integer;
    procedure Vparancs(_ukaz: string);
    procedure NewCurrency;
    procedure QUITGOMBClick(Sender: TObject);
    procedure ENDGOMBClick(Sender: TObject);
    procedure TRANZOKEGOMBClick(Sender: TObject);
    function kerekito(_int: integer): integer;
    procedure ARFCHANGEBOXClick(Sender: TObject);



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY','CZK',
         'DKK','EUR','GBP','HRK','HUF','ILS','JPY','MXN','NOK','NZD','PLN','RON',
         'RSD','RUB','SEK','THB','TRY','UAH','USD');

 _dnev: array[1..27] of string = ('AUSZTRAL DOLLAR','BOSNYAK MARKA','BOLGAR LEVA',
         'BRAZIL REAL','KANADAI DOLLAR','SVAJCI FRANK','KINAI JUAN','CSEH KORONA',
         'DAN KORONA','EURO','ANGOL FONT','HORVAT KUNA','MAGYAR FORINT','IZRAELI SHAKEL',
         'JAPAN JEN','MEXIKOI PESO','NORVEG KORONA','UJZELANDI DOLLAR',
         'LENGYEL ZLOTY','ROMAN LEI','SZERB DINAR','OROSZ RUBEL','SVED KORONA',
         'THAI BATH','TOROK LIRA','UKRAN HRIVNYA','USA DOLLAR');

 
  _elszarf: array[1..30] of integer;

  _dn,_dv,_db,_da,_dt,_de: array[1..25] of TPanel;
  _ci: array[1..25] of TCheckBox;

  _dnstr,_dbstr,_dastr,_dtstr,_destr: array[1..25] of string;

  _valnem  : array[1..25] of string;
  _bankjegy: array[1..25] of integer;
  _alaparf : array[1..25] of integer;
  _elszi   : array[1..25] of integer;
  _tortresz: array[1..25] of string;
  _realarf : array[1..25] of real;
  _ertek   : array[1..25] of integer;
  _cimlet  : array[1..25] of byte;

  _aktalaparf : integer;
  _aktbankjegy: integer;
  _aktelszarf : integer;

  _akttortresz: string;
  _aktrealarf : real;
  _aktertek   : integer;
  _aktcimlet  : byte;
  _aktarf     : integer;
  _sumertek   : integer;


  _aktPanel,_ujPanel: Tpanel;
  _aktbox     : TCheckBox;
  _aktstring  : string;
  _ptkod      : string;

  _code: integer;
  _pcs,_aktdnem,_aktdnev,_reals,_dType: string;
  _sorveg: string = chr(13)+chr(10);

  _height,_width,_top,_left: word;
  _pos,_seldb,_navig: byte;
  _arfolyamtilt : boolean;

  _pss,_bill,_xx,_dnemdb,_w1,_f1,_vancimlet: byte;
  _cimlista: string ='c:\ERTEKTAR\cimlprnt.txt';

function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\ertektar\bin\super.dll' name 'supervisorjelszo';
function kcimletrutin(_para: byte): integer; stdcall; external 'c:\ertektar\bin\kcimlet.dll'
                                  name 'kcimletrutin';

function keszleteditalorutin(_para: byte): integer; stdcall;

implementation

{$R *.dfm}


function keszleteditalorutin(_para: byte): integer; stdcall;
begin
  form2 := TForm2.Create(Nil);
  _navig := _para;
  result := Form2.ShowModal;
  Form2.Free;
end;



procedure TForm2.FormActivate(Sender: TObject);

VAR _PT: byte;
    _ptnev,_tipus,_rag,_focim: string;

begin
  _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  _top    := trunc((_height-768)/2);
  _left   := trunc((_width-1024)/2);

  Top     := _top;
  Left    := _left;
  Height  := 768;
  Width   := 1024;

  ArfChangeBox.Checked := False;
  _arfolyamtilt := True;
  EredmenyPanel.Visible := False;

  TombeToltes;
  Panelclear;
  ValutaAdatokBetoltese;
  _pcs := 'DELETE FROM CIMLETPISZKOZAT';
  VParancs(_pcs);

  vDbase.connected := true;
  with VQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _ptkod := trim(FieldByName('PENZTARKOD').asstring);
      _ptnev := trim(FieldByName('TARSPENZTARNEV').AsString);
      _tipus := FieldByName('TIPUS').asString;
      Close;
    end;
  Vdbase.close;

  _pt := ord(_ptkod[1]);
  _arfolyamtilt := True;

  _focim := 'PÉNZÁTVÉTEL ';
  _rag := '-TOL';
  if _tipus='F' then
    begin
      _focim := 'PÉNZÁTADÁS ';
      _rag := '-NAK';
    end;
  _focim := _focim + _ptnev + _rag;
  FocimPanel.Caption := _focim;
  FocimPanel.Repaint;

  BoxTakaro.visible := False;

  if (_pt>64) then
    begin
      _arfolyamtilt := False;
      Boxtakaro.visible := true;
    end;

  if Fileexists(_cimlista) then sysutils.DeleteFile(_cimlista);
  AdatNullazas;

  dn1.Enabled := true;
  dn1click(DN1);
end;


procedure TForm2.AdatNullazas;

var i: byte;

begin
  _sumertek := 0;
  _seldb    := 0;
  _dType    := '';
  for i := 1 to 25 do
    begin
      _valnem[i] := '';
      _alaparf[i] := 0;
      _bankjegy[i] := 0;
      _ertek[i] := 0;
      _tortresz[i] := '';
      _cimlet[i] := 0;
      _realarf[i] := 0.00;

      _dnstr[i] := '';
      _dbstr[i] := '';
      _dastr[i] := '';
      _dtstr[i] := '';
      _destr[i] := '';

    end;
end;
// =============================================================================
                  procedure TForm2.DN1Click(Sender: TObject);
// =============================================================================

// Az elsö oszlop (VALUTANEM) lesz aktiv

begin
  _aktpanel := TPanel(sender);
  _pss      := _aktpanel.tag;
  PanelsWhiting;
  _aktpanel.color := clYellow;

  // Valutanem üres string:

  _aktstring      := '';

  dnHideEdit.text := '';
  Activecontrol   := dnHideEdit;
end;



// =============================================================================
     procedure TForm2.DNHIDEEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

// itt kell bekérni a valuta nemet

var _z: byte;

begin
  _bill := ord(key);

  // Egy angol nagybetüt nyomott le:

  if (_bill>64) and (_bill<91) then
    begin
      _aktstring := _aktstring + chr(_bill);   // Hozzáirjuk az eddigi stringhez

      // Még nincs beirva a valutanem minden betüje - várom a további betü(ke)t:
      if length(_aktstring)<3 then
        begin
          _dn[_pss].Caption := _aktstring;  // Kiirom a képernyöre
          exit;
        end else

        // A beirt string 3 betüböl áll:

        begin

          _xx := scanDnem(_aktstring);    // Van ilyen valuta ?

          if _xx=0 then    //  Nincs !!
            begin
              _dn[_pss].caption := '';
              _aktPanel := _dn[_pss];
              dn1click(_aktpanel);
              exit;
            end;
        end;

      _dn[_pss].caption := _aktstring;
      if _seldb>1 then
        begin
          _z := 1;
          while _z<=_seldb do
            begin
              if _aktstring=_valnem[_z] then
                begin
                  ShowMessage(_aktstring+' MÁR BE VAN IRVA !');
                  _aktPanel := _DN[_pss];
                  _aktpanel.Caption := '';
                  Dn1click(_aktpanel);
                  exit;
                end;
              inc(_z);
            end;
         end;

      if (_aktstring='HUF') and (_dType='DEV') then
        begin
          _dn[_pss].caption := '';
          exit;
        end;

      if (_pss=1) AND (_dType='') then
        begin
          if _aktstring='HUF' then _dType := 'FT'
          else _dType := 'DEV';
        end;

      _dn[_pss].Caption := _aktstring;  // beirjuk a beirt valutát
      _valnem[_pss]     := _aktstring;
      _dn[_pss].Enabled := False;       // ide más már nem irható

      _dv[_pss].caption := _dnev[_xx];  //  a nevet is beirja a köv. oszlopba:

      _aktalaparf  := _elszarf[_xx];   // Az alaparfolyam = elszámolási arfolyam
      _alaparf[_pss] := _aktalaparf;
      _elszi[_pss] := _aktalaparf;
      _akttortresz := '';
      _aktrealarf  := _aktalaparf*1;
      _realarf[_pss] := _aktrealarf;

      _da[_pss].caption := inttostr(_aktalaparf);
      _dastr[_pss] := inttostr(_aktalaparf);
      _dt[_pss].Caption := '';
      _ci[_pss].Visible := true;
      _aktcimlet  := 0;

      // A bankjegypanel,alaparfolyam és tortreszpanel aktiv:

      _db[_pss].Enabled := True;
      _da[_pss].Enabled := True;
      _dt[_pss].Enabled := True;

      inc(_seldb);

      _aktpanel := _db[_pss];
      db1click(_aktPanel);
      exit;
    end;

  if _bill=38 then
    begin
      PrevCurrency;
      exit;
    end;

   If _bill=35 then
     begin
       EndgombClick(Nil);
       exit;
     end;

end;

// =============================================================================
                 procedure TForm2.DB1Click(Sender: TObject);
// =============================================================================

begin
  _aktpanel := TPanel(sender);
  _pss      := _aktpanel.tag;

  PanelsWhiting;
  _aktpanel.color := clYellow;
  _aktrealarf     := _realarf[_pss];
  _aktstring      := _dbStr[_pss];

  DbHideedit.Text := _aktstring;
  Activecontrol   := DbHideedit;
end;

// =============================================================================
      procedure TForm2.DBHIDEEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

// itt kérjuk be a bankjegyeket:

begin
  _bill := ord(Key);

  // Numpad számait normálra konvertálja:
  if (_bill>95) and (_bill<106) then _bill := _bill-48;

  // Számjegyet ütött  be:
  if (_bill>47) and (_bill<58) then
    begin
      _aktstring   := _aktstring + chr(_bill);
      _dbstr[_pss] := _aktstring;

      val(_aktstring,_aktbankjegy,_code);
      if _code<>0 then _aktbankjegy := 0;
      _bankjegy[_pss]   := _aktbankjegy;
      _db[_pss].caption := FtForm(_aktbankjegy);

      ErtekKijelzes;
      exit;
    end;

  // Backspace gombot nyomott:

  if (_bill=8) then
    begin
      _w1 := length(_aktstring);
      if _w1=0 then exit;

      if _w1=1 then _aktstring := ''
      else _aktstring := leftstr(_aktstring,_w1-1);

      _dbstr[_pss] := _aktstring;

      val(_aktstring,_aktbankjegy,_code);
      if _code<>0 then _aktbankjegy := 0;
      _bankjegy[_pss]   := _aktbankjegy;
      _db[_pss].caption := FtForm(_aktbankjegy);

      ErtekKijelzes;
      exit;
    end;

  // Jobbra lép az árfolyamra:

  if _bill=39 then
    begin
      _aktpanel := _da[_pss];
      da1Click(_aktpanel);
      exit;
    end;

   // felfele lép ha a darab már ki van töltva:
   if (_bill=38) and (_ertek[_pss]>0) then
    begin
      PrevCurrency;
      exit;
    end;

   // enter - jöhet a következõ valuta:
  if (_bill=13) AND (_ertek[_pss]>0) then
    begin
      if (_pss=25) or (_dtype='FT') then
        begin
          Activecontrol := EndGomb;
          exit;
        end;
      NewCurrency;
      exit;
    end;

  if (_bill=40) and (_ertek[_pss]>0) then
    begin
      nextCurrency;
      exit;
    end;

   If _bill=35 then
     begin
       EndgombClick(Nil);
       exit;
     end;

end;

// =============================================================================
               procedure TForm2.DA1Click(Sender: TObject);
// =============================================================================

begin
  if _arfolyamtilt then exit;

  _aktpanel := TPanel(sender);
  _pss      := _aktpanel.tag;

  PanelsWhiting;
  _aktpanel.color := clYellow;

  _aktbankjegy := _bankjegy[_pss];
  _aktstring   := _daStr[_pss];

  _aktalaparf  := _alaparf[_pss];
  _akttortresz := _tortresz[_pss];

  DaHideEdit.Text := _aktstring;
  Activecontrol   := DaHideedit;

end;

// =============================================================================
       procedure TForm2.DAHIDEEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================


begin
   _bill := ord(key);

   // Numpad számai normálra konvertálva:
   if (_bill>95) and (_bill<106) then _bill := _bill-48;

   // számjegyet ütött:
   if (_bill>47) and (_bill<58) then
     begin
       if length(_aktstring)>4 then exit;
       _aktstring        := _aktstring + chr(_bill);
       _dastr[_pss]      := _aktstring;

       _da[_pss].Caption := _aktstring;

       val(_aktstring,_aktalaparf,_code);
       if _code<>0 then _aktalaparf := 0;
       _alaparf[_pss] := _aktalaparf;

       _reals := _aktstring;
       if _akttortresz<>'' then _reals := _reals+','+_akttortresz;

       _aktrealarf    := strtofloat(_reals);
       _realarf[_pss] := _aktrealarf;

       _aktbankjegy := _bankjegy[_pss];
       Ertekkijelzes;
       exit;
     end;

   if _bill=8 then
     begin
       _w1 := length(_aktstring);
       if _w1=0 then exit;
       if _w1=1 then _aktstring := ''
       else _aktstring := leftstr(_aktstring,_w1-1);

       _dastr[_pss]      := _aktstring;
       _da[_pss].Caption := _aktstring;

       val(_aktstring,_aktalaparf,_code);
       if _code<>0 then _aktalaparf := 0;
       _alaparf[_pss] := _aktalaparf;

       _reals := _aktstring;
       if _reals='' then _reals := '0';
       if _akttortresz<>'' then _reals := _reals+','+_akttortresz;

       _aktrealarf    := strtofloat(_reals);
       _realarf[_pss] := _aktrealarf;

       _aktbankjegy := _bankjegy[_pss];
       Ertekkijelzes;
       exit;
     end;

   // Vesszö - pont vagy jobbra billentyü:
   if (_bill=46) or (_bill=44) or (_bill=190) or (_bill=110) or (_bill=39) then
     begin
       _aktPanel := _dt[_pss];
       dt1Click(_aktpanel);
       exit;
     end;


    // Visszalép a bankjegyre:
   if _bill=37 then
     begin
       _aktpanel := _db[_pss];
       if not _aktpanel.Enabled then exit;
       db1Click(_aktpanel);
       exit;
     end;

   if _bill=38 then
    begin
      if _pss=1 then exit;
      _ujPanel := _da[_pss-1];
      da1Click(_ujpanel);
      exit;
    end;

  if (_bill=13) then
     begin
       NewCurrency;
       exit;
     end;

   if (_bill=40)  then
    begin
      if (_pss=25) or (_dtype='FT') then
        begin
          Activecontrol := EndGomb;
          exit;
        end;
      _ujpanel := _da[_pss+1];
      da1Click(_ujpanel);
      exit;
    end;

   If _bill=35 then
     begin
       EndgombClick(Nil);
       exit;
     end;

end;

// =============================================================================
                 procedure TForm2.DT1Click(Sender: TObject);
// =============================================================================

begin
  if _arfolyamtilt then exit;
  
  _aktpanel := Tpanel(sender);
  _pss      := _aktpanel.tag;

  PanelsWhiting;
  _aktpanel.color := clYellow;

  _aktbankjegy := _bankjegy[_pss];
  _aktalaparf  := _alaparf[_pss];
  _aktstring   := _dtstr[_pss];

  dtHideedit.Text := _aktstring;
  ActiveControl := dtHideedit;
end;

// =============================================================================
       procedure TForm2.DTHIDEEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  _bill := ord(key);

  if (_bill>95) and (_bill<106) then _bill := _bill-48;

  if (_bill>47) and (_bill<58) then
    begin
      if length(_aktstring)>3 then exit;
      
      _aktstring        := _aktstring + chr(_bill);
      _dtstr[_pss]      := _aktstring;
      _dt[_pss].caption := _aktstring;
      _tortresz[_pss]   := _aktstring;

      _reals            := _dastr[_pss];
      if _aktstring<>'' then _reals := _reals + ',' + _aktstring;
      _aktrealarf       := strtofloat(_reals);
      _realarf[_pss] := _aktrealarf;
      ErtekKijelzes;
      exit;
    end;

  if _bill=8 then
     begin
       _w1 := length(_aktstring);
       if _w1=0 then exit;
       if _w1=1 then _aktstring := ''
       else _aktstring := leftstr(_aktstring,_w1-1);
        _dtstr[_pss]      := _aktstring;
      _dt[_pss].caption := _aktstring;
      _tortresz[_pss]   := _aktstring;

      _reals            := _dastr[_pss];
      if _aktstring<>'' then _reals := _reals + ',' + _aktstring;
      _aktrealarf       := strtofloat(_reals);
      _realarf[_pss] := _aktrealarf;
      ErtekKijelzes;
      exit;
    end;

  if (_bill=13) and (_ertek[_pss]>0) then
    begin
      if (_pss=25) or (_dtype='FT') then
        begin
          Activecontrol := EndGomb;
          exit;
        end;
      NewCurrency;
      exit;
    end;

  if (_bill=40) and (_ertek[_pss+1]>0) then
    begin
      _ujpanel := _dt[_pss+1];
      Dt1Click(_ujpanel);
      exit;
    end;

  if _bill=37 then
    begin
      _ujpanel := _da[_pss];
      da1Click(_ujpanel);
      exit;
    end;

  if _bill=38 then
    begin
      if _pss=1 then exit;
      _ujPanel := _dt[_pss-1];
      dt1Click(_ujpanel);
      exit;
    end;

   If _bill=35 then
     begin
       EndgombClick(Nil);
       exit;
     end;

end;

// =============================================================================
                        procedure TForm2.ErtekKijelzes;
// =============================================================================

begin
  _aktertek := round(_aktrealarf/100*_aktbankjegy);
//  _aktertek := kerekito(_aktertek);
  _ertek[_pss] := _aktErtek;
  _destr[_pss] := inttostr(_aktertek);
  _de[_pss].Caption := ftform(_aktertek);
end;




procedure TForm2.PanelClear;

var _y: byte;

begin
  _y := 1;
  while _y<=25 do
    begin
      _dn[_y].Caption := '';

      _db[_y].Caption := '';
      _da[_y].Caption := '';
      _de[_y].Caption := '';
      _dt[_y].Caption := '';
      _ci[_y].checked := False;

      _dn[_y].enabled := false;
      _db[_y].enabled := false;
      _da[_y].enabled := false;
      _dt[_y].Enabled := False;
      _ci[_y].Visible := False;

      _dnstr[_y] := '';
      _dbstr[_y] := '';
      _dastr[_y] := '';
      _destr[_y] := '';
      _dtstr[_y] := '';

      _bankjegy[_y] := 0;
      _tortresz[_y] := '';
      _cimlet[_y]   := 0;

      inc(_y);
    end;
end;




procedure TForm2.TombeToltes;

begin
  _dn[1] := DN1;
  _dn[2] := DN2;
  _dn[3] := DN3;
  _dn[4] := DN4;
  _dn[5] := DN5;
  _dn[6] := DN6;
  _dn[7] := DN7;
  _dn[8] := DN8;
  _dn[9] := DN9;
  _dn[10]:= DN10;
  _dn[11]:= DN11;
  _dn[12]:= DN12;
  _dn[13]:= DN13;
  _dn[14]:= DN14;
  _dn[15]:= DN15;
  _dn[16]:= DN16;
  _dn[17]:= DN17;
  _dn[18]:= DN18;
  _dn[19]:= DN19;
  _dn[20]:= DN20;
  _dn[21]:= DN21;
  _dn[22]:= DN22;
  _dn[23]:= DN23;
  _dn[24]:= DN24;
  _dn[25]:= DN25;

  _dv[1] := DV1;
  _dv[2] := DV2;
  _dv[3] := DV3;
  _dv[4] := DV4;
  _dv[5] := DV5;
  _dv[6] := DV6;
  _dv[7] := DV7;
  _dv[8] := DV8;
  _dv[9] := DV9;
  _dv[10]:= DV10;
  _dv[11]:= DV11;
  _dv[12]:= DV12;
  _dv[13]:= DV13;
  _dv[14]:= DV14;
  _dv[15]:= DV15;
  _dv[16]:= DV16;
  _dv[17]:= DV17;
  _dv[18]:= DV18;
  _dv[19]:= DV19;
  _dv[20]:= DV20;
  _dv[21]:= DV21;
  _dv[22]:= DV22;
  _dv[23]:= DV23;
  _dv[24]:= DV24;
  _dv[25]:= DV25;

  _db[1] := DB1;
  _db[2] := DB2;
  _db[3] := DB3;
  _db[4] := DB4;
  _db[5] := DB5;
  _db[6] := DB6;
  _db[7] := DB7;
  _db[8] := DB8;
  _db[9] := DB9;
  _db[10]:= DB10;
  _db[11]:= DB11;
  _db[12]:= DB12;
  _db[13]:= DB13;
  _db[14]:= DB14;
  _db[15]:= DB15;
  _db[16]:= DB16;
  _db[17]:= DB17;
  _db[18]:= DB18;
  _db[19]:= DB19;
  _db[20]:= DB20;
  _db[21]:= DB21;
  _db[22]:= DB22;
  _db[23]:= DB23;
  _db[24]:= DB24;
  _db[25]:= DB25;

  _da[1] := DA1;
  _da[2] := DA2;
  _da[3] := DA3;
  _da[4] := DA4;
  _da[5] := DA5;
  _da[6] := DA6;
  _da[7] := DA7;
  _da[8] := DA8;
  _da[9] := DA9;
  _da[10]:= DA10;
  _da[11]:= DA11;
  _da[12]:= DA12;
  _da[13]:= DA13;
  _da[14]:= DA14;
  _da[15]:= DA15;
  _da[16]:= DA16;
  _da[17]:= DA17;
  _da[18]:= DA18;
  _da[19]:= DA19;
  _da[20]:= DA20;
  _da[21]:= DA21;
  _da[22]:= DA22;
  _da[23]:= DA23;
  _da[24]:= DA24;
  _da[25]:= DA25;

  _dt[1] := DT1;
  _dt[2] := DT2;
  _dt[3] := DT3;
  _dt[4] := DT4;
  _dt[5] := DT5;
  _dt[6] := DT6;
  _dt[7] := DT7;
  _dt[8] := DT8;
  _dt[9] := DT9;
  _dt[10]:= DT10;
  _dt[11]:= DT11;
  _dt[12]:= DT12;
  _dt[13]:= DT13;
  _dt[14]:= DT14;
  _dt[15]:= DT15;
  _dt[16]:= DT16;
  _dt[17]:= DT17;
  _dt[18]:= DT18;
  _dt[19]:= DT19;
  _dt[20]:= DT20;
  _dt[21]:= DT21;
  _dt[22]:= DT22;
  _dt[23]:= DT23;
  _dt[24]:= DT24;
  _dt[25]:= DT25;


  _de[1] := DE1;
  _de[2] := DE2;
  _de[3] := DE3;
  _de[4] := DE4;
  _de[5] := DE5;
  _de[6] := DE6;
  _de[7] := DE7;
  _de[8] := DE8;
  _de[9] := DE9;
  _de[10]:= DE10;
  _de[11]:= DE11;
  _de[12]:= DE12;
  _de[13]:= DE13;
  _de[14]:= DE14;
  _de[15]:= DE15;
  _de[16]:= DE16;
  _de[17]:= DE17;
  _de[18]:= DE18;
  _de[19]:= DE19;
  _de[20]:= DE20;
  _de[21]:= DE21;
  _de[22]:= DE22;
  _de[23]:= DE23;
  _de[24]:= DE24;
  _de[25]:= DE25;

  _ci[1] := CI1;
  _ci[2] := CI2;
  _ci[3] := CI3;
  _ci[4] := CI4;
  _ci[5] := CI5;
  _ci[6] := CI6;
  _ci[7] := CI7;
  _ci[8] := CI8;
  _ci[9] := CI9;
  _ci[10]:= CI10;
  _ci[11]:= CI11;
  _ci[12]:= CI12;
  _ci[13]:= CI13;
  _ci[14]:= CI14;
  _ci[15]:= CI15;
  _ci[16]:= CI16;
  _ci[17]:= CI17;
  _ci[18]:= CI18;
  _ci[19]:= CI19;
  _ci[20]:= CI20;
  _ci[21]:= CI21;
  _ci[22]:= CI22;
  _ci[23]:= CI23;
  _ci[24]:= CI24;
  _ci[25]:= CI25;

end;




procedure Tform2.PanelsWhiting;

var i: byte;

begin
  for i := 1 to 25 do
    begin
      _dn[i].Color := clWhite;
      _db[i].color := clWhite;
      _da[i].Color := clWhite;
      _dt[i].Color := clWhite;
    end;
end;


function TForm2.ScanDnem(_d: string): byte;

var _z: byte;

begin
  result := 0;
  _z := 1;
  while _z<=27 do
    begin
      if _dnem[_z]=_d then
        begin
          result := _z;
          exit;
        end;
      inc(_z);
    end;
end;


procedure TForm2.ValutaAdatokBetoltese;

begin
  _pcs := 'SELECT * FROM ARFOLYAM' + _SORVEG;
  _pcs := _pcs + 'WHERE VALUTANEM<>'+chr(39)+'EUA'+chr(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  _dnemdb := 0;
  vdbase.connected := true;
  with VQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not vquery.Eof do
    begin
      _aktdnem := Vquery.FieldByNAme('VALUTANEM').asstring;
      _aktalaparf := Vquery.FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;

      inc(_dnemdb);

      _xx := scandnem(_aktdnem);
      _elszarf[_xx] := trunc(_aktalaparf);
      Vquery.next;
    end;
  Vquery.close;
  Vdbase.close;
end;


function TForm2.Realtostr(_r: real): string;

var _pos: byte;

begin
  _w1:= 0;
  result := floattostr(_r);
  _pos := pos(',',result);
  if _pos>0 then
      result := leftstr(result,_pos-1)+'.'+midstr(result,_pos+1,_w1-_pos);

end;


function TForm2.Ftform(_ft: integer): string;

begin
  result := '';
  if _ft=0 then exit;

  result := inttostr(_ft);
  _w1 := length(result);

  if _w1<4 then exit;

  if _w1>6 then
    begin
      _f1 := _w1-6;
      result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3)+' '+midstr(result,_f1+4,3);
      exit;

    end;

  _f1 := _w1-3;
  result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3);
end;


procedure TForm2.CI1Click(Sender: TObject);
begin
  _aktBox := TCheckBox(sender);
  _pss := _aktbox.Tag;
  _aktdnem := _valnem[_pss];
  _xx := scandnem(_aktdnem);
  _vancimlet := kcimletrutin(_xx);
  if _vancimlet=2 then
    begin
      _aktpanel := _db[_pss];
      db1click(_aktpanel);
      exit;
    end;
  _cimlet[_pss] := 1;
  _aktbankjegy := GetCimletezettBankjegy;

  _aktbox.checked := true;
  _aktbox.Enabled := False;
  _db[_pss].Caption := Ftform(_aktbankjegy);
  _db[_pss].Enabled := False;
  _bankjegy[_pss] := _aktbankjegy;
  _dbstr[_pss] := inttostr(_aktbankjegy);
  _aktrealarf := _realarf[_pss];

  ErtekKijelzes;

  NextCurrency;

end;

function TForm2.GetCimletezettBankjegy: integer;

begin
  _pcs := 'SELECT * FROM CIMLETPISZKOZAT WHERE VALUTANEM='+chr(39)+_aktdnem+chr(39);
  Vdbase.connected := true;
  with vquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
      result := FieldByNAme('BANKJEGY').asInteger;
      Close;
    end;
  Vdbase.close;
end;


procedure TForm2.PrevCurrency;

begin
  if _pss=1 then exit;
  if _db[_pss-1].Enabled then
    begin
      _aktpanel := _db[_pss-1];
      db1Click(_aktpanel);
      exit;
    end;

  _aktpanel := _da[_pss-1];
  da1Click(_aktpanel);
end;

procedure TForm2.Vparancs(_ukaz: string);

begin
  Vdbase.Connected := true;
  if vtranz.InTransaction then vtranz.Commit;
  vtranz.StartTransaction;
  with vquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  vtranz.Commit;
  vdbase.close;
end;


procedure TForm2.NewCurrency;

begin
  if _pss=25 then
    begin
      Activecontrol := Endgomb;
      exit;
    end;

  if _valnem[_pss+1]='' then
    begin
      _ujPanel := _dn[_pss+1];
      dn1Click(_ujPanel);
      exit;
    end;

  NextCurrency;
end;


procedure TForm2.NextCurrency;

begin
  if (_dType='FT') OR (_pss=25) then
    begin
      Activecontrol := endgomb;
      exit;
    end;

  if _valnem[_pss+1]='' then
    begin
      _aktpanel := _dN[_pss+1];
      dN1Click(_aktpanel);
      exit;
    end;

  _ujpanel := _db[_pss+1];
  if _ujpanel.Enabled then db1click(_ujpanel)
  else
  begin
    _ujpanel := _da[_pss+1];
    da1Click(_ujpanel);
    exit;
  end;
end;


procedure TForm2.QUITGOMBClick(Sender: TObject);
begin
  Modalresult := 2;
end;

procedure TForm2.ENDGOMBClick(Sender: TObject);

var _y : byte;
    _szalliranytext: string;

begin
  _y := 1;
  _sumertek := 0;
  while _y<=_seldb do
    begin
      _aktdnem     := _valnem[_y];
      _aktarf      := _alaparf[_y];
      _aktbankjegy := _bankjegy[_y];
      _aktertek    := _ertek[_y];
      _aktelszarf  := _elszi[_y];
      _akttortresz := _tortresz[_y];
      _aktcimlet   := _cimlet[_y];
      _xx := scandnem(_aktdnem);

      _sumertek := _sumertek + _aktertek;

      if _aktcimlet=0 then
        begin
          _pcs := 'INSERT INTO CIMLETPISZKOZAT (VALUTANEM,BANKJEGY,';
          _pcs := _pcs + 'ARFOLYAM,ELSZAMOLASIARFOLYAM,TORTRESZ)'+ _sorveg;
          _pcs := _pcs + 'VALUES (' + chr(39) + _aktdnem + chr(39) + ',';

          _pcs := _pcs + inttostr(_aktbankjegy) + ',';
          _pcs := _pcs + inttostr(_aktarf) + ',';
          _PCS := _pcs + inttostr(_aktelszarf) + ',';
          _pcs := _pcs + chr(39) + _akttortresz + chr(39) + ')';
        end else
        begin
          _pcs := 'UPDATE CIMLETPISZKOZAT SET ARFOLYAM='+inttostr(_aktarf);
          _pcs := _pcs + ',ELSZAMOLASIARFOLYAM=' + inttostr(_aktelszarf);
          _pcs := _pcs + ',TORTRESZ=' + chr(39) + _akttortresz + chr(39);
          _pcs := _pcs + ',BANKJEGY=' + inttostr(_aktbankjegy)+_sorveg;
          _pcs := _pcs + 'WHERE VALUTANEM='+chr(39)+_aktdnem+chr(39);
        end;

      VParancs(_pcs);
      inc(_y);
    end;

  _szalliranytext := 'ELSZÁLLITÁSA';
  if _navig=1 then _szalliranytext := 'ÁTVÉTELE';

  Rcimpanel.Caption := 'PÉNZEK ' +_szalliranytext;
  Rcimpanel.Repaint;

  DarabPanel.caption := inttostr(_seldb)+' VALUTA';
  DarabPanel.repaint;

  ertekPanel.caption := ftform(_sumertek)+ ' Ft értékben';
  Ertekpanel.repaint;

  with eredmenyPanel do
    begin
      Top := 200;
      left := 230;
      Visible := true;
    end;
  Activecontrol := TranzOkeGomb;

end;

procedure TForm2.TRANZOKEGOMBClick(Sender: TObject);
begin
  Modalresult := 1;
end;


// =============================================================================
           function TForm2.kerekito(_int: integer): integer;
// =============================================================================

var _nums: string;
    _utdig,_wnums: Byte;

begin
  result := _int;
  _nums := inttostr(_int);
  _wnums := length(_nums);
  _utdig := ord(_nums[_wnums])-48;
  if (_utdig<>0) and (_utdig<>5) then
    begin
      if (_utdig=1) or (_utdig=2) then result := _int-_utdig;
      if (_utdig=6) or (_utdig=7) then result := _int-(_utdig-5);
      if (_utdig=3) or (_utdig=4) then result := _int+(5-_utdig);
      if (_utdig=8) or (_utdig=9) then result := _int+10-_utdig;
    end;
end;




procedure TForm2.ARFCHANGEBOXClick(Sender: TObject);

var _spk: integer;

begin
  if arfChangeBox.Checked then
    begin
       _spk := supervisorjelszo(0);
       if _spk=1 then _arfolyamtilt := False
       else ArfchangeBox.Checked := False;
    end else
    begin
       ArfChangebox.Checked := False;
       _arfolyamtilt := True;
    end;

  Dn1click(DN1);
end;

end.

