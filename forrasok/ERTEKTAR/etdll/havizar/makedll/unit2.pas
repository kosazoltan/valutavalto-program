unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBQuery, IBCustomDataSet, IBTable,
  Buttons, ExtCtrls, ComCtrls, dateUtils, strutils, Printers;

type
  THAVIZARAS = class(TForm)

    MenuPanel : TPanel;
    MessPanel : TPanel;
    Takaro    : TPanel;

    EvCombo   : TComboBox;
    HoCombo   : TComboBox;

    Label1    : TLabel;
    Label2    : TLabel;

    HoOkeGomb : TBitBtn;
    MegsemGomb: TBitBtn;

    NoPrintBox: TCheckBox;

    Shape1    : TShape;

    FastCsik  : TProgressBar;
    SlowCsik  : TProgressBar;
    VALDATAQUERY: TIBQuery;
    VALDATADBASE: TIBDatabase;
    VALDATATRANZ: TIBTransaction;
    VALDATATABLA: TIBTable;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;

    procedure AlapadatBeolvasas;
    procedure NyitoBeolvasas;
    procedure AtadAtvetgyujtes;
    procedure AtadAtvetLista;
    procedure ForgalomLista;
    procedure WuafaNyomtatas;
    procedure PenztarAllas;
    procedure Kezelesidijnyomtatas;
    function ScanPtar(_pts: string): word;
    procedure Ekernyomtatas;

    function FormKiir(_in: integer):string;

    procedure ValDataParancs(_ukaz: string);
    procedure BLokkfocimiro;
    procedure Startnyomtatas;
    procedure SetHzTabla;
    procedure MakeHzTabla;
    procedure EvComboChange(Sender: TObject);
    procedure FejlecIras;
    procedure FormActivate(Sender: TObject);

    procedure HoOkeGombClick(Sender: TObject);


    procedure Kozepreir(_s: string);
    procedure MegsemGombClick(Sender: TObject);
    procedure VonalHuzo;
    function ForintForm(_osszeg:integer):string;
    procedure adatnullazas;

    function ArfForm(_ft: integer): string;
    function Elokieg(_s: string; _h: byte): string;



    function Kieg(_s: string; _h: byte): string;
    function Nulele(_b: byte): string;
    function Scandnem(_dn: string): byte;
  
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  HAVIZARAS: THAVIZARAS;

  _pcs,_farok,_efarok,_hzTablaNev,_evhos,_kftnev: string;
  _sorveg: string = chr(13)+chr(10);

  _LFile,_nyomtat,_olvas: Textfile;

// ----------- ARRAYS OF STRING ------------------------------------------

  _honapnev: array[1..12] of string = (
             'JANUÁR',
             'FEBRUÁR',
             'MÁRCIUS',
             'ÁPRILIS',
             'MÁJUS',
             'JUNIUS',
             'JULIUS',
             'AUGUSZTUS',
             'SZEPTEMBER',
             'OKTÓBER',
             'NOVEMBER',
             'DECEMBER');

  _dnem : array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                'CZK','DKK','EUR','GBP','HRK','HUF','ILS','JPY','MXN','NOK',
                'NZD','PLN','RON','RSD','RUB','SEK','THB','TRY','UAH','USD');

  _dnev : array[1..27] of string = ('Ausztrál dollár','Bosnyák Márka','Bolgár leva',
           'Brazil real','Kanadai dollár','Svájci frank','Kinai jüan','Cseh korona',
           'Dán korona','Euró','Angol font','Horvát kuna','Magyar forint',
           'Izraeli shakel','Japán jen','Mexikói peso','Norvég korona',
           'Újzélandi dollár','Lengyel zloty','Román lei','Szerb dinár',
           'Orosz rubel','Svéd korona','Thai baht','Török lira','Ukrán hrivnya',
           'Amerikai dollár');

 // _ptss: array[1..2850] of string;
 // _trdnemSorszam: array[1..2850] of byte;
//  _ptatvetel,_ptatadas: array[1..2850] of integer;
  _atvetel,_atadas,_zaro,_nyito: array[1..27] of integer;

  _ptdarab:word;
  _ptsor: array[1..500] of string;
  _yy: word;
  _ptatadas,_ptatvetel: array[1..27,1..500] of integer;

  _ptarAtadas,_ptarAtvet: integer;
  _ekernyito,_kezdijnyito,_usdnyito,_hufnyito,_afanyito: integer;
  _usdZaro,_hufZaro,_afaZaro,_usdbevetel,_hufbevetel,_afabevetel: integer;
  _usdkiadas,_hufkiadas,_afakiadas: integer;
  _ekerzaro,_kezdijzaro,_aktbankjegy,_aktnyito,_aktzaro: integer;

  _width,_height,_top,_left,_maiev,_maiho,_kertev,_kertho,_havinapok: word;
  _tranzsorszam,_tranzdb: word;

  _printer,_xx: byte;

  _homepenztarkod,_homepenztarnev,_homepenztarcim,_homeTelefon: string;
  _elseje,_hovege,_aktevhonap,_fejfilenev,_tetFileNev,_bizonylatszam: string;
  _penztar,_aktdnem,_tipus,_mondat,_cegnev,_adoszam: string;

function havizarorutin: integer; stdcall;

implementation


{$R *.dfm}

function havizarorutin: integer; stdcall;

begin
  Havizaras := THavizaras.Create(Nil);
  result := Havizaras.showmodal;
  Havizaras.free;
end;

// =============================================================================
               procedure THAVIZARAS.FormActivate(Sender: TObject);
// =============================================================================

var i: byte;

begin
  Takaro.Visible := false;
  NoPrintBox.Checked := False;

  _width := Screen.Monitors[0].Width;
  _height:= screen.Monitors[0].Height;

  _top   := trunc((_height-768)/2);
  _left  := trunc((_width-1024)/2);

  top    := _top + 150;
  left   := _left +250;

  AdatNullazas;

  Alapadatbeolvasas;

  _maiev := yearof(Date);
  _maiho := monthof(date);

  evcombo.items.clear;
  hocombo.items.clear;

  evcombo.items.add(inttostr(_maiev-1));
  evcombo.items.add(inttostr(_maiev));

  for i := 1 to 12 do hocombo.items.add(_honapnev[i]);

  evcombo.itemindex := 1;
  hocombo.itemindex := (_maiho-1);

  Activecontrol := Hookegomb;

end;


// =============================================================================
                procedure THAVIZARAS.HOOKEGOMBClick(Sender: TObject);
// =============================================================================

var _evindex,_hoindex: integer;
    _eev,_eho,_y: word;

begin
  with Takaro do
    begin
      top     := 104;
      Left    := 8;
      Visible := True;
      repaint;
    end;

  _hoindex := hocombo.itemindex;
  _evindex := evcombo.itemindex;

  _kertev  := _maiev;
  if _evindex=0 then dec(_kertev);
  _kertho  := 1 + _hoindex;

  _farok := inttostr(_kertev-2000)+nulele(_kertho);
  _evHos := inttostr(_kertev)+' '+_honapnev[_kertho];

  _eev := _kertev;
  _eho := _kertho-1;

  if _eho<1 then
    begin
      _eho := 12;
      dec(_eev);
    end;

  _eFarok := inttostr(_eev-2000)+nulele(_eho);
  _HzTablaNev := 'HZ' + _eFarok;

  MessPanel.Caption := 'Nyitó készletek beolvasása';
  Messpanel.repaint;

  NyitoBeolvasas;

  Slowcsik.Max := 10;
  Fastcsik.Max := 1;

  FastCsik.Position := 0;
  SlowCsik.Position := 0;
  MessPanel.Caption := '';
  MessPanel.Repaint;

  _havinapok  := DaysInaMonth(_kertev,_kertho);
  _elseje     := inttostr(_kertev)+'.'+nulele(_kertho)+'.01';
  _hovege     := leftstr(_elseje,8)+nulele(_havinapok);
  _aktevhonap := inttostr(_kertev)+nulele(_kertho);

  MessPanel.Caption := 'A havi zárólista megkezdése';
  Messpanel.repaint;
  Blokkfocimiro;

  Kozepreir(_evhos+'I HAVI ZARAS');
  WRITELN(_lFile,' ');
  writeLn(_LFile,'        Kezdo datum: ' + _elseje);
  writeLn(_LFile,'        Vegso datum: ' + _hovege + _sorveg);

  MessPanel.Caption := 'Az adatok összegyüjtése';
  Messpanel.repaint;

  SlowCsik.Position := 1;
  AtadAtvetGyujtes;

  MessPanel.Caption := 'A havi forgalmak listája';
  Messpanel.repaint;

  SlowCsik.Position := 2;
  AtadAtvetLista;

  _y := 1;
  while _y<=27 do
    begin
      _zaro[_y] := _nyito[_y] + _atvetel[_y] - _atadas[_y];
      inc(_y);
    end;

  SlowCsik.Position := 3;
  ForgalomLista;

  MessPanel.Caption := 'Zárókészletek összeállitása';
  Messpanel.repaint;

  SlowCsik.Position := 4;
  PenztarAllas;

  MessPanel.Caption := 'Western Union és AFA listák';
  Messpanel.repaint;

  SlowCsik.Position := 5;
  WuaFaNyomtatas;

  MessPanel.Caption := 'Kezelési díjak és e-kereskedelem';
  Messpanel.repaint;

  SlowCsik.Position := 6;
  KezelesiDijNyomtatas;

  SlowCsik.Position := 7;
  Ekernyomtatas;

  FastCsik.Max := 2;
  Fastcsik.Position := 1;
  MessPanel.Caption := 'Nyomtatás beinditása';
  Messpanel.repaint;
  SlowCsik.Position := 8;
  writeLn(_LFile,' '+_sorveg);
  CloseFile(_LFile);


  StartNyomtatas;

  MessPanel.Caption := 'A havi zárótabla létrehozása';
  Messpanel.repaint;

  SlowCsik.Position := 9;
  SetHzTabla;

  SlowCsik.Position := 10;
  Fastcsik.Position := 2;
  Sleep(2500);

  Modalresult := 1;
end;


// =============================================================================
                procedure THAVIZARAS.ValdataParancs(_ukaz: string);
// =============================================================================

begin
  ValdataDbase.Connected := True;
  if ValdataTranz.InTransaction then ValdataTranz.Commit;
  VAldataTranz.StartTransaction;

  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;

  ValdataTranz.Commit;
  ValdataDbase.close;
end;

// =============================================================================
                 function THAVIZARAS.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
           procedure THAVIZARAS.MegsemGombClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 2;
end;

// =============================================================================
           procedure THAVIZARAS.EvComboChange(Sender: TObject);
// =============================================================================

begin
  ActiveControl := HookeGomb;
end;

// =============================================================================
              function THAVIZARAS.ScanDnem(_dn: string): byte;
// =============================================================================

var _z: byte;

begin
  _z := 1;
  while _z<=27 do
    begin
      if _dnem[_z]=_dn then
        begin
          result := _z;
          exit;
        end;
      inc(_z);
    end;
  result := 0;
end;



// =============================================================================
                  procedure THAVIZARAS.AlapadatBeolvasas;
// =============================================================================

begin
  MessPanel.Caption := 'Az alapadok beolvasása';
  MessPanel.Repaint;

  ValutaDbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM HARDWARE');
      Open;
      _kftnev  := trim(FieldByNAme('KFTNEV').asString);
      _printer := FieldbyName('PRINTER').asInteger;
      Close;

      Sql.Clear;
      Sql.Add('SELECT * FROM PENZTAR');
      Open;

      _homepenztarkod := trim(FieldByNAme('PENZTARKOD').asstring);
      _homepenztarNev := trim(FieldByName('PENZTARNEV').asString);
      _homepenztarCim := trim(FieldByName('PENZTARCIM').AsString);
      _homeTelefon  := trim(FieldByName('TELEFONSZAM').AsString);
      Close;
    end;
  ValutaDbase.close;

  _kftnev := uppercase(_kftnev);
  _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';
  _adoszam := '32313332-2-02';

  Sleep(600);
end;

// =============================================================================
           function THaviZaras.Kieg(_s: string; _h: byte): string;
// =============================================================================

begin
  result := _s;
  while length(result)<_h do result := result + chr(32);
end;

// =============================================================================
            function THAVIZARAS.Elokieg(_s: string; _h: byte): string;
// =============================================================================

begin
  result := _s;
  while length(result)<_h do result := ' ' + result;
end;



// =============================================================================
                         procedure THAVIZARAS.Fejleciras;
// =============================================================================

begin
  writeLn(_LFile,chr(27)+'@'+chr(14)+'      EXCLUSIVE' +chr(20));
  writeLn(_LFile,chr(14)+'  ' + 'BEST CHANGE ZRT' + CHR(20));

  Kozepreir(_homepenztarnev);
  Kozepreir(_homepenztarcim);

  if _homeTelefon<>'' then Kozepreir('Tel: '+_homeTelefon);

  VonalHuzo;
  Kozepreir(inttostr(_kertev)+' '+_honapnev[_kertho]+' havi penztarzaras');
  VonalHuzo;
end;


// =============================================================================
                function THAVIZARAS.ArfForm(_ft: integer): string;
// =============================================================================

var _fts: string;
    _w1,_f1: byte;

begin
  _fts := inttostr(_ft);
  _w1  := length(_fts);
  if _w1<4 then
    begin
      while length(_fts)<6 do _fts := ' ' + _fts;
      result := _fts;
      exit;
    end;

  _f1 := _w1-3;
  _fts := leftstr(_fts,_f1)+','+midstr(_fts,_f1+1,3);
  while length(_fts)<6 do _fts := ' ' + _fts;
  result := _fts;
end;

// =============================================================================
                  procedure THAVIZARAS.Kozepreir(_s: string);
// =============================================================================

var _w,_oo: byte;

begin
  _s  := trim(_s);
  _w  := length(_s);
  _oo := trunc((40-_w)/2);
  _s  := dupestring(' ',_oo)+_s;

  writeLn(_LFile,_s);
end;

// =============================================================================
                         procedure THAVIZARAS.VonalHuzo;
// =============================================================================

begin
  writeLn(_LFile,dupestring('-',40));
end;




// #############################################################################
// #############################################################################
// =============================================================================
              procedure THavizaras.AtadAtvetgyujtes;
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
  _pcs := _pcs + 'WHERE (FEJ.STORNO=1)';

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
          _tipus         := FieldByNAme('TIPUS').asString;
          _penztar       := trim(FieldByname('TARSPENZTARKOD').asstring);
          _aktdnem       := FieldByName('VALUTANEM').asstring;
          _aktBankjegy   := FieldByName('BANKJEGY').asInteger;
        end;


      _xx := ScanDnem(_aktdnem);
      _yy := scanptar(_penztar);

      if _tipus='F' then _ptatadas[_xx,_yy] := _ptatadas[_xx,_yy] + _aktbankjegy;
      if _tipus='U' then _ptatvetel[_xx,_yy]:= _ptatvetel[_xx,_yy] + _aktbankjegy;

      IF _tipus='F' then _atadas[_xx] := _atadas[_xx] + _aktbankjegy
      else _atvetel[_xx] := _atvetel[_xx] + _aktbankjegy;


      Valdataquery.Next;
    end;

  ValdataQuery.close;
  Valdatadbase.close;

  _tranzdb := _tranzsorszam;
end;


// =============================================================================
              procedure THavizaras.AtadAtvetLista;
// =============================================================================

var _cim,_aktpt: string;

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

  _cim := _evhos + 'i penztarak kozotti mozgasok';

  KozepreIr(_cim);
  VonalHuzo;

  //              123456789012345678901234567890123456789
  writeLn(_LFile,' Dnem  Ptar    Atadott       Atvett');
  //               EUR   143   123 456 789   123 456 789

  VonalHuzo;

  _xx := 1;
  while _xx<=27 do
    begin
      _aktdnem := _dnem[_xx];
      _yy := 1;
      while _yy<=_ptdarab do
        begin
          _aktpt := _ptsor[_yy];
          _atadott := _ptatadas[_xx,_yy];
          _atvett  := _ptatvetel[_xx,_yy];

          if (_atadott>0) OR (_atvett>0) then
            begin
              write(_LFile,' '+_aktdnem+'   ');
              write(_LFile,elokieg(_aktpt,3)+'   ');
              write(_LFile,FormKiir(_atadott)+'   ');
              writeLn(_LFile,FormKiir(_atvett));
            end;
          inc(_yy);
        end;
      inc(_xx);
    end;

  VonalHuzo;
  writeLn(_LFile,'Penztarak kozotti mozgasok osszesitve');
  writeLn(_Lfile,'  Dnem      Atadott        Atvett');
  VonalHuzo;

  _xx := 1;
  while _xx<=27 do
    begin
      _aktdnem    := _dnem[_xx];
      _atadott := _atadas[_xx];
      _atvett  := _atvetel[_xx];

      if (_atadott>0) or (_atvett>0) then
        begin
          write(_LFile,'   '+_aktdnem+'    ');
          write(_Lfile,Formkiir(_atadott)+'    ');
          writeLn(_LFile,FormKiir(_Atvett));
        end;

      inc(_xx);
    end;
  VonalHuzo;
end;

// =============================================================================
               procedure THavizaras.ForgalomLista;
// =============================================================================


var _aktatvett,_aktatadas,_ctrlsum: integer;

begin
  writeLn(_LFile,'  HAVI BANKJEGY-FORGALOM KIMUTATÁSA-I');
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
  writeLn(_LFile,' HAVII BANKJEGY-FORGALOM KIMUTATÁSA-II');
  vonalHuzo;
  writeLn(_LFile,'VALUTANEM ATADOTT OSSZEG    ZARO KESZLET');
  VonalHuzo;
  _xx := 1;
  while _xx<=27 do
    begin
      _aktdnem   := _dnem[_xx];
      _aktnyito  := _nyito[_xx];
      _aktatvett := _atvetel[_xx];
      _aktatadas := _atadas[_xx];
      _aktzaro   := _zaro[_xx];
      _ctrlsum   := _aktnyito+_aktatvett+_aktatadas+_aktzaro;
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
             procedure  THavizaras.WuafaNyomtatas;
// =============================================================================

var _wzar: string;
    _aktusdbevetel,_akthufbevetel,_aktafabevetel: integer;
    _aktusdkiadas,_akthufkiadas,_aktafakiadas: integer;

begin
  _usdBevetel := 0;
  _usdKiadas  := 0;

  _hufBevetel := 0;
  _hufKiadas  := 0;

  _afaBevetel := 0;
  _afaKiadas  := 0;

  _wzar := 'WZAR' + _farok;

  ValdataDbase.connected := true;
  _pcs := 'SELECT * FROM ' + _wzar + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with ValdataQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not ValdataQuery.eof do
    begin
      _aktusdbevetel := ValdataQuery.FieldbyNAme('USDBEVETEL').asInteger;
      _akthufbevetel := ValdataQuery.FieldbyNAme('HUFBEVETEL').asInteger;
      _aktafabevetel := ValdataQuery.FieldbyNAme('AFABEVETEL').asInteger;

      _aktusdKiadas := ValdataQuery.FieldbyNAme('USDKIADAS').asInteger;
      _akthufKiadas := ValdataQuery.FieldbyNAme('HUFKIADAS').asInteger;
      _aktafaKiadas := ValdataQuery.FieldbyNAme('AFAKIADAS').asInteger;

      _usdbevetel := _usdbevetel + _aktusdbevetel;
      _usdkiadas  := _usdkiadas + _aktusdkiadas;

      _hufbevetel := _hufbevetel + _akthufbevetel;
      _hufkiadas  := _hufkiadas + _akthufkiadas;

      _afabevetel := _afabevetel + _aktafabevetel;
      _afakiadas  := _afakiadas + _aktafakiadas;
      ValdataQuery.next;
    end;

  ValdataQuery.Last;
  _usdZaro := ValdataQuery.FieldByName('USDZARO').asInteger;
  _hufZaro := ValdataQuery.FieldByName('HUFZARO').asInteger;
  _afaZaro := ValdataQuery.FieldByName('AFAZARO').asInteger;

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

/////////////////////
// =============================================================================
                  procedure THavizaras.PenztarAllas;
// =============================================================================

var _egyenleg: integer;

begin
  _mondat := _evhos +'i penztar zaras';
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
      if _aktzaro>0 then
        begin
          _egyenleg := _aktzaro-_aktnyito;

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
            procedure THavizaras.Kezelesidijnyomtatas;
// =============================================================================

var _kdat: string;
    _kdnyito,_kdbe,_kdki,_aktkdbe,_aktkdki: integer;

begin
  _kdbe := 0;
  _kdki := 0;

  _kdat := 'KDAT' + _farok;
  _pcs := 'SELECT * FROM ' + _kDat + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  ValdataDbase.Connected := true;
  with ValdataQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;
      First;
      _kdNyito := FieldByNAme('NYITO').asInteger;
    end;

  while not ValdataQuery.eof do
    begin
      _aktkdbe    := ValdataQuery.FieldByNAme('BEVETEL').asInteger;
      _aktkdki    := ValdataQuery.FieldByNAme('KIADAS').asInteger;
      _kdbe := _kdbe + _aktkdbe;
      _kdki := _kdki + _aktkdki;
      ValdataQuery.next;
    end;

  ValdataQuery.Last;
  _kezdijZaro  := ValdataQuery.FieldByNAme('ZARO').asInteger;
  ValdataQuery.Close;
  ValdataDbase.close;

  // ---------------------------------------------------------------------------

  Kozepreir('KEZELESI KOLTSEGEK HAVI LISTAJA');
  VonalHuzo;
  writeLn(_LFile,' NAPI NYITO OSSZEG ......:  ' + Formkiir(_kdnyito));
  writeLn(_LFile,' ATVETT OSSZEG ..........:  ' + Formkiir(_kdbe));
  writeLn(_LFile,' ATADOTT OSSZEG .........:  ' + Formkiir(_kdki));
  writeLN(_LFile,' NAPI ZARO OSSZEG .......:  ' + Formkiir(_kezdijzaro));

  VonalHuzo;
end;


// =============================================================================
            procedure THavizaras.Ekernyomtatas;
// =============================================================================

var _edat: string;
    _enyito,_ebe,_eki,_aktebe,_akteki: integer;

begin

  _edat := 'EDAT' + _farok;

  _ebe := 0;
  _eki := 0;

  _pcs := 'SELECT * FROM ' + _EDat + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  ValdataDbase.Connected := true;
  with ValdataQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;
      First;
      _ENyito := FieldByNAme('NYITO').asInteger;
    end;

  while not ValdataQuery.eof do
    begin
      _aktebe := ValdataQuery.FieldByNAme('BEVETEL').asInteger;
      _akteki := ValdataQuery.FieldByNAme('KIADAS').asInteger;
      _ebe := _ebe + _aktebe;
      _eki := _eki + _akteki;
      ValdataQuery.next;
    end;
  ValdataQuery.Last;
  _ekerzaro := VAldataQuery.FieldByNAme('ZARO').asInteger;
  ValdataQuery.close;
  Valdatadbase.close;


  // ---------------------------------------------------------------------------

  KozepreIr('ELEKTROMOSKERESKEDELMI MOZGÁSOK');
  VonalHuzo;
  
  writeLn(_LFile,' NAPI NYITO OSSZEG ......:  ' + Formkiir(_Enyito));
  writeLn(_LFile,' ATVETT OSSZEG ..........:  ' + Formkiir(_Ebe));
  writeLn(_LFile,' ATADOTT OSSZEG .........:  ' + Formkiir(_Eki));
  writeLN(_LFile,' NAPI ZARO OSSZEG .......:  ' + Formkiir(_Ekerzaro));

  VonalHuzo;
end;

// =============================================================================
                   procedure THavizaras.BlokkFocimIro;
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
               procedure THavizaras.Startnyomtatas;
// =============================================================================

var _mondat: string;
    _nyomtat,_olvas: textFile;

begin

  if noprintBox.checked then exit;

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
                    procedure Thavizaras.SetHzTabla;
// =============================================================================

var _y: byte;

begin
  _hzTablanev := 'HZ' + _farok;

  ValdataTabla.close;
  ValdataTabla.Tablename := _hzTablanev;
  ValdataDbase.connected := true;

  if not ValdataTabla.exists then MakeHzTabla;

  _pcs := 'DELETE FROM ' + _hzTablanev;
  ValdataParancs(_pcs);

  _y := 1;
  while _y<=27 do
    begin
      _aktzaro := _zaro[_y];
      _aktdnem := _dnem[_y];
      if _aktzaro>0 then
        begin
          _pcs := 'INSERT INTO ' + _hztablanev + ' (VALUTANEM,ZARO)' + _sorveg;
          _pcs := _pcs + 'VALUES (' + chr(39) + _aktdnem + chr(39) + ',';
          _pcs := _pcs + inttostr(_aktzaro) + ')';
          ValdataParancs(_pcs);
        end;
      inc(_y);
    end;

  _pcs := 'UPDATE ' + _hztablanev + ' SET KEZDIJZARO='+inttostr(_kezdijzaro);
  _pcs := _pcs + ',EKERZARO=' + inttostr(_ekerzaro);
  _pcs := _pcs + ',USDZARO=' + inttostr(_usdzaro);
  _pcs := _pcs + ',HUFZARO=' + inttostr(_hufZaro);
  _pcs := _pcs + ',AFAZARO=' +inttostr(_afazaro);
  ValdataParancs(_pcs);
end;

procedure THavizaras.MakeHzTabla;

begin
  _pcs := 'CREATE TABLE ' + _hzTablaNev + '(';
  _pcs := _pcs + 'VALUTANEM CHAR (3)'+ ',' + _sorveg;
  _pcs := _pcs + 'ZARO INTEGER,'+ _sorveg;
  _pcs := _pcs + 'KEZDIJZARO INTEGER,';
  _pcs := _pcs + 'EKERZARO INTEGER,';
  _pcs := _pcs + 'USDZARO INTEGER,';
  _pcs := _pcs + 'HUFZARO INTEGER,';
  _pcs := _pcs + 'AFAZARO INTEGER)';
  ValdataParancs(_pcs);
end;

// =============================================================================
                  function THavizaras.FormKiir(_in: integer):string;
// =============================================================================
begin
  result := '          -';
  if _in=0  then exit;
  Result := ForintForm(_in);
  Result := EloKieg(Result,11);
end;

// =============================================================================
             function THavizaras.ForintForm(_osszeg:integer):string;
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
                   procedure Thavizaras.NyitoBeolvasas;
// =============================================================================

var i: byte;

begin

  for i := 1 to 27 do _nyito[i] := 0;

  ValdataDbase.Connected := true;

  _pcs := 'SELECT * FROM '+ _hztablanev;
  with ValdataQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
      _kezdijnyito := FieldByNAme('KEZDIJZARO').asInteger;
      _ekernyito   := FieldByNAme('EKERZARO').asInteger;
      _usdnyito    := FieldByNAme('USDZARO').asInteger;
      _hufnyito    := FieldByNAme('HUFZARO').asInteger;
      _afanyito    := FieldByNAme('AFAZARO').asInteger;
    end;

  while not ValdataQuery.Eof do
    begin
      with ValdataQuery do
        begin
          _aktdnem  := FieldByName('VALUTANEM').asString;
          _aktnyito := FieldByName('ZARO').asInteger;
        end;

      _xx := ScanDnem(_aktdnem);
      if _xx>0 then _Nyito[_xx] := _aktnyito;
      ValdataQuery.next;
    end;

  ValdataQuery.Close;
  valdatadbase.close;
end;


function ThaviZaras.ScanPtar(_pts: string): word;

var _y: word;

begin
  _pts := trim(_pts);
  if _ptdarab=0 then
    begin
      _ptdarab := 1;
      _ptsor[1] := _pts;
      result := 1;
      exit;
    end;

  _y := 1;
  while _y<=_ptdarab do
    begin
      if _ptsor[_y]=_pts then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;

  inc(_ptdarab);
  _ptsor[_ptdarab] := _pts;
  result := _ptdarab;
end;

procedure Thavizaras.adatnullazas;

begin
  _xx := 1;
  _yy := 1;

  while _xx<=27 do
    begin
      _atvetel[_xx] := 0;
      _atadas[_xx] := 0;
      _yy := 1;
      while _yy<=500 do
        begin
          _ptatadas[_xx,_yy] := 0;
          _ptatvetel[_xx,_yy] := 0;
          inc(_yy);
        end;
      inc(_xx);
    end;
  _ptdarab := 0;
end;          



end.
