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

var _ok: integer;

begin
  _ok := Makepack.SHOWMODAL;
  if _ok=1 then Form1.Color := clGreen else Form1.Color := clred;
end;

{
var
  ESTIZAR: TESTIZAR;

  xNevek: array[1..10] of string = ('CIMT','NARF','ARFE','WAFA','WUNI','WZAR','TESC',
                          'BF','BT','TRAD');

  xIBTip: array[1..10] of integer = (2,2,2,2,2,2,2,2,2,2);

  xMezok: array[1..111] of string = ('AFA20SZAZALEKOS','AFA5SZAZALEKOS','AFAOSSZEG',
              'ALLAMPOLGAR','ANYJANEVE',
              'ARFOLYAM','AZONOSITO','BANKJEGY','BIZONYLATSZAM','BIZONYLATTIPUS',

              'BRUTTOOSSZEG','CIMLET1','CIMLET2','CIMLET3','CIMLET4',
              'CIMLET5','CIMLET6','CIMLET7','CIMLET8','CIMLET9',

              'CIMLET10','CIMLET11','CIMLET12','CIMLET13','CIMLET14','COIN',
              'DATUM','ELADASIARFOLYAM','ELLATMANYFORINT','ELOJEL',

              'ELOZONEV','ELSZAMOLASIARFOLYAM','ENGEDMENYTIPUSSZAM','FOEGYSEGSZAM',
              'FORINTERTEK','FOTEVEKENYSEG','HUFBEVETEL','HUFKIADAS','HUFNYITO','HUFZARO',

              'IDO','JOGISZEMELYNEV','KEPVISBEO','KEPVISELONEV','KIFIZETETTOSSZEG',
              'LAKCIM','LAKCIMKARTYA','LEANYKORI','MEGBIZOSZAM','MEGBIZOTT',

              'MEGBIZOTTBEOSZTASA','MEGBIZOTTNEVE','MEGBIZOTTSZAMA','METROBEVETEL',
              'METROKIADAS','METRONYITO','METROVISSZA','METROZARO','MTCNSZAM','NEV',

              'NYITO','OKIRATSZAM','OKMANYTIPUS','OSSZESEN','OSSZESFORINT','OSSZESFORINTERTEK',
              'PENZTAR','PENZTAROSNEV','PENZTARSZAM','PLOMBASZAM',

              'SORSZAM','STORNO','STORNOBIZONYLAT','STORNOZOTTBIZONYLAT','SZALLITONEV',
              'SZAMLABRUTTO','SZAMLASZAM','SZULETESIHELY','SZULETESIIDO','TARSPENZTARKOD',

              'TARTOZKODASIHELY','TELEFONSZAM','TELEPHELYCIM','TESCOBEVETEL','TESCOKIADAS',
              'TESCONYITO','TESCOVISSZA','TESCOZARO','TETEL','TIPUS',

              'TRANZAKCIOTIPUS','TRBPENZTAR','STORNOBIZONYLAT','UGYFELNEV','UGYFELSZAM',
              'UGYFELTIPUS','UGYKEZELESIDIJ','UJARFOLYAM','USDBEVETEL','USDKIADAS',

              'USDNYITO','USDZARO','VALUTANEM','VETELIARFOLYAM','WUGYFELNEV',
              'WUGYFELSZAM','ZARO','ELSZAMARFOLYAM','PENZTAROSIMAX','NETTO','KEZELESIDIJ');



  xMkodok: array[1..111] of integer = (11,11,11,4,4,9,4,11,5,10,
                                      11,2,2,2,2,2,2,2,2,2,
                                      2,2,2,2,2,1,3,9,11,10,
                                      4,9,1,1,11,4,11,11,11,11,
                                      8,4,4,4,11,4,4,4,11,11,
                                      4,4,11,11,11,11,11,11,4,4,
                                      11,4,4,11,11,11,4,4,2,4,
                                      4,1,5,5,4,11,4,4,4,4,
                                      4,4,4,11,11,11,11,11,1,10,
                                      4,4,4,4,11,10,11,9,11,11,
                                      11,11,6,9,4,11,11,9,9,11,11);


  xTipusok: array[1..11] of integer = (1,1,3,3,3,3,2,3,2,3,1);  // 1=I,2=F,3=S

  xMezodarab: array[1..10] of integer;

  xMezoSs: array[1..10,1..20] of integer;



   1. kód: Byte   Result: 1 byte (numerikus);
   2. kód: Word   Result: 1 word (numerikus)
   3. Kód: Dátum  Result: char (10) [DATUMDEKOD]
   4. kód: Szöveg Result: string [TEXTDEKOD]
   5. kód: Bizonylatszám  Result: Bizonylatszám char(7) [DNEMDEKOD]
   6. Kód: Valutanem Result: Char (3) [DNEMDEKOD]
   7. Kód: DoublePrecision szám  [INTEGDEKOD] float
   8. kód: Idõ  char(8) [IDODEKOD]
   9. kód: Árfolyam  1000*Float [INTEGDEKOD/1000]
  10. kód: Character (1)
  11. kod: Nagy Integer  (integdekod)

  MEZÖK:

    1. AFA20SZAZALEKOS    11   Nagy integer
    2. AFA5SZAZALEKOS     11   Nagy integer
    3. AFAOSSZEG          11   Nagy integer
    4. ALLAMPOLGAR         4   String
    5. ANYJANEVE           4   String
    6. ARFOLYAM            9   Árfolyam
    7. AZONOSITO           4   String
    8. BANKJEGY           11   Nagy integer
    9. BIZONYLATSZAM       5   Bizonylat
   10. BIZONYLATTIPUS     10   karakter

   11. BRUTTOOSSZEG       11   Nagy integer
   12. CIMLET1             2   Word
   13. CIMLET2             2   Word
   14. CIMLET3             2   Word
   15. CIMLET4             2   Word
   16. CIMLET5             2   Word
   17. CIMLET6             2   Word
   18. CIMLET7             2   Word
   19. CIMLET8             2   Word
   20. CIMLET9             2   Word

   21. CIMLET10            2   Word
   22. CIMLET11            2   Word
   23. CIMLET12            2   Word
   24. CIMLET13            2   Word
   25. CIMLET14            2   Word
   26. COIN                1   Byte
   27. DATUM               3   Datum
   28. ELADASIARFOLYAM     9   Árfolyam
   29. ELLATMANYFORINT    11   Nagy integer
   30. ELOJEL             10   Karakter

   31. ELOZONEV            4   String
   32. ELSZAMOLASIARFOLYAM 9   Árfolyam
   33. ENGEDMENYTIPUSSZAM  1   Byte
   34. FOEGYSEGSZAM        1   Byte
   35. FORINTERTEK        11   Nagy integer
   36. FOTEVEKENYSEG       4   String
   37. HUFBEVETEL         11   Nagy integer
   38. HUFKIADAS          11   Nagy integer
   39. HUFNYITO           11   Nagy integer
   40. HUFZARO            11   Nagy integer

   41. IDO                 8   Idö
   42. JOGISZEMELYNEV      4   String
   43. KEPVISBEO           4   String
   44. KEPVISELONEV        4   String
   45. KIFIZETETTOSSZEG   11   Nagy integer
   46. LAKCIM              4   String
   47. LAKCIMKARTYA        4   String
   48. LEANYKORI           4   String
   49. MEGBIZOSZAM        11   Nagy integer
   50. MEGBIZOTT          11   Nagy integer

   51. MEGBIZOTTBEOSZTASA  4   String
   52. MEGBIZOTTNEVE       4   String
   53. MEGBIZOTTSZAMA     11   Nagy integer
   54. METROBEVETEL       11   Nagy integer
   55. METROKIADAS        11   Nagy integer
   56. METRONYITO         11   Nagy integer
   57. METROVISSZA        11   Nagy integer
   58. METROZARO          11   Nagy integer
   59. MTCNSZAM            4   String
   60. NEV                 4   String

   61. NYITO              11   Nagy integer
   62. OKIRATSZAM          4   String
   63. OKMANYTIPUS         4   String
   64. OSSZESEN           11   Nagy integer
   65. OSSZESFORINT       11   Nagy integer
   66. OSSZESFORINTERTEK  11   Nagy integer
   67. PENZTAR             4   String
   68. PENZTAROSNEV        4   String
   69. PENZTARSZAM         2   Word
   70. PLOMBASZAM          4   String

   71. SORSZAM             4   String
   72. STORNO              1   Byte
   73. STORNOBIZONYLAT     5   Bizonylat
   74. STORNOZOTTBIZONYLAT 5   Bizonylat
   75. SZALLITONEV         4   String
   76. SZAMLABRUTTO       11   Nagy integer
   77. SZAMLASZAM          4   String
   78. SZULETESIHELY       4   String
   79. SZULETESIIDO        4   String
   80. TARSPENZTARKOD      4   String

   81. TARTOZKODASIHELY    4   String
   82. TELEFONSZAM         4   String
   83. TELEPHELYCIM        4   String
   84. TESCOBEVETEL       11   Nagy integer
   85. TESCOKIADAS        11   Nagy integer
   86. TESCONYITO         11   Nagy integer
   87. TESCOVISSZA        11   Nagy integer
   88. TESCOZARO          11   Nagy integer
   89. TETEL               1   Byte
   90. TIPUS              10   Karakter

   91. TRANZAKCIOTIPUS     4   String
   92. TRBPENZTAR          4   String
   93. STORNOBIZONYLAT     4   sTRING
   94. UGYFELNEV           4   String
   95. UGYFELSZAM         11   Nagy integer
   96. UGYFELTIPUS        10   Karakter
   97. UGYKEZELESIDIJ     11   Nagy integer
   98. UJARFOLYAM          9   Árfolyam
   99. USDBEVETEL         11   Nagy integer
  100. USDKIADAS          11   Nagy integer

  101. USDNYITO           11   Nagy integer
  102. USDZARO            11   Nagy integer
  103. VALUTANEM           6   Dnem
  104. VETELIARFOLYAM      9   Árfolyam
  105. WUGYFELNEV          4   String
  106. WUGYFELSZAM        11   Nagy integer
  107. ZARO               11   Nagy integer

  108. ELSZAMARFOLYAM      9   Árfolyam
  109. PENZTAROSIMAX       9   Árfolyam
  111. TRANZDIJ           11   Nagy integer

  112. KEZELESIDIJ        11   Nagy integer
  113. BIZONYLAT           4   String
  114. MOZGAS              1   Byte
  115. ORIGBIZONYLAT       4   STRING



  _index,_rekdb,_ugyfeldarab,_jogidarab,_mbsz,_maxnap,_telefon: integer;
  _reksor,_reszRek,_szuro,_tszuro,_bszuro,_aktPara,_adatsor: string;
  _AKTKOD,_rekordDarab,_aktmezodb,_aktmezoss,_akttipus: integer;
  _matrica,_atadas,_atvetel,_zarokeszlet,_ft,_napikezelesidij: integer;
  _dataDarab,_feladva: byte;
  _aktmezonev,_nev,_leanykori,_tp,_zPenztar: string;
  _stornovan: boolean;
  _fileAlap,_kit,_tradeTabla: string;
  _aktTablanev: string;

  _tablaSorszam,_irany: byte;

  _Udata: array[1..15] of string;
  _ptszam: word;
  _bfFiln,_btFiln,_evhos: string;
  _personalPath: string;
  _targetPath: string;

  _adat: variant;
  _olvas,_iras: file of byte;
  _adatlapdarab,_csomagdarab: word;

  _forint: array[1..50] of integer;
  _addjel: array[1..50] of byte;
  _tarspt: array[1..50] of string;

  _pval : array[0..4] of string;
  _pkesz: array[0..4] of integer;


implementation

uses Unit63;

{$R *.dfm}

{
// =================================================================
     procedure TEstiZar.FormActivate(Sender: TObject);
// =================================================================


begin
    TOP := _top+250;
    Left := _left+310;

    _personalPath := 'c:\valuta\out\person.dat';
    _targetPath   := 'C:\VALUTA\OUT\ZTEMP.DAT';

    xMezoDarab[1] := 17;
    xMezoDarab[2] := 7;
    xMezoDarab[3] := 10;
    xMezoDarab[4] := 14;
    xMezoDarab[5] := 13;
    xMezoDarab[6] := 19;
    xMezoDarab[7] := 10;
    xMezoDarab[8] := 17;
    xMezoDarab[9] := 10;

    // 1. CIMTyymm:

    xMezoSs[1,1]  := 27;    //  1. DATUM
    xMezoSs[1,2]  := 103;   //  2. VALUTANEM
    xMezoSs[1,3]  := 66;    //  3. OSSZESFORINTERTEK
    xMezoSs[1,4]  := 12;    //  4. CIMLET1
    xMezoSs[1,5]  := 13;    //  5. CIMLET2
    xMezoSs[1,6]  := 14;    //  6. CIMLET3
    xMezoSs[1,7]  := 15;    //  7. CIMLET4
    xMezoSs[1,8]  := 16;    //  8. CIMLET5
    xMezoSs[1,9]  := 17;    //  9. CIMLET6
    xMezoSs[1,10] := 18;    // 10. CIMLET7
    xMezoSs[1,11] := 19;    // 11. CIMLET8
    xMezoSs[1,12] := 20;    // 12. CIMLET9
    xMezoSs[1,13] := 21;    // 13. CIMLET10
    xMezoSs[1,14] := 22;    // 14. CIMLET11
    xMezoSs[1,15] := 23;    // 15. CIMLET12
    xMezoSs[1,16] := 24;    // 16. CIMLET13
    xMezoSs[1,17] := 25;    // 17. CIMLET14

    // 2. NARFyymm:

    xMezoSs[2,1] := 27;     // 1. DATUM
    xMezoSs[2,2] := 103;    // 2. VALUTANEM
    xMezoSs[2,3] := 104;    // 3. VETELIARFOLYAM
    xMezoSs[2,4] := 28;     // 4. ELADASIARFOLYAM
    xMezoSs[2,5] := 32;     // 5. ELSZAMOLASIARFOLYAM
    xMezoSs[2,6] := 61;     // 6. NYITO
    xMezoSs[2,7] := 107;    // 7. ZARO

    // 3. ARFEyymm:

    xMezoSs[3,1] := 27;     // 1. DATUM
    xMezoSs[3,2] := 103;    // 2. VALUTANEM
    xMezoSs[3,3] := 6;      // 3. ARFOLYAM
    xMezoSs[3,4] := 98;     // 4. UJARFOLYAM
    xMezoSs[3,5] := 68;     // 5. PENZTAROSNEV
    xMezoSs[3,6] := 9;      // 6. BIZONYLATSZAM
    xMezoSs[3,7] := 8;      // 7. BANKJEGY
    xMezoSs[3,8] := 33;     // 8. ENGEDMENYTIPUSSZAM
    xMezoSs[3,9] := 108;    // 9. ELSZAMARFOLYAM
    xMezoSs[3,10]:= 109;    //10. PENZTAROSIMAX

    // 4. WAFAyymm:

    xMezoSs[4,1]  := 34;    //  1. FOEGYSEGSZAM
    xMezoSs[4,2]  := 69;    //  2.PENZTARSZAM
    xMezoSs[4,3]  := 95;    //  3. UGYFELSZAM
    xMezoSs[4,4]  := 27;    //  4. DATUM
    xMezoSs[4,5]  := 71;    //  5. SORSZAM
    xMezoSs[4,6]  := 77;    //  6. SZAMLASZAM
    xMezoSs[4,7]  := 11;    //  7. BRUTTOOSSZEG
    xMezoSs[4,8]  := 3;     //  8. AFAOSSZEG
    xMezoSs[4,9]  := 97;    //  9. UGYKEZELESIDIJ
    xMezoSs[4,10] := 45;    // 10. KIFIZETTOSSZEG
    xMezoSs[4,11] := 29;    // 11. ELLATMANYFORINT
    xMezoSs[4,12] := 91;    // 12. TRANZAKCIOTIPUS
    xMezoSs[4,13] := 72;    // 13. STORNO
    xMezoSs[4,14] := 93;    // 15. STORNOBIZONYLAT
 // xMezoSs[4,15] := 74;    // 14. STORNOZOTTBIZONYLAT

    // 5. WUNIyymm:

    xMezoSs[5,1]  := 34;    //  1. FOEGYSEGSZAM
    xMezoSs[5,2]  := 69;    //  2. PENZTARSZAM
    xMezoSs[5,3]  := 95;    //  3. UGYFELSZAM
    xMezoSs[5,4]  := 27;    //  4. DATUM
    xMezoSs[5,5]  := 71;    //  5. SORSZAM
    xMezoSs[5,6]  := 103;   //  6. VALUTANEM
    xMezoSs[5,7]  := 8;     //  7. BANKJEGY
    xMezoSs[5,8]  := 96;    //  8. UGYFELTIPUS
    xMezoSs[5,9]  := 68;    //  9. PENZTAROSNEV
    xMezoSs[5,10] := 91;    // 10. TRANZAKCIOTIPUS
    xMezoSs[5,11] := 59;    // 11. MTCNSZAM
    xMezoSs[5,12] := 72;    // 12. STORNO
    xMezoSs[5,13] := 93;    // 13. STORNOBIZONYLAT
//    xMezoSs[5,14] := 74;    // 14. STORNOZOTTBIZONYLAT

    // 6. WZARyymm:

    xMezoSs[6,1]  := 27;    //  1. DATUM
    xMezoSs[6,2]  := 101;   //  2. USDNYITO
    xMezoSs[6,3]  := 39;    //  3. HUFNYITO
    xMezoSs[6,4]  := 56;    //  4. METRONYITO
    xMezoSs[6,5]  := 86;    //  5. TESCONYITO
    xMezoSs[6,6]  := 102;   //  6. USDZARO
    xMezoSs[6,7]  := 40;    //  7. HUFZARO
    xMezoSs[6,8]  := 58;    //  8. METROZARO
    xMezoSs[6,9]  := 88;    //  9. TESCOZARO
    xMezoSs[6,10] := 99;    // 10. USDBEVETEL
    xMezoSs[6,11] := 37;    // 11. HUFBEVETEL
    xMezoSs[6,12] := 54;    // 12. METROBEVETEL
    xMezoSs[6,13] := 84;    // 13. TESCOBEVETEL
    xMezoSs[6,14] := 100;   // 14. USDKIADAS
    xMezoSs[6,15] := 38;    // 15. HUFKIADAS
    xMezoSs[6,16] := 55;    // 16. METROKIADAS
    xMezoSs[6,17] := 85;    // 17. TESCOKIADAS
    xMezoSs[6,18] := 57;    // 18. METROVISSZA
    xMezoSs[6,19] := 87;    // 19. TESCOVISSZA
//   xMezoSs[6,20] := 97;    // 20. UGYKEZELESIDIJ

    // 7. TESCyymm:

    xMezoSs[7,1]  := 27;    //  1. DATUM
    xMezoSs[7,2]  := 10;    //  2. BIZONYLATTIPUS
    xMezoSs[7,3]  := 9;     //  3. BIZONYLATSZAM
    xMezoSs[7,4]  := 106;   //  4. WUGYFELSZAM
    xMezoSs[7,5]  := 105;   //  5. WUGYFELNEV
    xMezoSs[7,6]  := 76;    //  6. SZAMLABRUTTO
    xMezoSs[7,7]  := 77;    //  7. SZAMLASZAM
    xMezoSs[7,8]  := 2;     //  8. AFA5SZAZALEKOS
    xMezoSs[7,9]  := 1;     //  9. AFA20SZAZALEKOS
    xMezoSs[7,10] := 65;    // 10. OSSZESFORINT
 //   xMezoSs[7,11] := 73;    // 11. STORNOBIZONYLAT
 //   xMezoSs[7,12] := 72;    // 12. STORNO

    // 8. BFyymm:

    xMezoSs[8,1]  := 9;     //  1. BIZONYLATSZAM
    xMezoSs[8,2]  := 90;    //  2. TIPUS
    xMezoSs[8,3]  := 27;    //  3. DATUM
    xMezoSs[8,4]  := 41;    //  4. IDO
    xMezoSs[8,5]  := 66;    //  5. OSSZESFORINTERTEK
    xMezoSs[8,6]  := 96;    //  6. UGYFELTIPUS
    xMezoSs[8,7]  := 95;    //  7. UGYFELSZAM
    xMezoSs[8,8]  := 94;    //  8. UGYFELNEV
    xMezoSs[8,9]  := 89;    //  9. TETEL
    xMezoSs[8,10] := 68;    // 10. PENZTAROSNEV
    xMezoSs[8,11] := 80;    // 11. TARSPENZTARKOD
    xMezoSs[8,12] := 92;    // 12. TRBPENZTAR
    xMezoSs[8,13] := 72;    // 13. STORNO
    xMezoSs[8,14] := 73;    // 14. STORNOBIZONYLAT
    xMezoSs[8,15] := 70;    // 15. PLOMBASZAM
    xMezoSs[8,16] := 75;    // 16. SZALLITONEV
    xMezoss[8,17] := 111;   // 17. TRANZDIJ


//    xMezoSs[8,17] := 74;  // 17. STORNOZOTTBIZONYLAT
//   xMezoSs[8,13] := 49;   // 13. MEGBIZOSZAM
//   xMezoSs[8,14] := 50;   // 14. MEGBIZOTT

    // 9. BTyymm:

    xMezoSs[9,1] := 9;      // 1. BIZONYLATSZAM
    xMezoSs[9,2] := 27;     // 2. DATUM
    xMezoSs[9,3] := 103;    // 3. VALUTANEM
    xMezoSs[9,4] := 6;      // 4. ARFOLYAM
    xMezoSs[9,5] := 32;     // 5. ELSZAMOLASIARFOLYAM
    xMezoSs[9,6] := 8;      // 6. BANKJEGY
    xMezoSs[9,7] := 35;     // 7. FORINTERTEK
    xMezoSs[9,8] := 30;     // 8. ELOJEL
    xMezoSs[9,9] := 26;     // 9. COIN
    xMezoSs[9,10] := 72;     // 10. STORNO

   (*
       // 14. KEZDyymm:

    xMezoSs[14,1] := 27;     // 1. DATUM
    xMezoSs[14,2] := 30;     // 2. ELOJEL
    xMezoSs[14,3] := 112;    // 3. KEZELESIDIJ
    xMezoSs[14,4] := 67;     // 4. PENZTAR
    xMezoSs[14,5] := 114;    // 5. MOZGAS
    xMezoSs[14,6] := 113;    // 6. BIZONYLAT


    *)

    // A napnyitás napja a default:

    _zaroev := strtoint(leftstr(_megnyitottnap,4));
    _zarohonap := strtoint(midstr(_megnyitottnap,6,2));
    _zaronap := strtoint(midstr(_megnyitottnap,9,2));

  (* Törli c:\valuta\out könyvtárt *)
   ClearOutDir;

   (* Beállítja a default dátumot *)

   Naptar.Year := _zaroEv;
   Naptar.Month := _zaroHonap;
   Naptar.Day := _zaroNap;

   _evhos := inttostr(_zaroev)+ ' '+ _honapnev[_zaroHonap];
   
   EvHonapPanel.Caption := _evhos;
   EvhonapPanel.Caption;

   // Ha a dátum oké. akkor megnyomja a datumoke gombot
   ActiveControl := CsomagoloGomb;
end;



// =================================================================
     procedure TEstiZar.NapZCancelClick(Sender: TObject);
// =================================================================

begin
  ModalResult := 2;
end;

//********************************************************************
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// *******************************************************************
// -------------   INNEN INDUL AZ ESTI ZÁRÁS -------------------------

// =================================================================
     procedure TEstiZar.CsomagoloGombClick(Sender: TObject);
// =================================================================
(* Itt megadta a zárásnap dátumát tárgyév, tárgyhó, tárgynap alakban *)

var
    _cimletdarab,_qq: integer;
  //  _aktDbfNev: string;
    _byte,_zByte: Byte;

begin

   _targyEv  := Naptar.Year;
   _targyHo  := Naptar.Month;
   _targynap := Naptar.Day;

   (* A zárás dátuma és irodaszám alapján kialakitja a csomagfile nevét *)

  _ptSzam := strtoint(_homePenztarszam);
  _zaroDString := IntToStr(_targyEv)+'.'+Form1.nulele(_targyHo,2)+'.'+Form1.nulele(_targyNap,2);
  _fileAlap := Irodakod(_PtSzam);
  _kit := Form1.KitKod(_zaroDString);

  _zaroFile := _fileAlap + '.' + _kit;
  _markerFile := _fileAlap + '.m';
  _markerPath :=  'C:\valuta\out\'+_markerFile;
  _zaroPath := 'C:\valuta\out\'+_zaroFile;

  // Ha lenne már csomagfile akkor azt törölni kell:
  SysUtils.DeleteFile(_zaroPath);

  (* A tárgyév és tárgyhónap alapján meghatározza a gyüjtõ adatbázisok farkát *)

  _farok := Form1.Nulele(_targyev-2000,2)+Form1.nulele(_targyHo,2);

  _napikezelesidij := GetkezelesiDIj;

  ValdataDbase.close;
  ValdataDbase.Connected := True;
  if ValdataTranz.InTransaction then ValdataTranz.Commit;

  _szuro := 'WHERE (DATUM='+chr(39)+_zaroDstring+chr(39)+')';
  _pcs := 'SELECT * FROM CIMT' + _farok + _sorveg + _szuro;

  with ValdataQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
    end;

  _cimletdarab := ValdataQuery.Recno;
  ValDataQuery.close;

  if (_CimletDarab=0) and (not _afasgep) then
    begin
      Form1.HibaFutty;
      ShowMessage('Nem volt cimletezés a kért napon !');
      exit;
    end;

(* Itt már mehet a csomagkészités  *)

  AssignFile(_iras,_zaroPath);
  Rewrite(_iras);

  _byte := ord('N');
  Blockwrite(_iras,_byte,1);

  _byte := ord('T');             // NW AZ ÚJ ZÁRÁS, NT tranzdijas zárás
  Blockwrite(_iras,_byte,1);

  _qq := 1;
  while _qq<18 do
    begin
      if (_qq<9)  then EgytablaKodolas(_qq);
      if (_qq=9)  then BlokktetelKodolas;
      if (_qq=10) then Matricakodolas;
      if (_qq=11) then UgyfelKodolas;
      if (_qq=12) then AdatlapKodolas;
      if (_qq=13) then Gongycsomagkodolas;
      if (_qq=14) then KezdijPackiro;
      if (_qq=15) then jelenletKodolas;
      if (_qq=16) then FoglaloKodolas;
      if (_qq=17) then XkezdijKodolas;
      inc(_qq);
    end;


  _zByte := 255;
  Blockwrite(_iras,_zByte,1);
  Blockwrite(_iras,_zbyte,1);
  Blockwrite(_iras,_zbyte,1);
  CloseFile(_iras);

  AssignFile(_iras,_markerPath);
  Rewrite(_iras);
  BlockWrite(_iras,_verzio,length(_verzio));
  CloseFile(_iras);

  modalresult := 1;
end;


// =================================================================
    procedure TestiZar.EgyTablaKodolas(_fileSorszam: integer);
// =================================================================

var
     _q,_aktkod,_akttipus,_fs: integer;
     _aktTablaTipus: integer;

begin

   ValdataDbase.connected := True;
   ValDataTabla.Close;

   _aktTablaNev := xNevek[_fileSorszam];  // CIMT0605.DBF,NARF0605.DBF ...
   _akttablatipus := xibTip[_filesorszam];  // 1=farokkal, 2=farok nélkül
   if _akttablaTipus=2 then _aktTablanev := _akttablanev + _farok;
   ValdataTabla.Tablename := _aktTablanev;

  (* Ha nincs ilyen tábla, akkor nincs kódolás sem *)
   if not ValdataTabla.Exists then exit;

  _aktMezoDb := xMezoDarab[_fileSorSzam];
  _stornovan := False;
  _fs := _filesorszam;
  if (_fs=7) then _stornovan := True;

  _tszuro := _szuro;
  if _stornoVan then _tszuro := _szuro + ' AND (STORNO=1)';

  _pcs := 'SELECT * FROM '+ _akttablanev + _sorveg;
  _pcs := _pcs + _tszuro;

  with VAldataQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
    end;

  _rekordDarab := ValdataQuery.Recno;

  (* Ha nincs zárónapi bejegyzés, akkor nincs kódolás sem *)
  if _rekordDarab = 0 then
    begin
      ValdataQuery.Close;
      exit;
    end;

   (* Beirja az address számot és a rekordok számát *)
  Beiras(1,_filesorszam);
  Beiras(2,_rekordDarab);

  (* Elölrõl kezdjük az adatbázis átnézését *)
  ValdataQuery.First;

  while not ValdataQuery.Eof  do
    begin
      (* A rekord összes mezõjét lekódolja és felirja *)
      for _q := 1 to _aktMezoDb do
        begin
          _aktMezoSS  := xMezoSS[_fileSorSzam,_q];  // 1,2, ... 107
          _aktMezoNev := xMezok[_aktmezoSS];         // 'BANKJEGY', 'ARFOLYAM', ...
          _aktkod := xMkodok[_aktmezoSS];            // 1 .. 11
          _aktTipus := xTipusok[_aktkod];            // Integer Float string 1,2,3

          Beiras(1,_aktmezoss);

          case _aktTipus of

          1: // integer
             _adat := ValdataQuery.FieldbyName(_aktMezoNev).asInteger;

          2: // real
              _adat := ValdataQuery.FieldbyName(_aktMezoNev).asFloat;

          3: // string
              _adat := VAldataQuery.FieldbyName(_aktMezoNev).asString;
            end;
          Beiras(_aktKod,_adat); // a mezõ adatát beirja a csomagba
        end;
        
       if (_fileSorszam=6) then
         begin
           Beiras(1,97);
           Beiras(11,_napikezelesidij);
         end;
         
       Beiras(1,255);
       (* Következõ rekord *)
       ValdataQuery.Next;

     end;
   (* Kész az adatbázis *)
   ValdataQuery.Close;
end;


// =================================================================
     procedure Testizar.BlokKTetelKodolas;
// =================================================================

(* Most a blokktételeket kódoljuk be *)

var _q: integer;
    _blokkfejnev,_blokktetnev: string;
    _adat: variant;

begin
  _blokkfejnev := 'BF' + _farok ;
  _blokktetnev := 'BT' + _farok;

  BlokkDbase.Connected := true;
  BlokkTabla.close;
  BlokkTabla.Tablename := _blokkfejnev;
  if not BlokkTabla.exists then exit;

  _pcs := 'SELECT FEJ.*, TET.*' + _sorveg;
  _pcs := _pcs +'FROM '+_blokkfejnev+' FEJ JOIN '+_blokktetnev+' TET'+_sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM'+_sorveg;
  _pcs := _pcs + 'WHERE (FEJ.DATUM='+chr(39)+ _zaroDstring + chr(39)+')';

  IF BlokkTranz.InTransaction then Blokktranz.commit;
  with BlokkQuery do
    begin
      close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
    end;

  _rekordDarab := BlokkQuery.Recno;
  if _rekordDarab=0 then
    begin
      Blokkquery.close;
      Exit;
    end;

  _aktMezoDb := xMezoDarab[9];

  (* Beirja az address számot és a rekordok számát *)
  Beiras(1,9);
  Beiras(2,_rekordDarab);

  (* Elölrõl kezdjük az adatbázis átnézését *)
  BlokkQuery.First;

  while not Blokkquery.eof do
    begin
      for _q := 1 to _aktmezoDb do
        begin
           _aktMezoSS  := xMezoSS[9,_q];
           beiras(1,_aktmezoss);
          _aktMezoNev := xMezok[_aktmezoSS];         // 'BANKJEGY', 'ARFOLYAM', ...
          _aktkod := xMkodok[_aktmezoSS];            // 1 .. 11
          _aktTipus := xTipusok[_aktkod];            // Integer String Float

          if _aktmezonev='DATUM' then
            begin
              _adat := _zarodstring;
            end else
            begin


              case _aktTipus of

                  1: // integer
                       _adat := BlokkQuery.FieldbyName(_aktMezoNev).asInteger;

                  2: // real
                        _adat := BlokkQuery.FieldbyName(_aktMezoNev).asFloat;

                  3: // string
                       _adat := BlokkQuery.FieldbyName(_aktMezoNev).asString;
              end;
            end;
          Beiras(_aktKod,_adat); // a mezõ adatát beirja a csomagba
        end;
       Beiras(1,255);
       (* Következõ rekord *)
       BlokkQuery.Next;

     end;

   (* Kész az adatbázis *)

   BlokkQuery.Close;
   BlokkTranz.commit;
   Blokkdbase.close;
//   Beiras(1,255);
end;


// =================================================================
     procedure TestiZar.Beiras(_kkod: integer; _mertek: variant);
// =================================================================

var _hi,_lo,_betukod,_nulla,_dek: byte;
    _dkod,_tkod,_bnkod,_ikod: string;
    i,_lenmert,_b1r,_b2r,_b3r,_b4r,_maradt,_egesz: integer;

begin
  case _kKod of
    1: begin      // Egyetlen byte felirása
       _dek := _mertek;
       Blockwrite(_iras,_dek,1);
     end;

    2: begin    // Egy word felirása
       _hi := trunc(_mertek/256);
       _lo := _mertek - trunc(256*_hi);

       Blockwrite(_iras,_hi,1);
       Blockwrite(_iras,_lo,1);

     end;

    3: begin  // dátum felirása
        _dKod := TerminalForm.DatumKod(_mertek);
        for i:= 1 to 3 do
          begin
            _betuKod := ord(_dKod[i]);
            Blockwrite(_iras,_betuKod,1);
          end;
      end;

    4: begin    // egy string felirása
         _nulla := 0;
         if _mertek = chr(0) then Blockwrite(_iras,_nulla,1)
         else begin
           _mertek := trim(_mertek);
           _lenMert := length(_mertek);
           _tkod := Form1.TextKod(_mertek);
           blockwrite(_iras,_lenMert,1);
           for i := 1 to _lenMert do
             begin
               _betuKod := ord(_tKod[i]);
               Blockwrite(_iras,_betuKod,1);
             end;
         end;
       end;

    5: begin    // bizonylatszám (CNNNNNN) felirása
         _bnKod := TerminalForm.BnumKod(_mertek);
          for i := 1 to 3 do
            begin
               _betuKod := ord(_bnKod[i]);
               Blockwrite(_iras,_betuKod,1);
            end;
       end;

    6: begin     // valutanem felirása
          _dKod := DnemKod(_mertek);
          for i := 1 to 2 do
            begin
              _betuKod := ord(_dKod[i]);
              Blockwrite(_iras,_betuKod,1);
            end;
       end;

    7: begin      // egy integer felirasa
         _iKod := TerminalForm.IntegKod(_mertek);
         for i := 1 to 5 do
           begin
             _betuKod := ord(_iKod[i]);
             Blockwrite(_iras,_betuKod,1);
           end;
       end;

    8: begin   //egy idõstring felirása
         _iKod := TerminalForm.IdoKod(_mertek);
         for i := 1 to 3 do
           begin
             _betuKod := ord(_iKod[i]);
             Blockwrite(_iras,_betuKod,1);
           end;
       end;

    9: begin    // árfolyam felirása
         if _mertek=0 then _ikod := dupeString(chr(0),5)
           else
           begin
             _mertek := 10000*_mertek;
             _iKod := TerminalForm.IntegKod(_mertek);
           end;

         for i := 1 to 5 do
           begin
             _betuKod := ord(_iKod[i]);
             Blockwrite(_iras,_betuKod,1);
           end;
       end;

   10:  begin    // Egyetlen character felirása
          _tkod := _mertek;
          if _tkod='' then _betukod := 0
          else _betukod := ord(_tkod[1]);
           Blockwrite(_iras,_betukod,1);
        end;

   11:  begin
          if _mertek=0 then _ikod := dupeString(chr(0),5)
           else
             _iKod := TerminalForm.IntegKod(_mertek);


         for i := 1 to 5 do
           begin
             _betuKod := ord(_iKod[i]);
             Blockwrite(_iras,_betuKod,1);
           end;
       end;

    12: // négybyte-os integer (hhi-hlo-hi-lo)
       begin
         _egesz := _mertek;
         _b1r := trunc((_egesz/65536)/256);
         _maradt := _egesz - trunc(_b1r*65536*256);
         _b2r := trunc(_maradt/65536);
         _maradt := _maradt - trunc(_b2r*65536);
         _b3r := trunc(_maradt/256);
         _b4r := _maradt - trunc(_b3r*256);

         _bytetomb[1] := _b1r;
         _bytetomb[2] := _b2r;
         _bytetomb[3] := _b3r;
         _bytetomb[4] := _b4r;
         Blockwrite(_iras,_bytetomb,4);
       end;
   end;
end;


// =================================================================
     procedure TestiZar.ClearOutDir;
// =================================================================

var _fname: string;
    _vanmeg: TSearchRec;
    _ures: integer;

begin
   _URES := findFirst('c:\valuta\out\*.*',faAnyFile,_vanmeg);
   if _URES=0 then
     begin
       repeat
         _fname :=  _vanmeg.Name;
         SysUtils.Deletefile('c:\valuta\out\' + _fname);
       until FindNext(_vanmeg)<>0;
       FindClose(_vanmeg);
     end;
end;



(*
// =======================================================
       function TestiZar.ByteDekod(_bb: byte): byte;
// =======================================================

begin
  result := _bb;

  case _bb of
    181: result := 65;    // Á  65
    144: result := 69;    // É  201
    214: result := 73;    // Í  205
    224: result := 79;    // Ó 211
    153: result := 79;    // Ö  79
    138: result := 79;   // Õ  79
    233: result := 85;   // Ú  85
    154: result := 85;   // Ü  85
    235: result := 85;   // Û  85
    160: result := 97;   // á  97  a
    130: result := 101;   // é  101 e
    161: result := 105;   // í  105 i
    162: result := 111;   // ó  111 o
    148: result := 111;   // ö  111 o
    139: result := 111;   // õ  111 o
    163: result := 117;   // ú  117 u
    129: result := 117;   // ü  117 u
    251: result := 117;
  end;
end;
*)


// =============================================================================
          function TEstizar.IrodaKod(_irodaSzam: word): string;
// =============================================================================

var _szams: string;
    _betu,_plusz,_szor,_tiz,_egy,_b1,_b2,i: integer;
    _kodb: real;
    _ss: array[1..4] of string;

begin
  _szams := rightStr('000'+intToStr(_irodaSzam),4);

  for i := 1 to 4 do
    begin
      _betu := ord(_szams[i])-48;
      _plusz := (i+1);
      _szor := 10 - i;
      _kodb := (_betu + _plusz)*_szor;
      _tiz := trunc(_kodb/10);
      _egy := trunc(_kodb) - (10*_tiz);
      _b1 := 64 + _tiz;
      _b2 := 72 + (2*_egy);
      _ss[i] := chr(_b1) + chr(_b2);
    end;
  result := _ss[3] + _ss[1] + _ss[4] + _ss[2];
end;

// =============================================================================
           function TEstizar.DnemKod(_qdnem: string): string;
// =============================================================================

var _a,_b,_c,_1,_1a,_2: integer;

begin
  result := chr(0)+chr(0);
  if _qdnem='' then exit;
  _a := ord(_qdnem[1]) - 65;
  _b := ord(_qdnem[2]) - 65;
  _c := ord(_qdnem[3]) - 65;
  _1 := 4*_a;
  _1a := trunc(_b/8);
  _1 := _1 + _1a;
  _2 := 32*_b;
  while _2>255 do _2 := _2 - 256;
  _2 := _2 + _c;
  result := chr(_1) + chr(_2)
end;


// =============================================================================
                    procedure TEstizar.MatricaKodolas;
// =============================================================================

begin
   if (_gepfunkcio=1) AND (_kellMatrica=0) then exit;
   if (_gepfunkcio=3) then exit;

    Matricadbase.close;
   if _gepFunkcio=2 then
     begin
       EtarMatcsomag;
       exit;
     end;

   MatricaDbase.DatabaseName := 'c:\valuta\database\trade.gdb';
   MatricaDbase.Connected := true;

   _pcs := 'SELECT * FROM NAPIOSSZESITO' + _sorveg;
   _pcs := _pcs + 'WHERE DATUM='+chr(39) + _zaroDString + chr(39);

   with MatricaQuery do
     begin
       close;
       sql.clear;
       Sql.Add(_pcs);
       Open;
       First;
       _recno := recno;
     end;

   // Ha a napiosszesito tábla üres ezen a napon, akkor semmi sincs;
   if _recno=0 then
     begin
       MatricaQuery.close;
       Matricadbase.close;
       exit;
     end;

   // A zárónapi rekord mezõit beolvassa és zárja a napiosszesito táblát:
   with MatricaQuery do
     begin
       _nyito   := FieldByName('NYITO').asInteger;
       _matrica := FieldByName('MATRICA').asInteger;
       _telefon := FieldByName('TELEFON').asInteger;
       _atadas  := FieldByNAme('ATADAS').AsInteger;
       _atvetel := FieldByName('ATVETEL').asInteger;
       _zaro    := FieldByName('ZARO').AsInteger;
       _zarokeszlet := FieldByName('ZAROKESZLET').asInteger;
     end;
   MatricaQuery.close;
   Matricadbase.close;

   // -------------------- Innentõl indul az új csomag -------------------------

   _rekordDarab := 1;
   _tradetabla := 'TRAD'+midstr(_zarodstring,3,2)+midstr(_zarodstring,6,2);

   _pcs := 'SELECT * FROM '+ _tradetabla + _sorveg;
   _pcs := _pcs + 'WHERE (DATUM='+chr(39) + _zaroDString + chr(39);
   _pcs := _pcs + ') AND (TIPUS=' + chr(39) + 'F' + chr(39) + ')';

   Matricadbase.Connected := True;
   with MatricaQuery do
     begin
       close;
       sql.Clear;
       Sql.Add(_pcs);
       Open;
       first;
       _recno := recno;
     end;

   if _recno>0 then
     begin
       _reKorddarab := 0;
       while not MatricaQuery.Eof do
         begin
           inc(_rekordDarab);
           _ft := MatricaQuery.fieldByNAme('FIZETENDO').asInteger;
           _tp := MatricaQuery.FieldByName('TARSPENZTAR').asString;

           _irany := 45;  // minusz
           if _ft<0 then  // forditott elõjelek !!!!!
             begin
               _irany := 43;  // plusz +
               _ft := abs(_ft);
             end;

           _forint[_rekordDarab] := _ft;
           _addjel[_rekordDarab] := _irany;
           _tarspt[_rekordDarab] := _tp;
           MatricaQuery.Next;
         end;
     end;

   MatricaQuery.close;
   MatricaDbase.close;

   // --------------------------------------------------------------------------
   // A matrica csomagot elkésziti:

   MatPackiro;
end;

// =============================================================================
                       procedure TEstizar.MatPackIro;
// =============================================================================

var _zz,_zOsszeg: integer;
    _zIrany: byte;

begin

 (* Beirja az address számot és a rekordok számát *)

  _tablaSorszam := 10;  // az a matricás tábla sorszáma
  // _rekordDarab := 1;

  Beiras(1,_tablasorszam);
  Beiras(2,_rekordDarab);

  Beiras(1,_targyev-2000);
  Beiras(1,_targyho);
  Beiras(1,_targynap);
  Beiras(12,_nyito);
  Beiras(12,_matrica);
  Beiras(12,_telefon);
  Beiras(12,_atadas);
  Beiras(12,_atvetel);
  Beiras(12,_zaro);
  Beiras(12,_zarokeszlet);

  _zz := 1;
  while _zz<=_rekordDarab do
    begin
      _zPenztar := trim(_tarspt[_zz]);
      _zIrany   := _addjel[_zz];
      _zOsszeg  := _forint[_zz];
      Beiras(4,_zPenztar);
      Beiras(1,_zIrany);
      Beiras(12,_zOsszeg);
      inc(_zz);
    end;
  Beiras(1,255);
end;


// =============================================================================
                       procedure TEstizar.KezdijPackiro;
// =============================================================================

var _tPenztar,_bizonylat: string;
    _kezelesidij,_mozgas: integer;


begin
  _kvFileNev := 'KEZD' + midstr(_zarodstring,3,2)+midstr(_zarodstring,6,2);

  _pcs := 'SELECT * FROM ' + _kvfileNev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM='+ chr(39)+ _zaroDstring +chr(39)+')';
  _pcs := _pcs + ' AND (STORNO=1)';

  Valdatadbase.connected := true;
  with valdataQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;
  _rekorddarab := 0;
  while not ValdataQuery.eof do
    begin
      inc(_rekordDarab);
      ValdataQuery.next;
    end;

  if _rekordDarab=0 then
    begin
      ValdataQuery.close;
      ValdataDbase.close;
      exit;
    end;

  ValdataQuery.First;

 (* Beirja az address számot és a rekordok számát *)

  _tablaSorszam := 14;  // az a kezelési dij tábla sorszáma

  Beiras(1,_tablasorszam);
  Beiras(2,_rekordDarab);

  while not ValdataQuery.eof do
    begin
      with ValdataQuery do
        begin
          _datum         := FieldByName('DATUM').asString;
          _elojel        := FieldByName('ELOJEL').asstring;
          _kezelesidij   := FieldByName('KEZELESIDIJ').asInteger;
          _tpenztar      := FieldBynAme('PENZTAR').asString;
          _mozgas        := FieldByNAme('MOZGAS').asInteger;
          _bizonylat     := FieldByName('BIZONYLAT').asString;
        end;

      Beiras(4,_DATUM);
      Beiras(10,_elojel);
      Beiras(11,_kezelesidij);
      Beiras(4,_tpenztar);
      Beiras(1,_mozgas);
      Beiras(4,_bizonylat);
      Beiras(1,255);
      ValdataQuery.next;
    end;
  ValdataQuery.close;
  ValdataDbase.close;
end;


procedure TEstizar.FoglaloKodolas;

var _valdarab: integer;
    _vMezo,_kMezo: string;

begin
  _pcs := 'SELECT * FROM FOGLALOKESZLET';

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _valdarab := FieldByName('VALDARAB').asInteger;
    end;

  if _valdarab=0 then
    begin
      Valutaquery.close;
      Valutadbase.close;
      exit;
    end;

  _pp := 0;
  while _pp<_valdarab do
    begin
      _vmezo := 'V'+inttostr(_pp);
      _kMezo := 'K'+inttostr(_pp);
      _pval[_pp] := Valutaquery.FieldByName(_Vmezo).asString;
      _pKesz[_pp]:= Valutaquery.FieldByName(_kmezo).asInteger;
      inc(_pp);
    end;
  ValutaQuery.close;
  ValutaDbase.close;

  // -------------------------------------------------------------------    

  _tablasorszam := 16;
  _rekordDarab := 1;

  Beiras(1,_tablasorszam);
  Beiras(2,_rekordDarab);
  Beiras(4,_megnyitottnap);
  Beiras(1,_valdarab);

  _pp := 0;
  while _pp<_valdarab do
    begin
      _aktdnem := _pval[_pp];
      _bankjegy:= _pKesz[_pp];

      Beiras(4,_aktdnem);
      Beiras(11,_bankjegy);

      inc(_pp);
    end;

  Beiras(1,255);
  ValutaQuery.close;
  Valutadbase.close;
end;


procedure TEstizar.XkezdijKodolas;

var _osszesforint,_xkezdij: integer;

begin
  _xkezdFileNev := 'XKEZ' + _farok;
  _pcs := 'SELECT * FROM ' + _xkezdFileNev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM='+ chr(39)+ _zaroDstring +chr(39)+')';

  Valdatadbase.connected := true;
  with valdataQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _rekorddarab := 0;
  while not ValdataQuery.eof do
    begin
      inc(_rekordDarab);
      ValdataQuery.next;
    end;

  if _rekordDarab=0 then
    begin
      ValdataQuery.close;
      ValdataDbase.close;
      exit;
    end;

  ValdataQuery.First;

 (* Beirja az address számot és a rekordok számát *)

  _tablaSorszam := 17;  //  az extrakezdij tábla sorszáma

  Beiras(1,_tablasorszam);
  Beiras(2,_rekordDarab);

  while not ValdataQuery.eof do
    begin
      with ValdataQuery do
        begin
          _datum         := FieldByName('DATUM').asString;
          _bizonylatszam := FieldByName('BIZONYLAT').asstring;
          _osszesforint  := FieldbyName('BIZONYLATFORINT').asInteger;
          _xkezdij       := FieldbyName('EGYEDIKEZDIJ').asInteger;
        end;
      Beiras(4,_datum);
      Beiras(4,_bizonylatszam);
      Beiras(11,_osszesforint);
      Beiras(11,_xkezdij);
      Beiras(1,255);
      ValdataQuery.next;
    end;
  ValdataQuery.close;
  Valdatadbase.close;
end;

// =============================================================================
                       procedure TEstizar.JelenletKodolas;
// =============================================================================

begin
  _jletFileNev := 'JLET' + midstr(_zarodstring,3,2)+midstr(_zarodstring,6,2);

  _pcs := 'SELECT * FROM ' + _jletfileNev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM='+ chr(39)+ _zaroDstring +chr(39)+')';

  Valdatadbase.connected := true;
  with valdataQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _rekorddarab := 0;
  while not ValdataQuery.eof do
    begin
      inc(_rekordDarab);
      ValdataQuery.next;
    end;

  if _rekordDarab=0 then
    begin
      ValdataQuery.close;
      ValdataDbase.close;
      exit;
    end;

  ValdataQuery.First;

 (* Beirja az address számot és a rekordok számát *)

  _tablaSorszam := 15;  //  a jelenléti tábla sorszáma

  Beiras(1,_tablasorszam);
  Beiras(2,_rekordDarab);

  while not ValdataQuery.eof do
    begin
      with ValdataQuery do
        begin
          _datum         := FieldByName('DATUM').asString;
          _penztarosnev  := FieldByName('PENZTAROSNEV').asstring;
          _idkod         := FieldByName('IDKOD').asString;
          _belepes       := FieldBynAme('BELEPES').asString;
          _kilepes       := FieldByNAme('KILEPES').asString;
        end;

      Beiras(4,_DATUM);
      Beiras(4,_penztarosnev);
      Beiras(4,_idkod);
      Beiras(4,_belepes);
      Beiras(4,_kilepes);
      Beiras(1,255);
      ValdataQuery.next;
    end;
  ValdataQuery.close;
  ValdataDbase.close;
end;





// =============================================================================
                      procedure TEstizar.Etarmatcsomag;
// =============================================================================

var _typ: string;

begin

   ValutaDbase.Connected := true;

   _pcs := 'SELECT * FROM NAPIMAT' + _sorveg;
   _pcs := _pcs + 'WHERE DATUM='+chr(39) + _zaroDString + chr(39);

   with ValutaQuery do
     begin
       close;
       sql.clear;
       Sql.Add(_pcs);
       Open;
       First;
       _recno := recno;
     end;

   if _recno=0 then
     begin
       ValutaQuery.close;
       Valutadbase.close;
       exit;
     end;

   WITH vALUTAQUERY DO
     begin
       _atvetel := FieldByName('ATADAS').AsInteger;
       _atadas  := FieldByname('ATVETEL').asInteger;
       _nyito   := FieldByName('NYITO').asInteger;
       _zaro    := FieldByName('ZARO').asInteger;
     end;

   _zarokeszlet := _zaro;
   _matrica     := 0;
   _telefon     := 0;

   ValutaQuery.close;
   Valutadbase.close;

   // ------------------- INNEN A MÓDOSITÁS ------------------------------------

   _rekordDarab := 1;

   _pcs := 'SELECT * FROM MATBIZONYLAT' + _sorveg;
   _pcs := _pcs + 'WHERE (DATUM='+chr(39)+_zarodstring+chr(39)+') AND (STORNO=1)';

   Valutadbase.Connected := true;
   with ValutaQuery do
     begin
       Close;
       sql.Clear;
       Sql.Add(_pcs);
       Open;
       _recno := recno;
     end;

   if _recno>0 then
     begin
       _rekordDarab := 0;
       while not ValutaQuery.Eof do
         begin
           inc(_rekordDarab);
           _ft := ValutaQuery.FieldByNAme('OSSZEG').asInteger;
           _tp := ValutaQuery.FieldByName('TARSPENZTAR').asString;
           _typ:= ValutaQuery.FieldByName('BIZONYLATTIPUS').asstring;

           _tp := trim(_tp);
           _ft := abs(_ft);

           _irany := 45;  // '-' minusz kódja
           if _typ='B' then _irany := 43;  // + plusz-kódja
           _forint[_rekordDarab] := _ft;
           _addjel[_rekorddarab] := _irany;
           _tarspt[_rekorddarab] := _tp;
           ValutaQuery.Next;
         end;
     end;

   ValutaQuery.close;
   Valutadbase.close;

   MatPackiro;
end;


(*
// =============================================================================
                  procedure Testizar.AppendPersonalData;
// =============================================================================

var i: integer;

begin
  // _zaropath, _personalPath

  if FileExists(_targetpath) then deletefile(_targetpath);
  Assignfile(_olvas,_zaropath);
  reset(_olvas);

  Assignfile(_iras,_targetpath);
  rewrite(_iras);

  _filemeret := Filesize(_olvas);
  while _filemeret>1024 do
    begin
      Blockread(_olvas,_bytetomb,1024);
      Blockwrite(_iras,_bytetomb,1024);
      _fileMeret := _fileMeret - 1024;
    end;

  if _fileMeret>0 then
    begin
      Blockread(_olvas,_bytetomb,_fileMeret);
      Blockwrite(_iras,_bytetomb,_fileMeret);
    end;
   CloseFile(_olvas);

  Assignfile(_olvas,_personalpath);
  reset(_olvas);

  _filemeret := Filesize(_olvas);
  while _filemeret>1024 do
    begin
      Blockread(_olvas,_bytetomb,1024);
      Blockwrite(_iras,_bytetomb,1024);
      _fileMeret := _fileMeret - 1024;
    end;

  if _fileMeret>0 then
    begin
      Blockread(_olvas,_bytetomb,_fileMeret);
      Blockwrite(_iras,_bytetomb,_fileMeret);
    end;
  CloseFile(_olvas);

  for i := 1 to 3 do _bytetomb[i] := 255;

  Blockwrite(_iras,_bytetomb,3);
  CloseFile(_iras);

  // ------------------------------------------------

  DeleteFile(_zaropath);

  RenameFile(_targetPath,_zaroPath);
  DeleteFile(_personalPath);
end;
*)


// =============================================================================
                  procedure TEstizar.Ugyfelkodolas;
// =============================================================================

var _sumugyfel,_megbizottszama: integer;
    _fotevekenyseg,_kepviselonev,_thcim,_megbizottbeosztasa: string;
    _kepvisbeo,_telefonszam: string;

begin
  _pcs := 'SELECT * FROM JOGISZEMELY' + _sorveg;
  _pcs := _pcs + 'WHERE FELADVA<>111';
  Valutadbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      Last;
      _jogidarab := recno;
    end;

  _pcs := 'SELECT * FROM UGYFEL' + _sorveg;
  _pcs := _pcs + 'WHERE FELADVA<>111';
  Valutadbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      Last;
      _ugyfeldarab := recno;
    end;


  _sumUgyfel := _ugyfelDarab + _jogidarab;

  if _sumugyfel = 0 then
    begin
      ValutaQuery.close;
      ValutaDbase.close;
      exit;
    end;

  _tablaSorszam := 11;
  if _ugyfeldarab>0 then
    begin
      Beiras(1,_tablaSorszam);
      Beiras(2,_sumugyfel);
      ValutaQuery.First;
      while not ValutaQuery.Eof do
        begin
          with ValutaQuery do
            begin
              _ugyfelszam := FieldByName('UGYFELSZAM').AsInteger;
              _nev := trim(FieldByName('NEV').asString);
              _elozonev := trim(FieldByName('ELOZONEV').asstring);
              _anyjaneve := Trim(FieldByName('ANYJANEVE').asString);
              _leanykori := trim(FieldByNAme('LEANYKORI').AsString);
              _szulhely := trim(FieldByName('SZULETESIHELY').asString);
              _szulido := FieldByNAme('SZULETESIIDO').asstring;
              _allampolgar := TRIM(FieldByName('ALLAMPOLGAR').asstring);
              _lakcim := trim(FieldByName('LAKCIM').AsString);
              _okmanytipus := trim(FieldByName('OKMANYTIPUS').asstring);
              _azonosito := trim(FieldByName('AZONOSITO').asstring);
              _tarthely := trim(FieldByName('TARTOZKODASIHELY').asstring);
              _lcimcard := trim(FieldByName('LAKCIMKARTYA').asstring);
              _telefonszam := trim(FieldByNAme('TELEFONSZAM').asstring);
            end;
          Beiras(10,'N');
          Beiras(11,_ugyfelszam);
          Beiras(4,_nev);
          Beiras(4,_elozonev);
          Beiras(4,_anyjaneve);
          Beiras(4,_leanykori);
          Beiras(4,_szulhely);
          Beiras(4,_szulido);
          Beiras(4,_allampolgar);
          Beiras(4,_lakcim);
          Beiras(4,_okmanytipus);
          Beiras(4,_azonosito);
          Beiras(4,_tarthely);
          Beiras(4,_lcimcard);
          Beiras(4,_telefonszam);
          Beiras(1,255);
          ValutaQuery.Next;
        end;
      valutaQuery.close;
    end;

  if _jogiDarab>0 then
    begin
      if _ugyfeldarab=0 then
        begin
          Beiras(1,_tablaSorszam);
          Beiras(2,_jogidarab);
        end;

      _pcs := 'SELECT * FROM JOGISZEMELY' + _sorveg;
      _pcs := _pcs + 'WHERE FELADVA<>111';
      Valutadbase.Connected := True;
      with ValutaQuery do
        begin
          Close;
          sql.Clear;
          sql.Add(_pcs);
          Open;
        end;

      ValutaQuery.First;

      while not ValutaQuery.eof do
        begin
          with ValutaQuery do
            begin
              _ugyfelszam := FieldByNAme('UGYFELSZAM').asInteger;
              _nev := trim(FieldByNAme('JOGISZEMELYNEV').asString);
              _thcim := trim(FieldByNAme('TELEPHELYCIM').AsString);
              _okiratszam := trim(FieldByNAme('OKIRATSZAM').asstring);
              _fotevekenyseg := trim(FieldByNAme('FOTEVEKENYSEG').AsString);
              _kepviselonev := trim(FieldByName('KEPVISELONEV').AsString);
              _megbizottbeosztasa := trim(FieldByNAme('MEGBIZOTTBEOSZTASA').AsString);
              _kepvisbeo := trim(FieldByNAme('KEPVISBEO').asstring);
              _megbizottszama := FieldByNAme('MEGBIZOTTSZAMA').asInteger;
            end;
          Beiras(10,'J');
          Beiras(11,_ugyfelszam);
          Beiras(4,_nev);
          Beiras(4,_thcim);
          Beiras(4,_okiratszam);
          Beiras(4,_fotevekenyseg);
          Beiras(4,_kepviselonev);
          Beiras(4,_megbizottbeosztasa);
          Beiras(4,_kepvisbeo);
          Beiras(4,inttostr(_megbizottszama));
          Beiras(1,255);
          ValutaQuery.next;
        end;
      Valutaquery.close;
    end;
  Valutadbase.close;

  _pcs := 'UPDATE UGYFEL SET FELADVA=111';
  form1.IbValutaParancs(_pcs);

  _pcs := 'UPDATE JOGISZEMELY SET FELADVA=111';
  fORM1.IbValutaParancs(_pcs);
end;


procedure TEstizar.AdatlapKodolas;

var _sorszam,_osszesforint: integer;
    _prosnev: string;

begin
  _tablaSorszam := 12;
  _pcs := 'SELECT * FROM ADATLAP WHERE FELADVA<>111';
  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _adatlapdarab := recno;
    end;

  if _adatlapdarab=0 then
    begin
      ValutaQuery.close;
      Valutadbase.close;
      exit;
    end;

  Beiras(1,_tablaSorszam);
  Beiras(2,_adatlapdarab);

  Valutaquery.first;
  while not Valutaquery.eof do
    begin
      with ValutaQuery do
        begin
          _ugyfelszam := fieldbyname('UGYFELSZAM').asInteger;
          _nev := trim(FieldByName('UGYFELNEV').asString);
          _gongycsomagszam := FieldByName('GONGYCSOMAGSZAM').asInteger;
          _sorszam := FieldByName('SORSZAM').asInteger;
          _datum := FieldByName('DATUM').asstring;
          _prosnev := trim(Fieldbyname('PENZTAROSNEV').asString);
          _ugyfeltipus := FieldByName('UGYFELTIPUS').asstring;
          _korulmeny := trim(FieldByName('KORULMENY').asstring);
          _egyeb := trim(FieldByName('EGYEB').asstring);
          _osszesforint := FieldByName('OSSZESFORINT').asInteger;
          _storno := FieldByName('STORNO').asInteger;
        end;
      Beiras(11,_ugyfelszam);
      Beiras(4,_nev);
      Beiras(11,_sorszam);
      Beiras(11,_gongycsomagszam);
      Beiras(3,_datum);
      Beiras(4,_prosnev);
      Beiras(4,_ugyfeltipus);
      Beiras(4,_korulmeny);
      Beiras(4,_egyeb);
      Beiras(11,_osszesforint);
      Beiras(1,_storno);
      Beiras(1,255);
      Valutaquery.next;
    end;
  ValutaQuery.close;
  Valutadbase.close;

  _pcs := 'UPDATE ADATLAP SET FELADVA=111';
  Form1.ibvalutaParancs(_pcs);
end;



procedure TEstizar.Gongycsomagkodolas;

var _forintertek: integer;

begin
  _tablaSorszam := 13;
  _pcs := 'SELECT * FROM GONGYCSOMAG WHERE FELADVA<>111';
  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _csomagdarab := recno;
    end;

  if _csomagdarab=0 then
    begin
      ValutaQuery.close;
      Valutadbase.close;
      exit;
    end;

  Beiras(1,_tablaSorszam);
  Beiras(2,_csomagdarab);

  ValutaQuery.First;
  while not ValutaQuery.Eof do
    begin
      with ValutaQuery do
        begin
          _ugyfelszam      := FieldByName('UGYFELSZAM').asInteger;
          _datum           := FieldByName('DATUM').asstring;
          _valutanem       := FieldByName('VALUTANEM').asstring;
          _bankjegy        := FieldByName('BANKJEGY').asInteger;
          _forintertek     := FieldByName('FORINTERTEK').asInteger;
          _gongycsomagszam := FieldByNAme('GONGYCSOMAGSZAM').asInteger;
          _bizonylatszam   := FieldByName('BIZONYLATSZAM').asstring;
        end;

      Beiras(11,_ugyfelszam);
      Beiras(3,_datum);
      Beiras(6,_valutanem);
      Beiras(11,_gongycsomagszam);
      Beiras(11,_bankjegy);
      Beiras(5,_bizonylatszam);
      Beiras(11,_forintertek);
      Beiras(1,255);
      ValutaQuery.Next;
    end;
  ValutaQuery.close;
  Valutadbase.close;

  _pcs := 'UPDATE GONGYCSOMAG SET FELADVA=111';
  fORM1.IbValutaParancs(_PCS);
end;


procedure TESTIZAR.ELOHOGOMBClick(Sender: TObject);
begin
  Naptar.PrevMonth;
  HonapDisplay;
end;

procedure TESTIZAR.KOVHOGOMBClick(Sender: TObject);
begin
  Naptar.NextMonth;
  HonapDisplay;
end;

procedure TEstiZar.HonapDisplay;

begin
  _targyHo    := Naptar.Month;
  _targyev    := Naptar.year;
  _evhos := inttostr(_targyev) + ' ' + _honapnev[_targyho];
  EvhonapPanel.caption := _evhos;
  EvhonapPanel.repaint;

end;


procedure TESTIZAR.NEGSEMZARGOMBClick(Sender: TObject);
begin
  Modalresult := 2;
end;


function TEstiZar.GetKezelesiDIj: integer;

begin
  _pcs := 'SELECT *  FROM NAPIKEZELESIDIJ' + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _zaroDstring + chr(39);

  Valutadbase.connected := true;
  with Valutaquery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      _recno := recno;
    end;
  if _recno>0 then result := ValutaQuery.fieldBynAme('ZARO').asInteger
  else result := 0;
  ValutaQuery.close;
  ValutaDbase.close;
end;

}


end.
