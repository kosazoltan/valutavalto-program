unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBCustomDataSet, IBQuery, StdCtrls, dateUtils,
  IBTable, strutils, ExtCtrls, Buttons;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    HOCOMBO: TComboBox;
    EVCOMBO: TComboBox;
    Label1: TLabel;
    IBQUERY: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    PROSQUERY: TIBQuery;
    PROSDBASE: TIBDatabase;
    PROSTRANZ: TIBTransaction;
    IBTABLA: TIBTable;
    fdbpanel: TPanel;
    bizonylatpanel: TPanel;
    Memo1: TMemo;

    procedure FormActivate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Ibparancs(_ukaz: string);
    procedure AkttablaNyitas;
    procedure BeirjaAzIdkodot;
    procedure Loadprosandid;
    procedure Button1Click(Sender: TObject);

    function Nulele(_int: integer): string;
    function Ezertektar(_pnum: integer):boolean;
    function Nevcontrol(_pn,_id: string): boolean;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _jopenztarosnev,_jopenztaroskod,_keresettnev,_aktTablanev: string;
  _aktfeltetel,_bfFeltet,_wuFeltet,_aktid,_aktpn,_hasnev: string;


  _pcs,_nev,_kod,_farok,_bfnev,_wunev,_akttabla,_pn,_id,_fdbPath: string;

  _sorveg: string = chr(13)+chr(10);

  _prosnevdarab,_qq,_nevoke,_y: integer;

  _Tprosnev,_Tidkod: array[0..599] of string;
  _honev: array[1..12] of string = ('Január','Február','Március','Április','Május',
                  'Június','Július','Augusztus','Szeptember','Október',
                                        'November','December');
  _iden,_aktho,_kertev,_kertho: integer;
  _top,_left,_height,_width: word;


implementation

uses Unit2;

{$R *.dfm}

// =============================================================================
                 procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

var i: integer;

begin
  _height := screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  _top := round((_height-650)/2);
  _left := round((_width-510)/2);

  _iden := yearof(date);
  _aktho := monthof(date);

  evcombo.Items.clear;
  evcombo.Items.Add(inttostr(_iden-1));
  evcombo.Items.Add(inttostr(_iden));
  evcombo.ItemIndex := 1;

  hocombo.Items.Clear;
  for i := 1 to 12 do hocombo.Items.add(_honev[i]);
  hocombo.ItemIndex := _aktho-1;
end;


// =============================================================================
                 procedure TForm1.Button2Click(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;

// =============================================================================
                procedure TForm1.Button1Click(Sender: TObject);
// =============================================================================

begin

  Loadprosandid;

  // A kért év és hónap alapján meghatározza  Bf-nevet és  wuni-nevet:

  _kertev := _iden;
  if evcombo.ItemIndex=0 then dec(_kertev);
  _kertho := 1 + (hocombo.itemindex);
  _farok := inttostr(_kertev-2000)+nulele(_kertho);

  _bfnev := 'BF' + _farok;
  _wuNev := 'WUNI' + _farok;

  _BFfeltet := '(STORNO=1) AND (TIPUS<>'+chr(39)+'F'+CHR(39)+') AND (';
  _BFfeltet := _BFfeltet + 'TIPUS<>'+chr(39)+'U'+CHR(39)+')';

  _wufeltet := '(STORNO=1) AND (UGYFELTIPUS='+chr(39)+'U'+chr(39)+')';

  // QQ = A feltétetelezett pénztárszám:

 // ======================== CIKLUS FEJ ========================================

  _qq := 1;
  while _qq<=150 do
    begin

      // Az értéktárakat nem vizsgáljuk:

      if Ezertektar(_qq) then
        begin
          inc(_qq);
          Continue;
        end;

      _fdbPath := 'c:\receptor\database\v'+INTTOSTR(_qq)+'.fdb';

      // Ahol nincs adatbázis, ott pénztár sincs:

      if not fileExists(_fdbPath) then
        begin
          inc(_qq);
          continue;
        end;

      FdbPanel.Caption := _fdbpath;
      FdbPanel.Repaint;

      // ---------------------------------------------

      // Most megnézi, hogy az aktuális firebird tábla van-e;

      ibdbase.close;
      ibdbase.DatabaseName := _fdbPath;
      ibDbase.Connected := TRUE;

      _aktTablaNev := _bfNev;
      _aktFeltetel := _bfFeltet;

      ibTabla.close;
      ibTabla.TableName := _aktTablanev;

      // Ha a vizsgált tábla nem létezik, lépünk a következő pénztárra:

      if not ibtabla.Exists then
        begin
          ibDbase.close;
          inc(_qq);
          continue;
        end;


      AktTablaNyitas;

      // A táblán végig nézi az összes pénztárost:

      while not ibquery.Eof do
        begin

           // Kiolvassa a nevet és az id kódot:

          _aktpn := Ibquery.fieldbyname('PENZTAROSNEV').asString;
          _aktid := Ibquery.FieldByName('IDKOD').asString;

          // Ha a pénztáros már leszámolt, akkor nem vizsgáljuk:

          if _aktid='00000' then
            begin
              ibquery.next;
              continue;
            end;

          // Ellenörzi a két adatot: Ha nem volt rendben, akkor megjavitja
          //                         és false-al tér vissza:

          if not Nevcontrol(_aktpn,_aktid) then
            begin
              Memo1.Lines.add('Hibás adat: '+_aktpn+' - '+_aktid);
              AkttablaNyitas;
              Continue;
            end;


          ibquery.next;
        end;

      ibquery.next;
      ibdbase.close;

      // -----------------------------------------

      _aktTablanev := _wuNev;
      _aktFeltetel := _wufeltet;

      ibTabla.close;
      ibTabla.TableName := _aktTablanev;
      ibdbase.Connected := true;

      // Ha a vizsgált tábla nem létezik, lépünk a következő pénztárra:

      if not ibtabla.Exists then
        begin
          ibDbase.close;
          inc(_qq);
          continue;
        end;


      AktTablaNyitas;

      while not ibquery.Eof do
        begin

          _aktpn := Ibquery.fieldbyname('PENZTAROSNEV').asString;
          _aktid := Ibquery.FieldByName('IDKOD').asString;

          if _aktid='00000' then
            begin
              ibquery.next;
              continue;
            end;

          if not Nevcontrol(_aktpn,_aktid) then
            begin
              Memo1.Lines.add('Hibás adat: '+_aktpn+' - '+_aktid);
              AktTablaNyitas;
              Continue;
            end;
          ibquery.next;
        end;

      ibquery.close;
      ibdbase.close;

      // -----------------------------------------

      inc(_qq);
    end;

  Memo1.Lines.add('Készen van');  
  Showmessage('KÉSZEN VAN AZ EGÉSZ');
  Application.Terminate;
end;


// =============================================================================
          function TForm1.Nevcontrol(_pn,_id: string): boolean;
// =============================================================================

var _wpn: byte;

begin
  result := false;
  _y := 0;
  _keresettnev := trim(_pn);

  _pn := trim(leftstr(_pn,12));
  _wpn := length(_pn);

  while _y<_prosnevdarab do
    begin
      _hasnev := leftstr(_tprosnev[_y],_wpn);
      if _hasnev=_pn then
        begin

          _jopenztaroskod := _tidkod[_y];
          _jopenztarosnev := _keresettnev;

          if _jopenztaroskod = _id then
            begin
              // A vizsgált dolgozó rendben van:

              result := True;
              exit;
            end;
          // A néve stimmel, de a kód nem:
          BeirjaAzIdkodot; // set idkod=jopenztaroskod where Penztarosnev=_jopenztarosnev
          exit;
        end;
      inc(_y);
    end;

  // --------- Nem talált ilyen nevet  -----------------------------------------

  _nevOke := JonevetValaszt.ShowModal;
  if _nevoke=2 then  // tehát nincs ilyen dolgozó
    begin
      _jopenztaroskod := '00000';
      _jopenztarosnev := _keresettnev;
      BeirjaAzIdkodot;
      exit;
    end;

  ibquery.close;
  ibdbase.close;


  _pcs := 'UPDATE '+ _akttablanev + ' SET PENZTAROSNEV=' + chr(39)+_jopenztarosnev+chr(39)+',';
  _pcs := _pcs + 'IDKOD=' + chr(39)+ _jopenztaroskod + chr(39) + _sorveg;
  _pcs := _pcs + 'WHERE PENZTAROSNEV='+CHR(39) + _keresettnev + chr(39);

  ibParancs(_pcs);
end;


// =============================================================================
                procedure TForm1.Ibparancs(_ukaz: string);
// =============================================================================

begin
  ibdbase.Connected := true;
  if ibtranz.InTransaction then ibtranz.Commit;
  ibtranz.StartTransaction;
  with ibquery do
    begin
      Close;
      sql.clear;
      Sql.add(_ukaz);
      ExecSql;
    end;
  ibtranz.Commit;
  ibdbase.close;
end;      



// =============================================================================
                          procedure TForm1.BeirjaAzIdkodot;
// =============================================================================

begin
  ibquery.close;
  ibdbase.close;

  _pcs := 'UPDATE ' + _aktTablaNev + ' SET IDKOD=' + chr(39)+_jopenztaroskod+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE PENZTAROSNEV=' + chr(39) + _jopenztarosnev + chr(39);
  ibParancs(_pcs);
end;


// =============================================================================
                 function TForm1.Nulele(_int: integer): string;
// =============================================================================

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;


// =============================================================================
                function TForm1.Ezertektar(_pnum: integer):boolean;
// =============================================================================

begin
  result := True;
  if (_pnum=10) or (_pnum=20) or (_pnum=40) or (_pnum=50) then exit;
  if (_pnum=63) or (_pnum=75) or (_pnum=120) or (_pnum=145) then exit;
  result := false;
end;


// =============================================================================
                        procedure TForm1.Loadprosandid;
// =============================================================================

begin
  _prosnevdarab := 0;
  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAROSNEV';

  Prosdbase.connected := true;
  with ProsQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not Prosquery.eof do
    begin
      _pn := trim(Prosquery.Fieldbyname('PENZTAROSNEV').asstring);
      _id := prosquery.Fieldbyname('IDKOD').asstring;

      _Tprosnev[_prosnevdarab] := _pn;
      _Tidkod[_prosnevdarab] := _id;

      inc(_prosnevdarab);
      Prosquery.next;
    end;
  prosquery.close;
  prosdbase.close;
end;



// =============================================================================
                     procedure TForm1.AkttablaNyitas;
// =============================================================================

begin
  _pcs := 'SELECT * FROM ' + _aktTablaNev + _sorveg;
  _pcs := _pcs + 'WHERE ' + _aktFeltetel;

  ibdbase.Connected := true;
  with IbQuery do
    begin
      Close;
      Sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;
end;


end.
