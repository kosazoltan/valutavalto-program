unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, unit1, ExtCtrls, IBDatabase, DB, IBCustomDataSet, IBTable,
  StdCtrls, Buttons, ComCtrls, Grids, DBGrids, IBQuery, strutils, jpeg,
  comobj,activex,shlobj,Oleserver,Excel97,TlHelp32;

type
  TAtlagArfolyam = class(TForm)

    AktValnevPanel: TPanel;
    DisplayPanel  : TPanel;
    FocimPanel    : TPanel;
    IrodaPanel    : TPanel;
    FotoPanel     : TPanel;
    Panel1        : TPanel;

    AtlagTabla  : TIBTable;
    AtlagQuery  : TIBQuery;
    AtlagDbase  : TIBDatabase;
    AtlagTranz  : TIBTransaction;
    AtlagRacs   : TDBGrid;

    BlokkQuery  : TIBQuery;
    BlokkTabla  : TIBTable;
    BlokkDbase  : TIBDatabase;
    BlokkTranz  : TIBTransaction;

    DbookQuery  : TIBQuery;
    DbookDbase  : TIBDatabase;

    RecQuery    : TIBQuery;
    RecDbase    : TIBDatabase;
    RecTranz    : TIBTransaction;

    Csik        : TProgressBar;
    Image1      : TImage;
    Kilepo      : TTimer;
    Label2      : TLabel;
    Shape1      : TShape;
    ValutaBox   : TListBox;

    AtlagTabLaIroda        : TSmallintField;
    AtlagTabLaErtektar     : TSmallintField;
    AtlagTabLaMegnevezes   : TIBStringField;
    AtlagTablaValutaNem    : TIBStringField;
    AtlagTablaVetelBankjegy: TFloatField;
    AtlagTablaVetelErtek   : TFloatField;
    AtlagTablaEladBankjegy : TFloatField;
    AtlagTablaEladErtek    : TFloatField;
    AtlagTablaVetelAtlag   : TFloatField;
    AtlagTablaELADAtlag    : TFloatField;
    AtlagTablaValutaNev    : TIBStringField;
    AtlagTablaMarge        : TFloatField;
    AtlagTablaCegbetu      : TIBStringField;
    BitBtn1                : TBitBtn;
    DataSource1            : TDataSource;
    BitBtn2                : TBitBtn;


    procedure FormActivate(Sender: TObject);

    procedure AtlagLegyujtes;
    procedure AtlagRacsEnter(Sender: TObject);
    procedure AtlagRacsExit(Sender: TObject);
    procedure AtlagSzamitas;
    procedure AtlagDisplay;
    procedure ExceladatokBeirasa;
    procedure IkonKirako;
    procedure KilepoTimer(Sender: TObject);
    procedure KillExcel;
    procedure LivePenztarBeolvasas;
    procedure PenztarBeolvasas;
    procedure ValutaBoxEnter(Sender: TObject);
    procedure ValutaBoxExit(Sender: TObject);
    procedure ValutaBoxtolto;
    procedure ValutaBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ValutaBoxKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ValutaValtozott;
    procedure AtlagParancs(_ukaz: string);
    procedure AtlagRogzito;
    procedure MakeFejlec;
    procedure MakeFrames;
    procedure Oszlopszelesseg;
    procedure Vekony(_rg: string);
    procedure Vastag(_rg: string);

    function ErtTarScan(_kk: byte): byte;
    function DnemScan(_vn: string): byte;
    function VesszobolPont(_vst: string): string;
    function FtForm(_ft:real):string;
    procedure BitBtn1Click(Sender: TObject);

    function Ezertektar(_pnum: byte): boolean;
    function Scandnem(_d: string): byte;
    function ScanKorzet(_k: byte): byte;

    procedure BitBtn2Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ATLAGARFOLYAM: TATLAGARFOLYAM;

  _korzetszam: array[1..8] of byte = (10,20,40,50,63,75,120,145);
  _korzetnev: array[1..8] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
                        'DEBRECEN','NYÍREGYHÁZA','BÉKÉSCSABA','PÉCS',
                        'KAPOSVÁR');

  _dnem: array[1..25] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY','CZK',
         'DKK','EUR','GBP','ILS','JPY','MXN','NOK','NZD','PLN','RON',
         'RSD','RUB','SEK','THB','TRY','UAH','USD');

  _dnev: array[1..25] of string = ('Ausztral dollar','Bosnyak marka','Bolgar leva',
         'Brazil real','Kanadai dollar','Svajci frank','Kinai juan','Cseh korona',
         'Dan korona','Euro','Angol font','Izraeli shakel',
         'Japan jen','Mexikoi peso','Norveg korona','Ujzelandi dollar',
         'Lengyel zloty','Roman lei','Szerb dinar','Orosz rubel','Sved korona',
         'Thai bath','Torok lira','Ukran hrivnya','Usa dollar');

  _penztardarab,_ptss,_pt: byte;

  _valutadarab  : byte = 25;
  _ertektarDarab: byte = 8;

  _livepenztar: array[1..120] of byte;
  _korzet     : array[1..170] of byte;
  _penztarnev : array[1..170] of string;

  _idszOke,_aktUzletszam,_bankjegy,_ertek: integer;
  _vBjegy,_eBjegy,_vertek,_eertek,_vvAtlag,_veAtlag: array[1..120,1..25] of real;
  _evBjegy,_eeBjegy,_evErtek,_eeertek,_evAtlag,_eeAtlag: array[1..8,1..25] of real;
  _svbjegy,_sebjegy,_svertek,_seertek,_svAtlag,_seAtlag: array[1..25] of real;

  _vmarge: array[1..120,1..25] of real;
  _eMarge: array[1..8,1..25] of real;
  _sMarge: array[1..25] of real;

  _voltAdat,_ezegynap: boolean;
  _ertektar,_penztar,_aktertektar,_tolnap,_ignap,_aNap,_y,_etar,_qq,_valss: byte;
  _aktpt,_korzetnum,_priosz,_prisor: byte;
  _vetarf,_eladarf,_vetosszeg,_eladosszeg: REAL;
  _etss,_uzlet,_cc,_code,_mResult,_dnemindex,_oszlop,_sor: integer;
  _eatlag,_marge,_vb,_ve,_ee,_eb: real;
  _tolstring,_igstring,_aktFdbPath,_farok,_pcs,_tipus,_valutanem,_cegbetu: string;
  _aktdnem,_aktdnev,_tolnaps,_ignaps,_dbooks,_anapMezo,_st,_uznev,_path: string;
  _bizonylat: string;
  _sorveg: string = chr(13)+chr(10);

  _proc: PROCESSENTRY32;
  _LOOPER: boolean;
  _handle: HWND;
  _oxl,_owb,_range: olevariant;

function atlagarfolyamrutin: integer; stdcall;
function getidoszakrutin: integer; stdcall; external 'c:\receptor\newdll\idoszak.dll';

implementation

{$R *.dfm}

// =============================================================================
           function atlagarfolyamrutin: integer; stdcall;
// =============================================================================

begin
  Atlagarfolyam := TAtlagarfolyam.Create(Nil);
  result := Atlagarfolyam.showmodal;
  Atlagarfolyam.free;
end;

// =============================================================================
            procedure TAtlagArfolyam.FormActivate(Sender: TObject);
// =============================================================================

var _fc,_focim: string;
    i,j: byte;

begin
  Top    := 290;
  Left   := 270;
  Height := 430;
  Width  := 750;

  _mResult := 1;

  // BEÁLLITJA: _tolstring,_igstring,(=_datumtols,_datumigs),_ezegynap,_idoszakszuro(feltétel)
  _idszOke := getidoszakrutin;

  If _idszOke<>1 then
    begin
      _mResult := -1;
      Kilepo.Enabled := True;
      exit;
    end;

  FotoPanel.Visible := True;
  FotoPanel.repaint;

  _ezegynap := False;
  recdbase.Connected := True;
  with recquery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM IDOSZAK');
      Open;
      _tolstring := FieldByNAme('STARTDATE').asString;
      _igstring  := FieldByNAme('ENDDATE').asString;
      Close;
    end;
  recdbase.close;

  if (_tolstring=_igstring) then _ezegynap := True;

  _fc := 'ÁTLAGOS ÁRFOLYAM ';
  If _ezEgynap then
    _focim := _fc + _tolstring + '-I NAPON'
  else
    _focim := _fc + _tolstring + ' ÉS ' + _igstring + ' KÖZÖTTI IDÕSZAKBAN';

  FocimPanel.Caption := _focim;
  FocimPanel.repaint;

  for i := 1 to _penztardarab do
    begin
      for j := 1 to _valutadarab do
        begin
          _vbjegy[i,j]  := 0;
          _eBjegy[i,j]  := 0;
          _vErtek[i,j]  := 0;
          _eErtek[i,j]  := 0;
          _vvatlag[i,j] := 0;
          _veatlag[i,j] := 0;
          _vMarge[i,j]  := 0;
        end;
    end;

  for i := 1 to _ertektardarab do
    begin
      for j := 1 to _valutadarab do
        begin
          _evbjegy[i,j] := 0;
          _eeBjegy[i,j] := 0;
          _evErtek[i,j] := 0;
          _eeErtek[i,j] := 0;
          _evAtlag[i,j] := 0;
          _eeAtlag[i,j] := 0;
          _eMarge[i,j]  := 0;
        end;
    end;

  for j := 1 to _valutadarab do
    begin
      _svBjegy[j] := 0;
      _seBjegy[j] := 0;
      _svertek[j] := 0;
      _seertek[j] := 0;
    end;

  LivePenztarBeolvasas;
  PenztarBeolvasas;

  _voltadat := False;

  AtlagLegyujtes;

  if not _voltAdat then
    begin
      ShowMessage('NEM VOLT AZ IDÖSZAK ALATT FORGALOM');
      Exit;
    end;

  AtlagSzamitas;
  Atlagrogzito;
  Atlagdisplay;
end;

// =============================================================================
                 procedure Tatlagarfolyam.Atlaglegyujtes;
// =============================================================================

var _ptarszam,_valSS: integer;
    _fejTablaNev,_tetTablaNev: string;

begin
  Csik.Max      := _penztarDarab;
  Csik.Position := 0;

  _ptss := 1;
  while _ptss<_penztardarab do
    begin
      Csik.Position := _ptss;

      _pt := _livepenztar[_ptss];
      if ezertektar(_pt) then
        begin
          inc(_ptss);
          Continue;
        end;

      irodaPanel.Caption := _penztarNev[_pt];
      IrodaPanel.repaint;

      _aktfdbPath := 'c:\receptor\database\v'+inttostr(_pt)+'.fdb';
      _ertekTar := _korzet[_pt];
      _cegbetu := 'B';

      if not fileexists(_aktfdbPath) then
        begin
          inc(_ptss);
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

      _pcs := _pcs + ' AND (FEJ.STORNO=1)';

      BlokkTabla.close;
      with Blokkdbase do
        begin
          Close;
          DatabaseName := _aktfdbPath;
          Connected := True;
        end;

      if blokkTranz.InTransaction then blokktranz.Commit;
      Blokktabla.TableName := _fejtablanev;

      if not Blokktabla.exists then
        begin
          inc(_ptss);
          Continue;
        end;

      with BlokkQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          Open;
          Last;
          _cc := recno;
        end;

      if _cc=0 then
        begin
          BlokkQuery.Close;
          inc(_ptss);
          Continue;
        end;


      BlokkQuery.First;
      while not BlokkQuery.eof do
        begin
          with BlokkQuery do
            begin
              _bizonylat := FieldByNAme('BIZONYLATSZAM').asString;
              _tipus     := FieldByName('TIPUS').asString;
              _valutanem := FieldByName('VALUTANEM').asstring;
              _bankjegy  := FieldbyName('BANKJEGY').asInteger;
              _ertek     := FieldByName('FORINTERTEK').asInteger;
            end;

          if (_tipus='F') OR (_tipus='U') then
            begin
              Blokkquery.Next;
              Continue;
            end;

          if (_valutanem = 'HUF') OR (_VALUTANEM='HRK') then
            begin
              BlokkQuery.Next;
              Continue;
            end;

          _etss     := ErtTarScan(_ertekTar);
          _valss    := DnemScan(_valutanem);
          _voltadat := True;

          if (_tipus='V') then
            begin
              // A váltó vétele:
              _vbjegy[_ptss,_valss] := _vbjegy[_ptss,_valss] + _bankjegy;
              _vErtek[_ptss,_valss] := _vErtek[_ptss,_valss] + _ertek;

              // Az értéktár vétele:
              _evbjegy[_etss,_valss] := _evbjegy[_etss,_valss] + _bankjegy;
              _evertek[_etss,_valss] := _evertek[_etss,_valss] + _ertek;

              if _cegbetu='B' then
                begin
                  _svbjegy[_valss] := _svbjegy[_valss] + _bankjegy;
                  _svertek[_valss] := _svertek[_valss] + _ertek;
                end;
            end;

          if (_tipus='E') then
            begin
              // A váltó eladása:
              _ebjegy[_ptss,_valss] := _eBjegy[_ptss,_valss] + _bankjegy;
              _eErtek[_ptss,_valss] := _eErtek[_ptss,_valss] + _ertek;

              // Az értéktár eladása:
              _eebjegy[_etss,_valss] := _eebjegy[_etss,_valss] + _bankjegy;
              _eeertek[_etss,_valss] := _eeertek[_etss,_valss] + _ertek;

              // Az Exclusive Best Change eladása:
              if _cegbetu='B' then
                begin
                  _sebjegy[_valss] := _sebjegy[_valss] + _bankjegy;
                  _seertek[_valss] := _seertek[_valss] + _ertek;
                end;
            end;
          BlokkQuery.Next;
        end;
      BlokkQuery.Close;
      inc(_ptss);
    end;
 end;

// =============================================================================
                    procedure TAtlagarfolyam.Atlagszamitas;
// =============================================================================

var _imarge,_diff: integer;
    i,j,_aktiroda: integer;
    _va,_ea: real;

begin
  // Exlusive change átlagszámitás:

  _valss := 1;
  while _valss<=_valutaDarab do
    begin
      _vb := _svBjegy[_valSs];
      _eb := _sebjegy[_valSs];
      _ve := _svertek[_valSs];
      _eE := _seErtek[_valSs];

      _va := 0;
      _ea := 0;

      if _vb>0 then _va := int(100*_ve/_vb);
      if _eb>0 then _ea := int(100*_ee/_eb);

      _svAtlag[_valSs] := trunc(_va);
      _seAtlag[_valSs] := trunc(_ea);

      if _va>0 then
        begin
          _diff   := trunc(_ea)-trunc(_va);
          _imarge := trunc(10000*_diff/_va);
          _marge  := _iMarge/10000;
          _sMarge[_valSs] := _marge;
        end;
      inc(_valss);
    end;

  // Értéktárak átkagszámitása:

  _etss := 1;
  while _etss<=_ertektarDarab do
    begin

      _valss := 1;
      while _valss<=_valutadarab do
        begin
          _vb := _evBjegy[_etss,_valss];
          _eb := _eebjegy[_etss,_valss];
          _ve := _evertek[_etss,_valss];
          _eE := _eeErtek[_etss,_valss];

          _va := 0;
          _ea := 0;

          if _vb>0 then _va := int(100*_ve/_vb);
          if _eb>0 then _ea := int(100*_ee/_eb);

          _evAtlag[_etss,_valss] := trunc(_va);
          _eeAtlag[_etss,_valss] := trunc(_ea);

          if _va>0 then
            begin
              _diff   := trunc(_ea)-trunc(_va);
              _imarge := trunc(10000*_diff/_va);
              _marge  := _iMarge/10000;
             _eMarge[_etss,_valss] := _marge;
            end;
          inc(_valss);
        end;
      inc(_etss);
    end;

  // Váltók átlagszámítása:

  _ptss := 1;
  while _ptss<=_penztardarab do
    begin
      _valss := 1;
      while _valss<=_valutaDarab do
        begin
          _vB := _vBjegy[_ptss,_valss];
          _vE := _vErtek[_ptss,_valss];
          _eB := _eBjegy[_ptss,_valss];
          _eE := _eErtek[_ptss,_valss];

          _va := 0;
          _ea := 0;

          if _vb>0 then _va := int(100*_ve/_vb);
          if _eb>0 then _ea := int(100*_ee/_eb);

          _vvAtlag[_ptss,_valss] := trunc(_va);
          _veAtlag[_ptss,_valss] := trunc(_ea);
          if _va>0 then
            begin
              _diff := trunc(_ea)-trunc(_va);
              _imarge := trunc(10000*_diff/_va);
              _marge := _iMarge/10000;
              _vMarge[_ptss,_valss] := _marge;
            end;
          inc(_valss);
        end;
      inc(_ptss);
    end;

  // ----------------- Itt kész az átlagszámitás -----------------------------
  //
  // _svatlag[valutasorszam] = Best Change vétel átlag valutánként
  // _seAtlag[valutasorszam] = Best Change eladás átlag valutánként;

  // _evAtlag[értéktársorszám,valutasorszám] = értéktárak átlagvételei
  // _eeAtlag[értéktársorszám,valutasorszám] = értéktárak átlageladásai

  // _vvAtlag[irodasorszam,valutasorszám] = váltók átlagvételei
  // _veAtlag[irodasorszám,valutasorszám] = váltók átlag eladásai

end;

procedure TAtlagArfolyam.AtlagRogzito;

begin
   _pcs := 'DELETE FROM ATLAGARFOLYAM';
  AtlagParancs(_pcs);

  // -------- Best Change Atlagarfolyamok felirasa --------------------------

  AtlagDbase.Connected := True;
  if Atlagtranz.InTransaction then AtlagTranz.Commit;
  AtlagTranz.StartTransaction;

  _valss := 1;
  while _valss<=_valutaDarab do
    begin
      if (_svBjegy[_valss]>0) or (_seBjegy[_valss]>0) then
        begin
          _pcs := 'INSERT INTO ATLAGARFOLYAM (IRODA,ERTEKTAR,MEGNEVEZES,';
          _pcs := _pcs + 'VALUTANEM,VETELBANKJEGY,VETELERTEK,';
          _pcs := _pcs + 'ELADBANKJEGY,ELADERTEK,VETELATLAG,ELADATLAG,';
          _pcs := _pcs + 'VALUTANEV,MARGE)' + _sorveg;

          _pcs := _pcs + 'VALUES (0,0,' + chr(39)+ 'Ebc összesen'+ chr(39)+',';
          _pcs := _pcs + chr(39)+ _dnem[_valss] + chr(39) + ',';
          _pcs := _pcs + floattostr(_svBjegy[_valss])+',';
          _pcs := _pcs + floattostr(_svErtek[_valss])+',';
          _pcs := _pcs + floattostr(_seBjegy[_valss])+',';
          _pcs := _pcs + floattostr(_seErtek[_valss])+',';
          _pcs := _pcs + floattostr(_svAtlag[_valss])+',';
          _pcs := _pcs + floattostr(_seAtlag[_valss])+',';
          _pcs := _pcs + chr(39) + trim(_dnev[_valss]) + chr(39) +',';
          _pcs := _pcs + VesszobolPont(FloatToStr(_sMarge[_valss]))+')';

          with AtlagQuery do
            begin
              Close;
              Sql.Clear;
              Sql.Add(_pcs);
              ExecSql;
            end;
        end;
      inc(_valss);
    end;

  // -------------- Átlag felirása az értktárakba ------------------------

  _etss := 1;
  while _etss<=_ertektarDarab do
    begin
      _valss := 1;
      while _valss<=_valutaDarab do
        begin
          if (_evBjegy[_etss,_valss]>0) or (_eeBjegy[_etss,_valss]>0) then
            begin
              _pcs := 'INSERT INTO ATLAGARFOLYAM (IRODA,ERTEKTAR,MEGNEVEZES,';
              _pcs := _pcs + 'VALUTANEM,VETELBANKJEGY,VETELERTEK,';
              _pcs := _pcs + 'ELADBANKJEGY,ELADERTEK,VETELATLAG,ELADATLAG,';
              _pcs := _pcs + 'VALUTANEV,MARGE)' + _sorveg;

              _pcs := _pcs + 'VALUES (0,'+ inttostr(_korzetszam[_etss]) + ',';
              _pcs := _pcs + chr(39) + _korzetnev[_etss]+' KÖRZET' + chr(39) + ',';
              _pcs := _pcs + chr(39) + _dnem[_valss] + chr(39) + ',';

              _pcs := _pcs + floattostr(_evBjegy[_etss,_valss]) + ',';
              _pcs := _pcs + floattostr(_evErtek[_etss,_valss]) + ',';
              _pcs := _pcs + floattostr(_eeBjegy[_etss,_valss]) + ',';
              _pcs := _pcs + floattostr(_eeErtek[_etss,_valss]) + ',';
              _pcs := _pcs + floattostr(_evAtlag[_etss,_valss]) + ',';
              _pcs := _pcs + floattostr(_eeAtlag[_etss,_valss]) + ',';
              _pcs := _pcs + chr(39) + trim(_dnev[_valss]) + chr(39) + ',';
              _pcs := _pcs + VesszobolPont(FloatTostr(_eMarge[_etss,_valss]))+')';

              with AtlagQuery do
                begin
                  Close;
                  Sql.Clear;
                  Sql.Add(_pcs);
                  ExecSql;
                end;
            end;
          inc(_valss);
        end;
      inc(_etss);
    end;

  // ------------------ Váltók átlagárfolyamok felirása  ----------------------

   _ptss := 1;
   while _ptss<=_penztarDarab do
     begin
       _valss := 1;
       while _valss<=_valutaDarab do
         begin
           if (_vBjegy[_ptss,_valss]>0) or (_eBjegy[_ptss,_valss]>0) then
             begin
               _aktpt := _livepenztar[_ptss];
               _aktertektar := _korzet[_aktpt];

               _pcs := 'INSERT INTO ATLAGARFOLYAM (IRODA,ERTEKTAR,MEGNEVEZES,';
               _pcs := _pcs + 'VALUTANEM,VETELBANKJEGY,VETELERTEK,';
               _pcs := _pcs + 'ELADBANKJEGY,ELADERTEK,VETELATLAG,ELADATLAG,';
               _pcs := _pcs + 'VALUTANEV,MARGE)' + _sorveg;

               _pcs := _pcs + 'VALUES ('+ inttostr(_aktPt) + ',';
               _pcs := _pcs + inttostr(_aktertektar) + ',';
               _pcs := _pcs + chr(39) + _penztarnev[_aktPt] + chr(39) + ',';
               _pcs := _pcs + chr(39) + _dnem[_valss] + chr(39) + ',';

               _pcs := _pcs + floattostr(_vBjegy[_ptss,_valss]) + ',';
               _pcs := _pcs + floattostr(_vErtek[_ptss,_valss]) + ',';
               _pcs := _pcs + floattostr(_eBjegy[_ptss,_valss]) + ',';
               _pcs := _pcs + floattostr(_eErtek[_ptss,_valss]) + ',';
               _pcs := _pcs + floattostr(_vvAtlag[_ptss,_valss]) + ',';
               _pcs := _pcs + floattostr(_veAtlag[_ptss,_valss]) + ',';
               _pcs := _pcs + chr(39) + trim(_dnev[_valss]) + chr(39) + ',';
               _pcs := _pcs + VesszobolPont(FloatTostr(_vMarge[_ptss,_valss]))+')';

               with AtlagQuery do
                 begin
                   Close;
                   Sql.Clear;
                   Sql.Add(_pcs);
                   ExecSql;
                 end;
             end;
           inc(_valss);
         end;
       inc(_ptss);
     end;

  AtlagTranz.Commit;
  AtlagDbase.Close;
end;

// =============================================================================
              procedure TATLAGARFOLYAM.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  AtlagTabla.Close;
  ModalResult := _mResult;
end;

// =============================================================================
                     procedure TatlagArfolyam.Atlagdisplay;
// =============================================================================

begin
  Valutaboxtolto;
  ValutaValtozott;
  with displayPanel do
    begin
      Top     := 72;
      Left    := 16;
      Visible := True;
      Repaint;
    end;
end;


// =============================================================================
               procedure TAtlagarfolyam.LivePenztarBeolvasas;
// =============================================================================

begin
  _tolnaps := midstr(_tolstring,9,2);
  _ignaps  := midstr(_igstring,9,2);

  val(_tolnaps,_tolnap,_code);
  val(_ignaps,_ignap,_code);

  _farok := midstr(_tolstring,3,2)+midstr(_tolstring,6,2);
  _dbooks := 'DAYB' + _farok;

  _pcs := 'SELECT * FROM ' + _dbooks + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAR';

  dbookdbase.connected := true;
  with DbookQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  _ptss := 0;
  while not dbookQuery.eof do
    begin
      _pt := dbookQuery.fieldbyname('PENZTAR').asInteger;
      if _pt>150 then break;

      _anap := _tolnap;
      while _anap<=_ignap do
        begin
          _anapmezo := 'N' + inttostr(_anap);
          _st := dbookquery.fieldbyname(_anapmezo).asstring;
          if _st='B' then
            begin
              inc(_ptss);
              _livepenztar[_ptss]:= _pt;
              break;
            end;
          inc(_anap);
        end;
      dbookquery.next;
    end;
  dbookquery.close;
  dbookdbase.close;
  _penztardarab := _ptss;
end;

// =============================================================================
               procedure TAtlagArfolyam.PenztarBeolvasas;
// =============================================================================

begin
  _pcs := 'SELECT * FROM IRODAK ORDER BY UZLET';
  RecDbase.Connected  := True;
  with RecQuery do
    begin
      Close;
      Sql.Clear;
      Sql.add(_pcs);
      Open;
    end;

  while not RecQuery.Eof do
    begin
      _uzlet := RecQuery.Fieldbyname('UZLET').asInteger;
      if _uzlet>150 then break;

      _uzNev := trim(RecQuery.FieldByNAme('KESZLETNEV').asString);
      _etar  := RecQuery.FieldByNAme('ERTEKTAR').asInteger;

      _penztarNev[_uzlet] := _uzNev;
      _korzet[_uzlet] := _etar;
      RecQuery.next;
    end;
  RecQuery.Close;
  RecDbase.Close;
end;

// =============================================================================
            function TAtlagarfolyam.ErtTarScan(_kk: byte): byte;
// =============================================================================

begin
  Result := 0;
  _y := 1;
  while _y<=8 do
    begin
      if _korzetSzam[_y]=_kk then
        begin
          Result := _y;
          Exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
          function TAtlagArfolyam.DnemScan(_vn: string): byte;
// =============================================================================

begin
  Result := 0;
  _y := 1;
  while _y<=_valutaDarab do
    begin
      if _dnem[_y]=_vn then
        begin
          result  := _y;
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
           function TAtlagArfolyam.VesszobolPont(_vst: string): string;
// =============================================================================

var y,_kod: integer;

begin
  Result := '';
  if _vst='' then Exit;

  for y := 1 to Length(_vst) do
    begin
      _kod := ord(_vst[y]);
      if _kod=44 then _kod := 46;
      result := Result + chr(_kod);
    end;
end;

// =============================================================================
           function TAtlagarfolyam.FtForm(_ft:real):string;
// =============================================================================

begin
  Result := FormatFloat('### ### ###',_ft);
  while length(result)<11 do Result := ' ' + Result;
end;


// =============================================================================
                      procedure Tatlagarfolyam.Valutaboxtolto;
// =============================================================================

begin
  ValutaBox.Clear;
  ValutaBox.Items.Clear;

  _y := 1;
  while _y<=_valutaDarab do
    begin
      ValutaBox.Items.Add(_dNev[_y]);
      inc(_y);
    end;
  ValutaBox.ItemIndex := 0;
end;

// =============================================================================
        procedure TATLAGARFOLYAM.VALUTABOXMouseDown(Sender: TObject;
                      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  ValutaValtozott;
end;

// =============================================================================
    procedure TATLAGARFOLYAM.VALUTABOXKeyUp(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  ValutaValtozott;
end;

// =============================================================================
                    procedure TAtlagArfolyam.ValutaValtozott;
// =============================================================================

begin
  _dnemIndex := ValutaBox.Itemindex;
  _aktDnem := _dnem[1+_dnemIndex];
  _aktDnev   := _dnev[1+_dnemIndex];

  AktValnevPanel.Caption := _aktDnev;
  AktValnevPanel.Repaint;
  AtlagDbase.Close;

  AtlagDbase.Connected := True;
  AtlagTabla.Close;
  AtlagTabla.Filtered  := False;
  AtlagTabla.Open;
  AtlagTabla.Filter := 'valutanem=' + chr(39) + _aktDnem + CHR(39);
  AtlagTabla.Filtered := True;
end;

// =============================================================================
            procedure TATLAGARFOLYAM.ATLAGRACSEnter(Sender: TObject);
// =============================================================================

begin
  AtlagRacs.Color := $b0ffff;
end;

// =============================================================================
            procedure TATLAGARFOLYAM.ATLAGRACSExit(Sender: TObject);
// =============================================================================

begin
  AtlagRacs.color := clWhite;
end;

// =============================================================================
             procedure TATLAGARFOLYAM.VALUTABOXEnter(Sender: TObject);
// =============================================================================

begin
  ValutaBox.Color := $b0ffff;
end;

// =============================================================================
             procedure TATLAGARFOLYAM.VALUTABOXExit(Sender: TObject);
// =============================================================================

begin
   ValutaBox.Color := clWhite;
end;

// =============================================================================
              procedure TAtlagArfolyam.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  AtlagQuery.Close;
  AtlagDbase.Close;

  Kilepo.Enabled := True;
end;

// =============================================================================
          function TatlagArfolyam.EzErtektar(_pnum: byte): boolean;
// =============================================================================

begin
  result := true;
  if (_pnum=10) or (_pnum=20) or (_pnum=40) or (_pnum=50) or (_pnum=63) then Exit;
  if (_pnum=75) or (_pnum=120) or (_pnum=145) then exit;

  result := False;
end;


// =============================================================================
          procedure TAtlagArfolyam.AtlagParancs(_ukaz: string);
// =============================================================================

begin
  AtlagDbase.Close;
  AtlagDbase.Connected := True;
  if atlagTranz.InTransaction then AtlagTranz.Commit;
  AtlagTranz.StartTransaction;

  with AtlagQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_ukaz);
      ExecSql;
    end;
  Atlagtranz.commit;
  AtlagDbase.close;
end;


// =============================================================================
            procedure TAtlagArfolyam.BitBtn2Click(Sender: TObject);
// =============================================================================

begin
  _path := 'c:\receptor\mail\posta\Atlagarfolyam.xls';
  DeleteFile(_path);

  _oxl := CREATEOLEOBJECT('EXCEL.APPLICATION');
  _owb := _oxl.workbooks.add[1];


  OszlopSzelesseg;

  _range := 'B2:N2';
  _oxl.range[_range].MergeCells := True;
  _oxl.range[_range].Font.Name := 'Calibri';
  _oxl.range[_range].Font.Size := 14;
  _oxl.range[_range].Font.Bold := True;

  _oxl.Cells[2,2] := 'ÁTLAGÁRFOLYAMOK '+_tolstring+' ÉS '+_igstring+' KÖZÖTT';

  _range := 'B4:AP31';
  _oxl.range[_range].Font.Name := 'Calibri';
  _oxl.range[_range].Font.Size := 8;
  _oxl.range[_range].Font.Bold := False;
  _oxl.range[_range].Horizontalalignment := -4108;

  _range := 'C7:AP31';
  _oxl.range[_range].NumberFormat := '### ###';


  MakeFejlec;
  MakeFrames;

  // Valutanemek beirása:

  _y := 1;
  while _y<=25 do
    begin
      _oxl.Cells[6+_y,2] := _dnem[_y];
      inc(_y);
    end;

  ExceladatokBeirasa;

  _range := 'C7:C7';
  _oxl.range[_range].Select;
  _oxl.ActiveWindow.FreezePanes := True;

  _owb.saveas(_path);
  IkonKirako;

  _oxl.ActiveWorkBook.close;
  _oxl.quit;
  Modalresult := 1;
end;

// =============================================================================
                    procedure TAtlagArfolyam.MakeFrames;
// =============================================================================

begin
  Vekony('B4:B6');
  Vekony('B4:B6');
  Vekony('C4:F4');
  Vekony('G4:J4');
  Vekony('K4:N4');
  Vekony('O4:R4');
  Vekony('S4:V4');
  Vekony('W4:Z4');
  Vekony('AA4:AD4');
  Vekony('AE4:AH4');
  Vekony('AI4:AL4');
  Vekony('AM4:AP4');

  Vekony('C5:D5');
  Vekony('E5:F5');
  Vekony('G5:H5');
  Vekony('L5:J5');
  Vekony('K5:L5');
  Vekony('M5:N5');
  Vekony('O5:P5');
  Vekony('Q5:R5');
  Vekony('S5:T5');
  Vekony('U5:V5');
  Vekony('W5:X5');
  Vekony('Y5:Z5');
  Vekony('AA5:AB5');
  Vekony('AC5:AD5');
  Vekony('AE5:AF5');
  Vekony('AG5:AH5');
  Vekony('AI5:AJ5');
  Vekony('AK5:AL5');
  Vekony('AM5:AN5');
  Vekony('AO5:AP5');
  Vekony('AA5:AB5');

  Vekony('C6:C6');
  Vekony('E6:E6');
  Vekony('G6:G6');
  Vekony('I6:I6');
  Vekony('K6:K6');
  Vekony('M6:M6');
  Vekony('O6:O6');
  Vekony('Q6:Q6');
  Vekony('S6:S6');
  Vekony('U6:U6');
  Vekony('W6:W6');
  Vekony('Y6:Y6');
  Vekony('AA6:AA6');
  Vekony('AC6:AC6');
  Vekony('AE6:AE6');
  Vekony('AG6:AG6');
  Vekony('AI6:AI6');
  Vekony('AK6:AK6');
  Vekony('AM6:AM6');
  Vekony('AO6:AO6');

  Vekony('C4:F6');
  Vekony('C4:F31');

  Vekony('G4:J6');
  Vekony('G4:J31');
  Vekony('K4:N6');
  Vekony('K4:N31');
  Vekony('O4:R6');
  Vekony('O4:R31');
  Vekony('S4:V6');
  Vekony('S4:V31');
  Vekony('W4:Z6');
  Vekony('W4:Z31');
  Vekony('AA4:AD6');
  Vekony('AA4:AD31');
  Vekony('AE4:AH4');
  Vekony('AI4:AL4');
  Vekony('AI4:AAL31');
  Vekony('AM4:AP4');
  Vekony('AM4:AP31');

  Vastag('B4:AP6');
  Vastag('B4:AP31');
end;

// =============================================================================
               procedure TATLAGARFOLYAM.vekony(_rg: string);
// =============================================================================

begin
  _oxl.range[_rg].BorderAround(1,2);
end;


// =============================================================================
             procedure TATLAGARFOLYAM.vastag(_rg: string);
// =============================================================================

begin
  _oxl.range[_rg].BorderAround(1,4);
end;

// =============================================================================
                  procedure TAtlagArfolyam.OszlopSzelesseg;
// =============================================================================

begin
  _oxl.range['A1:A1'].Columnwidth := 8;
  _oxl.range['B1:B1'].Columnwidth := 7;
  _oxl.range['C1:C1'].Columnwidth := 8;
  _oxl.range['D1:D1'].Columnwidth := 10;
  _oxl.range['E1:E1'].Columnwidth := 8;
  _oxl.range['F1:F1'].Columnwidth := 10;
  _oxl.range['G1:G1'].Columnwidth := 8;
  _oxl.range['H1:H1'].Columnwidth := 10;
  _oxl.range['I1:I1'].Columnwidth := 8;
  _oxl.range['J1:J1'].Columnwidth := 10;
  _oxl.range['K1:K1'].Columnwidth := 8;
  _oxl.range['L1:L1'].Columnwidth := 10;
  _oxl.range['M1:M1'].Columnwidth := 8;
  _oxl.range['N1:N1'].Columnwidth := 10;
  _oxl.range['O1:O1'].Columnwidth := 8;
  _oxl.range['P1:P1'].Columnwidth := 10;
  _oxl.range['Q1:Q1'].Columnwidth := 8;
  _oxl.range['R1:R1'].Columnwidth := 10;
  _oxl.range['S1:S1'].Columnwidth := 8;
  _oxl.range['T1:T1'].Columnwidth := 10;
  _oxl.range['U1:U1'].Columnwidth := 8;
  _oxl.range['V1:V1'].Columnwidth := 10;
  _oxl.range['W1:W1'].Columnwidth := 8;
  _oxl.range['X1:X1'].Columnwidth := 10;
  _oxl.range['Y1:Y1'].Columnwidth := 8;
  _oxl.range['Z1:Z1'].Columnwidth := 10;

  _oxl.range['AA1:AA1'].Columnwidth := 8;
  _oxl.range['AB1:AB1'].Columnwidth := 10;
  _oxl.range['AC1:AC1'].Columnwidth := 8;
  _oxl.range['AD1:AD1'].Columnwidth := 10;
  _oxl.range['AE1:AE1'].Columnwidth := 8;
  _oxl.range['AF1:AF1'].Columnwidth := 10;
  _oxl.range['AG1:AG1'].Columnwidth := 8;
  _oxl.range['AH1:AH1'].Columnwidth := 10;
  _oxl.range['AI1:AI1'].Columnwidth := 8;
  _oxl.range['AJ1:AJ1'].Columnwidth := 10;
  _oxl.range['AK1:AK1'].Columnwidth := 8;
  _oxl.range['AL1:AL1'].Columnwidth := 10;
  _oxl.range['AM1:AM1'].Columnwidth := 8;
  _oxl.range['AN1:AN1'].Columnwidth := 10;
  _oxl.range['AO1:AO1'].Columnwidth := 8;
  _oxl.range['AP1:AP1'].Columnwidth := 10;
end;

// =============================================================================
                    procedure TAtlagArfolyam.MakeFejlec;
// =============================================================================

begin
  _oxl.range['C4:F4'].Mergecells := True;
  _oxl.range['G4:J4'].Mergecells := True;
  _oxl.range['K4:N4'].Mergecells := True;
  _oxl.range['O4:R4'].Mergecells := True;
  _oxl.range['S4:V4'].Mergecells := True;
  _oxl.range['W4:Z4'].Mergecells := True;
  _oxl.range['AA4:AD4'].Mergecells := True;
  _oxl.range['AE4:AH4'].Mergecells := True;
  _oxl.range['AI4:AL4'].Mergecells := True;
  _oxl.range['AM4:AP4'].Mergecells := True;

  _oxl.range['C5:D5'].Mergecells := True;
  _oxl.range['E5:F5'].Mergecells := True;
  _oxl.range['G5:H5'].Mergecells := True;
  _oxl.range['I5:J5'].Mergecells := True;
  _oxl.range['K5:L5'].Mergecells := True;
  _oxl.range['M5:N5'].Mergecells := True;
  _oxl.range['O5:P5'].Mergecells := True;
  _oxl.range['Q5:R5'].Mergecells := True;
  _oxl.range['S5:T5'].Mergecells := True;
  _oxl.range['U5:V5'].Mergecells := True;
  _oxl.range['W5:X5'].Mergecells := True;
  _oxl.range['Y5:Z5'].Mergecells := True;
  _oxl.range['AA5:AB5'].Mergecells := True;
  _oxl.range['AC5:AD5'].Mergecells := True;
  _oxl.range['AC5:AD5'].Mergecells := True;
  _oxl.range['AE5:AF5'].Mergecells := True;
  _oxl.range['AG5:AH5'].Mergecells := True;
  _oxl.range['AI5:AJ5'].Mergecells := True;
  _oxl.range['AK5:AL5'].Mergecells := True;
  _oxl.range['AM5:AN5'].Mergecells := True;
  _oxl.range['AO5:AP5'].Mergecells := True;

  _range := 'B4:B6';
  _oxl.range[_range].Mergecells := True;
  _oxl.range[_range].WrapText   := True;
  _oxl.range[_range].VerticalAlignment := -4108;

  _oxl.Cells[4,2]  := 'VALUTA NEMEK';
  _oxl.Cells[4,3]  := 'SZEKSZÁRD KÖRZET';
  _oxl.Cells[4,7]  := 'SZEGED KÖRZET';
  _oxl.Cells[4,11] := 'KECSKEMÉT KÖRZET';
  _oxl.Cells[4,15] := 'DEBRECEN KÖRZET';
  _oxl.Cells[4,19] := 'NYÍREGYHÁZA KÖRZET';
  _oxl.Cells[4,23] := 'BÉKÉSCSABA KÖRZET';
  _oxl.Cells[4,27] := 'PÉCS KÖRZET';
  _oxl.Cells[4,31] := 'KAPOSVÁR KÖRZET';
//  _oxl.Cells[4,35] := 'EXPRESSZ ÉKSZERHÁZ KFT.';
  _oxl.Cells[4,39] := 'EXCLUSIVE BEST CHANGE KFT';

  _oxl.Cells[5,3]  := 'VÉTEL';
  _oxl.Cells[5,5]  := 'ELADÁS';
  _oxl.Cells[5,7]  := 'VÉTEL';
  _oxl.Cells[5,9]  := 'ELADÁS';
  _oxl.Cells[5,11]  := 'VÉTEL';
  _oxl.Cells[5,13]  := 'ELADÁS';
  _oxl.Cells[5,15]  := 'VÉTEL';
  _oxl.Cells[5,17]  := 'ELADÁS';
  _oxl.Cells[5,19]  := 'VÉTEL';
  _oxl.Cells[5,21]  := 'ELADÁS';
  _oxl.Cells[5,23]  := 'VÉTEL';
  _oxl.Cells[5,25]  := 'ELADÁS';
  _oxl.Cells[5,27]  := 'VÉTEL';
  _oxl.Cells[5,29]  := 'ELADÁS';
  _oxl.Cells[5,31]  := 'VÉTEL';
  _oxl.Cells[5,33]  := 'ELADÁS';
//  _oxl.Cells[5,35]  := 'VÉTEL';
//  _oxl.Cells[5,37]  := 'ELADÁS';
  _oxl.Cells[5,39]  := 'VÉTEL';
  _oxl.Cells[5,41]  := 'ELADÁS';

  _oxl.Cells[6,3] := 'ÁRFOLYAM';
  _oxl.Cells[6,4] := 'ÖSSZEG';
  _oxl.Cells[6,5] := 'ÁRFOLYAM';
  _oxl.Cells[6,6] := 'ÖSSZEG';
  _oxl.Cells[6,7] := 'ÁRFOLYAM';
  _oxl.Cells[6,8] := 'ÖSSZEG';
  _oxl.Cells[6,9] := 'ÁRFOLYAM';
  _oxl.Cells[6,10] := 'ÖSSZEG';
  _oxl.Cells[6,11] := 'ÁRFOLYAM';
  _oxl.Cells[6,12] := 'ÖSSZEG';
  _oxl.Cells[6,13] := 'ÁRFOLYAM';
  _oxl.Cells[6,14] := 'ÖSSZEG';
  _oxl.Cells[6,15] := 'ÁRFOLYAM';
  _oxl.Cells[6,16] := 'ÖSSZEG';
  _oxl.Cells[6,17] := 'ÁRFOLYAM';
  _oxl.Cells[6,18] := 'ÖSSZEG';
  _oxl.Cells[6,19] := 'ÁRFOLYAM';
  _oxl.Cells[6,20] := 'ÖSSZEG';
  _oxl.Cells[6,21] := 'ÁRFOLYAM';
  _oxl.Cells[6,22] := 'ÖSSZEG';
  _oxl.Cells[6,23] := 'ÁRFOLYAM';
  _oxl.Cells[6,24] := 'ÖSSZEG';
  _oxl.Cells[6,25] := 'ÁRFOLYAM';
  _oxl.Cells[6,26] := 'ÖSSZEG';
  _oxl.Cells[6,27] := 'ÁRFOLYAM';
  _oxl.Cells[6,28] := 'ÖSSZEG';
  _oxl.Cells[6,29] := 'ÁRFOLYAM';
  _oxl.Cells[6,30] := 'ÖSSZEG';
  _oxl.Cells[6,31] := 'ÁRFOLYAM';
  _oxl.Cells[6,32] := 'ÖSSZEG';
  _oxl.Cells[6,33] := 'ÁRFOLYAM';
  _oxl.Cells[6,34] := 'ÖSSZEG';
//  _oxl.Cells[6,35] := 'ÁRFOLYAM';
//  _oxl.Cells[6,36] := 'ÖSSZEG';
//  _oxl.Cells[6,37] := 'ÁRFOLYAM';
//  _oxl.Cells[6,38] := 'ÖSSZEG';
  _oxl.Cells[6,39] := 'ÁRFOLYAM';
  _oxl.Cells[6,40] := 'ÖSSZEG';
  _oxl.Cells[6,41] := 'ÁRFOLYAM';
  _oxl.Cells[6,42] := 'ÖSSZEG';

end;

// =============================================================================
              procedure TAtlagArfolyam.ExceladatokBeirasa;
// =============================================================================

begin
  _pcs := 'SELECT * FROM ATLAGARFOLYAM' + _sorveg;
  _pcs := _pcs + 'WHERE (IRODA=0) AND (ERTEKTAR>0)' + _sorveg;
  _pcs := _pcs + 'ORDER BY ERTEKTAR,VALUTANEM';

  AtlagDbase.Connected := True;
  with AtlagQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

    while not AtlagQuery.Eof do
      begin
        _aktdnem    := AtlagQuery.FieldByNAme('VALUTANEM').asString;
        _korzetnum  := AtlagQuery.FieldByNAme('ERTEKTAR').asInteger;
        _vetArf     := AtlagQuery.FieldByNAme('VETELATLAG').asInteger;
        _eladArf    := AtlagQuery.FieldByName('ELADATLAG').asInteger;
        _vetOsszeg  := AtlagQuery.FieldByNAme('VETELBANKJEGY').asInteger;
        _eladOsszeg := AtlagQuery.FieldByNAme('ELADBANKJEGY').asInteger;

        _dnemIndex := Scandnem(_aktdnem);

        _korzetNum := ScanKorzet(_korzetNum);
        _priosz := 3 + (4*trunc(_korzetnum-1));
        _prisor := 6 + _dnemIndex;

        _oxl.Cells[_prisor,_priosz]   := _vetArf;
        _oxl.Cells[_prisor,_priosz+1] := _vetosszeg;
        _oxl.Cells[_prisor,_priosz+2] := _eladArf;
        _oxl.Cells[_prisor,_priosz+3] := _eladOsszeg;

        AtlagQuery.Next;
      end;

   // -----------------------------------------------------------------------

  _pcs := 'SELECT * FROM ATLAGARFOLYAM' + _sorveg;
  _pcs := _pcs + 'WHERE (IRODA=0) AND (ERTEKTAR=0)' + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  AtlagDbase.Connected := True;
  with AtlagQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  _priosz := 39;
  while not AtlagQuery.Eof do
    begin
      _aktdnem    := AtlagQuery.FieldByNAme('VALUTANEM').asString;
      _vetArf     := AtlagQuery.FieldByNAme('VETELATLAG').asInteger;
      _eladArf    := AtlagQuery.FieldByName('ELADATLAG').asInteger;
      _vetOsszeg  := AtlagQuery.FieldByNAme('VETELBANKJEGY').asInteger;
      _eladOsszeg := AtlagQuery.FieldByNAme('ELADBANKJEGY').asInteger;

      _dnemIndex := Scandnem(_aktdnem);
      _prisor := 6 + _dnemIndex;

      _oxl.Cells[_prisor,_priosz]   := _vetArf;
      _oxl.Cells[_prisor,_priosz+1] := _vetosszeg;
      _oxl.Cells[_prisor,_priosz+2] := _eladArf;
      _oxl.Cells[_prisor,_priosz+3] := _eladOsszeg;

      AtlagQuery.Next;
    end;
  AtlagQuery.close;
  ATlagdbase.close;
end;

// =============================================================================
            function TAtlagArfolyam.Scandnem(_d: string): byte;
// =============================================================================

var _y: byte;

begin
  result := 0;
  _y := 1;
  while _y<=_valutaDarab do
    begin
      if _dnem[_y]=_d then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
              function TAtlagArfolyam.ScanKorzet(_k: byte): byte;
// =============================================================================

var _y: byte;

begin
  result := 0;
  _y := 1;
  while _y<=8 do
    begin
      if _korzetszam[_y]=_k then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
                  procedure TAtlagarfolyam.KillExcel;
// =============================================================================

var
  _fileName,_filePath: String;

begin

  _Proc.dwSize := SizeOf(_Proc);
  _handle := CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
  _Looper := Process32First(_handle,_proc);

  while Integer(_Looper) <> 0 do
    begin
      _filepath := _Proc.szExeFile;
      _fileName := UpperCase(ExtractFileName(_filepath));

      if _fileName = 'EXCEL.EXE' then
        begin
          TerminateProcess(OpenProcess(1,Bool(1),_proc.th32ProcessID),0);
          break;
        end;

      _Looper := Process32Next(_handle,_proc);
    end;
  CloseHandle(_handle);
end;

// =============================================================================
                    procedure TAtlagArfolyam.IkonKirako;
// =============================================================================

var IObject: IUnKnown;
    isLink : IShellLink;
    ipFile : iPersistFile;
    PIDL   : pItemidList;
   inFolder: array[0..MAX_PATH] of char;
 TargetName: string;
   LinkName: widestring;

begin
  TargetName := 'C:\RECEPTOR\MAIL\POSTA\ATLAGARFOLYAM.XLS';

  IoBJECT := CreateComObject(CLSID_ShellLink);
  isLink := iObject as iShellLink;
  ipFile := iObject as iPersistFile;

  with Islink do
    begin
      SetPath(pchar(targetName));
      SetWorkingDirectory(pchar(extractFilePath(TargetName)));
    end;
  ShGetSpecialFolderLocation(0,CSIDL_DESKTOPDIRECTORY,PIDL);
  ShGetPathFromIdList(PIDL,InFolder);
  LinkName := infolder + '\Atlagarfolyam.lnk';
  ipFile.Save(pwChar(Linkname),False);
end;

end.

