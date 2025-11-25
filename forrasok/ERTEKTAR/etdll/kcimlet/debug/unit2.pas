unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, jpeg, ExtCtrls, strutils, IBDatabase, DB,
  IBCustomDataSet, IBQuery;

type
  TForm2 = class(TForm)
    KISCIMLETPANEL: TPanel;
    ALSOPANEL: TPanel;
    Panel3: TPanel;
    ZASZLO: TImage;
    DNEMPANEL: TPanel;
    S1: TPanel;
    S2: TPanel;
    S3: TPanel;
    S4: TPanel;
    S5: TPanel;
    S6: TPanel;
    S7: TPanel;
    S8: TPanel;
    S9: TPanel;
    S10: TPanel;
    S11: TPanel;
    S12: TPanel;
    S13: TPanel;
    S14: TPanel;
    MEGSEMGOMB: TPanel;
    CIMROGZITOGOMB: TPanel;
    SUMPANEL: TPanel;
    C1PANEL: TPanel;
    C2PANEL: TPanel;
    C3PANEL: TPanel;
    C4PANEL: TPanel;
    C5PANEL: TPanel;
    C6PANEL: TPanel;
    C7PANEL: TPanel;
    C8PANEL: TPanel;
    C9PANEL: TPanel;
    C10PANEL: TPanel;
    C11PANEL: TPanel;
    C12PANEL: TPanel;
    C13PANEL: TPanel;
    C14PANEL: TPanel;
    E1EDIT: TEdit;
    E2EDIT: TEdit;
    E3EDIT: TEdit;
    E4EDIT: TEdit;
    E5EDIT: TEdit;
    E6EDIT: TEdit;
    E7EDIT: TEdit;
    E8EDIT: TEdit;
    E9EDIT: TEdit;
    E10EDIT: TEdit;
    E11EDIT: TEdit;
    E12EDIT: TEdit;
    E13EDIT: TEdit;
    E14EDIT: TEdit;
    SS1: TPanel;
    SS2: TPanel;
    SS3: TPanel;
    SS4: TPanel;
    SS5: TPanel;
    SS6: TPanel;
    SS7: TPanel;
    SS8: TPanel;
    SS9: TPanel;
    SS10: TPanel;
    SS11: TPanel;
    SS12: TPanel;
    SS13: TPanel;
    SS14: TPanel;
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;

    procedure FormActivate(Sender: TObject);
    procedure CimletElokeszites;
    PROCEDURE CimletNullazo;
    procedure TombeToltes;
    procedure CimletNyomtatas;
    procedure VonalHuzo;
    procedure MegsemGombClick(Sender: TObject);
    procedure CIMrogzitoGombClick(Sender: TObject);
    procedure CimletDatabasebe;
    procedure Cimletvegigszamolas;
    procedure E1EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    function Kerekito(_int: integer): integer;
    function ForintForm(_sm:integer):string;
    function Tizenegy(_b: integer): string;
    function negyes(_n: integer): string;
    function Elokieg(_s: string;_h: byte):string;
    procedure E1EDITEnter(Sender: TObject);
    procedure E1EDITExit(Sender: TObject);

    
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _aktdnemIndex : byte;

  _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY','CZK',
         'DKK','EUR','GBP','HRK','HUF','ILS','JPY','MXN','NOK','NZD','PLN','RON',
         'RSD','RUB','SEK','THB','TRY','UAH','USD');

  

  _cimletstring: array[1..14] of string = ('20.000','10.000','5.000','2.000',
          '1.000','500','200','100','50','20','10','5','2','1');

  _cimletertek: array[1..14] of word = (20000,10000,5000,2000,1000,500,200,100,
           50,20,10,5,2,1);

  _cimletdarab: array[1..27] of byte = (5,5,7,7,5,6,7,6,5,9,4,7,12,4,4,5,5,5,5,7,
           9,7,7,9,7,9,7);

  _cimletsor: array[1..27] of string = ('89ABC','789AB','89ABCDE','89ABCDE',
           '89ABC','5789AB','89ABCDE','345678','56789','6789ABCDE','9ABC',
           '56789AB','123456789ABC','789A','2345','6789A','56789','89ABC',
           '789AB','6789BCE','3456789AB','34568BC','56789AB','5689ABCDE',
           '1789ABC','6789ABCDE','89ABCDE');

  _cs,_ss: array[1..14] of TPanel;
  _ce: array[1..14] of TEdit;
  _sert: array[1..14] of integer;
  _lcimsor: array[1..14] of byte;
  _cBankjegy: array[1..14] of word;

  _wideon : char = #14;
  _wideoff: char = #20;

  _cms: string;
  _klet,_aktdb,_cie,_csum: integer;

  _height,_width,_top,_left : word;


  _Lfile : textfile;

  _aktdnem,_aktCimletSor,_zaszloPath,_mondat,_akttext,_pcs: string;
  _aktCimletDarab,_cimletss,_cTag: byte;
  _kkHeight,_aktCimletErtek: word;
  _sumertek,_aktErtek,_aktBankJegy,_code,_bankjegy,_sorertek: integer;

  _aktedit: TEdit;
  _LPath : string = 'c:\ertektar\cimlprnt.txt';
  _sorveg: string = chr(13)+chr(10);


function kcimletrutin(_para: byte): integer; stdcall;

implementation

{$R *.dfm}


function kcimletrutin(_para: byte): integer; stdcall;

begin
  Form2 := TForm2.Create(Nil);
  _aktdnemindex := _para;
  result := Form2.showmodal;
  Form2.Free;
end;  



procedure TForm2.FormActivate(Sender: TObject);
begin
  _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  _top    := trunc((_height-768)/2);
  _left   := trunc((_width-1024)/2);

  Top     := _top + 80;
  Left    := _left + 180;

  TombeToltes;
  CimletElokeszites;
  Activecontrol := E1Edit;
end;

// =============================================================================
               procedure TForm2.CimletElokeszites;
// =============================================================================

var _y: byte;

begin

  CimletNullazo;

  // A kiválasztott deviza cimletezésének elõkészítése:
  // Paraméter: DEVSORINDEX

  _aktDnem          := _dNem[_aktDnemIndex];
  _aktCimletDarab   := _cimletDarab[_aktdnemindex];
  _aktCimletSor     := _cimletSor[_aktdnemindex];

  // Beirja a kiválasztott deviza nevét a cimletezõ táblába:

  dnemPanel.Caption := _aktDnem;

  // A deviza országának zászlóját is beépiti a táblázatba:

  _zaszloPath       := 'c:\ertektar\flags\'+_aktdnem+'.jpg';
  Zaszlo.Picture.LoadFromFile(_zaszloPath);

  // Az adott deviza cimlet fajta darabszámának megfelelö magasságúra
  //             állitja be a címlettáblázatot:


  _kkHeight := 90 + trunc(25*_aktcimletDarab);
  Height    := _kkheight+2;

  KiscimletPanel.Height := _kkheight;
  Alsopanel.top     := _kkheight-49;

  // A deviza teljes mennyiségét kinullázza:


  _sumertek := 0;

  // Kitölti a teljes táblát a választott devizának megfelelõ cimletekkel:

  _y := 1;
  while _y<=_aktcimletdarab do
    begin
      _cimletss := ord(_aktcimletsor[_y])-48;

      // Ha cimletsor 9 feletti asc-értékü betükonvertálása:

      if _cimletss>9 then _cimletss := _cimletss - 7;

      // A cimletek beirása a táblázatba: (pl. '20.000')

      _cs[_y].caption := _cimletstring[_cimletss];

      // Az aktuális cimletsor tömbbe töltése:

      _Lcimsor[_y]    := _cimletss;

      // Az eddig cimletezett adatok kijelzése:

      _aktCimletErtek := _cimletErtek[_cimletss];
      _aktbankjegy    := _CBankjegy[_cimletss];
      _aktertek       := trunc(_aktCimletErtek*_aktBankJegy);
      _sert[_y]       := kerekito(_aktertek);
      _Sumertek       := _Sumertek + _aktErtek;

      _ce[_y].Text    := '';
      _ss[_y].Caption := ForintForm(_aktertek);
      inc(_y);
    end;

  Sumpanel.Caption := Forintform(_sumertek);

  // Ha volt valamennyi cimletezés -> akkor rögzithetõ a cimlet:

  if _sumertek=0 then
    begin
      CimRogzitoGomb.Enabled := False;
      CimrogzitoGomb.Color := clSilver;
    end else
    begin
      CimRogzitoGomb.Enabled := True;
      CimrogzitoGomb.Color := clWhite;
    end;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//          Alapra állitja a KISCIMLETPANEL objektumait                       //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                   PROCEDURE TForm2.CimletNullazo;
// =============================================================================

var _y: byte;

begin
  _y := 1;
  while _y<=14 do
    begin
      _cs[_y].Caption := '';
      _ce[_y].text := '';
      _ss[_y].Caption := '';
      _sert[_y] := 0;
     
      inc(_y);
    end;

  SumPanel.Caption := '';
  CimrogzitoGomb.Enabled := False;
  CimrogzitoGomb.color := clSilver;
end;


procedure TForm2.TombeToltes;

begin
   // A cimletkeiratok téglái (pl 20.000) (kiscimletpanelen)

  _cs[1] := C1Panel;
  _cs[2] := C2Panel;
  _cs[3] := C3Panel;
  _cs[4] := C4Panel;
  _cs[5] := C5Panel;
  _cs[6] := C6Panel;
  _cs[7] := C7Panel;
  _cs[8] := C8Panel;
  _cs[9] := C9Panel;
  _cs[10]:= C10Panel;
  _cs[11]:= C11Panel;
  _cs[12]:= C12Panel;
  _cs[13]:= C13Panel;
  _cs[14]:= C14Panel;

  // Cimletezett értékek tégláai: (kiscimletpanelen)

  _ss[1] := SS1;
  _ss[2] := SS2;
  _ss[3] := SS3;
  _ss[4] := SS4;
  _ss[5] := SS5;
  _ss[6] := SS6;
  _ss[7] := SS7;
  _ss[8] := SS8;
  _ss[9] := SS9;
  _ss[10]:= SS10;
  _ss[11]:= SS11;
  _ss[12]:= SS12;
  _ss[13]:= SS13;
  _ss[14]:= SS14;

   // A cimlet bankjegyeinek edit-je: (kiscimletpanelen)

  _ce[1] := E1Edit;
  _ce[2] := E2Edit;
  _ce[3] := E3Edit;
  _ce[4] := E4Edit;
  _ce[5] := E5Edit;
  _ce[6] := E6Edit;
  _ce[7] := E7Edit;
  _ce[8] := E8Edit;
  _ce[9] := E9Edit;
  _ce[10]:= E10Edit;
  _ce[11]:= E11Edit;
  _ce[12]:= E12Edit;
  _ce[13]:= E13Edit;
  _ce[14]:= E14Edit;


end;

// =============================================================================
           function TForm2.kerekito(_int: integer): integer;
// =============================================================================

var _nums: string;
    _utdig,_wnums: Byte;

begin
  result := _int;
  _nums := inttostr(_int);
  _wnums := length(_nums);
  _utdig := ord(_nums[_wnums])-48;
  if (_utdig<>0) and (_utdig<>5) then
    begin
      if (_utdig=1) or (_utdig=2) then result := _int-_utdig;
      if (_utdig=6) or (_utdig=7) then result := _int-(_utdig-5);
      if (_utdig=3) or (_utdig=4) then result := _int+(5-_utdig);
      if (_utdig=8) or (_utdig=9) then result := _int+10-_utdig;
    end;
end;

// =============================================================================
             function TForm2.ForintForm(_sm:integer):string;
// =============================================================================

var _slen,_pp: integer;

begin
  Result := '-';

  if _sm=0 then exit;
  Result := intTostr(_sm);

  if _sm<1000 then exit;

  _sLen := length(Result);
  if _sm>999999 then
    begin
      _pp := _sLen-5;
      Result := midStr(Result,1,_pp-1)+' '+midStr(Result,_pp,3)+' '+midStr(Result,_pp+3,3);
      Exit;
    end;

  _pp := _sLen-2;
  Result := midStr(result,1,_pp-1)+' '+midStr(result,_pp,3);
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//               Billentyüt nyomott egy cimlet-bankjegy-téglát                //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
      procedure TFORM2.E1EDITKeyDown(Sender: TObject; var Key: Word;
                                                         Shift: TShiftState);
// =============================================================================

var _bill: byte;

begin
  // Az egyik cimletsor edit szerkesztése:

  _ctag := TEdit(sender).Tag;
  _bill := ord(key);

  // Felfele billentyüt nyomott és nem az elsó cimlet:

  if (_bill=38) and (_ctag>1) then
     begin
       CimletVegigszamolas;
       dec(_ctag);
       _aktedit := _ce[_ctag];
       Activecontrol := _aktedit;
       exit;
     end;

   // lefele billentyüt nyomott és nem az utolsó cimlet:

   if (_bill=40) and (_ctag<_aktcimletDarab) then
     begin
       CimletVegigSzamolas;
       inc(_ctag);
       _aktedit := _ce[_ctag];
       Activecontrol := _aktedit;
       exit;
     end;

  // Most már csak enter jöhet:

  if _bill<>13 then exit;

  CimletVegigSzamolas;

  if _cTag<_aktcimletDarab then
    begin
      inc(_ctag);
      _aktedit := _ce[_ctag];
      ActiveControl := _aktedit;
      exit;
    end;
  Activecontrol := Cimrogzitogomb;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//            A CIMLETEZÉS KÖZBEN A 'MÉGSEM' GOMBOT NYOMTA BE                 //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
          procedure TFORM2.MEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 2;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//          Megnyomta a cimlet-rögzitõ gombot - Cimlet rendben                //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
         procedure TFORM2.CIMrogzitoGOMBClick(Sender: TObject);
// =============================================================================

begin
   CimletVegigszamolas;
   Cimletnyomtatas;
   CimletDatabasebe;
   Modalresult := 1;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//               Ha van - akkor kinyomtatja a cimlet(ek)et                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                   procedure Tform2.CimletNyomtatas;
// =============================================================================

var _m: byte;

begin
  if Fileexists(_LPath) then
    begin
      Assignfile(_LFile,_LPath);
      Append(_LFile);
    end else
    begin
      AssignFile(_LFile,_LPath);
      rewrite(_LFile);
    end;

  // A cimletezett valuta neme és neve:

  _aktdnem := _dNem[_aktdnemIndex];
  _mondat  := _sorveg + '  '+_aktdnem + ' cimletezése' + _sorveg;

  writeLn(_LFile,_mondat);

  _m    := 1;
  _klet := 0;
  while _m<=14 do
    begin
      _aktdb := _cBankjegy[_m];
      if _aktdb>0 then
        begin
          _cms    := elokieg(_cimletstring[_m],6)+'-S ';
          _cie    := _cimletertek[_m];
          _mondat := '  '+_cms + negyes(_aktdb)+' db = ';
          _csum   := trunc(_cie*_aktdb);
          _mondat := _mondat + tizenegy(_csum);
          _klet   := _klet + _csum;

          writeLn(_LFile,_mondat);
        end;
      inc(_m);
    end;

  writeLn(_LFile,' ');
  writeLn(_Lfile,'          Osszesen: ' + ' ' + tizenegy(_klet));
  VonalHuzo;

  CloseFile(_LFile);

end;


procedure TForm2.CimletDatabasebe;

var _y: byte;

begin
  _pcs := 'INSERT INTO CIMLETPISZKOZAT (VALUTANEM,BANKJEGY';

  _y := 1;
  while _y<=14 do
    begin
      _pcs := _pcs + ',CIMLET'+inttostr(_y);
      inc(_y);
    end;
  _pcs := _pcs + ')'+_sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39)+_aktdnem+chr(39)+',';
  _pcs := _pcs + inttostr(_klet);

  _y := 1;
  while _y<=14 do
    begin
      _aktdb := _cBankjegy[_y];
      _pcs := _pcs + ',' + inttostr(_aktdb);
      inc(_y);
    end;
  _pcs := _pcs + ')';
  Vdbase.Connected := true;
  if vtranz.InTransaction then vtranz.Commit;
  vtranz.StartTransaction;
  with vquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;
  Vtranz.Commit;
  Vdbase.close;
end;


// =============================================================================
                procedure TForm2.Cimletvegigszamolas;
// =============================================================================

var _q,_z : byte;

begin
  for _q := 1 to 14 do _cbankjegy[_q] := 0;

  _q := 1;
  while _q<=_aktcimletdarab do
    begin
      _cimletss       := _LCimsor[_q];
      _aktcimletertek := _cimletErtek[_cimletss];

      _aktedit := _ce[_q];
      _aktText := trim(_aktedit.text);
      val(_aktText,_bankjegy,_code);
      if _code<>0 then _bankjegy := 0;

      _sorertek       := trunc(_bankjegy*_aktcimletertek);
      _sert[_q]       := _sorertek;
      _ss[_q].caption := forintform(_sorertek);

      _cBankjegy[_cimletss] := _bankjegy;

      inc(_q);
    end;

  _sumertek := 0;
  for _z := 1 to _aktcimletdarab do  _sumertek := _sumertek + _sert[_z];
  Sumpanel.caption := Forintform(_sumertek);
  Sumpanel.repaint;
  if _sumErtek>0 then
     begin
       CimrogzitoGomb.Color   := clWhite;
       CimrogzitoGomb.Enabled := True;
     end else
     begin
       CimrogzitoGomb.Color   := clSilver;
       CimrogzitoGomb.Enabled := False;
     end;
end;

// ============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                      39 karakter hosszu vonalat nyomtat                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                 procedure TForm2.VonalHuzo;
// =============================================================================

begin
  writeLn(_LFile,dupestring('-',39));
end;

// ============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                  Formázva kinyomtat egy négyjegyü számot                   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
               function TForm2.negyes(_n: integer): string;
// =============================================================================

begin
  result := inttostr(_n);
  while length(result)<4 do result := ' '+result;
end;

// ============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                  Formázva kinyomtat egy tizenegyjegyü számot               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
             function TForm2.Tizenegy(_b: integer): string;
// =============================================================================

var _r: string;
    _w1,_p1: byte;

begin
  _r := inttostr(_b);
  _w1 := length(_r);
  if _b>999999 then
    begin
      _p1 := _w1-6;
      _r := leftstr(_r,_p1)+'.'+midstr(_r,_p1+1,3)+'.'+midstr(_r,_p1+4,3);
    end else
    begin
      if _b>999 then
         begin
            _p1 := _w1-3;
            _r := leftstr(_r,_p1)+'.'+midstr(_r,_p1+1,3);
          end;
    end;
  _w1 := length(_r);
  while _w1<11 do
    begin
      _r := ' '+_r;
      _w1 := length(_r);
    end;

  result := _r;
end;


// ============================================================================
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//       Elöröl kiegésziti 0-kkal a stringet, mig _H hosszú nem lesz          //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// ============================================================================
         function Tform2.Elokieg(_s: string;_h: byte):string;
// ============================================================================

begin
  result := _s;
  while length(result)<_h do  result := ' '+result;
end;

procedure TForm2.E1EDITEnter(Sender: TObject);
begin
  Tedit(sender).Color := clYellow;
end;

procedure TForm2.E1EDITExit(Sender: TObject);
begin
  Tedit(sender).Color := clWindow;
end;

end.
