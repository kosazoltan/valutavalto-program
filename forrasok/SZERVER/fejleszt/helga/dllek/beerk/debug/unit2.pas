unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, DB, DBTables, idGlobal, StrUtils, Buttons,
  jpeg, IBDatabase, IBCustomDataSet, IBQuery;

type
  TATTEKINTES = class(TForm)
    ALAPPANEL: TPanel;
    Label1: TLabel;
    Shape1: TShape;
    Image1: TImage;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    IDOSZAKPANEL: TPanel;
    kilepo: TTimer;


    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure kilepoTimer(Sender: TObject);
    procedure adatSzolgaltato;

    function Adatdisplay: integer;
    function EgyidoszakAdatai: boolean;



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ATTEKINTES: TATTEKINTES;
  _aktUzletszam,_CBSORS,_displaytype,_mResult,_aktegyseg,_dispback,_back: integer;
  _dpb: integer;
  _quit: boolean;
  _tolstring,_igstring,_filter,_aktbetu,_pcs: string;
  _sorveg: string = chr(13)+chr(10);
  _aktkorzss,_aktkorzet: byte;

  _betusor: array[1..4] of string = ('B','P','E','Z');
  _korzetsor: array[1..9] of byte = (10,20,40,50,63,75,120,145,180);


function keszletdisplayrutin: integer; stdcall; external 'c:\receptor\newdll\keszdisp.dll' name 'keszletdisplayrutin';
function forgalomdisplayrutin: integer; stdcall; external 'c:\receptor\newdll\forgdisp.dll' name 'forgalomdisplayrutin';
function wudisplayrutin: integer; stdcall; external 'c:\receptor\newdll\wudisp.dll' name 'wudisplayrutin';
function ptkforgdisplayrutin: integer; stdcall; external 'c:\receptor\newdll\ptkdisp.dll' name 'ptkforgdisplayrutin';
function bankiforgdisplayrutin: integer; stdcall; external 'c:\receptor\newdll\bankdisp.dll' name 'bankiforgdisplayrutin';
function trbforgdisplayrutin: integer; stdcall; external 'c:\receptor\newdll\trbdisp.dll' name 'trbforgdisplayrutin';
function stornodisplayrutin: integer; stdcall; external 'c:\receptor\newdll\stornodisp.dll' name 'stornodisplayrutin';
function getegysegkod: integer; stdcall; external 'c:\receptor\newdll\getegyseg.dll' name 'getegysegkod';
function getdisplaymenu: integer; stdcall; external 'c:\receptor\newdll\getdisp.dll' name 'getdisplaymenu';
function getidoszakrutin: integer; stdcall; external 'c:\receptor\newdll\idoszak.dll' name 'getidoszakrutin';
function adatlegyujtorutin: integer; stdcall; external 'c:\receptor\newdll\legyujto.dll' name 'adatlegyujtorutin';

function beerkezettadatok: integer; stdcall;


implementation

{$R *.dfm}


function beerkezettadatok: integer; stdcall;

begin
  attekintes := TAttekintes.Create(Nil);
  result := attekintes.showModal;
  Attekintes.free;
end;



// ===================================================================
           procedure TATTEKINTES.Button1Click(Sender: TObject);
// ===================================================================

begin
  Modalresult := 2;
end;

// =============================================================================
            procedure TATTEKINTES.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top := 158;
  Left := 208;

  // Idõszak:

  if not egyidoszakadatai then
    begin
      _mresult := -1;
      Kilepo.Enabled := True;
      exit;
    end;

  _aktegyseg := getegysegkod;
  if _aktegyseg=-1 then
    begin
      _mResult := -1;
      Kilepo.Enabled := True;
      exit;
    end;

  _displayType := getdisplaymenu;
  if _displaytype=-1 then
    begin
      _mResult := -1;
      Kilepo.Enabled := True;
      exit;
    end;

  // ----------------------------------------------------

  AdatSzolgaltato;
end;



{
// =============================================================================
                 procedure TAttekintes.SetDatabaseFilter;
// =============================================================================

var _aktbetusors: byte;

begin
  if (_aktegyseg<200) then _filter := '(IRODASZAM='+inttostr(_aktegyseg)+')';
  if (_aktegyseg=201) then _filter := '(ERTEKTAR=-1)';
  if (_aktegyseg>210) and (_aktegyseg<220) then
    begin
      _aktbetusors := _aktegyseg-210;
      _aktbetu := _betusor[_aktbetusors];
      _filter := '(ERTEKTAR=0) AND (IRODASZAM=0) AND (CEGBETU='+chr(39)+_aktbetu+chr(39)+')';
    end;

  if (_aktegyseg>220) and (_aktegyseg<230) then
    begin
      _aktkorzss := _aktegyseg-220;
      _aktkorzet := _korzetsor[_aktkorzss];
      _filter := '(IRODASZAM=0) AND (ERTEKTAR='+inttostr(_aktkorzet)+')';
    end;

  _pcs := 'DELETE FROM ADATATADO';
  ReceptParancs(_pcs);

  _pcs := 'INSERT INTO ADATATADO (SZURO)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39)+ _filter + chr(39)+')';
  Receptparancs(_pcs);
end;

}

procedure TAttekintes.Adatszolgaltato;
begin
  while True do
    begin
      _dpb := Adatdisplay;
      if _dpb=-1 then break;

      if _dpb=1 then
        begin
          _displaytype := getdisplaymenu;
          if _displaytype=-1 then break;
          continue;
        end;

      if _dpb=2 then
        begin
          _aktegyseg := getegysegkod;
          if _aktegyseg=-1 then break;
          continue;
        end;

      if _dpb=3 then if not egyidoszakadatai then break;

    end;
  _mResult := 1;
  Kilepo.enabled := true;

end;



// =============================================================================
              function TAttekintes.Adatdisplay: integer;
// =============================================================================

begin
  case _displayType of
    1: _back := forgalomdisplayrutin;
    2: _back := keszletdisplayrutin;
    3: _back := wudisplayrutin;
    4: _back := ptkforgdisplayrutin;
    5: _back := bankiforgdisplayrutin;
    6: _back := trbforgdisplayrutin;
    7: _back := stornodisplayrutin;
  end;
  result := _back;
end;


{
procedure TAttekintes.ReceptParancs(_ukaz: string);

begin
  recdbase.connected := true;
  if rectranz.intransaction then rectranz.commit;
  Rectranz.startTransaction;
  with RecQuery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  Rectranz.commit;
  Recdbase.close;
end;



//  AdatLegyujtes.ShowModal;
{
//  _kellexcel := False;
  while True do
    begin
//      _aktUzletszam := Getuzletszam.Showmodal;
      if _aktUzletszam<0 then
        begin
          // -1=best, -2=pannon, -3=east  -4=ZALOG
          _cbsors := abs(_aktuzletszam);
          dec(_cbsors);
 //         if _cbSors<3 then _displayFocim := _subdir[_cbsors]+' CHANGE ADATAI'
 //         else _displayfocim := 'EXPRESSZ ÉKSZERHÁZ ADATAI';
          _displaytipus := 4;
        end;

      _aktUzletszam := _aktuzletszam-3;
      if _aktuzletszam=-2 then
        begin
          ModalResult := 1;
          break;
        end;

      if _aktuzletszam=-1 then
        begin
          _displayFocim := 'EXCLUSIVE CHANGE ÖSSZESÍTETT ADATAI';
          _displaytipus := 1;
        end;
      if _aktuzletszam=0 then
        begin
          _displayTipus := 2;
          _displayFocim := _aktkorzetnev + ' régió adatai';

        end;
      if _aktuzletszam>0 then
        begin
          _displayFocim := _aktPenztarNev + ' pénztár adatai';
          _displayTipus := 3;
        end;
      Displayselect;
    end;

  ModalResult := 1;


end;

// ===================================================
        procedure Tattekintes.Displayselect;
// ===================================================




begin
  EXIT;
  {
  while true do
    begin

      _delem := Adatmenu.ShowModal;
      case _delem of

        1: ForgalomDisplay.ShowModal;
        2: KeszletDisplay.ShowModal;
        3: Wunidisplay.ShowModal;
        4: PenztarKozottiDisplay.ShowModal;
        5: BankForgalomdisplay.ShowModal;
        6: TrbDisplay.Showmodal;
        7: StornoDisp.ShowModal;
        8: Break;

       end;
    end;
  

end;

}

function TAttekintes.EgyidoszakAdatai: boolean;

begin
  Result := false;
  if getidoszakrutin<>1 then exit;

  Recdbase.Connected := true;
  with RecQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM IDOSZAK');
      Open;
      _tolstring := FieldByNAme('STARTDATE').asString;
      _igString  := FieldByName('ENDDATE').asString;
      Close;
    end;
  RecDbase.close;

  idoszakpanel.caption := _tolstring+' - '+_igstring+' között';
  Idoszakpanel.repaint;

  adatlegyujtorutin;
  resuLT := True;
end;


procedure TATTEKINTES.kilepoTimer(Sender: TObject);
begin
  Kilepo.Enabled := False;
  Modalresult := _mResult;
end;

end.
