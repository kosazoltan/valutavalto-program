unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBCustomDataSet, IBTable, ComCtrls, StdCtrls,
  Buttons, ExtCtrls, strUtils, IBQuery;

type
  TAdatLeGyujtes = class(TForm)

    Csik          : TProgressBar;
    NagyCsik      : TProgressBar;

    ArtQuery      : TIBQuery;
    ArtDbase      : TIBDatabase;
    ArtTranz      : TIBTransaction;

    BlokkTabla    : TIBTable;
    BlokkQuery    : TIBQuery;
    BlokkTranz    : TIBTransaction;
    BlokkDbase    : TIBDatabase;

    NarfQuery     : TIBQuery;
    NarfDbase     : TIBDatabase;
    NarfTranz     : TIBTransaction;

    ReceptorTabla : TIBTable;
    ReceptorQuery : TIBQuery;
    ReceptorDbase : TIBDatabase;
    ReceptorTranz : TIBTransaction;

    Label1        : TLabel;

    UzenoPanel    : TPanel;
    AlcimPanel    : TPanel;

    Shape1        : TShape;
    Kilepo        : TTimer;
    ELSZAMQUERY: TIBQuery;
    ELSZAMDBASE: TIBDatabase;
    ELSZAMTRANZ: TIBTransaction;


    procedure FormActivate(Sender: TObject);

    procedure IrodaBetolto;
    procedure Idoszakbeolvasas;
    procedure GetLastdaysRates;

    procedure CimletGyujtes;
    procedure ForgalomGyujtes;
    procedure ForgalomRutin;
    procedure SendingRutin;
    procedure StornoRegisztracio;
    procedure BankGyujtes;
    procedure TRBGyujtes;
    procedure InterPtControl;
    procedure TRBControl;

    procedure WuniNullazas;
    procedure WuniForgalomGyujtes;
    procedure GetWuniNyitasZaras;
    procedure MetroForgalomGyujtes;
    procedure TescoForgalomGyujtes;
    procedure WuniAfaBerogzites;

    procedure MNBArfolyamLetoltes;

    // --------------------------------------

    procedure KeszletKorzetSummazas;
    procedure KeszletKorzetSumNullazo;
    procedure KeszletKorzetSumRogzito;

    procedure KeszletKftSummazas;
    procedure KeszletKftSumRogzito;

    procedure KeszletCegSummazas;
    procedure KeszletCegSumNullazo;
    procedure KeszletCegSumRogzito;

    // --------------------------------------

    procedure ForgKorzetSummazas;
    procedure ForgKorzetSumNullazo;
    procedure ForgKorzetSumRogzito;

    procedure ForgKftSummazas;
    procedure ForgKftSumRogzito;

    procedure ForgCegSummazas;
    procedure ForgCegSumNullazo;
    procedure ForgCegSumRogzito;

    // ----------------------------------------

    procedure KilepoTimer(Sender: TObject);
    procedure ReceptorParancs(_ukaz: string);
    procedure TablakUritese;
    procedure ElozohoControl;


    function BankScan(_tpt: string): byte;
    function BetubolInteger(_szo: string): integer;
    function CegbetuScan(_betu: string): byte;
    function DnemScan(_vn: string): byte;
    function KorzetScan(_et: integer): byte;
    function MulthaviUtolsoCimNap: string;
    function Nulele(_b: byte): string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AdatLegyujtes: TAdatLegyujtes;

  _kftDarab   : byte = 4;
  _korzetDarab: byte = 9;
  _valutadarab: byte = 27;

  _kftss,_korzss,_valss: byte;

  _bankjel: array[1..6] of string = ('RB','FRB','ERB','TRB','HRB','JRB');
  _korzetszam: array[1..9] of byte = (10,20,40,50,63,75,120,145,180);
  _korzetnev: array[1..9] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
             'DEBRECEN','NYIREGYHÁZ','BÉKÉSCSABA','PÉCS','KAPOSVÁR', 'EXPRESSZ');

  _dTablak: array[1..11] of string = ('FORGALOMGYUJTO','CIMLETGYUJTO','WUNIGYUJTO',
      'PENZTARKOZOTT','TRBGYUJTO','SUMBANKFORGALOM','STORNOFEJ','STORNOTETEL',
      'SUMCIMLET','SUMUGYFELFORGALOM','SUMWUNI');

  _honapnev: array[1..12] of string = ('Január','Február','Március','Április',
               'Május','Junius','Július','Augusztus','Szeptember','Október',
               'November','December');

  _napnev: array[1..7] of string = ('HÉTFÕ','KEDD','SZERDA','CSÜTÖRTÖK','PÉNTEK',
               'SZOMBAT','VASÁRNAP');

  _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY','CZK',
         'DKK','EUR','GBP','HRK','HUF','ILS','JPY','MXN','NOK','NZD','PLN','RON',
         'RSD','RUB','SEK','THB','TRY','UAH','USD');

  _dnev: array[1..27] of string = ('Ausztral dollar','Bosnyak marka','Bolgar leva',
         'Brazil real','Kanadai dollar','Svajci frank','Kinai juan','Cseh korona',
         'Dan korona','Euro','Angol font','Horvat kuna','Magyar forint','Izraeli shakel',
         'Japan jen','Mexikoi peso','Norveg korona','Ujzelandi dollar',
         'Lengyel zloty','Roman lei','Szerb dinar','Orosz rubel','Sved korona',
         'Thai bath','Torok lira','Ukran hrivnya','Usa dollar');

  _sorveg: string = chr(13)+chr(10);
  _betusor: array[1..9] of string;

  _kftnevek: array[1..4] of string = ('BEST CHANGE KFT','EAST CHANGE KFT',
  'PANNON CHANGE KFT','EXPRESSZ ÉKSZERHÁZ KFT');

  _kftbetuk: array[1..4] of string = ('B','E','P','Z');
  _kftBetusor: array[1..9] of string = ('P','B','B','E','E','E','P','P','Z');

  // =================== GLOBÁLIS VÁLTOZÓK =====================================

  _pcs,_farok,_elofarok,_fejtablaNev,_tetTablanev,_cimtarTablanev: string;
  _narfTablaNev,_wunitablanev,_wzarTablanev,_tescoTablanev: string;
  _metroTablanev,_aktFdbPath,_bazis,_keres,_sttipus,_utdnem: string;
  _aktKftBetu,_eloWzarTablanev: string;

  _eloev,_elohonap,_y,_qq,_cc,_utvalss,_aktkorzetszam: word;
  _recno,_code,_mResult: integer;
  _aktertek,_atlelsz,_ftertek: real;
  
  _ezegynap,_kellwuni,_vanvaltas: boolean;


  // =================== IRODABETÖLTÉS VÁLTOZÓI ================================

  _irodaDarab: byte;

  _xnev,_xCegbetu: string;
  _uzlet,_xkorzet,_xvalvaltas,_xwunion: byte;

  _irodanev,_kftbetu: array[1..180] of string;
  _korzet,_wunion,_valvalt,_uzletsor: array[1..180] of byte;

  // ================= IDÕSZAK BEOLVASÁS VÁLTOZÓI ==============================

  _tolstring,_igstring,_idoszakszuro,_fejszuro: string;


  // ==================== CIMLETGYÜJTÉS VÁLTOZOI ===============================

  _elszamarf,_mnbarfolyam: array[1..27] of integer;
  _cim: array[1..14] of word;
  _c1,_c2,_c3,_c4,_c5,_c6,_c7,_c8,_c9,_c10,_c11,_c12,_c13,_c14: word;
   _kDatum,_tema: string;
   _elszarf,_aktelszam: integer;

 // ------------------ OSSZESITÉS VÁLTOZÓ TÖMBÖK -----------------------------

 _elszdb,_elszarfolyam: integer;
 _elszar,_aktelsz,_selszam,_keszlet: real;
 _aktbetu: string;

 // Körzet összesités:

  _skk,_skft: array[1..9,1..27] of real;
  _skc1,_skc2,_skc3,_skc4,_skc5,_skc6,_skc7,_skc8: array[1..9,1..27] of integer;
  _skelsz,_skc9,_skc10,_skc11,_skc12,_skc13,_skc14: array[1..9,1..27] of integer;

  // Kft összesités:

  _sck,_scelsz: array[1..9,1..27] of real;
  _scc1,_scc2,_scc3,_scc4,_scc5,_scc6,_scc7: array[1..9,1..27] of integer;
  _scc8,_scc9,_scc10,_scc11,_scc12,_scc13,_scc14: array[1..9,1..27] of integer;

  // Totál cég (zálog nélkül):

  _xumk,_xumkft: array[1..27] of real;
  _xumc1,_xumc2,_xumc3,_xumc4,_xumc5,_xumc6: array[1..27] of integer;
  _xumc7,_xumc8,_xumc9,_xumc10,_xumc11,_xumc12: array[1..27] of integer;
  _xumc13,_xumc14: array[1..27] of integer;

  // Total cég (záloggal együtt)

  _sumk,_sumkft: array[1..27] of real;
  _sumc1,_sumc2,_sumc3,_sumc4,_sumc5,_sumc6: array[1..27] of integer;
  _sumc7,_sumc8,_sumc9,_sumc10,_sumc11,_sumc12: array[1..27] of integer;
  _sumc13,_sumc14: array[1..27] of integer;

  // =================== FORGALOM VÁLTOZÓI =====================================

  _bizonylat,_datum,_ido,_tipus,_trbptars,_prosnev,_stbiz,_aktdnem: string;
  _elojel,_stornoindok,_penztar,_ftMezo,_mezo,_aktcegbetu: string;

  _bankjegy,_aktelszarf,_aktpenztar,_trbptar,_aktvett,_akteladott: integer;
  _aktvettft,_akteladottFt: real;
  _storno,_penztarszam,_aktkorzet,_kuldo,_fogado: byte;

  _bj,_ee: real;

  _vett,_eladott,_aktedb,_aktelszdb: integer;
  _vettft,_eladottft,_aktkesz: real;

  _ezBank: boolean;
  _kvett,_kEladott,_kelsz: array[1..9,1..27] of integer;
  _kvettft,_keladottft: array[1..9,1..27] of real;

  _cvett,_celadott,_celsz: array[1..4,1..27] of integer;
  _cvettft,_celadottft: array[1..4,1..27] of real;

  _xumvett,_xumeladott,_xumelsz: array[1..27] of integer;
  _xumvettft,_xumeladottft: array[1..27] of real;

  _sumvett,_sumeladott,_sumelsz: array[1..27] of integer;
  _sumvettft,_sumeladottft,_selsz: array[1..27] of real;

  // =================== WZAR BEOLVASAS VÁLTOZÓI ===============================

   _nyitonap,_zaronap: string;
   _usdNyito,_hufNyito,_tescoNyito,_metroNyito,_afaNyito: integer;
   _usdZaro,_hufZaro,_metroZaro,_tescoZaro,_afaZaro: integer;

  // ========================= WESTERN UNION ===================================

  // -------  ALAP VÁLTOZÓK -------------------

  _foegyseg: byte;
  _tranzakcio,_irany: string;

  _usdbe,_hufbe,_afabe,_usdki,_hufki,_afaki: integer;
  _usdGBe,_usdGki,_usdPbe,_usdPki,_usdUbe,_usdUki: integer;
  _hufGBe,_hufGki,_hufPbe,_hufPki,_hufUbe,_hufUki: integer;
  _afaGBe,_afaGki,_afaPbe,_afaPki,_afaUki: integer;

  _tescoGbe,_tescoGki,_tescoPbe,_tescoPki,_tescoUki: integer;
  _metroGbe,_metroGki,_metroPbe,_metroPki,_metroUki: integer;

   // ============== AFAGYUJTES ================================================

  _kifizetve,_ellatmany,_osszBjegy,_bq: integer;

  // =================== PENZTARAK KÖZÖTTI VÁLTOZOK ============================

  _kuldott,_fogadott: integer;
  _status: string;

// =============================================================================  
//##############################################################################
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function summawuniafa: integer; stdcall; external 'c:\receptor\newdll\sumwuafa.dll';

// =============================================================================
                function adatlegyujtorutin: integer; stdcall;
// =============================================================================


implementation
{$R *.dfm}


// =============================================================================
               function adatlegyujtorutin: integer; stdcall;
// =============================================================================

begin
  adatlegyujtes := TAdatLegyujtes.Create(Nil);
  result := adatlegyujtes.showmodal;
  adatlegyujtes.free;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
          procedure TADATLEGYUJTES.FormActivate(Sender: TObject);
// =============================================================================

begin

  Top    := 440;
  Left   := 380;
  Repaint;

  IrodaBetolto;       // 1-180 ptnev,korzet,cégbetu,wunion,valvalt / irodadarab
  MNBArfolyamLetoltes;
  IdoszakBeolvasas;   // -tol+-igstr,szürõk,farok tablanevek

  //  A hyüjtõtáblák kiüritése:
  TablakUritese;       // 11 db delete from dtabla

// ========================  IRODÁK CIKLUSA ====================================

  NagyCsik.Max      := _irodaDarab;    // felsöcsik alapra
  NagyCsik.Position := 0;

  // ===================== ADATKIOLVASÁS CIKLUSFEJE ============================

  _qq := 1;
  while _qq<=_irodaDarab do    // az összes nyitott iroda fdb-n megy végig
    begin
       NagyCsik.Position :=  _qq;

      // következö pénztár alapadatai a pénztárak tömbjeibõl:

      _aktPenzTar  := _uzletsor[_qq];
      _aktKorzet   := _korzet[_aktPenztar];
      _aktCegbetu  := _kftbetu[_aktPenztar];

      _kellwuni    := False;
      if _wunion[_aktpenztar]=1 then _kellwuni := True;

      _vanvaltas   := False;
      if _valvalt[_aktpenztar]=1 then _vanvaltas := True;

      _bazis := 'c:\receptor\database';
      if _aktPenztar>150 then _bazis := 'c:\cartcash\database';
      _aktFdbPath := _bazis + '\v' + inttostr(_aktPenztar)+'.fdb';

      // Ha az aktuális adatbázis nem létezik -> átugorja

      if not Fileexists(_aktFdbPath) then
        begin
          inc(_qq);
          Continue;
        end;

      //  A pénztár adatbázisa létezik - lehet feldolgozni az adatait:

      UzenoPanel.Caption := inttostr(_aktPenztar)+' - '+_irodanev[_aktpenztar];
      UzenoPanel.Repaint;

      // -----------------------------------------------------------------------

      if _VanValtas then   // Van a pénztárban pénzváltás
        begin
          Cimletgyujtes;   // készletek legyüjtése
          ForgalomGyujtes; // forgalom legyüjtése
        end;

      WuniNullazas;        // usd,huf,afa,tesco,metro - nyito,gbe,gki,pbe ..nullázás

      if _kellWuni then    // Van a pénztárban WU vagy AFa:
        begin
          GetWuniNyitasZaras;   // WU és AFA nyitó és Záró adat beolvasdása
          WuniForgalomGyujtes;  // USD és HUF - gbe,gki,pbe.pki,ube,uki adatok beolvasása
          MetroForgalomGyujtes; // metro - gbe,gki,pbe,pki,uki beolvasasa
          TescoForgalomGyujtes; // tesco - pbe,pki,uki adatok beolvasasa
        end;

      WuniAfaBerogzites; // afaadatok = metro+tesco  Adatok rögzitése wunigyujtobe

      inc(_qq);          // kovetkezõ pénztár
    end;

  // --------------- ADATKIOLVASÁS CIKLUSLÁBAZATA ------------------------------


  KeszletKorzetSummazas;
  Nagycsik.Position := 2;

  KeszletKorzetSumRogzito;
  Nagycsik.Position := 3;

  KeszletKftSummazas;
  KeszletkftsumRogzito;
  Nagycsik.position := 4;

  KeszletCegSummazas;
  KeszletCegSumRogzito;

  Nagycsik.Position := 5;

  ForgKorzetSummazas;
  ForgKorzetSumRogzito;

  NagyCsik.Position := 6;
  ForgKftSummazas;
  ForgKftSumRogzito;

  ForgCegSummazas;
  Nagycsik.Position := 7;

  ForgCegSumRogzito;
  Nagycsik.Position := 8;


  summawuniafa;

  Nagycsik.Position := 10;
  sleep(2500);

  _mResult := 1;
  Kilepo.Enabled := True;
end;

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//                            ADATOK LEGYÜJTÉSE
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
                  procedure TAdatlegyujtes.CimletGyujtes;
// =============================================================================

begin

  AlcimPanel.Caption := 'CIMLETEK GYÜJTÉSE';
  AlcimPanel.Repaint;

  // A kért havi cimlettabla neve:

  _cimtarTablanev := 'CIMT' + _farok;
  _narfTablanev   := 'NARF' + _farok;

  NarfDbase.Close;
  NarfDbase.DatabaseName := _aktfdbPath;

  with Blokkdbase do
    begin
      Close;
      DatabaseName := _aktFdbPath;
      Connected := true;
    end;

  Blokktabla.close;
  BlokkTabla.TableName := _cimtarTablaNev;

  // Ha a kért havi cimlettábla nem létezik:

  if not BlokkTabla.exists then
    begin

      // Multhavi utolsó cimlet dátuma:

      _kdatum := MulthaviUtolsoCimNap;

      if _kdatum='' then exit;

       // A cimlettábla neve az elözõ havié:
       _cimTarTablanev := 'CIMT' + _elofarok;
       _narfTablanev   := 'NARF' + _elofarok;

    end else

    // Létezik a kért havi cimlettábla:

    begin
      // Megnyitja a kért-havi cimlettáblát az _igstring vagy elötti
      // dátumig  dátum sorrendben:

      _narftablanev := 'NARF' + _farok;

      _pcs := 'SELECT * FROM '+_cimtarTablaNev + _sorveg;
      _pcs := _pcs + 'WHERE DATUM<='+chr(39) + _igString + chr(39)+_sorveg;
      _pcs := _pcs + 'ORDER BY DATUM';
      with BlokkQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          Last;
          _recno := Recno;
        end;

      // Amennyiben üres a kért-havi cimlettábla:

      if _recNo=0 then
        begin

          // Bekéri az elözõ-havi cimlettábla utolsó dátumát:
          _kdatum := MulthaviUtolsoCimNap();

          //  Ha az elözö-havi cimlettábla is üres - nioncs készlet:
          if _kdatum='' then exit;

          // A cimtar-tabla neve = elözöhavi cimtártábla neve:
          _cimtarTablaNev := 'CIMT' + _elofarok;
          _narfTablanev   := 'NARF' + _elofarok;
        end else
        begin
          // A kért-havi cimletek utolsó dátuma:
          _kdatum := BlokkQuery.FieldByNAme('DATUM').AsString;
        end;
    end;

  // Az IG - napi elszámolási árfolyamok _elszamarf tömbbe irja:
  GetLastdaysRates;

  Receptordbase.connected := true;
  if receptorTranz.InTransaction then receptorTranz.commit;
  ReceptorTranz.StartTransaction;

  // ---------------------------------------------------------------------------
  // Megnyitja a kért-havi (vagy elözö-havi) cimlettáblát az utolsó nap dátumra:

  _pcs := 'SELECT * FROM '+_cimtarTablaNev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39) + _kdatum + chr(39);

  BlokkDbase.Connected := true;
  with BlokkQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  // Az utolsó napi (kért ignaphoz képest) cimletek beolvasása:

  while not BlokkQuery.Eof do
    begin
      // Beolvassa a valuta nemét és összegét:

      _aktDnem := BlokkQuery.FieldbyName('VALUTANEM').asString;
      _keszlet  := BlokkQuery.FieldByname('OSSZESEN').asInteger;

      // Meghatározza a valutanem sorszámát:
      _valss := Dnemscan(_aktDnem);
      if _valss=0 then
        begin
          // Nem létezõ valuta:
          BlokkQuery.Next;
          Continue;
        end;

      // Az aktuális valutanem cikleteit tömbbe olvassa:

      _y := 1;
      while _y<=14 do
        begin
          _tema := 'CIMLET'+inttostr(_y);
          _cim[_y] := BlokkQuery.Fieldbyname(_tema).asInteger;
          inc(_y);
        end;

      _elszArfolyam := _MNBArfolyam[_valss];
      _ftertek := trunc(_elszArfolyam/100*_keszlet);

      _pcs := 'INSERT INTO CIMLETGYUJTO (IRODASZAM,ERTEKTAR,CEGBETU,';
      _pcs := _pcs + 'VALUTANEM,ELSZAMOLASIARFOLYAM,';
      _pcs := _pcs + 'KESZLET,FORINTERTEK,CIMLET1,CIMLET2,CIMLET3,';
      _pcs := _pcs + 'CIMLET4,CIMLET5,CIMLET6,';
      _pcs := _pcs + 'CIMLET7,CIMLET8,CIMLET9,CIMLET10,CIMLET11,';
      _pcs := _pcs + 'CIMLET12,CIMLET13,CIMLET14)'+_sorveg;

      _pcs := _pcs + 'VALUES ('+inttostr(_aktpenztar)+',';
      _pcs := _pcs + inttostr(_aktkorzet)+',';
      _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',';
      _pcs := _pcs + chr(39)+_aktdnem + chr(39)+ ',';
      _pcs := _pcs + inttostr(_elszArfolyam)+',';
      _pcs := _pcs + floattostr(_keszlet)+',';
      _pcs := _pcs + floattostr(_ftertek);

      _y := 1;
      while _y<=14 do
        begin
          _pcs := _pcs + ',' + inttostr(_cim[_y]);
          if _y=14 then _pcs := _pcs + ')';
          inc(_y);
        end;

      with ReceptorQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Execsql;
        end;

      BlokkQuery.next;
    end;
  BlokkQuery.Close;
  Blokkdbase.close;

  Receptortranz.commit;
  ReceptorDbase.close;
end;

// =============================================================================
                 procedure  TadatLegyujtes.ForgalomGyujtes;
// =============================================================================

// A blokkfej- és tétel alapján forgalom,ptközött,trb és banki gyüjtést végez

begin

  // Ellenörzi van-e havi gyütötábla. Ha nincs -> vissza

  Blokktabla.close;
  BlokkTabla.TableName := _fejtablanev;
  Blokkdbase.Connected := true;

  if not Blokktabla.Exists then
    begin
      Blokkdbase.close;
      exit;
    end;

  // -------------------------------------

  AlcimPanel.Caption := 'FORGALOM GYÜJTÉSE';
  AlcimPanel.Repaint;

  _pcs := 'SELECT FEJ.*, TET.*' + _sorveg;
  _pcs := _pcs +'FROM '+_fejtablanev+' FEJ JOIN '+_tettablanev+' TET'+_sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM'+_sorveg;

  _pcs := _pcs + 'WHERE ' +_fejszuro;

  with BlokkQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  // Az összes szürt blokkon végig kell menni:

  Csik.Max := _recno;

  _cc := 0;
   while not BlokkQuery.eof do
     begin
        inc(_cc);
        Csik.Position := _cc;

       // A blokk fontos adatai:

       with BlokkQuery do
         begin
           _storno      := FieldByName('STORNO').ASiNTEGER;
           _bizonylat   := FieldByName('BIZONYLATSZAM').asString;
           _datum       := FieldByName('DATUM').asstring;
           _ido         := FieldByname('IDO').asstring;
           _tipus       := FieldByName('TIPUS').asString;
           _trbptars    := FieldByName('TRBPENZTAR').asString;
           _penztar     := trim(FieldByName('PENZTAR').asString);
           _prosnev     := FieldByName('PENZTAROSNEV').asstring;
           _stbiz       := FieldByname('STORNOBIZONYLAT').asString;
           _aktDnem     := FieldByName('VALUTANEM').asString;
           _bankjegy    := FieldByNAme('BANKJEGY').asInteger;
           _aktelszarf  := FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
           _ftertek     := FieldByNAME('FORINTERTEK').asInteger;
           _elojel      := FieldByName('ELOJEL').asString;
           _stornoIndok := FieldByName('SZALLITONEV').AsString;
         end;

        _valss := Dnemscan(_aktDnem);
        if _valss<1 then
          begin
            BlokkQuery.next;
            Continue;
          end;

       // -------------- A storno(zott) bizonylatok registrálása ---------------

       if _storno>1 then
         begin
           StornoRegisztracio;
           BlokkQuery.Next;
           Continue;
         end;

       // ---------    A _penztar és _trbPenztar normalizálása -----------------

       _trbPtar := BetubolInteger(_trbpTars);

       // A pénztárstring normalizálása:

       if _penztar = '' then _penztar := '0' else _penztar := trim(_penztar);
       _penztarSzam := BetubolInteger(_penztar);


   // Az elszámolási árfolyamot a Napi árfolyamból veszi:
   // _elszamolasiarfolyam := GetElszamar(_datum,_aktdnem);

       if (_tipus='V') or (_tipus='E') then  ForgalomRutin else SendingRutin;
       BlokkQuery.Next;
     end;
   BlokkQuery.close;
end;


// =============================================================================
                  procedure Tadatlegyujtes.GetWuniNyitasZaras;
// =============================================================================

var _nyitonap,_zaronap: string;

begin
  // Ellanörzi van-e WZAR havi tábla:

  AlcimPanel.Caption := 'W.U. + AFA nyitó- és záró-készletei';
  Alcimpanel.Repaint;

  Blokktabla.TableName := _wzarTablanev;
  with BlokkDbase do
    begin
      Close;
      Databasename := _aktfdbpath;
      Connected := true;
    end;

  if not Blokktabla.Exists then
    begin
      BLokkdbase.close;
      elozohoControl;
      exit;
    end;

  _pcs := 'SELECT * FROM ' + _wzarTablanev + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with BlokkQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      Blokkquery.close;
      Blokkdbase.close;
      ElozohoCOntrol;
      exit;
    end;

  // Az e-havi wzar tábla utolsó rekordjáról indulunk, amig el nem érjük
  // a kezdönapot vagy annál régebbi napot, vagy a tábla elejét (BOF)

  _usdNyito   := 0;
  _hufNyito   := 0;
  _metroNyito := 0;
  _tescoNyito := 0;

  _usdZaro    := 0;
  _hufZaro    := 0;
  _metroZaro  := 0;
  _tescoZaro  := 0;

  _nyitoNap := '';
  _zaronap  := '';

  if _recno>0 then
    begin
      while not BlokkQuery.Eof do
        begin
          _datum := BlokkQuery.FieldByNAme('DATUM').asString;
          if (_datum>=_tolstring) and (_nyitonap='') then _nyitonap := _datum;
          if (_datum=_igstring) then
            begin
              _zaronap := _datum;
              Break;
            end;

          if (_datum>_igstring) then
            begin
              BlokkQuery.Prior;
              if Blokkquery.Bof then break;
              _zaronap := Blokkquery.FieldByNAme('DATUM').asString;
              break;
            end;
          BlokkQuery.next;
        end;
    end;
  if (_zaronap='') then _zaronap := _datum;


  if _nyitonap<>'' then
    begin
      Blokkquery.Locate('DATUM',_nyitonap,[loPartialkey]);
      with BlokkQuery do
        begin
          _usdNyito   := FieldByNAme('USDNYITO').asInteger;
          _hufNyito   := FieldByNAme('HUFNYITO').asInteger;
          _metroNyito := FieldByNAme('METRONYITO').asInteger;
          _tescoNyito := FieldByName('TESCONYITO').asInteger;
        end;

      Blokkquery.Locate('DATUM',_zaronap,[loPartialkey]);
      with BlokkQuery do
        begin
          _usdZaro := FieldByNAme('USDZARO').asInteger;
          _hufZaro := FieldByNAme('HUFZARO').asInteger;
          _metroZaro := FieldByNAme('METROZARO').asInteger;
          _tescoZaro  := FieldByName('TESCOZARO').asInteger;
        end;
    end;
   _afaNyito := _metroNyito+_tescoNyito;
   _afaZaro  := _metroZaro+_tescoZaro;

   Blokkquery.close;
   Blokkdbase.close;
end;


// =============================================================================
                procedure TadatLegyujtes.ElozohoControl;
// =============================================================================

begin
  _eloWzarTablanev := 'WZAR' + _eloFarok;
  Blokktabla.close;
  BlokkTabla.TableName := _eloWzarTablanev;
  Blokkdbase.connected := true;
  if not Blokktabla.exists then
    begin
      Blokkdbase.close;
      exit;
    end;  


  _pcs := 'SELECT * FROM ' + _elowzarTablanev + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with BlokkQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      Blokkquery.close;
      Blokkdbase.close;
      exit;
    end;
   with BlokkQuery do
     begin
       _usdZaro := FieldByNAme('USDZARO').asInteger;
       _hufZaro := FieldByNAme('HUFZARO').asInteger;
       _metroZaro := FieldByNAme('METROZARO').asInteger;
       _tescoZaro  := FieldByName('TESCOZARO').asInteger;
     end;

   BlokkQuery.close;
   Blokkdbase.close;
end;




// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
                procedure Tadatlegyujtes.WuniForgalomGyujtes;
// =============================================================================


begin
   Blokktabla.close;
   BlokkTabla.TableName := _wunitablanev;
   Blokkdbase.Connected := True;
   if not Blokktabla.Exists then
     begin
       Blokkdbase.close;
       exit;
     end;

  AlcimPanel.Caption := 'W.U. FORGALOM GYÜJTÉSE';
  AlcimPanel.Repaint;

  _pcs := 'SELECT * FROM '+ _wuniTablanev + _sorveg;
  _pcs := _pcs + 'WHERE '+ _idoszakszuro + ' AND (STORNO=1)';

  with BlokkQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  if BlokkQuery.Recno=0 then
    begin
      BlokkQuery.close;
      Exit;
    end;

  while not BlokkQuery.eof do
    begin
      with BlokkQuery do
        begin
          _foegyseg := FieldByName('FOEGYSEG').asInteger;
          _aktdnem := FieldByName('VALUTANEM').asString;
          _bankjegy := FieldByName('BANKJEGY').asInteger;
          _Tranzakcio := FieldByName('TRANZAKCIOTIPUS').asstring;
        end;

      _irany := Leftstr(_tranzakcio,1);
      if (_foegyseg<2) and (_aktDnem='USD') and (_irany='+') then
             _usdGbe := _usdGbe + _bankJegy;

      if (_foegyseg<2) and (_aktDnem='USD') and (_irany='-') then
             _usdGKi := _usdGKi + _bankJegy;

       if (_foegyseg<2) and (_aktDnem='HUF') and (_irany='+') then
             _hufGbe := _hufGbe + _bankJegy;

      if (_foegyseg<2) and (_aktDnem='HUF') and (_irany='-') then
             _hufGKi := _hufGKi + _bankJegy;

      // -----------------------------------------------------------------------

      if (_foegyseg=2) and (_aktdnem='USD') and (_irany='+') then
             _usdPbe := _usdPbe + _bankJegy;

      if (_foegyseg=2) and (_aktdnem='USD') and (_irany='-') then
             _usdPKi := _usdPKi + _bankJegy;

       if (_foegyseg=2) and (_aktdnem='HUF') and (_irany='+') then
             _hufPbe := _hufPbe + _bankJegy;

      if (_foegyseg=2) and (_aktdnem='HUF') and (_irany='-') then
             _hufPKi := _hufPKi + _bankJegy;

      // -----------------------------------------------------------------------

      if (_foegyseg=5) and (_aktdnem='USD') and (_irany='+') then
             _usdUbe := _usdUbe + _bankJegy;

      if (_foegyseg=5) and (_aktdnem='USD') and (_irany='-') then
             _usdUKi := _usdUKi + _bankJegy;

       if (_foegyseg=5) and (_aktdnem='HUF') and (_irany='+') then
             _hufube := _hufUbe + _bankJegy;

      if (_foegyseg=5) and (_aktdnem='HUF') and (_irany='-') then
             _hufUKi := _hufUKi + _bankJegy;

      // -----------------------------------------------------------------------

      BlokkQuery.Next;
    end;
  BlokkQuery.Close;
end;


// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
                 procedure Tadatlegyujtes.MetroForgalomGyujtes;
// =============================================================================

begin

  Blokktabla.close;
  BlokkTabla.TableName := _metroTablanev;
  Blokkdbase.Connected := true;
  if not blokktabla.Exists then
    begin
      Blokkdbase.close;
      exit;
    end;

  AlcimPanel.Caption := 'METRO FORGALOM GYÜJTÉSE';
  AlcimPanel.Repaint;


  _pcs := 'SELECT * FROM '+ _metroTablaNev + _sorveg;
  _pcs := _pcs +'WHERE '+ _idoszakszuro + ' AND (STORNO=1)';

  with BlokkQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  if BlokkQuery.Recno=0 then
    begin
      BlokkQuery.close;
      Exit;
    end;

  while not BlokkQuery.eof do
    begin
      with BlokkQuery do
        begin
          _foegyseg   := FieldByName('FOEGYSEG').asInteger;
          _kifizetve  := FieldByName('KIFIZETVE').asInteger;
          _ellatmany  := FieldByName('ELLATMANY').asInteger;
          _Tranzakcio := FieldByName('TRANZAKCIOTIPUS').asstring;
        end;

      _irany := Leftstr(_tranzakcio,1);
      if (_foegyseg=3) and (_irany='+') then
             _metroGbe := _metroGbe + _ellatmany;

      if (_foegyseg=3) and (_irany='-') then
             _metroGKi := _metroGKi + _ellatmany;

      // -----------------------------------------------------------------------

      if (_foegyseg=4) and (_irany='+') then
             _metroPbe := _metroPbe + _ellatmany;

      if (_foegyseg=4) and (_irany='-') then
             _metroPKI := _metropKi + _ellatmany;

      // -----------------------------------------------------------------------

      if (_foegyseg=6) then
             _metroUKI := _metroUKI + _kifizetve;

      // -----------------------------------------------------------------------

      BlokkQuery.Next;
    end;
  BlokkQuery.Close;
 
end;

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
              procedure Tadatlegyujtes.TescoForgalomGyujtes;
// =============================================================================

begin
   Blokktabla.close;
   blokktabla.TableName := _tescoTablanev;
   Blokkdbase.connected := True;
   if not Blokktabla.Exists then
     begin
       Blokkdbase.close;
       exit;
     end;

  AlcimPanel.Caption := 'TESCO FORGALOM GYÜJTÉSE';
  AlcimPanel.Repaint;


  _pcs := 'SELECT * FROM '+ _TescoTablaNev + _sorveg;
  _pcs := _pcs + 'WHERE '+ _idoszakszuro;

  with BlokkQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  if BlokkQuery.Recno=0 then
    begin
      BlokkQuery.close;
      Exit;
    end;

  while not BlokkQuery.eof do
    begin
      with BlokkQuery do
        begin
          _osszBjegy := FieldByName('OSSZESEN').asInteger;
          _Tranzakcio := FieldByName('TIPUS').asstring;
        end;

      if _tranzakcio='B' then _tescoPbe := _tescoPbe + _osszBjegy;
      if _tranzakcio='K' then _tescoPki := _tescoPki + _osszBjegy;
      if _tranzakcio='V' then _tescoUKi := _tescoUki + _osszBjegy;

      BlokkQuery.Next;

    end;
  BlokkQuery.Close;

end;


// =============================================================================
                      procedure TadatLegyujtes.ForgalomRutin;
// =============================================================================
// ---------------------- A FORGALOMGYÜJTÉS subrutinja -------------------------

//       IDE KERÜLNEK A VÉTEL ÉS ELADÁS KONVERZIÓ BIZONYLATOK TÉTELEI
// A forgalomgyüjtöbe gyüjti a VETT,ELADOTT,VETTERTEK ÉS ELADOTTERTEK mezöket


begin

  // A forint nem forgalom :

  if _aktdnem= 'HUF' then exit;

  // A gyüjtött mezök kijelölése:

  if _tipus ='V' then _mezo := 'VETT' else _mezo := 'ELADOTT';
  _ftMezo := _mezo + 'ERTEK';    // VETTERTEK vagy ELADOTTERTEK

  // ennek az irodának van már ilyen valutája gyüjtve?

  _pcs := 'SELECT * FROM FORGALOMGYUJTO'+_sorveg;
  _pcs := _pcs + 'WHERE IRODASZAM='+inttostr(_aktpenztar)+' and VALUTANEM='+chr(39)+_aktDnem+chr(39);

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  if _recno=0 then  // Ez új bejegyzés
    begin
      _pcs := 'INSERT INTO FORGALOMGYUJTO (VALUTANEM,IRODASZAM,CEGBETU,';
      _pcs := _pcs + 'ERTEKTAR,ELSZAMOLASIARFOLYAM,'+_mezo+','+_ftmezo+')'+_sorveg;
      _pcs := _pcs + 'VALUES (' +chr(39) + _aktDnem +chr(39)+',';
      _pcs := _pcs + inttostr(_aktpenztar)+',';
      _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',';

      if _aktcegbetu='Z' then _aktKorzet := 180;

      _pcs := _pcs + inttostr(_aktKorzet)+',';
      _pcs := _pcs + inttostr(_aktelszarf)+',';
      _pcs := _pcs + floattostr(_bankjegy)+',';
      _pcs := _pcs + floattoStr(_ftertek)+')';
    end else
    begin   // ez gyüjtött bejegyzés

      _bj := ReceptorQuery.FieldByName(_mezo).asInteger;
      _ee := ReceptorQuery.FieldByName(_ftMezo).asInteger;

      _bj := _bj + _bankjegy;
      _ee := _ee + _ftertek;

      _pcs := 'UPDATE FORGALOMGYUJTO'+_sorveg;
      _pcs := _pcs + 'SET '+_mezo+'='+floattostr(_bj)+',';
      _pcs := _pcs + _ftmezo + '='+floattostr(_ee)+_sorveg;
      _pcs := _pcs + 'WHERE IRODASZAM='+inttostr(_aktpenztar)+' AND VALUTANEM='+chr(39)+_aktdnem+chr(39);
    end;

  ReceptorParancs(_pcs);
end;

// =============================================================================
          procedure TadatLegyujtes.ReceptorParancs(_ukaz: string);
// =============================================================================

begin
  ReceptorDbase.Connected := True;
  if ReceptorTranz.InTransaction then receptorTranz.Commit;
  ReceptorTranz.StartTransaction;

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_ukaz);
      ExecSql;
    end;

  receptorTranz.commit;
  receptordbase.close;
end;

// =============================================================================
                    procedure TadatLegyujtes.SendingRutin;
// =============================================================================
// ---------------------- A FORGALOMGYÜJTÉS subrutinja -------------------------
//                IDE KERÜLNEK AZ F ÉS U TIPUSÚ BIZONYLATOK TÉTELEI:

begin

  // A trb és banki bizonylatok lekezelése:

  if _penztarszam<2 then
    begin
      if _penztar='TRB' then
        begin
          TRBGyujtes;  // TRB ÉRTÉKEK GYÜJTÉSE
          exit;
        end;

      // -------------- Itt a TRB-n kivüli bizonylatojk (ERB,RB,JRB ...) -------

      _ezBank := False;
      _bq := BankScan(_penztar);

      if _bq>0 then _ezbank := True;
      if _ezbank then BankGyujtes;   // BANKI ADATOK GYÜJTÉSE
      exit;
    end;

  // ------- ITT A PÉNZTÁRAK KÖZÖTTI MOZGÁSOKAT GYÜJTI -------------------------

  // ------- aktuális mezök meghatározása: -----

  if _tipus = 'F' then
    begin
      _kuldo := _aktpenztar;
      _fogado := _penzTarszam;
      _mezo := 'KULDOTT';
    end else
    begin
      _kuldo := _penztarszam;
      _fogado := _aktPenztar;
      _mezo := 'FOGADOTT';
    end;

   _keres := inttostr(_kuldo)+_aktDnem+inttostr(_fogado);

  // ------------- pénztárak közötti forgalom ----------------------------------

  _pcs := 'SELECT * FROM PENZTARKOZOTT' + _sorveg;
  _pcs := _pcs + 'WHERE KULDODNEMFOGADO=' + chr(39) + _keres + chr(39);

  ReceptorDbase.connected := true;
  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  if _recno=0 then
    begin
      _pcs := 'INSERT INTO PENZTARKOZOTT (VALUTANEM,KULDO,FOGADO,';
      _pcs := _pcs + 'KULDODNEMFOGADO,'+_mezo+')'+_sorveg;

      _pcs := _pcs + 'VALUES ('+chr(39)+_aktDnem+chr(39)+',';
      _pcs := _pcs + inttostr(_KULDO) + ',';
      _pcs := _pcs + inttostr(_FOGADO) + ',';
      _pcs := _pcs + chr(39) + _keres + chr(39)+',';
      _pcs := _pcs + floattostr(_bankjegy)+')';
    end else
    begin
      _bj := ReceptorQuery.FieldByName(_mezo).asInteger;
      _bj := _bj + _bankjegy;

      _pcs := 'UPDATE PENZTARKOZOTT'+_sorveg;
      _pcs := _pcs + 'SET '+_mezo+'='+floattostr(_bj)+_sorveg;
      _pcs := _pcs + 'WHERE KULDODNEMFOGADO='+chr(39)+_keres+chr(39);
    end;
  ReceptorQuery.close;
  ReceptorDbase.close;

  ReceptorParancs(_pcs);

end;

// =============================================================================
                     procedure TadatLegyujtes.TRBGyujtes;
// =============================================================================
// ----------------- A SENDING PROCEDURE SUBROUTINJA ---------------------------
//                       TRB BIZONYLATOK GYÜJTÉSE

begin
  if _tipus = 'F' then
    begin
      _kuldo := _aktpenztar;
      _fogado := _trbptar;
      _mezo := 'KULDOTT';
    end else
    begin
      _kuldo := _trbPtar;
      _fogado := _aktPenztar;
      _mezo := 'FOGADOTT';
    end;

  _pcs := 'Select * From TRBGYUJTO'+_sorveg;
  _pcs := _pcs + 'where Valutanem='+chr(39)+_aktDnem+chr(39)+' AND ';
  _pcs := _pcs + 'KULDO='+inttostr(_kuldo)+' AND FOGADO='+inttostr(_fogado);

  ReceptorDbase.Connected := true;
  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  if _recno=0 then
    begin
      _pcs := 'INSERT INTO TRBGYUJTO (VALUTANEM,KULDO,FOGADO,'+_mezo+')'+_sorveg;
      _pcs := _pcs+'VALUES ('+chr(39)+_aktDnem+chr(39)+','+inttostr(_KULDO)+','+inttostr(_FOGADO);
      _pcs := _pcs+','+floattostr(_bankjegy)+')';
    end else
    begin
      _bj := ReceptorQuery.FieldByName(_mezo).asInteger;
      _bj := _bj + _bankjegy;

      _pcs := 'UPDATE TRBGYUJTO'+_sorveg;
      _pcs := _pcs + 'SET '+_mezo+'='+floattostr(_bj)+_sorveg;
      _pcs := _pcs +'WHERE VALUTANEM='+CHR(39)+_aktDnem+chr(39)+' AND ';
      _pcs := _pcs + 'KULDO='+inttostr(_kuldo)+' AND FOGADO='+inttostr(_fogado);
    end;
  ReceptorQuery.close;
  ReceptorDbase.close;

  ReceptorParancs(_pcs);

end;

// =============================================================================
                   procedure TadatLegyujtes.BankGyujtes;
// =============================================================================
// ----------------- A SENDING PROCEDURE SUBROUTINJA ---------------------------
//                        BANKI BIZONYLATOK GYÜJTÉSE

begin

  if _tipus = 'F' then _mezo := 'BEFIZETETTKP' else _mezo := 'FELVETTKP';

  _pcs := 'SELECT * FROM SUMBANKFORGALOM'+_sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM='+chr(39)+_aktDnem+chr(39);

  ReceptorDbase.Connected := true;
  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  if _recno=0 then
    begin
      _pcs := 'INSERT INTO SUMBANKFORGALOM (VALUTANEM,'+_mezo+')'+_sorveg;
      _pcs := _pcs+'VALUES ('+chr(39)+_aktDnem+chr(39)+','+floatToStr(_bankjegy)+')';
    end else
    begin
      _bj := ReceptorQuery.FieldByName(_mezo).asInteger;
      _bj := _bj + _bankjegy;

      _pcs := 'UPDATE SUMBANKFORGALOM'+_sorveg;
      _pcs := _pcs + 'SET '+_mezo+'='+floattostr(_bj)+_sorveg;
      _pcs := _pcs + 'WHERE VALUTANEM='+chr(39)+_aktdnem+chr(39);
    end;

  receptorQuery.close;
  ReceptorDbase.close;

  ReceptorParancs(_pcs);

end;

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


// =============================================================================
             function TAdatLegyujtes.MulthaviUtolsoCimNap: string;
// =============================================================================
// -------------- A CIMLETGYÜJTÉS PROCEDURE FUNKCIÓJA --------------------------

begin
  // A kért havi cimlettábla nem létezik

  result := '';

  // At elözõ havi cimlettábla neve:

  _cimTarTablaNev := 'CIMT'+ _elofarok;

  BlokkDbase.Connected := true;
  Blokktabla.close;
  BlokkTabla.TableName := _cimtarTablaNev;

  // Ha elözõ hõnapban sincs cimlettábla -> vissza: üres string

  if not BlokkTabla.exists then
    begin
      Blokkdbase.close;
      exit;
    end;

  //  Megnyitja az elözõhavi cimlettáblát Dátum sorrendben:

  _pcs := 'SELECT * FROM ' + _cimtarTablanev + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with BlokkQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _recno := recno;
    end;

  // Múlt havi utolsó dátumú rekord nincs -> üres a cimlettábla
  if _RecNo=0 then
    begin
      BlokkQuery.Close;
      Blokkdbase.close;
      Exit;
    end;

  // Visszaadja az utolsó rekord dátumát a múlt havi cimleteknek:
  Result := BlokkQuery.FieldByNAme('DATUM').AsString;
  BlokkQuery.Close;
end;


// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
                 procedure TadatLegyujtes.InterPtControl;
// =============================================================================

begin
  with ReceptorTabla do
    begin
      TableName := 'PENZTARKOZOTT';
      Open;
      Refresh;
      First;
    end;


  while not ReceptorTabla.eof do
    begin

      _kuldott := ReceptorTabla.FieldByName('KULDOTT').asInteger;
      _fogadott := ReceptorTabla.FieldByName('FOGADOTT').asInteger;
      _status := 'OK';
      if _kuldott<>_fogadott then _status := '?';
      with ReceptorTabla do
        begin
          Edit;
          FieldByNAme('STATUS').AsString := _status;
          Post;
        end;
      ReceptorTabla.Next;
    end;
  ReceptorTabla.Close;
end;


// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
                  procedure TadatLegyujtes.TRBControl;
// =============================================================================

begin

  ReceptorDbase.Connected := true;
  with ReceptorTabla do
    begin
      TableName := 'TRBGYUJTO';
      Open;
      Refresh;
      First;
    end;

  while not ReceptorTabla.eof do
    begin
      _kuldott := ReceptorTabla.FieldByName('KULDOTT').asInteger;
      _fogadott := ReceptorTabla.FieldByName('FOGADOTT').asInteger;
      _status := 'OK';
      if _kuldott<>_fogadott then _status := '?';
      with ReceptorTabla do
        begin
          Edit;
          FieldByNAme('STATUS').AsString := _status;
          Post;
        end;
      ReceptorTabla.Next;
    end;
  ReceptorTranz.Commit;
  ReceptorTabla.Close;
end;


// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


// =============================================================================
                procedure Tadatlegyujtes.StornoRegisztracio;
// =============================================================================
// ------------------- FORGALOMGYUJTES SUBRUTINJA ------------------------------

begin
  if _storno=2 then _STTIPUS := 'STORNOZOTT' ELSE  _STTIPUS:= 'STORNO';

  _pcs := 'INSERT INTO STORNOFEJ (IRODASZAM,CEGBETU,BIZONYLATSZAM,DATUM,';
  _pcs := _pcs + 'IDO,PENZTAROSNEV,STORNOTIPUS,STORNOBIZONYLAT,STORNOINDOK)'+_sorveg;

  _pcs := _pcs + 'VALUES ('+inttostr(_aktpenztar)+',';
  _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylat+chr(39)+',';
  _pcs := _pcs + chr(39) + _datum+chr(39)+',';
  _pcs := _pcs + chr(39) + _ido+chr(39)+',';
  _pcs := _pcs + chr(39) + _prosnev+chr(39)+',';
  _pcs := _pcs + chr(39) + _sttipus+chr(39)+',';
  _pcs := _pcs + chr(39) + _stBiz+chr(39)+',';
  _pcs := _pcs + chr(39) + trim(_stornoindok)+chr(39)+')';

  receptorParancs(_pcs);

  _pcs := 'INSERT INTO STORNOTETEL (IRODASZAM,CEGBETU,BIZONYLATSZAM,VALUTANEM,';
  _pcs := _pcs + 'BANKJEGY,FORINTERTEK)'+_SORVEG;
  _pcs := _pcs + 'VALUES ('+inttostr(_aktpenztar)+',';
  _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',';
  _pcs := _pcs + chr(39)+_bizonylat +chr(39)+',';
  _pcs := _pcs + chr(39)+_aktdnem+chr(39)+',';
  _pcs := _pcs + floattostr(_bankjegy)+',';
  _pcs := _pcs + floattostr(_ftertek)+')';

  ReceptorParancs(_pcs);
end;

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
                procedure TadatLegyujtes.WuniAfaBerogzites;
// =============================================================================

begin

  AlcimPanel.Caption := 'W.U. + AFA ADATOK BERÖGZITÉSE';
  AlcimPanel.Repaint;

  _afanyito := _metronyito + _tesconyito;

  _afagbe   := _metrogbe + _tescoGbe;
  _afaGki   := _metroGki + _tescoGki;
  _afaPbe   := _metroPbe + _tescoPbe;
  _afaPki   := _metroPki + _tescoPki;
  _afaUki   := _metroUki + _tescoUki;

  _usdbe := _usdgbe+_usdpbe+_usdube;
  _hufbe := _hufgbe+_hufpbe+_hufube;
  _afabe := _afagbe+_afapbe;

  _usdki := _usdgki+_usdpki+_usduki;
  _hufki := _hufgki+_hufpki+_hufuki;
  _afaki := _afaGki+_afaPki+_afaUki;




  _pcs := 'INSERT INTO WUNIGYUJTO (IRODASZAM,ERTEKTAR,CEGBETU,USDNYITO,';
  _pcs := _pcs + 'HUFNYITO,AFANYITO,USDZARO,HUFZARO,AFAZARO,USDGBE,HUFGBE,';
  _pcs := _pcs + 'AFAGBE,USDGKI,HUFGKI,AFAGKI,USDPBE,HUFPBE,AFAPBE,USDPKI,';
  _pcs := _pcs + 'HUFPKI,AFAPKI,USDUBE,HUFUBE,USDUKI,HUFUKI,AFAUKI,';
  _pcs := _pcs + 'USDBE,HUFBE,AFABE,USDKI,HUFKI,AFAKI)' + _sorveg;


  _pcs := _pcs + 'VALUES ('+ inttostr(_aktpenztar) + ',';
  _pcs := _pcs + inttostr(_aktkorzet) + ',';
  _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',';
  _pcs := _pcs + inttostr(_usdnyito)+',';
  _pcs := _pcs + inttostr(_hufnyito)+',';
  _pcs := _pcs + inttostr(_afanyito)+',';
  _pcs := _pcs + inttostr(_usdzaro)+',';
  _pcs := _pcs + inttostr(_hufzaro)+',';
  _pcs := _pcs + inttostr(_afazaro)+',';
  _pcs := _pcs + inttostr(_usdgbe)+',';
  _pcs := _pcs + inttostr(_hufgbe)+',';
  _pcs := _pcs + inttostr(_afagbe)+',';
  _pcs := _pcs + inttostr(_usdgki)+',';
  _pcs := _pcs + inttostr(_hufgki)+',';
  _pcs := _pcs + inttostr(_afaGki)+',';
  _pcs := _pcs + inttostr(_usdPbe)+',';
  _pcs := _pcs + inttostr(_hufpbe)+',';
  _pcs := _pcs + inttostr(_afapbe)+',';
  _pcs := _pcs + inttostr(_usdpki)+',';
  _pcs := _pcs + inttostr(_hufpki)+',';
  _pcs := _pcs + inttostr(_afapki)+',';
  _pcs := _pcs + inttostr(_usdube)+',';
  _pcs := _pcs + inttostr(_hufube)+',';
  _pcs := _pcs + inttostr(_usduki)+',';
  _pcs := _pcs + inttostr(_hufuki)+',';
  _pcs := _pcs + inttostr(_afauki)+',';

  _pcs := _pcs + inttostr(_usdbe)+',';
  _pcs := _pcs + inttostr(_hufbe)+',';
  _pcs := _pcs + inttostr(_afabe)+',';

  _pcs := _pcs + inttostr(_usdki)+',';
  _pcs := _pcs + inttostr(_hufki)+',';
  _pcs := _pcs + inttostr(_afaki)+')';
  ReceptorParancs(_pcs);
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//                         SEGÉD PROGRAMOK
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
             procedure Tadatlegyujtes.TablakUritese;
// =============================================================================

var _tnev: string;

begin
  _y := 1;
  while _y<=11 do
    begin
      _tnev := _dTablak[_y];
      _pcs := 'DELETE FROM ' + _tNev;
      ReceptorParancs(_pcs);
      inc(_y);
    end;
end;


// =============================================================================
       function TAdatlegyujtes.BetubolInteger(_szo: string): integer;
// =============================================================================
// -------------  A FORGALOMGYUJTES FUNKCIÓJA ----------------------------------

var _szam,j: integer;
    _allDigit : string;
    _kod : Byte;

begin
  Result := 0;
  if _szo='' then exit;

  _szo := Trim(_szo);
  _allDigit := '';

  for j := 1 to length(_szo) do
    begin
      _kod := ord(_szo[j]);
      if (_kod>47) and (_kod<58) then _alldigit := _alldigit + chr(_kod);
    end;

  if _alldigit='' then exit;
  val(_szo,_szam,_code);

  if _code<>0 then _szam := 0;
  Result := _szam;
end;

// =============================================================================
               function TAdatlegyujtes.Nulele(_b:byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
                 procedure TAdatlegyujtes.IrodaBetolto;
// =============================================================================

begin

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE CLOSED=' + chr(39) + 'N' + chr(39) + _sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  ReceptorDbase.Connected := true;
  with ReceptorQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  _IrodaDarab := 0;
  while not ReceptorQuery.Eof do
    begin
      with ReceptorQuery do
        begin
          _uzlet     := FieldByName('UZLET').asInteger;
          _xnev      := trim(FieldByNAme('KESZLETNEV').asString);
          _xkorzet   := FieldByName('ERTEKTAR').asInteger;
          _xcegbetu  := FieldByname('CEGBETU').asstring;
          _xValvaltas:= FieldByNAme('VALUTAVALTAS').asInteger;
          _xwunion   := FieldByNAme('WESTERNUNION').asInteger;
        end;

      inc(_irodaDarab);

      _uzletsor[_irodaDarab] := _uzlet;

      _irodanev[_uzlet] := _xNev;
      _kftbetu[_uzlet]  := _xCegbetu;
      _korzet[_uzlet]   := _xKorzet;
      _wunion[_uzlet]   := _xWunion;
      _valvalt[_uzlet]  := _xValValtas;

      ReceptorQuery.next;
    end;

  ReceptorQuery.close;
  Receptordbase.close;

  // --------------------------------------------------

  Artdbase.connected := true;
  with Artquery do
    begin
      Close;
      sql.clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  while not ArtQuery.eof do
    begin
      with ArtQuery do
        begin
          _uzlet      := FieldByName('UZLET').asInteger;
          _xnev       := trim(FieldByNAme('KESZLETNEV').asString);
          _xValValtas := FieldByName('VALUTAVALTAS').asInteger;
          _xWunion    := FieldByNAme('WESTERNUNION').asInteger;
        end;

      inc(_irodaDarab);

      _uzletsor[_irodaDarab] := _uzlet;

      _irodanev[_uzlet] := _xNev;
      _kftbetu[_uzlet]  := 'Z';
      _korzet[_uzlet]   := 180;
      _wunion[_uzlet]   := _xWunion;
      _valvalt[_uzlet]  := _xValValtas;

      ArtQuery.next;
    end;
  ArtQuery.close;
  Artdbase.close;
end;

// =============================================================================
          function TAdatlegyujtes.DnemScan(_vn: string): byte;
// =============================================================================

var _y: byte;
begin
  Result := 0;
  for _y := 1 to 27 do
    begin
      if _vn = _dnem[_y] then
        begin
          Result := _y;
          Break;
        end;
    end;
end;

//==============================================================================
          function TAdatlegyujtes.KorzetScan(_et: integer): byte;
// =============================================================================

(* Visszaadja a paraméterben adott értéktár tömbbeli sorszámát *)

begin
  result := 0;
  _korzss := 1;
  while _korzss<=_korzetdarab do
    begin
      if _korzetszam[_korzss] = _et then
        begin
          result := _korzss;
          break;
        end;
        inc(_korzss);
    end;

end;

// =============================================================================
           function TAdatlegyujtes.BankScan(_tpt: string): byte;
// =============================================================================

var j: integer;
   _bj: string;

begin
  result := 0;
  for j := 1 to 6 do
    begin
      _bj := _bankjel[j];
      if _bj=_tpt then
        begin
          result := j;
          exit;
        end;
    end;
end;

// =============================================================================
           function TAdatLegyujtes.CegbetuScan(_betu: string): byte;
// =============================================================================

begin
  result := 1;
  _betu := uppercase(_betu);
  if _betu='B' then exit;
  inc(result);
  if _betu='E' then exit;
  inc(result);
  if _betu='P' then exit;
  inc(result);
end;

// =============================================================================
          procedure TAdatLeGyujtes.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := _mResult;
end;


// =============================================================================
                procedure TAdatLegyujtes.IdoszakBeolvasas;
// =============================================================================

begin
  ReceptorDbase.Connected := true;
  with ReceptorQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM IDOSZAK');
      Open;

      _tolstring := FieldByNAme('STARTDATE').asString;
      _igstring := FieldByName('ENDDATE').asString;
      Close;
    end;
  ReceptorDbase.close;

  _idoszakszuro := '(DATUM>='+chr(39)+_tolstring+chr(39)+') AND (DATUM<=';
  _idoszakszuro := _idoszakszuro + chr(39)+_igstring + chr(39) + ')';

  _fejszuro := '(FEJ.DATUM>='+chr(39)+_tolstring+chr(39)+') AND (FEJ.DATUM<=';
  _fejszuro := _fejszuro + chr(39)+_igstring + chr(39) + ')';

  _farok    := midstr(_tolstring,3,2)+midstr(_tolstring,6,2);

  _eloev    := strtoint(leftstr(_farok,2));
  _eloHonap := strtoint(midstr(_farok,3,2));

  dec(_EloHonap);
  if _elohonap=0 then
    begin
      dec(_eloev);
      _elohonap := 12;
    end;

  _eloFarok := nulele(_eloev)+nulele(_elohonap);

  _ezEgyNap := False;
  if (_tolstring=_igstring) then _ezegynap := True;

  if _ezegynap then
    begin
      _idoszakszuro := '(DATUM='+chr(39)+_igstring+chr(39)+')';
      _fejszuro := '(FEJ.DATUM='+chr(39)+_igstring+chr(39)+')';
    end;

  // A havi táblanevek megállapítása:

  _fejTablanev    := 'BF'   + _farok;
  _tetTablaNev    := 'BT'   + _farok;
  _cimtarTablanev := 'CIMT' + _farok;
  _narfTablaNev   := 'NARF' + _farok;
  _wzarTablanev   := 'WZAR' + _farok;
  _wuniTablaNev   := 'WUNI' + _farok;
  _metroTablaNev  := 'WAFA' + _farok;
  _tescoTablanev  := 'TESC' + _farok;
end;

// =============================================================================
                  procedure TAdatLegyujtes.GetLastdaysRates;
// =============================================================================

begin
 _y := 1;
  while _y<=27 do
    begin
      _elszamarf[_y] := 0;
      inc(_y);
    end;

  //  Kiolvassa az utolsó napi elszámolási arfolyamokat:

  NarfDbase.Connected := true;

  _pcs := 'SELECT * FROM ' + _narftablanev + _sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM<>'+chr(39) + 'EUA' + chr(39);

  with NarfQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  while not NarfQuery.Eof do
    begin
      _aktDnem := NarfQuery.fieldByNAme('VALUTANEM').asString;
      _elszarf := NarfQuery.FieldByName('ELSZAMOLASIARFOLYAM').asInteger;

      _valss := Dnemscan(_aktdnem);
      if _valss>0 then _elszamarf[_valss] := _elszarf;

      NarfQuery.next;
    end;

  NarfQuery.close;
  NarfDbase.close;
end;


// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$   NULLAZASOK  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

// =============================================================================
                  procedure TAdatLegyujtes.WuniNullazas;
// =============================================================================


begin
  AlcimPanel.Caption := 'W.U. + AFA adatok nullázása';
  AlcimPanel.repaint;

  _usdNyito   := 0;
  _hufNyito   := 0;
  _metronyito := 0;
  _tesconyito := 0;
  _afaNyito   := 0;

  _usdGBe     := 0;
  _hufGBe     := 0;
  _metroGBe   := 0;
  _tescoGBe   := 0;
  _afaGBe     := 0;

  _usdGKi     := 0;
  _hufGKi     := 0;
  _metroGKi   := 0;
  _tescoGKi   := 0;
  _afaGKi     := 0;

  _usdPBe     := 0;
  _hufPBe     := 0;
  _metroPBe   := 0;
  _tescoPBe   := 0;
  _afaPBe     := 0;

  _usdPKi     := 0;
  _hufPKi     := 0;
  _metroPKi   := 0;
  _tescoPKi   := 0;
  _afaPKi     := 0;

  _usdUBe     := 0;
  _hufUBe     := 0;

  _usdUKi     := 0;
  _hufUKi     := 0;
  _metroUKi   := 0;
  _tescoUKi   := 0;
  _afaUki     := 0;

  _usdZaro    := 0;
  _hufZaro    := 0;
  _metroZaro  := 0;
  _tescoZaro  := 0;
  _afaZaro    := 0;
end;





// =============================================================================
               procedure TAdatlegyujtes.KeszletKorzetSummazas;
// =============================================================================

begin

  KeszletKorzetSumNullazo;

  UzenoPanel.Caption := 'KÉSZLETEK ÖSSZESÍTÉSE';
  UzenoPanel.repaint;

  Nagycsik.Max      := 10;
  Nagycsik.position := 1;

  // ---------------------------------------------------------------------------
  // Megnyitja a CimletGyüjtöt, ahol az eddig gyüjtött adatok vannak:

  ReceptorDbase.Connected := true;
  _pcs := 'SELECT * FROM CIMLETGYUJTO';

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  Csik.Position := 0;
  Csik.max      := _RecNo;

  _cc := 0;

  // Ha nincs egyetlen adat sem gyüjtve, nincs mit összesiteni !

  if _recno=0 then
    begin
      ReceptorTranz.Commit;
      ReceptorQuery.Close;
      Exit;
    end;

  // ---------------------------------------------------------------------------
  //  A cimletgyüjtöt rekordonként kiolvassa:

  while not ReceptorQuery.Eof do
    begin
      inc(_cc);
      Csik.Position := _cc;

      with ReceptorQuery do
        begin
          _aktkorzet    := FieldByNAme('ERTEKTAR').asInteger;
          _aktdnem      := FieldByName('VALUTANEM').asString;
          _elszarfolyam := FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
          _keszlet      := FieldByName('KESZLET').asInteger;
          _ftertek      := FieldByName('FORINTERTEK').asInteger;

          _c1 := FieldByNAme('CIMLET1').asInteger;
          _c2 := FieldByNAme('CIMLET2').asInteger;
          _c3 := FieldByNAme('CIMLET3').asInteger;
          _c4 := FieldByNAme('CIMLET4').asInteger;
          _c5 := FieldByNAme('CIMLET5').asInteger;
          _c6 := FieldByNAme('CIMLET6').asInteger;
          _c7 := FieldByNAme('CIMLET7').asInteger;
          _c8 := FieldByNAme('CIMLET8').asInteger;
          _c9 := FieldByNAme('CIMLET9').asInteger;
          _c10 := FieldByNAme('CIMLET10').asInteger;
          _c11 := FieldByNAme('CIMLET11').asInteger;
          _c12 := FieldByNAme('CIMLET12').asInteger;
          _c13 := FieldByNAme('CIMLET13').asInteger;
          _c14 := FieldByNAme('CIMLET14').asInteger;
        end;

      _valss      := DnemScan(_aktdnem);
      _korzss     := Korzetscan(_aktkorzet);
      _aktkftbetu := _kftbetusor[_korzss];

      _skk[_korzss,_valss]   := _skk[_korzss,_valss]  + _keszlet;
      _skft[_korzss,_valss]  := _skft[_korzss,_valss] + _ftertek;
      _skelsz[_korzss,_valss]:= _elszarfolyam;
      _skc1[_korzss,_valss]  := _skc1[_korzss,_valss]  + _c1;
      _skc2[_korzss,_valss]  := _skc2[_korzss,_valss]  + _c2;
      _skc3[_korzss,_valss]  := _skc3[_korzss,_valss]  + _c3;
      _skc4[_korzss,_valss]  := _skc4[_korzss,_valss]  + _c4;
      _skc5[_korzss,_valss]  := _skc5[_korzss,_valss]  + _c5;
      _skc6[_korzss,_valss]  := _skc6[_korzss,_valss]  + _c6;
      _skc7[_korzss,_valss]  := _skc7[_korzss,_valss]  + _c7;
      _skc8[_korzss,_valss]  := _skc8[_korzss,_valss]  + _c8;
      _skc9[_korzss,_valss]  := _skc9[_korzss,_valss]  + _c9;
      _skc10[_korzss,_valss] := _skc10[_korzss,_valss] + _c10;
      _skc11[_korzss,_valss] := _skc11[_korzss,_valss] + _c11;
      _skc12[_korzss,_valss] := _skc12[_korzss,_valss] + _c12;
      _skc13[_korzss,_valss] := _skc13[_korzss,_valss] + _c13;
      _skc14[_korzss,_valss] := _skc14[_korzss,_valss] + _c14;

      receptorQuery.next;
    end;
  ReceptorQuery.close;
  ReceptorDbase.close;
end;

// =============================================================================
                  procedure TAdatlegyujtes.KeszletKorzetSumRogzito;
// =============================================================================

begin
  Alcimpanel.Caption := 'Készlet körzetösszesitõ rögzitése';
  AlcimPanel.repaint;

  receptorDbase.connected := true;
  if receptortranz.intransaction then receptorTranz.commit;
  ReceptorTranz.StartTransaction;

  _korzss := 1;
  while _korzss<=_korzetdarab do
    begin
      _aktkorzetszam := _korzetszam[_korzss];
      _aktcegbetu := _kftbetusor[_korzss];
      _valss := 1;
      while _valss<=_valutadarab do
        begin
          _aktdnem := _dnem[_valss];
          _keszlet := _skk[_korzss,_valss];
          _elszarfolyam := _skelsz[_korzss,_valss];
          _ftertek := _skft[_korzss,_valss];

          _c1  := _skc1[_korzss,_valss];
          _c2  := _skc2[_korzss,_valss];
          _c3  := _skc3[_korzss,_valss];
          _c4  := _skc4[_korzss,_valss];
          _c5  := _skc5[_korzss,_valss];
          _c6  := _skc6[_korzss,_valss];
          _c7  := _skc7[_korzss,_valss];
          _c8  := _skc8[_korzss,_valss];
          _c9  := _skc9[_korzss,_valss];
          _c10 := _skc10[_korzss,_valss];
          _c11 := _skc11[_korzss,_valss];
          _c12 := _skc12[_korzss,_valss];
          _c13 := _skc13[_korzss,_valss];
          _c14 := _skc14[_korzss,_valss];

          _pcs := 'INSERT INTO CIMLETGYUJTO (ERTEKTAR,IRODASZAM,CEGBETU,';
          _pcs := _pcs + 'VALUTANEM,ELSZAMOLASIARFOLYAM,KESZLET,FORINTERTEK,';
          _pcs := _pcs + 'CIMLET1,CIMLET2,CIMLET3,CIMLET4,CIMLET5,CIMLET6,';
          _pcs := _pcs + 'CIMLET7,CIMLET8,CIMLET9,CIMLET10,CIMLET11,CIMLET12,';
          _pcs := _pcs + 'CIMLET13,CIMLET14)' + _sorveg;

          _pcs := _pcs + 'VALUES (' + inttostr(_aktkorzetszam) + ',0,';
          _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',';
          _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
          _pcs := _pcs + floattostr(_elszarfolyam) + ',';
          _pcs := _pcs + floattostr(_keszlet) + ',';
          _pcs := _pcs + floattostr(_ftertek) + ',';
          _pcs := _pcs + inttostr(_c1) + ',';
          _pcs := _pcs + inttostr(_c2) + ',';
          _pcs := _pcs + inttostr(_c3) + ',';
          _pcs := _pcs + inttostr(_c4) + ',';
          _pcs := _pcs + inttostr(_c5) + ',';
          _pcs := _pcs + inttostr(_c6) + ',';
          _pcs := _pcs + inttostr(_c7) + ',';
          _pcs := _pcs + inttostr(_c8) + ',';
          _pcs := _pcs + inttostr(_c9) + ',';
          _pcs := _pcs + inttostr(_c10) + ',';
          _pcs := _pcs + inttostr(_c11) + ',';
          _pcs := _pcs + inttostr(_c12) + ',';
          _pcs := _pcs + inttostr(_c13) + ',';
          _pcs := _pcs + inttostr(_c14) + ')';

          with ReceptorQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Execsql;
            end;
          inc(_valss);
        end;
      inc(_korzss);
    end;
  Receptortranz.COmmit;
  Receptordbase.close;
end;

// =============================================================================
          procedure TadatLegyujtes.KeszletKorzetSumNullazo;
// =============================================================================

begin

  Alcimpanel.caption := 'Körzet készletösszesitõ nullázása';
  AlcimPanel.repaint;

  Csik.Max := _korzetdarab;
  _korzss := 1;

  while _korzss<=_korzetdarab do
    begin
      _valss := 1;
      csik.position := _korzss;

      while _valss<=_valutadarab do
        begin
           _skk[_korzss,_valss]  := 0;
           _skft[_korzss,_valss] := 0;
           _skelsz[_korzss,_valss] := 0;
           _skc1[_korzss,_valss] := 0;
           _skc2[_korzss,_valss] := 0;
           _skc3[_korzss,_valss] := 0;
           _skc4[_korzss,_valss] := 0;
           _skc5[_korzss,_valss] := 0;
           _skc6[_korzss,_valss] := 0;
           _skc7[_korzss,_valss] := 0;
           _skc8[_korzss,_valss] := 0;
           _skc9[_korzss,_valss] := 0;
          _skc10[_korzss,_valss] := 0;
          _skc11[_korzss,_valss] := 0;
          _skc12[_korzss,_valss] := 0;
          _skc13[_korzss,_valss] := 0;
          _skc14[_korzss,_valss] := 0;
          inc(_valss);
        end;
      inc(_korzss);
    end;
end;

// =============================================================================
               procedure  TadatLegyujtes.KeszletKftSummazas;
// =============================================================================

begin
  Alcimpanel.Caption := 'Kfték készleteinek összesitése';
  Alcimpanel.repaint;

  KeszletKorzetSumNullazo;

  ReceptorDbase.Connected := true;
  _pcs := 'SELECT * FROM CIMLETGYUJTO' + _sorveg;
  _pcs := _pcs + 'WHERE (IRODASZAM=0) AND (ERTEKTAR>0)';

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  Csik.Position := 0;
  Csik.max      := _RecNo;

  _cc := 0;

  // Ha nincs egyetlen adat sem gyüjtve, nincs mit összesiteni !

  if _recno=0 then
    begin
      ReceptorTranz.Commit;
      ReceptorQuery.Close;
      Exit;
    end;


  while not ReceptorQuery.Eof do
    begin
      inc(_cc);
      Csik.Position := _cc;

      with ReceptorQuery do
        begin
          _aktdnem      := FieldByName('VALUTANEM').asString;
          _aktcegbetu   := FieldByName('CEGBETU').asString;
          _elszarfolyam := FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
          _keszlet      := FieldByName('KESZLET').asFloat;
          _ftertek      := FieldByName('FORINTERTEK').asFloat;

          _c1 := FieldByNAme('CIMLET1').asInteger;
          _c2 := FieldByNAme('CIMLET2').asInteger;
          _c3 := FieldByNAme('CIMLET3').asInteger;
          _c4 := FieldByNAme('CIMLET4').asInteger;
          _c5 := FieldByNAme('CIMLET5').asInteger;
          _c6 := FieldByNAme('CIMLET6').asInteger;
          _c7 := FieldByNAme('CIMLET7').asInteger;
          _c8 := FieldByNAme('CIMLET8').asInteger;
          _c9 := FieldByNAme('CIMLET9').asInteger;
          _c10 := FieldByNAme('CIMLET10').asInteger;
          _c11 := FieldByNAme('CIMLET11').asInteger;
          _c12 := FieldByNAme('CIMLET12').asInteger;
          _c13 := FieldByNAme('CIMLET13').asInteger;
          _c14 := FieldByNAme('CIMLET14').asInteger;
        end;

      _kftss := Cegbetuscan(_aktCegBetu);
      _valss := Dnemscan(_aktdnem);

       _skk[_kftss,_valss]   := _skk[_kftss,_valss]   + _keszlet;
       _skft[_kftss,_valss] := _skft[_kftss,_valss] + _ftErtek;
       _skelsz[_kftss,_valss]  := _elszarfolyam;
       _skc1[_kftss,_valss]  := _skc1[_kftss,_valss]  + _c1;
       _skc2[_kftss,_valss]  := _skc2[_kftss,_valss]  + _c2;
       _skc3[_kftss,_valss]  := _skc3[_kftss,_valss]  + _c3;
       _skc4[_kftss,_valss]  := _skc4[_kftss,_valss]  + _c4;
       _skc5[_kftss,_valss]  := _skc5[_kftss,_valss]  + _c5;
       _skc6[_kftss,_valss]  := _skc6[_kftss,_valss]  + _c6;
       _skc7[_kftss,_valss]  := _skc7[_kftss,_valss]  + _c7;
       _skc8[_kftss,_valss]  := _skc8[_kftss,_valss]  + _c8;
       _skc9[_kftss,_valss]  := _skc9[_kftss,_valss]  + _c9;
      _skc10[_kftss,_valss] := _skc10[_kftss,_valss] + _c10;
      _skc11[_kftss,_valss] := _skc11[_kftss,_valss] + _c11;
      _skc12[_kftss,_valss] := _skc12[_kftss,_valss] + _c12;
      _skc13[_kftss,_valss] := _skc13[_kftss,_valss] + _c13;
      _skc14[_kftss,_valss] := _skc14[_kftss,_valss] + _c14;

      receptorQuery.next;
    end;
  ReceptorQuery.close;
  ReceptorDbase.close;
end;


// =============================================================================
           procedure TAdatlegyujtes.KeszletKftSumRogzito;
// =============================================================================

begin
  Alcimpanel.Caption := 'KFT-ék készleteinek rögzitése';
  Alcimpanel.Repaint;

  receptorDbase.connected := true;
  if receptortranz.intransaction then receptorTranz.commit;
  ReceptorTranz.StartTransaction;

  _kftss := 1;
  while _kftss<=_kftdarab do
    begin
      _aktcegbetu := _kftBetuk[_kftss];
      _valss := 1;
      while _valss<=_valutadarab do
        begin
          _aktdnem := _dnem[_valss];
          _keszlet := _skk[_kftss,_valss];
          _elszarfolyam := _skelsz[_kftss,_valss];
          _ftertek := _skft[_kftss,_valss];

          _c1  := _skc1[_kftss,_valss];
          _c2  := _skc2[_kftss,_valss];
          _c3  := _skc3[_kftss,_valss];
          _c4  := _skc4[_kftss,_valss];
          _c5  := _skc5[_kftss,_valss];
          _c6  := _skc6[_kftss,_valss];
          _c7  := _skc7[_kftss,_valss];
          _c8  := _skc8[_kftss,_valss];
          _c9  := _skc9[_kftss,_valss];
          _c10 :=_skc10[_kftss,_valss];
          _c11 :=_skc11[_kftss,_valss];
          _c12 :=_skc12[_kftss,_valss];
          _c13 :=_skc13[_kftss,_valss];
          _c14 :=_skc14[_kftss,_valss];

          _pcs := 'INSERT INTO CIMLETGYUJTO (ERTEKTAR,IRODASZAM,CEGBETU,';
          _pcs := _pcs + 'VALUTANEM,ELSZAMOLASIARFOLYAM,KESZLET,FORINTERTEK,';
          _pcs := _pcs + 'CIMLET1,CIMLET2,CIMLET3,CIMLET4,CIMLET5,CIMLET6,';
          _pcs := _pcs + 'CIMLET7,CIMLET8,CIMLET9,CIMLET10,CIMLET11,CIMLET12,';
          _pcs := _pcs + 'CIMLET13,CIMLET14)' + _sorveg;

          _pcs := _pcs + 'VALUES (0,0,';
          _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',';
          _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
          _pcs := _pcs + inttostr(_elszarfolyam) + ',';
          _pcs := _pcs + floattostr(_keszlet) + ',';
          _pcs := _pcs + floattostr(_ftertek) + ',';
          _pcs := _pcs + inttostr(_c1) + ',';
          _pcs := _pcs + inttostr(_c2) + ',';
          _pcs := _pcs + inttostr(_c3) + ',';
          _pcs := _pcs + inttostr(_c4) + ',';
          _pcs := _pcs + inttostr(_c5) + ',';
          _pcs := _pcs + inttostr(_c6) + ',';
          _pcs := _pcs + inttostr(_c7) + ',';
          _pcs := _pcs + inttostr(_c8) + ',';
          _pcs := _pcs + inttostr(_c9) + ',';
          _pcs := _pcs + inttostr(_c10) + ',';
          _pcs := _pcs + inttostr(_c11) + ',';
          _pcs := _pcs + inttostr(_c12) + ',';
          _pcs := _pcs + inttostr(_c13) + ',';
          _pcs := _pcs + inttostr(_c14) + ')';

          with ReceptorQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Execsql;
            end;
          inc(_valss);
        end;
      inc(_kftss);
    end;
  Receptortranz.COmmit;
  Receptordbase.close;
end;

// =============================================================================
            procedure TadatLegyujtes.KeszletCegSummazas;
// =============================================================================

begin
  Alcimpanel.Caption := 'Teljes cég készlet összesitése';
  AlcimPanel.Repaint;

  KeszletCegSumNullazo;

  _pcs := 'SELECT * FROM CIMLETGYUJTO' + _sorveg;
  _pcs := _pcs + 'WHERE (IRODASZAM=0) AND (ERTEKTAR=0)'+_sorveg;
  _pcs := _pcs + 'ORDER BY CEGBETU';

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  // Ha nincs egyetlen adat sem gyüjtve, nincs mit összesiteni !

  if _recno=0 then
    begin
      ReceptorTranz.Commit;
      ReceptorQuery.Close;
      Exit;
    end;

  while not ReceptorQuery.Eof do
    begin
      with ReceptorQuery do
        begin
          _aktdnem      := FieldByName('VALUTANEM').asString;
          _aktcegbetu   := FieldByName('CEGBETU').asString;
          _elszarfolyam := FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
          _keszlet      := FieldByName('KESZLET').asFloat;
          _ftertek      := FieldByName('FORINTERTEK').asFloat;
          _c1           := FieldByNAme('CIMLET1').asInteger;
          _c2           := FieldByNAme('CIMLET2').asInteger;
          _c3           := FieldByNAme('CIMLET3').asInteger;
          _c4           := FieldByNAme('CIMLET4').asInteger;
          _c5           := FieldByNAme('CIMLET5').asInteger;
          _c6           := FieldByNAme('CIMLET6').asInteger;
          _c7           := FieldByNAme('CIMLET7').asInteger;
          _c8           := FieldByNAme('CIMLET8').asInteger;
          _c9           := FieldByNAme('CIMLET9').asInteger;
          _c10          := FieldByNAme('CIMLET10').asInteger;
          _c11          := FieldByNAme('CIMLET11').asInteger;
          _c12          := FieldByNAme('CIMLET12').asInteger;
          _c13          := FieldByNAme('CIMLET13').asInteger;
          _c14          := FieldByNAme('CIMLET14').asInteger;
        end;

      _valss := dnemscan(_aktdnem);

      if _aktCegbetu<>'Z' then
        begin
          _sumk[_valss]  := _sumk[_valss]   + _keszlet;
          _sumkft[_valss] := _sumkft[_valss] + _ftertek;
          _sumelsz[_valss] := _elszarfolyam;
          _sumc1[_valss] := _sumc1[_valss]  + _c1;
          _sumc2[_valss] := _sumc2[_valss]  + _c2;
          _sumc3[_valss] := _sumc3[_valss]  + _c3;
          _sumc4[_valss] := _sumc4[_valss]  + _c4;
          _sumc5[_valss] := _sumc5[_valss]  + _c5;
          _sumc6[_valss] := _sumc6[_valss]  + _c6;
          _sumc7[_valss] := _sumc7[_valss]  + _c7;
          _sumc8[_valss] := _sumc8[_valss]  + _c8;
          _sumc9[_valss] := _sumc9[_valss]  + _c9;
          _sumc10[_valss]:= _sumc10[_valss] + _c10;
          _sumc11[_valss]:= _sumc11[_valss] + _c11;
          _sumc12[_valss]:= _sumc12[_valss] + _c12;
          _sumc13[_valss]:= _sumc13[_valss] + _c13;
          _sumc14[_valss]:= _sumc14[_valss] + _c14;
        end;

      _xumk[_valss]  := _xumk[_valss]   + _keszlet;
      _xumkft[_valss]:= _xumkft[_valss] + _ftertek;
      _xumelsz[_valss] := _elszarfolyam;
      _xumc1[_valss] := _xumc1[_valss]  + _c1;
      _xumc2[_valss] := _xumc2[_valss]  + _c2;
      _xumc3[_valss] := _xumc3[_valss]  + _c3;
      _xumc4[_valss] := _xumc4[_valss]  + _c4;
      _xumc5[_valss] := _xumc5[_valss]  + _c5;
      _xumc6[_valss] := _xumc6[_valss]  + _c6;
      _xumc7[_valss] := _xumc7[_valss]  + _c7;
      _xumc8[_valss] := _xumc8[_valss]  + _c8;
      _xumc9[_valss] := _xumc9[_valss]  + _c9;
      _xumc10[_valss]:= _xumc10[_valss] + _c10;
      _xumc11[_valss]:= _xumc11[_valss] + _c11;
      _xumc12[_valss]:= _xumc12[_valss] + _c12;
      _xumc13[_valss]:= _xumc13[_valss] + _c13;
      _xumc14[_valss]:= _xumc14[_valss] + _c14;
      receptorQuery.next;
    end;
  receptorquery.close;
  receptordbase.close;
end;

// =============================================================================
             procedure Tadatlegyujtes.KeszletCegSumNullazo;
// =============================================================================

begin
  _valss := 1;
  while _valss<=_valutadarab do
    begin
      _sumk[_valss]  := 0;
      _sumkft[_valss] := 0;
      _sumelsz[_valss] := 0;
      _sumc1[_valss] := 0;
      _sumc2[_valss] := 0;
      _sumc3[_valss] := 0;
      _sumc4[_valss] := 0;
      _sumc5[_valss] := 0;
      _sumc6[_valss] := 0;
      _sumc7[_valss] := 0;
      _sumc8[_valss] := 0;
      _sumc9[_valss] := 0;
      _sumc10[_valss]:= 0;
      _sumc11[_valss]:= 0;
      _sumc12[_valss]:= 0;
      _sumc13[_valss]:= 0;
      _sumc14[_valss]:= 0;

      _xumk[_valss]  := 0;
      _xumkft[_valss] := 0;
      _xumelsz[_valss] := 0;
      _xumc1[_valss] := 0;
      _xumc2[_valss] := 0;
      _xumc3[_valss] := 0;
      _xumc4[_valss] := 0;
      _xumc5[_valss] := 0;
      _xumc6[_valss] := 0;
      _xumc7[_valss] := 0;
      _xumc8[_valss] := 0;
      _xumc9[_valss] := 0;
      _xumc10[_valss]:= 0;
      _xumc11[_valss]:= 0;
      _xumc12[_valss]:= 0;
      _xumc13[_valss]:= 0;
      _xumc14[_valss]:= 0;

      inc(_valss);
    end;
end;

// =============================================================================
           procedure TAdatlegyujtes.KeszletCegSumRogzito;
// =============================================================================

begin
  ReceptorDbase.connected := true;
  if ReceptorTranz.InTransaction then ReceptorTranz.Commit;
  ReceptorTranz.StartTransaction;

  _valss := 1;
  while _valss<=_valutadarab do
    begin
      _aktdnem := _dnem[_valss];
      _keszlet := _sumk[_valss];
      _ftertek := _sumkft[_valss];
      _elszarfolyam := _sumelsz[_valss];

      _c1  := _sumc1[_valss];
      _c2  := _sumc2[_valss];
      _c3  := _sumc3[_valss];
      _c4  := _sumc4[_valss];
      _c5  := _sumc5[_valss];
      _c6  := _sumc6[_valss];
      _c7  := _sumc7[_valss];
      _c8  := _sumc8[_valss];
      _c9  := _sumc9[_valss];
      _c10 := _sumc10[_valss];
      _c11 := _sumc11[_valss];
      _c12 := _sumc12[_valss];
      _c13 := _sumc13[_valss];
      _c14 := _sumc14[_valss];

      _pcs := 'INSERT INTO CIMLETGYUJTO (ERTEKTAR,IRODASZAM,CEGBETU,';
      _pcs := _pcs + 'VALUTANEM,ELSZAMOLASIARFOLYAM,KESZLET,FORINTERTEK,';
      _pcs := _pcs + 'CIMLET1,CIMLET2,CIMLET3,CIMLET4,CIMLET5,CIMLET6,';
      _pcs := _pcs + 'CIMLET7,CIMLET8,CIMLET9,CIMLET10,CIMLET11,CIMLET12,';
      _pcs := _pcs + 'CIMLET13,CIMLET14)' + _sorveg;

      _pcs := _pcs + 'VALUES (-1,0,';
      _pcs := _pcs + chr(39) + chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + inttostr(_elszarfolyam) + ',';
      _pcs := _pcs + floattostr(_keszlet) + ',';
      _pcs := _pcs + floattostr(_ftertek) + ',';
      _pcs := _pcs + inttostr(_c1) + ',';
      _pcs := _pcs + inttostr(_c2) + ',';
      _pcs := _pcs + inttostr(_c3) + ',';
      _pcs := _pcs + inttostr(_c4) + ',';
      _pcs := _pcs + inttostr(_c5) + ',';
      _pcs := _pcs + inttostr(_c6) + ',';
      _pcs := _pcs + inttostr(_c7) + ',';
      _pcs := _pcs + inttostr(_c8) + ',';
      _pcs := _pcs + inttostr(_c9) + ',';
      _pcs := _pcs + inttostr(_c10) + ',';
      _pcs := _pcs + inttostr(_c11) + ',';
      _pcs := _pcs + inttostr(_c12) + ',';
      _pcs := _pcs + inttostr(_c13) + ',';
      _pcs := _pcs + inttostr(_c14) + ')';

      with ReceptorQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Execsql;
        end;

      // ----------------------

      _keszlet := _xumk[_valss];
      _elszarfolyam := _xumelsz[_valss];
      _ftertek := _xumkft[_valss];

      _c1  := _xumc1[_valss];
      _c2  := _xumc2[_valss];
      _c3  := _xumc3[_valss];
      _c4  := _xumc4[_valss];
      _c5  := _xumc5[_valss];
      _c6  := _xumc6[_valss];
      _c7  := _xumc7[_valss];
      _c8  := _xumc8[_valss];
      _c9  := _xumc9[_valss];
      _c10 := _xumc10[_valss];
      _c11 := _xumc11[_valss];
      _c12 := _xumc12[_valss];
      _c13 := _xumc13[_valss];
      _c14 := _xumc14[_valss];

      _pcs := 'INSERT INTO CIMLETGYUJTO (ERTEKTAR,IRODASZAM,CEGBETU,';
      _pcs := _pcs + 'VALUTANEM,ELSZAMOLASIARFOLYAM,KESZLET,FORINTERTEK,';
      _pcs := _pcs + 'CIMLET1,CIMLET2,CIMLET3,CIMLET4,CIMLET5,CIMLET6,';
      _pcs := _pcs + 'CIMLET7,CIMLET8,CIMLET9,CIMLET10,CIMLET11,CIMLET12,';
      _pcs := _pcs + 'CIMLET13,CIMLET14)' + _sorveg;

      _pcs := _pcs + 'VALUES (-2,0,';
      _pcs := _pcs + chr(39) + chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + inttostr(_elszarfolyam) + ',';
      _pcs := _pcs + floattostr(_keszlet) + ',';
      _pcs := _pcs + floattostr(_ftertek) + ',';
      _pcs := _pcs + inttostr(_c1) + ',';
      _pcs := _pcs + inttostr(_c2) + ',';
      _pcs := _pcs + inttostr(_c3) + ',';
      _pcs := _pcs + inttostr(_c4) + ',';
      _pcs := _pcs + inttostr(_c5) + ',';
      _pcs := _pcs + inttostr(_c6) + ',';
      _pcs := _pcs + inttostr(_c7) + ',';
      _pcs := _pcs + inttostr(_c8) + ',';
      _pcs := _pcs + inttostr(_c9) + ',';
      _pcs := _pcs + inttostr(_c10) + ',';
      _pcs := _pcs + inttostr(_c11) + ',';
      _pcs := _pcs + inttostr(_c12) + ',';
      _pcs := _pcs + inttostr(_c13) + ',';
      _pcs := _pcs + inttostr(_c14) + ')';

      with ReceptorQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Execsql;
        end;
      inc(_valss);
    end;

  Receptortranz.COmmit;
  Receptordbase.close;
end;

// =============================================================================
           procedure TAdatlegyujtes.ForgKorzetSummazas;
// =============================================================================

begin
  Alcimpanel.Caption := 'Körzetforgalom összesitése';
  Alcimpanel.Repaint;

  ForgKorzetSumNullazo;

  UzenoPanel.Caption := 'FROGALOM ÖSSZESÍTÉSE';
  UzenoPanel.repaint;

  Nagycsik.Max      := 10;
  Nagycsik.position := 1;

  // ---------------------------------------------------------------------------
  // Megnyitja a CimletGyüjtöt, ahol az eddig gyüjtött adatok vannak:

  ReceptorDbase.Connected := true;
  _pcs := 'SELECT * FROM FORGALOMGYUJTO';

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  Csik.Position := 0;
  Csik.max      := _RecNo;

  _cc := 0;

  // Ha nincs egyetlen adat sem gyüjtve, nincs mit összesiteni !

  if _recno=0 then
    begin
      ReceptorTranz.Commit;
      ReceptorQuery.Close;
      Exit;
    end;

  // ---------------------------------------------------------------------------
  //  A cimletgyüjtöt rekordonként kiolvassa:

  while not ReceptorQuery.Eof do
    begin
      inc(_cc);
      Csik.Position := _cc;

      with ReceptorQuery do
        begin
          _aktkorzet    := FieldByNAme('ERTEKTAR').asInteger;
          _aktdnem      := FieldByName('VALUTANEM').asString;
          _vett         := FieldByName('VETT').asInteger;
          _eladott      := FieldByName('ELADOTT').asInteger;
          _vettft       := FieldByName('VETTERTEK').asFloat;
          _eladottft    := FieldByNAme('ELADOTTERTEK').asfloat;
          _elszarfolyam := FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
        end;

      _valss      := DnemScan(_aktdnem);
      _korzss     := Korzetscan(_aktkorzet);
      _aktkftbetu := _kftbetusor[_korzss];

      _kVett[_korzss,_valss] := _kVett[_korzss,_valss] + _vett;
      _kEladott[_korzss,_valss] := _kEladott[_korzss,_valss] + _eladott;
      _kVettft[_korzss,_valss] := _kVettFt[_korzss,_valss] + _vettft;
      _kEladottft[_korzss,_valss] := _kEladottft[_korzss,_valss] + _eladottft;
      _kelsz[_korzss,_valss] := _elszarfolyam;
      ReceptorQuery.next;
    end;
  ReceptorQuery.close;
  Receptordbase.close;
end;

// =============================================================================
           procedure TAdatlegyujtes.ForgKorzetSumNullazo;
// =============================================================================

begin
  _korzss := 1;
  while _korzss<=_korzetdarab do
    begin
      _valss := 1;
      while _valss<=_valutaDarab do
         begin
           _kvett[_korzss,_valss] := 0;
           _keladott[_korzss,_valss] := 0;
           _kvettft[_korzss,_valss] := 0;
           _keladottft[_korzss,_valss] := 0;
           inc(_valss);
         end;
       inc(_korzss);
     end;
end;

// =============================================================================
           procedure TAdatlegyujtes.ForgKorzetSumRogzito;
// =============================================================================

begin
  ReceptorDbase.connected := true;
  if receptortranz.intransaction then ReceptorTranz.commit;
  ReceptorTranz.StartTransaction;

  _korzss := 1;
  while _korzss<=_korzetdarab do
    begin
      _aktkorzetszam := _korzetszam[_korzss];
      _aktcegbetu    := _kftbetusor[_korzss];
      _valss := 1;
      while _valss<=_valutadarab do
        begin
          _aktdnem := _dnem[_valss];
          _vett    := _kvett[_korzss,_valss];
          _eladott := _kEladott[_korzss,_valss];
          _vettft  := _kVettft[_korzss,_valss];
          _eladottft := _keladottft[_korzss,_valss];
          _elszarfolyam := _kelsz[_korzss,_valss];

          _pcs := 'INSERT INTO FORGALOMGYUJTO (VALUTANEM,IRODASZAM,CEGBETU,';
          _pcs := _pcs + 'ERTEKTAR,ELSZAMOLASIARFOLYAM,VETT,VETTERTEK,'+_sorveg;
          _pcs := _pcs + 'ELADOTT,ELADOTTERTEK)' + _sorveg;

          _pcs := _pcs + 'VALUES (' +chr(39) + _aktDnem +chr(39)+',0,';
          _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',';
          _pcs := _pcs + inttostr(_aktKorzetszam)+',';
          _pcs := _pcs + floattostr(_elszarfolyam)+',';
          _pcs := _pcs + inttostr(_vett) + ',';
          _pcs := _pcs + floattostr(_vettft)+',';
          _pcs := _pcs + inttostr(_eladott) + ',';
          _pcs := _pcs + floattoStr(_eladottft)+')';

          with receptorQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Execsql;
            end;
          inc(_valss);
        end;
      inc(_korzss);
    end;
  ReceptorTranz.commit;
  Receptordbase.close;
end;

// =============================================================================
               procedure  TadatLegyujtes.ForgKftSummazas;
// =============================================================================

begin
  Alcimpanel.Caption := 'KFT-ék forgalmi összesitése';
  AlcimPanel.Repaint;

  ForgKorzetSumNullazo;

  ReceptorDbase.Connected := true;
  _pcs := 'SELECT * FROM FORGALOMGYUJTO' + _sorveg;
  _pcs := _pcs + 'WHERE (IRODASZAM=0) AND (ERTEKTAR>0)';

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  Csik.Position := 0;
  Csik.max      := _RecNo;

  _cc := 0;

  // Ha nincs egyetlen adat sem gyüjtve, nincs mit összesiteni !

  if _recno=0 then
    begin
      ReceptorTranz.Commit;
      ReceptorQuery.Close;
      Exit;
    end;


  while not ReceptorQuery.Eof do
    begin
      inc(_cc);
      Csik.Position := _cc;

      with ReceptorQuery do
        begin
          _aktdnem      := FieldByName('VALUTANEM').asString;
          _aktcegbetu   := FieldByName('CEGBETU').asString;
          _elszarfolyam := FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
          _vett      := FieldByName('VETT').asInteger;
          _eladott   := FieldByNAme('ELADOTT').asInteger;
          _vettft    := FieldByName('VETTERTEK').asFloat;
          _eladottft := FieldByNAme('ELADOTTERTEK').asFloat;
        end;

      _valss := dnemscan(_aktdnem);
      _kftss  := CegBetuScan(_aktcegbetu);

      _kvett[_kftss,_valss] := _kvett[_kftss,_valss] + _vett;
      _keladott[_kftss,_valss] := _keladott[_kftss,_valss] + _eladott;
      _kvettft[_kftss,_valss] := _kvettft[_kftss,_valss] + _vettft;
      _keladottft[_kftss,_valss] := _keladottft[_kftss,_valss] + _eladottft;
      _kelsz[_kftss,_valss] := _elszarfolyam;
      ReceptorQuery.next;
    end;
  receptorQuery.close;
  receptordbase.close;
end;


// =============================================================================
               procedure  TadatLegyujtes.ForgKftSumRogzito;
// =============================================================================

begin
  receptorDbase.connected := true;
  if receptortranz.intransaction then receptorTranz.commit;
  ReceptorTranz.StartTransaction;

  _kftss := 1;
  while _kftss<=_kftdarab do
    begin
      _aktcegbetu := _kftBetuk[_kftss];
      _valss := 1;
      while _valss<=_valutadarab do
        begin
          _aktdnem := _dnem[_valss];
          _vett := _kVett[_kftss,_valss];
          _eladott := _keladott[_kftss,_valss];
          _vettft := _kvettft[_kftss,_valss];
          _eladottft := _keladottft[_kftss,_valss];
          _elszarfolyam := _kelsz[_kftss,_valss];

         _pcs := 'INSERT INTO FORGALOMGYUJTO (VALUTANEM,IRODASZAM,CEGBETU,';
         _pcs := _pcs + 'ERTEKTAR,ELSZAMOLASIARFOLYAM,VETT,VETTERTEK,'+_sorveg;
         _pcs := _pcs + 'ELADOTT,ELADOTTERTEK)' + _sorveg;

         _pcs := _pcs + 'VALUES (' +chr(39) + _aktDnem +chr(39)+',0,';
          _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',0,';

          _pcs := _pcs + floattostr(_elszarfolyam)+',';
          _pcs := _pcs + inttostr(_vett) + ',';
          _pcs := _pcs + floattostr(_vettft)+',';
          _pcs := _pcs + inttostr(_eladott) + ',';
          _pcs := _pcs + floattoStr(_eladottft)+')';

          with receptorQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Execsql;
            end;
          inc(_valss);
        end;
      inc(_kftss);
    end;
  ReceptorTranz.commit;
  ReceptorDbase.close;
end;

// =============================================================================
                procedure TadatLegyujtes.ForgCegSummazas;
// =============================================================================

begin
  Alcimpanel.Caption := 'Teljes cég forgalmának összesitése';
  AlcimPanel.repaint;

  ReceptorDbase.Connected := true;

  _pcs := 'SELECT * FROM FORGALOMGYUJTO' + _sorveg;
  _pcs := _pcs + 'WHERE (IRODASZAM=0) AND (ERTEKTAR=0)';

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  // Ha nincs egyetlen adat sem gyüjtve, nincs mit összesiteni !

  if _recno=0 then
    begin
      ReceptorTranz.Commit;
      ReceptorQuery.Close;
      Exit;
    end;

  while not ReceptorQuery.Eof do
    begin
      with ReceptorQuery do
        begin
          _aktdnem      := FieldByName('VALUTANEM').asString;
          _aktcegbetu   := FieldByName('CEGBETU').asString;
          _elszarfolyam := FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
          _vett      := FieldByName('VETT').asInteger;
          _eladott   := FieldByNAme('ELADOTT').asInteger;
          _vettft    := FieldByName('VETTERTEK').asFloat;
          _eladottft := FieldByNAme('ELADOTTERTEK').asFloat;
        end;

      _valss := dnemscan(_aktdnem);
      _kftss  := CegBetuScan(_aktcegbetu);

      if _aktcegbetu<>'Z' then
        begin
          _Sumvett[_valss] := _sumvett[_valss] + _vett;
          _sumeladott[_valss] := _sumeladott[_valss] + _ELADOTT;
          _sumvettFt[_valss] := _sumvettFt[_valss] + _vettft;
          _sumeladottft[_valss] := _sumeladottft[_valss] + _eladottft;
        end;

      _xumvett[_valss] := _xumvett[_valss] + _vett;
      _xumeladott[_valss] := _xumeladott[_valss] + _eladott;
      _xumvettFt[_valss] := _xumvettFt[_valss] + _vettft;
      _xumeladottft[_valss] := _xumeladottft[_valss] + _eladottft;
      _xumelsz[_valss] := _elszarfolyam;
      ReceptorQuery.next;
    end;
  receptorquery.close;
  receptorDbase.close;
end;

// =============================================================================
                procedure TAdatLegyujtes.forgcegsumnullazo;
// =============================================================================

begin
  _valss := 1;
  while _valss<=_valutadarab do
    begin
      _sumvett[_valss] := 0;
      _sumeladott[_valss] := 0;
      _sumvettft[_valss] := 0;
      _sumeladott[_valss] :=0;
      _sumelsz[_valss] := 0;

      _xumvett[_valss] := 0;
      _xumeladott[_valss] := 0;
      _xumvettft[_valss] := 0;
      _xumeladott[_valss] :=0;
      _xumelsz[_valss] := 0;
      inc(_valss);
    end;
end;


// =============================================================================
                procedure TAdatLegyujtes.ForgCegSumRogzito;
// =============================================================================

begin
  receptorDbase.connected := true;
  if receptorTranz.InTransaction then receptorTranz.commit;
  ReceptorTranz.StartTransaction;

  _valss := 1;
  while _valss<=_valutadarab do
    begin
      _aktdnem := _dnem[_valss];
      _vett := _sumvett[_valss];
      _eladott := _sumeladott[_valss];
      _vettft := _sumvettft[_valss];
      _eladottft := _sumeladottft[_valss];
      _elszarfolyam := _sumelsz[_valss];

      _pcs := 'INSERT INTO FORGALOMGYUJTO (VALUTANEM,IRODASZAM,CEGBETU,';
      _pcs := _pcs + 'ERTEKTAR,ELSZAMOLASIARFOLYAM,VETT,VETTERTEK,';
      _pcs := _pcs + 'ELADOTT,ELADOTTERTEK)' + _sorveg;

      _pcs := _pcs + 'VALUES (' + chr(39)+_aktdnem + chr(39) + ',';
      _pcs := _pcs + '0,' + chr(39)+chr(39)+',';
      _pcs := _pcs + '-1,' + floattostr(_elszarfolyam) + ',';
      _pcs := _pcs + inttostr(_vett) + ',';
      _pcs := _pcs + floattostr(_vettft) + ',';
      _pcs := _pcs + inttostr(_eladott) + ',';
      _pcs := _pcs + floattostr(_eladottft) + ')';

      with ReceptorQuery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Execsql;
        end;

     // --------------------------

      _vett := _xumvett[_valss];
      _eladott := _xumeladott[_valss];
      _vettft := _xumvettft[_valss];
      _eladottft := _xumeladottft[_valss];
      _elszarfolyam := _xumelsz[_valss];

      _pcs := 'INSERT INTO FORGALOMGYUJTO (VALUTANEM,IRODASZAM,CEGBETU,';
      _pcs := _pcs + 'ERTEKTAR,ELSZAMOLASIARFOLYAM,VETT,VETTERTEK,';
      _pcs := _pcs + 'ELADOTT,ELADOTTERTEK)' + _sorveg;

      _pcs := _pcs + 'VALUES (' + chr(39)+_aktdnem + chr(39) + ',';
      _pcs := _pcs + '0,' + chr(39)+chr(39)+',';
      _pcs := _pcs + '-2,' + floattostr(_elszarfolyam) + ',';
      _pcs := _pcs + inttostr(_vett) + ',';
      _pcs := _pcs + floattostr(_vettft) + ',';
      _pcs := _pcs + inttostr(_eladott) + ',';
      _pcs := _pcs + floattostr(_eladottft) + ')';

      with ReceptorQuery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Execsql;
        end;
      inc(_valss);
    end;
  ReceptorTranz.commit;
  ReceptorDbase.close;
end;


procedure TadatLegyujtes.MNBArfolyamLetoltes;

var _earf: real;
    _xx : byte;
begin
   _pcs := 'SELECT * FROM ARFOLYAM' + _sorveg;
   _pcs := _pcs + 'WHERE VALUTANEM<>' + chr(39)+'EUA'+chr(39);

   ElszamDbase.connected := true;
   with ElszamQuery do
     begin
       close;
       sql.clear;
       sql.add(_pcs);
       Open;
     end;

   while not ElszamQuery.eof do
     begin
       _aktdnem := ElszamQuery.FieldByName('VALUTANEM').asString;
       _earf := ElszamQuery.FieldByName('ELSZAMOLASIARFOLYAM').asFloat;
       _xx := DnemScan(_aktdnem);
       _mnbArfolyam[_xx] := trunc(_earf);
       elszamQuery.next;
     end;
   Elszamquery.close;
   elszamDbase.close;
end;


end.
