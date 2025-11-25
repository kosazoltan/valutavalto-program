unit Unit33;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, unit1, ExtCtrls, IBDatabase, DB, IBCustomDataSet, IBTable,
  StdCtrls, Buttons, ComCtrls, Grids, DBGrids, IBQuery;

type
  TATLAGARFOLYAM = class(TForm)
    STARTTIMER: TTimer;
    FOCIMPANEL: TPanel;
    CSIK: TProgressBar;
    BitBtn1: TBitBtn;
    VALUTASOURCE: TDataSource;
    MERGESOURCE: TDataSource;
    ATLAGTABLA: TIBTable;
    ATLAGDBASE: TIBDatabase;
    ATLAGTRANZ: TIBTransaction;
    BLOKKQUERY: TIBQuery;
    BLOKKTABLA: TIBTable;
    BLOKKDBASE: TIBDatabase;
    BLOKKTRANZ: TIBTransaction;
    FUGGONY: TPanel;
    IRODAPANEL: TPanel;
    Label1: TLabel;
    KILEPOTIMER: TTimer;
    AtlagQuery: TIBQuery;
    Shape1: TShape;
    Shape2: TShape;
    Shape3: TShape;
    Shape4: TShape;

    procedure FormActivate(Sender: TObject);
    procedure Atlaglegyujtes;
//    procedure DisplayAtlagselect;
    procedure STARTTIMERTimer(Sender: TObject);
    procedure atlagSzamitas;
    procedure BitBtn1Click(Sender: TObject);
    procedure KILEPOTIMERTimer(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ATLAGARFOLYAM: TATLAGARFOLYAM;
  _idszOke,_aktUzletszam,_bankjegy,_ertek: integer;
  _vBjegy,_eBjegy,_vertek,_eertek,_vvAtlag,_veAtlag: array of array of integer;
  _evBjegy,_eeBjegy,_evErtek,_eeertek,_evAtlag,_eeAtlag: array of array of integer;
  _svbjegy,_sebjegy,_svertek,_seertek,_svAtlag,_seAtlag: array of integer;
  _vMarge,_eMarge: array of array of real;
  _sMarge: array of real;
  _voltAdat : boolean;
  _etss,_uzlet: integer;
  _eatlag,_marge,_vb,_ve,_ee,_eb: real;
  _vAtlag: real;

implementation

uses Unit36;

{$R *.dfm}

// =================================================================
         procedure TATLAGARFOLYAM.FormActivate(Sender: TObject);
// =================================================================

var _fc,_focim: string;

begin
  Top := _top + 120;
  Left := _left + 140;
  hEIGHT := 530;
  Width := 750;


  // BEÁLLITJA: _tolstring,_igstring,(=_datumtols,_datumigs),_ezegynap,_idoszakszuro(feltétel)
 // _idszOke := IdoszakBeform.ShowModal;

  if _idszOke=1 then
    begin
      _fc := 'ÁTLAGOS ÁRFOLYAM ';
      IF _ezEgynap then
          _focim := _fc + _tolstring + '-I NAPON'
      ELSE
         _focim := _fc + _tolstring + ' ÉS ' + _igstring + ' KÖZÖTTI IDÕSZAKBAN';

      FocimPanel.Caption := _focim;
      StartTimer.enabled := true;
      Exit;
    end;
  ModalResult := 1;
end;

// =============================================================================
           procedure TATLAGARFOLYAM.STARTTIMERTimer(Sender: TObject);
// =============================================================================

var i,j: integer;

begin
  startTimer.Enabled := false;

  setlength(_vBjegy,_irodadarab,_valutadarab);
  setlength(_eBjegy,_irodadarab,_valutadarab);
  setlength(_vErtek,_irodadarab,_valutadarab);
  setlength(_eertek,_irodadarab,_valutadarab);
  Setlength(_vvatlag,_irodaDarab,_valutaDarab);
  SetLength(_veAtlag,_irodaDarab,_valutaDarab);
  SetLength(_vMarge,_irodaDarab,_valutaDarab);

  Setlength(_evBjegy,_ertektardarab,_valutadarab);
  Setlength(_eeBjegy,_ertektardarab,_valutadarab);
  Setlength(_evErtek,_ertektardarab,_valutadarab);
  Setlength(_eeertek,_ertektardarab,_valutadarab);
  Setlength(_evAtlag,_ertektarDarab,_valutaDarab);
  SetLength(_eeAtlag,_ertekTarDarab,_valutaDarab);
  Setlength(_emarge,_ertekTarDarab,_valutaDarab);

  Setlength(_svbjegy,_valutadarab);
  Setlength(_sebjegy,_valutadarab);
  Setlength(_svertek,_valutadarab);
  Setlength(_seertek,_valutadarab);
  Setlength(_svAtlag,_valutaDarab);
  setlength(_seatlag,_valutaDarab);
  Setlength(_sMarge,_valutaDarab);

  for i := 0 to _irodadarab-1 do
    begin
      for j := 0 to _valutadarab-1 do
        begin
          _vbjegy[i,j] := 0;
          _eBjegy[i,j] := 0;
          _vErtek[i,j] := 0;
          _eErtek[i,j] := 0;
          _vvatlag[i,j] := 0;
          _veatlag[i,j] := 0;
          _vMarge[i,j] := 0;
        end;
    end;

  for i := 0 to _ertektardarab-1 do
    begin
      for j := 0 to _valutadarab-1 do
        begin
          _evbjegy[i,j] := 0;
          _eeBjegy[i,j] := 0;
          _evErtek[i,j] := 0;
          _eeErtek[i,j] := 0;
          _evAtlag[i,j] := 0;
          _eeAtlag[i,j] := 0;
          _eMarge[i,j] := 0;
        end;
    end;

  for j := 0 to _valutadarab-1 do
    begin
      _svBjegy[j] := 0;
      _seBjegy[j] := 0;
      _svertek[j] := 0;
      _seertek[j] := 0;
    end;

  _voltadat := False;
  AtlagLegyujtes;

  if not _voltAdat then
    begin
      ShowMessage('NEM VOLT AZ IDÖSZAK ALATT FORGALOM');
      Exit;
    end;

  // -----------------------------------------------------

//  AtlagBeirasa;

  AtlagSzamitas;

  // -----------------------------------------------------

  Atlagdisplay.Showmodal;
  KilepoTimer.Enabled := True;
end;



// =======================================================
         procedure Tatlagarfolyam.Atlaglegyujtes;
// =======================================================

var _qq,_ptarszam,_valSS: integer;
    _uzTipus,_fejTablaNev,_tetTablaNev: string;

begin
  _qq := 0;
  Csik.Max := _irodaDarab;
  Csik.Position := 0;
  while _qq<_irodadarab do
    begin
      Csik.Position := _qq;

      _uzlet := _irodaszam[_qq];
      irodaPanel.Caption := _irodaNev[_uzlet];
      IrodaPanel.repaint;

      _uzlet := _Irodaszam[_qq];
      _uztipus := _vtipus[_uzlet];
      _ertekTar := _korzet[_uzlet];
      _aktfdbPath := 'c:\receptor\database\v'+inttostr(_uzlet)+'.fdb';

      if not fileexists(_aktfdbPath) then
        begin
          inc(_qq);
          Continue;
        end;  

      _fejtablanev := 'BF'+_FAROK;
      _tetTablaNev := 'BT'+_FAROK;

      _pcs := 'SELECT FEJ.*, TET.*' + _sorveg;
      _pcs := _pcs +'FROM '+_fejtablanev+' FEJ JOIN '+_tettablanev+' TET'+_sorveg;
      _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM'+_sorveg;

      if _ezegynap then
        _pcs := _pcs + 'WHERE (FEJ.DATUM=' + chr(39) + _tolstring + chr(39)+')'
      else
        _pcs := _pcs + 'WHERE (FEJ.DATUM BETWEEN '+chr(39)+_tolstring+chr(39)+' AND '+chr(39)+_igstring+chr(39)+')';

      _pcs := _pcs + ' AND ((FEJ.STORNO=1) OR (FEJ.STORNO IS NULL))';

      BlokkTabla.close;
      BlokkDbase.close;
      BlokkDbase.DatabaseName := _aktfdbPath;
      BlokkDbase.Connected  := true;
      if blokkTranz.InTransaction then blokktranz.Commit;
      Blokktabla.TableName := _fejtablanev;
      if not Blokktabla.exists then
        begin
          inc(_qq);
          Continue;
        end;

      with BlokkQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          Last;
        end;

      _cc := BlokkQuery.Recno;
      if _cc=0 then
        begin
          BlokkQuery.Close;
          inc(_qq);
          Continue;
        end;

    //  Csik.Max := _cc;
      BlokkQuery.First;
      while not BlokkQuery.eof do
        begin
          with BlokkQuery do
            begin
              _penztar := FieldByName('PENZTAR').asString;
              _tipus := FieldByName('TIPUS').asString;
              _valutanem := FieldByName('VALUTANEM').asstring;
              _bankjegy := FieldbyName('BANKJEGY').asInteger;
              _ertek := FieldByName('FORINTERTEK').asInteger;
              _elojel := FieldByName('ELOJEL').asString;
            end;

          _penztar := trim(_penztar);
          if (_tipus='F') OR (_tipus='U') then
            begin
            //  _bq := Form1.BankScan(_penztar);
            //  if _bq=0 then
            //    begin
                  Blokkquery.Next;
                  Continue;
            //    end;
            end;

          if _valutanem = 'HUF' then
            begin
              BlokkQuery.Next;
              Continue;
            end;

          _VALSS := 1;  
//          _etss := Form1.ErtTarScan(_ertekTar);
//          _valss := Form1.DnemScan(_valutanem);
          _voltadat := True;

          if (_tipus='V') or ((_tipus='K') and (_elojel='+')) then
            begin
              // A váltó vétele:
              _vbjegy[_qq,_valss] := _vbjegy[_qq,_valss] + _bankjegy;
              _vErtek[_qq,_valss] := _vErtek[_qq,_valss] + _ertek;

              // Az értéktár vétele:
              _evbjegy[_etss,_valss] := _evbjegy[_etss,_valss] + _bankjegy;
              _evertek[_etss,_valss] := _evertek[_etss,_valss] + _ertek;

              // Exclusive best change vétele:
              _svbjegy[_valss] := _svbjegy[_valss] + _bankjegy;
              _svertek[_valss] := _svertek[_valss] + _ertek;
            end;

          if (_tipus='E') or ((_tipus='K') and (_elojel='-')) then
            begin
              // A váltó eladása:
              _ebjegy[_qq,_valss] := _eBjegy[_qq,_valss] + _bankjegy;
              _eErtek[_qq,_valss] := _eErtek[_qq,_valss] + _ertek;

              // Az értéktár eladása:
              _eebjegy[_etss,_valss] := _eebjegy[_etss,_valss] + _bankjegy;
              _eeertek[_etss,_valss] := _eeertek[_etss,_valss] + _ertek;

              // Az Exclusive Best Change eladása:
              _sebjegy[_valss] := _sebjegy[_valss] + _bankjegy;
              _seertek[_valss] := _seertek[_valss] + _ertek;
            end;
          BlokkQuery.Next;
        end;
      BlokkQuery.Close;
      inc(_qq);
    end;
end;



// ===================================================
        procedure TAtlagarfolyam.Atlagszamitas;
// ===================================================

var _imarge,_diff: integer;
    i,j,_aktiroda: integer;
    _va,_ea: real;

begin
  // Exlusive change átlagszámitás:

  for j := 0 to _valutaDarab-1 do
    begin
      _vb := _svBjegy[j];
      _eb := _sebjegy[j];
      _ve := _svertek[j];
      _eE := _seErtek[j];

      _va := 0;
      _ea := 0;

      if _vb>0 then _va := int(100*_ve/_vb);
      if _eb>0 then _ea := int(100*_ee/_eb);

      _svAtlag[j] := trunc(_va);
      _seAtlag[j] := trunc(_ea);

      if _va>0 then
        begin
          _diff := trunc(_ea)-trunc(_va);
          _imarge := trunc(10000*_diff/_va);
          _marge := _iMarge/10000;
          _sMarge[j] := _marge;
        end;
    end;


  // Értéktárak átkagszámitása:

  for i := 0 to _ertekTarDarab-1 do
    begin

      for j := 0 to _valutadarab-1 do
        begin
          _vb := _evBjegy[i,j];
          _eb := _eebjegy[i,j];
          _ve := _evertek[i,j];
          _eE := _eeErtek[i,j];

          _va := 0;
          _ea := 0;

          if _vb>0 then _va := int(100*_ve/_vb);
          if _eb>0 then _ea := int(100*_ee/_eb);

          _evAtlag[i,j] := trunc(_va);
          _eeAtlag[i,j] := trunc(_ea);

          if _va>0 then
            begin
              _diff := trunc(_ea)-trunc(_va);
              _imarge := trunc(10000*_diff/_va);
              _marge := _iMarge/10000;
             _eMarge[i,j] := _marge;
            end;
        end;
    end;

  // Váltók átlagszámítása:

  for i := 0 to _irodaDarab-1 do
    begin
      for j := 0 to _valutaDarab-1 do
        begin
          _vB := _vBjegy[i,j];
          _vE := _vErtek[i,j];
          _eB := _eBjegy[i,j];
          _eE := _eErtek[i,j];

          _va := 0;
          _ea := 0;

          if _vb>0 then _va := int(100*_ve/_vb);
          if _eb>0 then _ea := int(100*_ee/_eb);

          _vvAtlag[i,j] := trunc(_va);
          _veAtlag[i,j] := trunc(_ea);
          if _va>0 then
            begin
              _diff := trunc(_ea)-trunc(_va);
              _imarge := trunc(10000*_diff/_va);
              _marge := _iMarge/10000;
              _vMarge[i,j] := _marge;
            end;
        end;
    end;

  // ----------------- Itt kész az átlagszámitás -----------------------------
  //
  // _svatlag[valutasorszam] = Best Change vétel átlag valutánként
  // _seAtlag[valutasorszam] = Best Change eladás átlag valutánként;

  // _evAtlag[értéktársorszám,valutasorszám] = értéktárak átlagvételei
  // _eeAtlag[értéktársorszám,valutasorszám] = értéktárak átlageladásai

  // _vvAtlag[irodasorszam,valutasorszám] = váltók átlagvételei
  // _veAtlag[irodasorszám,valutasorszám] = váltók átlag eladásai


  Atlagdbase.close;
  AtlagDbase.connected := True;
  if atlagtranz.InTransaction then atlagtranz.Commit;

  // ---------------------- Atlagarfolyamtabla üritése ---------------------

  AtlagTranz.StartTransaction;
  _pcs := 'DELETE FROM ATLAGARFOLYAM';

  with AtlagQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;

  // -------- Best Change Atlagarfolyamok felirasa --------------------------

  if Atlagtranz.InTransaction then atlagTranz.Commit;
  Atlagtranz.StartTransaction;

  for i := 0 to _valutaDarab-1 do
    begin
       _pcs := 'INSERT INTO ATLAGARFOLYAM (IRODA,ERTEKTAR,MEGNEVEZES,';
       _pcs := _pcs + 'VALUTANEM,VETELBANKJEGY,VETELERTEK,';
       _pcs := _pcs + 'ELADBANKJEGY,ELADERTEK,VETELATLAG,ELADATLAG,';
       _pcs := _pcs + 'VALUTANEV,MARGE)' + _sorveg;

       _pcs := _pcs + 'VALUES (0,0,' + chr(39)+ 'Exclusive Change összesen'+ chr(39)+',';
       _pcs := _pcs + chr(39)+ _dnem[i] + chr(39) + ',';
       _pcs := _pcs + inttostr(_svBjegy[i])+',';
       _pcs := _pcs + inttostr(_svErtek[i])+',';
       _pcs := _pcs + inttostr(_seBjegy[i])+',';
       _pcs := _pcs + inttostr(_seErtek[i])+',';
       _pcs := _pcs + inttostr(_svAtlag[i])+',';
       _pcs := _pcs + inttostr(_seAtlag[i])+',';
       _pcs := _pcs + chr(39) + trim(_dnev[i]) + chr(39) +',';
       _pcs := _pcs + Form1.VesszobolPont(FloatToStr(_sMarge[i]))+')';

       with AtlagQuery do
         begin
           Close;
           Sql.Clear;
           Sql.Add(_pcs);
           ExecSql;
         end;
    end;

  // -------------- Átlag felirása az értktárakba ------------------------

  for i := 0 to _ertekTarDarab-1 do
    begin
      for j := 0 to _valutaDarab-1 do
        begin
          _pcs := 'INSERT INTO ATLAGARFOLYAM (IRODA,ERTEKTAR,MEGNEVEZES,';
          _pcs := _pcs + 'VALUTANEM,VETELBANKJEGY,VETELERTEK,';
          _pcs := _pcs + 'ELADBANKJEGY,ELADERTEK,VETELATLAG,ELADATLAG,';
          _pcs := _pcs + 'VALUTANEV,MARGE)' + _sorveg;

          _pcs := _pcs + 'VALUES (0,'+ inttostr(_korzetszam[i]) + ',';
          _pcs := _pcs + chr(39) + _korzetnev[i]+' KÖRZET' + chr(39) + ',';
          _pcs := _pcs + chr(39) + _dnem[j] + chr(39) + ',';

          _pcs := _pcs + inttostr(_evBjegy[i,j]) + ',';
          _pcs := _pcs + inttostr(_evErtek[i,j]) + ',';
          _pcs := _pcs + inttostr(_eeBjegy[i,j]) + ',';
          _pcs := _pcs + inttostr(_eeErtek[i,j]) + ',';
          _pcs := _pcs + inttostr(_evAtlag[i,j]) + ',';
          _pcs := _pcs + inttostr(_eeAtlag[i,j]) + ',';
          _pcs := _pcs + chr(39) + trim(_dnev[j]) + chr(39) + ',';
          _pcs := _pcs + Form1.VesszobolPont(FloatTostr(_eMarge[i,j]))+')';

          with AtlagQuery do
            begin
              Close;
              Sql.Clear;
              Sql.Add(_pcs);
              ExecSql;
            end;
        end;
    end;

  // ------------------ Váltók átlagárfolyamok felirása  ----------------------

   for i := 0 to _irodaDarab-1 do
     begin
       for j := 0 to _valutaDarab-1 do
         begin
           _aktiroda := _irodaszam[i];
           _aktertektar := _korzet[_aktiroda];

           _pcs := 'INSERT INTO ATLAGARFOLYAM (IRODA,ERTEKTAR,MEGNEVEZES,';
           _pcs := _pcs + 'VALUTANEM,VETELBANKJEGY,VETELERTEK,';
           _pcs := _pcs + 'ELADBANKJEGY,ELADERTEK,VETELATLAG,ELADATLAG,';
           _pcs := _pcs + 'VALUTANEV,MARGE)' + _sorveg;

           _pcs := _pcs + 'VALUES ('+ inttostr(_aktiroda) + ',';
           _pcs := _pcs + inttostr(_aktertektar) + ',';
           _pcs := _pcs + chr(39) + _irodaNev[_aktIroda] + chr(39) + ',';
           _pcs := _pcs + chr(39) + _dnem[j] + chr(39) + ',';

           _pcs := _pcs + inttostr(_vBjegy[i,j]) + ',';
           _pcs := _pcs + inttostr(_vErtek[i,j]) + ',';
           _pcs := _pcs + inttostr(_eBjegy[i,j]) + ',';
           _pcs := _pcs + inttostr(_eErtek[i,j]) + ',';
           _pcs := _pcs + inttostr(_vvAtlag[i,j]) + ',';
           _pcs := _pcs + inttostr(_veAtlag[i,j]) + ',';
           _pcs := _pcs + chr(39) + trim(_dnev[j]) + chr(39) + ',';
           _pcs := _pcs + Form1.VesszobolPont(FloatTostr(_vMarge[i,j]))+')';

           with AtlagQuery do
             begin
               Close;
               Sql.Clear;
               Sql.Add(_pcs);
               ExecSql;
             end;
         end;
     end;

  AtlagTranz.Commit;
end;

procedure TATLAGARFOLYAM.BitBtn1Click(Sender: TObject);
begin
  KilepoTimer.Enabled := True;
end;

procedure TATLAGARFOLYAM.KILEPOTIMERTimer(Sender: TObject);
begin
  KilepoTimer.Enabled := False;
  AtlagTabla.Close;
  ModalResult := 1;
end;

end.
