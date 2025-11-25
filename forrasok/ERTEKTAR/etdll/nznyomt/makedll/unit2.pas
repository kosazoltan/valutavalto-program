unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, DateUtils, DB, DBTables, strUtils,printers,
  ComCtrls, IBDatabase, IBCustomDataSet, IBTable, Grids, DBGrids, IBQuery;

type
  TNapzarNyomtatoForm = class(TForm)

    Csik            : TProgressBar;

     DatumPanel     : TPanel;
  NyomFormpanel     : TPanel;
         Label1     : TLabel;
        Idozito     : TTimer;

    Shape1          : TShape;
    XTRANZ          : TIBTransaction;
    XDBASE          : TIBDatabase;
    XQUERY          : TIBQuery;

    ValdataTabla    : TIBTable;
    ValDataQuery    : TIBQuery;
    ValDataDbase    : TIBDatabase;
    ValDataTranz    : TIBTransaction;

    ValutaTabla     : TIBTable;
    ValutaQuery     : TIBQuery;
    ValutaDbase     : TIBDatabase;
    ValutaTranz     : TIBTransaction;
    XTABLA          : TIBTable;
    HRKQUERY: TIBQuery;
    HRKDBASE: TIBDatabase;
    HRKTRANZ: TIBTransaction;
    NAPLOQUERY: TIBQuery;
    NAPLODBASE: TIBDatabase;
    NAPLOTRANZ: TIBTransaction;

    procedure AtadAtvetGyujtes;
    procedure AtadatvetLista;
    procedure ForgalomLista;
    procedure WuAfaNyomtatas;
    procedure EkerNyomtatas;
    procedure KunaNyomtatas;
    procedure Naplobair;
    procedure Hrkregeneralo;
    procedure HrkParancs(_ukaz: string);
    procedure NaploParancs(_ukaz: string);

    procedure BlokkFocimIro;
    procedure EllenorBejegyzes;
    procedure FormActivate(Sender: TObject);
    procedure IdozitoTimer(Sender: TObject);
    procedure Kezelesidijnyomtatas;
    procedure KozepreIr(_szoveg: string);
    procedure PenztarAllas;
    procedure StartNyomtatas;
    procedure VonalHuzo;
    procedure ZaroKeszletBeolvasas;

    function Elokieg(_s: string; _p: byte): string;
    function ForintForm(_osszeg:integer):string;
    function FormKiir(_in: integer):string;
    function Scandnem(_dn: string): integer;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  NapzarNyomtatoForm: TNapzarNyomtatoForm;

  _height,_width,_top,_left,_tranzdb,_prosszam,_tranzsorszam: word;
  _homepenztarszam: byte;
  _hrknyito,_hrkbevetel,_hrkkiadas,_hrkzaro,_recno,_sumbe,_sumki: integer;
  _hNyito,_hzaro,_be,_ki: integer;
  _aktdatum: string;

  _nyito,_zaro,_atvetel,_atadas: array[1..27] of integer;
  _ptatvetel,_ptatadas,_trdnemsorszam: array[1..500] of integer;
  _ptss: array[1..500] of string;


  _LFile: textfile;

  _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                                   'CZK','DKK','EUR','GBP','HRK','HUF','ILS',
                                   'JPY','MXN','NOK','NZD','PLN','RON','RSD',
                                   'RUB','SEK','THB','TRY','UAH','USD');

  _pcs,_zDatums,_ertektarnev,_megnyitottnap,_homepenztarkod: string;
  _homePenztarnev,_homePenztarcim,_cegnev,_datumtext,_farok: string;
  _mondat,_aktdnem,_tipus,_cimt,_ellenornev,_ellenorbeo,_kftnev: string;
  _bizonylatszam,_fejFileNev,_tetfilenev,_penztar,_adoszam: string;
  _idos,_oras,_percs,_datum: string;

  _sorveg: string = chr(13)+chr(10);

  _printer,_xx: byte;
  _aktnyito,_aktzaro,_aktbankjegy,_ptaratvet,_ptaratadas,_code: integer;


function napzarnyomtatorutin: integer; stdcall;


implementation

{$R *.dfm}

// =============================================================================
              function napzarnyomtatorutin: integer; stdcall;
// =============================================================================

begin
  NapzarNyomtatoForm := TNapzarnyomtatoForm.Create(Nil);
  result := Napzarnyomtatoform.showmodal;
  NapzarnyomtatoForm.free;
end;


// =============================================================================
           procedure TNAPZARNYOMTATOFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  // Zárónap = VALUTA.FDB -> VTEMP -> DATUM

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;
  _top    := trunc((_height-768)/2);
  _left   := trunc((_width-1024)/2);

  Top    := _top +295;
  Left   := _left +330;

  Width  := 430;
  Height := 200;

  Idozito.Enabled := True;
end;


// =============================================================================
          procedure TNAPZARNYOMTATOFORM.IDOZITOTimer(Sender: TObject);
// =============================================================================

begin
  Idozito.Enabled := false;

  Csik.Max := 11;

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _zDatums := trim(FieldByName('DATUM').asString);
      Close;
    end;

  _farok := midstr(_zDatums,3,2)+midstr(_zDatums,6,2);

  with ValutaQuery do
    begin
      Sql.clear;
      Sql.Add('SELECT * FROM HARDWARE');
      Open;
      _printer       := FieldByNAme('PRINTER').asInteger;
      _kftnev        := trim(FieldByNAme('KFTNEV').asString);
      _megnyitottnap := trim(FieldByNAme('MEGNYITOTTNAP').asstring);
      Close;

      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;

      _homePenztarkod  := trim(FieldByName('PENZTARKOD').asString);
      _homePenztarnev  := trim(FieldByName('PENZTARNEV').AsString);
      _homepenztarcim  := trim(FieldByName('PENZTARCIM').AsString);
      Close;
    end;
  Valutadbase.close;

  val(_homePenztarkod,_homePenztarszam,_code);

  _cimt := 'CIMT' + _farok;
  _pcs := 'SELECT * FROM ' + _cimt;
  ValdataDbase.Connected := true;
  with ValdataQuery do
    begin
      close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;
      _prosszam := FieldByNAme('PROSSZAM').asInteger;
      Close;
    end;
  Valdatadbase.close;

  _pcs := 'SELECT * FROM VTEMP';
  ValutaDbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _ellenornev := trim(FieldByNAme('ELLENORNEV').AsString);
      _ellenorbeo := trim(FieldByNAme('ELLENORBEO').AsString);
      Close;
    end;
  Valutadbase.close;

  _kftnev := uppercase(_kftnev);
  _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';

  if _KFTnev='BEST' then _adoszam := '32313332-2-02';
  // A föfelirat  neghatározása:

  _idos := timetostr(TIME);
  if midstr(_idos,2,1)=':' then  _idos:= '0'+_idos;

  _oras := leftstr(_idos,2);
  _percs := midstr(_idos,4,2);
  _idos := _oras+' óra '+_percs+' perci';

  _datumtext := _zDatums + ' '+_idos+' NAPI ZARAS';
  DatumPanel.Caption := _datumText;
  DatumPanel.Repaint;
  NyomformPanel.Repaint;

  sleep(2000);

  ZaroKeszletbeolvasas;

  Csik.Position := 2;

  // Megnyitja AKTLST.TXT-t és beleirja a fejlécet:

  BlokkFocimiro;
  KozepreIr(_datumText);

  // A napi vétel és eladások beirása a text file-ba:

  AtadAtvetGyujtes;
  Csik.Position := 3;

  // A pénztári átvétel és átadás textfilebe irása:

  AtadatvetLista;
  Csik.Position := 4;

  ForgalomLista;
  Csik.position := 5;

  // Ha ez nem egy régebbi nap újranyomtatása, akkor nyilatkozat beirása:

  PenztarAllas;
  if _zDatums=_megnyitottnap then
    begin
      writeLn(_LFile,'Buntetojogi felelosegem tudataban kije-');
      writeLN(_LFile,'lentem,hogy a penztar allasa es a zaro-');
      writeLn(_LFile,'szalagon szereplo osszegek megegyeznek.');

      writeLn(_LFile,_sorveg);
      writeLn(_Lfile,dupestring('.',39));
      writeLn(_Lfile,'              penztaros');
      writeLn(_lfile,_sorveg + _sorveg);
    end;

  Csik.Position := 6;

  Wuafanyomtatas;
  Csik.Position := 7;

  Kezelesidijnyomtatas;
  Csik.Position := 8;

  Kunanyomtatas;

  EkerNyomtatas;
  Csik.Position := 9;


  ellenorbejegyzes;
  Csik.Position := 10;

  writeln(_LFile,_sorveg+_sorveg);
  CloseFile(_LFile);

  Startnyomtatas;
  Csik.Position := 11;
  sleep(300);
  ModalResult := 1;
end;


// =============================================================================
      procedure TNapzarNyomtatoForm.BlokkFocimIro;
// =============================================================================

begin

  assignFile(_LFile,'C:\ERTEKTAR\Aktlst.txt');
  Rewrite(_LFile);

  KozepreIr(_cegnev);
  Kozepreir(_homePenztarKod+' '+_homePenztarnev);
  Kozepreir(_homePenztarCim);
  Kozepreir('Adoszam: ' + _adoszam);
  VonalHuzo;
end;

// =============================================================================
                  procedure TNapZArNyomtatoForm.PenztarAllas;
// =============================================================================

var _egyenleg: integer;

begin
  _mondat := _ZDatums + '-i penztar allasa';
  KozepreIr(_mondat);
  VonalHuzo;

  writeLn(_Lfile,'Val.   Nyito     Forgalom      Penztar');
  writeLn(_Lfile,'nem   osszeg    egyenlege       allas');
  VonalHuzo;

  _xx := 1;
  while _xx<=27 do
    begin
      _aktdnem   := _dnem[_xx];
      _aktnyito  := _nyito[_xx];
      _aktzaro   := _zaro[_xx];

      _egyenleg := _aktzaro-_aktnyito;

      if _aktzaro>0 then
        begin
          write(_Lfile,_aktdnem+' ');
          write(_Lfile,Formkiir(_aktnyito)+' ');
          write(_Lfile,FormKiir(_egyenleg)+' ');
          writeLn(_Lfile,FormKiir(_aktzaro));
        end;

      inc(_xx);
    end;
  VonalHuzo;
  WriteLN(_LFile,' ');
end;


// =============================================================================
            procedure TNapzarNyomtatoForm.Kezelesidijnyomtatas;
// =============================================================================

var _kdat: string;
    _kdnyito,_kdbe,_kdki,_kdzaro: integer;

begin
  _kdat := 'KDAT' + _farok;
  _pcs := 'SELECT * FROM ' + _kDat + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _zDatums + chr(39);

  ValdataDbase.Connected := true;
  with ValdataQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;
      _kdNyito := FieldByNAme('NYITO').asInteger;
      _kdbe    := FieldByNAme('BEVETEL').asInteger;
      _kdki    := FieldByNAme('KIADAS').asInteger;
      _kdZaro  := FieldByNAme('ZARO').asInteger;
      Close;
    end;
  ValdataDbase.close;

  // ---------------------------------------------------------------------------

  writeLn(_LFile,' KEZELESI KOLTSEG '+ _zDatums + '-I LISTAJA');
  VonalHuzo;
  writeLn(_LFile,' NAPI NYITO OSSZEG ......:  ' + Formkiir(_kdnyito));
  writeLn(_LFile,' ATVETT OSSZEG ..........:  ' + Formkiir(_kdbe));
  writeLn(_LFile,' ATADOTT OSSZEG .........:  ' + Formkiir(_kdki));
  writeLN(_LFile,' NAPI ZARO OSSZEG .......:  ' + Formkiir(_kdzaro));

  VonalHuzo;
end;


// =============================================================================
            procedure TNapzarNyomtatoForm.Ekernyomtatas;
// =============================================================================

var _edat: string;
    _enyito,_ebe,_eki,_ezaro: integer;

begin

  _edat := 'EDAT' + _farok;
  
  _pcs := 'SELECT * FROM ' + _EDat + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _zDatums + chr(39);

  ValdataDbase.Connected := true;
  with ValdataQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;
      _ENyito := FieldByNAme('NYITO').asInteger;
      _Ebe    := FieldByNAme('BEVETEL').asInteger;
      _Eki    := FieldByNAme('KIADAS').asInteger;
      _EZaro  := FieldByNAme('ZARO').asInteger;
      Close;
    end;
  ValdataDbase.close;

  // ---------------------------------------------------------------------------

  writeLn(_LFile,' E-KERESKEDELMI MOZGÁSOK '+ _zDatums + '-N');
  VonalHuzo;
  writeLn(_LFile,' NAPI NYITO OSSZEG ......:  ' + Formkiir(_Enyito));
  writeLn(_LFile,' ATVETT OSSZEG ..........:  ' + Formkiir(_Ebe));
  writeLn(_LFile,' ATADOTT OSSZEG .........:  ' + Formkiir(_Eki));
  writeLN(_LFile,' NAPI ZARO OSSZEG .......:  ' + Formkiir(_Ezaro));

  VonalHuzo;
end;



// =============================================================================
                procedure TNapzarNyomtatoForm.EllenorBejegyzes;
// =============================================================================


var _text: string;

begin
  _text := 'Alulirott ' + trim(_ellenornev);

  KozepreIr(_text);
  KozepreIr(trim(_ellenorbeo));
  writeln(_LFile,'      alairasommal igazolom, hogy a');
  _text := trim(_homePenztarKod)+' szamu értéktár';

  KozepreIr(_text);
  KozepreIr(trim(_homePenztarCim));

  WriteLn(_LFile,' zarasa az FZS-01/2009 szamu modositott');
  WriteLn(_LFile,'      korlevel betartasaval tortent');
  WriteLn(_Lfile,_sorveg + dupestring('.',39));
  WriteLn(_LFile,'       Ellenorzo szemely alairasa');
  writeLn(_Lfile,_sorveg);
end;


// =============================================================================
       function TNapZarNyomtatoForm.Elokieg(_s: string; _p: byte): string;
// =============================================================================

begin
  result := trim(_s);
  while length(result)<_p do result := ' ' + result;

end;

// =============================================================================
             function TNapZarNyomtatoForm.ForintForm(_osszeg:integer):string;
// =============================================================================

var _slen,_pp: integer;
    _ejel : string;

begin
  Result := '-';

  if _osszeg=0 then exit;

  _ejel := '';

  if _osszeg<0 then
    begin
      _ejel := '-';
      _osszeg := abs(_osszeg);
    end;

  Result := intTostr(_osszeg);

  if _osszeg<1000 then
    begin
      Result := _ejel + Result;
      Exit;
    end;

  _sLen := length(Result);
  if _osszeg>999999 then
    begin
      _pp := _sLen-5;
      Result := _ejel + midStr(Result,1,_pp-1)+','+midStr(Result,_pp,3)+','+midStr(Result,_pp+3,3);
      Exit;
    end;

  _pp := _sLen-2;
  Result := _ejel + midStr(result,1,_pp-1)+','+midStr(result,_pp,3);

end;



// =============================================================================
                 procedure TNapzarNyomtatoForm.Vonalhuzo;
// =============================================================================

begin
  writeln(_LFile,dupestring('-',40));
end;

// =============================================================================
                  function TNapzarNyomtatoForm.FormKiir(_in: integer):string;
// =============================================================================
begin
  result := '          -';
  if _in=0  then exit;
  Result := ForintForm(_in);
  Result := EloKieg(Result,11);
end;

// =============================================================================
              procedure TNapzarNyomtatoForm.KozepreIr(_szoveg: string);
// =============================================================================

var _oo: integer;

begin
  _szoveg := trim(_szoveg);
  _oo := trunc((40-length(_szoveg))/2);
  writeLn(_LFile,dupestring(' ',_oo)+_szoveg);
end;


// =============================================================================
         function TNapzarNyomtatoForm.Scandnem(_dn: string): integer;
// =============================================================================

var _z: integer;

begin
  _z := 1;
  while _z<=27 do
    begin
      if _dn=_dnem[_z] then
        begin
          result := _z;
          exit;
        end;
      inc(_z);
    end;
  result := 0;
end;


// =============================================================================
              procedure TNapzarNyomtatoForm.AtadAtvetgyujtes;
// =============================================================================

var i: byte;

begin
  for i := 1 to 27 do
    begin
      _atvetel[i] := 0;
      _atadas[i]  := 0;
    end;

  _tranzsorszam := 0;

  _fejFileNev := 'BF' + _farok;
  _tetFileNev := 'BT' + _farok;

  _pcs := 'SELECT FEJ.*, TET.*' + _sorveg;
  _pcs := _pcs + 'FROM ' +_fejfilenev + ' FEJ JOIN ' + _tetFileNev + ' TET' + _sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM' + _sorveg;
  _pcs := _pcs + 'WHERE (FEJ.STORNO=1) AND (FEJ.DATUM='+chr(39)+_zDatums+chr(39)+')';

  
  Valdatadbase.Connected := true;
  with ValdataQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  while not ValdataQuery.eof do
    begin
      with ValdataQuery do
        begin
          _bizonylatszam := FieldByNAme('BIZONYLATSZAM').asString;
          _penztar       := trim(FieldByname('TARSPENZTARKOD').asstring);
          _aktdnem       := FieldByName('VALUTANEM').asstring;
          _aktBankjegy   := FieldByName('BANKJEGY').asInteger;
        end;
      _tipus := leftstr(_bizonylatszam,1);

      inc(_tranzSorszam);
      _xx := ScanDnem(_aktdnem);
      if _xx<1 then
        begin
          ValdataQuery.next;
          Continue;
        end;

      if _tipus='F' then _atadas[_xx] := _atadas[_xx] + _aktbankjegy;
      if _tipus='U' then _atvetel[_xx]:= _atvetel[_xx] + _aktbankjegy;

      IF _tipus='F' then _ptatadas[_tranzSorszam] := _aktbankjegy
      else _ptatvetel[_tranzsorszam] := _aktbankjegy;
      _ptss[_tranzsorszam]      := _penztar;
      _trdnemSorszam[_tranzsorszam]    := _xx;


      Valdataquery.Next;
    end;

  ValdataQuery.close;
  Valdatadbase.close;

  _tranzdb := _tranzsorszam;
end;


// =============================================================================
              procedure TNapZarNyomtatoForm.AtadAtvetLista;
// =============================================================================

var _cim,_aktpt: string;
    _trss: word;
    _atadott,_atvett: integer;

begin
  {

  _zDatums = Ennek a napnak kell azárását nyomtatni.
  _tranzdb = ennyi átad-átvét tranzakció volt a napon

  _trdnemsorszam[1.._tranzdb]   = az egyes tranzakciók valutaneme
  _ptatadas[1.._tranzdb] = átadott összegek tömbje
  _ptatvetel[1.._tranzdb]= átvett összegek tömbje
  _ptas[1.._tranzdb]     = a tranzakciók társpénztára

  _atadas[1..27] az egyes valuták átadott összege
  _atvetel[1..27] az egyes valuták átvett összege
  }

  _cim := _zDatums + '-i penztarak kozotti mozgasok';

  KozepreIr(_cim);
  VonalHuzo;

  //              123456789012345678901234567890123456789
  writeLn(_LFile,' Dnem  Ptar    Atadott       Atvett');
  //               EUR   143   123 456 789   123 456 789

  VonalHuzo;

  _trss := 1;
  while _trss<=_tranzdb do
    begin
      _xx      := _trDnemSorszam[_trss];
      _aktdnem := _dNem[_xx];
      _atadott := _ptatadas[_trss];
      _atvett  := _ptatvetel[_trss];
      _aktpt   := _ptss[_trss];

      if (_atadott>0) OR (_atvett>0) then
        begin
          write(_LFile,' '+_aktdnem+'   ');
          write(_LFile,elokieg(_aktpt,3)+'   ');
          write(_LFile,FormKiir(_atadott)+'   ');
          writeLn(_LFile,FormKiir(_atvett));
        end;
      inc(_trss);
    end;

  VonalHuzo;
  writeLn(_LFile,'Penztarak kozotti mozgasok osszesitve');
  writeLn(_Lfile,'  Dnem      Atadott        Atvett');
  VonalHuzo;

  _xx := 1;
  while _xx<=27 do
    begin
      _aktdnem    := _dnem[_xx];
      _ptaratadas := _atadas[_xx];
      _ptaratvet  := _atvetel[_xx];

      if (_ptaratadas>0) or (_ptaratvet>0) then
        begin
          write(_LFile,'   '+_aktdnem+'    ');
          write(_Lfile,Formkiir(_ptaratadas)+'    ');
          writeLn(_LFile,FormKiir(_ptarAtvet));
        end;

      inc(_xx);
    end;
  VonalHuzo;
end;

// =============================================================================
               procedure TNapZarNyomtatoForm.ForgalomLista;
// =============================================================================


var _aktatvett,_aktatadas,_ctrlsum: integer;

begin
  writeLn(_LFile,'  NAPI BANKJEGY-FORGALOM KIMUTATÁSA-I');
  vonalHuzo;
  writeLn(_LFile,'VALUTANEM  NYITO KESZLET   ATVETT OSSZEG');
  VonalHuzo;
  _xx := 1;
  while _xx<=27 do
    begin
      _aktdnem   := _dnem[_xx];
      _aktnyito  := _nyito[_xx];
      _aktatvett := _atvetel[_xx];
      _aktatadas := _atadas[_xx];
      _aktzaro   := _zaro[_xx];

      _ctrlsum := _aktnyito+_aktatvett+_aktatadas+_aktzaro;
      if _ctrlsum>0 then
        begin
          write(_LFile,'  '+_aktdnem+'      ');
          write(_LFile,FormKiir(_aktNyito)+'       ');
          writeLn(_LFile,FormKiir(_aktatvett));
        end;

      inc(_xx);
    end;

  VonalHuzo;
  writeLn(_LFile,' NAPI BANKJEGY-FORGALOM KIMUTATÁSA-II');
  vonalHuzo;
  writeLn(_LFile,'VALUTANEM ATADOTT OSSZEG    ZARO KESZLET');
  VonalHuzo;
  _xx := 1;
  while _xx<=27 do
    begin
      _aktdnem    := _dnem[_xx];
      _aktnyito   := _nyito[_xx];
      _aktatvett  := _atvetel[_xx];
      _aktatadas  := _atadas[_xx];
      _aktzaro    := _zaro[_xx];

      _ctrlsum := _aktnyito+_aktatvett+_aktatadas+_aktzaro;

      if _ctrlsum>0 then
        begin
          write(_LFile,'  ' + _aktdnem+'      ');
          write(_LFile,Formkiir(_aktatadas)+'       ');
          writeLn(_Lfile,FormKiir(_aktzaro));
        end;
      inc(_xx);
    end;
  VonalHuzo;

end;

// =============================================================================
             procedure  TNapzarNyomtatoForm.WuafaNyomtatas;
// =============================================================================

var _wzar: string;
    _usdnyito,_usdzaro,_usdbevetel,_usdkiadas: integer;
    _hufnyito,_hufzaro,_hufbevetel,_hufkiadas: integer;
    _afanyito,_afazaro,_afabevetel,_afakiadas: integer;

begin

  _wzar := 'WZAR' + _farok;

  ValdataDbase.connected := true;
  _pcs := 'SELECT * FROM ' + _wzar + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _zDatums + chr(39);


  with ValdataQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;

      _usdNyito := FieldByName('USDNYITO').asInteger;
      _usdBevetel := FieldByName('USDBEVETEL').asInteger;
      _usdKiadas := FieldByName('USDKIADAS').asInteger;
      _usdZaro := FieldByName('USDZARO').asInteger;

      _hufNyito := FieldByName('HUFNYITO').asInteger;
      _hufBevetel := FieldByName('HUFBEVETEL').asInteger;
      _hufKiadas := FieldByName('HUFKIADAS').asInteger;
      _hufZaro := FieldByName('HUFZARO').asInteger;

      _afaNyito := FieldByName('AFANYITO').asInteger;
      _afaBevetel := FieldByName('AFABEVETEL').asInteger;
      _afaKiadas := FieldByName('AFAKIADAS').asInteger;
      _afaZaro := FieldByName('AFAZARO').asInteger;
      Close;
    end;
  ValDataQuery.Close;

  Kozepreir('Western Union és AFA forgalom');
  VonalHuzo;

  Kozepreir('Western Union dollár forgalma:');
  writeln(_Lfile,' ');

  writeln(_LFile,'         Nyito: '+ formkiir(_usdNyito)+' USD');
  writeLN(_LFile,'       Bevetel: '+ formkiir(_usdbevetel)+' USD');
  writeLn(_LFile,'        Kiadas: '+ formkiir(_usdkiadas)+' USD');
  writeln(_LFile,'          Zaro: '+ formkiir(_usdZaro)+' USD');

  writeln(_Lfile,' ');
  Kozepreir('Western Union forint forgalma:');
  writeln(_Lfile,' ');

  writeln(_LFile,'         Nyito: '+ formkiir(_hufNyito)+' HUF');
  writeLN(_LFile,'       Bevetel: '+ formkiir(_hufbevetel)+' HUF');
  writeLn(_LFile,'        Kiadas: '+ formkiir(_hufkiadas)+' HUF');
  writeln(_LFile,'          Zaro: '+ formkiir(_hufZaro)+' HUF');

  writeln(_Lfile,' ');
  Kozepreir('Afa visszaigenyles forgalma:');
  writeln(_Lfile,' ');

  writeln(_LFile,'         Nyito: '+ formkiir(_afaNyito)+' FT');
  writeLN(_LFile,'       Bevetel: '+ formkiir(_afabevetel)+' FT');
  writeLn(_LFile,'        Kiadas: '+ formkiir(_afakiadas)+' FT');
  writeln(_LFile,'          Zaro: '+ formkiir(_afaZaro)+' FT');

  VonalHuzo;

end;



{
----------------------------------------
     Western Union és AFA forgalom
----------------------------------------
     Western Union dollár forgalma

         Nyito: 123,456,000 USD
       Bevetel: 123,456,000 USD
        Kiadas: 123,456,000 USD
          Zaro: 123,555,600 USD

     Western Union forint forgalma

         Nyito: 123,456,000 USD
       Bevetel: 123,456,000 USD
        Kiadas: 123,456,000 USD
          Zaro: 123,555,600 USD

      Afa visszaigenyles forgalma

         Nyito: 123,456,000 USD
       Bevetel: 123,456,000 USD
        Kiadas: 123,456,000 USD
          Zaro: 123,555,600 USD
----------------------------------------
}


// =============================================================================
               procedure TNapzarNyomtatoForm.Startnyomtatas;
// =============================================================================

var _mondat: string;
    _nyomtat,_olvas: textFile;

begin
  if _printer<>1 then AssignFile(_nyomtat,'LPT1')
  else AssignPrn(_nyomtat);

  Rewrite(_nyomtat);
  AssignFile(_olvas,'c:\ERTEKTAR\aktlst.txt');
  Reset(_olvas);

  while not eof(_olvas) do
    begin
      readln(_olvas,_mondat);
      writeln(_nyomtat,_mondat);
    end;
  System.closeFile(_nyomtat);
  System.CloseFile(_olvas);
end;

// =============================================================================
             procedure TNapzarNyomtatoForm.ZarokeszletBeolvasas;
// =============================================================================

var _narf: string;

begin

  _narf := 'NARF' + _farok;
  _pcs := 'SELECT * FROM ' + _narf + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _zDatums + chr(39);
  ValdataDbase.connected := true;
  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not ValdataQuery.eof do
    begin
      _aktnyito := ValdataQuery.FieldByNAme('NYITO').asInteger;
      _aktzaro  := ValdataQuery.FieldByNAme('ZARO').asInteger;
      _aktdnem  := ValdataQuery.FieldByNAme('VALUTANEM').asString;
      _xx := ScanDnem(_aktdnem);
      if _xx>0 then
        begin
          _nyito[_xx] := _aktnyito;
          _zaro[_xx] := _aktzaro;
        end;
      ValdataQuery.next;
    end;

   ValdataQuery.close;
   ValdataDbase.close;
end;

// =============================================================================
                 procedure TNapzarNyomtatoForm.KunaNyomtatas;
// =============================================================================

begin
  _hrknyito   := 0;
  _hrkbevetel := 0;
  _hrkkiadas  := 0;
  _hrkzaro    := 0;

  hrkregeneralo;

  _pcs := 'SELECT * FROM HRKNAPLO';
  HrkDbase.connected := true;
  with HrkQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno>0 then
    begin
      _pcs := 'SELECT * FROM HRKNAPLO' + _sorveg;
      _pcs := _pcs + 'WHERE DATUM='+chr(39) + _zDatums + chr(39);
      with HrkQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _recno := recno;
        end;

      if _recno=0 then
        begin
          _pcs := 'SELECT * FROM HRKNAPLO' + _sorveg;
          _pcs := _pcs + 'ORDER BY DATUM';

          with HrkQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
              Last;
              _hrknyito := FieldByNAme('ZARO').asInteger;
            end;
          Hrkquery.close;

          _hrkbevetel := 0;
          _hrkkiadas  := 0;
          _hrkzaro    := _hrknyito;
        end else
        begin
          with HrkQuery do
            begin
              _hrknyito := Fieldbyname('NYITO').asInteger;
              _hrkbevetel := Fieldbyname('BEVETEL').asInteger;
              _hrkkiadas := Fieldbyname('KIADAS').asInteger;
              _hrkzaro := Fieldbyname('ZARO').asInteger;
            end;
        end;
    end;

  HrkQuery.Close;
  Hrkdbase.Close;

  writeLn(_LFile,'HORVAT KUNA '+ _zDatums + '-I LISTAJA');
  writeLn(_lfILE,dupestring('-',40));
  writeLn(_LFile,' NAPI NYITO OSSZEG .....:  ' + Formkiir(_hrknyito));
  writeLn(_LFile,' ATVETT OSSZEG .........:  ' + Formkiir(_hrkbevetel));
  writeLn(_LFile,' ATADOTT OSSZEG ........:  ' + Formkiir(_hrkkiadas));
  writeLN(_LFile,' NAPI ZARO OSSZEG ......:  ' + Formkiir(_hrkzaro));
  writeLn(_lfILE,dupestring('-',40));
end;

// =============================================================================
                procedure TNapzarNyomtatoForm.Hrkregeneralo;
// =============================================================================

begin
  _pcs := 'DELETE FROM HRKNAPLO';
  HrkParancs(_pcs);

  _pcs := 'SELECT * FROM HRKSZAMLAK' + _sorveg;
  _pcs := _pcs + 'WHERE STORNO=1' + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  HrkDbase.connected := true;
  with HrkQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _aktdatum := FieldByNAme('DATUM').asString;
    end;

  _sumBe := 0;
  _sumKi := 0;
  _hnyito := 0;
  _hzaro  := 0;

  while not HrkQuery.eof do
    begin
      _datum := HrkQuery.FieldByNAme('DATUM').asString;
      _be := HrkQuery.fieldByNAme('BEVETEL').asInteger;
      _ki := HrkQuery.FieldByNAme('KIADAS').asInteger;

      if _aktdatum=_datum then
        begin
          _sumbe := _sumbe + _be;
          _sumki := _sumki + _ki;
          Hrkquery.next;
          Continue;
        end;

      Naplobair;

      _hnyito := _hzaro;
      _sumbe := _be;
      _sumki := _ki;
      _aktdatum := _datum;

      HrkQuery.next;
    end;

  Naplobair;

  _pcs := 'UPDATE HRKDATA SET AKTKESZLET=' + inttostr(_hzaro);
  HrkParancs(_pcs);
end;

// =============================================================================
                 procedure TNapzarNyomtatoForm.Naplobair;
// =============================================================================

begin
  _hzaro := _hnyito+_sumbe-_sumki;
  _pcs := 'INSERT INTO HRKNAPLO (DATUM,NYITO,BEVETEL,KIADAS,ZARO)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _aktdatum + chr(39) + ',';
  _pcs := _pcs + inttostr(_hnyito) + ',';
  _pcs := _pcs + inttostr(_sumbe) + ',';
  _pcs := _pcs + inttostr(_sumki) + ',';
  _pcs := _pcs + inttostr(_hzaro) + ')';

  NaploParancs(_pcs);
end;

procedure TNapzarNyomtatoForm.HrkParancs(_ukaz: string);

begin
  Hrkdbase.Connected := True;
  if Hrktranz.InTransaction then Hrktranz.commit;
  HrkTranz.StartTransaction;
  with HrkQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  HrkTranz.commit;
  hrkdbase.close;
end;

procedure TNapzarNyomtatoForm.NaploParancs(_ukaz: string);

begin
  Naplodbase.Connected := True;
  if Naplotranz.InTransaction then Naplotranz.commit;
  NaploTranz.StartTransaction;
  with NaploQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  NaploTranz.commit;
  Naplodbase.close;
end;



end.











                                                                                                                                                                                        