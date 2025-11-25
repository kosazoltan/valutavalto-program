unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, IBDatabase, DB, IBCustomDataSet,
  IBQuery, Strutils, DateUtils, Grids, Calendar, IBTable;

type
  TForm2 = class(TForm)

    VisszaGomb: TButton;
    Panel1: TPanel;

    Shape1 : TShape;
    Shape2 : TShape;
    SH1    : TShape;
    SH2    : TShape;
    SH3    : TShape;
    SH4    : TShape;
    SH5    : TShape;
    SH6    : TShape;
    SH7    : TShape;
    SH8    : TShape;
    SH9    : TShape;
    SH10   : TShape;
    SH11   : TShape;
    SH12   : TShape;
    SH13   : TShape;
    SH14   : TShape;
    SH15   : TShape;
    SH16   : TShape;
    SH17   : TShape;
    SH18   : TShape;
    SH19   : TShape;
    SH20   : TShape;
    SH21   : TShape;
    SH22   : TShape;
    SH23   : TShape;
    SH24   : TShape;
    SH25   : TShape;
    SH26   : TShape;
    SH27   : TShape;
    SH28   : TShape;
    SH29   : TShape;
    SH30   : TShape;
    SH31   : TShape;
    SH32   : TShape;
    SH33   : TShape;
    SH34   : TShape;
    SH35   : TShape;
    SH36   : TShape;
    SH37   : TShape;
    SH38   : TShape;
    SH39   : TShape;
    SH40   : TShape;
    SH41   : TShape;
    SH42   : TShape;
    SH43   : TShape;
    SH44   : TShape;
    SH45   : TShape;
    SH46   : TShape;
    SH47   : TShape;
    SH48   : TShape;
    SH49   : TShape;
    SH50   : TShape;
    SH51   : TShape;
    SH52   : TShape;
    SH53   : TShape;
    SH54   : TShape;
    SH55   : TShape;
    SH56   : TShape;
    SH57   : TShape;
    SH58   : TShape;
    SH59   : TShape;
    SH60   : TShape;
    SH61   : TShape;
    SH62   : TShape;
    SH63   : TShape;
    SH64   : TShape;
    SH65   : TShape;
    SH66   : TShape;
    SH67   : TShape;
    SH68   : TShape;
    SH69   : TShape;
    SH70   : TShape;
    SH71   : TShape;
    SH72   : TShape;
    SH73   : TShape;
    SH74   : TShape;
    SH75   : TShape;
    SH76   : TShape;
    SH77   : TShape;
    SH78   : TShape;
    SH79   : TShape;
    SH80   : TShape;
    SH81   : TShape;
    SH82   : TShape;
    SH83   : TShape;
    SH84   : TShape;
    SH85   : TShape;
    SH86   : TShape;
    SH87   : TShape;
    SH88   : TShape;
    SH89   : TShape;
    SH90   : TShape;
    SH91   : TShape;
    SH92   : TShape;
    SH93   : TShape;
    SH94   : TShape;
    SH95   : TShape;
    SH96   : TShape;
    SH97   : TShape;
    SH98   : TShape;
    SH99   : TShape;
    SH100  : TShape;
    SH101  : TShape;
    SH102  : TShape;
    SH103  : TShape;
    SH104  : TShape;
    SH105  : TShape;
    SH106  : TShape;
    SH107  : TShape;
    SH108  : TShape;
    SH109  : TShape;
    SH110  : TShape;
    SH111  : TShape;
    SH112  : TShape;
    SH113  : TShape;
    SH114  : TShape;
    SH115  : TShape;
    SH116  : TShape;
    SH117  : TShape;
    SH118  : TShape;
    SH119  : TShape;
    SH120  : TShape;
    SH121  : TShape;
    SH122  : TShape;
    SH123  : TShape;
    SH124  : TShape;
    SH125  : TShape;
    SH126  : TShape;
    SH127  : TShape;
    SH128  : TShape;
    SH129  : TShape;
    SH130  : TShape;
    SH131  : TShape;
    SH132  : TShape;
    SH133  : TShape;
    SH134  : TShape;
    SH135  : TShape;
    SH136  : TShape;
    SH137  : TShape;
    SH138  : TShape;
    SH139  : TShape;
    SH140  : TShape;
    SH141  : TShape;
    SH142  : TShape;
    SH143  : TShape;
    SH144  : TShape;
    SH145  : TShape;
    SH146  : TShape;
    SH147  : TShape;
    SH148  : TShape;
    SH149  : TShape;
    SH150  : TShape;
    SH151  : TShape;
    SH152  : TShape;
    SH153  : TShape;
    SH154  : TShape;
    SH155  : TShape;
    SH156  : TShape;
    SH157  : TShape;
    SH158  : TShape;
    SH159  : TShape;
    SH160  : TShape;
    SH161  : TShape;
    SH162  : TShape;
    SH163  : TShape;
    SH164  : TShape;
    SH165  : TShape;
    SH166  : TShape;
    SH167  : TShape;
    SH168  : TShape;
    SH169  : TShape;
    SH170  : TShape;

    Label1 : TLabel;
    pn1    : TLabel;
    pn2    : TLabel;
    pn3    : TLabel;
    pn4    : Tlabel;
    pn5    : TLabel;
    pn6    : TLabel;
    pn7    : TLabel;
    pn8    : TLabel;
    pn9    : TLabel;
    Pn10   : TLabel;
    Pn11   : TLabel;
    pn12   : TLabel;
    pn13   : TLabel;
    pn14   : TLabel;
    pn15   : TLabel;
    pn16   : TLabel;
    pn17   : TLabel;
    pn18   : TLabel;
    pn19   : TLabel;
    pn20   : TLabel;
    pn21   : TLabel;
    pn22   : TLabel;
    pn23   : TLabel;
    pn24   : TLabel;
    pn25   : TLabel;
    pn26   : TLabel;
    PN27   : TLabel;
    pN28   : TLabel;
    pN29   : TLabel;
    pN30   : TLabel;
    pN31   : TLabel;
    pN32   : TLabel;
    pN33   : TLabel;
    pN34   : TLabel;
    pN35   : TLabel;
    pN36   : TLabel;
    pN37   : TLabel;
    pN38   : TLabel;
    pN39   : TLabel;
    pN40   : TLabel;
    pN41   : TLabel;
    pN42   : TLabel;
    pN43   : TLabel;
    pN44   : TLabel;
    pN45   : TLabel;
    pN46   : TLabel;
    pN47   : TLabel;
    pN48   : TLabel;
    pN49   : TLabel;
    pN50   : TLabel;
    pN51   : TLabel;
    pN52   : TLabel;
    pN53   : TLabel;
    pN54   : TLabel;
    pN55   : TLabel;
    PN56   : TLabel;
    PN57   : TLabel;
    PN58   : TLabel;
    PN59   : TLabel;
    PN60   : TLabel;
    PN61   : TLabel;
    PN62   : TLabel;
    PN63   : TLabel;
    PN64   : TLabel;
    PN65   : TLabel;
    PN66   : TLabel;
    PN67   : TLabel;
    PN68   : TLabel;
    PN69   : TLabel;
    PN70   : TLabel;
    PN71   : TLabel;
    PN72   : TLabel;
    PN73   : TLabel;
    PN74   : TLabel;
    PN75   : TLabel;
    PN76   : TLabel;
    PN77   : TLabel;
    PN78   : TLabel;
    PN79   : TLabel;
    PN80   : TLabel;
    PN81   : TLabel;
    PN82   : TLabel;
    PN83   : TLabel;
    PN84   : TLabel;
    PN85   : TLabel;
    PN86   : TLabel;
    PN87   : TLabel;
    PN88   : TLabel;
    PN89   : TLabel;
    PN90   : TLabel;
    PN91   : TLabel;
    pn92   : TLabel;
    pn93   : TLabel;
    pn94   : TLabel;
    pn95   : TLabel;
    pn96   : TLabel;
    pn97   : TLabel;
    PN98   : TLabel;
    PN99   : TLabel;
    PN100  : TLabel;
    PN101  : TLabel;
    PN102  : TLabel;
    PN103  : TLabel;
    PN104  : TLabel;
    PN105  : TLabel;
    PN106  : TLabel;
    PN107  : TLabel;
    PN108  : TLabel;
    PN109  : TLabel;
    PN110  : TLabel;
    PN111  : TLabel;
    PN112  : TLabel;
    PN113  : TLabel;
    PN114  : TLabel;
    PN115  : TLabel;
    PN116  : TLabel;
    PN117  : TLabel;
    PN118  : TLabel;
    PN119  : TLabel;
    PN120  : TLabel;
    PN121  : TLabel;
    PN122  : TLabel;
    PN123  : TLabel;
    PN124  : TLabel;
    PN125  : TLabel;
    PN126    : TLabel;
    PN127    : TLabel;
    PN128    : TLabel;
    PN129    : TLabel;
    PN130    : TLabel;
    PN131    : TLabel;
    PN132    :  TLabel;
    PN133    : TLabel;
    PN134    : TLabel;
    PN135    : TLabel;
    PN136    : TLabel;
    PN137    : TLabel;
    PN138    : TLabel;
    PN139    : TLabel;
    PN140    : TLabel;
    PN141    : TLabel;
    PN142    : TLabel;
    PN143    : TLabel;
    PN144    : TLabel;
    PN145    : TLabel;
    PN146    : TLabel;
    PN147    : TLabel;
    PN148    : TLabel;
    PN149    : TLabel;
    PN150    : TLabel;
    PN151    : TLabel;
    PN152    : TLabel;
    PN153    : TLabel;
    PN154    : TLabel;
    PN155    : TLabel;
    PN156    : TLabel;
    PN157    : TLabel;
    PN158    : TLabel;
    PN159    : TLabel;
    PN160    : TLabel;
    PN161    : TLabel;
    PN162    : TLabel;
    PN163    : TLabel;
    PN164    : TLabel;
    pn165    : TLabel;
    PN166    : TLabel;
    PN167    : TLabel;
    PN168    : TLabel;
    PN169    : TLabel;
    PN170    : TLabel;

    Bevel1          : TBevel;
    Bevel2          : TBevel;

    ReceptorQuery   : TIBQuery;
    ReceptorDbase   : TIBDatabase;
    ReceptorTranz   : TIBTransaction;

    ArtQUERY        : TIBQuery;
    ArtDBASE        : TIBDatabase;
    ArtTRANZ        : TIBTransaction;

    DBookQUERY      : TIBQuery;
    DBookDBASE      : TIBDatabase;
    DBookTRANZ      : TIBTransaction;

    acDBookTABLA    : TIBTable;
    acDBookQUERY    : TIBQuery;
    acDBookDBASE    : TIBDatabase;
    acDBookTRANZ    : TIBTransaction;

    IrodaNevPanel   : TPanel;
    UzenoPanel      : TPanel;
    DatumPanel      : TPanel;
    DDatumPanel     : TPanel;
    NaptarPanel     : TPanel;
    ZarasJeloloPanel: TPanel;

    NAPTAR          : TCalendar;

    BitBtn2         : TBitBtn;
    EloHoGomb       : TBitBtn;
    KovHoGomb       : TBitBtn;
    DatumRendbenGomb: TBitBtn;
    DatumMegsemGomb : TBitBtn;
    ElozoNapGomb    : TBitBtn;
    KovetkezoNapGomb: TBitBtn;
    EgyPenztarGomb  : TBitBtn;
    AllPenztarGomb  : TBitBtn;
    JeloloVisszaGomb: TBitBtn;
    Label2          : TLabel;
    Label3          : TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    CIKLUS: TTimer;
    DBOOKTABLA: TIBTable;

    procedure AcDbookParancs(_ukaz: string);
    procedure AllPenztarGombClick(Sender: TObject);
    procedure Bejottdisp;
    procedure BitBtn2Click(Sender: TObject);
    procedure DatumMegsemGombClick(Sender: TObject);
    procedure DatumRendbenGombClick(Sender: TObject);
    procedure DbookBeolvaso;
    procedure DBookParancs(_ukaz: string);
    procedure DDisp;
    procedure EgyPenztarGombClick(Sender: TObject);
    procedure EloHoGombClick(Sender: TObject);
    procedure ElozoNAPGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure IrodaBetolto;
    procedure JeloloVisszaGombClick(Sender: TObject);
    procedure KovetkezoNapGombClick(Sender: TObject);
    procedure KovHoGombClick(Sender: TObject);
    procedure NaptarChange(Sender: TObject);
    procedure NemJottbeDisp;
    procedure NoPtarDisp;
    procedure Pn1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Pn1Click(Sender: TObject);
    procedure Tablaalapra;
    procedure Tablaszinezo;
    procedure Tombetolto;
    procedure VisszaGombClick(Sender: TObject);
    procedure ZarvaDisp;

    function Getaktmezo: string;
    function HunDateToStr(_d: Tdatetime): string;
    function Hunstrtodate(_s: string): TDatetime;
    function Nulele(_b: byte): string;
    procedure CIKLUSTimer(Sender: TObject);
   

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _aktDate: TDateTime;
  _aktshape: TShape;
  _aktnum  : TLabel;

  _napnev: array[1..7] of string = ('hétfõ','kedd','szerda','csütörtök','péntek',
                                      'szombat','vasárnap');

  _sh: array[1..170] of TShape;
  _pn: ARRAY[1..170] of TLabel;

  _irodanev,_zarva,_sunclose,_satclose,_status: array[1..170] of string;

  _pcs,_irnev,_closed,_aktdatums,_aktstatus,_farok,_aktdbook,_aktnaps: string;
  _aktmezo,_stat,_sunc,_satc,_aktho_nap,_aktnapnev,_filter: string;
  _mainaps: string;
  _sorveg: string = chr(13) + chr(10);
  _uzlet,_y,_pt,_aktnap,_akthetnap,_xx: byte;
  _code,_index: integer;


function zarasbeerkezesek: integer; stdcall;


implementation

{$R *.dfm}

function zarasbeerkezesek: integer; stdcall;
begin
  Form2 := TForm2.Create(Nil);
  result := Form2.showmodal;
  Form2.free;
end;


// =============================================================================
               procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top    := 158;
  Left   := 208;
  width  := 864;
  Height := 684;

  Tombetolto;
  TablaAlapra;
  Irodabetolto;
  Tablaszinezo;
  Ciklus.Enabled := True;
end;

// =============================================================================
                    procedure TForm2.Tablaszinezo;
// =============================================================================

begin
  Dbookbeolvaso;

  _y := 1;
  while _y<=170 do
    begin
      _aktstatus := _status[_y];

      if _aktstatus='B' then bejottdisp;
      if _aktstatus='X' then zarvadisp;
      if _aktstatus='N' then nemjottbedisp;
      if _aktstatus='0' then noptardisp;
      inc(_y);
    end;
end;

// =============================================================================
                          procedure TForm2.DBookbeolvaso;
// =============================================================================

var i: byte;

begin
  for i := 1 to 170 do _status[i] := '0';

  _farok    := midstr(_aktdatums,3,2)+midstr(_aktdatums,6,2);
  _aktdbook := 'DAYB' + _farok;

  _pcs := 'SELECT * FROM '+_aktdbook;
  _aktmezo := GetAktmezo;
  dbookdbase.connected := true;
  with dbookQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not Dbookquery.eof do
    begin
      _pt   := Dbookquery.FieldByName('PENZTAR').asInteger;
      _stat := trim(DbookQuery.FieldByNAme(_AKTMEZO).asString);

      if (_stat='B') or (_stat='X') then _status[_pt] := _stat;
      if _stat='' then _status[_pt] := 'N';

      Dbookquery.next;
    end;

  Dbookquery.close;
  Dbookdbase.close;

  // ------------------------------------------------------------------

  AcdbookDbase.connected := true;
  with Acdbookquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not AcDbookquery.eof do
    begin
      _pt   := AcDbookquery.FieldByName('PENZTAR').asInteger;
      _stat := AcDbookQuery.FieldByNAme(_AKTMEZO).asString;

      if (_stat='B') or (_stat='X') then _status[_pt] := _stat;
      if _stat='' then _status[_pt] := 'N';

      AcDbookquery.next;
    end;

  AcDbookquery.close;
  AcDbookdbase.close;
end;



// =============================================================================
                        procedure TForm2.Irodabetolto;
// =============================================================================

begin
  receptordbase.Connected := true;
  _pcs := 'SELECT * FROM RENDSZER';

  with ReceptorQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      _aktdatums := FieldByNAme('MUNKANAP').asString;
      Close;
    end;

  _mainaps   := _aktdatums;
  _aktdate   := Hunstrtodate(_aktdatums);
  _akthetnap := dayoftheweek(_aktdate);  // 6= szombat, 7= vasárnap
  _aktnapnev := _napnev[_akthetnap];
  _aktho_nap := midstr(_aktdatums,6,2)+midstr(_aktdatums,9,2);

  DatumPanel.Caption := _aktdatums+' '+_aktnapnev;
  DatumPanel.repaint;

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  with ReceptorQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  while not ReceptorQuery.eof do
    begin
      _uzlet    := ReceptorQuery.FieldByNAme('UZLET').asInteger;
      _irnev    := trim(ReceptorQuery.FieldByNAme('KESZLETNEV').asString);
      _closed   := ReceptorQuery.FieldByName('CLOSED').asString;

      _irodanev[_uzlet] := _irnev;
      _zarva[_uzlet]    := _closed;

      ReceptorQuery.next;
    end;
  receptorQuery.close;
  receptordbase.close;

  // ----------------------------------------------

  Artdbase.Connected := true;
  with ArtQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  while not ArtQuery.eof do
    begin
      _uzlet    := ArtQuery.FieldByNAme('UZLET').asInteger;
      _irnev    := trim(ArtQuery.FieldByNAme('KESZLETNEV').asString);
      _closed   := ArtQuery.FieldByName('CLOSED').asString;

      _irodanev[_uzlet] := _irnev;
      _zarva[_uzlet]    := _closed;

      ArtQuery.next;
    end;

  ArtQuery.close;
  Artdbase.close;
end;

// =============================================================================
                         procedure TForm2.TablaAlapra;
// =============================================================================

begin
  _y := 1;
  while _y<=170 do
    begin
      _aktshape := _sh[_y];
      _aktnum   := _pn[_y];

      _aktshape.Brush.Color := clwhite;
      _aktnum.Font.Color    := clBlack;

      inc(_y);
    end;
  IrodanevPanel.caption := '';
  UzenoPanel.caption    := '';
end;

procedure TForm2.Bejottdisp;
begin
  _aktshape := _sh[_y];
  _aktnum   := _pn[_y];

  _aktshape.Brush.Color := clYellow;
  _aktnum.Font.Color    := clNavy;
end;

// =============================================================================
                      procedure TForm2.NemJottbeDisp;
// =============================================================================

begin
  _aktshape := _sh[_y];
  _aktnum   := _pn[_y];

  _aktshape.Brush.Color := clRed;
  _aktnum.Font.Color    := clYellow;
end;

// =============================================================================
                          procedure TForm2.ZarvaDisp;
// =============================================================================

begin
  _aktshape := _sh[_y];
  _aktnum   := _pn[_y];

  _aktshape.Brush.Color := clSilver;
  _aktnum.Font.Color    := clBlack;
end;

// =============================================================================
                        procedure TForm2.NoPtarDisp;
// =============================================================================

begin
  _aktshape := _sh[_y];
  _aktnum   := _pn[_y];

  _aktshape.Brush.Color := clBlack;
  _aktnum.Font.Color    := clWhite;
end;

// =============================================================================
              function Tform2.Hunstrtodate(_s: string): TDatetime;
// =============================================================================

var _evs,_hos,_naps: string;
    _aev,_aho,_anap: word;

begin
  _evs  := leftstr(_s,4);
  _hos  := midstr(_s,6,2);
  _naps := midstr(_s,9,2);

  val(_evs,_aev,_code);
  val(_hos,_aho,_code);
  val(_naps,_anap,_code);

  result := encodedate(_aev,_aho,_anap);
end;

// =============================================================================
            procedure TForm2.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
      procedure TForm2.pn1MouseMove(Sender: TObject; Shift: TShiftState; X,
                                                                   Y: Integer);
// =============================================================================


var _ixs,_mess,_aktirnev: string;
    _pcol,_fcol : TColor;

begin
  _pcol := clWhite;
  _fcol := clBlack;

  _ixs := TLabel(sender).caption;
  val(_ixs,_xx,_code);

  _aktirnev  := _irodanev[_xx];
  _aktstatus := _status[_xx];

  IrodaNevPanel.Caption := _aktirnev;

  if _aktstatus='B' then
    begin
      _mess := 'A zárás bejött';
      _pcol := clLime;
      _fcol := clBlack;
    end;

  if _aktstatus='N' then
    begin
      _mess := 'Zárás még nem jött be';
      _pcol := clRed;
      _fcol := clYellow;
    end;

  if _aktstatus='X' then
    begin
      _mess := 'Pénztár zárva volt';
      _pcol := clSilver;
      _fcol := clBlack;
    end;

  if _aktstatus='0' then
    begin
      _mess := 'Itt nincs pénztár';
      _pcol := clBlack;
      _fcol := clWhite;
    end;

  with Uzenopanel do
    begin
      Caption    := _mess;
      color      := _pcol;
      Font.Color := _fcol;
      repaint;
    end;
end;


function TForm2.Getaktmezo: string;

begin
 _aktnaps := midstr(_aktdatums,9,2);
  val(_aktnaps,_aktnap,_code);
  result := 'N' + inttostr(_aktnap);
end;

// =============================================================================
             procedure TForm2.ELOHOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Naptar.PrevMonth;
  ddisp;
end;

// =============================================================================
              procedure TForm2.KOVHOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Naptar.NextMonth;
  Ddisp;
end;

// =============================================================================
                           procedure TForm2.DDisp;
// =============================================================================

begin
  _aktdate   := Naptar.CalendarDate;
  _aktdatums := Hundatetostr(_aktdate);
  if leftstr(_aktdatums,7)>leftstr(_Mainaps,7) then
    begin
      showmessage('A KÉRT NAP A JÖVÖBEN LESZ');
      Elohogombclick(Nil);
      exit;
    end;  

  DdatumPanel.Caption := _aktdatums;
  DdatumPanel.repaint;
end;

// =============================================================================
             function TForm2.HunDatetoStr(_d: Tdatetime): string;
// =============================================================================

var _dev,_dho,_dnap: word;

begin
  _dEv  := yearof(_d);
  _dHo  := monthof(_d);
  _dNap := dayof(_d);

  result := inttostr(_dev)+'.'+nulele(_dho)+'.'+nulele(_dnap);
end;

// =============================================================================
              function TForm2.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


// =============================================================================
           procedure TForm2.DATUMMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  NaptarPanel.Visible := false;
end;

// =============================================================================
             procedure TForm2.DATUMRENDBENGOMBClick(Sender: TObject);
// =============================================================================

begin
  _akthetnap := dayoftheweek(_aktdate);  // 6= szombat, 7= vasárnap
  _aktnapnev := _napnev[_akthetnap];
  _aktho_nap := midstr(_aktdatums,6,2)+midstr(_aktdatums,9,2);

  DatumPanel.caption := _aktdatums + ' '+_aktnapnev;
  DatumPanel.repaint;

  Naptarpanel.Visible := False;

  Tablaszinezo;
end;

// =============================================================================
             procedure TForm2.BitBtn2Click(Sender: TObject);
// =============================================================================

begin
  Naptar.CalendarDate := _aktdate;

  with NaptarPanel do
    begin
      top     := 24;
      left    := 168;
      Visible := True;
      repaint;
    end;

  DdatumPanel.Caption := _aktdatums;
  DdatumPanel.repaint;
end;

// =============================================================================
              procedure TForm2.NAPTARChange(Sender: TObject);
// =============================================================================

begin
  Ddisp;
end;

// =============================================================================
              procedure TForm2.ELOZONAPGOMBClick(Sender: TObject);
// =============================================================================

begin
  if Naptarpanel.Visible then exit;

  _aktdate   := _aktdate - 1;
  _aktdatums := Hundatetostr(_aktdate);
  _akthetnap := dayoftheweek(_aktdate);  // 6= szombat, 7= vasárnap
  _aktnapnev := _napnev[_akthetnap];
  _aktho_nap := midstr(_aktdatums,6,2)+midstr(_aktdatums,9,2);

  DatumPanel.Caption := _aktdatums+' '+_aktnapnev;
  DatumPanel.repaint;

  TablaSzinezo;

end;

// =============================================================================
          procedure TForm2.KOVETKEZONAPGOMBClick(Sender: TObject);
// =============================================================================

begin
  if Naptarpanel.Visible then exit;
  _aktdate   := _aktdate + 1;
  _aktdatums := Hundatetostr(_aktdate);
  _akthetnap := dayoftheweek(_aktdate);  // 6= szombat, 7= vasárnap
  _aktnapnev := _napnev[_akthetnap];
  _aktho_nap := midstr(_aktdatums,6,2)+midstr(_aktdatums,9,2);

  DatumPanel.Caption := _aktdatums+' '+_aktnapnev;
  DatumPanel.repaint;

  TablaSzinezo;

end;

// =============================================================================
               procedure TForm2.pn1Click(Sender: TObject);
// =============================================================================

var _ixs,_bcaps: string;
    _aktcol: TColor;

begin
  _ixs := TLabel(sender).Caption;
  val(_ixs,_index,_code);

  _aktcol := _sh[_index].brush.color;

  if _aktcol<>clred then exit;

  _bcaps := 'A ' + inttostr(_index)+'-S PÉNZTÁR ZÁRVA VOLT A FENTI NAPON';

  EgyPenztarGomb.Caption := _bcaps;
  Egypenztargomb.repaint;

  with ZarasJeloloPanel do
    begin
      top     := 132;
      left    := 128;
      Visible :=  true;
      repaint;
    end;
  Activecontrol := EgyPenztarGomb;
end;

// =============================================================================
          procedure TForm2.JELOLOVISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  ZarasJeloloPanel.Visible := False;
end;

// =============================================================================
          procedure TForm2.EGYPENZTARGOMBClick(Sender: TObject);
// =============================================================================

begin

   _aktmezo := Getaktmezo;
  _pcs := 'UPDATE DAYB' + _farok + ' SET ' + _aktmezo + '='+chr(39)+'X'+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE PENZTAR=' + inttostr(_index);

  if _index<151 then DbookParancs(_pcs) else acdbookParancs(_pcs);
  _aktshape := _sh[_index];
  _aktnum := _pn[_index];
  _aktshape.Brush.Color := clSilver;
  _aktnum.Font.Color := clBlack;

  ZarasJeloloPanel.Visible := False;
end;


procedure TForm2.DbookParancs(_ukaz: string);

begin
  Dbookdbase.connected := true;
  if dbooktranz.intransaction then dbooktranz.commit;
  dbooktranz.startTransaction;
  with DBookQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  Dbooktranz.commit;
  Dbookdbase.close;
end;

procedure TForm2.AcDbookParancs(_ukaz: string);

begin
  Acdbookdbase.close;
  AcDbookdbase.DatabaseName := '185.43.207.99:c:\cartcash\database\daybook.fdb';
  AcDbookdbase.connected := true;

  if Acdbooktranz.intransaction then Acdbooktranz.commit;
  Acdbooktranz.startTransaction;
  with AcDBookQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  AcDbooktranz.commit;
  AcDbookdbase.close;
end;




// =============================================================================
                      procedure TForm2.Tombetolto;
// =============================================================================

begin
  _sh[1]  := sh1;
  _sh[2]  := sh2;
  _sh[3]  := sh3;
  _sh[4]  := sh4;
  _sh[5]  := sh5;
  _sh[6]  := sh6;
  _sh[7]  := sh7;
  _sh[8]  := sh8;
  _sh[9]  := sh9;

  _sh[10] := sh10;
  _sh[11] := sh11;
  _sh[12] := sh12;
  _sh[13] := sh13;
  _sh[14] := sh14;
  _sh[15] := sh15;
  _sh[16] := sh16;
  _sh[17] := sh17;
  _sh[18] := sh18;
  _sh[19] := sh19;
  _sh[20] := sh20;

  _sh[21] := sh21;
  _sh[22] := sh22;
  _sh[23] := sh23;
  _sh[24] := sh24;
  _sh[25] := sh25;
  _sh[26] := sh26;
  _sh[27] := sh27;
  _sh[28] := sh28;
  _sh[29] := sh29;

  _sh[30] := sh30;
  _sh[31] := sh31;
  _sh[32] := sh32;
  _sh[33] := sh33;
  _sh[34] := sh34;
  _sh[35] := sh35;
  _sh[36] := sh36;
  _sh[37] := sh37;
  _sh[38] := sh38;
  _sh[39] := sh39;

  _sh[40] := sh40;
  _sh[41] := sh41;
  _sh[42] := sh42;
  _sh[43] := sh43;
  _sh[44] := sh44;
  _sh[45] := sh45;
  _sh[46] := sh46;
  _sh[47] := sh47;
  _sh[48] := sh48;
  _sh[49] := sh49;

  _sh[50] := sh50;
  _sh[51] := sh51;
  _sh[52] := sh52;
  _sh[53] := sh53;
  _sh[54] := sh54;
  _sh[55] := sh55;
  _sh[56] := sh56;
  _sh[57] := sh57;
  _sh[58] := sh58;
  _sh[59] := sh59;

  _sh[60] := sh60;
  _sh[61] := sh61;
  _sh[62] := sh62;
  _sh[63] := sh63;
  _sh[64] := sh64;
  _sh[65] := sh65;
  _sh[66] := sh66;
  _sh[67] := sh67;
  _sh[68] := sh68;
  _sh[69] := sh69;

  _sh[70] := sh70;
  _sh[71] := sh71;
  _sh[72] := sh72;
  _sh[73] := sh73;
  _sh[74] := sh74;
  _sh[75] := sh75;
  _sh[76] := sh76;
  _sh[77] := sh77;
  _sh[78] := sh78;
  _sh[79] := sh79;

  _sh[80] := sh80;
  _sh[81] := sh81;
  _sh[82] := sh82;
  _sh[83] := sh83;
  _sh[84] := sh84;
  _sh[85] := sh85;
  _sh[86] := sh86;
  _sh[87] := sh87;
  _sh[88] := sh88;
  _sh[89] := sh89;

  _sh[90] := sh90;
  _sh[91] := sh91;
  _sh[92] := sh92;
  _sh[93] := sh93;
  _sh[94] := sh94;
  _sh[95] := sh95;
  _sh[96] := sh96;
  _sh[97] := sh97;
  _sh[98] := sh98;
  _sh[99] := sh99;

  _sh[100] := sh100;
  _sh[101] := sh101;
  _sh[102] := sh102;
  _sh[103] := sh103;
  _sh[104] := sh104;
  _sh[105] := sh105;
  _sh[106] := sh106;
  _sh[107] := sh107;
  _sh[108] := sh108;
  _sh[109] := sh109;

  _sh[110] := sh110;
  _sh[111] := sh111;
  _sh[112] := sh112;
  _sh[113] := sh113;
  _sh[114] := sh114;
  _sh[115] := sh115;
  _sh[116] := sh116;
  _sh[117] := sh117;
  _sh[118] := sh118;
  _sh[119] := sh119;

  _sh[120] := sh120;
  _sh[121] := sh121;
  _sh[122] := sh122;
  _sh[123] := sh123;
  _sh[124] := sh124;
  _sh[125] := sh125;
  _sh[126] := sh126;
  _sh[127] := sh127;
  _sh[128] := sh128;
  _sh[129] := sh129;

  _sh[130] := sh130;
  _sh[131] := sh131;
  _sh[132] := sh132;
  _sh[133] := sh133;
  _sh[134] := sh134;
  _sh[135] := sh135;
  _sh[136] := sh136;
  _sh[137] := sh137;
  _sh[138] := sh138;
  _sh[139] := sh139;

  _sh[140] := sh140;
  _sh[141] := sh141;
  _sh[142] := sh142;
  _sh[143] := sh143;
  _sh[144] := sh144;
  _sh[145] := sh145;
  _sh[146] := sh146;
  _sh[147] := sh147;
  _sh[148] := sh148;
  _sh[149] := sh149;

  _sh[150] := sh150;
  _sh[151] := sh151;
  _sh[152] := sh152;
  _sh[153] := sh153;
  _sh[154] := sh154;
  _sh[155] := sh155;
  _sh[156] := sh156;
  _sh[157] := sh157;
  _sh[158] := sh158;
  _sh[159] := sh159;

  _sh[160] := sh160;
  _sh[161] := sh161;
  _sh[162] := sh162;
  _sh[163] := sh163;
  _sh[164] := sh164;
  _sh[165] := sh165;
  _sh[166] := sh166;
  _sh[167] := sh167;
  _sh[168] := sh168;
  _sh[169] := sh169;
  _sh[170] := sh170;

  _Pn[1]  := pn1;
  _pn[2]  := pn2;
  _pn[3]  := pn3;
  _pn[4]  := pn4;
  _pn[5]  := pn5;
  _pn[6]  := pn6;
  _pn[7]  := pn7;
  _pn[8]  := pn8;
  _pn[9]  := pn9;

  _pn[10] := pn10;
  _pn[11] := pn11;
  _pn[12] := pn12;
  _pn[13] := pn13;
  _pn[14] := pn14;
  _pn[15] := pn15;
  _pn[16] := pn16;
  _pn[17] := pn17;
  _pn[18] := pn18;
  _pn[19] := pn19;
  _pn[20] := pn20;

  _pn[21] := pn21;
  _pn[22] := pn22;
  _pn[23] := pn23;
  _pn[24] := pn24;
  _pn[25] := pn25;
  _pn[26] := pn26;
  _pn[27] := pn27;
  _pn[28] := pn28;
  _pn[29] := pn29;

  _pn[30] := pn30;
  _pn[31] := pn31;
  _pn[32] := pn32;
  _pn[33] := pn33;
  _pn[34] := pn34;
  _pn[35] := pn35;
  _pn[36] := pn36;
  _pn[37] := pn37;
  _pn[38] := pn38;
  _pn[39] := pn39;

  _pn[40] := pn40;
  _pn[41] := pn41;
  _pn[42] := pn42;
  _pn[43] := pn43;
  _pn[44] := pn44;
  _pn[45] := pn45;
  _pn[46] := pn46;
  _pn[47] := pn47;
  _pn[48] := pn48;
  _pn[49] := pn49;

  _pn[50] := pn50;
  _pn[51] := pn51;
  _pn[52] := pn52;
  _pn[53] := pn53;
  _pn[54] := pn54;
  _pn[55] := pn55;
  _pn[56] := pn56;
  _pn[57] := pn57;
  _pn[58] := pn58;
  _pn[59] := pn59;

  _pn[60] := pn60;
  _pn[61] := pn61;
  _pn[62] := pn62;
  _pn[63] := pn63;
  _pn[64] := pn64;
  _pn[65] := pn65;
  _pn[66] := pn66;
  _pn[67] := pn67;
  _pn[68] := pn68;
  _pn[69] := pn69;

  _pn[70] := pn70;
  _pn[71] := pn71;
  _pn[72] := pn72;
  _pn[73] := pn73;
  _pn[74] := pn74;
  _pn[75] := pn75;
  _pn[76] := pn76;
  _pn[77] := pn77;
  _pn[78] := pn78;
  _pn[79] := pn79;

  _pn[80] := pn80;
  _pn[81] := pn81;
  _pn[82] := pn82;
  _pn[83] := pn83;
  _pn[84] := pn84;
  _pn[85] := pn85;
  _pn[86] := pn86;
  _pn[87] := pn87;
  _pn[88] := pn88;
  _pn[89] := pn89;

  _pn[90] := pn90;
  _pn[91] := pn91;
  _pn[92] := pn92;
  _pn[93] := pn93;
  _pn[94] := pn94;
  _pn[95] := pn95;
  _pn[96] := pn96;
  _pn[97] := pn97;
  _pn[98] := pn98;
  _pn[99] := pn99;

  _pn[100] := pn100;
  _pn[101] := pn101;
  _pn[102] := pn102;
  _pn[103] := pn103;
  _pn[104] := pn104;
  _pn[105] := pn105;
  _pn[106] := pn106;
  _pn[107] := pn107;
  _pn[108] := pn108;
  _pn[109] := pn109;

  _pn[110] := pn110;
  _pn[111] := pn111;
  _pn[112] := pn112;
  _pn[113] := pn113;
  _pn[114] := pn114;
  _pn[115] := pn115;
  _pn[116] := pn116;
  _pn[117] := pn117;
  _pn[118] := pn118;
  _pn[119] := pn119;

  _pn[120] := pn120;
  _pn[121] := pn121;
  _pn[122] := pn122;
  _pn[123] := pn123;
  _pn[124] := pn124;
  _pn[125] := pn125;
  _pn[126] := pn126;
  _pn[127] := pn127;
  _pn[128] := pn128;
  _pn[129] := pn129;

  _pn[130] := pn130;
  _pn[131] := pn131;
  _pn[132] := pn132;
  _pn[133] := pn133;
  _pn[134] := pn134;
  _pn[135] := pn135;
  _pn[136] := pn136;
  _pn[137] := pn137;
  _pn[138] := pn138;
  _pn[139] := pn139;

  _pn[140] := pn140;
  _pn[141] := pn141;
  _pn[142] := pn142;
  _pn[143] := pn143;
  _pn[144] := pn144;
  _pn[145] := pn145;
  _pn[146] := pn146;
  _pn[147] := pn147;
  _pn[148] := pn148;
  _pn[149] := pn149;

  _pn[150] := pn150;
  _pn[151] := pn151;
  _pn[152] := pn152;
  _pn[153] := pn153;
  _pn[154] := pn154;
  _pn[155] := pn155;
  _pn[156] := Pn156;
  _pn[157] := Pn157;
  _pn[158] := Pn158;
  _pn[159] := Pn159;

  _pn[160] := pn160;
  _pn[161] := pn161;
  _pn[162] := pn162;
  _pn[163] := pn163;
  _pn[164] := pn164;
  _pn[165] := pn165;
  _pn[166] := pn166;
  _pn[167] := pn167;
  _pn[168] := pn168;
  _pn[169] := pn169;
  _pn[170] := pn170;
end;

procedure TForm2.ALLPENZTARGOMBClick(Sender: TObject);

var _sign: string;

begin
  _aktmezo := getaktmezo;

  Dbookdbase.Connected := True;
  if dBooktranz.InTransaction then dBookTranz.Commit;
  dBooktranz.StartTransaction;
  DbookTabla.Tablename := _aktdbook;
  DbookTabla.Open;
  while not DbookTabla.Eof do
    begin
      _sign := trim(Dbooktabla.FieldByNAme(_aktmezo).asString);
      if _sign='' then
        begin
          dBooktabla.edit;
          dbookTabla.FieldByName(_aktmezo).AsString := 'X';
          dBooktabla.Post;
        end;
      dbookTabla.next;
    end;
  dbooktranz.commit;
  dbookdbase.close;

  // -------------------------------------------

  AcDbookDbase.connected := true;
  if AcdBooktranz.InTransaction then AcdBookTranz.Commit;
  AcdBooktranz.StartTransaction;

  AcDbookTabla.TableName := _aktdbook;
  AcDbooktabla.Open;
  while not AcDbookTabla.Eof do
    begin
      _sign := trim(AcdbookTabla.FieldByNAme(_aktmezo).asString);
      if _sign='' then
        begin
          AcdBooktabla.edit;
          AcdbookTabla.FieldByName(_aktmezo).AsString := 'X';
          AcdBooktabla.Post;
        end;
      AcdbookTabla.next;
    end;
  Acdbooktranz.commit;
  Acdbookdbase.close;

  ZarasJeloloPanel.Visible := False;
  TablaSzinezo;
end;


procedure TForm2.CIKLUSTimer(Sender: TObject);
begin
  Ciklus.Enabled := False;
  Tablaszinezo;
  Ciklus.Enabled := True;
end;

end.
