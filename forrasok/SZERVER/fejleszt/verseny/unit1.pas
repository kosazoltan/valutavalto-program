unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, IBTable,
  Strutils, Grids, DBGrids, ExtCtrls, Buttons, ComCtrls, jpeg, dateutils;

type
  TForm1 = class(TForm)
    PROSQUERY: TIBQuery;
    PROSDBASE: TIBDatabase;
    PROSTRANZ: TIBTransaction;
    PTARQUERY: TIBQuery;
    PTARDBASE: TIBDatabase;
    PTARTRANZ: TIBTransaction;
    VTETQUERY: TIBQuery;
    VTETDBASE: TIBDatabase;
    VTETTRANZ: TIBTransaction;
    VFEJTABLA: TIBTable;
    VFEJQUERY: TIBQuery;
    VFEJDBASE: TIBDatabase;
    VFEJTRANZ: TIBTransaction;
    VERSENYQUERY: TIBQuery;
    VERSENYDBASE: TIBDatabase;
    VERSENYTRANZ: TIBTransaction;
    PENZTARTABLA: TIBTable;
    PENZTARDBASE: TIBDatabase;
    PENZTARTRANZ: TIBTransaction;
    PENZTAROSTABLA: TIBTable;
    PENZTAROSDBASE: TIBDatabase;
    PENZTAROSTRANZ: TIBTransaction;
    Shape1: TShape;
    Image1: TImage;
    Image2: TImage;
    STARTPANEL: TPanel;
    EVCOMBO: TComboBox;
    HONAPCOMBO: TComboBox;
    STARTGOMB: TBitBtn;
    Label1: TLabel;
    CSIK: TProgressBar;
    Shape3: TShape;
    Panel1: TPanel;
    BIZPANEL: TPanel;
    TPANEL: TPanel;


    procedure FormActivate(Sender: TObject);
    procedure ProsBeolvasas;
    procedure PtarBeolvasas;
    procedure JutfreeBizonylatok;
    procedure ArfolyamBeolvasas;
    procedure VersenyRogzites;
    procedure VersenyParancs(_ukaz: string);
    procedure SetpenztarSorrend;
    procedure setProsSorrend;
    procedure VersenyStart;

    function getProsnev(_id:string): string;
    function EzErtektar(_p: byte): boolean;
    function GetkonvOsszeg(_bsz: string): integer;
    function Jutalekfree(_biz: string): boolean;
    function Nulele(_int: byte):string;
    function Getproskorzet(_ids: string): integer;
    function RealToStr(_rr: real): string;
    procedure STARTGOMBClick(Sender: TObject);
    procedure EVCOMBOChange(Sender: TObject);
    procedure Panel1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);

    function HutoGb(_kod: byte): byte;
    function Angolra(_huName: string): string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _korzetszamok: array[1..8] of byte = (10,20,40,50,63,75,120,145);
  _korzetnevek: array[1..8] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
              'DEBRECEN','NYÍREGYHÁZA','BÉKÉSCSABA','PÉCS','KAPOSVÁR');

  _honev: array[1..12]of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS','MÁJUS',
                  'JÚNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
                  'NOVEMBER','DECEMBER');

  _kertev,_kerthonap,_gyujtoev,_gyujtoHonap,_aktev,_akthonap: word;
  _idDarab,_ptDarab,_code,_cc,_penztarosdarab,_pp,_szaz: integer;

  _eforg,_aforg: real;

  _elozoeviptarforgalom,_akthaviptarforgalom : array[1..150] of real;
  _elozoHaviProsforgalom,_akthaviProsforgalom: array[1..500] of real;

  _prosforg,_prosKezdij,_proswuni: array[1..900] of real;
  _idtomb,_prostomb,_idSequ: array[1..900] of string;

  _irodaNevTomb   : array[1..150] of string;
  _irodaKorzetTomb: array[1..150] of byte;

  _ptarforg,_ptsequ: array[1..150] of real;

  _penztar,_nap,_aktkorzet,_aktptnum,_evindex,_honapindex: byte;
  _bfTablanev,_btTablaNev,_arfeTablaNev,_narfTablaNev,_wunitablanev: string;
  _farok,_aktfdbPath,_tipus,_idkod,_bizonylatszam,_pcs,_vnem,_datum: string;
  _naps,_aktid,_aktnev,_idstr,_aktptnev,_elozoevhonev,_elozohonev: string;
  _akthonev,_aktevhos,_multevhos,_multhos,_prosnev: string;

  _sorveg: string = chr(13) + chr(10);
  _usdArf: array[1..31] of integer;

  _jFreeBizDarab,_osszeg,_kezdij,_xx,_bjegy,_ptardarab,_szazint,_recno: integer;
  _jFreeBiz: array[1..99] of string;

  _ezJutFree,_oev: boolean;
  _szazalek: real;
  _top,_left,_height,_width: word;

implementation

uses Unit2, Unit4, Unit5;

{$R *.dfm}


// =============================================================================
             procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

var i: integer;

begin
  _height := Screen.Monitors[0].Height;
  _width := Screen.Monitors[0].Width;

  _top := trunc((_height-400)/2);
  _left := trunc((_width-870)/2);

  Top := _top;
  Left := _left;

  // A program képét a képernyö legelejére teszi, nem takarja semmi:
//  SetWindowPos(Form1.Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE);

  _aktev := yearof(Date);
  _akthonap := monthof(date);

  evcombo.Items.Clear;
  evcombo.Items.add(inttostr(_aktev-1));
  evcombo.Items.Add(inttostr(_aktev));
  evcombo.ItemIndex := 1;

  Honapcombo.Items.Clear;
  for i := 1 to 12 do Honapcombo.Items.Add(_honev[i]);
  Honapcombo.ItemIndex := _akthonap-1;

  _idDarab := 0;
  _ptDarab := 0;

  for i := 1 to 500 do
    begin
      _idsequ[i] := '';
      _akthaviProsforgalom[i] :=0;
      _elozohaviprosforgalom[i] := 0;
    end;

  for i := 1 to 150 do
    begin
      _akthaviPtarforgalom[i] := 0;
      _elozoeviptarforgalom[i] := 0;
    end;

  Prosbeolvasas;
  Csik.Position := 8;

  PtarBeolvasas;

  Csik.Position := 15;

  StartPanel.Visible := true;
  ActiveControl := StartGomb;
end;

// =============================================================================
                procedure TForm1.STARTGOMBClick(Sender: TObject);
// =============================================================================

begin
  _evindex := evcombo.ItemIndex;
  _honapindex := Honapcombo.ItemIndex;
  _kertev := _aktev-1+_evindex;
  _kerthonap := 1+_honapindex;
  VersenyStart;
end;

// =============================================================================
                         procedure TForm1.VersenyStart;
// =============================================================================

var _ok: integer;
    _sss : real;

begin
  StartPanel.visible := false;
  Csik.Position := 20;

  _gyujtoev    := _kertev;
  _gyujtoHonap := _kertHonap;
  _aktevhos := inttostr(_kertev)+'.'+nulele(_kerthonap)+' hó';
  _oev := false;
  _ok :=Jutalek.Showmodal;
  if _ok=2 then
    begin
      Application.Terminate;
      exit;
    end;

  Form1.Repaint;
  Csik.Position := 40;

  _cc := 1;
  while _cc<=_idDarab do
    begin
      _sss := _prosforg[_cc]+_proskezdij[_cc]+_proswuni[_cc];
      _akthaviprosforgalom[_cc] := _sss;
      inc(_cc);
    end;

  // ---------------------------------------------------------------------------

  dec(_gyujtoHonap);
  if _gyujtohonap<1 then
    begin
      _gyujtoHonap := 12;
      dec(_gyujtoev);
    end;

  _multhos := inttostr(_gyujtoev)+'.'+nulele(_gyujtohonap)+' hó';
  _oev := False;
  if (_gyujtoev=2014) and (_gyujtohonap<8) then _oev := true;
  _ok := Jutalek.Showmodal;
  if _ok=2 then
    begin
      Application.terminate;
      exit;
    end;

  Form1.Repaint;
  Csik.Position := 50;

  _cc := 1;
  while _cc<=_idDarab do
    begin
      _sss := _prosforg[_cc]+_proskezdij[_cc]+_proswuni[_cc];
      _elozohaviprosforgalom[_cc] := _sss;
      inc(_cc);
    end;

  // ---------------------------------------------------------------------------

  _gyujtoev := _kertev;
  _gyujtohonap := _kerthonap;
  _oev := False;
  _ok := UjPenztarforgalom.showmodal;
  if _ok=2 then
    begin
      Application.terminate;
      exit;
    end;

  Form1.Repaint;
  Csik.Position := 60;

  _cc := 1;
  while _cc<=150 do
    begin
      _sss := _ptarforg[_cc];
      _akthaviptarforgalom[_cc] := _sss;
      inc(_cc);
    end;

   // ---------------------------------------------------------------------------

  _gyujtoev := _kertev-1;
  _gyujtohonap := _kerthonap;
  _oev := false;
  if (_gyujtoev<2014) or ((_gyujtoev=2014) and (_gyujtohonap<8)) then _oev := true;
  _ok := UjPenztarforgalom.showmodal;
  if _ok=2 then
    begin
      Application.terminate;
      exit;
    end;

  Form1.Repaint;
  _multevhos:= inttostr(_gyujtoev)+'.'+nulele(_gyujtohonap)+' hó';

  Csik.Position := 70;

  _cc := 1;
  while _cc<=150 do
    begin
      _sss := _ptarforg[_cc];
      if _oev then
        begin
          if (_cc=78) or (_cc=79) then
            begin
              inc(_cc);
              continue;
            end;
              
          if (_cc=72) or (_cc=73) then
            begin
              if _cc=72 then _elozoeviptarforgalom[79] := _sss;
              if _cc=73 then _elozoeviptarforgalom[78] := _sss;
              inc(_cc);
              continue;
            end;
         end;
      _elozoeviptarforgalom[_cc] := _sss;
      inc(_cc);
    end;

  // ---------------------------------------------------------------------------

  Form1.Repaint;
  VersenyRogzites;
  Csik.position := 75;


  SetProsSorrend;
  SetPenztarSorrend;
  Form1.repaint;
  Csik.Position := 85;

  MakeExcel.ShowModal;
  Csik.Position := 100;

end;

// =============================================================================
                      procedure TForm1.VersenyRogzites;
// =============================================================================

begin
  _pcs := 'DELETE FROM PENZTAR';
  VersenyParancs(_pcs);

  _pcs := 'DELETE FROM PENZTAROS';
  VersenyParancs(_pcs);

  _pp := 1;
  while _pp<=_idDarab do
    begin
      _aforg := _akthaviprosforgalom[_pp];
      _eforg := _elozohaviprosforgalom[_pp];

      if (_aforg>0) and (_eforg>0) then
        begin
          _aktid := _idSequ[_pp];

          _szaz     := trunc(10000 * _aforg/_eforg);
          _szazalek := _szaz/100;

          _aktnev := Getprosnev(_aktid);
          _idstr := leftstr(_aktid,3);
          _aktkorzet := getproskorzet(_idstr);

          _pcs := 'INSERT INTO PENZTAROS (IDKOD,PENZTAROSNEV,ELOZOHAVIFORGALOM,';
          _pcs := _pcs + 'EHAVIFORGALOM,KORZET,SZAZALEK)' + _sorveg;
          _pcs := _pcs + 'VALUES (' + chr(39) + _aktid + chr(39) + ',';
          _pcs := _pcs + chr(39) + _aktnev + chr(39) + ',';
          _pcs := _pcs + realtostr(_eforg) + ',';
          _pcs := _pcs + realtostr(_aforg) + ',';
          _pcs := _pcs + inttostr(_aktkorzet) + ',';
          _pcs := _pcs + realtostr(_szazalek)+ ')';
          VersenyParancs(_pcs);
        end;
      inc(_pp);
    end;

  // ===========================================================================

  _pp := 1;
  while _pp<=150 do
    begin
      _eforg := _elozoeviptarforgalom[_pp];
      _aforg := _akthaviptarforgalom[_pp];
      if (_eforg>0) and (_aforg>0) then
        begin
          _aktptnum := _pp;
          _aktptnev := _irodanevtomb[_pp];
          _idstr := inttostr(_irodakorzetTomb[_pp]);
          _aktkorzet := getproskorzet(_idstr);

          _szaz     := trunc(10000 * _aforg/_eforg);
          _szazalek := _szaz/100;

          _pcs := 'INSERT INTO PENZTAR (PENZTARSZAM,PENZTARNEV,ELOZOEVIFORGALOM,';
          _pcs := _pcs + 'EHAVIFORGALOM,KORZET,SZAZALEK)' + _sorveg;
          _pcs := _pcs + 'VALUES (' + inttostr(_aktptnum) + ',';
          _pcs := _pcs + chr(39) + _aktptnev + chr(39) + ',';
          _pcs := _pcs + realtostr(_eforg) + ',';
          _pcs := _pcs + realtostr(_aforg) + ',';
          _pcs := _pcs + inttostr(_aktkorzet) + ',';
          _pcs := _pcs + realtostr(_szazalek)+ ')';
          VersenyParancs(_pcs);
        end;
      inc(_pp);
    end;
end;


// =============================================================================
             function TForm1.Getproskorzet(_ids: string): integer;
// =============================================================================

var _korzetszam: byte;

begin
  val(_ids,_korzetszam,_code);
  if _code<>0 then _korzetszam := 10;
  result := 1;
  while result<=8 do
    begin
      if _korzetszamok[result] = _korzetszam then exit;
      inc(result)
    end;
  if result>8 then result := 1;
end;


// =============================================================================
                       procedure TForm1.ProsBeolvasas;
// =============================================================================

begin
  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAROSNEV';

  ProsDbase.Connected := True;
  with prosQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
      _cc := 0;
    end;

  while not ProsQuery.eof do
    begin
      inc(_cc);
      with ProsQuery do
        begin
          _idTomb[_cc]   := FieldByName('IDKOD').asstring;
          _prosnev := trim(FieldByname('PENZTAROSNEV').asString);
          _prosTomb[_cc] := ANGOLRA(_prosnev);
        end;
      ProsQuery.Next;
    end;
  _penztarosDarab := _cc;
  ProsQuery.close;
  ProsDbase.close;
end;

// =============================================================================
                      procedure TForm1.PtarBeolvasas;
// =============================================================================

var _ptnev: string;
    _ptkorzet: byte;

begin
  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  PtarDbase.connected := True;
  with PtarQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  while not Ptarquery.eof do
    begin
      _penztar := PtarQuery.FieldByName('UZLET').asInteger;
      if _penztar>150 then break;
      
      _ptnev   := trim(PtarQuery.FieldByName('KESZLETNEV').asString);
      _ptkorzet:= PtarQuery.FieldByName('ERTEKTAR').asInteger;

      _irodanevTomb[_penztar] := _ptnev;
      _irodakorzetTomb[_penztar] := _ptKorzet;
      Ptarquery.next;
    end;
  ptarquery.close;
  Ptardbase.close;
end;

// =============================================================================
               function TForm1.getProsnev(_id:string): string;
// =============================================================================

var _z: integer;

begin
  _z := 1;
  while _z<=_penztarosdarab do
    begin
      if _idtomb[_z]=_id then
        begin
          result := _prostomb[_z];
          exit;
        end;
      inc(_z);
    end;
  result := '????';
end;


// =============================================================================
                 function TForm1.EzErtektar(_p: byte): boolean;
// =============================================================================

var _z : byte;

begin
  result := False;
  _z := 1;
  while _z<=8 do
    begin
      if _korzetszamok[_z]=_p then
        begin
          result := True;
          break;
        end;
      inc(_z);
    end;
end;


// =============================================================================
            function TForm1.GetkonvOsszeg(_bsz: string): integer;
// =============================================================================


var _tetossz: integer;

begin

  vtetdbase.close;
  vtetdbase.databasename := _aktfdbPath;
  vtetdbase.connected := true;

  _pcs := 'SELECT * FROM ' + _btTablaNev + _sorveg;
  _pcs := _pcs + 'WHERE (BIZONYLATSZAM='+CHR(39)+_BSZ+chr(39)+') ';
  _pcs := _pcs + 'AND (ELOJEL='+chr(39)+'+'+CHR(39)+')';

  with vtetquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  result := 0;
  while not vtetquery.eof do
    begin
      _tetossz := vtetquery.fieldbyName('FORINTERTEK').asInteger;
      result := result + _tetossz;
      vtetquery.next;
    end;

  vtetquery.close;
  vtetdbase.close;
  result := trunc(2*result);
end;


// =============================================================================
            function TForm1.Jutalekfree(_biz: string): boolean;
// =============================================================================

// Megadja, hogy a paraméterben adott bizonylat jutalékmentes-e

var _y: byte;

begin
  result := false;
  if _jFreeBizdarab=0 then exit;

  _y := 1;
  while _y<=_jfreeBizDarab do
    begin
      if _jFreeBiz[_y]=_biz then
        begin
          result := true;
          exit;
        end;
      inc(_y);
    end;
end;


// =============================================================================
                 procedure Tform1.JutfreeBizonylatok;
// =============================================================================

var _biz: string;

begin
  vFejdbase.close;
  vFejdbase.DatabaseName := _aktfdbpath;
  vFejdbase.connected := true;
  vFejtabla.close;
  vFejtabla.TableName := _arfetablaNev;
  Tpanel.Caption := _arfetablanev;
  Tpanel.repaint;
  if not vFejtabla.Exists then
    begin
      _jFreebizdarab := 0;
      vFejdbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+_arfeTablanev + _sorveg;
  _pcs := _pcs + 'WHERE ENGEDMENYTIPUS=34';

  with vFejQuery do
    begin
      Close;
      Sql.clear;
      sql.Add(_pcs);
      Open;
      last;
      _jFreeBizdarab := recno;
      first;
    end;

  if _jFreeBizdarab>0 then
    begin
      _cc := 0;
      while not VFejquery.eof do
        begin
          _biz := VFejQuery.fieldByName('BIZONYLATSZAM').asString;
          inc(_cc);
          _jfreebiz[_cc] := _biz;
          vFejQuery.next;
        end;

      _jfreeBizDarab := _cc;
      vFejquery.close;
      vFejdbase.close;
    end;
end;

// =============================================================================
               function TForm1.Nulele(_int: byte):string;
// =============================================================================


begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;

//==============================================================================
                   procedure TForm1.ArfolyamBeolvasas;
// =============================================================================

var i,_elszar: integer;

begin
  for i := 1 to 31 do _usdarf[i] := 0;

  // A szegedi értéktárból olvassa a havi USD árfolyamokat;

  _pcs := 'SELECT * FROM ' + _narfTablaNev + _sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM='+chr(39)+'USD'+chr(39);

  // A szegedi értéktár adatait olvassa be ( Miért ? csak !)

  vFejDbase.close;
  vFejDbase.databasename := 'c:\receptor\database\v20.fdb';
  vFejDbase.connected := true;

  with vFejQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  // A napi USD árfolyamok az _USDARF 1..31 tömbbe kerülnek

  while not vFejQuery.eof do
    begin
      _datum  := vFejQuery.FieldByname('DATUM').asString;
      _elszar := vFejQuery.FieldByname('ELSZAMOLASIARFOLYAM').asInteger;

      _naps := midstr(_datum,9,2);
      val(_naps,_nap,_code);

      if _code<>0 then _nap := 1;

      _usdarf[_nap] := _elszar;
      vFejQuery.next;
    end;

  vFejQuery.close;
  vFejDbase.close;
end;

// =============================================================================
                procedure TForm1.VersenyParancs(_ukaz: string);
// =============================================================================

begin
  versenydbase.Connected := true;
  if versenytranz.InTransaction then Versenytranz.Commit;
  Versenytranz.StartTransaction;

  with Versenyquery do
    begin
      Close;
      sql.clear;
      sql.Add(_ukaz);
      ExecSql;
    end;
  VersenyTranz.Commit;
  VersenyDbase.close;
end;

// =============================================================================
                  function TForm1.RealToStr(_rr: real): string;
// =============================================================================

var _pos: integer;

begin
  Result := '0';
  if _rr=0 then exit;

  Result := Floattostr(_rr);
  _pos := pos(chr(44),result);
  if _pos>0 then result[_pos] := chr(46);
end;


// =============================================================================
                      procedure TForm1.SetpenztarSorrend;
// =============================================================================

var _aktk,_ss: byte;

begin

 // FocimPanel.Caption := 'A helyezések beállítása';
  PenztarDbase.Connected := True;

  if PenztarTranz.InTransaction then PenztarTranz.commit;
  PenztarTranz.StartTransaction;

  PenztarTabla.Open;
  PenztarTabla.First;

  _ss   := 0;
  _aktk := 0;

  while not PenztarTabla.eof do
    begin
      _aktkorzet := PenztarTabla.FieldByName('KORZET').asInteger;
      if _aktkorzet>_aktk then
        begin
          _ss  := 0;
          _aktk := _aktkorzet;
        end;
      inc(_ss);

      PenztarTabla.Edit;
      PenztarTabla.FieldByName('HELYEZES').asInteger := _ss;
      PenztarTabla.Post;
      PenztarTabla.next;
    end;

  PenztarTabla.IndexName := '';
  PenztarTranz.commit;
  PenztarDbase.close;
end;


// =============================================================================
                    procedure TForm1.setProsSorrend;
// =============================================================================

var _ss,_aktk: byte;

begin
  PenztarosDbase.Connected := True;
  if penztarosTranz.InTransaction then Penztarostranz.commit;
  PenztarosTranz.StartTransaction;

  PenztarosTabla.Open;
  PenztarosTabla.First;

  _ss := 0;
  _aktk := 0;

  while not PenztarosTabla.eof do
    begin
      _aktkorzet := PenztarosTabla.FieldByName('KORZET').asInteger;
      if _aktkorzet>_aktk then
        begin
          _ss := 0;
          _aktk := _aktkorzet;
        end;
      inc(_ss);

      with PenztarosTabla do
        begin
          Edit;
          FieldByName('HELYEZES').asInteger := _ss;
          Post;
        end;

      PenztarosTabla.Next;
    end;

  PenztarosTranz.commit;
  PenztarosDbase.close;

//  FocimPanel.Caption := 'A helyezések sikeresen beállítva !';
//  Focimpanel.Repaint;

end;

// =============================================================================
               procedure TForm1.EVCOMBOChange(Sender: TObject);
// =============================================================================

begin
  ActiveControl := StartGomb;
end;

// =============================================================================
                procedure TForm1.Panel1Click(Sender: TObject);
// =============================================================================

begin
  Application.terminate;
end;



procedure TForm1.Button1Click(Sender: TObject);

var _ok: integer;

begin
   _gyujtoev := _kertev-1;
  _gyujtohonap := _kerthonap;
  _ok := UjPenztarforgalom.showmodal;
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



end.
