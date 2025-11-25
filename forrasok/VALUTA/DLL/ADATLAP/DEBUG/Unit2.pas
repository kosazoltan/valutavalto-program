unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Grids, ExtCtrls, DB, DBGrids, StrUtils,
  DBTables, IBDatabase, IBCustomDataSet, IBTable, IBQuery,dateutils;

type
  TAdatlapForm = class(TForm)                              
    VISSZAGOMB: TBitBtn;
    ADATLAPSOURCE: TDataSource;
    ADATLAPDBASE: TIBDatabase;
    ADATLAPTRANZ: TIBTransaction;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    GONGYCSOMAGTABLA: TIBTable;
    GONGYCSOMAGDBASE: TIBDatabase;
    GONGYCSOMAGTRANZ: TIBTransaction;
    GongySOURCE: TDataSource;
    GongyCsomagTablaUgyfelTipus: TIBStringField;
    GongyCsomagTablaUgyfelSzam: TIntegerField;
    GongyCsomagTablaUgyfelNev: TIBStringField;
    GongyCsomagTablaDatum: TIBStringField;
    GongyCsomagTablaValutanem: TIBStringField;
    GongyCsomagTablaBankjegy: TIntegerField;
    GongyCsomagTablaForintErtek: TIntegerField;
    GongyCsomagTablaGongyCsomagSzam: TIntegerField;
    GongyCsomagTablaBizonylatSzam: TIBStringField;
    FEJDBASE: TIBDatabase;
    FEJTRANZ: TIBTransaction;
    VALUTAQUERY: TIBQuery;
    ADATLAPQUERY: TIBQuery;
    ADATLAPQUERYUGYFELSZAM: TIntegerField;
    ADATLAPQUERYGONGYCSOMAGSZAM: TIntegerField;
    ADATLAPQUERYSORSZAM: TIntegerField;
    ADATLAPQUERYDATUM: TIBStringField;
    ADATLAPQUERYIDO: TIBStringField;
    ADATLAPQUERYPENZTARKOD: TIBStringField;
    ADATLAPQUERYPENZTAROSNEV: TIBStringField;
    ADATLAPQUERYUGYFELTIPUS: TIBStringField;
    ADATLAPQUERYKORULMENY: TIBStringField;
    ADATLAPQUERYEGYEB: TIBStringField;
    ADATLAPQUERYOSSZESFORINT: TIntegerField;
    ADATLAPQUERYSTORNO: TSmallintField;
    ADATLAPQUERYUGYFELNEV: TIBStringField;
    MODQUERY: TIBQuery;
    MODDBASE: TIBDatabase;
    modtranz: TIBTransaction;
    Panel3: TPanel;
    Shape1: TShape;
    Panel7: TPanel;
    NEVEDIT: TEdit;
    ELOZOEDIT: TEdit;
    LANYEDIT: TEdit;
    ANYJAEDIT: TEdit;
    CIMEDIT: TEdit;
    CIMCARDEDIT: TEdit;
    SZULHELYEDIT: TEdit;
    SZULIDOEDIT: TEdit;
    OKMTIPEDIT: TEdit;
    AZONOSITOEDIT: TEdit;
    ALLAMPOLGEDIT: TEdit;
    TARTHELYEDIT: TEdit;
    Shape2: TShape;
    Panel8: TPanel;
    ELOZOGOMB: TBitBtn;
    MODRENDBENGOMB: TBitBtn;
    KOVETKEZOGOMB: TBitBtn;
    Shape3: TShape;
    Label31: TLabel;
    Label40: TLabel;
    Label41: TLabel;
    Label42: TLabel;
    Label43: TLabel;
    Label44: TLabel;
    Label45: TLabel;
    Label46: TLabel;
    Label47: TLabel;
    Label48: TLabel;
    Label49: TLabel;
    Label50: TLabel;
    JOGIPANEL: TPanel;
    JNEVEDIT: TEdit;
    JHELYEDIT: TEdit;
    JOKIRSZAMEDIT: TEdit;
    JTEVEKENYEDIT: TEdit;
    JKEPVISEDIT: TEdit;
    JBEOSZTASEDIT: TEdit;
    Label51: TLabel;
    UGYFSTORNOLABEL: TLabel;
    JOGISTORNOLABEL: TLabel;
    Label54: TLabel;
    Label55: TLabel;
    Label56: TLabel;
    Label57: TLabel;
    Label58: TLabel;
    Label59: TLabel;
    Panel9: TPanel;
    PENZTARPANEL: TPanel;
    Shape4: TShape;
    Label12: TLabel;
    Panel14: TPanel;
    Panel15: TPanel;
    Shape5: TShape;
    Shape6: TShape;
    SORSZAMPANEL: TPanel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    CEGNEVLABEL: TLabel;
    CEGCIMLABEL: TLabel;
    FELELOSLABEL: TLabel;
    Panel17: TPanel;
    Shape7: TShape;
    Panel18: TPanel;
    Shape8: TShape;
    PROSPANEL: TPanel;
    Label20: TLabel;
    Panel20: TPanel;
    Shape9: TShape;
    Shape10: TShape;
    Panel21: TPanel;
    TRANZRACS: TDBGrid;
    Shape11: TShape;
    Shape12: TShape;
    Label21: TLabel;
    GONGYERTEKPANEL: TPanel;
    Shape13: TShape;
    BEJELENT3GOMB: TBitBtn;
    NYOMTATOGOMB: TBitBtn;
    STORNOGOMB: TBitBtn;
    Shape14: TShape;
    INDEXNEVLISTA: TListBox;
    NYOMTATOPANEL: TPanel;
    AZONOSITONYOMTATOGOMB: TBitBtn;
    BEJELENTESNYOMTATOGOMB: TBitBtn;
    NYOMTATASVEGEGOMB: TBitBtn;
    Label4: TLabel;
    Shape15: TShape;
    alappanel: TPanel;
    Panel2: TPanel;
    Shape17: TShape;
    Label5: TLabel;
    ADATLAPRACS: TDBGrid;
    BitBtn2: TBitBtn;
    MINORTRANSGOMB: TBitBtn;
    MAJORTRANSGOMB: TBitBtn;
    CANCELGOMB: TBitBtn;
    TIPUSPANEL: TPanel;
    GONGYCSOMAGQUERY: TIBQuery;
    RADATLAP: TRadioButton;
    RFELEV: TRadioButton;
    FEJQUERY: TIBQuery;
    Label1: TLabel;
    Label6: TLabel;

    procedure FormActivate(Sender: TObject);

    procedure KartonDisplay;
    procedure UgyfelDataRead(_usz: integer);
    function Kozepreir(_mit: string): string;
    procedure JogiDataRead(_usz: integer);
    procedure GongyErtekDisp;
    procedure VonalHuzo;
    procedure cancelgombClick(Sender: TObject);
    procedure ADATLAPRACSKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure AdatlapBeolvaso;
    procedure UrlapFeltolto;
    procedure BitBtn1Enter(Sender: TObject);
    procedure BitBtn1Exit(Sender: TObject);
    procedure korvisszagombClick(Sender: TObject);
  
    procedure Valutaparancs(_ukaz: string);


    procedure MINORTRANSGOMBClick(Sender: TObject);
    procedure MAJORTRANSGOMBClick(Sender: TObject);
    procedure ELOZOGOMBClick(Sender: TObject);
    procedure KOVETKEZOGOMBClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ADATLAPRACSDblClick(Sender: TObject);
     procedure MODRENDBENGOMBClick(Sender: TObject);

    procedure GetnaturAdatok;
    procedure GetJogiadatok;

    function MegbizoKereso(_gysz: integer): integer;

    function Ninelen(_num: integer):string;
    procedure LapformClear;
    procedure JogiDisp;
    procedure TextKiiro;

    procedure Pirosito(_hova: TEdit;_text: string);
    procedure adatmodositogombClick(Sender: TObject);
    procedure CIMEDITEnter(Sender: TObject);
    procedure CIMEDITExit(Sender: TObject);
    procedure MainJob;
    procedure CIMEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);

    procedure BitBtn2Click(Sender: TObject);
    procedure Bejelentesnyomtatas;
    procedure WriteNaturAdatok;
    procedure WriteJogiadatok;
    procedure StartNyomtatas;
    procedure nyomtatogombClick(Sender: TObject);
    procedure AZONOSITONYOMTATOGOMBClick(Sender: TObject);
    procedure BEJELENTESNYOMTATOGOMBClick(Sender: TObject);
    procedure NYOMTATASVEGEGOMBClick(Sender: TObject);

    procedure STORNOGOMBClick(Sender: TObject);
    procedure MBSZEMELYGOMBClick(Sender: TObject);

    procedure Naturdisp;
    procedure TranzakcioDisplay;
    procedure RFELEVClick(Sender: TObject);
    function Forintform(_ft: integer): string;

 
    function HunDateTostr(_caldat: TdateTime): string;
    function Nulele(_b: byte): string;

    procedure NEVEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
      
    procedure VISSZAGOMBClick(Sender: TObject);
  
    procedure BEJELENT3GOMBClick(Sender: TObject);



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ADATLAPFORM: TADATLAPFORM;
  _bjtxt,_fttxt,_osszegtxt,_status: string;
  _leiras,_tranznev,_tipusPanelCim: string;
  _osszeg,_sorszam,_megbizott,_aktugyfelszam,_aktsorszam: integer;
  _egyebValtozott: boolean;

  _Fdb,_GERTEK,_vanMegbizo,_aktcsomagszam: integer;
  _gSzuro,_uSzuro: string;
  _mbUgyfelNev,_mBelozonev,_mbLeanyNev,_mbAnyjaNeve: string;
  _mblakcim,_mbLcimCard,_mbSzulhely,_mbSzulido: string;
  _mbOkmanyTipus,_mbAzonosito,_mbTarthely: string;
  _mbAllampolgar,_penztarnev,_penztarkod: string;
  _vanUgyfel: boolean;


  _vnem,_vfts,_vbjs: array[1..9] of string;
  _VEDIT: array[1..6] of tedit;
  _vRegi,_vuj : array[1..6] of string;
  _jregi,_juj : array[1..6] of string;
  _vmezo: array[1..6] of string;
  _JEDIT: array[1..6] of tedit;
  _jmezo: array[1..6] of string;

   _regiUgyfel,_megvan,_szabad,_valtozas: boolean;
  _pcs,_aktdnem,_ugyfeltipus,_szuro,_elozonev,_okmanytipus,_kftnev: string;
  _sorveg: string=#13#10;
  _ugyfelnev,_anyjaneve,_mamas,_datums,_farok,_tablanev: string;
  _aktertek,_ugyfelszam,_ertek,_tag,_spk,_penztarszam,_code: integer;
  _penztarosnev,_korulmeny,_egyeb,_penztar,_bnum: string;
  _gongycsomagszam,_stornojel,_recno,_bankjegy: integer;
  _leanynev,_lakcim,_lcimcard,_szulhely,_szulido,_azonosito: string;
  _tarthely,_allampolgar,_joginev,_jogihely,_okiratszam: string;
  _tevekenyseg,_kepvisnev,_beosztas: string;
  _LFile: textfile;
  _munkadir,_FTABLANEV,_TTABLANEV: string;
  _widOn,_widoff,_inic,_cegnev,_cegcim,_felelos: string;
  _PENZTARCIM,_bizonylatszam: string;
  _TOP,_LEFT,_bugyfel,_UTLAPSZAM: INTEGER;
  _height,_width: integer;


function adatlaprutin: integer; stdcall;

implementation



{$R *.dfm}


function adatlaprutin: integer; stdcall;

begin
  Adatlapform := TAdatlapform.Create(Nil);
  result := Adatlapform.ShowModal;
  Adatlapform.Free;
end;


// =============================================================================
               procedure TAdatlapForm.FormActivate(Sender: TObject);
// =============================================================================


begin


   _top := 0;
   _left := 0;
   _height := Screen.Monitors[0].Height;
   _width  := Screen.Monitors[0].width;
   if _height>768 then _top := trunc((_height-768)/2);
   if _width>1024 then _left := trunc((_width-1024)/2);

   Top := _top;
   Left := _left;
   Width := 1024;
   Height := 768;

  _mamas := Hundatetostr(date);

  _vEdit[1] := CIMEDIT;
  _vEdit[2] := CIMCARDEDIT;
  _vEdit[3] := OKMTIPEDIT;
  _vEdit[4] := AZONOSITOEDIT;
  _vEdit[5] := ALLAMPOLGEDIT;
  _vEdit[6] := TARTHELYEDIT;

  _jEdit[1] := JNEVEDIT;
  _jEdit[2] := JHELYEDIT;
  _jEdit[3] := JOKIRSZAMEDIT;
  _jEdit[4] := JTEVEKENYEDIT;
  _jEdit[5] := JKEPVISEDIT;
  _jEdit[6] := JBEOSZTASEDIT;

  _vmezo[1] := 'LAKCIM';
  _vmezo[2] := 'LCIMCARD';
  _vmezo[3] := 'OKMANYTIP';
  _vmezo[4] := 'AZONOSITO';
  _vmezo[5] := 'ALLAMPOLG';
  _vmezo[6] := 'TARTHELY';

  _jmezo[1] := 'JOGINEV';
  _jmezo[2] := 'JOGIHELY';
  _jmezo[3] := 'OKIRSZAM';
  _jmezo[4] := 'TEVEKENY';
  _jmezo[5] := 'KEPVISNEV';
  _jmezo[6] := 'BEOSZTAS';

  _tipusPanelCim := '(AZ ÖSSZES TRANZAKCIÓ)';

  MainJob;
end;

// =============================================================================
                         procedure TadatlapForm.MainJob;
// =============================================================================

begin
  NyomtatoPanel.Visible  := False;
  JogiPanel.Visible      := False;

  // -------------------------------------------

  ValutaDbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.Add('SELECT * FROM PENZTAR');
      Open;
      _penztarnev := trim(FieldByName('PENZTARNEV').asstring);
      _penztarkod := trim(Fieldbyname('PENZTARKOD').AsString);
      _penztarcim := trim(FieldByName('PENZTARCIM').AsString);
      Close;
      sql.clear;
      sql.Add('SELECT * FROM HARDWARE');
      oPEN;
      _KFTNEV := trim(FieldByNAme('KFTNEV').AsString);
      close;
    end;
  Valutadbase.close;

  val(_penztarkod,_penztarszam,_code);
  if _penztarszam<151 then
    begin
      _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';
      _cegcim := 'PÉCS, CITROM U. 2-6';
      _felelos:= 'KARDOS ILDIKÓ, PÉCS CITROM U. 2-6 (Tel: 70-457-75-63';

    end else
    begin
      _cegnev := 'EXPRESSZ EKSZERHAZ ES MINIBANK KFT';
      _cegcim := '';
      _felelos := '';
    end;

  PenztarPanel.caption := trim(_penztarnev);
  PenztarPanel.repaint;

  CegnevLabel.Caption := _cegnev;
  CegcimLabel.Caption := _cegcim;
  FelelosLabel.Caption:= _felelos;
  AdatlapForm.Repaint;

  // -------------------------------------------

  AdatlapDbase.Close;
  AdatlapDbase.Connected := true;
  if adatlapTranz.InTransaction then AdatlapTranz.Commit;

  _pcs := 'SELECT * FROM ADATLAP'+_sorveg;
  if _szuro<>'' then  _pcs := _pcs + 'WHERE '+ _szuro + _sorveg;
  _pcs := _pcs + 'ORDER BY SORSZAM DESC';

  with AdatLapQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  TipusPanel.Caption := _tipusPanelCim;
  with Alappanel do
    begin
      top := 0;
      Left := 0;
      Visible := true;
    end;
  ActiveControl := AdatLApRacs;
end;


// =============================================================================
           procedure TADATLAPFORM.ADATLAPRACSDblClick(Sender: TObject);
// =============================================================================

begin
   AlapPanel.Visible :=False;
   Kartondisplay;
end;

// =============================================================================
     procedure TADATLAPFORM.ADATLAPRACSKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  AlapPanel.Visible :=False;
  Kartondisplay;
end;


// =============================================================================
                    procedure TadatlapForm.KartonDisplay;
// =============================================================================

begin
  AdatLapbeolvaso;
  UrlapFeltolto;
  NyomtatoGomb.Enabled := True;
end;


// =============================================================================
                   procedure TadatLapForm.AdatlapBeolvaso;
// =============================================================================

begin
  with AdatlapQuery do
    begin
      _sorszam         := FieldByName('SORSZAM').asInteger;
      _penztarkod      := FieldByName('PENZTARKOD').asString;
      _penztarosnev    := trim(FieldByName('PENZTAROSNEV').asstring);
      _ugyfelnev       := trim(FieldByName('UGYFELNEV').AsString);
      _ugyfelszam      := FieldbyName('UGYFELSZAM').asInteger;
      _ugyfeltipus     := FieldByName('UGYFELTIPUS').AsString;
      _korulmeny       := FieldByName('KORULMENY').asstring;
      _egyeb           := FieldByNAme('EGYEB').asstring;
      _datums          := FieldByNAme('DATUM').AsString;
      _osszeg          := FieldByName('OSSZESFORINT').asInteger;
      _gongycsomagszam := FieldByName('GONGYCSOMAGSZAM').asinteger;
      _stornojel       := FieldByName('STORNO').asInteger;
    end;
  _AKTSORSZAM  := _sorszam;

  _elozoNev    := '';
  _leanyNev    := '';
  _anyjaNeve   := '';
  _lakcim      := '';
  _lcimCard    := '';
  _szulhely    := '';
  _szulido     := '';
  _okmanyTipus := '';
  _azonosito   := '';
  _tarthely    := '';
  _allampolgar := '';

  _vanMegbizo := 0;
  IF _gongycsomagszam>0 then _vanmegbizo := Megbizokereso(_gongycsomagszam);

  if _ugyfelTipus='J' then
    begin
      _joginev     := _ugyfelnev;
      _jogihely    := '';
      _okiratszam  := '';
      _tevekenyseg := '';
      _kepvisnev   := '';
      _megbizott   := 0;
      JogiDataRead(_ugyfelszam);
    end else  UgyfelDaTaRead(_ugyfelszam);
end;


// =============================================================================
              procedure TAdatlapForm.UgyfelDataRead(_usz: integer);
// =============================================================================

begin
  _aktugyfelszam := _usz;

  ValutaDbase.close;
  ValutaDbase.connected := true;
  if ValutaTranz.Intransaction then ValutaTranz.Commit;

  _pcs := 'SELECT * FROM UGYFEL'+_sorveg;
  _pcs := _pcs + 'WHERE UGYFELSZAM='+inttostr(_usz);

  with ValutaQuery do
    begin
      close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
    end;

  if ValutaQuery.recno=0 then
    begin
      ValutaQuery.Close;
      Exit;
    end;


  with ValutaQuery do
    begin
      _ugyfelnev   := trim(FieldByname('NEV').asString);
      _elozoNev    := trim(FieldByName('ELOZONEV').asstring);
      _leanyNev    := trim(FieldByName('LEANYKORI').asstring);
      _anyjaNeve   := trim(FieldByname('ANYJANEVE').asString);
      _lakcim      := trim(FieldByName('LAKCIM').asString);
      _lcimCard    := FieldByName('LAKCIMKARTYA').asstring;
      _szulhely    := trim(FieldByName('SZULETESIHELY').asString);
      _szulido     := FieldByName('SZULETESIIDO').asString;
      _okmanyTipus := FieldByName('OKMANYTIPUS').asString;
      _azonosito   := FieldByName('AZONOSITO').asstring;
      _tarthely    := trim(FieldByName('TARTOZKODASIHELY').asString);
      _allampolgar := trim(FieldByName('ALLAMPOLGAR').asstring);
    end;
  ValutaQuery.Close;
end;

procedure Tadatlapform.WriteNaturAdatok;

begin
  _pcs := 'UPDATE UGYFEL SET NEV='+chr(39) + _ugyfelnev + chr(39) + ',';
  _pcs := _pcs + 'ELOZONEV='+chr(39)+_elozonev+chr(39)+',';
  _pcs := _pcs + 'LEANYKORI='+chr(39)+_leanynev+chr(39)+',';
  _PCS := _pcs + 'ANYJANEVE='+chr(39)+_anyjaneve+chr(39)+',';
  _pcs := _pcs + 'LAKCIM='+chr(39)+_lakcim+chr(39)+',';
  _pcs := _pcs + 'LAKCIMKARTYA='+chr(39)+_lcimcard+chr(39)+',';
  _pcs := _pcs + 'SZULETESIHELY='+chr(39)+_szulhely+chr(39)+',';
  _pcs := _pcs + 'SZULETESIIDO='+chr(39)+_szulido+chr(39)+',';
  _pcs := _pcs + 'OKMANYTIPUS='+chr(39)+_okmanytipus+chr(39)+',';
  _pcs := _pcs + 'AZONOSITO='+chr(39)+_azonosito+chr(39)+',';
  _pcs := _pcs + 'TARTOZKODASIHELY='+chr(39)+_tarthely+chr(39)+',';
  _pcs := _pcs + 'ALLAMPOLGAR='+chr(39)+_allampolgar+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE UGYFELSZAM='+inttostr(_aktugyfelszam);

  ValutaParancs(_pcs);
end;




// =============================================================================
                procedure TAdatlapForm.JogiDataRead(_usz:integer);
// ========================================================= ===================

begin
  _aktugyfelszam := _usz;

  ValutaDbase.close;
  ValutaDbase.connected := true;
  if ValutaTranz.Intransaction then ValutaTranz.Commit;

  _pcs := 'SELECT * FROM JOGISZEMELY'+_sorveg;
  _pcs := _pcs + 'WHERE UGYFELSZAM='+inttostr(_usz);

  with ValutaQuery do
    begin
      close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
    end;

  if ValutaQuery.recno=0 then
    begin
      ValutaQuery.Close;
      Exit;
    end;

  with ValutaQuery do
    begin
      _joginev     := FieldByName('JOGISZEMELYNEV').asString;
      _jogihely    := FieldByName('TELEPHELYCIM').asstring;
      _okiratszam  := FieldByName('OKIRATSZAM').asString;
      _tevekenyseg := FieldByName('FOTEVEKENYSEG').asstring;
      _beosztas    := FieldByName('KEPVISBEO').AsString;
      _kepvisnev   := FieldByName('KEPVISELONEV').asstring;
      _megbizott   := FieldByName('MEGBIZOTTSZAMA').asInteger;
    end;
  ValutaQuery.Close;

  if _megbizott>0 then UgyfelDataRead(_MEGBIZOTT);

end;


procedure TadatlapForm.writeJogiadatok;

begin
  _pcs := 'UPDATE JOGISZEMELY SET JOGISZEMELYNEV='+chr(39)+_joginev+chr(39)+',';
  _pcs := _pcs + 'TELEPHELYCIM='+chr(39)+_jogihely+chr(39)+',';
  _pcs := _pcs + 'OKIRATSZAM='+chr(39)+_okiratszam+chr(39)+',';
  _pcs := _pcs + 'FOTEVEKENYSEG='+chr(39)+_tevekenyseg+chr(39)+',';
  _pcs := _pcs + 'KEPVISBEO='+chr(39)+_beosztas+chr(39)+',';
  _pcs := _pcs + 'KEPVISELONEV='+chr(39)+_kepvisnev+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE UGYFELSZAM='+inttostr(_aktugyfelszam);

  ValutaParancs(_pcs);
end;


// =============================================================================
                     procedure TAdatlapForm.Urlapfeltolto;
// =============================================================================


begin
  LapformClear;
  if _ugyfeltipus <>'J' then Jogipanel.Hide else jogipanel.Show;

  SorszamPanel.Caption := inttostr(_sorszam);
  PenztarPanel.Caption := _penztarnev;
  ProsPanel.Caption    := _penztarosNev;
  _allampolgar := uppercase(_allampolgar);

  if _ugyfelTipus<>'J' then Naturdisp else Jogidisp;
  TranzakcioDisplay;
  ModrendbenGomb.Enabled := False;
end;

// =============================================================================
          procedure TAdatlapForm.MODRENDBENGOMBClick(Sender: TObject);
// =============================================================================

begin
  if _ugyfeltipus<>'J' then
    begin
      GetNaturadatok;
      WriteNaturAdatok;
      NaturDisp;
    end else
    Begin
      GetJogiadatok;
      WriteJogiadatok;
      Jogidisp;
    end;
  ModRendbenGomb.Enabled := False;
end;

// =============================================================================
                      procedure TadatlapForm.NaturDisp;
// =============================================================================


begin
  Pirosito(Nevedit,_ugyfelNev);
  Pirosito(Elozoedit,_elozonev);
  Pirosito(Lanyedit,_leanyNev);
  Pirosito(AnyjaEdit,_anyjaNeve);
  Pirosito(Cimedit,_lakcim);
  Pirosito(CimCardEdit,_lcimCard);
  Pirosito(SzulhelyEdit,_szulhely);
  Pirosito(SzulidoEdit,_szulido);
  Pirosito(OkmtipEdit,_okmanyTipus);
  Pirosito(AzonositoEdit,_azonosito);
  Pirosito(TarthelyEdit,_tarthely);
  Pirosito(AllampolgEdit,_allampolgar);
  if _stornojel>1 then
    begin
      UgyfStornoLabel.Visible := True;
      Stornogomb.Enabled := False;
    end else
    begin
      UgyfstornoLabel.visible := false;
      StornoGomb.Enabled := True;
    end;
end;


procedure TadatlapForm.Getnaturadatok;
begin
   _ugyfelnev := trim(Nevedit.text);
   _elozonev := trim(Elozoedit.text);
   _leanynev := trim(LanyEdit.text);
   _anyjaneve := trim(Anyjaedit.text);
   _lakcim := trim(Cimedit.text);
   _lcimcard := trim(CimCardEdit.text);
   _szulhely := trim(Szulhelyedit.text);
   _szulido := trim(SzulidoEdit.text);
   _okmanytipus := trim(OkmTipEdit.text);
   _azonosito := trim(Azonositoedit.text);
   _tarthely := trim(Tarthelyedit.text);
   _allampolgar := trim(AllampolgEdit.text);
end;





// ===================================================
          procedure TadatlapForm.JogiDisp;
// ==================================================


begin
  Pirosito(Jnevedit,_joginev);
  Pirosito(Jhelyedit,_jogihely);
  Pirosito(jokirszamEdit,_okiratszam);
  Pirosito(jtevekenyedit,_tevekenyseg);
  Pirosito(jkepvisedit,_kepvisnev);
  Pirosito(jbeosztasedit,_beosztas);
  if _stornojel>1 then
    begin
      JogistornoLabel.visible := true;
      StornoGomb.enabled := false;
    end else
    begin
      JogistornoLabel.visible := False;
      StornoGomb.enabled := True;
    end;
end;

procedure TAdatlapform.GetJogiadatok;

begin
    _joginev := trim(Jnevedit.text);
    _jogihely := trim(jhelyedit.text);
    _okiratszam := trim(jokirszamEdit.text);
    _tevekenyseg := trim(Jtevekenyedit.text);
    _kepvisnev := trim(JKepvisedit.text);
    _beosztas := trim(jBeosztasedit.text);
end;




// =============================================================================
                       procedure TadatlapForm.LapformClear;
// =============================================================================


begin
  Nevedit.clear;
  Elozoedit.clear;
  Lanyedit.clear;
  Anyjaedit.clear;
  Cimedit.clear;
  CimCardedit.clear;
  Szulhelyedit.clear;
  Szulidoedit.clear;
  OkmTipedit.clear;
  Azonositoedit.clear;
  TarthelyEdit.clear;
  Allampolgedit.clear;
  Jnevedit.clear;
  JHelyedit.clear;
  JOkirszamedit.clear;
  JTevekenyedit.clear;
  JKepvisedit.clear;
  JBeosztasedit.clear;

end;

// =============================================================================
                procedure TadatlapForm.Tranzakciodisplay;
// =============================================================================

var _tavaly: TDateTime;
    _tavalys: string;
    _sumforint: integer;

begin
  _tavaly := date-180;
  _tavalys := Hundatetostr(_tavaly);

  GongyCsomagDbase.connected := True;
  _pcs := 'SELECT * FROM GONGYCSOMAG' + _sorveg;
  if Rfelev.checked then
    begin
      _pcs := _pcs + 'WHERE (UGYFELSZAM='+inttostr(_ugyfelszam)+') AND (';
      _pcs := _pcs + 'DATUM>=' + chr(39) + _tavalys + chr(39) + ')';
    end else
    begin
      _pcs := _pcs + 'WHERE GONGYCSOMAGSZAM='+inttostr(_gongycsomagszam);
    end;

  GongySource.Enabled := False;
  with GongyCsomagQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  _sumForint := 0;
  while not GongycsomagQuery.eof do
    begin
      _sumForint := _sumforint + GongyCsomagQuery.FieldByNAme('FORINTERTEK').asInteger;
      GongyCsomagQuery.Next;
    end;
  GongyErtekPanel.caption := ForintForm(_sumForint)+ ' Ft';
  GongyCsomagQuery.First;
  GongySource.enabled := True;
  Activecontrol := TranzRacs;
end;


// =============================================================================
                 function TadatlapForm.Forintform(_ft: integer): string;
// =============================================================================


var _p1: integer;

begin
  result := inttostr(_ft);
  if _ft<1000 then exit;
  if _ft>=1000000 then
    begin
      _p1 := length(result)-6;
      result := leftstr(result,_p1)+','+midstr(result,_p1+1,3)+','+midstr(result,_p1+4,3);
      exit;
    end;

  _p1 := length(result)-3;
  result := leftstr(result,_p1)+','+midstr(result,_p1+1,3);
end;

// =============================================================================
         procedure TADATLAPFORM.MINORTRANSGOMBClick(Sender: TObject);
// =============================================================================

begin
  adatLapQuery.Close;
  AdatLapSource.Enabled := False;

  _szuro := 'OSSZESFORINT<300000';
  _tipusPanelCim := '(300 000 FT ALATTI TRANZAKCIÓK)';

  AdatLapSource.Enabled := False;

  AdatlapDbase.Close;
  AdatlapDbase.Connected := True;
//  if AdatLapTranz.InTransaction then AdatlapTranz.Commit;

  _pcs := 'SELECT * FROM ADATLAP' + _sorveg;
  if _szuro<>'' then  _pcs := _pcs + 'WHERE '+ _szuro + _sorveg;
  _pcs := _pcs + 'ORDER BY SORSZAM DESC';

  with AdatlapQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  AdatLapSource.Enabled := True;
  TipusPanel.Caption := _tipusPanelCim;
end;

// =============================================================================
       procedure TADATLAPFORM.MAJORTRANSGOMBClick(Sender: TObject);
// =============================================================================

begin
   AdatlapQuery.close;
   AdatlapSource.Enabled := False;
   _szuro := 'OSSZESFORINT>=300000';
   _tipusPanelCim := '(300 000 FT FELETTI TRANZAKCIÓK)';

   AdatlapDbase.Close;
   AdatlapDbase.Connected := true;
   if AdatLapTranz.InTransaction then AdatlapTranz.Commit;

  _pcs := 'SELECT * FROM ADATLAP' + _sorveg;
  _pcs := _pcs + 'WHERE ' + _SZURO + _sorveg;
  _pcs := _pcs + 'ORDER BY SORSZAM DESC';

  with AdatlapQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  AdatLapSource.Enabled := True;
  TipusPanel.Caption := _tipusPanelCim;
end;

// =============================================================================
               procedure TADATLAPFORM.ELOZOGOMBClick(Sender: TObject);
// =============================================================================

begin
  GongyCsomagTabla.Close;
  JogiPanel.Left := 20;

  AdatlapQuery.Prior;
  if AdatlapQuery.Bof then
    begin
      Elozogomb.Enabled := False;
      Exit;
    end;
  KovetkezoGomb.Enabled := True;
  AdatlapBeolvaso;
  UrlapFeltolto;

end;

// =============================================================================
            procedure TADATLAPFORM.KOVETKEZOGOMBClick(Sender: TObject);
// =============================================================================

begin
  GongyCsomagTabla.Close;
  JogiPanel.Left := 20;

  AdatlapQuery.Next;
  if AdatlapQuery.Eof then
    begin
      KovetkezoGomb.Enabled := False;
      Exit;
    end;
  Elozogomb.Enabled := True;
  AdatlapBeolvaso;
  UrlapFeltolto;
end;


// =============================================================================
         function TadatLapForm.MegbizoKereso(_gysz: integer): integer;
// =============================================================================


var _gdatum,_gbizonylat,_dbasenev,_tablanev,_uftipus: string;
    _bizott,_bizo,_mbszam: integer;

begin
  result := 0;

  GongyCsomagDbase.Connected := True;
  _pcs := 'SELECT * FROM GONGYCSOMAG'+ _sorveg;
  _pcs := _pcs + 'WHERE GONGYCSOMAGSZAM='+inttostr(_gysz);
  with GongycsomagQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _recno := Recno;
    end;
  if _recno=0 then
    begin
      GongycsomagQuery.close;
      GongycsomagDbase.close;
      Exit;
    end;

  _gDatum     := GongycsomagQuery.FieldByName('DATUM').asstring;
  _gbizonylat := GongyCsomagQuery.FieldByname('BIZONYLATSZAM').asstring;

  GongyCsomagQuery.close;
  GongyCsomagDbase.close;

  _farok := midstr(_gdatum,3,2)+midstr(_gdatum,6,2);

  if _gdatum=_mamas then
    begin
      _dbaseNev := 'C:\VALUTA\DATABASE\VALUTA.FDB';
      _tablanev := 'BLOKKFEJ';
    end else
    begin
      _dBaseNev := 'C:\VALUTA\DATABASE\VALDATA.FDB';
      _tablaNev := 'BF'+_farok;
    end;

  Fejdbase.close;
  Fejdbase.DatabaseName := _dbaseNev;
  Fejdbase.Connected := True;
  _pcs := 'SELECT * FROM ' + _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM=' +  chr(39)+ _gBizonylat + chr(39);

  with FejQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _recno := recno;
    end;
  if _recno=0 then
    begin
      FejQuery.close;
      FejDbase.close;
      exit;
    end;

  _bizott := 0;
  _bizo   := 0;
  _uftipus := FejQuery.FieldByName('UGYFELTIPUS').asstring;

  if _uftipus='J' then
      _bizott := FejQuery.FieldByName('MEGBIZOTT').asInteger
  else _bizo  := FejQuery.FieldByName('MEGBIZOSZAM').asInteger;

  FejQuery.close;
  FejDbase.close;

  if (_bizott+_bizo)=0 then exit;

  if _bizott>0 then
    begin
      _mbszam := _bizott;
      Result  := 1;
    end else
    begin
      _mbSzam := _bizo;
      result  := 2;
    end;

  UgyfelDataRead(_mbSzam);

  _Mbugyfelnev   := _ugyfelnev;
  _MbelozoNev    := _elozonev;
  _mbleanyNev    := _leanynev;
  _mbanyjaNeve   := _anyjaNeve;
  _mblakcim      := _lakcim;
  _mblcimCard    := _lcimCard;
  _mbszulhely    := _szulhely;
  _mbszulido     := _szulido;
  _mbokmanyTipus := _okmanyTipus;
  _mbazonosito   := _azonosito;
  _mbtarthely    := _tarthely;
  _mballampolgar := _allampolgar;

end;

// =============================================================================
             procedure TADATLAPFORM.STORNOGOMBClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'UPDATE ADATLAP SET STORNO=2 WHERE SORSZAM='+inttostr(_sorszam);
  ValutaParancs(_pcs);

  AdatlapDbase.Connected := true;
  _pcs := 'SELECT * FROM ADATLAP' + _sorveg;
  if _szuro<>'' then _pcs := _pcs + 'WHERE '+ _szuro + _sorveg;
  _pcs := _pcs + 'ORDER BY SORSZAM DESC';

  with AdatlapQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
    end;

  AdatlapQuery.Locate('SORSZAM',_sorszam,[]);

  JogiStornoLabel.Visible := True;
  UgyfStornoLabel.Visible := true;
end;

// =============================================================================
     procedure TADATLAPFORM.FormKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
   if ord(key)= 34  then  // pgdwn
     begin
       KovetkezoGombClick(kovetkezogomb);
       exit;
     end;

   if ord(key)= 33 then  // pgup
     begin
       ElozoGombClick(elozogomb);
       Exit;
     end;

   if ord(Key)=119 then
     begin
       NyomtatogombClick(Nyomtatogomb);
       exit;
     end;
end;


// =============================================================================
           procedure TADATLAPFORM.nyomtatogombClick(Sender: TObject);
// =============================================================================

begin

  NyomtatoGomb.Enabled := False;
  with NyomtatoPanel do
    begin
      top := 330;
      Left := 280;
      Show;
    end;
  ActiveControl := AzonositoNyomtatoGomb;
end;


// =============================================================================
       procedure TADATLAPFORM.AZONOSITONYOMTATOGOMBClick(Sender: TObject);
// =============================================================================

begin
  NyomtatoPanel.Visible := false;
  ActiveControl := KovetkezoGomb;
end;

// =============================================================================
      procedure TADATLAPFORM.BEJELENTESNYOMTATOGOMBClick(Sender: TObject);
// =============================================================================

begin
  NyomtatoPanel.Visible := False;

//  BejelentesPrepare;
  BejelentesNyomtatas;
  StartNyomtatas;
  ActiveControl := KovetkezoGomb;
end;

// =============================================================================
         procedure TadatLapform.Pirosito(_hova: TEdit; _text: string);
// =============================================================================


var _csillag: char;
    _ww: integer;

begin
  if _text='' then exit;
  _text := trim(_text);
  _ww := length(_text);
  if _ww = 0 then exit;
  _csillag := _text[_ww];
  if _csillag='*' then
    begin
      _hova.Font.color := clRed;
      _ww := length(_text);
      _text := Leftstr(_text,_ww-1);
    end else
    begin
      _hova.Font.Color := clBlack;
    end;
  _hova.Text := _text;
end;

// =============================================================================
          procedure TADATLAPFORM.korvisszagombClick(Sender: TObject);
// =============================================================================

begin
  AdatlapDbase.Close;
  AdatlapDbase.Connected := true;
  if adatlapTranz.InTransaction then AdatlapTranz.Commit;

  _pcs := 'SELECT * FROM ADATLAP'+_sorveg;
  if _szuro<>'' then  _pcs := _pcs + 'WHERE '+ _szuro + _sorveg;
  _pcs := _pcs + 'ORDER BY SORSZAM DESC';

  with AdatLapQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Locate('SORSZAM',_aktsorszam,[]);
    end;
end;



// =============================================================================
                    procedure TAdatlapForm.GongyErtekDisp;
// =============================================================================


begin
  _gertek := 0;
  GongycsomagTabla.First;
  while not GongycsomagTabla.eof do
    begin
      _ertek := GongycsomagTabla.FieldByName('FORINTERTEK').asInteger;
      _gertek := _gertek + _ertek;
      GongyCsomagTabla.Next;
    end;
 
end;


// =============================================================================
              procedure TADATLAPFORM.BitBtn1Enter(Sender: TObject);
// =============================================================================

begin
  TBitBtn(sender).font.Color := clPurple;
end;

// =============================================================================
               procedure TADATLAPFORM.BitBtn1Exit(Sender: TObject);
// =============================================================================

begin
  TBitBtn(sender).Font.Color := clGray;
end;

// =============================================================================
          procedure TADATLAPFORM.adatmodositogombClick(Sender: TObject);
// =============================================================================

begin
//  _spk := supervisorjelszo;
  if _spk<>1 then exit;

  cimedit.ReadOnly := False;
  CimCardEdit.ReadOnly := false;
  OkmTipEdit.ReadOnly := False;
  AzonositoEdit.ReadOnly := False;
  AllampolgEdit.ReadOnly := False;
  TartHelyEdit.ReadOnly := False;

 // MegsemGomb.Enabled := True;
//  AdatModositoGomb.Enabled := false;

  _vregi[1] := Cimedit.Text;
  _vregi[2] := cimcardedit.Text;
  _vregi[3] := okmtipedit.Text;
  _vregi[4] := azonositoedit.Text;
  _vregi[5] := allampolgedit.text;
  _vregi[6] := TarthelyEdit.Text;

  ActiveControl := cimedit;

end;

// =============================================================================
              procedure TADATLAPFORM.CIMEDITEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := $80FFFF;
end;

// =============================================================================
              procedure TADATLAPFORM.CIMEDITExit(Sender: TObject);
// =============================================================================


begin
  TEDIT(SENDER).Color := clWindow;
end;


// =============================================================================
    procedure TADATLAPFORM.CIMEDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

var _kod: byte;
begin
  _tag := Tedit(sender).Tag;
  _kod := ord(key);
 // rendbengomb.Enabled := true;
  if (_kod=40) or (_kod=13) then
    begin

      if _tag<6 then
        begin
           inc(_tag);
           Activecontrol := _vedit[_tag];
        end else
  //        ActiveControl := RendbenGomb;
      exit;
    end;

  if (_kod=38) and (_tag>1) then ActiveControl := _vedit[_tag-1];
end;


// =============================================================================
            procedure TADATLAPFORM.BitBtn2Click(Sender: TObject);
// =============================================================================

begin
  jOGIPANEL.Hide;
  ActiveControl := Kovetkezogomb;
end;

// =============================================================================
                  procedure TadatlapForm.Bejelentesnyomtatas;
// =============================================================================

var i,_qErtek:integer;

begin
  assignFile(_LFile,'c:\valuta\Aktlst.txt');
  Rewrite(_LFile);
  write(_LFile,_inic);
  WriteLn(_LFile,inttostr(_sorszam)+'. Bejelentesi adatlap '+ _datums);
  writeLn(_LFile,' ');
  WriteLn(_Lfile,'  Titkosan kezelendo, bizalmas adatok');
  writeLn(_Lfile,' Haladektalanul tovabbitando felettesnek');
  writeLn(_Lfile,dupestring('=',39));
  writeLn(_Lfile,_widOn+'      BEJELENTES'+_widOff);
  writeLn(_Lfile,'          szokatlan tranzakciokrol');
  writeLn(_Lfile,dupestring('=',39));
  writeLn(_Lfile,'Az erintett penzugyi szolgaltato neve:');
  writeLn(_LFile,' ');
  writeLn(_Lfile,'Tranzakciot eszlelo fiok:');
  KozepreIr(_penztarnev);
  writeLn(_LFile,' ');
  KozepreIr(_cegnev);
  KozepreIr(_cegcim);
  Kozepreir(_penztarkod+' szamu penztar');
  KozepreIr(_PenztarCim);
  writeLn(_Lfile,' ');
  writeLn(_Lfile,'Felelos szemely:');
  writeLn(_Lfile,' ');
  writeLn(_Lfile,_felelos);

  writeLn(_Lfile,' ');
  writeLn(_Lfile,'A tranzakciot folytato ugyfel adatai:');
  writeLn(_Lfile,' ');
  if _joginev<>'' then
    begin
      writeLn(_Lfile,' Jogi szemely: '+_joginev);
      writeLn(_Lfile,'   telephelye: '+_jogihely);
      writeLn(_Lfile,'  Okiratszama: '+_okiratszam);
      writeln(_Lfile,' Tevekenysege: '+_tevekenyseg);
      writeLn(_Lfile,'  Kepviseloje: '+_kepvisnev);
      writeLN(_Lfile,' Megbizott sz: '+_ugyfelnev);
    end else writeLn(_Lfile,'  Ugyfel neve: '+_ugyfelnev);

  writeLn(_Lfile,'Szul.-i helye: '+_szulhely);
  writeLn(_LFile,'Szul.-i ideje: '+_szulido);
  writeLn(_Lfile,'   Anyja neve: '+_anyjaNeve);
  writeLn(_Lfile,'Cime: '+ _lakcim);
  writeLn(_Lfile,'  Allampolgar: '+ _allampolgar);
  writeLn(_LFile,'Okmany tipusa: '+ _okmanytipus);
  writeLn(_LFile,'        szama: '+ _azonosito);

  writeLN(_LFile,' ');
  for i := 1 to _fdb do
    begin
      _aktdnem := _vnem[i];
      writeLn(_Lfile,'         '+_aktdnem+'  '+_vbjs[i]+'  '+_vfts[i]);
    end;
  writeLn(_LFile,dupestring('-',39));
  writeLn(_Lfile,' ');
  writeLn(_Lfile,'Penzmosasra utalo adat, teny, korulmeny:');
  writeLn(_lFile,_korulmeny);
  writeLn(_Lfile,' ');
  writeLn(_Lfile,'Egyeb penzmosasra utalo korulmeny:');
  writeLn(_Lfile,_egyeb);
  writeLn(_Lfile,_sorveg);
  writeLn(_Lfile,'Penzugyi szolgaltato szervezet altal');
  writeLN(_Lfile,'             tet intezkedesek: ');
  writeLn(_LFile,' ');
  writeLn(_LFile,'Adatok rogzitese, bejelentesi kotele-');
  writeLn(_LFile,'zettseg vegrehajtasa');
  writeLn(_LFile,' ');

  writeLn(_LFile,'   Utobbi felev alatti tranzakciok');
  writeLn(_LFile,' ');

  VonalHuzo;
  WriteLn(_Lfile,' Datum  Bizonylat    Valuta     Forint');
  VonalHuzo;

  _uszuro := '(UGYFELTIPUS='+CHR(39)+_ugyfeltipus+chr(39);
  _uszuro := _uszuro + ') AND (UGYFELSZAM='+inttostr(_ugyfelszam)+')';
  _pcs := 'SELECT * FROM GONGYCSOMAG' + _sorveg;
  _pcs := _pcs + 'WHERE ' + _uszuro;

  GongyCsomagDbase.Connected := True;
  with GongyCsomagQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  _qErtek := 0;
  while not GongycsomagQuery.Eof do
    begin
      with GongycsomagQuery do
        begin
          _datums := FieldByNAme('DATUM').asstring;
          _bizonylatszam := FieldByName('BIZONYLATSZAM').asString;
          _bankjegy := FieldByNAme('BANKJEGY').AsInteger;
          _aktdnem := FieldByName('VALUTANEM').AsString;
          _ertek := FieldByName('FORINTERTEK').asInteger;
        end;
      _qErtek := _qErtek + _ertek;
      write(_LFile,midstr(_datums,3,8)+' ');
      write(_LFile,_bizonylatszam+' ');
      write(_lFile,ninelen(_bankjegy)+' ');
      write(_LFile,_aktdnem + ' ');
      writeLn(_LFile,ninelen(_ertek));
      GongycsomagQuery.Next;
    end;

  GongyCsomagQuery.close;
  GongyCsomagDbase.close;

  VonalHuzo;
  WriteLn(_LFile,'Osszes tranzakcio erteke: '+ forintform(_qErtek)+ ' Ft');
  VonalHuzo;

  writeLn(_LFile,_sorveg+_sorveg+_sorveg);
  VonalHuzo;
  writeLn(_Lfile,_widOn+'ATVETELI ELISMERVENY'+_widOff);
  VonalHuzo;
  writeLn(_Lfile,'Bejelentolap sorszama: '+inttostr(_sorszam));
  writeLn(_lFile,'    Bejelento penztar: '+_penztarkod+' sz. penztar');
  KozepreIr(_penztarcim);
  writeLn(_Lfile,'   Kiallito penztaros: '+ _penztarosnev);
  writeLn(_Lfile,'    A kiallitas kelte: '+_datums);
  writeLN(_lfile,_sorveg+_sorveg);
  writeLn(_LFile,'Atvetel-atadas kelte: ..................');
  writeLN(_lfile,_sorveg+_sorveg);
  writeLn(_LFile,'..................  ..................');
  writeLn(_LFile,'       atado               atvevo');
  writeLN(_lfile,_sorveg+_sorveg);
end;

procedure TAdatlapform.VonalHuzo;

begin
  writeLn(_LFile,dupestring('-',39));
end;

// =============================================================================
             function Tadatlapform.Kozepreir(_mit: string): string;
// =============================================================================


begin
  result := _mit;
end;

// =============================================================================
       procedure TADATLAPFORM.NYOMTATASVEGEGOMBClick(Sender: TObject);
// =============================================================================

begin
  NyomtatoPanel.Visible := False;
  ActiveControl := KovetkezoGomb;
end;

// =============================================================================
              function TadatlapForm.Ninelen(_num: integer):string;
// =============================================================================


begin
  result := inttostr(_num);
  while length(result)<9 do result := ' '+ result;
end;

// =============================================================================
           procedure TADATLAPFORM.MBSZEMELYGOMBClick(Sender: TObject);
// =============================================================================

begin
  Naturdisp;
  JogiPanel.Left := 440;

end;

// =============================================================================
          procedure TAdatlapForm.RFELEVClick(Sender: TObject);
// =============================================================================

begin
  TranzakcioDisplay;
end;




procedure TAdatlapForm.NEVEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);

var _aktedit: TEdit;
    _text: string;
    _wleng: integer;
    _utbetu : char;

begin
  if Ord(Key)<>13 then exit;
  _aktedit := Tedit(sender);
  _text := trim(_aktedit.text);
  _wleng := length(_text);
  _utbetu := _text[_wleng];
  if _utbetu<>'*' then _text := _text + '*';
  _aktedit.text := _text;
  ModrendbenGomb.Enabled := True;
  ActiveControl := ModrendbenGomb;
end;

// =============================================================================
           procedure TADATLAPFORM.cancelgombClick(Sender: TObject);
// =============================================================================

begin
  if AdatlapTranz.InTransaction then AdatlapTranz.commit;
  AdatlapQuery.close;
  adatlapDbase.close;
  Modalresult := -1;
end;

// =============================================================================
                      procedure TAdatlapForm.StartNyomtatas;
// =============================================================================

begin
  Writeln(_LFile,_sorveg,_sorveg);
  WriteLn(_LFile,chr(26));
  CloseFile(_LFile);
  TextKiiro;
end;

// =============================================================================
                            procedure TAdatlapForm.TextKiiro;
// =============================================================================

var _mondat: string;
    _nyomtat,_olvas: textFile;

begin
  AssignFile(_nyomtat,'LPT1');
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


procedure TadatlapForm.Valutaparancs(_ukaz: string);

begin
  ValutaDbase.connected := True;
  if ValutaTranz.InTransaction then ValutaTranz.Commit;
  Valutatranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_ukaz);
      ExecSql;
    end;
  ValutaTranz.Commit;
  ValutaDbase.close;
end;

function Tadatlapform.HunDateTostr(_caldat: TDateTime): string;

var _h_ev,_h_ho,_h_nap: word;
begin
  _h_ev := yearof(_caldat);
  _h_ho := monthof(_caldat);
  _h_nap:= dayof(_caldat);

  result := inttostr(_h_ev)+'.'+nulele(_h_ho)+'.'+nulele(_h_nap);
end;

function Tadatlapform.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


procedure TAdatlapForm.VISSZAGOMBClick(Sender: TObject);
begin
  GongycsomagTabla.close;
  GongyCsomagDbase.close;
  Modalresult := -1;
end;



procedure TAdatlapForm.BEJELENT3GOMBClick(Sender: TObject);
begin
  if _sorszam>0 then Modalresult := _sorszam
  else Modalresult := -1;

end;


end.
