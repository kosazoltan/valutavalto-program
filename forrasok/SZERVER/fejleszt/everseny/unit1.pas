unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBCustomDataSet, IBQuery, Comobj,dateutils,
  StdCtrls, Buttons, ComCtrls, IBTable, ExtCtrls,TlHelp32, strutils, jpeg;


type
  TForm1 = class(TForm)
    QUITGOMB: TBitBtn;
    Label1: TLabel;
    ACTABLA: TIBTable;
    ACQUERY: TIBQuery;
    ACDBASE: TIBDatabase;
    ACTRANZ: TIBTransaction;
    PROSQUERY: TIBQuery;
    PROSDBASE: TIBDatabase;
    PROSTRANZ: TIBTransaction;
    ACVQUERY: TIBQuery;
    ACVTABLA: TIBTable;
    ACVDBASE: TIBDatabase;
    ACVTRANZ: TIBTransaction;
    STARTGOMB: TBitBtn;
    VERSENYQUERY: TIBQuery;
    VERSENYDBASE: TIBDatabase;
    VERSENYTRANZ: TIBTransaction;
    VERSENYTABLA: TIBTable;
    FASTCSIK: TProgressBar;
    Shape1: TShape;
    EVCOMBO: TComboBox;
    HOCOMBO: TComboBox;
    TAKARO: TPanel;
    Shape2: TShape;
    Image1: TImage;
    Shape3: TShape;
    Label2: TLabel;
    Image2: TImage;

    procedure BitBtn2Click(Sender: TObject);
    procedure STARTGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure PTarbeolvasas;
    procedure PtarosBeolvasas;
    procedure HaviBlokkRead(_sTipss: byte);
    procedure HaviWuniRead(_sTipss: byte);
    procedure adatFeliras;
    procedure VersenyParancs(_ukaz: string);
    procedure MakeExcel;
    procedure TablaRajzolas;
    procedure ExcelKill;
    procedure AdatFeltoltes;
    procedure QuitGombClick(Sender: TObject);
    procedure HelyezesIras;
    procedure VastagKeret(_rs: string);
    procedure VekonyKeret(_rs: string);

    function Angolra(_huName: string): string;
    function Nulele(_b: byte): string;
    function HutoGb(_kod: byte): byte;
    function GetusdArfolyam: integer;
    function Idcontrol(_i,_p: string): boolean;
    function scanidkod(_aktid: string): word;
    function RealToStr(_rr: real): string;
    function Ketdec(_sz: real): real;
    procedure EVCOMBOChange(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

   _honev: array[1..12]of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS','MÁJUS',
                  'JÚNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
                  'NOVEMBER','DECEMBER');

  _kertev: word;
  _kertho: word;

  _ptarszam: array[1..20] of byte;
  _ptarnev : array[1..20] of string;

  _ptarosnev,_ptarosid: array[1..800] of string;
  _aktwuni,_aktNarf,_dn: string;

  _livpros,_livptar: word;
  _prossor : array[1..800] of string;
  _penztarsor: array[1..20] of byte;

  _OXL,_owb,_range: OleVariant;

  _ptarindex,_ptardarab,_prosindex,_ptarosdarab,_xx: word;
  _eev,_eho,_aktpenztarnum,_helyezes,_ptSumRow: word;
  _firstProsRow,_sorindex,_pindex: word;

  _akthaviforg,_eeviforg,_elohaviforg: real;
  _szazalek,_szaz: real;

  _farok,_eevifarok,_ehavifarok,_aktprosnev,_aktidkod,_rangestr,_formula: string;
  _ahobf,_ahobt,_ahonarf,_ahowuni: string;
  _eevbf,_eevbt,_eevnarf,_eevwuni: string;
  _ehobf,_ehobt,_ehonarf,_ehowuni: string;
  _fdbpath,_pcs,_multevhos,_aktevhos,_multhos,_aktptarnev,_pnev,_szazas: string;
  _prosid,_prosnev,_atlagszazas,_mt,_nn,_SS: string;

  _ehavi,_eevi,_elohavi,_akthavi: integer;
  _sumLastYear,_sumThisYear,_atlagszaz: real;

  _lastPtRow,_focim2sor,_lastProsRow,_firstPtRow,_xSor,_pnum: word;
  _ppos,_pp: byte;

  _sorveg: string = chr(13)+chr(10);

  _ft,_bj,_usdarfolyam: integer;
  _id,_pn: string;

  _prosft: array[1..800,1..3] of real;
  _ptarft: array[1..20,1..3] of real;

  proc : PROCESSENTRY32;
  _handle : HWND;
  _Looper : BOOL;

  _top,_left,_width,_height,_evindex,_hoindex,_maiev,_maiho: word;


implementation



{$R *.dfm}

// =============================================================================
               procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

var i,j: word;

begin
  _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  _top  := trunc((_height-665)/2);
  _left := trunc((_width-820)/2);

  Top  := _top;
  Left := _left;

  for i := 1 to 3 do
    begin
      for j := 1 to 600 do _prosFt[j,i] := 0;
      for j := 1 to 20 do _ptarft[j,i] := 0;
    end;
  _livpros := 0;
  _livPtar := 0;

   PtarBeolvasas;
  PtarosBeolvasas;

  _maiev := yearof(Date);
  _maiho := monthof(date);

  evcombo.Items.clear;
  hocombo.Items.clear;

  evcombo.Items.Add(inttostr(_maiev-1));
  evcombo.Items.Add(inttostr(_maiev));
  evcombo.ItemIndex := 1;

  for i := 1 to 12 do Hocombo.Items.Add(_honev[i]);
  hocombo.itemindex := _maiho-1;

  ActiveControl := startGomb;

end;


// =============================================================================
             procedure TForm1.STARTGOMBClick(Sender: TObject);
// =============================================================================

begin

  startgomb.Enabled := false;

  _evindex := evcombo.itemindex;
  _hoindex := hocombo.itemindex;

  _kertev := _evindex - 1 + _maiev;
  _kertho := 1 + _hoindex;

  _aktevhos := inttostr(_kertev)+' '+nulele(_kertho)+' hónap';

  _farok   := inttostr(_kertev-2000) + nulele(_kertho);

  _AHOBF   := 'BF' + _farok;
  _AHOBT   := 'BT' + _farok;
  _AHONARF := 'NARF' + _farok;
  _AHOWUNI := 'WUNI' + _farok;

  _eevifarok := inttostr(_kertev-2001)+ nulele(_kertho);

  _EEVBf := 'BF' + _eevifarok;
  _EEVBt := 'BT' + _eevifarok;
  _EEVNarf := 'NARF' + _eevifarok;
  _EEVWuni := 'WUNI' + _eevifarok;

  _multevhos := '20' + leftstr(_eevifarok,2)+' '+midstr(_eevifarok,3,2)+' hónap';

  _eev := _kertev;
  _eho := _kertho-1;
  if _eho=0 then
    begin
      _eho := 12;
      dec(_eev);
    end;

  _ehavifarok := inttostr(_eev-2000)+nulele(_eho);
  _EHOBF := 'BF' + _ehavifarok;
  _EHOBT := 'BT' + _ehavifarok;
  _EHONarf := 'NARF' + _ehavifarok;
  _EHOWuni := 'WUNI' + _ehavifarok;

  _multhos := '20' + leftstr(_ehavifarok,2)+' '+midstr(_ehavifarok,3,2)+' hónap';

  // ---------------------------------------------------------------

  _ptarIndex := 1;
  _pp := 0;
  Fastcsik.Position := 135;
  
  while _ptarindex<=_ptardarab do
    begin
      _aktpenztarnum := _ptarszam[_ptarindex];
      _fdbPath := 'c:\RECEPTOR\database\v' + inttostr(_aktpenztarnum)+'.FDB';
      if not FileExists(_fdbPath) then
        begin
          inc(_ptarindex);
          Continue;
        end;

      Acvdbase.close;
      AcvTabla.close;
      Acvdbase.DatabaseName := _fdbpath;

      AcvDbase.Connected := true;
      AcvTabla.TableName := _AHOBF;
      if Acvtabla.Exists then HaviBlokkRead(1);


      AcvTabla.TableName := _AHOWUNI;
      if Acvtabla.Exists then HaviWuniRead(1);

      // ------------------------------------------

       AcvTabla.TableName := _EHOBF;
      if Acvtabla.Exists then HaviBlokkRead(2);

      AcvTabla.TableName := _EHOWUNI;
      if Acvtabla.Exists then HaviWuniRead(2);

      // ------------------------------------------

      AcvTabla.TableName := _EEVBF;
      if Acvtabla.Exists then HaviBlokkRead(3);

      AcvTabla.TableName := _EEVWUNI;
      if Acvtabla.Exists then HaviWuniRead(3);

      // ------------------------------------------

      Acvdbase.close;
      inc(_ptarindex);
    end;

  fastcsik.Position := 130;
  AdatFeliras;
  fastcsik.Position := 131;
  HelyezesIras;
  fastcsik.Position := 132;
  TablaRajzolas;
  Fastcsik.Position := 133;
  Adatfeltoltes;
  Fastcsik.Position := 135;
  _oxl.visible      := True;
  Takaro.Visible    := False;
  Fastcsik.Visible  := False;
end;


// =============================================================================
              function TForm1.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


// =============================================================================
                       procedure TForm1.PtarBeolvasas;
// =============================================================================

var _u: byte;
    _n: string;

begin
  _ptardarab := 0;

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE (CLOSED='+chr(39)+'N'+chr(39)+') AND (UZLET>151)'+_sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  Acdbase.connected := true;
  with AcQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;


  while not AcQuery.eof do
    begin
      _u := Acquery.fieldbyname('UZLET').asInteger;
      _n := trim(Acquery.FieldByName('KESZLETNEV').asString);
      inc(_ptardarab);
      _ptarszam[_ptardarab] := _u;
      _ptarnev[_ptardarab] := _n;
      AcQuery.next;
    end;
  AcQuery.close;
  Acdbase.close;

end;

// =============================================================================
                      procedure TForm1.PtarosBeolvasas;
// =============================================================================

var _pnev,_id: string;

begin
  _ptarosdarab := 0;
  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAROSNEV';

  Prosdbase.connected := true;
  with ProsQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not Prosquery.eof do
    begin
      _pnev := trim(ProsQuery.FieldByName('PENZTAROSNEV').asString);
      _id   := trim(Prosquery.FieldByNAme('IDKOD').asString);

      inc(_ptarosdarab);
      _ptarosid[_ptarosdarab] := _id;
      _pnev := angolra(_pnev);
      _ptarosnev[_ptarosdarab] := _pnev;
      Prosquery.next;
    end;
  Prosquery.close;
  Prosdbase.close;
end;

// =============================================================================
               procedure TForm1.HaviBlokkRead(_sTipss: byte);
// =============================================================================

// _stipss = 1='AHO' (kerthavi) , 2='EHO' (elözöhavi) 3='EEV' (elözöévi)

var _aktbf,_aktbt: string;

begin
  inc(_pp);
  Fastcsik.Position := _pp;

  if _sTipss = 1 then
    begin
      _aktbf := _ahoBF;
      _aktbt := _ahoBT;
    end;

  if _sTipss = 2 then
    begin
      _aktbf := _ehoBF;
      _aktbt := _ehoBt;
    end;

  if _sTipss = 3 then
    begin
      _aktbf := _eevBF;
      _aktbt := _eevBT;
    end;

  _pcs := 'SELECT * FROM ' + _aktBF + _sorveg;
  _pcs := _pcs + 'WHERE ((TIPUS='+chr(39)+'V'+chr(39)+')';
  _pcs := _pcs + ' OR (TIPUS='+CHR(39)+'E'+chr(39) +'))';
  _pcs := _pcs + ' AND (STORNO=1)';

  with AcvQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not AcvQuery.eof do
    begin
      _ft := AcvQuery.FieldByNAme('OSSZESEN').asInteger;
      _pn := trim(AcvQuery.FieldByNAme('PENZTAROSNEV').asString);
      _id := trim(AcvQuery.FieldByNAme('IDKOD').asString);

      if not Idcontrol(_id,_pn) then
        begin
          showmessage(inttostr(_aktpenztarnum)+'. pt -> BF hiba = '+_pn+','+_id);
          Acvquery.close;
          Acvdbase.close;
          Halt;
          exit;
        end;

      _xx := Scanidkod(_id);
      _prosft[_xx,_stipss] := _prosft[_xx,_stipss] + _ft;
      _pindex := _ptarindex;

      _ptarft[_pindex,_stipss] := _ptarft[_pindex,_stipss] + _ft;
      AcvQuery.next;
    end;
 
  AcvQuery.close;
end;

// =============================================================================
                 procedure TForm1.HaviWuniRead(_stipss: byte);
// =============================================================================

begin
  inc(_pp);
  Fastcsik.Position := _pp;

  if _sTipss = 1 then
    begin
      _aktwuni := _ahoWuni;
      _aktnarf := _ahoNarf;
    end;

  if _sTipss = 2 then
    begin
      _aktWuni := _ehoWuni;
      _aktNarf := _ehoNarf;
    end;

  if _sTipss = 3 then
    begin
      _aktwuni := _eevWuni;
      _aktNarf := _eevNarf;
    end;

  _usdarfolyam := GetUsdArfolyam;

  _pcs := 'SELECT * FROM ' + _aktWuni + _sorveg;
  _pcs := _pcs + 'WHERE (FOEGYSEG=5) AND (STORNO=1)';

  with AcvQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _nn := AcvDbase.databaseName;
  while not AcvQuery.eof do
    begin
      _ss := AcvQuery.FieldByName('SORSZAM').ASSTRING;
      _mt := AcvQuery.FieldByName('MTCNSZAM').asstring;
      _bj := AcvQuery.FieldByNAme('BANKJEGY').asInteger;
      _pn := trim(AcvQuery.FieldByNAme('PENZTAROSNEV').asString);
      _id := trim(AcvQuery.FieldByNAme('IDKOD').asString);
      _dn := acvquery.FieldByname('VALUTANEM').asstring;

      if not Idcontrol(_id,_pn) then
        begin
          showmessage(inttostr(_aktpenztarnum)+'. pt -> wuni-hiba = '+_pn+','+_id);
          Acvquery.close;
          Acvdbase.close;
          Halt;
          exit;
        end;

      _xx := Scanidkod(_id);

      if _usdarfolyam=0 then _usdarfolyam := 290;
      if _dn='USD' then _bj := trunc(_bj/100*_usdarfolyam);

      _prosft[_xx,_stipss] := _prosft[_xx,_stipss] + _bj;
      _ptarft[_ptarindex,_stipss] := _ptarft[_ptarindex,_stipss] + _bj;

      AcvQuery.next;
    end;
  AcvQuery.close;
end;


// =============================================================================
                      function TForm1.GetusdArfolyam: integer;
// =============================================================================

begin
  Acvtabla.close;
  acvtabla.TableName := _aktnarf;
  if not acvtabla.Exists then
    begin
      result := 290;
      exit;
    end;  

 
  _pcs := 'SELECT * FROM ' + _aktNarf + _sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39) + 'USD' + chr(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  WITH ACVQUERY DO
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      last;
      result := Fieldbyname('ELSZAMOLASIARFOLYAM').asInteger;
      Close;
    end;
end;

// =============================================================================
              function TForm1.Idcontrol(_i,_p: string): boolean;
// =============================================================================

var _y: word;

begin
  result := False;
  _p := angolra(_p);
  _Y := 1;
  while _y<=_ptarosdarab do
    begin
      if _ptarosid[_y]=_i then
        begin
          if _p=_ptarosnev[_y] then result := True;
          exit;
        end;
      inc(_y);
    end;
end;


// =============================================================================
             function TForm1.scanidkod(_aktid: string): word;
// =============================================================================

var _y: word;

begin
  result := 0;
  _y :=1;
  while _y<=_ptarosdarab do
    begin
      if _ptarosid[_y]=_aktid then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;


// =============================================================================
               procedure TForm1.BitBtn2Click(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;

// =============================================================================
                            procedure TForm1.AdatFeliras;
// =============================================================================

begin
  _pcs := 'DELETE FROM PENZTAR';
  VersenyParancs(_pcs);

  _pcs := 'DELETE FROM PENZTAROS';
  VersenyParancs(_pcs);

  _sumLastyear:= 0;
  _sumThisYear:= 0;

  _livptar   := 0;
  _ptarindex := 1;
  while _ptarindex<=_ptardarab do
    begin
      _aktpenztarnum := _ptarszam[_ptarindex];
   //   if _aktpenztarnum=160 then _aktpenztarnum := 154;
      _aktPtarnev    := _ptarnev[_ptarindex];
      _akthaviforg   := _ptarft[_ptarindex,1];
      _eeviforg      := _ptarFt[_ptarindex,3];

      if (_akthaviforg=0) and (_eeviforg=0) then
         begin
           inc(_ptarindex);
           Continue;
         end;


      _szazalek := 0;
      if _eeviforg>0 then
        begin
          _szazalek := 100*_akthaviforg/_eeviforg;
          _sumLastYear := _sumLastYear + _eeviforg;
          _sumThisYear := _sumThisYear + _akthaviforg;
        end;

      _szazalek := ketdec(_szazalek);

      _pcs := 'INSERT INTO PENZTAR (PENZTARSZAM,PENZTARNEV,EHAVIFORGALOM,';
      _pcs := _pcs + 'ELOZOEVIFORGALOM,SZAZALEK)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + inttostr(_aktpenztarnum) + ',';
      _pcs := _pcs + chr(39) + _aktptarnev + chr(39) + ',';
      _pcs := _pcs + realtostr(_akthaviforg) + ',';
      _pcs := _pcs + realtostr(_eeviforg)+',';
      _pcs := _pcs + realtostr(_szazalek)+')';

      VersenyParancs(_pcs);

      inc(_livptar);
      _penztarsor[_livptar] := _aktpenztarnum;

      inc(_ptarindex);
    end;

  _atlagszaz := 100*_sumThisYear/_sumLastYear;
  _atlagszaz := ketdec(_atlagszaz);
  _atlagszazas := realtostr(_atlagszaz);

  _livpros   := 0;
  _prosindex := 1;
  while _prosindex<=_ptarosdarab do
    begin
      _aktidkod    := _ptarosid[_prosindex];
      _aktprosnev  := _ptarosnev[_prosindex];

      _elohaviforg := _prosft[_prosindex,2];
      _akthaviforg := _prosft[_prosindex,1];

      if (_elohaviforg=0) and (_akthaviforg=0) then
        begin
          inc(_prosindex);
          Continue;
        end;

      _szazalek := 0;
      if _elohaviforg>0 then _szazalek := 100*_akthaviforg/_elohaviforg;
      _szazalek := ketdec(_szazalek);

      _pcs := 'INSERT INTO PENZTAROS (IDKOD,PENZTAROSNEV,ELOZOHAVIFORGALOM,';
      _pcs := _pcs + 'EHAVIFORGALOM,SZAZALEK)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + CHR(39) + _aktidkod + chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktprosnev + chr(39) + ',';
      _pcs := _pcs + realtostr(_elohaviforg) + ',';
      _pcs := _pcs + realtostr(_akthaviforg) + ',';
      _pcs := _pcs + realtostr(_szazalek)+')';

      VersenyParancs(_pcs);

      inc(_livpros);
      _prossor[_livpros] := _aktidkod;

      inc(_prosindex);
    end;
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
             procedure Tform1.VersenyParancs(_ukaz: string);
// =============================================================================

begin
  VersenyDbase.connected := true;
  if versenytranz.InTransaction then Versenytranz.Commit;
  VersenyTranz.StartTransaction;
  with VersenyQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  VersenyTranz.commit;
  Versenydbase.close;
end;


function TForm1.Ketdec(_sz: real): real;

var _szint: integer;

begin
  _szint := trunc(100*_sz);
  result := _szint/100;
end;


// =============================================================================
//                         EXCEL-KÉSZITÉSE
// =============================================================================


procedure TForm1.MakeExcel;

begin
 
  TablaRajzolas;
  _oxl.Visible;
end;


// =============================================================================
                 procedure TForm1.TablaRajzolas;
// =============================================================================

begin
   _oxl := CreateOleObject('Excel.Application');
  _owb := _oxl.workbooks.add[1];

  _firstPtRow := 8;

  // Az oszlop szélességek beállitása:

  _oxl.Range['A1:A1'].columnWidth := 10;
  _oxl.Range['B1:B1'].columnWidth := 12;
  _oxl.Range['C1:C1'].columnWidth := 40;
  _oxl.Range['D1:D1'].columnWidth := 24;
  _oxl.Range['E1:E1'].columnWidth := 24;
  _oxl.Range['F1:F1'].columnWidth := 18;
  _oxl.Range['G1:G1'].columnWidth := 14;

  // Fõcim felirata:

  _rangestr := 'B2:G2';
  _oxl.Range[_rangestr].Mergecells := True;
  _oxl.Range[_rangestr].Font.Name := 'Times New Roman';
  _oxl.Range[_rangestr].Font.Size := 18;
  _oxl.Range[_rangestr].Font.Bold := True;
  _oxl.Range[_rangestr].Font.Italic := True;
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.Cells[2,2] := 'EXPRESSZ-ZÁLOG VERSENYADATAI';

  // széles üres sor:

  _rangestr := 'B3:G3';
  _oxl.Range[_rangestr].Font.Size := 18;

  // Pénztárak helyezésai felirat:

  _rangestr := 'B4:G4';
  _oxl.Range[_rangestr].Mergecells := True;
  _oxl.Range[_rangestr].Font.Name := 'Times New Roman';
  _oxl.Range[_rangestr].Font.Size := 14;
  _oxl.Range[_rangestr].Font.Bold := True;
  _oxl.Range[_rangestr].Font.Italic := True;
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;

  _oxl.cells[3,4] := _aktevhos;
  _oxl.Cells[4,2] := 'PÉNZTÁRAK HELYEZÉSEI';

  // Az utolsó pénztár sora:

  _lastPtRow := _firstptRow +_livptar -1;

  // széles üres sor az 5-ik sor:

  _rangestr := 'B5:G5';
  _oxl.Range[_rangestr].Font.Size := 14;

  // Pénztár nevek betümérete = 11

  _rangestr := 'C8:C'+inttostr(_lastptRow);
  _oxl.Range[_rangestr].Font.Size := 11;

  // Fejléc: 2 cella merge = 'PÉNZTÁR'

  _oxl.Range['B6:C6'].Mergecells := true;

  // Fejléc: 2 cella összenyitva = 'FORGALOM'

  _oxl.Range['D6:E6'].mergecells := True;

  // a TELJES FEJLÉC BETüTIPUS= Times Bold és Italic

  _oxl.Range['B6:G7'].Font.Name  := 'Times New Roman';
  _oxl.Range['B6:G7'].Font.Bold  := True;
  _oxl.Range['B6:G7'].Font.Italic:= True;

   // A fejléc két elsõ oszlopa-elsõ sora betüméret = 12;

  _oxl.Range['B6:E6'].Font.Size := 12;

  // A fejléc elsõ 2 oszlopa-második sora betüméret: 10 (száma,megnevezése)

  _oxl.Range['B7:E7'].Font.Size := 10;

  // A százalék fejléce két egymásalatti cella merge (SZÁZALÉKOS NÖVEKEDÉS)
  // sortörés megengedése:

  _oxl.Range['F6:F7'].Mergecells := True;
  _oxl.Range['F6:F7'].Wraptext := True;

  // A 'HELYEZÉS' fejlév 2 egymásalatti cella merge (HELYEZÉS) középen

  _oxl.Range['G6:G7'].Mergecells := True;
  _oxl.Range['B6:G7'].VerticalAlignment := -4108;

  //  A teljes fejléc szövege középre rendezve:

  _oxl.Range['B6:G7'].HorizontalAlignment := -4108;

  // A fejléc szövegeinek beirása:

  _oxl.Cells[6,2] := 'PÉNZTÁR';
  _oxl.Cells[6,4] := 'FORGALOM';
  _oxl.Cells[7,2] := 'SZÁMA';
  _oxl.Cells[7,3] := 'MEGNEVEZÉSE';

  _oxl.Cells[7,4] := _multevhos;
  _oxl.Cells[7,5] := _aktevhos;

  _oxl.Cells[6,6] := 'SZÁZALÉKOS NÕVEKEDÉS';
  _oxl.Cells[6,7] := 'HELYEZÉS';

  // A pénztár összesen sor kialakitása:

  _ptSumRow := _lastPtRow + 1;

  _rangeStr := 'B'+inttostr(_ptSumRow)+':C'+inttostr(_ptSumRow);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.Range[_rangestr].Mergecells := true;
  _oxl.Cells[_ptSumrow,2] := 'ÖSSZESEN';
  _oxl.Cells[_ptSumrow,2].Font.Name := 'Times New Roman';
  _oxl.Cells[_ptSumrow,2].Font.Bold := True;
  _oxl.Cells[_ptSumrow,2].Font.Italic := True;
  _oxl.Cells[_ptSumrow,2].Font.Size := 12;

  // elözöévi forgalom összes sora

  _formula := '=sum(D8:D'+inttostr(_lastptRow)+')';
  _oxl.Cells[_ptSumRow,4].formula := _formula;

  // akt havi  forgalom összes sora:

  _formula := '=sum(E8:E'+inttostr(_lastptRow)+')';
  _oxl.Cells[_ptSumRow,5].formula := _formula;

  // Az átlagos növekedés %-ka:

  _oxl.Cells[_ptSumRow,6] := _atlagszazas;

  // A jobb-alsó sarok befeketitve ( nincs használatban)

  _oxl.Cells[_ptSumRow,7].Interior.color := clGray;

  // ------------------ BORDERS ------------------------------------------------


  // A pénztár helyezés táblázata:

  _rangestr := 'B6:G'+inttostr(_ptSumRow);
  Vekonykeret(_rangestr);

  // A fejléc kerete:

  VekonyKeret('B6:G7');

  // Az elözöévi adatok kerete:

  _rangestr := 'D6:D'+inttostr(_ptSumRow);
  VekonyKeret(_rangestr);

  // Akt havi adatok keretei:

  _rangestr := 'E6:E'+inttostr(_ptSumRow);
  VekonyKeret(_rangestr);

  // százalékos növekedés keret:

  _rangestr := 'F6:F'+inttostr(_ptSumRow);
  VekonyKeret(_rangestr);

  // AZ alsó összesen sor kerete:

  _rangestr := 'B'+inttostr(_ptSumRow)+':G'+ inttostr(_PtSumRow);
  VekonyKeret(_rangestr);

  // A teljes adat cellák betüinek kialakitása:

  _rangestr := 'C8:C' +inttostr(_lastPtRow);
  _oxl.Range[_rangestr].Font.Size := 11;
  _oxl.Range[_rangestr].Font.Name := 'Times New Roman';
  _oxl.Range[_rangestr].Font.Italic := true;

  // A pénztárszámok középre rendezése:

  _rangestr := 'B8:B' + inttostr(_lastPtRow);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;

  //  A forgalmi adatok formázása:

   _rangestr := 'D8:E'+inttostr(_ptSumRow);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.Range[_rangestr].Numberformat := '### ### ### ###0[$ Ft]';

  // Százalékos növekedés adatoszlopának formázáse:

  _rangestr := 'F8:F'+inttostr(_ptSumRow);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.Range[_rangestr].Numberformat := '###,###0[$ %]';

  // Helyezések számainak középre rendezése:

  _rangestr := 'G8:G'+inttostr(_lastPtRow);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;

  Vekonykeret('B6:E6');

  _rangestr := 'B7:B' +inttostr(_lastptrow);
  VekonyKeret(_rangestr);

  _rangestr := 'B6:G' + inttostr(_ptSumRow);
  VastagKeret(_rangestr);

  _rangestr := 'B' + inttostr(_ptSumRow)+':G' + inttostr(_ptSumRow);
  VastagKeret(_rangestr);

  Vastagkeret('B6:G7');
  _rangestr := 'D6:E' + inttostr(_ptSumRow);
  VastagKeret(_rangestr);




  // =========== 2. aLSÓ TÁBLA (pénztárosok helyezései) ========================

  // Pénztárosok helyezéseinek fõcimsora:

  _foCim2Sor := _ptSumrow + 3;
  _rangestr := 'B' + inttostr(_focim2Sor)+':G' + inttostr(_focim2sor);

  _oxl.Cells[_focim2sor,2] := 'PÉNZTÁROSOK HELYEZÉSEI';

  _oxl.Range[_rangestr].Mergecells := true;
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.Range[_rangestr].Font.Name := 'Times New Roman';
  _oxl.Range[_rangestr].Font.Size := 14;
  _oxl.Range[_rangestr].Font.Bold := True;
  _oxl.Range[_rangestr].Font.Italic := True;

  // Az utolsó pénztáros sora:

  _firstProsRow := _focim2Sor + 4;
  _lastProsRow  :=  _firstProsRow + _livpros-1;

  // Alsó tábla fejléc kialakitása: (PÉNZTÁROS ÉS FORGALOM BETÜMÉRET=12);

  _rangestr := 'B'+inttostr(_focim2sor+2)+':E'+inttostr(_focim2sor+2);
  _oxl.Range[_rangestr].Font.Size := 12;

  // fEJLÉC 2. sora elsõ 4 oszlop (betüméret= 10):

  _rangestr := 'B'+inttostr(_focim2sor+3)+':E'+inttostr(_focim2sor+3);
  _oxl.Range[_rangestr].Font.Size := 10;

  // a fejléc PÉNZTÁROS oszlopa 2 oszlop összenyitása:

  _rangestr := 'B' + inttostr(_focim2sor+2)+':C' + inttostr(_focim2sor+2);
  _oxl.Range[_rangestr].Mergecells := true;

  // a fejléc FORGALOM oszlopa (2 oszlop összenyitása):

  _rangestr := 'D' + inttostr(_focim2sor+2)+':E' + inttostr(_focim2sor+2);
  _oxl.Range[_rangestr].Mergecells := true;

  // A fejléc elsö sora ( középre - bold  - italic):

  _rangestr := 'B' + inttostr(_focim2sor+2)+':G' + inttostr(_focim2sor+2);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.Range[_rangestr].Font.Bold := True;
  _oxl.Range[_rangestr].Font.Italic := True;

  // A százalékos fejléc 2 sor összenyitása:

  _rangestr := 'F' + inttostr(_focim2sor+2)+':F' + inttostr(_focim2sor+3);
  _oxl.Range[_rangestr].Mergecells := true;

  // A helyezés fejléc 2 sor összenyitása:

  _rangestr := 'G' + inttostr(_focim2sor+2)+':G' + inttostr(_focim2sor+3);
  _oxl.Range[_rangestr].Mergecells := true;

  //  A két utolsó oszlop fejléc betümérete = 10;

  _rangestr := 'F'+inttostr(_focim2sor+2)+':G'+inttostr(_focim2sor+3);
  _oxl.Range[_rangestr].Font.size := 12;

  // A százalék fejléc beállitás (all-center, wraptext)

  _rangestr := 'F' + inttostr(_focim2sor+2)+':F'+inttostr(_focim2sor+3);
  _oxl.Range[_rangestr].Wraptext := True;
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.Range[_rangestr].VerticalAlignment := -4108;

  // A HELYEZÉS fejléc felirat középre rendezése:

  _rangestr := 'G' + inttostr(_focim2sor+2)+':G'+inttostr(_focim2sor+3);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.Range[_rangestr].VerticalAlignment := -4108;

  // a fejléc szövegeinek beirása:

  _oxl.Cells[_focim2sor+2,2] := 'PÉNZTÁROS';
  _oxl.Cells[_focim2sor+2,4] := 'FORGALOM';
  _oxl.Cells[_focim2sor+2,6] := 'SZÁZALÉKOS NÕVEKEDÉS';
  _oxl.Cells[_focim2sor+2,7] := 'HELYEZÉS';

  // A föcim második sor szövegek beállitása:

  _rangestr := 'B' + inttostr(_focim2sor+3)+':E' +inttostr(_focim2sor+3);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.Range[_rangestr].Font.Italic := true;
  _oxl.Range[_rangestr].Font.Bold := true;

  // A fejléc alsó sorának szövegei beirása:

  _oxl.Cells[_focim2sor+3,2] := 'ID-KÓDJA';
  _oxl.Cells[_focim2sor+3,3] := 'NEVE';
  _oxl.Cells[_focim2sor+3,4] := _multhos;
  _oxl.Cells[_focim2sor+3,5] := _aktevhos;

  //  A teljes pénztáros adatok betüinek kialakitása:

  _rangestr := 'C' + inttostr(_firstProsRow)+':C' +inttostr(_lastProsRow);
  _oxl.Range[_rangestr].Font.Size := 11;
  _oxl.Range[_rangestr].Font.Name := 'Times New Roman';
  _oxl.Range[_rangestr].Font.Italic := true;

  // ------------------ BORDERS ------------------------------------------------

  // A teljes alsó tábla kerete:

  _rangestr := 'B'+inttostr(_focim2sor+2)+':G'+inttostr(_lastProsRow);
  VekonyKeret(_rangestr);

  // A fejléc keretezése:

  _rangestr := 'B' + inttostr(_focim2sor+2)+':G'+ inttostr(_focim2sor+3);
  Vekonykeret(_rangestr);

  // Mult havi forgalom adatoszlop kerete:

  _rangestr := 'D'+inttostr(_focim2sor+2)+':D'+inttostr(_lastProsRow);
  VekonyKeret(_rangestr);

  // E-havi forgalom  adatoszlop keretei:

  _rangestr := 'E'+inttostr(_focim2sor+2)+':E'+inttostr(_lastProsRow);
  VekonyKeret(_rangestr);

  // A százalékos adatoszlop kerete:

  _rangestr := 'F'+inttostr(_focim2sor+2)+':F'+inttostr(_lastProsRow);
  VekonyKeret(_rangestr);

  // ---------------------------------------------------------------------------

   // Id-kódok középre:

  _rangestr := 'B' + inttostr(_firstprosRow)+':B'+inttostr(_lastprosRow);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;

  // ---------------------------------------------------------------------------

  // A forgalmi adatok számainak formázása:

  _rangestr := 'D'+ inttostr(_firstProsRow)+':E'+inttostr(_lastProsRow);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.Range[_rangestr].Numberformat := '### ### ### ###0[$ Ft]';

  // A százalékos növekedés oszlopának formázása:

  _rangestr := 'F' + inttostr(_firstprosRow)+':F'+inttostr(_lastProsRow);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.Range[_rangestr].Numberformat := '###,###0[$ %]';

  // Helyezés oszlopának formázása:

  _rangestr := 'G' + inttostr(_firstProsRow)+':G'+inttostr(_lastProsRow);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'B' + inttostr(_firstprosrow-1)+':E'+inttostr(_firstprosrow-1);
  VekonyKeret(_rangestr);

  _rangestr := 'B' + inttostr(_firstprosRow-1)+':B'+inttostr(_lastProsRow);
  VekonyKeret(_rangestr);

  _rangestr := 'B' + inttostr(_firstprosRow-2)+':G'+INTTOSTR(_firstprosRow-1);
  Vastagkeret(_rangestr);

  _rangestr := 'B' + inttostr(_firstProsRow-2)+':G'+inttostr(_lastProsRow);
  VastagKeret(_rangestr);

  _rangestr := 'D'+inttostr(_firstProsRow-2)+':E'+inttostr(_lastProsRow);
  VastagKeret(_rangestr);

end;


procedure TForm1.HelyezesIras;

begin
  Versenydbase.connected := True;
  if Versenytranz.InTransaction then versenytranz.commit;
  Versenytranz.StartTransaction;
  VersenyTabla.close;
  VersenyTabla.TableName := 'PENZTAR';
  VersenyTabla.Open;
  Versenytabla.indexName := 'Idx_penztar';
  Versenytabla.first;

  _Helyezes := 0;
  while not Versenytabla.Eof do
    begin
       inc(_helyezes);
      VersenyTabla.edit;
      VersenyTabla.FieldByName('HELYEZES').AsInteger := _helyezes;
      Versenytabla.Post;
      VersenyTabla.next;
    end;
  VersenyTranz.commit;
  Versenydbase.close;
  Versenytabla.close;

  // ----------------------------------------------

  Versenydbase.connected := True;
  if Versenytranz.InTransaction then versenytranz.commit;
  Versenytranz.StartTransaction;
  VersenyTabla.close;
  VersenyTabla.TableName := 'PENZTAROS';
  VersenyTabla.Open;
  Versenytabla.IndexName := 'Idx_penztaros';
  Versenytabla.first;

  _Helyezes := 0;
  while not Versenytabla.Eof do
    begin
      inc(_helyezes);
      VersenyTabla.edit;
      VersenyTabla.FieldByName('HELYEZES').AsInteger := _helyezes;
      Versenytabla.Post;
      VersenyTabla.next;
    end;
  VersenyTranz.commit;
  Versenydbase.close;
  Versenytabla.close;
end;

// =============================================================================
                    procedure TForm1.AdatFeltoltes;
// =============================================================================

begin

  Versenydbase.Connected := true;
  _pcs := 'SELECT * FROM PENZTAR' + _sorveg;
  _pcs := _pcs + 'ORDER BY HELYEZES';

  with VersenyQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _sorindex := 0;
  while not VersenyQuery.eof do
    begin
      _helyezes := VersenyQuery.FieldByNAme('HELYEZES').asInteger;
      _pnum := VersenyQuery.FieldByNAme('PENZTARSZAM').asInteger;
      _pnev := trim(VersenyQuery.FieldByNAme('PENZTARNEV').asString);
      _ehavi := VersenyQuery.FieldByNAme('EHAVIFORGALOM').asInteger;
      _eevi := VersenyQuery.FieldByNAme('ELOZOEVIFORGALOM').asInteger;
      _szaz := VersenyQuery.FieldByNAme('SZAZALEK').asFloat;

      _szazas := Form1.realtostr(_szaz);

      _xsor := _firstPtRow + _sorindex;

      _oxl.cells[_xsor,2] := inttostr(_pnum);
      _oxl.cells[_xsor,3] := _pnev;
      _oxl.cells[_xsor,4] := intToStr(_eevi);
      _oxl.cells[_xsor,5] := intToStr(_ehavi);
      _oxl.cells[_xsor,6] := _szazas;
      _oxl.Cells[_xsor,7] := _helyezes;

      if _helyezes<4 then
        begin
          _oxl.Cells[_xsor,3].font.color := clred;
           _oxl.Cells[_xsor,3].font.Bold := True;
          _oxl.Cells[_xsor,7].font.color := clRed;
          _oxl.Cells[_xsor,7].font.Bold := true;
        end;

      inc(_sorindex);
      VersenyQuery.next;
    end;

  // ---------------------------------------------------------------------------

  _pcs := 'SELECT * FROM PENZTAROS' + _sorveg;
  _pcs := _pcs + 'ORDER BY HELYEZES';

  with VersenyQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _sorindex := 0;
  while not VersenyQuery.eof do
    begin
      _helyezes := VersenyQuery.FieldByNAme('HELYEZES').asInteger;
      _prosid := VersenyQuery.FieldByNAme('IDKOD').asString;
      _prosnev:= trim(VersenyQuery.FieldByNAme('PENZTAROSNEV').asString);
      _elohavi:= Versenyquery.FieldByNAme('ELOZOHAVIFORGALOM').asInteger;
      _akthavi:= VersenyQuery.FieldByNAme('EHAVIFORGALOM').asInteger;
      _szaz := VersenyQuery.FieldByNAme('SZAZALEK').asFloat;

      _szazas := Form1.realtostr(_szaz);
      _ppos := pos('.',_szazas);
      _szazas := leftstr(_szazas,_ppos+2);

      _xsor := _firstProsRow + _sorindex;

      _oxl.Cells[_xsor,2] := _prosid;
      _oxl.Cells[_xsor,3] := _prosnev;
      _oxl.Cells[_xsor,4] := inttoStr(_elohavi);
      _oxl.Cells[_xsor,5] := intToStr(_akthavi);
      _oxl.Cells[_xsor,6] := _szazas;
      _oxl.Cells[_xsor,7] := inttostr(_helyezes);

      if _helyezes<4 then
        begin
          _oxl.Cells[_xsor,3].font.color := Clred;
          _oxl.Cells[_xsor,3].font.Bold := True;
          _oxl.Cells[_xsor,7].font.color := clRed;
          _oxl.Cells[_xsor,7].font.Bold := True;
        end;

      inc(_sorindex);  
      Versenyquery.Next;
    end;
  VersenyQuery.Close;
  VersenyDbase.close;
end;


procedure TForm1.QuitGombClick(Sender: TObject);
begin
  _oxl.Quit;
  _oxl := unassigned;
  excelKill;
  Application.Terminate;
end;

// =============================================================================
                  procedure TForm1.ExcelKill;
// =============================================================================


var
  _fileName,_filePath: String;

begin

  Proc.dwSize := SizeOf(Proc);
  _handle := CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
  _Looper := Process32First(_handle,proc);

  while Integer(_Looper) <> 0 do
    begin
      _filepath := Proc.szExeFile;
      _fileName := UpperCase(ExtractFileName(_filepath));

      if _fileName = 'EXCEL.EXE' then
        begin
          TerminateProcess(OpenProcess(1,Bool(1),proc.th32ProcessID),0);
          break;
        end;

      _Looper := Process32Next(_handle,proc);
    end;
  CloseHandle(_handle);
end;


procedure TForm1.VekonyKeret(_rs: string);

begin
  _oxl.Range[_rs].BorderAround(1,2);
end;


procedure TForm1.VastagKeret(_rs: string);

begin
  _oxl.Range[_rs].BorderAround(1,3);
end;




procedure TForm1.EVCOMBOChange(Sender: TObject);
begin
  Activecontrol := startgomb;
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
