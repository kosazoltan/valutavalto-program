unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, Grids, DBGrids, IBDatabase, IBCustomDataSet,
  IBQuery, Buttons, ExtCtrls, Calendar, jpeg, strutils, IBTable;

type
  TForm2 = class(TForm)

    CimEdit            : TEdit;
    KodEdit            : TEdit;
    NevEdit            : TEdit;
    PenzEdit           : TEdit;
    TelefonEdit        : TEdit;

    AdVetPanel         : TPanel;
    AFAPanel           : TPanel;
    BizonylatPanel     : TPanel;
    EgysegPanel        : TPanel;
    FocimPanel         : TPanel;
    KeszletPanel       : TPanel;
    MenuPanel          : TPanel;
    USDPanel           : TPanel;
    HUFPanel           : TPanel;
    NaptarNapPanel     : TPanel;
    NaptarPanel        : TPanel;
    Panel6             : TPanel;
    Panel8             : TPanel;
    PartnerPanel       : TPanel;
    PartnerNevPanel    : TPanel;
    TranzFocimPanel    : TPanel;
    TranzPanel         : TPanel;
    TranzTakaro        : TPanel;
    UjPenztarPanel     : TPanel;

    AFAAtvetGomb       : TBitBtn;
    AFAAtadGomb        : TBitBtn;
    BizBackGomb        : TBitBtn;
    BizonylatGomb      : TBitBtn;
    EloHoGomb          : TBitBtn;
    KovHoGomb          : TBitBtn;
    MasikDatumGomb     : TBitBtn;
    PartnerValasztoGomb: TBitBtn;
    PenztarOKEGomb     : TBitBtn;
    PenztarMegsemGomb  : TBitBtn;
    PTMegsemGomb       : TBitBtn;
    PTOkeGomb          : TBitBtn;
    RePrintGomb        : TBitBtn;
    StornoGomb         : TBitBtn;
    TranzMegsemGomb    : TBitBtn;
    TranzOKEGomb       : TBitBtn;
    UjPTGomb           : TBitBtn;
    VisszaGomb         : TBitBtn;
    WUAtvetGomb        : TBitBtn;
    WUAtadGomb         : TBitBtn;

    Label1             : TLabel;
    Label2             : TLabel;
    Label3             : TLabel;
    Label4             : TLabel;
    Label5             : TLabel;
    Label6             : TLabel;
    Label8             : TLabel;
    Label9             : TLabel;

    KeszletQuery       : TIBQuery;
    KeszletDbase       : TIBDatabase;
    KeszletTranz       : TIBTransaction;

    SzallitoQuery      : TIBQuery;
    SzallitoDbase      : TIBDatabase;
    SzallitoTranz      : TIBTransaction;

    ValdataQuery       : TIBQuery;
    ValdataDbase       : TIBDatabase;
    ValdataTranz       : TIBTransaction;

    ValutaTabla        : TIBTable;
    ValutaQuery        : TIBQuery;
    ValutaDbase        : TIBDatabase;
    ValutaTranz        : TIBTransaction;

    BizonylatRacs      : TDBGrid;
    PenztarRacs        : TDBGrid;

    BizonylatSource    : TDataSource;
    PenztarSource      : TDataSource;

    DnemCombo          : TComboBox;

    Naptar             : TCalendar;

    Image1             : TImage;
    Image2             : TImage;

    Shape1             : TShape;
    Shape2             : TShape;
    Shape3             : TShape;
    KESZPRINT: TBitBtn;

    procedure AFAAtvetGombClick(Sender: TObject);
    procedure AFAAtadGombClick(Sender: TObject);
    procedure AlapadatBeolvasas;
    procedure BankjegyBevitel;
    procedure BizBackGombClick(Sender: TObject);
    procedure BizonylatDisplay;
    procedure BizonylatGombClick(Sender: TObject);
    procedure BizonylatNyomtatas;
    procedure DnemComboChange(Sender: TObject);
    procedure ElohoGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure KeszletBeolvasas;
    procedure KeszletDisplay;
    procedure Kinyomtatas;
    procedure KodEditEnter(Sender: TObject);
    procedure KodEditExit(Sender: TObject);
    procedure KodEditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure KovhoGombClick(Sender: TObject);
    procedure Kozostranzakcio;
    procedure Mainapdisplay;
    procedure MasikDatumGombClick(Sender: TObject);
    procedure Menube;
    procedure NaptarChange(Sender: TObject);
    procedure NaptarDblClick(Sender: TObject);
    procedure PartnerValasztoGombClick(Sender: TObject);
    procedure PenzEditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure PenztarOkeGOMBClick(Sender: TObject);
    procedure PenztarRacsDblClick(Sender: TObject);
    procedure PenztarRacsKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure PenztartValasztott;
    procedure PlombaAdatBeolvasas;
    procedure PTOkeGombClick(Sender: TObject);
    procedure ReprintGombClick(Sender: TObject);
    procedure StornoGombClick(Sender: TObject);
    procedure TranzMegsemGombClick(Sender: TObject);
    procedure TranzOkeGombClick(Sender: TObject);
    procedure UjPTGombClick(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);
    procedure VisszaGombClick(Sender: TObject);
    procedure WuAtadGombClick(Sender: TObject);
    procedure WuAtvetGombClick(Sender: TObject);

    function FtForm(_num: integer;_bTip: string): string;
    function GetBizonylat: string;
    function Nul6(_n: integer):string;
    function Nulele(_b: byte):string;
    procedure KESZPRINTClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _storno: byte;
  _width,_height,_kertev,_kerthonap,_kertnap: word;

  _code,_bankjegy,_usdkeszlet,_hufkeszlet,_afakeszlet,_comboindex: integer;

  _pcs,_aktptkod,_aktptnev,_aktptcim,_aktpttel,_aktkod,_elojel,_aktdnem: string;
  _megnyitottnap,_tranztipus,_bizonylatszam,_homepenztarcim,_cegadoszam: string;
  _hometelefon,_szallitonev,_plombaszam,_megjegyzes,_kertnaps,_farok: string;
  _datum,_penztar,_tipus,_stbizonylat: string;

  _sorveg: string = chr(13)+chr(10);

  _tedit : array[1..4] of Tedit;

  _homepenztarkod: string = '180';
  _voltstorno,_regebbinap : boolean;

  _kertDatum: TDateTime;


function blokknyomtatas(_para: integer):integer; stdcall; external 'c:\ertektar\bin\bloknyom.dll' name 'blokknyomtatas';
function getplombarutin: integer; stdcall; external 'c:\ertektar\bin\getplomb.dll' name 'getplombarutin';
function regeneralorutin: integer; stdcall; external 'c:\ertektar\bin\regen.dll' name 'regeneralorutin';
function westernunionrutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
               function westernunionrutin: integer; stdcall;
// =============================================================================

begin
  form2 := tform2.create(Nil);
  result := Form2.showmodal;
  Form2.free;
end;


// =============================================================================
              procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _width  := Screen.Monitors[0].Width;
  _height := Screen.Monitors[0].Height;

  Top := trunc((_height-768)/2);
  Left := trunc((_width-1024)/2);

  Width  := 1024;
  Height := 768;

  _tedit[1] := Kodedit;
  _tedit[2] := Nevedit;
  _tedit[3] := Cimedit;
  _tedit[4] := Telefonedit;
  AlapadatBeolvasas;

  KeszletBeolvasas;
  KeszletDisplay;
  with KeszletPanel do
    begin
      Left := 16;
      top := 410;
      Visible := true;
      repaint;
    end;

  Menube;
end;


// =============================================================================
                             procedure TForm2.Menube;
// =============================================================================


begin
  Partnerpanel.visible    := False;
  TranzPanel.visible      := False;

  Bizonylatpanel.visible  := False;
  Bizonylatsource.enabled := False;
  Penztarsource.enabled   := False;
  UjpenztarPanel.visible  := False;
  NaptarPanel.Visible     := False;

  Valutaquery.close;
  ValdataQuery.close;
  ValutaDbase.close;
  Valdatadbase.close;

  with FocimPanel do
    begin
      Left := 8;
      Top := 8;
      Visible := true;
      Repaint;
    end;

  with Menupanel do
    begin
      Top := 56;
      Left := 8;
      Visible := True;
      repaint;
    end;
  Activecontrol := WuAtvetGomb;
end;

// =============================================================================
                procedure TForm2.VisszaGombClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
             procedure TForm2.WuAtvetGombClick(Sender: TObject);

begin
  _elojel := '+';
  _tranztipus := 'WU';
  KozosTranzakcio;
end;

// =============================================================================
           procedure TForm2.WuAtadGombClick(Sender: TObject);
// =============================================================================

begin
  _elojel := '-';
  _tranztipus := 'WU';
  KozosTranzakcio;
end;

// =============================================================================
             procedure TForm2.AFAAtvetGombClick(Sender: TObject);
// =============================================================================

begin
  _elojel := '+';
  _tranztipus := 'WA';
  KozosTranzakcio;
end;

// =============================================================================
             procedure TForm2.AFAAtadGombClick(Sender: TObject);
// =============================================================================

begin
  _elojel := '-';
  _tranztipus := 'WA';
  KozosTranzakcio;
end;

// =============================================================================
                  procedure TForm2.Kozostranzakcio;
// =============================================================================

var _tfcim,_partner: string;

begin

  if _tranztipus='WU' then _Tfcim := 'WESTERN UNION PÉNZEK '
  else _TFcim := 'AFAS PENZEK ';

  IF _elojel='+' then _tfcim := _tfcim + 'ÁTVÉTELE' else _tfcim := _tfcim + 'ÁTADÁSA';

  Tranzfocimpanel.caption := _tfcim;
  TranzfocimPanel.repaint;

  FocimPanel.visible := false;
  Menupanel.Visible := false;

  EgysegPanel.Caption := '';
  Penzedit.Clear;
  dnemCombo.ItemIndex := 0;
  TranzOkeGomb.Enabled := False;

  with TranzTakaro do
    begin
      top := 96;
      Left := 8;
      Visible := true;
    end;

  if _elojel='+' then _partner:='KÜLDÕ ' else _partner := 'FOGADÓ ';
  PartnernevPanel.Caption := _partner+'EGYSÉG MEGNEVEZÉSE';
  PartnerValasztoGomb.Caption := _partner+'EGYSEG KIVÁLASZTÁSA';

  PartnerValasztoGomb.visible := True;
  PartnerValasztoGomb.enabled := True;

  if _elojel='+' then AdvetPanel.caption := 'ÁTVETT PÉNZ ÖSSZEGE'
  else Advetpanel.Caption := 'ÁTADOTT PÉNZ ÖSSZEGE';
  AdvetPanel.repaint;

  with Tranzpanel do
    begin
      Top := 8;
      Left := 8;
      Visible := true;
      Repaint;
    end;

  ActiveControl := PartnerValasztoGomb;
end;

// =============================================================================
          procedure TForm2.PartnerValasztoGombClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'SELECT * FROM PENZTAR' + _sorveg;
  _pcs := _pcs + 'WHERE PENZTARKOD<>'+CHR(39)+_homePenztarkod+chr(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY PENZTARNEV';

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  Penztarsource.Enabled := True;

  Partnervalasztogomb.Enabled := False;
  with PartnerPanel do
    begin
      top := 72;
      Left := 8;
      Visible := True;
    end;
  PenztarRacs.SetFocus;
end;

// =============================================================================
           procedure TForm2.TranzMegsemGombClick(Sender: TObject);
// =============================================================================

begin
  menube;
end;

// =============================================================================
               procedure TForm2.UjPTGombClick(Sender: TObject);
// =============================================================================

begin
  Tranzpanel.Visible := false;
  PartnerPanel.Visible := false;
  Kodedit.clear;
  Nevedit.clear;
  Cimedit.clear;
  telefonedit.clear;

  with UjpenztarPanel do
    begin
      top :=8;
      left := 8;
      visible := true;
    end;
  Activecontrol := Kodedit;

end;

// =============================================================================
              procedure TForm2.KodEditEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clYellow;
end;

// =============================================================================
                     procedure TForm2.KodEditExit(Sender: TObject);
// =============================================================================

begin
  TEdit(sender).Color := clwhite;
end;

// =============================================================================
       procedure TForm2.KodEditKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================


var _tag: byte;
    _bill: byte;

begin
  _tag := TEdit(sender).Tag;
  _bill := ord(key);

  if (_bill=37) and (_tag>1) then
    begin
      Activecontrol := _tedit[_tag-1];
      exit;
    end;

  if _bill<>13 then exit;

  if _tag=4 then
    Activecontrol := Penztarokegomb else Activecontrol := _tedit[_tag+1];
end;


// =============================================================================
           procedure TForm2.PenztarOkeGombClick(Sender: TObject);
// =============================================================================


begin
  _aktptkod := trim(kodedit.text);
  if _aktptkod='' then
    begin
      Activecontrol := Kodedit;
      exit;
    end;

  Valutaquery.first;
  while not valutaquery.eof do
    begin
      _aktkod := trim(ValutaQuery.fieldByName('PENZTARKOD').AsString);
      if _aktkod=_aktptkod then
        begin
          Valutaquery.close;
          Valutadbase.close;
          Showmessage('EZ A PÉNZTÁRKÓD MÁR LÉTEZIK !');
          Activecontrol := Kodedit;
          exit;
        end;
      Valutaquery.next;
    end;
  ValutaQuery.close;
  Valutadbase.close;

  _aktptnev := trim(Nevedit.text);
  _aktptcim := trim(Cimedit.text);
  _aktpttel := trim(Telefonedit.text);

  if _aktptnev='' then
    begin
      Activecontrol := Nevedit;
      exit;
    end;

  if _aktptcim='' then
    begin
      Activecontrol := cimedit;
      exit;
    end;

  // ------------------------- itt rendben az ûj pénztár -------------------

  _pcs := 'INSERT INTO PENZTAR (PENZTARKOD,PENZTARNEV,PENZTARCIM,TELEFONSZAM)'+_SORVEG;
  _pcs := _pcs + 'VALUES (' + chr(39)+_aktptkod+chr(39)+',';
  _pcs := _pcs + chr(39)+_aktptnev+chr(39)+',';
  _pcs := _pcs + chr(39)+_aktptcim+chr(39)+',';
  _pcs := _pcs + chr(39)+_aktpttel+chr(39)+')';
  ValutaParancs(_pcs);

  UjpenztarPanel.visible := false;
  Partnervalasztogomb.Visible := false;

  TranzTakaro.Visible := false;
  with TranzPanel do
    begin
      top := 8;
      Left := 8;
      Visible := true;
      Repaint;
    end;
  Egysegpanel.caption := _aktptnev;
  Egysegpanel.repaint;
  DnemCombo.ItemIndex := 0;
  Activecontrol := Penzedit;
end;


// =============================================================================
              procedure TForm2.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  Valutadbase.connected := true;
  if valutatranz.InTransaction then Valutatranz.Commit;
  ValutaTranz.StartTransaction;
  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  Valutatranz.Commit;
  Valutadbase.close;
end;

// =============================================================================
                procedure TForm2.PTOkeGombClick(Sender: TObject);
// =============================================================================

begin
  PenztartValasztott;
end;

// =============================================================================
             procedure TForm2.PenztarRacsDblClick(Sender: TObject);
// =============================================================================

begin
  PenztartValasztott;
end;

// =============================================================================
      procedure TForm2.PenztarRacsKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  PenztartValasztott;
end;


// =============================================================================
                     procedure TForm2.PenztartValasztott;
// =============================================================================

begin
  _aktptkod := trim(ValutaQuery.FieldByName('PENZTARKOD').asstring);
  _aktptnev := trim(ValutaQuery.FieldByName('PENZTARNEV').asstring);

  Valutaquery.close;
  Valutadbase.close;

  _pcs := 'UPDATE VTEMP SET PENZTARKOD='+chr(39)+_aktptkod+chr(39);
  _pcs := _pcs + ',TARSPENZTARNEV=' + chr(39)+_aktptnev+chr(39);
  ValutaParancs(_pcs);

  PartnerValasztoGomb.visible := False;
  Tranztakaro.Visible := False;

  Bankjegybevitel;
  PartnerPanel.visible := false;
end;

// =============================================================================
                     procedure TForm2.Bankjegybevitel;
// =============================================================================

begin
  egysegpanel.caption := _aktptnev;
  with Tranzpanel do
    begin
      TOp := 8;
      Left := 8;
      Visible := true;
      Repaint;
    end;
  Activecontrol := Penzedit;
end;

// =============================================================================
         procedure TForm2.PenzEditKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

var _banks: string;

begin
  if ord(Key)<>13 then exit;

  _banks := trim(Penzedit.Text);
  val(_banks,_bankjegy,_code);
  if _code<>0 then _bankjegy := 0;
  if _bankjegy=0 then
    begin
      ActiveControl := Penzedit;
      exit;
    end;
  TranzokeGomb.Enabled := true;
  Activecontrol := TranzOkeGomb;
end;

// =============================================================================
             procedure TForm2.DnemComboChange(Sender: TObject);
// =============================================================================

begin
  tranzokegomb.Enabled := true;
  Activecontrol := Tranzokegomb;
end;



 {
  TranzfocimPanel.Caption := 'WESTERN UNION PÉNZEK ÁTUTALÁSA';
  TranzfocimPanel.repaint;


  FocimPanel.visible := false;
  Menupanel.Visible := false;

  EgysegPanel.Caption := '';
  Penzedit.Clear;
  dnemCombo.ItemIndex := 0;
  TranzOkeGomb.Enabled := False;

  with TranzTakaro do
    begin
      top := 96;
      Left := 8;
      Visible := true;
    end;

  _ELOJEL := '-';
  _tranztip := 'WU';

  PartneRnevPanel.caption := 'FOGADÓ EGYSÉG MEGNEVEZÉSE';
  PartnerValasztogomb.Caption := 'FOGADÓ EGYSÉG KIVÁLASZTÁSA';
  PartnerValasztoGomb.visible := True;
  PartnerValasztoGomb.enabled := True;

  AdvetPanel.caption := 'ÁTADOTT PÉNZ ÖSSZEGE';
  AdvetPanel.repaint;


  with Tranzpanel do
    begin
      TOp := 8;
      Left := 8;
      Visible := true;
      Repaint;
    end;

  ActiveControl := PartnerValasztoGomb;
end;

}

// =============================================================================
                      procedure TForm2.Keszletbeolvasas;
// =============================================================================

begin
  KeszletDbase.connected := True;
  with keszletquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM WUAFAADATOK');
      Open;
      _usdkeszlet := FieldByNAme('USDKESZLET').asInteger;
      _hufkeszlet := FieldByNAme('HUFKESZLET').asInteger;
      _afakeszlet := FieldByNAme('AFAKESZLET').asInteger;
      Close;
    end;
  Keszletdbase.close;
end;

// =============================================================================
                      procedure TForm2.Keszletdisplay;
// =============================================================================

begin
  usdPanel.Caption := FtForm(_usdkeszlet,'USD');
  hufPanel.Caption := FtForm(_hufkeszlet,'HUF');
  afaPanel.Caption := FtForm(_afakeszlet,'FT');
  Keszletpanel.repaint;
end;


// =============================================================================
            function TForm2.FtForm(_num: integer;_btip: string): string;
// =============================================================================

var _nums: string;
    _f1,_w1: byte;

begin
  result := '-';
  if _num=0 then exit;
  _nums := inttostr(_num);
  _w1 := length(_nums);
  if _w1<4 then
    begin
      result := _nums;
      exit;
    end;
  if _w1>6 then
    begin
      _f1 := _w1-6;
      result := leftstr(_nums,_f1)+' '+midstr(_nums,_f1+1,3)+' '+midstr(_nums,_f1+4,3);
      result := result + ' '+_btip;
      exit;
    end;
  _f1 := _w1-3;
  result := leftstr(_nums,_f1)+ ' '+midstr(_nums,_f1+1,3)+' '+_btip;
end;

// =============================================================================
                       procedure TForm2.AlapadatBeolvasas;
// =============================================================================

begin
  Keszletdbase.connected := true;
  with KeszletQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap := trim(FieldByNAme('MEGNYITOTTNAP').asString);
      _cegadoszam := trim(FieldByNAme('ADOSZAM').ASSTRING);
      Close;
    end;

  Keszletdbase.close;

  stornogomb.Enabled := true;
  naptar.CalendarDate := Date;
  Bizonylatdisplay;

end;

// =============================================================================
                   procedure TForm2.Bizonylatdisplay;
// =============================================================================

begin
  _kertev := Naptar.Year;
  _kerthonap := Naptar.Month;
  _kertnap := Naptar.Day;

  _kertnaps := inttostr(_kertev)+'.'+nulele(_kerthonap)+'.'+nulele(_kertnap);
  _farok := inttostr(_kertev-2000)+nulele(_kerthonap);

  if _kertnaps=_megnyitottnap then
    begin
      Mainapdisplay;
      exit;
    end;

  _regebbinap := true;
  stornogomb.Enabled := False;
  _pcs := 'SELECT * FROM WUNI'+_FAROK+_SORVEG;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_kertnaps+chr(39);

  Valdatadbase.Connected := true;
  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;
  BizonylatSource.Enabled := False;
  Bizonylatsource.dataset := valdataquery;
  Bizonylatsource.Enabled := true;
   with BizonylatPanel do
    begin
      top := 8;
      Left := 8;
      Visible := true;
    end;
  Bizonylatracs.setfocus;
end;

// =============================================================================
                    procedure TForm2.Mainapdisplay;
// =============================================================================

begin
  stornogomb.Enabled := True;
  _regebbinap := False;

  Valutadbase.Connected := true;
  if valutatranz.InTransaction then valutatranz.Commit;
  valutatranz.StartTransaction;
  with Valutatabla do
    begin
      Close;
      ValutaTabla.TableName := 'WUAFAFORG';
      Open;
    end;
  BizonylatSource.Enabled := False;
  Bizonylatsource.dataset := valutaTabla;
  Bizonylatsource.Enabled := true;

   with BizonylatPanel do
    begin
      top := 8;
      Left := 8;
      Visible := true;
    end;
  Bizonylatracs.setfocus;
end;

// =============================================================================
           procedure TForm2.TranzOkeGombClick(Sender: TObject);
// =============================================================================

var _plombaoke: byte;
    _banks: string;

begin
  _comboindex := dnemCombo.itemindex;
  _aktdnem := 'HUF';
  if _comboIndex=1 then _aktdnem := 'USD';

  _banks := trim(Penzedit.Text);
  val(_banks,_bankjegy,_code);
  if _code<>0 then _bankjegy := 0;
  if _bankjegy=0 then
    begin
      Activecontrol := Penzedit;
      exit;
    end;

  _plombaOke := getplombarutin;
  if _plombaOke=2 then exit;

  PlombaAdatBeolvasas;

  _bizonylatszam := GetBizonylat;

  _pcs := 'INSERT INTO WUAFAFORG (DATUM,VALUTANEM,BIZONYLAT,BANKJEGY,ELOJEL,';
  _pcs := _pcs + 'PENZTAR,BIZTIPUS,STORNO)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_bankjegy) + ',';
  _pcs := _pcs + chr(39) + _elojel + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktptkod + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tranztipus + chr(39) + ',1)';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO WPENZSZALLITAS (DATUM,BIZONYLATSZAM,SZALLITONEV,';
  _pcs := _pcs + 'PLOMBASZAM,MEGJEGYZES,WTIPUS)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39) +',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _szallitonev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _plombaszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _megjegyzes + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tranztipus + chr(39) + ')';
  ValutaParancs(_pcs);
  _datum := _megnyitottnap;
  Kinyomtatas;
end;

// =============================================================================
                    function TForm2.GetBizonylat: string;
// =============================================================================

var _ujbsz,_lastwube,_lastwuki,_lastafabe,_lastafaki: integer;
    _mezo: string;

begin
  Keszletdbase.connected := true;
  with keszletquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM WUAFAADATOK');
      Open;
      _lastwube  := FieldByNAme('LASTWUBE').asInteger;
      _lastwuki  := FieldByNAme('LASTWUKI').asInteger;
      _lastafabe := FieldByNAme('LASTAFABE').asInteger;
      _lastafaki := FieldByNAme('LASTAFAKI').asInteger;
      CLOSE;
    end;

  Keszletdbase.close;

  if _tranztipus = 'WU' then
    begin
      if _elojel='+' then
        begin
          _mezo := 'LASTWUBE';
          _ujbsz := 1 + _lastwube;
          result := 'WB-'+nul6(_ujbsz);
        end else
        begin
          _mezo := 'LASTWUKI';
          _ujbsz := 1 + _lastwuki;
          result := 'WK-'+nul6(_ujbsz);
        end;
    end else
    begin
      if _elojel='+' then
        begin
          _mezo := 'LASTAFABE';
          _ujbsz := 1 + _lastafabe;
          result := 'AB-'+nul6(_ujbsz);
        end else
        begin
          _mezo := 'LASTAFAKI';
          _ujbsz := 1 + _lastafaki;
          result := 'AK-'+nul6(_ujbsz);
        end;
    end;
  _pcs := 'UPDATE WUAFAADATOK SET ' + _MEZO+'='+inttostr(_ujbsz);
  ValutaParancs(_pcs);
end;

// =============================================================================
                    function TForm2.Nul6(_n: integer):string;
// =============================================================================

begin
  result := inttostr(_n);
  while length(result)<6 do result := '0' + RESULT;
end;

// =============================================================================
                  procedure TForm2.BizonylatNyomtatas;
// =============================================================================

begin
  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (TIPUS,DATUM,VALUTANEM,BANKJEGY,ELOJEL,TRANZTIPUS,';
  _pcs := _pcs + 'BIZONYLATSZAM,PENZTARKOD,SZALLITONEV,PLOMBASZAM,';
  _pcs := _pcs + 'MEGJEGYZES,STORNO)'+_sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + 'W' + chr(39) + ',';
  _pcs := _pcs + chr(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
  _pcs := _pcs + inttostr(_bankjegy) + ',';
  _pcs := _pcs + chr(39) + _elojel + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tranztipus + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktptkod + chr(39) + ',';
  _pcs := _pcs + chr(39) + _szallitonev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _plombaszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _megjegyzes + chr(39) + ',';
  _pcs := _pcs + inttostr(_storno) + ')';
  ValutaParancs(_pcs);
  blokknyomtatas(1);
end;

// =============================================================================
                   procedure TForm2.PlombaAdatBeolvasas;
// =============================================================================

begin
  ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _szallitonev := trim(FieldbyNAme('SZALLITONEV').asString);
      _plombaszam := trim(FieldByNAme('PLOMBASZAM').asString);
      _megjegyzes := trim(FieldbyNAme('MEGJEGYZES').asString);
      Close;
    end;
  ValutaDbase.close;
end;

// =============================================================================
           procedure TForm2.BizonylatGombClick(Sender: TObject);
// =============================================================================

begin
  _voltstorno := False;
  _regebbinap := True;
  Bizonylatdisplay;
end;

// =============================================================================
                    function TForm2.Nulele(_b: byte):string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
         procedure TForm2.MasikDatumGombClick(Sender: TObject);
// =============================================================================

begin
  if not _regebbinap then
    begin
      ValutaTranz.commit;
      Valutatabla.close;
      Valutadbase.close;
      _regebbinap := True;
    end;

  with NaptarPanel do
    begin
      top  := 424;
      left := 576;
      Visible := True;
    end;
end;

// =============================================================================
             procedure TForm2.BizBackGombClick(Sender: TObject);
// =============================================================================

begin
  if not _regebbinap then
    begin
      ValutaTranz.commit;
      Valutatabla.close;
      Valutadbase.close;
      _regebbinap := True;
    end else
    begin
      ValdataQuery.Close;
      Valdatadbase.close;
    end;

  if _voltstorno then
    begin
      regeneralorutin;
      Keszletdisplay;
      _voltstorno := False;
    end;

  Naptarpanel.Visible := False;
  BizonylatPanel.Visible := False;
end;

// =============================================================================
              procedure TForm2.NaptarChange(Sender: TObject);
// =============================================================================

begin
  _kertev := Naptar.Year;
  _kerthonap := Naptar.Month;
  _kertnap := Naptar.day;
  _kertnaps := inttostr(_kertev)+'.'+nulele(_kerthonap)+'.'+nulele(_kertnap);
  NaptarnapPanel.Caption := _kertnaps;
  NaptarNapPanel.repaint;
end;

// =============================================================================
             procedure TForm2.ElohoGombClick(Sender: TObject);
// =============================================================================

begin
  Naptar.PrevMonth;
end;

// =============================================================================
            procedure TForm2.KovhoGombClick(Sender: TObject);
// =============================================================================

begin
  Naptar.NextMonth;
end;

// =============================================================================
               procedure TForm2.NaptarDblClick(Sender: TObject);
// =============================================================================

begin
  NaptarPanel.visible := False;
  Bizonylatdisplay;
end;

// =============================================================================
             procedure TForm2.StornoGombClick(Sender: TObject);
// =============================================================================

begin
  _STORNO := Valutatabla.FieldByNAme('STORNO').asInteger;
  if _storno>1 then
    begin
      showmessage('EZ A TÉTEL MÁR ÉRVÉNYTELEN');
      exit;
    end;

  _voltstorno := True;
  with ValutaTabla do
    begin
      _datum := fieldByName('DATUM').asstring;
      _stbizonylat := FieldByNAme('BIZONYLAT').asString;
      _aktdnem := FieldByNAme('VALUTANEM').asString;
      _bankjegy := FieldByNAme('BANKJEGY').asInteger;
      _elojel := FieldByNAme('ELOJEL').asstring;
      _penztar := FieldByNAme('PENZTAR').asString;
      _tranztipus := FieldByNAme('BIZTIPUS').asString;
    end;
  ValutaTabla.edit;
  valutatabla.FieldByName('STORNO').asInteger := 2;
  Valutatabla.post;

  ValutaTranz.commit;
  Valutadbase.close;

  // -----------------------------------------------------

  _pcs := 'SELECT * FROM PENZTAR WHERE PENZTARKOD='+chr(39)+_penztar+chr(39);
  Valutadbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _aktptnev := trim(FieldByNAme('PENZTARNEV').AsString);
      Close;
    end;
  Valutadbase.close;


  // -----------------------------------------------------

  _bizonylatszam := GetBizonylat;

  if _elojel='+' then _elojel := '-' else _elojel := '+';

  // -----------------------------------------------------

  _pcs := 'INSERT INTO WUAFAFORG (DATUM,BIZONYLAT,VALUTANEM,BANKJEGY,ELOJEL,';
  _pcs := _pcs + 'PENZTAR,BIZTIPUS,STORNO)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _datum + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
  _pcs := _pcs + inttostr(_bankjegy) + ',';
  _pcs := _pcs + chr(39) + _elojel + chr(39) + ',';
  _pcs := _pcs + chr(39) + _penztar + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tranztipus + chr(39) + ',';
  _pcs := _pcs + '3)' + _sorveg;
  ValutaParancs(_pcs);

  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (STORNO)' +_sorveg;
  _pcs := _pcs + 'VALUES (3)';
  ValutaParancs(_pcs);

  _pcs := 'UPDATE VTEMP SET BIZONYLATSZAM='+chr(39)+_bizonylatszam+chr(39);
  _pcs := _pcs + ',DATUM='  + CHR(39) + _datum + chr(39) + ',TIPUS=';
  _pcs := _pcs + chr(39)+'W'+chr(39)+',TRANZTIPUS=' + CHR(39)+_tranztipus+chr(39);
  _pcs := _pcs + ',VALUTANEM='+chr(39)+_aktdnem+chr(39)+',BANKJEGY='+inttostr(_bankjegy);
  _pcs := _pcs + ',ELOJEL=' + chr(39) + _elojel + chr(39);
  _pcs := _pcs + ',STORNOBIZONYLAT='+chr(39)+_stBizonylat+chr(39);
  _pcs := _pcs + ',TARSPENZTARNEV='+chr(39)+_aktptnev+chr(39);
  _pcs := _pcs + ',PENZTARKOD='+chr(39)+_penztar+chr(39);
  ValutaParancs(_pcs);
  blokknyomtatas(1);

  regeneralorutin;
  Keszletdisplay;
  _voltstorno := False;

  Naptarpanel.Visible := False;
  BizonylatPanel.Visible := False;


end;

// =============================================================================
           procedure TForm2.RePrintGombClick(Sender: TObject);
// =============================================================================

begin
  if _regebbinap then
    begin
      with ValdataQuery do
        begin
          _datum := FieldByNAme('DATUM').asString;
          _aktdnem := FieldByName('VALUTANEM').asString;
          _bizonylatszam := trim(FieldByNAme('BIZONYLAT').asstring);
          _bankjegy := FieldByNAme('BANKJEGY').asInteger;
          _elojel := Fieldbyname('ELOJEL').asString;
          _aktptkod := trim(FieldByNAme('PENZTAR').asstring);
          _tranztipus := trim(FieldByNAme('BIZTIPUS').asstring);
          _storno := FieldByNAme('STORNO').asInteger;
        end;
    end else
    begin
      with Valutatabla do
        begin
          _datum := FieldByNAme('DATUM').asString;
          _aktdnem := FieldByName('VALUTANEM').asString;
          _bizonylatszam := trim(FieldByNAme('BIZONYLAT').asstring);
          _bankjegy := FieldByNAme('BANKJEGY').asInteger;
          _elojel := Fieldbyname('ELOJEL').asString;
          _aktptkod := FieldByNAme('PENZTAR').asstring;
          _tranztipus := trim(FieldByNAme('BIZTIPUS').asstring);
          _storno := FieldByNAme('STORNO').asInteger;
        end;
    end;

  _tipus := 'W';
  _pcs := 'SELECT * FROM WPENZSZALLITAS WHERE BIZONYLATSZAM='+chr(39)+_bizonylatszam+chr(39);

  Szallitodbase.connected := true;
  with Szallitoquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _szallitonev := trim(FieldByNAme('SZALLITONEV').asstring);
      _plombaszam := trim(FieldByNAme('PLOMBASZAM').asString);
      _megjegyzes := trim(FieldByNAme('MEGJEGYZES').asstring);
      Close;
    end;
  _pcs := 'SELECT * FROM PENZTAR WHERE PENZTARKOD='+chr(39)+_aktptkod+chr(39);
   with Szallitoquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _aktptnev := trim(FieldByNAme('PENZTARNEV').asstring);
      close;
    end;
  Szallitodbase.close;
  Kinyomtatas;

end;

// =============================================================================
                       procedure TForm2.Kinyomtatas;
// =============================================================================

begin

  _PCS := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (DATUM,VALUTANEM,BIZONYLATSZAM,BANKJEGY,ELOJEL,';
  _pcs := _pcs + 'SZALLITONEV,PLOMBASZAM,MEGJEGYZES,';
  _pcs := _pcs + 'PENZTARKOD,TRANZTIPUS,STORNO,TIPUS,TARSPENZTARNEV)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _datum + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_bankjegy) + ',';
  _pcs := _pcs + chr(39) + _elojel + chr(39) + ',';

  _pcs := _pcs + chr(39) + _szallitonev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _plombaszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _megjegyzes + chr(39) + ',';

  _pcs := _pcs + chr(39) + _aktptkod + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tranztipus + chr(39) + ',';
  _pcs := _pcs + '1,';
  _pcs := _pcs + chr(39) + 'W' + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktptnev + chr(39) + ')';
  ValutaParancs(_pcs);

  blokknyomtatas(1);
  regeneralorutin;
  KeszletBeolvasas;
  KeszletDisplay;

  Menube;

end;

procedure TForm2.KESZPRINTClick(Sender: TObject);
begin
  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (TIPUS)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39)+'Q'+CHR(39) + ')';
  ValutaParancs(_pcs);

  blokknyomtatas(1);


end;

end.

