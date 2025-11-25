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
  aPPLICATION.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Havizaras.showmodal;
end;

end.

{
@      EXCLUSIVE
  BEST CHANGE ZRT
              PECS, ARKAD
        PECS, BAJCSY-ZS. U. 11.
            Tel: 72/523-022
----------------------------------------
   2016 SZEPTEMBER havi penztarzaras
----------------------------------------
        Kezdo datum: 2016.09.01
         Zaro datum: 2016.09.30
----------------------------------------
Valuta         Novekedes     Csokkenes
----------------------------------------
AUD        Nyito:          170
 Vetel-Elad:          650            110
 Atvet-Atad:          100            600
Tobbl-Hiany:       -              -     
            Zaro:          210
----------------------------------------
BAM        Nyito:       -     
 Vetel-Elad:          770            720
 Atvet-Atad:           50             50
Tobbl-Hiany:           50             50
            Zaro:           50
----------------------------------------
BGN        Nyito:        1,771
 Vetel-Elad:          251          1,603
 Atvet-Atad:        1,300          1,000
Tobbl-Hiany:       -              -     
            Zaro:          719
----------------------------------------
BRL        Nyito:          165
 Vetel-Elad:       -                   5
 Atvet-Atad:       -              -     
Tobbl-Hiany:       -              -     
            Zaro:          160
----------------------------------------
CAD        Nyito:          465
 Vetel-Elad:        1,260            940
 Atvet-Atad:          100            600
Tobbl-Hiany:       -              -     
            Zaro:          285
----------------------------------------
CHF        Nyito:        1,820
 Vetel-Elad:       14,630          5,110
 Atvet-Atad:        5,000         14,000
Tobbl-Hiany:       -              -     
            Zaro:        2,340
----------------------------------------
CNY        Nyito:            1
 Vetel-Elad:        2,351              1
 Atvet-Atad:       -              -     
Tobbl-Hiany:       -              -     
            Zaro:        2,351
----------------------------------------
CZK        Nyito:       32,900
 Vetel-Elad:       13,400        142,400
 Atvet-Atad:      120,000         -     
Tobbl-Hiany:       -              -     
            Zaro:       23,900
----------------------------------------
DKK        Nyito:           50
 Vetel-Elad:        2,600          2,600
 Atvet-Atad:       -              -     
Tobbl-Hiany:       -              -     
            Zaro:           50
----------------------------------------
EUR        Nyito:       10,563
 Vetel-Elad:      365,325        133,416
 Atvet-Atad:       25,000        253,000
Tobbl-Hiany:       -              -     
            Zaro:       14,472
----------------------------------------
GBP        Nyito:        1,805
 Vetel-Elad:       32,570         17,005
 Atvet-Atad:        4,990         20,500
Tobbl-Hiany:       -              -     
            Zaro:        1,860
----------------------------------------
HRK        Nyito:       31,910
 Vetel-Elad:      126,150        149,650
 Atvet-Atad:       75,100         60,000
Tobbl-Hiany:       -              -     
            Zaro:       23,510
----------------------------------------
HUF        Nyito:    8,063,130
 Vetel-Elad:   65,104,275    152,054,350
 Bankkartya:      448,205
 Atvet-Atad:  101,937,750     16,500,000
Tobbl-Hiany:       -              -     
            Zaro:    6,550,805
----------------------------------------
ILS        Nyito:          150
 Vetel-Elad:          100         -     
 Atvet-Atad:       -              -     
Tobbl-Hiany:       -              -     
            Zaro:          250
----------------------------------------
JPY        Nyito:       -     
 Vetel-Elad:      235,000        200,000
 Atvet-Atad:      200,000        235,000
Tobbl-Hiany:       -              -     
            Zaro:       -     
----------------------------------------
MXN        Nyito:       -     
 Vetel-Elad:       -              -     
 Atvet-Atad:       -              -     
Tobbl-Hiany:       -              -     
            Zaro:       -     
----------------------------------------
NOK        Nyito:        2,650
 Vetel-Elad:       17,350          9,900
 Atvet-Atad:        2,500         12,000
Tobbl-Hiany:       -              -     
            Zaro:          600
----------------------------------------
NZD        Nyito:       -     
 Vetel-Elad:       -              -     
 Atvet-Atad:       -              -     
Tobbl-Hiany:       -              -     
            Zaro:       -     
----------------------------------------
PLN        Nyito:        3,290
 Vetel-Elad:        3,680         15,340
 Atvet-Atad:       13,300         -     
Tobbl-Hiany:       -              -     
            Zaro:        4,930
----------------------------------------
RON        Nyito:        5,152
 Vetel-Elad:       13,130         16,615
 Atvet-Atad:        7,000          3,000
Tobbl-Hiany:       -              -     
            Zaro:        5,667
----------------------------------------
RSD        Nyito:       54,890
 Vetel-Elad:       53,350         91,820
 Atvet-Atad:       70,050             50
Tobbl-Hiany:           50             50
            Zaro:       86,420
----------------------------------------
RUB        Nyito:        1,560
 Vetel-Elad:       12,750          6,510
 Atvet-Atad:       -              -     
Tobbl-Hiany:       -              -     
            Zaro:        7,800
----------------------------------------
SEK        Nyito:        1,460
 Vetel-Elad:       38,290          8,250
 Atvet-Atad:        4,500         33,000
Tobbl-Hiany:       -              -     
            Zaro:        3,000
----------------------------------------
THB        Nyito:        4,080
 Vetel-Elad:       -                  20
 Atvet-Atad:       -              -     
Tobbl-Hiany:       -              -     
            Zaro:        4,060
----------------------------------------
TRY        Nyito:        6,100
 Vetel-Elad:        1,765            915
 Atvet-Atad:       -               3,000
Tobbl-Hiany:       -              -     
            Zaro:        3,950
----------------------------------------
UAH        Nyito:        6,556
 Vetel-Elad:          103            601
 Atvet-Atad:       -               3,000
Tobbl-Hiany:       -              -     
            Zaro:        3,058
----------------------------------------
USD        Nyito:        4,899
 Vetel-Elad:       64,271         21,291
 Atvet-Atad:        4,000         48,000
Tobbl-Hiany:       -              -     
            Zaro:        3,879
----------------------------------------
        HAVI FORGALOM OSSZESITES
----------------------------------------
Havi vetelnel kiadas....:  152,044,050 Ft
Havi eladasnal bevetel..:   65,552,480 Ft
   - ebbol bankkartyaval:      448,205 Ft
----------------------------------------
           KEZELESI KOLTSEGEK
----------------------------------------
Havi nyito osszeg ......:     973,460
Kezelesi koltseg .......:   2,941,580
Atvett osszeg ..........:      -     
Atadott osszeg .........:   2,348,840
Havi zaro osszeg .......:   1,566,200
----------------------------------------
       HORVÁT KUNA HAVI ZÁRÁSA
----------------------------------------
Havi nyito osszeg ......:     973,460
Vett horvát kuna .......:      -
Atadott osszeg .........:   2,348,840
Havi zaro osszeg .......:   1,566,200
----------------------------------------
            HAVI ZAROKESZLET
----------------------------------------
Dnem   Keszlet     Arfolyam       Ertek
----------------------------------------
AUD          210  21,036       44,175 Ft
BAM           50  15,807        7,903 Ft
BGN          719  15,807      113,652 Ft
BRL          160   8,476       13,561 Ft
CAD          285  20,993       59,830 Ft
CHF        2,340  28,525      667,485 Ft
CNY        2,351   4,143       97,401 Ft
CZK       23,900   1,144      273,416 Ft
DKK           50   4,147        2,073 Ft
EUR       14,472  30,915    4,474,018 Ft
GBP        1,860  35,823      666,307 Ft
HRK       23,510   4,114      967,201 Ft
HUF    6,550,805     100    6,550,805 Ft
ILS          250   7,358       18,395 Ft
JPY       -          274       -      Ft
MXN       -        1,408       -      Ft
NOK          600   3,438       20,628 Ft
NZD       -       20,057       -      Ft
PLN        4,930   7,165      353,234 Ft
RON        5,667   6,933      392,893 Ft
RSD       86,420     251      216,914 Ft
RUB        7,800     436       34,008 Ft
SEK        3,000   3,215       96,450 Ft
THB        4,060     797       32,358 Ft
TRY        3,950   9,193      363,123 Ft
UAH        3,058   1,067       32,628 Ft
USD        3,879  27,635    1,071,961 Ft
----------------------------------------
Osszes keszlet erteke ..:  16,570,419 Ft
Forint keszlet .........:   6,550,805 Ft
Mindosszesen ...........:  23,121,224 Ft
----------------------------------------
     WESTERN UNION FORGALOM ZARASA
----------------------------------------
            Usa dollar    Magyar Forint
----------------------------------------
Nyito :          1,457         773,120
Bevet :          2,500       7,281,650
Kiadas:          1,400       7,020,570
Zaro  :          2,557       1,034,200
----------------------------------------
   ELEKTROMOS KERESKEDES HAVI ZARASA
----------------------------------------
Nyito keszlet ........:      -      Ft
Penz atvetel .........:      19,490 Ft
Penzatadas ...........:         628 Ft
Zaro keszlet .........:      18,862 Ft
----------------------------------------
         A HAVI UGYFELFORGALOM
----------------------------------------
        Elado ugyfelek:  3,020 FO
         Vevo ugyfelek:    895 FO
----------------------------------------



}
