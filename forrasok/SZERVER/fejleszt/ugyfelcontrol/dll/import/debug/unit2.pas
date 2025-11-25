unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Grids, Calendar, ExtCtrls, ComCtrls, Dateutils,
  strutils, IBDatabase, DB, IBCustomDataSet, IBQuery, IBTable;

type
  TIMPORTFORM = class(TForm)
    NAPTARPANEL: TPanel;
    PROGRESSDPANEL: TPanel;
    FOPANEL: TPanel;
    NAPTAR: TCalendar;
    ELOHOGOMB: TBitBtn;
    KOVHOGOMB: TBitBtn;
    KERTNAPPANEL: TPanel;
    UZENOPANEL: TPanel;
    Panel2: TPanel;
    CSIK: TProgressBar;
    Memo1: TMemo;
    DATUMOKEGOMB: TBitBtn;
    VISSZAGOMB: TBitBtn;
    Shape1: TShape;
    REMOTEQUERY: TIBQuery;
    REMOTEDBASE: TIBDatabase;
    REMOTETRANZ: TIBTransaction;
    IMPQUERY: TIBQuery;
    IMPDBASE: TIBDatabase;
    IMPTRANZ: TIBTransaction;
    BIZQUERY: TIBQuery;
    BIZDBASE: TIBDatabase;
    BIZTRANZ: TIBTransaction;
    IMPTABLA: TIBTable;
    REMOTETABLA: TIBTable;
    UGYFELQUERY: TIBQuery;
    IBDatabase1: TIBDatabase;
    UGYFELDBASE: TIBDatabase;
    UGYFELTRANZ: TIBTransaction;

    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure NAPTARChange(Sender: TObject);
    procedure ELOHOGOMBClick(Sender: TObject);
    procedure KOVHOGOMBClick(Sender: TObject);
    procedure VISSZAGOMBClick(Sender: TObject);
    procedure DATUMOKEGOMBClick(Sender: TObject);
    procedure Korrekcio;
    procedure Irodakbetoltese;
    procedure Bizonylatgyujtes;
    procedure Bazisbairas;
    procedure ImpParancs(_ukaz: string);
    procedure BizParancs(_ukaz: string);
    procedure BizonylatFeliras;
    procedure VegFeldolgozas;
    procedure GetNaturData;
    procedure Joginullazas;
    procedure MbNullazas;
    procedure Naturnullazas;
    procedure GetJogiData;
    procedure ImportFileRogzites;
    procedure FejlecBeirasa;

    function GetOkmtip(_ot: string): string;
    function Pontoz(_szido: string): string;
    function ScanPenztar(_psz: byte): byte;
    function Nulele(_b: byte): string;
   

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  IMPORTFORM: TIMPORTFORM;

  _host: string = '185.43.207.99';
  _ptszam: array[1..180] of byte;
  _ptbankkod,_ptceg: array[1..180] of string;
  _iras: textfile;
  _impnev: array[1..2] of string = ('BEST','ZALO');

  _kertdatum,_tegnap: TDatetime;
  _ev,_ho,_nap,_kertev,_kertho,_kertnap,_bizonylatdarab,_pp,_cs: word;
  _kertnaps,_uz,_farok,_ugyftablaPath,_bt,_pcs,_biztabla,_aktfdbPath: string;
  _bankkod,_cegbetu,_ugyftipus,_mbiso,_jiso,_aktbankKod,_aktdnem,_akttabla: string;
  _tranztipus,_aktbizonylatszam,_ugyfelnev,_ugyfelelozonev,_szulido: string;
  _szulhely,_anyjaneve,_okmtipus,_azonosito,_joginev,_telephely: string;
  _okiratszam,_mbneve,_mbelozonev,_mbszulido,_mbszulhely,_mbanyjaneve: string;
  _mbOkmTipus,_kftnev,_niso,_aktarfolyam,_mbazonosito,_pts,_arfs: string;
  _mbTabla,_fdbpath,_aktceg,_mbData,_msorszams,_mbelonev: string;
  _bizszam,_utip,_ugyfnev,_kbetu,_okmtip: string;
  _aktbankjegy,_forintertek,_code,_aktsorszam,_aktpenztar,_zz,_xx,_ARF: integer;
  _recno: integer;
  _sorveg: string = chr(13)+chr(10);
  _betu,_pt,_uzlet,_penztardb,_zn,_mblen: byte;

  _sos: array[1..1500] of integer;
  _biz,_ntb: array[1..1500] of string;

  _top,_left,_height,_width: word;

function importkeszitorutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
             function importkeszitorutin: integer; stdcall;
// =============================================================================

begin
  Importform := TImportform.Create(Nil);
  result := Importform.ShowModal;
  Importform.free;
end;

// =============================================================================
              procedure Timportform.FormCreate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;

  _top := round((_height-518)/2);
  _left:= round((_width-356)/2);

  top := _top-78;
  left := _left;
  repaint;
  IrodakBetoltese;
  _tegnap := Date-1;

  _Ev := yearof(_tegnap);
  _ho := monthof(_tegnap);
  _nap:= dayof(_tegnap);

  _kertnaps := inttostr(_ev)+'.'+nulele(_ho)+'.'+nulele(_nap);
  KertNapPanel.Caption := _kertnaps;

  naptar.CalendarDate := _tegnap;
end;

// =============================================================================
            procedure TIMPORTFORM.Button1Click(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
            procedure Timportform.FormActivate(Sender: TObject);
// =============================================================================

begin


  Fopanel.Color := clWhite;
  Fopanel.caption := '';
  Fopanel.repaint;

  Uzenopanel.Caption := '';
  UzenoPanel.repaint;

  Memo1.Lines.clear;
  Memo1.Clear;
  Memo1.repaint;

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

  RemoteDbase.close;
  RemoteDbase.DatabaseName := _ugyfTablaPath;
  RemoteDbase.connected    := true;

  UgyfelDbase.Close;
  UgyfelDbase.dataBaseName := _ugyfTablaPath;
  
  UzenoPanel.Caption:= 'Bizonylatok legyüjtése';
  UzenoPanel.Repaint;

  BizonylatGyujtes;
  if _bizonylatdarab=0 then
    begin
      SHowMessage('A kért napon nem volt bizonylat');
      Modalresult := 2;
      exit;
    end;

  UzenoPanel.Caption:= 'Bizonylatok felirása';
  UzenoPanel.Repaint;

  Bizonylatfeliras;

  UzenoPanel.Caption:= 'Adatok feldolgozása';
  UzenoPanel.Repaint;
  Vegfeldolgozas;

  UzenoPanel.Caption:= 'Az adatváltozások javítása';
  UzenoPanel.Repaint;
  Korrekcio;

  UzenoPanel.Caption:= 'A csv file-ok felirása';
  UzenoPanel.Repaint;

  ImportFileRogzites;

  UzenoPanel.Caption:= 'CSV FILE-OK ELKÉSZÜLTEK';
  UzenoPanel.Repaint;

  Sleep(1200);
  Modalresult := 1;
end;

// =============================================================================
                  procedure TImportForm.Bizonylatgyujtes;
// =============================================================================

begin
  _betu := 65;
  _pp   := 0;

  csik.Max := 26;
  Csik.min := 0;

  while _betu<=90 do
    begin
      csik.Position := _betu-64;
      _Biztabla := chr(_betu) + 'BIZ';

      _pcs := ' SELECT * FROM ' +_biztabla + _sorveg;
      _pcs := _pcs + 'WHERE (DATUM='+chr(39)+_kertnaps+chr(39)+')';
      _pcs := _pcs + ' AND (FIZETENDO>=300000)';

      with RemoteQuery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
        end;

      while not RemoteQuery.Eof do
        begin
          inc(_pp);
          _sos[_pp] := RemoteQuery.FieldByname('SORSZAM').asInteger;
          _biz[_pp] := RemoteQuery.FieldByNAme('BIZONYLATSZAM').asstring;
          _ntb[_pp] := chr(_betu)+'NEV';
          RemoteQuery.next;
        end;
      inc(_betu);
    end;

  _pcs := ' SELECT * FROM JOGIBIZ' +_sorveg;
  _pcs := _pcs + 'WHERE (DATUM='+chr(39)+_kertnaps+chr(39)+')';
  _pcs := _pcs + ' AND (FIZETENDO>=300000)';

  with RemoteQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not RemoteQuery.Eof do
    begin
      inc(_pp);
      _sos[_pp] := RemoteQuery.FieldByname('SORSZAM').asInteger;
      _biz[_pp] := RemoteQuery.FieldByNAme('BIZONYLATSZAM').asstring;
      _ntb[_pp] := 'JOGI';
      RemoteQuery.next;
    end;

  RemoteQuery.close;
  RemoteDbase.close;

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

  _aktfdbpath := _host + ':C:\receptor\database\receptor.fdb';

  remotedbase.close;
  remotedbase.databasename := _aktfdbpath;
  remotedbase.connected := true;

  with remotequery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  While not remotequery.eof do
    begin
      _uzlet := Remotequery.fieldbyname('UZLET').asInteger;
      _bankkod := remotequery.fieldByName('BANKKOD').asString;
      _cegbetu := remotequery.FieldByNAme('CEGBETU').asString;

      inc(_pt);

      _ptszam[_pt] := _uzlet;
      _ptbankkod[_pt]:= _bankkod;
      _ptceg[_pt] := _cegbetu;

      remotequery.Next;
    end;
  remotequery.close;
  Remotedbase.close;

  _aktfdbpath := _host + ':C:\cartcash\database\artcash.fdb';

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  Remotedbase.DatabaseName := _aktfdbpath;
  Remotedbase.connected := true;
  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not remotequery.eof do
    begin
      _uzlet   := remotequery.FieldByNAme('UZLET').asInteger;
      _bankkod := remoteQuery.fieldByNAme('BANKKOD').asString;

      inc(_pt);

      _ptszam[_pt]    := _uzlet;
      _ptbankkod[_pt] := _Bankkod;
      _ptceg[_pt]     := 'Z';

      remotequery.next;
    end;

  remotequery.close;
  remotedbase.close;

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
               procedure TImportForm.ImpParancs(_ukaz: string);
// =============================================================================

begin
  Impdbase.Connected := true;
  if impTranz.InTransaction then impTranz.commit;
  ImpTranz.StartTransaction;
  with ImpQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_ukaz);
      Execsql;
    end;
  impTranz.Commit;
  impDbase.Close;
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

var _astr: string;

begin
  _zz := 0;
  csik.Position := 0;

  _pcs := ' DELETE FROM IMPORT';
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

  while not Bizquery.eof do
    begin
      inc(_zz);
      csik.Position := _zz;

      with Bizquery do
        begin
          _aktbizonylatszam := FieldByNAme('BIZONYLATSZAM').asString;
          _aktpenztar := FieldByNAme('PENZTAR').asInteger;
          _akttabla := FieldByNAme('NEVTABLA').asString;
          _aktsorszam := FieldByNAme('SORSZAM').asInteger;
        end;

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
      if _aktceg='Z' then _kftnev := 'ZALO';

      _fdbPath := _host + ':c:\receptor';
      if _aktpenztar>150 then _fdbPath := _host + ':c:\cartcash';

      _fdbPath := _fdbPath + '\database\v'+inttostr(_aktpenztar)+'.FDB';
      RemoteDbase.Close;
      RemoteTabla.close;

      RemoteDbase.DatabaseName := _fdbPath;
      RemoteDbase.Connected    := True;
      RemoteTabla.TableName    := _bt;

      if not RemoteTabla.Exists then
        begin
          RemoteDbase.Close;
          Continue;
        end;

      _pcs := 'select * from ' + _bt + _SORVEG;
      _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_aktbizonylatszam+chr(39);

      with RemoteQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
        end;

      while not RemoteQuery.Eof do
        begin
          with RemoteQuery do
            begin
              _aktbankjegy := FieldByNAme('BANKJEGY').asInteger;
              _aktdnem     := Fieldbyname('VALUTANEM').asString;
              _arf         := FieldbyName('ARFOLYAM').asInteger;
              _forintertek := FieldByNAme('FORINTERTEK').AsInteger;
            end;

          if _aktdnem= 'JPY' then _arf := trunc(10*_arf);
          _arfs := inttostr(_arf);
          _zn   := length(_arfs)-2;
          _astr := '';

          if _arf<1000 then _astr := '00';

          _aktarfolyam := _astr + leftstr(_arfs,_zn)+'.'+midstr(_arfs,_zn+1,2);
          if (_forintertek>=300000) then BazisbaIras;
          RemoteQuery.Next;
        end;
      RemoteQuery.close;
      RemoteDbase.close;
      BizQuery.next;
    end;
  RemoteDbase.close;
end;

// =============================================================================
                  procedure TImportForm.GetNaturData;
// =============================================================================

var _elonev,_lanynev: string;

begin
  UgyfelDbase.Connected := true;

  _pcs := 'SELECT * FROM ' + _akttabla + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_aktsorszam);

  with UgyfelQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;

      _ugyfelnev := trim(FieldByNAme('NEV').asString);
      _elonev    := trim(FieldByNAme('ELOZONEV').asString);
      _lanynev   := trim(FieldByNAme('LEANYKORI').asString);
      _szulido   := FieldByNAme('SZULETESIIDO').asString;
      _szulhely  := trim(FieldByName('SZULETESIHELY').asString);
      _anyjaneve := trim(FieldByNAme('ANYJANEVE').asString);
      _niso      := FieldByNAme('ISO').asString;
      _okmtipus  := trim(FieldByNAme('OKMANYTIP').AsSTRING);
      _azonosito := trim(FieldByNAme('AZONOSITO').asString);
    end;

  if (_lanynev<>'') and (_elonev='') then _elonev := _lanynev;
  if _elonev='' then _elonev := _ugyfelnev;
  _ugyfelelozonev := _elonev;
  UgyfelQuery.close;
  UgyfelDbase.close;
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

// =============================================================================
                  procedure TImportForm.MbNullazas;
// =============================================================================

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
  UgyfelDbase.connected := true;

  _pcs := 'SELECT * FROM JOGI' + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_aktsorszam);

  with UgyfelQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;

      _jogiNev    := trim(FieldByNAme('JOGISZEMELYNEV').AsString);
      _jIso       := FieldByNAme('ISO').asstring;
      _telephely  := trim(FieldByNAme('TELEPHELYCIM').AsString);
      _okiratszam := trim(Fieldbyname('OKIRATSZAM').AsString);
      _mbData     := trim(FieldByName('MBDATASORSZAM').asstring);
    end;

  _mblen := length(_mbdata);
  IF _MbLen<5 then
    begin
      _uz := inttostr(_aktsorszam)+'. '+_joginev+' : NINCS MEGBIZOTT !';
      SHowmessage(_UZ);
      joginullazas;
      UgyfelQuery.Close;
      UgyfelDbase.Close;
      exit;
    end;

  _mbTabla   := leftstr(_mbdata,4);
  _mSorszams := midstr(_mbdata,5,_mblen-4);

  _pcs := 'SELECT * FROM ' +_mbtabla + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM='+_msorszams;

   with UgyfelQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _mbneve      := trim(FieldByNAme('NEV').asString);
      _mbelonev    := trim(FieldByNAme('ELOZONEV').AsString);
      _mbleany     := trim(FieldByNAme('LEANYKORI').AsString);
      _mbanyjaneve := trim(FieldByNAme('ANYJANEVE').AsString);
      _mbszulido   := FieldByNAme('SZULETESIIDO').asString;
      _mbSzulhely  := trim(FieldByNAme('SZULETESIHELY').AsString);
      _mbiso       := FieldByNAme('ISO').AsString;
      _mbOkmtipus  := trim(FieldByName('OKMANYTIP').AsString);
      _mbAzonosito := trim(FieldByNAme('AZONOSITO').AsString);
    end;
  UgyfelQuery.Close;
  UgyfelDbase.Close;

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
  while _cc<=2 do
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
              _aktbankjegy    := FieldByNAme('BANKJEGY').asInteger;
              _aktdnem        := fieldByNAme('VALUTANEM').asString;
              _tranztipus    := trim(FieldByNAme('TRANZTIPUS').AsString);
              _aktarfolyam   := trim(FieldByNAme('ARFOLYAM').AsString);
              _forintertek   := FieldByNAme('FORINTERTEK').asInteger;
              _aktbizonylatszam := FieldByNAme('BIZONYLATSZAM').AsString;
              _ugyfelnev        := trim(FieldByNAme('UGYFNEV').AsString);
              _ugyfelelozonev   := trim(FieldByNAme('ELOZONEV').AsString);
              _szulido          := fieldbyname('SZULIDO').asString;
              _szulhely         := trim(fieldbyname('SZULHELY').asString);
              _anyjaneve        := trim(fieldbyname('ANYJANEVE').AsString);
              _niso             := fieldbyname('NISO').AsString;
              _okmtipus         := trim(FieldByName('OKMTIPUS').ASSTRING);
              _azonosito        := trim(FieldByNAme('AZONOSITO').AsString);
              _joginev          := trim(FieldByNAme('JOGINEV').AsString);
              _jiso             := fieldByNAme('JISO').AsString;
              _telephely        := trim(Fieldbyname('TELEPHELY').AsString);
              _okiratszam       := trim(fieldByNAme('OKIRATSZAM').AsString);
              _mbneve           := trim(FieldByNAme('MBNEVE').AsString);
              _mbelozonev       := trim(fieldBynAme('MBELOZONEV').AsString);
              _mbszulido        := fieldByNAme('MBSZULIDO').asString;
              _mbszulhely       := trim(FieldByNAme('MBSZULHELY').AsString);
              _mbanyjaneve      := trim(fieldbyname('MBANYJANEVE').asString);
              _mbiso            := fieldByNAme('MBISO').AsString;
              _mbokmtipus       := trim(FieldByNAme('MBOKMTIPUS').AsString);
              _mbazonosito      := trim(FieldByNAme('MBAZONOSITO').AsString);
            end;

          if _okmtipus<>'' then _okmtipus := GetOkmTip(_okmtipus);
          if _mbokmtipus<>'' then _mbOkmtipus := GetOkmTip(_mbokmtipus);

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

// =============================================================================
           function TImportForm.Pontoz(_szido: string): string;
// =============================================================================

begin
  if trim(_szido)='' then
    begin
      result := '';
      exit;
    end;

  result := leftstr(_szido,4)+'.'+midstr(_szido,5,2)+'.'+midstr(_szido,7,2);
end;

// =============================================================================
                    procedure TImportForm.FejlecBeirasa;
// =============================================================================

begin
  write(_iras,';tranzakció adatai;;;;;;;;');
  write(_iras,'természetes személy ügyfelet azonosító adatok;;;;;;;;');
  writeLn(_iras,'céges ügyfél adatai;;;;cég nevében eljáró személy adatai;;;;;;;');
  write(_iras,'ügyfél típus (cég, természetes személy);üzlethelyiség azonosító;');
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


// =============================================================================
              function TImportForm.GetOkmtip(_ot: string): string;
// =============================================================================

var _kbasc: byte;

begin
  _ot := uppercase(_ot);
  _kbasc := ord(_ot[1]);
  result := 'SZIG';
  case _kbasc of
     85: result := 'ÚTLEVÉL';
    163: result := 'ÚTLEVÉL';
    233: result := 'ÚTLEVÉL';
     74: result := 'JOGOSÍTVÁNY';
     83: result := 'SZIG';
  end;
end;

// =============================================================================
                        procedure TImportForm.Korrekcio;
// =============================================================================

begin

  RemoteDbase.Connected := true;

  // Az import-táblát irásra-olvasásra megnyitja:

  impDbase.Connected := True;
  if impTranz.InTransaction then ImpTranz.Commit;
  impTranz.StartTransaction;

  impTabla.Open;
  impTabla.Last;

  // Hány rekordból áll az import-tábla:
  _recno := impTabla.Recno;
  impTabla.First;

  Csik.Max := _recno;
  _cs := 0;

  // Végigmegy az importtábla összes rekordján:

  while not Imptabla.Eof do
    begin
      inc(_cs);
      Csik.Position := _cs;

      _bizszam := ImpTabla.FieldByName('BIZONYLATSZAM').asString;
      _utip    := leftstr(ImpTabla.Fieldbyname('UGYFELTIPUS').asString,1);

      if _uTip='c' then _biztabla := 'JOGIBIZ'
      else begin
        _ugyfnev  := Imptabla.fieldByName('UGYFNEV').asstring;
        _kbetu    := leftstr(_ugyfnev,1);
        _biztabla := _kbetu + 'BIZ';
      end;

      _pcs := 'SELECT * FROM ' + _biztabla + _sorveg;
      _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39) + _bizszam +chr(39);

      with UgyfelQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          _recno := recno;
        end;

      if _recno>0 then
        begin
          _okmTip    := trim(UgyfelQuery.FieldByName('OKMANYTIP').AsString);
          _azonosito := trim(UgyfelQuery.FieldByName('AZONOSITO').AsString);

          if _okmTip<>'' then
            begin
              if _utip='c' then
                begin
                  impTabla.edit;
                  impTabla.fieldByName('MBOKMTIPUS').asString := _okmtip;
                  impTabla.fieldbyname('MBAZONOSITO').AsString := _azonosito;
                  impTabla.Post;
                end else
                begin
                  impTabla.edit;
                  impTabla.fieldByName('OKMTIPUS').asString := _okmtip;
                  impTabla.fieldbyname('AZONOSITO').AsString := _azonosito;
                  impTabla.Post;
                end;
            end;
        end;
      UgyfelQuery.close;
      impTabla.next;
    end;

  Imptranz.Commit;
  impDbase.Close;

  UgyfelDbase.close;
end;
end.
