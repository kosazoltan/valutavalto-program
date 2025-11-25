unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, dateutils, IBDatabase, DB, strutils,
  Excel97,ComObj,IBQuery, ComCtrls, IBTable, Tlhelp32,oleserver,
  IBCustomDataSet;

type
  TForm1 = class(TForm)
    IDOSZAKPANEL: TPanel;
    Label1: TLabel;
    EVCOMBO: TComboBox;
    HOCOMBO: TComboBox;
    TOLCOMBO: TComboBox;
    IGCOMBO: TComboBox;
    IDSZOKEGOMB: TBitBtn;
    QUITGOMB: TBitBtn;
    Label2: TLabel;
    Label3: TLabel;
    Shape1: TShape;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    ARTQUERY: TIBQuery;
    ARTDBASE: TIBDatabase;
    ARTTRANZ: TIBTransaction;
    WQUERY: TIBQuery;
    WDBASE: TIBDatabase;
    WTRANZ: TIBTransaction;
    GYQUERY: TIBQuery;
    GYDBASE: TIBDatabase;
    GYTRANZ: TIBTransaction;
    LEVALOGATOPANEL: TPanel;
    VALFOCIMPANEL: TPanel;
    CSIK: TProgressBar;
    KORZETGOMB: TBitBtn;
    PENZTARGOMB: TBitBtn;
    KFTGOMB: TBitBtn;
    MASIDSZGOMB: TBitBtn;
    KILEPESGOMB: TBitBtn;
    Label4: TLabel;
    Shape2: TShape;
    GOMBTAKARO: TPanel;
    PENZTARVALASZTOPANEL: TPanel;
    Label5: TLabel;
    PENZTARBOX: TListBox;
    KORZETVALASZTOPANEL: TPanel;
    Label6: TLabel;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    RadioButton3: TRadioButton;
    RadioButton4: TRadioButton;
    RadioButton5: TRadioButton;
    RadioButton6: TRadioButton;
    RadioButton7: TRadioButton;
    RadioButton8: TRadioButton;
    RadioButton9: TRadioButton;
    KORZETOKEGOMB: TBitBtn;
    KORZETVISSZAGOMB: TBitBtn;
    PENZTAROKEGOMB: TBitBtn;
    PENZTARVISSZAGOMB: TBitBtn;
    KFTVALASZTOPANEL: TPanel;
    RadioButton10: TRadioButton;
    RadioButton11: TRadioButton;
    RadioButton12: TRadioButton;
    RadioButton13: TRadioButton;
    Label7: TLabel;
    KFTOKEGOMB: TBitBtn;
    KFTVISSZAGOMB: TBitBtn;
    Shape3: TShape;
    wTabla: TIBTable;
    Memo1: TMemo;
    Memo2: TMemo;
    KFTPANEL: TPanel;
    EBCGOMB: TPanel;
    EECGOMB: TPanel;
    EPCGPMB: TPanel;
    ECPZGOMB: TPanel;
    BACKKFTGOMB: TPanel;
    Label8: TLabel;
    KORZETPANEL: TPanel;
    K10GOMB: TPanel;
    K20GOMB: TPanel;
    K40GOMB: TPanel;
    K50GOMB: TPanel;
    K63GOMB: TPanel;
    K75GOMB: TPanel;
    K120GOMB: TPanel;
    K145GOMB: TPanel;
    KEXPGOMB: TPanel;
    BACKKORZETGOMB: TPanel;
    Label9: TLabel;
    PENZTARPANEL: TPanel;
    Label10: TLabel;
    CHANGEBOX: TListBox;
    EXPBOX: TListBox;
    MAKEEXCELPANEL: TPanel;
    PENZTARMENUPANEL: TPanel;
    backptvalgomb: TPanel;
    EXCGOMB: TPanel;
    EXPGOMB: TPanel;
    EXCELCSIK: TProgressBar;
    EXCELCIMPANEL: TPanel;
    Shape4: TShape;
    PTVALMEGSEMGOMB: TBitBtn;
    Shape5: TShape;
    Shape6: TShape;
    Shape7: TShape;
    KORZETTAKARO: TPanel;
    PENZTARTAKARO: TPanel;
    KFTTAKARO: TPanel;

    procedure QUITGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure UjidoszakBeallitas;

    function Nulele(_b: byte): string;
    function Scankorzet(_knum: byte): byte;
    function GetPenztarnev(_pnum: byte): string;
    procedure ExcGombClick(Sender: TObject);

    procedure EVCOMBOChange(Sender: TObject);
    procedure TOLCOMBOChange(Sender: TObject);
    procedure IGCOMBOChange(Sender: TObject);
    procedure Getirodak;
    procedure IDSZOKEGOMBClick(Sender: TObject);
    procedure LevalogatoRutin;
    procedure MakeExcel;
    procedure ExcelKill;
    procedure PtValasztott;
    procedure ZPtValasztott;
    procedure KftValasztott(Sender: TObject);

    procedure PENZTARGOMBClick(Sender: TObject);
    procedure KorzetetValasztott;

    procedure CHANGEBOXDblClick(Sender: TObject);
    procedure CHANGEBOXKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
   
    procedure EXPBOXDblClick(Sender: TObject);
    procedure EXPBOXKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure EXPGOMBClick(Sender: TObject);
    procedure KFTGOMBClick(Sender: TObject);
    procedure BACKKFTGOMBClick(Sender: TObject);
    procedure backptvalgombClick(Sender: TObject);
    procedure KORZETGOMBClick(Sender: TObject);
    procedure BACKKORZETGOMBClick(Sender: TObject);
    procedure KilepesGombClick(Sender: TObject);
    procedure MasIDSZGOMBClick(Sender: TObject);
    procedure KorzetClick(Sender: TObject);
  
   
   

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _cbetu: array[1..4] of string = ('B','E','P','Z');

  _kftnevek: array[1..4] of string = ('BEST CHANGE','EAST CHANGE',
        'PANNON CHANGE','EXPRESSZ ZÁLOG');

  _korzetnev: array[1..9] of string = ('SZEKSZÁRDI','SZEGEDI','KECSKEMÉTI',
          'DABRECENI','NYÍREGYHÁZI','BÉKÉSCSBAI','PÉCSI','KAPOSVÁRI',
          'ZÁLOGHÁZI');

  _korzetszam: array[1..9] of byte = (10,20,40,50,63,75,120,145,180);



  _honev: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS1','ÁPRILIS',
          'MÁJUS','JUNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
          'NOVEMBER','DECEMBER');

  _ptarszam,_ptaretar: array[0..149] of byte;
  _ptarnev,_ptarcbetu: array[0..149] of string;
  _artszam: array[0..25] of byte;
  _artnev : array[0..25] of string;

  _sorveg: string = chr(13) + chr(10);

  _penztar,_korzet,_aktptnum,_aktkznum,_kss,_kftss: byte;
  _aktev,_aktho,_akttol,_aktig,_prisor,_lastsor,_baseleft: word;
  _kertev,_kertho,_kerttol,_kertig,_csiklen: word;
  _aktdatums,_uznev,_cegbetu,_toldatums,_igDatums,_farok,_valutanem: string;
  _pcs,_gypcs,_wNev,_aktptarnev,_aktcbetu,_aktfdb,_datum,_sorszam: string;
  _mtcnszam,_ttipus,_prosnev,_focim,_ceg,_bizonylat,_mtcn,_aktptnev: string;
  _knev,_pnev,_feltetel,_filter,_idszfilter,_aktkznev,_aktkftnev: string;
  _aktcegbetu: string;

  _code,_cs,_recno,_bankjegy,_ptss: integer;

  _lastday,_y,_uzlet,_uzdb,_etar,_exptardarab,_artptardarab,_aktptar: byte;
  _aktkorzet: byte;

  proc : PROCESSENTRY32;
  _handle : HWND;
  _Looper : BOOL;

  _host : string = '185.43.207.99';
  _exceltabla,_sajatexcel,_range: variant;

implementation

{$R *.dfm}


procedure TForm1.QUITGOMBClick(Sender: TObject);
begin
  ExcelKill;
  Application.Terminate;
end;



procedure TForm1.FormActivate(Sender: TObject);
begin
  _baseLeft := Form1.left;
  GetIrodak;
  evcombo.Items.Clear;
  hocombo.Items.Clear;
  tolcombo.Items.Clear;
  igcombo.Items.clear;

  _aktev := yearof(date);
  _aktho := monthof(date);
  _akttol := dayof(date);
  _aktig := _akttol;
  _aktdatums := inttostr(_aktev)+'.'+nulele(_aktho)+'.'+nulele(_akttol);

  evcombo.Items.Add(inttostr(_aktev-1));
  evcombo.Items.Add(inttostr(_aktev));
  evcombo.ItemIndex := 1;

  _y := 1;
  while _y<=12 do
    begin
      Hocombo.items.add(_honev[_y]);
      inc(_y);
    end;
  hocombo.ItemIndex := _aktho-1;

  _lastday := daysinamonth(_aktev,_aktho);

  _y := 1;
  while _y<=_lastday do
    begin
      tolcombo.Items.add(inttostr(_y));
      if _y>=_akttol then igcombo.Items.add(inttostr(_y));
      inc(_y);
    end;
  tolcombo.ItemIndex :=_akttol-1;
  igcombo.ItemIndex := 0;
  UjidoszakBeallitas;
end;


procedure TForm1.UjIdoszakBeallitas;
begin

  with idoszakPanel do
    begin
      top  := 0;
      left := 0;
      Visible := true;
      repaint;
    end;

  Activecontrol := IdszOkeGomb;

end;


function TForm1.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;




procedure TForm1.EVCOMBOChange(Sender: TObject);
begin
  _kertev := (_aktev-1) + evcombo.itemindex;
  _kertho := 1 + hocombo.itemindex;
  _lastday := daysinamonth(_kertev,_kertho);
  tolcombo.Items.clear;
  igcombo.Items.clear;
  _y := 1;
  while _y<=_lastday do
    begin
      tolcombo.Items.Add(inttostr(_y));
      igcombo.Items.add(inttostr(_y));
      inc(_y);
    end;
  tolcombo.ItemIndex := 0;
  igcombo.ItemIndex := _lastday-1;
  Activecontrol := idszOkegomb;
end;

procedure TForm1.TOLCOMBOChange(Sender: TObject);

var _n: integer;

begin
  _kerttol := 1+tolcombo.itemindex;
  igcombo.Items.Clear;
  _y := _kerttol;
  _n := -1;
  while _y<=_lastday do
    begin
      igcombo.Items.Add(inttostr(_y));
      inc(_n);
      inc(_y);
    end;
  igcombo.ItemIndex := _n;
  Activecontrol := idszOkeGomb;

end;

procedure TForm1.IGCOMBOChange(Sender: TObject);
begin
  Activecontrol := idszOkeGomb;
end;

procedure TForm1.GetIrodak;

begin
  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE WESTERNUNION=1';
  recdbase.Connected := true;
  with recquery do
    begin
      Close;
      sql.clear;
      sql.Add(_PCS);
      Open;
    end;

  _uzdb := 0;
  while not recquery.Eof do
    begin
      _uzlet := Recquery.FieldByNAme('UZLET').asInteger;
      _uznev := trim(recQuery.fieldByNAme('KESZLETNEV').asString);
      _cegbetu := Recquery.FieldByNAme('CEGBETU').asString;
      _etar := RecQuery.FieldByNAme('ERTEKTAR').asInteger;

      _ptarszam[_uzdb] := _uzlet;
      _ptarnev[_uzdb]  := _uznev;
      _ptarcbetu[_uzdb] := _cegbetu;
      _ptaretar[_uzdb] := _etar;
      inc(_uzdb);
      recquery.next;
    end;

  recquery.close;
  recdbase.close;

  _ExPtardarab := _uzdb;

  // ------------------------------------

  artdbase.Connected := true;
  with artquery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
    end;

  _uzdb := 0;
  while not artquery.Eof do
    begin
      _uzlet := artquery.FieldByNAme('UZLET').asInteger;
      _uznev := trim(artQuery.fieldByNAme('KESZLETNEV').asString);

      _artszam[_uzdb] := _uzlet;
      _artnev[_uzdb]  := _uznev;

      inc(_uzdb);
      artquery.next;
    end;

  _artPtardarab := _uzdb;
end;


procedure TForm1.IDSZOKEGOMBClick(Sender: TObject);

var _igs: string;

begin
  _kertev  := (_aktev-1)+(evcombo.ItemIndex);
  _kertho  := 1+(hocombo.ItemIndex);
  _kerttol := 1 + (tolcombo.ItemIndex);
  _y := igcombo.ItemIndex;
  _igs := Igcombo.Items[_y];
  val(_igs,_kertig,_code);
  _toldatums := inttostr(_kertev)+'.'+nulele(_kertho)+'.'+nulele(_kerttol);
  _igDatums := leftstr(_toldatums,8)+nulele(_kertig);
  if _toldatums>_aktdatums then
    begin
      Showmessage('A KÉRT DÁTUM A JÖVÕBEN LESZ');
      exit;
    end;

  IdoszakPanel.Visible := False;

  _idszFilter := '(DATUM>='+chr(39)+_toldatums+chr(39)+')';
  _idszfilter := _idszfilter + ' AND (DATUM<=' + chr(39) + _igdatums + chr(39) + ')';

  with LevalogatoPanel do
    begin
      top := 0;
      left := 0;
      Visible := true;
      repaint;
    end;

  Memo1.Lines.Clear;
  memo1.Clear;
  Memo1.Repaint;

  Memo2.Lines.Clear;
  memo2.clear;
  memo2.repaint;

  with GombTakaro do
    begin
      left := 28;
      top  := 160;
      visible := true;
      repaint;
    end;

  LevalogatoRutin;

  Csik.Visible := False;
  GombTakaro.visible := False;
end;

// =============================================================================
                    procedure TForm1.Levalogatorutin;
// =============================================================================

begin
 
  _Focim := 'A WESTERN UNION FORGALOM LEVÁLOGATÁSA '+_toldatums+' ÉS '+_igDatums+' KÖZÖTT';
  ValFocimPanel.Caption := _focim;
  ValfocimPanel.repaint;
  gydbase.connected := true;
  if gytranz.InTransaction then gytranz.commit;
  Gytranz.StartTransaction;
  _pcs := 'DELETE FROM WUGYUJTO';
  with GyQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      ExecSql;
    end;
  gYTRANZ.COMMIT;
  Gydbase.close;

  gydbase.connected := true;
  if gytranz.InTransaction then gytranz.commit;
  Gytranz.StartTransaction;
  _farok := inttostr(_kertev-2000)+nulele(_kertho);

  _wNev := 'WUNI' + _farok;

  _csiklen := _exPtarDarab + _artPtarDarab;
  Csik.max := _csiklen;
  _cs := 0;

 // --------------------------------------------------------

  _y := 0;
  while _y<_exPtarDarab do
    begin
      _aktptar := _ptarszam[_y];
      _aktptarnev := _ptarnev[_y];
      _aktkorzet := _ptarEtar[_y];
      _aktcbetu := _ptarcbetu[_y];

      inc(_cs);
      Csik.position := _cs;

      _aktfdb := _host + ':C:\RECEPTOR\DATABASE\V' + inttostr(_aktptar)+'.FDB';
      Memo1.Lines.Add(_aktPTARNEV);

      Wdbase.close;
      wdbase.databasename := _aktfdb;
      wdbase.connected := true;

      wtabla.tablename := _wNev;
      if not wTabla.exists then
        begin
          wQuery.close;
          wDbase.close;
          inc(_y);
          Continue;
        end;

      _pcs := 'SELECT * FROM ' + _wNev + _sorveg;
      _pcs := _pcs + 'WHERE (DATUM>=' + chr(39)+_toldatums + chr(39)+') AND (';
      _pcs := _pcs + 'DATUM<=' + chr(39)+_igDatums+chr(39)+') AND (STORNO=1)';

      with Wquery do
        begin
          Close;
          Sql.clear;
          Sql.add(_pcs);
          Open;
          _recno := recno;
        end;

      if _recno>0 then
        begin
          while not wquery.eof do
            begin
              with Wquery do
                begin
                  _datum := FieldByName('DATUM').asString;
                  _sorszam := FieldByName('SORSZAM').asstring;
                  _bankjegy := FieldByName('BANKJEGY').asInteger;
                  _valutanem := FieldByName('VALUTANEM').asString;
                  _mtcnszam := FieldByName('MTCNSZAM').asString;
                  _ttipus := FieldByNAme('TRANZAKCIOTIPUS').asString;
                  _PROSNEV := FieldByName('PENZTAROSNEV').asString;
                end;

              Memo2.Lines.Add(_datum+'-'+inttostr(_bankjegy)+' '+_valutanem);

              _gypcs := 'INSERT INTO WUGYUJTO (CEG,KORZET,PENZTAR,DATUM,SORSZAM,';
              _gypcs := _gypcs + 'BANKJEGY,VALUTANEM,MTCNSZAM,TRANZAKCIOTIPUS,';
              _gypcs := _gypcs + 'PENZTAROSNEV)'+_sorveg;
              _gypcs := _gypcs + 'VALUES (' + chr(39) + _aktcbetu + chr(39) + ',';
              _gypcs := _gypcs + inttostr(_aktkorzet) + ',';
              _gypcs := _gypcs + inttostr(_aktptar) + ',';
              _gypcs := _gypcs + chr(39) + _datum + chr(39) + ',';
              _gypcs := _gypcs + chr(39) + _sorszam + chr(39) + ',';
              _gypcs := _gypcs + inttostr(_bankjegy) + ',';
              _gypcs := _gypcs + chr(39) + _valutanem + chr(39) + ',';
              _gypcs := _gypcs + chr(39) + _mtcnszam + chr(39) + ',';
              _gypcs := _gypcs + chr(39) + _ttipus + chr(39) + ',';
              _gypcs := _gypcs + chr(39) + _prosnev + chr(39) + ')';
              with GyQuery do
                begin
                  Close;
                  sql.clear;
                  sql.add(_gypcs);
                  ExecSql;
                end;
              wQuery.next;
            end;
        end;
      wquery.close;
      wdbase.close;

      inc(_y);
    end;

  // ---------------------------------------------------------------------------

  _y := 0;
  while _y<_artPtarDarab do
    begin
      _aktptar := _artszam[_y];
      _aktptarnev := _artnev[_y];
      _aktkorzet := 180;
      _aktcbetu := 'Z';

      inc(_cs);
      Csik.position := _cs;

      _aktfdb := _host + ':C:\CARTCASH\DATABASE\V' + inttostr(_aktptar)+'.FDB';
      Memo1.Lines.Add(_akTptarnev);

      Wdbase.close;
      wdbase.databasename := _aktfdb;
      wdbase.connected := true;

      wtabla.tablename := _wNev;
      if not wTabla.exists then
        begin
          wQuery.close;
          wDbase.close;
          inc(_y);
          Continue;
        end;

      _pcs := 'SELECT * FROM ' + _wNev + _sorveg;
      _pcs := _pcs + 'WHERE (DATUM>=' + chr(39)+_toldatums + chr(39)+') AND (';
      _pcs := _pcs + 'DATUM<=' + chr(39)+_igDatums+chr(39)+') AND (STORNO=1)';

      with Wquery do
        begin
          Close;
          Sql.clear;
          Sql.add(_pcs);
          Open;
          _recno := recno;
        end;

      if _recno>0 then
        begin
          while not wquery.eof do
            begin
              with Wquery do
                begin
                  _datum := FieldByName('DATUM').asString;
                  _sorszam := FieldByName('SORSZAM').asstring;
                  _bankjegy := FieldByName('BANKJEGY').asInteger;
                  _valutanem := FieldByName('VALUTANEM').asString;
                  _mtcnszam := FieldByName('MTCNSZAM').asString;
                  _ttipus := FieldByNAme('TRANZAKCIOTIPUS').asString;
                end;

              Memo2.Lines.Add(_datum+'-'+inttostr(_bankjegy)+' '+_valutanem);

              _gypcs := 'INSERT INTO WUGYUJTO (CEG,KORZET,PENZTAR,DATUM,SORSZAM,';
              _gypcs := _gypcs + 'BANKJEGY,VALUTANEM,MTCNSZAM,TRANZAKCIOTIPUS)'+_sorveg;
              _gypcs := _gypcs + 'VALUES (' + chr(39) + _aktcbetu + chr(39) + ',';
              _gypcs := _gypcs + inttostr(_aktkorzet) + ',';
              _gypcs := _gypcs + inttostr(_aktptar) + ',';
              _gypcs := _gypcs + chr(39) + _datum + chr(39) + ',';
              _gypcs := _gypcs + chr(39) + _sorszam + chr(39) + ',';
              _gypcs := _gypcs + inttostr(_bankjegy) + ',';
              _gypcs := _gypcs + chr(39) + _valutanem + chr(39) + ',';
              _gypcs := _gypcs + chr(39) + _mtcnszam + chr(39) + ',';
              _gypcs := _gypcs + chr(39) + _ttipus + chr(39) + ')';

              with GyQuery do
                begin
                  Close;
                  sql.clear;
                  sql.add(_gypcs);
                  ExecSql;
                end;
              wQuery.next;
            end;
        end;
      wquery.close;
      wdbase.close;

      inc(_y);
    end;
  Gytranz.Commit;
  Gydbase.close;
end;


// =============================================================================
                  procedure TfORM1.ExcelKill;
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





function TForm1.Scankorzet(_knum: byte): byte;

var _y: byte;

begin
  result := 9;
  _y := 1;
  while _y<=8 do
    begin
      if _knum=_korzetszam[_y] then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;


function TForm1.GetPenztarnev(_pnum: byte): string;

var _y: byte;

begin
  result := '';
  _y := 1;
  if _pnum>150 then
    begin
      while _y<=_artPtarDarab do
        begin
          if _pnum=_artszam[_y] then
            begin
              result := _artnev[_y];
              exit;
            end;
          inc(_y);
        end;
      exit;
    end;


  _y := 1;
  while _y<=_exPtardarab do
    begin
      if _pnum=_ptarszam[_y] then
        begin
          result := _ptarnev[_y];
          exit;
        end;
       inc(_y);
    end;
end;

procedure TForm1.PenztarGombClick(Sender: TObject);

begin

  MakeExcelPanel.Visible := False;

  with penztarPanel do
    begin
      left := 22;
      top  := 176;
      visible := true;
    end;

  with PenztarMenuPanel do
    begin
      left := 144;
      top := 48;
      Visible := True;
    end;
  ActiveControl := excgomb;
end;

// =============================================================================
               procedure TForm1.ExcGombClick(Sender: TObject);
// =============================================================================

var _n: string;

begin
  changeBox.Clear;
  changeBox.Items.Clear;

  _y := 1;
  changebox.Items.Add('----------------------------------');
  while _y<=_exPtarDarab do
    begin
      _n := _ptarnev[_y];
      changebox.Items.Add(_n);
      inc(_y);
    end;

  with Changebox do
    begin
      ItemIndex := 1;
      top := 50;
      left := 256;
      visible := True;
    end;

  with PtValMegsemGomb do
    begin
      top := 250;
      left:= 336;
      Visible := true;
      repaint;
    end;    

  PenztarMenuPanel.Visible := False;
  Changebox.SetFocus;
end;





procedure TForm1.CHANGEBOXDblClick(Sender: TObject);
begin
  PtValasztott;
  Form1.left := _baseleft;
end;

procedure TForm1.CHANGEBOXKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;

  ptValasztott;
  Form1.left := _baseleft;
end;


procedure TForm1.PtValasztott;

begin
  with PenztarTakaro do
    begin
      top := 8;
      left := 8;
      Visible := true;
      repaint;
    end;

  _ptss := Changebox.itemindex;
  _aktptnev := uppercase(_ptarnev[_ptss]);
  _aktptnum := _ptarszam[_ptss];

  ChangeBox.Visible := False;
  ExcelcimPanel.caption := _aktptnev+' ADATAINAK EXCELTÁBLÁBA DOLGOZÁSA FOLYAMATBAN';
  Excelcimpanel.Visible := True;
  Excelcimpanel.repaint;

  with MakeExcelPanel do
    begin
      top := 24;
      left := 8;
      visible := true;
      repaint;
    end;
  _filter := ' (PENZTAR='+inttostr(_aktptnum)+') AND ' + _idszfilter;
  _focim := 'A WESTERN UNION BIZONYLATOK A(Z) ' + _aktptnev + ' PÉNZTÁRBAN ';
  _focim := _focim + _toldatums + ' ÉS ' + _igdatums + ' KÖZÖTT';
  MakeExcel;
  PenztarTakaro.Visible := false;
end;

procedure TForm1.ZPtValasztott;

begin
  with PenztarTakaro do
    begin
      top := 8;
      left := 110;
      Visible := true;
      repaint;
    end;

  _ptss := ExpBox.itemindex;
  _aktptnev := uppercase(_artnev[_ptss]);
  _aktptnum := _artszam[_ptss];

  ExpBox.Visible := False;
  ExcelcimPanel.caption := _aktptnev+' ADATAINAK EXCELTÁBLÁBA DOLGOZÁSA FOLYAMATBAN';
  Excelcimpanel.Visible := True;
  Excelcimpanel.repaint;

  with MakeExcelPanel do
    begin
      top := 24;
      left := 8;
      visible := true;
      repaint;
    end;
  _filter := ' (PENZTAR='+inttostr(_aktptnum)+') AND ' + _idszfilter;;
  _focim := 'A WESTERN UNION BIZONYLATOK A(Z) ' + _aktptnev + ' PÉNZTÁRBAN ';
  _focim := _focim + _toldatums + ' ÉS ' + _igdatums + ' KÖZÖTT';
  MakeExcel;
  PenztarTakaro.Visible := False;
end;


procedure TForm1.EXPBOXDblClick(Sender: TObject);
begin
  ZptValasztott;
  Form1.left := _baseleft;
end;

procedure TForm1.EXPBOXKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  ZptValasztott;
  Form1.left := _baseleft;
end;

procedure TForm1.EXPGOMBClick(Sender: TObject);

var _n: string;

begin
  expBox.Clear;
  expBox.Items.Clear;

  _y := 1;
  expbox.Items.Add('----------------------------------');
  while _y<=_artPtarDarab do
    begin
      _n := _artnev[_y];
      expbox.Items.Add(_n);
      inc(_y);
    end;

  with expbox do
    begin
      ItemIndex := 1;
      top := 50;
      left := 256;
      visible := True;
    end;

  with PtValMegsemGomb do
    begin
      top := 250;
      left:= 336;
      Visible := true;
      repaint;
    end;

  PenztarMenuPanel.Visible := False;
  expbox.SetFocus;
end;

procedure TForm1.KFTGOMBClick(Sender: TObject);
begin
  MakeExcelPanel.Visible := False;
  with KftPanel do
    begin
      left := 24;
      top  := 170;
      visible := true;
      repaint;
    end;
  ActiveControl := ebcgomb;
end;

procedure TForm1.BACKKFTGOMBClick(Sender: TObject);
begin
  kftPanel.Visible := False;
end;

procedure TForm1.backptvalgombClick(Sender: TObject);
begin
  PenztarMenuPanel.Visible := False;
  Penztarpanel.Visible := False;
end;



procedure TForm1.KORZETGOMBClick(Sender: TObject);
begin
   with Korzetpanel do
     begin
       top := 170;
       left := 24;
       Visible := true;
       repaint;
     end;
   KorzetTakaro.Visible := False;
end;



procedure TForm1.BACKKORZETGOMBClick(Sender: TObject);
begin
  KorzetPanel.Visible := False;
end;

procedure TForm1.KILEPESGOMBClick(Sender: TObject);
begin
  ExcelKill;
  aPPLICATION.TERMINATE;
end;

procedure TForm1.MASIDSZGOMBClick(Sender: TObject);
begin
  LevalogatoPanel.Visible := false;
  UjidoszakBeallitas;
end;


procedure TForm1.KorzetClick(Sender: TObject);
begin
  _aktkznum := TPanel(Sender).tag;
  _kss := ScanKorzet(_aktkzNum);
  _aktkznev := _korzetnev[_kss] + ' KÖRZET';

  KorzetetValasztott;
  Form1.Left := _baseleft;
end;



procedure TForm1.KorzetetValasztott;

begin
  MakeExcelPanel.Visible := false;
  with KorzetTakaro do
    begin
      top := 24;
      left := 120;
      Visible := True;
      repaint;
    end;


  ExcelcimPanel.caption := _aktKZnev+' ADATAINAK EXCELTÁBLÁBA DOLGOZÁSA FOLYAMATBAN';
  Excelcimpanel.Visible := True;
  Excelcimpanel.repaint;

  with MakeExcelPanel do
    begin
      top := 24;
      left := 8;
      visible := true;
      repaint;
    end;
  _filter := ' (KORZET='+inttostr(_aktKZnum)+') AND ' + _idszfilter;
  _focim := 'A WESTERN UNION BIZONYLATOK A(Z) ' + _aktkznev + ' PÉNZTÁRBAN ';
  _focim := _focim + _toldatums + ' ÉS ' + _igdatums + ' KÖZÖTT';
  MakeExcel;
  KorzetTakaro.Visible := false;
  fORM1.Left := _baseleft;
end;


procedure TForm1.KftValasztott(Sender: TObject);

begin
  with KftTakaro do
    begin
      top := 8;
      left := 80;
      visible := True;
      repaint;
    end;


  _kftss := TPanel(Sender).Tag;
  _aktkftnev := _kftnevek[_kftss];
  _aktcegbetu := _cbetu[_kftss];

  ExcelcimPanel.caption := _aktKftnev + ' ADATAINAK EXCELTÁBLÁBA DOLGOZÁSA FOLYAMATBAN';
  Excelcimpanel.Visible := True;
  Excelcimpanel.repaint;

  with MakeExcelPanel do
    begin
      top := 24;
      left := 8;
      visible := true;
      repaint;
    end;
  _filter := ' (CEG=' + CHR(39) + _aktcegbetu + chr(39) +') AND ' + _idszfilter;
  _focim := 'A WESTERN UNION BIZONYLATOK A(Z) ' + _aktkftnev + ' KFT-BEN ';
  _focim := _focim + _toldatums + ' ÉS ' + _igdatums + ' KÖZÖTT';
  MakeExcel;
  KftTakaro.Visible := false;
  fORM1.Left := _baseleft;  
end;

procedure TForm1.MakeExcel;

begin
  _pcs := 'SELECT * FROM WUGYUJTO' + _sorveg;
  _pcs := _pcs + 'WHERE ' + _filter;

  Gydbase.Connected := TRUE;
  with GyQuery do
    begin
      Close;
      sql.Clear;
      sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  _lastsor := _recno + 5;

  Excelcsik.Max := _recno;
  _exceltabla := CreateOleObject('Excel.Application');

  _sajatexcel := _exceltabla.workbooks.add[1];
  _sajatexcel.activate;

  _exceltabla.range['A1:A1'].Columnwidth := 3;
  _exceltabla.range['B1:B1'].Columnwidth := 9;
  _exceltabla.range['C1:C1'].Columnwidth := 14;
  _exceltabla.range['D1:D1'].Columnwidth := 26;
  _exceltabla.range['E1:E1'].Columnwidth := 14;
  _exceltabla.range['F1:F1'].Columnwidth := 14;
  _exceltabla.range['G1:G1'].Columnwidth := 14;
  _exceltabla.range['H1:H1'].Columnwidth := 14;
  _exceltabla.range['I1:I1'].Columnwidth := 14;
  _exceltabla.range['J1:J1'].Columnwidth := 15;
  _exceltabla.range['K1:K1'].Columnwidth := 31;

  _exceltabla.range['B3:K3'].mergecells := True;
  _exceltabla.range['B3:K3'].interior.color := $B0FFFF;
  _exceltabla.range['B3:K3'].font.size := 14;
  _exceltabla.range['B3:K3'].font.italic := true;
  _exceltabla.range['B3:K3'].HorizontalAlignment := -4108;

  _exceltabla.cells(3,2) := _focim;

  _exceltabla.range['B5:K5'].HorizontalAlignment := -4108;
  _exceltabla.range['B5:K5'].Font.Bold := True;
  _exceltabla.cells(5,2) := 'CÉG';
  _exceltabla.cells(5,3) := 'KÖRZET';
  _exceltabla.cells(5,4) := 'PÉNZTÁR';
  _exceltabla.cells(5,5) := 'DÁTUM';
  _exceltabla.cells(5,6) := 'BIZONYLAT';
  _exceltabla.cells(5,7) := 'BANKJEGY';
  _exceltabla.cells(5,8) := 'VALUTANEM';
  _exceltabla.cells(5,9) := 'MTCNSZÁM';
  _exceltabla.cells(5,10):= 'TRANZAKCIÓ';
  _exceltabla.cells(5,11):= 'PÉNZTÁROSNÉV';

  // -------------------------------------------------------

   _excelTabla.range['B6:F'+inttostr(_lastsor)].HorizontalAlignment := -4108;
   _excelTabla.range['I6:J'+inttostr(_lastsor)].HorizontalAlignment := -4108;
   _excelTabla.range['G6:G'+inttostr(_lastsor)].numberformat := '### ### ###';

   _range := _exceltabla.range['A6:A6'];
   _range.select;
   _exceltabla.ActiveWindow.FreezePanes := true;

  // -------------------------------------------------------


  _prisor := 6;
  _cs := 0;
  while not GyQuery.eof do
    begin
      inc(_cs);
      excelcsik.Position := _cs;
      with GyQuery do
        begin
          _ceg := FieldByNAme('CEG').asString;
          _korzet := FieldByNAme('KORZET').asInteger;
          _penztar := FieldByName('PENZTAR').asInteger;
          _datum := FieldByNAme('DATUM').asString;
          _bizonylat := trim(FieldByName('SORSZAM').asString);
          _bankjegy := FieldByNAme('BANKJEGY').asInteger;
          _valutanem := FieldByNAme('VALUTANEM').asString;
          _mtcn := trim(FieldByName('MTCNSZAM').asstring);
          _ttipus := trim(FieldByName('TRANZAKCIOTIPUS').asString);
          _prosnev := trim(FieldByNAme('PENZTAROSNEV').asString);
        end;

      if _ceg='B' then _ceg := 'BEST';
      if _ceg='E' then _ceg := 'EAST';
      if _ceg='P' then _ceg := 'PANNON';
      if _ceg='Z' then _ceg := 'ZALOG';

      _korzet := ScanKorzet(_korzet);
      _pnev := GetPenztarNev(_penztar);
      _knev := _korzetnev[_korzet];

      _exceltabla.cells[_prisor,2] := _ceg;
      _exceltabla.cells[_prisor,3] := _knev;
      _exceltabla.cells[_prisor,4] := _pNev;
      _exceltabla.cells[_prisor,5] := _datum;
      _exceltabla.cells[_prisor,6] := _bizonylat;
      _exceltabla.cells[_prisor,7] := inttostr(_bankjegy);
      _exceltabla.cells[_prisor,8] := _valutanem;
      _exceltabla.cells[_prisor,9] := _mtcn;
      _exceltabla.cells[_prisor,10]:= _ttipus;
      _exceltabla.cells[_prisor,11]:= _prosnev;

      inc(_prisor);
      GyQuery.next;
    end;
  Gyquery.close;
  Gydbase.close;
  
  MakeExcelPanel.Visible := False;
  FORM1.Left := -1900;
  _exceltabla.visible := true;
end;

end.
