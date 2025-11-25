 unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, DateUtils,
  Dialogs, StdCtrls, Buttons, ExtCtrls, Grids, DBGrids, DB, DBTables, StrUtils,
  Mask, IBDatabase, IBCustomDataSet, IBTable, IBQuery, jpeg, printers;

type

  TTESCOFORM = class(TForm)

AtadottAtvettLabel: TLabel;
    JOBCIMLABEL: TLabel;
            Label2: TLabel;
            Label4: TLabel;
            Label5: TLabel;
            Label6: TLabel;
            Label7: TLabel;
            Label8: TLabel;
            Label9: TLabel;
           Label10: TLabel;
           Label11: TLabel;
           Label12: TLabel;
           Label13: TLabel;
           Label14: TLabel;
           Label24: TLabel;
           Label25: TLabel;

     AfaVisszaPanel: TPanel;
        BekeroPanel: TPanel;
       BizlistPanel: TPanel;
     BizonylatPanel: TPanel;
     FizetendoPanel: TPanel;
          MegjPanel: TPanel;
       PartnerPanel: TPanel;
     PillallasPanel: TPanel;
        PillFtPanel: TPanel;
        UgyfelPanel: TPanel;

      DataSource: TDataSource;

    SzlaszamEdit: TEdit;
      BruttoEdit: TEdit;
       Szaz5Edit: TEdit;
    SZAZ25EDIT: TEdit;

   BizlistVegeGomb: TBitBtn;
        CancelGomb: TBitBtn;
           EscGomb: TBitBtn;
       RendbenGomb: TBitBtn;
        StornoGomb: TBitBtn;
     VisszaOkeGomb: TBitBtn;
  VisszaCancelGomb: TBitBtn;

         DataRacs: TDBGrid;

      OSSZEGEDIT: TEdit;
    NYOMTATOGOMB: TBitBtn;
     FOMENUPANEL: TPanel;

     IIATVETGOMB: TBitBtn;
      IIATADGOMB: TBitBtn;
     PTATVETGOMB: TBitBtn;
    PTATVESZGOMB: TBitBtn;
VISSZATERITOGOMB: TBitBtn;
       LISTAGOMB: TBitBtn;
 PILLKESZLETGOMB: TBitBtn;
     KILEPESGOMB: TBitBtn;
    Label3: TLabel;
    BIZSZAMPANEL: TPanel;
    TALLOZODBASE: TIBDatabase;
    TALLOZOTRANZ: TIBTransaction;

    IntervalumPanel: TPanel;
    NYOMTATOFGOMB: TBitBtn;

    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    VALUTAQUERY: TIBQuery;

    Shape1: TShape;
    Shape3: TShape;
    Shape4: TShape;
    TALLOZOQUERY: TIBQuery;
    SZAZ18EDIT: TEdit;
    Label16: TLabel;
    Label17: TLabel;
    Label19: TLabel;
    Shape6: TShape;
    HATTERPANEL: TPanel;
    Image1: TImage;
    VALDATATABLA: TIBTable;
    VALDATAQUERY: TIBQuery;
    VALDATADBASE: TIBDatabase;
    VALDATATRANZ: TIBTransaction;
    OSSZEGPANEL: TPanel;


    procedure AdveszBlokk;
    procedure AfavisszaBlokk;
    procedure Attekintes(Sender: TObject);
    procedure BizBeolvaso(_biznum: string);
    procedure BizlistVegeGombClick(Sender: TObject);
    procedure CancelGombClick(Sender: TObject);
    procedure DataRacsKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DataracsCellClick(Column: TColumn);
    procedure EscapeGombClick(Sender: TObject);
    procedure EscGombClick(Sender: TObject);
    procedure VonalHuzo;

    procedure Fomenu;
    procedure FormActivate(Sender: TObject);
    procedure InnovaAtvetel(Sender: TObject);
    procedure InnovaAtadas(Sender: TObject);
    procedure PlombaWrite;
    procedure GetKertdatumAdatok;
    procedure BlokkFocimIro(_kellnyitni: boolean);

    procedure KozosMunka;
    procedure NyomtatoGombClick(Sender: TObject);
  
    function Getidos: string;
    function GetWcegNev(_cnum: integer): string;

    procedure PenzkeszletList(Sender: TObject);
    procedure PenztarAtvetel(Sender: TObject);
    procedure PenztarAtadas(Sender: TObject);
    procedure Pillertek(sender: TObject);
    procedure RekordChange;
    procedure RendbengombClick(Sender: TObject);
    procedure StornoGombClick(Sender: TObject);
    procedure StornoblokkNyom;
    procedure GetWuKeszlet;

    procedure SzlaszamEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure UgyfelOkeGombClick(Sender: TObject);
    procedure Visszaterites(Sender: TObject);
    function GetWuBizszam(_btip: string;_write: boolean): string;

    procedure VisszaCancelGombClick(Sender: TObject);
    procedure VisszaOkeGombClick(Sender: TObject);
  
    procedure IIATVETGOMBEnter(Sender: TObject);
    procedure IIATVETGOMBExit(Sender: TObject);
    procedure KILEPESGOMBClick(Sender: TObject);
    procedure IIATVETGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure VISSZAOKEGOMBEnter(Sender: TObject);
    procedure VISSZAOKEGOMBExit(Sender: TObject);
    procedure AlapAdatBeolvasas;
    function Nulele(_b: integer;_hh: byte): string;
    function kerekito(_int: integer): integer;
    function ForintForm(_osszeg:integer):string;
    procedure HaventSomuch(_vanem:string);
    procedure Bizregiszter(_xbiz: string);
    procedure PlombaAdatBeolvasas;
    procedure WuKeszletAllito(_btip: string; _vnem: string; _aktosszeg: integer);
    procedure WaktualNullazo;
    procedure ValutaParancs(_ukaz: string);
    procedure GetWudata;
    procedure KozepreIr(_szoveg: string);
    procedure StartNyomtatas;
 
    procedure NoData;
    procedure OSSZEGEDITKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
   

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  TESCOFORM: TTESCOFORM;

  _prgCim: array[1..8] of string;
  _aktGomb: TBitbtn;

  _widon : char = #14;
  _widoff: char = #20;


  _gepfunkcio,_stornojel,_kellmetroafa,_printer,_tag: byte;
  
  _aktMenuPont,_wugyfszam,_brutto,_cegszam,_kisafa,_nagyafa: integer;
  _afa,_afa5,_afa20,_afa18,_afa25,_ugyfelszam,_wuOsszeg: integer;
  _aktcegszam,_code,_sumafa,_recno,_sumMetro,_sumtesco,_bill: integer;

  _szlaszam,_biztip,_szamlaszam,_tranznev,_ftIrany,_origbizonylat: string;
  _aktidos,_szallitonev,_plombaszam,_aktdnem,_partnernev,_elojel: string;
  _wTipus,_bizonylatszam,_pcs,_megnyitottnap,_megjegyzes: string;
  _tolstring,_igstring,_anyjaneve,_szulhely,_szulido,_lakcim,_okmanytipus: string;
  _azonosito,_tablanev,_szuro,_ugyfelnev,_cegnev,_mezo,_numtext: string;
  _homepenztarkod,_homepenztarnev,_homepenztarcim,_bizkelte: string;
  _sorveg: string = chr(13)+chr(10);

  _top,_left,_height,_width: word;
  _kertev,_kertho,_tolnap,_ignap: word;
  _copyblokk: boolean;

  _LFile: textfile;

function getwesternceg: integer; stdcall; external 'c:\valuta\bin\getwceg.dll' name 'getwesternceg';
function getplombarutin: integer; stdcall; external 'c:\valuta\bin\getplomb.dll' name 'getplombarutin';
function getwesternugyfel(_para: integer): integer; stdcall; external 'c:\valuta\bin\getwugyf.dll' name 'getwesternugyfel';
function idoszakrutin: integer; stdcall; external 'c:\valuta\bin\idoszak.dll' name 'idoszakrutin';
function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';

function tescorutin: integer; stdcall;


implementation


{$R *.dfm}

function tescorutin: integer; stdcall;
begin
  tescoform := TTescoform.create(Nil);
  result := tescoform.showmodal;
  tescoform.free;
end;


// =============================================================================
                  procedure TTESCOFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  _top    := round((_height-768)/2);
  _left   := round((_width-1024)/2);

  Top     := _top;
  Left    := _left;
  Height  := 768;
  Width   := 1024;

  _aktidos := GetIdos;

  PillAllasPanel.Visible := False;
  BizlistPanel.Visible   := False;
  AfaVisszaPanel.Visible := False;
  BekeroPanel.Visible    := False;

  Alapadatbeolvasas;

  _prgCim[1] := 'PÉNZÁTVÉTEL INNOVA INVESTTÖL';
  _prgCim[2] := 'PÉNZÁTADÁS INNOVA INVESTNEK';
  _prgCim[3] := 'PÉNZÁTVÉTEL ÁFAPÉNZTÁRBÓL';
  _prgCim[4] := 'PÉNZÁTADÁS EGY ÁFAPÉNZTÁRNAK';
  _prgCim[5] := 'ÁFÁVISSZATÉRÍTÉS KIFIZETÉSE';
  _prgCim[6] := 'BIZONYLAT LISTA - SZTORNÓ';
  _prgCim[7] := 'PILLANATNYI PÉNZKÉSZLET';
  _prgcim[8] := 'KILÉPÉS';

  _szallitonev := '';
  _plombaszam := '';

  if _gepFunkcio=2 then
    begin
      iiAtvetGomb.Enabled := True;
      iiAtadGomb.Enabled := True;
      _aktgomb := iiAtvetGOmb;
    end else
    begin
      iiAtvetGomb.Enabled := False;
      iiAtadGomb.Enabled := False;
      _aktgomb := PtatvetGomb;
    end;
  _aktdnem := 'HUF';
   _wTipus := 'T';
  
  Fomenu;
end;

// =============================================================================
                          procedure TTESCOFORM.Fomenu;
// =============================================================================

begin
  with FomenuPanel do
    begin
      Top     := 410;
      Left    := 280;
      Visible := true;
    end;
  ActiveControl := _aktgomb;
end;


// =============================================================================
              procedure TTESCOFORM.InnovaAtvetel(Sender: Tobject);
// =============================================================================

begin
  _aktMenuPont := 1;
      _aktgomb := iiAtvetGomb;
       _bizTip := 'B';
     _tranznev := 'PÉNZÁTVÉTEL';
   _partnerNev := 'INNOVA INVEST';
   _aktCegszam := 0;
   _ugyfelszam := 0;
      _ftIrany := 'ÁTVETT';
       _elojel := '+';

  KozosMunka;
end;

// =============================================================================
              procedure TTESCOFORM.InnovaAtadas(Sender: TObject);
// =============================================================================

begin
  _aktMenupont := 2;
      _aktGomb := iiAtadGomb;
       _bizTip := 'K';
     _tranzNev := 'PÉNZÁTADÁS';
   _partnerNev := 'INNOVA INVEST';
   _ugyfelszam := 0;
   _aktCegszam := 0;
      _ftIrany := 'ÁTADOTT';
       _elojel := '-';

  KozosMunka;
end;

// =============================================================================
           procedure TTESCOFORM.PenztarAtvetel(Sender: TObject);
// =============================================================================

begin
  _aktMenupont := 3;
      _aktgomb := ptAtvetGomb;
       _bizTip := 'B';
     _tranzNev := 'PÉNZÁTVÉTEL';
   _ugyfelszam := 0;
      _ftIrany := 'ÁTVETT';
       _elojel := '+';

  KozosMunka;
end;

// =============================================================================
               procedure TTESCOFORM.PenztarAtadas(Sender: TObject);
// =============================================================================

begin
  _aktMenupont := 4;
      _aktGomb := ptAtveszGomb;
       _bizTip := 'K';
     _tranzNev := 'PÉNZÁTADÁS';
   _ugyfelszam := 0;
      _ftIrany := 'ÁTADOTT';
       _elojel := '-';

  KozosMunka;
end;


// =============================================================================
                          procedure TTESCOFORM.KozosMunka;
// =============================================================================

var 
    _rag: string;

begin
  FomenuPanel.Visible := False;

  // Pénztárakkal val tranzakciók esetén a Pénztár bekérése:

  if (_aktMenuPont=3) or (_aktMenuPont=4) then
    begin
      _aktcegszam := getwesternceg;
      if _aktcegszam=-1 then
        begin
          Fomenu;
          exit;
        end;
      _partnernev := GetWcegNev(_aktcegszam);
    end;

  // Az összeg bekérõ edit törlése;

  OsszegEdit.clear;
  JobcimLabel.Caption := _tranzNev;
  AtadottAtvettlabel.Caption := _ftIrany;

  _rag := '-TOL';
  if _bizTip = 'K' then _rag := '-NAK';

  PartnerPanel.Caption := trim(_partnerNev)+_rag;

  _bizonylatSzam := GetWuBizszam(_biztip,False);
  BizszamPanel.Caption := _bizonylatSzam;

  // Bekérõpanel megjelenése, az edit aktiválodik:

  oSSZEGpANEL.CAPTION := '';
  OsszegEdit.Text := '';
  _numtext := '';

  RendbenGomb.Enabled := False;
  with BekeroPanel do
    begin
           Top := 260;
          Left := 330;
       Visible := True;
    end;
  ActiveControl := Osszegedit;
end;


// =============================================================================
  procedure TTESCOFORM.OSSZEGEDITKeyUp(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
//==============================================================================

var _ww: byte;

begin
  _bill := ord(key);
  if (_bill>95) and (_bill<106) then _bill := _bill-48;

  if (_bill>47) and (_bill<58) then
    begin
      _numtext := _numtext + chr(_bill);
      val(_numtext,_wuosszeg,_code);
      OsszegPanel.Caption := Forintform(_wuosszeg);
      RendbenGomb.Enabled := true;
      Activecontrol := Osszegedit;
      exit;
    end;

  if _bill=8 then
    begin
      if _numtext='' then exit;

      _ww := length(_numtext);
      if _ww=1 then
         begin
           _numtext := '';
           OsszegPanel.Caption := '';
           Activecontrol := Osszegedit;
           exit;
         end;
       dec(_ww);

       _numtext := leftstr(_numtext,_ww);
       val(_numtext,_wuosszeg,_code);
       Osszegpanel.Caption := Forintform(_wuosszeg);
       Activecontrol := Osszegedit;
       exit;
     end;

  if ord(key)<>13 then
    begin
      Activecontrol := rendbenGomb;
      exit;
    end;
end;


// =============================================================================
           procedure TTESCOFORM.RendbenGombClick(Sender: TObject);
// =============================================================================

var _plombaOke: integer;

begin
  // TESCO BIZONYLAT RENDBEN VAN !!!

  BekeroPanel.Visible := False;

  // ha nincs összeg akkor semmi sincs

  if _wuosszeg=0 then
    begin
      Fomenu;
      Exit;
    end;

  // Ha kiadási bizonylatról van szó, akkor megnézi van-e ennyi pénz
  if _biztip='K' then
    begin
      GetWuKeszlet; // Bekéri az összes AFA készletet:
      if _wuOsszeg>_sumafa then
        begin
          HaventSomuch('FORINT');
          ModalResult := 2;
          exit;
        end;
    end;

  // -------------  PLOMBASZÁM BEKÉRÉSE ----------------------------------------

   _plombaOke := getplombarutin;
  if _plombaoke<>1 then
    begin
      // Ha nem sikerült a plomba beplvasás -> storno az egész tranzakció

      Modalresult := 2;
      exit;
    end;
  PlombaadatBeolvasas;


  // ---------------------------------------------------------------------------

  // Bekéri a bizonylatszámot, és rögziti is azt (TRUE) !!
  _bizonylatszam := GetWuBizszam(_biztip,True);

  Bizregiszter(_bizonylatszam);

  // A bizonylat értékével módosul a készlet:
  WuKeszletAllito(_biztip,'HUF',_wuOsszeg);

// -------- A TESCO BIZONYLAT RÖGZITÉSE TESCO TÁBLÁBA --------------------------

  _AKTIDOS := GetIdos;
  ValutaDbase.Close;
  Valutadbase.connected := true;
  if valutaTranz.Intransaction then ValutaTranz.Commit;
  ValutaTranz.StartTransaction;

  _pcs := 'INSERT INTO TESCO (DATUM,IDO,BIZONYLATTIPUS,BIZONYLATSZAM,WUGYFELSZAM,';
  _pcs := _pcs + 'WUGYFELNEV,OSSZESFORINT,STORNO)'+_sorveg;

  _pcs := _pcs + 'VALUES ('+chr(39)+_megnyitottnap+chr(39)+',';
  _pcs := _pcs + chr(39) + _aktidos + chr(39) + ',';
  _pcs := _pcs + chr(39)+_biztip+chr(39)+',';
  _pcs := _pcs + chr(39)+_bizonylatszam+chr(39)+',';
  _pcs := _pcs + inttostr(_ugyfelszam)+',';
  _pcs := _pcs + chr(39)+_partnernev+chr(39)+',';
  _pcs := _pcs + inttostr(_wuosszeg) + ',';
  _pcs := _pcs + '1)';

  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.add(_pcs);
      ExecSql;
    end;

  ValutaTranz.Commit;

  PlombaWrite;

// ---------------- TESCO BIZONYLAT NYOMTATÁSA  --------------------------------
// Bizonylatot nyomtatása

    AdveszBlokk;
    WaktualNullazo;
    Fomenu;
end;


// =============================================================================
                          procedure TTescoForm.WaktualNullazo;
// =============================================================================

begin
  _pcs := 'UPDATE WUAFAADATOK SET WAKTUALBIZONYLAT='+CHR(39)+CHR(39);
  ValutaParancs(_pcs);
end;


// =============================================================================
             procedure TTescoForm.ValutaParancs(_ukaz: string);
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



// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
            procedure TTESCOFORM.Visszaterites(Sender: TObject);
// =============================================================================

//                            TESCO ÁFAVISSZATÉRITÉS
//                       =================================



begin

  FomenuPanel.Visible := False;

  _aktgomb := VisszateritoGomb;
  _aktMenuPont := 5;
  _bizTip := 'V';

 // Az ügyfél kiválasztása:

  _ugyfelszam := getwesternugyfel(3);
  if _ugyfelszam=-1 then
    begin
      Fomenu;
      exit;
    end;

  Getwudata;

  // Bizonylatszám bekérése ----------------------------------------------------

  _bizonylatszam := GetWuBizszam(_biztip,False);
  BizonylatPanel.Caption := _bizonylatszam;
  UgyfelPanel.caption := _partnernev;

  Szlaszamedit.clear;
  Bruttoedit.clear;
  Szaz5edit.Clear;
  Szaz18Edit.Clear;

  Szaz25Edit.Clear;
  
  FizetendoPanel.Caption := '';
  VisszaOkeGomb.Enabled := False;

  with AfavisszaPanel do
    begin
      top := 180;
      Left := 270;
      Visible := True;
    end;
  ActiveControl := AFAvisszapanel;
  SzlaszamEdit.SetFocus;
end;

// =============================================================================
       procedure TTESCOFORM.SzlaszamEditKeyDown(Sender: TObject; var Key: Word;
                                                   Shift: TShiftState);
// =============================================================================

var _tag: integer;

begin
  if ord(key)=13 then
    begin
      _tag := Tedit(sender).Tag;
      inc(_tag);

      case _tag of
        2:
           activecontrol := bruttoedit;

        3: begin
             val(Bruttoedit.text,_brutto,_code);
             if _code<>0 then
               begin
                 _brutto := 0;
                 exit;
               end;
             _brutto := Kerekito(_brutto);
             BruttoEdit.Text := inttostr(_brutto);
             activecontrol := szaz5edit;
           end;


        4: begin
             val(szaz5edit.Text,_afa5,_code);
             if _code<>0 then
               begin
                 _afa5 := 0;
                 ActiveControl := szaz18edit;
                 exit;
               end;
             _afa5 := Kerekito(_afa5);
             Szaz5Edit.Text := Inttostr(_afa5);
             activecontrol := szaz18edit;
           end;

        5: begin
             val(szaz18edit.Text,_afa18,_code);
             if _code<>0 then
               begin
                 _afa18 := 0;
                 ActiveControl := szaz25edit;
                 exit;
               end;
             _afa18 := Kerekito(_afa18);
             Szaz18Edit.Text := Inttostr(_afa18);
             activecontrol := szaz25edit;
           end;

        7: begin
             val(Szaz25edit.Text,_afa25,_code);
             if _code<>0 then
               begin
                 _afa25 := 0;
               end;

             _afa25 := Kerekito(_afa25);
             Szaz25Edit.Text := Inttostr(_afa25);

             val(szaz5edit.Text,_afa5,_code);
             if _code<>0 then _afa5 := 0;

             val(szaz18edit.Text,_afa18,_code);
             if _code<>0 then _afa18 := 0;

             _kisafa := _afa5+_afa18;
             _nagyafa := _afa25;

             _afa := _kisafa + _nagyafa;
             if _afa = 0 then exit;

             FizetendoPanel.caption := forintform(_afa)+' Ft';
             VisszaOkeGomb.Enabled := true;
             activecontrol := visszaokegomb;
           end;
      end;
    end;
end;


// =============================================================================
           procedure TTESCOFORM.VisszaOkeGombClick(Sender: TObject);
// =============================================================================

//                  TESCO ÁFAVISSZAIGÉNYLÉS RENDBEN VAN
//                 -------------------------------------

begin
  val(szaz5edit.Text,_afa5,_code);
  if _code<>0 then _afa5 := 0;

  val(szaz18edit.Text,_afa18,_code);
  if _code<>0 then _afa18 := 0;

  val(szaz25edit.Text,_afa25,_code);
  if _code<>0 then _afa25 := 0;

  // Ha nincs visszaigénylés akkor vége ...

  _kisafa := _afa5 + _afa18;
  _nagyafa := _afa25;
  _afa := _kisafa + _nagyafa;
  if _afa = 0 then exit;

  val(Bruttoedit.text,_brutto,_code);
  if _code<>0 then _brutto := 0;

  _szlaszam := SzlaszamEdit.Text;

  FizetendoPanel.Caption := ForintForm(_afa)+' Ft';

  // Ha nincs _afa-nyi forint akkor nem tud fizetni
  GetWuKeszlet;
  if _sumAfa<_afa then
    begin
      HaventSomuch('FORINT');
      ModalResult := 2;
      exit;
    end;

// -------- Minden rendben, lehet regisztrálni a Tesco bizonylatot -------------


  _aktidos := GetIdos;

  // BizonylatSzam bekérése és rögzitése: A készlet aktualizálása:

  _bizonylatszam := GetWuBizszam(_biztip,True);
  WuKeszletAllito(_biztip,'HUF',_AFA);

  _pcs := 'INSERT INTO TESCO (DATUM,IDO,BIZONYLATTIPUS,BIZONYLATSZAM,WUGYFELSZAM,';
  _pcs := _pcs + 'WUGYFELNEV,SZAMLABRUTTO,SZAMLASZAM,AFA5SZAZALEKOS,AFA20SZAZALEKOS,';
  _pcs := _pcs + 'OSSZESFORINT,STORNO)'+_sorveg;

  _pcs := _pcs + 'VALUES ('+chr(39)+_megnyitottnap+chr(39)+',';
  _PCS := _pcs + chr(39) + _aktidos + chr(39)+',';
  _pcs := _pcs + chr(39)+'V'+chr(39)+',';
  _pcs := _pcs + chr(39)+_bizonylatszam+chr(39)+',';
  _pcs := _pcs + inttostr(_ugyfelszam)+',';
  _pcs := _pcs + chr(39)+_partnernev+chr(39)+',';
  _pcs := _pcs + inttostr(_brutto)+',';
  _pcs := _pcs + chr(39)+_szlaszam+chr(39)+',';
  _pcs := _pcs + inttostr(_kisafa)+',';
  _pcs := _pcs + inttostr(_nagyafa)+',';
  _pcs := _pcs + inttostr(_afa) + ',';
  _pcs := _pcs + '1)';

  // A tescobizonylat beirása a TESCO táblába ----------------------------------

 ValutaParancs(_pcs);

  // ----------------------- A bizonylat kinyomtatása  -------------------------

  AfavisszaBlokk;
  AfaVisszaPanel.Visible := False;
  WaktualNullazo;
  Fomenu;
end;

// =============================================================================
              procedure TTESCOFORM.CancelGombClick(Sender: TObject);
// =============================================================================

begin
  Bekeropanel.Visible := false;
  Fomenu;
end;


// ============================================================================
       procedure TTESCOFORM.VisszaCancelGombClick(Sender: TObject);
// ============================================================================

begin
  AfavisszaPanel.Visible :=False;
  Fomenu;
end;



// =============================================================================
                    procedure TTescoForm.GetWudata;
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






// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

// =============================================================================
               procedure TTESCOFORM.Attekintes(Sender: Tobject);
// =============================================================================


var _vanHonap: integer;
begin
   FomenuPanel.Visible := False;
   _Aktgomb := ListaGomb;

  _vanhonap := idoszakrutin;
  if _vanhonap=2 then
    begin
      Fomenu;
      exit;
    end;

  GetKertdatumAdatok;

  if _tolstring<_megnyitottnap then
    begin
      _tablanev := 'TESC'+ Nulele(_kertev-2000,2)+Nulele(_kertho,2);
      _szuro := '(DATUM BETWEEN '+chr(39)+_tolstring+chr(39)+' AND '+chr(39)+_igstring+chr(39)+')';
      intervalumPanel.Caption := _tolstring+' és '+_igstring + ' között';

      ValdataDbase.connected := True;
      ValdataTabla.close;
      ValdataTabla.TableName := _tablanev;
      if not ValdataTabla.Exists then
        begin
          ValdataDbase.close;
          ShowMessage('HIÁNYZIK A KÉRT HAVI GYÜJTÕ');
          Fomenu;
          Exit;
        end;

      ValdataDbase.close;  
      with TallozoDbase do
        begin
          Connected := False;
          DataBaseName := 'C:\VALUTA\DATABASE\VALDATA.FDB';
          Connected := True;
        end;

      _pcs := 'SELECT * FROM ' + _tablanev + _sorveg;
      _pcs := _pcs + 'WHERE ' + _szuro;
    end;

  if _tolstring=_megnyitottnap then
    begin
       intervalumPanel.Caption := 'A MAI NAPI BIZONYLATOK';
       with TallozoDbase do
        begin
          Connected := False;
          DataBaseName := 'C:\VALUTA\DATABASE\VALUTA.FDB';
          Connected := True;
        end;

      _tablanev := 'TESCO';
      _szuro := '';
      _pcs := 'SELECT * FROM TESCO' + _sorveg;
    end;

  Tallozodbase.Connected := true;
  with TallozoQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  if TallozoQuery.Recno=0 then
   begin
     Nodata;
     TallozoQuery.Close;
     Fomenu;
     Exit;
   end;

  with BizListPanel do
    begin
       Top := 120;
       Left := 70;
       Visible := true;
     end;
  ActiveControl := DataRacs;
end;

// =============================================================================
                           procedure TTescoForm.NoData;
// =============================================================================


begin

  ShowMessage('NINCSENEK ADATAIM A KÉRT IDÕSZAKRÓL');
end;



// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
// =============================================================================
            procedure TTESCOFORM.Pillertek(Sender: TObject);
// =============================================================================


begin
  Fomenupanel.Visible := false;
  _aktgomb := PillkeszletGomb;

  Valutadbase.close;
  Valutadbase.Connected := true;
  if ValutaTranz.InTransaction then ValutaTranz.commit;

  _pcs := 'SELECT * FROM WUAFAADATOK';
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
    end;

  _sumAfa := ValutaQuery.FieldByName('OSSZESAFAKESZLET').asInteger;
  ValutaQuery.Close;


  PillFtPanel.Caption := ForintForm(_sumaFA)+' Ft';
  with PillAllasPanel do
    begin
      Top := 520;
      Left := 310;
      Visible := True;
    end;
  ActiveControl := EscGomb;
end;


// =============================================================================
              procedure TTESCOFORM.EscapeGombClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 2;
end;



procedure TTescoForm.GetKertdatumAdatok;

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



// =============================================================================
                         procedure TTESCOFORM.ADveszblokk;
// =============================================================================

var _text,_va,_vas: string;

begin

  BlokkFoCimIro(True);
  if _copyBlokk then writeLn(_LFile,'           M Á S O L A T');
  _copyBlokk := False;
  if _stornojel<2 then
       writeLn(_Lfile,_widon+'------ INNOVA -----'+_widoff)
  else writeLN(_Lfile,_widon+'- STORNO BIZONYLAT-'+_widoff);

  KozepreIr('INNOVA - INVEST');
  _text := 'AFAELLATMANY ';
  if (_aktmenupont=1) or (_aktmenuPont=3) then
    begin
      _text := _text + ' ATVETELE A';
       _va  := 'Atvett ';
       _vas := 'Atvetel';
    end else
    begin
      _text := _text + ' ATADASA A';
        _va := 'Atadott';
       _vas := ' Atadas';
    end;

  KozepreIr(_text);
  KozepreIr(_partnernev);
  VonalHuzo;
  WriteLn(_LFile,'Bizonylatszam : '+_bizonylatszam);
  writeLn(_Lfile,_vas + ' kelte : ' + _bizkelte+' ('+_aktidos+')');
  WriteLn(_LFile,_va+' osszeg: '+ forintform(_wuosszeg)+' Ft');
  WriteLn(_LFile,'Szallito neve : ' + _szallitonev);
  WriteLn(_Lfile,'Zsakplombaszam: ' + _plombaszam);
  VonalHuzo;
  if _stornojel=3 then
         WriteLN(_Lfile,'Stornozott blokk szama: '+ _bizonylatszam);

  WriteLn(_Lfile,_sorveg);
  writeln(_Lfile,dupestring('.',18)+'     '+dupestring('.',18));
  write(_Lfile,'     atado');
  writeLn(_Lfile,dupestring(' ',18)+'atvevo');
  writeLn(_LFile,_sorveg+_sorveg+_sorveg);
  StartNyomtatas;
  _stornojel := 1;
end;

// =============================================================================
                    procedure TTESCOFORM.Afavisszablokk;
// =============================================================================

begin
  BlokkFoCimIro(True);
  writeLn(_Lfile,_widon+'------ INNOVA -----'+_widoff);

  KozepreIr('AFAVISSZATERITES BIZONYLATA');
  writeLn(_LFile,'Bizonylat kelte: '+ _bizkelte+' ('+_aktidos+')');
  writeLn(_LFile,'Bizonylat szama: '+ _widon+ _bizonylatszam+_widoff);
  VonalHuzo;

  writeLn(_LFile,'Ugyfel adatai:'+ _sorveg);
  writeLn(_LFile,'        neve: '+ _partnernev);
  writeLn(_LFile,'  anyja neve: '+ _anyjaneve);
  writeLn(_LFile,' szul. helye: '+ _szulhely);
  writeLn(_LFile,'       ideje: '+ _szulido);
  writeLN(_LFile,'cim: '+_lakcim);
  writeLn(_LFile,'okmany tipus: '+ _okmanytipus);
  writeLN(_LFile,'       szama: '+ _azonosito);
  VonalHuzo;

  writeLn(_LFile,'Szamla adatai:'+ _sorveg);
  writeLn(_LFile,'Szamlaszam: '+_szlaszam);
  writeLn(_Lfile,'      Brutto osszeg: '+ forintform(_brutto)+' Ft');
  writeLN(_LFile,'Kifizetett  5 % AFA: '+ Forintform(_afa5)+' Ft');
  writelN(_LFile,'Kifizetett 18 % AFA: '+ ForintForm(_afa18)+' Ft');
  writeLn(_LFile,'Kifizetett 25 % AfA: '+ ForintForm(_afa20)+' Ft');
  writeLn(_LFile,'Kifizetett 27 % AfA: '+ ForintForm(_afa25)+' Ft');
  VonalHuzo;
  _kisafa := _afa5+_afa18;
  _nagyafa := _afa20+_afa25;
  _afa := _kisafa + _nagyafa;
  WriteLn(_Lfile,'Kifizetve: '+Forintform(_afa)+' Ft');
  VonalHuzo;
  WriteLn(_Lfile,_sorveg + _sorveg);
  writeLn(_Lfile,dupestring('.',18)+'     '+dupestring('.',18));
  writeLn(_Lfile,'     ugyfel'+dupestring(' ',18)+'penztaros');
  writeLn(_Lfile,_sorveg+_sorveg+_sorveg);

  StartNyomtatas;
end;


// =============================================================================
         procedure TTESCOFORM.UgyfelOkeGombClick(Sender: TObject);
// =============================================================================

begin

  _bizonylatszam := GetWuBizszam('V',False);
  BizonylatPanel.Caption := _bizonylatszam;


  UgyfelPanel.Caption := _ugyfelnev;

  SzlaszamEdit.Clear;
  BruttoEdit.Clear;
  Szaz5edit.Clear;
  Szaz18edit.Clear;
  Szaz25edit.clear;
  FizetendoPanel.Caption := '';

  with AfaVisszaPanel do
    begin
           Top := 145;
          Left := 230;
       Visible := True;
    end;
  ActiveControl := SzlaszamEdit;
end;


// =============================================================================
     procedure TTESCOFORM.DataRacsKeyUp(Sender: TObject; var Key: Word;
                                             Shift: TShiftState);
// =============================================================================

begin
  RekordChange;
end;


// =============================================================================
                      procedure TTESCOFORM.RekordChange;
// =============================================================================

var _ujrecno: integer;

begin
   if TallozoQuery.Eof then exit;
  _ujrecno := TallozoQuery.RecNo;
  if _ujrecno<>_recno then
    begin
      _recno := _ujrecno;
      _stornojel := TallozoQuery.FieldByName('STORNO').asInteger;
      if _stornojel>1 then
        begin
          if _stornojel=3 then MegjPanel.Caption := 'STORNÓ BIZONYLAT'
          else MegjPanel.Caption := 'STORNOZOTT BIZONYLAT';
          StornoGomb.Enabled := False;
        end else
        begin
          StornoGomb.Enabled := True;
          MegjPanel.Caption := '';
        end;
    end;
end;

// =============================================================================
          procedure TTESCOFORM.DataRacsCellClick(Column: TColumn);
// =============================================================================

begin
  RekordChange;
end;

// =============================================================================
             procedure TTESCOFORM.StornoGombClick(Sender: TObject);
// =============================================================================


begin
  _stornojel := TallozoQuery.FieldByName('STORNO').AsInteger;
  _origbizonylat := TallozoQuery.FieldByName('BIZONYLATSZAM').asString;
  if _stornojel>1 then exit;

  TallozoQuery.Close;

  TallozoDbase.Connected := True;
  if TallozoTranz.InTransaction then TallozoTranz.Commit;
  TallozoTranz.StartTransaction;


  BizBeolvaso(_origbizonylat);

  _bizonylatSzam := GetWuBizszam(_biztip,False);
  _pcs := 'UPDATE ' + _tablanev + ' SET STORNOBIZONYLAT='+chr(39)+_bizonylatszam+chr(39);
  _pcs := _pcs + ',STORNO=2' + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_origbizonylat+chr(39);

  with TallozoQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Execsql;
    end;

  TallozoTranz.Commit;
  TallozoQuery.Close;

  _wuOsszeg := trunc((-1)*_wuosszeg);
  WuKeszletAllito(_biztip,'HUF',_wuOsszeg);

  _bizonylatSzam := GetWuBizszam(_biztip,True);
  WaktualNullazo;

  _kisafa := trunc((-1)*(_afa5+_afa18));
  _nagyafa := trunc((-1)*(_afa20+_afa25));

  _aktidos := GetIdos;


  _pcs := 'INSERT INTO ' + _tablanev + ' (DATUM,IDO,BIZONYLATTIPUS,BIZONYLATSZAM,';
  _pcs := _pcs + 'AFA5SZAZALEKOS,AFA20SZAZALEKOS,OSSZESFORINT,STORNO,SZAMLABRUTTO,';
  _pcs := _pcs + 'SZAMLASZAM,WUGYFELSZAM,WUGYFELNEV,STORNOBIZONYLAT)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktidos + chr(39) + ',';
  _pcs := _pcs + chr(39) + _biztip + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_kisafa) + ',';
  _pcs := _pcs + inttostr(_nagyafa) + ',';
  _pcs := _pcs + inttostr(_wuOsszeg) + ',';
  _pcs := _pcs + '3,';
  _pcs := _pcs + inttostr(_brutto) + ',';
  _pcs := _pcs + chr(39) + _szlaszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_ugyfelszam) + ',';
  _pcs := _pcs + chr(39) + _ugyfelnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _origbizonylat + chr(39)+')';

  ValutaParancs(_pcs);
  _stornojel := 3;

  if (_biztip='B') or (_biztip='K') then
    begin
      AdveszBlokk;
      TallozoQuery.close;
      BizlistPanel.visible := False;
      Fomenu;
      exit;
    end;

  // Afavissza storno:
  _bizkelte := _megnyitottnap;
  StornoblokkNyom;
  MegjPanel.Caption := 'STORNÓ BIZONYLAT';
  TallozoQuery.Close;
  
  BizListPanel.Visible := False;
  Fomenu;
end;


procedure TTescoForm.VonalHuzo;

begin
  writeLn(_LFile,dupestring(' ',39));
end;



// =============================================================================
             procedure TTESCOFORM.NyomtatoGombClick(Sender: TObject);
// =============================================================================

var _spk: integer;

begin

  _spk := supervisorjelszo(0);
  if _spk<>1 then exit;

  _copyBlokk := True;

  _stornojel := TallozoQuery.FieldByName('STORNO').AsInteger;
  _bizonylatszam := TallozoQuery.FieldByName('BIZONYLATSZAM').asString;

  Bizbeolvaso(_bizonylatszam);
  if (_biztip='B') or (_biztip='K') then
    begin
     // _storno := 1;
      AdveszBlokk;
      Activecontrol := Dataracs;
      exit;
    end;

  if _stornojel>1 then
    begin
      StornoBlokkNyom;
      Activecontrol := Dataracs;
      Exit;
    end;

  GetWuData;
  AfaVisszaBlokk;
  _pcs := 'SELECT * FROM '+ _tablanev + _sorveg;
  if _szuro<>'' then _pcs := _pcs + 'WHERE ' + _szuro;
  with TallozoQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;
  Activecontrol := Dataracs;
end;

// =============================================================================
                      procedure TTESCOFORM.StornoBlokkNyom;
// =============================================================================

begin
  BlokkFoCimIro(True);
  writeLn(_Lfile,_widon+'- Storno bizonylat-'+_widoff);
  KozepreIr('AFAVISSZATERITES BIZONYLATA');
  writeLN(_LFILE,'Bizonylat kelte: '+ _bizkelte+ ' ('+_aktidos +')');
  writeLN(_LFile,'Bizonylat szama: '+ _widon+ _bizonylatszam+_widoff);
  VonalHuzo;

  writeLn(_Lfile,'        Ugyfel neve: '+_partnernev);
  writeLn(_Lfile,'      Brutto osszeg: '+ forintform(_brutto)+' Ft');
  writeLN(_LFile,'Kifizetett  5 % AFA: '+ Forintform(_kisafa)+' Ft');
  writeLn(_LFile,'Kifizetett 20 % AfA: '+ ForintForm(_nagyafa)+' Ft');
  VonalHuzo;

  WriteLn(_Lfile,'Kifizetve: '+Forintform(_kisafa+_nagyafa)+' Ft');
  VonalHuzo;

  WriteLN(_Lfile,'Stornozott blokk szama: '+ _origbizonylat);
  writeLn(_Lfile,_sorveg);

  StartNyomtatas;
  _stornojel := 1;
end;


// =============================================================================
             procedure TTESCOFORM.BizBeolvaso(_biznum: string);
// =============================================================================


begin

  _pcs := 'SELECT * FROM '+ _tablanev + _sorveg;

  if _szuro<>'' then
     _pcs := _pcs + 'WHERE '+_szuro+' AND' else  _pcs := _pcs + 'WHERE';

  _pcs := _pcs + ' (BIZONYLATSZAM='+chr(39)+ _biznum + chr(39)+')';

  with TallozoQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;

      First;
      _bizkelte := FieldByName('DATUM').asString;
      _wuosszeg := FieldByName('OSSZESFORINT').asInteger;
      _biztip := FieldByName('BIZONYLATTIPUS').asString;
      _kisafa := FieldByName('AFA5SZAZALEKOS').AsInteger;
      _nagyafa := FieldByNAme('AFA20SZAZALEKOS').AsInteger;
      _ugyfelszam := FieldByName('WUGYFELSZAM').asInteger;
      _ugyfelnev := FieldByName('WUGYFELNEV').AsString;
      _szlaszam := FieldByName('SZAMLASZAM').AsString;
      _brutto := FieldByName('SZAMLABRUTTO').asInteger;
      _partnernev := _ugyfelNev;
    end;
  _origbizonylat := _biznum;  
  if _bizkelte>'2010.09.01' then _aktidos := TallozoQuery.Fieldbyname('IDO').AsString
  else _aktidos := '-';
end;



// =============================================================================
          procedure TTESCOFORM.BizlistVegeGombClick(Sender: TObject);
// =============================================================================

begin

  TallozoQuery.Close;
  BizListPanel.Visible := False;
  Fomenu;
end;

// =============================================================================
               procedure TTESCOFORM.EscGombClick(Sender: TObject);
// =============================================================================

begin
  PillAllasPanel.Visible := False;
  Fomenu;
end;

// =============================================================================
              procedure TTESCOFORM.PenzkeszletList(SENDER:TObject);
// =============================================================================

begin
  _aktidos := GetIdos;
  _aktidos := '('+leftstr(_aktidos,2)+' ora '+midstr(_aktidos,4,2)+' perckor)';

  assignFile(_LFile,'c:\valuta\Aktlst.txt');
  Rewrite(_LFile);
  
  VonalHuzo;

  writeLn(_LFile,'AZ AFAVISSZATERITES FORINTKESZLETE');

  VonalHuzo;
  KozepreIr(lowercase(_megnyitottnap));
  Kozepreir(_aktidos);
  VonalHuzo;

  KozepreIr('Forintkeszlet: '+ forintform(_sumaFA)+' HUF');
  VonalHuzo;
  writeLn(_Lfile,_sorveg);
  StartNyomtatas;

end;


// =============================================================================
           procedure TTESCOFORM.IIATVETGOMBEnter(Sender: TObject);
// =============================================================================

begin
  _aktGomb := TBitbtn(sender);
  _tag := _aktgomb.Tag;

  with _aktGomb.Font do
    begin
      Color := clRed;
      Style := [fsBold];
    end;
end;

// =============================================================================
        procedure TTESCOFORM.IIATVETGOMBExit(Sender: TObject);
// =============================================================================

begin
  _aktGomb := TBitbtn(Sender);
  with _aktGomb.Font do
    begin
      Color := clBlack;
      Style := [];
    
    end;
end;

// =============================================================================
            procedure TTESCOFORM.KILEPESGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;


// =============================================================================
       procedure TTESCOFORM.IIATVETGOMBMouseMove(Sender: TObject;
                                           Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  Activecontrol := TBitbtn(Sender);
end;

// =============================================================================
           procedure TTESCOFORM.VISSZAOKEGOMBEnter(Sender: TObject);
// =============================================================================

begin
  with TBitBtn(Sender).Font do
    begin
      Color := clRed;
      Style := [fsBold];
    end;

end;

// =============================================================================
            procedure TTESCOFORM.VISSZAOKEGOMBExit(Sender: TObject);
// =============================================================================

begin
   with TBitBtn(Sender).Font do
    begin
      Color := clBlack;
      Style := [];
    end;
end;


procedure TTescoFORM.AlapadatBeolvasas;

begin
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _gepfunkcio := FieldByNAme('GEPFUNKCIO').asInteger;
      _megnyitottnap := trim(FieldByNAme('MEGNYITOTTNAP').asString);
      _printer := FieldByNAme('PRINTER').asInteger;
      _kellmetroafa := FieldByNAme('KELLMETROAFA').asInteger;
      Close;

      _cegnev := 'BEST CHANGE ZRT';

      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _homepenztarkod := trim(FieldByNAme('PENZTARKOD').asString);
      _homepenztarnev := trim(FieldByNAme('PENZTARNEV').AsString);
      _homePenztarcim := trim(FieldByNAme('PENZTARCIM').AsString);
      Close;
    end;
  Valutadbase.close;
  _bizkelte := _megnyitottnap;
end;


function TTescoform.Getidos: string;

begin
  result := timetostr(Time);
  if midstr(result,2,1)=':' then result := '0' + result;
end;

function TTescoform.Nulele(_b: integer;_hh: byte): string;

begin
  result := inttostr(_b);
  while length(result)<_hh do result := '0' + result;
end;

// =============================================================================
           function TTescoForm.kerekito(_int: integer): integer;
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
           function TTescoForm.GetWcegNev(_cnum: integer): string;
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
      function TTescoform.GetWuBizszam(_btip: string;_write: boolean): string;
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
             function TTescoForm.ForintForm(_osszeg:integer):string;
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
      Result := _ejel + midStr(Result,1,_pp-1)+' '+midStr(Result,_pp,3)+' '+midStr(Result,_pp+3,3);
      Exit;
    end;

  _pp := _sLen-2;
  Result := _ejel + midStr(result,1,_pp-1)+' '+midStr(result,_pp,3);

end;

// =============================================================================
                        procedure TTescoForm.GetWuKeszlet;
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
      _sumAfa   := FieldByName('OSSZESAFAKESZLET').asInteger;
      _sumMetro := FieldByName('METROAFAKESZLET').asInteger;
      _sumTesco := FieldByName('TESCOAFAKESZLET').asInteger;
      Close;
    end;
  Valutadbase.close;

  if (_sumMetro + _sumTesco)<>_sumafa then _sumAfa := _summetro+_sumTesco;
end;

// =============================================================================
               procedure TTescoForm.HaventSomuch(_vanem:string);
// =============================================================================

begin
  ShowMessage('NINCS ENNYI '+_vanem+' KÉSZLETÜNK');
end;


procedure TTescoForm.Bizregiszter(_xbiz: string);

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
              procedure TTescoForm.PlombaAdatBeolvasas;
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
      procedure TTescoForm.WuKeszletAllito(_btip: string; _vnem: string;
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


procedure TTescoForm.PlombaWrite;

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
                     procedure TTescoForm.KozepreIr(_szoveg: string);
// =============================================================================

var _oo: integer;

begin
  _szoveg := trim(_szoveg);
  _oo := trunc((40-length(_szoveg))/2);
  writeLn(_LFile,dupestring(' ',_oo)+_szoveg);
end;

// =============================================================================
                      procedure TTescoForm.StartNyomtatas;
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
               procedure TTescoFORM.BlokkFocimIro(_kellnyitni: boolean);
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
  Kozepreir('Adoszam: 32313332-2-02');
  
end;


end.
