unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  Strutils, ComCtrls, ExtCtrls, Grids, DBGrids;

type
  TForm1 = class(TForm)
    STARTGOMB: TBitBtn;
    KILEPOGOMB: TBitBtn;
    BIZQUERY: TIBQuery;
    BIZDBASE: TIBDatabase;
    BIZTRANZ: TIBTransaction;
    DATUMEDIT: TEdit;
    Label1: TLabel;
    NEVQUERY: TIBQuery;
    NEVDBASE: TIBDatabase;
    NEVTRANZ: TIBTransaction;
    OKMQUERY: TIBQuery;
    OKMDBASE: TIBDatabase;
    OKMTRANZ: TIBTransaction;
    CSIK: TProgressBar;
    ALCSIK: TProgressBar;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    RACS: TDBGrid;
    HIANYSOURCE: TDataSource;
    Panel4: TPanel;
    Shape1: TShape;
    RECEPTQUERY: TIBQuery;
    RECEPTDBASE: TIBDatabase;
    RECEPTTRANZ: TIBTransaction;
    ARTQUERY: TIBQuery;
    ARTDBASE: TIBDatabase;
    ARTTRANZ: TIBTransaction;
    procedure KILEPOGOMBClick(Sender: TObject);
    procedure TaroltJpgTombbe;

    PROCEDURE hASONLITAS;
    procedure OkmParancs(_ukaz: string);
    procedure IrodanevBetoltes;

    procedure STARTGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure DATUMEDITEnter(Sender: TObject);
    procedure DATUMEDITExit(Sender: TObject);
    procedure DATUMEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);

    procedure JpegInsert(_j: string);
    function Nincsmegbeirva: boolean;
  
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _pTars,_hipt,_hipbiz: array[1..15000] of string;
  _psorszam,_hipsorszam: array[1..15000] of integer;
  _jpegss: array[1..15000] of integer;
  _ptnev: array[1..180] of string;
  _jpegdb,_aktptar,_code,_ss,_BDB,_cc,_utsorszam: integer;

  _betu,_uzlet: byte;
  _datadb,_hianydb: word;
  _sorszam,_y,_aktsorszam,_van,_nincs,_q,_recno: integer;
  _biztabla,_nevTabla,_pcs,_kertdatum,_pts,_aktptars,_minta,_jpegnev: string;
  _aktnev,_evtizes,_uznev,_aktbiz,_aktptarnev,_fdbpath: string;
  _sorveg: string = chr(13)+chr(10);
  _srec: TSearchRec;
  _megvan: boolean;

implementation

{$R *.dfm}

// =============================================================================
              procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin
  Panel2.Caption := 'IRODÁK BETÖLTÉSE';
  Panel2.Repaint;

  Csik.Max := 178;

  IrodaNevbetoltes;

  Panel2.caption := '';
  Panel2.repaint;
  csik.Position := 0;

  _kertdatum := trim(DatumEdit.Text);
  if length(_kertdatum)<>10 then
    begin
      Datumedit.clear;
      Activecontrol := DatumEdit;
      exit;
    end;


  Activecontrol := startGomb;
end;

// =============================================================================
           procedure TForm1.KILEPOGOMBClick(Sender: TObject);
// =============================================================================

begin
  okmQuery.close;
  OkmDbase.close;
  Application.terminate;
end;

// =============================================================================
                procedure TForm1.STARTGOMBClick(Sender: TObject);
// =============================================================================

begin
  _betu := 65;
  csik.Max := 24;

  HianySource.Enabled := False;

  _pcs := 'DELETE FROM OKMANYHIANY';
  OkmParancs(_pcs);


  while _betu<=90 do
    begin
      Csik.Position := _betu-64;
      Panel1.Caption := chr(_betu)+'NEV TÁBLA';
      Panel1.Repaint;

      _datadb := 0;
      _hianydb := 0;

      _biztabla := chr(_betu)+'BIZ';
      _nevtabla := chr(_betu)+'NEV';

      Panel2.caption := 'Tárolt okmányok legyüjtése';
      Panel2.repaint;

      TaroltJpgTombbe;

      Panel2.caption := 'Bizonylatok kiolvasása';
      Panel2.repaint;

      _pcs := 'SELECT * FROM ' + _biztabla + _sorveg;
      _pcs := _pcs + 'WHERE (DATUM>=' + chr(39) + _kertdatum + chr(39) +')';
      _pcs := _pcs + ' AND (FIZETENDO>=300000)' + _sorveg;
      _pcs := _pcs + 'ORDER BY SORSZAM';

      Bizdbase.Connected := true;
      with BizQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          last;
          _bdb := recno;
          First;
        end;

      Alcsik.Max := _bdb;
      _cc := 0;

      _utsorszam := 0;
      while not Bizquery.Eof do
        begin
          inc(_cc);
          Alcsik.Position := _cc;

          _aktbiz  := Bizquery.fieldbyname('BIZONYLATSZAM').asString;
          _pts  := midstr(_aktbiz,2,3);
          _sorszam := BizQuery.FieldByNAme('SORSZAM').asInteger;
          if _sorszam=_utsorszam then
            begin
              Bizquery.next;
              continue;
            end;

          _utsorszam := _sorszam;
          Panel3.caption := _aktbiz;
          Panel3.repaint;

          Hasonlitas;

          Bizquery.next;
        end;
      bizquery.close;
      bizdbase.close;
      Panel3.Caption := '';
      pANEL3.Repaint;

      //  ---------------------------------------------

      Okmdbase.Connected := True;
      if OkmTranz.InTransaction then OkmTranz.Commit;
      OkmTranz.StartTransaction;

      Nevdbase.Connected := true;

      if _hianydb>0 then
        begin
          Alcsik.Max := _hianydb;

          PANEL2.Caption := 'Hiányzó okmányok felirasa';
          Panel2.repaint;
          _y := 1;
          while _y<=_hianydb do
            begin
              Alcsik.Position := _y;
              _aktsorszam := _hipsorszam[_y];
              _aktptars := _hipt[_y];
              _aktbiz := _hipbiz[_y];
              val(_aktptars,_aktptar,_code);
              _aktptarnev := _ptnev[_aktptar];

              _pcs := 'SELECT * FROM ' + _nevtabla +  _sorveg;
              _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_aktsorszam);
              with Nevquery do
                begin
                  Close;
                  sql.clear;
                  Sql.add(_pcs);
                  Open;
                  _aktnev := FieldByNAme('NEV').asString;
                  Close;
                end;

              Panel4.Caption := _aktnev;
              Panel4.repaint;

              if nincsmegbeirva then
                begin
                  _pcs := 'INSERT INTO OKMANYHIANY (SORSZAM,NEV,PENZTAR,';
                  _pcs := _pcs + 'PENZTARNEV,BIZONYLATSZAM)'+_sorveg;
                  _pcs := _pcs + 'VALUES (' + inttostr(_aktsorszam)+',';
                  _pcs := _pcs + chr(39)+_aktnev+chr(39) + ',';
                  _pcs := _pcs + inttostr(_aktptar)+',';
                  _pcs := _pcs + chr(39) + _aktptarnev + chr(39)+',';
                  _pcs := _pcs + chr(39) + _aktbiz + chr(39) + ')';

                  with OkmQuery do
                    begin
                     Close;
                      sql.clear;
                      sql.add(_pcs);
                      Execsql;
                    end;

                end;
              Panel4.Caption := '';
              Panel4.repaint;

              inc(_y);
            end;
        end;
      okmtranz.commit;
      okmdbase.close;
      nevdbase.close;

      inc(_betu);
    end;

  pANEL1.Caption := '';
  pANEL1.repaint;

  pANEL2.Caption := '';
  pANEL2.repaint;


  Okmdbase.Connected := True;
  _pcs := 'SELECT * FROM OKMANYHIANY' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAR,NEV';
  with OkmQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;


  Csik.Position := 0;
  Alcsik.Position := 0;

  HianySource.Enabled := True;
  Racs.SetFocus;

end;


function TForm1.Nincsmegbeirva: boolean;

begin
  result := True;
  _pcs := 'SELECT * FROM OKMANYHIANY' + _sorveg;
  _pcs := _pcs + 'WHERE (SORSZAM='+inttostr(_aktsorszam)+')';
  _pcs := _pcs + ' AND (NEV='+chr(39)+_aktnev+chr(39)+')'+_sorveg;

  Okmdbase.connected := true;
  with Okmquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
      Close;
    end;
  Okmdbase.close;
  if _recno<0 then result := False;
end;


// =============================================================================
                         procedure TForm1.Hasonlitas;
// =============================================================================

begin
  _y := 1;
  while _y<=_jpegdb do
    begin
      if _jpegss[_y]= _sorszam then exit;
      inc(_y);
    end;
  inc(_hianydb);
  _hipt[_hianydb] := _pts;
  _hipsorszam[_hianydb] := _sorszam;
  _hipbiz[_hianydb] := _aktbiz;
end;


// =============================================================================
             procedure TForm1.DATUMEDITEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).color := clYellow;
end;

// =============================================================================
             procedure TForm1.DATUMEDITExit(Sender: TObject);
// =============================================================================

begin
  Tedit(Sender).Color := clWindow;
end;

// =============================================================================
     procedure TForm1.DATUMEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  _kertdatum := trim(datumedit.Text);
  if length(_kertdatum)<>10 then
    begin
      Datumedit.clear;
      Activecontrol := datumedit;
      exit;
    end;
  _evtizes := midstr(_kertdatum,3,2);
  _fdbPath := 'c:\receptor\database\ugyfel'+_evtizes+'.fdb';
  Bizdbase.close;
  Bizdbase.DatabaseName := _fdbPath;

  Nevdbase.close;
  Nevdbase.DatabaseName := _fdbPath;


  StartGomb.Enabled := True;
  Activecontrol := Startgomb;
end;


// =============================================================================
                     procedure TForm1.TaroltJpgTombbe;
// =============================================================================

begin
  _minta := 'D:\scanner\'+_nevtabla+'\*.jpg';
  if FindFirst(_minta, faAnyFile, _srec) = 0 then
    begin
      repeat
        _jpegnev := _srec.Name;
        Jpeginsert(_Jpegnev);
      until FindNext(_srec) <> 0;
      Findclose(_srec);
    end;
end;

// =============================================================================
                  procedure TForm1.JpegInsert(_j: string);
// =============================================================================

var _ww,_z,_asc: byte;

begin
  _ww := length(_j);
  _z := 1;
  while _z<_ww do
    begin
      _asc := ord(_j[_z]);
      if _asc=45 then break;
      inc(_z);
    end;

  _j := leftstr(_j,_z-1);

  val(_j,_ss,_code);
  if _jpegdb=0 then
    begin
      _jpegss[1] := _ss;
      _jpegdb := 1;
      exit;
    end;

  _q := 1;
  while _q<=_jpegdb do
    begin
      if _jpegss[_q]=_ss then exit;
      inc(_q);
    end;
  inc(_jpegdb);
  _jpegss[_jpegdb] := _ss;
end;


procedure TForm1. OkmParancs(_ukaz: string);

begin
  okmdbase.Connected := true;
  if okmtranz.InTransaction then okmtranz.Commit;
  Okmtranz.StartTransaction;
  with Okmquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Okmtranz.commit;
  Okmdbase.close;
end;


procedure TForm1.IrodanevBetoltes;

begin
  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  receptDbase.connected := true;
  with Receptquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not Receptquery.eof do
    begin
      _uzlet := ReceptQuery.fieldbyname('UZLET').asInteger;
      _uznev := trim(ReceptQuery.FieldByName('KESZLETNEV').asString);
      _ptnev[_uzlet] := _uzNev;

      Csik.Position := _uzlet;
      ReceptQuery.next;
    end;
  receptQuery.close;
  receptdbase.close;

  artdbase.connected := true;
  with artquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not Artquery.eof do
    begin
      _uzlet := ArtQuery.fieldbyname('UZLET').asInteger;
      _uznev := trim(ArtQuery.FieldByName('KESZLETNEV').asString);
      _ptnev[_uzlet] := _uzNev;
      Csik.Position := _uzlet;
      ArtQuery.next;
    end;
  ArtQuery.close;
  Artdbase.close;
end;



end.
