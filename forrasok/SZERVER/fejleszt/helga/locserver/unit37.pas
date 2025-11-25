unit Unit37;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBQuery, DB, IBCustomDataSet, IBTable, Unit1,
  IBDatabase, strUtils, dateUtils, ComCtrls, Grids, DBGrids, ExtCtrls;

type
  TWuniWafaControl = class(TForm)
    WZARDBASE: TIBDatabase;
    WZARTABLA: TIBTable;
    WZARTRANZ: TIBTransaction;
    WUNITABLA: TIBTable;
    WUNIDBASE: TIBDatabase;
    WUNITRANZ: TIBTransaction;
    WZARQUERY: TIBQuery;
    WUCTRLQUERY: TIBQuery;
    WUCTRLTABLA: TIBTable;
    WUCTRLDBASE: TIBDatabase;
    WUCTRLTRANZ: TIBTransaction;
    WUNIQUERY: TIBQuery;
    WAFATABLA: TIBTable;
    WAFAQUERY: TIBQuery;
    WAFADBASE: TIBDatabase;
    wafatranz: TIBTransaction;
    CSIK: TProgressBar;
    RACS: TDBGrid;
    DataSource1: TDataSource;
    KILEPOGOMB: TBitBtn;
    Label1: TLabel;
    Label2: TLabel;
    HIBAJEGYZEK: TMemo;
    BOLTPANEL: TPanel;
    WUCTRLTABLAIRODASZAM: TSmallintField;
    WUCTRLTABLAELOHAVIUSDZARO: TIntegerField;
    WUCTRLTABLAELOHAVIHUFZARO: TIntegerField;
    WUCTRLTABLAELOHAVIAFAZARO: TIntegerField;
    WUCTRLTABLAUSDNYITO: TIntegerField;
    WUCTRLTABLAHUFNYITO: TIntegerField;
    WUCTRLTABLAAFANYITO: TIntegerField;
    WUCTRLTABLAUSDBE: TIntegerField;
    WUCTRLTABLAHUFBE: TIntegerField;
    WUCTRLTABLAAFABE: TIntegerField;
    WUCTRLTABLAUSDKI: TIntegerField;
    WUCTRLTABLAHUFKI: TIntegerField;
    WUCTRLTABLAAFAKI: TIntegerField;
    WUCTRLTABLAUSDZARO: TIntegerField;
    WUCTRLTABLAHUFZARO: TIntegerField;
    WUCTRLTABLAAFAZARO: TIntegerField;
    WUCTRLTABLAHIBAKOD: TSmallintField;
    WUCTRLTABLASTATUS: TIBStringField;
    WUCTRLTABLASZAMUSDZARO: TIntegerField;
    WUCTRLTABLASZAMHUFZARO: TIntegerField;
    WUCTRLTABLASZAMAFAZARO: TIntegerField;
    VALTOPANEL: TPanel;
    Shape1: TShape;
    Shape2: TShape;

    procedure InsertWuniMozgas;
    procedure InsertAfaMozgas;
    procedure HibaKiiro;

    procedure FormActivate(Sender: TObject);
    procedure KILEPOGOMBClick(Sender: TObject);
    procedure RACSKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);

    function Nulele(_tt: integer): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  WuniWafaControl: TWuniWafaControl;
  _pcs,_farok,_elofarok,_aktfdbpath: string;
  _aktev,_aktho,_eloev,_eloho,_uzlet: integer;
  _uzaro,_hzaro,_mzaro,_tzaro,_cc: integer;
  _unyito,_hnyito,_mNyito,_tNyito,_osszesen: integer;
  _varos,_bolt,_ttipus,_valutanem,_status: string;
  _usdbe,_usdki,_hufbe,_hufki,_afabe,_afaki,_tescobe,_tescoki: integer;
  _bankjegy,_metrobe,_metroki,_kifizetve,_ellatmany: integer;
  _ehUzaro,_ehHzaro,_ehAZaro,_anyito,_aZaro,_ube,_hbe,_abe: integer;
  _uki,_hki,_aki,_uszam,_hszam,_aszam: integer;
  _hibakod,_hbyte: byte;

  _hiba: array[1..6] of string = ('MULTHAVI USD ZÁRÓ ELTÉR AZ E-HAVI NYITÓTÓL',
                'MULTHAVI HUF ZÁRÓ ELTÉR AZ E-HAVI NYITÓTÓL','MULTHAVI ÁFA ZÁRÓ ELTÉR AZ E-HAVI NYITÓTÓL',
                'SZÁMITOTT USD ZÁRÓ ELTÉR A TÉNYLEGESTÖL',
                'SZÁMITOTT HUF ZÁRÓ ELTÉR A TÉNYLEGESTÖL',
                'SZÁMITOTT ÁFA ZÁRÓ ELTÉR A TÉNYLEGESTÖL');


implementation

{$R *.dfm}


 // ==============================================================
        procedure TWuniWafaControl.FormActivate(Sender: TObject);
 // ==============================================================

var _aktvaltonev: string;

begin

  Top := _top + 120;
  Left := _left + 140;
  Height := 530;
  Width := 750;
  
  Racs.Visible := False;
  HibaJegyzek.Visible := False;
  ValtoPanel.Visible := False;
  Label1.Repaint;
  Label2.Repaint;

  WuctrlDbase.connected := true;
  if WuctrlTranz.InTransaction then WuctrlTranz.commit;
  WuctrlTranz.StartTransaction;

  WuctrlTabla.Open;
  WuCtrlTabla.emptytable;
  if WuctrlTranz.InTransaction then WuctrlTranz.COmmit;

  WuCtrlTranz.StartTransaction;

  _aktev := yearof(date);
  _aktho := monthof(date);
  _eloev := _aktev;
  _eloho := _aktho-1;

  if _eloho=0 then
    begin
      _eloho := 12;
      dec(_eloev);
    end;

  _farok := nulele(_aktev-2000)+nulele(_aktho);
  _elofarok := nulele(_eloev-2000)+nulele(_eloho);

  Csik.Max := _irodaDarab-1;
  _qq := 0;
  while _qq<_irodaDarab do
    begin
      // Az irodaszam (uzlet) és értéktarszám beolvasása:

      Csik.Position := _qq;
      _uzlet := _IrodaSzam[_qq];
      _aktfdbPath := 'c:\receptor\database\v'+ inttostr(_uzlet)+'.fdb';
      if not FileExists(_aktfdbPAth) then
        begin
          inc(_qq);
          Continue;
        end;  


      _aktvaltonev := _irodaNev[_qq];
      // Kijelzi az aktuális bolt nevét:

      BoltPanel.Caption := _aktvaltoNev;
      BoltPanel.Repaint;

      // A multhavi havizárból ki olvassuk a havizáró értékeket:

      Wzartabla.close;
      WzarDbase.close;
      Wzardbase.DatabaseName := _aktfdbPath;
      Wzardbase.Connected := True;
      wzartabla.TableName := 'WZAR'+_ELOFAROK;

      // A multhavi zárókészletek: ---------------------------------------------

      if  wzarTabla.exists then
        begin
          _pcs := 'SELECT * FROM WZAR'+_elofarok + _sorveg;
          _pcs := _pcs + 'ORDER BY DATUM';

          with WzarQuery do
            begin
              Close;
              Sql.Clear;
              Sql.Add(_pcs);
              Open;
              Last;
            end;

          if WzarQuery.recno>0 then
            begin
              with wzarQuery do
                begin
                  _uZaro := FieldByName('USDZARO').asInteger;
                  _hZaro := FieldByname('HUFZARO').asInteger;
                  _mZaro := FieldByName('METROZARO').asInteger;
                  _tZaro := FieldByName('TESCOZARO').asInteger;
                end;

              _pcs := 'INSERT INTO WUNICONTROL (IRODASZAM,ELOHAVIUSDZARO,ELOHAVIHUFZARO,';
              _pcs := _pcs + 'ELOHAVIAFAZARO)' + _sorveg;

              _pcs := _pcs + 'VALUES ('+inttostr(_uzlet)+',';
              _pcs := _pcs + inttostr(_uZaro)+',';
              _pcs := _pcs + inttostr(_hZaro)+',';
              _pcs := _pcs + inttostr(_mzaro+_tZaro)+')';

              // A multhavi zárókészletek felirása:

              with WuCtrlQuery do
                begin
                  Close;
                  Sql.Clear;
                  Sql.Add(_pcs);
                  ExecSql;
                end;
            end;
        end;

   // ----------- E-HAVI NYITÓKÉSZLETEK ----------------------------------------

      WzarTabla.TableName := 'WZAR' + _farok;
      if not WzarTabla.Exists then
        begin
          inc(_qq);
          Continue;
        end;

      // Az ehavi nyitókészletek beolvasása:

      _pcs := 'SELECT * FROM WZAR'+ _farok + _sorveg;
      _pcs := _pcs + 'ORDER BY DATUM';

      with WzarQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          First;
        end;

      if WzarQuery.recno=0 then
        begin
          inc(_qq);
          Continue;
        end;

      // Beolvassuk az e-havi nyitókat:

      with WzarQuery do
        begin
          _uNyito := FieldByName('USDNYITO').asInteger;
          _hNyito := FieldByName('HUFNYITO').asInteger;
          _mNyito := FieldByName('METRONYITO').asInteger;
          _tNyito := FieldByName('TESCONYITO').asInteger;
        end;

      _pcs := 'SELECT * FROM WUNICONTROL' + _sorveg;
      _pcs := _pcs + 'WHERE IRODASZAM='+inttostr(_uzlet);

      with wuCtrlQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          First;
        end;

      // Ha még nincs bejegyzés: insert, ha már van UPDate nyitókészletek

      if WuCtrlQuery.Recno=0 then
        begin
          _pcs := 'INSERT INTO WUNICONTROL (IRODASZAM,USDNYITO,HUFNYITO,';
          _pcs := _pcs + 'AFANYITO)' + _sorveg;

          _pcs := _pcs + 'VALUES ('+inttostr(_uzlet)+',';
          _pcs := _pcs + inttostr(_uNyito)+',';
          _pcs := _pcs + inttostr(_hNyito)+',';
          _pcs := _pcs + inttostr(_mNyito+_tNyito)+')';
        end else
        begin
          _pcs := 'UPDATE WUNICONTROL SET USDNYITO='+INTTOSTR(_uNyito);
          _pcs := _pcs + ',HUFNYITO='+inttostr(_hNyito);
          _pcs := _pcs + ',AFANYITO='+inttostr(_mNyito+_tnyito)+_sorveg;
          _pcs := _pcs + 'WHERE IRODASZAM='+inttostr(_uzlet);
        end;

      with wuCtrlQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          ExecSql;
        end;


   // ------------ E-HAVI ZÁRÓKÉSZLETEK ----------------------------------------

      // Az ehavi zárókészletek beolvasása:

      _pcs := 'SELECT * FROM WZAR'+ _farok + _sorveg;
      _pcs := _pcs + 'ORDER BY DATUM';

      with WzarQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          Last;
        end;

       if WzarQuery.Recno=0 then
         begin
           inc(_qq);
           Continue;
         end;

      // Beolvassuk az e-havi zárókat:

      with WzarQuery do
        begin
          _uZaro := FieldByName('USDZARO').asInteger;
          _hZaro := FieldByName('HUFZARO').asInteger;
          _mZaro := FieldByName('METROZARO').asInteger;
          _tZaro := FieldByName('TESCOZARO').asInteger;
        end;

      _pcs := 'SELECT * FROM WUNICONTROL' + _sorveg;
      _pcs := _pcs + 'WHERE IRODASZAM='+inttostr(_uzlet);

      with wuCtrlQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          First;
        end;

      // Ha még nincs bejegyzés: insert, ha már van UPDate nyitókészletek

      if WuCtrlQuery.Recno=0 then
        begin
          _pcs := 'INSERT INTO WUNICONTROL (IRODASZAM,USDZARO,HUFZARO,';
          _pcs := _pcs + 'AFAZARO)' + _sorveg;

          _pcs := _pcs + 'VALUES ('+inttostr(_uzlet)+',';
          _pcs := _pcs + inttostr(_uZaro)+',';
          _pcs := _pcs + inttostr(_hZaro)+',';
          _pcs := _pcs + inttostr(_mZaro+_tZaro)+')';
        end else
        begin
          _pcs := 'UPDATE WUNICONTROL SET USDZARO='+INTTOSTR(_uZaro);
          _pcs := _pcs + ',HUFZARO='+inttostr(_hZaro);
          _pcs := _pcs + ',AFAZARO='+inttostr(_mZaro+_tZaro)+_sorveg;
          _pcs := _pcs + 'WHERE IRODASZAM='+inttostr(_uzlet);
        end;

      // ------ zárókészletek beirása ---------------------------------

      with wuCtrlQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          ExecSql;
        end;

      InsertWuniMozgas;
      InsertAfaMozgas;

      inc(_qq);
    end;
  wuctrlTranz.commit;

  // ---------------------------------------------------------------------------

  csik.Visible := false;
  Boltpanel.Visible := false;

  if wuctrlTranz.InTransaction then WuctrlTranz.Commit;
  WuctrlTranz.StartTransaction;

  WuctrlTabla.Open;
  WuctrlTabla.First;

  while not WuCtrlTabla.Eof do
    begin
      with WuctrlTabla do
        begin
          _ehUZaro := Fieldbyname('ELOHAVIUSDZARO').asInteger;
          _ehHZaro := FieldByName('ELOHAVIHUFZARO').asInteger;
          _ehAZaro := FieldByName('ELOHAVIAFAZARO').asInteger;

          _uNyito := FieldByNAme('USDNYITO').AsInteger;
          _hNyito := FieldByName('HUFNYITO').AsInteger;
          _aNyito := FieldByName('AFANYITO').asInteger;

          _uZaro := FieldByNAme('USDZARO').AsInteger;
          _hZaro := FieldByName('HUFZARO').AsInteger;
          _aZaro := FieldByName('AFAZARO').asInteger;

          _uBe := FieldByName('USDBE').asInteger;
          _hBe := FieldByName('HUFBE').asInteger;
          _aBe := FieldByName('AFABE').asInteger;

          _uKi := FieldByName('USDKI').asInteger;
          _hKi := FieldByName('HUFKI').asInteger;
          _aKi := FieldByName('AFAKI').asInteger;
        end;

      // ------------- SZÁMTAN ------------------------------------

      _uSzam := _uNyito + _uBe - _uki;
      _hSzam := _hNyito + _hBe - _hki;
      _aSzam := _aNyito + _aBe - _aki;

      _hibakod := 0;
      if _ehUzaro<>_uNyito then _hibakod := 1;
      if _ehHzaro<>_hNyito then _hibakod := _hibakod + 2;
      if _ehAZaro<>_aNyito then _hibakod := _hibaKod + 4;

      if _uSzam<>_Uzaro then _hibakod := _hibaKod + 8;
      if _hSzam<>_hZaro then _hibaKod := _hibakod + 16;
      if _aSzam<>_aZaro then _hibakod := _hibakod + 32;

      if _hibakod=0 then _status := 'OKE' else _status := '?';

      with WuCtrlTabla do
        begin
          Edit;
          FieldByName('SZAMUSDZARO').AsInteger := _uSzam;
          FieldByName('SZAMHUFZARO').asInteger := _hSzam;
          FieldByNAme('SZAMAFAZARO').asInteger := _aSzam;
          FieldByName('HIBAKOD').asInteger := _hibaKod;
          FieldByName('STATUS').asString := _status;
          Post;
        end;

      WuCtrlTabla.Next;
    end;
  WuCtrlTranz.commit;

  Hibajegyzek.Clear;
  Hibajegyzek.Visible := true;
  ValtoPanel.Visible := true;

  WuCtrlTabla.Open;
  WuCtrlTabla.First;
  Racs.Visible := True;
  Racs.SelectedIndex := 0;
  HibaKiiro;
end;

// ==========================================================
       function TWuniWafaControl.Nulele(_tt: integer): string;
// ==========================================================


begin
  result := inttostr(_tt);
  if _tt<10 then result := '0' + result;
end;

// =====================================================
         procedure TWuniWafaControl.InsertWuniMozgas;
// =====================================================


begin
  wuniDbase.close;
  Wunidbase.DatabaseName := _aktfdbPath;
  Wunidbase.Connected := True;
  wunitabla.TableName := 'WUNI' + _farok;
  if not WuniTabla.exists then exit;

  //---------------------------------

  _pcs := 'SELECT * FROM WUNI'+_farok+ _sorveg;
  _pcs := _pcs + 'WHERE (STORNO IS NULL) OR (STORNO<2)';

  with wuniQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  _usdbe := 0;
  _hufbe := 0;
  _usdki := 0;
  _hufki := 0;

  // ------------------------------------

  while not WuniQuery.eof do
    begin
      with WuniQuery do
        begin
          _ttipus := FieldByName('TRANZAKCIOTIPUS').asString;
          _bankjegy := FieldByName('BANKJEGY').asInteger;
          _valutanem := FieldByName('VALUTANEM').asstring;
        end;

      if leftstr(_ttipus,1)='+' then
        begin
          if _valutanem='USD' then _usdBe := _usdbe + _bankjegy
          else _hufbe := _hufbe + _bankjegy;
        end else
        begin
          if _valutanem='USD' then _usdKi := _usdKi + _bankjegy
          else _hufki := _hufKi + _bankjegy;
        end;

      Wuniquery.Next;
    end;

  // -----------------------------------------

  WuniQuery.Close;

  //  -------------------------------------------

  _pcs := 'SELECT * FROM WUNICONTROL WHERE IRODASZAM='+inttostr(_uzlet);
  with WuctrlQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_Pcs);
      Open;
      First;
    end;

  // ---------------------------------------------------------------------------

  if WuCtrlQuery.Recno=0 then
    begin
      _pcs := 'INSERT INTO WUNICONTROL (IRODASZAM,USDBE,HUFBE,';
      _pcs := _pcs + 'USDKI,HUFKI)';

      _pcs := _pcs + 'VALUES ('+inttostr(_uzlet)+',';
      _pcs := _pcs + inttostr(_usdBe)+',';
      _pcs := _pcs + inttostr(_hufbe)+',';
      _pcs := _pcs + inttostr(_usdki)+',';
      _pcs := _pcs + inttostr(_hufki)+')';

    end else
    begin
      _pcs := 'UPDATE WUNICONTROL SET USDBE='+inttostr(_usdbe);
      _pcs := _pcs + ',USDKI='+inttostr(_usdki);
      _pcs := _pcs + ',HUFBE='+inttostr(_hufbe);
      _pcs := _pcs + ',HUFKI='+inttostr(_hufki)+_sorveg;
      _pcs := _pcs + 'WHERE IRODASZAM='+inttostr(_uzlet);
    end;

  // ---------------------------------------------------------------------------

  with WuctrlQuery do
    begin
      CLose;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;
end;

// ===================================================
        procedure TWuniWafaControl.InsertAfaMozgas;
// ===================================================


begin

  _metrobe := 0;
  _metroki := 0;
  _tescoBe := 0;
  _tescoKi := 0;

  WafaTabla.Close;
  wafaDbase.close;
  Wafadbase.DatabaseName := _aktfdbPath;
  Wafadbase.Connected := True;
  WafaTabla.TableName := 'WAFA'+_FAROK;
  if wafaTabla.exists then
    begin
      _pcs := 'SELECT * FROM WAFA'+_farok+ _sorveg;
      _pcs := _pcs + 'WHERE (STORNO IS NULL) OR (STORNO<2)';
      with wafaQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          First;
        end;

      _metrobe := 0;
      _metroki := 0;

      while not WafaQuery.eof do
        begin
          with WafaQuery do
            begin
              _ttipus := FieldByName('TRANZAKCIOTIPUS').asString;
              _kifizetve := FieldByName('KIFIZETVE').asInteger;
              _ellatmany := FieldByName('ELLATMANY').asInteger;
            end;
          if leftstr(_ttipus,1)='+' then _metrobe := _metrobe + _kifizetve + _ellatmany
          else _metroki := _metroki + _kifizetve + _ellatmany;

          WafaQuery.Next;
        end;
      WafaQuery.Close;
    end;

  // ------------------------------------------------------------

  WafaTabla.Close;
  WafaTabla.TableName := 'TESC'+_FAROK;
  if wafaTabla.exists then
    begin
      _pcs := 'SELECT * FROM TESC'+_farok;

      with wafaQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          First;
        end;

      while not WafaQuery.eof do
        begin
          with WafaQuery do
            begin
              _ttipus := FieldByName('TIPUS').asString;
              _OSSZESEN := FieldByName('OSSZESEN').asInteger;
            end;
          if (_ttipus)='B' then _tescobe := _tescobe + _osszesen
          else _tescoki := _tescoki + _osszesen;

          WafaQuery.Next;
        end;
      WafaQuery.Close;
    end;

  // ==============================================================

   _pcs := 'SELECT * FROM WUNICONTROL WHERE IRODASZAM='+inttostr(_uzlet);

  with WuctrlQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_Pcs);
      Open;
      First;
    end;

  if WuCtrlQuery.Recno=0 then
    begin
      _pcs := 'INSERT INTO WUNICONTROL (IRODASZAM,AFABE,AFAKI)'+_sorveg;

      _pcs := _pcs + 'VALUES ('+inttostr(_uzlet)+',';
      _pcs := _pcs + inttostr(_MetroBe+_tescobe)+',';
      _pcs := _pcs + inttostr(_metroki+_tescoki)+')';
    end else
    begin
      _pcs := 'UPDATE WUNICONTROL SET AFABE='+inttostr(_METRObe+_tescobe);
      _pcs := _pcs + ',AFAKI='+inttostr(_METROKI+_tescoki)+_sorveg;
      _pcs := _pcs + 'WHERE IRODASZAM='+inttostr(_uzlet);
    end;

  with WuctrlQuery do
    begin
      CLose;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;
end;

 // ==============================================================
         procedure TWuniWafaControl.KILEPOGOMBClick(Sender: TObject);
 // ==============================================================

begin
  WuCtrlTabla.Close;
  Modalresult := 1;
end;

// =======================================
       procedure TWuniWafaControl.HibaKiiro;
// =======================================

var _hbyte,_jelzo: byte;
    _hibaszo: string;

begin
  _hibakod := WuCtrlTabla.FieldByName('HIBAKOD').asInteger;
  _uzlet := WuCtrlTabla.FieldByName('IRODASZAM').asInteger;
  ValtoPanel.Caption := _irodanev[_uzlet];

  HibaJegyzek.Clear;

  if _hibaKod =0 then
    begin
      with HibaJegyzek do
        begin
          Color := $A0FFFF;
          Font.Color := clNavy;
          Font.Style := [];
          Lines.Add('MINDEN RENDBEN');
        end;
      ActiveControl := Racs;
      Exit;
    end;
  with Hibajegyzek do
    begin
      Color := $8040FF;
      Font.Color := clYellow;
      Font.Style := [fsBold];
    end;

  _cc := 6;
  _hbyte := 64;
  while _cc>0 do
    begin
      _hbyte := _hbyte shr 1;
      _jelzo := _hbyte and _hibakod;
      if _jelzo>0 then
        begin
          _hibaszo := _hiba[_cc];
          Hibajegyzek.Lines.add(_hibaszo);
        end;
      dec(_cc);
    end;
  ActiveControl := Racs;
end;

procedure TWuniWafaControl.RACSKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  HibaKiiro;
end;

end.
