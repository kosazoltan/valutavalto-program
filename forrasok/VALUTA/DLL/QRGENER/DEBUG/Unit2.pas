unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, DelphiZXingQRCode, ExtCtrls,strUtils,
  StdCtrls, ComCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery;

type
  TForm2 = class(TForm)
    AlapPanel  : TPanel;
    Kijelzo    : TPaintBox;
    Csuszo     : TTrackBar;
    TovabbGomb : TBitBtn;
    QrTakaro   : TPanel;

    Shape1     : TShape;

    Label1     : TLabel;
    Label2     : TLabel;
    Label3     : TLabel;
    Label4     : TLabel;
    MeretPanel : TPanel;

    ValutaQuery: TIBQuery;
    ValutaDbase: TIBDatabase;
    ValutaTranz: TIBTransaction;
    NEXTGOMB: TBitBtn;
    FOCIMPANEL: TPanel;
    n1LABEL: TLabel;
    N2LABEL: TLabel;
    Label7: TLabel;
    Shape2: TShape;

    procedure Day_open_3;
    procedure Clear_All_currencies;
    procedure Install_currencies;
    procedure Day_close;
    procedure Day_open;
    procedure Pay_in;
    procedure Pay_out;
    procedure Buying;
    procedure Selling;
    procedure Cancellation;

    procedure FormDestroy(Sender: TObject);

    procedure KijelzoPaint(Sender: TObject);
    procedure MeretChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);

    procedure QrParamBeolvasas;
    procedure TOVABBGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure MasodikLepcso;
    procedure HarmadikLepcso;

    function Scandnem(_xDnem: string): integer;
    function Nulele(_b: byte): string;
    function Konvdnem(_zDnem: string): string;
    function Arfform(_yArf: integer): string;
    procedure NEXTGOMBClick(Sender: TObject);
    function Konv(_b: byte): byte;
    function Commless(_s: string): string;

  private
    QRCodeBitmap: TBitmap;
  public
    procedure Frissit;
  end;


var
  Form2: TForm2;
  _reklam: string = 'Raiffeisen Bank ugynoke';

  _number,_y,_z,_tetel,_kulfoldi,_openMenet: byte;
  _skala,_xx,_zaro,_aktbjegy,_kezdij,_aktarf,_fizetendo,_recnum: integer;
  _bytetomb: array[1..2054] of byte;
  _iras: File of Byte;

  _zk: array[0..26] of integer;
  _yDnem: array[1..26] of string;
  _bjegy,_arf: array[1..26] of integer;
  _earf: array[0..26] of integer;

  _initstring: string = 'http://www.fiscat.com/AEE';
  _pcs,_pacs,_aktdnem,_bizonylatszam,_okmanytipus,_azonosito: string;
  _penztarkod: string;

  _width,_height,_left,_top: word;
  _randnum,_penztarszam,_code: integer;
  _becsuszik: boolean;

  _dnem: array[0..26] of string = ('HUF','EUR','AUD','BAM','BGN','BRL','CAD',
                          'CHF','CNY','CZK','DKK','GBP','HRK','ILS','JPY',
                          'MXN','NOK','NZD','PLN','RON','RSD','RUB','SEK',
                          'THB','TRY','UAH','USD');



function qrdisplayrutin: integer; stdcall;


implementation

{$R *.dfm}

function qrdisplayrutin: integer; stdcall;
begin
  Form2 := TForm2.Create(NIL);
  result := Form2.showmodal;
  Form2.Free;
end;

// =============================================================================
              procedure TForm2.FormCreate(Sender: TObject);
// =============================================================================

begin
  _width := screen.Monitors[0].Width;
  _height := screen.Monitors[0].Height;

  _top := round((_height-768)/2);
  _left := round((_width-1024)/2);

  Top := _top+80;
  Left := _left + 300;

  NextGomb.Visible := False;
  shape1.repaint;
  AlapPanel.repaint;
  Repaint;
end;

// =============================================================================
                procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  Csuszo.OnChange := Nil;
  Csuszo.Position := 16;
  _Becsuszik      := True;
  _kulfoldi       := 0;

  QrParamBeolvasas;

  Label7.Repaint;

  Sleep(1200);

  Csuszo.OnChange := MeretChange;

  QRCodeBitmap := TBitmap.Create;
  case _number of

    0: Day_open_3;
    1: Clear_all_currencies;
    2: Install_Currencies;
    3: Day_close;
    4: Day_Open;
    5: Pay_in;
    6: Pay_out;
    7: Buying;
    8: Selling;
    9: Cancellation;
  end;
end;

// =============================================================================
               procedure TForm2.MeretChange(Sender: TObject);
// =============================================================================

begin
  Frissit;
end;

// =============================================================================
                 procedure TForm2.FormDestroy(Sender: TObject);
// =============================================================================

begin
  QRCodeBitmap.Free;
end;

// =============================================================================
                 procedure TForm2.KijelzoPaint(Sender: TObject);
// =============================================================================

var
  Scale: Double;
begin
  Kijelzo.Canvas.Brush.Color := clWhite;
  Kijelzo.Canvas.FillRect(Rect(0, 0, Kijelzo.Width, Kijelzo.Height));
  if ((QRCodeBitmap.Width > 0) and (QRCodeBitmap.Height > 0)) then
  begin
    if (Kijelzo.Width < Kijelzo.Height) then
    begin
      Scale := Kijelzo.Width / QRCodeBitmap.Width;
    end else
    begin
      Scale := Kijelzo.Height / QRCodeBitmap.Height;
    end;
    Kijelzo.Canvas.StretchDraw(Rect(0, 0, Trunc(Scale * QRCodeBitmap.Width), Trunc(Scale * QRCodeBitmap.Height)), QRCodeBitmap);
  end;
end;


// =============================================================================
                             procedure TForm2.Frissit;
// =============================================================================

var
  QRCode: TDelphiZXingQRCode;
  Row, Column: Integer;
  _q: word;



begin

  Kijelzo.Width := 0;
  QRCode := TDelphiZXingQRCode.Create;
  try
    _skala := Csuszo.Position;
    MeretPanel.Caption := inttostr(_skala);
    Meretpanel.repaint;


    QRCode.Data := _pacs;
    QRCode.Encoding := TQrCodeEncoding(0);
    QrCode.Quietzone := _skala;

    row := Qrcode.rows;
    Column := Qrcode.columns;

    QrcodeBitmap.Height := Row;
    QrcodeBitmap.Width := Column;

    for Row := 0 to QRCode.Rows - 1 do
    begin
      for Column := 0 to QRCode.Columns - 1 do
      begin
        if (QRCode.IsBlack[Row, Column]) then
        begin
          QRCodeBitmap.Canvas.Pixels[Column, Row] := clBlack;
        end else
        begin
          QRCodeBitmap.Canvas.Pixels[Column, Row] := clWhite;
        end;
      end;
    end;
  finally
    QRCode.Free;
  end;
  if _becsuszik then
    begin
      _q := 25;
      while _q<350 do
        begin
          _q := _q + 25;
          Kijelzo.Width := _q;
          Kijelzo.repaint;
          sleep(20);
        end;
    end;
  Kijelzo.Width := 350;
  Kijelzo.repaint;
  _becsuszik := false;
end;



// =============================================================================
            procedure TForm2.TOVABBGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;


// =============================================================================
                 procedure Tform2.Clear_All_currencies;
// =============================================================================

begin
  FocimPanel.caption := 'ÖSSZES VALUTA TÖRLÉSE';
  FocimPanel.repaint;

  _pacs := _initstring + '|CCL';
  Frissit;
end;

// =============================================================================
                procedure Tform2.Install_currencies;
// =============================================================================

begin
  FocimPanel.caption := 'VALUTÁK FELVITELE';
  FocimPanel.repaint;

  _pacs := _initstring + '|CYS';
  _Y := 1;
  while _y<=25 do
    begin
      _aktdnem := _dnem[_y+1];
      _pacs := _Pacs + '|CY'+nulele(_y)+'|'+_aktdnem+'|1|1|'+_aktdnem+'|0';
      inc(_y);
    end;
  Frissit;
end;

// =============================================================================
                          procedure Tform2.Day_close;
// =============================================================================

begin
  FocimPanel.caption := 'A NAP ZÁRÁSA';
  FocimPanel.repaint;

  _pacs := _initstring + '|DC|0|0|1|1|';
  Frissit;
end;

// =============================================================================
                          procedure Tform2.Day_open;
// =============================================================================

var i: byte;
    _elszarf: integer;

begin
  Csuszo.OnChange := Nil;
  Csuszo.Position := 16;
  Csuszo.OnChange := MeretChange;

  FocimPanel.caption := 'NAP MEGNYITÁSA';
  FocimPanel.repaint;
  for i:= 0 to 26 do _zk[i] := 0;

  _pcs := 'SELECT * FROM ARFOLYAM';
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not ValutaQuery.eof do
    begin
      _aktdnem := ValutaQuery.fieldByName('VALUTANEM').asstring;
      if _aktdnem='EUA' then
        begin
          ValutaQuery.Next;
          Continue;
        end;
      _elszarf := Valutaquery.FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
      _zaro := ValutaQuery.FieldbyName('ZARO').asInteger;

      _xx := scandnem(_aktdnem);
      _zk[_xx] := _zaro;
      _arf[_xx] := _elszarf;

      ValutaQuery.next;
    end;
  ValutaQuery.close;
  Valutadbase.close;

  _pacs := _initstring + '|OP|LOCA|100.0000|'+inttostr(_zk[0]);
  _y := 0;
  while _y<=25 do
    begin
      _aktarf := _arf[_y+1];
      _aktbjegy := _zk[_y+1];
      _pacs := _pacs + '|CY'+nulele(_y);
      _pacs := _pacs + '|' + arfform(_aktarf);
      _pacs := _pacs + '|' +inttostr(_aktbjegy);
      inc(_y);
    end;
  Frissit;
end;

// =============================================================================
                          procedure Tform2.Pay_in;
// =============================================================================

begin
  FocimPanel.caption := 'PÉNZ ÁTVÉTELE';
  FocimPanel.repaint;

  _pacs := _initstring + '|RA|08|'+_bizonylatszam;
  _y := 1;
  while _y<=_tetel do
    begin
      _aktdnem := _yDnem[_y];
      _aktbjegy := _bjegy[_y];

      _pacs := _pacs + '|' + konvdnem(_aktdnem);
      _pacs := _pacs + '|' + inttostr(_aktbjegy)+'|1';

      inc(_y);
    end;
  Frissit;
end;

// =============================================================================
                          procedure Tform2.Pay_out;
// =============================================================================

begin
  FocimPanel.caption := 'PÉNZ ÁTADÁSA';
  FocimPanel.repaint;

  _pacs := _initstring + '|PO|11|'+_bizonylatszam;
  _y := 1;
  while _y<=_tetel do
    begin
      _aktdnem := _yDnem[_y];
      _aktbjegy := _bjegy[_y];

      _pacs := _pacs + '|' + konvdnem(_aktdnem);
      _pacs := _pacs + '|' + inttostr(_aktbjegy)+'|1';

      inc(_y);
    end;
  Frissit;
end;


// =============================================================================
                          procedure Tform2.Buying;
// =============================================================================

begin
  FocimPanel.caption := 'VALUTA VÁSÁRLÁSA';
  FocimPanel.repaint;

   _pacs := _initstring + '|CY-LO||'+_reklam+'|||';
   _pacs := _pacs + '|' + inttostr(_tetel);

   _y := 1;
   while _y<=_tetel do
     begin
       _aktdnem :=  _ydnem[_y];
       _aktarf  := _arf[_y];
       _aktbjegy := _bjegy[_y];

       _pacs := _pacs + '|'+konvdnem(_aktdnem)+'|'+arfform(_aktarf);
       _pacs := _pacs + '|'+inttostr(_aktbjegy);
       inc(_y);
     end;
  _pacs := _pacs + '|' + inttostr(_kezdij);
  _pacs := _pacs + '|'+ inttostr(1+_kulfoldi);

   if (_kulfoldi=1) or (_okmanytipus='') or (_azonosito='') then
    begin
      _okmanytipus := 'NN';
      _azonosito := '0000';
    end;

  _pacs := _pacs + '|' + _okmanytipus + '|'+_azonosito;
  _pacs := _pacs + '||';
  _pacs := _pacs + '|' + _bizonylatszam + '||NN|0000|NN|NN|0';

  Frissit;
end;

// =============================================================================
                          procedure Tform2.Selling;
// =============================================================================

begin
  FocimPanel.caption := 'VALUTA ELADÁSA';
  FocimPanel.repaint;

  _pacs := _initstring + '|LO-CY||'+ _reklam + '||||'+inttostr(_fizetendo);
  _pacs := _pacs + '|' + inttostr(_kezdij)+'|'+inttostr(_tetel);

  _y := 1;
  while _y<=_tetel do
    begin
      _aktdnem :=  _ydnem[_y];
      _aktarf  := _arf[_y];
      _aktbjegy := _bjegy[_y];

      _pacs := _pacs + '|'+ konvdnem(_aktdnem) +'|'+arfform(_aktarf)+'|'+inttostr(_aktbjegy);
      inc(_y);
    end;
  _pacs := _pacs + '|' + inttostr(1+_kulfoldi);

  if (_kulfoldi=1) or (_okmanytipus='') or (_azonosito='') then
    begin
      _okmanytipus := 'NN';
      _azonosito := '0000';
    end;

  _pacs := _pacs + '|' + _okmanytipus + '|'+_azonosito;
  _pacs := _pacs + '|'+_bizonylatszam+'||NN|0000|NN|NN';
  Frissit;
end;

// =============================================================================
                function TForm2.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
                          procedure Tform2.Cancellation;
// =============================================================================

begin
  FocimPanel.caption := 'BIZONYLAT STORNOZÁSA';
  FocimPanel.repaint;

  _pacs := _initstring + '|STORNO||'+inttostr(_recnum)+'|0||NN|0000|NN|NN';
  Frissit;
end;

// =============================================================================
               function Tform2.Scandnem(_xDnem: string): integer;
// =============================================================================

begin
  result := 0;
  while result<=26 do
    begin
      if _xdnem=_dnem[result] then exit;
      inc(result);
    end;
end;

// =============================================================================
                      procedure TForm2.QrParamBeolvasas;
// =============================================================================

begin
  _pcs := 'SELECT * FROM QRPARAMS';

  ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.Add('SELECT * FROM PENZTAR');
      Open;
      _penztarkod := trim(FieldByNAme('PENZTARKOD').AsString);
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
      _number := FieldByNAme('NUMBER').asInteger;
    end;

  val(_penztarkod,_penztarszam,_code);
  if _penztarSzam<151 then
    begin
      n1Label.Caption := 'EXCLUSIVE';
      n2Label.Caption := 'CHANGE';
    end else
    begin
      n1Label.Caption := 'EXPRESSZ';
      n2Label.Caption := 'EKSZERHAZ';
    end;

  n1Label.repaint;
  n2Label.repaint;


  if _number<5 then
    begin
      ValutaQuery.close;
      ValutaDbase.close;
      exit;
    end;

  if _number=9 then
    begin
      _recnum := ValutaQuery.FieldByName('RECNUM').asInteger;
      ValutaQuery.close;
      Valutadbase.close;
      exit;
    end;

  _bizonylatszam := trim(ValutaQuery.FieldByName('BIZONYLATSZAM').asString);
  _kulfoldi      := ValutaQuery.FieldbyNAme('KULFOLDI').asInteger;
  _fizetendo     := ValutaQuery.FieldByNAme('FIZETENDO').asInteger;
  _okmanytipus   := trim(ValutaQuery.FieldbyNAme('OKMANYTIPUS').asstring);
  _azonosito     := trim(ValutaQuery.FieldByName('AZONOSITO').asString);
  _kezdij        := ValutaQuery.FieldByNAme('KEZELESIDIJ').asInteger;
  _kezdij        := abs(_kezdij);

  _okmanytipus := Commless(_okmanytipus);
  _azonosito   := Commless(_azonosito);


  _tetel := 0;
  while not valutaquery.eof do
    begin
      inc(_tetel);
      _yDnem[_tetel] := ValutaQuery.FieldbyName('VALUTANEM').asstring;
      _bjegy[_tetel] := ValutaQuery.FieldByNAme('BANKJEGY').asInteger;
      if _number>6 then _arf[_tetel] := ValutaQuery.FieldByNAme('ARFOLYAM').asInteger;
      ValutaQuery.next;
    end;
  ValutaQuery.close;
  Valutadbase.close;
end;

// =============================================================================
           function TForm2.Konvdnem(_zDnem: string): string;
// =============================================================================

begin
  _xx := scandnem(_zDnem);
  result := 'LOCA';
  if _xx=0 then exit;

  result := 'CY'+nulele(_xx-1);
end;

// =============================================================================
               function TForm2.Arfform(_yArf: integer): string;
// =============================================================================

var _f1: byte;

begin
  if _yArf<100 then
    begin
      result := '0.'+nulele(_yArf)+'00';
      exit;
    end;

  result := inttostr(_yArf);
  if _aktdnem='JPY' then
    begin
      result := leftstr(result,1)+'.'+midstr(result,2,3)+'0';
      exit;
    end;

  _f1 := length(result)-2;
  result := leftstr(result,_f1)+'.'+midstr(result,_f1+1,2)+'00';
end;


// =============================================================================
                        procedure TForm2.Day_open_3;
// =============================================================================


var i: byte;

begin
  _openmenet := 1;
  Tovabbgomb.Enabled := False;
  Nextgomb.Visible := true;
  FocimPanel.caption := 'NAP MEGNYITÁSA 3 LÉPCSÕBEN';
  FocimPanel.repaint;

  for i:= 0 to 26 do
    begin
      _zk[i]   := 0;
      _earf[i] := 0;
    end;

  Valutadbase.connected := true;

  _xx := 0;
  while _xx<=26 do
    begin
      _aktdnem := _dnem[_xx];
      _pcs := 'SELECT * FROM ARFOLYAM WHERE VALUTANEM='+chr(39)+_aktdnem+chr(39);
      with ValutaQuery do
        begin
          Close;
          Sql.clear;
          sql.add(_pcs);
          Open;
          _earf[_xx] := FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
          _zk[_xx]   := FieldByNAme('ZARO').AsInteger;
          close;
        end;
      inc(_xx);
    end;
  Valutadbase.close;

  _pacs := _initstring + '|OP|LOCA|100.0000|'+inttostr(_zk[0]);
  _y := 1;
  while _y<=8 do
    begin
      _aktarf   := _earf[_y];
      _aktbjegy := _zk[_y];

      _pacs     := _pacs + '|CY'+nulele(_y-1);
      _pacs     := _pacs + '|' + arfform(_aktarf);
      _pacs     := _pacs + '|' +inttostr(_aktbjegy);
      inc(_y);
    end;
  Frissit;
end;


procedure TForm2.Masodiklepcso;

begin
  _openMenet := 2;
  FocimPanel.Caption := '2. Lépcsõ = Valuta bevétel';
  FocimPanel.repaint;

  Randomize;
  _randnum := random(9000);
  _bizonylatszam := 'U'+inttostr(_randnum);


  _pacs := _initstring + '|RA|08|'+_bizonylatszam;

  _xx := 9;
  while _xx<=17 do
    begin
      _aktdnem := _Dnem[_xx];
      _aktbjegy:= _zk[_xx];

      _pacs := _pacs + '|' + konvdnem(_aktdnem);
      _pacs := _pacs + '|' + inttostr(_aktbjegy)+'|1';

      inc(_xx);
    end;
  Frissit;
end;

procedure TForm2.Harmadiklepcso;

begin
  FocimPanel.Caption := '3. Lépcsõ = Maradék bevétel';
  FocimPanel.repaint;
  Nextgomb.Visible := false;
  Tovabbgomb.Enabled := true;

  _openMenet := 3;
  Randomize;
  _randnum := random(9000);
  _bizonylatszam := 'U'+inttostr(_randnum);

  _pacs := _initstring + '|RA|08|'+_bizonylatszam;
  _xx := 18;
  while _xx<=26 do
    begin
      _aktdnem := _Dnem[_xx];
      _aktbjegy := _zk[_xx];

      _pacs := _pacs + '|' + konvdnem(_aktdnem);
      _pacs := _pacs + '|' + inttostr(_aktbjegy)+'|1';

      inc(_xx);
    end;
  Frissit;
end;

procedure TForm2.NEXTGOMBClick(Sender: TObject);
begin
  qRtAKARO.Visible := True;
  if _openMenet=1 then
    begin
      Masodiklepcso;
      exit;
    end;
  if _openMenet=2 then
    begin
      Harmadiklepcso;
      exit;
    end;
  NextGomb.Visible := False;
  Tovabbgomb.enabled := true;
  Modalresult := 1;

end;

// =============================================================================
               function TFORM2.Commless(_s: string): string;
// =============================================================================

var _ls,_z,_asc: byte;

begin
  result := '';
  _s := trim(_s);
  _ls := length(_s);
  if _Ls=0 then exit;

  _s := uppercase(_s);
  _z := 1;
  while _z<=_Ls do
    begin
      _asc := ord(_s[_z]);
      if _asc>190 then _asc := konv(_asc);
      result := result + chr(_asc);
      inc(_z);
    end;
end;

// =============================================================================
               function TFORM2.Konv(_b: byte): byte;
// =============================================================================

begin
  case _b of
    193: _b := 65;
    201: _b := 69;
    205: _b := 73;
    211: _b := 79;
    213: _b := 79;
    214: _b := 79;
    218: _b := 85;
    219: _b := 85;
    220: _b := 85;

    225: _b := 65;
    233: _b := 69;
    237: _b := 73;
    243: _b := 79;
    245: _b := 79;
    246: _b := 79;
    250: _b := 85;
    251: _b := 85;
    252: _b := 85;
  end;
  result := _b;
end;


end.
