unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, dateutils, IBDatabase, DB,strutils,
  IBCustomDataSet, TlHelp32, IBQuery;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Shape1: TShape;
    P12: TPanel;
    P6: TPanel;
    P9: TPanel;
    P3: TPanel;
    P1: TPanel;
    P2: TPanel;
    P10: TPanel;
    P11: TPanel;
    P8: TPanel;
    P7: TPanel;
    P4: TPanel;
    P5: TPanel;
    HONEVPANEL: TPanel;
    EVCOMBO: TComboBox;
    HOOKEGOMB: TBitBtn;
    HOMEGSEMGOMB: TBitBtn;
    BitBtn1: TBitBtn;
    Panel2: TPanel;
    Panel3: TPanel;
    Shape2: TShape;
    Shape3: TShape;
    Label1: TLabel;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    ACQUERY: TIBQuery;
    ACDBASE: TIBDatabase;
    ACTRANZ: TIBTransaction;
    BESZQUERY: TIBQuery;
    BESZDBASE: TIBDatabase;
    BESZTRANZ: TIBTransaction;


    procedure P12MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Shape1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormActivate(Sender: TObject);
    procedure P11MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure HOMEGSEMGOMBClick(Sender: TObject);
    procedure EVCOMBOChange(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure HOOKEGOMBClick(Sender: TObject);
    procedure KonstansBetoltes;
    procedure SetKorzetPt(_etar,_ptar: word);
    procedure AdatNullazas;
    procedure ExcelKill;
    procedure KonkurenciaOlvasas;
    procedure KonkTombClear;

    function Nulele(_b: byte): string;
    function ScanEtar(_e: word): byte;



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _top,_left,_height,_width: word;

  _honev: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS',
              'MÁJUS','JÚNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
              'NOVEMBER','DECEMBER');

  _ppanel: array[1..12] of TPanel;

  _korzetnevek: array[1..8] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
                                    'DEBRECEN','NYÍREGYHÁZA','BÉKÉSCSABA',
                                    'PÉCS','KAPOSVÁR');

  _korzetszamok: array[1..8] of WORD = (10,20,40,50,63,75,120,145);
  _korzetPtDb: array[1..8] of byte;
  _korzetPtszamSor: array[1..8,1..30] of byte;

  _korzetIndex,_aktkorzetdarab,_etarss,_aktkdb: byte;
  _kNev,_aktkorzetnev,_rangestr,_long,_pcs,_fdbPath,_aktknev,_aktkk: string;
  _bfTablanev,_bttablanev,_tranztablanev,_wutablanev,_besztablanev: string;
  _eevbesztablanev,_ehobesztablanev: string;
  _bizonylatszam,_datum,_tipus,_farok: string;

  _k1nev,_k2nev,_k3nev,_k4nev,_exckk: array[1..150] of string;
  _kk1,_kk2,_kk3,_kk4: array[1..150] of string;
  _kdb: array[1..150] of byte;

  _sorveg: string = chr(13) + chr(10);

  _recno,_netto,_kezelesidij: integer;

  _penztarnev: array[1..150] of string;
  _ptertektar: array[1..150] of integer;

  _konk : array[1..22] of string;
  _kkonk: array[1..8,1..6] of byte;
  _konkdb: array[1..8] of byte = (4,6,6,5,5,4,4,5);

  _vetel,_eladas,_wuhuf,_wuusd,_haszon,_kezdij,_tranzado: array[1..150] of real;
  _vugyfel,_eugyfel,_wuugyfel: array[1..150] of integer;

  _eevvetel,_eeveladas,_eevwuhuf,_eevwuusd: array[1..150] of real;
  _eevhaszon,_eevkezdij,_eevtranzado: array[1..150] of real;
  _eevvugyfel,_eeveugyfel,_eevwuugyfel: array[1..150] of integer;

  _kertev,_kertho,_aktev,_aktho,_korzet,_ehoev,_ehoho: word;
  _hoclosed: boolean;
  _aktpanel: TPanel;

  _aktpenztarnev,_eevfarok: string;
  _aktertektar,_aktvugyfel,_akteugyfel,_aktwuugyfel: integer;
  _aktvetel,_akteladas: real;
  _aktwuhuf,_aktwuusd,_akthaszon,_aktkezdij,_akttranzado: real;

  _aktpenztar: word;

  proc : PROCESSENTRY32;
  _handle : HWND;
  _Looper : BOOL;


implementation

uses Unit3, Unit2;

{$R *.dfm}

// =============================================================================
             procedure TForm1.HOOKEGOMBClick(Sender: TObject);
// =============================================================================

var _evindex: byte;
    _kevs: string;
    _code: integer;

begin
  _evindex := evCombo.itemindex;
  _kevs := trim(evcombo.Items[_evindex]);
  val(_kevs,_kertev,_code);

  if _code<>0 then exit;
  _farok := midstr(_kevs,3,2)+nulele(_kertho);
  _bftablanev := 'BF' + _farok;
  _bttablanev := 'BT' + _farok;
  _wutablanev := 'WUNI' + _farok;
  _tranztablanev := 'TRANZDIJ' + _farok;
  _beszTablanev := 'BESZ' + _farok;

  KonkTombClear;
  KonkurenciaOLvasas;

  Adatgyujtes.Showmodal;
  MakeExcel.Showmodal;
  Application.terminate;
end;


// =============================================================================
        procedure TForm1.P12MouseMove(Sender: TObject; Shift: TShiftState;
                                                                 X,Y: integer);
// =============================================================================

var _xho: word;

begin
  if _hoClosed then exit;

  _xho := TPanel(sender).Tag;
  if _xho=_kertho then exit;

  _kertho := _xho;
  Honevpanel.Caption := _honev[_xho];
  Honevpanel.repaint;
end;

// =============================================================================
     procedure TForm1.Shape1MouseMove(Sender: TObject; Shift: TShiftState;
                                                                   X,Y:integer);
// =============================================================================

begin
  if _hoclosed then exit;

//  _KERTHO := 0;
  HonevPanel.Caption := '';
  HonevPanel.repaint;
end;

// =============================================================================
                 procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

var i: byte;

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;
  _left   := trunc((_width-862)/2);
  _top    := 120;

  Top     := _top;
  Left    := _left;
  width   := 870;

  HoOkeGomb.Enabled := False;

  AdatNullazas;
  KOnstansBetoltes;


  _aktev:= yearof(date);
  _aktho := monthof(date);

  _kertho := 0;
  _hoClosed := False;
  _ppanel[1] := P1;
  _ppanel[2] := P2;
  _ppanel[3] := P3;
  _ppanel[4] := P4;
  _ppanel[5] := P5;
  _ppanel[6] := P6;
  _ppanel[7] := P7;
  _ppanel[8] := P8;
  _ppanel[9] := P9;
  _ppanel[10]:= P10;
  _ppanel[11]:= P11;
  _ppanel[12]:= P12;

  for i := 1 to 12 do _ppanel[i].Font.Color := clBlack;
  HonevPanel.Font.Color := clBlack;
  Evcombo.font.Color := clBlack;

  Evcombo.Items.clear;
  evcombo.Items.Add(inttostr(_aktev-2));
  evcombo.Items.Add(inttostr(_aktev-1));
  evcombo.Items.Add(inttostr(_aktev));

  evcombo.ItemIndex := 2;
  _aktpanel := _ppanel[_aktho];
  Activecontrol := _aktpanel;
end;

// =============================================================================
     procedure TForm1.P11MouseDown(Sender: TObject; Button: TMouseButton;
                                             Shift: TShiftState; X, Y: Integer);
// =============================================================================

var i: byte;

begin
  _hoclosed := true;
  _kertho := TPanel(sender).Tag;

  for i := 1 to 12 do _ppanel[i].Font.Color := clSilver;
  HonevPanel.Font.Color := clRed;
  evcombo.Font.Color := clRed;
  Evcombo.Enabled := False;
  HoOkeGomb.Enabled := true;
  Activecontrol := Hookegomb;
end;

// =============================================================================
             procedure TForm1.HOMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

var i: byte;

begin
  _Kertho := 0;
  for i := 1 to 12 do _ppanel[i].Font.Color := clBlack;
  HonevPanel.Font.Color := clBlack;
  Evcombo.Font.Color := clBlack;
  _hoclosed := False;
  Hookegomb.Enabled := False;
  Evcombo.Enabled := true;

end;

// =============================================================================
            procedure TForm1.EVCOMBOChange(Sender: TObject);
// =============================================================================

begin
  Activecontrol := p1;
end;

// =============================================================================
               procedure TForm1.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;

// =============================================================================
                      procedure TForm1.KonstansBetoltes;
// =============================================================================

var _pt,_et: word;
    _pn: string;

begin
  _konk[1] := 'BRIGETIO';
  _konk[2] := 'BUZAI';
  _konk[3] := 'CHANGE PONT';
  _konk[4] := 'CORNER';
  _konk[5] := 'CORRECT';
  _konk[6] := 'EURÓ-MANI';
  _konk[7] := 'FECO';
  _konk[8] := 'FÖNICIA';
  _konk[9] := 'GÓDI';
  _konk[10]:= 'IBUSZ';
  _konk[11]:= 'INFINITI';
  _konk[12]:= 'INTERCHANGE';
  _konk[13]:= 'MECSEK TAKARÉK';
  _konk[14]:= 'MINIBANK';
  _konk[15]:= 'MISO';
  _konk[16]:= 'NÁDIX';
  _konk[17]:= 'NÉMETH';
  _konk[18]:= 'NORTHLINE';
  _konk[19]:= 'OROSTRAVEL';
  _konk[20]:= 'ÖREG';
  _konk[21]:= 'ROMÁN';
  _konk[22]:= 'SÜMEGI';

  _kkonk[1,1] := 9;
  _kkonk[1,2] := 10;
  _kkonk[1,3] := 13;
  _kkonk[1,4] := 17;

  _kkonk[2,1] := 4;
  _kkonk[2,2] := 5;
  _kkonk[2,3] := 10;
  _kkonk[2,4] := 12;
  _kkonk[2,5] := 14;
  _kkonk[2,6] := 18;

  _kkonk[3,1] := 4;
  _kkonk[3,2] := 5;
  _kkonk[3,3] := 6;
  _kkonk[3,4] := 10;
  _kkonk[3,5] := 11;
  _kkonk[3,6] := 18;

  _kkonk[4,1] := 2;
  _kkonk[4,2] := 5;
  _kkonk[4,3] := 8;
  _kkonk[4,4] := 10;
  _kkonk[4,5] := 16;

  _kkonk[5,1] := 3;
  _kkonk[5,2] := 5;
  _kkonk[5,3] := 10;
  _kkonk[5,4] := 14;
  _kkonk[5,5] := 21;

  _kkonk[6,1] := 10;
  _kkonk[6,2] := 18;
  _kkonk[6,3] := 19;
  _kkonk[6,4] := 20;

  _kkonk[7,1] := 4;
  _kkonk[7,2] := 5;
  _kkonk[7,3] := 10;
  _kkonk[7,4] := 15;

  _kkonk[8,1] := 1;
  _kkonk[8,2] := 5;
  _kkonk[8,3] := 7;
  _kkonk[8,4] := 10;
  _kkonk[8,5] := 22;

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE (CLOSED=' + chr(39)+'N'+chr(39)+')';
  _pcs := _pcs + ' AND (STATUS=' + chr(39) + 'P' + chr(39) + ')'+_sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  recdbase.Connected := true;
  with RecQuery do
    begin
      Close;
      Sql.Clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not RecQuery.eof do
    begin
      _pt := RecQuery.FieldByName('UZLET').asInteger;
      _pn := trim(Recquery.FieldByName('KESZLETNEV').asstring);
      _et := Recquery.FieldByName('ERTEKTAR').asInteger;
      _ptErtektar[_pt] := _et;
      _penztarnev[_pt] := _pn;
      SetKorzetPt(_et,_pt);
      RecQuery.next;
    end;
  Recquery.close;
  Recdbase.close;

 
end;

// =============================================================================
                procedure TForm1.setKorzetPt(_etar,_ptar: word);
// =============================================================================

var _kp: byte;

begin
  _etarss := scanEtar(_etar);
  _kp := _korzetPtdb[_etarss]+1;
  _korzetPtdb[_etarss] := _kp;
  _korzetPtSzamsor[_etarss,_kp] := _ptar;
end;

// =============================================================================
                    function TForm1.ScanEtar(_e: word): byte;
// =============================================================================


var _y: byte;

begin
  _y := 1;
  result := 0;
  while _y<=8 do
    begin
      if _korzetszamok[_y]=_e then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;


// =============================================================================
                           procedure TForm1.AdatNullazas;
// =============================================================================

var i: byte;

begin
  for i := 1 to 150 do
    begin
      _penztarnev[i] := '';
      _ptErtektar[i] := 0;
   end;

  for i := 1 to 8 do _korzetPtDb[i] := 0;
end;

// =============================================================================
                   function TForm1.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
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


procedure TForm1.KonkurenciaOlvasas;

var _aktkdb: byte;

begin
  _pcs := 'SELECT * FROM KONKURENCIA';
  Beszdbase.connected := true;
  with Beszquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not Beszquery.Eof do
    begin
      with BeszQuery do
        begin
          _aktpenztar := FieldByName('PENZTAR').asInteger;
          _aktkdb := FieldByName('KONKDARAB').asInteger;
          _k1nev[_aktpenztar] := trim(FieldbyNAme('K1NEV').asstring);
          _exckk[_aktpenztar] := trim(FieldbyName('EXCKK').AsString);
          if _aktkdb>0 then _kk1[_aktpenztar] := trim(FieldByName('KK1').AsString);
          if _aktkdb>1 then
            begin
              _k2nev[_aktpenztar] := trim(FieldByName('K2NEV').AsString);
              _kk2[_aktpenztar]  := trim(FieldByName('KK2').AsString);
            end;

          if _aktkdb>2 then
            begin
              _k3nev[_aktpenztar] := trim(FieldByName('K3NEV').AsString);
              _kk3[_aktpenztar]   := trim(FieldByName('KK3').AsString);
            end;

          if _aktkdb>3 then
            begin
              _k4nev[_aktpenztar] := trim(FieldByName('K4NEV').AsString);
              _kk4[_aktpenztar]   := trim(FieldByName('KK4').AsString);
            end;
        end;
      _kdb[_aktpenztar] := _aktkdb;
      BeszQuery.Next;
    end;
  BeszQuery.close;
  Beszdbase.close;
end;

procedure TForm1.KonkTombClear;

var _y: byte;

begin
  _y := 1;
  while _y<=150 do
    begin
      _kdb[_y] := 0;
      _exckk[_y] := '';
      _k1nev[_y] := '';
      _k2nev[_y] := '';
      _k3nev[_y] := '';
      _k4nev[_y] := '';
      _kk1[_y] := '';
      _kk2[_y] := '';
      _kk3[_y] := '';
      _kk4[_y] := '';
      inc(_y);
    end;
end;


end.
