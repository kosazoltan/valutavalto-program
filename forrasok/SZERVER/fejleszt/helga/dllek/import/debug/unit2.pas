unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, DateUtils, DB, DBTables, StrUtils,
  IBDatabase, IBCustomDataSet, IBTable, IBQuery, ComObj,Excel97, Oleserver,
  Printers, jpeg;

type
  TMAKEIMPORT = class(TForm)

    ArtQuery        : TIBQuery;
    ArtDbase        : TIBDatabase;
    ArtTranz        : TIBTransaction;

    AcTabla         : TIBTable;
    AcDbase         : TIBDatabase;
    AcTranz         : TIBTransaction;

    BlokkTabla      : TIBTable;
    BlokkQuery      : TIBQuery;
    BlokkDbase      : TIBDatabase;
    BlokkTranz      : TIBTransaction;

    CimtarTabla     : TIBTable;
    CimtarQuery     : TIBQuery;
    CimtarDbase     : TIBDatabase;
    CimtarTranz     : TIBTransaction;

    DaybookTabla    : TIBTable;
    DaybookDbase    : TIBDatabase;
    DaybookTranz    : TIBTransaction;

    ReceptorQuery   : TIBQuery;
    ReceptorDbase   : TIBDatabase;
    ReceptorTranz   : TIBTransaction;

    NapnevPanel     : TPanel;
    Panel1          : TPanel;

    Shape1          : TShape;
    Shape2          : TShape;
    Shape3          : TShape;
    Shape5          : TShape;
    Shape6          : TShape;
    Shape7          : TShape;

    Label1          : TLabel;
    Label2          : TLabel;
    Label3          : TLabel;

    EvKombo         : TComboBox;
    HoKombo         : TComboBox;
    NapKombo        : TComboBox;

    BackToMenuGomb  : TBitBtn;
    ImportCancel    : TBitBtn;
    ImportGo        : TBitBtn;

    Uzeno           : TMemo;
    PrintDialog1    : TPrintDialog;
    Image1          : TImage;


    procedure AdatbazisUrito;
    procedure AllomanyIras;
    procedure AllomPrepare;
    procedure BackToMenuGombClick(Sender: TObject);
    procedure Bankforgfeliro;
    procedure BankForgIras;
 
    procedure CimletGyujto;
    procedure ElsoNapiKeszlet;
    procedure EvKomboChange(Sender: TObject);
    procedure ForgalomGyujto;
    procedure FormCreate(Sender: TObject);
    procedure HoKomboChange(Sender: TObject);
    procedure ImportCancelClick(Sender: TObject);
    procedure ImportGoClick(Sender: TObject);
    procedure IrodaBeolvasas;
    procedure NapKomboChange(Sender: TObject);
    procedure ReceptorParancs(_ukaz: string);
    procedure SetNapszam;
    procedure UgyfelForgIras;
    procedure WImport;

    function Cimtarseek(_nap: string):boolean;
    function DnemScan(_vn: string):integer;
    function Kerekito(_real: real): real;
    function Nulele(_b: byte): string;
    function Otnulla(_cci: integer):string;
    function Setidostr: string;
    function TegnapControl(_datums:string): boolean;
  
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MakeImport: TMakeImport;

  _top,_left,_height,_width,_irodaDarab: word;

  _honapnev: array[1..12] of string = ('Január','Február','Március','Április',
               'Május','Junius','Július','Augusztus','Szeptember','Október',
               'November','December');

  _napnev: array[1..7] of string = ('HÉTFÕ','KEDD','SZERDA','CSÜTÖRTÖK','PÉNTEK',
               'SZOMBAT','VASÁRNAP');


  _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                                   'CZK','DKK','EUR','GBP','HRK','HUF','ILS',
                                   'JPY','MXN','NOK','NZD','PLN','RON','RSD',
                                   'RUB','SEK','THB','TRY','UAH','USD');


  _kertdatum: TDateTime;
  _aktTabla : TibTable;

  _cegBetuk: array[1..2] of string = ('B','Z');
  _subdir  : array[1..2] of string = ('BEST','ZALOG');

  _valtonev: array[1..2] of string = ('EXCLUSIVE BEST CHANGE','EXPRESSZ ÉKSZERHÁZ');
  _azonosito: array[1..2] of string = ('107746  ','A0AYTS  ');

  _cimlet: array[1..14] of integer = (20000,10000,5000,2000,1000,500,200,
                                       100,50,20,10,5,2,1);

  _vettVal,_eladottval,_bkeladott: array[1..27] of real;
  _felvettval,_befizetettval     : array[1..27,1..2] of real;

  _irodanev,_cegbetu,_bankkod,_nstatus: array[1..170] of string;

  _irodaszam   : array[1..170] of byte;
  _missPenztar : array[1..30] of byte;
  _voltBankForg: array[1..2] of Boolean;

  _sorveg     : string = chr(13)+chr(10);
  _valutaDarab: byte = 27;

  _host: string = '185.43.207.99';

  _aktPenztar,_cc,_cegss,_bq,_css: byte;

  _ezBank,_vanJelentes,_ezEdit,_voltugyfforg,_vanhiany: Boolean;

  _bfTablaNev,_btTablanev,_pcs,_path,_kertdatums,_textnev,_mondat      : string;
  _zznap,_adatum,_datums,_tema,_farok,_elofarok,_utbiz,_aktpath        : string;
  _adat,_aktStatus,_ugyff,_bankf,_stblokk,_regiblokk,_utBKod,_sFizeszk : string;
  _aktBankKod,_aktptarkod,_ixsor,_tarsbetu,_aktdnem,_tipus,_elojel     : string;
  _origtipus,_penztar,_blokknum,_tblokknum,_cimtar,_elohavicimtar,_fize: string;
  _aktcegbetu,_aktfdbPath,_aktpenztarNev,_hianystring,_bizonylatszam   : string;
  _zNaps,_zznaps,_trbPenztar,_xCim,_dataPath                           : string;

  _targyDatum: TDateTime;

  _tenyev,_kertev,_kertho,_kertnap,_hnap,_houtolsonap,_exev,_exho,_exnap: word;
  _targyEv,_targyho,_targynap: word;

  _excelTabla,_sajatexcel,_range: variant;

  _bkkezdij,_hufIndex,_valutaIndex,_recno,_rcc,_bekp,_kikp,_aktsor: integer;
  _vvpont,_cimletDarab,_darab,_sCimlet,_sDarab,_tspenztar,_fizetoeszkoz: integer;
  _kpfelvett,_kpbefizet,_code,_bankjegy,_ertek,_aktkezdij: integer;
  _kpfel,_kpbe,_ujfel,_bkadott,_kerekites: integer;
  _osszFt,_ujbe,_ujki,_ujvett,_ujeladott,_aktcimlet,_eladott,_vett: integer;

  _bke,_bankkartyas: real;

  _iras: TextFile;

function importfelirorutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
                function importfelirorutin: integer; stdcall;
// =============================================================================
begin
  MakeImport := TMakeImport.Create(Nil);
  result := Makeimport.ShowModal;
  MakeImport.Free;
end;

// =============================================================================
             procedure TMakeImport.FormCreate(Sender: TObject);
// =============================================================================

var i,j:integer;

begin

  Top     := 158;
  Left    := 208;
  Height  := 684;
  Width   := 864;

  Uzeno.Clear;
  
  BacktoMenugomb.Visible := False;
  _kertDatum := YESTERDAY;

  _kertev  := yearof(_kertdatum);
  _kertho  := monthof(_kertdatum);
  _kertnap := dayof(_kertdatum);

  for i := 1 to 27 do
    begin
      for j := 1 to 2 do
        begin
          _felvettval[i,j] := 0;
          _befizetettval[i,j] := 0;
        end;
    end;

  AdatBazisUrito;
  IrodaBeolvasas;

  for i := 1 to 2 do _voltBankForg[i] := False;

  _tenyEv := _kertEv;

  EvKombo.Clear;
  HoKombo.Clear;

  for i := -2 to 0 do evKombo.Items.Add(inttostr(_kertEv+i));
  for i := 1 to 12 do hoKombo.Items.Add(_honapNev[i]);

  EvKombo.ItemIndex := 2;
  HoKombo.itemIndex := _kertHo-1;
  SetNapSzam;

end;

// =============================================================================
              procedure TMakeImport.ImportGoClick(Sender: TObject);
// =============================================================================

var _naps: string;
    _napindex: integer;

begin
  _kertev   := _tenyev-2+evKombo.ItemIndex;
  _kertho   := 1+Hokombo.ItemIndex;
  _napindex := NapKombo.itemIndex;
  _naps     := trim(Napkombo.Items[_napindex]);

  val(_naps,_kertnap,_code);

  _kertdatum  := encodedate(_kertev,_kertho,_kertnap);
  _kertdatums := inttostr(_kertev)+'.'+nulele(_kertho)+'.'+nulele(_kertnap);
  _targyDatum := _kertDatum+1;
  _targyev    := yearof(_targydatum);
  _targyho    := monthof(_targydatum);
  _targynap   := dayof(_targydatum);
  _tema       := 'N' + _Naps;

  if not TegnapControl(_kertdatums) then
    begin
      ShowMessage('Még nincs benn az összes zárás !');
      exit;
    end;

  ImportCancel.Enabled := False;

// ---------- Itt minden zárás beérkezett ---------------------------------

  _exev := _kertEv;
  _exho := _kertho-1;

  if _exho=0 then
    begin
      _exho := 12;
      dec(_exev);
    end;

  _farok    := Nulele(_kertev-2000) + nulele(_kertho);
  _elofarok := Nulele(_exev-2000)  + Nulele(_exho);

  _hufindex := Dnemscan('HUF');

  _cc := 1;
  while _cc<=_IrodaDarab do  // végig a nyitott irodákon    closed='N'
    begin
      _cegss      := 1;
      _aktcegbetu := 'B';

      _aktPenztar    := _irodaSzam[_cc];
      _aktBankKod    := _bankkod[_aktpenztar];
      _aktpenztarnev := _irodanev[_aktpenztar];
      _datapath      := '\database\V' + inttostr(_aktpenztar) + '.fdb';

      _aktfdbPath    := _host + ':c:\receptor' + _dataPath;
      if _aktpenztar>150 then
        begin
          _aktfdbPath := _host +':c:\cartcash' + _datapath;
          _cegss := 2;
          _aktcegbetu := 'Z';
        end;

      Blokkdbase.close;
      Blokkdbase.DatabaseName := _aktfdbPath;
      TRY
        Blokkdbase.Connected := True;
      EXCEPT
        inc(_cc);
        Continue;
      END;

      Blokkdbase.close;

      // -----------------------------------------------------------------------

      _aktStatus  := _nstatus[_aktpenztar];

      if _aktstatus='B' then Forgalomgyujto;

      CimletGyujto;

      Uzeno.Lines.Add(inttostr(_aktpenztar)+'. '+_irodanev[_aktpenztar]+ ' adatainak feldolgozása ...');

      inc(_cc);
    end;

  BankforgFeliro;

// ---------------- Az adatok textfile-ba irása ------------------------------

  Wimport;
  BacktoMenugomb.Visible := True;

  _bankkartyas := 0;
  _bkkezdij    := 0;
end;


// =============================================================================
                   procedure TMakeImport.BankForgFeliro;
// =============================================================================

begin
  ReceptorDbase.Close;
  _cegss := 1;
  while _cegss<=2 do
    begin
      _aktcegbetu := _CEGbetuk[_cegss];

      if _voltbankforg[_cegss] then
        begin
          _valutaIndex := 1;
          while _valutaIndex<=_valutaDarab do
            begin
              _aktdnem := _dnem[_valutaIndex];
              if (_felvettval[_valutaIndex,_cegss]>0) or (_befizetettval[_valutaIndex,_cegss]>0) then
                begin
                  _pcs := 'INSERT INTO SUMBANKFORGALOM (VALUTANEM,CEGBETU,FELVETTKP,';
                  _pcs := _pcs + 'BEFIZETETTKP)' + _sorveg;
                  _pcs := _pcs + 'VALUES ('+chr(39)+_aktdnem+chr(39)+',';
                  _pcs := _pcs + chr(39)+_aktcegbetu+chr(39)+',';
                  _pcs := _pcs + floattostr(_felvettval[_valutaIndex,_cegss]) + ',';
                  _pcs := _pcs + floattostr(_befizetettval[_valutaIndex,_cegss])+')';

                  ReceptorParancs(_pcs);
                end;
              inc(_valutaIndex);
            end;
        end;
      inc(_cegss);
    end;
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
   _pcs := _pcs + ' WHERE DATUM<=' + chr(39)+_kertdatums+chr(39);
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

               ReceptorParancs(_pcs);
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
                       procedure TMakeImport.WIMPORT;
// =============================================================================


var _tnap,_aktazonosito,_aktvaltonev: string;

begin
   _cegss := 1;
   while _cegss<=2 do
     begin
       _aktcegBetu   := _cegBetuk[_cegss];
       _aktvaltonev  := _valtonev[_cegss];
       _AktAzonosito := _azonosito[_cegss];
       _textNev      := 'C:\LOCSERVER\DATA\BANKOUT\'+ _subdir[_cegss]+'\'+
                       _cegbetuk[_cegss] + 'M' +
                       Nulele(_kertev-2000)+
                       Nulele(_kertho)+ Nulele(_kertnap)+'.txt';

       Uzeno.Lines.Add(dupestring('-',70));
       Uzeno.Lines.Add(_aktvaltonev +' IMPORT FILE IRÁSÁT MEGKEZDTEM !');
       DeleteFile(_textNev);
       AssignFile(_iras,_textNev);
       Rewrite(_iras);

       _mondat := '# ' + _aktvaltonev + ' - ' + inttostr(_kertev)+' '+ _honapnev[_kertho]+' '+inttostr(_kertnap)+_sorveg;
       write(_iras,_mondat);
       write(_iras,_sorveg);
       write(_iras,'BEGIN'+_SORVEG);

       _tNap := 'TNAP'+CHR(9)+inttostr(_targyev)+'-'+Nulele(_targyho)+'-'+Nulele(_targynap);
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

       write(_iras,'END'+_sorveg);
       CloseFile(_iras);

       inc(_cegss);
     end;

   // --------------------------------------------------------------------------

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
      while length(_aktbankKod)<4 do _aktbankKod := _aktbankKod + chr(32);

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
          _eladott := FieldByName('ELADOTT').asInteger;
          _vett    := FieldByName('VETT').asInteger;
          _bkadott := FieldByName('BKELADOTT').asInteger;
          _bankkartyas := FieldbyName('BKARTYA').asInteger;
          _bkkezdij := FieldByName('BKKEZDIJ').asInteger;
        end;

      if _aktdnem='' then
        begin
          ReceptorQuery.Next;
          Continue;
        end;

      if _aktdnem<>'HUF' then _eladott := _eladott-_bkadott;

      _aktbankKod := ReceptorQuery.FieldByNAme('BANKKOD').asString;
      while length(_aktbankKod)<4 do _aktBankKod := _aktbankkod + chr(32);

      if _utbKod<>_aktbankKod then
        begin
          if _vanJelentes=True then write(_iras,'JELENTES END'+_SORVEG+_sorveg);
          write(_iras,'JELENTES UGYFELFORGALOM'+_sorveg);
          _vanJelentes := True;
          _utbKod := _aktBankKod;
          write(_iras,'UZLETHELYISEG_AZONOSITO'+chr(9)+_aktbankKod+_sorveg);
          write(_iras,'ERTEKNAP'+chr(9)+'-1'+_sorveg);
        end;

      _mondat := _aktdnem+chr(9)+inttostr(_eladott)+chr(9)+inttostr(_vett);
      _mondat := _mondat + chr(9) + '0';

      if _aktdnem='HUF' then
         begin
           _mondat := _mondat + chr(9)+'0'+CHR(9)+floattostr(_bankkartyas)+chr(9)+inttostr(_bkkezdij);
         end else
         begin
           _mondat := _mondat + chr(9)+inttostr(_bkadott)+chr(9)+'0'+CHR(9)+'0';
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
          _kpfelvett := FieldByName('FELVETTKP').asInteger;
          _kpbefizet := FieldByName('BEFIZETETTKP').asInteger;
        end;
      write(_iras,_aktdnem+chr(9)+inttostr(_kpfelvett)+chr(9)+inttostr(_kpbefizet)+chr(9)+
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
  _houtolsonap := daysinamonth(_kertev,_kertho);
  NapKombo.Clear;
  for i := 1 to _houtolsonap do NapKombo.items.Add(inttostr(i));
  napkombo.ItemIndex := _kertnap-1;
  _kertdatum := encodeDate(_kertev,_kertho,_kertnap);
  _hnap := dayoftheweek(_kertdatum);
  NapNevPanel.Caption := uppercase(_napnev[_hnap]);
  ActiveControl := ImportGo;
end;

// =============================================================================
             procedure TMAKEIMPORT.EVKOMBOChange(Sender: TObject);
// =============================================================================

var _evDiff: integer;
begin
    _evdiff := evkombo.ItemIndex-2;
   _kertev := _tenyev + _evdiff;
   _kertnap := 1;
   Setnapszam;
end;

// =============================================================================
                procedure TMAKEIMPORT.HOKOMBOChange(Sender: TObject);
// =============================================================================

begin
   _kertho := Hokombo.ItemIndex + 1;
   _kertnap := 1;
   Setnapszam;
end;

// =============================================================================
             procedure TMAKEIMPORT.NAPKOMBOChange(Sender: TObject);
// =============================================================================

begin
  _kertnap := NapKombo.ItemIndex + 1;
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
  _pcs := 'DELETE FROM SUMALLOMANY';
  ReceptorParancs(_pcs);

  _pcs := 'DELETE FROM SUMBANKFORGALOM';
  ReceptorParancs(_pcs);

  _pcs := 'DELETE FROM SUMUGYFELFORGALOM';
  ReceptorParancs(_pcs);
end;



// =============================================================================
          procedure TMAKEIMPORT.BACKTOMENUGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;


// ===========================================================================
        function TMakeImport.TegnapControl(_datums:string):boolean;
// ==========================================================================

// Vizsgálja, hogy bejött-e minden tegnapi adat

var
     i,_zHiany: integer;
     _dayBookName,_napstatus,_napmezo: string;
begin

  // Default: Minden bejött

  Result := True;

  _vanHiany := False;

  // Tegnapi napot vizsgálja:

  _farok      := midstr(_datums,3,2)+midstr(_datums,6,2);
  _kertnap    := strtoint(midstr(_datums,9,2));

 // A naplófile es a mezö meghatározása:

  _daybookname := 'DAYB'+ _farok;
  _napmezo     := 'N' + inttostr(_kertnap);

  // A napló-adatbázis megnyitása:

  DayBookDbase.Connected    := True;

  with DayBookTabla do
    begin
      Close;
      TableName := _dayBookName;
      IndexFieldNames := 'PENZTAR';
      Open;
      Refresh;
      First;
    end;

  _vanHiany := False;
  _zHiany   := 0;

  // Végigmegyünk az összes pénztáron:

  while not DayBookTabla.eof do
    begin
      _aktPenztar := DayBookTabla.FieldByname('PENZTAR').asInteger;
      _napstatus  := DayBookTabla.FieldByname(_napMezo).asString;
      _nstatus[_aktpenztar] := _napstatus;
      if _napstatus='' then
        begin
          _vanHiany := True;
          _missPenztar[_zHiany] := _aktPenztar;
          inc(_zHiany);
          if _zhiany>20 then break;
        end;
      DayBooktabla.Next;
    end;

  // Naplóadatbázis bezárva

  DayBookTabla.Close;
  DayBookDbase.Connected := False;

// -------------------------------------------------------

  // A napló-adatbázis megnyitása expressznél:

  AcDbase.Connected    := True;
  with AcTabla do
    begin
      Close;
      TableName := _dayBookName;
      IndexFieldNames := 'PENZTAR';
      Open;
      Refresh;
      First;
    end;


  // Végigmegyünk az összes pénztáron:
  while not AcTabla.eof do
    begin
      _aktPenztar := AcTabla.FieldByname('PENZTAR').asInteger;
      _napstatus  := AcTabla.FieldByname(_napMezo).asString;
      _nstatus[_aktpenztar] := _napstatus;
      if _napstatus='' then
        begin
          _vanHiany := True;
          _missPenztar[_zHiany] := _aktPenztar;
          inc(_zHiany);
          if _zhiany>20 then break;
        end;
      Actabla.Next;
    end;

  // Naplóadatbázis bezárva

  AcTabla.Close;
  AcDbase.Connected := False;

  // ----------------------------------------------------------

  if not _vanHiany then exit;

  // A hiánystring összeállitása - ha van:

  _hianyString := '';
  if _vanHiany then
    begin
      for i := 0 to _zhiany-1 do
          _hianyString := _hianyString + inttostr(_missPenztar[i])+',';

      // Jelzi, hogy volt hiányzó zárás:
      Result := False;
    end;
end;


// =============================================================================
                 function TMakeImport.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
                    procedure TMAKEIMPORT.IrodaBeolvasas;
// =============================================================================


var _isz,_cc,i: byte;
    _in,_ibk: string;

begin
  for i := 1 to 170 do
    begin
      _irodaszam[i] := 0;
      _irodanev[i]  := '';
      _bankkod[i]   := '';
      _cegbetu[i]   := 'B';
      if i>150 then _cegbetu[i] := 'Z';
    end;

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE CLOSED=' + chr(39)+'N'+chr(39)+_sorveg;
  _pcs := _Pcs + 'ORDER BY UZLET';

  ReceptorDbase.connected := true;
  with ReceptorQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _cc := 0;
  while not ReceptorQuery.Eof do
    begin
      inc(_cc);

      _isz := ReceptorQuery.FieldByName('UZLET').asInteger;
      _in  := trim(ReceptorQuery.FieldByName('KESZLETNEV').asString);
      _ibk := trim(ReceptorQuery.FieldByNAme('BANKKOD').asString);

      _irodaszam[_cc] := _isz;
      _irodanev[_isz] := _in;
      _bankkod[_isz]  := _ibk;

      ReceptorQuery.next;
    end;

  ReceptorQuery.close;
  Receptordbase.close;

  // ------------------------------------------------------------

  ArtDbase.connected    := True;
  with ArtQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not ArtQuery.Eof do
    begin
      inc(_cc);
      _isz := ArtQuery.FieldByName('UZLET').asInteger;
      _in  := trim(ArtQuery.FieldByName('KESZLETNEV').asString);
      _ibk := trim(ArtQuery.FieldByNAme('BANKKOD').asString);

      _irodaszam[_cc]  := _isz;
      _irodanev[_isz]  := _in;
      _bankkod[_isz]   := _ibk;
      ArtQuery.next;
    end;
  ArtQuery.close;
  ArtDbase.close;

  _irodaDarab := _cc;
end;


// =============================================================================
           function TMakeImport.DnemScan(_vn: string): integer;
// =============================================================================

var _y: integer;

begin
  Result := 0;
  for _y := 1 to _valutadarab do
    begin
      if _vn = _dnem[_y] then
        begin
          Result := _y;
          Break;
        end;
    end;
end;

// =============================================================================
           function TMakeImport.kerekito(_real: real): real;
// =============================================================================

var _nums: string;
    _utdig,_wnums: Byte;

begin
  result := _real;
  _nums := floattostr(_real);
  _wnums := length(_nums);
  _utdig := ord(_nums[_wnums])-48;
  if (_utdig<>0) and (_utdig<>5) then
    begin
      if (_utdig=1) or (_utdig=2) then result := _real-_utdig;
      if (_utdig=6) or (_utdig=7) then result := _real-(_utdig-5);
      if (_utdig=3) or (_utdig=4) then result := _real+(5-_utdig);
      if (_utdig=8) or (_utdig=9) then result := _real+10-_utdig;
    end;
end;


// =============================================================================
               procedure TMakeImport.CimletGyujto;
// =============================================================================

{
   Meglévõ adatok:  _aktpenztar (1..168)    closed='N'
                    _sktstatus  ('B' or 'X')
                    _aktfdbPath  (c:\receptor\database\Vnn.fdb, c:\cartcas\.. etc
                    _cegss: 1 or 2
                    _farok és elofarok: '2108', '2112'
}

begin

   _aktcegBetu := 'B';
   if _aktpenztar>150 then _aktcegbetu := 'Z';

   _aktbankkod := _bankkod[_aktpenztar];

   // A cimtárból vesszük az adatokat:

   _cimTar := 'CIMT'+_farok;
   _elohavicimtar := 'CIMT' + _elofarok;

  // Uzeno.Lines.Add('Pénztárállomány bedolgozása ...');

   with CimtarDbase do
     begin
       Connected    := False;
       DatabaseName := _aktfdbPath;
       Connected    := true;
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
   _pcs := _pcs + ' WHERE DATUM<=' + chr(39)+_kertdatums + chr(39);
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

   while not CimtarQuery.Eof do
     begin
       _aktdnem := CimtarQuery.FieldByName('VALUTANEM').asString;

       _css := 1;
       while _css<=14 do
         begin
           _tema      := 'CIMLET' + Inttostr(_css);
           _aktcimlet := _cimlet[_css];
           _ixsor     := _aktbankkod+_aktdnem+otnulla(_aktcimlet);
           _darab     := CimTarQuery.FieldByNAme(_tema).asInteger;

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

               ReceptorParancs(_pcs);
             end;
           inc(_css);
         end;
      CimtarQuery.Next;
    end;

  // Az állománytábla fel van töltve a cimletekkel:

  CimtarQuery.close;
  CimtarDbase.close;

end;

// =============================================================================
                     procedure TMakeImport.ElsoNapiKeszlet;
// =============================================================================
//        Ha nem létezik a kért havi cimtar-tábla a VALDATA.FDB  - ben


begin
  CimtarDbase.close;
  CimtarDbase.Connected := True;

  CimtarTabla.close;
  CimtarTabla.TableName := _elohaviCimtar;

  // Ha még elöhavi sincs, akkor nincs készlet

  if not CimtarTabla.Exists then
    begin
      CimtarDbase.close;
      exit;
    end;

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
       CimtarDbase.Close;
       CimtarQuery.Close;
       Exit;
     end;

 // Kiolvassa az elözö hónap utolsó napi dátumát:
  _zznaps := CimtarQuery.FieldByName('DATUM').asString;

  _pcs := 'SELECT * FROM '+_elohaviCimtar + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _zznaps + chr(39) + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

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
      _css := 1;

      while _css<=14 do
        begin
          _tema      := 'CIMLET' + inttostr(_css);
          _aktcimlet := _cimlet[_css];
          _darab     := CimtarQuery.FieldByName(_tema).asInteger;
          _ixsor     := _aktbankkod+_aktdnem+otnulla(_aktcimlet);

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

               ReceptorParancs(_pcs);
            end;
          inc(_css);
        end;
      CimtarQuery.Next;
    end;

  CimtarQuery.close;
  CimtarDbase.close;
end;

// =============================================================================
                    procedure TmakeImport.ForgalomGyujto;
// =============================================================================

var i: byte;

begin
  _voltUgyfForg := false;

  _BfTablaNev := 'BF' + _farok;
  _BtTablaNev := 'BT' + _farok;

  BlokkTabla.close;
  with BlokkDbase do
    begin
      Close;
      DatabaseName := _aktfdbPath;
      Connected    := True;
    end;

  BlokkTabla.TableName := _BFtablaNev;
  if not BlokkTabla.Exists then
    begin
      BlokkDbase.close;
      exit;
    end;

  _pcs := 'SELECT FEJ.*,TET.*' + _sorveg;
  _pcs := _pcs + 'FROM '+ _bfTablanev+' FEJ JOIN ' + _btTablanev+' TET' + _sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM' + _sorveg;
  _pcs := _pcs + 'WHERE (FEJ.DATUM=' +chr(39) + _kertdatums + chr(39) +') AND (';
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

  for i := 1 to _valutaDarab do
    begin
      _vettval[i]    := 0;
      _eladottval[i] := 0;
      _bkeladott[i]  := 0;
    end;

  _bankkartyas := 0;
  _bkkezdij    := 0;

(* -------- Itt kezdödik a napi forgalmi adatok bedolgozása -----------------*)

  _utbiz := 'XXXXXXX';
  while not BlokkQuery.Eof do
    begin
      with BlokkQuery do
        begin
          _bizonylatszam := FieldByName('BIZONYLATSZAM').asstring;
          _Tipus         := FieldByName('TIPUS').asString;
          _osszFt        := FieldByName('OSSZESEN').asInteger;
          _penztar       := FieldByName('PENZTAR').asString;
          _TRBPenztar    := trim(FieldbyName('TRBPENZTAR').asstring);
          _aktdnem       := FieldByName('VALUTANEM').asString;
          _bankjegy      := FieldByName('BANKJEGY').asInteger;
          _elojel        := FieldByName('ELOJEL').asString;
          _ertek         := FieldByName('FORINTERTEK').asInteger;
          _fizetoeszkoz  := FieldByName('FIZETOESZKOZ').asInteger;
          _aktkezdij     := FieldByName('KEZELESIDIJ').asInteger;
          _kerekites     := FieldByName('KEREKITES').asInteger;
        end;

      if _penztar='' then _penztar := 'URES' else _penztar := trim(_penztar);
      if (_penztar='TH') OR (_PENZTAR='1') then
        begin
          BlokkQuery.Next;
          Continue;
        end;

      _bq := 0;
      if _trbpenztar<>'' then
        begin
          val(_trbPenztar,_tspenztar,_code);
          if _code<>0 then _tsPenztar := 0;

          if _tspenztar>0 then
            begin
              _tarsbetu := 'B';
              if _tspenztar>150 then _tarsbetu := 'Z';
              if _tarsbetu<>_aktcegbetu then _bq := 1;
            end;
        end;

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

      _valutaIndex := DnemScan(_aktdnem);

      // Az ezbank flag jelzi, hogy ez Ugyfel vagy bank forgalma

      If _ezBank then
        begin
          _voltbankForg[_cegss] := true;

          if _tipus='U' then  _felvettVal[_valutaindex,_cegss] := _felvettVal[_valutaindex,_cegss] + _bankjegy
          else _befizetettval[_valutaindex,_cegss] := _befizetettval[_valutaindex,_cegss] + _bankjegy;

          BlokkQuery.Next;
          Continue;
        end;

      if _aktdnem='HUF' then
        begin
          BlokkQuery.Next;
          Continue;
        end;

      _voltugyfforg := True;

      if _elojel='+' then
        begin
          _vettval[_valutaIndex] := _vettval[_valutaIndex] + _bankjegy;
          _eladottval[_hufindex] := _eladottval[_hufindex] + _ertek;
          if _bizonylatszam<>_utbiz then _eladottval[_hufindex] := _eladottval[_hufindex]+_kerekites;
        end else
        begin
          _eladottval[_valutaindex] := _eladottval[_valutaindex] + _bankjegy;
          if _fizetoeszkoz<2 then
            begin
              _vettval[_hufindex] := _vettval[_hufindex] + _ertek;
              if _bizonylatszam<>_utbiz then _vettval[_hufindex] := _vettval[_hufindex]+_kerekites;
            end;
          if _fizetoeszkoz=2 then
            begin
              _bkeladott[_valutaindex] := _bkeladott[_valutaindex] + _bankjegy;
              _bankkartyas := _bankkartyas + trunc(_ertek);
              if _bizonylatszam<>_utbiz then
                begin
                  _bkkezdij := _bkkezdij + abs(_aktkezdij);
                end;
            end;
        end;
      _utbiz := _bizonylatszam;
      _aktkezdij := 0;
      BlokkQuery.Next;
    end;

  BlokkQuery.Close;
  BlokkDbase.close;

  // ---------------------------------------------------------------------------

  if _voltugyfforg then
    begin
      _valutaindex := 1;
      while _valutaindex<=_valutadaraB do
        begin
          _aktdnem := _dnem[_valutaindex];
          if (_eladottval[_valutaindex]>0) or (_vettval[_valutaIndex]>0) then
            begin
              _bke := _bkeladott[_valutaIndex];
              _bkeladott[_valutaIndex] := kerekito(_bke);

              _pcs := 'INSERT INTO SUMUGYFELFORGALOM (IRODASZAM,CEGBETU,BANKKOD,';
              _pcs := _pcs + 'BANKDNEM,VALUTANEM,ELADOTT,VETT,BKELADOTT)'+_sorveg;

              _pcs := _pcs + 'VALUES ('+inttostr(_aktpenztar)+',';
              _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',';
              _PCS := _Pcs + chr(39) + _aktbankkod + chr(39) + ',';
              _pcs := _pcs + chr(39) + _aktbankkod+_aktdnem + chr(39)+ ',';
              _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
              _pcs := _pcs + floattostr(_eladottval[_valutaIndex]) + ',';
              _pcs := _Pcs + floattostr(_vettval[_valutaIndex])+ ',';
              _pcs := _pcs + floattostr(_bkeladott[_valutaIndex])+')';

              receptorParancs(_pcs);
            end;
          inc(_valutaindex);
        end;
 
      _bankkartyas := kerekito(_bankkartyas);

      _pcs := 'UPDATE SUMUGYFELFORGALOM SET BKARTYA='+floattostr(_bankkartyas);
      _pcs := _pcs + ',BKKEZDIJ=' + inttostr(_bkkezdij)+_SORVEG;
      _pcs := _pcs + 'WHERE (IRODASZAM='+inttostr(_aktpenztar)+')';

      receptorParancs(_pcs);

    end;
end;

// =============================================================================
           procedure TMakeImport.ReceptorParancs(_ukaz: string);
// =============================================================================

begin
  ReceptorDbase.connected := true;
  if receptorTranz.InTransaction then ReceptorTranz.Commit;
  ReceptorTranz.StartTransaction;

  with ReceptorQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  ReceptorTranz.commit;
  ReceptorDbase.close;
end;


end.
