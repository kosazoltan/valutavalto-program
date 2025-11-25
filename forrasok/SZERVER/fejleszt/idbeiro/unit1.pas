unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBQuery, IBCustomDataSet, IBTable, StdCtrls,
  Buttons, ExtCtrls;

type
  TForm1 = class(TForm)
    PROSTABLA: TIBTable;
    PROSQUERY: TIBQuery;
    PROSDBASE: TIBDatabase;
    prostranz: TIBTransaction;
    IBTABLA: TIBTable;
    IBQUERY: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    IDPANEL: TPanel;
    NEVPANEL: TPanel;
    PENZTARPANEL: TPanel;

    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure PenztarBeolvasas;
    function Hasonlitas: boolean;
    procedure IbParancs(_ukaz: string);

    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _prosnev,_idkod,_mixed: array[0..1500] of string;
  _cc,_prosdarab,_pp,_living,_lastrec: integer;
  _pcs,_fdbpath,_keresettnev,_jopenztarosnev,_joidkod,_akttablanev: string;
  _keresettidkod: string;
  _top,_left: word;

  _reboot: boolean;

  _sorveg: string = chr(13)+chr(10);
  _farok : string = '2302';



implementation

uses Unit2;

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  _lastrec := 0;
  _pp := 1;
  while _pp<151 do
    begin
      _fdbpath := 'c:\receptor\database\v'+inttostr(_pp)+'.fdb';

      PenztarPanel.Caption := inttostr(_pp);
      PenztarPanel.Repaint;

      if not FileExists(_fdbpath) then
        begin
          inc(_pp);
          Continue;
        end;

      // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

      _aktTablaNev := 'BF' + _farok;
      ibtabla.TableName := _akttablanev;
      ibdbase.close;
      ibdbase.DatabaseName := _fdbpath;
      ibdbase.Connected := true;
      if not ibtabla.exists then
        begin
          ibdbase.close;
          inc(_pp);
          Continue;
        end;
      _pcs := 'SELECT * FROM '+ _akttablanev + _sorveg;
      _pcs := _pcs + 'WHERE ((TIPUS=' + chr(39) + 'V' + chr(39);
      _pcs := _pcs + ') OR (TIPUS=' + chr(39) + 'E' + chr(39);
      _pcs := _pcs + ') OR (TIPUS=' + chr(39) + 'K' + chr(39);
      _pcs := _pcs + ')) AND (STORNO=1)';

      with ibquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          first;
        end;

      while not ibQuery.Eof do
        begin
          _keresettnev := trim(Ibquery.fieldbyname('PENZTAROSNEV').asString);
          _keresettidkod  := Ibquery.FieldByName('IDKOD').asString;
          Nevpanel.Caption := _keresettnev;
          idpanel.Caption := _keresettidkod;
          Nevpanel.Repaint;
          idpanel.Repaint;

          _reboot := Hasonlitas;
          if _reboot then Break;
          ibquery.next;
        end;
      ibquery.Close;
      ibdbase.close;
      if not _reboot then inc(_pp);

      // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      _aktTablaNev := 'WUNI' + _farok;
      ibtabla.TableName := _akttablanev;
      ibdbase.close;
      ibdbase.DatabaseName := _fdbPath;
      ibdbase.Connected := true;
      if not ibtabla.exists then
        begin
          ibdbase.close;
          inc(_pp);
          Continue;
        end;

      _pcs := 'SELECT * FROM '+ _akttablanev + _sorveg;
      _pcs := _pcs + 'WHERE (UGYFELTIPUS=' + chr(39) + 'U' + chr(39);
      _pcs := _pcs + ') AND (STORNO=1)';

      with ibquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          first;
        end;

      while not ibQuery.Eof do
        begin
          _keresettnev := trim(Ibquery.fieldbyname('PENZTAROSNEV').asString);
          _keresettidkod  := Ibquery.FieldByName('IDKOD').asString;

           Nevpanel.Caption := _keresettnev;
          idpanel.Caption := _keresettidkod;
          Nevpanel.Repaint;
          idpanel.Repaint;


          _reboot := Hasonlitas;
          if _reboot then Break;
          ibquery.next;
        end;
      ibquery.Close;
      ibdbase.close;
      if not _reboot then inc(_pp);
    end;

  ShowMessage('A HÓNAP RENDBEN');
  Application.Terminate;
end;


function TForm1.Hasonlitas: boolean;

begin
  result := False;
  if _keresettidkod='00000' then exit;
  if _keresettnev='' then exit;
  _cc := 0;

  while _cc<_prosdarab do
    begin
      if (_keresettnev=_prosnev[_cc]) then
        begin
          if (_idkod[_cc]=_keresettidkod) then exit;

          _pcs := 'UPDATE ' + _AKTTABLANEV + ' SET IDKOD=' + chr(39)+_idkod[_cc]+chr(39)+_sorveg;
          _pcs := _pcs + 'WHERE PENZTAROSNEV='+chr(39)+_keresettnev+chr(39);
          ibparancs(_pcs);
          result := True;  // reboot ciklus
          exit;
        end;
      inc(_cc);
    end;
  _living := SelectPenztaros.Showmodal;
  if _living=2 then
    begin
      _pcs := 'UPDATE ' + _akttablanev + ' SET IDKOD='+chr(39)+'00000'+chr(39)+_sorveg;
      _pcs := _pcs + 'WHERE PENZTAROSNEV='+chr(39)+_keresettnev+chr(39);
      ibParancs(_pcs);
    end else
    begin
      _pcs := 'UPDATE ' + _akttablanev + ' SET IDKOD='+chr(39)+_joidkod+chr(39)+_sorveg;
      _pcs := _pcs + 'WHERE PENZTAROSNEV=' + chr(39)+_keresettnev+chr(39);
      ibParancs(_pcs);
      if (_keresettnev<>_jopenztarosnev) then
        begin
          _pcs := 'UPDATE ' + _akttablanev + ' SET PENZTAROSNEV='+chr(39)+_joPenztarosnev+chr(39)+_sorveg;
          _pcs := _pcs + 'WHERE IDKOD=' + chr(39) + _joidkod + chr(39);
          ibParancs(_pcs);
        end;
    end;
  result := true;
end;











procedure TForm1.PenztarBeolvasas;

begin
  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAROSNEV';

  prosdbase.connected := True;
  with Prosquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _cc := 0;
  while not Prosquery.eof do
    begin
      _prosnev[_cc] := trim(ProsQuery.FieldbyName('PENZTAROSNEV').asString);
      _idkod[_cc] := ProsQuery.FieldByName('IDKOD').asString;

      _mixed[_cc] := _idkod[_cc] + ' : ' + _PROSNEV[_CC];

      inc(_cc);
      Prosquery.next;
    end;
  ProsQuery.close;
  Prosdbase.close;
  _prosdarab := _cc;

end;


procedure TForm1.IbParancs(_ukaz: string);

begin
  ibdbase.close;
  ibdbase.connected := true;
  if ibtranz.InTransaction then ibtranz.Commit;
  ibtranz.StartTransaction;
  with ibquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  ibtranz.commit;
  ibdbase.close;
end;      


procedure TForm1.FormCreate(Sender: TObject);
begin
  _top := 150;
  _left := 350;
  PenztarBeolvasas;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  Top := _top;
  Left := _left;
end;

end.
