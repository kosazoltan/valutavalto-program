unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, IBDatabase, DB, IBQuery, IBCustomDataSet, IBTable,
  StdCtrls, strutils,Dateutils;

type
  TDBOOKCTRL = class(TForm)

    StartTimer  : TTimer;

    DayBookTabla: TIBTable;
    DayBookQuery: TIBQuery;
    DayBookDbase: TIBDatabase;
    DayBookTranz: TIBTransaction;

    ReceptTabla : TIBTable;
    ReceptQuery : TIBQuery;
    ReceptDbase : TIBDatabase;
    ReceptTranz : TIBTransaction;

    ExpTabla    : TIBTable;
    ExpQuery    : TIBQuery;
    ExpDbase    : TIBDatabase;
    ExpTranz    : TIBTransaction;

    EngTabla    : TIBTable;
    EngQuery    : TIBQuery;
    Engdbase    : TIBDatabase;
    EngTranz    : TIBTransaction;

    PtermTabla  : TIBTable;
    PtermQuery  : TIBQuery;
    PtermDbase  : TIBDatabase;
    PtermTranz  : TIBTransaction;

    Panel1      : TPanel;
    Kilepo      : TTimer;
    EXPBOOKTABLA: TIBTable;
    EXPBOOKQUERY: TIBQuery;
    EXPBOOKDBASE: TIBDatabase;
    EXPBOOKTRANZ: TIBTransaction;

    procedure ChParancs(_ukaz: string);
    procedure ZParancs(_ukaz: string);
    procedure FormActivate(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure MakeExpDayBook;
    procedure MakeEngedely;
    procedure MakePterm;
    procedure MakeChDaybook;
    procedure PenztarBeolvasas;
    procedure SetChDaybook;
    procedure SetZDayBook;

    function Nulele(_b: byte): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DBookCtrl: TDBookCtrl;

  _chPenztarszam: array[1..150] of byte;
  _zPenztarSzam : array[1..20] of byte;

  _satclose,_sunclose,_uzclose: array[1..180] of string;

  _maiDatum: TDateTime;

  _aktev,_aktho,_aktnap,_hNap,_havinap: word;
  _chPenztarDarab,_zPenztarDarab,_uzlet,_yPenztar: byte;

  _aktevs,_akthos,_farok,_tNev,_engNev,chPath,_pTermNev,_mezo: string;
  _aktclose,_aktsatclose,_aktsunclose,_pcs,_sclose,_tclose,_close: string;


  _sorveg: string = chr(13)+chr(10);

function daybookcontrol: integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
              function daybookcontrol: integer; stdcall;
// =============================================================================


begin
  dbookctrl := TDbookctrl.Create(Nil);
  result := dbookctrl.showmodal;
  dbookctrl.free;
end;


// =============================================================================
           procedure TDBOOKCTRL.FormActivate(Sender: TObject);
// =============================================================================

var _evtizs: string;

begin
  Left := 447;
  Top  := 66;
  repaint;

  _maidatum := date;

  _hNap     := dayoftheWeek(_maidatum);
  _aktev    := Yearof(_maidatum);
  _aktho    := Monthof(_maidatum);
  _aktnap   := Dayof(_maidatum);
  _havinap  := daysInAMonth(_aktev,_aktho);

  _aktevs   := inttostr(_aktev);
  _akthos   := nulele(_aktho);

  _evtizs   := midstr(_aktevs,3,2);

  _farok    := _evtizs + _AKThos;
  _tnev     := 'DAYB' + _farok;
  _engnev   := 'ENG' + _farok;
  _ptermnev := 'P_' + _evtizs + '_' + _akthos;

  PenztarBeolvasas;

  SetChDaybook;
  SetZDayBook;

  EngDbase.Connected := True;
  EngTabla.close;
  EngTabla.Tablename := _engNev;
  if not Engtabla.exists then MakeEngedely;
  EngDbase.close;

  PtermDbase.connected := True;
  PtermTabla.close;
  PtermTabla.Tablename := _ptermNev;
  if not Ptermtabla.exists then MakePterm;
  Ptermdbase.close;

  Kilepo.enabled := True;
end;


// =============================================================================
                    procedure TDBookCtrl.SetchDayBook;
// =============================================================================

var _y: byte;

begin
  DaybookDbase.connected := True;
  DayBookTabla.close;
  DaybookTabla.Tablename := _tNev;
  if not DayBookTabla.exists then MakeChDaybook;
  DayBookDbase.close;

  _mezo := 'N' + inttostr(_aktnap);

  _y := 1;
  while _y<=_chPenztarDarab do
    begin
      _uzlet       := _chPenztarszam[_y];
      _aktclose    := _uzClose[_uzlet];
      _aktsatClose := _satclose[_uzlet];
      _aktsunClose := _sunclose[_uzlet];

      if (_aktclose='X') or ((_hNap=6) AND (_aktSatClose='X')) or ((_hNap=7) and (_aktsunclose='X')) then
        begin
          _pcs := 'UPDATE ' + _tNev + ' SET ' + _MEZO + '='+chr(39)+'X'+chr(39)+_sorveg;
          _pcs := _pcs + 'WHERE PENZTAR='+inttostr(_uzlet);
          chParancs(_pcs);
        end;

      inc(_y);
    end;
end;

// =============================================================================
                       procedure TDBookCtrl.SetZDayBook;
// =============================================================================

var _y: byte;

begin
  ExpBookDbase.connected := True;
  ExpBookTabla.close;
  ExpBookTabla.Tablename := _tNev;
  if not ExpBookTabla.exists then MakeExpDayBook;
  ExpBookDbase.close;
end;


// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                     MAKE - DATABASE TABLAK                                 //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                       procedure TDBookCtrl.MakeChDaybook;
// =============================================================================


var _y: byte;

begin
  DayBookDbase.close;

  _pcs := 'CREATE TABLE ' + _tNev + ' (' + _sorveg;
  _pcs := _pcs + 'PENZTAR INTEGER,' + _sorveg;

  for _y := 1 to 30 do
      _pcs := _pcs + 'N' + inttostr(_y)+' CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;

  _pcs := _pcs + 'N31 CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250)';
  ChParancs(_pcs);

  _pcs := 'CREATE INDEX IDX_' +_tNev + ' ON ' + _tNev + ' (PENZTAR)';
  Chparancs(_pcs);

  // ---------------------------------------------------------------------

  _y := 1;
  while _y<=_chPenztarDarab do
    begin
      _yPenztar := _chPenztarSzam[_y];
      _pcs := 'INSERT INTO '+_tNev+' (PENZTAR) VALUES ('+inttostr(_ypenztar)+')';

      ChParancs(_pcs);
      inc(_y);
    end;
    
  _Y := 151;
  while _y<=168 do
    begin
      _pcs := 'INSERT INTO '+_tNev+' (PENZTAR) VALUES ('+inttostr(_y)+')';

      ChParancs(_pcs);
      inc(_y);
    end;
end;

// =============================================================================
             procedure TDBOOKCTRL.MakeExpDayBook;
// =============================================================================

var _y: byte;

begin

  DayBookDbase.close;

  _pcs := 'CREATE TABLE ' + _tNev + ' (' + _sorveg;
  _pcs := _pcs + 'PENZTAR INTEGER,' + _sorveg;

  for _y := 1 to 30 do
      _pcs := _pcs + 'N' + inttostr(_y)+' CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;

  _pcs := _pcs + 'N31 CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250)';
  zParancs(_pcs);

  _pcs := 'CREATE INDEX IDX_' +_tNev + ' ON ' + _tNev + ' (PENZTAR)';
  zParancs(_pcs);

  // --------------------------------------------------------

    // Beirja az új táblába az összes pénztár számát:

  _y := 151;
  while _y<=168 do
    begin
      _pcs := 'INSERT INTO '+_tNev+' (PENZTAR) VALUES ('+inttostr(_y)+')';
      zParancs(_pcs);
      inc(_y);
    end;
end;

////////////////////////////////////////////////////////////////////////////////
//                        SEGÉD PROGRAMOK
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                procedure TDBOOKCTRL.ChParancs(_ukaz: string);
// =============================================================================

begin
  dayBookDbase.Connected := true;
  if dayBookTranz.InTransaction then DayBookTranz.Commit;
  DayBooktranz.StartTransaction;

  with DayBookQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  DayBookTranz.commit;
  Daybookdbase.close;
end;

// =============================================================================
                procedure TDBOOKCTRL.ZParancs(_ukaz: string);
// =============================================================================

begin
  ExpBookDbase.Connected := true;
  if ExpBookTranz.InTransaction then ExpBookTranz.Commit;
  ExpBooktranz.StartTransaction;

  with ExpBookQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  ExpBookTranz.commit;
  ExpBookdbase.close;
end;

// =============================================================================
                 procedure TDBookCtrl.PenztarBeolvasas;
// =============================================================================


var _y: byte;

begin
  _pcs := 'SELECT * FROM IRODAK'+_sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  ReceptDbase.Connected := True;
  with ReceptQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  _y := 0;
  while not Receptquery.eof do
    begin
      with ReceptQuery do
        begin
          _uzlet  := FieldByNAme('UZLET').asInteger;
          _close  := FieldByNAme('CLOSED').asString;
          _sClose := FieldByNAme('SUNDAYCLOSE').asString;
          _tClose := FieldByNAme('SATURDAYCLOSE').asString;
        end;

      inc(_y);
      _chPenztarszam[_y]     := _uzlet;
      _uzclose[_uzlet]  := _close;
      _satclose[_uzlet] := _tClose;
      _sunClose[_uzlet] := _sClose;
      receptquery.next;
    end;

  receptQuery.close;
  receptdbase.close;
  _chPenztarDarab := _Y;

  // --------------------------------------------

  ExpDbase.Connected := True;
  with ExpQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  _y := 0;
  while not ExpQuery.eof do
    begin
      with ExpQuery do
        begin
          _uzlet  := FieldByNAme('UZLET').asInteger;
          _close  := FieldByNAme('CLOSED').asString;
          _sClose := FieldByNAme('SUNDAYCLOSE').asString;
          _tClose := FieldByNAme('SATURDAYCLOSE').asString;
        end;

      inc(_y);
      _zPenztarszam[_y]     := _uzlet;
      _uzclose[_uzlet]  := _close;
      _satclose[_uzlet] := _tClose;
      _sunClose[_uzlet] := _sClose;
      ExpQuery.next;
    end;

  ExpQuery.close;
  ExpDbase.close;

  _zPenztarDarab := _y;
end;

// =============================================================================
                      procedure TDBOOKCTRL.MakeEngedely;
// =============================================================================

begin
  _pcs := 'CREATE TABLE ' + _engnev + ' (' + _sorveg;
  _pcs := _pcs + 'ERTEKTAR SMALLINT,' + _sorveg;
  _pcs := _pcs + 'PENZTAR SMALLINT,' + _sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'IDO CHAR (8) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'BIZONYLATSZAM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'ENGEDELYTARGYA CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'TRANZAKCIO CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'OSSZEG INTEGER,' + _sorveg;
  _pcs := _pcs + 'KEDVARFOLYAM INTEGER,' + _sorveg;
  _pcs := _pcs + 'ENGEDELYEZO CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'KEZDIJENGEDELYTIPUS CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'KEDVKEZDIJ INTEGER,' + _sorveg;
  _pcs := _pcs + 'KEDVEZMENYKOD INTEGER,' + _sorveg;
  _pcs := _pcs + 'CONTROL SMALLINT)';

  if engTranz.InTransaction then engtranz.Commit;
  Engtranz.StartTransaction;
  with engQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;
  Engtranz.commit;
  Engdbase.close;
end;

// =============================================================================
                         procedure TDbookctrl.MakePterm;
// =============================================================================

begin
  _pcs := 'CREATE TABLE ' + _ptermnev + ' (' + _sorveg;
  _pcs := _pcs + 'BANKKOD INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO1 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK1 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO2 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK2 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO3 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK3 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO4 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK4 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO5 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK5 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO6 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK6 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO7 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK7 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO8 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK8 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO9 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK9 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO10 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK10 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO11 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK11 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO12 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK12 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO13 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK13 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO14 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK14 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO15 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK15 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO16 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK16 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO17 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK17 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO18 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK18 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO19 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK19 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO20 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK20 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO21 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK21 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO22 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK22 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO23 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK23 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO24 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK24 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO25 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK25 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO26 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK26 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO27 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK27 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO28 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK28 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO29 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK29 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO30 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK30 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSNETTO31 INTEGER,' + _sorveg;
  _pcs := _pcs + 'POSKK31 INTEGER,' + _sorveg;
  _pcs := _pcs + 'BETUJEL CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'CEGBETU CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250)';

  if Ptermtranz.InTransaction then Ptermtranz.Commit;
  Ptermtranz.StartTransaction;
  with Ptermquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      execsql;
    end;
  Ptermtranz.Commit;
  Ptermdbase.close;
end;

// =============================================================================
               procedure TDBOOKCTRL.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult :=1;
end;


function TdBookCtrl.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;




end.

