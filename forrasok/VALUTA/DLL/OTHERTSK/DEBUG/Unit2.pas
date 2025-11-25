unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, DB, DBTables, Grids, DBGrids,printers,
  ComCtrls, IBDatabase, IBCustomDataSet, IBTable, IBQuery, strutils, jpeg;

type
  TEGYEBBEALLITASFORM = class(TForm)
    WUGYFELPANEL: TPanel;
    WUGYFELRACS: TDBGrid;
    visszagomb: TBitBtn;
    Label5: TLabel;
    KERESEDIT: TEdit;
    Label6: TLabel;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    VALUTAQUERY: TIBQuery;
    Shape13: TShape;
    Image1: TImage;
    fopanel: TPanel;
    Image2: TImage;
    Label2: TLabel;
    BEALLITASGOMB: TBitBtn;
    ALLVALUTACLEARGOMB: TBitBtn;
    ALLVALUTAINSTALLGOMB: TBitBtn;
    BACKTOMENUGOMB: TBitBtn;
    kilepo: TTimer;
    NAPNYITASGOMB: TBitBtn;
    NAPZARASGOMB: TBitBtn;
    MENUTAKARO: TPanel;
    Image3: TImage;
    PTARGEPGOMB: TBitBtn;
    ADATLAPGOMB: TBitBtn;
    UGYTMKGOMB: TBitBtn;
    MELLEKLET: TPanel;
    MELL3PANEL: TPanel;
    Panel2: TPanel;
    Panel1: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Label1: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label8: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    EGYSEGEDIT: TEdit;
    DATUMIDOEDIT: TEdit;
    KIJELOLTEDIT: TEdit;
    NEVEDIT: TEdit;
    LEIRASEDIT: TEdit;
    CONFIRMDOKUEDIT: TEdit;
    KORULMENYEDIT: TEdit;
    INTEZKEDESEDIT: TEdit;
    ADATQUERY: TIBQuery;
    ADATDBASE: TIBDatabase;
    ADATTRANZ: TIBTransaction;
    DataSource1: TDataSource;
    ADATRACS: TDBGrid;
    ADATQUERYUGYFELTIPUS: TIBStringField;
    ADATQUERYUGYFELSZAM: TIntegerField;
    ADATQUERYUGYFELNEV: TIBStringField;
    ADATQUERYDATUM: TIBStringField;
    ADATQUERYVALUTANEM: TIBStringField;
    ADATQUERYBANKJEGY: TIntegerField;
    ADATQUERYFORINTERTEK: TIntegerField;
    ADATQUERYGONGYCSOMAGSZAM: TIntegerField;
    ADATQUERYDATUGYFSZAM: TIBStringField;
    ADATQUERYBIZONYLATSZAM: TIBStringField;
    ADATQUERYFELADVA: TSmallintField;
    MELLEK3GOMB: TBitBtn;
    MELLEK8GOMB: TBitBtn;
    EXITGOMB: TBitBtn;
    Label7: TLabel;
    Label9: TLabel;
    CIMEDIT: TEdit;
    Label34: TLabel;
    OKMANYEDIT: TEdit;
    Label17: TLabel;
    EGYEBEDIT: TEdit;
    ADATQUERYFORRAS: TIBStringField;
    ADATQUERYENGEDELYEZO: TIBStringField;
    NYITOPANEL: TPanel;
    Label12: TLabel;
    NORMNYITASGOMB: TBitBtn;
    NYITAS3GOMB: TBitBtn;
    Shape1: TShape;
    Shape2: TShape;
    OTPGOMB: TBitBtn;
    OTPPANEL: TPanel;
    Label13: TLabel;
    PROSBELEPGOMB: TBitBtn;
    PROSKILEPGOMB: TBitBtn;
    BACKGOMB: TBitBtn;
    TERMZAROGOMB: TBitBtn;
    FRISSITOGOMB: TBitBtn;
    SETCOMPORTGOMB: TBitBtn;
    NAVPORTPANEL: TPanel;
    Shape3: TShape;
    Label18: TLabel;
    C1: TRadioButton;
    C2: TRadioButton;
    C3: TRadioButton;
    C4: TRadioButton;
    SPFIXGOMB: TBitBtn;
    SPMEGSEMGOMB: TBitBtn;

 
    procedure FormActivate(Sender: TObject);
    procedure Menube;

    procedure BEALLITASGOMBClick(Sender: TObject);

    procedure BACKTOMENUGOMBClick(Sender: TObject);

//    procedure ALLVALUTACLEARGOMBClick(Sender: TObject);
//    procedure ALLVALUTAINSTALLGOMBClick(Sender: TObject);

    procedure ValutaParancs(_ukaz: string);
    procedure kilepoTimer(Sender: TObject);
    procedure PTARGEPGOMBClick(Sender: TObject);
    procedure ADATLAPGOMBClick(Sender: TObject);
    procedure UGYTMKGOMBClick(Sender: TObject);
    procedure BejelentMain;
    function Aposztless(_s: string): string;
    procedure WriteMelleklet8;
    procedure Mellek1Print(Sender: TObject);
    procedure NAPZARASGOMBClick(Sender: TObject);
    procedure NORMNYITASGOMBClick(Sender: TObject);
    procedure NYITAS3GOMBClick(Sender: TObject);
    procedure ALLVALUTACLEARGOMBClick(Sender: TObject);
    procedure ALLVALUTAINSTALLGOMBClick(Sender: TObject);
    procedure NAPNYITASGOMBClick(Sender: TObject);

    procedure ADATRACSEnter(Sender: TObject);
    procedure ADATRACSExit(Sender: TObject);
    procedure KORULMENY8EDITEnter(Sender: TObject);
    procedure KORULMENY8EDITExit(Sender: TObject);
    procedure NEVEDITKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure KORULMENY8EDITKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure Adatmentes;
    procedure EXITGOMBClick(Sender: TObject);
    function FtForm(_ft: integer): string;
    procedure LastTranzRead;


    procedure Kozepreir(_s: string);
    procedure TextKiiro;
    procedure Soremeles;
   
    procedure WriteMelleklet1;
    procedure MELLEK8GOMBClick(Sender: TObject);
    procedure PROSBELEPGOMBClick(Sender: TObject);
    procedure PROSKILEPGOMBClick(Sender: TObject);
    procedure TERMZAROGOMBClick(Sender: TObject);
    procedure BACKGOMBClick(Sender: TObject);
    procedure OTPGOMBClick(Sender: TObject);
    procedure FRISSITOGOMBClick(Sender: TObject);
    procedure SPMEGSEMGOMBClick(Sender: TObject);
    procedure SPFIXGOMBClick(Sender: TObject);
 
    procedure SETCOMPORTGOMBClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  EGYEBBEALLITASFORM: TEGYEBBEALLITASFORM;

  _cm: array[1..4] of TRadioButton;

  _ezsupervisor,_qroke,_spk,_oke,_sorszam,_recno,_gcsomagszam: integer;
  _forras,_engedelyezo,_aktdnem: string;
  _ugyfelszam,_printer,_aktbankjegy,_aktertek,_ww,_code: integer;
  _top,_left,_width,_height,_kozszereplo: word;
  _BILL,_t,_homeszam: BYTE;

  _xDa,_xBi,_xDn: array[1..30] of string;
  _xBj,_xFt: array[1..30] of integer;
  _tetel,_otpoke,_navcom: byte;

  _kftNev,_aktprosnev,_aktbizonylat: string;

  _medit: array[1..3] of TEdit;

  _pcs,_leiras,_cdoku,_korulmeny,_aktdatum,_tarthely,_cegnev: string;
  _intezkedes,_datum,_ido,_ugyfeltipus,_bizonylatszam: string;
  _joginev,_jogihely,_okiratszam,_kepvisnev,_kepvisbeo,_megbizottnev: string;
  _mbbeo,_nev,_elozonev,_anyjaneve,_lakcim,_szulido,_szulhely,_irszam: string;
  _varos,_utca,_okmtip,_azonosito,_allampolgar,_leanykori,_homekod: string;
  _homenev,_homecim,_hometel,_egyseg,_datumidos,_kijelolt,_nevstr: string;
  _allamp,_anyacim,_okmany,_megnyitottnap: string;
  _sorveg: string = chr(13)+chr(10);
  _LFile : textfile;

  _update: boolean;

function otpterminal: integer; stdcall; external 'c:\valuta\bin\otp.dll' name 'otpterminal';
function ugyfeltmkrutin: integer; stdcall; external 'c:\valuta\bin\ugyftmk.dll' name 'ugyfeltmkrutin';  
function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';
function parameterezes: integer; stdcall; external 'c:\VALUTA\bin\gepsetup.dll' name 'parameterezes';
function adatlaprutin: integer; stdcall; external 'c:\valuta\bin\adatlap.dll'  name 'adatlaprutin';
function bejelentorutin(_para: integer): integer; stdcall; external 'c:\valuta\bin\bejelent.dll'
                                         name 'bejelentorutin';

function qrdisplayrutin: integer; stdcall; external 'c:\valuta\bin\qrgener.dll' name 'qrdisplayrutin';
function othertaskrutin: integer; stdcall;

implementation

{$R *.dfm}

function othertaskrutin: integer; stdcall;
begin
  EgyebBeallitasForm := TegyebBeallitasForm.Create(Nil);
  result := egyebbeallitasform.ShowModal;
  EgyebBeallitasForm.Free;
end;


// =============================================================================
          procedure TEGYEBBEALLITASFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  _top    := round((_height-768)/2);
  _left   := round((_width-1024)/2);


  Top    := _top;
  Left   := _left;
  Width  := 1024;
  Height :=  768;

  Menutakaro.Visible := true;
  Melleklet.Visible  := False;
  Mellek3gomb.Enabled := True;
  Mellek8gomb.Enabled := True;

  _medit[1] := Leirasedit;
  _medit[2] := Confirmdokuedit;
  _medit[3] := Korulmenyedit;

  _cm[1] := C1;
  _cm[2] := C2;
  _cm[3] := C3;
  _cm[4] := C4;

  _spk := supervisorjelszo(0);
  if _spk<>1 then
    begin
      Kilepo.enabled := true;
      exit;
    end;
  Menube;
end;


procedure TEGYEBBEALLITASFORM.Menube;

begin
  with fopanel do
    begin
      top  := 170;
      left := 240;
      Visible := True;
     end;
  ActiveControl := BeallitasGomb;
end;

// =============================================================================
       procedure TEGYEBBEALLITASFORM.BEALLITASGOMBClick(Sender: TObject);
// =============================================================================

begin
  _oke := parameterezes;
  if _oke=1 then
    begin
      Application.Terminate;
      exit;
    end;
end;

// =============================================================================
         procedure TEGYEBBEALLITASFORM.BACKTOMENUGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;



// =============================================================================
          procedure TEgyebBeallitasForm.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  Valutadbase.Connected := true;
  if valutatranz.InTransaction then ValutaTranz.commit;
  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      execSql;
    end;
  ValutaTranz.commit;
  valutadbase.close;
end;

procedure TEGYEBBEALLITASFORM.kilepoTimer(Sender: TObject);
begin
  Kilepo.Enabled := false;
  Modalresult := 2;
end;

procedure TEGYEBBEALLITASFORM.PTARGEPGOMBClick(Sender: TObject);
begin
  MenuTakaro.visible := False;
end;

procedure TEGYEBBEALLITASFORM.ADATLAPGOMBClick(Sender: TObject);

begin
  fopanel.Visible := false;
  _sorszam := adatlaprutin;
  if _sorszam>0 then BejelentMain
  else Menube;
end;

procedure TEGYEBBEALLITASFORM.UGYTMKGOMBClick(Sender: TObject);
begin
  ugyfeltmkrutin;
end;

procedure TEGYEBBEALLITASFORM.BejelentMain;

begin
  _kozszereplo := 0;
  with MellekLet do
    begin
      top := 0;
      Left := 80;
    end;

  _pcs := 'SELECT * FROM BEJELENT WHERE SORSZAM='+inttostr(_sorszam);
  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  _leiras := '';
  _cdoku := '';
  _korulmeny := '';
  _intezkedes := '';
  _update := False;

  if _recno>0 then
    begin
      with ValutaQuery do
        begin
          _leiras := Aposztless(FieldByNAme('LEIRAS').asString);
          _cdoku := Aposztless(FieldByNAme('CDOKU').asstring);
          _korulmeny := Aposztless(FieldByNAme('KORULMENY3').asString);
          _intezkedes := Aposztless(FieldByNAme('INTEZKEDES').asstring);
        end;
      _update := True;
    end;
  ValutaQuery.close;

  _pcs := 'SELECT * FROM ADATLAP WHERE SORSZAM='+INTTOSTR(_sorszam);
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;
  if _recno=0 then
    begin
      Valutaquery.close;
      Valutadbase.close;
      ShowMessage('NEM TALÁLOM A KÉRT ADATLAPOT !');
      Kilepo.Enabled := true;
      exit;
    end;
  with ValutaQuery do
    begin
      _gcsomagszam := FieldByName('GONGYCSOMAGSZAM').asInteger;
      _datum := FieldByNAme('DATUM').asString;
      _ido := trim(FieldByNAme('IDO').asString);
      Close;
    end;

  _pcs := 'SELECT * FROM GONGYCSOMAG WHERE GONGYCSOMAGSZAM='+inttostr(_gcsomagszam);
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.Add(_pcs);
      Open;
      _recno := recno;
    end;
  if _recno=0 then
    begin
      ValutaQuery.close;
      Valutadbase.close;
      ShowMessage('NINCSENEK ADATAIM A KÉRT JELENTÉSHEZ !');
      Kilepo.enabled := true;
      exit;
    end;

  with ValutaQuery do
    begin
      _ugyfeltipus := FieldbyName('UGYFELTIPUS').asString;
      _ugyfelszam  := FieldByNAme('UGYFELSZAM').asInteger;
      _bizonylatszam:= trim(FieldByNAme('BIZONYLATSZAM').AsString);
      Close;
    end;
  if _ugyfeltipus='J' then
    begin
      _pcs := 'SELECT * FROM JOGISZEMELY WHERE UGYFELSZAM='+inttostr(_ugyfelszam);
      with ValutaQuery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _recno := recno;
        end;
      if _recno=0 then
        begin
          ValutaQuery.Close;
          Valutadbase.close;
          Showmessage('NINCSENEK ADATAIM AZ ÜGYFÉLRÕL !');
          Kilepo.enabled := true;
          exit;
        end;

      with ValutaQuery do
        begin
          _joginev := Aposztless(FieldByName('JOGISZEMELYNEV').AsString);
          _jogihely:= Aposztless(FieldByName('TELEPHELYCIM').AsString);
          _okiratszam :=Aposztless(FieldByName('OKIRATSZAM').AsString);
          _kepvisnev := Aposztless(FieldByName('KEPVISELONEV').AsString);
          _kepvisbeo := Aposztless(FieldByNAme('KEPVISBEO').AsString);
          _megbizottnev := Aposztless(FieldByNAme('MEGBIZOTTNEVE').AsString);
          _mbbeo := Aposztless(FieldByName('MEGBIZOTTBEOSZTASA').AsString);
          Close;
        end;
    end;

  if _ugyfeltipus='N' then
    begin
      _pcs := 'SELECT * FROM UGYFEL WHERE UGYFELSZAM='+inttostr(_ugyfelszam);
      with ValutaQuery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _recno := recno;
        end;

      if _recno=0 then
        begin
          ValutaQuery.Close;
          Valutadbase.close;
          Showmessage('NINCSENEK ADATAIM AZ ÜGYFÉLRÕL !');
          Kilepo.enabled := true;
          exit;
        end;

      with ValutaQuery do
        begin
          _nev := Aposztless(FieldByName('NEV').AsString);
         _elozonev := Aposztless(FieldByName('ELOZONEV').AsString);
         _anyjaneve := Aposztless(FieldByName('ANYJANEVE').AsString);
         _lakcim := Aposztless(FieldByName('LAKCIM').AsString);
         _szulido := Aposztless(FieldbyName('SZULETESIIDO').asString);
         _szulhely := Aposztless(Fieldbyname('SZULETESIHELY').AsString);
         _irszam := Aposztless(FieldByName('IRSZAM').AsString);
         _varos := Aposztless(FieldByName('VAROS').asstring);
         _utca := Aposztless(FieldByNAme('UTCA').AsString);
         _okmtip := Aposztless(FieldByName('OKMANYTIPUS').AsString);
         _azonosito := Aposztless(FieldByNAme('AZONOSITO').AsString);
         _allampolgar := Aposztless(FieldByName('ALLAMPOLGAR').asString);
         _leanykori := Aposztless(FieldByNAme('LEANYKORI').AsString);
         _kozszereplo := FieldbyNAme('KOZSZEREPLO').asInteger;
         _tarthely := Aposztless(FieldByName('TARTOZKODASIHELY').AsString);
          Close;
        end;
      if _lakcim='' then _lakcim := _irszam+' '+_varos+' '+_utca;
    end;
   _pcs := 'SELECT * FROM PENZTAR';
   with ValutaQuery do
     begin
       close;
       sql.clear;
       sql.add(_pcs);
       Open;
       _homekod := trim(FieldByName('PENZTARKOD').AsString);
       _homenev := trim(FieldByNAme('PENZTARNEV').asstring);
       _homecim := trim(FieldByNAme('PENZTARCIM').asstring);
       _hometel := trim(FieldByNAme('TELEFONSZAM').asstring);
       Close;
       sql.Clear;
       sql.add('SELECT * FROM HARDWARE');
       Open;

       _printer := FieldByNAme('PRINTER').asInteger;
       _aktprosnev := trim(FieldByName('PENZTAROSNEV').AsString);
       _kftnev := trim(FieldByNAme('KFTNEV').AsString);
       _megnyitottnap := FieldByNAme('MEGNYITOTTNAP').asstring;
       Close;
     end;

   val(_homekod,_homeszam,_code);
   if _homeszam<151 then
     begin
       _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';
     end else
     begin
       _cegnev := 'EXPRESSZ EKSZERHAZ ES MINIBANK KFT';
     end;


   _pcs := 'SELECT * FROM GONGYCSOMAG WHERE UGYFELSZAM='+inttostr(_ugyfelszam);
   Valutadbase.close;
   Adatdbase.Connected := True;
   with adatQuery do
     begin
       Close;
       sql.clear;
       sql.Add(_pcs);
       Open;
     end;

   _egyseg := leftstr(_homenev+' '+_homecim+' '+_hometel,40);
   _datumidos := _datum + ' - ' +_ido;
   _kijelolt := '';
   if _homeszam<151 then
       _kijelolt := 'NAGY ANNAMÁRIA PÉCS CITROM UTCA 2-6 TEL:06+70-457-75-63';

   if _ugyfeltipus='N' then
     begin
       _nevstr := _nev;
       if _elozonev<>'' then _nevstr := _nev + ' ('+_elozonev+')';
       if _leanykori<>'' then _nevstr := _nev + ' ('+_leanykori + ')';
       _allamp := _allampolgar+' (szul: '+_szulido+' '+_szulhely+')';
       _anyacim := _anyjaneve+' '+_lakcim;
       _okmany := _okmtip+' '+_azonosito;
     end;

 
   // -------------------- 3 - as melléklet feltöltése --------------------

   if _ugyfeltipus='N' then
     begin
       Nevedit.Text := _nev;
       Okmanyedit.text := _okmtip + ' '+_azonosito;
       Cimedit.Text := _lakcim;
       Egyebedit.Text := _szulido+' '+_szulhely +' '+_anyjaneve;
     end;

   if _ugyfeltipus='J' then
     begin
       Nevedit.Text := _joginev;
       Okmanyedit.Text := _okiratszam;
       Cimedit.Text := _jogihely;
       Egyebedit.Text := _megbizottnev;
     end;

   Egysegedit.text :=  _egyseg;
   Datumidoedit.Text := _datumidos;
   Kijeloltedit.Text := _kijelolt;
   LeirasEdit.Text := _leiras;
   Confirmdokuedit.Text := _cdoku;
   Korulmenyedit.Text := _korulmeny;
   Intezkedesedit.Text :=  _intezkedes;

   // ---------------------------------------------------------------------

    Melleklet.Visible := true;

  with Mell3Panel do
    begin
      top := 2;
      left := 2;
      Visible := true;
      repaint;
    end;
  Activecontrol :=exitgomb;
end;


procedure TEGYEBBEALLITASFORM.ADATRACSEnter(Sender: TObject);
begin
  aDATRACS.Color := $B0FFFF;
end;

procedure TEGYEBBEALLITASFORM.ADATRACSExit(Sender: TObject);
begin
  Adatracs.Color := clWindow;
end;

procedure TEGYEBBEALLITASFORM.KORULMENY8EDITEnter(Sender: TObject);
begin
  Tedit(sender).Color := $B0FFFF;
end;

procedure TEGYEBBEALLITASFORM.KORULMENY8EDITExit(Sender: TObject);
begin
  tEDIT(SENDER).Color := clWindow;
end;

procedure TEGYEBBEALLITASFORM.NEVEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);

var _ess: byte;

begin
  _ess := TEdit(sender).Tag;
  _bill := ord(key);

  if (_bill<>13) and (_bill<>38) and (_bill<>40) then exit;

  if (_bill=13) or (_bill=40) then
    begin
      if _ess<3 then Activecontrol := _medit[_ess+1]
      else activecontrol := Adatracs;
    end;

  if (_bill=38) then
    begin
      if _ess>1 then  Activecontrol := _medit[_ess-1];
    end;

end;

procedure TEGYEBBEALLITASFORM.KORULMENY8EDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  activecontrol := Adatracs;
end;


procedure TEGYEBBEALLITASFORM.Adatmentes;

begin

  _leiras    := Aposztless(Leirasedit.Text);
  _cdoku     := Aposztless(Confirmdokuedit.Text);
  _korulmeny := Aposztless(Korulmenyedit.Text);
  _intezkedes:= 'Bejelentes az F.I.U. reszere';
  if _update then
    begin
      _pcs := 'UPDATE BEJELENT SET LEIRAS=' + chr(39) + _leiras + chr(39);
      _pcs := _pcs + ',CDOKU=' + chr(39) + _cdoku + chr(39);
      _pcs := _pcs + ',KORULMENY3=' + chr(39) + _korulmeny + chr(39);
      _pcs := _pcs + ',INTEZKEDES=' + chr(39) + _intezkedes + chr(39)+_sorveg;
      _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
    end else
    begin
      _pcs := 'INSERT INTO BEJELENT (SORSZAM,LEIRAS,';
      _pcs := _pcs + 'CDOKU,KORULMENY3,INTEZKEDES)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + inttostr(_sorszam) + ',';
      _pcs := _pcs + chr(39) + _leiras + chr(39) + ',';
      _pcs := _pcs + chr(39) + _cdoku + chr(39) + ',';
      _pcs := _pcs + chr(39) + _korulmeny + chr(39) + ',';
      _pcs := _pcs + chr(39) + _intezkedes + chr(39) + ')';
    end;
  Valutadbase.Connected := true;

  if valutatranz.InTransaction then valutaTranz.commit;
  Valutatranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;
  ValutaTranz.commit;
  Valutadbase.close;
end;

procedure TEGYEBBEALLITASFORM.EXITGOMBClick(Sender: TObject);
begin
  AdatQuery.Close;
  Adatdbase.close;
  Adatmentes;
  Melleklet.Visible := false;
  MENUBE;
end;




{
procedure TEGYEBBEALLITASFORM.Nyomtatas;

var _w: byte;

begin

  _leiras      := Aposztless(Leirasedit.Text);
  _cdoku       := Aposztless(Confirmdokuedit.Text);
  _korulmeny   := Aposztless(Korulmenyedit.Text);
 
  _intezkedes  := Aposztless(IntezkedesEdit.Text);

  AssignFile(_LFile,'c:\valuta\aktlst.txt');
  rewrite(_LFile);
  writeLn(_LFile,'   BEJELENTES PENZMOSAS ES TERRORIZMUS');
  writeLn(_LFile,' FINANSZIROZASARA UTALO ADAT, TENY VAGY');
  writeLn(_LFile,'    KORULMENY FELMERULESERE UTALO');
  writeLn(_LFile,'              INFORMACIOROL' + _sorveg);


  writeLn(_LFile,'Bejelento egyseg:');
  writeLn(_LFile,_egyseg);
  write(_LFile,'Eszleles datuma és ideje: ');
  writeLn(_LFile,_datumidos);
  writeLn(_LFile,'Kijelolt szemely:');
  writeLn(_LFile,_kijelolt+_sorveg);
  if _ugyfeltipus='N' then
    begin
      writeLn(_LFile,'Neve:');
      writeLn(_LFile,_nev);
      writeLn(_LFile,'Lakcime:');
      writeLn(_LFile,_lakcim);
      writeLn(_LFile,'Okmanyai:');
      writeLn(_LFile,_okmtip+' '+_azonosito);
    end;

  if _ugyfeltipus='J' then
    begin
      writeLn(_LFile,'Megnevezese:');
      writeLn(_LFile,_joginev);
      writeLn(_LFile,'Telephelye:');
      writeLn(_LFile,_jogihely);
      writeLn(_LFile,'Okirat szama:');
      writeLn(_LFile,_okiratszam);
      writeLn(_LFile,'Kepviselo neve:');
      writeLn(_LFile,_kepvisnev);
      writeLn(_LFile,'Megbizott neve:');
      writeLn(_LFile,_megbizottnev);
      writeLn(_LFile,' ');
    end;

  if _kapcsolodo<>'' then
    begin
      writeLn(_LFile,'Kapcsolodo szemelyek adatai:');
      _w := length(_kapcsolodo);

      Kozepreir(leftstr(_kapcsolodo,40));
      if _w>40 then Kozepreir(midstr(_kapcsolodo,41,_w-40));
      writeLn(_Lfile,'  ');
    end;

  if _leiras<>'' then
    begin
      writeLn(_LFile,'Az ugylet leirasa:');
       _w := length(_leiras);

      Kozepreir(leftstr(_leiras,40));
      if _w>40 then Kozepreir(midstr(_leiras,41,_w-40));
      writeLn(_Lfile,'  ');
    end;

  if _ugyfszamlak<>'' then
    begin
      writeLn(_LFile,'Az ugyfel szamlai:');
       _w := length(_ugyfszamlak);

      Kozepreir(leftstr(_ugyfszamlak,40));
      if _w>40 then Kozepreir(midstr(_ugyfszamlak,41,_w-40));
      writeLn(_Lfile,'  ');
    end;

  if _utalo<>'' then
    begin
      writeLn(_LFile,'Penzmosasra utalo adatok:');
       _w := length(_utalo);

      Kozepreir(leftstr(_utalo,40));
      if _w>40 then Kozepreir(midstr(_utalo,41,_w-40));
      writeLn(_Lfile,'  ');
    end;

  if _cdoku<>'' then
    begin
      writeLn(_LFile,'Penzmosast alatamaszto adatok:');
       _w := length(_cdoku);

      Kozepreir(leftstr(_cdoku,40));
      if _w>40 then Kozepreir(midstr(_cdoku,41,_w-40));
      writeLn(_Lfile,'  ');

    end;

  if _korulmeny3<>'' then
    begin
      writeLn(_LFile,'Mas penzmosasra utalo korulmeny:');
       _w := length(_korulmeny3);

      Kozepreir(leftstr(_korulmeny3,40));
      if _w>40 then Kozepreir(midstr(_korulmeny3,41,_w-40));
      writeLn(_Lfile,'  ');
    end;

  if _korulmeny8<>'' then
    begin
      writeLn(_LFile,'Minden olyan adat es korulmeny,melybol');
      writeLn(_LFile,'az alanynak vagyoni elonye szarmazik:');
       _w := length(_korulmeny8);

      Kozepreir(leftstr(_korulmeny8,40));
      if _w>40 then Kozepreir(midstr(_korulmeny8,41,_w-40));
      writeLn(_Lfile,'  ');

    end;

  if _intezkedes<>'' then
    begin
      writeLn(_LFile,'Szervezet altal tett intezkedesek:');
      _w := length(_intezkedes);

      Kozepreir(leftstr(_intezkedes,40));
      if _w>40 then Kozepreir(midstr(_intezkedes,41,_w-40));
      writeLn(_Lfile,'  ');
    end;

  writeln(_LFile,_sorveg+_sorveg+_sorveg);
  writeLn(_LFile,'.................      .................');
  writeln(_LFile,'      atado                 atvevo');

  writeLn(_LFile,_sorveg+_sorveg);
  CloseFile(_LFile);
  TextKiiro;
 
end;
}

// =============================================================================
               procedure TEGYEBBEALLITASFORM.Kozepreir(_s: string);
// =============================================================================

var _ww,_oo: byte;

begin
  _s := trim(_s);
  _ww := length(_s);
  if _ww<40 then
    begin
      _oo := round((40-_ww)/2);
      _s := dupestring(' ',_oo)+_s;
    end;
  writeLn(_LFile,_s);
end;


function TEGYEBBEALLITASFORM.Aposztless(_s: string): string;

var _w,_asc,_y: byte;

begin
  result := '';
  _s := trim(_s);

  _w := length(_s);
  if _w=0 then exit;

  _y := 1;
  while _y<=_w do
    begin
      _asc := ord(_s[_y]);
      if (_asc<>39) and (_asc<>34) then result := result + chr(_asc);
      inc(_y);
    end;
end;

procedure TEGYEBBEALLITASFORM.Soremeles;

begin
  writeLN(_LFile,' ');
end;

function TegyebBeallitasForm.FtForm(_ft: integer): string;

var _wr,_f1: byte;

begin
  result := inttostr(_ft);
  _wr := length(result);
  if _wr<4 then exit;

  if _wr>6 then
    begin
      _f1 := _wr-6;
      result := leftstr(result,_f1)+'.'+midstr(result,_f1+1,3)+'.'+midstr(result,_f1+3,3);
      exit;
    end;

  _f1 := _wr-3;
  result := leftstr(result,_f1)+'.'+midstr(result,_f1+1,3);
end;




// =============================================================================
           procedure TEgyebBeallitasForm.Mellek1Print(Sender: TObject);
// =============================================================================


begin
  LastTranzRead;
  WriteMelleklet1;
  TextKiiro;
 
end;

// =============================================================================
               procedure TEgyebBeallitasForm.LastTranzRead;
// =============================================================================

var _t: byte;
    _bi,_da,_dn: string;
    _ft,_bj: integer;

begin

  _t := 0;
  _ft := 0;
  _bj := 0;
  Adatquery.first;
  while not Adatquery.Eof do
    begin
      _bi := AdatQuery.FieldByNAme('BIZONYLATSZAM').asString;
      _da := adatquery.FieldByName('DATUM').asString;
      _dn := adatquery.FieldbyName('VALUTANEM').asString;

      _ft := AdatQuery.FieldbyName('FORINTERTEK').asInteger;
      _bj := adatquery.FieldByName('BANKJEGY').asInteger;

      _forras := trim(Adatquery.FieldByNAme('FORRAS').asString);
      _engedelyezo := trim(AdatQuery.FieldbyNAme('ENGEDELYEZO').AsString);

      inc(_t);

      _xbi[_t] := _bi;
      _xda[_t] := _da;
      _xdn[_t] := _dn;
      _xft[_t] := _ft;
      _xbj[_t] := _bj;

      Adatquery.next;
    end;
  _tetel := _t;

  _aktbizonylat := _bi;
  _aktdnem := _dn;
  _aktertek := _ft;
  _aktbankjegy := _bj;

  adatquery.first;

  _leiras    := Aposztless(Leirasedit.Text);
  _cdoku     := Aposztless(Confirmdokuedit.Text);
  _korulmeny := Aposztless(Korulmenyedit.Text);
  _intezkedes:= 'Bejelentes az F.I.U. reszere';

end;

// =============================================================================
               procedure TEGYEBBEALLITASFORM.WriteMelleklet1;
// =============================================================================


begin

   assignfile(_LFile,'c:\valuta\aktlst.txt');
   rewrite(_LFile);

   Kozepreir('3. szamu melleklet');
   writeLn(_LFile,'Bejelentes penzmosas es terrorizmus fi-');
   writeLn(_LFile,'nanszirozasara utalo adat,  teny  vagy');
   writeLn(_LFile,'korulmeny felmerulesere utalo informa-');
   Kozepreir('ciorol');
   soremeles;

   KozepreIr('KIZAROLAG BELSO HASZNALATRA');
   writeLn(_LFile,'Titkosan kezelendo, bizalmas adatok');
   kozepreir('haladektalanul tovabbitando');
   kozepreir('a felettesnek');
   soremeles;

   writeLn(_LFile,'A erintett szolgaltato:');
   kozepreir(_CEGNEV);
   soremeles;

   writeLn(_LFile,'Tranzakciot eszlelo fiok:');
   Kozepreir(_homekod+'. szamu penztar');
   Kozepreir(_homenev);
   Kozepreir(_homecim);
   soremeles;

   writeLn(_LFile,'Bejelentes datuma: '+_megnyitottnap);
   soremeles;

   writeLn(_LFile,'Kijelolt szemely:');
   Kozepreir(_KIJELOLT);
   soremeles;

   writeLn(_LFile,'Tranzakciot folytato ugyfel:');
   if _ugyfeltipus='N' THEN
     begin
       KozepreIr(_nev);
       Kozepreir(_lakcim);
       Kozepreir(_tarthely);
       Kozepreir(_szulido+' '+_szulhely);
       KozepreIr(_anyjaneve);
       KozepreIr(_allampolgar);
       Kozepreir(_okmtip+' '+_azonosito);

     end else
     begin
       Kozepreir(_joginev);
       KozepreIr(_jogihely);
       Kozepreir(_okiratszam);
     end;
   soremeles;

   writeLn(_LFile,'Az ugylet reszletei:');
   Kozepreir('Bizonylatszam: '+_aktbizonylat);
   kozepreir(ftform(_aktbankjegy)+' '+_aktdnem+' ('+ftform(_aktertek)+' Ft)');

   if _forras<>'' then
     begin
       Kozepreir('A penz forrasa:');
       Kozepreir(_forras);
     end;

   if _engedelyezo<>'' then
     begin
       Kozepreir('Az engedelyezo:');
       Kozepreir(_engedelyezo);
     end;
   if _kozszereplo=0 then Kozepreir('Az ugyfel nem kiemelt kozszereplo')
   else kozepreir('Az ugyfel kiemelt kozszereplo');
   soremeles;

   _ww := length(_leiras);
   if _ww>0 then
     begin
       writeLn(_LFile,'Penzmosasra vagy terrorizmus finanszi-');
       writeLn(_LFile,'rozasara utalo adat, teny vagy korul-');
       writeLn(_LFile,'meny leirasa:');
       if _ww>40 then
          begin
            writeLn(_LFile,leftstr(_leiras,40));
            kozepreir(midstr(_leiras,41,_ww-40));
          end else Kozepreir(_leiras);
       soremeles;
     end;

   _ww := length(_cdoku);
   if _ww>0 then
     begin
       writeLn(_LFile,'A fentieket alatamaszto dokumentumok:');
       if _ww>40 then
         begin
           writeLn(_LFile,leftstr(_cDoku,40));
           kozepreir(midstr(_cDoku,41,_ww-40));
         end else Kozepreir(_cDoku);
       soremeles;
     end;

   _ww := length(_korulmeny);
   if _ww>0 then
     begin
       writeLn(_LFile,'Egyeb, fent nem emlitett korulmenyek:');
       if _ww>40 then
         begin
           writeLn(_LFile,leftstr(_korulmeny,40));
           kozepreir(midstr(_korulmeny,41,_ww-40));
         end else Kozepreir(_korulmeny);
       soremeles;
     end;

   writeLn(_Lfile,'A szolgaltato szervezet altal tett in-');
   writeLn(_lFile,'tezkedesek:');
   writeLn(_LFile,'  Bejelentes az F.I.U. reszere');
   soremeles;

   writeLn(_LFile,'Az utobbi felev tranzakcioi:');
   _t := 1;
   while _t<=_tetel do
     begin
       _aktbizonylat := _xbi[_t];
       _aktdnem      := _xdn[_t];
       _aktertek     := _xft[_t];
       _aktbankjegy  := _xbj[_t];
       _aktdatum     := _xDa[_t];

       kozepreir(_aktdatum+' - '+_aktbizonylat);
       kozepreir(ftform(_aktbankjegy)+' '+_aktdnem+'  ('+ftform(_aktertek)+' Ft)');

       inc(_t);
     end;

   Soremeles;

   kozepreir('ATVETELI ELISMERVENY');
   soremeles;
   writeln(_LFile,'Bejelento lap sorszama: '+inttostr(_sorszam)+'/'+leftstr(_megnyitottnap,4));
   writeLn(_LFile,'Bejelento ptar: '+ _homenev);
   writeln(_LFile,'Kiallito: '+_aktprosnev);
   writeLn(_LFile,'Kiallitas kelte: ' + _megnyitottnap);
   soremeles;

   writeLn(_LFile,'Atadas-atvetel kelte: .................');
   soremeles;

   writeLn(_LFile,'..................    .................');
   writelN(_LFile,'     atado                  atvevo');
   soremeles;
   soremeles;
   Closefile(_LFile);

end;

// =============================================================================
                            procedure TEGYEBBEALLITASFORM.TextKiiro;
// =============================================================================

var
    _nyomtat,_olvas: textFile;
    _mondat: string;
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
         procedure TEGYEBBEALLITASFORM.MELLEK8GOMBClick(Sender: TObject);
// =============================================================================

begin
  LastTranzRead;
  WriteMelleklet8;
  TextKiiro;

end;

// =============================================================================
              procedure TEGYEBBEALLITASFORM.WriteMelleklet8;
// =============================================================================

begin
   assignfile(_LFile,'c:\valuta\aktlst.txt');
   rewrite(_LFile);

   Kozepreir('8. szamu melleklet');
   soremeles;

   writeLn(_LFile,'Bejelentes penzugyi es vagyoni korla-');
   kozepreir('tozo intezkedes alapjan');
   soremeles;

   writeLn(_LFile,'TITKOSAN KEZELENDO, BIZALMAS ADATOK');
   kozepreir('Haladektalanul tovabbitando a');
   kozepreir('felettesnek');
   soremeles;

   kozepreir('Az erintett szolgaltato neve:');
   kozepreir('Exclusive Best Change Zrt');
   soremeles;

   kozepreir('Tranzakciot eszlelo fiok:');
   kozepreir(_homekod+'. szamu penztar');
   kozepreir(_homenev);
   Kozepreir(_homecim);
   soremeles;

   writeLn(_LFile,'Bejelentes datuma: ' + _megnyitottnap);
   writeln(_LFile,'Kijelolt szemely:');
   Kozepreir(_KIJELOLT);

   soremeles;

   writeLn(_Lfile,'Tranzakciot folytato ugyfel adatai:');
   if _ugyfeltipus='N' then
     begin
       kozepreir(_nev);
       kozepreir(_lakcim);
       Kozepreir(_tarthely);
       kozepreir(_szulido+' '+_szulhely);
       Kozepreir(_anyjaneve);
       Kozepreir(_allampolgar);
       kozepreir(_okmtip+': '+_azonosito);
     end;
   if _ugyfeltipus='J' then
     begin
       Kozepreir(_joginev);
       kozepreir(_jogihely);
       kozepreir(_okiratszam);
     end;
   Soremeles;

  writeLN(_LFile,'Az ugylet reszletei:');
  kozepreir('Bizonylat: '+ _aktbizonylat);
  kozepreir(ftform(_aktbankjegy)+' '+_aktdnem+' ('+ftform(_aktertek)+' Ft)');
  Kozepreir('Penz forrasa: '+_forras);
  Kozepreir('ERngedelyezo: '+_engedelyezo);
  if _kozszereplo=0 then kozepreir('nem kiemelt kozszereplo')
  else kozepreir('Az ugyfel kiemelt kozszereplo');
  soremeles;

  writeLn(_LFile,'A szolgaltato szervezet altal tett in-');
  kozepreir('tezkedesek');
  Kozepreir('Bejelentes az F.I.U. reszere');
  soremeles;

  kozepreir('ATVETELI ELISMERVENY');
  soremeles;

   writeLn(_LFile,'Az utobbi felev tranzakcioi:');
   _t := 1;
   while _t<=_tetel do
     begin
       _aktbizonylat := _xbi[_t];
       _aktdnem      := _xdn[_t];
       _aktertek     := _xft[_t];
       _aktbankjegy  := _xbj[_t];
       _aktdatum     := _xDa[_t];

       kozepreir(_aktdatum+' - '+_aktbizonylat);
       kozepreir(ftform(_aktbankjegy)+' '+_aktdnem+'  ('+ftform(_aktertek)+' Ft)');

       inc(_t);
     end;

   Soremeles;


  writeLn(_LFile,'Bejelento lap sorszama: '+inttostr(_sorszam)+'/'+leftstr(_megnyitottnap,4));
  writeln(_LFile,'Bejelento ptar: ' + _homekod +'. szamu penztar');
  kozepreir(_homenev);
  writeLn(_LFile,'Kiallitott pros: ' + _aktprosnev);
  writeln(_LFile,'Kiallitas kelte: ' + _megnyitottnap);
  soremeles;

  Writeln(_LFile,'Atadas-atvetel kelte: ...............');
  soremeles;

   writeLn(_LFile,'Atadas-atvetel kelte: .................');
   soremeles;

   writeLn(_LFile,'..................    .................');
   writelN(_LFile,'     atado                  atvevo');
   soremeles;
   soremeles;
   Closefile(_LFile);
end;

procedure TEGYEBBEALLITASFORM.NAPZARASGOMBClick(Sender: TObject);
begin
  Fopanel.Visible := false;
  _pcs := 'DELETE FROM QRPARAMS';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO QRPARAMS (NUMBER)' + _sorveg;
  _pcs := _pcs + 'VALUES (3)';
  ValutaParancs(_pcs);
  qrdisplayrutin;
  Menube;
end;


procedure TEGYEBBEALLITASFORM.NORMNYITASGOMBClick(Sender: TObject);
begin
  nYITOPANEL.VISIBLE := FALSE;

  _pcs := 'INSERT INTO QRPARAMS (NUMBER)' + _sorveg;
  _pcs := _pcs + 'VALUES (4)';
  ValutaParancs(_pcs);

  qrdisplayrutin;
  Menube;
end;

procedure TEGYEBBEALLITASFORM.NYITAS3GOMBClick(Sender: TObject);
begin
   nYITOPANEL.VISIBLE := FALSE;

  _pcs := 'INSERT INTO QRPARAMS (NUMBER)' + _sorveg;
  _pcs := _pcs + 'VALUES (0)';
  ValutaParancs(_pcs);

  qrdisplayrutin;
  Menube;

end;

// =============================================================================
     procedure TEGYEBBEALLITASFORM.ALLVALUTACLEARGOMBClick(Sender: TObject);
// =============================================================================

begin
  Fopanel.Visible := false;
  _pcs := 'DELETE FROM QRPARAMS';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO QRPARAMS (NUMBER)' + _sorveg;
  _pcs := _pcs + 'VALUES (1)';
  ValutaParancs(_pcs);
  qrdisplayrutin;

  Menube;
end;

// =============================================================================
    procedure TEGYEBBEALLITASFORM.ALLVALUTAINSTALLGOMBClick(Sender: TObject);
// =============================================================================

begin
  Fopanel.Visible := false;
  _pcs := 'DELETE FROM QRPARAMS';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO QRPARAMS (NUMBER)' + _sorveg;
  _pcs := _pcs + 'VALUES (2)';
  ValutaParancs(_pcs);
  qrdisplayrutin;
  Menube;
end;


procedure TEGYEBBEALLITASFORM.NAPNYITASGOMBClick(Sender: TObject);
begin
  Fopanel.Visible := false;
  _pcs := 'DELETE FROM QRPARAMS';
  ValutaParancs(_pcs);

  with NyitoPanel do
    begin
      top := 210;
      Left := 270;
      Visible := true;
      repaint;
    end;
  Activecontrol := NormNyitasGomb;
end;





procedure TEGYEBBEALLITASFORM.PROSBELEPGOMBClick(Sender: TObject);
begin
  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (OTPFUNCTYPE)' + _sorveg;
  _pcs := _pcs + 'VALUES (50)';
  ValutaParancs(_pcs);

  _otpoke := otpterminal;
  if _otpoke=1 then
    begin
      _pcs := 'UPDATE HARDWARE SET OTPOPEN=1';
      ValutaParancs(_pcs);
    end;
end;

procedure TEGYEBBEALLITASFORM.PROSKILEPGOMBClick(Sender: TObject);
begin
  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (OTPFUNCTYPE)' + _sorveg;
  _pcs := _pcs + 'VALUES (51)';
  ValutaParancs(_pcs);

  _otpoke := otpterminal;
  if _otpoke=1 then
    begin
      _pcs := 'UPDATE HARDWARE SET OTPOPEN=0';
      ValutaParancs(_pcs);
    end;


end;

procedure TEGYEBBEALLITASFORM.TERMZAROGOMBClick(Sender: TObject);
begin
  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (OTPFUNCTYPE)' + _sorveg;
  _pcs := _pcs + 'VALUES (60)';
  ValutaParancs(_pcs);

  _otpoke := otpterminal;
  if _otpoke=1 then
    begin
      _pcs := 'UPDATE HARDWARE SET OTPOPEN=0';
      ValutaParancs(_pcs);
    end;
end;

procedure TEGYEBBEALLITASFORM.BACKGOMBClick(Sender: TObject);
begin
  OtpPanel.Visible := False;
end;

procedure TEGYEBBEALLITASFORM.OTPGOMBClick(Sender: TObject);
begin
  with OTPPanel do
    begin
      Top     := 96;
      left    := 16;
      Visible := True;
      Repaint;
    end;
  Activecontrol := ProsBelepGomb;

end;

procedure TEGYEBBEALLITASFORM.FRISSITOGOMBClick(Sender: TObject);
begin
  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (OTPFUNCTYPE)' + _sorveg;
  _pcs := _pcs + 'VALUES (90)';
  ValutaParancs(_pcs);

  _otpoke := otpterminal;
end;


// =============================================================================
         procedure TEGYEBBEALLITASFORM.SPMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  NavPortPanel.Visible := False;
end;

// =============================================================================
           procedure TEGYEBBEALLITASFORM.SPFIXGOMBClick(Sender: TObject);
// =============================================================================

var _y: byte;

begin
  _y := 1;
  while _y<=4 do
    begin
      if _cm[_y].Checked then break;
      inc(_y);
    end;

  if _y<5 then
    begin
      _pcs := 'UPDATE HARDWARE SET NAVCOM=' + inttostr(_y);
      ValutaParancs(_pcs);
    end;
  NavPortPanel.Visible := False;
end;

procedure TEGYEBBEALLITASFORM.SETCOMPORTGOMBClick(Sender: TObject);

var _aktradioButton: TRadioButton;

begin
  Valutadbase.connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _navcom := FieldByName('NAVCOM').asInteger;
      Close;
    end;
  Valutadbase.close;

  if _navcom=0 then _navcom := 1;


  with NavPortPanel do
    begin
      top  := 50;
      left := 240;
      Visible := true;
      repaint;
    end;
  _aktRadioButton := _cm[_navcom];
  _aktradioButton.Checked := True;

end;

end.
