
unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,ExtCtrls, idglobal, Buttons, strutils, wininet,
  IBDatabase, DB, IBCustomDataSet, IBQuery, dateutils;

type

  TNAPIMENTES = class(TForm)

    Kilepo      : TTimer;
    Shape4      : TShape;
    BackupPanel : TPanel;
    Panel1      : TPanel;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;

    procedure ValutaFdbMentes;
    procedure FormActivate(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);

    function Nulele(_b: byte): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  NapiMentes: TNAPIMENTES;

  _top,_left,_width,_height: word;
  _aktev,_aktho,_aktnap: word;
  _valpath,_savepath,_mainap,_pcs: string;
  _sorveg: string = chr(13)+chr(10);


function sendokmanyrutin: integer; stdcall; external 'c:\valuta\bin\sendokmany.dll' name 'sendokmanyrutin';
function backuprestore: integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
              function backuprestore: integer; stdcall;
// =============================================================================

begin
  Napimentes := TNapimentes.create(Nil);
  result := Napimentes.Showmodal;
  Napimentes.Free;
end;

// =============================================================================
             procedure TNAPIMENTES.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width := Screen.Monitors[0].Width;

  _top := trunc((_height-384)/2);
  _left := trunc((_width-512)/2);

  Top      := _top;
  Left     := _left;
  Width    := 505;
  Height   := 350;

  _aktev := yearof(date);
  _aktho := monthof(date);
  _aktnap:= dayof(Date);

  _mainap := inttostr(_aktev)+'.'+nulele(_aktho)+'.'+nulele(_aktnap);


  Kilepo.Enabled:= False;
  BackupPanel.repaint;

  valutafdbMentes;
  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (DATUM,NEVTABLA)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _MAINAP +chr(39) + ',';
  _pcs := _pcs + chr(39) + 'NAPI' + chr(39) + ')';
  ValutaParancs(_pcs);

  sendokmanyrutin;

  Kilepo.Enabled := True;
end;


// =============================================================================
             procedure TNapiMentes.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  Valutadbase.connected := true;
  if valutatranz.InTransaction then valutatranz.Commit;
  ValutaTranz.StartTransaction;
  with valutaquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Valutatranz.commit;
  Valutadbase.close;
end;

// =============================================================================
                procedure TNAPIMENTES.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  ModalResult := 1;
end;


// =============================================================================
                   procedure TnapiMentes.ValutaFdbMentes;
// =============================================================================

begin
  _valpath  := 'c:\valuta\database\valuta.fdb';
  _savePath := 'c:\valuta\mentes\lastgood\valuta.fdb';

  if fileExists(_savePath) then sysutils.DeleteFile(_savepath);
  copyfileto(_valpath,_savepath);
end;

// =============================================================================
             function TNapiMentes.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

end.

