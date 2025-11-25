unit Unit11;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, unit1, ExtCtrls, dateUtils, IBDatabase, DB,
  IBCustomDataSet, IBQuery, IBTable, StrUtils, Grids, DBGrids, Wininet;

type
  TZARAS = class(TForm)
    LISTAKGOMB: TBitBtn;
    Label1: TLabel;
    Label2: TLabel;
    Shape1: TShape;
    MENUSHAPE: TShape;
    PILLGOMB: TBitBtn;
    PENZATADGOMB: TBitBtn;
    VISSZAGOMB: TBitBtn;
    PILLPANEL: TPanel;
    Label3: TLabel;
    Label4: TLabel;
    pillallpanel: TPanel;
    PILLBACKGOMB: TBitBtn;
    PENZATADOPANEL: TPanel;
    Shape2: TShape;
    PENZATADBACKGOMB: TBitBtn;
    Shape7: TShape;
    TRANZPANEL: TPanel;
    Label10: TLabel;
    HIDEEDITFT: TEdit;
    BIZONYLATPANEL: TPanel;
    OSSZEGLABEL: TLabel;
    FORINTPANEL: TPanel;
    DATUMLABEL: TLabel;
    DATUMPANEL: TPanel;
    ATADOGOMB: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    TRADEQUERY: TIBQuery;
    TRADEDBASE: TIBDatabase;
    TRADETRANZ: TIBTransaction;
    TRADETABLA: TIBTable;
    LISTAPANEL: TPanel;
    DataSource1: TDataSource;
    LEVKOMBO: TComboBox;
    LHONAPKOMBO: TComboBox;
    lvisszaGOMB: TBitBtn;
    TRADERACS: TDBGrid;
    penzatadogomb: TBitBtn;
    PENZATVEVOGOMB: TBitBtn;
    Shape3: TShape;
    PENZTARVALASZTOPANEL: TPanel;
    Shape4: TShape;
    PENZTARQUERY: TIBQuery;
    PENZTARDBASE: TIBDatabase;
    PENZTARTRANZ: TIBTransaction;
    PENZTARRACS: TDBGrid;
    penztarSOURCE: TDataSource;
    valasztoGomb: TBitBtn;
    megsemvalasztogomb: TBitBtn;
    Shape5: TShape;
    Shape6: TShape;
    TRANZAKCIOPANEL: TPanel;
    Shape8: TShape;
    STORNOGOMB: TBitBtn;
    TRADETABLATIPUS: TIBStringField;
    TRADETABLABIZONYLATSZAM: TIBStringField;
    TRADETABLAKATEGORIA: TIBStringField;
    TRADETABLASTARTDATUM: TIBStringField;
    TRADETABLAENDDATUM: TIBStringField;
    TRADETABLATELEFONSZAM: TIBStringField;
    TRADETABLARENDSZAM: TIBStringField;
    TRADETABLACOUNTRYNAME: TIBStringField;
    TRADETABLAREFERENCEID: TIBStringField;
    TRADETABLATRANZAKCIO: TIBStringField;
    TRADETABLAFIZETENDO: TIntegerField;
    TRADETABLAPENZTAROSNEV: TIBStringField;
    TRADETABLADATUM: TIBStringField;
    TRADETABLAIDO: TIBStringField;
    TRADETABLASZOLGALTATO: TIBStringField;
    TRADETABLASZOLGALTATAS: TIBStringField;
    TRADETABLAUGYFELSZAM: TIntegerField;
    TRADETABLAUGYFELNEV: TIBStringField;
    TRADETABLAUGYFELCIM: TIBStringField;
    TRADETABLATARSPENZTAR: TIBStringField;
    TRADETABLAELKULDVE: TSmallintField;
    TRADETABLASTORNO: TSmallintField;

    procedure LISTAKGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
   
    procedure PILLGOMBClick(Sender: TObject);
    procedure PILLBACKGOMBClick(Sender: TObject);
    procedure VISSZAGOMBClick(Sender: TObject);


    procedure NAPZARGOMBEnter(Sender: TObject);
    procedure NAPZARGOMBExit(Sender: TObject);
    procedure NAPZARGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);


    procedure PENZATADGOMBClick(Sender: TObject);
    procedure PENZATADBACKGOMBClick(Sender: TObject);
    procedure PenztarValasztas;
    procedure UtbizonylatRegiszter;

    procedure FeladasKonyveles;
    procedure FeladasBlokk;

    function Nulele(_num: integer): string;
    function Ftform(_num: integer):string;

    procedure HIDEEDITFTEnter(Sender: TObject);
    procedure HIDEEDITFTExit(Sender: TObject);
    procedure HIDEEDITFTChange(Sender: TObject);

    procedure HIDEEDITFTKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure ATADOGOMBClick(Sender: TObject);
    procedure FORINTPANELClick(Sender: TObject);
    procedure lvisszaGOMBClick(Sender: TObject);
    procedure LEVKOMBOChange(Sender: TObject);
    procedure penzatadogombClick(Sender: TObject);
    procedure PENZATVEVOGOMBClick(Sender: TObject);
    function GetPillallas: integer;
    procedure megsemvalasztogombClick(Sender: TObject);
    procedure valasztoGombClick(Sender: TObject);
    procedure PENZTARRACSCellClick(Column: TColumn);
    procedure PENZTARRACSKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure TRADERACSKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure TRADERACSDblClick(Sender: TObject);
    procedure TRADERACSCellClick(Column: TColumn);
    procedure UjcikkreLepett;
    procedure StornoblokkNyomtatas;
    procedure STORNOGOMBClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ZARAS: TZARAS;
  _utevindex,_uthoindex: integer;
  _ezev,_eho,_enap,_ehnap,_utnap: word;
  _kertev,_kertho,_kertnap,_kerthnap,_hev,_hho: word;
  _kertDatum: TDatetime;
  _kertdatums,_evhonaps,_bizonylat,_text,_tarsPenztar: string;
  _found,_recno,_osszeg,_bill,_aktforint: integer;
  _nyito,_zaro,_matforg,_telforg,_feladas,_code: integer;
  _tradeFile,_longDatumString,_mamas,_obizonylat: string;
  _sendFile,_sendPath: string;
  _iras: File of byte;
  _fileveg: integer = 229;
  _crypss,_stornoOsszeg: integer;
  _hNet,_hFtp: HInternet;

  _remotefile,_localfile,_tranzAkcioIrany: string;
  _pillall : integer;
  _tarspenztarkod,_tarspenztarnev,_tranztext: string;

implementation



{$R *.dfm}

// =============================================================================
              procedure TZARAS.LISTAKGOMBClick(Sender: TObject);
// =============================================================================

begin
 // Listak.showmodal;

  LevKombo.ItemIndex := 2;
  LHonapKombo.ItemIndex := _eho-1;

  _utevindex := 2;
  _uthoindex := _eho-1;

  with  ListaPanel do
    begin
      Top := _top + 80;
      Left := 8;
      Visible := True;
    end;

  _farok := inttostr(_ezev-2000)+nulele(_eho);
  _tradeFile := 'TRAD' + _farok;

  TradeDbase.Connected := true;
  TradeTabla.close;
  Tradetabla.TableName := _tradefile;
  if not TradeTabla.Exists then
    begin
      ShowMessage('NINCS ADAT A HÓNAPRÓL !');
      TradeDbase.Close;
      ActiveControl := LHonapKOmbo;
      exit;
    end;

  with TradeQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add('SELECT * FROM '+ _tradeFile);
      Open;
    end;
  Ujcikkrelepett;
  ActiveControl := TradeRacs;
end;


// =============================================================================
                  procedure TZARAS.FormActivate(Sender: TObject);
// =============================================================================

var i: integer;
begin
  Top := _top;
  Left := _left;
  Height := 768;
  Width := 1024;

  PillPanel.Visible := false;
  PenzAtadoPanel.Visible := false;
  ListaPanel.Visible := false;
  Menushape.Height := 210;

  // ------------------------------------------

  _ezev := yearof(date);
  _eho := monthof(date);
  _enap := dayof(date);
  _ehnap := dayoftheweek(date);
  _longDatumString := inttostr(_ezev)+' '+_honev[_eho]+' '+inttostr(_enap);
  _longDatumString := _longDatumString + ' ' + _napnev[_ehnap];
  _mamas := Form1.Hundatetostr(date);

  LevKombo.Clear;
  LevKombo.Items.Clear;

  for i := -2 to 0 do LEvkombo.Items.add(inttostr(_ezev+i));

  LHonapKombo.clear;
  LHonapkombo.items.clear;

  for i := 1 to 12 do LHonapKombo.items.add(_honev[i]);

  _utnap := daysinamonth(_ezev,_eho);

end;

// =============================================================================
              procedure TZARAS.PILLGOMBClick(Sender: TObject);
// =============================================================================

var _pills: string;
    _pillall: integer;

begin
  Form1.Logbair('PILLANATNYI KÉSZLETRE KLIKKELT');
  Menushape.Height := 290;
  TradeDbase.Connected := true;
  with TradeQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add('SELECT * FROM PARAMETERS');
      Open;
      _pillall := FieldByName('PILLALLAS').asInteger;
      Close;
    end;
 TradeDbase.close;

 _pills := formatfloat('### ### ###',(1*_pillall))+' Ft';
 PillallPanel.Caption := _pills;
 fORM1.Logbair('Pillanatnyi állás: '+ _pills);
  with PillPanel do
    begin
      top := 260;
      left := 296;
      Visible := True;
    end;
  ActiveControl := pillbackgomb;
end;

// =============================================================================
             procedure TZARAS.PILLBACKGOMBClick(Sender: TObject);
// =============================================================================

begin
  PillPanel.Visible := false;
  Menushape.Height := 210;
end;

// =============================================================================
             procedure TZARAS.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;




// =============================================================================
             procedure TZARAS.NAPZARGOMBEnter(Sender: TObject);
// =============================================================================

begin
  TBItbtn(sender).Font.Color := clBlack;
end;

// =============================================================================
            procedure TZARAS.NAPZARGOMBExit(Sender: TObject);
// =============================================================================

begin
  TBitbtn(sender).Font.Color := clGray;
end;

// =============================================================================
    procedure TZARAS.NAPZARGOMBMouseMove(Sender: TObject; Shift: TShiftState;
                                               X, Y: Integer);
// =============================================================================

begin
  ActiveControl := Tbitbtn(sender);
end;

procedure TZARAS.PENZATADGOMBClick(Sender: TObject);
begin
  Tranzpanel.Visible := false;
  PenztarValasztoPanel.Visible := False;

  with Penzatadopanel do
    begin
      Top := 160;
      Left := 8;
      Visible := True;
    end;

  _utbizonylat := Form1.GetUtBizonylat;
  _bizonylat := 'F' + form1.HatNulele(_utbizonylat+1);
  BizonylatPanel.Caption := 'F' + midstr(_bizonylat,2,6);

  HideeditFt.Text := '';
  DatumPanel.caption := _mamas;

  Penzatvevogomb.Enabled := True;
  Penzatadogomb.Enabled := true;
  ActiveControl := Penzatadogomb;


//  ActiveControl := HideEditFt;

end;

// =============================================================================
          procedure TZARAS.PENZATADBACKGOMBClick(Sender: TObject);
// =============================================================================

begin
  Penzatadopanel.Visible := false;
  ActiveControl := Penzatadgomb;
end;


// =============================================================================
                    function TZaras.Nulele(_num: integer): string;
// =============================================================================


begin
  result := inttostr(_num);
  if _num<10 then result := '0' + result;
end;


// =============================================================================
               function TZaras.Ftform(_num: integer): string;
// =============================================================================


var _nums: string;
    _wm: integer;

begin
  _nums := inttostr(_num);
  _wm := length(_nums);
  if _wm>6 then
      _nums := leftstr(_nums,_wm-6)+' '+midstr(_nums,_wm-5,3)+' '+midstr(_nums,_wm-2,3);
  if (_wm>3) and (_wm<7) then
      _nums := leftstr(_nums,_wm-3)+' '+midstr(_nums,_wm-2,3);
  while length(_nums)<9 do _nums := ' ' + _nums;
  result := _nums + ' Ft';
end;



// =============================================================================
                procedure TZARAS.HIDEEDITFTEnter(Sender: TObject);
// =============================================================================

begin
  ForintPanel.Color := clWhite;
  ForintPanel.BorderStyle := BsSingle;
end;

// =============================================================================
               procedure TZARAS.HIDEEDITFTExit(Sender: TObject);
// =============================================================================

begin
  ForintPanel.Color := $B0FFFF;
  ForintPanel.BorderStyle := bsNone;
end;

// =============================================================================
             procedure TZARAS.HIDEEDITFTChange(Sender: TObject);
// =============================================================================


begin
  _text := Hideeditft.text;
  val(_text,_osszeg,_code);
  if _code<>0 then _osszeg := 0;
  if _osszeg=0 then
    begin
      HideeditFt.Text := '';
      ForintPanel.Caption := '';
      exit;
    end;
  Forintpanel.Caption := ftform(_osszeg);
end;

// =============================================================================
         procedure TZARAS.HIDEEDITFTKeyDown(Sender: TObject; var Key: Word;
                                                         Shift: TShiftState);
// =============================================================================

begin
  if ord(key)=13 then
    begin
      ActiveContrOL := AtadoGomb;
      exit;
    end;
end;


// =============================================================================
             procedure TZARAS.MEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  PenzatadoPanel.Visible := false;
  ActiveControl := PenzatadGomb;
end;

// =============================================================================
               procedure TZARAS.ATADOGOMBClick(Sender: TObject);
// =============================================================================


begin
  _pillall := GetPillallas;
  _text := HideeditFt.text;
  val(_text,_osszeg,_code);
  if _code<>0 then _osszeg := 0;
  if _osszeg = 0 then
    begin
      ShowMessage('Nem adtad meg az összeget');
      HideeditFt.text := '';
      ActiveControl := HideeditFt;
      exit;
    end;
  if _tranzakcioIrany= '-' then
    begin
      if _osszeg>_pillall then
        begin
          ShowMessage('NINCS ENNYI PÉNZ FELADÁSRA !');
          EXIT;
        end;
     end;
  FeladasKonyveles;
  FeladasBlokk;
  PenzatadoPanel.Visible := false;
  ActiveControl := PenzatadGomb;
end;


// =============================================================================
                     procedure TZaras.FeladasKonyveles;
// =============================================================================


begin
  _farok := nulele(_ezev-2000)+nulele(_eho);
  _TradeFile := 'TRAD' + _farok;
  _idos := Form1.getidos;

  IF _tranzakcioirany='+' then _osszeg := trunc((-1)*_osszeg);

  _pcs := 'INSERT INTO ' + _tradefile + ' (TIPUS,BIZONYLATSZAM,FIZETENDO,PENZTAROSNEV,';
  _pcs := _pcs + 'DATUM,IDO,TARSPENZTAR,ELKULDVE,STORNO)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39)+'F'+chr(39)+',';
  _pcs := _pcs + chr(39) + _bizonylat + chr(39) + ',';
  _pcs := _pcs + inttostr(_osszeg) + ',';
  _pcs := _pcs + chr(39) + _prosnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mamas + chr(39) + ',';
  _pcs := _pcs + chr(39) + _idos + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tarspenztarkod + chr(39) + ',0,0)';
  Form1.TRadeParancs(_pcs);

  // ---------------------------------------------------------

  TradeDbase.Connected := true;
  _pcs := 'SELECT * FROM PARAMETERS';
  with TradeQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      _pillall := FieldByname('PILLALLAS').asInteger;
      close;
    end;
  TradeDbase.close;

  _pillall := _pillall - _osszeg;
  _utbizonylat := Form1.GetUtbizonylat;
  inc(_utbizonylat);
  UtbizonylatRegiszter;
end;

procedure Tzaras.UtbizonylatRegiszter;

begin
  _pcs := 'UPDATE PARAMETERS SET UTBIZONYLAT='+inttostr(_utbizonylat)+',';
  _pcs := _pcs + 'PILLALLAS=' + inttostr(_pillall);
  Form1.TRadeParancs(_pcs);
end;

// =============================================================================
            procedure TZARAS.FORINTPANELClick(Sender: TObject);
// =============================================================================

begin
  ActiveControl := HideEditFt;
end;


// =============================================================================
                        procedure TZaras.FeladasBlokk;
// =============================================================================


begin
  Form1.Blokknyitas;
  Form1.BlokkFocimIro;
  writeLn(_LFile,'Kereskedelmi penzforgalom az ertektarral');
  writeLn(_LFile,dupestring('-',39));

  if _tranzAkcioIrany = '+' then
    begin
      writeLn(_LFile,'       Bizonylatszam: ' + 'F-'+midstr(_bizonylat,2,6));
      writeLn(_LFile,'      Feladas datuma: ' + _mamas);
      writeLn(_LFile,'       Feladas ideje: ' + _idos);
      writeLn(_LFile,'     Feladott osszeg: ' + trim(ftform(_osszeg)));
      writeLn(_LFile,'         Tarspenztar: ' + _tarspenztarnev);
      writeLn(_LFile,'    Feladast vegezte: ' + leftstr(_prosnev,18));
    end else
    begin
      writeLn(_LFile,'       Bizonylatszam: ' + 'F-'+midstr(_bizonylat,2,6));
      writeLn(_LFile,'      Atvetel datuma: ' + _mamas);
      writeLn(_LFile,'       Atvetel ideje: ' + _idos);
      writeLn(_LFile,'       Atvett osszeg: ' + trim(ftform(_osszeg)));
      writeLn(_LFile,'         Tarspenztar: ' + _tarspenztarnev);
      writeLn(_LFile,'    Atvetelt vegezte: ' + leftstr(_prosnev,18));
    end;

  writeLn(_LFile,dupestring('-',39));
  Form1.StartNyomtatas;
  if _tranzakcioIrany='+' then Form1.Logbair('Pénzfeladás az értéktárnak')
  else Form1.Logbair('Pénzátvétel az értéktártól');

  Form1.Logbair('Biz: '+ 'F-'+midstr(_bizonylat,2,6));
  Form1.Logbair('Összeg: ' + inttostr(_osszeg));

end;


procedure TZaras.StornoblokkNyomtatas;

begin
  Form1.Logbair('Stornoblokkot nyomtat');
  Form1.Blokknyitas;
  Form1.BlokkFocimIro;
  writeLN(_LFile,'Penzforgalmi bizonylat stornoja');
  writeLn(_LFile,'Stornozott bizonylat: ' + _obizonylat);
  writeLn(_LFile,'    Storno bizonylat: ' + _bizonylat);
  writeLn(_LFile,'    Stornozas datuma: ' + _mamas);
  writeLn(_LFile,'   Stornozott osszeg: ' + trim(ftform(_stornoosszeg)));
  writeLn(_LFile,'         Tarspenztar: ' + _tarspenztarnev);
  writeLn(_LFile,'  Stornozast vegezte: ' + leftstr(_prosnev,18));
  writeLn(_LFile,dupestring('-',39));
  Form1.StartNyomtatas;
end;


// =============================================================================
                 procedure TZARAS.lvisszaGOMBClick(Sender: TObject);
// =============================================================================

begin
  TradeQuery.close;
  TradeDbase.close;
  ListaPanel.Visible := False;
  ActiveControl := ListakGomb;
end;

// =============================================================================
               procedure TZARAS.LEVKOMBOChange(Sender: TObject);
// =============================================================================

begin
  _kertev := _ezev - 2 + LevKombo.itemindex;
  _kertho := 1 + LHonapKombo.itemindex;
  _farok := inttostr(_kertev-2000)+nulele(_kertho);
  _tradeFile := 'TRAD' + _farok;
  TradeDbase.connected := True;
  TradeTabla.Close;
  TradeTabla.TableName := _tradeFile;
  if not TradeTabla.Exists then
    begin
      ShowMessage('NINCS A KÉRT HÓNAPRÓL ADAT');

      LevKombo.ItemIndex := _utevindex;
      LHonapKombo.ItemIndex := _uthoIndex;

      activecontrol := TradeRacs;
      exit;
    end;

  _utevindex := LevKombo.itemindex;
  _uthoIndex := LhonapKombo.ItemIndex;

  with TradeQuery do
    begin
      close;
      Sql.Clear;
      sql.Add('SELECT * FROM ' + _tradeFile);
      Open;
    end;
  Form1.Logbair('Megnyitotta: '+_tradefile+'-t');
  ActiveControl := TradeRacs;
end;




(*

1234567890123456789012345678901234567890
----------------------------------------
      EEXXCCLLUUSSIIVVEE  BBEESSTT
             CCHHAANNGGEE
123 szamu penztar       Hodmezovasarhely
Penztaros: Baradlay Richard
----------------------------------------
       Egyeb kereskedelem napi zaras
        2010 szeptember 21 csutortok
----------------------------------------
        Napi nyitoosszeg: 1 000 000 Ft
       Autopalya matrica: 2 500 000 Ft
  Mobiltelefon feltoltes:   430 000 Ft
    Teljes napi forgalom: 2 930 000 Ft
  Feladas az ertektarnak: 2 900 000 Ft
         Napi zaroosszeg:    30 000 Ft
----------------------------------------

1234567890123456789012345678901234567890
----------------------------------------
      EEXXCCLLUUSSIIVVEE  BBEESSTT
             CCHHAANNGGEE
123 szamu penztar       Hodmezovasarhely
Penztaros: Baradlay Richard
----------------------------------------
       Egyeb kereskedelem havi zaras
          2010 szeptember honap
----------------------------------------
        Havi nyitoosszeg: 1 000 000 Ft
       Autopalya matrica: 2 500 000 Ft
  Mobiltelefon feltoltes:   430 000 Ft
    Teljes havi forgalom: 2 930 000 Ft
  Feladas az ertektarnak: 2 900 000 Ft
       Hovegi zaroosszeg:    30 000 Ft
----------------------------------------


1234567890123456789012345678901234567890
----------------------------------------
      EEXXCCLLUUSSIIVVEE  BBEESSTT
             CCHHAANNGGEE
123 szamu penztar       Hodmezovasarhely
Penztaros: Baradlay Richard
----------------------------------------
Kereskedelmi penzfeladas az ertektarnak
----------------------------------------
       Bizonylatszam: F-100234
      Feladas datuma: 2010.12.15
       Feladas ideje: 12:30
     Feladott osszeg: 12 450 Ft
    Feladast vegezte: 123456789012345678
----------------------------------------
*)

procedure TZARAS.penzatadogombClick(Sender: TObject);
begin
  Form1.Logbair('Pénzátadásra klikkelt');
  _TranzakcioIrany := '-';
  PenztarValasztas;
end;

procedure TZARAS.PENZATVEVOGOMBClick(Sender: TObject);
begin
  fORM1.Logbair('Pénzátvételre klikkelt');
  _TranzakcioIrany := '+';
  PenztarValasztas;
end;

function Tzaras.GetPillAllas: integer;

begin
  TradeDbase.Connected := true;
  _pcs := 'SELECT * FROM PARAMETERS';
  with TradeQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      result := FieldByname('PILLALLAS').asInteger;
      close;
    end;
  TradeDbase.close;
end;

// =============================================================================
                        procedure Tzaras.PenztarValasztas;
// =============================================================================

begin
  Penzatadogomb.Enabled := False;
  Penzatvevogomb.Enabled := False;

  PenztarDbase.connected := true;

  _pcs := 'SELECT * FROM PENZTAR' + _sorveg;
  _pcs := _pcs + 'WHERE PENZTARKOD<>'+chr(39)+_homepenztarSzam+chr(39);

  with PenztarQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  with PenztarValasztoPanel do
    begin
      Top := 72;
      Left := 160;
      Visible := True;
    end;

  ActiveControl := PenztarRacs;
end;

procedure TZARAS.megsemvalasztogombClick(Sender: TObject);
begin
  Modalresult := 2;
end;

// =============================================================================
               procedure TZARAS.valasztoGombClick(Sender: TObject);
// =============================================================================

begin
  _tarspenztarKod := trim(Penztarquery.FieldByName('PENZTARKOD').asstring);
  _tarspenztarNev := trim(Penztarquery.FieldByName('PENZTARNEV').asstring);

  PenztarQuery.close;
  PenztarDbase.close;
  _tranztext := 'PÉNZÁTADÁS ';

  if _tranzakcioIrany='+' then _tranzText := 'PÉNZÁTVÉTEL ';
  _tranztext := _tranztext + _tarsPenztarnev;

  if _tranzAkcioIrany='+' then _tranztext := _tranzText + 'TOL'
  else _tranztext := _tranzText + 'NAK';
  TranzakcioPanel.Caption := _tranzText;

  if _tranzAkcioirany='+' then
    begin
      DatumLabel.Caption  := 'ÁTVÉTEL KELTE:';
      OsszegLabel.caption := 'ÁTVETT ÖSSZEG:';
      Atadogomb.Caption  := 'ÁTVÉTEL KÖNYVELHETÖ';
    end else
    begin
      DatumLabel.Caption  := 'ÁTADÁS KELTE:';
      OsszegLabel.caption := 'ÁTADOTT ÖSSZEG:';
      Atadogomb.Caption := 'ÁTADÁS KÖNYVELHETÖ';
    end;

  Tranzpanel.visible := True;
  PenztarValasztoPanel.Visible := false;
  HideeditFt.Clear;
  ActiveControl := HideeditFt;
end;

procedure TZARAS.PENZTARRACSCellClick(Column: TColumn);
begin
  ValasztoGombClick(Nil);
end;

procedure TZARAS.PENZTARRACSKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  ValasztoGombClick(Nil);
end;

procedure TZARAS.TRADERACSKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  UjcikkreLepett;
end;


procedure TZaras.UjcikkreLepett;

var _akttipus,_aktdatum: string;
    _storno : integer;

begin
  _akttipus := TradeQuery.Fieldbyname('TIPUS').asstring;
  _storno := TradeQuery.FieldByName('STORNO').asInteger;
  _aktdatum := tradeQuery.FieldByName('DATUM').asstring;
  if (_akttipus='F') and (_aktdatum=_mamas) and (_storno<>2) and (_storno<>3) then
  stornogomb.Enabled := true else stornogomb.Enabled := false;


end;

procedure TZARAS.TRADERACSDblClick(Sender: TObject);
begin
  UjcikkreLepett;
end;

procedure TZARAS.TRADERACSCellClick(Column: TColumn);
begin
  Ujcikkrelepett;
end;

procedure TZARAS.STORNOGOMBClick(Sender: TObject);
begin
  // itt stornozok egy mai napi stornozatlan f-es bizonylatot
  Form1.Logbair('Stornogombra klikkelt');
  with Tradequery do
    begin
      _fizetendo := FieldByName('FIZETENDO').asInteger;
      _tarsPenztar := fieldByName('TARSPENZTAR').asstring;
      _obizonylat := fieldByName('BIZONYLATSZAM').asstring;
    end;
  Form1.Logbair('Stornozott biz: '+ _obizonylat+' érték: '+inttostr(_fizetendo));

  // elöszöt a valasztott rekordon a stornot 2-re állitom:

  _pcs := 'UPDATE ' + _tradefile + ' SET STORNO=2' + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39) + _obizonylat + chr(39);
  Form1.TradeParancs(_pcs);

  // ---------  Bejegyzek egy stornoszámlát  -----------------------------------

  _utbizonylat := Form1.GetUtBizonylat;
  inc(_utbizonylat);
  _bizonylat := 'F' + form1.HatNulele(_utbizonylat);
  _stornoosszeg := trunc((-1)*_fizetendo);
  _pcs := 'INSERT INTO ' + _tradefile + ' (BIZONYLATSZAM,TARSPENZTAR,FIZETENDO,';
  _pcs := _pcs + 'STORNO,DATUM)';
  _pcs := _pcs + 'VALUES (' + chr(39) + _bizonylat + chr(39) + ',';
  _pcs := _pcs +  chr(39) + _tarspenztar + chr(39) + ',';
  _pcs := _pcs +  inttostr(_stornoosszeg)+',3,';
  _pcs := _pcs + chr(39)+_mamas+chr(39) + ')';
  Form1.Tradeparancs(_pcs);

  // felirom a pillanatnyi állást és az utolsó biz számot:

  _aktforint := Getpillallas;
  _pillall := _aktforint + _fizetendo;
  Utbizonylatregiszter;
  StornoBlokknyomtatas;

  ListaPanel.Visible := False;
  ActiveControl := ListakGomb;

end;

end.

