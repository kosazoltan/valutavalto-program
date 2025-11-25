unit Unit34;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, unit1, StdCtrls, Buttons, Grids, DBGrids, IBDatabase,
  DB, IBCustomDataSet, IBTable, ComCtrls, IBQuery, StrUtils;

type
  TARFOLYAMELTERITES = class(TForm)
    STARTTIMER: TTimer;
    KEDVEZTABLA: TIBTable;
    KEDVEZDBASE: TIBDatabase;
    KEDVEZTRANZ: TIBTransaction;
    FUGGONY: TPanel;
    IRODAPANEL: TPanel;
    Label3: TLabel;
    idoszakPanel: TPanel;
    KILEPOTIMER: TTimer;
    ARFEDBASE: TIBDatabase;
    ARFETRANZ: TIBTransaction;
    ARFETABLA: TIBTable;
    ARFEQUERY: TIBQuery;
    KEDVEZQUERY: TIBQuery;
    ARFETABLADATUM: TIBStringField;
    ARFETABLAVALUTANEM: TIBStringField;
    ARFETABLAARFOLYAM: TFloatField;
    ARFETABLAUJARFOLYAM: TFloatField;
    ARFETABLAPENZTAROSNEV: TIBStringField;
    ARFETABLABIZONYLATSZAM: TIBStringField;
    ARFETABLABANKJEGY: TIntegerField;
    ARFETABLAENGEDMENYTIPUS: TSmallintField;
    CSIK: TProgressBar;
    BitBtn1: TBitBtn;
    Shape1: TShape;
    Shape2: TShape;
    Shape3: TShape;
    Shape4: TShape;
    Shape5: TShape;

    procedure FormActivate(Sender: TObject);
    procedure STARTTIMERTimer(Sender: TObject);

    procedure BitBtn1Click(Sender: TObject);
    procedure KILEPOTIMERTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ARFOLYAMELTERITES: TARFOLYAMELTERITES;
  _idszOke,_uzlet,_ratetype,_diff,_engedmeny,_bankjegy: integer;
  _uztipus,_tablanev,_bizonylat,_ENGEDMENYOK: string;
  _arfolyam,_ujarfolyam: real;
  _aktuzletszam: integer;


implementation

uses Unit35;

{$R *.dfm}

procedure TARFOLYAMELTERITES.FormActivate(Sender: TObject);
begin

  Top    := _top  + 120;
  Left   := _left + 140;
  Width  := 750;
  Height := 530;
  
//  _idszOke := IdoszakBeform.ShowModal;

  if _idszOke=1 then
    begin
      IdoszakPanel.Caption := _tolstring+' - '+_igstring;
      IdoszakPanel.repaint;
      StartTimer.enabled := true;
      Exit;
    end;
  Kilepotimer.enabled := True;
end;

// =============================================================================
         procedure TARFOLYAMELTERITES.STARTTIMERTimer(Sender: TObject);
// =============================================================================

begin
  StartTimer.Enabled := false;
  Kedvezdbase.close;
  Kedvezdbase.connected := True;
  if kedvezTranz.InTransaction then KedvezTranz.Commit;
  KedvezTranz.StartTransaction;
  Kedveztabla.Open;
  KedvezTabla.EmptyTable;
  KedvezTranz.Commit;
  KedvezTabla.Close;

  if kedveztranz.InTransaction then KedvezTranz.Commit;
  KedvezTranz.StartTransaction;

  _qq := 0;
  Csik.Max := _irodadarab;
  while _qq<_irodadarab-1 do
    begin
      Csik.Position := _qq;

      _uzlet := _irodaszam[_qq];
      irodaPanel.Caption := _irodaNev[_uzlet];
      IrodaPanel.repaint;

      _uzlet := _Irodaszam[_qq];
      _aktcegbetu := _cegbetutomb[_uzlet];
      _uztipus := _vtipus[_uzlet];
      _ertekTar := _korzet[_uzlet];
      _aktfdbPath := 'c:\receptor\database\v'+inttostr(_uzlet)+'.fdb';
      if not fileExists(_aktfdbPath) then
        begin
          inc(_qq);
          Continue;
        end;  


      _tablaNev := 'ARFE' + _farok;


      Arfedbase.Close;
      arfedbase.DatabaseName := _aktfdbPath;
      Arfedbase.Connected := true;

      ArfeTabla.Close;
      ArfeTabla.TableName := _tablanev;
      if not ArfeTabla.Exists then
        begin
          inc(_qq);
          Continue;
        end;
       _pcs := 'SELECT * FROM ' + _tablanev + _sorveg;

       if _ezegynap then
        _pcs := _pcs + 'WHERE (DATUM=' + chr(39) + _tolstring + chr(39)+')'
       else
        _pcs := _pcs + 'WHERE (DATUM BETWEEN '+chr(39)+_tolstring+chr(39)+' AND '+chr(39)+_igstring+chr(39)+')';

       _pcs := _pcs + 'ORDER BY DATUM';
       with ArfeQuery do
         begin
           Close;
           Sql.Clear;
           Sql.Add(_pcs);
           Open;
           First;
         end;

       if ArfeQuery.Recno=0 then
         begin
           ArfeQuery.close;
           inc(_qq);
           Continue;
         end;
       while not arfeQuery.eof do
         begin
           with ArfeQuery do
             begin
               _datum := FieldByName('DATUM').asString;
               _valutanem := FieldByName('VALUTANEM').asString;
               _arfolyam := FieldByName('ARFOLYAM').asFloat;
               _ujarfolyam := FieldByName('UJARFOLYAM').asFloat;
               _prosnev := FieldByName('PENZTAROSNEV').asString;
               _bizonylat := FieldByName('BIZONYLATSZAM').asString;
               _bankjegy := FieldByName('BANKJEGY').asInteger;
               _rateType := FieldByNAme('ENGEDMENYTIPUS').asInteger;
             end;
           _tipus := leftstr(_bizonylat,1);
           if _tipus = 'V' then _diff := trunc(_ujarfolyam - _arfolyam)
           else _diff := trunc(_arfolyam - _ujarfolyam);

           _engedmeny := trunc(_diff*_bankjegy/100);
           _engedmenyOk := '?';
           case _ratetype of
             10: _engedmenyOk := 'ÜGYFÉLKÁRTYA';
             12: _engedmenyOk := 'PÉNZTÁROSI SÁV';
             20: _engedmenyOk := 'SÁVOS KEDVEZMÉNY';
             31: _engedmenyOk := 'ÜGYVEZETÖI';
             32: _engedmenyOk := 'FÖÉRTÉKTÁROSI';
             33: _engedmenyOk := 'ÉRTÉKTÁROSI';
             34: _engedmenyOk := 'ÜGYVEZETÖI';
           end;

           _pcs := 'INSERT INTO ARFOLYAMELTERITES (IRODA,ERTEKTAR,CEGBETU,DATUM,VALUTANEM,ARFOLYAM,UJARFOLYAM,';
           _pcs := _pcs + 'PENZTAROSNEV,BIZONYLATSZAM,BANKJEGY,RATETYPE,ENGEDMENY,ENGEDMENYOK)'+_sorveg;
           _pcs := _pcs + 'VALUES (' + inttostr(_uzlet)+',';
           _pcs := _pcs + inttostr(_ertektar)+',';
           _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',';
           _pcs := _pcs + chr(39)+ _datum + chr(39) + ',';
           _pcs := _pcs + chr(39) + _valutanem + chr(39) + ',';
           _pcs := _pcs + Form1.VesszobolPont(Floattostr(_arfolyam))+',';
           _pcs := _pcs + Form1.VesszobolPont(FloatTostr(_ujarfolyam))+',';
           _pcs := _pcs + chr(39) + _prosnev + chr(39) + ',';
           _pcs := _pcs + chr(39) + _bizonylat + chr(39) + ',';
           _pcs := _pcs + inttostr(_bankjegy)+',';
           _pcs := _pcs + inttostr(_ratetype)+',';
           _pcs := _pcs + inttostr(_engedmeny)+',';
           _pcs := _pcs + chr(39)+_engedmenyOk + chr(39)+')';

           with KedvezQuery do
             begin
               Close;
               Sql.Clear;
               Sql.Add(_pcs);
               ExecSql;
             end;
           ArfeQuery.Next;
         end;
       ArfeQuery.Close;
       inc(_qq);
    end;
  KedvezTranz.Commit;

  while True do
    begin
      _aktUzletszam :=1;   // Getuzletszam.Showmodal;
      if _aktuzletszam<0 then
        begin
          _cbsors := abs(_aktuzletszam);
          dec(_cbSors);
          _displayfocim := 'EXCLUSIVE '+_subdir[_CBSORS]+' KFT ADATAI';
          _displayTipus := 4;
          // Kft display
          // -1=best, -2=pannon, -3=east
        end;

      _aktUzletszam := _aktuzletszam-3;
      if _aktuzletszam=-2 then break;
      if _aktuzletszam=-1 then
        begin
          _displayFocim := 'ÖSSZES KEDVEZMÉNY';
          _displaytipus := 1;
        end;
      if _aktuzletszam=0 then
        begin
          _displayTipus := 2;
          _displayFocim := _aktkorzetnev + ' régió adatai';

        end;
      if _aktuzletszam>0 then
        begin
          _displayFocim := _aktPenztarNev + ' pénztár adatai';
          _displayTipus := 3;
        end;
      KedvezmenyLista.ShowModal;
    end;
  Kilepotimer.Enabled := true;
end;


procedure TARFOLYAMELTERITES.BitBtn1Click(Sender: TObject);
begin
  KilepoTimer.Enabled := true;
end;

procedure TARFOLYAMELTERITES.KILEPOTIMERTimer(Sender: TObject);
begin
  Kilepotimer.Enabled := False;
  ModalResult := 1;
end;

end.
