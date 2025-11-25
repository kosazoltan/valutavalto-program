unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, IBDatabase, DB, IBCustomDataSet,
  IBQuery,DateUtils, ComCtrls, Grids, DBGrids, strutils, jpeg;

type
  TForm2 = class(TForm)

    Image1              : TImage;

    AthozoGomb          : TPanel;
    AthozoPanel         : TPanel;
    GombTakaroPanel     : TPanel;
    GTakaroPanel        : TPanel;
    UJJOGIPANEL: TPanel;
    JogiValDataIN       : TPanel;
    JogiLista           : TPanel;
    JogiListazoPanel    : TPanel;
    LastYearGomb        : TPanel;
    ListaGomb           : TPanel;
    LetiltoGomb         : TPanel;
    LetiltoPanel        : TPanel;
    LakcimPanel         : TPanel;
    LevalogatoPanel     : TPanel;
    LevalCimPanel       : TPanel;
    NaturLista          : TPanel;
    NaturListazoPanel   : TPanel;
    UjNaturPanel        : TPanel;
    NatValDataIn        : TPanel;
    OldJogiPanel        : TPanel;
    OldNaturPanel       : TPanel;
    Panel1              : TPanel;
    Panel2              : TPanel;
    TJogiGomb           : TPanel;
    TiltoMenuPanel      : TPanel;
    TipusValasztoPanel  : TPanel;
    TNaturGomb          : TPanel;
    UjRegiPanel         : TPanel;
    VisszaGomb          : TPanel;
    YearGomb            : TPanel;

    LocJogiQuery        : TIBQuery;
    LocJogiDbase        : TIBDatabase;
    LocJogiTranz        : TIBTransaction;

    LocNaturQuery       : TIBQuery;
    LocNaturDbase       : TIBDatabase;
    LocNaturTranz       : TIBTransaction;

    RemJogiQuery        : TIBQuery;
    RemJogiDbase        : TIBDatabase;
    RemJogiTranz        : TIBTransaction;

    RemQuery            : TibQuery;
    RemDbase            : TibDatabase;
    RemTranz            : TibTransaction;

    JogiListaRacs       : TDBGrid;
    JogiRacs            : TDBGrid;
    NaturRacs           : TDBGrid;
    NaturListaRacs      : TDBGrid;

    LocJogiSource       : TDataSource;
    LocNaturSource      : TDataSource;
    RemJogiSource       : TDataSource;
    RemNaturSource      : TDataSource;

    AthozStartGomb      : TBitBtn;
    AthozMegsemGomb     : TBitBtn;
    ForrasGomb          : TBitBtn;
    JogiGomb            : TBitBtn;
    JogiDataOkeGomb     : TBitBtn;
    JogiVisszaVonoGomb  : TBitBtn;
    JogiListaVisszaGomb : TBitBtn;
    JogiLetiltoGomb     : TBitBtn;
    JogiValMegsemGomb   : TBitBtn;
    JogiListaTiltoGomb  : TBitBtn;
    JogiListaMegsemGomb : TBitBtn;
    MegsemGomb          : TBitBtn;
    NaturVisszaVonoGomb : TBitBtn;
    NaturListaVisszaGomb: TBitBtn;
    NaturGomb           : TBitBtn;
    NatValOkeGomb       : TBitBtn;
    NatValMegsemGomb    : TBitBtn;
    NatLetiltoGomb      : TBitBtn;
    NewGomb             : TBitBtn;
    NLMegsemGomb        : TBitBtn;
    OldGomb             : TBitBtn;
    PenzForrasGomb      : TBitBtn;
    TiltoGomb           : TBitBtn;
    TRendbenGomb        : TBitBtn;
    TMegsemGomb         : TBitBtn;

    Shape1              : TShape;
    Shape2              : TShape;
    Shape3              : TShape;
    Shape4              : TShape;

    LocMemo             : TMemo;
    RemMemo             : TMemo;

    KBLabel             : TLabel;
    Label1              : TLabel;
    Label2              : TLabel;
    Label3              : TLabel;
    Label4              : TLabel;
    Label5              : TLabel;
    Label6              : TLabel;
    Label7              : TLabel;
    Label8              : TLabel;
    Label9              : TLabel;
    Label10             : TLabel;
    Label11             : TLabel;
    Label12             : TLabel;
    Label13             : TLabel;
    Label14             : TLabel;
    Label15             : TLabel;
    Label16             : TLabel;
    Label17             : TLabel;
    Label18             : TLabel;
    Label19             : TLabel;
    Label20             : TLabel;
    Label21             : TLabel;
    Label22             : TLabel;
    Label23             : TLabel;
    Label24             : TLabel;
    Label25             : TLabel;
    Label26             : TLabel;
    Label27             : TLabel;

    Csik                : TProgressBar;
    LevalCsik           : TProgressBar;

    AktJogiNevEdit      : TEdit;
    AnyjaEdit           : TEdit;
    BetuEdit            : TEdit;
    JLKerEdit           : TEdit;
    jNevEdit            : TEdit;
    jTelephelyEdit      : TEdit;
    jFotevEdit          : TEdit;
    JogiNevEdit         : TEdit;
    jKerEdit            : TEdit;
    jOkiratEdit         : TEdit;
    JMBNevEdit          : TEdit;
    KerEdit             : TEdit;
    LakcimEdit          : TEdit;
    NaturNevEdit        : TEdit;
    NevEdit             : TEdit;
    RNKerEdit           : TEdit;
    SzulhelyEdit        : TEdit;
    SzulidoEdit         : TEdit;
    Label28: TLabel;
    NATNEVEDIT: TEdit;
    JOGIFORRASGOMB: TBitBtn;
    UJJOGIFORRASGOMB: TBitBtn;

    procedure AktJogiNevDisplay;
    procedure AnyjaEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure AthozoGombClick(Sender: TObject);
    procedure AthozMegsemGombClick(Sender: TObject);
    procedure BetuEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormActivate(Sender: TObject);
    procedure ForrasGombClick(Sender: TObject);
    procedure LastYearGombClick(Sender: TObject);
    procedure LetiltoGombClick(Sender: TObject);
    procedure LocJogiParancs(_ukaz: string);
    procedure LocNaturParancs(_ukaz: string);
    procedure LocNaturParancsPart(_ukaz: string);
    procedure LocJogiParancsPart(_ukaz: string);
    procedure Levalogatas;
    procedure ListaGombClick(Sender: TObject);
    procedure JogiLevalogatas;
    procedure JogiTiltottListazas;
    procedure JogiRacsKeyUp(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure JogiListaVisszaGombClick(Sender: TObject);
    procedure JogiRacsDblClick(Sender: TObject);
    procedure JogiRacsCellClick(Column: TColumn);
    procedure JogiGombClick(Sender: TObject);
    procedure JogiVisszaVonoGombClick(Sender: TObject);
    procedure JNevEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure JTelephelyEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure JFotevEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure JogiAdatKimasolo;
    procedure JogiAdatBemasolo;
    procedure JogiListaRacsKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure JogiListaRacsCellClick(Column: TColumn);
    procedure JogiListaRacsDblClick(Sender: TObject);
    procedure JOkiratEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure JMbNevEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure JogiLetiltoGombClick(Sender: TObject);
    procedure JogiDataOkeGombClick(Sender: TObject);
    procedure JogiracsNevDisplay;
    procedure MegsemGombClick(Sender: TObject);
    procedure Menube;
    procedure NatListaNevDisplay;
    procedure NaturGombClick(Sender: TObject);
    procedure NaturAdatKimasolo;
    procedure NaturAdatBemasolo;
    procedure NaturLevalogatas;
    procedure NaturListaRacsDblClick(Sender: TObject);
    procedure NaturListaRacsKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure NaturTiltottlistazas;
    procedure NaturRacsKeyUp(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure NaturRacsDblClick(Sender: TObject);
    procedure NaturRacsCellClick(Column: TColumn);
    procedure NaturListaVisszaGombClick(Sender: TObject);
    procedure NaturVisszaVonoGombClick(Sender: TObject);
    procedure NatValOkeGombClick(Sender: TObject);
    procedure NatValMegsemGOMBClick(Sender: TObject);
    procedure NatLetiltoGombClick(Sender: TObject);
    procedure NaturRacsNevDisplay;
    procedure NevEditEnter(Sender: TObject);
    procedure NevEditExit(Sender: TObject);
    procedure NevEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure NLMegsemGombClick(Sender: TObject);
    procedure OldJogivalasztas;
    procedure Oldgombclick(Sender: TObject);
    procedure OldNaturValasztas;
    procedure PenzForrasGombClick(Sender: TObject);
    procedure RembeMasolas;
    procedure RemoteParancs(_ukaz: string);
    procedure SzulhelyEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure SzulidoEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TNaturGombClick(Sender: TObject);
    procedure TiltoGombClick(Sender: TObject);
    procedure TiltoMasolas;
    procedure TJogiGombClick(Sender: TObject);
    procedure TMegsemGombClick(Sender: TObject);
    procedure TRendbenGombClick(Sender: TObject);
    procedure UgyfelLetiltas;
    procedure UjNaturUgyfel;
    procedure UjJogiUgyfel;
    procedure VisszaGombClick(Sender: TObject);
    procedure YearGombClick(Sender: TObject);

    function Angolra(_huName: string): string;
    function HutoGb(_kod: byte): byte;
    function Tomorito(_ts: string): string;
    procedure NATURLISTARACSCellClick(Column: TColumn);
    procedure NEWGOMBClick(Sender: TObject);
    procedure JOGIVALMEGSEMGOMBClick(Sender: TObject);
    procedure JOGILISTATILTOGOMBClick(Sender: TObject);
    procedure JOGIFORRASGOMBClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _vanletiltas,_ezuj,_megvan: boolean;

  _asc,_tiltva,_nltiltva,_first,_bill,_wlen,_kulfoldi,_kozszerep: byte;
  _height,_width,_top,_left,_year,_lastyear,_kertev,_iden,_tavaly: word;
  _recno,_sorszam,_nlsorszam,_jogisorszam,_jogitiltva,_natsorszam: integer;

  _ttipus,_evtizes,_aktfdb,_remotePath,_pcs,_tablanev,_nev,_anyja,_jnev: string;
  _szulhely,_szulido,_telephely,_fotev,_mbneve,_lakcim,_jogiszemelynev: string;
  _nevtabla,_fdbpath,_unev,_uanyja,_uszulhely,_uszulido,_lastmezo,_jkeress: string;
  _jtelep,_jFotev,_jOkirat,_jMbnev,_kbetu,_Lmezo,_nlNev,_keress,_ujkeress: string;
  _joginev,_natnev,_ideiDekads,_tavalyiDekads,_ideiFdb,_tavalyiFdb,_kb: string;
  _elozonev,_leanykori,_allampolg,_okmanytip,_azonosito,_lcimcard,_iso: string;

  _sorveg: string = chr(13)+chr(10);
  _host  : string = '185.43.207.99';

function tiltaskezelorutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
             function tiltaskezelorutin: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.ShowModal;
  form2.Free;
end;


// =============================================================================
             procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;

  _top    := round((_height-595)/2);
  _left   := round((_width-1017)/2);

  Top     := _top;
  Left    := _left+48;
  width   := 906;
  Height  := 452;

  Menube;
end;

// =============================================================================
                         procedure TForm2.Menube;
// =============================================================================

begin
  with tiltomenupanel do
    begin
      top := 80;
      left := 260;
      Visible := true;
      repaint;
    end;
  Activecontrol := Listagomb;
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
            procedure TForm2.ListaGombClick(Sender: TObject);
// =============================================================================

begin
  TiltoMenuPanel.Visible := False;

  with TipusValasztoPanel do
    begin
      Top     := 40;
      Left    := 200;
      Visible := true;
      Repaint;
    end;
  ActiveControl := NaturGomb;
end;

// =============================================================================
               procedure TForm2.MegsemGombClick(Sender: TObject);
// =============================================================================

begin
  TipusValasztoPanel.Visible := False;
  Image1.repaint;
  MenuBe;
end;

// =============================================================================
            procedure TForm2.jogigombClick(Sender: TObject);
// =============================================================================

begin
  TipusValasztoPanel.Visible := False;
  Image1.Repaint;
  _tTipus := 'J';
  Levalogatas;
end;

// WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
// =============================================================================
               procedure TForm2.NaturGombClick(Sender: TObject);
// =============================================================================

begin
  TipusValasztoPanel.Visible := False;
  Image1.repaint;
  _tTipus := 'N';
  Levalogatas;
end;

// HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                      procedure TForm2.Levalogatas;
// =============================================================================

var _cim: string;

begin
  if _tTipus='N' then _cim := 'TERMÉSZETES' else _cim := 'JOGI';
  LevalCimPanel.Caption := 'A LETILTOTT '+_cim+' SZEMÉLYEK LEVÁLOGATÁSA';
  LevalcimPanel.repaint;

  with LevalogatoPanel do
    begin
      top  := 130;
      left := 200;
      Visible := True;
      repaint;
    end;

  LevalCsik.Position := 0;
  if _ttipus='N' then NaturLevalogatas else JogiLevalogatas;
end;

//                                                                               ===============================
// =============================================================================  TILTOTT TERMÉSZETES SZEMÉLYEK
// =============================================================================         LEVÁLOGATÁSA
                  procedure TForm2.NaturLevalogatas;                          // ================================
// =============================================================================
begin

  LocNaturParancs('DELETE FROM UGYFELEK');

  _year    := yearof(date);
  _evTizes := midstr(inttostr(_year),3,2);
  _aktfdb  := 'UGYFEL'+ _evTizes + '.FDB';

  _remotePath := _host + ':C:\RECEPTOR\DATABASE\' + _aktfdb;

  RemDbase.Close;
  RemDbase.DatabaseName := _remotepath;
  RemDbase.Connected := True;

  LocNaturDbase.Connected := true;
  if LocNaturTranz.InTransaction then LocNaturTranz.Commit;
  LocNaturTranz.StartTransaction;

  LevalCsik.Max := 24;
  _vanLetiltas := False;

  _asc := 65;
  while _asc<=90 do
    begin
      LevalCsik.Position := _asc-64;
      _tablaNev := chr(_asc)+'NEV';

      _pcs := 'SELECT * FROM ' + _tablanev + _sorveg;
      _pcs := _pcs + 'WHERE TILTVA>0';

      with RemQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          _recNo := recNo;
        end;

      If _recNo>0 then
        begin
          _vanLetiltas := True;
          while not RemQuery.Eof do
            begin
              _sorSzam  := RemQuery.FieldByNAme('SORSZAM').asInteger;
              _nev      := trim(RemQuery.FieldByName('NEV').asString);
              _anyja    := trim(RemQuery.FieldByNAme('ANYJANEVE').asString);
              _szulHely := trim(RemQuery.FieldByName('SZULETESIHELY').AsString);
              _szulIdo  := trim(RemQuery.FieldByName('SZULETESIIDO').asString);
              _lakCim   := trim(RemQuery.FieldByNAme('LAKCIM').asString);
              _tiltva   := RemQuery.FieldByName('TILTVA').asInteger;

              _pcs := 'INSERT INTO UGYFELEK (NEV,ANYJANEVE,SZULETESIHELY,';
              _pcs := _pcs + 'SZULETESIIDO,LAKCIM,SORSZAM,TILTVA)' + _sorveg;
              _pcs := _pcs + 'VALUES (' + chr(39) + _nev + chr(39) + ',';
              _pcs := _pcs + chr(39) + _anyja + chr(39) + ',';
              _pcs := _pcs + chr(39) + _szulhely + chr(39) + ',';
              _pcs := _pcs + chr(39) + _szulido + chr(39) + ',';
              _pcs := _pcs + chr(39) + _lakcim + chr(39) + ',';
              _pcs := _pcs + inttostr(_sorszam) + ',';
              _pcs := _pcs + inttostr(_tiltva) + ')';
              LocNaturParancsPart(_pcs);
              RemQuery.next;
            end;
        end;
      RemQuery.close;
      inc(_asc);
    end;

  LocNaturTranz.commit;
  LocNaturDbase.close;

  RemQuery.close;
  RemDbase.close;

  if _vanLetiltas=False then
    begin
      Levalogatopanel.Visible := False;
      ShowMessage('NINCS LETILTOTT TERMÉSZETES SZEMÉLY');
      Menube;
      Exit;
    end;

  NaturTiltottListazas;
end;

// =============================================================================
                 procedure TForm2.NaturTiltottListazas;
// =============================================================================

begin
  _keress := '';
  Keredit.Text := '';

  LevalogatoPanel.Visible := False;
  LocJogiSource.Enabled := False;

  _pcs := 'SELECT * FROM UGYFELEK ORDER BY NEV';
  LocNaturDbase.connected := True;
  with LocNaturQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
    end;

  NaturvisszaVonoGomb.Enabled := False;
  LocNaturSource.Enabled := True;
  with NaturListazoPanel do
    begin
      Top     := 8;
      Left    := 8;
      Visible := True;
      Repaint;
    end;
  Naturracs.enabled := True;
  Activecontrol := Naturracs;
  NaturRacsNevDisplay;
end;

// =============================================================================
        procedure TForm2.NaturRacsKeyUp(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  _bill := ord(key);

  if _bill=13 then
    begin
      NaturRacsNevDisplay;
      NaturVisszavonoGomb.Enabled := True;
      Activecontrol := NaturvisszavonoGomb;
      exit;
    end;

  if (_bill>96) and (_bill<123) then _bill := _bill-32;

  if (_bill>32) and (_bill<41) then  // kurzor billentyük
    begin
      NaturRacsNevDisplay;
      _keress := '';
      KerEdit.Text :='';
      NaturRacsNevDisplay;
      exit;
    end;

  if ((_bill>64) and (_bill<91)) OR (_bill=32) then
    begin
      _ujkeress := _keress + chr(_bill);
      _megvan := LocNaturQuery.Locate('NEV',_ujkeress,[loPartialKey]);
      if _megvan then
        begin
          _keress := _ujkeress;
          Keredit.Text := _keress;
          NaturRacsNevDisplay;
        end;
      exit;
    end;

  if _bill=8 then
    begin
      _wlen := length(_keress);
      if _wlen<2 then
        begin
          _keress := '';
          Keredit.Text := '';
          exit;
        end;
      dec(_wlen);
      _keress := leftstr(_keress,_wlen);
      LocNaturQuery.Locate('NEV',_KERESS,[loPartialKey]);
      Keredit.Text := _keress;
      NaturRacsNevDisplay;
      exit;
    end;
end;

// =============================================================================
                            procedure TForm2.NaturRacsNevDisplay;
// =============================================================================

begin
  _nev     := trim(LocNaturQuery.FieldByNAme('NEV').asString);
  _sorszam := LocNaturQuery.FieldByName('SORSZAM').asInteger;
  _tiltva  := LocNaturQuery.fieldbyname('TILTVA').asInteger;

  NaturNevedit.text := _nev;
  NaturNevEdit.repaint;
  Activecontrol := NaturRacs;
end;

// =============================================================================
             procedure TForm2.NaturRacsDblClick(Sender: TObject);
// =============================================================================

begin
  NaturRacsNevDisplay;
  Naturracs.Enabled := false;
  NaturVisszavonoGomb.Enabled := True;
  Activecontrol := NaturvisszavonoGomb;
end;

// =============================================================================
            procedure TForm2.NaturRacsCellClick(Column: TColumn);
// =============================================================================

begin
  NaturRacsNevDisplay;
end;

// =============================================================================
           procedure TForm2.NaturListaVisszaGombClick(Sender: TObject);
// =============================================================================

begin
  NaturListazoPanel.Visible := False;
  LocNaturQuery.close;
  LocNaturDbase.close;
  Menube;
end;

// =============================================================================
            procedure Tform2.NaturVisszaVonoGombClick(Sender: TObject);
// =============================================================================

begin
  _unev := LocNaturQuery.FieldByNAme('NEV').asString;
  LocNaturQuery.close;
  LocNAturDbase.close;

  _nevtabla := leftstr(_unev,1)+'NEV';
  _pcs := 'UPDATE ' + _nevtabla + ' SET TILTVA=0' + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
  RemoteParancs(_pcs);

  NaturListazoPanel.Visible := False;
  LocNaturQuery.close;
  LocNaturDbase.close;

  Menube;
end;


// =============================================================================  ========================
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   JOGI TILTOT SZEMÉLYEK
// =============================================================================       LEVÁLOGATÁSA
                  procedure TForm2.JogiLevalogatas;                         //    =========================
// =============================================================================

begin
  LocJogiParancs('DELETE FROM JOGISZEMELY');

  _year    := yearof(date);
  _evtizes := midstr(inttostr(_year),3,2);
  _aktfdb  := 'UGYFEL'+ _evtizes + '.FDB';

  _remotepath := _host + ':C:\RECEPTOR\DATABASE\' + _aktfdb;

  Remdbase.Close;
  Remdbase.DatabaseName := _remotepath;
  Remdbase.Connected := True;

  LocJogiDbase.Connected := true;
  if locJogiTranz.InTransaction then LocJogiTranz.Commit;
  LocJogiTranz.StartTransaction;

  _pcs := 'SELECT * FROM JOGI' + _sorveg;
  _pcs := _pcs + 'WHERE TILTVA=1';

  with Remquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  Levalcsik.Max := _recno;
  If _recno>0 then
    begin
      while not RemQuery.Eof do
        begin
          _sorszam   := Remquery.fieldByNAme('SORSZAM').asinteger;
          _nev       := trim(Remquery.FieldByName('JOGISZEMELYNEV').asString);
          _telephely := trim(Remquery.FieldByNAme('TELEPHELYCIM').AsString);
          _fotev     := trim(Remquery.FieldByName('FOTEVEKENYSEG').AsString);
          _mbneve    := trim(RemQuery.FieldByName('MEGBIZOTTNEVE').asString);

          _pcs := 'INSERT INTO JOGISZEMELY (JOGISZEMELYNEV,TELEPHELYCIM,';
          _pcs := _pcs + 'FOTEVEKENYSEG,MEGBIZOTTNEVE,SORSZAM)' + _sorveg;
          _pcs := _pcs + 'VALUES (' + chr(39) + _nev + chr(39) + ',';
          _pcs := _pcs + chr(39) + _telephely + chr(39) + ',';
          _pcs := _pcs + chr(39) + _fotev + chr(39) + ',';
          _pcs := _pcs + chr(39) + _mbneve + chr(39) + ',';
          _pcs := _pcs + inttostr(_sorszam) + ')';
          LocJogiParancsPart(_pcs);
          RemQuery.next;
        end;
      RemQuery.close;
    end;

  LocJogiTranz.commit;
  LocJogiDbase.close;
  RemDbase.close;

  if _recno=0 then
    begin
      Levalogatopanel.Visible := False;
      ShowMessage('NINCS LETILTOTT JOGI SZEMÉLY');
      Menube;
      Exit;
    end;

  JogiTiltottListazas;
end;

// =============================================================================
                 procedure TForm2.JogiTiltottListazas;
// =============================================================================

begin
  _jKeress := '';
  JKeredit.Text := '';

  LevalogatoPanel.Visible := False;
  LocNaturSource.Enabled := False;

  _pcs := 'SELECT * FROM JOGISZEMELY ORDER BY JOGISZEMELYNEV';

  LocJogiDbase.Connected := True;
  with LocJogiQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  LocJogiSource.Enabled := true;
  JogiVisszavonoGomb.Enabled := False;

  with JogiListazoPanel do
    begin
      top := 8;
      left := 8;
      visible := True;
      repaint;
    end;
  Jogiracs.Enabled := True;
  Activecontrol := Jogiracs;
  JogiRacsNevDisplay;
end;

// =============================================================================
                       procedure TForm2.JogiRacsNevDisplay;
// =============================================================================

begin
  _jogiszemelynev     := trim(LocJogiQuery.FieldByNAme('JOGISZEMELYNEV').asString);
  _sorszam := LocJogiQuery.FieldByName('SORSZAM').asInteger;
  _tiltva  := LocJogiQuery.fieldbyname('TILTVA').asInteger;

  JogiNevedit.text := _jogiszemelynev;
  JogiNevEdit.repaint;
  Activecontrol := JogiRacs;
end;

// =============================================================================
      procedure TForm2.JOGIRACSKeyUp(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  _bill := ord(key);

  if _bill=13 then
    begin
      JogiRacsNevDisplay;
      Jogiracs.Enabled := False;
      JogivisszaVonoGomb.Enabled := True;
      Activecontrol := JogivisszavonoGomb;
      exit;
    end;

  if (_bill>96) and (_bill<123) then _bill := _bill-32;
  if (_bill>36) and (_bill<41) then  // kurzor billentyük
    begin
      _jkeress := '';
      JKerEdit.Text :='';
      JogiRacsNevDisplay;
      exit;
    end;

  if (_bill>64) and (_bill<91) then
    begin
      _ujkeress := _jkeress + chr(_bill);
      _megvan := LocJogiQuery.Locate('JOGISZEMELYNEV',_ujkeress,[loPartialKey]);
      if _megvan then
        begin
          _Jkeress := _ujkeress;
          JKeredit.Text := _Jkeress;
          JogiRacsNevDisplay;
        end;
      exit;
    end;

  if _bill=8 then
    begin
      _wlen := length(_jkeress);
      if _wlen<2 then
        begin
          _jkeress := '';
          jKeredit.Text := '';
          exit;
        end;
      dec(_wlen);
      _jkeress := leftstr(_jkeress,_wlen);
      LocJogiQuery.Locate('KOGISZEMELYNEV',_jKERESS,[loPartialKey]);
      JKeredit.Text := _jkeress;
      JogiRacsNevDisplay;
      exit;
    end;

end;

// =============================================================================
               procedure TForm2.JogiRacsDblClick(Sender: TObject);
// =============================================================================

begin
  JogiRacsNevDisplay;
  Jogiracs.Enabled := False;
  JogivisszaVonoGomb.Enabled := True;
  Activecontrol := JogivisszavonoGomb;
end;

// =============================================================================
                procedure TForm2.JogiRacsCellClick(Column: TColumn);
// =============================================================================

begin
  JogiRacsNevDisplay;
end;

// =============================================================================
          procedure TForm2.JogiListaVisszaGombClick(Sender: TObject);
// =============================================================================

begin
  JogiListazoPanel.Visible := False;
  LocJogiQuery.close;
  LocJogiDbase.close;
  Menube;
end;

// =============================================================================
          procedure TForm2.JogiVisszaVonoGombClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'UPDATE JOGI SET TILTVA=0' + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
  RemoteParancs(_pcs);
  JogiListazoPanel.Visible := False;
  LocJogiQuery.close;
  LocJogiDbase.close;
  Menube;
end;

// =============================================================================  =================
////////////////////////////////////////////////////////////////////////////////    LETILTÁSOK !!!
// =============================================================================  =================
// =============================================================================
          procedure TForm2.LetiltoGombClick(Sender: TObject);
// =============================================================================

begin

  // Egy személy vagy jogi személy letiltása:

  // Menupanel eltünik:
  TiltoMenupanel.Visible := False;

  // Beállitható az év (idén,tavaly) és tipus (természetes, jogi)¦

  _year := Yearof(date);
  _lastyear := _year-1;

  Yeargomb.Caption     := inttostr(_year);
  LastyearGomb.Caption := inttostr(_lastyear);
  TRendbenGomb.Enabled := false;

  _kertev := 0;
  YearGomb.Color := clBtnFace;
  YearGomb.Font.Color := clBlack;
  YearGomb.Enabled := True;

  LastYearGomb.Color := clBtnFace;
  LastYearGomb.Font.Color := clBlack;
  LastYearGomb.Enabled := True;

  _tTipus := '';

  tNAturGomb.Color := clBtnFace;
  tNaturGomb.Font.Color := clBlack;
  tNaturGomb.Enabled := True;

  tJogiGomb.Color := clBtnFace;
  tJogiGomb.Font.Color := clBlack;
  tJogiGomb.Enabled := True;

  with LetiltoPanel do
    begin
      Top     := 100;
      Left    := 250;
      Visible := true;
      repaint;
    end;
  Activecontrol := yeargomb;
end;

// =============================================================================
             procedure TForm2.YearGombClick(Sender: TObject);
// =============================================================================

begin
  // Az idei ügyfeleket választotta:

  YearGomb.Color := clYellow;
  YearGomb.Font.Color := clRed;
  LastYearGomb.Enabled := False;
  _kertEv := _year;
  if _tTipus<>'' then
    begin
      TRendbenGomb.Enabled := True;
      Activecontrol := TRendbenGomb;
    end;
end;

// =============================================================================
           procedure TForm2.LastYearGombClick(Sender: TObject);
// =============================================================================

//  a TAVALYI évet választotta:

begin
  LastYearGomb.Color := clYellow;
  LastYearGomb.Font.Color := clRed;
  YearGomb.Enabled := False;
  _kertEv := _lastYear;
  if _tTipus<>'' then
    begin
      TRendbenGomb.Enabled := True;
      ActiveControl := TRendbenGomb;
    end;
end;

// =============================================================================
            procedure TForm2.TNaturGombClick(Sender: TObject);
// =============================================================================

//  Természetes személyt választott

begin
  TNaturgomb.color := clYellow;
  Tnaturgomb.Font.Color := clRed;
  Tjogigomb.Enabled := false;
  _ttipus := 'N';
  if _kertev>0 then
    begin
      Trendbengomb.Enabled := true;
      Activecontrol := Trendbengomb;
    end;
end;

// =============================================================================
            procedure TForm2.TJogiGombClick(Sender: TObject);
// =============================================================================

begin
  TJogigomb.color := clYellow;
  TJogigomb.Font.Color := clRed;
  TNaturgomb.Enabled := False;
  _ttipus := 'J';
  if _kertev>0 then
    begin
      Trendbengomb.Enabled := true;
      Activecontrol := Trendbengomb;
    end;
end;

// =============================================================================
            procedure TForm2.TMegsemGombClick(Sender: TObject);
// =============================================================================

begin
  LetiltoPanel.Visible := false;
  Menube;
end;

// =============================================================================  ===============
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$   AZ ÖSSZES NÉV
// =============================================================================     LETÖLTÉSE
            procedure TForm2.TRendbenGombClick(Sender: TObject);            //      A TILTÁSHOZ
// =============================================================================  ================

begin
  LetiltoPanel.Visible := false;
  _evtizes := midstr(inttostr(_kertev),3,2);
  _fdbPath := _host + ':c:\receptor\database\ugyfel'+_evtizes+'.FDB';

  Remdbase.close;
  Remdbase.DatabaseName := _FdbPath;

  with UjregiPanel do
    begin
      top  := 200;
      left := 300;
      Visible := True;
    end;
  Activecontrol := oldgomb;
end;

// =============================================================================
                procedure TForm2.Oldgombclick(Sender: TObject);
// =============================================================================

begin
  UjregiPanel.Visible := False;
  if _ttipus='N' then OldNaturvalasztas else OldJogivalasztas;
end;

// =============================================================================
            procedure TForm2.NewGombClick(Sender: TObject);
// =============================================================================

begin
  UjRegiPanel.Visible := False;
  If _ttipus='N' then UjNaturUgyfel else UjJogiUgyfel;
end;

//                                                                                ============================
// HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH   RÉGI TERMÉSZETES SZEMÉLYEK
// =============================================================================    LISTÁZÁSA A TILTÁSHOZ
                       procedure TForm2.OldNaturvalasztas;                      // ============================
// =============================================================================

begin
  BetuEdit.Text := '';
  GtakaroPanel.Visible := False;
  NaturLista.Visible := False;
  KbLabel.Caption := ' ';
  NatnevEdit.Text := '';

  with OldNaturpanel do
    begin
      top := 40;
      left := 156;
      Visible := True;
      repaint;
    end;
  Activecontrol := Betuedit;
end;

// =============================================================================
        procedure TForm2.BETUEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;

  _kbetu := trim(BetuEdit.Text);

  if _kbetu='' then exit;
  if (ord(_kbetu[1])<65) or (ord(_kbetu[1])>91) then exit;

  KbLabel.Caption := _kbetu;

  _nevtabla := _kBetu + 'NEV';
  _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
  _pcs := _pcs + 'ORDER BY NEV';

  _fdbPath := _host + ':C:\receptor\database\ugyfel' + _evtizes + '.fdb';

  Remdbase.close;
  Remdbase.DatabaseName := _fdbPath;
  Remdbase.connected := true;

  with Remquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  RemNaturSource.Enabled := True;

  with Naturlista do
    begin
      top := 88;
      left := 16;
      visible := True;
    end;

  RNKeredit.Text := '';
  with GTakaroPanel do
    begin
      top := 40;
      left := 20;
      Visible := True;
      Repaint;
    end;
  _keress := '';

  TiltoGomb.Enabled  := False;
  ForrasGomb.Enabled := False;
  NatListaNevDisplay;
  _first := 0;

  ActiveControl := NaturListaRacs;
end;

// ============================================================================= =======================
       procedure TForm2.NATURLISTARACSKeyUp(Sender: TObject; var Key: Word;   //  TERMÉSZETES SZEMÉLYEK
                                                           Shift: TShiftState); //    KIVÁLASZTÁSA
                                                                             //       A LETILTÁSHOZ
// =============================================================================  ========================

begin
  _bill := ord(key);
  if (_bill=13) and (_first=0) then
    begin
      _first := 1;
      _bill := 33;
    end;

  if (_bill>96) and (_bill<123) then _bill := _bill-32;
  if (_bill>32) and (_bill<41) then  // kurzor billentyük
    begin
      NatListaNevDisplay;
      _keress := '';
      RnKerEdit.Text :='';
      exit;
    end;

  if _bill=13 then
    begin
      NatListaNevDisplay;
      TiltoGomb.Enabled := True;
      ForrasGomb.Enabled := True;

      Activecontrol := Tiltogomb;
      exit;
    end;

  if ((_bill>64) and (_bill<91)) OR (_bill=32) then
    begin
      _ujkeress := _keress + chr(_bill);
      _megvan := RemQuery.Locate('NEV',_ujkeress,[loPartialKey]);
      if _megvan then
        begin
          NatListaNevDisplay;
          _keress := _ujkeress;
          RnKeredit.Text := _keress;
        end;
      exit;
    end;

  if _bill=8 then
    begin
      _wlen := length(_keress);
      if _wlen<2 then
        begin
          _keress := '';
          RnKeredit.Text := '';
          exit;
        end;
      dec(_wlen);
      _keress := leftstr(_keress,_wlen);
      RemQuery.Locate('NEV',_KERESS,[loPartialKey]);
      RnKeredit.Text := _keress;
      NatListaNevDisplay;
    end;
end;

// =============================================================================
          procedure TForm2.NaturListaRacsCellClick(Column: TColumn);
// =============================================================================

begin
  NatlistaNevDisplay;
end;

// =============================================================================
                  procedure TForm2.NatListaNevDisplay;
// =============================================================================

begin
  _natnev     := Trim(Remquery.fieldByNAme('NEV').asString);
  _natsorszam := Remquery.FieldByName('SORSZAM').asInteger;

  NatNevEdit.text := _Natnev;
  NatNevEdit.repaint;
end;

// =============================================================================
            procedure TForm2.NaturListaRacsDblClick(Sender: TObject);
// =============================================================================

begin
  TiltoGomb.Enabled := True;
  ForrasGomb.Enabled := True;

  Activecontrol := Tiltogomb;
end;

// =============================================================================
           procedure TForm2.NatLetiltoGombClick(Sender: TObject);
// =============================================================================

begin
  _tiltva := 1;
  GombTakaroPanel.Visible := true;
  UgyfelLetiltas;
  Menube;
end;

// =============================================================================
             procedure TForm2.PENZFORRASGOMBClick(Sender: TObject);
// =============================================================================

begin
  _tiltva := 2;
  GombTakaroPanel.Visible := true;
  UgyfelLetiltas;
  Menube;
end;

// =============================================================================
                       procedure TForm2.UgyfelLetiltas;
// =============================================================================

begin
  _pcs := 'UPDATE '+ _NEVTABLA + ' SET TILTVA=' + inttostr(_tiltva) + _Sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
  RemoteParancs(_pcs);
  UjNaturPanel.Visible := False;
end;

// =============================================================================  =================================
                       procedure TForm2.OldJogivalasztas;                       //  RÉGI JOGI SZEMÉLYEK VÁLASZTÁSA
// =============================================================================  =================================

begin
  with OldJogiPanel do
    begin
      top := 40;
      left := 156;
      Visible := True;
      repaint;
    end;

  _fdbPath := _host + ':C:\receptor\database\ugyfel' + _evtizes + '.fdb';

  RemJogiDbase.close;
  RemJogiDbase.DatabaseName := _fdbPath;
  RemJogiDbase.Connected := true;

  _pcs := 'SELECT * FROM JOGI' + _sorveg;
  _pcs := _pcs + 'ORDER BY JOGISZEMELYNEV,MEGBIZOTTNEVE';

  with RemJogiQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  RemJogiSource.Enabled := True;

  _jKeress := '';
  JLKeredit.Text := '';
  AktJogiNevEdit.Text :='';

  with JogiLista do
    begin
      top  := 72;
      left := 32;
      visible := True;
    end;

  JogiListaTiltoGomb.Enabled := False;
  JogiForrasgomb.Enabled := False;
  AktjogiNevdisplay;
  JogiListaRacs.SetFocus;
end;

// =============================================================================  =======================
     procedure TForm2.JogiListaRacsKeyUp(Sender: TObject; var Key: Word;     //    LENYOMOTT BILLENTYÜK
                                                           Shift: TShiftState); //      KEZELÉSE
// =============================================================================  ========================

begin
  _bill := ord(key);

  if (_bill>96) and (_bill<123) then _bill := _bill-32;

  if _bill=13 then
    begin
      AktJoginevDisplay;

      JogiForrasGomb.enabled := true;
      JogiListaTiltoGomb.Enabled := True;
      Activecontrol := JogiListaTiltogomb;
      exit;
    end;

  if (_bill>32) and (_bill<41) then  // kurzor billentyük
    begin
      _jkeress := '';
      JLKerEdit.Text :='';
      AktJogiNevDisplay;
      exit;
    end;

  if ((_bill>64) and (_bill<91)) OR (_bill=32) then
    begin
      _ujkeress := _jkeress + chr(_bill);
      _megvan := RemJogiQuery.Locate('JOGISZEMELYNEV',_ujkeress,[loPartialKey]);
      if _megvan then
        begin
          AktjogiNevDisplay;
          _jkeress := _ujkeress;
          JLKeredit.Text := _jkeress;
        end;
      exit;
    end;

  if _bill=8 then
    begin
      _wlen := length(_jkeress);
      if _wlen<2 then
        begin
          AktjoginevDisplay;
          _jkeress := '';
          JLKeredit.Text := '';
          exit;
        end;
      dec(_wlen);
      _keress := leftstr(_jkeress,_wlen);
      RemJogiQuery.Locate('JOGISZEMELYNEV',_JKERESS,[loPartialKey]);
      JLKeredit.Text := _jkeress;
      Activecontrol := JogiListaRacs;
    end;
end;

// =============================================================================
           procedure TForm2.JogiListaRacsCellClick(Column: TColumn);
// =============================================================================

begin
  AktJogiNevDisplay;
end;

// =============================================================================
               procedure TForm2.AktJoginevDisplay;
// =============================================================================

begin
  _joginev := trim(RemjogiQuery.fieldByName('JOGISZEMELYNEV').asString);
  _jogisorszam := RemjogiQuery.FieldByNAme('SORSZAM').asInteger;
  _jogitiltva := RemJogiQuery.fieldByNAme('TILTVA').asInteger;
  AktJogiNevedit.Text := _joginev;
  AktJogiNevEdit.repaint;
  Activecontrol := JogiListaRacs;
end;

// =============================================================================
           procedure TForm2.JogiListaRacsDblClick(Sender: TObject);
// =============================================================================

begin
  AktJoginevDisplay;
  JogiForrasgomb.Enabled := True;
  JogiListaTiltoGomb.Enabled := True;
  Activecontrol := JogiListaTiltogomb;
end;

// =============================================================================  =============================
                     procedure TForm2.UjNaturUgyfel;                  //            UJ NATUR ÜGYFELEK TILTÁSA
// =============================================================================  =============================

begin

  NevEdit.Text      := '';
  AnyjaEdit.Text    := '';
  SzulHelyEdit.text := '';
  SzulidoEdit.Text  := '';
  LakcimEdit.Text   := '';

  GombTakaroPanel.Visible := True;
  with UjNaturPanel do
    begin
      Left := 250;
      Top  := 80;
      Visible := true;
      repaint;
    end;

  Activecontrol := Nevedit;
end;

// =============================================================================
       procedure TForm2.NevEditKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  ActiveControl := AnyjaEdit;
end;

// =============================================================================
     procedure TForm2.AnyjaEditKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Activecontrol := Szulhelyedit;
end;

// =============================================================================
     procedure TForm2.SzulhelyEditKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Activecontrol := SzulidoEdit;
end;

// =============================================================================
     procedure TForm2.SzulidoEditKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;

  NatvalOkeGomb.enabled := true;
  ActiveControl := NatValOkeGomb;
end;

// =============================================================================
          procedure TForm2.NatValOkeGombClick(Sender: TObject);
// =============================================================================

var _hiany: byte;

begin
  _unev      := Angolra(trim(Nevedit.text));
  _uanyja    := Angolra(trim(AnyjaEdit.text));
  _uszulhely := angolra(trim(Szulhelyedit.Text));
  _uszulido  := tomorito(trim(SzulidoEdit.Text));
  _hiany := 0;

  if _unev='' then exit;

  if _uanyja='' then _hiany := 1;

  if (_uszulhely='') and (_uszulido='') and (_hiany=1) then exit;

  _kbetu    := leftstr(_unev,1);
  _nevtabla := _kbetu + 'NEV';
  _lMezo    := _kBetu + 'LAST';

  _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
  _pcs := _pcs + 'WHERE (NEV LIKE ' + CHR(39) + _UNEV + '%' + CHR(39)+')';
  _pcs := _pcs + ' AND (SZULETESIIDO='+chr(39)+_uszulido+chr(39)+')';

  Remdbase.connected := True;
  with Remquery do
    begin
      close;
      sql.clear;
      Sql.Add(_pcs);
      Open;
      _recno := recno;
    end;

  _ezuj    := False;
  _sorszam := 0;

  if _recno=0 then    // ez egy új terMészetes személy
    begin
      RemQuery.close;
      Remdbase.close;

      if _uanyja='' then
        begin
          Activecontrol := AnyjaEdit;
          exit;
        end;

      if _uszulhely='' then
        begin
          Activecontrol := SzulhelyEdit;
          exit;
        end;

      if _uszulido='' then
        begin
          Activecontrol := SzulIdoEdit;
          exit;
        end;

      REMdbase.Connected := True;
      with Remquery do
        begin
          Close;
          sql.clear;
          sql.Add('SELECT * FROM LASTNUMS');
          Open;
          _sorszam := FieldByNAme(_LMezo).asInteger;
          close;
        end;
      Remdbase.close;

      inc(_sorszam);

      _pcs := 'UPDATE LASTNUMS SET '+ _lmezo + '=' + inttostr(_sorszam);
      remoteParancs(_pcs);

      _pcs := 'INSERT INTO ' + _nevtabla + ' (SORSZAM,NEV,ANYJANEVE,SZULETESIHELY,';
      _pcs := _pcs + 'SZULETESIIDO,TILTVA)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + inttostr(_sorszam) + ',';
      _pcs := _pcs + chr(39) + _unev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _uanyja + chr(39) + ',';
      _pcs := _pcs + chr(39) + _uszulhely + chr(39) + ',';
      _pcs := _pcs + chr(39) + _uszulido + chr(39) + ',0)';
      RemoteParancs(_pcs);
      _ezuj := True;
    end;

  if _recno>0 then
    begin
      _uanyja    := trim(Remquery.fieldByNAme('ANYJANEVE').asString);
      _uszulhely := trim(Remquery.FieldByNAme('SZULETESIHELY').AsString);
      _lakcim    := trim(RemQuery.Fieldbyname('LAKCIM').asString);
      _sorszam   := Remquery.fieldByName('SORSZAM').asInteger;
      _tiltva    := Remquery.FieldByName('TILTVA').asInteger;

      AnyjaEdit.Text := _uAnyja;
      SzulhelyEdit.Text := _uszulhely;

      AnyjaEdit.repaint;
      SzulhelyEdit.Repaint;
      Lakcimedit.Text := _lakcim;
      LakcimPanel.visible := True;
      Lakcimpanel.Repaint;

      REmquery.close;
      remDbase.close;

      if _tiltva>0 then
        begin
          ShowMessage('A választott személy már le van tiltva !');
          UjNaturPanel.Visible := False;
          Menube;
          exit;
        end;
    end;

  GombTakaroPanel.Visible := False;
end;

// ============================================================================= =================================
                   procedure TForm2.UjJogiUgyfel;                   //               UJ JOGI SZEMÉLYEK TILTÁSA
// ============================================================================= =================================

begin
  with UjJogiPanel do
    begin
      Top := 70;
      Left := 230;
      Visible := True;
      Repaint;
    end;

  jNevedit.Clear;
  jTelephelyEdit.Clear;
  jFotevEdit.Clear;
  jOkiratEdit.Clear;
  jMbNevEdit.Clear;

  JogiLetiltoGomb.Enabled := False;
  UjJogiForrasGomb.Enabled := False;

  JogiDataOkeGomb.Enabled := False;
  ActiveControl := JNevEdit;
end;

// =============================================================================
        procedure TForm2.JNevEditKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;

  _jNev := trim(JnevEdit.Text);
  if _jNev='' then Exit;

  ActiveControl := jTelephelyEdit;
end;

// =============================================================================
    procedure TForm2.JTelephelyEditKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then Exit;
  _jTelep := trim(jTelephelyEdit.Text);
  if _jTelep='' then Exit;

  ActiveControl := jFotevEdit;
end;

// =============================================================================
       procedure TForm2.JFotevEditKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then Exit;

  _jFotev := trim(jFotevEdit.Text);
  if _jFotev='' then Exit;

  ActiveControl := JOkiratEdit;
end;

// =============================================================================
     procedure TForm2.JOkiratEditKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
   if ord(key)<>13 then Exit;
   _jOkirat := trim(jOkiratEdit.Text);
   if _jOkirat='' then Exit;

   ActiveControl := jMbNevEdit;
end;

// =============================================================================
        procedure TForm2.JMbNevEditKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then Exit;
  _jMbNev := trim(JMbNevEdit.Text);
  if _jMbNev='' then Exit;

  JogiDataOkeGomb.Enabled := True;
  ActiveControl := JogiDataOkeGomb;
end;

// =============================================================================
            procedure TForm2.JogiDataOkeGombClick(Sender: TObject);
// =============================================================================

begin
  _jNev := trim(jNevEdit.Text);
  if _jNev='' then Exit;

  _jTelep := trim(jTelephelyEdit.Text);
  if _jTelep='' then Exit;

  _jFotev := trim(jFotevEdit.Text);
  if _jFotev='' then Exit;

   _jOkirat := trim(jOkiratEdit.Text);
   if _jOkirat='' then Exit;

  _jMbNev := trim(jMbNevEdit.Text);
  if _jMbNev='' then Exit;

  _pcs := 'SELECT * FROM JOGI' + _sorVeg;
  _pcs := _pcs + 'WHERE (JOGISZEMELYNEV=' + chr(39) + _jNev + chr(39)+') AND (';
  _pcs := _pcs + 'OKIRATSZAM=' + chr(39) + _jOkirat + chr(39) + ')';

  Remdbase.Connected := True;
  with RemQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _recNo := RecNo;
    end;

  _ezUj    := False;
  _sorSzam := 0;

  if _recNo=0 then
    begin
      RemQuery.Close;
      Remdbase.Close;
      _ezUj := True;
    end else
    begin
      _sorszam := RemQuery.FieldByNAme('SORSZAM').asInteger;
      _jogiNev    := trim(Remquery.FieldByNAme('JOGISZEMELYNEV').asString);
      _jTelep  := trim(RemQuery.fieldByName('TELEPHELYCIM').asString);
      _jFotev  := trim(RemQuery.fieldByNAme('FOTEVEKENYSEG').AsString);
      _jOkirat := trim(RemQuery.FieldByNAme('OKIRATSZAM').asString);
      _jMbnev  := trim(Remquery.FieldByNAme('MEGBIZOTTNEVE').asString);
      RemQuery.Close;
      RemDbase.Close;
    end;

  UjJogiForrasGomb.Enabled := True;
  JogiLetiltoGomb.Enabled := True;

  JogiDataOkeGomb.Enabled := False;
  ActiveControl := JogiLetiltoGomb;
end;

// =============================================================================
               procedure TForm2.JogiLetiltoGombClick(Sender: TObject);
// =============================================================================

begin
  _tiltva := TBitbtn(Sender).Tag;
  if _ezUj=False then
    begin
      RemDbase.Connected := True;
      with RemQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add('SELECT * FROM LASTNUMS');
          Open;
          _sorSzam := FieldByNAme('JOGILAST').asInteger;
          Close;
        End;
      RemDbase.Close;
      inc(_sorSzam);

      _pcs := 'UPDATE LASTNUMS SET JOGILAST=' + intToStr(_sorSzam);
      RemoteParancs(_pcs);

      _pcs := 'INSERT INTO JOGI (SORSZAM,JOGISZEMELYNEV,TELEPHELYCIM,OKIRATSZAM,';
      _pcs := _pcs + 'FOTEVEKENYSEG,MEGBIZOTTNEVE,DATUM,ISO,TILTVA)' + _sorVeg;
      _pcs := _pcs + 'VALUES (' + intToStr(_sorszam) + ',';
      _pcs := _pcs + chr(39) + _jogiNev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _jTelep + chr(39) + ',';
      _pcs := _pcs + chr(39) + _jOkirat + chr(39) + ',';
      _pcs := _pcs + chr(39) + _jFotev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _jMbNev + chr(39) + ',';
      _pcs := _pcs + chr(39) + '2010.01.01' + chr(39) + ',';
      _pcs := _pcs + chr(39) + 'HU' + chr(39) + ',';
      _pcs := _pcs + inttostr(_tiltva)+')';
    end else
    begin
      _pcs := 'UPDATE JOGI SET TILTVA=' + inttostr(_tiltva)+_sorveg;
      _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
    end;
  RemoteParancs(_pcs);
  UjJogiPanel.Visible := False;
  if _tiltva=1 then ShowMessage(_joginev+' LETILTVA !')
  else Showmessage(_joginev + ' CSAK FORRÁS MEGADÁSSAL VÁLTHAT');
  Menube;
end;

// =============================================================================
          procedure TForm2.JogiValMegsemGombClick(Sender: TObject);
// =============================================================================

begin
  UjJogiPanel.Visible := False;
  Menube;
end;

// ============================================================================= ========================================
            procedure TForm2.ATHOZOGOMBClick(Sender: TObject);           //        TILTOTT ÜGYFELEK ÁTHOZÁSA ELÖZÖ ÉVRÕL
// ============================================================================= =========================================

begin
   TiltoMenuPanel.Visible := False;
  with AthozoPanel do
    begin
      Top     := 80;
      Left    := 150;
      Visible := True;
      Repaint;
    end;

  _iden   := yearof(Date);
  _tavaly := _iden-1;

  _ideiDekads := midstr(inttostr(_iden),3,2);
  _tavalyidekads := midstr(inttostr(_tavaly),3,2);

  _ideiFdb := '185.43.207.99:c:\receptor\database\UGYFEL' + _ideiDekads + '.FDB';
  _tavalyiFdb := '185.43.207.99:c:\receptor\database\UGYFEL' + _tavalyiDekads + '.FDB';

  NaturAdatKimasolo;
  NaturAdatBemasolo;

  JogiAdatKimasolo;
  JogiAdatBemasolo;
  AthozoPanel.Visible := False;
  Menube;
end;

// =============================================================================
             procedure TForm2.AthozMegsemGombClick(Sender: TObject);
// =============================================================================

begin
  AthozoPanel.Visible := False;
  Menube;
end;

// ============================================================================= =================================
                   procedure TForm2.NaturAdatKimasolo;            //              Natur tiltottak átmásolása a ta-
//                                                                                 valyi szerverrõl a Bizlatokba
// ============================================================================= ==================================

begin
  RemDbase.close;
  RemDbase.DatabaseName := _tavalyiFdb;
  RemDbase.connected := True;

  LocNaturParancs('DELETE FROM UGYFELEK');

  LocNaturDbase.Connected := True;
  if LocNaturTranz.InTransaction then LocNaturTranz.Commit;
  LocNaturTranz.StartTransaction;

  Csik.Max := 26;

  _asc := 65;
  while _asc<=90 do
    begin
      Csik.Position := _asc-64;

      _tablaNev := chr(_asc) + 'NEV';
      _pcs := 'SELECT * FROM ' + _tablaNev + _sorVeg;
      _pcs := _pcs + 'WHERE (TILTVA=1) OR (TILTVA=2)';

      with RemQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          _recNo := recNo;
        end;

      if _recNo>0 then
        begin
          while not RemQuery.Eof do
            begin

              _nev       := trim(Remquery.FieldByName('NEV').asString);
              _anyja := trim(Remquery.fieldbyname('ANYJANEVE').AsString);
              _szulhely  := trim(Remquery.FieldByName('SZULETESIHELY').asString);
              _szulido   := trim(RemQuery.FieldByName('SZULETESIIDO').asString);
              _allampolg :=trim(Remquery.Fieldbyname('ALLAMPOLGAR').AsString);
              _LAKCIM    := trim(Remquery.Fieldbyname('LAKCIM').asstring);
              _tiltva    := RemQuery.FieldByNAme('TILTVA').asInteger;

              LocMemo.Lines.Add(_nev);

              _pcs := 'INSERT INTO UGYFELEK (NEV,ANYJANEVE,SZULETESIHELY,';
              _pcs := _pcs + 'SZULETESIIDO,ALLAMPOLGAR,LAKCIM,TILTVA)' + _sorveg;

              _pcs := _pcs + 'VALUES (' + chr(39) + _nev + chr(39) + ',';
              _pcs := _pcs + chr(39) + _anyja + chr(39) + ',';
              _pcs := _pcs + chr(39) + _szulhely + chr(39) + ',';
              _pcs := _pcs + chr(39) + _szulido + chr(39) + ',';
              _pcs := _pcs + chr(39) + _allampolg + chr(39) + ',';
              _pcs := _pcs + chr(39) + _lakcim + chr(39) + ',';

              _pcs := _pcs + inttostr(_tiltva) + ')';

              RemMemo.Lines.add(_nev);

              LocNaturParancsPart(_pcs);
              RemQuery.next;
            end;
        end;
      RemQuery.close;
      inc(_asc);
    end;
  LocNaturTranz.commit;
  LocNaturDbase.close;
  Remdbase.close;
end;

// ============================================================================= ========================================
                 procedure Tform2.NaturAdatBemasolo;    //    A BIZLATOK UGYFELEIBÕL A KIMÁSOLT TAVALYI TILTOTT ÜGYFELEK
//                                                                 BEMÁSOLJA AZ IDEI SZERVERRE (HA ÚJ) VAGY CSAK LETILTJA
// ============================================================================= =========================================

begin
  RemDbase.close;
  RemDbase.DatabaseName := _ideiFdb;

  _pcs := 'SELECT * FROM UGYFELEK ORDER BY NEV';

  LocNaturDbase.Connected := True;
  with LocNaturQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
    end;

  while not LocNaturQuery.Eof do
    begin
      _nev       := trim(LocNaturQuery.FieldByName('NEV').AsString);
      _anyja     := trim(LocNaturQuery.FieldByNAme('ANYJANEVE').asString);
      _szulhely  := trim(LocNaturQuery.FieldByNAme('SZULETESIHELY').asString);
      _szulido   := LocnaturQuery.FieldByNAme('SZULETESIIDO').asstring;
      _allampolg := locnaturquery.fieldbyname('ALLAMPOLGAR').ASSTRING;
      _lakcim    := trim(locnaturquery.fieldbyName('LAKCIM').asString);
      _tiltva    := LocNaturQuery.FieldByNAme('TILTVA').asInteger;

      _kb := leftstr(_nev,1);
      _nevtabla := _kb + 'NEV';

      _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
      _pcs := _pcs + 'WHERE (NEV='+chr(39)+_nev+chr(39)+') AND (';
      _pcs := _pcs + 'SZULETESIIDO=' + chr(39)+_szulido + chr(39)+')';

      RemDbase.Connected := True;
      with RemQuery do
        begin
          Close;
          sql.clear;
          Sql.add(_Pcs);
          Open;
          _recNo := recNo;
        end;

      if _recNo=0 then RembeMasolas
      else TiltoMasolas;
      LocNaturQuery.Next;
    end;
  LocNaturQuery.close;
  LocNaturdbase.close;
end;

// ============================================================================= =================================
                       procedure TForm2.TiltoMasolas; //
// ============================================================================= ==================================

begin
  _sorszam := RemQuery.fieldByNAme('SORSZAM').asInteger;

  RemQuery.Close;
  Remdbase.Close;

  _pcs := 'UPDATE ' + _nevtabla + ' SET TILTVA=' + inttostr(_tiltva)+_sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
  RemoteParancs(_pcs);
end;

// =============================================================================
                     procedure TForm2.RembeMasolas;
// =============================================================================

begin
  RemQuery.Close;
  RemDbase.Close;

  _LMezo := _kb + 'LAST';
  _pcs := 'SELECT * FROM LASTNUMS';

  remDbase.Connected := True;
  with RemQuery do
    begin
      CLose;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      _sorszam := FieldByNAme(_LMezo).asInteger;
      Close;
    end;
  remdbase.close;

  inc(_sorszam);

  _pcs := 'UPDATE LASTNUMS SET ' + _lmezo + '=' + inttostr(_sorszam);
  RemoteParancs(_pcs);

  _pcs := 'INSERT INTO ' + _nevtabla + ' (SORSZAM,NEV,SZULETESIIDO,TILTVA,';
  _pcs := _pcs + 'ANYJANEVE,SZULETESIHELY,ALLAMPOLGAR,';
  _pcs := _pcs + 'LAKCIM)'+_sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_sorszam) + ',';
  _pcs := _pcs + chr(39) + _nev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _szulido + chr(39) + ',';
  _pcs := _pcs + inttostr(_tiltva) + ',';
  _pcs := _pcs + chr(39) + _anyja + chr(39) + ',';
  _pcs := _pcs + chr(39) + _szulhely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _allampolg + chr(39) + ',';
  _pcs := _pcs + chr(39) + _lakcim + chr(39) + ')';
  RemoteParancs(_pcs);

  RemMemo.Lines.Add(_nev);
end;

// =============================================================================
                     procedure TForm2.JogiAdatKimasolo;
// =============================================================================

begin
  RemDbase.close;
  RemDbase.DatabaseName := _tavalyiFdb;
  Remdbase.Connected := True;

  LocNaturParancs('DELETE FROM JOGISZEMELY');

  LocNaturDbase.Connected := True;
  if LocNaturTranz.InTransaction then LocNaturTranz.Commit;
  LocNaturTranz.StartTransaction;;

  _pcs := 'SELECT * FROM JOGI' +  _sorVeg;
  _pcs := _pcs + 'WHERE (TILTVA=1) OR (TILTVA=2)';

  with RemQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _recNo := recNo;
    end;

  if _recNo>0 then
    begin
      while not RemQuery.Eof do
        begin
          _joginev := trim(Remquery.FieldByName('JOGISZEMELYNEV').asString);
          _jTelep  := trim(Remquery.FieldByName('TELEPHELYCIM').asString);
          _jOkirat := trim(Remquery.FieldByName('OKIRATSZAM').asString);
          _jFotev  := trim(Remquery.FieldByName('FOTEVEKENYSEG').asString);
          _jMbnev  := trim(Remquery.FieldByName('MEGBIZOTTNEVE').asString);

          LocMemo.Lines.Add(_joginev);

          _pcs := 'INSERT INTO JOGISZEMELY (JOGISZEMELYNEV,TELEPHELYCIM,';
          _pcs := _pcs + 'OKIRATSZAM,FOTEVEKENYSEG,MEGBIZOTTNEVE)'+_sorveg;

          _pcs := _pcs + 'VALUES (' + chr(39) + _joginev + chr(39) + ',';
          _pcs := _pcs + chr(39) + _jTelep + chr(39) + ',';
          _pcs := _pcs + chr(39) + _jOkirat + chr(39) + ',';
          _pcs := _pcs + chr(39) + _fotev + chr(39) + ',';
          _pcs := _pcs + chr(39) + _jmbNev + chr(39) + ')';

          LocNaturParancsPart(_pcs);
          RemQuery.next;
        end;

      LocNaturTranz.Commit;
      LocNaturDbase.Close;

      RemQuery.close;
      Remdbase.close;
    end else
    begin
      LocNaturTranz.Commit;
      LocNaturDbase.Close;
      RemQuery.Close;
      RemDbase.Close;
    end;
end;

// =============================================================================
                 procedure Tform2.JogiAdatBemasolo;
// =============================================================================

begin
  RemDbase.close;
  RemDbase.DatabaseName := _ideiFdb;

  _pcs := 'SELECT * FROM JOGISZEMELY ORDER BY JOGISZEMELYNEV';

  LocJogiDbase.Connected := True;
  with LocJogiQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _recno := Recno;
    end;

  if _recno=0 then
    begin
      LocJogiQuery.close;
      LocJogiDbase.close;
      exit;
    end;

  while not LocJogiQuery.Eof do
    begin
      _joginev := trim(LocJogiQuery.FieldByName('JOGISZEMELYNEV').AsString);
      _jTelep  := trim(LocJogiQuery.FieldByName('TELEPHELYCIM').AsString);
      _jOkirat := trim(LocJogiQuery.FieldByName('OKIRATSZAM').AsString);
      _jFotev  := trim(LocJogiQuery.FieldByName('FOTEVEKENYSEG').AsString);
      _jMbnev  := trim(LocJogiQuery.FieldByName('MEGBIZOTTNEVE').AsString);

      RemMemo.LineS.Add(_joginev);

      _pcs := 'SELECT * FROM JOGI' + _sorveg;
      _pcs := _pcs + 'WHERE (JOGISZEMELYNEV=' + CHR(39)+_Joginev + chr(39);
      _pcs := _pcs + ') AND (OKIRATSZAM=' + chr(39)+_jOkirat+chr(39)+')';

      RemDbase.Connected := true;
      with Remquery do
        begin
          Close;
          Sql.clear;
          Sql.add(_pcs);
          Open;
          _recno := Recno;
        end;

      if _recNo=0 then
        begin
          _pcs := 'SELECT * FROM LASTNUMS';
          with RemQuery do
            begin
              close;
              sql.clear;
              sql.add(_pcs);
              Open;
              _sorszam := FieldByNAme('JOGILAST').asInteger;
              close;
            end;
          Remdbase.close;
          inc(_sorszam);

          _pcs := 'UPDATE LASTNUMS SET JOGILAST=' + inttostr(_sorszam);
          RemoteParancs(_pcs);

          _pcs := 'INSERT INTO JOGI (SORSZAM,JOGISZEMELYNEV,TELEPHELYCIM,';
          _pcs := _pcs + 'OKIRATSZAM,FOTEVEKENYSEG,MEGBIZOTTNEVE,TILTVA)'+_sorveg;
          _pcs := _pcs + 'VALUES (' + inttostr(_sorszam) + ',';
          _pcs := _pcs + chr(39) + _joginev + chr(39) + ',';
          _pcs := _pcs + chr(39) + _jTelep + chr(39) + ',';
          _pcs := _pcs + chr(39) + _jOkirat  + chr(39) + ',';
          _pcs := _pcs + chr(39) + _jFotev + chr(39) + ',';
          _pcs := _pcs + chr(39) + _jMbnev + chr(39) + ',';
          _pcs := _pcs + '1)';
        end else
        begin
          _sorszam := Remquery.FieldByNAme('SORSZAM').asInteger;
          Remquery.close;
          Remdbase.close;

          _pcs := 'UPDATE JOGI SET TILTVA=1' + _sorveg;
          _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
        end;
      RemoteParancs(_pcs);

      LocJogiQuery.next;
    end;
end;

// =============================================================================
             procedure TForm2.VisszaGombClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
               function TForm2.Tomorito(_ts: string): string;
// =============================================================================

var _ws,_y,_aktasc: byte;

begin
  _ts := trim(_ts);
  result := '';

  if _ts='' then exit;

  _ts := uppercase(_ts);
  _ws := length(_ts);
  _y := 1;

  while _y<=_ws do
    begin
      _aktasc := ord(_ts[_y]);
      if (_aktasc>47) and (_aktasc<58) then result := result + chr(_aktasc);
      if (_aktasc>64) and (_aktasc<91) then result := result + chr(_aktasc);
      inc(_y);
    end;
end;

// =============================================================================
            procedure TForm2.NATVALMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  UjNaturPanel.Visible := False;
  Menube;
end;

// =============================================================================
           procedure TForm2.NLMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  Remquery.close;
  remDbase.close;

  Kblabel.Caption       := ' ';
  NaturLista.Visible    := False;
  OldNaturPanel.Visible := False;
  OldJogiPanel.Visible  := False;
  Menube;
end;

// =============================================================================
             procedure TForm2.TiltoGombClick(Sender: TObject);
// =============================================================================

begin
  _nlNev     := trim(Remquery.FieldByName('NEV').asString);
  _nlSorszam := Remquery.FieldByNAme('SORSZAM').asInteger;
  _nlTiltva  := Remquery.FieldByName('TILTVA').asInteger;

  OldNaturpanel.Visible := False;
  Remquery.close;
  Remdbase.close;

  if _nltiltva>0 then
    begin
      Showmessage(_NLnEV + ' MÁR LE VAN TILTVA !');
      Menube;
      Exit;
    end;

   _pcs := 'UPDATE ' + _nevtabla + ' SET TILTVA=1' + _sorveg;
   _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_nlsorszam);
   RemoteParancs(_pcs);

   ShowMessage(_nlNev+' LETILTÁSRA KERÜLT');
   Menube;
end;

// =============================================================================
             procedure TForm2.ForrasGombClick(Sender: TObject);
// =============================================================================

begin
  _nlNev     := trim(Remquery.FieldByName('NEV').asString);
  _nlSorszam := Remquery.FieldByNAme('SORSZAM').asInteger;
  _nlTiltva  := Remquery.FieldByName('TILTVA').asInteger;
  OldNaturpanel.visible := False;

  Remquery.close;
  Remdbase.close;

   _pcs := 'UPDATE ' + _nevtabla + ' SET TILTVA=2' + _sorveg;
   _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_nlsorszam);
   RemoteParancs(_pcs);

   ShowMessage(_nlNev+' CSAK FORRÁS MEGJELÖLÉSSEL VÁLTHAT');
   Menube;
end;

// ============================================================================= ======================
///////////////////////  EGYEB PROGRAMOK ///////////////////////////////////////    EGYÉB PROGRAMOK
// ============================================================================= ======================
           procedure TForm2.LocNaturParancs(_ukaz: string);
// =============================================================================

begin

  LocNaturDbase.Connected := True;
  if LocNaturTranz.InTransaction then LocNaturTranz.Commit;
  LocNaturTranz.StartTransaction;

  with LocNaturQuery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;

  LocNaturTranz.commit;
  LocNaturDbase.close;
end;

// =============================================================================
           procedure TForm2.LocJogiParancs(_ukaz: string);
// =============================================================================

begin
  LocJogiDbase.Connected := True;
  if LocJogiTranz.InTransaction then LocJogiTranz.Commit;
  LocJogiTranz.StartTransaction;

  with LocJogiQuery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;

  LocJogiTranz.commit;
  LocJogiDbase.close;
end;

// =============================================================================
             procedure TForm2.RemoteParancs(_ukaz: string);
// =============================================================================

begin
  Remdbase.connected := true;
  if remtranz.InTransaction then Remtranz.commit;
  Remtranz.StartTransaction;
  with RemQuery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  remtranz.Commit;
  Remdbase.close;
end;

// =============================================================================
             procedure TForm2.LocNaturParancsPart(_ukaz: string);
// =============================================================================

begin
  with LocNaturQuery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
end;

// =============================================================================
             procedure TForm2.LocJogiParancsPart(_ukaz: string);
// =============================================================================

begin
  with LocJogiQuery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
end;

// =============================================================================
                 function TForm2.Angolra(_huName: string): string;
// =============================================================================

var _whn,_z,_asc: byte;

begin
  result  := '';

  _huname := uppercase(trim(_huname));
  _whn    := length(_huname);

  if _whn=0 then exit;

  _z := 1;
  while _z<=_whn do
    begin
      _asc := ord(_huname[_z]);
      _asc := HutoGb(_asc);

      result := result + chr(_asc);
      inc(_z);
    end;
end;

// =============================================================================
                   function TForm2.HutoGb(_kod: byte): byte;
// =============================================================================

var _r: byte;

begin
  _r := _kod;
  case _kod of
    186: _r := 69;  // E
    187: _r := 79;  // O
    193: _r := 65;  // A
    201: _r := 69;  // E
    211: _r := 79;  // O
    213: _r := 79;  // O
    214: _r := 79;  // O
    218: _r := 85;  // U
    219: _r := 85;  // U
    220: _r := 85;  // U
    222: _r := 65;  // A
    226: _r := 73;  // I
    205: _r := 73;  // I

    225: _r := 97;  // a
    233: _r := 101; // e
    237: _r := 105; // i
    243: _r := 111; // o
    246: _r := 111; // o
    245: _r := 111; // o
    250: _r := 117; // u
    252: _r := 117; // u
    251: _r := 117; // u
  end;
  result := _r;
end;

// =============================================================================
             procedure TForm2.NEVEDITEnter(Sender: TObject);
// =============================================================================

begin
  TEdit(sender).Color := clYellow;
end;

// =============================================================================
              procedure TForm2.NEVEDITExit(Sender: TObject);
// =============================================================================

begin
  TEdit(sender).Color := clWindow;
end;

procedure TForm2.JOGILISTATILTOGOMBClick(Sender: TObject);
begin
  JogiLista.Visible := False;
  OldJogiPanel.Visible := False;
  RemJogiQuery.close;
  RemJogiDbase.close;

  _pcs := 'UPDATE JOGI SET TILTVA=1 WHERE SORSZAM=' + inttostr(_jogisorszam);
  remoteParancs(_pcs);
  Showmessage(_joginev + ' SIKERESEN LETILTVA !');
  Menube;
end;

procedure TForm2.JOGIFORRASGOMBClick(Sender: TObject);
begin
  JogiLista.Visible := False;
  OldJogiPanel.Visible := False;
  RemJogiQuery.close;
  RemJogiDbase.close;

  _pcs := 'UPDATE JOGI SET TILTVA=2 WHERE SORSZAM=' + inttostr(_jogisorszam);
  remoteParancs(_pcs);
  Showmessage(_joginev + ' CSAK FORRÁSMEGJELÖLÉSSEL VÁLTHAT !');
  Menube;

end;

end.
