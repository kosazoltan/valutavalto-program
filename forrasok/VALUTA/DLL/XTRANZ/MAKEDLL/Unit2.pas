unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBTable, Grids,printers,
  DBGrids, Buttons, ExtCtrls, dateutils, Strutils, IBQuery;

type
  TXTRANZFORM = class(TForm)
    KILEPOGOMB: TButton;
    EVCOMBO: TComboBox;
    HOCOMBO: TComboBox;
    Label1: TLabel;
    XKEZDIJRACS: TDBGrid;
    XKTABLA: TIBTable;
    XKDBASE: TIBDatabase;
    XKTRANZ: TIBTransaction;
    TIPUSPANEL: TPanel;
    HONAPRENDBENGOMB: TBitBtn;
    xksource: TDataSource;
    XKTABLADATUM: TIBStringField;
    XKTABLABIZONYLAT: TIBStringField;
    XKTABLABIZONYLATFORINT: TIntegerField;
    XKTABLAEGYEDIKEZDIJ: TIntegerField;
    XKTABLATIPUS: TIBStringField;
    BitBtn1: TBitBtn;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    procedure KILEPOGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure HONAPRENDBENGOMBClick(Sender: TObject);
    procedure XKEZDIJRACSKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure EVCOMBOChange(Sender: TObject);
    function Nulele(_int: integer): string;
    procedure BitBtn1Click(Sender: TObject);
    procedure StartNyomtatas;
    function Formazo(_num: integer):string;
 

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  XTRANZFORM: TXTRANZFORM;
  _maiev,_maiho,_width,_height,_top,_left,_printer: word;

  _honev: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS','MÁJUS',
      'JÚNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER','NOVEMBER','DECEMBER');

  _KERTHO,_KERTEV: WORD;

  _xkFarok,_xkfile: string;

  _mess: array[1..7] of string = ('Kezdíj felezése ügyvezetõi engedéllyel',
        'Kezelési díj felezése akcióban',
        'Kezelési díj felezése kártya segítségével',
        'Kezelési díj elengedése ügyvezetõ engedélyével',
        'Kezelési díj elengedése kártya segítségével',
        'Egyedi kezelési díj (max 3%%)',
        'Bármennyi kezelési dij engedéllyel');

function extratranzdijdisp: integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
            function extratranzdijdisp: integer; stdcall;
// =============================================================================

begin
  XtranzForm := TXtranzform.create(Nil);
  result := XtranzForm.showModal;
  XtranzForm.Free;
end;

// =============================================================================
          procedure TXTRANZFORM.KILEPOGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;

// =============================================================================
            procedure TXTRANZFORM.FormActivate(Sender: TObject);
// =============================================================================

var i: integer;

begin
  _height := screen.Monitors[0].Height;
  _width := screen.Monitors[0].Width;

  _top := trunc((_height-768)/2);
  _left := trunc((_width-1024)/2);

  Top := _top+8;
  Left := _left + 345;
  _maiev := yearof(date);
  _maiho := monthof(Date);

  EVCOMBO.Items.clear;
  evcombo.Items.Add(inttostr(_maiev-1));
  evcombo.Items.add(inttostr(_maiev));

  Hocombo.Items.Clear;
  for i := 1 to 12 do Hocombo.Items.add(_honev[i]);

  Evcombo.ItemIndex := 1;
  Hocombo.ItemIndex := _maiho-1;

  Valutadbase.Connected := true;
  with VAlutaquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _printer := FieldByNAme('PRINTER').asInteger;
      Close;
    end;
  Valutadbase.close;

  Activecontrol := Honaprendbengomb;
end;

// =============================================================================
           procedure TXTRANZFORM.HONAPRENDBENGOMBClick(Sender: TObject);
// =============================================================================

var _ss : Tshiftstate;
    _key: word;

begin
  _kertho := 1+ Hocombo.itemindex;
  _kertev := _maiev;

  if evcombo.itemindex=0 then dec(_kertev);

  _xkFarok := inttostr(_kertev-2000)+nulele(_kertho);
  _xkFile := 'XKEZ' + _xkFarok;

  xkDbase.Connected := true;
  xkTabla.Close;
  xkTabla.TableName := _xkFile;

  if not xkTabla.Exists then
    begin
      xkdbase.close;
      showmessage('A KÉRT HÓNAPRÓL NINCS ADAT');
      exit;
    end;

  xkTabla.Open;
  xkTabla.First;

  ActiveControl := xKezdijRacs;
  _key := 65;
  _ss := [ssAlt];
  xKezdijRacsKeyUp(Nil,_key,_ss);

end;

// =============================================================================
     procedure TXTRANZFORM.XKEZDIJRACSKeyUp(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================


var _akttipus,_tiptext: string;
    _akttip: byte;

begin
  _akttipus := xktabla.fieldbyname('TIPUS').asString;
  _akttip   := ord(_akttipus[1])-64;
  _tiptext  := _mess[_akttip];

  TipusPanel.Caption := _tiptext;
  TipusPanel.repaint;
end;

// =============================================================================
           procedure TXTRANZFORM.EVCOMBOChange(Sender: TObject);
// =============================================================================

begin
  Activecontrol := HonapRendbenGomb;
end;

// =============================================================================
           function TXtranzForm.Nulele(_int: integer): string;
// =============================================================================

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;

// =============================================================================
           procedure TXTRANZFORM.BitBtn1Click(Sender: TObject);
// =============================================================================

var _txtiras: Textfile;
    _datum,_bizonylat,_tipus: string;
    _bizft,_kezdij,_akttip: integer;

begin

  {
  --------------------------------------
  Datum/Biz. Ftossz/kezdij  Engedelyezo
  --------------------------------------
  2013.11.12 12,345,678 Ft   UGYVEZETO
    V123456  12,345,678 Ft  FOERTEKTAROS
                              KARTYAS
                            EGYEDI KEZDIJ
   }

  AssignFile(_txtiras,'c:\valuta\aktlst.txt');
  rewrite(_txtiras);

  writeLn(_txtiras,'---------------------------------------');
  writeln(_txtiras,'Datum/Biz.  Ftossz/Kezdij Engedelyezo');
  writeLn(_txtiras,'---------------------------------------');
  xktabla.first;
  while not xkTabla.eof do
    begin
      with xktabla do
        begin
          _datum     := FieldByName('DATUM').asstring;
          _bizonylat := FieldByName('BIZONYLAT').asstring;
          _bizft     := FieldByName('BIZONYLATFORINT').asInteger;
          _kezdij    := FieldByName('EGYEDIKEZDIJ').asInteger;
          _tipus     := FieldByName('TIPUS').asstring;
        end;

      _akttip := ord(_tipus[1])-64;
      write(_txtiras,_datum+' ');
      write(_txtiras,formazo(_bizft)+'  ');
      case _akttip of
        1: writeLn(_txtiras,' UGYVEZETO/');
        2: writeLn(_txtiras,'  KARTYAS');
        3: writeLn(_txtiras,'EGYEDI KEZDIJ');
        4: writeLn(_txtiras,'KKTG FELEZES');
      end;
      write(_txtiras,'  '+_bizonylat+'  ');
      write(_txtiras,formazo(_kezdij)+'  ');
      if _akttip=1 then write(_txtiras,'FOERTEKTAROS');
      writeLn(_txtiras,chr(13)+chr(10));
      xkTabla.next;
    end;
  xktabla.first;

  writeLn(_txtiras,'---------------------------------------'+chr(13)+chr(10));
  closefile(_txtiras);

  StartNyomtatas;
end;

// =============================================================================
            function TXtranzForm.Formazo(_num: integer):string;
// =============================================================================

var _s,_nums: string;
    _nlen,_ff: byte;
begin
  _nums := inttostr(_num);
  _nlen := length(_nums);
  result := '      -      ';

  if _num=0 then exit;

  if _nlen>6 then
    begin
      _ff := _nLen-6;
      _s := leftstr(_nums,_ff)+','+midstr(_nums,_ff+1,3)+','+midstr(_nums,_ff+4,3);
      result := _s + ' Ft';
      while length(result)<13 do result := ' ' + result;
      exit;
    end;

  if _nlen<4 then
    begin
      result := _nums+' Ft';
      while length(result)<13 do result := ' ' + result;
      exit;
    end;
  _ff := _nlen-3;
  result := leftstr(_nums,_ff)+','+ midstr(_nums,_ff+1,3)+' Ft';
  while length(result)<13 do result := ' ' + result;
end;






procedure TXtranzform.StartNyomtatas;

var _olvas,_nyomtat: textfile;
    _mondat: string;

begin
  if _printer<>1 then AssignFile(_nyomtat,'LPT1')
  else Assignprn(_nyomtat);

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



end.
