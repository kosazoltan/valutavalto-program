unit Unit29;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBCustomDataSet, IBTable, ComCtrls, StdCtrls,
  Buttons, ExtCtrls, unit1, strUtils, IBQuery;

type
  TADATLEGYUJTES = class(TForm)
    CSIK: TProgressBar;
    INDITO: TTimer;
    RECEPTORDBASE: TIBDatabase;
    RECEPTORTRANZ: TIBTransaction;
    Label1: TLabel;
    NAGYCSIK: TProgressBar;
    UZENOPANEL: TPanel;
    ALCIMPANEL: TPanel;
    BLOKKTRANZ: TIBTransaction;
    BLOKKDBASE: TIBDatabase;
    BLOKKTABLA: TIBTable;
    BLOKKQUERY: TIBQuery;
    RECEPTORQUERY: TIBQuery;
    ELSZAMQUERY: TIBQuery;
    NARFDBASE: TIBDatabase;
    NARFTRANZ: TIBTransaction;
    RECEPTORTABLA: TIBTable;
    Shape1: TShape;

    procedure FormActivate(Sender: TObject);
    procedure INDITOTimer(Sender: TObject);
    procedure ForgalomGyujtes;
    procedure CimletGyujtes;
    procedure WuniForgalomGyujtes;
    procedure BankGyujtes;
    procedure Cimletosszesites;
    procedure ForgalomOsszesites;
    procedure WuniOsszesites;

    procedure InterPtControl;
    procedure TRBControl;
    procedure ForgalomRutin;
    procedure SendingRutin;
    procedure TRBGyujtes;
    procedure WuniNullazas;
    procedure GetWuniNyitasZaras;

    procedure StornoRegisztracio;
    procedure TablaUrites(_tNev: string);
    procedure WuniAfaBerogzites;
    procedure MetroForgalomGyujtes;
    procedure TescoForgalomGyujtes;
   
    function GetElszamar(_xdat: string; _xnem: string): integer;
    function MulthaviUtolsoCimNap(): string;
    function BetubolInteger(_szo: string): integer;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ADATLEGYUJTES: TADATLEGYUJTES;

  _narfTablanev,_fejTablanev,_tetTablaNev,_cimtarTablanev,_wzarTablanev: string;
  _wuniTablaNev,_metroTablaNev,_TescoTablanev: string;

  _blokknum,_bnum,_coin,_kdatum,_sorszam,_irany,_stornoindok: string;
  _gycimlet,_gyforgalom,_bjegy,_ellatmany,_kifizetve: integer;

  _vett,_eladott,_vettertek,_eladottertek: integer;
  _svett,_seladott,_svettertek,_seladottertek: integer;

  // -----------------------------------------------------------------

  _UsdNyito,_HufNyito,_Afanyito,_Metronyito,_TescoNyito: integer;
  _UsdGbe,_HufGbe,_AfaGBe,_MetroGBe,_TescoGBe: integer;
  _UsdGKi,_HufGKi,_AfaGKi,_MetroGKi,_TescoGKi: integer;
  _UsdPbe,_HufPbe,_AfaPBe,_MetroPBe,_TescoPBe: integer;
  _UsdPKi,_HufPKi,_AfaPKi,_MetroPKi,_TescoPKi: integer;
  _UsdUbe,_HufUbe: integer;
  _UsdUKi,_HufUKi,_AfaUKi,_MetroUKi,_TescoUKi: integer;
  _UsdZaro,_HufZaro,_AfaZaro,_MetroZaro,_TescoZaro: integer;

  // ----------------------------------------------------------------

  _ignap,_foegyseg,_penztarszam,_osszbjegy,_valss: integer;
  _kuldott,_fogadott,_bj: integer;
  _vdatum,_adatum: string;
  _stBiz,_atipus: string;
  _scim: array[1..14] of integer;

  _uny,_uz,_hny,_hz,_ubg,_ubp,_ubu,_ukg,_ukp,_uku,_any,_az: array[0..27] of integer;
  _hbg,_hbp,_hbu,_hkg,_hkp,_hku,_abg,_abp,_akg,_akp,_aku: array[0..27] of integer;

  _kuny,_kuz,_khny,_khz,_kubg,_kubp,_kubu,_kukg,_kukp,_kuku,_kany,_kaz: array[0..2] of integer;
  _khbg,_khbp,_khbu,_khkg,_khkp,_khku,_kabg,_kabp,_kakg,_kakp,_kaku: array[0..2] of integer;

  _kkeszlet,_kertek,_skkeszlet,_skkertek: array[0..9,0..27] of integer;
  _kcimsor,_skcimsor: array[0..9,0..27] of string;
  _skeszlet,_skertek: array[0..27] of integer;
  _scimsor: array[0..27] of string;

  _kvett,_keladott,_kvettertek,_keladottertek: array[0..9,0..27] of integer;
  _kkvett,_kkeladott,_kkvettertek,_kkeladottertek: array[0..9,0..27] of integer;
  _kelszarf: array[0..27] of integer;
  _sumvett,_sumeladott,_sumvettertek,_sumeladottertek: array[0..27] of integer;

implementation

uses Unit16;

{$R *.dfm}


// ==============================================================
      procedure TADATLEGYUJTES.FormActivate(Sender: TObject);
// ==============================================================

var _elohonap,_eloev: integer;


begin
  Top    := _top + 290;
  Left   := _left + 270;
  Height := 210;

  _gyforgalom := 0;
  _gycimlet   := 0;

  _farok    := midstr(_tolstring,3,2)+midstr(_tolstring,6,2);
  _eloev    := strtoint(leftstr(_farok,2));
  _elohonap := strtoint(midstr(_farok,3,2));

  dec(_EloHonap);

  if _elohonap=0 then
    begin
      dec(_eloev);
      _elohonap := 12;
    end;

  _elofarok := Form1.nulele(_eloev)+form1.nulele(_elohonap);
  _voltadat := False;
  _ignap    := strtoint(midstr(_igstring,9,2));

  if (_tolstring=_igstring) then
    begin
      _ezegynap     := true;
      _idoszakLabel := _tolstring;
    end else
    begin
      _ezegynap := False;
      _idoszakLabel := _tolstring + ' - '+_igstring+' között';
    end;

  Indito.enabled := True;
end;

// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
// =============================================================================
            procedure TADATLEGYUJTES.INDITOTimer(Sender: TObject);
// =============================================================================

var _vanmar: boolean;

begin
  Indito.Enabled := False;

  NagyCsik.Max := _irodaDarab+2;
  NagyCsik.Position := 0;
  NagyCsik.Repaint;

  // ----------- A GYÜJTÖTÁBLÁK KIÜRITÉSE ------------------------------------

  TablaUrites('FORGALOMGYUJTO');
  TablaUrites('CIMLETGYUJTO');
  TablaUrites('WUNIGYUJTO');
  TablaUrites('PENZTARKOZOTT');
  TablaUrites('TRBGYUJTO');
  TablaUrites('SUMBANKFORGALOM');
  TablaUrites('STORNOFEJ');
  TablaUrites('STORNOTETEL');
  TablaUrites('SUMCIMLET');
  TablaUrites('SUMUGYFELFORGALOM');
  TablaUrites('SUMWUNI');

  // ---------------------------------------------------------------------------

  _fejtablanev    := 'BF'+_farok;
  _tetTablaNev    := 'BT'+_farok;
  _cimtarTablanev := 'CIMT'+_farok;
  _NarfTablaNev   := 'NARF'+ _farok;
  _wzarTablanev   := 'WZAR'+_farok;
  _wuniTablaNev   := 'WUNI' + _farok;
  _metroTablaNev  := 'WAFA' + _farok;

// ========================  IRODÁK CIKLUSA ===============

  // A QQ ciklusváltozó végigmegy az összes irodán:

  ReceptorDbase.Close;
  ReceptorDbase.connected := true;
  if ReceptorTranz.InTransaction then ReceptorTranz.Commit;
  ReceptorTranz.StartTransaction;

  // -------------------- AZ ÖSSZES IRODA CIKLUSFEJE ---------------------------

  _QQ := 0;
  while _QQ<_irodaDarab do
    begin
       NagyCsik.Position :=  _qq;
       AdatLegyujtes.Repaint;  // a FORM ÚJRAFESTÉSE

       // ------------------------------------------------------------

      _aktpenzTar  := _irodaszam[_qq];
      _aktertekTar := _korzet[_aktpenztar];
      _aktcegbetu  := _cegbetutomb[_aktPenztar];
      _aktfdbPath  := 'c:\receptor\database\v'+inttostr(_aktpenztar)+'.FDB';
      if not Fileexists(_aktfdbPath) then
        begin
          inc(_qq);
          Continue;
        end;  


      UzenoPanel.Caption := inttostr(_aktPenztar)+' - '+_irodanev[_aktpenztar];
      UzenoPanel.Repaint;

      // -----------------------------------------------------------------------
      // A napi árfolyam tábla elõkészitése: az elszámoló árak kiolvasása miatt

      NarfDbase.Close;
      NarfDbase.DatabaseName := _aktfdbPath;
      NarfDbase.Connected    := true;

      Blokktabla.Close;
      BlokkDbase.Close;
      BlokkDbase.DatabaseName := _aktfdbPath;
      BlokkDbase.Connected    := True;

      BlokkTabla.TableName := _NarfTablaNev;
      _vanmar := Blokktabla.exists;
      if _vanmar=False then IrodaTmk.MakeNarf(_aktfdbPath,_narfTablaNev);

      with BlokkDbase do
        begin
          Close;
          DatabaseName := _aktFdbPath;
          Connected := true;
        end;

      BlokkTabla.Close;
      BlokkTabla.TableName := _fejtablaNev;

      // HA VAN FEJTÁBLA, AKKOR FORGALOM LEGYÜJTÉSE !!!!!!!!!!!!!!
      if BlokkTabla.Exists then ForgalomGyujtes;

      BlokkDbase.Connected := true;
      Blokktabla.close;
      BlokkTabla.TableName := _cimtarTablaNev;

      // Ha van havi cimletezés, akkor CimletGyüjtés !!!!!!!!!
      if BlokkTabla.exists then CimletGyujtes;

      // -----------------------------------------------------------------------
      //  wuni és wafa adatok lenullázása:

      WuniNullazas;

      BlokkDbase.Connected := true;
      Blokktabla.close;
      BlokkTabla.TableName := _wzarTablaNev;

      // -----------------------------------------------------------------------
      // Ha van havi western-záró, akkor Wuni-wafa nyitó-zaró

      if Blokktabla.Exists then GetWuniNyitasZaras;

      // -----------------------------------------------------------------------
      // Ha van Wuni (és nem üres), akkor wuniforgalomgyüjtés

      BlokkDbase.Connected := true;
      Blokktabla.close;

      BlokkTabla.TableName := _wuniTablaNev;
      if Blokktabla.Exists then WuniForgalomGyujtes;

      // -----------------------------------------------------------------------
      // HA van Wafa ( és nem üres) , akkor  wafaforgalomgyüjtés

      BlokkDbase.Connected := true;
      BlokkTabla.close;
      BlokkTabla.TableName := _metroTablaNev;
      if BlokkTabla.Exists then MetroForgalomGyujtes;

     // -----------------------------------------------------------------------
     // Ha van Tesco (és nem üres), akkor Tescoforgalomgyujtes

      _tescoTablaNev := 'TESC' + _farok;

      BlokkDbase.Connected := true;
      BlokkTabla.close;
      BlokkTabla.TableName := _tescoTablaNev;
      if BlokkTabla.Exists then TescoForgalomGyujtes;

     // ------------------------------------------------------------------------

      WuniAfaBerogzites;

     // ------------------------------------------------------------------------
     // Következö Iroda:
      inc(_qq);
    end;

  AdatLegyujtes.Repaint;
  ReceptorTranz.Commit;

// =============================================================================

  // Ha voltak egyáltalán adatok, akkor összesiteni kell öket:

  Nagycsik.Position := 150;

  if _voltadat then
    begin
      AlcimPanel.Caption := '';
      AlcimPanel.Repaint;

      UzenoPanel.Caption := 'CIMLET ÖSSZESITÉS';
      UzenoPanel.Repaint;
      CImletOsszesites;
      nagyCsik.Position := 152;

      UzenoPanel.Caption := 'FORGALOM ÖSSZESITÉS';
      UzenoPanel.Repaint;
      ForgalomOsszesites;
      nagyCsik.Position := 154;

      UzenoPanel.Caption := 'WESTERN UNION ÖSSZESITÉS';
      UzenoPanel.Repaint;
      WuniOsszesites;
      nagyCsik.Position := 156;

      UzenoPanel.Caption := 'PÉNZTÁRAK KÖZÖTTI FORGALOM';
      UzenoPanel.Repaint;
      InterPtControl;
      nagyCsik.Position := 160;

      UzenoPanel.Caption := 'TRB KONTROL';
      UzenoPanel.Repaint;
      TRBControl;
      nagyCsik.Position := 162;
      ModalResult := 1;
    end else ModalResult := 2;

end;


// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
                 procedure  TadatLegyujtes.ForgalomGyujtes;
// =============================================================================

// A blokkfej- és tétel alapján forgalom,ptközött,trb és banki gyüjtést végez

begin

  AlcimPanel.Caption := 'FORGALOM GYÜJTÉSE';
  AlcimPanel.Repaint;

  _pcs := 'SELECT FEJ.*, TET.*' + _sorveg;
  _pcs := _pcs +'FROM '+_fejtablanev+' FEJ JOIN '+_tettablanev+' TET'+_sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM'+_sorveg;
  if _ezegynap then
      _pcs := _pcs + 'WHERE FEJ.DATUM=' + chr(39) + _tolstring + chr(39)
  else
     _pcs := _pcs + 'WHERE FEJ.DATUM BETWEEN '+chr(39)+_tolstring+chr(39)+' AND '+chr(39)+_igstring+chr(39);

  with BlokkQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
    end;
  BlokkQuery.Last;
  _cc := Blokkquery.RecNo;

  // Az összes szürt blokkon végig kell menni:
  Csik.Max := _cc;

  _cc := 0;
  BlokkQuery.First;
   while not BlokkQuery.eof do
     begin

        Csik.Position := _cc;
        inc(_cc);

       // A blokkfej 5 fontos adata:

       with BlokkQuery do
         begin
           _storno      := FieldByName('STORNO').ASiNTEGER;
           _blokknum    := FieldByName('BIZONYLATSZAM').asString;
           _datum       := FieldByName('DATUM').asstring;
           _ido         := FieldByname('IDO').asstring;
           _atipus      := FieldByName('TIPUS').asString;
           _trbptars    := FieldByName('TRBPENZTAR').asString;
           _penztar     := FieldByName('PENZTAR').asString;
           _prosnev     := FieldByName('PENZTAROSNEV').asstring;
           _stbiz       := FieldByname('STORNOBIZONYLAT').asString;
           _valutanem   := FieldByName('VALUTANEM').asString;
           _bankjegy    := FieldByNAme('BANKJEGY').asInteger;
           _ertek       := FieldByNAME('FORINTERTEK').asInteger;
           _elojel      := FieldByName('ELOJEL').asString;
           _stornoIndok := FieldByName('SZALLITONEV').AsString;
         end;

        _valss := Form1.Dnemscan(_valutanem);
        if _valss<0 then
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

       _tipus := _atipus;
       _voltadat := True;

   // Az elszámolási árfolyamot a Napi árfolyamból veszi:

       _elszamolasiarfolyam := GetElszamar(_datum,_valutanem);

       if (_tipus='V') or (_tipus='E') then  ForgalomRutin else SendingRutin;
       BlokkQuery.Next;
     end;
   BlokkQuery.close;
end;


// =============================================================================
                      procedure TadatLegyujtes.ForgalomRutin;
// =============================================================================
// ---------------------- A FORGALOMGYÜJTÉS subrutinja -------------------------

//       IDE KERÜLNEK A VÉTEL ÉS ELADÁS KONVERZIÓ BIZONYLATOK TÉTELEI
// A forgalomgyüjtöbe gyüjti a VETT,ELADOTT,VETTERTEK ÉS ELADOTTERTEK mezöket

var _ee: real;
    _ftMezo : string;

begin

  // A forint nem forgalom :

  if _valutanem= 'HUF' then exit;

  // A gyüjtött mezök kijelölése:

  if _tipus ='V' then _mezo := 'VETT' else _mezo := 'ELADOTT';
  _ftMezo := _mezo + 'ERTEK';    // VETTERTEK vagy ELADOTTERTEK

  // ennek az irodának van már ilyen valutája gyüjtve?

  _pcs := 'Select * From Forgalomgyujto'+_sorveg;
  _pcs := _pcs + 'where Irodaszam='+inttostr(_aktpenztar)+' and Valutanem='+chr(39)+_valutanem+chr(39);

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
    end;

  if ReceptorQuery.recno=0 then  // Ez új bejegyzés
    begin
      inc(_gyforgalom);
      _pcs := 'INSERT INTO FORGALOMGYUJTO (VALUTANEM,IRODASZAM,CEGBETU,';
      _pcs := _pcs + 'ERTEKTAR,ELSZAMOLASIARFOLYAM,'+_mezo+','+_ftmezo+')'+_sorveg;
      _pcs := _pcs + 'VALUES (' +chr(39) + _valutanem +chr(39)+',';
      _pcs := _pcs + inttostr(_aktpenztar)+',';
      _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',';
      if _aktcegbetu='Z' then _aktertekTar := 180;
      _pcs := _pcs + inttostr(_aktertektar)+',';
      _pcs := _pcs + inttostr(_elszamolasiarfolyam)+',';
      _pcs := _pcs + floattostr(_bankjegy)+',';
      _pcs := _pcs + floattoStr(_ertek)+')';
    end else
    begin   // ez gyüjtött bejegyzés

      _bj := ReceptorQuery.FieldByName(_mezo).asInteger;
      _ee := ReceptorQuery.FieldByName(_ftMezo).asInteger;

      _bj := _bj + _bankjegy;
      _ee := _ee + _ertek;

      _pcs := 'UPDATE FORGALOMGYUJTO'+_sorveg;
      _pcs := _pcs + 'SET '+_mezo+'='+floattostr(_bj)+',';
      _pcs := _pcs + _ftmezo + '='+floattostr(_ee)+_sorveg;
      _pcs := _pcs + 'WHERE IRODASZAM='+inttostr(_aktpenztar)+' AND VALUTANEM='+chr(39)+_valutanem+chr(39);
    end;

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;      // Beirjuk a gyüjtött adatot a forgalomgyüjtöbe
    end;
end;


// =============================================================================
                    procedure TadatLegyujtes.SendingRutin;
// =============================================================================
// ---------------------- A FORGALOMGYÜJTÉS subrutinja -------------------------
//                IDE KERÜLNEK AZ F ÉS U TIPUSÚ BIZONYLATOK TÉTELEI:

var _ezbank : boolean;

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
      _bq := Form1.BankScan(_penztar);
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

   _keres := inttostr(_kuldo)+_valutanem+inttostr(_fogado);

  // ------------- pénztárak közötti forgalom ----------------------------------

  _pcs := 'SELECT * FROM PENZTARKOZOTT' + _sorveg;
  _pcs := _pcs + 'WHERE KULDODNEMFOGADO=' + chr(39) + _keres + chr(39);

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
    end;

  if ReceptorQuery.recno=0 then
    begin
      _pcs := 'INSERT INTO PENZTARKOZOTT (VALUTANEM,KULDO,FOGADO,';
      _pcs := _pcs + 'KULDODNEMFOGADO,'+_mezo+')'+_sorveg;

      _pcs := _pcs + 'VALUES ('+chr(39)+_valutanem+chr(39)+',';
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

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;
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
  _pcs := _pcs + 'where Valutanem='+chr(39)+_valutanem+chr(39)+' AND ';
  _pcs := _pcs + 'KULDO='+inttostr(_kuldo)+' AND FOGADO='+inttostr(_fogado);

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
    end;

  if ReceptorQuery.recno=0 then
    begin
      _pcs := 'INSERT INTO TRBGYUJTO (VALUTANEM,KULDO,FOGADO,'+_mezo+')'+_sorveg;
      _pcs := _pcs+'VALUES ('+chr(39)+_valutanem+chr(39)+','+inttostr(_KULDO)+','+inttostr(_FOGADO);
      _pcs := _pcs+','+floattostr(_bankjegy)+')';
    end else
    begin
      _bj := ReceptorQuery.FieldByName(_mezo).asInteger;
      _bj := _bj + _bankjegy;

      _pcs := 'UPDATE TRBGYUJTO'+_sorveg;
      _pcs := _pcs + 'SET '+_mezo+'='+floattostr(_bj)+_sorveg;
      _pcs := _pcs +'WHERE VALUTANEM='+CHR(39)+_valutanem+chr(39)+' AND ';
      _pcs := _pcs + 'KULDO='+inttostr(_kuldo)+' AND FOGADO='+inttostr(_fogado);
    end;

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;
end;

// =============================================================================
                   procedure TadatLegyujtes.BankGyujtes;
// =============================================================================
// ----------------- A SENDING PROCEDURE SUBROUTINJA ---------------------------
//                        BANKI BIZONYLATOK GYÜJTÉSE

begin

  if _tipus = 'F' then _mezo := 'BEFIZETETTKP' else _mezo := 'FELVETTKP';

  _pcs := 'Select * From SUMBANKFORGALOM'+_sorveg;
  _pcs := _pcs + 'where Valutanem='+chr(39)+_valutanem+chr(39);

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
    end;

  if ReceptorQuery.recno=0 then
    begin
      _pcs := 'INSERT INTO SUMBANKFORGALOM (VALUTANEM,'+_mezo+')'+_sorveg;
      _pcs := _pcs+'VALUES ('+chr(39)+_valutanem+chr(39)+','+floatToStr(_bankjegy)+')';
    end else
    begin
      _bj := ReceptorQuery.FieldByName(_mezo).asInteger;
      _bj := _bj + _bankjegy;

      _pcs := 'UPDATE SUMBANKFORGALOM'+_sorveg;
      _pcs := _pcs + 'SET '+_mezo+'='+floattostr(_bj)+_sorveg;
      _pcs := _pcs + 'WHERE VALUTANEM='+chr(39)+_valutanem+chr(39);
    end;

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;
end;

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
                  procedure TAdatlegyujtes.CimletGyujtes;
// =============================================================================

var z: integer;

begin

  AlcimPanel.Caption := 'KÉSZLETEK GYÜJTÉSE';
  AlcimPanel.Repaint;

  _cimtarTablanev := 'CIMT'+_farok;

  BlokkDbase.Connected := true;
  Blokktabla.close;
  BlokkTabla.TableName := _cimtarTablaNev;
  if not BlokkTabla.exists then
    begin
      _kdatum := MulthaviUtolsoCimNap();
      if _kdatum='' then exit;
       _cimTarTablanev := 'CIMT' + _elofarok;
    end else
    begin
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
        end;

      if BlokkQuery.RecNo=0 then
        begin
          _kdatum := MulthaviUtolsoCimNap();
          if _kdatum='' then exit;
          _cimtarTablaNev := 'CIMT' + _elofarok;
        end else _kdatum := BlokkQuery.FieldByNAme('DATUM').AsString;
    end;

  _pcs := 'SELECT * FROM '+_cimtarTablaNev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39) + _kdatum + chr(39);
  with BlokkQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  while not BlokkQuery.Eof do
    begin
      _valutanem := BlokkQuery.FieldbyName('VALUTANEM').asString;
      _osszesen  := BlokkQuery.FieldByname('OSSZESEN').asInteger;

      _valss := Form1.Dnemscan(_valutanem);
      if _valss<0 then
        begin
          BlokkQuery.Next;
          Continue;
        end;

      inc(_gycimlet);

      for z := 1 to 14 do
        begin
          _tema := 'CIMLET'+inttostr(z);
          _cim[z] := BlokkQuery.Fieldbyname(_tema).asInteger;
        end;

      _elszamolasiArfolyam := GetElszamar(_kdatum,_valutanem);
      _ertek := trunc(_elszamolasiarfolyam*_osszesen/100);

      _pcs := 'INSERT INTO CIMLETGYUJTO (IRODASZAM,ERTEKTAR,CEGBETU,';
      _pcs := _pcs + 'VALUTANEM,ELSZAMOLASIARFOLYAM,';
      _pcs := _pcs + 'KESZLET,FORINTERTEK,CIMLET1,CIMLET2,CIMLET3,';
      _pcs := _pcs + 'CIMLET4,CIMLET5,CIMLET6,';
      _pcs := _pcs + 'CIMLET7,CIMLET8,CIMLET9,CIMLET10,CIMLET11,';
      _pcs := _pcs + 'CIMLET12,CIMLET13,CIMLET14)'+_sorveg;

      _pcs := _pcs + 'VALUES ('+inttostr(_aktpenztar)+',';
      _pcs := _pcs + inttostr(_aktertektar)+',';
      _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',';
      _pcs := _pcs + chr(39)+_valutanem + chr(39)+ ',';
      _pcs := _pcs + inttostr(_elszamolasiarfolyam)+',';
      _pcs := _pcs + inttostr(_osszesen)+',';
      _pcs := _pcs + inttostr(_ertek);

      for z := 1 to 14 do _pcs := _pcs + ',' + inttostr(_cim[z]);
      _pcs := _pcs + ')';

      with ReceptorQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          ExecSql;
        end;

      BlokkQuery.next;
    end;
  BlokkQuery.Close;
end;

// =============================================================================
             function TAdatLegyujtes.MulthaviUtolsoCimNap(): string;
// =============================================================================
// -------------- A CIMLETGYÜJTÉS PROCEDURE FUNKCIÓJA --------------------------

begin
  result := '';
  _cimTarTablaNev := 'CIMT'+ _elofarok;

  BlokkDbase.Connected := true;
  Blokktabla.close;
  BlokkTabla.TableName := _cimtarTablaNev;

  if not BlokkTabla.exists then exit;

  _pcs := 'SELECT * FROM ' + _cimtarTablanev + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with BlokkQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
    end;

  if Blokkquery.RecNo=0 then
    begin
      BlokkQuery.Close;
      Exit;
    end;

  Result := BlokkQuery.FieldByNAme('DATUM').AsString;
  BlokkQuery.Close;
end;

// =============================================================================
     function TadatLegyujtes.GetElszamar(_xdat: string; _xnem: string): integer;
// =============================================================================
// ----------------------  PUBLIKUS FUNKCIO ------------------------------------

begin
  Result := 0;
  if _xNem='HUF' then
    begin
      Result := 100;
      exit;
    end;
  _valss := Form1.DNemScan(_xnem);
  if _valss>-1 then Result := _elszarf[_valss];
end;



// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
         procedure TadatLegyujtes.ForgalomOsszesites;
// =============================================================================

var _etss,_valss,i,j: integer;

begin
  Nagycsik.Position := 50;
  Nagycsik.Repaint;


  for i := 0 to _ertektardarab-1 do
    begin
      for j := 0 to _valutadarab-1 do
        begin
          _kvett[i,j] := 0;
          _keladott[i,j] := 0;
          _kvettertek[i,j] := 0;
          _keladottertek[i,j] := 0;
        end;
    end;

  for i := 0 to 3 do
    begin
      for j := 0 to _valutadarab-1 do
        begin
          _kkvett[i,j] := 0;
          _kkeladott[i,j] := 0;
          _kkvettertek[i,j] := 0;
          _kkeladottertek[i,j] := 0;
        end;
    end;

  for j := 0 to _valutadarab-1 do
    begin
      _kelszarf[j] := 0;
      _sumvett[j] := 0;
      _sumeladott[j] := 0;
      _sumvettertek[j] := 0;
      _sumeladottertek[j] := 0;
    end;

  ReceptorDbase.close;
  ReceptorDbase.Connected := True;
  if ReceptorTranz.InTransaction then ReceptorTranz.Commit;
  ReceptorTranz.StartTransaction;

  _pcs := 'SELECT * FROM FORGALOMGYUJTO';
  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
    end;

  Csik.Max := receptorQuery.RecNo;
  CSIK.Position := 0;
  Csik.Repaint;

  // Ha nincs egyetlen adat sem gyüjtva, nincs mit összesiteni !

  if receptorQuery.recno=0 then
    begin
      receptorQuery.close;
      Exit;
    end;

  //  A forgalomgyüjtöt rekordonként kiolvassa:

  _cc := 0;
  ReceptorQuery.First;
  while not ReceptorQuery.Eof do
    begin
      inc(_cc);
      Csik.Position := _cc;
      with ReceptorQuery do
        begin
          _aktertektar := FieldByNAme('ERTEKTAR').asInteger;
          _valutanem := FieldByName('VALUTANEM').asString;
          _elszarfolyam := FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
          _vett := FieldByName('VETT').asInteger;
          _eladott := FieldByName('ELADOTT').asInteger;
          _vettertek := FieldByName('VETTERTEK').asInteger;
          _eladottertek := FieldByName('ELADOTTERTEK').asInteger;
          _cegbetu := FieldbyName('CEGBETU').AsString;
        end;

      _etss := Form1.ErtTarScan(_aktertektar);
      _valss := Form1.DNemScan(_valutanem);
      _cbsors := Form1.GetCegbetuSorszam(_cegbetu);

      _kvett[_etss,_valss] := _kvett[_etss,_valss] + _vett;
      _keladott[_etss,_valss] := _keladott[_etss,_valss] + _eladott;
      _kvettertek[_etss,_valss] := _kvettertek[_etss,_valss] + _vettertek;
      _keladottertek[_etss,_valss] := _keladottertek[_etss,_valss] + _eladottertek;

      _kkvett[_cbsors,_valss] := _kkvett[_cbsors,_valss] + _vett;
      _kkeladott[_cbsors,_valss] := _kkeladott[_cbsors,_valss] + _eladott;
      _kkvettertek[_cbsors,_valss] := _kkvettertek[_cbsors,_valss] + _vettertek;
      _kkeladottertek[_cbsors,_valss] := _kkeladottertek[_cbsors,_valss] + _eladottertek;

      if _kelszarf[_valss]=0 then _kelszarf[_valss] := _elszarfolyam;
      ReceptorQuery.Next;
    end;

  for i := 0 to _ertektarDarab-1 do
    begin
      for j := 0 to _valutadarab-1 do
        begin
          _sumvett[j] := _sumvett[j] + _kvett[i,j];
          _sumeladott[j] := _sumeladott[j] + _keladott[i,j];
          _sumvettertek[j] := _sumvettertek[j] + _kvettertek[i,j];
          _sumeladottertek[j] := _sumeladottertek[j] + _keladottertek[i,j];
        end;
    end;

  NagyCsik.Position := 75;
  Nagycsik.Repaint;

// ---------  A TELJES CÉG FORGALMÁNAK FELIRÁSA --------------------------------

    for j := 0 to _valutadarab-1 do
      begin
        _valutanem := _dnem[j+1];
        _elszarfolyam := _kelszarf[j];
        _vett := _sumvett[j];
        _eladott := _sumeladott[j];
        _vettertek := _sumvettertek[j];
        _eladottertek := _sumeladottertek[j];

        _pcs := 'INSERT INTO FORGALOMGYUJTO (IRODASZAM,ERTEKTAR,VALUTANEM,ELSZAMOLASIARFOLYAM,';
        _pcs := _pcs + 'VETT,ELADOTT,VETTERTEK,ELADOTTERTEK)'+_sorveg;

        _pcs := _pcs + 'VALUES (0,0,'+ chr(39)+_valutanem+chr(39)+',';
        _pcs := _pcs + inttostr(_elszarfolyam)+','+inttostr(_vett)+','+inttostr(_eladott)+',';
        _pcs := _pcs + inttostr(_vettertek)+','+inttostr(_eladottertek)+')';

        with ReceptorQuery do
          begin
            Close;
            Sql.Clear;
            Sql.add(_pcs);
            ExecSql;
          end;
      end;

// -------------- JÖHETNEK AZ ÉRTÉKTÁRAK ÖSSZESITETT ADATAI  -------------------

  for i := 0 to _ertektardarab-1 do
    begin
      _aktertektar := _korzetszam[i];
      for j := 0 to _valutadarab-1 do
        begin
          _valutanem := _dnem[j+1];
          _elszarfolyam := _kelszarf[j];
          _vett := _kvett[i,j];
          _eladott := _keladott[i,j];
          _vettertek := _kvettertek[i,j];
          _eladottertek := _keladottertek[i,j];

          _pcs := 'INSERT INTO FORGALOMGYUJTO (IRODASZAM,ERTEKTAR,VALUTANEM,ELSZAMOLASIARFOLYAM,';
          _pcs := _pcs + 'VETT,ELADOTT,VETTERTEK,ELADOTTERTEK)'+_sorveg;

          _pcs := _pcs + 'VALUES (0,'+inttostr(_aktertektar)+','+ chr(39)+_valutanem+chr(39)+',';
          _pcs := _pcs + inttostr(_elszarfolyam)+','+inttostr(_vett)+','+inttostr(_eladott)+',';
          _pcs := _pcs + inttostr(_vettertek)+','+inttostr(_eladottertek)+')';

          with ReceptorQuery do
            begin
              Close;
              Sql.Clear;
              Sql.add(_pcs);
              ExecSql;
            end;
        end;
    end;

   // --------------------------------------------------------------------------

   // -------------- JÖHETNEK A KFT-K ÖSSZESITETT ADATAI  -------------------


  for i := 0 to 3 do
    begin
      for j := 0 to _valutadarab-1 do
        begin
          _valutanem := _dnem[j+1];
          _elszarfolyam := _kelszarf[j];
          _vett := _Kkvett[i,j];
          _eladott := _kkeladott[i,j];
          _vettertek := _kkvettertek[i,j];
          _eladottertek := _kkeladottertek[i,j];

          _pcs := 'INSERT INTO FORGALOMGYUJTO (IRODASZAM,ERTEKTAR,VALUTANEM,ELSZAMOLASIARFOLYAM,';
          _pcs := _pcs + 'VETT,ELADOTT,VETTERTEK,ELADOTTERTEK)'+_sorveg;

          _pcs := _pcs + 'VALUES (-1,'+inttostr(i)+','+ chr(39)+_valutanem+chr(39)+',';
          _pcs := _pcs + inttostr(_elszarfolyam)+','+inttostr(_vett)+','+inttostr(_eladott)+',';
          _pcs := _pcs + inttostr(_vettertek)+','+inttostr(_eladottertek)+')';

          with ReceptorQuery do
            begin
              Close;
              Sql.Clear;
              Sql.add(_pcs);
              ExecSql;
            end;
        end;
    end;

  ReceptorTranz.Commit;
  ReceptorQuery.Close;
end;



// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
                 procedure TadatLegyujtes.InterPtControl;
// =============================================================================

begin
  ReceptorDbase.close;
  ReceptorDbase.Connected := true;
  if ReceptorTranz.InTransaction then ReceptorTranz.Commit;
  ReceptorTranz.StartTransaction;

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
  ReceptorTranz.Commit;
  ReceptorTabla.Close;
end;


// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
                  procedure TadatLegyujtes.TRBControl;
// =============================================================================

begin
  ReceptorDbase.close;
  ReceptorDbase.Connected := true;
  if ReceptorTranz.InTransaction then ReceptorTranz.Commit;
  ReceptorTranz.StartTransaction;

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
                procedure TadatLegyujtes.Cimletosszesites;
// =============================================================================

//              CIMLETEK ÉRTÉKTÁRANKÉNT ÖSSZEADÁSA KÖVETKEZIK
//                         SUMCIMLET TÁBLA ÜRES !

var z,_etss,i,j,_valss,_aktcimletdb,_zz,_aktsum,_aktdb,_etcimdb,_sumdb: integer;
    _urcimsor,_cimstring,_aktsumcimsor,_ujsumsor,_aktsumcimlet,_aktcimlets: string;
    _aktscimsor,_etarcimsor,_ujscimsor,_etpar,_sumpar: string;
    _hi,_lo,_sumlo,_sumhi,_aktlo,_akthi,_etlo,_ethi: byte;
begin
  {
  Setlength(_kkeszlet,_ertektardarab,28);
  Setlength(_kertek,_ertektardarab,28);
  Setlength(_kcimsor,_ertektardarab,28);

  setlength(_skkeszlet,4,28);
  Setlength(_skKertek,4,28);
  Setlength(_skcimsor,4,28);

  setlength(_skeszlet,28);
  Setlength(_sKertek,28);
  Setlength(_scimsor,28);
  }

  _urcimsor := dupestring(chr(0),28);

  for i := 0 to _ertektardarab-1 do
    begin
      for j := 0 to _valutadarab-1 do
        begin
          _kkeszlet[i,j] := 0;
          _kertek[i,j] := 0;
          _kcimsor[i,j] := _urcimsor;
        end;
    end;

  // Kft gyüjtök kinullázása

  for i := 0 to 2 do
    begin
      for j := 0 to _valutaDarab-1 do
        begin
          _skkeszlet[i,j]:= 0;
          _skkertek[i,j] := 0;
          _skcimsor[i,j] := _urcimsor;
        end;
    end;


  // Megnyitja a CimletGyüjtöt, ahol az eddig gyüjtött adatok vannak:

  ReceptorDbase.Close;
  ReceptorDbase.Connected := true;
  if ReceptorTranz.InTransaction then ReceptorTranz.Commit;
  ReceptorTranz.StartTransaction;

  _pcs := 'SELECT * FROM CIMLETGYUJTO';
  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
    end;

  NagyCsik.Max := 100;
  NagyCsik.Position := 30;
  Csik.Position := 0;
  Csik.max := ReceptorQuery.RecNo;
  Csik.Repaint;
  NagyCsik.Repaint;

  _cc := 0;

  // Ha nincs egyetlen adat sem gyüjtve, nincs mit összesiteni !

  if receptorQuery.recno=0 then
    begin
      ReceptorTranz.Commit;
      receptorQuery.close;
      Exit;
    end;

  //  A cimletgyüjtöt rekordonként kiolvassa:

  ReceptorQuery.First;
  while not ReceptorQuery.Eof do
    begin
      inc(_cc);
      Csik.Position := _cc;

      with ReceptorQuery do
        begin
          _aktpenztar   := FieldByName('IRODASZAM').asInteger;
          _aktertektar  := FieldByNAme('ERTEKTAR').asInteger;
          _valutanem    := FieldByName('VALUTANEM').asString;
          _elszarfolyam := FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
          _ertek        := FieldByName('FORINTERTEK').asInteger;
          _keszlet      := FieldByName('KESZLET').asInteger;
          _cegbetu      := FieldByName('CEGBETU').asString;
        end;

      //  .. és a cimleteket is

      _Cimstring := '';
      for z := 1 to 14 do
        begin
          _mezo        := 'CIMLET'+inttostr(z);
          _aktcimletdb := ReceptorQuery.FieldByName(_mezo).asInteger;
          _hi          := trunc(_aktcimletdb/256);
          _lo          := _aktcimletdb - trunc(256*_hi);
          _cimstring   := _cimstring + chr(_lo)+chr(_hi);
        end;

      _etss  := Form1.ErtTarScan(_aktertektar);
      _valss := Form1.DNemScan(_valutanem);
      _cbsors := 1; // GetCegbetuSorszam(_cegbetu);

      _kkeszlet[_etss,_valss] := _kkeszlet[_etss,_valss] + _keszlet;
      _kertek[_etss,_valss]   := _kertek[_etss,_valss] + _ertek;
      _skkeszlet[_cbSors,_valss] := _skkeszlet[_cbSors,_valss] + _keszlet;
      _skkertek[_cbSors,_valss] := _skkertek[_cbsors,_valss] + _ertek;

      _aktsumcimsor := _kcimsor[_etss,_valss];

      _zz := 1;
      _ujsumsor := '';
      while _zz<28 do
        begin
          _aktsumcimlet := midstr(_aktsumcimsor,_zz,2);

          _sumlo  := ord(_aktsumcimlet[1]);
          _sumhi  := ord(_aktsumcimlet[2]);
          _aktsum := _sumlo+trunc(256*_sumhi);

          _aktcimlets := midstr(_cimstring,_zz,2);

          _aktlo  := ord(_aktcimlets[1]);
          _akthi  := ord(_aktcimlets[2]);
          _aktdb  := _aktlo+trunc(256*_akthi);

          _aktsum := _aktsum + _aktdb;
          _sumhi  := trunc(_aktsum/256);
          _sumlo  := _aktsum-trunc(256*_sumhi);

          _ujsumsor := _ujsumsor + chr(_sumlo)+chr(_sumhi);
          _zz := _zz + 2;
        end;
      _kcimsor[_etss,_valss] := _ujsumsor;

      // -----------------------------------------------------------------------

      _aktsumcimsor := _skcimsor[_cbsors,_valss];

      _zz := 1;
      _ujsumsor := '';
      while _zz<28 do
        begin
          _aktsumcimlet := midstr(_aktsumcimsor,_zz,2);

          _sumlo  := ord(_aktsumcimlet[1]);
          _sumhi  := ord(_aktsumcimlet[2]);
          _aktsum := _sumlo+trunc(256*_sumhi);

          _aktcimlets := midstr(_cimstring,_zz,2);

          _aktlo  := ord(_aktcimlets[1]);
          _akthi  := ord(_aktcimlets[2]);
          _aktdb  := _aktlo+trunc(256*_akthi);

          _aktsum := _aktsum + _aktdb;
          _sumhi  := trunc(_aktsum/256);
          _sumlo  := _aktsum-trunc(256*_sumhi);

          _ujsumsor := _ujsumsor + chr(_sumlo)+chr(_sumhi);
          _zz := _zz + 2;
        end;
      _skcimsor[_cbsors,_valss] := _ujsumsor;

      ReceptorQuery.Next;
    end;


 // ----------------------------------------------------------------------------

  NagyCsik.Position := 35;
  NagyCsik.Repaint;

  Csik.Max :=100;
  Csik.Position := 50;
  Csik.Repaint;

  for j := 0 to _valutadarab-1 do
    begin
      _skeszlet[j] := 0;
      _sKertek[j] := 0;
      _sCimsor[j] := _urcimsor;
    end;


  for i := 0 to _ertektardarab-1 do
    begin
      for j := 0 to _valutadarab-1 do
        begin
          _skeszlet[j] := _skeszlet[j] + _kkeszlet[i,j];
          _skertek[j] := _skertek[j] + _kertek[i,j];

          _aktscimsor := _sCimsor[j];
          _etarcimsor := _kcimsor[i,j];

          _zz := 1;
          _ujscimsor := '';
          while _zz<28 do
            begin
              _etpar     := midstr(_etarcimsor,_zz,2);
              _etlo      := ord(_etpar[1]);
              _ethi      := ord(_etpar[2]);
              _etcimdb   := _etlo + trunc(256*_ethi);

              _sumpar    := midstr(_aktscimsor,_zz,2);
              _sumhi     := ord(_sumpar[2]);
              _sumlo     := ord(_sumpar[1]);

              _sumdb     := _sumlo + trunc(256*_sumhi);
              _sumdb     := _sumdb + _etcimdb;
              _sumhi     := trunc(_sumdb/256);
              _sumlo     := _sumdb-trunc(256*_sumhi);
              _ujscimsor := _ujscimsor + chr(_sumlo)+chr(_sumhi);

              _zz := _zz + 2;
            end;
          _scimsor[j] := _ujscimsor;
        end;
    end;

    for j := 0 to _valutadarab-1 do
      begin
        _valutanem    := _dnem[j+1];
        _keszlet      := _skeszlet[j];
        _ertek        := _SKertek[j];
        _elszarfolyam := 0;
        _aktcimlets   := _scimsor[j];

        if _keszlet>0 then _elszarfolyam := trunc(100*_ertek/_keszlet);

        for i := 0 to 13 do
          begin
            _zz       := 1+i+i;
            _sumpar   := midstr(_aktcimlets,_zz,2);
            _sumlo    := ord(_sumpar[1]);
            _sumhi    := ord(_sumpar[2]);
            _cim[i+1] := _sumlo+trunc(256*_sumhi);
          end;

        _pcs := 'INSERT INTO CIMLETGYUJTO (IRODASZAM,ERTEKTAR,';
        _pcs := _pcs + 'VALUTANEM,ELSZAMOLASIARFOLYAM,';
        _pcs := _pcs + 'KESZLET,FORINTERTEK,CIMLET1,CIMLET2,';
        _pcs := _pcs + 'CIMLET3,CIMLET4,CIMLET5,CIMLET6,';
        _pcs := _pcs + 'CIMLET7,CIMLET8,CIMLET9,CIMLET10,';
        _pcs := _pcs + 'CIMLET11,CIMLET12,CIMLET13,CIMLET14)'+_sorveg;

        _pcs := _pcs + 'VALUES (0,0,';
        _pcs := _pcs + chr(39) + _valutanem + chr(39)+',';
        _pcs := _pcs + inttostr(_elszarfolyam)+',';
        _pcs := _pcs + inttostr(_keszlet)+',';
        _pcs := _pcs + inttostr(_ertek);

        for z := 1 to 14 do _pcs := _pcs + ','+inttostr(_cim[z]);
        _pcs := _pcs + ')';

        with ReceptorQuery do
          begin
            Close;
            Sql.Clear;
            Sql.add(_pcs);
            ExecSql;
          end;
      end;

  NagyCsik.Position := 40;
  NagyCsik.Repaint;

  Csik.Position := 100;
  Csik.Repaint;

 // -------------------- értéktárak felirása  --------------------------------


    for i := 0 to _ertektardarab-1 do
      begin
        for j:= 0 to _valutadarab-1 do
          begin
            _valutanem    := _dnem[j+1];
            _keszlet      := _kkeszlet[i,j];
            _ertek        := _Kertek[i,j];
            _elszarfolyam := 0;
            _etarcimsor   := _kcimsor[i,j];

            if _keszlet>0 then _elszarfolyam := trunc(100*_ertek/_keszlet);

            for z := 0 to 13 do
              begin
                _zz       := 1+z+z;
                _sumpar   := midstr(_etarcimsor,_zz,2);
                _sumlo    := ord(_sumpar[1]);
                _sumhi    := ord(_sumpar[2]);
                _cim[z+1] := _sumlo+trunc(256*_sumhi);
              end;

            _aktertektar := _korzetszam[i];

            _pcs := 'INSERT INTO CIMLETGYUJTO (IRODASZAM,ERTEKTAR,VALUTANEM,';
            _pcs := _pcs + 'ELSZAMOLASIARFOLYAM,KESZLET,FORINTERTEK,CIMLET1,';
            _pcs := _pcs + 'CIMLET2,CIMLET3,CIMLET4,CIMLET5,CIMLET6,';
            _pcs := _pcs + 'CIMLET7,CIMLET8,CIMLET9,CIMLET10,CIMLET11,';
            _pcs := _pcs + 'CIMLET12,CIMLET13,CIMLET14)'+_sorveg;

            _pcs := _pcs + 'VALUES (0,';
            _pcs := _pcs + inttostr(_aktertektar)+',';
            _pcs := _pcs + chr(39)+_valutanem+chr(39)+',';
            _pcs := _pcs + inttostr(_elszarfolyam)+',';
            _pcs := _pcs + inttostr(_keszlet)+',';
            _pcs := _pcs + inttostr(_ertek);

            for z := 1 to 14 do _pcs := _pcs + ','+inttostr(_cim[z]);
            _pcs := _pcs + ')';

            with ReceptorQuery do
              begin
                Close;
                Sql.Clear;
                Sql.add(_pcs);
                ExecSql;
              end;
          end;
      end;

    // ------------------- kft-ek felirasa -------------------------------------


    for i := 0 to 2 do
      begin
        for j:= 0 to _valutadarab-1 do
          begin
            _valutanem    := _dnem[j+1];
            _keszlet      := _skkeszlet[i,j];
            _ertek        := _sKkertek[i,j];
            _elszarfolyam := 0;
            _etarcimsor   := _skcimsor[i,j];

            if _keszlet>0 then _elszarfolyam := trunc(100*_ertek/_keszlet);

            for z := 0 to 13 do
              begin
                _zz       := 1+z+z;
                _sumpar   := midstr(_etarcimsor,_zz,2);
                _sumlo    := ord(_sumpar[1]);
                _sumhi    := ord(_sumpar[2]);
                _cim[z+1] := _sumlo+trunc(256*_sumhi);
              end;

            _pcs := 'INSERT INTO CIMLETGYUJTO (IRODASZAM,ERTEKTAR,VALUTANEM,';
            _pcs := _pcs + 'ELSZAMOLASIARFOLYAM,KESZLET,FORINTERTEK,CIMLET1,';
            _pcs := _pcs + 'CIMLET2,CIMLET3,CIMLET4,CIMLET5,CIMLET6,';
            _pcs := _pcs + 'CIMLET7,CIMLET8,CIMLET9,CIMLET10,CIMLET11,';
            _pcs := _pcs + 'CIMLET12,CIMLET13,CIMLET14)'+_sorveg;

            _pcs := _pcs + 'VALUES (-1,';
            _pcs := _pcs + inttostr(i)+',';
            _pcs := _pcs + chr(39)+_valutanem+chr(39)+',';
            _pcs := _pcs + inttostr(_elszarfolyam)+',';
            _pcs := _pcs + inttostr(_keszlet)+',';
            _pcs := _pcs + inttostr(_ertek);

            for z := 1 to 14 do _pcs := _pcs + ','+inttostr(_cim[z]);
            _pcs := _pcs + ')';

            with ReceptorQuery do
              begin
                Close;
                Sql.Clear;
                Sql.add(_pcs);
                ExecSql;
              end;
          end;
      end;

    ReceptorTranz.Commit;
    ReceptorQuery.Close;
end;




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
  _pcs := _pcs + chr(39) + _blokknum+chr(39)+',';
  _pcs := _pcs + chr(39) + _datum+chr(39)+',';
  _pcs := _pcs + chr(39) + _ido+chr(39)+',';
  _pcs := _pcs + chr(39) + _prosnev+chr(39)+',';
  _pcs := _pcs + chr(39) + _sttipus+chr(39)+',';
  _pcs := _pcs + chr(39) + _stBiz+chr(39)+',';
  _pcs := _pcs + chr(39) + trim(_stornoindok)+chr(39)+')';

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;

  _pcs := 'INSERT INTO STORNOTETEL (IRODASZAM,CEGBETU,BIZONYLATSZAM,VALUTANEM,';
  _pcs := _pcs + 'BANKJEGY,FORINTERTEK)'+_SORVEG;
  _pcs := _pcs + 'VALUES ('+inttostr(_aktpenztar)+',';
  _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',';
  _pcs := _pcs + chr(39)+_blokknum +chr(39)+',';
  _pcs := _pcs + chr(39)+_valutanem+chr(39)+',';
  _pcs := _pcs + floattostr(_bankjegy)+',';
  _pcs := _pcs + floattostr(_ertek)+')';

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;
end;


// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
             procedure Tadatlegyujtes.TablaUrites(_tNev: string);
// =============================================================================


begin
  ReceptorDbase.Connected := True;
  if ReceptorTranz.InTransaction then ReceptorTranz.Commit;
  ReceptorTranz.StartTransaction;
  with ReceptorQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add('DELETE FROM ' + _tNev);
      ExecSql;
    end;
  ReceptorTranz.commit;
  ReceptorDbase.Close;
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


//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
                  procedure TAdatLegyujtes.WuniNullazas;
// =============================================================================


begin
  _usdNyito   := 0;
  _hufNyito   := 0;
  _metronyito := 0;
  _tesconyito := 0;
  _afaNyito   := 0;

  _usdGBe   := 0;
  _hufGBe   := 0;
  _metroGBe := 0;
  _tescoGBe := 0;
  _afaGBe   := 0;

  _usdGKi   := 0;
  _hufGKi   := 0;
  _metroGKi := 0;
  _tescoGKi := 0;
  _afaGKi   := 0;

  _usdPBe   := 0;
  _hufPBe   := 0;
  _metroPBe := 0;
  _tescoPBe := 0;
  _afaPBe   := 0;

  _usdPKi   := 0;
  _hufPKi   := 0;
  _metroPKi := 0;
  _tescoPKi := 0;
  _afaPKi   := 0;

  _usdUBe   := 0;
  _hufUBe   := 0;

  _usdUKi   := 0;
  _hufUKi   := 0;
  _metroUKi := 0;
  _tescoUKi := 0;
  _afaUki   := 0;

  _usdZaro   := 0;
  _hufZaro   := 0;
  _metroZaro := 0;
  _tescoZaro := 0;
  _afaZaro   := 0;
end;


// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
                  procedure Tadatlegyujtes.GetWuniNyitasZaras;
// =============================================================================

var _nyitonap,_zaronap: string;

begin

  _pcs := 'SELECT * FROM ' + _wzarTablanev + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with BlokkQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
    end;

  // Az e-havi wzar tábla utolsó rekordjáról indulunk, amig el nem érjük
  // a kezdönapot vagy annál régebbi napot, vagy a tábla elejét (BOF)

  _nyitonap := '';
  while not BlokkQuery.Bof do
    begin
      _datum := Blokkquery.FieldByNAme('DATUM').asString;

      // Megtalálta a kezdö napot:

      if _datum=_tolstring then
        begin
          _nyitonap := _datum;
          Break;
        end;

      // A kezdö napnál régebbi napot talált:

      if _datum<_tolstring then
        begin
          _nyitonap :=  _datum;
          break;
        end;
      BlokkQuery.Prior;
    end;

  BlokkQuery.close;
  if _nyitoNap='' then  // Nem talált megfelelö napot:
    begin

       // Nézzük a múlthavi táblát
      _wzarTablanev := 'WZAR'+_elofarok;

      BlokkTabla.Close;
      Blokktabla.TableName := _wzartablanev;

      // Van egyáltalán múlthavi tábla ?

      if Blokktabla.Exists then
        begin
          with BlokkQuery do
            begin
              Close;
              Sql.Clear;
              Sql.Add(_pcs);
              Open;
              Last;
            end;

          // Ha van, akkor az utolsó napját kell beolvasni
          if BlokkQuery.Recno>0 then _nyitonap := BlokkQuery.FieldByName('DATUM').asstring;
          BlokkQuery.Close;
        end;
    end;

  // Ha találtunk megfelelö nyitónapot, akkor az adatait beolvassa:

  if _nyitoNap<>'' then
    begin
      _pcs := 'SELECT * FROM ' + _wzarTablanev + _sorveg;
      _pcs := _pcs + 'WHERE DATUM='+chr(39)+_nyitonap+chr(39);

      with BlokkQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
        end;

      if Blokkquery.recno>0 then
        begin
          with BlokkQuery do
            begin
              _usdNyito   := FieldByName('USDNYITO').asInteger;
              _hufNyito   := FieldByName('HUFNYITO').asInteger;
              _metronyito := FieldByName('METRONYITO').asInteger;
              _tesconyito := FieldByName('TESCONYITO').asInteger;
            end;
          _afaNyito := _metronyito + _tescoNyito;
        end;
    end;

 // ---------- Jöhetnek a záró mennyiségek ---------------------------

  _wzarTablanev := 'WZAR' + _farok;

  _pcs := 'SELECT * FROM ' + _wzarTablanev + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  _zaroNap := '';

  with BlokkQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
    end;

  // Keressi azt a napot, amelyik az utolsó nap
  while not BlokkQuery.Bof do
    begin
      _datum := Blokkquery.FieldByNAme('DATUM').asString;
      if _datum=_igstring then
        begin
          _zaronap := _datum;
          Break;
        end;

      if _datum<_igstring then
        begin
          _zaronap :=  _datum;
          break;
        end;

      BlokkQuery.Prior;
    end;

  if _zaronap<>'' then
    begin
      _pcs := 'SELECT * FROM ' + _wzarTablanev + _sorveg;
      _pcs := _pcs + 'WHERE DATUM='+chr(39)+_zaronap+chr(39);

      with BlokkQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;

          _usdZaro   := FieldByName('USDZARO').asInteger;
          _hufZaro   := FieldByName('HUFZARO').asInteger;
          _metroZaro := FieldByName('METROZARO').asInteger;
          _tescoZaro := FieldByName('TESCOZARO').asInteger;
          Close;
        end;
       _afaZaro := _metroZaro + _tescoZaro;
    end;
  BlokkQuery.Close;
end;

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
                procedure Tadatlegyujtes.WuniForgalomGyujtes;
// =============================================================================


var _tranzAkcio: STRING;

begin

  _pcs := 'SELECT * FROM '+ _wuniTablanev + _sorveg;
  _pcs := _pcs + 'WHERE '+ _idoszakszuro + ' AND (STORNO<2)';

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
          _valutanem := FieldByName('VALUTANEM').asString;
          _bjegy := FieldByName('BANKJEGY').asInteger;
          _Tranzakcio := FieldByName('TRANZAKCIOTIPUS').asstring;
        end;

      _irany := Leftstr(_tranzakcio,1);
      if (_foegyseg<2) and (_valutanem='USD') and (_irany='+') then
             _usdGbe := _usdGbe + _bJegy;

      if (_foegyseg<2) and (_valutanem='USD') and (_irany='-') then
             _usdGKi := _usdGKi + _bJegy;

       if (_foegyseg<2) and (_valutanem='HUF') and (_irany='+') then
             _hufGbe := _hufGbe + _bJegy;

      if (_foegyseg<2) and (_valutanem='HUF') and (_irany='-') then
             _hufGKi := _hufGKi + _bJegy;

      // -----------------------------------------------------------------------

      if (_foegyseg=2) and (_valutanem='USD') and (_irany='+') then
             _usdPbe := _usdPbe + _bJegy;

      if (_foegyseg=2) and (_valutanem='USD') and (_irany='-') then
             _usdPKi := _usdPKi + _bJegy;

       if (_foegyseg=2) and (_valutanem='HUF') and (_irany='+') then
             _hufPbe := _hufPbe + _bJegy;

      if (_foegyseg=2) and (_valutanem='HUF') and (_irany='-') then
             _hufPKi := _hufPKi + _bJegy;

      // -----------------------------------------------------------------------

      if (_foegyseg=5) and (_valutanem='USD') and (_irany='+') then
             _usdUbe := _usdUbe + _bJegy;

      if (_foegyseg=5) and (_valutanem='USD') and (_irany='-') then
             _usdUKi := _usdUKi + _bJegy;

       if (_foegyseg=5) and (_valutanem='HUF') and (_irany='+') then
             _hufube := _hufUbe + _bJegy;

      if (_foegyseg=5) and (_valutanem='HUF') and (_irany='-') then
             _hufUKi := _hufUKi + _bJegy;

      // -----------------------------------------------------------------------

      BlokkQuery.Next;
    end;
  BlokkQuery.Close;
end;


// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
                 procedure Tadatlegyujtes.MetroForgalomGyujtes;
// =============================================================================

var _tranzAkcio: string;

begin

  _pcs := 'SELECT * FROM '+ _metroTablaNev + _sorveg;
  _pcs := _pcs +'WHERE '+ _idoszakszuro + ' AND ((STORNO<2) OR (STORNO IS NULL))';

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
             _metroUKI := _AFAUKI + _kifizetve;

      // -----------------------------------------------------------------------

      BlokkQuery.Next;
    end;
  BlokkQuery.Close;

end;

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
              procedure Tadatlegyujtes.TescoForgalomGyujtes;
// =============================================================================


var _tranzAkcio: string;

begin

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


// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
                procedure TadatLegyujtes.WuniAfaBerogzites;
// =============================================================================


begin
  _afanyito := _metronyito + _tesconyito;
  _afagbe := _metrogbe + _tescoGbe;
  _afaGki := _metroGki + _tescoGki;
  _afaPbe := _metroPbe + _tescoPbe;
  _afaPki := _metroPki + _tescoPki;
  _afaUki := _metroUki + _tescoUki;

  _pcs := 'INSERT INTO WUNIGYUJTO (IRODASZAM,ERTEKTAR,CEGBETU,USDNYITO,';
  _pcs := _pcs + 'HUFNYITO,AFANYITO,USDZARO,HUFZARO,AFAZARO,USDGBE,HUFGBE,';
  _pcs := _pcs + 'AFAGBE,USDGKI,HUFGKI,AFAGKI,USDPBE,HUFPBE,AFAPBE,USDPKI,';
  _pcs := _pcs + 'HUFPKI,AFAPKI,USDUBE,HUFUBE,USDUKI,HUFUKI,AFAUKI)' + _sorveg;

  _pcs := _pcs + 'VALUES ('+ inttostr(_aktpenztar) + ',';
  _pcs := _pcs + inttostr(_aktertektar) + ',';
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
  _pcs := _pcs + inttostr(_afauki)+')';

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Execsql;
    end;
end;


// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
                procedure TAdatlegyujtes.WuniOsszesites;
// =============================================================================

//  FELADAT:  A WUNIGYÜJTÖ REKORDJAIT ÉRTEKTÁRRA ÉS TOTAL ÖSSZESITENI
//                      ÉS BEIRNI A WUNIGYUJTÖ TÁBLÁBA

var z,_etss: integer;

begin

   // Az értéktárak tömbjének deklarálása:
   {
   Setlength(_uny,_ertektarDarab);
   Setlength(_uz,_ertektarDarab);
   Setlength(_hny,_ertektardarab);
   Setlength(_hz,_ertektarDarab);
   Setlength(_any,_ertektardarab);
   Setlength(_az,_ertektarDarab);

   Setlength(_ubg,_ertektarDarab);
   Setlength(_ubp,_ertektarDarab);
   Setlength(_ubu,_ertektarDarab);
   Setlength(_ukg,_ertektarDarab);
   Setlength(_ukp,_ertektarDarab);
   Setlength(_uku,_ertektarDarab);

   Setlength(_hbg,_ertektarDarab);
   Setlength(_hbp,_ertektarDarab);
   Setlength(_hbu,_ertektarDarab);
   Setlength(_hkg,_ertektarDarab);
   Setlength(_hkp,_ertektarDarab);
   Setlength(_hku,_ertektarDarab);

   Setlength(_abg,_ertektarDarab);
   Setlength(_abp,_ertektarDarab);
   Setlength(_akg,_ertektarDarab);
   Setlength(_akp,_ertektarDarab);
   Setlength(_aku,_ertektarDarab);
   }

   for z := 0 to _ertektardarab-1 do
     begin

       _uny[z]:= 0;
       _uz[z] := 0;
      _hny[z] := 0;
       _hz[z] := 0;
      _any[z] := 0;
       _az[z] := 0;

       _ubg[z] := 0;
       _ubp[z] := 0;
       _ubg[z] := 0;
       _ubu[z] := 0;
       _ukg[z] := 0;
       _ukp[z] := 0;
       _uku[z] := 0;

       _hbg[z] := 0;
       _hbp[z] := 0;
       _hbu[z] := 0;
       _hkg[z] := 0;
       _hkp[z] := 0;
       _hku[z] := 0;

       _abg[z] := 0;
       _abp[z] := 0;
       _akg[z] := 0;
       _akp[z] := 0;
       _aku[z] := 0;
     end;

   for z := 0 to 2 do
     begin

       _kuny[z]:= 0;
       _kuz[z] := 0;
      _khny[z] := 0;
       _khz[z] := 0;
      _kany[z] := 0;
       _kaz[z] := 0;

       _kubg[z] := 0;
       _kubp[z] := 0;
       _kubg[z] := 0;
       _kubu[z] := 0;
       _kukg[z] := 0;
       _kukp[z] := 0;
       _kuku[z] := 0;

       _khbg[z] := 0;
       _khbp[z] := 0;
       _khbu[z] := 0;
       _khkg[z] := 0;
       _khkp[z] := 0;
       _khku[z] := 0;

       _kabg[z] := 0;
       _kabp[z] := 0;
       _kakg[z] := 0;
       _kakp[z] := 0;
       _kaku[z] := 0;
     end;

  // A wuni gyüjtö összes adatát beolvassa:

  Receptordbase.close;
  ReceptorDbase.Connected := true;
  if ReceptorTranz.InTransaction then ReceptorTranz.Commit;
  ReceptorTranz.StartTransaction;

  _pcs := 'SELECT * FROM WUNIGYUJTO';

  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
    end;

  // Ha nincs egyetlen adat sem gyüjtve, nincs mit összesiteni !

  if receptorQuery.recno=0 then
    begin
      receptorTranz.commit;
      receptorQuery.close;
      Exit;
    end;

  Csik.Max := ReceptorQuery.RecNo;
  Csik.position := 0;
  Csik.Repaint;

  //  A wunigyüjtöt rekordonként kiolvassa:

  _cc := 0;
  ReceptorQuery.First;
  while not ReceptorQuery.Eof do
    begin
      inc(_cc);
      Csik.Position := _cc;
      with ReceptorQuery do
        begin
          _aktertektar := FieldByNAme('ERTEKTAR').asInteger;
          _cegbetu  := FieldByname('CEGBETU').asString;

          _usdnyito := FieldByName('USDNYITO').asInteger;
          _hufnyito := FieldByName('HUFNYITO').asInteger;
          _afanyito := FieldByName('AFANYITO').asInteger;

          _usdzaro := FieldByName('USDZARO').asInteger;
          _hufzaro := FieldByName('HUFZARO').asInteger;
          _afazaro := FieldByName('AFAZARO').asInteger;

          _usdGbe := Fieldbyname('USDGBE').asInteger;
          _usdPbe := FieldByName('USDPBE').asInteger;
          _usdUbe := FieldByName('USDUBE').asInteger;

          _hufGbe := Fieldbyname('HUFGBE').asInteger;
          _hufPbe := FieldByName('HUFPBE').asInteger;
          _hufUbe := FieldByName('HUFUBE').asInteger;

          _usdGKi := Fieldbyname('USDGKI').asInteger;
          _usdPKi := FieldByName('USDPKI').asInteger;
          _usdUKi := FieldByName('USDUKI').asInteger;

          _hufGKi := Fieldbyname('HUFGKI').asInteger;
          _hufPKi := FieldByName('HUFPKI').asInteger;
          _hufUKi := FieldByName('HUFUKI').asInteger;

          _afaGbe := FieldByName('AFAGBE').asInteger;
          _afaPbe := FieldByName('AFAPBE').asInteger;

          _afaGki := FieldByName('AFAGKI').asInteger;
          _afaPki := FieldByName('AFAPKI').asInteger;
          _afaUki := FieldByName('AFAUKI').asInteger;

        end;

      // Itt summáza az aktuális értéktár tömbjeibe az adatokat:

      _etss := Form1.Erttarscan(_aktertekTar);
      _cbsors := 1; // GetCegbetuSorszam(_cegbetu);

      _uny[_etss] := _uny[_etss] + _usdnyito;
      _hny[_etss] := _uny[_etss] + _hufnyito;
      _any[_etss] := _uny[_etss] + _afanyito;

      _kuny[_cbsors] := _kuny[_cbsors] + _usdnyito;
      _khny[_cbsors] := _kHny[_cbsors] + _hufnyito;
      _kany[_cbsors] := _kAny[_cbsors] + _afanyito;

      // -----------------------------------------------------------------------

      _uz[_etss] := _uz[_etss] + _usdzaro;
      _hz[_etss] := _hz[_etss] + _hufzaro;
      _az[_etss] := _az[_etss] + _afazaro;

      _kuz[_cbsors] := _kuz[_cbsors] + _usdzaro;
      _khz[_cbsors] := _khz[_cbsors] + _hufzaro;
      _kaz[_cbsors] := _kaz[_cbsors] + _afazaro;

      // -----------------------------------------------------------------------

      _ubg[_etss] := _ubg[_etss] + _usdgbe;
      _ubp[_etss] := _ubp[_etss] + _usdpbe;
      _ubu[_etss] := _ubu[_etss] + _usdube;

      _kubg[_cbsors] := _kubg[_cbsors] + _usdgbe;
      _kubp[_cbsors] := _kubp[_cbsors] + _usdpbe;
      _kubu[_cbsors] := _kubu[_cbsors] + _usdube;

      // -----------------------------------------------------------------------

      _ukg[_etss] := _ukg[_etss] + _usdgki;
      _ukp[_etss] := _ukp[_etss] + _usdpki;
      _uku[_etss] := _uku[_etss] + _usduki;

      _kukg[_cbsors] := _kukg[_cbsors] + _usdgki;
      _kukp[_cbsors] := _kukp[_cbsors] + _usdpki;
      _kuku[_cbsors] := _kuku[_cbsors] + _usduki;

      // -----------------------------------------------------------------------

      _hbg[_etss] := _hbg[_etss] + _hufgbe;
      _hbp[_etss] := _hbp[_etss] + _hufpbe;
      _hbu[_etss] := _hbu[_etss] + _hufube;

      _khbg[_cbsors] := _khbg[_cbsors] + _hufgbe;
      _khbp[_cbsors] := _khbp[_cbsors] + _hufpbe;
      _khbu[_cbsors] := _khbu[_cbsors] + _hufube;

      // -----------------------------------------------------------------------

      _hkg[_etss] := _hkg[_etss] + _hufgki;
      _hkp[_etss] := _hkp[_etss] + _hufpki;
      _hku[_etss] := _hku[_etss] + _hufuki;

      _khkg[_cbsors] := _khkg[_cbsors] + _hufgki;
      _khkp[_cbsors] := _khkp[_cbsors] + _hufpki;
      _khku[_cbsors] := _khku[_cbsors] + _hufuki;

      // -----------------------------------------------------------------------

      _abg[_etss] := _abg[_etss] + _afagbe;
      _abp[_etss] := _abp[_etss] + _afapbe;

      _kabg[_cbsors] := _kabg[_cbsors] + _afagbe;
      _kabp[_cbsors] := _kabp[_cbsors] + _afapbe;

      // -----------------------------------------------------------------------

      _akg[_etss] := _akg[_etss] + _afagki;
      _akp[_etss] := _akp[_etss] + _afapki;
      _aku[_etss] := _aku[_etss] + _afauki;

      _kakg[_cbsors] := _kakg[_cbsors] + _afagki;
      _kakp[_cbsors] := _kakp[_cbsors] + _afapki;
      _kaku[_cbsors] := _kaku[_cbsors] + _afauki;

      ReceptorQuery.Next;  // Következö iroda adatai
    end;

  // A teljes cégre összesités ....

  wuniNullazas;
  for z := 0 to _ertektarDarab-1 do
    begin
      _usdnyito := _usdNyito + _uny[z];
      _hufnyito := _hufnyito + _hny[z];
      _afanyito := _afanyito + _any[z];

      _usdzaro := _usdzaro + _uz[z];
      _hufzaro := _hufzaro + _hz[z];
      _afazaro := _afazaro + _az[z];

      _usdgbe := _usdgbe + _ubg[z];
      _usdpbe := _usdpbe + _ubp[z];
      _usdube := _usdube + _ubu[z];

      _hufgbe := _hufgbe + _hbg[z];
      _hufpbe := _hufpbe + _hbp[z];
      _hufube := _hufube + _hbu[z];

      _usdgki := _usdgki + _ukg[z];
      _usdpki := _usdpki + _ukp[z];
      _usduki := _usduki + _uku[z];

      _hufgki := _hufgki + _hkg[z];
      _hufpki := _hufpki + _hkp[z];
      _hufuki := _hufuki + _hku[z];

      _afagbe := _afagbe + _abg[z];
      _afapbe := _afapbe + _abp[z];

      _afagki := _afagki + _akg[z];
      _afapki := _afapki + _akp[z];
      _afauki := _afauki + _aku[z];
    end;

  // A teljes cég összesitö beirása ---

  _pcs := 'INSERT INTO WUNIGYUJTO (IRODASZAM,ERTEKTAR,USDNYITO,HUFNYITO,AFANYITO,';
  _pcs := _pcs + 'USDZARO,HUFZARO,AFAZARO,USDGBE,HUFGBE,AFAGBE,USDGKI,HUFGKI,AFAGKI,';
  _pcs := _pcs + 'USDPBE,HUFPBE,AFAPBE,USDPKI,HUFPKI,AFAPKI,USDUBE,HUFUBE,';
  _pcs := _pcs + 'USDUKI,HUFUKI,AFAUKI)'+_sorveg;

  _pcs := _pcs + 'VALUES (0,0,'+inttostr(_usdnyito)+',';
  _pcs := _pcs + inttostr(_hufnyito)+','+inttostr(_afanyito)+','+inttostr(_usdzaro)+',';
  _pcs := _pcs + inttostr(_hufzaro)+','+inttostr(_afazaro)+','+inttostr(_usdgbe)+',';
  _pcs := _pcs + inttostr(_hufgbe)+','+inttostr(_afagbe)+','+inttostr(_usdgki)+',';
  _pcs := _pcs + inttostr(_hufgki)+','+inttostr(_afagki)+','+inttostr(_usdpbe)+',';
  _pcs := _pcs + inttostr(_hufpbe)+','+inttostr(_afapbe)+','+inttostr(_usdpki)+',';
  _pcs := _pcs + inttostr(_hufpki)+','+inttostr(_afapki)+','+inttostr(_usdube)+',';
  _pcs := _pcs + inttostr(_hufUbe)+','+inttostr(_usduki)+','+inttostr(_hufuki)+',';
  _pcs := _pcs + inttostr(_afauki)+')';

   with ReceptorQuery do
     begin
       Close;
       Sql.Clear;
       Sql.add(_pcs);
       ExecSql;
     end;

 // ---------- Az értéktárak összesitett adatainak beirása:

  for z := 0 to _ertektarDarab-1 do
    begin
      _usdnyito := _uny[z];
      _hufnyito := _hny[z];
      _afanyito := _any[z];

      _usdzaro := _uz[z];
      _hufzaro := _hz[z];
      _afazaro := _az[z];

      _usdgbe := _ubg[z];
      _usdpbe := _ubp[z];
      _usdube := _ubu[z];

      _hufgbe := _hbg[z];
      _hufpbe := _hbp[z];
      _hufube := _hbu[z];

      _usdgki := _ukg[z];
      _usdpki := _ukp[z];
      _usduki := _uku[z];

      _hufgki := _hkg[z];
      _hufpki := _hkp[z];
      _hufuki := _hku[z];

      _afagbe := _abg[z];
      _afapbe := _abp[z];

      _afagki := _akg[z];
      _afapki := _akp[z];
      _afauki := _aku[z];

      _aktertektar := _korzetszam[z];

      _pcs := 'INSERT INTO WUNIGYUJTO (IRODASZAM,ERTEKTAR,USDNYITO,HUFNYITO,AFANYITO,';
      _pcs := _pcs + 'USDZARO,HUFZARO,AFAZARO,USDGBE,HUFGBE,AFAGBE,USDGKI,HUFGKI,AFAGKI,';
      _pcs := _pcs + 'USDPBE,HUFPBE,AFAPBE,USDPKI,HUFPKI,AFAPKI,USDUBE,HUFUBE,';
      _pcs := _pcs + 'USDUKI,HUFUKI,AFAUKI)'+_sorveg;

      _pcs := _pcs + 'VALUES (0,'+inttostr(_aktertektar)+','+inttostr(_usdnyito)+',';
      _pcs := _pcs + inttostr(_hufnyito)+','+inttostr(_afanyito)+','+inttostr(_usdzaro)+',';
      _pcs := _pcs + inttostr(_hufzaro)+','+inttostr(_afazaro)+','+inttostr(_usdgbe)+',';
      _pcs := _pcs + inttostr(_hufgbe)+','+inttostr(_afagbe)+','+inttostr(_usdgki)+',';
      _pcs := _pcs + inttostr(_hufgki)+','+inttostr(_afagki)+','+inttostr(_usdpbe)+',';
      _pcs := _pcs + inttostr(_hufpbe)+','+inttostr(_afapbe)+','+inttostr(_usdpki)+',';
      _pcs := _pcs + inttostr(_hufpki)+','+inttostr(_afapki)+','+inttostr(_usdube)+',';
      _pcs := _pcs + inttostr(_hufUbe)+','+inttostr(_usduki)+','+inttostr(_hufuki)+',';
      _pcs := _pcs + inttostr(_afauki)+')';

      with ReceptorQuery do
        begin
          Close;
          Sql.Clear;
          Sql.add(_pcs);
          ExecSql;
        end;
    end;

  // ---------------------------------------------------------------------------

 // ---------- A KFT-K összesitett adatainak beirása:

  for z := 0 to 2 do
    begin
      _usdnyito := _Kuny[z];
      _hufnyito := _Khny[z];
      _afanyito := _Kany[z];

      _usdzaro := _Kuz[z];
      _hufzaro := _Khz[z];
      _afazaro := _Kaz[z];

      _usdgbe := _Kubg[z];
      _usdpbe := _Kubp[z];
      _usdube := _Kubu[z];

      _hufgbe := _Khbg[z];
      _hufpbe := _Khbp[z];
      _hufube := _Khbu[z];

      _usdgki := _Kukg[z];
      _usdpki := _Kukp[z];
      _usduki := _Kuku[z];

      _hufgki := _Khkg[z];
      _hufpki := _Khkp[z];
      _hufuki := _Khku[z];

      _afagbe := _Kabg[z];
      _afapbe := _Kabp[z];

      _afagki := _Kakg[z];
      _afapki := _Kakp[z];
      _afauki := _Kaku[z];

      _pcs := 'INSERT INTO WUNIGYUJTO (IRODASZAM,ERTEKTAR,USDNYITO,HUFNYITO,AFANYITO,';
      _pcs := _pcs + 'USDZARO,HUFZARO,AFAZARO,USDGBE,HUFGBE,AFAGBE,USDGKI,HUFGKI,AFAGKI,';
      _pcs := _pcs + 'USDPBE,HUFPBE,AFAPBE,USDPKI,HUFPKI,AFAPKI,USDUBE,HUFUBE,';
      _pcs := _pcs + 'USDUKI,HUFUKI,AFAUKI)'+_sorveg;

      _pcs := _pcs + 'VALUES (-1,'+inttostr(Z)+','+inttostr(_usdnyito)+',';
      _pcs := _pcs + inttostr(_hufnyito)+','+inttostr(_afanyito)+','+inttostr(_usdzaro)+',';
      _pcs := _pcs + inttostr(_hufzaro)+','+inttostr(_afazaro)+','+inttostr(_usdgbe)+',';
      _pcs := _pcs + inttostr(_hufgbe)+','+inttostr(_afagbe)+','+inttostr(_usdgki)+',';
      _pcs := _pcs + inttostr(_hufgki)+','+inttostr(_afagki)+','+inttostr(_usdpbe)+',';
      _pcs := _pcs + inttostr(_hufpbe)+','+inttostr(_afapbe)+','+inttostr(_usdpki)+',';
      _pcs := _pcs + inttostr(_hufpki)+','+inttostr(_afapki)+','+inttostr(_usdube)+',';
      _pcs := _pcs + inttostr(_hufUbe)+','+inttostr(_usduki)+','+inttostr(_hufuki)+',';
      _pcs := _pcs + inttostr(_afauki)+')';

      with ReceptorQuery do
        begin
          Close;
          Sql.Clear;
          Sql.add(_pcs);
          ExecSql;
        end;
    end;

  ReceptorTranz.Commit;
  ReceptorQuery.Close;
end;


end.
