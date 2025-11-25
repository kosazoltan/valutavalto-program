unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ComCtrls, ExtCtrls, DateUtils, DB,
  DBTables, strUtils, IBDatabase, IBCustomDataSet, IBTable, IBQuery;

type
  TREGIZARASFORM = class(TForm)
    ALAPPANEL: TPanel;
    EVCOMBO: TComboBox;
    HOCOMBO: TComboBox;
    NAPCOMBO: TComboBox;
    Label1: TLabel;
    NAPNEVEDIT: TEdit;
    STARTGOMB: TBitBtn;
    ESCAPEGOMB: TBitBtn;
    Shape1: TShape;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    valutatranz: TIBTransaction;

    procedure ESCAPEGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure EVCOMBOChange(Sender: TObject);
    procedure NAPCOMBOChange(Sender: TObject);
    procedure DatumAllito;
    procedure STARTGOMBClick(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);
 
 
    function Nulele(_b: byte): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  REGIZARASFORM: TREGIZARASFORM;

  _honapnev: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS',
                'MÁJUS','JÚNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
                'NOVEMBER','DECEMBER');

  _napnev: array[1..7] of string = ('HÉTFÕ','KEDD','SZERDA','CSÜTÖRTÖK','PÉNTEK',
                                    'SZOMBAT','VASÁRNAP');

  _KERTdATUM : TDateTime;
  _zDatums,_pcs: string;
  _sorveg: string = chr(13)+chr(10);

  _top,_left,_height,_width,_mostev,_mostho,_mostnap,_hnap,_utnap: word;
  _kertnap,_kertho,_kertev: word;

function napzarnyomtatorutin: integer; stdcall; external 'c:\ertektar\bin\nznyomt.dll'
                                        name 'napzarnyomtatorutin';

function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\ertektar\bin\super.dll' name 'supervisorjelszo';                                        

function regizarasrutin: integer; stdcall;

implementation

{$R *.dfm}

function regizarasrutin: integer; stdcall;
begin
  regizarasform := TregizarasForm.Create(Nil);
  result := regizarasform.showmodal;
  regizarasform.free;
end;


// =============================================================================
       procedure TREGIZARASFORM.FormActivate(Sender: TObject);
// =============================================================================

var i: integer;
begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top := round((_height-768)/2);
  _left := round((_width-1024)/2);

  Top    := _top+240;
  Left   := _left+365;
  Height := 219;
  Width  := 619;

  _mostev  := yearof(now);
  _mostho  := monthof(now);
  _mostnap := dayof(now);
  _hnap    := dayoftheweek(now);

  Evcombo.Clear;
  Hocombo.Clear;
  Napcombo.clear;
  Napnevedit.clear;

  for i  := -2 to 0 do Evcombo.Items.add(inttostr(_mostev+i));
  for i  := 1 to 12 do Hocombo.Items.Add(_honapnev[i]);
  _utnap := daysinamonth(_mostev,_mostho);
  for i  := 1 to _utnap do NapCombo.Items.add(Inttostr(i));

  Evcombo.ItemIndex  := 2;
  Hocombo.ItemIndex  := _mostho-1;
  Napcombo.ItemIndex := _mostnap-1;
  Napnevedit.Text    := _napnev[_hnap];
  _kertDatum         := Date;
  StartGomb.Enabled  := True;
  EscapeGomb.Enabled := true;
  ActiveControl := StartGomb;
end;


procedure TREGIZARASFORM.ValutaParancs(_ukaz: string);

begin
  Valutadbase.connected := true;
  if valutatranz.InTransaction then valutatranz.Commit;
  Valutatranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  ValutaTranz.Commit;
  Valutadbase.close;
end;


// =============================================================================
       procedure TREGIZARASFORM.ESCAPEGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 2;
end;

// =============================================================================
           procedure TREGIZARASFORM.EVCOMBOChange(Sender: TObject);
// =============================================================================

begin
  _kertnap := 1;
  DatumAllito;
end;

// =============================================================================
      procedure TREGIZARASFORM.NAPCOMBOChange(Sender: TObject);
// =============================================================================

begin
  _Kertnap := 1 + Napcombo.ItemIndex;
  Datumallito;
end;

// =============================================================================
                     procedure TRegizarasForm.DAtumAllito;
// =============================================================================

var
     i: integer;
begin
   _kertev   := _mostev-2+evcombo.ItemIndex;
  _kertho    := 1+hocombo.ItemIndex;
  _kertDatum := EncodeDate(_kertev,_kertho,_kertnap);
  _hnap      := dayoftheweek(_kertdatum);
  _utnap     := daysinamonth(_kertev,_kertho);
  Napcombo.Clear;

  for i := 1 to _utnap do NapCombo.Items.add(Inttostr(i));
  Napcombo.ItemIndex := _kertnap-1;
  Napnevedit.Text    := _napnev[_hnap];
  ActiveControl      := StartGomb;
end;

// =============================================================================
           procedure TREGIZARASFORM.STARTGOMBClick(Sender: TObject);
// =============================================================================

VAR _spk: integer;

begin
  StartGomb.Enabled  := False;
  EscapeGomb.Enabled := False;
  _spk := supervisorjelszo(0);
  if _spk=1 then
    begin
      _zDatums := inttostr(_kertev)+'.'+nulele(_kertho)+'.'+nulele(_kertnap);
      _pcs := 'DELETE FROM VTEMP';
      ValutaParancs(_pcs);

      _pcs := 'INSERT INTO VTEMP (DATUM)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _zDatums + chr(39) + ')';
      ValutaParancs(_pcs);
      napzarnyomtatorutin;
    end;

  ModalResult := 1;
end;



function TRegizarasForm.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


end.
