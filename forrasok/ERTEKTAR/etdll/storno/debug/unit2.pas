unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, Grids, DBGrids, IBDatabase, IBCustomDataSet, IBQuery,
  ExtCtrls, StdCtrls, StrUtils, Buttons, IBTable, jpeg;

type
  TSTORNOFORM = class(TForm)
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    STORNOSOURCE: TDataSource;
    TEMPQUERY: TIBQuery;
    TEMPDBASE: TIBDatabase;
    TEMPTRANZ: TIBTransaction;
    Panel1: TPanel;
    BIZONYLATRACS: TDBGrid;
    radiok: TGroupBox;
    Label8: TLabel;
    Label9: TLabel;
    VISSZAGOMB: TBitBtn;
    STORNOGOMB: TBitBtn;
    BIZELOPANEL: TPanel;
    Label1: TLabel;
    bizvegedit: TEdit;
    surepanel: TPanel;
    Label2: TLabel;
    SUREBIZSZAMPANEL: TPanel;
    Label3: TLabel;
    IGENGOMB: TBitBtn;
    NEMGOMB: TBitBtn;
    VEGPANEL: TPanel;
    Label4: TLabel;
    Label5: TLabel;
    BIZSZAMPANEL: TPanel;
    Label6: TLabel;
    ERTEKPANEL: TPanel;
    STARTGOMB: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    LASTKERDOPANEL: TPanel;
    Label11: TLabel;
    maystornogomb: TBitBtn;
    nosuccessgomb: TBitBtn;
    Shape1: TShape;
    FUGGONY: TPanel;
    VALUTATABLA: TIBTable;
    Label12: TLabel;
    INDOKEDIT: TEdit;
    KILEPO: TTimer;
    Image1: TImage;
    TEMPQUERYFORINTERTEK: TIntegerField;
    TEMPQUERYBIZONYLATSZAM: TIBStringField;
    radiopanel: TPanel;
    UR: TRadioButton;
    UFR: TRadioButton;
    FR: TRadioButton;
    FFR: TRadioButton;

    procedure FormActivate(Sender: TObject);
    procedure BizLista;
    function FtForm(_ft: integer): string;

    procedure ValutaParancs(_ukaz: string);

    procedure URClick(Sender: TObject);
    procedure FRClick(Sender: TObject);

    procedure UFRClick(Sender: TObject);
    procedure FFRClick(Sender: TObject);

    procedure AlapAdatBeolvasas;
    procedure SureStorno;
    procedure SzamlaBeolvasas;
    procedure StornoFolyamat;

    procedure VISSZAGOMBClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);

    procedure NEMGOMBClick(Sender: TObject);
    procedure STORNOGOMBClick(Sender: TObject);
    procedure radiokClick(Sender: TObject);
    procedure IGENGOMBClick(Sender: TObject);
    procedure BIZONYLATRACSDblClick(Sender: TObject);
    procedure ZCOUNTEDITEnter(Sender: TObject);
    procedure ZCOUNTEDITExit(Sender: TObject);
  
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure STARTGOMBClick(Sender: TObject);

    function Nulele(_b: integer;_hh: byte): string;
  
    procedure INDOKEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure KILEPOTimer(Sender: TObject);
  

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  STORNOFORM: TSTORNOFORM;

   _vnem,_ejel: array[1..27] of string;
  _arf,_bjegy,_ftert: array[1..27] of integer;

  _aktdnem,_elojel,_ftbiz: string;
  _arfolyam,_bankjegy,_forintertek: integer;

  _utkeres,_tarsptar,_stornoindok,_pcs,_keres,_bizonylatszam: string;
  _akttipus,_stblokk,_megnyitottnap,_aktidos,_indok,_trTip: string;

  _sorveg: string = chr(13)+chr(10);

  _soft,_tarspt,_oft,_code,_kezdij,_blokk,_spk: integer;

   _top,_left,_width,_height: word;
   _bill,_tetel,_maistornodarab,_maxnum,_nlen,_y,_napistorno: byte;

   _ptkod,_bizelokod,_bizker,_origbizonylat,_tipus,_mezo: string;
   _stornobizonylat: string;

   _ezstorno,_megvan: boolean;

function regeneralorutin: integer; stdcall; external 'c:\ertektar\bin\regen.dll' name 'regeneralorutin';
function blokknyomtatas(_para: integer):integer; stdcall; external 'c:\ertektar\bin\bloknyom.dll' name 'blokknyomtatas';
function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\ertektar\bin\super.dll' name 'supervisorjelszo';

function stornorutin: integer; stdcall;

implementation

{$R *.dfm}

function stornorutin: integer; stdcall;
begin
  stornoform := TstornoForm.Create(Nil);
  result := stornoform.showmodal;
  stornoform.free;
end;


// =============================================================================
          procedure TSTORNOFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top := round((_height-455)/2);
  _left := round((_width-580)/2);

  Top    := _top;
  Left   := _left;
  Height := 455;
  Width  := 580;


  SurePanel.Visible := false;
  Vegpanel.visible := false;

  AlapadatBeolvasas;

  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

 
  _keres := '';

end;

// =============================================================================
                 procedure TStornoForm.AlapadatBeolvasas;
// =============================================================================

begin
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT* FROM PENZTAR');
      Open;
      _ptKod := trim(FieldByName('PENZTARKOD').asString);
      close;
      sql.clear;
      sql.add('SELECT* FROM HARDWARE');
      Open;
      _megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').AsString);
      _napistorno := FieldByName('NAPISTORNO').asInteger;
      Close;
    end;
  Valutadbase.close;

  while length(_ptkod)<3 do _ptkod := '0'+_ptkod;
end;


// =============================================================================
              procedure TSTORNOFORM.URClick(Sender: TObject);
// =============================================================================

begin
  _trTip := 'U';
  BizLista;
end;

// =============================================================================
              procedure TSTORNOFORM.FRClick(Sender: TObject);
// =============================================================================

begin
  _trTip := 'F';
  BizLista;
end;

// =============================================================================
              procedure TSTORNOFORM.UFRClick(Sender: TObject);
// =============================================================================

begin
  _trtip := 'UF';
  BizLista;
end;

// =============================================================================
              procedure TSTORNOFORM.FFRClick(Sender: TObject);
// =============================================================================

begin
  _trTip := 'FF';
  BizLista;
end;


// =============================================================================
                procedure TstornoForm.BizLista;
// =============================================================================

begin
  _BIZKER := _TRTIP;
  _bizelokod := _trtip+_ptKod;

  if length(_TRTIP)=2 then
    begin
      _maxnum := 5;
      BizeloPanel.Caption := _bizelokod;
    end else
    begin
      _maxnum := 6;
      BizeloPanel.caption := '   '+_bizelokod;
    end;
  Bizvegedit.MaxLength := _maxnum;
  Bizvegedit.Clear;
  Bizelopanel.repaint;

  _KERES := '';
  KEYPREVIEW := True;
  _bizker := _bizelokod;

  _pcs := 'SELECT * FROM BLOKKFEJ' + _sorveg;
  _pcs := _pcs + 'WHERE (BIZONYLATSZAM LIKE ' +chr(39)+_BIZKER+'%'+chr(39);
  _pcs := _pcs + ') AND (STORNO=1)';

  TempDbase.connected := true;
  with TempQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;
  Bizonylatracs.SetFocus;
end;

// =============================================================================
           function TstornoForm.Nulele(_b: integer;_hh: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  while length(result)<_hh do result := '0' + result;
end;

// =============================================================================
           procedure TSTORNOFORM.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  ValutaQuery.close;
  ValutaDbase.close;
  Modalresult := 1;
end;

// =============================================================================
     procedure TSTORNOFORM.FormKeyPress(Sender: TObject; var Key: Char);
// =============================================================================

var _bill,_wk: byte;
    _ujkeres: string;

begin
  _bill := ord(key);

  IF (_BILL>95) AND (_bill<106) then _bill := _bill-48;

  if (_bill>47) AND (_bill<58) then
    begin
      _wk := length(_keres);
      if _wk=_maxnum then exit;
      _ujkeres := _keres + chr(_bill);
     
      _bizker := _bizelokod + _ujkeres;
      _megvan := Tempquery.Locate('BIZONYLATSZAM',_BIZKER,[loPartialKey]);
      if _megvan then
        begin
          _keres := _ujkeres;
          BizvegEdit.Text := _keres;
         
        end;
      exit;
    end;

  if _bill=8 then
    begin
      _wk := length(_keres);
     
      if _wk=0 then exit;
      if _wk=1 then
        begin
          _keres := '';
          Bizvegedit.Text := '';
          exit;
        end;
      dec(_wk);
      _keres := leftstr(_keres,_wk);
      BizVegedit.Text := _keres;
      exit;
    end;

  if _bill=13 then
    begin
      if length(_keres)<_maxnum then
        begin
          _bizker := trim(Tempquery.FieldbyName('BIZONYLATSZAM').AsString);
           _origbizonylat := _bizker;
          Surestorno;
          exit;
        end;
    end;
end;

// =============================================================================
                        procedure TstornoForm.Surestorno;
// =============================================================================

begin
  Keypreview := false;
  SzamlaBeolvasas;

  if _napistorno>2 then
    begin
      _spk := supervisorjelszo(0);
      if _spk<>1 then
        begin
          Modalresult := 2;
          exit;
        end;
    end;

  SureBizszamPanel.caption := _bizker;
  SurebizszamPanel.repaint;
  with SurePanel do
    begin
      top :=  110;
      left := 150;
      Visible := true;
      repaint;
    end;
  Activecontrol := Nemgomb;
end;

// =============================================================================
            procedure TSTORNOFORM.NEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  SurePanel.Visible := False;
  Keypreview := true;
end;

// =============================================================================
            procedure TSTORNOFORM.STORNOGOMBClick(Sender: TObject);
// =============================================================================

begin
  STORNOGOMB.Enabled := fALSE;
  _bizker := trim(Tempquery.FieldbyName('BIZONYLATSZAM').AsString);
  _origbizonylat := _bizker;
  SureStorno;
end;

// =============================================================================
           procedure TSTORNOFORM.radiokClick(Sender: TObject);
// =============================================================================

begin
  Keypreview := true;
end;

// =============================================================================
             procedure TSTORNOFORM.IGENGOMBClick(Sender: TObject);
// =============================================================================

begin
  SurePanel.visible := False;

  Bizszampanel.Caption := _origbizonylat;
  ertekPanel.Caption  := ftform(_forintertek)+' Ft';
  IndokEdit.Clear;
  StartGomb.Enabled := False;

  with VegPanel do
    begin
      top := 88;
      left := 88;
      Visible := true;
    end;
  ActiveControl := Indokedit;

end;

// =============================================================================
         procedure TSTORNOFORM.BIZONYLATRACSDblClick(Sender: TObject);
// =============================================================================

begin
  _bizker := trim(Tempquery.FieldbyName('BIZONYLATSZAM').AsString);
  _origbizonylat := _bizker;
  Surestorno;
end;

// =============================================================================
           procedure TSTORNOFORM.ZCOUNTEDITEnter(Sender: TObject);
// =============================================================================

begin
  tedit(Sender).color := $b0ffff;
end;

// =============================================================================
           procedure TSTORNOFORM.ZCOUNTEDITExit(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clwindow;
end;



// =============================================================================
            function Tstornoform.FtForm(_ft: integer): string;
// =============================================================================

var _wr,_f1: byte;

begin
  result := inttostr(_ft);
  if _ft<1000 then exit;

  _wr := length(result);
  if _wr>6 then
    begin
      _f1 := _wr-6;
      result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3)+' '+midstr(result,_f1+4,3);
      exit;
    end;
  _f1 := _wr-3;
  result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3);
end;

// =============================================================================
           procedure TSTORNOFORM.MEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  TempQuery.close;
  Tempdbase.close;
  Modalresult := 2;
end;

// =============================================================================
                   procedure TstornoForm.SzamlaBeolvasas;
// =============================================================================

begin
  _pcs := 'SELECT * FROM BLOKKFEJ' + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39)+_origbizonylat+chr(39);
  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _tipus := FieldByNAme('TIPUS').asString;
      _oft := FieldByNAme('FORINTERTEK').asInteger;
      _tarsptar := FieldByNAme('TARSPENZTARKOD').asString;
      Close;
    end;

  _pcs := 'SELECT * FROM BLOKKTETEL' + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39)+_origbizonylat+chr(39);
   Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  _tetel := 0;
  while not ValutaQuery.Eof do
    begin
      _aktdnem := ValutaQuery.FieldbyNAme('VALUTANEM').asString;
      _arfolyam := ValutaQuery.FieldByNAme('ARFOLYAM').asInteger;
      _bankjegy := ValutaQuery.FieldByNAme('BANKJEGY').asInteger;
      _forintertek := ValutaQuery.FieldByNAme('FORINTERTEK').asInteger;
      _elojel := ValutaQuery.FieldByNAme('ELOJEL').asString;

      inc(_tetel);

      _vnem[_tetel] := _aktdnem;
      _arf[_tetel] := _arfolyam;
      _bjegy[_tetel] := _bankjegy;
      _ftert[_tetel] := _forintertek;
      _ejel[_tetel] := _elojel;

      ValutaQuery.next;
    end;
  ValutaQuery.close;
  ValutaDbase.close;
end;


// =============================================================================
            procedure TSTORNOFORM.STARTGOMBClick(Sender: TObject);
// =============================================================================


begin
  Tempquery.close;
  Tempdbase.close;

  VegPanel.Visible := False;
  StornoFolyamat;

  ModalResult := 1;
end;


procedure TStornoForm.StornoFolyamat;

begin
  _stornoindok := trim(Indokedit.Text);

  _aktidos := timetostr(Time);
  if midstr(_aktidos,2,1)=':' then _aktidos := '0'+_aktidos;
  _aktidos := leftstr(_aktidos,5);

  if (_tipus='F') or (_tipus='U') then
    begin
      if midstr(_origbizonylat,2,1)='F' then _tipus:=leftstr(_origbizonylat,2)
    end;

  if _tipus='U' then _mezo  := 'LASTATVET';
  if _tipus='F' then _mezo  := 'LASTATADAS';
  if _tipus='UF' then _mezo := 'LASTFTATVETEL';
  if _tipus='FF' then _mezo := 'LASTFTATADAS';

  _pcs := 'UPDATE BLOKKFEJ SET STORNO=2' + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39)+_origbizonylat+chr(39);
  ValutaParancs(_pcs);

  _pcs := 'UPDATE BLOKKTETEL SET STORNO=2' + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39)+_origbizonylat+chr(39);
  ValutaParancs(_pcs);

  ValutaDbase.Connected := True;
  if ValutaTranz.InTransaction then Valutatranz.commit;
  Valutatranz.StartTransaction;

  ValutaTabla.close;
  ValutaTabla.tablEname := 'UTOLSOBLOKKOK';
  ValutaTabla.Open;
  _blokk := ValutaTabla.FieldByNAme(_mezo).asInteger;
  inc(_blokk);

  ValutaTabla.edit;
  ValutaTabla.FieldByNAme(_mezo).asInteger := _blokk;
  ValutaTabla.Post;
  ValutaTranz.commit;
  Valutadbase.close;

  _nlen := 6;
  if length(_tipus)=2 then _nLen := 5;
  _stornoBizonylat := _bizelokod + nulele(_blokk,_nLen);
  _oft := trunc(_oft*(-1));
  _forintertek := trunc(_forintertek*(-1));
  _kezdij := trunc(_kezdij*(-1));
  _tipus := leftstr(_tipus,1);


  _pcs := 'INSERT INTO BLOKKFEJ (BIZONYLATSZAM,TIPUS,DATUM,IDO,FORINTERTEK,';
  _pcs := _pcs + 'TETEL,STORNO)'+_sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39)+_stornoBizonylat+chr(39)+',';
  _pcs := _pcs + chr(39)+_tipus+chr(39)+',';
  _pcs := _pcs + chr(39) + _megnyitottnap + chr(39)+',';
  _pcs := _pcs + chr(39) + _aktidos + chr(39) + ',';
  _pcs := _pcs + inttostr(_oft) + ',';
  _pcs := _pcs + inttostr(_tetel) + ',';
  _pcs := _pcs + '3)';
  ValutaParancs(_pcs);

  _y := 1;
  while _y<=_tetel do
    begin
      _aktdnem := _vnem[_y];
      _arfolyam := _arf[_y];
      _bankjegy := _bjegy[_y];
      _forintertek := _ftert[_y];
      _elojel := _ejel[_y];

      _bankjegy := trunc(_bankjegy*(-1));
      _forintertek := trunc(_forintertek*(-1));

      _pcs := 'INSERT INTO BLOKKTETEL (BIZONYLATSZAM,VALUTANEM,ARFOLYAM,';
      _pcs := _pcs + 'BANKJEGY,FORINTERTEK,';
      _Pcs := _pcs + 'STORNO,DATUM)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + CHR(39) + _STORNOBIZONYLAT +chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + inttostr(_arfolyam) + ',';
      _pcs := _pcs + inttostr(_bankjegy) + ',';
      _pcs := _pcs + inttostr(_forintertek) + ',';
      _pcs := _pcs + '3,';
      _pcs := _pcs + chr(39) + _megnyitottnap + chr(39) + ')';
      ValutaParancs(_pcs);

      _pcs := 'INSERT INTO VTEMP (VALUTANEM,ARFOLYAM,BANKJEGY,FORINTERTEK)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + inttostr(_arfolyam)+ ',';
      _pcs := _pcs + inttostr(_bankjegy) + ',';
      _pcs := _pcs + inttostr(_forintertek) + ')';
      ValutaParancs(_pcs);

      inc(_y);
    end;

  _pcs := 'UPDATE VTEMP SET BIZONYLATSZAM='+chr(39)+_STORNObizonylat+chr(39)+',';
  _pcs := _pcs + 'STORNOBIZONYLAT='+chr(39)+_ORIGBIZONYLAT+chr(39)+',';
  _pcs := _pcs + 'STORNO=3,TIPUS='+CHR(39)+_tipus+chr(39);
  _pcs := _pcs + ',DATUM=' + chr(39) + _megnyitottnap + chr(39);
  _pcs := _pcs + ',IDO=' + chr(39) + _aktidos + chr(39);
  _pcs := _pcs + ',STORNOINDOK=' + chr(39)+ _stornoindok + chr(39);
  ValutaParancs(_pcs);

   blokknyomtatas(1);
   _ftbiz := midstr(_stornobizonylat,2,1);
   if _ftbiz='F' then blokknyomtatas(2);

   inc(_napistorno);
   _pcs := 'UPDATE HARDWARE SET NAPISTORNO=' + inttostr(_napistorno);
   ValutaParancs(_pcs);

   regeneralorutin;
end;

// =============================================================================
             procedure TSTORNOFORM.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  ValutaDbase.connected := true;
  if valutatranz.InTransaction then valutatranz.Commit;
  Valutatranz.StartTransaction;
  with valutaquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  ValutaTranz.commit;
  Valutadbase.close;
end;      

// =============================================================================
     procedure TSTORNOFORM.INDOKEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)=13 then
    begin
      Startgomb.Enabled:= True;
      Activecontrol := StartGomb;
    end;
end;





procedure TSTORNOFORM.KILEPOTimer(Sender: TObject);
begin
  Kilepo.Enabled := False;
  Modalresult := 2;
end;

end.








