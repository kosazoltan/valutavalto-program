unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StrUtils, IBQuery, IBDatabase, DB, IBCustomDataSet,
  IBTable, StdCtrls, DateUtils, Buttons, ComCtrls, idGlobal,MAPI;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;




    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);




  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _munkanap: string;
  _ok: integer;


implementation

uses Unit3;



{$R *.dfm}



procedure TForm1.Button2Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
    _munkanap := '2011.11.30';
   _ok := TabMaker.showmodal;

end;

end.
