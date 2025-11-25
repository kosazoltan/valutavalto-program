unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBQuery, IBCustomDataSet,
  IBTable, strutils, ExtCtrls, ComCtrls, dateutils;

type
  TForm1 = class(TForm)
    STARTGOMB: TBitBtn;
    KILEPOGOMB: TBitBtn;
    PGYQUERY: TIBQuery;
    PGYDBASE: TIBDatabase;
    PGYTRANZ: TIBTransaction;
    INFOBOX: TListBox;
    Label1: TLabel;
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    mainpanel: TPanel;
    VTABLA: TIBTable;
    ALLUGYFQUERY: TIBQuery;
    ALLUGYFDBASE: TIBDatabase;
    ALLUGYFTRANZ: TIBTransaction;
    ALLJOGIQUERY: TIBQuery;
    ALLJOGIDBASE: TIBDatabase;
    ALLJOGITRANZ: TIBTransaction;
    ALLUGYFTABLA: TIBTable;
    ALLJOGITABLA: TIBTable;
    UGYFQUERY: TIBQuery;
    UGYFDBASE: TIBDatabase;
    UGYFTRANZ: TIBTransaction;
    UGYFTABLA: TIBTable;
    tovabbgomb: TBitBtn;
    PGYTABLA: TIBTable;
    CSIK: TProgressBar;
    LBOX: TListBox;
    BitBtn1: TBitBtn;

    procedure AdatokPotlasa;
    procedure KILEPOGOMBClick(Sender: TObject);
    procedure STARTGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure Valutaparancs(_ukaz: string);
    procedure Uparancs(_ukaz: string);
    procedure UjUgyfelFelvetele;
    procedure UjMegbizottFelvetele;
    procedure UjJogiFelvetele;
    procedure BizonylatKonyveles;

    function Nulele(_b: byte): string;
    function DataFromVdbase: boolean;
    function DataFromAllUgyfel: boolean;
    function DataFromAllJogi: boolean;
    function NaturUgyfelKereses: integer;
    function MbUgyfelKereses: integer;
    function JogiUgyfelKereses: integer;
    function HutoGb(_kod: byte): byte;
    function DoubleKill(_s: string): string;
    function Angolra(_huName: string): string;
    function Tomorito(_ts: string): string;
    function Kokm(_s:string): string;
    
    procedure tovabbgombClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _biztabla,_plombaszam,_mbdatasorszam: string;
  _iras: textfile;

  _pcs,_nevtabla,_mbNevTabla,_jTablanev,_jPcs,_mbTablanev,_upcs,_mbpcs: string;
  _uTablanev,_lastmezo,_logpath: string;
  _sorveg: string = chr(13)+chr(10);

  _rTranzdb,_rSumma,_rHetiossz,_rEvimax,_rSorszam,_rTiltva: integer;
  _rAnyjaneve,_rSzuletesihely,_rSzuletesiido: string;

  _natursss,_jogisss,_mbsss: integer;
  _ssumma,_sevimax,_recno,_sTranzdb,_aktsss,_p: integer;

  _gypenztar: byte;
  _gyDatum,_gynev,_gybizonylat: string;
  _gyFizetendo,_PP: integer;

  _vDbasePath,_vUgyfeltip,_vUgyfelnev,_evtizeds,_farok,_bfnev,_vnevbetu: string;
  _vUgyfelszam: integer;

  _uNev,_uElo,_uAnyja,_uLany,_uSzulhely,_uSzulido,_uAllamp,_uLakcim,_uIso: string;
  _uOkmTip,_uAzonosito,_uTarthely,_uLCimCard,_uIrszam,_uVaros,_uUtca: string;
  _ukulf,_uKozszer: byte;

  _jNev,_jTelep,_jOkirat,_jFotev,_jKepvis,_jMBnev,_jMbbeo,_jKepvisbeo: string;
  _jiso,_jOrszag,_aktjnev: string;
  _jMbszam: integer;

  _mbNev,_mbElo,_mbAnyja,_mbLany,_mbSzulhely,_mbSzulido,_mbAllamp: string;
  _mbLakcim,_mbOkmTip,_mbAzonosito,_mbTarthely,_mbLCimCard,_mbIrszam: string;
  _mbVaros,_mbUtca,_mbIso: string;
  _mbkulf,_mbKozszer: byte;

  _ukBetu,_mbkBetu,_logfile,_logdir,_mm: string;
  _megvan: boolean;

  _aktev,_aktho,_aktnap,_akthour: word;

implementation

{$R *.dfm}


// =============================================================================
                 procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin
  _aktev := yearof(date);
  _aktho := monthof(date);
  _aktnap:= dayof(date);

  _logfile := 'XL'+inttostr(_aktev-2000)+nulele(_aktho)+nulele(_aktnap)+'.LOG';
  _logdir := 'c:\receptor\mail\log';

  if not Directoryexists(_logdir) then createdir(_logdir);
  _logpath := _logdir + '\' + _logfile;
  AssignFile(_iras,_logPath);
  rewrite(_iras);

  with Infobox do
    begin
      top := 120;
      left := 144;
      visible := True;
      repaint;
    end;
  Activecontrol := TovabbGomb;
end;


// =============================================================================
                procedure TForm1.STARTGOMBClick(Sender: TObject);
// =============================================================================

begin

  // A hiányzó tranzakciók adatait tartalmazza a PGYTABLA adatbázis¦

  StartGomb.enabled := False;
  with MainPanel do
    begin
      top := 120;
      left := 144;
      Visible := true;
      repaint;
    end;

  Pgydbase.Connected := true;
  if Pgytranz.InTransaction then pgytranz.Commit;
  Pgytranz.StartTransaction;
  Pgytabla.Open;
  Pgytabla.Last;
  _recno := Pgytabla.RecNo;
  Csik.Max := _recno;

  if _recno=0 then
    begin
      // Üres a hiányzó tranzakciók adatai - Nincs mit tenni  - vége
      Pgytranz.commit;
      PgyDbase.close;
      Pgytabla.close;
      CLosefile(_iras);
      ShowMessage('NINCSEN RÖGZITETT HIBÁS TRANZAKCIÓ A PGYÜJTÕBEN');
      Application.Terminate;
      exit;
    end;

  // -----------------------  TÉNYLEGES INDULÁS --------------------------------

  PgyTabla.First;
  _pp := 0;
  while not PgyTabla.Eof do
    begin
      inc(_pp);
      Csik.Position := _pp;

      _gypenztar   := PgyTabla.fieldByName('PENZTAR').asInteger;
      _gydatum     := PgyTabla.FieldByname('DATUM').asString;
      _gynev       := trim(PgyTabla.FieldByName('NEV').AsString);
      _gyFizetendo := PGyTabla.FieldByNAme('FIZETENDO').asInteger;
      _gyBizonylat := PgyTabla.FieldByName('BIZONYLAT').asString;


      _mm:= inttostr(_gypenztar)+'. számu pénztár '+_gyDatum+'-an ';
      _mm := _mm + ' Kiadta a '+_gybizonylat+' számu bizonylatot ';
      _mm := _mm + inttostr(_gyfizetendo)+' Ft értékben';
      writeln(_iras,'================');
      writeLn(_iras,_mm);

      Lbox.Items.add(inttostr(_gyPenztar)+'-'+_gydatum+':'+_gynev);
      Lbox.Repaint;

      _evtizeds    := midstr(_gyDatum,3,2);
      _farok       := midstr(_gydatum,3,2)+midstr(_gydatum,6,2);
      _bfnev       := 'BF' + _farok;

      // A _vugyfelszam és _vugyfeltip beolvasasa Vxxx.fdb-böl a gydatum hónapi
      // BF-táblából a gyBizonylat rekordjából

      if not DataFromVdbase then
        begin
          PGyTabla.Next;
          continue;
        end;

       // -----------------------------------------------------------

      // A _vugyfelszam és a _vugyfeltip alapján az aktuális pénztár
      // átmentett Valuta.fdb UGYFEL táblájából adatokat olvas ki
      // u-val kezdödõ változókba (vagy nem sikerül result = false)

      if _vUgyfeltip='N' then
        begin
          if not DataFromAllUgyfel  then
            begin
              PGyTabla.next;
              Continue;
            end;

         // Most megkeresi az ügyfelet a Server ugyfélnyilvántartásában

          _natursss := NaturUgyfelKereses;
          if _natursss=-1 then
            begin
              // Ez tiltott ügyfél volt

              PgyTabla.next;
              continue;
            end;

          if _natursss=0 then UjUgyfelFelvetele;

          if _natursss=0 then
            begin
              PgyTabla.next;
              continue;
            end;
        end;


      // A _vugyfelszam rekordjat keresi az átmentett jogiszemély táblából
      // ha megtalálta j-vel kezdödö változókba irja
      // a megbizott személy adatait mb-vel kezdödö változókba irja

      if _vUgyfeltip='J' then
        begin
          if not DataFromAllJogi then
            begin
              PGyTabla.Next;
              Continue;
            end;

          //  elsõnek megkeresi a megbizott személy adatait:

          _mbsss := MbUgyfelKereses;
          if _mbsss=0 then Ujmegbizottfelvetele;

          _mbdatasorszam := _mbNevtabla+inttostr(_mbsss);

          // ------------------------------------------------

          _jogisss := JogiUgyfelKereses;
          if _jogisss=-1 then
            begin
              PgyTabla.next;
              Continue;
            end;

          if _jogisss=0 then UjJogiFelvetele;

          if _jogisss=0 then
            begin
              PgyTabla.Next;
              Continue;
            end;
        end;


      adatokPotlasa;

      PgyTabla.edit;
      Pgytabla.FieldByName('PLOMBA').asString := 'OKE';
      Pgytabla.post;

      Lbox.items.Add('SIKERES ADATPÓTLÁS TÖRTÉNT');
      Lbox.Repaint;


      PgyTabla.next;
    end;
  Pgytranz.commit;
  Pgydbase.close;

  _pcs := 'DELETE FROM PGYUJTO' + _sorveg;
  _pcs := _Pcs + 'WHERE PLOMBA=' + chr(39) + 'OKE' + chr(39);

  Pgydbase.Connected := true;
  if Pgytranz.InTransaction then pgytranz.Commit;
  Pgytranz.StartTransaction;
  with PgyQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;
  Pgytranz.commit;
  Pgydbase.close;

  ShowMessage('AZ ADAT POTLÁSOKAT BEFEJEZTEM');
 
end;

// =============================================================================
                function TForm1.DataFromVdbase: boolean;
// =============================================================================

begin
  result := False;

  if _gypenztar<151 then _vDbasePath := 'c:\receptor\database\v' + inttostr(_gypenztar)+'.fdb'
  else _vDbasePath := 'c:\cartcash\database\v' + inttostr(_gypenztar)+'.fdb';

  if not fileExists(_vdbasepath) then exit;

  _mm := 'Megnyitom a '+_vdbasepath+' nevü adatbázist';
  writeln(_iras,_mm);

  with VDbase do
    begin
      Close;
      DatabaseName := _vDbasePath;
      Connected := true;
    end;

  vtabla.close;
  vTabla.TableName := _bfNev;

  _mm := 'Meg szeretném nyitni a '+_bfnev+' táblát';
  writeLn(_iras,_mm);

  if not vtabla.Exists then
    begin

      writeLn(_iras,'Nincs ilyen adattábla ..'+chr(13)+chr(10));
      vdbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM ' + _bfNev + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_gybizonylat+chr(39);

  with vQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      writeLn(_iras,_gyBizonylat+' számú bizonylat nincs a táblában');
      writeLN(_iras,' ');

      vquery.close;
      vdbase.close;
      exit;
    end;

  _vUgyfeltip  := Vquery.fieldByName('UGYFELTIPUS').asString;
  _vUgyfelszam := Vquery.FieldByName('UGYFELSZAM').asInteger;
  _vugyfelnev  := TRIM(Vquery.FieldByNAme('UGYFELNEV').asString);

  _mm := _gyBizonylat+' számu bizonylaton: ';
  _mm := _mm + inttostr(_vugyfelszam)+' számu '+_vugyfeltip + ' tipusú ';
  _mm := _mm + _vugyfelnev + ' nevü ügyfelet találtam';
  writeLn(_iras,_mm);

  vquery.close;
  vdbase.close;

  // ----------------------------------------------------------

  if (_vUgyfelszam=0) or ((_vugyfeltip<>'N') and (_vUgyfeltip<>'J')) then exit;

  result := true;
end;

// =============================================================================
               function TForm1.NaturUgyfelKereses: integer;
// =============================================================================

var _pont: byte;

begin

  // Az ugyfelnev kezdöbetüje alapján meghatározza a NÉVTÁBLA-t

  result := 0;
  writeLn(_iras,'Most megkeressi az ügyfelet az UGYFELxx.FDB nyilvántartásában');

  _ukBetu := leftstr(_unev,1);
  _nevtabla  := _ukBetu + 'NEV';
  _biztabla  := _ukbetu + 'BIZ';

  // A szerveren megnyitja a névnek megfelelö Nevtablat
  // ée keresi az Ugyfelnev-et:

  _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
  _pcs := _pcs + 'WHERE NEV=' + chr(39) + _unev + chr(39);

  writeLn(_iras,_nevtabla+' nevü táblában keresi a(z) '+_uNev+' nevet');

  Ugyfdbase.close;
  Ugyfdbase.databasename := 'c:\receptor\database\ugyfel'+_evtizeds+'.fdb';
  Ugyfdbase.connected := true;
  writeln(_iras,'(az alkalmazott adatbázis: UGYFEL'+_evtizeds+'.FDB)');

  with UgyfQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := Recno;
    end;

  // Ha nem találja az ügyfél nevét a szerveren, akkor ez egy új ügyfél lesz

  if _recno=0 then
    begin
      // Még nincs az ügyfél regisztrálva
      writeLn(_iras,'Nem találta -  tehát az ügyfél még nincs regisztrálva');
      writeLn(_iras,' ');

      UgyfQuery.close;
      Ugyfdbase.close;
      exit;
    end;

  // Az ügyfélnek megfelelö nevre van leszürve az adatbázis:

  _megvan := False; // default = nincs meg

  writeLn(_iras,'Talált ilyen nevü ügyfele(ke)t. Nost nézi a többi adatokat');

  _p :=0;
  while not UgyfQuery.eof do
    begin
      // Ha a következö 3 adatból 2 egyezik, akkor azonositva van az ügyfel:

      inc(_p);

      _rAnyjaneve     := trim(UgyfQuery.fieldByNAme('ANYJANEVE').asString);
      _rSzuletesihely := trim(UgyfQuery.FieldByNAme('SZULETESIHELY').asString);
      _rSzuletesiido  := trim(UgyfQuery.FieldByNAme('SZULETESIIDO').asString);

      writeLn(_iras,inttostr(_p)+', '+_rAnyjaneve+'-'+_rszuletesihely+'-'+_rszuletesiido);

      _pont := 0;
      if _ranyjaneve=_uanyja then _pont := 1;
      if _rszuletesiido=_uszulido then inc(_pont);
      if _rszuletesihely=_uszulhely then inc(_pont);

      writeLn(_iras,'A többi adat '+ inttostr(_pont)+'-on egyezik');

      if _pont>1 then
        begin
          // AZ ügyfél egyeztetve van, befejezi a keresést:
          _megvan := True;
          writeLn(_iras,' ... tehát egyezõnek tekinthetõ');
          break;
        end;

      // Tovább keres az adatbázisban:
      UgyfQuery.next;
    end;

  // Mégsem találta meg az egyezö adatu személyt:
  if not _megvan then
    begin
      // A többi adat nem egyezett - igy nincs meg az ügyfél

      UgyfQuery.close;
      Ugyfdbase.close;

      writeLn(_iras,'A többi adat eltér -  tehát nincs még nyilvántartva');

      exit;
    end;

  // Megtalálta a szerveren az aktuális ügyfelet:
  // Igy beolvassa az összes személyi adatát, és az évi tranzakció adatait:

  writeLn(_iras,'Tehát sikerült megtalálni a szerveren az ügyfelet');

  with UgyfQuery do
    begin
      _rTranzdb := FieldByNAme('TRANZAKCIODB').asInteger;
      _rsorszam := FieldByNAme('SORSZAM').asInteger;
      _rtiltva  := FieldByNAme('TILTVA').asInteger;
      _rsumma   := FieldByNAme('FORINTOSSZEG').asInteger;
      _revimax  := FieldByNAme('EVIMAX').asInteger;
      _rhetiossz:= FieldByNAme('HETIOSSZ').asInteger;
    end;

  writeLn(_iras,'A regisztrált ügyfél változó adatai');
  writeLn(_iras,'  - eddigi tranzakciók száma     : '+inttostr(_rtranzdb)+' db');
  writeLn(_iras,'  - eddigi tranzakciók összértéke: '+inttostr(_rsumma)+' Ft');
  writeLn(_iras,'  - az évi maximális váltás      : '+inttostr(_rEvimax)+' Ft');
  if _rtiltva=1 then writeLn(_iras,'Az ügyfél le van tiltva !')
  else writeLn(_iras,'Az ügyfél nincs letiltva');
  writeln(_iras,' ');

  if _rtiltva=1 then result := -1 else result := _rSorszam;

  UgyfQuery.close;
  Ugyfdbase.close;
end;

// =============================================================================
                  function TForm1.DataFromAllJogi: boolean;
// =============================================================================

begin
  result := False;
  _jTablanev := 'J' + inttostr(_gyPenztar);

  _mm := 'A jogi személyt keresi a ' + _jTablanev + ' lementett jogi táblában';
  writeLN(_iras,_mm);

  AllJogiDbase.Connected := true;

  AllJogiTabla.close;
  AllJogiTabla.TableName := _jtablanev;

  if not AllJogiTabla.Exists then
    begin
      writeln(_iras,'Nincs lementve '+_jTablanev+' nevü jogi adatbázis');

      // Nincs átmentett Jogiszemély adatbázis
      AllJogidbase.close;
      Exit;
    end;

  // Keresi a _vugyfelszam-hoz tartozó rekordot a jogiszemely táblában

  _jpcs := 'SELECT * FROM ' + _jTablanev + _sorveg;
  _jpcs := _jpcs + 'WHERE UGYFELSZAM=' + inttostr(_vUgyfelszam);

  writeLn(_iras,_jtablanev+' adatbázisban keresi '+inttostr(_vugyfelszam)+' számu jogi személyt');

  with AllJogiQuery do
    begin
      Close;
      sql.clear;
      sql.add(_jpcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      // Nem találta meg a _vugyfelszamhoz tartozó rekordot (nem jellemzõ):

      writeLn(_iras,'Még nincs regisztrálva ez a jogiszemély');

      AllJogiQuery.close;
      AllJogiDbase.close;
      exit;
    end;

  // Megtalálta a vugyfelszamhoz tartozó rekordot. Az adatokat j-vel kezdödö
  // változókba olvassa

  writeLn(_iras,'A jogi személy meg van. Adatai:');

  with AllJogiQuery do
    begin
      _jnev := angolra(Fieldbyname('JOGISZEMELYNEV').asString);
      _jTelep:= angolra(FieldByNAme('TELEPHELYCIM').asString);
      _jOkirat := angolra(FieldByName('OKIRATSZAM').AsString);
      _jFotev := angolra(FieldByNAme('FOTEVEKENYSEG').asString);
      _jKepvis := angolra(FieldByNAme('KEPVISELONEV').asString);
      _jMBszam := FieldByNAme('MEGBIZOTTSZAMA').asInteger;
      _jMBnev := angolra(FieldByNAme('MEGBIZOTTNEVE').asString);
      _jMBbeo := angolra(FieldByNAme('MEGBIZOTTBEOSZTASA').asString);
      _jKepvisbeo := angolra(FieldByNAme('KEPVISBEO').asString);
      _jIso := trim(FieldByNAme('ISO').AsString);
      _jOrszag := trim(FieldByNAme('ORSZAG').asString);
      Close;
    end;

  if length (_jiso)<>2 then _jiso := 'HU';

  writeLn(_iras,'   - ' + _jnev);
  writeLn(_iras,'   - ' + _jTelep);
  writeLn(_iras,'   - mbNev : ' + _jMbnev);
  writeLn(_iras,'   - mbszám: ' + inttostr(_jmbszam));

  AllJogiDbase.close;

  // ----------------------------------

  // Nagy hiba, ha nincs megbizott a jogiszemélyhez rendelve. Nagyon ritkán

  if _jMbszam=0 then exit;

  // A pénztár átmentett ügyféltáblája:

 _mbTablanev := 'U'+inttostr(_gyPenztar);
  writeLn(_iras,'Most meg kell keresni a megbizott személyt');
  writeLn(_iras,'Az aktuális adattábla: '+ _mbTablanev);

  AllUgyfDbase.Connected := True;

  AllUgyfTabla.close;
  Allugyftabla.TableName := _mbtablanev;

  if not Allugyftabla.Exists then
    begin

      // Nincs meg az átmentett adabázis
      writeLn(_iras,'Nincs lementve a kivánt jogiszemély tábla');
      Allugyfdbase.close;
      Exit;
    end;

  // megkeresi a megbizott személy rekordját

  _mbpcs := 'SELECT * FROM ' + _mbTablanev + _sorveg;
  _mbpcs := _mbpcs + 'WHERE UGYFELSZAM=' + inttostr(_jMbszam);

  _mm := 'Keresi ' + _mbTablanev +'-ben ' + inttostr(_jmbszam)+' számu megbizottat';
  writeLn(_iras,_mm);

  with AllUgyfquery do
    begin
      Close;
      sql.clear;
      sql.add(_mbpcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin

      // Nem találta meg a megbizott adatait:

      writeln(_iras,'Nem találta meg a megbizottat a '+_mbtablanev+'-ben');

      AllUgyfquery.close;
      AllUgyfdbase.close;
      exit;
    end;

  // Most mb-vel kezdödö változókba tölti a megbizott adatait:

  writeln(_iras,'Megtalálta a megbizott személy adatait a lemntett táblában');
  with AllUgyfQuery do
    begin
      _mbnev       := angolra(FieldByNAme('NEV').asString);
      _mbElo       := angolra(FieldByName('ELOZONEV').asString);
      _mbAnyja     := angolra(FieldByNAme('ANYJANEVE').asString);
      _mbLany      := angolra(FieldByName('LEANYKORI').asString);
      _mbSzulhely  := angolra(FieldByNAme('SZULETESIHELY').asString);
      _mbSzulido   := tomorito(FieldByNAme('SZULETESIIDO').asString);
      _mballamp     := angolra(FieldByNAme('ALLAMPOLGAR').asString);
      _mbLakcim    := angolra(FieldByName('LAKCIM').asString);
      _mbOkmtip    := FieldByName('OKMANYTIPUS').asString;
      _mbAzonosito := angolra(FieldByname('AZONOSITO').asString);
      _mbTarthely  := angolra(FieldByNAme('TARTOZKODASIHELY').asString);
      _mbLcimCard  := angolra(FieldByName('LAKCIMKARTYA').asString);
      _mbKulf      := FieldByName('KULFOLDI').asInteger;
      _mbKOzszer   := FieldByNAme('KOZSZEREPLO').asInteger;
      _mbIrszam    := FieldByNAme('IRSZAM').asString;
      _mbVaros     := angolra(FieldByNAme('VAROS').asString);
      _mbUtca      := angolra(FieldByNAme('UTCA').asString);
      _mbiso       := trim(FieldByName('ISO').asString);
      Close;
    end;

  if length(_mbiso)<2 then _mbIso := 'HU';

  _mbOkmtip := kokm(_mbOkmtip);
  writeln(_iras,_mbnev+'-'+_mbAnyja+'-'+_mbszulhely+'-'+_mbszulido);

  AllUgyfdbase.close;
  result := True;
end;


// =============================================================================
                      procedure TForm1.AdatokPotlasa;
// =============================================================================

begin

  writeLn(_iras,'Végül pótolja a hiányzó adatokat:');
  _ssumma := _gyfizetendo + _rsumma;
  _stranzdb := _rTranzdb+1;
  if _rEvimax<_gyFizetendo then _sEvimax := _gyFizetendo else _sEvimax := _rEvimax;

  writeLn(_iras,inttostr(_ssumma)+'='+inttostr(_rsumma)+'+'+inttostr(_gyfizetendo));

  if _vUgyfeltip='N' then
    begin
      _plombaszam := _nevtabla+inttostr(_natursss);

      writeln(_iras,'plombaszam: '+_plombaszam);

      _aktsss := _natursss;
      BizonylatKonyveles;

      _pcs := 'UPDATE ' + _nevtabla + ' SET FORINTOSSZEG='+ inttostr(_ssumma);
      _pcs := _pcs + ',EVIMAX='+inttostr(_sevimax)+',DATUM='+chr(39)+_gydatum+chr(39);
      _pcs := _pcs + ',TRANZAKCIODB=' + inttostr(_sTranzdb);
      _pcs := _pcs + ',HETIOSSZ='+inttostr(_gyFizetendo)+_sorveg;
      _pcs := _pcs + 'WHERE SORSZAM='+inttostr(_natursss);
      Uparancs(_pcs);

      _mm := 'Update '+_nevtabla+' where sorszam='+inttostr(_natursss);
      writeLn(_iras,_mm);

    end;

   if _vUgyfeltip='J' then
     begin
       _plombaszam := 'JOGI' + inttostr(_jogisss);
       _mbdatasorszam := _mbnevtabla + inttostr(_mbsss);

       _biztabla := 'JOGIBIZ';
       _aktsss := _jogisss;
       BizonylatKonyveles;

       writeLn(_iras,'A JOGI tábla '+ inttostr(_jogisss)+' sorszámon frissiti a ft adatokat');
       _pcs := 'UPDATE JOGI SET FORINTOSSZEG='+ inttostr(_ssumma);
       _pcs := _pcs + ',EVIMAX='+inttostr(_sevimax)+',DATUM='+chr(39)+_gydatum+chr(39);
       _pcs := _pcs + ',TRANZAKCIODB=' + inttostr(_sTranzdb);
       _pcs := _pcs + ',MBDATASORSZAM=' + chr(39)+_mbDataSorszam+chr(39);
       _pcs := _pcs + ',HETIOSSZ='+inttostr(_gyFizetendo)+_sorveg;

       _pcs := _pcs + 'WHERE SORSZAM='+inttostr(_JOGIsss);
       Uparancs(_pcs);
     end;

  _pcs := 'UPDATE ' + _bfnev + ' SET PLOMBASZAM=' + chr(39)+_plombaszam+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_gyBizonylat+chr(39);
  ValutaParancs(_pcs);

  writeLn(_iras,'Végül visszairja a plombaszámot ('+_plombaszam+') a penztár BF-jében');
  writeLn(_iras,'..................');
end;


procedure TForm1.BizonylatKonyveles;

begin
  writeLn(_iras,'BIZONYLATKÖNYVELÉS:');
  writeLn(_iras,'Van-e ' + _biztabla + '-ban ' + _gybizonylat + ' ?');

  _pcs := 'SELECT * FROM ' + _biztabla + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_gyBizonylat+chr(39);

  Ugyfdbase.close;
  Ugyfdbase.databasename := 'c:\receptor\database\ugyfel'+_evtizeds+'.fdb';
  Ugyfdbase.connected := true;
  with Ugyfquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno :=recno;
      Close;
    end;
  Ugyfdbase.close;

  if _recno>0 then
    begin
      writeLn(_iras,'Igen benn van. Mégegyszer nem kell beirni');
      exit;
    end;

  _pcs := 'INSERT INTO ' + _biztabla + ' (SORSZAM,BIZONYLATSZAM,FIZETENDO,';
  _Pcs := _pcs + 'DATUM)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + inttostr(_aktsss) + ',';
  _pcs := _pcs + chr(39) + _gybizonylat + chr(39) + ',';
  _pcs := _pcs + inttostr(_gyFizetendo) + ',';
  _pcs := _pcs + chr(39) + _gyDatum + chr(39) + ')';
  Uparancs(_pcs);

  writeln(_iras,'Sikeresen könyvelte a bizonylatot a '+_biztabla+'-ban');

end;




// =============================================================================
                    procedure TForm1.UParancs(_ukaz: string);
// =============================================================================

begin

  Ugyfdbase.close;
  Ugyfdbase.databasename := 'c:\receptor\database\ugyfel'+_evtizeds+'.fdb';
  Ugyfdbase.connected := true;

  if Ugyftranz.InTransaction then Ugyftranz.commit;
  Ugyftranz.StartTransaction;
  with Ugyfquery do
    begin
      CLose;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Ugyftranz.commit;
  Ugyfdbase.Close
end;

// =============================================================================
                 procedure TForm1.Valutaparancs(_ukaz: string);
// =============================================================================

begin

  if _gypenztar<151 then _vDbasePath := 'c:\receptor\database\v' + inttostr(_gypenztar)+'.fdb'
  else _vDbasePath := 'c:\cartcash\database\v' + inttostr(_gypenztar)+'.fdb';
  Vdbase.close;
  Vdbase.DatabaseName := _vdbasePath;

  Vdbase.connected := true;
  if vtranz.InTransaction then Vtranz.commit;
  Vtranz.StartTransaction;
  with vquery do
    begin
      CLose;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Vtranz.commit;
  Vdbase.Close
end;

// =============================================================================
               function TForm1.DataFromAllUgyfel: boolean;
// =============================================================================

{
  Parameter: _vugyfelszam,_gypenztar

  Ha létezik a penztár mentett ügyféltáblája és ott a megadott
  _vugyfelszam-hoz tartozó rekord meg van, akkor az ott található
  ugyfélhez tartozó összes adatot u-val kezdödõ valtozókba irja
}

begin

  result := False;
  _uTablanev := 'U'+inttostr(_gyPenztar);
  _mm := 'Megpróbálom a beküldött ügyfél adatbázisból kiolvasni az ügyfél adatait';
  writeLn(_iras,_mm);

  AllUgyfDbase.Connected := True;
  AllUgyfTabla.close;
  Allugyftabla.TableName := _utablanev;
  _mm := 'Az átmentett ügyfél tábla neve = '+_uTablanev;
  writeLn(_iras,_mm);

  if not Allugyftabla.Exists then
    begin
      writeln(_iras,'Az átmentett ügyfél táblát nem találom. Nincs még átmentve');
      writeLn(_iras,' ');

      Lbox.Items.Add('Nincs átmentve az ügyféltábla');
      Lbox.Repaint;
      // Nincs átmentve a pénztár ügyfeleinek táblája a szerverre

      Allugyfdbase.close;
      Exit;
    end;

  // A parameter ugyfélszámhoz tartozó rekord szürése:

  _upcs := 'SELECT * FROM ' + _uTablanev + _sorveg;
  _upcs := _upcs + 'WHERE UGYFELSZAM=' + inttostr(_vUgyfelszam);

  _mm := 'Keresem az ügyfél táblában a '+inttostr(_vUgyfelszam)+' ügyfélszámu rekordot';
  writeLn(_iras,_mm);

  with AllUgyfquery do
    begin
      Close;
      sql.clear;
      sql.add(_upcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      writeLn(_iras,'Nincs meg az ugyfél táblában ez az ügyfél ???');
      writeLn(_iras,' ');

      Lbox.Items.add('Nincs a mentett ugyféltáblában az ügyfél');
      Lbox.Repaint;
      // Nincs a megadott ugyfélszámhoz tartozó rekord

      AllUgyfquery.close;
      AllUgyfdbase.close;
      exit;
    end;

  // _u-val kezdödõ változókba olvassa a natur adatokat

  _mm := 'Sikerült megtalálni '+inttostr(_vugyfelszam)+' ügyfélszámû ügyfelet';
  writeLn(_iras,_mm);

  with AllUgyfQuery do
    begin
      _unev       := angolra(FieldByNAme('NEV').asString);
      _uElo       := angolra(FieldByName('ELOZONEV').asString);
      _uAnyja     := angolra(FieldByNAme('ANYJANEVE').asString);
      _uLany      := angolra(FieldByName('LEANYKORI').asString);
      _uSzulhely  := angolra(FieldByNAme('SZULETESIHELY').asString);
      _uSzulido   := tomorito(FieldByNAme('SZULETESIIDO').asString);
      _uallamp    := angolra(FieldByNAme('ALLAMPOLGAR').asString);
      _uLakcim    := angolra(FieldByName('LAKCIM').asString);
      _uOkmtip    := FieldByName('OKMANYTIPUS').asString;
      _uAzonosito := angolra(FieldByname('AZONOSITO').asString);
      _uTarthely  := angolra(FieldByNAme('TARTOZKODASIHELY').asString);
      _uLcimCard  := angolra(FieldByName('LAKCIMKARTYA').asString);
      _uKulf      := FieldByName('KULFOLDI').asInteger;
      _uKOzszer   := FieldByNAme('KOZSZEREPLO').asInteger;
      _uIrszam    := FieldByNAme('IRSZAM').asString;
      _uVaros     := angolra(FieldByNAme('VAROS').asString);
      _uUtca      := angolra(FieldByNAme('UTCA').asString);
      _uiso       := trim(FieldByName('ISO').asString);
      Close;
    end;
  AllUgyfdbase.close;

  if length(_uIso)<>2 then _uIso := 'HU';
  _uOkmTip := kokm(_uOkmTip);

  writeLn(_iras,'Az ügyfél adatai: '+_unev+'-'+_uanyja+'-'+_uszulhely+'-'+_uszulido);
  writeLn(_iras,_uOkmTip+'-'+_uazonosito+'-'+_uLakcim);
  writeLn(_iras,_uIrszam+'-'+_uVaros+'-'+_uUtca+'---'+_uIso);
  writeLn(_iras,'-----');

  result := True;
end;


// =============================================================================
               function TForm1.MbUgyfelKereses: integer;
// =============================================================================

var _pont: byte;
    _nss: integer;

begin

  // Az ugyfelnev kezdöbetüje alapján meghatározza a NÉVTÁBLA-t

  result := 0;

  _mbkBetu := leftstr(_mbnev,1);
  _mbnevtabla  := _mbkBetu + 'NEV';

  writeLn(_iras,'Keresi a megbizottat (' + _mbnev + ') ' + _mbnevtabla + '-ban');

  // A szerveren megnyitja a névnek megfelelö Nevtablat
  // ée keresi az Ugyfelnev-et:

  _pcs := 'SELECT * FROM ' + _mbnevtabla + _sorveg;
  _pcs := _pcs + 'WHERE NEV=' + chr(39) + _mbnev + chr(39);

  Ugyfdbase.close;
  Ugyfdbase.databasename := 'c:\receptor\database\ugyfel'+_evtizeds+'.fdb';
  Ugyfdbase.connected := true;

  with UgyfQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := Recno;
    end;

  // Ha nem találja az ügyfél nevét a szerveren, akkor ez egy új ügyfél lesz

  if _recno=0 then
    begin
      writeln(_iras,_mbnev+' nemn regisztrált ügyfél');
      Lbox.Items.Add('Nem regisztrált ügyfél');
      Lbox.Repaint;

      UgyfQuery.close;
      Ugyfdbase.close;
      exit;
    end;

  // Az ügyfélnek megfelelö nevre van leszürve az adatbázis:

  _megvan := False; // default = nincs meg

  _P := 0;
  while not UgyfQuery.eof do
    begin
      INC(_P);

      // Ha a következö 3 adatból 2 egyezik, akkor azonositva van az ügyfel:

      _rAnyjaneve     := trim(UgyfQuery.fieldByNAme('ANYJANEVE').asString);
      _rSzuletesihely := trim(UgyfQuery.FieldByNAme('SZULETESIHELY').asString);
      _rSzuletesiido  := trim(UgyfQuery.FieldByNAme('SZULETESIIDO').asString);

      writeLn(_iras,inttostr(_p)+'. '+_rAnyjaneve+'-'+_rszuletesihely+'-'+_rszuletesiido);

      _pont := 0;
      if _ranyjaneve=_mbanyja then _pont := 1;
      if _rszuletesiido=_mbszulido then inc(_pont);
      if _rszuletesihely=_mbszulhely then inc(_pont);

      writeln(_iras,inttostr(_pont)+'-ban egyezés');

      if _pont>1 then
        begin
          // AZ ügyfél egyeztetve van, befejezi a keresést:
          _megvan := True;
          break;
        end;

      // Tovább keres az adatbázisban:
      UgyfQuery.next;
    end;

  // Mégsem találta meg az egyezö adatu személyt:
  if not _megvan then
    begin
      writeln(_iras,'Tehát nem egyezik elég adat');
      lbox.Items.Add('Ügyfél többi adata nem stimmel');
      Lbox.Repaint;

      UgyfQuery.close;
      Ugyfdbase.close;
      exit;
    end;

  // Megtalálta a szerveren az aktuális ügyfelet:

  _nss := UgyfQuery.FieldByName('SORSZAM').ASiNTEGER;;
  writeLn(_iras,'Megvan a megbizott. Sorszáma: '+inttostr(_nss));

   UgyfQuery.close;
  Ugyfdbase.close;

  result := _nss;

end;


// =============================================================================
               function TForm1.jogiUgyfelKereses: integer;
// =============================================================================

var _jT,_rTelep: string;
    _jTlen: byte;
    _jss : integer;

begin
  // A jogi személy keresi a szerver UGYFELYY táblából Jogiugyfelnev alapján:

  result    := 0;   // default = nincs meg

  _nevtabla := 'JOGI';
  _biztabla := 'JOGIBIZ';

  _aktJnev := _jNev;

  writeLn(_iras,'Keresi '+_aktjnev+'-t a JOGI táblában');

  // A Jogiszemélynév elsõ 15 karaktere alapján keresem:

  if length(_aktjnev)>15 then _aktjnev := leftstr(_jnev,15);

  _pcs := 'SELECT * FROM JOGI' +  _sorveg;
  _pcs := _pcs + 'WHERE JOGISZEMELYNEV LIKE ' + chr(39) + _aktJnev +'%'+ chr(39);

  UgyfDbase.connected := true;
  with UgyfQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := Recno;
    end;

  // Ilyen nevü jogiszemély nincs regisztrálva a szerveren

  if _recno=0 then
    begin
      writeln(_iras,_aktjnev+' nevü jogiszemély nincs nyilvántartva');
      lbox.Items.Add('Ilyen nevü jogiszemély nincs a szerveren');
      Lbox.Repaint;

      UgyfQuery.close;
      Ugyfdbase.close;
      exit;
    end;

  writeln(_iras,'Talált '+ _aktjnev + ' nevü jogi személyt');
  _megvan := False; // DEFAULT NINCS MEG

  _jT    := _jTelep;
  _jTLen := length(_jT);

  if _jtlen>15 then _jT := leftstr(_jt,15);
  _jTlen := length(_jT);

  while not UgyfQuery.eof do
    begin
      _rTelep := trim(Ugyfquery.FieldByNAme('TELEPHELYCIM').asString);
      _rtelep := trim(leftstr(_rTelep,_jtlen));
      writeLn(_iras,'A telephely egyeztetés -'+_rtelep+'='+_jt);

      if _rTelep=_Jt then
        begin
          writeLn(_iras,'Egyezik, tehát megvan');
          _megvan := True;
          break;
        end;
      UgyfQuery.next;
    end;

  if not _megvan then
    begin
      writeLn(_iras,'Mégsincs regisztrálva ez a jogi személy');
      Lbox.Items.Add('Nincs meg a jogi személy a szerveren');
      Lbox.Repaint;

      UgyfQuery.close;
      Ugyfdbase.close;
      exit;
    end;

  // Az aktuális jogiszemély már regisztrálva van az adatbázisban

  _jss       := UgyfQuery.fieldByName('SORSZAM').asInteger;
  _rtranzdb  := UgyfQuery.FieldByNAme('TRANZAKCIODB').asInteger;
  _rsumma    := UgyfQuery.FieldByNAme('FORINTOSSZEG').asInteger;
  _rEvimax   := UgyfQuery.FieldByName('EVIMAX').asInteger;
  _rHetiossz := UgyfQuery.FieldByName('HETIOSSZ').asInteger;
  _rTiltva   := UgyfQuery.Fieldbyname('TILTVA').asInteger;

  UgyfQuery.close;
  UgyfDbase.close;

  writeln(_iras,'Az ügyfél '+inttostr(_jss)+' sorszámon van regisztrálva');
  writeLn(_iras,'Tiltás = '+ inttostr(_rTiltva));

  if _rtiltva>0 then _jss := -1;

  result := _jss;
end;



// =============================================================================
               procedure Tform1.UjugyfelFelvetele;
// =============================================================================

begin

  _ukbetu    := leftstr(_uNev,1);
  _nevtabla := _ukBetu+'NEV';
  _lastmezo := _ukBetu+'LAST';
  _biztabla := _ukbetu+'BIZ';

  writeln(_iras,'Regisztrálja '+ _unev +' ügyfelet, mint új ügyfél');

  Ugyfdbase.close;
  Ugyfdbase.databasename := 'c:\receptor\database\ugyfel'+_evtizeds+'.fdb';
  Ugyfdbase.connected := true;
  Ugyftabla.close;
  writeLn(_iras,'Az ügyfelet regisztrálja az UGYFEL'+_evtizeds+'.FDB adatbázisba');

  if ugyfTranz.InTransaction then ugyftranz.commit;
  ugyftranz.StartTransaction;

  ugyftabla.TableName := 'LASTNUMS';
  UgyfTabla.Open;
  _natursss := Ugyftabla.fieldByNAme(_LASTMEZO).asinteger;
  inc(_natursss);

  writeLn(_iras,'Kiolvassa '+_lastmezo+' mezõ értékét és eggyel növeli: '+inttostr(_natursss));
  writeLn(_iras,'Az új ügyfél sorszáma: '+inttostr(_natursss));

  ugyftabla.edit;
  Ugyftabla.FieldByName(_lastmezo).asInteger := _natursss;
  Ugyftabla.Post;

  Ugyftranz.commit;
  Ugyfdbase.close;
  Ugyftabla.close;

  // --------------------------------------------------------------

  _pcs := 'INSERT INTO ' + _nevtabla + ' (SORSZAM,NEV,ELOZONEV,ANYJANEVE,LEANYKORI,';
  _pcs := _pcs + 'SZULETESIHELY,SZULETESIIDO,ALLAMPOLGAR,LAKCIM,OKMANYTIP,';
  _pcs := _pcs + 'AZONOSITO,TARTOZKODASIHELY,LAKCIMKARTYA,KULFOLDI,TRANZAKCIODB,';
  _pcs := _pcs + 'FORINTOSSZEG,EVIMAX,DATUM,HETIOSSZ,TILTVA,ISO)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_natursss) + ',';

  _pcs := _pcs + chr(39) + _unev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _uElo + chr(39) + ',';
  _pcs := _pcs + chr(39) + _uAnyja + chr(39) + ',';
  _pcs := _pcs + chr(39) + _uLany + chr(39) + ',';
  _pcs := _pcs + chr(39) + _uSzulhely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _uSzulido + chr(39) + ',';
  _pcs := _pcs + chr(39) + _uAllamp + chr(39) + ',';
  _pcs := _pcs + chr(39) + _uLakcim + chr(39) + ',';
  _pcs := _pcs + chr(39) + _uOkmTip + chr(39) + ',';
  _pcs := _pcs + chr(39) + _uAzonosito + chr(39) + ',';
  _pcs := _pcs + chr(39) + _uTarthely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _uLcimcard + chr(39) + ',';
  _pcs := _pcs + inttostr(_uKulf) + ',';
  _pcs := _pcs + '0,';
  _pcs := _pcs + '0,';
  _pcs := _pcs + '0,';
  _pcs := _pcs + chr(39) + chr(39) + ',';
  _pcs := _pcs + '0,';
  _pcs := _pcs + '0,';
  _pcs := _pcs + chr(39) + _uIso + chr(39) + ')';

  Uparancs(_pcs);
  lbox.items.add('Felvettem egy új ügyfelet');
  Lbox.Repaint;

  writeLn(_iras,'Felvettük ' + _unev + '-t '+inttostr(_natursss)+' sorszáman '+_nevtabla+' táblázatba');

  _rTranzdb   := 0;
  _rEvimax    := 0;
  _rSumma     := 0;
  _rHetiOssz  := 0;
end;

// =============================================================================
               procedure Tform1.UjMegbizottFelvetele;
// =============================================================================

begin

  _mbkbetu    := leftstr(_mbNev,1);

  _mbnevtabla := _mbkBetu+'NEV';
  _lastmezo   := _mbkBetu+'LAST';

  Ugyfdbase.close;
  Ugyfdbase.databasename := 'c:\receptor\database\ugyfel'+_evtizeds+'.fdb';
  Ugyfdbase.connected := true;
  Ugyftabla.close;

  writeLn(_iras,'A megbizott (' +_mbNev + ') még nincs regisztrálva.');
  writeln(_iras,'Most felveszi a megbizott adatait az adatbázisba');

  if ugyfTranz.InTransaction then ugyftranz.commit;
  ugyftranz.StartTransaction;
  ugyftabla.TableName := 'LASTNUMS';
  Ugyftabla.Open;
  _mbsss := Ugyftabla.fieldByNAme(_lastmezo).asinteger;
  inc(_mbsss);

  writeLn(_iras,'A megbizott sorszama '+_lastmezo+' mezõ alapján: '+inttostr(_mbsss));

  ugyftabla.edit;
  Ugyftabla.FieldByName(_lastmezo).asInteger := _mbsss;
  Ugyftabla.Post;

  Ugyftranz.commit;
  Ugyfdbase.close;
  Ugyftabla.close;

  // --------------------------------------------------------------

  writeLn(_iras,'Most a(z) '+_nevtabla+' táblába irja a megbizott adatait');

  _pcs := 'INSERT INTO ' + _nevtabla + ' (SORSZAM,NEV,ELOZONEV,ANYJANEVE,LEANYKORI,';
  _pcs := _pcs + 'SZULETESIHELY,SZULETESIIDO,ALLAMPOLGAR,LAKCIM,OKMANYTIP,';
  _pcs := _pcs + 'AZONOSITO,TARTOZKODASIHELY,LAKCIMKARTYA,KULFOLDI,TRANZAKCIODB,';
  _pcs := _pcs + 'FORINTOSSZEG,EVIMAX,DATUM,HETIOSSZ,TILTVA,ISO)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_mbsss) + ',';

  _pcs := _pcs + chr(39) + _mbnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbElo + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbAnyja + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbLany + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbSzulhely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbSzulido + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbAllamp + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbLakcim + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbOkmTip + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbAzonosito + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbTarthely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbLcimcard + chr(39) + ',';
  _pcs := _pcs + inttostr(_mbKulf) + ',';
  _pcs := _pcs + '0,';
  _pcs := _pcs + '0,';
  _pcs := _pcs + '0,';
  _pcs := _pcs + chr(39) + chr(39) + ',';
  _pcs := _pcs + '0,';
  _pcs := _pcs + '0,';
  _pcs := _pcs + chr(39) + _mbIso + chr(39) + ')';

  Uparancs(_pcs);
  writeLn(_iras,_mbnev+' adatait rögzitette '+_nevtabla + ' táblába '+inttostr(_mbsss)+' sorszámot');

  Lbox.Items.Add('Felvettem egy új megbizott személyt');
  Lbox.Repaint;
end;

// =============================================================================
               procedure Tform1.UjJogiFelvetele;
// =============================================================================

begin

  _nevtabla := 'JOGI';
  _lastmezo := 'JOGILAST';
  _biztabla := 'JOGIBIZ';

  Ugyfdbase.close;
  Ugyfdbase.databasename := 'c:\receptor\database\ugyfel'+_evtizeds+'.fdb';
  Ugyfdbase.connected := true;
  Ugyftabla.close;

  if ugyfTranz.InTransaction then ugyftranz.commit;
  ugyftranz.StartTransaction;
  ugyftabla.TableName := 'LASTNUMS';
  ugyftabla.Open;
  _Jogisss := Ugyftabla.fieldByNAme(_lastmezo).asinteger;
  inc(_Jogisss);

  writeLn(_iras,'Új jogi személyt vesz fel '+inttostr(_jogisss)+' sorszámon');

  ugyftabla.edit;
  Ugyftabla.FieldByName(_lastmezo).asInteger := _Jogisss;
  Ugyftabla.Post;

  Ugyftranz.commit;
  Ugyfdbase.close;
  Ugyftabla.close;

  // --------------------------------------------------------------

  _pcs := 'INSERT INTO JOGI(SORSZAM,JOGISZEMELYNEV,TELEPHELYCIM,OKIRATSZAM,';
  _pcs := _pcs + 'FOTEVEKENYSEG,MEGBIZOTTNEVE,KEPVISELONEV,MEGBIZOTTBEOSZTASA,';
  _pcs := _pcs + 'KEPVISBEO,TRANZAKCIODB,';
  _pcs := _pcs + 'FORINTOSSZEG,EVIMAX,DATUM,HETIOSSZ,TILTVA,ISO)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_Jogisss) + ',';

  _pcs := _pcs + chr(39) + _Jnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _jTelep + chr(39) + ',';
  _pcs := _pcs + chr(39) + _jOkirat + chr(39) + ',';
  _pcs := _pcs + chr(39) + _jFotev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _jMbNev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _jKepvis + chr(39) + ',';
  _pcs := _pcs + chr(39) + _jMbbeo + chr(39) + ',';
  _pcs := _pcs + chr(39) + _jkepvisbeo + chr(39) + ',';
  _pcs := _pcs + '0,';
  _pcs := _pcs + '0,';
  _pcs := _pcs + '0,';
  _pcs := _pcs + chr(39)+chr(39)+',';
  _pcs := _pcs + '0,0,';

  _pcs := _pcs + chr(39) + _jIso + chr(39) + ')';

  Uparancs(_pcs);

  Lbox.items.Add('Felvettem egy új jogi személyt');
  Lbox.Repaint;

  _rTranzdb   := 0;
  _rEvimax    := 0;
  _rSumma     := 0;
  _rHetiOssz  := 0;
end;



// =============================================================================
                 function TForm1.Angolra(_huName: string): string;
// =============================================================================

var _whn,_z,_asc: byte;

begin
  result  := '';

  _huname := uppercase(trim(_huname));
  _whn    := length(_huname);

  if _whn=0 then exit;

  _z := 1;
  while _z<=_whn do
    begin
      _asc := ord(_huname[_z]);
      _asc := HutoGb(_asc);

      result := result + chr(_asc);
      inc(_z);
    end;
  result := DoubleKill(result);
end;

// =============================================================================
                   function TForm1.DoubleKill(_s: string): string;
// =============================================================================

var _w,_asc,_utasc,_y: byte;

begin
  result := '';

  _s := trim(_s);
  _w := length(_s);

  // Ha üres string -> nincs mit tömöriteni
  if _w=0 then exit;

  _y     := 1;
  _utasc := 0;       // default

  while _y<=_w do
    begin
      _asc := ord(_s[_y]);
      if (_asc=32) and (_utasc=32) then
        begin
          inc(_y);
          continue;
        end;

      if _asc=32 then
        begin
          result := result + ' ';
          _utasc := 32;
          inc(_y);
          Continue;
        end;

      if (_asc<48) or (_asc>90) then
        begin
          inc(_y);
          Continue;
        end;

      if (_asc>57) and (_asc<65) then
        begin
          inc(_y);
          Continue;
        end;

      result := Result + chr(_asc);
      _utasc := _asc;
      inc(_y);
    end;
end;

// =============================================================================
                   function TForm1.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;

end;


// =============================================================================
                   function TForm1.HutoGb(_kod: byte): byte;
// =============================================================================

var _r: byte;

begin
  _r := _kod;
  case _kod of
    186: _r := 69;  // E
    187: _r := 79;  // O
    193: _r := 65;  // A
    201: _r := 69;  // E
    211: _r := 79;  // O
    213: _r := 79;  // O
    214: _r := 79;  // O
    218: _r := 85;  // U
    219: _r := 85;  // U
    220: _r := 85;  // U
    222: _r := 65;  // A
    226: _r := 73;  // I
    205: _r := 73;  // I

    225: _r := 97;  // a
    233: _r := 101; // e
    237: _r := 105; // i
    243: _r := 111; // o
    246: _r := 111; // o
    245: _r := 111; // o
    250: _r := 117; // u
    252: _r := 117; // u
    251: _r := 117; // u
  end;
  result := _r;
end;

// =============================================================================
               function TForm1.Tomorito(_ts: string): string;
// =============================================================================

var _ws,_y,_aktasc: byte;

begin
  _ts := trim(_ts);
  result := '';

  if _ts='' then exit;

  _ts := uppercase(_ts);
  _ws := length(_ts);
  _y := 1;

  while _y<=_ws do
    begin
      _aktasc := ord(_ts[_y]);
      if (_aktasc>47) and (_aktasc<58) then result := result + chr(_aktasc);
      if (_aktasc>64) and (_aktasc<91) then result := result + chr(_aktasc);
      inc(_y);
    end;
end;

// =============================================================================
            procedure TForm1.KILEPOGOMBClick(Sender: TObject);
// =============================================================================

begin
  CloseFile(_iras);
  Application.Terminate;
end;

function TForm1.Kokm(_s:string): string;

var _kbs: string;

begin
  _kbs := uppercase(leftstr(_s,1));
  result := 'SZIG';
  if _kbs='U' then result := 'UTLEVEL';
  if _kbs='J' then result := 'JOGOSITVANY';
END;



procedure TForm1.tovabbgombClick(Sender: TObject);
begin
  Infobox.Visible := false;
  infobox.Left := -1144;
  tovabbgomb.Visible := False;
  Activecontrol := Startgomb;
end;

end.
