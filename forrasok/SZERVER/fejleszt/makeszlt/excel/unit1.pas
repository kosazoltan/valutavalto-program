unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, WININET, StrUtils;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _hNet,_hFTP,_hSearch: HINTERNET;
  _findData: WIN32_FIND_DATA;

  _dnemDarab: integer = 20;
  _dnem:array[1..20] of string = ('EUR','USD','GBP','CHF','AUD','CAD','DKK',
           'JPY','NOK','SEK','CZK','HRK','PLN','RON','RSD','BGN','ILS','UAH',
           'RUB','EUA');

  _valutanemek: array[1..20] of string = ('AUD','BGN','CAD','CHF','CZK','DKK',
           'EUR','GBP','HRK','HUF','ILS','JPY','NOK','PLN','RON','RSD','RUB',
           'SEK','UAH','USD');

  _valutanevek: array[1..20] of string = ('AUSZTRÁL DOLLÁR','BOLGÁR LEVA','KANADAI DOLLÁR',
            'SVÁJCI FRANK','CSEH KORONA','DÁN KORONA','EURÓ','ANGOL FONT','HORVÁT KUNA',
            'MAGYAR FORINT','IZRAELI SHAKEL','JAPÁN YEN','NORVÉG KORONA','LENGYEL ZLOTYI',
            'ROMÁN LEJ','SZERB DINÁR','OROSZ RUBEL','SVÉD KORONA','UKRÁN HRIVNYA',
            'AMERIKAI DOLLÁR');

  _korzetszamok: array[1..8] of byte = (10,20,40,50,63,75,120,145);
  _korzetnevek: array[1..9] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT','DEBRECEN',
             'NYIREGYHÁZ','BÉKÉSCSABA','PÉCS','KAPOSVÁR','EXCLUSIVE CHANGE');

  _irodadarab      : integer;                     // ennyi váltóiroda van (a zártakkal együtt)
  _irodanevek      : array[1..150] of string;     // az összes iroda neve
  _valtokorzetek   : array[1..150] of byte;       // az egyes irodák körzetszámai

  _elszarfolyamok  : array[1..20] of real;        // a 20 valuta elszámoló árfolyamai

  _korzet          : integer;
  _aktkorzetDarab  : integer;
  _korzetKeszlet   : array[1..8,1..20] of integer;   // a körzetek összesített készletei
  _korzetertek     : array[1..8,1..20] of integer;   // a körzetek összesített forintértéke

  _ebcKeszlet      : array[1..20] of integer;     // A teljes cég összes készlete
  _ebcertek        : array[1..20] of integer;     // A teljes cég forintértéke
  _korzetValtodarab: array[1..8] of byte;         // Egyes körzetekben lévö élõ irodák száma

  _eloIrodadarab   : integer;                     // Ennyi élõ iroda küldött adatokat
  _eloIrodaSor     : array[1..150] of byte;       // A fentiek irodaszámai
  _valutakeszlet   : array[1..150,1..20] of integer; // Az élõirodák valutakészletei
  _valtosor        : array[1..8,1..25] of Byte;   // A 8 körzet irodáinak sorszámai

  // ---------------------------------------------------------------------------

  _ftpPort: integer = 21;
  _host: string = '89.135.183.117';
  _userId: string = 'ebc-10%';
  _ftpPassword: string = 'klc+45%';

  _bytetomb: array[1..4096] of byte;

  // ---------------------------------------------------------------------------

  _width,_height,_top,_left,_code,_aktPenztar: integer;

  _workDir,_ktszfile,_aktfilenev: string;
  _sikeres: boolean;
  _olvas: file of byte;
  _aktvalutaDarab: integer;
  _mamas: string;

implementation

uses Unit2;

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);

var i,j: integer;

begin
   for i:= 1 to 3 do
     begin
       for j := 1 to 20 do _valutakeszlet[i,j] := 0;
     end;
   _elszarfolyamok[1] := 23500;
   _elszarfolyamok[2] := 3100;
   _elszarfolyamok[3] := 500;
   _elszarfolyamok[4] := 1340;
   _elszarfolyamok[5] := 3400;
   _elszarfolyamok[6] := 11200;
   _elszarfolyamok[7] := 3800;
   _elszarfolyamok[8] := 150;
   _elszarfolyamok[9] := 560;
   _elszarfolyamok[10] := 23000;
   _elszarfolyamok[11] := 543;
   _elszarfolyamok[12] := 2300;
   _elszarfolyamok[13] := 2400;
   _elszarfolyamok[14] := 2450;
   _elszarfolyamok[15] := 2550;
   _elszarfolyamok[16] := 233;
   _elszarfolyamok[17] := 1770;
   _elszarfolyamok[18] := 2400;
   _elszarfolyamok[19] := 2760;
   _elszarfolyamok[20] := 1000;

   _korzetvaltodarab[1] := 3;
   _korzetvaltodarab[2] := 2;
   _korzetvaltodarab[3] := 5;
   _korzetvaltodarab[4] := 4;
   _korzetvaltodarab[5] := 3;
   _korzetvaltodarab[6] := 2;
   _korzetvaltodarab[7] := 5;
   _korzetvaltodarab[8] := 2;

   _irodadarab := 25;

   _irodanevek[1] := 'SZEKSZÁRD';
   _irodanevek[2] := 'MOHÁCS';
   _irodanevek[3] := 'KALOCSA';
   _irodanevek[4] := 'TOKAJ';
   _irodanevek[5] := 'BÓLY';
   _irodanevek[6] := 'PÁPA';
   _irodanevek[7] := 'SZIGETVÁR';
   _irodanevek[8] := 'PÉCS';
   _irodanevek[9] := 'BUDAPEST';
   _irodanevek[10] := 'KINIZS';
   _irodanevek[11] := 'BAJA';
   _irodanevek[12] := 'SZENTES';
   _irodanevek[13] := 'NOGRÁD';
   _irodanevek[14] := 'KOMLÓ';
   _irodanevek[15] := 'EGER';
   _irodanevek[16] := 'SZENTENDRE';
   _irodanevek[17] := 'KOMÁROM';
   _irodanevek[18] := 'KELENCE';
   _irodanevek[19] := 'SZEGED';
   _irodanevek[20] := 'DEBRECEN';
   _irodanevek[21] := 'SZOLNOK';
   _irodanevek[22] := 'SÁSD';
   _irodanevek[23] := 'MOHÁCS';
   _irodanevek[24] := 'MISKOLC';
   _irodanevek[25] := 'SIÓFOK';

   _valutakeszlet[1,1] := 1200;
   _valutakeszlet[1,2] := 110;
   _valutakeszlet[1,5] := 240;
   _valutakeszlet[1,6] := 106;
   _valutakeszlet[1,12]:= 1030;
   _valutakeszlet[1,17]:= 1205;
   _valutakeszlet[1,20]:= 1260;

   _valutakeszlet[2,1] := 1200;
   _valutakeszlet[2,2] := 110;
   _valutakeszlet[2,5] := 240;
   _valutakeszlet[2,6] := 100;

   _valutakeszlet[3,12]:= 1000;
   _valutakeszlet[3,17]:= 1205;
   _valutakeszlet[3,20]:= 1260;

   _valutakeszlet[4,1] := 1500;
   _valutakeszlet[4,5] := 150000;

   _valutakeszlet[5,1] := 1200;
   _valutakeszlet[5,9] := 100;
   _valutakeszlet[5,13] := 12000;

   _valutakeszlet[6,1] := 1200;
   _valutakeszlet[6,2] := 110;
   _valutakeszlet[6,9] := 240;
   _valutakeszlet[6,16] := 100;

   _valutakeszlet[7,13] := 1200;
   _valutakeszlet[7,16] := 110;
   _valutakeszlet[7,17] := 240;
   _valutakeszlet[7,18] := 100;

   _valutakeszlet[8,1] := 1200;
   _valutakeszlet[8,6] := 110;
   _valutakeszlet[8,15] := 240;
   _valutakeszlet[8,16] := 160;

   _valutakeszlet[9,1] := 10;
   _valutakeszlet[9,2] := 1100;
   _valutakeszlet[9,5] := 234;
   _valutakeszlet[9,16] := 250;

   _valutakeszlet[10,1] := 1250;
   _valutakeszlet[10,9] := 190;
   _valutakeszlet[10,15] := 290;
   _valutakeszlet[10,20] := 110;

   _valutakeszlet[11,4] := 250;
   _valutakeszlet[11,9] := 390;
   _valutakeszlet[11,15] := 2190;
   _valutakeszlet[11,20] := 1100;

   _valutakeszlet[12,4] := 250;
   _valutakeszlet[12,9] := 390;
   _valutakeszlet[12,15] := 2190;
   _valutakeszlet[12,20] := 1100;

   _valutakeszlet[13,4] := 210;
   _valutakeszlet[13,12] := 690;
   _valutakeszlet[13,15] := 2100;
   _valutakeszlet[13,16] := 1100;

   _valutakeszlet[14,6] := 250;
   _valutakeszlet[14,9] := 390;
   _valutakeszlet[14,11]:= 2190;
   _valutakeszlet[14,20]:= 1100;

   _valutakeszlet[15,4] := 250;
   _valutakeszlet[15,9] := 390;
   _valutakeszlet[15,15] := 2190;
   _valutakeszlet[15,20] := 1120;

   _valutakeszlet[16,4] := 250;
   _valutakeszlet[16,9] := 390;
   _valutakeszlet[16,15] := 2190;
   _valutakeszlet[16,20] := 1100;

   _valutakeszlet[17,4] := 250;
   _valutakeszlet[17,9] := 390;
   _valutakeszlet[17,15] := 2190;
   _valutakeszlet[17,20] := 1100;

   _valutakeszlet[18,4] := 55;
   _valutakeszlet[18,9] := 4490;
   _valutakeszlet[18,15] := 23;
   _valutakeszlet[18,20] := 118;

   _valutakeszlet[19,4] := 200;
   _valutakeszlet[19,9] := 1190;
   _valutakeszlet[19,15] := 2190;
   _valutakeszlet[19,20] := 1100;

   _valutakeszlet[20,4] := 550;
   _valutakeszlet[20,6] := 3901;
   _valutakeszlet[20,15]:= 2190;
   _valutakeszlet[20,17]:= 1100;

   _valutakeszlet[21,4] := 252;
   _valutakeszlet[21,6] := 390;
   _valutakeszlet[21,12]:= 2190;
   _valutakeszlet[21,17]:= 1100;

   _valutakeszlet[22,7] := 250;
   _valutakeszlet[22,11]:= 390;
   _valutakeszlet[22,15]:= 2190;
   _valutakeszlet[22,18]:= 1100;

   _valutakeszlet[23,1] := 150;
   _valutakeszlet[23,9] := 323;
   _valutakeszlet[23,15]:= 290;
   _valutakeszlet[23,17]:= 1170;

   _valutakeszlet[24,1] := 20;
   _valutakeszlet[24,9] := 310;
   _valutakeszlet[24,10]:= 229;
   _valutakeszlet[24,20]:= 1180;

   _valutakeszlet[25,2] := 250;
   _valutakeszlet[25,5] := 690;
   _valutakeszlet[25,10]:= 269;
   _valutakeszlet[25,18]:= 1300;

   _eloIrodaDarab := 25;

   _eloirodasor[1] := 1;
   _eloirodasor[2] := 2;
   _eloirodasor[3] := 3;
   _eloirodasor[4] := 4;
   _eloirodasor[5] := 5;
   _eloirodasor[6] := 6;
   _eloirodasor[7] := 7;
   _eloirodasor[8] := 8;
   _eloirodasor[9] := 9;
   _eloirodasor[10]:= 10;
   _eloirodasor[11]:= 11;
   _eloirodasor[12]:= 12;
   _eloirodasor[13]:= 13;
   _eloirodasor[14]:= 14;
   _eloirodasor[15]:= 15;
   _eloirodasor[16]:= 16;
   _eloirodasor[17]:= 17;
   _eloirodasor[18]:= 18;
   _eloirodasor[19]:= 19;
   _eloirodasor[20]:= 20;
   _eloirodasor[21]:= 21;
   _eloirodasor[22]:= 22;
   _eloirodasor[23]:= 23;
   _eloirodasor[24]:= 24;
   _eloirodasor[25]:= 25;

   _korzetvaltodarab[1] := 3;
   _korzetvaltodarab[2] := 2;
   _korzetvaltodarab[3] := 3;
   _korzetvaltodarab[4] := 2;
   _korzetvaltodarab[5] := 3;
   _korzetvaltodarab[6] := 4;
   _korzetvaltodarab[7] := 5;
   _korzetvaltodarab[8] := 3;

   _valtosor[1,1] := 1;
   _valtosor[1,2] := 2;
   _valtosor[1,3] := 3;

   _valtosor[2,1] := 4;
   _valtosor[2,2] := 5;

   _valtosor[3,1] := 6;
   _valtosor[3,2] := 7;
   _valtosor[3,3] := 8;

   _valtosor[4,1] := 9;
   _valtosor[4,2] := 10;

   _valtosor[5,1] := 11;
   _valtosor[5,2] := 12;
   _valtosor[5,3] := 13;

   _valtosor[6,1] := 14;
   _valtosor[6,2] := 15;
   _valtosor[6,3] := 16;
   _valtosor[6,4] := 17;

   _valtosor[7,1] := 18;
   _valtosor[7,2] := 19;
   _valtosor[7,3] := 20;
   _valtosor[7,4] := 21;
   _valtosor[7,5] := 22;

   _valtosor[8,1] := 23;
   _valtosor[8,2] := 24;
   _valtosor[8,3] := 25;

   _mamas := leftstr(datetostr(date),10);
   MakeExcelTabla.showmodal;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  Application.Terminate;
end;

end.
