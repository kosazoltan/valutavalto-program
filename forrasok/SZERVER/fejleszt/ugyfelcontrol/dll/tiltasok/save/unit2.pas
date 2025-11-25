unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, IBDatabase, DB, IBCustomDataSet,
  IBQuery,DateUtils, ComCtrls, Grids, DBGrids, strutils;

type
  TForm2 = class(TForm)

    AthozoPanel         : TPanel;
    TiltoMenuPanel      : TPanel;
    ListaGomb           : TPanel;
    LetiltoGomb         : TPanel;
    AthozoGomb          : TPanel;
    VisszaGomb          : TPanel;
    ListaPanel          : TPanel;
    LevalogatoPanel     : TPanel;
    LevalCimPanel       : TPanel;
    JogiListazoPanel    : TPanel;
    Panel2              : TPanel;
    TipusValasztoPanel  : TPanel;
    NaturListazoPanel   : TPanel;
    Panel1              : TPanel;

    LocQuery            : TIBQuery;
    LocDbase            : TIBDatabase;
    LocTranz            : TIBTransaction;

    JogiRacs            : TDBGrid;
    NaturRacs           : TDBGrid;

    RemQuery            : TibQuery;
    RemDbase            : TibDatabase;
    RemTranz            : TibTransaction;

    JogiSource          : TDataSource;
    NaturSource         : TDataSource;

    AthozStartGomb      : TBitBtn;
    AthozMegsemGomb     : TBitBtn;
    JogiGomb            : TBitBtn;
    JogiVisszaVonoGomb  : TBitBtn;
    JogiListaVisszaGomb : TBitBtn;
    MegsemGomb          : TBitBtn;
    NaturVisszaVonoGomb : TBitBtn;
    NaturListaVisszaGomb: TBitBtn;
    NaturGomb           : TBitBtn;
    Shape2              : TShape;
    Shape3              : TShape;
    Shape4              : TShape;

    LocMemo             : TMemo;
    RemMemo             : TMemo;

    Label4              : TLabel;
    Label5              : TLabel;
    Label6              : TLabel;
    Label1              : TLabel;
    Label2              : TLabel;

    Csik                : TProgressBar;
    LevalCsik           : TProgressBar;

    JogiNevEdit         : TEdit;
    NaturNevEdit        : TEdit;
    NATURKIVALASZTOPANEL: TPanel;
    NATVALDATAIN: TPanel;
    Label7: TLabel;
    NEVEDIT: TEdit;
    ANYJAEDIT: TEdit;
    SZULHELYEDIT: TEdit;
    SZULIDOEDIT: TEdit;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    NATVALOKEGOMB: TBitBtn;
    NATVALMEGSEMGOMB: TBitBtn;
    LAKCIMPANEL: TPanel;
    Label12: TLabel;
    LAKCIMEDIT: TEdit;
    NATLETILTOGOMB: TBitBtn;
    JOGIKIVALASZTOPANEL: TPanel;
    JOGIVALDATAIN: TPanel;
    Label13: TLabel;
    JNEVEDIT: TEdit;
    JTELEPHELYEDIT: TEdit;
    JFOTEVEDIT: TEdit;
    JOKIRATEDIT: TEdit;
    JMBNEVEDIT: TEdit;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    JOGILETILTOGOMB: TBitBtn;
    JOGIVALMEGSEMGOMB: TBitBtn;
    JOGIJELZOPANEL: TPanel;
    JOGIDATAOKEGOMB: TBitBtn;
    CSAKFORRASPANEL: TPanel;
    LETILTOPANEL: TPanel;
    YEARGOMB: TPanel;
    LASTYEARGOMB: TPanel;
    TNATURGOMB: TPanel;
    TJOGIGOMB: TPanel;
    TRENDBENGOMB: TBitBtn;
    TMEGSEMGOMB: TBitBtn;
    Label3: TLabel;
    Shape1: TShape;
    PENZFORRASGOMB: TBitBtn;
    GOMBTAKAROPANEL: TPanel;

    procedure AthozoGombClick(Sender: TObject);
    procedure AthozMegsemGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure LastYearGombClick(Sender: TObject);
    procedure LetiltoGombClick(Sender: TObject);
    procedure LocParancsPart(_ukaz: string);
    procedure Levalogatas;
    procedure ListaGombClick(Sender: TObject);
    procedure JogiLevalogatas;
    procedure JogiTiltottListazas;
    procedure JogiRacsKeyUp(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure JogiListaVisszaGombClick(Sender: TObject);
    procedure JogiRacsDblClick(Sender: TObject);
    procedure JogiRacsCellClick(Column: TColumn);
    procedure JogiRecordChange;
    procedure JogiTiltas;
    procedure JogiGombClick(Sender: TObject);
    procedure JogiVisszaVonoGombClick(Sender: TObject);
    procedure MegsemGombClick(Sender: TObject);
    procedure Menube;
    procedure NaturGombClick(Sender: TObject);
    procedure NaturAdatAtmasolo;
    procedure NaturLevalogatas;
    procedure NaturTiltas;
    procedure NaturTiltottlistazas;
    procedure NaturRacsKeyUp(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure NaturRacsDblClick(Sender: TObject);
    procedure NaturRacsCellClick(Column: TColumn);
    procedure NaturListaVisszaGombClick(Sender: TObject);
    procedure NaturVisszaVonoGombClick(Sender: TObject);
    procedure RecordChange;
    procedure RemoteParancs(_ukaz: string);
    procedure TNaturGombClick(Sender: TObject);
    procedure TJogiGombClick(Sender: TObject);
    procedure TMegsemGombClick(Sender: TObject);
    PROCEDURE UgyfelLetiltas;
    procedure VisszaGombClick(Sender: TObject);
    procedure YearGombClick(Sender: TObject);
    procedure TRENDBENGOMBClick(Sender: TObject);

    function HutoGb(_kod: byte): byte;
    function Tomorito(_ts: string): string;
    function Angolra(_huName: string): string;
    procedure NEVEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ANYJAEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SZULHELYEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SZULIDOEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure NATVALOKEGOMBClick(Sender: TObject);
    procedure NATVALMEGSEMGOMBClick(Sender: TObject);
    procedure NATLETILTOGOMBClick(Sender: TObject);
    procedure NEVEDITEnter(Sender: TObject);
    procedure NEVEDITExit(Sender: TObject);
    procedure JNEVEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure JTELEPHELYEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure JFOTEVEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure JOKIRATEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  
    procedure JMBNEVEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure JOGILETILTOGOMBClick(Sender: TObject);
    procedure JOGIDATAOKEGOMBClick(Sender: TObject);
    procedure PENZFORRASGOMBClick(Sender: TObject);
   
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _vanletiltas,_ezuj: boolean;
  _asc,_tiltva: byte;
  _height,_width,_top,_left,_year,_lastyear,_kertev: word;
  _recno,_sorszam: integer;
  _ttipus,_evtizes,_aktfdb,_remotePath,_pcs,_tablanev,_nev,_anyja,_jnev: string;
  _szulhely,_szulido,_telephely,_fotev,_mbneve,_lakcim,_jogiszemelynev: string;
  _nevtabla,_fdbpath,_unev,_uanyja,_uszulhely,_uszulido,_lastmezo: string;
  _jtelep,_jFotev,_jOkirat,_jMbnev,_kbetu,_Lmezo: string;

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

// =============================================================================
            procedure TForm2.ListaGombClick(Sender: TObject);
// =============================================================================

begin
  TiltoMenuPanel.Visible := False;
  with ListaPanel do
    begin
      top  := 8;
      left := 8;
      Visible := true;
      repaint;
    end;  

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
  MenuBe;
end;

// =============================================================================
               procedure TForm2.NaturGombClick(Sender: TObject);
// =============================================================================

begin
  TipusValasztoPanel.Visible := False;
  _tTipus := 'N';
  Levalogatas;
end;

// =============================================================================
            procedure TForm2.jogigombClick(Sender: TObject);
// =============================================================================

begin
  TipusValasztoPanel.Visible := False;
  _tTipus := 'J';
  Levalogatas;
end;


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

// =============================================================================
                  procedure TForm2.NaturLevalogatas;
// =============================================================================
begin
  Locdbase.Connected := True;
  if locTranz.InTransaction then Loctranz.Commit;
  LocTranz.StartTransaction;
  LocParancsPart('DELETE FROM UGYFELEK');
  LocTranz.commit;
  Locdbase.close;

  _year    := yearof(date);
  _evtizes := midstr(inttostr(_year),3,2);
  _aktfdb  := 'UGYFEL'+ _evtizes + '.FDB';

  _remotepath := _host + ':C:\RECEPTOR\DATABASE\' + _aktfdb;

  Remdbase.Close;
  Remdbase.DatabaseName := _remotepath;
  Remdbase.Connected := True;

  Locdbase.Connected := true;
  if loctranz.InTransaction then Loctranz.Commit;
  Loctranz.StartTransaction;

  Levalcsik.Max := 24;

  _vanletiltas := False;
  _asc := 65;
  while _asc<=90 do
    begin
      Levalcsik.Position := _asc-64;
      _tablanev := chr(_asc)+'NEV';

      _pcs := 'SELECT * FROM ' + _tablanev + _sorveg;
      _pcs := _pcs + 'WHERE TILTVA>0';

      with Remquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _recno := recno;
        end;

      If _recno>0 then
        begin
          _vanletiltas := True;
          while not RemQuery.Eof do
            begin
              _sorszam  := Remquery.fieldByNAme('SORSZAM').asinteger;
              _nev      := trim(Remquery.FieldByName('NEV').asString);
              _anyja    := trim(Remquery.FieldByNAme('ANYJANEVE').AsString);
              _szulhely := trim(Remquery.FieldByName('SZULETESIHELY').AsString);
              _szulido  := trim(RemQuery.FieldByName('SZULETESIIDO').asString);
              _lakcim   := trim(RemQuery.FieldByNAme('LAKCIM').asString);
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
              LocParancsPart(_pcs);
              RemQuery.next;
            end;
        end;
      RemQuery.close;
      inc(_asc);
    end;
  Loctranz.commit;
  Locdbase.close;
  RemDbase.close;

  if _vanletiltas=False then
    begin
      ShowMessage('NINCS LETILTOTT TERMÉSZETES SZEMÉLY');
      Modalresult := 1;
    end;

  NaturTiltottListazas;

end;

// =============================================================================
                  procedure TForm2.JogiLevalogatas;
// =============================================================================
begin
  Locdbase.Connected := True;
  if locTranz.InTransaction then Loctranz.Commit;
  LocTranz.StartTransaction;
  LocParancsPart('DELETE FROM JOGISZEMELY');
  LocTranz.commit;
  Locdbase.close;

  _year    := yearof(date);
  _evtizes := midstr(inttostr(_year),3,2);
  _aktfdb  := 'UGYFEL'+ _evtizes + '.FDB';

  _remotepath := _host + ':C:\RECEPTOR\DATABASE\' + _aktfdb;

  Remdbase.Close;
  Remdbase.DatabaseName := _remotepath;
  Remdbase.Connected := True;

  Locdbase.Connected := true;
  if loctranz.InTransaction then Loctranz.Commit;
  Loctranz.StartTransaction;

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
          LocParancsPart(_pcs);
          RemQuery.next;
        end;
      RemQuery.close;
    end;

  Loctranz.commit;
  Locdbase.close;
  RemDbase.close;

  if _recno=0 then
    begin
      ShowMessage('NINCS LETILTOTT JOGI SZEMÉLY');
      Modalresult := 1;
    end;

  JogiTiltottListazas;
end;

// =============================================================================
                 procedure TForm2.NaturTiltottListazas;
// =============================================================================

begin
  LevalogatoPanel.Visible := False;
  Jogisource.Enabled := False;

  _pcs := 'SELECT * FROM UGYFELEK ORDER BY NEV';
  Locdbase.connected := True;
  with LocQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
    end;

  NaturSource.Enabled := True;
  with NaturListazoPanel do
    begin
      Top     := 8;
      Left    := 8;
      Visible := True;
      Repaint;
    end;
  Activecontrol := Naturracs;
  RecordChange;
end;

// =============================================================================
                 procedure TForm2.JogiTiltottListazas;
// =============================================================================

begin
  LevalogatoPanel.Visible := False;
  Natursource.Enabled := False;

  _pcs := 'SELECT * FROM JOGISZEMELY ORDER BY JOGISZEMELYNEV';
  Locdbase.connected := True;
  with LocQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  JogiSource.Enabled := true;


  with JogiListazoPanel do
    begin
      top := 8;
      left := 8;
      visible := True;
      repaint;
    end;
  Activecontrol := Jogiracs;
  JogiRecordChange;
end;

// =============================================================================
        procedure TForm2.NaturRacsKeyUp(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  RecordChange;
end;

// =============================================================================
             procedure TForm2.NaturRacsDblClick(Sender: TObject);
// =============================================================================

begin
  RecordChange;
end;

// =============================================================================
            procedure TForm2.NaturRacsCellClick(Column: TColumn);
// =============================================================================

begin
  RecordChange;
end;

// =============================================================================
                     procedure TForm2.RecordChange;
// =============================================================================

begin
  _nev := trim(LocQuery.FieldByNAme('NEV').asString);
  _sorszam := Locquery.FieldByName('SORSZAM').asInteger;
  _tiltva := LocQuery.fieldbyname('TILTVA').asInteger;

  if _tiltva=2 then CsakforrasPanel.Visible := True
  else Csakforraspanel.Visible := False;

  NaturNevedit.text := _nev;
  NaturNevEdit.repaint;
end;

// =============================================================================
           procedure TForm2.NaturListaVisszaGombClick(Sender: TObject);
// =============================================================================

begin
  NaturListazoPanel.Visible := False;
  LocQuery.close;
  Locdbase.close;
  Menube;
end;

// =============================================================================
               procedure TForm2.JogiRacsDblClick(Sender: TObject);
// =============================================================================

begin
  JogiRecordChange;
end;

// =============================================================================
                procedure TForm2.JogiRacsCellClick(Column: TColumn);
// =============================================================================

begin
  JogiRecordChange;
end;

// =============================================================================
      procedure TForm2.JOGIRACSKeyUp(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  JogiRecordChange;
end;

// =============================================================================
                       procedure TForm2.JogiRecordChange;
// =============================================================================

begin
  _jogiszemelynev := trim(LocQuery.FieldByNAme('JOGISZEMELYNEV').AsString);
  _sorszam := Locquery.fieldByName('SORSZAM').AsInteger;
  Joginevedit.Text := _jogiSzemelyNev;
  JoginevEdit.repaint;
end;

// =============================================================================
          procedure TForm2.JogiListaVisszaGombClick(Sender: TObject);
// =============================================================================

begin
  JogiListazoPanel.Visible := False;
  LocQuery.close;
  LocDbase.close;
  Menube;
end;

// =============================================================================
            procedure Tform2.NaturVisszaVonoGombClick(Sender: TObject);
// =============================================================================

begin
  _nevtabla := leftstr(_unev,1)+'NEV';
  _pcs := 'UPDATE ' + _nevtabla + ' SET TILTVA=0' + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
  RemoteParancs(_pcs);

  NaturListazoPanel.Visible := False;
  LocQuery.close;
  LocDbase.close;

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
  LocQuery.close;
  LocDbase.close;
  Menube;
end;




// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
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

// =============================================================================
            procedure TForm2.TRendbenGombClick(Sender: TObject);
// =============================================================================

begin
  LetiltoPanel.Visible := false;
  _evtizes := midstr(inttostr(_kertev),3,2);
  _fdbPath := _host + ':c:\receptor\database\ugyfel'+_evtizes+'.FDB';
  Remdbase.close;

  Remdbase.DatabaseName := _FdbPath;
  if _ttipus='N' then Naturtiltas else jogitiltas;
end;

// =============================================================================
                           procedure TForm2.NaturTiltas;
// =============================================================================

begin
  with ListaPanel do
    begin
      top := 8;
      LEFT := 8;
      Visible := True;
      repaint;
    end;

  with NaturKivalasztoPanel do
    begin
      top := 8;
      left := 8;
      Visible := True;
      repaint;
    end;

  Nevedit.Clear;
  AnyjaEdit.Clear;
  SzulhelyEdit.Clear;
  SzulidoEdit.Clear;

  with NatValDataIn do
    begin
      left    := 220;
      Top     := 80;
      Visible := true;
      repaint;
    end;
  NatValOkeGomb.enabled := False;  
  Activecontrol := NevEdit;
end;

// =============================================================================
                            procedure TForm2.JogiTiltas;
// =============================================================================

begin
  Listapanel.left := 8;
  ListaPanel.visible := true;

  with JogiKivalasztoPanel do
    begin
      top := 8;
      left := 8;
      Visible := True;
      repaint;
    end;

  jNevedit.Clear;
  jTelephelyEdit.Clear;
  jFotevEdit.Clear;
  jOkiratEdit.Clear;
  jMbNevEdit.clear;

  with JogiValDataIn do
    begin
      left    := 220;
      Top     := 80;
      Visible := true;
      repaint;
    end;
  JogiDataOkeGomb.Enabled := False;
  Activecontrol := JNevEdit;
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

  _ezuj := False;
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
          NatvalDataIn.Visible := False;
          NaturkivalasztoPanel.Visible := False;
          Menube;
          exit;
        end;
    end;

  GombTakaroPanel.Visible := False;

end;

// =============================================================================
           procedure TForm2.NATLETILTOGOMBClick(Sender: TObject);
// =============================================================================

begin
  _tiltva := 1;
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
  NatValDataIn.visible := False;
  NaturkivalasztoPanel.Visible := False;
end;

{
// =============================================================================
                    procedure TForm2.JogiLevalogatas;
// =============================================================================

var _cc: integer;

begin
  Locdbase.Connected := True;
  if locTranz.InTransaction then Loctranz.Commit;
  LocTranz.StartTransaction;
  LocParancsPart('DELETE FROM JOGISZEMELY');
  LocTranz.commit;
  Locdbase.close;

  _year    := yearof(date);
  _evtizes := midstr(inttostr(_year),3,2);
  _aktfdb  := 'UGYFEL'+ _evtizes + '.FDB';

  _remotepath := 'C:\RECEPTOR\DATABASE\' + _aktfdb;

  Remdbase.Close;
  Remdbase.DatabaseName := _remotepath;
  Remdbase.Connected := True;

  Locdbase.Connected := true;
  if loctranz.InTransaction then Loctranz.Commit;
  Loctranz.StartTransaction;

  _tablanev := 'JOGI';

  _pcs := 'SELECT * FROM JOGI' + _sorveg;
  _pcs := _pcs + 'WHERE TILTVA=1';

  with Remquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  If _recno>0 then
    begin
      Levalcsik.Max := _recno;
      _cc := 0;
      while not RemQuery.Eof do
        begin
          inc(_cc);
          Levalcsik.Position := _cc;

         _sorszam   := Remquery.fieldByNAme('SORSZAM').asinteger;
         _nev       := trim(Remquery.FieldByName('JOGISZEMELYNEV').asString);
         _telephely := trim(Remquery.FieldByNAme('TELEPHELYCIM').AsString);
         _FOTEV     := trim(Remquery.FieldByName('FOTEVEKENYSEG').AsString);
         _mbneve    := trim(RemQuery.FieldByName('MEGBIZOTTNEVE').asString);

         _pcs := 'INSERT INTO JOGISZEMELY (JOGISZEMELYNEV,TELEPHELYCIM,FOTEVEKENYSEG,';
         _pcs := _pcs + 'MEGBIZOTTNEVE,SORSZAM)' + _sorveg;
         _pcs := _pcs + 'VALUES (' + chr(39) + _nev + chr(39) + ',';
         _pcs := _pcs + chr(39) + _telephely + chr(39) + ',';
         _pcs := _pcs + chr(39) + _fotev + chr(39) + ',';
         _pcs := _pcs + chr(39) + _mbneve + chr(39) + ',';
         _pcs := _pcs + inttostr(_sorszam) + ')';
         LocParancsPart(_pcs);
         RemQuery.next;
        end;
    end;

  RemQuery.close;
  Loctranz.commit;
  Locdbase.close;
  RemDbase.close;
end;
}




// =============================================================================
            procedure TForm2.ATHOZOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Tiltomenupanel.visible := false;
  with AthozoPanel do
    begin
      top := 40;
      left := 120;
      Visible := True;
      repaint;
    end;

  _year    := yearof(date);
  _evtizes := midstr(inttostr(_year),3,2);
  _aktfdb  := 'UGYFEL'+ _evtizes + '.FDB';

  _remotepath := 'C:\RECEPTOR\DATABASE\' + _aktfdb;

  Remdbase.Close;
  Remdbase.DatabaseName := _remotepath;

end;

// =============================================================================
           procedure TForm2.ATHOZMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  AthozoPanel.Visible := False;
  Menube;
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
             procedure TForm2.LocParancsPart(_ukaz: string);
// =============================================================================

begin
  with LocQuery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
end;

// =============================================================================
                   procedure TForm2.NaturAdatAtmasolo;
// =============================================================================

begin
  _pcs := 'DELETE FROM UGYFELEK';

  locParancsPart(_pcs);
  LocTranz.commit;
  Locdbase.close;

  Locdbase.Connected := True;
  if LocTranz.InTransaction then Loctranz.Commit;
  LocTranz.StartTransaction;

  _asc := 65;
  while _asc<=90 do
    begin
      Csik.Position := _asc-64;

      _tablanev := chr(_asc)+'NEV';
      _pcs := 'SELECT * FROM ' + _tablanev + _sorveg;
      _pcs := _pcs + 'WHERE TILTVA=1';
      with Remquery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _recno := recno;
        end;

      if _recno>0 then
        begin
          while not Remquery.Eof do
            begin
              _sorszam := Remquery.fieldByNAme('SORSZAM').asinteger;
              _nev := trim(Remquery.FieldByName('NEV').asString);
              _anyja := trim(Remquery.FieldByNAme('ANYJANEVE').AsString);
              _szulhely := trim(Remquery.FieldByName('SZULETESIHELY').AsString);
              _szulido := trim(RemQuery.FieldByName('SZULETESIIDO').asString);

              Locmemo.Lines.Add(_nev);

              _pcs := 'INSERT INTO UGYFELEK (NEV,ANYJANEVE,SZULETESIHELY,';
              _pcs := _pcs + 'SZULETESIIDO,SORSZAM)' + _sorveg;
              _pcs := _pcs + 'VALUES (' + chr(39) + _nev + chr(39) + ',';
              _pcs := _pcs + chr(39) + _anyja + chr(39) + ',';
              _pcs := _pcs + chr(39) + _szulhely + chr(39) + ',';
              _pcs := _pcs + chr(39) + _szulido + chr(39) + ',';
              _pcs := _pcs + inttostr(_sorszam) + ')';

              RemMemo.Lines.add(_nev);

              LocParancsPart(_pcs);
              RemQuery.next;
            end;
        end;
      RemQuery.close;
      inc(_asc);
    end;
  Loctranz.commit;
  LocDbase.close;
  Remdbase.close;
end;

// =============================================================================
             procedure TForm2.VisszaGombClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
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





procedure TForm2.NATVALMEGSEMGOMBClick(Sender: TObject);
begin
  NatValDataIn.Visible := false;
  NaturKivalasztoPanel.Visible := False;
  Menube;
end;




procedure TForm2.NEVEDITEnter(Sender: TObject);
begin
  TEdit(sender).Color := clYellow;
end;

procedure TForm2.NEVEDITExit(Sender: TObject);
begin
  TEdit(sender).Color := clWindow;
end;

procedure TForm2.JNEVEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;

  _jnev := trim(Jnevedit.Text);
  if _jNev='' then exit;

  Activecontrol := jTelephelyEdit;
end;

procedure TForm2.JTELEPHELYEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  _jtelep := trim(JtelephelyEdit.Text);
  if _jTelep='' then exit;

  Activecontrol := jFotevEdit;
end;


procedure TForm2.JFOTEVEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;

  _jfotev := trim(jFotevEdit.Text);
  if _jFotev='' then exit;

  Activecontrol := JOkiratedit;
end;

procedure TForm2.JOKIRATEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
   if ord(key)<>13 then exit;
   _jokirat := trim(Jokiratedit.text);
   if _jokirat='' then exit;

   Activecontrol := jmbnevedit;
end;




procedure TForm2.JMBNEVEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  _jmbnev := trim(JMBNEVEDIT.Text);
  if _jmbnev='' then exit;

  JogiDataOkeGomb.Enabled := true;
  Activecontrol := JogiDataOkegomb;
end;

procedure TForm2.JOGIDATAOKEGOMBClick(Sender: TObject);


begin
  _jnev := trim(Jnevedit.Text);
  if _jNev='' then exit;

  _jtelep := trim(JtelephelyEdit.Text);
  if _jTelep='' then exit;

  _jfotev := trim(jFotevEdit.Text);
  if _jFotev='' then exit;

   _jokirat := trim(Jokiratedit.text);
   if _jokirat='' then exit;

  _jmbnev := trim(JMBNEVEDIT.Text);
  if _jmbnev='' then exit;

  _pcs := 'SELECT * FROM JOGI' + _sorveg;
  _pcs := _pcs + 'WHERE (JOGISZEMELYNEV=' + chr(39) + _jnev + chr(39)+') AND (';
  _pcs := _pcs + 'OKIRATSZAM=' + chr(39) + _jokirat + chr(39) + ')';

  Remdbase.Connected := true;
  with RemQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  _ezuj := False;
  _sorszam := 0;

  if _recno=0 then
    begin
      RemQuery.close;
      Remdbase.close;
      _ezuj := True;
    end else
    begin
      _jNev    := trim(Remquery.FieldByNAme('JOGISZEMELYNEV').asString);
      _jTelep  := trim(RemQuery.fieldByName('TELEPHELYCIM').asString);
      _jFotev  := trim(RemQuery.fieldByNAme('FOTEVEKENYSEG').AsString);
      _jOkirat := trim(RemQuery.FieldByNAme('OKIRATSZAM').asString);
      _jmbnev  := trim(Remquery.FieldByNAme('MEGBIZOTTNEVE').asString);
      remquery.close;
      remdbase.close;
    end;

  JogiletiltoGomb.enabled := true;
  JogidataOkeGomb.enabled := false;
  ActiveControl := JogiLetiltoGomb;
end;

procedure TForm2.JogiLetiltoGombClick(Sender: TObject);

begin
  exit;
  {
  JogiJelzoPanel.Visible := True;
  JogiJelzoPanel.Repaint;
  If _ezuj then
    begin
      _pcs := 'SELECT * FROM LASTNUMS';
      RemDbase.connected := true;
      with Remquery do
        begin
          close;
          Sql.clear;
          sql.add(_pcs);
          Open;
          _sorszam := FieldByNAme('JOGILAST').asInteger;
          close;
        end;
      Remdbase.close;
      inc(_sorszam);
      _pcs := 'UPDATE LASTNUMS SET JOGILAST=' + inttostr(_sorszam);
      RemoteParancs(_pcs);

      _pcs := 'INSERT INTO JOGI (SORSZAM,

   }

end;



procedure TForm2.PENZFORRASGOMBClick(Sender: TObject);
begin
  _tiltva := 2;
  GombTakaroPanel.Visible := true;
  UgyfelLetiltas;
  Menube;

end;

end.
