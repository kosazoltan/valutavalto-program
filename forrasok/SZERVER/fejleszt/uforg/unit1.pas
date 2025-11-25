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
    PTSEDIT: TEdit;
    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    function getsorszam(_ff: integer): integer;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  // 1110,1111,1112,1201,1202,1203,1204,1205,1206,1207,1208,1209,1210,

  _farkok: array[1..13] of string = ('1110','1111','1112','1201','1202','1203',
                       '1204','1205','1206','1207','1208','1209','1210');

  _vft,_eft: array[1..13,1..26] of integer;
  _qq,_penztar,_nn,_ft,_sorszam,_mm,_vas,_ela,_code: integer;
  _pcs,_aktfarok,_mezo,_bbetu,_vpath,_tablanev,_tipus,_fark,_evhos: string;
  _sorveg: string = chr(13)+chr(10);
  _van: boolean;
  _pts: string;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  _PTS := trim(ptsedit.text);
  val(_pts,_penztar,_code);
  if _code<>0 then
    begin
      application.Terminate;
      exit;
    end;



  _qq := 1;
  while _qq<14 do
    begin
      _aktfarok := _farkok[_qq];
      FAROKPANEL.Caption := _aktfarok;
      farokpanel.Repaint;

      (*
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


          _nn := 1;
          _van := False;
          while _nn<32 do
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
           *)

      _penztar:=54;
      _vPath := 'c:\receptor\database\v' + inttostr(_penztar)+'.gdb';
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
          _pcs := _pcs + 'WHERE STORNO=1';
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
                   _ft := FieldByName('OSSZESEN').asInteger;
                 end;

               if (_tipus='V') then
                 begin
                   _sorszam := Getsorszam(_ft);
                   _vft[_qq,_sorszam] := _vft[_qq,_sorszam] + 1;
                 end;

               if (_tipus='E') then
                 begin
                   _sorszam := Getsorszam(_ft);
                   _eft[_qq,_sorszam] := _eft[_qq,_sorszam] + 1;
                 end;
               vquery.next;
             end;
           vquery.close;
           vDbase.close;
        end;
      inc(_qq);
    end;

  uZeNOPANEL.CAPTION := 'adatbázisba beleirás';
  uzenopanel.repaint;

  Ugydbase.Connected :=true;
  if ugytranz.InTransaction then ugytranz.commit;
  ugytranz.StartTransaction;
  _qq := 1;
  while _qq<14 do
    begin
      _fark := _farkok[_qq];
      _evhos := '20'+leftstr(_fark,2)+'.'+midstr(_fark,3,2);

      _pcs := 'INSERT INTO UGYFELFORGALOM (EVHOS,V1,E1,V2,E2,V3,E3,V4,E4,V5,E5,';
      _pcs := _pcs + 'V6,E6,V7,E7,V8,E8,V9,E9,V10,E10,V11,E11,V12,E12,';
      _pcs := _pcs + 'V13,E13,V14,E14,V15,E15,V16,E16,V17,E17,V18,E18,';
      _pcs := _pcs + 'V19,E19,V20,E20,V21,E21,V22,E22,V23,E23,V24,E24,';
      _pcs := _pcs + 'V25,E25,V26,E26)'+_SORVEG;
      _pcs := _pcs + 'VALUES (' + chr(39) + _evhos + chr(39) + ',';

      _mm := 1;
      while _mm<26 do
        begin
          _vas := _vft[_qq,_mm];
          _ela := _eft[_qq,_mm];
          _pcs := _pcs + inttostr(_vas)+',';
          _pcs := _pcs + inttostr(_ela)+',';
          inc(_mm);
        end;

      _vas := _vft[_qq,26];
      _ela := _eft[_qq,26];
      _pcs := _pcs + inttostr(_vas)+',';
      _pcs := _pcs + inttostr(_ela)+')';

       with ugyquery do
         begin
           Close;
           Sql.Clear;
           Sql.Add(_pcs);
           Execsql;
         end;
      inc(_qq);
    end;
  UgyTranz.commit;
  Ugydbase.close;
  ShowMessage('FELIRTAM !!!');
  Application.terminate;
end;

function TForm1.getsorszam(_ff: integer): integer;

begin
  result := 1;
  if _ff<2001 then exit;

  result := 2;
  if _ff<10001 then exit;

  result := 3;
  if _ff<20001 then exit;

  result := 4;
  if _ff<30001 then exit;

  result := 5;
  if _ff<40001 then exit;

  result := 6;
  if _ff<50001 then exit;

  result := 7;
  if _ff<60001 then exit;

  result := 8;
  if _ff<70001 then exit;

  result := 9;
  if _ff<80001 then exit;

  result := 10;
  if _ff<90001 then exit;

  result := 11;
  if _ff<100001 then exit;

   result := 12;
  if _ff<120001 then exit;

   result := 13;
  if _ff<130001 then exit;

  result := 14;
  if _ff<140001 then exit;

   result := 15;
  if _ff<150001 then exit;

  result := 16;
  if _ff<200001 then exit;

  result := 17;
  if _ff<300001 then exit;

  result := 18;
  if _ff<400001 then exit;

  result := 19;
  if _ff<500001 then exit;

  result := 20;
  if _ff<1000001 then exit;

  result := 21;
  if _ff<1500001 then exit;

  result := 22;
  if _ff<2500001 then exit;

  result := 23;
  if _ff<5000001 then exit;

  result := 24;
  if _ff<10000001 then exit;

  result := 25;
  if _ff<20000001 then exit;

  result := 26;
end;


procedure TForm1.FormActivate(Sender: TObject);

var i,j: byte;

begin
  for i := 1 to 13 do
    begin
      for j :=  1 to 10 do
        begin
          _vft[i,j] := 0;
          _eft[i,j] := 0;
        end;
    end;

  _pcs := 'DELETE FROM UGYFELFORGALOM';
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