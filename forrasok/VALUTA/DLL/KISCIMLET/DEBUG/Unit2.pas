unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, jpeg, ExtCtrls, strutils, Buttons, IBDatabase, DB,
  IBCustomDataSet, IBQuery;

type
  TKISCIMLET = class(TForm)

    AlapPanel     : TPanel;
    BPan1         : TPanel;
    BPan2         : TPanel;
    BPan3         : TPanel;
    c1Panel       : TPanel;
    c2Panel       : TPanel;
    c3Panel       : TPanel;
    c4Panel       : TPanel;
    c5Panel       : TPanel;
    c6Panel       : TPanel;
    c7Panel       : TPanel;
    c8Panel       : TPanel;
    c9Panel       : TPanel;
    c10Panel      : TPanel;
    c11Panel      : TPanel;
    c12Panel      : TPanel;
    c13Panel      : TPanel;
    c14Panel      : TPanel;
    CimletKeszGomb: TPanel;
    DNam1         : TPanel;
    DNam2         : TPanel;
    DNam3         : TPanel;
    DnemPanel     : TPanel;
    Gombpanel     : TPanel;
    MegsemGomb    : TPanel;
    MenuPanel     : TPanel;
    p1            : TPanel;
    p2            : TPanel;
    p3            : TPanel;
    p4            : TPanel;
    p5            : TPanel;
    p6            : TPanel;
    p7            : TPanel;
    p8            : TPanel;
    p9            : TPanel;
    p10           : TPanel;
    p11           : TPanel;
    p12           : TPanel;
    p13           : TPanel;
    p14           : TPanel;
    panel2        : TPanel;
    Panel4        : TPanel;
    s1Panel       : TPanel;
    s2Panel       : TPanel;
    s3Panel       : TPanel;
    s4Panel       : TPanel;
    s5Panel       : TPanel;
    s6Panel       : TPanel;
    s7Panel       : TPanel;
    s8Panel       : TPanel;
    s9Panel       : TPanel;
    s10Panel      : TPanel;
    s11Panel      : TPanel;
    s12Panel      : TPanel;
    s13Panel      : TPanel;
    s14Panel      : TPanel;
    SumPanel      : TPanel;

    e1Edit        : TEdit;
    e2EDIT        : TEdit;
    e3EDIT        : TEdit;
    e4EDIT        : TEdit;
    e5EDIT        : TEdit;
    e6EDIT        : TEdit;
    e7EDIT        : TEdit;
    e8EDIT        : TEdit;
    e9EDIT        : TEdit;
    e10Edit       : TEdit;
    e11Edit       : TEdit;
    e12Edit       : TEdit;
    e13Edit       : TEdit;
    e14Edit       : TEdit;

    kilepo        : TTimer;

    ibQuery       : TIBQuery;
    ibDbase       : TIBDatabase;
    ibTranz       : TIBTransaction;

    Flag1         : TImage;
    Flag2         : TImage;
    Flag3         : TImage;
    Zaszlo        : TImage;

    CimletVegGomb : TBitBtn;

    procedure Adatrogzites;
    procedure Aktival(_tt: byte);
    procedure BitBtn2Click(Sender: TObject);
    procedure CfgBedolgozas(_sor: string);
    procedure CimletKeszGombClick(Sender: TObject);
    procedure CimletVegGombClick(Sender: TObject);
    procedure DezAktival(_tt: byte);
    procedure DNam1Click(Sender: TObject);
    procedure Flag1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure MegsemGombClick(Sender: TObject);
    procedure p1Exit(Sender: TObject);
    procedure e1EditEnter(Sender: TObject);
    procedure e1EditKeyUp(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure e1EditExit(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure Menustart;
    procedure Munka;
    procedure p1Enter(Sender: TObject);
    procedure Summazas;
    procedure TablaUrites;
    procedure ValutatValasztott(_sors: integer);
    procedure Wordbeiro(_ww: word);
    procedure ZaroByteIro;

    function Ele4(_bj: integer):string;
    function FtForm(_int: integer): string;
    function GetUresTomb: byte;
    function Getconfig: boolean;
    function ScanTenyDnem(_vv: string): byte;
    function ScanDnem(_adnem: string): byte;
    function ValutaControl: boolean;
    procedure FormCreate(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Kiscimlet: TKiscimlet;

  _biniras      : file of byte;
  _bytetomb     : array[1..16] of byte;

  _cBankjegy    : array[1..3,1..14] of word;
  _bPan         : array[1..3] of tPanel;

  _cimlet : array[1..14] of integer = (20000,10000,5000,2000,1000,500,200,100,
                                             50,20,10,5,2,1);
  _cimlets: array[1..14] of string = ('20 000','10 000','5 000','2 000','1 000',
                             '500','200','100','50','20','10','5','2','1');

  _cCimletDarab : array[1..3] of byte;
  _cCimletErtek : array[1..3,1..14] of word;
  _cdb          : array[1..27] of byte;
  _cpan         : array[1..14] of TPanel;
  _ct           : array[1..27,1..14] of byte;
  _cValNev      : array[1..3] of string;

  _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY','CZK','DKK',
                            'EUR','GBP','HRK','HUF','ILS','JPY','MXN','NOK','NZD',
                            'PLN','RON','RSD','RUB','SEK','THB','TRY','UAH',
                            'USD');

  _dnPan        : array[1..3] of TPanel;
  _ecim         : array[1..14] of integer;
  _eedit        : array[1..14] of TEdit;
  _flags        : array[1..3]of TImage;
  _mb           : array[1..3] of integer;
  _mv           : array[1..3] of string;
  _ppan         : array[1..14] of TPanel;
  _sbj          : array[1..14] of integer;
  _sert         : array[1..14] of integer;
  _span         : array[1..14] of TPanel;

  _dataPath     : string = 'c:\valuta\aktcim.dat';
  _sorveg       : string = chr(13) + chr(10);

  _aktualdnem   : string;
  _aktdnem      : string;
  _pcs          : string;
  _yTipus       : string;
  _zaszloPath   : string;

 _aktualbankjegy: integer;
  _basheight    : integer;
  _cc           : integer;
  _code         : integer;
  _cValDarab    : integer;
  _recno        : integer;
  _sorsum       : integer;
  _ssert        : integer;
  _yFiz         : integer;

  _aktualdarab  : byte;
  _qq           : byte;
  _tag          : byte;
  _tt           : byte;
  _xx           : byte;
  _ytetel       : byte;

  _bankjegy     : word;
  _top          : word;
  _left         : word;
  _height       : word;
  _width        : word;

function kiscimletezes: integer; stdcall;


implementation

{$R *.dfm}

{   Visszatérés: 1= oké, 2=storno

    Rögzités: 'c:\valuta\aktcim.dat'

    - cimletezett valutadarab   1 byte (Ha nulla -> nincs cimletezés)
      Ciklus: 1-töl cimletezett valutadarabig:
           - valutanem  3 byte (#255-el kódolva)
           - élõ cimletdarab:  byte
             Ciklus: 1-tõl élõ cimletdarab:
                 - cimletérték: word (lo-hi) (pl. 20000,5000,50,2)
                 - bankjegy: word (lo-hi)
             Kisciklus záró: 255
      Nagyciklus záró: 255
    File záró: 255
}


// =============================================================================
                   function kiscimletezes: integer; stdcall;
// =============================================================================

begin
  Kiscimlet := TKiscimlet.create(Nil);
  result := Kiscimlet.showModal;
  Kiscimlet.Free;
end;


// =============================================================================
               procedure TKiscimlet.FormActivate(Sender: TObject);
// =============================================================================

var i: integer;

begin
    top   := _top + 10;
  Left   := _left + 740;

  Menustart;

  _cValDarab := 0;
  for i := 1 to 3 do _cValnev[i] := '';

  if not ValutaControl then
    begin
      Kilepo.Enabled := true;
      exit;
    end;

  _bPan[1] := BPAN1;
  _bPan[2] := BPAN2;
  _bPan[3] := BPAN3;

  _dnPan[1] := DNAM1;
  _dnPan[2] := DNAM2;
  _dnPan[3] := DNAM3;

  _Flags[1] := Flag1;
  _Flags[2] := Flag2;
  _Flags[3] := Flag3;

  _cpan[1] := C1PANEL;
  _cpan[2] := C2PANEL;
  _cpan[3] := C3PANEL;
  _cpan[4] := C4PANEL;
  _cpan[5] := C5PANEL;
  _cpan[6] := C6PANEL;
  _cpan[7] := C7PANEL;
  _cpan[8] := C8PANEL;
  _cpan[9] := C9PANEL;
  _cpan[10]:= C10PANEL;
 
  _cpan[12]:= C12PANEL;
  _cpan[13]:= C13PANEL;
  _cpan[14]:= C14PANEL;
  _span[11]:= C11PANEL;


  _ppan[1] := P1;
  _ppan[2] := P2;
  _ppan[3] := P3;
  _ppan[4] := P4;
  _ppan[5] := P5;
  _ppan[6] := P6;
  _ppan[7] := P7;
  _ppan[8] := P8;
  _ppan[9] := P9;
  _ppan[10]:= P10;
  _ppan[11]:= P11;
  _ppan[12]:= P12;
  _ppan[13]:= P13;
  _ppan[14]:= P14;


  _eedit[1] := E1EDIT;
  _eedit[2] := E2EDIT;
  _eedit[3] := E3EDIT;
  _eedit[4] := E4EDIT;
  _eedit[5] := E5EDIT;
  _eedit[6] := E6EDIT;
  _eedit[7] := E7EDIT;
  _eedit[8] := E8EDIT;
  _eedit[9] := E9EDIT;
  _eedit[10]:= E10EDIT;
  _eedit[11]:= E11EDIT;
  _eedit[12]:= E12EDIT;
  _eedit[13]:= E13EDIT;
  _eedit[14]:= E14EDIT;

  _Span[1] := S1PANEL;
  _span[2] := S2PANEL;
  _span[3] := S3PANEL;
  _span[4] := S4PANEL;
  _span[5] := S5PANEL;
  _span[6] := S6PANEL;
  _span[7] := S7PANEL;
  _span[8] := S8PANEL;
  _span[9] := S9PANEL;
  _span[10]:= S10PANEL;
  _span[11]:= S11PANEL;
  _span[12]:= S12PANEL;
  _span[13]:= S13PANEL;
  _span[14]:= s14PANEL;

  for i := 2 to 3 do _bpan[i].Visible := false;

  for i := 1 to 14 do
    begin
      _ppan[i].OnEnter := p1enter;
      _ppan[i].OnExit  := p1exit;
      _eedit[i].OnEnter := e1editenter;
      _eedit[i].OnExit := e1editExit;
      _eedit[i].OnKeyUp := e1editkeyup;
    end;

  if not Getconfig then
    begin
      Kilepo.enabled := True;
      exit;
    end;

  if (_ytipus<>'K') then
    begin
      Flag1.Picture.LoadFromFile('c:\valuta\flags\huf.jpg');
      Dnam1.Caption := 'HUF';
    end;

  if (_yTipus='K') then
    begin
      _qq := 1;
      while _qq<=_ytetel do
        begin
          _flags[_qq].Picture.LoadFromFile('c:\valuta\flags\'+_mv[_qq]+'.jpg');
          _dnpan[_qq].Caption := _mv[_qq];
          _bpan[_qq].Visible := true;
          inc(_qq);
        end;
    end else
    Begin
      _qq := 1;
      while _qq<=_yTetel do
        begin
          _AKTDNEM := _mv[_qq];
          _flags[_qq+1].Picture.LoadFromFile('c:\valuta\flags\'+ _aktdnem +'.jpg');
          _dnPan[_qq+1].Caption := _aktdnem;
          _bpan[_qq+1].Visible := True;
           inc(_qq);
        end;
    end;
  ActiveControl := cimletvegGOmb;
end;

// =============================================================================
                        procedure TKiscimlet.Munka;
// =============================================================================

begin

  TablaUrites;
  with Cimletkeszgomb do
    begin
      Color := $AAAAAA;
      Font.Color := clGray;
      Enabled := False;
    end;

  Width := 280;

  AlapPanel.Top := 0;
  AlapPanel.left:= 0;
  Alappanel.repaint;

  _xx := scandnem(_aktualdnem);
  _tt := scanTenyDnem(_aktualdnem);
  if _tt>0 then _cValnev[_tt] := '';

  _zaszloPath  := 'c:\valuta\flags\'+_aktualdnem+'.jpg';
  _aktualdarab := _cdb[_xx];
  _basHeight   := 96+trunc(27*_aktualDarab);

  Height := _basheight+40;
  Alappanel.Height := _basHeight;
  GombPanel.Top := _basheight-50;

  Zaszlo.Picture.LoadFromFile(_zaszloPath);
  DnemPanel.Caption := _aktualDnem;

  _qq := 1;
  while _qq<=_aktualdarab do
    begin
      _cc := _ct[_xx,_qq];
      _cpan[_qq].Caption :=  _cimlets[_cc];
      _ecim[_qq] := _cimlet[_cc];
      inc(_qq);
    end;

  ActiveControl := e1edit;
end;

// =============================================================================
                     procedure TKiscimlet.Tablaurites;
// =============================================================================


begin
  Zaszlo.Picture := Nil;
  DnemPanel.Caption := '';
  _qq := 1;
  while _qq<=14 do

    begin
      _cpan[_qq].Caption := '';
      _span[_qq].caption := '';
      _eedit[_qq].Text := '';
      _ecim[_qq] := 0;
      _sert[_qq] := 0;
      _sbj[_qq]  := 0;
      inc(_qq);
    end;
  Sumpanel.caption := '';
end;


// =============================================================================
           function TKiscimlet.ScanDnem(_adnem: string): byte;
// =============================================================================

// Meghatározza a valutanem abszolut sorszámát


var _y: integer;

begin
  result := 0;
  _y := 1;
  while _y<=27 do
    begin
      if _adnem=_dnem[_y] then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;


// =============================================================================
                  function TKiscimlet.Getconfig: boolean;
// =============================================================================

var _mondat,_configpath: string;
    _txtOlvas: textfile;


begin
  result := False;
  _configpath := 'c:\valuta\cimlet.cfg';
  if not fileExists(_configPath) then exit;

  Assignfile(_txtolvas,_configpath);
  Reset(_txtolvas);

  while not eof(_txtolvas) do
    begin
      readln(_txtolvas,_mondat);
      cfgBedolgozas(_mondat);
    end;
  closeFile(_txtOlvas);

  _cdb[25] := 2;
  _ct[25,1] := 13;
  _ct[25,2] := 14;

  result := True;
end;


// =============================================================================
             procedure TKiscimlet.CfgBedolgozas(_sor: string);
// =============================================================================

var _wsor,_darab,_p,_ctsor: byte;
    _cimsor,_aktdnem: string;

begin
  _wsor := length(_sor);
  _aktdnem := leftstr(_sor,3);
  _darab   := ord(_sor[4]) - 65;
  _cimsor  := midstr(_sor,5,_wsor-4);

  _xx := Scandnem(_aktdnem);

  _cdb[_xx] := _darab;

  _p := 1;
  while _p<=_darab do
    begin
      _ctsor := ord(_cimsor[_p])-65;
      _ct[_xx,_p] := _ctsor;
      inc(_p);
    end;
end;


// =============================================================================
                        procedure TKiscimlet.Summazas;
// =============================================================================

var _z: byte;
    _serts: string;

begin
  _ssert := 0;
  for _z := 1 to 14 do _ssert := _ssert + _sert[_z];
  _serts := FtForm(_ssert);
  if _serts<>'' then _serts := _serts + ' '+ _aktualdnem;
  SumPanel.caption := _serts;
  Sumpanel.repaint;
  if _ssert>=_aktualBankjegy then
    begin
      cimletkeszgomb.Color := clWhite;
      Cimletkeszgomb.Font.Color := clBlack;
      Cimletkeszgomb.Enabled := true;
      Activecontrol := CimletkeszGomb;
    end else
    begin
      cimletkeszgomb.Color := $AAAAAA;
      Cimletkeszgomb.Font.Color := clGray;
      Cimletkeszgomb.Enabled := False;
    end;

end;


// =============================================================================
            function TKiscimlet.FtForm(_int: integer): string;
// =============================================================================

var _f1,_wf: byte;

begin
  result := '';
  if _int=0 then exit;
  result := inttostr(_int);
  if _int<1000 then exit;
  _wf := length(result);
  if _wf>6 then
    begin
      _f1 := _wf-6;
      result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3)+' '+midstr(result,_f1+4,3);
      exit;
    end;
   _f1 := _wf-3;
   result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3);
end;


// =============================================================================
             procedure TKisCimlet.KilepoTimer(Sender: TObject);
// =============================================================================

begin
 Kilepo.Enabled := false;
 Modalresult := 2;
end;


// =============================================================================
             procedure TKisCimlet.BitBtn2Click(Sender: TObject);
// =============================================================================

begin
  Modalresult := 2;
end;

// =============================================================================
               procedure TKisCimlet.E1EditEnter(Sender: TObject);
// =============================================================================

begin
  _tag := Tedit(Sender).tag;
  aktival(_tag);
end;


// =============================================================================
                   procedure Tkiscimlet.Aktival(_tt: byte);
// =============================================================================

begin
  _ppan[_tt].Color := clYellow;
  _eedit[_tt].Color:= clYellow;
end;


// =============================================================================
                  procedure Tkiscimlet.DezAktival(_tt: byte);
// =============================================================================

begin
  _ppan[_tt].Color := clWindow;
  _eedit[_tt].Color:= clWindow;
end;

// =============================================================================
              procedure TKisCimlet.E1EditExit(Sender: TObject);
// =============================================================================

begin
  _tag := TEdit(Sender).Tag;
  Dezaktival(_tag);
end;

// =============================================================================
                procedure TKisCimlet.p1Enter(Sender: TObject);
// =============================================================================

begin
  _tag := TPanel(sender).tag;
  Aktival(_tag);
end;

// =============================================================================
               procedure TKisCimlet.p1Exit(Sender: TObject);
// =============================================================================

begin
  _tag := TPanel(Sender).Tag;
  Dezaktival(_tag);
end;

// =============================================================================
       procedure TKisCimlet.E1EditKeyUp(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

var _bill   : integer;
    _aktedit: TEdit;
    _beirts : string;

begin
  _bill := ord(key);
  _tag  := Tedit(sender).Tag;
  if (_bill<>13) and (_bill<>38) and (_bill<>40) then exit;

  _aktedit := _eedit[_tag];
  _beirts  := trim(_aktedit.Text);

  val(_beirts,_bankjegy,_code);

  if _code<>0 then _bankjegy := 0;

  if _bankjegy>0 then
    begin
      _eedit[_tag].Text   := ele4(_bankjegy);
      _sorsum             := trunc(_ecim[_tag]*_bankjegy);
      _span[_tag].Caption := FtForm(_sorsum);
      _sbj[_tag]          := _bankjegy;
      _sert[_tag]         := _sorsum;
    end else
    begin
      _sert[_tag]         := 0;
      _sbj[_tag]          := 0;
      _span[_tag].Caption := '';
      _eedit[_tag].Text   := '';
    end;

   Summazas;

  if (_bill=13) or (_bill=40) and (_tag<_aktualdarab) then
    begin
      inc(_tag);
      ActiveControl := _eedit[_tag];
      exit;
    end;

  if _tag=1 then exit;

  dec(_tag);
  ActiveControl := _eedit[_tag];
end;

// =============================================================================
            function TKiscimlet.Ele4(_bj: integer):string;
// =============================================================================

begin
  result := inttostr(_bj);
  while length(result)<4 do result := ' '+result;
end;

// =============================================================================
              function TKiscimlet.ValutaControl: boolean;
// =============================================================================

var _vnem: string;
    _vBjegy,_coin: integer;

begin
  Result := False;

  _pcs := 'SELECT * FROM VTEMP' + _sorveg;
  _pcs := _pcs + 'WHERE BANKJEGY>0';

  ibdbase.Connected := true;
  with Ibquery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      ibquery.close;
      ibdbase.Close;
      exit;
    end;

  _yTipus := ibQuery.FieldByNAme('TIPUS').asString;
  _yTetel := ibQuery.FieldByNAme('TETEL').asInteger;
  _yfiz   := ibquery.FieldByName('FIZETENDO').asInteger;

  _cc := 0;
  while not Ibquery.Eof do
    begin
      _vNem := ibQuery.FieldByName('VALUTANEM').asstring;
      _coin := ibQuery.FieldByName('COIN').asInteger;
      if (_vNem='EUR') AND (_coin=1) then _vNem := 'EUA';
      if _vnem<>'HUF' then
        begin
          inc(_cc);
          _vBjegy  := Ibquery.FieldByName('BANKJEGY').asInteger;
          _mv[_cc] := _vNem;
          _mb[_cc] := _vBjegy;

        end else dec(_yTetel);
      ibquery.next;
    end;

  ibquery.close;
  ibdbase.close;
  result := True;
end;


// =============================================================================
        procedure TKisCimlet.CimletVegGombClick(Sender: TObject);
// =============================================================================

begin
  AdatRogzites;
  Modalresult := 1;
end;

// =============================================================================
            procedure TKisCimlet.FLag1Click(Sender: TObject);
// =============================================================================

begin
  _tag := TImage(sender).Tag;
  ValutatValasztott(_tag);
end;

// =============================================================================
             procedure TKisCimlet.DNam1Click(Sender: TObject);
// =============================================================================

begin
  _tag := TPanel(sender).Tag;
  ValutatValasztott(_tag);
end;

// =============================================================================
           procedure TKiscimlet.ValutatValasztott(_sors: integer);
// =============================================================================

begin
  with MenuPanel do
    begin
      Top := -300;
      Left := -300;
    end;

  // Konverzió esetén az aktulás valuta a tényleges sorszámu:

  if _ytipus='K' then
    begin
      _aktualdnem     := _mv[_sors];
      _aktualbankjegy := _mb[_sors];
    end else

    // Vétel/Eladásnál az elsõ a HUF a többi az egyéb
    begin
      if _sors=1 then
        begin
          _aktualdnem     := 'HUF';
          _aktualbankjegy := _yFiz;
        end else
        begin
          _aktualdnem     := _mv[_sors-1];
          _aktualbankjegy := _mb[_sors-1];
        end;
    end;
  Munka;
end;


// =============================================================================
                        procedure TKisCimlet.Menustart;
// =============================================================================


begin
   with AlapPanel do
    begin
      top  := -600;
      left := -300;
    end;
  with MenuPanel do
    begin
      top  := 0;
      Left := 0;
    end;
  Height := 260;
  Width  := 254;
end;

// =============================================================================
           procedure TKisCimlet.MegsemGombClick(Sender: TObject);
// =============================================================================

begin
   with AlapPanel do
    begin
      top := -600;
      left:= -300;
    end;
  with MenuPanel do
    begin
      top := 0;
      Left:= 0;
    end;
  Height := 260;
  Width  := 254;
end;

// =============================================================================
            function TKiscimlet.ScanTenyDnem(_vv: string): byte;
// =============================================================================

begin

  result := 0;

  if _cvalnev[1]=_vv then result := 1;
  if _cvalnev[2]=_vv then result := 2;
  if _cvalnev[3]=_vv then result := 3;

end;


// =============================================================================
          procedure TKisCimlet.CimletKeszGombClick(Sender: TObject);
// =============================================================================


var _cc,i,_aktcdarab,_ccdb,_cvdb: byte;

begin
  if _ssert>_aktualBankjegy then Kiscimlet.Caption := 'VISSZAJÁR = '
              + inttostr(_ssert-_aktualbankjegy)+ ' '+_aktualdnem;

  _tt := getUresTomb;
  _cValNev[_tt] := _aktualdnem;

  _cc   := 1;
  _ccdb := 0;
  while _cc<=_aktualdarab do
    begin
      _aktcdarab := _sbj[_cc];
      if _aktcdarab>0 then
        begin
          inc(_ccdb);
          _cCimletErtek[_tt,_ccdb] := _ecim[_cc];
          _cBankjegy[_tt,_ccdb] := _aktcdarab;
        end;
      inc(_cc);
    end;

  _cCimletDarab[_tt] := _ccdb;
  _cvdb := 0;

  for i := 1 to 3 do
    begin
      if _cValNev[i]<>'' then inc(_cvdb);
    end;

  _cValDarab := _cvdb;

  MegsemGombClick(Nil);
end;

// =============================================================================
                    function TKisCimlet.GetUresTomb: byte;
// =============================================================================

begin
  result := 1;
  while result<=3 do
    begin
      if _cValnev[result]='' then exit;
      inc(result);
    end;
end;

// =============================================================================
                      procedure TKiscimlet.Adatrogzites;
// =============================================================================

var
    _p,_aktcimletdb: byte;
    _clt,_cbj: word;
begin
  _dataPath := 'c:\valuta\aktcim.dat';
  if Fileexists(_dataPath) then Sysutils.DeleteFile(_dataPath);
  if _cValdarab=0 then exit;

  Assignfile(_biniras,_dataPath);
  Rewrite(_biniras);
  _bytetomb[1] := _cValdarab;
  Blockwrite(_biniras,_bytetomb,1);

  _cc := 1;
  while _cc<=_cValDarab do
    begin
      _aktualdnem := _cValNev[_cc];
      _p := 1;
      while _p<=3 do
        begin
          _bytetomb[_p] := 255 - ord(_aktualdnem[_p]);
          inc(_p);
        end;
      blockwrite(_biniras,_bytetomb,3);

      _aktcimletdb := _cCimletDarab[_cc];
      _Bytetomb[1] := _aktcimletdb;

      Blockwrite(_biniras,_bytetomb,1);

      _p := 1;
      while _p<=_aktcimletdb do
        begin
          _cLt := _cCimletErtek[_cc,_p];
          _cBj := _cBankjegy[_cc,_p];
          wordbeiro(_clt);
          wordbeiro(_cBj);
          inc(_p);
        end;
      Zarobyteiro;
      inc(_cc);
    end;
  ZaroByteiro;
  Zarobyteiro;
  Closefile(_biniras);
  Modalresult := 1;
end;


// =============================================================================
                procedure TKisCimlet.Wordbeiro(_ww: word);
// =============================================================================

var _hi,_lo: byte;

begin
  _hi := trunc(_ww/256);
  _lo := _ww-trunc(256*_hi);
  _bytetomb[1] := _lo;
  _bytetomb[2] := _hi;
  Blockwrite(_biniras,_bytetomb,2);
end;

// =============================================================================
                      procedure TKiscimlet.Zarobyteiro;
// =============================================================================

begin
  _bytetomb[1] := 255;
  BlockWrite(_biniras,_bytetomb,1);
end;

procedure TKISCIMLET.FormCreate(Sender: TObject);
begin
   _height := screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top    := trunc((_height-768)/2);
  _left   := trunc((_width-1024)/2);

   top   := _top + 10;
  Left   := _left + 750;

end;


end.
