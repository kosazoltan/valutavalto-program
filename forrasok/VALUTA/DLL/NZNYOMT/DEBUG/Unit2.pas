unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, DateUtils, DB, DBTables, strUtils,printers,
  ComCtrls, IBDatabase, IBCustomDataSet, IBTable, Grids, DBGrids, IBQuery;

type
  TNapzarNyomtatoForm = class(TForm)

    Csik            : TProgressBar;

     DatumPanel     : TPanel;
  NyomFormpanel     : TPanel;
         Label1     : TLabel;
        Idozito     : TTimer;

    Shape1          : TShape;
    XTRANZ: TIBTransaction;
    XDBASE: TIBDatabase;
    XQUERY: TIBQuery;

    ValdataTabla    : TIBTable;
    ValDataQuery    : TIBQuery;
    ValDataDbase    : TIBDatabase;
    ValDataTranz    : TIBTransaction;

    ValutaTabla     : TIBTable;
    ValutaQuery     : TIBQuery;
    ValutaDbase     : TIBDatabase;
    ValutaTranz     : TIBTransaction;
    XTABLA: TIBTable;
    HRKQUERY: TIBQuery;
    HRKDBASE: TIBDatabase;
    HRKTRANZ: TIBTransaction;

    procedure Adatgyujtes;
    procedure ArfolyamLista;
    procedure BlokkFocimIro;
    procedure DnemBeolvasas;
    procedure FoglaloKeszletNyomtatas;
    procedure FormActivate(Sender: TObject);
    procedure KunaNyomtatas;
    procedure IdozitoTimer(Sender: TObject);
    procedure Kezelesidijnyomtatas;
    procedure KozepreIr(_szoveg: string);
    procedure NapiForgalomLista;
    procedure NapZaroKeszletek;
    procedure NzForgalom;
    procedure NzPenztarAtadVesz;
    procedure PenztarAllas;
    procedure StartNyomtatas;
    procedure TradezaroLista;
    procedure VonalHuzo;
    procedure WuWaDataRead;
    procedure WuWaLista;
    procedure VAlutaParancs(_ukaz: string);

    function ArfolyamForm(_curr: integer): string;
    function DAyTraffic:boolean;
    function DnemScan(_adn: string): byte;
    function Elokieg(_s: string; _p: byte): string;
    function F6(_n: integer): string;
    function F9(_n: integer): string;
    function ForintForm(_osszeg:integer):string;
    function FormKiir(_in: integer):string;
    function GetIdos: string;
    function Kieg(_s: string;_p: byte): string;
    function S9(_n: integer): string;
    function Sform(_n,_h: integer): string;
    function TablaExists(_tnev: string): boolean;
    function wout(_s: string): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  NapzarNyomtatoForm: TNapzarNyomtatoForm;


  _tradePath   : string = 'c:\valuta\database\trade.fdb';
  _sorveg      : string = chr(13)+chr(10);

  _aktDnem,
  _aktDnev,
  _aktIdos,
  _aktPt,
  _bizonylatSzam,
  _cegNev,
  _datumText,
  _elojel,
  _farok,
  _fejfilenev,
  _homePenztarCim,
  _homePenztarNev,
  _homePenztarKod,
  _kftNev,
  _lastBizonylat,
  _matTipus,
  _megnyitottNap,
  _narftabla,
  _nums,
  _pcs,
  _penztar,
  _szoveg,
  _szuro,
  _tablaNev,
  _tetFilenev,
  _tipus,
  _zDatums: string;

  _aktBankjegy,
  _aktEArf,
  _akteladas,
  _akteladasFt,
  _aktElszarf,
  _aktErtek,
  _aktNyito,
  _aktVArf,
  _aktvetel,
  _aktVetelFt,
  _aktZaro,
  _atadott,
  _atvett,
  _bankKartya,
  _bkEladas,
  _bkKtsg,
  _code,
  _dek,
  _eKerekites,
  _feladas,
  _fizetoeszkoz,
  _forint,
  _ftk,
  _hufBe,
  _hufKi,
  _hufNyito,
  _hufZaro,
  _hrknyito,
  _hrkbevetel,
  _hrkkiadas,
  _hrkzaro,
  _kerekites,
  _kktsg,
  _kpEladas,
  _matForg,
  _metroBe,
  _metroKi,
  _metroNyito,
  _metrovissza,
  _metrozaro,
  _mOsszeg,
  _navOke,
  _ptarAtadas,
  _ptarAtvet,
  _recno,
  _sEladasFt,
  _sumForg,
  _sVetelFt,
  _telForg,
  _tescoBe,
  _tescoKi,
  _tescoNyito,
  _tescoVissza,
  _tescoZaro,
  _tNyito,
  _trBesum,
  _trKisum,
  _trNyito,
  _tZaro,
  _trZaro,
  _usdBe,
  _usdKi,
  _usdNyito,
  _usdZaro,
  _ugyKezdij,
  _vKerekites,
  _zz: integer;

  _dnemDarab,
  _dnemindex,
  _fvalDarab,
  _homepenztarszam,
  _kellMetro,
  _kellMatrica,
  _kellMoneygram,
  _kellTesco,
  _kellWestern,
  _postTerm,
  _printer,
  _xx: byte;

  _dNem,_dnev: array[1..30] of string;

  _elszArf: array[1..30] of integer;
  _fNyito,_fZaro,_fBe,_fKi: array[0..4] of integer;

  _nyito,_zaro: array[1..27] of integer;
  _vetel,_eladas,_vetelft,_eladasFt,_atvetel,_atadas: array[1..27] of integer;
  _ptatadas,_ptatvetel: array[1..500] of integer;
  _ptss: array[1..500] of string;
  _trdnem: array[1..500] of byte;

  _volttr: boolean;

  _height,
  _left,
  _top,
  _tranzdb,
  _trss,
  _width: word;

  _LFile: textFile;

  _aktid,_tranzid,_price,_amount,_feltoltes,_cardbe,_cardki: integer;
  _cashbe,_cashki,_ertekesites,_eladforg: integer;
  _cardnyito,_cardzaro,_cashnyito,_cashzaro: integer;
  _datumido,_product: string;



function napzarnyomtatorutin: integer; stdcall;


implementation

{$R *.dfm}

// =============================================================================
              function napzarnyomtatorutin: integer; stdcall;
// =============================================================================

begin
  NapzarNyomtatoForm := TNapzarnyomtatoForm.Create(Nil);
  result := Napzarnyomtatoform.showmodal;
  NapzarnyomtatoForm.free;
end;


// =============================================================================
           procedure TNAPZARNYOMTATOFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  // Z·rÛnap = VALUTA.FDB -> VTEMP -> DATUM

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;
  _top    := trunc((_height-768)/2);
  _left   := trunc((_width-1024)/2);

  Top    := _top +295;
  Left   := _left +330;

  Width  := 430;
  Height := 200;

  Idozito.Enabled := True;
end;


// =============================================================================
          procedure TNAPZARNYOMTATOFORM.IDOZITOTimer(Sender: TObject);
// =============================================================================

begin
  Idozito.Enabled := false;
  // _dnemdarab : _DNEM …S ELSZARF tˆmbelem feltˆltÈse ARFOLYAM.FDB-bol #EUA

  repaint;
  DnemBeolvasas;

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;

      // Beolvassa a z·randÛ napot:

      _zDatums := trim(FieldByName('DATUM').asString);
      _navoke := FieldbyName('OTVENEDIK').asInteger;
      Close;

      // A gÈp paramÈtereit:

      Sql.clear;
      Sql.Add('SELECT * FROM HARDWARE');
      Open;
      _printer       := FieldByNAme('PRINTER').asInteger;
      _kellwestern   := FieldByName('KELLWESTERN').asInteger;
      _kellTesco     := FieldByName('KELLTESCOAFA').asInteger;
      _kellmetro     := FieldByNAme('KELLMETROAFA').asInteger;
      _kellMatrica   := FieldByNAme('KELLMATRICA').asInteger;
      _kftnev        := trim(FieldByNAme('KFTNEV').AsString);
      _megnyitottnap := trim(FieldByNAme('MEGNYITOTTNAP').AsString);
      _postterm      := FieldByName('POSTTERM').asInteger;

      //  A pÈnzt·r adatait:

      Close;
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;

      _homePenztarkod  := trim(FieldByName('PENZTARKOD').asString);
      _homePenztarnev  := trim(FieldByName('PENZTARNEV').AsString);
      _homepenztarcim  := trim(FieldByName('PENZTARCIM').AsString);
      Close;
    end;
  Valutadbase.close;

  val(_homePenztarKod,_homePenztarszam,_code);
  if _homePenztarszam<151 then
    begin
      _cegnev := 'Exclusive Best Change Zrt';
    end else
    begin
      _cegnev := 'Expressz Ekszerhaz es Minibank Kft';
    end;

  _bkktsg := 0;

  // Az idˆstring beolvas·sa:

  _aktIdos           := GetIdos;

  // A fˆfelirat Ès havi-farok neghat·roz·sa:

  _datumtext := _zDatums + '-i z·r·s nyomtat·sa';
  DatumPanel.Caption := _datumText;
  DatumPanel.Repaint;
  NyomformPanel.Repaint;

  sleep(2000);

  _farok := midstr(_zDatums,3,2)+midstr(_zDatums,6,2);

  // Az Aktlist.txt fˆcimÈnek Ès d·tum·nak beir·sa:

  Csik.Position := 10;

  // Megnyitja AKTLST.TXT-t Ès beleirja a fejlÈcet:

  BlokkFocimiro;
  KozepreIr(_datumText);

  // A napi vÈtel Ès elad·sok beir·sa a text file-ba:

  Adatgyujtes;
  Csik.Position := 15;
  NzForgalom; // vÈtel.elad·s

  // A pÈnzt·ri ·tvÈtel Ès ·tad·s textfilebe ir·sa:

  Csik.Position := 20;
  nzPenztarAtadVesz;

  // Az ·rfolyamlista feljegyzÈse:


  Csik.Position := 25;
  ArfolyamLista;

  // Ha ez nem egy rÈgebbi nap ˙jranyomtat·sa, akkor nyilatkozat beir·sa:


//  if _navOke<>2 then PenztarAllas;

  PenztarAllas;
  if _zDatums=_megnyitottnap then
    begin
      writeLn(_LFile,'Buntetojogi felelosegem tudataban kije-');
      writeLN(_LFile,'lentem,hogy a penztar allasa es a zaro-');
      writeLn(_LFile,'szalagon szereplo osszegek megegyeznek.');

      writeLn(_LFile,_sorveg);
      writeLn(_Lfile,dupestring('.',39));
      writeLn(_Lfile,'              penztaros');
      writeLn(_lfile,_sorveg + _sorveg);
    end;

  // Napi z·rÛkÈszlet kiir·sa:

  Csik.Position := 30;
  NapZaroKeszletek;

  // A napi forgalom kiir·sa:

  Csik.Position := 35;
  NapiForgalomLista;
  Csik.Position := 40;

////  if _navoke<>2 then Kezelesidijnyomtatas;

  Kezelesidijnyomtatas;
  Csik.Position := 45;

  KunaNyomtatas;
  Csik.Position := 48;

//  FoglaloKeszletNyomtatas;

  // A wzaryymm-bıl kiolvassa az adatokat:

  Csik.Position := 50;
  if (_kellwestern=1) or (_kelltesco=1) or (_kellmetro=1) then
    begin
      WuWaDataRead;
      // Az wunion Ès wafa textfileba ir·sa:
      Wuwalista;
    end;
  Csik.Position := 60;

  if (_kellmatrica=1) then TradeZarolista;
  Csik.Position := 70;

  Csik.Position := 90;

  writeln(_LFile,_sorveg+_sorveg);
  CloseFile(_LFile);

  Startnyomtatas;
  Csik.Position := 120;

  _pcs := 'UPDATE VTEMP SET OTVENEDIK=0';
  ValutaParancs(_pcs);
  sleep(300);
  ModalResult := 1;
end;

// =============================================================================
      procedure TNapzarNyomtatoForm.BlokkFocimIro;
// =============================================================================

begin

  assignFile(_LFile,'C:\VALUTA\Aktlst.txt');
  Rewrite(_LFile);

  KozepreIr(_cegnev);
  Kozepreir(_homePenztarKod + ' ' + _homePenztarnev);
  Kozepreir(_homePenztarCim);
  VonalHuzo;
end;

// =============================================================================
                   procedure TNapzarNyomtatoForm.NzForgalom;
// =============================================================================


begin

  _svetelft := 0;
  _seladasFt := 0;

  // ------------ SUMM¡Z¡S ---------------------------------------------

  _xx := 1;
  while _xx<=27 do
    begin
      _sVetelFt := _sVetelFt + _vetelFt[_xx];
      _sEladasFt:= _sEladasFt+ _eladasFt[_xx];
      inc(_xx);
    end;
  _svetelft := _sVetelFt + _vKerekites;
  _sEladasft := _sEladasFt + _eKerekites;


  KozepreIr('Valuta vasarlasok es eladasok');
  VonalHuzo;

  writeLn(_LFile,'Va-   Valuta vasarlas    Valuta eladas');
  writeLn(_Lfile,'luta-----------------------------------');
  writeLn(_LFile,'nem   Valuta   Forint   Valuta   Forint');
  VonalHuzo;

  _xx := 1;
  while _xx<=27 do
    begin
      _aktdnem := _dnem[_xx];
      _aktvetel := _vetel[_xx];
      _akteladas := _eladas[_xx];

      if _aktdnem= 'HUF' then
        begin
          inc(_xx);
          Continue;
        end;

      if (_aktvetel=0) and (_akteladas=0) then
        begin
          inc(_xx);
          Continue;
        end;

      _aktvetelFt := _vetelft[_xx];
      _akteladasft := _eladasft[_xx];

      Write(_Lfile,_aktdnem+' ');
      Write(_LFile,Elokieg(inttostr(_aktvetel),8)+' ');
      write(_Lfile,Elokieg(inttostr(_aktvetelft),8)+' ');
      write(_LFile,Elokieg(inttostr(_akteladas),8)+' ');
      writeLn(_Lfile,Elokieg(inttostr(_akteladasft),8));

      inc(_xx);
    end;

  if _postterm=1 then _kpeladas := _seladasft-_bkeladas;

  VonalHuzo;

  write(_LFile,'  Osszes vetel erteke  : ');
  writeLn(_Lfile,FormKiir(_sVetelFt)+' Ft');
  write(_LFile,' Osszes eladas erteke  : ');
  writeLn(_LFile,FormKiir(_seladasFt)+' Ft');
  if _postterm=1 then
    begin
      writeLn(_LFile,'      ebbol keszpenzes : '+Formkiir(_kpeladas)+' Ft');
      writeLn(_LFile,'           bankkartyas : '+Formkiir(_bkeladas)+' Ft');
    end;
  VonalHuzo;
end;


// =============================================================================
             procedure TNapZarNyomtatoForm.nzPenztarAtadVesz;
// =============================================================================

var _cim: string;

begin

  _cim := _zDatums + '-i penztarak kozotti mozgasok';

  KozepreIr(_cim);
  VonalHuzo;

  //              123456789012345678901234567890123456789
  writeLn(_LFile,' Dnem  Ptar    Atadott       Atvett');
  //               EUR   143   123 456 789   123 456 789

  VonalHuzo;

  _trss := 1;
  while _trss<=_tranzdb do
    begin
      _xx := _trDnem[_trss];
      _aktdnem := _dNem[_xx];
      _atadott := _ptatadas[_trss];
      _atvett  := _ptatvetel[_trss];
      _aktpt   := _ptss[_trss];

      if (_atadott>0) OR (_atvett>0) then
        begin
          write(_LFile,' '+_aktdnem+'   ');
          write(_LFile,elokieg(_aktpt,3)+'   ');
          write(_LFile,FormKiir(_atadott)+'   ');
          writeLn(_LFile,FormKiir(_atvett));
        end;
      inc(_trss);
    end;

  VonalHuzo;
  writeLn(_LFile,'Penztarak kozotti mozgasok osszesitve');
  writeLn(_Lfile,'  Dnem      Atadott        Atvett');
  VonalHuzo;


  _xx := 1;
  while _xx<=27 do
    begin
      _aktdnem    := _dnem[_xx];
      _ptaratadas := _atadas[_xx];
      _ptaratvet  := _atvetel[_xx];

      if (_ptaratadas>0) or (_ptaratvet>0) then
        begin
          write(_LFile,'   '+_aktdnem+'    ');
          write(_Lfile,Formkiir(_ptaratadas)+'    ');
          writeLn(_LFile,FormKiir(_ptarAtvet));
        end;

      inc(_xx);
    end;
  VonalHuzo;
end;



// =============================================================================
                   procedure TNapZarNyomtatoForm.ArfolyamLista;
// =============================================================================

var _varfs,_earfs: string;
begin
  Kozepreir(_ZDatums +'-i valuta arfolyamok');
  VonalHuzo;

  writeLn(_Lfile,'Valuta         Veteli         Eladasi');
  writeLn(_Lfile,' nem          arfolyam        arfolyam');
  VonalHuzo;

  Valdatadbase.close;
  ValdataDbase.connected := True;
  _narftabla := 'NARF' + _farok;

  _pcs := 'SELECT * FROM ' + _narftabla + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_zDatums+chr(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  with ValdataQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;

    end;
  while not ValdataQuery.Eof do
    begin
      with ValdataQuery do
        begin
          _aktnyito:= FieldbyName('NYITO').AsInteger;
          _aktZaro := FieldByName('ZARO').asInteger;
          _aktdnem := FieldByName('VALUTANEM').AsString;
          _aktvarf := FieldByNAme('VETELIARFOLYAM').asInteger;
          _aktearf := FieldByName('ELADASIARFOLYAM').asInteger;
        end;

      _xx := Dnemscan(_aktdnem);
      _nyito[_xx] := _aktnyito;
      _zaro[_xx]  := _aktzaro;

      _varfs := ArfolyamForm(_aktvarf);
      _earfs := ArfolyamForm(_aktearf);

      write(_LFile,' '+_aktdnem+'      ');
      write(_Lfile,Elokieg(_varfs,11)+'     ');
      writeLn(_LFile,Elokieg(_earfs,11));

      ValdataQuery.Next;
    end;
  ValdataQuery.Close;

  VonalHuzo;
end;



// =============================================================================
                  procedure TNapZArNyomtatoForm.PenztarAllas;
// =============================================================================

var _egyenleg: integer;
begin
  _szoveg := _ZDatums + '-i penztar allasa';
  KozepreIr(_szoveg);
  VonalHuzo;

  writeLn(_Lfile,'Val.   Nyito     Forgalom      Penztar');
  writeLn(_Lfile,'nem   osszeg    egyenlege       allas');
  VonalHuzo;

  _xx := 1;
  while _xx<=27 do
    begin
      _aktdnem := _dnem[_xx];
      _aktnyito:= _nyito[_xx];
      _aktzaro := _zaro[_xx];
      if _aktzaro>0 then
        begin
          _egyenleg := _aktzaro-_aktnyito;

          write(_Lfile,_aktdnem+' ');
          write(_Lfile,Formkiir(_aktnyito)+' ');
          write(_Lfile,FormKiir(_egyenleg)+' ');
          writeLn(_Lfile,FormKiir(_aktzaro));
        end;

      inc(_xx);
    end;
  VonalHuzo;
  WriteLN(_LFile,' ');
end;


// =============================================================================
                  procedure TNapZarNyomtatoForm.NapZaroKeszletek;
// =============================================================================


var _elszarfs: string;

begin

  _szoveg := _zDatums + '-I NAPI ZAROKESZLET';

  KozepreIr(_szoveg);
  VonalHuzo;

  writeLn(_Lfile,'DNEM   KESZLET     ARFOLYAM       ERTEK');
  VonalHuzo;

  _dek := 0;
  _ftk := 0;

  _xx := 1;
  while _xx<=27 do
    begin
      _aktzaro := _zaro[_xx];
      _aktdnem := _dnem[_xx];
      if _aktzaro=0 then
        begin
          inc(_xx);
          Continue;
        end;

      _aktelszarf := _elszarf[_xx];
      If _aktdnem='JPY' then _aktelszarf := round(_aktelszarf/10);

      _zz := trunc(_aktzaro*_aktelszarf/100);
      _elszarfs := arfolyamForm(_aktelszarf);

      write(_Lfile,_aktdnem+' ');
      write(_Lfile,formkiir(_aktzaro)+' ');
      write(_Lfile,elokieg(_elszarfs,11)+' ');

      if _aktdnem = 'HUF' then _ftk := _zz else _dek := _dek + _zz;

      writeLn(_Lfile,FormKiir(_zz));
      inc(_xx);
   end;
  VonalHuzo;

  writeLn(_Lfile,'O S S Z E S  K E S Z L E T : '+ Formkiir(_dek));
  writeLn(_Lfile,'F O R I N T  K E S Z L E T : '+ Formkiir(_ftk));
  writeLn(_LFile,'   M I N D O S S Z E S E N : '+ Formkiir(_dek+_ftk));
  VonalHuzo;
end;


// =============================================================================
               procedure TNapzarNyomtatoForm.NapiForgalomLista;
// =============================================================================

var _voltadat:boolean;
    _ptnak,_pttol: integer;

begin
  _voltadat := DayTraffic;
  if not _voltAdat then exit;

  writeLn(_LFile,'    NAPI FORGALOM KIMUTATASA - I.');
  VonalHuzo;

  writeLn(_LFile,'Datum      (DATE)          : '+ _zDatums);
  writeLn(_LFile,'Ido        (TIME)          : ' + _aktidos);
  VonalHuzo;

  writeLn(_Lfile,'DNEM     NYITO       VETEL       ELADAS');
  VonalHuzo;

  _xx :=1;
  while _xx<=27 do
    begin
      _aktdnem := _dnem[_xx];
      _aktnyito := _nyito[_xx];
      _akteladas := _eladas[_xx];
      _aktvetel := _vetel[_xx];
      _ptnak   := _atadas[_xx];
      _pttol   := _atvetel[_xx];
      _aktzaro := _zaro[_xx];

      if (_aktnyito=0) and (_aktzaro=0) and (_aktvetel=0) and (_akteladas=0) and (_ptnak=0) and (_pttol=0) then
        begin
          inc(_xx);
          Continue;
        end;

      if _aktdnem='HUF' then
        begin
          _aktvetel  := trunc((-1)*_sVetelft);
          _akteladas := trunc((-1)*_sEladasFt);
        end;
      write(_LFile,_aktdnem+' ');
      write(_LFile,Formkiir(_aktnyito)+' ');
      write(_LFile,FormKiir(_aktvetel)+' ');
      writeLn(_LFile,Formkiir(_akteladas));
      inc(_xx);
    end;

  VonalHuzo;

  writeLn(_LFile,'    NAPI FORGALOM KIMUTATASA - II.');
  VonalHuzo;

  writeLN(_LFile,'DNEM ATAD-PTNAK ATVET-PENZTARTOL  ZARO');
  VonalHuzo;

  _xx := 1;
  while _xx<=27 do
    begin
      _aktdnem := _dnem[_xx];
      _aktnyito := _nyito[_xx];
      _akteladas := _eladas[_xx];
      _aktvetel := _vetel[_xx];
      _ptnak   := _atadas[_xx];
      _pttol   := _atvetel[_xx];
      _aktzaro := _zaro[_xx];

      if (_aktnyito=0) and (_aktzaro=0) and (_aktvetel=0) and (_akteladas=0) and (_ptnak=0) and (_pttol=0) then
        begin
          inc(_xx);
          Continue;
        end;

      write(_LFile,_aktdnem+' ');
      write(_LFile,FormKiir(_ptnak)+' ');
      write(_Lfile,FormKiir(_pttol)+' ');
      writeLn(_lfile,FormKiir(_aktzaro));

      inc(_xx);
    end;
  VonalHuzo;
end;


// =============================================================================
            procedure TNapzarNyomtatoForm.Kezelesidijnyomtatas;
// =============================================================================

var _knapinyito,_knapikezdij,_knapiatvet,_knapiatad,_knapizaro,_forint: integer;
    _mozgasnev,_pts: string;


begin
  _pcs := 'SELECT * FROM NAPIKEZELESIDIJ' + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_zDatums + chr(39);

  valutadbase.Connected := true;
  with valutaquery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      _knapinyito  := FieldByName('NYITO').asInteger;
      _knapikezdij := FieldByNAme('KEZELESIDIJ').asInteger;
      _knapiatvet  := FieldByName('KEZELESIDIJATVETEL').asInteger;
      _knapiatad   := FieldByName('KEZELESIDIJATADAS').asInteger;
      _knapizaro   := FieldByName('ZARO').asInteger;
      close;
    end;
  Valutadbase.close;

  // ---------------------------------------------------------------------------

  writeLn(_LFile,' KEZELESI KOLTSEG '+ _zDatums + '-I LISTAJA');
  writeLn(_lfILE,dupestring('-',40));
  writeLn(_LFile,' NAPI NYITO OSSZEG ......:  ' + Formkiir(_knapinyito));
  writeLn(_LFile,' KEZELESI KOLTSEG .......:  ' + Formkiir(_knapikezdij));
  writeLn(_LFile,' ATVETT OSSZEG ..........:  ' + Formkiir(_knapiatvet));
  writeLn(_LFile,' ATADOTT OSSZEG .........:  ' + Formkiir(_knapiatad));
  writeLN(_LFile,' NAPI ZARO OSSZEG .......:  ' + Formkiir(_knapizaro));
  if _postterm=1 then
        writeLn(_LFile,' BANKKARTYA KEZ-I KOLTSEG:  ' + Formkiir(_bkktsg));
  writeLn(_lfILE,dupestring('-',40));


  _tablanev := 'KEZD'+_FAROK;
  _pcs := 'SELECT * FROM ' + _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM='+CHR(39)+_zDatums+chr(39)+') AND (STORNO=1)';

  Valdatadbase.Connected := True;
  with valdataquery do
    begin
      Close;
      sql.Clear;
      Sql.add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      Valdataquery.close;
      ValdataDbase.close;
      exit;
    end;

  writeLn(_LFile,'   A KEZELESI KOLTSEG TRANZAKCIOI');
  writeLn(_lfILE,dupestring('-',40));
  writeLn(_LFile,'BIZONYLAT  MOZGAS      OSSZEG       PTAR');
  writeLn(_lfILE,dupestring('-',40));

  // itt jOn a ciklus
  while not Valdataquery.Eof do
    begin
      with ValdataQuery do
        begin
          _bizonylatszam := FieldByName('BIZONYLAT').asString;
          _forint := FieldByName('KEZELESIDIJ').asInteger;
          _pts := FieldByname('PENZTAR').asString;
        end;

      _elojel := '+';
      _mozgasnev := 'atvetel';

      if leftstr(_bizonylatszam,1)='K' then
        begin
          _elojel :='-';
          _mozgasnev := 'atadas ';
        end;

      write(_LFile,_bizonylatszam + '  '+ _mozgasnev + '  '+_elojel);
      writeln(_LFile,formkiir(_forint)+' Ft  ' + _pts);
      ValdataQuery.next;
    end;
  ValdataQuery.close;
  ValdataDbase.close;

  writeLn(_lfILE,dupestring('-',40));
  writeLn(_LFile,_sorveg);
end;


// =============================================================================
           procedure TNapzarNyomtatoForm.FoglaloKeszletNyomtatas;
// =============================================================================

var _k0,_k1,_k2,_k3,_k4: integer;
    _v0,_v1,_v2,_v3,_v4: string;

begin
  //            FOGLALO KESZLETEK
// 1234567890123456789012345678901234567890
//   Valutanem   Valutanev      Zarokeszlet
// ----------------------------------------
//     NZD    UJZELANDI DOLLAR  123 456 789
// 123456789 123456789 123456789 123456789

  if _zDatums<_megnyitottnap then exit;

  _pcs := 'SELECT * FROM FOGLALOKESZLET' + _sorveg;

  ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _fvalDarab := FieldbyNAme('VALDARAB').asInteger;
    end;

  if _fValdarab=0 then
    begin
      ValutaQuery.close;
      Valutadbase.close;
      exit;
    end;

  Kozepreir('FOGLALO KESZLETEK');
  writeLn(_LFile,'  Valutanem   Valutanev      Zarokeszlet');
  writeLn(_LFile,dupestring('-',39));

  with ValutaQuery do
    begin
      _k0 := FieldbyName('K0').asInteger;
      _v0 := FieldByName('V0').asstring;

      _k1 := FieldbyName('K1').asInteger;
      _v1 := FieldByName('V1').asstring;

      _k2 := FieldbyName('K2').asInteger;
      _v2 := FieldByName('V2').asstring;

      _k3 := FieldbyName('K3').asInteger;
      _v3 := FieldByName('V3').asstring;

      _k4 := FieldbyName('K4').asInteger;
      _v4 := FieldByName('V4').asstring;
      Close;
    end;

  Valutadbase.close;

  if _k0>0 then
    begin
      _xx := dnemscan(_v0);
      _aktdnev := _dnev[_xx];

      write(_LFile,'    ' + _V0+'   '+kieg(_aktdnev,16)+'  ');
      writeLn(_LFile,formKiir(_k0));
   end;

  if _k1>0 then
    begin
      _xx := dnemscan(_v1);
      _aktdnev := _dnev[_xx];

      write(_LFile,'    ' + _V1+'   '+kieg(_aktdnev,16)+'  ');
      writeLn(_LFile,formKiir(_k1));
   end;

  if _k2>0 then
    begin
      _xx := dnemscan(_v2);
      _aktdnev := _dnev[_xx];

      write(_LFile,'    ' + _V2+'   '+kieg(_aktdnev,16)+'  ');
      writeLn(_LFile,formKiir(_k2));
   end;

  if _k3>0 then
    begin
      _xx := dnemscan(_v3);
      _aktdnev := _dnev[_xx];

      write(_LFile,'    ' + _V3+'   '+kieg(_aktdnev,16)+'  ');
      writeLn(_LFile,formKiir(_k3));
   end;

  if _k4>0 then
    begin
      _xx := dnemscan(_v4);
      _aktdnev := _dnev[_xx];

      write(_LFile,'    ' + _V4+'   '+kieg(_aktdnev,16)+'  ');
      writeLn(_LFile,formKiir(_k4));
   end;
  VonalHuzo;
end;



// =============================================================================
                      procedure TNapzarNyomtatoForm.WuWaDataRead;
// =============================================================================

var _wzaroNev : string;

begin

  _wzaroNev := 'WZAR'+ _farok;
  if not TablaExists(_wzaroNev) then exit;

  ValDataDbase.close;
  ValdataDbase.Connected := True;

  if ValdataTranz.InTransaction then ValdataTranz.commit;
  ValdataTranz.StartTransaction;

  _pcs := 'SELECT * FROM ' + _wzaronev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_zDatums + chr(39);

  with ValdataQuery do
    begin
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _recno := recno;
      First;
    end;

  if ValdataQuery.RecNo=0 then
    begin
      ValdataQuery.Close;
      exit;
    end;

  with ValdataQuery do
    begin
      _usdNyito := FieldByName('USDNYITO').asInteger;
      _usdBe := FieldByName('USDBEVETEL').asInteger;
      _usdKi := FieldByName('USDKIADAS').asInteger;
      _usdZaro := FieldByName('USDZARO').asInteger;

      _hufNyito := FieldByName('HUFNYITO').asInteger;
      _hufBe := FieldByName('HUFBEVETEL').asInteger;
      _hufKi := FieldByName('HUFKIADAS').asInteger;
      _hufZaro := FieldByName('HUFZARO').asInteger;

      _MetroNyito := FieldByName('METRONYITO').asInteger;
      _metroBe := FieldByName('METROBEVETEL').asInteger;
      _metroKi := FieldByName('METROKIADAS').asInteger;
      _metroZaro := FieldByName('METROZARO').asInteger;
      _ugykezdij := FieldByName('UGYKEZELESIDIJ').asInteger;
      _metrovissza := FieldByName('METROVISSZA').asInteger;

      _TescoNyito := FieldByName('TESCONYITO').asInteger;
      _tescoBe := FieldByName('TESCOBEVETEL').asInteger;
      _tescoKi := FieldByName('TESCOKIADAS').asInteger;
      _tescoZaro := FieldByName('TESCOZARO').asInteger;
      _tescovissza := FieldByName('TESCOVISSZA').asInteger;
    end;
  ValDataQuery.Close;
end;


// =============================================================================
                  procedure TnapZarNyomtatoForm.WuWaLista;
// =============================================================================

begin
   if (_kellWestern=1) then
     begin
       KozepreIr('WESTERN UNION FORGALOM ZARASA');
       VonalHuzo;

       writeLn(_LFile,'            Usa dollar    Magyar Forint');
       VonalHuzo;

       writeLn(_LFile,'Nyito :    ' + Formkiir(_usdNyito)+'     '+FormKiir(_hufNyito));
       writeLn(_LFile,'Bevet :    ' + FormKiir(_usdBe)   +'     '+FormKiir(_hufbe));
       writeLn(_LFile,'Kiadas:    ' + FormKiir(_usdki)   +'     '+FormKiir(_hufki));
       writeln(_Lfile,'Zaro  :    ' + FormKiir(_usdZaro) +'     '+FormKiir(_hufZaro));
       VonalHuzo;
     end;

   if (_kellTesco=1) or (_kellMetro=1) then
     begin
       KozepreIr('AZ AFAVISSZATERITES FORGALOM ZARASA');
       VonalHuzo;

       writeLn(_LFile,'Nyito keszlet ........:  '+FormKiir(_Metronyito+_Tesconyito)+' Ft');
       writeLn(_Lfile,'Forint ellatmany .....:  '+FormKiir(_metroBe+_Tescobe)+' Ft');
       writeLn(_Lfile,'Ellatmany kifizetes ..:  '+FormKiir(_metroki+_Tescoki)+' Ft');
       writeLn(_Lfile,'AFA visszaterites ....:  '+FormKiir(_metroVissza+_Tescovissza)+' Ft');

       writeLn(_LFile,'Ugykezelesi dij ......:  '+FormKiir(_ugykezdij)+' Ft');
       writeLn(_LFile,'Zaro keszlet .........:  '+FormKiir(_metrozaro+_tescoZaro)+' Ft');
       VonalHuzo;
     end;
end;


// =============================================================================
               procedure TNapzarNyomtatoForm.TradeZaroLista;
// =============================================================================


var _trnyito,_trmatrica,_trtelefon,_trVodafon,_tratadas,_tratvetel,_trzaro: integer;
    _ft,_pillallas,_trPaysafe: integer;
    _tip,_sortext,_tnev,_biz,_fts,_tpt,_TIPS: string;

begin

  KozepreIr('MATRICA FORGALMI ZARAS');

  _trmatrica := 0;
  _trTelefon := 0;
  _trVodafon := 0;
  _trPaysafe := 0;
  _tratadas  := 0;
  _tratvetel := 0;
 


      _pcs := 'SELECT * FROM PARAMETERS';
      Xdbase.close;
      Xdbase.databaseName := _tradePath;
      Xdbase.Connected := true;
      with XQuery do
        begin
          Close;
          sql.Clear;
          sql.Add(_pcs);
          Open;
          First;
          _pillallas := fieldbyname('PILLALLAS').asInteger;
          Close;
        end;

      XDbase.close;

      _tnev := 'TRAD' + _farok;
      _pcs := 'SELECT * FROM '+_tnev + _sorveg;
      _pcs := _pcs + 'WHERE DATUM='+chr(39) + _zDatums + chr(39);

      Xdbase.Connected := true;
      with XQuery do
        begin
          Close;
          sql.Clear;
          sql.Add(_pcs);
          Open;
          First;
          _recno := recno;
        end;

      if _recno>0 then
        begin
          writeLn(_lfILE,dupestring('-',39));
          writeLn(_LFile,'Bizony.  Megnevezes      Osszeg     Ptar');
          writeLn(_lfILE,dupestring('-',39));

          while not XQuery.Eof do
            begin

              _biz := Xquery.FieldByName('BIZONYLATSZAM').asstring;
              _ft  := XQuery.FieldByName('FIZETENDO').asInteger;
              _tpt := XQuery.FieldByName('TARSPENZTAR').asString;
              _tip := XQuery.FieldByName('TIPUS').asstring;

              _fts := ForintForm(_ft);
              _sortext :=' '+ Kieg(_biz,9);

              if _tip='T' then _tips := 'Telefon felt.';
              if _tip='M' then _tips := 'Matrica ert.';
              if _tip='V' then _tips := 'Vodafon felt.';
              if _tip='P' then _tips := 'Paysafe felt.';

              if (_tip='F') and (_ft<0) then _tips := 'Penzatvetel';
              if (_tip='F') and (_ft>0) then _tips := 'Penzatadas';

              _ft := abs(_ft);

              _fts := ForintForm(_ft);
              _sortext := _sortext + Kieg(_tips,15);
              _sortext := _sortext + Elokieg(_fts,11);

              if _tip='F' then _sortext := _sortext +' (' + trim(_tpt)+')';
              writeLn(_LFile,_sortext);
              XQuery.next;
            end;
        end;

      XQuery.Close;
      Xdbase.close;

      // -----------------------------------------------------------------------

      _pcs := 'SELECT * FROM NAPIOSSZESITO'+_sorveg;
      _pcs := _pcs + 'WHERE DATUM='+chr(39) + _zDatums + chr(39);

      with XDbase do
        begin
          close;
          DatabaseName := _tradePath;
          Connected := true;
        end;

      with XQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          _recno := recno;
        end;

      if _recno>0 then
        begin
          with Xquery do
            begin
              _trnyito   := FieldByName('NYITO').asInteger;
              _trMatrica := FieldByName('MATRICA').asInteger;
              _trTelefon := FieldByName('TELEFON').asInteger;
              _trVodafon := FieldByName('VODAFON').asInteger;
              _trPaySafe := FieldByName('PAYSAFECARD').asInteger;
              _trAtadas  := FieldByName('ATADAS').asInteger;
              _trAtvetel := FieldByName('ATVETEL').AsInteger;
              _trZaro    := FieldByName('ZARO').asInteger;
            end;
        end else
        begin
          _trnyito := _pillallas;
          _trzaro  := _pillallas;
        end;

      writeLn(_lfILE,dupestring('-',39));
      writeLn(_LFile,'     Napi nyito osszeg : ' + Formkiir(_trnyito));
      writeLn(_LFile,'     Matrica eladas    : ' + Formkiir(_trMatrica));
      writeLn(_Lfile,'     Telefonfeltoltes  : ' + Formkiir(_trTelefon));
      writeLn(_LFile,'     Vodafon feltoltes : ' + Formkiir(_trVodafon));
      writeLn(_LFile,'     Paysafe feltoltes : ' + Formkiir(_trPaySafe));
      write(_LFile,'     Forint atadas -   : ');

      if _tratadas<> 0 then
         begin
           _pcs := 'SELECT * FROM '+_tnev + _sorveg;
           _pcs := _pcs + 'WHERE (DATUM='+chr(39)+_zDatums+chr(39)+') AND (';
           _PCS := _pcs + 'TIPUS=' + chr(39)+ 'F' + CHR(39) + ') AND (';
           _pcs := _pcs + 'FIZETENDO>0)';

           with XQuery do
             begin
               Close;
               sql.Clear;
               sql.add(_pcs);
               Open;
               First;
             end;

           while not Xquery.eof do
             begin
               _ft  := abs(XQuery.FieldByName('FIZETENDO').asInteger);
               _tpt := XQuery.FieldByName('TARSPENZTAR').asString;
               writeLn(_LFile,Formkiir(_ft)+' '+_tpt);
               Xquery.next;
             end;
         end;

      writeLn(_LFile,' ');

      // ---------------------------------------------------------------------

      write(_LFile,'     Forint atvetel -  : ');
      if _tratvetel<>0 then
        begin
          _pcs := 'SELECT * FROM '+_tnev + _sorveg;
          _pcs := _pcs + 'WHERE (DATUM='+chr(39)+_zDatums+chr(39)+') AND (';
          _PCS := _pcs + 'TIPUS=' + chr(39)+ 'F' + CHR(39) + ') AND (';
          _pcs := _pcs + 'FIZETENDO<0)';
          with XQuery do
            begin
              Close;
              sql.Clear;
              sql.add(_pcs);
              Open;
              First;
            end;

          while not Xquery.eof do
            begin
              _ft  := XQuery.FieldByName('FIZETENDO').asInteger;
              _tpt := XQuery.FieldByName('TARSPENZTAR').asString;
              writeLn(_LFile,Formkiir(_ft)+' '+ _tpt);
              Xquery.next;
           end;
      end;
      writeLn(_Lfile,' ');
      writeln(_LFile,'     Napi zaro osszeg  : ' + Formkiir(_trzaro));

      XQuery.close;
      Xdbase.close;
      VonalHuzo;

end;




// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq
// =============================================================================
            function TNapZarNyomtatoForm.DAyTraffic:boolean;
// =============================================================================


begin
  _szuro := '(NYITO<>0) OR (ELADAS<>0) OR (VETEL<>0) OR (ATADAS<>0) OR (ATVETEL<>0)';
  result := False;

  ValutaDbase.Close;
  ValutaDbase.Connected := True;
  if ValutaTranz.InTransaction then ValutaTranz.Commit;

  _pcs := 'SELECT * FROM HAVIZAR' + _sorveg;
  _pcs := _pcs + 'WHERE ' + _szuro;

  with Valutaquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  if ValutaQuery.recno>0 then Result := True;
  ValutaQuery.Close;
end;

// =============================================================================
       function TNapZarNyomtatoForm.Elokieg(_s: string; _p: byte): string;
// =============================================================================

begin
  result := trim(_s);
  while length(result)<_p do result := ' ' + result;

end;

// =============================================================================
             function TNapZarNyomtatoForm.ForintForm(_osszeg:integer):string;
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
         function TNapzarNyomtatoForm.Kieg(_s: string;_p: byte): string;
// =============================================================================

begin
  result := _s;
  while length(result)<_p do result := result + ' ';
end;

// =============================================================================
             function  TNapzarNyomtatoForm.S9(_n: integer): string;
// =============================================================================

begin
  result := inttostr(_n);
  while length(result)<9 do result := ' ' + result;
end;


// =============================================================================
              function TNapzarNyomtatoForm.Getidos: string;
// =============================================================================

begin
  result := Timetostr(Time);
  if midstr(result,2,1)=':' then Result := '0' + result;
end;

// =============================================================================
        function TNapzarNyomtatoForm.ArfolyamForm(_curr: integer): string;
// =============================================================================

var
    _currs: string;

begin
  _currs := intToStr(_curr) + '.00';
  Result := EloKieg(_currs,11);
end;


// =============================================================================
          function TNapzarNyomtatoForm.sform(_n,_h: integer): string;
// =============================================================================

var _w1,_f1: byte;

begin
  result := inttostr(_n);
  if _h=3 then
    begin
      while length(result)<3 do result := ' ' + result;
      exit;
    end;

  _w1 := length(result);
  if _w1>3 then
    begin
      _f1 := _w1-3;
      result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3);
    end;

  while length(result)<7 do result := ' ' + result;
end;

// =============================================================================
                 procedure TNapzarNyomtatoForm.Vonalhuzo;
// =============================================================================

begin
  writeln(_LFile,dupestring('-',40));
end;

// =============================================================================
                  function TNapzarNyomtatoForm.FormKiir(_in: integer):string;
// =============================================================================
begin
  Result := ForintForm(_in);
  Result := EloKieg(Result,11);
end;

// =============================================================================
              procedure TNapzarNyomtatoForm.KozepreIr(_szoveg: string);
// =============================================================================

var _oo: integer;

begin
  _szoveg := trim(_szoveg);
  _oo := trunc((40-length(_szoveg))/2);
  writeLn(_LFile,dupestring(' ',_oo)+_szoveg);
end;

// =============================================================================
               procedure TNapzarNyomtatoForm.DnemBeolvasas;
// =============================================================================

begin
  _dnemDarab := 0;
  _pcs := 'SELECT * FROM ARFOLYAM' + _sorveg;
  _pcs := _pcs + 'WHERE (VALUTANEM<>'+chr(39)+'EUA'+chr(39);
  _pcs := _pcs + ') AND (VALUTANEM<>'+chr(39)+'RCH'+chr(39)+')'+_sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  ValutaDbase.Connected := True;
  with valutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not ValutaQuery.Eof do
    begin
      _aktdnem    := ValutaQuery.FieldByName('VALUTANEM').asString;
      _aktdnev    := trim(ValutaQuery.Fieldbyname('VALUTANEV').asString);
      _aktelszarf := ValutaQuery.FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
      inc(_dnemDarab);

      _dnem[_dnemDarab] := _aktdnem;
      _dnev[_dnemdarab] := _aktdnev;
      _elszarf[_dnemdarab] := _aktelszarf;

      ValutaQuery.next;
    end;
  ValutaQuery.close;
  Valutadbase.close;
end;

// =============================================================================
        function TNapzarNyomtatoForm.DnemScan(_adn: string): byte;
// =============================================================================


var _y: byte;

begin
  result := 0;
  _y := 1;
  while _y<=_dnemdarab do
    begin
      if _dnem[_y]=_adn then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
            function TNapzarNyomtatoForm.Tablaexists(_tnev: string): boolean;
// =============================================================================

begin
  ValdataTabla.close;
  Valdatadbase.connected := true;
  ValdataTabla.Tablename := _tnev;
  result := ValdataTabla.Exists;
  Valdatadbase.close;
end;


// \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
///////////////////////////////////////////////////////////////////////////////
//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

procedure TNapzarNyomtatoForm.Adatgyujtes;

var i: byte;

begin
  for i := 1 to 27 do
    begin
      _vetel[i]   := 0;
      _eladas[i]  := 0;
      _vetelFt[i] := 0;
      _eladasFt[i]:= 0;
      _atvetel[i] := 0;
      _atadas[i]  := 0;
    end;

  _bkeladas := 0;
  _bkktsg   := 0;

  _fejFileNev := 'BF'+_farok;
  _tetFileNev := 'BT'+_farok;

   // A blokkfejgy¸jtˆ megnyit·sa: sz¸rve a z·r·s napj·ra

  _pcs := 'SELECT FEJ.*, TET.* FROM '+_fejfilenev+' FEJ JOIN '+_tetfilenev+' TET' + _sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM' + _sorveg;
  _pcs := _pcs + 'WHERE (FEJ.DATUM='+chr(39)+_zDatums+chr(39)+') AND (FEJ.STORNO=1)'+_sorveg;
  _pcs := _pcs + 'ORDER BY FEJ.BIZONYLATSZAM';

  Valdatadbase.Connected := true;
  with ValdataQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  _lastBizonylat := 'XXXXXXX';
  _bkeladas := 0;
  _bkktsg   := 0;

  _vKerekites := 0;
  _eKerekites := 0;

   // VÈgigmegy a mai napi blokkokon

  while not ValdataQuery.eof do
    begin
      with ValdataQuery do
        begin
          _bizonylatszam := FieldByNAme('BIZONYLATSZAM').asString;
          _tipus         := FieldByName('TIPUS').ASSTRING;
          _penztar       := trim(FieldByname('TARSPENZTARKOD').asstring);
          _aktdnem       := FieldByName('VALUTANEM').asstring;
          _aktBankjegy   := FieldByName('BANKJEGY').asInteger;
          _aktertek      := FieldbyNAme('FORINTERTEK').AsInteger;
          _elojel        := FieldByName('ELOJEL').asString;
          _fizetoeszkoz  := Fieldbyname('FIZETOESZKOZ').asInteger;
          _kktsg         := Fieldbyname('KEZELESIDIJ').asInteger;
          _kerekites     := FieldByNAme('KEREKITES').asInteger;
        end;

      if (_tipus='E') AND (_fizetoeszkoz=2) then
        begin
          _bkeladas := _bkeladas + _aktertek;
          if _lastbizonylat<>_bizonylatszam then _bkktsg   := _bkktsg + _kktsg;
        end;

      _xx := DnemScan(_aktdnem);
      if _tipus='V' then
        begin
          _vetel[_xx]   := _vetel[_xx] + _aktbankjegy;
          _vetelFt[_xx] := _vetelFt[_xx] + _aktErtek;
          if _lastbizonylat<>_bizonylatszam then _vKerekites := _vKerekites + _kerekites;
        end;

      if _tipus='E' then
        begin
          _eladas[_xx]   := _eladas[_xx] + _aktbankjegy;
          _eladasFt[_xx] := _eladasFt[_xx] + _aktErtek;
          if _lastbizonylat<>_bizonylatszam then _eKerekites := _eKerekites + _kerekites;
        end;

      if _tipus='F' then
        begin
          _atadas[_xx] := _atadas[_xx] + _aktbankjegy;
          inc(_trss);
          _ptatadas[_trss] := _aktbankjegy;
          _ptss[_trss] := _penztar;
          _trdnem[_trss] := _xx;
        end;

      if _tipus='U' then
        begin
          _atvetel[_xx] := _atvetel[_xx] + _aktbankjegy;
          inc(_trss);
          _ptatvetel[_trss] := _aktbankjegy;
          _ptss[_trss] := _penztar;
          _trdnem[_trss] := _xx;
        end;

       _lastBizonylat := _bizonylatszam;
      Valdataquery.Next;
    end;
  ValdataQuery.close;
  Valdatadbase.close;
  _tranzdb := _trss;
end;



// =============================================================================
               procedure TNapzarNyomtatoForm.Startnyomtatas;
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



function TNapzarNyomtatoform.Wout(_s: string): string;

var _ws,_q,_asc: byte;

begin
  result := '';
  _ws := length(_s);
  _q := 1;
  while _q<=_ws do
    begin
      _asc := ord(_s[_q]);
      if _asc<>32 then result := result + chr(_asc);
      inc(_q);
    end;
end;


// =============================================================================
             function TNapzarNyomtatoForm.F6(_n: integer): string;
// =============================================================================

var _r: string;
    _wr,_f1: byte;

begin
  _r := inttostr(_n);
  _wr := length(_r);
  if _wr<4 then
    begin
      while length(_r)<7 do _r := ' '+_r;
      result := _r;
      exit;
    end;
  _f1 := _wr-3;
  _r := leftstr(_r,_f1)+' '+midstr(_r,_f1+1,3);
  while Length(_r)<7 do _r := ' '+_r;
  result := _r;
end;

// =============================================================================
            function TNapzarNyomtatoForm.F9(_n: integer): string;
// =============================================================================

var _r: string;
    _wr,_f1: byte;

begin
  _r := inttostr(_n);
  _wr := length(_r);
  if _wr>6 then
    begin
      _f1 := _wr-6;
      _r := leftstr(_r,_f1)+' '+midstr(_r,_f1+1,3)+' '+midstr(_r,_f1+4,3);
    end else
    begin
      if _wr>3 then
        begin
          _f1 := _wr-3;
          _r := leftstr(_r,_f1)+' '+midstr(_r,_f1+1,3);
        end;
    end;
  while length(_r)<11 do _r := ' '+_r;
  result := _r;
end;


procedure TnapzarNyomtatoForm.VAlutaParancs(_ukaz: string);

begin
  ValutaDbase.connected := true;
  if valutatranz.InTransaction then Valutatranz.commit;
  ValutaTranz.StartTransaction;

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


procedure TNapzarNyomtatoForm.KunaNyomtatas;
begin
  _hrknyito   := 0;
  _hrkbevetel := 0;
  _hrkkiadas  := 0;
  _hrkzaro    := 0;

  _pcs := 'SELECT * FROM HRKNAPLO';
  HrkDbase.connected := true;
  with HrkQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno>0 then
    begin
      _pcs := 'SELECT * FROM HRKNAPLO' + _sorveg;
      _pcs := _pcs + 'WHERE DATUM='+chr(39) + _zDatums + chr(39);
      with HrkQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _recno := recno;
        end;

      if _recno=0 then
        begin
          _pcs := 'SELECT * FROM HRKNAPLO ORDER BY DATUM';
          with HrkQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
              Last;
              _hrknyito := FieldByNAme('ZARO').asInteger;
            end;
          Hrkquery.close;

          _hrkbevetel := 0;
          _hrkkiadas  := 0;
          _hrkzaro    := _hrknyito;
        end else
        begin
          with HrkQuery do
            begin
              _hrknyito := Fieldbyname('NYITO').asInteger;
              _hrkbevetel := Fieldbyname('BEVETEL').asInteger;
              _hrkkiadas := Fieldbyname('KIADAS').asInteger;
              _hrkzaro := Fieldbyname('ZARO').asInteger;
            end;
        end;
    end;

  HrkQuery.Close;
  Hrkdbase.Close;

  writeLn(_LFile,'HORVAT KUNA '+ _zDatums + '-I LISTAJA');
  writeLn(_lfILE,dupestring('-',40));
  writeLn(_LFile,' NAPI NYITO OSSZEG .....:  ' + Formkiir(_hrknyito));
  writeLn(_LFile,' ATVETT OSSZEG .........:  ' + Formkiir(_hrkbevetel));
  writeLn(_LFile,' ATADOTT OSSZEG ........:  ' + Formkiir(_hrkkiadas));
  writeLN(_LFile,' NAPI ZARO OSSZEG ......:  ' + Formkiir(_hrkzaro));
  writeLn(_lfILE,dupestring('-',40));
end;
end.

  (*


----------------------------------------
 KEZELESI KOLTSEG 2012.12.12-I LISTAJA
----------------------------------------
NAPI NYITO OSSZEG ......: 123,456,234 Ft
KEZELêSI KOLTSEG .......: 123,456,000 Ft
ATVETT OSSZEG ..........: 123,456,789 Ft
ATADOTT OSSZEG .........: 123,456,789 Ft
NAPI ZARO OSSZEG .......: 123,456,789 Ft
----------------------------------------
   A KEZELESI KOLTSEG TRANZAKCIOI
----------------------------------------
BIZONYLAT  MOZGAS      OSSZEG       PTAR
----------------------------------------
B-123456   atadas  -123,456,789 FT  1234
B-123456   atadas  -123,456,789 FT  1234
B-123456   atadas  -123,456,789 FT  1234
B-123456   atadas  -123,456,789 FT  1234
----------------------------------------
    HORV¡T KUNA 2012.12.12-I LISTAJA
----------------------------------------
NAPI NYITO OSSZEG .....: 123,456,234 HRK
ATVETT OSSZEG .........: 123,456,789 HRK
ATADOTT OSSZEG ........: 123,456,789 HRK
NAPI ZARO OSSZEG ......: 123,456,789 HRK
----------------------------------------



123456789012345678901234567890123456789

   ----------------------------------
   E-kereskedelem 2010.12.30-i zarasa
   ----------------------------------
    Napi nyito ˆsszeg  : 1.234.567 Ft
    Matrica eladas     : 1.234.567 Ft
    Mobilfeltoltes     : 1.234.567 Ft
    Atadas(FRB )       : 1.234.567 Ft
    Atadas(123 )       : 1.234.567 Ft
    Atvetel(FB  )      : 1.234.555 fT

    Napi zaro osszeg   : 1.234.567 Ft
   ----------------------------------



    writeLn(_lfILE,dupestring('-',39));
      writeLn(_LFile,'             Nyito: ' + Form1.Formkiir(_trnyito));
      writeLn(_LFile,'           Matrica: ' + Form1.Formkiir(_trMatrica));
      writeLn(_Lfile,'           Telefon: ' + Form1.Formkiir(_trTelefon));
      writeln(_LFile,'        Penzatadas: ' + Form1.Formkiir(_tratadas));
      writeln(_LFile,'       Penzatvetel: ' + Form1.Formkiir(_tratvetel));
      writeln(_LFile,'              Zaro: ' + Form1.Formkiir(_trzaro));

   ---------------------------------------
   Napi nyito osszeg : 1.234.567 Ft
   Matrica eladas    :
   Telefon feltoltes :
   Ft ·tad·sok  abcd :
                aaaa :
   Ft.atvetelek aaaa :
                bbbb :
   Napi zaro osszeg  :


----------------------------------------
          A MONEYGRAM Z¡R¡SA
----------------------------------------
             HUF       EUR       USD
Nyito:    123456789 123456789 123456789
Bankbol:  123456789 1       9 1        9
Bankba:   123456789 1       9 1        9
Ugyfelnek:123456789 1       9 1        9
Ugyfeltol:123456789 1       9 1        9
Zaro:     123456789 123456789 123456789
}






