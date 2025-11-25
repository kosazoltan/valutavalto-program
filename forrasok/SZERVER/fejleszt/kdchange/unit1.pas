unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  Grids, DBGrids, ExtCtrls, IBTable;

type
  TForm1 = class(TForm)
    TRDBASE: TIBDatabase;
    TRTRANZ: TIBTransaction;
    Panel1: TPanel;
    Label1: TLabel;
    KILEPO: TTimer;
    TRQUERY: TIBQuery;


    procedure FormActivate(Sender: TObject);
  
    procedure KParancs(_ukaz: string);
    procedure KILEPOTimer(Sender: TObject);


    
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _tranz,_kezdij: array[1..10] of integer;
  _akttranz,_aktkdij: integer;
  _pcs: string;
  _sorveg: string = chr(13)+chr(10);
  _ss: byte;

implementation

{$R *.dfm}



procedure TForm1.FormActivate(Sender: TObject);
begin
  _tranz[1] := 3000;
  _kezdij[1]:= 190;

  _tranz[2] := 10000;
  _kezdij[2]:= 490;

  _tranz[3] := 60000;
  _kezdij[3]:= 890;

  _tranz[4] := 100000;
  _kezdij[4]:= 990;

  _tranz[5] := 150000;
  _kezdij[5]:= 1490;

  _tranz[6] := 300000;
  _kezdij[6]:= 2490;

  _tranz[7] := 500000;
  _kezdij[7]:= 3490;

  _tranz[8] := 1000000;
  _kezdij[8]:= 4990;

  _tranz[9] := 1500000;
  _kezdij[9]:= 5990;

  _tranz[10] := 2000000;
  _kezdij[10]:= 7990;

  _ss :=1;
  while _ss<=10 do
    begin
      _akttranz := _tranz[_ss];
      _aktkdij  := _kezdij[_ss];
      _pcs := 'UPDATE TRANZDIJTABLA SET TRANZAKCIO='+inttostr(_akttranz);
      _pcs := _pcs + ',KEZELESIDIJ='+inttostr(_aktkdij)+_sorveg;
      _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_ss);
      KParancs(_pcs);
      inc(_ss);
    end;
  _pcs := 'UPDATE TRANZDIJTABLA SET KEZELESIDIJ='+inttostr(9990)+_SORVEG;
  _pcs := _pcs + 'WHERE SORSZAM=23';
  Kparancs(_pcs);

  _pcs := 'UPDATE HARDWARE SET KEZDIJMAX=9990';
  Kparancs(_pcs);
  Kilepo.Enabled := True;
end;  



procedure TForm1.KParancs(_ukaz: string);

begin
  trdbase.Connected := true;
  if trtranz.InTransaction then trtranz.Commit;
  trtranz.StartTransaction;
  with TrQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_ukaz);
      Execsql;
    end;
  TrTranz.commit;
  trdbase.close;
end;




procedure TForm1.KILEPOTimer(Sender: TObject);
begin
  aPPLICATION.Terminate;
end;

end.
