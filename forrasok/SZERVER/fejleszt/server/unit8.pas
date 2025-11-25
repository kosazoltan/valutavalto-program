unit Unit8;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, DBTables, StdCtrls, Buttons, DBITypes, DBIProcs, dbiErrs,
  ExtCtrls, IdGlobal, StrUtils, Grids, DateUtils, IBQuery, IBDatabase,
  IBCustomDataSet, IBTable;


type
  TCimletezoForm = class(TForm)

     // A cimletezett bankjegyek editjei:

     CE1: TEdit;
     CE2: TEdit;
     CE3: TEdit;
     CE4: TEdit;
     CE5: TEdit;
     CE6: TEdit;
     CE7: TEdit;
     CE8: TEdit;
     CE9: TEdit;
    CE10: TEdit;
    CE11: TEdit;
    CE12: TEdit;
    CE13: TEdit;
    CE14: TEdit;

     SP1: TPanel;
     SP2: TPanel;
     SP3: TPanel;
     SP4: TPanel;
     SP5: TPanel;
     SP6: TPanel;
     SP7: TPanel;
     SP8: TPanel;
     SP9: TPanel;
    SP10: TPanel;
    SP11: TPanel;
    SP12: TPanel;
    SP13: TPanel;
    SP14: TPanel;

     VP1: TPanel;
     VP2: TPanel;
     VP3: TPanel;
     VP4: TPanel;
     VP5: TPanel;
     VP6: TPanel;
     VP7: TPanel;
     VP8: TPanel;
     VP9: TPanel;
    VP10: TPanel;
    VP11: TPanel;
    VP12: TPanel;
    VP13: TPanel;
    VP14: TPanel;
    VP15: TPanel;
    VP16: TPanel;
    VP17: TPanel;
    VP18: TPanel;
    VP19: TPanel;
    VP20: TPanel;
    VP21: TPanel;
    VP22: TPanel;
    VP23: TPanel;
    VP24: TPanel;
    VP25: TPanel;

     CP1: TPanel;
     CP2: TPanel;
     CP3: TPanel;
     CP4: TPanel;
     CP5: TPanel;
     CP6: TPanel;
     CP7: TPanel;
     CP8: TPanel;
     CP9: TPanel;
    CP10: TPanel;
    CP11: TPanel;
    CP12: TPanel;
    CP13: TPanel;
    CP14: TPanel;

    // A takaro panelek:

     TAKPANEL1: TPanel;
     TAKPANEL2: TPanel;
     TAKPANEL3: TPanel;
     TAKPANEL4: TPanel;
     TAKPANEL5: TPanel;
     TAKPANEL6: TPanel;
     TAKPANEL7: TPanel;
     TAKPANEL8: TPanel;
     TAKPANEL9: TPanel;
    TAKPANEL10: TPanel;
    TAKPANEL11: TPanel;
    TAKPANEL12: TPanel;
    TAKPANEL13: TPanel;
    TAKPANEL14: TPanel;


      CimletPanel: TPanel;
 CimletezettPanel: TPanel;
      RovNevPanel: TPanel;
   TeljesNevPanel: TPanel;
          Panel19: TPanel;

       Label1: TLabel;
       Label3: TLabel;
       Label4: TLabel;
       Label6: TLabel;
      Panel45: TPanel;
 LongDatumNev: TLabel;

         ExitGomb: TBitBtn;    // escape
     RogzitsdGomb: TBitBtn;
    CIMLETLISTAGOMB: TBitBtn;
    CIMTARTABLA: TIBTable;
    CIMTARDBASE: TIBDatabase;
    CIMTARTRANZ: TIBTransaction;
    ARFOLYAMTABLA: TIBTable;
    ARFOLYAMDBASE: TIBDatabase;
    ARFOLYAMTRANZ: TIBTransaction;
    QuerytABLA: TIBQuery;
    QUERYDBASE: TIBDatabase;
    QUERYTRANZ: TIBTransaction;
    CIMLETTABLA: TIBTable;
    CIMLETDBASE: TIBDatabase;
    CIMLETTRANZ: TIBTransaction;

   // A PROGRAM PROCEDURAI:

   procedure FormCreate(Sender: TObject);
   procedure CimletRogzites(Sender: TObject);
   procedure KonstansTomb;
   procedure SetUpBeolvas;
   procedure PiszkozatClear;
   procedure VPMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
   procedure Panel19MouseMove(Sender: TObject; Shift: TShiftState; X,Y: integer);
   procedure VPClick(Sender: TObject);
   procedure CE1Enter(Sender: TObject);
   procedure CE14Exit(Sender: TObject);
   procedure CE1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
   procedure CimSKip(_irany:integer);
   procedure DataBedolgozas;
   procedure SqlParancs(_ukaz: string);
   procedure NemRogziteniGombClick(Sender: TObject);
   procedure Kimasol;
   procedure Bemasol;
   procedure ExitGombClick(Sender: TObject);
   procedure NemNapZaras;
   procedure Nevbeiro;
   procedure MakeCimtar(_fdbNev: string; _dNev: string);

   procedure CimtarRogzites;

   // A PROGRAM FUNKCIOI:


 //  function CimTarBeolvasas():boolean;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CimletezoForm: TCimletezoForm;

  _config: TextFile;

  _aktPanel,_aktgomb,_aktSumPanel,_aktCimletPanel: TPanel;
  _aktEdit: TEdit;
  _aktszin: TColor;

  _aktcert,_aktss,_zaro,_valutasorszam: integer;
  _sumcim,_aktzaro,_osszeg,_aktcss,_ss,_milegyen: integer;
  _vtag,_ctag,_cimletdarab,_scim,_qq,_aktbjegy: integer;
  _aktcbjegy,_aktErtek,_osszesen,_aktcim,_osszcimertek: integer;

  _aktmez,_tablanev,_cDatum,_zaroDString,_longDstring: string;
  _longNev,_rovnev: string;

  _hnap: word;

  _rendben,_voltCimlet: boolean;

  _valNevPanel: array[0..25] of TPanel;
  _takPan: array[1..14] of TPanel;

  _cic:array[1..14] of integer;

  _cimedit: array[1..15] of TEdit;
  _cimgomb: array[1..15] of TPanel;
   _sumPan: array[1..15] of TPanel;


   _liveCimDarab: array[0..25] of integer;
   _liveCimsor: array[0..25] of string;
   _liveCimBankjegy: array[0..25,1..15] of Integer;
   _liveosszes: array[0..25] of integer;



implementation

uses Unit1, Unit19;

{$R *.dfm}

// =============================================================
        procedure TCimletezoForm.FormCreate(Sender: TObject);
// =============================================================
   (*
                        ARFOLYAM.DBF ALAPJÁN:

        _VALUTADARAB = ennyi fajta valuta van az arfolyam.dbf-ben
        _DNEM[0.._valutadarab-1] = az árfolyam.dbf-bõl vett DNEM
        _DNEV[0.._valutadarab-1] = az árfolyam.dbf-bõl vett DMEGN
        _VARF[0.._valutadarab-1] = az árfolyam.dbf-bõl vett VARF
        _EARF[0.._valutadarab-1] = az árfolyam.dbf-bõl vett EARF
        _ELSZARF[0.._valutadarab-1] = az árfolyam.dbf-bõl vett ELSZ_ARF
        _MODISZ[0.._valutadarab-1] = az árfolyam.dbf-bõl vett MODISZAZ
        -------------------------------------------------------------
                          CIMLET.CFG ALAPJÁN:

         _CONFIGSS = ennyi valutának van meg a paramétere
         _VNEM[1.._CONFIGSS] = a setupban lévõ valutanevek
         _VCDB[1.._CONFIGSS] = a setupban lévõ valuták elérhetõ cimletei
         _VCIMSOR[1.._CONFIGSS] = az elérhetö valuták cimletsorszámai+65 STRING
         --------------------------------------------------------------------
                     A KISZÁMITOTT ÉRTÉKEK TÖMBJEI:

          _LIVEVALUTADARAB = ennyi valutának volt záróértéke az ARFOLYAM.DBF-ben

          _LIVEDNEM[1.._liveValutaDarab] = fentiek rövid neveinek tömbje
          _LIVEDNEV[1.._liveValutaDarab] = ugyanennek hosszu neve
          _LIVeCIMDARAB[1.._liveValutaDarab] = ennyi cimlete van az élö valuáknak
          _LIVeCIMSOR[     - "" -         ] = (string) ASC-65 = CIMLETSORSZÁM
                                             Pl. 'BDH' = 3 féle cimlet
                                               'B'-65 = 1 -> 20.000
                                               'D'-65 = 3 ->  5.000
                                               'H'-65 = 7 ->    200
          _LIVECIMBANKJEGY[1.._liveValutaDarab,1..14] = egyes valuták cimlet-
                                               darabszámai
          _LIVEoSSZES[1.._liveValutaDarab] = Az élõ valuták cimletezett
                                               értékei
          _LIVEZARO[1.._liveValutaDarab] = Az ARFOLYAM.DBF záróértékei
          ----------------------------------------------------------------------
   *)


var _i,j:integer;

begin

      Top := _top+120;
     Left := _left+140;
   Height := 530;
    Width := 750;

   CimletezettPanel.Color := clBtnFace;
   KonstansTomb; // _valnevpanel[1..25],_cimedit[1..14],_cimgomb[1..14],_sumpan[1..14]

  // Az összes takarólemez takarjon:

  for _i := 1 to 14 do
    begin
      _aktpanel := _takpan[_i];
      _aktpanel.Visible := True;
    end;

  CimletezettPanel.Caption := '';
  _osszCimertek := 0;
  _rendben := False;

  for _i := 0 to 24 do  _valnevPanel[_i].Caption := '';

// --------------------- NAPI ZÁRÁS --------------------------------------------


    // CimletListázógomb és felirat elrejtve:

      _zaroDstring := leftstr(Form1.hdatetostr(_aktDatum),10);
      _hnap:= dayoftheweek(_aktdatum);

     // A napizárás napját szöveggel kiirja:

      _longDstring := Form1.setLongDstring(_zarodstring);
      LongDatumNev.Caption := _longDString;

// -------------------- Az élõ valuták cimleteinek beolvasása -------------

  SetupBeolvas;

// -------------------- A cimletadatok kinullázás ------------------------

  _qq := 0;
  while _qq<_ValutaDarab do
    begin
      _liveOsszes[_qq] := 0;
      for j := 1 to 14 do
           _liveCimbankjegy[_qq,j] := 0;

      inc(_qq);
    end;

//----------- A cimletezés nullázott adatokkal készen áll ----------------------



// ------- Most összehasonlitja a LiveOsszes és LiveZaro tomb adatait
//  és kezeli az OK edit-ek X-jét, és a DNEV kiirások színét is
//  ha az osszes Live valuta rendben, akkor a visszatérés = TRUE

  _rendben := False;
  NemNapZaras;



// ------- A valuta panelekre beirja az élö valuta neveket ------------

   Nevbeiro;

  // Nullázás:

   _vtag := 0;
   _Ctag := 0;

   Rovnevpanel.Caption := '';
   TeljesNevPanel.Caption := '';
end;


// =============================================
      procedure TCimletezoForm.SetUpBeolvas;
// =============================================

(* A konfigurációs adatok (cimletdarab, és sorszámok) tömbbe irja *)

var _cfdarab,_yy: integer;
    _mondat,_cfsor,_configNev: string;

begin
   // Megnyitja a Cimlet konfigurációs file-ját:

   _confignev := 'c:\receptor\Cimlet.cfg';
   AssignFile(_config,_confignev);
   Reset(_config);

   while not eof(_config) do
     begin

       // Beolvas egy-egy sort a konfigurációból:

       ReadLn(_config,_mondat);
       _aktdnem := leftstr(_mondat,3);

       // A sor a valutanévvel kezdödik, megnézi, hogy van-e ilyen valuta

       _yy := Form1.DnemScan(_aktdnem);
       if _yy>-1 then   // Ha van ilyen valuta:
         begin

           // Kiemeli a cimletdarabot és sort:

           _cfdarab := ord(_mondat[4])-65;
           _cfsor := midstr(_mondat,5,_cfDarab);

           // A valuták tömbjeibe iródnak:

           _liveCimDarab[_yy] := _cfDarab;
           _liveCimSor[_yy] := _cfSor;
         end;
     end;
   CloseFile(_config);
end;


// ============================================================================
    procedure TCimletezoform.VPMouseMove(Sender: TObject; Shift: TShiftState;
                                                              X,  Y: Integer);
// ============================================================================

begin

   if _valutaSorszam>-1 then
     begin
       _aktpanel := _valNevPanel[_valutaSorszam];
       _aktPanel.Color := clBtnFace;
       _aktpanel.Font.Color := clNavy;
     end;
  _valutaSorszam := TPanel(Sender).Tag;
  TPanel(Sender).Color := clRed;
  TPanel(Sender).Font.Color := clWhite;

end;

//==============================================================================
   procedure TCimletezoForm.Panel19MouseMove(Sender: TObject; Shift: TShiftState;
                                                                 X, Y: Integer);
// =============================================================================

begin
  if _valutaSorszam>0 then
    begin
      _aktpanel := _valNevPanel[_valutaSorszam];
      _aktPanel.Color := clBtnFace;
      _aktpanel.Font.Color := clNavy;
    end;
  _valutaSorszam := 0;
end;

// ==========================================================
       procedure TCimletezoForm.VPClick(Sender: TObject);
// ==========================================================

(*
     Egy valutát kiválasztottam: sorszáma -> VTAG  (0...24)
*)

begin

  _vtag := Tpanel(Sender).Tag;       // VTAG = VÁLASZTOTT VALUTA SORSZÁMA A SAJÁT TÁBLÁNKBAN
  if _vTAG>=_ValutaDarab then exit;   // ÜRES VALUTAPANELRE KATTINTOTT
  _valutasorszam := 0;                // EGÉR NE AKARJON SZINT TÖRÖLNI
  Bemasol;
end;


// =============================================================
         procedure TCimletezoForm.CE1Enter(Sender: TObject);
// =============================================================


begin
  _aktedit := TEdit(Sender);
  _CTag := _aktedit.Tag;
  _aktedit.Color := clYellow;
end;


// =========================================================
       procedure TCimletezoForm.CE14Exit(Sender: TObject);
// =========================================================

(*  Egy cimlet-editbõl kilép *)

begin
  _aktedit := Tedit(sender);
  _Aktedit.color := clWindow;
end;


// ==========================================================================
    procedure TCimletezoform.CE1KeyDown(Sender: TObject; var Key: Word;
                                                        Shift: TShiftState);
// ==========================================================================

var _betu: integer;
begin
  _betu := ord(key);

  if (_betu=13) or (_betu=40) then
    begin
      Kimasol;
      CimSKip(1);
      exit;
    end;

  if (_betu=38) then
    begin
      Kimasol;
      CimSkip(-1);
      exit;
    end;

  if (_betu=35) then
    begin
      Kimasol;
      CimletRogzites(Ce1);
      exit;
    end;

end;

// =======================================================
      procedure TCimletezoForm.CimSKip(_irany:integer);
// =======================================================


var i,_aktc,_has,_aktcimDarab: integer;
    _aktcimsor: string;
    _betu: char;

begin

  CimletezettPanel.Color := clBtnFace;
  CimletezettPanel.Font.Color := clNavy;

  _aktc := 0;
  _aktcimsor := _LiveCimsor[_Vtag];
  _aktcimDarab := _liveCimDarab[_Vtag];

  for i := 1 to _aktcimDarab do
    begin
      _betu := _aktcimsor[i];
      _has := ord(_betu)-65;

      if _has=_CTag then
        begin
          _aktc := i;
          break;
        end;
    end;

  if _irany=1 then
    begin
      inc(_aktC);
      if _aktc>_aktcimDarab then _aktc := 1;
    end else
    begin
      dec(_aktC);
      if _aktC<1 then _aktC := _aktcimDarab;
    end;
  _betu := _aktCimSor[_aktC];
  _cTag := ord(_betu)-65;
  _aktedit := _cimEdit[_cTag];
  _aktEdit.SetFocus;
end;


(*
// ======================================================
      function TCimletezoForm.CimTarBeolvasas():boolean;
// ======================================================

// A napi záráshoz beolvassa az elözöleg erre a napra rögzitett értékeket:

var _fpath: string;
     i: integer;

begin

  // A Cimlettábla paraméterek meghatározása a _ZaroDStringnek megfelelöen

  Result := False;
  CimletTabla.Close;

 // A cimtárgyüjtõ neve és útvonala meghatározása:

  _tablanev := 'CIMT'+ midstr(_zaroDstring,3,2)+midstr(_zaroDstring,6,2)+'.dbf';
  _fpath := 'c:\valuta\'+_tablanev;

 // Ha esetleg még nem lenne cimtár havigyüjtö, akkor nincs mit bemásolni !
  if not fileExists(_fpath) then exit;

  // A cimtárt leindexeli dátum szerint:

  cimletTabla.Close;

  with CimletTabla do
    begin
      close;
      TableName := _tablaNev;
      Filter := 'DATUM='+chr(39)+_zaroDstring+chr(39);
      Filtered := True;
      Open;
      First;
      Refresh;
    end;

 // Ha nincs a zárónapra bejegyzés, akkor nincs mit beolvasnia:

  if CimletTabla.Eof then
    begin
      with CimletTabla do
        begin
          Close;
          Filtered := False;
          Filter := '';
        end;
      exit;
    end;

  // A cimtárból a záró-napra bejegyzett valuták cimleteit olvassa a CIC tömbbe

  while not CimletTabla.Eof do
    begin

      _aktdnem := CimletTabla.FieldByName('DNEM').asString;
      for i := 1 to 14 do
        begin
          _aktmez := 'D'+Form1.Nulele(i+4);
          _cic[i] := cimletTabla.FieldByName(_aktmez).asInteger;
        end;

  // Feltölti a _liveCimbankjegy és _liveOsszes tömböket adatokkal:

     DataBedolgozas;
     CimletTabla.Next;
     Result := True;
   end;

  CimletTabla.Close;
end;
*)



// ============================================
     procedure TCimletezoform.DataBedolgozas;
// ============================================

// Feltölti a _liveCimbankjegy és _liveOsszes tömböket adatokkal:

var i:integer;
begin

   _vtag := Form1.DnemScan(_aktdnem);
   _scim := 0;

   If _vtag>0 then
     begin

       for i := 1 to 14 do

         begin
           _aktcbjegy := _cic[i];     // A beolvasott bankjegy ebbõl a cimletböl
           _aktertek := _cimlet[i]*_aktcbjegy;  // A fenti értéke
           _liveCimBankjegy[_vtag,i] := _aktCBjegy;
           _scim := _scim + _aktertek;
         end;
       _liveOsszes[_vTag] := _scim;  // ennyi érték van ebbõl a valutából
     end;
end;

// ===============================================================
       procedure TCimletezoForm.PiszkozatClear;
// ===============================================================

begin
  CimletTabla.Close;
  CimletTabla.EmptyTable;
end;


// ===========================================================
      procedure TCimletezoForm.SqlParancs(_ukaz: string);
// ===========================================================

(* Végrehajtja a paraméterben adott SQL parancsot *)
begin
  with QUERYTABLA do
    begin
      close;
      Sql.Clear;
      SQL.Add(_ukaz);
      ExecSql;
    end;
end;


// ======================================================================
     procedure TCimletezoForm.NemRogziteniGombClick(Sender: TObject);
// ======================================================================

begin
  ModalResult := 2;
end;



// =======================================================
          procedure TCimletezoForm.Kimasol;
// =======================================================
  (* A _Vtag-nak 1 és _liveValutaDarab közé kell esni *)

var _aktstr: string;
    _qqErtek: integer;

begin
  if _Vtag<0 then exit;

  _qq := 1;
  _sumcim := 0;

  while _qq<15 do
    begin
      _aktedit := _cimedit[_qq];
      _aktpanel := _takpan[_qq];
      if not _aktpanel.Visible then
        begin
          _aktstr := _aktedit.Text;
          val(_aktstr,_aktbjegy,_code);
          if _code<>0 then _aktbjegy := 0;
          _aktedit.Text := inttoStr(_aktbJegy);
          _liveCimBankjegy[_vtag,_qq] := _aktbjegy;
          _qqertek := _cimlet[_qq]*_aktbjegy;
          _osszcimertek := _osszcimertek + _qqertek;
          _sumPan[_qq].Caption := Form1.ForintForm(_qqertek);
          _sumcim := _sumcim + _qqertek;
        end;
      inc(_qq);
    end;
  _liveOsszes[_vtag] := _sumcim;

  CimletezettPanel.Caption := Form1.Forintform(_sumCim);
  RogzitsdGomb.Enabled := True;
end;

// ======================================================
          procedure TCimletezoForm.Bemasol;
// ======================================================
(* A _Vtag-nak 0 és _ValutaDarab-1 közé kell esni *)

var _editDarab: integer;
    _editSor: string;
     _betu: char;

begin
  if _Vtag<0 then exit;

  _qq := 14;
  while _qq>0 do
    begin
      _aktCimletPanel := _cimGomb[_qq];
      _aktPanel := _takpan[_qq];

      _aktpanel.Visible := True;
      _aktcimletPanel.Font.Color := clGray;
      dec(_qq);
    end;

  ActiveControl := Rovnevpanel;
  _editDarab := _liveCimDarab[_vTag];
  _editSor := _liveCimsor[_vTag];
  _rovnev := _Dnem[_Vtag];      // A VÁLASZTOTT VALUTA RÖVID NEVE
  _longNev := _Dnev[_Vtag];     // A VÁLASZTOTT VALUTA HOSSZÚ NEVE

  RovNevPanel.Caption := _rovnev;     // A VALUTANEVEK KIJELZÉSE
  TeljesNevPanel.Caption := _longNev;

  _qq := 1;
  _sumCIm := 0;

  while _qq<15 do
    begin
      _aktedit := _cimedit[_qq];
      _aktbJegy := _liveCimBankjegy[_vtag,_qq];
      _aktedit.Text := inttostr(_aktbjegy);
      _aktertek := _aktbjegy*_cimlet[_qq];
      _aktsumPanel := _sumPan[_qq];
      _aktsumPanel.Caption := Form1.ForintForm(_aktertek);
      _sumCim := _sumcim + _aktertek;
      inc(_qq);
    end;

  CimletezettPanel.Caption := Form1.Forintform(_sumCim);

  _aktszin := clNavy;

  CimletezettPanel.Font.Color := _aktszin;
  _qq := _editdarab;
  while _qq>0 do
    begin
      _betu := _editSor[_qq];
      _aktSS := ord(_betu)-65;
      _aktedit := _cimedit[_aktss];

      _aktPanel := _takPan[_aktss];
      _aktPanel.Visible := False;

      _aktcimletpanel := _cimgomb[_aktss];
      _aktcimletPanel.Font.color := clBlack;
      dec(_qq);
    end;

  _aktedit.SetFocus;
end;



// ================================================================
      procedure TCimletezoForm.ExitGombClick(Sender: TObject);
// ================================================================

begin
  CimTarTabla.Close;
  CimletTabla.close;
  ModalResult := 2;
end;

// ===========================================
      procedure TCimletezoForm.KonstansTomb;
// ===========================================

begin
  _cimedit[1]  := ce1;
  _cimedit[2]  := ce2;
  _cimedit[3]  := ce3;
  _cimedit[4]  := ce4;
  _cimedit[5]  := ce5;
  _cimedit[6]  := ce6;
  _cimedit[7]  := ce7;
  _cimedit[8]  := ce8;
  _cimedit[9]  := ce9;
  _cimedit[10] := ce10;
  _cimedit[11] := ce11;
  _cimedit[12] := ce12;
  _cimedit[13] := ce13;
  _cimedit[14] := ce14;

  _cimgomb[1]  := cp1;
  _cimgomb[2]  := cp2;
  _cimgomb[3]  := cp3;
  _cimgomb[4]  := cp4;
  _cimgomb[5]  := cp5;
  _cimgomb[6]  := cp6;
  _cimgomb[7]  := cp7;
  _cimgomb[8]  := cp8;
  _cimgomb[9]  := cp9;
  _cimgomb[10] := cp10;
  _cimgomb[11] := cp11;
  _cimgomb[12] := cp12;
  _cimgomb[13] := cp13;
  _cimgomb[14] := cp14;

  _sumPan[1]  := sp1;
  _sumPan[2]  := sp2;
  _sumPan[3]  := sp3;
  _sumPan[4]  := sp4;
  _sumPan[5]  := sp5;
  _sumPan[6]  := sp6;
  _sumPan[7]  := sp7;
  _sumPan[8]  := sp8;
  _sumPan[9]  := sp9;
  _sumPan[10] := sp10;
  _sumPan[11] := sp11;
  _sumPan[12] := sp12;
  _sumPan[13] := sp13;
  _sumPan[14] := sp14;

  _valNevPanel[0]  := vp1;
  _valNevPanel[1]  := vp2;
  _valNevPanel[2]  := vp3;
  _valNevPanel[3]  := vp4;
  _valNevPanel[4]  := vp5;
  _valNevPanel[5]  := vp6;
  _valNevPanel[6]  := vp7;
  _valNevPanel[7]  := vp8;
  _valNevPanel[8]  := vp9;
  _valNevPanel[9] := vp10;
  _valNevPanel[10] := vp11;
  _valNevPanel[11] := vp12;
  _valNevPanel[12] := vp13;
  _valNevPanel[13] := vp14;
  _valNevPanel[14] := vp15;
  _valNevPanel[15] := vp16;
  _valNevPanel[16] := vp17;
  _valNevPanel[17] := vp18;
  _valNevPanel[18] := vp19;
  _valNevPanel[19] := vp20;
  _valNevPanel[20] := vp21;
  _valNevPanel[21] := vp22;
  _valNevPanel[22] := vp23;
  _valNevPanel[23] := vp24;
  _valNevPanel[24] := vp25;

  _takpan[1]  := takpanel1;
  _takpan[2]  := takpanel2;
  _takpan[3]  := takpanel3;
  _takpan[4]  := takpanel4;
  _takpan[5]  := takpanel5;
  _takpan[6]  := takpanel6;
  _takpan[7]  := takpanel7;
  _takpan[8]  := takpanel8;
  _takpan[9]  := takpanel9;
  _takpan[10] := takpanel10;
  _takpan[11] := takpanel11;
  _takpan[12] := takpanel12;
  _takpan[13] := takpanel13;
  _takpan[14] := takpanel14;
end;




// ====================================================
        procedure TCimletezoForm.NemNapzaras;
// ====================================================

var i: integer;

begin
  for i := 0 to 24 do
    begin
      _aktPanel := _valNevpanel[i];
      _aktpanel.Font.Color := clNavy;
    end;
  RogzitsdGomb.Enabled := False;
end;

// ===========================================
      procedure TCimletezoForm.Nevbeiro;
// ===========================================

begin
  _qq := 0;

  while _qq<_ValutaDarab do
    begin
       _aktdnem := _DNem[_qq+1];
       _aktdnev := _DNev[_qq+1];
      _aktpanel := _valNevPanel[_qq];
      _aktpanel.Caption := _aktdnev;
      inc(_qq);
    end;
end;


// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
// =============================================================================
         procedure TCimletezoForm.CimletRogzites(Sender: TObject);
// =============================================================================

begin
  _aktFdbPath := 'c:\receptor\database\v'+inttostr(_aktpenztar)+'.FDB';
  CimtarRogzites;
end;



// ==================================================
        procedure TCimletezoForm.CimtarRogzites;
// ==================================================

var
    i,j: integer;

begin

  _tablaNev := 'CIMT'+midstr(_zarodstring,3,2)+midstr(_zarodstring,6,2);
  

  CimtarTabla.Close;
  CimTarDbase.Connected := False;
  CimTarDbase.DatabaseName := _aktFdbPath;
  CimTarDbase.Connected := true;

  CimTarTabla.TableName := _Tablanev;

  if not CimTarTabla.Exists then MakeCimtar(_aktfdbPath,_tablanev);
  if cimTartranz.InTransaction then cimTartranz.Commit;
  CimTartranz.StartTransaction;

  _pcs := 'DELETE FROM ' + _tablanev + ' WHERE DATUM=' + chr(39) + _zaroDstring + chr(39);

  with QueryTabla do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;
   if cimtarTranz.InTransaction then CimtarTranz.commit;
   CimTartranz.StartTransaction;

   CimTarTabla.Open;
   CimTarTabla.Refresh;

   if _osszcimertek=0 then
     begin
       with CimTarTabla do
         begin
           Append;
           Edit;
           FieldByName('DATUM').AsString := _zaroDString;
           FieldByname('VALUTANEM').AsString := 'HUF';
           Post;
           Close;
         end;
       ShowMessage('ÜRES CIMLETJEGYZÉKET RÖGZITETTEM !');
       CimtarTranz.Commit;
       CimtarTabla.Close;
       Exit;
     end;

   _qq := 0;
   while _qq <_ValutaDarab do
     begin
       _osszesen := _liveOsszes[_qq];
       _aktDnem := _Dnem[_qq+1];

       for i := 1 to 14 do
         begin
           _aktBjegy := _liveCimBankjegy[_qq,i];
           _cic[i] := _aktBjegy;
         end;

       if _osszesen>0 then
         begin

           with CimTarTabla do
             begin
               Append;
               Edit;
               FieldByName('DATUM').AsString := _zaroDString;
               FieldByName('VALUTANEM').asString := _aktdnem;
               FieldByNAme('OSSZESEN').asInteger := _osszesen;
             end;

           for  j := 1 to 14 do
             begin
               _aktMez := 'CIMLET'+INTTOSTR(j);
               CimTarTabla.FieldByName(_aktmez).asInteger := _cic[j];
             end;

           CimTarTabla.Post;
         end;
       inc(_qq);
     end;
   CimtarTranz.Commit;
   CimTarTabla.Close;
   ShowMessage('A '+_longDString+'-I CIMLETEZÉST RÖGZITETTEM A NAPI CIMLETEK GYÜJTÖJÉBE');
   Modalresult := 1;
end;

(*
procedure TCimletezoForm.CIMLETLISTAGOMBClick(Sender: TObject);
begin
   PiszkozatRogzites;
   CimletLista.showmodal;
end;

procedure TCimletezoForm.PiszkozatRogzites;

begin
  PotcimletTabla.close;
  PotcimletTabla.EmptyTable;
end;
*)

// ==========================================================================
      procedure TCimletezoForm.MakeCimtar(_fdbNev: string; _dNev: string);
// ==========================================================================

var 
    _sorveg : string;
begin
  _sorveg := chr(13)+chr(10);
  
  QueryDbase.connected := false;
  QueryDbase.DatabaseName := _fdbNev;
  QueryDbase.Connected := true;
  if QueryTranz.intransaction then QueryTranz.commit;
  QueryTranz.StartTransAction;
  _pcs := 'CREATE TABLE ' + _dNev + ' ('+_sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'OSSZESEN INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET1 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET2 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET3 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET4 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET5 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET6 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET7 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET8 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET9 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET10 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET11 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET12 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET13 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET14 INTEGER)';
  with queryTabla do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;
  _pcs := 'CREATE INDEX IDX_'+_dnev+' ON '+_dnev+' (VALUTANEM)';
  with queryTabla do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;

  _pcs := 'CREATE INDEX  IDX_1'+_dnev+' ON '+_dnev+' (DATUM)';
  with queryTabla do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;
  QueryTranz.commit;
  queryTabla.Close;
end;

end.
