unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  DateUtils,StrUtils,IBTable, ExtCtrls, idglobal;

type
  TForm1 = class(TForm)
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    VTABLA: TIBTable;
    Memo1: TMemo;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    ARTQUERY: TIBQuery;
    ARTDBASE: TIBDatabase;
    ARTTRANZ: TIBTransaction;
    KILEPO: TTimer;
    Label1: TLabel;
    Label2: TLabel;

    procedure Indexeles;
    procedure MakeXml;

    function DDekonv(_dt: TDatetime): string;
    function Nulele(_b: byte): string;
    function Tegctrl(_ctrldat: string): boolean;
    function Gethavisum: integer;

    procedure FormActivate(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _HONAP : array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS',
                 'MÁJUS','JUNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER',
                                           'OKTÓBER','NOVEMBER','DECEMBER');

  _NAPOK : array[1..7] of string = ('HÉTFÕN','KEDDEN','SZERDÁN','CSÜTÖRTÖKÖN',
                            'PÉNTEKEN','SZOMBATON','VASÁRNAP');

  _iras: textfile;                          
  _tegnap: TDateTime;
  _pvtot,_petot,_pvkdij,_pekdij,_pvnetto,_penetto: array[1..169] of integer;
  _pnetto,_pkdij,_ptot,_havisum: array[1..169] of integer;
  _ptnev,_ptcegbetu: array[1..169] of string;
  _bsor,_esor,_psor,_zsor: array[1..140] of byte;

  _pcs,_blokkfej,_farok,_tegnaps,_vfdb,_tipus,_aktcegbetu,_focim: string;
  _sorveg: string = chr(13)+chr(10);
  _pt,_bdb,_edb,_pdb,_zdb: byte;
  _recno,_total,_kdij,_vtot,_etot,_vkdij,_ekdij: integer;

   _xev,_xho,_xnap,_hnap: word;
   _exdir,_exfile,_expath,_xml,_target,_xmlPath: string;

   _copyoke: boolean;

implementation

uses Unit2;

{$R *.dfm}



// =============================================================================
                 procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin

  _tegnap := yesterday;
  _tegnaps := ddekonv(_tegnap);

  if not tegctrl(_tegnaps) then
    begin
      Kilepo.enabled := True;
      exit;
    end;

  repaint;

  _hnap := dayoftheweek(_tegnap);
  _farok := midstr(_tegnaps,3,2)+midstr(_tegnaps,6,2);

  _focim := 'FORGALMI ADATOK '+inttostr(_xev)+' '+_honap[_xho]+' ';
  _focim := _focim + inttostr(_xnap)+' '+_napok[_hnap];

  _exdir := 'c:\receptor\mail\sendmail\data';
  _exfile := 'Nforg_' + _tegnaps + '.xls';
  _expath := _exdir + '\' + _exfile;

  _pt := 4;
  while _pt<=169 do
    begin
      _vfdb := 'c:\receptor\database\v' + INTTOSTR(_PT)+'.fdb';
      if _pt>150 then _vfdb := 'c:\cartcash\database\v'+inttostr(_pt)+'.fdb';

      if not FileExists(_vFdb) then
        begin
          inc(_pt);
          continue;
        end;
      _blokkfej := 'BF' + _farok;


      vdbase.close;
      vdbase.DatabaseName := _vFdb;
      vdbase.Connected := true;

      vtabla.close;
      vtabla.TableName := _BLOKKFEJ;
      if not vtabla.Exists then
        begin
          vdbase.close;
          inc(_pt);
          continue;
        end;

      _havisum[_pt] := GetHavisum;

      _pcs := 'SELECT * FROM ' + _BLOKKFEJ + _sorveg;
      _pcs := _pcs + 'WHERE (DATUM=' + chr(39)+_tegnaps+chr(39)+')';
      _pcs := _pcs + ' AND ((TIPUS='+chr(39)+'V'+chr(39)+') OR (TIPUS=';
      _pcs := _pcs + chr(39)+'E'+chr(39)+')) AND (STORNO=1)';

      with vquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _recno := recno
        end;

      if _recno=0 then
        begin
          Vquery.close;
          vdbase.close;
          inc(_pt);
          Continue;
        end;

      Memo1.lines.ADD(_VfDB);

      _eTot  := 0;
      _vTot  := 0;
      _eKdij := 0;
      _vKdij := 0;

      while not Vquery.Eof do
        begin
          _tipus := Vquery.fieldByNAme('TIPUS').asString;
          _total := Vquery.FieldByName('OSSZESEN').asInteger;
          _kdij  := Vquery.FieldByNAme('KEZELESIDIJ').asInteger;

          if _tipus='V' then
            begin
              _vtot  := _vtot + _total;
              _vkdij := _vKdij + _kdij;
            end;

          if _tipus= 'E' then
            begin
              _eTot  := _eTot + _total;
              _ekDij := _eKdij + _kDij;
            end;
          Vquery.next;
        end;

      Vquery.close;
      Vdbase.close;

      _pvtot[_pt]  := _vtot;
      _peTot[_pt]  := _eTot;
      _pvkdij[_pt] := _vkdij;
      _pekdij[_pt] := _ekDij;

      inc(_pt);
    end;

  Indexeles;
  Excelform.Showmodal;
  MakeXml;

  _target := 'c:\receptor\mail\sendmail\' + _xml;
  _copyoke := Copyfileto(_xmlPath,_target);

  if _copyoke then
    begin
      _pcs := 'UPDATE RENDSZER SET CAMCLEAR='+chr(39)+_tegnaps+chr(39);
      recdbase.Connected := true;
      if rectranz.InTransaction then rectranz.Commit;
      rectranz.StartTransaction;
      with recquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Execsql;
        end;
      rectranz.commit;
      recdbase.close;
    end;

  Kilepo.Enabled := true;
end;


// =============================================================================
               function TForm1.DDekonv(_dt: TDatetime): string;
// =============================================================================

begin
  _xev := yearof(_dt);
  _xho := monthof(_dt);
  _xnap:= dayof(_dt);
  result := inttostr(_xev)+'.'+nulele(_xho)+'.'+nulele(_xNap);
end;

// =============================================================================
                   function TForm1.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
                           procedure TForm1.Indexeles;
// =============================================================================

begin
  _bdb := 0;
  _edb := 0;
  _pdb := 0;
  _zdb := 0;

  Artdbase.Connected := true;
  Recdbase.Connected := True;

  _pt := 1;
  while _pt<=169 do
    begin
      _pvnetto[_pt] := _pvtot[_pt] - _pvkdij[_pt];
      _penetto[_pt] := _petot[_pt] + _pekdij[_pt];
      _pnetto[_pt] := _pvnetto[_pt]+_penetto[_pt];
      _pkdij[_pt] := _pvkdij[_pt] + _pekdij[_pt];
      _ptot[_pt] := _pvtot[_pt] + _petot[_pt];

      _pcs := 'SELECT * FROM IRODAK WHERE UZLET='+inttostr(_pt);

      if _ptot[_pt]>0 then
        begin
          if _pt<151 then
            begin
              with recquery do
                begin
                  close;
                  sql.clear;
                  sql.add(_pcs);
                  Open;
                  _ptnev[_pt] := trim(FieldByNAme('KESZLETNEV').AsString);
                  _aktcegbetu := FieldByNAme('CEGBETU').asString;
                  Close;
                end;
              _ptcegbetu[_pt] := _aktcegbetu;
              if _aktcegbetu='B' then
                begin
                  inc(_bdb);
                  _bsor[_bdb] := _pt;
                end;

              if _aktcegbetu='E' then
                begin
                  inc(_edb);
                  _esor[_edb] := _pt;
                end;

              if _aktcegbetu='P' then
                begin
                  inc(_pdb);
                  _psor[_pdb] := _pt;
                end;
            end else
            begin
              with artquery do
                begin
                  Close;
                  sql.clear;
                  sql.add(_pcs);
                  Open;
                  _ptnev[_pt] := trim(FieldByNAme('KESZLETNEV').AsString);
                  Close;
                end;
              _ptcegbetu[_pt] := 'Z';
              inc(_zdb);
              _zsor[_zdb] := _pt;
            end;
        end;

      inc(_pt);
    end;
  Recdbase.close;
  Artdbase.close;
end;


procedure TForm1.KILEPOTimer(Sender: TObject);
begin
  Kilepo.Enabled := False;
  Application.terminate;
end;

procedure Tform1.Makexml;

var _mail: string;

begin
  _xml := 'E'+midstr(_tegnaps,6,2)+midstr(_tegnaps,9,2)+'.xml';
  _xmlPath := 'c:\receptor\mail\napiforg\' + _xml;

  Assignfile(_iras,_xmlPath);
  rewrite(_iras);

  _mail := '<mail>'+_sorveg;
  _mail := _mail + '  <addresses>' + _sorveg;
  _mail := _mail + '    <address>kosa.zoltan.ebc@gmail.com</address>' + _sorveg;
  _mail := _mail + '    <address>fabulyazsuzsa.eec@gmail.com</address>'+_sorveg;
  _mail := _mail + '    <address>durucz.tamas.eec@gmail.com</address>'+_sorveg;
  _mail := _mail + '    <address>kasza.helga.ebc@gmail.com</address>'+_sorveg;
  _mail := _mail + '  </addresses>'+_sorveg;
  _mail := _mail + '  <subject>'+_Tegnaps+'- forgalom</subject>'+_sorveg;
  _mail := _mail + '  <message>Excel tablat kuldtem a tegnapi forgalomrol</message>'+_sorveg;

  _mail := _mail + '  <attachment>' + _exfile + '</attachment>' + _sorveg;
  _mail := _mail + '</mail>';

  write(_iras,_mail);
  Closefile(_iras);
end;  

function TForm1.tegctrl(_ctrldat: string): boolean;

var _lastnForg: string;

begin
  result := False;
  recdbase.connected := true;
  with Recquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM RENDSZER');
      Open;
      _lastnForg := trim(FieldByNAme('CAMCLEAR').asString);
      CLose;
    end;
  recdbase.close;
  if _lastNforg<_ctrlDat then result := True;
end;

// =============================================================================
                   function TForm1.Gethavisum: integer;
// =============================================================================

begin
  result := 0;

  _pcs := 'SELECT * FROM ' + _BLOKKFEJ + _sorveg;
  _pcs := _pcs + 'WHERE ((TIPUS='+chr(39)+'V'+chr(39)+') OR (TIPUS=';
  _pcs := _pcs + chr(39)+'E'+chr(39)+')) AND (STORNO=1)';

  with vquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      _recno := recno
    end;

  if _recno=0 then
    begin
      Vquery.close;
      exit;
    end;

  while not Vquery.Eof do
    begin
      _tipus := Vquery.fieldByNAme('TIPUS').asString;
      _total := Vquery.FieldByName('OSSZESEN').asInteger;
      _kdij  := Vquery.FieldByNAme('KEZELESIDIJ').asInteger;

      if _tipus='V' then _total := _total-_kdij
      else _total := _total + _kdij;

      result := result + _total;
      Vquery.next;
    end;
  Vquery.close;
end;

end.
