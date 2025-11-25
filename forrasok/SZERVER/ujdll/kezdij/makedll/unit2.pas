unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, strUtils, IBDatabase, DB, IBCustomDataSet, IBQuery,
  ExtCtrls, Buttons, IBTable, excel97,comobj,activex, ComCtrls, jpeg;

type
  TForm2 = class(TForm)
    DQUERY: TIBQuery;
    RECQUERY: TIBQuery;
    DDBASE: TIBDatabase;
    RECDBASE: TIBDatabase;
    KEZDQUERY: TIBQuery;
    KEZDDBASE: TIBDatabase;
    DTRANZ: TIBTransaction;
    RECTRANZ: TIBTransaction;
    KEZDTRANZ: TIBTransaction;
    KILEPO: TTimer;
    KEZDTABLA: TIBTable;
    BFEJTABLA: TIBTable;
    BFEJQUERY: TIBQuery;
    BFEJDBASE: TIBDatabase;
    BFEJTRANZ: TIBTransaction;
    Panel1: TPanel;
    Label1: TLabel;
    uzenopanel: TPanel;
    CSIK: TProgressBar;
    KEP: TImage;
    Shape1: TShape;


    procedure KezdijNullazo;
    procedure KezdijKiolvaso;
    procedure KezdijBeiro;
    procedure KezdijExcelbetoltes;

    procedure PenztarSorEpito;
    procedure PenztarParaBeolvasas;
    procedure GetIdoszak;
    procedure KezdParancs(_ukaz: string);
    procedure FormActivate(Sender: TObject);
    procedure Keret(_rs: string; _wide: byte);
    procedure KilepoTimer(Sender: TObject);
    procedure FejlecKeszites(_ful: byte);
    procedure Makekezdtabla(_tnev: string);

    function KezdtablaNyitas(_kftbetu: string): boolean;
    function ezEtar(_ptr: byte):  boolean;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _penztarnev,_bankkod: array[1..168] of string;
  _penztarsor: array[1..168] of byte;

  _HONEV: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS',
                'MÁJUS','JUNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
                'NOVEMBER','DECEMBER');
  _cegPtardb: array[1..2] of byte;
  _cb: array[1..2] of string =  ('B','Z');

  _kv,_ke: array[1..168,1..31] of integer;

  _tolstring,_igstring,_fdbPath,_knaps,_vNaps,_status,_aMezo,_pcs: string;
  _farok,_daybook,_uznev,_tablanev,_lowstr,_e2str,_lows,_cegbetu: string;
  _excelpath,_vMezo,_eMezo,_rangestr,_formula,_bf,_filter,_subdir: string;
  _datum,_tipus,_naps,_kd,_cimpcs,_bkod,_aktcegbetu,_kertevs,_kerthos: string;
  _sorveg: string = chr(13)+chr(10);

  _code,_mResult,_ok,_svet,_sela,_vosz,_bk,_vAdat,_eAdat,_recno,_kezdij: integer;
  _ch,_pt,_ptss,_penztarDarab,_knap,_vNap,_aNap,_uzlet,_sptdarab,_yyy: byte;
  _ptDarab,_nap: byte;

  _lowest,_oo,_lowdat,_aktsor,_kertev,_kertho,_nn,_pp,_csikss: word;

  _oxl,_owb,_range: Olevariant;


function hovalasztorutin: integer; stdcall; external 'c:\receptor\newdll\hovalasz.dll';
function kezdijosszesito: integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
                function kezdijosszesito: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.showmodal;
  Form2.free;
end;



// =============================================================================
             procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _mResult := -1;
  TOP :=260;
  left := 360;
  Repaint;


  _ok := hovalasztorutin;
  if _ok=-1 then
    begin
      Kilepo.enabled := True;
      exit;
    end;
  PenztarParaBeolvasas;
  PenztarsorEpito;
  KezdijNullazo;
  KezdijKiOlvaso;
  Kezdijbeiro;
  KezdijExcelbeToltes;

  Kilepo.Enabled := True;
end;


// =============================================================================
                       procedure TForm2.KezdijNullazo;
// =============================================================================

begin
  _pt := 1;
  while _pt<=168 do
    begin
      _nap := 1;
      while _nap<=31 do
        begin
          _kv[_pt,_nap] := 0;
          _ke[_pt,_nap] := 0;
          inc(_nap);
        end;
      inc(_pt);
    end;
end;

// =============================================================================
                        procedure TForm2.KezdijKiolvaso;
// =============================================================================

begin
  UzenoPanel.Caption := 'A KEZELÉSI DÍJAK ÖSSZESÍTÉSE';
  UzenoPanel.Repaint;

  _bf := 'BF' + _farok;

  _filter := '((TIPUS='+chr(39)+'V'+chr(39)+') OR (TIPUS='+chr(39)+'E'+CHR(39)+'))';
  _filter := _filter + ' AND (DATUM>='+chr(39)+_tolstring+chr(39)+') AND (DATUM<='+chr(39)+_igstring+chr(39)+')';
  _filter := _filter + ' AND (STORNO=1) AND (FIZETOESZKOZ=1)';

  _pcs := 'SELECT * FROM ' + _BF + _sorveg;
  _pcs := _pcs + 'WHERE ' + _filter;

  Csik.Max := _ptss;
  _ptss := 1;
  while _ptss<=_penztardarab do
    begin
      csik.Position := _ptss;
      _pt := _penztarsor[_ptss];
      _bkod := _bankkod[_pt];
      _aktcegbetu := 'B';

      if _pt>150 then _aktcegbetu := 'Z';
      _fdbpath := 'c:\receptor\database\v' + inttostr(_pt) + '.fdb';

      with Bfejdbase do
        begin
          close;
          databasename := _fdbpath;
          connected := true;
        end;

      with Bfejtabla do
        begin
          Close;
          tablename := _bf;
        end;

      if not Bfejtabla.exists then
        begin
          Bfejdbase.close;
          inc(_ptss);
          continue;
        end;

      with bfejQuery do
        begin
          Close;
          sql.clear;
          sql.Add(_pcs);
          Open;
          _recno := recno;
        end;

      if _recno=0 then
        begin
          BfejQuery.close;
          Bfejdbase.close;
          inc(_ptss);
          Continue;
        end;

      while not Bfejquery.Eof do
        begin
          _datum := BfejQuery.FieldByNAme('DATUM').asString;
          _tipus := BFejQuery.FieldByNAme('TIPUS').asString;
          _kezdij:= BfejQuery.FieldByName('KEZELESIDIJ').asInteger;

          _naps := midstr(_datum,9,2);
          val(_naps,_nap,_code);

          if _tipus='V' then _kv[_ptss,_nap] := _kv[_ptss,_nap] + _kezdij;
          if _tipus='E' then _ke[_ptss,_nap] := _ke[_ptss,_nap] + _kezdij;

          BfejQuery.next;
        end;
      BfejQuery.close;
      BfejDbase.close;
      inc(_ptss);
    end;
end;


// =============================================================================
                        procedure TForm2.KezdijBeiro;
// =============================================================================

begin
  uzenoPanel.Caption := 'AZ ÖSSZESITETT KEZ-I DÍJAK RÖGZÍTÉSE';
  UzenoPanel.Repaint;

  _KD  := 'KEZD' + _farok;
  KezdDbase.Connected := true;
  KezdTabla.close;
  KezdTabla.TableName := _kd;
  if not kezdTabla.Exists then MakeKezdTabla(_kd);

  _pcs := 'DELETE FROM ' + _kd;
  KezdParancs(_pcs);

  _cimpcs := 'INSERT INTO ' + _KD  + ' (PENZTAR,KDV1,KDE1,KDV2,KDE2,KDV3,KDE3,';
  _cimpcs := _cimpcs + 'KDV4,KDE4,KDV5,KDE5,KDV6,KDE6,KDV7,KDE7,KDV8,KDE8,';
  _cimpcs := _cimpcs + 'KDV9,KDE9,KDV10,KDE10,KDV11,KDE11,KDV12,KDE12,KDV13,KDE13,';
  _cimpcs := _cimpcs + 'KDV14,KDE14,KDV15,KDE15,KDV16,KDE16,KDV17,KDE17,KDV18,KDE18,';
  _cimpcs := _cimpcs + 'KDV19,KDE19,KDV20,KDE20,KDV21,KDE21,KDV22,KDE22,KDV23,KDE23,';
  _cimpcs := _cimpcs + 'KDV24,KDE24,KDV25,KDE25,KDV26,KDE26,KDV27,KDE27,KDV28,KDE28,';
  _cimpcs := _cimpcs + 'KDV29,KDE29,KDV30,KDE30,KDV31,KDE31,BANKKOD,CEGBETU)'+_sorveg;
  _cimpcs := _cimpcs + 'VALUES (';


  _ptss := 1;
  while _ptss<=_penztardarab do
    begin
      Csik.Position := _ptss;

      _pt := _penztarsor[_ptss];
      _bkod := _bankkod[_pt];
      _aktcegbetu := 'B';
      if _pt>150 then _aktcegbetu := 'Z';
      _pcs := _cimpcs + inttostr(_pt) + ',';
      _nap := 1;
      while _nap<=31 do
        begin
          _vadat := _kv[_ptss,_nap];
          _eAdat := _ke[_ptss,_nap];
          _pcs := _pcs + inttostr(_vadat)+','+inttostr(_eAdat);
          if _nap=31 then
            begin
              _pcs := _pcs + ',' + chr(39) + _bkod + chr(39) + ',';
              _Pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ')';
              KezdParancs(_pcs);
            end else _pcs := _pcs + ',';
          inc(_nap);
        end;
      inc(_ptss);
    end;
end;

// ======================= ÁLTALÁNOS SUBRUTINOK ================================
// =============================================================================
                   procedure TForm2.PenztarSorEpito;
// =============================================================================
//
//   EGY ADOTT IDÕSZAK ALATT NYITVALÉVÕ PÉNZTÁRAK SZÁMÁT PÉNZTÁRSORBA GYÜJTI
//                   (_penztarsor[1.._penztardarab])
//
begin
  GetIdoszak;

  Csik.Position := 0;
  _csikss := 0;

  uzenoPanel.Caption := 'A NYITVATARTÓ PÉNZTÁRAK ÖSSZEIRÁSA';
  uzenoPanel.Repaint;

  _farok := midstr(_tolstring,3,2)+midstr(_tolstring,6,2);
  _daybook := 'DAYB' + _farok;

  _kNaps := midstr(_tolstring,9,2);
  _vNaps := midstr(_igstring,9,2);

  Val(_kNaps,_knap,_code);
  val(_vNaps,_vnap,_code);

  _fdbPath := 'c:\receptor\database\DAYBOOK.FDB';
  with Ddbase do
    begin
      Close;
      DatabaseName := _fdbPath;
      Connected := true;
    end;

  with DQuery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM ' + _daybook + ' ORDER BY PENZTAR');
      Open;
    end;

  while not dQuery.Eof do
    begin
      inc(_csikss);
      Csik.Position := _csikss;

      _pt := dQuery.fieldByName('PENZTAR').asInteger;
      if ezEtar(_pt) then
        begin
          dQuery.next;
          continue;
        end;

      _status := 'X';
      _anap   := _knap;
      while _anap<=_vnap do
        begin
          _aMezo  := 'N' + inttostr(_anap);
          _status := dQuery.Fieldbyname(_aMezo).asString;
          if _status='B' then break;
          inc(_anap);
        end;
      if _status='B' then
        begin
          inc(_ptss);
          _penztarsor[_ptss] := _pt;
        end;
      dQuery.next;
    end;
  dQuery.close;
  dDbase.close;

  csik.Position := 168;
  sleep(1500);

  // -------------------------------------

  _penztarDarab := _ptss;
end;

// =============================================================================
                    procedure TForm2.PenztarParaBeolvasas;
// =============================================================================

begin
  uzenoPanel.Caption := 'Pémztárak adatainak beolvasása';
  uzenoPanel.Repaint;

  Csik.Max := 17;
  _csikss := 0;
  Csik.Visible := True;

  _fdbPath := 'c:\receptor\database\receptor.fdb';
  with Recdbase do
    begin
      Close;
      DatabaseName := _fdbPath;
      Connected := true;
    end;

  with Recquery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM IRODAK ORDER BY UZLET');
      Open;
    end;

  while not recquery.eof do
    begin
      inc(_csikss);
      Csik.Position := _csikss;

      _uzlet := RecQuery.fieldbyname('UZLET').asInteger;
      _uznev := trim(Recquery.FieldByNAme('KESZLETNEV').asString);
      _bkod  := trim(Recquery.fieldByNAme('BANKKOD').asString);
      _penztarNev[_uzlet] := _uznev;
      _bankkod[_uzlet] := _bkod;

      recQuery.next;
    end;
  recquery.close;
  recdbase.close;

  Csik.Position := 168;
  sleep(1500);
end;

// =============================================================================
                     procedure TForm2.GetIdoszak;
// =============================================================================

begin
  _fdbPath := 'c:\receptor\database\receptor.fdb';
  with Recdbase do
    begin
      Close;
      DatabaseName := _fdbPath;
      Connected := true;
    end;

  with RecQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM IDOSZAK');
      Open;
      _tolstring := FieldByName('STARTDATE').asString;
      _igstring  := trim(FieldByName('ENDDATE').asString);
      Close;
    end;
  recdbase.close;
  _kertevs := leftstr(_tolstring,4);
  _kerthos := midstr(_tolstring,6,2);

  val(_kertevs,_kertev,_code);
  val(_kerthos,_kertho,_code);
end;


// =============================================================================
              procedure TForm2.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := _mResult;
end;

// =============================================================================
                 procedure TForm2.KezdijExcelbeToltes;
// =============================================================================

var i: byte;

begin
  UzenoPanel.Caption := 'AZ EXCELTÁBLA ELKÉSZÍTÉSE';
  UzenoPanel.Repaint;
  Csik.position := 0;

  _tablaNev := 'KEZD' + _FAROK;

  KezdTabla.close;
  KezdTabla.TableName := _tablanev;
  KezdDbase.Connected := true;
  if not KezdTabla.Exists then
    begin
      KezdQuery.close;
      KezdDbase.close;
      exit;
    end;

  KezdQuery.close;
  KezdDbase.close;

  _pcs := 'SELECT * FROM KEZD'+ _farok+_sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAR';
  with KezdQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  for i := 1 to 2 do _cegptardb[i] := 0;
  _sptdarab := 0;

  while not kezdquery.Eof do
    begin
      _cegbetu := Kezdquery.FieldByname('CEGBETU').asString;
      if _cegbetu='B' then _cegptardb[1] := _cegptardb[1]+ 1;
      if _cegbetu='Z' then _cegptardb[2] := _cegptardb[2]+ 1;
      inc(_sptdarab);
      KezdQuery.next;
    end;

  KezdQuery.close;
  Kezddbase.close;

  // ----------------------------------------

  if _sptdarab=0 then  exit;

  _excelPath := 'C:\receptor\mail\posta\KEZD'+_farok+'.xls';
  if fileExists(_excelPath) then Deletefile(_excelpath);

  _oxl := CREATEOLEOBJECT('EXCEL.APPLICATION');
  _owb := _oxl.workbooks.Add[1];
  _oxl.workbooks[1].sheets.add(,,2);
  _oxl.workbooks[1].worksheets[1].name := 'EBC';
  _oxl.workbooks[1].worksheets[2].name := 'EXPRESSZ';

  _yyy := 1;
  while _yyy<=2 do
    begin
      _cegbetu := _cb[_yyy];
      if not KezdTablanyitas(_cegbetu) then
        begin
          inc(_yyy);
          Continue;
        end;
      _ptdarab := _cegptardb[_yyy];
      FejlecKeszites(_yyy);

  // --------------------------------------------------------------------


  _aktsor := 4;
  _ptss := 0;
  while not kezdquery.Eof do
    begin
      inc(_ptss);
      Csik.Position := _ptss;

      _bk := KezdQuery.fieldbyName('BANKKOD').asInteger;
      _pt := Kezdquery.FieldByName('PENZTAR').asInteger;

      _oxl.worksheets[_yyy].cells[_aktsor,1] := inttostr(_bk);
      _oxl.worksheets[_yyy].cells[_aktsor,2] := inttostr(_pt);

      _vosz := 3;
      _svet := 0;
      _sela := 0;

      for i := 1 to 31 do
        begin
          _Vmezo := 'KDV'+inttostr(i);
          _eMezo := 'KDE'+inttostr(i);

          _vadat := Kezdquery.FieldByName(_vmezo).asInteger;
          _eadat := KezdQuery.FieldByName(_eMezo).asInteger;

          _oxl.worksheets[_yyy].cells[_aktsor,_vosz] := _vadat;
          _oxl.worksheets[_yyy].cells[_aktsor,_vosz+1] := _eAdat;

          _svet := _svet + _vadat;
          _sela := _sela + _eadat;

          _vosz := _vosz+2;
        end;

      _oxl.worksheets[_yyy].cells[_aktsor,65] := _sVet;
      _oxl.worksheets[_yyy].cells[_aktsor,66] := _sEla;

      inc(_aktsor);
      KezdQuery.Next;
    end;

  csik.Position :=168;
  Kezdquery.close;
  Kezddbase.close;

  _RANGE := _oxl.range['C4:C4'];
  _range.select;
  _Oxl.activewindow.freezepanes := true;

  inc(_yyy)
  end;

  _owb.saveas(_excelpath);
  _oxl.activeworkbook.close;
  _oxl.quit;
  _oxl := unassigned;
  _owb := unassigned;

  UzenoPanel.caption := 'Excel táblát kitettem a postába -> KEZD'+_farok+'.xls néven';
  UzenoPanel.repaint;
  sleep(2500);
end;


// =============================================================================
                procedure TForm2.FejlecKeszites(_ful: byte);
// =============================================================================



begin
  _LOWEST := _ptdarab + 5;
  _lowstr := inttostr(_lowest);
  _e2str := inttostr(_ptdarab+4);

  _oxl.worksheets[_Ful].range['A1:AH1'].Mergecells := true;
  _oxl.worksheets[_ful].range['A1:AH1'].FONT.NAME := 'Times New Roman';
  _oxl.worksheets[_ful].range['A1:AH1'].font.size := 18;
  _oxl.worksheets[_ful].range['A1:AH1'].font.italic := True;
  _oxl.worksheets[_ful].range['A1:AH1'].HorizontalAlignment := -4108;

  _oxl.worksheets[_ful].cells[1,1] := inttostr(_kertev)+' '+_honev[_kertho]+'i beérkezett kezelési költségek';

  // ---------------------------------------------------------------------------

  _ch := 65;
  while _ch<=89 do
    begin
      Keret(chr(_ch)+'2:'+chr(_ch+1)+_lowstr,2);
      inc(_ch);
      inc(_ch);
    end;

  _ch := 65;
  while _ch<=89 do
    begin
      Keret('A' + chr(_ch)+'2:A' + chr(_ch+1)+_lowstr,2);
      inc(_ch);
      inc(_ch);
    end;

  _ch := 65;
  while _ch<=77 do
    begin
      Keret('B' + chr(_ch)+ '2:B' + chr(_ch+1)+_lowstr,2);
      inc(_ch);
      inc(_ch);
    end;

  Keret('A2:BN3',4);
  Keret('A2:BN' + _lowstr,4);
  Keret('A' + _e2str + ':BN' + _lowstr,4);

  // ---------------------------------------------------------------------------

  _rangestr := 'A2:BN' + _lowstr;
  _oxl.worksheets[_ful].range[_rangestr].Font.size := 10;

  _rangestr := 'C2:BN'+_lowstr;
  _oxl.worksheets[_ful].range[_rangestr].NumberFormat := '### ### ###';
  _oxl.worksheets[_ful].range[_rangestr].HorizontalAlignment := -4108;

  // ---------------------------------------------------------------------------

  _rangestr := 'A'+ _e2str + ':B' + _lowstr;
  _oxl.worksheets[_ful].range[_rangestr].Mergecells := true;
  _oxl.worksheets[_ful].range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_ful].range[_rangestr].VerticalAlignment := -4108;
  _oxl.worksheets[_ful].range[_rangestr].Font.bold := true;
  _oxl.worksheets[_ful].cells[_lowest-1,1] := 'ÖSSZESEN';

  // ---------------------------------------------------------------------------

  _CH := 67;
  while _ch<=89 do
    begin
      _rangestr := chr(_ch)+_lowstr+':'+chr(_ch+1)+_lowstr;
      _oxl.worksheets[_ful].range[_rangestr].Mergecells := true;
      _ch := _ch+2;
    end;

  _CH := 65;
  while _ch<=89 do
    begin
      _rangestr := 'A' +chr(_ch)+_lowstr+':A'+chr(_ch+1)+_lowstr;
      _oxl.worksheets[_ful].range[_rangestr].Mergecells := true;
      _ch := _ch+2;
    end;

  _CH := 65;
  while _ch<=77 do
    begin
      _rangestr := 'B' +chr(_ch)+_lowstr+':B'+chr(_ch+1)+_lowstr;
      _oxl.worksheets[_ful].range[_rangestr].Mergecells := true;
      _ch := _ch+2;
    end;

// -----------------------------------------------------------------------------


  _rangestr := 'A2:A3';
  _oxl.worksheets[_ful].range[_rangestr].Mergecells := true;
  _oxl.worksheets[_ful].cells[2,1] := 'BANK KÓD';

  _rangestr := 'B2:B3';
  _oxl.worksheets[_ful].range[_rangestr].Mergecells := true;
  _oxl.worksheets[_ful].cells[2,2] := 'PÉNZTÁR SZÁM';

  _NN :=1;

  while _nn<13 do
    begin
      _pp := trunc(_nn*2);   // 2 .. 24
      _rangestr := chr(_pp+65) + '2:' + chr(_pp+66)+'2';
      _oxl.worksheets[_ful].range[_rangestr].Mergecells := true;
      _oxl.worksheets[_ful].cells[2,_pp+1] := inttostr(_nn);

      _oxl.worksheets[_ful].cells[3,_pp+1] := 'Vétel';
      _oxl.worksheets[_ful].cells[3,_pp+2] := 'Eladás';
      inc(_nn);
    end;

  while _nn<26 do
    begin
      _pp := _nn-13;
      _pp := trunc(_pp*2);
      _rangestr := 'A' +chr(65+_pp)+'2:A'+chr(_pp+66)+'2';

      _oxl.worksheets[_ful].range[_rangestr].Mergecells := true;
      _oxl.worksheets[_ful].cells[2,_pp+27] := inttostr(_nn);

      _oxl.worksheets[_ful].cells[3,_pp+27] := 'Vétel';
      _oxl.worksheets[_ful].cells[3,_pp+28] := 'Eladás';
      inc(_nn);
    end;

  while _nn<32 do
    begin
      _pp := _nn-26;
      _pp := trunc(_pp*2);
      _rangestr := 'B' +chr(65+_pp)+'2:B'+chr(_pp+66)+'2';

      _oxl.worksheets[_ful].range[_rangestr].Mergecells := true;
      _oxl.worksheets[_ful].cells[2,_pp+53] := inttostr(_nn);

      _oxl.worksheets[_ful].cells[3,_pp+53] := 'Vétel';
      _oxl.worksheets[_ful].cells[3,_pp+54] := 'Eladás';
      inc(_nn);
    end;

  _rangestr := 'A2:BN3';
  _oxl.worksheets[_ful].range[_rangestr].Font.bold := true;

  _rangestr := 'A' + _E2STR+':BN'+_LOWSTR;
  _oxl.worksheets[_ful].range[_rangestr].Font.bold := true;

  _rangestr := 'A2:B3';
  _oxl.worksheets[_ful].range[_rangestr].VerticalAlignment := -4108;
  _oxl.worksheets[_ful].range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_ful].range[_rangestr].WrapText := true;

  _rangestr := 'BM2:BN2';
  _oxl.worksheets[_ful].range[_rangestr].Mergecells := true;
  _oxl.worksheets[_ful].Cells[2,65] := 'ÖSSZESEN';

  _rangestr := 'B4:B'+inttostr(_lowest-2);
  _oxl.worksheets[_ful].range[_rangestr].HorizontalAlignment := -4108;

  // ===========================================================================

  _lowdat := _ptdarab+3;
  _lows := inttostr(_lowdat);

  _oo := 3;
  while _oo<=26 do
    begin
      _ch := 64 + _oo;
      _formula := '=SUM(' + chr(_ch) + '4:' +  chr(_ch) + _lows+')';
      _oxl.worksheets[_ful].cells[_ptdarab+4,_oo] := _formula;

      _formula := '=SUM(' + chr(_ch+1) + '4:' +  chr(_ch+1) + _lows+')';
      _oxl.worksheets[_ful].cells[_ptdarab+4,_oo+1] := _formula;

      _formula := '=SUM('+chr(_ch)+_e2str+':'+chr(_ch+1)+_e2Str+')';
      _oxl.worksheets[_ful].cells[_lowest,_oo] := _formula;
      _oo := _oo + 2;
    end;

 // ----------------------------------------------------------------------------

 _oo := 27;
  while _oo<=52 do
    begin
      _ch := 38 + _oo;
      _formula := '=SUM(A' + chr(_ch) + '4:A' +  chr(_ch) + _lows+')';
      _oxl.worksheets[_ful].cells[_ptdarab+4,_oo] := _formula;

      _formula := '=SUM(A' + chr(_ch+1) + '4:A' +  chr(_ch+1) + _lows+')';
      _oxl.worksheets[_ful].cells[_ptdarab+4,_oo+1] := _formula;

      _formula := '=SUM(A'+chr(_ch)+_e2str+':A'+chr(_ch+1)+_e2Str+')';
      _oxl.worksheets[_ful].cells[_lowest,_oo] := _formula;
      _oo := _oo + 2;
    end;

 // ----------------------------------------------------------------------------

 _oo := 53;
  while _oo<=66 do
    begin
      _ch := _oo+12;
      _formula := '=SUM(B' + chr(_ch) + '4:B' +  chr(_ch) + _lows+')';
      _oxl.worksheets[_ful].cells[_ptdarab+4,_oo] := _formula;

      _formula := '=SUM(B' + chr(_ch+1) + '4:B' +  chr(_ch+1) + _lows+')';
      _oxl.worksheets[_ful].cells[_ptdarab+4,_oo+1] := _formula;

      _formula := '=SUM(B'+chr(_ch)+_e2str+':B'+chr(_ch+1)+_e2Str+')';
      _oxl.worksheets[_ful].cells[_lowest,_oo] := _formula;
      _oo := _oo + 2;
    end;

end;

// =============================================================================
            function TForm2.KezdtablaNyitas(_kftbetu: string): boolean;
// =============================================================================

begin
  result := False;
  _pcs := 'SELECT * FROM KEZD'+ _farok + _sorveg;
  _pcs := _pcs + 'WHERE CEGBETU='+chr(39)+_kftbetu+chr(39);
  _pcs := _pcs + 'ORDER BY PENZTAR';

  KezdDbase.connected := True;
  with KezdQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _ptdarab := recno;
      First;
    end;

  if _ptdarab=0 then
    begin
      KezdQuery.close;
      Kezddbase.close;
      Exit;
    end;
  result := true;
end;


// =============================================================================
               procedure TForm2.Keret(_rs: string; _wide: byte);
// =============================================================================

begin
  _oxl.worksheets[_yyy].range[_rs].Borderaround(1,_wide);
end;

// =============================================================================
            procedure TForm2.KezdParancs(_ukaz: string);
// =============================================================================

begin
  KezdDbase.connected := true;
  if kezdtranz.InTransaction then kezdtranz.commit;
  KezdTranz.StartTransaction;

  with KezdQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Kezdtranz.commit;
  Kezddbase.close;
end;


// =============================================================================
                  procedure  Tform2.Makekezdtabla(_tnev: string);
// =============================================================================


begin
  KezdDbase.close;

//  Memo1.Lines.add('A ' + _tnev + ' nevü interbase táblát készitem ...');
  _pcs := 'CREATE TABLE ' + _tnev +' (' +_sorveg;
  _pcs := _pcs + 'PENZTAR SMALLINT,' +_sorveg;
  _pcs := _pcs + 'KDV1 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE1 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV2 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE2 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV3 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE3 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV4 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE4 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV5 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE5 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV6 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE6 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV7 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE7 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV8 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE8 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV9 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE9 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV10 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE10 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV11 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE11 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV12 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE12 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV13 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE13 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV14 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE14 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV15 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE15 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV16 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE16 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV17 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE17 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV18 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE18 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV19 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE19 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV20 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE20 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV21 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE21 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV22 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE22 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV23 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE23 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV24 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE24 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV25 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE25 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV26 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE26 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV27 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE27 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV28 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE28 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV29 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE29 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV30 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE30 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDV31 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KDE31 INTEGER,' +_sorveg;
  _pcs := _pcs + 'BANKKOD INTEGER,'+ _sorveg;
  _pcs := _pcs + 'CEGBETU CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250)';
  KezdParancs(_pcs);
end;


// =============================================================================
               function TForm2.EzEtar(_PTR: byte): boolean;
// =============================================================================

begin
  result := true;
  if (_ptr=10) or (_ptr=20) or (_ptr=40) or (_ptr=50) or (_ptr=63) then exit;
  if (_ptr=75) or (_ptr=120) or (_ptr=145) then exit;
  result := False;
end;
end.
