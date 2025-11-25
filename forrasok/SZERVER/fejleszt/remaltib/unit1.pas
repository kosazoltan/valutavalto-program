unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, DBCtrls, Buttons, ComCtrls, IBDatabase, DB,
  IBCustomDataSet,Registry, IBQuery, Grids, DBGrids, IBTable, StrUtils,
  jpeg;

type
  TForm1 = class(TForm)
    Panel4: TPanel;
    Panel1: TPanel;
    Panel2: TPanel;
    MNEVPANEL1: TPanel;
    MVALUEEDIT1: TEdit;
    MNEVPANEL2: TPanel;
    MVALUEEDIT2: TEdit;
    MNEVPANEL3: TPanel;
    MVALUEEDIT3: TEdit;
    MTIPPANEL1: TPanel;
    MTIPPANEL2: TPanel;
    MTIPPANEL3: TPanel;
    Panel7: TPanel;
    TABLALISTA: TListBox;
    Panel9: TPanel;
    ADATBAZISNEVPANEL: TPanel;
    DBCOMBO: TComboBox;
    RENDEZESVALASZTO: TGroupBox;
    NINCSRENDEZES: TRadioButton;
    VANRENDEZES: TRadioButton;
    RENDEZESPANEL: TPanel;
    TENDENCIAVALASZTO: TGroupBox;
    NOVEKEDES: TRadioButton;
    CSOKKENES: TRadioButton;
    INDEXMEZO1COMBO: TComboBox;
    INDEXMEZO2COMBO: TComboBox;
    Label3: TLabel;
    INDEXSTART: TBitBtn;
    SZURESVALASZTO: TGroupBox;
    NINCSSZURES: TRadioButton;
    VANSZURES: TRadioButton;
    SZUROPANEL: TPanel;
    Label1: TLabel;
    DBNavigator1: TDBNavigator;
    MVALUEEDIT4: TEdit;
    MVALUEEDIT5: TEdit;
    MVALUEEDIT6: TEdit;
    MVALUEEDIT7: TEdit;
    MVALUEEDIT8: TEdit;
    MTIPPANEL4: TPanel;
    MTIPPANEL5: TPanel;
    MTIPPANEL6: TPanel;
    MTIPPANEL7: TPanel;
    MTIPPANEL8: TPanel;
    MNEVPANEL4: TPanel;
    MNEVPANEL5: TPanel;
    MNEVPANEL6: TPanel;
    MNEVPANEL7: TPanel;
    MNEVPANEL8: TPanel;
    CONDMEZO1: TComboBox;
    RELACIO1: TComboBox;
    CONDMEZO2: TComboBox;
    CONDMEZO3: TComboBox;
    ESVAGY1: TComboBox;
    HASEDIT1: TEdit;
    SZUROSTART: TBitBtn;
    ESVAGY2: TComboBox;
    RELACIO2: TComboBox;
    RELACIO3: TComboBox;
    HASEDIT2: TEdit;
    HASEDIT3: TEdit;
    Panel25: TPanel;
    BitBtn4: TBitBtn;
    BitBtn6: TBitBtn;
    BitBtn7: TBitBtn;
    BitBtn5: TBitBtn;
    QUITGOMB: TBitBtn;
    VALUTAQUERYTABLA: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    VALDATAQUERYTABLA: TIBQuery;
    VALDATADBASE: TIBDatabase;
    VALDATATRANZ: TIBTransaction;
    DBEDITPANEL: TPanel;
    DBEDIT: TDBGrid;
    DBSOURCE: TDataSource;
    IBTABLA: TIBTable;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    MEZOQUERY: TIBQuery;
    MEZODBASE: TIBDatabase;
    MEZOTRANZ: TIBTransaction;
    ADATKIJELZES: TGroupBox;
    RACSOS: TRadioButton;
    TABLAS: TRadioButton;
    INDEXINFOPANEL: TPanel;
    Label2: TLabel;
    FIRSTINDEX: TPanel;
    SECONDINDEX: TPanel;
    Label4: TLabel;
    TENDENCIAPANEL: TPanel;
    Label5: TLabel;
    Label6: TLabel;
    Panel5: TPanel;
    Panel6: TPanel;
    RENDEZESOFFGOMB: TBitBtn;
    Panel8: TPanel;
    INDEXLISTA: TListBox;
    BitBtn1: TBitBtn;
    REKORDTORLESE: TBitBtn;
    KERESOGOMB: TBitBtn;
    KERMEZOCOMBO: TComboBox;
    KEREDIT: TEdit;
    Label7: TLabel;
    FILTERINFOPANEL: TPanel;
    Label8: TLabel;
    FILTERINFOCSIK: TPanel;
    BitBtn2: TBitBtn;
    STARTTIMER: TTimer;
    TAKAROLEMEZ: TPanel;
    IBQuery: TIBQuery;
    JELSZOEDIT: TEdit;
    Label9: TLabel;
    sqlgomb: TBitBtn;
    SQLPARANCSPANEL: TPanel;
    Label10: TLabel;
    OpenDialog1: TOpenDialog;
    dbseekgomb: TBitBtn;
    DBASEPANEL: TPanel;
    PARANCSEDIT: TEdit;
    Label11: TLabel;
    VEGREHAJTOGOMB: TBitBtn;
    KILEPOGOMB: TBitBtn;
    Shape1: TShape;
    PCSQUERY: TIBQuery;
    PCSDBASE: TIBDatabase;
    pcstranz: TIBTransaction;
    Label12: TLabel;
    Shape2: TShape;
    Image1: TImage;

    procedure FdbComboFeltoltes;
    procedure FormCreate(Sender: TObject);
    procedure QUITGOMBClick(Sender: TObject);
    procedure DBCOMBOChange(Sender: TObject);
    procedure TABLALISTAClick(Sender: TObject);
    procedure TablaChange;
    procedure TABLALISTAEnter(Sender: TObject);
    procedure TABLALISTAExit(Sender: TObject);
    procedure DBEDITEnter(Sender: TObject);
    procedure DBEDITExit(Sender: TObject);
    procedure RENDEZESVALASZTOClick(Sender: TObject);
    procedure MezoMeghatarozo;
    procedure TablaTorles;
    procedure TablaBeiras;
    procedure UpScroll;
    procedure DownScroll;
    procedure MasRekord;
    procedure RekordRead;
    procedure Felfele;
    procedure Lefele;
    function AdatControl(_mss: integer; _atag: integer): boolean;
    function GetIndexNev(): integer;
    function VanAltIndex():boolean;

    procedure ADATKIJELZESClick(Sender: TObject);
    procedure MVALUEEDIT1Enter(Sender: TObject);
    procedure MVALUEEDIT1Exit(Sender: TObject);
  
    procedure MVALUEEDIT1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure TABLALISTAKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);

    procedure DBEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);

    procedure DBNavigator1Click(Sender: TObject; Button: TNavigateBtn);
    procedure INDEXMEZO1COMBOChange(Sender: TObject);
    procedure INDEXSTARTClick(Sender: TObject);
    procedure DBNavigator1BeforeAction(Sender: TObject;
      Button: TNavigateBtn);
    procedure MVALUEEDIT1KeyPress(Sender: TObject; var Key: Char);
    procedure RENDEZESOFFGOMBClick(Sender: TObject);
    procedure CancelRendezes;
    procedure BitBtn1Click(Sender: TObject);
    procedure REKORDTORLESEClick(Sender: TObject);
    procedure MVALUEEDIT1Click(Sender: TObject);
    procedure KERMEZOCOMBOChange(Sender: TObject);
    procedure KEREDITEnter(Sender: TObject);
    procedure KEREDITExit(Sender: TObject);
    procedure KERESOGOMBClick(Sender: TObject);
    procedure KEREDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure KERESOGOMBEnter(Sender: TObject);
    procedure KERESOGOMBExit(Sender: TObject);
    procedure NINCSSZURESClick(Sender: TObject);
    procedure CONDMEZO1Enter(Sender: TObject);
    procedure CONDMEZO1Exit(Sender: TObject);
    procedure HASEDIT1Enter(Sender: TObject);
    procedure HASEDIT1Exit(Sender: TObject);
    procedure CONDMEZO1Change(Sender: TObject);
    procedure RELACIO1Change(Sender: TObject);
    procedure HASEDIT1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ESVAGY1Change(Sender: TObject);
    procedure CONDMEZO2Change(Sender: TObject);
    procedure RELACIO2Change(Sender: TObject);
    procedure HASEDIT2KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ESVAGY2Change(Sender: TObject);
    procedure CONDMEZO3Change(Sender: TObject);
    procedure RELACIO3Change(Sender: TObject);
    procedure HASEDIT3KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SZUROSTARTClick(Sender: TObject);
    function GetFeltetel(): string;
    function MakeOneCond(_mz:string;_tp:string;_rs:string;_tx: string):string;
    procedure BitBtn2Click(Sender: TObject);
    procedure FilterOff;
    procedure BitBtn4Click(Sender: TObject);
    procedure BitBtn5Click(Sender: TObject);
    procedure BitBtn6Click(Sender: TObject);
    procedure STARTTIMERTimer(Sender: TObject);
    procedure JELSZOEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure dbseekgombClick(Sender: TObject);
    procedure VEGREHAJTOGOMBClick(Sender: TObject);
    procedure PARANCSEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure KILEPOGOMBClick(Sender: TObject);
    procedure sqlgombClick(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure HASEDIT1Change(Sender: TObject);
    procedure HASEDIT2Change(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _top,_left,_height,_width: integer;

  _alapdir :string = '185.43.207.99:c:\receptor\database\';

  _HOST : string = '185.43.207.99';
  _fdbDarab: word;
  _fdbnev: array[0..1024] of string;
  _tablanev: array[0..600] of string;
  _indexnev: array[0..8] of string;
  _tabladarab,_ix,_cc,_mezoDarab: integer;
  _queryTabla: TIBQuery;
  _rendezes,_szures,_scroll: boolean;
  _mezoNev,_mezotipus: array of string;
  _mezoData: array of string;
  _mezoHossz: array of integer;
  _aktTablaNev,_aktIBNev,_dbaseNev: string;
  _mnevPanel,_mtipPanel: array[1..8] of TPanel;
  _valueEdit: array[1..8] of TEdit;
  _utolsosor,_utolsoMezo,_aktmezoHossz,_sorszam: integer;
  _aktmezonev,_aktmezotip,_aktstring,_aktDbaseNev: string;
  _aktnPanel,_aktTPanel: TPanel;
  _aktVedit: TEdit;
  _lastPanel,_felsoadat,_alsoadat: integer;
  _utnum,_ujnum,_indexDarab: integer;
  _aktsorszam,_indexMezoDarab: integer;
  _aktData,_aktAltIndex,_feltetel: string;
  _rekordValtozas,_megvan: boolean;
  _ujRekord: TBookMark;
  _tag,_aktmezoSorszam,_mezoss: integer;
  _pcs: string;
  _sorveg: string = chr(13)+chr(10);
  _relacio: array[0..5] of string = (' NAGYOBB',' NAGYOBB/EGYENLÕ',' EGYENLÕ',' KISEBB/EGYENLÕ',
                                       ' KISEBB','NEM EGYENLÖ');
  _relstring: array[0..5] of string = ('>','>=','=','<=','<','<>');
   _float: real;
  _mcIndex,_rcIndex,_integer,_code : integer;
  _databaseName,_workdir: string;

  _honapnev: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS',
                        'MÁJUS','JUNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER',
                        'OKTÓBER','NOVEMBER','DECEMBER');

implementation

uses Unit2, Unit3, Unit4, Unit5, Unit6;

{$R *.dfm}


// ========================================================
        procedure TForm1.FormCreate(Sender: TObject);
// ========================================================

var i: integer;

begin
 // _monitordb := Screen.MonitorCount;
  _height := screen.Monitors[0].Height;
  _width := screen.Monitors[0].Width;

  if _height<768 then
    begin
      ShowMessage('A KÉPERNYÖ FELBONTÁSÁT ÁLLÍTSA 1024x768-RA !');
      Application.Terminate;
      Exit;
    end;

  _top := 0;
  _left := 0;

  if (_height>768) then
    begin
      _top := trunc((_height-768)/2);
      _left := trunc((_width-1024)/2);
    end;

     Top := _top;
    Left := _Left;
  Height := 768;
   Width := 1024;
  with takarolemez do
    begin
      Top := 72;
      Left := 5;
      Width := 1024;
      Height := 768;
      Visible := True;
    end;



  RendezesPanel.Visible := False;
  Szuropanel.Visible := False;
  IndexInfoPanel.Visible := False;
  FilterInfoPanel.Visible := False;
  SqlParancsPanel.Visible := false;

  _mNevPanel[1] := MNEVPANEL1;
  _mNevPanel[2] := MNEVPANEL2;
  _mNevPanel[3] := MNEVPANEL3;
  _mNevPanel[4] := MNEVPANEL4;
  _mNevPanel[5] := MNEVPANEL5;
  _mNevPanel[6] := MNEVPANEL6;
  _mNevPanel[7] := MNEVPANEL7;
  _mNevPanel[8] := MNEVPANEL8;

  _mTipPanel[1] := MTIPPANEL1;
  _mTipPanel[2] := MTIPPANEL2;
  _mTipPanel[3] := MTIPPANEL3;
  _mTipPanel[4] := MTIPPANEL4;
  _mTipPanel[5] := MTIPPANEL5;
  _mTipPanel[6] := MTIPPANEL6;
  _mTipPanel[7] := MTIPPANEL7;
  _mTipPanel[8] := MTIPPANEL8;

  _valueEdit[1] := MVALUEEDIT1;
  _valueEdit[2] := MVALUEEDIT2;
  _valueEdit[3] := MVALUEEDIT3;
  _valueEdit[4] := MVALUEEDIT4;
  _valueEdit[5] := MVALUEEDIT5;
  _valueEdit[6] := MVALUEEDIT6;
  _valueEdit[7] := MVALUEEDIT7;
  _valueEdit[8] := MVALUEEDIT8;

  Keredit.Text := '';

  Kermezocombo.clear;
  KermezoCombo.ItemIndex := -1;

  _rendezes := False;
  _szures   :=  False;
  _rekordValtozas := False;

  Esvagy1.Clear;
  EsVagy2.clear;

  Esvagy1.Items.Add(' VAGY');
  Esvagy1.Items.Add('  ÉS');

  Esvagy2.Items.Add(' VAGY');
  Esvagy2.Items.Add('  ÉS');

  Esvagy1.ItemIndex := -1;
  Esvagy2.ItemIndex := -1;

  Relacio1.clear;
  Relacio2.clear;
  Relacio3.clear;

  for i := 0 to 4 do
    begin
      Relacio1.Items.Add(_relacio[i]);
      Relacio2.Items.Add(_relacio[i]);
      Relacio3.Items.Add(_relacio[i]);
    end;

  Hasedit1.Clear;
  Hasedit2.Clear;
  Hasedit3.Clear;

  FdbComboFeltoltes;

  StartTimer.Enabled := True;
end;

// =============================================================================
                procedure TForm1.STARTTIMERTimer(Sender: TObject);
// =============================================================================



begin
  StartTimer.Enabled := false;
  ActiveControl := Jelszoedit;
end;

// =========================================================
        procedure TForm1.QUITGOMBClick(Sender: TObject);
// =========================================================

begin
  Application.Terminate;
end;


// ==========================================================
     procedure TForm1.DBCOMBOChange(Sender: TObject);
// ==========================================================

(*  VÁLTÁS A DATABÁZISOK KÖZÖTT  *)

var
    i: integer;

begin
  _ix := DBCOMBO.ItemIndex;
  _pcs := 'SELECT RDB$RELATION_NAME FROM RDB$RELATIONS ';
  _pcs := _pcs + 'WHERE RDB$FLAGS=1';

  _databaseName := _alapdir + _fdbNev[_ix];

  ibdbase.close;
  ibdbase.DatabaseName := _databaseName;
  ibdbase.Connected := True;
  with Ibquery do
    begin
      Close;
      sql.Clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  // A FDB-ben talált táblázatokat a Tablanev-tömbbe irja:
  // A táblák darabszámát a TABLADARAB változóba teszi:

  _cc := 0;
  while not ibquery.Eof do
    begin
      _tablanev[_cc] := ibquery.FieldbyName('RDB$RELATION_NAME').asString;
      inc(_cc);
      ibquery.Next;
    end;
  _tablaDarab := _cc;
  ibquery.Close;
  ibDbase.close;

  if _tabladarab=0 then
    begin
      ShowMessage('NEM TALÁLOK TÁBLÁKAT !');
      Dbcombo.ItemIndex := 0;
      DBcomboChange(NIL);
      Exit;
    end;  

  // A FDB összes táblanevét a tábla-listába irja:

  TablaLista.Clear;
  for i := 0 to (_tablaDarab-1) do TablaLista.Items.Add(_tablanev[i]);
  TablaLista.ItemIndex := 0;  // Kurzor a legelsõ táblanéven

  Tablachange;
  ActiveControl := TablaLista;
end;


// ==============================================================
        procedure TForm1.TABLALISTAClick(Sender: TObject);
// ==============================================================

begin
  IF  _REKORDvALTOZAS then RogzitesForm.showModal;
  RendezesPanel.Visible := False;
  NincsRendezes.Checked := True;
  Ibtabla.IndexName := '';
  TablaChange;
end;


// ============================================
        procedure TForm1.TablaChange;
// ============================================

  (* Új tábla lett az aktuális *)

var _tablass,i: integer;

begin

   // Az új tábla sorszáma -> a TABLASS:

  FilterOff; 
  _tablass := TablaLista.ItemIndex;
  _aktTablanev := TablaLista.Items[_tablass];
  _aktTablaNev := trim(_akttablanev);
  AdatbazisnevPanel.Caption := _aktTablaNev+' - TÁBLA';

  Ibtabla.Close;

  // ix = 0 -> VALUTA.FDB, ix = 1 -> VALDATA.FDB

  MezoDbase.Connected := false;

  // A DBASE útvonalak beállitása IbTabla és MezoTabla paramétereként

  MezoDbase.DatabaseName := _databasename;

  // Az adatbázis bekapcsolva:

  IBDbase.connected := True;
  MezoDbase.Connected := True;

  // Az IBtábla megnyitása:

  IBtabla.TableName := _aktTablaNev;
  IbTabla.Open;
  iBTABLA.Refresh;

  // Az ibtabla strukturája tömbökbe másolodnak:

  MezoMeghatarozo;

  // A keresés mezõtõmbjét a comboba másolja az esetleges kereséshez:
  KermezoCombo.Clear;

  condMezo1.Clear;
  condMezo2.Clear;
  condMezo3.Clear;

  for i := 1 to _mezodarab do
    begin
      KermezoCombo.Items.Add(_mezoNev[i]);
      CondMezo1.Items.Add(_mezoNev[i]);
      CondMezo2.Items.Add(_mezoNev[i]);
      CondMezo3.Items.Add(_mezoNev[i]);
    end;

  KermezoCombo.ItemIndex := -1;
  CondMezo1.ItemIndex := -1;
  CondMezo2.ItemIndex := -1;
  CondMezo3.ItemIndex := -1;

  Keredit.clear;

  // Az IBtabla elsõ rekordját beolvassa  a MEZODATA tömbbe:
  IBTabla.First;
  RekordRead;

  // Maximum a tábla elsõ 8 adatának beirása az esetleges Táblás kijelzéshez
  TablaBeiras;
end;

// ================================================================
       procedure TForm1.TABLALISTAEnter(Sender: TObject);
// ================================================================

begin
  TablaLista.Color := $00B0FFFF;
end;

// ================================================================
          procedure TForm1.TABLALISTAExit(Sender: TObject);
// ================================================================

begin
  TablaLista.Color := clWindow;
end;

// ================================================================
            procedure TForm1.DBEDITEnter(Sender: TObject);
// ================================================================

begin
  Dbedit.Color := $00B0FFFF;
end;

// ================================================================
         procedure TForm1.DBEDITExit(Sender: TObject);
// ================================================================

begin
  DBEDIT.Color := clWindow;
end;

// ================================================================
       procedure TForm1.RENDEZESVALASZTOClick(Sender: TObject);
// ================================================================

var 
     i: integer;
begin
  IndexStart.Enabled := False;
  IndexInfoPanel.Visible := False;

  if (NincsRendezes.checked) then
    begin
      RendezesPanel.Visible := False;
      IbTabla.IndexFieldNames := '';
      IBTabla.IndexName := '';
      IBtabla.Refresh;
      exit;
    end;

  IndexMezo1Combo.Clear;
  IndexMezo2Combo.Clear;

  for i := 1 to _mezodarab do
    begin
      _aktmezoNev := _mezoNev[i];
      IndexMezo1Combo.Items.Add(_aktmezonev);
      IndexMezo2Combo.Items.Add(_aktmezoNev);
    end;
  IndexMezo1combo.ItemIndex := -1;
  IndexMezo2Combo.ItemIndex := -1;

  Novekedes.Checked := True;
  RendezesPanel.Visible := True;
  ActiveControl := IndexMezo1Combo;
end;

// =============================================
       procedure TForm1.MezoMeghatarozo;
// =============================================


var  _mnev,_mTipus: string;
     _tombMeret: integer;

begin

  // Egy új Tábla strukturájának meghatározása:

  _mezoDarab := ibTabla.FieldCount;
  _tombMeret := _mezodarab+1;

  // A Tábla strukturájának és adatainak tömbjét:

  Setlength(_mezonev,_tombMeret);
  SetLength(_mezotipus,_tombMeret);
  SetLength(_mezoHossz,_tombMeret);
  setlength(_mezoData,_tombMeret);

  // Az SQL parancs-sor összeállitása:


  _pcs := 'SELECT r.RDB$FIELD_NAME AS FIELD_NAME,'+_sorveg;
  _pcs := _pcs + 'r.RDB$DESCRIPTION AS FIELD_DESCRIPTION,'+_sorveg;
  _pcs := _pcs + 'r.RDB$DEFAULT_VALUE as Field_default_value,'+_sorveg;
  _pcs := _pcs + 'r.RDB$NULL_FLAG AS FIELD_NOT_NULL_CONSTRAINT,'+_sorveg;
  _pcs := _pcs + 'f.RDB$FIELD_LENGTH AS FIELD_LENGTH,'+_sorveg;
  _pcs := _pcs + 'f.RDB$FIELD_PRECISION AS FIELD_PRECISION,'+_sorveg;
  _pcs := _pcs + 'f.RDB$FIELD_SCALE AS FIELD_SCALE,'+_SorVeg;
  _pcs := _pcs + 'case f.RDB$Field_type'+_sorveg;
  _pcs := _pcs + 'WHEN 261 THEN '+CHR(39)+'BLOB'+CHR(39) + _sorveg;
  _pcs := _pcs + 'WHEN 14 THEN ' +CHR(39)+ 'SZÖVEG' + CHR(39)+_sorveg;
  _pcs := _pcs + 'WHEN 40 THEN ' +CHR(39)+ 'CSTRING' + CHR(39)+_sorveg;
  _pcs := _pcs + 'WHEN 11 THEN ' +CHR(39)+ 'DFLOAT' + CHR(39)+_sorveg;
  _pcs := _pcs + 'WHEN 27 THEN ' +CHR(39)+ 'TIZEDES TÖRT' + CHR(39)+_sorveg;
  _pcs := _pcs + 'WHEN 10 THEN ' +CHR(39)+ 'FLOAT' + CHR(39)+_sorveg;
  _pcs := _pcs + 'WHEN 16 THEN ' +CHR(39)+ 'INT64' + CHR(39)+_sorveg;
  _pcs := _pcs + 'WHEN 8 THEN ' +CHR(39)+ 'EGÉSZ SZÁM' + CHR(39)+_sorveg;
  _pcs := _pcs + 'WHEN 9 THEN ' +CHR(39)+ 'QUAD' + CHR(39)+_sorveg;
  _pcs := _pcs + 'WHEN 7 THEN ' +CHR(39)+ 'EGÉSZ SZÁM' + CHR(39)+_sorveg;
  _pcs := _pcs + 'WHEN 12 THEN ' +CHR(39)+ 'DÁTUM' + CHR(39)+_sorveg;
  _pcs := _pcs + 'WHEN 13 THEN ' +CHR(39)+ 'IDÕ' + CHR(39)+_sorveg;
  _pcs := _pcs + 'WHEN 35 THEN ' +CHR(39)+ 'TIMESTAMP' + CHR(39)+_sorveg;
  _pcs := _pcs + 'WHEN 37 THEN ' +CHR(39)+ 'VARCHAR' + CHR(39)+_sorveg;
  _pcs := _pcs + 'ELSE ' + chr(39) + 'ISMERTELEN' +CHR(39)+_sorveg;
  _pcs := _pcs + 'END AS FIELD_TYPE,'+ _sorveg;
  _pcs := _pcs + 'f.RDB$FIELD_SUB_TYPE AS FIELD_SUBTYPE,'+ _sorveg;
  _pcs := _pcs + 'coll.RDB$COLLATION_NAME AS FIELD_COLLATION,'+_sorveg;
  _pcs := _pcs + 'cset.RDB$CHARACTER_SET_NAME AS FIELD_CHARSET'+_sorveg;
  _pcs := _pcs + 'FROM RDB$RELATION_FIELDS r'+_sorveg;
  _pcs := _pcs + 'LEFT JOIN RDB$FIELDS f ON r.RDB$FIELD_SOURCE=F.RDB$FIELD_NAME'+_SorVeg;
  _pcs := _pcs + 'LEFT JOIN RDB$COLLATIONS COLL on r.RDB$COLLATION_ID=COLL.RDB$COLLATION_ID'+_SorVeg;
  _pcs := _pcs + 'AND f.RDB$CHARACTER_SET_ID = coll.RDB$CHARACTER_SET_ID'+_sorveg;
  _pcs := _pcs + 'LEFT JOIN RDB$CHARACTER_SETS CSET ON f.RDB$CHARACTER_SET_ID=cset.RDB$CHARACTER_SET_ID'+_SorVeg;
  _pcs := _pcs + 'WHERE r.RDB$RELATION_NAME='+CHR(39)+_aktTablaNev+CHR(39)+_SorVeg;
  _pcs := _pcs + 'ORDER BY r.RDB$FIELD_POSITION'+_SorVeg;

  // A struktura meghatározása az SQL parancs segitségével:

  with MezoQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  // A struktura adatok tömbökbe másolása a QUERYTÁBLÁBÓL:

  _cc := 1;
  while not MezoQuery.Eof do
    begin
      with MezoQuery do
        begin
          _mNev := FieldByName('FIELD_NAME').AsString;
          _mTipus:= FieldByName('FIELD_TYPE').AsString;
          _mezoHossz[_cc] := FieldByName('FIELD_LENGTH').asinteger;
        end;
      _mnev := trim(_mnev);
      _mezoNev[_cc] := _mNev;
      _mezotipus[_cc] := trim(_mTipus);
      inc(_cc);
      MezoQuery.Next;
    end;
  MezoQuery.Close;
end;

// ==========================================
         procedure TForm1.RekordRead;
// =========================================


var i: integer;
   _aktmezo: string;

begin
  for i := 1 to _mezodarab do
    begin
      _aktmezo := _mezonev[i];
      _mezodata[i] := ibTabla.FieldByname(_aktmezo).AsString;
    end;
end;




// ======================================
      procedure TForm1.TablaTorles;
// ======================================

var i: integer;

begin
  for i := 1 to 8 do
    begin
      _aktnPanel := _mNevPanel[i];
      _aktTPanel := _mTipPanel[i];
      _aktVEdit  := _valueEdit[i];

      _aktnPanel.Caption := '';
      _aktTPanel.Caption := '';
      _aktvedit.Clear;
    end;
end;


// =========================================
        procedure TForm1.TablaBeiras;
// =========================================

var i: integer;


begin
  // A 3 adat üresre állitása mind a 8 sorban
  TablaTorles;

  // Default: A legalsó használt adatpanel:8, lehet scrollozni
  _lastPanel := 8;
  _scroll := True;

  // Ha a mezö csak 8 vagy kevesebb: A legalsó használt panel: ahány mezõ van
  // Nem lehet scrollozni !

  if _mezoDarab<9 then
    begin
      _lastpanel := _mezoDarab;
      _scroll := False;
    end;

  // Az elsõlapi adatok bemásolása:
  for i := 1 to _lastpanel do
    begin
      _aktnPanel := _mnevPanel[i];
      _aktTPanel := _mTipPanel[i];
      _aktVedit  := _valueEdit[i];

      _aktMezoNev := _mezonev[i];
      _aktmezotip := _mezotipus[i];
      _aktdata := _mezoData[i];

      _aktnPanel.Caption := _aktmezoNev;
      _aktTPanel.Caption := _aktmezotip;
      _aktvedit.Text := _aktdata;
    end;

  // A felsõ mezõ sorszáma: 1, a legalsó (ha van) 8
  _felsoAdat := 1;
  _alsoAdat := 8;

  // Az aktiv mezö sorszáma=1 ( a legfelsõ)
  _AktMezoSorszam := 1;
end;


// ====================================================================
         procedure TForm1.ADATKIJELZESClick(Sender: TObject);
// ====================================================================

begin
  IF RACSOS.Checked then
    begin
      IF  _REKORDvALTOZAS then RogzitesForm.showModal;
      dbsource.Enabled := True;
      dbeditpanel.Visible := true;
      activecontrol := Dbedit;
    end else
    begin
       RekordRead;
       Tablabeiras;
       dbeditPanel.Visible := false;
       Activecontrol := MValueEdit1;
    end;
end;

// ==============================================================
       procedure TForm1.MVALUEEDIT1Enter(Sender: TObject);
// ==============================================================



begin
  _tag := Tedit(sender).Tag;
  _aktNPanel := _mNevPanel[_tag];
  _aktTPanel := _mTipPanel[_tag];
  _aktVedit := _valueEdit[_Tag];
  with _aktNPanel.Font do
    begin
      color := clNavy;
      style := [fsBOLD];
    end;
  with _aktTPanel.Font do
    begin
      color := clNavy;
      style := [fsBOLD];
    end;
  _AktVEdit.Color := $00B0FFFF;
end;

// ==========================================================
      procedure TForm1.MVALUEEDIT1Exit(Sender: TObject);
// ==========================================================

begin

  // Tag = 1..8 között az edit sorszáma

  _tag := Tedit(sender).Tag;

  // A 3 adat tároló objectuma:
  _aktNPanel := _mNevPanel[_tag];
  _aktTPanel := _mTipPanel[_tag];
  _aktVedit := _valueEdit[_Tag];

  // Az aktuális mezõ sorszámát igy számitom ki:
  _aktMezoSorszam := (_tag+_felsoadat-1);

  if AdatControl(_aktmezosorszam,_tag) then _rekordValtozas := True;

  with _aktNPanel.Font do
    begin
      color := clGray;
      style := [];
    end;
  with _aktTPanel.Font do
    begin
      color := clGray;
      style := [];
    end;
  _AktVEdit.Color := clwindow;

end;


// =================================================================================
         procedure TForm1.MVALUEEDIT1KeyDown(Sender: TObject; var Key: Word;
                                                             Shift: TShiftState);
// =================================================================================


var _bill: integer;

begin
  _tag := TEdit(Sender).Tag;
  _aktMezosorszam := _felsoAdat+_tag-1;
  _bill := ord(key);
  case _bill of
    40: Lefele;

    38: Felfele;
   end;
end;


// ==================================================
        procedure TForm1.Lefele;
// ==================================================

begin

  if (not _scroll) and (_aktMezosorszam=_mezodarab) then exit;
  if _aktMezosorszam<_alsoAdat then
    begin
      inc(_aktMezoSorszam);
      _tag := _aktMezoSorszam - _felsoAdat + 1;
      _aktvedit := _valueEdit[_tag];
      ActiveControl := _aktvEdit;
    end else downScroll;

end;

// ==================================
        procedure TForm1.Felfele;
// ==================================

begin
  if _aktMezosorszam=1 then exit;
  if  _aktmezosorszam>_felsoAdat then
    begin
      dec(_aktmezosorszam);
      _tag := _aktMezoSorszam - _felsoAdat + 1;
      _aktvedit := _valueEdit[_tag];
      ActiveControl := _aktvEdit;
    end else upscroll;
end;

// =========================================
         procedure Tform1.DownScroll;
// =========================================

var i: integer;

begin
  if not _scroll then exit;
  if _alsoadat=_mezoDarab then exit;

  for i :=1 to 7 do
    begin
      _aktNPanel := _mNevPanel[i];
      _aktTPanel := _mTipPanel[i];
      _aktVedit := _valueEdit[i];

      _mezoss := (_felsoAdat+i);
      _aktNPanel.Caption := _mezonev[_mezoss];
      _aktTPanel.Caption := _mezotipus[_mezoss];
      _aktVedit.Text := _mezoData[_mezoss];
    end;

   inc(_felsoAdat);
   inc(_alsoAdat);

   MNevPanel8.caption := _mezonev[_alsoAdat];
   MTipPanel8.Caption := _mezoTipus[_alsoAdat];
   MValueEdit8.Text := _mezoData[_alsoAdat];

   inc(_aktMezoSorszam);
   ActiveControl := MValueEdit8;
end;

// =====================================
       procedure TForm1.UpScroll;
// =====================================

var i: integer;

begin
  if not _Scroll then exit;
  if _felsoAdat=1 then exit;
  dec(_alsoAdat);
  dec(_felsoAdat);

  for i := 1 to 8 do
    begin
      _mezoss := (_felsoAdat-1+i);

      _aktNPanel := _mNevPanel[i];
      _aktTPanel := _mTipPanel[i];
      _aktVedit := _valueEdit[i];

      _aktNPanel.Caption := _mezonev[_mezoss];
      _aktTPanel.Caption := _mezotipus[_mezoss];
      _aktVEdit.Text := _mezoData[_mezoss];
    end;
  Dec(_aktMezoSorszam);
  ActiveControl := MValueEdit1;
end;

// ===========================================================================
      procedure TForm1.TABLALISTAKeyDown(Sender: TObject; var Key: Word;
                                                        Shift: TShiftState);
// ===========================================================================

var _bill,_item: integer;

begin
  _bill := ord(key);

  if (_bill=39) then
    begin
      _item := TablaLista.Itemindex;
      Tablalista.ItemIndex := _item-1;
      if racsos.Checked then ActiveControl := DBEdit
       else ActiveControl := MValueEdit1;
    end;

  if (_bill=13) then
    begin
      if racsos.Checked then ActiveControl := DBEdit
       else ActiveControl := MValueEdit1;
      exit;
    end;
end;


// ============================================================================
        procedure TForm1.DBEDITKeyDown(Sender: TObject; var Key: Word;
                                                      Shift: TShiftState);
// ============================================================================

var _bill,_oszlop: integer;

begin
   _bill := ord(key);
   _oszlop := Dbedit.SelectedIndex;
   if (_bill= 37) and (_oszlop=0) then   // balra
     begin
       ActiveControl := TablaLista;
       Exit;
     end;
end;


// =============================================================================
       function TForm1.AdatControl(_mss: integer; _atag: integer): boolean;
// =============================================================================

VAR _aktText: string;

begin
  (* A 2 paraméter: Rekord Mezõsorszáma és az Edit sorszáma *)

  // Default: nem helyes a bevitt adat:
  Result := false;

  // Az aktuális mezõ értéke:
  _aktData := trim(_mezoData[_mss]);

  // A kötelezõ adathossz:
  _aktMezoHossz := _mezoHossz[_mss];

  // Az aktuális mezõ tipusa:
  _aktMezoTip := _mezoTipus[_mss];

  // Az aktuális mezõ adatának EDIT-je:
  _aktVedit := _valueEdit[_atag];

  // Ha az eredeti adat nem változott, akkor nincs mit tenni:
  _aktText := trim(_aktVedit.Text);
  if _aktData=_aktText then exit;

  // Ha szöveges az adat:
  if _aktmezoTip= 'SZÖVEG' then
    begin
      // Ha a beirt szöveg hosszabb mint az engedélyezett
      // akkor levágjuk a végét:
      if length(_aktText)>_aktmezoHossz then
        begin
          _aktText := leftstr(_aktText,_aktmezoHossz);
          _aktVedit.Text := _aktText;
        end;
      // Az új adat bekerül az mezõadattömbbe
      _mezoData[_mss] := _aktText;
      Result := true;
      Exit;
    end;

  // Ha a mezö tipusa egész szám (integer):
  if (_aktmezoTip='EGÉSZ SZÁM') then
    begin
      val(_akttext,_integer,_code);

      // Ha nem számot irt be, akkor visszairjuk az
      // eredeti adatot az aktuális EDIT-be:
      if _code<>0 then
        begin
          _aktVedit.Text := _aktData;
          exit;
        end;

      // Az uj adat bekerül a mezõadattömbbe:
      _mezodata[_mss] := _aktText;
      Result := True;
      exit;
    end;

  // HA az adat tizedes tört, úgyanúgy bánnunk vele,mint
  // az integerrel, de real számba töltjük az adatot:

  if (_aktmezoTip='TIZEDES TÖRT') then
    begin
      val(_akttext,_FLOAT,_code);
      if _code<>0 then
        begin
          _aktVedit.Text := _aktData;
          exit;
        end;
      _mezodata[_mss] := _aktText;
      Result := True;
      exit;
    end;
END;

// =====================================
      procedure TForm1.Masrekord;
// =====================================

begin
  if Tablas.checked then
    begin
      rekordRead;
      TablaBeiras;
      ActiveControl := MValueEdit1;
    end;
end;

// ==================================================================================
       procedure TForm1.DBNavigator1Click(Sender: TObject; Button: TNavigateBtn);
// ==================================================================================

begin
  MasRekord;
end;

// =====================================================================
       procedure TForm1.INDEXMEZO1COMBOChange(Sender: TObject);
// =====================================================================

begin
  IndexStart.Enabled := true;
  ActiveControl := Indexstart;
end;

// ===============================================
      function TForm1.GetIndexNev(): integer;
// ===============================================

var i,_idarab: integer;

begin
  Result := 0;
  IndexLista.Clear;
  Ibtabla.GetIndexNames(IndexLista.Items);
  _IDarab := IndexLista.Count;
  if _IDarab=0 then exit;
  for i := 0 to _iDarab-1 do
    begin
      _indexNev[i] := IndexLista.Items[i];
    end;
  result := _idarab;
end;


// ======================================================================
          procedure TForm1.INDEXSTARTClick(Sender: TObject);
// ======================================================================

var _emex1ix,_emex2ix: integer;
    _xmezo1,_xmezo2,_xfs: string;

begin
   IndexStart.Enabled := false;
   IBtabla.Close;

// -----------------------------------------------------

  _indexMezoDarab := 0;
  _emex1ix := indexMezo1combo.Itemindex;
  _emex2ix := indexMezo2combo.Itemindex;
  if _emex1ix=_emex2ix then _emex2ix := -1;
  if _emex1ix=-1 then
    begin
      Cancelrendezes;
      Exit;
    end;

   if VanAltIndex() then IBTabla.DeleteIndex(_aktALTINDEX);

// ------ Az indexelendõ mezõk kiemelése ....

  _xmezo1 := _mezonev[_emex1ix+1];
  inc(_indexMezoDarab);
  if _emex2ix>-1 then
    begin
      inc(_indexMezoDarab);
      _xmezo2 := _mezonev[_emex2ix+1];
    end;

  _xfs := _xmezo1;
  if _indexMezoDarab=2 then _xfs := _xmezo1+';'+_xmezo2;

  ibDbase.close;
  ibDbase.Connected := true;
  if ibTranz.InTransaction then Ibtranz.Commit;
  Ibtranz.StartTransaction;

  if Novekedes.Checked then IBtabla.Addindex('ALTX'+_aktTablaNev,_xfs,[])
  else IBtabla.AddIndex('ALTX'+_aktTablaNev,_XFS,[ixDescending]);

  Ibtranz.Commit;


  IbTabla.IndexDefs.Update;

  IBTabla.IndexName := '';
  IF VanAltIndex() then IBtabla.IndexName := 'ALTX'+_aktTablaNev;


// Az index információk kijelzése ....

  SecondIndex.Caption := '-';
  FirstIndex.Caption := _xmezo1;
  If _indexMezoDarab=2 then SecondIndex.Caption := _xmezo2;
  if Csokkenes.Checked then TendenciaPanel.Caption := 'CSÖKKENÕ'
  else TendenciaPanel.Caption := 'NÖVEKEDÕ';
  IndexInfoPanel.Visible := true;
  Ibtabla.Open;
  IbTabla.Refresh;
  Ibtabla.First;

  if Racsos.Checked then dbedit.Repaint;
end;

// ===================================================================
      procedure TForm1.DBNavigator1BeforeAction(Sender: TObject;
                                               Button: TNavigateBtn);
// ===================================================================

begin
  IF  _REKORDvALTOZAS then RogzitesForm.showModal;
end;

// =============================================================================
      procedure TForm1.MVALUEEDIT1KeyPress(Sender: TObject; var Key: Char);
// =============================================================================

begin
  if ord(key)=13 then lefele;
end;

// ================================================================
      procedure TForm1.RENDEZESOFFGOMBClick(Sender: TObject);
// ================================================================

begin
  Cancelrendezes;
end;

// ===========================================
        procedure TForm1.CancelRendezes;
// ===========================================

begin
  Indexinfopanel.visible := False;
  RendezesPanel.visible := False;
  NincsRendezes.checked := True;
  Ibtabla.close;
  ibDbase.Connected := False;
  ibTabla.IndexName := '';
  Ibdbase.Connected := True;
  Ibtabla.Open;
  Ibtabla.Refresh;
  Ibtabla.First;
end;

// =================================================
        function TForm1.VanAltIndex():boolean;
// =================================================

var i: integer;

begin
  Result := False;
  ibTabla.IndexDefs.Update;
  _indexDarab := GetIndexNev();
  if _indexDarab=0 then exit;
  for i := 0 to (_indexDarab-1) do
    begin
      if leftstr(_indexNev[i],4)='ALTX' then
        begin
          _aktaltIndex := _indexNev[i];
          result := True;
          Break;
        end;
    end;
end;

// =============================================================
       procedure TForm1.BitBtn1Click(Sender: TObject);
// =============================================================

begin
  with IBtabla do
    begin
      Close;
      ReadOnly := False;
    end;

  IbDbase.Close;  
  IBdbase.Connected := True;
  if ibTranz.InTransaction then ibTranz.Commit;
  ibTranz.StartTransaction;

  with IbTabla do
    begin
      Open;
      Append;
      edit;
      _ujRekord := GetBookMark;
      Post;
      Close;
    end;
  ibTranz.Commit;

  with ibTabla do
    begin
      ReadOnly := True;
      Open;
      GotoBookMark(_ujrekord);
      FreeBookMark(_ujRekord);
    end;
  ibTabla.Refresh;
end;

// =============================================================
      procedure TForm1.REKORDTORLESEClick(Sender: TObject);
// =============================================================

begin
  RekordTorloForm.ShowModal;
end;

// =============================================================
      procedure TForm1.MVALUEEDIT1Click(Sender: TObject);
// =============================================================

begin
  _tag := TEdit(Sender).Tag;
  _aktMezosorszam := (_tag+_felsoAdat-1);
end;

// =============================================================
        procedure TForm1.KERMEZOCOMBOChange(Sender: TObject);
// =============================================================

begin
  _mcIndex := KermezoCombo.itemindex;
  if (_mcindex>-1) then
    begin
      ActiveControl := Keredit;
    end; 
end;

// =============================================================
        procedure TForm1.KEREDITEnter(Sender: TObject);
// =============================================================

begin
  Keredit.Color := clYellow;
end;

// =============================================================
        procedure TForm1.KEREDITExit(Sender: TObject);
// =============================================================

begin
  Keredit.Color := clWindow;
end;

// =============================================================
         procedure TForm1.KERESOGOMBClick(Sender: TObject);
// =============================================================

var _ktipus,_kMezo,_kstring,_kadat: string;
    _float: real;
    _integer ,_code: integer;
begin
  _mcIndex := KermezoCombo.itemindex;
  if _mcIndex=-1 then
    begin
      ActiveControl := KermezoCombo;
      exit;
    end;

  inc(_mcindex);
  _ktipus := _mezotipus[_mcIndex];
  _kmezo := trim(_mezonev[_mcIndex]);
  _kstring := Trim(Keredit.Text);

  if (_kstring='') and (_ktipus<>'SZÖVEG') then _kstring := '0';

  if _ktipus='SZÖVEG' then _kadat := _kstring;
  if (leftstr(_ktipus,5)='EGÉSZ') then
    begin
      val(_kstring,_integer,_code);
      _kadat := inttostr(_integer);
    end;

  if (leftstr(_ktipus,5)='TIZED') then
    begin
      val(_kstring,_float,_code);
      _kadat := floattostr(_float);
    end;

  if _ktipus = 'SZÖVEG' then
    _megvan := Ibtabla.Locate(_kmezo,_kadat,[loPartialkey])
  else
    _megvan := Ibtabla.Locate(_kmezo,_kadat,[]);

  KerMezoCombo.ItemIndex := -1;
  Keredit.Clear;

  if not _megvan then
    begin
      ShowMessage('NEM TALÁLOM A KERESETT ADATOT !');
      IBtabla.First;
      Exit;
    end;
  if racsos.Checked then ActiveControl := Dbedit else ActiveControl := MValueEdit1;

end;

// ============================================================================
     procedure TForm1.KEREDITKeyDown(Sender: TObject; var Key: Word;
                                                       Shift: TShiftState);
// ============================================================================

begin
  if ord(key)=13 then activecontrol := KeresoGomb;
end;

// =============================================================
       procedure TForm1.KERESOGOMBEnter(Sender: TObject);
// =============================================================

begin
  KeresoGomb.Font.Color := clNavy;
  KeresoGomb.Font.Style := [fsBold];
end;

// =============================================================
        procedure TForm1.KERESOGOMBExit(Sender: TObject);
// =============================================================

begin
  KeresoGomb.Font.Color := clGray;
  KeresoGomb.Font.Style := [];
end;

// =============================================================
         procedure TForm1.NINCSSZURESClick(Sender: TObject);
// =============================================================

begin
  if Vanszures.Checked then
    begin
      Esvagy1.ItemIndex := -1;
      Esvagy2.ItemIndex := -1;

      Condmezo1.ItemIndex := -1;
      Condmezo2.ItemIndex := -1;
      Condmezo3.ItemIndex := -1;

      Relacio1.ItemIndex := 2;
      Relacio2.ItemIndex := -1;
      Relacio3.ItemIndex := -1;

      Hasedit1.Clear;
      Hasedit2.Clear;
      Hasedit3.Clear;

      Esvagy1.Enabled := false;
      Esvagy2.Enabled := false;

      CondMezo2.Enabled := False;
      CondMezo3.Enabled := False;

      Relacio2.Enabled := False;
      Relacio3.Enabled := False;

      SzuroPanel.Visible := true;
      ActiveControl := Condmezo1;
    end;

  if Nincsszures.Checked then FilterOff;

end;

// =============================================================
       procedure TForm1.CONDMEZO1Enter(Sender: TObject);
// =============================================================

begin
  TCombobox(sender).Color := clYellow;
end;

// =============================================================
         procedure TForm1.CONDMEZO1Exit(Sender: TObject);
// =============================================================

begin
  TCombobox(sender).Color := clWindow;
end;

// =============================================================
       procedure TForm1.HASEDIT1Enter(Sender: TObject);
// =============================================================

begin
  TEdit(sender).Color := clYellow;
end;

// =============================================================
         procedure TForm1.HASEDIT1Exit(Sender: TObject);
// =============================================================

begin
  Tedit(Sender).Color := clWIndow;
end;

// =============================================================
        procedure TForm1.CONDMEZO1Change(Sender: TObject);
// =============================================================

begin
  Relacio1.Enabled := True;
  ActiveControl := Hasedit1;
end;

// =============================================================
        procedure TForm1.RELACIO1Change(Sender: TObject);
// =============================================================

begin
  ActiveControl := hasedit1;
end;

// ==========================================================================
      procedure TForm1.HASEDIT1KeyDown(Sender: TObject; var Key: Word;
                                                       Shift: TShiftState);
// ==========================================================================

begin
  if ord(key)<>13 then exit;
 
  Esvagy1.Enabled := true;
  ActiveControl := Szurostart;
end;

// =============================================================
        procedure TForm1.ESVAGY1Change(Sender: TObject);
// =============================================================

begin
  Condmezo2.Enabled := True;
  Activecontrol := Condmezo2;
end;

// =============================================================
        procedure TForm1.CONDMEZO2Change(Sender: TObject);
// =============================================================

begin
  Relacio2.ItemIndex := 2;
  Relacio2.Enabled := true;
  Hasedit2.Enabled := true;
  Activecontrol :=hasedit2;
end;

// =============================================================
        procedure TForm1.RELACIO2Change(Sender: TObject);
// =============================================================

begin
  Hasedit2.Enabled := true;
  Activecontrol := hasedit2;
end;

// ==========================================================================
      procedure TForm1.HASEDIT2KeyDown(Sender: TObject; var Key: Word;
                                                     Shift: TShiftState);
// ==========================================================================

begin
  if ord(key)<>13 then exit;
  EsVagy2.Enabled := true;
  ActiveControl := SzuroStart;
end;

// =============================================================
       procedure TForm1.ESVAGY2Change(Sender: TObject);
// =============================================================

begin
  CondMezo3.Enabled := True;
  ActiveControl := CondMezo3;
end;

// =============================================================
       procedure TForm1.CONDMEZO3Change(Sender: TObject);
// =============================================================

begin
  Relacio3.ItemIndex := 2;
  Relacio3.Enabled := true;
  Hasedit3.Enabled := true;
  ActiveControl := Hasedit3;
end;

// =============================================================
       procedure TForm1.RELACIO3Change(Sender: TObject);
// =============================================================

begin
  Hasedit3.Enabled := true;
  ActiveControl := Hasedit3;
end;

// ==========================================================================
     procedure TForm1.HASEDIT3KeyDown(Sender: TObject; var Key: Word;
                                                      Shift: TShiftState);
// ==========================================================================

begin
  if ord(key)<>13 then exit;
  Activecontrol := szuroStart;
end;

// =============================================================
       procedure TForm1.SZUROSTARTClick(Sender: TObject);
// =============================================================


begin
   _feltetel := GetFeltetel();
   if _feltetel='' then
     begin
       FilterOff;
       Exit;
     end;  

   SzuroPanel.Visible := False;
   FilterInfoCsik.Caption := _feltetel;
   FilterInfoPanel.Visible := true;


   Ibtabla.Filter := _feltetel;
   IbTabla.Filtered := True;
   Ibtabla.Refresh;
   Ibtabla.First;
end;



// =============================================================
          function TForm1.GetFeltetel(): string;
// =============================================================


var _cix1,_cix2,_cix3: integer;
    _rix1,_rix2,_rix3: integer;
        _evix1,_evix2: integer;
    _has1,_has2,_has3,_part2,_part3: string;
    _szint : integer;
    _m1,_m2,_M3,_r1,_r2,_r3,_t1,_t2,_t3: string;

begin
  Result := '';

  _cix1 := Condmezo1.ItemIndex;
  _cix2 := Condmezo2.ItemIndex;
  _cix3 := Condmezo3.ItemIndex;

  _rix1 := Relacio1.ItemIndex;
  _rix2 := Relacio2.ItemIndex;
  _rix3 := Relacio3.ItemIndex;

  _evix1 := esvagy1.ItemIndex;
  _evix2 := esvagy2.ItemIndex;

  _has1 := Hasedit1.Text;
  _has2 := Hasedit2.Text;
  _has3 := Hasedit3.Text;

  if (_cix1=-1) or  (_rix1=-1) then exit;

  inc(_cix1);
  _szint := 1;
  _m1 := _mezonev[_cix1];
  _r1 := _relstring[_rix1];
  _t1 := _mezotipus[_cix1];

  if (_cix2>-1) and (_rix2>-1) and (_evix1>-1) then
    begin
      _szint := 2;
      inc(_cix2);
      _m2 := _mezonev[_cix2];
      _t2 := _mezotipus[_cix2];
      _r2 := _relstring[_rix2];
      if (_cix3>-1) and (_rix3>-1) and (_evix2>-1) then
        begin
          _szint := 3;
          inc(_cix3);
          _m3 := _mezonev[_cix3];
          _t3 := _mezotipus[_cix3];
          _r3 := _relstring[_rix3];
        end;
    end;
  result := MakeOneCond(_m1,_t1,_r1,_has1);
  if _szint>1 then
    begin
      _part2 := MakeOneCond(_m2,_t2,_r2,_has2);
      if _evix1=0 then result := result + ' OR ' + _PART2
      else  result := result + ' AND ' + _PART2;
    end;
  if _szint=3 then
    begin
      _part3 := MakeOneCond(_m3,_t3,_r3,_has3);
      if _evix2=0 then result := result + ' OR ' + _PART3
      else  result := result + ' AND ' + _PART3;
    end;
end;


// ===================================================================================
    function TForm1.MakeOneCond(_mz:string;_tp:string;_rs:string;_tx: string):string;
// ===================================================================================

begin

  result := '(' + _mz + _rs;
  if _tp='SZÖVEG' then
    begin
      if _tx='' then
        begin
          if _rs='=' then  Result := '('+_mz+' IS NULL)';
          if _rs='<>' then Result := '('+_mz+' IS NOT NULL)';
          Exit;
        end;

      _tx := Trim(_tx);
      if _rs='=' then
        begin
          Result := '('+_mz+' LIKE '+ chr(39) + _tx+ '%'+chr(39)+')';
          exit;
        end;
      result := Result + chr(39)+trim(_tx)+chr(39)+')';
      exit;
    end;

  if leftstr(_tp,5)='EGÉSZ' then
    begin
      val(_tx,_integer,_code);
      if _code<>0 then _integer := 0;
      Result := result +inttostr(_integer)+')';
      Exit;
    end;

  val(_tx,_float,_code);
  if _code<>0 then _float:=0;
  Result := Result + floattostr(_float)+')';
end;

// ===================================================
     procedure TForm1.BitBtn2Click(Sender: TObject);
// ===================================================

begin
  FilterOff;
end;

// ====================================
      procedure TForm1.FilterOff;
// ====================================


begin
  FilterInfoPanel.Visible := false;
  SzuroPanel.Visible := False;
  NincsSzures.checked := True;
  if not Ibtabla.Active then exit;
  IBtabla.Filtered := false;
  IbTabla.Filter := '';
  Ibtabla.Refresh;
  IbTabla.First;
end;


procedure TForm1.BitBtn4Click(Sender: TObject);
begin
  ZappoloForm.ShowModal;
  TablaChange;
end;

procedure TForm1.BitBtn5Click(Sender: TObject);
begin
  SzamSumma.showModal; 
end;

procedure TForm1.BitBtn6Click(Sender: TObject);
begin
  MezotoltoForm.ShowModal;
end;




procedure TForm1.JELSZOEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  IF ord(key)<>13 then exit;
  if trim(Jelszoedit.text)= '628' then
    begin
      TakaroLemez.Visible := False;
      dbcombo.ItemIndex := 0;
      DBComboChange(DBCombo);
    end;
end;

procedure TForm1.dbseekgombClick(Sender: TObject);
var _dbpath: string;
begin
  if Opendialog1.Execute then
    begin
      _dbPath := Opendialog1.FileName;
      pcsdbase.close;
      pcsdbase.DatabaseName := _dbPath;
    end;
  Dbasepanel.Caption := _dbPath;
  Dbasepanel.Repaint;
end;



procedure TForm1.VEGREHAJTOGOMBClick(Sender: TObject);
begin
  if dbasepanel.Caption='' then exit;
  _pcs := trim(Parancsedit.text);

  if _pcs = '' then exit;

  pcsdbase.Connected := true;
  if pcstranz.InTransaction then pcstranz.commit;
  pcstranz.StartTransaction;
  with pcsQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Execsql;
    end;
  PcsTranz.Commit;
  pcsdbase.close;
  Parancsedit.Text := 'VÉGREHAJTVA !';
  pARANCSEDIT.REPAINT;
  SLEEP(1500);
  sQLPARANCSpANEL.Visible := false;

end;

procedure TForm1.PARANCSEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  IF ORD(KEY)<>13 THEN EXIT;
  Activecontrol := Vegrehajtogomb;
end;

procedure TForm1.KILEPOGOMBClick(Sender: TObject);
begin
  SqlParancsPanel.Visible := false;
end;

procedure TForm1.sqlgombClick(Sender: TObject);
begin
  DbasePanel.Caption := '';
  Parancsedit.clear;
  with SqlParancsPanel do
    begin
      top := 300;
      Left := 90;
      Visible := true;
    end;
  Activecontrol := dbseekgomb;  
end;

procedure TForm1.Image1Click(Sender: TObject);
begin
  TakaroLemez.Visible := False;
  dbcombo.ItemIndex := 0;
  DBComboChange(DBCombo);
end;



procedure TForm1.HASEDIT1Change(Sender: TObject);
begin
  Esvagy1.Enabled := true;
end;

procedure TForm1.HASEDIT2Change(Sender: TObject);
begin
  Esvagy2.Enabled := true;
end;

procedure TForm1.FdbComboFeltoltes;

var _srec: TSearchrec;
    _y : word;
    _minta: string;

begin
  dbCombo.items.clear;

  {
  _fdbDarab := 0;
  _minta := _alapdir + '*.FDB';
  if FindFirst(_minta, faAnyfile, _srec) = 0 then
    begin
      repeat
        _fdbNev[_fdbDarab] := _sRec.Name;
        inc(_fdbDarab);
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;

  if _fdbDarab=0 then
    begin
      ShowMessage('NEM TALÁLTAM ADATBÁZISOKAT');
      Application.Terminate;
      exit;
    end;

  _y := 0;
  while _y<_fdbDarab do
    begin
      dbCombo.items.add(_fdbNev[_y]);
      inc(_y);
    end;
  }

  _FDBNEV[0] := 'UGYFEL19.fdb';
  dbcombo.Items.Add('UGYFEL19');
  dbCombo.Itemindex := 0;
end;



end.

