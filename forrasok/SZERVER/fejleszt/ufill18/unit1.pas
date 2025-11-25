unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBQuery, IBCustomDataSet,strutils,
  IBTable, ExtCtrls;

type
  TForm1 = class(TForm)
    STARTGOMB: TBitBtn;
    KILEPOGOMB: TBitBtn;
    UTABLA: TIBTable;
    UQUERY: TIBQuery;
    UDBASE: TIBDatabase;
    UTRANZ: TIBTransaction;
    VTABLA: TIBTable;
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    Memo1: TMemo;
    PTABLA: TIBTable;
    PQUERY: TIBQuery;
    PDBASE: TIBDatabase;
    PTRANZ: TIBTransaction;
    FDBPANEL: TPanel;
    HONAPPANEL: TPanel;
    UGYFELPANEL: TPanel;

    procedure KILEPOGOMBClick(Sender: TObject);
    procedure STARTGOMBClick(Sender: TObject);
    procedure AdatTorles;
    procedure Bemasolas;

    procedure NaturRutin;
    procedure JogiRutin;

    procedure NaturDAtaFromPersbig;
  
    procedure NaturUgyfelBedolgozas;
    procedure UjNaturUgyfelFelvetele;


    procedure JogiDataFromPersbig;
    procedure FoundJogiClient;
    procedure JogiUgyfelBedolgozas;
    procedure UjJogiUgyfelFelvetele;

    procedure Bizregisztracio;
    function Angolra(_huName: string): string;
    function HutoGb(_kod: byte): byte;
    function Tomorito(_ts: string): string;


    procedure Uparancs(_ukaz: string);
    procedure Vparancs(_ukaz: string);
    function Szetszed(_s: string): byte;
    function ezertektar(_p: byte): boolean;
 
    function Doublekill(_s: string): string;
    function Nulele(_b: byte): string;

    function Ezirszam(_is: string): boolean;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _pt,_ho,_vJoginevHossz: byte;
  _vUgyfelszam,_vFizetendo,_recno,_tDb,_sss,_fto,_evimax: integer;

  _pcs,_fdbPath,_tNev,_filter,_kBetu,_nevtabla,_lastvari,_biztabla: string;
  _vUgyfel,_vUgyfelnev,_vUgyfelcim,_vUgyfeltipus,_vBizonylatszam,_vDatum: string;
  _vVaros,_vUtca,_vJoginev: string;

  _pKulfoldi: byte;

  _pUgyfelnev,_pugyfelcim,_pVaros,_pUtca,_pElozonev,_pAnyjaneve: string;
  _pLeanykori,_pSzuletesihely,_pSzuletesiido,_pAllampolgar,_pLakcim: string;
  _pAzonosito,_pLakcimkartya,_pTartozkodasihely,_pBizonylatszam: string;
  _pDatum,_pOkmanytipus,_pJoginev,_pTelephely,_pOkiratszam: string;
  _pFotevekeny,_pMBNeve,_pKepvisnev,_pMbBeo,_pKepvisbeo: string;

  _PFizetendo: integer;

  _sorveg: string = chr(13)+chr(10);
  _szotag: array[1..18] of string;

  _megvan: boolean;


implementation

{$R *.dfm}


// =============================================================================
               procedure TForm1.STARTGOMBClick(Sender: TObject);
// =============================================================================

begin
   Memo1.Lines.Add('ADATTÖRLÉS ....');
   AdatTorles;

   Memo1.Lines.Add('BEMÁSOLÁS ...');
   Bemasolas;
end;

// =============================================================================
                            procedure TForm1.ADattorles; // OKE
// =============================================================================

VAR _B: BYTE;
    _nNev,_bnev: string;

begin
   Memo1.Lines.Add('AZ ADATOK TÖRLÉSE ......');

   _b := 65;
  while _b<=90 do
    begin
      _Nnev := chr(_b)+'NEV';
      _Bnev := chr(_b)+'BIZ';

      _pcs  := 'DELETE FROM ' + _nnev;
      Uparancs(_pcs);

      _pcs := 'DELETE FROM ' + _bnev;
      Uparancs(_pcs);

      inc(_b);
    end;

  _pcs := 'DELETE FROM JOGI';
  Uparancs(_pcs);

  _pcs := 'DELETE FROM JOGIBIZ';
  Uparancs(_pcs);

  _pcs := 'DELETE FROM LASTNUMS';
  Uparancs(_pcs);

  _pcs := 'INSERT INTO LASTNUMS (ALAST,BLAST,CLAST,DLAST,ELAST,FLAST,GLAST,HLAST,';
  _pcs := _pcs + 'ILAST,JLAST,KLAST,LLAST,MLAST,NLAST,OLAST,PLAST,QLAST,RLAST,SLAST,';
  _pcs := _pcs + 'TLAST,ULAST,VLAST,WLAST,XLAST,YLAST,ZLAST,JOGILAST)' + _sorveg;
  _pcs := _pcs + 'VALUES (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)';
  Uparancs(_pcs);
end;


// =============================================================================
                             procedure TForm1.Bemasolas;
// =============================================================================

begin
  // ------------- 1. penztártól a 168-es pénztárig végigmegy  -----------------

  _pt := 1;              // PENTTÁR = 1 - 168
  while _pt<=168 do
    begin

      //  Értéktárban nincs ügyfél: átlépi

      if EzErtektar(_pt) then
        begin
          inc(_pt);
          continue;
        end;

      // Adatbázis utvonala:

      _fdbPath := 'c:\receptor\database\v'+inttostr(_pt)+'.fdb';

      // Ha nincs ilyen pénztár: átlépi

      if not FileExists(_fdbPath) then
        begin
          inc(_pt);
          continue;
        end;

      fdbPanel.Caption := _fdbPath;
      fdbPanel.Repaint;

      vDbase.close;
      vDbase.DatabaseName := _fdbPath;

      VTabla.close;

      // Januártól - Decemberig végignézzük a blokkfejeket

      _ho := 1;
      while _ho<=12 do
        begin

          // A hónap megfelelõ blokkfeje:
          _tnev := 'BF18' + nulele(_ho);

          HonapPanel.Caption := _tnev;
          HonapPanel.repaint;

          vTabla.TableName := _tNev;
          vDbase.Connected := True;

          // Ha ebben a hónapban nem volt havigyüjtõ -> tovább

          if not vTabla.Exists then
            begin
              vDbase.close;

              inc(_ho);
              Continue;
            end;

          // Vétel, eladás blokkok, nem stornozott, van ügyfélnév blokkok:

          _filter := '((TIPUS='+chr(39)+'V'+chr(39)+') OR (TIPUS=';
          _filter := _filter + chr(39)+'E'+chr(39)+')) AND (STORNO=1) AND (';
          _filter := _filter + 'UGYFELNEV>'+CHR(39)+'@'+chr(39)+')';

          _pcs := 'SELECT * FROM ' + _tNev + _sorveg;
          _pcs := _pcs + 'WHERE ' + _filter;

          with vQuery do
            begin
              close;
              sql.clear;
              sql.add(_pcs);
              Open;
              First;
            end;

          // Sorbamegyünk a blokkfejekben lévõ ügyfeleken:

          while not vQuery.Eof do
            begin
              with vQuery do
                begin
                  _vUgyfelnev     := Angolra(FieldByNAme('UGYFELNEV').asString);
                  _vUgyfelcim     := Angolra(FieldByNAme('UGYFELCIM').asString);
                  _vUgyfelszam    := Fieldbyname('UGYFELSZAM').asinteger;
                  _vUgyfeltipus   := uppercase(FieldByNAme('UGYFELTIPUS').asstring);

                  _vFizetendo     := FieldByName('OSSZESEN').asInteger;
                  _vBizonylatszam := FieldByName('BIZONYLATSZAM').asString;
                  _vDatum         := FieldByName('DATUM').asString;
                end;

              if _vUgyfelTipus='X' then
                 begin
                   vQuery.next;
                   Continue;
                 end;

              if _vugyfelTipus = 'J' then JogiRutin
              else NaturRutin;
              vQuery.Next;
            end;

          Vdbase.close;
          VQuery.close;

          inc(_ho);   // következõ hónap
        end;
      inc(_pt);       // következõ pénztár
    end;
end;

// *****************************************************************************
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                           procedure TForm1.NaturRutin;
// =============================================================================

var _irsz: string;

begin

   _kBetu := leftstr(_vUgyfelnev,1);
   _nevTabla := _kBetu + 'NEV';

   // ------------------------------

   Szetszed(_vUgyfelcim);

   _irsz := _szotag[1];
   if ezIrszam(_irsz) then
     begin
       _vVaros := _szotag[2];
       _vUtca  := _szotag[3];
     end else
     begin
       _vVaros := _szotag[1];
       _vUtca  := _szotag[2];
     end;

   // Beolvassa a Persbig táblából az ügyfélszámhoz tartozó rekordot


   _pcs := 'SELECT * FROM ' + _nevTabla + _sorveg;
   _pcs := _pcs + 'WHERE UGYFELSZAM=' + inttostr(_vUgyfelSzam);

   // A persbig Névtáblában keresi a megadott ügyfélszámot:
   // -----------------------------------------------------

   pDbase.Connected := True;
   with PQuery do
     begin
       Close;
       Sql.clear;
       Sql.add(_pcs);
       Open;
       _recno := recno;
     end;

   _megvan := False;
   while not PQuery.Eof do
     begin
       _pUgyfelnev:= Angolra(Pquery.FieldByNAme('NEV').asString);

       // Ha a név egyezik a két adatbázisban -¢ megtaláltam persbig rekordot
       if _pUgyfelnev=_vUgyfelnev  then
         begin
           _megvan := True;
           break;
         end;
       pQuery.next;
     end;

   // --------------------------------------------------------------------------

   // Ha a megadott ügyfélszámon az adott ügyfél van, tehát rendben:

   if _megvan then
     begin

     
      
       NaturDAtaFromPersbig;
       Pquery.close;
       Pdbase.close;

       NaturUgyfelBedolgozas;
       exit;
     end;

  // ---------------------------------------------------------------------------

   // Most megpróbálom NEV szerint keresni

   _pcs := 'SELECT * FROM ' + _NEVTABLA + _sorveg;
   _pcs := _pcs + 'WHERE NEV='+ chr(39)+_vugyfelnev+chr(39);
   pDbase.connected := true;
   with pQuery do
     begin
       Close;
       sql.clear;
       sql.add(_pcs);
       Open;
       _recno := recno;
     end;

   if _recno=0 then
     begin
       Pquery.close;
       Pdbase.close;
    
       exit;
     end;

   while not Pquery.eof do
     begin
       _pugyfelnev := angolra(Pquery.FieldByNAme('NEV').asString);
       _pugyfelcim := angolra(Pquery.FieldByNAme('LAKCIM').asString);

       Szetszed(_pUgyfelcim);

       _irsz := _szotag[1];
       if ezIrszam(_irsz) then
         begin
           _pVaros := _szotag[2];
           _pUtca  := _szotag[3];
         end else
         begin
           _pVaros := _szotag[1];
           _pUtca  := _szotag[2];
         end;

      if (_pvaros=_vvaros) or (_putca=_vUtca) then
         begin

           NaturDAtaFromPersbig;
           Pquery.close;
           Pdbase.close;

           Naturugyfelbedolgozas;
           exit;
         end;
       Pquery.next;
     end;

   // Nem találtam meg az ügyfelet:

   PQuery.close;
   Pdbase.close;
end;

// =============================================================================
                      procedure TForm1.NaturDAtaFromPersbig;
// =============================================================================

begin
  with PQuery do
    begin
      _pUgyfelnev        := Angolra(FieldByNAme('NEV').asString);
      _pElozonev         := Angolra(Fieldbyname('ELOZONEV').asString);
      _pAnyjaneve        := Angolra(Fieldbyname('ANYJANEVE').asString);
      _pLeanykori        := Angolra(Fieldbyname('LEANYKORI').asString);
      _pSzuletesihely    := Angolra(Fieldbyname('SZULETESIHELY').asString);
      _pSzuletesiido     := tomorito(Fieldbyname('SZULETESIIDO').asString);
      _pAllampolgar      := Angolra(Fieldbyname('ALLAMPOLGAR').asString);
      _pLakcim           := Angolra(Fieldbyname('LAKCIM').asString);
      _pOkmanytipus      := Angolra(Fieldbyname('OKMANYTIPUS').asString);
      _pAzonosito        := tomorito(Fieldbyname('AZONOSITO').asString);
      _pTartozkodasihely := Angolra(Fieldbyname('TARTOZKODASIHELY').asString);
      _pLakcimkartya     := tomorito(Fieldbyname('LAKCIMKARTYA').asString);
      _pKulfoldi         := Fieldbyname('KULFOLDI').asInteger;
    end;
  _pOkmanytipus := leftstr(_pOkmanytipus,10);
end;



// =============================================================================
               procedure TForm1.NaturUgyfelBedolgozas;
// =============================================================================

begin
  _kBetu    := leftstr(_nevTabla,1);
  _lastVari := _kBetu + 'LAST';
  _bizTabla := _kBetu + 'BIZ';

  uGYFELPANEL.Caption := _PuGYFELNEV;
  Ugyfelpanel.repaint;

  _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
  _pcs := _pcs + 'WHERE (NEV=' + chr(39) + _pUgyfelNev+chr(39) + ')';
  _pcs := _pcs + ' AND (ANYJANEVE=' + chr(39) + _pAnyjaneve + chr(39)+')';

  // ---------------------------------------------------------------------

  uDbase.Connected := True;
  with UQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      Uquery.close;
      uDbase.close;
      UjNaturUgyfelFelvetele;
      exit;
    end;

  _tdb := Uquery.FieldByNAme('TRANZAKCIODB').asInteger;
  _sss := Uquery.FieldByNAme('SORSZAM').asInteger;
  _fto := Uquery.FieldByNAme('FORINTOSSZEG').asInteger;
  _evimax := Uquery.FieldByNAme('EVIMAX').asInteger;

  Uquery.Close;
  Udbase.close;

  if _vfizetendo>_evimax then _evimax := _vfizetendo;

  _fto := _fto + _VFizetendo;
  inc(_tdb);

  _pcs := 'UPDATE ' + _nevtabla + ' SET TRANZAKCIODB='+inttostr(_tdb);
  _pcs := _pcs + ',EVIMAX=' + inttostr(_evimax);
  _pcs := _pcs + ',FORINTOSSZEG=' + inttostr(_fto) + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM='+ inttostr(_sss);
  uParancs(_pcs);

  Bizregisztracio;
end;

// =============================================================================
                      procedure TForm1.Bizregisztracio;
// =============================================================================

begin
  _pcs := 'INSERT INTO ' + _biztabla + ' (SORSZAM,BIZONYLATSZAM,FIZETENDO,DATUM)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + inttostr(_sss) + ',';
  _pcs := _pcs + chr(39) + _vBizonylatszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_vfizetendo) + ',';
  _pcs := _pcs + chr(39) + _vDatum + chr(39) + ')';
  UParancs(_pcs);
end;

// =============================================================================
               procedure TForm1.UjNaturUgyfelFelvetele;
// =============================================================================

begin
  Udbase.connected := true;

  _pcs := 'SELECT * FROM LASTNUMS';
  with uquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _sss := FieldByNAme(_lastvari).asInteger;
      Close;
    end;
  Udbase.close;

  inc(_sss);

  _tdb := 1;
  _fto := _VFizetendo;

  // ---------------------------------------------------------------------

  _pcs := 'UPDATE LASTNUMS SET '+_LASTVARI+'='+inttostr(_sss);
  uParancs(_pcs);

  _pcs := 'INSERT INTO ' + _nevtabla + ' (SORSZAM,NEV,ELOZONEV,ANYJANEVE,';
  _pcs := _pcs + 'LEANYKORI,SZULETESIHELY,SZULETESIIDO,ALLAMPOLGAR,LAKCIM,';
  _pcs := _pcs + 'OKMANYTIP,AZONOSITO,TARTOZKODASIHELY,LAKCIMKARTYA,KULFOLDI,';
  _pcs := _pcs + 'TRANZAKCIODB,FORINTOSSZEG,EVIMAX)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_sss) + ',';
  _pcs := _pcs + chr(39) + _pUgyfelNev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _pElozonev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _pAnyjaneve + chr(39) + ',';
  _pcs := _pcs + chr(39) + _pLeanykori + chr(39) + ',';
  _pcs := _pcs + chr(39) + _pSzuletesihely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _pSzuletesiido + chr(39) + ',';
  _pcs := _pcs + chr(39) + _pAllampolgar + chr(39) + ',';
  _pcs := _pcs + chr(39) + _pLakcim + chr(39) + ',';
  _pcs := _pcs + chr(39) + _pOkmanytipus + chr(39) + ',';
  _pcs := _pcs + chr(39) + _pAzonosito + chr(39) + ',';
  _pcs := _pcs + chr(39) + _pTartozkodasihely + chr(39) + ',';
  _pcs := _pcs + chr(39) + _pLakcimkartya + chr(39) + ',';

  _pcs := _pcs + inttostr(_pKulfoldi) + ',';
  _pcs := _pcs + '1,';
  _pcs := _pcs + inttostr(_Fto)+',';
  _pcs := _pcs + inttostr(_fto)+')';

  Uparancs(_pcs);

  BizRegisztracio;
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//##############################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                         procedurE tfORM1.JogiRutin;
// =============================================================================

begin
  _nevtabla := 'JOGI';
  _vjoginev := trim(leftstr(_vugyfelnev,12));
  _vjogiNevhossz := length(_vjoginev);

  _pcs := 'SELECT * FROM JOGI' + _sorveg;
   _pcs := _pcs + 'WHERE UGYFELSZAM=' + inttostr(_vugyfelszam);

   Pdbase.connected := true;
   with  PQuery do
     begin
       Close;
       sql.clear;
       sql.add(_pcs);
       Open;
       _recno := recno;
     end;

   _pJogiNev := Angolra(Pquery.FieldByNAme('JOGISZEMELYNEV').asstring);

   if leftstr(_pJoginev,_vjogiNevHossz)=_vJoginev then
     begin
       JogiDataFromPersbig;
       Pquery.close;
       Pdbase.close;
       FoundJogiClient;
       exit;
     end;

  // Most nev szerint keressük a jogi személyt

  _pcs := 'SELECT * FROM JOGI WHERE JOGISZEMELYNEV LIKE ';
  _pcs := _pcs + chr(39) + _vjoginev + '%' + CHR(39);

  with Pquery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno>0 then
     begin
       JogiDAtaFromPersbig;
       Pquery.close;
       Pdbase.close;

       FoundJogiClient;
       exit;
     end;

    // Nem találtam meg az ügyfelet:

   PQuery.close;
   Pdbase.close;
end;


// =============================================================================
                      procedure TForm1.JogiDataFromPersbig;
// =============================================================================

begin
  with PQuery do
    begin
      _pJoginev    := Angolra(FieldByNAme('JOGISZEMELYNEV').asString);
      _pTelephely  := Angolra(FieldByNAme('TELEPHELYCIM').AsString);
      _pOkiratszam := Angolra(FieldByNAme('OKIRATSZAM').asString);
      _pFotevekeny := Angolra(FieldByNAme('FOTEVEKENYSEG').AsString);
      _pMbNeve     := Angolra(FieldByNAme('MEGBIZOTTNEVE').AsString);

      _pKepvisnev  := Angolra(FieldByNAme('KEPVISELONEV').AsString);
      _pMbBeo      := Angolra(FieldByNAme('MEGBIZOTTBEOSZTASA').AsString);
      _pKepvisbeo  := Angolra(FieldByNAme('KEPVISBEO').AsString);
    end;
end;

// =============================================================================
                  procedure TForm1.FoundJogiClient;
// =============================================================================


begin

  JogiUgyfelBedolgozas;
end;


// =============================================================================
               procedure TForm1.JogiUgyfelBedolgozas;
// =============================================================================

begin
  _kBetu    := leftstr(_nevTabla,1);
  _lastVari := 'JOGILAST';
  _bizTabla := 'JOGIBIZ';

  _pcs := 'SELECT * FROM JOGI' + _sorveg;
  _pcs := _pcs + 'WHERE JOGISZEMELYNEV='+chr(39) + _PJOGINEV+ chr(39);

  // ---------------------------------------------------------------------

  uDbase.Connected := True;
  with UQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      Uquery.close;
      uDbase.close;
      UjJogiUgyfelFelvetele;
      exit;
    end;

  _tdb := Uquery.FieldByNAme('TRANZAKCIODB').asInteger;
  _sss := Uquery.FieldByNAme('SORSZAM').asInteger;
  _fto := Uquery.FieldByNAme('FORINTOSSZEG').asInteger;
  _evimax := Uquery.FieldByNAme('EVIMAX').asInteger;

  Uquery.Close;
  Udbase.close;


  if _vFizetendo>_evimax then _evimax := _vFizetendo;

  _fto := _fto + _vFizetendo;
  inc(_tdb);

  _pcs := 'UPDATE JOGI SET TRANZAKCIODB='+inttostr(_tdb);
  _pcs := _pcs + ',EVIMAX=' + inttostr(_evimax);
  _pcs := _pcs + ',FORINTOSSZEG=' + inttostr(_fto) + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM='+ inttostr(_sss);
  uParancs(_pcs);

  Bizregisztracio;
end;

// =============================================================================
               procedure TForm1.UjJogiUgyfelFelvetele;
// =============================================================================

begin
  Udbase.connected := true;

  _pcs := 'SELECT * FROM LASTNUMS';
  with uquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _sss := FieldByNAme('JOGILAST').asInteger;
      Close;
    end;
  Udbase.close;

  inc(_sss);

  _tdb := 1;
  _fto := _pFizetendo;

  // ---------------------------------------------------------------------

  _pcs := 'UPDATE LASTNUMS SET JOGILAST='+inttostr(_sss);
  uParancs(_pcs);

   _pcs := 'INSERT INTO JOGI (JOGISZEMELYNEV,TELEPHELYCIM,OKIRATSZAM,';
   _pcs := _pcs + 'FOTEVEKENYSEG,MEGBIZOTTNEVE,KEPVISELONEV,KEPVISBEO,';
   _pcs := _pcs + 'MEGBIZOTTBEOSZTASA,SORSZAM,KULFOLDI,TRANZAKCIODB,';
   _pcs := _pcs + 'FORINTOSSZEG,EVIMAX)' + _sorveg;

   _pcs := _pcs + 'VALUES (' + chr(39) + _pjoginev + chr(39) + ',';
   _pcs := _pcs + chr(39) + _pTelephely + chr(39) + ',';
   _pcs := _pcs + chr(39) + _pOkiratszam + chr(39) + ',';
   _pcs := _pcs + chr(39) + _pFotevekeny + chr(39) + ',';
   _pcs := _pcs + chr(39) + _pMbNeve + chr(39) + ',';
   _pcs := _pcs + chr(39) + _pKepvisnev + chr(39) + ',';
   _pcs := _pcs + chr(39) + _pKepvisbeo + chr(39) + ',';
   _pcs := _pcs + chr(39) + _pMbBeo +  chr(39) + ',';
   _pcs := _pcs + inttostr(_sss) + ',';
   _pcs := _pcs + inttostr(_pkulfoldi) + ',';
   _pcs := _pcs + '1,';
   _pcs := _pcs + inttostr(_fto) + ',';
   _pcs := _pcs + inttostr(_vFizetendo)+')';

  Uparancs(_pcs);

  BizRegisztracio;
end;

// =============================================================================
                function TForm1.ezertektar(_p: byte): boolean;
// =============================================================================

begin
  result := False;
  if (_p=10) or (_p=20) or (_p=40) or (_p=50) or (_p=63) or (_p=85) or (_p=120) or (_p=145) then result := True;
end;


// =============================================================================
                function TForm1.Szetszed(_s: string): byte;
// =============================================================================

VAR _q,_len,_asc,i: byte;
    _tags: string;

begin
  _q := 0;
  _s := trim(_s);
  _len := length(_s);
  i := 1;

  _tags := '';
  while i<=_len do
    begin
      _asc := ord(_s[i]);
      if (_asc=44) or (_asc=46) then
        begin
          inc(i);
          Continue;
        end;

      if (_asc=32) then
        begin
          inc(_q);
          _szotag[_q] := _tags;
          if _tags=' ' then dec(_q);
          _tags := '';
        end else _tags := _tags + chr(_asc);

      inc(i);
    end;
  inc(_q);
  _szotag[_q] := _tags;
  result := _q;

end;


// =============================================================================
                   procedure TForm1.Uparancs(_ukaz: string);
// =============================================================================

begin
  udbase.connected := true;
  if utranz.InTransaction then utranz.Commit;
  utranz.StartTransaction;
  with uquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  utranz.commit;
  udbase.close;
end;

// =============================================================================
                 procedure TForm1.Vparancs(_ukaz: string);
// =============================================================================

begin
  Vdbase.connected := true;
  if Vtranz.InTransaction then Vtranz.Commit;
  Vtranz.StartTransaction;
  with Vquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Vtranz.commit;
  Vdbase.close;
end;

// =============================================================================
           procedure TForm1.KILEPOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;

// =============================================================================
               function TForm1.Ezirszam(_is: string): boolean;
// =============================================================================

var _y,_asc: byte;

begin
  result := False;

  _is := trim(_is);
  if length(_is)<>4 then exit;

  _y := 1;
  while _y<=4 do
    begin
      _asc := ord(_is[_y]);
      if (_asc<48) or (_asc>57) then exit;
      inc(_y);
    end;
  result := True;
end;

// =============================================================================
                 function TForm1.Angolra(_huName: string): string;
// =============================================================================

var _whn,_z,_asc: byte;

begin
  result  := '';

  _huname := uppercase(trim(_huname));
  _whn    := length(_huname);

  if _whn=0 then exit;

  _z := 1;
  while _z<=_whn do
    begin
      _asc := ord(_huname[_z]);
      _asc := HutoGb(_asc);

      result := result + chr(_asc);
      inc(_z);
    end;

  result := DoubleKill(result);

end;

// =============================================================================
                   function TForm1.DoubleKill(_s: string): string;
// =============================================================================

var _w,_asc,_utasc,_y: byte;

begin
  result := '';

  _s := trim(_s);
  _w := length(_s);

  // Ha üres string -> nincs mit tömöriteni
  if _w=0 then exit;

  _y     := 1;
  _utasc := 0;       // default

  while _y<=_w do
    begin
      _asc := ord(_s[_y]);
      if (_asc=32) and (_utasc=32) then
        begin
          inc(_y);
          continue;
        end;

      if _asc=32 then
        begin
          result := result + ' ';
          _utasc := 32;
          inc(_y);
          Continue;
        end;

      if (_asc<48) or (_asc>90) then
        begin
          inc(_y);
          Continue;
        end;

      if (_asc>57) and (_asc<65) then
        begin
          inc(_y);
          Continue;
        end;

      result := Result + chr(_asc);
      _utasc := _asc;
      inc(_y);
    end;
end;




// =============================================================================
                   function TForm1.HutoGb(_kod: byte): byte;
// =============================================================================

var _r: byte;

begin
  _r := _kod;
  case _kod of
    186: _r := 69;  // E
    187: _r := 79;  // O
    193: _r := 65;  // A
    201: _r := 69;  // E
    211: _r := 79;  // O
    213: _r := 79;  // O
    214: _r := 79;  // O
    218: _r := 85;  // U
    219: _r := 85;  // U
    220: _r := 85;  // U
    222: _r := 65;  // A
    226: _r := 73;  // I
    205: _r := 73;  // I

    225: _r := 97;  // a
    233: _r := 101; // e
    237: _r := 105; // i
    243: _r := 111; // o
    246: _r := 111; // o
    245: _r := 111; // o
    250: _r := 117; // u
    252: _r := 117; // u
    251: _r := 117; // u
  end;
  result := _r;
end;


// =============================================================================
           function TForm1.Tomorito(_ts: string): string;
// =============================================================================

var _ws,_y,_aktasc: byte;

begin
  _ts := trim(_ts);
  result := '';

  if _ts='' then exit;

  _ts := uppercase(_ts);
  _ws := length(_ts);
  _y := 1;

  while _y<=_ws do
    begin
      _aktasc := ord(_ts[_y]);
      if (_aktasc>47) and (_aktasc<58) then result := result + chr(_aktasc);
      if (_aktasc>64) and (_aktasc<91) then result := result + chr(_aktasc);
      inc(_y);
    end;
end;

// =============================================================================
                 function TForm1.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;




end.
