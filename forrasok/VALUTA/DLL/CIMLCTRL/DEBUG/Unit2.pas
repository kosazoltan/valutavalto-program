unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,IBDatabase, DB, IBCustomDataSet,
  IBQuery, IBTable;

type
  TCIMLETCONTROL = class(TForm)
    Label1: TLabel;
    INDITO: TTimer;
    vALUTAquery: TIBQuery;
    VALUTAdbase: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    XQUERY: TIBQuery;
    XDBASE: TIBDatabase;
    XTRANZ: TIBTransaction;
    CQUERY: TIBQuery;
    CDBASE: TIBDatabase;
    CTRANZ: TIBTransaction;
    Ctabla: TIBTable;

    procedure FormActivate(Sender: TObject);
    procedure InditoTimer(Sender: TObject);

    procedure GetPenztarZarasAdatai;
    procedure Getkezelesidij;
    procedure GetWestern;
    procedure GetafaKeszlet;
    procedure GetfoglaloKeszlet;
    procedure GetEtradeKeszlet;

    procedure Cparancs(_ukaz: string);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CIMLETCONTROL: TCIMLETCONTROL;

  _eTradePath : string = 'c:\valuta\database\trade.fdb';

  _cimletType: byte;
  _top,_left,_height,_width : word;

  _gepfunkcio,_readybyte,_valdb,_y: byte;
  _megnyitottnap: string;
  _nincskeszlet : boolean;
  _cimoke,_aktkeszlet,_aktcimlet,_zaro,_recno,_wuusd,_wuhuf,_afahuf: integer;


  _cimletPath,_aktdnem,_pcs,_dnvari,_kevari: string;
  _sorveg: string = chr(13)+chr(10);
  _yDnem: array[0..4] of string;
  _yKesz: array[0..4] of integer;



function cimletctrlrutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
         function cimletctrlrutin: integer; stdcall;
// =============================================================================

begin
  Cimletcontrol  := TCimletcontrol.create(Nil);
  result := Cimletcontrol.ShowModal;
  CimleTControl.Free;
end;

// =============================================================================
         procedure TCIMLETCONTROL.FormActivate(Sender: TObject);
// =============================================================================

begin

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;
  _top := trunc((_height-110)/2);
  _left := trunc((_width-300)/2);

   Top  := _top;
   Left := _left;
   Valutadbase.Connected := true;
   with Valutaquery do
     begin
       Close;
       Sql.clear;
       Sql.add('SELECT * FROM HARDWARE');
       Open;
       _gepfunkcio    := FieldByName('GEPFUNKCIO').asInteger;
       _megnyitottnap := trim(FieldByNAme('MEGNYITOTTNAP').AsString);
       _cimletType    := FieldByNAme('MENETSZAM').asInteger;
       Close;
     end;
   ValutaDbase.close;
   Indito.Enabled := true;
end;

// =============================================================================
            procedure TCIMLETCONTROL.INDITOTimer(Sender: TObject);
// =============================================================================


begin
  Indito.Enabled := false;

  _nincskeszlet := True;

  _pcs := 'UPDATE CIMINI SET AKTKESZLET=0 WHERE CIMLETTYPE='+inttostr(_cimlettype);
  CParancs(_pcs);

  Case _cimletType of
    1: GetPenztarZarasAdatai;
    2: Getkezelesidij;
    3: Getwestern;
    4: Getafakeszlet;
    5: GetfoglaloKeszlet;
    6: GetEtradeKeszlet;
  end;

  if _nincskeszlet then
     begin
       ModalResult := 3;
       exit;
     end;

  Cdbase.Connected := true;
  if ctranz.InTransaction then ctranz.commit;
  Ctranz.StartTransaction;

  CTabla.Filtered := False;
  Ctabla.Open;
  Ctabla.Filter := 'CIMLETTYPE=' + inttostr(_cimlettype);
  Ctabla.Filtered := true;
  Ctabla.First;

  _cimOke := 1;
  while not Ctabla.Eof do
    begin
      _aktkeszlet := Ctabla.Fieldbyname('AKTKESZLET').asInteger;
      _aktcimlet  := Ctabla.FieldByNAme('CIMLETEZETT').asInteger;
      _readybyte  := 1;
      if (_aktkeszlet<>_aktcimlet) then
        begin
          _readybyte := 0;
          _cimoke    := 2;
        end;
      Ctabla.edit;
      Ctabla.FieldByName('READY').AsInteger := _readybyte;
      Ctabla.post;
      Ctabla.Next;
    end;
  Ctranz.commit;
  Cdbase.close;
  Ctabla.close;
  Modalresult := _cimoke;
end;


// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
//                       KÉSZLETEK BEOLVASASA
// =============================================================================
//§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
// =============================================================================
                procedure TcimletControl.GetPenztarZarasAdatai;
// =============================================================================

begin
  _pcs := 'SELECT * FROM ARFOLYAM' + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  ValutaDbase.connected := true;
  with Valutaquery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  while not Valutaquery.eof do
    begin
      _aktdnem    := Valutaquery.fieldbyName('VALUTANEM').asstring;
      _zaro       := Valutaquery.FieldByName('ZARO').asInteger;
      if _aktdnem='HRK' then _zaro := 0;
      if _zaro>0 then
         begin
           _nincskeszlet := False;
           _pcs := 'UPDATE CIMINI SET AKTKESZLET=' + inttostr(_zaro)+_sorveg;
           _pcs := _pcs + 'WHERE (CIMLETTYPE=1) AND (VALUTANEM=';
           _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ')';
           CParancs(_pcs);
         end;
      Valutaquery.next;
    end;
  Valutaquery.close;
  Valutadbase.close;
end;

// =============================================================================
                  procedure Tcimletcontrol.Getkezelesidij;
// =============================================================================


begin
  _aktkeszlet := 0;
  Valutadbase.Connected := true;

  _pcs := 'SELECT * FROM KEZELESIDATA';
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno>0 then _aktkeszlet := Valutaquery.fieldByname('AKTKEZELESIDIJ').asInteger;

  ValutaQuery.close;
  Valutadbase.close;

  if _aktkeszlet>0 then
    begin
      _nincskeszlet := False;
      _pcs := 'UPDATE CIMINI SET AKTKESZLET=' + inttostr(_aktkeszlet)+_sorveg;
      _pcs := _pcs + 'WHERE CIMLETTYPE=2';
      CParancs(_pcs);
    end;
end;



// =============================================================================
                        procedure TcimletControl.GetWestern;
// =============================================================================


begin
  _pcs := 'SELECT * FROM WUAFAADATOK';

  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      _wuusd := FieldByname('WUDOLLARKESZLET').asInteger;
      _wuHuf := FieldbyName('WUFORINTKESZLET').asInteger;
      close;
    end;
  Valutadbase.close;

  if (_wuhuf>0) then
    begin
      _nincskeszlet := False;
      _pcs := 'UPDATE CIMINI SET AKTKESZLET=' + inttostr(_wuHuf)+_sorveg;
      _pcs := _pcs + 'WHERE (CIMLETTYPE=3) AND (VALUTANEM=';
      _pcs := _pcs + chr(39) + 'HUF' + chr(39) + ')';
      CParancs(_pcs);
    end;

  if (_wuusd>0) then
    begin
      _nincskeszlet := False;
      _pcs := 'UPDATE CIMINI SET AKTKESZLET=' + inttostr(_wuUsd)+_sorveg;
      _pcs := _pcs + 'WHERE (CIMLETTYPE=3) AND (VALUTANEM=';
      _pcs := _pcs + chr(39) + 'USD' + chr(39) + ')';
      CParancs(_pcs);
    end;
end;


// =============================================================================
                 procedure TcimletControl.GetAfaKeszlet;
// =============================================================================

begin
  _pcs := 'SELECT * FROM WUAFAADATOK';

  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      _afaHuf:= FieldByName('OSSZESAFAKESZLET').asInteger;
      close;
    end;

  Valutadbase.close;

  IF _afaHuf>0 then
     begin
      _nincskeszlet := False;
      _pcs := 'UPDATE CIMINI SET AKTKESZLET=' + inttostr(_afaHuf)+_sorveg;
      _pcs := _pcs + 'WHERE (CIMLETTYPE=4)';
      CParancs(_pcs);
    end;
end;

// =============================================================================
                     procedure Tcimletcontrol.GetfoglaloKeszlet;
// =============================================================================

begin
  Valutadbase.Connected := true;
  with Valutaquery do
    begin
      Close;
      sql.Clear;
      sql.Add('SELECT * FROM FOGLALOKESZLET');
      Open;
      _valdb := FieldByName('VALDARAB').asInteger;
    end;

  if _valdb = 0 then
    begin
      ValutaQuery.close;
      Valutadbase.close;
      exit;
    end;

  _y := 0;
  while _y<_valdb do
    begin
      _dnvari := 'V'+inttostr(_y);
      _kevari := 'K' + inttostr(_y);
      _ydnem[_y] := Valutaquery.fieldbyname(_dnvari).asString;
      _yKesz[_y] := ValutaQuery.FieldByName(_kevari).asInteger;
      inc(_y);
    end;
  ValutaQuery.close;
  Valutadbase.close;

  _y := 0;
  while _y<_valdb do
    begin
      _aktdnem := _ydnem[_y];
      _aktkeszlet := _yKesz[_y];

      if _aktkeszlet>0 then
        begin
          _nincskeszlet := False;
          _pcs := 'SELECT * FROM CIMINI WHERE (VALUTANEM='+chr(39)+_aktdnem+chr(39);
          _pcs := _pcs + ') AND (CIMLETTYPE=5)';
          Valutadbase.Connected := true;
          with ValutaQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
              _recno := recno;
              close;
            end;
          valutadbase.close;

          if _recno>0 then
            begin
              _pcs := 'UPDATE CIMINI SET AKTKESZLET='+inttostr(_aktkeszlet)+_sorveg;
              _pcs := _pcs + 'WHERE (VALUTANEM='+chr(39)+_aktdnem+chr(39);
              _pcs := _pcs + ') AND (CIMLETTYPE=5)';
             end else
             begin
               _pcs := 'INSERT INTO CIMINI (VALUTANEM,AKTKESZLET,CIMLETTYPE)'+_sorveg;
               _pcs := _pcs + 'VALUES (' + CHR(39) + _AKTDNEM + chr(39) + ',';
               _pcs := _pcs + inttostr(_aktkeszlet)+',5)';
             end;
          CParancs(_pcs);
        end;
      inc(_y);
    end;
end;


// =============================================================================
                procedure TCimletControl.GetEtradekeszlet;
// =============================================================================


begin
  if not Fileexists(_etradePath) then exit;

  Xdbase.close;
  Xdbase.DatabaseName := _etradePath;
  Xdbase.connected := true;
  with Xquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM PARAMETERS');
      Open;
      _aktkeszlet := FieldByName('PILLALLAS').asInteger;
      Close;
    end;
  Xdbase.close;

  if _aktkeszlet>0 then
    begin
      _nincskeszlet := False;
      _pcs := 'UPDATE CIMINI SET AKTKESZLET=' + inttostr(_aktkeszlet)+_sorveg;
      _pcs := _pcs + 'WHERE (CIMLETTYPE=6)';
      CParancs(_pcs);
    end;

end;


// =============================================================================
               procedure TCimletcontrol.Cparancs(_ukaz: string);
// =============================================================================

begin
  Cdbase.connected := true;
  if ctranz.InTransaction then ctranz.commit;
  ctranz.StartTransaction;
  with cquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  Ctranz.Commit;
  Cdbase.close;
end;
end.
