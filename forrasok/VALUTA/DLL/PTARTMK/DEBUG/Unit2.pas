unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Grids, DBGrids, DB, Unit1, ExtCtrls, DBTables,
  IBCustomDataSet, IBQuery, IBDatabase, IBTable, strutils;

type
  TPENZTARTMKFORM = class(TForm)

    PenztarSource: TDataSource;
      PenztarRacs: TDBGrid;

    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;

    PenztarCimEdit: TEdit;
    PenztarNevEdit: TEdit;
   PenztarSzamEdit: TEdit;
       TelefonEdit: TEdit;

       RendbenGomb: TBitBtn;
    megsemgomb: TBitBtn;
        EscapeGomb: TBitBtn;
      ModositoGomb: TBitBtn;
 PenztarTorlesGomb: TBitBtn;
     UjPenztarGomb: TBitBtn;
    TMKPANEL: TPanel;
    inditotimer: TTimer;
    PENZTARTRANZ: TIBTransaction;
    PENZTARDBASE: TIBDatabase;
    PENZTARQUERY: TIBQuery;
    Shape1: TShape;
    Shape2: TShape;
    VALQUERY: TIBQuery;
    VALDBASE: TIBDatabase;
    VALTRANZ: TIBTransaction;
    SURETORLESPANEL: TPanel;
    Label8: TLabel;
    DELPENZTARNEVPANEL: TPanel;
    TOROLIGENGOMB: TBitBtn;
    TOROLNEMGOMB: TBitBtn;
    Shape3: TShape;

    procedure AdatFeliras;
    procedure Adatbeolvasas;
    procedure PenztarModositas(Sender: TObject);
    procedure MegsemgombClick(Sender: TObject);
    procedure EscapeGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure PenztarszamEditEnter(Sender: TObject);
    procedure PenztarszamEditExit(Sender: TObject);
    procedure PenztarszamEditKeyDow(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure PenztarTorlesGombClick(Sender: TObject);
    procedure RendbenGombClick(Sender: TObject);
    procedure TorolNemGombClick(Sender: TObject);
    procedure TorolIgenGombClick(Sender: TObject);
    procedure UjpenztarGombClick(Sender: TObject);
    procedure inditotimerTimer(Sender: TObject);
    procedure PenztarNevEditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure PenztarCimEditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure TelefonEditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure ValutaParancs(_ukaz: string);
    procedure PenztarNyitas;
    procedure PenztarModify;

    function Vanilyenszam(_nums: string): boolean;
    procedure PENZTARRACSDblClick(Sender: TObject);
    procedure PENZTARRACSKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PenztarTMKForm: TPenztarTmkForm;

  _penztarkod,_penztarnev,_penztarcim,_telefonszam,_pcs,_akcio: string;
  _sorveg: string = chr(13)+chr(10);

  _top,_left,_height,_width,_cc: word;
  _recno : integer;
  _valtoztatas: boolean;

function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';
function penztartmkrutin: integer; stdcall;

implementation


{$R *.dfm}

// =============================================================================
                    function penztartmkrutin: integer; stdcall;
// =============================================================================

begin
  PenztarTMKForm := TPenztarTMKForm.Create(Nil);
  result := PenztartmkForm.Showmodal;
  PenztarTmkForm.Free;
end;


// =============================================================================
        procedure TPENZTARTMKFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top  := 0;
  _left := 0;
  _top  := trunc((_height-459)/2);
  _left := trunc((_width-811)/2);

  Top    := _top;
  Left   := _left;
  Height := 423;
  Width  := 798;

  TmkPanel.Visible        := False;
  SureTorlesPanel.Visible := False;

  _valtoztatas := False;
  InditoTimer.Enabled := true;
end;

// =============================================================================
       procedure TPenztarTMKForm.InditoTimerTimer(Sender: TObject);
// =============================================================================

begin
  InditoTimer.Enabled := False;
  PenztarNyitas;
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
           procedure TPenztarTmkForm.PenztarModositas(Sender: TObject);
// =============================================================================


var _spw,_rekord: integer;

begin
  _rekord := PenztarQuery.Recno;
  if _rekord=1 then
    begin
      _spw := supervisorjelszo(0);
      if _spw<>1 then
        begin
          ShowMessage('SAJÁT PÉNZTÁRAT CSAK SUPERVISOR MÓDOSITHAT');
          Exit;
        end;
    end;
  PenztarModify;
end;

// =============================================================================
              procedure TpenztarTMKForm.PenztarModify;
// =============================================================================

begin

  _akcio := 'M';
  AdatBeolvasas;

  Penztarszamedit.text     := _penztarKod;
  Penztarszamedit.Enabled  := False;
  Penztarszamedit.ReadOnly := True;

  Penztarnevedit.text      := _penztarNev;
  Penztarcimedit.Text      := _penztarCim;
  Telefonedit.Text         := _telefonszam;

  Penztarnevedit.Repaint;
  Penztarcimedit.Repaint;
  Telefonedit.repaint;

  with TmkPanel do
    begin
      Top     := 100;
      Left    := 50;
      Visible := True;
    end;

 _valtoztatas  := True;
end;

// =============================================================================
       procedure TPENZTARTMKFORM.PENZTARNEVEDITKeyDown(Sender: TObject;
                                            var Key: Word; Shift: TShiftState);
// =============================================================================


var _ujpenztarnev: string;

begin
  if ord(key)<>13 then exit;

  _ujpenztarnev := trim(PenztarNevedit.text);
  if _ujpenztarNev = '' then exit;

  if _ujpenztarnev<>_penztarnev then
    begin
      _penztarNev  := _ujpenztarNev;
      _valtoztatas := True;
    end;

  ActiveControl := Penztarcimedit;
end;


// =============================================================================
     procedure TPENZTARTMKFORM.PENZTARCIMEDITKeyDown(Sender: TObject;
                                           var Key: Word; Shift: TShiftState);
// =============================================================================

var _ujpenztarcim : string;

begin
  if ord(key)<>13 then exit;

  _ujpenztarCim := trim(PenztarCimedit.text);
  if _ujpenztarCim = '' then exit;

  if _ujpenztarcim<>_penztarcim  then
    begin
      _penztarcim  := _ujpenztarcim;
      _valtoztatas := True;
    end;

  ActiveControl := TelefonEdit;
end;

// =============================================================================
       procedure TPenztarTMKForm.TelefonEditKeyDown(Sender: TObject;
                                             var Key: Word; Shift: TShiftState);
// =============================================================================

var _ujtelefon: string;

begin
  if ord(key)<>13 then exit;

  _ujTelefon := trim(Telefonedit.text);
  if _ujTelefon = '' then exit;

  if _ujtelefon<>_telefonszam then
    begin
      _telefonszam := _ujtelefon;
      _valtoztatas := True;
    end;
  ActiveControl := RendbenGomb;
end;


// =============================================================================
           procedure TPenztarTMKForm.RENDBENGOMBClick(Sender: TObject);
// =============================================================================

begin
  PenztarQuery.close;
  Penztardbase.close;

  if _valtoztatas then Adatfeliras;

  TmkPanel.Visible := False;
  PenztarNyitas;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
          procedure TPENZTARTMKFORM.UJPENZTARGOMBClick(Sender: TObject);
// =============================================================================

var _spk: integer;

begin
  penztarQuery.close;
  PenztarDbase.Close;

  _spk := supervisorjelszo(0);
  if _spk<>1 then
    begin
      ShowMessage('ÚJ PÉNZTÁRAT CSAK SUPERVISOR VEHET FEL');
      Penztarnyitas;
      Exit;
    end;

  _akcio := 'U';

  Penztarszamedit.ReadOnly := false;
  Penztarszamedit.Clear;
  PenztarNevedit.Clear;
  Penztarcimedit.Clear;
  Telefonedit.Clear;

  with TmkPanel do
    begin
      Top     := 100;
      Left    := 50;
      visible := True;
    end;

  PenztarSzamedit.Enabled := True;
  ActiveControl := Penztarszamedit;
end;

// =============================================================================
     procedure TPENZTARTMKFORM.PenztarszamEditKeyDow(Sender: TObject;
                                           var Key: Word; Shift: TShiftState);
// =============================================================================

var _bill: byte;
    _ujpenztarszam: string;

begin
  _bill := ord(key);
  if _bill<> 13 then exit;

  _ujpenztarszam := trim(Penztarszamedit.text);
  if _ujpenztarszam='' then exit;

  if Vanilyenszam(_ujpenztarszam) then
    begin
      ShowMessage('Ez a pénztárszám már létezik !');
      exit;
    end;

  _penztarkod := _ujpenztarszam;
  ActiveControl := PenztarNevedit;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
        procedure TPENZTARTMKFORM.PENZTARTORLESGOMBClick(Sender: TObject);
// =============================================================================


var _spk,_rekord: integer;


begin
  _rekord := PenztarQuery.Recno;
  if _rekord=1 then
    begin
      ShowMessage('SAJÁT PÉNZTÁR NEM TÖRÖLHETÖ !');
      SureTorlesPanel.Visible := False;
      ActiveControl := PenztarRacs;
      PenztarRacs.SetFocus;
      Exit;
    end;

  _spk := supervisorjelszo(0);

  if _spk<>1 then
    begin
      ShowMessage('PÉNZTÁRAT CSAK SUPERVISOR TÖRÖLHET ');
      Exit;
    end;

  Adatbeolvasas;

  Delpenztarnevpanel.caption := _penztarnev;
  with suretorlesPanel do
    begin
      Top := 210;
      Left := 200;
      Visible := True;
    end;
  ActiveControl := TorolNemgomb;
end;

// =============================================================================
           procedure TPENZTARTMKFORM.megsemgombClick(Sender: TObject);
// =============================================================================

begin
  TmkPanel.Visible := False;
  PenztarNyitas;
end;

// =============================================================================
         procedure TPENZTARTMKFORM.TOROLNEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  SureTorlesPanel.Visible := False;
  PenztarNyitas;
end;

// =============================================================================
         procedure TPENZTARTMKFORM.TOROLIGENGOMBClick(Sender: TObject);
// =============================================================================

begin

  _pcs := 'DELETE FROM PENZTAR WHERE PENZTARKOD='+chr(39)+_penztarKod+chr(39);
  ValutaParancs(_pcs);

  SureTorlesPanel.Visible := False;
  Penztarnyitas;
end;


// =============================================================================
          procedure TPENZTARTMKFORM.ESCAPEGOMBClick(Sender: TObject);
// =============================================================================

begin
  PenztarQuery.Close;
  PenztarDbase.Close;
  ModalResult := 2;
end;


// =============================================================================
                 procedure TPenztarTMKForm.PenztarNyitas;
// =============================================================================

begin
  Penztarquery.close;
  Penztardbase.close;

  _pcs := 'SELECT * FROM PENZTAR';
  PenztarDbase.connected := true;
  with Penztarquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;
  PenztarRacs.SelectedIndex := 0;
  ActiveControl := PenztarRacs;
end;


// =============================================================================
                  procedure TPenztarTMKForm.Adatfeliras;
// =============================================================================

begin
  if not _valtoztatas then exit;

  if _akcio='U' then
    begin
      _pcs := 'INSERT INTO PENZTAR (PENZTARKOD,PENZTARNEV,PENZTARCIM,TELEFONSZAM)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _penztarkod + chr(39) + ',';
      _pcs := _pcs + chr(39) + _penztarnev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _penztarcim + chr(39) + ',';
      _pcs := _pcs + chr(39) + _telefonszam + chr(39) + ')';
    end else
    begin
      _pcs := 'UPDATE PENZTAR SET PENZTARNEV=' + chr(39) + _penztarnev + chr(39)+',';
      _pcs := _pcs + 'PENZTARCIM=' + chr(39) + _penztarcim + chr(39) + ',';
      _pcs := _pcs + 'TELEFONSZAM=' + chr(39) + _telefonszam + chr(39) + _sorveg;
      _pcs := _pcs + 'WHERE PENZTARKOD=' + chr(39) + _penztarkod + chr(39);
    end;
  ValutaParancs(_pcs);
end;


procedure TPenztarTmkForm.ValutaParancs(_ukaz: string);

begin
  Valdbase.connected := true;
  if Valtranz.InTransaction then valtranz.Commit;
  Valtranz.StartTransaction;
  with ValQuery do
    begin
      close;
      sql.Clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Valtranz.commit;
  Valdbase.close;
end;

procedure TPenztarTMKForm.Adatbeolvasas;

begin
  with PenztarQuery do
    begin
      _penztarkod := trim(FieldByName('PENZTARKOD').asString);
      _penztarnev := trim(FieldByName('PENZTARNEV').asString);
      _penztarcim := trim(FieldByName('PENZTARCIM').asString);
      _telefonszam:= trim(FieldByName('TELEFONSZAM').asString);
    end;
end;


// =============================================================================
    procedure TPenztarTMKForm.PenztarSzamEditEnter(Sender: TObject);
// =============================================================================

begin
 Tedit(sender).Color := clYellow;
 Tedit(sender).clear;
end;

// =============================================================================
         procedure TPENZTARTMKFORM.PENZTARSZAMEDITExit(Sender: TObject);
// =============================================================================

begin
  TEdit(Sender).Color := clWindow;
end;


function TPenztarTmkForm.Vanilyenszam(_nums: string): boolean;

begin
  Result := False;
  if _nums='' then exit;

  _pcs := 'SELECT * FROM PENZTAR WHERE PENZTARKOD='+chr(39)+_nums+chr(39);

  ValDbase.connected := true;
  with ValQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
      Close;
    end;
  ValDbase.close;
  if _recno>0 then result := true;
end;




procedure TPENZTARTMKFORM.PENZTARRACSDblClick(Sender: TObject);
begin
  PenztarModify;
end;

procedure TPENZTARTMKFORM.PENZTARRACSKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  PenztarModify;
end;

end.
