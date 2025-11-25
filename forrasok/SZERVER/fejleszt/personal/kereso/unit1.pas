unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, IBDatabase, DB, IBCustomDataSet,
  IBQuery, Grids, DBGrids, strutils, jpeg, ComCtrls, DATEUTILS, IBTable,
  Comobj;

type
  TForm1 = class(TForm)
    SEEKMENUPANEL: TPanel;
    Label1: TLabel;
    NEVKEZDETGOMB: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    NEVELEJEPANEL: TPanel;
    Label2: TLabel;
    nevedit: TEdit;
    Label3: TLabel;
    NevEloOkeGomb: TBitBtn;
    evelomegsemgomb: TBitBtn;
    SEEKQUERY: TIBQuery;
    SEEKDBASE: TIBDatabase;
    SEEKTRANZ: TIBTransaction;
    FINDQUERY: TIBQuery;
    FINDDBASE: TIBDatabase;
    FINDTRANZ: TIBTransaction;
    FindRacsPanel: TPanel;
    FINDSOURCE: TDataSource;
    FINDRACS: TDBGrid;
    Label4: TLabel;
    ESPANEL: TPanel;
    Label6: TLabel;
    FELTETELLISTA: TListBox;
    NEXTPANEL: TPanel;
    kovirpanel: TPanel;
    NEXTEDIT: TEdit;
    ESOKEGOMB: TBitBtn;
    ESMEGSEMGOMB: TBitBtn;
    morecondipanel: TPanel;
    Label8: TLabel;
    VANCONDIGOMB: TBitBtn;
    NOCONDIGOMB: TBitBtn;
    Label5: TLabel;
    fieldcombo: TComboBox;
    KEZDETEGOMB: TBitBtn;
    TARTALMAZZAGOMB: TBitBtn;
    FELTETELCSIKPANEL: TPanel;
    NEVTOREDEKPANEL: TPanel;
    Label7: TLabel;
    Label9: TLabel;
    NEVTOREDIT: TEdit;
    TOROKEGOMB: TBitBtn;
    TORMEGSEMGOMB: TBitBtn;
    MASADATPANEL: TPanel;
    Label10: TLabel;
    KERCOMBO: TComboBox;
    Label11: TLabel;
    CHILDPANEL: TPanel;
    kerkezdgomb: TBitBtn;
    KERTTARTGOMB: TBitBtn;
    mezonevpanel: TPanel;
    KERDATAEDIT: TEdit;
    KERDATAOKEGOMB: TBitBtn;
    KERDATAMEGSEMGOMB: TBitBtn;
    KERMEZOMEGSEMGOMB: TBitBtn;
    KERMEZOOKEGOMB: TBitBtn;
    alaplap: TPanel;
    escapegomb: TBitBtn;
    Image1: TImage;
    Shape2: TShape;
    KERMENUPANEL: TPanel;
    Label12: TLabel;
    TOTDBGOMB: TBitBtn;
    KFTGOMB: TBitBtn;
    KORZETGOMB: TBitBtn;
    PENZTARGOMB: TBitBtn;
    NOSEEKGOMB: TBitBtn;
    Shape3: TShape;
    KFTPANEL: TPanel;
    PRADIO: TRadioButton;
    ERADIO: TRadioButton;
    BRADIO: TRadioButton;
    START1: TBitBtn;
    Q1: TBitBtn;
    KORZETPANEL: TPanel;
    K1: TRadioButton;
    K2: TRadioButton;
    K3: TRadioButton;
    K4: TRadioButton;
    K5: TRadioButton;
    K6: TRadioButton;
    K7: TRadioButton;
    K8: TRadioButton;
    START2: TBitBtn;
    Q2: TBitBtn;
    IRODAPANEL: TPanel;
    IRODALISTA: TListBox;
    START3: TBitBtn;
    Q3: TBitBtn;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    CSIKHUZOPANEL: TPanel;
    KERFOCIMPANEL: TPanel;
    MESSPANEL: TPanel;
    CSIK: TProgressBar;
    Shape4: TShape;
    TABLACSIK: TProgressBar;
    masikugyfelGomb: TBitBtn;
    kervallumcsikpanel: TPanel;
    TRANZAKCIOKGOMB: TBitBtn;
    BIZONYLATKERESOPANEL: TPanel;
    UGYFELNEVPANEL: TPanel;
    Label13: TLabel;
    TOLEVCOMBO: TComboBox;
    TOLHOCOMBO: TComboBox;
    Label14: TLabel;
    IGEVCOMBO: TComboBox;
    IGHOCOMBO: TComboBox;
    Label15: TLabel;
    Shape5: TShape;
    BIZSEEKGOMB: TBitBtn;
    noseekbizGomb: TBitBtn;
    Panel1: TPanel;
    BIZKERCSIK: TProgressBar;
    BFTABLA: TIBTable;
    BIZONYLATQUERY: TIBQuery;
    BIZONYLATDBASE: TIBDatabase;
    BIZONYLATTRANZ: TIBTransaction;
    BFQUERY: TIBQuery;
    BFDBASE: TIBDatabase;
    BFTRANZ: TIBTransaction;
    BTQUERY: TIBQuery;
    BTDBASE: TIBDatabase;
    BTTRANZ: TIBTransaction;
    BIZONYLATRACSPANEL: TPanel;
    BIZONYLATSOURCE: TDataSource;
    BIZONYLATFOCIMPANEL: TPanel;
    BIZONYLATRACS: TDBGrid;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    infopanel: TPanel;
    BIZONYLATQUERYDATUM: TIBStringField;
    BIZONYLATQUERYIDO: TIBStringField;
    BIZONYLATQUERYBIZONYLATSZAM: TIBStringField;
    BIZONYLATQUERYTIPUS: TIBStringField;
    BIZONYLATQUERYVALUTANEM: TIBStringField;
    BIZONYLATQUERYBANKJEGY: TIntegerField;
    BIZONYLATQUERYARFOLYAM: TIntegerField;
    BIZONYLATQUERYFORINTERTEK: TIntegerField;
    BIZONYLATQUERYPENZTAR: TSmallintField;
    BIZONYLATQUERYPENZTARNEV: TIBStringField;

    procedure NEVKEZDETGOMBClick(Sender: TObject);
    procedure IrodaBeolvasas;
    procedure Tol_Ig_beallito;
    procedure UgyfeletValasztott;
    function GetPenztarNev(_apt: byte):string;

    procedure TalalatDisplay;
    procedure neveditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);

    procedure NevEloOkeGombClick(Sender: TObject);
    function GetkorzetNev(_k: byte): string;
    procedure IrodatValasztott;
    procedure FindParancs(_ukaz: string);
    procedure FormActivate(Sender: TObject);
    procedure evelomegsemgombClick(Sender: TObject);
    procedure NOCONDIGOMBClick(Sender: TObject);
    procedure VANCONDIGOMBClick(Sender: TObject);
    procedure KEZDETEGOMBClick(Sender: TObject);
    procedure TARTALMAZZAGOMBClick(Sender: TObject);
    procedure nexteditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ESOKEGOMBClick(Sender: TObject);
    procedure fieldcomboChange(Sender: TObject);
    procedure neveditEnter(Sender: TObject);
    procedure neveditExit(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure TOROKEGOMBClick(Sender: TObject);
    procedure NEVTOREDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure BitBtn4Click(Sender: TObject);
    procedure KERMEZOOKEGOMBClick(Sender: TObject);
    procedure kerkezdgombClick(Sender: TObject);
    procedure KERTTARTGOMBClick(Sender: TObject);
    procedure KERDATAEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure KERMEZOMEGSEMGOMBClick(Sender: TObject);
    procedure TORMEGSEMGOMBClick(Sender: TObject);
    procedure KERDATAMEGSEMGOMBClick(Sender: TObject);
    procedure ESMEGSEMGOMBClick(Sender: TObject);
    procedure KERCOMBOChange(Sender: TObject);
    procedure KERDATAOKEGOMBClick(Sender: TObject);
    procedure masikugyfelGombClick(Sender: TObject);
    procedure KFTGOMBClick(Sender: TObject);
    procedure KORZETGOMBClick(Sender: TObject);
    procedure PENZTARGOMBClick(Sender: TObject);
    procedure Q1Click(Sender: TObject);
    procedure IRODALISTAKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure IRODALISTAClick(Sender: TObject);
    procedure TOTDBGOMBClick(Sender: TObject);
    procedure StartKereses(Sender: TObject);
    procedure EgytablabanKereses;
    procedure START1Click(Sender: TObject);
    procedure START2Click(Sender: TObject);
    procedure START3Click(Sender: TObject);
    procedure escapegombClick(Sender: TObject);
 
    procedure TRANZAKCIOKGOMBClick(Sender: TObject);
    procedure TOLEVCOMBOChange(Sender: TObject);

    procedure noseekbizGombClick(Sender: TObject);
    procedure BIZSEEKGOMBClick(Sender: TObject);
    function Nulele(_b: byte): string;
    procedure BizonylatBemasolas;
    procedure Bizonylatdisplay;
    procedure FINDRACSKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _pTabla: array[1..6] of string;
  _magy,_mezo: array[0..10] of string;

  _fi,_ri: array[0..25] of byte;
  _ksz: array[0..25] of string;

  _penztarszam,_ptertektar: array[0..149] of byte;
  _penztarnev,_ptcegbetu: array[0..149] of string;

  _korzNum: array[1..8] of byte = (10,20,40,50,63,75,120,145);
  _korzNev: array[1..8] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
             'DEBRECEN','NYÍREGHÁZA','BÉKÉSCSABA','PÉCS','KAPOSVÁR');

  _hoNev: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS',
                        'MÁJUS','JÚNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER',
                        'OKTÓBER','NOVEMBER','DECEMBER');

  _aktev,_aktho: word;

  _fieldIndex,_condidb,_kerindex,_penztardarab,_kertiroda,_kerVallum: byte;
  _kertKorzet,_seektype,_tDarab,_evindex,_hoindex,_ugypenztar: byte;
  _y,_ugyfelszam: integer;

  _keres,_akttablanev,_feltetel,_condition,_aktnev,_kertirodanev: string;
  _kezdobetukod,_ptPtr,_aktetar,_penztar,_aktpt,_aktet: byte;

  _nev,_elozonev,_anyjaneve,_leanykori,_szulhely,_szulido,_allampolg: string;
  _lakcim,_okmtip,_azonosito,_tarthely,_lcimcard,_telefon,_emailcim: string;
  _aktdatum,_aktceg,_pcs,_nextkeres,_kotoszo,_esKeres,_kertkft,_ptnev: string;
  _kerfocim,_kertkorzetnev,_kertkftnev,_evs,_ugyfelnev,_rangestr: string;

  _sorveg: string = chr(13)+chr(10);
  _recno,_irodaindex,_sptr: integer;

  _css,_fix,_rix: byte;
  _kerszo,_ugyFdbPath,_igevhos,_tolevhos,_aktevhos,_valutanem,_last: string;

  _kertTolEv,_kertTolHo: word;
  _kertIgEv,_kertigHo,_tolev,_tolho,_rekordDb: word;
  _napindex,_igev,_igho,_xEv,_xHo,_prisor: word;

  _farok,_bfTablanev,_btTablanev,_bizonylatszam,_datum,_ido,_tipus: string;
  _bankjegy,_arfolyam,_ftertek,_forint: integer;

  _foundbizonylat,_vanExcel: boolean;
  _oxl,_owb: Olevariant;


implementation

{$R *.dfm}


// =============================================================================
              procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

var _y: byte;

begin
  CsikHuzopanel.Visible   := False;
  EsPanel.Visible         := False;
  NextPanel.Visible       := False;
  MoreCondiPanel.Visible  := False;
  FindRacsPanel.Visible   := False;
  Seekmenupanel.visible   := false;
  Nevelejepanel.Visible   := False;
  MasAdatPanel.Visible    := False;
  NevToredekPanel.Visible := False;
  KerMenuPanel.Visible    := False;
  KerVallumCsikPanel.Visible := False;
  FeltetelCsikPanel.Visible := False;
  KftPanel.Visible        := False;
  KorzetPanel.Visible     := False;
  IrodaPanel.Visible      := False;
  BizonylatracsPanel.Visible   := false;
  BizonylatkeresoPanel.Visible := False;

  FindracsPanel.visible   := False;
  FindSource.Enabled      := False;
  _vanExcel := false;

  _pTabla[1] := 'ADUGYFEL';
  _pTabla[2] := 'EHUGYFEL';
  _pTabla[3] := 'ILUGYFEL';
  _pTabla[4] := 'MPUGYFEL';
  _pTabla[5] := 'QTUGYFEL';
  _pTabla[6] := 'UZUGYFEL';

  _magy[0] := 'ÜGYFÉL NEVE';
  _magy[1] := 'ANYJA NEVE';
  _magy[2] := 'LAKÁS CÍME';
  _magy[3] := 'SZÜLETÉSI HELYE';
  _magy[4] := 'SZÜLETÉSI IDEJE';
  _magy[5] := 'OKMÁNY SZÁMA';
  _magy[6] := 'LEÁNYKORI NEVE';
  _magy[7] := 'LAKCÍM KÁRTYÁJA';
  _magy[8] := 'ÁLLAMPOLGÁRSÁGA';
  _magy[9] := 'ELÖZÕ NEVE';
  _magy[10] := 'TARTOZKODÁSI HELYE';

  _mezo[0] := 'NEV';
  _mezo[1] := 'ANYJANEVE';
  _mezo[2] := 'LAKCIM';
  _mezo[3] := 'SZULETESIHELY';
  _mezo[4] := 'SZULETESIIDO';
  _mezo[5] := 'AZONOSITO';
  _mezo[6] := 'LEANYKORI';
  _mezo[7] := 'LAKCIMKARTYA';
  _mezo[8] := 'ALLAMPOLGAR';
  _mezo[9] := 'ELOZONEV';
  _mezo[10] := 'TARTOZKODASIHELY';

  Irodabeolvasas;

  FieldCombo.Items.clear;
  KerCombo.Items.clear;
  _y := 1;
  while _y<=10 do
    begin
      FieldCombo.Items.Add(_magy[_y]);
      KerCombo.Items.add(_magy[_y]);
      inc(_y);
    end;
  FieldCombo.ItemIndex := 0;
  KerCombo.ItemIndex := 0;
  with SeekMenuPanel do
    begin
      Top := 240;
      Left := 390;
      Visible := true;
      Repaint;
    end;
  ActiveControl := NevKezdetGomb;
end;


// =============================================================================
              procedure TForm1.BitBtn3Click(Sender: TObject);
// =============================================================================

begin
  _seektype := 1;  // Név töredék alapján
  SeekMenuPanel.visible := false;
  MoreCondiPanel.Visible := false;
  ESPANEL.Visible := False;

  NevTorEdit.clear;
  TorOkeGomb.Enabled := false;

  with NevToredekPanel do
    begin
      Top := 32;
      Left:= 400;
      Visible := true;
    end;
  Activecontrol := NevToredit;

end;


// =============================================================================
                procedure TForm1.BitBtn4Click(Sender: TObject);
// =============================================================================

begin
  _seekType := 2;   // Más adat alapján keres;
  SeekMenuPanel.visible := false;
  MoreCondiPanel.Visible := false;
  EsPanel.Visible := False;

  NevTorEdit.clear;
  TorOkeGomb.Enabled := false;
  ChildPanel.Visible := False;
  with MasAdatPanel do
    begin
      Top := 32;
      Left:= 400;
      Visible := true;
    end;
  Activecontrol := KermezoOkegomb;

end;


// =============================================================================
             procedure TForm1.NEVKEZDETGOMBClick(Sender: TObject);
// =============================================================================

begin
  _seekType := 0;  // Név kezdete alapján
  SeekMenuPanel.visible := false;
  MoreCondiPanel.Visible := false;
  ESPANEL.Visible := False;

  Nevedit.clear;
  NevEloOkeGomb.Enabled := false;

  with NevelejePanel do
    begin
      Top := 32;
      Left:= 400;
      Visible := true;
    end;
  Activecontrol := Nevedit;
end;

// =============================================================================
     procedure TForm1.NEVTOREDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(Key)<>13 then exit;
  _keres := trim(NevToredit.Text);
  if _keres='' then exit;
  Torokegomb.Enabled := true;
  Activecontrol := TorOkeGomb;
end;


// =============================================================================
     procedure TForm1.neveditKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(Key)<>13 then exit;
  _keres := trim(Nevedit.Text);
  if _keres='' then exit;
  Nevelookegomb.Enabled := true;
  Activecontrol := NeveloOkeGomb;

end;


// =============================================================================
               procedure TForm1.TOROKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  Feltetellista.Items.clear;
  FeltetelLista.clear;
  NevtoredekPanel.visible := False;
  FeltetelLista.Items.add('aki NEVE tartalmazza = '+_keres);
   with Espanel do
    begin
      Top := 32;
      Left := 320;
      Visible := true;
    end;

  _condidb := 1;

  _fi[0]  := 0;
  _ri[0]  := 1;

  _ksz[0] := _keres;
  with MoreCondiPanel do
    begin
      Top := 290;
      Left := 320;
      Visible := true;
    end;
  ActiveControl := NoCondiGomb;

end;


// =============================================================================
               procedure TForm1.NevEloOkeGombClick(Sender: TObject);
// =============================================================================

begin
  Feltetellista.Items.clear;
  FeltetelLista.clear;
  NevelejePanel.Visible := False;
  FeltetelLista.Items.add('aki NEVÉNEK kezdete = '+_keres);
  with Espanel do
    begin
      Top := 32;
      Left := 320;
      Visible := true;
    end;

  _condidb := 1;
  _fi[0]  := 0;
  _ri[0]  := 0;
  _ksz[0] := _keres;
  with MoreCondiPanel do
    begin
      Top := 290;
      Left := 320;
      Visible := true;
    end;
  ActiveControl := NoCondiGomb;
end;

// =============================================================================
           procedure TForm1.NOCONDIGOMBClick(Sender: TObject);
// =============================================================================

begin
  espanel.visible := false;

  MoreCondiPanel.Visible := False;
  _feltetel := '';
  _condition := '';
  _css := 0;
  while _css<_condidb do
    begin
      _fix := _fi[_css];
      _rix := _ri[_css];     // _rix=0 -> eleje, _rix=1 -> tartalmaz
      _kerszo := _ksz[_css];
      _condition := _condition + '(' + _mezo[_fix] + ' LIKE ' +chr(39);
      if _rix=1 then _condition := _condition + '%';
      _condition := _condition + _kerszo + '%'+ CHR(39)+ ')';

      _feltetel := _feltetel + _magy[_fix]+' ';
      if _rix=0 then _feltetel := _feltetel + 'eleje '
      else _feltetel := _feltetel + 'tartalmazza ';
      _felTetel := _feltetel + _kerszo;
      inc(_css);
      if _css<_condidb then
        begin
          _condition := _condition + ' AND ';
          _feltetel := _Feltetel + ' és ';
        end;
   end;

  FeltetelCsikPanel.caption := 'FELTÉTEL: ' + _FELTETEL;
  with FeltetelCsikPanel do
    begin
      Top := 16;
      Left := 16;
      caption := 'FELTÉTEL: '+_feltetel;
      Visible := true;
      repaint;
    end;

  with KermenuPanel do
    begin
      Top := 80;
      Left := 325;
      Visible := True;
    end;

  Activecontrol := TotdbGomb;

end;


// =============================================================================
                       procedure TForm1.TalalatDisplay;
// =============================================================================

begin
  Finddbase.Connected := True;
  with Findquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VALOGATAS');
      Open;
      First;
      _recno := Recno;
    end;

  if _recno=0 then
    begin
      FindQuery.close;
      FindDbase.close;
      ShowMessage('NEM TALÁLTAM ÜGYFELET A MEGADOTT ADATOK FIGYELEMBEVÉTELÉVEL !');

      with SeekMenuPanel do
        begin
          Top := 240;
          Left := 390;
          Visible := true;
          Repaint;
        end;
      ActiveControl := NevKezdetGomb;
      exit;
    end;

  Findsource.Enabled := true;
  with FindRacsPanel do
    begin
      Left := 24;
      Top := 72;
      Visible := true;
    end;
  Activecontrol := Findracs;
end;



// =============================================================================
                procedure TForm1.FindParancs(_ukaz: string);
// =============================================================================

begin
  Finddbase.connected := true;
  if Findtranz.InTransaction then Findtranz.commit;
  Findtranz.StartTransaction;
  with Findquery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  Findtranz.Commit;
  Finddbase.close;
end;

// =============================================================================
           procedure TForm1.evelomegsemgombClick(Sender: TObject);
// =============================================================================

begin
  Nevelejepanel.visible := false;
    with SeekMenuPanel do
    begin
      Top := 240;
      Left := 390;
      Visible := true;
      Repaint;
    end;
  ActiveControl := NevKezdetGomb;
end;


// =============================================================================
               procedure TForm1.VANCONDIGOMBClick(Sender: TObject);
// =============================================================================

begin
  MoreCondiPanel.visible := False;
  Activecontrol := KezdeteGomb;

end;

// =============================================================================
               procedure TForm1.KEZDETEGOMBClick(Sender: TObject);
// =============================================================================

begin
  KovirPanel.Caption := 'A KOVETKEZÕ:';
  Nextedit.clear;
  with NextPanel do
    begin
      Top := 416;
      Left :=  320;
      Visible := True;
    end;

  Esokegomb.Enabled := False;
  _kotoszo := 'kezdete = ';
  activeControl := Nextedit;
end;

// =============================================================================
             procedure TForm1.TARTALMAZZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  KovirPanel.Caption := 'A KÖVETKEZÕT:';
  Nextedit.clear;
  with NextPanel do
    begin
      Top := 416;
      Left :=  320;
      Visible := True;
    end;


  Esokegomb.Enabled := False;
  _kotoszo := 'tartalmazza = ';
  activeControl := Nextedit;
end;

// =============================================================================
     procedure TForm1.nexteditKeyDown(Sender: TObject; var Key: Word;
                                                         Shift: TShiftState);
// =============================================================================

begin
  if ord(Key)<>13 then exit;
  _nextkeres := trim(nextedit.Text);
  if _nextkeres='' then exit;
  Esokegomb.Enabled := true;
  Activecontrol := EsOkeGomb;
end;

// =============================================================================
             procedure TForm1.ESOKEGOMBClick(Sender: TObject);
// =============================================================================

var _mondat: string;

begin
  NextPanel.Visible := False;

  _esKeres := trim(Nextedit.Text);
  _FIELDINDEX := FieldCombo.ItemIndex;

  _ksz[_condidb] := _eskeres;
  _fi[_condidb] := 1 + _fieldindex;
  if leftstr(_kotoszo,1)= 'k' then _ri[_condidb] := 0 else _ri[_condidb] := 1;
   inc(_condidb);

  _mondat := 'és ' + _magy[_fieldindex+1]+' '+ _kotoszo + _eskeres;
  FeltetelLista.Items.Add(_mondat);
   with MoreCondiPanel do
    begin
      Top := 290;
      Left := 320;
      Visible := true;
    end;
  MorecondiPanel.BringToFront;
  Activecontrol := Nocondigomb;
end;

// =============================================================================
             procedure TForm1.fieldcomboChange(Sender: TObject);
// =============================================================================

begin
  aCTIVECONTROL := KezdeteGomb;
end;

// =============================================================================
              procedure TForm1.neveditEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := $B0FFFF;
end;

// =============================================================================
             procedure TForm1.neveditExit(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clWindow;
end;

// =============================================================================
            procedure TForm1.KERMEZOOKEGOMBClick(Sender: TObject);
// =============================================================================

var _kermezo: string;

begin
  _kerindex := Kercombo.itemindex;
  _kermezo := _magy[_kerindex+1];

  KerDataEdit.clear;
  KerdataEdit.Visible := false;

  MezonevPanel.Caption := _kermezo;
  KerDataOkegomb.Enabled := false;
  with ChildPanel do
    begin
      Top := 80;
      left := 0;
      Visible := True;
    end;
  Activecontrol := KerKezdGomb;
end;


// =============================================================================
            procedure TForm1.kerkezdgombClick(Sender: TObject);
// =============================================================================

begin
  _rix := 0;
  KerDataEdit.Visible := true;
  Activecontrol := Kerdataedit;
end;


// =============================================================================
             procedure TForm1.KERTTARTGOMBClick(Sender: TObject);
// =============================================================================

begin
  _rix := 1;
  KerDataEdit.Visible := true;
  Activecontrol := Kerdataedit;
end;

// =============================================================================
     procedure TForm1.KERDATAEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  _keres := Trim(KerdataEdit.Text);
  if _keres='' then exit;
  KerdataokeGomb.Enabled := true;
  Activecontrol := KerdataOkeGomb;
end;

// =============================================================================
             procedure TForm1.KERMEZOMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  MasAdatPanel.Visible := False;
    with SeekMenuPanel do
    begin
      Top := 240;
      Left := 390;
      Visible := true;
      Repaint;
    end;
  ActiveControl := NevKezdetGomb;
end;

// =============================================================================
             procedure TForm1.TORMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  NevtoredekPanel.Visible := False;
    with SeekMenuPanel do
    begin
      Top := 240;
      Left := 390;
      Visible := true;
      Repaint;
    end;
  ActiveControl := NevKezdetGomb;
end;

// =============================================================================
          procedure TForm1.KERDATAMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  ChildPanel.Visible := False;
end;

// =============================================================================
              procedure TForm1.ESMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  Nextpanel.Visible := False;
end;

// =============================================================================
                 procedure TForm1.KERCOMBOChange(Sender: TObject);
// =============================================================================

begin
  ActiveControl := KermezoOkeGomb;
end;

// =============================================================================
                procedure TForm1.KERDATAOKEGOMBClick(Sender: TObject);
// =============================================================================

var _aktmezo,_mondat: string;

begin
   Feltetellista.Items.clear;
  FeltetelLista.clear;
  Masadatpanel.Visible := False;
  _kerindex := KerCombo.ItemIndex;
  _aktmezo := _magy[1+_kerindex];
  _mondat := 'aki '+_aktmezo;
  if _rix=0 then _mondat := _mondat + ' kezdete ' else _mondat := _mondat + ' tartalmazza ';
  _mondat := _mondat + '= '+_keres;

  FeltetelLista.Items.add(_mondat);

  _condidb := 1;

  _fi[0]  := 1+_kerindex;
  _ri[0]  := _rix;

  _ksz[0] := _keres;
  with MoreCondiPanel do
    begin
      Top := 290;
      Left := 320;
      Visible := true;
    end;
  ActiveControl := NoCondiGomb;

   with Espanel do
    begin
      Top := 32;
      Left := 320;
      Visible := true;
    end;

end;

// =============================================================================
                procedure TForm1.masikugyfelGombClick(Sender: TObject);
// =============================================================================

begin
  FindQuery.close;
  FindDbase.close;
  
  FindracsPanel.Visible := false;
  CsikhuzoPanel.Visible := False;
  FeltetelcsikPanel.Visible := false;
  KerVallumcsikPanel.Visible := False;

   with SeekMenuPanel do
    begin
      Top := 240;
      Left := 390;
      Visible := true;
      Repaint;
    end;
  ActiveControl := NevKezdetGomb;
end;

// =============================================================================
                procedure TForm1.KFTGOMBClick(Sender: TObject);
// =============================================================================

begin
  _kervallum := 1;  // Egy kft területén keres;
  Pradio.Checked := true;
  with KftPanel do
    begin
      top := 130;
      Left := 327;
      Visible := True;
      repaint;
    end;
end;

// =============================================================================
               procedure TForm1.KORZETGOMBClick(Sender: TObject);
// =============================================================================

begin
  _kervallum := 2;  // Egy körzet területén keres
  K1.Checked := true;
  with KorzetPanel do
    begin
      top := 132;
      Left := 328;
      Visible := True;
      repaint;
    end;
end;

// =============================================================================
                procedure TForm1.PENZTARGOMBClick(Sender: TObject);
// =============================================================================

begin
   _kervallum := 3;  // Csak egy irodában keres;
   with IrodaPanel do
    begin
      top := 133;
      Left := 329;
      Visible := True;
      repaint;
    end;
   Irodalista.ItemIndex := 0;
   IrodaLista.SetFocus;

end;

// =============================================================================
                  procedure TForm1.Q1Click(Sender: TObject);
// =============================================================================

begin
  Application.terminate;
end;

// =============================================================================
                      procedure TForm1.IrodaBeolvasas;
// =============================================================================

begin
  IrodaLista.Items.Clear;
  IrodaLista.Clear;

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE CLOSED=' + chr(39) + 'N' + chr(39);
  Recdbase.Connected := true;
  with recquery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  _penztardarab := 0;
  while not Recquery.Eof do
    begin
      _aktpt := RecQuery.FieldByName('UZLET').asInteger;
      _aktnev:= trim(Recquery.FieldByName('KESZLETNEV').asString);
      _aktet := Recquery.FieldByName('ERTEKTAR').asInteger;
      _aktceg:= RecQuery.FieldByName('CEGBETU').asString;

      _penztarszam[_penztardarab] := _aktpt;
      _penztarnev[_penztardarab]  := _aktnev;
      _ptertektar[_penztardarab]  := _aktet;
      _ptcegbetu[_penztardarab]   := _aktceg;

      IrodaLista.Items.add(_aktnev);
      inc(_penztardarab);

      RecQuery.Next;
    end;
  Recquery.close;
  Recdbase.close;
end;



function TForm1.GetPenztarNev(_apt: byte): string;

var _y: byte;

begin
  _y := 0;
  result := '?';
  while _y<_penztardarab do
    begin
      if _penztarszam[_y]=_apt then
        begin
          result := _penztarnev[_y];
          exit;
        end;
      inc(_y);
    end;
end;





// =============================================================================
     procedure TForm1.IRODALISTAKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  IrodatValasztott;
end;

// =============================================================================
                procedure TForm1.IRODALISTAClick(Sender: TObject);
// =============================================================================

begin
  IrodatValasztott;
end;

// =============================================================================
              procedure TForm1.START1Click(Sender: TObject);
// =============================================================================


begin
  KftPanel.Visible := false;
  if PRadio.checked then
    begin
      _kertkft := 'P';
      _kertkftnev := 'PANNON';
    end;

  if ERadio.checked then
    begin
      _kertkft := 'E';
      _kertkftnev := 'EAST';
    end;

  if BRadio.checked then
    begin
      _kertkft := 'B';
      _kertkftNev := 'BEST';
    end;
  StartKereses(Nil);
end;

// =============================================================================
               procedure TForm1.START2Click(Sender: TObject);
// =============================================================================


begin
  KorzetPanel.Visible := False;

  if K1.Checked then _kertkorzet := 10;
  if K2.Checked then _kertkorzet := 20;
  if K3.Checked then _kertkorzet := 40;
  if K4.Checked then _kertkorzet := 50;
  if K5.Checked then _kertkorzet := 63;
  if K6.Checked then _kertkorzet := 75;
  if K7.Checked then _kertkorzet := 120;
  if K8.Checked then _kertkorzet := 140;

  _kertKorzetNev := GetKorzetNev(_kertkorzet);
  StartKereses(Nil);
end;


// =============================================================================
             function TForm1.GetkorzetNev(_k: byte): string;
// =============================================================================

var _y: byte;

begin
  _y := 1;
  result := '?';

  while _y<=8 do
    begin
      if _korznum[_y]=_k then
        begin
          result := _korzNev[_y];
          exit;
        end;
      inc(_y);
    end;
end;


// =============================================================================
                  procedure TForm1.START3Click(Sender: TObject);
// =============================================================================

begin
  IrodatValasztott;
end;

// =============================================================================
                      procedure TForm1.IrodatValasztott;
// =============================================================================

begin
  _irodaindex := IrodaLista.ItemIndex;
  _kertIroda := _penztarszam[_irodaindex];
  _kertirodanev := _penztarnev[_irodaindex];
  IrodaPanel.Visible := false;
  StartKereses(Nil);

end;

// =============================================================================
                procedure TForm1.TOTDBGOMBClick(Sender: TObject);
// =============================================================================

begin
  _kervallum := 0;  // Teljes adatbázisban keresés;
  KervallumCsikPanel.Caption := 'KERESÉS = A teljes adatbázisban';
  StartKereses(Nil);
end;

// =============================================================================
               procedure TForm1.StartKereses(Sender: TObject);
// =============================================================================

var _kernev: string;

begin
  KermenuPanel.Visible := False;
  Image1.repaint;
  with KervallumcsikPanel do
    begin
      Top := 32;
      Left := 8;
      Visible := True;
      Repaint;
    end;

  _pcs := 'DELETE FROM VALOGATAS';
  FINDparancs(_pcs);
  _ptPtr := 1;
  if _seekType=0 then   // Név eleje az elsõ feltétel;
    begin
      _kernev := _ksz[0];
      _kezdoBetuKod := ord(_kernev[1]);

      _ptPtr := 6;
      case _kezdobetuKod of
        65..68: _ptPtr := 1;
        69..72: _ptPtr := 2;
        73..76: _ptPtr := 3;
        77..80: _ptPtr := 4;
        81..84: _ptPtr := 5;
      end;

      _tDarab := _ptPtr;
      Tablacsik.Max := 2;

    end else
    begin
      _tDarab := 6;
      Tablacsik.max := 7;
    end;

  if _kervallum=0 then _kerfocim := 'KERESÉS = AZ ÖSSZES ADATBÁZISBAN';
  if _kerVallum=1 then _kerfocim := 'KERESÉS = CSAK A '+_kertkftnev+ ' ADATAI KÖZÖTT';
  if _kervallum=2 then _kerfocim := 'KERESÉS = CSAK '+ _kertkorzetnev + ' ADATAI KÖZÖTT';
  if _kervallum=3 then _kerfocim := 'KERESÉS = CSAK A '+_kertirodanev+' ADATAIBAN';

  KerfocimPanel.Caption := _kerfocim;
  KerfocimPanel.Repaint;

  KervallumcsikPanel.Caption := _kerfocim;
  KerVallumCsikPanel.repaint;

  MessPanel.Caption := '';
  MessPanel.repaint;

  KerMenuPanel.Visible := false;


  with CsikHuzoPanel do
    begin
      Top := 200;
      Left := 180;
      Visible := True;
      repaint;
    end;

  while _ptPtr<=_tdarab do
    begin
      Tablacsik.Position := _ptPtr;
      EgytablabanKereses;
      if _seektype=0 then break;
      inc(_ptPtr);
    end;
  TalalatDisplay;
end;


// =============================================================================
                    procedure TForm1.EgytablabanKereses;
// =============================================================================

begin
  _aktTablanev := _pTabla[_ptPtr];
  _pcs := 'SELECT * FROM ' + _aktTablanev + _sorveg;
  _pcs := _pcs + 'WHERE ' + _condition;


  if _kervallum=1 then  //  egy kft-ben keres
      _pcs := _pcs + ' AND (KFT='+chr(39)+_kertkft+chr(39)+')';

  if _kervallum=2 then  // egy körzetben keres
      _pcs := _pcs + ' AND (ERTEKTAR='+inttostr(_kertkorzet)+')';

  if _kervallum=3 then //  csak egy irodában keres;
      _pcs := _pcs + ' AND (PENZTAR='+inttostr(_kertiroda)+')';

  Seekdbase.Connected := true;
  with seekquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  if _recno=0 then
    begin
      Seekquery.close;
      Seekdbase.close;
      exit;
    end;

  Csik.Max := _recno;
  _sptr := 0;
  while not SeekQuery.eof do
    begin
      inc(_sptr);
      Csik.Position := _sptr;
      with SeekQuery do
        begin
          _ugyfelszam := FieldByName('UGYFELSZAM').asInteger;
          _nev      := trim(FieldbyName('NEV').asstring);
          _elozonev := trim(FieldByNAme('ELOZONEV').AsString);
          _anyjaneve:= trim(FieldByName('ANYJANEVE').asString);
          _leanykori:= trim(FieldByName('LEANYKORI').AsString);
          _szulhely := trim(FieldByName('SZULETESIHELY').AsString);
          _szulido  := trim(FieldByName('SZULETESIIDO').AsString);
          _allampolg:= trim(FieldByName('ALLAMPOLGAR').AsString);
          _lakcim   := trim(FieldByName('LAKCIM').AsString);
          _okmtip   := trim(FieldByNAme('OKMANYTIPUS').AsString);
          _azonosito:= trim(FieldByName('AZONOSITO').asString);
          _tarthely := trim(FieldByName('TARTOZKODASIHELY').AsString);
          _lcimcard := trim(FieldByName('LAKCIMKARTYA').AsString);
          _telefon  := trim(FieldByName('TELEFONSZAM').AsString);
          _emailcim := trim(FieldByName('EMAILCIM').asstring);
          _penztar  := FieldByName('PENZTAR').asInteger;
          _aktdatum := FieldByName('DATUM').asString;
          _aktetar  := FieldByName('ERTEKTAR').asInteger;
          _aktceg   := FieldByName('KFT').asstring;
        end;

      _pcs := 'INSERT INTO VALOGATAS (UGYFELSZAM,NEV,ELOZONEV,ANYJANEVE,';
      _pcs := _pcs + 'LEANYKORI,SZULETESIHELY,SZULETESIIDO,ALLAMPOLGAR,';
      _pcs := _pcs + 'LAKCIM,OKMANYTIPUS,AZONOSITO,TARTOZKODASIHELY,';
      _pcs := _pcs + 'LAKCIMKARTYA,TELEFONSZAM,EMAILCIM,DATUM,PENZTAR,';
      _pcs := _pcs + 'ERTEKTAR,KFT)' + _sorveg;

      _pcs := _pcs + 'VALUES (' + inttostr(_ugyfelszam)+',';
      _pcs := _pcs + chr(39) + _nev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _elozonev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _anyjaneve + chr(39) + ',';
      _pcs := _pcs + chr(39) + _leanykori + chr(39) + ',';
      _pcs := _pcs + chr(39) + _szulhely + chr(39) + ',';
      _pcs := _pcs + chr(39) + _szulido + chr(39) + ',';
      _pcs := _pcs + chr(39) + _allampolg + chr(39) + ',';
      _pcs := _pcs + chr(39) + _lakcim + chr(39) + ',';
      _pcs := _pcs + chr(39) + _okmTip + chr(39) + ',';
      _pcs := _pcs + chr(39) + _azonosito + chr(39) + ',';
      _pcs := _pcs + chr(39) + _tarthely + chr(39) + ',';
      _pcs := _pcs + chr(39) + _lcimcard + chr(39) + ',';
      _pcs := _pcs + chr(39) + _telefon + chr(39) + ',';
      _pcs := _pcs + chr(39) + _emailcim + chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktdatum + chr(39) + ',';
      _pcs := _pcs + inttostr(_penztar) + ',';
      _pcs := _pcs + inttostr(_aktetar) + ',';
      _pcs := _pcs + chr(39) + _aktceg + chr(39) + ')';
      Findparancs(_pcs);

      Seekquery.next;
    end;
  Seekquery.close;
  Seekdbase.close;
end;

// =============================================================================
            procedure TForm1.escapegombClick(Sender: TObject);
// =============================================================================

begin
  if _vanExcel then
    begin
      _owb := unassigned;
      _oxl.quit;
      _oxl := unassigned;
    end;
  Application.Terminate;
end;

// =============================================================================
                    procedure Tform1.Tol_Ig_beallito;
// =============================================================================

var _yev: word;

begin
  _aktev := yearof(date);
  _aktho := monthof(date);

  tolevcombo.items.clear;
  igevcombo.Items.clear;

  _yev := _aktev;
  while _yev>=2014 do
    begin
      _evs := inttostr(_yev);
      tolevcombo.Items.add(_evs);
      igevcombo.Items.add(_evs);
      _yev := _yev-1;
    end;

  tolhocombo.Items.Clear;
  ighocombo.Items.clear;

  _y := 1;
  while _y<=12 do
    begin
      tolhocombo.Items.add(_honev[_y]);
      ighocombo.Items.add(_honev[_y]);
      inc(_y);
    end;

  Tolevcombo.ItemIndex := (_aktev-_yev-1);
  Igevcombo.ItemIndex := 0;

  TolhoCombo.ItemIndex := 0;
  Ighocombo.ItemIndex := _aktho-1;

end;



// =============================================================================
            procedure TForm1.TRANZAKCIOKGOMBClick(Sender: TObject);
// =============================================================================

begin
  UgyfeletValasztott;
end;


// =============================================================================
                   function TForm1.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
      procedure TForm1.FINDRACSKeyDown(Sender: TObject; var Key: Word;
                                                         Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  UgyfeletValasztott;
end;




// =============================================================================
             procedure TForm1.UgyfeletValasztott;
// =============================================================================

begin
  _ugyfelnev  := trim(Findquery.FieldByName('NEV').asString);
  _ugyfelszam := FindQuery.FieldByName('UGYFELSZAM').asInteger;
  _ugyPenztar := FindQuery.FieldByName('PENZTAR').asInteger;

  UgyfelnevPanel.Caption := _ugyfelnev;
  UgyfelnevPanel.repaint;
  BizonylatFocimPanel.Caption := _ugyfelnev+ ' BIZONYLATAI A KÉRT INTERVALLUMBAN';
  BizonylatFocimpanel.Repaint;

  Bizkercsik.Position := 0;
  with BizonylatkeresoPanel do
    begin
      Top := 136;
      Left:= 208;
      Visible := True;
      repaint;
    end;
  Tol_ig_beallito;

end;


// =============================================================================
            procedure TForm1.TOLEVCOMBOChange(Sender: TObject);
// =============================================================================

begin
  Activecontrol := BizSeekGomb;
end;


// =============================================================================
           procedure TForm1.noseekbizGombClick(Sender: TObject);
// =============================================================================

begin
  BizonylatKeresoPanel.Visible := False;
end;

// =============================================================================
            procedure TForm1.BIZSEEKGOMBClick(Sender: TObject);
// =============================================================================

var _hodarab,_hoss: word;


begin
  _pcs := 'DELETE FROM BIZONYLATOK';
  FindParancs(_pcs);

  _evindex := tolevcombo.ItemIndex;
  _tolev   := strtoint(Tolevcombo.items[_evindex]);

  _hoindex := tolhoCombo.itemindex;
  _tolho   := 1+ _hoindex;

  _evindex := igevcombo.ItemIndex;
  _igev    := strtoint(IgEvCombo.items[_evindex]);

  _hoindex := ighoCombo.itemindex;
  _igho    := 1+ _hoindex;

  _hodarab := _igho - _tolho + trunc(12*(_igev-_tolev));
  Bizkercsik.Max := _hodarab;

  _tolevhos:= inttostr(_tolev)+nulele(_tolho);
  _igevhos := inttostr(_igev)+nulele(_igho);

  if _tolevhos>_igevhos then
    begin
      ShowMessage('Érvénytelen idõintervallum !');
      exit;
    end;

  _ugyFdbPath := 'C:\receptor\database\V'+ inttostr(_ugyPenztar) + '.FDB';
  if not FileExists(_ugyfdbPath) then
    begin
      ShowMessage('NEM TALÁLOM '+inttostr(_ugypenztar)+' ADATBÁZISÁT');
      EXIT;
    end;

  _xev := _tolev;
  _xho := _tolho;
  _aktevhos:= _TOLEVHOS;
  _hoss := 0;
  while _aktevhos<=_igevhos do
    begin
      _farok := midstr(_aktevhos,3,4);
      _bfTablanev := 'BF' + _farok;
      _btTablaNev := 'BT' + _farok;
      
      inc(_hoss);
      Bizkercsik.Position := _hoss;

      infopanel.Caption := inttostr(_xev)+' - '+_honev[_xho];
      infopanel.repaint;


      bfTabla.close;
      bftabla.tablename := _bfTablanev;

      Bfdbase.close;
      bfdbase.databasename := _ugyFdbPath;
      bfdbase.Connected := True;

      if not bftabla.Exists then
        begin
          inc(_xho);
          if _xho>12 then
            begin
              _xHo := 1;
              inc(_xEv);
            end;
          _aktevhos := inttostr(_xev)+nulele(_xHo);
          Continue;
        end;

      _pcs := 'SELECT * FROM ' + _bftablaNev + _sorveg;
      _pcs := _pcs + 'WHERE (UGYFELSZAM='+inttostr(_ugyfelszam)+') AND (';
      _pcs := _pcs + 'UGYFELTIPUS=' + chr(39) + 'N' + chr(39) + ')';
      with bfQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          First;
          _recno := recno;
        end;

      if _recno>0 then BizonylatBemasolas;

      Bfquery.close;
      Bfdbase.close;


      inc(_xho);
      if _xho>12 then
        begin
          _xHo := 1;
          inc(_xEv);
        end;

      _aktevhos := inttostr(_xev)+nulele(_xHo);
    end;

  BizonylatkeresoPanel.Visible := false;
  FindRacsPanel.Visible := false;
  CsikHuzoPanel.Visible := False;
  KerVallumCsikPanel.Visible := False;
  FeltetelcsikPanel.Visible := False;

  if _FoundBizonylat then Bizonylatdisplay
  else
  begin
    ShowMessage('NEM TALÁLTAM BIZONYLATOT A KÉRT IDÕINTERVALLUMBAN');
    with SeekMenuPanel do
      begin
        Top := 240;
        Left := 390;
        Visible := true;
        Repaint;
      end;
    ActiveControl := NevKezdetGomb;
  end;

end;


// =============================================================================
                    procedure TForm1.BizonylatBemasolas;
// =============================================================================

var _ugyPenztarNev: string;

begin
  Btdbase.close;
  Btdbase.DatabaseName := _ugyfdbPath;
  BtDbase.connected := True;

  _ugyPenztarnev := GetPenztarnev(_ugypenztar);

  while not Bfquery.Eof do
    begin
      _bizonylatszam := BfQuery.FieldByName('BIZONYLATSZAM').asString;
      _datum := BfQuery.FieldByName('DATUM').asString;
      _ido := Bfquery.FieldByName('IDO').asstring;
      _tipus := Bfquery.Fieldbyname('TIPUS').asstring;

      _pcs := 'SELECT * FROM ' + _BTTABLANEV + _sorveg;
      _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_bizonylatszam+chr(39);

      with Btquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          First;
        end;
      while not BtQuery.Eof do
        begin
          _valutanem:= Btquery.FieldByNAme('VALUTANEM').asString;
          _bankjegy := BtQuery.fieldByName('BANKJEGY').asInteger;
          _arfolyam := BtQuery.FieldByName('ARFOLYAM').asInteger;
          _ftertek  := Btquery.FieldbyName('FORINTERTEK').asInteger;

          _pcs := 'INSERT INTO BIZONYLATOK (DATUM,IDO,BIZONYLATSZAM,TIPUS,PENZTARNEV,';
          _pcs := _pcs + 'VALUTANEM,BANKJEGY,ARFOLYAM,FORINTERTEK,PENZTAR)' + _sorveg;
          _pcs := _pcs + 'VALUES (' + chr(39) + _datum + chr(39) + ',';
          _pcs := _pcs +  chr(39) + _ido + chr(39) + ',';
          _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
          _pcs := _pcs + chr(39) + _tipus + chr(39) + ',';
          _pcs := _pcs + chr(39) + _ugypenztarnev + chr(39)+ ',';
          _pcs := _pcs + chr(39) + _valutanem + chr(39) + ',';
          _pcs := _pcs + inttostr(_bankjegy) + ',';
          _pcs := _pcs + inttostr(_arfolyam) + ',';
          _pcs := _pcs + inttostr(_ftertek) + ',';
          _pcs := _pcs + inttostr(_ugypenztar)+')';

          FindParancs(_pcs);
          BtQuery.next;
        end;
      btquery.Close;
      Btdbase.close;

      BfQuery.next;
    end;
  _foundBizonylat := True;
end;

// =============================================================================
                    procedure TForm1.Bizonylatdisplay;
// =============================================================================


begin

  FindracsPanel.Visible := False;
  Bizonylatdbase.Connected := True;

  _pcs := 'SELECT * FROM BIZONYLATOK' + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with BizonylatQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;


  BizonylatSource.enabled := true;

  with BizonylatRacsPanel do
    begin
      Top  := 90;
      Left := 60;
      Visible := true;
    end;
  ActiveControl := BizonylatRacs;



end;




procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  BizonylatracsPanel.Visible := false;
  with SeekMenuPanel do
    begin
      Top := 240;
      Left := 390;
      Visible := true;
      Repaint;
    end;
  ActiveControl := NevKezdetGomb;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);

var _tipusnev: string;

begin
  BizonylatQuery.Last;
  _rekordDb := BizonylatQuery.recno;
  BizonylatQuery.first;


  _oxl := CreateOleObject('Excel.Application');
  _owb := _oxl.workbooks.add[1];

  _oxl.Range['B1:B1'].Columnwidth := 8;
  _oxl.Range['C1:C1'].Columnwidth := 28;
  _oxl.Range['D1:D1'].Columnwidth := 11;
  _oxl.Range['E1:E1'].Columnwidth := 8;
  _oxl.Range['F1:F1'].Columnwidth := 12;
  _oxl.Range['G1:G1'].Columnwidth := 8;
  _oxl.Range['H1:H1'].Columnwidth := 12;
  _oxl.Range['I1:I1'].Columnwidth := 8;
  _oxl.Range['J1:J1'].Columnwidth := 13;
  _oxl.Range['K1:K1'].Columnwidth := 13;

  {
  _oxl.Range['A3:O35'].HorizontalAlignment := -4108;

  _rangestr := 'B5:O35';
  _oxl.range[_RANGESTR].NumberFormat := '### ### ###';
  }

  _rangestr := 'B3:K3';
  _oxl.Range[_rangestr].MergeCells := True;
  _oxl.Range[_rangestr].HorizontalAligNment := -4108;
  _oxl.Range[_rangestr].Font.Size := 12;
  _oxl.Range[_rangestr].Font.Bold := True;
  _oxl.Range[_rangestr].Font.Italic := True;

  _oxl.Cells[3,2] := _ugyfelnev + ' '+inttostr(_tolev)+' '+
       _honev[_tolho]+ ' ÉS '+inttostr(_igev)+' '+_honev[_igho] +' KÖZÖTTI TRANZAKCIÓI';

  _rangestr := 'B5:K5';
  _oxl.Range[_rangestr].HorizontalAligNment := -4108;
  _oxl.Range[_rangestr].Font.Size := 10;
  _oxl.Range[_rangestr].Font.Bold := True;
  _oxl.Range[_rangestr].Font.Italic := True;


  _oxl.Cells[5,2] := 'PT.';
  _oxl.Cells[5,3] := 'PÉNZTÁRNÉV';
  _oxl.Cells[5,4] := 'DÁTUM';
  _oxl.Cells[5,5] := 'IDÕ';
  _oxl.Cells[5,6] := 'BIZONYLAT';
  _oxl.Cells[5,7] := 'TIPUS';
  _oxl.Cells[5,8] := 'BANKJEGY';
  _oxl.Cells[5,9] := 'VNEM';
  _oxl.Cells[5,10]:= 'ÁRFOLYAM';
  _oxl.Cells[5,11]:= 'FORINT';

  _last := inttostr(5+_rekordDb);
  _rangestr := 'B6:K'+_last;
  _oxl.Range[_rangestr].Font.Size := 10;
  _oxl.Range[_rangestr].Font.Bold := False;;
  _oxl.Range[_rangestr].Font.Italic := False;

  _rangestr := 'B6:B'+_last;
  _oxl.Range[_rangestr].HorizontalAligNment := -4108;

  _rangestr := 'D6:G'+_last;
  _oxl.Range[_rangestr].HorizontalAligNment := -4108;

  _rangestr := 'I6:I'+_last;
  _oxl.Range[_rangestr].HorizontalAligNment := -4108;

  _rangestr := 'H6:H'+_last;
  _oxl.Range[_rangestr].NumberFormat := '### ### ###';

  _rangestr := 'J6:K'+_last;
  _oxl.Range[_rangestr].NumberFormat := '### ### ###';

  _prisor := 6;

  while not BizonylatQuery.eof do
    begin
      with BizonylatQuery do
        begin
          _datum := FieldByName('DATUM').asString;
          _ido   := FieldByName('IDO').asstring;
          _bizonylatszam := FieldByname('BIZONYLATSZAM').asstring;
          _tipus := Fieldbyname('TIPUS').asstring;
          _valutanem:= FieldByNAme('VALUTANEM').asString;
          _bankjegy := fieldByName('BANKJEGY').asInteger;
          _arfolyam := FieldByName('ARFOLYAM').asInteger;
          _forint  := FieldbyName('FORINTERTEK').asInteger;
          _penztar := FieldByName('PENZTAR').asInteger;
          _ptnev := trim(Fieldbyname('PENZTARNEV').asstring);
        end;

      if _tipus='V' then _tipusnev := 'Vétel';
      if _tipus='E' then _tipusnev := 'Eladás';
      if _tipus='K' then _tipusnev := 'Konverzió';

      _oxl.Cells[_prisor,2] := _penztar;
      _oxl.Cells[_prisor,3] := _ptnev;
      _oxl.Cells[_prisor,4] := _datum;
      _oxl.Cells[_prisor,5] := _ido;
      _oxl.Cells[_prisor,6] := _bizonylatszam;
      _oxl.Cells[_prisor,7] := _tipusnev;
      _oxl.Cells[_prisor,8] := _bankjegy;
      _oxl.Cells[_prisor,9] := _valutanem;
      _oxl.Cells[_prisor,10]:= _arfolyam;
      _oxl.Cells[_prisor,11]:= _forint;
      inc(_prisor);
      BizonylatQuery.next;
    end;
  BizonylatQuery.First;

  _vanexcel := true;

  _oxl.visible := true;
end;










end.
