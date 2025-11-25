unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, jpeg, dateutils, IBDatabase, DB,
  IBQuery, IBCustomDataSet, IBTable, strutils, excel97, comobj, activex,
  Grids, DBGrids;

type
  TJUTALEKFORM = class(TForm)
    Panel1                : TPanel;
    EvCombo               : TComboBox;
    HoCombo               : TComboBox;
    TolCombo              : TComboBox;
    Label1                : TLabel;
    IgCombo               : TComboBox;
    Label2                : TLabel;
    Label3                : TLabel;
    StartGomb             : TBitBtn;
    KilepoGomb            : TBitBtn;
    Shape1                : TShape;
    Image1                : TImage;
    Label4                : TLabel;
    VFejTabla             : TIBTable;
    VFejQuery             : TIBQuery;
    VFejDbase             : TIBDatabase;
    VFejTranz             : TIBTransaction;
    pTabla                : TIBTable;
    pQuery                : TIBQuery;
    pDbase                : TIBDatabase;
    pTranz                : TIBTransaction;
    jTabla                : TIBTable;
    jQuery                : TIBQuery;
    jDbase                : TIBDatabase;
    jTranz                : TIBTransaction;
    InfoPanel             : TPanel;
    BizonylatPanel        : TPanel;
    UzenoPanel            : TPanel;
    IrodaNevPanel         : TPanel;
    KilepoTimer           : TTimer;
    IrodaSzamPanel        : TPanel;
    rQuery                : TIBQuery;
    rDbase                : TIBDatabase;
    rTranz                : TIBTransaction;
    DisplayPanel          : TPanel;
    JutalekSource         : TDataSource;
    jRacs                 : TDBGrid;
    jTablaIDKod           : TIBStringField;
    jTablaPenztarosNev    : TIBStringField;
    jTablaPenztariForgalom: TIntegerField;
    jTablaWesternForgalom : TIntegerField;
    jTablaIrodaszam       : TSmallintField;
    jTablaIrodanev        : TIBStringField;
    jTablaTeljesForgalom  : TIntegerField;
    jTablaJutalek         : TIntegerField;
    jTablaJutalekSzorzo   : TSmallintField;
    jTablaJutalekMentes   : TIntegerField;
    jTablaKezelesiDij     : TIntegerField;
    FocimPanel            : TPanel;
    excelgomb: TBitBtn;
    KilepesGomb: TBitBtn;
    vTetQuery             : TIBQuery;
    vTetTranz             : TIBTransaction;
    vTetDbase             : TIBDatabase;
    sJutQuery             : TIBQuery;
    sJutTabla             : TIBTable;
    sJutDbase             : TIBDatabase;
    sJutTranz             : TIBTransaction;
    postapanel            : TPanel;
    SetSzorzoGomb         : TBitBtn;
    Panel2: TPanel;
    RCHANGE: TRadioButton;
    RZALOG: TRadioButton;
    Label5: TLabel;
    Label6: TLabel;
    EXITGOMB: TBitBtn;
    EXINFOCSIK: TPanel;

    procedure FormActivate(Sender: TObject);
    procedure EvcomboChange(Sender: TObject);
    procedure TolcomboChange(Sender: TObject);
    procedure NapComboToltes;
    procedure ArfolyamBeolvasas;
    procedure KilepoGombClick(Sender: TObject);
    procedure IgComboClick(Sender: TObject);
    procedure StartGombClick(Sender: TObject);
    procedure JutFreeBizonylatok;
    procedure BlokkNyitas;
    procedure JutalekSzamitas;
    procedure jParancs(_ukaz: string);
    procedure TaroltIdekBeolvasasa;
    procedure MakeExcelTabla;
    procedure Szorzoktombbe;
    procedure IrodakTombbe;
    procedure KilepoTimerTimer(Sender: TObject);
    procedure DisplayTablaKijelzes;
    procedure KilepesGombClick(Sender: TObject);
    procedure excelgombClick(Sender: TObject);
    procedure AdatAtadas;
    procedure JutalekOsszesites;
    procedure sJutParancs(_ukaz: string);
    procedure MakeSumExcel;
    procedure SetSzorzoGombClick(Sender: TObject);


    function Nulele(_int: integer): string;
    function JutalekFree(_biz: string): boolean;
    function ScanIdPt(_i: string;_p: byte): integer;
    function EzErtektar(_pt: byte): boolean;
    function ScanPros(_id: string):string;
    function GetKonvOsszeg(_bsz: string): integer;
    function CompareIDPros(_qId,_qpros: string): boolean;
    function Angolra(_huName: string): string;
    function HutoGb(_kod: byte): byte;
    procedure EXITGOMBClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  JutalekForm: TJutalekForm;

  _height,_width,_aktev,_aktho,_kertev,_kertho: word;
  _honev: array[1..12] of string = ('január','február','március','április',
           'május','június','július','augusztus','szeptember','október',
           'november','december');

  _hoindex,_evindex,_havinapok,_kerttol,_kertig,_nap: byte;
  _farok,_kezdonap,_utolsonap,_pcs,_aktfdbpath,_tipus,_idkod: string;
  _bftablanev,_wunitablanev,_narftablanev,_arfetablanev: string;
  _btTablanev,_bizonylatszam,_elojel,_vnem,_datum,_naps: string;
  _exPath,_aktptnev,_focim,_pnev,_bazis: string;
  _sorveg: string = chr(13)+chr(10);

   _tolnap,_ignap: byte;
  _idsequ: array[0..1500] of string;
  _sforg,_skezdij,_swuni,_sjutfree: array[0..1500] of integer;
  _idPointer,_osszeg,_kezdij,_bjegy,_elszar,_cc,_qq,_lastsor: integer;

  _usdarf : array[1..31] of integer;
  _jfreebiz: array[1..300] of string;
  _jfreebizdarab,_ftertek,_xx,_code,_recno,_xsor: integer;

  _penztar: byte;
  _ezJutFree,_vanexcel: boolean;

  _etarnum: array[1..9] of byte = (10,20,40,50,63,75,120,145,170);
  _taroltidDarab: integer;

  _taroltid,_taroltprosnev: array[1..1500] of string;
  _exceltabla,_sajatexcel,_range: variant;
  _prosnev,_ptnev,_fark: string;

  _ptszam,_ptforgalom,_kdij,_wuforg,_sumforg,_szorzo,_jut,_jutmentes: integer;
  _jutszorzo: array[1..170] of integer;
  _irodanevtomb: array[1..170] of string;

   _ctrlProsnev,_mess,_evhos: string;
  _aktsequ,_aktid,_aktprosnev: string;
  _aktkezdij,_aktwuni,_aktjutfree,_eddjut: integer;
  _jutalek,_aktpt,_aktforg,_jutalekdarab,_forgalomdarab: integer;
  _sqw: byte;
  _ezZalog: boolean;
  _startiroda,_endiroda: word;

function jutalekszorzo: integer; stdcall; external 'c:\receptor\newdll\jutszaz.dll' name 'jutalekszorzo';
function jutalekszamitorutin: integer;stdcall;

implementation

{$R *.dfm}


// =============================================================================
            function jutalekszamitorutin: integer;stdcall;
// =============================================================================

begin
  JutalekForm := Tjutalekform.create(Nil);
  result := jutalekform.showmodal;
  jutalekform.free;
end;




// =============================================================================
            procedure TJUTALEKFORM.FormActivate(Sender: TObject);
// =============================================================================

var i: integer;

begin
  _width  := screen.Monitors[0].Width;
  _height := Screen.Monitors[0].height;

  Top     := 80+Trunc((_height-613)/2);
  Left    := Trunc((_width-453)/2);
  Width   := 440;
  Height := 500;

  InfoPanel.Visible := false;
  Postapanel.Visible := False;

  // Az alapadatok alapra állítása:

  for i := 0 to 1500 do
    begin
      _sforg[i]   := 0;
      _swuni[i]   := 0;
      _skezdij[i] := 0;
      _sjutfree[i]:= 0;
      _idsequ[i]  := '00000';
    end;

  SzorzokTombbe;

  // Beolvassa a Penztarosok táblából a  Taroltid, taroltprosnev tömbök adatait

  TaroltIdekBeolvasasa;

  _idpointer := 0;
  _vanexcel  := False;

  // A naptar comboinak feltöltése:

  Evcombo.Items.clear;
  Hocombo.Items.clear;

  Tolcombo.clear;
  Igcombo.clear;

  _aktev := yearof(date);
  _aktho := monthof(date);

  Evcombo.Items.Add(inttostr(_aktev-1));
  Evcombo.Items.Add(inttostr(_aktev));

  for i := 1 to 12 do hocombo.Items.add(_honev[i]);

  Evcombo.ItemIndex := 1;
  Hocombo.ItemIndex := _aktho-1;

  NapComboToltes;
end;


// =============================================================================
                 procedure TjutalekForm.NapCOmboToltes;
// =============================================================================

var i: integer;

begin
  _hoindex := Hocombo.itemindex;
  _evindex := Evcombo.itemindex;

  _kertev := _aktev-1+_evindex;
  _kertho := _hoindex+1;
  _havinapok := daysinamonth(_kertev,_kertho);

  tolcombo.Items.Clear;
  igcombo.Items.clear;

  for i := 1 to _havinapok do
    begin
      tolcombo.items.add(inttostr(i));
      igcombo.items.add(inttostr(i));
    end;

  tolcombo.ItemIndex := 0;
  igcombo.ItemIndex := _havinapok-1;
  Activecontrol := startgomb;
end;


// =============================================================================
            procedure TJUTALEKFORM.STARTGOMBClick(Sender: TObject);
// =============================================================================

var _vProsnev,_items: string;
    _ixx : integer;

begin
  // Az idõ-intervallum meghatározása:

  _ezZalog := False;
  if RZalog.Checked then _ezzalog := True;

  IrodakTombbe;  

  _kertev := _aktev-1+evcombo.itemindex;
  _kertho := 1+hocombo.itemindex;
  _tolnap := 1+tolcombo.itemindex;
  _ixx    := igcombo.itemindex;
  _items  := igcombo.items[_ixx];
  _ignap  := strtoint(_items);

  _evhos  := inttostr(_kertev)+'-'+nulele(_kertho);

  with Infopanel do
    begin
      Top := 328;
      Left := 8;
      Visible := True;
    end;

  // A hónap ismeretében a változók kialakítása:

  _farok        := inttostr(_kertev-2000)+nulele(_kertho);
  _kezdonap     := inttostr(_kertev)+'.'+nulele(_kertho)+'.'+nulele(_tolnap);
  _utolsonap    := leftstr(_kezdonap,8)+nulele(_ignap);
  _bftablanev   := 'BF' + _farok;
  _btTablanev   := 'BT' + _farok;
  _wunitablanev := 'WUNI' + _farok;
  _narftablanev := 'NARF' + _farok;
  _arfetablanev := 'ARFE' + _farok;

  // ---------------------------------------------------------------------------

  // Beolvassa minden egyes nap USD árfolyamát, (a WU jutalék érdekében)

  Arfolyambeolvasas;  // A napi usd árfolyamok 1..31

  // ---------------------------------------------------------------------------

  // A startirodatol az endirodáig megy végig a program:

   _penztar := _startiroda;
   while _penztar<=_endiroda do

     begin
       IrodaszamPanel.caption := inttostr(_penztar);
       IrodaszamPanel.repaint;

       _ptnev := _irodanevtomb[_penztar];
       if length(_ptnev)<5 then
         begin
           inc(_penztar);
           Continue;
         end;

       IrodanevPanel.Caption := _ptnev;
       Irodanevpanel.repaint;

       // Az értéktárakon átlép a program:

       if ezErtektar(_penztar) then
         begin
           inc(_penztar);
           continue;
         end;

       //  Ha nincs ilyen pénztár, akkor ezt is átlépi:

       _aktfdbPath := 'c:\receptor\database\v' + INTTOSTR(_penztar)+'.FDB';
       if not FileExists(_aktfdbPAth) then
         begin
           inc(_penztar);
           Continue;
         end;

       // HA nincs a kért hónapra blokkfejtábla, a pénztárt átlépi a program:

       vfejDbase.close;
       vfejdbase.DatabaseName := _aktfdbPath;
       vfejdbase.Connected := true;
       vfejtabla.close;

       vfejtabla.TableName := _bftablanev;

       if vfejtabla.Exists then
         begin

           // A kért hónap jutalékmentes bizonylatait tömbbe olvassa:

           _jfreebizDarab := 0;
           JutfreeBizonylatok;  // A 34-es engedménytipusu bizonylatszamok tömbbe olvasás

           // Most megnyitja a blokkok tábláját (storno=1,tipus=V-E-K,idõintervallum)

           vFEJdbase.close;

           Uzenopanel.Caption := 'Forgalmi adatok ...';
           Uzenopanel.repaint;

            // Létezõ pénztár, létezõ blokkfej tábláját megnyitja:


           blokknyitas;

           //  A megnyitott blokkokon végigmegy a program:

           while not vFejQuery.Eof do
             begin

               // A blokkok adatait változókba olvassa:

               with VFejQuery do
                 begin
                   _tipus         := FieldByName('TIPUS').asString;
                   _idKod         := FieldByName('IDKOD').asString;
                   _osszeg        := FieldByName('OSSZESEN').asInteger;
                   _kezdij        := abs(FieldbyName('KEZELESIDIJ').asInteger);
                   _vProsnev      := FieldByNAme('PENZTAROSNEV').asString;

                   _bizonylatszam := FieldByName('BIZONYLATSZAM').asString;
                 end;


               if _idkod='00000' then
                 begin
                   Vfejquery.next;
                   Continue;
                 end;

               _vProsnev := Angolra(_vProsnev);
               if not CompareIdpros(_idKod,_vProsnev) then
                 begin
                   Vfejtabla.close;
                   Vfejdbase.close;
                   ShowMessage('HIBÁS ID-KÓD: '+trim(_vprosnev)+' - '+_idKod);
                   ModalResult := 2;
                   Exit;
                 end;

               Bizonylatpanel.Caption := _bizonylatszam;
               BizonylatPanel.Repaint;

               // A konverzió esetén: a forintérték kétszerese számít !

               if (_tipus='K') THEN _osszeg := GetKonvOsszeg(_bizonylatszam);
                // and (_elojel='+') then _osszeg := _osszeg + trunc(2*_ftErtek);

               //  A bizonylatszám alapján megnézi, nem-e jutalékmentes a tranzakció ?

               _ezJutFree := JutalekFree(_bizonylatszam);

               // Az idkod és pénztár index alapján megkeresi az adat sorszámát:
               // A visszatérés a tömb indexét adja.
               // Az idpointer a következõ elemre mutat, ha ez egy új elem:
               //


               _xx := scanidpt(_idkod,_penztar);

               // Ha jutalékmentes ez a bizonylat, akkor itt summmázza
               // Ha nem, akkor a forgalom és kezelési dij tömbbe summázódik

               if _ezjutfree then _sjutfree[_xx] := _sJutfree[_xx] + _osszeg
                 else
                 begin
                   _sforg[_xx] := _sforg[_xx] + _osszeg;
                   _skezdij[_xx]:= _skezdij[_xx] + _kezdij;
                 end;

               // Jöhet a következõ bizonylat:

               VFejquery.next;
             end;

           // Az összes valutaváltó bizonylat be van itt summázva a tömbökbe:

           VFejquery.close;
           vFejdbase.close;
         end

         //  Nincsen ennek a péntárnak a kért havi blokkfejtáblája
         // Igy jöhet a következõ pénztár:

         else
         begin
           vFejdbase.close;
           inc(_penztar);
           continue;
         end;

       // ----------------------------------------------------------------------

       //  A Western Union jutalékok kiszámítása, illetve tömbbe gyüjtése:

       vFejdbase.connected := True;
       vFejtabla.TableName := _wunitablanev;

       // Ha ennek a pénztárnak van Western Unionja, akkor kigyüjti az afatokat

       if vFejtabla.Exists then
         begin
           Uzenopanel.Caption := 'Western Union adatok ...';
           Uzenopanel.repaint;

           // Megnyitja a WUNIyymm táblát napintervallumban,storno=1
           // ugyfeltipus='U' feltételekkel:

           _pcs := 'SELECT * FROM ' + _wunitablanev + _sorveg;
           _pcs := _pcs + 'WHERE (STORNO=1) AND (DATUM BETWEEN '+ chr(39)+_kezdonap;
           _pcs := _pcs + chr(39) + ' AND ' + chr(39)+ _utolsonap + chr(39) + ')';
           _pcs := _pcs + ' AND (UGYFELTIPUS='+chr(39)+'U'+chr(39)+')';

           with vFejQuery do
             begin
               Close;
               Sql.clear;
               sql.add(_pcs);
               Open;
               First;
             end;

           // Végig megy az összes rekordokon:

           while not vFejquery.eof do
             begin
               with vFejQuery do
                 begin
                   _idkod := FieldByName('IDKOD').asstring;
                   _vnem  := FieldByName('VALUTANEM').asstring;
                   _bjegy := FieldByName('BANKJEGY').asInteger;
                   _datum := FieldByName('DATUM').asstring;
                   _vprosnev := FieldByNAme('PENZTAROSNEV').asString;
                 end;

               if _idkod='00000' then
                 begin
                   vfejquery.next;
                   Continue;
                 end;

               _vProsnev := Angolra(_vProsnev);

               if not CompareIdpros(_idKod,_vProsnev) then
                 begin
                   Vfejtabla.close;
                   Vfejdbase.close;
                   ShowMessage('HIBÁS ID-KÓD: '+trim(_vprosnev)+' - '+_idKod);
                   ModalResult := 2;
                   Exit;
                 end;

               //  A dátumból kiszedi a napot:

               _naps := midstr(_datum,9,2);
               val(_naps,_nap,_code);
               if _code<>0 then _nap := 1;

               // Ha a tranzakció forintban van az összeg a banykjegy mezõ
               // Ha dollárban van, akkor átszámítja forintra

               if _vnem='HUF' then _osszeg := _bjegy
               else _osszeg := trunc(_usdarf[_nap]*_bjegy/100);

               // Megkeresi a idkod-penztar indexet

               _xx := scanidpt(_idkod,_penztar);

               // A tömbbe begyüjti a wu forgalmat az index alapjáb

               _sWuni[_xx] := _swuni[_xx] + _osszeg;

               // Jöhet a következö wu. bizonylat:

               vFejquery.next;
             end;

           // A Wu bizonylatok be vannak itt summázva a _swuni tömbbe:

           vFejquery.close;
           vFejdbase.close;
         end;

       // ----------------------------------------------------------------------

       //  Jöhet a következõ pénztár:

       inc(_penztar);
     end;

  Uzenopanel.Caption := 'Adatgyüjtés kész !';
  Uzenopanel.repaint;
  Sleep(2500);

  Uzenopanel.Caption := 'A jutalék számítás megkezdése ...';
  Uzenopanel.repaint;

  // A szorzók és összegek alapján kiszámitja a fejekre szánt jutalékokat:

  Jutalekszamitas;
  JutalekOsszesites;

  // ---------------------------------------------------------------------------

//  Uzenopanel.Caption := 'Exceltábla létrehozása ...';
//  Uzenopanel.repaint;

  // Az adatok alapján exceltáblát készít:

//  MakeExcelTabla;

  Infopanel.Visible := False;
  DisplaytablaKijelzes;
end;



// =============================================================================
               procedure TJUTALEKFORM.evcomboChange(Sender: TObject);
// =============================================================================

begin
  napcombotoltes;
end;

// =============================================================================
           procedure TJUTALEKFORM.tolcomboChange(Sender: TObject);
// =============================================================================


var i: integer;

begin
  _kerttol:= 1+tolcombo.itemindex;
  igcombo.items.clear;
  for i := _kerttol to _havinapok do igcombo.Items.add(inttostr(i));
  igcombo.ItemIndex := _havinapok-_kerttol;
  activecontrol := Startgomb;
end;

// =============================================================================
              procedure TJUTALEKFORM.KILEPOGOMBClick(Sender: TObject);
// =============================================================================

begin
   Kilepotimer.Enabled := true;
end;

// =============================================================================
            procedure TJUTALEKFORM.igcomboClick(Sender: TObject);
// =============================================================================

begin
  Activecontrol := Startgomb;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$



// =============================================================================
                 procedure TJutalekform.DisplayTablaKijelzes;
// =============================================================================

begin

  Left := Trunc((_width-865)/2);
  width := 865;

  _focim:= 'DOLGOZÓK JUTALÉKA ' + inttostr(_kertev)+' '+_HONEV[_kertho]+' ';
  _focim := _focim + inttostr(_tolnap)+'-'+inttostr(_ignap)+' KÖZÖTT';

  Focimpanel.caption := _focim;
  FocimPanel.Repaint;

  Height := 610;
  width := 870;

  Jdbase.Connected := true;
  jtabla.open;
  with displayPanel do
    begin
      Left := 8;
      Top := 16;
      Height := 555;
      Width := 850;
      Visible := True;
    end;
  Activecontrol := Jracs;
end;

// =============================================================================
                 procedure TJutalekform.ArfolyamBeolvasas;
// =============================================================================

var i: integer;

begin
  for i := 1 to 31 do _usdarf[i] := 0;

  // A szegedi értéktárból olvassa a havi USD árfolyamokat;

  _pcs := 'SELECT * FROM ' + _narfTablaNev + _sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM='+chr(39)+'USD'+chr(39);


  // A szegedi értéktár adatait olvassa be ( Miért ? csak !)

  vFejDbase.close;
  vFejdbase.databasename := 'c:\receptor\database\v20.fdb';
  vFejdbase.connected := true;
  with vFejquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  // A napi USD árfolyamok az _USDARF 1..31 tömbbe kerülnek

  while not vFejquery.eof do
    begin
      _datum := vFejquery.fieldbyname('DATUM').asstring;
      _elszar := vFejquery.FieldByname('ELSZAMOLASIARFOLYAM').asInteger;
      _naps := midstr(_datum,9,2);
      val(_naps,_nap,_code);
      if _code<>0 then _nap := 1;
      _usdarf[_nap] := _elszar;
      vFejQuery.next;
    end;
  vFejquery.close;
  vFejdbase.close;
end;


// =============================================================================
                 procedure tJutalekform.JutfreeBizonylatok;
// =============================================================================

var _biz: string;
    _etip,_ujfree: word;

begin

  vFejdbase.connected := true;
  vFejtabla.close;
  vFejtabla.TableName := _arfetablaNev;
  if not vFejtabla.Exists then
    begin
      _jFreebizdarab := 0;
      vFejdbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+_arfeTablanev;
//  _pcs := _pcs + 'WHERE ENGEDMENYTIPUS=34';
  _jfreeBizdarab := 0;


  with vFejQuery do
    begin
      Close;
      Sql.clear;
      sql.Add(_pcs);
      Open;
      first;
    end;
  _cc := 0;
  while not vFejquery.Eof do
    begin
      _biz := VFejQuery.fieldByName('BIZONYLATSZAM').asString;
      _etip:= VfejQuery.FieldByname('ENGEDMENYTIPUS').asInteger;
      _ujfree := _etip AND 128;
      IF (_ujfree>0) or (_etip=34) then
        begin
          inc(_cc);
          _jfreebiz[_cc] := _biz;
        end;
      vFejQuery.next;
    end;
  _jfreeBizDarab := _cc;
  vFejquery.close;
  vFejdbase.close;
end;


// =============================================================================
          function TJutalekform.nulele(_int: integer): string;
// =============================================================================

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;


// =============================================================================
                      procedure TJUtalekform.BlokkNyitas;
// =============================================================================

begin
  

  vfejdbase.connected := true;
  _pcs := 'SELECT * FROM '+ _bftablanev + _sorveg;
  _pcs := _pcs + 'WHERE (STORNO=1) AND ((TIPUS='+chr(39)+'V'+CHR(39)+')';
  _pcs := _pcs + ' OR (TIPUS='+chr(39)+'E'+CHR(39)+')';
  _pcs := _pcs + ' OR (TIPUS='+chr(39)+'K'+chr(39)+'))';
  _pcs := _pcs + ' AND (DATUM BETWEEN '+ chr(39)+_kezdonap;
  _pcs := _pcs + chr(39) + ' AND ' + chr(39)+ _utolsonap + chr(39) + ')';

  with vFejquery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;
end;


// =============================================================================
            function TJutalekForm.Jutalekfree(_biz: string): boolean;
// =============================================================================

// Megadja, hogy a paraméterben adott bizonylat jutalékmentes-e

var _y: byte;

begin
  result := false;
  if _jFreeBizdarab=0 then exit;

  _y := 1;
  while _y<=_jfreeBizDarab do
    begin
      if _jFreeBiz[_y]=_biz then
        begin
          result := true;
          exit;
        end;
      inc(_y);
    end;
end;


// =============================================================================
       function TJutalekform.Scanidpt(_i: string;_p: byte): integer;
// =============================================================================

var _y: integer;
    _both,_is: string;

begin
   result := _idpointer;
   _is := trim(_i);

   if length(_is)<5 then
     begin
      // Uzenopanel.Caption := 'HIBÁS ID-KÓD !: '+_IS;
      // UzenoPanel.repaint;
       SLEEP(30);
       exit;
     end;

  // Az összetett index = idkod+penztár (pl: both='05022'+'50'= '0502250'
  _both := _i + inttostr(_p);

  // Ha ez a legelsõ index ,akkor ez a nulladik elem a tömbben.

  if _idPointer=0 then
    begin
      _idsequ[0] := _both;
      _idpointer := 1;

      Result := 0;
      exit;
    end;

  _y := 0;
  while _y<_idpointer do
    begin
      if _idsequ[_y]=_both then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
  _idsequ[_idPointer] := _both;
  Result := _idPointer;
  inc(_idpointer);
end;


// =============================================================================
              function TJutalekform.ezertektar(_pt: byte): boolean;
// =============================================================================

// Megadja, hogy a paraméterben adott péntárszám értéktár száma-e


var _y: byte;

begin
   _y := 1;
   result := false;
   if _pt=34 then
     begin
       result := true;
       exit;
     end;
       
   while _y<=8 do
     begin
       if _etarnum[_y]=_pt then
         begin
           result := True;
           exit;
         end;
       inc(_y);
     end;
end;

// =============================================================================
                  procedure TJutalekForm.JutalekSzamitas;
// =============================================================================

begin

  // A forgalom tábla nullázása:

  _pcs := 'DELETE FROM PENZTAROSFORGALOM';
  jParancs(_pcs);

  // Az összes indexelt tömbadaton végigmegyünk:

  _qq := 0;
  while _qq<_idpointer do
    begin

      // Az Idkod + pénztár index ---> _idsequ tömbben van:

      // Az aktuális tömbböt szétbontja aktid és aktpt részekre:

      _aktsequ  := _idsequ[_qq];
      _sqw      := length(_aktsequ);
      _aktid    := leftstr(_aktsequ,5);
      _aktpt    := strtoint(midstr(_aktsequ,6,_sqw-5));
      _aktptnev := _irodanevtomb[_aktpt];

      // Az indexhez tartozó forgalmi adatokat változókba tölti:

      _aktforg    := _sforg[_qq];
      _aktkezdij  := _skezdij[_qq];
      _aktwuni    := _swuni[_qq];
      _aktjutfree := _sJutfree[_qq];

      // Az idkod alapján, meghatározza a pénztáros nevét:

      _aktprosnev := scanpros(_aktid);

      // Az összes forgalom a váltóforgalom + wetern forgalom + kezelési díj

      _sumforg := _aktforg + _aktwuni + _aktkezdij;

      // Megkapja a pénztárhoz tartozó százezredes szorzót:

      _szorzo := _jutszorzo[_aktpt];

      //  Végül kiszámítja a pénztárosnak járó jutalék összegét:

      _jutalek := round(_sumforg/100000*_szorzo);


      // Az összes meghatározott adatot beirja egy rekordba, a forgalom táblába:

      _pcs := 'INSERT INTO PENZTAROSFORGALOM (IDKOD,PENZTAROSNEV,PENZTARIFORGALOM,';
      _pcs := _pcs + 'WESTERNFORGALOM,JUTALEKMENTES,KEZELESIDIJ,IRODANEV,';
      _pcs := _pcs + 'IRODASZAM,TELJESFORGALOM,JUTALEKSZORZO,JUTALEK)' + _sorveg;

      _pcs := _pcs + 'VALUES (' + CHR(39) + _AKTID + chr(39) + ',';
      _pcs := _pcs + chr(39) +  _aktprosnev + chr(39) + ',';
      _pcs := _pcs + inttostr(_aktforg) + ',';
      _pcs := _pcs + inttostr(_aktwuni) + ',';
      _pcs := _pcs + inttostr(_aktjutfree)+',';
      _pcs := _pcs + inttostr(_aktkezdij) + ',';
      _pcs := _pcs + chr(39) + _aktptnev + chr(39) + ',';
      _pcs := _pcs + inttostr(_aktpt) + ',';
      _pcs := _pcs + inttostr(_sumforg) + ',';
      _pcs := _pcs + inttostr(_szorzo) + ',';
      _pcs := _pcs  + inttostr(_jutalek) +')';

      jParancs(_pcs);

      // Jöhet a következõ sequ index:

      inc(_qq);
    end;
  Jdbase.Connected := True;
  with JQuery do
    begin
      Close;
      sql.clear;
      Sql.add('SELECT * FROM PENZTAROSFORGALOM');
      Open;
      Last;
      _forgalomdarab := Recno;
      Close;
    end;
  Jdbase.Close;


end;

// =============================================================================
             procedure TJutalekForm.jParancs(_ukaz: string);
// =============================================================================

begin
  jdbase.connected := true;
  if jtranz.InTransaction then jtranz.commit;
  jtranz.StartTransaction;
  with jquery do
    begin
      Close;
      sql.clear;
      Sql.Add(_ukaz);
      Execsql;
    end;
  jtranz.commit;
  jdbase.close;
end;


// =============================================================================
                      procedure TJutalekform.Szorzoktombbe;
// =============================================================================

begin
  _pcs := 'SELECT * FROM JUTALEKSZORZO';
  JDbase.Connected := True;
  with Jquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  while not jQuery.eof do
    begin
      _ptszam := jQuery.fieldbyname('IRODASZAM').asInteger;
      _szorzo := jQuery.fieldbyname('JUTALEKSZORZO').asInteger;

      _jutszorzo[_ptszam] := _szorzo;
      jQuery.next;
    end;
  jQuery.close;
  jDbase.close;
end;

// =============================================================================
            function TJutalekform.Scanpros(_id: string):string;
// =============================================================================

var _y: integer;

begin
  _y := 1;
  result := '?';
  while _y<=_taroltidDarab do
    begin
      if _taroltid[_y]=_id then
        begin
          result := _taroltprosnev[_y];
          exit;
        end;
      inc(_y);
    end;
end;


// =============================================================================
               procedure TJutalekForm.TaroltidekBeolvasasa;
// =============================================================================

var _psn: string;

begin

  Pdbase.Connected := true;

  with pquery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM PENZTAROSOK');
      Open;
      First;
    end;

  _cc := 1;
  while not pQuery.eof do
    begin
      _taroltid[_cc]      := pquery.Fieldbyname('IDKOD').asString;
      _psn := pquery.FieldByName('PENZTAROSNEV').asString;
      _taroltprosnev[_cc] := Angolra(_psn);
      inc(_cc);
      pquery.next;
    end;

  _taroltIdDarab := _cc;

  Pquery.close;
  Pdbase.close;
end;

// =============================================================================
                  PROCEDURE TJutalekForm.MakeExcelTabla;
// =============================================================================

begin
  _expath := 'c:\receptor\mail\posta\jutalek\best\jut_'+_farok+'.xls';

  if _ezZalog then _expath := 'c:\receptor\mail\posta\jutalek\zalog\jut_'+_farok+'.xls';

  if fileExists(_expath) then
         DeleteFile(_expath);

  _excelTabla := CreateOLEOBJECT('EXCEL.APPLICATION');
  _sajatexcel := _exceltabla.workbooks.add[1];
  _sajatexcel.Activate;

  _exceltabla.range['A1:A1'].Columnwidth := 11;
  _exceltabla.range['B1:B1'].Columnwidth := 32;
  _exceltabla.range['C1:C1'].Columnwidth := 6;
  _exceltabla.range['D1:D1'].Columnwidth := 25;
  _exceltabla.range['E1:E1'].Columnwidth := 12;
  _exceltabla.range['F1:F1'].Columnwidth := 12;
  _exceltabla.range['G1:G1'].Columnwidth := 12;
  _exceltabla.range['H1:H1'].Columnwidth := 12;
  _exceltabla.range['I1:I1'].Columnwidth := 8;
  _exceltabla.range['J1:J1'].Columnwidth := 12;
  _exceltabla.range['K1:K1'].Columnwidth := 12;

  _exceltabla.range['A1:K1'].Mergecells := true;
  _exceltabla.range['A1:K1'].Font.size := 14;
  _exceltabla.range['A1:K1'].Font.bold  := True;
  _exceltabla.range['A1:K1'].Font.Italic := true;
  _FOCIM := inttostr(_kertev)+' '+_honev[_kertho]+'i jutalékok (';
  if _ezZalog then _focim := _focim + 'zálog)'
  else _focim := _focim + 'best)';

  _exceltabla.cells[1,1] := _focim;

  _lastsor := _forgalomdarab+3;
  _range := 'A1:K'+inttostr(_lastsor);

  _exceltabla.range[_range].font.name := 'Calibri';
  _exceltabla.range[_range].font.size := 11;

  _range := 'A1:A' +inttostr(_lastsor);
  _exceltabla.range[_range].HorizontalAlignment := -4108;

  _range := 'C1:C' +inttostr(_lastsor);
  _exceltabla.range[_range].HorizontalAlignment := -4108;

  _range := 'I1:I' +inttostr(_lastsor);
  _exceltabla.range[_range].HorizontalAlignment := -4108;

  _range := 'E1:H' +inttostr(_lastsor);
  _exceltabla.range[_range].Numberformat := '### ### ###';

   _range := 'J1:K' +inttostr(_lastsor);
  _exceltabla.range[_range].Numberformat := '### ### ###';

   _range := 'A3:K3';
  _exceltabla.range[_range].Font.Bold := true;
  _exceltabla.range[_range].HorizontalAlignment := -4108;

  // ---------------------------------------------------
   (*
  _excelTabla.Range['A1:H1'].MergeCells := True;
  _excelTabla.Cells[1,1] := inttostr(_aktev)+' '+_honev[_aktho]+'I STORNOZOTT BIZONYLATOK';
  _excelTabla.Cells[1,1].Font.size := 14;
  _excelTabla.Cells[1,1].Font.Bold := True;
  _excelTabla.Cells[1,1].HorizontalAlignment := -4108;
  _XSOR := 3;
  *)

  _exceltabla.cells[3,1] := 'ID-KÓD';
  _exceltabla.cells[3,2] := 'A PÉNZTÁROS NEVE';
  _exceltabla.cells[3,3] := 'PT';
  _exceltabla.cells[3,4] := 'A PÉNZTÁR NEVE';
  _exceltabla.cells[3,5] := 'FORG.';
  _exceltabla.cells[3,6] := 'KEZDÍJ';
  _exceltabla.cells[3,7] := 'WU.FORG.';
  _exceltabla.cells[3,8] := 'JUTALAP';
  _exceltabla.cells[3,9] := 'SZORZÓ';
  _exceltabla.cells[3,10]:= 'JUTALÉK';
  _exceltabla.cells[3,11]:= 'J.MENTES';

  _xSor := 4;

  jdbase.Connected := true;
  _pcs := 'SELECT * FROM PENZTAROSFORGALOM' + _sorveg;
  _pcs := _pcs + 'ORDER BY IDKOD';
  with jQuery do
    begin
      Close;
      sql.Clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not JQuery.eof do
    begin
      with jQuery do
        begin
          _idkod      := FieldByName('IDKOD').asString;
          _prosnev    := trim(FieldByName('PENZTAROSNEV').asString);
          _ptszam     := FieldByName('IRODASZAM').asInteger;
          _ptnev      := trim(FieldByName('IRODANEV').AsString);
          _PTforgalom := Fieldbyname('PENZTARIFORGALOM').asInteger;
          _kdIj       := FieldByNAme('KEZELESIDIJ').asInteger;
          _wuforg     := FieldByNAme('WESTERNFORGALOM').asInteger;
          _sumforg    := FieldByNAme('TELJESFORGALOM').asInteger;
          _szorzo     := FieldByNAme('JUTALEKSZORZO').asInteger;
          _jut        := FieldByName('JUTALEK').asInteger;
          _jutmentes  := FieldByNAme('JUTALEKMENTES').asInteger;
        end;

      _exceltabla.cells[_xsor,1] := _idkod;
      _exceltabla.cells[_xsor,2] := _prosnev;
      _exceltabla.cells[_xsor,3] := inttostr(_ptszam);
      _exceltabla.cells[_xsor,4] := _ptnev;
      _exceltabla.cells[_xsor,5] := inttostr(_ptforgalom);
      _exceltabla.cells[_xsor,6] := inttostr(_kdij);
      _exceltabla.cells[_xsor,7] := inttostr(_wuforg);
      _exceltabla.cells[_xsor,8] := inttostr(_sumforg);
      _exceltabla.cells[_xsor,9] := inttostr(_szorzo);
      _exceltabla.cells[_xsor,10]:= inttostr(_jut);
      _exceltabla.cells[_xsor,11]:= inttostr(_jutmentes);
      inc(_xsor);
      jQuery.next;
    end;


  _range := 'A4:A4';
  _excelTabla.range[_range].select;
  _exceltabla.Activewindow.freezePanes := TRUE;;


  _sajatexcel.saveas(_expath);
  _exceltabla.quit;
  _excelTabla := unassigned;

end;

// =============================================================================
            procedure TJutalekForm.KILEPOTIMERTimer(Sender: TObject);
// =============================================================================

begin
  KilepoTimer.Enabled := false;
  if _vanexcel then
    begin
      _excelTabla.ActiveWorkBook.close;
      _sajatexcel := unassigned;
      _exceltabla.quit;
      _exceltabla := unassigned;
    end;
  Modalresult := 1;
end;


// =============================================================================
                procedure TJutalekform.Irodaktombbe;
// =============================================================================

var _i,i: integer;
    _n: string;

begin
  for i := 1 to 170 do _irodanevtomb[i] := '-';

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  if _ezZalog then
    begin
      _pcs := _Pcs + 'WHERE UZLET>150' + _sorveg;
      _startiroda :=151;
      _endIroda   := 168;
    end else
    begin
      _pcs := _pcs + 'WHERE UZLET<151' + _sorveg;
      _startiroda := 1;
      _endIroda   := 150;
    end;

  _pcs := _pcs + 'ORDER BY UZLET';

  rdbase.connected := true;
  with rQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  while not rQuery.Eof do
    begin
      _i := rQuery.FieldByName('UZLET').asInteger;
      _n := trim(rQuery.FieldByNAme('KESZLETNEV').asString);
      _irodaNevTomb[_i] := _n;
      rQuery.next;
    end;
  rQuery.close;
  rDbase.close;
end;


// =============================================================================
          procedure TJUTALEKFORM.KilepesGombClick(Sender: TObject);
// =============================================================================

begin
  Jtabla.close;
  jdbase.close;
  Modalresult := 1;
end;

// =============================================================================
           procedure TJUTALEKFORM.excelgombClick(Sender: TObject);
// =============================================================================

begin
  ExInfoCsik.Visible := True;
  MakeExcelTabla;
  MakeSumExcel;
  Adatatadas;
  ExInfoCsik.Visible := False;


  with Postapanel do
    begin
      Top := 132;
      Left := 210;
      Visible := True;
      Repaint;
    end;
//  KilepoTimer.Enabled := true;
end;


// =============================================================================
            function TJutalekform.GetkonvOsszeg(_bsz: string): integer;
// =============================================================================


var _tetossz: integer;

begin
  vtetdbase.close;
  vtetdbase.databasename := _aktfdbPath;
  vtetdbase.connected := true;

  _pcs := 'SELECT * FROM ' + _btTablaNev + _sorveg;
  _pcs := _pcs + 'WHERE (BIZONYLATSZAM='+CHR(39)+_BSZ+chr(39)+') ';
  _pcs := _pcs + 'AND (ELOJEL='+chr(39)+'+'+CHR(39)+')';

  with vtetquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;
  result := 0;
  while not vtetquery.eof do
    begin
      _tetossz := vtetquery.fieldbyName('FORINTERTEK').asInteger;
      result := result + _tetossz;
      vtetquery.next;
    end;
  vtetquery.close;
  vtetdbase.close;
  result := trunc(2*result);
end;


// =============================================================================
                 procedure TJutalekForm.JutalekOsszesites;
// =============================================================================

begin
  _pcs := 'DELETE FROM JUTALEK';
  SJutParancs(_pcs);

  Jdbase.connected := true;
  with JQuery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM PENZTAROSFORGALOM');
      Open;
      First;
    end;

  while not Jquery.eof do
    begin
      _idkod := jquery.fieldByName('IDKOD').asstring;
      _pnev  := jquery.fieldByName('PENZTAROSNEV').asstring;
      _jutalek := jquery.fieldByName('JUTALEK').AsInteger;

      _pnev := Angolra(_pNev);

      _pcs := 'SELECT * FROM JUTALEK' + _sorveg;
      _pcs := _pcs + 'WHERE IDKOD=' + chr(39)+_idkod+chr(39);

      Sjutdbase.Connected := True;
      with Sjutquery do
        begin
          Close;
          Sql.clear;
          Sql.Add(_pcs);
          Open;
          _recno := recno;
        end;


      if _recno>0 then
        begin
          _eddjut := SjutQuery.fieldbyname('JUTALEK').asInteger;
          Sjutquery.close;
          Sjutdbase.close;

          _jutalek := _jutalek + _eddjut;
          _pcs := 'UPDATE JUTALEK SET JUTALEK='+inttostr(_jutalek)+_sorveg;
          _pcs := _pcs + 'WHERE IDKOD='+chr(39)+_idkod+chr(39);
        end else
        begin
          Sjutquery.close;
          Sjutdbase.close;

          _pcs := 'INSERT INTO JUTALEK (IDKOD,PENZTAROSNEV,JUTALEK)' + _sorveg;
          _pcs := _pcs + 'VALUES ('+ chr(39) + _idkod + chr(39) + ',';
          _pcs := _pcs + chr(39) + _pnev + chr(39) + ',';
          _pcs := _pcs + inttostr(_jutalek)+')';
        end;
      Sjutparancs(_pcs);
      Jquery.next;
    end;
  Jquery.close;
  Jdbase.close;

  Sjutdbase.Connected := true;
  with Sjutquery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM JUTALEK');
      Open;
      Last;
      _jutalekdarab := Recno;
      Close;
    end;
  Sjutdbase.close;
end;


// =============================================================================
              procedure TJUtalekform.Sjutparancs(_ukaz: string);
// =============================================================================

begin
  Sjutdbase.connected := True;
  if Sjuttranz.InTransaction then Sjuttranz.Commit;
  Sjuttranz.StartTransaction;
  with Sjutquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_ukaz);
      ExecSql;
    end;
  Sjuttranz.commit;
  Sjutdbase.close;
end;

// =============================================================================
                    PROCEDURE TJutalekForm.MakeSumExcel;
// =============================================================================

begin


  _expath := 'c:\receptor\mail\posta\jutalek\best\sjut_'+_farok+'.xls';

  if _ezZalog then _expath := 'c:\receptor\mail\posta\jutalek\zalog\sjut_'+_farok+'.xls';

  _excelTabla := CreateOLEOBJECT('EXCEL.APPLICATION');

  _sajatexcel := _exceltabla.workbooks.add[1];
  _sajatexcel.Activate;

  // ---------------------------------------------------
   (*
  _excelTabla.Range['A1:H1'].MergeCells := True;
  _excelTabla.Cells[1,1] := inttostr(_aktev)+' '+_honev[_aktho]+'I STORNOZOTT BIZONYLATOK';
  _excelTabla.Cells[1,1].Font.size := 14;
  _excelTabla.Cells[1,1].Font.Bold := True;
  _excelTabla.Cells[1,1].HorizontalAlignment := -4108;
  _XSOR := 3;
  *)


  _lastsor := _jutalekdarab+3;

  _range := 'A1:C'+inttostr(_lastsor);
  _exceltabla.range[_range].font.name := 'Times New Roman';
  _exceltabla.range[_range].font.size := 12;
  _exceltabla.range[_range].font.italic := True;

  _exceltabla.Range['A1:A1'].Columnwidth  := 12;
  _exceltabla.Range['B1:B1'].Columnwidth  := 37;
  _exceltabla.Range['C1:C1'].Columnwidth  := 12;

  _exceltabla.Range['A1:C1'].Font.size := 14;
  _exceltabla.Range['A1:C1'].Font.Bold := True;
  _exceltabla.Range['A1:C1'].Mergecells := True;
  
  _focim := inttostr(_kertev)+' '+_honev[_kertho]+'i összesitett jutalek';
  if _ezZalog then _focim := _focim + ' (zálog)'
  else _focim := _focim + ' (Best)';

  _exceltabla.cells[1,1] := _focim;

  _exceltabla.range['A3:C3'].Font.Bold := true;
  _exceltabla.range['A3:C3'].HorizontalAlignment := -4108;

  _exceltabla.range['A4:A'+inttostr(_lastsor)].HorizontalAlignment := -4108;
  _exceltabla.range['C4:C'+inttostr(_lastsor)].HorizontalAlignment := -4108;
  _exceltabla.range['C4:C'+inttostr(_lastsor)].Numberformat := '### ### ###';

  _exceltabla.cells[3,1] := 'ID-KÓD';
  _exceltabla.cells[3,2] := 'A PÉNZTÁROS NEVE';
  _exceltabla.cells[3,3]:= 'JUTALÉK';

  _xSor := 4;

  sjutdbase.Connected := true;
  _pcs := 'SELECT * FROM JUTALEK' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAROSNEV';
  with SjutQuery do
    begin
      Close;
      sql.Clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not sJutQuery.eof do
    begin
      with sjutQuery do
        begin
          _idkod   := FieldByName('IDKOD').asString;
          _prosnev := FieldByName('PENZTAROSNEV').asString;
          _jut     := FieldByName('JUTALEK').asInteger;
        end;

      _exceltabla.cells[_xsor,1] := _idkod;
      _exceltabla.cells[_xsor,2] := _prosnev;
      _exceltabla.cells[_xsor,3]:= inttostr(_jut);
      inc(_xsor);
      sjutQuery.next;
    end;

  _range := 'A4:A4';
  _excelTabla.range[_range].select;
  _exceltabla.Activewindow.freezePanes := True;

  DeleteFile(_expath);
  _sajatexcel.saveas(_expath);
  _excelTabla.quit;
  _excelTabla := unassigned;
end;


// =============================================================================
      function TJutalekForm.CompareIDPros(_qId,_qpros: string): boolean;
// =============================================================================

var
    _wqp: integer;

begin
  result := False;
  _ctrlProsnev := Scanpros(_qId);
  _qpros := trim(_qpros);
  _wqp := length(_qpros);
  if _wqp>10 then _wqp := 10;
  _ctrlProsnev := leftstr(_ctrlProsnev,_wqp);
  _qpros := leftstr(_qpros,_wqp);
  if _ctrlProsnev=_qpros then result := true
  else begin
    _mess := 'Hibás pénztárosnév: '+_ctrlProsnev+'<>'+_qpros;
    Showmessage(_mess);
  end;
end;


// =============================================================================
                  procedure TJutalekform.Adatatadas;
// =============================================================================

var _tranzfile,_tranzpath,_ids,_datasor: string;
    _jut,_id: integer;
    _textiras: TextFile;

begin
  _tranzfile := 'Jut_'+_farok+'.csv';
  _tranzpath := 'c:\receptor\mail\posta\jutalek\best\' + _tranzfile;
  if _ezZalog then
        _tranzpath := 'c:\receptor\mail\posta\jutalek\zalog\' + _tranzfile;

  Assignfile(_textiras,_tranzpath);
  Rewrite(_textiras);

  _pcs := 'SELECT * FROM JUTALEK' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAROSNEV';

  Sjutdbase.connected := true;
  with SjutQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;
  while not SjutQuery.Eof do
    begin
      with Sjutquery do
        begin
          _ids     := trim(FieldByName('IDKOD').asString);
          _prosnev := FieldByName('PENZTAROSNEV').AsString;
          _jut     := FieldByName('JUTALEK').asInteger;
        end;
      val(_ids,_id,_code);
      _prosnev := Angolra(_prosnev);

      if _code<>0 then _id := 0;
      _datasor := inttostr(_id)+';'+_prosnev+';'+inttostr(_jut)+';'+_evhos;
      writeln(_textiras,_datasor);
      Sjutquery.next;
    end;
  closeFile(_textiras);

  Sjutquery.close;
  Sjutdbase.close;
end;

// =============================================================================
            procedure TJUTALEKFORM.SETSZORZOGOMBClick(Sender: TObject);
// =============================================================================

begin
  jutalekszorzo;
end;

//                   KISEGITO FUNKCIOK, PROGRAMOK
// =============================================================================
                 function TJUTALEKFORM.Angolra(_huName: string): string;
// =============================================================================

var _whn,_z,_asc: byte;

begin
  result  := '';

  _huname := uppercase(trim(_huname));
  _whn    := length(_huname);

  if _whn=0 then exit;

  _z := 1;
  while _z<=_whn do
    begin
      _asc := ord(_huname[_z]);
      _asc := HutoGb(_asc);

      result := result + chr(_asc);
      inc(_z);
    end;
end;


// =============================================================================
                   function TJUTALEKFORM.HutoGb(_kod: byte): byte;
// =============================================================================

var _r: byte;

begin
  _r := _kod;
  case _kod of
    186: _r := 69;  // E
    187: _r := 79;  // O
    193: _r := 65;  // A
    201: _r := 69;  // E
    211: _r := 79;  // O
    213: _r := 79;  // O
    214: _r := 79;  // O
    218: _r := 85;  // U
    219: _r := 85;  // U
    220: _r := 85;  // U
    222: _r := 65;  // A
    226: _r := 73;  // I
    205: _r := 73;  // I

    225: _r := 97;  // a
    233: _r := 101; // e
    237: _r := 105; // i
    243: _r := 111; // o
    246: _r := 111; // o
    245: _r := 111; // o
    250: _r := 117; // u
    252: _r := 117; // u
    251: _r := 117; // u
  end;
  result := _r;
end;




procedure TJUTALEKFORM.EXITGOMBClick(Sender: TObject);
begin
  KilepoTimer.Enabled := true;
end;

end.
