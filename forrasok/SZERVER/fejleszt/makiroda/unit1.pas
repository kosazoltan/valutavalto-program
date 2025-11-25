unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBCustomDataSet, IBQuery, StdCtrls, Buttons,
  ExtCtrls, ComCtrls;

type
  TForm1 = class(TForm)
    IBQUERY: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    Label1: TLabel;
    Label2: TLabel;
    STARTTIMER: TTimer;
    CSIK: TProgressBar;
    ACQUERY: TIBQuery;
    ACDBASE: TIBDatabase;
    ACTRANZ: TIBTransaction;


    procedure OneWordWrite(_szo: string);
    procedure STARTTIMERTimer(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure AcIrodakFelirasa;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _irodaDarab,_ertekTar,_uzlet,_cc,_acirodadarab: integer;
  _adatPath,_varos,_boltnev: string;
  _iras: File of Byte;
  _byteTomb: array[1..128] of byte;
  _kod: byte;
  _sorveg: string = chr(13)+chr(10);

implementation

{$R *.dfm}


// =============================================================================
             procedure TForm1.STARTTIMERTimer(Sender: TObject);
// =============================================================================

begin
  StartTimer.Enabled := false;
  _irodaDarab := 0;
  IbDbase.Connected := true;
  if ibTranz.InTransaction then ibTranz.Commit;

  with IBquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add('SELECT * FROM IRODAK ORDER BY UZLET');
      Open;
      Last;
    end;
  _irodaDarab := ibquery.Recno;
  Csik.Max := _irodaDarab;
  _adatPath := 'c:\receptor\mail\IRODAK\irodak.dat';

  AssignFile(_iras,_adatpath);
  Rewrite(_iras);

  _byteTomb[1] := _IrodaDarab;
  BlockWrite(_iras,_byteTomb,1);

  ibQuery.First;
  _cc := 0;
  while not ibQuery.Eof do
    begin
       Csik.Position := _cc;
       inc(_cc);
       with ibQuery do
         begin
           _uzlet := FieldByName('UZLET').asInteger;
           _ertekTar := FieldByName('ERTEKTAR').asInteger;
           _varos := FieldByName('VAROS').asString;
           _boltNev := FieldByName('BOLTNEV').asString;
         end;

       _byteTomb[1] := _uzlet;
       _byteTomb[2] := _ertektar;
       BlockWrite(_iras,_byteTomb,2);
       OneWordWrite(_varos);
       OnewordWrite(_boltnev);

      IbQuery.Next;
    end;
  CloseFile(_iras);
  IbQuery.Close;
  ibDbase.Close;

  AcIrodakFelirasa;

  Application.Terminate;
end;

// =============================================================================//
                 procedure TForm1.AcIrodakFelirasa;
// =============================================================================

var _pcs: string;

begin
 _pcs := 'SELECT * FROM IRODAK'+_sorveg;
 _PCS := _PCS + 'WHERE CLOSED='+chr(39)+'N'+chr(39)+_sorveg;
 _pcs := _pcs + 'ORDER BY UZLET'+ _sorveg;

  _acIrodaDarab := 0;
  acDbase.Connected := true;
  with Acquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
    end;
  _acirodaDarab := acquery.Recno;
  Csik.Max := _acirodaDarab;
  _adatPath := 'c:\receptor\mail\IRODAK\acirodak.dat';

  AssignFile(_iras,_adatpath);
  Rewrite(_iras);

  _byteTomb[1] := _acIrodaDarab;
  BlockWrite(_iras,_byteTomb,1);

  AcQuery.First;
  _cc := 0;
  while not AcQuery.Eof do
    begin
       Csik.Position := _cc;
       inc(_cc);
       with AcQuery do
         begin
           _uzlet    := FieldByName('UZLET').asInteger;
           _boltNev  := trim(FieldByName('KESZLETNEV').asString);
         end;

       _byteTomb[1] := _uzlet;
       BlockWrite(_iras,_byteTomb,1);
       OnewordWrite(_boltnev);

      AcQuery.Next;
    end;
  CloseFile(_iras);
  acQuery.Close;
  acDbase.Close;
end;




// =============================================================================
                procedure TForm1.OneWordWrite(_szo: string);
// =============================================================================

var _hszo,i: integer;

begin
  _szo := trim(_szo);
  _hszo := length(_szo);
  _bytetomb[1] := _hszo;
  BlockWrite(_iras,_bytetomb,1);
  if _hszo=0 then exit;
  for i := 1 to _hszo do
    begin
      _kod := 255-ord(_szo[i]);
      _bytetomb[i] := _kod;
    end;
  BlockWrite(_iras,_bytetomb,_hszo);
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  startTimer.Enabled := true;
end;

end.
