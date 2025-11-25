
unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, IBDatabase, DB, IBCustomDataSet,
  IBQuery, strutils, IBTable, Buttons, Grids, DBGrids, jpeg;

type
  TForm2 = class(TForm)
    Csik              : TProgressBar;
    Kilepo            : TTimer;
    Image1            : TImage;

    GombPanel         : TPanel;
    Panel1            : TPanel;
    RacsPanel         : TPanel;
    UzenoPanel        : TPanel;

    RecQuery          : TIBQuery;
    RecDbase          : TIBDatabase;
    RecTranz          : TIBTransaction;

    vQuery            : TIBQuery;
    vDbase            : TIBDatabase;
    vTranz            : TIBTransaction;
    vTabla            : TIBTable;

    wQuery            : TIBQuery;
    wDbase            : TIBDatabase;
    wTranz            : TIBTransaction;

    Racs              : TDBGrid;
    WafaSource        : TDataSource;
    WuniSource        : TDataSource;

    wQueryKuldes      : TIBStringField;
    wQueryFogadas     : TIBStringField;
    wQueryKuldo       : TIBStringField;
    wQueryFogado      : TIBStringField;
    wQueryValutanem   : TIBStringField;
    wQueryKuldottPenz : TIntegerField;
    wQueryFogadottPenz: TIntegerField;
    wQueryStatus      : TIBStringField;

    WafaGomb          : TBitBtn;
    WuniGomb          : TBitBtn;
    NoEquGomb         : TBitBtn;
    AllTranzGomb      : TBitBtn;
    BackToMenuGomb    : TBitBtn;
    Shape1: TShape;

    procedure PenztarParaBeolvasas;
    procedure PenztarSorEpito;
    procedure GetIdoszak;
    procedure KilepoTimer(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure ErtektarGyujto;
    procedure PenztarGyujto;
    procedure NoEquGombClick(Sender: TObject);
    procedure AllTranzGombClick(Sender: TObject);
    procedure BackToMenuGombClick(Sender: TObject);
    procedure WafaGombClick(Sender: TObject);
    procedure WuniGombClick(Sender: TObject);
    procedure Wafafeliras;
    procedure Wunifeliras;
    procedure Wparancs(_ukaz: string);

    function Nul3(_sm: byte): string;
    function Scanwafa(_astr: string): word;
    function Scanwuni(_astr: string): word;
    function Ezertektar(_ptr: byte): boolean;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _korzet: array[1..170] of byte;
  _penztarnev: array[1..170] of string;
  _penztarsor: array[1..170] of byte;

  _wastring,_wustring: array[1..4096] of string;
  _wafajegy,_wunijegy: array[1..4096] of integer;
  _sorveg: string = chr(13)+chr(10);

  _wuni,_wafa,_tesco,_aktwastr,_aktwustr,_fogadas,_fogadonev: string;
  _kftipus,_kuldostr,_fogadostr,_ellenstring: string;
  _pcs,_status,_farok,_tolstring,_igstring,_daybook,_uznev,_tipus: string;
  _kertevs,_kerthos,_kezdnaps,_vegnaps,_fdbPath,_aMezo,_aktfdb,_filter: string;
  _sorszam,_ttip,_aktdnem,_utip,_aktstring,_kuldos,_kuldonev,_keres: string;
  _kertev,_kertho,_kezdnap,_vegnap,_ss,_xx: word;

  _swadb,_swudb,_y,_fogado,_kuldokod: word;
  _csikss,_aNap,_wadb,_wudb,_kuldo,_fogadokod: word;

  _pt,_ptss,_penztardarab,_uzlet,_ertektar,_ptszam,_aktkorzet,_foe: byte;

  _mResult,_code,_idszOke,_osszeg,_aktwabjegy,_aktwubjegy,_bankjegy: integer;
  _recno,_kuldottpenz,_fogadottpenz: integer;

  _ezErtektar: boolean;


function getidoszakrutin: integer; stdcall; external 'c:\receptor\newdll\idoszak.dll';

function wuafaatadatvet: integer; stdcall;


implementation

{$R *.dfm}


// =============================================================================
                       function wuafaatadatvet: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.showmodal;
  Form2.Free;
end;


// =============================================================================
              procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

var i: word;

begin
  TOP  := 200;
  Left := 310;
  repaint;

  _idszOke := getidoszakrutin;

  if _idszoke=-1 then
    begin
      _mResult := -1;
      Kilepo.Enabled := true;
      exit;
    end;

  image1.visible := True;
  Image1.repaint;

  for i:=1 to 4096 do
    begin
      _wafaJegy[i] := 0;
      _wuniJegy[i] := 0;
    end;

  PenztarParaBeolvasas;

  GetIdoszak;

  _wuni  := 'WUNI' + _farok;
  _wafa  := 'WAFA' + _farok;
  _tesco := 'TESC' + _farok;

  _wadb := 0;
  _wudb := 0;

  PenztarSorEpito;
  Csik.Max := _penztardarab;

  _ptss := 1;
  while _ptss<=_penztarDarab do
    begin
      Csik.Position := _ptss;

      _pt := _penztarSor[_ptss];
      _ezErtektar := Ezertektar(_pt);

      UzenoPanel.caption := inttostr(_pt)+' '+ _penztarNev[_pt];
      UzenoPanel.Repaint;

      if _ezErtektar then ErtekTargyujto
      else PenztarGyujto;

      inc(_ptss);
    end;

  WafaFeliras;
  WuniFeliras;

  WuniSource.Enabled := False;
  WafaSource.Enabled := False;

  _filter := 'ALLTRANZ';

  _pcs := 'SELECT * FROM WAFATRANZ';
  Wdbase.Connected := True;
  with Wquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

   UzenoPanel.Caption := 'AFA VISSZATÉRITÉS';
   UzenoPanel.repaint;

   with GombPanel do
     begin
       top  := 48;
       left := 144;
       Visible := True;
       repaint;
     end;

   Image1.Visible := False;

   _tipus := 'WAFA';
   with RacsPanel do
     begin
       top := 96;
       left:= 8;
       Visible := True;
       repaint;
     end;

   wafasource.Enabled := False;
   racs.Enabled := False;
   racs.DataSource := wafasource;
   Wafasource.Enabled := True;
   Racs.Enabled  := True;
   Activecontrol := Racs;
end;

// =============================================================================
                           procedure TForm2.PenztarGyujto;
// =============================================================================

begin
  _aktFdb := 'c:\receptor\database\v'+inttostr(_pt)+'.fdb';

  with VDbase do
    begin
      Close;
      DatabaseName := _aktFdb;
      Connected    := True;
    end;

  _aktkorzet := _korzet[_pt];

  vTabla.Close;
  vTabla.TableName := _tesco;
  if Vtabla.Exists then
    begin
      _pcs := 'SELECT * FROM ' + _tesco + _sorveg;
      _pcs := _pcs + 'WHERE (DATUM>'+CHR(39)+_TOLSTRING+chr(39)+') AND (';
      _pcs := _pcs + 'DATUM<='+chr(39)+_igstring+chr(39)+')';

      with Vquery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
        end;

      while not Vquery.Eof do
        begin
          _ttip   := Vquery.fieldByName('TIPUS').asString;
          _osszeg := Vquery.FieldByName('OSSZESEN').asInteger;

          if _ttip='B' then
            begin
              _aktString := 'F' + nul3(_aktkorzet) + 'HUF' + nul3(_pt);
              _xx := ScanWafa(_aktstring);
              _wafajegy[_xx] := _wafajegy[_xx] + _osszeg;
            end;
          Vquery.next;
        end;
      Vquery.close;
    end;

   // --------------------------------------------------------

  vTabla.Close;
  vTabla.TableName := _wafa;
  if Vtabla.Exists then
    begin
      _pcs := 'SELECT * FROM ' + _wafa + _sorveg;
      _pcs := _pcs + 'WHERE (DATUM>'+CHR(39)+_TOLSTRING+chr(39)+') AND (';
      _pcs := _pcs + 'DATUM<='+chr(39)+_igstring+chr(39)+')';
      _pcs := _pcs + ' AND (STORNO=1)';

      with Vquery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
        end;

      while not Vquery.Eof do
        begin
          _sorszam   := Vquery.fieldByName('SORSZAM').asString;
          _osszeg := Vquery.FieldByName('ELLATMANY').asInteger;
          _ttip := leftstr(_sorszam,2);

          if _ttip='AB' then
            begin
              _aktString := 'F' + nul3(_aktkorzet) + 'HUF' + nul3(_pt);
              _xx := ScanWafa(_aktstring);
              _wafajegy[_xx] := _wafajegy[_xx] + _osszeg;
            end;
          Vquery.next;
        end;
      Vquery.close;
    end;


   // --------------------------------------------------------

  Vtabla.close;
  vtabla.TableName := _wuni;
  if Vtabla.Exists then
    begin
      _pcs := 'SELECT * FROM ' + _wuni + _sorveg;
      _pcs := _pcs + 'WHERE (DATUM>'+CHR(39)+_TOLSTRING+chr(39)+') AND (';
      _pcs := _pcs + 'DATUM<='+chr(39)+_igstring+chr(39)+')';
      _pcs :=  _pcs + ' AND (STORNO=1)';

      with Vquery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
        end;

      while not Vquery.Eof do
        begin
          _sorszam := VQuery.FieldByNAme('SORSZAM').asString;
          _ptszam  := Vquery.FieldByNAme('PENZTARSZAM').asInteger;
          _osszeg  := Vquery.FieldByName('BANKJEGY').asInteger;
          _aktdnem := VQuery.fieldByNAme('VALUTANEM').asString;
          _utip    := Vquery.FieldByNAme('UGYFELTIPUS').asString;
          _ttip    := leftstr(_sorszam,2);

          if (_ttip='WB') AND (_utip='P') then
            begin
              _aktstring := 'F'+nul3(_aktkorzet)+_aktdnem+nul3(_pt);
              _xx := Scanwuni(_aktstring);
              _wunijegy[_xx] := _wunijegy[_xx] + _osszeg;
            end;

          if (_ttip='WK') AND (_utip='P') then
            begin
              _aktstring := 'K'+nul3(_pt)+_aktdnem+nul3(_aktkorzet);
              _xx := Scanwuni(_aktstring);
              _wunijegy[_xx] := _wunijegy[_xx] + _osszeg;
            end;
          Vquery.next;
        end;
      Vquery.close;
    end;
  Vdbase.close;
end;

// =============================================================================
                          procedure TForm2.ERtektarGyujto;
// =============================================================================

begin
  _aktfdb := 'c:\receptor\database\v'+inttostr(_pt)+'.fdb';

  with VDbase do
    begin
      Close;
      DatabaseName := _aktfdb;
      Connected := true;
    end;

  Vtabla.close;
  vtabla.TableName := _wafa;
  if Vtabla.Exists then
    begin
      _pcs := 'SELECT * FROM ' + _wafa + _sorveg;
      _pcs := _pcs + 'WHERE (DATUM>='+CHR(39)+_TOLSTRING+chr(39)+') AND (';
      _pcs := _pcs + 'DATUM<='+chr(39)+_igstring+chr(39)+')';
      _pcs :=  _pcs + ' AND (STORNO=1)';

      with Vquery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
        end;

      while not Vquery.Eof do
        begin
          _sorszam := VQuery.FieldByNAme('SORSZAM').asString;
          _ptszam  := Vquery.FieldByNAme('PENZTARSZAM').asInteger;
          _osszeg  := Vquery.FieldByNAme('ELLATMANY').asInteger;
          _ttip    := leftstr(_sorszam,2);

          if _ttip='AK' then
            begin
              _aktstring := 'K'+nul3(_pt)+'HUF'+nul3(_ptszam);
              _xx := ScanWafa(_aktstring);
              _wafajegy[_xx] := _wafajegy[_xx] + _osszeg;
            end;
          Vquery.next;
        end;

      VQuery.close;
    end;

  // ---------------------------------------------------------------------------

  Vtabla.close;
  vtabla.TableName := _wuni;
  if Vtabla.Exists then
    begin
      _pcs := 'SELECT * FROM ' + _wuni + _sorveg;
      _pcs := _pcs + 'WHERE (DATUM>='+CHR(39)+_TOLSTRING+chr(39)+') AND (';
      _pcs := _pcs + 'DATUM<='+chr(39)+_igstring+chr(39)+')';
      _pcs :=  _pcs + ' AND (STORNO=1)';

      with Vquery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
        end;

      while not Vquery.Eof do
        begin
          _sorszam := VQuery.FieldByNAme('SORSZAM').asString;
          _ptszam  := Vquery.FieldByNAme('PENZTARSZAM').asInteger;
          _osszeg  := Vquery.FieldByNAme('BANKJEGY').asInteger;
          _aktdnem := VQuery.FieldByName('VALUTANEM').asString;
          _ttip    := leftstr(_sorszam,2);

          if _ttip= 'WK' then
            begin
              _aktstring := 'K'+nul3(_pt)+_aktdnem+nul3(_ptszam);
              _xx := scanwuni(_aktstring);
              _wunijegy[_xx] := _wunijegy[_xx] + _osszeg;
            end;

          if (_ttip='WB') AND (_ptszam>0) then
            begin
              _aktstring := 'F'+nul3(_ptszam)+_aktdnem+nul3(_pt);
              _xx := Scanwuni(_aktstring);
              _wunijegy[_xx] := _wunijegy[_xx] + _osszeg;
            end;
          Vquery.next;
        end;
      Vquery.close;
      Vdbase.close;
    end;
end;

// =============================================================================
                function TForm2.Scanwafa(_astr: string): word;
// =============================================================================

var _z: word;

begin
  if _wadb=0 then
    begin
      _wastring[1] := _astr;
      _wadb := 1;
      result := 1;
      exit;
    end;

  _z := 1;
  while _z<=_wadb do
    begin
      if _wastring[_z]=_astr then
        begin
          result := _z;
          exit;
        end;
      inc(_z);
    end;
  inc(_wadb);
  _wastring[_wadb] := _astr;
  result := _wadb;
end;

// =============================================================================
                function TForm2.Scanwuni(_astr: string): word;
// =============================================================================

var _z: word;

begin
  if _wudb=0 then
    begin
      _wustring[1] := _astr;
      _wudb := 1;
      result := 1;
      exit;
    end;

  _z := 1;
  while _z<=_wudb do
    begin
      if _wustring[_z]=_astr then
        begin
          result := _z;
          exit;
        end;
      inc(_z);
    end;
  inc(_wudb);
  _wustring[_wudb] := _astr;
  result := _wudb;
end;

// =============================================================================
                   procedure TForm2.PenztarSorEpito;
// =============================================================================
//
//   EGY ADOTT IDÕSZAK ALATT NYITVALÉVÕ PÉNZTÁRAK SZÁMÁT PÉNZTÁRSORBA GYÜJTI
//                   (_penztarsor[1.._penztardarab])
//
begin
  Csik.Position := 0;
  _csikss := 0;

  uzenoPanel.Caption := 'A NYITVATARTÓ PÉNZTÁRAK ÖSSZEIRÁSA';
  uzenoPanel.Repaint;

  _farok := midstr(_tolstring,3,2)+midstr(_tolstring,6,2);
  _daybook := 'DAYB' + _farok;

  _fdbPath := 'c:\receptor\database\DAYBOOK.FDB';
  with RecDbase do
    begin
      Close;
      DatabaseName := _fdbPath;
      Connected := true;
    end;

  with RecQuery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM ' + _daybook + ' ORDER BY PENZTAR');
      Open;
    end;

  while not RecQuery.Eof do
    begin
      inc(_csikss);
      Csik.Position := _csikss;

      _pt := RecQuery.fieldByName('PENZTAR').asInteger;
      if _pt>150 then
        begin
          Recquery.next;
          continue;
        end;

      _status := 'X';

      _anap   := _kezdnap;
      while _anap<=_vegnap do
        begin
          _aMezo  := 'N' + inttostr(_anap);
          _status := RecQuery.Fieldbyname(_aMezo).asString;
          if _status='B' then break;
          inc(_anap);
        end;

      if _status='B' then
        begin
          inc(_ptss);
          _penztarsor[_ptss] := _pt;
        end;
      RecQuery.next;
    end;
  RecQuery.close;
  RecDbase.close;

  csik.Position := 170;
  sleep(1500);

  _penztarDarab := _ptss;
end;

// =============================================================================
                    procedure TForm2.PenztarParaBeolvasas;
// =============================================================================

begin
  uzenoPanel.Caption := 'Pémztárak adatainak beolvasása';
  uzenoPanel.Repaint;

  Csik.Max := 170;
  _csikss := 0;
  Csik.Visible := True;

  _fdbPath := 'c:\receptor\database\receptor.fdb';
  with Recdbase do
    begin
      Close;
      DatabaseName := _fdbPath;
      Connected := true;
    end;

  with Recquery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM IRODAK ORDER BY UZLET');
      Open;
    end;

  while not recquery.eof do
    begin
      inc(_csikss);
      Csik.Position := _csikss;

      _uzlet := RecQuery.fieldbyname('UZLET').asInteger;
      IF _UZLET>150 then
        begin
          recquery.next;
          continue;
        end;
      _uznev := trim(RecQuery.FieldByName('KESZLETNEV').asString);
      _ertektar := Recquery.FieldByNAme('ERTEKTAR').asInteger;

      UzenoPanel.caption := _uznev;
      Uzenopanel.repaint;

      _penztarNev[_uzlet] := _uznev;
      _korzet[_uzlet] := _ertektar;

      recQuery.next;
    end;
  recquery.close;
  recdbase.close;

  Csik.Position := 170;
  sleep(1500);
end;

// =============================================================================
                     procedure TForm2.GetIdoszak;
// =============================================================================

begin
  _fdbPath := 'c:\receptor\database\receptor.fdb';
  with Recdbase do
    begin
      Close;
      DatabaseName := _fdbPath;
      Connected := true;
    end;

  with RecQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM IDOSZAK');
      Open;
      _tolstring := FieldByName('STARTDATE').asString;
      _igstring  := trim(FieldByName('ENDDATE').asString);
      Close;
    end;
  recdbase.close;

  _kertevs  := leftstr(_tolstring,4);
  _kerthos  := midstr(_tolstring,6,2);
  _kezdnaps := midstr(_tolstring,9,2);
  _vegNaps  := midstr(_igstring,9,2);

  val(_kertevs,_kertev,_code);
  val(_kerthos,_kertho,_code);
  val(_kezdnaps,_kezdnap,_code);
  val(_vegnaps,_vegnap,_code);

  _FAROK := midstr(_tolstring,3,2)+midstr(_tolstring,6,2);

end;

// =============================================================================
              procedure TForm2.KilepoTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := _mResult;
end;


// =============================================================================
            function TForm2.Ezertektar(_ptr: byte): boolean;
// =============================================================================

begin
  result := True;

  if (_ptr=10) or (_ptr=20) or (_ptr=40) or (_ptr=50) or (_ptr=63) then exit;
  if (_ptr=75) or (_ptr=120) or (_ptr=145) then exit;

  result := False;
end;

// =============================================================================
                 function TForm2.Nul3(_sm: byte): string;
// =============================================================================

begin
  result := inttostr(_sm);
  while length(result)<3 do result := '0' + result;
end;

// =============================================================================
                       procedure TForm2.WAFAfeliras;
// =============================================================================

begin
  UzenoPanel.Caption := 'Afa adarok felirása';
  UzenoPanel.Repaint;

  Csik.Max := _wadb;
  _pcs := 'DELETE FROM WAFATRANZ';
  wParancs(_pcs);

  _y := 1;
  while _y<=_wadb do
    begin
      Csik.Position := _y;
      _aktstring := _wastring[_y];
      _kftipus   := leftstr(_aktstring,1);
      _kuldostr  := midstr(_aktstring,2,3);
      _aktdnem   := midstr(_aktstring,5,3);
      _fogadostr := midstr(_aktstring,8,3);

      val(_kuldostr,_kuldokod,_code);
      val(_fogadostr,_fogadokod,_code);

      if _kftipus='K' then
        begin
          _bankjegy    := _wafaJegy[_y];
          _kuldonev    := _penztarnev[_kuldokod];
          _ellenstring := 'F' + midstr(_aktstring,2,9);

          _pcs := 'SELECT * FROM WAFATRANZ WHERE FOGADAS='+chr(39)+_ellenstring+chr(39);

          wDbase.Connected := True;
          with wQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
              _recno := recno;
            end;

          if _recno>0 then
            begin
              _fogadottpenz := wQuery.fieldByName('FOGADOTTPENZ').asInteger;
              wQuery.close;
              wDbase.close;

              if _fogadottPenz=_bankjegy then _status:='OK' else _status:='?';

              _pcs := 'UPDATE WAFATRANZ SET KULDES='+chr(39)+_aktstring+chr(39);
              _pcs := _pcs + ',KULDO=' + chr(39) + _kuldonev + chr(39);
              _pcs := _pcs + ',KULDOTTPENZ=' + inttostr(_bankjegy);
              _pcs := _pcs + ',STATUS=' + chr(39) + _status + chr(39) + _sorveg;
              _pcs := _pcs + 'WHERE FOGADAS='+chr(39)+_ellenstring+chr(39);
              wParancs(_pcs);
              inc(_y);
              Continue;
            end;

          if _recno=0 then
            begin
              _pcs := 'INSERT INTO WAFATRANZ (KULDES,KULDO,VALUTANEM,KULDOTTPENZ,';
              _pcs := _pcs + 'STATUS)' + _sorveg;
              _pcs := _pcs + 'VALUES (' + chr(39) + _aktstring + chr(39) + ',';
              _pcs := _pcs + chr(39) + _kuldonev + chr(39) + ',';
              _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
              _pcs := _pcs + inttostr(_bankjegy) + ',';
              _pcs := _pcs + chr(39) + '?' + chr(39) + ')';
              wParancs(_pcs);
              inc(_y);
              continue;
            end;
        end;

      // =======================================

      if _kftipus='F' then
        begin
          _bankjegy    := _wafaJegy[_y];
          _fogadonev    := _penztarnev[_fogadokod];
          _ellenstring := 'K' + midstr(_aktstring,2,9);

          _pcs := 'SELECT * FROM WAFATRANZ WHERE KULDES='+chr(39)+_ellenstring+chr(39);

          wDbase.Connected := True;
          with wQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
              _recno := recno;
            end;

          if _recno>0 then
            begin
              _kuldottpenz := wQuery.fieldByName('KULDOTTPENZ').asInteger;
              wQuery.close;
              wDbase.close;

              if _kuldottPenz=_bankjegy then _status:='OK' else _status:='?';

              _pcs := 'UPDATE WAFATRANZ SET FOGADAS='+chr(39)+_aktstring+chr(39);
              _pcs := _pcs + ',FOGADO=' + chr(39) + _fogadonev + chr(39);
              _pcs := _pcs + ',FOGADOTTPENZ=' + inttostr(_bankjegy);
              _pcs := _pcs + ',STATUS=' + chr(39) + _status + chr(39) + _sorveg;
              _pcs := _pcs + 'WHERE KULDES='+chr(39)+_ellenstring+chr(39);
              wParancs(_pcs);
              inc(_y);
              Continue;
            end;

          if _recno=0 then
            begin
              _pcs := 'INSERT INTO WAFATRANZ (FOGADAS,FOGADO,VALUTANEM,FOGADOTTPENZ,';
              _pcs := _pcs + 'STATUS)' + _sorveg;
              _pcs := _pcs + 'VALUES (' + chr(39) + _aktstring + chr(39) + ',';
              _pcs := _pcs + chr(39) + _fogadonev + chr(39) + ',';
              _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
              _pcs := _pcs + inttostr(_bankjegy) + ',';
              _pcs := _pcs + chr(39) + '?' + chr(39) + ')';
              wParancs(_pcs);
              inc(_y);
              continue;
            end;
        end;
      inc(_y);
    end;
end;

// =============================================================================
                       procedure TForm2.WuniFeliras;
// =============================================================================

begin
  UzenoPanel.Caption := 'A Western Union adatok felirása';
  UzenoPanel.Repaint;

  _pcs := 'DELETE FROM WUNITRANZ';
  wParancs(_pcs);

  Csik.Max := _wudb;
  _Y := 1;
  while _y<=_wudb do
    begin
      csik.Position := _y;
      _aktstring := _wustring[_y];
      _kftipus   := leftstr(_aktstring,1);
      _kuldostr  := midstr(_aktstring,2,3);
      _aktdnem   := midstr(_aktstring,5,3);
      _fogadostr := midstr(_aktstring,8,3);

      val(_kuldostr,_kuldokod,_code);
      val(_fogadostr,_fogadokod,_code);

      if _kftipus='K' then
        begin
          _bankjegy    := _wuniJegy[_y];
          _kuldonev    := _penztarnev[_kuldokod];
          _ellenstring := 'F' + midstr(_aktstring,2,9);

          _pcs := 'SELECT * FROM WUNITRANZ WHERE FOGADAS='+chr(39)+_ellenstring+chr(39);

          wDbase.Connected := True;
          with wQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
              _recno := recno;
            end;

          if _recno>0 then
            begin
              _fogadottpenz := wQuery.fieldByName('FOGADOTTPENZ').asInteger;
              wQuery.close;
              wDbase.close;

              if _fogadottPenz=_bankjegy then _status:='OK' else _status:='?';

              _pcs := 'UPDATE WUNITRANZ SET KULDES='+chr(39)+_aktstring+chr(39);
              _pcs := _pcs + ',KULDO=' + chr(39) + _kuldonev + chr(39);
              _pcs := _pcs + ',KULDOTTPENZ=' + inttostr(_bankjegy);
              _pcs := _pcs + ',STATUS=' + chr(39) + _status + chr(39) + _sorveg;
              _pcs := _pcs + 'WHERE FOGADAS='+chr(39)+_ellenstring+chr(39);
              wParancs(_pcs);
              inc(_y);
              Continue;
            end;

          if _recno=0 then
            begin
              _pcs := 'INSERT INTO WUNITRANZ (KULDES,KULDO,VALUTANEM,KULDOTTPENZ,';
              _pcs := _pcs + 'STATUS)' + _sorveg;
              _pcs := _pcs + 'VALUES (' + chr(39) + _aktstring + chr(39) + ',';
              _pcs := _pcs + chr(39) + _kuldonev + chr(39) + ',';
              _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
              _pcs := _pcs + inttostr(_bankjegy) + ',';
              _pcs := _pcs + chr(39) + '?' + chr(39) + ')';
              wParancs(_pcs);
              inc(_y);
              continue;
            end;
        end;

      // =======================================

      if _kftipus='F' then
        begin
          _bankjegy    := _wuniJegy[_y];
          _fogadonev    := _penztarnev[_fogadokod];
          _ellenstring := 'K' + midstr(_aktstring,2,9);

          _pcs := 'SELECT * FROM WUNITRANZ WHERE KULDES='+chr(39)+_ellenstring+chr(39);

          wDbase.Connected := True;
          with wQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
              _recno := recno;
            end;

          if _recno>0 then
            begin
              _kuldottpenz := wQuery.fieldByName('KULDOTTPENZ').asInteger;
              wQuery.close;
              wDbase.close;

              if _kuldottPenz=_bankjegy then _status:='OK' else _status:='?';

              _pcs := 'UPDATE WUNITRANZ SET FOGADAS='+chr(39)+_aktstring+chr(39);
              _pcs := _pcs + ',FOGADO=' + chr(39) + _fogadonev + chr(39);
              _pcs := _pcs + ',FOGADOTTPENZ=' + inttostr(_bankjegy);
              _pcs := _pcs + ',STATUS=' + chr(39) + _status + chr(39) + _sorveg;
              _pcs := _pcs + 'WHERE KULDES='+chr(39)+_ellenstring+chr(39);
              wParancs(_pcs);
              inc(_y);
              Continue;
            end;

          if _recno=0 then
            begin
              _pcs := 'INSERT INTO WUNITRANZ (FOGADAS,FOGADO,VALUTANEM,FOGADOTTPENZ,';
              _pcs := _pcs + 'STATUS)' + _sorveg;
              _pcs := _pcs + 'VALUES (' + chr(39) + _aktstring + chr(39) + ',';
              _pcs := _pcs + chr(39) + _fogadonev + chr(39) + ',';
              _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
              _pcs := _pcs + inttostr(_bankjegy) + ',';
              _pcs := _pcs + chr(39) + '?' + chr(39) + ')';
              wParancs(_pcs);
              inc(_y);
              continue;
            end;
        end;
      inc(_y);
    end;
end;

// =============================================================================
                procedure TForm2.wParancs(_ukaz: string);
// =============================================================================

begin
  wDbase.connected := True;
  if wTranz.InTransaction then wTranz.Commit;
  wTranz.StartTransaction;
  with wQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_ukaz);
      ExecSql;
    end;
  wTranz.Commit;
  wDbase.close;
end;

// =============================================================================
             procedure TForm2.NOEQUGOMBClick(Sender: TObject);
// =============================================================================

begin
  if _filter='NOTOK' then exit;

  if _tipus='WAFA' then _pcs := 'SELECT * FROM WAFATRANZ WHERE STATUS<>'+chr(39)+'OK'+chr(39)
  else _pcs := 'SELECT * FROM WUNITRANZ WHERE STATUS<>'+chr(39)+'OK'+chr(39);

  with wquery do
   begin
     Close;
     sql.clear;
     sql.add(_pcs);
     Open;
   end;
  _filter :='NOTOK';
end;

// =============================================================================
              procedure TForm2.ALLTRANZGOMBClick(Sender: TObject);
// =============================================================================

begin
  if _filter='ALLTRANZ' then exit;

  if _tipus='WAFA' then _pcs := 'SELECT * FROM WAFATRANZ'
  else _pcs := 'SELECT * FROM WUNITRANZ';

  with wquery do
   begin
     Close;
     sql.clear;
     sql.add(_pcs);
     Open;
   end;
  _filter :='ALLTRANZ';
end;

// =============================================================================
            procedure TForm2.BackToMenuGombClick(Sender: TObject);
// =============================================================================

begin
  wquery.close;
  wquery.close;
  _mResult := 1;
  Kilepo.Enabled := True;
end;

// =============================================================================
             procedure TForm2.WAFAGOMBClick(Sender: TObject);
// =============================================================================

begin
  if _tipus='WAFA' then exit;

  racs.Enabled := False;
  wunisource.Enabled := False;
  wafasource.Enabled := False;

  _pcs := 'SELECT * FROM WAFATRANZ';

  UzenoPanel.Caption := 'ÁFA VISSZATÉRITÉS';
  UzenoPanel.repaint;

  with Wquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  _tipus := 'WAFA';
  racs.DataSource := wafasource;
  wafasource.Enabled := True;
  racs.Enabled := true;
  Activecontrol := Racs;
end;

// =============================================================================
           procedure TForm2.WUNIGOMBClick(Sender: TObject);
// =============================================================================

begin
  if _tipus='WUNI' then exit;

  racs.Enabled       := False;
  wafasource.Enabled := False;
  wunisource.Enabled := False;

  _pcs := 'SELECT * FROM WUNITRANZ';

  UzenoPanel.Caption := 'WESTERN UNION';
  UzenoPanel.repaint;

  with Wquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  _tipus := 'WUNI';

  racs.DataSource := wunisource;
  wunisource.Enabled := True;
  Racs.Enabled := True;
  Activecontrol := Racs;
end;

end.
