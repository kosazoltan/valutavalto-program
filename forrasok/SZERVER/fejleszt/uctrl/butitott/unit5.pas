unit Unit5;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  ExtCtrls, Grids, Calendar, dateutils, strutils, ComCtrls, IBTable;

type
  Timportform = class(TForm)
    IMPQUERY: TIBQuery;
    IMPDBASE: TIBDatabase;
    IMPTRANZ: TIBTransaction;
    NAPTARPANEL: TPanel;
    NAPTAR: TCalendar;
    KERTNAPPANEL: TPanel;
    ELOHOGOMB: TBitBtn;
    KOVHOGOMB: TBitBtn;
    DATUMOKEGOMB: TBitBtn;
    VISSZAGOMB: TBitBtn;
    Shape1: TShape;
    progresspanel: TPanel;
    fopanel: TPanel;
    MEMOPANEL: TPanel;
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    UFQUERY: TIBQuery;
    UFDBASE: TIBDatabase;
    UFTRANZ: TIBTransaction;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    ARTQUERY: TIBQuery;
    ARTDBASE: TIBDatabase;
    ARTTRANZ: TIBTransaction;
    BIZQUERY: TIBQuery;
    BIZDBASE: TIBDatabase;
    BIZTRANZ: TIBTransaction;
    uzenopanel: TPanel;
    Panel1: TPanel;
    CSIK: TProgressBar;
    Memo1: TMemo;
    VTABLA: TIBTable;

    procedure IrodakBetoltese;
    procedure BazisbaIras;
    procedure BizParancs(_ukaz: string);
    procedure Bizonylatgyujtes;
    procedure Bizonylatfeliras;
    procedure ImportFileRogzites;

    procedure BitBtn1Click(Sender: TObject);
    procedure DATUMOKEGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure NAPTARChange(Sender: TObject);
    procedure ELOHOGOMBClick(Sender: TObject);
    procedure KOVHOGOMBClick(Sender: TObject);
    procedure VISSZAGOMBClick(Sender: TObject);
    procedure ImpParancs(_ukaz: string);
    procedure NaturNullazas;
    procedure MBNullazas;
    procedure JogiNullazas;
    procedure Vegfeldolgozas;
    procedure GetNaturData;
    procedure GetJogiData;
    procedure Fejlecbeirasa;

    function Nulele(_b: byte): string;
    function ScanPenztar(_psz: byte): byte;
    function Pontoz(_szido: string): string;
 

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  importform: Timportform;
  _kertdatum,_tegnap: TDateTime;
  _aktbankjegy,_bizonylatdarab,_code,_aktsorszam,_forintertek,_zz: integer;
  _pt,_uzlet,_penztardb,_betu,_pp,_aktpenztar,_xx,_mblen: byte;
  _ev,_ho,_nap,_kertev,_kertho,_kertnap: word;
  _kertnaps,_farok,_pcs,_cegbetu,_bankkod,_ugyftipus,_aktbankkod,_aktdnem: string;
  _tranztipus,_aktarfolyam,_aktbizonylatszam,_ugyfelnev,_ugyfelelozonev: string;
  _szulido,_szulhely,_anyjaneve,_niso,_azonosito,_joginev,_jiso,_telephely: string;
  _mbazonosito,_kftnev,_ugyftablapath,_bt,_biztabla,_pts,_akttabla: string;
  _okiratszam,_mbneve,_mbelozonev,_mbszulido,_mbszulhely,_mbanyjaneve,_mbiso: string;
  _okmtipus,_mbokmtipus,_aktceg,_fdbPath,_mbdata,_mbtabla,_mbelonev: string;
  _msorszams,_uz: string;
  _sorveg: string = chr(13)+chr(10);

  _ptszam: array[1..180] of integer;
  _ptbankkod,_ptceg: array[1..180] of string;
  _sos : array[1..500] of integer;
  _biz,_ntb: array[1..500] of string;
  _arf,_zn: integer;
  _arfs: string;

  _impnev: array[1..4] of string = ('BEST','EAST','PANN','ZALO');


  _host: string = '185.43.207.99';
  _iras: textfile;

implementation

{$R *.dfm}


// =============================================================================
            procedure Timportform.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
            procedure Timportform.FormActivate(Sender: TObject);
// =============================================================================

begin
  repaint;
  IrodakBetoltese;

  _tegnap := Date-1;

  _Ev := yearof(_tegnap);
  _ho := monthof(_tegnap);
  _nap:= dayof(_tegnap);

  _kertnaps := inttostr(_ev)+'.'+nulele(_ho)+'.'+nulele(_nap);
  KertNapPanel.Caption := _kertnaps;

  naptar.CalendarDate := _tegnap;
  ActiveControl := datumokegomb;
end;

// =============================================================================
           procedure Timportform.NAPTARChange(Sender: TObject);
// =============================================================================

begin
  _kertdatum := Naptar.CalendarDate;
  _ev := yearof(_kertdatum);
  _ho := monthof(_kertdatum);
  _nap:= dayof(_kertdatum);

  _kertnaps := inttostr(_ev)+'.'+nulele(_ho)+'.'+nulele(_nap);
  KertnapPanel.Caption := _kertnaps;
end;

// =============================================================================
          procedure Timportform.ELOHOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Naptar.PrevMonth;
end;

// =============================================================================
            procedure Timportform.KOVHOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Naptar.NextMonth;
end;

// =============================================================================
            procedure Timportform.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 2;
end;

// =============================================================================
               function TIMportForm.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
           procedure Timportform.DATUMOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _kertdatum := Naptar.CalendarDate;
  if _kertdatum>date then
    begin
      ShowMessage('A KÉRT DÁTUM MAJD A JÖVÕBEN LESZ');
      exit;
    end;
  _uz := 'A '+_kertnaps + '-I IMPORT FILE ELKÉSZÍTÉSE';

  Fopanel.caption := _uz;
  Fopanel.Color := clYellow;
  Fopanel.Repaint;

  _kertev := Naptar.Year;
  _kertho := Naptar.Month;
  _kertnap:= Naptar.day;

  _farok := inttostr(_kertev-2000)+nulele(_kertho);
  _bt := 'BT' + _farok;

  _ugyftablaPath := _HOST + ':c:\receptor\database\ugyfel' + midstr(_kertnaps,3,2)+'.FDB';

  Ufdbase.close;
  ufDbase.DatabaseName := _ugyfTablaPath;
  ufdbase.connected := true;

  UzenoPanel.Caption:= 'Bizonylatok legyüjtése';
  UzenoPanel.Repaint;

  BizonylatGyujtes;

  UzenoPanel.Caption:= 'Bizonylatok felirása';
  UzenoPanel.Repaint;

  Bizonylatfeliras;

  UzenoPanel.Caption:= 'Adatok feldolgozása';
  UzenoPanel.Repaint;

  Vegfeldolgozas;

  UzenoPanel.Caption:= 'A csv file-ok felirása';
  UzenoPanel.Repaint;

  ImportFileRogzites;

  UzenoPanel.Caption:= 'CSV FILE-OK ELKÉSZÜLTEK';
  UzenoPanel.Repaint;

  sLEEP(1200);
  Modalresult := 1;

end;

// =============================================================================
                  procedure TImportForm.Bizonylatgyujtes;
// =============================================================================

begin
  _betu := 65;
  _pp := 0;
  csik.Max := 26;
  Csik.min := 0;
  while _betu<=90 do
    begin
      csik.Position := _betu-64;
      _Biztabla := chr(_betu) + 'BIZ';
      _pcs := ' SELECT * FROM ' +_biztabla + _sorveg;
      _pcs := _pcs + 'WHERE (DATUM='+chr(39)+_kertnaps+chr(39)+')';
      _pcs := _pcs + ' AND (FIZETENDO>=300000)';
      with UfQuery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
        end;
      while not Ufquery.Eof do
        begin
          inc(_pp);
          _sos[_pp] := Ufquery.fieldByname('SORSZAM').asInteger;
          _biz[_pp] := Ufquery.fieldByNAme('BIZONYLATSZAM').asstring;
          _ntb[_pp] := chr(_betu)+'NEV';
          Ufquery.next;
        end;
      inc(_betu);
    end;

  _pcs := ' SELECT * FROM JOGIBIZ' +_sorveg;
  _pcs := _pcs + 'WHERE (DATUM='+chr(39)+_kertnaps+chr(39)+')';
  _pcs := _pcs + ' AND (FIZETENDO>=300000)';

  with UfQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not Ufquery.Eof do
    begin
      inc(_pp);
      _sos[_pp] := Ufquery.fieldByname('SORSZAM').asInteger;
      _biz[_pp] := Ufquery.fieldByNAme('BIZONYLATSZAM').asstring;
      _ntb[_pp] := 'JOGI';
      Ufquery.next;
    end;
  ufquery.close;
  ufdbase.close;
  Csik.Position := 26;
  sleep(200);
  _bizonylatDarab := _pp;
end;

// =============================================================================
                     procedure TImportForm.Irodakbetoltese;
// =============================================================================

begin
  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE STATUS='+chr(39)+'P'+chr(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  recdbase.connected := true;
  with recquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  While not recquery.eof do
    begin
      _uzlet := Recquery.fieldbyname('UZLET').asInteger;
      _bankkod := recquery.fieldByName('BANKKOD').asString;
      _cegbetu := recquery.FieldByNAme('CEGBETU').asString;

      inc(_pt);

      _ptszam[_pt] := _uzlet;
      _ptbankkod[_pt]:= _bankkod;
      _ptceg[_pt] := _cegbetu;

      recquery.Next;
    end;
  recquery.close;
  Recdbase.close;
  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  Artdbase.connected := true;
  with ArtQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;
  while not artquery.eof do
    begin
      _uzlet := Artquery.FieldByNAme('UZLET').asInteger;
      _bankkod := ArtQuery.fieldByNAme('BANKKOD').asString;
      inc(_pt);
      _ptszam[_pt] := _uzlet;
      _ptbankkod[_pt] := _Bankkod;
      _ptceg[_pt] := 'Z';
      Artquery.next;
    end;

  artquery.close;
  Artdbase.close;

  _penztardb := _pt;

end;

// =============================================================================
                     procedure TImportform.bazisbairas;
// =============================================================================

begin
  if _ugyftipus='cég' then
    begin
      if _mbiso='' then _mbIso := 'HU';
      if _jiso='' then _jiso := 'HU';
    end else
    begin
      if _niso='' then _niso := 'HU';
    end;

  _pcs := 'INSERT INTO IMPORT (UGYFELTIPUS,BANKKOD,DATUM,BANKJEGY,VALUTANEM,';
  _pcs := _pcs + 'TRANZTIPUS,ARFOLYAM,FORINTERTEK,BIZONYLATSZAM,UGYFNEV,ELOZONEV,';
  _pcs := _pcs + 'SZULIDO,SZULHELY,ANYJANEVE,NISO,OKMTIPUS,AZONOSITO,JOGINEV,JISO,';
  _pcs := _pcs + 'TELEPHELY,OKIRATSZAM,MBNEVE,MBELOZONEV,MBSZULIDO,MBSZULHELY,';
  _pcs := _pcs + 'MBANYJANEVE,MBISO,MBOKMTIPUS,MBAZONOSITO,KFT)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _ugyftipus + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktbankkod + chr(39) + ',';
  _pcs := _pcs + chr(39) + _kertnaps + chr(39) + ',';
  _pcs := _pcs + inttostr(_aktbankjegy) + ',';
  _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tranztipus + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktarfolyam + chr(39) + ',';
  _pcs := _pcs + inttostr(_forintertek) + ',';
  _pcs := _pcs + chr(39) + _aktbizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _ugyfelnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _ugyfelelozonev + chr(39) + ',';
  _pcs := _pcs + chr(39) + pontoz(_szulido) +  chr(39) + ',';
  _pcs := _pcs + chr(39) + _szulhely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _anyjaneve + chr(39) + ',';
  _pcs := _pcs + chr(39) + _niso + chr(39) + ',';
  _pcs := _pcs + chr(39) + _okmtipus + chr(39) + ',';
  _pcs := _pcs + chr(39) + _azonosito + chr(39) + ',';
  _pcs := _pcs + chr(39) + _joginev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _jiso +chr(39) + ',';
  _pcs := _pcs + chr(39) + _telephely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _okiratszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbneve + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbelozonev + chr(39) + ',';
  _pcs := _pcs + chr(39) + pontoz(_mbSzulido) + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbszulhely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbanyjaneve + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbiso +chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbokmtipus + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mbazonosito + chr(39)+',';
  _pcs := _pcs + chr(39) + _kftnev + chr(39)+')';
  ImpParancs(_pcs);
end;

// =============================================================================
               procedure TImportform.ImpParancs(_ukaz: string);
// =============================================================================

begin
  impdbase.connected := true;
  if imptranz.InTransaction then imptranz.commit;
  imptranz.StartTransaction;
  with impquery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  imptranz.commit;
  impdbase.close;
end;

// =============================================================================
             procedure TImportForm.BizParancs(_ukaz: string);
// =============================================================================

begin
  bizdbase.connected := true;
  if biztranz.InTransaction then biztranz.commit;
  Biztranz.StartTransaction;
  with Bizquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Biztranz.commit;
  Bizdbase.close;
end;

// =============================================================================
                  procedure TImportForm.BizonylatFeliras;
// =============================================================================

begin
  _pcs := 'DELETE FROM BIZONYLATOK';
  BizParancs(_pcs);
  _pp := 1;
  csik.Max := _bizonylatDarab;
  while _pp<=_bizonylatdarab do
    begin
      Csik.position := _pp;
      _aktbizonylatszam := _biz[_pp];
      _pts := midstr(_aktbizonylatszam,2,3);
      val(_pts,_aktpenztar,_code);
      _aktsorszam := _sos[_pp];
      _aktTabla := _ntb[_pp];
      _pcs := 'INSERT INTO BIZONYLATOK (BIZONYLATSZAM,PENZTAR,NEVTABLA,SORSZAM)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39)+_aktbizonylatszam+chr(39)+',';
      _pcs := _pcs + inttostr(_aktpenztar) + ',';
      _pcs := _pcs + chr(39) + _akttabla + chr(39) + ',';
      _pcs := _pcs + inttostr(_aktsorszam) + ')';
      BizParancs(_pcs);
      inc(_pp);
    end;
end;

// =============================================================================
                  procedure TImportForm.VegFeldolgozas;
// =============================================================================


begin
  _zz := 0;
  csik.Position := 0;
  _PCS := ' DELETE FROM IMPORT';
  ImpParancs(_pcs);

  _pcs := 'SELECT * FROM BIZONYLATOK' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAR';

  Bizdbase.connected := true;
  with Bizquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  Ufdbase.connected := true;
  while not Bizquery.eof do
    begin
      inc(_zz);
      csik.Position := _zz;

      _aktbizonylatszam := BizQuery.FieldByNAme('BIZONYLATSZAM').asString;
      _aktpenztar := Bizquery.FieldByNAme('PENZTAR').asInteger;
      _akttabla := Bizquery.FieldByNAme('NEVTABLA').asString;
      _aktsorszam := BizQuery.FieldByNAme('SORSZAM').asInteger;
      _ugyftipus := 'természetes személy';

      Memo1.Lines.add(_aktbizonylatszam+' '+ _akttabla+' '+inttostr(_aktsorszam));

      if _akttabla='JOGI' then
        begin
          Naturnullazas;
          _ugyftipus := 'cég';
          GetJogiData;
          if _joginev='' then
            begin
              Bizquery.Next;
              continue;
            end;
        end else
        begin
          Joginullazas;
          MbNullazas;
          GetNaturdata;
        end;
      _xx := scanPenztar(_aktpenztar);
      _aktbankkod := _ptbankKod[_xx];
      _tranztipus := 'vétel';
      if leftstr(_aktbizonylatszam,1)='E' then _tranztipus := 'eladás';

      _aktceg := _ptceg[_xx];
      if _aktceg='B' then _kftnev := 'BEST';
      if _aktceg='E' then _kftnev := 'EAST';
      if _aktceg='P' then _kftnev := 'PANN';
      if _aktceg='Z' then _kftnev := 'ZALO';

      _fdbPath := _host + ':c:\receptor';
      if _aktpenztar>150 then _fdbPath := _host + ':c:\cartcash';

      _fdbPath := _fdbPath + '\database\v'+inttostr(_aktpenztar)+'.FDB';
      Vdbase.Close;
      VTabla.close;
      vdbase.DatabaseName := _fdbPath;
      vdbase.Connected := true;
      Vtabla.TableName := _bt;
      if not Vtabla.Exists then
        begin
          vdbase.Close;
          continue;
        end;  

      _pcs := 'select * from ' + _bt + _SORVEG;
      _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_aktbizonylatszam+chr(39);

      with vquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
        end;

      while not vquery.Eof do
        begin
          _aktbankjegy := Vquery.fieldByNAme('BANKJEGY').asInteger;
          _aktdnem := Vquery.fieldbyname('VALUTANEM').asString;
          _arf := Vquery.fieldbyName('ARFOLYAM').asInteger;
          _forintertek := Vquery.FieldByNAme('FORINTERTEK').AsInteger;
          if _aktdnem= 'JPY' then _arf := trunc(10*_arf);
          _arfs := inttostr(_arf);
          _zn := length(_arfs)-2;

          _aktarfolyam := leftstr(_arfs,_zn)+'.'+midstr(_arfs,_zn+1,2);
          if (_forintertek>=300000) then BazisbaIras;
          vquery.next;
        end;
      Vquery.close;
      vdbase.close;
      BizQuery.next;
    end;
  ufdbase.close;
end;

// =============================================================================
                  procedure TImportForm.GetNaturData;
// =============================================================================

var _elonev,_lanynev: string;

begin
  _pcs := 'SELECT * FROM ' + _akttabla + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_aktsorszam);

  with ufquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _ugyfelnev := trim(FieldByNAme('NEV').asString);
      _elonev := trim(FieldByNAme('ELOZONEV').asString);
      _lanynev := trim(FieldByNAme('LEANYKORI').asString);
      _szulido := FieldByNAme('SZULETESIIDO').asString;
      _szulhely := trim(FieldByName('SZULETESIHELY').asString);
      _anyjaneve := trim(FieldByNAme('ANYJANEVE').asString);
      _niso := FieldByNAme('ISO').asString;
      _okmtipus := trim(FieldByNAme('OKMANYTIP').AsSTRING);
      _azonosito := trim(FieldByNAme('AZONOSITO').asString);
    end;

  if (_lanynev<>'') and (_elonev='') then _elonev := _lanynev;
  if _elonev='' then _elonev := _ugyfelnev;
  _ugyfelelozonev := _elonev;
end;

// =============================================================================
                    procedure TImportform.Joginullazas;
// =============================================================================

begin
  _joginev := '';
  _jiso := '';
  _telephely := '';
  _okiratszam := '';
end;

procedure TImportForm.MbNullazas;

begin
  _mbNeve := '';
  _mbElozonev := '';
  _mbSzulido := '';
  _mbszulhely := '';
  _mbanyjaneve := '';
  _mbiso := '';
  _mbokmtipus := '';
  _mbAzonosito := '';
end;

// =============================================================================
                   procedure TImportForm.Naturnullazas;
// =============================================================================

begin
  _ugyfelnev := '';
  _ugyfelelozonev := '';
  _szulido := '';
  _szulhely := '';
  _anyjaneve := '';
  _niso := '';
  _okmtipus := '';
  _azonosito := '';
end;

// =============================================================================
                     procedure TImportForm.GetJogiData;
// =============================================================================

var _mbleany: string;

begin
  _pcs := 'SELECT * FROM JOGI' + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_aktsorszam);

  with ufquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _JOGInev := trim(FieldByNAme('JOGISZEMELYNEV').AsString);
      _jiso := FieldByNAme('ISO').asstring;
      _telephely := trim(FieldByNAme('TELEPHELYCIM').AsString);
      _okiratszam := trim(Fieldbyname('OKIRATSZAM').AsString);
      _mbData := trim(FieldByName('MBDATASORSZAM').asstring);
    end;

  _mblen := length(_mbdata);
  IF _MBLEN<5 then
    begin
      _uz := inttostr(_aktsorszam)+'. '+_joginev+' : NINCS MEGBIZOTT !';
      SHowmessage(_UZ);
      joginullazas;
      exit;
    end;


  _mbtabla := leftstr(_mbdata,4);
  _msorszams := midstr(_mbdata,5,_mblen-4);

  _pcs := 'SELECT * FROM ' +_mbtabla + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM='+_msorszams;

   with ufquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _mbneve := trim(FieldByNAme('NEV').asString);
      _mbelonev := trim(FieldByNAme('ELOZONEV').AsString);
      _mbleany  := trim(FieldByNAme('LEANYKORI').AsString);
      _mbanyjaneve := trim(FieldByNAme('ANYJANEVE').AsString);
      _mbszulido := FieldByNAme('SZULETESIIDO').asString;
      _mbSzulhely := trim(FieldByNAme('SZULETESIHELY').AsString);
      _mbiso := fieldByNAme('ISO').AsString;
      _mbOkmtipus := trim(fieldByName('OKMANYTIP').AsString);
      _mbAzonosito := trim(fieldByNAme('AZONOSITO').AsString);
    end;
  Ufquery.close;

  if (_mbleany<>'') and (_mbelonev='') then _mbelonev := _mbleany;
  if _mbelonev='' then _mbelonev := _mbneve;
  _MBelozonev := _mbelonev;
end;

// =============================================================================
              function TImportform.ScanPenztar(_psz: byte): byte;
// =============================================================================

var _y: byte;

begin
  result := 0;
  _y := 1;
  while _y<=_penztardb do
    begin
      if _ptszam[_y]=_psz then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
                  procedure TImportForm.ImportFileRogzites;
// =============================================================================


var _cc: byte;
    _aktcsv,_aktcsvpath,_kbs: string;
    _recno : integer;

begin
  ImpDbase.Connected := true;
  _CC := 1;
  while _cc<=4 do
    begin
      _aktceg := _impnev[_cc];
      _aktcsv := leftstr(_aktceg,2)+inttostr(_kertev)+nulele(_kertho)+nulele(_kertnap)+'.csv';
      _aktcsvPath := 'c:\uctrl\data\' + _aktcsv;
      if fileexists(_aktcsvPath) then sysutils.DeleteFile(_aktcsvPath);

      Assignfile(_iras,_aktcsvPath);
      rewrite(_iras);

      FejlecBeirasa;

      _pcs := 'SELECT * FROM IMPORT' + _sorveg;
      _pcs := _pcs + 'WHERE KFT='+chr(39)+_aktceg+chr(39);
      with Impquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          Last;
          _recno := recno;
          First;
        end;

      csik.Max := _recno;
      _zz := 0;
      while not impquery.eof do
        begin
          inc(_zz);
          Csik.Position := _zz;

          with Impquery do
            begin
              _ugyftipus := trim(FieldByNAme('UGYFELTIPUS').AsString);
              _aktbankkod := trim(FieldByNAme('BANKKOD').AsString);
              _aktbankjegy := FieldByNAme('BANKJEGY').asInteger;
              _aktdnem := fieldByNAme('VALUTANEM').asString;
              _tranztipus := trim(FieldByNAme('TRANZTIPUS').AsString);
              _aktarfolyam := trim(FieldByNAme('ARFOLYAM').AsString);
              _forintertek := FieldByNAme('FORINTERTEK').asInteger;
              _aktbizonylatszam := FieldByNAme('BIZONYLATSZAM').AsString;
              _ugyfelnev := trim(FieldByNAme('UGYFNEV').AsString);
              _ugyfelelozonev := trim(FieldByNAme('ELOZONEV').AsString);
              _szulido := fieldbyname('SZULIDO').asString;
              _szulhely := trim(fieldbyname('SZULHELY').asString);
              _anyjaneve := trim(fieldbyname('ANYJANEVE').AsString);
              _niso := fieldbyname('NISO').AsString;
              _okmtipus := trim(FieldByName('OKMTIPUS').ASSTRING);
              _azonosito := trim(FieldByNAme('AZONOSITO').AsString);
              _joginev := trim(FieldByNAme('JOGINEV').AsString);
              _jiso := fieldByNAme('JISO').AsString;
              _telephely := trim(Fieldbyname('TELEPHELY').AsString);
              _okiratszam := trim(fieldByNAme('OKIRATSZAM').AsString);
              _mbneve := trim(FieldByNAme('MBNEVE').AsString);
              _mbelozonev := trim(fieldBynAme('MBELOZONEV').AsString);
              _mbszulido := fieldByNAme('MBSZULIDO').asString;
              _mbszulhely := trim(FieldByNAme('MBSZULHELY').AsString);
              _mbanyjaneve := trim(fieldbyname('MBANYJANEVE').asString);
              _mbiso := fieldByNAme('MBISO').AsString;
              _mbokmtipus := trim(FieldByNAme('MBOKMTIPUS').AsString);
              _mbazonosito := trim(FieldByNAme('MBAZONOSITO').AsString);
            end;

           if _okmtipus='' then _okmtipus := 'SZIG';
           _kbs := uppercase(leftstr(_okmtipus,1));
           IF _kbs='S' then _okmtipus := 'SZIG';
           if _kbs='J' then _okmtipus := 'Jogosítvány';
           if _kbs='U' then _okmtipus := 'Útlevél';


          if _mbokmtipus='' then _okmtipus := 'SZIG';

          _kbs := uppercase(leftstr(_mbokmtipus,1));
          IF _kbs='S' then _mbokmtipus := 'SZIG';
          if _kbs='J' then _mbokmtipus := 'Jogosítvány';
          if _kbs='U' then _mbokmtipus := 'Útlevél';

          if _ugyftipus='cég' then _okmtipus:='';

          // itt beirja a csv fileba
          write(_iras,_ugyftipus + ';');
          if leftstr(_aktbankkod,1)='0' then write(_iras,chr(39));
          write(_iras,_aktbankkod + ';');
          write(_iras,_kertnaps + ';');
          write(_iras,inttostr(_aktbankjegy) + ';');
          write(_iras,_aktdnem + ';');
          write(_iras,_tranztipus + ';');
          write(_iras,_aktarfolyam + ';');
          write(_iras,inttostr(_forintertek) + ';');
          write(_iras,_aktbizonylatszam + ';');
          write(_iras,_ugyfelnev + ';');
          write(_iras,_ugyfelelozonev + ';');
          write(_iras,_szulido+';');
          write(_iras,_szulhely+';');
          write(_iras,_anyjaneve+';');
          write(_iras,_niso+';');
          write(_iras,_okmtipus+';');
          write(_iras,_azonosito+';');
          write(_iras,_joginev+';');
          write(_iras,_jiso+';');
          write(_iras,_telephely+';');
          write(_iras,_okiratszam+';');
          write(_iras,_mbneve+';');
          write(_iras,_mbelozonev+';');
          write(_iras,_mbszulido+';');
          write(_iras,_mbszulhely+';');
          write(_iras,_mbanyjaneve+';');
          write(_iras,_mbiso+';');
          write(_iras,_mbokmtipus+';');
          writeLn(_iras,_mbazonosito);
          impquery.next;
        end;
      impquery.close;
      impdbase.Close;
      closefile(_iras);

      inc(_cc);
    end;
end;

function TImportForm.Pontoz(_szido: string): string;

begin
  if trim(_szido)='' then
    begin
      result := '';
      exit;
    end;
      
  result := leftstr(_szido,4)+'.'+midstr(_szido,5,2)+'.'+midstr(_szido,7,2);
end;


procedure TImportForm.FejlecBeirasa;

begin
  write(_iras,';tranzakció adatai;;;;;;;;');
  write(_iras,'természetes személy ügyfelet azonosító adatok;;;;;;;;');
  writeLn(_iras,'céges ügyfél adatai;;;;cég nevében eljáró személy adatai;;;;;;;');
  write(_iras,'ügyfél típus (cég, természetes személy);üzlethelység azonosító;');
  write(_iras,'tranzakció dátuma;összeg;valutanem;eladás/vétel;');
  write(_iras,'alkalmazott árfolyam;tranzakció forint összege;');
  write(_iras,'tranzakció egyedi azonosítója;családi és utónév;');
  write(_iras,'születési családi és utónév;születési dátum;születési hely;');
  write(_iras,'anyja neve;állampolgársága;azonosító okmány típusa;');
  write(_iras,'azonosító okmány száma;cég neve;bejegyzés országa;székhely;');
  write(_iras,'cégjegyzékszám (bejegyzési szám);családi és utónév;');
  write(_iras,'születési családi és utónév;születési dátum;születési hely;');
  write(_iras,'anyja neve;állampolgársága;azonosító okmány típusa;');
  writeLn(_iras,'azonosító okmány száma');
end;

end.

