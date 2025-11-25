unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Strutils,
  Dialogs, StdCtrls, Buttons, ExtCtrls, DB, DBTables, Grids, DBGrids,
  ComCtrls, IBDatabase, IBCustomDataSet, IBTable, IBQuery, jpeg, printers;

type

  TLISTAFORM = class(TForm)

    BizonylatPanel      : TPanel;
    EvStatiPanel        : TPanel;
    FocimPanel          : TPanel;
    MenuPanel           : TPanel;
    PTForgPanel         : TPanel;
    TemaPanel           : TPanel;
    TolPanel            : TPanel;
    InfoPanel           : TPanel;
    IgPanel             : TPanel;
    TemaFocimPanel      : TPanel;

    AdvetVisszaGomb     : TBitBtn;
    BizonylatOKGomb     : TBitBtn;
    CancelGomb          : TBitBtn;
    ForgStatGomb        : TBitBtn;
    NyomtatoGomb        : TBitBtn;
    StatiGomb           : TBitBtn;
    HaviTabloGomb       : TBitBtn;
    KedvezmenyGomb      : TBitBtn;
    PillanatnyiGomb     : TBitBtn;
    PenztariForgalomGomb: TBitBtn;
    PrForgKilepGomb     : TBitBtn;
    PTForgNyomGomb      : TBitBtn;
    BitBtn2             : TBitBtn;
    DekadGomb           : TBitBtn;
    BitBtn3             : TBitBtn;
    PTForgVisszaGomb    : TBitBtn;
    TRBGomb             : TBitBtn;
    VisszaGomb          : TBitBtn;

    Label1              : TLabel;
    FocimLabel          : TLabel;
    Label5              : TLabel;
    Label6              : TLabel;
    TurelemLabel        : TLabel;
    Label2              : TLabel;
    Label3              : TLabel;

    BizonylatSource     : TDataSource;
    EVStatiSource       : TDataSource;
    PtarForgSource      : TDataSource;

    BizonylatRacs       : TDBGrid;
    EvStatiRacs         : TDBGrid;
    PTForgRacs          : TDBGrid;

    Shape1              : TShape;
    Shape2              : TShape;
    Shape3              : TShape;

    Image1              : TImage;

    PenztarForgalomQuery: TIBQuery;
    TempQuery           : TIBQuery;
    AdVetQuery          : TIBQuery;
    ValutaQuery         : TIBQuery;
    ValdataQuery        : TIBQuery;
    ValQuery            : TIBQuery;

    PenztarForgalomDbase: TIBDatabase;
    AdVetDBase          : TIBDatabase;
    TempDbase           : TIBDatabase;
    ValutaDbase         : TIBDatabase;
    ValdataDbase        : TIBDatabase;
    ValDbase            : TIBDatabase;

    AdVetTranz          : TIBTransaction;
    PenztarForgalomTranz: TIBTransaction;
    TempTranz           : TIBTransaction;
    ValutaTranz         : TIBTransaction;
    ValdataTranz        : TIBTransaction;
    ValTranz            : TIBTransaction;

    Csik                : TProgressBar;

    PenztarForgalomQueryAtvettBankjegy  : TIntegerField;
    PenztarForgalomQueryAtadottBankjegy : TIntegerField;
    AdVetQueryEladottBankjegy           : TIntegerField;
    AdVetQueryEladottForintErtek        : TIntegerField;
    AdVetQueryVettBankjegy              : TIntegerField;
    AdVetQueryVettForintErtek           : TIntegerField;

    PenztarForgalomQueryValutanem       : TIBStringField;
    PenztarForgalomQueryPenztarkod      : TIBStringField;
    AdVetQUeryValutanem                 : TIBStringField;
    ADVetQueryTipus                     : TIBStringField;
    VALUTATABLA: TIBTable;
    VALTABLA: TIBTable;

   // ---------------------------------------------------------

    procedure AdatDumpList;
    procedure AdvetVisszaGombClick(Sender: TObject);
    procedure AlapadatBeolvasas;
    procedure BitBtn2Click(Sender: TObject);
    procedure BizListFejlec;
    procedure BizonylatLista;
    procedure BizonylatListaPrint(Sender: TObject);
    procedure BizVisszaGombClick(Sender: TObject);
    procedure BlokkFocimIro;
    procedure DekadLista;
    procedure ForgstatLista;
    procedure FormActivate(Sender: TObject);
    procedure GetKertdatumAdatok;
    procedure HavitabloDisplay;
    procedure KezdijLista;
    procedure KozepreIr(_szoveg: string);
    procedure Menube;
    procedure MenugombClick(Sender: TObject);
    procedure PenztarForgalomLista;
    procedure PtForglist;
    procedure PTForgVisszaGombClick(Sender: TObject);
    procedure TextKiiro;
    procedure ValParancs(_ukaz: string);
    procedure VonalHuzo;
    procedure MaiforgOsszesito;
    procedure STATIGOMBClick(Sender: TObject);

    function Elokieg(_s: string; _hh: byte): string;
    function ForintForm(_osszeg:integer):string;
    function FtForm(_num: integer): string;
    function FormKiir(_n: integer): string;
    function Nulele(_b: byte): string;
    function Scandnem(_dn: string): byte;
    function ScanPtarKod(_ps: string): byte;
    function WinExecAndWait32(Path: PChar; Visibility: Word): integer;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ListaForm: TListaForm;

  _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                                   'CZK','DKK','EUR','GBP','HRK','HUF','ILS',
                                   'JPY','MXN','NOK','NZD','PLN','RON','RSD',
                                   'RUB','SEK','THB','TRY','UAH','USD');

  _penztarsor: array[1..30] of string;
  _ptdb: byte;

  _atvett,_atadott: array[1..30,1..27] of integer;
  _eladott,_vett,_eladottft,_vettft: array[1..27] of integer;


  _temacim : array[1..4] of string = ('BIZONYLATOK LISTÁJA','PÉNZFORGALMI LISTA',
                         'TRB FORGALOM LISTÁJA','VÉTEL-ELADÁS LISTÁJA');

  _LFile: textfile;

  _aktdnem,
  _aktpenztarosnev,
  _aktprosid,
  _aktptkod,
  _bfTablanev,
  _bizonylatszam,
  _btTablanev,
  _cegnev,
  _datum,
  _farok,
  _fcim,
  _homepenztarkod,
  _homepenztarnev,
  _homepenztarcim,
  _igstring,
  _kftnev,
  _megnyitottnap,
  _mess,
  _pcs,
  _penztar,
  _penztarkod,
  _tipus,
  _tolstring: string;

  _sorveg: string = chr(13)+chr(10);

  _height,
  _ignap,
  _kertev,
  _kertho,
  _left,
  _tolnap,
  _top,
  _width: word;

  _aktpt,
  _gepfunkcio,
  _homepenztarszam,
  _pp,
  _printer,
  _vss,
  _xx: byte;

  _csakmai,
  _eztrb   : Boolean;

  _aktarfolyam,
  _aktatadott,
  _aktatvett,
  _aktbankjegy,
  _akteladott,
  _akteladottft,
  _aktertek,
  _aktvett,
  _aktvettft,
  _arfolyam,
  _atadva,
  _atveve,
  _bankjegy,
  _cc,
  _code,
  _eladBjegy,
  _ftertek,
  _joidoszak,
  _oke,
  _rcc,
  _recno,
  _vettbjegy: integer;


function forgalomdekad: integer; stdcall; external 'c:\valuta\bin\dekad.dll' name 'forgalomdekad';
function idoszakrutin: integer; stdcall; external 'c:\valuta\bin\idoszak.dll' name 'idoszakrutin';
function kezelesidijdekad: integer; stdcall; external 'c:\valuta\bin\kezdek.dll' name 'kezelesidijdekad';
function napikonyvelorutin: integer; stdcall; external 'c:\valuta\bin\napkonyv.dll' name 'napikonyvelorutin';
function napikezdijrutin: integer; stdcall; external 'c:\valuta\bin\napikezd.dll' name 'napikezdijrutin';
function pillanatnyikeszlet: integer; stdcall; external 'c:\valuta\bin\pillkesz.dll' name 'pillanatnyikeszlet';


function kulonfelelistak: integer; stdcall;

implementation

{$R *.dfm}


function kulonfelelistak: integer; stdcall;

begin
  ListaForm := TListaform.create(Nil);
  result := Listaform.showModal;
  Listaform.Free;
end;


// =============================================================================
                 procedure TListaForm.FormActivate(Sender: TObject);
// =============================================================================

begin
  _width  := Screen.Monitors[0].Width;
  _height := Screen.Monitors[0].Height;

  _top    := round((_height-768)/2);
  _left   := round((_width-1024)/2);

  Top     := _top;
  Left    := _left;
  width   := 1024;
  Height  := 768;

  TemaPanel.Visible       := False;
  BizonylatPanel.Visible  := False;
  PtforgPanel.Visible     := False;
  EvstatiPanel.Visible    := False;
  Csik.Visible            := False;
  InfoPanel.Visible       := False;
  TurelemLabel.Visible    := False;
  Havitablogomb.Enabled   := false;
  KedvezmenyGomb.Enabled  := False;
  PillanatnyiGomb.Enabled := False;

  Alapadatbeolvasas;

  if _gepfunkcio=2 then
    begin
      Havitablogomb.Enabled   := true;
      Pillanatnyigomb.Enabled := True;
      KedvezmenyGomb.Enabled  := True;
    end;

  Menube;
end;

// =============================================================================
                          procedure TListaform.Menube;
// =============================================================================

begin
  Csik.Visible      := False;
  TemaPanel.Visible := False;
  Infopanel.Visible := False;

  Image1.repaint;

  with MenuPanel do
    begin
      Top     := 24;
      Left    := 24;
      Visible := True;
    end;
  Activecontrol := BizonylatokGomb;
end;


// =============================================================================
            procedure TListaForm.MenugombClick(Sender: TObject);
// =============================================================================

VAR _HOOKE: INTEGER;
    _menupont: byte;
    _aktfocim: string;

begin
  MenuPanel.Visible := False;
  _menupont := TBitbtn(sender).Tag;
  if _menupont<5 then
    begin
      _hooke := idoszakrutin;
      if _hooke=2 then
        begin
          Menube;
          exit;
        end;
        Image1.Repaint;
      GetKertdatumAdatok;

      _aktfocim              := _temacim[_menupont];

      TolPanel.caption       := _tolstring;
      IgPanel.Caption        := _igstring;
      TemaFocimPanel.Caption := _aktfocim;

      Tolpanel.repaint;
      igpanel.repaint;
      temafocimpanel.repaint;

      with Temapanel do
        begin
          top     := 16;
          Left    := 8;
          Visible := True;
          repaint;
        end;
    end;

  _csakmai := False;
  if _tolstring=_megnyitottnap then _csakmai := True;

  _ezTrb := false;
  case _menupont of
     1: Bizonylatlista;
     2: PenztarforgalomLista;

     3: begin
          _eztrb := true;
          PenztarforgalomLista;
        end;

     4: ForgstatLista;
     5: HaviTabloDisplay;
     6: begin
          pillanatnyikeszlet;
          Menube;
        end;

     7: Menube;
   //  7: KedvezmenyForm.Showmodal;

     8: dekadlista;
     9: kezdijlista;
    10: begin
          Modalresult := 1;
          exit;
        end;
  end;
end;


// =============================================================================
                  procedure TLIstaForm.BizonylatLista;
// =============================================================================

begin
  _pcs := 'DELETE FROM VTEMP';
  ValParancs(_pcs);

  infoPanel.Visible := true;
  InfoPanel.repaint;

  _farok := midstr(_tolstring,3,2)+midstr(_tolstring,6,2);

  _btTablanev := 'BT' + _farok;
  _pcs := 'SELECT * FROM ' + _btTablanev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM>=' + chr(39) + _tolstring + chr(39) + ')';
  _pcs := _pcs + ' AND (DATUM<=' + chr(39) + _igstring + chr(39) + ')';
  _pcs := _pcs + ' AND (STORNO=1)';

  Valdatadbase.connected := true;
  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  Csik.Max := _recno;;
  Csik.Visible := True;

  _cc := 0;
  while not ValdataQuery.eof do
    begin
      inc(_cc);
      Csik.Position := _cc;
      with ValdataQuery do
        begin
          _bizonylatszam := FieldByName('BIZONYLATSZAM').asstring;
          _aktdnem := FieldByName('VALUTANEM').asString;
          _bankjegy := FieldByName('BANKJEGY').asInteger;
          _datum := FieldByNAme('DATUM').asstring;
          _ftertek := FieldByNAme('FORINTERTEK').asInteger;
          _arfolyam := FieldByName('ARFOLYAM').asInteger;
        end;

      _tipus := leftstr(_bizonylatszam,1);
      _pcs := 'INSERT INTO VTEMP (DATUM,TIPUS,VALUTANEM,ARFOLYAM,BANKJEGY,';
      _pcs := _pcs + 'FORINTERTEK,BIZONYLATSZAM)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _datum + chr(39) + ',';
      _pcs := _pcs + chr(39) + _tipus + chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + inttostr(_arfolyam) + ',';
      _pcs := _pcs + inttostr(_bankjegy) + ',';
      _pcs := _pcs + inttostr(_ftertek) + ',';
      _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ')';
      ValParancs(_pcs);
      ValdataQuery.next;
    end;
  ValdataQuery.close;
  ValdataDbase.close;

  // ---------------------------------------------------------------------------

  IF (_igstring=_megnyitottnap) then
    begin
      _pcs := 'SELECT * FROM BLOKKTETEL' + _sorveg;
      _pcs := _pcs + 'WHERE (DATUM>=' + chr(39) + _tolstring + chr(39) + ')';
      _pcs := _pcs + ' AND (DATUM<=' + chr(39) + _igstring + chr(39) + ')';
      _pcs := _pcs + ' AND (STORNO=1)';

      valutadbase.connected := true;
      with ValutaQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          First;
        end;

      while not ValutaQuery.eof do
        begin
          with ValutaQuery do
            begin
              _bizonylatszam := FieldByName('BIZONYLATSZAM').asstring;
              _aktdnem := FieldByName('VALUTANEM').asString;
              _bankjegy := FieldByName('BANKJEGY').asInteger;
              _datum := FieldByNAme('DATUM').asstring;
              _ftertek := FieldByNAme('FORINTERTEK').asInteger;
              _arfolyam := FieldByName('ARFOLYAM').asInteger;
            end;

          _tipus := leftstr(_bizonylatszam,1);

          _pcs := 'INSERT INTO VTEMP (DATUM,TIPUS,VALUTANEM,ARFOLYAM,';
          _pcs := _pcs + 'BANKJEGY,FORINTERTEK)'+_sorveg;
          _pcs := _pcs + 'VALUES (' + chr(39) + _datum + chr(39) + ',';
          _pcs := _pcs + chr(39) + _tipus + chr(39) + ',';
          _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
          _pcs := _pcs + inttostr(_arfolyam) + ',';
          _pcs := _pcs + inttostr(_bankjegy) + ',';
          _pcs := _pcs + inttostr(_ftertek) + ')';
          ValParancs(_pcs);
          ValutaQuery.next;
        end;

      ValutaQuery.close;
      ValutaDbase.close;
    end;

  // ---------------------------------------------------------------------------

   Tempdbase.connected := true;
   with TempQuery do
     begin
       Close;
       sql.clear;
       sql.add('SELECT * FROM VTEMP');
       Open;
       First;
       _recno := recno;
     end;

   if _recno=0 then
     begin
       Tempquery.close;
       Tempdbase.close;
       Showmessage('NINCS BIZONYLAT A KÉRT IDÖSZAKBAN');
       Menube;
       exit;
     end;

  with TempQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      First;
    end;

  Infopanel.Visible := False;
  Csik.visible := false;
  Image1.repaint;

  BizonylatSource.Enabled := true;

  FocimLabel.Caption := 'KIADOTT BIZONYLATOK '+_TOLSTRING+' ÉS '+_IGSTRING+'KÖZÖTT';
  with BizonylatPanel do
    begin
      Top := 240;
      Left := 510;
      Visible := True;
    end;

  Bizonylatracs.SetFocus;
end;

// =============================================================================
           procedure TLISTAFORM.BIZVISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Bizonylatsource.Enabled := False;

  TempQuery.close;
  TempDbase.close;
  BizonylatPanel.Visible := False;

  Image1.repaint;
  Menube;
end;

// =============================================================================
              procedure TLISTAFORM.BizonylatListaPrint(Sender: TObject);
// =============================================================================

begin
  BlokkfocimIro;
  KozepreIr('A KIADOTT BIZONYLATOK LISTÁJA');
  KozepreIr(_tolstring+' éS '+_IGSTRING);
  vonalhuzo;

  _pcs := 'SELECT * FROM VTEMP WHERE TIPUS=' + chr(39)+'V'+chr(39);
  with TempQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  KozepreIr('VALUTA VÁSÁRLÁSOK BIZONYLATAI');
  BizListFejlec;
  AdatDumpList;

// ---------------------------------------------------------

  _pcs := 'SELECT * FROM VTEMP WHERE TIPUS=' + chr(39)+'E'+chr(39);
  with TempQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  KozepreIr('VALUTA ELADÁSOK BIZONYLATAI');
  BizListFejlec;
  AdatDumpList;

// ---------------------------------------------------------

   _pcs := 'SELECT * FROM VTEMP WHERE TIPUS=' + chr(39)+'U'+chr(39);
  with TempQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  KozepreIr('PENZTARI ATVETELEK BIZONYLATAI');
  BizListFejlec;
  AdatDumpList;

// ---------------------------------------------------------

  _pcs := 'SELECT * FROM VTEMP WHERE TIPUS=' + chr(39)+'F'+chr(39);
  with TempQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  KozepreIr('PENZTARI ATADASOK BIZONYLATAI');
  BizListFejlec;
  AdatDumpList;

  writeLn(_LFile,_sorveg+_sorveg+_sorveg);
  CloseFile(_LFile);
  Textkiiro;

  _pcs := 'SELECT * FROM VTEMP';
  with TempQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  ActiveControl := BizonylatRacs;
end;

// =============================================================================
                         procedure TListaForm.AdatDumpList;
// =============================================================================

var _bjegys,_akterts,_naps: string;

begin
  TempQuery.First;
  while not TempQuery.Eof do
    begin
      with TempQuery do
        begin
          _datum := FieldByName('DATUM').asstring;
          _bizonylatszam := FieldByName('BIZONYLATSZAM').asstring;
          _aktdnem := FieldByName('VALUTANEM').AsString;
          _aktarfolyam := FieldByName('ARFOLYAM').asInteger;
          _aktBankJegy := FieldByName('BANKJEGY').AsInteger;
          _aktertek := FieldByNAme('FORINTERTEK').AsInteger;

        end;

      _naps := midstr(_datum,9,2);
      _bjegys := trim(ForintForm(_aktbankjegy));
      _akterts := trim(ForintForm(_aktertek));
      _bjegys := Elokieg(_bjegys,9);
      _akterts := elokieg(_akterts,11);
      write(_Lfile,_naps+' '+_bizonylatszam +' '+_aktdnem + ' ');
      write(_Lfile,_bjegys+' ');

      writeLN(_Lfile,_akterts);
      TempQuery.Next;
    end;
  VonalHuzo;
  writeLn(_LFile,_sorveg);
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                  procedure TLIstaForm.PenztarForgalomLista;
// =============================================================================

var i,j: byte;


begin
  _pcs := 'DELETE FROM PENZTARFORGALOM';
  ValParancs(_pcs);

  infoPanel.Visible := true;
  InfoPanel.repaint;

  _farok := midstr(_tolstring,3,2)+midstr(_tolstring,6,2);

  for i := 1 to 30 do
    begin
      for j := 1 to 27 do
        begin
          _atvett[i,j] := 0;
          _atadott[i,j]:= 0;
        end;
     end;
   _ptdb := 0;

  _recno := 0;
  if _csakmai then
    begin
      _bfTablanev := 'BLOKKFEJ';
      _btTablaNev := 'BLOKKTETEL';
      Valutadbase.close;
      Valutatabla.Close;
      Valutadbase.Connected := true;
      ValutaTabla.TableName := 'BLOKKFEJ';
      ValutaTabla.Open;
      _recno := ValutaTabla.RecNo;
      Valutatabla.Close;
      Valutadbase.close;
    end;

  if _recno>0 then
    begin
      maiForgOsszesito;
      exit;
    end;

  _bfTablanev := 'BF' + _farok;
  _btTablanev := 'BT' + _farok;

  _pcs := 'SELECT FEJ.*,TET.*' + _sorveg;
  _pcs := _pcs + 'FROM '+ _bfTablanev+' FEJ JOIN ' + _btTablanev+' TET' + _sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM' + _sorveg;
  _pcs := _pcs + 'WHERE (FEJ.DATUM>=' +chr(39) + _tolstring + chr(39) +') AND (';
  _pcs := _pcs + 'FEJ.STORNO=1) AND (FEJ.DATUM<=' + chr(39);
  _pcs := _pcs + _igstring + chr(39) + ')';

  Valdatadbase.connected := True;
  with ValdataQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  Csik.Max := _recno;
  Csik.Visible := true;

  _cc := 0;
  while not Valdataquery.eof do
    begin
      inc(_cc);
      Csik.Position := _cc;

      _tipus := ValdataQuery.FieldByName('TIPUS').asString;
      if (_tipus='F') or (_tipus='U') THEN
        begin
          _penztarkod := trim(ValdataQuery.FieldByName('TARSPENZTARKOD').asString);
          if (_eztrb=True) and (_penztarkod<>'TRB') then
            begin
              ValdataQuery.next;
              continue;
            end;

          _pp := ScanPtarKod(_penztarkod);
          _aktdnem := ValdataQuery.FieldbyNAme('VALUTANEM').asstring;
          _aktbankjegy := ValdataQuery.FieldbyName('BANKJEGY').asInteger;
          _xx := Scandnem(_aktdnem);
          if _tipus='U' then _atvett[_pp,_xx] := _atvett[_pp,_xx] + _aktbankjegy
          else _atadott[_pp,_xx] := _atadott[_pp,_xx] + _aktbankjegy;
        end;
      ValdataQuery.next;
    end;
  ValdataQuery.close;
  ValdataDbase.close;

  // ---------------------------------------------------------------------------

  _pcs := 'SELECT FEJ.*,TET.*' + _sorveg;
  _pcs := _pcs + 'FROM BLOKKFEJ FEJ JOIN BLOKKTETEL TET' + _sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM' + _sorveg;
  _pcs := _pcs + 'WHERE (FEJ.DATUM<' +chr(39) + _tolstring + chr(39) +') AND (';
  _pcs := _pcs + 'FEJ.STORNO=1) AND (FEJ.DATUM<=' + chr(39);
  _pcs := _pcs + _igstring + chr(39) + ')';

  Valutadbase.connected := True;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  while not Valutaquery.eof do
    begin
      _tipus := ValutaQuery.FieldByName('TIPUS').asString;
      if (_tipus='F') or (_tipus='U') THEN
        begin
          _penztarkod := trim(ValutaQuery.FieldByName('TARSPENZTARKOD').asString);
          if (_eztrb=True) and (_penztarkod<>'TRB') then
            begin
              ValutaQuery.next;
              Continue;
            end;

          _pp := ScanPtarKod(_penztarkod);
          _aktdnem := ValutaQuery.FieldbyNAme('VALUTANEM').asstring;
          _aktbankjegy := ValutaQuery.FieldbyName('BANKJEGY').asInteger;
          _xx := Scandnem(_aktdnem);
          if _tipus='U' then _atvett[_pp,_xx] := _atvett[_pp,_xx] + _aktbankjegy
          else _atadott[_pp,_xx] := _atadott[_pp,_xx] + _aktbankjegy;
        end;
      ValutaQuery.next;
    end;
  ValutaQuery.close;
  ValutaDbase.close;

// =============== Penztarforgalom rögzitése ===================================

  if _ptdb=0 then
    begin
      _mess := 'PÉNZTÁRI FORGALOM A KÉRT IDÖSZAKBAN';
      if _eztrb then _mess := 'TRB ' + _mess;
      ShowMessage('NEM VOLT '+_mess);
      Menube;
      exit;
    end;

  _aktpt := 1;
  while _aktpt<=_ptdb do
    begin
      _aktptkod := _Penztarsor[_aktpt];
      _vss := 1;
      while _vss<=27 do
        begin
          _aktdnem := _dnem[_vss];
          _aktatvett := _atvett[_aktpt,_vss];
          _aktatadott:= _atadott[_aktpt,_vss];
          if (_aktatvett>0) or (_aktatadott>0) then
             begin
                _pcs := 'INSERT INTO PENZTARFORGALOM (PENZTARKOD,VALUTANEM,';
                _pcs := _pcs + 'ATVETTBANKJEGY,ATADOTTBANKJEGY)' + _sorveg;
                _pcs := _pcs + 'VALUES (' + chr(39)+ _aktptkod + chr(39)+',';
                _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
                _pcs := _pcs + inttostr(_aktatvett)+','+inttostr(_aktatadott)+')';
                ValParancs(_pcs);
              end;
          inc(_vss);
        end;
      inc(_aktpt);
    end;

  Infopanel.Visible := False;
  Csik.Visible := False;

  _fcim := 'PÉNZTÁRAK KÖZÖTT FORGALOM ';
  if _ezTRB then _fcim := 'TRB FORGALOM ';
  Focimpanel.caption := _FCIM;

  with PtforgPanel do
    begin
      top := 180;
      Left := 300;
      Visible := True;
    end;

  _pcs := 'SELECT * FROM PENZTARFORGALOM';

  PenztarForgalomdbase.Connected := true;
  with PenztarForgalomQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  PtarForgSource.Enabled := True;
  PtforgRacs.SetFocus;

end;


// =============================================================================
                procedure TLIstaForm.MaiforgOsszesito;
// =============================================================================


begin
  _pcs := 'SELECT FEJ.*,TET.*' + _sorveg;
  _pcs := _pcs + 'FROM BLOKKFEJ FEJ JOIN BLOKKTETEL TET' + _sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM' + _sorveg;
  _pcs := _pcs + 'WHERE (FEJ.DATUM='+chr(39) + _MEGNYITOTTNAP + chr(39) +')';
  _pcs := _pcs + ' AND (FEJ.STORNO=1)';

  Valutadbase.connected := True;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  while not Valutaquery.eof do
    begin
      _tipus := ValutaQuery.FieldByName('TIPUS').asString;
      if (_tipus='F') or (_tipus='U') THEN
        begin
          _penztarkod := trim(ValutaQuery.FieldByName('TARSPENZTARKOD').asString);
          if (_eztrb=True) and (_penztarkod<>'TRB') then
            begin
              ValutaQuery.next;
              Continue;
            end;

          _pp := ScanPtarKod(_penztarkod);
          _aktdnem := ValutaQuery.FieldbyNAme('VALUTANEM').asstring;
          _aktbankjegy := ValutaQuery.FieldbyName('BANKJEGY').asInteger;
          _xx := Scandnem(_aktdnem);
          if _tipus='U' then _atvett[_pp,_xx] := _atvett[_pp,_xx] + _aktbankjegy
          else _atadott[_pp,_xx] := _atadott[_pp,_xx] + _aktbankjegy;
        end;
      ValutaQuery.next;
    end;
  ValutaQuery.close;
  ValutaDbase.close;

// =============== Penztarforgalom rögzitése ===================================

  if _ptdb=0 then
    begin
      _mess := 'PÉNZTÁRI FORGALOM A KÉRT IDÖSZAKBAN';
      if _eztrb then _mess := 'TRB ' + _mess;
      ShowMessage('NEM VOLT '+_mess);
      Menube;
      exit;
    end;

  _aktpt := 1;
  while _aktpt<=_ptdb do
    begin
      _aktptkod := _Penztarsor[_aktpt];
      _vss := 1;
      while _vss<=27 do
        begin
          _aktdnem := _dnem[_vss];
          _aktatvett := _atvett[_aktpt,_vss];
          _aktatadott:= _atadott[_aktpt,_vss];
          if (_aktatvett>0) or (_aktatadott>0) then
             begin
                _pcs := 'INSERT INTO PENZTARFORGALOM (PENZTARKOD,VALUTANEM,';
                _pcs := _pcs + 'ATVETTBANKJEGY,ATADOTTBANKJEGY)' + _sorveg;
                _pcs := _pcs + 'VALUES (' + chr(39)+ _aktptkod + chr(39)+',';
                _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
                _pcs := _pcs + inttostr(_aktatvett)+','+inttostr(_aktatadott)+')';
                ValParancs(_pcs);
              end;
          inc(_vss);
        end;
      inc(_aktpt);
    end;

  Infopanel.Visible := False;
  Csik.Visible := False;

  _fcim := 'PÉNZTÁRAK KÖZÖTT FORGALOM ';
  if _ezTRB then _fcim := 'TRB FORGALOM ';
  Focimpanel.caption := _FCIM;

  with PtforgPanel do
    begin
      top := 180;
      Left := 300;
      Visible := True;
    end;

  _pcs := 'SELECT * FROM PENZTARFORGALOM';

  PenztarForgalomdbase.Connected := true;
  with PenztarForgalomQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  PtarForgSource.Enabled := True;
  PtforgRacs.SetFocus;

end;









// =============================================================================
            procedure TLISTAFORM.PTFORGVISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  PtarForgSource.Enabled := False;

  PenztarForgalomQuery.close;
  PenztarForgalomDbase.close;
  PtForgPanel.Visible := False;

  Image1.repaint;
  Menube;
end;

// =============================================================================
                            procedure TlistaForm.PtForglist;
// =============================================================================

var _lsor: string;

begin
  BlokkFoCimIro;
  KozepreIr(_fcim);
  KozepreIr(_tolstring+' es '+_igstring+' kozott');
  VonalHuzo;

  writeLn(_Lfile,'Penztar   Dnem      Atveve      Atadva');
  VonalHuzo;

  PenztarforgalomQuery.first;
  while not PenzTarforgalomQuery.eof do
    begin
      with PenzTarforgalomQuery do
        begin
          _penztar := FieldByName('PENZTARKOD').asString;
          _aktdnem := FieldByName('VALUTANEM').asstring;
           _atveve := FieldByName('ATVETTBANKJEGY').asInteger;
           _atadva := FieldByName('ATADOTTBANKJEGY').asInteger;
             _lsor := Elokieg(_penztar,5)+'     '+_aktdnem+' '+FormKiir(_atveve)+' '+FormKiir(_atadva);
          writeLn(_Lfile,_Lsor);
          Next;
        end;
    end;
  VonalHuzo;
  writeLn(_LFile,_sorveg+_sorveg+_sorveg);
  Closefile(_LFile);
  TextKiiro;
end;

// =============================================================================
         function TListaForm.Elokieg(_s: string; _hh: byte): string;
// =============================================================================

begin
  _s := trim(_s);
  while length(_s)<_hh do _s := ' ' + _s;
  result := _s;
end;

// =============================================================================
             function TListaForm.ForintForm(_osszeg:integer):string;
// =============================================================================

var _slen,_pp: integer;
    _ejel : string;

begin
  Result := '-';

  if _osszeg=0 then exit;

  _ejel := '';

  if _osszeg<0 then
    begin
      _ejel := '-';
      _osszeg := abs(_osszeg);
    end;

  Result := intTostr(_osszeg);

  if _osszeg<1000 then
    begin
      Result := _ejel + Result;
      Exit;
    end;

  _sLen := length(Result);
  if _osszeg>999999 then
    begin
      _pp := _sLen-5;
      Result := _ejel + midStr(Result,1,_pp-1)+','+midStr(Result,_pp,3)+','+midStr(Result,_pp+3,3);
      Exit;
    end;

  _pp := _sLen-2;
  Result := _ejel + midStr(result,1,_pp-1)+','+midStr(result,_pp,3);
end;

// =============================================================================
                            procedure TLISTAFORM.Vonalhuzo;
// =============================================================================

begin
  WriteLn(_LFile,dupestring('-',40));
end;

// =============================================================================
                     procedure TListaForm.KozepreIr(_szoveg: string);
// =============================================================================

var _oo: integer;

begin
  _szoveg := trim(_szoveg);
  _oo := trunc((40-length(_szoveg))/2);
  writeLn(_LFile,dupestring(' ',_oo)+_szoveg);
end;

// =============================================================================
                         procedure TListaForm.FORGSTATLista;
// =============================================================================

var i: byte;

begin
  infoPanel.Visible := true;
  InfoPanel.repaint;

  for i := 1 to 27 do
    begin
      _eladott[i] := 0;
      _eladottft[i] := 0;
      _vett[i] := 0;
      _vettft[i] := 0;
    end;

  _farok := midstr(_tolstring,3,2)+midstr(_tolstring,6,2);
  _btTablaNev := 'BT'+_farok;

  _pcs := 'SELECT * FROM ' + _btTablaNev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM>=' + chr(39)+_tolstring+chr(39)+')';
  _pcs := _pcs + ' AND (DATUM<=' + chr(39) + _igstring + chr(39) + ')';
  _pcs := _pcs + ' AND (STORNO=1)';

  ValdataDbase.connected := true;
  with ValdataQuery do
    begin
      close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  Csik.Max := _recno;
  Csik.Visible := True;

  _cc := 0;
  while not ValdataQuery.eof do
    begin
      inc(_cc);
      Csik.Position := _cc;
      with ValdataQuery do
        begin
          _aktdnem := FieldByName('VALUTANEM').asString;
          _bizonylatszam := FieldbyName('BIZONYLATSZAM').asString;
          _aktbankjegy := FieldbyNAme('BANKJEGY').asInteger;
          _aktertek := FieldbyName('FORINTERTEK').asInteger;
        end;

      _tipus := leftstr(_bizonylatszam,1);
      if (_tipus='V') or (_tipus='E') then
        begin
          _xx := scandnem(_aktdnem);
          if _tipus='V' then
            begin
              _vett[_xx] := _vett[_xx] + _aktbankjegy;
              _vettft[_xx] := _vettft[_xx] + _aktertek;
            end else
            begin
              _eladott[_xx] := _eladott[_xx] + _aktbankjegy;
              _eladottft[_xx] := _eladottft[_xx] + _aktertek;
            end;
        end;
      ValdataQuery.next;
    end;
  Valdatadbase.close;

  // -------------------------------------------------------------

  if _igstring=_megnyitottnap then
    begin
      _pcs := 'SELECT * FROM BLOKKTETEL' + _sorveg;
      _pcs := _pcs + 'WHERE (DATUM>=' + chr(39)+_tolstring+chr(39)+')';
      _pcs := _pcs + ' AND (DATUM<=' + chr(39) + _igstring + chr(39) + ')';
      _pcs := _pcs + ' AND (STORNO=1)';

      Valutadbase.Connected := true;
      with ValutaQuery do
        begin
          close;
          sql.clear;
          Sql.add(_pcs);
          Open;
        end;

      while not ValutaQuery.eof do
        begin
          with ValutaQuery do
            begin
              _aktdnem := FieldByName('VALUTANEM').asString;
              _bizonylatszam := FieldbyName('BIZONYLATSZAM').asString;
              _aktbankjegy := FieldbyNAme('BANKJEGY').asInteger;
              _aktertek := FieldbyName('FORINTERTEK').asInteger;
            end;

          _tipus := leftstr(_bizonylatszam,1);
          if (_tipus='V') or (_tipus='E') then
            begin
              _xx := scandnem(_aktdnem);
              if _tipus='V' then
                begin
                  _vett[_xx] := _vett[_xx] + _aktbankjegy;
                  _vettft[_xx] := _vettft[_xx] + _aktertek;
                end else
                begin
                  _eladott[_xx] := _eladott[_xx] + _aktbankjegy;
                  _eladottft[_xx] := _eladottft[_xx] + _aktertek;
                end;
            end;
          ValutaQuery.next;
        end;
      Valutadbase.close;
    end;

  _pcs := 'DELETE FROM EVISTATISZTIKA';
  ValParancs(_pcs);

  _vss := 1;
  while _vss<=27 do
    begin
      _aktdnem := _dnem[_vss];
      if _aktdnem='HUF' then
        begin
          inc(_vss);
          Continue;
        end;

      _aktvett    := _vett[_vss];
      _akteladott := _eladott[_vss];

      _aktvettFt    := _vettFT[_vss];
      _akteladottFt := _eladottFt[_vss];

      if (_aktvett>0) or (_akteladott>0) then
        begin
          _pcs := 'INSERT INTO EVISTATISZTIKA (VALUTANEM,ELADOTTBANKJEGY,';
          _PCS := _pcs + 'ELADOTTFORINTERTEK,VETTBANKJEGY,VETTFORINTERTEK)'+_SORVEG;
          _pcs := _pcs + 'VALUES (' + chr(39) + _aktdnem + chr(39) +',';
          _pcs := _pcs + inttostr(_akteladott)+','+inttostr(_akteladottft)+',';
          _pcs := _pcs + inttostr(_aktvett)+','+inttostr(_aktvettft) + ')';
          Valparancs(_pcs);
        end;
      inc(_vss);
    end;


  ValDbase.Connected := true;
  with ValTabla do
    begin
      Close;
      Tablename := 'EVISTATISZTIKA';
      Open;
      first;
      Refresh;
      _aktdnem := FieldByName('VALUTANEM').asString;
    end;

  evstatisource.Enabled := true;

  with EvstatiPanel do
    begin
      top := 140;
      Left := 350;
      Visible := True;
    end;

  Statigomb.Enabled := true;
  EvstatiRacs.SetFocus;
end;

// =============================================================================
            function TLISTAFORM.FormKiir(_n: integer): string;
// =============================================================================

var _ns: string;

begin
  _ns := Forintform(_n);
  result := elokieg(_ns,11);
end;

// =============================================================================
                         procedure TListaForm.BizListFejlec;
// =============================================================================

begin
  VonalHuzo;
  writeLN(_Lfile,'Nap Biz.lat Valuta Bankjegy Forint ertek');
  VonalHuzo;
end;

// =============================================================================
             procedure TLISTAFORM.HAVITabloDisplay;
// =============================================================================

var _tpath: string;
    _pacs: pchar;

begin
  _TPATH := 'c:\valuta\bin\tablo.exe';

  _pacs := addr(_tPath[1]);
  winexecandwait32(_pacs,sw_hide);
  Menube;
end;

// =============================================================================
                     procedure TLISTAFORM.DekadLista;
// =============================================================================

begin
  menupanel.Visible := false;
  if _gepfunkcio=2 then _oke := napikonyvelorutin
  else _oke := forgalomdekad;
  if _oke<>1 then Showmessage('SIKERTELEN FORGALOM NYOMTATÁS');
  Menube;
end;

// =============================================================================
                    procedure TListaForm.KezdijLista;
// =============================================================================

begin
  IF _gepfunkcio=2 then _oke := napikezdijrutin
  else _oke := kezelesidijdekad;
  if _oke<>1 then ShowMessage('SIKERTELEN KEZELÉSI DIJ LISTA NYOMTATÁS');
  Menube;
end;

// =============================================================================
                function TLISTAFORM.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
                    procedure TListaForm.GetKertdatumAdatok;
// =============================================================================

begin
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.Add('SELECT * FROM IDOSZAK');
      Open;
      _kertev := FieldbyName('KERTEV').asInteger;
      _kertho := FieldbyName('KERTHO').asInteger;
      _tolnap := FieldbyName('TOLNAP').asInteger;
      _ignap  := FieldbyName('IGNAP').asInteger;
      _tolstring := FieldbyName('TOLSTRING').asString;
      _igstring := FieldByName('IGSTRING').asString;
      Close;
    end;
  Valutadbase.close;
end;


// =============================================================================
                function TListaform.Scandnem(_dn: string): byte;
// =============================================================================

var _y: byte;

begin
  result := 0;
  _y := 1;
  while _y<=27 do
    begin
      if _dn=_dnem[_y] then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
            function TListaform.ScanPtarKod(_ps: string): byte;
// =============================================================================

var _y: byte;

begin
  if _ptdb=0 then
    begin
      _ptdb := 1;
      _penztarsor[1] := trim(_ps);
      result := 1;
      exit;
    end;

  _y := 1;
  while _y<=_ptdb do
    begin
      if _ps=_penztarsor[_y] then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
  inc(_ptdb);
  _penztarsor[_ptdb] := _ps;
  result := _ptdb;
end;

// =============================================================================
                procedure TListaform.ValParancs(_ukaz: string);
// =============================================================================

begin
  valDbase.connected := true;
  if valtranz.InTransaction then Valtranz.commit;
  Valtranz.StartTransaction;
  with Valquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Valtranz.Commit;
  Valdbase.close;
end;


// =============================================================================
              procedure TListaForm.Alapadatbeolvasas;
// =============================================================================

begin
  _pcs := 'SELECT * FROM VTEMP';
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      SQL.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap:= trim(FieldByName('MEGNYITOTTNAP').AsString);
      _aktpenztarosnev := trim(FieldByName('PENZTAROSNEV').AsString);
      _aktprosid := FieldByNAme('IDKOD').asString;
      _kftnev := trim(FieldByNAme('KFTNEV').AsString);
      _printer := FieldByNAme('PRINTER').asInteger;
      _gepfunkcio := FieldByName('GEPFUNKCIO').asInteger;
      Close;

      sql.Clear;
      Sql.Add('SELECT * FROM PENZTAR');
      Open;
      _homePenztarkod  := trim(FieldByNAme('PENZTARKOD').AsString);
      _homepenztarnev  := trim(FieldByname('PENZTARNEV').AsString);
      _homepenztarcim  := trim(FieldByName('PENZTARCIM').AsString);
      Close;
    end;
  Valutadbase.close;

  val(_homepenztarkod,_homepenztarszam,_code);
  if _homePenztarSzam<151 then
    begin
      _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';
    end else
    begin
      _cegnev := 'EXPRESSZ EKSZERHAZ ES MINIBANK KFT';
    end;  

  _farok := midstr(_megnyitottnap,3,2)+midstr(_megnyitottnap,6,2);

end;


// =============================================================================
   function TListaForm.WinExecAndWait32(Path: PChar; Visibility: Word): integer;
// =============================================================================

var Msg: TMsg;
    lpExitCode: cardinal;
    StartupInfo: TStartupInfo;
    ProcessInfo: TProcessInformation;

begin
  FillChar(StartupInfo, SizeOf(TStartupInfo), 0);
  with StartupInfo do
    begin
      cb := SizeOf(TStartupInfo);
      dwFlags := STARTF_USESHOWWINDOW or STARTF_FORCEONFEEDBACK;
      wShowWindow := visibility; {you could pass sw_show or sw_hide as parameter}
    end;

  if CreateProcess(nil, path, nil, nil, False, NORMAL_PRIORITY_CLASS,
                                      nil, nil, StartupInfo,ProcessInfo) then

    begin
      repeat
        while PeekMessage(Msg, 0, 0, 0, pm_Remove) do
          begin
            if Msg.Message = wm_Quit then Halt(Msg.WParam);
            TranslateMessage(Msg);
            DispatchMessage(Msg);
          end;

        GetExitCodeProcess(ProcessInfo.hProcess,lpExitCode);
      until lpExitCode <> Still_Active;

    with ProcessInfo do {not sure this is necessary but seen in in some code elsewhere}
      begin
        CloseHandle(hThread);
        CloseHandle(hProcess);
      end;

    Result := 0; {success}
  end else Result := GetLastError;
end;

// =============================================================================
                       procedure TLISTAFORM.BlokkFocimIro;
// =============================================================================

begin
  Assignfile(_LFile,'c:\valuta\aktlst.txt');
  rewrite(_LFile);

  vonalhuzo;
  KozepreIr(_cegnev);
  Kozepreir(_homepenztarkod+' '+_homepenztarnev);
  KozepreIr(_homePenztarcim);
  VonalHuzo;
end;

// =============================================================================
                            procedure TListaForm.TextKiiro;
// =============================================================================

var _mondat: string;
    _nyomtat,_olvas: textFile;

begin
  if _printer<>1 then AssignFile(_nyomtat,'LPT1:')
  else AssignPrn(_nyomtat);
  Rewrite(_nyomtat);
  AssignFile(_olvas,'c:\valuta\aktlst.txt');
  Reset(_olvas);

  while not eof(_olvas) do
    begin
      readln(_olvas,_mondat);
      writeln(_nyomtat,_mondat);
    end;
  System.closeFile(_nyomtat);
  System.CloseFile(_olvas);
end;


// =============================================================================
          procedure TLISTAFORM.ADVETVISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  evstatisource.Enabled := False;
  AdvetQuery.close;
  Advetdbase.close;
  evstatiPanel.Visible := False;
  Menube;
end;

// =============================================================================
           procedure TLISTAFORM.BitBtn2Click(Sender: TObject);
// =============================================================================

begin
  PtForglist;
end;

{

123456789012345678901234567890123456789
---------------------------------------
   2019.11.12 ÉS 2019.11.25 KÖZÖTTI
       VASAROLT VALUTAK LISTAJA
---------------------------------------
VALUTANEM     VALUTA       FORINTERTEK
---------------------------------------
   'AUD     123 456 789     123 456 789

---------------------------------------
         ELADOTT VALUTAK LISTAJA

}

// =============================================================================
            procedure TLISTAFORM.STATIGOMBClick(Sender: TObject);
// =============================================================================

var _y: byte;

begin
   Statigomb.Enabled := false;
   BlokkFocimiro;
   Kozepreir(_tolstring+ ' ÉS ' + _igstring + ' KÖZÖTTI');
   Kozepreir('VASAROLT VALUTAK LISTÁJA');
   VonalHuzo;
   writeLn(_LFile,'VALUTANEM     VALUTA       FORINTERTEK');
   VonalHuzo;

   _y := 1;
   while _y<=27 do
     begin
       _aktdnem := _dnem[_y];
       if _aktdnem='HUF' then
         begin
           inc(_y);
           continue;
         end;
       _aktvett := _vett[_y];
       _aktvettft := _vettft[_y];
       if _aktvett>0 then
         begin
           writeln(_LFile,'   '+_aktdnem+'     '+ftform(_aktvett)+'     '+ftform(_aktvettft));
         end;
       inc(_y);
     end;

   // ----------------------------------------------------------

   Vonalhuzo;
   Kozepreir('ELADOTT VALUTAK LISTÁJA');
   VonalHuzo;
   writeLn(_LFile,'VALUTANEM     VALUTA       FORINTERTEK');
   VonalHuzo;

   _y := 1;
   while _y<=27 do
     begin
       _aktdnem := _dnem[_y];
       if _aktdnem='HUF' then
         begin
           inc(_y);
           continue;
         end;
       _akteladott := _eladott[_y];
       _akteladottft := _eladottft[_y];
       if _akteladott>0 then
         begin
           writeln(_LFile,'   '+_aktdnem+'     '+ftform(_akteladott)+'     '+ftform(_akteladottft));
         end;
       inc(_y);
     end;
  VonalHuzo;

  writeLn(_LFile,_sorveg+_sorveg+_sorveg);
  CloseFile(_LFile);
  Textkiiro;

  ActiveControl := EvStatiracs;
end;


function TListaForm.FtForm(_num: integer): string;

var _ns: string;

begin
  _ns := fORINTFORM(_num);
  while length(_ns)<11 do _ns := ' '+_ns;
  result := _ns;
end;

end.




