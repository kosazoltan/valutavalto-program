unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, TlHelp32, DateUtils, Buttons, Strutils, IBDatabase,
  DB, IBQuery, IBCustomDataSet, IBTable, ComCtrls, Comobj, ExtCtrls;

type
  TForm2 = class(TForm)
    EvCombo     : TComboBox;
    HoCombo     : TComboBox;

    Memo        : TMemo;
    StartGomb   : TBitBtn;
    KilepGomb   : TBitBtn;

    VTabla      : TIBTable;
    VQuery      : TIBQuery;
    VDbase      : TIBDatabase;
    VTRANZ      : TIBTransaction;

    RecQuery    : TIBQuery;
    RecDbase    : TIBDatabase;
    RecTranz    : TIBTransaction;

    ArtQuery    : TIBQuery;
    ArtDbase    : TIBDatabase;
    ArtTranz    : TIBTransaction;

    NapCsuszka  : TProgressBar;
    IrodaCsuszka: TProgressBar;

    Label1      : TLabel;
    Label2      : TLabel;

    Shape1      : TShape;
    Shape2      : TShape;
    Shape3      : TShape;
    Shape4      : TShape;

    procedure AdatUrito;
    procedure CegosszesenSor;
    procedure ElsejePotlasa;
    procedure ExcelKill;
    procedure EgyNapiAdatFeltoltes;
    procedure EgykorzetNapja;
    procedure ErtektarWuData;
    procedure EvComboChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure HaviWesternTablo;
    procedure HibaWrite(_hibass: byte);
    procedure KilepGombClick(Sender: TObject);
    procedure Korzetbesorolas;
    procedure MakeExcel;
    procedure Napifejlec;
    procedure PenztarWuData;
    procedure SetPenztarsor;
    procedure StartGombClick(Sender: TObject);
    procedure Vastagkeret(_rs: string; _sh: byte);
    procedure Vekonykeret(_rs: string; _sh: byte);

    function AdatEllenorzes: boolean;
    function Getcegss(_bt: string): byte;
    function Getkorzetss(_kn: byte): byte;
    function Nulele(_num: byte): string;
    function ScanPenztar(_pnum: byte): byte;
    function ScanKorzet(_knum: byte): byte;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2        : TForm2;

  _proc        : PROCESSENTRY32;
  _handle      : HWND;

  _cegsor      : array[1..2] of string = ('B','Z');
  _cegnevek    : array[1..2] of string = ('EXCLUSIVE BEST CHANGE KFT.',
                                      'EXPRESSZ ÉKSZERHÁZ ÉS MINIBANK KFT.');
  _cegrovnev   : array[1..2] of string = ('BEST CHANGE','EXPRESSZ');
   _korzetnevek: array[1..9] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
       'DEBRECEN','NYIREGYHÁZ','BÉKÉSCSABA','PÉCS','KAPOSVÁR','EXPRESSZ');

  _cegkorzetDarab: array[1..2] of byte = (8,1);
  _cegkorzetSor  : array[1..2,1..8] of byte = ((20,40,50,63,75,10,120,145),
                               (180,0,0,0,0,0,0,0));

  _korzetsor         : array[1..9] of byte = (10,20,40,50,63,75,120,145,180);
  _korzetPenztarDarab: array[1..9] of byte;
  _korzetPenztarsor  : array[1..9,1..150] of byte;

  _penztarsor,_ptkorzet,_ptkft: array[1..180] of byte;
  _penztarnev,_ptstatus: array[1..180] of string;

  _zUsdNyito,_zUsdZaro,_zUsdBe,_zUsdKi: array[1..180,1..31] of integer;
  _zHufNyito,_zHufZaro,_zHufBe,_zHufKi: array[1..180,1..31] of integer;

  _wUsdUgyfBe,_wUsdUgyfKi,_wHufUgyfBe,_wHufUgyfKi: array[1..180,1..31] of integer;
  _wUsdBankBe,_wUsdBankKi,_wHufBankBe,_wHufBankKi: array[1..180,1..31] of integer;

  _honev: array[1..12] of string = ('JANUAR','FEBRUAR','MARCIUS','APRILIS','MAJUS',
           'JUNIUS','JULIUS','AUGUSZTUS','SZEPTEMBER','OKTOBER','NOVEMBER',
                                                                    'DECEMBER');
  _sumsor: array[1..80] of integer;

  _oxl,_owb,_range      : olevariant;
  _O1,_sumdarab,_sss,_ho: byte;

  _prisor,_startsor,_endsor,_osszsor,_usd,_huf,_cegSumsor,_aktsor      : integer;

  _aktdatums,_rangestr,_ks,_pristr,_sstr,_estr,_ostr,_cstr,_aktsorszam : string;
  _aktkorzetnev,_excelnev,_excelPath,_formula,_orangestr,_as           : string;

  _pt,_ptss,_korzetnum,_korzetss,_cegss,_y,_irodadarab,_aktpt,_xnap    : byte;
  _aktkorzetss,_aktcegss,_aktnap,_aktfoe,_havinap,_utnap,_aktptdarab   : byte;
  _penztardarab,_aktdarab,_pp,_aktkorzetdarab,_ptkorzetss,_aktkorzetnum: byte;


  _pcs,_ptnev,_cegbetu,_farok,_wzar,_wuni,_aktptnev,_aktfdbpath,_pmess: string;
  _vdatum,_aktdnem,_akttranz,_mess,_utDatum,_elodatums,_aktcegnev     : string;
  _aktstatus: string;
  _sorveg: string = chr(13)+chr(10);

  _vUsdnyito,_vUsdZaro,_vHufNyito,_vHufZaro,_aktbankjegy,_hiba        : integer;
  _vUsdBe,_vUsdKi,_vHufbe,_vHufki                                     : integer;
  _utUsdZaro,_utHufZaro,_ugyfUsdBe,_ugyfHufBe,_ugyfUsdki,_ugyfHufKi   : integer;
  _maiUsdNyito,_maiHufNyito,_usdbe,_usdki,_hufbe,_hufki,_bankHufKi    : integer;
  _szamUsdZaro,_szamHufZaro,_bankUsdBe,_bankHufbe,_bankUsdki          : integer;
  _forgUsdBe,_forgUsdKi,_forgHufbe,_forgHufki,_evindex,_hoindex       : integer;

  _aktev,_aktho,_top,_left,_height,_width,_targyev,_targyho           : word;

  _vanexcel,_looper: boolean;


function westernforgalom: integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
            function WesternForgalom: integer; stdcall;
// =============================================================================

begin
  Form2  := TForm2.Create(Nil);
  Result := Form2.showmodal;
  Form2.free;
end;


// =============================================================================
             procedure TForm2.FormActivate(Sender: TObject);
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

  EvCombo.Items.clear;
  EvCombo.Clear;

  EvCombo.Items.add(inttostr(_aktev-1));
  EvCombo.Items.Add(inttostr(_aktev));
  EvCombo.ItemIndex := 1;

  HoCombo.Items.clear;
  HoCombo.clear;
  _ho := 1;

  while _ho<=12 do
    begin
      HoCombo.Items.Add(_honev[_ho]);
      inc(_ho);
    end;

  if _aktHo=1 then
    begin
      EvCombo.ItemIndex := 0;
      HoCombo.ItemIndex := 11;
    end else
    begin
      HoCombo.ItemIndex := _aktHo-1;
    end;
  ActiveControl := StartGomb;
end;

// =============================================================================
          procedure TForm2.StartGombClick(Sender: TObject);
// =============================================================================

begin

  _evindex := EvCombo.ItemIndex;
  _hoIndex := HoCombo.ItemIndex;

  if (_evIndex=1) and ((1+_hoIndex)>_aktHo) then
    begin
      ShowMessage('A KÉRT HÓNAP A JÖVÕBEN LESZ');
      exit;
    end;

   StartGomb.Enabled := false;
   Memo.Lines.Add('    MEGKEZDEM AZ ELLENÕRZÉST');
   ActiveControl := Kilepgomb;
   _targyEv := _aktEv-1 + _evIndex;
   _targyHo := 1 + _hoIndex;

   _eloDatums := inttostr(_targyEv) + '.' + nulele(_targyHo) + '.';
   _farok     := midstr(_eloDatums,3,2) + midstr(_eloDatums,6,2);

   _haviNap := DaysInAMonth(_targyEv,_targyHo);
   if (_targyEv=_aktEv) AND (_targyHo=_aktHo) then _haviNap := dayof(date);

  _wZar := 'WZAR' + _farok;
  _wUni := 'WUNI' + _farok;

  _vanExcel := False;

  HaviWesternTablo;
end;


// =============================================================================
                     procedure TForm2.HaviWesternTablo;
// =============================================================================

begin
  SetPenztarSor;
  AdatUrito;
  KorzetbeSorolas;

  _ptss := 1;
  while _ptss<=_irodaDarab do
    begin
      _aktPt       := _penztarSor[_ptss];
      _aktPtNev    := _penztarNev[_ptss];
      _aktKorzetSs := _ptKorzet[_ptss];
      _aktCegSs    := _ptKft[_ptss];
      _aktstatus   := _ptStatus[_ptss];

      if _aktPt<151 then
        _aktFdbPath  := 'c:\receptor\database\v' + inttostr(_aktPt) + '.fdb'
      else
        _aktFdbPath  := 'c:\Cartcash\database\v' + inttostr(_aktPt) + '.fdb';

      with vDbase do
        begin
          close;
          databaseName := _aktFdbPath;
          connected    := True;
        end;

      vTabla.Close;
      vTabla.TableName := _wZar;
      if not vTabla.Exists then
        begin
          vDbase.Close;
          inc(_ptSs);
          Continue;
        end;

      _pcs := 'SELECT * FROM ' + _wzar + _sorVeg;
      _pcs := _pcs + 'ORDER BY DATUM';

      with vQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
        end;

      _utDatum := vQuery.FieldByName('DATUM').asString;
      _utNap   := strtoint(midstr(_utDatum,9,2));

      _utUsdZaro := vQuery.FieldByName('USDNYITO').asInteger;
      _utHufZaro := vQuery.FieldByNAme('HUFNYITO').asInteger;

      if _utNap>1 then ElsejePotlasa;
      _utNap := 0;

      while not vQuery.Eof do
        begin
          _vDatum := vQuery.FieldByName('DATUM').asString;
          _aktNap := strtoint(midstr(_vDatum,9,2));
          if (_aktNap-1)>_utNap then
            begin
              _xNap := _utNap+1;
              while _xNap<_aktNap do
                begin
                  _zUsdNyito[_ptss,_xnap] := _utUsdZaro;
                  _zHufNyito[_ptss,_xnap] := _utHufZaro;
                  _zUsdZaro[_ptss,_xnap]  := _utUsdZaro;
                  _zHufZaro[_ptss,_xnap]  := _utHufZaro;
                  inc(_xNap);
                end;
            end;
          _utNap := _aktNap;

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

          _zUsdNyito[_ptSs,_aktNap] := _vUsdNyito;
          _zUsdZaro[_ptSs,_aktNap]  := _vUsdZaro;
          _zUsdBe[_ptSs,_aktNap]    := _vUsdBe;
          _zUsdKi[_ptSs,_aktNap]    := _vUsdKi;

          _zHufNyito[_ptSs,_aktNap] := _vHufNyito;
          _zHufZaro[_ptSs,_aktNap]  := _vHufZaro;
          _zHufBe[_ptSs,_aktNap]    := _vHufBe;
          _zHufKi[_ptSs,_aktNap]    := _vHufKi;
          vQuery.next;
        end;
      vQuery.close;

      if _aktNap<_haviNap then
        begin
          _xNap := _aktNap+1;
          while _xNap<=_haviNap do
            begin
              _zUsdNyito[_ptss,_xnap] := _utUsdZaro;
              _zHufNyito[_ptss,_xnap] := _utHufZaro;
              _zUsdZaro[_ptss,_xnap]  := _utUsdZaro;
              _zHufZaro[_ptss,_xnap]  := _utHufZaro;
              inc(_xNap);
            end;
        end;

      // --------------------------------------

      vTabla.Close;
      vTabla.TableName := _wuni;
      if not vTabla.Exists then
        begin
          vDbase.close;
          inc(_ptSs);
          Continue;
        end;

      _pcs := 'SELECT * FROM ' + _wuni + _sorveg;
      _pcs := _pcs + 'WHERE STORNO=1' + _sorveg;
      _pcs := _pcs + 'ORDER BY DATUM';

      with vQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
        end;

      while not vQuery.Eof do
        begin
          _vDatum      := vQuery.FieldByName('DATUM').asString;
          _aktNap      := strtoint(midstr(_vDatum,9,2));
          _aktfoe      := vQuery.FieldByNAme('FOEGYSEG').asInteger;
          _aktDnem     := vQuery.Fieldbyname('VALUTANEM').asString;
          _aktTranz    := vQuery.FieldByNAme('TRANZAKCIOTIPUS').asString;
          _aktBankJegy := vQuery.FieldByName('BANKJEGY').asInteger;
          _aktsorszam  := vQuery.FieldByName('SORSZAM').asString;

          // -------------------------------------------------------------

          if _aktstatus='P' then PenztarWuData else ErtektarWudata;



          vQuery.Next;
        end;

      vQuery.Close;
      vDbase.Close;
      inc(_ptSs);
    end;

  if not AdatEllenorzes then
    begin
      Memo.Lines.Add('  ');
      Memo.Lines.Add('       HIBÁS ADATOKAT TALÁLTAM !');
      Exit;
    end Else
    begin
      Memo.Lines.add('       A HAVI ADATOK HIBÁTLANOK');
      Sleep(4000);
    end;

  Memo.Clear;
  Memo.Lines.Clear;
  Memo.Font.Size := 12;
  Memo.Font.Style := [];
  MakeExcel;
end;

// =============================================================================
                      procedure TForm2.PenztarWUdata;
// =============================================================================

begin
  if _aktFoe=5 then
    begin
      if (_aktTranz='+B') AND (_aktDnem='USD') then
        begin
          _wUsdUgyfBe[_ptss,_aktNap] := _wUsdUgyfBe[_ptss,_aktNap] + _aktBankJegy;
        end;

      if (_aktTranz='-K') AND (_aktDnem='USD') then
        begin
          _wUsdUgyfKi[_ptSs,_aktNap] := _wUsdUgyfKi[_ptSs,_aktNap] + _aktBankJegy;
        end;

      if (_aktTranz='+B') AND (_aktDnem='HUF') then
        begin
          _wHufUgyfBe[_ptSs,_aktNap] := _wHufUgyfBe[_ptSs,_aktNap] + _aktBankJegy;
        end;

      if (_aktTranz='-K') AND (_aktDnem='HUF') then
        begin
          _wHufUgyfKi[_ptSs,_aktNap] := _wHufUgyfKi[_ptSs,_aktNap] + _aktBankJegy;
        end;
    end;

  // -------------------------------------------------------------

  if _aktFoe<5 then
    begin
      if (_aktTranz='+B') AND (_aktDnem='USD') then
        begin
          _wUsdBankBe[_ptSs,_aktNap] := _wUsdBankBe[_ptSs,_aktNap] + _aktBankJegy;
        end;

      if (_aktTranz='-K') AND (_aktDnem='USD') then
        begin
          _wUsdBankKi[_ptSs,_aktNap] := _wUsdBankKi[_ptSs,_aktNap] + _aktBankJegy;
        end;

      if (_aktTranz='+B') AND (_aktDnem='HUF') then
        begin
          _wHufBankBe[_ptSs,_aktNap] := _wHufBankBe[_ptSs,_aktNap] + _aktBankJegy;
        end;

      if (_aktTranz='-K') AND (_aktDnem='HUF') then
        begin
          _wHufBankKi[_ptSs,_aktNap] := _wHufBankKi[_ptSs,_aktNap] + _aktBankJegy;
        end;
    end;
end;

// =============================================================================
                      procedure TForm2.ErtektarWUdata;
// =============================================================================

begin
  if leftstr(_aktsorszam,2)='WB' then
    begin
      if _aktdnem='USD' then _wUsdBankBe[_ptss,_aktnap] := _wUsdBankBe[_ptss,_aktnap] + _aktbankjegy;
      if _aktdnem='HUF' then _wHufBankBe[_ptss,_aktnap] := _wHufBankBe[_ptss,_aktnap] + _aktbankjegy;
    end;

  if leftstr(_aktsorszam,2)='WK' then
    begin
      if _aktdnem='USD' then _wUsdBankKi[_ptss,_aktnap] := _wUsdBankKi[_ptss,_aktnap] + _aktbankjegy;
      if _aktdnem='HUF' then _wHufBankKi[_ptss,_aktnap] := _wHufBankKi[_ptss,_aktnap] + _aktbankjegy;
    end;
end;


// =============================================================================
                      procedure TForm2.SetPenztarSor;
// =============================================================================

begin
  _ptSs := 0;

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE (WESTERNUNION=1) AND (CLOSED=' + chr(39) + 'N' + chr(39) +')'+_sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  RecDbase.Connected := True;
  with RecQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
    end;

  while not RecQuery.eof do
    begin
      _pt := RecQuery.FieldByNAme('UZLET').asInteger;
      if _pt>150 then break;
      
      _ptNev := trim(RecQuery.FieldByNAme('KESZLETNEV').asString);
      _korzetNum := RecQuery.FieldByNAme('ERTEKTAR').asInteger;
      _cegBetu := RecQuery.FieldByNAme('CEGBETU').asString;
      _aktstatus := Recquery.FieldByName('STATUS').asString;

      _korzetSs := GetKorzetSs(_korzetNum);
      _cegSs    := GetCegSs(_cegBetu);

      inc(_ptSs);

      _penztarSor[_ptSs] := _pt;
      _penztarNev[_ptSs] := _ptNev;
      _ptKorzet[_ptSs]   := _korzetSs;
      _ptKft[_ptSs]      := _cegSs;
      _ptStatus[_ptss]   := _aktstatus;

      RecQuery.Next;
    end;

  RecQuery.Close;
  RecDbase.Close;

  // ------------------------------------------

  ArtDbase.Connected := True;
  with ArtQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
    end;

  while not ArtQuery.Eof do
    begin
      _pt    := ArtQuery.FieldByName('UZLET').asInteger;
      _ptNev := trim(ArtQuery.FieldByName('KESZLETNEV').asString);

      inc(_ptSs);

      _penztarSor[_ptSs] := _pt;
      _penztarNev[_ptSs] := _ptNev;
      _ptKorzet[_ptSs]   := 9;
      _ptKft[_ptSs]      := 2;
      _ptStatus[_ptss]   := 'P';

      ArtQuery.Next;
    end;

  ArtQuery.Close;
  ArtDbase.Close;

  _irodaDarab := _ptSs;
end;

// =============================================================================
                 procedure TForm2.KorzetbeSorolas;
// =============================================================================

begin
  _ptSs := 1;

  while _ptSs<=_irodaDarab do
    begin
      _aktPt     := _penztarSor[_ptSs];
      _korzetSs  := _ptKorzet[_ptSs];
      _aktDarab  := _korzetPenztarDarab[_korzetSs];

      inc(_aktDarab);

      _korzetPenztarDarab[_korzetSs]         := _aktDarab;
      _korzetPenztarSor[_korzetSs,_aktDarab] := _aktPt;
      inc(_ptSs);
    end;
end;


// =============================================================================
              function TForm2.GetKorzetSs(_kn: byte): byte;
// =============================================================================

begin
  Result := 0;

  _y := 1;
  while _y<=9 do
    begin
      if _korzetSor[_y]=_kn then
        begin
          Result := _y;
          Exit;
        end;

      inc(_y);
    end;
end;

// =============================================================================
               function TForm2.GetCegSs(_bt: string): byte;
// =============================================================================

begin
  Result := 0;
  _y := 1;

  while _y<=4 do
    begin
      if _cegSor[_y]=_bt then
        begin
          Result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
                            procedure TForm2.AdatUrito;
// =============================================================================

begin
  _ptSs := 1;
  while _ptSs<=_irodaDarab do
    begin
      _aktnap := 1;
      while _aktnap<=31 do
        begin
          _zUsdNyito[_ptSs,_aktNap] := 0;
          _zUsdZaro[_ptSs,_aktNap]  := 0;
          _zUsdBe[_ptSs,_aktNap]    := 0;
          _zUsdKi[_ptSs,_aktNap]    := 0;

          _zHufNyito[_ptSs,_aktNap] := 0;
          _zHufZaro[_ptSs,_aktNap]  := 0;
          _zHufBe[_ptSs,_aktNap]    := 0;
          _zHufKi[_ptSs,_aktNap]    := 0;

          _wUsdUgyfBe[_ptSs,_aktNap] := 0;
          _wUsdUgyfKi[_ptSs,_aktNap] := 0;
          _wUsdBankBe[_ptSs,_aktNap] := 0;
          _wUsdBankKi[_ptSs,_aktNap] := 0;

          _wHufUgyfBe[_ptSs,_aktNap] := 0;
          _wHufUgyfKi[_ptSs,_aktNap] := 0;
          _wHufBankBe[_ptSs,_aktNap] := 0;
          _wHufBankKi[_ptSs,_aktNap] := 0;

          inc(_aktNap);
        end;

      inc(_ptSs);
    end;

  _korzetSs := 1;
  while _korzetSs<=9 do
    begin
      _korzetPenztarDarab[_korzetSs] := 0;
      _pp := 1;
      while _pp<=150 do
        begin
          _korzetPenztarSor[_korzetSs,_pp] := 0;
          inc(_pp);
        end;
      inc(_korzetSs);
    end;
end;

// =============================================================================
                 function TForm2.AdatEllenorzes: boolean;
// =============================================================================

begin
  Memo.Clear;
  Memo.Lines.Clear;
  Memo.Font.Size := 12;

  Result := False;
  _ptSs  := 1;
  _hiba  := 0;

  NapCsuszka.Min       := 1;
  NapCsuszka.Max       := _haviNap;
  NapCsuszka.Visible   := True;

  irodaCsuszka.Min     := 1;
  irodaCsuszka.Max     := _irodaDarab;
  IrodaCsuszka.Visible := True;

  while _ptSs<=_irodaDarab do
    begin
      IrodaCsuszka.Position := _ptSs;
      _aktNap    := 1;
      _utUsdZaro := _zusdnyito[_ptSs,1];
      _uthufZaro := _zhufnyito[_ptSs,1];

      while _aktNap<=_haviNap do
        begin
          NapCsuszka.Position := _aktNap;
          _maiUsdNyito := _zUsdNyito[_ptSs,_aktNap];
          _maiHufNyito := _zHufNyito[_ptSs,_aktNap];

          if _maiUsdNyito<>_utUsdZaro then HibaWrite(1);
          if _maiHufNyito<>_utHufZaro then HibaWrite(2);

          _usdBe := _zUsdBe[_ptSs,_aktNap];
          _usdKi := _zUsdKi[_ptSs,_aktNap];
          _hufBe := _zHufBe[_ptSs,_aktNap];
          _hufKi := _zHufKi[_ptSs,_aktNap];

          _szamUsdZaro := _maiUsdNyito + _usdBe - _usdKi;
          _szamHufZaro := _maiHufNyito + _hufBe - _hufki;

          _utUsdZaro := _zUsdZaro[_ptSs,_aktNap];
          _utHufZaro := _zhufZaro[_ptSs,_aktNap];

          if _utUsdZaro<>_szamUsdZaro then HibaWrite(3);
          if _utHufZaro<>_szamHufZaro then HibaWrite(4);

          _bankUsdBe := _wUsdBankBe[_ptSs,_aktNap];
          _bankHufBe := _wHufBankBe[_ptSs,_aktNap];
          _bankUsdKi := _wUsdBankKi[_ptSs,_aktNap];
          _bankHufKi := _wHufBankKi[_ptSs,_aktNap];

          _ugyfUsdBe := _wUsdUgyfBe[_ptSs,_aktNap];
          _ugyfHufBe := _wHufUgyfBe[_ptSs,_aktNap];
          _ugyfUsdKi := _wUsdUgyfKi[_ptSs,_aktNap];
          _ugyfHufKi := _wHufUgyfKi[_ptSs,_aktNap];

          _forgUsdBe := _bankUsdBe + _ugyfUsdBe;
          _forgUsdKi := _bankUsdKi + _ugyfUsdKi;
          _forgHufBe := _bankHufbe + _ugyfHufBe;
          _forgHufKi := _bankHufKi + _ugyfHufKi;

          if _UsdBe<>(_ugyfUsdbe + _bankUsdbe) then HibaWrite(5);
          if _HufBe<>(_ugyfHufbe + _bankHufbe) then HibaWrite(6);
          if _UsdKi<>(_ugyfUsdKi + _bankUsdKi) then HibaWrite(7);
          if _HufKi<>(_ugyfHufKi + _bankHufKi) then HibaWrite(8);

          inc(_aktNap);
        end;
      inc(_ptSs);
    end;

  irodaCsuszka.Visible   := False;
  napCsuszka.Visible     := False;

  if _hiba=0 then result := True;
end;

// =============================================================================
                procedure TForm2.HibaWrite(_hibass: byte);
// =============================================================================

begin
  Inc(_hiba);
  _mess := _penztarNev[_ptSs] + ' ' + inttostr(_aktNap)+'. napján';
  Memo.Lines.Add(_mess);

  case _hibaSs of
    1: _mess := 'USD nyitó nem azonos az elözõ napi záróval';
    2: _mess := 'HUF nyitó nem azonos az elözõ napi záróval';
    3: _mess := 'USD számitott záró nem egyezik a tényleges záróval';
    4: _mess := 'HUF számitott záró nem egyezik a tényleges záróval';
    5: _mess := 'Ügyfél és Banki USD bevétel nem azonos az USD bevétellel';
    6: _mess := 'Ügyfél és Banki HUF bevétel nem azonos az HUF bevétellel';
    7: _mess := 'Ügyfél és Banki USD kiadás nem azonos az USD kiadással';
    8: _mess := 'Ügyfél és Banki HUF kiadás nem azonos az HUF kiadással';
  end;
  Memo.Lines.Add(_mess);
end;

// =============================================================================
               procedure TForm2.KilepGombClick(Sender: TObject);
// =============================================================================

begin
  if _vanExcel then
    begin
      _oxl.Quit;
      _oxl := UnAssigned;
      ExcelKill;
    end;

  Modalresult :=1;
end;

// =============================================================================
               procedure TForm2.ElsejePotlasa;
// =============================================================================

begin
  _xNap := 1;
  while _xNap<_utNap do
    begin
      _zUsdNyito[_ptss,_xNap] := _utUsdZaro;
      _zHufNyito[_ptss,_xNap] := _utHufZaro;
      _zUsdZaro[_ptss,_xNap]  := _utUsdZaro;
      _zHufZaro[_ptss,_xNap]  := _utHufZaro;
      inc(_xNap);
    end;
end;

// =============================================================================
                      procedure TForm2.MakeExcel;
// =============================================================================

var i: byte;

begin
   _oxl := CreateOleObject('Excel.Application');
   _owb := _oxl.Workbooks.Add[1];

   _vanExcel := True;

  // --------------  A 31 fül létrehozása és elnevezése ------------------------

   _oxl.Workbooks[1].Sheets.Add(,,31);
   For i := 1 to 31 do
       _oxl.Workbooks[1].Worksheets[i].Name := inttostr(i);

  // --------------------------------------------------------------------------

   NapCsuszka.Max := _haviNap;
   Memo.Lines.Add('AZ EXCELTÁBLA ÖSSZEÁLLÍTÁSA');

   // _munkanap: elsejétõl a hó utolsó napjáig:

   _aktNap := 1;
   _priSor := 1;
   while _aktnap<=_havinap do
     begin
       _aktDatums := _eloDatums + nulele(_aktNap);

       Memo.Lines.Add('    ');
       Memo.Lines.Add(_aktDatums+' beirása az exceltáblába');

       NapCsuszka.Visible  := True;
       NapCsuszka.Position := _aktNap;

       _priSor := 1;

       NapiFejlec;

       _priSor := 8;
       _cegSs  := 1;

       while _cegSs<=2 do
         begin
           _aktCegNev := _cegNevek[_cegSs];
           _priStr    := inttostr(_priSor);
           _rangeStr  := 'B' + _priStr + ':O' + _priStr;
           _sumDarab  := 0;
           _oxl.WorkSheets[_aktNap].range[_rangeStr].Mergecells := True;
           _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Name  := 'Calibri';
           _oxl.WorkSheets[_aktnap].range[_rangeStr].Font.Size  := 14;
           _oxl.WorkSheets[_aktnap].range[_rangeStr].Font.Bold  := True;
           _oxl.WorkSheets[_aktnap].range[_rangeStr].Font.Italic:= True;
           _oxl.WorkSheets[_aktnap].range[_rangeStr].HorizontalAlignment := -4108;
           _oxl.WorkSheets[_aktnap].range[_rangeStr] := _aktCegNev;

           inc(_priSor);

           _aktKorzetDarab      := _cegKorzetDarab[_cegSs];
           _ptKorzetSs          := 1;
           IrodaCsuszka.Max     := _aktkorzetDarab;
           IrodaCsuszka.Visible := True;

           while _ptKorzetSs<=_aktKorzetDarab do
             begin
               IrodaCsuszka.Position := _ptKorzetSs;
               _aktKorzetNum         := _cegKorzetSor[_cegSs,_ptKorzetSs];
               _korzetSs             :=  scanKorzet(_aktKorzetNum);
               _aktKorzetNev         := _korzetNevek[_korzetSs];

               Memo.Lines.Add(_aktKorzetNev);
               EgyKorzetNapja;
               inc(_ptKorzetSs);
             end;

           CegOsszesenSor;

           inc(_cegSs);
         end;
       inc(_aktNap);
     end;

  _excelNev  := 'WU' + inttostr(_targyEv) + Nulele(_targyHo) + '.xls';
  _excelPath := 'c:\receptor\mail\posta\' + _excelNev;

  if FileExists(_excelPath) then DeleteFile(_excelPath);

  _owb.SaveAs(_excelPath);
  _oxl.Visible := True;

  IrodaCsuszka.Visible := False;
  NapCsuszka.Visible   := False;

  Memo.clear;
  Memo.Lines.Clear;

  Memo.Lines.Add('Az exceltáblát mentettem '+ _excelPath + '-ba');
end;

// =============================================================================
                  procedure TForm2.NapiFejlec;
// =============================================================================

var _foCim: string;

begin
  _oxl.WorkSheets[_aktNap].range['A1:A1'].ColumnWidth := 2;
  _oxl.WorkSheets[_aktNap].range['B1:B1'].ColumnWidth := 10;
  _oxl.WorkSheets[_aktNap].range['C1:C1'].ColumnWidth := 30;
  _oxl.WorkSheets[_aktNap].range['D1:D1'].ColumnWidth := 10;
  _oxl.WorkSheets[_aktNap].range['E1:E1'].ColumnWidth := 10;
  _oxl.WorkSheets[_aktNap].range['F1:F1'].ColumnWidth := 10;
  _oxl.WorkSheets[_aktNap].range['G1:G1'].ColumnWidth := 10;
  _oxl.WorkSheets[_aktNap].range['H1:H1'].ColumnWidth := 10;
  _oxl.WorkSheets[_aktNap].range['I1:I1'].ColumnWidth := 10;
  _oxl.WorkSheets[_aktNap].range['J1:J1'].ColumnWidth := 10;
  _oxl.WorkSheets[_aktNap].range['K1:K1'].ColumnWidth := 10;
  _oxl.WorkSheets[_aktNap].range['L1:L1'].ColumnWidth := 10;
  _oxl.WorkSheets[_aktNap].range['M1:M1'].ColumnWidth := 10;
  _oxl.WorkSheets[_aktNap].range['O1:O1'].ColumnWidth := 10;

  // ---------------------------------------------------------------------------

  _foCim := 'WESTERN UNION HAVI ADATAI '+ inttostr(_targyEv)+' '+_honev[_targyHo];
  _foCim := _foCim + ' HÓNAPBAN';

  _rangeStr := 'B1:O1';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Mergecells := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Name  := 'Calibri';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Size  := 14;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Bold  := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Italic:= True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Color := $4090;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].HorizontalAlignment := -4108;
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := _foCim;

  _aktDatums := _eloDatums+nulele(_aktNap);
  _rangeStr := 'E2:I2';

  _oxl.WorkSheets[_aktNap].range[_rangeStr].Mergecells := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Name  := 'Arial Black';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Size  := 12;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Bold  := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Italic:= True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Color := $4090;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].HorizontalAlignment := -4108;
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := _aktDatums;

  // Teljes fejtábla:

  _rangeStr := 'B4:O6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Name := 'Arial';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Size := 9;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].HorizontalAlignment := -4108;

  // Pénztár oszlop:

  _rangeStr := 'B4:C4';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].MergeCells := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'PÉNZTÁRAK';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Bold := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Italic := True;

  // Pénztárszám oszlop:

  _rangeStr := 'B5:B6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].MergeCells := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].VerticalAlignment := -4108;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Bold := true;
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'SZÁMA';


  // Pénztárnév oszlop:

  _rangeStr := 'C5:C6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Mergecells := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].VerticalAlignment := -4108;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Bold := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'MEGNEVEZÉSE';

  // Nyitó készletek oszlopa:

  _rangeStr := 'D4:E5';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Mergecells := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].VerticalAlignment := -4108;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Bold := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'NYITÓ KÉSZLET';

  // Tranzakciók oszlopai:

  _rangeStr := 'F4:I4';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Mergecells  := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Bold   := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Italic := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'BANKI/PÉNZTÁRI TRANZAKCIÓK';

  // Banki átvételek oszlopai:

  _rangeStr := 'F5:G5';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Mergecells  := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Bold   := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Italic := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'ÁTVÉTEL';

  // Banki átadások oszlopai:

  _rangeStr := 'H5:I5';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].MergeCells  := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Bold   := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Italic := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'ÁTADÁS';

  // Ügyfél tranzakciók oszlopai:

  _rangeStr := 'J4:M4';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].MergeCells  := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Bold   := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Italic := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'ÜGYFÉL TRANZAKCIÓK';

  // Ügyfél átvétel oszlopok:

  _rangeStr := 'J5:K5';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].MergeCells  := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Bold   := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Italic := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'ÁTVÉTEL';

  // Ügyfél kifizetések oazkopai:

  _rangeStr := 'L5:M5';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].MergeCells  := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Bold   := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Italic := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'KIFIZETÉSEK';

  // Záró készletek:

  _rangeStr := 'N4:O5';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].MergeCells   := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].VerticalAlignment := -4108;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Bold    := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Italic  := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'ZÁRÓ KÉSZLETEK';

  _rangeStr := 'D6:D6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'USD';

  _rangeStr := 'E6:E6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'HUF';

  _rangeStr := 'D6:D6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'USD';

  _rangeStr := 'E6:E6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'HUF';

  _rangeStr := 'D6:D6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'USD';

  _rangeStr := 'E6:E6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'HUF';

  _rangestr := 'F6:F6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'USD';

  _rangeStr := 'F6:F6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'HUF';

  _rangeStr := 'G6:G6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'USD';

  _rangeStr := 'G6:G6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'HUF';

  _rangeStr := 'H6:H6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'USD';

  _rangeStr := 'I6:I6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'HUF';

  _rangeStr := 'J6:J6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'USD';

  _rangeStr := 'K6:K6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'HUF';

  _rangeStr := 'L6:L6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'USD';

  _rangeStr := 'M6:M6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'HUF';

  _rangeStr := 'N6:N6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'USD';

  _rangeStr := 'O6:O6';
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := 'HUF';

  _oxl.WorkSheets[_aktNap].select;
  _range := _oxl.Range['A7:A7'];
  _range.Select;

  // ------------------- KERETEZES ---------------------------------------------

  _ks := 'B4:C4';
  VekonyKeret(_ks,_aktNap);

  _ks := 'C5:C6';
  VekonyKeret(_ks,_aktNap);

  _ks := 'D4:E5';
  VekonyKeret(_ks,_aktNap);

  _ks := 'J4:M4';
  VekonyKeret(_ks,_aktNap);

  _ks := 'D6:D6';
  VekonyKeret(_ks,_aktNap);

  _ks := 'F6:F6';
  VekonyKeret(_ks,_aktNap);

  _ks := 'H5:I5';
  VekonyKeret(_ks,_aktNap);

  _ks := 'L5:M5';
  VekonyKeret(_ks,_aktNap);

  _ks := 'H6:H6';
  VekonyKeret(_ks,_aktNap);

  _ks := 'J6:J6';
  VekonyKeret(_ks,_aktNap);

  _ks := 'L6:L6';
  VekonyKeret(_ks,_aktNap);

  _ks := 'N6:N6';
  VekonyKeret(_ks,_aktNap);

  _ks := 'F5:G5';
  VekonyKeret(_ks,_aktNap);

  _ks := 'J5:K5';
  VekonyKeret(_ks,_aktNap);

  _ks := 'N4:O5';
  VekonyKeret(_ks,_aktNap);

  _ks := 'B4:O6';
  VastagKeret(_ks,_aktNap);

  // ---------------------------------------------------------------

  _oxl.ActiveWindow.FreezePanes := True;

  _priSor := 8;
end;

// =============================================================================
           procedure TForm2.VastagKeret(_rs: string; _sh: byte);
// =============================================================================

begin
  _oxl.WorkSheets[_sh].Range[_rs].BorderAround(1,4);
end;

// =============================================================================
          procedure TForm2.VekonyKeret(_rs: string; _sh: byte);
// =============================================================================

begin
  _oxl.WorkSheets[_sh].Range[_rs].BorderAround(1,2);
end;

// =============================================================================
               procedure TForm2.EgyKorzetNapja;
// =============================================================================

begin
  _aktPtDarab := _korzetPenztarDarab[_korzetSs];
  _priStr := inttostr(_priSor);

  _rangeStr := 'B' + _priStr + ':C' + _priStr;

  _oxl.WorkSheets[_aktNap].Range[_rangeStr].MergeCells  := True;
  _oxl.WorkSheets[_aktNap].Range[_rangeStr].Font.Name   := 'Colibri';
  _oxl.WorkSheets[_aktNap].Range[_rangeStr].Font.Size   := 11;
  _oxl.WorkSheets[_aktNap].Range[_rangeStr].HorizontalAlignment := -4108;
  _oxl.WorkSheets[_aktNap].Range[_rangeStr] := _aktKorzetNev + 'I KÖRZET';

  _startSor := _priSor + 1;
  _endSor   := _priSor + _aktPtDarab;
  _osszSor  := _endSor + 1;

  // pénztárszámok oszlopa

  _sStr := inttostr(_startSor);
  _eStr := inttostr(_endSor);

  _rangeStr := 'B' + _sStr + ':B' + _eStr;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Name   := 'Colibri';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Size   := 8;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].HorizontalAlignment := -4108;

  // pénztárnevek oszlopa:

  _rangeStr := 'C' + _sstr + ':C' + _estr;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Name   := 'Colibri';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Size   := 8;

  // A forgalmi adatok területe:

  _rangeStr := 'D' + _sStr + ':O' + _eStr;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Name   := 'Colibri';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Size   := 8;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].NumberFormat := '### ### ###';

  // A körzet összesen sora:

  _oStr := inttostr(_osszSor);
  _rangeStr := 'B' + _oStr + ':C' + _oStr;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Mergecells  := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].HorizontalAlignment := -4108;
  _oxl.WorkSheets[_aktNap].range[_rangeStr] := _aktKorzetNev + ' ÖSSZESEN';

  _rangeStr := 'B' + _oStr + ':O' + _oStr;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Name   := 'Colibri';
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Size   := 9;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Bold   := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Italic := True;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].Font.Color  := clRed;

  _rangeStr := 'D' + _oStr + ':O' + _oStr;
  _oxl.WorkSheets[_aktNap].range[_rangeStr].NumberFormat := '### ### ###';


  EgynapiAdatfeltoltes;

  inc(_sumDarab);
  _sumSor[_sumdarab] := _osszSor;

  _priSor := _osszSor+2;
end;

// =============================================================================
           function TForm2.ScanKorzet(_kNum: byte): byte;
// =============================================================================

begin
  Result := 0;
  _y := 0;
  while _y<=9 do
    begin
      if _kNum=_korzetSor[_y] then
        begin
          Result := _y;
          Exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
            function TForm2.ScanPenztar(_pNum: byte): byte;
// =============================================================================

begin
  Result := 0;
  _y := 0;
  while _y<=_irodaDarab do
    begin
      if _pNum=_penztarSor[_y] then
        begin
          Result := _y;
          Exit;
        end;
      inc(_y);
    end;
end;


// =============================================================================
              procedure TForm2.EgyNapiAdatFeltoltes;
// =============================================================================

var _xSor: byte;

begin
  _xSor := _StartSor;

  _pp := 1;
  while _xSor<=_endSor do
    begin
      _aktPt := _korzetPenztarSor[_korzetSs,_pp];
      _ptSs  := ScanPenztar(_aktPt);

      _oxl.WorkSheets[_aktNap].Cells[_xSor,2] := _aktPt;
      _oxl.WorkSheets[_aktNap].Cells[_xSor,3] := _penztarNev[_ptSs];

      _usd := _zUsdNyito[_ptSs,_aktNap];
      _huf := _zHufNyito[_ptSs,_aktNap];

      _oxl.WorkSheets[_aktNap].Cells[_xSor,4] := _usd;
      _oxl.WorkSheets[_aktNap].Cells[_xSor,5] := _huf;

      _usd := _wUsdBankBe[_ptSs,_aktNap];
      _huf := _wHufBankBe[_ptSs,_aktNap];

      _oxl.WorkSheets[_aktNap].Cells[_xSor,6] := _usd;
      _oxl.WorkSheets[_aktNap].Cells[_xSor,7] := _huf;

      _usd := _wUsdBankKi[_ptSs,_aktNap];
      _huf := _wHufBankKi[_ptSs,_aktNap];

      _oxl.WorkSheets[_aktNap].Cells[_xSor,8] := _usd;
      _oxl.WorkSheets[_aktNap].Cells[_xSor,9] := _huf;

      _usd := _wUsdUgyfBe[_ptSs,_aktNap];
      _huf := _wHufUgyfBe[_ptSs,_aktNap];

      _oxl.WorkSheets[_aktNap].Cells[_xSor,10] := _usd;
      _oxl.WorkSheets[_aktNap].Cells[_xSor,11] := _huf;

      _usd := _wUsdUgyfki[_ptSs,_aktNap];
      _huf := _wHufUgyfki[_ptSs,_aktNap];

      _oxl.WorkSheets[_aktNap].Cells[_xSor,12] := _usd;
      _oxl.WorkSheets[_aktNap].Cells[_xSor,13] := _huf;

      _usd := _zUsdZaro[_ptSs,_aktNap];
      _huf := _zHufZaro[_ptSs,_aktNap];

      _oxl.WorkSheets[_aktNap].Cells[_xSor,14] := _usd;
      _oxl.WorkSheets[_aktNap].Cells[_xSor,15] := _huf;

      inc(_pp);
      inc(_xSor);
    end;

  _o1 := 68;
  while _o1<=79 do
    begin
      _rangeStr  := chr(_o1) + _sstr + ':' + chr(_o1) + _estr;
      _formula   := '=Sum(' + _rangestr + ')';
      _oRangeStr := chr(_o1)+_ostr + ':' + chr(_o1) + _ostr;
      _oxl.WorkSheets[_aktNap].Range[_orangeStr].Formula := _formula;
      inc(_o1);
    end;
end;

// =============================================================================
            function TForm2.Nulele(_num: byte): string;
// =============================================================================

begin
  Result := inttostr(_num);
  if _num<10 then Result := '0' + Result;
end;

// =============================================================================
                    procedure TForm2.CegOsszesenSor;
// =============================================================================

var _rovNev: string;

begin
  dec(_prisor);

  _cegSumSor := _priSor;
  _cStr      := inttostr(_cegSumSor);
  _rovNev    := _cegrovnev[_cegSs];

  _rangeStr  := 'B' + _cStr + ':C' + _cStr;

  _oxl.WorkSheets[_aktNap].Range[_rangeStr].MergeCells  := True;
  _oxl.WorkSheets[_aktNap].Range[_rangeStr].HorizontalAlignment := -4108;
  _oxl.WorkSheets[_aktNap].Range[_rangeStr] := _rovNev + ' ÖSSZESEN';

  _rangeStr  := 'B' + _cStr + ':O' + _cStr;

  _oxl.WorkSheets[_aktNap].Range[_rangeStr].Font.Bold   := True;
  _oxl.WorkSheets[_aktNap].Range[_rangeStr].Font.Italic := True;
  _oxl.WorkSheets[_aktNap].Range[_rangeStr].Font.Color  := $FF3030;

  _rangeStr  := 'D' + _cStr + ':O' + _cStr;
  _oxl.WorkSheets[_aktNap].Range[_rangeStr].NumberFormat := '### ### ###';

  // ----------------------------------------------------------------------

  _o1 := 68;
  while _o1<=79 do
    begin
      _formula := '=Sum(';
      _sss := 1;
      while _sss<=_sumDarab do
        begin
          _aktSor := _sumSor[_sss];
          _as     := inttostr(_aktSor);
          _formula := _formula + chr(_o1) + _as;
          inc(_sss);

          if _sss<=_sumDarab then _formula := _formula + '+';
        end;

      _oRangeStr := chr(_o1) + _cStr + ':' + chr(_o1) + _cStr;
      _oxl.WorkSheets[_aktNap].Range[_orangeStr].Formula := _formula;

      inc(_o1);
    end;
  _sumDarab := 0;
  _priSor   := _priSor + 2;

end;

// =============================================================================
                  procedure TForm2.ExcelKill;
// =============================================================================

var
  _fileName,_filePath: String;

begin

  _Proc.DwSize := SizeOf(_Proc);
  _handle      := CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
  _Looper      := Process32First(_handle,_proc);

  while Integer(_Looper) <> 0 do
    begin
      _filePath := _Proc.SzExeFile;
      _fileName := UpperCase(ExtractFileName(_filePath));

      if _fileName = 'EXCEL.EXE' then
        begin
          TerminateProcess(OpenProcess(1,Bool(1),_proc.th32ProcessID),0);
      //    break;
        end;

      _Looper := Process32Next(_handle,_proc);
    end;
  CloseHandle(_handle);
end;

// =============================================================================
                procedure TForm2.EvComboChange(Sender: TObject);
// =============================================================================

begin
  ActiveControl := StartGomb;
end;
end.
