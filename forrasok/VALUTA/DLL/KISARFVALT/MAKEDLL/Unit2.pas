unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet,
  IBQuery, ExtCtrls, strutils, IBTable;

type
  TForm2 = class(TForm)

    ValutaQuery   : TIBQuery;
    ValutaDbase   : TIBDatabase;
    ValutaTranz   : TIBTransaction;

    CimVA         : TPanel;
    CimEA1        : TPanel;
    CimVK1        : TPanel;
    CimEK1        : TPanel;
    CimSHKex      : TPanel;
    CimSHKVetel   : TPanel;
    CimVF1        : TPanel;
    CimEF1        : TPanel;
    CupPanel      : TPanel;
    CupPanel2     : TPanel;
    DnemPanel     : TPanel;
    Dnem2Panel    : TPanel;
    FejCim1       : TPanel;
    HintPanel     : TPanel;
    IgArfPanel    : TPanel;
    LimPanel1     : TPanel;
    LimPanel2     : TPanel;
    LimPanel3     : TPanel;
    SHKCimPanel   : TPanel;
    SHKFuggony    : TPanel;
    TolArfPanel   : TPanel;
    UjArfPanel    : TPanel;

    CuppOkeGomb   : TBitBtn;
    CuppMegsemGomb: TBitBtn;
    VisszaGomb    : TBitBtn;

    Nyujto        : TTimer;
    Nyujto2       : TTimer;
    Kilepo        : TTimer;

    Shape1        : TShape;
    Shape2        : TShape;
    Shape3        : TShape;

    Label7        : TLabel;
    Label14       : TLabel;
    Label10       : TLabel;
    Label11       : TLabel;
    Label15       : TLabel;
    Label16       : TLabel;

    UjArfEdit     : TEdit;

    SHKOkeGomb    : TBitBtn;
    SHKMegsemGomb : TBitBtn;

    SP1           : TPanel;
    SP2           : TPanel;
    SP3           : TPanel;
    SP4           : TPanel;
    SP5           : TPanel;
    SP6           : TPanel;
    SP7           : TPanel;
    SP8           : TPanel;
    SP9           : TPanel;
    SP10          : TPanel;
    SP11          : TPanel;
    SP12          : TPanel;
    SP13          : TPanel;
    SP14          : TPanel;
    SP15          : TPanel;
    SP16          : TPanel;
    SP17          : TPanel;
    SP18          : TPanel;
    SP19          : TPanel;
    SP20          : TPanel;
    SP21          : TPanel;
    SP22          : TPanel;
    SP23          : TPanel;
    SP24          : TPanel;
    SP25          : TPanel;
    SP26          : TPanel;
    SP27          : TPanel;

    D1            : TPanel;
    D2            : TPanel;
    D3            : TPanel;
    D4            : TPanel;
    D5            : TPanel;
    D6            : TPanel;
    D7            : TPanel;
    D8            : TPanel;
    D9            : TPanel;
    D10           : TPanel;
    D11           : TPanel;
    D12           : TPanel;
    D13           : TPanel;
    D14           : TPanel;
    D15           : TPanel;
    D16           : TPanel;
    D17           : TPanel;
    D18           : TPanel;
    D19           : TPanel;
    D20           : TPanel;
    D21           : TPanel;
    D22           : TPanel;
    D23           : TPanel;
    D24           : TPanel;
    D25           : TPanel;
    D26           : TPanel;
    D27           : TPanel;

    N1            : TPanel;
    N2            : TPanel;
    N3            : TPanel;
    N4            : TPanel;
    N5            : TPanel;
    N6            : TPanel;
    N7            : TPanel;
    N8            : TPanel;
    N9            : TPanel;
    N10           : TPanel;
    N11           : TPanel;
    N12           : TPanel;
    N13           : TPanel;
    N14           : TPanel;
    N15           : TPanel;
    N16           : TPanel;
    N17           : TPanel;
    N18           : TPanel;
    N19           : TPanel;
    N20           : TPanel;
    N21           : TPanel;
    N22           : TPanel;
    N23           : TPanel;
    N24           : TPanel;
    N25           : TPanel;
    N26           : TPanel;
    N27           : TPanel;

    VA1           : TPanel;
    VA2           : TPanel;
    VA3           : TPanel;
    VA4           : TPanel;
    VA5           : TPanel;
    VA6           : TPanel;
    VA7           : TPanel;
    VA8           : TPanel;
    VA9           : TPanel;
    VA10          : TPanel;
    VA11          : TPanel;
    VA12          : TPanel;
    VA13          : TPanel;
    VA14          : TPanel;
    VA15          : TPanel;
    VA16          : TPanel;
    VA17          : TPanel;
    VA18          : TPanel;
    VA19          : TPanel;
    VA20          : TPanel;
    VA21          : TPanel;
    VA22          : TPanel;
    VA23          : TPanel;
    VA24          : TPanel;
    VA25          : TPanel;
    VA26          : TPanel;
    VA27          : TPanel;

    EA1           : TPanel;
    EA2           : TPanel;
    EA3           : TPanel;
    EA4           : TPanel;
    EA5           : TPanel;
    EA6           : TPanel;
    EA7           : TPanel;
    EA8           : TPanel;
    EA9           : TPanel;
    EA10          : TPanel;
    EA11          : TPanel;
    EA12          : TPanel;
    EA13          : TPanel;
    EA14          : TPanel;
    EA15          : TPanel;
    EA16          : TPanel;
    EA17          : TPanel;
    EA18          : TPanel;
    EA19          : TPanel;
    EA20          : TPanel;
    EA21          : TPanel;
    EA22          : TPanel;
    EA23          : TPanel;
    EA24          : TPanel;
    EA25          : TPanel;
    EA26          : TPanel;
    EA27          : TPanel;

    VK1           : TPanel;
    VK2           : TPanel;
    VK3           : TPanel;
    VK4           : TPanel;
    VK5           : TPanel;
    VK6           : TPanel;
    VK7           : TPanel;
    VK8           : TPanel;
    VK9           : TPanel;
    VK10          : TPanel;
    VK11          : TPanel;
    VK12          : TPanel;
    VK13          : TPanel;
    VK14          : TPanel;
    VK15          : TPanel;
    VK16          : TPanel;
    VK17          : TPanel;
    VK18          : TPanel;
    VK19          : TPanel;
    VK20          : TPanel;
    VK21          : TPanel;
    VK22          : TPanel;
    VK23          : TPanel;
    VK24          : TPanel;
    VK25          : TPanel;
    VK26          : TPanel;
    VK27          : TPanel;

    EK1           : TPanel;
    EK2           : TPanel;
    EK3           : TPanel;
    EK4           : TPanel;
    EK5           : TPanel;
    EK6           : TPanel;
    EK7           : TPanel;
    EK8           : TPanel;
    EK9           : TPanel;
    EK10          : TPanel;
    EK11          : TPanel;
    EK12          : TPanel;
    EK13          : TPanel;
    EK14          : TPanel;
    EK15          : TPanel;
    EK16          : TPanel;
    EK17          : TPanel;
    EK18          : TPanel;
    EK19          : TPanel;
    EK20          : TPanel;
    EK21          : TPanel;
    EK22          : TPanel;
    EK23          : TPanel;
    EK24          : TPanel;
    EK25          : TPanel;
    EK26          : TPanel;
    EK27          : TPanel;

    VF1           : TPanel;
    VF2           : TPanel;
    VF3           : TPanel;
    VF4           : TPanel;
    VF5           : TPanel;
    VF6           : TPanel;
    VF7           : TPanel;
    VF8           : TPanel;
    VF9           : TPanel;
    VF10          : TPanel;
    VF11          : TPanel;
    VF12          : TPanel;
    VF13          : TPanel;
    VF14          : TPanel;
    VF15          : TPanel;
    VF16          : TPanel;
    VF17          : TPanel;
    VF18          : TPanel;
    VF19          : TPanel;
    VF20          : TPanel;
    VF21          : TPanel;
    VF22          : TPanel;
    VF23          : TPanel;
    VF24          : TPanel;
    VF25          : TPanel;
    VF26          : TPanel;
    VF27          : TPanel;

    EF1           : TPanel;
    EF2           : TPanel;
    EF3           : TPanel;
    EF4           : TPanel;
    EF5           : TPanel;
    EF6           : TPanel;
    EF7           : TPanel;
    EF8           : TPanel;
    EF9           : TPanel;
    EF10          : TPanel;
    EF11          : TPanel;
    EF12          : TPanel;
    EF13          : TPanel;
    EF14          : TPanel;
    EF15          : TPanel;
    EF16          : TPanel;
    EF17          : TPanel;
    EF18          : TPanel;
    EF19          : TPanel;
    EF20          : TPanel;
    EF21          : TPanel;
    EF22          : TPanel;
    EF23          : TPanel;
    EF24          : TPanel;
    EF25          : TPanel;
    EF26          : TPanel;
    EF27          : TPanel;

    VX1           : TPanel;
    VX2           : TPanel;
    VX3           : TPanel;
    VX4           : TPanel;
    VX5           : TPanel;
    VX6           : TPanel;
    VX7           : TPanel;
    VX8           : TPanel;
    VX9           : TPanel;
    VX10          : TPanel;
    VX11          : TPanel;
    VX12          : TPanel;
    VX13          : TPanel;
    VX14          : TPanel;
    VX15          : TPanel;
    VX16          : TPanel;
    VX17          : TPanel;
    VX18          : TPanel;
    VX19          : TPanel;
    VX20          : TPanel;
    VX21          : TPanel;
    VX22          : TPanel;
    VX23          : TPanel;
    VX24          : TPanel;
    VX25          : TPanel;
    VX26          : TPanel;
    VX27          : TPanel;

    EX1           : TPanel;
    EX2           : TPanel;
    EX3           : TPanel;
    EX4           : TPanel;
    EX5           : TPanel;
    EX6           : TPanel;
    EX7           : TPanel;
    EX8           : TPanel;
    EX9           : TPanel;
    EX10          : TPanel;
    EX11          : TPanel;
    EX12          : TPanel;
    EX13          : TPanel;
    EX14          : TPanel;
    EX15          : TPanel;
    EX16          : TPanel;
    EX17          : TPanel;
    EX18          : TPanel;
    EX19          : TPanel;
    EX20          : TPanel;
    EX21          : TPanel;
    EX22          : TPanel;
    EX23          : TPanel;
    EX24          : TPanel;
    EX25          : TPanel;
    EX26          : TPanel;
    EX27          : TPanel;

    Label1        : TLabel;
    Label2        : TLabel;
    Label3        : TLabel;
    Label6        : TLabel;
    Label9        : TLabel;
    Label12       : TLabel;
    Label13       : TLabel;

    procedure FormActivate(Sender: TObject);
    procedure AdatNullazas;
    procedure ArfolyamBeolvasas;
    procedure BeCuppanas;
    procedure CellaRegeneracio;
    procedure CellaKijeloles;
    procedure CuppOkeGombClick(Sender: TObject);
    procedure EscapeGombClick(Sender: TObject);
    procedure GetCellaColor;
    procedure GetTablasoroszlop(_cnev: string);
    procedure KilepoTimer(Sender: TObject);
    procedure KurzorBeallitas;
    procedure NyujtoTimer(Sender: TObject);
    procedure Nyujto2Timer(Sender: TObject);
    procedure PanelFeltoltes;
    procedure ShkCuppanas;
    procedure SHKOkeGombClick(Sender: TObject);
    procedure SP1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure TombokbeToltes;
    procedure UjarfEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure VK2MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure VK2MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Vparancs(_ukaz: string);
    procedure VX2MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure VX2MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

    function Ftform(_num: integer): string;
    function Limformat(_int: integer):string;
    function Nulele(_int: integer): string;
    function ScanDnem(_adnem: string): integer;
    function VTempBeolvasas: boolean;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _dnem,_dnev: array[1..27] of string;
  _varf,_earf,_k1vet,_k2vet,_k1ela,_k2ela,_shkv,_shke: array[1..27] of integer;

  _dpanel,_npanel,_vaPanel,_eaPanel,_vkPanel,_ekPanel: array[1..27] of TPanel;
  _vfPanel,_efPanel,_vxPanel,_exPanel,_sp: array[1..27] of TPanel;

  _qDnem : array[1..6] of string;
  _sorveg: string = #13#10;

  _aktcella,_lastcella        : TPanel;
  _lastColor                  : TColor;

  _voltshk,_mayshk,_cellchange,_maymove: boolean;

  _tetel,_ss,_xx,_ratetype,_keziarfolyam: byte;

  _top,_left,_height,_width,_cc,_cellarow,_cellacolumn,_z    : word;
  _hpTop,_hpLeft                                             : word;

  _pp,_aktbankjegy,_mResult,_ujarfolyam,_sajatHataskoru,_kod : integer;
  _limit1,_limit2,_limit3,_recno,_cl,_ct,_ch,_cw             : integer;
  _qq,_aktbjegy,_aktosszeg,_cellasor,_cellaoszlop,_code      : integer;
  _tolarfolyam,_igarfolyam,_shkLimit,_aktlimit,_ujarfint     : integer;
  _aktmaxvarf,_aktminearf,_eurvetarf,_fizetendo,_index       : integer;

  _pcs,_cellatype,_cellaOszlopBetu,_tipus,_back,_aktdnem     : string;
  _aktdnev,_cellanev,_mess                                   : string;


Function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll';
function kisarfolyamkedvezmeny: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
         function kisarfolyamkedvezmeny: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.create(Nil);
  Result := Form2.Showmodal;
  Form2.Free;
end;

// =============================================================================
        procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin

  CupPanel.Visible  := False;
  CupPanel2.visible := False;
  HintPanel.Visible := False;

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;

  if _height>768 then _top := trunc((_height-768)/2);
  if _width>1024 then _left := trunc((_width-1024)/2);

  Top    := _top;
  Left   := _left;
  width  := 1024;
  Height := 768;

  _voltshk   := False;  // Sajáthatáskörü jelzõ flag alapra

  _lastColor := 0;
  _lastCella := Nil;
  _mayMove   := true;

  AdatNullazas;    // Arfolyam-tömbök kinullázása
  TombokbeToltes;  // A cellapanelek tömbökbe töltése

  if not VtempBeOlvasas then
    begin
      ShowMessage('Már minden valuta árfolyam kedvezményes');
      _mResult := -1;
      Kilepo.Enabled := true;
      exit;
    end;

  // Limitek és árfolyamok tömbbe olvasása 27 valutánál:
  ArfolyamBeolvasas;
  if _keziarfolyam=1 then
    begin
      Showmessage('KÉZI ÁRFOLYAMVÁLTOZTATÁS ! NINCS KEDVEZMÉNY');
      _mresult := 1;
      Kilepo.Enabled := true;
      exit;
    end;

  PanelFeltoltes;
  KurzorBeallitas;

  // Ha már mind az 5 lehetõség kimerült a függöny legördül:

  IF (_sajathataskoru>4) or (not _mayShk) then
    begin
      with SHKFuggony do
        begin
          Top     := 8;
          Left    := 812;
          Visible := True;
          Repaint;
        end;
    end;
  Cellakijeloles;
end;

// =============================================================================
        function TForm2.Limformat(_int: integer):string;
// =============================================================================

var _pp: integer;

begin
  result := inttostr(_int);
  _pp    := length(result);

  if _pp<4 then exit;

  if _pp>6 then
    begin
      _pp    := _pp - 6;
      result := leftstr(result,_pp)+'.'+midstr(result,_pp+1,3)+'.'+midstr(result,_pp+4,3);
      exit;
    end;
  _pp    := _pp-3;
  result := leftstr(result,_pp)+'.'+midstr(result,_pp+1,3);
end;

// =============================================================================
       function TForm2.ScanDnem(_adnem: string): integer;
// =============================================================================

begin
  result := 0;
  _z := 1;
  while _z<=27 do
    begin
      if _dnem[_z]=_adNem then
        begin
          result := _z;
          exit;
        end;
      inc(_z);
    end;
end;

// =============================================================================
        procedure TForm2.NYUJTOTimer(Sender: TObject);
// =============================================================================

begin
  Nyujto.enabled := false;

  _cl := _cl - 12;
  _ct := _ct -2;
  _cw := _cw + 24;
  _ch := _ch + 5;

  with cuppanel do
    begin
      top    := _ct;
      Left   := _cl;
      Height := _ch;
      Width  := _cw;
    end;
  if _cw<430 then Nyujto.Enabled := True
  else Activecontrol := CuppOkeGomb;
end;

// =============================================================================
        procedure TForm2.CUPPOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  CellaRegeneracio;

  if _aktdnem='JPY' then _ujarfolyam := _ujarfolyam*10;
  _ujarfint := round(_ujarfolyam);

  if _aktdnem='JPY' then _ujarfolyam := round(_ujarfint/10)
  else _ujarfolyam := _ujarfint;

  _pcs := 'UPDATE VTEMP SET ARFOLYAM=' + inttostr(_ujarfolyam);
  _PCS := _PCS + ',KEDVEZMENYESARFOLYAM=' + inttostr(_ujarfolyam);

  if _ratetype =0 then _pcs := _pcs + ',RATETYPE=1';

  _pcs := _pcs + ',SORENGEDMENY=1' + _sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39) + _aktdnem + chr(39);
  VParancs(_pcs);
  logirorutin(pchar('Pénztáros árfolyamengedményt ad: '+_aktdnem+' új árfolyama: '+inttostr(_ujarfolyam)));

  Modalresult := 1;
end;

// =============================================================================
               procedure TForm2.Vparancs(_ukaz: string);
// =============================================================================

begin
  ValutaDbase.Connected := true;
  if ValutaTranz.InTransaction then ValutaTranz.Commit;
  Valutatranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Execsql;
    end;
  ValutaTranz.Commit;
  Valutadbase.Close;
end;


// =============================================================================
        function TForm2.Nulele(_int: integer): string;
// =============================================================================

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;


// =============================================================================
           procedure TForm2.NYUJTO2Timer(Sender: TObject);
// =============================================================================

begin
   Nyujto2.enabled := false;

  _cw := _cw + 20;
  _ch := _ch + 10;

  with CupPanel2 do
    begin
      Height := _ch;
      Width  := _cw;
    end;
  if _cw<430 then Nyujto2.Enabled := True
  else ActiveControl := SHKOkeGomb;
end;


// =============================================================================
        procedure TForm2.SHKOkeGombClick(Sender: TObject);
// =============================================================================

var _arfs: string;

begin

  CellaRegeneracio;

  _arfs := trim(ujArfEdit.Text);
  val(_arfs,_ujArfolyam,_code);

  if _code<>0 then _ujArfolyam:=0;

  if (_ujArfolyam<_tolArfolyam) or (_ujArfolyam>_igArfolyam) then
    begin
      CupPanel2.Visible := False;
      Exit;
    end;

   if _aktdnem='JPY' then _ujArfolyam := _ujArfolyam*10;
  _ujArfInt := round(_ujArfolyam);

  if _aktDnem='JPY' then _ujArfolyam := round(_ujArfInt/10)
  else _ujArfolyam := _ujArfInt;

  _pcs := 'UPDATE VTEMP SET ARFOLYAM=' + inttostr(_ujArfolyam);
  _pcs := _pcs + ',SORENGEDMENY=2';
  if _ratetype<2 then _pcs := _pcs + ',RATETYPE=2';
  _PCS := _PCS + ',KEDVEZMENYESARFOLYAM=' + inttostr(_ujArfolyam) + _sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39) + _aktDnem + chr(39);
  VParancs(_pcs);

  _mess := 'Sajáthatáskörü engedmény= '+_aktdnem+' új árfolyam: '+ inttostr(_UJARFOLYAM);
  logirorutin(pchar(_mess));

  ModalResult := 2;
end;

// =============================================================================
        procedure TForm2.UjArfEDITKeyDown(Sender: TObject;
// =============================================================================

var Key: Word; Shift: TShiftState);

begin
  if ord(key)<>13 then exit;
  if ujArfEdit.Text = '' then exit;
  ActiveControl := ShkOkeGomb;
end;

// =============================================================================
         procedure TForm2.EscapeGombClick(Sender: TObject);
// =============================================================================

begin
  CellaRegeneracio;
  ModalResult := -1;
end;

// =============================================================================
        procedure TForm2.GetTablaSorOszlop(_cNev: string);
// =============================================================================

var _ww: integer;

begin
  _cellaType := leftstr(_cNev,1);
  _cellaOszlopBetu := midstr(_cNev,2,1);
  _ww := length(_cNev);
  _cellaSor := strtoint(midstr(_cNev,3,_ww-2));

  if _cellaOszlopBetu='K' then _cellaOszlop := 5;
  if _cellaOszlopBetu='F' then _cellaOszlop := 7;
  if _cellaOszlopBetu='X' then _cellaOszlop := 9;
  if _cellaType='E' then inc(_cellaOszlop);

  _cellaRow    := 76 + trunc(21*_cellaSor);
  _cellaColumn := 424 + trunc(97*(_cellaOszlop-5));

end;

// =============================================================================
            procedure TForm2.CellaRegeneracio;
// =============================================================================

begin
  if _lastColor=0 then exit;

  _lastCella.Color := _lastColor;
  _lastCella.Font.Color := clBlack;
  _cellChange := False;
end;


// =============================================================================
                  procedure TForm2.GetCellaColor;
// =============================================================================

begin
   _lastCella := _aktCella;
   _lastColor := _aktCella.Color;

   _aktCella.Color := clRed;
   _aktCella.Font.Color := clWhite;
   _cellChange := True;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// ------------------------- EGÉR MÜVELETEK ------------------------------------
// =============================================================================
       procedure TForm2.SP1MouseMove(Sender: TObject;
                                          Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  if not _mayMove then exit;
  HintPanel.Visible := False;
  CellaRegeneracio;
end;

// =============================================================================
       procedure TForm2.VK2MouseMove(Sender: TObject;
                                            Shift: TShiftState; X, Y: Integer);
// =============================================================================


begin
  if not _mayMove then exit;

  _aktCella := TPanel(sender);
  if (_aktCella.Cursor<>crHandPoint) then
    begin
      CellaRegeneracio;
      Exit;
    end;

  if not _cellChange  then GetCellaColor;

  _cellaNev := uppercase(_aktCella.Name);
  GetTablasorOszlop(_cellaNev);

  _hpTop := _cellaRow - 80;
  _hpLeft := _cellaColumn-73;

  HintPanel.Top     := _hpTop;
  HintPanel.Left    := _hpLeft;
  HintPanel.Visible := True;
end;

// =============================================================================
        procedure TForm2.VK2MouseDown(Sender: TObject;
                      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  if not _mayMove then exit;

  HintPanel.Visible := False;
  _aktCella := Tpanel(Sender);
  if _aktCella.Cursor<>crHandPoint then Exit;
  if Button<>mbLeft then exit;
   _mayMove := False;

  _cellaNev := _aktCella.Name;
  GetTablaSorOszlop(_cellaNev);
  BeCuppanas;
end;

// =============================================================================
         procedure TForm2.VX2MouseMove(Sender: TObject;
                                           Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin

  if not _mayMove then exit;
  if not _mayShk then exit;

  _aktCella := TPanel(Sender);
  if (_aktCella.Cursor<>crHandPoint) then
    begin
      CellaRegeneracio;
      Exit;
    end;

  if not _cellChange  then GetcellaColor;

  _cellaNev := uppercase(_aktCella.Name);
  GetTablasorOszlop(_cellanev);

  _hpTop := _cellaRow - 80;
  _hpLeft := 740;

  HintPanel.Top     := _hpTop;
  HintPanel.Left    := _hpLeft;
  HintPanel.Visible := True;

end;


// =============================================================================
      procedure TForm2.VX2MouseDown(Sender: TObject;
                     Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  if not _mayMove then Exit;
  if not _mayShk then Exit;

  HintPanel.Visible := False;

  _aktCella := Tpanel(Sender);
  if _aktCella.Cursor<>crHandPoint then Exit;
  if Button<>mbLeft then Exit;

  _mayMove := False;

  _cellaNev := _aktCella.Name;
  GetTablaSorOszlop(_cellaNev);
  ShkCuppanas;
end;

// ----------------------------- BECUPPANÁSOK ----------------------------------
// =============================================================================
                 procedure TForm2.Becuppanas;
// =============================================================================

begin
  _index := _cellaSor;
  if _cellaOszlopBetu='K' then
    begin
      if _cellaType='V' then _ujArfolyam := _k1vet[_index]
      else _ujArfolyam := _k1ela[_index];
    end else
    begin
      if _cellaType='V' then _ujArfolyam := _k2vet[_index]
      else _ujArfolyam := _k2ela[_index];
    end;
  _aktDnem := _dnem[_index];

  dNemPanel.Caption := _aktdnem;
  UjArfPanel.Caption := ftform(_ujArfolyam);

  _ct := _cellaRow -75;
  _cl := _cellaColumn-60;
  _ch := 35;
  _cw := 190;

  with CupPanel do
    begin
      width   := _cw;
      height  := _ch;
      top     := _ct;
      left    := _cl;
      Visible := True;
    end;
  Nyujto.Enabled := True;
end;

// =============================================================================
                 procedure TForm2.Shkcuppanas;
// =============================================================================


begin
  if _sajatHataskoru>4 then
    begin
      Showmessage('A MAI NAPON MÁR 5 SAJÁTHATÁSKÖRÜ BIZONYLAT VOLT. TÖBBRE NINCS LEHETÕSÉG');
      Exit;
    end;

   _index   := _cellasor;
   _aktdnem := _dnem[_index];
   if _cellatype='E' then
      begin
        _igArfolyam := _earf[_index];
        _tolArfolyam:= _shke[_index];
      end else
      begin
        _tolArfolyam := _varf[_index];
        _igArfolyam  := _shkv[_index];
      end;

  Dnem2Panel.Caption  := _aktDnem;
  TolarfPanel.Caption := ftform(_tolArfolyam);
  IgArfPanel.Caption  := ftform(_igArfolyam);

  if (_Tipus='V') then UjArfedit.Text := inttostr(_igArfolyam)
  else UjArfedit.Text := inttostr(_tolArfolyam);

  _ch := 65;
  _cw := 190;
  _ct := _cellaRow-80;
  if _ct>520 then _ct := 520;

  with cupPaneL2 do
    begin
      width   := _cw;
      height  := _ch;
      top     := _ct;
      left    := 460;
      Visible := True;
    end;
  Nyujto2.Enabled := True;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
/////////////////////  KIS ARFOLYAM KEDVEZMÉNY MEGADÁSA  ///////////////////////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
              procedure TForm2.TombokbeToltes;
// =============================================================================

begin

  // A 27 valuta sorának alappanelje:

  _sp[1]  := sp1;
  _sp[2]  := sp2;
  _sp[3]  := sp3;
  _sp[4]  := sp4;
  _sp[5]  := sp5;
  _sp[6]  := sp6;
  _sp[7]  := sp7;
  _sp[8]  := sp8;
  _sp[9]  := sp9;
  _sp[10] := sp10;
  _sp[11] := sp11;
  _sp[12] := sp12;
  _sp[13] := sp13;
  _sp[14] := sp14;
  _sp[15] := sp15;
  _sp[16] := sp16;
  _sp[17] := sp17;
  _sp[18] := sp18;
  _sp[19] := sp19;
  _sp[20] := sp20;
  _sp[21] := sp21;
  _sp[22] := sp22;
  _sp[23] := sp23;
  _sp[24] := sp24;
  _sp[25] := sp25;
  _sp[26] := sp26;
  _sp[27] := sp27;

  // A valuta-nemek paneljei:

  _dPanel[1]  := D1;
  _dPanel[2]  := D2;
  _dPanel[3]  := D3;
  _dPanel[4]  := D4;
  _dPanel[5]  := D5;
  _dPanel[6]  := D6;
  _dPanel[7]  := D7;
  _dPanel[8]  := D8;
  _dPanel[9]  := D9;
  _dPanel[10] := D10;
  _dPanel[11] := D11;
  _dPanel[12] := D12;
  _dPanel[13] := D13;
  _dPanel[14] := D14;
  _dPanel[15] := D15;
  _dPanel[16] := D16;
  _dPanel[17] := D17;
  _dPanel[18] := D18;
  _dPanel[19] := D19;
  _dPanel[20] := D20;
  _dPanel[21] := D21;
  _dPanel[22] := D22;
  _dPanel[23] := D23;
  _dPanel[24] := D24;
  _dPanel[25] := D25;
  _dPanel[26] := D26;
  _dPanel[27] := D27;

  // A valutanevek paneljei:

  _nPanel[1]  := N1;
  _nPanel[2]  := N2;
  _nPanel[3]  := N3;
  _nPanel[4]  := N4;
  _nPanel[5]  := N5;
  _nPanel[6]  := N6;
  _nPanel[7]  := N7;
  _nPanel[8]  := N8;
  _nPanel[9]  := N9;
  _nPanel[10] := N10;
  _nPanel[11] := N11;
  _nPanel[12] := N12;
  _nPanel[13] := N13;
  _nPanel[14] := N14;
  _nPanel[15] := N15;
  _nPanel[16] := N16;
  _nPanel[17] := N17;
  _nPanel[18] := N18;
  _nPanel[19] := N19;
  _nPanel[20] := N20;
  _nPanel[21] := N21;
  _nPanel[22] := N22;
  _nPanel[23] := N23;
  _nPanel[24] := N24;
  _nPanel[25] := N25;
  _nPanel[26] := N26;
  _nPanel[27] := N27;

  // A vételi alapárfolyamok paneljei:

  _vaPanel[1]  := VA1;
  _vaPanel[2]  := VA2;
  _vaPanel[3]  := VA3;
  _vaPanel[4]  := VA4;
  _vaPanel[5]  := VA5;
  _vaPanel[6]  := VA6;
  _vaPanel[7]  := VA7;
  _vaPanel[8]  := VA8;
  _vaPanel[9]  := VA9;
  _vaPanel[10] := VA10;
  _vaPanel[11] := VA11;
  _vaPanel[12] := VA12;
  _vaPanel[13] := VA13;
  _vaPanel[14] := VA14;
  _vaPanel[15] := VA15;
  _vaPanel[16] := VA16;
  _vaPanel[17] := VA17;
  _vaPanel[18] := VA18;
  _vaPanel[19] := VA19;
  _vaPanel[20] := VA20;
  _vaPanel[21] := VA21;
  _vaPanel[22] := VA22;
  _vaPanel[23] := VA23;
  _vaPanel[24] := VA24;
  _vaPanel[25] := VA25;
  _vaPanel[26] := VA26;
  _vaPanel[27] := VA27;

  // Az eladási alapárfolyamok paneljei:

  _eaPanel[1]  := EA1;
  _eaPanel[2]  := EA2;
  _eaPanel[3]  := EA3;
  _eaPanel[4]  := EA4;
  _eaPanel[5]  := EA5;
  _eaPanel[6]  := EA6;
  _eaPanel[7]  := EA7;
  _eaPanel[8]  := EA8;
  _eaPanel[9]  := EA9;
  _eaPanel[10] := EA10;
  _eaPanel[11] := EA11;
  _eaPanel[12] := EA12;
  _eaPanel[13] := EA13;
  _eaPanel[14] := EA14;
  _eaPanel[15] := EA15;
  _eaPanel[16] := EA16;
  _eaPanel[17] := EA17;
  _eaPanel[18] := EA18;
  _eaPanel[19] := EA19;
  _eaPanel[20] := EA20;
  _eaPanel[21] := EA21;
  _eaPanel[22] := EA22;
  _eaPanel[23] := EA23;
  _eaPanel[24] := EA24;
  _eaPanel[25] := EA25;
  _eaPanel[26] := EA26;
  _eaPanel[27] := EA27;

  // A kisebb vételi árfolyam-kedvezmény paneljei:

  _vkPanel[1]  := VK1;
  _vkPanel[2]  := VK2;
  _vkPanel[3]  := VK3;
  _vkPanel[4]  := VK4;
  _vkPanel[5]  := VK5;
  _vkPanel[6]  := VK6;
  _vkPanel[7]  := VK7;
  _vkPanel[8]  := VK8;
  _vkPanel[9]  := VK9;
  _vkPanel[10] := VK10;
  _vkPanel[11] := VK11;
  _vkPanel[12] := VK12;
  _vkPanel[13] := VK13;
  _vkPanel[14] := VK14;
  _vkPanel[15] := VK15;
  _vkPanel[16] := VK16;
  _vkPanel[17] := VK17;
  _vkPanel[18] := VK18;
  _vkPanel[19] := VK19;
  _vkPanel[20] := VK20;
  _vkPanel[21] := VK21;
  _vkPanel[22] := VK22;
  _vkPanel[23] := VK23;
  _vkPanel[24] := VK24;
  _vkPanel[25] := VK25;
  _vkPanel[26] := VK26;
  _vkPanel[27] := VK27;

  // A kisebb eladási árfolyam-kedvezmény paneljei:

  _ekPanel[1]  := EK1;
  _ekPanel[2]  := EK2;
  _ekPanel[3]  := EK3;
  _ekPanel[4]  := EK4;
  _ekPanel[5]  := EK5;
  _ekPanel[6]  := EK6;
  _ekPanel[7]  := EK7;
  _ekPanel[8]  := EK8;
  _ekPanel[9]  := EK9;
  _ekPanel[10] := EK10;
  _ekPanel[11] := EK11;
  _ekPanel[12] := EK12;
  _ekPanel[13] := EK13;
  _ekPanel[14] := EK14;
  _ekPanel[15] := EK15;
  _ekPanel[16] := EK16;
  _ekPanel[17] := EK17;
  _ekPanel[18] := EK18;
  _ekPanel[19] := EK19;
  _ekPanel[20] := EK20;
  _ekPanel[21] := EK21;
  _ekPanel[22] := EK22;
  _ekPanel[23] := EK23;
  _ekPanel[24] := EK24;
  _ekPanel[25] := EK25;
  _ekPanel[26] := EK26;
  _ekPanel[27] := EK27;

  // A nagyobb vételi árfolyam-kedvezmény paneljei:

  _vfPanel[1]  := VF1;
  _vfPanel[2]  := VF2;
  _vfPanel[3]  := VF3;
  _vfPanel[4]  := VF4;
  _vfPanel[5]  := VF5;
  _vfPanel[6]  := VF6;
  _vfPanel[7]  := VF7;
  _vfPanel[8]  := VF8;
  _vfPanel[9]  := VF9;
  _vfPanel[10] := VF10;
  _vfPanel[11] := VF11;
  _vfPanel[12] := VF12;
  _vfPanel[13] := VF13;
  _vfPanel[14] := VF14;
  _vfPanel[15] := VF15;
  _vfPanel[16] := VF16;
  _vfPanel[17] := VF17;
  _vfPanel[18] := VF18;
  _vfPanel[19] := VF19;
  _vfPanel[20] := VF20;
  _vfPanel[21] := VF21;
  _vfPanel[22] := VF22;
  _vfPanel[23] := VF23;
  _vfPanel[24] := VF24;
  _vfPanel[25] := VF25;
  _vfPanel[26] := VF26;
  _vfPanel[27] := VF27;

  // A nagyobb eladási árfolyam-kedvezmény paneljei:

  _efPanel[1]  := EF1;
  _efPanel[2]  := EF2;
  _efPanel[3]  := EF3;
  _efPanel[4]  := EF4;
  _efPanel[5]  := EF5;
  _efPanel[6]  := EF6;
  _efPanel[7]  := EF7;
  _efPanel[8]  := EF8;
  _efPanel[9]  := EF9;
  _efPanel[10] := EF10;
  _efPanel[11] := EF11;
  _efPanel[12] := EF12;
  _efPanel[13] := EF13;
  _efPanel[14] := EF14;
  _efPanel[15] := EF15;
  _efPanel[16] := EF16;
  _efPanel[17] := EF17;
  _efPanel[18] := EF18;
  _efPanel[19] := EF19;
  _efPanel[20] := EF20;
  _efPanel[21] := EF21;
  _efPanel[22] := EF22;
  _efPanel[23] := EF23;
  _efPanel[24] := EF24;
  _efPanel[25] := EF25;
  _efPanel[26] := EF26;
  _efPanel[27] := EF27;

  // A sajáthatáskörü vételi árfolyamkedvezmények paneljei:

  _vxPanel[1]  := VX1;
  _vxPanel[2]  := VX2;
  _vxPanel[3]  := VX3;
  _vxPanel[4]  := VX4;
  _vxPanel[5]  := VX5;
  _vxPanel[6]  := VX6;
  _vxPanel[7]  := VX7;
  _vxPanel[8]  := VX8;
  _vxPanel[9]  := VX9;
  _vxPanel[10] := VX10;
  _vxPanel[11] := VX11;
  _vxPanel[12] := VX12;
  _vxPanel[13] := VX13;
  _vxPanel[14] := VX14;
  _vxPanel[15] := VX15;
  _vxPanel[16] := VX16;
  _vxPanel[17] := VX17;
  _vxPanel[18] := VX18;
  _vxPanel[19] := VX19;
  _vxPanel[20] := VX20;
  _vxPanel[21] := VX21;
  _vxPanel[22] := VX22;
  _vxPanel[23] := VX23;
  _vxPanel[24] := VX24;
  _vxPanel[25] := VX25;
  _vxPanel[26] := VX26;
  _vxPanel[27] := VX27;

  // A saját hatáskörü eladási árfolyam-kedvezmény paneljei:

  _exPanel[1]  := EX1;
  _exPanel[2]  := EX2;
  _exPanel[3]  := EX3;
  _exPanel[4]  := EX4;
  _exPanel[5]  := EX5;
  _exPanel[6]  := EX6;
  _exPanel[7]  := EX7;
  _exPanel[8]  := EX8;
  _exPanel[9]  := EX9;
  _exPanel[10] := EX10;
  _exPanel[11] := EX11;
  _exPanel[12] := EX12;
  _exPanel[13] := EX13;
  _exPanel[14] := EX14;
  _exPanel[15] := EX15;
  _exPanel[16] := EX16;
  _exPanel[17] := EX17;
  _exPanel[18] := EX18;
  _exPanel[19] := EX19;
  _exPanel[20] := EX20;
  _exPanel[21] := EX21;
  _exPanel[22] := EX22;
  _exPanel[23] := EX23;
  _exPanel[24] := EX24;
  _exPanel[25] := EX25;
  _exPanel[26] := EX26;
  _exPanel[27] := EX27;
end;

// =============================================================================
            procedure TForm2.AdatNullazas;
// =============================================================================

begin
  _z := 1;
  while _z<=27 do
    begin
      _dnem[_z]  := '';
      _dNev[_z]  := '';
      _varf[_z]  := 0;
      _earf[_z]  := 0;
      _k1vet[_z] := 0;
      _k1ela[_z] := 0;
      _k2vet[_z] := 0;
      _k2ela[_z] := 0;
       _shkv[_z] := 0;
       _shke[_z] := 0;

       inc(_z);
    end;
end;

// =============================================================================
          procedure TForm2.ArfolyamBeolvasas;
// =============================================================================

begin
  _pcs := 'SELECT * FROM HARDWARE' + _sorveg;

  valutaDbase.connected := True;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;

      _limit1 := FieldByName('LIMIT1').asInteger;
      _limit2 := FieldByName('LIMIT2').asInteger;
      _limit3 := FieldByName('LIMIT3').asInteger;
      _sajatHataskoru := FieldByNAme('SAJATHATASKORU').asInteger;
      _keziarfolyam := FieldByName('KEZIARFOLYAM').asInteger;

      close;
    end;

  _pcs := 'SELECT* FROM ARFOLYAM' + _sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM<>'+chr(39)+'RCH'+chr(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  with ValutaQuery do
     begin
       Close;
       Sql.Clear;
       Sql.Add(_pcs);
       Open;
       First;
     end;

   _cc := 0;
   while not ValutaQuery.eof do
     begin
       _aktDnem := ValutaQuery.FieldByName('VALUTANEM').asString;
       if _aktDnem<>'HUF' then
         begin
           inc(_cc);
           _dnem[_cc] := _aktDnem;

           with ValutaQuery do
             begin
               _dNev[_cc] := trim(FieldByNAme('VALUTANEV').asstring);
               _vArf[_cc] := FieldByNAme('VETELIARFOLYAM').asInteger;
               _eArf[_cc] := FieldByNAme('ELADASIARFOLYAM').asInteger;
               _k1Vet[_cc]:= FieldByName('K1VETEL').asInteger;
               _k2Vet[_cc]:= FieldByName('K2VETEL').asInteger;
               _k1Ela[_cc]:= FieldByName('K1ELADAS').asInteger;
               _k2Ela[_cc]:= FieldByName('K2ELADAS').asInteger;
               _shkv[_cc] := FieldByName('SHKVETARFOLYAM').asInteger;
               _shke[_cc] := FieldByName('SHKELADARFOLYAM').asInteger;
             end;
           if _aktDnem='EUR' then _eurVetArf := _varf[_cc];
         end;
       ValutaQuery.Next;
     end;

   _mayShk    := False;
   _shkLimit  := trunc(10*_eurVetArf);

   if _fizetendo>=_shkLimit then _mayShk := True;

   ValutaQuery.close;
   ValutaDbase.close;
end;

// =============================================================================
               function TForm2.VtempBeolvasas: boolean;
// =============================================================================

begin
  Result := False;
  ValutaDbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM VTEMP WHERE SORENGEDMENY=0');
      Open;
      _recno := Recno;
    end;

  if _recno=0 then
    begin
      ValutaQuery.Close;
      Valutadbase.Close;
      exit;
    end;

  with ValutaQuery do
    begin
      _tetel     := FieldByNAme('TETEL').asInteger;
      _tipus     := FieldByName('TIPUS').asstring;
      _ratetype  := FieldByName('RATETYPE').asInteger;
      _fizetendo := FieldByNAme('FIZETENDO').asInteger;
    end;

  _z := 0;
  while not ValutaQuery.eof do
    begin
      inc(_z);
      _qDnem[_z] := valutaQuery.FieldbyNAme('VALUTANEM').asString;
      if _tetel=_z then Break;
      ValutaQuery.Next;
    end;
  ValutaQuery.close;
  ValutaDbase.close;
  Result := True;
end;


// =============================================================================
            procedure TForm2.PanelFeltoltes;
// =============================================================================

begin
  _z := 1;
  while _z<=27 do
    begin
      _dpanel[_z].Caption  := _dnem[_z];
      _nPanel[_z].Caption  := _dNev[_z];
      _vaPanel[_z].Caption := ftform(_varf[_z]);
      _eaPanel[_z].Caption := ftform(_earf[_z]);
      _vkPanel[_z].Caption := ftform(_k1vet[_z]);
      _ekPanel[_z].Caption := ftform(_k1ela[_z]);
      _vfPanel[_z].Caption := ftform(_k2vet[_z]);
      _efPanel[_z].Caption := ftform(_k2ela[_z]);
      _vxPanel[_z].Caption := ftform(_shkv[_z]);
      _exPanel[_z].Caption := ftform(_shke[_z]);

      inc(_z);
    end;
end;

// =============================================================================
             function TForm2.Ftform(_num: integer): string;
// =============================================================================

var _len,_ff: byte;

begin
  _back := inttostr(_num);
  _len   := length(_back);

  if _len>3 then
    begin
      _ff := _len-3;
      _back := leftstr(_back,_ff)+','+midstr(_back,_ff+1,3);
    end;
  result := _back;
end;

// =============================================================================
                   procedure TForm2.KurzorBeallitas;
// =============================================================================

begin
  _z := 1;
  while _z<=27 do
    begin
      _sp[_z].Color := clGray;

      _vkpanel[_z].Cursor := crDefault;
      _ekpanel[_z].Cursor := crDefault;
      _vfpanel[_z].Cursor := crDefault;
      _efpanel[_z].Cursor := crDefault;
      _vxpanel[_z].Cursor := crDefault;
      _expanel[_z].Cursor := crDefault;

      inc(_z);
    end;
end;

// =============================================================================
              procedure TForm2.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  ModalResult := _mResult;
end;

// =============================================================================
                    procedure TForm2.CellaKijeloles;
// =============================================================================

begin
  if _tipus='V' then
    begin
 //     if _fizetendo>=_limit1 then
 //       begin
          _ss := 1;
          while _ss<=_tetel do
            begin
              _aktdnem := _qDnem[_ss];

              _xx := scandnem(_aktDnem);
              _vkPanel[_xx].Cursor := crHandPoint;
          //    if _fizetendo>=_limit2 then
               _vfPanel[_xx].Cursor:= crHandPoint;
              if _mayShk then _vxPanel[_xx].Cursor := crHandPoint;
              inc(_ss);
            end;
  //      end;
    end;

  if _tipus='E' then
    begin
 //     if _fizetendo>=_limit1 then
 //       begin
          _ss := 1;
          while _ss<=_tetel do
            begin
              _aktDnem := _qDnem[_ss];

              _xx := scanDnem(_aktDnem);
              _ekPanel[_xx].Cursor := crHandPoint;
          //    if _fizetendo>=_limit2 then
               _efPanel[_xx].Cursor:= crHandPoint;
              if _mayShk then _exPanel[_xx].Cursor := crHandPoint;
              inc(_ss);
            end;
//        end;
    end;
end;



end.
