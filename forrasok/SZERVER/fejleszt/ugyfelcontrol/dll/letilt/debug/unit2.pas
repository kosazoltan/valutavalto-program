unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DB, Grids, DBGrids, ExtCtrls, IBDatabase,
  IBCustomDataSet, IBQuery, strutils, dateutils, IBTable;

type
  TForm2 = class(TForm)

    BizlatokQuery     : TIBQuery;
    BizlatokDbase     : TIBDatabase;
    BizlatokTranz     : TIBTransaction;

    JogiQuery         : TIBQuery;
    JogiDbase         : TIBDatabase;
    JogiTranz         : TIBTransaction;

    RemoteTabla       : TIBTable;
    RemoteQuery       : TIBQuery;
    RemoteDbase       : TIBDatabase;
    RemoteTranz       : TIBTransaction;

    FigyelemPanel     : TPanel;
    JogiTiltoPanel    : TPanel;
    KeziAdatPanel     : TPanel;
    LetiltoPanel      : TPanel;
    TakaroPanel       : TPanel;
    TTPanel           : TPanel;

    Label1            : TLabel;
    Label3            : TLabel;
    Label4            : TLabel;
    Label5            : TLabel;
    Label6            : TLabel;
    Label7            : TLabel;
    Label8            : TLabel;
    Label9            : TLabel;
    Label2            : TLabel;
    Label19           : TLabel;
    Label10           : TLabel;
    Label11           : TLabel;
    Label12           : TLabel;
    Label13           : TLabel;
    Label14           : TLabel;
    Label15           : TLabel;
    Label16           : TLabel;
    Label17           : TLabel;
    Label18           : TLabel;
    Label20           : TLabel;
    Label21           : TLabel;
    TNevEdit          : TEdit;
    TiltNEVEdit       : TEdit;
    TAnyjaEdit        : TEdit;
    TNedit            : TEdit;
    TAEdit            : TEdit;
    TIEdit            : TEdit;
    THEdit            : TEdit;
    TLEdit            : TEdit;
    TSzulidoEdit      : TEdit;
    TSzulhelyEdit     : TEdit;

    TiltoRacs         : TDBGrid;
    JogiTiltRACS      : TDBGrid;

    JogiTiltSource    : TDataSource;
    TiltoSource       : TDataSource;

    IgenGomb          : TBitBtn;
    NemGomb           : TBitBtn;
    TMegsemGomb       : TBitBtn;
    JMegsemGomb       : TBitBtn;
    JogiTiltoGomb     : TBitBtn;
    JogiTiltMegsemGomb: TBitBtn;
    TGomb             : TBitBtn;
    MegemGomb         : TBitBtn;
    KeziGomb          : TBitBtn;
    LetiltoGomb       : TBitBtn;
    TVisszaGomb       : TBitBtn;

    Kilepo            : TTimer;

    Shape1            : TShape;
    Label23: TLabel;
    KERESOPANEL: TPanel;
    Label24: TLabel;
    VALUGYFEDIT: TEdit;

    procedure FormActivate(Sender: TObject);
    procedure IgenGombClick(Sender: TObject);
    procedure JMegsemGombClick(Sender: TObject);
    procedure JogiTiltastValasztott;
    procedure JogiTiltas;
    procedure JogiTiltoGombClick(Sender: TObject);
    procedure JogiTiltRacsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure JogiTiltMegsemGombClick(Sender: TObject);
    procedure KeziGombClick(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure MegemGombClick(Sender: TObject);
    procedure NemGombClick(Sender: TObject);
    procedure RemoteParancs(_ukaz: string);
    procedure TGombClick(Sender: TObject);
    procedure TNevEditEnter(Sender: TObject);
    procedure TNevEditExit(Sender: TObject);
    procedure TiltotValasztott;
    procedure TiltoRacsDblClick(Sender: TObject);
    procedure TiltoRacsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TiltNevEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TMegsemGombClick(Sender: TObject);
    procedure TTMBClick(Sender: TObject);
    procedure TNevEditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure TVisszaGombClick(Sender: TObject);
    procedure Ugyfeltiltas;

    function Angolra(_huName: string): string;
    function DoubleKill(_s: string): string;
    function HutoGb(_kod: byte): byte;
    function Tomorito(_ts: string): string;
    procedure JOGITILTRACSDblClick(Sender: TObject);
   
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _height,_width,_left,_TOP,_aktev: word;
  _bill,_wk: byte;

  _tEdit : array[1..4] of TEdit;
  _host: string = '185.43.207.99';

  _ugyfeltipus,_evtizes,_fdbpath,_tkernev,_kezdobetu,_nevtabla,_pcs: string;
  _tiltnev,_tiltanyja,_tiltszulido,_tiltszulhely,_lastvari,_aktevs: string;
  _ttnev,_ttanyja,_ttszulido,_ttszulhely,_ttlakcim,_keres,_valugyfnev: string;
  _sorveg: string = chr(13)+chr(10);

  _ttsss,_SSS,_sorszam: integer;
  _ttiltva: byte;
  _found: boolean;


function letiltorutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
               function letiltorutin: integer; stdcall;
// =============================================================================

begin
  form2 := TForm2.Create(Nil);
  result := Form2.showmodal;
  form2.free;
end;


// =============================================================================
            procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height  := screen.Monitors[0].Height;
  _width   := Screen.Monitors[0].Width;
  _top     := round((_height-595)/2);
  _left    := round((_width-1017)/2);

  Top      := _top;
  Left     := _left+48;
  Height   := 452;
  width    := 906;

  _tEdit[1] := tiltnevedit;
  _tEdit[2] := tanyjaedit;
  _tEdit[3] := tszulidoedit;
  _tEdit[4] := tszulhelyedit;

  bizlatokdbase.connected := True;
  with BizlatokQuery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _ugyfeltipus := FieldByNAme('PTTIPUS').asString;
      close;
    end;
  BizlatokDbase.close;
  if _ugyfeltipus='N' then Ugyfeltiltas else Jogitiltas;
//  Kilepo.enabled := True;
end;

// =============================================================================
                      procedure TForm2.UgyfelTiltas;
// =============================================================================

begin
  _aktev := yearof(date);
  _evtizes := midstr(inttostr(_aktev),3,2);
  _fdbPath := _host + ':C:\receptor\database\ugyfel' + _evtizes + '.FDB';

  Remotedbase.Close;
  remotedbase.DatabaseName := _fdbPath;
  remoteDbase.Connected := True;


  with Letiltopanel do
    begin
      top := 0;
      Left := 0;
      Visible := True;
      repaint;
    end;
  Activecontrol := tnevedit;
end;

// =============================================================================
               procedure TForm2.KilepoTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;

  remotequery.close;
  remotedbase.close;
  JogiQuery.close;
  JogiDbase.close;

  Modalresult := 1;
end;

// =============================================================================
        procedure TForm2.TNevEditKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;

  _tkernev   := angolra(Tnevedit.Text);
  _kezdobetu := leftstr(_tkernev,1);
  _nevtabla  := _kezdobetu + 'NEV';

  _pcs := 'SELECT * FROM ' +_nevtabla + _sorveg;
  _pcs := _pcs + 'WHERE (NEV LIKE ' + chr(39) + _tkernev + '%'+chr(39)+')'+_sorveg;
  _pcs := _pcs + 'ORDER BY NEV';

  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  TiltoSource.Enabled := True;
  Tiltoracs.SetFocus;
end;


// =============================================================================
             procedure TForm2.TiltoRacsDblClick(Sender: TObject);
// =============================================================================

begin
  Tiltotvalasztott;
end;

// =============================================================================
        procedure TForm2.TiltoRacsKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  TiltotValasztott;
end;

// =============================================================================
                  procedure TForm2.TiltotValasztott;
// ============================================================================

begin
  with RemoteQuery do
    begin
      _ttnev      := trim(FieldByNAme('NEV').asString);
      _ttanyja    := trim(FieldByNAme('ANYJANEVE').asString);
      _ttszulido  := FieldByNAme('SZULETESIIDO').asString;
      _ttszulhely := trim(FieldByNAme('SZULETESIHELY').asString);
      _ttlakcim   := trim(FieldByNAme('LAKCIM').asString);
      _ttsss      := FieldByNAme('SORSZAM').asInteger;
      _ttiltva    := FieldByNAme('TILTVA').asInteger;
    end;

  if _ttiltva=1 then
    begin
      with Figyelempanel do
        begin
          top     := 108;
          left    := 226;
          Visible := True;
          repaint;
        end;
      Activecontrol := Nemgomb;
      exit;
    end;


  Tnedit.text := _ttnev;
  TAedit.text := _ttanyja;
  Tiedit.text := _ttszulido;
  Thedit.text := _ttszulhely;
  TLedit.text := _ttlakcim;

  Kezigomb.Enabled := False;
  TMegsemgomb.Enabled := False;
  with TTPanel do
    begin
      top     := 55;
      left    := 248;
      Visible := true;
      repaint;
    end;

end;

// =============================================================================
              procedure TForm2.TNevEditEnter(Sender: TObject);
// =============================================================================

begin
   Tedit(sender).Color := clyellow;
end;


// =============================================================================
               procedure TForm2.TNevEditExit(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clWindow;
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
  result := DoubleKill(result);
end;

// =============================================================================
                   function TForm2.DoubleKill(_s: string): string;
// =============================================================================

var _w,_asc,_utasc,_y: byte;

begin
  result := '';

  _s := trim(_s);
  _w := length(_s);

  // Ha üres string -> nincs mit tömöriteni
  if _w=0 then exit;

  _y     := 1;
  _utasc := 0;       // default

  while _y<=_w do
    begin
      _asc := ord(_s[_y]);
      if (_asc=32) and (_utasc=32) then
        begin
          inc(_y);
          continue;
        end;

      if _asc=32 then
        begin
          result := result + ' ';
          _utasc := 32;
          inc(_y);
          Continue;
        end;

      if (_asc<48) or (_asc>90) then
        begin
          inc(_y);
          Continue;
        end;

      if (_asc>57) and (_asc<65) then
        begin
          inc(_y);
          Continue;
        end;

      result := Result + chr(_asc);
      _utasc := _asc;
      inc(_y);
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
            procedure TForm2.TVisszaGombClick(Sender: TObject);
// =============================================================================

begin
  TTPanel.Visible     := False;
  Kezigomb.Enabled    := True;
  TMegsemgomb.Enabled := True;
end;

// =============================================================================
                procedure TForm2.KeziGombClick(Sender: TObject);
// =============================================================================

var i: byte;

begin
  for i := 1 to 4 do _TEdit[i].clear;

  Kezigomb.Enabled := False;
  TMegsemgomb.Enabled := False;
  with KeziAdatPanel do
    begin
      Top := 56;
      Left:= 192;
      Visible := true;
      repaint;
    end;
  Activecontrol := Tiltnevedit;
end;

// =============================================================================
                 procedure TForm2.TTMbClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'UPDATE ' + _nevtabla + ' SET TILTVA=1' + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_ttsss);
  RemoteParancs(_pcs);

  TTpanel.Visible := false;
  LetiltoPanel.visible := False;
  Showmessage(_ttnev + ' nevû ügyfél letiltva');

  Kilepo.Enabled := True;
end;

// =============================================================================
               procedure TForm2.RemoteParancs(_ukaz: string);
// =============================================================================

begin
  RemoteDbase.connected := True;
  if RemoteTranz.InTransaction then RemoteTranz.commit;
  RemoteTranz.StartTransaction;
  with RemoteQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_ukaz);
      Execsql;
    end;
  RemoteTranz.Commit;
  RemoteDbase.close;
end;

// =============================================================================
               procedure TForm2.MegemGombClick(Sender: TObject);
// =============================================================================

begin
  KeziadatPanel.Visible := False;
  KeziGomb.Enabled      := True;
  TMegsemGomb.Enabled   := True;
  ActiveControl         := TiltoRacs;
end;

// =============================================================================
              procedure TForm2.NemGombClick(Sender: TObject);
// =============================================================================

begin
  FigyelemPanel.Visible := False;
  ActiveControl := TiltoRacs;
end;

// =============================================================================
                procedure TForm2.IgenGombClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'UPDATE ' + _nevtabla + ' SET TILTVA=0' + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_ttsss);
  RemoteParancs(_pcs);

  TTpanel.Visible       := False;
  LetiltoPanel.visible  := False;
  FigyelemPanel.Visible := False;
  showmessage(_ttnev + ' nevü ügyfél tiltása feloldva');

  Kilepo.Enabled := True;
end;

// =============================================================================
          procedure TForm2.TiltNevEditKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

var _tag: byte;

begin
  if ord(key)<>13 then exit;

  _tag := TEdit(sender).Tag;
  inc(_tag);
  if _tag>4 then Activecontrol := Tgomb else ActiveControl := _tedit[_tag];
end;

// =============================================================================
               procedure TForm2.TGombClick(Sender: TObject);
// =============================================================================
begin

  _tiltnev      := angolra(Tiltnevedit.Text);
  _tiltanyja    := Angolra(TAnyjaEdit.text);
  _tiltszulido  := tomorito(Tszulidoedit.text);
  _tiltszulhely := Angolra(TszulhelyEdit.text);

  _kezdoBetu := Leftstr(_tiltnev,1);
  _nevtabla  := _kezdobetu + 'NEV';
  _lastvari  := _kezdobetu + 'LAST';

  _aktev   := yearof(date);
  _aktevs  := inttostr(_aktev);
  _fdbPath := _host + ':C:\receptor\database\ugyfel' + midstr(_aktevs,3,2)+'.FDB';

  RemoteDbase.Close;
  RemoteDbase.databasename := _fdbPath;
  RemoteDbase.Connected := true;

  if RemoteTranz.InTransaction then RemoteTranz.commit;
  RemoteTranz.StartTransaction;
  RemoteTabla.close;
  RemoteTabla.TableName := 'LASTNUMS';
  RemoteTabla.Open;

  _sss := ReMoteTabla.FieldByNAme(_lastvari).asInteger;
  RemoteTabla.edit;
  RemoteTabla.FieldByNAme(_lastvari).AsInteger := _sss+1;
  RemoteTabla.Post;
  RemoteTranz.commit;
  RemoteDbase.close;

  inc(_sss);

  _pcs := 'INSERT INTO '+_nevtabla+' (SORSZAM,NEV,ANYJANEVE,SZULETESIIDO,';
  _pcs := _pcs + 'SZULETESIHELY,TILTVA)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_sss) + ',';
  _pcs := _pcs + chr(39)  + _tiltnev + chr(39) + ',';
  _pcs := _pcs + chr(39)  + _tiltanyja + chr(39) + ',';
  _pcs := _pcs + chr(39)  + _tiltszulido + chr(39) + ',';
  _pcs := _pcs + chr(39)  + _tiltszulhely + chr(39) + ',1)';

  RemoteParancs(_pcs);

  Keziadatpanel.Visible := False;
  LetiltoPanel.Visible := False;
  Showmessage(_tiltnev+' nevü ügyfél letiltva !');
  Kilepo.Enabled := True;
end;

// =============================================================================
           function TForm2.Tomorito(_ts: string): string;
// =============================================================================

var _ws,_y,_aktasc: byte;

begin
  _ts    := trim(_ts);
  result := '';

  if _ts='' then exit;

  _ts := uppercase(_ts);
  _ws := length(_ts);
  _y  := 1;

  while _y<=_ws do
    begin
      _aktasc := ord(_ts[_y]);
      if (_aktasc>47) and (_aktasc<58) then result := result + chr(_aktasc);
      if (_aktasc>64) and (_aktasc<91) then result := result + chr(_aktasc);
      inc(_y);
    end;
end;

// =============================================================================
          procedure TForm2.TMegsemGombClick(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := True;
end;

// =============================================================================
                     procedure TForm2.JogiTiltas;
// =============================================================================

var _dnev,_aktevs,_tail: string;
    _aktev : word;

begin
  _aktev  := yearof(date);
  _aktevs := inttostr(_aktev);
  _tail   := midstr(_aktevs,3,2);
  _dnev   := 'UGYFEL' + _tail + '.FDB';

  _pcs := 'SELECT * FROM JOGI' + _sorveg;
  _pcs := _pcs + 'ORDER BY JOGISZEMELYNEV';


  JogiDbase.close;
  JogiDbase.DatabaseName := _host + ':C:\RECEPTOR\DATABASE\' + _dnev;
  JogiDbase.Connected := True;
  wiTH JogiQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  JogitiltSource.Enabled := True;
  KeresoPanel.Caption := '';

  _Keres := '';
  with JogiTiltoPanel do
    begin
      top := 54;
      left := 200;
      Visible := True;
      Repaint;
    end;
  ActiveControl :=  JogiTiltRacs;
end;


// =============================================================================
     procedure TForm2.JogiTiltRacsKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  _bill := ord(key);

  if (_bill>96) and (_bill<123) then _bill := _bill-32;
  if (_bill>64) and (_bill<91) then
    begin
      _keres := _keres + chr(_bill);
      _found := JogiQuery.Locate('JOGISZEMELYNEV',_keres,[loPartialkey]);
      if _found then KeresoPanel.Caption := _keres;
      exit;
    end;

  if _bill=8 then
    begin
      _wk := length(_keres);
      if _wk=0 then exit;

      if _wk=1 then
        begin
          _keres := '';
          KeresoPanel.Caption := '';
          exit;
        end;
      dec(_wk);
      _keres := leftstr(_keres,_wk);
      JogiQuery.Locate('JOGISZEMELYNEV',_keres,[loPartialkey]);
      KeresoPanel.Caption := _keres;
      exit;
    end;

  if _bill =13 then
    begin
      JogitiltastValasztott;
      exit;
    end;

  _Keres := '';
  KeresoPanel.caption := '';
end;

// =============================================================================
                  procedure TForm2.JogitiltastValasztott;
// =============================================================================

begin
  _valugyfnev := trim(Jogiquery.fieldbyname('JOGISZEMELYNEV').asstring);
  _sorszam := Jogiquery.FieldByNAme('SORSZAM').asInteger;
  JogiQuery.close;
  Jogidbase.close;

  Valugyfedit.Text := _valugyfnev;

  JmegsemGomb.Visible := False;
  TakaroPanel.Visible := False;
  ActiveControl := JogitiltoGomb;
end;

// =============================================================================
            procedure TForm2.JMegsemGombClick(Sender: TObject);
// =============================================================================

begin
  RemoteQuery.close;
  RemoteDbase.close;
  JogitiltoPanel.Visible := False;

  Kilepo.Enabled := true;
end;


// =============================================================================
             procedure TForm2.JOGITILTOGOMBClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'UPDATE JOGI SET TILTVA=1 WHERE SORSZAM='+inttostr(_sorszam);
  RemoteParancs(_pcs);

  JogiTiltoPanel.Visible := False;
  JogiTiltSource.Enabled := False;

  Kilepo.Enabled := True;
end;


// =============================================================================
          procedure TForm2.JogiTiltMegsemGombClick(Sender: TObject);
// =============================================================================

begin
  JogiQuery.close;
  Jogidbase.close;

  Kilepo.Enabled := True;
end;


// =============================================================================
          procedure TForm2.JOGITILTRACSDblClick(Sender: TObject);
// =============================================================================

begin
  JogiTiltastValasztott;
end;






end.
