unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery,
  Buttons, strutils;

type
  TForm2 = class(TForm)
    KILEPO: TTimer;
    BIZLATOKQUERY: TIBQuery;
    BIZLATOKDBASE: TIBDatabase;
    BIZLATOKTRANZ: TIBTransaction;
    RADIOPANEL: TPanel;
    Shape1: TShape;
    KFTRADIO: TRadioButton;
    KORZETRADIO: TRadioButton;
    PENZTARRADIO: TRadioButton;
    PTMEGSEMGOMB: TBitBtn;
    PENZTARCOMBO: TComboBox;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    KORZETCOMBO: TComboBox;
    KORZETOKEGOMB: TBitBtn;
    KFTOKEGOMB: TBitBtn;
    FOCIMALAP: TPanel;
    FOCIMPANEL: TPanel;
    KFTPANEL: TPanel;
    Shape2: TShape;
    RBEST: TRadioButton;
    REXPRESSZ: TRadioButton;
    RALL: TRadioButton;
    PTOKEGOMB: TBitBtn;
    KERTDATUMPANEL: TPanel;
    KERTDATUMSPANEL: TPanel;
    Label1: TLabel;
    RADIOCIMPANEL: TPanel;

    procedure FormActivate(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);
    procedure PenztarRadioClick(Sender: TObject);
    procedure IrodaBeolvasas;
    function Nul3(_b: byte): string;
    procedure PtMegsemGombClick(Sender: TObject);
    procedure PenztarComboChange(Sender: TObject);
    procedure PTokeGombClick(Sender: TObject);
    procedure VtempInsert;
    procedure BizlatParancs(_ukaz: string);
    procedure KORZETRADIOClick(Sender: TObject);
    procedure KORZETCOMBOChange(Sender: TObject);
    procedure KFTRADIOClick(Sender: TObject);
    procedure KFTOKEGOMBClick(Sender: TObject);
    procedure RBESTClick(Sender: TObject);
    procedure KORZETOKEGOMBClick(Sender: TObject);



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _height,_width,_top,_left,_kertev,_kertho,_tolnap,_ignap: word;
  _kertdatums,_datumlimit,_fopcs,_csoptipus,_aktpenztarnev: string;
  _megnevezes,_pttipus,_aktcegbetu,_aktceg: string;
  _ok,_code: integer;
  _aktpenztar,_aktkorzet: byte;
  _toltes: boolean;

  _host: string = '185.43.207.99';

  _honev      : array[1..12] of string = ('január','február','március',
                             'április','május','junius',
         'július','augusztus','szeptember','október','november','december');

  _kftnev: array[1..2] of string = ('Exclusive Best Change Kft','Expressz Ékszerház Kft');

  _korzet: array[1..180] of byte;
  _cegbetu: array[1..180] of string;

  _korzetek: array[0..7] of byte = (10,20,40,50,63,75,120,145);
  _korzetnevek: array[0..7] of string = ('Szekszárd','Szeged','Kecskemét',
         'Debrecen','Nyíregyháza','Békéscsaba','Pécs','Kaposvár');

  _kftnum: array[1..180] of byte;
  _penztarnev,_ptarcim: array[1..180] of string;

  _sorveg: string = chr(13)+chr(10);
  _pcs,_fdbpath,_uznev,_uzcim,_aktkorzetnev: string;
  _ertektar: byte;


function idoszakoslista: integer; stdcall; external 'c:\uctrl\bin\idoszakos.dll';
function idoszaksetting: integer; stdcall; external 'c:\uctrl\bin\idoszak.dll';
function adatgyujtorutin: integer; stdcall; external 'c:\uctrl\bin\adatgyujto.dll';

function adatlistazorutin: integer; stdcall;

implementation

uses Unit1;

{$R *.dfm}

function adatlistazorutin: integer; stdcall;

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.showmodal;
  form2.free;
end;  



procedure TForm2.FormActivate(Sender: TObject);
begin
  _height := screen.Monitors[0].Height;
  _width  := screen.Monitors[0].width;

  _top := round((_height-595)/2);
  _left := 8+round((_width-1017)/2);

  top    := _top-50;
  left   := _left;
  width  := 1001;
  height := 537;
  color  := clGreen;
  _ok    := idoszaksetting;

  if _ok=-1 then
    begin
      ShowMessage('Nincsenek adatok a kért idõszakban');
      Kilepo.enabled := True;
      exit;
    end;

  IrodaBeolvasas;

  BizlatokDbase.Connected := true;
  with BizlatokQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM IDOSZAK');
      Open;
      _kertev := FieldByNAme('KERTEV').asInteger;
      _kertho := FieldByNAme('KERTHO').asInteger;
      _tolnap := FieldByNAme('TOLNAP').asInteger;
      _ignap  := FieldByNAme('IGNAP').asInteger;
      Close;
    end;
  BizlatokDbase.close;

  _kertdatums := inttostr(_kertev)+' '+_honev[_kertho]+' '+inttostr(_tolnap)+'-'+inttostr(_ignap);
   _datumLimit := _kertDatums+ ' közötti forgalom';

   // ---------------------------------

  _toltes := true;

  PenztarRadio.Enabled := True;
  KorzetRadio.Enabled  := True;
  KFTRadio.Enabled     := True;

  PenztarRadio.Checked := False;
  KorzetRadio.Checked  := False;
  KftRadio.Checked     := False;

  _toltes := False;

  //------------------------------------
  with RadioCimPanel do
    begin
      Left := 280;
      top := 92;
      Visible := true;
      repaint;
    end;

  // kft szerint, körzet szerint, plnztárszerint rádiogomb választás
  with RadioPanel do
    begin
      top     := 120;
      left    := 280;
      Visible := True;
      repaint;
    end;

  //  Mégsem választok a fentiek közül gomb felrakása:
  with PtMegsemGomb do
    begin
      top     := 168;
      left    := 608;
      Height  := 25;
      Visible := True;
    end;
  _FoPcs := 'SELECT * FROM ADATGYUJTO';
end;

procedure TForm2.KILEPOTimer(Sender: TObject);
begin
  Kilepo.Enabled := False;
  Modalresult := 1;
end;

// =============================================================================
             procedure TForm2.PenztarRadioClick(Sender: TObject);
// =============================================================================
//        A pénztárak szerinti választó gombra kattintott


begin
  if _toltes then exit;

  _csoptipus := 'P';

  Penztarradio.Enabled := False;
  Korzetradio.Enabled  := False;
  KftRadio.Enabled     := False;

  if penztarRadio.Checked then
    begin
      with PenztarCombo do
        begin
          top     := 168;
          left    := 280;
          Visible := True;
        end;
      Penztarcombo.ItemIndex := 0;
    end;
end;


// =============================================================================
                      procedure TForm2.IrodaBeolvasas;
// =============================================================================

var _uzlet,i: byte;
    _uznev,_pn: string;

begin
  For i := 1 to 180 do
    begin
      _penztarnev[i] := '-';
      _cegbetu[i] := '-';
      _korzet[i] := 0;
    end;

  Penztarcombo.Items.clear;

  _pcs := 'SELECT * FROM IRODAK'  + _sorveg;
  _pcs := _pcs + 'WHERE CLOSED=' + chr(39) + 'N' + CHR(39);

  _fdbPath := _host + ':C:\receptor\database\receptor.fdb';
  recdbase.close;
  recdbase.DatabaseName := _fdbPath;
  recdbase.connected := True;

  with recquery do
    begin
      Close;
      sql.clear;
      sql.add(_PCS);
      Open;
    end;

  while not RecQuery.eof do
    begin
      _uzlet := Recquery.fieldByName('UZLET').asInteger;
      _uznev := trim(Recquery.FieldByNAme('KESZLETNEV').asString);
      _UzCim := trim(RecQuery.FieldByNAme('IRODACIM').ASsTRING);
      _ertektar := Recquery.FieldByNAme('ERTEKTAR').asInteger;

      _penztarnev[_uzlet] := _uzNev;
      _ptarcim[_uzlet] := _uzcim;
      _korzet[_uzlet] := _ertektar;
      _cegbetu[_uzlet] := 'B';
      _KFTNUM[_uzlet] := 1;

      RecQuery.next;
    end;
   RecQuery.close;
   recdbase.close;

   // --------------------------------------------------------

  _fdbPath := _host + ':C:\cartcash\database\artcash.fdb';
  recdbase.close;
  recdbase.DatabaseName := _fdbPath;
  recdbase.connected := True;

  with RecQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not RecQuery.eof do
    begin
      _uzlet := RecQuery.fieldByName('UZLET').asInteger;
      _uznev := trim(RecQuery.FieldByNAme('KESZLETNEV').asString);
      _uzcim := trim(RecQuery.FieldByNAme('IRODACIM').asString);

      _korzet[_uzlet]  := 180;
      _cegbetu[_uzlet] := 'Z';
      _kftnum[_uzlet]  := 2;

      _penztarnev[_uzlet] := _uzNev;
      _ptarcim[_uzlet]    := _uzcim;

      RecQuery.next;
    end;
  RecQuery.close;
  RecDbase.close;

  i := 1;
  while i<=180 do
    begin
      if _penztarnev[i]<>'-' then
        begin
          _pn := nul3(i)+'. '+_penztarnev[i];
          Penztarcombo.Items.add(_pn);
        end;
       inc(i);
    end;

   Korzetcombo.Items.clear;

   i := 0;
   while i<=7 do
     begin
       korzetcombo.Items.add(_korzetnevek[i]+' körzete');
       inc(i);
     end;
end;


// =============================================================================
                   function TForm2.Nul3(_b: byte): string;
// =============================================================================

begin
  result :=  inttostr(_b);
  while length(result)<3 do result := '0' + result;
end;


// =============================================================================
               procedure TForm2.PtMegsemGombClick(Sender: TObject);
// =============================================================================

begin
  PenztarCombo.visible    := False;
  KorzetCombo.Visible     := False;
  KorzetOkeGomb.Visible   := False;
  KftOkeGomb.Visible      := False;
  FocimAlap.visible       := False;

  KftPanel.Visible        := False;
  Ptokegomb.Visible       := False;
  PtMegsemGomb.Visible    := False;
  RadioPanel.Visible      := False;
  Radiocimpanel.Visible   := False;
  KertdatumPanel.Visible  := False;
  Kilepo.Enabled := True;

end;

// =============================================================================
               procedure TForm2.PenztarComboChange(Sender: TObject);
// =============================================================================
//                  PÉNZTÁRT JELÖLT KI A LISTÁBAN


begin
  KertDatumPanel.Visible := False;
  RadioPanel.Visible := False;
  RadioCImPanel.visible := False;
  PenztarCombo.Visible := False;

  _aktpenztarnev := Penztarcombo.Text;
  _megnevezes    := _aktpenztarnev;
  FocimPanel.Caption := _megnevezes+ ' ' + _datumLimit;

  with Focimalap do
   begin
     top := 56;
     Left := 208;
     Visible := true;
     repaint;
   end;

  with PtOkeGomb do
    begin
      top := 102;
      left := 320;
      visible := True;
    end;

  with PtMegsemGomb do
    begin
      top := 102;
      Left := 480;
      Visible := true;
    end;

  Activecontrol := PtOkeGomb;
end;

// =============================================================================
                  procedure TForm2.PTokeGombClick(Sender: TObject);
// =============================================================================
//                          PÉNZTÁRT VÁLASZTOTT - LEOKÉZTA

var _pts: string;

begin
  Focimalap.Visible    := False;
  Ptokegomb.Visible    := False;
  PenztarCombo.Visible := False;
  RadioPanel.Visible   := False;

  _pttipus := 'P';

  _aktpenztarnev := Penztarcombo.Text;
  _pts := leftstr(_aktpenztarnev,3);
  val(_pts,_aktpenztar,_code);
  _megnevezes := _aktpenztarnev;
  FocimPanel.Caption := _megnevezes+' '+_datumLimit;
  FocimPanel.repaint;

  FocimAlap.Visible := True;

  Ptmegsemgomb.Visible := False;

  repaint;
  Shape1.repaint;

  VTempInsert;

  _OK := adatgyujtorutin;
  if _ok=-1 then
    begin
      ShowMessage('NINCSENEK ADATOK A BEÁLLÍTOTT FELTÉTELEKKEL');
      Ptmegsemgomb.Visible := false;
      repaint;
      Focimpanel.visible := False;
      Kilepo.Enabled := True;
      exit;
    end;

  FocimAlap.Visible := False;
  idoszakoslista;
  Kilepo.Enabled := True;
end;


// =============================================================================
                    procedure TForm2.VtempInsert;
// =============================================================================

begin
  _pcs := 'DELETE FROM VTEMP';
  BizlatParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (PTTIPUS,AKTPENZTAR,AKTKORZET,';
  _pcs := _pcs + 'AKTCEGBETU,MEGNEVEZES,KERTDATUMS)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _pttipus + chr(39) + ',';
  _pcs := _pcs + inttostr(_aktpenztar) + ',';
  _pcs := _pcs + inttostr(_aktkorzet) + ',';
  _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',';
  _pcs := _pcs + chr(39) + _megnevezes + chr(39) + ',';
  _pcs := _pcs + chr(39) + _kertdatums + chr(39) + ')';
  BizlatParancs(_pcs);
end;

// =============================================================================
             procedure TForm2.BizlatParancs(_ukaz: string);
// =============================================================================

begin
  BizlatokDbase.Connected := True;
  if BizlatokTranz.InTransaction then BizlatokTranz.Commit;
  BizlatokTranz.StartTransaction;
  with BizlatokQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  BizlatokTranz.commit;
  BizlatokDbase.close;
end;


// =============================================================================
              procedure TForm2.KORZETRADIOClick(Sender: TObject);
// =============================================================================

//                   A körzetek rádió-gombot választotta:

begin
  if _toltes then exit;

  _csoptipus := 'K';

  Penztarradio.Enabled := False;
  Korzetradio.Enabled  := False;
  KftRadio.Enabled     := False;

  if KorzetRadio.Checked then
    begin
      with KorzetCombo do
        begin
          top     := 168;
          left    := 280;
          Visible := True;
        end;
      Korzetcombo.ItemIndex := 0;
    end;
end;

// =============================================================================
            procedure TForm2.KORZETCOMBOChange(Sender: TObject);
// =============================================================================

//                   EGY KÖRZETET jelölt ki

var _kindex: integer;

begin
  KertDatumPanel.Visible := False;
  RadioPanel.Visible     := False;
  RadioCimPanel.visible  := False;
  KorzetCombo.Visible    := False;

  with KorzetOkeGomb do
    begin
      top := 102;
      left := 320;
      visible := True;
    end;

  with Ptmegsemgomb do
    begin
      top := 102;
      left := 480;
      repaint;
    end;

  _kindex := Korzetcombo.ItemIndex;

  _aktkorzetnev := _korzetnevek[_kindex];
  _aktkorzet := _korzetek[_kindex];

  _megnevezes := _aktkorzetnev + ' körzete';
  FocimPanel.Caption := _megnevezes +  ' ' + _datumLimit;
  FocimPanel.repaint;
  with FocimAlap do
    begin
      top := 54;
      Left := 208;
      Visible := True;
      repaint;
    end;

  Activecontrol := KorzetOkeGomb;
end;

// =============================================================================
             procedure TForm2.KFTRADIOClick(Sender: TObject);
// =============================================================================
//                  A KFT rádio-gombot választotta

begin
  if _toltes then exit;

  // cégválasztó tipus=C
  _csoptipus := 'C';

  // A radiógombok letiltva:
  Penztarradio.Enabled := False;
  Korzetradio.Enabled  := False;
  KftRadio.Enabled     := False;

  if KftRadio.Checked then
     begin
       _toltes := True;

       RBest.Checked     := False;
       RExpressz.Checked := False;
       RAll.Checked      := False;

       _toltes := False;

  // Három rádiógomb: BEST - EXPRESSZ - TELJES CÉG

       with KftPanel do
         begin
           top := 168;
           left := 280;
           visible := true;
         end;
     end;

end;

// =============================================================================
             procedure TForm2.KFTOKEGOMBClick(Sender: TObject);
// =============================================================================
//                 A KFT OPCIÓK KÖZÜL VÁLASZTOTT  -> BEST

begin
  Kftpanel.Visible     := False;
  Ptmegsemgomb.Visible := False;
  KftOkeGomb.Visible   := False;
  RadioPanel.Visible   := False;

  if RBest.Checked then
    begin
      _aktcegbetu := 'B';
      _aktceg := 'BEST CHANGE KFT';
    end;

  if RExpressz.Checked then
    begin
      _aktcegbetu := 'Z';
      _aktceg := 'EXPRESSZ ÉKSZERHÁZ';
    end;

  if RAll.Checked then
    begin
      _aktcegbetu := 'A';
      _aktceg := 'ÖSSZES';
    end;

  _pttipus := 'C';
  _megnevezes :=_aktceg;
  FocimPanel.Caption := _megnevezes + ' ' + _datumLimit;

  repaint;
  VTempInsert;

  _OK := adatgyujtorutin;
  if _ok=-1 then
    begin
      Ptmegsemgomb.Visible := false;
      ShowMessage('NINCSENEK ADATOK A BEÁLLÍTOTT FELTÉTELEKKEL');
      FocimPanel.Visible := False;
      repaint;
      Kilepo.Enabled := True;
      exit;
    end;
  FocimAlap.Visible := False;
  idoszakoslista;
  Kilepo.Enabled := True;
end;

// =============================================================================
                 procedure TForm2.RBESTClick(Sender: TObject);
// =============================================================================

//          KFT OPCIÓK KÖZÜL VÁLASZTOTT -> EXPRESSZ VAGY TLEJES CÉG

begin
  if _toltes then exit;

  KertdatumPanel.Visible := False;
  Kftpanel.Visible := False;
  RadioPanel.Visible := False;

  with PtMegsemGomb do
    begin
      top  := 102;
      left := 480;
    end;

  with KftOkegomb do
    begin
      top := 102;
      left := 320;
      Visible := True;
    end;

  _pttipus := 'C';

  if Rbest.Checked then
    begin
      _aktcegbetu := 'B';
      _megnevezes := 'Best Change Kft';
      Focimpanel.caption := _megnevezes + ' ' + _datumlimit;
    end;

  if RExpressz.Checked then
    begin
      _aktcegbetu := 'Z';
      _megnevezes := 'Expressz ékszerház';
      FocimPanel.caption := _megnevezes+ ' ' + _datumLimit;
    end;

  if RAll.Checked then
    begin
      _aktcegbetu := 'A';
      _megnevezes := 'Teljes cég';
      FocimPanel.caption := _megnevezes+ ' ' + _datumLimit;
    end;

  radioCimPanel.Visible := False;  
  with Focimalap do
    begin
      top := 54;
      left := 208;
      Visible := true;
      repaint;
    end;
end;

// =============================================================================
           procedure TForm2.KORZETOKEGOMBClick(Sender: TObject);
// =============================================================================
//                   KÖRZETET VÁLASZTOTT


var _kindex: integer;

begin
  Korzetokegomb.Visible := False;
  KorzetCombo.Visible   := False;
  RadioPanel.Visible    := False;

  _pttipus := 'K';
  _kindex := Korzetcombo.ItemIndex;

  _aktkorzetnev := _korzetnevek[_kindex];
  _aktkorzet    := _korzetek[_kindex];

  _megnevezes := _aktkorzetnev + ' körzete';
  FocimPanel.Caption := _megnevezes+ ' ' + _datumLimit;
  FocimAlap.visible := True;

  Ptmegsemgomb.Visible := False;

  repaint;
  Shape1.repaint;
  VTempInsert;

  _OK := adatgyujtorutin;
  if _ok=-1 then
    begin
      Ptmegsemgomb.Visible := false;
      ShowMessage('NINCSENEK ADATOK A BEÁLLÍTOTT FELTÉTELEKKEL');
      FocimPanel.Visible := False;
      repaint;
      Kilepo.Enabled := True;
      exit;
    end;
    
  FocimAlap.Visible := False;
  idoszakoslista;
  Kilepo.Enabled := True;
end;



end.
