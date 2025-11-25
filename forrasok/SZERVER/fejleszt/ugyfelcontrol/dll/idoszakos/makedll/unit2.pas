unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery,
  Grids, DBGrids, Buttons, Mask, DBCtrls;

type
  TForm2 = class(TForm)
    BIZFELTETPANEL         : TPanel;
    JOGIUGYFELPANEL        : TPanel;
    IGDATEEDIT             : TEdit;
    INFOPANEL              : TPanel;
    IDOCIMPANEL            : TPanel;
    NUMFELTETPANEL         : TPanel;
    NUMCIMPANEL            : TPanel;
    IDOFELTETPANEL         : TPanel;
    NEVFELTETPANEL         : TPanel;
    NEVCIMPANEL            : TPanel;
    Panel1                 : TPanel;
    Panel2                 : TPanel;
    LIMITPANEL             : TPanel;
    PENZTARPANEL           : TPanel;
    Panel3                 : TPanel;
    NATUGYFELPANEL         : TPanel;
    FELTETELPANEL          : TPanel;
    SZUROPANEL             : TPanel;
    SORRENDPANEL           : TPanel;
    SORRENDGOMB            : TPanel;
    PENZPANEL              : TPanel;
    PTARPANEL              : TPanel;
    RACSPANEL              : TPanel;
    SZUROPANELGOMB         : TPanel;
    SZUROGOMB              : TPanel;
    VISSZAGOMB             : TPanel;

    Label1                 : TLabel;
    Label2                 : TLabel;
    Label3                 : TLabel;
    Label4                 : TLabel;
    Label5                 : TLabel;
    Label6                 : TLabel;
    Label7                 : TLabel;
    Label8                 : TLabel;
    Label9                 : TLabel;
    Label10                : TLabel;
    Label20                : TLabel;
    Label11                : TLabel;
    Label12                : TLabel;
    Label13                : TLabel;
    Label14                : TLabel;
    Label15                : TLabel;
    Label16                : TLabel;
    Label17                : TLabel;
    Label18                : TLabel;
    Label19                : TLabel;
    Label23                : TLabel;
    Label24                : TLabel;
    Label30                : TLabel;
    Label21                : TLabel;
    Label22                : TLabel;
    Label25                : TLabel;
    Label26                : TLabel;
    Label27                : TLabel;
    Label28                : TLabel;

    FIRSTNUMEDIT           : TEdit;
    SORRENDEDIT            : TEdit;
    IGNUMEDIT              : TEdit;
    FELTETEDIT             : TEdit;
    FIRSTDATEEDIT          : TEdit;
    NEVKEZDETEDIT          : TEdit;

    NUMOKEGOMB             : TBitBtn;
    IDORENDBENGOMB         : TBitBtn;
    IDOMEGSEMGOMB          : TBitBtn;
    SZURESRENDBENGOMB      : TBitBtn;
    NEVOKEGOMB             : TBitBtn;
    NEVMEGSEMGOMB          : TBitBtn;
    SZURESMEGSEMGOMB       : TBitBtn;
    BIZRENDBENGOMB         : TBitBtn;
    BIZMEGSEMGOMB          : TBitBtn;
    NUMMEGSEMGOMB          : TBitBtn;

    BIZLATOKQUERY          : TIBQuery;
    BIZLATOKDBASE          : TIBDatabase;
    BIZLATOKTRANZ          : TIBTransaction;

    FEJQUERY               : TIBQuery;
    FEJDBASE               : TIBDatabase;
    FEJTRANZ               : TIBTransaction;

    FEJRACS                : TDBGrid;

    FEJSOURCE              : TDataSource;

    IDOBEFORERadio         : TRadioButton;
    IDOAFTERRadio          : TRadioButton;
    IDOAMONGRadio          : TRadioButton;
    IDOKONKRETRadio        : TRadioButton;
    NUMLESSRadio           : TRadioButton;
    NUMBIGGERRadio         : TRadioButton;
    NUMBETWEENRadio        : TRadioButton;
    NUMKONKRETRadio        : TRadioButton;
    VBetuRadio             : TRadioButton;
    EBETURadio             : TRadioButton;

    FeltetelLista          : TListBox;
    IndexLista             : TListBox;
    Label29: TLabel;
    Label31: TLabel;
    AktIndexEdit: TEdit;
    CondInfoEdit: TEdit;
    TIPUSFELTETPANEL: TPanel;
    Panel4: TPanel;
    ALLUGYFELRADIO: TRadioButton;
    CSAKJOGIRADIO: TRadioButton;
    CSAKNATURRADIO: TRadioButton;
    TIPUSRENDBENGOMB: TBitBtn;
    TIPUSMEGSEMGOMB: TBitBtn;
    DBEdit2: TDBEdit;
    DBEdit3: TDBEdit;
    DBEdit4: TDBEdit;
    DBEdit5: TDBEdit;
    DBEdit6: TDBEdit;
    DBEdit7: TDBEdit;
    DBEdit8: TDBEdit;
    DBEdit9: TDBEdit;
    DBEdit10: TDBEdit;
    DBEdit1: TDBEdit;
    DBEdit11: TDBEdit;
    DBEdit12: TDBEdit;
    DBEdit13: TDBEdit;
    DBEdit14: TDBEdit;
    DBEdit15: TDBEdit;
    DBEdit16: TDBEdit;
    DBEdit17: TDBEdit;
    DBEdit18: TDBEdit;
    DBEdit19: TDBEdit;
    DBEdit20: TDBEdit;
    DBEdit21: TDBEdit;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    DBEdit22: TDBEdit;
    DBEdit23: TDBEdit;
    DBEdit24: TDBEdit;
    DBEdit25: TDBEdit;
    DBEdit26: TDBEdit;
    DBEdit27: TDBEdit;
    FEJQUERYBIZONYLATSZAM: TIBStringField;
    FEJQUERYDATUM: TIBStringField;
    FEJQUERYIDO: TIBStringField;
    FEJQUERYFIZETENDO: TIntegerField;
    FEJQUERYKEZELESIDIJ: TIntegerField;
    FEJQUERYPENZTARSZAM: TSmallintField;
    FEJQUERYPENZTARNEV: TIBStringField;
    FEJQUERYSORSZAM: TIntegerField;
    FEJQUERYPROSID: TIBStringField;
    FEJQUERYNEVTABLA: TIBStringField;
    FEJQUERYVALUTANEM: TIBStringField;
    FEJQUERYBANKJEGY: TIntegerField;
    FEJQUERYARFOLYAM: TIntegerField;
    FEJQUERYELSZAMARF: TIntegerField;
    FEJQUERYFTERTEK: TIntegerField;
    FEJQUERYNEV: TIBStringField;
    FEJQUERYANYJANEVE: TIBStringField;
    FEJQUERYSZULETESIIDO: TIBStringField;
    FEJQUERYSZULETESIHELY: TIBStringField;
    FEJQUERYLAKCIM: TIBStringField;
    FEJQUERYUTOLSOVALTAS: TIBStringField;
    FEJQUERYEVIMAX: TIntegerField;
    FEJQUERYVALTASDB: TSmallintField;
    FEJQUERYOSSZESVALTAS: TIntegerField;
    FEJQUERYKORZET: TSmallintField;
    FEJQUERYKFT: TIBStringField;
    FEJQUERYKEPVISNEV: TIBStringField;
    FEJQUERYMBBEO: TIBStringField;
    FEJQUERYKEPVISBEO: TIBStringField;
    FEJQUERYMEGBIZOTTNEVE: TIBStringField;
    FEJQUERYUGYFELTIPUS: TIBStringField;
    FEJQUERYPENZTAROSNEV: TIBStringField;
    FEJQUERYISO: TIBStringField;
    FEJQUERYMARKER: TSmallintField;
    FEJQUERYCEGNEV: TIBStringField;
    FEJQUERYOKIRATSZAM: TIBStringField;
    FEJQUERYMBSZULIDO: TIBStringField;
    FEJQUERYMBSZULHELY: TIBStringField;
    FEJQUERYMBANYJA: TIBStringField;
    FEJQUERYTELEPHELYCIM: TIBStringField;
    FEJQUERYALLAMPOLGAR: TIBStringField;
    FEJQUERYMBALLAMPOLGAR: TIBStringField;
    FEJQUERYOKMANYTIPUS: TIBStringField;
    FEJQUERYAZONOSITO: TIBStringField;
    FEJQUERYMBOKMTIPUS: TIBStringField;
    FEJQUERYMBAZONOSITO: TIBStringField;
    FEJQUERYCEGORSZAG: TIBStringField;
    FEJQUERYPENZTARCIM: TIBStringField;
    FEJQUERYFOTEVEKENYSEG: TIBStringField;
    KISUGYFELPANEL: TPanel;
    Label32: TLabel;
    Label33: TLabel;
    Label34: TLabel;
    DBEdit28: TDBEdit;
    DBEdit29: TDBEdit;
    DBEdit30: TDBEdit;
    Panel10: TPanel;
    RadioButton1: TRadioButton;
    KISUGYFELNELKULRADIO: TRadioButton;


    procedure FormActivate(Sender: TObject);
    procedure VisszaGombClick(Sender: TObject);
    procedure RacsDisplay;
    procedure Bizonylatvaltas;
    procedure BizonylatFeltet;
    procedure FejRacsCellClick(Column: TColumn);
    procedure FejParancs(_ukaz: string);
    procedure FejRacsDblClick(Sender: TObject);
    procedure FejRacsKeyUp(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure SzuroGombClick(Sender: TObject);
    procedure SetMarker;
    procedure Datumfeltet(_selcondi: string;_leiro: string);
    procedure Numberfeltet(_selcondi: string;_leiro: string);
    procedure SzuresMegsemGombClick(Sender: TObject);
    procedure SorrendGombClick(Sender: TObject);
    procedure SzuroPanelGombClick(Sender: TObject);
    procedure IndexListaDblClick(Sender: TObject);
    procedure SzuresRendbenGOMBClick(Sender: TObject);
    procedure FeltetelListaDblClick(Sender: TObject);
    procedure BizRendbenGombClick(Sender: TObject);
    procedure BizMegsemGombClick(Sender: TObject);
    procedure VBetuRadioClick(Sender: TObject);
    procedure Stringfeltet(_selcondi: string;_leiro: string);
    procedure IdoAmongRadioClick(Sender: TObject);
    procedure FirstDateEditEnter(Sender: TObject);
    procedure FirstDateEditExit(Sender: TObject);
    procedure FirstDateEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure IgDateEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure IdoRendbenGOMBClick(Sender: TObject);
    procedure IdoMegsemGOMBClick(Sender: TObject);
    procedure NumBetweenRadioClick(Sender: TObject);
    procedure FirstNumEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure NumOkeGombClick(Sender: TObject);
    procedure IgNumEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure NevKezdetEditKeyPress(Sender: TObject; var Key: Char);
    procedure NevMegsemGombClick(Sender: TObject);
    procedure NevOkeGombClick(Sender: TObject);
    procedure NUMMEGSEMGOMBClick(Sender: TObject);

    procedure TIPUSRENDBENGOMBClick(Sender: TObject);
    procedure TIPUSMEGSEMGOMBClick(Sender: TObject);
    procedure Tipusfeltet(_selcondi: string;_leiro: string);
    procedure Panel10Click(Sender: TObject);
   

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _honev: array[1..12] of string = ('január','február','március','április',
               'május','junius','július','augusztus','szeptember','október',
               'november','december');

  _indexnev: array[0..14] of string = ('Bizonylatszám','Bizonylat dátuma',
        'Bizonylat ideje','Fizetendö forint','Kezelési dij','Pénztár száma',
        'Valuta neme','Ügyfél neve','Ügyfél anyja','Ügyfél szül-i ideje',
        'Ügyfél szül-i helye','Ügyfél lakcime','Évi max. váltás','Évi össz váltás',
        'Pénztáros neve');

   _indexmezo: array[0..14] of string = ('BIZONYLATSZAM','DATUM','IDO','FIZETENDO',
       'KEZELESIDIJ','PENZTARSZAM','VALUTANEM','NEV','ANYJANEVE','SZULETESIIDO',
       'SZULETESIHELY','LAKCIM','EVIMAX','OSSZESVALTAS','PENZTAROSNEV');

   _vanIndex,_vanfilter: BOOLEAN;

  _top,_left,_height,_width,_kertev,_kertho,_tolnap,_ignap: word;
  _kertdatums,_megnevezes,_fopcs,_bizlat,_pcs,_ugyfeltipus,_utvaltas: string;
  _ptnev,_prosnev,_ugyfelnev,_anyja,_szulido,_szulhely,_lakcim,_iso,_aktindex: string;
  _mbbeo,_mbneve,_kepvisbeo,_kepvisnev,_selmezo,_condi,_selcondi,_condinfo: string;
  _firstdate,_igDate,_aktmezo,_aktleiro,_rel,_firstnums,_ignums,_aktnev,_uresmezo: string;
  _sorveg: string = chr(13)+chr(10);
  _evimax,_eviossz,_xss,_css,_firstnum,_ignum,_code: integer;
  _trdb: byte;

function exceltablakeszites: integer; stdcall; external 'c:\uctrl\bin\makeexcel.dll';
function idoszakoslista: integer; stdcall;


implementation

{$R *.dfm}

// =============================================================================
              function idoszakoslista: integer; stdcall;
// =============================================================================

begin
  Form2 := tform2.Create(Nil);
  result := form2.ShowModal;
  Form2.free;
end;

// =============================================================================
             procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := screen.Monitors[0].Height;
  _width  := screen.Monitors[0].width;

  _top := round((_height-595)/2);
  _left := 8+round((_width-1017)/2);

  top    := _top-50;
  left   := _left;
  width  := 1001;
  height := 537;
  color  := clWhite;

  // ------------------------------------

  _condInfo := '';
  _aktindex := '';
  _uresmezo := chr(39)+chr(39);

  _pcs := 'UPDATE VTEMP SET ORDERMEZO=' + _uresmezo;
  _pcs := _pcs + ',FELTETEL='+_uresmezo;
  _pcs := _pcs + ',INDEXMEZO='+_uresmezo;

  FejParancs(_pcs);

  BizlatokDbase.Connected := true;
  with BizlatokQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM IDOSZAK');
      Open;
      _kertev := FieldByNAme('KERTEV').asInteger;
      _kertho := FieldByNAme('KERTHO').asInteger;
      _tolnap := FieldByNAme('TOLNAP').asInteger;
      _ignap  := FieldByNAme('IGNAP').asInteger;
      Close;
      Sql.clear;
      sql.Add('SELECT * FROM VTEMP');
      Open;
      _megnevezes := trim(FieldByNAme('MEGNEVEZES').AsString);
      Close;
    end;
  BizlatokDbase.close;

  _kertdatums := inttostr(_kertev)+' '+_honev[_kertho]+' '+inttostr(_tolnap)+'-'+inttostr(_ignap);
  LimitPanel.Caption := _kertDatums;

  PenztarPanel.caption := _megnevezes;
  PenztarPanel.repaint;
  _fopcs := 'SELECT * FROM ADATGYUJTO WHERE (MARKER=1)';
  RacsDisplay;
end;

// ================================== ZZZ ======================================
                       procedure TForm2.Racsdisplay;
// =============================================================================

begin
  FejDbase.Connected := true;
  with FejQuery do
    begin
      Close;
      sql.clear;
      sql.add(_fopcs);
      Open;
    end;

  BizonylatValtas;
  Activecontrol := Fejracs;
end;

// =============================================================================
          procedure TForm2.FEJRACSKeyUp(Sender: TObject; var Key:
                                                      Word;Shift: TShiftState);
// =============================================================================

begin
  BizonylatValtas;
end;

// =============================================================================
             procedure TForm2.FEJRACSCellClick(Column: TColumn);
// =============================================================================

begin
  BizonylatValtas;
end;

// =============================================================================
           procedure TForm2.FEJRACSDblClick(Sender: TObject);
// =============================================================================

begin
  BizonylatValtas;
end;

// =============================================================================
                        procedure TForm2.Bizonylatvaltas;
// =============================================================================

begin

  _ugyfeltipus := Fejquery.fieldByName('UGYFELTIPUS').asString;
  if _ugyfeltipus='N' then
    begin
      Jogiugyfelpanel.Visible := False;
      KisUgyfelPanel.visible  := False;
      with Natugyfelpanel do
        begin
          left := 8;
          top :=  40;
          Visible := true;
          repaint;
        end;
    end;

  if _ugyfeltipus='K' then
    begin
      Jogiugyfelpanel.Visible := False;
      NatUgyfelPanel.visible  := False;
      with KisUgyfelpanel do
        begin
          left := 8;
          top :=  40;
          Visible := true;
          repaint;
        end;
    end;

  if _ugyfeltipus='J' then
    begin

      KisUgyfelPanel.visible  := False;
      NatugyfelPanel.visible := False;
      with JogiUgyFelPanel do
        begin
          top := 4;
          left := 8;
          height := 237;
          Visible := true;
          repaint;
        end;
    end;
end;

// =============================================================================
             procedure TForm2.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
           procedure TForm2.SZUROGOMBClick(Sender: TObject);
// =============================================================================

begin
  Fejquery.close;
  FejDbase.close;
  SzuroGomb.Enabled := False;
  with FeltetelPanel do
    begin
      top := 58;
      Left := 16;
      Visible := True;
      repaint;
    end;

end;


// =============================================================================
           procedure TForm2.SZURESMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  SzuroGomb.Enabled := True;
  FeltetelPanel.Visible := False;
  Feltetellista.Enabled := True;
  racsDisplay;
end;

// =============================================================================
           procedure TForm2.SORRENDGOMBClick(Sender: TObject);
// =============================================================================

begin
  FeltetelLista.Visible := False;
  Indexlista.visible := true;
  Infopanel.Left := 104;
  Infopanel.Top := 365;
  Infopanel.Visible := true;
  Activecontrol := IndexLista;
end;

// =============================================================================
           procedure TForm2.SZUROPANELGOMBClick(Sender: TObject);
// =============================================================================

begin
  IndexLista.Visible := False;
  FeltetelLista.Visible := True;
  Infopanel.Left := 450;
  Infopanel.Top := 365;
  Infopanel.Visible := true;

  Activecontrol :=  FeltetelLista;
end;


// =============================================================================
           procedure TForm2.INDEXLISTADblClick(Sender: TObject);
// =============================================================================

begin
  Infopanel.visible := false;
  _XSS := IndexLista.ItemIndex;
  _AKTINDEX := _indexnev[_xss];
  SorrendEdit.Text := _aktindex;
  _selmezo := _indexMezo[_xss];
  Indexlista.Visible := False;
end;

// =============================================================================
          procedure TForm2.SZURESRENDBENGOMBClick(Sender: TObject);
// =============================================================================

begin
  FeltetelLista.Enabled := true;
  if _selmezo<>'' then
    begin
      _fopcs := 'SELECT * FROM ADATGYUJTO' + _sorveg;
      _fopcs := _fopcs + 'WHERE (MARKER=1)' + _sorveg;
      _fopcs := _fopcs + 'ORDER BY ' + _selmezo;
    end;

  Szurogomb.Enabled := true;
  Aktindexedit.Text := _aktindex;
  Condinfoedit.Text := _condinfo;

  _pcs := 'UPDATE VTEMP SET INDEXMEZO='+chr(39)+_aktindex+chr(39);
  _pcs := _pcs + ',FELTETEL='+chr(39)+_condinfo+chr(39);
  _pcs := _pcs + ',ORDERMEZO=' +chr(39)+_selmezo+chr(39);
  Fejparancs(_pcs);
  FeltetelPanel.visible := False;

  RacsDisplay;
end;

// =============================================================================
         procedure TForm2.FELTETELLISTADblClick(Sender: TObject);
// =============================================================================

begin
  Infopanel.Visible := False;
  _css := FeltetelLista.Itemindex;
  FeltetelLista.Enabled := False;
  case _css of
    0: bizonylatfeltet;
    1: datumfeltet('DATUM','BIZONYLAT DÁTUMA');
    2: datumfeltet('IDO','BIZONYLAT KIADÁS IDEJE');
    3: numberfeltet('FIZETENDO','BIZONYLAT VÉGÖSSZEGE');
    4: numberfeltet('KEZELESIDIJ','KEZELÉSI DÍJA');
    5: numberfeltet('PENZTARSZAM','PÉNZTÁR SZÁMA');
    6: stringfeltet('VALUTANEM','VALUTA NEME');
    7: stringfeltet('NEV','ÜGYFÉL NEVE');
    8: stringfeltet('ANYJANEVE','ÜGYFÉL ANYJA NEVE');
    9: datumfeltet('SZULETESIIDO','ÜGYFÉL SZÜLETÉSI IDEJE');
    10: stringfeltet('SZULETESIHELY','ÜGYFÉL SZÜL-I HELYE');
    11: stringfeltet('LAKCIM','ÜGYFÉL CIME');
    12: datumfeltet('UTOLSOVALTAS','UTOLSÓ VÁLTÁS NAPJA');
    13: numberfeltet('EVIMAX','ÉVI LEGNAGYOBB VÁLTÁS');
    14: numberfeltet('OSSZESVALTAS','ÉVI ÖSSZES VÁLTÁS');
    15: stringfeltet('PENZTAROSNEV','PÉNZTÁROS NEVE');
    16: tipusfeltet('UGYFELTIPUS','ÜGYFÉL TIPUSA');
  end;
end;

// =============================================================================
                  procedure Tform2.Bizonylatfeltet;
// =============================================================================

begin
  with Bizfeltetpanel do
    begin
      top := 80;
      left := 264;
      Visible := true;
    end;
end;


// =============================================================================
                  procedure TForm2.SetMarker;
// =============================================================================

begin
  FejQuery.close;
  Fejdbase.close;

  _pcs := 'UPDATE ADATGYUJTO SET MARKER=0';
  FejParancs(_pcs);

  _pcs := 'UPDATE ADATGYUJTO SET MARKER=1' + _sorveg;
  _pcs := _pcs + 'WHERE ' + _condi;
  FejParancs(_pcs);

  Fejdbase.connected := true;
  _pcs := 'SELECT * FROM ADATGYUJTO' + _sorveg;
  _pcs := _pcs + 'WHERE MARKER=1';
  with Fejquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;
end;

// =============================================================================
             procedure TForm2.FejParancs(_ukaz: string);
// =============================================================================

begin
  Fejdbase.connected := true;
  if fejtranz.InTransaction then fejtranz.Commit;
  Fejtranz.StartTransaction;
  with Fejquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Fejtranz.commit;
  Fejdbase.close;
end;

// =============================================================================
           procedure TForm2.BIZRENDBENGOMBClick(Sender: TObject);
// =============================================================================

var _ccd: string;

begin
  _ccd := '';
  if VBeturadio.Checked then _ccd := 'V%';
  if EBeturadio.Checked then _ccd := 'E%';
  BizfeltetPanel.visible := False;
  if _ccd<>'' then
    begin
      _condi := '(BIZONYLATSZAM LIKE ' + chr(39) + _ccd + chr(39) + ')';
      _condinfo := 'Bizonylatszám elsõ betüje = ' + _ccd;
      Feltetedit.Text := _condinfo;
      SetMarker;
    end;
end;

// =============================================================================
           procedure TForm2.BIZMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  FeltetelLista.Enabled := true;
  BizfeltetPanel.visible := False;
end;

// =============================================================================
            procedure TForm2.VBETURADIOClick(Sender: TObject);
// =============================================================================

begin
  Activecontrol := BizRendbengomb;
end;

// =============================================================================
        procedure TForm2.Datumfeltet(_selcondi: string;_leiro: string);
// =============================================================================

begin
  igDateEdit.clear;
  igDateEdit.visible := false;
  IdoCimPanel.caption := _leiro;

  _aktMezo  := _selcondi;
  _aktLeiro := _leiro;

  FirstDateEdit.clear;
  with IdofeltetPanel do
    begin
      top := 80;
      left := 264;
      Visible := true;
    end;
  Activecontrol := Idorendbengomb;
end;

// =============================================================================
          procedure TForm2.Numberfeltet(_selcondi: string;_leiro: string);
// =============================================================================

begin

  IgNumEdit.Visible       := False;

  _aktMezo  := _selcondi;
  _aktLeiro := _leiro;

  Firstnumedit.clear;
  IgnumEdit.clear;
  NumcimPanel.Caption := _aktleiro;

  with NumFeltetPanel do
    begin
      top := 80;
      left := 264;
      Visible := true;
    end;
end;

// =============================================================================
          procedure TForm2.Tipusfeltet(_selcondi: string;_leiro: string);
// =============================================================================

begin

  with TipusFeltetPanel do
    begin
      top := 80;
      left := 264;
      Visible := true;
    end;
  Activecontrol := Tipusrendbengomb;
end;

// =============================================================================
        procedure TForm2.NumBetweenRadioClick(Sender: TObject);
// =============================================================================

begin
  if NumBetweenRadio.Checked then ignumedit.Visible := true
  else ignumEdit.visible := false;
  Activecontrol := FirstNumedit;
end;

// =============================================================================
         procedure TForm2.IDOAMONGRADIOClick(Sender: TObject);
// =============================================================================

begin
  if idoamongRadio.checked then igDateEdit.Visible := True
  else igDateEdit.visible := False;
  Activecontrol := FirstdateEdit;
end;

// =============================================================================
          procedure TForm2.FIRSTDATEEDITEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clYellow;
end;

// =============================================================================
           procedure TForm2.FIRSTDATEEDITExit(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clwindow;
end;

// =============================================================================
    procedure TForm2.FIRSTDATEEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  if idoamongradio.Checked then Activecontrol := igdateEdit
  else activeControl := idoRendbenGomb;
end;

// =============================================================================
       procedure TForm2.IGDATEEDITKeyDown(Sender: TObject; var Key: Word;
// =============================================================================

  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  Activecontrol := idoRendbenGomb;
end;

// =============================================================================
          procedure TForm2.IDORENDBENGOMBClick(Sender: TObject);
// =============================================================================

begin
  _firstDate := trim(FirstDateEdit.text);
  if _firstDate='' then
    begin
      FirstdateEdit.clear;
      ActiveControl := FirstDateEdit;
      exit;
    end;

  if idoAmongradio.checked then
    begin
      _igDate := trim(igDateEdit.text);
      if _igDate='' then
        begin
          igDateEdit.clear;
          Activecontrol := igDateEdit;
          exit;
        end;
    end;

  idofeltetPanel.Visible := False;

  // ------------------------------------------------------------

  if idoamongRadio.Checked then
    begin
      _condi := '(' + _aktmezo + '>=' + chr(39) + _firstDate + chr(39) + ')';
      _condi := _condi + ' AND (' + _aktmezo + '<=' +  chr(39) + _igdate + chr(39) + ')';
      _condinfo := _aktmezo + ' ' + _firstdate +' és '+_igdate+' között';
      Feltetedit.Text := _condinfo;
    end else
    begin
      IF idokonkretradio.checked then
        begin
          _condi := '('+_aktmezo+' LIKE ' +chr(39)+_firstdate+'%'+chr(39)+')';
          _condinfo := _aktmezo+' = ' + _firstdate;
        end else
        begin
          if idobeforeRadio.checked then _rel := '<=';
          if idoafterRadio.Checked then _rel := '>=';
          _condi := '(' + _aktmezo + _rel + chr(39)+_firstdate+chr(39)+')';
          _condinfo := _aktmezo+_rel+_firstdate;
        end;
    end;

  Feltetedit.Text := _condinfo;
  FeltetelLista.visible := False;
  Setmarker;
end;

// =============================================================================
         procedure TForm2.IDOMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  Feltetellista.Enabled := True;
  IdoFeltetPanel.visible := False;
end;

// =============================================================================
     procedure TForm2.FIRSTNUMEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  if NumBetweenRadio.Checked then Activecontrol := Ignumedit
  else ActiveControl := NumOkegomb;
end;

procedure TForm2.TIPUSRENDBENGOMBClick(Sender: TObject);
begin
  TipusfeltetPanel.visible := False;
  if Allugyfelradio.Checked then
    begin
      _condi := '(UGYFELTIPUS='+chr(39)+'N'+chr(39)+') OR (UGYFELTIPUS='+chr(39)+'J'+chr(39)+')';
      _condinfo := 'MINDEN ÜGYFÉLTIPUS';
    end;

  If KisugyfelNelkulRadio.Checked then
    begin
      _condi := 'UGYFELTIPUS<>'+chr(39)+'K'+chr(39);
      _condinfo := 'KISÜGYFELEK NÉLKÜL';
    end;  

  if CsakNaturRadio.Checked then
    begin
      _condi := 'UGYFELTIPUS=' + chr(39)+'N'+chr(39);
      _condinfo := 'CSAK TERMÉSZETES SZEMÉLYEK';
    end;

  if CsakJogiRadio.Checked then
    begin
      _condi := 'UGYFELTIPUS=' + chr(39)+'J'+chr(39);
      _condinfo := 'CSAK JOGI SZEMÉLYEK';
    end;

  Feltetedit.Text := _condinfo;
   FeltetelLista.visible := False;
   Setmarker;
end;



// =============================================================================
           procedure TForm2.NUMOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  NumfeltetPanel.Visible := False;

  _firstNums := trim(FirstNumEdit.text);

  if _firstNums='' then
    begin
      FirstNumEdit.clear;
      ActiveControl := FirstNumEdit;
      exit;
    end;

  if numBetweenradio.checked then
    begin
      _igNums := trim(igNumEdit.text);
      if _igNums='' then
        begin
          igNumEdit.clear;
          Activecontrol := igNumEdit;
          exit;
        end;
    end;

  NumfeltetPanel.Visible := false;

 // ------------------------------------------------------------

  Val(_firstNums,_firstnum,_code);
  if _code<>0 then _firstnum := 0;

  _ignum := 0;
  if _ignums<>'' then
    begin
      val(_ignums,_ignum,_code);
      if _code<>0 then _ignum := 0;
    end;


  if numBetweenRadio.Checked then
    begin
      _condi := '(' + _aktmezo + '>=' + inttostr(_firstnum) + ')';
      _condi := _condi + ' AND (' + _aktmezo + '<=' +  inttostr(_igNum) + ')';
      _condinfo := _condi+' '+inttostr(_firstnum)+' és '+inttostr(_ignum)+' között';
      Feltetedit.Text := _condinfo;
    end else
    begin
      if numlessRadio.checked then _rel := '<=';
      if numbiggerRadio.Checked then _rel := '>=';
      IF numkonkretradio.checked then _rel := '=';

      _condi := '(' + _aktmezo + _rel + inttostr(_firstNum) + ')';
      _condinfo := _aktmezo+_rel+inttostr(_firstnum);
      Feltetedit.Text := _condinfo;
    end;
   FeltetelLista.visible := False;
   Setmarker;
end;

// =============================================================================
      procedure TForm2.IGNUMEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Activecontrol := Numokegomb;
end;

// =============================================================================
        procedure TForm2.Stringfeltet(_selcondi: string;_leiro: string);
// =============================================================================

begin

  _aktMezo  := _selcondi;
  _aktLeiro := _leiro;

  NevcimPanel.caption := _aktleiro;
  NevKezdetEdit.clear;
  with NevFeltetPanel do
    begin
      top := 80;
      left := 264;
      Visible := true;
    end;
  Activecontrol := NevkezdetEdit;
end;

// =============================================================================
    procedure TForm2.NEVKEZDETEDITKeyPress(Sender: TObject; var Key: Char);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Activecontrol := Nevokegomb;
end;

// =============================================================================
          procedure TForm2.NEVMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  Nevfeltetpanel.visible := False;
end;

// =============================================================================
           procedure TForm2.NEVOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _aktnev := trim(NevkezdetEdit.Text);
  if _aktnev='' then
    begin
      Activecontrol := Nevkezdetedit;
      exit;
    end;

  _condi := '('+_aktmezo+' LIKE ' + chr(39)+_aktnev+'%'+CHR(39)+')';
  _condinfo := _aktmezo+' eleje = ' + _aktnev +' ...';
  Feltetedit.Text := _condinfo;
  NevFeltetPanel.Visible := False;
  FeltetelLista.visible := False;
  Setmarker;
end;


procedure TForm2.NUMMEGSEMGOMBClick(Sender: TObject);
begin
  FeltetelLista.Enabled := True;
  NumfeltetPanel.Visible := False;
end;





procedure TForm2.TIPUSMEGSEMGOMBClick(Sender: TObject);
begin
  FeltetelLista.Enabled := True;
  TipusfeltetPanel.visible := False;
end;

procedure TForm2.Panel10Click(Sender: TObject);
begin
  exceltablakeszites;
end;

END.
