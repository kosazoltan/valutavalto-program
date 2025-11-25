unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, DB, DBTables,StrUtils,Printers,
  IBDatabase, IBCustomDataSet, IBTable, IBQuery, dateutils;

type
  TQUITFORM = class(TForm)

    QuitPanel: TPanel;

       Label1: TLabel;

  NonQuitGomb: TBitBtn;
     QuitGomb: TBitBtn;

    QuitTimer: TTimer;
    VALTABLA: TIBTable;
    VALDBASE: TIBDatabase;
    VALTRANZ: TIBTransaction;
    VALQUERY: TIBQuery;
    KERDOPANEL: TPanel;
    Label2: TLabel;
    NYITVAGOMB: TBitBtn;
    ZARVAGOMB: TBitBtn;
    Shape1: TShape;
    Shape2: TShape;
    Panel1: TPanel;

    procedure FormActivate(Sender: TObject);
    procedure NyilatkozatNyomtato;
    function EzSzombat(_ds: string): boolean;
    procedure NyitvaVagy;
    procedure NONQUITGOMBClick(Sender: TObject);
    procedure QUITGOMBClick(Sender: TObject);
    procedure SetPara;

    procedure QUITTIMERTimer(Sender: TObject);

    procedure NYITVAGOMBClick(Sender: TObject);
    procedure ZARVAGOMBClick(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);

    function Ezpentek(_ds: string): boolean;
    procedure KozepreIr(_s: string);
    function StrtoHunDate(_s: string): TDateTime;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  QUITFORM: TQUITFORM;
  _ezSaturday: boolean;
  _top,_left,_height,_width: word;
  _lezartnap,_mondat,_aktpenztarosnev,_homepenztarkod,_kftnev: string;
  _cegnev,_pcs: string;
  _code: integer;
  _homepenztarszam: byte;
  _saturday,_printer: byte;
  _LFile,_nyomtat,_olvas: textfile;
  _sorveg: string = chr(13)+chr(10);
   _LF5: string  = #27#97#5;   // 5 sor emelés

function quitrutin: integer; stdcall;
function backuprestore(_para: integer):integer;stdcall;external 'c:\valuta\bin\mentes.dll' name 'backuprestore';

implementation

{$R *.dfm}

function quitrutin: integer; stdcall;
begin
  Quitform := TQuitForm.Create(Nil);
  result := Quitform.showmodal;
  Quitform.Free;
end;





// =============================================================================
              procedure TQUITFORM.FormActivate(Sender: TObject);
// =============================================================================


begin
  QuitPanel.visible := False;
  KerdoPanel.Visible := False;

  _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].width;

  _top := trunc((_height-768)/2);
  _left := trunc((_width-1024)/2);

  Height := 100;
  Width  := 423;
  Top    := _top  + 418;
  Left   := _Left + 310;

  ValDbase.Connected := true;
  with ValQuery do
     begin
       Close;
       Sql.Clear;
       Sql.Add('SELECT * FROM HARDWARE');
       Open;
       _lezartnap := trim(FieldByName('LEZARTNAP').asString);
       _aktpenztarosnev := trim(FieldByNAme('PENZTAROSNEV').asString);
       _kftnev := trim(FieldbyNAme('KFTNEV').AsString);
       _printer := FieldByNAme('PRINTER').asInteger;
       _saturday := FieldByNAme('SATURDAY').asInteger;
       Close;
       Sql.Clear;
       Sql.Add('SELECT * FROM PENZTAR');
       Open;
       _homepenztarKOD := trim(FieldByName('PENZTARKOD').AsString);
       Close;
     end;

  ValDbase.close;




  val(_homepenztarkod,_homepenztarszam,_code);

  if _homepenztarszam<151 then
    begin
      _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';
    end else
    begin
      _cegnev := 'EXPRESSZ EKSZERHAZ ES MINIBANK KFT';
    end;

  // ---------------------------------------------------------------------------

  Setpara;

  if trim(_lezartnap)<>'' then    // tehát a nap már zárva van
    begin
      if EzPentek(_lezartnap) then
        begin
          Nyitvavagy;
          exit;
        end;

      if Ezszombat(_lezartnap) then
        begin
          Nyitvavagy;
          exit;
        end;

      SetPara;
      backuprestore(0);
      QuitTimer.Enabled := True;
      Exit;
    end;

  with QuitPanel do
    begin
      Top := 0;
      Left := 0;
      Visible := True;
    end;
  ActiveControl := QuitGomb;
end;


procedure TQuitform.ValutaParancs(_ukaz: string);

begin
  Valdbase.Connected := true;
  if valtranz.InTransaction then valtranz.commit;
  valtranz.StartTransaction;
  with valquery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Valtranz.Commit;
  valdbase.close;

end;

// =============================================================================
                      procedure TQuitForm.Nyitvavagy;
// =============================================================================

begin
  with KerdoPanel do
    begin
      Top  := 0;
      Left := 0;
      Visible := true;
    end;
  ActiveControl := NyitvaGomb;
end;


// =============================================================================
              procedure TQUITFORM.NONQUITGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 2;
end;

// =============================================================================
              procedure TQUITFORM.QUITGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;


// =============================================================================
             procedure TQUITFORM.QUITTIMERTimer(Sender: TObject);
// =============================================================================

begin
  QuitTimer.Enabled := False;
  ModalResult := 1;
end;


// =============================================================================
            function TQuitForm.Ezpentek(_ds: string): boolean;
// =============================================================================

var _hnap: word;
    _manap: TDateTime;


begin
  result := False;
  if _saturday=0 then exit;

  _manap := strtoHundate(_DS);
  _hnap  := dayoftheweek(_manap);

  if _hnap=5 then
    begin
      result := True;
      exit;
    end;
end;




// =============================================================================
               function TQuitform.EzSzombat(_DS: STRING): boolean;
// =============================================================================

var _hnap: word;
    _manap: TDateTime;
    _honaps: string;

begin
  result := False;

  _manap := strtoHundate(_DS);
  _hnap  := dayoftheweek(_manap);

  if _hnap=6 then
    begin
      result := True;
      exit;
    end;
  _honaps := midstr(_DS,6,5);

  if (_honaps='12.23') or (_honaps='12.31') or (_honaps='03.14') then result := true;
  if (_honaps='04.30') or (_honaps='08.19') or (_honaps='10.22') then result := True;
  if (_honaps='10.30') then result := true;

end;

// =============================================================================
                  procedure TQuitForm.NyilatkozatNyomtato;
// =============================================================================

begin
  Assignfile(_LFile,'c:\valuta\aktlst.txt');
  rewrite(_LFile);

  kozepreir('N Y I L A T K O Z A T');
  writeln(_LFile,'  ');

  _mondat := 'Alulirott ' + trim(_aktpenztarosnev);
  KozepreIr(_mondat);
  _mondat := 'az ' + _cegnev;
  KozepreIr(_mondat);
  WriteLn(_LFile,_homePenztarkod+'. szamu  penztaranak  dolgozoja  ki-');
  writeLn(_Lfile,'jelentem,  hogy a ' + _lezartnap + ' napi zaro-');
  writeLn(_LFile,'szalagon szereplo osszegek a valosagnak');
  writeLn(_lFile,'megfelelnek  es a  penztar  trezorjaban');
  writeLn(_Lfile,'elzarasra kerultek, es ezt alairasommal');
  KozepreIr('elismerem');
  writeLn(_LFile,'  ');
  writeLn(_LFile,'Ezen  nyilatkozat az unnepi / vasarnapi');
  Kozepreir('zarvatartas miatt keszult.');
  writeLn(_LFile,_sorveg);
  writeLn(_LFile,'Datum: '+_lezartnap);
  writeLn(_Lfile,_sorveg);
  writeLn(_lfile,'.......................................');
  writeLn(_lFile,'                 penztaros');
  writeLn(_LFile,_sorveg+_sorveg+_sorveg);
 
  Writeln(_LFile,_LF5);
  WriteLn(_LFile,chr(26));
  CloseFile(_LFile);

  if _printer<>1 then AssignFile(_nyomtat,'LPT1')
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





procedure TQuitForm.KozepreIr(_s: string);

var _w,_oo: byte;

begin
  _s := trim(_s);
  _w := length(_s);
  if _w=0 then
    begin
      writeLn(_LFile,' ');
      exit;
    end;

  if _w>39 then
    begin
      _w := 39;
      _s := leftstr(_s,39);
    end;

  if _w<39 then
    begin
      _oo := trunc((39-_w)/2);
      _s := dupestring(' ',_oo) + _s;
    end;
  writeLn(_LFile,_s);
end;







{

             NYILATKOZAT

123456789012345678901234567890123456789
Alulirott XXXXXXXXXXXX XXXXXXXXXXXXXXXX    (KÖZÉPRE)
az             (középre)
123. szamu  penztaranak  dolgozoja  ki-
jelentem,  hogy a 2015.11.11 napi zaro-
szalagon szereplo osszegek a valosagnak
megfelelnek  es a  penztar  trezorjaban
elzarasra kerultek, es ezt alairasommal
             elismerem.

Ezen  nyilatkozat az ünnepi / vasárnapi
zárvatartás miatt készült.


Nyíregyháza, 2015.01.10


.......................................
                 pénztáros


}

// =============================================================================
               procedure TQUITFORM.NYITVAGOMBClick(Sender: TObject);
// =============================================================================

begin
  SetPara;
  backuprestore(0);
  Modalresult := 1;
end;

// =============================================================================
             procedure TQUITFORM.ZARVAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Nyilatkozatnyomtato;
  backuprestore(0);
  Modalresult := 1;
end;


function TQuitForm.StrtoHunDate(_s: string): TDateTime;


var _evs,_hos,_naps: string;
    _aev,_aho,_anap: word;
    _code: integer;

begin
  result := date;
  _evs := leftstr(_s,4);
  _hos := midstr(_s,6,2);
  _naps:= midstr(_s,9,2);

  val(_evs,_aev,_code);
  if _code<>0 then exit;

  val(_hos,_aho,_code);
  if _code<>0 then exit;

  val(_naps,_anap,_code);
  if _code<>0 then exit;

  result := encodedate(_aev,_aho,_anap);
end;

procedure TQuitform.setpara;

begin
  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _pcs := 'UPDATE VTEMP SET DATUM='+chr(39)+_lezartnap+chr(39);
  ValutaParancs(_pcs);
end;  
end.
