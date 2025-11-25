unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBQuery, IBCustomDataSet,
  IBTable, ExtCtrls, dateutils;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    STARTGOMB: TBitBtn;
    VTABLA: TIBTable;
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    GYQUERY: TIBQuery;
    GYDBASE: TIBDatabase;
    GYTRANZ: TIBTransaction;
    Memo1: TMemo;
    Label1: TLabel;
    Shape1: TShape;
    TOLEVCOMBO: TComboBox;
    TOLHOCOMBO: TComboBox;
    IGEVCOMBO: TComboBox;
    IGHOCOMBO: TComboBox;
    Label2: TLabel;
    Label3: TLabel;

    procedure BitBtn2Click(Sender: TObject);
    procedure StartGombClick(Sender: TObject);

    function ezetar(_ptr: byte): boolean;
    function Angolra(_huName: string): string;
    function DoubleKill(_s: string): string;
    function HutoGb(_kod: byte): byte;
    procedure GyParancs(_ukaz: string);
    function Nulele(_b: byte): string;
 
    procedure FormActivate(Sender: TObject);
    procedure TOLEVCOMBOChange(Sender: TObject);
   

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _pt,_ho,_ev: byte;
  _sorveg: string = chr(13)+chr(10);
  _farok,_bf,_pcs,_un,_psz,_dat,_tip,_fdbpath,_ucs,_lastfarok,_biz: string;
  _osz,_recno,_kdij,_fizetendo: integer;

  _honev: array[1..12] of string = ('január','február','március','április','május',
       'junius','július','augusztus','szeptember','október','november','december');

  _y : byte;
  _aktev,_aktho,_tolevindex,_igevindex,_tolhoindex,_ighoindex: word;
  _kerttolev,_kertigev,_kerttolho,_kertigho: word;
  _tolev,_tolho,_igev,_igho,_honapdb: word;

  _toldatums,_igdatums: string;


implementation

{$R *.dfm}

// =============================================================================
              procedure TForm1.BitBtn2Click(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;

end;

// =============================================================================
             procedure TForm1.StartGombClick(Sender: TObject);
// =============================================================================

begin
  _tolevindex  := tolevcombo.ItemIndex;
  _tolhoindex  := tolhocombo.itemindex;

  _igevindex   := igevcombo.ItemIndex;
  _ighoindex   := ighocombo.itemindex;

  _tolev := (_aktev-1)+_tolevindex;
  _igev  := (_aktev-1)+_igevindex;

  _tolho := _tolhoindex+1;
  _igho  := _ighoindex+1;

  _honapdb := daysinamonth(_igev,_igho);

  _toldatums := inttostr(_tolev)+'.'+nulele(_tolho)+'.01';
  _igdatums  := inttostr(_igev) +'.'+nulele(_igho) +'.'+nulele(_honapdb);


  // ----------------------------------------------------------

  _UCS := 'DELETE FROM PGYUJTO';
  Gyparancs(_ucs);

  _pt := 4;
  while _pt<=180 do
    begin
      if ezetar(_pt) then
        begin
          inc(_pt);
          continue;
        end;

      if _pt<151 then _fdbpath := 'c:\receptor\database\v'+inttostr(_pt)+'.fdb'
      else _fdbpath := 'c:\cartcash\database\v'+inttostr(_pt)+'.fdb';

      if not fileExists(_fdbpath) THEN
        begin
          inc(_pt);
          continue;
        end;

      vdbase.close;
      vdbase.databasename := _fdbpath;
      vDbase.connected := true;

      _ev := _tolev-2000;
      _ho := _tolho;

      _farok := inttostr(_ev)+nulele(_ho);
      _lastfarok := inttostr(_igev-2000)+nulele(_igho);

      while _farok<=_lastfarok do
        begin
          _bf := 'BF' + _farok;
          Memo1.Lines.Add(inttostr(_pt)+'. '+_bf);

          vtabla.close;
          vtabla.tablename := _bf;
          if not vtabla.exists then
            begin
              inc(_ho);
              if _ho>12 then
                begin
                  _ho := 1;
                  inc(_ev);
                end;
              _farok := inttostr(_ev)+nulele(_ho);
              continue;
            end;

          _pcs := 'SELECT * FROM ' + _bf + _sorveg;
          _pcs := _pcs + 'WHERE ((TIPUS='+chr(39)+'V'+CHR(39)+') OR (';
          _pcs := _pcs + 'TIPUS='+chr(39)+'E'+CHR(39)+')) AND (';
          _pcs := _pcs + 'OSSZESEN>294000) AND (STORNO=1)';

          with vquery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
              _recno := recno;
            end;

          if _recno>0 then
            begin
              while not vquery.eof do
                begin
                  _un := angolra(Vquery.FieldByNAme('UGYFELNEV').asString);
                  _psz := trim(Vquery.fieldByNAme('PLOMBASZAM').asString);
                  _osz := vquery.Fieldbyname('OSSZESEN').asInteger;
                  _kdij := vquery.fieldByNAme('KEZELESIDIJ').asInteger;
                  _dat := vquery.fieldByNAme('DATUM').asString;
                  _tip := vquery.FieldByNAme('TIPUS').asString;
                  _biz := vquery.FieldByNAme('BIZONYLATSZAM').asString;

                  if _tip='V' then _fizetendo := _osz - _kdij
                  else _FIZETENDO := _OSZ+_KDIJ;
                  if (_fizetendo>=300000) and (_psz<'@') then
                    begin
                     _ucs := 'INSERT INTO PGYUJTO (PENZTAR,DATUM,NEV,PLOMBA,';
                     _ucs := _ucs + 'FIZETENDO,BIZONYLAT,TIPUS)'+_sorveg;
                     _ucs := _ucs + 'VALUES ('+inttostr(_pt)+',';
                     _ucs := _ucs + CHR(39) + _DAT + chr(39) + ',';
                     _ucs := _ucs + chr(39) + _un + chr(39) + ',';
                     _ucs := _ucs + CHR(39)+_psZ +chr(39)+ ',';
                     _ucs := _ucs + inttostr(_fizetendo) + ',';
                     _ucs := _ucs + chr(39) + _biz + chr(39) + ',';
                     _ucs := _ucs + chr(39) + _tip + chr(39) + ')';
                     GyParancs(_ucs);
                    end;

                  VQuery.next;
                end;
            end;

          Vquery.close;

          inc(_ho);
          if _ho>12 then
            begin
              _ho := 1;
              inc(_ev);
            end;
          _farok := inttostr(_ev)+nulele(_ho);
        end;
      Vdbase.close;
      inc(_pt);
    end;
  Showmessage('KÉSZEN VAGYOK');
end;


// =============================================================================
                function TForm1.ezetar(_ptr: byte): boolean;
// =============================================================================

begin
  result := true;
  if (_ptr=10) or (_ptr=20) or (_ptr=40) or (_ptr=50) then exit;
  if (_ptr=63) or (_ptr=75) or (_ptr=120) or (_ptr=145) then exit;
  result := false;
end;


// =============================================================================
                 function TForm1.Angolra(_huName: string): string;
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
                   function TForm1.DoubleKill(_s: string): string;
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
                   function TForm1.HutoGb(_kod: byte): byte;
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
                procedure TForm1.GyParancs(_ukaz: string);
// =============================================================================

begin
  gydbase.connected := true;
  if gytranz.InTransaction then gytranz.Commit;
  Gytranz.StartTransaction;
  with Gyquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Gytranz.Commit;
  Gydbase.close;

end;

// =============================================================================
                function Tform1.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


// =============================================================================
                 procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin
  tolhocombo.Items.clear;
  ighocombo.Items.clear;

  _y :=1;
  while _y<=12 do
    begin
      tolhocombo.Items.Add(_honev[_y]);
      ighocombo.Items.Add(_honev[_y]);
      inc(_Y);
    end;

  _aktev := yearof(date);
  _aktho := monthof(date);

  tolevcombo.Items.clear;
  igevcombo.items.clear;

  tolevcombo.Items.add(inttostr(_aktev-1));
  igevcombo.Items.Add(inttostr(_aktev-1));

  tolevcombo.Items.add(inttostr(_aktev));
  igevcombo.Items.Add(inttostr(_aktev));

  tolevcombo.itemindex := 1;
  igevcombo.itemindex  := 1;

  tolhocombo.itemindex := _aktho-1;
  ighocombo.itemindex  := _aktho-1;

  Activecontrol := Startgomb;
end;

// =============================================================================
           procedure TForm1.TOLEVCOMBOChange(Sender: TObject);
// =============================================================================

begin

  Activecontrol := Startgomb;
end;


end.
