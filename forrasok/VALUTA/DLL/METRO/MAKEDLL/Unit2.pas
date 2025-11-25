unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, DB, DBTables, StrUtils, DateUtils,
  IBDatabase, IBCustomDataSet, IBTable, IBQuery, printers, jpeg;

type
  TMETROFORM = class(TForm)

  BizDispVisszaGomb: TBitBtn;
       BizTalloGomb: TBitBtn;
          ElozoGomb: TBitBtn;
   FomenuKilepoGomb: TBitBtn;
       IIAtveszGomb: TBitBtn;
         IIAtadGomb: TBitBtn;
          KBackGomb: TBitBtn;
Keszletnyomtatogomb: TBitBtn;
   KisMenuKilepGomb: TBitBtn;
      KovetkezoGomb: TBitBtn;
          ListaGomb: TBitBtn;
      NyomtatasGomb: TBitBtn;
    PillKeszletGomb: TBitBtn;
         PTAtadGomb: TBitBtn;
       PTAtveszGomb: TBitBtn;
         StornoGomb: TBitBtn;
     SureStornoGomb: TBitBtn;
     SureCancelGomb: TBitBtn;
    TranzCancelGomb: TBitBtn;
       TranzOkeGomb: TBitBtn;
   VisszaCancelGomb: TBitBtn;
      VisszaOkeGomb: TBitBtn;
     VisszaTeroGomb: TBitBtn;
  VisszateritesGomb: TBitBtn;

     BizonylatPanel: TPanel;
 BizonylatSzamPanel: TPanel;
       BizszamPanel: TPanel;
         DatumPanel: TPanel;
     EllatmanyPanel: TPanel;
        FomenuPanel: TPanel;
         ForintEdit: TPanel;
      ForintKeszlet: TPanel;
       KisMenuPanel: TPanel;
    MegnevezesPanel: TPanel;
             Panel2: TPanel;
    PartnerNevPanel: TPanel;
       PartnerPanel: TPanel;
    PillKeszletCsik: TPanel;
   PillKeszletPanel: TPanel;
        StornoPanel: TPanel;
     StornoBizPanel: TPanel;
    StornoSurePanel: TPanel;
    TranzakcioPanel: TPanel;
      TranzNevPanel: TPanel;
      SzazalekPanel: TPanel;
     UgyfelnevPanel: TPanel;
     UgykezdijPanel: TPanel;
   UgykezelesiPanel: TPanel;
 VisszaTeritesPanel: TPanel;
VisszaTeritettPanel: TPanel;
         WafaKarton: TPanel;

           AfaEdit: TEdit;
        BruttoEdit: TEdit;
         HideEdit2: TEdit;
      ListHideEdit: TEdit;
      SzlaszamEdit: TEdit;

       AdveszLabel: TLabel;
       BigNumLabel: TLabel;
            Label1: TLabel;
            Label2: TLabel;
            Label3: TLabel;
            Label4: TLabel;
            Label5: TLabel;
            Label6: TLabel;
            Label7: TLabel;
            Label8: TLabel;
            Label9: TLabel;
           Label11: TLabel;
           Label12: TLabel;
           Label13: TLabel;
           Label14: TLabel;
           Label15: TLabel;
           Label16: TLabel;
           Label17: TLabel;
           Label18: TLabel;
           Label19: TLabel;
           Label20: TLabel;
           Label21: TLabel;
           Label22: TLabel;
           Label23: TLabel;
           Label24: TLabel;
           Label26: TLabel;
           Label27: TLabel;
           Label28: TLabel;
           Label29: TLabel;
           Label30: TLabel;
           Label31: TLabel;
           Label32: TLabel;
           Label33: TLabel;
           Label34: TLabel;
           Label35: TLabel;
           Label36: TLabel;
        STBizLabel: TLabel;
    StornoTipLabel: TLabel;

            Shape1: TShape;
            Shape2: TShape;
            Shape3: TShape;
            Shape4: TShape;
            Shape5: TShape;
            Shape6: TShape;
            Shape7: TShape;
            Shape8: TShape;
            Shape9: TShape;
           Shape10: TShape;
           Shape11: TShape;

      TallozoTabla: TIBTable;
      TallozoDbase: TIBDatabase;
      TallozoTranz: TIBTransaction;

       ValutaQuery: TIBQuery;
       ValutaDbase: TIBDatabase;
       ValutaTranz: TIBTransaction;
    TALLOZOQUERY: TIBQuery;
    CEGBEKEROPANEL: TPanel;
    Label25: TLabel;
    Label37: TLabel;
    NEVEDIT: TEdit;
    Label38: TLabel;
    CIMEDIT: TEdit;
    cegokegomb: TBitBtn;
    cegmegsemgomb: TBitBtn;
    uniosafagomb: TBitBtn;
    AFATIPUSPANEL: TPanel;
    UNIOSPANEL: TPanel;
    Shape12: TShape;
    Panel3: TPanel;
    Label10: TLabel;
    Label39: TLabel;
    KILEPO: TTimer;
    IBTable1: TIBTable;
    IBQuery1: TIBQuery;
    VALDATAQUERY: TIBQuery;
    VALDATADBASE: TIBDatabase;
    VALDATATRANZ: TIBTransaction;
    valdatatabla: TIBTable;
    bpanel: TPanel;
    Label40: TLabel;
    Image1: TImage;

// ----------------------------------------------

    procedure AfaTranzNyomtatas;
    procedure AfaTranzRegisztralas;
    procedure BizTalloGombClick(Sender: TObject);
    procedure BizTalloGombEnter(Sender: TObject);
    procedure BizTalloGombExit(Sender: TObject);
    procedure BizDispVisszaGombClick(Sender: TObject);
    procedure ElozoGombClick(Sender: TObject);
    procedure EscapeGombClick(Sender: TObject);
    procedure WuKeszletAllito(_btip: string; _vnem: string; _aktosszeg: integer);
    procedure Bizregiszter(_xbiz: string);
    procedure FejVonalHuzo;
    procedure GetWuKeszlet;
    function kerekito(_int: integer): integer;
    procedure Fomenu;
    procedure FomenuKilepoGombClick(Sender: TObject);
    procedure ForintEditClick(Sender: TObject);
    procedure ForintEditEnter(Sender: TObject);
    procedure ForintEditExit(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure GetaktwCeg;
    procedure VonalHuzo;
    procedure PlombaAdatBeolvasas;
    function GetWcegNev(_cnum: integer): string;
    procedure HideEdit2KeyPress(Sender: TObject; var Key: Char);
    procedure IIAtadGombClick(sender: TObject);
    procedure IIAtadGombEnter(Sender: TObject);
    procedure IIAtadGombExit(Sender: TObject);
    procedure KozepreIr(_szoveg: string);
    function Nulele(_b: integer;_hh: byte): string;
    procedure IIAtadGombMouseMove(Sender: TObject; Shift: TShiftState; X,
              Y: Integer);
    procedure IIAtVeszGombClick(sender: TObject);
    procedure kbackgombClick(Sender: TObject);
    procedure KeszletnyomtatogombKeyDown(Sender: TObject; var Key: Word;
              Shift: TShiftState);
    procedure Kismenu;
    procedure BlokkFocimIro(_kellnyitni: boolean);
    procedure KISMENUKILEPGOMBClick(Sender: TObject);
    procedure KovetkezoGombClick(Sender: TObject);
    procedure ListaGombClick(Sender: TObject);
    procedure ListHideEditKeyDown(Sender: TObject; var Key: Word;
              Shift: TShiftState);
    procedure MaiNapiLista;
    procedure MegsemGombClick(Sender: TObject);
    procedure NyomtatasGombClick(Sender: TObject);
    procedure PenzkeszletList(sender: TObject);
    procedure PillKeszletGombClick(Sender: TObject);
    procedure PtAtadGombClick(Sender: TObject);
    procedure PTAtveszGombClick(Sender: TObject);
    procedure StornoBizNyomtat;
    procedure StornoGombClick(Sender: TObject);
    procedure SurestornogombClick(Sender: TObject);
    procedure SzlaszamEditEnter(Sender: TObject);
    procedure SzlaszamEditExit(Sender: TObject);
    procedure SzlaszamEditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure TranzCancelGombClick(Sender: TObject);
    procedure TranzOkeGombClick(Sender: TObject);
    procedure AlapadatBeolvasas;
    procedure Ugyfeladatiro;
    procedure WaktualNullazo;
    procedure ValutaParancs(_ukaz: string);
    procedure VisszaOkeGombClick(Sender: TObject);
    procedure VisszaOkeGombEnter(Sender: TObject);
    procedure VisszaOkeGombExit(Sender: TObject);
    procedure VisszaOkeGombMouseMove(Sender: TObject; Shift: TShiftState;
              X, Y: Integer);
    procedure VisszaTeritesGombClick(Sender: TObject);
    function GetWuBizszam(_btip: string;_write: boolean): string;
    procedure VisszateroGombClick(Sender: TObject);
    procedure WafaKartonDisp;
    procedure WafaNyugtaIras;
    procedure wAfaRegisztralas;
    procedure StartNyomtatas;
    procedure GetWudata;
    procedure PlombaWrite;
    procedure WafaRekordRead;
    procedure CEGESAFAGOMBClick(Sender: TObject);
    procedure NEVEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CIMEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cegokegombClick(Sender: TObject);
    procedure cegmegsemgombClick(Sender: TObject);
    procedure uniosafagombClick(Sender: TObject);
    function Getidos: string;
    function ForintForm(_osszeg:integer):string;

    procedure HaventSomuch(_vanem:string);
    procedure Nodata;
    procedure KILEPOTimer(Sender: TObject);
    procedure GetKertdatumAdatok;



  private
    { Private declarations }
  public
    { Public declarations }
  end;

 // ------------- METRO AFA --------------------

var
     METROFORM: TMETROFORM;

    _menucim: array[1..7] of string;
    _szedit: array[1..3] of Tedit;

    _widon : char = #14;
    _widoff: char = #20;


    _aktGomb: TBitbtn;
    _ceges,_copyblokk,_stornozottblokk: boolean;

    _gepfunkcio,_stornojel,_bill: byte;
    _homePenztarkod,_megnyitottnap,_aktidos,_wTipus,_aktdnem: string;
    _szallitonev,_plombaszam,_bizonylattipus,_elojel,_datum: string;
    _bizonylatszam,_partnernev,_farok,_tolstring,_igstring: string;
    _jogihely,_joginev,_tipus,_kepvisnev,_anyjaneve,_beosztas: string;
    _szulhely,_szulido,_azonosito,_okmanytipus,_lakcim,_mezo: string;
    _megjegyzes,_cegnev,_homepenztarnev,_homepenztarcim: string;

    _kev,_kho: word;
    _euafa,_ugykezdijszazalek,_uniosAfa,_ugyfelszam,_code,_aktcegszam: integer;
    _afaErtek,_brutto,_ellatmany,_foegyseg,_ugyfoke,_sumafa,_tag: integer;
    _kifizetendo,_kifizetett,_ugykezdij,_wuosszeg,_recno: integer;
    _lastIndex,_menupont,_penztar,_aktszazalek,_eusukszazalek: integer;
    _jogiugyfelszam: integer;

    _aktTranz,_bizonylatKelte,_origBizonylat,_osszegString,_cegadoszam: string;
    _szamlaszam,_sorszam,_stornoBizonylat,_stornoKelte: string;
    _tranzTipus,_wafaTablaNev,_ccim,_pcs,_okiratszam,_tevekenyseg: string;
    _sorveg: string = chr(13)+chr(10);

    _top,_left,_height,_width: word;
    _kertev,_kertho,_tolnap,_ignap: word;
    _lFile: textfile;
    _printer,_kellmetroafa: byte;

    _sumusd,_sumhuf,_sumMetro,_sumTesco: integer;


function getwesternugyfel(_para: integer): integer; stdcall; external 'c:\valuta\bin\getwugyf.dll' name 'getwesternugyfel';
function getwesternceg: integer; stdcall; external 'c:\valuta\bin\getwceg.dll' name 'getwesternceg';
function getplombarutin: integer; stdcall; external 'c:\valuta\bin\getplomb.dll' name 'getplombarutin';
function idoszakrutin: integer; stdcall; external 'c:\valuta\bin\idoszak.dll' name 'idoszakrutin';
function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';

function metrorutin: integer; stdcall;


implementation

{$R *.dfm}

function metrorutin: integer; stdcall; 
begin
  MetroForm := TMetroForm.Create(Nil);
  result := Metroform.ShowModal;
  MetroForm.free;
end;  

// =============================================================================
                  procedure TMETROFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  _width := Screen.Monitors[0].Width;
  _height:= Screen.Monitors[0].Height;

  _top   := round((_height-660)/2);
  _left  := round((_width-1018)/2);

  Top    := _top;
  Left   := _left;

  Width  := 1018;
  Height := 660;

  VisszateritesPanel.Visible := False;
  VisszateroGomb.Visible     := False;
  KisMenuPanel.Visible       := False;
  PillkeszletPanel.Visible   := False;
  WafaKarton.Visible         := False;
  StornoSurePanel.Visible    := False;
  TRanzAkcioPanel.Visible    := False;
  CegbekeroPanel.Visible     := False;

  AlapadatBeolvasas;

  if (_gepfunkcio=1) AND (_kellMetroAfa=0) then
    begin
      Kilepo.enabled := True;
      exit;
    end;

  if _gepFunkcio=2 then
    begin
      IIAtadGomb.Enabled     := True;
      IIAtveszGomb.Enabled   := True;
      _aktgomb               := iiAtadgomb;
    end else
    begin
      IIAtadGomb.Enabled     := False;
      IIAtveszGomb.Enabled   := False;
      _aktgomb               := ptAtadGomb;
    end;

  _aktidos     := GetIdos;
  _szallitonev := '';
  _plombaszam  := '';

  _menucim[1] := 'PÉNZÁTADÁS INNOVA INVESTNEK';
  _menucim[2] := 'PÉNZÁTVÉTEL INNOVA INVESTTÖL';
  _menucim[3] := 'PÉNZÁTADÁS EGY ÁFAPÉNZTÁRNAK';
  _menucim[4] := 'PÉNZÁTVÉTEL EGY ÁFAPÉNZTÁRTÓL';
  _menucim[5] := 'ÁFA VISSZATÉRITÉS KÜLFÖLDI ÜGYFÉL RÉSZÉRE';
  _menucim[6] := 'CÉGNEK TÖRTÉNÕ ÁFA-KIFIZATÉS';
  _menucim[7] := 'EGYÉB LISTÁK, BIZONYLAT SZTORNÓ';

  _szedit[1] := SzlaszamEdit;
  _szedit[2] := Bruttoedit;
  _szedit[3] := AfaEdit;

  _wTipus := 'A';
  _aktdnem := 'HUF';

  Fomenu;
end;


procedure TMETROFORM.AlapadatBeolvasas;

begin
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _gepfunkcio := FieldByNAme('GEPFUNKCIO').asInteger;
      _megnyitottnap := TRIM(FieldByNAme('MEGNYITOTTNAP').asString);
      _printer := FieldByNAme('PRINTER').asInteger;
      _kellmetroafa := FieldByNAme('KELLMETROAFA').asInteger;
      _ugykezdijszazalek := FieldByName('UGYKEZDIJSZAZALEK').asInteger;
      Close;

      _cegnev := 'BEST CHANGE ZRT';
      _cegadoszam := '32313332-2-02';

      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _homepenztarkod := trim(FieldByNAme('PENZTARKOD').asString);
      _homepenztarnev := trim(FieldByNAme('PENZTARNEV').AsString);
      _homePenztarcim := trim(FieldByNAme('PENZTARCIM').AsString);
      Close;
    end;
  Valutadbase.close;
end;


// =============================================================================
                        procedure TMETROFORM.Fomenu;
// =============================================================================

begin
  with FomenUPanel do
    begin
      Top     := 125;
      Left    := 40;
      Visible := True;
    end;
  ActiveControl := _aktgomb;
end;


// =============================================================================
             procedure TMETROFORM.IIAtadGombClick(sender: TObject);
// =============================================================================

begin
   FomenuPanel.Visible := False;
   _aktgomb := iiAtadGomb;
   _bizonylattipus := 'AK';
         _aktTranz := '-K';
           _elojel := '-';
         _foegyseg := 3;
         _menuPont := 1;
  GetAktWCeg;
end;


// =============================================================================
            procedure TMETROFORM.IIAtVeszGombClick(sender: TObject);
// =============================================================================

begin
  FomenuPanel.Visible := False;
  _aktGomb := iiAtveszGomb;
  _bizonylatTipus := 'AB';
        _aktTranz := '+B';
          _elojel := '+';
        _foegyseg := 3;
        _menuPont := 2;
  GetAktWceg;
end;


// =============================================================================
                procedure TMETROFORM.PtAtadGombClick(Sender: TObject);
// =============================================================================

begin
  FomenuPanel.Visible := False;
  _aktgomb := ptAtadGomb;
  _bizonylatTipus := 'AK';
        _aktTranz := '-K';
          _elojel := '-';
        _foegyseg := 4;
        _menuPont := 3;
  GetAktWceg;
END;


// =============================================================================
            procedure TMETROFORM.PtAtveszGombClick(Sender: TObject);
// =============================================================================

begin
  FomenuPanel.Visible := False;
  _aktgomb := ptAtveszGomb;
  _bizonylatTipus := 'AB';
        _aktTranz := '+B';
        _foegyseg := 4;
          _elojel := '+';
        _menuPont := 4;
  GetAktWceg;
end;

// =============================================================================
          procedure TMETROFORM.VisszateritesGombClick(Sender: TObject);
// =============================================================================


begin
  FomenuPanel.Visible := False;
  _uniosafa := 1;
  _aktszazalek := _ugykezdijszazalek;
  afatipusPanel.Caption := 'ÁFA-VISSZATÉRITÉS';
  afatipusPanel.Font.Color := clNavy;
  _ceges := False;
  _aktgomb := VisszateritesGomb;
  _bizonylatTipus := 'AV';
        _foegyseg := 6;
        _aktTranz := '-V';
          _elojel := '-';
        _menuPont := 6;

  _ugyfelszam := getwesternugyfel(2);
  if _ugyfelszam=-1 then
    begin
      Fomenu;
      exit;
    end;
  Getwudata;  

  // A bekérõpanel alapra állítása:

  SzlaszamEdit.Clear;
    BruttoEdit.Clear;
       AfaEdit.Clear;

   SzazalekPanel.Caption := intTostr(_aktszazalek);

  UgykezDijPanel.Caption := '';
     BigNumLabel.Caption := '';

  // Bekéri az aktuális bizonylatszámot és kiirja

  _bizonylatszam := GetWuBizszam(_bizonylatTipus,False);
  BizonylatPanel.Caption := _bizonylatszam;

  // Kiirja az ügyfél nevét:
  UgyfelnevPanel.caption := _partnerNev;

  // végül Kiteszi a visszatérités bekérõpaneljét:
   with VisszaTeritesPanel do
     begin
           Top := 128;
          Left := 14;
       Visible := True;
     end;

   // Az elején nem lehet okézni
   VisszaOkeGomb.Enabled := False;

   // Az elsö bekérendõ adat  a számlaszám
   ActiveControl := SzlaszamEdit;
end;


// =============================================================================
                           procedure TMETROFORM.Kismenu;
// =============================================================================

begin
  FomenuPanel.Visible := False;
  _aktGomb := ListaGomb;
  with KismenuPanel do
    begin
       Top := 230;
      Left := 80;
      Visible := True;
    end;
  ActiveControl := BiztalloGomb;
end;


// =============================================================================
            procedure TMETROFORM.SzlaszamEditEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).color := clYellow;
end;

// =============================================================================
              procedure TMETROFORM.SzlaszamEditExit(Sender: TObject);
// =============================================================================

begin
  Tedit(Sender).Color := clWindow;
end;


// =============================================================================
    procedure TMETROFORM.SzlaszamEditKeyDown(Sender: TObject; var Key: Word;
                                             Shift: TShiftState);
// =============================================================================

var _tag: integer;


begin
  IF ORD(KEY)>47 then exit;

  _tag := TEdit(sender).Tag;
  if (ord(key)=13) or (ord(key)=40) then
    begin
      if _tag=2 then
        begin
          val(bruttoEdit.Text,_brutto,_code);
          if _code<>0 then _brutto := 0;
          if _brutto=0 then exit;

          _brutto := Kerekito(_brutto);
          BruttoEdit.Text := Inttostr(_brutto);
          Activecontrol := AfaEdit;
          Exit;
        end;

      if _tag=3 then
        begin

          val(AfaEdit.Text,_afaertek,_code);

          if _code<>0 then _afaertek := 0;
          if _afaertek=0 then exit;
          _afaertek := Kerekito(_afaertek);
          AfaEdit.Text := Inttostr(_afaErtek);
          if _uniosAfa=2 then _ugykezdij := trunc(_eusukszazalek*_afaertek/100)
          else _ugykezdij := trunc((_ugykezDijSzazalek*_afaErtek)/100);
          _ugykezdij := Kerekito(_ugykezdij);
          _kifizetendo := Kerekito((_afaErtek - _ugykezdij));

          UgykezdijPanel.Caption := ForintForm(_ugykezdij);
          BignumLabel.Caption := ForintForm(_kifizetendo)+' Ft';
          VisszaOkeGomb.Enabled := True;
          ActiveControl := VisszaOkeGomb;
          exit;
        end;

      inc(_tag);
      ActiveControl := _szedit[_tag];
    end;

  if ord(key)= 38 then
    begin
      dec(_tag);
      if _tag>0 then
        ActiveControl := _szedit[_tag];
    end;
end;


// =============================================================================
             procedure TMETROFORM.VisszaOkeGombClick(Sender: TObject);
// =============================================================================

//                LEHET REGISZTRÁLNI A VISSZATÉRITÉST
//               -------------------------------------

begin
  _szamlaszam := SzlaszamEdit.Text;

  Val(Bruttoedit.Text,_brutto,_code);
  if _code<>0 then _brutto := 0;
  if _brutto=0 then
    begin
      visszaterogombclick(Nil);
      exit;
    end;

  Val(afaEdit.Text,_afaErtek,_code);

  if _code<>0 then _afaErtek := 0;

  if _afaErtek=0 then
    begin
      visszaterogombclick(Nil);
      exit;
    end;

  _wuosszeg := _kifizetendo;

  GetWuKeszlet;
  if _wuOsszeg>_sumafa then
    begin
      HaventSomuch('FORINT');
      ModalResult := 2;
      Exit;
    end;

  // ------------ Most már tényleg könyvelhetö ---------------------------------

  WafaRegisztralas;
  WafaNyugtaIras;

  {
  with visszateroGomb do
    begin
      top := 540;
      left := 270;
      Visible := True;
    end;
  ActiveControl := VisszateroGomb;
  }
  Visszaterogombclick(Nil);
end;

// =============================================================================
                  procedure TMETROFORM.WafaRegisztralas;
// =============================================================================


begin
  _ugykezdij := trunc((_ugykezdijszazalek*_afaertek)/100);
  _bizonylatszam := GetWuBizszam(_bizonylatTipus,True);
  _aktidos := GetIdos;

  _pcs := 'INSERT INTO METROAFAMOZGAS (FOEGYSEGSZAM,UGYFELSZAM,UNIOSAFA,DATUM,IDO,SORSZAM,';
  _pcs := _pcs + 'SZAMLASZAM,BRUTTOOSSZEG,AFAOSSZEG,KEZELESISZAZALEK,';
  _pcs := _pcs + 'UGYKEZELESIDIJ,KIFIZETETTOSSZEG,TRANZAKCIOTIPUS,STORNO)'+_sorveg;

  _pcs := _pcs + 'VALUES (6,'+inttostr(_ugyfelszam)+',';
  if _uniosafa=2 then _pcs := _pcs + '2,' else _pcs := _pcs + '1,';
  _pcs := _pcs + chr(39) + _megnyitottnap+chr(39)+',';
  _pcs := _pcs + chr(39) + _aktidos + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39)+',';
  _pcs := _pcs + chr(39) + _szamlaszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_brutto) + ',';
  _pcs := _pcs + inttostr(_afaertek) + ',';
  _pcs := _pcs + inttostr(_aktszazalek)+',';
  _pcs := _pcs + inttostr(_ugykezdij)+',';
  _pcs := _pcs + inttostr(_kifizetendo)+','+chr(39)+'-V'+chr(39)+',1)';


  ValutaParancs(_pcs);
  WukeszletAllito(_bizonylatTipus,'HUF',_kifizetendo);

  Bizregiszter(_bizonylatszam);


end;


// =============================================================================
                      procedure TMETROFORM.FejVonalHuzo;
// =============================================================================

begin
  if (_stornojel>1) then
    begin
      Writeln(_LFile,'--------- '+ 'Stornozott bizonylat'+'---------');
      Exit;
    end;

  if _copyBlokk then
    begin
      writeLn(_LFile,'------------ '+  'Bizonylat masolat'+'--------');
      exit;
    end;
  VonalHuzo;
end;

procedure TMetroForm.Vonalhuzo;

begin
  writeLn(_LFile,dupestring('-',39));
end;


// =============================================================================
             procedure TMETROFORM.VISSZATEROGOMBClick(Sender: TObject);
// =============================================================================

begin
  WaktualNullazo;
  VisszateritesPanel.Visible := False;
  VisszaTeroGomb.Visible := False;
  Fomenu;
end;

// =============================================================================
                              procedure TMETROFORM.GetaktWceg;
// =============================================================================

begin
   FomenuPanel.Visible := False;
   if _menupont<3 then
     begin
       _partnerNev := 'INNOVA INVEST';
       _aktcegszam := 0;
     end else
     begin
       _aktcegszam := getwesternceg;
       if _aktcegszam=-1 then
         begin
           Fomenu;
           exit;
         end;
       _partnernev := GetWcegNev(_aktcegszam);
     end;

  TranznevPanel.Caption := _menucim[_menuPont];
  PartnerPanel.Caption := _partnernev;
  _BizonylatSzam := GetWuBizszam(_bizonylattipus,False);
  BizSzamPanel.Caption := _bizonylatSzam;

  if _elojel='+' then AdveszLabel.Caption := 'ÁTVETT FORINT:'
  else AdveszLabel.Caption := 'ÁTADOTT FORINT';

  _bizonylatKelte := _megnyitottnap;
  Hideedit2.Top := 1+ forintedit.top;
  _osszegstring := '';
  _wuosszeg := 0;
   ForintEdit.Caption := '';
   with TranzakcioPanel do
     begin
       top := 200;
       Left := 60;
       Visible := True;
     end;
   TranzOkeGomb.Enabled := False;
   Activecontrol := HideEdit2;

end;


// =============================================================================
           function TMetroForm.GetWcegNev(_cnum: integer): string;
// =============================================================================

begin
  Result := '?';

  _pcs := 'SELECT * FROM WUAFACEGEK'+ _sorveg;
  _pcs := _pcs + 'WHERE CEGSZAM='+inttostr(_cnum);

  ValutaDbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  if _Recno>0 then result := ValutaQuery.FieldByName('CEGNEV').asString;
  ValutaQuery.close;
  Valutadbase.close;
end;



// =============================================================================
      procedure TMETROFORM.HIDEEDIT2KeyPress(Sender: TObject; var Key: Char);
// =============================================================================

var _LL: integer;

begin
  _bill := ord(key);
  if _bill =13 then
    begin
      if _wuosszeg>0 then
        begin
          TranzOkeGomb.Enabled := True;
          ActiveControl := TranzOkeGomb;
        end
      else ActiveControl := TRanzCancelGomb;
      Exit;
    end;

  if _bill=27 then
    begin
      TranzakcioPanel.visible := False;
      Fomenu;
      exit;
    end;

   if (_bill>47) and (_bill<58) then
     begin
       _osszegstring := _osszegstring+chr(_bill);
       _wuosszeg := strtoint(_osszegstring);
       ForintEdit.Caption := ForintForm(_wuosszeg);
       exit
     end;

   if _bill=8 then
     begin
       if _osszegstring ='' then exit;
       _LL := length(_osszegstring);
       if _LL = 1 then
         begin
           _osszegstring := '';
           ForintEdit.Caption := '';
           Exit;
         end;
       dec(_ll);
       _osszegstring := leftstr(_osszegstring,_LL);
       _wuosszeg := StrToInt(_osszegstring);
       ForintEdit.Caption := ForintForm(_wuosszeg);
       exit;
     end;

end;


// =============================================================================
              procedure TMETROFORM.TranzOkeGombClick(Sender: TObject);
// =============================================================================

var _plombaOke: integer;

begin
  if _aktTranz='-K' then
    begin
      GetWuKeszlet;
      if _wuOsszeg>_sumAfa then
        begin
          HaventSomuch('FORINT');
          ModalResult := 2;
          Exit;
        end;
    end;

  _plombaOke := getplombarutin;
  if _plombaoke<>1 then
    begin
      // Ha nem sikerült a plomba beplvasás -> storno az egész tranzakció

      Modalresult := 2;
      exit;
    end;

  PlombaadatBeolvasas;



  _copyBlokk := False;
  _stornojel := 1;
  _stornozottBlokk := False;

  AfaTranzRegisztralas;
  Plombawrite;

  AfaTranzNyomtatas;
  TranzakcioPanel.Visible := False;
  WaktualNullazo;
  Fomenu;
end;

procedure TMetroForm.PlombaWrite;

begin
  _pcs := 'INSERT INTO WPENZSZALLITAS (DATUM,BIZONYLATSZAM,PLOMBASZAM,';
  _pcs := _pcs + 'SZALLITONEV,WTIPUS)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + CHR(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39)+ _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _plombaszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _szallitonev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _wtipus + _elojel + chr(39) + ')';
  ValutaParancs(_pcs);
end;




// =============================================================================
                    procedure TMETROFORM.AfaTranzRegisztralas;
// =============================================================================

begin
  _bizonylatszam := GetWuBizszam(_bizonylatTipus,True);
  _aktidos := GetIdos;

  ValutaDbase.Close;
  ValutaDbase.Connected := true;
  If ValutaTranz.InTransaction then valutaTranz.Commit;
  valutaTranz.StartTransaction;

  _pcs := 'INSERT INTO METROAFAMOZGAS (FOEGYSEGSZAM,PENZTARSZAM,ELLATMANYFORINT,';
  _pcs := _pcs + 'DATUM,IDO,SORSZAM,TRANZAKCIOTIPUS,STORNO)'+_sorveg;

  _pcs := _pcs + 'VALUES ('+inttostr(_foegyseg)+',';
  _pcs := _pcs + inttostr(_aktcegszam)+',';
  _pcs := _pcs + inttostr(_wuosszeg)+',';
  _pcs := _pcs + chr(39)+_bizonylatkelte+chr(39)+',';
  _pcs := _pcs + chr(39)+_aktidos+chr(39)+',';
  _pcs := _pcs + chr(39)+_bizonylatszam+chr(39)+',';
  _pcs := _pcs + chr(39)+_akttranz+chr(39) + ',';
  _pcs := _pcs + '1)';

  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;
  ValutaTranz.Commit;
  ValutaQuery.Close;

  WuKeszletAllito(_bizonylatTipus,'HUF',_wuOsszeg);
end;


// =============================================================================
             procedure TMETROFORM.ForintEditClick(Sender: TObject);
// =============================================================================

begin
  ActiveControl := Hideedit2;
end;


// =============================================================================
               procedure TMETROFORM.ForintEditEnter(Sender: TObject);
// =============================================================================

begin
  Forintedit.Color := clYellow;
end;


// =============================================================================
               procedure TMETROFORM.ForintEditExit(Sender: TObject);
// =============================================================================

begin
  Forintedit.Color := clWindow;
end;


// =============================================================================
       procedure TMETROFORM.BizTalloGombEnter(Sender: TObject);
// =============================================================================

begin;
  TBitBtn(Sender).Font.color := clBlue;
  TbitBtn(sender).Font.Style := [fsBold];
end;


// =============================================================================
             procedure TMETROFORM.BizTalloGombExit(Sender: TObject);
// =============================================================================

begin
  TBitBtn(sender).Font.color := clGray;
  TBitBtn(Sender).Font.Style := [];
end;

// =============================================================================
            procedure TMETROFORM.PillKeszletGombClick(Sender: TObject);
// =============================================================================

begin
  Kismenupanel.Visible := False;
  _aktGomb := PillKeszletGomb;

  ValutaDbase.close;
  ValutaDbase.Connected := True;
  if ValutaTranz.InTransaction then ValutaTranz.commit;

  _pcs := 'SELECT * FROM WUAFAADATOK';
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _sumAfa := FieldByName('OSSZESAFAKESZLET').AsInteger;
      Close;
    end;

  ForintKeszlet.Caption := ForintForm(_sumAfa)+' HUF';
  with PillKeszletPanel do
    begin
      Top := 230;
      Left := 70;
      Visible := True;
    end;
  ActiveControl := KeszletNyomtatoGomb;
end;

// =============================================================================
             procedure TMETROFORM.MegsemGombClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 2;
end;


// =============================================================================
            procedure TMETROFORM.BizTalloGombClick(Sender: TObject);
// =============================================================================

var _honapOke: integer;

begin

   // Eltünik a kismenü panelje:

   KismenuPanel.Visible := False;

  // Bekéri a kivánt idõszakot:

  _honapOke := idoszakrutin;
  if _honapOke=2 then
    begin
      Kismenu;
      exit;
    end;

  GetKertdatumAdatok;

  // Ha csak a mai napra kiváncsi: Mai napi Lista

  if _tolstring=_megnyitottnap then
    begin
      MaiNapiLista;
      KisMenu;
      Exit;
    end;

  // A kért idõszak alapján meghatározza a Gyüjtõtábla nevét:
  _farok := Nulele(_kertev-2000,2)+Nulele(_kertho,2);
  _wafaTablaNev := 'WAFA' + _farok;  // pl. 'WAFA0802' = 2008 FEBRUÁR

  // Ha a kért gyüjtõ nem létezik, akkor nincs tovább

  Valdatadbase.connected := true;
  ValdataTabla.close;
  ValdataTabla.tablename := _wafatablanev;
  if not Valdatatabla.exists then
    begin
      Valdatadbase.close;
      NoData;
      Kismenu;
      Exit;
    end;
  Valdatadbase.close;

  // Beállitja a tallozó tábla paramétereit a gyüjtõ adatbázisra

  with TallozoDbase do
    begin
      Connected := False;
      DatabaseName := 'C:\VALUTA\DATABASE\VALDATA.FDB';
      Connected := True;
    end;

  if TallozoTranz.InTransaction then TallozoTranz.Commit;

  _pcs := 'SELECT * FROM '+ _wafaTablaNev+_sorveg;
  _pcs := _pcs + 'WHERE DATUM BETWEEN '+ chr(39)+_tolstring+chr(39)+ ' AND '+ chr(39)+_igstring+chr(39);

  with TallozoQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  // Ha a kért hónapban nincs AFA bizonylat - akkor nincs tovább

  if TallozoQuery.RecNo=0 then
    begin
      TallozoQuery.close;
      NoData;
      KisMenu;
      Exit;
    end;

  // Régebbi bizonylatot nem lehet stornózni, csak a mait
  StornoGomb.Visible := False;

  // A karton kijelzõ ürlapot kiteszi egy ablakba:

  with WafaKarton do
    begin
      Top := 190;
      Left := 280;
      Visible := True;
    end;

  ElozoGomb.Enabled := False;

  // Beolvassa az elsõ rekordot:
  WafaRekordRead;

  // Kijelzi az elsõ rekordot, vezérlés a ListHideedit-nek
  WafaKartonDisp;
end;


// =============================================================================
                           procedure TMetroForm.NoData;
// =============================================================================


begin

  ShowMessage('NINCSENEK ADATAIM A KÉRT IDÕSZAKRÓL');
end;




// =============================================================================
              procedure TMETROFORM.KovetkezoGombClick(Sender: TObject);
// =============================================================================

begin
  TallozoQuery.Next;
  if TallozoQuery.Eof then KovetkezoGomb.Enabled := False;
  Elozogomb.Enabled := true;
  WafaRekordRead;
  WafaKartondisp;
end;


// =============================================================================
              procedure TMETROFORM.ElozoGombClick(Sender: TObject);
// =============================================================================

begin
  TallozoQuery.Prior;
  if TallozoQuery.Bof then elozogomb.Enabled := False;
  KovetkezoGomb.Enabled := True;
  WafaRekordRead;
  WafaKartondisp;
end;

// =============================================================================
                     procedure TMETROFORM.MainapiLista;
// =============================================================================

  (*  A mai napi Afabizonylatokat szeretné látni
  *)

begin
  TallozoQuery.Close;
  with TallozoDbase do
    begin
      Connected := False;
      DatabaseName := 'C:\VALUTA\DATABASE\VALUTA.FDB';
      Connected := True;
    end;

  if TallozoTranz.InTransaction then TallozoTranz.Commit;

  _wafaTablaNev := 'METROAFAMOZGAS';

  _pcs := 'SELECT * FROM METROAFAMOZGAS'+_sorveg;
  _pcs := _pcs + 'ORDER BY SORSZAM';

  with TallozoQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  StornoGomb.Visible := True;
  StornoGomb.Enabled := True;

  if TallozoQuery.Eof then
    begin
      TallozoQuery.Close;
      ShowMessage('ÜRES A MAI AFA VISSZAIGÉNYLÉS KARTONJA');
      Exit;
    end;

  with WafaKarton do
    begin
      Top := 32;
      Left := 42;
      Visible := True;
    end;

 WafaRekordRead;
 WafaKartonDisp;
end;

// =============================================================================
               procedure TMETROFORM.StornoGombClick(Sender: TObject);
// =============================================================================

begin
  Wafakarton.Enabled := False;
  Bpanel.Caption := _sorszam;
  with StornoSurePanel do
    begin
      Left := 50;
      Top := 120;
      Visible := True;
    end;
  ActiveControl := surestornoGomb;
end;


// =============================================================================
            procedure TMETROFORM.SureStornoGombClick(Sender: TObject);
// =============================================================================

//                STORNOZÁS

var _btp,_tt: string;
    _ft,_ujbrutto,_ujafa,_ujkdij : integer;

begin
  StornoSurePanel.Visible := False;

  WafaKarton.Enabled := True;
  _origBizonylat := _sorszam;
  _btp := leftstr(_sorszam,2);

  _bizonylatSzam := GetWuBizszam(_btp,True);
  WaktualNullazo;

  _FT := trunc((-1)*_wuOsszeg);

  WuKeszletAllito(_btp,'HUF',_ft);
  _aktidos := GetIdos;

  ValutaDbase.close;
  ValutaDbase.Connected := True;
  if ValutaTranz.InTransaction then ValutaTranz.Commit;
  ValutaTranz.StartTransaction;

  _pcs := 'UPDATE '+_wafatablanev + ' SET STORNO=2,STORNOBIZONYLAT=';
  _pcs := _pcs +chr(39)+_bizonylatszam+chr(39) + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM='+chr(39)+_origbizonylat+chr(39);

  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;

  _pcs := 'INSERT INTO ' + _wafaTablaNev + ' (DATUM,IDO,SZAMLASZAM,FOEGYSEGSZAM,SORSZAM)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39) + ',';
  _PCS := _pcs + chr(39) + _aktidos + chr(39) + ',';
  _pcs := _pcs + chr(39) + _szamlaszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_foegyseg)+',';
  _pcs := _pcs + chr(39)+_bizonylatszam+chr(39)+')';

   with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;

  if _tranzTipus = '-V' then
    begin
      _ujbrutto := trunc((-1)*_brutto);
      _ujafa := trunc((-1)*_afaertek);
      _ujkdij := trunc((-1)*_ugykezdij);

      _pcs := 'UPDATE ' + _wafaTablaNev + ' SET TRANZAKCIOTIPUS='+chr(39)+'+V'+chr(39);
      _pcs := _pcs + ',UGYFELSZAM='+inttostr(_ugyfelszam);
      _pcs := _pcs + ',BRUTTOOSSZEG='+inttostr(_ujBrutto);
      _pcs := _pcs + ',AFAOSSZEG='+inttostr(_ujafa);
      _pcs := _pcs + ',KEZELESISZAZALEK='+inttostr(_ugykezdijszazalek);
      _pcs := _pcs + ',UGYKEZELESIDIJ='+inttostr(_ujkdij);
      _pcs := _pcs + ',KIFIZETETTOSSZEG='+inttostr(_ft)+ _sorveg;
    end else
    begin
      _pcs := 'UPDATE '+ _wafatablanev + ' SET PENZTARSZAM='+inttostr(_penztar);
      _pcs := _pcs + ',ELLATMANYFORINT='+inttostr(_ft)+ _sorveg;
    end;

  _pcs := _pcs + 'WHERE SORSZAM=' + chr(39)+_bizonylatszam + chr(39);
   with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;

  if _tranztipus='-K' then _tt := '+K';
  if _tranztipus='+B' then _tt := '-B';

  _pcs := 'UPDATE ' + _wafaTablaNev + ' SET TRANZAKCIOTIPUS='+chr(39)+_tt+chr(39);
  _pcs := _pcs + ',STORNO=3';
  _pcs := _pcs + ',STORNOZOTTBIZONYLAT='+chr(39)+_origbizonylat+chr(39);
  _pcs := _pcs + ',SORSZAM='+chr(39)+_bizonylatszam+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE SORSZAM='+chr(39)+_bizonylatszam+chr(39);

   with ValutaQuery do
     begin
       Close;
       Sql.Clear;
       Sql.Add(_pcs);
       ExecSql;
     end;
  ValutaTranz.Commit;
  ValutaQuery.Close;

  _stornojel := 3;

  if _foegyseg=6 then wAfanyugtaIras else AfaTranzNyomtatas;
  StornoPanel.Caption := 'STORNO';

  TallozoDbase.Connected := True;
  if Tallozotranz.InTransaction then tallozoTranz.commit;

  _pcs := 'SELECT * FROM METROAFAMOZGAS' + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM='+chr(39)+_origbizonylat+chr(39);

  with Tallozoquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;
  WafarekordRead;
  WafaKartonDisp;

  _pcs := 'SELECT * FROM METROAFAMOZGAS' + _sorveg;
  _pcs := _pcs + 'ORDER BY SORSZAM';

  with Tallozoquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

end;

// =============================================================================
              procedure TMETROFORM.EscapeGombClick(Sender: TObject);
// =============================================================================

begin
  StornoSurePanel.Visible := False;
  WafaKarton.Visible := False;
  _aktGomb := ListaGomb;
  Fomenu;
end;


// =============================================================================
              procedure TMETROFORM.NYOMTATASGOMBClick(Sender: TObject);
// =============================================================================

var _spk: integer;

begin
  _spk := supervisorjelszo(0);
  if _spk<>1 then exit;
  _copyBlokk := True;
  if _foegyseg=6 then WafaNyugtaIras else AfaTranzNyomtatas;
end;




// =============================================================================
                    procedure TMETROFORM.AfaTranzNyomtatas;
// =============================================================================

var _sor: string;

begin
  BlokkFoCimIro(True);
  FejvonalHuzo;
  if (_stornojel>1) or (_stornozottBlokk) then
    begin
      StornoBiznyomtat;
      Exit;
    end;

  if _foegyseg=3 then WriteLn(_LFile,dupestring(' ',13)+'INNOVA - INVEST') ELSE
                      writeLN(_LFile,dupestring(' ',14)+'AFA - PENZTAR');

  if _elojel ='+' then
      _sor := 'AFAELLATMANY ATVETELE A ' else _sor := 'AFAELLATMANY ATADASA A ';

  kozepreIr(_sor);
  _sor := trim(_partnernev);

  if _elojel='+' then _sor := _sor + 'TOL' ELSE _sor := _sor + 'NAK';

  KozepreIr(_sor);

  VonalHuzo;
  writeLn(_LFile,'Bizonylatszam : '+ _bizonylatszam);

  if _elojel='-' then
    begin
      writeLn(_LFile,'Atadas kelte  : '+_bizonylatKelte+' ('+_aktidos+')');
      writeLn(_LFile,'Atadott osszeg: ' + Forintform(_wuosszeg)+' Ft');
    end else
    begin
      writeLn(_LFile,'Atvetel kelte : '+_bizonylatkelte+' ('+_AKTIDOS+')');
      writeLn(_LFile,'Atvett osszeg : '+ Forintform(_wuosszeg)+' Ft');
    end;
  WriteLn(_LFile,'Szallito neve : '+_szallitonev);
  WriteLn(_LFile,'Zsakplombaszam: '+_plombaszam);
  VonalHuzo;

  writeln(_Lfile,' ');
  writeLn(_LFile,dupestring('.',18) + '   ' + dupestring('.',18));
  writeLn(_LFile,'     atado                atvevo');
  StartNyomtatas;

end;

// =============================================================================
                     procedure TMETROFORM.WafaNyugtaIras;
// =============================================================================

begin

  BlokkFoCimIro(True);

  if (_stornojel>1) or (_stornozottBlokk) then
    begin
      _bizonylatkelte := _megnyitottnap;
      StornoBiznyomtat;
      Exit;
    end;

  FejvonalHuzo;

  if _uniosAfa=2 then writeLn(_LFile,'UNIOS AFAVISSZATERITES BIZONYLATA')
  else writeLN(_LFile,'     AFAVISSZATERITES BIZONYLATA');
  writeLn(_LFile,'Bizonylat kelte: '+ _megnyitottnap+' ('+_aktidos+')');
  writeLn(_LFile,'Bizonylat szama: '+ _widon + _bizonylatszam + _widOff);

  VonalHuzo;

  writeLn(_LFile,'Ugyfeladatok:');
  writeLn(_LFile,'        neve: '+ _partnernev);

  UgyfelAdatIro;


  VonalHuzo;

  writeLn(_LFile,'Szamla adatai:');
  writeLn(_LFile,'     szamla szama: '+ _szamlaszam);
  writeLn(_Lfile,'   brutto osszege: '+ ForintForm(_brutto)+' Ft');
  writeLn(_lfile,'      AFA osszege: ' + Forintform(_afaertek)+' Ft');
  writeLn(_LFile,'  ugykezelesi dij: ' + Forintform(_ugykezdij)+' Ft');

  VonalHuzo;

  writeLn(_LFile,'Kifizetve: '+_widon+forintform(_wuosszeg)+' Ft'+_widoff);

  VonalHuzo;

  writeLn(_Lfile,' ');
  writeLn(_Lfile,dupestring('.',18)+'   '+dupestring('.',18));
  writeLn(_Lfile,'     ugyfel'+dupestring(' ',17)+'penztaros');
  StartNyomtatas;
end;

// =============================================================================
                     procedure TMETROFORM.StornoBizNyomtat;
// =============================================================================


begin
  if _stornojel=2 then _tipus := 'STORNOZOTT ';
  if _stornojel=3 then  _tipus := '   STORNO ';

  writeLn(_LFile,_widon + _tipus + 'BIZONYLAT' + _widoff);
  VonalHuzo;

  if _ugyfelSzam>0 then
      write(_Lfile,'Ugyfel: ') else write(_LFile,'Partner: ');

  writeLn(_LFile,_partnerNev);

  write(_lfile,_sorveg);
  writeLn(_LFile,'  Stornobizonylat szama: '+ _Bizonylatszam);

  if _stornojel>1 then writeLn(_LFile,'  Eredeti bizonylatszam: '+ _origBizonylat);

  writeLn(_LFile,'        Stornozas kelte: '+ _bizonylatkelte);
  writeLn(_Lfile,'      Stornozott osszeg: '+ forintForm(_wuosszeg)+' Ft');

  VonalHuzo;
  writeLn(_LFile,_sorveg+_sorveg);
  VonalHuzo;

  writeLn(_LFile,'         stornozast vegezte');
  StartNyomtatas;
  _stornozottBlokk := False;
  _stornojel := 1;
end;



// =============================================================================
                procedure TMETROFORM.kbackgombClick(Sender: TObject);
// =============================================================================

begin
   pILLKESZLETpANEL.Visible := False;
   KismenuPanel.Visible := True;
   ActiveControl := Biztallogomb;
end;

// =============================================================================
           procedure TMETROFORM.KISMENUKILEPGOMBClick(Sender: TObject);
// =============================================================================

begin
  KismenuPanel.Visible := False;
  _aktGomb := ListaGomb;
  Fomenu;
end;

// =============================================================================
           procedure TMETROFORM.TRANZCANCELGOMBClick(Sender: TObject);
// =============================================================================

begin
  TranzakcioPanel.Visible := False;
  Fomenu;
end;

// =============================================================================
           procedure TMETROFORM.BIZDISPVISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  wAFAKARTON.Visible := FALSE;
  KisMenu;
end;

// =============================================================================
            procedure TMETROFORM.PenzkeszletList(Sender: TObject);
// =============================================================================

begin
  _aktidos := GetIdos;
  _aktidos := '('+leftstr(_aktidos,2)+' ora '+midstr(_aktidos,4,2)+' perckor)';

  assignFile(_LFile,'c:\valuta\Aktlst.txt');
  Rewrite(_LFile);

  VonalHuzo;

  writeLn(_LFile,'AZ AFAVISSZATERITES FORINTKESZLETE');

  VonalHuzo;
  KozepreIr(_megnyitottnap);
  Kozepreir(_aktidos);
  VonalHuzo;

  KozepreIr('Forintkeszlet: '+ forintform(_sumAfa)+' HUF');
  VonalHuzo;
 
  StartNyomtatas;

end;


// =============================================================================
             procedure TMETROFORM.IIATADGOMBEnter(Sender: TObject);
// =============================================================================

begin
  _aktGomb := TBitbtn(Sender);
  _Tag := _aktGomb.Tag;
  with _aktGomb.Font do
    begin
      Color := clRed;
      Style := [fsBold];
    end;
end;



// =============================================================================
              procedure TMETROFORM.IIATADGOMBExit(Sender: TObject);
// =============================================================================

begin
  _aktGomb := TBitbtn(Sender);
  _Tag := _aktGomb.Tag;
  with _aktGomb.Font do
    begin
      Color := clBlack;
      Style := [];
    end;
end;

// =============================================================================
            procedure TMETROFORM.FOMENUKILEPOGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;

// =============================================================================
    procedure TMETROFORM.KeszletnyomtatogombKeyDown(Sender: TObject;
                                         var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>119 then exit;
  PenzkeszletList(KeszletNyomtatoGomb);
end;

// =============================================================================
                   procedure TMETROFORM.WafaRekordRead;
// =============================================================================


begin

  with TallozoQuery do
    begin
      _foEgyseg := FieldByName('FOEGYSEGSZAM').asInteger;
      _penztar := FieldByName('PENZTARSZAM').asInteger;
      _ugyfelszam := FieldByName('UGYFELSZAM').asInteger;
      _datum := FieldByName('DATUM').asString;
      _sorszam := FieldByName('SORSZAM').asString;
      _szamlaszam := FieldByName('SZAMLASZAM').asString;
      _brutto := FieldByName('BRUTTOOSSZEG').asInteger;
      _afaErtek := FieldByNAme('AFAOSSZEG').asInteger;
      _ugykezDij := FieldByName('UGYKEZELESIDIJ').asInteger;
      _kifizetett := FieldByName('KIFIZETETTOSSZEG').asInteger;
      _ellatmany := FieldByName('ELLATMANYFORINT').asInteger;
      _tranztipus := FieldByName('TRANZAKCIOTIPUS').asString;
      _stornojel := FieldByName('STORNO').asInteger;
      _stornoBizonylat := FieldByName('STORNOBIZONYLAT').asstring;
      _origbizonylat := FieldByName('STORNOZOTTBIZONYLAT').asstring;
    end;


   _euAfa := 1;
   if _datum>'2010.09.01' then
     begin
      _aktidos := TallozoQuery.FieldByName('IDO').asString;
      _uniosafa := TallozoQuery.FieldByName('UNIOSAFA').asInteger;
     end
     else _aktidos := '-';

  if _ugyfelszam>0 then
    begin
      ValutaDbase.close;
      Valutadbase.Connected := True;
      if valutaTranz.InTransaction then ValutaTranz.Commit;

      _pcs := 'SELECT * FROM WUGYFEL'+ _sorveg;
      _pcs := _pcs + 'WHERE UGYFELSZAM='+inttostr(_ugyfelszam);

      with ValutaQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          First;
        end;

      if ValutaQuery.recno>0 then _partnernev := Valutaquery.FieldByName('NEV').asstring;
      ValutaQuery.close;
      _wuosszeg := _kifizetett;
    end;

  if _penztar>0 then
    begin
      ValutaDbase.close;
      Valutadbase.Connected := True;

      if valutaTranz.InTransaction then ValutaTranz.Commit;

      _pcs := 'SELECT * FROM WUAFACEGEK'+ _sorveg;
      _pcs := _pcs + 'WHERE CEGSZAM='+inttostr(_penztar);

      with ValutaQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          First;
        end;

      if ValutaQuery.Recno>0 then
               _partnerNev := ValutaQuery.FieldByName('CEGNEV').asString;
      ValutaQuery.Close;
      _wuosszeg := _ellatmany;
    end;

  if (_foegyseg=2) and (_penztar=0) then
    begin
      _partnernev := 'Innova Invest';
      _wuOsszeg := _ellatmany;
    end;
end;

// =============================================================================
                      procedure TMETROFORM.WafaKartonDisp;
// =============================================================================

var _megnev: string;

begin
  if _uniosafa=2 then Uniospanel.visible := true else UniosPanel.Visible := false;
  stornogomb.Enabled := true;
  if _stornojel>1 then Stornogomb.Enabled := False;
  WafaKarton.Visible := true;
  Datumpanel.caption := _datum;
  PartnerNevPanel.Caption := _partnerNev;
  if _tranzTipus='+B' then _megnev := 'PÉNZÁTVÉTEL';
  if _tranzTipus='-K' then _megnev := 'PÉNZÁTADÁS';
  if _tranzTipus='-V' then _megnev := 'ÁFAVISSZATÉRÍTÉS';
  MegnevezesPanel.Caption := _megnev;
  BizonylatszamPanel.Caption := _sorszam;

  if _kifizetett>0 then visszateritettPanel.caption := ForintForm(_kifizetett)
  else visszaTeritettPanel.Caption := '';

  if _ellatmany>0 then ellatmanypanel.Caption := ForintForm(_ellatmany)
  else ellatmanyPanel.Caption := '';

  if _ugykezdij>0 then UgykezelesiPanel.caption := ForintForm(_ugykezdij)
  else UgykezelesiPanel.caption  := '';

  StBizLabel.Visible := False;
  StornoTipLabel.Visible := False;

  if _stornojel<2 then
    begin
      StornoPanel.Color := clWhite;
      StornoPanel.Caption := '';
      StornoBizPanel.Caption := '';
    end else
    begin
      StBizLabel.Visible := True;
      StornoTipLabel.Visible := True;
      StornoPanel.Color := clMaroon;
    end;

  if _stornojel=2 then
    begin
      StornoPanel.Caption := 'STORNOZOTT BIZONYLAT';
      StornoBizPanel.Caption  := _stornoBizonylat;
      StornoTipLabel.Caption := 'Stornó';
    end;

  if _stornojel=3 then
    begin
      StornoPanel.Caption := 'STORNO BIZONYLAT';
      StornobizPanel.Caption := _origBizonylat;
      StornoTipLabel.Caption := 'Stornózott';
    end;
  ActiveControl := ListHideedit;
end;


// =============================================================================
             procedure TMETROFORM.LISTAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Kismenu;
end;

// =============================================================================
     procedure TMETROFORM.LISTHIDEEDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================


begin
  _bill := ord(key);
  case _bill of
    33: // Page Up
        begin
          if not elozogomb.enabled then exit;
          ElozogombClick(ListHideEdit);
        end;

    34: // Page Down
        begin
          if not KovetkezoGomb.Enabled then exit;
          KovetkezoGombClick(ListHideEdit);
        end;

   119: // F8
        NyomtatasGombClick(ListHideedit);

    46: // Delete
        begin
          if not stornogomb.Enabled then exit;
          stornoGombClick(ListHideedit);
        end;

    27: // Escape
          BizDispVisszaGombClick(ListHideedit);

  end;
end;

// =============================================================================
   procedure TMETROFORM.IIATADGOMBMouseMove(Sender: TObject; Shift: TShiftState;
                                                                X, Y: Integer);
// =============================================================================

begin
  ActiveControl := TBitBtn(Sender);
end;

// =============================================================================
             procedure TMETROFORM.VISSZAOKEGOMBEnter(Sender: TObject);
// =============================================================================

begin
  with tbitbtn(sender).Font do
    begin
      COlor := clRed;
      Style := [fsBold];
    end;
end;

// =============================================================================
             procedure TMETROFORM.VISSZAOKEGOMBExit(Sender: TObject);
// =============================================================================

begin
  with tbitbtn(sender).Font do
    begin
      COlor := clNavy;
      Style := [];
    end;
end;

// =============================================================================
        procedure TMETROFORM.VISSZAOKEGOMBMouseMove(Sender: TObject;
                                           Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  ActiveControl := TBitBtn(sender);
end;

// =============================================================================
           procedure TMETROFORM.CEGESAFAGOMBClick(Sender: TObject);
// =============================================================================

begin
  FomenuPanel.Visible := False;
  _ceges := True;
  _aktgomb := UniosAfaGomb;
  _bizonylatTipus := 'AV';
        _foegyseg := 6;
        _aktTranz := '-V';
          _elojel := '-';
        _menuPont := 6;

  Nevedit.Clear;
  Cimedit.Clear;
  with CegbekeroPanel do
    begin
      top := 525;
      Left := 250;
      Visible := True;
    end;
  ActiveControl := Nevedit;
end;


procedure TMETROFORM.cegokegombClick(Sender: TObject);
begin
  _partnernev := trim(nevedit.Text);
  _ugyfelszam := 0;
  _ccim := trim(cimedit.text);
  if _partnernev='' then
    begin
      ActiveControl := nevedit;
      exit;
    end;
  if _ccim='' then
    begin
      ActiveControl := cimedit;
      Exit;
    end;

  Cegbekeropanel.Visible := False;

  // A bekérõpanel alapra állítása:

  SzlaszamEdit.Clear;
    BruttoEdit.Clear;
       AfaEdit.Clear;

   SzazalekPanel.Caption := intTostr(_ugyKezDijSzazalek);

  UgykezDijPanel.Caption := '';
     BigNumLabel.Caption := '';

  // Bekéri az aktuális bizonylatszámot és kiirja

  _bizonylatszam := GetWuBizszam(_bizonylatTipus,False);
  BizonylatPanel.Caption := _bizonylatszam;

  // Kiirja az ügyfél nevét:
  UgyfelnevPanel.caption := _partnerNev;

  // végül Kiteszi a visszatérités bekérõpaneljét:
   with VisszaTeritesPanel do
     begin
           Top := 208;
          Left := 208;
       Visible := True;
     end;

   // Az elején nem lehet okézni
   VisszaOkeGomb.Enabled := False;

   // Az elsö bekérendõ adat  a számlaszám
   ActiveControl := SzlaszamEdit;
end;

procedure TMETROFORM.NEVEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (ord(key)<>13) and (ord(key)<>40) then exit;
  _partnernev := trim(nevedit.text);
  if _partnernev='' then exit;
  ActiveControl := Cimedit;
end;

// =============================================================================
    procedure TMETROFORM.CIMEDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)=38 then
    begin
      ActiveControl := Nevedit;
      exit;
    end;
  if ord(key)<>13 then exit;
  _ccim := trim(cimedit.text);
  if _ccim='' then exit;
  Activecontrol := Cegokegomb;

end;


procedure TMETROFORM.cegmegsemgombClick(Sender: TObject);
begin
  CegbekeroPanel.Visible := false;
  Fomenu;
end;

procedure TMETROFORM.uniosafagombClick(Sender: TObject);
begin

   FomenuPanel.Visible := False;
  _uniosafa := 2;
  _aktszazalek := _eusukszazalek;
  afatipusPanel.Caption := 'UNIÓS ÁFA-VISSZATÉRITÉS';
  afatipusPanel.Font.Color := clRed;
  _ceges := False;
  _aktgomb := UniosAfaGomb;
  _bizonylatTipus := 'AV';
        _foegyseg := 6;
        _aktTranz := '-V';
          _elojel := '-';
        _menuPont := 6;

  
  // A bekérõpanel alapra állítása:

  SzlaszamEdit.Clear;
    BruttoEdit.Clear;
       AfaEdit.Clear;

   SzazalekPanel.Caption := intTostr(_eusukSzazalek);

  UgykezDijPanel.Caption := '';
     BigNumLabel.Caption := '';

  // Bekéri az aktuális bizonylatszámot és kiirja

  _bizonylatszam := GetWuBizszam(_bizonylatTipus,False);
  BizonylatPanel.Caption := _bizonylatszam;

  // Kiirja az ügyfél nevét:

  _partnernev := _joginev;
  _ugyfelszam := _jogiugyfelszam;
  UgyfelnevPanel.caption := _partnerNev;

  // végül Kiteszi a visszatérités bekérõpaneljét:
   with VisszaTeritesPanel do
     begin
           Top := 128;
          Left := 14;
       Visible := True;
     end;

   // Az elején nem lehet okézni
   VisszaOkeGomb.Enabled := False;

   // Az elsö bekérendõ adat  a számlaszám
   ActiveControl := SzlaszamEdit;
end;

procedure TMETROFORM.Ugyfeladatiro;

begin
  if _ceges then
    begin
      writeLN(_LFile,'        cime: '+ _ccim);
      exit;
    end;

  if _uniosafa=2 then
     begin
       if _jogihely<>'' then    writeLn(_LFile,'  cime: '+_jogihely);
       if _tevekenyseg<>'' then writeLn(_LFile,'  tev.: '+_tevekenyseg);
       if _okiratszam<>'' then  writeLn(_LFile,'okirat: '+_okiratszam);
       if _kepvisnev<>'' then   writeLn(_LFile,'kepvis: '+_kepvisnev);
       if _beosztas<>'' then    writeln(_Lfile,'beoszt: '+_beosztas);
       exit;
     end;

  if _anyjaNeve<>'' then WriteLn(_LFile,'  anyja neve: ' + _anyjaneve);
  if _szulhely<>'' then writeLn(_LFile,' szul. helye: '+ _szulhely);
  if _szulido<>'' then writeLn(_Lfile,'       ideje: '+_szulido);
  if _Lakcim<>'' then writeLn(_lfile,'cim: '+_lakcim);
  if _okmanyTipus<>'' then writeLn(_lFile,'okmany tipus: '+ _okmanytipus);
  if _azonosito<>'' then writeLn(_LFile,'okmany szama: '+_azonosito);
end;

function TMetroForm.Getidos: string;

begin
  result := timetostr(Time);
  if midstr(result,2,1)=':' then result := '0' + result;
end;

function TMetroform.Nulele(_b: integer;_hh: byte): string;

begin
  result := inttostr(_b);
  while length(result)<_hh do result := '0' + result;
end;


// =============================================================================
                    procedure TMetroForm.GetWudata;
// =============================================================================

begin
  _pcs := 'SELECT * FROM WUGYFEL'+ _sorveg;
  _pcs := _pcs + 'WHERE UGYFELSZAM='+inttostr(_ugyfelszam);

  ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  if _Recno>0 then
    begin
      with ValutaQuery do
        begin
          _partNernev := FieldByName('NEV').asString;
          _AnyjaNeve := FieldByNAme('ANYJANEVE').asString;
          _szulhely := FieldByName('SZULETESIHELY').AsString;
          _Szulido := FieldByName('SZULETESIIDO').asstring;
          _lakcim := FieldByName('LAKCIM').AsString;
          _Okmanytipus := FieldByName('OKMANYTIPUS').asstring;
          _Azonosito := FieldByNAme('AZONOSITO').asstring;
        end;
    end;
  ValutaQuery.close;
  ValutaDbase.Close;
end;


// =============================================================================
      function TMetroform.GetWuBizszam(_btip: string;_write: boolean): string;
// =============================================================================

var _aktb: integer;

begin
  if _btip='WB' then _mezo := 'WUBE';
  if _btip='WK' then _mezo := 'WUKI';
  if _btip='UB' then _mezo := 'WUUGYFELBE';
  if _btip='UK' then _mezo := 'WUUGYFELKI';
  if _btip='AB' then _mezo := 'AFABE';
  if _btip='AK' then _mezo := 'AFAKI';
  if _btip='AV' then _mezo := 'AFAVISSZA';

  if (_btip='B') or (_btip='K') or (_btip='V') then _mezo := 'TESCO';
  _mezo := 'UTOLSO' + _mezo + 'BLOKK';

  _pcs := 'SELECT * FROM WUAFAADATOK';
  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _aktb := FieldByName(_mezo).asInteger;
    end;

  ValutaQuery.Close;
  ValutaDbase.close;

  // ---------------------------------------------------------------------------

  inc(_aktb);

  if _mezo='UTOLSOTESCOBLOKK' then
    begin
      if _aktb>99990 then _aktb := 1;
      Result := _bTip +'-' + Nulele(_aktb,5);
    end else
    begin
      if _aktb>999990 then _aktb := 1;
      Result := _bTip + '-' +  Nulele(_aktb,6);
    end;

  // ---------------------------------------------------------------------------

  if _write then
    begin
      _pcs := 'UPDATE WUAFAADATOK SET ' + _mezo + '=' + inttostr(_aktb)+',';
      _pcs := _pcs + 'WAKTUALBIZONYLAT=' + chr(39) + result + chr(39);
      ValutaParancs(_pcs);
    end;
end;

// =============================================================================
           function TMetroForm.kerekito(_int: integer): integer;
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
             function TMetroForm.ForintForm(_osszeg:integer):string;
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
                        procedure TMetroForm.GetWuKeszlet;
// =============================================================================


begin
  _pcs := 'SELECT * FROM WUAFAADATOK';
  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _sumUsd   := FieldByName('WUDOLLARKESZLET').asInteger;
      _sumHuf   := FieldByName('WUFORINTKESZLET').asInteger;
      _sumAfa   := FieldByName('OSSZESAFAKESZLET').asInteger;
      _sumMetro := FieldByName('METROAFAKESZLET').asInteger;
      _sumTesco := FieldByName('TESCOAFAKESZLET').asInteger;
      Close;
    end;
  Valutadbase.close;
    
  if (_sumMetro + _sumTesco)<>_sumafa then _sumAfa := _summetro+_sumTesco;
end;

// =============================================================================
               procedure TMetroForm.HaventSomuch(_vanem:string);
// =============================================================================

begin
  ShowMessage('NINCS ENNYI '+_vanem+' KÉSZLETÜNK');
end;

// =============================================================================
                          procedure TMetroForm.WaktualNullazo;
// =============================================================================

begin
  _pcs := 'UPDATE WUAFAADATOK SET WAKTUALBIZONYLAT='+CHR(39)+CHR(39);
  ValutaParancs(_pcs);
end;

// =============================================================================
      procedure TMetroForm.WuKeszletAllito(_btip: string; _vnem: string;
                                                          _aktosszeg: integer);
// =============================================================================

var _b1,_mezo,_iranybetu,_job: string;    // WB, WK, UB, UK  AB  AK  AV, B, K, V
    _ujosszeg,_eddig: integer;


begin
  _b1 := leftstr(_bTip,1);    // W vagy U  vagy A  Vagy B vagy K vagy V

  // Ha a bizonylat 2 betüs (_btip), akkor a 2-ik betü az irány,
  // ha egybetüs akkor AZ TESCO (_job='T')
  // Iranybetu: B(evétel) K(iadás) V(isszafizetés)

  if length(_btip)=2 then _iranyBetu := midstr(_bTip,2,1) else
    begin
      _iranyBetu := _b1;
      _job := 'T';
    end;

  // A visszavétel tulajdonképpen kiadás:

  if _iranyBetu ='V' then _iranyBetu := 'K';

  // A W és U kezdetü bizonylat Wstern Union bzionylata (_job='W')
  // A _mezo függ a valutanemtöl

  if (_b1='W') or (_b1='U') then
    begin
      _job := 'W';
      if _vnem='USD' then _mezo := 'WUDOLLARKESZLET' else _mezo := 'WUFORINTKESZLET';
    end;

  // Az 'A'-val kezdödö tipus METROAFA (_job='A')

  if (_b1='A') then
    begin
      _job := 'A';
      _mezo := 'METROAFAKESZLET';
    end;

  if _job = 'T' then _mezo := 'TESCOAFAKESZLET';
  if _iranybetu = 'K' then _aktOsszeg := (-1)* _aktosszeg;

  // Beállitva: _mezo (field.név), _job: W,A,T (WU,METRO,TESCO) Iránybetu

  ValutaDbase.Close;

  // Open WUAFADATOK tábla
  _pcs := 'SELECT * FROM WUAFAADATOK';

  Valutadbase.Connected := true;
   with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;

      _eddig := FieldByName(_mezo).asInteger;
      _sumMetro := FieldByName('METROAFAKESZLET').asInteger;
      _sumTesco := FieldByName('TESCOAFAKESZLET').asInteger;
      Close;
    end;
  Valutadbase.close;


   // Ha bevétel, akkor növeli, kiadásnál csökkenti a készletet:

  _ujOsszeg := _eddig + _aktosszeg;

  // Az AFA-készletek meghatározása:

  if _mezo='METROAFAKESZLET' then _sumMetro := _sumMetro + _aktosszeg;
  if _mezo='TESCOAFAKESZLET' then _sumTesco := _sumTesco + _aktosszeg;
  _sumafa := _sumMetro+_sumTesco;

  _pcs := 'UPDATE WUAFAADATOK SET ' + _mezo + '=' + inttostr(_ujosszeg);
  _pcs := _pcs + ',OSSZESAFAKESZLET=' + inttostr(_sumAfa);
  ValutaParancs(_pcs);
end;

procedure TMetroForm.Bizregiszter(_xbiz: string);

var _bizfile: string;
    _biziro: textfile;

begin
  _bizfile := 'c:\valuta\aktbizo.txt';
  assignfile(_biziro,_bizfile);
  rewrite(_biziro);
  write(_biziro,_xbiz);
  closefile(_biziro);
end;

// =============================================================================
             procedure TMetroForm.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  ValutaDbase.Close;
  ValutaDbase.Connected := True;
  if ValutaTranz.InTransaction then ValutaTranz.Commit;
  ValutaTranz.StartTransaction;
  with Valutaquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_ukaz);
      ExecSql;
    end;
  ValutaTranz.Commit;
  ValutaDbase.close;
end;


// =============================================================================
                     procedure TMetroForm.KozepreIr(_szoveg: string);
// =============================================================================

var _oo: integer;

begin
  _szoveg := trim(_szoveg);
  _oo := trunc((40-length(_szoveg))/2);
  writeLn(_LFile,dupestring(' ',_oo)+_szoveg);
end;

// =============================================================================
                      procedure TMetroForm.StartNyomtatas;
// =============================================================================

var _mondat: string;
    _nyomtat,_olvas: textFile;

begin
  Writeln(_LFile,_sorveg+_sorveg);
  WriteLn(_LFile,chr(26));
  CloseFile(_LFile);

  if _printer<>1 then AssignFile(_nyomtat,'LPT1')
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
              procedure TMetroForm.PlombaAdatBeolvasas;
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

procedure TMetroForm.GetKertdatumAdatok;

begin
  valutadbase.connected := true;
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


procedure TMETROFORM.KILEPOTimer(Sender: TObject);
begin
  kILEPO.Enabled := FALSE;
  Modalresult := 2;
end;


// =============================================================================
               procedure TMetroFORM.BlokkFocimIro(_kellnyitni: boolean);
// =============================================================================

begin
  if _kellNyitni then
    begin
      assignFile(_LFile,'c:\valuta\Aktlst.txt');
      Rewrite(_LFile);
    end;

  Kozepreir('Exclusive');
  Kozepreir(_cegNev);
  Kozepreir(_homePenztarkod+' '+_homepenztarnev);
  Kozepreir(_homePenztarCim);
  Kozepreir('Adoszam: ' + _cegadoszam);
end;




end.




