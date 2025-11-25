unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBQuery, IBCustomDataSet, IBTable,
  Buttons, ExtCtrls, ComCtrls, dateUtils, strutils, Printers;

type
  THAVIZARAS = class(TForm)

    DataTabla : TIBTable;
    DataQuery : TIBQuery;
    DataDbase : TIBDatabase;
    DataTranz : TIBTransaction;

    TradeTabla: TIBTable;
    TradeQuery: TIBQuery;
    TradeDbase: TIBDatabase;
    TradeTranz: TIBTransaction;

    ValQuery  : TIBQuery;
    ValDbase  : TIBDatabase;
    ValTranz  : TIBTransaction;

    MenuPanel : TPanel;
    MessPanel : TPanel;
    Takaro    : TPanel;

    EvCombo   : TComboBox;
    HoCombo   : TComboBox;

    Label1    : TLabel;
    Label2    : TLabel;

    HoOkeGomb : TBitBtn;
    MegsemGomb: TBitBtn;

    NoPrintBox: TCheckBox;

    Shape1    : TShape;

    FastCsik  : TProgressBar;
    SlowCsik  : TProgressBar;
    HRKQUERY: TIBQuery;
    HRKDBASE: TIBDatabase;
    HRKTRANZ: TIBTransaction;

    procedure Afairas;
    procedure AlapadatBeolvasas;
    procedure DataParancs(_ukaz: string);

    procedure EtarHaviTradeTablo;
    procedure EvComboChange(Sender: TObject);
    procedure FejlecIras;
    procedure Forgalomiras;
    procedure ForgalomOsszesitesIras;
    procedure FormActivate(Sender: TObject);
    procedure GetElszamarfolyamok;
    procedure HRKLista;
    procedure HaviforgalomGyujtes;
    procedure HaviKezdijRegeneralo;
    procedure HaviNyitoAdatFeliras;
    procedure HavizarasNyomtatas;
    procedure HoOkeGombClick(Sender: TObject);
    procedure HaviTrade;
    procedure HzMake;
    procedure KezkoltsegIras;
    procedure Kozepreir(_s: string);
    procedure MegsemGombClick(Sender: TObject);
    procedure WesternIras;

    procedure UgyfelforgalomIras;
    procedure Valparancs(_ukaz: string);
    procedure VonalHuzo;
    procedure WuAfaforgalom;
    procedure WuDataClear;
    procedure ZarokeszletIras;

    function ArfForm(_ft: integer): string;
    function Elokieg(_s: string; _h: byte): string;
    function Ftform(_ft: integer): string;
    function Getutkezdijss: integer;
    function Int3Str(_ft: integer):string;
    function Kieg(_s: string; _h: byte): string;
    function Nulele(_b: byte): string;
    function Scandnem(_dn: string): byte;
    function sform(_n,_h: integer): string;
    function S9(_n: integer): string;
    function F6(_n: integer): string;
    function F9(_n: integer): string;
    function wout(_s: string):string;
 
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  HAVIZARAS: THAVIZARAS;

  _pcs   : string;
  _sorveg: string = chr(13)+chr(10);

  _LFile,_nyomtat,_olvas: Textfile;

// ----------- ARRAYS OF STRING ------------------------------------------

  _honapnev: array[1..12] of string = (
             'JANUÁR',
             'FEBRUÁR',
             'MÁRCIUS',
             'ÁPRILIS',
             'MÁJUS',
             'JUNIUS',
             'JULIUS',
             'AUGUSZTUS',
             'SZEPTEMBER',
             'OKTÓBER',
             'NOVEMBER',
             'DECEMBER');

  _dnem : array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                'CZK','DKK','EUR','GBP','HRK','HUF','ILS','JPY','MXN','NOK',
                'NZD','PLN','RON','RSD','RUB','SEK','THB','TRY','UAH','USD');

  _dnev : array[1..27] of string = ('Ausztrál dollár','Bosnyák Márka','Bolgár leva',
           'Brazil real','Kanadai dollár','Svájci frank','Kinai jüan','Cseh korona',
           'Dán korona','Euró','Angol font','Horvát kuna','Magyar forint',
           'Izraeli shakel','Japán jen','Mexikói peso','Norvég korona',
           'Újzélandi dollár','Lengyel zloty','Román lei','Szerb dinár',
           'Orosz rubel','Svéd korona','Thai baht','Török lira','Ukrán hrivnya',
           'Amerikai dollár');

  _ematTxt: array[1..30] of string;

  _elszam,     // elszámoló árfolyamok
  _havinyito,  // havi nyitó készletek
  _havizaro,   // havi záró készletek
  _hZaro,      // havi zárókészlet az utolsó címletezésnél
  _sAtad,      // társpénztárnak átadott összeg
  _sAtvesz,    // társpénztártól átvett összeg
  _sElad,      // havi eladott bankjegy (Ft-nál a bevétel)
  _sHiany,     // havi hiány (csökkenti a készletet)
  _sKonvM,     // kiadott bankjegy konverziónál
  _sKonvP,     // átvett bankjegy konverziónál
  _sTobblet,   // havi többlet (növeli a készletet)
  _sVet: array[1..27] of integer;  // havi vettbankjegy (bankkartyas is Ft-nál kiadás)

  _fizetoeszkoz, // 1= készpénz, 2= bankkártya
  _ftindex,      // a forint indexe a DNEM tömbben

  _kellMetroafa, // 1 = kell metro AFA
  _kellMatrica,  // 1 = van elektromos kereskedés
  _kellTescoAfa, // 1 = van Tesco AFA
  _kellWestern,  // 1 = van Western Union szolgáltatás

  _kellmoneygram,
  _printer,      // 1 = USB printer
  _sortextDarab,
  _xx: byte;     // DNEM-tömb indexe

  _eUgyfel,        // ügyfelek eladásnál
  _height,        // képernyõ magassága
  _havinapok,
  _hokezdokdijss,  // a havi elso kezdij sorszáma
  _kertev,         // a zárandó év
  _kertho,         // a zárandó hónap
  _left,           // a program bal margója
  _maiho,          // az aktuális hónap
  _maiev,          // az aktuális év
  _top,            // program felsõ margója
  _vUgyfel,        // ügyfelek vásárlásnál
  _width: word;    // képernyõ szélessége

  _aktAtad,
  _aktAtvesz,
  _aktBankjegy,
  _aktEladas,
  _aktElszamArf,
  _aktElszarf,
  _aktErtek,
  _aktHiany,
  _aktKezdij,
  _aktKonvM,
  _aktKonvP,
  _aktNyito,
  _aktTobblet,
  _aktVetel,
  _aktZaro,
  _atadas,
  _atvetel,
  _be,
  _bOsszeg,
  _cc,
  _code,
  _eusAfavissza,
  _ftbe,
  _ftErtek,
  _ftki,
  _haviKezdij,          // a beszedett havi kezelesi dij
  _haviKezdijAtadas,
  _haviKezdijAtvet,
  _haviKezdijBk,
  _haviKezdijNyito,
  _haviKezdijzaro,
  _hufBe,
  _hufKi,
  _hufNyito,
  _hufZaro,
  _kerekites,
  _ki,
  _ktm,
  _ktp,
  _lastKezdijSorszam,
  _matAtveszFt,
  _matfeladFt,
  _matForint,
  _matNyito,
  _matZaro,
  _metroBe,
  _metroKi,
  _metroNyito,
  _metroVissza,
  _metroZaro,
  _osszErtek,
  _paySafeFt,
  _penztarszam,
  _qq,
  _recno,
  _sumErtek,
  _sFtbk,
  _sKezdij,
  _sKezdijbk,
  _telenorForint,
  _telForint,
  _tescoBe,
  _tescoKi,
  _tescoNyito,
  _tescoVissza,
  _tescoZaro,
  _ugyKezdij,
  _usdBe,
  _usdKi,
  _usdNyito,
  _usdZaro,
  _vodaForint,
  _xCsAtadas,
  _xCsAtvetel,
  _xCsErtekesites,
  _xCsNyito,
  _xCsVissza,
  _xCsZaro,
  _xFtAtadas,
  _xFtAtvetel,
  _xFtErtekesites,
  _xFtNyito,
  _xFtVissza,
  _xFtZaro: integer;

  _aktDnem,
  _aktevhonap,
  _bizonylat,
  _bizonylatszam,
  _bfTablaNev,
  _bosss,
  _btTablaNev,
  _bTipus,
  _cegnev,
  _cimtarTablaNev,
  _datum,
  _eFarok,
  _eHzaroTablanev,
  _elojel,
  _elseje,
  _evHonaps,
  _farok,
  _hovege,
  _kezdTablanev,
  _kezdodatum,
  _kftNev,
  _lastDay,
  _mondat,
  _narfTablanev,
  _penztarCim,
  _penztarkod,
  _penztarnev,
  _ptTelefon,
  _sorText,
  _tarsPtar,
  _tipus,
  _tPtar,
  _ujHzTablanev,
  _utBizonylat,
  _utDatum,
  _vegsodatum,
  _wzaroTablanev: string;

  _ujbiz: boolean;

  
  _aktid,_tranzid,_price,_amount,_feltoltes,_cardbe,_cardki: integer;
  _cashbe,_cashki,_ertekesites,_eladas,_nyito,_bevet,_kiad,_hrkzaro: integer;
  _cardnyito,_cardzaro,_cashnyito,_cashzaro,_zaro,_sumbe,_sumki: integer;
  _datumido,_product,_datumelo: string;

function havizarorutin: integer; stdcall;

implementation


{$R *.dfm}

function havizarorutin: integer; stdcall;

begin
  Havizaras := THavizaras.Create(Nil);
  result := Havizaras.showmodal;
  Havizaras.free;
end;

// =============================================================================
               procedure THAVIZARAS.FormActivate(Sender: TObject);
// =============================================================================

var i: byte;

begin
  Takaro.Visible := false;
  NoPrintBox.Checked := False;

  _width := Screen.Monitors[0].Width;
  _height:= screen.Monitors[0].Height;

  _top   := trunc((_height-768)/2);
  _left  := trunc((_width-1024)/2);

  top    := _top + 150;
  left   := _left +250;

  Alapadatbeolvasas;

  _maiev := yearof(Date);
  _maiho := monthof(date);

  evcombo.items.clear;
  hocombo.items.clear;

  evcombo.items.add(inttostr(_maiev-1));
  evcombo.items.add(inttostr(_maiev));

  for i := 1 to 12 do hocombo.items.add(_honapnev[i]);

  evcombo.itemindex := 1;
  hocombo.itemindex := (_maiho-1);

  Activecontrol := Hookegomb;

end;


// =============================================================================
                procedure THAVIZARAS.HOOKEGOMBClick(Sender: TObject);
// =============================================================================

var _evindex,_hoindex: integer;
    _eev,_eho,_waf: word;

begin

  _hoindex := hocombo.itemindex;
  _evindex := evcombo.itemindex;

  _kertev  := _maiev;
  if _evindex=0 then dec(_kertev);
  _kertho  := 1 + _hoindex;

  _farok := inttostr(_kertev-2000)+nulele(_kertho);

  _bfTablaNev   := 'BF' + _farok;
  _btTablanev   := 'BT' + _farok;
  _kezdTablaNev := 'KEZD' + _farok;

  _eev := _kertev;
  _eho := _kertho-1;

  if _eho<1 then
    begin
      _eho := 12;
      dec(_eev);
    end;

  _eFarok := inttostr(_eev-2000)+nulele(_eho);
  _eHzaroTablaNev := 'HZ' + _eFarok;

  Slowcsik.Max := 9;
  Fastcsik.Max := 1;

  FastCsik.Position := 0;
  SlowCsik.Position := 0;
  MessPanel.Caption := '';
  MessPanel.Repaint;

  _havinapok := DaysInaMonth(_kertev,_kertho);
  _elseje := inttostr(_kertev)+'.'+nulele(_kertho)+'.01';
  _hovege := leftstr(_elseje,8)+nulele(_havinapok);
  _aktevhonap := inttostr(_kertev)+nulele(_kertho);

  with Takaro do
    begin
      top     := 104;
      Left    := 8;
      Visible := True;
      repaint;
    end;

  _ktm := 0;
  _ktp := 0;
    
  SlowCsik.Position := 1;
  HaviForgalomGyujtes;


  SlowCsik.Position := 2;
  HaviKezdijRegeneralo;


  SlowCsik.Position := 3;
  GetElszamArfolyamok;

  _waf := _kellwestern+_kellmetroafa+_kelltescoafa;
  if _waf>0 then
    begin
      SlowCsik.Position := 4;
      WuaFaForgalom;
    end;

  SlowCsik.Position := 7;
  HaviNyitoAdatFeliras;

  SlowCsik.Position := 8;
  HaviZarasNyomtatas;

  SlowCsik.Position := 9;
  Sleep(2500);

  Modalresult := 1;
end;

// =============================================================================
                    procedure THAVIZARAS.HaviForgalomGyujtes;
// =============================================================================

var i,_max: byte;

begin
  MessPanel.Caption := 'Havi forgalom gyüjtése';
  MessPanel.Repaint;

  _ftIndex := ScanDnem('HUF');

  // ---------------------------------------------------------------------------
  // Nullazas:

  for i := 1 to 27 do
    begin
      _haviNyito[i] := 0;   // Valuták havi nyitókészlete
      _haviZaro[i]  := 0;   // Valuták havi zárókészlete
      _svet[i]      := 0;   // Ennyi valutát vett a hónapban
      _selad[i]     := 0;   // Ennyi valutát adott el a hónapban
      _sKonvP[i]    := 0;   // Ennyi konverziós plusz bankjegy volt
      _sKonvM[i]    := 0;   // Ennyi konverzios minusz volt
      _sAtad[i]     := 0;   // Ennyi valuta lett atadva
      _sAtvesz[i]   := 0;   // Ennyi valutat vatt at a hónapban
      _sTobblet[i]  := 0;   // Ennyi többlet volt a hónapban
      _sHiany[i]    := 0;   // Ennyi hiány volt a hónapban
    end;

  _sKezdij          := 0;   //
  _sFtbk            := 0;
  _skezdijbk        := 0;

  _vUgyfel          := 0;
  _eUgyfel          := 0;

  FastCsik.Position := 1;

  // --------------------------------------------------------------------------
  // Havi nyitó készletek beolbasasa:

  MessPanel.Caption := 'Nyitó készletek beolvasása';
  MessPanel.Repaint;

  _pcs := 'SELECT * FROM ' + _eHzaroTablanev;
  DataDbase.Connected := true;

  with DataQuery do
    begin
      Close;
      Sql.clear;
      sql.add(_pcs);
      Open;
      First;
      _haviKezdijNyito   := FieldByName('KEZDIJZARO').asInteger;
      _lastKezdijSorszam := FieldByNAme('UTKEZDIJSORSZAM').asInteger;
    end;

  while not DataQuery.eof do
    begin
      with DataQuery do
        begin
          _aktDnem := FieldByName('VALUTANEM').asString;
          _aktZaro := FieldByName('ZARO').asInteger;
        end;

      _xx := ScanDnem(_aktDnem);
      _HaviNyito[_xx] := _aktZaro;

      DataQuery.next;
    end;

  DataQuery.close;
  DataDbase.close;

  FastCsik.Position := 2;

  // ---------------------------------------------------------------------------

  MessPanel.Caption := 'A havi forgalom gyüjtése';
  MessPanel.Repaint;

  DataDbase.Connected := true;
  _pcs := 'SELECT * FROM ' + _bfTablaNev + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';
  with DataQuery do
    begin
      Close;
      Sql.clear;
      sql.add(_pcs);
      Open;
      last;
      _recno := Recno;
      _vegsoDatum := FieldByName('DATUM').asString;
      First;
      _kezdoDatum := FieldByName('DATUM').asString;
      Close;
    end;

  _pcs := 'SELECT FEJ.*,TET.*' + _sorveg;
  _pcs := _pcs + 'FROM '+ _bfTablaNev+' FEJ JOIN ' + _btTablaNev+' TET' + _sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM' + _sorveg;
  _pcs := _pcs + 'WHERE (FEJ.STORNO=1)';

  with DataQuery do
    begin
      Close;
      Sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _max := 5+_recno;

  FastCsik.Max := _max;

  _cc := 2;
  _utBizonylat := 'XXXXXXX';

  while not DataQuery.eof do
    begin
      inc(_cc);
      FastCsik.Position := _cc;

      with DataQuery do
        begin
          _tipus         := FieldByName('TIPUS').asString;
          _aktKezdij     := FieldByName('KEZELESIDIJ').asInteger;
          _fizetoEszkoz  := FieldByName('FIZETOESZKOZ').asInteger;
          _tarsPtar      := trim(FieldByName('TARSPENZTARKOD').asstring);
          _aktDnem       := FieldByName('VALUTANEM').asstring;
          _aktBankjegy   := FieldByNAme('BANKJEGY').asInteger;
          _ftertek       := FieldByName('FORINTERTEK').asInteger;
          _elojel        := FieldByName('ELOJEL').asstring;
          _bizonylatSzam := FieldByName('BIZONYLATSZAM').asString;
          _kerekites     := FieldByNAme('KEREKITES').asInteger;
        end;

      _ujbiz := False;
      IF _utBizonylat<>_bizonylatszam then _ujbiz := True;

      IF _ujbiz then
        begin
          if _tipus='V' then inc(_vUgyfel);
          if _tipus='E' then inc(_eUgyfel);

          _sKezdij := _sKezdij + abs(_aktKezdij);
          if _fizetoEszkoz=2 then _sKezdijBk := _sKezdijBk + abs(_aktKezdij);
        end;

      _xx := ScanDnem(_aktDnem);

      if _tipus='V' then
        begin
          _sVet[_xx] := _sVet[_xx] + _aktBankjegy;
          _sElad[_ftIndex] := _sElad[_ftIndex] + _ftErtek;
          if _ujbiz then _selad[_ftIndex] := _sElad[_ftIndex] + _kerekites;
        end;

      if _tipus='E' then
        begin
          _sElad[_xx] := _sElad[_xx] + _aktBankjegy;
          _sVet[_ftIndex] := _sVet[_ftindex] + _ftErtek;

          IF _ujbiz then  _sVet[_ftIndex] := _sVet[_ftIndex] + _kerekites;

          if _fizetoEszkoz=2 then
            begin
              _sFtBk := _sFtbk + _ftErtek;
              IF _ujbiz then _sFtBk := _sFtBk + _kerekites;
            end;
        end;

      if ((_tipus='F') OR (_tipus='U')) AND ((_tarsPtar='TH') OR (_tarsPtar='1')) then
        begin
          if _elojel='+' then _sTobblet[_xx] := _sTobblet[_xx] + _aktBankjegy
          else _sHiany[_xx] := _sHiany[_xx] + _aktBankjegy;
        end;

      if _tipus='F' then _sAtad[_xx]   := _sAtad[_xx] + _aktBankjegy;
      if _tipus='U' then _sAtvesz[_xx] := _sAtvesz[_xx] + _aktBankjegy;

      _utBizonylat := _bizonylatszam;

      DataQuery.next;
    end;

  DataQuery.close;
  DataDbase.close;

  _sVet[_ftIndex] := _sVet[_ftindex] - _sFtBk;

  _qq := 1;
  while _qq<=27 do
    begin
      _aktDnem    := _dNem[_qq];
      _aktNyito   := _haviNyito[_qq];
      _aktVetel   := _sVet[_qq];
      _aktEladas  := _sElad[_qq];

      _aktKonvP   := _sKonvP[_qq];
      _aktKonvM   := _sKonvM[_qq];

      _aktAtad    := _sAtad[_qq];
      _aktAtvesz  := _sAtvesz[_qq];
      _aktTobblet := _sTobblet[_qq];
      _aktHiany   := _sHiany[_qq];

      _aktZaro    := _aktNyito+_aktVetel-_aktEladas+_aktAtvesz-_aktAtad;
      _aktZaro    := _aktZaro+_aktKonvp-_aktKonvM;

      _haviZaro[_qq] := _aktZaro;
      inc(_qq);
    end;

  FastCsik.Position := _max;
  Sleep(150);
end;

// =============================================================================
                  procedure THAVIZARAS.HaviKezdijRegeneralo;
// =============================================================================

begin
  MessPanel.Caption := 'Havi kezdij regenerálás';
  MessPanel.Repaint;

  FastCsik.Max := 5;
  FastCsik.Position := 1;

  _haviKezdij       := 0;
  _haviKezdijAtadas := 0;
  _haviKezdijAtvet  := 0;

// =================== KERESÉS A BFyymm GYÜTÖADATBÁZISBAN ======================

  DataDbase.Connected := true;

  _pcs := 'SELECT * FROM '+ _bfTablanev + _sorveg;
  _pcs := _pcs + 'WHERE (STORNO=1) AND ((TIPUS='+chr(39)+'V'+chr(39)+')';
  _pcs := _pcs + ' OR (TIPUS='+chr(39)+'E'+CHR(39)+'))';

  with DataQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  while not DataQuery.eof do
    begin
      _aktKezdij := DataQuery.FieldByName('KEZELESIDIJ').asInteger;
      _fizetoEszkoz :=  DataQuery.FieldByName('FIZETOESZKOZ').asInteger;

      if _fizetoEszkoz=1 then _haviKezdij := _haviKezdij + abs(_aktKezdij)
      else _haviKezdijBk := _HaviKezdijBk + abs(_aktKezdij);

      DataQuery.next;
    end;

  DataQuery.close;

  // ------------------ KERESÉS A KEZDYYMM ADATBÁZISBAN ------------------------

  FastCsik.Position := 2;

  _pcs := 'SELECT * FROM '+ _kezdTablaNev + _sorveg;
  _pcs := _pcs + 'WHERE (STORNO=1) AND (MOZGAS>1)';

  with DataQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  while not DataQuery.eof do
    begin
      _aktKezdij := DataQuery.FieldByName('KEZELESIDIJ').asInteger;
      _elojel    := DataQuery.FieldByName('ELOJEL').asString;

      if _elojel='+' then _haviKezdijAtvet := _haviKezdijAtvet + _aktKezdij
      else _haviKezdijAtadas := _haviKezdijAtadas + _aktKezdij;

      DataQuery.next;
    end;

  DataQuery.close;
  DataDbase.close;

  FastCsik.Position := 3;

  _haviKezdijZaro:= _haviKezdijNyito+_haviKezdij+_haviKezdijAtvet-_haviKezdijAtadas;

  _pcs := 'DELETE FROM HAVIKEZELESIDIJ' + _sorveg;
  _pcs := _pcs + 'WHERE HONAP=' + inttostr(_kertho);

  ValParancs(_pcs);

  _pcs := 'INSERT INTO HAVIKEZELESIDIJ (HONAP,NYITO,KEZELESIDIJ,KEZELESIDIJATVETEL,';
  _pcs := _pcs + 'KEZELESIDIJATADAS,ZARO)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + inttostr(_kertHo) + ',';
  _pcs := _pcs + inttostr(_haviKezdijNyito) + ',';
  _pcs := _pcs + inttostr(_haviKezdij) + ',';
  _pcs := _pcs + inttostr(_haviKezdijAtvet) + ',';
  _pcs := _pcs + inttostr(_haviKezdijAtadas) + ',';
  _pcs := _pcs + inttostr(_haviKezdijZaro) + ')';
  ValParancs(_pcs);

  FastCsik.Position := 5;
  sleep(1500);
end;


// =============================================================================
                procedure THAVIZARAS.ValParancs(_ukaz: string);
// =============================================================================

begin
  ValDbase.Connected := true;
  if ValTranz.InTransaction then ValTranz.Commit;
  ValTranz.StartTransaction;
  with ValQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  ValTranz.Commit;
  ValDbase.close;
end;


// =============================================================================
                procedure THAVIZARAS.DataParancs(_ukaz: string);
// =============================================================================

begin
  DataDbase.Connected := True;
  if DataTranz.InTransaction then DataTranz.Commit;
  DataTranz.StartTransaction;
  with DataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  DataTranz.Commit;
  DataDbase.close;
end;

// =============================================================================
                 function THAVIZARAS.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
           procedure THAVIZARAS.MegsemGombClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 2;
end;

// =============================================================================
           procedure THAVIZARAS.EvComboChange(Sender: TObject);
// =============================================================================

begin
  ActiveControl := HookeGomb;
end;

// =============================================================================
              function THAVIZARAS.ScanDnem(_dn: string): byte;
// =============================================================================

var _z: byte;

begin
  _z := 1;
  while _z<=27 do
    begin
      if _dnem[_z]=_dn then
        begin
          result := _z;
          exit;
        end;
      inc(_z);
    end;
  result := 0;
end;

// =============================================================================
                  procedure THAVIZARAS.GetElszamArfolyamok;
// =============================================================================

begin
  MessPanel.Caption := 'Elszám árfolyamok betöltése';
  MessPanel.Repaint;
  
  FastCsik.Max := 2;
  FastCsik.Position := 1;

  _narfTablaNev := 'NARF' + _farok;

  _pcs := 'SELECT * FROM ' + _narfTablaNev + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  DataDbase.Connected := True;
  with DataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _lastDay := trim(FieldByName('DATUM').asString);
      Close;
    end;

  _pcs := 'SELECT * FROM ' + _narfTablaNev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _lastDay + chr(39);

  with DataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not DataQuery.eof do
    begin
      _aktDnem      := DataQuery.FieldByName('VALUTANEM').asString;
      _aktElszamArf := DataQuery.FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
      if _aktdnem='JPY' then _aktelszamArf := round(_aktelszamarf/10);
      _xx := ScanDnem(_aktDnem);
      if _xx>0 then _elszam[_xx] := _aktelszamArf;

      DataQuery.next;
    end;


  DataQuery.Close;
  DataDbase.Close;

  FastCsik.Position := 2;
  sleep(1500);
end;

// =============================================================================
                 procedure THAVIZARAS.WuAfaForgalom;
// =============================================================================

var
    _ube,_uki,_hbe,_hki,_abe,_aki,_avi,_evi,_udi: integer;
    _ibe,_iki,_ivi: integer;

begin

  Messpanel.Caption := 'A WU. és AFA adatok beolvasása';
  MessPanel.Repaint;
  
  FastCsik.Max := 3;
  FastCsik.Position := 1;

  WuDataClear;

  _wzaroTablaNev := 'WZAR' + _farok;
  DataDbase.Connected := True;
  DataTabla.Close;

  DataTabla.TableName := _wzaroTablaNev;

  if not DataTabla.exists then
    begin
      DataDbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+_wzaroTablaNev+_sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with DataQuery do
    begin
      close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  with DataQuery do
    begin
      _usdNyito   := FieldByName('USDNYITO').asInteger;
      _hufNyito   := FieldByName('HUFNYITO').asInteger;
      _MetroNyito := FieldByName('METRONYITO').asInteger;
      _TescoNyito := FieldByName('TESCONYITO').asInteger;
    end;

  Fastcsik.Position := 2;

  while not DataQuery.eof do
    begin
      with DataQuery do
        begin
          _uBe := FieldByName('USDBEVETEL').asInteger;
          _uKi := FieldByName('USDKIADAS').asInteger;
          _hBe := FieldByName('HUFBEVETEL').asInteger;
          _hKi := FieldByName('HUFKIADAS').asInteger;
          _aBe := FieldByName('METROBEVETEL').asInteger;
          _aKi := FieldByName('METROKIADAS').asInteger;
          _iBe := FieldByName('TESCOBEVETEL').asInteger;
          _iKi := FieldByName('TESCOKIADAS').asInteger;
          _udi := FieldByName('UGYKEZELESIDIJ').asInteger;
          _avi := FieldByName('METROVISSZA').asInteger;
          _evi := FieldByName('EUSAFAVISSZA').asInteger;
          _ivi := FieldByName('TESCOVISSZA').asInteger;
        end;

      _usdBe        := _usdBe + _ube;
      _usdKi        := _usdKi + _uki;
      _hufBe        := _hufBe + _hbe;
      _hufKi        := _hufKi + _hki;
      _metroBe      := _metroBe + _abe;
      _metroKi      := _metroKi + _aki;
      _tescoBe      := _tescoBe + _ibe;
      _tescoKi      := _tescoKi + _iki;
      _ugyKezdij    := _ugyKezdij + _udi;
      _metroVissza  := _metroVissza + _avi;
      _eusAfaVissza := _eusafaVissza + _evi;
      _tescoVissza  := _tescoVissza + _ivi;

      DataQuery.Next;
    end;

  with DataQuery do
    begin
      Last;
      _usdZaro   := FieldByName('USDZARO').asInteger;
      _hufZaro   := FieldByName('HUFZARO').asInteger;
      _metroZaro := FieldByName('METROZARO').asInteger;
      _tescoZaro := FieldByName('TESCOZARO').asInteger;
      close;
    end;
  Datadbase.Close;

  FastCsik.Position :=3;
  sleep(1500);
end;

// =============================================================================
                procedure THAVIZARAS.WuDataClear;
// =============================================================================

begin
  _usdNyito  := 0;
  _hufNyito  := 0;
  _MetroNyito:= 0;
  _TescoNyito:= 0;

  _usdBe     := 0;
  _hufBe     := 0;
  _metroBe   := 0;
  _tescoBe   := 0;

  _usdKi     := 0;
  _hufKi     := 0;
  _metroKi   := 0;
  _tescoKi   := 0;

  _usdZaro   := 0;
  _hufZaro   := 0;
  _metroZaro := 0;
  _tescoZaro := 0;

  _metroVissza  := 0;
  _eusAfaVissza := 0;
  _tescoVissza  := 0;
  _ugyKezdij    := 0;
end;

// =============================================================================
                  procedure THAVIZARAS.AlapadatBeolvasas;
// =============================================================================

begin
  MessPanel.Caption := 'Az alapadok beolvasása';
  MessPanel.Repaint;
  
  ValDbase.Connected := True;
  with ValQuery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM HARDWARE');
      Open;

      _kellWestern := FieldByName('KELLWESTERN').asInteger;
      _kellTescoAfa:= FieldbyNAme('KELLTESCOAFA').asInteger;
      _kellMetroAfa:= FieldByName('KELLMETROAFA').asInteger;
      _kellMatrica := FieldByNAme('KELLMATRICA').asInteger;
      _printer     := FieldbyName('PRINTER').asInteger;
      _kftNev      := trim(FieldByName('KFTNEV').AsString);

      Close;
      Sql.Clear;
      Sql.Add('SELECT * FROM PENZTAR');
      Open;
      _penztarkod := trim(FieldByNAme('PENZTARKOD').AsString);
      _penztarNev := trim(FieldByName('PENZTARNEV').asString);
      _penztarCim := trim(FieldByName('PENZTARCIM').AsString);
      _ptTelefon  := trim(FieldByName('TELEFONSZAM').AsString);
      Close;
    end;
  ValDbase.close;

  val(_penztarkod,_penztarszam,_code);
  if _penztarszam<151 then
    begin
      _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';
    end else
    begin
      _cegnev := 'EXPRESSZ ÉKSZERHÁZ ÉS MINIBANK KFT';
    end;

  Sleep(1500);
end;

// =============================================================================
           function THaviZaras.Kieg(_s: string; _h: byte): string;
// =============================================================================

begin
  result := _s;
  while length(result)<_h do result := result + chr(32);
end;

// =============================================================================
            function THAVIZARAS.Elokieg(_s: string; _h: byte): string;
// =============================================================================

begin
  result := _s;
  while length(result)<_h do result := ' ' + result;
end;

// =============================================================================
                function THAVIZARAS.GetUtKezdijSs: integer;
// =============================================================================


var _kezdTablaNev: string;

begin
  _kezdTablaNev := 'KEZD' + _farok;

  DataDbase.Connected := True;

  _pcs := 'SELECT * FROM ' + _kezdTablaNev;
  with DataQuery do
    begin
      Close;
      Sql.Clear;
      Sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
      close;
    end;

  result := _lastkezdijsorszam + _recno;
  DataDbase.close;
end;

// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//
//                    HAVI ZÁRÁS KINYOMTATÁSA
// =============================================================================


// =============================================================================
                    procedure THAVIZARAS.HaviZarasNyomtatas;
// =============================================================================

begin
  MessPanel.Caption := 'Aktlst.txt összeállítása';
  MessPanel.Repaint;
  
  FastCsik.Max      := 12;
  FastCsik.Position := 1;

  AssignFile(_LFile,'c:\valuta\aktlst.txt');
  Rewrite(_LFile);

  FejlecIras;
  FastCsik.Position := 2;

  ForgalomIras;
  FastCsik.Position := 3;

  ForgalomOsszesitesIras;
  FastCsik.Position := 4;

  KezkoltsegIras;
  FastCsik.Position := 5;

  HrkLista;

  ZaroKeszletIras;
  FastCsik.Position := 6;

  if _kellWestern=1 then
    begin
      WesternIras;
      FastCsik.Position := 7;
    end;

  if (_kellTescoAfa=1) or (_kellMetroAfa=1) then
    begin
      AfaIras;
      FastCsik.Position := 8;
    end;

  if (_kellMatrica=1) then hAVItRADE; // PtarEkerIras;
  FastCsik.Position := 9;

  FastCsik.Position := 10;

  UgyfelForgalomIras;
  FastCsik.Position := 11;

  CloseFile(_LFile);

  if NoPrintBox.Checked then
    begin
      FastCsik.Position := 12;
      Sleep(1500);
      Exit;
    end;

  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------

  if _printer<>1 then AssignFile(_nyomtat,'LPT1')
  else AssignPrn(_nyomtat);
  ReWrite(_nyomtat);

  AssignFile(_olvas,'c:\valuta\aktlst.txt');
  Reset(_olvas);

  while not eof(_olvas) do
    begin
      readln(_olvas,_mondat);
      writeln(_nyomtat,_mondat);
    end;
  System.closeFile(_nyomtat);
  System.CloseFile(_olvas);

  FastCsik.Position := 12;
  sleep(1500);
end;

// =============================================================================
                         procedure THAVIZARAS.Fejleciras;
// =============================================================================

begin
  Kozepreir(_cegnev);
  Kozepreir(_penztarnev);
  Kozepreir(_penztarcim);

  if _ptTelefon<>'' then Kozepreir('Tel: '+_ptTelefon);

  VonalHuzo;
  Kozepreir(inttostr(_kertev)+' '+_honapnev[_kertho]+' havi penztarzaras');
  VonalHuzo;
end;

// =============================================================================
                      procedure THAVIZARAS.Forgalomiras;
// =============================================================================


begin
  writeLn(_LFile,'        Kezdo datum: ' + _kezdoDatum);
  writeLn(_LFile,'         Zaro datum: ' + _vegsodatum);
  VonalHuzo;

  WriteLn(_LFile,'Valuta         Novekedes     Csokkenes');
  VonalHuzo;

  _xx := 1;
  while _xx<=27 do
    begin
      _aktdnem := _dNem[_xx];
      _sorText := _aktdNem + '        Nyito: ' + ftForm(_haviNyito[_xx]);
      WriteLn(_LFile,_sorText);

      _be := _sVet[_xx] + _sKonvP[_xx];
      _ki := _sElad[_xx] + _sKonvM[_xx];

      if _aktdnem='HUF' then
        begin
          _be := _be - _ktm;
          _ki := _ki - _ktm;
           _ftbe := _be;
          _ftki := _ki;

        end;

      _aktTobblet:= _sTobblet[_xx];
      _aktHiany  := _sHiany[_xx];

      _aktAtvesz := _sAtvesz[_xx]-_aktTobblet;
      _aktAtad   := _sAtad[_xx]-_akthiany;
      _aktZaro   := _havizaro[_xx];

      writeLn(_LFile,' Vetel-Elad: ' + ftForm(_be)+'   '+ftform(_ki));
      if _dnem[_xx]='HUF' then
          writeLn(_LFile,' Bankkartya: ' + ftform(_sFtBk));
      writeLn(_LFile,' Atvet-Atad: ' + ftform(_aktAtvesz)+'   '+ftform(_aktAtad));
      writeLn(_LFile,'Tobbl-Hiany: ' + ftform(_aktTobblet)+'   '+ftform(_aktHiany));
      writeLn(_LFile,'            Zaro: '+ftform(_aktZaro));
      VonalHuzo;
      inc(_xx);
    end;
end;

// =============================================================================
                   procedure THAVIZARAS.ForgalomOsszesitesIras;
// =============================================================================


begin
  KozepreIr('HAVI FORGALOM OSSZESITES');
  VonalHuzo;
  WriteLN(_LFile,'Havi vetelnel kiadas....: ' + ftform(_ftki)+' Ft');
  WriteLn(_LFile,'Havi eladasnal bevetel..: ' + ftForm(_ftbe)+' Ft');
  WriteLn(_LFile,'Havi eladas b.kartyaval.: ' + ftForm(_sFtBk)+' Ft');
  VonalHuzo;
end;

// =============================================================================
                      procedure THAVIZARAS.KezkoltsegIras;
// =============================================================================

begin
  KozepreIr('KEZELESI KOLTSEGEK');
  VonalHuzo;
  WriteLN(_LFile,'Havi nyito osszeg ......:' + ftform(_haviKezdijNyito));
  WriteLN(_LFile,'Kezelesi koltseg .......:' + ftform(_haviKezdij));
  WriteLN(_LFile,'Atvett osszeg ..........:' + ftform(_haviKezdijAtvet));
  writeLn(_LFile,'Bankkartyas koltseg ....:' + ftform(_sKezdijBk));
  WriteLN(_LFile,'Atadott osszeg .........:' + ftform(_haviKezdijAtadas));
  WriteLN(_LFile,'Havi zaro osszeg .......:' + ftform(_haviKezdijZaro));
  VonalHuzo;
end;

// =============================================================================
                    procedure THAVIZARAS.ZaroKeszletIras;
// =============================================================================

begin
  KozepreIr('HAVI ZAROKESZLET');
  VonalHuzo;
  Writeln(_LFile,'Dnem   Keszlet     Arfolyam       Ertek');
  VonalHuzo;

  _xx := 1;
  _sumertek := 0;

  while _xx<=27 do
    begin
      _aktElszarf := _elszam[_xx];
      _aktZaro    := _haviZaro[_xx];
      _aktDnem    := _dNem[_xx];
      _aktErtek   := trunc(_aktElszarf/100*_aktZaro);

      if _aktDnem='HUF' then _ftErtek := _aktErtek
      else _sumErtek := _sumErtek + _aktErtek;

      _sorText := _aktDnem + ' '+ftform(_aktZaro)+'  '+arfform(_aktElszarf);
      _sorText := _sorText + ' '+ftform(_aktErtek)+' Ft';
      WriteLn(_LFile,_sorText);
      inc(_xx);
    end;
  VonalHuzo;

  _osszErtek := _sumErtek + _ftErtek;

  writeLn(_LFile,'Osszes keszlet erteke ..:'+ftform(_sumErtek)+' Ft');
  writeLn(_LFile,'Forint keszlet .........:'+ftform(_ftErtek)+' Ft');
  writeLn(_LFile,'Mindosszesen ...........:'+ftform(_osszErtek)+ ' Ft');
  VonalHuzo;
end;

// =============================================================================
                function THAVIZARAS.ArfForm(_ft: integer): string;
// =============================================================================

var _fts: string;
    _w1,_f1: byte;

begin
  _fts := inttostr(_ft);
  _w1  := length(_fts);
  if _w1<4 then
    begin
      while length(_fts)<6 do _fts := ' ' + _fts;
      result := _fts;
      exit;
    end;

  _f1 := _w1-3;
  _fts := leftstr(_fts,_f1)+','+midstr(_fts,_f1+1,3);
  while length(_fts)<6 do _fts := ' ' + _fts;
  result := _fts;
end;

// =============================================================================
                       procedure THAVIZARAS.WesternIras;
// =============================================================================

begin
  KozepreIr('WESTERN UNION FORGALOM ZARASA');
  VonalHuzo;
  WriteLn(_LFile,'            Usa dollar    Magyar Forint');
  Vonalhuzo;

  WriteLn(_LFile,'Nyito :   ' + ftform(_usdNyito)+'    '+ftform(_hufNyito));
  writeLn(_LFile,'Bevet :   ' + ftform(_usdBe)+'    ' + ftform(_hufBe));
  writeLn(_LFile,'Kiadas:   ' + ftform(_usdKi)  +'    ' + ftform(_hufKi));
  writeLn(_LFile,'Zaro  :   ' + ftform(_usdZaro)+'    ' + ftform(_hufZaro));
  VonalHuzo;
end;

// =============================================================================
                          procedure THAVIZARAS.Afairas;
// =============================================================================

begin
  KozepreIr('AFAVISSZATERITES ADATAI');
  VonalHuzo;
  writeLn(_LFile,'Nyito keszlet ........:' + ftform(_metroNyito+_tescoNyito)+' Ft');
  writeLn(_LFile,'Forint ellatmany .....:' + ftform(_tescoBe+_metroBe)+' Ft');
  writeLn(_LFile,'Ellatmany kifizetes ..:' + ftform(_tescoKi+_metroKi)+' Ft');
  writeLn(_LFile,'AFA visszaterites ....:' + FtForm(_tescoVissza+_metroVissza)+' Ft');
  writeLn(_LFile,'Ugykezelesi dij ......:' + FtForm(_ugyKezdij)+' Ft');
  writeLn(_LFile,'Zaro keszlet .........:' + FtForm(_metroZaro+_tescoZaro)+' Ft');
  VonalHuzo;
end;

{
// =============================================================================
                         procedure THAVIZARAS.PtarEkerIras;
// =============================================================================

begin
  Kozepreir('ELEKTROMOS KERESKEDES HAVI ZARASA');
  VonalHuzo;
  writeLn(_LFile,'Havi nyito osszeg.....:' + ftform(_matNyito)+' Ft');
  writeLn(_LFile,'Matrica eladas .......:' + ftform(_matForint)+' Ft');
  writeLn(_LFile,'Telefonfeltoltes .....:' + ftform(_telForint)+' Ft');
  writeLn(_LFile,'Vodafon feltoltes.....:' + ftform(_vodaForint)+' Ft');
  writeLN(_LFile,'Telenor feltoltes ....:' + ftform(_telenorft)+' Ft');
  writeLn(_LFile,'Paysafecard feltoltes.:' + ftform(_paySafeFt)+' Ft');
  writeLn(_LFile,'Forint atadas ........:' + ftform(_matfeladFt)+' Ft');
  writeLn(_LFile,'Havi zaro osszeg .....:' + ftform(_matZaro)+' Ft');
  Vonalhuzo;
end;

// =============================================================================
                       procedure THAVIZARAS.EtarEkerIras;
// =============================================================================

begin
  KozepreIr('ELEKTROMOS KERESKEDES HAVI ZARASA');
  VonalHuzo;
  writeLn(_LFile,'Nyito keszlet ........:' + ftform(_matNyito)+' Ft');
  writeLn(_LFile,'Penz atvetel .........:' + ftform(_matAtveszft)+' Ft');
  writeLn(_LFile,'Penzatadas ...........:' + ftform(_matFeladFt)+' Ft');
  writeLn(_LFile,'Zaro keszlet .........:' + ftform(_matZaro)+' Ft');
  VonalHuzo;
end;
}


// =============================================================================
                      procedure THAVIZARAS.UgyfelForgalomIras;
// =============================================================================

begin
  KozepreIr('A HAVI UGYFELFORGALOM');
  VonalHuzo;

  writeLn(_LFile,'        Elado ugyfelek: '+arfform(_vUgyfel)+ ' FO');
  writeLn(_LFile,'         Vevo ugyfelek: '+arfform(_eUgyfel)+ ' FO');
  Vonalhuzo;
end;

// =============================================================================
               function THAVIZARAS.Ftform(_ft: integer): string;
// =============================================================================

var _f1,_w1: byte;
    _fts,_res: string;

begin
  result := '      -     ';
  if _ft=0 then exit;

  _elojel := ' ';
  if _ft<0 then _elojel := '-';
  _ft := abs(_ft);

  _fts := inttostr(_ft);
  _w1 := length(_fts);
  if _w1<4 then
    begin
      while length(_fts)<11 do _fts := ' '+_fts;
      result := _elojel + _fts;
      exit;
    end;

  // ---------------------------------------

  if _w1<7 then
    begin
      _f1 := _w1 - 3;
      _fts := leftstr(_fts,_f1)+','+midstr(_fts,_f1+1,3);

      while length(_fts)<11 do _fts := ' '+_fts;
      result := _elojel + _fts;
      exit;
    end;

   // -----------------------------------------------------------

  _f1 := _w1-6;
  _res := leftstr(_fts,_f1) + ',';
  _res := _res + midstr(_fts,_f1+1,3)+',';
  _res := _res + midstr(_fts,_f1+4,3);
  while length(_res)<11 do _res := ' ' + _res;
  result := _elojel + _res;
end;

// =============================================================================
                  procedure THAVIZARAS.Kozepreir(_s: string);
// =============================================================================

var _w,_oo: byte;

begin
  _s  := trim(_s);
  _w  := length(_s);
  _oo := trunc((40-_w)/2);
  _s  := dupestring(' ',_oo)+_s;

  writeLn(_LFile,_s);
end;

// =============================================================================
                         procedure THAVIZARAS.VonalHuzo;
// =============================================================================

begin
  writeLn(_LFile,dupestring('-',40));
end;

// =============================================================================
               function THAVIZARAS.Int3Str(_ft: integer):string;
// =============================================================================

var _fts: string;

begin
  _fts := inttostr(_ft);
  while length(_fts)<3 do _fts := ' '+_fts;
  result := _fts;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//
// =============================================================================
                     procedure THAVIZARAS.HavinyitoAdatFeliras;
// =============================================================================

var i: byte;
    _aktdnev: string;
    _hkdjz,_utkdss: integer;

begin
  HzMake;

  for i := 1 to 27 do _hzaro[i] := 0;

  _cimtarTablaNev := 'CIMT' + _farok;

  _pcs := 'SELECT * FROM ' + _cimtarTablaNev + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  DataDbase.Connected := True;
  with DataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _utDatum := FieldByName('DATUM').asString;
      Close;
    end;
   _pcs := 'SELECT * FROM ' + _cimtarTablaNev + _sorveg;
   _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _utdatum + chr(39) + _sorveg;
   _pcs := _pcs + 'ORDER BY VALUTANEM';

   with DAtaQuery do
     begin
       Close;
       Sql.clear;
       Sql.add(_pcs);
       Open;
       First;
     end;

   while not DataQuery.eof do
     begin
       _aktDnem := Dataquery.FieldByNAme('VALUTANEM').asString;
       _aktZaro := Dataquery.FieldByNAme('OSSZESFORINTERTEK').asInteger;

       _xx := ScanDnem(_aktDnem);
       _hzaro[_xx] := _aktZaro;
       DataQuery.next;
     end;

   DataQuery.close;
   DataDbase.close;

   // -----------------------------------------------------------

   _xx := 1;
   while _xx<=27 do
     begin
       _aktDnem := _dNem[_xx];
       _aktZaro := _hZaro[_xx];

       if _aktZaro>0 then
         begin
           _aktDnev := _dNev[_xx];

           _pcs := 'INSERT INTO ' + _ujHzTablaNev + ' (VALUTANEM,VALUTANEV,ZARO)'+_SORVEG;
           _pcs := _pcs + 'VALUES (' + chr(39) + _aktDnem + chr(39) + ',';
           _pcs := _pcs + chr(39) + _aktDnev + chr(39) + ',';
           _pcs := _pcs + inttostr(_aktZaro) + ')';
           DataParancs(_pcs);
         end;
       inc(_xx);
     end;

   // --------------------------------------------------------------------------

   ValDbase.Connected := True;

   _pcs := 'SELECT * FROM HAVIKEZELESIDIJ' + _sorveg;
   _pcs := _pcs + 'WHERE HONAP=' + inttostr(_kertho);

   with ValQuery do
     begin
       Close;
       Sql.clear;
       Sql.add(_pcs);
       Open;
       _hkDjZ := FieldByNAme('ZARO').asInteger;
       Close;
     end;
   ValDbase.close;

   _utKdSs := GetUtKezdijSs;

   _pcs := 'UPDATE ' + _ujHzTablaNev + ' SET KEZDIJZARO='+inttostr(_hkDjZ);
   _pcs := _pcs + ',UTKEZDIJSORSZAM='+inttostr(_utKdSs);
   DataParancs(_pcs);
end;

// =============================================================================
                             procedure THAVIZARAS.HzMake;
// =============================================================================

begin
  _ujHzTablaNev := 'HZ' + _farok;
  MessPanel.caption := 'HZ - tábla létrehozása';
  MessPanel.Repaint;

  DataTabla.close;
  DataTabla.TableName := _ujHzTablaNev;

  DataDbase.Connected := True;
  if DataTabla.Exists then
    begin
      DataDbase.close;
      _pcs := 'DELETE FROM ' + _ujHzTablaNev;
      DataParancs(_pcs);
      exit;
    end;

  DataDbase.close;

  _pcs := 'CREATE TABLE ' + _ujhzTablaNev + '(';
  _pcs := _pcs + 'VALUTANEM CHAR (3)'+ ',' + _sorveg;
  _pcs := _pcs + 'VALUTANEV CHAR (20) CHARACTER SET WIN1250 COLLATE PXW_HUN' + ',' + _Sorveg;
  _pcs := _pcs + 'ZARO INTEGER,'+ _sorveg;
  _pcs := _pcs + 'KEZDIJZARO INTEGER,' + _sorveg;
  _pcs := _pcs + 'UTKEZDIJSORSZAM INTEGER)';
  DataParancs(_pcs);

  _pcs := 'CREATE INDEX X' + _ujHZTablaNev + _sorveg;
  _pcs := _pcs + 'ON ' + _ujhzTablaNev + ' (VALUTANEM)';
  DataParancs(_pcs);
end;

///----------------QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ---------------------------

// =============================================================================
                  procedure THavizaras.Havitrade;
// =============================================================================

var _tnev,_biz,_tpt,_tip,_fts,_sortext,_tips: string;
    _ft,_nyito,_psafeforint,_felforint,_zaro: integer;

begin
  writeLn(_LFile,'         E-KER HAVI ZARAS');
  VonalHuzo;

  _tnev := 'TRAD' + _farok;
  _pcs := 'SELECT * FROM '+_tnev+_sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  Tradedbase.close;
  Tradedbase.databaseName := 'c:\valuta\database\trade.fdb';
  Tradedbase.Connected := true;
  with TradeQuery do
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
      writeLn(_LFile,'Bizony.  Megnevezes      Osszeg     Ptar');
      writeLn(_lfILE,dupestring('-',39));

      while not TradeQuery.Eof do
        begin
          _biz := Tradequery.FieldByName('BIZONYLATSZAM').asstring;
          _ft  := TradeQuery.FieldByName('FIZETENDO').asInteger;
          _tpt := TradeQuery.FieldByName('TARSPENZTAR').asString;
          _tip := TradeQuery.FieldByName('TIPUS').asstring;

          if _tpt<>'TK' then
            begin

              _fts := FtForm(_ft);
              _sortext :=Kieg(_biz,9);

              if _tip='T' then _tips := 'Telefon felt.';
              if _tip='V' then _tips := 'Vodafon felt.';
              if _tip='N' then _tips := 'Telenor felt.';
              if _tip='M' then _tips := 'Matrica ert.';
              if _tip='P' then _tips := 'Paysafe ert.';

              if (_tip='F') and (_ft<0) then _tips := 'Penzatvetel';
              if (_tip='F') and (_ft>0) then _tips := 'Penzatadas';

              _ft := abs(_ft);
              _fts := FtForm(_ft);
              _sortext := _sortext + Kieg(_tips,15);
              _sortext := _sortext + Elokieg(_fts,11);

              if _tip='F' then _sortext := _sortext +' ' + _tpt;
              writeLn(_LFile,_sortext);
            end;
          TradeQuery.next;
        end;
    end;

  TradeQuery.Close;
  Tradedbase.close;

  // -----------------------------------------------------------------------


  TradeDbase.Connected := true;
  _pcs := 'SELECT * FROM HAVIOSSZESITO' + _sorveg;
  _pcs := _pcs + 'WHERE EVHONAP='+ chr(39) + '20' + _farok + chr(39);

  with TradeQuery do
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
       TradeQuery.close;
       TradeDbase.close;
       exit;
     end;

   with TradeQuery do
     begin
       _nyito := FieldByName('NYITO').asInteger;
       _matforint := FieldByName('MATRICAFORINT').asInteger;
       _telForint := FieldByName('TELEFONFORINT').asInteger;
       _vodaForint := FieldByName('VODAFONFORINT').asInteger;
       _telenorForint := FieldByName('TELENORFORINT').asInteger;
       _psafeForint := FieldByNAme('PAYSAFEFORINT').asInteger;
       _felForint := FieldByName('FELADASFORINT').asInteger;
       _zaro := FieldByName('ZARO').asInteger;
       Close;
     end;
   TradeDbase.close;

   VonalHuzo;
   writeLn(_LFile,'     Havi nyitókészlet: '+fTform(_nyito));
   writeLn(_LFile,'         Matrica vétel: '+ftform(_matforint));
   writeLN(_Lfile,'     Telefon feltöltés: '+ftform(_telforint));
   writeLn(_Lfile,'     Vodafon feltöltés: '+ftform(_vodaforint));
   writeLn(_LFile,'     Telenor feltöltés: '+ftform(_telenorForint));
   writeLn(_LFile,'           Paysafecard: '+ftform(_psafeforint));
   writeLn(_LFile,'        Forint feladás: '+ftform(_felforint));
   writeLn(_LFile,'      Havi zárókészlet: '+fTform(_zaro)+_sorveg);
   writeLn(_Lfile,'  A feltöltések összege a vodafone');
   writeLn(_Lfile,'   kivételével 21% áfát tartalmaz');
   VonalHuzo;
end;

// =============================================================================
             procedure ThaviZaras.EtarHaviTradeTablo;
// =============================================================================

var _bosss,_bizonylat,_btipus,_tptar,_sortext: string;
    _bosszeg,_nyito,_zaro: integer;

begin

  // ---------------------------------------------------------------------------
  writeLn(_LFile,'            MATRICA HAVI ZARAS');
  VonalHuzo;
  writeLn(_LFile,' Datum     Bizonyl. Tranz. Osszeg   Ptar');
  VonalHuzo;

  // ---------------------------------------------------------------------------

  _pcs := 'SELECT * FROM MATBIZONYLAT' + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM>'+chr(39) + _elseje + chr(39)+') AND (DATUM<'+chr(39)+_hovege+chr(39)+')'+_sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  (*
   Datum     Bizonyl. Tranz. Osszeg   Ptar
  2011.01.22 B-000002 atvet 123456000 TRB
  123456789012345678901234567890123456789
                     storn
  *)

  ValDbase.Connected := true;
  with ValQuery do
    begin
      CLose;
      sql.clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  _atadas  := 0;
  _atvetel := 0;

  while not ValQuery.eof do
    begin
      with ValQuery do
        begin
          _datum     := FieldByName('DATUM').asstring;
          _bosszeg   := FieldByName('OSSZEG').asInteger;
          _bizonylat := FieldByName('BIZONYLATSZAM').asString;
          _tptar     := FieldByName('TARSPENZTAR').asstring;
        end;

      _bosszeg := abs(_bosszeg);

      _bTipus := leftstr(_bizonylat,1);
      _sortext := _datum+' '+_bizonylat+' ';

      if _btipus='B' then
        begin
          _atvetel := _atvetel + _bosszeg;
          _sortext := _sortext + 'atvet';
        end;

      if _btipus='K' then
        begin
          _atadas := _atadas + _bosszeg;
          _sortext := _sortext + 'atad ';
        end;
      if _btipus = 'S' then _sortext := _sortext + 'storn';

      _bosss := inttostr(_bosszeg);
      _bosss := Elokieg(_bosss,10);
      _sortext := _sortext+_bosss+' '+_tptar;
      writeLn(_LFile,_sortext);
      valquery.Next;
    end;
  ValQuery.close;
  Valdbase.close;

  // ---------------------------------------------------------------------------

  ValDbase.connected := true;

  _pcs := 'SELECT * FROM HAVIMAT' + _sorveg;
  _pcs := _pcs + 'WHERE EVHONAP='+CHR(39)+_AKTEVHONAP+chr(39);
  with ValQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      _recno := recno;
    end;

  _nyito := 0;
  _atadas := 0;
  _atvetel := 0;
  _zaro := 0;

  if _recno>0 then
    begin
      with ValQuery do
        begin
          _nyito := FieldByName('NYITO').asInteger;
          _atadas := FieldByName('ATADAS').asInteger;
          _atvetel := FieldByNAme('ATVETEL').asInteger;
          _zaro := FieldByname('ZARO').asInteger;
        end;
    end;

  ValQuery.Close;
  Valdbase.close;

  VonalHuzo;

  writeLn(_LFile,'Havi nyitókészlet: '+ftform(_nyito));
  writeLn(_LFile,'Pénztári átadás  : '+ftform(_atadas));
  writeLN(_Lfile,'Pénztári átvétel : '+ftform(_atvetel));
  writeLn(_LFile,' Havi zárókészlet: '+ftform(_zaro));
  VonalHuzo;

end;



function THaviZaras.sform(_n,_h: integer): string;

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

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



// =============================================================================
             function  THavizaras.S9(_n: integer): string;
// =============================================================================

begin
  result := inttostr(_n);
  while length(result)<9 do result := ' ' + result;
end;



function THavizaras.Wout(_s: string): string;

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
             function THaviZaras.F6(_n: integer): string;
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
              function THaviZaras.F9(_n: integer): string;
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


procedure THavizaras.HrkLista;

begin
  _datumelo := inttostr(_kertev)+'.'+nulele(_kertho);
  _pcs := 'SELECT * FROM HRKNAPLO' + _sorveg;
  _pcs := _pcs + 'WHERE DATUM LIKE ' + chr(39)+_datumelo + '%' + chr(39) + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  Hrkdbase.connected := true;
  with HrkQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  _nyito := HrkQuery.FieldByNAme('NYITO').asInteger;
  _sumbe := 0;
  _sumki := 0;
  while not hrkQuery.eof do
    begin
      _bevet := HrkQuery.fieldByNAme('BEVETEL').asInteger;
      _kiad  := HrkQuery.FieldByName('KIADAS').asInteger;
      _zaro  := HrkQuery.FieldByNAme('ZARO').asInteger;

      _sumbe := _sumbe + _bevet;
      _sumki := _sumki + _kiad;

      HrkQuery.Next;
    end;

  HrkQuery.close;
  HrkDbase.close;

  _hrkzaro := _nyito + _sumbe - _sumki;
  if _hrkzaro<>_zaro then
    begin
      ShowMessage('HIBA A HRK ZÁRÓÖSSZEGBEN');
      exit;
    end;

  KozepreIr('HORVÁT KUNA HAVI ZÁRÁSA');
  VonalHuzo;
  WriteLN(_LFile,'Havi nyito osszeg ......:' + ftform(_Nyito));
  WriteLN(_LFile,'Vett horvat kuna .......:' + ftform(_sumbe));
  WriteLN(_LFile,'Atadott osszeg .........:' + ftform(_sumki));
  WriteLN(_LFile,'Havi zaro osszeg .......:' + ftform(_hrkZaro));
  VonalHuzo;
end;


end.
