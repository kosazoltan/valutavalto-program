unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, StrUtils,
  ExtCtrls,TlHelp32, jpeg, DateUtils, Buttons, IBTable, comobj, Grids,
  Calendar;

type
  TForm2 = class(TForm)

    ArcQuery    : TIBQuery;
    ArcDBase    : TIBDatabase;
    ArcTranz    : TIBTransaction;

    GyujtoQuery : TIBQuery;
    GyujtoDBase : TIBDatabase;
    GyujtoTranz : TIBTransaction;

    JogiQuery   : TIBQuery;
    JogiDBase   : TIBDatabase;
    JogiTranz   : TIBTransaction;

    RecQuery    : TIBQuery;
    RecDBase    : TIBDatabase;
    RecTranz    : TIBTransaction;

    TulajQuery  : TIBQuery;
    TulajDbase  : TIBDatabase;
    TulajTranz  : TIBTransaction;
    TulajTabla  : TIBTable;

    VTabla      : TIBTable;
    VQuery      : TIBQuery;
    VDbase      : TIBDatabase;
    VTranz      : TIBTransaction;

    DatumPanel  : TPanel;
    Fuggony     : TPanel;
    Panel1      : TPanel;
    Panel3      : TPanel;
    XlsNevPanel : TPanel;

    BitBtn1     : TBitBtn;
    BitBtn3     : TBitBtn;
    BitBtn2     : TBitBtn;
    KilepoGomb  : TBitBtn;
    HonapOkeGomb: TBitBtn;

    Label1      : TLabel;
    Label2      : TLabel;
    Label3      : TLabel;
    Label4      : TLabel;
    Label5      : TLabel;
    FuggonyExcel: TLabel;

    Naptar      : TCalendar;
    Memo1       : TMemo;
    BFEJQUERY: TIBQuery;
    BFEJDBASE: TIBDatabase;
    BFEJTRANZ: TIBTransaction;

    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure GyujtoParancs(_ukaz: string);
    procedure GyujtoBeiras;
    procedure DaybookControl;
    procedure FormActivate(Sender: TObject);
    procedure HonapOkeGombClick(Sender: TObject);
    procedure KilepoGombClick(Sender: TObject);
    procedure Levalogatas;
    procedure NaptarKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure NaptarDblClick(Sender: TObject);
    procedure NaptarValtozott;
    procedure PenztarBeolvasas;
    procedure TulajKiolvasas;
    procedure ExcelKill;

    function Ezertektar(_pn: byte): boolean;
    function Nulele(_b: byte): string;
    function ScanPtar(_p: byte): byte;
  

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _host: string = '185.43.207.99';

  _penztarsor: array[1..150] of byte;
  _ptarnev: array[1..150] of string;

  _pBetu,_step,_y,_len,_evindex,_pp,_aktpenztar,_penztardb,_pt,_xx: byte;
  _aktpt,_wpl,_xlen,_kulfoldi: byte;

  _eloho,_aktnap,_aktho,_aktev,_kertev,_kertho,_kertnap,_cc: word;
  _recno,_code: integer;

  _akthonev,_elohonev,_evstring,_evs,_farok,_aktdayb,_pcs,_aktbf: string;
  _fdbPath,_ugyfFdb,_plombaszam,_sss,_xmbDataSors,_aktptnev: string;
  _xmbnevtabla,_xmbtablanev,_xsss,_excelnev,_napmezo,_betu: string;
  _xTulajnev,_xtulelozonev,_xTulajcim,_xTulszulhely,_xtulszulido: string;
  _xtulallamp,_xTulJelleg,_xTulMertek,_xtultarthely,_jogictrlnev: string;
  _bfejtablanev,_tulajtablanev,_naps,_joginev,_bizonylatszam: string;
  _telephely,_tulajnev,_tulelonev,_tulcim,_tulszulhely,_tulszulido: string;
  _tulallamp,_tultarthely,_tuljelleg,_tulmertek,_evtiz,_ugyfelfdb: string;
  _tulkozszerep: byte;

  _sorveg: string = chr(13)+chr(10);

  _oxl,_owb: olevariant;

  _korzetszamok: array[1..8] of byte = (10,20,40,50,63,75,120,145);
  _voltopen,_vanExcel,_looper: boolean;

  _honev: array[1..12] of string = ('JANUÁR','FEBRUÁR',
             'MÁRCIUS',
             'ÁPRILIS','MÁJUS','JUNIUS',
             'JÚLIUS',
             'AUGUSZTUS','SZEPTEMBER','OKTÓBER',
             'NOVEMBER','DECEMBER');

   _xnev,_xtelephelycim,_xOkiratszam,_xFotevekenyseg,_xMegbizottneve: string;
   _xmegbizottbeo,_xkepviseloneve,_xKepvisbeo,_xLastChange,_xiso: string;
   _focim,_rangestr,_ignums,_excelpath,_datumstring,_kertdatums,_jNums: string;
   _jAdoszam: string;

   _xpenztar,_xsorszam,_xmegbizottszama,_xkozszereplo,_xkUlfoldi: word;
   _xOsszesforint,_xEvimax,_xtranzdarab,_ugyfeldb,_prisor: integer;

   _handle: HWND;
   _PROC: PROCESSENTRY32;

   _TOP,_LEFT,_HEIGHT,_WIDTH: word;



implementation

uses Unit3;

{$R *.dfm}

// =============================================================================
             procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top := round((_height-570)/2);
  _left := round((_width-352)/2);

  Top  := _top;
  Left := _left;

   _vanexcel := False;
   _Y := 1;

  _aktnap   := dayof(Date);
  _aktho    := monthof(Date);
  _aktev    := yearof(Date);
  _akthonev := _honev[_AKTHO];

  Naptar.Year  := _aktev;
  Naptar.Month := _aktho;
  Naptar.Day   := _aktnap;

  _datumstring := inttostr(_aktev)+' '+_akthonev + ' '+inttostr(_aktnap);
  DatumPanel.Caption := _datumstring;
  DatumPanel.Repaint;

  Activecontrol := HonapOkeGomb;
end;

// =============================================================================
            procedure TForm2.BitBtn2Click(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;


// =============================================================================
         procedure TForm2.HONAPOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  HonapOkeGomb.Enabled := False;
  _kertev := Naptar.year;
  _kertho := Naptar.Month;
  _kertnap:= Naptar.Day;

  _kertdatums := inttostr(_kertev)+'.'+nulele(_kertho)+'.'+nulele(_kertnap);
  _evtiz  := inttostr(_kertev-2000);
  _farok  := _evtiz + nulele(_kertho);
  _bfejTablanev  := 'BF' + _farok;
  _tulajTablanev := 'TULAJ' + _farok;
  _ugyfelfdb := _HOST + ':C:\RECEPTOR\DATABASE\UGYFEL' + _EVTIZ + '.FDB';
  Memo1.Lines.Add('FELDOLGOZÁS INDUL');

  _naps := _farok+nulele(_kertnap);
  _excelnev  := 'JG' + _naps + '.xls';
  _excelPath := 'c:\jogiszemely\excel\' + _excelnev;
  xlsNevPanel.Caption := _excelnev;
  xlsNevPanel.Visible := true;

  DayBookControl;
  PenztarBeolvasas;

  Levalogatas;

  Form3.showmodal;   // exceltabla készítés

  Fuggony.Visible := True;
end;

// =============================================================================
                    procedure Tform2.PenztarBeolvasas;
// =============================================================================

begin
  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  with Recdbase do
    begin
      Close;
      Databasename := _host+':c:\receptor\database\receptor.fdb';
      Connected := true;
    end;

  recdbase.connected := true;
  with RecQuery do
    begin
      close;
      sql.clear;
      sql.add(_PCS);
      Open;
    end;

  while not recQuery.eof do
    begin
      _pt := RecQuery.fieldbyname('UZLET').asInteger;
      _xx := scanptar(_pt);
      if _xx>0 then
        begin
          _ptarnev[_xx] := trim(recquery.fieldByName('KESZLETNEV').asString);
        end;
       recquery.next;
     end;
   recQuery.close;
   recdbase.close;

   // --------------------------------------

  with Arcdbase do
    begin
      Close;
      databasename := _host+':c:\cartcash\database\artcash.fdb';
      Connected := true;
    end;

  with ArcQuery do
    begin
      close;
      sql.clear;
      sql.add(_PCS);
      Open;
    end;

  while not arcQuery.eof do
    begin
      _pt := ArcQuery.fieldbyname('UZLET').asInteger;
      _xx := scanptar(_pt);
      if _xx>0 then
        begin
          _ptarnev[_xx] := trim(arcquery.fieldByName('KESZLETNEV').asString);
        end;
       Arcquery.next;
     end;
   ArcQuery.close;
   Arcdbase.close;
end;

// =============================================================================
                function TForm2.ScanPtar(_p: byte): byte;
// =============================================================================

var _xp: byte;

begin
  result := 0;
  _xp := 1;
  while _xp<=_penztardb do
    begin
      if _penztarsor[_xp]=_p then
        begin
          result := _xp;
          exit;
        end;
      inc(_xp);
    end;
end;

// =============================================================================
                function TForm2.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
                       procedure TForm2.Levalogatas;
// =============================================================================

begin
  _pcs := 'DELETE FROM GYUJTO';
  GyujtoParancs(_pcs);

  _pt := 1;
  while _pt<=_penztardb do
    begin
      _aktpt    := _penztarsor[_pt];
      _aktptnev := _ptarnev[_pt];
      Memo1.Lines.add(_aktptnev);

      _fdbpath := _host+':c:\receptor\database\v'+inttostr(_aktpt)+'.fdb';
      if _aktpt>150 then _fdbPath := _host+':c:\cartcash\database\v'+inttostr(_aktpt)+'.fdb';

      with bfejdbase do
        begin
          close;
          databasename := _fdbPath;
        end;

      with vdbase do
        begin
          close;
          databasename := _fdbPath;
          Connected := True;
        end;

      Tulajkiolvasas;
      Vdbase.close;
      inc(_pt);
    end;
end;



// =============================================================================
            procedure TForm2.KilepoGombClick(Sender: TObject);
// =============================================================================

begin
  if _vanexcel then ExcelKill;
  Application.Terminate;
end;


// =============================================================================
                  procedure TForm2.ExcelKill;
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
            function Tform2.Ezertektar(_pn: byte): boolean;
// =============================================================================

var _k: byte;

begin
  result := true;
  _k := 1;
  while _k<=8 do
    begin
      if _korzetszamok[_k]=_pn then exit;
      inc(_k);
    end;
  result := False;
end;

// =============================================================================
                     procedure TForm2.NAPTARValtozott;
// =============================================================================

begin
  Naptar.Refresh;

  _kertev := Naptar.Year;
  _kertho := Naptar.Month;
  _kertnap:= Naptar.day;

  _datumstring := inttostr(_kertev)+' '+_honev[_kertho] + ' '+inttostr(_kertnap);
  DatumPanel.Caption := _datumstring;
  DatumPanel.Repaint;

  Activecontrol := HonapOkeGomb;

end;

// =============================================================================
              procedure TForm2.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  Naptar.PrevMonth;
  Naptarvaltozott;
end;

// =============================================================================
                 procedure TForm2.BitBtn3Click(Sender: TObject);
// =============================================================================

begin
  Naptar.NextMonth;
  NaptarValtozott;
end;

// =============================================================================
procedure TForm2.NAPTARKeyUp(Sender: TObject; var Key: Word;Shift: TShiftState);
// =============================================================================
begin
  NaptarValtozott;
end;

// ========== ===================================================================
             procedure TForm2.NAPTARDblClick(Sender: TObject);
// =============================================================================

begin
  Naptarvaltozott;
end;


////////////////////////////////////////////////////////////////////////////////
// ////////////////////////// ellenörzött procedurák ***************************
// =============================================================================
                   procedure TForm2.DaybookControl;
// =============================================================================

//  felállít egy 'penztarsor' tömböt, azokból a pénztárszámokból, amelyek
//  a kért napon beküldtek esti zárást. (4-168 pénztár intervasllumban);
//  A tömb mérete: [1-_penztardb]

begin
  _aktdayb := 'DAYB' + _farok;
  _pcs := 'SELECT * FROM ' + _aktdayb + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAR';

  with Recdbase do
    begin
      close;
      Databasename := _host+':c:\receptor\database\daybook.fdb';
      Connected := true;
    end;

  with recQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  _cc := 0;
  _napMezo := 'N'+inttostr(_kertnap);
  while not Recquery.Eof do
    begin
      _aktPenztar := RecQuery.fieldByNAme('PENZTAR').asInteger;
      if ezErtektar(_aktpenztar) then
        begin
          recquery.next;
          continue;
        end;

      _betu := Recquery.fieldbyname(_NapMezo). asstring;
      if _betu<>'B' then
        begin
          Recquery.Next;
          Continue;
        end;

      inc(_cc);
      _penztarsor[_cc] := _aktpenztar;
      Recquery.next;
    end;

  Recquery.close;
  Recdbase.close;

  // --------------------------------------------

  with Arcdbase do
    begin
      CLose;
      Databasename := _host+':c:\cartcash\database\daybook.fdb';
      COnnected :=true;
    end;

  _aktdayb := 'DAYB' + _farok;
  _pcs := 'SELECT * FROM ' + _aktdayb + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAR';

  with arcQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  while not ArcQuery.Eof do
    begin
      _aktPenztar := ArcQuery.fieldByNAme('PENZTAR').asInteger;

      _betu := Arcquery.fieldbyname(_NapMezo). asstring;
      if _betu<>'B' then
        begin
          Arcquery.Next;
          Continue;
        end;

      inc(_cc);
      _penztarsor[_cc] := _aktpenztar;
      Arcquery.next;
    end;

  Arcquery.close;
  Arcdbase.close;

  _penztardb := _cc;
end;

// =============================================================================
                   procedure TForm2.TulajKiolvasas;
// =============================================================================
begin
  vTabla.close;
  vTabla.TableName := _tulajTablanev;
  if not vtabla.Exists then exit;

  _pcs := 'SELECT * FROM ' + _tulajtablanev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _kertdatums + chr(39) + _sorveg;
  _pcs := _pcs + 'ORDER BY BIZONYLATSZAM';

  with vQuery do
    begin
      close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      vQuery.close;
      exit;
    end;

   while not Vquery.eof do
     begin
       with vquery do
         begin
           _bizonylatszam := trim(FieldByNAme('bizonylatszam').AsString);
           _joginev       := trim(FieldByNAme('JOGISZEMELYNEV').AsString);
     //      _telephely     := trim(FieldByNAme('TELEPHELYCIM').asString);
           _tulajnev      := trim(FieldByNAme('UGYFELNEV').AsString);
           _tulElonev     := trim(FieldByNAme('ELOZONEV').AsString);
           _tulcim        := trim(FieldByNAme('LAKCIM').AsString);
           _tulszulhely   := trim(FieldByNAme('SZULETESIHELY').AsString);
           _tulSzulido    := trim(FieldByNAme('SZULETESIIDO').AsString);
           _tulallamp     := trim(FieldByNAme('ALLAMPOLGAR').AsString);
           _tultarthely   := trim(FieldByNAme('TARTOZKODASIHELY').AsString);
           _tuljelleg     := trim(FieldByNAme('ERDJELLEG').AsString);
           _tulmertek     := trim(FieldByNAme('ERDMERTEK').AsString);
           _tulkozszerep  := FieldByNAme('KOZSZEREPLO').asInteger;
         end;
       _pcs := 'SELECT * FROM ' + _bfejtablanev + _sorveg;
       _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39)+_bizonylatszam+chr(39);

       _jAdoszam := '';
       bfejdbase.connected := true;
       with Bfejquery do
         begin
           Close;
           sql.clear;
           sql.add(_pcs);
           Open;
           _recno := recno;
         end;

       if _recno>0 then
          BEGIN
            _jAdoszam := BfejQuery.FieldByNAme('ADOSZAM').asString;
            _plombaszam := trim(BFejQuery.FieldByNAme('PLOMBASZAM').asString);
          END;
       BfejQuery.close;
       Bfejdbase.close;

       _wpl := length(_plombaszam);
       _jnums := midstr(_plombaszam,5,_wpl-4);

       _pcs := 'SELECT * FROM JOGI WHERE SORSZAM='+_jNums;
       with Jogidbase do
         begin
           Close;
           databasename := _ugyfelfdb;
           Connected := true;
         end;

       with JogiQuery do
         begin
           Close;
           sql.clear;
           sql.add(_Pcs);
           Open;
           _telephely := trim(FieldByNAme('TELEPHELYCIM').AsString);
           Close;
         end;

       Jogidbase.close;

       GyujtobeIras;
       vquery.next;
     end;
    vquery.close;
end;



// =============================================================================
                      procedure Tform2.Gyujtobeiras;
// =============================================================================

begin
  _pcs := 'INSERT INTO GYUJTO (PENZTAR,BIZONYLATSZAM,JOGINEV,TELEPHELYCIM,ADOSZAM,';
  _pcs := _pcs + 'TULAJNEV,ELOZONEV,LAKCIM,SZULETESIHELY,SZULETESIIDO,';
  _pcs := _pcs + 'ALLAMPOLGAR,TARTOZKODASIHELY,ERDJELLEG,ERDMERTEK,KULFOLDI,';
  _pcs := _pcs + 'KOZSZEREPLO)' + _sorveg;

  _pcs := _pcs + 'VALUES ('+ inttostr(_aktPt) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _JOGInev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _Telephely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _jadoszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tulajnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tulelonev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tulcim + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tulszulhely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tulszulido + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tulallamp + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tultarthely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tuljelleg + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tulmertek + chr(39) + ',';
  _pcs := _pcs + inttostr(_Kulfoldi) + ',';
  _pcs := _pcs + inttostr(_tulkozszerep) + ')';

  GyujtoParancs(_pcs);
end;


// =============================================================================
              procedure TForm2.GyujtoParancs(_ukaz: string);
// =============================================================================

begin
  Gyujtodbase.connected := True;
  if gyujtoTranz.intransaction then GyujtoTranz.commit;
  Gyujtotranz.startTransaction;

  with GyujtoQuery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  GyujtoTranz.commit;
  Gyujtodbase.close;
end;
end.

