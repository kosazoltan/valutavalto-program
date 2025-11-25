unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery,
  Strutils, COmObj, ComCtrls, IBTable, TlHelp32, Grids, DBGrids, Buttons;

type
  TForm2 = class(TForm)
    KILEPO: TTimer;
    RECEPTORQUERY: TIBQuery;
    RECEPTORDBASE: TIBDatabase;
    RECEPTORTRANZ: TIBTransaction;
    DAYBQUERY: TIBQuery;
    DAYBDBASE: TIBDatabase;
    DAYBTRANZ: TIBTransaction;
    HRKQUERY: TIBQuery;
    HRKDBASE: TIBDatabase;
    HRKTRANZ: TIBTransaction;
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    VTABLA: TIBTable;
    ALAPLAP: TPanel;
    Label1: TLabel;
    RACSPANEL: TPanel;
    HRKRACS: TDBGrid;
    HRKSOURCE: TDataSource;
    HRKQUERYPENZTARSZAM: TSmallintField;
    HRKQUERYPENZTARKOD: TIBStringField;
    HRKQUERYPENZTARNEV: TIBStringField;
    HRKQUERYV1: TIntegerField;
    HRKQUERYE1: TIntegerField;
    HRKQUERYV2: TIntegerField;
    HRKQUERYE2: TIntegerField;
    HRKQUERYV3: TIntegerField;
    HRKQUERYE3: TIntegerField;
    HRKQUERYV4: TIntegerField;
    HRKQUERYE4: TIntegerField;
    HRKQUERYV5: TIntegerField;
    HRKQUERYE5: TIntegerField;
    HRKQUERYV6: TIntegerField;
    HRKQUERYE6: TIntegerField;
    HRKQUERYV7: TIntegerField;
    HRKQUERYE7: TIntegerField;
    HRKQUERYV8: TIntegerField;
    HRKQUERYE8: TIntegerField;
    HRKQUERYV9: TIntegerField;
    HRKQUERYE9: TIntegerField;
    HRKQUERYV10: TIntegerField;
    HRKQUERYE10: TIntegerField;
    HRKQUERYV11: TIntegerField;
    HRKQUERYE11: TIntegerField;
    HRKQUERYV12: TIntegerField;
    HRKQUERYE12: TIntegerField;
    HRKQUERYV13: TIntegerField;
    HRKQUERYE13: TIntegerField;
    HRKQUERYV14: TIntegerField;
    HRKQUERYE14: TIntegerField;
    HRKQUERYV15: TIntegerField;
    HRKQUERYE15: TIntegerField;
    HRKQUERYV16: TIntegerField;
    HRKQUERYE16: TIntegerField;
    HRKQUERYV17: TIntegerField;
    HRKQUERYE17: TIntegerField;
    HRKQUERYV18: TIntegerField;
    HRKQUERYE18: TIntegerField;
    HRKQUERYV19: TIntegerField;
    HRKQUERYE19: TIntegerField;
    HRKQUERYV20: TIntegerField;
    HRKQUERYE20: TIntegerField;
    HRKQUERYV21: TIntegerField;
    HRKQUERYE21: TIntegerField;
    HRKQUERYV22: TIntegerField;
    HRKQUERYE22: TIntegerField;
    HRKQUERYV23: TIntegerField;
    HRKQUERYE23: TIntegerField;
    HRKQUERYV24: TIntegerField;
    HRKQUERYE24: TIntegerField;
    HRKQUERYV25: TIntegerField;
    HRKQUERYE25: TIntegerField;
    HRKQUERYV26: TIntegerField;
    HRKQUERYE26: TIntegerField;
    HRKQUERYV27: TIntegerField;
    HRKQUERYE27: TIntegerField;
    HRKQUERYV28: TIntegerField;
    HRKQUERYE28: TIntegerField;
    HRKQUERYV29: TIntegerField;
    HRKQUERYE29: TIntegerField;
    HRKQUERYV30: TIntegerField;
    HRKQUERYE30: TIntegerField;
    HRKQUERYV31: TIntegerField;
    HRKQUERYE31: TIntegerField;
    HRKQUERYVSUM: TIntegerField;
    HRKQUERYESUM: TIntegerField;
    HRKQUERYERTEKTAR: TSmallintField;
    CSIK: TProgressBar;
    Label2: TLabel;
    Label3: TLabel;
    PENZTARNEVEDIT: TEdit;
    KORZETNEVEDIT: TEdit;
    Label4: TLabel;
    DNEMPANEL: TPanel;
    Label5: TLabel;
    PENZTARGOMB: TBitBtn;
    KORZETGOMB: TBitBtn;
    KILEPOGOMB: TBitBtn;
    HRKHUFGOMB: TBitBtn;
    CHANGEGOMB: TBitBtn;
    HUFSOURCE: TDataSource;
    HUFQUERY: TIBQuery;
    HUFDBASE: TIBDatabase;
    HUFTRANZ: TIBTransaction;
    EXCELGOMB: TBitBtn;
    HUFRACS: TDBGrid;
    HUFQUERYPENZTARSZAM: TSmallintField;
    HUFQUERYPENZTARKOD: TIBStringField;
    HUFQUERYPENZTARNEV: TIBStringField;
    HUFQUERYV1: TIntegerField;
    HUFQUERYE1: TIntegerField;
    HUFQUERYV2: TIntegerField;
    HUFQUERYE2: TIntegerField;
    HUFQUERYV3: TIntegerField;
    HUFQUERYE3: TIntegerField;
    HUFQUERYV4: TIntegerField;
    HUFQUERYE4: TIntegerField;
    HUFQUERYV5: TIntegerField;
    HUFQUERYE5: TIntegerField;
    HUFQUERYV6: TIntegerField;
    HUFQUERYE6: TIntegerField;
    HUFQUERYV7: TIntegerField;
    HUFQUERYE7: TIntegerField;
    HUFQUERYV8: TIntegerField;
    HUFQUERYE8: TIntegerField;
    HUFQUERYV9: TIntegerField;
    HUFQUERYE9: TIntegerField;
    HUFQUERYV10: TIntegerField;
    HUFQUERYE10: TIntegerField;
    HUFQUERYV11: TIntegerField;
    HUFQUERYE11: TIntegerField;
    HUFQUERYV12: TIntegerField;
    HUFQUERYE12: TIntegerField;
    HUFQUERYV13: TIntegerField;
    HUFQUERYE13: TIntegerField;
    HUFQUERYV14: TIntegerField;
    HUFQUERYE14: TIntegerField;
    HUFQUERYV15: TIntegerField;
    HUFQUERYE15: TIntegerField;
    HUFQUERYV16: TIntegerField;
    HUFQUERYE16: TIntegerField;
    HUFQUERYV17: TIntegerField;
    HUFQUERYE17: TIntegerField;
    HUFQUERYV18: TIntegerField;
    HUFQUERYE18: TIntegerField;
    HUFQUERYV19: TIntegerField;
    HUFQUERYE19: TIntegerField;
    HUFQUERYV20: TIntegerField;
    HUFQUERYE20: TIntegerField;
    HUFQUERYV21: TIntegerField;
    HUFQUERYE21: TIntegerField;
    HUFQUERYV22: TIntegerField;
    HUFQUERYE22: TIntegerField;
    HUFQUERYV23: TIntegerField;
    HUFQUERYE23: TIntegerField;
    HUFQUERYV24: TIntegerField;
    HUFQUERYE24: TIntegerField;
    HUFQUERYV25: TIntegerField;
    HUFQUERYE25: TIntegerField;
    HUFQUERYV26: TIntegerField;
    HUFQUERYE26: TIntegerField;
    HUFQUERYV27: TIntegerField;
    HUFQUERYE27: TIntegerField;
    HUFQUERYV28: TIntegerField;
    HUFQUERYE28: TIntegerField;
    HUFQUERYV29: TIntegerField;
    HUFQUERYE29: TIntegerField;
    HUFQUERYV30: TIntegerField;
    HUFQUERYE30: TIntegerField;
    HUFQUERYV31: TIntegerField;
    HUFQUERYE31: TIntegerField;
    HUFQUERYVSUM: TIntegerField;
    HUFQUERYESUM: TIntegerField;
    HUFQUERYERTEKTAR: TSmallintField;
    HUFQUERYKORZETNEV: TIBStringField;
    HRKQUERYKORZETNEV: TIBStringField;
    GOMBTAKARO: TPanel;

    procedure FormActivate(Sender: TObject);
    procedure IdoszakBeolvasas;
    procedure MakePenztarsor;
    procedure MakeExcel;
    procedure Vekony(_rs: string);
    procedure Vastag(_rs: string);
    procedure PenztarAdatOLvasas;
    procedure HrkParancs(_ukaz: string);
    procedure Adatbeiras;
    procedure MakeWorkPlace;
    procedure HrkLegyujtes;
    procedure ExcelZaro;
    procedure KillExcel;
    procedure HrkRacsDisplay;
    procedure HufRacsDisplay;
    procedure AdatSummazas;
    procedure Nullazas;
    procedure RekordValtas;

    procedure KILEPOTimer(Sender: TObject);

    function ScanKorzet(_k: byte): byte;
    function Getkorzetnev(_kz: byte): string;
    procedure EXCELGOMBClick(Sender: TObject);
    procedure KILEPOGOMBClick(Sender: TObject);
    procedure HRKHUFGOMBClick(Sender: TObject);
    procedure PENZTARGOMBClick(Sender: TObject);
    procedure KORZETGOMBClick(Sender: TObject);
    procedure CHANGEGOMBClick(Sender: TObject);
    procedure HRKRACSCellClick(Column: TColumn);
    procedure HRKRACSDblClick(Sender: TObject);
    procedure HRKRACSKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _honev: array[1..12] of string = ('január','február','március','április',
               'május','jumius','július','augusztus','szeptember','október',
               'november','december');

  _ptnev,_ptbankkod: array[1..150] of string;
  _penztarsor,_ptk,_ptkorzet: array[1..150] of byte;
  _korzetszam: array[1..8] of byte = (10,20,40,50,63,75,120,145);
  _korzetnev: array[1..8] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT','DEBRECEN',
                     'NYÍREGYHÁZA','BÉKÉSCSABA','PÉCS','KAPOSVÁR');

  _vnaposz: array[1..31] of string = ('B','D','F','H','J','L','N','P','R','T',
                    'V','X','Z','AB','AD','AF','AH','AJ','AL','AN','AP','AR',
                    'AT','AV','AX','AZ','BB','BD','BF','BH','BJ');

  _enaposz: array[1..31] of string = ('C','E','G','I','K','M','O','Q','S','U',
                    'W','Y','AA','AC','AE','AG','AI','AK','AM','AO','AQ','AS',
                    'AU','AW','AY','BA','BC','BE','BG','BI','BK');

  _sumhrk: array[1..31] of integer;
  _kvsum,_kesum: array[1..8] of integer;
  _cegvsum,_cegesum: integer;

  // summazas:

  _kv,_ke: array[1..8,1..31] of integer;
  _sv,_se,_rv,_re: array[1..31] of integer;

  _idszOke,_mResult,_code,_recno,_bankjegy,_akthrk,_vsum,_esum,_akthuf: integer;
  _aktv,_akte,_vhuf: integer;

  _tolString,_igstring,_farok,_aktdaybook,_tolnaps,_ignaps,_pcs,_mezo,_akthos: string;
  _jel,_focim,_rangestr,_last,_workPlace,_vFormula,_eFormula,_pris,_VPCS: string;
  _vosz,_eosz,_bt,_aktfdb,_datum,_naps,_aktptnev,_aktbankkod,_hrktablaNev: string;
  _svFormula,_seFormula,_excelPath,_aktkorzetnev,_aktvaluta,_vmezo,_emezo: string;
  _egyseg,_pnev,_knev: string;
  _sorveg: string = chr(13)+chr(10);

  _tolnap,_ignap,_oszlop,_sszam,_sumsor,_prisor,_vy,_cc,_aktho: word;
  _ptss,_penztarDarab,_pt,_nap,_aktpt,_aktk,_xx,_aktkorzet,_etar,_kz: byte;
  _nyitvavolt,_vanexcel,_looper: boolean;

  _Handle: HWND;
  _Proc: PROCESSENTRY32;

  _oxl,_owb,_range: olevariant;

function hovalasztorutin: integer; stdcall; external 'c:\receptor\newdll\hovalasz.dll';
function horvatkunarutinok: integer; stdcall;


implementation

{$R *.dfm}


// =============================================================================
               function horvatkunarutinok: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.showModal;
  Form2.Free;
end;


// =============================================================================
           procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _mresult  := 1;
  _vanexcel := False;

  _idszOke  := hovalasztorutin;
  if _idszOke=-1 then
    begin
      Kilepo.enabled := true;
      exit;
    end;

  Idoszakbeolvasas;
  _farok := midstr(_tolstring,3,2)+midstr(_tolstring,6,2);
  _hrkTablaNev := 'HRK'+_farok;

  _BT   := 'BT' + _farok;
  _Vpcs := 'SELECT * FROM ' + _BT + _sorveg;
  _Vpcs := _Vpcs + 'WHERE (VALUTANEM='+chr(39)+'HRK'+chr(39)+') ';
  _Vpcs := _VPCS + 'AND (BIZONYLATSZAM LIKE '+chr(39)+'V%'+chr(39)+') ';
  _vpcs := _vpcs + 'AND (STORNO=1) AND (ELOJEL='+chr(39)+'+'+chr(39)+')';

  MakePenztarSor;
  PenztarAdatOlvasas;
  HrkLegyujtes;
  with Racspanel do
    begin
      top  := 96;
      left := 24;
      Visible := true;
    end;
  Csik.Position := 0;
  _egyseg := 'P';
  HrkRacsdisplay;
end;

// =============================================================================
                procedure TForm2.IdoszakBeolvasas;
// =============================================================================

begin
  ReceptorDbase.Connected := true;
  with ReceptorQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM IDOSZAK');
      Open;

      _tolstring := FieldByNAme('STARTDATE').asString;
      _igstring := FieldByName('ENDDATE').asString;
      Close;
    end;
  ReceptorDbase.close;
  _tolnaps := midstr(_tolstring,9,2);
  _ignaps  := midstr(_igstring,9,2);
  _akthos  := midstr(_tolstring,6,2);
  val(_akthos,_aktho,_code);
  val(_tolnaps,_tolnap,_code);
  val(_ignaps,_ignap,_code);

  _excelPath := 'c:\receptor\mail\posta\HRK'+ _farok + '.xls';
end;


// =============================================================================
                  procedure TForm2.MakePenztarSor;
// =============================================================================

begin
  _aktDaybook := 'DAYB' + _farok;
  _pcs        := 'SELECT * FROM ' + _aktDaybook + ' ORDER BY PENZTAR';

  Daybdbase.Connected := true;
  with DaybQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  Csik.Max := 150;
  _ptss := 0;
  _cc := 0;
  while not Daybquery.Eof do
    begin
      inc(_cc);
      csik.Position := _cc;

      _pt         := Daybquery.fieldbyName('PENZTAR').asInteger;
      _nyitvavolt := False;
      _nap        := _tolnap;

      while _nap<=_ignap do
        begin
          _mezo := 'N' + inttostr(_nap);
          _jel := Daybquery.FieldByName(_mezo).asString;

          if _jel='B' then
            begin
              _nyitvaVolt := True;
              Break;
            end;
          inc(_nap);
        end;

      // Ha a hónapban egy napon is nyitva volt:
      if _nyitvavolt then
        begin
          _aktFdb := 'c:\receptor\database\V' + inttostr(_pt) + '.fdb';

          with vDbase do
            begin
              Close;
              DatabaseName := _aktFdb;
              Connected := true;
            end;

          VTabla.close;
          VTabla.Tablename := _bt;

          if vTabla.Exists then
            begin
              with vQuery do
                begin
                  Close;
                  Sql.clear;
                  Sql.add(_vpcs);
                  Open;
                  _recno := recno;
                  Close;
                end;

              // Ha volt még HRK vétel is, akkor bekerül a pénztársorba
              if _recno>0 then
                begin
                  inc(_ptss);
                  _penztarsor[_ptss] := _pt;
                end;

              // A vtabla bezárva:
              vQuery.Close;
            end;

           // A teljes penztari adatbázis lezárva:
           vDbase.close;
        end;
      //  Jöhet a következö Daybook penztar:
      DaybQuery.Next;
    end;

  Csik.Position := 150;

  // Ennyi pénztárban volt HRK forgalom:
  _penztarDarab := _ptss;

  // Végül a daybook is bezárul:

  DaybQuery.close;
  DaybDbase.close;
end;

// =============================================================================
                 procedure TForm2.PenztarAdatOlvasas;
// =============================================================================

begin
  ReceptorDbase.Connected := true;

  // Csak a HRK -forgalmat bonyolitott pénztárak:
  _ptss := 1;
  Csik.Max := _penztarDarab;
  while _ptss<=_penztardarab do
    begin
      Csik.Position := _ptss;

      _aktpt := _penztarsor[_ptss];

      _pcs := 'SELECT * FROM IRODAK WHERE UZLET='+inttostr(_aktpt);
      with ReceptorQuery do
        begin
          Close;
          Sql.clear;
          Sql.add(_pcs);
          Open;

          _ptnev[_aktpt]     := trim(FieldByName('KESZLETNEV').asString);
          _ptk[_aktpt]       := FieldByName('ERTEKTAR').asInteger;
          _ptbankkod[_aktpt] := trim(FieldByName('BANKKOD').asString);

          Close;
        end;

      _aktK := _ptk[_aktpt];
      _xx   := Scankorzet(_aktk);

      _ptKorzet[_aktpt] := _xx;

      inc(_ptss);
    end;

  ReceptorDbase.close;
end;

// =============================================================================
                   procedure TForm2.HrkLegyujtes;
// =============================================================================

var i: byte;

begin
  _pcs := 'DELETE FROM ' + _hrkTablaNev;
  HrkParancs(_pcs);

  // Végigmegyümk a HRK-t forgalmazó pénztárakon:

  _ptss := 1;
  Csik.Max := _penztardarab;

  while _ptss<=_penztardarab do
    begin
      Csik.position := _ptss;

      _aktpt  := _penztarsor[_ptss];
      _aktfdb := 'c:\receptor\database\v' + inttostr(_aktpt) + '.fdb';

      with VDbase do
        begin
          Close;
          DatabaseName := _aktfdB;
          Connected    := True;
        end;

      with Vquery do
        begin
          Close;
          sql.clear;
          sql.add(_Vpcs);
          Open;
        end;

      // Kinullázza a napok HRK forgalmát:

      for i := 1 to 31 do _sumHrk[i] := 0;

      // Beolvassa azokat a napokat. ahol volt HRK vétel:
      while not vQuery.Eof do
        begin
          // Melyik napon volt a vétel:

          _datum := vQuery.FieldByName('DATUM').asString;
          _naps  := midstr(_datum,9,2);
          val(_naps,_nap,_code);

          // Mennyi HRK-t vásároltunk:
          _bankjegy := VQuery.FieldByNAme('BANKJEGY').asInteger;

          // Besummázza a megfelelö nap tömbjébe:
          _sumHrk[_nap] := _sumHrk[_nap] + _bankjegy;

          // következö vétel:
          Vquery.Next;
        end;

      // A pénztar adatbázisa lezárva:
      vQuery.Close;
      vDbase.Close;

      // A pénztár többi adata a tömbökböl:

      _aktPtNev   := _ptnev[_aktPt];
      _aktbankkod := _ptBankKod[_aktpt];
      _aktkorzet  := _ptk[_aktpt];

      // A rekordot beirja a havi HRK adatbázisba:

      _pcs := 'INSERT INTO ' +_hrkTablanev + ' (PENZTARSZAM,PENZTARKOD,PENZTARNEV,V1,E1,';
      _pcs := _pcs + 'V2,E2,V3,E3,V4,E4,V5,E5,V6,E6,V7,E7,V8,E8,V9,E9,V10,E10,';
      _pcs := _pcs + 'V11,E11,V12,E12,V13,E13,V14,E14,V15,E15,V16,E16,V17,E17,';
      _pcs := _pcs + 'V18,E18,V19,E19,V20,E20,V21,E21,V22,E22,V23,E23,V24,E24,';
      _pcs := _pcs + 'V25,E25,V26,E26,V27,E27,V28,E28,V29,E29,V30,E30,';
      _pcs := _pcs + 'V31,E31,VSUM,ESUM,ERTEKTAR,KORZETNEV)' + _sorveg;

      _pcs := _pcs + 'VALUES (' + inttostr(_aktpt)+',';
      _pcs := _pcs + chr(39) + _aktbankkod + chr(39)+',';
      _pcs := _pcs + chr(39) + _aktPtNev + chr(39) + ',';

      _nap  := 1;
      _vsum := 0;
      while _nap<=31 do
        begin
          // A napi HRK vétel:
          _akthrk := _sumhrk[_nap];

          // Besummázza a havi tömbbe:
          _vsum   := _vsum + _akthrk;

          // Beirja a napi vételt és eladast ?? a rekordba:
          _pcs := _pcs + inttostr(_akthrk)+',';
          _aktHuf := trunc(35*_akthrk);
          _pcs := _pcs + inttostr(_akthuf)+',';
          inc(_nap);
        end;

      // a rekord végén a havi vétel-eladas ?? summa:
      _pcs := _pcs + inttostr(_vsum)+',';
      _esum := trunc(35*_vsum);
      _pcs := _pcs + inttostr(_esum) + ',';

      // És végül a pénztár értéktárra:
      _pcs := _pcs + inttostr(_aktkorzet) + ',';
      _aktkorzetnev := GetKorzetnev(_aktkorzet);
      _pcs := _pcs + chr(39) + _aktkorzetnev + chr(39) + ')';

      // Felirja a rekordot
      HrkParancs(_pcs);

      // Következõ pénztár:
      inc(_ptss);
    end;
  Adatsummazas;
end;


// =============================================================================
             procedure TForm2.HrkParancs(_ukaz: string);
// =============================================================================

begin
  HrkDbase.Connected := true;
  if HrkTranz.InTransaction then HrkTranz.Commit;
  HrkTranz.StartTransaction;
  with HrkQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_ukaz);
      ExecSql;
    end;
  HrkTranz.Commit;
  HrkDbase.Close;
end;

// =============================================================================
            procedure TForm2.KilepoTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  if _aktvaluta='HRK' then
    begin
      Hrkquery.close;
      Hrkdbase.close;
    end else
    begin
      Hufquery.close;
      Hufdbase.close;
    end;
  Excelzaro;
  ModalResult    := _mResult;
end;

// =============================================================================
                 function TForm2.ScanKorzet(_k: byte): byte;
// =============================================================================

var _y: byte;

begin
  Result := 0;
  _y := 1;
  while _y<=8 do
    begin
      if _korzetSzam[_y]=_k then
        begin
          Result := _y;
          Exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
                       procedure TForm2.MakeExcel;
// =============================================================================

begin
  _focim := leftstr(_tolstring,4)+' '+_honev[_aktho]+'-i HRK váltások';

  _oxl := CreateOleObject('EXCEL.APPLICATION');
  _owb := _oxl.workbooks.add[1];

  _rangestr := 'B1:P1';
  _oxl.range[_rangestr].mergecells  := true;
  _oxl.range[_rangestr].font.Name   := 'Calibri';
  _oxl.range[_rangestr].font.size   := 18;
  _oxl.range[_rangestr].Font.italic := True;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;
  _oxl.cells[1,2] := _focim;

  _oxl.range['A1:A1'].columnwidth := 14;
  _oxl.range['B1:B1'].columnwidth := 11;
  _oxl.range['C1:C1'].columnwidth := 11;
  _oxl.range['D1:D1'].columnwidth := 11;
  _oxl.range['E1:E1'].columnwidth := 11;
  _oxl.range['F1:F1'].columnwidth := 11;
  _oxl.range['G1:G1'].columnwidth := 11;
  _oxl.range['H1:H1'].columnwidth := 11;
  _oxl.range['I1:I1'].columnwidth := 11;
  _oxl.range['J1:J1'].columnwidth := 11;
  _oxl.range['K1:K1'].columnwidth := 11;
  _oxl.range['L1:L1'].columnwidth := 11;
  _oxl.range['M1:M1'].columnwidth := 11;
  _oxl.range['N1:N1'].columnwidth := 11;
  _oxl.range['O1:O1'].columnwidth := 11;
  _oxl.range['P1:P1'].columnwidth := 11;
  _oxl.range['Q1:Q1'].columnwidth := 11;
  _oxl.range['R1:R1'].columnwidth := 11;
  _oxl.range['S1:S1'].columnwidth := 11;
  _oxl.range['T1:T1'].columnwidth := 11;
  _oxl.range['U1:U1'].columnwidth := 11;
  _oxl.range['V1:V1'].columnwidth := 11;
  _oxl.range['W1:W1'].columnwidth := 11;
  _oxl.range['X1:X1'].columnwidth := 11;
  _oxl.range['Y1:Y1'].columnwidth := 11;
  _oxl.range['Z1:Z1'].columnwidth := 11;
  _oxl.range['AA1:AA1'].columnwidth := 11;
  _oxl.range['AB1:AB1'].columnwidth := 11;
  _oxl.range['AC1:AC1'].columnwidth := 11;
  _oxl.range['AD1:AD1'].columnwidth := 11;
  _oxl.range['AE1:AE1'].columnwidth := 11;
  _oxl.range['AF1:AF1'].columnwidth := 11;
  _oxl.range['AG1:AG1'].columnwidth := 11;
  _oxl.range['AH1:AH1'].columnwidth := 11;
  _oxl.range['AI1:AI1'].columnwidth := 11;
  _oxl.range['AJ1:AJ1'].columnwidth := 11;
  _oxl.range['AK1:AK1'].columnwidth := 11;
  _oxl.range['AL1:AL1'].columnwidth := 11;
  _oxl.range['AM1:AM1'].columnwidth := 11;
  _oxl.range['AN1:AN1'].columnwidth := 11;
  _oxl.range['AO1:AO1'].columnwidth := 11;
  _oxl.range['AP1:AP1'].columnwidth := 11;
  _oxl.range['AQ1:AQ1'].columnwidth := 11;
  _oxl.range['AR1:AR1'].columnwidth := 11;
  _oxl.range['AS1:AS1'].columnwidth := 11;
  _oxl.range['AT1:AT1'].columnwidth := 11;
  _oxl.range['AU1:AU1'].columnwidth := 11;
  _oxl.range['AV1:AV1'].columnwidth := 11;
  _oxl.range['AW1:AW1'].columnwidth := 11;
  _oxl.range['AX1:AX1'].columnwidth := 11;
  _oxl.range['AY1:AY1'].columnwidth := 11;
  _oxl.range['AZ1:AZ1'].columnwidth := 11;
  _oxl.range['BA1:BA1'].columnwidth := 11;
  _oxl.range['BB1:BB1'].columnwidth := 11;
  _oxl.range['BC1:BC1'].columnwidth := 11;
  _oxl.range['BD1:BD1'].columnwidth := 11;
  _oxl.range['BE1:BE1'].columnwidth := 11;
  _oxl.range['BF1:BF1'].columnwidth := 11;
  _oxl.range['BG1:BG1'].columnwidth := 11;
  _oxl.range['BH1:BH1'].columnwidth := 11;
  _oxl.range['BI1:BI1'].columnwidth := 11;
  _oxl.range['BJ1:BJ1'].columnwidth := 11;
  _oxl.range['BK1:BK1'].columnwidth := 11;
  _oxl.range['BL1:BL1'].columnwidth := 11;
  _oxl.range['BM1:BM1'].columnwidth := 11;

  _oxl.range['A2:BM3'].HorizontalAlignment := -4108;
  _oxl.range['A2:BM3'].Font.Name := 'Calibri';
  _oxl.range['A2:BM3'].Font.Size := 12;
  _oxl.range['A2:BM3'].Font.Bold := True;

  _oxl.range['B2:C2'].Mergecells := True;
  _oxl.range['D2:E2'].Mergecells := True;
  _oxl.range['F2:G2'].Mergecells := True;
  _oxl.range['H2:I2'].Mergecells := True;
  _oxl.range['J2:K2'].Mergecells := True;
  _oxl.range['L2:M2'].Mergecells := True;
  _oxl.range['N2:O2'].Mergecells := True;
  _oxl.range['P2:Q2'].Mergecells := True;
  _oxl.range['R2:S2'].Mergecells := True;
  _oxl.range['T2:U2'].Mergecells := True;
  _oxl.range['V2:W2'].Mergecells := True;
  _oxl.range['X2:Y2'].Mergecells := True;
  _oxl.range['Z2:AA2'].Mergecells := True;
  _oxl.range['AB2:AC2'].Mergecells := True;
  _oxl.range['AD2:AE2'].Mergecells := True;
  _oxl.range['AF2:AG2'].Mergecells := True;
  _oxl.range['AH2:AI2'].Mergecells := True;
  _oxl.range['AJ2:AK2'].Mergecells := True;
  _oxl.range['AL2:AM2'].Mergecells := True;
  _oxl.range['AN2:AO2'].Mergecells := True;
  _oxl.range['AP2:AQ2'].Mergecells := True;
  _oxl.range['AP2:AQ2'].Mergecells := True;
  _oxl.range['AR2:AS2'].Mergecells := True;
  _oxl.range['AT2:AU2'].Mergecells := True;
  _oxl.range['AV2:AW2'].Mergecells := True;
  _oxl.range['AX2:AY2'].Mergecells := True;
  _oxl.range['AZ2:BA2'].Mergecells := True;
  _oxl.range['BB2:BC2'].Mergecells := True;
  _oxl.range['BD2:BE2'].Mergecells := True;
  _oxl.range['BF2:BG2'].Mergecells := True;
  _oxl.range['BH2:BI2'].Mergecells := True;
  _oxl.range['BJ2:BK2'].Mergecells := True;
  _oxl.range['BL2:BM2'].Mergecells := True;

  _oxl.range['A2:A3'].MergeCells := True;
  _oxl.range['A2:A3'].WrapText := true;

  _oxl.cells[2,1] := 'TELEPHELY KÓD';

  _oszlop := 2;
  _sszam  := 1;
  while _sszam<=31 do
    begin
      _oxl.cells[2,_oszlop] := inttostr(_sszam);
      inc(_oszlop);
      inc(_oszlop);
      inc(_sszam);
    end;

  _oxl.cells[2,_oszlop] := 'ÖSSZESEN';

  _oszlop := 2;
  while _oszlop<=65 do
    begin
      _oxl.Cells[3,_oszlop]   := 'HRK vétel';
      _oxl.Cells[3,_oszlop+1] := 'HUF eladás';
      _oszlop := _oszlop+2;
    end;

  _sumsor := 4 + _penztarDarab;
  _last   := inttostr(_sumsor);

  Vekony('B2:C' + _last);
  Vekony('F2:G' + _last);
  Vekony('J2:K' + _last);
  Vekony('N2:O' + _last);
  Vekony('R2:S' + _last);
  Vekony('V2:W' + _last);
  Vekony('Z2:AA' + _last);
  Vekony('AD2:AE' + _last);
  Vekony('AH2:AI' + _last);
  Vekony('AL2:AM' + _last);
  Vekony('AP2:AQ' + _last);
  Vekony('AT2:AU' + _last);
  Vekony('AX2:AY' + _last);
  Vekony('BB2:BC' + _last);
  Vekony('BF2:BG' + _last);
  Vekony('BJ2:BK' + _last);
  Vekony('B3:BM3');

  Vastag('A2:BM3');
  Vastag('A' + _last +':BM'+_last);
  Vastag('A2:BM' + _last);
  Vastag('A2:A'+_LAST);

  _oxl.Range['A'+_last+':A' + _last].Font.Size := 12;
  _oxl.Range['A'+_last+':A' + _last].Font.Bold := True;
  _oxl.Range['A'+_last+':A' + _last].HorizontalAlignment := -4108;
  _oxl.Cells[_sumsor,1] := 'ÖSSZESEN';

   _rangestr := 'B4:B4';
   _range := _oxl.Range[_rangestr];
   _range.Select;
   _oxl.ActiveWindow.FreezePanes := True;

   AdatBeiras;
   _vanexcel := True;

   Sysutils.DeleteFile(_excelPath);
   _owb.saveas(_excelpath);
  _oxl.Visible := True;
end;

// =============================================================================
               procedure TForm2.Vekony(_rs: string);
// =============================================================================

begin
  _oxl.range[_rs].borderaround(1,2);
end;

// =============================================================================
                procedure TForm2.Vastag(_rs: string);
// =============================================================================

begin
  _oxl.range[_rs].borderaround(1,4);
end;



// =============================================================================
                   procedure TForm2.MakeWorkPlace;
// =============================================================================

begin
  _workPlace := 'B4:BM'+_last;
  _oxl.range[_workplace].font.size := 10;
  _oxl.range[_workplace].HorizontalAlignment := -4108;
  _oxl.range[_workplace].numberformat := '### ### ###';
  _pris := inttostr(_sumsor-1);

  _oxl.range['A4:A'+_pris].HorizontalAlignment := -4108;

  _svFormula := '=SUM(BL4:BL'+_pris+')';
  _oxl.cells[_sumsor,64].formula := _svformula;

  _seFormula := '=SUM(BM4:BM'+_pris+')';
  _oxl.cells[_sumsor,65].formula := _seformula;



  _nap := 1;
  while _nap<=31 do
    begin
      _vosz := _vNapOsz[_nap];
      _eosz := _eNaposz[_nap];
      _vFormula := '=SUM('+_vosz+'4:'+_vosz+_pris+')';
      _eFormula := '=SUM('+_eosz+'4:'+_eosz+_pris+')';
      _vy := trunc(2*_nap);
      _oxl.cells[_sumsor,_vy].formula   := _vFormula;
      _oxl.cells[_sumsor,_vy+1].formula := _eFormula;
      inc(_nap);
    end;

end;


// =============================================================================
                   procedure TForm2.AdatBeiras;
// =============================================================================

           // Adatbázis bemásolása az excel - táblába

begin
  MakeWorkPlace;

  _pcs := 'SELECT * FROM ' + _hrktablanev + _sorveg;
  _pcs := _pcs + 'WHERE PENZTARSZAM>0' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTARSZAM';

  HrkDbase.Connected := True;
  with HrkQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
    end;

   _prisor := 3;
   while not HrkQuery.Eof do
     begin
       _aktPt      := HrkQuery.FieldByName('PENZTARSZAM').AsInteger;
       _aktBankKod := trim(HrkQuery.FieldByName('PENZTARKOD').AsString);
       _aktPtNev   := trim(HrkQuery.FieldByName('PENZTARNEV').asString);
       _aktKorzet  := HrkQuery.FieldByNAme('ERTEKTAR').asInteger;

       _nap := 1;
       while _nap<=31 do
         begin
           _mezo         := 'V' + inttostr(_nap);
           _sumHrk[_nap] := HrkQuery.FieldByName(_mezo).asInteger;
           inc(_nap);
         end;
       _vSum := HrkQuery.FieldByNAme('VSUM').asInteger;

       // ---------------------------------------------------

       if _vSum>0 then
         begin
           inc(_prisor);

           _oxl.Cells[_prisor,1] := _aktBankKod;
           _nap := 1;

           while _nap<=31 do
             begin
               _vy     := trunc(2*_nap);
               _aktHrk := _sumhrk[_nap];
               _aktHuf := trunc(35*_akthrk);

               _oxl.Cells[_prisor,_vy]   := _akthrk;
               _oxl.Cells[_prisor,_vy+1] := _akthuf;

               inc(_nap);
             end;
           _oxl.Cells[_prisor,64] := _vsum;
           _vhuf := trunc(_vsum*35);
           _oxl.Cells[_prisor,65] := _vhuf;
         end;
       HrkQuery.Next;
     end;
   HrkQuery.Close;
   HrkDbase.Close;
end;

// =============================================================================
                        procedure TForm2.ExcelZaro;
// =============================================================================

begin
  if _vanExcel then
    begin
      _oxl.quit;
      _oxl := unassigned;
      KillExcel;
    end;
end;

// =============================================================================
                  procedure TForm2.KillExcel;
// =============================================================================

var
  _fileName,_filePath: String;

begin
  _Proc.dwSize := SizeOf(_Proc);
  _handle := CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
  _Looper := Process32First(_handle,_proc);

  while Integer(_Looper) <> 0 do
    begin
      _filepath := _Proc.szExeFile;
      _fileName := UpperCase(ExtractFileName(_filepath));

      if _fileName = 'EXCEL.EXE' then
        begin
          TerminateProcess(OpenProcess(1,Bool(1),_proc.th32ProcessID),0);
          break;
        end;

      _Looper := Process32Next(_handle,_proc);
    end;
  CloseHandle(_handle);
end;

// =============================================================================
            function TForm2.Getkorzetnev(_kz: byte): string;
// =============================================================================

begin
  _xx := scanKorzet(_kz);
  result := _korzetnev[_xx];
end;

// =============================================================================
            procedure TForm2.EXCELGOMBClick(Sender: TObject);
// =============================================================================

begin
  HrkQuery.close;
  HufQuery.close;
  Hufdbase.close;
  Hrkdbase.close;
  HrkRacs.Visible := False;
  HufRacs.Visible := False;
  GombTakaro.Visible := True;
  MakeExcel;
end;

// =============================================================================
                 procedure TForm2.HrkRacsDisplay;
// =============================================================================

begin
  if _egyseg='P' then
    begin
      _pcs := 'SELECT * FROM ' + _hrktablanev + _sorveg;
      _pcs := _pcs + 'WHERE (PENZTARSZAM>0)';
    end;

  if _egyseg='K' then
    begin
      _pcs := 'SELECT * FROM ' + _hrktablanev + _sorveg;
      _pcs := _pcs + 'WHERE (PENZTARSZAM=0) AND (';
      _pcs := _pcs + 'ERTEKTAR>0)';
    end;

  if _egyseg='C' then
    begin
      _pcs := 'SELECT * FROM ' + _hrktablanev + _sorveg;
      _pcs := _pcs + 'WHERE (PENZTARSZAM=0) AND (ERTEKTAR=0)';
    end;

  HufRacs.Visible := False;
  Hufsource.Enabled := false;
  Hufquery.close;
  Hufdbase.close;

  Hrkdbase.Connected := True;
  with HrkQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_PCS);
      Open;
    end;

  _aktValuta := 'HRK';
  dnemPanel.Caption := _aktvaluta;

  HrkSource.Enabled := True;
  with Hrkracs do
    begin
      top := 32;
      left := 0;
      Visible := true;
      repaint;
    end;
  RekordValtas;
  Hrkracs.SetFocus;
end;

// =============================================================================
                   procedure TForm2.HufRacsDisplay;
// =============================================================================

begin
  if _egyseg='P' then
    begin
      _pcs := 'SELECT * FROM ' + _hrktablanev + _sorveg;
      _pcs := _pcs + 'WHERE (PENZTARSZAM>0)';
    end;

  if _egyseg='K' then
    begin
      _pcs := 'SELECT * FROM ' + _hrktablanev + _sorveg;
      _pcs := _pcs + 'WHERE (PENZTARSZAM=0) AND (';
      _pcs := _pcs + 'ERTEKTAR>0)';
    end;

  if _egyseg='C' then
    begin
      _pcs := 'SELECT * FROM ' + _hrktablanev + _sorveg;
      _pcs := _pcs + 'WHERE (PENZTARSZAM=0) AND (ERTEKTAR=0)';
    end;

  HrkRacs.Visible := False;
  Hrksource.Enabled := false;
  Hrkquery.close;
  Hrkdbase.close;

  Hufdbase.Connected := True;
  with HufQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_PCS);
      Open;
    end;

  _aktValuta := 'HUF';
  dnemPanel.Caption := _aktvaluta;

  HUFSource.Enabled := True;
  with Hufracs do
    begin
      top := 32;
      left := 0;
      Visible := true;
      repaint;
    end;
  RekordValtas;    
  Hufracs.SetFocus;
end;


// =============================================================================
            procedure TForm2.KILEPOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := True;
end;



// =============================================================================
           procedure TForm2.HRKHUFGOMBClick(Sender: TObject);
// =============================================================================

begin
  if _aktvaluta='HRK' then HufRacsDisplay
  else HrkRacsDisplay;
end;


// =============================================================================
                       procedure TForm2.AdatSummazas;
// =============================================================================

var i: byte;

begin
  Csik.Max := 3;
  Nullazas;

  Hrkdbase.connected := true;
  with HrkQuery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM '+ _hrkTablanev);
      Open;
    end;

  while not HrkQuery.eof do
    begin
      for i := 1 to 31 do
        begin
          _rv[i] := 0;
          _re[i] := 0;
        end;

      _etar := HrkQuery.FieldByName('ERTEKTAR').asInteger;
      _xx := Scankorzet(_etar);

      _nap := 1;
      while _nap<=31 do
        begin
          _vmezo := 'V' + inttostr(_nap);
          _emezo := 'E' + inttostr(_nap);
          _rv[_nap] := HrkQuery.fieldbyname(_vmezo).asInteger;
          _re[_nap] := HrkQuery.FieldByName(_eMezo).asInteger;
          inc(_nap);
        end;

      _nap := 1;
      while _nap<=31 do
        begin
          _kv[_xx,_nap] := _kv[_xx,_nap] + _rv[_nap];
          _ke[_xx,_nap] := _ke[_xx,_nap] + _re[_nap];

          _kvsum[_xx] := _kvsum[_xx] + _rv[_nap];
          _kesum[_xx] := _kesum[_xx] + _re[_nap];

          _sv[_nap] := _sv[_nap] + _rv[_nap];
          _se[_nap] := _se[_nap] + _re[_nap];

          _cegvsum := _cegvsum + _rv[_nap];
          _cegesum := _cegesum + _re[_nap];

          inc(_nap);
        end;
      Hrkquery.next;
    end;
  Csik.Position := 1;

  if hrktranz.InTransaction then hrktranz.commit;
  Hrktranz.StartTransaction;

  _kz := 1;
  while _kz<=8 do
    begin
      _aktv := _kvsum[_kz];
      if _aktv>0 then
        begin
          _pcs := 'INSERT INTO '+ _hrkTablanev + ' (KORZETNEV,V1,E1,V2,E2,V3,E3,V4,E4,';
          _pcs := _pcs + 'V5,E5,V6,E6,V7,E7,V8,E8,V9,E9,V10,E10,V11,E11,V12,E12,V13,E13,';
         _pcs := _pcs + 'V14,E14,V15,E15,V16,E16,V17,E17,V18,E18,V19,E19,V20,E20,V21,';
         _pcs := _pcs + 'E21,V22,E22,V23,E23,V24,E24,V25,E25,V26,E26,V27,E27,V28,E28,';
         _pcs := _pcs + 'V29,E29,V30,E30,V31,E31,VSUM,ESUM,ERTEKTAR,PENZTARSZAM)' + _sorveg;

         _pcs := _pcs + 'VALUES (';

         _aktkorzetnev := _korzetnev[_kz];
         _pcs := _pcs + chr(39) + _aktkorzetnev + chr(39) + ',';
         _nap := 1;

         while _nap<=31 do
           begin
             _aktv := _kv[_kz,_nap];
             _akte := _ke[_kz,_nap];
             _pcs := _pcs + inttostr(_aktv)+','+inttostr(_akte)+',';
             inc(_nap);
           end;

         _aktv := _Kvsum[_kz];
         _akte := _Kesum[_kz];

         _pcs := _pcs + inttostr(_aktv)+','+inttostr(_akte)+',';

         _pcs := _pcs + inttostr(_korzetszam[_KZ])+',0)';

         with HrkQuery do
           begin
             Close;
             sql.clear;
             sql.Add(_pcs);
             Execsql;
           end;
        end;
      inc(_kz);
    end;

  Csik.Position := 2;

  // ---------------EXCLUSIVE CHANGE ------------------------------

  _pcs := 'INSERT INTO '+ _hrkTablanev + ' (V1,E1,V2,E2,V3,E3,V4,E4,';
  _pcs := _pcs + 'V5,E5,V6,E6,V7,E7,V8,E8,V9,E9,V10,E10,V11,E11,V12,E12,V13,E13,';
  _pcs := _pcs + 'V14,E14,V15,E15,V16,E16,V17,E17,V18,E18,V19,E19,V20,E20,V21,';
  _pcs := _pcs + 'E21,V22,E22,V23,E23,V24,E24,V25,E25,V26,E26,V27,E27,V28,E28,';
  _pcs := _pcs + 'V29,E29,V30,E30,V31,E31,VSUM,ESUM,PENZTARSZAM,ERTEKTAR)' + _sorveg;

  _pcs := _pcs + 'VALUES (';
  _nap := 1;
  while _nap<=31 do
    begin
      _aktv := _sv[_nap];
      _akte := _se[_nap];
      _pcs := _pcs + inttostr(_aktv)+','+inttostr(_akte)+',';
      inc(_nap);
    end;
  _pcs := _pcs + inttostr(_cegvsum)+','+inttostr(_cegesum)+',';
  _pcs := _pcs + '0,0)';

  with HrkQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_pcs);
      Execsql;
    end;
  Hrktranz.Commit;
  Hrkdbase.close;
  Csik.Position := 3;
  sleep(1200);
end;


// =============================================================================
                        procedure TForm2.Nullazas;
// =============================================================================

begin
  _nap := 1;
  while _nap<=31 do
    begin
      _sv[_nap] := 0;
      _se[_nap] := 0;
      _kz := 1;
      while _kz<=8 do
        begin
          _kv[_kz,_nap] := 0;
          _ke[_kz,_nap] := 0;
          inc(_kz);
        end;
      inc(_nap);
    end;

  _kz := 1;
  while _kz<=8 do
    begin
      _kvsum[_kz] := 0;
      _kesum[_kz] := 0;
      inc(_kz);
    end;

  _cegvsum := 0;
  _cegesum := 0;

end;

procedure TForm2.PENZTARGOMBClick(Sender: TObject);
begin
  _egyseg := 'P';
  if _aktvaluta='HRK' then HRKRacsDisplay;
  if _aktvaluta='HUF' then HUFRacsDisplay;
end;

procedure TForm2.KORZETGOMBClick(Sender: TObject);
begin
  _egyseg := 'K';
  if _aktvaluta='HRK' then HRKRacsDisplay;
  if _aktvaluta='HUF' then HUFRacsDisplay;
end;

procedure TForm2.CHANGEGOMBClick(Sender: TObject);
begin
  _egyseg := 'C';
  if _aktvaluta='HRK' then HRKRacsDisplay;
  if _aktvaluta='HUF' then HUFRacsDisplay;
end;


procedure TForm2.Rekordvaltas;

begin
  if _aktvaluta='HUF' then
    begin
      _pnev := trim(Hufquery.fieldbyname('PENZTARNEV').asString);
      _knev := trim(HufQuery.FieldByNAme('KORZETNEV').asString);
    end else
    begin
      _pnev := trim(HrkQuery.fieldbyname('PENZTARNEV').asString);
      _knev := trim(HrkQuery.FieldByNAme('KORZETNEV').asString);
    end;
  Penztarnevedit.text := _pnev;
  Korzetnevedit.text := _knev+'-I KÖRZET';
  if (_pnev='') AND (_knev='') then
    begin
      Penztarnevedit.text := 'EXCLUSIVE CHANGE';
      KorzetNevEdit.Text := '';
    end;
end;

procedure TForm2.HRKRACSCellClick(Column: TColumn);
begin
  RekordValtas;
end;

procedure TForm2.HRKRACSDblClick(Sender: TObject);
begin
  RekordValtas;
end;

procedure TForm2.HRKRACSKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  RekordValtas;
end;

end.
