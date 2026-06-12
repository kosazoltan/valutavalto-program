unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Grids, Calendar, IBTable, IBDatabase, DB,
  IBCustomDataSet, IBQuery, Strutils, ExtCtrls,excel97,comobj,activex,
  DateUtils;

type
  TForm1 = class(TForm)
    DAYBQUERY: TIBQuery;
    DAYBDBASE: TIBDatabase;
    DAYBTRANZ: TIBTransaction;
    BFTABLA: TIBTable;
    BFTRANZ: TIBTransaction;
    BFDBASE: TIBDatabase;
    BFQUERY: TIBQuery;
    KEZDQUERY: TIBQuery;
    KEZDDBASE: TIBDatabase;
    KEZDTRANZ: TIBTransaction;
    KEZDTABLA: TIBTable;
    Label1: TLabel;
    MENUPANEL: TPanel;
    Shape2: TShape;
    EGYNAPBEGOMB: TBitBtn;
    BitBtn7: TBitBtn;
    BitBtn8: TBitBtn;
    naptarpanel: TPanel;
    NAPTAR: TCalendar;
    Label2: TLabel;
    EVPANEL: TPanel;
    HONAPPANEL: TPanel;
    ELOHOGOMB: TBitBtn;
    KOVHOGOMB: TBitBtn;
    Shape1: TShape;
    DATUMOKEGOMB: TBitBtn;
    DATUMMEGSEMGOMB: TBitBtn;
    UZENOPANEL: TPanel;
    Label3: TLabel;
    MEMOPANEL: TPanel;
    Memo1: TMemo;
    visszagomb: TBitBtn;
    LOGOPANEL: TPanel;
    Shape3: TShape;
    Label4: TLabel;
    HONAPKEROPANEL: TPanel;
    EVCOMBO: TComboBox;
    HOCOMBO: TComboBox;
    hookegomb: TBitBtn;
    homegsemgomb: TBitBtn;
    Panel1: TPanel;
    Shape4: TShape;
    DAYBTABLA: TIBTable;


    procedure FormActivate(Sender: TObject);
    procedure Makekezdtabla(_tnev: string);
    procedure Excelkeszites;

    function Nulele(_n: integer): string;
    procedure BitBtn8Click(Sender: TObject);
    procedure EGYNAPBEGOMBClick(Sender: TObject);
    procedure DATUMMEGSEMGOMBClick(Sender: TObject);
    procedure ELOHOGOMBClick(Sender: TObject);
    procedure KOVHOGOMBClick(Sender: TObject);
    procedure DATUMOKEGOMBClick(Sender: TObject);
    procedure BitBtn7Click(Sender: TObject);
    procedure homegsemgombClick(Sender: TObject);
    procedure hookegombClick(Sender: TObject);
    procedure EVCOMBOChange(Sender: TObject);
    procedure visszagombClick(Sender: TObject);

    function KezdtablaNyitas(_kftbetu: string): boolean;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _top,_left,_height,_width: word;
  _NAP,_HONAP,_EV,_kertev,_kerthonap,_kertnap: word;
  _bankkod: array[1..150] of integer;
  _egyseg: array[1..150] of string;
  _datum: TDateTime;
  _datums,_farok,_kezdTablanev,_bfejnev,_daybnev,_pcs,_tip: string;
  _aktmezo,_fdbpath,_kmezo,_bks,_excelpath,_mezo,_formula: string;
  _sorveg: string = chr(13)+chr(10);
  _pt,_recno,_skezdij,_kezdij,_bkod,_qq,_bk,_code,_ptdarab: integer;
  _aktsor,_adat,_yyy: integer;
  _ptardb: array[1..3] of integer;
  _sptdarab: integer;
  _rangestr,_tablanev: string;
  _oxl,_owb,_RANGE: OleVariant;
  _cb: array[1..3] of string = ('B','E','P');
  _honev: array[1..12] of string = ('január','február','március','április',
                   'május','június','július','augusztus','szeptember',
                   'október','november','december');

implementation

{$R *.dfm}

// =============================================================================
                  procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

VAR _KFT: STRING;

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;
  _top := trunc((_height-530)/2);
  _left := trunc((_width-700)/2);

  Top    := _top;
  Left   := _left;
  Height := 530;
  Width  := 700;

  _ev := yearof(date);
  _honap := monthof(date);
  _nap := dayof(date);

  HonapkeroPanel.Visible := false;
  UzenoPanel.Visible := False;
  NaptarPanel.Visible := false;

  with Logopanel do
    begin
      Top := 420;
      Left := 530;
      Visible := True;
    end;

  Bfdbase.close;
  Bfdbase.DatabaseName := 'c:\receptor\database\receptor.fdb';

  _pcs := 'SELECT * FROM IRODAK';
  BfDbase.Connected := TRUE;
  with Bfquery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  while not bfquery.Eof do
    begin
      _qq := bfquery.fieldbyname('UZLET').asInteger;
      _bks := trim(bfquery.FieldByName('BANKKOD').asstring);
      _kft := bfquery.FieldByName('CEGBETU').asString;
      val(_bks,_bk,_code);
      _bankkod[_qq] := _bk;
      _egyseg[_qq]  := _kft;
      Bfquery.next;
    end;
  Bfquery.close;
  Bfdbase.close;

  with MenuPanel do
   begin
     Top := 150;
     Left := 120;
     Visible := True;
   end;
end;

// =============================================================================
                procedure TForm1.DATUMOKEGOMBClick(Sender: TObject);
// =============================================================================

var _cbetu,_tipfelt: string;

begin
   NaptarPanel.Visible := False;
   memo1.clear;
   Memo1.Lines.Clear;
   with Uzenopanel do
     begin
       Top := 80;
       Left := 120;
       Visible := True;
     end;

  _kertev    := Naptar.Year;
  _kerthonap := Naptar.Month;
  _kertnap   := Naptar.Day;
  _datum     := naptar.CalendarDate;
  _datums    := leftstr(datetostr(_datum),10);
  if _datums<'2012.12.01' then
    begin
      Memo1.lines.add('Túl korai adatokat kér !');
      sleep(2000);
      exit;
    end;


  Memo1.Lines.add(_DATUMS+' napi beküldött kezelési költségek');

  _farok   := inttostr(_kertev-2000)+nulele(_kerthonap);
  _kezdtablanev := 'KEZD'+_farok;
  _bfejnev := 'BF' + _farok;
  _kmezo := 'KD' + inttostr(_kertnap);

  Kezddbase.Connected := True;
  KezdTabla.close;
  Kezdtabla.TableName := _kezdtablanev;
  if not Kezdtabla.exists then MakeKezdtabla(_kezdtablanev);

  _pcs := 'UPDATE '+ _kezdtablanev + ' SET '+ _kmezo + '=0';
  if kezdTranz.InTransaction then kezdTranz.commit;
  Kezdtranz.StartTransaction;
  with KezdQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      ExecSql;
    end;
  KezdTranz.commit;
  KezdDbase.close;

  // -------------------------------------

  _DaybNev := 'DAYB'+_farok;
  DaybTabla.close;
  DaybTabla.TableName := _daybnev;
  Daybdbase.Connected := true;
  if not daybtabla.Exists then
    begin
      Daybtabla.close;
      Daybdbase.close;
      Memo1.Lines.add('Erről a napról még nincsen adat');
      Activecontrol := Visszagomb;
      exit;
    end;


  _PCS := 'SELECT * FROM ' + _daybnev;

  Daybdbase.Connected := true;
  with DaybQuery do
    begin
      close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  _aktmezo := 'N' + inttostr(_kertnap);
  while not Daybquery.eof do
    begin
      _pt := DaybQuery.FieldByNAme('PENZTAR').asInteger;
      _tip:= DaybQuery.fieldbyname(_aktmezo).asString;

      Memo1.Lines.add(inttostr(_pt)+'. számú pénztár adatai ...');

      if _tip='B' then
        begin
          _fdbpath := 'c:\receptor\database\v'+inttostr(_pt)+'.fdb';

          bfdbase.close;
          bftabla.close;
          bfdbase.DatabaseName := _fdbPath;
          Bfdbase.Connected := true;
          Bftabla.TableName := _bfejnev;
          if not bftabla.Exists then
            begin
              Memo1.Lines.add('Hiányzik '+inttostr(_pt)+'. pénztár '+ _bfejnev+' táblája');
              Sleep(900);
              DaybQuery.next;
              Continue;
            end;

          _tipfelt := '(TIPUS='+chr(39)+'V'+chr(39)+')';
          _tipfelt := _tipfelt + ' OR (TIPUS='+chr(39)+'E'+chr(39)+')';

          _pcs := 'SELECT * FROM ' + _bfejnev + _sorveg;
          _pcs := _pcs + 'WHERE (DATUM='+chr(39)+_datums+chr(39)+')';
          _pcs := _pcs + ' AND (STORNO=1) AND (' + _tipfelt +')';

          with BfQuery do
            begin
              Close;
              sql.clear;
              Sql.Add(_pcs);
              Open;
              First;
              _recno := recno;
            end;

          _skezdij := 0;
          if _recno>0 then
            begin
              while not BfQuery.Eof do
                begin
                  _kezdij := Bfquery.FieldByName('KEZELESIDIJ').asInteger;
                  _skezdij := _skezdij + abs(_kezdij);
                  Bfquery.Next;
                end;
             end;

          Bfquery.close;
          Bfdbase.close;

          //-----------------------------------------

          _pcs := 'SELECT * FROM ' + _kezdTablaNev + _sorveg;
          _pcs := _pcs + 'WHERE PENZTAR=' + inttostr(_pt);

          KezdDbase.Connected := true;
          with KezdQuery do
            begin
              Close;
              sql.Clear;
              Sql.Add(_pcs);
              Open;
              First;
              _recno := recno;
              Close;
            end;
          KezdDbase.close;

          _bKod := _bankkod[_pt];
          _CBETU := _egyseg[_pt];

          if _recno=0 then
            begin
              _pcs := 'INSERT INTO ' + _kezdTablaNev + ' (PENZTAR,'+_kmezo+',BANKKOD,CEGBETU)'+_sorveg;
              _pcs := _pcs + 'VALUES ('+inttostr(_pt)+','+ inttostr(_skezdij)+ ',';
              _pcs := _pcs + inttostr(_bkod)+',';
              _pcs := _pcs + chr(39) + _cbetu +chr(39) + ')';

            end else
            begin
              _pcs := 'UPDATE '+_kezdTablanev + ' SET '+_KmEZO+'='+inttostr(_skezdij)+_sorveg;
              _pcs := _pcs + 'WHERE PENZTAR='+INTTOSTR(_PT);
            end;

          KezdDbase.Connected := true;
          if kezdtranz.InTransaction then kezdtranz.commit;
          KezdTranz.StartTransaction;

          with KezdQuery do
            begin
              Close;
              sql.clear;
              Sql.Add(_pcs);
              Execsql;
            end;
          Kezdtranz.commit;
          KezdDbase.close;
        end;
      daybquery.Next;
    end;
  daybquery.close;
  daybdbase.close;
  Memo1.Lines.add('Az adatok beolvasása befejezödött');
  sleep(500);

  Uzenopanel.Visible := false;
  with MenuPanel do
    begin
      Top := 150;
      Left := 120;
      Visible := True;
    end;


//  Excelkeszites;

end;



// =============================================================================
                  function TForm1.Nulele(_n: integer): string;
// =============================================================================


begin
  result := inttostr(_n);
  if _n<10 then result := '0' + result;
end;

// =============================================================================
                  procedure  Tform1.Makekezdtabla(_tnev: string);
// =============================================================================


begin
  Memo1.Lines.add('A ' + _tnev + ' nevü interbase táblát készitem ...');
  _pcs := 'CREATE TABLE ' + _tnev +' (' +_sorveg;
  _pcs := _pcs + 'PENZTAR SMALLINT,' +_sorveg;
  _pcs := _pcs + 'KD1 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD2 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD3 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD4 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD5 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD6 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD7 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD8 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD9 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD10 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD11 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD12 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD13 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD14 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD15 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD16 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD17 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD18 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD19 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD20 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD21 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD22 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD23 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD24 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD25 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD26 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD27 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD28 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD29 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD30 INTEGER,' +_sorveg;
  _pcs := _pcs + 'KD31 INTEGER,' +_sorveg;
  _pcs := _pcs + 'BANKKOD INTEGER,'+ _sorveg;
  _pcs := _pcs + 'CEGBETU CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250)';

  KezdDbase.connected := true;
  if kezdTranz.InTransaction then kezdtranz.Commit;
  kezdtranz.StartTransaction;
  with KezdQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_pcs);
      Execsql;
    end;
  KezdTranz.commit;
  Kezddbase.close;
end;





procedure TForm1.BitBtn8Click(Sender: TObject);
begin
  Application.terminate;
end;

procedure TForm1.EGYNAPBEGOMBClick(Sender: TObject);
begin
  Naptar.Year := _ev;
  Naptar.Month := _honap;
  _kertev := _ev;
  _kerthonap := _honap;
   evpanel.Caption := inttostr(_kertev);
  Honappanel.Caption := _honev[_kerthonap];

  Menupanel.Visible := false;
  with Naptarpanel do
    begin
      Top := 70;
      Left := 110;
      Visible := True;
    end;
end;

procedure TForm1.DATUMMEGSEMGOMBClick(Sender: TObject);
begin
  evpanel.Caption := inttostr(_ev);
  Honappanel.Caption := _honev[_honap];

  Naptarpanel.Visible := false;
   with MenuPanel do
   begin
     Top := 150;
     Left := 120;
     Visible := True;
   end;
end;

procedure TForm1.ELOHOGOMBClick(Sender: TObject);
begin
  Naptar.PrevMonth;
  _kertev := Naptar.Year;
  _kerthonap := naptar.month;
  evpanel.Caption := inttostr(_kertev);
  Honappanel.Caption := _honev[_kerthonap];
end;

procedure TForm1.KOVHOGOMBClick(Sender: TObject);
begin
   Naptar.NextMonth;
  _kertev := Naptar.Year;
  _kerthonap := naptar.month;
  evpanel.Caption := inttostr(_kertev);
  Honappanel.Caption := _honev[_kerthonap];

end;


procedure TForm1.BitBtn7Click(Sender: TObject);
var i: integer;
begin
  MenuPanel.Visible := false;

  evcombo.clear;
  evcombo.Items.clear;

  Hocombo.Clear;
  Hocombo.Items.clear;

  for i := -2 to 0 do Evcombo.Items.Add(inttostr(i+_ev));
  for i := 1 to 12 do Hocombo.Items.add(_honev[i]);

  evcombo.ItemIndex := 2;
  Hocombo.ItemIndex := _honap-1;

  with HonapkeroPanel do
    begin
      Top := 170;
      Left := 160;
      Visible := true;
    end;
  ActiveControl := Hookegomb;
end;

procedure TForm1.homegsemgombClick(Sender: TObject);
begin
  HonapKeroPanel.Visible := False;
   with MenuPanel do
   begin
     Top := 150;
     Left := 120;
     Visible := True;
   end;
end;

procedure TForm1.hookegombClick(Sender: TObject);
begin
  HonapKeroPanel.Visible := false;
   memo1.clear;
   Memo1.Lines.Clear;
   with Uzenopanel do
     begin
       Top := 80;
       Left := 120;
       Visible := True;
     end;

   _Kertev := _ev-2+evcombo.itemindex;
   _kerthonap := 1+hocombo.itemindex;
   _farok := inttostr(_kertev-2000)+nulele(_kerthonap);
   ExcelKeszites;
end;

procedure TForm1.ExcelKeszites;

var _nn,i: integer;
    _cegbetu: string;


begin
  _tablanev := 'KEZD' + _FAROK;
  Memo1.Lines.add(_tablanev + '.xls exceltáblát állítom össze');

  kezdTabla.close;
  kezdTabla.TableName := _tablanev;
  kezdDbase.Connected := true;
  if not Kezdtabla.Exists then
    begin
       KezdQuery.close;
      Kezddbase.close;
      Memo1.Lines.add('Nincsen adat a kért hónapról');
      SLEEP(2500);
      Uzenopanel.Visible := false;
      with MenuPanel do
        begin
          Top := 150;
          Left := 120;
          Visible := True;
        end;
      EXIT;
    end;

  Kezdquery.close;
  KezdDbase.close;

  _pcs := 'SELECT * FROM KEZD'+ _farok;
  with KezdQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  for i := 1 to 3 do _ptardb[i] := 0;
  _sptdarab := 0;

  while not kezdquery.Eof do
    begin
      _cegbetu := Kezdquery.fieldByname('CEGBETU').asString;
      if _cegbetu='B' then _ptardb[1] := _ptardb[1]+ 1;
      if _cegbetu='E' then _ptardb[2] := _ptardb[2]+ 1;
      if _cegbetu='P' then _ptardb[3] := _ptardb[3]+ 1;
      inc(_sptdarab);
      KezdQuery.next;
    end;

  KezdQuery.close;
  Kezddbase.close;

  if _sptdarab=0 then
    begin
      Memo1.Lines.add('Nincs adat a kért hónapról');
      SLEEP(2500);
      Uzenopanel.Visible := false;
      with MenuPanel do
        begin
          Top := 150;
          Left := 120;
          Visible := True;
        end;
      exit;
    end;

  _excelPath := 'C:\receptor\mail\posta\KEZD'+_farok+'.xls';
  if fileExists(_excelPath) then Deletefile(_excelpath);

  _oxl := CREATEOLEOBJECT('EXCEL.APPLICATION');
  _owb := _oxl.workbooks.Add[1];
  _oxl.workbooks[1].sheets.add(,,3);
  _oxl.workbooks[1].worksheets[1].name := 'EBC';
  _oxl.workbooks[1].worksheets[2].name := 'EEC';
  _oxl.workbooks[1].worksheets[3].name := 'EPC';

  _yyy := 1;
  while _yyy<=3 do
    begin
      _cegbetu := _cb[_yyy];
      if not KezdTablanyitas(_cegbetu) then
        begin
          inc(_yyy);
          Continue;
        end;
      _ptdarab := _ptardb[_yyy];

  _oxl.worksheets[_yyy].range['A1:AH1'].Mergecells := true;
  _oxl.worksheets[_yyy].range['A1:AH1'].FONT.NAME := 'Times New Roman';
  _oxl.worksheets[_yyy].range['A1:AH1'].font.size := 22;
  _oxl.worksheets[_yyy].range['A1:AH1'].font.italic := True;
  _oxl.worksheets[_yyy].range['A1:AH1'].HorizontalAlignment := -4108;

  _oxl.worksheets[_yyy].cells[1,1] := inttostr(_ev)+' '+_honev[_honap]+'i beérkezett kezelési költségek';

  _rangestr := 'A3:AH3';
  _oxl.worksheets[_yyy].range[_rangestr].columnwidth := 16;
  _oxl.worksheets[_yyy].range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_yyy].range[_rangestr].font.name := 'ARIAL';
  _oxl.worksheets[_yyy].range[_rangestr].FONT.BOLD := true;
  _oxl.worksheets[_yyy].range[_rangestr].font.size := 11;


  _rangestr := 'A4:AH'+inttostr(_ptdarab+3);
  _oxl.worksheets[_yyy].range[_rangestr].font.name := 'ARIAL';
  _oxl.worksheets[_yyy].range[_rangestr].font.size := 12;
  _oxl.worksheets[_yyy].range[_rangestr].Font.Italic := True;
  _oxl.worksheets[_yyy].range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_yyy].range[_rangestr].Numberformat := '### ### ###';

  _oxl.worksheets[_yyy].cells[3,1] := 'BANK KÓD';
  _oxl.worksheets[_yyy].cells[3,2] := 'PÉNZTÁR SZÁM';

  _NN := 1;
  while _nn<=31 do
    begin
      _oxl.worksheets[_yyy].cells[3,2+_nn] := inttostr(_nn);
      inc(_nn);
    end;
  _oxl.worksheets[_yyy].cells[3,34] := 'ÖSSZESEN';

  // --------------------------------------------------------------------

  _aktsor := 4;
  while not kezdquery.Eof do
    begin
      _bk := KezdQuery.fieldbyName('BANKKOD').asInteger;
      _pt := Kezdquery.FieldByName('PENZTAR').asInteger;

      Memo1.lines.add(inttostr(_pt)+'. pénztár adatait irom be');

      _oxl.worksheets[_yyy].cells[_aktsor,1] := inttostr(_bk);
      _oxl.worksheets[_yyy].cells[_aktsor,2] := inttostr(_pt);
      for i := 1 to 31 do
        begin
          _mezo := 'KD'+inttostr(i);
          _adat := Kezdquery.FieldByName(_mezo).asInteger;
           _oxl.worksheets[_yyy].cells[_aktsor,i+2] := _adat;
        end;
      inc(_aktsor);
      KezdQuery.Next;
    end;
  Kezdquery.close;
  Kezddbase.close;

  // --------------------------------------------------------------------------

  _formula := '=SUM(C4:AG4)';
  _oxl.worksheets[_yyy].range['AH4:AH'+INTTOSTR(4+_ptdarab)].formula := _formula;

  _formula := '=SUM(C4:C'+inttostr(_aktsor-1)+')';
  _rangestr := 'C'+inttostr(_aktsor)+':AH'+inttostr(_aktsor);
  _oxl.worksheets[_yyy].range[_rangestr].formula := _formula;
  _oxl.worksheets[_yyy].range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'A'+inttostr(_aktsor)+':B'+inttostr(_aktsor);

  _oxl.worksheets[_yyy].range[_rangestr].mergecells := True;
  _oxl.worksheets[_yyy].range[_rangestr].font.bold := True;
  _oxl.worksheets[_yyy].range[_rangestr].font.italic := True;
  _oxl.worksheets[_yyy].range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_yyy].cells[_aktsor,1] := 'ÖSSZESEN';


  _range := _oxl.range['C'+inttostr(_aktsor)+':AH'+inttostr(_aktsor)];
  _range.select;
  _range.font.bold := true;
  _range.font.name := 'ARIAL';
  _range.font.italic := true;
  _range.font.size := 12;
  _range.horizontalalignment := -4108;
  _range.numberformat := '### ### ###';

  _oxl.worksheets[_yyy].cells[_aktsor,34].font.size := 12;
  _oxl.worksheets[_yyy].cells[_aktsor,34].font.Bold := True;
  _oxl.worksheets[_yyy].cells[_aktsor,34].font.color := clRed;

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
  Memo1.Lines.add('Excel táblát kitettem a postába -> KEZD'+_farok+'.xls néven');
end;


procedure TForm1.EVCOMBOChange(Sender: TObject);
begin
  ActiveControl := HookeGomb;
end;

procedure TForm1.visszagombClick(Sender: TObject);
begin
  uZENOpANEL.Visible := fALSE;
   with MenuPanel do
        begin
          Top := 150;
          Left := 120;
          Visible := True;
        end;
end;

function TForm1.KezdtablaNyitas(_kftbetu: string): boolean;

begin
  result := False;
  _pcs := 'SELECT * FROM KEZD'+ _farok + _sorveg;
  _pcs := _pcs + 'WHERE CEGBETU='+chr(39)+_kftbetu+chr(39);

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
      Memo1.Lines.add('Nincs adat a kért hónapról');
      sleep(2500);
      Uzenopanel.Visible := false;
      with MenuPanel do
        begin
          Top := 150;
          Left := 120;
          Visible := True;
        end;
      EXIT;
    end;
  result := true;
end;


end.
