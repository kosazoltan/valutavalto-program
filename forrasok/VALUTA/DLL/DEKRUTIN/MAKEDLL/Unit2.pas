unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, strUtils, IBDatabase, DB, IBCustomDataSet, IBQuery,
  IBTable, printers, Buttons, Dateutils, ExtCtrls;

type
  TDekadRutin = class(TForm)

    DekadOkEGomb: TBitBtn;
    MegsemGomb  : TButton;

    NaploQuery  : TIBQuery;
    NaploDbase  : TIBDatabase;
    NaploTranz  : TIBTransaction;

    ValutaQuery : TIBQuery;
    ValutaDbase : TIBDatabase;
    ValutaTranz : TIBTransaction;

    ValdataQuery: TIBQuery;
    ValdataDbase: TIBDatabase;
    ValdataTranz: TIBTransaction;
    ValdataTabla: TIBTable;

    EvCombo     : TComboBox;
    HoCombo     : TComboBox;
    DekadCombo  : TComboBox;

    Label3      : TLabel;
    Shape2      : TShape;

    procedure BfKiolvasas;
    procedure DekadNyomtatas;
    procedure DekadOkeGombClick(Sender: TObject);
    procedure DekadParancs(_ukaz: string);
    procedure DosKozep(_txt: string);
    procedure EvComboChange(Sender: TObject);
    procedure ForgalomBeolvasas(_kkezdonap: string);
    procedure FormActivate(Sender: TObject);
    procedure MegsemGombClick(Sender: TObject);
    procedure PenztarAdatBeolvaso;
    procedure RekordFeliras;
    procedure StartDekadszamitas;
    procedure VonalHuzas;

    function Form11(_int: integer): string;
    function FtFormalo(_ft: integer): string;
    function GetControlZaro(_das: string): integer;
    function GetKezdoNap(_xev,_xho,_xdekad: word): string;
    function GetKezdoSorszam(_wnaps: string):word;
    function GetNapiCImlet(_aNap: string): integer;
    function GetnyitoForint(_das: string): integer;
    function GetVegsoNap(_ns: string): string;
    function NulEle(_n: byte): string;
    function NulKieg(_i,_hh: integer): string;
    function PtarKepzo(_pts: string): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DEKADRUTIN: TDEKADRUTIN;

  _honev: array[1..12] of string  = ('JANUAR','FEBRUAR','MARCIUS','APRILIS','MAJUS',
                  'JUNIUS','JULIUS','AUGUSZTUS','SZEPTEMBER','OKTOBER','NOVEMBER',
                  'DECEMBER');

  _napnev: array[1..7] of string = ('hétfõ','kedd','szerda','csütörtök','péntek',
                   'szombat','vasárnap');

  _textiras : Textfile;
  _nyomtat  : Textfile;
  _textOlvas: Textfile;


  _xbiz,_xpts,_xnaps: array[1..80] of string;
  _xsum: array[1..80] of integer;
  _xsto: array[1..80] of byte;
  _xsordb: word;

  _voltvetel,_volteladas: boolean;

  _storno,_printer,_y,_feszkoz: byte;
  _aktsorszam,_aktev,_aktho,_aktnap,_aktdekad,_vegsosorszam: word;
  _kertev,_kertho,_kertdekad,_bebizdarab,_kibizdarab,_osszbizonylat: word;

  _code,_recno,_nyito,_zaro,_kezdosorszam,_utolsosorszam: integer;
  _osszbevetel,_osszkiadas,_vetel,_eladas,_seladas,_ctrlHuf,_osszeg: integer;
  _osszesen,_evindex,_hoindex,_dekadindex,_tnyito,_tzaro: integer;

  _pcs,_lastnap,_penztarkod,_penztarnev,_penztarcim,_focim,_farok: string;
  _bfejNev,_datum,_bizonylatszam,_tarspenztarkod,_cimtabla: string;
  _kertkezdonap,_kertvegsonap,_aktdatums,_kknap,_kvnap,_lezartnap: string;
  _fejTablaNev,_tetTablaNev,_cimTablanev,_aktbiz,_aktdnem: string;

  _sorveg : string = chr(13)+chr(10);
  _kotojel: string = '     -     ';

  _width,_height,_top,_left: word;
  _bankkartyas,_ctrecno,_ctzaro,_forint,_bjegy,_kerekites: integer;

  _evs,_hos,_elofarok,_hzTabla,_elojel,_mess: string;
  _eloev,_eloho: word;

  _btip,_tipus,_ptrs: string;
  _osszft: integer;


Function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll' name 'logirorutin';
function supervisorjelszo(_para: integer): integer; stdcall;
                       external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';

function forgalomdekad: integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
                function forgalomdekad: integer; stdcall;
// =============================================================================

begin
  Dekadrutin := TDekadrutin.Create(Nil);
  result := dekadrutin.showmodal;
  Dekadrutin.free;
end;


// =============================================================================
            procedure TDEKADRUTIN.FormActivate(Sender: TObject);
// =============================================================================

begin
  _width := screen.Monitors[0].Width;
  _height:= Screen.Monitors[0].height;

  _top := trunc((_height-203)/2);
  _left:= trunc((_width-611)/2);

  Top    := _top;
  Left   := _left;
  Height := 203;
  Width  := 611;

  PenztaradatBeolvaso;

  _aktev := yearof(date);
  _aktho := monthof(date);
  _aktnap:= dayof(date);

  _aktdatums := inttostr(_aktev)+'.'+nulele(_aktho)+'.'+nulele(_aktnap);
  _aktdekad:= 3;
  if _aktnap<11 then _aktdekad := 1 ELSE
  if _aktnap<21 then _aktdekad := 2;

  evcombo.Items.clear;
  evcombo.Items.Add(inttostr(_aktev-1));
  evcombo.Items.Add(inttostr(_aktev));
  evcombo.ItemIndex := 1;

  Hocombo.Items.clear;
  _y := 1;
  while _y<=12 do
    begin
      Hocombo.Items.Add(uppercase(_honev[_y]));
      inc(_y);
    end;

  Hocombo.ItemIndex := (_aktho-1);

  Dekadcombo.Items.clear;
  _y := 1;
  while _y<=3 do
    begin
      Dekadcombo.Items.add(inttostr(_y)+'. DEKÁD');
      inc(_y);
    end;

  DekadCombo.itemindex := _aktdekad-1;
  Repaint;
  Activecontrol := DekadOkeGomb;
end;

// =============================================================================
           procedure TDEKADRUTIN.DEKADOKEGOMBClick(Sender: TObject);
// =============================================================================

var _spk: integer;

begin
  _xsordb := 0;

  _evIndex := evcombo.itemindex;
  _hoindex := HoCombo.ItemIndex;
  _dekadindex := dekadcombo.ItemIndex;

  _kertev := _evindex+_aktev-1;
  _kertho := 1 + _hoindex;
  _kertdekad := 1 + _dekadindex;

  _kertkezdonap := GetKezdonap(_kertev,_kertho,_kertdekad);
  _kertvegsonap := Getvegsonap(_kertkezdonap);

  _mess := 'Tol-ig: '+_kertkezdonap+'-'+_kertvegsonap;
  logirorutin(pchar(_mess));

  if _kertkezdonap>_aktdatums then
    begin
      ShowMessage('A KÉRT DÁTUM A JÖVÕBEN LESZ !');
      ModalResult := 2;
      exit;
    end;

  // Dekád közepén kéri a nyomtatást
  if (_kertvegsonap>_aktdatums) then
    begin
      if _lezartnap='' then
         begin
           _pcs := 'SELECT * FROM BLOKKFEJ';
           valutadbase.connected := true;
           with ValutaQuery do
             begin
               Close;
               sql.clear;
               sql.add(_pcs);
               Open;
               _recno := recno;
               Close;
             end;
           Valutadbase.close;
           if _recno>0 then
             begin
               Showmessage('NINCS LEZÁRVA A MAI NAP');
               Modalresult := 2;
               exit;
             end;
         end;
      StartDekadszamitas;
      exit;
    end;

  if _kertvegsonap<_aktdatums then
    begin
      _spk := supervisorjelszo(0);
      if _spk<>1 then
        begin
          ModalResult := 2;
          exit;
        end;
    end;
  Startdekadszamitas;
end;

// =============================================================================
                 procedure TDekadrutin.StartDekadSzamitas;
// =============================================================================

var _uzenet: string;

begin
   logirorutin(pchar('Kezdödik a dekádszámitás'));

  _tnyito := GetNyitoForint(_kertkezdonap);
  _ctZaro := GetControlZaro(_kertvegsonap);
  _kezdosorszam := GetKezdosorszam(_kertkezdonap);

  _mess := 'Nyito/COntrol='+inttostr(_tnyito)+'/'+inttostr(_ctzaro);
  logirorutin(pchar(_mess));
  logirorutin(pchar('Kezdõsorszam: '+inttostr(_kezdosorszam)));

  if (_kezdosorszam=0) then
    begin
      Modalresult := 2;
      exit;
    end;

  ForgalomBeolvasas(_kertkezdonap);
  _vegsosorszam := _kezdosorszam + _xsordb-1;

  logirorutin(pchar('Vegsösorszám='+inttostr(_vegsosorszam)));

  if _voltvetel then inc(_vegsosorszam);
  if _volteladas then inc(_vegsosorszam);
  if _bankkartyas>0 then _vegsosorszam := _vegsosorszam + 2;

  logirorutin(pchar('Korrigált végsõ sorszám='+inttostr(_vegsosorszam)));

  _osszbevetel := 0;
  _osszkiadas  := 0;

  _y := 1;
  while _y<=_xsordb do
    begin
      _aktbiz := leftstr(_xbiz[_y],2);
      _forint := _xsum[_y];
      if _aktbiz='FF' then _osszkiadas := _osszkiadas + _forint
      else _osszbevetel := _osszbevetel + _forint;
      inc(_y);
    end;

  _osszbevetel := _osszbevetel  + _eladas;
  _osszkiadas  := _osszkiadas + _vetel;

  logirorutin(pchar('Összbe='+inttostr(_osszbevetel)+' Összki='+inttostr(_osszkiadas)));

  _tZaro := _tNyito + _osszBevetel - _osszKiadas;
  logirorutin(pchar('Tzáró='+inttostr(_tnyito)+'+'+inttostr(_osszbevetel)+'-'+inttostr(_osszkiadas)));

  if _ctzaro<>_tzaro then
    begin
      logirorutin(pchar('Záró<>CtrlZaro='+inttostr(_tzaro)+'<>'+inttostr(_ctzaro)));
      _uzenet := 'Nem egyezik a záró ('+inttostr(_tzaro)+'<>'+inttostr(_ctzaro);
      Showmessage(_uzenet);
      Modalresult := 2;
      exit;
    end;

  RekordFeliras;

  Dekadnyomtatas;
  ModalResult := 1;

end;


// =============================================================================
            function TDekadRutin.GetControlZaro(_das: string): integer;
// =============================================================================


begin
  _pcs := 'SELECT * FROM ' + _cimtabla + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM<=' + chr(39) + _das + chr(39) + ') ';
  _pcs := _pcs + 'AND (VALUTANEM='+CHR(39)+'HUF'+chr(39)+')' + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  ValdataDbase.connected := true;
  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      result := FieldByName('OSSZESFORINTERTEK').asInteger;
      Close;
    end;
  ValdataDbase.close;
  logirorutin(pchar(_cimtabla+'-ból beolvasott záró='+inttostr(result)));
end;


// =============================================================================
            function TDekadRutin.GetnyitoForint(_das: string): integer;
// =============================================================================


begin
  _farok := midstr(_das,3,2) + midstr(_das,6,2);
  _cimTabla := 'CIMT' + _farok;

  _pcs := 'SELECT * FROM ' + _cimtabla + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM<' + chr(39) + _das + chr(39) + ') ';
  _pcs := _pcs + 'AND (VALUTANEM='+CHR(39)+'HUF'+chr(39)+')' + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  ValdataDbase.connected := true;
  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
    end;

  if _recno>0 then
    begin
      result := ValdataQuery.FieldbyName('OSSZESFORINTERTEK').asInteger;
      ValdataQuery.close;
      ValdataDbase.close;
      exit;
    end;

  ValdataQuery.close;
  ValdataDbase.close;

  _evs := leftstr(_das,4);
  _hos := midstr(_das,6,2);

  val(_evs,_eloev,_code);
  val(_hos,_eloho,_code);

  dec(_eloho);
  if _eloho=0 then
    begin
      _eloho := 12;
      dec(_eloev);
    end;

  _elofarok := inttostr(_eloev-2000)+nulele(_eloho);
  _hztabla := 'HZ'+_elofarok;
  _pcs := 'SELECT * FROM ' + _hzTabla + _sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39) + 'HUF' + chr(39);

  ValdataDbase.connected := true;
  with VAldataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      result := FieldByNAme('ZARO').asInteger;
      close;
    end;
  ValdataDbase.close;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
// =============================================================================
// =============================================================================
                 procedure  TDekadrutin.DekadNyomtatas;
// =============================================================================


var _dekadPath,_istring,_aktnaps,_sortext,_akttipus,_ss,_mondat: string;
    _datumdekads: string;

begin

  _dekadPath := 'c:\valuta\aktlst.txt';
  AssignFile(_textIras,_dekadPath);
  Rewrite(_textIras);

  // Pénztár adatainak felirása:

  DosKozep(_penztarKod+'. PENZTAR');
  DosKozep(_penztarNev);
  DosKozep(_penztarCim);

  VonalHuzas;

  // Kiirja az év, hónap és dekád adataival a fõcímet:

  _focim := inttostr(_kertev)+' '+ uppercase(_honev[_kertho])+' HAVI ';
  _focim := _focim + chr(48+_kertDekad)+'. DEKADZARAS';
  DosKozep(_focim);

  // Kiirja a dekád idõ-intervallumát:

  _iString := _kertkezDonap + ' - ' + _kertvegsonap;
  Doskozep(_iString);

  VonalHuzas;

  // Adatok fejléce:

  WriteLn(_textiras,'Sor Np   Bizony.  Ft.atvetel   Ft.atadas');
  VonalHuzas;

   // A kezdõ sorszámmal indulnak az adatsorok:
  _aktSorszam := _kezdoSorszam;

  _y := 1;
  while _y<=_xsordb do
    begin
      _aktnaps        := _Xnaps[_y];
      _bizonylatszam  := _xbiz[_y];
      _osszeg         := _xsum[_y];
      _tarspenztarkod := _xpts[_y];
      _storno         := _xsto[_y];

       // Összeállit egy adatsort:

       _sorText := nulKieg(_aktSorszam,3)+' ' + _aktnaps + ' ' + _bizonylatSzam+' ';
       _akttipus := leftstr(_bizonylatszam,2);

       if _aktTipus = 'UF' then
         begin
           if _storno<>1 then _ss := '  storno bizonylat'
           else _ss := Form11(_osszeg)+ ' ' + ptarKepzo(_tarsPenztarKod);
         end else
         begin
            if _storno<>1 then _ss := '  storno bizonylat'
            else _ss := PtarKepzo(_tarsPenztarKod) + ' ' + Form11(_osszeg);
         end;

       _sortext := _sortext + _ss;
       writeLn(_textIras,_sorText);
       inc(_aktSorszam);
       inc(_y);
     end;

    dec(_aktsorszam);

   // A dekádjelentésbõl kiolvasott vétel sorát irja fel (ha volt vétel)

  if _vetel>0 then
     begin
       inc(_aktsorszam);
       _sorText := nulKieg(_aktSorszam,3)+'    V.vetel:   '+_kotoJel + ' '+ Form11(_vetel);
       writeLn(_textIras,_sorText);
     end;

   // A dekádjelentésbõl kiolvasott eladás sorát irja fel (ha volt eladás);

  if _VOLTeladas then
     begin
       inc(_aktsorszam);
       _sorText := nulKieg(_aktSorszam,3)+'     V.elad:   '+ Form11(_eladas)+' '+_kotoJel;
       writeLn(_textIras,_sorText);
     end;

  if _bankkartyas>0 then
    begin
      inc(_aktsorszam);
      _sortext := nulkieg(_aktsorszam,3)+' Bankkartya:   '+Form11(_bankkartyas)+' '+_kotojel;
      writeLn(_textiras,_sortext);
      inc(_aktsorszam);
      _seladas := _eladas + _bankkartyas;
      _sortext := nulkieg(_aktsorszam,3)+' Ossz. elad:   '+Form11(_seladas)+' '+_kotojel;
      writeLn(_textiras,_sortext);
    end;


   logirorutin(pchar('Aktsorszám/végsorszám ' + inttostr(_aktsorszam)+'/'+inttostr(_vegsosorszam)));

   if (_aktSorszam<>_vegsoSorszam) then
     begin
       logirorutin(pchar('Nem egyeznek a sorszámok. Kilépek'));
       CloseFile(_textIras);
       Showmessage('VALAMI HIBA VAN A SORSZÁMOK KÖRUL !');
       exit;
     end;

   VonalHuzas;

   // Az összesitõ sorok felirása:

   logirorutin(pchar('A dekádzárás kinyomtatása'));

   _sorText := 'Dekad forgalom:   ' + Form11(_osszBevetel)+' '+ Form11(_osszKiadas);
   writeLn(_textIras,_sorText);

   _sorText := '  Nyito forint:   ' + Form11(_tnyito) + ' ###########';
   writeLn(_textIras,_sorText);

   _sorText := '   Zaro forint:   ########### ' + form11(_tzaro);
   writeLn(_textIras,_sorText);

   _osszesen := _osszBevetel + _tnyito;

   _sorText := ' Osszes forint:   ' + form11(_osszesen)+' '+ form11(_osszesen);
   writeLn(_textIras,_sorText);

   VonalHuzas;

   // A dátum és aláirás felirása a lap aljára:

   writeLn(_textIras,_sorVeg);

   _sorText := _aktdatums + '     ' + dupestring('.',24);
   writeLn(_textIras,_sorText);

   _sorText := dupestring(chr(32),25)+ 'penztaros';
   writeLn(_textIras,_sorText);
   writeLn(_textIras,_sorVeg+_sorVeg+_sorVeg+chr(26));
   closefile(_textIras);

   // A dekádjelentés be van irva az AKTLST.TXT -be

   // ------------------------------------------------------

   // A dekádjelentés tényleges kinyomtatása:


   if _printer<>1 then AssignFile(_nyomtat,'LPT1')
   else assignprn(_nyomtat);
   Rewrite(_nyomtat);

   AssignFile(_textOlvas,'c:\valuta\aktlst.txt');
   Reset(_textOlvas);

   while not eof(_textOlvas) do
     begin
       readLn(_textOlvas,_mondat);
       writeLn(_nyomtat,_mondat);
     end;
   System.CloseFile(_nyomtat);
   System.CloseFile(_textOlvas);
  

   // $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
   //  Itt kell registrálni a nyomtatást a naplóban !!!
   // kertev, kertho, kertdekad

   _datumdekads := inttostr(_kertev)+nulele(_kertho)+ nulele(_kertdekad);
   _pcs := 'SELECT * FROM PRINTCONTROL WHERE DATUMDEKAD='
                                                +chr(39)+_datumdekads+chr(39);

   NaploDbase.Connected := true;
   if NaploTranz.InTransaction then Naplotranz.commit;
   Naplotranz.StartTransaction;

   with Naploquery do
     begin
       Close;
       Sql.clear;
       sql.Add(_pcs);
       Open;
       _recno := recno;
       close;
     end;

   // Ha nincs még bejegyzés a napra - akkor insert
   if _recno=0 then
     begin
       _pcs := 'INSERT INTO PRINTCONTROL (DEKADPRINT,KEZDIJPRINT,DATUMDEKAD)' +_sorveg;
       _pcs := _pcs + 'VALUES (1,0,';
       _pcs := _pcs + chr(39)+_datumdekads+chr(39)+')';
     end else
     begin
       _pcs := 'UPDATE PRINTCONTROL SET DEKADPRINT=1' + _sorveg;
       _pcs := _pcs + 'WHERE DATUMDEKAD='+chr(39)+_datumdekads+chr(39);
     end;

   with Naploquery do
     begin
       Close;
       sql.clear;
       sql.Add(_pcs);
       Execsql;
     end;
   Naplotranz.commit;
   naplodbase.close;
  exit;
end;

// =============================================================================
                        procedure TDekadRutin.VonalHuzas;
// =============================================================================

var _stext: string;

begin
  _stext := Dupestring('-',41);
  writeLn(_textiras,_stext);
end;

// =============================================================================
           function TDekadrutin.FtFormalo(_ft: integer): string;
// =============================================================================

var _wfts,_p1: integer;
    _fts: string;

begin
  Result := '       -        ';

  if _ft=0 then exit;

  _fts  := inttostr(_ft);
  _wFts := length(_fts);

  if _wFts>6 then
    begin
      _p1  := _wFts-6;
      _fts := leftstr(_fts,_p1)+'.'+midstr(_fts,_p1+1,3)+'.'+midstr(_fts,_p1+4,3);
    end else

    begin
      if _wFts>3 then
        begin
          _p1  := _wFts-3;
          _fts := leftstr(_fts,_p1)+'.'+midstr(_fts,_p1+1,3);
        end;
    end;

  while length(_fts)<11 do _fts := ' ' + _fts;
  Result := _fts + '.- Ft';
end;

// =============================================================================
                  function TDekadrutin.Nulele(_n: byte): string;
// =============================================================================

begin
  result := inttostr(_n);
  if _n<10 then result := '0' + result;
end;


// =============================================================================
              function TDekadRutin.NulKieg(_i,_hh: integer): string;
// =============================================================================

var _s: string;

begin
  _s := inttostr(_i);
  _s := trim(_s);
  while length(_s)<_hh do _s := '0' + _s;
  result := _s;
end;

// =============================================================================
                 procedure TDekadrutin.Doskozep(_txt: string);
// =============================================================================

var _ww,_oo: integer;

begin
  _txt := trim(_txt);
  _ww  := length(_txt);

  if _ww=0 then exit;

  _oo  := trunc((40-_ww)/2);
  _txt := dupestring(chr(32),_oo)+_txt;

  writeLn(_textiras,_txt);
end;

// =============================================================================
             function Tdekadrutin.Form11(_int: integer): string;
// =============================================================================

var _res: string;
    _wRes,_p1: integer;

begin

  Result := _kotojel;
  if _int=0 then exit;

  _res  := inttostr(_int);
  _wRes := length(_res);

  if _wres>6 then
    begin
      _p1 := _wRes-6;
      _res := leftstr(_res,_p1)+'.'+midstr(_res,_p1+1,3)+'.'+midstr(_res,_p1+4,3);
    end else
    begin
      if _wRes>3 then
        begin
          _p1 := _wRes-3;
          _res := leftstr(_res,_p1)+'.'+midstr(_res,_p1+1,3);
        end;
    end;
  while length(_res)<11 do _res := ' ' + _res;
  result := _res;
end;

// =============================================================================
          function Tdekadrutin.PtarKepzo(_pts: string): string;
// =============================================================================

begin
  result := '   ('+trim(_pts)+')';
  while length(result)<11 do result := result + ' ';
end;



procedure TDEKADRUTIN.MEGSEMGOMBClick(Sender: TObject);
begin
  Modalresult := 2;
end;





// =============================================================================
               procedure TDEKADRUTIN.EVCOMBOChange(Sender: TObject);
// =============================================================================

begin
  ActiveControl := DekadOkeGomb;
end;






// =============================================================================
                     procedure TDekadRutin.RekordFeliras;
// =============================================================================

begin
  _mess := 'Kitörli a DEKADJELENTES-böl ' +_kertkezdonap+'-i bejegytést';
  logirorutin(pchar(_mess));
  _pcs := 'DELETE FROM DEKADJELENTES' + _sorveg;
  _pcs := _pcs + 'WHERE KEZDONAP=' + chr(39) + _kertkezdonap + chr(39);

  DekadParancs(_pcs);

  _pcs := 'INSERT INTO DEKADJELENTES (DEKAD,KEZDONAP,UTOLSONAP,KEZDOSORSZAM,';
  _pcs := _pcs + 'UTOLSOSORSZAM,NYITO,OSSZBEVETEL,OSSZKIADAS,ZARO,';
  _pcs := _pcs + 'VETEL,ELADAS,BANKKARTYAS)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + inttostr(_kertdekad) + ',';
  _pcs := _pcs + chr(39) + _kertkezdonap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _kertvegsonap + chr(39) + ',';
  _pcs := _pcs + inttostr(_kezdosorszam) + ',';
  _pcs := _pcs + inttostr(_vegsosorszam) + ',';
  _pcs := _pcs + inttostr(_tNyito) + ',';
  _pcs := _pcs + inttostr(_osszbevetel) + ',';
  _pcs := _pcs + inttostr(_osszkiadas) + ',';
  _pcs := _pcs + inttostr(_tZaro) + ',';
  _pcs := _pcs + inttostr(_vetel) + ',';
  _pcs := _pcs + inttostr(_eladas) + ',';
  _pcs := _pcs + inttostr(_bankkartyas)+')';

  DekadParancs(_pcs);
  logirorutin(pchar('Bejegyzi a DEKADJELENTES-be '+_kertkezdonap+'-i tételt'));
end;

// =============================================================================
             procedure TDekadrutin.DekadParancs(_ukaz: string);
// =============================================================================

begin
  ValutaDbase.Connected := true;
  if ValutaTranz.InTransaction then ValutaTranz.Commit;
  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  ValutaTranz.Commit;
  ValutaDbase.close;
end;

// =============================================================================
           function TDekadrutin.GetNapiCImlet(_aNap: string): integer;
// =============================================================================

var _aFarok,_evs,_hos,_eFarok,_hznev: string;
    _eev,_eho: word;

begin
  result := 0;

  _aFarok := midstr(_aNap,3,2)+midstr(_aNap,6,2);
  _cimTablaNev := 'CIMT' + _aFarok;

  ValdataDbase.connected := True;
  ValdataTabla.tablename := _cimTablaNev;
  if not ValdataTabla.exists then
    begin
      ValdataDbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+ _cimTablanev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM<='+chr(39)+_aNap+chr(39)+') AND (';
  _pcs := _pcs + 'VALUTANEM='+chr(39)+'HUF'+CHR(39)+')'+_sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
    end;

  if _recno>0 then
    begin
      result := ValdataQuery.FieldbyName('OSSZESFORINTERTEK').asInteger;
    end;
  ValdataQuery.close;
  ValdataDbase.close;
  if _recno>0 then exit;

  _evs := leftstr(_aNap,4);
  _hos := midstr(_anap,6,2);

  val(_evs,_eev,_code);
  val(_hos,_eho,_code);

  dec(_eho);
  if _eho<1 then
    begin
      _eho:= 12;
      dec(_eev);
    end;


  _eFarok := inttostr(_eev-2000)+nulele(_eho);
  _hzNev := 'HZ' + _eFarok;

  ValdataDbase.Connected := true;
  ValdataTabla.close;
  ValdataTabla.TableName := _hzNev;
  if not ValdataTabla.Exists then
    begin
      ValdataDbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM ' + _HZnev + _SORVEG;
  _PCS := _pcs +'WHERE VALUTANEM=' + chr(39) + 'HUF' + chr(39);
  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      result := FieldByName('ZARO').asInteger;
      Close;
    end;
  ValdataDbase.close;

end;


// =============================================================================
                procedure TDekadRutin.PenztarAdatBeolvaso;
// =============================================================================

begin
  ValutaDbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      First;
      _penztarkod := trim(FieldByName('PENZTARKOD').AsString);
      _penztarnev := trim(FieldByName('PENZTARNEV').AsString);
      _penztarcim := trim(FieldByName('PENZTARCIM').AsString);
      close;
    end;

  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.Add('SELECT * FROM HARDWARE');
      Open;
      _printer := FieldByName('PRINTER').asInteger;
      _lezartnap := trim(Fieldbyname('LEZARTNAP').asstring);
      close;
    end;

  ValutaDbase.close;
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
// =============================================================================
      function TDekadrutin.GetKezdoNap(_xev,_xho,_xdekad: word): string;
// =============================================================================

var _xnap: word;

begin
  _xnap := 21;
  if _xdekad=1 then _xnap := 1;
  if _xdekad=2 then _xnap := 11;

  result := inttostr(_xev)+'.'+nulele(_xho)+'.'+nulele(_xnap);
end;

// =============================================================================
         function TDekadrutin.Getvegsonap(_ns: string): string;
// =============================================================================

var _qevs,_qhos,_qnaps: string;
    _qev,_qho,_holastDay: word;
    _qdekad: byte;

begin
  _qevs := leftstr(_ns,4);
  _qhos := midstr(_ns,6,2);
  _qnaps:= midstr(_ns,9,2);

  val(_qevs,_qev,_code);
  val(_qhos,_qho,_code);

  _qdekad := 3;
  if _qnaps='01' then _qdekad := 1;
  if _qnaps='11' then _qdekad := 2;

  if _qdekad=1 then _qnaps := '10';
  if _qdekad=2 then _qnaps := '20';
  if _qdekad=3 then
    begin
      _holastday := daysinamonth(_qev,_qho);
      _qnaps := inttostr(_holastday);
    end;

  result := inttostr(_qev)+'.'+nulele(_qho)+'.'+_qnaps;
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
// =============================================================================
          procedure Tdekadrutin.Forgalombeolvasas(_kkezdonap: string);
// =============================================================================

begin
  _kknap := _kkezdonap;
  _kvnap := _kertvegsonap;
  _farok   := midstr(_kknap,3,2) + midstr(_kknap,6,2);

  _FejTablaNev := 'BF' + _farok;
  _TetTablaNev := 'BT' + _farok;

 // ----------------------------------------------------------------------------

  _osszBevetel := 0;
  _osszKiadas  := 0;
  _beBizDarab
    := 0;
  _kiBizDarab  := 0;

  _osszBizonylat := 0;

  _voltVetel   := False;
  _voltEladas  := False;

  _vetel       := 0;
  _eladas      := 0;
  _bankkartyas := 0;

  // ---------------------------------------------------------------------------

  BfKiolvasas;

  // ---------------------------------------------------------------------------

  _osszBizonylat := _xsordb;
  if _voltVetel then inc(_osszBizonylat);
  if _voltEladas then inc(_osszBizonylat);
  if _bankkartyas>0 then _osszbizonylat := _osszbizonylat + 2;

end;

// =============================================================================
                     procedure TDekadRutin.BfKiolvasas;
// =============================================================================


begin
  // A BF farok havi gyüjtõ adatait olvassa be a dekád idõszaka alatt:

  _pcs := 'SELECT * FROM ' + _fejTablanev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM>=' + chr(39)+_kknap+chr(39)+')';
  _pcs := _pcs + ' AND (DATUM<=' + chr(39)+_kvnap+chr(39)+')' + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM,IDO';

  ValdataDbase.Connected := true;
  ValdataTabla.Close;
  ValdataTabla.TableName := _FejTablaNev;

  if not ValdataTabla.Exists then
    begin
      ValdataDbase.close;
      exit;
    end;

  with ValdataQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  // Ha van a dekád alatt bizonylat - akkor azokat beolvassa:

  if _recno>0 then
    begin
      while not ValdataQuery.Eof do
        begin
          _aktdatums := ValdataQuery.FieldByName('DATUM').asString;
          _ptrs := trim(Valdataquery.FieldByName('TARSPENZTARKOD').asString);
          _bizonylatszam := Valdataquery.FieldByName('BIZONYLATSZAM').asString;
          _feszkoz      := ValdataQuery.FieldByName('FIZETOESZKOZ').asInteger;
          _bTip   := leftstr(_bizonylatSzam,2);
          _storno := ValdataQuery.FieldByName('STORNO').asInteger;
          _osszft := ValdataQuery.FieldByNAme('OSSZESFORINTERTEK').asInteger;
          _kerekites := ValdataQuery.FieldByNAme('KEREKITES').asInteger;

          if (_bTip='UF') OR (_bTip='FF') then
            begin
              inc(_xsordb);
              _xbiz[_xsordb] := _bizonylatszam;
              _xsto[_xsordb] := _storno;
              _xnaps[_xsordb]:= midstr(_aktdatums,9,2);
              _xpts[_xsordb] := _ptrs;

              if _storno=1 then _xsum[_xsordb] := _osszft
              else _xsum[_xsordb] := 0;

              ValdataQuery.Next;
              Continue;
            end;

          if _storno<>1 then
            begin
              ValdataQuery.next;
              Continue;
            end;

          _tipus := leftstr(_bTip,1);

          if _tipus='V' then
            begin
              _voltVetel := True;
              _vetel := _vetel + _osszFt+_kerekites;
            end;

          if _tipus='E' then
            begin
              _voltEladas := True;
              if _feszkoz=2 then _bankkartyas := _bankkartyas + _osszft+_kerekites
              else _eladas := _eladas + _osszFt+_kerekites;
            end;
          ValdataQuery.Next;
        end;
    end;

  ValdataQuery.close;
  ValdataDbase.close;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================

// =============================================================================
            function TDekadRutin.GetkezdoSorszam(_wnaps: string):word;
// =============================================================================

var _ss: integer;
    _kss: string;

begin
  if midstr(_wnaps,6,5)='01.01' then
    begin
      _pcs := 'DELETE FROM DEKADJELENTES WHERE KEZDONAP<'+chr(39)+_wnaps+chr(39);
      DekadParancs(_pcs);
      result := 1;
      exit;
    end;

  result := 0;
  _pcs := 'SELECT * FROM DEKADJELENTES' + _sorveg;
  _pcs := _pcs + 'WHERE KEZDONAP<' + chr(39) + _wnaps + chr(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY KEZDONAP';

  ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
    end;

  if _recno>0 then
     begin
       _ss := ValutaQuery.FieldByName('UTOLSOSORSZAM').asInteger;
       result := 1 + _ss;
     end;

  ValutaQuery.close;
  ValutaDbase.close;

  if _recno=0 then
    begin
      _kss := inputbox('SORSZÁMBEKÉRÕ','Kérem a dekád elsõ sorszámát:','0');
      val(_kss,result,_code);
      if _code<>0 then result := 0;
    end;
end;



end.
