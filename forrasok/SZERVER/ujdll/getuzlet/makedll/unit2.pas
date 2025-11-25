unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls,StrUtils, IBDatabase, DB,
  IBCustomDataSet, IBQuery;

type
  TGETUZLETSZAM = class(TForm)

    FomenuPanel       : TPanel;

    BitBtn1           : TBitBtn;
    ChangeKftGomb     : TBitBtn;
    ErtektarakGomb    : TBitBtn;
    ErtektarCancelGomb: TBitBtn;
    PenztarCancelGomb : TBitBtn;
    MegsemGomb        : TBitBtn;
    PenztarakGomb     : TBitBtn;
    ValasztoGomb      : TBitBtn;

    ErtektarPanel     : TPanel;
    Label1            : TLabel;
    Label2            : TLabel;
    Label3            : TLabel;
    PenztarPanel      : TPanel;

    ErtektarList      : TListBox;
    PenztarList       : TListBox;

    Shape1            : TShape;
    Shape2            : TShape;
    Shape3            : TShape;
    Shape4            : TShape;
    Shape5            : TShape;
    Shape6            : TShape;
    Shape7            : TShape;
    Shape11           : TShape;
    ZalogGomb         : TBitBtn;

    ReceptorQuery     : TIBQuery;
    ReceptorDbase     : TIBDatabase;
    ReceptorTranz     : TIBTransaction;
    ParaQuery         : TIBQuery;
    ParaDbase         : TIBDatabase;
    ParaTranz         : TIBTransaction;
    ArtQuery          : TIBQuery;
    ArtDbase          : TIBDatabase;
    ArtTranz          : TIBTransaction;

    procedure FormActivate(Sender: TObject);
    procedure IrodaBetolto;
    procedure ChangeKftGombClick(Sender: TObject);

    procedure ErtektarakGombClick(Sender: TObject);
    procedure PenztarakGombClick(Sender: TObject);
    procedure ParaParancs(_ukaz: string);
    procedure SetFilter;
    procedure ParaFeliro;
    procedure ErtektarListKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ErtekTartValasztott(Sender: TObject);
    procedure PenztarListKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PenztartValasztott(Sender: TObject);
    procedure ChangeKftGombEnter(Sender: TObject);
    procedure ChangeKftGombExit(Sender: TObject);
    procedure ChangeKftGombMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ValasztoGombEnter(Sender: TObject);
    procedure ValasztoGombExit(Sender: TObject);
    procedure MegsemGombClick(Sender: TObject);
    procedure ZalogGombClick(Sender: TObject);

    function Kibovit(_pp:integer): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

{
  MODALRESULT: 1-180 Közvetlen a pénzár száma

               201 - Exclusive Change Kft

               211-214 = Best,Pannon,East,Expressz

               221-229 = Szekszard,Szeged,Kecskemét,Debrecen,Nyiregyhza
                         Békéscsaba,Pécs,Kaposvár,Expressz
}


var
  GETUZLETSZAM: TGETUZLETSZAM;

  _irodadarab: word;
  _irodaszam,_pKorzet: array[1..180] of word;
  _irodanev,_pCegbetu: array[1..180] of string;

  _index     : integer;
  _aktirodaszam,_aktkorzet: integer;
  _ptsz,_y   : word;
  _aktitem,_aktcegbetu,_filter: string;

  _korzetszaM: array[1..9] of byte = (10,20,40,50,63,75,120,145,162);
  _kBetusor : array[1..9] of string = ('B','B','B','B','B','B','B','B','Z');
  _korzetnev : array[1..9] of string = ('Szekszárd','Szeged','Kecskemét','Debrecen',
                         'Nyíregyháza','Békéscsaba','Pécs','Kaposvár','Expressz');
  _cc: word;

  _pcs: string;
  _sorveg: string = chr(13)+chr(10);

  _aktpenztar,_szurotipus: byte;

  _PenztarIndex: integer;


function getegysegkod: integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
                function getegysegkod: integer; stdcall;
// =============================================================================

begin
  Getuzletszam := TGetuzletszam.Create(Nil);
  result := Getuzletszam.showmodal;
  Getuzletszam.free;
end;


// =============================================================================
          procedure TGetuzletszam.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top    := 350;
  Left   := 390;

  IrodaBetolto;

  ErtekTarPanel.Visible := False;
  PenztarPanel.Visible  := False;

  ErtekTarList.Clear;
  _y := 1;
  while _y<=9 do
    begin
      ErtekTarList.Items.Add(_korzetnev[_y]);
      inc(_y);
    end;

  ErtekTarList.ItemIndex := 0;

  PenztarList.Clear;
  PenztarList.Items.Clear;

  _y := 1;
  while _y<=_irodadarab do
    begin
      _ptsz    := _irodaszam[_y];
      _aktitem := kibovit(_ptsz)+'-'+_irodanev[_y];
      PenztarList.Items.Add(_aktitem);
      inc(_y);
    end;

  PenztarList.ItemIndex := 0;


  _aktcegBetu := '';
  with FomenuPanel do
    begin
      Top  := 0;
      Left := 0;
      Visible := true;
    end;
  ActiveControl := ChangeKftGomb;
end;


// -----------------------------------------------------------------------------
// =============================================================================
           procedure TGETUZLETSZAM.CHANGEKFTGOMBClick(Sender: TObject);
// =============================================================================

begin
  _szurotipus := 4;
  ParaFeliro;
  Modalresult := 201;
end;

// =============================================================================
         procedure TGETUZLETSZAM.ERTEKTARAKGOMBClick(Sender: TObject);
// =============================================================================

begin
  FomenuPanel.Visible := False;

  Height := 310;
  Width  := 282;
  Left   := 500;

  with ErtekTarpanel do
    begin
      Top := 0;
      Left := 0;
      Visible := true;
    end;
  ActiveControl := ertekTarList;
  ErtektarList.SetFocus;
end;

// =============================================================================
            procedure TGETUZLETSZAM.PenztarakGombClick(Sender: TObject);
// =============================================================================

begin
  FomenuPanel.Visible := False;

  Height := 317;
  width  := 347;
  left   := 460;

  with PenztarPanel do
    begin
      Top     := 0;
      Left    := 0;
      Visible := true;
    end;

  ActiveControl := PenztarList;
  PenztarList.SetFocus;
end;


// =============================================================================
      procedure TGETUZLETSZAM.CHANGEKFTGOMBMouseMove(Sender: TObject;
                                            Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  ActiveControl := TBitbtn(Sender);
end;


// =============================================================================
          procedure TGETUZLETSZAM.VALASZTOGOMBEnter(Sender: TObject);
// =============================================================================

begin
  with Tbitbtn(sender).Font do
    begin
      Color := clRed;
      styLe := [fsBold];
    end;
end;

// =============================================================================
           procedure TGETUZLETSZAM.VALASZTOGOMBExit(Sender: TObject);
// =============================================================================

begin
  with Tbitbtn(sender).Font do
    begin
      Color := clBlack;
      styLe := [];
    end;
end;


// -----------------------------------------------------------------------------
// =============================================================================
                      procedure TGetuzletszam.IrodaBetolto;
// =============================================================================

var _z: byte;

begin

  for _z := 1 to 180 do
    begin
      _irodanev[_z] := '';
      _irodaszam[_z]:= 0;
      _Pkorzet[_z] := 0;
      _Pcegbetu[_z] := '';
    end;

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  ReceptorDbase.Connected := true;
  with ReceptorQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_PCS);
      Open;
      First;
    end;

  _cc := 0;
  ReceptorQuery.First;
  while not ReceptorQuery.Eof do
    begin
      inc(_cc);
      with ReceptorQuery do
        begin
          _irodaszam[_cc] := FieldByName('UZLET').asInteger;
          _irodanev[_cc]  := trim(FieldByName('KESZLETNEV').asstring);
          _pKorzet[_cc] := FieldByNAme('ERTEKTAR').asInteger;
          _pCegbetu[_cc] := FieldByName('CEGBETU').asString;
        end;
      ReceptorQuery.Next;
    end;
  ReceptorQuery.Close;
  ReceptorDbase.Close;

// -----------------------------------------------------------------------------

  ArtDbase.Connected := true;
  with ArtQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_PCS);
      Open;
      First;
    end;


  while not ArtQuery.Eof do
    begin
      inc(_cc);
      with ArtQuery do
        begin
          _irodaszam[_cc] := FieldByName('UZLET').asInteger;
          _irodanev[_cc]  := trim(FieldByName('KESZLETNEV').asstring);
          _pKorzet[_cc] := 180;
          _pCegbetu[_cc] := 'Z';
        end;
      ArtQuery.Next;
    end;
  ArtQuery.Close;
  ArtDbase.Close;




  _irodadarab := _cc;
end;

// -----------------------------------------------------------------------------
// =============================================================================
   procedure TGETUZLETSZAM.PENZTARLISTKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  PenztartValasztott(Nil);
end;

// =============================================================================
          procedure TGetuzletszam.PenztartValasztott(Sender: TObject);
// =============================================================================

begin
  _szurotipus := 1;
  _index := 1+PenztarList.Itemindex;
  _aktirodaszam := _Irodaszam[_index];
  _aktkorzet := _pKorzet[_index];
  _aktcegbetu := _pCegbetu[_index];
  Parafeliro;
  Modalresult := _aktirodaszam;
end;

// -----------------------------------------------------------------------------
// =============================================================================
    procedure TGETUZLETSZAM.ERTEKTARLISTKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  ErtektartValasztott(Nil);
end;

// =============================================================================
         procedure TGetuzletszam.ErtekTartvalasztott(Sender: TObject);
// =============================================================================

begin
  _index := 1+ErtektarList.itemindex;
  _szurotipus := 2;
  _AKTCEGBETU := _KBETUSOR[_index];
  _aktkorzet := _korzetszam[_index];
  ParaFeliro;
  Modalresult := 220+_index;
end;

{
// -----------------------------------------------------------------------------
// =============================================================================
         procedure TGetUzletSzam.BestGombClick(Sender: TObject);
// =============================================================================
begin
  _szurotipus := 3;
  _aktCegBetu := 'B';
  ParaFeliro;
  Modalresult := 211;
end;

// =============================================================================
          procedure TGetUzletszam.PannonGombClick(Sender: TObject);
// =============================================================================
begin
  _szurotipus := 3;
  _aktCegBetu := 'P';
  ParaFeliro;
  Modalresult := 212;
end;

// =============================================================================
             procedure TGetUzletSzam.EastGombClick(Sender: TObject);
// =============================================================================

begin
  _szurotipus := 3;
  _aktcegbetu := 'E';
  ParaFeliro;
  ModalResult := 213;
end;
}


// =============================================================================
           procedure TGetUzletSzam.ZalogGombClick(Sender: TObject);
// =============================================================================
begin
  _szurotipus := 3;
  _aktCegBetu := 'Z';
  ParaFeliro;
  ModalResult := 214;
end;

// -----------------------------------------------------------------------------
// =============================================================================
          procedure TGetuzletszam.MegsemGombClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := -1;
end;

// =============================================================================
            function TGetUzletszam.Kibovit(_pp:integer): string;
// =============================================================================

begin
  result := inttostr(_pp);
  while length(result)<3 do result := ' '+result;
end;

// =============================================================================
          procedure TGETUZLETSZAM.CHANGEKFTGOMBEnter(Sender: TObject);
// =============================================================================

begin
  with TBitBtn(sender).Font do
    begin
      Color := clRed;
      style := [fsBold,fsItalic];
      size := 12;
    end;
end;

// =============================================================================
          procedure TGETUZLETSZAM.CHANGEKFTGOMBExit(Sender: TObject);
// =============================================================================

begin
  with TBitBtn(sender).Font do
    begin
      Color := clBlack;
      style := [];
      size := 10;
    end;
end;


// =============================================================================
                   procedure TGetuzletszam.ParaFeliro;
// =============================================================================

begin
  SetFIlter;

  _pcs := 'DELETE FROM ADATATADO';
  ParaParancs(_pcs);

  _pcs := 'INSERT INTO ADATATADO (TIPUS,IRODA,KORZET,CEGBETU,SZURO)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + inttostr(_szurotipus) + ',';
  _pcs := _pcs + inttostr(_aktirodaszam)+',';
  _pcs := _pcs + inttostr(_aktkorzet) + ',';
  _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',';
  _pcs := _pcs + chr(39) + _filter + chr(39) + ')';
  ParaParancs(_pcs);
end;

// =============================================================================
            procedure TGetuzletszam.ParaParancs(_ukaz: string);
// =============================================================================

begin
  Paradbase.connected := True;
  if ParaTranz.intransAction then ParaTranz.commit;
  Paratranz.StartTransaction;
  with ParaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  ParaTranz.commit;
  Paradbase.close;
end;

// =============================================================================
                     procedure TGetuzletszam.Setfilter;
// =============================================================================

begin
  if _szurotipus=1 then _filter := '(IRODASZAM='+inttostr(_aktirodaszam)+') AND (ERTEKTAR>0)';
  if _szurotipus=2 then _filter := '(IRODASZAM=0) AND (ERTEKTAR='+inttostr(_aktkorzet)+')';
  if _szurotipus=3 then _filter := '(IRODASZAM=0) AND (ERTEKTAR=0) AND (CEGBETU=';
  if _szurotipus=4 then _filter := '(ERTEKTAR=-1)';
end;


end.
