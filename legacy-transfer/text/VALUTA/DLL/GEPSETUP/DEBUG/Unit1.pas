unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, IBDatabase, IBTable, IBCustomDataSet, IBQuery;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    IBTransaction1: TIBTransaction;
    IBQuery1: TIBQuery;
    IBTable1: TIBTable;
    IBDatabase1: TIBDatabase;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses Unit2;

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  Application.terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  sETUPFORM.showmodal;
end;

end.
