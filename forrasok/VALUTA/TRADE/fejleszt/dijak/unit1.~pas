unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, Buttons,
  ExtCtrls;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    IBQUERY: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    Label1: TLabel;
    Shape1: TShape;

    procedure BitBtn1Click(Sender: TObject);
    procedure Parancs(_pp: string);
    procedure BitBtn2Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _pcs : string;
  _sorveg: string = chr(13)+chr(10);

implementation

{$R *.dfm}

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  ibdbase.connected := true;
  if ibtranz.InTransaction then ibtranz.Commit;
  ibtranz.StartTransaction;

  _pcs := 'UPDATE CIKKTORZS SET EGYSEGAR=1470'+_sorveg;
  _pcs := _pcs + 'WHERE AZONOSITO=34';
  Parancs(_pcs);

  _pcs := 'UPDATE CIKKTORZS SET EGYSEGAR=2975'+_sorveg;
  _pcs := _pcs + 'WHERE AZONOSITO=24';
   Parancs(_pcs);

  _pcs := 'UPDATE CIKKTORZS SET EGYSEGAR=4780'+_sorveg;
  _pcs := _pcs + 'WHERE AZONOSITO=25';
   Parancs(_pcs);

  _pcs := 'UPDATE CIKKTORZS SET EGYSEGAR=42980'+_sorveg;
  _pcs := _pcs + 'WHERE AZONOSITO=26';
   Parancs(_pcs);

  _pcs := 'UPDATE CIKKTORZS SET EGYSEGAR=13385'+_sorveg;
  _pcs := _pcs + 'WHERE AZONOSITO=57';
   Parancs(_pcs);

  _pcs := 'UPDATE CIKKTORZS SET EGYSEGAR=21975'+_sorveg;
  _pcs := _pcs + 'WHERE AZONOSITO=58';
   Parancs(_pcs);

  _pcs := 'UPDATE CIKKTORZS SET EGYSEGAR=199975'+_sorveg;
  _pcs := _pcs + 'WHERE AZONOSITO=59';
   Parancs(_pcs);

   ibtranz.commit;
   ibdbase.close;
   Application.terminate;
end;


procedure Tform1.Parancs(_pp: string);

begin
  with ibQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pp);
      ExecSql;
    end;
end;

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  Application.Terminate;
end;

end.
