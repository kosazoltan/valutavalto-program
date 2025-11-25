unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, strutils, idglobal,
  IBDatabase, DB, IBCustomDataSet, IBQuery;

type
  TSZUNETKIJELZO = class(TForm)
    TIPUSCOMBO: TComboBox;
    TOLORACOMBO: TComboBox;
    TOLPERCCOMBO: TComboBox;
    IGORACOMBO: TComboBox;
    IGPERCCOMBO: TComboBox;
    SZUNETGOMB: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    Shape1: TShape;
    Label1: TLabel;
    VALQUERY: TIBQuery;
    VALDBASE: TIBDatabase;
    VALTRANZ: TIBTransaction;

    procedure FormActivate(Sender: TObject);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure SZUNETGOMBClick(Sender: TObject);
    procedure Getadatok;

    function Nulele(_num: byte): string;
    procedure TOLORACOMBOChange(Sender: TObject);
    procedure valutaParancs(_ukaz: string);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SZUNETKIJELZO: TSZUNETKIJELZO;
  _height,_width,_top,_left: word;
  _mess: array[0..1] of string = ('Technikai szünet','Ebédszünet');
  _aktora,_ora,_perc,_toloraindex,_igoraindex,_tolpercindex: byte;
  _igpercIndex,_tipusIndex: byte;
  _sorveg: string = chr(13)+chr(10);
  _idos,_oras,_pcs,_megnyitottnap,_aktpenztarosnev: string;
  _tempPath : string = 'c:\valuta\temp.txt';
  _messPath : string = 'c:\valuta\mess.txt';


function szunetkijelzorutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
                 function szunetkijelzorutin: integer; stdcall;
// =============================================================================

begin
  szunetkijelzo := TSzunetkijelzo.Create(Nil);
  result := szunetkijelzo.showmodal;
  szunetkijelzo.free;
end;


// Szünetet szeretne kijelezni a pénztáros:

// =============================================================================
           procedure TSZUNETKIJELZO.FormActivate(Sender: TObject);
// =============================================================================

var i: integer;

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;
  _top    := trunc((_height-270)/2);
  _left   := trunc((_width-540)/2);

  Top  := _top;
  Left := _left;

  GetAdatok;

  TipusCombo.Items.clear;
  TolOracombo.Items.Clear;
  TolPercCombo.Items.clear;
  IgOracombo.Items.Clear;
  IgPercCombo.Items.clear;

  i := 0;
  while i<=1 do
    begin
      tipuscombo.Items.add(_mess[i]);
      inc(i);
    end;

  TipusCombo.ItemIndex := 0;

  _idos := timetostr(Now);
  if midstr(_idos,2,1)=':' then _idos := '0' + _idos;

  _aktora := strtoint(leftstr(_idos,2));
  _ora := _aktora;

  while _ora<24 do
    begin
      _oras := Nulele(_ora);
      Toloracombo.Items.Add(_oras +' óra');
      IgOraCombo.Items.Add(_oras +' óra');
      inc(_ora);
    end;
  Toloracombo.ItemIndex := 0;
  IgoraCombo.ItemIndex := 0;

  _perc := 0;
  while _perc<=55 do
    begin
      TolpercCombo.Items.Add(nulele(_perc)+' perctõl');
      IgPercCombo.Items.Add(nulele(_perc)+' percig');
      _perc := _perc + 5;
    end;

  TolpercCombo.ItemIndex := 0;
  IgpercCombo.ItemIndex := 0;

  ActiveControl := MegsemGomb;

end;

// =============================================================================
          procedure TSZUNETKIJELZO.MEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 2;
end;

// =============================================================================
                 procedure TSZUNETKIJELZO.SZUNETGOMBClick(Sender: TObject);
// =============================================================================

var _txtiro: Textfile;
    _tolstring,_igstring,_megnevezes: string;
    _tolos,_tolps,_igos,_igps: string;

begin
  _tolOraIndex := TolOraCombo.itemindex;
  _igOraIndex := IgOraCombo.itemindex;
  _tolPercIndex := TolPercCombo.ItemIndex;
  _igPercIndex := IgpercCombo.ItemIndex;
  _tipusIndex := TipusCombo.itemindex;

  if (_tolOraIndex=_igoraIndex) and (_tolpercindex>=_igpercindex) then
    begin
      Showmessage('Az idõbeállítás érvénytelen');
      Activecontrol := IgPercCombo;
      Exit;
    end;

  // -------------------- Itt jó a beállitás ----------------------------------

  _tolos := ToloraCombo.items[_toloraindex];
  _tolps := TolpercCombo.Items[_tolpercIndex];

  _igos  := IgoraCombo.Items[_igoraindex];
  _igps  := IgPercCombo.Items[_igPercIndex];

  _tolstring := leftstr(_tolos,2)+':'+leftstr(_tolps,2);
  _igstring  := leftstr(_igos,2)+':'+leftstr(_igps,2);

  Assignfile(_txtiro,_messPath);
  rewrite(_txtiro);

  writeln(_txtiro,inttostr(_tipusindex));
  writeLn(_txtiro,_tolstring);
  writeLn(_txtiro,_igstring);
  closefile(_txtiro);

  _megnevezes := _mess[_tipusindex];

  _pcs := 'INSERT INTO PAUSES (DATUM,TOL,IG,MEGNEVEZES,PENZTAROSNEV,MESSNUM)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39)+ ',';
  _pcs := _pcs + chr(39) + _tolstring + chr(39) + ',';
  _pcs := _pcs + chr(39) + _igstring + chr(39) + ',';
  _pcs := _pcs + chr(39) + trim(_megnevezes) + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktpenztarosnev + chr(39) + ',';
  _pcs := _pcs + inttostr(_tipusindex) + ')';

  ValutaParancs(_pcs);
  Modalresult := 1;
end;

// =============================================================================
            function TSzunetKijelzo.Nulele(_num: byte): string;
// =============================================================================

begin
  result := inttostr(_num);
  if _num<10 then result := '0' + result;
end;

// =============================================================================
           procedure TSZUNETKIJELZO.TOLORACOMBOChange(Sender: TObject);
// =============================================================================

begin
  Activecontrol := Szunetgomb;
end;


procedure TSzunetKijelzo.valutaParancs(_ukaz: string);

begin
  valdbase.connected := true;
  if valtranz.InTransaction then valtranz.commit;
  valtranz.StartTransaction;
  with ValQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  Valtranz.commit;
  Valdbase.close;
end;

procedure TSzunetKijelzo.Getadatok;

begin
  valdbase.connected := true;
  with Valquery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap := FieldByNAme('MEGNYITOTTNAP').asString;
      _aktpenztarosnev := trim(FieldByNAme('PENZTAROSNEV').asString);
      Close;
    end;
  Valdbase.close;

end;




end.
