unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  IBTable, ExtCtrls, dateUtils, strUtils, TlHelp32;

type
  TForm1 = class(TForm)
    hobekeropanel: TPanel;
    EVCOMBO: TComboBox;
    HOCOMBO: TComboBox;
    HONAPOKEGOMB: TBitBtn;
    HONAPMEGSEMGOMB: TBitBtn;
    Label1: TLabel;
    Shape1: TShape;
    Shape2: TShape;
    Shape3: TShape;
    MUNKAPANEL: TPanel;
    KERTHOPANEL: TPanel;
    Memo1: TMemo;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    VQUERY: TIBQuery;
    VTABLA: TIBTable;
    VDBASE: TIBDatabase;
    vTRANZ: TIBTransaction;

    procedure IrodaBeolvasas;

    procedure FormActivate(Sender: TObject);
    procedure HONAPMEGSEMGOMBClick(Sender: TObject);
    procedure EVCOMBOChange(Sender: TObject);
    procedure HONAPOKEGOMBClick(Sender: TObject);

    procedure AdatGyujtes;
    procedure IrodaNullazas;
    procedure UresControl;
    procedure NyitoFix;
    procedure Belsofix;
    procedure ExcelKill;
    procedure Logiro(_mess: string);

    procedure WzarBedolgozas;
    procedure BfBedolgozas;
    procedure KezdBedolgozas;
    procedure EfejBedolgozas;

    function Nulele(_b: byte): string;
    function Getpenztarnev(_pt: byte): string;
    function ScanPenztar(_ptn: byte): byte;
    function ScanErtektar(_etn: byte): byte;
    function Urctrl(_p: byte): boolean;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1  : TForm1;

  _korzetnev: array[1..9] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT','DEBRECEN',
                      'NYÍREGYHÁZ','BÉKÉSCSABA','PÉCS','KAPOSVÁR','EXPRESSZ');

  _korzetszam: array[1..9] of byte = (10,20,40,50,63,75,120,145,180);

  _korzetirodadb: array[1..9] of byte;
  _korzetirodasor: array[1..9,1..20] of byte;

  _xUsdNyito,_xHufNyito,_xUsdBe,_xHufbe,_xUsdKi,_xHufKi: array[1..150,1..31] of integer;
  _xUsdZaro,_xHufZaro,_xAfanyito,_xAfaZaro: array[1..150,1..31] of integer;
  _xkdBevet,_xKdAtvet,_xKdBefiz: array[1..150,1..31] of integer;
  _xetradeNyito,_xMatrica,_xTelefon: array[1..150,1..31] of integer;
  _xEtradeAtadas,_xEtradeAtvetel,_xEtradeZaro: array[1..150,1..31] of integer;
  _xAfaBanktolbe,_xAfaVissza,_xAfakiadas: array[1..150,1..31] of integer;

  _penztarsor: array[1..150] of byte;
  _penztarnev: array[1..150] of string;
  _irkorzetszam: array[1..150] of byte;
  _urespenztar: array[1..150] of boolean;

  _honev: array[1..12] of string = ('JANUAR','FEBRUAR','MARCIUS','APRILIS','MAJUS',
                         'JUNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
                         'NOVEMBER','DECEMBER');

  _pcs,_farok,_sTablanev,_fdbPath,_aktTablaNev,_datum,_naps,_elojel: string;
  _aktPenztarnev,_datumelo: string;
  _sorveg: string = chr(13) + chr(10);

  _penztarszam,_ertektar,_ptIndex,_aktpenztarszam,_nap,_mozgas,_xx,_x,_kdb,_havinap: byte;
  _top,_left,_height,_width,_aktev,_aktho,_kertev,_kertho,_y,_irodadarab: word;
  _evindex,_hoIndex,_code,_kezdij: integer;
  _pnev,_mamas,_idos: string;
  _vanExcel,_LOOPER: boolean;

  _Lev,_Lho,_lnap: word;

  _logpath  : string = 'c:\receptor\mail\log\tablo.log';
  _iras     : textfile;


  _handle   : HWND;
  _proc     : PROCESSENTRY32;


implementation

uses Unit2;

{$R *.dfm}

procedure TForm1.IrodaNullazas;

begin
  _y := 1;
  while _y<=9 do
    begin
      _korzetirodaDb[_y] := 0;
      _x := 1;
      while _x<=20 do
        begin
          _korzetirodasor[_y,_x] := 0;
          inc(_x);
        end;
      inc(_y);
    end;
end;

// =============================================================================
            procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _Top := round((_height-430)/2);
  _left := round((_width-330)/2);

  Top  := _top;
  Left := _left;
  repaint;

  _Lev := yearof(date);
  _Lho := monthof(date);
  _lnap:= dayof(date);

  _mamas := inttostr(_lev)+'.'+nulele(_lho)+'.'+nulele(_LNap);

  AssignFile(_iras,_logPath);
  rewrite(_iras);

  _aktev := yearof(date);
  _aktho := monthof(date);

  evcombo.clear;
  evcombo.Items.clear;
  evcombo.Items.Add(inttostr(_aktev-1));
  evcombo.Items.Add(inttostr(_aktev));

  hocombo.Clear;
  Hocombo.Items.clear;
  _y := 1;
  while _y<=12 do
    begin
      Hocombo.Items.add(_honev[_y]);
      inc(_y);
    end;
  _evindex := 1;
  _hoindex := _aktho-2;

  if _hoindex<0 then
    begin
      _hoindex := 11;
      _evindex := 0;
    end;

  evcombo.ItemIndex := _evindex;
  Hocombo.ItemIndex := _hoIndex;

  with HobekeroPanel do
    begin
      top := 0;
      left := 0;
      Visible := true;
      repaint;
    end;

  Activecontrol := HonapOkeGomb;
end;

// =============================================================================
             procedure TForm1.EVCOMBOChange(Sender: TObject);
// =============================================================================


begin
  Activecontrol := HonapOkegomb;
end;

// =============================================================================
             procedure TForm1.HONAPOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _evindex := evcombo.itemindex;
  _hoIndex := hocombo.itemindex;
  if (_evindex=1) and ((1+_hoindex)>_aktho) then
    begin
      ShowMessage('HIBÁS A KÉRT HÓNAP');
      exit;
    end;
  _kertev := _aktev-1+_evindex;
  _kertho := 1+_hoindex;
  HobekeroPanel.Visible := False;

  logiro('Valasztott honap: '+inttostr(_kertev)+' '+inttostr(_kertho));

  // -----------------------------------

  KertHoPanel.Caption := inttostr(_kertev)+'  '+_honev[_kertho];
  KertHoPanel.Repaint;
  _farok := midstr(inttostr(_kertev),3,2)+nulele(_kertho);
  _sTablanev := 'HT' + _farok;

  _datumelo := inttostr(_kertev)+'.'+nulele(_kertho)+'.';
  _havinap := daysinamonth(_kertev,_kertho);

  with MunkaPanel do
    begin
      top := 0;
      left := 24;
      Visible := true;
      repaint;
    end;

  IrodaBeolvasas;
  AdatGyujtes;
  UresControl;
  NyitoFix;
  BelsoFix;

  ExcelKeszites.ShowModal;
  if _vanexcel then ExcelKill;
  closeFile(_iras);
  Application.terminate;
end;


procedure TForm1.adatgyujtes;

begin
  _ptIndex := 1;
  while _ptindex<=_irodaDarab do
    begin
      _aktpenztarszam := _penztarsor[_ptIndex];
      _fdbPath := 'c:\receptor\database\v'+inttostr(_aktpenztarszam)+'.FDB';

      _aktPenztarnev := GetPenztarnev(_aktpenztarszam);

      Logiro(_aktpenztarnev + ' adatainak bekérése');

      Memo1.Lines.add('===========================');
      Memo1.Lines.Add(_aktpenztarnev);

      // WZAR BEDOLGOZÁSA ================

      _aktTablaNev := 'WZAR' + _farok;

      vDbase.close;
      vDbase.dataBasename := _fdbPath;
      vdbase.connected    := True;

      vTabla.close;
      vTabla.TableName := _aktTablaNev;
      if vTabla.exists then WzarBedolgozas;

      // BF BEDOLGOZÁSA (KEZDIJ BESZEDÉS)=====================

      _aktTablaNev := 'BF' + _farok;

      vdbase.connected := True;

      vTabla.close;
      vTabla.TableName := _aktTablaNev;
      if vTabla.exists then bFBedolgozas;

      // KEZD BEDOLGOZÁSA (kezdij) ==============================

      _aktTablanev := 'KEZD' + _farok;

      vdbase.connected := True;
      vTabla.close;
      vTabla.TableName := _aktTablaNev;
      if vTabla.exists then KezdBedolgozas;

      // EFEJ BEDOLGOZÁSA (ETRADE) ==============================

      _aktTablanev := 'EFEJ' + _farok;

     vdbase.connected := True;

      vTabla.close;
      vTabla.TableName := _aktTablaNev;
      if vTabla.exists then EfejBedolgozas;
      inc(_ptIndex);
    end;
end;

// =============================================================================
                      procedure TForm1.WzarBedolgozas;
// =============================================================================

var _wuUsdnyito,_wuHufNyito,_wuUsdBe,_wuHufBe,_wuUsdki,_wuHufKi: integer;
    _wuUsdZaro,_wuHufZaro: integer;
    _metronyito,_tesconyito,_metroZaro,_tescozaro,_tescobe,_metrobe: integer;
    _tescoki,_metroki,_metrovissza,_tescovissza: integer;

begin
  Logiro(_akttablanev + ' bedolgozása ..');
  Memo1.Lines.add('Western Union gyüjtése');
  _pcs := 'SELECT * FROM ' + _aktTablanev + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with Vquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not vquery.eof do
    begin
      _datum      := Vquery.fieldByName('DATUM').asString;
      _wuusdnyito := vQuery.FieldByNAme('USDNYITO').asInteger;
      _wuHufNyito := vQuery.FieldByName('HUFNYITO').asInteger;
      _wuUsdBe    := vQuery.FieldByName('USDBE').asInteger;
      _wuHufBe    := vQuery.FieldByNAme('HUFBE').asInteger;
      _wuUsdKi    := vQuery.FieldByName('USDKI').asInteger;
      _wuHufKi    := vQuery.FieldByNAme('HUFKI').asInteger;
      _wuUsdZaro  := Vquery.FieldByName('USDZARO').asInteger;
      _wuHufZaro  := vQuery.FieldByNAme('HUFZARO').asInteger;
      _metronyito := vQuery.FieldByName('METRONYITO').asInteger;
      _tescoNyito := vQuery.FieldByNAme('TESCONYITO').asInteger;
      _metrozaro  := vQuery.FieldByNAme('METROZARO').asInteger;
      _tescoZaro  := vQuery.FieldbyName('TESCOZARO').asInteger;
      _tescobe    := Vquery.FieldByName('TESCOBE').asInteger;
      _metrobe    := Vquery.FieldByName('METROBE').asInteger;
      _tescoki    := Vquery.FieldByName('TESCOKI').asInteger;
      _metroki    := Vquery.FieldByName('METROKI').asInteger;
      _metrovissza:= Vquery.FieldByName('METROVISSZA').asInteger;
      _tescovissza:= Vquery.FieldByName('TESCOVISSZA').asInteger;

      _naps := midstr(_datum,9,2);
      val(_naps,_nap,_code);
      if _code<>0 then _nap := 0;

      _xUsdNyito[_ptIndex,_nap] := _wuusdnyito;
      _xHufNyito[_ptIndex,_nap] := _wuhufnyito;
      _xUsdBe[_ptIndex,_nap]    := _wuusdbe;
      _xHufBe[_ptIndex,_nap]    := _wuhufbe;
      _xUsdKi[_ptIndex,_nap]    := _wuusdKi;
      _xHufKi[_ptIndex,_nap]    := _wuhufKi;
      _xUsdZaro[_ptIndex,_nap]  := _wuUsdZaro;
      _xHufZaro[_ptIndex,_nap]  := _wuHufZaro;
      _xAfaNyito[_ptIndex,_nap] := _metronyito+_tesconyito;
      _xAfaZaro[_ptIndex,_nap]  := _metrozaro+_tescoZaro;
      _xAfaBanktolBe[_ptIndex,_nap] := _tescobe+_metrobe;
      _xAfakiadas[_ptindex,_nap] := _tescoki+_metroki;
      _xAfaVissza[_ptindex,_nap] := _tescovissza+_metrovissza;

      vQuery.next;
    end;
  vQuery.close;
  vDbase.close;
end;


procedure TForm1.BFBedolgozas;

begin
  Logiro(_akttablanev+' bedolgozasa ...');

  Memo1.Lines.add('A befizetett kezdijak');
  _pcs := 'SELECT * FROM ' + _aktTablanev + _sorveg;
  _pcs := _pcs + 'WHERE STORNO=1' + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with Vquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not vquery.eof do
    begin
      _datum := Vquery.fieldByName('DATUM').asString;
      _naps := midstr(_datum,9,2);
      val(_naps,_nap,_code);
      if _code<>0 then _nap := 0;
      _kezdij := vquery.FieldByNAme('KEZELESIDIJ').asInteger;
      _xkdbevet[_ptindex,_nap] := _xkdBevet[_ptIndex,_nap] + _kezdij;
      vQuery.next;
    end;
  vquery.close;
  vDbase.close;
end;

procedure TForm1.KezdBedolgozas;

begin
  Logiro(_akttablanev+' bedolgozása ...');
  Memo1.Lines.Add('Kezelési díjak beolvasása');
  _pcs := 'SELECT * FROM ' + _aktTablanev + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with Vquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not vquery.eof do
    begin
      _datum := Vquery.fieldByName('DATUM').asString;
      _elojel := vQuery.FieldByNAme('ELOJEL').asString;
      _mozgas := vQuery.FieldByNAme('MOZGAS').asInteger;
      _kezdij := vQuery.FieldByNAme('KEZELESIDIJ').asInteger;

      _naps := midstr(_datum,9,2);
      val(_naps,_nap,_code);
      if _code<>0 then _nap := 0;

      if (_elojel = '+') and (_mozgas=4) then
        begin
          _xKdAtvet[_ptIndex,_nap] := _xKdAtvet[_ptIndex,_nap] + _kezdij;
        end;

      if (_elojel = '-') and (_mozgas=3) then
        begin
          _xKdbefiz[_ptIndex,_nap] := _xKdBefiz[_ptIndex,_nap] + _kezdij;
        end;
      vQuery.next;
    end;
  Vquery.close;
  vDbase.close;
end;


procedure TForm1.EfejBedolgozas;

var _nyito,_matrica,_telefon,_vodafon,_telenor,_paysafecard: integer;
    _atadas,_atvetel,_zaro,_telefonok: integer;

begin
  Logiro(_akttablanev+' bedolgzoása ...');
  Memo1.Lines.add('Elektromos kereskedés');
  _pcs := 'SELECT * FROM ' + _aktTablanev + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with Vquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not vquery.eof do
    begin
      _datum := Vquery.fieldByName('DATUM').asString;
      _nyito := vQuery.FieldByNAme('NYITO').asInteger;
      _matrica := vQuery.FieldByName('MATRICA').asInteger;
      _telefon := vquery.fieldByNAme('TELEFON').asInteger;
      _vodafon := vQuery.FieldByNAme('VODAFON').asInteger;
      _telenor := vQuery.FieldByNAme('TELENOR').asInteger;
      _paysafecard := vQuery.FieldByNAme('PAYSAFECARD').asInteger;
      _atadas := vQuery.FieldByNAme('ATADAS').asInteger;
      _atvetel := vQuery.FieldByNAme('ATVETEL').asInteger;
      _zaro := vQuery.FieldByNAme('ZARO').asInteger;

      _naps := midstr(_datum,9,2);
      val(_naps,_nap,_code);
      if _code<>0 then _nap := 0;

      _xEtradeNyito[_ptIndex,_nap] := _nyito;
      _xMatrica[_ptIndex,_nap] := _xMatrica[_ptIndex,_nap] + _matrica;
      _telefonok := _telefon+_vodafon+_telenor+_paysafecard;
      _xTelefon[_ptIndex,_nap] := _xtelefon[_ptindex,_nap] + _telefonok;
      _xEtradeAtadas[_ptindex,_nap] := _xEtradeAtadas[_ptIndex,_nap]+_atadas;
      _xEtradeAtvetel[_ptindex,_nap] := _xEtradeAtvetel[_ptIndex,_nap]+_atVetel;
      _xEtradeZaro[_ptIndex,_nap] := _zaro;
      vQuery.next;
    end;
  vQuery.close;
  Vdbase.close;
end;


// =============================================================================
          function TForm1.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
           procedure TForm1.HONAPMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  Application.terminate;
end;

// =============================================================================
                      procedure TForm1.IrodaBeolvasas;
// =============================================================================

begin

  IrodaNullazas;

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE CLOSED=' +chr(39) + 'N' + CHR(39) + _sorveg;
  _pcs := _pcs + 'ORDER BY ERTEKTAR,UZLET';

  recdbase.connected := True;
  with recQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  _y := 0;
  while not recquery.eof do
    begin
      _penztarszam := Recquery.FieldByNAme('UZLET').asInteger;
      _pnev        := trim(RecQuery.FieldByNAme('KESZLETNEV').asString);
      _ertektar    := Recquery.FieldByNAme('ERTEKTAR').asInteger;
      if _penztarszam>150 then _ertektar := 180;

      _xx := ScanErtektar(_ertektar);

      _kdb := _KorzetIrodadb[_xx]+1;
      _korzetirodadb[_xx] := _kdb;
      _korzetIrodasor[_xx,_kdb] := _penztarszam;

      inc(_y);
      _penztarsor[_y] := _penztarszam;
      _penztarnev[_y] := _pNev;
      _irkorzetszam[_y] := _ertektar;
      _urespenztar[_y] := False;
      recQuery.next;
    end;
  recquery.close;
  recdbase.close;
  _irodaDarab := _y;
end;


// =============================================================================
              function Tform1.Getpenztarnev(_pt: byte): string;
// =============================================================================

begin
  result := '<unknown>';
  _xx := ScanPenztar(_pt);
  if _XX=0 then exit;

  result := _penztarnev[_xx];
  exit;
end;

// =============================================================================
                  function TForm1.ScanPenztar(_ptn: byte): byte;
// =============================================================================

var _k: byte;

begin
  result := 0;
  _k := 1;
  while _k<=_irodadarab do
    begin
      if _Penztarsor[_k]=_ptn then
        begin
          result := _k;
          exit;
        end;
      inc(_k);
    end;
end;

// =============================================================================
               function TForm1.ScanErtektar(_etn: byte): byte;
// =============================================================================

var _k: byte;

begin
  result := 0;
  _k := 1;
  while _k<=9 do
    begin
      if _korzetszam[_k]=_etn then
        begin
          result := _k;
          exit;
        end;
      inc(_k);
    end;
end;


// =============================================================================
                            procedure TForm1.UresCOntrol;
// =============================================================================

var _pt: byte;
    _ures: boolean;
begin
  _pt := 1;
  while _pt<=_irodaDarab do
    begin
      _ures := urctrl(_pt);
      if _ures then _uresPenztar[_pt] := True;
      inc(_pt);
    end;
end;

// =============================================================================
                function TForm1.Urctrl(_p: byte): boolean;
// =============================================================================

begin
  result := False;
  _nap := 1;
  while _nap<=_havinap do
    begin
      if _xUsdNyito[_p,_nap]>0 then exit;
      if _xHufNyito[_p,_nap]>0 then exit;
      if _xUsdbe[_p,_nap]>0 then exit;
      if _xHufbe[_p,_nap]>0 then exit;
      if _xUsdki[_p,_nap]>0 then exit;
      if _xHufki[_p,_nap]>0 then exit;
      if _xUsdZaro[_p,_nap]>0 then exit;
      if _xHufZaro[_p,_nap]>0 then exit;

      if _xKdBevet[_p,_nap]>0 then exit;
      if _xKdBefiz[_p,_nap]>0 then exit;
      if _xKdAtvet[_p,_nap]>0 then exit;

      if _xEtradenyito[_p,_nap]>0 then exit;
      if _xMatrica[_p,_nap]>0 then exit;
      if _xTelefon[_p,_nap]>0 then exit;
      if _xEtradeAtadas[_p,_nap]>0 then exit;
      if _xEtradeAtvetel[_p,_nap]>0 then exit;
      if _xEtradeZaro[_p,_nap]>0 then exit;

      if _xAfanyito[_p,_nap]>0 then exit;
      if _xAfabanktolbe[_p,_nap]>0 then exit;
      if _xAfakiadas[_p,_nap]>0 then exit;
      if _xAfavissza[_p,_nap]>0 then exit;
      if _xAfaZaro[_p,_nap]>0 then exit;

      inc(_NAP);
    end;
  result := true;
end;

procedure TForm1.NyitoFix;

var _pt,_endnap: byte;
    _xNyito: integer;

begin
  _xnyito := 0;
  _pt := 1;
  while _pt<=_irodadarab do
    begin
      if _urespenztar[_pt] then
        begin
          inc(_pt);
          continue;
        end;

      if (_xUsdNyito[_pt,1]=0) and (_xUsdZaro[_pt,1]=0) then
        begin
          _endnap := 0;
          _nap := 2;
          while _nap<=_havinap do
            begin
              if _xUsdNyito[_pt,_nap]>0 then
                begin
                  _xNyito := _xUsdNyito[_pt,_nap];
                  _endnap := _nap-1;
                  break;
                end;
              inc(_nap);
            end;
          if _endnap>0 then
            begin
              _nap := 1;
              while _nap<=_endnap do
                begin
                  _xUsdNyito[_pt,_nap] := _xNyito;
                  _xUsdZaro[_pt,_nap]  := _xNyito;
                  inc(_nap);
                end;
            end;
        end;

   // ---------------------------------------------------------

      if (_xHufNyito[_pt,1]=0) and (_xHufZaro[_pt,1]=0) then
        begin
          _endnap := 0;
          _nap := 2;
          while _nap<=_havinap do
            begin
              if _xHufNyito[_pt,_nap]>0 then
                begin
                  _xNyito := _xHufNyito[_pt,_nap];
                  _endnap := _nap-1;
                  break;
                end;
              inc(_nap);
            end;
          if _endnap>0 then
            begin
              _nap := 1;
              while _nap<=_endnap do
                begin
                  _xHufNyito[_pt,_nap] := _xNyito;
                  _xHufZaro[_pt,_nap]  := _xNyito;
                  inc(_nap);
                end;
            end;
        end;

   // ---------------------------------------------------------
   // ==========================================================

      if (_xEtradeNyito[_pt,1]=0) and (_xEtradeZaro[_pt,1]=0) then
        begin
          _endnap := 0;
          _nap := 2;
          while _nap<=_havinap do
            begin
              if _xEtradeNyito[_pt,_nap]>0 then
                begin
                  _xNyito := _xEtradeNyito[_pt,_nap];
                  _endnap := _nap-1;
                  break;
                end;
              inc(_nap);
            end;
          if _endnap>0 then
            begin
              _nap := 1;
              while _nap<=_endnap do
                begin
                  _xEtradeNyito[_pt,_nap] := _xNyito;
                  _xEtradeZaro[_pt,_nap]  := _xNyito;
                  inc(_nap);
                end;
            end;
        end;

   // ---------------------------------------------------------

      if (_xAfaNyito[_pt,1]=0) and (_xAfaZaro[_pt,1]=0) then
        begin
          _endnap := 0;
          _nap := 2;
          while _nap<=_havinap do
            begin
              if _xAfaNyito[_pt,_nap]>0 then
                begin
                  _xNyito := _xAfaNyito[_pt,_nap];
                  _endnap := _nap-1;
                  break;
                end;
              inc(_nap);
            end;
          if _endnap>0 then
            begin
              _nap := 1;
              while _nap<=_endnap do
                begin
                  _xAfaNyito[_pt,_nap] := _xNyito;
                  _xAfaZaro[_pt,_nap]  := _xNyito;
                  inc(_nap);
                end;
            end;
        end;
      inc(_pt);
    end;
end;


procedure TForm1.belsoFix;

var _pt: byte;
    _xNyito: integer;

begin
  _pt := 1;
  while _pt<=_irodaDarab do
    begin
      if _urespenztar[_pt] then
        begin
          inc(_pt);
          continue;
        end;
      _nap := 1;
      while _nap<=_havinap do
        begin
          if (_xUsdNyito[_pt,_nap]=0) and (_xUsdZaro[_pt,_nap]=0) then
            begin
              dec(_nap);
              _xNyito := _xUsdZaro[_pt,_nap];
              inc(_nap);
              _xUsdNyito[_pt,_nap] := _xNyito;
              _xUsdZaro[_pt,_nap] := _xNyito;
            end;
          inc(_nap);
        end;

    // ------------------------------------------

      _nap := 1;
      while _nap<=_havinap do
        begin
          if (_xHufNyito[_pt,_nap]=0) and (_xHufZaro[_pt,_nap]=0) then
            begin
              dec(_nap);
              _xNyito := _xHufZaro[_pt,_nap];
              inc(_nap);
              _xHufNyito[_pt,_nap] := _xNyito;
              _xHufZaro[_pt,_nap] := _xNyito;
            end;
          inc(_nap);
        end;

    // ------------------------------------------

      _nap := 1;
      while _nap<=_havinap do
        begin
          if (_xEtradeNyito[_pt,_nap]=0) and (_xEtradezaro[_pt,_nap]=0) then
            begin
              dec(_nap);
              _xNyito := _xEtradeZaro[_pt,_nap];
              inc(_nap);
              _xEtradeNyito[_pt,_nap] := _xNyito;
              _xEtradeZaro[_pt,_nap] := _xNyito;
            end;
          inc(_nap);
        end;

    // ------------------------------------------

      _nap := 1;
      while _nap<=_havinap do
        begin
          if (_xAfaNyito[_pt,_nap]=0) and (_xAfaZaro[_pt,_nap]=0) then
            begin
              dec(_nap);
              _xNyito := _xAfaZaro[_pt,_nap];
              inc(_nap);
              _xAfaNyito[_pt,_nap] := _xNyito;
              _xAfaZaro[_pt,_nap] := _xNyito;
            end;
          inc(_nap);
        end;
      inc(_pt);
    end;
end;

// =============================================================================
                  procedure TForm1.ExcelKill;
// =============================================================================

var
  _fileName,_filePath: String;

begin

  _Proc.dwSize := SizeOf(_Proc);
  _handle := CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
  _Looper := Process32First(_handle,_proc);

  while Integer(_Looper) <> 0 do
    begin
      _filepath := _Proc.szExeFile;
      _fileName := UpperCase(ExtractFileName(_filepath));

      if _fileName = 'EXCEL.EXE' then
        begin
          TerminateProcess(OpenProcess(1,Bool(1),_proc.th32ProcessID),0);
        //  break;
        end;

      _Looper := Process32Next(_handle,_proc);
    end;
  CloseHandle(_handle);
end;

procedure TForm1.Logiro(_mess: string);

var _logsor: string;

begin
  _idos   := timetostr(time);
  _logsor := _mamas+' '+_idos+': '+_mess;
  writeLn(_iras,_logsor);
end;

end.
