unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, IBDatabase, DB, IBCustomDataSet,
  IBQuery, IBTable, ComCtrls, Buttons, strutils, Dateutils,printers, jpeg;

type
  TNapzarForm = class(TForm)

    Indito          : TTimer;

    ValutaTabla     : TIBTable;
    ValutaQuery     : TIBQuery;
    ValutaDbase     : TIBDatabase;
    ValutaTranz     : TIBTransaction;

    ValDataTabla    : TIBTable;
    ValDataQuery    : TIBQuery;
    ValDataDbase    : TIBDatabase;
    ValDataTranz    : TIBTransaction;

    Label1          : TLabel;

    DatumPanel      : TPanel;
    EllenorPanel    : TPanel;
    E1              : TPanel;
    E2              : TPanel;
    E3              : TPanel;
    E4              : TPanel;
    E5              : TPanel;
    E6              : TPanel;
    E7              : TPanel;
    E8              : TPanel;
    E9              : TPanel;
    Panel1          : TPanel;
    RendbenPanel    : TPanel;
    V1              : TPanel;
    V2              : TPanel;
    V3              : TPanel;
    V4              : TPanel;
    V5              : TPanel;
    V6              : TPanel;
    V7              : TPanel;
    V8              : TPanel;
    V9              : TPanel;
    ZarasMenetPanel : TPanel;

    Shape1          : TShape;
    Shape2          : TShape;
    Shape3          : TShape;
    Shape4          : TShape;

    Memo1           : TMemo;

    zOkeGomb        : TBitBtn;
    SOURCEQUERY: TIBQuery;
    SOURCEDBASE: TIBDatabase;
    SOURCETRANZ: TIBTransaction;

    procedure CimtarAtmasolas;
    procedure CimtipRogzito(_ctip: byte);
    procedure CopyTables(_sourceName:string;_targetName:string);
    procedure DekZarCtrl(_dd: string);
    procedure ForgalomBeolvasas;
    procedure FormActivate(Sender: TObject);
    procedure HaviGyujtokbeMasolas;
    procedure InditoTimer(Sender: TObject);
    procedure NyitoMeghatarozas;
    procedure NapiForgalomSzamitas;
    procedure NapzarFeltolt;
    procedure NArfolyamFeliras;
    procedure SetGyujtoFileNevek;
//    procedure SetRekordDarab;
    procedure UgyfelNullazo;
    procedure ValutaParancs(_ukaz: string);
    procedure ValdataParancs(_ukaz: string);
    procedure ZaroBeolvasas;
    procedure ZdatumsVtempbe;
    procedure ZOkeGombClick(Sender: TObject);
    procedure UresPenztarControl;

    function MTCNControl:boolean;
    function Napzarcontrol: integer;
    function Nulele(_b: byte): string;
    function Scandnem(_dn: string): byte;
  
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  NAPZARFORM: TNAPZARFORM;

   _ep,_vp: array[1..9] of TPanel;

  _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                                   'CZK','DKK','EUR','GBP','HRK','HUF','ILS',
                                   'JPY','MXN','NOK','NZD','PLN','RON','RSD',
                                   'RUB','SEK','THB','TRY','UAH','USD');

  _dnev: array[1..27] of string = ('Ausztral dollar','Bosnyak marka','Bolgar leva',
         'Brazil real','Kanadai dollar','Svajci frank','Kinai juan','Cseh korona',
         'Dan korona','Euro','Angol font','Horvat kuna','Magyar forint','Izraeli shakel',
         'Japan jen','Mexikoi peso','Norveg korona','Ujzelandi dollar',
         'Lengyel zloty','Roman lei','Szerb dinar','Orosz rubel','Sved korona',
         'Thai bath','Torok lira','Ukran hrivnya','Usa dollar');

  _atadas,
  _atvetel,
  _earf,
  _eladas,
  _elszarf,
  _nyito,
  _varf,
  _vetel,
  _zaro: array[1..27] of integer;

  _cimletsorszam,
  _fizetoeszkoz,
  _gepfunkcio,
  _hufIndex,
  _kellforgalom,
  _kellMatrica,
  _kellMetro,
  _kellTesco,
  _kellWestern,
  _otp,
  _otpopen,
  _xx: byte;

  _height,
  _left,
  _top,
  _width: word;

  _aktBankjegy,
  _aktEarf,
  _aktElszarf,
  _aktNyito,
  _aktVarf,
  _aktZaro,
  _bjVetel,
  _cimletOke,
  _code,
  _ekerekites,
  _errorcode,
  _fejdb,
  _forintertek,
  _hrkoke,
  _hufzaro,
  _kerekites,
  _navoke,
  _tetdb,
  _vKerekites,
  _zFejdb,
  _zTetDb,
  _recno: integer;

  _aktDnem,
  _aktDnev,
  _arFileNev,
  _bizonylatszam,
  _cimFileNev,
  _farok,
  _fejFileNev,
  _jletFileNev,
  _kvFileNev,
  _megnyitottnap,
  _lezartnap,
  _narfFileNev,
  _pcs,
  _tetFileNev,
  _teFileNev,
  _tipus,
  _xKezdFileNev,
  _utbizonylat,
  _vKezdFileNev,
  _waFilenev,
  _wuFilenev,
  _zDatums: string;

  _ujbiz: boolean;

  _sorveg: string = chr(13)+chr(10);

  function checkcontrol(_para: integer): integer; stdcall; external 'c:\valuta\bin\checklst.dll';
  function cimletmenurutin: integer; stdcall; external 'c:\valuta\bin\cimlmenu.dll';
  function cimletctrlrutin: integer; stdcall; external 'c:\valuta\bin\cimlctrl.dll';
  function forgalomdekad: integer; stdcall; external 'c:\valuta\bin\dekad.dll';
  function getellenorrutin: integer; stdcall; external 'c:\valuta\bin\getellen.dll';
  function kezelesidijdekad: integer; stdcall; external 'c:\valuta\bin\kezdek.dll';
  function napijelrutin: integer; stdcall; external 'c:\valuta\bin\napijel.dll';
  function napzarnyomtatorutin: integer; stdcall; external 'c:\valuta\bin\nznyomt.dll';
  function regeneralorutin(_para: integer): integer; stdcall; external 'c:\valuta\bin\regen.dll';
  function qrdisplayrutin: integer; stdcall; external 'c:\valuta\bin\qrgener.dll';
  function navzarocontrol: integer; stdcall; external 'c:\valuta\bin\navzaro.dll';
  function otpterminal: integer; stdcall; external 'c:\valuta\bin\otp.dll';
  function horvatkunazaro: integer; stdcall; external 'c:\valuta\bin\hrkzaro.dll';

function napzarrutin: integer; stdcall;

implementation


{$R *.dfm}

// =============================================================================
                    function napzarrutin: integer; stdcall;
// =============================================================================

begin
  Napzarform := TNapzarform.Create(Nil);
  result := NapzarForm.showmodal;
  napzarform.free;
end;



// =============================================================================
             procedure TNAPZARFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  _width  := screen.Monitors[0].Width;
  _height := Screen.Monitors[0].Height;

  _top    := trunc((_height-768)/2);
  _left   := trunc((_width-1024)/2);

  Top     := _top + 120;
  Left    := _left + 250;

  _ep[1]  := e1;
  _ep[2]  := e2;
  _ep[3]  := e3;
  _ep[4]  := e4;
  _ep[5]  := e5;
  _ep[6]  := e6;
  _ep[7]  := e7;
  _ep[8]  := e8;
  _ep[9]  := e9;

  _vp[1]  := v1;
  _vp[2]  := v2;
  _vp[3]  := v3;
  _vp[4]  := v4;
  _vp[5]  := v5;
  _vp[6]  := v6;
  _vp[7]  := v7;
  _vp[8]  := v8;
  _vp[9]  := v9;

  DatumPanel.Caption := '';
  Indito.Enabled := true;
end;

// =============================================================================
              procedure TNAPZARFORM.INDITOTimer(Sender: TObject);
// =============================================================================

begin
  Indito.Enabled := False;
  Zarasmenetpanel.Visible := False;
  _hufindex := scandnem('HUF');

 // A hardware-ben lévõ napnyitás mutatja, a napot, amit zárni kell:

   _pcs := 'SELECT * FROM HARDWARE';

  ValutaDbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;


      _gepfunkcio   := FieldByNAme('GEPFUNKCIO').asInteger;
      _lezartnap    := trim(FieldByName('LEZARTNAP').asstring);
      _kellforgalom := FieldByNAme('KELLFORGALOM').asInteger;
      _kellwestern  := FieldByName('KELLWESTERN').asInteger;
      _kellMetro    := FieldByName('KELLMETROAFA').asInteger;
      _kelltesco    := FieldByName('KELLTESCOAFA').asInteger;
      _kellmatrica  := FieldByNAme('KELLMATRICA').asInteger;
      _otp          := FieldByName('POSTTERM').asInteger;
      _otpopen      := FieldByName('OTPOPEN').asInteger;
      _megnyitottnap:= trim(FieldByNAme('MEGNYITOTTNAP').asstring);
      Close;

      Sql.Clear;
      Sql.add('SELECT * FROM VTEMP');
      Open;
      _zDatums := trim(FieldbyName('DATUM').asString);
      Close;

    end;
  ValutaDbase.Close;

  // Ha nincs benn dátum, az fatális hiba - nincs zárás !

  if _zDatums='' then
    begin
      ShowMessage('NINCS BELÉPÉSI DÁTUM A HARDWARE-BEN');
      ModalResult := 2;
      exit;
    end;

  if _zDatums>_megnyitottnap then
    begin
      Showmessage('A zárandó nap a jövõben lesz !');
      Modalresult := 2;
      exit;
    end;

  DatumPanel.Caption := _zDatums;
  DatumPanel.Repaint;

  ZdatumsVtempbe;

  // A zárandó nap : zarodatum  - stringesitve = _zDatums
  // Az adatok regenerálása: valuta + western uniun

  regeneralorutin(0);

  // Ellenörzi, hogy lehet-e napot zárni
  //     (MTCN számok,átadólap,cimletezések erc.Self)

  _errorcode := Napzarcontrol;

  {
     errorcode=  0: hibátlan
                 1: hiányos MTCN szám
                 2: esti cimletezés hibás
                 3: kezelési dij cimletezés hibás
                 4: western union cimletezés hibás
                 5: afacimletezés hibás
                 6: foglaló cimletezés hibás
                 7: elektromos kereskedés cimletezés hibás
                 8: axa cimletezés hibás
                 9: moneygram cimletezés hibás
  }


  // 1.  = Hiányos MTCN szám esetén nem lehet zárni

  if (_errorcode=1) then
    begin
      Modalresult := 2;
      exit;
    end;

  // 1-nál nagyobb hiba = Hiányzó vagy rossz címlet:

  if _errorcode>1 then
    begin
      _errorcode := cimletmenurutin;
      IF _errorcode=-1 then
        begin
          Modalresult := 2;
          exit;
        end;

      if _errorcode<>1 then
        begin
          Modalresult := 2;
          exit;
        end;

      Indito.enabled := true;
      Exit;
    end;

  Memo1.clear;


  _hrkOke := horvatkunazaro;
  if _hrkOke=-1 then
    begin
      ModalResult := 2;
      exit;
    end;

  // ------------------ Napzárás a pénztárgépen --------------------------------

   _pcs := 'DELETE FROM QRPARAMS';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO QRPARAMS (NUMBER)' + _sorveg;
  _pcs := _pcs + 'VALUES (3)';
  ValutaParancs(_pcs);

  qrdisplayrutin;

  // ----------------  NAV KONTROL ---------------------------------------------

  _navoke := navzarocontrol;
  if _navoke=-1 then
    begin
      Modalresult := 2;
      exit;
    end;  


  // ----------- Itt minden rendben, indulhat a napzárás -----------------------

  with ZarasmenetPanel do
    begin
      Top     := 88;
      Left    := 16;
      Visible := True;
      Repaint;
    end;

  Memo1.Lines.Add('A NAPI ADATOK BEMÁSOLÁSA A HAVI GYÜJTÖKBE');
  HavigyujtokbeMasolas;

  Memo1.Lines.Add('A NAPI ADATOK MEGHATÁROZÁSA');
  Napiforgalomszamitas;

//  ITT INDUL A NAPZÁRÁS

  Memo1.Lines.Add('A NAPI ÁRFOLYAMTÁBLÁK FELTÖLTÉSE');
  NarfolyamFeliras;

  // Az ügyfelek napi gyüjtölistáinak üritése:
  // A természetes és jogi személyek napi göngyölt forintját nulláza ki:

  Memo1.Lines.add('NAPI JELENTÉS ÖSSZEÁLLÍTÁSA');
  napijelrutin;

  Memo1.Lines.add('ADATOK BEIRÁSA A DEKÁDJELENTÉSBE');

  DekzarCtrl(_zDatums);

  ZDatumsVtempbe;
  napzarnyomtatorutin;

  // A zárás ezennel készre vehetõ, igy a Napzárás mezõ kitölthetõ:

  Memo1.Lines.Add('A NAPI ZÁRÁS VÉGREHAJTÁSÁNAK NYUGTÁZÁSA');
  _pcs := 'UPDATE HARDWARE SET LEZARTNAP='+chr(39)+_zDatums+chr(39);
  ValutaParancs(_pcs);

  UresPenztarControl;

  Zokegomb.Visible := True;
  ZokeGomb.Enabled := true;
  ActiveControl := Zokegomb;

end;


procedure TNapZarForm.UresPenztarControl;

begin
  _pcs := 'SELECT * FROM ARFOLYAM' + _sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39)+'HUF'+chr(39);

  with ValutaQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _hufzaro := FieldByNAme('ZARO').asInteger;
      Close;
    end;
  ValutaDbase.close;

  if _hufzaro<>0 then exit;

  _pcs := 'DELETE FROM ' + _CIMFILENEV + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + _zDatums + chr(39);
  ValdataParancs(_pcs);

  _pcs := 'INSERT INTO ' + _cimfilenev + ' (DATUM,VALUTANEM,OSSZESFORINTERTEK)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + CHR(39) + _zDatums + chr(39) + ',';
  _pcs := _pcs + chr(39) + 'HUF' + chr(39) + ',';
  _pcs := _pcs + '0)';
  ValDataParancs(_pcs);
end;


// =============================================================================
                     function TNAPZARFORM.NapzarControl: integer;
// =============================================================================

VAR I: INTEGER;

begin
  // Az ellemörzést-követõ panel alapra aállitása:

  for i := 1 to 11 do
    begin
      _ep[i].font.color := clGray;
      _vp[i].caption := '';
    end;

  with EllenorPanel do
    begin
      Top  := 88;
      Left := 32;
      Visible := true;
    end;

  // Ha minden rendben van - akkor 0 a visszatérés
  Result := 0;

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  //      Ha van Western Union,  nézi, hogy magvan-e az összes MTCN szám:

   e1.font.color := clBlack;
  if (_kellWestern=1) then
    begin
      if not MTCNControl then
        begin
          v1.caption := 'hiányos';
          ShowMessage('KITÖLTETLEN MTCN SZÁM VAN EGY WESTERN-UNION BIZONYLATBAN');
          Result := 2;  // errorcode=2 -> mtcn szám hiányos
          Exit;
        end;
      v1.caption := 'rendben';
    end else v1.caption := 'nem kell';

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  //                      Esti zárás cimletek ellenõrzése:

  e2.font.color := clBlack;
  _cimletsorszam := 1;
  CimtipRogzito(_cimletsorszam);
  _CimletOke := cimletctrlrutin;

  if _cimletOke=2 then
    begin
      v2.caption := 'nem egyezik';
      ShowMessage('HIÁNYZIK VAGY ELTÉR AZ ESTI PÉNZTÁR CIMLETEZÉSE');
      Result := 4; // errorcode-4 -> HIBÁS ESTI CIMLETEZÉS
      Exit;
    end;

  // Ha a címlet jó - bemásolja a havi CIMTÁR-ba

  CimtarAtmasolas;
  v2.caption := 'rendben';

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  //          A kezelési díj cimleteinek ellenörzése:

  e3.font.color := clBlack;
  _cimletsorszam := 2;
  CimtipRogzito(_cimletsorszam);
  _CimletOke := cimletctrlrutin;
  if _CimletOke=2 then
    begin
      v3.caption := 'nem egyezik';
      ShowMessage('Nincs, vagy nem egyezik a kezelési díj címletezése');
      result := 5;  // errorcode = 5 -> hibás kezelési díj zárása
      exit;
    end;
  v3.caption := 'rendben';

 // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 //      Ha van Western, akkor annak címletezését kell vizsgálni:

  e4.font.color := clBlack;
  if (_kellWestern=1) then
    begin
      _cimletSorszam := 3;
      CimtipRogzito(_cimletsorszam);
      _cimletoke := cimletctrlrutin;

      if _cimletOke=2 then
        begin
          v4.caption := 'nem egyezik';
          ShowMessage('Nincs, vagy nemegyezik a  Western Union cimletezés ');
          cimletmenurutin;
          Result := 6;  // errorcode=6 -> hibás wu. cimletezés
          Exit;
        end;
      v4.caption := 'rendben';
    end else v4.caption := 'nem kell';

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  //          Ha van AFA, akkor annak cimletezeset is vizsgálni kell:

   e5.font.color := clBlack;
   if (_kelltesco=1) or (_kellmetro=1) then
    begin
      _cimletsorszam := 4;
      CimtipRogzito(_cimletsorszam);
      _cimletoke := cimletctrlrutin;

      if _cimletOke=2 then
        begin
          v5.caption := 'nem egyezik';
          ShowMessage('Az ÁFA-pénztár nincs cimletezve');
          Result := 7;  // errorcode=7 -> áfa cimletezés rossz
          Exit;
        end;
      v5.caption := 'rendben';
    end else v5.caption := 'nem kell';

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  //             A foglaló cimletezést is vizsgálni kell:

    e6.font.color := clBlack;
   _cimletsorszam := 5;
   CimtipRogzito(_cimletsorszam);
   _cimletoke := cimletctrlrutin;

   if _cimletOke=2 then
     begin
       v6.caption := 'nem egyezik';
       ShowMessage('A foglalókészlet nincs cimletezve');
       Result := 8;  // errorcode=7 -> áfa cimletezés rossz
       exit;
     end;
   if _cimletoke=1 then v6.caption := 'rendben' else v6.Caption := 'nincs';
   v6.repaint;

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  //                  Az e-kereskedelem cimletezés vizsgálata

   e7.Font.Color := clBlack;
   if (_kellmatrica=1) or (_gepfunkcio=2) then
     begin
       _cimletsorszam := 6;
       CimtipRogzito(_cimletsorszam);
       _cimletoke := cimletctrlrutin;

      if _cimletOke=2 then
        begin
          v7.caption := 'nem egyezik';
          ShowMessage('Az e-kereskedelem nincs cimletezve');
          Result := 9;  // errorcode=9 -> e-trade cimletezés rossz
          Exit;
        end;
      v7.caption := 'rendben';
    end else v7.caption := 'nem kell';


   {
  // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  //                 Az Axa-biztositó címleteinek vizsgálata:

   e8.Font.Color := clBlack;
   if _kellaxa=1 then
     begin
       _cimletsorszam := 8;
       CimtipRogzito(_cimletsorszam);
       _cimletoke := cimletctrlrutin;

      if _cimletOke=2 then
        begin
          v8.caption := 'nem egyezik';
          ShowMessage('Az axa-bizotsitó nincs cimletezve');
          Result := 10;  // errorcode=10 -> axa cimletezés rossz
          Exit;
        end;
      v8.caption := 'rendben';
    end else v8.caption := 'nem kell';

   // ===========================================================================
  //              A moneygrtam címleteinek vizsgálata:
  // ===========================================================================

   e9.Font.Color := clBlack;
   if _kellmoneygram=1 then
     begin
       _cimletsorszam := 9;
       CimtipRogzito(_cimletsorszam);
       _cimletoke := cimletctrlrutin;

      if _cimletOke=2 then
        begin
          v9.caption := 'nem egyezik';
          ShowMessage('A moneygram nincs cimletezve');
          Result := 11;  // errorcode=10 -> moneygram cimletezés rossz
          Exit;
        end;
      v9.caption := 'rendben';
    end else v9.caption := 'nem kell';

    }

  // ===========================================================================

   EllenorPanel.repaint;

   RendbenPanel.visible := True;
   RendbenPanel.Repaint;
   sleep(2000);
   EllenorPanel.visible := False;
end;


// =============================================================================
                procedure TNAPZARFORM.HavigyujtokbeMasolas;
// =============================================================================

begin
  SetGyujtoFileNevek;

  {
  if _lezartnap=_megnyitottnap then
    begin
      SetRekordDarab;
      if _fejDb>_zFejDb then
        begin
          _pcs := 'DELETE FROM ' + _fejFileNev + ' WHERE DATUM='+chr(39)+_megnyitottnap+chr(39);
          ValdataParancs(_pcs);
        end;

      if _tetDb>_zTetDb then
        begin
          _pcs := 'DELETE FROM ' + _tetFileNev + ' WHERE DATUM='+chr(39)+_megnyitottnap+chr(39);
          ValdataParancs(_pcs);
        end;
    end;
  }

  CopyTables('BLOKKFEJ',_fejFileNev);
  CopyTables('BLOKKTETEL',_tetFileNev);

  if (_kellMetro=1) then CopyTables('METROAFAMOZGAS',_waFileNev);
  if (_kellWestern=1) then CopyTables('WUMOZGAS',_wuFileNev);
  if (_kellTesco=1) then CopyTables('TESCO',_teFileNev);

  CopyTables('JELENLET',_jletFileNev);
  CopyTables('ARFOLYAMELTERITES',_arFileNev);
  CopyTables('KEZELESIDIJ',_kvFileNev);
  CopyTables('EGYENIKEZDIJ',_xKezdFilenev);
end;

// =============================================================================
              procedure TNAPZARFORM.SetGyujtoFileNevek;
// =============================================================================

begin
  _Farok       := midstr(_zDatums,3,2)+midstr(_zDatums,6,2);

  _fejFileNev  := 'BF' + _farok;
  _tetFileNev  := 'BT' + _farok;
  _cimFileNev  := 'CIMT' + _farok;

  _wuFileNev   := 'WUNI' + _farok;
  _waFileNev   := 'WAFA' + _farok;
  _narfFileNev := 'NARF' + _farok;
  _arFileNev   := 'ARFE' + _farok;

  _teFilenev   := 'TESC' + _farok;
  _kvFilenev   := 'KEZD' + _farok;
  _jletFilenev := 'JLET' + _farok;
  _xkezdFilenev:= 'XKEZ' + _farok;
end;

// =============================================================================
      procedure TNAPZARFORM.CopyTables(_sourceName:string;_targetName:string);
// =============================================================================

var _mezonevek,_mezotipus: array of string;
    _mezolen: array of byte;
    _mezodarab,_cc,_y: word;

    _mNev,_mTipus,_mPcs,_dPcs,_aktmezotip,_aktstring,_aktmezonev: string;
    _aktinteger: integer;
    _mHossz: byte;
    _aktreal: real;

begin
  Valutadbase.Connected := True;
  with ValutaTabla do
    begin
      Close;
      TableName := _sourceName;
      Open;
      Refresh;
      First;
      _recno := recno;
    end;

  // Ha üres a forrástábla - nincs mit átmuvolni !
  if _recno = 0 then
    begin
      ValutaTabla.Close;
      ValutaDbase.Close;
      Exit;
    end;

  _mezoDarab := ValutaTabla.FieldCount;

  SetLength(_mezonevek,_mezoDarab);
  Setlength(_mezotipus,_mezoDarab);
  Setlength(_mezolen,_mezodarab);

  // A forrástábla VALUTA.FDB-böl olvas

  _pcs := 'SELECT r.RDB$FIELD_NAME AS FIELD_NAME,' + _sorveg;
  _pcs := _pcs + 'f.RDB$FIELD_LENGTH AS FIELD_LENGTH,' + _sorveg;
  _pcs := _pcs + 'case f.RDB$Field_type' + _sorveg;

  _pcs := _pcs + 'WHEN 14 THEN ' + chr(39)+ 'CHAR' + chr(39) + _sorveg;
  _pcs := _pcs + 'WHEN 27 THEN ' + chr(39)+ 'DOUBLE PRECISION' + chr(39) + _sorveg;
  _pcs := _pcs + 'WHEN 8 THEN ' + chr(39) + 'INTEGER' + chr(39) + _sorveg;
  _pcs := _pcs + 'WHEN 7 THEN ' + chr(39) + 'SMALLINT' + chr(39) + _sorveg;
  _pcs := _pcs + 'ELSE ' + chr(39) + 'UNKNOWN' + chr(39) + _sorveg;
  _pcs := _pcs + 'END AS FIELD_TYPE,' + _sorveg;

  _pcs := _pcs + 'f.RDB$FIELD_SUB_TYPE AS FIELD_SUBTYPE,' + _sorveg;
  _pcs := _pcs + 'coll.RDB$COLLATION_NAME AS FIELD_COLLATION,' +_sorveg;
  _pcs := _pcs + 'cset.RDB$CHARACTER_SET_NAME AS FIELD_CHARSET' +_sorveg;
  _pcs := _pcs + 'FROM RDB$RELATION_FIELDS r' +_sorveg;
  _pcs := _pcs + 'LEFT JOIN RDB$FIELDS f ON r.RDB$FIELD_SOURCE=F.RDB$FIELD_NAME' + _sorVeg;
  _pcs := _pcs + 'LEFT JOIN RDB$COLLATIONS COLL on r.RDB$COLLATION_ID=COLL.RDB$COLLATION_ID' + _sorVeg;
  _pcs := _pcs + 'AND f.RDB$CHARACTER_SET_ID = coll.RDB$CHARACTER_SET_ID' + _sorveg;
  _pcs := _pcs + 'LEFT JOIN RDB$CHARACTER_SETS CSET ON f.RDB$CHARACTER_SET_ID=cset.RDB$CHARACTER_SET_ID' + _sorVeg;
  _pcs := _pcs + 'WHERE r.RDB$RELATION_NAME='+chr(39) + _sourceName + chr(39) + _sorVeg;
  _pcs := _pcs + 'ORDER BY r.RDB$FIELD_POSITION' + _sorVeg;

  ValutaDbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  // A struktura adatok tömbökbe másolása a QUERYTÁBLÁBÓL:

  _cc := 0;
  while not ValutaQuery.Eof do
    begin
      with ValutaQuery do
        begin
          _mNev   := trim(FieldByName('FIELD_NAME').AsString);
          _mTipus := trim(FieldByName('FIELD_TYPE').AsString);
          _mHossz := FieldByName('FIELD_LENGTH').asinteger;
        end;

      _mezonevek[_cc] := _mNev;
      _mezotipus[_cc] := _mTipus;
      _mezolen[_cc]   := _mHossz;
      inc(_cc);

      ValutaQuery.next;
    end;

  ValutaQuery.close;
  ValutaDbase.close;

  _mPcs := 'INSERT INTO ' + _targetName + ' (';

  _y := 0;
  while _y<_MezoDarab do
    begin
      _aktmezonev := _mezonevek[_y];

      _mPcs := _mPcs + _aktmezonev;
      inc(_y);
      if _y<_mezodarab then _mPcs := _mPcs + ','
    end;
  _mpcs := _mpcs + ')'+_sorveg;

  // $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
  // ===========================================================================

  _pcs := 'SELECT * FROM ' + _sourcename;
  SourceDbase.Connected := True;
  with SourceQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not SourceQuery.Eof do
    begin
      _dPcs := 'VALUES (';
      _y := 0;
      while _y<_mezodarab do
        begin
          _aktmezonev := _mezonevek[_y];
          _aktmezotip := _mezoTipus[_y];
          if (_aktmezotip='INTEGER') or (_aktmezotip='SMALLINT') then
            begin
              _aktInteger := SourceQuery.FieldByName(_aktmezonev).asInteger;
              _dpcs := _dpcs + inttostr(_aktinteger);
            end;

          if _aktmezoTip='DOUBLE PRECISION' then
            begin
              _aktreal := SourceQuery.FieldByName(_aktmezonev).asFloat;
              _dpcs := _dpcs + floattostr(_aktreal);
            end;

          if _aktmezotip='CHAR' then
            begin
              _aktstring := trim(SourceQuery.FieldByName(_aktmezonev).asString);
              _dpcs := _dpcs + chr(39) + _aktstring + chr(39);
            end;
          inc(_y);
          if _y<_mezodarab then _dpcs := _dpcs + ','
          else break;
        end;
      _dpcs := _dpcs + ')';

      _pcs := _mPcs + _dPcs;

      ValdataParancs(_pcs);
      SourceQuery.next;
    end;

  SourceQuery.close;
  SourceDbase.close;

  // -------------------------------------------------

  _pcs := 'DELETE FROM ' + _sourceName;
  ValutaParancs(_pcs);
end;


// =============================================================================
                       procedure TNAPZARFORM.NapzarFeltolt;
// =============================================================================

{
  Az árfolyam táblából bemásolja VALUTANEM,VALUTANÉV,ZÁRÓ adatokat
  a NAPIZAR táblába:

}

var _valdb: byte;

begin

  ValutaDbase.Close;
  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add('SELECT * FROM ARFOLYAM ORDER BY VALUTANEM');
      Open;
      First;
    end;

  _valdb := 0;
  while not ValutaQuery.Eof do
    begin
      with ValutaQuery do
        begin
          _aktdnem := FieldByNAme('VALUTANEM').asString;
          _aktdnev := FieldByNAme('VALUTANEV').asstring;
          _aktvarf := FieldbyName('VETELIARFOLYAM').asInteger;
          _aktearf := FieldByName('ELADASIARFOYLAM').AsInteger;
          _aktelszarf := FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
          _aktzaro    := FieldByName('ZARO').AsInteger;
        end;

      inc(_valdb);

      _dnem[_valdb] := _aktdnem;
      _dnev[_valdb] := _aktdnev;
      _varf[_valdb] := _aktvarf;
      _earf[_valdb] := _aktearf;
      _elszarf[_valdb] := _aktelszarf;
      _zaro[_valdb] := _aktzaro;

      ValutaQuery.next;
    end;
  ValutaQuery.close;
  ValdataQuery.Close;
end;


// =============================================================================
                     procedure TNAPZARFORM.NarfolyamFeliras;
// =============================================================================

var _y: byte;

begin
  _pcs := 'DELETE FROM ' + _narffileNev + ' WHERE DATUM='+chr(39)+_zDatums+chr(39);
  ValdataParancs(_pcs);

  _y := 1;
  while _y<=27 do
    begin
      _aktdnem  := _dnem[_y];
      _aktnyito := _nyito[_y];
      _aktzaro  := _zaro[_y];
      _aktvarf  := _varf[_y];
      _aktearf  := _earf[_y];
      _aktelszarf := _elszarf[_y];
      _aktzaro  := _zaro[_y];

      _pcs := 'INSERT INTO '+ _narffileNev + ' (DATUM,VALUTANEM,VETELIARFOLYAM,';
      _pcs := _pcs + 'ELADASIARFOLYAM,ELSZAMOLASIARFOLYAM,NYITO,ZARO)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _zDatums + chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + inttostr(_aktvarf) + ',';
      _pcs := _pcs + inttostr(_aktearf) + ',';
      _pcs := _pcs + inttostr(_aktelszarf) + ',';
      _pcs := _pcs + inttostr(_aktnyito) + ',';
      _pcs := _pcs + inttostr(_aktzaro) + ')';
      ValdataParancs(_pcs);
      inc(_y);
    end;
end;

// =============================================================================
                       procedure TNAPZARFORM.UgyfelNullazo;
// =============================================================================


begin
  _pcs := 'UPDATE UGYFEL SET NAPIGONGYOLTFORINT=0';
  ValutaParancs(_pcs);

  _pcs := 'UPDATE JOGISZEMELY SET NAPIGONGYOLTFORINT=0';
  ValutaParancs(_pcs);
end;

// =============================================================================
                  function TNAPZARFORM.MTCNControl:boolean;
// =============================================================================

var _mtcn,_uTipus,_datum: string;
    _stornojel: byte;

begin
  Result := True;

  ValutaDbase.Connected := True;
  IF ValutaTranz.InTransaction then ValutaTranz.Commit;

  _pcs := 'SELECT * FROM WUMOZGAS';
  with ValutaQuery do
    begin
      CLose;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  while not ValutaQuery.eof do
    begin
      with ValutaQuery do
        begin
          _stornoJel := FieldByName('Storno').asInteger;
          _utipus    := FieldByName('UGYFELTIPUS').asString;
          _datum     := FieldByName('DATUM').asString;
          _mtcn      := FieldByName('MTCNSZAM').asstring;
        end;

      _datum := leftstr(_datum,10);
      if (_stornojel>1) or (_utipus<>'U')  then
        begin
          ValutaQuery.next;
          continue;
        end;

      _mtcn := trim(_mtcn);
      if length(_mtcn)=0 then
         begin
           result := False;
           Break;
         end;
      ValutaQuery.Next;
    end;
  ValutaQuery.Close;
  ValutaDbase.close;
end;

// =============================================================================
               procedure TNAPZARFORM.ZOKEGOMBClick(Sender: TObject);
// =============================================================================

var _otpoke: integer;

begin
  if _otp=1 then
    begin
      if _otpopen=1 then
        begin

          _pcs := 'DELETE FROM VTEMP';
          ValutaParancs(_pcs);

          _pcs := 'INSERT INTO VTEMP (OTPFUNCTYPE)';
          _PCS := _pcs + 'VALUES (51)';


          ValutaParancs(_pcs);
          _otpoke := otpterminal;

          if _otpoke=1 then
            begin
              _pcs := 'UPDATE HARDWARE SET OTPOPEN=0';
              ValutaParancs(_pcs);
            end;
        end;
    end;

  Modalresult := 1;
end;

// =============================================================================
                    procedure TNAPZARFORM.CimtarAtmasolas;
// =============================================================================

var i: integer;
    _cmt: array[1..14] of word;
    _pp: byte;
    _cimtablanev,_mezo: string;

begin
  _farok := midstr(_megnyitottnap,3,2)+midstr(_megnyitottnap,6,2);
  _cimtablanev := 'CIMT' + _farok;

  _pcs := 'DELETE FROM '+ _cimTablaNev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _zDatums + chr(39);
  ValdataParancs(_pcs);

  ValutaDbase.Connected := true;
  _pcs := 'SELECT * FROM CIMINI'+_SORVEG;
  _pcs := _pcs + 'WHERE (CIMLETTYPE=1) AND (AKTKESZLET>0)' + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  while not ValutaQuery.eof do
    begin
      with ValutaQuery do
        begin
          _aktdnem     := FieldByName('VALUTANEM').asString;
          _aktdnev     := FieldByName('VALUTANEV').asstring;
          _aktbankjegy := FieldByname('AKTKESZLET').asInteger;

          for i := 1 to 14 do
            begin
              _mezo := 'CIMLET'+inttostr(i);
              _cmt[i] := Fieldbyname(_mezo).asInteger;
            end;
        end;

      _pcs := 'INSERT INTO ' + _cimTablaNev + ' (DATUM,VALUTANEM,VALUTANEV,';
      _pcs := _pcs + 'OSSZESFORINTERTEK,';
      _pp := 1;

      while _pp<14 do
        begin
          _pcs := _pcs + 'CIMLET'+inttostr(_pp)+',';
          inc(_pp);
        end;

      _pcs := _pcs + 'CIMLET14)'+_sorveg;
      _pcs := _pcs + 'VALUES (' +chr(39) + _zDatums  + chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktdnev + chr(39) + ',';
      _pcs := _pcs + inttostr(_aktbankjegy) + ',';
      _pp := 1;

      while _pp<14 do
        begin
          _pcs := _pcs + inttostr(_cmt[_pp])+',';
          inc(_pp);
        end;

      _pcs := _pcs + inttostr(_cmt[14])+')';
      ValdataParancs(_pcs);

      Valutaquery.next;
    end;
  ValutaQuery.close;
  ValutaDbase.close;
end;

// =============================================================================
               procedure TNAPZARFORM.dekZarCtrl(_dd: string);
// =============================================================================

var _cev,_cho,_cnap,_utnap: word;

begin
  _cnap  := strtoint(midstr(_dd,9,2));
  _cev   := strtoint(leftstr(_dd,4));
  _cho   := strtoint(midstr(_dd,6,2));
  _utnap := daysinamonth(_cev,_cho);

  if (_cnap<>10) and (_cnap<>20) and (_cnap<>_utnap) then exit;

  if _gepfunkcio=1 then
    begin
      forgalomdekad;
      kezelesidijdekad;
    end;
end;

// =============================================================================
                 procedure TNAPZARFORM.CimtipRogzito(_ctip: byte);
// =============================================================================

begin
  _pcs := 'UPDATE HARDWARE SET MENETSZAM=' + inttostr(_ctip);
  ValutaParancs(_pcs);
end;

// =============================================================================
           procedure TNAPZARFORM.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  ValutaDbase.connected := True;
  if Valutatranz.InTransaction then valutaTranz.Commit;
  ValutaTranz.StartTransaction;
  with VALUTAQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  ValutaTranz.commit;
  Valutadbase.close;
end;

// =============================================================================
             procedure TNAPZARFORM.ValdataParancs(_ukaz: string);
// =============================================================================

begin
  ValdataDbase.connected := True;
  if Valdatatranz.InTransaction then ValdataTranz.Commit;
  ValdataTranz.StartTransaction;
  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  ValdataTranz.commit;
  Valdatadbase.close;
end;


// =============================================================================
              function TNAPZARFORM.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


// =============================================================================
                     procedure TNapZarForm.NapiForgalomSzamitas;
// =============================================================================

var _y: byte;

begin
  NyitoMeghatarozas;
  ForgalomBeolvasas;
  ZaroBeolvasas;

  _y := 1;
  while _y<=27 do
    begin
      _nyito[_y] := _nyito[_y] + _vetel[_y] + _atvetel[_y] - _eladas[_y] - _atadas[_y];
      inc(_y);
    end;
  _nyito[_hufindex] := _nyito[_hufindex] - _bjVetel;

end;


// =============================================================================
                    procedure TNapzarForm.Zarobeolvasas;
// =============================================================================

var i: byte;

begin
  for i := 1 to 27 do
    begin
      _varf[i] := 0;
      _earf[i] := 0;
      _elszarf[i] := 0;
      _zaro[i] := 0;
    end;

  ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM ARFOLYAM');
      Open;
      First;
    end;

  while not ValutaQuery.eof do
    begin
      _aktdnem := ValutaQuery.FieldbyName('VALUTANEM').asString;
      _aktvarf := Valutaquery.FieldbyName('VETELIARFOLYAM').asInteger;
      _aktearf := ValutaQuery.FieldbyName('ELADASIARFOLYAM').asInteger;
      _aktelszarf := ValutaQuery.FieldbyName('ELSZAMOLASIARFOLYAM').asInteger;
      _aktzaro := ValutaQuery.FieldByNAme('ZARO').asInteger;

      _xx := scanDnem(_aktdnem);
      IF _XX>0 then
        begin
          _varf[_xx] := _aktvarf;
          _earf[_xx] := _aktearf;
          _elszarf[_xx] := _aktelszarf;
          _zaro[_xx] := _aktzaro;
        end;  
      ValutaQuery.next;
    end;
  ValutaQuery.close;
  Valutadbase.close;
end;


// =============================================================================
                  procedure TNapzarForm.NyitoMeghatarozas;
// =============================================================================

var i: byte;
    _zevs,_zHos,_elofarok,_hzTablanev: string;
    _zev,_zHo,_eloev,_eloho: word;

begin
  for i := 1 to 27 do _nyito[i] := 0;

  _zEvs := leftstr(_zDatums,4);
  _zHos := midstr(_zDatums,6,2);

  val(_zevs,_zev,_code);
  val(_zHos,_zHo,_code);

  _eloev := _zEv;
  _eloho := _zHo;

  dec(_eloho);
  if _eloho=0 then
    begin
      _eloho := 12;
      dec(_eloev);
    end;

  _elofarok := inttostr(_eloev-2000)+nulele(_eloho);
  _hzTablanev := 'HZ' + _elofarok;

  ValdataDbase.connected := true;
  ValdataTabla.close;
  ValdataTabla.TableName := _hzTablanev;
  if not ValdataTabla.exists then
    begin
      Valdatadbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM ' + _hztablanev + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not ValdataQuery.eof do
    begin
      _aktdnem := ValdataQuery.FieldByNAme('VALUTANEM').asstring;
      _aktnyito := ValdataQuery.FieldByNAme('ZARO').asInteger;
      _xx := ScanDnem(_aktdnem);
      _nyito[_xx] := _aktnyito;
      ValdataQuery.next;
    end;
  ValdataQuery.close;
  ValdataDbase.close;
end;

// =============================================================================
                 procedure TNapzarForm.ForgalomBeolvasas;
// =============================================================================

var i: byte;

begin
  for i := 1 to 27 do
    begin
      _vetel[i] := 0;
      _eladas[i] := 0;
      _atadas[i] := 0;
      _atvetel[i] := 0;
    end;

  _vKerekites := 0;
  _eKerekites := 0;

  _pcs := 'SELECT FEJ.*,TET.*' + _sorveg;
  _pcs := _pcs + 'FROM '+ _fejFileNev+' FEJ JOIN ' + _tetFileNev+' TET' + _sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM' + _sorveg;
  _pcs := _pcs + 'WHERE (FEJ.STORNO=1) AND (FEJ.DATUM<' + chr(39)+_zDatums+chr(39)+')';

  ValdataDbase.connected := true;
  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  {
  while not ValdataQuery.eof do
    begin
      _tipus := ValdataQuery.FieldByNAme('TIPUS').asString;
      _kerekites := ValdataQuery.FieldByName('KEREKITES').asInteger;
      if _tipus='V' then _vkerekites := _vkerekites + _kerekites;
      if _tipus='E' then _eKerekites := _eKerekites + _kerekites;
      ValdataQuery.next;
    end;
  ValdataQuery.close;

  // ---------------------------------------------------------------------------

  _pcs := 'SELECT * FROM ' + _tetFileNev + _sorveg;
  _pcs := _pcs + 'WHERE (STORNO=1) AND (DATUM<' + chr(39)+_zDatums+chr(39)+')';

  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  }

  _utbizonylat := 'XXXXX';
  _bjVetel  := 0;

  while not ValdataQuery.eof do
    begin
      _bizonylatszam := ValdataQuery.FieldByNAme('BIZONYLATSZAM').asString;
      _tipus := ValdataQuery.FieldByNAme('TIPUS').asString;
      _aktdnem := ValdataQuery.FieldByNAme('VALUTANEM').asString;
      _aktbankjegy := ValdataQuery.FieldByName('BANKJEGY').asinteger;
      _forintertek := ValdataQuery.FieldbyName('FORINTERTEK').asInteger;
      _kerekites := ValdataQuery.FieldByNAme('KEREKITES').asInteger;
      _fizetoeszkoz := ValdataQuery.FieldByNAme('FIZETOESZKOZ').asInteger;

      _ujbiz := False;
      if _utbizonylat<>_bizonylatszam then _ujbiz := True;

      _xx := scandnem(_aktdnem);

      if _tipus='V' then
        begin
          _vetel[_xx] := _vetel[_xx] + _aktbankjegy;
          _eladas[_hufindex] := _eladas[_hufindex] + _forintertek;
          if _ujbiz then _eladas[_hufindex]:=_eladas[_hufindex]+_kerekites;

        end;

      if _tipus='E' then
        begin
          _eladas[_xx] := _eladas[_xx] + _aktbankjegy;
          _vetel[_hufindex] := _vetel[_hufindex] + _forintertek;
          if _fizetoeszkoz=2 then
            begin
              _bjVetel := _bjvetel + _forintertek;
              if _ujbiz then _bjvetel := _bjvetel + _kerekites;
            end;

          if _ujbiz then _vetel[_hufindex]:=_vetel[_hufindex]+_kerekites;
        end;

      if _tipus='U' then _atvetel[_xx] := _atvetel[_xx] + _aktbankjegy;
      if _tipus='F' then _atadas[_xx] := _atadas[_xx] + _aktbankjegy;
      _utbizonylat := _bizonylatszam;

      ValdataQuery.next;
    end;
  ValdataQuery.close;
  ValdataDbase.close;
end;

// =============================================================================
            function TNapzarform.Scandnem(_dn: string): byte;
// =============================================================================

var _z: byte;

begin
  result := 0;
  _z := 1;
  while _z<=27 do
    begin
      if _dnem[_z] = _dn then
        begin
          result := _z;
          exit;
        end;
      inc(_z);
    end;
end;

// =============================================================================
                  procedure TNapzarform.ZdatumsVtempbe;
// =============================================================================

begin
  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (DATUM,OTVENEDIK)'+_sorveg;
  _pcs := _pcs + 'VALUES ('+chr(39)+_zDatums+chr(39)+',';
  _pcs := _pcs + inttostr(_navoke)+')';
  ValutaParancs(_pcs);
end;


{
procedure TNapzarForm.SetRekordDarab;

begin
  valutadbase.connected := true;
  _pcs := 'SELECT * FROM BLOKKFEJ WHERE DATUM='+chr(39)+_megnyitottnap+chr(39);
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _fejdb := recno;
      close;
    end;

  _pcs := 'SELECT * FROM BLOKKTETEL WHERE DATUM='+chr(39)+_megnyitottnap+chr(39);
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _TETdb := recno;
      close;
    end;
  ValutaDbase.close;

  // ---------------------------------------------------------------------------

  valdatadbase.connected := true;
  _pcs := 'SELECT * FROM ' + _fejfileNev + ' WHERE DATUM='+chr(39)+_megnyitottnap+chr(39);
  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _zFejdb := recno;
      close;
    end;

  _pcs := 'SELECT * FROM ' + _tetFileNev + ' WHERE DATUM='+chr(39)+_megnyitottnap+chr(39);
  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _zTetdb := recno;
      close;
    end;
  ValdataDbase.close;
end;
}

end.
