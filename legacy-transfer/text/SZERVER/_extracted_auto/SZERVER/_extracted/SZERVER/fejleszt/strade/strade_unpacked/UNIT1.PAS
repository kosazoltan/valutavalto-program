unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DB, IBDatabase, IBCustomDataSet, IBQuery,
  Grids, DBGrids, Strutils, IBTable, ExtCtrls, DateUtils;

type
  TForm1 = class(TForm)
    TEMPRACS: TDBGrid;
    TRADEQUERY: TIBQuery;
    TRADEDBASE: TIBDatabase;
    TRADETRANZ: TIBTransaction;
    TEMPSOURCE: TDataSource;
    CIKKTORZSQUERY: TIBQuery;
    IRODAQUERY: TIBQuery;
    CIKKTORZSDBASE: TIBDatabase;
    IRODADBASE: TIBDatabase;
    CIKKTORZSTRANZ: TIBTransaction;
    IRODATRANZ: TIBTransaction;
    KILEPOGOMB: TBitBtn;
    Label1: TLabel;
    HTRADETABLA: TIBTable;
    HTRADEQUERY: TIBQuery;
    HTRADEDBASE: TIBDatabase;
    HTRADETRANZ: TIBTransaction;
    GroupBox1: TGroupBox;
    RONEMONTH: TRadioButton;
    NAPNEVPANEL: TPanel;
    VALTOCOMBO: TComboBox;
    GroupBox2: TGroupBox;
    RALLOFFICES: TRadioButton;
    RONEOFFICE: TRadioButton;
    etarbox: TGroupBox;
    RONEVALUESTOCK: TRadioButton;
    RALLVALUESTOCK: TRadioButton;
    GroupBox4: TGroupBox;
    RALLITEMS: TRadioButton;
    RPHONEFILL: TRadioButton;
    RCARLICENSE: TRadioButton;
    RPAYING: TRadioButton;
    TRADETABLA: TIBTable;
    ETARCOMBO: TComboBox;
    OSSZESPANEL: TPanel;
    Label2: TLabel;
    TRADETABLAIRODASZAM: TSmallintField;
    TRADETABLATIPUS: TIBStringField;
    TRADETABLADATUM: TIBStringField;
    TRADETABLACIKKSZAM: TSmallintField;
    TRADETABLACIKKNEV: TIBStringField;
    TRADETABLAEGYSEGAR: TIntegerField;
    TRADETABLABEFIZETVE: TIntegerField;
    TRADETABLAIRODANEV: TIBStringField;
    TRADETABLAERTEKTAR: TSmallintField;
    TRADEQUERYIRODASZAM: TSmallintField;
    TRADEQUERYTIPUS: TIBStringField;
    TRADEQUERYDATUM: TIBStringField;
    TRADEQUERYCIKKSZAM: TSmallintField;
    TRADEQUERYCIKKNEV: TIBStringField;
    TRADEQUERYEGYSEGAR: TIntegerField;
    TRADEQUERYBEFIZETVE: TIntegerField;
    TRADEQUERYIRODANEV: TIBStringField;
    TRADEQUERYERTEKTAR: TSmallintField;
    RTERM: TRadioButton;
    IDOSZAKPANEL: TPanel;
    GroupBox5: TGroupBox;
    EVCOMBO: TComboBox;
    HONAPCOMBO: TComboBox;
    TOLNAPCOMBO: TComboBox;
    IGNAPCOMBO: TComboBox;
    Label3: TLabel;
    Label4: TLabel;
    IGEVPANEL: TPanel;
    IGHONAPPANEL: TPanel;
    FUGGONY: TPanel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    SUMMAPANEL: TPanel;
    SUMMAQUERY: TIBQuery;
    SUMMADBASE: TIBDatabase;
    SUMMATRANZ: TIBTransaction;
    EGYENLEGGOMB: TBitBtn;
    IBTable1: TIBTable;
    IBTable1IRODASZAM: TSmallintField;
    IBTable1BEVETEL: TIntegerField;
    IBTable1KIADAS: TIntegerField;
    IBTable1NYITO: TIntegerField;
    IBTable1ZARO: TIntegerField;
    summaracs: TDBGrid;
    MULTEVIGOMB: TBitBtn;
    EZEVIGOMB: TBitBtn;
    HAVITABLA: TIBTable;
    HAVIDBASE: TIBDatabase;
    HAVITRANZ: TIBTransaction;
    HAVISOURCE: TDataSource;
    visszagomb: TBitBtn;
    HAVITABLAIRODASZAM: TSmallintField;
    HAVITABLAERTEKTAR: TSmallintField;
    HAVITABLAHONAP: TSmallintField;
    HAVITABLANYITO: TIntegerField;
    HAVITABLAMATRICA: TIntegerField;
    HAVITABLATELEFON: TIntegerField;
    HAVITABLAATADAS: TIntegerField;
    HAVITABLAZARO: TIntegerField;
    TEMPQUERY: TIBQuery;
    TEMPDBASE: TIBDatabase;
    TEMPTRANZ: TIBTransaction;
    TEMPQUERYIRODASZAM: TSmallintField;
    TEMPQUERYDATUM: TIBStringField;
    TEMPQUERYCIKKSZAM: TSmallintField;
    TEMPQUERYCIKKNEV: TIBStringField;
    TEMPQUERYEGYSEGAR: TIntegerField;
    TEMPQUERYBEFIZETVE: TIntegerField;
    TEMPQUERYIRODANEV: TIBStringField;
    TEMPQUERYERTEKTAR: TSmallintField;
    TEMPQUERYTIPUS: TIBStringField;
    KIJELZESGOMB: TBitBtn;
    termtakaro: TPanel;
    BALFUGGONY: TPanel;
    jobbfuggony: TPanel;
    ETARTAKARO: TPanel;

    procedure KILEPOGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure Cikktorzsbeolvasas;
    procedure IrodaBeolvasas;
 //   procedure RacsDisplay;
 //   procedure EgyHonapValtozott;

    function Nulele(_int: integer): string;
    procedure HONEVCOMBOChange(Sender: TObject);
    procedure RONEMONTHClick(Sender: TObject);
    procedure EVCOMBOChange(Sender: TObject);
 //   procedure NAPCOMBOChange(Sender: TObject);
    procedure RTOTALMONTHClick(Sender: TObject);
    procedure RONEOFFICEClick(Sender: TObject);
    procedure VALTOCOMBOChange(Sender: TObject);
    procedure RALLOFFICESClick(Sender: TObject);
    procedure RONEVALUESTOCKClick(Sender: TObject);
    procedure RALLVALUESTOCKClick(Sender: TObject);
    procedure ETARCOMBOChange(Sender: TObject);
    procedure RPHONEFILLClick(Sender: TObject);
    FUNCTION Forintform(_int: integer): string;
    procedure RTERMClick(Sender: TObject);
    procedure TolnapToltes;
    procedure IgalapraAllitas;
 
    function GetSumirodass(_irsz: integer): integer;
    function ScanIrodaNev(_isz: integer):string;
    function ScanErtektar(_isz: integer):integer;


    procedure TOLEVCOMBOChange(Sender: TObject);
    procedure IGNAPCOMBOChange(Sender: TObject);
    procedure TOLNAPCOMBOChange(Sender: TObject);
    procedure MULTEVIGOMBClick(Sender: TObject);
    procedure EZEVIGOMBClick(Sender: TObject);
    procedure EGYENLEGGOMBClick(Sender: TObject);
    procedure visszagombClick(Sender: TObject);
    procedure FuggonyLe;
    function Setfilter: string;
    procedure KIJELZESGOMBClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _pcs,_evhos: string;
  _sorveg: string = chr(13)+chr(10);

  _HONAPNEV: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS',
        'MÁJUS','JUNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
        'NOVEMBER','DECEMBER');

  _NAPNEV: array[1..7] of string = ('HÉTFŐ','KEDD','SZERDA','CSÜTÖRTÖK',
         'PÉNTEK','SZOMBAT','VASÁRNAP');

  _evIndex,_hoIndex,_aktev,_aktnap,_napindex,_akthonap: integer;
  _aktirodaszam,_valtoIndex,_aktertektarszam,_etarindex,_recno: integer;

  _aktdatums,_aktirodas,_aktcikknev,_tablanev,_aktcikktipus: string;
  _aktiroda,_code,_irodasorszam,_aktertektar,_aktcikkszam,_befiz: integer;
  _cikksorszam,_aktegysegar,_irodadarab,_cikkszamdarab,_ss: integer;
  _aktirodaNev,_mondat,_farok,_fpath,_aktTablanev: string;
  irodanevek,cikknevek,cikktipusok: array of string;
  Ertektarak,egysegarak,irodaszamok,cikkszamok: array of integer;

  Ertektarszamok: array[0..7] of integer = (10,20,40,50,63,75,120,145);
  ErtektarNevek : array[0..7] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
                   'DEBRECEN','NYÍREGYHÁZA','BÉKÉSCSABA','PÉCS','KAPOSVÁR');

  _olvas: textfile;
  _maiev,_maihonap,_mainap: word;
  _mamas: string;
  _tombMeret,_havinapok,_hnap,_sum,_tt,_ujEvHodarab: integer;
  _sirodadarab,_cikkszam,_xx: integer;
  _sirss,_bevetel,_kiadas: array[0..149] of integer;
  _vancond: boolean;
  _aktdatum: TDatetime;

  _top,_left,_height,_width,_tmfileDarab,_egyaktev,_ignap: integer;
  _utevhos: string;
  _ujevhos: array[0..24] of string;
  _srec: Tsearchrec;
  _indexnev,_filter,_AKTHonapNev: string;
  _kertev,_kertho,_kerttolnap,_kertignap,_kertirodaszam,_kertertektar: integer;
  _kerttoldatum,_kertigdatum: string;


function tradedataload: integer; stdcall; external 'c:\receptor\bin\tradload.dll' name 'tradedataload';


implementation

uses Unit2;

{$R *.dfm}




// =============================================================================
               procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

var i: integer;

begin
   Top  := 120;
   Left := 130;

   FuggonyLe;
   SummaPanel.Visible   := False;
   OsszesPanel.Caption  := '';
   TermTakaro.visible   := true;

   _aktev := yearof(date);

   // ------------------------------------

   Form1.Repaint;

   _maiev       := yearof(Date);
   _maihonap    := monthof(Date);
   _mainap      := dayof(Date);
   _mamas       := leftstr(datetostr(date),10);
   _aktev       := _maiev;
   _akthonap    := _maiHonap;
   _aktnap      := _mainap;

   // --------------------------------------------------------------------------

   // Cikkek beolvasása: c:\receptor\database\matcikkek.Fdb-ből
   Cikktorzsbeolvasas;

   // Irodák beolvasás: c:\receptor\database\receptor.Fdb-ből
   Irodabeolvasas;

   // --------------------------------------------------------------------------

   if Findfirst('c:\receptor\mail\trade\tm*.*',faanyfile,_srec)=0 then
     begin
       Findclose(_srec);
       tradedataload;    // dll-lel tölti a tradeyymm táblákat txt file-ok alapján
       _egyaktev := _aktev;
       Haviegyenleg.showModal;
     end;

   // -------------------------------------

   Evcombo.Items.clear;
   for i := 0 to 2 do Evcombo.Items.Add(inttostr(_maiev+i-2));
   Evcombo.ItemIndex := 2;

   HonapCombo.Items.Clear;
   for i := 1 to 12 do HonapCombo.Items.add(_honapNev[i]);
   HonapCombo.ItemIndex := _akthonap-1;
   _AKTHonapNev := _HonapNev[_aktHonap-1];

   ValtoCombo.Items.Clear;
   for i := 0 to _irodaDarab-1 do ValtoCombo.Items.add(IrodaNevek[i]);
   ValtoCombo.ItemIndex := 0;

   EtarCombo.Items.clear;
   for i := 0 to 7 do Etarcombo.Items.Add(Ertektarnevek[i]);

   // --------------------------------------------------------------------------

   // Rádiócheck alapállás

   ROneMonth.Checked      := true;
   RallOffices.Checked    := True;
   RAllValueStock.Checked := True;
   Rallitems.Checked      := True;

   // --------------------------------------------------------------------------

   NapNevPanel.Visible := False;

   Valtocombo.Text := '';
   ValtoCombo.Enabled := False;
   EtarCombo.Text := '';
   Etarcombo.Enabled := False;
   ActiveControl := KijelzesGomb;
end;


// =============================================================================
                    procedure TForm1.Cikktorzsbeolvasas;
// =============================================================================

begin
  cikktorzsdbase.Connected := true;
  _pcs := 'SELECT *  FROM CIKKTORZS ORDER BY CIKKSZAM';
  with cikktorzsQuery do
    begin
      close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      Last;
      _cikkszamDarab := Recno;
      First;
    end;

  _tombMeret := _cikkszamdarab+1;

  Setlength(cikkszamok,_tombMeret);
  Setlength(cikknevek,_tombMeret);
  setlength(cikktipusok,_tombMeret);
  Setlength(egysegarak,_tombmeret);

  _ss := 0;
  while not CikktorzsQuery.eof do
    begin
      with CikktorzsQuery do
        begin
          _aktcikkszam := FieldByName('CIKKSZAM').asInteger;
          _aktcikknev := FieldByName('CIKKNEV').asString;
          _aktcikktipus := FieldByName('TIPUS').asString;
          _aktegysegar := FieldByName('EGYSEGAR').asInteger;
        end;
      Cikkszamok[_ss] := _aktcikkszam;
      Cikknevek[_ss] := trim(_aktcikknev);
      Cikktipusok[_ss] := _aktcikktipus;
      Egysegarak[_ss] := _aktegysegar;
      inc(_ss);
      CikktorzsQuery.Next;
    end;
  CikktorzsQuery.close;
  Cikktorzsdbase.close;
end;

// =============================================================================
                     procedure TForm1.IrodaBeolvasas;
// =============================================================================


begin
  IrodaDbase.connected := true;
  _pcs := 'SELECT *  FROM IRODAK'+_sorveg;
  _pcs := _pcs + 'WHERE (STATUS=' +chr(39)+ 'P' + chr(39)+') AND (KESZLETNEV<>'+CHR(39)+CHR(39)+')'+_sorveg;
  _pcs := _pcs + 'ORDER BY KESZLETNEV';
  with IrodaQuery do
    begin
      Close;
      Sql.clear;
      sql.add(_Pcs);
      Open;
      Last;
      _irodadarab := Recno;
      First;
    end;
  setlength(Irodanevek,_irodadarab+1);
  setlength(irodaszamok,_irodadarab+1);
  setlength(ertektarak,_irodadarab+1);

  _ss := 0;
  while not irodaquery.eof do
    begin
      with Irodaquery do
        begin
          _aktirodanev := FieldByName('KESZLETNEV').asString;
          _aktiroda := FieldByname('UZLET').asInteger;
          _aktertektar := FieldByName('ERTEKTAR').asInteger;
        end;
      Irodanevek[_ss]  := TRIM(_aktirodanev);
      Irodaszamok[_ss] := _aktiroda;
      Ertektarak[_ss]  := _aktertektar;
      inc(_ss);
      Irodaquery.next;
    end;
  IrodaQuery.close;
  IrodaDbase.close;
end;



// =============================================================================
                procedure TForm1.KILEPOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;

(*

// =============================================================================
                     procedure TForm1.RacsDisplay;
// =============================================================================


var _ignapIndex,i: integer;
    _ignaps: string;
    _toldatums,_igdatums: string;

begin
  if Summapanel.Visible then
    begin
      Havitabla.CLose;
      _Tablanev := 'HAVI'+inttostr(_aktev);
      _indexnev := 'X'+inttostr(_aktev)+'2';
      Havitabla.TableName := _tablanev;
      HaviDbase.Connected := true;
      if not Havitabla.Exists then
        begin
          ShowMessage('HIÁNYZIK A KÉRT ÉV EGYENLEGE');
          EXIT;
        end;
      Havitabla.IndexName := _indexnev;
      Havitabla.Filtered := false;
      _valtoindex := Valtocombo.itemindex;
      _aktirodaszam := Irodaszamok[_valtoindex];
      _filter := 'IRODASZAM='+inttostr(_aktirodaszam);
      Havitabla.Filter := _filter;
      Havitabla.Filtered := true;
      SummaRacs.Refresh;
      summaracs.Repaint;
      ActiveControl := Summaracs;
      exit;
    end;

  with Fuggony do
    begin
      Left := 1;
      Top := 50;
      Visible := True;
    end;

   for i := 0 to 149 do
     begin
       _bevetel[i] := 0;
       _kiadas[i] := 0;
     end;
    OsszesPanel.Caption := '';
    _sirodadarab := 0;
    if rterm.Checked then
      begin
        _evindex := tolevCombo.itemindex;
        _hoindex := tolHonevCombo.Itemindex;
      end else
      begin
        _evIndex := Evcombo.itemindex;
        _hoIndex := HonevCombo.ItemIndex;
      end;

   _aktev := _maiev-2+_evindex;
   _akthonap := 1 + _hoindex;

   _farok := nulele(_aktev-2000)+nulele(_akthonap);
   _aktTablaNev := 'TRADE'+_farok;

   _aktnap := 0;
   if ROneMonth.Checked then
     begin
       _napindex := Napcombo.itemindex;
       _aktnap := _napindex + 1;
       _aktdatums := inttostr(_aktev)+'.'+nulele(_akthonap)+'.'+nulele(_aktnap);
     end;

   if RTerm.Checked then
     begin
       _tolnap := 1+TolnapCOmbo.ItemIndex;
       _ignapindex := IgnapCOmbo.ItemIndex;
       _ignaps := IgnapCOmbo.items[_ignapIndex];
       _ignap := strtoint(_ignaps);
       _toldatums := inttostr(_aktev)+'.'+nulele(_akthonap)+'.'+nulele(_tolnap);
       _igdatums := inttostr(_aktev)+'.'+nulele(_akthonap)+'.'+nulele(_ignap);
     end;

   _aktirodaszam := 0;
   if ROneOffice.Checked then
     begin
       _valtoindex := Valtocombo.itemindex;
       _aktirodaszam := Irodaszamok[_valtoindex];
     end;

   _aktertektarszam := 0;
   if ROneValueStock.Checked then
     begin
       _etarIndex := Etarcombo.itemindex;
       _aktertektarszam := ertektarszamok[_etarindex];
     end;

  // ---------------------------------------------------------------------------

  TradeDbase.Connected := True;
  TradeTabla.close;
  TradeTabla.TableName := _aktTablaNev;
  if not TradeTabla.Exists then
    begin
      TradeQuery.close;
      TradeDbase.close;
      TempRacs.Visible := false;
      NoDataPanel.Visible := True;
      Fuggony.Visible := false;
      ActiveControl := KilepoGomb;
      exit;
    end;

  _pcs := 'SELECT * FROM ' + _akttablanev;
  _vanCond := False;

  if ROneOffice.Checked then
    begin
      _pcs := _pcs + _sorveg + 'WHERE (IRODASZAM='+ inttostr(_aktirodaszam)+')';
      _vanCond := True;
    end;

  if ROneMonth.Checked then
    begin
      if _vancond then _pcs := _pcs + ' AND ' else _pcs := _pcs +_sorveg+ 'WHERE ';
      _pcs := _pcs + '(DATUM='+chr(39)+_aktdatums+chr(39)+')';
      _vanCond := True;
    end;

  if RTerm.Checked then
    begin
      if _vancond then _pcs := _pcs + ' AND ' else _pcs := _pcs +_sorveg+ 'WHERE ';
      _pcs := _pcs + '((DATUM>='+chr(39)+_toldatums+chr(39)+') AND (DATUM<='+chr(39)+_igDatums+chr(39)+'))';
      _vancond := True;
    end;


  if ROneValueStock.Checked then
    begin
      if _vancond then _pcs := _pcs + ' AND ' else _pcs := _pcs+_sorveg + 'WHERE ';
      _pcs := _pcs + '(ERTEKTAR=' + inttostr(_aktertektarszam)+')';
      _vanCond := True;
    end;

  if RPhoneFill.Checked then
    begin
      if _vancond then _pcs := _pcs + ' AND ' else _pcs := _pcs+_sorveg + 'WHERE ';
      _pcs := _pcs + '(TIPUS='+chr(39)+'T'+chr(39)+')';
       _vanCond := True;
    end;

  if RCarLicense.Checked then
    begin
      if _vancond then _pcs := _pcs + ' AND ' else _pcs := _pcs+_sorveg + 'WHERE ';
      _pcs := _pcs + '(TIPUS='+chr(39)+'M'+chr(39)+')';
       _vanCond := True;
    end;

  if RPaying.Checked then
    begin
      if _vancond then _pcs := _pcs + ' AND ' else _pcs := _pcs+_sorveg + 'WHERE ';
      _pcs := _pcs + '(TIPUS='+chr(39)+'F'+chr(39)+')';
       _vanCond := True;
    end;

  TempSource.Enabled := false;

  Tradedbase.connected := True;
  if tradeTranz.InTransaction then Tradetranz.Commit;
  with TradeQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      TradeQuery.close;
      TradeDbase.close;
      TempRacs.Visible := false;
      NodataPanel.Visible := True;
      Fuggony.Visible := false;
      ActiveControl := Kilepogomb;
      exit;
    end;
  NodataPanel.visible := False;
  _sum := 0;
  while not TradeQuery.eof do
    begin
      _befiz := TradeQuery.FieldByName('BEFIZETVE').asInteger;
      _sum := _sum + _befiz;
      if RTerm.Checked then
        begin
          _aktiroda := TradeQuery.FieldByname('IRODASZAM').AsInteger;
          _cikkszam := TradeQuery.FieldByName('CIKKSZAM').asInteger;
          _xx := getSumirodass(_aktiroda);
          if _cikkszam>0 then _bevetel[_xx] := _bevetel[_xx] + _befiz
          else _kiadas[_xx] := _kiadas[_xx] + _befiz;
        end;
      TradeQuery.next;
    end;
  TradeQuery.First;
  (*
  if RTerm.Checked then
    begin
      TermSummaDisplay;
      exit;
    end;


  Fuggony.Visible := false;
  TempSource.Enabled := true;
  TempRacs.Visible := true;
  OsszesPanel.Caption := Forintform(_sum)+' Ft';
end;

*)

function TForm1.Nulele(_int: integer): string;

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;

procedure TForm1.HONEVCOMBOChange(Sender: TObject);
begin
  if ROneMonth.Checked then
    begin
 //     EgyhonapValtozott;
      Exit;
    end;
 // RacsDisplay;
end;

procedure TForm1.RONEMONTHClick(Sender: TObject);
begin
  TermTakaro.visible := True;
 
end;



procedure TForm1.EVCOMBOChange(Sender: TObject);
begin
  if ROneMonth.Checked then
    begin
   //   EgyhonapValtozott;
      Exit;
    end;
//  RacsDisplay;
end;

procedure TForm1.RTOTALMONTHClick(Sender: TObject);
begin
  FuggonyLe;
end;

procedure TForm1.RONEOFFICEClick(Sender: TObject);
begin
  FuggonyLe;
  Valtocombo.Enabled := true;
  Valtocombo.ItemIndex := 1;
  Egyenleggomb.enabled := True;
  Etarcombo.Text := '';
  Etarcombo.Enabled := false;
  RAllValueStock.Checked := True;
  ActiveControl := KijelzesGomb;
end;

procedure TForm1.VALTOCOMBOChange(Sender: TObject);
var _vindex: integer;
begin
  if summaPanel.Visible then
    begin
      _vindex := Valtocombo.ItemIndex;
      _kertirodaszam := Irodaszamok[_vIndex];
      EgyenlegGombclick(Nil);
      Exit;
    end;

  Fuggonyle;
  ActiveControl := KijelzesGomb;
end;

procedure TForm1.RALLOFFICESClick(Sender: TObject);
begin
  Fuggonyle;
  Egyenleggomb.Enabled := False;
  Etarbox.Enabled := true;
  Valtocombo.Text := '';
  Valtocombo.Enabled := false;
  ActiveControl := KijelzesGomb;
end;

procedure TForm1.RONEVALUESTOCKClick(Sender: TObject);
begin
  Fuggonyle;
  RallOffices.Checked := True;
  Etarcombo.Enabled := True;
  Etarcombo.itemindex := 0;
  ActiveControl := Kijelzesgomb;
end;

procedure TForm1.RALLVALUESTOCKClick(Sender: TObject);
begin
  Fuggonyle;
  RallOffices.Checked := True;
  Groupbox2.Enabled := True;
  Etarcombo.Enabled := False;
  Activecontrol := KijelzesGomb;
end;

procedure TForm1.ETARCOMBOChange(Sender: TObject);
begin
  FuggonyLe;
end;

procedure TForm1.RPHONEFILLClick(Sender: TObject);
begin
  FuggonyLe;
end;

FUNCTION Tform1.Forintform(_int: integer): string;

var _wLen,_p1: integer;

begin
  result := inttostr(_int);
  if _int<1000 then exit;
  _wlen := length(result);
  if _int>=1000000 then
    begin
      _p1 := _wlen-6;
      result := leftstr(result,_p1)+','+midstr(result,_p1+1,3)+','+midstr(result,_p1+4,3);
      exit;
    end;
  _p1 := _wlen-3;
  result := leftstr(result,_p1)+','+midstr(result,_p1+1,3);
end;


// =============================================================================
                procedure TForm1.RTERMClick(Sender: TObject);
// =============================================================================

var i: integer;

begin
   if _aktnap<1 then _aktnap := 1;
   IghonapPanel.Caption := _aktHonapNev;

   Evcombo.Items.clear;
   for i := 0 to 2 do Evcombo.Items.Add(inttostr(_maiev+i-2));
   Evcombo.ItemIndex := 2;

   HonapCombo.Items.Clear;
   for i := 1 to 12 do HonapCombo.Items.add(_honapNev[i]);
   HonapCombo.ItemIndex := _akthonap-1;

   Tolnaptoltes;
   IgalapraAllitas;
   TermTakaro.Visible := false;

   ActiveControl := KijelzesGomb;
end;

// =============================================================================
                         procedure TForm1.TolnapToltes;
// =============================================================================

begin
  _havinapok := DaysinaMonth(_aktev,_akthonap);

  TolnapCombo.Clear;

  _tt := 0;
   while _tt<_havinapok do
    begin
      TolnapCombo.items.Add(inttostr(_tt+1));
      inc(_tt);
    end;
  if _aktnap>_havinapok then _aktnap := _havinapok;
  Tolnapcombo.itemindex := (_aktnap-1);
end;

// =============================================================================
                       procedure TForm1.IgalapraAllitas;
// =============================================================================



begin
  _ignap   := _aktnap;
  IgEvPanel.Caption := inttostr(_aktev);
  IgHonapPanel.Caption := _honapNev[_akthonap];
  _tt := _aktnap;
  igNapCombo.clear;
  while _tt<=_havinapok do
    begin
      ignapCombo.Items.Add(inttostr(_tt));
      inc(_tt);
    end;
 ignapcombo.ItemIndex := 0;
end;


procedure TForm1.TOLEVCOMBOChange(Sender: TObject);

begin
   if summaPanel.Visible then
      begin
        _kertev := _maiev-2+evcombo.ItemIndex;
        EgyenlegGombclick(Nil);
        Exit;
      end;

   Fuggonyle;
   _evIndex  := Evcombo.itemindex;
   _aktev    := _maiev-2+_evindex;
   _hoIndex  := HonapCombo.ItemIndex;
   _akthonap := 1 + _hoindex;

   TolnapToltes;
   IgalapraAllitas;

   ActiveControl := KijelzesGomb;
   Kijelzesgomb.SetFocus;
end;

procedure TForm1.IGNAPCOMBOChange(Sender: TObject);
begin
  Fuggonyle;
end;

procedure TForm1.TOLNAPCOMBOChange(Sender: TObject);
begin
  _aktnap := 1+tolnapcombo.ItemIndex;
  ignapcombo.Clear;
  _tt := _aktnap;
  while _tt<=_havinapok do
    begin
      ignapcombo.Items.add(inttostr(_tt));
      inc(_tt);
    end;
  Ignapcombo.ItemIndex := 0;
 // RacsDisplay;
end;



 function TForm1.GetSumirodass(_irsz: integer): integer;
var _y: integer;

begin
  result := 0;
  if _sirodadarab=0 then
    begin
      _sirss[0] := _irsz;
      _sirodadarab := 1;
      exit;
    end;

  _y := 0;
  while _y<_sirodadarab do
    begin
      if _sirss[_y]= _irsz then
        begin
          result := _y;
          Exit;
        end;
      inc(_y);
    end;
  _sirss[_sirodadarab] := _irsz;
  result := _sirodadarab;
  inc(_sirodadarab);
end;

(*
procedure TForm1.TermSummaDisplay;

var _qq,_irsz,_bev,_kia: integer;

begin
  SummaDbase.connected := true;
  if SummaTranz.InTransaction then SummaTranz.commit;
  SummaTranz.StartTransaction;
  with SummaQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add('DELETE FROM OSSZESITO');
      ExecSql;
    end;
  SummaTranz.Commit;
  SummaDbase.close;

  // -----------------------------------------------

  if _sirodadarab>0 then
    begin
      Summadbase.Connected := true;
      SummaTranz.StartTransaction;
      _qq := 0;
      while _qq<_sirodaDarab do
        begin
          _irsz := _sirss[_qq];
          _bev := _bevetel[_qq];
          _kia := _kiadas[_qq];
          _pcs := 'INSERT INTO OSSZESITO (IRODASZAM,BEVETEL,KIADAS)'+_sorveg;
          _pcs := _pcs + 'VALUES ('+inttostr(_irsz) + ',';
          _pcs := _pcs + inttostr(_bev)+','+inttostr(_kia)+')';
          with Summaquery do
            begin
              Close;
              sql.Clear;
              sql.Add(_pcs);
              ExecSql;
            end;
          inc(_qq);
        end;
      SummaTranz.commit;
      SummaDbase.close;
      Summadbase.connected := true;
      _pcs := 'SELECT * FROM OSSZESITO'+_sorveg;
      _pcs := _pcs + 'ORDER BY IRODASZAM';
      with SummaQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          First;
        end;
    end;

  Summasource.Enabled := true;
  with SummaPanel do
    begin
      Top :=152;
      Left := 8;
      Visible := True;
    end;
  Fuggony.Visible := False;
  activeControl := SummaRacs;
end;
*)


procedure TForm1.MULTEVIGOMBClick(Sender: TObject);
begin
  _egyaktev := _maiev-1;
  Haviegyenleg.ShowModal;
end;

procedure TForm1.EZEVIGOMBClick(Sender: TObject);
begin
  _egyaktev := _maiev;
  Haviegyenleg.ShowModal;
end;

procedure TForm1.EGYENLEGGOMBClick(Sender: TObject);
begin
 Balfuggony.Visible := True;
 JobbFuggony.Visible := True;
 EtarTakaro.Visible := True;

 Havitabla.close;
 _Tablanev := 'HAVI'+inttostr(_kertev);
 _indexnev := 'X'+inttostr(_kertev)+'2';
 Havitabla.TableName := _tablanev;
 HaviDbase.Connected := true;
 if not Havitabla.Exists then
   begin
     ShowMessage('HIÁNYZIK A KÉRT ÉV EGYENLEGE');
     EXIT;
   end;
 Havitabla.IndexName := _indexnev;
 Havitabla.Filtered := false;
 if roneoffice.checked then
   begin
     Havitabla.Filter := 'IRODASZAM='+inttostr(_kertirodaszam);
     Havitabla.Filtered := True;
   end;

 (*
 if ROneOffice.Checked then
   begin
     _valtoindex := Valtocombo.itemindex;
     _aktirodaszam := Irodaszamok[_valtoindex];
     _filter := 'IRODASZAM='+inttostr(_aktirodaszam);
     Havitabla.Filter := _filter;
     Havitabla.Filtered := true;
   end;
  *)

  Havitabla.Open;
  Havitabla.First;

  with summaPanel do
    begin
      Top := 117;
      Left:= 8;
      Visible := True;
    end;
  Activecontrol := Summaracs;
end;

procedure TForm1.visszagombClick(Sender: TObject);
begin
  Havitabla.close;
  HaviDbase.close;
  Summapanel.Visible := False;
  Balfuggony.visible := false;
  JobbFuggony.Visible := False;
  EtarTakaro.Visible := False;
  Rallvaluestock.checked := true;
 
end;

function TForm1.ScanIrodaNev(_isz: integer):string;

Var _y: integer;

begin
  _y := 0;
  result := ' ';
  while _y<_irodaDarab do
    begin
      if irodaszamok[_y] = _isz then
        begin
          result := irodanevek[_y];
          exit;
        end;
      inc(_y);
    end;
end;


function TForm1.ScanErtektar(_isz: integer):integer;

var _y: integer;

begin
  _y := 0;
  result := 0;
  while _y<_irodaDarab do
    begin
      if irodaszamok[_y] = _isz then
        begin
          result := Ertektarak[_y];
          exit;
        end;
      inc(_y);
    end;
end;

procedure TForm1.FuggonyLE;

begin
  Egyenleggomb.Enabled := False;
  with Fuggony do
    begin
      Caption := '';
      Left := 8;
      Top := 153;
      Visible := True;
    end;
end;


function TForm1.Setfilter: string;

var _vindex,_eindex: integer;

begin

  _kertev := _maiev - 2 + evcombo.itemindex;
  _kertho := 1 + honapcombo.itemindex;
  if Rterm.Checked then
    begin
      _kerttolnap := 1 + tolnapcombo.itemindex;
      _kertignap  := _kerttolnap + ignapcombo.itemindex;
      _kerttoldatum := inttostr(_kertev)+'.'+nulele(_kertho)+'.'+nulele(_kerttolnap);
      _kertigdatum := leftstr(_kerttoldatum,8)+nulele(_kertignap);
    end;



  result := '';
  if ROneMonth.checked then
        result := '(DATUM LIKE '+chr(39)+inttostr(_kertev)+'.'+nulele(_kertho)+'%'+chr(39)+')'
    else
        result := '((DATUM>='+chr(39)+_kerttoldatum+chr(39)+') AND (DATUM<='+CHR(39)+_kertigdatum+chr(39)+'))';

  if rOneOffice.checked then
    begin
      _vindex := Valtocombo.ItemIndex;
      _kertirodaszam := Irodaszamok[_vIndex];
      result := result + ' AND (IRODASZAM='+inttostr(_kertirodaszam)+')';
    end;

  if rOneValueStock.checked then
    begin
      _eindex := Etarcombo.itemindex;
      _kertertektar := Ertektarszamok[_eindex];
      result := result + ' AND (ERTEKTAR='+inttostr(_kertertektar)+')'; 
    end;

  if summapanel.visible then exit;
  if RallItems.checked then exit;

  if rPhoneFill.checked then result := result + ' AND (TIPUS='+chr(39)+'T'+chr(39)+')';
  if rCarLicense.checked then result := result + ' AND (TIPUS='+chr(39)+'M'+chr(39)+')';
  if rPaying.checked then result := result + ' AND (TIPUS='+chr(39)+'F'+chr(39)+')';
end;


procedure TForm1.KIJELZESGOMBClick(Sender: TObject);
var _be : integer;
begin
   if ROneOffice.checked then
                EgyenlegGomb.Enabled := True;

   _pcs := 'SELECT * FROM STRADE';

   Fuggony.Caption := 'AZ ADATOK KALKULÁLÁSA FOLYAMATBAN ...';
   Fuggony.Repaint;
   _filter := Setfilter;

   if _filter<>'' then _pcs := _pcs + _sorveg + 'WHERE '+ _filter;

   Tempdbase.Connected := True;
   with TempQuery do
     begin
       Close;
       Sql.clear;
       Sql.Add(_pcs);
       Open;
       First;
     end;
   _sum := 0;
   while not TempQuery.Eof do
     begin
       _be := Tempquery.fieldbyName('BEFIZETVE').asInteger;
       _tipus := Tempquery.FieldByName('TIPUS').asString;
       if _tipus='F' then _be := trunc((-1)*_be);
       _sum := _sum + _be;
       Tempquery.Next;
     end;
   Tempquery.First;
   OsszesPanel.Caption := Forintform(_sum)+' Ft';
   Osszespanel.Repaint;
   Fuggony.Visible := False;
   ActiveControl := TempRacs;
end;

end.
