unit Unit4;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, comobj, activex, ExtCtrls, IBDatabase, DB, strutils,
  IBCustomDataSet, IBQuery, DAteUtils, ComCtrls;

type
  TMAKEEXCEL = class(TForm)
    KILEPO: TTimer;
    TETQUERY: TIBQuery;
    FEJDBASE: TIBDatabase;
    FEJQUERY: TIBQuery;
    FEJTRANZ: TIBTransaction;
    TETDBASE: TIBDatabase;
    TETTRANZ: TIBTransaction;
    UQUERY: TIBQuery;
    UDBASE: TIBDatabase;
    UTRANZ: TIBTransaction;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    ARTQUERY: TIBQuery;
    ARTDBASE: TIBDatabase;
    ARTTRANZ: TIBTransaction;
    Panel1: TPanel;
    Label1: TLabel;
    CSIK: TProgressBar;
    Shape1: TShape;

    procedure FormActivate(Sender: TObject);
    procedure MakeFejlec;
    procedure AdatBeiro;
    procedure KilepoTimer(Sender: TObject);
//    procedure IrodaBetoltes;
    procedure ExelbeRogzit;
    procedure GetMegbizottData;
    function arfform(_arf: integer): string;
    function GetExPath: string;
    function SZulform(_szi: string): string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MAKEEXCEL: TMAKEEXCEL;
  _expath : string;
  _oxl,_owb,_range: Olevariant;
  _rangestr,_udbnev,_bizonylat,_valutanem,_tipus,_pcs,_datum,_ugyftip: string;
  _joginev,_jogicim,_okirat,_mbneve,_aktkftnev,_aktptcim,_csoport: string;

  _mbnev,_mbelozonev,_mbszuletesihely,_mbszuletesiido,_mbanyjaneve: string;
  _mbAllampolgar,_mbOkmanytipus,_mbAzonosito,_megbizott,_mbTabla: string;

  _asc,_aktevtized,_penztar,_aktkftnum,_wmb: byte;
  _prisor,_aktev,_top,_left: word;
  _bankjegy,_arfolyam,_ftertek,_sorszam,_cc,_recno: integer;

  _head: string;
  _sorpath : string = 'c:\uctrl\data\sorszam.txt';

  _vanmb: boolean;


implementation

uses Unit1;

{$R *.dfm}


procedure TMAKEEXCEL.FormActivate(Sender: TObject);
begin
  _TOP := Form1.top;
  _left := Form1.left;

  Top := _top +250;
  Left := _left +300;

  if _csoptipus='P' then _csoport := _aktpenztarnev;
  if _csoptipus='K' then _csoport := _aktkorzetnev+' körzet';
  if _csoptipus='C' then _csoport := lowercase(_aktceg) + ' kft';

  _aktev := yearof(Date);
  _aktevtized := _aktev-2000;
  _udbNev := _host + ':C:\RECEPTOR\DATABASE\UGYFEL' + inttostr(_aktevtized)+'.fdb';

  _expath := Getexpath;

  Udbase.close;
  Udbase.DatabaseName := _udbNev;

  _head := 'Ügyfél adatok '+inttostr(_kertev)+' '+_honev[_kertho]+' '+inttostr(_tolnap);
  _head := _head + ' és ' + _honev[_kertho]+' '+inttostr(_ignap)+' között';
  _head := _head + '  ('+_csoport+')';

  _oxl := CreateOleObject('EXCEL.APPLICATION');
  _owb := _oxl.workbooks.Add[1];
  _owb.Activate;

  _oxl.range['B1:B1'].ColumnWidth := 11;
  _oxl.range['C1:C1'].ColumnWidth := 11;
  _oxl.range['D1:D1'].ColumnWidth := 7;
  _oxl.range['E1:E1'].ColumnWidth := 11;
  _oxl.range['F1:F1'].ColumnWidth := 13;
  _oxl.range['G1:G1'].ColumnWidth := 17;
  _oxl.range['H1:H1'].ColumnWidth := 13;
  _oxl.range['I1:I1'].ColumnWidth := 32;
  _oxl.range['J1:J1'].ColumnWidth := 44;
  _oxl.range['K1:K1'].ColumnWidth := 32;
  _oxl.range['L1:L1'].ColumnWidth := 32;
  _oxl.range['M1:M1'].ColumnWidth := 11;
  _oxl.range['N1:N1'].ColumnWidth := 17;
  _oxl.range['O1:O1'].ColumnWidth := 32;
  _oxl.range['P1:P1'].ColumnWidth := 17;
  _oxl.range['Q1:Q1'].ColumnWidth := 20;
  _oxl.range['R1:R1'].ColumnWidth := 17;
  _oxl.range['S1:S1'].ColumnWidth := 37;
  _oxl.range['T1:T1'].ColumnWidth := 15;
  _oxl.range['U1:U1'].ColumnWidth := 39;
  _oxl.range['V1:V1'].ColumnWidth := 19;
  _oxl.range['W1:W1'].ColumnWidth := 32;
  _oxl.range['X1:X1'].ColumnWidth := 32;
  _oxl.range['Y1:Y1'].ColumnWidth := 11;
  _oxl.range['Z1:Z1'].ColumnWidth := 18;
  _oxl.range['AA1:AA1'].ColumnWidth := 32;
  _oxl.range['AB1:AB1'].ColumnWidth := 17;
  _oxl.range['AC1:AC1'].ColumnWidth := 17;
  _oxl.range['AD1:AD1'].ColumnWidth := 20;

  _rangestr := 'B3:J3';
  _oxl.range['B3:J3'].Mergecells := true;
  _oxl.range[_rangestr].Font.Name := 'Times New Roman';
  _oxl.range[_rangestr].Font.Size := 16;
  _oxl.range[_rangestr].Font.Italic := True;
  _oxl.cells[3,2] := _head;

  MakeFejlec;
  AdatBeiro;


  if FileExists(_exPath) then Sysutils.DeleteFile(_exPath);
  _owb.saveas(_expath);
  _oxl.quiT;
  _oxl := unassigned;
  Kilepo.enabled := True;
end;

// =============================================================================
                       procedure TMakeExcel.MakeFejlec;
// =============================================================================


begin


   Panel1.Caption := 'EXCEL FEJLÉC KÉSZÍTÉSE';
   Panel1.repaint;

   Csik.Position := 1;

  _oxl.range['B5:J5'].MergeCells := True;
  _oxl.range['K5:R5'].MergeCells := True;
  _oxl.range['S5:V5'].MergeCells := True;
  _oxl.range['W5:AD5'].MergeCells := True;

  _rangestr := 'B5:AD5';
  _oxl.range[_rangestr].Font.Name := 'Arial';
  _oxl.range[_rangestr].Font.Bold := True;
  _oxl.range[_rangestr].Font.Italic := True;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;

  // ---------------------------------------

  _asc := 66;
  while _asc<=90 do
    begin
      _rangestr := chr(_asc)+'6:'+chr(_asc)+'8';
      _oxl.range[_rangestr].MergeCells := True;
      inc(_asc);
    end;

  _asc := 65;
  while _asc<=68 do
    begin
      _rangestr := 'A'+chr(_asc)+'6:A'+chr(_asc)+'8';
      _oxl.range[_rangestr].MergeCells := True;
      inc(_asc);
    end;

  _rangestr := 'B6:AD8';
  _oxl.range[_rangestr].Font.Name := 'Calibri';
  _oxl.range[_rangestr].Font.Bold := True;
  _oxl.range[_rangestr].Font.Italic := True;
  _oxl.range[_rangestr].Font.Size := 12;

  _oxl.range[_rangestr].wraptext := True;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;
  _oxl.range[_rangestr].VerticalAlignment := -4108;

  // -------------------------------------------------

  _oxl.cells[5,2]  := 'TRANZAKCIÓ ADATAI';
  _oxl.cells[5,11] := 'TERMÉSZETES SZEMÉLYT AZONOSÍTÓ ADATOK';
  _oxl.cells[5,19]:= 'CÉGES ÜGYFÉL ADATAI';
  _oxl.cells[5,23]:= 'CÉG NEVÉBEN ELJÁRÓ SZEMÉLY ADATAI';

  // -------------------------------------------------

   _oxl.cells[6,2] := 'Tranzakció dátuma';
   _oxl.cells[6,3] := 'Összeg';
   _oxl.cells[6,4] := 'Valuta nem';
   _oxl.cells[6,5] := 'Tranzakció típusa';
   _oxl.cells[6,6] := 'Alkalmazott árfolyam';
   _oxl.cells[6,7] := 'Tranzakció forint összege';
   _oxl.cells[6,8] := 'Tranzakció egyedi azonosítója';
   _oxl.cells[6,9] := 'Pénzváltó ügynök megnevezése';
   _oxl.cells[6,10]:= 'Pénzváltó üzlethelyiség címe';

   _oxl.cells[6,11]:= 'Családi és utónév';
   _oxl.cells[6,12]:= 'Születési család és utónév';
   _oxl.cells[6,13]:= 'Születési dátum';
   _oxl.cells[6,14]:= 'Születési helye';
   _oxl.cells[6,15]:= 'Anyja neve';
   _oxl.cells[6,16]:= 'Állampolgársága';
   _oxl.cells[6,17]:= 'Azonosító okmány típusa';
   _oxl.cells[6,18]:= 'Azonosító okmány száma';

   _oxl.cells[6,19]:= 'Cégnév';
   _oxl.cells[6,20]:= 'Bejegyzés országa';
   _oxl.cells[6,21]:= 'Székhelye';
   _oxl.cells[6,22]:= 'Cégjegyzélszám';

   _oxl.cells[6,23]:= 'Családi és utónév';
   _oxl.cells[6,24]:= 'Születési családi és utónév';
   _oxl.cells[6,25]:= 'Születési dátum';
   _oxl.cells[6,26]:= 'Születési hely';
   _oxl.cells[6,27]:= 'Anyja neve';
   _oxl.cells[6,28]:= 'Állampolgársága';
   _oxl.cells[6,29]:= 'Azonosító okmány típusa';
   _oxl.cells[6,30]:= 'Azonosító okmány száma';

   _rangestr := 'B6:AD8';
   _oxl.range[_rangestr].BorderAround(1,2);

   _rangestr := 'K5:R5';
   _oxl.range[_rangestr].BorderAround(1,2);

   _rangestr := 'S5:V5';
   _oxl.range[_rangestr].BorderAround(1,2);

   _rangestr := 'B6:AD8';
   _oxl.range[_rangestr].BorderAround(1,2);

   _rangestr := 'B6:B8';
   _oxl.range[_rangestr].BorderAround(1,2);

   _rangestr := 'D6:D8';
   _oxl.range[_rangestr].BorderAround(1,2);

   _rangestr := 'F6:F8';
   _oxl.range[_rangestr].BorderAround(1,2);

   _rangestr := 'H6:H8';
   _oxl.range[_rangestr].BorderAround(1,2);

   _rangestr := 'J6:J8';
   _oxl.range[_rangestr].BorderAround(1,2);

   _rangestr := 'L6:L8';
   _oxl.range[_rangestr].BorderAround(1,2);

   _rangestr := 'N6:N8';
   _oxl.range[_rangestr].BorderAround(1,2);

   _rangestr := 'P6:P8';
   _oxl.range[_rangestr].BorderAround(1,2);

   _rangestr := 'R6:R8';
   _oxl.range[_rangestr].BorderAround(1,2);

   _rangestr := 'T6:T8';
   _oxl.range[_rangestr].BorderAround(1,2);

   _rangestr := 'V6:V8';
   _oxl.range[_rangestr].BorderAround(1,2);

   _rangestr := 'X6:X8';
   _oxl.range[_rangestr].BorderAround(1,2);

   _rangestr := 'Z6:Z8';
   _oxl.range[_rangestr].BorderAround(1,2);

   _rangestr := 'AB6:AB8';
   _oxl.range[_rangestr].BorderAround(1,2);

   _rangestr := 'AD6:AD8';
   _oxl.range[_rangestr].BorderAround(1,2);

   _rangestr := 'B5:AD8';
   _oxl.range[_rangestr].BorderAround(1,4);

   Csik.Position := 2;
end;


procedure TMAKEEXCEL.KILEPOTimer(Sender: TObject);
begin
  Kilepo.Enabled := False;
  ModalResult := 1;
end;


procedure TMakeExcel.AdatBeiro;

begin
  _prisor := 9;
  _pcs := 'SELECT * FROM TETELEK' + _sorveg;
  _pcs := _pcs + 'ORDER BY BIZONYLAT';

  Tetdbase.connected := true;
  with TetQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  Csik.Max := _recno+2;
  _cc := 2;
  while not TetQuery.eof do
    begin
      inc(_cc);
      Csik.Position := _cc;
      with TetQuery do
        begin
          _bizonylat := FieldByNAme('BIZONYLAT').asString;
          _valutanem := FieldByNAme('VALUTANEM').asString;
          _bankjegy  := FieldByNAme('BANKJEGY').asInteger;
          _arfolyam  := FieldByNAme('ARFOLYAM').asInteger;
          _ftertek   := FieldByNAme('ERTEK').asInteger;
        end;

      _tipus := 'vétel';
      if leftstr(_bizonylat,1)='E' then _tipus := 'eladás';

      _pcs := 'SELECT * FROM FEJEK' + _sorveg;
      _pcs := _pcs + 'WHERE BIZONYLAT='+chr(39)+_bizonylat+chr(39);

      Fejdbase.connected := true;
      with FejQuery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _datum := fieldByName('DATUM').asString;
          _sorszam := FieldByNAme('SORSZAM').asInteger;
          _penztar := FieldByNAme('PENZTAR').asInteger;
          _nevtabla := trim(FieldByNAme('NEVTABLA').asString);
          Close;
        end;

      Fejdbase.close;

      Panel1.Caption := _datum + ' - ' + _bizonylat;
      Panel1.repaint;

        // -------------------------------------

      uDbase.close;
      udbase.DatabaseName := _udbnev;
      uDbase.connected := true;
      _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
      _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
      with uquery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
        end;

      _vanMb := False;

      if _nevtabla<>'JOGI' then
        begin
          _ugyftip := 'N';
          _qnev := trim(Uquery.FieldByNAme('NEV').asString);
          _qelozonev := trim(Uquery.FieldByNAme('ELOZONEV').asString);
          _qszuletesihely := trim(Uquery.fieldByName('SZULETESIHELY').asString);
          _qszuletesiido := Uquery.FieldByNAme('SZULETESIIDO').asString;
          _qanyjaneve := trim(uquery.FieldByNAme('ANYJANEVE').asString);
          _qallampolgar := trim(Uquery.FieldByNAme('ALLAMPOLGAR').asString);
          _qokmanytipus := trim(Uquery.FieldByNAme('OKMANYTIP').asString);
          _qazonosito := trim(Uquery.fieldByNAme('AZONOSITO').asString);
        end else
        begin
          _ugyftip := 'J';
          _joginev := trim(uquery.FieldByNAme('JOGISZEMELYNEV').asString);
          _jogicim := trim(Uquery.FieldByNAme('TELEPHELYCIM').asString);
          _okirat := trim(Uquery.FieldByNAme('OKIRATSZAM').asString);
          _mbneve := trim(Uquery.FieldByNAme('MEGBIZOTTNEVE').asString);
          _Megbizott := trim(Uquery.FieldByName('MBDATASORSZAM').asString);
          GetMegbizottData;
        end;
      Uquery.close;
      Udbase.close;

      _aktkftnum := _kftnum[_penztar];
      _aktkftnev := _kftnev[_aktkftnum];
      _aktptcim  := _ptarcim[_penztar];

      Exelberogzit;

      TetQuery.next;
    end;
  Tetquery.close;
  Tetdbase.close;

  // ------------------------------------------------

  _rangestr := 'B10:B'+inttostr(_prisor);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;

    _rangestr := 'D10:F'+inttostr(_prisor);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;

    _rangestr := 'H10:I'+inttostr(_prisor);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;

    _rangestr := 'M10:M'+inttostr(_prisor);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.Range[_rangestr].NumberFormat := '#### ## ##';

    _rangestr := 'P10:R'+inttostr(_prisor);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;

    _rangestr := 'T10:T'+inttostr(_prisor);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;

    _rangestr := 'V10:V'+inttostr(_prisor);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;

    _rangestr := 'Y10:Y'+inttostr(_prisor);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;

    _rangestr := 'AB10:AB'+inttostr(_prisor);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;

    _rangestr := 'AC10:AC'+inttostr(_prisor);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;

    _rangestr := 'AD10:AD'+inttostr(_prisor);
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;

    _rangestr := 'C10:C'+inttostr(_prisor);
  _oxl.Range[_rangestr].NumberFormat := '### ### ###';

    _rangestr := 'F10:F'+inttostr(_prisor);
  _oxl.Range[_rangestr].NumberFormat := '### ##';

    _rangestr := 'F10:G'+inttostr(_prisor);
  _oxl.Range[_rangestr].NumberFormat := '### ### ###';

    _rangestr := 'C10:C'+inttostr(_prisor);
  _oxl.Range[_rangestr].NumberFormat := '### ### ###';

  _oxl.Range['A9:A9'].SELECT;
  _oxl.ActiveWindow.FreezePanes := true;
end;


procedure TMakeExcel.GetMegbizottData;

var _MSors: string;

begin
  //   PL.  _megbizott := 'MNEV1668'

  _wmb := length(_megbizott);
  if _wmb<5 then exit;

  _wmb := _wmb-4;
  _mbTabla := leftstr(_megbizott,4);
  _msors := midstr(_megbizott,5,_wmb);

  _pcs := 'SELECT * FROM ' + _mbtabla + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + _MSors;
  with Uquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then exit;

  _mbnev := trim(Uquery.FieldByNAme('NEV').asString);
  _mbelozonev := trim(Uquery.FieldByNAme('ELOZONEV').asString);
  _mbszuletesihely := trim(Uquery.fieldByName('SZULETESIHELY').asString);
  _mbszuletesiido := Uquery.FieldByNAme('SZULETESIIDO').asString;
  _mbanyjaneve := trim(uquery.FieldByNAme('ANYJANEVE').asString);
  _mballampolgar := trim(Uquery.FieldByNAme('ALLAMPOLGAR').asString);
  _mbokmanytipus := trim(Uquery.FieldByNAme('OKMANYTIP').asString);
  _mbazonosito := trim(Uquery.fieldByNAme('AZONOSITO').asString);

  _vanMb := True;
end;


function TMakeExcel.arfform(_arf: integer): string;

var _arfs: string;
    _warf,_f1: byte;
    
begin
  _arfs := inttostr(_arf);
  _warf := length(_arfs);
  if _valutanem='JPY' then
    begin
      result := leftstr(_arfs,1)+','+midstr(_arfs,2,_warf-1);
       while length(result)<6 do result := ' ' + result;
       exit;
    end;

  _f1   := _warf-2;
  result := leftstr(_arfs,_f1)+','+midstr(_arfs,_f1+1,3);
  while length(result)<6 do result := ' ' + result;
end;


function TMakeExcel.SZulform(_szi: string): string;

begin
  result := leftstr(_szi,4)+'.'+midstr(_szi,5,2)+'.'+midstr(_szi,7,2);
end;



procedure TmakeExcel.ExelbeRogzit;

begin
  inc(_Prisor);

  _oxl.cells[_prisor,2] := _datum;
  _oxl.cells[_prisor,3] := _bankjegy;
  _oxl.cells[_prisor,4] := _valutanem;
  _oxl.cells[_prisor,5] := _tipus;
  _oxl.cells[_prisor,6] := arfform(_arfolyam);
  _oxl.cells[_prisor,7] := _ftertek;
  _oxl.cells[_prisor,8] := _bizonylat;
  _oxl.cells[_prisor,9] := _aktkftnev;
  _oxl.cells[_prisor,10]:= _aktptcim;
  if _ugyftip='N' then
    begin
      _oxl.cells[_prisor,11] := _qnev;
      _oxl.cells[_prisor,12] := _qelozonev;
      _oxl.cells[_prisor,13] := szulform(_qszuletesiido);
      _oxl.cells[_prisor,14] := _qszuletesihely;
      _oxl.cells[_prisor,15] := _qanyjaneve;
      _oxl.cells[_prisor,16] := _qallampolgar;
      _oxl.cells[_prisor,17] := _qokmanytipus;
      _oxl.cells[_prisor,18] := _qazonosito;
    end else
    begin
      _oxl.cells[_prisor,19] := _joginev;
      _oxl.cells[_prisor,20] := 'HU';
      _oxl.cells[_prisor,21] := _jogicim;
      _oxl.cells[_prisor,22] := _okirat;

      if _vanMb then
        begin
          _oxl.cells[_prisor,23] := _mbNev;
          _oxl.cells[_prisor,24] := _mbElozonev;
          _oxl.cells[_prisor,25] := _mbSzuletesiido;
          _oxl.cells[_prisor,26] := _mbSzuletesihely;
          _oxl.cells[_prisor,27] := _mbAnyjaneve;
          _oxl.cells[_prisor,28] := _mbAllampolgar;
          _oxl.cells[_prisor,29] := _mbOkmanytipus;
          _oxl.cells[_prisor,30] := _mbAzonosito;
        end;
    end;
end;


function TMakeExcel.GetExPath: string;

var _olvas,_iras: textfile;
    _sstring: string;
    _ss : integer;

begin
  if fileExists(_sorpath) then
    begin
      AssignFile(_olvas,_sorpath);
      reset(_olvas);
      readln(_olvas,_sstring);
      Closefile(_olvas);
    end else _sstring := '0';

  val(_sstring,_ss,_code);
  inc(_ss);
  _sstring := inttostr(_ss);

  Assignfile(_iras,_sorpath);
  rewrite(_iras);
  writeLn(_iras,_sstring);
  CloseFile(_iras);

  result := 'c:\uctrl\data\uf' + _sstring + '.xls';
end;




{
procedure TMakeExcel.IrodaBetoltes;

var _uzlet,_k: byte;
    _pcim,_cbetu: string;

begin
  recdbase.connected := true;
  with Recquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM IRODAK');
      Open;
    end;

  while not recquery.eof do
    begin
      _uzlet := Recquery.fieldByNAme('UZLET').asInteger;
      _pcim  := trim(recquery.FieldByNAme('IRODACIM').asString);
      _cbetu := Recquery.FieldByNAme('CEGBETU').asString;

      _k := 1;
      if _cBetu='E' then _k := 2;
      IF _cBetu='P' then _k := 3;

      _kftnum[_uzlet] := _k;
      _ptarcim[_uzlet] := _pcim;
      Recquery.next;
    end;

  RecQuery.close;
  Recdbase.close;

  // -----------------------------------------------------

  Artdbase.connected := true;
  with Artquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM IRODAK');
      Open;
    end;

  while not Artquery.eof do
    begin
      _uzlet := Artquery.fieldByNAme('UZLET').asInteger;
      _pcim  := trim(Artquery.FieldByNAme('IRODACIM').asString);

      _kftnum[_uzlet] := 4;
      _ptarcim[_uzlet] := _pcim;
      Artquery.next;
    end;

  artQuery.close;
  Artdbase.close;
end;
}







end.
