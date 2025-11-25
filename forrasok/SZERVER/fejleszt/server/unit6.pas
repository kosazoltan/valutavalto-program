unit Unit6;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, unit1, ExtCtrls, Grids, DBGrids, ComCtrls, StdCtrls, IBDatabase,
  DB, IBCustomDataSet, IBQuery, StrUtils, IBTable;

type
  TMNBLISTAK = class(TForm)
    mnbstarttimer: TTimer;
    mnbquery: TIBQuery;
    mnbdbase: TIBDatabase;
    mnbtranz: TIBTransaction;
    Label2: TLabel;
    Shape1: TShape;


    procedure FormActivate(Sender: TObject);
    procedure mnbstarttimerTimer(Sender: TObject);
    procedure MakeExcelCsv;
    procedure KftDisplay(_kftss: integer);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MNBLISTAK: TMNBLISTAK;
  _IRAS: TEXTFILE;
  _kornev,_csvPath,_mondat,_status: string;
  _irsz: integer;
  _bankiatadas,_ptarikiadas,_ptariatvet: integer;
  _vplusz,_vminusz,_vetelforg,_eladforg,_forgegy,_bankegy: integer;
  _osszbevet,_sumatvet,_osszkiadas: integer;

implementation

uses Unit9, Unit14, Unit17, Unit18;

{$R *.dfm}

// ======================================================================
          procedure TMNBLISTAK.FormActivate(Sender: TObject);
// ======================================================================

begin
  Top := _top + 120;
  Left := _left +140;
  Height := 530;
  Width := 750;

  MnbStartTimer.Enabled := TRue;
end;

// ============================================================
    procedure TMNBLISTAK.mnbstarttimerTimer(Sender: TObject);
// ============================================================

var _vanIdoszak,_mnbOke,_aktuzletszam,_aktuz: integer;

begin
  MNBStartTimer.Enabled := False;

 _vanidoszak := IdoszakBeForm.showModal;
  if _vanidoszak<>1 then
    begin
      ModalResult := 2;
      exit;
    end;

 // FOPANEL.Visible := True;

  _MNBOKE := MNBLegyujto.ShowModal;
  if _mnbOke<>1 then
    begin
      ShowMessage('NINCS ADAT A KÉRT IDÕSZAKBAN !');
      ModalResult := 2;
      Exit;
    end;

  _kellExcel := true;
  while True do
    begin
      _aktUzletszam := Getuzletszam.Showmodal;
      if _aktuzletszam<0 then
        begin
          // KFT-k adatai;
          _aktuz := abs(_aktuzletszam);
          KftDisplay(_aktuz);
          Continue;
        end;

      _aktuzletszam := _aktuzletszam-3;
      if _aktuzletszam=-2 then break;
      if _aktuzletszam=-1 then
        begin
          _displayFocim := 'EXCLUSIVE CHANGE ÖSSZESÍTETT ADATAI';
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
      MnbListaDisplay.ShowModal;
    end;
  ModalResult := 1;
end;

// =============================================
       procedure TMNBListak.MakeExcelCsv;
// =============================================

begin
  MnBDbase.Close;
  MNBdbase.connected := True;
  if MNBTranz.intransaction then MNBtranz.Commit;

  _pcs := 'SELECT * FROM MNB'+_sorveg;
  _pcs := _pcs + 'WHERE ERTEKTAR=0 AND IRODASZAM=0'+_sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  with MNBQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  _csvPath := 'C:\RECEPTOR\MAIL\POSTA\MNB.CSV';
  if FileExists(_csvPath) then DeleteFile(_csvPath);

  AssignFile(_iras,_csvPath);
  Rewrite(_iras);
  _mondat := 'FORGALMI STATISZTIKA '+_tolstring +' ÉS ';
  _mondat := _mondat + _igstring+ ' KÖZÖTT';
  _mondat := _mondat + dupestring(';',18);
  WriteLn(_iras,_mondat);

  _mondat := 'PÉNZTÁRIEGYSÉG;VALUTA;NYITÓ KÉSZLET;VALUTA VÉTEL;TÖBBLET;';
  _mondat := _mondat + 'BANKKÁRTYA;PÉNZTÁRI ÁTVÉTEL;BANKI ÁTVÉTEL;';
  _mondat := _mondat + 'VALUTA ELADÁS;HIÁNY;PÉNZTÁRI ÁTADÁS;';
  _mondat := _mondat + 'BANKI ÁTADÁS;ZÁRÓ KÉSZLET;';
  _mondat := _mondat + 'VISSZAPÓTLÁS (+);VISSZAPÓTLÁS (-)';
  WriteLn(_iras,_mondat);

  while not MNBQuery.eof do
    begin
      with MNBQuery do
        begin
          _irsz := FieldByName('IRODASZAM').asInteger;
          _ertektar := FieldByName('ERTEKTAR').asInteger;
          _valutanem := FieldByName('VALUTANEM').asString;
          _nyito := FieldByname('NYITO').asInteger;
          _vetel := FieldByName('VETEL').asInteger;
          _eladas := FieldByName('ELADAS').asInteger;
          _bankkartya := FieldByName('BANKKARTYA').asInteger;
          _hiany := FieldByName('HIANY').asInteger;
          _tobblet := FieldByName('TOBBLET').asInteger;
          _bankiatvet := FieldByname('BANKIATVETEL').asInteger;
          _bankiatadas := FieldByName('BANKIATADAS').asInteger;
          _ptarikiadas := FieldByname('PENZTARIKIADAS').asInteger;
          _ptariatvet := FieldByName('PENZTARIATVETEL').asInteger;
          _zaro := FieldByName('ZARO').asInteger;
          _vplusz := FieldByName('VISSZAPLUSZ').asInteger;
          _vminusz := FieldByName('VISSZAMINUSZ').asInteger;
          _status := FieldByName('MEGJEGYZES').asString;
        end;
      _vetelforg := _vetel+_tobblet;
      _eladforg := _eladas+_hiany;
      _forgegy := _vetelforg-_eladforg;

      _bankegy := _bankiatvet-_bankiatadas;
      _osszbevet := _sumatvet + _bankiatvet + _ptariatvet;
      _osszkiadas := _eladforg + _bankiatadas + _ptarikiadas;

      if (_nyito=0) and (_forgegy=0) and (_bankegy=0) and (_zaro=0) then
        begin
          MNBquery.Next;
          Continue;
        end;

      if _irsz>0 then
        begin
          _kornev := _irodanev[_irsz];
        end else
        begin
          if _ertekTar=0 then
            begin
              _kornev := 'Exclusive Change Kft.';
            end else
            begin
              _etss := Form1.ertTarScan(_ertektar);
              _korNev := _korzetnev[_etss];
            end;
        end;

      write(_iras,_kornev+';');
      write(_iras,_valutanem+';');
      write(_iras,floattostr(_nyito)+';');
      write(_iras,floattostr(_vetel)+';');
      write(_iras,floattostr(_tobblet)+';');
      write(_iras,floattostr(_bankkartya)+';');
      write(_iras,floattostr(_ptariatvet)+';');
      write(_iras,floattostr(_bankiatvet)+';');
      write(_iras,floattostr(_eladas)+';');
      write(_iras,floattostr(_hiany)+';');
      write(_iras,floattostr(_ptarikiadas)+';');
      write(_iras,floattostr(_bankiatadas)+';');
      write(_iras,floattostr(_zaro)+';');
      write(_iras,floattostr(_vPlusz)+';');
      writeLn(_iras,floattostr(_vMinusz));
      MNBQuery.Next;
    end;
  MnbQuery.Close;
  CloseFile(_iras);
  ShowMessage('A FORGALMI STATISZTIKÁT KITETTEM A POSTÁBA');
END;


procedure TMNBListak.KftDisplay(_kftss: integer);

begin
  case _kftss of
    1: begin
          _displayFocim := 'BEST CHANGE ÖSSZESÍTETT ADATAI';
          _displaytipus := 4;
       end;

    2: begin
         _displayFocim := 'PANNON CHANGE ÖSSZESÍTETT ADATAI';
         _displayTipus := 5;
       end;

    3: begin
         _displayFocim := 'EAST CHANGE ÖSSZESÍTETT ADATAI';
         _displayTipus := 6;
       end;
  end;
  MnbListaDisplay.ShowModal;
end;

end.




