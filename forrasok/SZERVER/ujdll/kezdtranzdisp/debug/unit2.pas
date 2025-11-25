unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Comobj, Comctrls, ExtCtrls, IBDatabase, DB,
  IBCustomDataSet, IBQuery, strutils, IBTable;

type
  TForm2 = class(TForm)
    Csik         : TProgressBar;
    UzenoPanel   : TPanel;
    Kilepo       : TTimer;
    RecQuery     : TIBQuery;
    RecDbase     : TIBDatabase;
    RecTranz     : TIBTransaction;
    DQuery       : TIBQuery;
    DDbase       : TIBDatabase;
    DTranz       : TIBTransaction;
    ArtQuery     : TIBQuery;
    ArtDbase     : TIBDatabase;
    ArtTranz     : TIBTransaction;
    KdijQuery    : TIBQuery;
    KdijDbase    : TIBDatabase;
    KdijTranz    : TIBTransaction;
    KdijTabla    : TIBTable;
    TranzdijQuery: TIBQuery;
    TranzdijDbase: TIBDatabase;
    TranzdijTranz: TIBTransaction;
    VisszaGomb   : TBitBtn;
    Panel1       : TPanel;
    Shape1       : TShape;

    procedure PenztarParaBeolvasas;
    procedure Korzetbeiro;
    procedure MakeExcel;
    procedure FormActivate(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure Keret(_rs: string; _wide: byte);
    procedure VisszaGombClick(Sender: TObject);

    function GetKorzetnev(_pr: byte): string;
    function ScanKorzet(_kk: byte): byte;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _honev: array[1..12] of string = ('január','fenruár','március','április',
                'május','junius','július','augusztus','szeptember','október',
                'november','december');

  _korzetnevek: array[1..9] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
                  'DEBRECEN','NYIREGYHÁZA','BÉKÉSCSABA','PÉCS','KAPOSVÁR',
                  'EXPRESSZ');

  _korzetszamok: array[1..9] of byte = (10,20,40,50,63,75,120,145,180);
  _penztarnev  : array[1..170] of string;
  _korzet      : array[1..170] of byte;
  _penztarsor  : array[1..170] of byte;

  _tranzdij,_kezdij: array[1..170] of integer;

  _oxl,_owb,_range: olevariant;
  _rangestr,_focim,_pnev,_korzetnev,_tolstring,_evs,_hos,_farok,_daybook: string;
  _fdbPath,_status,_aMezo,_uzNev,_kdijTablaNev,_pcs,_vMezo,_emezo: string;
  _tranzdijTablaNev,_formula: string;
  _sorveg: string = chr(13)+chr(10);

  _penztardb,_lastsor,_prisor,_ptss,_aktkorzet,_pt,_ujkorzet,_xx,_anap,_uzlet: byte;
  _uzkorzet,_aktpt: byte;
  _kertev,_kertho,_csikss,_penztardarab,_ss,_z,_lastprisor,_ksor,_vsor: word;
  _tranzFt,_kezdFt,_hoOke,_code,_mResult,_vAdat,_eAdat,_ptfee,_aktfee: integer;
  _sumtra,_sumkez : integer;


function hovalasztorutin: integer; stdcall; external 'c:\receptor\newdll\hovalasz.dll';
function kezdtranzdisplay: integer; stdcall;


implementation

{$R *.dfm}

function kezdtranzdisplay: integer; stdcall;
begin
  Form2 := TForm2.Create(Nil);
  result := Form2.showmodal;
  Form2.free; 
end;

// =============================================================================
             procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin

  Top  := 292;
  Left := 347;
  Repaint;

  _hooke := hovalasztorutin;
  if _hooke=-1 then
    begin
      _mResult := -1;
      Kilepo.enabled := True;
      exit;
    end;

   with RecDbase do
     begin
       Close;
       DatabaseName := 'c:\receptor\database\receptor.fdb';
       Connected := True;
     end;

   with RecQuery do
     begin
       Close;
       sql.clear;
       sql.add('SELECT * FROM IDOSZAK');
       Open;
       _tolstring := FieldByName('STARTDATE').asString;
       Close;
     end;
   RecDbase.close;

   _evs := leftstr(_tolstring,4);
   _hos := midstr(_tolstring,6,2);

   val(_evs,_kertev,_code);
   val(_hos,_kertho,_code);

   _farok := midstr(_evs,3,2)+_hos;

   // ---------------------------------------------------

   PenztarParaBeolvasas;

   // ---------- KEZELÉSI DÍJAK BEOLVASÁSA - BEST CHANGE -----------------------

   _kdijTablaNev := 'KEZD' + _farok;
   with KdijDbase do
     begin
       Close;
       DatabaseName := 'c:\receptor\database\kezdij.fdb';
       Connected := True;
     end;

   KdijTabla.Close;
   KdijTabla.TableName := _kdijtablanev;

   if not KdijTabla.Exists then
     begin
       ShowMessage('NINCS HAVI TÁBLA');
       KdijDbase.close;

       _mResult := -1;

       Kilepo.Enabled := true;
       exit;
     end;

   KorzetBeiro;

   _pcs := 'SELECT * FROM ' + _kdijTablaNev +_sorveg;
   _pcs := _pcs + 'WHERE PENZTAR<151'+_SORVEG;
   _pcs := _pcs + 'ORDER BY ERTEKTAR,PENZTAR';

   with KdijQuery do
     begin
       Close;
       Sql.clear;
       Sql.add(_pcs);
       Open;
       First;
     end;

   _ss := 0;
   while not KdijQuery.Eof do
     begin
       inc(_ss);

       _pt := KdijQuery.FieldByName('PENZTAR').asInteger;
       _penztarSor[_ss] := _pt;

       _tranzFt := 0;
       _kezdFt  := 0;

       // egy pénztár napi kezelési dijainak összegezésa:

       _z := 1;
       while _z<=31 do
         begin
           _vMezo  := 'KDV'+inttostr(_z);
           _eMezo  := 'KDE'+inttostr(_z);
           _vadat  := Kdijquery.FieldByNAme(_vMezo).asInteger;
           _eAdat  := Kdijquery.FieldByNAme(_eMezo).asInteger;
           _kezdFt := _kezdFt + _vAdat + _eAdat;

           inc(_z);
          end;

       // Pénztár havi kezelési dija:

       _kezdij[_pt] := _kezdft;
       KdijQuery.Next;
     end;
   KdijQuery.close;
   Kdijdbase.close;

//   _penztardb := _ss;


   {
   // ----------   EXPRESSZ ÉKSZERHÁZ  -----------------------

   with KdijDbase do
     begin
       Close;
       DatabaseName := 'c:\cartcash\database\kezdij.fdb';
       Connected := True;
     end;

   KdijTabla.Close;
   KdijTabla.TableName := _kdijtablanev;

   if not KdijTabla.Exists then
     begin
       ShowMessage('NINCS EXPRESSZ HAVI TÁBLA');
       KdijDbase.close;

       _mResult := -1;

       Kilepo.Enabled := true;
       exit;
     end;

   _pcs := 'SELECT * FROM ' + _kdijTablaNev + _SORVEG;
   _pcs := _pcs + 'ORDER BY PENZTAR';

   with KdijQuery do
     begin
       Close;
       Sql.clear;
       Sql.add(_pcs);
       Open;
       First;
     end;

   while not KdijQuery.Eof do
     begin
       inc(_ss);

       _pt := KdijQuery.FieldByName('PENZTAR').asInteger;
       _penztarSor[_ss] := _pt;

       _tranzFt := 0;
       _kezdFt  := 0;

       // egy pénztár napi kezelési dijainak összegezésa:

       _z := 1;
       while _z<=31 do
         begin
           _vMezo  := 'VKD'+inttostr(_z);
           _eMezo  := 'EKD'+inttostr(_z);
           _vAdat  := KdijQuery.FieldByNAme(_vMezo).asInteger;
           _eAdat  := KdijQuery.FieldByNAme(_eMezo).asInteger;
           _kezdFt := _kezdFt + _vAdat + _eAdat;

           inc(_z);
          end;

       // Pénztár havi kezelési dija:

       _kezDij[_pt] := _kezdft;
       KdijQuery.Next;
     end;
   KdijQuery.close;
   Kdijdbase.close;
   }

   _penztardb := _ss;

   // ------- a tranzakciós dijak beolvasása -----------------------------------

   _tranzdijtablanev := 'TRANZDIJ' + _farok;

   _pcs := 'SELECT * FROM ' + _tranzdijTablanev + _sorveg;
   _pcs := _pcs + 'ORDER BY DISTRICT,CASHIER';

   _ss := 0;
   with TranzdijDbase do
     begin
       Close;
       Databasename := 'c:\receptor\database\tranzdij.fdb';
       Connected := true;
     end;

   with TranzdijQuery do
     begin
       Close;
       sql.clear;
       sql.add(_pcs);
       Open;
       First;
     end;

   _ptfee := 0;
   _aktpt := TranzdijQuery.fieldByNAme('CASHIER').asInteger;

   while not TranzdijQuery.eof do
     begin
       _pt := TranzdijQuery.FieldByNAme('CASHIER').asInteger;
       _aktfee := TranzdijQuery.fieldByNAme('TRANSFEE').asInteger;

       if _pt<>_aktpt then
         begin
           inc(_ss);
           _tranzdij[_aktpt] := _ptfee;
           _aktpt := _pt;
           _ptfee := 0;
         end;

       _ptfee := _ptfee + _aktfee;
       TranzdijQuery.next;
     end;
    inc(_ss);
   _tranzdij[_aktpt] := _ptFee;
   TranzdijQuery.close;
   Tranzdijdbase.close;

   {
   // ----------- expressz zálog tranzakciós értékei ---------------------------

   _pcs := 'SELECT * FROM ' + _tranzdijTablaNev + ' ORDER BY CASHIER';

   with artdbase do
     begin
       close;
       databasename := 'c:\cartcash\database\tranzdij.fdb';
       connected := true;
     end;

   with ArtQuery do
     begin
       Close;
       sql.clear;
       sql.Add(_pcs);
       Open;
     end;

   _ptfee := 0;
   _aktpt := ArtQuery.fieldByNAme('CASHIER').asInteger;

   while not artQuery.eof do
     begin
       _pt := ArtQuery.FieldByNAme('CASHIER').asInteger;
       _aktfee := ArtQuery.FieldByNAme('TRANSFEE').asInteger;
       if _pt<>_aktpt then
         begin
           inc(_ss);
           _tranzdij[_aktpt] := _ptfee;
           _aktpt := _pt;
           _ptfee := 0;
         end;
       _ptfee := _ptfee + _aktfee;
       ArtQuery.next;
     end;

   _tranzdij[_aktpt] := _ptFee;
   inc(_ss);

   ArtQuery.close;
   ArtDbase.close;
   }


   MakeExcel;

   Csik.Visible       := False;
   UzenoPanel.Visible := False;
   VisszaGomb.visible := True;

   Activecontrol := Visszagomb;
end;


// =============================================================================
                         procedure TForm2.MakeExcel;
// =============================================================================

begin
  UzenoPanel.Caption := 'Exceltábla készítése';
  Uzenopanel.repaint;
  Csik.Visible := false;

  _focim := '       Az Exclusive Change és Expressz Zálog '+inttostr(_kertev)+' ';
  _focim := _focim + _honev[_kertho]+' havitranzakciós és kezelési díj listája';

  _sumtra := 0;
  _sumkez := 0;

  _oxl := CreateOleObject('Excel.Application');
  _owb := _oxl.workbooks.add[1];

  _oxl.range['A1:A1'].columnwidth := 25;
  _oxl.range['B1:B1'].columnwidth := 15;
  _oxl.range['C1:C1'].columnwidth := 36;
  _oxl.range['D1:D1'].columnwidth := 15;
  _oxl.range['E1:E1'].columnwidth := 15;

  _rangestr := 'A3:F3';
  _oxl.range[_rangestr].Mergecells := True;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;
  _oxl.range[_rangestr].Font.Name := 'Arial';
  _oxl.range[_rangestr].Font.Size := 11;
  _oxl.range[_rangestr].Font.Bold := True;
  _oxl.range[_rangestr].Font.Italic := True;
  _oxl.cells[3,1] := _focim;

  _rangestr := 'B5:B6';
  _oxl.range[_rangestr].Mergecells := True;

  _rangestr := 'C5:C6';
  _oxl.range[_rangestr].Mergecells := True;

  _rangestr := 'D5:D6';
  _oxl.range[_rangestr].Mergecells := True;

  _rangestr := 'E5:E6';
  _oxl.range[_rangestr].Mergecells := True;

  _rangestr := 'B5:E6';
  _oxl.range[_rangestr].VerticalAlignment := -4108;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;
  _oxl.range[_rangestr].Font.Size   := 11;
  _oxl.range[_rangestr].Font.Bold   := True;
  _oxl.range[_rangestr].Font.Italic := True;
  _oxl.range[_rangestr].Wraptext := True;
  _oxl.cells[5,2] := 'PÉNZTÁR SZÁMA';
  _oxl.cells[5,3] := 'PÉNZTÁR MEGNEVEZÉSE';
  _oxl.cells[5,4] := 'TRANZAKCIÓ DÍJ';
  _oxl.cells[5,5] := 'BEFIZETETT KEZ-I DÍJ';

  _lastsor:= 7+_penztardb+18;

  _rangestr := 'B'+inttostr(8)+':E'+ inttostr(_lastsor);
  _oxl.range[_rangestr].Font.Size := 11;
  _oxl.range[_rangestr].Font.Bold := False;
  _oxl.range[_rangestr].Font.Italic := False;
  _prisor := 7;
  _ksor := 7;
  _ptss := 1;
  _aktkorzet := 10;
  while _ptss<=_penztardb do
    begin
      _pt       := _penztarsor[_ptss];
      _pnev     := _penztarnev[_pt];
      _ujkorzet := _korzet[_pt];
      _tranzft  := _tranzdij[_pt];
      _kezdFt   := _kezdij[_pt];

      if _pt>150 then break;

      _sumtra := _sumtra + _tranzft;
      _sumkez := _sumkez + _kezdFt;


      if (_ujkorzet>_aktKorzet) then
        begin
          _vsor := _prisor-1;
          _formula := '=SUM(D'+inttostr(_ksor)+':D'+inttostr(_vsor)+')';
          _rangestr := 'B'+inttostr(_prisor)+':C'+inttostr(_prisor);
          _oxl.cells[_prisor,4].formula := _formula;

          _formula := '=SUM(E'+inttostr(_ksor)+':E'+inttostr(_vsor)+')';
          _rangestr := 'B'+inttostr(_prisor)+':C'+inttostr(_prisor);
          _oxl.cells[_prisor,5].formula := _formula;

          _oxl.range[_rangestr].Mergecells := true;

          _rangestr := 'B'+inttostr(_prisor)+':E'+inttostr(_prisor);
          _oxl.range[_rangestr].Font.size := 12;
          _oxl.range[_rangestr].Font.Bold := True;


          _korzetnev := GetKorzetnev(_aktkorzet);
          _oxl.Cells[_prisor,2] := _korzetnev+' ÖSSZESEN';
          _prisor := _prisor+2;
          _ksor := _prisor;
          _aktkorzet := _ujkorzet;
        end;

      _oxl.cells[_prisor,2] := _pt;
      _oxl.cells[_prisor,3] := _pnev;
      _oxl.cells[_prisor,4] := _tranzFt;
      _oxl.cells[_prisor,5] := _kezdFt;

      inc(_prisor);
      inc(_ptss);
     end;
  _vsor := _prisor-1;
  _formula := '=SUM(D'+inttostr(_ksor)+':D'+inttostr(_vsor)+')';
  _oxl.cells[_prisor,4].formula := _formula;

  _formula := '=SUM(E'+inttostr(_ksor)+':E'+inttostr(_vsor)+')';
  _oxl.cells[_prisor,5].formula := _formula;

  _rangestr := 'B'+inttostr(_prisor)+':C'+inttostr(_prisor);
  _oxl.range[_rangestr].Mergecells := true;

  _rangestr := 'B'+inttostr(_prisor)+':E'+inttostr(_prisor);
  _oxl.range[_rangestr].Font.size := 12;
  _oxl.range[_rangestr].Font.Bold := True;

  _korzetnev := GetKorzetnev(_aktkorzet);
  _oxl.Cells[_prisor,2] := _korzetnev+' ÖSSZESEN';

  inc(_prisor);
  _rangestr := 'B'+inttostr(_prisor)+':C'+inttostr(_prisor);
  _oxl.range[_rangestr].Mergecells := true;
  _oxl.cells[_prisor,2] := 'Exclusive Best Change összesen';

  _rangestr := 'B'+inttostr(_prisor)+':E'+inttostr(_prisor);
  _oxl.range[_rangestr].Font.size := 12;
  _oxl.range[_rangestr].Font.Bold := True;
  _oxl.range[_rangestr].Font.Color := clRed;

  _oxl.Cells[_prisor,4] := _sumtra;
  _oxl.cells[_prisor,5] := _sumkez;

  _prisor := _prisor+2;
  _ksor := _prisor;

  _aktkorzet := _ujkorzet;

  _oxl.cells[_prisor,2] := _pt;
  _oxl.cells[_prisor,3] := _pnev;
  _oxl.cells[_prisor,4] := _tranzFt;
  _oxl.cells[_prisor,5] := _kezdFt;

  inc(_prisor);
  inc(_ptss);

  while _ptss<=_penztardb do
    begin
      _pt := _penztarsor[_ptss];
      _pnev := _penztarnev[_pt];
      _ujkorzet := _korzet[_pt];
      _tranzft := _tranzdij[_pt];
      _kezdFt  := _kezdij[_pt];

      _oxl.cells[_prisor,2] := _pt;
      _oxl.cells[_prisor,3] := _pnev;
      _oxl.cells[_prisor,4] := _tranzFt;
      _oxl.cells[_prisor,5] := _kezdFt;

      inc(_prisor);
      inc(_ptss);
    end;

  _vsor := _prisor-1;
  _formula := '=SUM(D'+inttostr(_ksor)+':D'+inttostr(_vsor)+')';
  _oxl.cells[_prisor,4].formula := _formula;

  _formula := '=SUM(E'+inttostr(_ksor)+':E'+inttostr(_vsor)+')';
  _oxl.cells[_prisor,5].formula := _formula;

  _rangestr := 'B'+inttostr(_prisor)+':C'+inttostr(_prisor);
  _oxl.range[_rangestr].Mergecells := true;
  _oxl.Cells[_prisor,2] := 'EXPRESSZ ÖSSZESEN';

  _rangestr := 'B'+inttostr(_prisor)+':E'+inttostr(_prisor);
  _oxl.range[_rangestr].Font.size := 12;
  _oxl.range[_rangestr].Font.Bold := True;
  _oxl.range[_rangestr].Font.Color := clRed;

  _lastprisor := _prisor;

  _rangestr := 'B7:B'+inttostr(_lastprisor);
  _oxl.range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'D7:E'+inttostr(_lastprisor);
  _oxl.range[_rangestr].HorizontalAlignment := -4108;
  _oxl.range[_rangestr].Numberformat := '### ### ###';

  Keret('C5:C6',2);
  Keret('D5:D6',2);
  Keret('B5:E6',4);

   _vsor := _prisor-1;
   _range := _oxl.range['A7','A7'];
   _range.select;
   _oxl.Activewindow.FreezePanes := True;

   _oxl.visible := True;
end;

// =============================================================================
           function TForm2.GetKorzetnev(_pr: byte): string;
// =============================================================================

begin
  _xx := ScanKorzet(_pr);
  result := _korzetnevek[_xx];
end;

// =============================================================================
              function TForm2.ScanKorzet(_kk: byte): byte;
// =============================================================================

var _y: byte;

begin
  result := 0;
  _y := 1;
  while _y<=9 do
    begin
      if _korzetszamok[_y]=_kk then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
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
      _uzkorzet := RecQuery.FieldByName('ERTEKTAR').asInteger;
      if _uzlet>150 then _uzKorzet := 180;

      _penztarNev[_uzlet] := _uznev;
      _korzet[_uzlet] := _uzKorzet;
      recQuery.next;
    end;
  recquery.close;
  recdbase.close;


  // -----------------------------------------
  {
  _fdbPath := 'c:\cartcash\database\artcash.fdb';
  with Artdbase do
    begin
      Close;
      DatabaseName := _fdbPath;
      Connected := true;
    end;

  with ArtQuery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM IRODAK ORDER BY UZLET');
      Open;
    end;

  while not ArtQuery.eof do
    begin
      inc(_csikss);
      Csik.Position := _csikss;

      _uzlet := ArtQuery.fieldbyname('UZLET').asInteger;
      _uznev := trim(ArtQuery.FieldByNAme('KESZLETNEV').asString);
      _uzkorzet := ArtQuery.FieldByName('ERTEKTAR').asInteger;

      _penztarNev[_uzlet] := _uznev;
      _korzet[_uzlet] := _uzKorzet;


      ArtQuery.next;
    end;
  ArtQuery.close;
  ArtDbase.close;
  }

  Csik.Position := 168;
  sleep(1500);
end;

// =============================================================================
               procedure TForm2.Keret(_rs: string; _wide: byte);
// =============================================================================

begin
  _oxl.range[_rs].Borderaround(1,_wide);
end;

// =============================================================================
              procedure TForm2.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := _mResult;
end;

// =============================================================================
               procedure TForm2.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 1;
  Kilepo.Enabled := true;
end;

// =============================================================================
                    procedure TForm2.Korzetbeiro;
// =============================================================================

var _aktet: byte;

begin
  Kdijdbase.connected := true;

  if Kdijtranz.InTransaction then KdijTranz.commit;
  Kdijtranz.StartTransaction;

  KdijTabla.Close;

  KdijTabla.TableName := _kdijtablanev;
  Kdijtabla.Open;
  while not KDijTabla.Eof do
    begin
      _aktpt := Kdijtabla.fieldByNAme('PENZTAR').asInteger;
      _aktet := _korzet[_aktpt];

      Kdijtabla.edit;
      KdijTabla.FieldByName('ERTEKTAR').AsInteger := _aktet;
      KdijTabla.Post;

      KdijTabla.next;
    end;

  Kdijtranz.commit;
  Kdijdbase.close;
  KdijTabla.close;
end;



end.
