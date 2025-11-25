unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, IBDatabase, DB, IBCustomDataSet,
  IBQuery, IBTable, ComCtrls, Buttons, strutils, Dateutils,printers, jpeg;

type
  TNapzarForm = class(TForm)

    Indito          : TTimer;

    SOURCEQUERY     : TIBQuery;
    SOURCEDBASE     : TIBDatabase;
    SOURCETRANZ     : TIBTransaction;

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
    E1: TPanel;
    E2: TPanel;
    E3: TPanel;
    E4: TPanel;
    E5: TPanel;
    Panel1          : TPanel;
    RendbenPanel    : TPanel;
    V1: TPanel;
    V2: TPanel;
    V3: TPanel;
    V4: TPanel;
    v5: TPanel;
    ZarasMenetPanel : TPanel;

    Shape1          : TShape;
    Shape2          : TShape;
    Shape3          : TShape;
    Shape4          : TShape;

    Memo1           : TMemo;

    zOkeGomb        : TBitBtn;
    HRKQUERY: TIBQuery;
    HRKDBASE: TIBDatabase;
    HRKTRANZ: TIBTransaction;



    procedure FormActivate(Sender: TObject);
    procedure HaviGyujtokbeMasolas;
    procedure InditoTimer(Sender: TObject);

    procedure ValutaParancs(_ukaz: string);
    procedure ValdataParancs(_ukaz: string);

    procedure ZOkeGombClick(Sender: TObject);
    procedure BFCopy;
    procedure BTCopy;
    procedure CIMTCopy;
    procedure NarfCopy;
    procedure WuniCopy;
    procedure WzarCopy;
    procedure EdatCopy;
    procedure EkerCopy;
    procedure KDatCopy;
    procedure KezdijCopy;
    procedure CimtipRogzito(_ctip: byte);

    function Napzarcontrol: integer;
    function Nulele(_b: byte): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  NAPZARFORM: TNAPZARFORM;

   _ep,_vp: array[1..5] of TPanel;


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

  _bf,_bt,_datum,_ido,_pcs,_megnyitottnap,_zdatums,_aktdnem,_aktdnev,_farok: string;
  _bizonylat,_tipus,_trbpenztar,_tarspenztar,_stornobiz,_elojel,_tortresz: string;
  _cimt,_edat,_eker,_kdat,_kezd,_narf,_wuni,_wzar,_biztipus: string;
  _prosnev,_idkod,_plomba,_szallnev: string;
  _sorveg: string = chr(13)+chr(10);

  _tetel,_recno,_aktvarf,_aktearf,_aktelszarf,_errorcode,_aktzaro,_aktnyito: integer;
  _forintertek,_arfolyam,_bankjegy,_bevetel,_kiadas,_elszamarf,_ellenorkod: integer;
  _elszarf,_hrkzaro,_cimoke: integer;

  _width,_height,_top,_left: word;
  _storno,_hufindex,_cimletsorszam,_cimletoke,_elloke: byte;

  function checkcontrol(_para: integer): integer; stdcall; external 'c:\ertektar\bin\checklst.dll' name 'checkcontrol';
  function cimletmenurutin: integer; stdcall; external 'c:\ertektar\bin\cimlmenu.dll' name 'cimletmenurutin';
  function cimletctrlrutin: integer; stdcall; external 'c:\ertektar\bin\cimlctrl.dll' name 'cimletctrlrutin';
  function getellenorrutin: integer; stdcall; external 'c:\ertektar\bin\getellen.dll' name 'getellenorrutin';
  function napzarnyomtatorutin: integer; stdcall; external 'c:\ertektar\bin\nznyomt.dll' name 'napzarnyomtatorutin';
  function regeneralorutin: integer; stdcall; external 'c:\ertektar\bin\regen.dll' name 'regeneralorutin';
  function kunacimletezes: integer; stdcall; external 'c:\ertektar\bin\hrkcim.dll';


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

  _vp[1]  := v1;
  _vp[2]  := v2;
  _vp[3]  := v3;
  _vp[4]  := v4;
  _vp[5]  := v5;

  DatumPanel.Caption := '';
  Indito.Enabled := true;
end;

// =============================================================================
              procedure TNAPZARFORM.INDITOTimer(Sender: TObject);
// =============================================================================

begin
  Indito.Enabled := False;
  Zarasmenetpanel.Visible := False;
  _hufindex := 13;

 // A hardware-ben lévõ napnyitás mutatja, a napot, amit zárni kell:

 _pcs := 'SELECT * FROM HARDWARE';

  ValutaDbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
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
  _farok := midstr(_zDatums,3,2)+midstr(_zDatums,6,2);

  regeneralorutin;

  // Ellenörzi, hogy lehet-e napot zárni
  //     (MTCN számok,átadólap,cimletezések erc.Self)

  _errorcode := Napzarcontrol;

  {
     errorcode=  0: hibátlan

                 1: esti cimletezés hibás
                 2: kezelési dij cimletezés hibás
                 3: western union cimletezés hibás
                 4: afacimletezés hibás
                 5: elektromos kereskedés cimletezés hibás

  }




  // 0-nál nagyobb hiba = Hiányzó vagy rossz címlet:

  if _errorcode>0 then
    begin
      _errorcode := cimletmenurutin;
      IF _errorcode=-1 then
        begin
          Modalresult := 1;
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

  _elloke := getellenorrutin;
  if _elloke<>1 then
    begin
      Modalresult := 2;
      exit;
    end;

  {
  _pcs := 'SELECT * FROM VTEMP';
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      _ellenornev := trim(FieldByNAme('ELLENORNEV').assTRING);
      _ellenorbeo := trim(FieldByNAme('ELLENORBEO').assTRING);
      Close;
    end;
  Valutadbase.close;
  }

  Checkcontrol(0);

  // ----------- Itt minden rendben, indulhat a napzárás -----------------------

  with ZarasmenetPanel do
    begin
      Top     := 88;
      Left    := 16;
      Visible := True;
      Repaint;
    end;

  _pcs := 'SELECT * FROM HRKNAPLO WHERE DATUM='+chr(39)+_zdatums+chr(39);
  Hrkdbase.Connected := True;
  with HrkQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      _hrkzaro := FieldByNAme('ZARO').asInteger;
      Close;
    end;
  Hrkdbase.close;

  if _hrkzaro>0 then
    begin
      _cimoke := kunacimletezes;
      if _cimoke=-1 then
        begin
          Modalresult := 2;
          exit;
        end;
    end;

  Memo1.Lines.Add('A NAPI ADATOK BEMÁSOLÁSA A HAVI GYÜJTÖKBE');
  HavigyujtokbeMasolas;

  Memo1.Lines.add('A NAPI ZÁRÁS KINYOMTATÁSA');
  napzarnyomtatorutin;

  // A zárás ezennel készre vehetõ, igy a Napzárás mezõ kitölthetõ:

  Memo1.Lines.Add('A NAPI ZÁRÁS VÉGREHAJTÁSÁNAK NYUGTÁZÁSA');
  _pcs := 'UPDATE HARDWARE SET LEZARTNAP='+chr(39)+_zDatums+chr(39);
  ValutaParancs(_pcs);

  Zokegomb.Visible := True;
  ZokeGomb.Enabled := true;
  ActiveControl    := Zokegomb;

end;

// =============================================================================
                     function TNAPZARFORM.NapzarControl: integer;
// =============================================================================

VAR I: INTEGER;

begin
  // Az ellemörzést-követõ panel alapra aállitása:

  for i := 1 to 5 do
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
  //                      Esti zárás cimletek ellenõrzése:

  e1.font.color := clBlack;
  _cimletsorszam := 1;
  CimtipRogzito(_cimletsorszam);
  _CimletOke := cimletctrlrutin;

  if _cimletOke=2 then
    begin
      v1.caption := 'nem egyezik';
      ShowMessage('HIÁNYZIK VAGY ELTÉR AZ ESTI PÉNZTÁR CIMLETEZÉSE');
      Result := 1; // errorcode-1 -> HIBÁS ESTI CIMLETEZÉS
      Exit;
    end;

  v1.caption := 'rendben';

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  //          A kezelési díj cimleteinek ellenörzése:

  e2.font.color := clBlack;
  _cimletsorszam := 2;
  CimtipRogzito(_cimletsorszam);
  _CimletOke := cimletctrlrutin;
  if _CimletOke=2 then
    begin
      v2.caption := 'nem egyezik';
      ShowMessage('Nincs, vagy nem egyezik a kezelési díj címletezése');
      result := 2;  // errorcode = 2 -> hibás kezelési díj zárása
      exit;
    end;
  v2.caption := 'rendben';

 // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 //      Ha van Western, akkor annak címletezését kell vizsgálni:

  e3.font.color := clBlack;

  _cimletSorszam := 3;
  CimtipRogzito(_cimletsorszam);
  _cimletoke := cimletctrlrutin;

  if _cimletOke=2 then
    begin
      v3.caption := 'nem egyezik';
      ShowMessage('Nincs, vagy nemegyezik a  Western Union cimletezés ');
      cimletmenurutin;
      Result := 3;  // errorcode=3 -> hibás wu. cimletezés
      Exit;
    end;

  v3.caption := 'rendben';


  // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  //          Ha van AFA, akkor annak cimletezeset is vizsgálni kell:

   e4.font.color := clBlack;

   _cimletsorszam := 4;
   CimtipRogzito(_cimletsorszam);
   _cimletoke := cimletctrlrutin;

   if _cimletOke=2 then
     begin
       v4.caption := 'nem egyezik';
       ShowMessage('Az ÁFA-pénztár nincs cimletezve');
       Result := 4;  // errorcode=4 -> áfa cimletezés rossz
       Exit;
     end;
   v4.caption := 'rendben';


  // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  //                  Az e-kereskedelem cimletezés vizsgálata

  e5.Font.Color := clBlack;

  _cimletsorszam := 5;
  CimtipRogzito(_cimletsorszam);
  _cimletoke := cimletctrlrutin;

  if _cimletOke=2 then
    begin
      v5.caption := 'nem egyezik';
      ShowMessage('Az e-kereskedelem nincs cimletezve');
      Result := 5;  // errorcode=5 -> e-trade cimletezés rossz
      Exit;
    end;
  v5.caption := 'rendben';

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
  Bfcopy;
  BtCopy;
  CimtCopy;
  NarfCopy;
  EdatCopy;
  EkerCopy;
  KdatCopy;
  KezdijCOpy;
  Wunicopy;
  wzarcopy;
end;


// =============================================================================
               procedure TNAPZARFORM.ZOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
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
                         procedure TNapzarForm.BfCopy;
// =============================================================================

begin
  _bf := 'BF' + _farok;
  _datum := _megnyitottnap;

   Memo1.Lines.Add('A BLOKKFEJEK MÁSOLÁSA');

  SourceDbase.connected := true;
  with Sourcequery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM BLOKKFEJ');
      Open;
    end;
  while not SourceQuery.eof do
    begin
      with SourceQuery do
        begin
          _bizonylat := trim(FieldByName('BIZONYLATSZAM').asString);
          _tipus := fieldByNAme('TIPUS').asstring;
          _ido := Fieldbyname('IDO').asstring;
          _forintertek := FieldByNAme('FORINTERTEK').asInteger;
          _tetel:= FieldByNAme('TETEL').ASiNTEGER;
          _trbPenztar := trim(FieldByNAme('TRBPENZTAR').asstring);
          _tarspenztar := trim(FieldByNAme('TARSPENZTARKOD').asString);
          _prosnev := trim(FieldByName('PENZTAROSNEV').AsString);
          _idKod := FieldByName('IDKOD').asString;
          _plomba := trim(FieldByName('PLOMBASZAM').AsString);
          _szallnev := trim(FieldByNAme('SZALLITONEV').AsString);
          _storno := FieldByNAme('STORNO').asInteger;
          _stornobiz := trim(FieldByNAme('STORNOBIZONYLAT').asString);
        end;

      _pcs := 'INSERT INTO ' + _BF + ' (BIZONYLATSZAM,DATUM,TIPUS,IDO,';
      _pcs := _pcs + 'FORINTERTEK,TETEL,TRBPENZTAR,TARSPENZTARKOD,';
      _pcs := _pcs + 'PENZTAROSNEV,IDKOD,PLOMBASZAM,SZALLITONEV,';
      _pcs := _pcs + 'STORNO,STORNOBIZONYLAT)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39)+_bizonylat+chr(39)+',';
      _pcs := _pcs + chr(39) + _datum + chr(39) + ',';
      _pcs := _pcs + chr(39) + _tipus + chr(39) + ',';
      _pcs := _pcs + chr(39) + _ido + chr(39) + ',';
      _pcs := _pcs + inttostr(_forintertek) + ',';
      _pcs := _pcs + inttostr(_tetel) + ',';
      _pcs := _pcs + chr(39) + _trbPenztar + chr(39) + ',';
      _pcs := _pcs + chr(39) + _tarspenztar + chr(39) + ',';
      _pcs := _pcs + chr(39) + _prosnev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _idkod + chr(39) + ',';
      _pcs := _pcs + chr(39) + _plomba + chr(39) + ',';
      _pcs := _pcs + chr(39) + _szallnev + chr(39) + ',';

      _pcs := _pcs + inttostr(_storno) + ',';
      _pcs := _pcs + chr(39) + _stornobiz + chr(39) + ')';
      ValdataParancs(_pcs);
      SourceQuery.next;
    end;
  SourceQuery.close;
  _pcs := 'DELETE FROM BLOKKFEJ';
  ValutaParancs(_pcs);
end;


// =============================================================================
                          procedure TNapzarForm.BtCopy;
// =============================================================================

begin
  _bt := 'BT' + _farok;
  _DATUM := _megnyitottnap;

   Memo1.Lines.Add('BLOKKTÉTELEK MÁSOLÁSA');

  SourceDbase.connected := true;
  with Sourcequery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM BLOKKTETEL');
      Open;
    end;
  while not SourceQuery.eof do
    begin
      with SourceQuery do
        begin
          _bizonylat := trim(FieldByName('BIZONYLATSZAM').asString);

          _AKTDNEM := fieldByNAme('VALUTANEM').asstring;
          _forintertek := FieldByNAme('FORINTERTEK').asInteger;
          _arfolyam:= FieldByNAme('ARFOLYAM').ASiNTEGER;
          _elszarf := FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
          _bankjegy := FieldByNAme('BANKJEGY').asInteger;
          _storno := FieldByNAme('STORNO').asInteger;
          _ELOJEL := FieldByNAme('ELOJEL').asString;
          _TORTRESZ := trim(FieldByNAme('TORTRESZ').asString);
        end;

      _pcs := 'INSERT INTO ' + _Bt + ' (BIZONYLATSZAM,DATUM,VALUTANEM,';
      _pcs := _pcs + 'FORINTERTEK,ARFOLYAM,ELSZAMOLASIARFOLYAM,BANKJEGY,TORTRESZ,';
      _pcs := _pcs + 'ELOJEL,STORNO)' + _sorveg;

      _pcs := _pcs + 'VALUES (' + chr(39)+_bizonylat+chr(39)+',';
      _pcs := _pcs + chr(39) + _datum + chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + inttostr(_forintertek) + ',';
      _pcs := _pcs + inttostr(_arfolyam) + ',';
      _pcs := _pcs + inttostr(_elszarf) + ',';
      _pcs := _pcs + inttostr(_bankjegy) +  ',';
      _pcs := _pcs + chr(39) + _tortresz + chr(39) + ',';
      _pcs := _pcs + chr(39) + _elojel + chr(39) + ',';
      _pcs := _pcs + inttostr(_storno) + ')';
      ValdataParancs(_pcs);
      SourceQuery.next;
    end;
  SourceQuery.close;
  sourcedbase.close;

  _pcs := 'DELETE FROM BLOKKTETEL';
  ValutaParancs(_pcs);
end;


// =============================================================================
                          procedure TNapzarForm.cIMTCopy;
// =============================================================================

var _c1,_c2,_c3,_c4,_c5,_c6,_c7,_c8,_c9,_c10,_c11,_c12,_c13,_c14: word;

begin
   _datum := _megnyitottnap;
    Memo1.Lines.Add('A CÍMLETEZÉS BEMÁSOLÁSA');

  _cimt := 'CIMT' + _farok;
  _pcs := 'DELETE FROM ' + _CIMT + ' WHERE DATUM='+chr(39)+_datum+chr(39);
  ValdataParancs(_pcs);

  _pcs := 'SELECT * FROM CIMINI' + _sorveg;
  _pcs := _pcs + 'WHERE (CIMLETTYPE=1) AND (CIMLETEZETT>0)';

  SourceDbase.connected := true;
  with Sourcequery do
    begin
      Close;
      sql.clear;
      sql.add(_PCS);
      Open;
    end;

  while not SourceQuery.eof do
    begin

      with SourceQuery do
        begin

          _bankjegy := Fieldbyname('CIMLETEZETT').ASiNTEGER;
          _aktdnem  := Fieldbyname('VALUTANEM').asstring;

          _c1 := FieldByname('CIMLET1').asInteger;
          _c2 := FieldByname('CIMLET2').asInteger;
          _c3 := FieldByname('CIMLET3').asInteger;
          _c4 := FieldByname('CIMLET4').asInteger;
          _c5 := FieldByname('CIMLET5').asInteger;
          _c6 := FieldByname('CIMLET6').asInteger;
          _c7 := FieldByname('CIMLET7').asInteger;
          _c8 := FieldByname('CIMLET8').asInteger;
          _c9 := FieldByname('CIMLET9').asInteger;
          _c10:= FieldByname('CIMLET10').asInteger;
          _c11:= FieldByname('CIMLET11').asInteger;
          _c12:= FieldByname('CIMLET12').asInteger;
          _c13:= FieldByname('CIMLET13').asInteger;
          _c14:= FieldByname('CIMLET14').asInteger;
        end;
      _pcs := 'INSERT INTO ' + _cimt + ' (DATUM,BANKJEGY,VALUTANEM,PROSSZAM,CIMLET1,';
      _pcs := _pcs + 'CIMLET2,CIMLET3,CIMLET4,CIMLET5,CIMLET6,CIMLET7,CIMLET8,';
      _pcs := _pcs + 'CIMLET9,CIMLET10,CIMLET11,CIMLET12,CIMLET13,CIMLET14)'+_SORVEG;

      _pcs := _pcs + 'VALUES (' + CHR(39) + _DATUM + CHR(39) + ',';
      _pcs := _pcs + inttostr(_bankjegy) + ',';
      _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + inttostr(_ellenorkod)+ ',';
      _pcs := _pcs + inttostr(_c1) + ',';
      _pcs := _pcs + inttostr(_c2) + ',';
      _pcs := _pcs + inttostr(_c3) + ',';
      _pcs := _pcs + inttostr(_c4) + ',';
      _pcs := _pcs + inttostr(_c5) + ',';
      _pcs := _pcs + inttostr(_c6) + ',';
      _pcs := _pcs + inttostr(_c7) + ',';
      _pcs := _pcs + inttostr(_c8) + ',';
      _pcs := _pcs + inttostr(_c9) + ',';
      _pcs := _pcs + inttostr(_c10) + ',';
      _pcs := _pcs + inttostr(_c11) + ',';
      _pcs := _pcs + inttostr(_c12) + ',';
      _pcs := _pcs + inttostr(_c13) + ',';
      _pcs := _pcs + inttostr(_c14) + ')';
      ValdataParancs(_pcs);

      SourceQuery.next;
    end;
  Sourcequery.close;
  sourcedbase.close;
end;


// =============================================================================
                        procedure TNapzarForm.EdatCopy;
// =============================================================================

begin
  _edat := 'EDAT' + _farok;
  _datum := _megnyitottnap;

   Memo1.Lines.Add('E-KERESKEDELEM ZÁRÁS BEMÁSOLÁSA');


  _pcs := 'DELETE FROM '+_EDAT+' WHERE DATUM='+chr(39)+_datum+chr(39);
  ValdataParancs(_pcs);

  SourceDbase.connected := true;
  with Sourcequery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM EKERDATA');
      Open;
      _aktnyito := FieldByName('NYITO').asInteger;
      _bevetel := FieldByNAme('BEVETEL').asInteger;
      _kiadas := FieldByNAme('KIADAS').asInteger;
      _aktzaro := FieldByNAme('ZARO').asInteger;
      Close;
    end;
  Sourcedbase.close;

  _pcs := 'INSERT INTO '+ _EDAT + ' (DATUM,NYITO,BEVETEL,KIADAS,ZARO)'+ _SORVEG;
  _pcs := _pcs + 'VALUES (' + chr(39) + _datum + chr(39) + ',';
  _pcs := _pcs + inttostr(_aktnyito) + ',';
  _pcs := _pcs + inttostr(_bevetel) + ',';
  _pcs := _pcs + inttostr(_kiadas) + ',';
  _pcs := _pcs + inttostr(_aktzaro) + ')';
  ValdataParancs(_pcs);
end;


// =============================================================================
                         procedure TNapzarForm.EKerCopy;
// =============================================================================

begin
  _eker := 'EKER' + _farok;
  _datum := _megnyitottnap;

   Memo1.Lines.Add('AZ EKRESKEDELEM FORGALMA');

  SourceDbase.connected := true;
  with Sourcequery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM EKERESKEDELEM');
      Open;
    end;
  while not SourceQuery.eof do
    begin
      with SourceQuery do
        begin
          _bizonylat := trim(FieldByNAme('BIZONYLAT').asstring);
          _elojel := FieldByNAme('ELOJEL').asstring;
          _bankjegy := FieldByNAme('BANKJEGY').asInteger;
          _tarspenztar := trim(FieldByNAme('PENZTAR').asstring);
          _storno := fieldbyname('STORNO').asInteger;
        end;

      _pcs := 'INSERT INTO ' + _EKER + ' (DATUM,BIZONYLAT,ELOJEL,BANKJEGY,';
      _pcs := _Pcs + 'PENZTAR,STORNO)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + CHR(39) + _datum + chr(39) + ',';
      _pcs := _pcs + chr(39) + _bizonylat + chr(39) + ',';
      _pcs := _pcs + chr(39) + _elojel + chr(39) + ',';
      _pcs := _pcs + inttostr(_bankjegy) + ',';
      _pcs := _pcs + chr(39) + _tarspenztar + chr(39) + ',';
      _pcs := _pcs + inttostr(_storno) + ')';
      ValdataParancs(_pcs);

      sourcequery.next;
    end;

    SourceQuery.close;
    sourcedbase.close;

    _pcs := 'DELETE FROM EKERESKEDELEM';
    ValutaParancs(_pcs);
end;


// =============================================================================
                      procedure TNapzarForm.KdatCopy;
// =============================================================================

begin
  _Kdat := 'KDAT' + _farok;
  _datum := _megnyitottnap;

   Memo1.Lines.Add('KEZELÉSI DÍJAL ZÁRÁS BEMÁSOLÁSA');

  _pcs := 'DELETE FROM ' + _kDat + ' WHERE DATUM=' +chr(39) + _datum + chr(39);
  ValdataParancs(_pcs);

  SourceDbase.connected := true;
  with Sourcequery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM KEZDIJDATA');
      Open;

      _aktnyito := FieldByName('NYITO').asInteger;
      _bevetel := FieldByNAme('BEVETEL').asInteger;
      _kiadas := FieldByNAme('KIADAS').asInteger;
      _aktzaro := FieldByNAme('ZARO').asInteger;
      Close;
    end;
  Sourcedbase.close;

  _pcs := 'INSERT INTO '+ _KDAT + ' (DATUM,NYITO,BEVETEL,KIADAS,ZARO)'+ _SORVEG;
  _pcs := _pcs + 'VALUES (' + chr(39) + _datum + chr(39) + ',';
  _pcs := _pcs + inttostr(_aktnyito) + ',';
  _pcs := _pcs + inttostr(_bevetel) + ',';
  _pcs := _pcs + inttostr(_kiadas) + ',';
  _pcs := _pcs + inttostr(_aktzaro) + ')';
  ValdataParancs(_pcs);
end;

// =============================================================================
                     procedure TNapzarForm.KezdijCopy;
// =============================================================================

begin
  _KEZD := 'KEZD' + _farok;
  _datum := _megnyitottnap;

   Memo1.Lines.Add('A KEZELÉSI FORGALMI ADATOK BEMÁSOLÁSA');
  SourceDbase.connected := true;
  with Sourcequery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM KEZDIJ');
      Open;
    end;
  while not SourceQuery.eof do
    begin
      with SourceQuery do
        begin
          _bizonylat := trim(FieldByNAme('BIZONYLAT').asstring);
          _elojel := FieldByNAme('ELOJEL').asstring;
          _bankjegy := FieldByNAme('BANKJEGY').asInteger;
          _tarspenztar := trim(FieldByNAme('PENZTAR').asstring);
          _storno := fieldbyname('STORNO').asInteger;
        end;

      _pcs := 'INSERT INTO ' + _KEZD + ' (DATUM,BIZONYLAT,ELOJEL,BANKJEGY,';
      _PCS := _pcs + 'PENZTAR,STORNO)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + CHR(39) + _datum + chr(39) + ',';
      _pcs := _pcs + chr(39) + _bizonylat + chr(39) + ',';
      _pcs := _pcs + chr(39) + _elojel + chr(39) + ',';
      _pcs := _pcs + inttostr(_bankjegy) + ',';
      _pcs := _pcs + chr(39) + _tarspenztar + chr(39) + ',';
      _pcs := _pcs + inttostr(_storno) + ')';
      ValdataParancs(_pcs);

      sourcequery.next;
    end;

  SourceQuery.close;
  sourcedbase.close;

  _pcs := 'DELETE FROM KEZDIJ';
  ValutaParancs(_pcs);
end;


// =============================================================================
                      procedure TNapzarForm.NarfCopy;
// =============================================================================

begin
  _narf := 'NARF' + _farok;
  _datum := _megnyitottnap;

   Memo1.Lines.Add('A NAPI ÁRFOLYAMOK BEMÁSOLÁSA');

  _pcs := 'DELETE FROM ' + _narf + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_datum+chr(39);
  ValdataParancs(_pcs);

  SourceDbase.connected := true;
  with Sourcequery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM ARFOLYAM');
      Open;
    end;
  while not SourceQuery.eof do
    begin
      with SourceQuery do
        begin
          _aktdnem := trim(FieldByNAme('VALUTANEM').asstring);
          _elszamarf := FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
          _aktnyito:= FieldByNAme('NYITO').asInteger;
          _aktzaro := FieldByNAme('ZARO').asInteger;
        end;

      _pcs := 'INSERT INTO ' + _narf + ' (DATUM,VALUTANEM,ELSZAMOLASIARFOLYAM,';
      _pcs := _pcs + 'NYITO,ZARO)' + _sorveg;

      _pcs := _pcs + 'VALUES (' + CHR(39) + _datum + chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + inttostr(_elszamarf) + ',';
      _pcs := _pcs + inttostr(_aktnyito) + ',';
      _pcs := _pcs + inttostr(_aktzaro) + ')';
      ValdataParancs(_pcs);
      SourceQuery.next;
    end;
end;

// =============================================================================
                        procedure TNapzarForm.WuniCopy;
// =============================================================================

begin
  _WUNI := 'WUNI' + _farok;
  _datum := _megnyitottnap;

   Memo1.Lines.Add('WESTERN UNION ÉS AFA ADATOK BEMÁSOLÁSA');

  SourceDbase.connected := true;
  with Sourcequery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM WUAFAFORG');
      Open;
    end;

  while not SourceQuery.eof do
    begin
      with SourceQuery do
        begin
          _bizonylat := trim(FieldByNAme('BIZONYLAT').asstring);
          _aktdnem := FieldByNAme('VALUTANEM').asString;
          _elojel := FieldByNAme('ELOJEL').asstring;
          _bankjegy := FieldByNAme('BANKJEGY').asInteger;
          _tarspenztar := trim(FieldByNAme('PENZTAR').asstring);
          _biztipus := trim(FieldByNAme('BIZTIPUS').asString);
          _storno := fieldbyname('STORNO').asInteger;
        end;

      _pcs := 'INSERT INTO ' + _WUNI + ' (DATUM,VALUTANEM,BIZONYLAT,BANKJEGY,';
      _pcs := _pcs + 'ELOJEL,PENZTAR,BIZTIPUS,STORNO)' + _sorveg;

      _pcs := _pcs + 'VALUES (' + CHR(39) + _datum + chr(39) + ',';
      _PCS := _PCS + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + chr(39) + _bizonylat + chr(39) + ',';
      _pcs := _pcs + inttostr(_bankjegy) + ',';
      _pcs := _pcs + chr(39) + _elojel + chr(39) + ',';
      _pcs := _pcs + chr(39) + _tarspenztar + chr(39) + ',';
      _pcs := _pcs + chr(39) + _biztipus + chr(39) + ',';
      _pcs := _pcs + inttostr(_storno) + ')';
      ValdataParancs(_pcs);

      sourcequery.next;
    end;

  SourceQuery.close;
  sourcedbase.close;

  _pcs := 'DELETE FROM WUAFAFORG';
  ValutaParancs(_pcs);
end;

// =============================================================================
                      procedure TNapzarForm.WZARCopy;
// =============================================================================

var _usdnyito,_usdbevetel,_usdkiadas,_usdzaro: integer;
    _hufnyito,_hufbevetel,_hufkiadas,_hufzaro: integer;
    _afanyito,_afabevetel,_afakiadas,_afazaro: integer;

begin
  _WZAR := 'WZAR' + _farok;
  _datum := _megnyitottnap;
  _pcs := 'DELETE FROM ' + _wZar + ' WHERE DATUM='+chr(39)+_datum+chr(39);
  ValdataParancs(_pcs);

   Memo1.Lines.Add('A WESTERN UNION ÉS AFA ZÁRÁS BEMÁSOLÁSA');

  SourceDbase.connected := true;
  with Sourcequery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM WZARO');
      Open;
    end;
  while not SourceQuery.eof do
    begin
      with SourceQuery do
        begin
          _usdNyito   := FieldByName('USDNYITO').asInteger;
          _usdbevetel := FieldByNAme('USDBEVETEL').asInteger;
          _usdkiadas  := FieldByNAme('USDKIADAS').asInteger;
          _usdzaro   := FieldByNAme('USDZARO').asInteger;

          _HUFNYITO := FieldByNAme('HUFNYITO').asInteger;
          _HUFbevetel := FieldByNAme('HUFBEVETEL').asInteger;
          _HUFkiadas := FieldByNAme('HUFKIADAS').asInteger;
          _HUFzaro := FieldByNAme('HUFZARO').asInteger;

          _afaNYITO := FieldByNAme('afaNYITO').asInteger;
          _afabevetel := FieldByNAme('afaBEVETEL').asInteger;
          _afakiadas := FieldByNAme('afaKIADAS').asInteger;
          _afazaro := FieldByNAme('afaZARO').asInteger;

        end;

      _pcs := 'INSERT INTO ' + _WZAR + ' (DATUM,USDNYITO,USDBEVETEL,USDKIADAS,';
      _PCS := _Pcs + 'USDZARO,HUFNYITO,HUFBEVETEL,HUFKIADAS,HUFZARO,AFANYITO,';
      _pcs := _pcs + 'AFABEVETEL,AFAKIADAS,AFAZARO)' + _sorveg;

      _pcs := _pcs + 'VALUES (' + CHR(39) + _datum + chr(39) + ',';
      _pcs := _pcs + inttostr(_usdnyito)+',';
      _pcs := _pcs + inttostr(_usdbevetel)+',';
      _pcs := _pcs + inttostr(_usdkiadas)+',';
      _pcs := _pcs + inttostr(_usdzaro)+',';

      _pcs := _pcs + inttostr(_hufnyito)+',';
      _pcs := _pcs + inttostr(_hufbevetel)+',';
      _pcs := _pcs + inttostr(_hufkiadas)+',';
      _pcs := _pcs + inttostr(_hufzaro)+',';

      _pcs := _pcs + inttostr(_afanyito)+',';
      _pcs := _pcs + inttostr(_afabevetel)+',';
      _pcs := _pcs + inttostr(_afakiadas)+',';
      _pcs := _pcs + inttostr(_afazaro)+')';
      ValdataParancs(_pcs);

      sourcequery.next;
    end;

  SourceQuery.close;
  sourcedbase.close;

  _pcs := 'DELETE FROM WZARO';
  ValutaParancs(_pcs);
end;
end.
