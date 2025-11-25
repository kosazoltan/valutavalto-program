unit Unit21;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DB, IBCustomDataSet, IBDatabase, IBTable,
  Grids, DBGrids, unit1, strUtils, IBQuery, ExtCtrls;

type
  TARFOLYAMTMK = class(TForm)
    CANCELGOMB: TBitBtn;
    ARFOLYAMRACS: TDBGrid;
    ARFOLYAMTABLA: TIBTable;
    ARFOLYAMDBASE: TIBDatabase;
    ARFOLYAMTRANZ: TIBTransaction;
    ARFOLYAMSOURCE: TDataSource;
    ARFOLYAMTABLAVALUTANEM: TIBStringField;
    ARFOLYAMTABLAVALUTANEV: TIBStringField;
    ARFOLYAMTABLAELSZAMOLASIARFOLYAM: TFloatField;
    Label1: TLabel;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn1: TBitBtn;
    BitBtn4: TBitBtn;
    ArfolyamQuery: TIBQuery;
    Shape1: TShape;
    Shape2: TShape;
    procedure CANCELGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FileBeiro;
    procedure ARFOLYAMRACSKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    function Kitkod(_kelte: string): string;
    procedure DnemKod(_dev: string);
    procedure OldArfolyamDelete;
    procedure BitBtn2Enter(Sender: TObject);
    procedure BitBtn2Exit(Sender: TObject);
    procedure TextKod(_sz: string);
    procedure IntegKod(_real: real);
    procedure BitBtn2MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
    function IntegDek(_5betu:string): real;
    function DnemDekod(_dkod:string):string;
    function RealToStr(_rr: real): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ARFOLYAMTMK: TARFOLYAMTMK;
  _iras,_olvas: file of byte;
  _kit: string;
  _byteTomb: array[1..255] of byte;
  _nevlen: integer;

implementation



{$R *.dfm}

// ======================================================================
        procedure TARFOLYAMTMK.CANCELGOMBClick(Sender: TObject);
// ======================================================================

begin
  if Arfolyamtranz.InTransaction then arfolyamTranz.Commit;
  ArfolyamTabla.close;
  ModalResult := 2;
end;

// ======================================================================
          procedure TARFOLYAMTMK.FormActivate(Sender: TObject);
// ======================================================================

begin
  tOP := _TOP + 120;
  Left := _left + 140;
  Height := 530;
  Width := 750;
  
  Bitbtn1.Enabled := true;

  Arfolyamdbase.close;
  ArfolyamDbase.Connected := true;
  if arfolyamTranz.InTransaction then arfolyamTranz.Commit;
  ArfolyamTranz.StartTransaction;

  with ArfolyamTabla do
    begin
      Open;
      Refresh;
      First;
    end;
  ArfolyamRacs.selectedIndex := 2;
  ActiveControl := arfolyamRacs;
end;

// ==================================================================================
       procedure TARFOLYAMTMK.ARFOLYAMRACSKeyDown(Sender: TObject; var Key: Word;
                                                       Shift: TShiftState);
// ==================================================================================


var _oszlop : integer;
begin
  if ord(key)=13 then
    begin
      _oszlop := arfolyamRacs.SelectedIndex;
      if _oszlop<2 then
        begin
          ArfolyamRacs.SelectedIndex := (_oszlop+1);
          exit;
        end;
      if not ArfolyamTabla.Eof then
        begin
          ArfolyamTabla.Next;
          ArfolyamRacs.SelectedIndex := 2;
        end;
    end;
end;

// ================================================
         procedure TArfolyamTmk.FileBeiro;
// ================================================


var _intar: real;
    _arfolyamDb: integer;
 //   _vanmeg: TSearchRec;
 //   _fname: string;

begin
   (*
   _ures := findFirst('c:\receptor\mail\arfolyam\*.*',faAnyFile,_vanmeg);
   if _ures=0 then
     begin
       repeat
         _fname :=  _vanmeg.Name;
         SysUtils.Deletefile('c:\receptor\mail\arfolyam\' + _fname);
       until FindNext(_vanmeg)<>0;
       FindClose(_vanmeg);
     end;
    *)

  OldArfolyamDelete;

  _kit := Kitkod(_mamas);

  AssignFile(_iras,'c:\receptor\mail\arfolyam\AF100.'+_kit);
  Rewrite(_iras);
  ArfolyamTabla.First;
  _arfolyamDb := 0;
  while not ArfolyamTabla.Eof do
    begin
      inc(_arfolyamdb);
      ArfolyamTabla.Next;
    end;

  _byteTomb[1] := _arfolyamDb;
  Blockwrite(_iras,_bytetomb,1);

  ArfolyamTabla.First;
  while not ArfolyamTabla.Eof do
    begin
      _aktdnem := ArfolyamTabla.FieldByName('VALUTANEM').asString;
      _elszamolasiarfolyam:= ArfolyamTabla.FieldByName('ELSZAMOLASIARFOLYAM').asInteger;

      DnemKod(_aktdnem);
      blockwrite(_iras,_bytetomb,2);
      _intar := 10000*_elszamolasiarfolyam;
      Integkod(_intar);
      Blockwrite(_iras,_byteTomb,5);
      ArfolyamTabla.Next;
    end;
  ArfolyamTabla.First;
  _byteTomb[1] := 255;
  _bytetomb[2] := 255;
  Blockwrite(_iras,_bytetomb,2);
  closeFile(_iras);
end;

// ========================================================
        procedure TarfolyamTmk.DnemKod(_dev: string);
// ========================================================


var _a,_b,_c,_1,_2: byte;


begin
  _a := ord(_dev[1])-65;
  _b := ord(_dev[2])-65;
  _c := ord(_dev[3])-65;

  _1 := trunc(4*_a)+ trunc(_b/8);
  _2 := _c + trunc(32*_B);

  _bytetomb[1] := _1;
  _byteTomb[2] := _2;
end;


// ==========================================================
     function TArfolyamTmk.Kitkod(_kelte: string): string;
// ==========================================================


var _hos,_evs,_naps: byte;
    _ho,_evt,_nap : integer;

begin
  result := '000';
  if _kelte='' then exit;

  _ho := strtoint(midstr(_kelte,6,2));
  _evt := strtoint(midstr(_kelte,3,2));
  _nap := strtoint(midstr(_kelte,9,2));
  _hos := 64 + trunc(2*_ho);
  if _nap<10 then _naps := _nap+48
  else _naps := _nap+55;
  _evs := _evt + 64;
  result := chr(_naps)+chr(_evs)+chr(_hos);
end;



// ==========================================================
      procedure TARFOLYAMTMK.BitBtn2Enter(Sender: TObject);
// ==========================================================

begin
  with TBitBtn(sender).Font do
    begin
      Color := clBlack;
    end;
end;

// ==========================================================
      procedure TARFOLYAMTMK.BitBtn2Exit(Sender: TObject);
// ==========================================================

begin
   with TBitBtn(sender).Font do
    begin
      Color := clGray;
    end;
end;

// =============================================================================
               procedure TARFOLYAMTMK.BitBtn2MouseMove(Sender: TObject;
                                          Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  ActiveControl := TBitbtn(sender);
end;


// =============================================================================
                 procedure TArfolyamTmk.TextKod(_sz: string);
// =============================================================================


var _ii,_jj: integer;
    _aa: byte;
    _back: string;

begin
  _ii := 1;
  _back := '';
  while _ii<=length(_sz) do
    begin
      _aa := ord(_sz[_ii]);
      if _aa<64 then
        begin
          _back := _back + chr(_aa+32);
          inc(_ii);
          continue;
        end;

      if _aa<128 then
        begin
          _back := _back + chr(_aa-32);
          inc(_ii);
          Continue;
        end;
      _back := _back + chr(_aa-1);
      inc(_ii);
    end;
  _ii := length(_sz);
  _jj := 1;
  while _ii>0 do
    begin
      _aa := ord(_back[_ii]);
      _byteTomb[_jj] := _aa;
      inc(_jj);
      dec(_ii);
    end;
end;

// =============================================================================
                   procedure TarfolyamTmk.IntegKod(_real: real);
// =============================================================================


var i: integer;
    _b1,_b2,_b3,_b4,_b5: Byte;

begin
  for i := 1 to 5 do _bytetomb[i] := 0;
  if _real=0 then exit;

  _b1 := trunc(_real/65536/65536);
  _real := _real - (65635*(65536*_b1));

  _b2 := trunc(_real/65536/256);
  _real := _real - (256*65536*_b2);

  _b3 := trunc(_real/65536);
  _real := _real - (_b3*65536);

  _b4 := trunc(_real/256);
  _b5 := trunc(_real - (256*_b4));

  _byteTomb[1] := _b1;
  _byteTomb[2] := _b2;
  _byteTomb[3] := _b3;
  _byteTomb[4] := _b4;
  _byteTomb[5] := _b5;
end;


// =============================================================================
            procedure TARFOLYAMTMK.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  BitBtn1.Enabled := false;
  FileBeiro;
end;

// =============================================================================
            procedure TARFOLYAMTMK.BitBtn4Click(Sender: TObject);
// =============================================================================

var _localFile,_kodstr: string;
    i: integer;
    _elszamarfolyam: real;

begin
  // ÁRFOLYAM BETÖLTÉSE

  _kit := Kitkod(_mamas);
  _localFile := 'c:\receptor\mail\arfolyam\AF100.'+_kit;
  if not FileExists(_localFile) then
    begin
      ShowMessage('NINCSENEK MAI ÁRFOLYAMOK SEHOL');
      EXIT;
    end;

  AssignFile(_olvas,_localfile);
  Reset(_olvas);
  BlockRead(_olvas,_byteTomb,1);
  _valutaDarab := _bytetomb[1];

  if _valutaDarab=0 then
    begin
      CloseFile(_olvas);
      ShowMessage('NINCSENEK ÁRFOLYAMOK AZ ADATOKBAN');
      Exit;
    end;

  ArfolyamDbase.Close;
  ArfolyamDbase.Connected := true;

  if ArfolyamTranz.InTransaction then ArfolyamTranz.Commit;
  ArfolyamTranz.StartTransaction;

  while true do
    begin
      BlockRead(_olvas,_byteTomb,2);
      if (_byteTomb[1]=255) and (_byteTomb[2]=255) then break;

      _kodstr := chr(_byteTomb[1])+chr(_byteTomb[2]);
      _aktdnem := dnemdekod(_kodstr);

      BlockRead(_olvas,_byteTomb,5);
      _kodstr := chr(_byTeTomb[1]);

      for i := 2 to 5 do  _kodStr := _kodstr + chr(_byteTomb[i]);
      _elszamarfolyam := (integDek(_kodstr))/10000;

      _pcs := 'UPDATE ARFOLYAM SET ELSZAMOLASIARFOLYAM='+RealToStr(_elszamarfolyam);
      _pcs := _pcs + ' WHERE VALUTANEM=' + chr(39) + _aktdnem + chr(39);

      with ArfolyamQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          ExecSql;
        end;
    end;

  CloseFile(_olvas);

  ArfolyamTranz.Commit;
  ArfolyamDbase.Close;

  ShowMessage('AZ ELSZÁMOLÓ ÁRFOLYAMOK SIKERESEN BETÖLTÖDTEK');
  cAnCELgOMBclICK(nil);
end;

// =============================================================================
           function TArfolyamTMk.IntegDek(_5betu:string): real;
// =============================================================================

var _a1,_a2,_a3,_a4,_a5,_negativ: integer;
    _r0,_r1,_r2,_r3,_r4,_big: real;

begin
  result := 0;

  if _5betu='' then exit;
  _a1 := ord(_5betu[1]);
  _a2 := ord(_5betu[2]);
  _a3 := ord(_5betu[3]);
  _a4 := ord(_5betu[4]);
  _a5 := ord(_5betu[5]);
  _negativ := 0;

  if _a1>127 then
    begin
      _a1 := _a1 - 128;
      _negativ := 1;
    end;
  _big := sqr(65536);
  _r0 := (1.00*_a5);
  _r1 := 256*_a4;
  _r2 := 65536*_a3;
  _r3 := 256*65536*_a2;
  _r4 := _big*_a1;

  result := _r0+_r1+_r2+_r3+_r4;

  if _negativ>0 then result := result*(-1);
end;

// =============================================================================
           function TArfolyamtmk.DnemDekod(_dkod:string):string;
// =============================================================================

var _a1,_a2,_x1,_x2,_x3: integer;

begin
  result := '';
  if _dkod='' then exit;
  _a1 := ord(_dkod[1]);    //  2
  _a2 := ord(_dkod[2]);    //  131

  _x1 := trunc(_a1/4);
  _x2 := trunc((_a1 and 3) * 8) + trunc(_a2/32);
  _x3 := (_a2 and 31);

  result := chr(_x1+65)+chr(_x2+65)+chr(_x3+65);
end;

function TArfolyamtmk.RealToStr(_rr: real): string;

var _rst: string;
    _ww,i: integer;
    _kod: byte;

begin
  _rst := floattostr(_rr);
  _ww := length(_rst);
  Result := '';
  if _ww=0 then exit;

  for i := 1 to _ww do
    begin
      _betu := _rst[i];
      _kod := ord(_betu);

      if _kod=44 then _kod := 46;
      Result := Result + chr(_kod);
    end;
end;

// =============================================================================
             procedure Tarfolyamtmk.OldArfolyamDelete;
// =============================================================================


var _srec: TSearchrec;
    _minta,_delpath,_dFile: string;
    _cc,_y: byte;
    _delfile: array[0..9] of string;

begin
  _minta := 'c:\receptor\mail\arfolyam\af100.*';
  _cc := 0;
  if FindFirst(_minta, faAnyFile, _srec) = 0 then
    begin
      repeat
        _delfile[_cc] := _srec.Name;
        inc(_cc);
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;
  if _cc>0 then
    begin
      _y := 0;
      while _y<=_cc do
        begin
          _dfile := _delfile[_y];
          _delpath := 'c:\receptor\mail\arfolyam\' + _dfile;
          Sysutils.DeleteFile(_delpath);
          inc(_y);
        end;
    end;
end;




end.
