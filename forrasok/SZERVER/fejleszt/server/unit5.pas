unit Unit5;

interface                          

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, DateUtils, Unit1, DB, DBTables, StrUtils,
  IBDatabase, IBCustomDataSet, IBTable, IBQuery, ComObj,Excel97, Oleserver,
  Printers;

type
  TMAKEIMPORT = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    EVKOMBO: TComboBox;
    HOKOMBO: TComboBox;
    NAPKOMBO: TComboBox;
    IMPORTGO: TBitBtn;
    IMPORTCANCEL: TBitBtn;
    uzeno: TMemo;
    SALLOMANYTABLA: TIBTable;
    SALLOMANYDBASE: TIBDatabase;
    SALLOMANYTRANZ: TIBTransaction;
    SBANKFORGTABLA: TIBTable;
    SBANKFORGDBASE: TIBDatabase;
    SBANKFORGTRANZ: TIBTransaction;
    BLOKKFEJTABLA: TIBTable;
    BLOKKFEJDBASE: TIBDatabase;
    BLOKKFEJTRANZ: TIBTransaction;
    BLOKKTETELTABLA: TIBTable;
    BLOKKTETELDBASE: TIBDatabase;
    BLOKKTETELTRANZ: TIBTransaction;
    CIMTARTABLA: TIBTable;
    CIMTARDBASE: TIBDatabase;
    CIMTARTRANZ: TIBTransaction;
    DAYBOOKTABLA: TIBTable;
    DAYBOOKDBASE: TIBDatabase;
    DAYBOOKTRANZ: TIBTransaction;
    SUGYFELFORGTABLA: TIBTable;
    SUGYFELFORGDBASE: TIBDatabase;
    SUGYFELFORGTRANZ: TIBTransaction;
    CimtarQuery: TIBQuery;
    SUGYFELFORGQUERY: TIBQuery;
    RECEPTORQUERY: TIBQuery;
    RECEPTORDBASE: TIBDatabase;
    RECEPTORTRANZ: TIBTransaction;
    BLOKKTABLA: TIBTable;
    BLOKKDBASE: TIBDatabase;
    BLOKKQUERY: TIBQuery;
    BLOKKTRANZ: TIBTransaction;
    Shape1: TShape;
    Shape2: TShape;
    NAPNEVPANEL: TPanel;
    Shape3: TShape;
    Label2: TLabel;
    SBANKFORGQUERY: TIBQuery;
    EXCELPRINTGOMB: TBitBtn;
    BACKTOMENUGOMB: TBitBtn;
    PrintDialog1: TPrintDialog;
    PRINTMENUPANEL: TPanel;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    Shape4: TShape;
    Shape5: TShape;

    procedure FormCreate(Sender: TObject);
    procedure ImportCancelClick(Sender: TObject);
    procedure SetNapszam;
    procedure EvKomboChange(Sender: TObject);
    procedure HoKomboChange(Sender: TObject);
    procedure NapKomboChange(Sender: TObject);
    procedure ImportGoClick(Sender: TObject);
    procedure AllomPrepare;
    procedure WImport;
    procedure EgyVrep(_VStatus: string);
    procedure UgyfPrePare;
    procedure ElsoNapiKeszlet;

    procedure AllomanyIras;
    procedure UgyfelForgIras;
    procedure BankForgIras;
    procedure AdatbazisUrito;
    procedure Bankforgfeliro;
    procedure exceltablaKeszito;
    procedure MakeTRBExcel(_akft: string);

    function Cimtarseek(_nap: string):boolean;
    function Setidostr:string;
    function Otnulla(_cci: integer):string;
    procedure EXCELPRINTGOMBClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BACKTOMENUGOMBClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MAKEIMPORT: TMAKEIMPORT;
  _bfTablaNev,_btTablanev,_pcs,_path: string;
  _zznap,_adatum,_datums: string;
  _targyDatum: TDateTime;
  _tenyev,_aktev,_aktho,_aktnap,_hnap,_houtolsonap: word;
  _targyEv,_targyho,_targynap: word;
  _exev,_exho,_exnap: word;
  _excelTabla,_sajatexcel,_range: variant;

   _vettVal,_eladottval: array[0..27] of real;
   _felvettval,_befizetettval: array[0..27,0..2] of real;

   _forintSs,_valss,_recno,_rcc,_bekp,_kikp,_aktsor,_bankkartyas,_bkkezdij: integer;

  _voltBankForg: array[0..2] of Boolean;


  _ezBank,_vanJelentes,_ezEdit,_voltugyfforg: Boolean;
  _adat,_aktStatus,_ugyff,_bankf,_stblokk,_regiblokk,_utBKod,_sFizeszk: string;
  _aktBankKod,_aktptarkod,_ixsor,_tarsbetu,_mondat: string;
  _vvpont,_cimletDarab,_darab,_sCimlet,_sDarab,_tspenztar,_fizetoeszkoz: integer;
  _aktkezdij: integer;
  _origtipus,_penztar,_blokknum,_tblokknum,_cimtar,_elohavicimtar,_fize: string;
  _kpfelvett,_kpbefizet: real;
  _kpfel,_kpbe,_ujfel: real;
  _osszFt,_ujbe,_ujki,_ujvett,_ujeladott:real;
  _aktTabla:TibTable;
  _iras: TextFile;
  _zNaps,_zznaps,_trbPenztar: string;

implementation

{$R *.dfm}


// =============================================================================
             procedure TMakeImport.FormCreate(Sender: TObject);
// =============================================================================

var i,j:integer;

begin
  Top     := _top  + 120;
  Left    := _left + 140;
  Height  := 530;
  Width   := 750;

  Uzeno.Clear;
  ExcelPrintGomb.Visible := False;
  BacktoMenugomb.Visible := False;
  Printmenupanel.Visible := false;
  
  _aktDatum := YESTERDAY;

  for i := 0 to _valutaDarab-1 do
    begin
      for j := 0 to 2 do
        begin
          _felvettval[i,j] := 0;
          _befizetettval[i,j] := 0;
        end;
    end;

  AdatBazisUrito;

  for i := 0 to 2 do _voltBankForg[i] := False;

  DecodeDate(_aktdatum,_aktEv,_aktHo,_aktNap);
  _tenyEv := _aktEv;

  EvKombo.Clear;
  HoKombo.Clear;

  for i := -2 to 0 do evKombo.Items.Add(inttostr(_aktEv+i));
  for i := 1 to 12 do hoKombo.Items.Add(_honapNev[i]);

  EvKombo.ItemIndex := 2;
  HoKombo.itemIndex := _aktHo-1;
  SetNapSzam;

end;

// =============================================================================
              procedure TMakeImport.ImportGoClick(Sender: TObject);
// =============================================================================

begin
  _targyDatum := _zNap+1;
  _znaps := leftstr(datetostr(_znap),10);

  DecodeDate(_zNap,_aktEv,_aktHo,_aktNap);
  DecodeDate(_targyDatum,_targyev,_targyho,_targynap);

  Form1.DbkControl(_zNaps);   // _dbkFile = 'DAYByymm.dbf' Indexelve !

  _aktnap := dayof(_zNap);
  _tema := 'N' + intToStr(_aktNap);

  if not Form1.TegnapControl(_zNaps) then
    begin
      ShowMessage('Még nincs benn az összes zárás !');
      exit;
    end;

  ImportCancel.Enabled := False;

// ---------- Itt minden zárás beérkezett ---------------------------------

  _exev := _aktEv;
  _exho := _aktho-1;

  if _exho=0 then
    begin
      _exho := 12;
      dec(_exev);
    end;

  _farok    := Form1.Nulele(_aktev-2000) + Form1.nulele(_aktho);
  _elofarok := Form1.Nulele(_exev-2000)  + Form1.Nulele(_exho);

  _vvpont := 1;
  while _vvpont<=_IrodaDarab do
    begin
      _aktPenztar := _irodaSzam[_vvpont-1];
      _aktBankKod := _bankkod[_aktpenztar];
      _aktcegbetu := _cegbetutomb[_aktpenztar];
      _aktfdbpath := 'c:\receptor\database\v'+inttostr(_aktpenztar)+'.fdb';
      IF not fileexists(_aktfdbPath) then
        begin
          inc(_vvpont);
          continue;
        end;

      _aktStatus  := _nstatus[_aktpenztar];
      _cegss := Form1.GetCegbetuSorszam(_aktcegbetu);

      IF _aktstatus<>'' then
        begin
          Uzeno.Lines.Add(inttostr(_aktpenztar)+'. '+_irodanev[_aktpenztar]+ ' adatainak feldolgozása ...');
          EgyVrep(_aktstatus);
        end else Uzeno.Lines.Add(inttostr(_aktpenztar)+'. '+_irodanev[_aktpenztar]+' ZÁRVA VOLT');
     
      inc(_vvpont);
    end;

  BankforgFeliro;


// ---------------- Az adatok textfile-ba irása ------------------------------

  Wimport;
  ExcelPrintGomb.Visible := True;
  BacktoMenugomb.Visible := True;
  _bankkartyas := 0;
  _bkkezdij    := 0;

end;

// =*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*


// =============================================================================
                  procedure TMakeImport.EgyVrep(_VStatus: string);
// =============================================================================
       // Egy iroda adatainak begolgozása :

begin

//  _ugyffTab := _aktdir + '\Ugyfforg.dbf';
//  _bankfTablanev := _aktdir + '\BankForg.dbf';

  // A blokkfej és blokktétetelek meglétének ellenörzése  ........

  if _vStatus='X' then  // Ha zárva volt, csak a készlete maradt a régi
    begin
      AllomPrepare;
      exit
    end;

  if (_vStatus<>'B') and (_vStatus<>'K') then exit;

// --------------------- Itt már csak a bejött adatok lehetnek --------------

  _BFTablaNev := 'BF' + _farok;
  _BTTablaNev := 'BT' + _farok;

  BlokkTabla.close;
  BlokkDbase.close;
  BlokkDbase.DatabaseName := _aktfdbPath;
  BlokkTabla.TableName := _BFtablaNev;
  BlokkDbase.Connected := true;
  if not BlokkTabla.Exists then exit;
  UgyfPrepare;   // Kitölti az ügyfél- és bankforgalmi táblázatot:
  AllomPrepare;  // Kitölti a valutaállomány cimleteit
end;


// =============================================================================
                      procedure Tmakeimport.UgyfPrePare;
// =============================================================================


var i: integer;

begin
 // Uzeno.Lines.Add('Ügyfél-, és banki forgalom bedolgozása ...');

  _pcs := 'SELECT FEJ.*,TET.*' + _sorveg;
  _pcs := _pcs + 'FROM '+ _bfTablanev+' FEJ JOIN ' + _btTablanev+' TET' + _sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM' + _sorveg;
  _pcs := _pcs + 'WHERE (FEJ.DATUM=' +chr(39) + _zNaps + chr(39) +') AND (';
  _pcs := _pcs + 'FEJ.STORNO=1)';

  BlokkDbase.close;
  Blokkdbase.DatabaseName := _aktfdbpath;

  BlokkDbase.Connected := true;
  with BlokkQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then   // Ha nincs znaps-i blokkfej akkor forgalom se volt
    begin
      BlokkQuery.Close;
      BlokkDbase.Close;
      exit;
    end;

   // ----------------------  Értékek kinullázása ------------------------------

   _voltugyfforg := false;

   for i := 0 to _valutaDarab-1 do
     begin
       _vettval[i]    := 0;
       _eladottval[i] := 0;
     end;
   _bankkartyas := 0;
   _bkkezdij    := 0;

   _forintSs := Form1.DnemScan('HUF');

(* -------- Itt kezdödik a napi forgalmi adatok bedolgozása -----------------*)

  while not BlokkQuery.Eof do
    begin
      with BlokkQuery do
        begin
          _Tipus    := FieldByName('TIPUS').asString;
          _osszFt   := FieldByName('OSSZESEN').asFloat;
          _penztar  := FieldByName('PENZTAR').asString;
          _TRBPenztar := trim(FieldbyName('TRBPENZTAR').asstring);
          _aktdnem  := FieldByName('VALUTANEM').asString;
          _bankjegy := FieldByName('BANKJEGY').asFloat;
          _elojel   := FieldByName('ELOJEL').asString;
          _ertek    := FieldByName('FORINTERTEK').asFloat;
          _fizetoeszkoz := FieldByName('FIZETOESZKOZ').asInteger;
          _aktkezdij := FieldByName('KEZELESIDIJ').asInteger;
        end;

      if _penztar='' then _penztar := 'URES' else _penztar := trim(_penztar);

      if (_penztar='TH') OR (_PENZTAR='1') then
        begin
          BlokkQuery.Next;
          Continue;
        end;

      _BQ     := 0;
      if _trbpenztar<>'' then
        begin
          // _aktcegbetu = B P vagy E (amit most elemzünk)

          val(_trbPenztar,_tspenztar,_code);
          if _code<>0 then _tsPenztar := 0;

          if _tspenztar>0 then
            begin
              _tarsbetu := _cegBetuTomb[_tsPenztar];
              if _tarsbetu<>_aktcegbetu then _bq := 1;
            end;
        end;

      // ///   _Bq := Form1.BankScan(_penztar);  // Ha Bq>0 akkor ez a társpénztár BANK !
      _ezBank := False;
      if _bq>0 then _ezBank := True
      else
        begin
          if (_tipus='U') OR (_tipus='F') then
             begin
               BlokkQuery.Next;
               Continue;
             end;
        end;

// --------------------- -------------------------------------------------------

      _valSS := Form1.DnemScan(_aktdnem);

      // Az ezbank flag jelzi, hogy ez Ugyfel vagy bank forgalma

      If _ezBank then
        begin
          _cegss := Form1.GetCegbetuSorszam(_aktcegbetu);
          _voltbankForg[_cegss] := true;

          if _tipus='U' then  _felvettVal[_valss,_cegss] := _felvettVal[_valss,_cegss] + _bankjegy
          else _befizetettval[_valss,_cegss] := _befizetettval[_valss,_cegss] + _bankjegy;

          BlokkQuery.Next;
          Continue;
        end;

      if _aktdnem='HUF' then
        begin
          BlokkQuery.Next;
          Continue;
        end;

      _voltUgyfforg := true;

      if _elojel='+' then
        begin
          _vettval[_valss] := _vettval[_valSS] + _bankjegy;
          _eladottval[_forintSS] := _eladottval[_forintSS] + _ertek;
        end else
        begin
          _eladottval[_valss] := _eladottval[_valss] + _bankjegy;
          if _fizetoeszkoz=2 then
            begin
              _bankkartyas := _bankkartyas + trunc(_ertek);
              _bkkezdij    := _bkkezdij + _aktkezdij;
              _aktkezdij   := 0;
            end else
            begin
              _vettval[_forintss] := _vettval[_forintss] + _ertek;
            end;

        end;
      BlokkQuery.Next;
    end;

  BlokkQuery.Close;
  BlokkDbase.close;

  // ---------------------------------------------------------------------------

  if _voltugyfforg then
    begin
      _valss := 0;
      while _valss<_valutadaraB do
        begin
          _aktdnem := _dnem[_valss];
          if (_eladottval[_valss]>0) or (_vettval[_valss]>0) then
            begin
              _pcs := 'INSERT INTO SUMUGYFELFORGALOM (IRODASZAM,CEGBETU,BANKKOD,';
              _pcs := _pcs + 'BANKDNEM,VALUTANEM,ELADOTT,VETT,';
              _pcs := _pcs + 'BANKKARTYAS,BKKEZDIJ)'+_sorveg;
              _pcs := _pcs + 'VALUES ('+inttostr(_aktpenztar)+',';
              _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',';
              _PCS := _Pcs + chr(39) + _aktbankkod + chr(39) + ',';
              _pcs := _pcs + chr(39) + _aktbankkod+_aktdnem + chr(39)+ ',';
              _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
              _pcs := _pcs + Form1.realtostr(_eladottval[_valss]) + ',';
              _pcs := _Pcs + Form1.realtostr(_vettval[_valss])+ ')';

              ReceptorDbase.Connected := true;
              if ReceptorTranz.InTransaction then ReceptorTranz.Commit;
              ReceptorTranz.StartTransaction;
              with ReceptorQuery do
                begin
                  Close;
                  Sql.Clear;
                  Sql.Add(_pcs);
                  Execsql;
                end;
              ReceptorTranz.Commit;
              ReceptorDbase.close;
            end;
          inc(_valss);
        end;
    end;
end;


// =============================================================================
                   procedure TMakeImport.BankForgFeliro;
// =============================================================================

begin
  ReceptorDbase.Connected := true;
  if ReceptorTranz.InTransaction then ReceptorTranz.Commit;
  ReceptorTranz.StartTransaction;
  _cegss := 0;
  while _cegss<3 do
    begin
      _aktcegbetu := _cegBetuk[_cegss];    // B  P  E

      if _voltbankforg[_cegss] then
        begin
          _valss := 0;
          while _valss<_valutaDarab do
            begin
              _aktdnem := _dnem[_valss];
              if (_felvettval[_valss,_cegss]>0) or (_befizetettval[_valss,_cegss]>0) then
                begin
                  _pcs := 'INSERT INTO SUMBANKFORGALOM (VALUTANEM,CEGBETU,FELVETTKP,';
                  _pcs := _pcs + 'BEFIZETETTKP)' + _sorveg;
                  _pcs := _pcs + 'VALUES ('+chr(39)+_aktdnem+chr(39)+',';
                  _pcs := _pcs + chr(39)+_aktcegbetu+chr(39)+',';
                  _pcs := _pcs + Form1.realtostr(_felvettval[_valss,_cegss]) + ',';
                  _pcs := _pcs + Form1.realtostr(_befizetettval[_valss,_cegss])+')';
                  with ReceptorQuery do
                    begin
                      Close;
                      sql.Clear;
                      sql.Add(_pcs);
                      Execsql;
                    end;
                end;
              inc(_valss);
            end;
        end;
      inc(_cegss);
    end;
  ReceptorTranz.commit;
  ReceptorDbase.close;
end;



// =============================================================================
                     procedure TMakeImport.AllomPrepare;
// =============================================================================
  // A valutakészlet - állomány bedolgozása

var i:integer;

begin
   // A cimtárból vesszük az adatokat:

   _cimTar := 'CIMT'+_farok;
   _elohavicimtar := 'CIMT' + _elofarok;

  // Uzeno.Lines.Add('Péntárállomány bedolgozása ...');

   with CimtarDbase do
     begin
       Connected := False;
       DatabaseName := _aktfdbPath;
       Connected := true;
     end;

   CimtarTabla.TableName := _cimtar;

   // Ha nincs e-havi cimtár, akkor az elözöhavi utolsó cimletek a jók

   if not CimtarTabla.Exists then
     begin
       ElsoNapiKeszlet;
       exit;
     end;

   // Megnyitja az e-havi cimleteket:

   _pcs := 'Select * FROM '+ _CIMTAR;
   _pcs := _pcs + ' WHERE DATUM<=' + chr(39)+_znaps+chr(39);
   _pcs := _pcs + ' ORDER BY DATUM';
   with CimtarQuery do
     begin
       Close;
       Sql.Clear;
       Sql.Add(_pcs);
       Open;
     end;

   if CimtarQuery.Eof then
     begin
       ElsoNapiKeszlet;
       exit;
     end;

  // Kiovassa a megtalált nap dátumát:

  CimtarQuery.Last;
  _zznaps := CimtarqUERY.FieldByName('DATUM').asString;
  _pcs := 'Select * FROM '+ _CIMTAR;
   _pcs := _pcs + ' WHERE DATUM=' + chr(39)+_zZnaps+chr(39);
   with CimtarQuery do
     begin
       Close;
       Sql.Clear;
       Sql.Add(_pcs);
       Open;
     end;

   // Végigolvassa a napra szürt cimlettárat:

   while not CimtarqUERY.Eof do
     begin
       _aktdnem := CimtarQuery.FieldByName('VALUTANEM').asString;
       for i := 1 to 14 do
         begin
           _tema := 'CIMLET' + Inttostr(i);
           _aktcimlet := _cimlet[i];
           _ixsor := _aktbankkod+_aktdnem+otnulla(_aktcimlet);
           _darab := CimTarQuery.FieldByNAme(_tema).asInteger;

       //    if (i=14) and (_aktdnem='HUF') and (_bankkartya>0) then
        //           _darab := _bankkartya;

           if _darab>0 then
             begin
               _pcs := 'INSERT INTO SUMALLOMANY (IRODASZAM,CEGBETU,BANKKOD,';
               _pcs := _pcs + 'BANKDNEMCIM,VALUTANEM,CIMLET,DARAB)' + _sorveg;
               _pcs := _pcs + 'VALUES (' + inttostr(_aktpenztar) +',';
               _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',';
               _pcs := _pcs + chr(39) + _aktbankkod + chr(39) + ',';
               _pcs := _pcs + chr(39) + _ixSor + chr(39) + ',';
               _PCS := _pcs + chr(39) + _aktdnem + chr(39) + ',';
               _pcs := _pcs + inttostr(_aktcimlet) + ',';
               _pcs := _pcs + inttostr(_darab) + ')';

               ReceptorDbase.Connected := true;
               if receptorTranz.InTransaction then ReceptorTranz.Commit;
               ReceptorTranz.StartTransaction;
               with receptorquery do
                 begin
                   Close;
                   sql.Clear;
                   sql.Add(_pcs);
                   Execsql;
                 end;
               ReceptorTranz.Commit;
               receptorDbase.close;
             end;
         end;
      CimtarQuery.Next;
    end;

  // Az állománytábla fel van töltve a cimletekkel:

  CimtarQuery.close;
  CimtarDbase.close;
end;

// =============================================================================
            function TMakeImport.Otnulla(_cci: integer):string;
// =============================================================================

var _cnum: integer;
begin
  _cnum := 20000-_cci;
  result := inttostr(_cnum);
  while length(result)<5 do result := '0'+result;
end;


// =============================================================================
                     procedure TMakeImport.ElsoNapiKeszlet;
// =============================================================================

var i:integer;

begin

  CimtarTabla.close;
  CimtarTabla.TableName := _elohaviCimtar;

  // Ha még elöhavi sincs, akkor nincs készlet

  if not CimtarTabla.Exists then exit;

  // Megnyitja az elözöhavi cimlettárat, és az utolsó napra lép:

  _pcs := 'Select * FROM '+ _elohaviCimtar+' ORDER BY DATUM';
   with CimtarQuery do
     begin
       Close;
       Sql.Clear;
       Sql.Add(_pcs);
       Open;
       Last;
     end;
   if CimtarQuery.Recno=0 then
     begin
       CimtarQuery.Close;
       Exit;
     end;

 // Kiolvassa az elözö hónap utolsó napi dátumát:

  _zznaps := CimtarQuery.FieldByName('DATUM').asString;
  _pcs := 'SELECT * FROM '+_elohavicimtar+' WHERE DATUM='+chr(39)+_zznaps+chr(39);
  with CimtarQuery do
     begin
       Close;
       Sql.Clear;
       Sql.Add(_pcs);
       Open;
     end;

  while not CimtarQuery.Eof do
    begin
      _aktdnem := cimtarQuery.FieldByName('VALUTANEM').asString;
      for i := 1 to 14 do
        begin
          _tema := 'CIMLET' + inttostr(i);
          _aktcimlet := _cimlet[i];
          _darab := CimtarQuery.FieldByName(_tema).asInteger;
          _ixsor := _aktbankkod+_aktdnem+otnulla(_aktcimlet);

          if _darab>0 then
            begin
               _pcs := 'INSERT INTO SUMALLOMANY (IRODASZAM,CEGBETU,BANKKOD,';
               _pcs := _pcs + 'BANKDNEMCIM,VALUTANEM,CIMLET,DARAB)' + _sorveg;
               _pcs := _pcs + 'VALUES (' + inttostr(_aktpenztar) +',';
               _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',';
               _pcs := _pcs + chr(39) + _aktbankkod + chr(39) + ',';
               _pcs := _pcs + chr(39) + _ixSor + chr(39) + ',';
               _PCS := _pcs + chr(39) + _aktdnem + chr(39) + ',';
               _pcs := _pcs + inttostr(_aktcimlet) + ',';
               _pcs := _pcs + inttostr(_darab) + ')';

               ReceptorDbase.Connected := true;
               if receptorTranz.InTransaction then ReceptorTranz.Commit;
               ReceptorTranz.StartTransaction;
               with receptorquery do
                 begin
                   Close;
                   sql.Clear;
                   sql.Add(_pcs);
                   Execsql;
                 end;
               ReceptorTranz.Commit;
               ReceptorDbase.close;
            end;
        end;
      CimtarQuery.Next;
    end;

  CimtarQuery.close;
  CimtarDbase.close;
end;

// =============================================================================
                       procedure TMakeImport.WIMPORT;
// =============================================================================


var _textNev,_mondat,_tnap,_aktazonosito,_aktvaltonev: string;

begin
   _CEGSS := 0;
   while _cegss<3 do
     begin
       _aktcegBetu := _cegBetuk[_cegss];
       _aktvaltonev := trim(_valtonev[_cegss]);
       _AktAzonosito  := trim(Form1.Kieg(_azonosito[_cegss],8));
       _textNev    := 'C:\RECEPTOR\MAIL\BANKOUT\'+ _subdir[_cegss]+'\'+
                       _impId[_cegss] +
                       Form1.Nulele(_aktev-2000)+
                       Form1.Nulele(_aktho)+ Form1.Nulele(_aktnap)+'.txt';

       Uzeno.Lines.Add(dupestring('-',70));
       Uzeno.Lines.Add(_aktvaltonev +' IMPORT FILE IRÁSÁT MEGKEZDTEM !');
       DeleteFile(_textNev);
       AssignFile(_iras,_textNev);
       Rewrite(_iras);

       _mondat := '# ' + _aktvaltonev + ' - ' + inttostr(_aktev)+' '+ _honapnev[_aktho]+' '+inttostr(_aktnap)+_sorveg;
       write(_iras,_mondat);
       write(_iras,_sorveg);
       write(_iras,'BEGIN'+_SORVEG);

       _tNap := 'TNAP'+CHR(9)+inttostr(_targyev)+'-'+Form1.Nulele(_targyho)+'-'+Form1.Nulele(_targynap);
       write(_iras,_tnap+_sorveg+_sorveg);

       _mondat := '# ' + TRIM(_valtonev[_cegss]) + _sorveg;
       write(_iras,_mondat);

       _mondat := 'PV_AZONOSITO'+chr(9)+_aktazonosito+_sorveg;
       write(_iras,_mondat);

   // ----------------

       AllomanyIras;
       UgyfelforgIras;
   //    BankForgIras;

   // ----------------

       write(_iras,'END'+_SORVEG);
       CloseFile(_iras);

       inc(_cegss);
     end;

   // --------------------------------------------------------------------------

   _datums := datetostr(_zNap);
   ExceltablaKeszito;

   Uzeno.Lines.Add(dupestring('-',70));
   Uzeno.Lines.Add('AZ IMPORTFILE LÉTREHOZÁSA BEFEJEZÖDÖTT !');
   Uzeno.Lines.Add(dupestring('-',70));
end;


// =============================================================================
                      procedure TMakeImport.AllomanyIras;
// =============================================================================

var _idopont: string;
begin

  _pcs := 'SELECT * FROM SUMALLOMANY' + _sorveg;
  _pcs := _PCS + 'WHERE CEGBETU='+chr(39) + _aktcegbetu + chr(39) + _sorveg;
  _pcs := _pcs + 'ORDER BY BANKDNEMCIM';

  ReceptorDbase.Connected := True;
  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  _utBkod := 'XXXX';
  _vanJelentes := False;

  while not ReceptorQuery.Eof do
    begin
      with ReceptorQuery do
        begin
          _aktdnem    := FieldByNAme('VALUTANEM').asstring;
          _scimlet    := FieldByName('CIMLET').asInteger;
          _sDarab     := FieldByName('DARAB').asInteger;
          _aktbankKod := FieldByName('BANKKOD').asString;
        end;

      _fize := 'KP';
      _aktbankKod := Form1.Kieg(_aktBankKod,4);

      // -----------------------------------------------------------------------

      if _aktbankKod<>_utBkod then
        begin
          if _vanJelentes then write(_iras,'JELENTES END'+_SORVEG);
          write(_iras,_sorveg+'JELENTES PENZTARALLOMANY'+_sorveg);

          _vanJelentes := True;
          _utBKod      := _aktbankKod;

          write(_iras,'UZLETHELYISEG_AZONOSITO'+CHR(9)+_aktBankKod+_sorveg);
          write(_iras,'ERTEKNAP'+chr(9)+'-1'+_sorveg);
          _idopont := SetIdoStr();
          write(_iras,'IDOPONT'+chr(9)+_idopont+_sorveg);
        end;

      write(_iras,_fize+chr(9)+_aktdnem+chr(9)+inttostr(_scimlet)+chr(9)+inttostr(_sDarab)+_sorveg);
      ReceptorQuery.Next;
    end;
  if _vanJelentes=True then write(_iras,'JELENTES END');
  write(_iras,_sorveg);
  ReceptorQuery.Close;
  ReceptorDbase.close;
end;


// =============================================================================
                   procedure TMakeImport.UgyfelForgIras;
// =============================================================================

var _xps: string;

begin
  _vanJelentes := False;
  _xps := 'BANKKOD+DNEM';
  _utbkod := 'XXX';

  _pcs := 'SELECT * FROM SUMUGYFELFORGALOM' + _sorveg;
  _pcs := _pcs + 'WHERE CEGBETU='+CHR(39)+_aktcegbetu+chr(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY BANKDNEM';

  Receptordbase.Connected := True;
  with ReceptorQuery do
    begin
      Close;
      Sql.clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  write(_iras,_sorveg);
  while not ReceptorQuery.Eof do
    begin
      with ReceptorQuery do
        begin
          _aktdnem := FieldByName('VALUTANEM').asString;
          _eladott := FieldByName('ELADOTT').asFloat;
          _vett    := FieldByName('VETT').asFloat;
          _bankkartyas := FieldbyName('BANKKARTYAS').asInteger;
          _bkkezdij := FieldByName('BKKEZDIJ').asInteger;
        end;

      if _aktdnem='' then
        begin
          ReceptorQuery.Next;
          Continue;
        end;

      _aktbankKod := ReceptorQuery.FieldByNAme('BANKKOD').asString;
      _aktbankKod := Form1.Kieg(_aktbankKod,4);

      if _utbKod<>_aktbankKod then
        begin
          if _vanJelentes=True then write(_iras,'JELENTES END'+_SORVEG+_sorveg);
          write(_iras,'JELENTES UGYFELFORGALOM'+_sorveg);
          _vanJelentes := True;
          _utbKod := _aktBankKod;
          write(_iras,'UZLETHELYISEG_AZONOSITO'+chr(9)+_aktbankKod+_sorveg);
          write(_iras,'ERTEKNAP'+chr(9)+'-1'+_sorveg);
        end;

  //    write(_iras,_aktdnem+chr(9)+floattostr(_eladott)+chr(9)+floattostr(_vett)+chr(9)+
  //                           '0' + _sorveg);

      _mondat := _aktdnem+chr(9)+floattostr(_eladott)+chr(9)+floattostr(_vett)+chr(9)+'0';
      if _aktdnem='HUF' then
         begin
           _mondat := _mondat + chr(9)+inttostr(_bankkartyas)+chr(9)+inttostr(_bkkezdij);
         end else
         begin
           _mondat := _mondat + chr(9)+'0'+chr(9)+'0';
         end;
      writeLn(_iras,_mondat);
      ReceptorQuery.Next;
    end;
  if _vanJelentes=True then write(_iras,'JELENTES END');
  write(_iras,_sorveg);

  ReceptorQuery.close;
  ReceptorDbase.close;
end;


// =============================================================================
                    procedure TMakeImport.BankForgIras;
// =============================================================================

begin

  _pcs := 'SELECT * FROM SUMBANKFORGALOM' + _sorveg;
  _pcs := _pcs + 'WHERE CEGBETU='+chr(39)+_aktcegbetu+chr(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  ReceptorDbase.Connected := True;
  with ReceptorQuery do
    begin
      Close;
      Sql.clear;
      sql.Add(_pcs);
      Open;
      First;
      _recno := recno;
    end;
    
  if _recno=0 then
    begin
      ReceptorQuery.Close;
      ReceptorDbase.close;
      exit;
    end;

  write(_iras,_sorveg);
  write(_iras,'JELENTES BANKIFORGALOM'+_sorveg);
  write(_iras,'ERTEKNAP'+chr(9)+'-1'+_sorveg);

  while not ReceptorQuery.Eof do
    begin
      with ReceptorQuery do
        begin
          _aktdnem := FieldByName('VALUTANEM').asString;
          _kpfelvett := FieldByName('FELVETTKP').asFloat;
          _kpbefizet := FieldByName('BEFIZETETTKP').asFloat;
        end;
      write(_iras,_aktdnem+chr(9)+floattostr(_kpfelvett)+chr(9)+floattostr(_kpbefizet)+chr(9)+
                        '0' + _sorveg);
      ReceptorQuery.Next;
    end;
  Write(_iras,'JELENTES END'+_sorveg);
  ReceptorQuery.close;
  ReceptorDbase.close;
end;


// =============================================================================
           procedure TMAKEIMPORT.IMPORTCANCELClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 2;
end;

// =============================================================================
                      procedure TMakeImport.SetNapszam;
// =============================================================================

var i:integer;

begin
  _houtolsonap := daysinamonth(_aktev,_aktho);
  NapKombo.Clear;
  for i := 1 to _houtolsonap do NapKombo.items.Add(inttostr(i));
  napkombo.ItemIndex := _aktnap-1;
  _ZNap := encodeDate(_aktev,_aktho,_aktnap);
  _hnap := dayoftheweek(_zNap);
  NapNevPanel.Caption := uppercase(_napnev[_hnap]);
  ActiveControl := ImportGo;
end;

// =============================================================================
             procedure TMAKEIMPORT.EVKOMBOChange(Sender: TObject);
// =============================================================================

var _evDiff: integer;
begin
    _evdiff := evkombo.ItemIndex-2;
   _aktev := _tenyev + _evdiff;
   _aktnap := 1;
   Setnapszam;
end;

// =============================================================================
                procedure TMAKEIMPORT.HOKOMBOChange(Sender: TObject);
// =============================================================================

begin
   _aktho := Hokombo.ItemIndex + 1;
   _aktnap := 1;
   Setnapszam;
end;

// =============================================================================
             procedure TMAKEIMPORT.NAPKOMBOChange(Sender: TObject);
// =============================================================================

begin
  _aktnap := NapKombo.ItemIndex + 1;
  SetNapSzam;
end;


// =============================================================================
             function TMakeImport.Cimtarseek(_nap: String):boolean;
// =============================================================================

var _aDatum: string;

begin
   // Keresi a paraméterben megadott napot:

   Result := False;

   _recno := Cimtartabla.RecNo;
   while not Cimtartabla.Eof do
     begin
       _adatum := cimtartabla.FieldByName('DATUM').asString;
       if _adatum=_nap then
         begin
           result := True;
           exit;
         end;
       if _adatum>_nap then break;
       CimtarTabla.Next;
     end;
end;

// =============================================================================
                   function TMakeImport.SetidoStr:string;
// =============================================================================

var _ido: string;

begin
  _ido := timetostr(time());
  if midstr(_ido,2,1)=':' then _ido := ' '+_ido;
  result := leftstr(_ido,5);
end;


// =============================================================================
                      procedure TMakeImport.AdatbazisUrito;
// =============================================================================

begin
  ReceptorDbase.Connected := true;
  if ReceptorTranz.InTransaction then ReceptorTranz.Commit;
  ReceptorTranz.StartTransaction;
  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add('DELETE FROM SUMALLOMANY');
      execsql;
    end;
  Receptortranz.Commit;
  Receptordbase.close;

  // -------------------------------------------------------

  ReceptorDbase.Connected := true;
  ReceptorTranz.StartTransaction;
  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add('DELETE FROM SUMBANKFORGALOM');
      execsql;
    end;
  Receptortranz.Commit;
  Receptordbase.close;

  // -------------------------------------------------------

  ReceptorDbase.Connected := true;
  ReceptorTranz.StartTransaction;
  with ReceptorQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add('DELETE FROM SUMUGYFELFORGALOM');
      execsql;
    end;
  Receptortranz.Commit;
  Receptordbase.close;
end;

// =============================================================================
                  procedure TMakeImport.ExcelTablaKeszito;
// =============================================================================

begin
  Uzeno.Lines.add('EAST CHANGE TRB EXCELTÁBLA KÉSZÍTÉSE');
  MakeTrbexcel('EAST');
  Uzeno.Lines.add('BEST CHANGE TRB EXCELTÁBLA KÉSZÍTÉSE');
  MakeTRBexcel('BEST');
  Uzeno.Lines.add('PANNON CHANGE TRB EXCELTÁBLA KÉSZÍTÉSE');
  MakeTRBExcel('PANNON');
  Uzeno.Lines.Add('MINDHÁROM KFT EXCELTÁBLA ELKÉSZÜLT');
end;

procedure TMakeImport.MakeTRBExcel(_akft: string);

var _kbetu : string;

begin
  
  _kbetu := leftstr(_akft,1);
  _exceltabla := CreateOleObject('Excel.Application');

  _sajatexcel := _exceltabla.workbooks.add[1];
  _sajatexcel.activate;

  _range := _exceltabla.Range['A2:D2'];
  _range.Select;
  _range.columnwidth := 22;


  _range.Font.Name := 'Arial';
  _range.Font.Size := 14;
  _range.Font.Bold := True;
  _range.Font.Italic := true;
  _range.Mergecells := true;


  _excelTabla.cells[2,1] := 'EXCLUSIVE '+_akft+' CHANGE TRB TRANZAKCIÓI';
  _exceltabla.cells[2,1].HorizontalAlignment := -4108;

  
  _range := _exceltabla.Range['A4:D4'];
  _range.Select;
  _range.Font.Size := 10;
  _range.Font.Bold := True;
  _range.columnwidth := 22;
  _range.HorizontalAlignment := -4108;

  _exceltabla.cells[4,1] := 'DÁTUM';
  _exceltabla.cells[4,2] := 'VALUTANEM';
  _exceltabla.cells[4,3] := 'FELVETT ÖSSZEG';
  _exceltabla.cells[4,4] := 'KIFIZETETT ÖSSZEG';

  _range := _exceltabla.Range['A5:B25'];
  _range.Select;
  _range.Font.Size := 10;
  _range.Font.Bold := False;
  _range.HorizontalAlignment := -4108;

  _range := _exceltabla.Range['C4:D25'];
  _range.Select;
  _range.numberformat := '### ### ###';


  _PATH := 'C:\RECEPTOR\MAIL\POSTA\'+ _AKFT + '_';
  _path := _path + Form1.Nulele(_aktev-2000);
  _path := _path + Form1.Nulele(_aktho)+ Form1.Nulele(_aktnap)+'.xls';

  if FileExists(_path) then DeleteFile(_path);


  Sbankforgdbase.Connected := true;
  _pcs := 'SELECT * FROM SUMBANKFORGALOM' + _sorveg;
  _pcs := _pcs + 'WHERE CEGBETU='+chr(39)+_kBetu+chr(39);

  with SbankforgQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
    end;

  _cc := 0;
  while not SbankforgQuery.eof do
    begin
      _aktdnem := SbankForgQuery.FieldByNAme('VALUTANEM').asString;
      _KIkp := SbankforgQuery.FieldByName('BEFIZETETTKP').asInteger;
      _bekp := SbankForgQuery.FieldByName('FELVETTKP').asInteger;
      _aktsor := 5+_cc;
      _excelTabla.cells[_aktsor,1] := _datums;
      _excelTabla.cells[_aktsor,2] := _aktdnem;
      _excelTabla.cells[_aktsor,3] := inttostr(_bekp);
      _excelTabla.cells[_aktsor,4] := inttostr(_kikp);
      inc(_cc);
      SbankForgQuery.next;
    end;

  SbankForgQuery.close;
  SbankForgdbase.close;


  _sajatexcel.saveas(_Path);
  _excelTabla.activeworkBook.close;
  _exceltabla.Quit;
  _exceltabla := unassigned;
end;


procedure TMAKEIMPORT.EXCELPRINTGOMBClick(Sender: TObject);
begin
  with PrintMenupanel do
    begin
       Top := 296;
      Left := 136;
      VIsible := true;
    end;
end;


procedure TMAKEIMPORT.BitBtn1Click(Sender: TObject);

var _kftIndex: integer;
    _ykft: string;
begin
  _kftindex := TBitbtn(sender).Tag;
  _ykft := _subdir[_kftindex];

  _PATH := 'C:\RECEPTOR\MAIL\POSTA\'+ _yKFT + '_';
  _path := _path + Form1.Nulele(_aktev-2000);
  _path := _path + Form1.Nulele(_aktho)+ Form1.Nulele(_aktnap)+'.xls';

  _exceltabla := CreateOleObject('Excel.Application');
  _sajatexcel := _exceltabla.workbooks.Open(_path);

  if PrintDialog1.Execute then  _sajatexcel.PrintOut;
  _excelTabla.activeworkBook.close;
  _exceltabla.Quit;
  _exceltabla := unassigned;
end;

procedure TMAKEIMPORT.BACKTOMENUGOMBClick(Sender: TObject);
begin
  Modalresult := 1;
end;

end.
