unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB, IBCustomDataSet,
  IBQuery;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Panel1: TPanel;
    Label1: TLabel;
    TEMPQUERY: TIBQuery;
    TEMPDBASE: TIBDatabase;
    TEMPTRANZ: TIBTransaction;
    KERNEVEDIT: TEdit;
    BACKPANEL: TPanel;

    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
   
    procedure TParancs(_ukaz: string);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _gyanusnev,_pcs,_aktugyfelnev: string;
  _gyanus: INTEGER;
  _sorveg: string = chr(13)+chr(10);

implementation

uses Unit2;

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  aPPLICATION.TERMINATE;

end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
   {
   _gyanusnev := TRIM(KERNEVEDIT.Text);
   TPARANCS('DELETE FROM VTEMP');
   _pcs := 'INSERT INTO VTEMP (UGYFELNEV)'+_SORVEG;
   _pcs := _pcs + 'VALUES (' + chr(39)+_gyanusnev+chr(39)+')';
   Tparancs(_pcs);
   }
   tempdbase.connected := true;
   with Tempquery do
     begin
       Close;
       sql.clear;
       sql.add('SELECT * FROM VTEMP');
       Open;
       _aktugyfelnev := trim(FieldByNAme('UGYFELNEV').asString);
       Close;
     end;
   Tempdbase.close;
   kERNEVEDIT.Text := _AKTUGYFELNEV;
   KernevEdit.repaint;

    _GYANUS := Terror.showmodal;

    bACKpANEL.Caption := inttostr(_gyanus);
    BackPanel.repaint;

    if _gyanus<0 then Panel1.caption := 'EZ AZ EMBER GYANUS'
    else Panel1.caption := 'EZ AZ EMBER NEM GYANUS';
end;

procedure TForm1.TParancs(_ukaz: string);

begin
  tempdbase.connected := true;
  if temptranz.InTransaction then TempTranz.Commit;
  TempTranz.StartTransaction;
  with Tempquery do
    begin
      CLose;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Temptranz.commit;
  tempdbase.Close;
end;
end.
