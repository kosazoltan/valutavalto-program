unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Grids, DBGrids, ComCtrls, StdCtrls, IBDatabase,
  DB, IBCustomDataSet, IBQuery, StrUtils, IBTable, Buttons, jpeg;

type
  TMNBLISTAK = class(TForm)
    ReceptorQuery: TIBQuery;
    Receptordbase: TIBDatabase;
    ReceptorTranz: TIBTransaction;

    ALAPPANEL: TPanel;
    Label1: TLabel;
    ReceptorQueryFILTER: TIBStringField;
    ReceptorQueryPENZTARSZAM: TSmallintField;
    Image1: TImage;
    gombtartopanel: TPanel;
    MASIDOSZAKGOMB: TBitBtn;
    MASEGYSEGGOMB: TBitBtn;
    VISSZAGOMB: TBitBtn;
    Shape1: TShape;

    procedure FormActivate(Sender: TObject);
    procedure ReceptParancs(_ukaz: string);
    procedure VISSZAGOMBClick(Sender: TObject);
    procedure MASIDOSZAKGOMBClick(Sender: TObject);
    procedure MASEGYSEGGOMBClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MNBLISTAK: TMNBLISTAK;

  _dispres,_tipus,_korzet,_ddback: integer;
  _filter,_cb: string;

  _cegbetusor: array[1..4] of string =('B','P','E','Z');
  _korzetsor : array[1..9] of byte =(10,20,40,50,63,75,120,145,180);

  _listakod : integer;
  _aktcegbetu: string;
  _korzetss,_korzetszam,_iroda: byte;

  _pcs : string;
  _sorveg: string = chr(13)+chr(10);


  _IRAS: TEXTFILE;
  _kornev,_csvPath,_mondat,_status: string;
  _irsz: integer;
  _bankiatadas,_ptarikiadas,_ptariatvet: integer;
  _vplusz,_vminusz,_vetelforg,_eladforg,_forgegy,_bankegy: integer;
  _osszbevet,_sumatvet,_osszkiadas: integer;
  _vanIdoszak,_gyujtesOke,_aktuzletszam,_aktuz: integer;
  _kellexcel: boolean;


function getidoszakrutin: integer; stdcall; external 'c:\receptor\newdll\idoszak.dll' name 'getidoszakrutin';
function adatlegyujtorutin: integer; stdcall; external 'c:\receptor\newdll\gyujto.dll' name 'adatlegyujtorutin';
function getegysegkod: integer; stdcall; external 'c:\receptor\newdll\getegyseg.dll' name 'getegysegkod';
function datadisplay: integer; stdcall; external 'c:\receptor\newdll\datadisp.dll' name 'datadisplay';


function mnblistarutin: integer; stdcall;

implementation

// uses Unit9, Unit14, Unit17, Unit18;

{$R *.dfm}

function mnblistarutin: integer; stdcall;
begin
  MNBListak := TMNBListak.Create(Nil);
  result := MNBListak.Showmodal;
  MNBListak.free;
end;  


// =============================================================================
             procedure TMNBLISTAK.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top    := 158;
  Left   := 208;
  Height := 684;
  width  := 864;

  with AlapPanel do
    begin
      top := 0;
      Left := 0;
      Visible := true;
      repaint;
    end;

 _vanidoszak := getidoszakrutin;
 if _vanidoszak=-1 then
   begin
     GombtartoPanel.Visible := True;
     exit;
   end;

 // FOPANEL.Visible := True;

  _gyujtesoke := adatlegyujtorutin;
  if _gyujtesOke=-1 then
    begin
      ShowMessage('NINCS ADAT A KÉRT IDÕSZAKBAN !');
      Gombtartopanel.Visible := true;
      Exit;
    end;

  _listakod := getegysegkod;
  if _listakod=-1 then
    begin
      GombtartoPanel.Visible := true;
      Exit;
    end;

  _ddback := datadisplay;
  if _ddBack = 1 then
    begin
      Masegyseggombclick(Nil);
      exit;
    end;
  if _ddback = 2 then
    begin
      MasidoszakGombClick(Nil);
      exit;
    end;

  GombtartoPanel.Visible := true;
end;

// =============================================================================
            procedure TMNBListak.ReceptParancs(_ukaz: string);
// =============================================================================

begin
  receptordbase.connected := true;
  if receptorTranz.InTransaction then receptorTranz.Commit;
  Receptortranz.StartTransaction;
  with ReceptorQuery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  ReceptorTranz.commit;
  Receptordbase.close;
end;


// =============================================================================
          procedure TMNBLISTAK.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
         procedure TMNBListak.MasIdoszakGombClick(Sender: TObject);
// =============================================================================

begin
  GombTartoPanel.Visible := False;
  _vanidoszak := getidoszakrutin;
  if _vanidoszak=-1 then
    begin
      GombTartoPanel.Visible := True;
      exit;
    end;

  _gyujtesOke := adatlegyujtorutin;
  if _gyujtesOke=-1 then
    begin
      ShowMessage('NINCS ADAT A KÉRT IDÕSZAKBAN !');
      GombtartoPanel.Visible := true;
      Exit;
    end;

  _listakod := getegysegkod;
  if _listaKod=-1 then exit;


  _ddback := datadisplay;

  if _ddBack = 1 then
    begin
      Masegyseggombclick(Nil);
      exit;
    end;

  if _ddback = 2 then
    begin
      MasidoszakGombClick(Nil);
      exit;
    end;
  GombTartoPanel.visible := True;
end;

// =============================================================================
           procedure TMNBLISTAK.MASEGYSEGGOMBClick(Sender: TObject);
// =============================================================================

begin
  GombTartoPanel.Visible := False;
  _listakod := getegysegkod;
  if _listakod=-1 then
    begin
      GombtartoPanel.Visible := true;
      Exit;
    end;


  _ddback := datadisplay;
  if _ddBack = 1 then
    begin
      Masegyseggombclick(Nil);
      exit;
    end;

  if _ddback = 2 then
    begin
      MasidoszakGombClick(Nil);
      exit;
    end;

  GombtartoPanel.Visible := True;;
end;

end.




