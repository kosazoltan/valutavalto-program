unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBTable, IBDatabase, DB, IBCustomDataSet, IBQuery, StdCtrls,
  Strutils, ExtCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    DAYBQUERY: TIBQuery;
    DAYBDBASE: TIBDatabase;
    DAYBTRANZ: TIBTransaction;
    VTABLA: TIBTable;
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    UGYQUERY: TIBQuery;
    UGYDBASE: TIBDatabase;
    UGYTRANZ: TIBTransaction;
    FAROKPANEL: TPanel;
    PATHPANEL: TPanel;
    uzenopanel: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _vft,_eft,_vforg,_eforg: array[1..150] of integer;
  _qq,_penztar,_nn,_ft,_sorszam,_mm,_vas,_ela,_TRANZDIJ,_forgalom: integer;
  _pcs,_aktfarok,_mezo,_bbetu,_vpath,_tablanev,_tipus,_fark,_evhos: string;
  _sorveg: string = chr(13)+chr(10);
  _van: boolean;
  _ptarsor: array[1..150] of byte;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  _aktfarok := '1212';

  daybdbase.Connected := True;
  _pcs := 'SELECT * FROM DAYB' + _aktfarok;
  with daybquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  while not daybquery.eof do
    begin
      _penztar := DaybQuery.fieldByName('PENZTAR').asInteger;
      _nn := 21;
      _van := False;
      while _nn<27 do
        begin
          _mezo := 'N' + inttostr(_nn);
          _bbetu := Daybquery.FieldByName(_mezo).asstring;
          if _bbetu='B' then
            begin
              _van := True;
              Break;
            end;
          inc(_nn);
        end;

      if not _van then
        begin
          daybquery.next;
          continue;
        end;

      _ptarsor[_penztar] := 1;

      _vPath := 'c:\receptor\database\v' + inttostr(_penztar)+'.fdb';
      pathpanel.caption := _vPath;
      pathpanel.repaint;

      vdbase.close;
      vdbase.DatabaseName := _vPath;
      vDbase.Connected := true;

      _tablanev := 'BF' + _aktfarok;
      vTabla.TableName := _tablanev;
      if vtabla.Exists then
        begin
          _pcs := 'SELECT * FROM ' + _tablanev + _sorveg;
          _pcs := _pcs + 'WHERE (STORNO=1) AND (DATUM>'+chr(39)+'2012.12.20'+chr(39)+')';
          _pcs := _pcs + ' AND (DATUM<'+chr(39)+'2012.12.27' + CHR(39)+')';
          with vQuery do
            begin
              Close;
              sql.Clear;
              sql.Add(_PCS);
              Open;
              First;
            end;

          while not vquery.eof do
            begin
              with vquery do
                begin
                  _tipus := FieldByName('TIPUS').asString;
                  _tranzdij := FieldByName('TRANZDIJ').asInteger;
                  _forgalom := FieldByName('OSSZESEN').asInteger;
                end;

              if (_tipus='V') then
                begin
                  _vft[_penztar] := _vft[_penztar] + abs(_tranzdij);
                  _vforg[_penztar] := _vforg[_penztar] + _forgalom;
                end;

              if (_tipus='E') then
                begin
                  _eft[_penztar] := _eft[_penztar] + abs(_tranzdij);
                   _eforg[_penztar] := _eforg[_penztar] + _forgalom;
                end;
              Vquery.next;
            end;
            Vquery.close;
            vDbase.close;
        end;
      Daybquery.Next;
    end;

  DaybQuery.close;
  daybdbase.close;

  uZeNOPANEL.CAPTION := 'adatbázisba beleirás';
  uzenopanel.repaint;

  Ugydbase.Connected :=true;
  if ugytranz.InTransaction then ugytranz.commit;
  ugytranz.StartTransaction;
  _qq := 1;
  while _qq<151 do
    begin
      if _ptarsor[_qq]=0 then
        begin
          inc(_qq);
          continue;
        end;
      _pcs := 'INSERT INTO TRANZDIJ (PENZTAR,VETEL,ELADAS,VFORG,EFORG)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + inttostr(_qq) +',';
      _pcs := _pcs + INTTOSTR(_VFT[_qq]) + ',';
      _pcs := _pcs + inttostr(_eft[_qq])+',';
      _pcs := _pcs + INTTOSTR(_VFORG[_qq]) + ',';
      _pcs := _pcs + inttostr(_efORG[_qq])+')';

      with ugyquery do
        begin
          Close;
          Sql.Clear;
          sql.Add(_pcs);
          execSql;
        end;
      inc(_qq);
    end;

  UgyTranz.commit;
  Ugydbase.close;
  ShowMessage('FELIRTAM !!!');
  Application.terminate;
end;



procedure TForm1.FormActivate(Sender: TObject);

var i: byte;

begin
  for i := 1 to 150 do
    begin
      _vft[i] := 0;
      _eft[i] := 0;
      _vforg[i] := 0;
      _eforg[i] := 0;
      _ptarsor[i] := 0;
    end;

  _pcs := 'DELETE FROM TRANZDIJ';
  UGYDBASE.Connected := tRUE;
  if ugytranz.InTransaction then ugytranz.Commit;
  ugytranz.StartTransaction;
  with ugyquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;
  ugytranz.commit;
  ugydbase.close;

end;

end.
