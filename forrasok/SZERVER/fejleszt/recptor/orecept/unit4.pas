unit Unit4;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, unit1, IBDatabase, DB, IBCustomDataSet, IBQuery,
  StdCtrls, ComCtrls;

type
  TPERSONALBEDOLGOZAS = class(TForm)
    KILEPOTIMER: TTimer;
    Label1: TLabel;
    PERSONQUERY: TIBQuery;
    PERSONDBASE: TIBDatabase;
    PERSONTRANZ: TIBTransaction;
    CSIK: TProgressBar;
    CIMPANEL: TPanel;
    procedure FormActivate(Sender: TObject);
    procedure KILEPOTIMERTimer(Sender: TObject);
    procedure Adatlapdekoder;
    procedure Csomagdekoder;
    procedure Ugyfeldekoder;
    procedure PersonParancs(_ukaz: string);
    function GetUgyfelnev(_ugysz: integer;_ugytip: string):string;

    function Getbyte: byte;
    function Getword: word;
    function GetText: string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PERSONALBEDOLGOZAS: TPERSONALBEDOLGOZAS;
  _ugyfeldarab,_ugyfelszam,_adatlapdarab,_csomagdarab: integer;
  _ugyfeltipus,_elozonev,_anyjaneve,_leanykori,_szulhely,_szulido: string;
  _allampolg,_lakcim,_okmanytip,_azonosito,_tarthely,_lcimCard: string;
  _telefon,_telephely,_okiratszam,_fotevek,_kepvisnev,_mbSzama: string;
  _mbbeo,_osszfts,_korulmeny,_egyeb,_ptrosnev,_bjegys,_forints: string;
  _csomagszam,_sorszam,_osszesforint,_code,_bankjegy,_forint,_cc: integer;

implementation

{$R *.dfm}


procedure TPERSONALBEDOLGOZAS.FormActivate(Sender: TObject);
begin
  Top  := 180;
  Left := 400;

  PersonalBedolgozas.Repaint;
  while true do
    begin
      case _tablajelzo of
        255: break;
        101: ugyfeldekoder;
        102: adatlapdekoder;
        103: csomagdekoder;
      end;
    end;
  Kilepotimer.Enabled := true;
end;

procedure TPERSONALBEDOLGOZAS.KILEPOTIMERTimer(Sender: TObject);
begin
  Kilepotimer.Enabled := false;
  ModalResult := 1;
end;


procedure TPERSONALBEDOLGOZAS.UgyfelDekoder;

begin
  _ugyfelDarab := Getword;
  CimPanel.Caption := 'ÜGYFELEK';
  CimPanel.Repaint;
  Csik.Max := _ugyfeldarab;
  _cc := 0;
  while _ugyfelDarab>0 do
    begin
      inc(_cc);
      Csik.Position := _cc;
      _ugyfelszam := GetWord;
      _ugyfeltipus := chr(getByte);
      _ugyfelnev := getText;
      _elozonev  := getText;
      _anyjaneve := GetText;
      _leanykori := GetText;
      _szulhely  := GetText;
      _szulido   := GetText;
      _allampolg := GetText;
      _lakcim    := GetText;
      _okmanytip := GetText;
      _azonosito := GetText;
      _tarthely  := GetText;
      _lcimcard  := GetText;
      _telefon   := GetText;
      _telephely := GetText;
      _okiratszam:= GetText;
      _fotevek   := GetText;
      _kepvisnev := GetText;
      _mbSzama   := GetText;
      _mbbeo     := GetText;

      _pcs := 'INSERT INTO UGYFELEK (UGYFELTIPUS,IRODASZAM,UGYFELSZAM,NEV,ELOZONEV,';
      _pcs := _pcs + 'ANYJANEVE,LEANYKORI,SZULETESIHELY,ALLAMPOLGAR,LAKCIM,OKMANYTIPUS,';
      _pcs := _pcs + 'AZONOSITO,TARTOZKODASIHELY,LAKCIMKARTYA,TELEFONSZAM,TELEPHELYCIM,';
      _pcs := _pcs + 'OKIRATSZAM,FOTEVEKENYSEG,KEPVISELONEV,MEGBIZOTTBEOSZTASA,';
      _pcs := _pcs + 'MEGBIZOTTSZAMA,SZULETESIIDO)' + _sorveg;

      _pcs := _pcs + 'VALUES (' + chr(39) + _ugyfeltipus + chr(39) + ',';
      _pcs := _pcs + inttostr(_aktirodaszam) + ',';
      _pcs := _pcs + inttostr(_ugyfelszam) + ',';
      _pcs := _pcs + chr(39) + _ugyfelnev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _elozonev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _anyjaneve + chr(39) + ',';
      _pcs := _pcs + chr(39) + _leanykori + chr(39) + ',';
      _pcs := _pcs + chr(39) + _szulhely + chr(39) + ',';
      _pcs := _pcs + chr(39) + _allampolg + chr(39) + ',';
      _pcs := _pcs + chr(39) + _lakcim + chr(39) + ',';
      _pcs := _pcs + chr(39) + _okmanytip + chr(39) + ',';
      _pcs := _pcs + chr(39) + _azonosito + chr(39) + ',';
      _pcs := _pcs + chr(39) + _tarthely + chr(39) + ',';
      _pcs := _pcs + chr(39) + _lcimCard + chr(39) + ',';
      _pcs := _pcs + chr(39) + _telefon + chr(39) + ',';
      _pcs := _pcs + chr(39) + _telephely + chr(39) + ',';
      _pcs := _pcs + chr(39) + _okiratszam + chr(39) + ',';
      _pcs := _pcs + chr(39) + _fotevek + chr(39) + ',';
      _pcs := _pcs + chr(39) + _kepvisnev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _mbbeo + chr(39) + ',';
      _pcs := _pcs + chr(39) + _mbszama + chr(39) + ',';
      _pcs := _pcs + chr(39) + _szulido + chr(39) + ')';

      PersonParancs(_pcs);
      dec(_ugyfeldarab);
    end;
  _tablajelzo := getByte;
end;

procedure TPERSONALBEDOLGOZAS.AdatlapDekoder;

begin
  _adatlapDarab := Getword;
  CimPanel.Caption := 'ADATLAPOK';
  CimPanel.Repaint;
  Csik.Max := _adatlapdarab;
  _cc := 0;
  while _adatlapDarab>0 do
    begin
      inc(_cc);
      Csik.Position := _cc;
      _ugyfelszam := Getword;
      _ugyfeltipus := chr(getbyte);
      _csomagszam := getword;
      _sorszam := getword;
      _storno := getbyte;

      _datum := gettext;
      _ptrosnev := gettext;
      _korulmeny := Gettext;
      _egyeb := Gettext;
      _osszfts := gettext;
      val(_osszfts,_osszesforint,_code);
      if _code<>0 then _osszesforint := 0;

      _ugyfelnev := GetUgyfelnev(_ugyfelszam,_ugyfeltipus);

      _pcs := 'INSERT INTO ADATLAP (UGYFELSZAM,IRODASZAM,UGYFELNEV,SORSZAM,';
      _pcs := _pcs + 'GONGYCSOMAGSZAM,DATUM,PENZTAROSNEV,UGYFELTIPUS,KORULMENY,';
      _pcs := _pcs + 'EGYEB,OSSZESFORINT,STORNO)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + inttostr(_ugyfelszam) + ',';
      _pcs := _pcs + inttostr(_aktirodaszam) + ',';
      _pcs := _pcs + chr(39) + _ugyfelnev +  chr(39) + ',';
      _pcs := _pcs + inttostr(_sorszam) + ',';
      _pcs := _pcs + inttostr(_csomagszam)+ ',';
      _pcs := _pcs + chr(39) + _datum  + chr(39) + ',';
      _pcs := _pcs + chr(39) + _ptrosnev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _ugyfeltipus + chr(39) + ',';
      _pcs := _pcs + chr(39) + _korulmeny + chr(39) + ',';
      _pcs := _pcs + chr(39) + _egyeb + chr(39) + ',';
      _pcs := _pcs + inttostr(_osszesforint)+ ',';
      _pcs := _pcs + chr(48+_storno) + ')';

      PersonParancs(_pcs);
      dec(_adatlapDarab);
    end;
  _tablajelzo := GetByte;
end;

procedure TPERSONALBEDOLGOZAS.CsomagDekoder;

begin
  _csomagDarab := Getword;

  CimPanel.Caption := 'CSOMAGOK';
  CimPanel.Repaint;
  Csik.Max := _csomagdarab;
  _cc := 0;

  while _csomagDarab>0 do
    begin
      inc(_cc);
      Csik.Position := _cc;
      _ugyfelszam := Getword;
      _ugyfeltipus := chr(getbyte);
      _csomagszam := getword;
      _datum := GetText;
      _bizonylatszam := GetText;
      _valutanem := GetText;
      _bjegys := GetText;
      _forints := GetText;
      val(_bjegys,_bankjegy,_code);
      if _code<>0 then _bankjegy := 0;

      val(_forints,_forint,_code);
      if _code<>0 then _forint := 0;

      _pcs := 'INSERT INTO GONGYCSOMAG (IRODASZAM,UGYFELSZAM,DATUM,VALUTANEM,';
      _pcs := _pcs + 'BANKJEGY,FORINTERTEK,GONGYCSOMAGSZAM,BIZONYLATSZAM)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + INTTOSTR(_aktirodaszam) + ',';
      _pcs := _pcs + inttostr(_ugyfelszam) + ',';
      _pcs := _pcs + chr(39) + _datum + chr(39) + ',';
      _pcs := _pcs + chr(39) + _valutanem + chr(39) + ',';
      _pcs := _pcs + inttostr(_bankjegy) + ',';
      _pcs := _pcs + inttostr(_forint) + ',';
      _pcs := _pcs + inttostr(_csomagszam) + ',';
      _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ')';

      PersonParancs(_pcs);
      dec(_csomagdarab);
    end;
  _tablaJelzo := Getbyte;
end;

function TPersonalBedolgozas.GetByte: byte;

begin
  Blockread(_olvas,_bytetomb,1);
  result := _byteTomb[1];
end;

function TPersonalBedolgozas.GetWord: word;

var _lo,_hi: byte;

begin
  Blockread(_olvas,_bytetomb,2);
  _lo := _bytetomb[1];
  _hi := _bytetomb[2];
  result := _lo + trunc(256*_hi);
end;

function TPersonalBedolgozas.GetText: string;

var _len,_y,_kod,_dkod: integer;

begin
  result := '';
  Blockread(_olvas,_bytetomb,1);
  _len := _bytetomb[1];
  if _len=0 then exit;

  Blockread(_olvas,_bytetomb,_len);

  _y := 1;
  while _y<=_len do
    begin
      _kod := _bytetomb[_y];
      _dkod := 255-_kod;
      if (_dkod<>39) and (_dkod<>34) then
                  result := result + chr(255-_kod);
      inc(_y);
    end;
end;

procedure TPersonalBedolgozas.PersonParancs(_ukaz: string);

begin
  Persondbase.connected := true;
  if Persontranz.InTransaction then PersonTranz.commit;
  Persontranz.StartTransaction;
  with PersonQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_ukaz);
      ExecSql;
    end;
  PersonTranz.Commit;
  Persondbase.close;
end;


function TPersonalBedolgozas.GetUgyfelnev(_ugysz: integer;_ugytip: string):string;
begin
  _pcs := 'SELECT * FROM UGYFELEK' + _sorveg;
  _pcs := _pcs + 'WHERE (UGYFELSZAM='+INTTOSTR(_UGYSZ)+') AND (IRODASZAM=';
  _pcs := _pcs + inttostr(_aktirodaszam)+') AND (UGYFELTIPUS=';
  _pcs := _pcs + chr(39) + _ugytip + chr(39) + ')';

  result := '';

  Persondbase.Connected := true;
  with PersonQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno>0 then result := PersonQuery.FieldByNAme('NEV').asstring;

  PersonQuery.close;
  Persondbase.Close;
end;  

end.


