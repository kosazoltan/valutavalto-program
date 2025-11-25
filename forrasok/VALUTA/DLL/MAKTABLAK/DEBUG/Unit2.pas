unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, dateUtils, IBDatabase, DB, IBCustomDataSet, IBTable, IBQuery,
  ExtCtrls;

type
  TForm2 = class(TForm)
    VALDATATABLA: TIBTable;
    VALDATADBASE: TIBDatabase;
    VALDATATRANZ: TIBTransaction;
    VALDATAQUERY: TIBQuery;
    INDITOTIMER: TTimer;

    procedure FormActivate(Sender: TObject);
    function Nulele(_int: integer):string;
    function Tablaexists(_tn: string): boolean;

    procedure SetFileNevek;
    procedure BlokkfejMake;
    procedure BlokktetMake;
    procedure KezdijMake;
    procedure Wunimake;
    procedure WafaMake;
    procedure JletMake;
    procedure NarfMake;
    procedure CimtarMake;
    procedure Tescomake;
    procedure WzaroMake;
    procedure ArfelterMake;
    procedure IbTablaparancs(_ukaz: string);
    procedure INDITOTIMERTimer(Sender: TObject);
    procedure CimletCfgControl;
    procedure XkezMake;
    procedure VipfMake;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _zaroDatum: TDateTime;
  _zaroEv,_zaroHonap: word;
  _farok,_fejfileNev,_tetFileNev,_wuFileNev,_kezdijnev: string;
  _wafileNev,_narfFileNev,_arFilenev,_ctFileNev: string;
  _wzFileNev,_teFilenev,_elofarok,_eloHoZar,_tradenev: string;
  _pcs,_jletfilenev,_xkezfileNev,_vipfFilenev: string;
  _sorveg: string = #13#10;
  _eloev,_eloHo: word;
  _charsor: string = ' CHARACTER SET WIN1250';
  _collate: string = ' COLLATE WIN1250';
  _hcollate: string = ' COLLATE PXW_HUN';
  _vSorveg: string = #44#13#10;


function makeibtablak: integer; stdcall;

implementation


{$R *.dfm}

// =============================================================================
                     function makeibtablak: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.create(Nil);
  Result := Form2.Showmodal;
  Form2.Free;
end;


procedure TForm2.FormActivate(Sender: TObject);
begin
  Form2.Visible := False;
  InditoTimer.enabled := true;
end;



// =============================================================================
        procedure TForm2.INDITOTIMERTimer(Sender: TObject);
// =============================================================================

begin
  InditoTimer.Enabled := False;
  _zaroDatum := Date;
  SetfileNevek;

  BlokkFejMake;
  BlokkTetMake;
  KezdijMake;
  JletMake;
  WuniMake;
  WafaMake;
  NarfMake;
  CimtarMake;
  TescoMake;
  WzaroMake;
  ArfelterMake;
  XkezMake;
  VipfMake;
  CimletCfgControl;
  ModalResult := 1;
end;


// =============================================================================
                          procedure TFORM2.SetFileNevek;
// =============================================================================

begin
  _zaroEv := yearOf(_zaroDatum);
  _zaroHonap := monthof(_zaroDatum);
  _Farok := Nulele(_zaroEv-2000) + Nulele(_zaroHonap);

  _fejFileNev  := 'BF' + _farok;
  _tetFileNev  := 'BT' + _farok;

  _wuFileNev   := 'WUNI' + _farok;
  _waFileNev   := 'WAFA' + _farok;
  _narfFileNev := 'NARF' + _farok;
  _arFileNev   := 'ARFE' + _farok;
  _ctFileNev   := 'CIMT' + _farok;
  _wzFileNev   := 'WZAR' + _farok;
  _teFilenev   := 'TESC' + _farok;
  _tradeNev    := 'TRAD' + _farok;
  _kezdijnev   := 'KEZD' + _farok;
  _jletFileNev := 'JLET' + _farok;
  _xkezFileNev := 'XKEZ' + _farok;
  _vipFFilenev := 'VIPF' + _farok;

  _eloEv := _zaroev;
  _eloHo := _zarohonap;

  dec(_eloHo);

  if _eloHo=0 then
    begin
      _eloHo := 12;
      dec(_eloEv);
    end;

  _eloFarok := Nulele(_eloEv-2000) + NulEle(_eloHo);
  _eloHoZar := 'HZ' + _eloFarok;

  if not TablaExists(_eloHozar) then _eloHozar := 'HZNYITO';
end;

// =============================================================================
                           procedure TFORM2.BlokkfejMake;
// =============================================================================

begin
  if TablaExists(_fejFilenev) then exit;

  _pcs := 'CREATE TABLE ' + _fejfileNev + ' (' + _sorveg;
  _pcs := _pcs + 'BIZONYLATSZAM CHAR(10)'+ _charsor+_collate+_vSorveg;
  _pcs := _pcs + 'TIPUS CHAR (1)'+ _charsor+_vSorveg;
  _pcs := _pcs + 'DATUM CHAR(10)'+ _charsor+_vSorveg;
  _pcs := _pcs + 'IDO CHAR (8)'+_vsorveg;
  _pcs := _pcs + 'NETTO INTEGER' + _vSorveg;
  _pcs := _pcs + 'TRANZDIJ INTEGER' + _vsorveg;
  _pcs := _pcs + 'KEZELESIDIJ INTEGER' + _vSorveg;
  _pcs := _pcs + 'FIZETENDO INTEGER' + _vSorveg;
  _pcs := _pcs + 'FIZETOESZKOZ SMALLINT' + _vSorveg;

  _pcs := _pcs + 'OSSZESFORINTERTEK INTEGER'+_vsorveg;
  _pcs := _pcs + 'UGYFELTIPUS CHAR (1)' +_vsorveg;
  _pcs := _pcs + 'UGYFELSZAM INTEGER' +  _vsorveg;
  _pcs := _pcs + 'UGYFELNEV CHAR (40)'+ _charsor+_Hcollate+_vSorveg;
  _pcs := _pcs + 'TETEL SMALLINT' + _vsorveg;
  _pcs := _pcs + 'IDKOD CHAR (5)' + _vsorveg;
  _pcs := _pcs + 'PENZTAROSNEV CHAR (25)'+_charsor+_Hcollate+_vsorveg;
  _pcs := _pcs + 'TARSPENZTARKOD CHAR (4)' + _vsorveg;
  _pcs := _pcs + 'TRBPENZTAR CHAR (3)' + _vsorveg;
  _pcs := _pcs + 'MEGBIZOSZAM INTEGER'+_vsorveg;
  _pcs := _pcs + 'MEGBIZOTT INTEGER' + _vsorveg;
  _pcs := _pcs + 'PLOMBASZAM CHAR (10)'+_charsor+_collate+_vsorveg;
  _pcs := _pcs + 'SZALLITONEV CHAR (40)'+_charsor+_Hcollate+_vsorveg;
  _pcs := _pcs + 'KONVERZIO SMALLINT' + _vSorveg;
  _PCS := _pcs + 'UGYFELCIM CHAR (40)'+ _charsor+_Hcollate+_vSorveg;
  _pcs := _pcs + 'ADOSZAM CHAR (15)' + _vSorveg;
  _pcs := _pcs + 'STORNO SMALLINT' + _vsorveg;
  _pcs := _pcs + 'STORNOZOTTBIZONYLAT CHAR (10)'+ _vsorveg;
  _pcs := _pcs + 'ZCOUNTS CHAR (4)' + _vSorveg;
  _pcs := _pcs + 'KEREKITES SMALLINT' + _vSorveg;
  _pcs := _pcs + 'RECNUMS CHAR (5)' + _vSorveg;
  _pcs := _pcs + 'FORRAS CHAR (20)' + _charsor+_Hcollate+_vsorveg;
  _pcs := _pcs + 'ENGEDELYEZO CHAR (20)' + _charsor+_Hcollate+_vsorveg;
  _pcs := _pcs + 'STORNOBIZONYLAT CHAR (10))';


  IbTablaParancs(_pcs);

  _pcs := 'CREATE INDEX ' + 'X'+ _fejFileNev + _sorveg;
  _pcs := _pcs + 'ON '+ _fejFileNev + '(DATUM)';
  ibTablaParancs(_pcs);
end;


// =============================================================================
                       procedure TFORM2.BlokktetMake;
// =============================================================================

begin
  if TablaExists(_tetFilenev) then exit;

  _pcs := 'CREATE TABLE ' + _tetfileNev + ' (' +_sorveg ;
  _pcs := _pcs + 'DATUM CHAR(10)'+ _charsor+_vSorveg;
  _pcs := _pcs + 'BIZONYLATSZAM CHAR(10)'+ _charsor+_vSorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3)' + _vsorveg;
  _pcs := _pcs + 'ARFOLYAM DOUBLE PRECISION' + _vsorveg;
  _pcs := _pcs + 'ELSZAMOLASIARFOLYAM DOUBLE PRECISION' + _vsorveg;
  _pcs := _pcs + 'BANKJEGY INTEGER' + _vsorveg;
  _pcs := _pcs + 'FORINTERTEK INTEGER' + _vsorveg;
  _pcs := _pcs + 'ELOJEL CHAR (1)' + _vsorveg;
  _pcs := _pcs + 'COIN SMALLINT'+_vsorveg;
  _pcs := _pcs + 'TORTRESZ CHAR (4)' + _vsorveg;
  _pcs := _pcs + 'STORNO SMALLINT)';
  iBTablaParancs(_pcs);

  _pcs := 'CREATE INDEX ' + 'X'+_tetfileNev + _SORVEG;
  _pcs := _pcs + 'ON ' + _tetFileNev + ' (BIZONYLATSZAM)';
  ibTablaParancs(_pcs);
end;

// =============================================================================
                       procedure TFORM2.KezdijMake;
// =============================================================================

begin
  if TablaExists(_kezdijnev) then exit;

  _pcs := 'CREATE TABLE ' + _kezdijNev + ' (' +_sorveg ;
  _pcs := _pcs + 'DATUM CHAR(10)'+ _charsor+_vSorveg;
  _pcs := _pcs + 'MOZGAS SMALLINT' + _vsorveg;
  _pcs := _pcs + 'BIZONYLAT CHAR (8)' + _charsor + _vsorveg;
  _pcs := _pcs + 'ORIGBIZONYLAT CHAR (8)' + _charsor + _vsorveg;
  _pcs := _pcs + 'ELOJEL CHAR (1)' + _charsor + _vsorveg;
  _pcs := _pcs + 'KEZELESIDIJ INTEGER' + _vsorveg;
  _pcs := _pcs + 'PENZTAR CHAR (4)' + _charsor + _vsorveg;
  _pcs := _pcs + 'PLOMBASZAM CHAR (10)'+ _charsor+_vSorveg;
  _pcs := _pcs + 'SZALLITONEV CHAR (20)'+_charsor+_collate+_vsorveg;
  _pcs := _pcs + 'STORNO SMALLINT)';
  iBTablaParancs(_pcs);

  _pcs := 'CREATE INDEX ' + 'X'+_KEZDIJNev + _SORVEG;
  _pcs := _pcs + 'ON ' + _kezdijNev + ' (BIZONYLAT)';
  ibTablaParancs(_pcs);
end;


// =============================================================================
                       procedure TForm2.JletMake;
// =============================================================================


begin
  if TablaExists(_jletfilenev) then exit;

  _pcs := 'CREATE TABLE ' + _jletFileNev + ' (' + _sorveg;
  _pcs := _pcs + 'PENZTAROSNEV CHAR(25) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'IDKOD CHAR (5) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'BELEPES CHAR (5) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'KILEPES CHAR (5) CHARACTER SET WIN1250 COLLATE WIN1250,';
  _pcs := _pcs + 'PENZTARNEV CHAR(25) CHARACTER SET WIN1250 COLLATE PXW_HUN)';

   ibTablaParancs(_pcs);

  _pcs := 'CREATE INDEX X' + _jletFileNev + _sorveg;
  _pcs := _pcs + 'ON ' + _jletFileNev + ' (DATUM)';
  ibTablaParancs(_pcs);
end;


// =============================================================================
                             procedure TFORM2.wuniMake;
// =============================================================================

begin
  if TablaExists(_wuFilenev) then exit;

  _pcs := 'CREATE TABLE ' + _wufileNev + ' ('+_sorveg;
  _pcs := _pcs + 'FOEGYSEGSZAM SMALLINT'+_Vsorveg;
  _pcs := _pcs + 'PENZTARSZAM INTEGER'+_Vsorveg;
  _pcs := _pcs + 'UGYFELSZAM INTEGER' + _vsorveg;
  _pcs := _pcs + 'SORSZAM CHAR (9)' + _vsorveg;
  _pcs := _pcs + 'DATUM CHAR (11)' + _vsorveg;
  _pcs := _pcs + 'IDO CHAR (8)' + _vsorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3)'+ _vsorveg;
  _pcs := _pcs + 'BANKJEGY INTEGER' + _vsorveg;
  _pcs := _pcs + 'UGYFELTIPUS CHAR (1)'+_vsorveg;
  _pcs := _pcs + 'IDKOD CHAR (5)' + _vsorveg;
  _pcs := _pcs + 'PENZTAROSNEV CHAR (25)'+_charsor+_collate+_vsorveg;
  _pcs := _pcs + 'TRANZAKCIOTIPUS CHAR (2)' + _vsorveg;
  _pcs := _pcs + 'MTCNSZAM CHAR (10)'+ _vsorveg;
  _pcs := _pcs + 'PLOMBASZAM CHAR (10)'+_charsor+_collate+_vsorveg;
  _pcs := _pcs + 'SZALLITONEV CHAR (20)'+_charsor+_collate+_vsorveg;
  _pcs := _pcs + 'STORNO SMALLINT' + _vsorveg;
  _pcs := _pcs + 'STORNOBIZONYLAT CHAR (9)'+ _vsorveg;
  _pcs := _pcs + 'STORNOZOTTBIZONYLAT CHAR (9))';
  ibTablaParancs(_pcs);

  _pcs := 'CREATE INDEX X' + _wufileNev + _sorveg;
  _pcs := _pcs + 'ON ' + _wufileNev + ' (DATUM)';
  ibTablaParancs(_pcs);
end;

// =============================================================================
                          procedure TFORM2.WafaMake;
// =============================================================================

begin
  if TablaExists(_waFilenev) then exit;

  _pcs := 'CREATE TABLE ' + _wafileNev + ' (' + _sorveg;
  _pcs := _pcs + 'FOEGYSEGSZAM SMALLINT'+ _vsorveg;
  _pcs := _pcs + 'PENZTARSZAM INTEGER'+ _vsorveg;
  _pcs := _pcs + 'UGYFELSZAM INTEGER'+ _vsorveg;
  _pcs := _pcs + 'UNIOSAFA INTEGER' + _vSorveg;
  _pcs := _pcs + 'DATUM CHAR (11)' + _vsorveg;
  _pcs := _pcs + 'IDO CHAR(8)' + _vsorveg;
  _pcs := _pcs + 'SORSZAM CHAR (9)'+ _vsorveg;
  _pcs := _pcs + 'SZAMLASZAM CHAR (15)' + _charsor+_collate+_vsorveg;
  _pcs := _pcs + 'BRUTTOOSSZEG INTEGER'+_vsorveg;
  _pcs := _pcs + 'AFAOSSZEG INTEGER' + _vsorveg;
  _pcs := _pcs + 'KEZELESISZAZALEK DOUBLE PRECISION' + _vsorveg;
  _pcs := _pcs + 'UGYKEZELESIDIJ INTEGER'+  _vsorveg;
  _pcs := _pcs + 'KIFIZETETTOSSZEG INTEGER,' + _sorveg;
  _pcs := _pcs + 'ELLATMANYFORINT INTEGER' + _vsorveg;
  _pcs := _pcs + 'TRANZAKCIOTIPUS CHAR (2)'+ _vsorveg;
  _pcs := _pcs + 'STORNO SMALLINT' + _vsorveg;
  _pcs := _pcs + 'STORNOZOTTBIZONYLAT CHAR (9)'+_vsorveg;
  _PCS := _pcs + 'STORNOBIZONYLAT CHAR (9))';
  ibTablaParancs(_pcs);

   _pcs := 'CREATE INDEX X' + _wafileNev + _sorveg;
  _pcs := _pcs + 'ON ' + _wafileNev + ' (DATUM)';
  ibTablaParancs(_pcs);

end;

// =============================================================================
                               procedure TFORM2.NarfMake;
// =============================================================================

begin
  if TablaExists(_narfFilenev) then exit;

  _pcs := 'CREATE TABLE ' + _narffileNev + ' ('+_sorveg;
  _pcs := _pcs + 'DATUM CHAR (11)' + _vsorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3)' + _vSorveg;
  _pcs := _pcs + 'VETELIARFOLYAM DOUBLE PRECISION'+ _vsorveg;
  _pcs := _pcs + 'ELADASIARFOLYAM DOUBLE PRECISION'+ _vsorveg;
  _pcs := _pcs + 'ELSZAMOLASIARFOLYAM DOUBLE PRECISION' + _vsorveg;
  _pcs := _pcs + 'NYITO INTEGER'+_vsorveg;
  _pcs := _pcs + 'ZARO INTEGER)';
  ibTablaParancs(_pcs);

  _pcs := 'CREATE INDEX X' + _narffileNev + _sorveg;
  _pcs := _pcs + 'ON ' + _narffileNev + ' (DATUM)';
  ibTablaParancs(_pcs);
end;

// =============================================================================
                         procedure TFORM2.CimtarMake;
// =============================================================================

begin
  if TablaExists(_ctFilenev) then exit;

  _pcs := 'CREATE TABLE ' + _ctfileNev + ' ('+_sorveg;
  _pcs := _pcs + 'DATUM CHAR (11)' + _vsorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3)' + _vsorveg;
  _pcs := _pcs + 'VALUTANEV CHAR (20)'+_charsor+_collate+_vsorveg;
  _pcs := _pcs + 'OSSZESFORINTERTEK INTEGER' + _vsorveg;
  _pcs := _pcs + 'CIMLET1 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET2 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET3 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET4 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET5 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET6 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET7 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET8 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET9 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET10 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET11 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET12 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET13 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET14 INTEGER)';
  ibTablaParancs(_pcs);

   _pcs := 'CREATE INDEX X' + _ctfileNev + _sorveg;
  _pcs := _pcs + 'ON ' + _ctfileNev + ' (VALUTANEM)';
  ibTablaParancs(_pcs);

end;

// =============================================================================
                        procedure TFORM2.TescoMake;
// =============================================================================

begin
  if TablaExists(_teFilenev) then exit;

  _pcs := 'CREATE TABLE ' + _tefileNev + ' ('+_sorveg;
  _pcs := _pcs + 'DATUM CHAR (11)' + _vsorveg;
  _pcs := _pcs + 'IDO CHAR(8)' + _vsorveg;
  _pcs := _pcs + 'BIZONYLATTIPUS CHAR (1)' + _vsorveg;
  _pcs := _pcs + 'BIZONYLATSZAM CHAR (7)' + _vsorveg;
  _pcs := _pcs + 'WUGYFELSZAM INTEGER' + _vsorveg;
  _pcs := _pcs + 'WUGYFELNEV CHAR (25)'+_charsor+_collate+_vsorveg;
  _pcs := _pcs + 'SZAMLABRUTTO INTEGER'+_vsorveg;
  _pcs := _pcs + 'SZAMLASZAM CHAR (25)'+_charsor+_collate+_vSorveg;
  _pcs := _pcs + 'AFA5SZAZALEKOS INTEGER'+ _vsorveg;
  _pcs := _pcs + 'AFA20SZAZALEKOS INTEGER'+ _vsorveg;
  _pcs := _pcs + 'OSSZESFORINT INTEGER'+ _vsorveg;
  _pcs := _pcs + 'STORNOBIZONYLAT CHAR (9)' + _vsorveg;
  _pcs := _pcs + 'STORNO SMALLINT)';
  ibTablaParancs(_pcs);

  _pcs := 'CREATE INDEX X' + _tefileNev + _sorveg;
  _pcs := _pcs + 'ON ' + _tefileNev + ' (DATUM)';
  ibTablaParancs(_pcs);

end;


// =============================================================================
                                procedure TFORM2.WZaroMake;
// =============================================================================

begin
  if TablaExists(_wzfilenev) then exit;

  _pcs := 'CREATE TABLE ' + _wzfileNev + '(';
  _pcs := _pcs + 'DATUM CHAR (11)' + _vsorveg;
  _pcs := _pcs + 'USDNYITO INTEGER' + _vsorveg;
  _pcs := _pcs + 'HUFNYITO INTEGER' + _vsorveg;
  _pcs := _pcs + 'METRONYITO INTEGER' + _vsorveg;
  _pcs := _pcs + 'TESCONYITO INTEGER' + _vsorveg;

  _pcs := _pcs + 'USDZARO INTEGER'+_vsorveg;
  _pcs := _pcs + 'HUFZARO INTEGER'+_vsorveg;
  _pcs := _pcs + 'METROZARO INTEGER'+_vsorveg;
  _pcs := _pcs + 'TESCOZARO INTEGER'+_vsorveg;

  _pcs := _pcs + 'USDBEVETEL INTEGER'+_vsorveg;
  _pcs := _pcs + 'HUFBEVETEL INTEGER'+_vsorveg;
  _pcs := _pcs + 'METROBEVETEL INTEGER'+_vsorveg;
  _pcs := _pcs + 'TESCOBEVETEL INTEGER'+_vsorveg;

  _pcs := _pcs + 'USDKIADAS INTEGER'+_vsorveg;
  _pcs := _pcs + 'HUFKIADAS INTEGER'+_vsorveg;
  _pcs := _pcs + 'METROKIADAS INTEGER'+_vsorveg;
  _pcs := _pcs + 'TESCOKIADAS INTEGER'+_vsorveg;

  _pcs := _pcs + 'METROVISSZA INTEGER'+_vsorveg;
  _pcs := _pcs + 'TESCOVISSZA INTEGER'+_vsorveg;
  _pcs := _pcs + 'EUSAFAVISSZA INTEGER' + _vSorveg;
  _pcs := _pcs + 'UGYKEZELESIDIJ INTEGER)';
  ibTablaParancs(_pcs);

   _pcs := 'CREATE INDEX X' + _wzfileNev + _sorveg;
  _pcs := _pcs + 'ON ' + _wzfileNev + ' (DATUM)';
  ibTablaParancs(_pcs);

end;


(*
// =============================================================================
                                procedure TFORM2.TradeMake;
// =============================================================================

begin
  if TablaExists(_tradeNev) then exit;

  _pcs := 'CREATE TABLE ' + _tradeNev + '(';
  _pcs := _pcs + 'DATUM CHAR (11)' + _vsorveg;
  _pcs := _pcs + 'NYITO INTEGER' + _vsorveg;
  _pcs := _pcs + 'MATRICA INTEGER' + _vsorveg;
  _pcs := _pcs + 'TELEFON INTEGER' + _vsorveg;
  _pcs := _pcs + 'ATADAS INTEGER' + _vsorveg;
  _pcs := _pcs + 'ATVETEL INTEGER'+_vsorveg;
  _pcs := _pcs + 'ZARO INTEGER'+_vsorveg;
  _pcs := _pcs + 'ZAROKESZLET INTEGER'+_vsorveg;
  _pcs := _pcs + 'PENZTAR INTEGER)';

  ibTablaParancs(_pcs);

   _pcs := 'CREATE UNIQUE INDEX X' + _tradeNev + _sorveg;
  _pcs := _pcs + 'ON ' + _tradeNev + ' (DATUM)';
  ibTablaParancs(_pcs);

end;
*)



// =============================================================================
                        procedure TFORM2.ArfelterMake;
// =============================================================================

begin
  if TablaExists(_arFilenev) then exit;

  _pcs := 'CREATE TABLE ' + _arfileNev + '(';
  _pcs := _pcs + 'DATUM CHAR (11)' + _vsorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3)' + _vsorveg;
  _pcs := _pcs + 'ARFOLYAM DOUBLE PRECISION' + _vsorveg;
  _pcs := _pcs + 'UJARFOLYAM DOUBLE PRECISION' + _vsorveg;
  _pcs := _pcs + 'PENZTAROSNEV CHAR (25)'+_charsor+_collate+_vsorveg;
  _pcs := _pcs + 'BIZONYLATSZAM CHAR (10)' + _vsorveg;
  _pcs := _pcs + 'BANKJEGY INTEGER'+ _vsorveg;
  _pcs := _pcs + 'ELSZAMARFOLYAM DOUBLE PRECISION' + _vsorveg;
  _pcs := _pcs + 'PENZTAROSIMAX DOUBLE PRECISION' + _vSorveg;
  _pcs := _pcs + 'ENGEDMENYTIPUSSZAM INTEGER)';
  ibTablaParancs(_pcs);

   _pcs := 'CREATE INDEX X' + _arfileNev + _sorveg;
  _pcs := _pcs + 'ON ' + _arfileNev + ' (DATUM)';
  ibTablaParancs(_pcs);
end;


procedure Tform2.xkezmake;

begin
  if TablaExists(_xkezFilenev) then exit;

  _pcs := 'CREATE TABLE '+ _xKezFileNev + ' (';
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250' + _vsorveg;
  _pcs := _pcs + 'BIZONYLAT CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250' + _vsorveg;
  _pcs := _pcs + 'BIZONYLATFORINT INTEGER' + _vsorveg;
  _pcs := _pcs + 'EGYEDIKEZDIJ INTEGER' +  _vsorveg;
  _pcs := _pcs + 'TIPUS CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250)';
  ibTablaParancs(_pcs);
end;

procedure Tform2.VipfMake;

begin
  if TablaExists(_vipfFilenev) then exit;

  _pcs := 'CREATE TABLE '+ _vipFFileNev + ' (';
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250' + _vsorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3) CHARACTER SET WIN1250 COLLATE WIN1250' + _vsorveg;
  _pcs := _pcs + 'KARTYASZAM SMALLINT' + _vsorveg;
  _pcs := _pcs + 'BANKJEGY INTEGER)';
  ibTablaParancs(_pcs);
end;



function TForm2.Nulele(_int: integer):string;

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;


function TForm2.TablaExists(_tn: string): boolean;


begin
  ValdataTabla.close;
  ValdataTabla.TableName := _tn;
  Valdatadbase.connected := true;
  result := True;
  if ValdataTabla.Exists then
    begin
      ValdataTabla.Close;
      ValdataDbase.close;
      exit;
    end;
  ValdataTabla.close;
  ValdataDbase.close;
  Result := False;
end;


procedure TForm2.IbTablaparancs(_ukaz: string);

begin
  ValdataDbase.connected := true;
  if ValdataTranz.InTransaction then ValdataTranz.Commit;
  ValdataTranz.StartTransaction;
  with ValdataQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_ukaz);
      ExecSql;
    end;
  ValdataTranz.Commit;
  ValdataDbase.close;
end;      

// =============================================================================
                      procedure TFORM2.CimletCfgControl;
// =============================================================================

var _cimletcfg: string;
    _cfg :textfile;
begin
  _cimletcfg := 'c:\valuta\cimlet.cfg';
  if fileExists(_cimletCfg) then exit;

  AssignFile(_cfg,_cimletcfg);
  Rewrite(_cfg);
  writeLN(_cfg,'AUDFIJKLM');
  writeLN(_cfg,'BGNHIJKLMNO');
  writeLN(_cfg,'CADFIJKLM');
  writeLN(_cfg,'CHFHFGHIJKL');
  writeLN(_cfg,'CZKIDEFGHIJK');
  writeLN(_cfg,'DKKFFGHIJ');
  writeLN(_cfg,'EURJGHIJKLMNO');
  writeLN(_cfg,'GBPEJKLM');
  writeLN(_cfg,'HRKIFGHIJKLM');
  writeLN(_cfg,'HUFMBCDEFGHIJKLM');
  writeLN(_cfg,'ILSEHIJK');
  writeLN(_cfg,'JPYECDEF');
  writeLN(_cfg,'NOKFFGHIJ');
  writeLN(_cfg,'PLNFHIJKL');
  writeLN(_cfg,'RONHGHIJLMO');
  writeLN(_cfg,'RSDIDFGHIJKL');
  writeLN(_cfg,'RUBHDFGIJLM');
  writeLN(_cfg,'SEKFFGIJK');
  writeLN(_cfg,'SKKHDFGHIJK');
  writeLN(_cfg,'UAHHHIJKLMN');
  writeLN(_cfg,'USDHIJKLMNO');
  WriteLn(_cfg,'HUFMBCDEFGHUJKLM');
  CloseFile(_cfg);
  ShowMessage('A CIMLET KONFIGURÁCIÓS ÁLLOMÁNYÁT BEÁLLITOTTAM');
end;

end.

