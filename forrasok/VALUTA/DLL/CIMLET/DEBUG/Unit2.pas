unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, strutils, Buttons, IBDatabase, DB, IBQuery,
  IBCustomDataSet, IBTable;

type
  TCimletezes = class(TForm)

    AktDnemPanel  : TPanel;

    Cc1           : TPanel;
    Cc2           : TPanel;
    Cc3           : TPanel;
    Cc4           : TPanel;
    Cc5           : TPanel;
    Cc6           : TPanel;
    Cc7           : TPanel;
    Cc8           : TPanel;
    Cc9           : TPanel;
    Cc10          : TPanel;
    Cc11          : TPanel;
    Cc12          : TPanel;
    Cc13          : TPanel;
    Cc14          : TPanel;

    Dd1           : TPanel;
    Dd2           : TPanel;
    Dd3           : TPanel;
    Dd4           : TPanel;
    Dd5           : TPanel;
    Dd6           : TPanel;
    Dd7           : TPanel;
    Dd8           : TPanel;
    Dd9           : TPanel;
    Dd10          : TPanel;
    Dd11          : TPanel;
    Dd12          : TPanel;
    Dd13          : TPanel;
    Dd14          : TPanel;
    Dd15          : TPanel;
    Dd16          : TPanel;
    Dd17          : TPanel;
    Dd18          : TPanel;
    Dd19          : TPanel;
    Dd20          : TPanel;
    Dd21          : TPanel;
    Dd22          : TPanel;
    Dd23          : TPanel;
    Dd24          : TPanel;
    Dd25          : TPanel;
    Dd26          : TPanel;
    Dd27          : TPanel;
    ExitGomb      : TPanel;
    InfPanel      : TPanel;
    KellSummaPanel: TPanel;
    Nn1           : TPanel;
    Nn2           : TPanel;
    Nn3           : TPanel;
    Nn4           : TPanel;
    Nn5           : TPanel;
    Nn6           : TPanel;
    Nn7           : TPanel;
    Nn8           : TPanel;
    Nn9           : TPanel;
    Nn10          : TPanel;
    Nn11          : TPanel;
    Nn12          : TPanel;
    Nn13          : TPanel;
    Nn14          : TPanel;
    Nn15          : TPanel;
    Nn16          : TPanel;
    Nn17          : TPanel;
    Nn18          : TPanel;
    Nn19          : TPanel;
    Nn20          : TPanel;
    Nn21          : TPanel;
    Nn22          : TPanel;
    Nn23          : TPanel;
    Nn24          : TPanel;
    Nn26          : TPanel;
    Nn27          : TPanel;
    Nn25          : TPanel;
    Panel1        : TPanel;
    QuitGomb      : TPanel;
    Rr1           : TPanel;
    Rr2           : TPanel;
    Rr3           : TPanel;
    Rr4           : TPanel;
    Rr5           : TPanel;
    Rr6           : TPanel;
    Rr7           : TPanel;
    Rr8           : TPanel;
    Rr9           : TPanel;
    Rr10          : TPanel;
    Rr11          : TPanel;
    Rr12          : TPanel;
    Rr13          : TPanel;
    Rr14          : TPanel;
    SftPanel      : TPanel;

    Ed1           : TEdit;
    Ed2           : TEdit;
    Ed3           : TEdit;
    Ed4           : TEdit;
    Ed5           : TEdit;
    Ed6           : TEdit;
    Ed7           : TEdit;
    Ed8           : TEdit;
    Ed9           : TEdit;
    Ed10          : TEdit;
    Ed11          : TEdit;
    Ed12          : TEdit;
    Ed13          : TEdit;
    Ed14          : TEdit;

    Shape1        : TShape;
    Shape2        : TShape;
    Shape3        : TShape;
    Shape4        : TShape;
    Shape5        : TShape;
    Shape6        : TShape;
    Shape7        : TShape;
    Shape8        : TShape;
    Shape9        : TShape;
    Shape10       : TShape;
    Shape11       : TShape;
    Shape12       : TShape;
    Shape13       : TShape;
    Shape14       : TShape;
    Shape15       : TShape;
    FocimPanel    : TPanel;

    Kk1           : TShape;
    Kk2           : TShape;
    Kk3           : TShape;
    Kk4           : TShape;
    Kk5           : TShape;
    Kk6           : TShape;
    Kk7           : TShape;
    Kk8           : TShape;
    Kk9           : TShape;
    Kk10          : TShape;
    Kk11          : TShape;
    Kk12          : TShape;
    Kk13          : TShape;
    Kk14          : TShape;
    Kk15          : TShape;
    Kk16          : TShape;
    Kk17          : TShape;
    Kk18          : TShape;
    Kk19          : TShape;
    Kk20          : TShape;
    Kk21          : TShape;
    Kk22          : TShape;
    Kk23          : TShape;
    Kk24          : TShape;
    Kk25          : TShape;
    Kk26          : TShape;
    Kk27          : TShape;
    Shape16       : TShape;

    KilepoTimer   : TTimer;

    IbTabla       : TIBTable;
    IbQuery       : TIBQuery;
    IbDbase       : TIBDatabase;
    IbTranz       : TIBTransaction;

    CQuery        : TIBQuery;
    CDbase        : TIBDatabase;
    CTranz        : TIBTransaction;


    procedure CimletbeMasolas;
    procedure Cimskip(_lep: integer);
    procedure ConfigInstall;
    procedure Ed1Enter(Sender: TObject);
    procedure Ed1Exit(Sender: TObject);
    procedure Ed1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ExitGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure IbParancs(_ukaz: string);
    procedure KilepoTimerTimer(Sender: TObject);
    procedure Kimasol;
    procedure NN1Click(Sender: TObject);
    procedure NN1MouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
    procedure Nullazo;
    procedure QuitGombClick(Sender: TObject);
    procedure RrSummazas;
    procedure SaveCimini;
    procedure Shape16MouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
    procedure UjDevizatValasztott;
    procedure ValutanevPanelTorles;

    function CiminiBeolvasas: byte;
    function F4(_n: integer): string;
    function Ftform(_num,_hh: integer): string;
    function IniBedolgozas: boolean;
    function Scandnem(_ds: string): integer;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Cimletezes: TCimletezes;

   _dkesz,_ckesz  : array[1..27] of integer;
   _maycim        : array[1..27,1..14] of boolean;
   _ccim          : array[1..27,1..14] of integer;
   _dd,_nn        : array[1..27] of TPanel;
   _cm            : array[1..14] of word;

   _ready,_vankesz: array[1..27] of byte;
   _kk            : array[1..27] of Tshape;

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

  _cimlet: array[1..14] of integer = (20000,10000,5000,2000,1000,500,200,100,
                                          50,20,10,5,2,1);

  _aktcimp,
  _cimflag: array[1..14] of boolean;

  _cc,
  _rr: array[1..14] of TPanel;

  _ed: array[1..14] of TEdit;

  _bytetomb: array[1..2048] of byte;
  _sorveg  : string = chr(13)+chr(10);
  _LF5     : string  = #27#97#5;   // 5 sor emelés

   _alloke : boolean;

  _olvas,_iras: File of byte;

  _aktbankjegy,_aktkeszlet,_cimkeszlet,_aktcimkeszlet,_aktbj,_aktrr: integer;
  _aktDevertek,_bankjegy,_billkod,_csorszam,_cimlettype,_code: integer;
  _css,_devsorszam,_lasttag,_mResult,_num,_qq,_sumdevertek,_xx: integer;

  _aktcn,_aktdnem,_cimletfile,_cimletFilePath,_focim,_nums,_cns,_pcs: string;
  _aktdnev,_megnyitottnap: string;

  _c1,_c2,_cx,_aktready,_inistatus,_utpiros,_hi,_lo,_hlo,_hhi: byte;
  _top,_left,_width,_height,_filemeret,_needhossz,_pp: word;

  _aktedit: Tedit;


function cimletezorutin:integer;stdcall;
function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';


implementation

{$R *.dfm}

// =============================================================================
            function cimletezorutin:integer;stdcall;
// =============================================================================

begin
  Cimletezes := TCimletezes.create(Nil);
  result := Cimletezes.ShowModal;
  Cimletezes.Free;
end;

// =============================================================================
                procedure TCimletezes.FormCreate(Sender: TObject);
// =============================================================================

begin
   ibdbase.Connected := true;
   with ibquery do
     begin
       Close;
       sql.clear;
       sql.add('SELECT * FROM HARDWARE');
       Open;
       _cimletType    := FieldByName('MENETSZAM').asInteger;
       _megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').AsString);
       Close;
     end;
   ibdbase.close;

  _dD[1] := DD1;
  _dD[2] := DD2;
  _dD[3] := DD3;
  _dD[4] := DD4;
  _dD[5] := DD5;
  _dD[6] := DD6;
  _dD[7] := DD7;
  _dD[8] := DD8;
  _dD[9] := DD9;
  _dD[10]:= DD10;
  _dD[11]:= DD11;
  _dD[12]:= DD12;
  _dD[13]:= DD13;
  _dD[14]:= DD14;
  _dD[15]:= DD15;
  _dD[16]:= DD16;
  _dD[17]:= DD17;
  _dD[18]:= DD18;
  _dD[19]:= DD19;
  _dD[20]:= DD20;
  _dD[21]:= DD21;
  _dd[22]:= DD22;
  _dd[23]:= DD23;
  _dd[24]:= DD24;
  _dd[25]:= DD25;
  _dd[26]:= DD26;
  _dd[27]:= DD27;

  _nn[1] := Nn1;
  _nn[2] := Nn2;
  _nn[3] := Nn3;
  _nn[4] := Nn4;
  _nn[5] := Nn5;
  _nn[6] := Nn6;
  _nn[7] := Nn7;
  _nn[8] := Nn8;
  _nn[9] := Nn9;
  _nn[10]:= Nn10;
  _nn[11]:= Nn11;
  _nn[12]:= Nn12;
  _nn[13]:= Nn13;
  _nn[14]:= Nn14;
  _nn[15]:= Nn15;
  _nn[16]:= Nn16;
  _nn[17]:= Nn17;
  _nn[18]:= Nn18;
  _nn[19]:= Nn19;
  _nn[20]:= Nn20;
  _nn[21]:= Nn21;
  _nn[22]:= Nn22;
  _nn[23]:= Nn23;
  _nn[24]:= Nn24;
  _nn[25]:= Nn25;
  _nn[26]:= Nn26;
  _nn[27]:= Nn27;


  _kk[1] := KK1;
  _kk[2] := KK2;
  _kk[3] := KK3;
  _kk[4] := KK4;
  _kk[5] := KK5;
  _kk[6] := KK6;
  _kk[7] := KK7;
  _kk[8] := KK8;
  _kk[9] := KK9;
  _kk[10]:= KK10;
  _kk[11]:= KK11;
  _kk[12]:= KK12;
  _kk[13]:= KK13;
  _kk[14]:= KK14;
  _kk[15]:= KK15;
  _kk[16]:= KK16;
  _kk[17]:= KK17;
  _kk[18]:= KK18;
  _kk[19]:= KK19;
  _kk[20]:= KK20;
  _kk[21]:= KK21;
  _kk[22]:= KK22;
  _kk[23]:= KK23;
  _kk[24]:= KK24;
  _kk[25]:= KK25;
  _kk[26]:= KK26;
  _kk[27]:= KK27;

  _ed[1] := ED1;
  _ed[2] := ED2;
  _ed[3] := ED3;
  _ed[4] := ED4;
  _ed[5] := ED5;
  _ed[6] := ED6;
  _ed[7] := ED7;
  _ed[8] := ED8;
  _ed[9] := ED9;
  _ed[10]:= ED10;
  _ed[11]:= ED11;
  _ed[12]:= ED12;
  _ed[13]:= ED13;
  _ed[14]:= ED14;

  _cc[1] := CC1;
  _cc[2] := CC2;
  _cc[3] := CC3;
  _cc[4] := CC4;
  _cc[5] := CC5;
  _cc[6] := CC6;
  _cc[7] := CC7;
  _cc[8] := CC8;
  _cc[9] := CC9;
  _cc[10]:= CC10;
  _cc[11]:= CC11;
  _cc[12]:= CC12;
  _cc[13]:= CC13;
  _cc[14]:= CC14;

  _rr[1] := Rr1;
  _rr[2] := Rr2;
  _rr[3] := Rr3;
  _rr[4] := Rr4;
  _rr[5] := Rr5;
  _rr[6] := Rr6;
  _rr[7] := Rr7;
  _rr[8] := Rr8;
  _rr[9] := Rr9;
  _rr[10]:= Rr10;
  _rr[11]:= Rr11;
  _rr[12]:= Rr12;
  _rr[13]:= Rr13;
  _rr[14]:= Rr14;
end;


// =============================================================================
              procedure TCIMLETEZES.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top := trunc((_height-768)/2);
  _left := trunc((_width-1024)/2);

  Top := _top;
  Left := _left;
  Height := 768;
  Width := 1024;

  _allOke := False;
  ExitGomb.Color := clWhite;
  ExitGomb.Font.Color := clBlack;
  ExitGomb.Caption := 'CÍMLETEZÉS MÉG NEM EGYEZIK - KILÉPÉS';
  exitgomb.Repaint;

  case _cimletType of
    1: _focim := 'VALUTA PÉNZTÁR CÍMLETEZÉSE';
    2: _focim := 'KEZELÉSI KÖLTSÉG CÍMLETEZÉSE';
    3: _focim := 'WESTERN UNION PÉNZTÁR CÍMLETEZÉSE';
    4: _focim := 'ÁFA PÉNZTÁR CÍMLETEZÉSE';
    5: _focim := 'AZ ÜGYFÉL FOGLALÓ CÍMLETEZÉSE';
    6: _focim := 'E-KERESKEDELEM CÍMLETEZÉSE';
    7: _focim := 'ÁTADAS-ÁTVÉTEL CÍMLETEZÉSE';
    8: _focim := 'AXA BIZTOSITÁS CÍMLETEZÉSE';
    9: _focim := 'MONEYGRAM KÉZSLET CÍMLETEZÉSE';
  end;

  Focimpanel.Caption := _focim;
  Focimpanel.Repaint;

  // Maycim beolvasása _maycim[dnemsorszam,csorszam]= true or false
  ConfigInstall;

  // Cimletezö display kitakatritása:
  Nullazo;

  _inistatus := CimInibeolvasas;
  if _inistatus=3 then
    begin
      ShowMessage('NINCS MIT CÍMLETEZNI');
      _mResult := 1;
      KilepoTimer.Enabled := true;
      exit;
    end;

  {
  if _inistatus>1 then
    begin
      if _inistatus>1 then
        begin
          case _inistatus of
             2: _Mresult := 2;
             3: Showmessage('NINCS MIT CIMLETEZNI');
             4: ShowMessage('HIBÁS A CIMINI FILE');
          end;
          KilepoTimer.enabled := True;
          exit;
        end;
    end;
   }

  if Inibedolgozas then
    begin
       ExitGomb.Color := clRed;
       ExitGomb.Font.Color := clYellow;
       ExitGomb.Caption := 'CIMLETEK RENDBEN - TOVÁBB';
       _allOke := True;
       Activecontrol := ExitGomb;
    end;
end;


// =============================================================================
                     function TCimletezes.F4(_n: integer): string;
// =============================================================================

begin
  result := '';
  if _n=0 then exit;

  result := inttostr(_n);

  if _n<1000 then
    begin
      while length(result)<5 do result := ' '+result;
    end else
    begin
      result := leftstr(result,1)+' '+midstr(result,2,3);
    end;
end;


// =============================================================================
                         procedure Tcimletezes.Nullazo;
// =============================================================================

var i: integer;
begin
  for i := 1 to 14 do
    begin
      _ed[i].Text    := '';
      _rr[i].Caption := '';
    end;

  for i := 1 to 27 do
    begin
      _vankesz[i] := 0;
      _ready[i]   := 0;
      _ckesz[i]   := 0;
      _dkesz[i]   := 0;

      // dnem-ek háttér szürkitése

      with _dd[i] do
        begin
          Font.color := $c0c0c0;
          Enabled := False;
        end;

      // dnevek háttér szürkitése:

      with _nn[i] do
        begin
          Font.color := $c0c0c0;
          Enabled := False;
        end;


      // A négyzetshape-k grafirozasa és szürkitése:

      _kk[i].Brush.Style := bsDiagCross;
      _kk[i].Brush.Color := clSilver;

    end;

  _utpiros := 0;
  Sftpanel.Caption := '';         // cimletezett összeg panel
  KellSummaPanel.Caption := '';   // ennyinek kell lenni az összegnek
  AktDnemPanel.Caption := '';     // nincs aktuális valutanem
end;



// =============================================================================
    procedure TCIMLETEZES.NN1MouseMove(Sender: TObject; Shift: TShiftState; X,
                                                                  Y: Integer);
// =============================================================================


var _dPanel,_nPanel: TPanel;
    _dss: integer;


begin
  _dss := TPanel(sender).Tag;
//  if _ready[_dss]=0 then exit;
  if _utPiros=_dss then exit;
  _utpiros := _dss;
  ValutanevPanelTorles;

  _dPanel := _dd[_dss];
  _nPanel := _nn[_dss];

  with _dPanel do
    begin
      color := clRed;
      Font.Color := clWhite;
    end;
  with _nPanel do
    begin
      color := clRed;
      Font.Color := clwhite;
    end;
end;


// =============================================================================
   procedure TCIMLETEZES.Shape16MouseMove(Sender: TObject; Shift: TShiftState;
                                                               X, Y: Integer);
// =============================================================================


begin
  ValutaNevPanelTorles;
end;

// =============================================================================
                procedure TCimletezes.ValutanevPanelTorles;
// =============================================================================


var i: integer;
    _dPanel,_nPanel: TPanel;

begin
   for i := 1 to 27 do
    begin
      _dPanel := _dd[i];
      _nPanel := _nn[i];
      _dPanel.Color := clBtnFace;
      _nPanel.Color := clBtnface;
      _dPanel.Font.Color := clBlack;
      _nPanel.Font.Color := clBlack;
    end;
end;


// =============================================================================
                function TCimletezes.ScanDnem(_ds: string): integer;
// =============================================================================

var _y: byte;

begin
  result := 0;
  _y := 1;
  while _y<=27 do
    begin
      if _dnem[_y]=_ds then
        begin
          result := _y;
          Break;
        end;
      inc(_y);
    end;
end;

// =============================================================================
           procedure TCIMLETEZES.KILEPOTIMERTimer(Sender: TObject);
// =============================================================================

begin
  Kilepotimer.Enabled := false;
  if (exitgomb.color=clRed) then Modalresult :=1 else Modalresult := 2;
end;

// =============================================================================
                        function TCimletezes.Inibedolgozas: boolean;
// =============================================================================

begin
  result := True;
  _qq := 1;
  while _qq<=27 do
    begin
      if _vankesz[_qq]=1 then
        begin
          _dd[_qq].Font.Color := clBlack;
          _nn[_qq].Font.Color := clBlack;
          _dd[_qq].Enabled := True;
          _nn[_qq].Enabled := True;
          _kk[_qq].Brush.Style := bsSolid;

          if _ready[_qq]=1 then _kk[_qq].Brush.Color := clred
          else begin
            _kk[_qq].Brush.Color := clWhite;
            result := False;
          end;
       end;

      inc(_qq);
    end;
end;


// =============================================================================
              procedure TCIMLETEZES.NN1Click(Sender: TObject);
// =============================================================================

begin
  _devsorszam := Tpanel(Sender).Tag;
  UjdevizatValasztott;
end;

// =============================================================================
                     procedure Tcimletezes.UjdevizatValasztott;
// =============================================================================

var i: integer;

begin
  for i := 1 to 14 do
    begin
      with _ed[i] do
        begin
          Visible := false;
          Caption := '';
          Enabled := False;
        end;

      with _rr[i] do
        begin
          Visible := false;
          Caption := '';
        end;

      _cimflag[i] := False;
      _cc[i].Font.Color := $c0c0c0;
    end;

  _aktdnem := _dnem[_devsorszam];
  AktdnemPanel.Caption := _aktdnem;

  _aktdevErtek := _dkesz[_devsorszam];
  KellSummaPanel.Caption := FormatFloat('### ### ###',_aktdevertek);

  for i := 1 to 14 do _aktcimp[i] := _maycim[_devsorszam,i];

  for i := 1 to 14 do
    begin
      if _aktcimp[i] then
        begin
          _cimFlag[i] := True;

          _cc[i].Font.Color := clBlack;

          _ed[i].color := clWhite;
          _rr[i].Color := clBtnFace;

          _ed[i].Visible := true;
          _ed[i].Enabled := True;
          _rr[i].Visible := True;

          _aktbj := _cCim[_devsorszam,i];
          _ed[i].Text := ftform(_aktbj,4);
        end;
    end;
   RRSummazas;
   CImskip(1);

end;

// =============================================================================
                      procedure TCimletezes.RRsummazas;
// =============================================================================

var i: integer;

begin
  _sumDevErtek := 0;
  for i := 1 to 14 do
    begin
      if _cimflag[i] then
        begin
          _aktbj := _cCim[_devsorszam,i];
          _aktrr := trunc(_cimlet[i]*_aktbj);
          _rr[i].Caption := Ftform(_aktrr,9);
          _sumDevErtek := _sumDevErtek + _aktrr;
        end;
    end;

   SftPanel.Caption := Ftform(_sumDevertek,9);
   _ckesz[_devsorszam] := _sumDevertek;

    if _sumDevertek<>_aktdevertek then
     begin
       aktdnemPanel.color := $FFB0FF;
       AktdnemPanel.Font.Color := clNavy;

       KellSummaPanel.Color := $FFB0FF;
       KellsummaPanel.Font.Color := clNavy;

       SftPanel.Color := $FFBAFF;
       SftPanel.Font.Color := clNavy;
       _kk[_devsorszam].brush.Color := clwhite;
       _ready[_devsorszam] := 0;


       Exitgomb.Color := clWhite;
       Exitgomb.Font.Color := clBlack;
       ExitGomb.Caption := 'CÍMLETEZÉS MÉG NEM EGYEZIK - KILÉPÉS';
       exitgomb.Repaint;
     end else
     begin
       aktdnemPanel.color := clYellow;
       AktdnemPanel.Font.Color := clRed;

       KellSummaPanel.Color := clYellow;
       KellsummaPanel.Font.Color := clRed;

       SftPanel.Color := clYellow;
       SftPanel.Font.Color := clRed;
       _ready[_devsorszam] := 1;

       _kk[_devsorszam].brush.Color := clRed;
       if Inibedolgozas then
          begin
            Exitgomb.Color :=clRed;
            Exitgomb.Font.Color := clYellow;
            ExitGomb.Caption := 'CIMLETEK RENDBEN - TOVÁBB';
            Activecontrol := ExitGomb;
          end;


     end;
end;



// =============================================================================
         function TCimletezes.Ftform(_num,_hh: integer): string;
// =============================================================================

var _s1: byte;

begin
  result := inttostr(_num);
  if _hh=4 then
    begin
      if _num<1000 then
        begin
          while length(result)<5 do result := ' ' + result;
          exit;
        end;
      result := leftstr(result,1)+' '+midstr(result,2,3);
      exit;
    end;

  if _num<1000 then
    begin
      while length(result)<11 do result := ' '+ result;
      exit;
    end;
  if _num<1000000 then
    begin
      _s1 := length(result)-3;
      result := leftstr(result,_s1)+ ' ' + midstr(result,_s1+1,3);
    end else
    begin
      _s1 := length(result)-6;
      result := leftstr(result,_s1)+' '+midstr(result,_s1+1,3)+' '+midstr(result,_s1+4,3);
    end;
  while length(result)<11 do result := ' ' + result;
end;

// =============================================================================
                   procedure TCimletezes.COnfigInstall;
// =============================================================================

var i,j,_darab,_pp,_pt: integer;
    _txtolvas: Textfile;
    _fPath,_mondat: string;

begin
  for i := 1 to 27 do
    begin
      for j := 1 to 14 do _maycim[i,j] := False;
    end;

  _fpath := 'c:\valuta\cimlet.cfg';
  Assignfile(_txtolvas,_fpath);
  Reset(_txtOlvas);

  while not eof(_txtolvas) do
    begin
      readLn(_txtOlvas,_mondat);
      _aktdnem := leftstr(_mondat,3);
      if (_aktdnem='EUA') OR (_aktdnem='RCH') then continue;


      _darab := ord(_mondat[4])-65;
      _xx := ScanDnem(_aktdnem);
      _pp := 1;

      while _pp<=_darab do
        begin
          _pt := ord(_mondat[4+_pp])-65;
          _maycim[_xx,_pt] := True;
          inc(_pp);
        end;
    end;
  Closefile(_txtolvas);
end;


// =============================================================================
       procedure TCIMLETEZES.ed1KeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  _billkod := ord(key);
  if (_billkod=13) or (_billkod=40) then
    begin
      Kimasol;
      Cimskip(1);
      Exit;
    end;

  if (_billkod=38)  then
    begin
      Kimasol;
      Cimskip(-1);
      Exit;
    end;
end;

// =============================================================================
                       procedure TCimletezes.Kimasol;
// =============================================================================

begin
  _aktedit := _ed[_csorszam];
  val(_aktedit.text,_aktbankjegy,_code);
  if _code<>0 then _aktbankjegy := 0;

  _aktedit.text := ftform(_aktbankjegy,4);
  _ccim[_devsorszam,_csorszam] := _aktbankjegy;
  RRsummazas;
end;

// =============================================================================
                procedure Tcimletezes.Cimskip(_lep: integer);
// =============================================================================

begin
  if _lep=1 then
    begin
      while _csorszam<15 do
        begin
          inc(_csorszam);
          if _csorszam>14 then _csorszam := 1;
          if _cimflag[_csorszam] then break;
        end;
    end else
    begin
      while _csorszam>0 do
        begin
          dec(_csorszam);
          if _csorszam=0 then _csorszam := 14;
          if _cimflag[_csorszam] then break;
        end;
    end;
  _aktedit := _ed[_csorszam];
  _aktedit.setfocus;

end;


// =============================================================================
             procedure TCIMLETEZES.ed1Enter(Sender: TObject);
// =============================================================================

begin
   _csorszam := Tedit(Sender).Tag;
   _rr[_csorszam].color := clYellow;
  _ed[_csorszam].color := clYellow;
end;


// =============================================================================
             procedure TCIMLETEZES.ed1Exit(Sender: TObject);
// =============================================================================

var i: integer;
begin
   for i := 1 to 14 do
     begin
       _rr[i].color := clBtnface;
       _ed[i].color := clWindow;
     end;
end;

// =============================================================================
                procedure TCimletezes.IbParancs(_ukaz: string);
// =============================================================================

begin
  ibdbase.connected := true;
  if ibtranz.Intransaction then ibtranz.commit;
  ibtranz.StartTransaction;

  with Ibquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  ibtranz.commit;
  ibdbase.close;
end;

// =============================================================================
                     procedure TCimletezes.SaveCimini;
// =============================================================================

var _y: byte;
    _acc: array[1..14] of word;
    _aktc: word;
    _mezo: string;

begin

  _pcs := 'UPDATE CIMINI SET CIMLETEZETT=0,READY=0,CIMLET1=0,CIMLET2=0,';
  _pcs := _pcs + 'CIMLET3=0,CIMLET4=0,CIMLET5=0,CIMLET6=0,CIMLET7=0,';
  _pcs := _pcs + 'CIMLET8=0,CIMLET9=0,CIMLET10=0,CIMLET11=0,CIMLET12=0,';
  _pcs := _pcs + 'CIMLET13=0,CIMLET14=0' + _sorveg;
  _pcs := _pcs + 'WHERE CIMLETTYPE='+inttostr(_cimlettype);
  ibParancs(_pcs);

  _xx := 1;
  while _xx<=27 do
    begin
      _aktkeszlet := _dKesz[_xx];
      if _aktkeszlet>0 then
        begin
          _aktdnem := _dnem[_xx];
          _aktcimkeszlet := _cKesz[_xx];
          _aktready := _ready[_xx];
          _y := 1;
          while _y<=14 do
            begin
              _acc[_y] := _ccim[_xx,_y];
              inc(_y);
            end;
          _pcs := 'UPDATE CIMINI SET CIMLETEZETT=' + inttostr(_aktcimkeszlet);
          _pcs := _pcs + ',READY=' + inttostr(_aktready);

          _y := 1;
          while _y<=14 do
            begin
               _mezo := 'CIMLET' + inttostr(_y);
              _aktc := _acc[_y];
              _pcs := _pcs + ',' + _mezo + '=' + inttostr(_aktc);
              inc(_y);
            end;
          _pcs := _pcs + 'WHERE (CIMLETTYPE=' + inttostr(_cimlettype)+')';
          _pcs := _pcs + ' AND (VALUTANEM=' + chr(39) + _aktdnem + chr(39) + ')';
          ibParancs(_pcs);
        end;
      inc(_xx);
    end;
end;


// =============================================================================
            procedure TCIMLETEZES.EXITGOMBClick(Sender: TObject);
// =============================================================================

begin
  Exitgomb.Visible := False;
  InfPanel.Repaint;
  SaveCimini;
  if (_allOke) AND (_cimletType=1) then CimletbeMasolas;

  KilepoTimer.Enabled := true;
end;

// =============================================================================
            procedure TCimletezes.QuitGombClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := -1;
end;


// =============================================================================
                  function Tcimletezes.CiminiBeolvasas: byte;
// =============================================================================

var i,j,_ddb,_c: byte;
    _aktcimlet: integer;
    _mezo: string;

begin
   for i := 1 to 27 do
     begin
       _cKesz[i]   := 0;
       _dkesz[i]   := 0;
       _ready[i]   := 0;
       _vankesz[i] := 0;

       for j := 1 to 14 do _ccim[i,j] := 0;
     end;

  _pcs := 'SELECT * FROM CIMINI' + _sorveg;
  _pcs := _pcs + 'WHERE CIMLETTYPE=' + inttostr(_cimletType)+ _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  cdbase.Connected := True;
  with Cquery do
    begin
      Close;
      sql.clear;
      Sql.Add(_pcs);
      Open;
    end;

  _ddb := 0;
  result := 1;
  while not Cquery.eof do
    begin
      _aktdnem    := Cquery.FieldByName('VALUTANEM').asString;
      _aktkeszlet := Cquery.fieldByName('AKTKESZLET').AsInteger;
      IF _aktdnem='HRK' then _aktkeszlet := 0;
      _xx := ScanDnem(_aktdnem);
      if _aktkeszlet>0 then
         begin
           inc(_ddb);
           _aktcimlet := Cquery.fieldByName('CIMLETEZETT').asInteger;
           _c := 1;
           while _c<=14 do
             begin
               _mezo := 'CIMLET' + inttostr(_c);
               _cm[_c] := Cquery.FieldByNAme(_mezo).asInteger;
               inc(_c);
             end;

           _dkesz[_xx] := _aktkeszlet;
           _ckesz[_xx] := _aktcimlet;
           _vankesz[_xx] := 1;

           if _aktkeszlet=_aktcimlet then
             begin
               _ready[_xx] := 1
             end else
             begin
               _ready[_xx] := 0;
               result := 2;
             end;

           for _c := 1 to 14 do _ccim[_xx,_c] := _cm[_c];
         end;
      Cquery.next;
    end;
  Cquery.close;
  Cdbase.close;

  if _ddb=0 then
    begin
      result := 3;
      exit;
    end;
end;

// =============================================================================
                      procedure TCimletezes.CimletbeMasolas;
// =============================================================================

var _y: byte;
    _mezo: string;

begin
  _pcs := 'DELETE FROM CIMLETEK';
  ibParancs(_pcs);

  _pcs := 'SELECT * FROM CIMINI' + _sorveg;
  _pcs := _pcs + 'WHERE (CIMLETTYPE=1) AND (AKTKESZLET>0)' + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  cdbase.connected := true;
  with Cquery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  while not Cquery.eof do
    begin
      _aktdnem := Cquery.FieldByName('VALUTANEM').asString;
      _xx := ScanDnem(_aktdnem);
      _aktdnev := _dnev[_xx];
      _cimkeszlet := Cquery.FieldByNAme('CIMLETEZETT').asInteger;
      _aktkeszlet := Cquery.FieldByname('AKTKESZLET').asInteger;
      _y := 1;
      while _y<=14 do
        begin
          _mezo := 'CIMLET' + inttostr(_y);
          _cm[_y] := Cquery.FieldByName(_mezo).asInteger;
          inc(_y);
        end;

      _pcs := 'INSERT INTO CIMLETEK (DATUM,VALUTANEM,VALUTANEV,OSSZESFORINTERTEK,';
      _pcs := _pcs + 'CIMLET1,CIMLET2,CIMLET3,CIMLET4,CIMLET5,CIMLET6,CIMLET7,';
      _pcs := _pcs + 'CIMLET8,CIMLET9,CIMLET10,CIMLET11,CIMLET12,CIMLET13,';
      _pcs := _pcs + 'CIMLET14)' + _sorveg;

      _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktdnev + chr(39) + ',';
      _pcs := _pcs + inttostr(_aktkeszlet) + ',';

      _y := 1;
      while _y<=13 do
        begin
          _pcs := _pcs + inttostr(_cm[_y]) + ',';
          inc(_y);
        end;
      _pcs := _pcs + inttostr(_cm[14]) + ')';
      ibParancs(_pcs);

      CQuery.next;
    end;
  Cquery.close;
  Cdbase.close;
end;
END.






