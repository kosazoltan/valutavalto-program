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

    procedure GetPenztarKeszlet;
    procedure GetkezdijKeszlet;
    procedure GetWuKeszlet;
    procedure GetAfakeszlet;
    procedure GetEkerKeszlet;

    procedure Cparancs(_ukaz: string);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CIMLETCONTROL: TCIMLETCONTROL;

  _cimletType: byte;
  _top,_left,_height,_width : word;

  _usdkeszlet,_hufkeszlet,_afakeszlet,_ekerkeszlet: integer;

  _readybyte: byte;
  _megnyitottnap: string;
  _nincskeszlet : boolean;
  _cimoke,_aktkeszlet,_aktcimlet,_zaro,_recno: integer;

  _cimletPath,_aktdnem,_pcs: string;
  _sorveg: string = chr(13)+chr(10);


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
    1: GetPenztarKeszlet;
    2: GetkezdijKeszlet;
    3: Getwukeszlet;
    4: GetAfaKeszlet;
    5: GetEkerKeszlet;
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
                procedure TcimletControl.GetPenztarKeszlet;
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
                  procedure Tcimletcontrol.GetkezdijKeszlet;
// =============================================================================


begin
  _aktkeszlet := 0;
  Valutadbase.Connected := true;

  _pcs := 'SELECT * FROM KEZDIJDATA';
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno>0 then _aktkeszlet := Valutaquery.fieldByname('ZARO').asInteger;

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
             procedure TcimletControl.GetWUKeszlet;
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
      _usdkeszlet := FieldByname('USDKESZLET').asInteger;
      _hufkeszlet := FieldbyName('HUFKESZLET').asInteger;
      close;
    end;
  Valutadbase.close;

  if (_hufkeszlet>0) then
    begin
      _nincskeszlet := False;
      _pcs := 'UPDATE CIMINI SET AKTKESZLET=' + inttostr(_Hufkeszlet)+_sorveg;
      _pcs := _pcs + 'WHERE (CIMLETTYPE=3) AND (VALUTANEM=';
      _pcs := _pcs + chr(39) + 'HUF' + chr(39) + ')';
      CParancs(_pcs);
    end;

  if (_usdkeszlet>0) then
    begin
      _nincskeszlet := False;
      _pcs := 'UPDATE CIMINI SET AKTKESZLET=' + inttostr(_Usdkeszlet)+_sorveg;
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
      _afaKeszlet:= FieldByName('AFAKESZLET').asInteger;
      close;
    end;

  Valutadbase.close;

  IF _afakeszlet>0 then
     begin
      _nincskeszlet := False;
      _pcs := 'UPDATE CIMINI SET AKTKESZLET=' + inttostr(_afakeszlet)+_sorveg;
      _pcs := _pcs + 'WHERE (CIMLETTYPE=4)';
      CParancs(_pcs);
    end;
end;


// =============================================================================
                procedure TCimletControl.GetEkerkeszlet;
// =============================================================================


begin
  Valutadbase.Connected := True;
  with Valutaquery do
    begin
      Close;
      sql.clear;
      Sql.add('SELECT * FROM EKERDATA');
      Open;
      _ekerkeszlet := FieldByName('ZARO').asInteger;
      Close;
    end;
  Valutadbase.close;

  if _ekerkeszlet>0 then
    begin
      _nincskeszlet := False;
      _pcs := 'UPDATE CIMINI SET AKTKESZLET=' + inttostr(_ekerkeszlet)+_sorveg;
      _pcs := _pcs + 'WHERE (CIMLETTYPE=5)';
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