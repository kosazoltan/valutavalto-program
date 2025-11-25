unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, Comobj, DateUtils,
  strutils, IBTable, ComCtrls, Buttons, TlHelp32, ExtCtrls;

type
  TForm1 = class(TForm)
    STARTGOMB: TButton;
    KILEPGOMB: TButton;
    RECQUERY: TIBQuery;
    VQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    VDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    VTRANZ: TIBTransaction;
    ARTQUERY: TIBQuery;
    ARTDBASE: TIBDatabase;
    ARTTRANZ: TIBTransaction;
    VTABLA: TIBTable;
    Memo: TMemo;
    IRODACSUSZKA: TProgressBar;
    NAPCSUSZKA: TProgressBar;
    Label1: TLabel;
    Label2: TLabel;
    EVCOMBO: TComboBox;
    HOCOMBO: TComboBox;
    Shape1: TShape;
    Shape2: TShape;
    Shape3: TShape;
    Label3: TLabel;
    Shape4: TShape;
    Shape5: TShape;

    procedure KILEPGOMBClick(Sender: TObject);
    procedure STARTGOMBClick(Sender: TObject);
    procedure ErtektarWuData;
    procedure ExcelKill;
    procedure MakeExcel;
    procedure SetPenztarsor;
    procedure AdatUrito;
    procedure HibaWrite(_hibass: byte);
    procedure ElsejePotlasa;
    procedure Korzetbesorolas;
    procedure EgyNapiAdatFeltoltes;
    procedure EgykorzetNapja;
    procedure CegosszesenSor;
    procedure Napifejlec;
    procedure HaviWesternTablo;
    procedure PenztarWuData;
    procedure Vastagkeret(_rs: string; _sh: byte);
    procedure Vekonykeret(_rs: string; _sh: byte);

    function AdatEllenorzes: boolean;
    function Getcegss(_bt: string): byte;
    function Getkorzetss(_kn: byte): byte;
    function Nulele(_num: byte): string;
    function ScanPenztar(_pnum: byte): byte;
    function ScanKorzet(_knum: byte): byte;

    procedure FormActivate(Sender: TObject);
    procedure EVCOMBOChange(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _proc: PROCESSENTRY32;
  _handle:HWND;

  _cegsor: array[1..2] of string = ('B','Z');

  _cegnevek: array[1..2] of string = ('EXCLUSIVE BEST CHANGE KFT.',
     'EXPRESSZ ÉKSZERHÁZ ÉS MINIBANK KFT.');

  _cegrovnev: array[1..2] of string = ('BEST CHANGE','EXPRESSZ');

   _korzetnevek: array[1..9] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
       'DEBRECEN','NYIREGYHÁZ','BÉKÉSCSABA','PÉCS','KAPOSVÁR','EXPRESSZ');

  _cegkorzetDarab: array[1..2] of byte = (8,1);
  _cegkorzetSor: array[1..2,1..8] of byte = ((20,40,50,63,75,10,120,145),(180,0,0,0,0,0,0,0));

  _korzetsor : array[1..9] of byte = (10,20,40,50,63,75,120,145,180);
  _korzetPenztarDarab: array[1..9] of byte;
  _korzetPenztarsor: array[1..9,1..25] of byte;

  _penztarsor,_ptkorzet,_ptkft: array[1..180] of byte;
  _penztarnev,_ptstatus: array[1..180] of string;

  _zUsdNyito,_zUsdZaro,_zUsdBe,_zUsdKi: array[1..180,1..31] of integer;
  _zHufNyito,_zHufZaro,_zHufBe,_zHufKi: array[1..180,1..31] of integer;

  _wUsdUgyfBe,_wUsdUgyfKi,_wHufUgyfBe,_wHufUgyfKi: array[1..180,1..31] of integer;
  _wUsdBankBe,_wUsdBankKi,_wHufBankBe,_wHufBankKi: array[1..180,1..31] of integer;

  _honev: array[1..12] of string = ('JANUAR','FEBRUAR','MARCIUS','APRILIS','MAJUS',
           'JUNIUS','JULIUS','AUGUSZTUS','SZEPTEMBER','OKTOBER','NOVEMBER',
           'DECEMBER');

  _sumsor: array[1..25] of integer;
  _oxl,_owb,_range: olevariant;
  _O1,_sumdarab,_sss,_ho: byte;
  _prisor,_startsor,_endsor,_osszsor,_usd,_huf,_cegSumsor,_aktsor: integer;

  _aktdatums,_rangestr,_ks,_pristr,_sstr,_estr,_ostr,_cstr,_aktsorszam: string;
  _aktkorzetnev,_excelnev,_excelPath,_formula,_orangestr,_as,_aktstatus: string;

  _pt,_ptss,_korzetnum,_korzetss,_cegss,_y,_irodadarab,_aktpt,_xnap: byte;
  _aktkorzetss,_aktcegss,_aktnap,_aktfoe,_havinap,_utnap,_aktptdarab: byte;
  _penztardarab,_aktdarab,_pp,_aktkorzetdarab,_ptkorzetss,_aktkorzetnum: byte;


  _pcs,_ptnev,_cegbetu,_farok,_wzar,_wuni,_aktptnev,_aktfdbpath,_pmess: string;
  _vdatum,_aktdnem,_akttranz,_mess,_utDatum,_elodatums,_aktcegnev: string;
  _sorveg: string = chr(13)+chr(10);

  _vUsdnyito,_vUsdZaro,_vHufNyito,_vHufZaro,_aktbankjegy,_hiba: integer;
  _vUsdBe,_vUsdKi,_vHufbe,_vHufki: integer;
  _utUsdZaro,_utHufZaro,_ugyfUsdBe,_ugyfHufBe,_ugyfUsdki,_ugyfHufKi: integer;
  _maiUsdNyito,_maiHufNyito,_usdbe,_usdki,_hufbe,_hufki: integer;
  _szamUsdZaro,_szamHufZaro,_bankUsdBe,_bankHufbe,_bankUsdki,_bankHufki: integer;
  _forgUsdBe,_forgUsdKi,_forgHufbe,_forgHufki,_evindex,_hoindex: integer;

  _aktev,_aktho,_top,_left,_height,_width,_targyev,_targyho: word;

  _vanexcel,_looper: boolean;

implementation


{$R *.dfm}

// =============================================================================
             procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;
  _top    := round((_height-587)/2);
  _left   := round((_width-395)/2);

  Top  := _top;
  Left := _left;
  Repaint;

  _aktev := yearof(date);
  _aktho := monthof(date);

  evcombo.Items.clear;
  evcombo.Clear;

  evcombo.Items.add(inttostr(_aktev-1));
  evcombo.Items.Add(inttostr(_aktev));
  evcombo.ItemIndex := 1;

  hocombo.Items.clear;
  hocombo.clear;
  _ho := 1;

  while _ho<=12 do
    begin
      hocombo.Items.Add(_honev[_ho]);
      inc(_ho);
    end;

  if _aktho=1 then
    begin
      evcombo.ItemIndex := 0;
      hocombo.ItemIndex := 11;
    end else
    begin
      hocombo.ItemIndex := _aktho-1;
    end;
  Activecontrol := StartGomb;
end;


// =============================================================================
          procedure TForm1.STARTGOMBClick(Sender: TObject);
// =============================================================================

begin
  _evindex := evcombo.itemindex;
  _hoIndex := hocombo.itemindex;
  if (_evindex=1) and ((1+_hoindex)>_aktho) then
    begin
      ShowMessage('A KÉRT HÓNAP A JÖVÕBEN LESZ');
      exit;
    end;

   StartGomb.Enabled := false;

   _targyev := _aktev-1+_evindex;
   _targyho := 1 + _hoindex;

   _elodatums := inttostr(_targyev)+'.'+nulele(_targyho)+'.';
   _farok := midstr(_elodatums,3,2)+midstr(_elodatums,6,2);

   _havinap := DAysinamonth(_targyev,_targyho);

  _wzar := 'WZAR' + _farok;
  _wuni := 'WUNI' + _farok;

  _vanexcel := False;

  HaviWesternTablo;
end;


// =============================================================================
                     procedure TForm1.HaviWesternTablo;
// =============================================================================

begin
  SetPenztarsor;
  AdatUrito;
  KorzetbeSorolas;

  _ptss := 1;
  while _ptss<=_irodadarab do
    begin
      _aktpt       := _penztarsor[_ptss];
      _aktptnev    := _penztarnev[_ptss];
      _aktkorzetss := _ptkorzet[_ptss];
      _aktcegss    := _ptkft[_ptss];
      _aktstatus   := _ptstatus[_ptss];

      if _aktpt<151 then
        _aktfdbpath  := 'c:\receptor\database\v' + inttostr(_aktpt) + '.fdb'
      else
        _aktfdbpath  := 'c:\Cartcash\database\v' + inttostr(_aktpt) + '.fdb';

      with Vdbase do
        begin
          close;
          databasename := _aktfdbPath;
          connected := true;
        end;

      VTabla.close;
      Vtabla.TableName := _wzar;
      if not VTabla.Exists then
        begin
          vdbase.close;
          inc(_ptss);
          Continue;
        end;

      _pcs := 'SELECT * FROM ' + _wzar + _sorveg;
      _pcs := _pcs + 'ORDER BY DATUM';

      with VQuery do
        begin
          Close;
          sql.clear;
          sql.Add(_pcs);
          Open;
        end;

      _utDatum := VQuery.FieldByName('DATUM').asString;
      _utNap := strtoint(midstr(_utdatum,9,2));

      _utUsdZaro := Vquery.FieldByNAme('USDNYITO').asInteger;
      _utHufZaro := Vquery.FieldByNAme('HUFNYITO').asInteger;

      if _utnap>1 then ElsejePotlasa;
      _utnap := 0;

      while not Vquery.Eof do
        begin
          _vDatum := Vquery.FieldByName('DATUM').asString;
          _aktnap := strtoint(midstr(_vdatum,9,2));
          if (_aktnap-1)>_utnap then
            begin
              _xnap := _utnap+1;
              while _xnap<_aktnap do
                begin
                  _zUsdNyito[_ptss,_xnap] := _utUsdZaro;
                  _zHufNyito[_ptss,_xnap] := _utHufZaro;
                  _zUsdZaro[_ptss,_xnap]  := _utUsdZaro;
                  _zHufZaro[_ptss,_xnap]  := _utHufZaro;
                  inc(_xNap);
                end;
            end;
          _utnap := _aktnap;

          _vUsdNyito := Vquery.FieldByNAme('USDNYITO').asInteger;
          _vUsdZaro  := Vquery.FieldByNAme('USDZARO').asInteger;
          _vUsdBe    := Vquery.FieldByNAme('USDBE').asInteger;
          _vUsdKi    := Vquery.FieldByNAme('USDKI').asInteger;

          _vHufNyito := Vquery.FieldByNAme('HUFNYITO').asInteger;
          _vHufZaro  := Vquery.FieldByNAme('HUFZARO').asInteger;
          _vHufBe    := Vquery.FieldByNAme('HUFBE').asInteger;
          _vHufKi    := Vquery.FieldByNAme('HUFKI').asInteger;

          _utUsdZaro := _vUsdZaro;
          _utHufZaro := _vHufZaro;

          _zUsdNyito[_ptss,_aktnap] := _vUsdNyito;
          _zUsdZaro[_ptss,_aktnap]  := _vUsdZaro;
          _zUsdBe[_ptss,_aktnap]    := _vUsdBe;
          _zUsdKi[_ptss,_aktnap]    := _vUsdKi;

          _zHufNyito[_ptss,_aktnap] := _vHufNyito;
          _zHufZaro[_ptss,_aktnap]  := _vHufZaro;
          _zHufBe[_ptss,_aktnap]    := _vHufBe;
          _zHufKi[_ptss,_aktnap]    := _vHufKi;
          vQuery.next;
        end;
      Vquery.close;

      if _aktnap<_havinap then
        begin
          _xnap := _aktnap+1;
          while _xnap<=_havinap do
            begin
              _zUsdNyito[_ptss,_xnap] := _utUsdZaro;
              _zHufNyito[_ptss,_xnap] := _utHufZaro;
              _zUsdZaro[_ptss,_xnap]  := _utUsdZaro;
              _zHufZaro[_ptss,_xnap]  := _utHufZaro;
              inc(_xNap);
            end;
        end;
      // --------------------------------------

      VTabla.close;
      Vtabla.TableName := _wuni;
      if not VTabla.Exists then
        begin
          vdbase.close;
          inc(_ptss);
          Continue;
        end;

      _pcs := 'SELECT * FROM ' + _wuni + _sorveg;
      _pcs := _pcs + 'WHERE STORNO=1' + _sorveg;
      _pcs := _pcs + 'ORDER BY DATUM';

      with VQuery do
        begin
          Close;
          sql.Clear;
          Sql.Add(_pcs);
          Open;
        end;

      while not vquery.Eof do
        begin
          _vDatum := Vquery.FieldByName('DATUM').asString;
          _aktnap := strtoint(midstr(_vdatum,9,2));
          _aktfoe := Vquery.FieldByNAme('FOEGYSEG').asInteger;
          _aktdnem := Vquery.Fieldbyname('VALUTANEM').asString;
          _akttranz := Vquery.FieldByNAme('TRANZAKCIOTIPUS').asString;
          _aktbankjegy := Vquery.FieldByName('BANKJEGY').asInteger;
          _aktsorszam := VQuery.FieldByName('SORSZAM').asString;

          // -------------------------------------------------------------

          if _aktstatus='P' then penztarwudata else ertektarwudata;
          Vquery.next;
        end;

      Vquery.Close;
      Vdbase.close;
      inc(_ptss);
    end;

  if not AdatEllenorzes then
    begin
      Memo.Lines.Add('  ');
      Memo.Lines.Add('       HIBÁS ADATOKAT TALÁLTAM !');
      exit;
    end Else
    begin
      Memo.Lines.add('       A HAVI ADATOK HIBÁTLANOK');
      Sleep(4000);
    end;

  Memo.Clear;
  Memo.Lines.clear;
  Memo.Font.Size := 12;
  Memo.Font.Style := [];
  MakeExcel;
end;

// =============================================================================
                      procedure TForm1.SetPenztarsor;
// =============================================================================

begin
  _ptss := 0;

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE (WESTERNUNION=1) AND (CLOSED='+chr(39)+'N'+chr(39)+')'+_sorveg;
//  _pcs := _pcs + 'AND (STATUS=' + chr(39) + 'P' + chr(39) + ')'+_sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  recdbase.connected := true;
  with recquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not recquery.eof do
    begin
      _pt := Recquery.FieldByNAme('UZLET').asInteger;
      _ptnev := trim(RecQuery.FieldByNAme('KESZLETNEV').asString);
      _korzetnum := Recquery.FieldByNAme('ERTEKTAR').asInteger;
      _cegbetu := Recquery.FieldByNAme('CEGBETU').asString;
      _aktstatus := Recquery.FieldByNAme('STATUS').asString;

      _korzetss := Getkorzetss(_korzetnum);

      inc(_ptss);

      _penztarsor[_ptss] := _pt;
      _penztarnev[_ptss] := _ptnev;
      _ptKorzet[_ptss]   := _korzetss;
      _ptkft[_ptss]      := 1;
      _ptstatus[_ptss]   := _aktstatus;
      recquery.next;
    end;

  recquery.close;
  recdbase.close;

  // ------------------------------------------

  artdbase.connected := true;
  with artquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not artquery.eof do
    begin
      _pt := artquery.FieldByNAme('UZLET').asInteger;
      _ptnev := trim(artQuery.FieldByNAme('KESZLETNEV').asString);

      inc(_ptss);

      _penztarsor[_ptss] := _pt;
      _penztarnev[_ptss] := _ptnev;
      _ptKorzet[_ptss]   := 9;
      _ptkft[_ptss]      := 2;
      _ptstatus[_ptss]   := 'P';
      ARTquery.next;
    end;

  ARTquery.close;
  ARTdbase.close;

  _irodaDarab := _ptss;
end;


// =============================================================================
                 procedure TForm1.KorzetbeSorolas;
// =============================================================================


begin
  _ptss := 1;
  while _ptss<=_irodaDarab do
    begin
      _aktPt     := _penztarsor[_ptss];
      _Korzetss  := _ptkorzet[_ptss];
      _aktdarab  := _korzetPenztarDarab[_korzetss];
      inc(_aktdarab);
      _korzetPenztarDarab[_korzetss] := _aktdarab;
      _korzetPenztarSor[_korzetss,_aktdarab] := _aktpt;
      inc(_ptss);
    end;
end;


// =============================================================================
              function TForm1.Getkorzetss(_kn: byte): byte;
// =============================================================================

begin
  result := 0;
  _y := 1;

  while _y<=9 do
    begin
      if _korzetsor[_y]=_kn then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
               function TForm1.getcegss(_bt: string): byte;
// =============================================================================

begin
  result := 0;
  _y := 1;
  while _y<=2 do
    begin
      if _cegsor[_y]=_bt then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
                            procedure TForm1.adatUrito;
// =============================================================================

begin
  _ptss := 1;
  while _ptss<=_irodaDarab do
    begin
      _aktnap := 1;
      while _aktnap<=31 do
        begin
          _zUsdNyito[_ptss,_aktnap] := 0;
          _zUsdZaro[_ptss,_aktnap] := 0;
          _zUsdBe[_ptss,_aktnap] := 0;
          _zUsdKi[_ptss,_aktnap] := 0;

          _zHufNyito[_ptss,_aktnap] := 0;
          _zHufZaro[_ptss,_aktnap] := 0;
          _zHufBe[_ptss,_aktnap] := 0;
          _zHufKi[_ptss,_aktnap] := 0;

          _wUsdUgyfBe[_ptss,_aktnap] := 0;
          _wUsdUgyfKi[_ptss,_aktnap] := 0;
          _wUsdBankBe[_ptss,_aktnap] := 0;
          _wUsdBankKi[_ptss,_aktnap] := 0;

          _wHufUgyfBe[_ptss,_aktnap] := 0;
          _wHufUgyfKi[_ptss,_aktnap] := 0;
          _wHufBankBe[_ptss,_aktnap] := 0;
          _wHufBankKi[_ptss,_aktnap] := 0;

          inc(_aktnap);
        end;
      inc(_ptss);
    end;

  _korzetss := 1;
  while _korzetss<=9 do
    begin
      _korzetPenztarDarab[_korzetss] := 0;
      _pp := 1;
      while _pp<=25 do
        begin
          _korzetPenztarSor[_korzetss,_pp] := 0;
          inc(_pp);
        end;
      inc(_korzetss);
    end;
end;


// =============================================================================
                 function TForm1.AdatEllenorzes: boolean;
// =============================================================================

begin
  Memo.Clear;
  Memo.Lines.Clear;
  Memo.Font.Size := 12;

  result := False;
  _ptss := 1;
  _hiba := 0;

  Napcsuszka.Min := 1;
  Napcsuszka.Max := _havinap;
  Napcsuszka.Visible := True;

  irodacsuszka.Min := 1;
  irodacsuszka.Max := _irodaDarab;
  IrodaCsuszka.Visible := True;

  while _ptss<=_irodadarab do
    begin
      irodacsuszka.Position := _ptss;
      _aktnap    := 1;
      _utUsdzaro := _zusdnyito[_ptss,1];
      _uthufzaro := _zhufnyito[_ptss,1];

      while _aktnap<=_havinap do
        begin
          Napcsuszka.Position := _aktnap;
          _maiUsdnyito := _zUsdnyito[_ptss,_aktnap];
          _maiHufNyito := _zHufNyito[_ptss,_aktnap];

          if _maiUsdNyito<>_utUsdZaro then Hibawrite(1);
          if _maiHufNyito<>_utHufZaro then Hibawrite(2);

          _usdBe := _zUsdBe[_ptss,_aktnap];
          _usdKi := _zUsdKi[_ptss,_aktnap];
          _hufBe := _zHufBe[_ptss,_aktnap];
          _hufKi := _zHufKi[_ptss,_aktnap];

          _szamUsdZaro := _maiUsdNyito + _usdBe - _usdKi;
          _szamHufZaro := _maiHufNyito + _hufBe - _hufki;

          _utUsdZaro := _zUsdZaro[_ptss,_aktnap];
          _utHufZaro := _zhufZaro[_ptss,_aktnap];

          if _utUsdZaro<>_szamUsdZaro then HibaWrite(3);
          if _utHufZaro<>_szamHufZaro then HibaWrite(4);

          _bankUsdBe := _wUsdBankBe[_ptss,_aktnap];
          _bankHufBe := _wHufBankBe[_ptss,_aktnap];
          _bankUsdKi := _wUsdBankKi[_ptss,_aktnap];
          _bankHufKi := _wHufBankKi[_ptss,_aktnap];

          _ugyfUsdBe := _wUsdUgyfBe[_ptss,_aktnap];
          _ugyfHufBe := _wHufUgyfBe[_ptss,_aktnap];
          _ugyfUsdKi := _wUsdUgyfKi[_ptss,_aktnap];
          _ugyfHufKi := _wHufUgyfKi[_ptss,_aktnap];

          _forgUsdBe := _bankUsdbe + _ugyfUsdBe;
          _forgUsdKi := _bankUsdKi + _ugyfUsdKi;
          _forgHufBe := _bankHufbe + _ugyfHufBe;
          _forgHufKi := _bankHufKi + _ugyfHufKi;

          if _UsdBe<>(_ugyfUsdbe + _bankUsdbe) then Hibawrite(5);
          if _HufBe<>(_ugyfHufbe + _bankHufbe) then Hibawrite(6);
          if _UsdKi<>(_ugyfUsdKi + _bankUsdKi) then Hibawrite(7);
          if _HufKi<>(_ugyfHufKi + _bankHufKi) then Hibawrite(8);

          inc(_aktnap);
        end;
      inc(_ptss);
    end;
  irodacsuszka.Visible := False;
  napcsuszka.Visible   := False;
  if _hiba=0 then result := true;
end;

// =============================================================================
                procedure TForm1.HibaWrite(_hibass: byte);
// =============================================================================

begin
  inc(_hiba);
  _mess := _penztarnev[_ptss] + ' ' + inttostr(_aktnap)+'. napján';
  memo.Lines.Add(_mess);

  case _hibass of
    1: _mess := 'USD nyitó nem azonos az elözõ napi záróval';
    2: _mess := 'HUF nyitó nem azonos az elözõ napi záróval';
    3: _mess := 'USD számitott záró nem egyezik a tényleges záróval';
    4: _mess := 'HUF számitott záró nem egyezik a tényleges záróval';
    5: _mess := 'Ügyfél és Banki USD bevétel nem azonos az USD bevétellel';
    6: _mess := 'Ügyfél és Banki HUF bevétel nem azonos az HUF bevétellel';
    7: _mess := 'Ügyfél és Banki USD kiadás nem azonos az USD kiadással';
    8: _mess := 'Ügyfél és Banki HUF kiadás nem azonos az HUF kiadással';
  end;
  Memo.Lines.add(_mess);
end;

// =============================================================================
               procedure TForm1.KILEPGOMBClick(Sender: TObject);
// =============================================================================

begin
  if _vanexcel then
    begin
      _oxl.Quit;
      _oxl := unassigned;
      ExcelKill;
    end;

  application.terminate;
end;

// =============================================================================
               procedure TForm1.ElsejePotlasa;
// =============================================================================

begin
  _xnap := 1;
  while _xnap<_utnap do
    begin
      _zUsdNyito[_ptss,_xnap] := _utUsdZaro;
      _zHufNyito[_ptss,_xnap] := _utHufZaro;
      _zUsdZaro[_ptss,_xnap]  := _utUsdZaro;
      _zHufZaro[_ptss,_xnap]  := _utHufZaro;
      inc(_xNap);
    end;
end;

// =============================================================================
                      procedure TForm1.MakeExcel;
// =============================================================================

var i: byte;

begin
   _oxl := CreateOleObject('Excel.Application');
   _owb := _oxl.workbooks.add[1];

   _vanexcel := true;

  // --------------  A 31 fül létrehozása és elnevezése ------------------------

   _oxl.workbooks[1].sheets.add(,,31);
   for i := 1 to 31 do
       _oxl.workbooks[1].worksheets[i].name := inttostr(i);

  // --------------------------------------------------------------------------

   Napcsuszka.Max := _havinap;
   Memo.Lines.Add('AZ EXCELTÁBLA ÖSSZEÁLLÍTÁSA');

   // _munkanap: elsejétõl a hó utolsó napjáig:

   _aktnap := 1;
   _prisor := 1;
   while _aktnap<=_havinap do
     begin
       _aktdatums := _elodatums + nulele(_aktnap);
       Memo.Lines.Add('    ');
       Memo.Lines.add(_aktdatums+' beirása az exceltáblába');
       Napcsuszka.Visible := True;
       Napcsuszka.Position := _aktnap;
       _prisor := 1;

       Napifejlec;
       _prisor := 8;

       _cegss := 1;
       while _cegss<=2 do
         begin
           _aktcegnev := _cegnevek[_cegss];
           _pristr := inttostr(_prisor);
           _rangestr := 'B'+_pristr+':O'+_pristr;
           _sumdarab := 0;
           _oxl.worksheets[_aktnap].range[_rangestr].Mergecells := True;
           _oxl.worksheets[_aktnap].range[_rangestr].Font.Name  := 'Calibri';
           _oxl.worksheets[_aktnap].range[_rangestr].Font.Size  := 14;
           _oxl.worksheets[_aktnap].range[_rangestr].Font.Bold  := True;
           _oxl.worksheets[_aktnap].range[_rangestr].Font.Italic:= True;
           _oxl.worksheets[_aktnap].range[_rangestr].HorizontalAlignment := -4108;
           _oxl.worksheets[_aktnap].range[_rangestr] := _aktcegnev;
           inc(_prisor);

           _aktkorzetdarab := _cegkorzetDarab[_cegss];
           _ptkorzetss := 1;
           IrodaCsuszka.Max := _aktkorzetDarab;
           IrodaCsuszka.Visible := true;
           while _ptkorzetss<=_aktkorzetdarab do
             begin
               Irodacsuszka.Position := _ptkorzetss;
               _aktkorzetnum := _cegkorzetsor[_cegss,_ptkorzetss];
               _korzetss :=  scanKorzet(_aktkorzetnum);
               _aktkorzetnev := _korzetnevek[_korzetss];
               Memo.Lines.Add(_aktkorzetnev);
               EgyKorzetNapja;
               inc(_ptKorzetss);
             end;

           CegOsszesenSor;

           inc(_cegss);
         end;
       inc(_aktnap);
     end;

  _excelnev := 'WU' + inttostr(_targyev)+Nulele(_targyho)+'.xls';
  _excelPath := 'c:\receptor\mail\posta\'+_excelnev;

  if FileExists(_excelpath) then Deletefile(_excelPath);
  _owb.saveas(_excelPath);
  _oxl.visible := True;

  Irodacsuszka.Visible := False;
  Napcsuszka.Visible := False;

  Memo.clear;
  Memo.Lines.Clear;
  
  Memo.Lines.add('Az exceltáblát mentettem '+ _excelpath + '-ba');
end;

// =============================================================================
                  procedure TForm1.Napifejlec;
// =============================================================================

var _focim: string;

begin
  _oxl.worksheets[_aktnap].range['A1:A1'].columnwidth := 2;
  _oxl.worksheets[_aktnap].range['B1:B1'].columnwidth := 10;
  _oxl.worksheets[_aktnap].range['C1:C1'].columnwidth := 30;
  _oxl.worksheets[_aktnap].range['D1:D1'].columnwidth := 10;
  _oxl.worksheets[_aktnap].range['E1:E1'].columnwidth := 10;
  _oxl.worksheets[_aktnap].range['F1:F1'].columnwidth := 10;
  _oxl.worksheets[_aktnap].range['G1:G1'].columnwidth := 10;
  _oxl.worksheets[_aktnap].range['H1:H1'].columnwidth := 10;
  _oxl.worksheets[_aktnap].range['I1:I1'].columnwidth := 10;
  _oxl.worksheets[_aktnap].range['J1:J1'].columnwidth := 10;
  _oxl.worksheets[_aktnap].range['K1:K1'].columnwidth := 10;
  _oxl.worksheets[_aktnap].range['L1:L1'].columnwidth := 10;
  _oxl.worksheets[_aktnap].range['M1:M1'].columnwidth := 10;
  _oxl.worksheets[_aktnap].range['O1:O1'].columnwidth := 10;

  // ---------------------------------------------------------------------------

  _focim := 'WESTERN UNION HAVI ADATAI '+ inttostr(_targyev)+' '+_honev[_targyho];
  _focim := _focim + ' HÓNAPBAN';

  _rangestr := 'B1:O1';
  _oxl.worksheets[_aktnap].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Name  := 'Calibri';
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Size  := 14;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Bold  := True;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Italic:= True;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Color := $4090;
  _oxl.worksheets[_aktnap].range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_aktnap].range[_rangestr] := _focim;


  _aktdatums := _elodatums+nulele(_aktnap);
  _rangestr := 'E2:I2';

  _oxl.worksheets[_aktnap].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Name  := 'Arial Black';
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Size  := 12;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Bold  := True;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Italic:= True;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Color := $4090;
  _oxl.worksheets[_aktnap].range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_aktnap].range[_rangestr] := _aktdatums;



  // Teljes fejtábla:

  _rangestr := 'B4:O6';
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Name := 'Arial';
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Size := 9;
  _oxl.worksheets[_aktnap].range[_rangestr].HorizontalAlignment := -4108;

  // Pénztár oszlop:

  _rangestr := 'B4:C4';
  _oxl.worksheets[_aktnap].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_aktnap].range[_rangestr] := 'PÉNZTÁRAK';
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Bold := True;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Italic := True;

  // Pénztárszám oszlop:

  _rangestr := 'B5:B6';
  _oxl.worksheets[_aktnap].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_aktnap].range[_rangestr].VerticalAlignment := -4108;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Bold := true;
  _oxl.worksheets[_aktnap].range[_rangestr] := 'SZÁMA';


  // Pénztárnév oszlop:

  _rangestr := 'C5:C6';
  _oxl.worksheets[_aktnap].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_aktnap].range[_rangestr].VerticalAlignment := -4108;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Bold := true;
  _oxl.worksheets[_aktnap].range[_rangestr] := 'MEGNEVEZÉSE';

  // Nyitó készletek oszlopa:

  _rangestr := 'D4:E5';
  _oxl.worksheets[_aktnap].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_aktnap].range[_rangestr].VerticalAlignment := -4108;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Bold := true;
  _oxl.worksheets[_aktnap].range[_rangestr] := 'NYITÓ KÉSZLET';

  // Tranzakciók oszlopai:

  _rangestr := 'F4:I4';
  _oxl.worksheets[_aktnap].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Bold := true;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Italic := true;
  _oxl.worksheets[_aktnap].range[_rangestr] := 'BANKI/PÉNZTÁRI TRANZAKCIÓK';

  // Banki átvételek oszlopai:

  _rangestr := 'F5:G5';
  _oxl.worksheets[_aktnap].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Bold := true;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Italic := true;
  _oxl.worksheets[_aktnap].range[_rangestr] := 'ÁTVÉTEL';

  // Banki átadások oszlopai:

  _rangestr := 'H5:I5';
  _oxl.worksheets[_aktnap].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Bold := true;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Italic := true;
  _oxl.worksheets[_aktnap].range[_rangestr] := 'ÁTADÁS';

  // Ügyfél tranzakciók oszlopai:

  _rangestr := 'J4:M4';
  _oxl.worksheets[_aktnap].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Bold := true;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Italic := true;
  _oxl.worksheets[_aktnap].range[_rangestr] := 'ÜGYFÉL TRANZAKCIÓK';

  // Ügyfél átvétel oszlopok:

  _rangestr := 'J5:K5';
  _oxl.worksheets[_aktnap].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Bold := true;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Italic := true;
  _oxl.worksheets[_aktnap].range[_rangestr] := 'ÁTVÉTEL';

  // Ügyfél kifizetések oazkopai:

  _rangestr := 'L5:M5';
  _oxl.worksheets[_aktnap].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Bold := true;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Italic := true;
  _oxl.worksheets[_aktnap].range[_rangestr] := 'KIFIZETÉSEK';

  // Záró készletek:

  _rangestr := 'N4:O5';
  _oxl.worksheets[_aktnap].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_aktnap].range[_rangestr].VerticalAlignment := -4108;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Bold := true;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Italic := true;
  _oxl.worksheets[_aktnap].range[_rangestr] := 'ZÁRÓ KÉSZLETEK';

  _rangestr := 'D6:D6';
  _oxl.worksheets[_aktnap].range[_rangestr] := 'USD';

  _rangestr := 'E6:E6';
  _oxl.worksheets[_aktnap].range[_rangestr] := 'HUF';

  _rangestr := 'D6:D6';
  _oxl.worksheets[_aktnap].range[_rangestr] := 'USD';

  _rangestr := 'E6:E6';
  _oxl.worksheets[_aktnap].range[_rangestr] := 'HUF';

  _rangestr := 'D6:D6';
  _oxl.worksheets[_aktnap].range[_rangestr] := 'USD';

  _rangestr := 'E6:E6';
  _oxl.worksheets[_aktnap].range[_rangestr] := 'HUF';

  _rangestr := 'F6:F6';
  _oxl.worksheets[_aktnap].range[_rangestr] := 'USD';

  _rangestr := 'F6:F6';
  _oxl.worksheets[_aktnap].range[_rangestr] := 'HUF';

  _rangestr := 'G6:G6';
  _oxl.worksheets[_aktnap].range[_rangestr] := 'USD';

  _rangestr := 'G6:G6';
  _oxl.worksheets[_aktnap].range[_rangestr] := 'HUF';

  _rangestr := 'H6:H6';
  _oxl.worksheets[_aktnap].range[_rangestr] := 'USD';

  _rangestr := 'I6:I6';
  _oxl.worksheets[_aktnap].range[_rangestr] := 'HUF';

  _rangestr := 'J6:J6';
  _oxl.worksheets[_aktnap].range[_rangestr] := 'USD';

  _rangestr := 'K6:K6';
  _oxl.worksheets[_aktnap].range[_rangestr] := 'HUF';

  _rangestr := 'L6:L6';
  _oxl.worksheets[_aktnap].range[_rangestr] := 'USD';

  _rangestr := 'M6:M6';
  _oxl.worksheets[_aktnap].range[_rangestr] := 'HUF';

  _rangestr := 'N6:N6';
  _oxl.worksheets[_aktnap].range[_rangestr] := 'USD';

  _rangestr := 'O6:O6';
  _oxl.worksheets[_aktnap].range[_rangestr] := 'HUF';

  _oxl.worksheets[_aktnap].select;
  _range := _oxl.range['A7:A7'];
  _range.Select;

  // ------------------- KERETEZES ---------------------------------------------

  _ks := 'B4:C4';
  Vekonykeret(_ks,_aktnap);

  _ks := 'C5:C6';
  Vekonykeret(_ks,_aktnap);

  _ks := 'D4:E5';
  Vekonykeret(_ks,_aktnap);

  _ks := 'J4:M4';
  Vekonykeret(_ks,_aktnap);

  _ks := 'D6:D6';
  Vekonykeret(_ks,_aktnap);

  _ks := 'F6:F6';
  Vekonykeret(_ks,_aktnap);

  _ks := 'H5:I5';
  Vekonykeret(_ks,_aktnap);

  _ks := 'L5:M5';
  Vekonykeret(_ks,_aktnap);

  _ks := 'H6:H6';
  Vekonykeret(_ks,_aktnap);

  _ks := 'J6:J6';
  Vekonykeret(_ks,_aktnap);

  _ks := 'L6:L6';
  Vekonykeret(_ks,_aktnap);

  _ks := 'N6:N6';
  Vekonykeret(_ks,_aktnap);

  _ks := 'F5:G5';
  Vekonykeret(_ks,_aktnap);

  _ks := 'J5:K5';
  Vekonykeret(_ks,_aktnap);

  _ks := 'N4:O5';
  Vekonykeret(_ks,_aktnap);

  _ks := 'B4:O6';
  Vastagkeret(_ks,_aktnap);

  // ---------------------------------------------------------------

  _oxl.Activewindow.FreezePanes := True;

  _prisor := 8;
end;

// =============================================================================
           procedure TForm1.Vastagkeret(_rs: string; _sh: byte);
// =============================================================================

begin
  _oxl.worksheets[_sh].range[_rs].borderAround(1,4);
end;

// =============================================================================
          procedure TForm1.Vekonykeret(_rs: string; _sh: byte);
// =============================================================================

begin
  _oxl.worksheets[_sh].range[_rs].borderAround(1,2);
end;

// =============================================================================
               procedure TForm1.EgykorzetNapja;
// =============================================================================

begin
  _aktPtDarab := _korzetPenztarDarab[_korzetss];
  _pristr := inttostr(_prisor);

  _rangestr := 'B' + _pristr + ':C' + _pristr;
  _oxl.worksheets[_aktnap].range[_rangestr].Mergecells  := True;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Name   := 'Colibri';
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Size   := 11;
  _oxl.worksheets[_aktnap].range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_aktnap].range[_rangestr] := _aktkorzetnev + 'I KÖRZET';

  _startsor := _prisor + 1;
  _endsor   := _prisor + _aktPtDarab;
  _osszsor  := _endsor + 1;

  // pénztárszámok oszlopa

  _sstr := inttostr(_startsor);
  _estr := inttostr(_endsor);

  _rangestr := 'B' + _sstr + ':B' + _estr;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Name   := 'Colibri';
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Size   := 8;
  _oxl.worksheets[_aktnap].range[_rangestr].HorizontalAlignment := -4108;

  // pénztárnevek oszlopa:

  _rangestr := 'C' + _sstr + ':C' + _estr;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Name   := 'Colibri';
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Size   := 8;

  // A forgalmi adatok területe:

  _rangestr := 'D' + _sstr + ':O' + _estr;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Name   := 'Colibri';
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Size   := 8;
  _oxl.worksheets[_aktnap].range[_rangestr].Numberformat := '### ### ###';

  // A körzet összesen sora:

  _ostr := inttostr(_osszsor);
  _rangestr := 'B' + _ostr + ':C' + _ostr;
  _oxl.worksheets[_aktnap].range[_rangestr].Mergecells  := True;
  _oxl.worksheets[_aktnap].range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_aktnap].range[_rangestr] := _aktkorzetnev + ' ÖSSZESEN';

  _rangestr := 'B' + _ostr + ':O' + _ostr;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Name   := 'Colibri';
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Size   := 9;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Bold   := true;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Italic := true;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Color  := clRed;

  _rangestr := 'D' + _ostr + ':O' + _ostr;
  _oxl.worksheets[_aktnap].range[_rangestr].Numberformat := '### ### ###';


  EgynapiAdatfeltoltes;
  inc(_sumdarab);
  _sumsor[_sumdarab] := _osszsor;
  _prisor := _osszsor+2;
end;

// =============================================================================
           function TForm1.ScanKorzet(_knum: byte): byte;
// =============================================================================

begin
  result := 0;
  _y := 0;
  while _y<=9 do
    begin
      if _knum=_korzetsor[_y] then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
            function TForm1.ScanPenztar(_pnum: byte): byte;
// =============================================================================

begin
  result := 0;
  _y := 0;
  while _y<=_irodadarab do
    begin
      if _pnum=_penztarsor[_y] then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;


// =============================================================================
              procedure TForm1.EgyNapiAdatFeltoltes;
// =============================================================================

var _xsor: byte;

begin
  _xsor := _Startsor;
  _pp := 1;
  while _xsor<=_endsor do
    begin
      _aktpt := _korzetPenztarSor[_korzetss,_pp];
      _ptss := ScanPenztar(_aktpt);

      _oxl.worksheets[_aktnap].Cells[_xSor,2] := _aktpt;
      _oxl.worksheets[_aktnap].Cells[_xSor,3] := _penztarnev[_ptss];

      _usd := _zUsdNyito[_ptss,_aktnap];
      _huf := _zHufNyito[_ptss,_aktnap];
      _oxl.worksheets[_aktnap].Cells[_xSor,4] := _usd;
      _oxl.worksheets[_aktnap].Cells[_xSor,5] := _huf;

      _usd := _wUsdBankBe[_ptss,_aktnap];
      _huf := _wHufBankBe[_ptss,_aktnap];
      _oxl.worksheets[_aktnap].Cells[_xSor,6] := _usd;
      _oxl.worksheets[_aktnap].Cells[_xSor,7] := _huf;

      _usd := _wUsdBankKi[_ptss,_aktnap];
      _huf := _wHufBankKi[_ptss,_aktnap];
      _oxl.worksheets[_aktnap].Cells[_xSor,8] := _usd;
      _oxl.worksheets[_aktnap].Cells[_xSor,9] := _huf;

      _usd := _wUsdUgyfBe[_ptss,_aktnap];
      _huf := _wHufUgyfBe[_ptss,_aktnap];
      _oxl.worksheets[_aktnap].Cells[_xSor,10] := _usd;
      _oxl.worksheets[_aktnap].Cells[_xSor,11] := _huf;

      _usd := _wUsdUgyfki[_ptss,_aktnap];
      _huf := _wHufUgyfki[_ptss,_aktnap];
      _oxl.worksheets[_aktnap].Cells[_xSor,12] := _usd;
      _oxl.worksheets[_aktnap].Cells[_xSor,13] := _huf;

      _usd := _zUsdZaro[_ptss,_aktnap];
      _huf := _zHufZaro[_ptss,_aktnap];
      _oxl.worksheets[_aktnap].Cells[_xSor,14] := _usd;
      _oxl.worksheets[_aktnap].Cells[_xSor,15] := _huf;

      inc(_pp);
      inc(_xsor);
    end;

  _o1 := 68;
  while _o1<=79 do
    begin
      _rangestr := chr(_o1) + _sstr + ':' + chr(_o1) + _estr;
      _formula := '=Sum(' + _rangestr +')';
      _oRangestr := chr(_o1)+_ostr + ':' + chr(_o1) + _ostr;
      _oxl.worksheets[_aktnap].range[_orangestr].Formula := _formula;
      inc(_o1);
    end;
end;

// =============================================================================
            function TForm1.Nulele(_num: byte): string;
// =============================================================================

begin
  result := inttostr(_num);
  if _num<10 then result := '0' + result;
end;

procedure TForm1.CegosszesenSor;

var _rovnev: string;

begin
  dec(_prisor);

  _cegSumSor := _prisor;
  _cstr      := inttostr(_cegsumSor);
  _rovnev    := _cegrovnev[_cegss];

  _rangestr  := 'B' + _cstr + ':C' + _cstr;
  _oxl.worksheets[_aktnap].range[_rangestr].Mergecells  := True;
  _oxl.worksheets[_aktnap].range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_aktnap].range[_rangestr] := _rovnev + ' ÖSSZESEN';

  _rangestr  := 'B' + _cstr + ':O' + _cstr;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Bold   := true;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Italic := true;
  _oxl.worksheets[_aktnap].range[_rangestr].Font.Color  := $FF3030;

  _rangestr  := 'D' + _cstr + ':O' + _cstr;
  _oxl.worksheets[_aktnap].range[_rangestr].NumberFormat := '### ### ###';

  // ----------------------------------------------------------------------

  _o1 := 68;
  while _o1<=79 do
    begin
      _formula := '=Sum(';
      _sss := 1;
      while _sss<=_sumdarab do
        begin
          _aktsor := _sumsor[_sss];
          _as := inttostr(_aktsor);
          _formula := _formula + chr(_o1)+_as;
          inc(_sss);
          if _sss<=_sumdarab then _formula := _formula + '+';
        end;

      _oRangestr := chr(_o1)+_cstr + ':' + chr(_o1) + _cstr;
      _oxl.worksheets[_aktnap].range[_orangestr].Formula := _formula;
      inc(_o1);
    end;
    _sumdarab := 0;
  _prisor := _prisor + 2;

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
      //    break;
        end;

      _Looper := Process32Next(_handle,_proc);
    end;
  CloseHandle(_handle);
end;


procedure TForm1.EVCOMBOChange(Sender: TObject);
begin
  Activecontrol := startgomb;
end;

// =============================================================================
                   procedure TForm1.penztarwudata;
// =============================================================================

begin
  if _aktfoe=5 then
    begin
      if (_akttranz='+B') AND (_aktdnem='USD') then
        begin
          _wUsdUgyfBe[_ptss,_aktnap] := _wUsdUgyfBe[_ptss,_aktnap] + _aktbankjegy;
        end;

      if (_akttranz='-K') AND (_aktdnem='USD') then
        begin
          _wUsdUgyfKi[_ptss,_aktnap] := _wUsdUgyfKi[_ptss,_aktnap] + _aktbankjegy;
        end;

      if (_akttranz='+B') AND (_aktdnem='HUF') then
        begin
          _wHufUgyfBe[_ptss,_aktnap] := _wHufUgyfBe[_ptss,_aktnap] + _aktbankjegy;
        end;

      if (_akttranz='-K') AND (_aktdnem='HUF') then
        begin
          _wHufUgyfKi[_ptss,_aktnap] := _wHufUgyfKi[_ptss,_aktnap] + _aktbankjegy;
        end;
    end;

    // -------------------------------------------------------------

  if _aktfoe<5 then
    begin
      if (_akttranz='+B') AND (_aktdnem='USD') then
        begin
          _wUsdBankBe[_ptss,_aktnap] := _wUsdBankBe[_ptss,_aktnap] + _aktbankjegy;
        end;

      if (_akttranz='-K') AND (_aktdnem='USD') then
        begin
          _wUsdBankKi[_ptss,_aktnap] := _wUsdBankKi[_ptss,_aktnap] + _aktbankjegy;
        end;

      if (_akttranz='+B') AND (_aktdnem='HUF') then
        begin
          _wHufBankBe[_ptss,_aktnap] := _wHufBankBe[_ptss,_aktnap] + _aktbankjegy;
        end;

      if (_akttranz='-K') AND (_aktdnem='HUF') then
        begin
          _wHufBankKi[_ptss,_aktnap] := _wHufBankKi[_ptss,_aktnap] + _aktbankjegy;
        end;
    end;
end;


procedure TForm1.ertektarWuData;

begin
  if leftstr(_aktsorszam,2)='WK' then
    begin
      if _aktDnem='USD' then _wUsdBankki[_ptss,_aktnap] := _wusdBankki[_ptss,_aktnap] + _aktbankjegy;
      if _aktdnem='HUF' then _wHufBankki[_ptss,_aktnap] := _wHufBankKi[_ptss,_aktnap] + _aktbankjegy;
    end;

  if leftstr(_aktsorszam,2)='WB' then
    begin
      if _aktDnem='USD' then _wUsdBankBe[_ptss,_aktnap] := _wusdBankBe[_ptss,_aktnap] + _aktbankjegy;
      if _aktdnem='HUF' then _wHufBankBe[_ptss,_aktnap] := _wHufBankBe[_ptss,_aktnap] + _aktbankjegy;
    end;
end;

end.
