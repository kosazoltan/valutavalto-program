unit Unit14;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, ComCtrls, DB, DBTables,StrUtils, StdCtrls, Buttons,
  IBDatabase, IBCustomDataSet, IBTable, IBQuery;

type
  TMNBLEGYUJTO = class(TForm)
    mnbcsik: TProgressBar;
    TOLIGPANEL: TPanel;
    INFOPANEL: TPanel;
    LETOLTESINDITO: TTimer;
    FCSIK: TProgressBar;
    uzletpanel: TPanel;
    MNBTABLA: TIBTable;
    MNBDBASE: TIBDatabase;
    MNBTRANZ: TIBTransaction;
    MNBTEMPTABLA: TIBTable;
    MNBTEMPDBASE: TIBDatabase;
    MNBTEMPTRANZ: TIBTransaction;
    BLOKKFEJTABLA: TIBTable;
    BLOKKFEJDBASE: TIBDatabase;
    BLOKKFEJTRANZ: TIBTransaction;
    BLOKKTETELTABLA: TIBTable;
    BLOKKTETELDBASE: TIBDatabase;
    BLOKKTETELTRANZ: TIBTransaction;
    CIMTARTABLA: TIBTable;
    CIMTARDBASE: TIBDatabase;
    CIMTARTRANZ: TIBTransaction;
    BLOKKQUERY: TIBQuery;
    MNBQUERY: TIBQuery;
    CIMTARQUERY: TIBQuery;
    Shape1: TShape;

    procedure FormActivate(Sender: TObject);
    procedure LetoltesInditoTimer(Sender: TObject);
    procedure ForgalomGyujtes;
 //   procedure UthonapNyitoBetolt;
 //   procedure UthonapZaroBetolt;
    procedure MNBDataread;
    procedure MNBStart;
    procedure setcounter;
    procedure TombokRekordbaIrasa;
    procedure Ertektarsumma(_et:integer; _vj:integer);
    procedure Keszletbetolto(_nyzTipus: string);
    procedure MulthaviUtolso(_nyz: string);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MNBLEGYUJTO: TMNBLEGYUJTO;

  _mVet,_mElad,_mHiany,_mTobblet,_mvisszp,_mvisszm: array[1..130,1..28] of integer;
  _mbankbol,_mbankba,_mptarba,_mptarbol,_mbankkartya: array[1..130,1..28] of integer;
  _mvdb,_medb,_mnyito,_mzaro,_mvanadat: array[1..130,1..28] of integer;

  _enyito,_ezaro,_evetel,_eeladas,_etobblet,_ehiany: array[1..9,1..28] of integer;
  _evisszap,_evisszam,_ebankba,_ebankbol,_eptarba,_eptarbol: array[1..9,1..28] of integer;
  _evdarab,_eedarab,_eBankkartya: array[1..9,1..28] of integer;

  _kftnyito,_kftzaro,_kftvetel,_kfteladas,_kfttobblet,_kfthiany: array[1..2,1..28] of integer;
  _kftvisszap,_kftvisszam,_kftbankba,_kftbankbol,_kftptarba,_kftptarbol: array[1..2,1..28] of integer;
  _kftvdarab,_kftedarab,_kftbankkartya: array[1..2,1..28] of integer;

  _snyito,_szaro,_svetel,_seladas,_stobblet,_shiany: array[1..28] of integer;
  _svisszap,_svisszam,_sbankba,_sbankbol,_sbankartya: array[1..28] of integer;
  _sptarba,_sptarbol,_sbankkartya,_svdarab,_sedarab: array[1..28] of integer;

  _fejTablaNev,_tetTablanev,_cimtarTablaNev,_elotablanev,_elocimtar,_elopath: string;
  _fPath,_cimtar,_regiBlokk,_stBlokk,_tBlokkNum,_datum,_megj,_utbiz,_bizonylat: string;

  _aktKorzet,_aktptar,_etss,_mnbDb,_mnbtempdb,_kerekites,_ii,_jj,_ee: integer;
  _vDarab,_eDarab,_valss,_ftss,_irqq,_fizetoeszkoz,_osszkeszlet,_tolev,_tolho: integer;
  _visszap,_visszam,_bankba,_bankbol,_ptarba,_ptarbol,_bankkartya: integer;

  _voltadat: boolean;

  _cegbetuk : array[1..2] of string = ('B','Z');
  _korzetbetu: string;

implementation

uses Unit1, Unit6;

{$R *.dfm}


// ===================================================================
        procedure TMNBLEGYUJTO.FormActivate(Sender: TObject);
// ===================================================================

  // Forgalmi adatokat gyüjt le datumtols - datumigs

begin
  Top := _top + 330;
  Left := _left + 230;
  Width := 585;
  _MNBDb := 0;
  _MNBTempdb := 0;
  LetoltesIndito.Enabled := true;
end;

// =================================================================
     procedure TMNBLEGYUJTO.LETOLTESINDITOTimer(Sender: TObject);
// =================================================================


var _tCim,_tcim2: string;
    i,j: integer;

begin
  LetoltesIndito.Enabled := False;
  UzletPanel.Caption := '';
  _voltAdat := False;

  // Információk kiirása vagy idöszaki, vagy csak a tegnapi ellenörzés:

  _ezegynap := False;
  if _eztegnap then
    begin
      _eztegnap := False;
      _tcim := 'A TEGNAP BEÉRKEZETT ADATOK';
      _tcim2 := 'ELLENÖRZÉSE';
      _ezegynap := True;
    end else
    begin
      _tCim := inttostr(_kertev)+' '+_honapnev[_kertho]+' '+_Datumtols+' - '+_datumigs;
      _tcim2 := 'KÖZÖTTI ADATOK LETÖLTÉSE';
    end;

  Toligpanel.Caption := _tCim;
  ToligPanel.Repaint;
  InfoPanel.Caption := _tcim2;
  InfoPanel.Repaint;

  // --------- MNB-tábla KIÜRITÉSE --------------------------

  _farok := midstr(_datumtols,3,2)+midstr(_datumtols,6,2);
  _tolev := strtoint(leftstr(_datumtols,4));
  _tolho := strtoint(midstr(_datumtols,6,2));

  // ----------------------------------------------------------------

  _eloev := _tolev;
  _eloho := _tolho-1;
  if _eloho=0 then
    begin
      _eloho := 12;
      dec(_eloev);
    end;

  _elofarok := Form1.Nulele(_eloev-2000)+Form1.Nulele(_eloho);

  // ----------------------------------------------------------------

  MNBtabla.IndexFieldNames := '';
  MNBStart;
  MNBTabla.EmptyTable;
  MNBTranz.Commit;

  // ---------------------------------------------------

  for i := 1 to _irodaDarab do
    begin
      for j := 1 to _valutadarab do
        begin
          _mvet[i,j]        := 0;
          _melad[i,j]       := 0;
          _mHiany[i,j]      := 0;
          _mTobblet[i,j]    := 0;
          _mVisszp[i,j]     := 0;
          _mVisszm[i,j]     := 0;
          _mBankbol[i,j]    := 0;
          _mBankba[i,j]     := 0;
          _mptarBa[i,j]     := 0;
          _mptarbol[i,j]    := 0;
          _mnyito[i,j]      := 0;
          _mzaro[i,j]       := 0;
          _mvdb[i,j]        := 0;
          _medb[i,j]        := 0;
          _mvanadat[i,j]    := 0;
          _mBankkartya[i,j] := 0;
        end;
    end;

  for i := 0 to _valutadarab-1 do
    begin
      _sNyito[i] := 0;
      _sZaro[i] := 0;
      _svetel[i] := 0;
      _seladas[i] := 0;
      _stobblet[i] := 0;
      _shiany[i] := 0;
      _svisszap[i] := 0;
      _svisszam[i] := 0;
      _sbankba[i] := 0;
      _sbankbol[i] := 0;
      _sptarba[i] := 0;
      _sptarbol[i] := 0;
      _svdarab[i] := 0;
      _sedarab[i] := 0;
      _sBankkartya[i] := 0;

      for j := 0 to _ertektardarab-1 do
        begin
           _eNyito[j,i] := 0;
           _eZaro[j,i] := 0;
           _evetel[j,i] := 0;
           _eeladas[j,i] := 0;
           _etobblet[j,i] := 0;
           _ehiany[j,i] := 0;
           _evisszap[j,i] := 0;
           _evisszam[j,i] := 0;
           _ebankba[j,i] := 0;
           _ebankbol[j,i] := 0;
           _eptarba[j,i] := 0;
           _eptarbol[j,i] := 0;
           _evdarab[j,i] := 0;
           _eedarab[j,i] := 0;
           _eBankkartya[j,i] := 0;
        end;

      for j := 0 to 1 do
        begin
           _kftNyito[j,i] := 0;
           _kftZaro[j,i] := 0;
           _kftvetel[j,i] := 0;
           _kfteladas[j,i] := 0;
           _kfttobblet[j,i] := 0;
           _kfthiany[j,i] := 0;
           _kftvisszap[j,i] := 0;
           _kftvisszam[j,i] := 0;
           _kftbankba[j,i] := 0;
           _kftbankbol[j,i] := 0;
           _kftptarba[j,i] := 0;
           _kftptarbol[j,i] := 0;
           _kftvdarab[j,i] := 0;
           _kftedarab[j,i] := 0;
           _kftBankkartya[j,i] := 0;
        end;
    end;

  _ftss := Form1.DnemScan('HUF');

  // ---------------------------------------------------------------

  MnbcSIK.Max     := _IrodaDarab;
  MnbCsik.Visible := True;

// ----------Ciklus indul az összes váltópénztáron keresztül ----------------

  _irqq := 0;
  while _irqq<_IrodaDarab do
    begin
      MNBcsik.Position := _irqq;
      MNBLegyujto.Repaint;

      // Az aktuális pénztárszám = qq.-ik pénztár száma
      _aktPt := _IrodaSzam[_irqq];


      // Az aktuális pénztár neve és körzetszáma:
      _aktpenztarnev := _irodaNev[_aktPt];
      _aktkorzet := _korzet[_aktpt];

      // Kiirja
      UzletPanel.Caption := inttostr(_aktpt)+' -> '+_aktpenztarnev;
      UzletPanel.Repaint;

      // Az fdb path a pénztárszámtól függ:
      _aktfdbPath := 'C:\RECEPTOR\DATABASE\V'+inttostr(_aktpt)+'.FDB';
      if not FileExists(_aktFdbPath) then
        begin
          inc(_irqq);
          Continue;
        end;


      // A három valutaváltó forgalmi-és készlet adatbázisai:
      _FejtablaNev := 'BF'+ _farok;
      _TetTablaNev := 'BT' + _farok;
      _cimtarTablanev := 'CIMT' + _farok;

      // A datumtols nap elötti utolsó cimleteinek betöltése a MNB táblába
      // NyitoBeToltes;
      Keszletbetolto('NYITO');

      // A zárókészletek betöltése az MNB táblába
      // ZaroBetoltes;
      KeszletBetolto('ZARO');

      BlokkFejtabla.close;
      BlokkfejDbase.COnnected := False;
      BlokkfejDbase.DatabaseName := _aktFdbPath;
      BlokkfejDbase.Connected := True;
      BlokkfejTabla.TableName := _fejTablaNev;

      if BlokkfejTabla.Exists then ForgalomGyujtes;
      inc(_irqq);
    end;

  _voltAdat := False;
  TombokRekordbaIrasa;

// --------- Itt az összes váltóüzlet forgalma le van töltve  -----------------

  //  Ha nem volt adat, akkor nincs mit tenni:

  if not _voltAdat then
    begin
      ModalResult := 2;
      Exit;
    end;

// ====================== ITT KEZDJÜK AZ ÖSSZESITÉST ==========================

 // if _kellCtrl=0 then AdatOsszesites;

  MNBCsik.Position := 2;

  UzletPanel.Caption := 'BEOLVASOTT ADATOK ELLENÖRZÉSE';
  UzletPanel.Repaint;

  MNBStart;
  fCSIK.Position := 0;

  Mnbtabla.Last;
  Fcsik.Max := MNBTabla.Recno;
  Fcsik.Repaint;
  _cc := 0;

  mnbTabla.First;
  while not MNBTabla.Eof do
    begin
      Fcsik.Position := _cc;
      inc (_cc);

       MNBDataRead;
      _bevetel := _vetel+_tobblet+_bankiatvet+_ptaratvesz+_visszaplusz;
      _kiadas := _eladas+_hiany+_bankiatad+_ptarkiad+_visszaminusz;
      _szamzaro := _nyito + _bevetel - _kiadas;
      MNBTabla.Edit;
      MNBTabla.FieldByName('SZAMITOTTZARO').AsInteger := _szamzaro;
      if _szamzaro<>_zaro then _megj := '?' else _megj := 'OK';
      MNBTabla.FieldByName('MEGJEGYZES').AsString := _megj;
      MNBTabla.Next;
    end;

  if mnbTranz.InTransaction then mnbTranz.commit;
  MnbTabla.Close;
  if _voltadat then Modalresult := 1 else ModalResult := 2;
end;



// ==============================================
      procedure TMNBLegyujto.MNBDataread;
// ==============================================

begin
  with MNBTabla do
    begin
      _nyito := FieldByName('NYITO').asInteger;
      _vetel := FieldByName('VETEL').asInteger;
      _eladas := FieldByName('ELADAS').asInteger;
      _hiany := FieldByNAme('HIANY').asInteger;
      _tobblet := FieldByNAme('TOBBLET').asInteger;
      _bankkartya := FieldByName('BANKKARTYA').asInteger;
      _bankiatvet := FieldByNAme('BANKIATVETEL').asInteger;
      _bankiatad := FieldByNAme('BANKIATADAS').asInteger;
      _ptarkiad := FieldByName('PENZTARIKIADAS').asInteger;
      _ptaratvesz := FieldByName('PENZTARIATVETEL').asInteger;
      _visszaPlusz := FieldByName('VISSZAPLUSZ').asInteger;
      _visszaMinusz := FieldByName('VISSZAMINUSZ').AsInteger;
      _zaro := FieldByName('ZARO').asInteger;
      _szamzaro := FieldByName('SZAMITOTTZARO').asInteger;
      _eladasdb := FieldByName('ELADASDARAB').asInteger;
      _veteldb := FieldByName('VETELDARAB').asInteger;
    end;
end;


// ================================================
         procedure TMNBLegyujto.ForgalomGyujtes;
// ================================================


begin
  FCsik.Position :=0;

  _pcs := 'SELECT FEJ.*, TET.*' + _sorveg;
  _pcs := _pcs +'FROM '+_fejtablanev+' FEJ JOIN '+_tettablanev+' TET'+_sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM'+_sorveg;

  if _ezegynap then
      _pcs := _pcs + 'WHERE FEJ.DATUM=' + chr(39) + _tolstring + chr(39)
  else
     _pcs := _pcs + 'WHERE FEJ.DATUM BETWEEN '+chr(39)+_tolstring+chr(39)+' AND '+chr(39)+_igstring+chr(39);

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
      if MNBTranz.intransaction then MNBtranz.commit;
      BlokkQuery.Close;
      Exit;
    end;

  FCsik.Max := _cc;
  _cc := 0;

// Itt indul a forgalom legyüjtés:

  _utbiz := 'XXXXXX';
  BlokkQuery.First;
  while not BlokkQuery.eof do
    begin
      inc(_cc);
      FCsik.Position := _cc;

    // Egy bizonylat-tétel adatainak beolvasása:

      with BlokkQuery do
        begin
          _bizonylat      := FieldByNAme('BIZONYLATSZAM').asString;
          _storno         := FieldByName('STORNO').asInteger;
          _aktTipus       := FieldByName('TIPUS').asString;
          _aktTarsPenztar := FieldByName('PENZTAR').asString;
          _aktDnem        := FieldByName('VALUTANEM').asString;
          _bankjegy       := FieldByName('BANKJEGY').asInteger;
          _elojel         := FieldByName('ELOJEL').asString;
          _ertek          := FieldByName('FORINTERTEK').asInteger;
          _fizetoeszkoz   := FieldByName('FIZETOESZKOZ').asInteger;
          _kerekites      := Fieldbyname('KEREKITES').asInteger;
        end;

      // a bizonylattétel VALUTANEMÉNEK sorszáma:

      _valss := Form1.DNemScan(_aktdnem);

      // Ha a tétel storno, vagy érvénytelen valutanem, akkor ignorálni a tételt

      if (_storno>1) or (_valss<0) then
        begin
          _utbiz := _bizonylat;
          BlokkQuery.Next;
          Continue;
        end;

      // A bizonylat-tétel társpénztárkódjának meghatározása:
      //          0 = bank vagy nincs társpénztár (pl. vétel,eladás)

      if _aktTarsPenztar='' then _aktTarspenztar := '0' else _aktTarspenztar := trim(_aktTarspenztar);
      if midstr(_aktTarspenztar,3,1)='.' then _aktTarsPenztar := leftstr(_aktTarsPenztar,2);
      Val(_aktTarsPenztar,_aktTarsPenztarSzam,_code);

      if _code<>0 then _aktTarsPenztarSzam := 0;

      // Ha a társpénztárszám nem nulla, akkor az egy saját pénztár

      _sajat := False;
      if (_aktTarsPenztarszam>1) and ((_AKTtipus='F') or (_AKTtipus='U')) then  _sajat := True;

      {
      // A konverziónál a plusz fizetendö forint tételét nem gyüjtjük !!!

      IF (_akttipus='K') AND (_aktdnem='HUF') then
        begin
          BlokkQuery.Next;
          Continue;
        end;
      }

      // Irqq= (0 és Iroda-darabnál eggyel kisebb szám) (IRODA-SORSZÁM)
      // Jelzi, hogy ebben az irodában volt mozgás ezzel a valutával=1

      _mvanadat[_irqq,_valss] := 1;

      // bankjegyet és forintértéket tömbbe gyüjti tipusok szerint

      Setcounter;

      IF (_AKTTIPUS='F') OR (_akttipus='U') then
        begin
          _utbiz := _bizonylat;
          BlokkQuery.Next;
          Continue;
        end;

      if _akttIpus='V' then _mvdb[_irqq,_valss] := _mvdb[_irqq,_valss] + 1;
      if _aktTipus='E' then _medb[_irqq,_valss] := _medb[_irqq,_valss] + 1;

      {
      if _akttipus='K' then
        begin
          _mvdb[_irqq,_valss] := _mvdb[_irqq,_valss] + 1;
          _medb[_irqq,_valss] := _medb[_irqq,_valss] + 1;
        end;
       }

      _utbiz := _bizonylat;
      BlokkQuery.Next;
    end;
  BlokkQuery.close;
end;


// =================================================
          procedure TMNBLegyujto.SetCounter;
// =================================================

begin
   if _aktTipus='V' then
     begin
       _mvet[_irqq,_valss] := _mvet[_irqq,_valss] + _bankjegy;
       _melad[_irqq,_ftss] := _melad[_irqq,_ftss] + _ertek;
       if _utbiz<>_bizonylat then _melad[_irqq,_ftss] := _melad[_irqq,_ftss] + _kerekites;
       exit;
     end;

   if _aktTipus='E' then
     begin
       _melad[_irqq,_valss] := _mElad[_irqq,_valss] + _bankjegy;

       if _fizetoeszkoz=2 then _bankkartya := _bankkartya + _ertek
       else
       begin
         _mvet[_irqq,_ftss] := _mvet[_irqq,_ftss] + _ertek;
         if _utbiz<>_bizonylat then _mvet[_irqq,_ftss] := _mvet[_irqq,_ftss] + _kerekites;
       end;

       exit;
     end;


  {
  if (_aktTipus = 'K') and (_elojel='+') then
    begin
      _mvet[_irqq,_valss] := _mvet[_irqq,_valss] + _bankjegy;
      _melad[_irqq,_ftss] := _melad[_irqq,_ftss] + _ertek;
      exit;
    end;

  if (_aktTipus = 'K') and (_elojel='-') then
    begin
      _melad[_irqq,_valss] := _melad[_irqq,_valss] + _bankjegy;
      _mvet[_irqq,_ftss] := _mvet[_irqq,_ftss] + _ertek;
      exit;
    end;
  }

  if (_aktTarsPenztar='TH') and (_elojel='+') then
    begin
      _mtobblet[_irqq,_valss] := _mTobblet[_irqq,_valss] + _bankjegy;
      exit;
    end;

  if (_aktTarsPenztar='TH') and (_elojel='-') then
    begin
      _mHiany[_irqq,_valss] := _mHiany[_irqq,_valss] + _bankjegy;
      exit;
    end;

  if (_aktTarsPenztar='1') and (_aktTipus='U') then
    begin
      _mvisszp[_irqq,_valss] := _mvisszp[_irqq,_valss] + _bankjegy;
      exit;
    end;

  if (_aktTarspenztar='1') and (_akttipus='F') then
    begin
      _mvisszm[_irqq,_valss] := _mvisszm[_irqq,_valss] + _bankjegy;
      exit;
    end;

  if (_aktTipus='F') and (_sajat) then
    begin
      _mptarba[_irqq,_valss] := _mptarba[_irqq,_valss] + _bankjegy;
      exit;
    end;

  if (_aktTipus='U') and (_sajat) then
    begin
      _mptarbol[_irqq,_valss] := _mptarbol[_irqq,_valss] + _bankjegy;
      exit;
    end;

  if (_aktTipus='F') and (_sajat=False) then
    begin
      _mbankba[_irqq,_valss] := _mbankba[_irqq,_valss] + _bankjegy;
      exit;
    end;

  if (_aktTipus='U') and (_sajat=False) then
    begin
      _mbankbol[_irqq,_valss] := _mbankbol[_irqq,_valss] + _bankjegy;
      exit;
    end;
end;



procedure TMNBLegyujto.MNBStart;

begin
  MnbDbase.Close;
  MnbDbase.COnnected := True;
  if MNBTranz.Intransaction then MNBTranz.Commit;
  MNBTranz.StartTransaction;
  with MNBTabla do
    begin
      Open;
      Refresh;
    end;
end;


(*
// ================================================
      function TMNBLegyujto.setelozoho():boolean;
// ================================================

begin
  Result := False;
  CimtarTabla.Close;

  _cimtarTablaNev := 'CIMT'+_elofarok;
  CimtarTabla.TableName := _cimtarTablaNev;
  CimtarDbase.Close;
  CimtarDbase.Connected := True;
  if not CimtarTabla.Exists then exit;

  _pcs := 'SELECT * FROM '+_cimtartablanev+_sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with Cimtarquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
    end;

  _datum := CimtarQuery.FieldByNAme('DATUM').asString;
  CimtarQuery.Close;
  Result := True;
end;
*)


// ======================================================
      procedure TMNBLegyujto.TombokRekordbairasa;
// ======================================================
//       A TÖMBÖKET BEIRJA AZ MNB TÁBLa REKORDJAIBA




begin

  MnbDbase.Close;
  MnbDbase.Connected := True;
  if MNBTranz.Intransaction then MNBTranz.Commit;
  MNBTranz.StartTransaction;
  with MNBTabla do
    begin
      Open;
      EmptyTable;
    end;

  FCsik.Max := _irodaDarab;
  _ii := 1;

  // Az összes iroda összes valutájának feljegyzése:

  while _ii<=_irodadarab-1 do
    begin
      Fcsik.position := _ii;
      _jj := 1;

      while _jj<=27 do
        begin

              _voltadat := True;
              _nyito := _mnyito[_ii,_jj];
              _zaro  := _mzaro[_ii,_jj];
              _vetel := _mvet[_ii,_jj];
              _eladas := _melad[_ii,_jj];
              _tobblet := _mtobblet[_ii,_jj];
              _hiany := _mhiany[_ii,_jj];
              _visszap := _mvisszp[_ii,_jj];
              _visszam := _mvisszm[_ii,_jj];
              _bankba := _mbankba[_ii,_jj];
              _bankbol := _mbankbol[_ii,_jj];
              _ptarba := _mptarba[_ii,_jj];
              _ptarbol := _mptarbol[_ii,_jj];
              _vdarab := _mvdb[_ii,_jj];
              _edarab := _medb[_ii,_jj];

              _aktptar := _irodaszam[_ii];
              _aktdnem := _dnem[_jj];
              _aktertektar := _korzet[_aktptar];
              _aktcegbetu := _cegbetutomb[_aktptar];

              // Értéktár és Bestchange summázása:

              _kft :=  Form1.GetCegbetuSorszam(_aktcegbetu);
              _etss := Form1.ErtTarScan(_aktertektar);
              Ertektarsumma(_etss,_jj);

              with MNBTabla do
                begin
                  append;
                  Edit;
                  FieldByName('IRODASZAM').asInteger := _aktptar;
                  FieldByName('CEGBETU').AsString := _aktcegBetu;
                  FieldByName('ERTEKTAR').asInteger :=  _aktertektar;
                  FieldByName('VALUTANEM').asString := _aktdnem;
                  FieldByName('NYITO').asInteger := _nyito;
                  FieldByName('VETEL').asInteger := _vetel;
                  FieldByName('ELADAS').asInteger := _eladas;
                  FieldByName('HIANY').asInteger := _hiany;
                  FieldByName('TOBBLET').asInteger := _tobblet;
                  FieldByName('BANKIATVETEL').asInteger := _bankbol;
                  FieldByName('BANKIATADAS').asInteger := _bankba;
                  FieldByName('PENZTARIKIADAS').asInteger := _ptarba;
                  FieldByName('PENZTARIATVETEL').asInteger := _ptarbol;
                  FieldByName('ZARO').asInteger := _zaro;
                  FieldByName('VETELDARAB').asInteger := _vdarab;
                  FieldByName('ELADASDARAB').asInteger := _edarab;
                  FieldByName('VISSZAPLUSZ').asInteger := _visszap;
                  FieldByName('VISSZAMINUSZ').asInteger := _visszam;
                  Post;
                end;

          inc(_jj);
        end;
      inc(_ii);
    end;

  if _kellctrl=1 then
    begin
      MNBTranz.Commit;
      MNBTabla.close;
      Exit;
    end;

  // Értéktárak feljegyzése:

  _ee := 0;
  while _ee<_ertektarDarab do
    begin
      _jj := 0;
      while _jj<_valutaDarab do
        begin
          _aktPtar := 0;
          _aktdnem := _dnem[_jj+1];
          _aktertektar := _korzetszam[_ee];
          _nyito := _enyito[_ee,_jj];
          _zaro := _ezaro[_ee,_jj];
          _vetel := _evetel[_ee,_jj];
          _eladas := _eeladas[_ee,_jj];
          _tobblet := _etobblet[_ee,_jj];
          _hiany := _ehiany[_ee,_jj];
          _visszap := _evisszap[_ee,_jj];
          _visszam := _evisszam[_ee,_jj];
          _bankba := _ebankba[_ee,_jj];
          _bankbol := _ebankbol[_ee,_jj];
          _ptarba := _eptarba[_ee,_jj];
          _ptarbol := _eptarbol[_ee,_jj];
          _vdarab := _evdarab[_ee,_jj];
          _edarab := _eedarab[_ee,_jj];

          with MNBTabla do
            begin
              append;
              Edit;
              FieldByName('IRODASZAM').asInteger := _aktptar;
           //   FieldByName('CEGBETU').AsString := _aktcegbetu;
              FieldByName('ERTEKTAR').asInteger :=  _aktertektar;
              FieldByName('VALUTANEM').asString := _aktdnem;
              FieldByName('NYITO').asInteger := _nyito;
              FieldByName('VETEL').asInteger := _vetel;
              FieldByName('ELADAS').asInteger := _eladas;
              FieldByName('HIANY').asInteger := _hiany;
              FieldByName('TOBBLET').asInteger := _tobblet;
              FieldByName('BANKIATVETEL').asInteger := _bankbol;
              FieldByName('BANKIATADAS').asInteger := _bankba;
              FieldByName('PENZTARIKIADAS').asInteger := _ptarba;
              FieldByName('PENZTARIATVETEL').asInteger := _ptarbol;
              FieldByName('ZARO').asInteger := _zaro;
              FieldByName('VETELDARAB').asInteger := _vdarab;
              FieldByName('ELADASDARAB').asInteger := _edarab;
              FieldByName('VISSZAPLUSZ').asInteger := _visszap;
              FieldByName('VISSZAMINUSZ').asInteger := _visszam;
              Post;
            end;
          inc(_jj);
        end;
      inc(_ee);
    end;

  // ----------------kft-k felirása --------------------------------------------

  _kft := 0;
  while _kft<2 do
    begin
      _jj := 0;
      _korzetbetu := _cegbetuk[_kft];
          while _jj<_valutaDarab do
            begin
              _aktPtar     := -1;
              _aktdnem     := _dnem[_jj+1];
              _aktertektar := -1;
              _nyito       := _kftnyito[_kft,_jj];
              _zaro        := _kftzaro[_kft,_jj];
              _vetel       := _kftvetel[_kft,_jj];
              _eladas      := _kfteladas[_kft,_jj];
              _tobblet     := _kfttobblet[_kft,_jj];
             _hiany        := _kfthiany[_kft,_jj];
             _visszap      := _kftvisszap[_kft,_jj];
             _visszam      := _kftvisszam[_kft,_jj];
             _bankba       := _kftbankba[_kft,_jj];
             _bankbol      := _kftbankbol[_kft,_jj];
             _ptarba       := _kftptarba[_kft,_jj];
             _ptarbol      := _kftptarbol[_kft,_jj];
             _vdarab       := _kftvdarab[_kft,_jj];
             _edarab       := _kftedarab[_kft,_jj];

             with MNBTabla do
            begin
              append;
              Edit;
              FieldByName('IRODASZAM').asInteger := -1;
              FieldByName('CEGBETU').AsString := _korzetbetu;
              FieldByName('ERTEKTAR').asInteger :=  _aktertektar;
              FieldByName('VALUTANEM').asString := _aktdnem;
              FieldByName('NYITO').asInteger := _nyito;
              FieldByName('VETEL').asInteger := _vetel;
              FieldByName('ELADAS').asInteger := _eladas;
              FieldByName('HIANY').asInteger := _hiany;
              FieldByName('TOBBLET').asInteger := _tobblet;
              FieldByName('BANKIATVETEL').asInteger := _bankbol;
              FieldByName('BANKIATADAS').asInteger := _bankba;
              FieldByName('PENZTARIKIADAS').asInteger := _ptarba;
              FieldByName('PENZTARIATVETEL').asInteger := _ptarbol;
              FieldByName('ZARO').asInteger := _zaro;
              FieldByName('VETELDARAB').asInteger := _vdarab;
              FieldByName('ELADASDARAB').asInteger := _edarab;
              FieldByName('VISSZAPLUSZ').asInteger := _visszap;
              FieldByName('VISSZAMINUSZ').asInteger := _visszam;
              Post;
            end;
          inc(_jj);
        end;
      inc(_kft);
    end;


  // Itt pedig felirja a BESTCHANGE REKORDJAIT:

  _jj := 0;
  while _jj<_valutadarab do
    begin
      _aktPtar := 0;
      _aktertektar := 0;
      _aktdnem := _dnem[_jj+1];
      _nyito := _snyito[_jj];
      _zaro := _szaro[_jj];
      _vetel := _svetel[_jj];
      _eladas := _seladas[_jj];
      _tobblet := _stobblet[_jj];
      _hiany := _shiany[_jj];
      _visszap := _svisszap[_jj];
      _visszam := _svisszam[_jj];
      _bankba := _sbankba[_jj];
      _bankbol := _sbankbol[_jj];
      _ptarba := _sptarba[_jj];
      _ptarbol := _sptarbol[_jj];
      _vdarab := _svdarab[_jj];
      _edarab := _sedarab[_jj];
      _bankkartya := _sbankkartya[_jj];

      with MNBTabla do
        begin
          append;
          Edit;
          FieldByName('IRODASZAM').asInteger := _aktptar;
       //   FieldByName('CEGBETU').AsString := _aktcegbetu;
          FieldByName('ERTEKTAR').asInteger :=  _aktertektar;
          FieldByName('VALUTANEM').asString := _aktdnem;
          FieldByName('NYITO').asInteger := _nyito;
          FieldByName('VETEL').asInteger := _vetel;
          FieldByName('ELADAS').asInteger := _eladas;
          FieldByName('HIANY').asInteger := _hiany;
          FieldByName('TOBBLET').asInteger := _tobblet;
          FieldByName('BANKIATVETEL').asInteger := _bankbol;
          FieldByName('BANKIATADAS').asInteger := _bankba;
          FieldByName('PENZTARIKIADAS').asInteger := _ptarba;
          FieldByName('PENZTARIATVETEL').asInteger := _ptarbol;
          FieldByName('ZARO').asInteger := _zaro;
          FieldByName('VETELDARAB').asInteger := _vdarab;
          FieldByName('ELADASDARAB').asInteger := _edarab;
          FieldByName('VISSZAPLUSZ').asInteger := _visszap;
          FieldByName('VISSZAMINUSZ').asInteger := _visszam;
          FieldByName('BANKKARTYA').asInteger := _bankkartya;
          Post;
        end;
      inc(_jj);
    end;
  MNBTranz.commit;
  MNBtabla.Close;
end;


// ======================================================================
      procedure TMNBLegyujto.Ertektarsumma(_et:integer; _vj:integer);
// ======================================================================


begin

  // ÉRTÉKTÁR SUMMÁZÁSA:

  _enyito[_et,_vj]   := _enyito[_et,_vj] + _nyito;
  _ezaro[_et,_vj]    := _ezaro[_et,_vj] + _zaro;
  _evetel[_et,_vj]   := _evetel[_et,_vj] + _vetel;
  _eeladas[_et,_vj]  := _eeladas[_et,_vj] + _eladas;
  _etobblet[_et,_vj] := _etobblet[_et,_vj] + _tobblet;
  _ehiany[_et,_vj]   := _ehiany[_et,_vj] + _hiany;
  _evisszap[_et,_vj] := _evisszap[_et,_vj] + _visszap;
  _evisszam[_et,_vj] := _evisszam[_et,_vj] + _visszam;
  _ebankba[_et,_vj]  := _ebankba[_et,_vj] + _bankba;
  _ebankbol[_et,_vj] := _ebankbol[_et,_vj] + _bankbol;
  _eptarba[_et,_vj]  := _eptarba[_et,_vj] + _ptarba;
  _eptarbol[_et,_vj] := _eptarbol[_et,_vj] + _ptarbol;
  _evdarab[_et,_vj]  := _evdarab[_et,_vj] + _vdarab;
  _eedarab[_et,_vj]  := _eedarab[_et,_vj] + _edarab;
  _ebankkartya[_et,_vj]:= _ebankkartya[_et,_vj] + trunc(_bankkartya);

  // KFT SUMMÁZÁSA:

  _kftnyito[_kft,_vj]   := _kftNyito[_kft,_vj] + _nyito;
  _kftZaro[_kft,_vj]    := _kftZaro[_kft,_vj] + _zaro;
  _kftVetel[_kft,_vj]   := _kftVetel[_kft,_vj] + _vetel;
  _kfteladas[_kft,_vj]  := _kftEladas[_kft,_vj] + _eladas;
  _kftTobblet[_kft,_vj] := _kftTobblet[_kft,_vj] + _tobblet;
  _kfthiany[_kft,_vj]   := _kfthiany[_kft,_vj] + _hiany;
  _kftvisszap[_kft,_vj] := _kftvisszap[_kft,_vj] + _visszap;
  _kftvisszam[_kft,_vj] := _kftvisszam[_kft,_vj] + _visszam;
  _kftbankba[_kft,_vj]  := _kftbankba[_kft,_vj] + _bankba;
  _kftbankbol[_kft,_vj] := _kftbankbol[_kft,_vj] + _bankbol;
  _kftptarba[_kft,_vj]  := _kftptarba[_kft,_vj] + _ptarba;
  _kftptarbol[_kft,_vj] := _kftptarbol[_kft,_vj] + _ptarbol;
  _kftvdarab[_kft,_vj]  := _kftvdarab[_kft,_vj] + _vdarab;
  _kftedarab[_kft,_vj]  := _kftedarab[_kft,_vj] + _edarab;
  _kftbankkartya[_kft,_vj] := _kftbankkartya[_kft,_vj] + trunc(_bankkartya);

  // exclusive CHANGE SUMMÁZÁSA

  _snyito[_vj]   := _snyito[_vj] + _nyito;
  _szaro[_vj]    := _szaro[_vj] + _zaro;
  _svetel[_vj]   := _svetel[_vj] + _vetel;
  _seladas[_vj]  := _seladas[_vj] + _eladas;
  _stobblet[_vj] := _stobblet[_vj] + _tobblet;
  _shiany[_vj]   := _shiany[_vj] + _hiany;
  _svisszap[_vj] := _svisszap[_vj] + _visszap;
  _svisszam[_vj] := _svisszam[_vj] + _visszam;
  _sbankba[_vj]  := _sbankba[_vj] + _bankba;
  _sbankbol[_vj] := _sbankbol[_vj] + _bankbol;
  _sptarba[_vj]  := _sptarba[_vj] + _ptarba;
  _sptarbol[_vj] := _sptarbol[_vj] + _ptarbol;
  _svdarab[_vj]  := _svdarab[_vj] + _vdarab;
  _sedarab[_vj]  := _sedarab[_vj] + _edarab;
  _sbankkartya[_vj] := _sbankkartya[_vj] + _bankkartya;

end;


// ======================================================================
        procedure TMNBlegyujto.Keszletbetolto(_nyzTipus: string);
// ======================================================================

var _filter,_utcimtDatum: string;

begin
  _voltadat := False;
  _cimtartablanev := 'CIMT' + _farok;

  Cimtardbase.Connected := False;
  CimtarTabla.Close;
  CImtardbase.DatabaseName := _aktfdbPath;
  CimtarDbase.Connected := True;
  CimtarTabla.TableName := _cimtarTablaNev;

  // Ha nincs a hónapnak cimlettáblája akkor multhavi utolsó nap:
  if not Cimtartabla.exists then
    begin
      MultHaviUtolso(_nyzTipus);
      Exit;
    end;

  _filter := 'DATUM<'+chr(39) + _tolstring + chr(39);
  if _nyzTipus='ZARO' then _filter := 'DATUM<='+ chr(39)+_igstring+chr(39);

  _pcs := 'SELECT * FROM '+ _cimtartablanev + _sorveg;
  _pcs := _pcs + 'WHERE '+_filter + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with CimtarQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
    end;

  if CimtarQuery.recno=0 then
    begin
      CimtarQuery.Close;
      MulthaviUtolso(_nyzTipus);
      Exit;
    end;

  _utcimtdatum := CimtarQuery.FieldByName('DATUM').asString;

  _pcs := 'SELECT * FROM '+ _cimtarTablanev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_utcimtDatum +chr(39);

  with CimtarQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

   while not CimtarQuery.Eof do
    begin
      // Beolvassuk sorban a valutanemeket
      _aktdnem := Cimtarquery.FieldByName('VALUTANEM').AsString;
      _valss := Form1.DnemScan(_aktdnem);

      if _valss<0 then
        begin
          CimtarQuery.Next;
          Continue;
        end;

      // Beolvassa a valuta nyitó összegét:
      _osszKeszlet := CimtarQuery.FieldByNAme('OSSZESEN').asInteger;
      if _nyzTipus='NYITO' then _mnyito[_irqq,_valss] := _osszKeszlet
      else _mZaro[_irqq,_valss] := _osszKeszlet;

      _voltAdat := true;
      CimtarQuery.next;
    end;
  Cimtarquery.Close;
end;


// ================================================================
       procedure TMNBlegyujto.MulthaviUtolso(_nyz: string);
// ================================================================

var _utcimtDatum: string;
begin
  _eloTablanev := 'CIMT' + _eloFarok;

  Cimtardbase.Connected := False;
  CimtarTabla.Close;
  CImtardbase.DatabaseName := _aktfdbPath;
  CimtarDbase.Connected := True;
  CimtarTabla.TableName := _eloTablaNev;

  // Ha nincs a multhónapnak se cimlettáblája, akkor ennyi :
  if not Cimtartabla.exists then exit;

  _pcs := 'SELECT * FROM '+ _eloTablaNev + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

   with CimtarQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
    end;

  _utcimtdatum := CimtarQuery.FieldByName('DATUM').asString;

  _pcs := 'SELECT * FROM '+ _eloTablanev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_utcimtDatum +chr(39);

  with CimtarQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

   while not CimtarQuery.Eof do
    begin
      // Beolvassuk sorban a valutanemeket
      _aktdnem := Cimtarquery.FieldByName('VALUTANEM').AsString;
      _valss := Form1.DnemScan(_aktdnem);

      if _valss<0 then
        begin
          CimtarQuery.Next;
          Continue;
        end;

      // Beolvassa a valuta nyitó összegét:

      _osszKeszlet := CimtarQuery.FieldByNAme('OSSZESEN').asInteger;
      if _nyz = 'NYITO' then _mnyito[_irqq,_valss] := _osszKeszlet
      else _mZaro[_irqq,_valss] := _osszKeszlet;

      _voltAdat := true;
      CimtarQuery.next;
    end;
  Cimtarquery.Close;
end;











end.
