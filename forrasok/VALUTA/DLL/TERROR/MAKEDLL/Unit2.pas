unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, unit1,strutils, WININET,
  IBDatabase, DB, IBCustomDataSet, IBQuery;

type
  TTERROR = class(TForm)

    Kilepo         : TTimer;

    RemoteQuery    : TIBQuery;
    RemoteTranz    : TIBTransaction;
    RemoteDbase    : TIBDatabase;

    TempQuery      : TIBQuery;
    TempDbase      : TIBDatabase;
    TempTranz      : TIBTransaction;

    Label1         : TLabel;
    Label2         : TLabel;
    Label3         : TLabel;
    Label4         : TLabel;

    EngedelyGomb   : TBitBtn;
    StopGomb       : TBitBtn;
    EngedelyezoGomb: TBitBtn;
    MegsemGomb     : TBitBtn;

    Panel1         : TPanel;
    EngedelyezoEdit: TEdit;

    procedure FormActivate(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure Regisztracio;
    procedure EngedelyGombClick(Sender: TObject);
    procedure StopGombClick(Sender: TObject);
    procedure EngedelyezoGombClick(Sender: TObject);
    procedure EngedelyezoEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    function BetuKiemelo(_s: string): string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  TERROR: TTERROR;

  _height,_width,_top,_left: word;

  _host,_remoteFdbPath: string;
  _pcs,_ugyfelnev,_aktidos,_engedelyezo,_engedelyezve: string;
  _penztarkod,_penztarnev,_megnyitottnap,_ptkod,_ptnev: string;

  _mresult,_recno : integer;
  _sikeres        : boolean;

  _sorveg: string = chr(13)+chr(10);

  _gyanus,_vaninternet: boolean;

  function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll'
  function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll';
  function terrorcontrol: integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
          function terrorcontrol: integer; stdcall;
// =============================================================================

begin
  Terror   := TTerror.Create(Nil);
  result   := Terror.showmodal;
  Terror.Free;
end;


// =============================================================================
               procedure TTERROR.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top    := round((_height-32)/2);
  _left   := round((_width-308)/2);

  Top     := _top-250;
  Left    := _left;

  Height  := 32;
  Width   := 292;

  Repaint;

  _pcs := 'SELECT * FROM VTEMP';

  TempDbase.Connected := True;
  with TempQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      _ugyfelNev := trim(FieldByNAme('UGYFELNEV').asString);

      Close;
      Sql.clear;
      Sql.Add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap:= FieldByName('MEGNYITOTTNAP').asString;
      _host := trim(FieldByName('HOST').AsString);

      _remoteFdbPath := _host + ':C:\RECEPTOR\DATABASE\TERRORISTS.FDB';

      Close;
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;

      _ptkod := trim(FieldByNAme('PENZTARKOD').AsString);
      _ptnev := trim(FieldByNAme('PENZTARNEV').AsString);
      Close;
    end;
  Tempdbase.close;

  _aktidos      := timetostr(Time);
  _engedelyezve := 'NEM';
  _engedelyezo  := '';
   _ugyfelnev   := BetuKiemelo(_ugyfelnev);

  _pcs := 'SELECT * FROM UNOLIST WHERE TERROR_NAME LIKE '+chr(39)+_ugyfelnev+'%'+chr(39);
  RemoteDbase.close;
  RemoteDbase.DatabaseName := _remoteFdbPath;

  _vaninternet := False;
  TRY
    Remotedbase.connected := true;
    _vaninternet := True;
  EXCEPT
    _vanInternet := False;
  end;

  if not _vanInternet then
    begin
      RemoteDbase.close;
      _mResult := 1;
      Kilepo.Enabled := true;
      exit;
    end;

  with RemoteQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      _recno := recno;
      Close;
    end;

  Remotedbase.close;

  // ---------------------------------------

  _gyanus := False;
  if _recno>0 then
    begin
      _gyanus := True;
      height := 164;
      exit;
    end;

  logirorutin(pchar('Terrorlistán nem szerepel az ügyfél'));
  _mResult := 1;
  Kilepo.enabled := true;
end;

// =============================================================================
            procedure TTERROR.ENGEDELYGOMBClick(Sender: TObject);
// =============================================================================

var _spk: integer;

begin
  _spk := supervisorjelszo(0);
  if _spk<>1 then _mResult := -1
  else _mResult := 1;

  Engedelyezogomb.Enabled := False;
  EngedelyezoEdit.Clear;
  
  Terror.Height := 275;
  ActiveControl := EngedelyezoEdit;
end;

// =============================================================================
           procedure TTERROR.STOPGOMBClick(Sender: TObject);
// =============================================================================

begin
  logirorutin(pchar('A terrorlistán szereplés miatt a trenzakció letiltva !'));
  Regisztracio;
  _mResult := -1;
  Kilepo.Enabled := true;
end;

// =============================================================================
            function TTerror.Betukiemelo(_s: string): string;
// =============================================================================

var _ws,_pp,_betu: byte;

begin
  _s := trim(_s);
  _ws := length(_s);
  result := '';
  _pp := 1;
  while _pp<=_ws do
    begin
      _betu := ord(_s[_pp]);
      if (_betu>64) and (_betu<91) then result := result + chr(_betu);
      inc(_pp);
    end;
end;


// =============================================================================
                      procedure TTerror.Regisztracio;
// =============================================================================

begin
  _pcs := 'INSERT INTO JOURNAL (DATUM,IDO,PENZTARKOD,PENZTARNEV,UGYFELNEV,';
  _pcs := _pcs + 'ENGEDELYEZVE,ENGEDELYEZO)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktidos + chr(39) + ',';
  _pcs := _pcs + chr(39) + _ptkod + chr(39) + ',';
  _pcs := _pcs + chr(39) + _ptnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _ugyfelnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _engedelyezve + chr(39) + ',';
  _pcs := _pcs + chr(39) + _engedelyezo + chr(39) + ')';
  remoteDbase.close;
  remoteDbase.DatabaseName := _remoteFdbPath;

  remotedbase.Connected := True;
  if remoteTranz.InTransaction then remotetranz.commit;
  remoteTranz.StartTransaction;

  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;
   remoteTranz.commit;
   remotedbase.close;
end;

// =============================================================================
        procedure TTERROR.ENGEDELYEZOGOMBClick(Sender: TObject);
// =============================================================================

begin
  _engedelyezve := 'IGEN';
  // engedélyezte a tranzakciót
  logirorutin(pchar('A terrorlista ellenére engedelyezték a tranzakciót'));
  logirorutin(pchar('Engedelyezö: ' + _engedelyezo));
  regisztracio;
  _mResult := 1;
  Kilepo.Enabled := True;
end;


procedure TTERROR.ENGEDELYEZOEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;

  _engedelyezo := trim(EngedelyezoEdit.Text);
  if _engedelyezo='' then exit;

  EngedelyezoGomb.Enabled := true;
  Activecontrol := EngedelyezoGomb;
end;

// =============================================================================
             procedure TTerror.KilepoTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := _mResult;
end;

end.
