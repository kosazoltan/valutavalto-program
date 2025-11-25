unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBTable, IBCustomDataSet, IBQuery,
  ExtCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    VQUERY: TIBQuery;
    VTABLA: TIBTable;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    VEVOQUERY: TIBQuery;
    VEVODBASE: TIBDatabase;
    vevotranz: TIBTransaction;
    Panel1: TPanel;
    TETELQUERY: TIBQuery;
    TETELTRANZ: TIBTransaction;
    TETELDBASE: TIBDatabase;
    Panel2: TPanel;

    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Vparancs(_ukaz: string);

    function Nulele(_b: byte): string;
    function ezertektar(_ptr: byte): boolean;
    function ezkellpenztar(_apt: byte): boolean;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _ev,_ho: word;
  _PT: byte;
  _fdbPath,_bf,_pcs: string;
  _sorveg: string = chr(13)+chr(10);

  _OKpT : array[1..51] of byte = (4,9,11,13,14,16,18,21,22,23,27,29,30,33,39,
                                  41,42,44,45,46,49,52,53,
                                  56,57,58,60,61,62,64,66,67,77,78,79,81,
                                  83,84,87,89,92,95,125,126,
                                  128,135,136,139,143,148,149);


implementation

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  aPPLICATION.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);


begin
  _PT := 3;
  WHILE _pt<=150 do
   begin

     if not EzkellPenztar(_pt) then
       begin
         inc(_pt);
         continue;
       end;

     _fdbpath := 'c:\receptor\database\v' + INTTOSTR(_pt)+'.fdb';
     if not fileexists(_fdbPath) then
       begin
         inc(_pt);
         continue;
       end;

     vdbase.close;
     Teteldbase.close;
     vdbase.databasename := _fdbPath;
     teteldbase.databasename := _fdbPath;
     
     pANEL1.Caption := _fdbPath;
     panel1.Repaint;

     _bf := 'BF1606';
     vtabla.close;
     vdbase.Connected := true;
     vtabla.TableName := _bf;
     if vtabla.Exists then
       begin
         vdbase.close;
         _pcs := 'ALTER TABLE ' + _bf + ' ADD FIZETOESZKOZ SMALLINT';
         Vparancs(_pcs);

         _pcs := 'UPDATE ' + _bf + ' SET FIZETOESZKOZ=1';
         Vparancs(_pcs);
       end;
     inc(_pt);
   end;
  ShowMessage('VÉGE VAN');
END;


PROCEDURE tfORM1.Vparancs(_ukaz: string);

begin
  Vdbase.connected := True;
  if Vtranz.InTransaction then vtranz.Commit;
  Vtranz.StartTransaction;
  with vquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  Vtranz.Commit;
  Vdbase.close;
end;


function TForm1.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;



function TForm1.ezertektar(_ptr: byte): boolean;

begin
  result := False;

  if (_ptr=10) or (_ptr=20) or (_ptr=40) or (_ptr=50) or (_ptr=63) then
     begin
       result := true;
       exit;
     end;

  if (_ptr=75) or (_ptr=120) or (_ptr=145) then result := true;
end;


function TForm1.ezkellpenztar(_apt: byte): boolean;

var _z: byte;

begin
  result := False;
  _z := 1;
  while _z<=51 do
    begin
      if _okPt[_z] = _apt then
        begin
          result := True;
          exit;
        end;
      inc(_z);
    end;
end;

end.
