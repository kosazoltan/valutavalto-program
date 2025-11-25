unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  IBTable, strutils, ExtCtrls, ComCtrls;

type
  TAdatFeltoltes = class(TForm)

    Kilepo     : TTimer;
    Label1     : TLabel;

    RemoteTabla: TIBTable;
    RemoteQuery: TIBQuery;
    RemoteDbase: TIBDatabase;
    RemoteTranz: TIBTransaction;

    BizlatQuery: TIBQuery;
    BizlatDbase: TIBDatabase;
    BizlatTranz: TIBTransaction;

    I1         : TPanel;
    I2         : TPanel;
    I3         : TPanel;
    I4         : TPanel;
    I5         : TPanel;
    I6         : TPanel;

    Ok1        : TPanel;
    Ok2        : TPanel;
    Ok3        : TPanel;
    Ok4        : TPanel;
    Ok5        : TPanel;
    Ok6        : TPanel;

    Panel1     : TPanel;
    UzenoPanel : TPanel;

    Shape1: TShape;
    CSIK: TProgressBar;
    KISUGYQUERY: TIBQuery;
    KISUGYDBASE: TIBDatabase;
    KISUGYTRANZ: TIBTransaction;

    procedure FormActivate(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure Getugyfeladatok;
    procedure GyujtoParancs(_ukaz: string);
    procedure IDoszakBeolvasas;
    procedure IrodaBeolvasas;
    procedure TombNullazas;
    procedure VTEmpBeolvasas;

    function AdatokBegyujtese: integer;
    function Ezertektar(_et: byte): boolean;
    function Kitomorito(_s: string): string;
    function Noirszam(_s: string): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ADATFELTOLTES: TADATFELTOLTES;
  _host: string = '185.43.207.99';

  _biz,_dat,_ido,_ptn,_pid,_ntb,_dnm,_unm,_uan,_usi: array[1..32768] of string;
  _ush,_ulc,_utv,_cbt,_kvn,_mbb,_kvb,_mbn,_uti,_prn: array[1..32768] of string;
  _iso,_cgn,_oki,_mbi,_mbh,_mba,_thc,_all,_mal,_okt: array[1..32768] of string;
  _azo,_mot,_maz,_cor,_ptc,_ftv: array[1..32768] of string;

  _fiz,_kdj,_ptr,_srs,_bjy,_arf,_els,_oft,_emx,_vdb: array[1..32768] of integer;
  _sft,_krz: array[1..32768] of integer;

  _penztarnev,_penztarcim,_cegbetu: array[1..168] of string;
  _korzet: array[1..168] of byte;

  _ezJogi: boolean;

  _toldatums,_igdatums,_bf,_bt,_pcs,_aktcegbetu,_szm,_lcim,_mbdss: string;
  _sorveg: string = chr(13)+chr(10);

  _top,_left,_mresult,_pp,_blokkdarab,_aktels,_aktarf,_recdarab,_qq: word;
  _width,_kertev,_kertho,_tolnap,_ignap: word;
  _pt,_wp,_akttet,_aktpenztar,_aktkorzet,_ertektar,_kezdobetu,_nww: byte;



  _farok,_aktfdbPath,_plomba,_p2cs,_bizonylat,_pttipus,_nevtabla: string;
  _aktdat,_aktido,_aktntab,_pts,_aktid,_aktval,_aktbiz,_evtizeds: string;
  _remDataPath,_aktTabla,_uzcim,_ptarcim,_fdbpath,_szido,_sszm: string;
  _ugyfeltipus,_kisugyfPath,_aktugyftip: string;

  _sorszam,_aktkdj,_aktbjy,_aktfte,_aktfiz,_aktsrs,_recno,_code: integer;
  _aktsors: integer;

function adatgyujtorutin: integer; stdcall;

implementation

uses Unit1;

{$R *.dfm}

// =============================================================================
             function adatgyujtorutin: integer; stdcall;
// =============================================================================

begin
  Adatfeltoltes := TAdatfeltoltes.Create(Nil);
  result := Adatfeltoltes.ShowModal;
  Adatfeltoltes.free;
end;


// =============================================================================
           procedure TADATFELTOLTES.FormActivate(Sender: TObject);
// =============================================================================

begin

  _width := Screen.Monitors[0].Width;
  _left := round((_width-312)/2);

  top := 290;
  left := _left;
  Repaint;

  // -----------------------------------
  // Az összes hárombetüs változó kinullázása

  I1.Visible := True;
  i1.repaint;
  TombNullazas;
  Ok1.Visible := True;
  Ok1.repaint;

  // --------------------------------------
  // Beolvassa az összes pénztár nevét,körzetét,kft-jét: (index = üzlet)

  i2.Visible := True;
  i2.repaint;
  IrodaBeolvasas;
  ok2.Visible := True;
  ok2.repaint;

  // ----------------------------------------
  // Vtemp-bõl beolvassa a paramétereket:
  //    pttipus: P=csak pénztár, K=egy körzet, C=egy kft  adatai
  // _akpenztar(1..168), _aktkorzet(10,20..145,180) _aktcegbetu (B vagy Z)

  i3.Visible := True;
  i3.repaint;
  Vtempbeolvasas;

  // -------------------------------
  // Az IDOSZAK táblából kiolvassa: toldatums,igdatums,kertev,kertho
  //                                tolnap, ignap

  IdoszakBeolvasas;
  ok3.Visible := True;
  ok3.repaint;

  _mResult := AdatokBegyujtese;  // 1 vagy -1
  Kilepo.enabled := true;
end;


/////////////////////  INNWN AZ UJ PROGRAM //////////////////////////////////

// =============================================================================
             function TAdatFeltoltes.Adatokbegyujtese: integer;
// =============================================================================

begin
  i4.Visible := True;
  i4.repaint;

  result := -1;
  GyujtoParancs('DELETE FROM ADATGYUJTO');

  _farok := midstr(_toldatums,3,2)+midstr(_toldatums,6,2);
  _bf := 'BF' + _farok;
  _bt := 'BT' + _farok;

  _pcs := 'SELECT FEJ.*, TET.*' + _sorveg;
  _pcs := _pcs + 'FROM ' + _bf + ' FEJ JOIN ' + _bt + ' TET' + _sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM' + _sorveg;
  _pcs := _pcs + 'WHERE (FEJ.DATUM>=' + chr(39) + _toldatums + chr(39) + ')';
  _pcs := _pcs + ' AND (FEJ.DATUM<='+chr(39)+_igdatums+chr(39) + ')';
  _pcs := _pcs + ' AND (FEJ.STORNO=1) AND (PLOMBASZAM>' + chr(39) + '@' + chr(39) + ')';
  _pt := 1;

  _pt := 1;
  csik.max := 168;
  while _pt<=168 do
    begin
      Csik.Position := _pt;

      // Ilyen számú pénztár nincs !
      if _penztarnev[_pt]='-' then
        begin
          inc(_pt);
          Continue;
        end;

      // Értéktárban nincs forgalom !

      if ezErtektar(_pt) then
        begin
          inc(_pt);
          continue;
        end;

      // Ha csak pénztárt akarunk listázni csak az aktpenztar jó !

      if _ptTipus='P' then
        begin
          if _pt<>_aktpenztar then
             begin
               inc(_pt);
               Continue;
             end;
        end;

      // Ha egy körzetet akarunk listázni, csak az aktkörzet jó !

      if _pttipus='K' then
        begin
          if _korzet[_pt]<>_aktkorzet then
            begin
              inc(_pt);
              Continue;
            end;
        end;

      // Ha egy KFT-t akarunk listázni, csak az akttcégbetü (vagy Mind) jó !

      If _pttipus='C' then
        begin

          // Ha aktcegbetu='A(LL)' minden pénztárt listázni kell

          if _aktcegbetu<>'A' then
            begin

              // Csak az  aktcegbetu kft jó !
              if _cegbetu[_pt]<>_aktcegbetu then
                begin
                  inc(_pt);
                  Continue;
                end;
            end;
        end;


      // Ez a pénztár végre már letölthetö:

      _aktfdbpath := _HOST +':c:\receptor\database\v' + inttostr(_pt)+'.FDB';
      if _pt>150 then _aktfdbpath := _HOST +':c:\cartcash\database\v' + inttostr(_pt)+'.FDB';

      with RemoteDbase do
        begin
          Close;
          Databasename := _aktfdbpath;   // A penztár adatbázisdára kapcsol
          Connected := true;
        end;

      RemoteTabla.Close;
      RemoteTabla.Tablename := _bf;

      // Ha a kért havi adatbázis hiányzik, akkor ez a pénztár sem kell !

      if not RemoteTabla.Exists then
        begin
          RemoteDbase.close;
          inc(_pt);
          Continue;
        end;

      // Megnyitja a kért havi adatbázis blokkfejeit és tételeit:

      with RemoteQuery do
        begin
          Close;
          Sql.clear;
          Sql.add(_pcs);
          Open;
          _recno := recno;
        end;

      // Ha az adatbázis üres, akkor ez a pénztar sem kell pénztár:

      if _recno=0 then
        begin
          RemoteQuery.close;
          RemoteDbase.close;
          inc(_pt);
          Continue;
        end;

      // végre egy normális feldolgozandó pénztár !
      // kiolvassa azokat a rekordokat, ahol Plombaszam egy Nevtabla+sorszam

      UzenoPanel.Caption := _penztarnev[_pt];
      UzenoPanel.Repaint;
      while not RemoteQuery.eof do
        begin
          _ugyfeltipus := RemoteQuery.FieldByNAme('UGYFELTIPUS').asString;
          _plomba := trim(RemoteQuery.fieldByName('PLOMBASZAM').asString);
          _wp     := length(_plomba);

          // Ha plomba nem a nevtabla+sorszam -> jöhet e következõ rekord:
          if _wp<5 then
            begin
              RemoteQuery.next;
              continue;
            end;

          // Kiszámitjuk a nevtábla sorszámát:

          _szm := midstr(_plomba,5,_wp-4);
          Val(_szm,_sorszam,_code);
          if _code<>0 then _sorszam := 0;

          // Ha itt a sorszám zéró, akkor jöhet a következõ rekord:

          if _sorszam=0 then
            begin
              RemoteQuery.next;
              continue;
            end;

          //  Kifejti a névtáblát:
          // Ha a névtabla nem JOGI vagy más értékes NEVTABLA akkor next:

          _nevtabla := leftstr(_plomba,4);

          // Valódi névtábla kell hogy legyen !
          if (_nevtabla<>'JOGI') AND (midstr(_nevtabla,2,3)<>'NEV') then
            begin
              RemoteQuery.next;
              Continue;
            end;

          _bizonylat := trim(RemoteQuery.FieldByNAme('BIZONYLATSZAM').asString);
          if _bizonylat='' then
            begin
              RemoteQuery.next;
              Continue;
            end;

          // Végre ez a rekord érvényes - Lépteti a sorszám számlálót

          inc(_pp);

          _uti[_pp] := _ugyfeltipus;
          _biz[_pp] := _bizonylat;
          _ptr[_pp] := _pt;
          _krz[_pp] := _korzet[_pt];
          _cbt[_pp] := _cegbetu[_pt];
          _ptn[_pp] := _penztarnev[_pt];
          _ptc[_pp] := _penztarcim[_pt];

          with RemoteQuery do
            begin
              // A fõtömbbe beirja a fejblokk értékes adatokat:

              _dat[_pp] := fieldbyname('DATUM').asString;
              _ido[_pp] := FieldByName('IDO').asString;
              _fiz[_pp] := FieldByNAme('OSSZESEN').asInteger;
              _kdj[_pp] := FieldByName('KEZELESIDIJ').asInteger;
              _prn[_pp] := trim(FieldByNAme('PENZTAROSNEV').asString);
              _pid[_pp] := trim(FieldByNAme('IDKOD').asString);
              _dnm[_pp] := FieldByNAme('VALUTANEM').asString;
              _bjy[_pp] := FieldByNAme('BANKJEGY').asInteger;
              _arf[_pp] := FieldByNAme('ARFOLYAM').asInteger;
              _els[_pp] := FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
              _oft[_pp] := FieldByNAme('FORINTERTEK').asInteger;

            end;

          // A fõtömbbe beirja a névtáblát vagy sorszámát

          _ntb[_pp] := _nevtabla;
          _srs[_pp] := _sorszam;

          RemoteQuery.next;
        end;
      RemoteQuery.close;
      RemoteDbase.close;

      // Jöhet e következõ pénztár:

      inc(_pt);
    end;

  // --------------------------------------------------

  ok4.Visible := True;
  ok4.repaint;

  // Összesen ennyi rekord van az adatgyujtöben:
  _recdarab := _pp;

  Csik.Max := _recdarab;

  // Ha nincs egy rekord sem, akkor nincs adat
  if _recDarab=0 then exit;

  GetugyfelAdatok;

  // ----------------------------------------------------

   i6.Visible := true;
   i6.repaint;

   // --------------------------------------------------
   // A begyüjtött adatokat beirja az adatgyutõbe:

   BizlatDbase.Connected := True;
   if BizlatTranz.InTransaction then BizlatTranz.commit;
   BizlatTranz.StartTransaction;

   _qq := 1;
   while _qq<=_recDarab do
     begin
       Csik.Position := _qq;
       _pcs := 'INSERT INTO ADATGYUJTO (BIZONYLATSZAM,DATUM,IDO,FIZETENDO,';
       _pcs := _pcs + 'KEZELESIDIJ,PENZTARSZAM,PENZTARNEV,SORSZAM,PROSID,';
       _pcs := _pcs + 'NEVTABLA,VALUTANEM,BANKJEGY,ARFOLYAM,ELSZAMARF,FTERTEK,';
       _pcs := _pcs + 'NEV,ANYJANEVE,SZULETESIIDO,SZULETESIHELY,LAKCIM,';
       _pcs := _pcs + 'UTOLSOVALTAS,EVIMAX,VALTASDB,OSSZESVALTAS,KORZET,KFT,';
       _pcs := _pcs + 'KEPVISNEV,MBBEO,KEPVISBEO,MEGBIZOTTNEVE,UGYFELTIPUS,';
       _pcs := _pcs + 'PENZTAROSNEV,ISO,MARKER,CEGNEV,OKIRATSZAM,MBSZULIDO,';
       _pcs := _pcs + 'MBSZULHELY,MBANYJA,TELEPHELYCIM,ALLAMPOLGAR,';
       _pcs := _pcs + 'MBALLAMPOLGAR,OKMANYTIPUS,AZONOSITO,MBOKMTIPUS,';
       _pcs := _pcs + 'MBAZONOSITO,CEGORSZAG,PENZTARCIM,FOTEVEKENYSEG)'+_sorveg;

       _pcs := _pcs + 'VALUES (' + chr(39) + _biz[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _dat[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _ido[_qq] + chr(39) + ',';
       _pcs := _pcs + inttostr(_fiz[_qq]) + ',';
       _pcs := _pcs + inttostr(_kdj[_qq]) + ',';
       _pcs := _pcs + inttostr(_ptr[_qq]) + ',';
       _pcs := _pcs + chr(39) + _ptn[_qq] + chr(39) + ',';
       _pcs := _pcs + inttostr(_srs[_qq]) + ',';
       _pcs := _pcs + chr(39) + _pid[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _ntb[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _dnm[_qq] + chr(39) + ',';
       _pcs := _pcs + inttostr(_bjy[_qq]) + ',';
       _pcs := _pcs + inttostr(_arf[_qq]) + ',';
       _pcs := _pcs + inttostr(_els[_qq]) + ',';
       _pcs := _pcs + inttostr(_oft[_qq]) + ',';
       _pcs := _pcs + chr(39) + _unm[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _uan[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _usi[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _ush[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _ulc[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _utv[_qq] + chr(39) + ',';
       _pcs := _pcs + inttostr(_emx[_qq]) + ',';
       _pcs := _pcs + inttostr(_vdb[_qq]) + ',';
       _pcs := _pcs + inttostr(_sft[_qq]) + ',';
       _pcs := _pcs + inttostr(_krz[_qq]) + ',';
       _pcs := _pcs + chr(39) + _cbt[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _kvn[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _mbb[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _kvb[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _mbn[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _uti[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _prn[_qq] + chr(39) + ',';
       _PCS := _pcs + chr(39) + _iso[_qq] + chr(39) + ',';
       _pcs := _pcs + '1,';
       _pcs := _pcs + chr(39) + _cgn[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _oki[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _mbi[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _mbh[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _mba[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _thc[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _all[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _mal[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _okt[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _azo[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _mot[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _maz[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _cor[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _ptc[_qq] + chr(39) + ',';
       _pcs := _pcs + chr(39) + _ftv[_qq] + chr(39) + ')';

       with BizlatQuery do
         begin
           Close;
           sql.clear;
           sql.add(_pcs);
           Execsql;
         end;
      inc(_qq);
    end;
  BizlatTranz.commit;
  BizlatDbase.close;
  ok6.Visible := true;
  ok6.repaint;

  UzenoPanel.Caption := 'AZ ADATOK FELIRÁSA ELKÉSZÜLT';
  sleep(2500);
  result := 1;
end;


// =============================================================================
             procedure TAdatfeltoltes.GyujtoParancs(_ukaz: string);
// =============================================================================

begin
  BizlatDbase.Connected := true;
  if BizlatTranz.InTransaction then BizlatTranz.Commit;
  BizlatTranz.StartTransaction;
  with BizlatQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_ukaz);
      Execsql;
    end;
  BizlatTranz.Commit;
  BizlatDbase.close;
end;

// =============================================================================
               procedure TadatFeltoltes.Getugyfeladatok;
// =============================================================================

begin
  i5.visible := True;
  i5.repaint;

  _kisugyfPath := _host+':C:\receptor\database\kisugyfel.fdb';
  with KisugyDbase do
    begin
      Close;
      DatabaseName := _kisugyfPath;
      Connected := True;
    end;

  _evtizeds := midstr(_toldatums,3,2);
  _remDataPath:= _host+':C:\receptor\database\ugyfel'+_evtizeds+'.fdb';

  RemoteDbase.DatabaseName := _remDataPath;
  RemoteDbase.Connected    := True;

  Csik.max := _recdarab;

  _qq := 1;
  while _qq<=_recDarab do
    begin
      Csik.Position := _qq;
      _aktTabla   := _ntb[_qq];
      _aktSors    := _srs[_qq];
      _aktugyftip := _uti[_qq];

      _pcs := 'SELECT * FROM ' + _akttabla+ ' WHERE SORSZAM='+inttostr(_aktSors);

      if _aktugyftip='K' then
        begin
          with KisUgyQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
              _recno := recno;
            end;
          if _recno>0 then
            begin
              _unm[_qq] := trim(KisUgyQuery.fieldByName('NEV').asString);
              _szido    := trim(KisUgyQuery.FieldByName('SZULIDO').asString);
              _usi[_qq] := kitomorito(_szido);
              _ush[_qq] := trim(KisUgyQuery.FieldByName('SZULHELY').asString);
              _utv[_qq] := KisugyQuery.fieldbyname('LASTDATE').asString;
            end;
          KisUgyQuery.close;
          inc(_qq);
          Continue;
        end;


      with RemoteQuery do
        begin
          Close;
          Sql.clear;
          sql.add(_pcs);
          Open;
          _recno := recno;
        end;

      if _recno>0 then
        begin
          if _aktugyftip='N' then
            begin
              _unm[_qq] := trim(RemoteQuery.FieldByName('NEV').asString);
              _uan[_qq] := trim(RemoteQuery.FieldByName('ANYJANEVE').asString);
              _szido    := trim(RemoteQuery.FieldByName('SZULETESIIDO').asString);
              _usi[_qq] := kitomorito(_szido);
              _ush[_qq] := trim(RemoteQuery.FieldByName('SZULETESIHELY').asString);
              _all[_qq] := trim(RemoteQuery.FieldByNAme('ALLAMPOLGAR').AsString);
              _lcim := trim(RemoteQuery.FieldByName('LAKCIM').asString);
              _ulc[_qq] := noirszam(_lcim);
              _okt[_qq] := trim(Remotequery.FieldByName('OKMANYTIP').AsString);
              _azo[_qq] := trim(RemoteQuery.FieldByNAme('AZONOSITO').AsString);
              _ezJogi   := False;
             end;
          if _aktugyftip = 'J' then
            begin
              _cgn[_qq] := trim(RemoteQuery.FieldByName('JOGISZEMELYNEV').asString);
              _thc[_qq] := trim(RemoteQuery.FieldByName('TELEPHELYCIM').asString);
              _oki[_qq] := trim(RemoteQuery.FieldByName('OKIRATSZAM').asString);
              _ftv[_qq] := trim(RemoteQuery.FieldByName('FOTEVEKENYSEG').asString);
              _mbn[_qq] := trim(RemoteQuery.FieldByName('MEGBIZOTTNEVE').asString);
              _kvn[_qq] := trim(RemoteQuery.FieldByName('KEPVISELONEV').AsString);
              _mbb[_qq] := trim(RemoteQuery.fieldByNAme('MEGBIZOTTBEOSZTASA').asString);
              _kvb[_qq] := trim(RemoteQuery.FieldByNAme('KEPVISBEO').AsString);
              _cor[_qq] := RemoteQuery.FieldByName('ISO').asString;
              _ezJogi   := True;
              _mbdss    := trim(RemoteQuery.FieldByName('MBDATASORSZAM').asstring);
            end;

         UzenoPanel.Caption := _unm[_qq];
         UzenoPanel.repaint;
          _iso[_qq] := RemoteQuery.Fieldbyname('ISO').asString;
          _utv[_qq] := RemoteQuery.fieldbyname('DATUM').asString;
          _emx[_qq] := RemoteQuery.FieldByNAme('EVIMAX').asInteger;
          _vdb[_qq] := RemoteQuery.FieldByNAme('TRANZAKCIODB').asInteger;
          _sft[_qq] := RemoteQuery.FieldByName('FORINTOSSZEG').asInteger;
        end;
      RemoteQuery.close;

      if (_ezjogi) and (midstr(_mbdss,2,3)='NEV') then
        begin
          _nevtabla := leftstr(_mbdss,4);
          _nww  := length(_mbdss);
          _sszm := midstr(_mbdss,5,_nww-4);

          _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
          _pcs := _pcs + 'WHERE SORSZAM='+_sszm;
          with RemoteQuery do
            begin
              Close;
              sql.clear;
              Sql.add(_pcs);
              Open;
              _recno := recno;
            end;
          if _recno>0 then
            begin
              _szido := trim(RemoteQuery.fieldByNAme('SZULETESIIDO').asString);
              _mbi[_qq] := kitomorito(_szido);
              _mbh[_qq] := trim(RemoteQuery.FieldbyName('SZULETESIHELY').AsString);
              _mba[_qq] := trim(RemoteQuery.FieldByName('ANYJANEVE').asString);
              _mal[_qq] := trim(RemoteQuery.FieldByNAme('ALLAMPOLGAR').asString);
              _mot[_qq] := trim(RemoteQuery.FieldByNAme('OKMANYTIP').AsString);
              _maz[_qq] := trim(RemoteQuery.FieldByNAme('AZONOSITO').AsString);
            end;
          RemoteQuery.close;
        end;
      inc(_qq);
    end;
  KisugyDbase.close;
  Remotedbase.close;
  ok5.Visible := True;
  ok5.repaint;
end;


// =============================================================================
           function TAdatFeltoltes.ezertektar(_et: byte): boolean;
// =============================================================================

begin
  result := True;
  if (_et=10) or (_et=20) or (_et=40) or (_et=50) or (_et=63) then exit;
  if (_et=85) or (_et=120) or (_et=145) then exit;
  result := False;
end;


// =============================================================================
           procedure TADATFELTOLTES.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := false;
  Modalresult := _mResult;
end;

// =============================================================================
                      procedure TAdatfeltoltes.IrodaBeolvasas;
// =============================================================================

var _uzlet,i: byte;
    _uznev: string;

begin
  For i := 1 to 168 do
    begin
      _penztarnev[i] := '-';
      _cegbetu[i]    := '-';
      _korzet[i]     := 0;
    end;

  _pcs := 'SELECT * FROM IRODAK'  + _sorveg;
  _pcs := _pcs + 'WHERE CLOSED=' + chr(39) + 'N' + CHR(39);

  _fdbpath := _host + ':C:\receptor\database\receptor.fdb';

  with RemoteDbase do
    begin
      Close;
      DatabaseName := _fdbpath;
      Connected := True;
    end;

  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_PCS);
      Open;
    end;

  while not RemoteQuery.eof do
    begin
      _uzlet := RemoteQuery.fieldByName('UZLET').asInteger;
      _uznev := trim(RemoteQuery.FieldByNAme('KESZLETNEV').asString);
      _uzcim := trim(RemoteQuery.FieldByNAme('IRODACIM').AsString);
      _ertektar := RemoteQuery.FieldByNAme('ERTEKTAR').asInteger;

      _penztarnev[_uzlet] := _uzNev;
      _penztarcim[_uzlet] := _uzCim;
      _korzet[_uzlet]     := _ertektar;
      _cegbetu[_uzlet]    := 'B';

      RemoteQuery.next;
    end;

   RemoteQuery.close;
   RemoteDbase.close;

   // --------------------------------------------------------

  _fdbpath := _host + ':C:\cartcash\database\artcash.fdb';

  with RemoteDbase do
    begin
      Close;
      DatabaseName := _fdbPath;
      Connected := True;
    end;

  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not RemoteQuery.eof do
    begin
      _uzlet := RemoteQuery.fieldByName('UZLET').asInteger;
      _uznev := trim(RemoteQuery.FieldByNAme('KESZLETNEV').asString);
      _uzcim := trim(RemoteQuery.FieldByNAme('IRODACIM').AsString);

      _korzet[_uzlet]     := 180;
      _cegbetu[_uzlet]    := 'Z';
      _penztarnev[_uzlet] := _uzNev;
      _penztarcim[_uzlet] := _uzcim;
      RemoteQuery.next;
    end;

  RemoteQuery.close;
  RemoteDbase.close;
end;

// =============================================================================
              procedure TAdatfeltoltes.VTempBeolvasas;
// =============================================================================

begin
  BizlatDbase.connected := True;
  with BizlatQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;

      _pttipus    := FieldByName('PTTIPUS').asString;
      _aktpenztar := FieldByNAme('AKTPENZTAR').asInteger;
      _aktkorzet  := FieldByNAme('AKTKORZET').asInteger;
      _aktcegbetu := FieldByName('AKTCEGBETU').asString;
      close;
    end;

  BizlatDbase.close;
end;

// =============================================================================
            procedure TAdatfeltoltes.IdoszakBeolvasas;
// =============================================================================

begin
  BizlatDbase.connected := True;
  with BizlatQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM IDOSZAK');
      Open;
      _toldatums := FieldByNAme('TOLSTRING').asString;
      _igdatums  := FieldByNAme('IGSTRING').asString;
      _kertev    := FieldByNAme('KERTEV').asInteger;
      _kertho    := FieldByNAme('KERTHO').asInteger;
      _tolnap    := FieldByNAme('TOLNAP').asInteger;
      _ignap     := FieldByNAme('IGNAP').asInteger;
      Close;
    end;
  BizlatDbase.close;
end;

// =============================================================================
            procedure TAdatfeltoltes.TombNullazas;
// =============================================================================

begin
  _qq := 1;
  while _qq<=32768 do
    begin
      _biz[_qq] := '';
      _dat[_qq] := '';
      _ido[_qq] := '';
      _ptn[_qq] := '';
      _pid[_qq] := '';
      _ntb[_qq] := '';
      _dnm[_qq] := '';
      _unm[_qq] := '';
      _uan[_qq] := '';
      _usi[_qq] := '';
      _ush[_qq] := '';
      _ulc[_qq] := '';
      _utv[_qq] := '';
      _cbt[_qq] := '';
      _kvn[_qq] := '';
      _mbb[_qq] := '';
      _kvb[_qq] := '';
      _mbn[_qq] := '';
      _uti[_qq] := '';
      _prn[_qq] := '';
      _iso[_qq] := '';
      _cgn[_qq] := '';
      _oki[_qq] := '';
      _mbi[_qq] := '';
      _mbh[_qq] := '';
      _thc[_qq] := '';
      _all[_qq] := '';
      _mal[_qq] := '';
      _okt[_qq] := '';
      _azo[_qq] := '';
      _mot[_qq] := '';
      _maz[_qq] := '';
      _cor[_qq] := '';
      _ptc[_qq] := '';
      _ftv[_qq] := '';

      _fiz[_qq] := 0;
      _kdj[_qq] := 0;
      _ptr[_qq] := 0;
      _srs[_qq] := 0;
      _bjy[_qq] := 0;
      _arf[_qq] := 0;
      _els[_qq] := 0;
      _oft[_qq] := 0;
      _emx[_qq] := 0;
      _vdb[_qq] := 0;
      _sft[_qq] := 0;
      _krz[_qq] := 0;
      inc(_qq);
    end;
end;

// =============================================================================
         function TAdatfeltoltes.Noirszam(_s: string): string;
// =============================================================================

var _px,_wws: byte;

begin
  result := _s;
  if _s='' then exit;

  _kezdobetu := ord(_s[1]);
  if _kezdobetu>64 then exit;

  _px := 1;
  while _px<6 do
    begin
      if ord(_s[_px])=32 then break;
      inc(_px);
    end;

  _wws := length(_s);
  result := midstr(_s,_px+1,_wws-_px);
end;

// =============================================================================
            function TadatFeltoltes.Kitomorito(_s: string): string;
// =============================================================================

begin
  result := _s;
  if length(_s)<>8 then exit;

  result := leftstr(_s,4)+'.'+midstr(_s,5,2)+'.'+midstr(_s,7,2);
end;
end.


