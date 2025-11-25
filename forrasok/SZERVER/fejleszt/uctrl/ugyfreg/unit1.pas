unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBQuery, IBCustomDataSet,
  IBTable, strutils, dateutils, ExtCtrls;

type
  TForm1 = class(TForm)
    BIZTABLA: TIBTable;
    BIZQUERY: TIBQuery;
    BIZDBASE: TIBDatabase;
    BIZTRANZ: TIBTransaction;
    NEVQUERY: TIBQuery;
    NEVDBASE: TIBDatabase;
    NEVTRANZ: TIBTransaction;
    KILEPO  : TTimer;
    Label1: TLabel;
    TASKMEMO: TMemo;
    partmemo: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;

    procedure UgyfelRegeneralo;
    procedure BizandNevNyitas;
    procedure FormActivate(Sender: TObject);
    procedure KillDouble;
    procedure KILEPOTimer(Sender: TObject);

    function Nulele(_b: byte): string;
    function Getweekday: string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _ss: array[1..1024] of word;
  _aktss: word;

  _betu : byte;

  _aktev,_TRanzdb,_aktho,_aktnap,_tegho,_tegnap: word;
  _ugyfdb,_ugyfss,_evimax,_sumft,_aktft,_recno,_hetift: integer;
  _aktevs,_evtizeds,_ugyfpath,_biztabla,_nevtabla,_pcs,_datums: string;
  _lastbiz,_aktbiz,_aktdatums,_honap,_tegdatums,_weekday: string;
  _sorveg: string = chr(13)+chr(10);

implementation

{$R *.dfm}

// =============================================================================
              procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin
  top := 250;
  left := 320;
  repaint; 


  _aktev    := yearof(date);
  _aktho    := monthof(date);
  _aktnap   := dayof(date);
  _aktevs   := inttostr(_aktev);
  _aktdatums:= _aktevs+'.'+nulele(_aktho)+'.'+nulele(_aktnap);
  _evtizeds := midstr(_aktevs,3,2);
  _honap    := midstr(_aktdatums,6,5);
  if _honap<'01.04' then
    begin
      Kilepo.Enabled := True;
      exit;
    end;

  _tegho := monthof(yesterday);
  _tegnap:= dayof(yesterday);
  _tegdatums := _aktevs+'.'+nulele(_tegho)+'.'+nulele(_tegnap);

  _ugyfpath := 'c:\receptor\database\ugyfel'+_evtizeds+'.fdb';

  _weekday := getweekday;

  TaskMemo.Lines.Clear;
  TaskMemo.Clear;
  PartMemo.Lines.clear;
  PartMemo.Clear;

  Taskmemo.repaint;
  Partmemo.repaint;

  KillDouble;
  UgyfelRegeneralo;
  taskmemo.clear;
  taskmemo.Lines.clear;

  taskmemo.clear;
  taskmemo.Lines.clear;
  Taskmemo.Lines.add('REGENERÁLÁS RENDBEN');
  Taskmemo.repaint;


  Kilepo.Enabled := true;
end;

// =============================================================================
                         procedure Tform1.Killdouble;
// =============================================================================

begin
  TaskMemo.Lines.add('Dupla bizonylatok kitörlése');
  Bizdbase.close;
  Bizdbase.DatabaseName := _ugyfPath;
  Bizdbase.connected := true;
  if Biztranz.intransaction then Biztranz.commit;
  Biztranz.startTransaction;

  _betu := 65;

  while _betu<=90 do
    begin
      _biztabla := chr(_betu)+'BIZ';
      TaskMemo.Lines.Add(_biztabla);

      PartMemo.Lines.clear;
      Partmemo.clear;
      Partmemo.repaint;


      _pcs := 'SELECT * FROM ' + _biztabla + _sorveg;
      _pcs := _pcs + 'ORDER BY BIZONYLATSZAM';
      with BizTabla do
        begin
          Close;
          Tablename := _biztabla;
          Open;
          indexfieldnames := 'BIZONYLATSZAM';
          last;
          _recno := recno;
          First;
        end;

      if _recno=0 then
        begin
          Biztabla.close;
          inc(_betu);
          continue;
        end;

      _lastbiz := 'xxxxxxxxxx';

      while not BizTabla.eof do
        begin
          _aktbiz := Biztabla.FieldByNAme('BIZONYLATSZAM').asString;
          if _aktbiz=_lastbiz then
            begin
              Biztabla.edit;
              Biztabla.fieldbyname('SORSZAM').asInteger := 0;
              Biztabla.Post;
            end;
          _lastbiz := _aktbiz;
          PartMemo.Lines.add(_lastbiz);
          Biztabla.next;
        end;

      inc(_betu);
    end;

  // ----------------------------------------------------

  _biztabla := 'JOGIBIZ';
  TaskMemo.Lines.add('JOGI BIZONYLATOK');

  Partmemo.lines.clear;
  Partmemo.clear;
  Partmemo.repaint;

  _pcs := 'SELECT * FROM ' + _biztabla + _sorveg;
  _pcs := _pcs + 'ORDER BY BIZONYLATSZAM';

  with BizTabla do
    begin
      CLOSE;
      Tablename := _biztabla;
      Open;
      indexfieldnames := 'BIZONYLATSZAM';
      First;
    end;

  _lastbiz := 'xxxxxxxxxx';
  while not BizTabla.eof do
    begin
      _aktbiz := Biztabla.FieldByNAme('BIZONYLATSZAM').asString;
      Partmemo.Lines.Add(_aktbiz);
      if _aktbiz=_lastbiz then
        begin
          Biztabla.edit;
          Biztabla.fieldbyname('SORSZAM').asInteger := 0;
          Biztabla.Post;
        end;
      _lastbiz := _aktbiz;
      Biztabla.next;
    end;
  Biztranz.commit;
  Bizdbase.close;
  Bizquery.close;
  Biztabla.close;

  // ----------------------------------------------------------

  _betu := 65;
  Bizdbase.connected := true;
  if Biztranz.intransaction then Biztranz.commit;
  Biztranz.startTransaction;

  TaskMemo.Lines.Add('Végleges törlés');

  while _betu<=90 do
    begin
      _biztabla := chr(_betu)+'BIZ';
      Partmemo.Lines.Add(_BIZTABLA);
      _pcs := 'DELETE FROM ' + _biztabla + _sorveg;
      _pcs := _pcs + 'WHERE SORSZAM=0';
      with Bizquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Execsql;
        end;
      inc(_betu);
    end;

  _pcs := 'DELETE FROM JOGIBIZ' + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=0';
  with Bizquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;
  BizTranz.commit;
  bizdbase.close;
  Bizquery.close;
  TaskMemo.lines.Add('A DUPLA BIZONYLATOK TÖRÖLVE');
  sleep(2500);
end;

// =============================================================================
                procedure TForm1.Ugyfelregeneralo;
// =============================================================================

begin
  pARTMEMO.Lines.Clear;
  Partmemo.Clear;
  Partmemo.Repaint;

  TaskMemo.Lines.clear;
  Taskmemo.clear;
  Taskmemo.Lines.add('ADATOK REGENERÁLÁSA');
  TaskMemo.repaint;

  BizAndNevNyitas;

  _betu := 65;
  while _betu<=90 do
    begin
      _biztabla := chr(_betu) + 'BIZ';
      _nevtabla := chr(_betu) + 'NEV';

      TaskMemo.Lines.Add(_nevtabla+' '+_biztabla);

      _pcs := 'SELECT * FROM ' + _biztabla + _sorveg;
      _pcs := _pcs + 'WHERE (DATUM='+ chr(39)+_tegdatums+chr(39)+')';

      with Bizquery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
        end;

      _ugyfdb := 0;
      while not Bizquery.eof do
        begin
          inc(_ugyfdb);
          _ss[_ugyfdb] := Bizquery.FieldByNAme('SORSZAM').asInteger;
          Bizquery.Next;
        end;

      Bizquery.close;

      if _ugyfdb=0 then
        begin
          inc(_betu);
          continue;
        end;

      _ugyfss := 1;
      while _ugyfss<=_ugyfdb do
        begin
          _aktss := _ss[_ugyfss];
          _pcs := 'SELECT * FROM ' + _biztabla + _sorveg;
          _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_aktss)+ _sorveg;
          _pcs := _pcs + 'ORDER BY DATUM';

          with Bizquery do
            begin
              CLose;
              sql.clear;
              sql.add(_pcs);
              Open;
            end;

          _evimax  := 0;
          _sumFt   := 0;
          _tranzDb := 0;
          _hetift  := 0;

          while not Bizquery.Eof do
            begin
              inc(_tranzdb);

              _aktdatums := Bizquery.fieldByName('DATUM').asString;
              _aktFt  := Bizquery.fieldByNAme('FIZETENDO').asInteger;
              _sumFt := _sumFt + _aktFt;

              if _aktdatums>=_weekday then _hetift := _hetift + _aktft;

              if _aktFt>_evimax then _evimax := _aktFt;
              bizquery.next;
            end;
          Bizquery.close;

          _pcs := 'UPDATE ' + _NEVTABLA + ' SET TRANZAKCIODB='+inttostr(_tranzdb);
          _pcs := _pcs + ',EVIMAX='+inttostr(_evimax);
          _pcs := _pcs + ',FORINTOSSZEG='+inttostr(_sumFt);
          _pcs := _pcs + ',HETIOSSZ='+inttostr(_hetiFt);
          _pcs := _pcs + ',DATUM='+chr(39)+_AKTdatums+chr(39)+_sorveg;
          _pcs := _pcs + 'WHERE SORSZAM='+inttostr(_aktss);

          Partmemo.lines.add(_nevtabla+' = '+inttostr(_sumft));

          with Nevquery do
            begin
              Close;
              Sql.clear;
              sql.add(_pcs);
              Execsql;
            end;
          Nevquery.close;
          inc(_ugyfss);
        end;
      Nevquery.close;
      BizQuery.close;
      inc(_betu);
   end;

  Nevtranz.commit;
  Nevdbase.close;
  nevquery.close;

  Bizquery.close;
  Bizdbase.close;

  //------------------------  jogi javitas -------------------------------------

  BizAndNevNyitas;

  Taskmemo.Lines.add('JOGI REGENERÁLÁS');
  Partmemo.Clear;
  Partmemo.Lines.Clear;
  PartMemo.repaint;

  _pcs := 'SELECT * FROM JOGIBIZ' + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39)+ _tegdatums + chr(39) + _sorveg;
  _pcs := _pcs + 'ORDER BY SORSZAM';

  _ugyfdb := 0;
  with Bizquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      close;
    end;

  _ugyfss := 0;
  while not Bizquery.eof do
    begin
      _aktss := Bizquery.fieldByName('SORSZAM').asInteger;
      inc(_ugyfdb);
      _ss[_ugyfdb] := _aktss;
      Bizquery.next;
    end;
  BizQuery.close;

  if _ugyfdb>0 then
    begin
      _ugyfss := 1;
      while _ugyfss<=_ugyfdb do
        begin
         _aktss := _ss[_ugyfss];
         _pcs := 'SELECT * FROM JOGIBIZ' + _sorveg;
         _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_aktss)+_sorveg;
         _pcs := _pcs + 'ORDER BY DATUM';

         Partmemo.Lines.Add(inttostr(_ugyfss));

         with Bizquery do
           begin
             close;
             sql.clear;
             sql.add(_pcs);
             Open;
           end;

         _tranzdb := 0;
         _sumFt   := 0;
         _evimax  := 0;
         _hetift  := 0;

         while not Bizquery.Eof do
           begin
            _aktft  := Bizquery.FieldByNAme('FIZETENDO').asInteger;
            _datums := Bizquery.fieldbyname('DATUM').asString;

            inc(_tranzdb);

            _sumFt := _sumFt + _aktFt;
            if _datums>=_weekday then _hetift := _hetift + _aktft;
            if _aktFt>_evimax then _evimax := _aktFt;
            Bizquery.next;
           end;

         Bizquery.close;

         _pcs := 'UPDATE JOGI SET FORINTOSSZEG='+inttostr(_sumFt);
         _pcs := _pcs + ',DATUM=' + chr(39) + _datums + chr(39);
         _pcs := _pcs + ',EVIMAX=' + INTTOSTR(_evimax);
         _pcs := _pcs + ',TRANZAKCIODB='+inttostr(_tranzdb);
         _pcs := _pcs + ',HETIOSSZ=' + inttostr(_hetift)+_sorveg;
         _pcs := _pcs + 'WHERE SORSZAM=' +inttostr(_ugyfss);

         with Nevquery do
           begin
             Close;
             sql.clear;
             sql.add(_pcs);
             Execsql;
           end;
        end;
      Bizquery.close;
      NevQuery.close;
      inc(_ugyfss);
    end;

  Nevtranz.commit;
  Nevdbase.close;
  nevquery.close;

  Bizquery.close;
  Bizdbase.close;
end;


// =============================================================================
                       procedure TForm1.BizandNevNyitas;
// =============================================================================

begin
  bizdbase.close;
  bizdbase.databasename := _ugyfPath;

  nevdbase.close;
  nevdbase.databasename := _ugyfPath;

  bizdbase.connected := True;
  nevdbase.connected := True;

  If nevtranz.InTransaction then nevtranz.commit;
  nevtranz.StartTransaction;
end;


function TForm1.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


function TForm1.Getweekday: string;

var _weekdate: TDatetime;
    _wev,_who,_wnap: word;

begin
  _weekdate := yesterday-7;
  _wev := yearof(_weekdate);
  _who := monthof(_weekdate);
  _wnap := dayof(_weekdate);
  result := inttostr(_wev)+'.'+nulele(_who)+'.'+nulele(_wnap);
end;





// =============================================================================
               procedure TForm1.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  kILEPO.Enabled := False;
  Application.Terminate;
end;

end.
