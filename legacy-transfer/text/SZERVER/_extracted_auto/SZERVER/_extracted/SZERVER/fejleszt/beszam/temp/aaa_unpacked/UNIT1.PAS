unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _korzetnevek: array[1..9] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
                                    'DEBRECEN','NYÍREGYHÁZA','BÉKÉSCSABA',
                                    'PÉCS','KAPOSVÁR','ZÁLOG');
  _korzetszamok: array[1..9] of WORD = (10,20,40,50,63,75,120,145,500);

  _korzetPtDb: array[1..9] of byte;
  _korzetPtszamSor: array[1..9,1..30] of byte;

  _korzetIndex,_aktkorzetdarab: byte;
  _kNev,_aktkorzetnev,_rangestr,_long: string;

 
  _penztarnev: array[1..170] of string;

  _konk : array[1..22] of string;
  _kkonk: array[1..9,1..6] of byte;
  _konkdb: array[1..9] of byte = (4,6,6,5,5,4,4,5,3);

implementation

uses Unit2;

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  MakeExcel.showmodal;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  _konk[1] := 'BRIGETIO';
  _konk[2] := 'BUZAI';
  _konk[3] := 'CHANGE PONT';
  _konk[4] := 'CORNER';
  _konk[5] := 'CORRECT';
  _konk[6] := 'EURÓ-MANI';
  _konk[7] := 'FECO';
  _konk[8] := 'FÖNICIA';
  _konk[9] := 'GÓDI';
  _konk[10]:= 'IBUSZ';
  _konk[11]:= 'INFINITI';
  _konk[12]:= 'INTERCHANGE';
  _konk[13]:= 'MECSEK TAKARÉK';
  _konk[14]:= 'MINIBANK';
  _konk[15]:= 'MISO';
  _konk[16]:= 'NÁDIX';
  _konk[17]:= 'NÉMETH';
  _konk[18]:= 'NORTHLINE';
  _konk[19]:= 'OROSTRAVEL';
  _konk[20]:= 'ÖREG';
  _konk[21]:= 'ROMÁN';
  _konk[22]:= 'SÜMEGI';

  _kkonk[1,1] := 9;
  _kkonk[1,2] := 10;
  _kkonk[1,3] := 13;
  _kkonk[1,4] := 17;

  _kkonk[2,1] := 4;
  _kkonk[2,2] := 5;
  _kkonk[2,3] := 10;
  _kkonk[2,4] := 12;
  _kkonk[2,5] := 14;
  _kkonk[2,6] := 18;

  _kkonk[3,1] := 4;
  _kkonk[3,2] := 5;
  _kkonk[3,3] := 6;
  _kkonk[3,4] := 10;
  _kkonk[3,5] := 11;
  _kkonk[3,6] := 18;

  _kkonk[4,1] := 2;
  _kkonk[4,2] := 5;
  _kkonk[4,3] := 8;
  _kkonk[4,4] := 10;
  _kkonk[4,5] := 16;

  _kkonk[5,1] := 3;
  _kkonk[5,2] := 5;
  _kkonk[5,3] := 10;
  _kkonk[5,4] := 14;
  _kkonk[5,5] := 21;

  _kkonk[6,1] := 10;
  _kkonk[6,2] := 18;
  _kkonk[6,3] := 19;
  _kkonk[6,4] := 20;

  _kkonk[7,1] := 4;
  _kkonk[7,2] := 5;
  _kkonk[7,3] := 10;
  _kkonk[7,4] := 15;

  _kkonk[8,1] := 1;
  _kkonk[8,2] := 5;
  _kkonk[8,3] := 7;
  _kkonk[8,4] := 10;
  _kkonk[8,5] := 22;

  _kkonk[9,1] := 1;
  _kkonk[9,2] := 5;
  _kkonk[9,3] := 17;

  _penztarnev[11] := 'Bonyhád TESCO';
  _penztarnev[12] := 'Szekszárd belváros';
  _penztarnev[14] := 'Paksi TESCO';
  _penztarnev[16] := 'Szekszárd TESCO';
  _penztarnev[17] := 'Baja TESCO';
  _penztarnev[99] := 'Mohács TESCO';
  _penztarnev[100]:= 'Kalocsa TESCO';

  _korzetPtdb[1] := 7;
  _korzetPtdb[2] := 0;
  _korzetPtdb[3] := 0;
  _korzetPtdb[4] := 0;
  _korzetPtdb[5] := 0;
  _korzetPtdb[6] := 0;
  _korzetPtdb[7] := 0;
  _korzetPtdb[8] := 0;
  _korzetPtdb[9] := 0;

  _korzetPtszamSor[1,1] := 11;
  _korzetPtszamSor[1,2] := 12;
  _korzetPtszamSor[1,3] := 14;
  _korzetPtszamSor[1,4] := 16;
  _korzetPtszamSor[1,5] := 17;
  _korzetPtszamSor[1,6] := 99;
  _korzetPtszamSor[1,7] := 100;


end;

end.
