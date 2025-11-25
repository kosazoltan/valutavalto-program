unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, IBDatabase, DB, IBCustomDataSet,
  IBQuery, strutils, dateUtils, IBTable, jpeg;

type
  TENGEDELYADAS = class(TForm)
    Panel1: TPanel;
    DATUMCOMBO: TComboBox;
    PENZTARCOMBO: TComboBox;
    Panel2: TPanel;
    remoteQuery: TIBQuery;
    remoteDbase: TIBDatabase;
    remoteTranz: TIBTransaction;
    VALQUERY: TIBQuery;
    VALDBASE: TIBDatabase;
    VALTRANZ: TIBTransaction;
    REMOTETABLA: TIBTable;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    ARFOLYAMENGEDOGOMB: TBitBtn;
    KEZDIJENGEDOGOMB: TBitBtn;
    ARFOLYAMKEDVEZMENYPANEL: TPanel;
    Shape2: TShape;
    Label16: TLabel;
    Label17: TLabel;
    DNEMCOMBO: TComboBox;
    Label18: TLabel;
    BANKJEGYEDIT: TEdit;
    Label19: TLabel;
    ARFOLYAMEDIT: TEdit;
    Label20: TLabel;
    ADOCOMBO: TComboBox;
    Label21: TLabel;
    ARFOLYAMKONYVELOGOMB: TBitBtn;
    FOLYTATASPANEL: TPanel;
    TOVABBIGOMB: TBitBtn;
    MASIKPENZTARGOMB: TBitBtn;
    Shape3: TShape;
    KILEPGOMB: TBitBtn;
    Shape4: TShape;
    Label22: TLabel;
    Shape5: TShape;
    Shape6: TShape;
    Shape7: TShape;
    PENZTARRENDBENGOMB: TBitBtn;
    EXITGOMB: TBitBtn;
    FIXINFOPANEL: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    FIXPENZTAREDIT: TEdit;
    FIXDATUMPANEL: TPanel;
    Shape8: TShape;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    KEZDIJENGEDELYPANEL: TPanel;
    Label9: TLabel;
    Label13: TLabel;
    kezdijtipcombo: TComboBox;
    KEZDIJEDIT: TEdit;
    Label14: TLabel;
    Label15: TLabel;
    KEZDIJKONYVELOGOMB: TBitBtn;
    Shape1: TShape;
    GOMBTAKAROPANEL: TPanel;
    ESCAPEGOMB: TBitBtn;
    Shape10: TShape;
    FUGGONY: TPanel;
    Label24: TLabel;
    KBIZONYLATEDIT: TEdit;
    Image1: TImage;
    BIZONYLATEDIT: TEdit;


    procedure FormActivate(Sender: TObject);
    procedure PENZTARCOMBOChange(Sender: TObject);

    procedure ComboFeltoltes;
    function FtForm(_ft: integer): string;
    procedure MakeHaviTabla(_tnev: string);
    function GetTranzIndex(_bs: string): byte;

    function Nulele(_b: byte): string;
    function Konvertdatum(_datum: TDatetime): string;
    procedure EXITGOMBClick(Sender: TObject);
    procedure PENZTARRENDBENGOMBClick(Sender: TObject);
    procedure ARFOLYAMENGEDOGOMBClick(Sender: TObject);
    procedure ESCAPEGOMBClick(Sender: TObject);
    procedure TRANZCOMBOChange(Sender: TObject);
    procedure BANKJEGYEDITEnter(Sender: TObject);
    procedure BANKJEGYEDITExit(Sender: TObject);
    procedure BANKJEGYEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ARFOLYAMKONYVELOGOMBClick(Sender: TObject);

    procedure ArfolyamKonyveles;
    procedure KezdijKonyveles;
    function Getido: string;
    procedure AlapadatBeolvasas;

    procedure MASIKPENZTARGOMBClick(Sender: TObject);
    procedure KEZDIJENGEDOGOMBClick(Sender: TObject);
    procedure kezdijtipcomboChange(Sender: TObject);
    procedure KEZDIJEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure KEZDIJKONYVELOGOMBClick(Sender: TObject);
    procedure TOVABBIGOMBClick(Sender: TObject);
    procedure RemoteParancs(_ukaz: string);
    procedure KBIZONYLATEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure BIZONYLATEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
   
    
   

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ENGEDELYADAS: TENGEDELYADAS;

 // _permfdb: string = 'ENGTEST.FDB';
   _permfdb: string = 'ENGEDELY.FDB';
  _ptszam: array[0..40] of byte;
  _ptnev : array[0..40] of string;

  _eddig: string;


  _dnem,_dnev: array[0..25] of string;

  _aktdatum,_kertdatum: TDatetime;
  _host: string;
  _sorveg: string = chr(13) + chr(10);

  _tranztomb: array[1..3] of string = ('V','E','K');
  _adotomb: array[0..4] of string = ('V','E','F','U','J');
  _lotomb: array[0..4] of byte = (8,16,32,64,128);
  _hitomb: array[0..3] of word = (256,512,1024,2048);
  _kezdtomb: array[0..3] of string = ('F','K','U','C');
  _kdengtomb: array[0..3] of string = ('E','E','U','E');

  _ptitem,_aktdatums,_engtipus,_remoteFdb,_pcs,_items,_aktptnev,_aktdnem: string;
  _pts,_tranztip,_engado,_bjs,_arfs,_alkds,_engs,_kengtipus: string;
  _fdbPath,_farok,_tablanev,_kezdtipus,_konvdatums,_aktido: string;

  _ptindex,_datindex,_tipindex,_valutaindex,_aktbankjegy: integer;
  _penztarindex,_datumindex,_tranzindex,_dnemindex,_adoindex: integer;
  _aktarfolyam,_kezdtipIndex,_aktkezdij: integer;
  _kertPenztarNum: byte;
  _kertPenztarNev,_kertdatums,_remoteFdbPath,_bizonylatszam: string;
  _aktpenztarszam,_ptdarab,_aktptnum,_aktora,_dnemdb,_edlen,_jutment: byte;
  _aktertektar,_gepfunkcio: byte;
  _aktev,_aktho,_aktnap,_cc,_permittype: word;
  _ertektar,_penztar: byte;

  _left,_width,_height,_top: word;

  _dnemtomb: array[0..25] of string = ('AUD','BAM','BGN','BRL','CAD','CHF',
              'CNY','CZK','DKK','EUR','GBP','HRK','ILS','JPY','MXN','NOK',
              'NZD','PLN','RON','RSD','RUB','SEK','THB','TRY','UAH','USD');


  _code,_bankjegy,_arfolyam,_alapkezdij,_engkezdij: integer;

   _napnev: array[1..7] of string = ('hétfõ','kedd','szerda','csütörtök',
                                        'péntek','szombat','vasárnap');

   _honev: array[1..12] of string = ('január','február','március','április',
             'május','június','július','augusztus','szeptember','október',
                                         'november','december');

function ratepermitrutin: integer; stdcall;

implementation

{$R *.dfm}

function ratepermitrutin: integer; stdcall;
begin
  engedelyadas := TEngedelyadas.Create(Nil);
  result := engedelyadas.showmodal;
  engedelyadas.free;
end;




// =============================================================================
               procedure TENGEDELYADAS.FormActivate(Sender: TObject);
// =============================================================================

begin
   _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  _top := trunc((_height-720)/2);
  _left:= trunc((_width-1000)/2);

  Top := _top;
  Left := _left;

  AlapadatBeolvasas;


  _remoteFdbPath := _host + ':C:\RECEPTOR\DATABASE\' + _permFdb;

  with Fuggony do
    begin
      Top := 50;
      Left := 40;
      Visible := True;
      repaint;
    end;

  with GombTakaroPanel do
    begin
      Top := 310;
      Left := 40;
      Visible := true;
    end;

  FixInfoPanel.Visible := false;
  KezdijEngedelyPanel.Visible := False;
  FolytatasPanel.Visible := False;
  ArfolyamKedvezmenyPanel.Visible := False;

  ComboFeltoltes;
  Fuggony.Visible := false;

  ActiveControl := PenztarRendbenGomb;
end;



// =============================================================================
                         procedure TENGEDELYADAS.COmbofeltoltes;
// =============================================================================

var _pt: integer;
    _ptn: string;
    _y: byte;

begin

  _remoteFdb := _host + ':C:\receptor\database\receptor.fdb';
  Remotedbase.close;
  RemoteDbase.DatabaseName := _remoteFdb;
  Remotedbase.Connected := True;

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE (ERTEKTAR='+inttostr(_aktertektar)+') AND ';
  _pcs := _pcs + '(CLOSED=' + chr(39) + 'N' + chr(39) + ') AND ';
  _pcs := _pcs + '(STATUS=' + chr(39) + 'P' + CHR(39) + ')' + _sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  with RemoteQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  _cc := 0;
  while not RemoteQuery.eof do
    begin
      _pt := Remotequery.FieldByName('UZLET').asInteger;
      _ptn := trim(RemoteQuery.FieldbyName('KESZLETNEV').asString);

      _ptszam[_cc]:= _pt;
      _ptnev[_cc] := _ptn;

      RemoteQuery.next;
      inc(_cc);
    end;
  RemoteQuery.close;
  RemoteDbase.close;
  _ptDarab := _cc;

  penztarcombo.Items.clear;
  _y := 0;
  while _y<_ptDarab do
    begin
      _aktptnum := _ptszam[_y];
      _items := inttostr(_aktptnum);
      _aktptnev := _ptnev[_y];

      while length(_items)<3 do _items := '0' + _items;

      _aktptnev := _ptnev[_y];
      penztarcombo.Items.add(_items+' '+_aktptnev);
      inc(_y);
    end;

  penztarCombo.ItemIndex := 0;

  // ---------------------------------------------------------

  _aktora := hourof(time);

  Datumcombo.Items.clear;

  _aktdatum := Date;
  _items := konvertDatum(_aktdatum);
  Datumcombo.Items.Add(_items);

  if _aktora<10 then
    begin
      _y := 3;
      while _y>0 do
        begin
          _aktdatum := _aktdatum - 1;
          _items := konvertDatum(_aktdatum);
          Datumcombo.Items.Add(_items);
          dec(_y);
        end;
    end;

  Datumcombo.ItemIndex := 0;

end;


// =============================================================================
           function TENGEDELYADAS.Konvertdatum(_datum: TDatetime): string;
// =============================================================================

var _yev,_yho,_ynap,_yhnap: word;

begin
  _yev  := yearof(_datum);
  _yho  := monthof(_datum);
  _ynap := dayof(_datum);
  _yhnap:= dayoftheweek(_datum);
  _konvdatums := inttostr(_yev)+'.'+nulele(_yho)+'.'+nulele(_ynap);

  result := inttostr(_yev)+' '+_honev[_yho]+' '+inttostr(_ynap)+' '+_napnev[_yhnap];
end;






// =============================================================================
           procedure TENGEDELYADAS.PENZTARCOMBOChange(Sender: TObject);
// =============================================================================

begin
  Activecontrol := PenztarRendbenGomb;
end;


{
// =============================================================================
                procedure TForm1.STGOMBClick(Sender: TObject);
// =============================================================================

begin

  _ptindex := PenztarCOmbo.itemindex;
  _ptItem := Penztarcombo.Items[_ptIndex];

  _pts := leftstr(_ptItem,3);
  val(_pts,_aktpenztarszam,_code);

  _datIndex := DatumCombo.itemindex;
  _aktdatum := Date-_datindex;
  _aktev    := yearof(_aktdatum);
  _aktho    := monthof(_aktdatum);
  _aktnap   := dayof(_aktdatum);
  _aktdatums:= inttostr(_aktev)+'.'+nulele(_aktho)+'.'+nulele(_aktnap);

  _tipIndex := tipuscombo.itemindex;
  MunkaPanelChange(_tipindex);

  Fuggony.Visible := false;
end;

}

// =============================================================================
                 function TENGEDELYADAS.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

  // =============================================================================
                function TENGEDELYADAS.FtForm(_ft: integer): string;
// =============================================================================

var _fts: string;
    _wts,_f1: byte;

begin
  result := '';
  if _ft=0 then exit;

  _fts := inttostr(_ft);
  _wts := length(_fts);

  if _wts<4 then
    begin
      result := _fts;
      exit;
    end;

  if _wts>6 then
    begin
      _f1 := _wts-6;
      result := leftstr(_fts,_f1)+' '+midstr(_fts,_f1+1,3)+' '+midstr(_fts,_f1+4,3);
      exit;
    end;
  _f1 := _wts-3;
  result := leftstr(_fts,_f1)+' '+midstr(_fts,_f1+1,3);
end;


procedure TENGEDELYADAS.EXITGOMBClick(Sender: TObject);
begin
  Modalresult := 1;
end;

procedure TENGEDELYADAS.PENZTARRENDBENGOMBClick(Sender: TObject);
begin

  _penztarIndex  := PenztarCombo.itemindex;
  _kertPenztarNum := _ptszam[_penztarIndex];
  _kertPenztarNev := _ptNev[_penztarIndex];
  FixPenztarEdit.Text := inttostr(_kertpenztarNum)+' '+_kertpenztarnev;

  _datumIndex := DAtumCombo.itemindex;
  _kertdatum := Date - _datumindex;

  Konvertdatum(_kertdatum);
  FixDatumPanel.Caption := _konvdatums;

  with FixInfoPanel do
    begin
      Top  := 88;
      Left := 48;
      Visible := true;
      repaint;
    end;

  GombTakaropanel.Visible := false;
  ActiveControl := ArfolyamEngedoGomb;
end;

procedure TENGEDELYADAS.ARFOLYAMENGEDOGOMBClick(Sender: TObject);
begin
  Bizonylatedit.Clear;
  DnemCombo.ItemIndex := 0;
  Bankjegyedit.clear;
  ArfolyamEdit.clear;
  AdocOMBO.ItemIndex := 1;

  with ArfolyamKedvezmenyPanel do
    begin
      Left := 88;
      Top := 320;
      Visible := true;
    end;
  ActiveControl := Bizonylatedit;
end;

procedure TENGEDELYADAS.ESCAPEGOMBClick(Sender: TObject);
begin
  ModalResult := 2;
end;

procedure TENGEDELYADAS.TRANZCOMBOChange(Sender: TObject);
begin
  _bizonylatszam := trim(BizonylatEdit.Text);
  if length(_bizonylatszam)<>10 then
    begin
      Activecontrol := Bizonylatedit;
      exit;
    end;

  if trim(Bankjegyedit.Text)='' then
    begin
      Activecontrol := Bankjegyedit;
      exit;
    end;

  if trim(Arfolyamedit.Text)='' then
    begin
      Activecontrol := Arfolyamedit;
      exit;
    end;

  ActiveControl := ArfolyamKonyveloGomb;
end;

procedure TENGEDELYADAS.BANKJEGYEDITEnter(Sender: TObject);
begin
  Tedit(sender).color := clYellow;
end;

procedure TENGEDELYADAS.BANKJEGYEDITExit(Sender: TObject);
begin
  Tedit(sender).Color := clWhite;
end;

procedure TENGEDELYADAS.BANKJEGYEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  TranzcomboChange(Nil);
end;

procedure TENGEDELYADAS.ARFOLYAMKONYVELOGOMBClick(Sender: TObject);
begin
  _aktido := GetIdo;

  _bizonylatszam := trim(Bizonylatedit.Text);
  _dnemindex  := Dnemcombo.itemindex;
  _adoIndex   := adoCombo.Itemindex;

  _bizonylatszam := trim(BizonylatEdit.Text);
  if length(_bizonylatszam)<>10 then
    begin
      ActiveControl := Bizonylatedit;
      exit;
    end;

  _tranzindex := GetTranzindex(_bizonylatszam);
  if _tranzindex=0 then
    begin
      Bizonylatedit.clear;
      Activecontrol := Bizonylatedit;
      exit;
    end;


  _bjs := trim(Bankjegyedit.Text);
  if _bjs='' then
    begin
      Activecontrol := BankjegyEdit;
      exit;
    end;

  Val(_bjs,_aktbankjegy,_code);

  if _Code<>0 then
    begin
      Bankjegyedit.clear;
      Activecontrol := Bankjegyedit;
      exit;
    end;

  _arfs := trim(Arfolyamedit.Text);
  if _arfs='' then
    begin
      Activecontrol := Arfolyamedit;
      exit;
    end;

  Val(_arfs,_aktarfolyam,_code);

  if _code<>0 then
    begin
      Arfolyamedit.clear;
      Activecontrol := Arfolyamedit;
      exit;
    end;

  ArfolyamKonyveles;
  with FolytatasPanel do
    begin
      Top := 340;
      Left:= 120;
      Visible := true;
    end;

  Activecontrol := TovabbiGomb;
end;

procedure TEngedelyAdas.ArfolyamKonyveles;

begin
  _aktdatums := _konvdatums;
  _farok := midstr(_aktdatums,3,2)+midstr(_aktdatums,6,2);
  _tablanev := 'ENG' + _farok;

  MakeHaviTabla(_tablanev);

  _pcs := 'INSERT INTO ' + _tablanev + ' (ERTEKTAR,PENZTAR,DATUM,IDO,';
  _pcs := _pcs + 'ENGEDELYTARGYA,BIZONYLATSZAM,VALUTANEM,';
  _pcs := _pcs + 'OSSZEG,TRANZAKCIO,KEDVARFOLYAM,ENGEDELYEZO,KEZDIJENGEDELYTIPUS,';
  _pcs := _pcs + 'KEDVKEZDIJ,KEDVEZMENYKOD,CONTROL)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_aktertektar) + ',';
  _pcs := _pcs + inttostr(_kertpenztarNum) + ',';                  // penztar
  _pcs := _pcs + chr(39) + _aktdatums + chr(39) + ',';             // dátum
  _pcs := _pcs + chr(39) + _aktido + chr(39) + ',';                // idö str
  _pcs := _pcs + chr(39) + 'A' + chr(39) + ',';                    // engedely targya
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _dnemtomb[_dnemindex] + chr(39) + ',';  // valuta
  _pcs := _pcs + inttostr(_aktbankjegy) + ',';                     // összeg
  _pcs := _pcs + chr(39) + _tranztomb[_tranzindex] + chr(39) + ','; // tranzakcio V E K
  _pcs := _pcs + inttostr(_aktarfolyam) + ',';                     // kedvményes árfolyam
  _pcs := _pcs + chr(39) + _adotomb[_adoindex] + chr(39) + ',';    // engedelyezo V E F U J
  _pcs := _pcs + chr(39) + ' ' + chr(39) + ',';                    // kezdij engtipus F E C
  _pcs := _pcs + '0,';                                             // kedvményes kezdij
  _pcs := _pcs + inttostr(_lotomb[_adoIndex]) + ',';               // kedvezmény kód 8,16,32,64,128
  _pcs := _pcs + '0)';                                          // control = const = 0

  Remoteparancs(_pcs);
end;

procedure TENGEDELYADAS.MASIKPENZTARGOMBClick(Sender: TObject);
begin
  FolytatasPanel.Visible := false;
  ArfolyamKedvezmenyPanel.visible := false;
  KezdijEngedelyPanel.Visible := False;
  GombTakaropanel.visible := True;
  FixinfoPanel.Visible := False;
  ActiveControl := PenztarRendbenGomb;
end;

procedure TENGEDELYADAS.KEZDIJENGEDOGOMBClick(Sender: TObject);
begin
  KBizonylatEdit.Clear;
  KezdijTipCombo.ItemIndex := 0;
  KezdijEdit.clear;

  with KezdijEngedelyPanel do
    begin
      Left := 88;
      Top := 320;
      Visible := true;
    end;
  Activecontrol := Kbizonylatedit;

end;

procedure TENGEDELYADAS.kezdijtipcomboChange(Sender: TObject);
begin
  _bizonylatszam := trim(KBizonylatEdit.Text);
  if length(_bizonylatszam)<>10 then
    begin
      ActiveControl := KbizonylatEdit;
      exit;
    end;

  if trim(Kezdijedit.Text)='' then
    begin
      ActiveControl := Kezdijedit;
      exit;
    end;
  ActiveControl := KezdijKonyveloGomb;
end;

procedure TENGEDELYADAS.KEZDIJEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  ActiveControl := KezdijKonyvelogomb;
end;



procedure TENGEDELYADAS.KEZDIJKONYVELOGOMBClick(Sender: TObject);

var _kdjs: string;

begin
  _aktido := Getido;
  _bizonylatszam := trim(KBizonylatEdit.Text);
  if length(_bizonylatszam)<>10 then
    begin
      Activecontrol := KBizonylatedit;
      exit;
    end;

  _tranzindex := GetTranzindex(_bizonylatszam);
  if _tranzindex=0 then
    begin
      KBizonylatedit.clear;
      Activecontrol := KBizonylatedit;
      exit;
    end;

  _kdjs := trim(Kezdijedit.Text);
  if _kdjs='' then
    begin
      Activecontrol := Kezdijedit;
      exit;
    end;
  val(_kdjs,_aktkezdij,_code);
  if _code<>0 then _aktkezdij := 0;

  _kezdtipIndex := KezdijTipCombo.itemindex;
  KezdijKonyveles;
  with FolytatasPanel do
    begin
      Top := 340;
      Left:= 120;
      Visible := true;
    end;

  Activecontrol := TovabbiGomb;

end;

procedure TEngedelyadas.KezdijKonyveles;

begin
  _aktdatums := _konvdatums;
  _farok := midstr(_aktdatums,3,2)+midstr(_aktdatums,6,2);
  _tablanev := 'ENG' + _farok;

  MakeHaviTabla(_tablanev);

  _pcs := 'INSERT INTO ' + _tablanev + ' (ERTEKTAR,PENZTAR,DATUM,IDO,';
  _pcs := _pcs + 'BIZONYLATSZAM,ENGEDELYTARGYA,VALUTANEM,';
  _pcs := _pcs + 'OSSZEG,TRANZAKCIO,KEDVARFOLYAM,ENGEDELYEZO,KEZDIJENGEDELYTIPUS,';
  _pcs := _pcs + 'KEDVKEZDIJ,KEDVEZMENYKOD,CONTROL)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_aktertektar) + ',';
  _pcs := _pcs + inttostr(_kertpenztarNum) + ',';      // penztar
  _pcs := _pcs + chr(39) + _aktdatums + chr(39) + ','; // datum
  _PCS := _pcs + chr(39) + _aktido + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + 'K' + chr(39) + ',';        // engedely targya A K
   _pcs := _pcs + chr(39) + _dnemtomb[_dnemindex] + chr(39) + ',';  // valuta
  _pcs := _pcs + inttostr(_aktbankjegy) + ',';         // osszeg
  _pcs := _pcs + chr(39) + _tranztomb[_tranzindex]+ chr(39) + ',';  // tranzakcio = V E K
  _pcs := _pcs + '0,';                                 // kedvezményes árfolyam
  _pcs := _pcs + chr(39) + _kdengtomb[_kezdtipIndex] + chr(39) + ','; // engedelyezo V E F U J
  _pcs := _pcs + chr(39) + _kezdtomb[_kezdtipIndex] + chr(39) + ',';  // kezdij eng. tipus F K U E
  _pcs := _pcs + inttostr(_aktkezdij) + ',';                // kedvezményes kezdij
  _pcs := _pcs + inttostr(_hitomb[_kezdtipIndex]) + ',';   // kedvezmenykód
  _pcs := _pcs + '0)';                                 // control = const=0

  Remoteparancs(_pcs);
end;


procedure TENGEDELYADAS.TOVABBIGOMBClick(Sender: TObject);
begin
  FolytatasPanel.visible := false;
  KezdijengedelyPanel.Visible := False;
  ArfolyamkedvezmenyPanel.Visible := False;
  GombTakaroPanel.Visible := False;
  Activecontrol := Arfolyamengedogomb;
end;

procedure TEngedelyAdas.MakeHaviTabla(_tnev: string);

begin


  RemoteDbase.close;
  Remotedbase.DatabaseName := _remoteFdbPath;
  RemoteDbase.connected := true;
  RemoteTabla.close;
  RemoteTabla.TableName := _tNev;

  if RemoteTabla.exists then
    begin
      Remotedbase.close;
      exit;
    end;

  _pcs := 'CREATE TABLE ' + _tNev + ' (' + _sorveg;
  _pcs := _pcs + 'ERTEKTAR SMALLINT,' + _sorveg;
  _pcs := _pcs + 'PENZTAR SMALLINT,' + _sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'IDO CHAR (8) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'BIZONYLATSZAM CHAR (7) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'ENGEDELYTARGYA CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'TRANZAKCIO CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'OSSZEG INTEGER,' + _sorveg;
  _pcs := _pcs + 'KEDVARFOLYAM INTEGER,' + _sorveg;
  _pcs := _pcs + 'ENGEDELYEZO CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'KEZDIJENGEDELYTIPUS CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'KEDVKEZDIJ INTEGER,' + _sorveg;
  _pcs := _pcs + 'KEDVEZMENYKOD INTEGER,' + _sorveg;
  _pcs := _pcs + 'CONTROL SMALLINT)';

  RemoteParancs(_pcs);
end;

procedure TEngedelyAdas.RemoteParancs(_ukaz: string);

begin
 

  RemoteDbase.close;
  Remotedbase.DatabaseName := _remoteFdbPath;
  RemoteDbase.connected := true;
  if RemoteTranz.intransaction then RemoteTranz.Commit;
  RemoteTranz.startTransaction;

  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      execSql;
    end;
  Remotetranz.commit;
  RemoteDbase.close;
end;


procedure TENGEDELYADAS.KBIZONYLATEDITKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if ord(Key)<>13 then exit;
  Activecontrol := KezdijKonyvelogomb;
end;



procedure TENGEDELYADAS.BIZONYLATEDITKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  TranzcomboChange(Nil);
end;

function TEngedelyAdas.Getido: string;

begin
  result := Timetostr(Time);
  if midstr(result,2,1)=':' then result := '0' + result;
end;

function TEngedelyadas.GetTranzIndex(_bs: string): byte;

var _kod: byte;

begin
  result := 0;
  _kod := ord(_bs[1]);

  case _kod of
    86: result := 1;   // V
    69: result := 2;   // E
    75: result := 3;   // K
  end;
end;

procedure TEngedelyAdas.AlapadatBeolvasas;

var _pts: string;

begin
  valdbase.connected := true;
  with ValQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _host := trim(FieldByNAme('HOST').AsString);
      Close;
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _pts := trim(FieldByName('PENZTARKOD').asString);
      Close;
    end;
  Valdbase.close;
  val(_pts,_aktertektar,_code);
end;


end.
