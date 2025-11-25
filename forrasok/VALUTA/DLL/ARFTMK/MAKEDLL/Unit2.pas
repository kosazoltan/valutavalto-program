unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Grids, DBGrids, ExtCtrls, DB, StrUtils,
  DBTables, IBDatabase, IBCustomDataSet, IBTable, IBQuery,printers;

type
  TARFOLYAMTMKFORM = class(TForm)

    ARFOLYAMSOURCE: TDataSource;

           Panel1: TPanel;
           Panel3: TPanel;
           Panel4: TPanel;
         TMKPANEL: TPanel;
    NYOMTATOPANEL: TPanel;
        DNEMPANEL: TPanel;
       NYITOPANEL: TPanel;
     BEVETELPANEL: TPanel;
      KIADASPANEL: TPanel;
        ZAROPANEL: TPanel;

    ARFOLYAMRACS: TDBGrid;

       ARFNYOMGOMB: TBitBtn;
   ELSZARFNYOMGOMB: TBitBtn;
        ESCAPEGOMB: TBitBtn;
       LETOLTOGOMB: TBitBtn;
      NYOMTATOGOMB: TBitBtn;
          SICCGOMB: TBitBtn;
       EARFEDIT: TEdit;
    ELSZARFEDIT: TEdit;
       VARFEDIT: TEdit;

        Label1: TLabel;
        Label2: TLabel;
        Label3: TLabel;
        Label4: TLabel;
        Label5: TLabel;
        Label6: TLabel;
        Label7: TLabel;
        Label8: TLabel;
        Label9: TLabel;
       Label10: TLabel;
       Label11: TLabel;
       Label12: TLabel;
       Label13: TLabel;
       Label16: TLabel;
    DNEM1LABEL: TLabel;
    DNEM2LABEL: TLabel;
    DNEM3LABEL: TLabel;
    DNEM4LABEL: TLabel;
    DNEM5LABEL: TLabel;
    DNEM6LABEL: TLabel;
    DNEM7LABEL: TLabel;
    ARFOLYAMDBASE: TIBDatabase;
    ARFOLYAMTRANZ: TIBTransaction;
    HARDWARETABLA: TIBTable;
    HARDWAREDBASE: TIBDatabase;
    HARDWARETRANZ: TIBTransaction;
    HARDWAREQUERY: TIBQuery;
    ARFOLYAMQUERY: TIBQuery;
    arfolyamokegomb: TBitBtn;
    MNBLETOLTOGOMB: TBitBtn;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    ARFOLYAMQUERYVALUTANEM: TIBStringField;
    ARFOLYAMQUERYVALUTANEV: TIBStringField;
    ARFOLYAMQUERYVETELIARFOLYAM: TFloatField;
    ARFOLYAMQUERYELADASIARFOLYAM: TFloatField;
    ARFOLYAMQUERYELSZAMOLASIARFOLYAM: TFloatField;
    ARFOLYAMQUERYMODOSITOSZAZALEK: TFloatField;
    ARFOLYAMQUERYNYITO: TIntegerField;
    ARFOLYAMQUERYBEVETEL: TIntegerField;
    ARFOLYAMQUERYKIADAS: TIntegerField;
    ARFOLYAMQUERYZARO: TIntegerField;
    ARFOLYAMQUERYK1VETEL: TFloatField;
    ARFOLYAMQUERYK2VETEL: TFloatField;
    ARFOLYAMQUERYK1ELADAS: TFloatField;
    ARFOLYAMQUERYK2ELADAS: TFloatField;
    Shape6: TShape;
    Shape2: TShape;
    Shape3: TShape;
    GOMBTAKAROPANEL: TPanel;
    Shape1: TShape;
    DNEVPANEL: TPanel;
    Panel5: TPanel;
    KEZIALLITOGOMB: TBitBtn;

    procedure AlapadatBeolvasas;
    procedure ARFOLYAMRACSKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ARFNYOMGOMBClick(Sender: TObject);
    procedure ARFNYOMGOMBEnter(Sender: TObject);
    procedure ARFNYOMGOMBExit(Sender: TObject);
    procedure ARFOLYAMRACSDblClick(Sender: TObject);
    procedure ArftmkNyomtatas;
    procedure DNevEDITEnter(Sender: TObject);
    procedure DNevEditExit(Sender: TObject);
    procedure EgyvalutaTmk;

    procedure ElszarfModositas;
    procedure ELSZARFNYOMGOMBClick(Sender: TObject);
    procedure EscapeGOMBClick(Sender: TObject);
  
    procedure FormCreate(Sender: TObject);
    procedure LetoltoGombClick(Sender: TObject);
    procedure NyomtatoGombClick(Sender: TObject);
    procedure NyomtatoPanelClick(Sender: TObject);
  
    procedure SICCGOMBClick(Sender: TObject);
    procedure BlokkFocimiro;
    procedure TextKiiro;
    procedure KozepreIr(_szoveg: string);


    function Forintform(_ft: integer): string;
    procedure ValutaParancs(_ukaz: string);
    function Elokieg(_s: string;_hh: byte): string;
    function Kieg(_s: string; _hh: byte): string;
    function Validalo(_reals: string): integer;
    function MertekCtrl(_szazalek: real):boolean;
    function DuplaSupkod():boolean;
    function Arfkiir(_arf: real): string;
    procedure VARFEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure EARFEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ELSZARFEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure arfolyamokegombClick(Sender: TObject);
    procedure ELSZARFGOMBClick(Sender: TObject);
    procedure ELSZARFEDITExit(Sender: TObject);
    procedure ELSZARFEDITChange(Sender: TObject);
    procedure MNBLETOLTOGOMBClick(Sender: TObject);

    function Getidos: string;
    procedure KEZIALLITOGOMBClick(Sender: TObject);
 


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ARFOLYAMTMKFORM: TARFOLYAMTMKFORM;


  _eddigedit,_ujdnem,_ujdnev,_pcs,_aktdnem,_aktdnev,_megnyitottnap: string;
  _idos,_kftnev,_CEGNEV: string;
  _homepenztarkod,_homepenztarnev,_homepenztarcim: string;

  _orivarf,_oriearf,_code: integer;
  _oke,_aktvarf,_aktearf,_aktelszarf,_nyito,_bevetel,_Kiadas,_zaro: integer;

  _printer,_homepenztarszam: byte;
  _sorveg: string = chr(13)+chr(10);

  _elszModable,_elszvalt,_maykezi: boolean;

  _top,_left,_height,_width: word;
  _LFile: textfile;

function arfolyamletoltes(_para: integer): integer;stdcall; external 'c:\valuta\bin\getarf.dll' name 'arfolyamletoltes';
function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';
function irodaarfolyamrutin: integer; stdcall; external 'c:\valuta\bin\irarfoly.dll' name 'irodaarfolyamrutin';

function arfolyamtmkrutin: integer; stdcall;

implementation

{$R *.dfm}


function arfolyamtmkrutin: integer; stdcall;

begin
  ArfolyamTmkForm := Tarfolyamtmkform.Create(Nil);
  result := ArfolyamtmkForm.showmodal;
  Arfolyamtmkform.free;
end;  



// =============================================================================
               procedure TARFOLYAMTMKFORM.FormCreate(Sender: TObject);
// =============================================================================

begin
  _height := screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  _top := round((_height-768)/2);
  _left := round((_width-1024)/2);

  Top    := _top;
  Left   := _left;
  Height := 768;
  Width  := 1024;

  _elszModable := False;
  _elszValt := False;

  GombTakaroPanel.Visible := False;

  AlapAdatBeolvasas;

  KeziAllitogomb.Enabled := True;
  _maykezi := False;

  TmkPanel.Visible      := False;
  NyomtatoPanel.Visible := False;

  Arfolyamdbase.Close;
  ArfolyamDbase.Connected := True;
  if ArfolyamTranz.InTransaction then arfolyamTranz.Commit;

  _pcs := 'SELECT * FROM ARFOLYAM ORDER BY VALUTANEM';
  with ArfolyamQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;


  ArfolyamRacs.Visible := True;
  ActiveControl := ArfolyamRacs;
end;

// =============================================================================
    procedure TARFOLYAMTMKFORM.ARFOLYAMRACSKeyDown(Sender: TObject;
                                 var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  EscapeGomb.Cancel := True;
  if ord(key)=13 then
    begin
      EgyValutaTmk;
      Exit;
    end;

// F8 - Nyomtatni akar
  if ord(key)=119 then
    begin
      ArfTmkNyomtatas;
      Exit;
    end;
end;

// =============================================================================
                  procedure TArfolyamTmkForm.EgyvalutaTmk;
// =============================================================================
        // Egy valuta árfolyamainak módositása


begin
   if NOT _maykezi then
     begin
       Showmessage('KÉRJEN ENGEDÉLYT A MÓDOSITÁSRA');
       exit;
     end;  

  with GombtakaroPanel do
    begin
      Top := 704;
      Left := 24;
      Visible := true;
      Repaint;
    end;

  EscapeGomb.Cancel := False;
  with ArfolyamQuery do
    begin

      // Beolvassa a módositandó valuta adatait:

      _aktdnem := Fieldbyname('VALUTANEM').AsString;
      _aktdnev := FieldByname('VALUTANEV').asString;
      _aktvarf := FieldByName('VETELIARFOLYAM').asInteger;
      _aktearf := FieldByName('ELADASIARFOLYAM').asInteger;
      _aktelszarf := FieldByname('ELSZAMOLASIARFOLYAM').asInteger;

      _nyito   := FieldByNAme('NYITO').asInteger;
      _bevetel := FieldByname('BEVETEL').asInteger;
      _kiadas  := FieldByNAme('KIADAS').asInteger;
      _zaro    := FieldByName('ZARO').asInteger;
    end;


  // ----------------------------------------------------------------

  if _aktdnem='HUF' then
    begin
      GombtakaroPanel.Visible := false;
      ShowMessage('A FORINT ÁRFOLYAMA NEM VÁLTOZTATHATÓ');
      SiccGombClick(NIL);
      Exit;
    end;


  // Ha nincs még elszámoló árfolyam, akkor le kell tölteni:

  if _aktelszarf=0 then
    begin
      GombtakaroPanel.Visible := false;
      ShowMessage('AZ ELSZÁMOLÓ ÁRFOLYAMOKAT LE KELL TÖLTENI A SZERVERRÕL');
      SiccGombClick(NIL);
      Exit;
    end;

  // Az eddigi két árfolyamot eltároljuk

  _orivarf := _aktvarf;
  _oriearf := _aktearf;

  // A módosítandó valuta nevének kijelzése:

  _aktdnem := trim(_aktdnem);
  _aktdnev := trim(_aktdnev);

  DnemPanel.Caption := _aktdnem;
  DnevPanel.Caption := _aktDnev;

  // A három árfolyam kiirása az editekbe és elszámoló módositó gombra:

  VarfEdit.Text := intToStr(_aktvarf);
  Earfedit.Text := intToStr(_aktEarf);
  ElszarfEdit.Text := intToStr(_aktelszarf);

  // A napi egyenleg tételeinek kijelzése:

  NyitoPanel.Caption := ForintForm(_nyito);
  BevetelPanel.Caption := ForintForm(_bevetel);
  Kiadaspanel.Caption := ForintForm(_kiadas);
  ZaroPanel.Caption := Forintform(_zaro);

  // Az valuta jelének kiirása az összes helyre:

  Dnem1Label.Caption := _aktdnem;
  Dnem2Label.Caption := _aktdnem;
  Dnem3Label.Caption := _aktdnem;
  Dnem4Label.Caption := _aktdnem;
  Dnem5Label.Caption := _aktdnem;
  Dnem6Label.Caption := _aktdnem;
  Dnem7Label.Caption := _aktdnem;

  // Az árfolyamrács eltünik, a Query bezáródik.

  ArfolyamRacs.Visible := False;
  ArfolyamQuery.Close;
  ArfolyamDbase.close;

  // Itt a elõjön a módosító panel az összes objektumával:

  with Tmkpanel do
    begin
      Top := 150;
      Left := 250;
      Visible := true;
    end;

  // Elsõnek a vételi-árfolyamot ajánlja fel a módositásra:

  ActiveControl := VarfEdit;
end;

function TarfolyamTmkForm.Forintform(_ft: integer): string;

var _f1,_w1: byte;

begin
  result := inttostr(_ft);
  _w1 := length(result);
  if _w1<4 then exit;

  if _w1>6 then
    begin
      _f1 := _w1-6;
      result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3)+' '+midstr(result,_f1+4,3);
      exit;
    end;

  _f1 := _w1-3;
  result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3);
end;




// =============================================================================
        procedure TARFOLYAMTMKFORM.arfolyamokegombClick(Sender: TObject);
// =============================================================================

var  _veltSzaz,_eeltSzaz: real;
     _VValt,_evalt: boolean;

begin


  _aktelszarf := validalo(elszarfedit.Text);
  if _aktelszarf=0 then exit;

  _aktvarf := validalo(varfedit.Text);
  if _aktvarf=0 then exit;

  if _aktVarf>=_aktelszarf then
    begin
      GombtakaroPanel.Visible := false;
      Showmessage('A VÉTELI ÁRFOLYAMNAK KISEBBNEK KELL LENNI AZ ELSZÁMOLÓ ÁRFOLYAMNÁL');
      exit;
    end;

  _aktearf := validalo(earfedit.Text);
  if _aktearf=0 then exit;

  if _aktEarf<=_aktelszarf then
    begin
      GombtakaroPanel.Visible := false;
      Showmessage('AZ ELADÁSI ÁRFOLYAMNAK NAGYOBBNAK KELL LENNI AZ ELSZÁMOLÓ ÁRFOLYAMNÁL');
      exit;
    end;

  if (_aktvarf=_orivarf) AND (_aktearf=_oriearf) and not _elszValt then
    begin
      SiccGombCLick(NIL);
      exit;
    end;

  _veltSzaz := 100-((100*_aktvarf)/_aktelszarf);
  _eeltSzaz := 100-((100*_aktelszarf)/_aktEarf);

  _vvalt := MertekCtrl(_veltszaz);
  _evalt := MertekCtrl(_eeltSzaz);

  if (not _vvalt) or (not _evalt) then
    begin
      if not _vvalt then ShowMessage('AZ ÚJ VÉTELI ÁRFOLYAM KISEBB AZ ENGEDÉLYEZETTNÉL')
      else ShowMessage('AZ ÚJ ELADÁSI ÁRFOLYAM NAGYOBB AZ ENGEDÉLYEZETTNÉL');

      if not DuplaSupKod() then
        begin
          SiccGombCLick(NIL);
          Exit;
        end;
    end;

  _pcs := 'UPDATE ARFOLYAM SET VETELIARFOLYAM=' + intToStr(_aktvarf) +',';
  _pcs := _pcs + 'ELADASIARFOLYAM=' + intToStr(_aktearf) + ',';
  _pcs := _pcs + 'ELSZAMOLASIARFOLYAM=' + inttostr(_aktelszarf) + _sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM='+chr(39) + _aktdnem + chr(39);
  ValutaParancs(_pcs);

  ArfolyamDbase.Connected := True;
  with ArfolyamQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add('SELECT * FROM ARFOLYAM ORDER BY VALUTANEM');
      Open;
      First;
    end;

  ArfolyamDbase.Connected := True;
  with ArfolyamQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add('SELECT * FROM ARFOLYAM ORDER BY VALUTANEM');
      Open;
      First;
    end;

  _elszValt := False;
  Tmkpanel.Visible := False;

  GombtakaroPanel.Visible := false;
  ArfolyamQuery.Locate('VALUTANEM',_aktdnem,[lopartialkey]);
  Arfolyamracs.visible := true;
  ActiveControl := arfolyamRacs;
end;

// =============================================================================
            procedure TARFOLYAMTMKFORM.SICCGOMBClick(Sender: TObject);
// =============================================================================

begin

  TmkPanel.Visible := False;
  ArfolyamRacs.Visible := True;

  Arfolyamdbase.close;
  ArfolyamDbase.Connected := True;
  if ArfolyamTranz.InTransaction then arfolyamTranz.commit;

  with arfolyamQuery do
    begin
      Close;
      sql.Clear;
      sql.Add('SELECT * FROM ARFOLYAM ORDER BY VALUTANEM');
      oPEN;
      First;
    end;
  EscapeGomb.Cancel := False;
  GombtakaroPanel.Visible := false;
  ActiveControl := ArfolyamRacs;
  ArfolyamRacs.SetFocus;
end;

// =============================================================================
            procedure TARFOLYAMTMKFORM.DNEVEDITEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clYellow;
end;

// =============================================================================
             procedure TARFOLYAMTMKFORM.DNEVEDITExit(Sender: TObject);
// =============================================================================

begin
  TEdit(Sender).Color := clWindow;
end;




// =============================================================================
        procedure TARFOLYAMTMKFORM.ESCAPEGOMBClick(Sender: TObject);
// =============================================================================

begin
 
  ArfolyamQuery.Close;
  ArfolyamDbase.close;
  ModalResult := 1;
end;

// =============================================================================
      procedure TARFOLYAMTMKFORM.LETOLTOGOMBClick(Sender: TObject);
// =============================================================================

begin
  

  ArfolyamQuery.Close;
  ArfolyamDbase.close;

  arfolyamletoltes(1);

  Arfolyamdbase.Connected := true;
  with ArfolyamQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add('SELECT * FROM ARFOLYAM ORDER BY VALUTANEM');
      Open;
      First;
    end;
  ActiveControl := ArfolyamRacs;
  ArfolyamRacs.Refresh;
  Arfolyamracs.Repaint;
end;




// =============================================================================
        procedure TARFOLYAMTMKFORM.ARFOLYAMRACSDblClick(Sender: TObject);
// =============================================================================

begin
  EgyvalutaTmk;
end;




// =============================================================================
         procedure TARFOLYAMTMKFORM.NYOMTATOGOMBClick(Sender: TObject);
// =============================================================================

begin
  ArftmkNyomtatas;
end;


// =============================================================================
                   procedure TArfolyamTmkForm.ArfTmkNyomtatas;
// =============================================================================


begin
  NyomtatoPanel.Left := 280;
  NyomtatoPanel.Visible := True;
  ActiveControl := Arfnyomgomb;
end;

// =============================================================================
         procedure TARFOLYAMTMKFORM.ARFNYOMGOMBEnter(Sender: TObject);
// =============================================================================

begin
  TBitbtn(sender).Font.Style := [fsItalic,fsBold];
end;

// =============================================================================
          procedure TARFOLYAMTMKFORM.ARFNYOMGOMBExit(Sender: TObject);
// =============================================================================

begin
  TBitBtn(Sender).Font.Style := [fsItalic];
end;

// =============================================================================
         procedure TARFOLYAMTMKFORM.NYOMTATOPANELClick(Sender: TObject);
// =============================================================================

begin
  NyomtatoPanel.Visible := False;
end;


function TARFOLYAMTMKFORM.Getidos: string;

begin
  result := timetostr(Time);
  if midstr(result,2,1)=':' then result := '0' + result;
end;

// =============================================================================
           procedure TARFOLYAMTMKFORM.ARFNYOMGOMBClick(Sender: TObject);
// =============================================================================

begin
  _idos := GetIdos;
  ArfolyamQuery.First;
  BlokkFoCimIro;
  writeLN(_LFile,_megnyitottnap+' '+leftstr(_idos,5)+' orai valuta arfolyamok');
  writeLn(_LFile,dupestring('-',40));
  WriteLn(_LFile,'Valuta  Egyseg    Veteli      Eladasi');
  writeLn(_LFile,' nem             arfolyam     arfolyam');
  writeLn(_LFile,dupestring('-',40));
  while not ArfolyamQuery.Eof do
    begin
      _aktdnem := ArfolyamQuery.FieldByName('VALUTANEM').asString;
      _aktVarf := ArfolyamQuery.FieldByName('VETELIARFOLYAM').asInteger;
      _aktEArf := ArfolyamQuery.FieldByName('ELADASIARFOLYAM').asInteger;

      write(_Lfile,' '+_aktdnem+'      100 ');
      writeLn(_LFile,Arfkiir(_aktvarf)+' '+ArfKiir(_aktearf));
      ArfolyamQuery.Next;
    end;
  writeLn(_LFile,dupestring('-',40));
  writeLn(_LFile,_sorveg+_sorveg+_sorveg);
  CloseFile(_LFile);
  TextKiiro;
end;

// =============================================================================
      procedure TARFOLYAMTMKFORM.ELSZARFNYOMGOMBClick(Sender: TObject);
// =============================================================================


begin
  _idos := GetIdos;
  ArfolyamQuery.First;
  BlokkFoCimIro;
  writeLN(_LFile,_megnyitottnap+' '+leftstr(_idos,5)+' orai elszam arfolyamok');
  writeLn(_LFile,dupestring('-',40));
  WriteLn(_LFile,'Valuta       A valuta        Elszamolo');
  writeLn(_LFile,' nem        megnevezese       arfolyam');
  writeLn(_LFile,dupestring('-',40));
  while not ArfolyamQuery.Eof do
    begin
      _aktdnem := ArfolyamQuery.FieldByName('VALUTANEM').asString;
      _aktDnev := ArfolyamQuery.FieldByName('VALUTANEV').asString;
      _aktelszarf := ArfolyamQuery.FieldByName('ELSZAMOLASIARFOLYAM').asInteger;

      write(_Lfile,' '+_aktdnem+' ');
      writeLn(_Lfile,Kieg(_aktdnev,22)+Arfkiir(_aktelszarf));
      ArfolyamQuery.Next;
    end;
  writeLn(_LFile,dupestring('-',40));
  writeLn(_LFile,_sorveg+_sorveg+_sorveg);
  CloseFile(_LFile);
  TextKiiro;
end;

procedure TArfolyamTmkForm.Blokkfocimiro;

begin
  assignfile(_LFile,'c:\valuta\aktlst.txt');
  rewrite(_LFile);
  Kozepreir(_cegnev);
  Kozepreir(_homepenztarkod+' '+_homePenztarnev);
  KozepreIr(_homepenztarcim);
  writeLn(_LFile,dupestring('-',40));
end;



// =============================================================================
         procedure TArfolyamTmkForm.KozepreIr(_szoveg: string);
// =============================================================================

var _oo: integer;

begin
  _szoveg := trim(_szoveg);
  _oo := trunc((40-length(_szoveg))/2);
  writeLn(_LFile,dupestring(' ',_oo)+_szoveg);
end;





function TArfolyamTmkForm.Kieg(_s: string; _hh: byte): string;

begin
  while length(_s)<_hh do _s := _s + ' ';
  result := _s;
end;


// =============================================================================
            function TArfolyamTmkForm.Arfkiir(_arf: real): string;
// =============================================================================

var _egesz,_pp: integer;
    _arfstring,_egstr: string;


begin
  // _arf = 166.23
  _egesz := round(_arf*10000);  // 166
  _egstr := inttostr(_egesz);
  _pp := length(_egstr)-4;
  _arfstring := leftstr(_egstr,_pp)+'.'+midstr(_egstr,_pp+1,4);
  result := Elokieg(_arfstring,12);
end;


function TARFOLYAMTMKFORM.Elokieg(_s: string;_hh: byte): string;

begin
  while length(_s)<_hh do _s:= ' '+_s;
  result := _s;
end;



// =============================================================================
   procedure TARFOLYAMTMKFORM.VARFEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  ActiveControl := EarfEdit;


end;

// =============================================================================
    procedure TARFOLYAMTMKFORM.EARFEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)=38 then
    begin
      ActiveControl := Varfedit;
      Exit;
    end;

  if ord(key)<>13 then exit;

  Arfolyamokegomb.Enabled := true;
  ActiveControl := ArfolyamOkeGomb;
end;


// =============================================================================
       procedure TARFOLYAMTMKFORM.ELSZARFEDITKeyDown(Sender: TObject;
                                      var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  elszarfmodositas;
end;

// =============================================================================
               procedure TarfolyamTMKForm.ElszarfModositas;
// =============================================================================

var _elszarftxt : string;

begin
  _elszarftxt := elszarfEdit.Text;
  if trim(_elszarftxt)='' then
    begin
      ElszarfEdit.Text := intToStr(_aktelszarf);
      _elszarftxt := elszarfedit.text;
    end;
  val(_elszarftxt,_aktelszarf,_code);
  if _code<>0 then
    begin
      ElszarfEdit.Text := intToStr(_aktelszarf);
      _elszarftxt := elszarfedit.text;
    end;

  _elszValt := true;
  ActiveControl := ArfolyamOkeGomb;

end;



// =============================================================================
        function TarfolyamTmkForm.Validalo(_reals: string): integer;
// =============================================================================


var _ww,i,_kod: integer;
    _rst: string;

begin

   result := 0;
   _reals := trim(_reals);
   _ww := length(_reals);
   if _ww=0 then exit;

   _rst := '';
   for i := 1 to _ww do
     begin
       _kod := ord(_reals[i]);
       if _kod=44 then _kod := 46;
       _rst := _rst + chr(_kod);
     end;

  val(_rst,result,_code);
  if _code<>0 then result := 0;
end;

// =============================================================================
         procedure TARFOLYAMTMKFORM.ELSZARFGOMBClick(Sender: TObject);
// =============================================================================

begin
  if not _elszModAble then
    begin
      _OKE := supervisorjelszo(0);
      if _oke<>1 then exit;
      _elszmodAble := true;
    end;
  ActiveControl := Elszarfedit;
end;

// =============================================================================
       procedure TARFOLYAMTMKFORM.ELSZARFEDITExit(Sender: TObject);
// =============================================================================

begin
  Elszarfedit.Color := clWindow;
  ElszarfModositas;
end;

// =============================================================================
         function TArfolyamTmkForm.MertekCtrl(_szazalek: real):boolean;
// =============================================================================


begin
  result := False;
  if (_aktdnem='EUR') then
    begin
      if _szazalek<=5 then result := True;
      exit;
    end;

  if (_aktdnem='AUD') OR (_aktdnem='CAD') OR (_aktdnem='DKK') OR (_aktdnem='NOK') OR (_aktdnem='SEK') then
    begin
      if _szazalek<=12 then result := True;
      exit;
    end;

  if (_aktdnem='GBP') then
    begin
      if _szazalek<=5 then Result := True;
      exit;
    end;

  if (_aktdnem='USD') then
    begin
      if _szazalek<=7 then result := True;
    end;

  if (_aktdnem='UAH') OR (_aktdnem='RSD') then
    begin
      if _szazalek<=12 then result := True;
    end;

  if (_aktdnem='CZK') OR (_aktdnem='JPY') OR (_aktdnem='HRK') then
    begin
      if _szazalek<=10 then result := True;
      exit;
    end;

  if (_aktdnem='BGN') OR (_aktdnem='RON') OR (_aktdnem='PLN') then
    begin
       if(_szazalek<=10) then result := True;
       exit;
     end;

  if (_aktdnem='EUA') OR (_aktdnem='RCH') then
    begin
      if _szazalek<=15 then Result := True;
      exit;
    end;

  if _szazalek<=6 then Result := true;
end;

// =============================================================================
                function TArfolyamTmkForm.DuplaSupkod():boolean;
// =============================================================================

var _oke: integer;

begin
  Result := false;
  _OKE := supervisorjelszo(0);
  if _oke<>1 then exit;

  _OKE := supervisorjelszo(0);
  if _oke<>1 then exit;
  Result := True;
end;

// =============================================================================
          procedure TARFOLYAMTMKFORM.ELSZARFEDITChange(Sender: TObject);
// =============================================================================

begin
  ArfolyamOkeGomb.Enabled := True;
end;



procedure TARFOLYAMTMKFORM.MNBLETOLTOGOMBClick(Sender: TObject);
begin

  ArfolyamQuery.Close;
  ArfolyamDbase.close;

  arfolyamletoltes(2);

  Arfolyamdbase.Connected := true;
  with ArfolyamQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add('SELECT * FROM ARFOLYAM ORDER BY VALUTANEM');
      Open;
      First;
    end;
  ActiveControl := ArfolyamRacs;
  ArfolyamRacs.Refresh;
  Arfolyamracs.Repaint;
end;


procedure TARFOLYAMTMKFORM.ValutaParancs(_ukaz: string);

begin
  Valutadbase.connected := true;
  if valutaTranz.InTransaction then Valutatranz.commit;
  Valutatranz.StartTransaction;
  with ValutaQuery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      execsql;
    end;
  ValutaTranz.Commit;
  Valutadbase.close;
end;


// =============================================================================
                  procedure TARFOLYAMTMKFORM.TextKiiro;
// =============================================================================

var _mondat: string;
    _nyomtat,_olvas: textFile;

begin

  if _printer<>1 then AssignFile(_nyomtat,'LPT1')
  else AssignPrn(_nyomtat);
  Rewrite(_nyomtat);
  AssignFile(_olvas,'c:\valuta\aktlst.txt');
  Reset(_olvas);

  while not eof(_olvas) do
    begin
      readln(_olvas,_mondat);
      writeln(_nyomtat,_mondat);
    end;
  System.closeFile(_nyomtat);
  System.CloseFile(_olvas);
end;

procedure TARFOLYAMTMKFORM.AlapadatBeolvasas;

begin
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap := FieldByNAme('MEGNYITOTTNAP').asString;
      _printer := FieldByName('PRINTER').asInteger;
      _kftnev := trim(FieldByNAme('KFTNEV').AsString);

      Close;
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _homepenztarkod := trim(FieldByNAme('PENZTARKOD').asString);
      _homePenztarnev := trim(FieldByNAme('PENZTARNEV').asString);
      _homePenztarCim := trim(FieldByNAme('PENZTARCIM').asString);
      Close;
    end;
  Valutadbase.close;

  val(_homepenztarkod,_homepenztarszam,_code);
  if _homepenztarszam<151 then
    begin
      _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';
    end else
    begin
      _cegnev := 'EXPRESSZ EKSZERHAZ ES MINIBANK KFT';
    end;

end;


procedure TARFOLYAMTMKFORM.KEZIALLITOGOMBClick(Sender: TObject);

var _spk: integer;

begin
   _spk := supervisorjelszo(0);
   if _spk<>1 then exit;

  KeziAllitogomb.Enabled := False;
  _maykezi := True;

  _pcs := 'UPDATE HARDWARE SET KEZIARFOLYAM=1';
  ValutaParancs(_pcs);

end;

end.
