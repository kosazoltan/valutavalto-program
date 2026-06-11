unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  ExtCtrls, strutils;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    BitBtn1: TBitBtn;
    Panel1: TPanel;
    IBQUERY: TIBQuery;
    IBDBASE: TIBDatabase;
    ibtranz: TIBTransaction;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    function Kiolvassa: string;
    procedure Beirja;
    procedure ibparancs(_ukaz: string);



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _jel,_pcs,_text: string;
  _sorveg: string = chr(13)+chr(10);

implementation

uses Unit2;

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  aPPLICATION.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  _JEL := 'A';
  BEIRJA;
  Form2.showmodal;
  _text := Kiolvassa;
  Panel1.caption := leftstr(_text,2)+' '+midstr(_text,3,length(_text)-2);
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  _JEL := 'O';
  BEIRJA;
  Form2.showmodal;
  _text := Kiolvassa;
  Panel1.caption := leftstr(_text,2)+' '+midstr(_text,3,length(_text)-2);
end;

procedure TForm1.Beirja;

begin
  _pcs := 'DELETE FROM VTEMP';
  ibParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (MEGJEGYZES)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _jel + chr(39)+')';
  ibparancs(_pcs);
end;


function TForm1.Kiolvassa: string;
begin
   ibdbase.connected := true;
   with Ibquery do
     begin
       Close;
       sql.clear;
       sql.add('SELECT * FROM VTEMP');
       Open;
       result := trim(FieldByNAme('MEGJEGYZES').asString);
       Close;
     end;
   ibdbase.close;
end;

procedure TForm1.ibparancs(_ukaz: string);

begin
  ibdbase.Connected := true;
  if ibtranz.InTransaction then ibtranz.commit;
  ibtranz.StartTransaction;
  with Ibquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  ibtranz.Commit;
  ibdbase.close;
end;      

end.
