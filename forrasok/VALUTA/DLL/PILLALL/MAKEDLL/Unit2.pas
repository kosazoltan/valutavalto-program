unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Grids, DBGrids, DB, StrUtils, IBDatabase,
  IBCustomDataSet, IBTable, ExtCtrls, IBQuery, printers;

type

  TPillanatnyiForm = class(TForm)

    PillanatnyiSource: TDataSource;
          KeszletRacs: TDBGrid;

    Label1: TLabel;
    ARFOLYAMDBASE: TIBDatabase;
    ARFOLYAMTRANZ: TIBTransaction;
    ARFOLYAMQUERY: TIBQuery;
    Shape1: TShape;
    Shape2: TShape;
    ARFOLYAMQUERYVALUTANEM: TIBStringField;
    ARFOLYAMQUERYVALUTANEV: TIBStringField;
    ARFOLYAMQUERYVETELIARFOLYAM: TFloatField;
    ARFOLYAMQUERYELADASIARFOLYAM: TFloatField;
    ARFOLYAMQUERYELSZAMOLASIARFOLYAM: TFloatField;
    ARFOLYAMQUERYMODOSITOSZAZALEK: TFloatField;
    ARFOLYAMQUERYNYITO: TIntegerField;
    ARFOLYAMQUERYBEVETEL: TIntegerField;
    ARFOLYAMQUERYKIADAS: TIntegerField;
    ARFOLYAMQUERYZARO: TIntegerField;
    ARFOLYAMQUERYK1VETEL: TFloatField;
    ARFOLYAMQUERYK2VETEL: TFloatField;
    ARFOLYAMQUERYK1ELADAS: TFloatField;
    ARFOLYAMQUERYK2ELADAS: TFloatField;
    ARFOLYAMQUERYSHKVETARFOLYAM: TFloatField;
    ARFOLYAMQUERYSHKELADARFOLYAM: TFloatField;
    ARFOLYAMQUERYKEZELESIDIJ: TIntegerField;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    NYOMTATOGOMB: TPanel;
    kezdikprintgomb: TPanel;
    escapegomb: TPanel;
    Panel1: TPanel;
    Label2: TLabel;
    BANKKARTYAPANEL: TPanel;
    BANKKARTYATAKARO: TPanel;
    Label3: TLabel;
    BKKTSGPANEL: TPanel;
    Label4: TLabel;

    procedure EscapeGombClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure NyomtatoGombClick(Sender: TObject);
    procedure AlapadatBeolvasas;
    function Getidos: string;
    procedure PillNyomtatas;
    procedure FormActivate(Sender: TObject);
    procedure KEZDIJPRINTGOMBClick(Sender: TObject);
    procedure Blokkfocimiro;
    function Elokieg(_szo: string;_hh: integer):string;
    function FormKiir(_in: integer):string;
    procedure TextKiiro;
    function ForintForm(_osszeg:integer):string;
    procedure KozepreIr(_szoveg: string);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PillanatnyiForm: TPillanatnyiForm;
  _bk,_bkktsg: integer;
  _top,_left,_height,_width: word;

  _pcs,_aktidos,_aktdnem,_megnyitottnap,_kftnev,_cegnev: string;
  _sorveg: string = chr(13)+chr(10);

  _nyito,_bevetel,_kiadas,_zaro,_egyenleg,_code: integer;
  _homePenztarkod,_homePenztarnev,_homePenztarcim: string;

  _postterm,_printer,_homePenztarszam: byte;

  _LFile: Textfile;

function regeneralorutin(_para: integer): integer; stdcall; external 'c:\valuta\bin\regen.dll' name 'regeneralorutin';
function pillallasrutin: integer; stdcall;


implementation
{$R *.dfm}

function pillallasrutin: integer; stdcall;
begin
  Pillanatnyiform := TPillanatnyiForm.Create(Nil);
  result := Pillanatnyiform.Showmodal;
  PillanatnyiForm.free;
end;


// =============================================================================
            procedure TPillanatnyiForm.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  _top    := round((_height-768)/2);
  _left   := round((_width-1024)/2);
  Top     := _top;
  Left    := _left;
  Width   := 1024;
  Height  := 768;
  
  KeyPreview := True;
  BankkartyaTakaro.Visible := True;

  AlapAdatBeolvasas;

  if _postterm=1 then
    begin
      BankkartyaPanel.Caption := inttostr(_bk)+' Ft';
      BkktsgPanel.Caption := inttostr(_bkktsg)+ ' Ft';
      BankkartyaPanel.Repaint;
      BkktsgPanel.Repaint;
      BankkartyaTakaro.visible := false;
    end;

  arfolyamdbase.Close;
  arfolyamdbase.Connected := True;
  if ArfolyamTranz.InTransaction then ArfolyamTranz.commit;
  _pcs := 'SELECT * FROM ARFOLYAM' + _sorveg;
  _pcs := _pcs + 'WHERE ZARO<>0' +_sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  with ArfolyamQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;
  ActiveControl := KeszletRacs;
end;

// =============================================================================
         procedure TPILLANATNYIFORM.ESCAPEGOMBClick(Sender: TObject);
// =============================================================================

begin
  ArfolyamQuery.close;
  ArfolyamDbase.close;
  ModalResult := 1;
end;

// =============================================================================
                    procedure TPillanatnyiForm.PillNyomtatas;
// =============================================================================

begin
  _aktidos := GetIdos;
  BlokkFoCimIro;
  writeLn(_Lfile,_megnyitottnap+' '+leftStr(_aktidos,5)+' perci penztar allas:');
  writeLN(_LFile,dupestring('-',40));
  writeLn(_LFile,'Val.   Nyito     Forgalom      Penztar');
  writeLn(_LFile,'nem   osszeg     egyenlege      allas');
  writeLN(_LFile,dupestring('-',40));

  arfolyamdbase.Close;
  arfolyamdbase.Connected := true;
  _pcs := 'SELECT * FROM ARFOLYAM' + _SORVEG;
  _pcs := _pcs + 'WHERE ZARO<>0' + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  with ArfolyamQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  while not ArfolyamQuery.Eof do
    begin
      with ArfolyamQuery do
        begin
          _aktdnem := FieldByNAme('VALUTANEM').AsString;
            _nyito := FieldByName('NYITO').AsInteger;
          _bevetel := FieldByName('BEVETEL').asInteger;
           _kiadas := FieldByName('KIADAS').AsInteger;
             _zaro := FieldByName('ZARO').AsInteger;
        end;

      _egyenleg := _bevetel-_kiadas;

      if (_zaro<>0) or (_nyito<>0) or (_egyenleg<>0) then
        begin
          write(_LFile,_aktdnem+' '+FormKiir(_nyito)+' ');
          writeLn(_LFile,FormKiir(_egyenleg)+' '+FormKiir(_zaro));
        end;

      ArfolyamQuery.Next;
    end;

  writeLN(_LFile,dupestring('-',40));
  writeLn(_LFile,_sorveg+_sorveg+_sorveg);
  Closefile(_LFile);
  TextKiiro;
end;

// =============================================================================
          procedure TPillanatnyiForm.NyomtatoGombClick(Sender: TObject);
// =============================================================================

begin
  Pillnyomtatas;
end;

function TPillanatnyiForm.Getidos: string;

begin
  result := timetostr(Time);
  if midstr(result,2,1)=':' then result := '0' + result;
end;


// =============================================================================
     procedure TPillanatnyiForm.FormKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)= 119 then PillNyomtatas;
  if ord(key)= 13 then EscapegombClick(NIL);
end;


// =============================================================================
              procedure TPillanatnyiForm.FormCreate(Sender: TObject);
// =============================================================================

begin
   Top := _top;
   Left := _left;
   Width := 1024;
   Height := 768;
end;

procedure TPillanatnyiForm.KEZDIJPRINTGOMBClick(Sender: TObject);

var _kdnyito,_kdkezdij,_kdatvet,_kdatadas,_kdzaro: integer;

begin
  regeneralorutin(0);

  _pcs := 'SELECT * FROM NAPIKEZELESIDIJ' + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+ chr(39) + _megnyitottnap + CHR(39);

  Valutadbase.Connected := true;
  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      _kdnyito := FieldByName('NYITO').asInteger;
      _kdkezdij:= FieldByName('KEZELESIDIJ').asInteger;
      _kdatvet := FieldByName('KEZELESIDIJATVETEL').asInteger;
      _kdatadas:= FieldbyName('KEZELESIDIJATADAS').asInteger;
      _kdZaro  := FieldByName('ZARO').asInteger;
      Close;
    end;
  Valutadbase.close;

  // ---------------------------------------------------------------------------

  _aktidos := GetIdos;
  BlokkFoCimIro;
  writeLn(_Lfile,_megnyitottnap+' '+leftStr(_aktidos,5)+'-i kez-i dij egyenlege:');
  writeLN(_LFile,dupestring('-',40));
  write(_LFile,'Napi nyito kez-i dij ..:  ');
  writeLn(_LFile,FormKiir(_kdnyito)+' Ft');

  write(_LFile,'A mai napon beszedve ..:  ');
  writeLn(_LFile,FormKiir(_kdkezdij)+' Ft');

  write(_LFile,'Kezelesi dij atvetel ..:  ');
  writeLn(_LFile,FormKiir(_kdatvet)+' Ft');

  write(_LFile,'Kezelesi dij atadasa ..:  ');
  writeLn(_LFile,FormKiir(_kdatadas)+' Ft');

  write(_LFile,'Pillanatnyi zaro osszeg:  ');
  writeLn(_LFile,FormKiir(_kdzaro)+' Ft');
  writeLN(_LFile,dupestring('-',40));

  writeLN(_LFile,dupestring('-',40));
  writeLn(_LFile,_sorveg+_sorveg+_sorveg);
  Closefile(_LFile);
  TextKiiro;
end;

procedure TPillanatnyiForm.AlapadatBeolvasas;

begin
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap := FieldByNAme('MEGNYITOTTNAP').asString;
      _printer := FieldByName('PRINTER').asInteger;
      _kftnev := trim(FieldByNAme('KFTNEV').AsString);
      _postterm:= FieldByNAme('POSTTERM').asInteger;
      _bk := Fieldbyname('BANKKARTYA').asInteger;
      _bkktsg := Fieldbyname('BKKOLTSEG').asInteger;

      Close;
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _homepenztarkod := trim(FieldByNAme('PENZTARKOD').asString);
      _homePenztarnev := trim(FieldByNAme('PENZTARNEV').asString);
      _homePenztarCim := trim(FieldByNAme('PENZTARCIM').asString);
      Close;
    end;
  Valutadbase.close;

  val(_homepenztarkod,_homepenztarszam,_code);
  if _homepenztarszam<151 then
    begin
      _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';
    end else
    begin
      _cegnev := 'EXPRESSZ EKSZERHAZ ES MINIBANK KFT';
    end;
end;

procedure  TPillanatnyiForm.Blokkfocimiro;

begin
  Assignfile(_LFile,'c:\valuta\aktlst.txt');
  rewrite(_LFile);
  Kozepreir(_cegnev);
  Kozepreir(_homePenztarkod+' '+_homepenztarnev);
  Kozepreir(_homepenztarcim);
  writeLN(_LFile,dupestring('-',40));
end;


// =============================================================================
                  function TPillanatnyiForm.FormKiir(_in: integer):string;
// =============================================================================
begin
  Result := ForintForm(_in);
  Result := EloKieg(Result,11);
end;


// =============================================================================
         procedure TPillanatnyiForm.KozepreIr(_szoveg: string);
// =============================================================================

var _oo: integer;

begin
  _szoveg := trim(_szoveg);
  _oo := trunc((40-length(_szoveg))/2);
  writeLn(_LFile,dupestring(' ',_oo)+_szoveg);
end;




// =============================================================================
           function TPillanatnyiForm.Elokieg(_szo: string;_hh: integer):string;
// =============================================================================

begin
  if length(_szo)>=_hh then
    begin
      Result := leftStr(_szo,_hh);
      exit;
    end;

  while length(_szo)<_hh do _szo := ' '+_szo;

  Result := _szo;
end;




// =============================================================================
             function TPillanatnyiForm.ForintForm(_osszeg:integer):string;
// =============================================================================

var _slen,_pp: integer;
    _ejel : string;

begin
  Result := '-';

  if _osszeg=0 then exit;

  _ejel := '';

  if _osszeg<0 then
    begin
      _ejel := '-';
      _osszeg := abs(_osszeg);
    end;

  Result := intTostr(_osszeg);

  if _osszeg<1000 then
    begin
      Result := _ejel + Result;
      Exit;
    end;

  _sLen := length(Result);
  if _osszeg>999999 then
    begin
      _pp := _sLen-5;
      Result := _ejel + midStr(Result,1,_pp-1)+','+midStr(Result,_pp,3)+','+midStr(Result,_pp+3,3);
      Exit;
    end;

  _pp := _sLen-2;
  Result := _ejel + midStr(result,1,_pp-1)+','+midStr(result,_pp,3);

end;

// =============================================================================
                            procedure TPillanatnyiForm.TextKiiro;
// =============================================================================

var _mondat: string;
    _nyomtat,_olvas: textFile;

begin

  if _printer<>1 then AssignFile(_nyomtat,'LPT1')
  else AssignPrn(_nyomtat);
  Rewrite(_nyomtat);
  AssignFile(_olvas,'c:\valuta\aktlst.txt');
  Reset(_olvas);

  while not eof(_olvas) do
    begin
      readln(_olvas,_mondat);
      writeln(_nyomtat,_mondat);
    end;
  System.closeFile(_nyomtat);
  System.CloseFile(_olvas);
end;




end.
