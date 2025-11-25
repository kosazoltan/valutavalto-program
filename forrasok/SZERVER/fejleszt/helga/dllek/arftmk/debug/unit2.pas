unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DB, IBCustomDataSet, IBDatabase, IBTable,
  Grids, DBGrids, unit1, strUtils, IBQuery, ExtCtrls, jpeg, dateutils;

type
  TARFOLYAMTMK = class(TForm)

    ArfolyamRacs                    : TDBGrid;

    ArfolyamTabla                   : TIBTable;
    ArfolyamQuery                   : TIBQuery;
    ArfolyamDbase                   : TIBDatabase;
    ArfolyamTranz                   : TIBTransaction;
    ArfolyamSource                  : TDataSource;
    ArfolyamTablaValutanem          : TIBStringField;
    ArfolyamTablaValutanev          : TIBStringField;
    ArfolyamTablaElszamolasiArfolyam: TFloatField;

    Label1                          : TLabel;
    FeliroGomb                      : TBitBtn;
    VisszaGomb                      : TBitBtn;

    Shape1                          : TShape;
    Shape2                          : TShape;
    Image1                          : TImage;

    Panel1                          : TPanel;
    Panel2                          : TPanel;

    procedure ArfolyamRacsKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure DnemKod(_dev: string);
   
    procedure FormActivate(Sender: TObject);
    procedure FileBeiro(Sender: TObject);
    procedure IntegKod(_real: real);
    procedure VisszaGombClick(Sender: TObject);

    function Getmamas: string;
    function Kitkod(_kelte: string): string;
    function Nulele(_B: byte): string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var

  ARFOLYAMTMK: TARFOLYAMTMK;

  _iras,_olvas: file of byte;
  _byteTomb   : array[1..255] of byte;

  _nevlen,_elszamolasiarfolyam: integer;

  _valutadarab: byte;
  _betu       : char;
  _top,_left,_height,_width,_aktev,_aktho,_aktnap: word;

  _mamas,_aktdnem,_pcs,_kit: string;


function arfolyamkarbantarto: integer; stdcall;

implementation



{$R *.dfm}


function arfolyamkarbantarto: integer; stdcall;

begin
  Arfolyamtmk := TarfolyamTmk.create(Nil);
  result :=  Arfolyamtmk.showmodal;
  Arfolyamtmk.free;
end;



// ======================================================================
        procedure TARFOLYAMTMK.VISSZAGOMBClick(Sender: TObject);
// ======================================================================

begin
  if Arfolyamtranz.InTransaction then arfolyamTranz.Commit;
  ArfolyamDbase.close;
  ArfolyamTabla.close;
  ModalResult := 2;
end;

// ======================================================================
          procedure TARFOLYAMTMK.FormActivate(Sender: TObject);
// ======================================================================

begin
  _height := screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top    := 25+round((_height-530)/2);
  _left   := round((_width-748)/2);

  Top     := _top;
  Left    := _left;
  Height  := 530;
  Width   := 750;

  _mamas := Getmamas;

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
  ArfolyamRacs.SelectedIndex := 2;
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

// =============================================================================
                 procedure TARFOLYAMTMK.FileBeiro(Sender:TObject);
// =============================================================================


var _intar: real;
    _arfolyamDb: integer;
    _arfFile,_arfPath: string;

begin
  _kit     := Kitkod(_mamas);
  _arffile := 'AF100.' + _kit;
  _arfPath := 'c:\receptor\mail\arfolyam\' + _arffile;

  AssignFile(_iras,_arfPath);
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

  Showmessage('A ' + _mamas + '-I ELSZÁMOLÓ ÁRFOLYAMOK SIKERESEN RÖGZÍTVE LETTEK');
  Modalresult := 1;

end;

// ========================================================
        procedure TARFOLYAMTMK.DnemKod(_dev: string);
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
     function TARFOLYAMTMK.Kitkod(_kelte: string): string;
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


// =============================================================================
                   procedure TARFOLYAMTMK.IntegKod(_real: real);
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
                     function TARFOLYAMTMK.getmamas: string;
// =============================================================================

begin
  _aktev := yearof(date);
  _aktho := monthof(date);
  _aktnap := dayof(date);

  result := inttostr(_aktev)+'.'+nulele(_aktho)+'.'+nulele(_aktnap);
end;

// =============================================================================
                function TARFOLYAMTMK.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;






{

$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
            procedure TARFTMK.BetoltoGombClick(Sender: TObject);
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
      Exit;
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
  VisszaGombClick(NIL);
end;

// =============================================================================
           function TARFTMK.IntegDek(_5betu:string): real;
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
           function TARFTMK.DnemDekod(_dkod:string):string;
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

// =============================================================================
             function TARFTMK.RealToStr(_rr: real): string;
// =============================================================================

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
             procedure TARFTMK.OldArfolyamDelete;
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
}




end.
